extends Camera2D
class_name RTSCamera
## RTS-style camera with WASD, edge scrolling, and zoom

@export var move_speed: float = 500.0
@export var edge_scroll_speed: float = 400.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.25
@export var max_zoom: float = 2.0
@export var edge_scroll_margin: int = 5
@export var enable_edge_scrolling: bool = true

# Camera bounds
@export var use_bounds: bool = true
var current_zone_bounds: Rect2 = Rect2(-2000, -2000, 4000, 4000)

func _ready():
	zoom = Vector2(1.0, 1.0)
	
	# Start at origin (where command ship spawns in Zone 1)
	global_position = Vector2.ZERO
	print("RTSCamera: Starting at position (0, 0)")
	
	# Initialize bounds from ZoneManager
	if ZoneManager:
		var zone = ZoneManager.get_current_zone()
		if not zone.is_empty():
			set_zone_bounds(zone.boundaries)

func _process(delta: float):
	handle_keyboard_movement(delta)
	
	if enable_edge_scrolling:
		handle_edge_scrolling(delta)
	
	handle_zoom()
	
	if use_bounds:
		clamp_camera_position()

func handle_keyboard_movement(delta: float):
	var movement = Vector2.ZERO
	
	if Input.is_action_pressed("camera_up"):
		movement.y -= 1
	if Input.is_action_pressed("camera_down"):
		movement.y += 1
	if Input.is_action_pressed("camera_left"):
		movement.x -= 1
	if Input.is_action_pressed("camera_right"):
		movement.x += 1
	
	if movement != Vector2.ZERO:
		position += movement.normalized() * move_speed * delta / zoom.x

func handle_edge_scrolling(delta: float):
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size
	var movement = Vector2.ZERO
	
	# Check each edge
	if mouse_pos.x < edge_scroll_margin:
		movement.x -= 1
	elif mouse_pos.x > viewport_size.x - edge_scroll_margin:
		movement.x += 1
	
	if mouse_pos.y < edge_scroll_margin:
		movement.y -= 1
	elif mouse_pos.y > viewport_size.y - edge_scroll_margin:
		movement.y += 1
	
	if movement != Vector2.ZERO:
		position += movement.normalized() * edge_scroll_speed * delta / zoom.x

func handle_zoom():
	# Don't zoom if paint mode is active (InputHandler uses wheel for circle radius)
	var input_handler = get_node_or_null("../Systems/InputHandler")
	if input_handler and input_handler.paint_mode_active:
		return
	
	var zoom_delta = 0.0
	
	if Input.is_action_just_pressed("zoom_in"):
		zoom_delta = zoom_speed
	elif Input.is_action_just_pressed("zoom_out"):
		zoom_delta = -zoom_speed
	
	if zoom_delta != 0.0:
		zoom_camera(zoom_delta)

func zoom_camera(amount: float):
	var new_zoom = zoom.x + amount
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)

func clamp_camera_position():
	var bounds_min = current_zone_bounds.position
	var bounds_max = current_zone_bounds.position + current_zone_bounds.size
	position.x = clamp(position.x, bounds_min.x, bounds_max.x)
	position.y = clamp(position.y, bounds_min.y, bounds_max.y)

func set_zone_bounds(bounds: Rect2):
	"""Update camera bounds based on current zone"""
	current_zone_bounds = bounds
	
	# Immediately clamp position to new bounds
	if use_bounds:
		clamp_camera_position()

func focus_on_position(target_position: Vector2, duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, duration)
