extends Node2D
class_name SelectionCircle

## Visual indicator showing a unit is selected

@export var radius: float = 30.0
@export var circle_color: Color = Color(0.0, 1.0, 0.8, 0.8)  # Bright cyan
@export var line_width: float = 2.5
@export var segments: int = 32

var circle_line: Line2D

func _ready():
	circle_line = Line2D.new()
	circle_line.width = line_width
	circle_line.default_color = circle_color
	circle_line.antialiased = true
	add_child(circle_line)
	
	_update_circle()
	
	# Initially hidden until unit is selected
	visible = false


func _update_circle():
	var points = PackedVector2Array()
	
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		var point = Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	circle_line.points = points


func set_radius(new_radius: float):
	radius = new_radius
	if circle_line:
		_update_circle()


func set_color(new_color: Color):
	circle_color = new_color
	if circle_line:
		circle_line.default_color = new_color


func show_selection():
	visible = true


func hide_selection():
	visible = false

