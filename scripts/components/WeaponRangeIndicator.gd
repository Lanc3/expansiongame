extends Node2D
class_name WeaponRangeIndicator
## Visual range indicator for ship weapons

enum WeaponType { LASER, MISSILE, MIXED }

@export var weapon_type: WeaponType = WeaponType.LASER
@export var range_radius: float = 250.0
@export var show_on_selection: bool = true

var range_line: Line2D = null
var is_visible_override: bool = false

func _ready():
	_create_range_circle()
	visible = false

func _create_range_circle():
	"""Create the visual range circle"""
	range_line = Line2D.new()
	range_line.name = "RangeCircle"
	range_line.width = 2.0
	range_line.antialiased = true
	
	# Color based on weapon type
	match weapon_type:
		WeaponType.LASER:
			range_line.default_color = Color(1.0, 0.3, 0.3, 0.4)  # Red
		WeaponType.MISSILE:
			range_line.default_color = Color(1.0, 0.9, 0.3, 0.4)  # Yellow
		WeaponType.MIXED:
			range_line.default_color = Color(1.0, 0.6, 0.3, 0.4)  # Orange
	
	# Generate circle points
	var segments = 48
	for i in range(segments + 1):
		var angle = (i * TAU) / segments
		var point = Vector2(cos(angle), sin(angle)) * range_radius
		range_line.add_point(point)
	
	add_child(range_line)

func set_range(new_range: float):
	"""Update the range radius"""
	range_radius = new_range
	if range_line:
		range_line.clear_points()
		var segments = 48
		for i in range(segments + 1):
			var angle = (i * TAU) / segments
			var point = Vector2(cos(angle), sin(angle)) * range_radius
			range_line.add_point(point)

func show_range():
	"""Show the range indicator"""
	visible = true
	is_visible_override = true

func hide_range():
	"""Hide the range indicator"""
	visible = false
	is_visible_override = false

func set_weapon_type(type: WeaponType):
	"""Update weapon type and color"""
	weapon_type = type
	if range_line:
		match weapon_type:
			WeaponType.LASER:
				range_line.default_color = Color(1.0, 0.3, 0.3, 0.4)
			WeaponType.MISSILE:
				range_line.default_color = Color(1.0, 0.9, 0.3, 0.4)
			WeaponType.MIXED:
				range_line.default_color = Color(1.0, 0.6, 0.3, 0.4)


