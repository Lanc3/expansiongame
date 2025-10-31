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
	custom_minimum_size = Vector2(GRID_SIZE * CELL_SIZE, GRID_SIZE * CELL_SIZE)
	blueprint = CosmoteerShipBlueprint.new()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_preload_textures()
	queue_redraw()

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
		var rect = Rect2(
			Vector2(cell_pos.x * CELL_SIZE, cell_pos.y * CELL_SIZE),
			Vector2(CELL_SIZE, CELL_SIZE)
		)
		
		# Draw hull texture from cache
		var texture_path = CosmoteerComponentDefs.get_hull_texture(hull_type)
		if texture_path and texture_cache.has(texture_path):
			var texture = texture_cache[texture_path]
			if texture:
				draw_texture_rect(texture, rect, false)
			else:
				# Fallback to color if texture is null
				_draw_hull_fallback(rect, hull_type)
		else:
			# Fallback to color if no texture
			_draw_hull_fallback(rect, hull_type)

func _draw_hull_fallback(rect: Rect2, hull_type: CosmoteerShipBlueprint.HullType):
	"""Draw hull as colored rectangle (fallback)"""
	var color = CosmoteerComponentDefs.get_hull_color(hull_type)
	draw_rect(rect, color, true)
	draw_rect(rect, color.lightened(0.2), false, 1.0)

func draw_components():
	for comp_data in blueprint.components:
		var comp_id = comp_data.get("type", "")
		var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
		var comp_size = comp_data.get("size", Vector2i.ONE)
		
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_id)
		if comp_def.is_empty():
			continue
		
		var rect = Rect2(
			Vector2(comp_pos.x * CELL_SIZE, comp_pos.y * CELL_SIZE),
			Vector2(comp_size.x * CELL_SIZE, comp_size.y * CELL_SIZE)
		)
		
		# Draw component texture from cache
		var sprite_path = comp_def.get("sprite", "")
		if sprite_path and texture_cache.has(sprite_path):
			var texture = texture_cache[sprite_path]
			if texture:
				# Draw texture scaled to fill component size
				draw_texture_rect(texture, rect, false)
				# Draw border
				draw_rect(rect, Color(0.8, 0.8, 1.0, 1.0), false, 2.0)
				
				# Draw level number in corner
				var parsed = CosmoteerComponentDefs.parse_component_id(comp_id)
				var level = parsed.get("level", 1)
				var font = ThemeDB.fallback_font
				var font_size = 12
				var level_text = "L%d" % level
				var text_pos = rect.position + Vector2(4, font_size + 2)
				# Draw outline
				draw_string(font, text_pos + Vector2(1, 1), level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)
				# Draw text
				draw_string(font, text_pos, level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0.898, 1, 1))
			else:
				# Fallback to colored rectangle with name
				_draw_component_fallback(rect, comp_def)
		else:
			# Fallback to colored rectangle with name
			_draw_component_fallback(rect, comp_def)

func _draw_component_fallback(rect: Rect2, comp_def: Dictionary):
	"""Draw component as colored rectangle with text label (fallback)"""
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
			
			# Check if placement is valid and optimal
			if is_valid_component_placement(current_component_type, hovered_cell):
				# Check if placement is optimal (for engines: at rear)
				var is_optimal = is_optimal_placement(current_component_type, hovered_cell)
				if is_optimal:
					color = Color(0.0, 1.0, 0.0, 0.3)  # Green if optimal
				else:
					color = Color(1.0, 1.0, 0.0, 0.3)  # Yellow if valid but suboptimal
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

func is_optimal_placement(component_type: String, pos: Vector2i) -> bool:
	"""Check if component placement is optimal based on type and position"""
	if component_type != "engine":
		return true  # Only engines have placement optimization
	
	if blueprint.get_hull_cell_count() == 0:
		return true  # Can't determine optimal on empty ship
	
	var comp_def = CosmoteerComponentDefs.get_component_data(component_type)
	var comp_size = comp_def.get("size", Vector2i.ONE)
	
	# Calculate where this engine would be relative to center of mass
	var center_of_mass = blueprint.calculate_center_of_mass()
	var engine_center = Vector2(pos) + Vector2(comp_size) * 0.5
	var to_engine = engine_center - center_of_mass
	
	if to_engine.length() < 0.1:
		return true  # At center, consider optimal
	
	# Check alignment with rear direction
	var rear_dir = -blueprint.forward_direction
	to_engine = to_engine.normalized()
	var alignment = to_engine.dot(rear_dir)
	
	# Optimal if aligned with rear (> 60 degrees from perpendicular)
	return alignment > 0.5

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

func draw_ship_direction_arrow():
	"""Draw an arrow showing the ship's forward direction at center of mass"""
	if blueprint.get_hull_cell_count() == 0:
		return
	
	var center_of_mass = blueprint.calculate_center_of_mass()
	var center_px = center_of_mass * CELL_SIZE + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
	
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
	
	var rear_dir = -blueprint.forward_direction  # Opposite of forward
	
	for comp_data in blueprint.components:
		if comp_data.get("type", "") != "engine":
			continue
		
		var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
		var comp_size = comp_data.get("size", Vector2i.ONE)
		
		# Draw thrust vector from engine center
		var engine_center_px = Vector2(comp_pos) * CELL_SIZE + Vector2(comp_size) * CELL_SIZE * 0.5
		var thrust_length = CELL_SIZE * 1.5
		var thrust_end = engine_center_px + rear_dir * thrust_length
		
		# Color based on alignment with rear
		var center_of_mass = blueprint.calculate_center_of_mass()
		var to_engine = (Vector2(comp_pos) + Vector2(comp_size) * 0.5) - center_of_mass
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
	"""Rotate the ship's forward direction by 90 degrees"""
	var current_dir = blueprint.forward_direction
	
	if clockwise:
		# Rotate 90 degrees clockwise: (x, y) -> (y, -x)
		blueprint.forward_direction = Vector2(current_dir.y, -current_dir.x)
	else:
		# Rotate 90 degrees counter-clockwise: (x, y) -> (-y, x)
		blueprint.forward_direction = Vector2(-current_dir.y, current_dir.x)
	
	queue_redraw()

