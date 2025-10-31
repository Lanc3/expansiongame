class_name CosmoteerShipBlueprint
extends Resource
## Data structure for Cosmoteer-style ship blueprints with hull painting

@export var blueprint_name: String = "Untitled Ship"
@export var grid_size: Vector2i = Vector2i(40, 40)
@export var forward_direction: Vector2 = Vector2(0, -1)  # Ship's forward facing direction (default: up)
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
	new_blueprint.forward_direction = forward_direction
	new_blueprint.hull_cells = hull_cells.duplicate(true)
	new_blueprint.components = components.duplicate(true)
	new_blueprint.thumbnail_data = thumbnail_data.duplicate()
	return new_blueprint

func get_hull_cell_count() -> int:
	return hull_cells.size()

func get_component_count() -> int:
	return components.size()

func is_hull_contiguous() -> bool:
	"""Check if all hull cells form a single connected structure"""
	if hull_cells.is_empty():
		return true  # Empty ship is technically contiguous
	
	var islands = get_hull_islands()
	return islands.size() <= 1

func get_hull_islands() -> Array[Array]:
	"""Returns separate groups of connected hull cells"""
	if hull_cells.is_empty():
		return []
	
	var visited: Dictionary = {}
	var islands: Array[Array] = []
	
	# Try each hull cell as a potential island start
	for cell_pos in hull_cells.keys():
		if visited.has(cell_pos):
			continue
		
		# Found a new island - flood fill from here
		var island: Array = []
		var queue: Array[Vector2i] = [cell_pos]
		
		while queue.size() > 0:
			var current = queue.pop_front()
			
			if visited.has(current):
				continue
			
			if not hull_cells.has(current):
				continue
			
			visited[current] = true
			island.append(current)
			
			# Check 4-directional neighbors
			var neighbors = [
				current + Vector2i(1, 0),
				current + Vector2i(-1, 0),
				current + Vector2i(0, 1),
				current + Vector2i(0, -1)
			]
			
			for neighbor in neighbors:
				if not visited.has(neighbor) and hull_cells.has(neighbor):
					queue.append(neighbor)
		
		islands.append(island)
	
	return islands

func get_ship_bounds() -> Rect2:
	"""Returns the bounding box of all hull cells"""
	if hull_cells.is_empty():
		return Rect2(0, 0, 0, 0)
	
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for cell_pos in hull_cells.keys():
		min_x = min(min_x, cell_pos.x)
		max_x = max(max_x, cell_pos.x)
		min_y = min(min_y, cell_pos.y)
		max_y = max(max_y, cell_pos.y)
	
	return Rect2(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func calculate_center_of_mass() -> Vector2:
	"""Calculate the weighted center of mass of the ship"""
	if hull_cells.is_empty() and components.is_empty():
		return Vector2.ZERO
	
	var total_mass: float = 0.0
	var weighted_position: Vector2 = Vector2.ZERO
	
	# Add hull mass
	for cell_pos in hull_cells.keys():
		var hull_type = get_hull_type(cell_pos)
		var mass = CosmoteerComponentDefs.get_hull_weight(hull_type)
		total_mass += mass
		weighted_position += Vector2(cell_pos) * mass
	
	# Add component mass
	for comp_data in components:
		var comp_type = comp_data.get("type", "")
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_type)
		if comp_def.is_empty():
			continue
		
		var mass = comp_def.get("weight", 0.0)
		var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
		var comp_size = comp_data.get("size", Vector2i.ONE)
		
		# Use center of component
		var center = Vector2(comp_pos) + Vector2(comp_size) * 0.5
		total_mass += mass
		weighted_position += center * mass
	
	if total_mass > 0:
		return weighted_position / total_mass
	
	# Fallback to geometric center
	var bounds = get_ship_bounds()
	return Vector2(bounds.position.x + bounds.size.x * 0.5, bounds.position.y + bounds.size.y * 0.5)

