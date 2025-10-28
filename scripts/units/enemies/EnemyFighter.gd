extends BaseEnemy
class_name EnemyFighter
## Fast, low HP interceptor with rapid-fire weapons

func _ready():
	super._ready()
	
	# Fighter stats
	unit_name = "Enemy Fighter"
	max_health = 60.0
	current_health = max_health
	move_speed = 180.0
	vision_range = 500.0  # Set vision range for fog of war (doubled from 250)
	
	# Combat stats
	patrol_speed = 70.0

func can_attack() -> bool:
	return true

func can_mine() -> bool:
	return false
