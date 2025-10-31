extends Node2D
## Spawns resources across all zones

@export var base_asteroid_count: int = 450
@export var min_spacing: float = 100.0

var resource_node_scene: PackedScene
var spawned_resources_by_zone: Dictionary = {}  # zone_id -> Array[Node2D]

func _ready():
	
	
	# Skip initial spawn if loading from save
	if SaveLoadManager and SaveLoadManager.is_loading_save:
		
		return
	
	resource_node_scene = preload("res://scenes/world/ResourceNode.tscn")
	
	
	# Wait for zones to be initialized
	if not ZoneManager:
		
		return
	
	if not ZoneManager.zones_ready:
		
		await ZoneManager.zones_initialized
	
	
	
	# Spawn resources for all zones
	spawn_all_zones()

func spawn_all_zones():
	"""Spawn resources for all discovered zones"""
	if not ZoneManager:
		return
	
	# Connect to zone discovery to spawn resources in new zones
	ZoneManager.zone_discovered.connect(_on_zone_discovered)
	
	# Spawn resources for all currently discovered zones
	for zone_id in ZoneManager.zones_by_id.keys():
		var zone = ZoneManager.get_zone(zone_id)
		if zone.is_empty():
			continue
		
		spawn_resources_for_zone(zone_id, zone)

func _on_zone_discovered(zone_id: String):
	"""Spawn resources when a new zone is discovered"""
	if not ZoneManager:
		return
	
	var zone = ZoneManager.get_zone(zone_id)
	if not zone.is_empty():
		spawn_resources_for_zone(zone_id, zone)
	


func get_total_spawned_count() -> int:
	var total = 0
	for zone_resources in spawned_resources_by_zone.values():
		total += zone_resources.size()
	return total

func spawn_resources_for_zone(zone_id: String, zone_data: Dictionary):
	"""Spawn resources for a specific zone in orbital positions around planets"""
	var zone_layer = zone_data.layer_node
	if not zone_layer:
		return
	
	var resources_node = zone_layer.get_node_or_null("Entities/Resources")
	if not resources_node:
		return
	
	# Get planets in this zone
	var planets_container = zone_layer.get_node_or_null("Planets")
	if not planets_container:
		return
	
	var planets = planets_container.get_children()
	if planets.is_empty():
		return
	
	# Check if resources already exist (from save file) - don't recreate them
	if resources_node.get_child_count() > 0:
		# Still need to populate the spawned_resources array for existing resources
		var existing_resources: Array[Node2D] = []
		for resource in resources_node.get_children():
			if is_instance_valid(resource):
				existing_resources.append(resource)
		spawned_resources_by_zone[zone_id] = existing_resources
		return
	
	# Number of asteroids per zone
	var asteroid_count = base_asteroid_count
	var spawned_resources: Array[Node2D] = []
	spawned_resources_by_zone[zone_id] = spawned_resources
	
	# Distribute asteroids among planets
	var asteroids_per_planet = asteroid_count / planets.size()
	
	for planet in planets:
		if not is_instance_valid(planet):
			continue
		
		# Spawn asteroids for this planet
		for i in range(asteroids_per_planet):
			var orbital_data = get_orbital_spawn_position(planet, zone_data.spawn_area_size)
			
			var asteroid = resource_node_scene.instantiate()
			asteroid.global_position = orbital_data.position
			
			# Override resource generation to use zone-specific tiers
			asteroid.set_meta("zone_id", zone_id)
			
			resources_node.add_child(asteroid)
			spawned_resources.append(asteroid)
			
			# Override the composition after it's been added to tree
			asteroid.resource_composition.clear()
			generate_zone_composition(asteroid, zone_id)
			
			# Register with OrbitalManager for rotation
			if OrbitalManager:
				OrbitalManager.register_asteroid(
					asteroid,
					planet,
					orbital_data.radius,
					orbital_data.angle
				)
	
	print("ResourceSpawner: Spawned %d asteroids in Zone %s around %d planet(s)" % [spawned_resources.size(), zone_id, planets.size()])

func generate_zone_composition(asteroid: ResourceNode, zone_id: String):
	"""Generate zone-appropriate resource composition for asteroid"""
	var total = randf_range(500.0, 2000.0)
	var num_types = randi_range(1, 5)
	var remaining = total
	
	asteroid.resource_composition.clear()
	
	for i in range(num_types):
		var is_last = (i == num_types - 1)
		var amount: float
		
		if is_last:
			amount = remaining
		else:
			var min_percent = 0.15
			var max_percent = 0.60
			amount = randf_range(remaining * min_percent, remaining * max_percent)
		
		# Use zone-specific resource selection
		var resource_id = ResourceDatabase.get_weighted_random_resource_for_zone(zone_id)
		
		asteroid.resource_composition.append({
			"type_id": resource_id,
			"amount": amount,
			"initial_amount": amount
		})
		
		remaining -= amount
	
	# Calculate total
	asteroid.total_resources = 0.0
	for comp in asteroid.resource_composition:
		asteroid.total_resources += comp.amount
	
	asteroid.remaining_resources = asteroid.total_resources
	
	# Update visual
	if asteroid.is_inside_tree():
		asteroid.base_scale = asteroid.calculate_base_scale(asteroid.total_resources)
		asteroid.update_visual()

func get_orbital_spawn_position(planet: Node2D, zone_size: float) -> Dictionary:
	"""Calculate orbital position around a planet"""
	# Base orbit radius: 25-40% of zone size (tighter orbits around planets)
	var base_radius = zone_size * randf_range(0.25, 0.4)
	
	# Add ±20% variation to radius for more spread
	var radius = base_radius + randf_range(-base_radius * 0.2, base_radius * 0.2)
	
	# Random starting angle
	var angle = randf() * TAU
	
	# Calculate position
	var position = planet.global_position + Vector2(
		cos(angle) * radius,
		sin(angle) * radius
	)
	
	return {
		"position": position,
		"planet": planet,
		"radius": radius,
		"angle": angle
	}
