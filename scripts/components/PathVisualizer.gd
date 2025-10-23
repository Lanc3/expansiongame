extends Node2D
class_name PathVisualizer

## Visualizes a unit's command queue path with directional arrows

enum CommandType {NONE, MOVE, ATTACK, MINE, RETURN_CARGO, HOLD_POSITION, PATROL, SCAN}

@export var arrow_spacing: float = 50.0  # Distance between arrow chevrons
@export var arrow_size: float = 8.0
@export var line_width: float = 2.0

var path_lines: Array[Line2D] = []
var arrow_lines: Array[Line2D] = []
var waypoint_markers: Array[WaypointMarker] = []
var unit_ref: Node2D = null

# Command type colors
const COMMAND_COLORS = {
	CommandType.MOVE: Color(0.3, 0.5, 1.0, 0.7),          # Blue
	CommandType.ATTACK: Color(1.0, 0.3, 0.3, 0.7),        # Red
	CommandType.MINE: Color(1.0, 0.9, 0.3, 0.7),          # Yellow
	CommandType.RETURN_CARGO: Color(0.3, 1.0, 0.5, 0.7),  # Green
	CommandType.HOLD_POSITION: Color(0.8, 0.8, 0.8, 0.7), # Gray
	CommandType.SCAN: Color(0.5, 0.3, 1.0, 0.7),          # Purple
}


func _ready():
	# Make this node top-level so it doesn't inherit parent's rotation/position
	set_as_top_level(true)
	
	# Initially hidden until unit is selected
	visible = false


func set_unit(unit: Node2D):
	unit_ref = unit


func update_path(command_queue: Array, unit_position: Vector2):
	# Clear existing visualization
	_clear_visualization()
	
	if command_queue.is_empty():
		return
	
	var current_pos = unit_position
	
	# Draw path segments for each command
	for i in range(command_queue.size()):
		var cmd = command_queue[i]
		var cmd_type = cmd.type
		
		# Determine target position - use entity position if available
		var target_pos = cmd.target_position
		if cmd.has("target_entity") and is_instance_valid(cmd.target_entity):
			target_pos = cmd.target_entity.global_position
		
		# Get color for this command type
		var color = COMMAND_COLORS.get(cmd_type, Color(1, 1, 1, 0.7))
		
		# Draw main path line
		var path_line = Line2D.new()
		path_line.width = line_width
		path_line.default_color = color
		path_line.antialiased = true
		path_line.points = PackedVector2Array([current_pos, target_pos])
		add_child(path_line)
		path_lines.append(path_line)
		
		# Draw directional arrows along the path
		_draw_arrows_on_segment(current_pos, target_pos, color)
		
		# Create waypoint marker at target position
		var marker = WaypointMarker.new()
		marker.command_type = cmd_type
		marker.marker_number = i + 1
		marker.position = target_pos
		add_child(marker)
		waypoint_markers.append(marker)
		
		# Update current position for next segment
		current_pos = target_pos


func _draw_arrows_on_segment(start_pos: Vector2, end_pos: Vector2, color: Color):
	var direction = (end_pos - start_pos).normalized()
	var distance = start_pos.distance_to(end_pos)
	var num_arrows = max(1, int(distance / arrow_spacing))
	
	for i in range(num_arrows):
		var t = (float(i + 1) / (num_arrows + 1))
		var arrow_pos = start_pos.lerp(end_pos, t)
		
		_draw_chevron(arrow_pos, direction, color)


func _draw_chevron(position: Vector2, direction: Vector2, color: Color):
	# Create chevron (arrow) pointing in direction
	var perpendicular = Vector2(-direction.y, direction.x)
	
	# Chevron vertices (V shape pointing forward)
	var left_point = position - direction * arrow_size + perpendicular * arrow_size * 0.5
	var tip_point = position + direction * arrow_size * 0.5
	var right_point = position - direction * arrow_size - perpendicular * arrow_size * 0.5
	
	# Draw left arm of chevron
	var left_line = Line2D.new()
	left_line.width = line_width
	left_line.default_color = color
	left_line.antialiased = true
	left_line.points = PackedVector2Array([left_point, tip_point])
	add_child(left_line)
	arrow_lines.append(left_line)
	
	# Draw right arm of chevron
	var right_line = Line2D.new()
	right_line.width = line_width
	right_line.default_color = color
	right_line.antialiased = true
	right_line.points = PackedVector2Array([tip_point, right_point])
	add_child(right_line)
	arrow_lines.append(right_line)


func _clear_visualization():
	# Remove all path lines
	for line in path_lines:
		if is_instance_valid(line):
			line.queue_free()
	path_lines.clear()
	
	# Remove all arrow lines
	for arrow in arrow_lines:
		if is_instance_valid(arrow):
			arrow.queue_free()
	arrow_lines.clear()
	
	# Remove all waypoint markers
	for marker in waypoint_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	waypoint_markers.clear()


func show_path():
	visible = true


func hide_path():
	visible = false


func _exit_tree():
	_clear_visualization()

