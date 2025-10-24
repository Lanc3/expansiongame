extends Node
## Handles unit selection including box selection and multi-select

signal selection_changed(selected_units: Array)
signal unit_selected(unit: Node2D)
signal unit_deselected(unit: Node2D)
signal asteroid_selected(asteroid: ResourceNode)
signal asteroid_deselected()
signal building_selected(building: Node2D)
signal building_deselected()

var selected_units: Array = []
var selected_asteroid: ResourceNode = null
var selected_building: Node2D = null
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_end: Vector2 = Vector2.ZERO

func select_unit(unit: Node2D, add_to_selection: bool = false):
	if not is_instance_valid(unit):
		return
	
	# Check if it's an asteroid
	if unit is ResourceNode:
		select_asteroid(unit)
		return
	
	if not add_to_selection:
		clear_selection()
	
	if unit not in selected_units:
		selected_units.append(unit)
		if unit.has_method("set_selected"):
			unit.set_selected(true)
		unit_selected.emit(unit)
	
	selection_changed.emit(selected_units)

func deselect_unit(unit: Node2D):
	if unit in selected_units:
		selected_units.erase(unit)
		if unit.has_method("set_selected"):
			unit.set_selected(false)
		unit_deselected.emit(unit)
		selection_changed.emit(selected_units)

func clear_selection():
	for unit in selected_units:
		if is_instance_valid(unit) and unit.has_method("set_selected"):
			unit.set_selected(false)
			unit_deselected.emit(unit)
	
	selected_units.clear()
	
	# Clear asteroid selection
	if selected_asteroid != null:
		selected_asteroid = null
		asteroid_deselected.emit()
	
	# Clear building selection
	if selected_building != null:
		if selected_building.has_method("set_selected"):
			selected_building.set_selected(false)
		selected_building = null
		building_deselected.emit()
	
	selection_changed.emit(selected_units)

func select_units_in_rect(rect: Rect2, add_to_selection: bool = false):
	if not add_to_selection:
		clear_selection()
	
	var units = EntityManager.units
	for unit in units:
		if not is_instance_valid(unit):
			continue
		
		# Only select player units (team_id 0)
		if unit.has_method("get") and unit.team_id == 0:
			if rect.has_point(unit.global_position):
				select_unit(unit, true)

func has_selection() -> bool:
	return not selected_units.is_empty()

func get_selection_count() -> int:
	return selected_units.size()

func is_unit_selected(unit: Node2D) -> bool:
	return unit in selected_units

func select_asteroid(asteroid: ResourceNode):
	"""Select a single asteroid"""
	# Clear units selection
	for unit in selected_units:
		if is_instance_valid(unit) and unit.has_method("set_selected"):
			unit.set_selected(false)
	selected_units.clear()
	
	# Select asteroid
	selected_asteroid = asteroid
	asteroid_selected.emit(asteroid)
	selection_changed.emit([])

func deselect_asteroid():
	"""Deselect asteroid"""
	if selected_asteroid != null:
		selected_asteroid = null
		asteroid_deselected.emit()
		selection_changed.emit([])

func select_building(building: Node2D):
	"""Select a building"""
	# Clear other selections
	clear_selection()
	
	# Select building
	selected_building = building
	if building.has_method("set_selected"):
		building.set_selected(true)
	building_selected.emit(building)
	
	print("SelectionManager: Building selected")

func deselect_building():
	"""Deselect building"""
	if selected_building != null:
		if selected_building.has_method("set_selected"):
			selected_building.set_selected(false)
		selected_building = null
		building_deselected.emit()
		selection_changed.emit([])

func select_units_by_type(unit_class_name: String):
	"""Select all player units of a specific type"""
	clear_selection()
	var player_units = EntityManager.get_units_by_team(0)
	
	for unit in player_units:
		if not is_instance_valid(unit):
			continue
		
		var matches = false
		match unit_class_name:
			"CommandShip":
				matches = "is_command_ship" in unit and unit.is_command_ship
			"MiningDrone":
				matches = unit is MiningDrone
			"CombatDrone":
				matches = unit is CombatDrone
			"ScoutDrone":
				matches = unit is ScoutDrone
			"BuilderDrone":
				matches = unit is BuilderDrone
			"HeavyDrone":
				matches = unit is HeavyDrone
			"SupportDrone":
				matches = unit is SupportDrone
		
		if matches:
			select_unit(unit, true)
