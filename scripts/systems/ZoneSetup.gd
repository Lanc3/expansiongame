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
	
	
	# Find WorldLayer in the scene
	world_layer = get_node("/root/GameScene/WorldLayer")
	if not world_layer:
		
		return
	
	
	await get_tree().create_timer(0.05).timeout  # Wait for scene to fully initialize
	
	setup_zone_layers()
	setup_wormholes()
	
	# Show only Zone 1 initially
	ZoneManager.update_zone_visibility()
	
	# Notify that zones are ready
	ZoneManager.mark_zones_initialized()


func setup_zone_layers():
	"""Create 9 zone layers with proper structure"""
	# Check if WorldLayer exists
	if not world_layer:
		
		return
	
	# Check if zones already exist (from save load or manual setup)
	if world_layer.has_node("Zone1Layer"):
		
		link_existing_zones()
		return
	
	
	
	for zone_id in range(1, 10):
		var zone_layer = Node2D.new()
		zone_layer.name = "Zone%dLayer" % zone_id
		zone_layer.visible = (zone_id == 1)  # Only Zone 1 visible initially
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
		var nav_region = create_navigation_region_for_zone(zone_id)
		zone_layer.add_child(nav_region)
		
		# Create zone boundary
		var boundary = create_zone_boundary(zone_id)
		zone_layer.add_child(boundary)
		
		# Register with ZoneManager
		ZoneManager.set_zone_layer(zone_id, zone_layer)
		
		# Create planets for this zone
		create_planets_for_zone(zone_id)
		

func create_navigation_region_for_zone(zone_id: int) -> NavigationRegion2D:
	"""Create a NavigationRegion2D sized for the zone"""
	var nav_region = NavigationRegion2D.new()
	nav_region.name = "NavigationRegion2D"
	
	# Get zone boundaries
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty():
		return nav_region
	
	var bounds = zone.boundaries
	var half_width = bounds.size.x / 2.0
	var half_height = bounds.size.y / 2.0
	
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
	
	print("ZoneSetup: Created NavigationRegion2D for Zone %d (size: %s)" % [zone_id, bounds.size])
	
	return nav_region

func create_zone_boundary(zone_id: int) -> Node2D:
	"""Create boundary system for a zone"""
	var boundary_script = load("res://scripts/systems/ZoneBoundary.gd")
	var boundary = Node2D.new()
	boundary.name = "ZoneBoundary"
	boundary.set_script(boundary_script)
	
	# Setup boundary after it's added to tree
	var zone = ZoneManager.get_zone(zone_id)
	if not zone.is_empty():
		boundary.call_deferred("setup_for_zone", zone_id, zone.boundaries)
	
	return boundary

func link_existing_zones():
	"""Link existing zone layers to ZoneManager"""
	for zone_id in range(1, 10):
		var zone_layer = world_layer.get_node_or_null("Zone%dLayer" % zone_id)
		if zone_layer:
			ZoneManager.set_zone_layer(zone_id, zone_layer)

func setup_wormholes():
	"""Create wormholes connecting zones"""
	
	# Zone 1: Only forward wormhole (to Zone 2)
	create_wormhole_for_zone(1, 2, true)
	
	# Zones 2-8: Both forward and return wormholes
	for zone_id in range(2, 9):
		create_wormhole_for_zone(zone_id, zone_id + 1, true)  # Forward
		create_wormhole_for_zone(zone_id, zone_id - 1, false)  # Return
	
	# Zone 9: Only return wormhole (to Zone 8)
	create_wormhole_for_zone(9, 8, false)
	

func create_wormhole_for_zone(zone_id: int, target_zone_id: int, is_forward: bool):
	"""Create a single wormhole in a zone"""
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty() or not zone.layer_node:
		return
	
	var wormholes_node = zone.layer_node.get_node_or_null("Wormholes")
	if not wormholes_node:
		return
	
	# Create wormhole
	var wormhole = wormhole_scene.instantiate()
	wormhole.source_zone_id = zone_id
	wormhole.target_zone_id = target_zone_id
	
	# Position at zone edge (different edges for forward vs return)
	var spawn_pos = get_wormhole_position_by_direction(zone_id, is_forward)
	wormhole.global_position = spawn_pos
	
	# Store direction in metadata for label display
	wormhole.set_meta("is_forward", is_forward)
	
	wormholes_node.add_child(wormhole)
	
	var direction_text = "forward" if is_forward else "return"
	print("ZoneSetup: Created %s wormhole in Zone %d at %s (→ Zone %d)" % [direction_text, zone_id, spawn_pos, target_zone_id])

func get_wormhole_position_by_direction(zone_id: int, is_forward: bool) -> Vector2:
	"""Get wormhole position based on direction (forward = right/bottom, return = left/top)"""
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty():
		return Vector2.ZERO
	
	var bounds = zone.boundaries
	
	# Forward wormholes on right or bottom edge
	# Return wormholes on left or top edge
	if is_forward:
		# Alternate between right and bottom
		if zone_id % 2 == 0:
			# Right edge
			return Vector2(
				bounds.position.x + bounds.size.x - 100,
				randf_range(bounds.position.y + 200, bounds.position.y + bounds.size.y - 200)
			)
		else:
			# Bottom edge
			return Vector2(
				randf_range(bounds.position.x + 200, bounds.position.x + bounds.size.x - 200),
				bounds.position.y + bounds.size.y - 100
			)
	else:
		# Alternate between left and top
		if zone_id % 2 == 0:
			# Left edge
			return Vector2(
				bounds.position.x + 100,
				randf_range(bounds.position.y + 200, bounds.position.y + bounds.size.y - 200)
			)
		else:
			# Top edge
			return Vector2(
				randf_range(bounds.position.x + 200, bounds.position.x + bounds.size.x - 200),
				bounds.position.y + 100
			)

func move_existing_entities_to_zone1():
	"""Move any existing units/resources to Zone 1"""
	var zone1 = ZoneManager.get_zone(1)
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

func create_planets_for_zone(zone_id: int):
	"""Create 1-2 planets for a zone at perimeter positions"""
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
		
		# Calculate scale based on zone size with randomness
		var base_scale = 2.0 + (zone_id * 0.3)  # Base: Zone 1: 2.3, Zone 9: 4.7
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
		
		print("ZoneSetup: Created planet at %s in Zone %d (scale: %.1f)" % [positions[i], zone_id, planet_scale])

func get_planet_edge_positions(zone_id: int, count: int) -> Array[Vector2]:
	"""Get positions around zone perimeter for planets"""
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

