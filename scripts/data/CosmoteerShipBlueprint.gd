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
		
		# Get hex cells occupied by this component
		var hex_cells = HexGrid.get_component_hex_cells(comp_pos, comp_size)
		
		# Check if pos is in hex_cells
		if pos in hex_cells:
			components.remove_at(i)
			return

func get_component_at(pos: Vector2i) -> Dictionary:
	for comp in components:
		var comp_pos = comp.get("grid_position", Vector2i.ZERO)
		var comp_size = comp.get("size", Vector2i.ONE)
		
		# Get hex cells occupied by this component
		var hex_cells = HexGrid.get_component_hex_cells(comp_pos, comp_size)
		
		# Check if pos is in hex_cells
		if pos in hex_cells:
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
			
			# Check 6-directional neighbors (hex grid)
			var neighbors = HexGrid.get_hex_neighbors(current)
			
			for neighbor in neighbors:
				if not visited.has(neighbor) and hull_cells.has(neighbor):
					queue.append(neighbor)
		
		islands.append(island)
	
	return islands

func get_ship_bounds() -> Rect2:
	"""Returns the bounding box of all hull cells in pixel coordinates"""
	if hull_cells.is_empty():
		return Rect2(0, 0, 0, 0)
	
	var cell_size = 15.0  # CELL_SIZE from CosmoteerShipGrid
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	# Convert hex positions to pixel positions and find bounds
	for cell_pos in hull_cells.keys():
		var pixel_pos = HexGrid.hex_to_pixel(cell_pos, cell_size)
		var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, cell_size)
		# Check all vertices of hexagon for bounds
		for vertex in hex_vertices:
			min_x = min(min_x, vertex.x)
			max_x = max(max_x, vertex.x)
			min_y = min(min_y, vertex.y)
			max_y = max(max_y, vertex.y)
	
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)

func calculate_center_of_mass() -> Vector2:
	"""Calculate the weighted center of mass of the ship in pixel coordinates"""
	if hull_cells.is_empty() and components.is_empty():
		return Vector2.ZERO
	
	var total_mass: float = 0.0
	var weighted_position: Vector2 = Vector2.ZERO
	var cell_size = 15.0  # CELL_SIZE from CosmoteerShipGrid
	
	# Add hull mass - convert hex positions to pixel positions
	for cell_pos in hull_cells.keys():
		var hull_type = get_hull_type(cell_pos)
		var mass = CosmoteerComponentDefs.get_hull_weight(hull_type)
		total_mass += mass
		# Convert hex coordinate to pixel position
		var pixel_pos = HexGrid.hex_to_pixel(cell_pos, cell_size)
		weighted_position += pixel_pos * mass
	
	# Add component mass
	for comp_data in components:
		var comp_type = comp_data.get("type", "")
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_type)
		if comp_def.is_empty():
			continue
		
		var mass = comp_def.get("weight", 0.0)
		var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
		var comp_size = comp_data.get("size", Vector2i.ONE)
		
		# Get hex cells occupied by component, calculate center in pixel space
		var hex_cells = HexGrid.get_component_hex_cells(comp_pos, comp_size)
		var center_hex = Vector2.ZERO
		for hex_pos in hex_cells:
			center_hex += Vector2(hex_pos)
		center_hex /= hex_cells.size()
		var center_px = HexGrid.hex_to_pixel(Vector2i(int(center_hex.x), int(center_hex.y)), cell_size)
		
		total_mass += mass
		weighted_position += center_px * mass
	
	if total_mass > 0:
		return weighted_position / total_mass
	
	# Fallback to geometric center
	var bounds = get_ship_bounds()
	return Vector2(bounds.position.x + bounds.size.x * 0.5, bounds.position.y + bounds.size.y * 0.5)

