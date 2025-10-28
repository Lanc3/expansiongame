extends Control
class_name CosmoteerShipGrid
## Visual grid for Cosmoteer-style ship building - handles rendering and input

signal cell_painted(pos: Vector2i, hull_type: CosmoteerShipBlueprint.HullType)
signal cell_erased(pos: Vector2i)
signal component_placed(component_type: String, pos: Vector2i)
signal component_removed(pos: Vector2i)
signal grid_changed()

const GRID_SIZE = 20
const CELL_SIZE = 30  # Pixels per cell

var blueprint: CosmoteerShipBlueprint
var current_paint_mode: String = "none"  # "hull", "component", "erase"
var current_hull_type: CosmoteerShipBlueprint.HullType = CosmoteerShipBlueprint.HullType.LIGHT
var current_component_type: String = ""
var is_painting: bool = false
var hovered_cell: Vector2i = Vector2i(-1, -1)

# Visual feedback
var thrust_status: String = "good"  # "good", "warning", "insufficient"

func _ready():
	custom_minimum_size = Vector2(GRID_SIZE * CELL_SIZE, GRID_SIZE * CELL_SIZE)
	blueprint = CosmoteerShipBlueprint.new()
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _draw():
	draw_background()
	draw_grid_lines()
	draw_hull_cells()
	draw_components()
	draw_hover_highlight()

func draw_background():
	# Background tint based on thrust/weight status
	var bg_color: Color
	match thrust_status:
		"good":
			bg_color = Color(0.1, 0.2, 0.1, 1.0)  # Dark green
		"warning":
			bg_color = Color(0.2, 0.2, 0.1, 1.0)  # Dark yellow
		"insufficient":
			bg_color = Color(0.2, 0.1, 0.1, 1.0)  # Dark red
		_:
			bg_color = Color(0.1, 0.1, 0.1, 1.0)  # Dark gray
	
	draw_rect(Rect2(Vector2.ZERO, size), bg_color, true)

func draw_grid_lines():
	var grid_color = Color(0.3, 0.3, 0.3, 1.0)
	
	# Vertical lines
	for x in range(GRID_SIZE + 1):
		var x_pos = x * CELL_SIZE
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, GRID_SIZE * CELL_SIZE), grid_color, 1.0)
	
	# Horizontal lines
	for y in range(GRID_SIZE + 1):
		var y_pos = y * CELL_SIZE
		draw_line(Vector2(0, y_pos), Vector2(GRID_SIZE * CELL_SIZE, y_pos), grid_color, 1.0)

func draw_hull_cells():
	for cell_pos in blueprint.hull_cells.keys():
		var hull_type_int = blueprint.hull_cells[cell_pos]
		var hull_type = hull_type_int as CosmoteerShipBlueprint.HullType
		var color = CosmoteerComponentDefs.get_hull_color(hull_type)
		var rect = Rect2(
			Vector2(cell_pos.x * CELL_SIZE, cell_pos.y * CELL_SIZE),
			Vector2(CELL_SIZE, CELL_SIZE)
		)
		draw_rect(rect, color, true)
		draw_rect(rect, color.lightened(0.2), false, 1.0)

func draw_components():
	for comp_data in blueprint.components:
		var comp_type = comp_data.get("type", "")
		var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
		var comp_size = comp_data.get("size", Vector2i.ONE)
		
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_type)
		if comp_def.is_empty():
			continue
		
		# Draw component background
		var rect = Rect2(
			Vector2(comp_pos.x * CELL_SIZE, comp_pos.y * CELL_SIZE),
			Vector2(comp_size.x * CELL_SIZE, comp_size.y * CELL_SIZE)
		)
		draw_rect(rect, Color(0.5, 0.5, 0.8, 0.8), true)
		draw_rect(rect, Color(0.8, 0.8, 1.0, 1.0), false, 2.0)
		
		# Draw component name (centered)
		var font = ThemeDB.fallback_font
		var font_size = 10
		var text = comp_def.get("name", "")
		var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos = rect.position + (rect.size - text_size) / 2
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

func draw_hover_highlight():
	if hovered_cell.x < 0 or hovered_cell.y < 0:
		return
	
	if hovered_cell.x >= GRID_SIZE or hovered_cell.y >= GRID_SIZE:
		return
	
	var color = Color(1.0, 1.0, 0.0, 0.3)  # Yellow highlight
	
	if current_paint_mode == "component" and not current_component_type.is_empty():
		# Show component size preview
		var comp_def = CosmoteerComponentDefs.get_component_data(current_component_type)
		if not comp_def.is_empty():
			var comp_size = comp_def.get("size", Vector2i.ONE)
			var rect = Rect2(
				Vector2(hovered_cell.x * CELL_SIZE, hovered_cell.y * CELL_SIZE),
				Vector2(comp_size.x * CELL_SIZE, comp_size.y * CELL_SIZE)
			)
			
			# Check if placement is valid
			if is_valid_component_placement(current_component_type, hovered_cell):
				color = Color(0.0, 1.0, 0.0, 0.3)  # Green if valid
			else:
				color = Color(1.0, 0.0, 0.0, 0.3)  # Red if invalid
			
			draw_rect(rect, color, true)
			draw_rect(rect, Color.WHITE, false, 2.0)
	else:
		# Single cell highlight
		var rect = Rect2(
			Vector2(hovered_cell.x * CELL_SIZE, hovered_cell.y * CELL_SIZE),
			Vector2(CELL_SIZE, CELL_SIZE)
		)
		draw_rect(rect, color, true)

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				is_painting = true
				handle_paint_action(get_grid_position(mouse_event.position))
			else:
				is_painting = false
	
	elif event is InputEventMouseMotion:
		var motion_event = event as InputEventMouseMotion
		hovered_cell = get_grid_position(motion_event.position)
		
		if is_painting and current_paint_mode in ["hull", "erase"]:
			handle_paint_action(hovered_cell)
		
		queue_redraw()

func get_grid_position(mouse_pos: Vector2) -> Vector2i:
	var x = int(mouse_pos.x / CELL_SIZE)
	var y = int(mouse_pos.y / CELL_SIZE)
	return Vector2i(x, y)

func handle_paint_action(pos: Vector2i):
	if pos.x < 0 or pos.y < 0 or pos.x >= GRID_SIZE or pos.y >= GRID_SIZE:
		return
	
	match current_paint_mode:
		"hull":
			paint_hull_cell(pos, current_hull_type)
		"erase":
			erase_cell(pos)
		"component":
			place_component(current_component_type, pos)

func paint_hull_cell(pos: Vector2i, hull_type: CosmoteerShipBlueprint.HullType):
	# Don't paint if there's already a component here
	if not blueprint.get_component_at(pos).is_empty():
		return
	
	# Don't re-paint if same type already exists
	if blueprint.has_hull_at(pos) and blueprint.get_hull_type(pos) == hull_type:
		return
	
	blueprint.add_hull_cell(pos, hull_type)
	cell_painted.emit(pos, hull_type)
	grid_changed.emit()
	queue_redraw()

func erase_cell(pos: Vector2i):
	# Try to remove component first
	var comp = blueprint.get_component_at(pos)
	if not comp.is_empty():
		blueprint.remove_component_at(pos)
		component_removed.emit(pos)
		grid_changed.emit()
	else:
		# Remove hull cell
		if blueprint.has_hull_at(pos):
			blueprint.remove_hull_cell(pos)
			cell_erased.emit(pos)
			grid_changed.emit()
	
	queue_redraw()

func place_component(component_type: String, pos: Vector2i) -> bool:
	if not is_valid_component_placement(component_type, pos):
		return false
	
	var comp_def = CosmoteerComponentDefs.get_component_data(component_type)
	if comp_def.is_empty():
		return false
	
	var component_data = {
		"type": component_type,
		"grid_position": pos,
		"size": comp_def.get("size", Vector2i.ONE)
	}
	
	blueprint.add_component(component_data)
	component_placed.emit(component_type, pos)
	grid_changed.emit()
	queue_redraw()
	return true

func is_valid_component_placement(component_type: String, pos: Vector2i) -> bool:
	var comp_def = CosmoteerComponentDefs.get_component_data(component_type)
	if comp_def.is_empty():
		return false
	
	var comp_size = comp_def.get("size", Vector2i.ONE)
	
	# Check if component fits in grid
	if pos.x + comp_size.x > GRID_SIZE or pos.y + comp_size.y > GRID_SIZE:
		return false
	
	# Check if all cells have hull
	for x in range(comp_size.x):
		for y in range(comp_size.y):
			var check_pos = pos + Vector2i(x, y)
			if not blueprint.has_hull_at(check_pos):
				return false
			
			# Check for overlap with existing components
			var existing_comp = blueprint.get_component_at(check_pos)
			if not existing_comp.is_empty():
				return false
	
	return true

func set_paint_mode_hull(hull_type: CosmoteerShipBlueprint.HullType):
	current_paint_mode = "hull"
	current_hull_type = hull_type
	current_component_type = ""

func set_paint_mode_component(component_type: String):
	current_paint_mode = "component"
	current_component_type = component_type

func set_paint_mode_erase():
	current_paint_mode = "erase"
	current_component_type = ""

func load_blueprint(new_blueprint: CosmoteerShipBlueprint):
	blueprint = new_blueprint.duplicate_blueprint()
	queue_redraw()

func get_current_blueprint() -> CosmoteerShipBlueprint:
	return blueprint

func clear_grid():
	blueprint.clear()
	grid_changed.emit()
	queue_redraw()

func set_thrust_status(status: String):
	thrust_status = status
	queue_redraw()

