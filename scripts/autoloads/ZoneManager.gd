extends Node
## Manages dynamic zone network in spiral galaxy

signal zone_switched(from_zone_id: String, to_zone_id: String)
signal unit_transferred(unit: Node2D, from_zone_id: String, to_zone_id: String)
signal zones_initialized()
signal zone_discovered(zone_id: String)

# Zone data structure - now supports dynamic generation
var zones_by_id: Dictionary = {}  # zone_id (String) -> zone Dictionary
var current_zone_id: String = ""
var zones_ready: bool = false

# Zone network seed for procedural generation
var zone_network_seed: int = 0

# Base spawn area for zones (4000x4000)
const BASE_ZONE_SIZE: float = 4000.0

# Zones per difficulty ring (outer rings have more zones)
const ZONES_PER_DIFFICULTY: Dictionary = {
	1: 8,  # Outer ring
	2: 6,
	3: 6,
	4: 4,
	5: 4,
	6: 4,
	7: 3,
	8: 3,
	9: 2   # Center
}

# Name generation word lists
const NAME_PREFIXES: Array[String] = ["Outer", "Inner", "Deep", "Frontier", "Edge", "Core", "Void", "Stellar"]
const NAME_TYPES: Array[String] = ["Sector", "Region", "Expanse", "Territory", "Zone", "Quadrant", "Nebula"]
const NAME_SUFFIXES: Array[String] = ["Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Crimson", "Azure", "North", "South", "East", "West"]

func _ready():
	print("ZoneManager: _ready() called")
	process_mode = Node.PROCESS_MODE_ALWAYS
	initialize_zones()
	print("ZoneManager: _ready() complete")

func initialize_zones():
	"""Initialize zone system - create first zone only, rest generated on-demand"""
	print("ZoneManager: initialize_zones() called")
	zones_by_id.clear()
	
	# Generate network seed
	generate_zone_network_seed()
	
	# Create initial starting zone at difficulty 1
	current_zone_id = create_initial_zone(1)
	print("ZoneManager: Initial zone created: '%s'" % current_zone_id)
	print("ZoneManager: zones_by_id has %d zones" % zones_by_id.size())
	
	

## Zone Network Generation

func generate_zone_network_seed():
	"""Generate or reuse zone network seed for procedural generation"""
	if zone_network_seed == 0:
		zone_network_seed = randi()
	print("ZoneManager: Zone network seed: %d" % zone_network_seed)

func create_initial_zone(difficulty: int) -> String:
	"""Create the first zone at a given difficulty level (at index 0)"""
	return create_zone_at_index(difficulty, 0, true)

func create_zone_at_index(difficulty: int, zone_index: int, discovered: bool = false) -> String:
	"""Create a zone at a specific index on its ring"""
	# Validate zone_index
	var max_zones = ZONES_PER_DIFFICULTY.get(difficulty, 4)
	if zone_index < 0 or zone_index >= max_zones:
		push_error("ZoneManager: Invalid zone_index %d for difficulty %d (max: %d)" % [zone_index, difficulty, max_zones])
		return ""
	
	# Check if zone at this index already exists
	var existing_zones = get_zones_at_difficulty(difficulty)
	for zone in existing_zones:
		if zone.zone_index == zone_index:
			print("ZoneManager: Zone at difficulty %d, index %d already exists: '%s'" % [difficulty, zone_index, zone.zone_id])
			return zone.zone_id
	
	# Create unique zone ID
	var zone_id = ""
	if zone_index == 0:
		zone_id = "d%d_start" % difficulty
	else:
		zone_id = "d%d_zone_%d" % [difficulty, zone_index]
	
	var zone = create_zone_data(zone_id, difficulty, zone_index, discovered)
	zones_by_id[zone_id] = zone
	
	print("ZoneManager: Created zone '%s' at difficulty %d, index %d" % [zone_id, difficulty, zone_index])
	return zone_id

func generate_lateral_zone(difficulty: int, source_zone_id: String, direction_angle: float, target_zone_index: int = -1) -> String:
	"""Generate a new lateral zone at the same difficulty"""
	# If target_zone_index is provided, use it; otherwise calculate sequentially
	var zone_index = target_zone_index
	
	if zone_index == -1:
		# Fallback: use sequential indexing (old behavior)
		var existing_zones = get_zones_at_difficulty(difficulty)
		zone_index = existing_zones.size()
		print("ZoneManager: WARNING - No target_zone_index provided, using sequential: %d" % zone_index)
	else:
		print("ZoneManager: Creating lateral zone at specified index: %d" % zone_index)
	
	# Check if ring is full
	var max_zones = ZONES_PER_DIFFICULTY.get(difficulty, 4)
	if zone_index >= max_zones:
		push_warning("ZoneManager: Cannot generate lateral zone - ring %d is full (%d/%d zones)" % [difficulty, zone_index, max_zones])
		return ""
	
	# Check if zone at this index already exists
	var existing_zones = get_zones_at_difficulty(difficulty)
	for zone in existing_zones:
		if zone.zone_index == zone_index:
			print("ZoneManager: Zone at difficulty %d, index %d already exists: '%s'" % [difficulty, zone_index, zone.zone_id])
			return zone.zone_id
	
	# Create unique zone ID
	var zone_id = "d%d_zone_%d" % [difficulty, zone_index]
	
	var zone = create_zone_data(zone_id, difficulty, zone_index, false)
	zones_by_id[zone_id] = zone
	
	print("ZoneManager: Generated lateral zone '%s' at difficulty %d (index %d)" % [zone_id, difficulty, zone_index])
	return zone_id

func create_zone_data(zone_id: String, difficulty: int, zone_index: int, discovered: bool) -> Dictionary:
	"""Create zone data structure"""
	# Calculate deterministic ring position from zone index
	var ring_position = get_zone_angle(difficulty, zone_index)
	
	var zone = {
		"zone_id": zone_id,
		"difficulty": difficulty,
		"zone_index": zone_index,  # New: deterministic position on ring
		"procedural_name": get_zone_procedural_name(zone_id, difficulty),
		"discovered": discovered,
		"ring_position": ring_position,
		"size_multiplier": float(difficulty),
		"spawn_area_size": BASE_ZONE_SIZE * float(difficulty),
		"boundaries": calculate_zone_boundaries(difficulty),
		"layer_node": null,
		"lateral_wormholes": [],
		"depth_wormholes": [],
		"max_resource_tier": difficulty - 1,
	}
	return zone

func get_zone_procedural_name(zone_id: String, difficulty: int) -> String:
	"""Generate procedural name from zone_id using seed"""
	# Hash zone_id with seed for deterministic generation
	var hash_value = zone_id.hash() ^ zone_network_seed
	
	# Select words from lists
	var prefix_idx = abs(hash_value) % NAME_PREFIXES.size()
	var type_idx = abs(hash_value >> 8) % NAME_TYPES.size()
	var suffix_idx = abs(hash_value >> 16) % NAME_SUFFIXES.size()
	
	# Adjust prefix based on difficulty
	if difficulty <= 3:
		prefix_idx = min(prefix_idx, 3)  # Favor "Outer", "Inner", "Deep", "Frontier"
	elif difficulty >= 7:
		prefix_idx = max(prefix_idx, 4)  # Favor "Edge", "Core", "Void", "Stellar"
	
	return "%s %s %s" % [NAME_PREFIXES[prefix_idx], NAME_TYPES[type_idx], NAME_SUFFIXES[suffix_idx]]

func calculate_zone_boundaries(difficulty: int) -> Rect2:
	"""Calculate rectangular boundaries for a zone based on difficulty"""
	var size = BASE_ZONE_SIZE * float(difficulty)
	var half_size = size / 2.0
	return Rect2(-half_size, -half_size, size, size)

func get_zone_angle(difficulty: int, zone_index: int) -> float:
	"""Calculate fixed angle for a zone on its ring based on its index"""
	var zones_on_ring = ZONES_PER_DIFFICULTY.get(difficulty, 4)
	if zones_on_ring <= 0:
		return 0.0
	
	# Validate zone_index
	if zone_index < 0 or zone_index >= zones_on_ring:
		push_warning("ZoneManager: Invalid zone_index %d for difficulty %d (max: %d)" % [zone_index, difficulty, zones_on_ring])
		return 0.0
	
	# Evenly distribute zones around the ring
	var angle = (float(zone_index) / float(zones_on_ring)) * TAU
	return angle

func get_depth_portal_zone_index(difficulty: int) -> int:
	"""Determine which zone index on a ring gets the purple wormhole"""
	# Use seed-based selection for variety, but deterministic
	var hash_value = (difficulty * 17) ^ zone_network_seed
	var zones_on_ring = ZONES_PER_DIFFICULTY.get(difficulty, 4)
	return abs(hash_value) % zones_on_ring

func should_zone_have_depth_portal(zone_id: String) -> bool:
	"""Check if this zone is the designated portal zone for its ring"""
	var zone = get_zone(zone_id)
	if zone.is_empty():
		return false
	
	# Check if zone has zone_index (backward compatibility)
	if not zone.has("zone_index"):
		push_warning("ZoneManager: Zone '%s' missing zone_index! Cannot determine portal status." % zone_id)
		return false
	
	var portal_index = get_depth_portal_zone_index(zone.difficulty)
	return zone.zone_index == portal_index

## Zone Access and Management

func get_zone(zone_id: String) -> Dictionary:
	"""Get zone data by ID"""
	return zones_by_id.get(zone_id, {})

func get_current_zone() -> Dictionary:
	"""Get the currently active zone"""
	return get_zone(current_zone_id)

func get_zones_at_difficulty(difficulty: int) -> Array:
	"""Get all zones at a specific difficulty level"""
	var result = []
	for zone in zones_by_id.values():
		if zone.difficulty == difficulty:
			result.append(zone)
	return result

func get_zones_at_difficulty_sorted(difficulty: int) -> Array:
	"""Get all zones at a specific difficulty level, sorted by zone_index"""
	var zones = get_zones_at_difficulty(difficulty)
	# Sort only zones that have zone_index
	zones.sort_custom(func(a, b): 
		var a_idx = a.zone_index if a.has("zone_index") else 0
		var b_idx = b.zone_index if b.has("zone_index") else 0
		return a_idx < b_idx
	)
	return zones

func get_zone_neighbors(zone_id: String) -> Dictionary:
	"""Get left and right neighbor zone IDs on the same ring"""
	var zone = get_zone(zone_id)
	if zone.is_empty():
		return {"left": "", "right": ""}
	
	# Check if zone has zone_index (might not if it's from old save or wasn't migrated)
	if not zone.has("zone_index"):
		push_warning("ZoneManager: Zone '%s' missing zone_index! Cannot determine neighbors." % zone_id)
		return {"left": "", "right": ""}
	
	var difficulty = zone.difficulty
	var zone_index = zone.zone_index
	var zones_on_ring = ZONES_PER_DIFFICULTY.get(difficulty, 4)
	
	# Calculate neighbor indices with wrapping
	var left_index = (zone_index - 1 + zones_on_ring) % zones_on_ring
	var right_index = (zone_index + 1) % zones_on_ring
	
	# Find zones with these indices (they might not exist yet)
	var left_zone_id = ""
	var right_zone_id = ""
	
	var zones_at_diff = get_zones_at_difficulty(difficulty)
	for z in zones_at_diff:
		if z.zone_index == left_index:
			left_zone_id = z.zone_id
		elif z.zone_index == right_index:
			right_zone_id = z.zone_id
	
	return {"left": left_zone_id, "right": right_zone_id}

func get_discovered_zones() -> Array[String]:
	"""Get list of all discovered zone IDs"""
	var result: Array[String] = []
	for zone_id in zones_by_id:
		if zones_by_id[zone_id].discovered:
			result.append(zone_id)
	return result

func get_undiscovered_neighbors(zone_id: String) -> Array[Dictionary]:
	"""Get neighboring zones that are undiscovered (only shows connected wormholes)"""
	var neighbors: Array[Dictionary] = []
	var zone = get_zone(zone_id)
	if zone.is_empty():
		return neighbors
	
	# Check lateral wormholes
	for wormhole in zone.lateral_wormholes:
		if is_instance_valid(wormhole):
			var target_id = wormhole.target_zone_id
			if target_id and not zones_by_id.has(target_id):
				neighbors.append({"zone_id": target_id, "type": "lateral", "wormhole": wormhole})
	
	# Check depth wormholes
	for wormhole in zone.depth_wormholes:
		if is_instance_valid(wormhole):
			var target_id = wormhole.target_zone_id
			if target_id and not zones_by_id.has(target_id):
				neighbors.append({"zone_id": target_id, "type": "depth", "wormhole": wormhole})
	
	return neighbors

func discover_zone(zone_id: String):
	"""Mark a zone as discovered"""
	if zone_id in zones_by_id and not zones_by_id[zone_id].discovered:
		zones_by_id[zone_id].discovered = true
		zone_discovered.emit(zone_id)
		print("ZoneManager: Zone '%s' discovered!" % zones_by_id[zone_id].procedural_name)

func is_zone_discovered(zone_id: String) -> bool:
	"""Check if a zone has been discovered"""
	var zone = get_zone(zone_id)
	return not zone.is_empty() and zone.discovered

func switch_to_zone(zone_id: String) -> bool:
	"""Switch camera view to a different zone"""
	if not zones_by_id.has(zone_id):
		print("ZoneManager: switch_to_zone - Zone %s not found!" % zone_id)
		return false
	
	if zone_id == current_zone_id:
		print("ZoneManager: switch_to_zone - Already in zone %s" % zone_id)
		return false
	
	var old_zone = current_zone_id
	current_zone_id = zone_id
	print("ZoneManager: switch_to_zone - Switching from %s to %s" % [old_zone, zone_id])
	
	# Update zone visibility
	update_zone_visibility()
	
	# Update camera bounds
	var new_zone = get_zone(zone_id)
	if new_zone.is_empty():
		return false
	
	# Notify camera system
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("set_zone_bounds"):
		camera.set_zone_bounds(new_zone.boundaries)
	
	zone_switched.emit(old_zone, zone_id)
	
	return true

func update_zone_visibility():
	"""Update visibility and processing of zone layers"""
	print("ZoneManager: update_zone_visibility() - Current zone: %s" % current_zone_id)
	for zone in zones_by_id.values():
		if zone.layer_node and is_instance_valid(zone.layer_node):
			var is_active = (zone.zone_id == current_zone_id)
			zone.layer_node.visible = is_active
			
			# IMPORTANT: Disable processing for inactive zones to save performance
			if is_active:
				zone.layer_node.process_mode = Node.PROCESS_MODE_INHERIT
			else:
				zone.layer_node.process_mode = Node.PROCESS_MODE_DISABLED
			
			print("  - Zone %s: visible=%s, process_mode=%s" % [zone.zone_id, is_active, "INHERIT" if is_active else "DISABLED"])

func set_zone_layer(zone_id: String, layer_node: Node2D):
	"""Associate a zone with its scene layer node"""
	if zone_id in zones_by_id:
		zones_by_id[zone_id].layer_node = layer_node
		print("ZoneManager: set_zone_layer - Zone '%s' now has layer_node: %s" % [zone_id, layer_node.name])
	else:
		print("ZoneManager: set_zone_layer - ERROR: Zone '%s' not found in zones_by_id!" % zone_id)

func set_zone_wormhole(zone_id: String, wormhole: Node2D, wormhole_type: String = "depth"):
	"""Add a wormhole to a zone"""
	if zone_id in zones_by_id:
		if wormhole_type == "lateral":
			if wormhole not in zones_by_id[zone_id].lateral_wormholes:
				zones_by_id[zone_id].lateral_wormholes.append(wormhole)
		else:  # depth
			if wormhole not in zones_by_id[zone_id].depth_wormholes:
				zones_by_id[zone_id].depth_wormholes.append(wormhole)

func transfer_units_to_zone(units: Array, target_zone_id: String, spawn_position: Vector2):
	"""Transfer units from current zone to target zone"""
	var target_zone = get_zone(target_zone_id)
	if target_zone.is_empty():
		print("ZoneManager: Cannot transfer units - target zone '%s' not found!" % target_zone_id)
		return
	
	if not target_zone.layer_node:
		print("ZoneManager: Cannot transfer units - target zone '%s' has no layer_node!" % target_zone_id)
		return
	
	print("ZoneManager: Transferring %d units to zone '%s'" % [units.size(), target_zone_id])
	
	for unit in units:
		if not is_instance_valid(unit):
			continue
		
		var old_zone_id = get_unit_zone(unit)
		
		# Reparent to target zone's Units container
		var target_units_node = target_zone.layer_node.get_node_or_null("Entities/Units")
		if target_units_node:
			# Calculate random offset near spawn position
			var random_offset = Vector2(
				randf_range(-100, 100),
				randf_range(-100, 100)
			)
			var new_position = spawn_position + random_offset
			
			# Store old parent for reparenting
			var old_parent = unit.get_parent()
			
			# Reparent unit
			old_parent.remove_child(unit)
			target_units_node.add_child(unit)
			unit.global_position = new_position
			
			# Update EntityManager
			if EntityManager.has_method("update_unit_zone"):
				EntityManager.update_unit_zone(unit, old_zone_id, target_zone_id)
			
			unit_transferred.emit(unit, old_zone_id, target_zone_id)
		
func get_unit_zone(unit: Node2D) -> String:
	"""Get which zone a unit is currently in"""
	for zone in zones_by_id.values():
		if zone.layer_node and is_instance_valid(zone.layer_node):
			if zone.layer_node.is_ancestor_of(unit):
				return zone.zone_id
	return current_zone_id  # Default to current zone

func get_zone_count() -> int:
	"""Get total number of generated zones"""
	return zones_by_id.size()

func is_valid_zone(zone_id: String) -> bool:
	"""Check if zone ID is valid"""
	return zones_by_id.has(zone_id)

func get_zone_wormhole_spawn_position(zone_id: String, angle: float) -> Vector2:
	"""Get position at the edge of a zone for wormhole placement"""
	var zone = get_zone(zone_id)
	if zone.is_empty():
		return Vector2.ZERO
	
	var bounds = zone.boundaries
	
	# Calculate position on perimeter based on angle (angle must be provided)
	var edge_distance = bounds.size.x / 2.0 * 0.9  # 90% of zone radius
	var position = Vector2(
		cos(angle) * edge_distance,
		sin(angle) * edge_distance
	)
	
	return position

func mark_zones_initialized():
	"""Called by ZoneSetup when all zones are ready"""
	zones_ready = true
	print("ZoneManager: mark_zones_initialized - Emitting zones_initialized signal")
	zones_initialized.emit()
	print("ZoneManager: zones_ready is now TRUE")
	

## Zone Statistics and Helpers

func get_zone_statistics(zone_id: String) -> Dictionary:
	"""Get comprehensive statistics for a zone"""
	var zone = get_zone(zone_id)
	if zone.is_empty():
		return {}
	
	var max_tier = zone.difficulty - 1
	var available_tiers = range(0, max_tier + 1)
	
	# Count resources in this zone
	var resource_count = 0
	if EntityManager:
		var zone_resources = EntityManager.get_resources_in_zone(zone_id)
		resource_count = zone_resources.size()
	
	# Calculate resource type count (how many unique types can spawn)
	var resource_types_count = 0
	for tier in available_tiers:
		resource_types_count += ResourceDatabase.get_resources_by_tier(tier).size()
	
	# Calculate rarity distribution
	var distribution = calculate_rarity_distribution(zone.difficulty)
	
	return {
		"zone_id": zone_id,
		"zone_name": zone.procedural_name,
		"difficulty": zone.difficulty,
		"size_multiplier": zone.size_multiplier,
		"max_tier": max_tier,
		"available_tiers": available_tiers,
		"resource_types_count": resource_types_count,
		"total_asteroids": resource_count,
		"rarity_distribution": distribution,
		"estimated_value": calculate_zone_value_rating(zone.difficulty)
	}

func calculate_rarity_distribution(difficulty: int) -> Dictionary:
	"""Calculate percentage distribution of resource rarities"""
	var max_tier = difficulty - 1
	
	# Tier groupings: Common (0-2), Uncommon (3-5), Rare (6-7), Ultra-Rare (8-9)
	var common_weight = 0.0
	var uncommon_weight = 0.0
	var rare_weight = 0.0
	var ultra_rare_weight = 0.0
	
	for tier in range(0, max_tier + 1):
		var weight = ResourceDatabase.TIER_WEIGHTS.get(tier, 0.0)
		if tier <= 2:
			common_weight += weight
		elif tier <= 5:
			uncommon_weight += weight
		elif tier <= 7:
			rare_weight += weight
		else:
			ultra_rare_weight += weight
	
	var total = common_weight + uncommon_weight + rare_weight + ultra_rare_weight
	
	if total == 0:
		return {"common": 100, "uncommon": 0, "rare": 0, "ultra_rare": 0}
	
	return {
		"common": int((common_weight / total) * 100),
		"uncommon": int((uncommon_weight / total) * 100),
		"rare": int((rare_weight / total) * 100),
		"ultra_rare": int((ultra_rare_weight / total) * 100)
	}

func calculate_zone_value_rating(difficulty: int) -> int:
	"""Calculate 1-5 star rating for zone based on available tiers"""
	var max_tier = difficulty - 1
	
	# Simple rating based on max tier
	if max_tier >= 8:
		return 5  # ★★★★★
	elif max_tier >= 6:
		return 4  # ★★★★☆
	elif max_tier >= 4:
		return 3  # ★★★☆☆
	elif max_tier >= 2:
		return 2  # ★★☆☆☆
	else:
		return 1  # ★☆☆☆☆

func get_player_presence_in_zone(zone_id: String) -> Dictionary:
	"""Check if player has units/buildings in this zone"""
	var zone = get_zone(zone_id)
	if zone.is_empty() or not zone.layer_node:
		return {"has_units": false, "has_buildings": false}
	
	var has_units = false
	var has_buildings = false
	
	# Check for units
	var units_node = zone.layer_node.get_node_or_null("Entities/Units")
	if units_node and units_node.get_child_count() > 0:
		has_units = true
	
	# Check for buildings
	var buildings_node = zone.layer_node.get_node_or_null("Entities/Buildings")
	if buildings_node and buildings_node.get_child_count() > 0:
		has_buildings = true
	
	return {"has_units": has_units, "has_buildings": has_buildings}

func reset():
	"""Reset zone manager state for starting a fresh game"""
	zones_by_id.clear()
	current_zone_id = ""
	zones_ready = false
	zone_network_seed = 0
	
	# Reinitialize
	initialize_zones()

## Debug Functions

func debug_print_current_zone_info():
	"""Print detailed information about the current zone"""
	var zone = get_current_zone()
	if zone.is_empty():
		print("DEBUG: No current zone!")
		return
	
	print("\n=== CURRENT ZONE INFO ===")
	print("  Zone ID: %s" % zone.zone_id)
	print("  Name: %s" % zone.procedural_name)
	print("  Difficulty: %d" % zone.difficulty)
	print("  Zone Index: %s" % (str(zone.zone_index) if zone.has("zone_index") else "MISSING"))
	print("  Size: %.0f x %.0f" % [zone.spawn_area_size, zone.spawn_area_size])
	print("  Boundaries: %s" % zone.boundaries)
	print("  Is Portal: %s" % should_zone_have_depth_portal(zone.zone_id))
	print("  Total Wormholes: %d (%d lateral + %d depth)" % [
		zone.lateral_wormholes.size() + zone.depth_wormholes.size(),
		zone.lateral_wormholes.size(),
		zone.depth_wormholes.size()
	])
	
	# List ALL wormholes with details
	print("\n  --- ALL WORMHOLES IN THIS ZONE ---")
	
	var wormhole_count = 1
	if zone.lateral_wormholes.size() > 0:
		print("  LATERAL Wormholes (BLUE/CYAN):")
		for wh in zone.lateral_wormholes:
			if is_instance_valid(wh):
				var target = "(undiscovered)" if wh.target_zone_id.is_empty() else wh.target_zone_id
				print("    [%d] BLUE at position %s → %s" % [wormhole_count, wh.global_position, target])
				wormhole_count += 1
	
	if zone.depth_wormholes.size() > 0:
		print("  DEPTH Wormholes (PURPLE):")
		for wh in zone.depth_wormholes:
			if is_instance_valid(wh):
				var target = "(undiscovered)" if wh.target_zone_id.is_empty() else wh.target_zone_id
				var direction = "forward" if wh.get_meta("is_forward", true) else "backward"
				var type_check = wh.wormhole_type
				print("    [%d] PURPLE at position %s → %s (%s) [type=%d]" % [wormhole_count, wh.global_position, target, direction, type_check])
				if type_check != 0:
					print("        *** ERROR *** Depth wormhole has wrong type! Should be 0, is %d" % type_check)
				wormhole_count += 1
	else:
		print("  NO DEPTH WORMHOLES! (This is the problem if this is a portal zone)")
	
	print("  -----------------------------------")
	print("========================\n")

func debug_print_all_zones():
	"""Print information about all discovered zones"""
	print("\n=== ALL DISCOVERED ZONES ===")
	for difficulty in range(1, 10):
		var zones = get_zones_at_difficulty_sorted(difficulty)
		if zones.is_empty():
			continue
		
		var portal_index = get_depth_portal_zone_index(difficulty)
		print("\nDifficulty %d (%d zones, portal at index %d):" % [difficulty, zones.size(), portal_index])
		for zone in zones:
			var is_portal = should_zone_have_depth_portal(zone.zone_id)
			var portal_str = " [PORTAL]" if is_portal else ""
			var discovered_str = " (discovered)" if zone.discovered else " (undiscovered)"
			var zone_idx_str = str(zone.zone_index) if zone.has("zone_index") else "MISSING"
			print("  %s (index %s, size %.0f)%s%s" % [
				zone.zone_id, zone_idx_str, 
				zone.spawn_area_size, portal_str, discovered_str
			])
	print("============================\n")
