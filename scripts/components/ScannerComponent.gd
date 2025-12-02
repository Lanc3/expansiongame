extends Node2D
class_name ScannerComponent

@export var level: int = 1
@export var range_px: float = 350.0
@export var scan_multiplier: float = 5.0

var target: Node2D = null
var is_selected: bool = false

@onready var beam: Laser2D = null
@onready var range_ring: Line2D = null

func _ready() -> void:
	beam = preload("res://scenes/components/Laser2D.tscn").instantiate() as Laser2D
	add_child(beam)
	beam.is_casting = false
	beam.color = Color(1.0, 1.0, 1.0, 0.95)  # White scanner beam
	beam.growth_time = 0.08
	beam.start_distance = 16.0
	# Thicken beam by +4
	beam.line_width = beam.line_width + 4.0
	# Range ring
	range_ring = Line2D.new()
	range_ring.width = 1.5
	range_ring.default_color = Color(0.2, 0.8, 1.0, 0.6)
	range_ring.visible = false
	add_child(range_ring)
	_draw_range_ring()

func setup_from_defs(def: Dictionary) -> void:
	level = int(def.get("level", 1))
	range_px = float(def.get("range_px", 350.0))
	scan_multiplier = float(def.get("scan_multiplier", 5.0))
	_draw_range_ring()

func set_selected(selected: bool) -> void:
	is_selected = selected
	if range_ring:
		range_ring.visible = selected

func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist <= range_px:
			# Point beam to target using global-relative angle to avoid parent rotation accumulation
			var parent_node := get_parent() as Node2D
			var global_angle = (target.global_position - global_position).angle()
			if parent_node:
				rotation = global_angle - parent_node.global_rotation
			else:
				rotation = global_angle
			# Clamp beam length to target distance (avoid full-length sweep)
			if beam:
				beam.max_length = clampf(dist, 0.0, range_px)
			beam.is_casting = true
			# accelerate scanning using node's scan api
			if target.has_method("start_scan"):
				if not target.is_scanned:
					# ensure a scanning unit is registered (use self)
					if target.scanning_unit == null:
						target.start_scan(self)
					# push scan forward faster by scaling delta
					target.update_scan(delta * scan_multiplier)
				else:
					# Scan complete - stop beam and free this scanner to accept new commands
					clear_target()
		else:
			beam.is_casting = false
	else:
		beam.is_casting = false

func scan(target_asteroid: Node2D) -> void:
	target = target_asteroid

func clear_target() -> void:
	target = null
	if beam:
		beam.is_casting = false

func _draw_range_ring() -> void:
	if range_ring == null:
		return
	var points: PackedVector2Array = []
	var segments := 64
	for i in range(segments + 1):
		var t = float(i) / float(segments) * TAU
		points.append(Vector2(cos(t), sin(t)) * range_px)
	range_ring.points = points


