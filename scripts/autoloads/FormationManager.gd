extends Node

## FormationManager - Autoload for managing unit formations during group movement
## Provides line, wedge, and circle formation patterns

signal default_formation_changed(formation_type: FormationType)

enum FormationType {
	NONE,
	LINE,
	WEDGE,
	CIRCLE,
	GRID
}

# Track formation assignments for groups of units
var formation_groups: Dictionary = {}  # group_id -> {units: Array, target: Vector2, type: FormationType}
var unit_formation_offsets: Dictionary = {}  # unit -> Vector2 offset
var next_group_id: int = 0

@export var formation_spacing: float = 40.0
var current_default_formation: FormationType = FormationType.LINE


## Assign formation positions to a group of units moving to the same target
func assign_formation(units: Array, target_position: Vector2, formation_type: FormationType = FormationType.NONE) -> int:
	if units.is_empty():
		return -1
	
	# Use default formation type if none specified
	if formation_type == FormationType.NONE:
		formation_type = current_default_formation
	
	# Create new formation group
	var group_id = next_group_id
	next_group_id += 1
	
	formation_groups[group_id] = {
		"units": units,
		"target": target_position,
		"type": formation_type
	}
	
	# Calculate and assign offsets for each unit
	calculate_formation_offsets(group_id, units, target_position, formation_type)
	
	return group_id

## Calculate formation offsets based on formation type
func calculate_formation_offsets(group_id: int, units: Array, target_position: Vector2, formation_type: FormationType):
	var count = units.size()
	
	# Calculate center of mass of units
	var center = Vector2.ZERO
	for unit in units:
		if is_instance_valid(unit):
			center += unit.global_position
	if count > 0:
		center /= count
	
	# Calculate formation direction (from center of units to target)
	var direction = (target_position - center).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	
	match formation_type:
		FormationType.LINE:
			_calculate_line_formation(units, direction, perpendicular)
		
		FormationType.WEDGE:
			_calculate_wedge_formation(units, direction, perpendicular)
		
		FormationType.CIRCLE:
			_calculate_circle_formation(units)
		
		FormationType.GRID:
			_calculate_grid_formation(units, direction, perpendicular)

## Line formation - units spread horizontally
func _calculate_line_formation(units: Array, direction: Vector2, perpendicular: Vector2):
	var count = units.size()
	var half_count = count / 2.0
	
	for i in range(count):
		var unit = units[i]
		if not is_instance_valid(unit):
			continue
		
		# Spread units along perpendicular axis
		var offset = perpendicular * (i - half_count) * formation_spacing
		unit_formation_offsets[unit] = offset

## Wedge/V formation - classic flying formation
func _calculate_wedge_formation(units: Array, direction: Vector2, perpendicular: Vector2):
	var count = units.size()
	
	# First unit at front (leader)
	if count > 0 and is_instance_valid(units[0]):
		unit_formation_offsets[units[0]] = Vector2.ZERO
	
	# Remaining units form V shape behind leader
	var side = -1
	for i in range(1, count):
		var unit = units[i]
		if not is_instance_valid(unit):
			continue
		
		var row = (i + 1) / 2  # Which row back from leader
		var offset = -direction * (row * formation_spacing * 0.7)  # Back
		offset += perpendicular * (row * formation_spacing * 0.5) * side  # To the side
		
		unit_formation_offsets[unit] = offset
		side *= -1  # Alternate sides

## Circle formation - units form a circle around target
func _calculate_circle_formation(units: Array):
	var count = units.size()
	var radius = formation_spacing * max(1.0, count / (2.0 * PI))
	
	for i in range(count):
		var unit = units[i]
		if not is_instance_valid(unit):
			continue
		
		var angle = (i / float(count)) * TAU
		var offset = Vector2(cos(angle), sin(angle)) * radius
		unit_formation_offsets[unit] = offset

## Grid formation - units in rows and columns
func _calculate_grid_formation(units: Array, direction: Vector2, perpendicular: Vector2):
	var count = units.size()
	var columns = ceil(sqrt(count))
	var rows = ceil(count / columns)
	
	for i in range(count):
		var unit = units[i]
		if not is_instance_valid(unit):
			continue
		
		var row = i / int(columns)
		var col = i % int(columns)
		
		var offset = Vector2.ZERO
		offset += perpendicular * (col - columns / 2.0) * formation_spacing
		offset += -direction * row * formation_spacing  # Negative to go back
		
		unit_formation_offsets[unit] = offset

## Get formation target position for a specific unit
func get_formation_target(unit: Node2D, base_target: Vector2) -> Vector2:
	if unit in unit_formation_offsets:
		return base_target + unit_formation_offsets[unit]
	return base_target

## Check if unit has a formation assignment
func has_formation(unit: Node2D) -> bool:
	return unit in unit_formation_offsets

## Clear formation assignment for a unit
func clear_unit_formation(unit: Node2D):
	if unit in unit_formation_offsets:
		unit_formation_offsets.erase(unit)

## Clear all formations for a group
func clear_formation_group(group_id: int):
	if group_id in formation_groups:
		var units = formation_groups[group_id].units
		for unit in units:
			clear_unit_formation(unit)
		formation_groups.erase(group_id)

## Set the default formation type
func set_default_formation(formation_type: FormationType):
	if current_default_formation != formation_type:
		current_default_formation = formation_type
		default_formation_changed.emit(formation_type)
		

## Get the current default formation type
func get_default_formation() -> FormationType:
	return current_default_formation

## Apply formation to currently selected units at a target position
func apply_formation_to_selected(units: Array, target_position: Vector2):
	if units.is_empty():
		return
	
	assign_formation(units, target_position, current_default_formation)

## Clean up invalid units from tracking
func _process(_delta: float):
	# Clean up invalid units
	var invalid_units = []
	for unit in unit_formation_offsets.keys():
		if not is_instance_valid(unit):
			invalid_units.append(unit)
	
	for unit in invalid_units:
		unit_formation_offsets.erase(unit)
