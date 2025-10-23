extends Resource
class_name BlueprintData
## Resource class storing blueprint grid data and validation

enum ComponentType {
	NONE = -1,
	ENERGY_CORE = 0,
	ENGINE = 1,
	WEAPON_LASER = 2,
	WEAPON_PLASMA = 3,
	MINING_TOOL = 4,
	SHIELD = 5,
	STORAGE = 6,
	ARMOR = 7,
	SENSOR = 8
}

@export var grid_width: int = 3
@export var grid_height: int = 5
@export var blueprint_name: String = "New Blueprint"

# 2D array storing component types (-1 = empty)
var grid_data: Array = []

# Array of component dictionaries for BlueprintEditor
var components: Array = []

func _init():
	initialize_grid()

func initialize_grid():
	grid_data.clear()
	for y in range(grid_height):
		var row = []
		for x in range(grid_width):
			row.append(ComponentType.NONE)
		grid_data.append(row)

func add_component(component_type: ComponentType, x: int, y: int) -> bool:
	if not is_valid_position(x, y):
		return false
	
	# Remove existing component at this position from components array
	remove_component(x, y)
	
	# Add to grid
	grid_data[y][x] = component_type
	
	# Add to components array
	components.append({
		"type": component_type,
		"grid_x": x,
		"grid_y": y
	})
	
	return true

func remove_component(x: int, y: int) -> bool:
	if not is_valid_position(x, y):
		return false
	
	# Remove from components array
	for i in range(components.size() - 1, -1, -1):
		var comp = components[i]
		if comp.grid_x == x and comp.grid_y == y:
			components.remove_at(i)
	
	# Remove from grid
	grid_data[y][x] = ComponentType.NONE
	return true

func get_component(x: int, y: int) -> int:
	if not is_valid_position(x, y):
		return ComponentType.NONE
	return grid_data[y][x]

func is_valid_position(x: int, y: int) -> bool:
	return x >= 0 and x < grid_width and y >= 0 and y < grid_height

func clear_grid():
	initialize_grid()
	components.clear()

func clear_components():
	"""Clear all components from the blueprint"""
	initialize_grid()
	components.clear()

func validate() -> Dictionary:
	"""Alias for validate_blueprint() - used by BlueprintEditor"""
	return validate_blueprint()

func validate_blueprint() -> Dictionary:
	var result = {
		"valid": false,
		"errors": [],
		"warnings": [],
		"energy_balance": 0.0
	}
	
	var has_energy_core = false
	var has_engine = false
	var component_count = 0
	
	# Calculate energy balance
	var stats = calculate_stats()
	result.energy_balance = stats.power
	
	for y in range(grid_height):
		for x in range(grid_width):
			var comp = grid_data[y][x]
			if comp != ComponentType.NONE:
				component_count += 1
				if comp == ComponentType.ENERGY_CORE:
					has_energy_core = true
				elif comp == ComponentType.ENGINE:
					has_engine = true
	
	# Validation rules
	if component_count == 0:
		result.errors.append("Blueprint is empty")
		return result
	
	if not has_energy_core:
		result.errors.append("Missing Energy Core (required)")
	
	if not has_engine:
		result.errors.append("Missing Engine (required)")
	
	if result.energy_balance < 0:
		result.errors.append("Negative energy balance (%.1f)" % result.energy_balance)
	
	if component_count < 3:
		result.warnings.append("Very few components")
	
	# Valid if no errors
	result.valid = result.errors.is_empty()
	return result

func calculate_stats() -> Dictionary:
	var stats = {
		"mass": 0.0,
		"power": 0.0,
		"speed": 0.0,
		"health": 100.0,
		"damage": 0.0,
		"cargo": 0.0,
		"mining_rate": 0.0
	}
	
	for y in range(grid_height):
		for x in range(grid_width):
			var comp = grid_data[y][x]
			match comp:
				ComponentType.ENERGY_CORE:
					stats.power += 100.0
					stats.mass += 20.0
				ComponentType.ENGINE:
					stats.speed += 50.0
					stats.mass += 15.0
				ComponentType.WEAPON_LASER:
					stats.damage += 10.0
					stats.power -= 20.0
					stats.mass += 10.0
				ComponentType.WEAPON_PLASMA:
					stats.damage += 20.0
					stats.power -= 40.0
					stats.mass += 15.0
				ComponentType.MINING_TOOL:
					stats.power -= 10.0
					stats.mass += 12.0
					stats.mining_rate += 5.0
				ComponentType.SHIELD:
					stats.health += 50.0
					stats.power -= 30.0
					stats.mass += 18.0
				ComponentType.STORAGE:
					stats.cargo += 100.0
					stats.mass += 10.0
				ComponentType.ARMOR:
					stats.health += 30.0
					stats.mass += 25.0
				ComponentType.SENSOR:
					stats.mass += 5.0
	
	# Calculate final speed based on mass
	if stats.mass > 0:
		stats.speed = stats.speed / (1.0 + stats.mass / 100.0)
	
	return stats

func get_component_count() -> int:
	var count = 0
	for y in range(grid_height):
		for x in range(grid_width):
			if grid_data[y][x] != ComponentType.NONE:
				count += 1
	return count
