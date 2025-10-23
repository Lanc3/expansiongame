extends Node

## Manages RTS control groups (Ctrl+1-9 to save, 1-9 to select)

signal group_changed(group_num: int)

# Control groups storage (1-9)
var control_groups: Dictionary = {}

# Badge colors for visual display (cycles through 9 colors)
const BADGE_COLORS = [
	Color(0.2, 1.0, 0.2),    # Green
	Color(0.2, 0.5, 1.0),    # Blue
	Color(1.0, 1.0, 0.2),    # Yellow
	Color(0.8, 0.2, 1.0),    # Purple
	Color(1.0, 0.6, 0.2),    # Orange
	Color(1.0, 0.2, 0.2),    # Red
	Color(0.2, 1.0, 1.0),    # Cyan
	Color(1.0, 0.4, 0.8),    # Pink
	Color(0.6, 1.0, 0.2),    # Lime
]

func _ready():
	# Initialize all 9 control groups as empty
	for i in range(1, 10):
		control_groups[i] = []
	
	

## Assign units to a control group
func assign_group(group_num: int, units: Array):
	if group_num < 1 or group_num > 9:
		push_warning("Invalid control group number: %d" % group_num)
		return
	
	# Remove units from their previous groups (one group per unit)
	for unit in units:
		if is_instance_valid(unit):
			_remove_unit_from_all_groups(unit)
	
	# Assign to new group (only valid units)
	var valid_units = []
	for unit in units:
		if is_instance_valid(unit):
			valid_units.append(unit)
			
			# Connect to died signal for auto-cleanup
			if unit.has_signal("died") and not unit.died.is_connected(_on_unit_died):
				unit.died.connect(_on_unit_died.bind(unit))
	
	control_groups[group_num] = valid_units
	group_changed.emit(group_num)
	


## Get units in a control group (filters out invalid units)
func get_group(group_num: int) -> Array:
	if group_num < 1 or group_num > 9:
		return []
	
	# Filter out invalid units
	var valid_units = []
	for unit in control_groups[group_num]:
		if is_instance_valid(unit):
			valid_units.append(unit)
	
	# Update stored group if any units were invalid
	if valid_units.size() != control_groups[group_num].size():
		control_groups[group_num] = valid_units
	
	return valid_units

## Clear a specific control group
func clear_group(group_num: int):
	if group_num < 1 or group_num > 9:
		return
	
	control_groups[group_num] = []
	group_changed.emit(group_num)
	

## Get which control group a unit belongs to (0 if none)
func get_unit_group(unit: Node2D) -> int:
	if not is_instance_valid(unit):
		return 0
	
	for group_num in range(1, 10):
		if unit in control_groups[group_num]:
			return group_num
	
	return 0

## Get badge color for a group number
func get_badge_color(group_num: int) -> Color:
	if group_num < 1 or group_num > 9:
		return Color.WHITE
	return BADGE_COLORS[group_num - 1]

## Remove unit from all control groups (when destroyed or reassigned)
func _remove_unit_from_all_groups(unit: Node2D):
	for group_num in range(1, 10):
		if unit in control_groups[group_num]:
			control_groups[group_num].erase(unit)
			group_changed.emit(group_num)

## Handle unit death - remove from control groups
func _on_unit_died(unit: Node2D):
	_remove_unit_from_all_groups(unit)
	

## Get count of units in a group
func get_group_count(group_num: int) -> int:
	return get_group(group_num).size()

## Check if a group has any units
func has_units(group_num: int) -> bool:
	return get_group_count(group_num) > 0

