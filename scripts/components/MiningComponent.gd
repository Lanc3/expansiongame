extends Node2D
class_name MiningComponent

@export var level: int = 1
@export var range_px: float = 300.0
@export var mining_rate: float = 1.0
@export var cargo_bonus: int = 100

# Owning ship to receive cargo
var owner_ship: CustomShip = null

var target: Node2D = null
var is_selected: bool = false

@onready var beam: Laser2D = null
@onready var range_ring: Line2D = null

var mine_timer: float = 0.0
const MINE_TICK: float = 0.5

func _ready() -> void:
	beam = preload("res://scenes/components/Laser2D.tscn").instantiate() as Laser2D
	add_child(beam)
	beam.is_casting = false
	beam.color = Color(0.2, 1.0, 0.2, 0.95)  # Green mining beam
	beam.growth_time = 0.08
	beam.start_distance = 16.0
	# Thicken beam by +4
	beam.line_width = beam.line_width + 4.0
	# Range ring
	range_ring = Line2D.new()
	range_ring.width = 1.5
	range_ring.default_color = Color(0.3, 1.0, 1.0, 0.6)
	range_ring.visible = false
	add_child(range_ring)
	_draw_range_ring()

func setup_from_defs(def: Dictionary) -> void:
	level = int(def.get("level", 1))
	range_px = float(def.get("range_px", 300.0))
	mining_rate = float(def.get("mining_rate", 1.0))
	cargo_bonus = int(def.get("cargo_bonus", 100))
	_draw_range_ring()

func set_selected(selected: bool) -> void:
	is_selected = selected
	if range_ring:
		range_ring.visible = selected

func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist <= range_px:
			# Orient beam towards target using global-relative angle (stable under parent rotation)
			var parent_node := get_parent() as Node2D
			var global_angle = (target.global_position - global_position).angle()
			if parent_node:
				rotation = global_angle - parent_node.global_rotation
			else:
				rotation = global_angle
			# Clamp beam length to target distance
			if beam:
				beam.max_length = clampf(dist, 0.0, range_px)
			beam.is_casting = true
			mine_timer += delta
			# If asteroid not scanned, attempt to start scanning minimally so miners can begin after
			if target and not target.is_scanned and target.has_method("start_scan"):
				if target.scanning_unit == null:
					target.start_scan(self)
				# slow scan while miners are assigned (not as fast as dedicated scanner)
				target.update_scan(delta * 1.0)
			if mine_timer >= MINE_TICK:
				mine_timer = 0.0
				_mine_tick()
		else:
			beam.is_casting = false
	else:
		beam.is_casting = false

func mine(target_asteroid: Node2D) -> void:
	target = target_asteroid

func clear_target() -> void:
	target = null
	if beam:
		beam.is_casting = false

func _mine_tick() -> void:
	# Use ResourceNode API where available
	if target and is_instance_valid(target):
		if target.has_method("extract_resource"):
			# Do not mine until asteroid is scanned
			if not target.is_scanned:
				return
			# baseline 1.0 scaled by mining_rate and level
			var amount := mining_rate * 1.0
			var extracted = target.extract_resource(amount)
			# Deliver to owner ship cargo
			if owner_ship and extracted is Dictionary and not extracted.is_empty():
				owner_ship.add_cargo_from_extraction(extracted)
				# If cargo now full, trigger return and stop mining
				if owner_ship.max_cargo > 0.0 and owner_ship.carrying_resources >= owner_ship.max_cargo - 0.001:
					if AudioManager:
						AudioManager.play_sound("cargo_full")
					owner_ship.start_returning()
					clear_target()

func _draw_range_ring() -> void:
	if range_ring == null:
		return
	var points: PackedVector2Array = []
	var segments := 64
	for i in range(segments + 1):
		var t = float(i) / float(segments) * TAU
		points.append(Vector2(cos(t), sin(t)) * range_px)
	range_ring.points = points


