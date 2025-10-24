extends Node
## Manages visual feedback for paint-queue command mode

var circle_node: Node2D = null
var circle_line: Line2D = null
var highlighted_targets: Dictionary = {}  # target -> {label: Label, number: int}
var label_scene: PackedScene = null

func _ready():
	# Create the circle cursor
	circle_node = Node2D.new()
	circle_node.z_index = 100
	circle_node.visible = false
	add_child(circle_node)
	
	# Create Line2D for the circle
	circle_line = Line2D.new()
	circle_line.width = 3.0
	circle_line.default_color = Color(0.0, 1.0, 0.0, 0.8)  # Green with some transparency
	circle_line.antialiased = true
	circle_node.add_child(circle_line)
	
	_generate_circle_points(150.0)

func _generate_circle_points(radius: float):
	"""Generate points for a circle"""
	if not circle_line:
		return
	
	circle_line.clear_points()
	var num_points = 64
	for i in range(num_points + 1):
		var angle = (i / float(num_points)) * TAU
		var point = Vector2(cos(angle), sin(angle)) * radius
		circle_line.add_point(point)

func show_circle(radius: float, world_position: Vector2):
	"""Show the circle cursor at the given world position"""
	if not circle_node:
		return
	
	circle_node.visible = true
	circle_node.global_position = world_position
	_generate_circle_points(radius)

func update_circle_position(world_position: Vector2):
	"""Update circle position"""
	if circle_node:
		circle_node.global_position = world_position

func update_circle_radius(radius: float):
	"""Update circle radius"""
	_generate_circle_points(radius)

func hide_circle():
	"""Hide the circle cursor"""
	if circle_node:
		circle_node.visible = false

func highlight_target(target: Node2D, queue_number: int):
	"""Highlight a target and show its queue number"""
	if not is_instance_valid(target):
		return
	
	# If already highlighted, just update the number
	if target in highlighted_targets:
		var data = highlighted_targets[target]
		if is_instance_valid(data.label):
			data.label.text = str(queue_number)
			data.number = queue_number
		return
	
	# Create a label to show the queue number
	var label = Label.new()
	label.text = str(queue_number)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0))  # Yellow
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", 2)
	label.z_index = 99
	label.position = Vector2(-10, -30)  # Offset above the target
	
	target.add_child(label)
	
	# Store reference
	highlighted_targets[target] = {
		"label": label,
		"number": queue_number
	}
	
	# Add a modulation tint to the target
	if target.has_method("set_modulate"):
		var original_modulate = target.modulate
		target.modulate = Color(0.5, 1.0, 0.5, 1.0)  # Green tint
		# Store original for restoration (optional enhancement)

func clear_highlights():
	"""Clear all target highlights"""
	for target in highlighted_targets.keys():
		if is_instance_valid(target):
			var data = highlighted_targets[target]
			if is_instance_valid(data.label):
				data.label.queue_free()
			# Restore original modulation
			if target.has_method("set_modulate"):
				target.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	highlighted_targets.clear()

func is_target_highlighted(target: Node2D) -> bool:
	"""Check if a target is already highlighted"""
	return target in highlighted_targets

func get_highlight_count() -> int:
	"""Get number of highlighted targets"""
	return highlighted_targets.size()

