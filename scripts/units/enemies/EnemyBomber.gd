extends BaseEnemy
class_name EnemyBomber
## Heavy artillery unit with high HP and explosive damage

func _ready():
	super._ready()
	
	# Bomber stats
	unit_name = "Enemy Bomber"
	max_health = 150.0
	current_health = max_health
	move_speed = 80.0
	
	# Combat stats
	vision_range = 640.0  # Doubled from 320
	patrol_speed = 35.0
	patrol_radius = 250.0  # Shorter patrol radius (slower)

func can_attack() -> bool:
	return true

func can_mine() -> bool:
	return false


