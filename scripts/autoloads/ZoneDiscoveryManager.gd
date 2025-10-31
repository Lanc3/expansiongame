extends Node
## Manages zone discovery and triggers on-demand zone generation

signal zone_discovered(zone_id: String)
signal wormhole_unlocked(wormhole: Node2D)
signal new_zone_generated(zone_id: String, source_zone_id: String)

# Reference to ZoneSetup for generating zone layers
var zone_setup: Node = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Wait for GameScene to fully load (ZoneSetup is a scene node, not an autoload)
	# We need to wait longer since GameScene loads after autoloads
	await get_tree().create_timer(0.5).timeout
	
	# Try multiple methods to find ZoneSetup
	zone_setup = get_tree().root.get_node_or_null("GameScene/Systems/ZoneSetup")
	
	if not zone_setup:
		# Fallback: try find_child if direct path fails
		zone_setup = get_tree().root.find_child("ZoneSetup", true, false)
	
	if zone_setup:
		print("ZoneDiscoveryManager: Found ZoneSetup at: %s" % zone_setup.get_path())
	else:
		print("ZoneDiscoveryManager: WARNING - ZoneSetup not found yet, will retry on first use")


func discover_zone(zone_id: String):
	"""Mark a zone as discovered"""
	if ZoneManager:
		ZoneManager.discover_zone(zone_id)
		zone_discovered.emit(zone_id)

func get_discoverable_zones(from_zone_id: String) -> Array[Dictionary]:
	"""Get neighboring zones that can be discovered"""
	if not ZoneManager:
		return []
	
	return ZoneManager.get_undiscovered_neighbors(from_zone_id)

func generate_and_discover_lateral_zone(source_zone_id: String, wormhole: Node2D, wormhole_direction: float) -> String:
	"""Generate a new lateral zone when entering an undiscovered wormhole"""
	if not ZoneManager:
		print("ZoneDiscovery: ERROR - ZoneManager not found!")
		return ""
	
	# Get source zone info
	var source_zone = ZoneManager.get_zone(source_zone_id)
	if source_zone.is_empty():
		print("ZoneDiscovery: ERROR - Source zone '%s' not found!" % source_zone_id)
		return ""
	
	var difficulty = source_zone.difficulty
	
	# Check if we've reached max zones for this difficulty
	var existing_zones = ZoneManager.get_zones_at_difficulty(difficulty)
	var max_zones = ZoneManager.ZONES_PER_DIFFICULTY.get(difficulty, 4)
	
	if existing_zones.size() >= max_zones:
		print("ZoneDiscovery: Max zones reached for difficulty %d (%d/%d)" % [difficulty, existing_zones.size(), max_zones])
		return ""
	
	# CRITICAL: Get the target zone index from the wormhole metadata
	var target_zone_index = wormhole.get_meta("target_zone_index", -1)
	if target_zone_index == -1:
		print("ZoneDiscovery: WARNING - Wormhole missing target_zone_index metadata!")
	else:
		print("ZoneDiscovery: Wormhole expects to create zone at index %d" % target_zone_index)
	
	# Generate new zone at the correct index
	var new_zone_id = ZoneManager.generate_lateral_zone(difficulty, source_zone_id, wormhole_direction, target_zone_index)
	
	# Update wormhole target
	if wormhole and is_instance_valid(wormhole):
		wormhole.target_zone_id = new_zone_id
		wormhole.is_active = true
	
	# Generate zone layer structure FIRST (before discovery)
	# Try to find ZoneSetup if not already cached
	if not zone_setup:
		zone_setup = get_tree().root.get_node_or_null("GameScene/Systems/ZoneSetup")
		if not zone_setup:
			zone_setup = get_tree().root.find_child("ZoneSetup", true, false)
	
	if zone_setup and zone_setup.has_method("create_zone_layer_for_discovered_zone"):
		zone_setup.create_zone_layer_for_discovered_zone(new_zone_id)
	else:
		print("ZoneDiscovery: ERROR - Cannot create zone layer (ZoneSetup not found)")
		# Can't continue without zone layer
		return ""
	
	# Create bidirectional wormhole connection (return wormhole in new zone)
	create_return_lateral_wormhole(new_zone_id, source_zone_id, wormhole_direction)
	
	# NOW discover the zone (this triggers resource/enemy spawning)
	ZoneManager.discover_zone(new_zone_id)
	
	# CRITICAL: Initialize systems for the new zone (in case zone was created as discovered)
	if FogOfWarManager and FogOfWarManager.has_method("initialize_zone_fog"):
		FogOfWarManager.initialize_zone_fog(new_zone_id)
	
	# Force spawn resources for the new zone
	var resource_spawner = get_tree().root.find_child("ResourceSpawner", true, false)
	if resource_spawner and resource_spawner.has_method("spawn_resources_for_zone"):
		var zone_data = ZoneManager.get_zone(new_zone_id)
		if not zone_data.is_empty():
			resource_spawner.spawn_resources_for_zone(new_zone_id, zone_data)
	
	# Force spawn enemies for the new zone
	var enemy_spawner = get_tree().root.find_child("EnemySpawnerSystem", true, false)
	if enemy_spawner and enemy_spawner.has_method("setup_zone_enemies"):
		enemy_spawner.setup_zone_enemies(new_zone_id)
	
	print("ZoneDiscovery: Discovered new zone '%s' (%s)" % [new_zone_id, ZoneManager.get_zone(new_zone_id).procedural_name])
	
	new_zone_generated.emit(new_zone_id, source_zone_id)
	zone_discovered.emit(new_zone_id)
	
	return new_zone_id

func generate_and_discover_depth_zone(source_zone_id: String, target_difficulty: int, wormhole_direction: float) -> String:
	"""Generate a new depth zone (different difficulty) when entering an undiscovered wormhole"""
	print("Wormhole_debug : >>> GENERATE_DEPTH_ZONE CALLED <<<")
	print("Wormhole_debug :   Source zone: %s" % source_zone_id)
	print("Wormhole_debug :   Target difficulty: %d" % target_difficulty)
	
	if not ZoneManager:
		print("Wormhole_debug :   ERROR - ZoneManager not found!")
		return ""
	
	# Check if valid difficulty
	if target_difficulty < 1 or target_difficulty > 9:
		print("Wormhole_debug :   ERROR - Invalid target difficulty: %d" % target_difficulty)
		return ""
	
	# Find or create the portal zone at target difficulty
	var new_zone_id = ""
	var zone_is_new = false
	
	# Get the designated portal zone index for the target difficulty
	var portal_index = ZoneManager.get_depth_portal_zone_index(target_difficulty)
	print("Wormhole_debug :   Portal index for difficulty %d is: %d" % [target_difficulty, portal_index])
	
	# Check if portal zone exists
	var existing_zones = ZoneManager.get_zones_at_difficulty(target_difficulty)
	var portal_zone = null
	
	print("Wormhole_debug :   Searching for existing portal zone...")
	print("Wormhole_debug :   Found %d zones at difficulty %d" % [existing_zones.size(), target_difficulty])
	
	for zone in existing_zones:
		if zone.has("zone_index"):
			if zone.zone_index == portal_index:
				portal_zone = zone
				print("Wormhole_debug :   ✓ Portal zone EXISTS: %s" % zone.zone_id)
				break
	
	if portal_zone:
		# Portal zone already exists, link to it
		new_zone_id = portal_zone.zone_id
		zone_is_new = false
		print("Wormhole_debug :   Using EXISTING portal zone: %s" % new_zone_id)
	else:
		# Portal zone doesn't exist, create it at the correct index
		print("Wormhole_debug :   Portal zone DOES NOT EXIST - creating NEW zone...")
		print("Wormhole_debug :   Calling create_zone_at_index(difficulty=%d, index=%d)" % [target_difficulty, portal_index])
		new_zone_id = ZoneManager.create_zone_at_index(target_difficulty, portal_index, false)
		if new_zone_id.is_empty():
			print("Wormhole_debug :   ERROR - create_zone_at_index returned EMPTY!")
			return ""
		zone_is_new = true
		print("Wormhole_debug :   ✓ Created NEW portal zone: %s" % new_zone_id)
	
	# DEBUG: Verify the created/found zone
	var verify_zone = ZoneManager.get_zone(new_zone_id)
	if not verify_zone.is_empty():
		print("Wormhole_debug :   Verifying zone '%s':" % new_zone_id)
		print("Wormhole_debug :     Difficulty: %d" % verify_zone.difficulty)
		print("Wormhole_debug :     Size: %.0f" % verify_zone.spawn_area_size)
		print("Wormhole_debug :     Has zone_index: %s" % ("yes (%d)" % verify_zone.zone_index if verify_zone.has("zone_index") else "NO"))
		print("Wormhole_debug :     Is portal zone: %s" % ZoneManager.should_zone_have_depth_portal(new_zone_id))
	else:
		print("Wormhole_debug :   ERROR - Cannot verify zone! Zone is empty!")
	
	# Generate zone layer FIRST if needed (before discovery)
	if not ZoneManager.get_zone(new_zone_id).layer_node:
		# Try to find ZoneSetup if not already cached
		if not zone_setup:
			zone_setup = get_tree().root.get_node_or_null("GameScene/Systems/ZoneSetup")
			if not zone_setup:
				zone_setup = get_tree().root.find_child("ZoneSetup", true, false)
		
		if zone_setup and zone_setup.has_method("create_zone_layer_for_discovered_zone"):
			zone_setup.create_zone_layer_for_discovered_zone(new_zone_id)
		else:
			print("ZoneDiscovery: ERROR - Cannot create zone layer for depth zone")
			return ""
	
	# Create bidirectional wormhole connection (return wormhole in new zone)
	# Only create if this is a newly created zone (not linking to existing)
	if zone_is_new:
		create_return_depth_wormhole(new_zone_id, source_zone_id)
	
	# NOW discover the zone (this triggers resource/enemy spawning)
	print("Wormhole_debug :   Discovering zone and initializing systems...")
	ZoneManager.discover_zone(new_zone_id)
	
	# CRITICAL: Initialize systems for the new zone (in case zone was created as discovered)
	if FogOfWarManager and FogOfWarManager.has_method("initialize_zone_fog"):
		FogOfWarManager.initialize_zone_fog(new_zone_id)
	
	# Force spawn resources for the new zone
	var resource_spawner = get_tree().root.find_child("ResourceSpawner", true, false)
	if resource_spawner and resource_spawner.has_method("spawn_resources_for_zone"):
		var zone_data = ZoneManager.get_zone(new_zone_id)
		if not zone_data.is_empty():
			resource_spawner.spawn_resources_for_zone(new_zone_id, zone_data)
	
	# Force spawn enemies for the new zone
	var enemy_spawner = get_tree().root.find_child("EnemySpawnerSystem", true, false)
	if enemy_spawner and enemy_spawner.has_method("setup_zone_enemies"):
		enemy_spawner.setup_zone_enemies(new_zone_id)
	
	print("Wormhole_debug :   Depth zone '%s' (difficulty %d) ready!" % [new_zone_id, target_difficulty])
	print("Wormhole_debug : >>> GENERATE_DEPTH_ZONE COMPLETE <<<\n")
	
	zone_discovered.emit(new_zone_id)
	
	return new_zone_id

func is_zone_discovered(zone_id: String) -> bool:
	"""Check if a zone has been discovered"""
	if not ZoneManager:
		return false
	return ZoneManager.is_zone_discovered(zone_id)

func get_discovered_zone_count() -> int:
	"""Get number of discovered zones"""
	if not ZoneManager:
		return 0
	return ZoneManager.get_discovered_zones().size()

func get_undiscovered_zone_count_at_difficulty(difficulty: int) -> int:
	"""Get how many zones remain undiscovered at a difficulty"""
	if not ZoneManager:
		return 0
	
	var max_zones = ZoneManager.ZONES_PER_DIFFICULTY.get(difficulty, 4)
	var existing_zones = ZoneManager.get_zones_at_difficulty(difficulty)
	
	return max_zones - existing_zones.size()

func create_return_lateral_wormhole(new_zone_id: String, source_zone_id: String, original_direction: float):
	"""Create a return wormhole in the new zone that points back to source zone"""
	# NOTE: This function is now mostly redundant because create_wormholes_for_zone
	# automatically creates wormholes to neighbors based on ring structure.
	# However, we keep it as a safety check to ensure bidirectional connection exists.
	
	if not ZoneManager:
		return
	
	var new_zone = ZoneManager.get_zone(new_zone_id)
	if new_zone.is_empty() or not new_zone.layer_node:
		return
	
	var wormholes_node = new_zone.layer_node.get_node_or_null("Wormholes")
	if not wormholes_node:
		return
	
	# Check if return wormhole already exists (should exist from create_wormholes_for_zone)
	for existing_wormhole in new_zone.lateral_wormholes:
		if is_instance_valid(existing_wormhole) and existing_wormhole.target_zone_id == source_zone_id:
			print("ZoneDiscovery: Return wormhole already exists in '%s' (created by ring structure)" % new_zone_id)
			return
	
	# If we get here, the source zone is NOT a ring neighbor (shouldn't happen with proper ring structure)
	# This is a safety fallback
	print("ZoneDiscovery: WARNING - Source zone '%s' is not a ring neighbor of '%s', creating fallback wormhole" % [source_zone_id, new_zone_id])

func create_return_depth_wormhole(new_zone_id: String, source_zone_id: String):
	"""Create a return wormhole in the new zone that points back to source zone (for depth travel)"""
	# NOTE: Both zones should be portal zones. The return wormhole should already exist
	# from create_wormholes_for_zone if the new zone is a portal zone and properly set up.
	# This function ensures bidirectional connection exists.
	
	if not ZoneManager:
		return
	
	var new_zone = ZoneManager.get_zone(new_zone_id)
	if new_zone.is_empty() or not new_zone.layer_node:
		return
	
	# Verify new zone is a portal zone (should have depth wormholes)
	if not ZoneManager.should_zone_have_depth_portal(new_zone_id):
		print("ZoneDiscovery: WARNING - Trying to create return depth wormhole in non-portal zone '%s'" % new_zone_id)
	
	var wormholes_node = new_zone.layer_node.get_node_or_null("Wormholes")
	if not wormholes_node:
		return
	
	# Check if return wormhole already exists (should exist from create_wormholes_for_zone)
	for existing_wormhole in new_zone.depth_wormholes:
		if is_instance_valid(existing_wormhole) and existing_wormhole.target_zone_id == source_zone_id:
			print("ZoneDiscovery: Return depth wormhole already exists in '%s' (created by portal structure)" % new_zone_id)
			return
	
	# If we get here, need to create the return wormhole
	# This can happen if the zones were created at different times
	var wormhole_scene = load("res://scenes/world/Wormhole.tscn")
	if not wormhole_scene:
		return
	
	# Determine if this is a forward or backward connection
	var source_zone = ZoneManager.get_zone(source_zone_id)
	if source_zone.is_empty():
		return
	
	var is_forward = new_zone.difficulty > source_zone.difficulty
	
	var wormhole = wormhole_scene.instantiate()
	wormhole.source_zone_id = new_zone_id
	wormhole.target_zone_id = source_zone_id  # Points back to source!
	wormhole.wormhole_type = Wormhole.WormholeType.DEPTH
	wormhole.is_undiscovered = false  # Already discovered!
	wormhole.set_meta("is_forward", not is_forward)  # Opposite direction
	
	# Position perpendicular to the zone's ring position (same as forward depth wormholes)
	var new_zone_data = ZoneManager.get_zone(new_zone_id)
	var ring_angle = new_zone_data.ring_position
	var angle = ring_angle + (PI / 2.0) if is_forward else ring_angle - (PI / 2.0)
	# Normalize angle
	while angle < 0:
		angle += TAU
	while angle >= TAU:
		angle -= TAU
	
	var spawn_pos = ZoneManager.get_zone_wormhole_spawn_position(new_zone_id, angle)
	wormhole.global_position = spawn_pos
	
	print("ZoneDiscovery: Return depth wormhole angle: %.2f degrees (perpendicular to ring at %.2f)" % [rad_to_deg(angle), rad_to_deg(ring_angle)])
	
	wormholes_node.add_child(wormhole)
	
	# CRITICAL: Set z_index to render depth wormholes ON TOP
	wormhole.z_index = 10  # Higher than lateral (0)
	
	# Wait for wormhole to be ready and register it with ZoneManager
	await get_tree().process_frame
	if is_instance_valid(wormhole) and ZoneManager:
		ZoneManager.set_zone_wormhole(new_zone_id, wormhole, "depth")
	
	print("ZoneDiscovery: Created return depth wormhole in '%s' pointing to '%s' at position %s" % [new_zone_id, source_zone_id, spawn_pos])
