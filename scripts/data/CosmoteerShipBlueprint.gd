class_name CosmoteerShipBlueprint
extends Resource
## Data structure for Cosmoteer-style ship blueprints with hull painting

@export var blueprint_name: String = "Untitled Ship"
@export var grid_size: Vector2i = Vector2i(20, 20)
@export var hull_cells: Dictionary = {}  # Vector2i -> int (HullType as int for serialization)
@export var components: Array = []  # Array of component dictionaries
@export var thumbnail_data: PackedByteArray = []  # Stored as PNG bytes

enum HullType { LIGHT, MEDIUM, HEAVY }

func _init():
	hull_cells = {}
	components = []

func add_hull_cell(pos: Vector2i, hull_type: HullType):
	hull_cells[pos] = int(hull_type)

func remove_hull_cell(pos: Vector2i):
	hull_cells.erase(pos)

func has_hull_at(pos: Vector2i) -> bool:
	return hull_cells.has(pos)

func get_hull_type(pos: Vector2i) -> HullType:
	var type_int = hull_cells.get(pos, int(HullType.LIGHT))
	return type_int as HullType

func add_component(component_data: Dictionary):
	components.append(component_data)

func remove_component_at(pos: Vector2i):
	for i in range(components.size() - 1, -1, -1):
		var comp = components[i]
		var comp_pos = comp.get("grid_position", Vector2i.ZERO)
		var comp_size = comp.get("size", Vector2i.ONE)
		
		# Check if position is within component bounds
		if pos.x >= comp_pos.x and pos.x < comp_pos.x + comp_size.x:
			if pos.y >= comp_pos.y and pos.y < comp_pos.y + comp_size.y:
				components.remove_at(i)
				return

func get_component_at(pos: Vector2i) -> Dictionary:
	for comp in components:
		var comp_pos = comp.get("grid_position", Vector2i.ZERO)
		var comp_size = comp.get("size", Vector2i.ONE)
		
		if pos.x >= comp_pos.x and pos.x < comp_pos.x + comp_size.x:
			if pos.y >= comp_pos.y and pos.y < comp_pos.y + comp_size.y:
				return comp
	
	return {}

func clear():
	hull_cells.clear()
	components.clear()

func duplicate_blueprint() -> CosmoteerShipBlueprint:
	var new_blueprint = CosmoteerShipBlueprint.new()
	new_blueprint.blueprint_name = blueprint_name
	new_blueprint.grid_size = grid_size
	new_blueprint.hull_cells = hull_cells.duplicate(true)
	new_blueprint.components = components.duplicate(true)
	new_blueprint.thumbnail_data = thumbnail_data.duplicate()
	return new_blueprint

func get_hull_cell_count() -> int:
	return hull_cells.size()

func get_component_count() -> int:
	return components.size()

