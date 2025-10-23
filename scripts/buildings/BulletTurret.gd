extends BaseTurret
## Bullet turret - basic projectile weapon

func _ready():
	super._ready()
	
	# Set bullet turret specific properties
	weapon_type = 0
	damage = 12.0
	fire_rate = 2.0
	attack_range = 250.0
	projectile_speed = 600.0
	max_health = 200.0
	current_health = max_health

