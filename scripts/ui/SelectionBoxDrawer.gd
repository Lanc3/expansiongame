extends ColorRect
## Draws the selection box during drag selection

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	color = Color(1.0, 1.0, 1.0, 0.3)  # White semi-transparent

func _process(_delta: float):
	if SelectionManager.is_dragging:
		visible = true
		update_selection_box()
	else:
		visible = false

func update_selection_box():
	# Get current mouse position in screen space
	var start_screen = SelectionManager.drag_start
	var current_screen = get_viewport().get_mouse_position()
	
	# Calculate rectangle in screen space
	var min_x = min(start_screen.x, current_screen.x)
	var min_y = min(start_screen.y, current_screen.y)
	var max_x = max(start_screen.x, current_screen.x)
	var max_y = max(start_screen.y, current_screen.y)
	
	# Apply to the ColorRect (use global_position to ignore parent transforms)
	global_position = Vector2(min_x, min_y)
	size = Vector2(max_x - min_x, max_y - min_y)
