extends BaseEnemy
class_name EnemyCruiser
## Balanced combat unit with medium HP and damage

func _ready():
	super._ready()
	
	# Cruiser stats
	unit_name = "Enemy Cruiser"
	max_health = 100.0
	current_health = max_health
	move_speed = 120.0
	
	# Combat stats
	vision_range = 280.0
	patrol_speed = 50.0

func can_attack() -> bool:
	return true

func can_mine() -> bool:
	return false


