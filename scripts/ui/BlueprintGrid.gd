extends Control
## Draws the grid and supports cell clicking

signal cell_clicked(cell: Vector2i)

var grid_cols: int = 30
var grid_rows: int = 18
var cell_px: int = 32
var placements: Array = []

func configure_grid(cols: int, rows: int, px: int):
	grid_cols = cols
	grid_rows = rows
	cell_px = px
	queue_redraw()

func set_placements(p: Array):
	placements = p
	queue_redraw()

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell = _screen_to_cell(event.position)
		if cell.x >= 0 and cell.y >= 0 and cell.x < grid_cols and cell.y < grid_rows:
			cell_clicked.emit(cell)

func _screen_to_cell(pos: Vector2) -> Vector2i:
	# In Control._gui_input, event.position is already local to this Control
	var local = pos
	return Vector2i(floor(local.x / cell_px), floor(local.y / cell_px))

func _draw():
	# Draw grid lines
	var color = Color(0.2, 0.7, 1.0, 0.3)
	for x in range(grid_cols + 1):
		var px = float(x * cell_px)
		draw_line(Vector2(px, 0), Vector2(px, grid_rows * cell_px), color, 1.0)
	for y in range(grid_rows + 1):
		var py = float(y * cell_px)
		draw_line(Vector2(0, py), Vector2(grid_cols * cell_px, py), color, 1.0)
	# Draw placed components as rectangles
	for p in placements:
		var comp = BlueprintDatabase.get_component_by_id(p.id)
		if comp.is_empty():
			continue
		var rect = Rect2(p.x * cell_px, p.y * cell_px, comp.size.x * cell_px, comp.size.y * cell_px)
		var fill = Color(0.4, 0.9, 0.6, 0.2)
		draw_rect(rect, fill, true)
		draw_rect(rect, Color(0.4, 0.9, 0.6, 0.8), false, 2.0)
