extends Node
## Manages processing states for entities across multiple zones
## Optimizes performance by reducing update frequency for inactive zones

# Zone tracking
var active_zone_id: int = 1
var inactive_update_counter: int = 0
const INACTIVE_UPDATE_INTERVAL: int = 60  # 1 FPS at 60 FPS (background simulation)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("ZoneProcessingManager: Initialized")

func _process(delta: float):
	# Update inactive zones at reduced frequency (1 FPS)
	inactive_update_counter += 1
	if inactive_update_counter >= INACTIVE_UPDATE_INTERVAL:
		inactive_update_counter = 0
		process_inactive_zones(delta * INACTIVE_UPDATE_INTERVAL)

func set_active_zone(zone_id: int):
	"""Switch which zone is actively processed"""
	if zone_id == active_zone_id:
		return
	
	print("ZoneProcessingManager: Switching from Zone %d to Zone %d" % [active_zone_id, zone_id])
	
	# Move old active zone entities to inactive state
	move_entities_to_inactive(active_zone_id)
	
	# Move new active zone entities to active state
	move_entities_to_active(zone_id)
	
	active_zone_id = zone_id

func move_entities_to_inactive(zone_id: int):
	"""Set entities in zone to reduced processing"""
	var units = EntityManager.get_units_in_zone(zone_id) if EntityManager else []
	
	for unit in units:
		if is_instance_valid(unit) and unit.has_method("set_processing_state"):
			unit.set_processing_state(1)  # REDUCED
	
	# Handle buildings
	var buildings = get_zone_buildings(zone_id)
	for building in buildings:
		if is_instance_valid(building) and building.has_method("set_processing_active"):
			building.set_processing_active(false)
	
	print("ZoneProcessingManager: Set Zone %d to REDUCED processing (%d units)" % [zone_id, units.size()])

func move_entities_to_active(zone_id: int):
	"""Set entities in zone to full processing"""
	var units = EntityManager.get_units_in_zone(zone_id) if EntityManager else []
	
	for unit in units:
		if is_instance_valid(unit) and unit.has_method("set_processing_state"):
			unit.set_processing_state(0)  # FULL
	
	# Handle buildings
	var buildings = get_zone_buildings(zone_id)
	for building in buildings:
		if is_instance_valid(building) and building.has_method("set_processing_active"):
			building.set_processing_active(true)
	
	print("ZoneProcessingManager: Set Zone %d to FULL processing (%d units)" % [zone_id, units.size()])

func process_inactive_zones(accumulated_delta: float):
	"""Process inactive zones at 1 FPS"""
	# Inactive zones handle their own reduced update logic
	# This is just to trigger periodic checks
	pass

func get_zone_buildings(zone_id: int) -> Array:
	"""Get all buildings in a zone"""
	var buildings = []
	var all_buildings = get_tree().get_nodes_in_group("enemy_buildings")
	
	for building in all_buildings:
		if is_instance_valid(building) and ZoneManager:
			if ZoneManager.get_unit_zone(building) == zone_id:
				buildings.append(building)
	
	return buildings

func on_unit_spawned(unit: Node2D, zone_id: int):
	"""Called when a new unit is spawned - set appropriate processing state"""
	if not is_instance_valid(unit):
		return
	
	if unit.has_method("set_processing_state"):
		if zone_id == active_zone_id:
			unit.set_processing_state(0)  # FULL
		else:
			unit.set_processing_state(1)  # REDUCED

func on_building_created(building: Node2D, zone_id: int):
	"""Called when a new building is created - set appropriate processing state"""
	if not is_instance_valid(building):
		return
	
	if building.has_method("set_processing_active"):
		building.set_processing_active(zone_id == active_zone_id)



