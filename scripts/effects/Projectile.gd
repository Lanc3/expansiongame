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
var owner_team_id: int = 0
var owner_zone_id: String = ""  # Zone where projectile was fired

@onready var sprite: Sprite2D = $Sprite2D
@onready var trail: Line2D = $Trail if has_node("Trail") else null

var trail_points: Array[Vector2] = []
const MAX_TRAIL_POINTS: int = 8  # OPTIMIZATION: Reduced from 20 to 8 (60% less memory)

func setup(wep_type: int, dmg: float, start_pos: Vector2, target_pos: Vector2, spd: float, homing: Node2D = null, owner: Node2D = null):
	global_position = start_pos
	damage = dmg
	speed = spd
	direction = (target_pos - start_pos).normalized()
	rotation = direction.angle()
	weapon_type = wep_type
	homing_target = homing
	owner_unit = owner
	
	# Store owner's team_id for friendly fire prevention
	if owner and "team_id" in owner:
		owner_team_id = owner.team_id
	
	# Store zone for visibility filtering
	if ZoneManager:
		if owner and ZoneManager.has_method("get_unit_zone"):
			owner_zone_id = ZoneManager.get_unit_zone(owner)
		else:
			owner_zone_id = ZoneManager.current_zone_id
	
	# OPTIMIZATION: Use pre-loaded textures from ProjectilePool
	if sprite and ProjectilePool:
		var texture = ProjectilePool.get_texture_for_type(weapon_type)
		sprite.texture = texture
		
		# Set color modulation based on weapon type
		match weapon_type:
			0: # LASER (Bullets)
				sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)  # Red
				sprite.scale = Vector2(0.8, 0.8)
			1: # PLASMA
				sprite.modulate = Color(0.3, 0.8, 1.0, 1.0)  # Cyan
				sprite.scale = Vector2(0.9, 0.9)
			2: # MISSILE
				sprite.modulate = Color(1.0, 0.7, 0.2, 1.0)  # Orange
				sprite.scale = Vector2(1.0, 1.0)

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
	# Check if projectile is in current zone
	if ZoneManager and not owner_zone_id.is_empty():
		if owner_zone_id != ZoneManager.current_zone_id:
			visible = false
			return
		else:
			visible = true
	
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
		# Return to pool instead of queue_free for reuse
		if ProjectilePool:
			ProjectilePool.return_projectile(self)
		else:
			queue_free()

func _on_body_entered(body: Node2D):
	if body == owner_unit:
		return  # Don't hit self
	
	# FRIENDLY FIRE CHECK - pass through allies
	if "team_id" in body:
		if body.team_id == owner_team_id:
			return  # Ignore allies completely (no collision, no damage)
	
	# Only damage enemies
	if body.has_method("take_damage"):
		# Pass valid owner_unit reference or null if it's been freed
		var attacker = owner_unit if is_instance_valid(owner_unit) else null
		body.take_damage(damage, attacker)
		
		# Spawn damage number
		if FeedbackManager and FeedbackManager.has_method("spawn_damage_number"):
			var is_player_damage = (owner_team_id == 0)  # Player is team 0
			FeedbackManager.spawn_damage_number(global_position, damage, is_player_damage)
	
	# Create impact effect
	FeedbackManager.spawn_explosion(global_position)
	
	# Return to pool instead of queue_free for reuse
	if ProjectilePool:
		ProjectilePool.return_projectile(self)
	else:
		queue_free()

func _on_area_entered(_area: Area2D):
	# Handle area collisions if needed
	pass

func reset_for_pool():
	"""Reset projectile state when returning to pool"""
	# Clear trail
	if trail_points:
		trail_points.clear()
	if trail:
		trail.clear_points()
	
	# Reset all properties
	age = 0.0
	homing_target = null
	owner_unit = null
	owner_team_id = 0
	owner_zone_id = ""  # Reset zone tracking
	direction = Vector2.ZERO
	global_position = Vector2.ZERO
	rotation = 0.0
