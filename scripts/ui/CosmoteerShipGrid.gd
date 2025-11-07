extends Control
class_name CosmoteerShipGrid
## Visual grid for Cosmoteer-style ship building - handles rendering and input

signal cell_painted(pos: Vector2i, hull_type: CosmoteerShipBlueprint.HullType)
signal cell_erased(pos: Vector2i)
signal component_placed(component_type: String, pos: Vector2i)
signal component_removed(pos: Vector2i)
signal grid_changed()

const GRID_SIZE = 40  # Doubled from 20 to compensate for halved cell size
const CELL_SIZE = 15  # Pixels per cell (halved from 30)

var blueprint: CosmoteerShipBlueprint
var current_paint_mode: String = "none"  # "hull", "component", "erase"
var current_hull_type: CosmoteerShipBlueprint.HullType = CosmoteerShipBlueprint.HullType.LIGHT
var current_component_type: String = ""
var is_painting: bool = false
var hovered_cell: Vector2i = Vector2i(-1, -1)

# Visual feedback
var thrust_status: String = "good"  # "good", "warning", "insufficient"

# Texture cache
var texture_cache: Dictionary = {}

func _ready():
	# Don't set custom_minimum_size - let parent container handle sizing
	# The grid will be drawn centered within available space
	blueprint = CosmoteerShipBlueprint.new()
	
	# CRITICAL: Must be STOP to receive mouse input
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Ensure we fill parent container to receive mouse events everywhere
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	_preload_textures()
	queue_redraw()

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		# Force redraw when resized to update grid centering
		queue_redraw()
		print("ShipGrid resized to: ", size)

func _preload_textures():
	"""Preload all component and hull textures into cache"""
	# Load hull textures
	for hull_type in [CosmoteerShipBlueprint.HullType.LIGHT, CosmoteerShipBlueprint.HullType.MEDIUM, CosmoteerShipBlueprint.HullType.HEAVY]:
		var texture_path = CosmoteerComponentDefs.get_hull_texture(hull_type)
		if texture_path and ResourceLoader.exists(texture_path):
			texture_cache[texture_path] = load(texture_path)
			if texture_cache[texture_path]:
				print("Loaded hull texture: ", texture_path)
			else:
				print("Failed to load hull texture: ", texture_path)
	
	# Load component textures
	for comp_type in CosmoteerComponentDefs.get_all_component_types():
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_type)
		var sprite_path = comp_def.get("sprite", "")
		if sprite_path and ResourceLoader.exists(sprite_path):
			if not texture_cache.has(sprite_path):
				texture_cache[sprite_path] = load(sprite_path)
				if texture_cache[sprite_path]:
					print("Loaded component texture: ", sprite_path)
				else:
					print("Failed to load component texture: ", sprite_path)

func _draw():
	draw_background()
	draw_grid_lines()
	draw_hull_cells()
	draw_components()
	draw_ship_direction_arrow()
	draw_engine_thrust_vectors()
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
	
	# Draw background to ensure Control has a rect for mouse input
	# Use slightly transparent so we can see if it's working
	draw_rect(Rect2(Vector2.ZERO, size), bg_color, true)

func draw_grid_lines():
	var grid_color = Color(0.3, 0.3, 0.3, 1.0)
	
	# Calculate grid bounds to center it
	var grid_bounds = _calculate_grid_bounds()
	var offset = (size - grid_bounds.size) / 2.0 - grid_bounds.position
	
	# Draw hexagon outlines for each hex cell in the grid
	for q in range(GRID_SIZE):
		for r in range(GRID_SIZE):
			var hex_pos = Vector2i(q, r)
			var pixel_pos = HexGrid.hex_to_pixel(hex_pos, CELL_SIZE) + offset
			var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, CELL_SIZE)
			draw_polyline(hex_vertices, grid_color, 1.0, true)

func draw_hull_cells():
	# Calculate grid bounds to center it
	var grid_bounds = _calculate_grid_bounds()
	var offset = (size - grid_bounds.size) / 2.0 - grid_bounds.position
	
	for cell_pos in blueprint.hull_cells.keys():
		var hull_type_int = blueprint.hull_cells[cell_pos]
		var hull_type = hull_type_int as CosmoteerShipBlueprint.HullType
		
		# Convert hex coordinates to pixel position with offset
		var pixel_pos = HexGrid.hex_to_pixel(cell_pos, CELL_SIZE) + offset
		var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, CELL_SIZE)
		
		# Draw hull texture from cache
		var texture_path = CosmoteerComponentDefs.get_hull_texture(hull_type)
		if texture_path and texture_cache.has(texture_path):
			var texture = texture_cache[texture_path]
			if texture:
				# Calculate UV coordinates for hex vertices
				# Map hex vertices to texture UV space (0-1)
				var bounds = _get_hex_bounds(hex_vertices)
				var uv_coords = PackedVector2Array()
				for vertex in hex_vertices:
					# Convert vertex position to UV coordinates relative to bounds
					var uv_x = (vertex.x - bounds.position.x) / bounds.size.x if bounds.size.x > 0 else 0.5
					var uv_y = (vertex.y - bounds.position.y) / bounds.size.y if bounds.size.y > 0 else 0.5
					uv_coords.append(Vector2(uv_x, uv_y))
				
				# Draw texture clipped to hex shape
				# draw_polygon(points, colors, uv_coords, texture)
				draw_polygon(hex_vertices, [], uv_coords, texture)
			else:
				# Fallback to color if texture is null
				_draw_hull_fallback_hex(hex_vertices, hull_type)
		else:
			# Fallback to color if no texture
			_draw_hull_fallback_hex(hex_vertices, hull_type)

func _draw_hull_fallback(rect: Rect2, hull_type: CosmoteerShipBlueprint.HullType):
	"""Draw hull as colored rectangle (fallback) - kept for compatibility"""
	var color = CosmoteerComponentDefs.get_hull_color(hull_type)
	draw_rect(rect, color, true)
	draw_rect(rect, color.lightened(0.2), false, 1.0)

func _draw_hull_fallback_hex(hex_vertices: PackedVector2Array, hull_type: CosmoteerShipBlueprint.HullType):
	"""Draw hull as colored hexagon (fallback)"""
	var color = CosmoteerComponentDefs.get_hull_color(hull_type)
	draw_colored_polygon(hex_vertices, color)
	draw_polyline(hex_vertices, color.lightened(0.2), 1.0, true)

func _get_hex_bounds(hex_vertices: PackedVector2Array) -> Rect2:
	"""Get bounding rectangle for hex vertices"""
	if hex_vertices.is_empty():
		return Rect2()
	
	var min_x = hex_vertices[0].x
	var max_x = hex_vertices[0].x
	var min_y = hex_vertices[0].y
	var max_y = hex_vertices[0].y
	
	for vertex in hex_vertices:
		min_x = min(min_x, vertex.x)
		max_x = max(max_x, vertex.x)
		min_y = min(min_y, vertex.y)
		max_y = max(max_y, vertex.y)
	
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)

func _calculate_grid_bounds() -> Rect2:
	"""Calculate the bounding box of the entire hex grid"""
	if GRID_SIZE == 0:
		return Rect2()
	
	# Find bounds of all hex cells
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for q in range(GRID_SIZE):
		for r in range(GRID_SIZE):
			var hex_pos = Vector2i(q, r)
			var pixel_pos = HexGrid.hex_to_pixel(hex_pos, CELL_SIZE)
			var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, CELL_SIZE)
			for vertex in hex_vertices:
				min_x = min(min_x, vertex.x)
				max_x = max(max_x, vertex.x)
				min_y = min(min_y, vertex.y)
				max_y = max(max_y, vertex.y)
	
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)

func draw_components():
	# Calculate grid bounds to center it
	var grid_bounds = _calculate_grid_bounds()
	var offset = (size - grid_bounds.size) / 2.0 - grid_bounds.position
	
	for comp_data in blueprint.components:
		var comp_id = comp_data.get("type", "")
		var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
		var comp_size = comp_data.get("size", Vector2i.ONE)
		
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_id)
		if comp_def.is_empty():
			continue
		
		# Get hex cells occupied by this component
		var hex_cells = HexGrid.get_component_hex_cells(comp_pos, comp_size)
		
		# Calculate bounding box from hex cell positions for texture scaling
		var min_x = INF
		var max_x = -INF
		var min_y = INF
		var max_y = -INF
		for hex_pos in hex_cells:
			var pixel_pos = HexGrid.hex_to_pixel(hex_pos, CELL_SIZE) + offset
			var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, CELL_SIZE)
			for vertex in hex_vertices:
				min_x = min(min_x, vertex.x)
				max_x = max(max_x, vertex.x)
				min_y = min(min_y, vertex.y)
				max_y = max(max_y, vertex.y)
		
		var bounds = Rect2(min_x, min_y, max_x - min_x, max_y - min_y)
		
		# Draw component texture from cache
		var sprite_path = comp_def.get("sprite", "")
		if sprite_path and texture_cache.has(sprite_path):
			var texture = texture_cache[sprite_path]
			if texture:
				# Draw texture scaled to hex bounding box
				draw_texture_rect(texture, bounds, false)
				
				# Draw hexagon outlines for each cell in pattern
				for hex_pos in hex_cells:
					var pixel_pos = HexGrid.hex_to_pixel(hex_pos, CELL_SIZE) + offset
					var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, CELL_SIZE)
					draw_polyline(hex_vertices, Color(0.8, 0.8, 1.0, 1.0), 2.0, true)
				
				# Draw level number in corner
				var parsed = CosmoteerComponentDefs.parse_component_id(comp_id)
				var level = parsed.get("level", 1)
				var font = ThemeDB.fallback_font
				var font_size = 12
				var level_text = "L%d" % level
				var text_pos = bounds.position + Vector2(4, font_size + 2)
				# Draw outline
				draw_string(font, text_pos + Vector2(1, 1), level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)
				# Draw text
				draw_string(font, text_pos, level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0.898, 1, 1))
			else:
				# Fallback to colored hexagons with name
				_draw_component_fallback_hex(hex_cells, comp_def)
		else:
			# Fallback to colored hexagons with name
			_draw_component_fallback_hex(hex_cells, comp_def)

func _draw_component_fallback(rect: Rect2, comp_def: Dictionary):
	"""Draw component as colored rectangle with text label (fallback) - kept for compatibility"""
	draw_rect(rect, Color(0.5, 0.5, 0.8, 0.8), true)
	draw_rect(rect, Color(0.8, 0.8, 1.0, 1.0), false, 2.0)
	
	# Draw component name (centered)
	var font = ThemeDB.fallback_font
	var font_size = 10
	var text = comp_def.get("name", "")
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = rect.position + (rect.size - text_size) / 2
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

func _draw_component_fallback_hex(hex_cells: Array[Vector2i], comp_def: Dictionary):
	"""Draw component as colored hexagons with text label (fallback)"""
	# Calculate grid bounds to center it
	var grid_bounds = _calculate_grid_bounds()
	var offset = (size - grid_bounds.size) / 2.0 - grid_bounds.position
	
	# Draw hexagons
	for hex_pos in hex_cells:
		var pixel_pos = HexGrid.hex_to_pixel(hex_pos, CELL_SIZE) + offset
		var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, CELL_SIZE)
		draw_colored_polygon(hex_vertices, Color(0.5, 0.5, 0.8, 0.8))
		draw_polyline(hex_vertices, Color(0.8, 0.8, 1.0, 1.0), 2.0, true)
	
	# Draw component name (centered on first hex)
	if hex_cells.size() > 0:
		var first_hex_pos = HexGrid.hex_to_pixel(hex_cells[0], CELL_SIZE) + offset
		var font = ThemeDB.fallback_font
		var font_size = 10
		var text = comp_def.get("name", "")
		var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos = first_hex_pos - text_size / 2
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

func draw_hover_highlight():
	if hovered_cell.x < 0 or hovered_cell.y < 0:
		return
	
	if hovered_cell.x >= GRID_SIZE or hovered_cell.y >= GRID_SIZE:
		return
	
	# Calculate grid bounds to center it
	var grid_bounds = _calculate_grid_bounds()
	var offset = (size - grid_bounds.size) / 2.0 - grid_bounds.position
	
	var color = Color(1.0, 1.0, 0.0, 0.3)  # Yellow highlight
	
	if current_paint_mode == "component" and not current_component_type.is_empty():
		# Show component hex pattern preview
		var comp_def = CosmoteerComponentDefs.get_component_data(current_component_type)
		if not comp_def.is_empty():
			var comp_size = comp_def.get("size", Vector2i.ONE)
			var hex_cells = HexGrid.get_component_hex_cells(hovered_cell, comp_size)
			
			# Determine color based on validity
			if is_valid_component_placement(current_component_type, hovered_cell):
				# Check if placement is optimal (for engines: at rear)
				var is_optimal = is_optimal_placement(current_component_type, hovered_cell)
				if is_optimal:
					color = Color(0.0, 1.0, 0.0, 0.3)  # Green if optimal
				else:
					color = Color(1.0, 1.0, 0.0, 0.3)  # Yellow if valid but suboptimal
			else:
				color = Color(1.0, 0.0, 0.0, 0.3)  # Red if invalid
			
			# Draw hexagon preview for each cell in pattern
			for hex_pos in hex_cells:
				if hex_pos.x >= 0 and hex_pos.y >= 0 and hex_pos.x < GRID_SIZE and hex_pos.y < GRID_SIZE:
					var pixel_pos = HexGrid.hex_to_pixel(hex_pos, CELL_SIZE) + offset
					var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, CELL_SIZE)
					draw_colored_polygon(hex_vertices, color)
					draw_polyline(hex_vertices, Color.WHITE, 2.0, true)
	else:
		# Single hex cell highlight
		var pixel_pos = HexGrid.hex_to_pixel(hovered_cell, CELL_SIZE) + offset
		var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, CELL_SIZE)
		draw_colored_polygon(hex_vertices, color)

func is_optimal_placement(component_type: String, pos: Vector2i) -> bool:
	"""Check if component placement is optimal based on type and position"""
	if component_type != "engine":
		return true  # Only engines have placement optimization
	
	if blueprint.get_hull_cell_count() == 0:
		return true  # Can't determine optimal on empty ship
	
	var comp_def = CosmoteerComponentDefs.get_component_data(component_type)
	var comp_size = comp_def.get("size", Vector2i.ONE)
	var hex_cells = HexGrid.get_component_hex_cells(pos, comp_size)
	
	# Calculate center of component in hex space, then convert to pixel
	var center_hex = Vector2.ZERO
	for hex_pos in hex_cells:
		center_hex += Vector2(hex_pos)
	center_hex /= hex_cells.size()
	var engine_center_px = HexGrid.hex_to_pixel(Vector2i(int(center_hex.x), int(center_hex.y)), CELL_SIZE)
	
	# Calculate where this engine would be relative to center of mass
	var center_of_mass = blueprint.calculate_center_of_mass()
	var to_engine = engine_center_px - center_of_mass
	
	if to_engine.length() < 0.1:
		return true  # At center, consider optimal
	
	# Check alignment with rear direction
	var rear_dir = -blueprint.forward_direction
	to_engine = to_engine.normalized()
	var alignment = to_engine.dot(rear_dir)
	
	# Optimal if aligned with rear (> 60 degrees from perpendicular)
	return alignment > 0.5

func _gui_input(event: InputEvent):
	# Debug: ensure we're receiving events
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				is_painting = true
				var grid_pos = get_grid_position(mouse_event.position)
				print("Mouse click at screen: ", mouse_event.position, " -> grid: ", grid_pos)
				handle_paint_action(grid_pos)
			else:
				is_painting = false
	
	elif event is InputEventMouseMotion:
		var motion_event = event as InputEventMouseMotion
		hovered_cell = get_grid_position(motion_event.position)
		
		if is_painting and current_paint_mode in ["hull", "erase"]:
			handle_paint_action(hovered_cell)
		
		queue_redraw()

func get_grid_position(mouse_pos: Vector2) -> Vector2i:
	# Calculate grid offset to center it
	var grid_bounds = _calculate_grid_bounds()
	
	# Ensure we have valid size
	if size.x <= 0 or size.y <= 0 or grid_bounds.size.x <= 0 or grid_bounds.size.y <= 0:
		# Fallback: use grid bounds directly if size not set
		return HexGrid.pixel_to_hex(mouse_pos - grid_bounds.position, CELL_SIZE)
	
	# Calculate offset to center the grid
	# grid_bounds.position is the top-left of the grid bounds (may be negative)
	# We want to center grid_bounds within size
	var offset = (size - grid_bounds.size) / 2.0 - grid_bounds.position
	
	# Convert pixel position to hex coordinates (q, r) - automatically snaps to nearest hex
	# Subtract offset to account for centering
	var adjusted_mouse = mouse_pos - offset
	var hex_pos = HexGrid.pixel_to_hex(adjusted_mouse, CELL_SIZE)
	return hex_pos

func handle_paint_action(pos: Vector2i):
	# Allow painting even if slightly out of bounds (due to hex rounding)
	# But clamp to reasonable range
	if pos.x < -1 or pos.y < -1 or pos.x > GRID_SIZE or pos.y > GRID_SIZE:
		return
	
	# Clamp to valid grid range
	var clamped_pos = Vector2i(clamp(pos.x, 0, GRID_SIZE - 1), clamp(pos.y, 0, GRID_SIZE - 1))
	
	match current_paint_mode:
		"hull":
			paint_hull_cell(clamped_pos, current_hull_type)
		"erase":
			erase_cell(clamped_pos)
		"component":
			place_component(current_component_type, clamped_pos)

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
	var hex_cells = HexGrid.get_component_hex_cells(pos, comp_size)
	
	# Check if all hex cells are within grid bounds
	for hex_pos in hex_cells:
		if hex_pos.x < 0 or hex_pos.y < 0 or hex_pos.x >= GRID_SIZE or hex_pos.y >= GRID_SIZE:
			return false
		
		# Check if hex cell has hull
		if not blueprint.has_hull_at(hex_pos):
			return false
		
		# Check for overlap with existing components
		var existing_comp = blueprint.get_component_at(hex_pos)
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

func draw_ship_direction_arrow():
	"""Draw an arrow showing the ship's forward direction at center of mass"""
	if blueprint.get_hull_cell_count() == 0:
		return
	
	# Calculate grid bounds to center it
	var grid_bounds = _calculate_grid_bounds()
	var offset = (size - grid_bounds.size) / 2.0 - grid_bounds.position
	
	# Center of mass is already in pixel coordinates from calculate_center_of_mass()
	var center_of_mass = blueprint.calculate_center_of_mass()
	var center_px = center_of_mass + offset
	
	# Draw arrow in forward direction
	var forward = blueprint.forward_direction
	var arrow_length = CELL_SIZE * 3
	var arrow_end = center_px + forward * arrow_length
	var arrow_width = CELL_SIZE * 0.5
	
	# Arrow color
	var arrow_color = Color(0.2, 0.8, 1.0, 0.8)  # Cyan
	
	# Draw arrow line
	draw_line(center_px, arrow_end, arrow_color, 3.0)
	
	# Draw arrowhead
	var perpendicular = Vector2(-forward.y, forward.x)
	var arrowhead_size = CELL_SIZE * 0.8
	var arrow_tip = arrow_end
	var arrow_left = arrow_end - forward * arrowhead_size + perpendicular * arrowhead_size * 0.5
	var arrow_right = arrow_end - forward * arrowhead_size - perpendicular * arrowhead_size * 0.5
	
	var arrowhead_points = PackedVector2Array([arrow_tip, arrow_left, arrow_right])
	draw_colored_polygon(arrowhead_points, arrow_color)
	
	# Draw center of mass crosshair
	var crosshair_size = CELL_SIZE * 0.3
	draw_line(center_px - Vector2(crosshair_size, 0), center_px + Vector2(crosshair_size, 0), Color(1, 1, 0, 0.6), 2.0)
	draw_line(center_px - Vector2(0, crosshair_size), center_px + Vector2(0, crosshair_size), Color(1, 1, 0, 0.6), 2.0)

func draw_engine_thrust_vectors():
	"""Draw thrust vector indicators on engines"""
	if blueprint.get_hull_cell_count() == 0:
		return
	
	# Calculate grid bounds to center it
	var grid_bounds = _calculate_grid_bounds()
	var offset = (size - grid_bounds.size) / 2.0 - grid_bounds.position
	
	var rear_dir = -blueprint.forward_direction  # Opposite of forward
	
	for comp_data in blueprint.components:
		if comp_data.get("type", "") != "engine":
			continue
		
		var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
		var comp_size = comp_data.get("size", Vector2i.ONE)
		var hex_cells = HexGrid.get_component_hex_cells(comp_pos, comp_size)
		
		# Calculate center of component in hex space, then convert to pixel
		var center_hex = Vector2.ZERO
		for hex_pos in hex_cells:
			center_hex += Vector2(hex_pos)
		center_hex /= hex_cells.size()
		var engine_center_px = HexGrid.hex_to_pixel(Vector2i(int(center_hex.x), int(center_hex.y)), CELL_SIZE) + offset
		
		# Draw thrust vector from engine center
		var thrust_length = CELL_SIZE * 1.5
		var thrust_end = engine_center_px + rear_dir * thrust_length
		
		# Color based on alignment with rear
		var center_of_mass = blueprint.calculate_center_of_mass()
		var to_engine = engine_center_px - center_of_mass
		var alignment = 0.0
		if to_engine.length() > 0.1:
			alignment = to_engine.normalized().dot(rear_dir)
		
		var thrust_color: Color
		if alignment > 0.5:  # Rear
			thrust_color = Color(0.2, 1.0, 0.2, 0.7)  # Green - good
		elif alignment > -0.5:  # Side
			thrust_color = Color(1.0, 1.0, 0.2, 0.7)  # Yellow - okay
		else:  # Front
			thrust_color = Color(1.0, 0.2, 0.2, 0.7)  # Red - bad
		
		draw_line(engine_center_px, thrust_end, thrust_color, 2.0)

func rotate_ship_direction(clockwise: bool = true):
	"""Rotate the ship's forward direction by 60 degrees (natural for hex grids)"""
	var current_dir = blueprint.forward_direction
	
	# 60-degree rotation matrix
	# Clockwise: cos(60°) = 0.5, sin(60°) = sqrt(3)/2 ≈ 0.866
	# Counter-clockwise: cos(-60°) = 0.5, sin(-60°) = -sqrt(3)/2 ≈ -0.866
	var cos_60 = 0.5
	var sin_60 = sqrt(3) / 2.0
	
	if clockwise:
		# Rotate 60 degrees clockwise
		blueprint.forward_direction = Vector2(
			current_dir.x * cos_60 + current_dir.y * sin_60,
			-current_dir.x * sin_60 + current_dir.y * cos_60
		)
	else:
		# Rotate 60 degrees counter-clockwise
		blueprint.forward_direction = Vector2(
			current_dir.x * cos_60 - current_dir.y * sin_60,
			current_dir.x * sin_60 + current_dir.y * cos_60
		)
	
	blueprint.forward_direction = blueprint.forward_direction.normalized()
	queue_redraw()
