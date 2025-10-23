extends Control
## Renders fog of war overlay by drawing tiles directly in screen space

var current_zone_id: int = 1
var camera: Camera2D
var last_camera_pos: Vector2 = Vector2.ZERO
var last_camera_zoom: float = 1.0
const REDRAW_THRESHOLD: float = 50.0  # Redraw if camera moves 50 units

func _ready():
	# Find camera
	camera = get_tree().get_root().find_child("Camera2D", true, false)
	
	# Make fullscreen - force all anchors and offsets
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Ensure we're visible but behind UI
	modulate = Color.WHITE
	z_index = -10  # Behind UI elements
	
	# Connect to zone manager
	if ZoneManager:
		ZoneManager.zone_switched.connect(_on_zone_switched)
		current_zone_id = ZoneManager.current_zone_id
	
	# Connect to fog manager for change notifications
	if FogOfWarManager:
		if FogOfWarManager.has_signal("fog_revealed"):
			FogOfWarManager.fog_revealed.connect(_on_fog_revealed)
	
	# Initialize camera tracking
	if camera:
		last_camera_pos = camera.global_position
		last_camera_zoom = camera.zoom.x
	
	# Enable processing for conditional redraw
	set_process(true)

func _process(_delta: float):
	if not camera:
		return
	
	# Only redraw if camera moved significantly or zoom changed
	var current_pos = camera.global_position
	var current_zoom = camera.zoom.x
	
	if last_camera_pos.distance_to(current_pos) > REDRAW_THRESHOLD or abs(last_camera_zoom - current_zoom) > 0.01:
		last_camera_pos = current_pos
		last_camera_zoom = current_zoom
		queue_redraw()

func _draw():
	if not FogOfWarManager or not camera:
		return
	
	var grid = FogOfWarManager.get_fog_grid(current_zone_id)
	if grid.is_empty():
		return
	
	var zone = ZoneManager.get_zone(current_zone_id)
	if zone.is_empty():
		return
	
	var zone_bounds = zone.boundaries
	var grid_height = grid.size()
	var grid_width = grid[0].size()
	var tile_size = FogOfWarManager.TILE_SIZE
	var render_tile_size = tile_size * 2.5  # Render tiles 2.5x larger for full edge coverage
	
	# Get viewport size and camera info
	var viewport = get_viewport()
	var viewport_size = viewport.get_visible_rect().size
	var control_size = size
	var camera_pos = camera.global_position
	var camera_zoom = camera.zoom.x
	
	# Calculate visible world area
	var visible_world_size = viewport_size / camera_zoom
	var padding = render_tile_size * 4.0
	var visible_world_min = camera_pos - (visible_world_size / 2.0) - Vector2(padding, padding)
	var visible_world_max = camera_pos + (visible_world_size / 2.0) + Vector2(padding, padding)
	
	# Step 1: Draw black fog for areas OUTSIDE the current zone boundaries
	# Calculate zone boundaries in screen space
	var zone_min_world = zone_bounds.position
	var zone_max_world = zone_bounds.position + zone_bounds.size
	var zone_min_screen = world_to_screen(zone_min_world, camera_pos, camera_zoom, viewport_size)
	var zone_max_screen = world_to_screen(zone_max_world, camera_pos, camera_zoom, viewport_size)
	
	# Draw black rectangles for areas outside zone
	# Top area (above zone)
	if zone_min_screen.y > 0:
		draw_rect(Rect2(0, 0, control_size.x, max(0, zone_min_screen.y)), Color(0, 0, 0, 1.0))
	# Bottom area (below zone)
	if zone_max_screen.y < control_size.y:
		draw_rect(Rect2(0, max(0, zone_max_screen.y), control_size.x, control_size.y - max(0, zone_max_screen.y)), Color(0, 0, 0, 1.0))
	# Left area (left of zone) - full height
	if zone_min_screen.x > 0:
		var y_start = clamp(zone_min_screen.y, 0, control_size.y)
		var y_end = clamp(zone_max_screen.y, 0, control_size.y)
		draw_rect(Rect2(0, y_start, max(0, zone_min_screen.x), y_end - y_start), Color(0, 0, 0, 1.0))
	# Right area (right of zone) - full height
	if zone_max_screen.x < control_size.x:
		var y_start = clamp(zone_min_screen.y, 0, control_size.y)
		var y_end = clamp(zone_max_screen.y, 0, control_size.y)
		draw_rect(Rect2(min(zone_max_screen.x, control_size.x), y_start, control_size.x - min(zone_max_screen.x, control_size.x), y_end - y_start), Color(0, 0, 0, 1.0))
	
	# Step 2: Draw black fog tiles for unexplored areas WITHIN the zone
	for y in range(grid_height):
		for x in range(grid_width):
			if grid[y][x]:  # Already explored - skip
				continue
			
			# Calculate tile world position (center of the logical tile for better coverage)
			var tile_world_x = zone_bounds.position.x + (x * tile_size) + (tile_size * 0.5)
			var tile_world_y = zone_bounds.position.y + (y * tile_size) + (tile_size * 0.5)
			# Offset by half render size to center the larger render tile
			var tile_render_x = tile_world_x - (render_tile_size * 0.5)
			var tile_render_y = tile_world_y - (render_tile_size * 0.5)
			var tile_world_pos = Vector2(tile_render_x, tile_render_y)
			
			# Check if tile is visible on screen (very lenient culling with large margin)
			var tile_end_x = tile_render_x + render_tile_size
			var tile_end_y = tile_render_y + render_tile_size
			if tile_end_x < visible_world_min.x or tile_render_x > visible_world_max.x:
				continue
			if tile_end_y < visible_world_min.y or tile_render_y > visible_world_max.y:
				continue
			
			# Convert world position to screen position
			var screen_pos = world_to_screen(tile_world_pos, camera_pos, camera_zoom, viewport_size)
			# Render at 2x size with extra overlap to ensure edge coverage
			var screen_size = Vector2(render_tile_size, render_tile_size) * camera_zoom + Vector2(2, 2)
			
			# Draw black fog tile for unexplored area
			draw_rect(Rect2(screen_pos, screen_size), Color(0, 0, 0, 1.0))
			
			# Draw feathered edges for blur effect (3x larger for more pronounced blur)
			var feather = 24.0 * camera_zoom  # Increased from 8.0 to 24.0 (3x)
			draw_rect(Rect2(screen_pos.x - feather, screen_pos.y - feather, screen_size.x + feather * 2, screen_size.y + feather * 2), Color(0, 0, 0, 0.3))
			draw_rect(Rect2(screen_pos.x - feather * 2, screen_pos.y - feather * 2, screen_size.x + feather * 4, screen_size.y + feather * 4), Color(0, 0, 0, 0.2))
			draw_rect(Rect2(screen_pos.x - feather * 3, screen_pos.y - feather * 3, screen_size.x + feather * 6, screen_size.y + feather * 6), Color(0, 0, 0, 0.1))

func world_to_screen(world_pos: Vector2, camera_pos: Vector2, camera_zoom: float, viewport_size: Vector2) -> Vector2:
	"""Convert world position to screen position"""
	var relative_pos = world_pos - camera_pos
	var screen_pos = (relative_pos * camera_zoom) + (viewport_size / 2.0)
	return screen_pos

func _on_zone_switched(_from_zone_id: int, to_zone_id: int):
	"""Handle zone switch"""
	current_zone_id = to_zone_id
	if camera:
		last_camera_pos = camera.global_position
		last_camera_zoom = camera.zoom.x
	queue_redraw()

func _on_fog_revealed(zone_id: int):
	"""Handle fog revelation notification"""
	if zone_id == current_zone_id:
		queue_redraw()

