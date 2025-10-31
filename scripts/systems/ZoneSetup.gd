extends Node
## Helper script to setup zone structure in GameScene

@onready var wormhole_scene = preload("res://scenes/world/Wormhole.tscn")
@onready var planet_scene = preload("res://scenes/world/Planet.tscn")

var world_layer: Node2D

# Planet texture paths
var planet_textures: Array[String] = [
	"res://assets/sprites/Planets/planet1.png",
	"res://assets/sprites/Planets/planet2.png",
	"res://assets/sprites/Planets/planet3.png",
	"res://assets/sprites/Planets/planet4.png",
	"res://assets/sprites/Planets/planet5.png",
	"res://assets/sprites/Planets/planet6.png",
	"res://assets/sprites/Planets/planet7.png",
	"res://assets/sprites/Planets/planet8.png",
	"res://assets/sprites/Planets/planet9.png",
	"res://assets/sprites/Planets/planet10.png",
	"res://assets/sprites/Planets/planet11.png",
	"res://assets/sprites/Planets/planet12.png",
	"res://assets/sprites/Planets/planet13.png",
	"res://assets/sprites/Planets/planet14.png",
	"res://assets/sprites/Planets/planet15.png",
]

func _ready():
	print("ZoneSetup: _ready() called")
	
	# Find WorldLayer in the scene
	world_layer = get_node("/root/GameScene/WorldLayer")
	if not world_layer:
		print("ZoneSetup: ERROR - WorldLayer not found!")
		return
	
	print("ZoneSetup: WorldLayer found")
	
	await get_tree().create_timer(0.05).timeout  # Wait for scene to fully initialize
	
	print("ZoneSetup: Setting up zone layers...")
	await setup_zone_layers()
	print("ZoneSetup: Zone layers setup complete!")
	
	# NOTE: Wormholes are created in create_zone_layer_for_discovered_zone()
	# Don't call setup_wormholes() here - it would create duplicates!
	
	# Show only Zone 1 initially
	print("ZoneSetup: Updating zone visibility...")
	ZoneManager.update_zone_visibility()
	
	# Notify that zones are ready
	print("ZoneSetup: Marking zones as initialized...")
	ZoneManager.mark_zones_initialized()
	print("ZoneSetup: Initialization complete!")


func setup_zone_layers():
	"""Create initial zone layer only - rest generated on-demand"""
	# Check if WorldLayer exists
	if not world_layer:
		print("ZoneSetup: setup_zone_layers - WorldLayer is null!")
		return
	
	# Check if zones already exist
	if world_layer.get_child_count() > 0:
		print("ZoneSetup: Found %d existing zone layers" % world_layer.get_child_count())
		
		# Check if we're loading from a save
		if SaveLoadManager and SaveLoadManager.is_loading_save:
			print("ZoneSetup: Loading from save - linking existing zones...")
			link_existing_zones()
			return
		else:
			# Clear old zones from previous session (not a save load)
			print("ZoneSetup: Clearing old zone layers from previous session...")
			for child in world_layer.get_children():
				child.queue_free()
			# Wait for nodes to be removed
			await get_tree().process_frame
	
	# Create only the initial starting zone (saves will call create_zone_layers_for_loaded_zones separately)
	if ZoneManager and not ZoneManager.current_zone_id.is_empty():
		print("ZoneSetup: Creating initial zone layer for: '%s'" % ZoneManager.current_zone_id)
		create_zone_layer_for_discovered_zone(ZoneManager.current_zone_id)
	else:
		print("ZoneSetup: ERROR - Cannot create zone layer!")
		if not ZoneManager:
			print("  ZoneManager is null!")
		elif ZoneManager.current_zone_id.is_empty():
			print("  current_zone_id is empty!")
		

func create_zone_layers_for_loaded_zones():
	"""Create zone layers for all zones loaded from save file"""
	print("ZoneSetup: create_zone_layers_for_loaded_zones() called!")
	
	if not ZoneManager:
		print("ZoneSetup: ERROR - ZoneManager not found!")
		return
	
	if not world_layer:
		print("ZoneSetup: ERROR - world_layer not found!")
		return
	
	var discovered_zones = ZoneManager.get_discovered_zones()
	print("ZoneSetup: Creating zone layers for %d loaded zones..." % discovered_zones.size())
	print("ZoneSetup: Discovered zones: %s" % str(discovered_zones))
	
	for zone_id in discovered_zones:
		# Check if layer already exists
		var zone = ZoneManager.get_zone(zone_id)
		if zone.is_empty():
			print("ZoneSetup: WARNING - Zone %s is empty!" % zone_id)
			continue
		
		if zone.layer_node == null:
			print("ZoneSetup: Creating layer for loaded zone: %s (no layer exists)" % zone_id)
			create_zone_layer_for_discovered_zone(zone_id)
		else:
			print("ZoneSetup: Zone %s already has layer: %s" % [zone_id, zone.layer_node.name])
	
	print("ZoneSetup: Finished creating layers for loaded zones")

func create_zone_layer_for_discovered_zone(zone_id: String):
	"""Create zone layer structure for a newly discovered zone"""
	if not world_layer or not ZoneManager:
		return
	
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty():
		return
	
	# Check if layer already exists
	var layer_name = "Zone_%s" % zone_id
	if world_layer.has_node(layer_name):
		return
	
	var zone_layer = Node2D.new()
	zone_layer.name = layer_name
	zone_layer.visible = (zone_id == ZoneManager.current_zone_id)
	world_layer.add_child(zone_layer)
	
	# Create Planets container (before entities for z-ordering)
	var planets = Node2D.new()
	planets.name = "Planets"
	zone_layer.add_child(planets)
	
	# Create Entities container
	var entities = Node2D.new()
	entities.name = "Entities"
	zone_layer.add_child(entities)
	
	# Create Units container
	var units = Node2D.new()
	units.name = "Units"
	entities.add_child(units)
	
	# Create Resources container
	var resources = Node2D.new()
	resources.name = "Resources"
	entities.add_child(resources)
	
	# Create Buildings container
	var buildings = Node2D.new()
	buildings.name = "Buildings"
	entities.add_child(buildings)
	
	# Create Wormholes container
	var wormholes = Node2D.new()
	wormholes.name = "Wormholes"
	zone_layer.add_child(wormholes)
	
	# Create navigation region for this zone
	var nav_region = create_navigation_region_for_zone(zone.difficulty)
	zone_layer.add_child(nav_region)
	
	# Create zone boundary
	var boundary = create_zone_boundary(zone_id, zone.boundaries)
	zone_layer.add_child(boundary)
	
	# Register with ZoneManager
	ZoneManager.set_zone_layer(zone_id, zone_layer)
	
	# Create planets for this zone
	create_planets_for_zone(zone_id)
	
	# Create wormholes
	create_wormholes_for_zone(zone_id)
	
	print("ZoneSetup: Created zone layer for '%s' (%s)" % [zone_id, zone.procedural_name])

func create_navigation_region_for_zone(difficulty: int) -> NavigationRegion2D:
	"""Create a NavigationRegion2D sized for the zone"""
	var nav_region = NavigationRegion2D.new()
	nav_region.name = "NavigationRegion2D"
	
	# Calculate bounds based on difficulty
	var size = ZoneManager.BASE_ZONE_SIZE * float(difficulty)
	var half_width = size / 2.0
	var half_height = size / 2.0
	
	# Create navigation polygon covering the entire zone
	var nav_poly = NavigationPolygon.new()
	
	# Define vertices as rectangle covering the zone
	var vertices = PackedVector2Array([
		Vector2(-half_width, -half_height),  # Top-left
		Vector2(half_width, -half_height),   # Top-right
		Vector2(half_width, half_height),    # Bottom-right
		Vector2(-half_width, half_height)    # Bottom-left
	])
	
	nav_poly.vertices = vertices
	nav_poly.add_outline(vertices)
	
	# Create the polygon (single quad covering entire zone)
	var polygon = PackedInt32Array([0, 1, 2, 3])
	nav_poly.add_polygon(polygon)
	
	nav_region.navigation_polygon = nav_poly
	
	return nav_region

func create_zone_boundary(zone_id: String, boundaries: Rect2) -> Node2D:
	"""Create boundary system for a zone"""
	var boundary_script = load("res://scripts/systems/ZoneBoundary.gd")
	var boundary = Node2D.new()
	boundary.name = "ZoneBoundary"
	boundary.set_script(boundary_script)
	
	# Setup boundary after it's added to tree
	boundary.call_deferred("setup_for_zone", zone_id, boundaries)
	
	return boundary

func link_existing_zones():
	"""Link existing zone layers to ZoneManager"""
	if not ZoneManager:
		return
	
	for child in world_layer.get_children():
		if child.name.begins_with("Zone_"):
			var zone_id = child.name.replace("Zone_", "")
			ZoneManager.set_zone_layer(zone_id, child)

func setup_wormholes():
	"""DEPRECATED: Wormholes are now created in create_zone_layer_for_discovered_zone()"""
	# This function is no longer called to avoid duplicate wormhole creation
	pass

func create_wormholes_for_zone(zone_id: String):
	"""Create depth and lateral wormholes for a zone"""
	if not ZoneManager:
		return
	
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty() or not zone.layer_node:
		return
	
	var wormholes_node = zone.layer_node.get_node_or_null("Wormholes")
	if not wormholes_node:
		return
	
	var difficulty = zone.difficulty
	
	# Phase 2: Create exactly 2 lateral wormholes (left and right neighbors on ring)
	create_lateral_wormholes(zone_id, wormholes_node)
	
	# Phase 3: Create depth wormholes ONLY if this is the designated portal zone
	if ZoneManager.should_zone_have_depth_portal(zone_id):
		# Forward (deeper) wormhole
		if difficulty < 9:
			create_depth_wormhole(zone_id, wormholes_node, true)
		
		# Backward (outer) wormhole
		if difficulty > 1:
			create_depth_wormhole(zone_id, wormholes_node, false)
		
		print("ZoneSetup: Zone '%s' is the depth portal zone for difficulty %d" % [zone_id, difficulty])

func create_lateral_wormholes(zone_id: String, parent: Node2D):
	"""Create lateral wormholes connecting to left and right neighbors on the ring"""
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty():
		return
	
	# Get neighbor zone information
	var neighbors = ZoneManager.get_zone_neighbors(zone_id)
	
	# Create left wormhole
	if not neighbors.left.is_empty():
		create_lateral_wormhole_to_neighbor(zone_id, neighbors.left, parent, true)
	else:
		# Neighbor doesn't exist yet - create undiscovered wormhole
		create_undiscovered_lateral_wormhole(zone_id, parent, true)
	
	# Create right wormhole
	if not neighbors.right.is_empty():
		create_lateral_wormhole_to_neighbor(zone_id, neighbors.right, parent, false)
	else:
		# Neighbor doesn't exist yet - create undiscovered wormhole
		create_undiscovered_lateral_wormhole(zone_id, parent, false)

func create_lateral_wormhole_to_neighbor(source_zone_id: String, target_zone_id: String, parent: Node2D, is_left: bool):
	"""Create a lateral wormhole to a specific existing neighbor"""
	var source_zone = ZoneManager.get_zone(source_zone_id)
	var target_zone = ZoneManager.get_zone(target_zone_id)
	if source_zone.is_empty() or target_zone.is_empty():
		return
	
	# Calculate angle toward the neighbor
	var angle_to_neighbor = calculate_angle_to_neighbor(source_zone, target_zone)
	
	var wormhole = wormhole_scene.instantiate()
	wormhole.source_zone_id = source_zone_id
	wormhole.target_zone_id = target_zone_id
	wormhole.wormhole_type = Wormhole.WormholeType.LATERAL
	wormhole.is_undiscovered = false  # Known neighbor
	wormhole.wormhole_direction = angle_to_neighbor
	
	# Position at zone edge pointing toward neighbor
	var spawn_pos = ZoneManager.get_zone_wormhole_spawn_position(source_zone_id, angle_to_neighbor)
	wormhole.global_position = spawn_pos
	
	parent.add_child(wormhole)
	
	# Set z_index for lateral wormholes (lower than depth)
	wormhole.z_index = 0  # Default, depth wormholes will be 10
	
	ZoneManager.set_zone_wormhole(source_zone_id, wormhole, "lateral")
	
	var direction = "left" if is_left else "right"
	print("ZoneSetup: Created %s lateral wormhole in '%s' to '%s' at angle %.2f" % [direction, source_zone_id, target_zone_id, angle_to_neighbor])

func create_undiscovered_lateral_wormhole(zone_id: String, parent: Node2D, is_left: bool):
	"""Create an undiscovered lateral wormhole (neighbor doesn't exist yet)"""
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty():
		return
	
	# Check if zone has zone_index
	if not zone.has("zone_index"):
		push_warning("ZoneSetup: Cannot create lateral wormhole - zone '%s' missing zone_index" % zone_id)
		return
	
	var difficulty = zone.difficulty
	var zone_index = zone.zone_index
	var zones_on_ring = ZoneManager.ZONES_PER_DIFFICULTY.get(difficulty, 4)
	
	# Calculate target neighbor index
	var target_index = (zone_index + (-1 if is_left else 1) + zones_on_ring) % zones_on_ring
	
	# Calculate angle toward where the neighbor would be
	var target_angle = ZoneManager.get_zone_angle(difficulty, target_index)
	var angle_to_neighbor = calculate_angle_between_ring_positions(zone.ring_position, target_angle)
	
	var wormhole = wormhole_scene.instantiate()
	wormhole.source_zone_id = zone_id
	wormhole.target_zone_id = ""  # Will be set when discovered
	wormhole.wormhole_type = Wormhole.WormholeType.LATERAL
	wormhole.is_undiscovered = true
	wormhole.wormhole_direction = angle_to_neighbor
	
	# CRITICAL: Store the target zone index so when discovered, we create the zone at the correct index
	wormhole.set_meta("target_zone_index", target_index)
	
	print("ZoneSetup: Undiscovered lateral wormhole will create zone at index %d (difficulty %d)" % [target_index, difficulty])
	
	# Position at zone edge
	var spawn_pos = ZoneManager.get_zone_wormhole_spawn_position(zone_id, angle_to_neighbor)
	wormhole.global_position = spawn_pos
	
	parent.add_child(wormhole)
	
	# Set z_index for lateral wormholes (lower than depth)
	wormhole.z_index = 0  # Default, depth wormholes will be 10
	
	ZoneManager.set_zone_wormhole(zone_id, wormhole, "lateral")
	
	var direction = "left" if is_left else "right"
	print("ZoneSetup: Created undiscovered %s lateral wormhole in '%s' at angle %.2f" % [direction, zone_id, angle_to_neighbor])

func calculate_angle_to_neighbor(source_zone: Dictionary, target_zone: Dictionary) -> float:
	"""Calculate angle from source zone toward target zone on same ring"""
	# Both zones are on the same ring (same radius), so we just need direction
	var angle_diff = target_zone.ring_position - source_zone.ring_position
	
	# Normalize to [-PI, PI] for shortest path
	while angle_diff > PI:
		angle_diff -= TAU
	while angle_diff < -PI:
		angle_diff += TAU
	
	# Return the direction angle
	return source_zone.ring_position + angle_diff

func calculate_angle_between_ring_positions(from_angle: float, to_angle: float) -> float:
	"""Calculate the shortest angle between two ring positions"""
	var angle_diff = to_angle - from_angle
	
	# Normalize to [-PI, PI]
	while angle_diff > PI:
		angle_diff -= TAU
	while angle_diff < -PI:
		angle_diff += TAU
	
	return from_angle + angle_diff

func create_depth_wormhole(zone_id: String, parent: Node2D, is_forward: bool):
	"""Create a depth wormhole (discovered if target portal zone exists)"""
	print("Wormhole_debug : === CREATE DEPTH WORMHOLE START ===")
	print("Wormhole_debug :   Zone: %s" % zone_id)
	print("Wormhole_debug :   Direction: %s" % ("FORWARD (toward center)" if is_forward else "BACKWARD (toward outer)"))
	
	if not ZoneManager:
		print("Wormhole_debug :   ERROR - ZoneManager is null!")
		return
	
	var source_zone = ZoneManager.get_zone(zone_id)
	if source_zone.is_empty():
		print("Wormhole_debug :   ERROR - Source zone is empty!")
		return
	
	var target_difficulty = source_zone.difficulty + (1 if is_forward else -1)
	print("Wormhole_debug :   Source difficulty: %d" % source_zone.difficulty)
	print("Wormhole_debug :   Target difficulty: %d (zones get %s)" % [target_difficulty, "BIGGER" if is_forward else "smaller"])
	
	# Find the portal zone at the target difficulty
	var target_zone_id = ""
	var target_portal_index = ZoneManager.get_depth_portal_zone_index(target_difficulty)
	
	print("Wormhole_debug :   Looking for PORTAL zone at difficulty %d, portal index %d" % [target_difficulty, target_portal_index])
	
	# Check if target portal zone exists
	var target_zones = ZoneManager.get_zones_at_difficulty(target_difficulty)
	print("Wormhole_debug :   Found %d existing zones at difficulty %d" % [target_zones.size(), target_difficulty])
	
	for zone in target_zones:
		if zone.has("zone_index"):
			if zone.zone_index == target_portal_index:
				target_zone_id = zone.zone_id
				print("Wormhole_debug :   ✓ FOUND existing portal zone: %s" % target_zone_id)
				break
	
	if target_zone_id.is_empty():
		print("Wormhole_debug :   Portal zone doesn't exist yet - wormhole will be UNDISCOVERED")
	
	print("Wormhole_debug :   Creating wormhole instance...")
	var wormhole = wormhole_scene.instantiate()
	wormhole.source_zone_id = zone_id
	wormhole.target_zone_id = target_zone_id
	wormhole.wormhole_type = Wormhole.WormholeType.DEPTH
	wormhole.is_undiscovered = target_zone_id.is_empty()
	wormhole.set_meta("is_forward", is_forward)
	
	print("Wormhole_debug :   Wormhole properties SET:")
	print("Wormhole_debug :     source_zone_id = %s" % wormhole.source_zone_id)
	print("Wormhole_debug :     target_zone_id = %s" % ("EMPTY (undiscovered)" if wormhole.target_zone_id.is_empty() else wormhole.target_zone_id))
	print("Wormhole_debug :     wormhole_type = %d (0=DEPTH, 1=LATERAL)" % wormhole.wormhole_type)
	print("Wormhole_debug :     is_undiscovered = %s" % wormhole.is_undiscovered)
	print("Wormhole_debug :     is_forward = %s" % is_forward)
	
	# Position perpendicular to the zone's ring position to avoid ANY overlap with lateral wormholes
	# Lateral wormholes point along the ring (toward neighbors)
	# Depth wormholes point perpendicular to the ring (inward/outward from center)
	var ring_angle = source_zone.ring_position
	var angle = ring_angle + (PI / 2.0) if is_forward else ring_angle - (PI / 2.0)
	# Normalize angle to [0, 2PI]
	while angle < 0:
		angle += TAU
	while angle >= TAU:
		angle -= TAU
	
	var spawn_pos = ZoneManager.get_zone_wormhole_spawn_position(zone_id, angle)
	wormhole.global_position = spawn_pos
	
	print("Wormhole_debug :   Zone ring position: %.2f degrees" % rad_to_deg(ring_angle))
	print("Wormhole_debug :   Depth wormhole angle: %.2f degrees (perpendicular %s from ring)" % [rad_to_deg(angle), "INWARD" if is_forward else "OUTWARD"])
	print("Wormhole_debug :   Spawn position: %s" % spawn_pos)
	
	parent.add_child(wormhole)
	
	# CRITICAL: Set z_index to render depth wormholes ON TOP of lateral wormholes
	wormhole.z_index = 10  # Lateral wormholes default to 0, depth should be higher
	
	print("Wormhole_debug :   Added to scene tree under: %s" % parent.name)
	print("Wormhole_debug :   Z-index set to: %d (renders ON TOP)" % wormhole.z_index)
	
	ZoneManager.set_zone_wormhole(zone_id, wormhole, "depth")
	
	# Verify registration
	var zone_check = ZoneManager.get_zone(zone_id)
	print("Wormhole_debug :   Zone '%s' now has %d depth wormholes, %d lateral wormholes" % [zone_id, zone_check.depth_wormholes.size(), zone_check.lateral_wormholes.size()])
	print("Wormhole_debug : === CREATE DEPTH WORMHOLE COMPLETE ===\n")

func move_existing_entities_to_zone1():
	"""Move any existing units/resources to starting zone"""
	if not ZoneManager or ZoneManager.current_zone_id.is_empty():
		return
	
	var zone1 = ZoneManager.get_zone(ZoneManager.current_zone_id)
	if zone1.is_empty() or not zone1.layer_node:
		return
	
	# Move units
	var old_units = world_layer.get_node_or_null("Entities/Units")
	if old_units:
		var zone1_units = zone1.layer_node.get_node_or_null("Entities/Units")
		if zone1_units:
			for unit in old_units.get_children():
				old_units.remove_child(unit)
				zone1_units.add_child(unit)
	
	# Move resources
	var old_resources = world_layer.get_node_or_null("Entities/Resources")
	if old_resources:
		var zone1_resources = zone1.layer_node.get_node_or_null("Entities/Resources")
		if zone1_resources:
			for resource in old_resources.get_children():
				old_resources.remove_child(resource)
				zone1_resources.add_child(resource)

func create_planets_for_zone(zone_id: String):
	"""Create 1-2 planets for a zone at perimeter positions"""
	if not ZoneManager:
		return
	
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty() or not zone.layer_node:
		return
	
	var planets_container = zone.layer_node.get_node_or_null("Planets")
	if not planets_container:
		return
	
	# Check if planets already exist (from save file) - don't recreate them
	if planets_container.get_child_count() > 0:
		return
	
	# Randomly choose 1 or 2 planets for this zone
	var planet_count = randi_range(1, 2)
	var positions = get_planet_edge_positions(zone_id, planet_count)
	
	for i in range(planet_count):
		# Select random planet texture
		var texture_path = planet_textures[randi() % planet_textures.size()]
		var texture = load(texture_path)
		
		# Calculate scale based on zone difficulty with randomness
		var difficulty = zone.difficulty
		var base_scale = 2.0 + (difficulty * 0.3)  # Base: Diff 1: 2.3, Diff 9: 4.7
		var planet_scale = base_scale * randf_range(1.0, 3.0)  # Random 1x-3x multiplier
		
		# Create planet
		var planet = planet_scene.instantiate()
		planet.global_position = positions[i]
		planets_container.add_child(planet)
		
		# Setup planet properties
		if planet.has_method("setup"):
			planet.setup(zone_id, texture, planet_scale)
		
		# Add to "planets" group for easy lookup
		planet.add_to_group("planets")
		
		print("ZoneSetup: Created planet at %s in Zone '%s' (scale: %.1f)" % [positions[i], zone_id, planet_scale])

func get_planet_edge_positions(zone_id: String, count: int) -> Array[Vector2]:
	"""Get positions around zone perimeter for planets"""
	if not ZoneManager:
		return []
	
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty():
		return []
	
	var positions: Array[Vector2] = []
	var zone_size = zone.spawn_area_size
	var zone_radius = zone_size / 2.0 * 0.9  # 90% of zone radius
	
	if count == 1:
		# Single planet: random angle
		var angle = randf() * TAU
		angle += randf_range(-0.26, 0.26)  # ±15 degrees randomness
		positions.append(Vector2(
			cos(angle) * zone_radius,
			sin(angle) * zone_radius
		))
	elif count == 2:
		# Two planets: opposite sides with randomness
		var base_angle = randf() * TAU
		for i in range(2):
			var angle = base_angle + (i * PI)  # 180° apart
			angle += randf_range(-0.26, 0.26)  # ±15 degrees randomness
			positions.append(Vector2(
				cos(angle) * zone_radius,
				sin(angle) * zone_radius
			))
	
	return positions
