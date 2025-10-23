extends Node2D
class_name WaypointMarker

## Displays a numbered waypoint marker with command type icon

enum CommandType {NONE, MOVE, ATTACK, MINE, RETURN_CARGO, HOLD_POSITION, PATROL, SCAN}

@export var command_type: CommandType = CommandType.MOVE
@export var marker_number: int = 1
@export var marker_size: float = 20.0

var background_circle: Polygon2D
var icon_polygon: Polygon2D
var number_label: Label

# Command type colors
const COMMAND_COLORS = {
	CommandType.MOVE: Color(0.3, 0.5, 1.0, 0.8),          # Blue
	CommandType.ATTACK: Color(1.0, 0.3, 0.3, 0.8),        # Red
	CommandType.MINE: Color(1.0, 0.9, 0.3, 0.8),          # Yellow
	CommandType.RETURN_CARGO: Color(0.3, 1.0, 0.5, 0.8),  # Green
	CommandType.HOLD_POSITION: Color(0.8, 0.8, 0.8, 0.8), # Gray
	CommandType.SCAN: Color(0.5, 0.3, 1.0, 0.8),          # Purple
}


func _ready():
	_create_marker()


func _create_marker():
	# Create background circle
	background_circle = Polygon2D.new()
	var circle_points = _create_circle_points(marker_size, 16)
	background_circle.polygon = circle_points
	background_circle.color = _get_command_color()
	add_child(background_circle)
	
	# Create command icon
	icon_polygon = Polygon2D.new()
	icon_polygon.polygon = _get_command_icon_shape()
	icon_polygon.color = Color(1, 1, 1, 1)  # White icon
	add_child(icon_polygon)
	
	# Create number label
	number_label = Label.new()
	number_label.text = str(marker_number)
	number_label.position = Vector2(-6, marker_size + 2)
	number_label.add_theme_font_size_override("font_size", 14)
	number_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	number_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	number_label.add_theme_constant_override("outline_size", 2)
	add_child(number_label)


func _create_circle_points(radius: float, seg_count: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(seg_count):
		var angle = (float(i) / seg_count) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _get_command_color() -> Color:
	return COMMAND_COLORS.get(command_type, Color(1, 1, 1, 0.8))


func _get_command_icon_shape() -> PackedVector2Array:
	var points = PackedVector2Array()
	var size = marker_size * 0.5
	
	match command_type:
		CommandType.MOVE:
			# Circle outline (small inner circle)
			for i in range(8):
				var angle = (float(i) / 8) * TAU
				points.append(Vector2(cos(angle), sin(angle)) * size * 0.4)
		
		CommandType.ATTACK:
			# X shape (crosshair)
			points = PackedVector2Array([
				Vector2(-size * 0.5, -size * 0.5),
				Vector2(-size * 0.2, -size * 0.2),
				Vector2(0, 0),
				Vector2(-size * 0.2, size * 0.2),
				Vector2(-size * 0.5, size * 0.5),
				Vector2(0, 0),
				Vector2(size * 0.2, size * 0.2),
				Vector2(size * 0.5, size * 0.5),
				Vector2(0, 0),
				Vector2(size * 0.2, -size * 0.2),
				Vector2(size * 0.5, -size * 0.5),
			])
		
		CommandType.MINE:
			# Diamond shape
			points = PackedVector2Array([
				Vector2(0, -size),
				Vector2(size * 0.6, 0),
				Vector2(0, size),
				Vector2(-size * 0.6, 0),
			])
		
		CommandType.RETURN_CARGO:
			# Arrow pointing back (left)
			points = PackedVector2Array([
				Vector2(size * 0.5, -size * 0.5),
				Vector2(-size * 0.5, 0),
				Vector2(size * 0.5, size * 0.5),
				Vector2(size * 0.2, size * 0.3),
				Vector2(-size * 0.2, 0),
				Vector2(size * 0.2, -size * 0.3),
			])
		
		CommandType.SCAN:
			# Radar sweep (triangle)
			points = PackedVector2Array([
				Vector2(0, -size),
				Vector2(size * 0.5, size * 0.3),
				Vector2(-size * 0.5, size * 0.3),
			])
		
		_:
			# Default: small circle
			for i in range(6):
				var angle = (float(i) / 6) * TAU
				points.append(Vector2(cos(angle), sin(angle)) * size * 0.3)
	
	return points


func set_command_type(type: CommandType):
	command_type = type
	if background_circle and icon_polygon:
		background_circle.color = _get_command_color()
		icon_polygon.polygon = _get_command_icon_shape()


func set_marker_number(num: int):
	marker_number = num
	if number_label:
		number_label.text = str(num)

