extends Node
## Tracks and manages all game entities for quick queries

signal unit_registered(unit: Node2D)
signal unit_unregistered(unit: Node2D)
signal resource_registered(resource: Node2D)
signal resource_unregistered(resource: Node2D)

# Legacy arrays (kept for backward compatibility)
var units: Array = []
var resources: Array = []
var buildings: Array = []
var projectiles: Array = []

# Zone-aware tracking
var units_by_zone: Dictionary = {}  # zone_id -> Array[Node2D]
var resources_by_zone: Dictionary = {}  # zone_id -> Array[Node2D]
var buildings_by_zone: Dictionary = {}  # zone_id -> Array[Node2D]

func _ready():
	# Initialize zone tracking for all 9 zones
	for zone_id in range(1, 10):
		units_by_zone[zone_id] = []
		resources_by_zone[zone_id] = []
		buildings_by_zone[zone_id] = []

# Unit Management
func register_unit(unit: Node2D, zone_id: int = -1):
	if unit not in units:
		units.append(unit)
		
		# Determine zone if not provided
		if zone_id == -1:
			zone_id = ZoneManager.get_unit_zone(unit)
		
		# Add to zone tracking
		if zone_id in units_by_zone:
			if unit not in units_by_zone[zone_id]:
				units_by_zone[zone_id].append(unit)
		
		# Set initial processing state based on zone
		if ZoneProcessingManager and unit.has_method("set_processing_state"):
			if zone_id == ZoneManager.current_zone_id:
				unit.set_processing_state(0)  # FULL
			else:
				unit.set_processing_state(1)  # REDUCED
		
		unit_registered.emit(unit)

func unregister_unit(unit: Node2D):
	if unit in units:
		units.erase(unit)
		
		# Remove from zone tracking
		for zone_id in units_by_zone:
			if unit in units_by_zone[zone_id]:
				units_by_zone[zone_id].erase(unit)
		
		SelectionManager.deselect_unit(unit)
		unit_unregistered.emit(unit)

func get_units_in_radius(position: Vector2, radius: float, team_id: int = -1) -> Array:
	var nearby = []
	for unit in units:
		if not is_instance_valid(unit):
			continue
		
		var distance = unit.global_position.distance_to(position)
		if distance <= radius:
			if team_id == -1 or unit.team_id == team_id:
				nearby.append(unit)
	
	return nearby

func get_nearest_unit(position: Vector2, team_id: int = -1, exclude: Node2D = null) -> Node2D:
	var nearest: Node2D = null
	var min_distance: float = INF
	
	for unit in units:
		if not is_instance_valid(unit) or unit == exclude:
			continue
		
		if team_id != -1 and unit.team_id != team_id:
			continue
		
		var distance = unit.global_position.distance_to(position)
		if distance < min_distance:
			min_distance = distance
			nearest = unit
	
	return nearest

func get_units_by_team(team_id: int) -> Array:
	var team_units = []
	for unit in units:
		if is_instance_valid(unit) and unit.team_id == team_id:
			team_units.append(unit)
	return team_units

# Resource Management
func register_resource(resource: Node2D, zone_id: int = -1):
	if resource not in resources:
		resources.append(resource)
		
		# Determine zone if not provided
		if zone_id == -1:
			zone_id = ZoneManager.get_unit_zone(resource)
		
		# Add to zone tracking
		if zone_id in resources_by_zone:
			if resource not in resources_by_zone[zone_id]:
				resources_by_zone[zone_id].append(resource)
		
		resource_registered.emit(resource)

func unregister_resource(resource: Node2D):
	if resource in resources:
		resources.erase(resource)
		
		# Remove from zone tracking
		for zone_id in resources_by_zone:
			if resource in resources_by_zone[zone_id]:
				resources_by_zone[zone_id].erase(resource)
		
		resource_unregistered.emit(resource)

func get_nearest_resource(position: Vector2, resource_type: int = -1) -> Node2D:
	var nearest: Node2D = null
	var min_dist = INF
	
	for resource in resources:
		if not is_instance_valid(resource):
			continue
		
		if resource_type >= 0 and resource.resource_type != resource_type:
			continue
		
		var dist = position.distance_to(resource.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = resource
	
	return nearest

# Building Management
func register_building(building: Node2D):
	if building not in buildings:
		buildings.append(building)

func unregister_building(building: Node2D):
	buildings.erase(building)

# Projectile Management
func register_projectile(projectile: Node2D):
	if projectile not in projectiles:
		projectiles.append(projectile)

func unregister_projectile(projectile: Node2D):
	projectiles.erase(projectile)

# Cleanup
func cleanup_invalid_entities():
	# Remove invalid units
	units = units.filter(func(u): return is_instance_valid(u))
	resources = resources.filter(func(r): return is_instance_valid(r))
	buildings = buildings.filter(func(b): return is_instance_valid(b))
	projectiles = projectiles.filter(func(p): return is_instance_valid(p))
	
	# Cleanup zone tracking
	for zone_id in units_by_zone:
		units_by_zone[zone_id] = units_by_zone[zone_id].filter(func(u): return is_instance_valid(u))
	for zone_id in resources_by_zone:
		resources_by_zone[zone_id] = resources_by_zone[zone_id].filter(func(r): return is_instance_valid(r))
	for zone_id in buildings_by_zone:
		buildings_by_zone[zone_id] = buildings_by_zone[zone_id].filter(func(b): return is_instance_valid(b))

# Zone-aware methods
func get_units_in_zone(zone_id: int) -> Array:
	"""Get all units in a specific zone"""
	if zone_id in units_by_zone:
		return units_by_zone[zone_id].duplicate()
	return []

func get_resources_in_zone(zone_id: int) -> Array:
	"""Get all resources in a specific zone"""
	if zone_id in resources_by_zone:
		return resources_by_zone[zone_id].duplicate()
	return []

func update_unit_zone(unit: Node2D, old_zone_id: int, new_zone_id: int):
	"""Update unit's zone tracking when it moves between zones"""
	# Remove from old zone
	if old_zone_id in units_by_zone:
		if unit in units_by_zone[old_zone_id]:
			units_by_zone[old_zone_id].erase(unit)
	
	# Add to new zone
	if new_zone_id in units_by_zone:
		if unit not in units_by_zone[new_zone_id]:
			units_by_zone[new_zone_id].append(unit)
