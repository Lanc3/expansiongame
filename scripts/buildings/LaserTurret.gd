extends BaseTurret
## Laser turret - high damage energy weapon

func _ready():
	super._ready()
	
	# Set laser turret specific properties
	weapon_type = 1
	damage = 20.0
	fire_rate = 1.0
	attack_range = 350.0
	projectile_speed = 800.0
	max_health = 250.0
	current_health = max_health

