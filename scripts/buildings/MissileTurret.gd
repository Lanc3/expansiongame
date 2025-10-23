extends BaseTurret
class_name MissileTurret
## Long-range homing missile turret

func _ready():
	# Set missile turret stats
	max_health = 300.0
	attack_range = 450.0
	damage = 40.0
	fire_rate = 0.3
	projectile_speed = 400.0
	weapon_type = 2  # Missile (homing)
	rotation_speed = 1.5  # Slower tracking (heavy weapon)
	
	super._ready()


