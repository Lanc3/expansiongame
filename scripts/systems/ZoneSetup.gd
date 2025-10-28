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
	
	print("ZoneSetup: Setting up wormholes...")
	setup_wormholes()
	
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
	
	# Create only the initial starting zone
	if ZoneManager and not ZoneManager.current_zone_id.is_empty():
		print("ZoneSetup: Creating initial zone layer for: '%s'" % ZoneManager.current_zone_id)
		create_zone_layer_for_discovered_zone(ZoneManager.current_zone_id)
	else:
		print("ZoneSetup: ERROR - Cannot create zone layer!")
		if not ZoneManager:
			print("  ZoneManager is null!")
		elif ZoneManager.current_zone_id.is_empty():
			print("  current_zone_id is empty!")
		

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
	"""Create wormholes for initial zone"""
	if ZoneManager and not ZoneManager.current_zone_id.is_empty():
		create_wormholes_for_zone(ZoneManager.current_zone_id)

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
	
	# Create lateral wormholes (2-3 per zone)
	var num_lateral = 2 if difficulty >= 7 else 3
	var lateral_angle_step = TAU / num_lateral
	
	for i in range(num_lateral):
		var angle = i * lateral_angle_step + randf_range(-0.3, 0.3)  # Add randomness
		create_lateral_wormhole(zone_id, wormholes_node, angle)
	
	# Create depth wormholes (if not at difficulty boundaries)
	# Forward (deeper) wormhole
	if difficulty < 9:
		create_depth_wormhole(zone_id, wormholes_node, true)
	
	# Backward (outer) wormhole
	if difficulty > 1:
		create_depth_wormhole(zone_id, wormholes_node, false)

func create_lateral_wormhole(zone_id: String, parent: Node2D, angle: float):
	"""Create a lateral wormhole (undiscovered initially)"""
	var wormhole = wormhole_scene.instantiate()
	wormhole.source_zone_id = zone_id
	wormhole.target_zone_id = ""  # Will be set when discovered
	wormhole.wormhole_type = Wormhole.WormholeType.LATERAL
	wormhole.is_undiscovered = true
	wormhole.wormhole_direction = angle
	
	# Position at zone edge based on angle
	var spawn_pos = ZoneManager.get_zone_wormhole_spawn_position(zone_id, angle)
	wormhole.global_position = spawn_pos
	
	parent.add_child(wormhole)
	print("ZoneSetup: Created lateral wormhole in '%s' at angle %.2f" % [zone_id, angle])

func create_depth_wormhole(zone_id: String, parent: Node2D, is_forward: bool):
	"""Create a depth wormhole (discovered if target exists)"""
	if not ZoneManager:
		return
	
	var source_zone = ZoneManager.get_zone(zone_id)
	if source_zone.is_empty():
		return
	
	var target_difficulty = source_zone.difficulty + (1 if is_forward else -1)
	
	# Check if target zone exists
	var target_zones = ZoneManager.get_zones_at_difficulty(target_difficulty)
	var target_zone_id = target_zones[0].zone_id if not target_zones.is_empty() else ""
	
	var wormhole = wormhole_scene.instantiate()
	wormhole.source_zone_id = zone_id
	wormhole.target_zone_id = target_zone_id
	wormhole.wormhole_type = Wormhole.WormholeType.DEPTH
	wormhole.is_undiscovered = target_zone_id.is_empty()
	wormhole.set_meta("is_forward", is_forward)
	
	# Position based on forward/backward
	var angle = 0.0 if is_forward else PI  # Forward = right, backward = left
	var spawn_pos = ZoneManager.get_zone_wormhole_spawn_position(zone_id, angle)
	wormhole.global_position = spawn_pos
	
	parent.add_child(wormhole)
	
	var direction = "forward" if is_forward else "backward"
	print("ZoneSetup: Created %s depth wormhole in '%s'" % [direction, zone_id])

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
