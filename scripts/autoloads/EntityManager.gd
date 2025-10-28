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
	# Zone tracking dictionaries are now initialized on-demand when zones are discovered
	# No pre-initialization needed for dynamic zone system
	pass

	# Unit Management
func register_unit(unit: Node2D, zone_id: String = ""):
	if unit not in units:
		units.append(unit)
		
		# Determine zone if not provided
		if zone_id.is_empty():
			zone_id = ZoneManager.get_unit_zone(unit) if ZoneManager else ""
		
		# Add to zone tracking (initialize zone array if needed)
		if not zone_id.is_empty():
			if zone_id not in units_by_zone:
				units_by_zone[zone_id] = []
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

func get_nearest_unit_in_zone(position: Vector2, team_id: int, zone_id: String, exclude: Node2D = null) -> Node2D:
	"""Get nearest unit in specific zone (optimized for combat)"""
	# OPTIMIZATION: Only check units in the specified zone
	if not zone_id in units_by_zone:
		return null
	
	var nearest: Node2D = null
	var min_distance: float = INF
	
	for unit in units_by_zone[zone_id]:
		if not is_instance_valid(unit) or unit == exclude:
			continue
		
		if team_id != -1 and unit.team_id != team_id:
			continue
		
		# Use distance_squared for faster comparison (avoid sqrt)
		var distance_sq = unit.global_position.distance_squared_to(position)
		if distance_sq < min_distance:
			min_distance = distance_sq
			nearest = unit
	
	return nearest

func get_units_in_radius_zone(position: Vector2, radius: float, team_id: int, zone_id: String) -> Array:
	"""Get units in radius within specific zone (optimized for combat)"""
	var nearby: Array = []
	var radius_sq = radius * radius  # Use squared for comparison
	
	if not zone_id in units_by_zone:
		return nearby
	
	for unit in units_by_zone[zone_id]:
		if not is_instance_valid(unit):
			continue
		
		if team_id != -1 and unit.team_id != team_id:
			continue
		
		var distance_sq = unit.global_position.distance_squared_to(position)
		if distance_sq <= radius_sq:
			nearby.append(unit)
	
	return nearby

func get_units_by_team(team_id: int) -> Array:
	var team_units = []
	for unit in units:
		if is_instance_valid(unit) and unit.team_id == team_id:
			team_units.append(unit)
	return team_units

# Resource Management
func register_resource(resource: Node2D, zone_id: String = ""):
	if resource not in resources:
		resources.append(resource)
		
		# Determine zone if not provided
		if zone_id.is_empty():
			zone_id = ZoneManager.get_unit_zone(resource) if ZoneManager else ""
		
		# Add to zone tracking (initialize zone array if needed)
		if not zone_id.is_empty():
			if zone_id not in resources_by_zone:
				resources_by_zone[zone_id] = []
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
func register_building(building: Node2D, zone_id: String = ""):
	"""Register a building with zone tracking"""
	if building not in buildings:
		buildings.append(building)
		
		# Determine zone if not provided
		if zone_id.is_empty():
			zone_id = ZoneManager.get_unit_zone(building) if ZoneManager else ""
		
		# Add to zone tracking (initialize zone array if needed)
		if not zone_id.is_empty():
			if zone_id not in buildings_by_zone:
				buildings_by_zone[zone_id] = []
			if building not in buildings_by_zone[zone_id]:
				buildings_by_zone[zone_id].append(building)
		

func unregister_building(building: Node2D):
	"""Unregister a building from tracking"""
	if building in buildings:
		buildings.erase(building)
		
		# Remove from zone tracking
		for zone_id in buildings_by_zone:
			if building in buildings_by_zone[zone_id]:
				buildings_by_zone[zone_id].erase(building)

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
func get_units_in_zone(zone_id: String) -> Array:
	"""Get all units in a specific zone"""
	if zone_id in units_by_zone:
		return units_by_zone[zone_id].duplicate()
	return []

func get_buildings_in_zone(zone_id: String) -> Array:
	"""Get all buildings in a specific zone"""
	if zone_id in buildings_by_zone:
		return buildings_by_zone[zone_id].duplicate()
	return []

func get_resources_in_zone(zone_id: String) -> Array:
	"""Get all resources in a specific zone"""
	if zone_id in resources_by_zone:
		return resources_by_zone[zone_id].duplicate()
	return []

func update_unit_zone(unit: Node2D, old_zone_id: String, new_zone_id: String):
	"""Update unit's zone tracking when it moves between zones"""
	# Remove from old zone
	if old_zone_id in units_by_zone:
		if unit in units_by_zone[old_zone_id]:
			units_by_zone[old_zone_id].erase(unit)
	
	# Add to new zone (initialize array if needed)
	if not new_zone_id in units_by_zone:
		units_by_zone[new_zone_id] = []
	
	if unit not in units_by_zone[new_zone_id]:
		units_by_zone[new_zone_id].append(unit)
		print("EntityManager: Unit transferred to zone '%s' - zone now has %d units" % [new_zone_id, units_by_zone[new_zone_id].size()])

func clear_all():
	"""Clear all entity registrations"""
	units.clear()
	buildings.clear()
	resources.clear()
	projectiles.clear()
	
	# Clear zone tracking
	for zone_id in units_by_zone:
		units_by_zone[zone_id].clear()
	for zone_id in resources_by_zone:
		resources_by_zone[zone_id].clear()
	for zone_id in buildings_by_zone:
		buildings_by_zone[zone_id].clear()
