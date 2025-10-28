extends StaticBody2D
class_name BaseTurret
## Base class for enemy turret buildings with auto-targeting

signal target_acquired(target: Node2D)
signal target_lost()
signal turret_destroyed()

# Turret properties
@export var max_health: float = 200.0
@export var attack_range: float = 250.0
@export var rotation_speed: float = 2.0  # Radians per second
@export var damage: float = 12.0
@export var fire_rate: float = 2.0  # Shots per second
@export var projectile_speed: float = 600.0
@export var weapon_type: int = 0  # 0=Bullet, 1=Laser, 2=Missile
@export var zone_id: String = ""
@export var team_id: int = 1  # Enemy team

var current_health: float
var current_target: Node2D = null
var fire_cooldown: float = 0.0
var target_scan_timer: float = 0.0
var target_scan_interval: float = 0.3  # Scan every 0.3 seconds

# Performance optimization
var processing_active: bool = true
var reduced_scan_interval: float = 5.0  # Scan every 5 seconds in background

# Visual components
@onready var turret_base: Sprite2D = $TurretBase if has_node("TurretBase") else null
@onready var turret_gun: Sprite2D = $TurretGun if has_node("TurretGun") else null
@onready var health_bar: ProgressBar = $HealthBar if has_node("HealthBar") else null
@onready var laser_sight: Line2D = $LaserSight if has_node("LaserSight") else null
@onready var muzzle_flash: Sprite2D = $TurretGun/MuzzleFlash if has_node("TurretGun/MuzzleFlash") else null
@onready var weapon_component: Node = $WeaponComponent if has_node("WeaponComponent") else null

func _ready():
	current_health = max_health
	
	# Add to groups
	add_to_group("enemies")
	add_to_group("enemy_buildings")
	add_to_group("turrets")
	
	# Setup collision
	collision_layer = 2  # Buildings layer
	collision_mask = 0
	
	# Initialize visuals
	update_health_bar()
	
	if laser_sight:
		laser_sight.visible = false
	
	if muzzle_flash:
		muzzle_flash.visible = false
	


func set_processing_active(active: bool):
	"""Set processing state for optimization"""
	processing_active = active
	if not active:
		target_scan_interval = reduced_scan_interval
	else:
		target_scan_interval = 0.3

func _process(delta: float):
	# Minimal processing in inactive zones
	if not processing_active:
		fire_cooldown = max(0, fire_cooldown - delta)
		return
	
	# Update fire cooldown
	if fire_cooldown > 0:
		fire_cooldown -= delta
	
	# Scan for targets periodically
	target_scan_timer += delta
	if target_scan_timer >= target_scan_interval:
		target_scan_timer = 0.0
		scan_for_targets()
	
	# Track and attack current target
	if is_instance_valid(current_target):
		track_target(delta)
		
		# Check if target still in range
		var distance = global_position.distance_to(current_target.global_position)
		if distance > attack_range:
			lose_target()
		elif fire_cooldown <= 0:
			fire_at_target()
	else:
		# No target, return gun to neutral position
		if turret_gun:
			var neutral_rotation = 0.0
			turret_gun.rotation = lerp_angle(turret_gun.rotation, neutral_rotation, rotation_speed * delta * 0.5)

func scan_for_targets():
	"""Scan for player units within attack range"""
	# OPTIMIZATION: Use zone-aware targeting (only check units in current zone)
	var current_zone_id = ZoneManager.get_unit_zone(self)
	var nearest_player: Node2D = null
	var attack_range_sq = attack_range * attack_range  # Use squared for faster comparison
	
	# Only search in the same zone - turrets should not attack across zones
	if not current_zone_id.is_empty() and EntityManager.has_method("get_nearest_unit_in_zone"):
		nearest_player = EntityManager.get_nearest_unit_in_zone(global_position, 0, current_zone_id, self)  # team_id 0 = player
	# No fallback - turrets should only attack units in their zone
	
	if nearest_player and is_instance_valid(nearest_player):
		# Check distance using squared values (avoid sqrt)
		var distance_sq = global_position.distance_squared_to(nearest_player.global_position)
		
		if distance_sq <= attack_range_sq:
			if current_target != nearest_player:
				acquire_target(nearest_player)
		elif current_target == nearest_player:
			lose_target()
	elif is_instance_valid(current_target):
		# Current target no longer exists
		lose_target()

func acquire_target(target: Node2D):
	"""Lock onto a new target"""
	current_target = target
	target_acquired.emit(target)
	
	if laser_sight:
		laser_sight.visible = true

func lose_target():
	"""Lose current target"""
	current_target = null
	target_lost.emit()
	
	if laser_sight:
		laser_sight.visible = false

func track_target(delta: float):
	"""Rotate turret gun to face target"""
	if not turret_gun or not is_instance_valid(current_target):
		return
	
	# Calculate direction to target
	var direction = (current_target.global_position - global_position).normalized()
	var target_rotation = direction.angle()
	
	# Smoothly rotate gun
	turret_gun.rotation = lerp_angle(turret_gun.rotation, target_rotation, rotation_speed * delta)
	
	# Update laser sight
	if laser_sight:
		var distance = global_position.distance_to(current_target.global_position)
		laser_sight.clear_points()
		laser_sight.add_point(Vector2.ZERO)
		laser_sight.add_point(direction * distance)

func fire_at_target():
	"""Fire weapon at current target"""
	if not is_instance_valid(current_target):
		return
	
	# Use weapon component if available
	if weapon_component and weapon_component.has_method("fire_at"):
		weapon_component.fire_at(current_target, global_position)
	else:
		# Fallback: create projectile manually
		create_projectile()
	
	# Set cooldown
	fire_cooldown = 1.0 / fire_rate
	
	# Muzzle flash
	show_muzzle_flash()

func create_projectile():
	"""Create and fire a projectile (fallback if no WeaponComponent)"""
	# OPTIMIZATION: Use projectile pool
	var projectile: Projectile
	if ProjectilePool:
		projectile = ProjectilePool.get_projectile()
	else:
		var projectile_scene = preload("res://scenes/effects/Projectile.tscn")
		projectile = projectile_scene.instantiate()
		get_tree().root.add_child(projectile)
	
	var muzzle_pos = global_position
	if turret_gun:
		muzzle_pos = turret_gun.global_position + Vector2(cos(turret_gun.global_rotation), sin(turret_gun.global_rotation)) * 20
	
	projectile.setup(
		weapon_type,
		damage,
		muzzle_pos,
		current_target.global_position,
		projectile_speed,
		current_target if weapon_type == 2 else null,  # Homing for missiles
		self
	)

func show_muzzle_flash():
	"""Show muzzle flash effect"""
	if muzzle_flash:
		muzzle_flash.visible = true
		muzzle_flash.modulate.a = 1.0
		
		# Fade out muzzle flash
		var tween = create_tween()
		tween.tween_property(muzzle_flash, "modulate:a", 0.0, 0.1)
		tween.tween_callback(func(): if is_instance_valid(muzzle_flash): muzzle_flash.visible = false)

func take_damage(amount: float, attacker: Node2D = null):
	"""Handle damage to turret"""
	current_health -= amount
	update_health_bar()
	
	# Visual feedback
	if turret_base:
		# Flash red
		turret_base.modulate = Color(1.5, 0.5, 0.5, 1)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self):
			turret_base.modulate = Color(1, 1, 1, 1)
	
	if current_health <= 0:
		die()

func die():
	"""Turret destroyed"""
	
	
	# Explosion effect (will be added later)
	turret_destroyed.emit()
	
	queue_free()

func update_health_bar():
	"""Update health bar visual"""
	if health_bar:
		health_bar.value = (current_health / max_health) * 100.0
		health_bar.visible = current_health < max_health

