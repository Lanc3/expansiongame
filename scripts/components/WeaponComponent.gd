extends Node
class_name WeaponComponent
## Weapon component for combat units

enum WeaponType {LASER, PLASMA, MISSILE}

@export var weapon_type: WeaponType = WeaponType.LASER
@export var damage: float = 10.0
@export var fire_rate: float = 1.0  # shots per second
@export var rangeAim: float = 300.0
@export var projectile_speed: float = 500.0
@export var homing: bool = false  # For missiles

var cooldown_timer: float = 0.0

func _ready():
	# Don't need to preload scene anymore - ProjectilePool handles it
	pass

func _process(delta: float):
	if cooldown_timer > 0:
		cooldown_timer -= delta

func can_fire() -> bool:
	return cooldown_timer <= 0

func get_range() -> float:
	return rangeAim

func fire_at(target: Node2D, from_position: Vector2):
	if not can_fire() or not is_instance_valid(target):
		return
	
	cooldown_timer = 1.0 / fire_rate
	
	# Play weapon sound with spatial audio
	if AudioManager:
		AudioManager.play_weapon_sound(from_position)
	
	# OPTIMIZATION: Get projectile from pool instead of instantiating
	var projectile: Projectile
	if ProjectilePool:
		projectile = ProjectilePool.get_projectile()
		# Pooled projectiles stay as children of ProjectilePool (already in tree)
	else:
		# Fallback if pool not available
		var projectile_scene = preload("res://scenes/effects/Projectile.tscn")
		projectile = projectile_scene.instantiate()
		get_tree().root.add_child(projectile)
	
	projectile.setup(
		weapon_type,
		damage,
		from_position,
		target.global_position,
		projectile_speed,
		target if homing else null,
		get_parent()  # Owner (the unit firing)
	)
