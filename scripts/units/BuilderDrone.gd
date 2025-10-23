extends BaseUnit
class_name BuilderDrone

## Builder drone capable of constructing structures

@export var build_range: float = 60.0
@export var build_speed: float = 1.0

var building_target: Node2D = null

func _ready():
	super._ready()
	unit_name = "Builder Drone"
	max_health = 100.0
	current_health = max_health
	move_speed = 120.0  # Slower than scouts
	vision_range = 350.0  # Builder drones have moderate vision

func can_attack() -> bool:
	return false

func can_mine() -> bool:
	return false

func can_build() -> bool:
	return true

# Building functionality would go here when implemented
# For now, this is a basic framework
