extends Area2D
class_name Projectile
## Projectile with optional homing capability

var damage: float
var speed: float
var direction: Vector2
var lifetime: float = 3.0
var age: float = 0.0
var weapon_type: int
var homing_target: Node2D = null
var owner_unit: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var trail: Line2D = $Trail if has_node("Trail") else null

var trail_points: Array[Vector2] = []
const MAX_TRAIL_POINTS: int = 20

func setup(wep_type: int, dmg: float, start_pos: Vector2, target_pos: Vector2, spd: float, homing: Node2D = null, owner: Node2D = null):
	global_position = start_pos
	damage = dmg
	speed = spd
	direction = (target_pos - start_pos).normalized()
	rotation = direction.angle()
	weapon_type = wep_type
	homing_target = homing
	owner_unit = owner
	
	# Set sprite/color based on weapon type
	if sprite:
		match weapon_type:
			0: # LASER
				sprite.modulate = Color.RED
			1: # PLASMA
				sprite.modulate = Color.CYAN
			2: # MISSILE
				sprite.modulate = Color.ORANGE

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	EntityManager.register_projectile(self)
	
	# Set to pausable so projectiles respect game pause
	# Note: Off-screen processing is handled by visibility settings, not process_mode
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# Setup collision
	collision_layer = 16  # Layer 5 (Projectiles)
	collision_mask = 1 + 2  # Layers 1-2 (Units, Resources)

func _exit_tree():
	EntityManager.unregister_projectile(self)

func _process(delta: float):
	# Homing behavior
	if homing_target and is_instance_valid(homing_target):
		var target_direction = (homing_target.global_position - global_position).normalized()
		direction = direction.lerp(target_direction, 2.0 * delta)  # Smooth turn
		rotation = direction.angle()
	
	# Move
	global_position += direction * speed * delta
	
	# Trail effect
	if trail:
		trail_points.append(global_position)
		if trail_points.size() > MAX_TRAIL_POINTS:
			trail_points.pop_front()
		trail.points = PackedVector2Array(trail_points)
	
	# Lifetime
	age += delta
	if age >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D):
	if body == owner_unit:
		return  # Don't hit self
	
	if body.has_method("take_damage"):
		body.take_damage(damage, owner_unit)
	
	# Create impact effect
	FeedbackManager.spawn_explosion(global_position)
	queue_free()

func _on_area_entered(_area: Area2D):
	# Handle area collisions if needed
	pass
