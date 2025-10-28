extends BaseUnit
class_name SupportDrone

## Support drone capable of repairing and buffing other units

@export var repair_range: float = 80.0
@export var repair_rate: float = 10.0  # HP per second
@export var scan_interval: float = 1.0  # Check for damaged allies every second

var repair_target: BaseUnit = null
var scan_timer: float = 0.0

func _ready():
	super._ready()
	unit_name = "Support Drone"
	max_health = 70.0  # Fragile support unit
	current_health = max_health
	move_speed = 160.0  # Fast to reach allies
	vision_range = 700.0  # Support drones have moderate vision (doubled from 350)

func can_attack() -> bool:
	return false

func can_mine() -> bool:
	return false

func can_repair() -> bool:
	return true

func _physics_process(delta: float):
	super._physics_process(delta)
	
	# Auto-repair nearby damaged allies when idle
	if ai_state == AIState.IDLE:
		scan_timer += delta
		if scan_timer >= scan_interval:
			scan_timer = 0.0
			auto_repair_ally()

func auto_repair_ally():
	# Find nearest damaged friendly unit
	var player_units = EntityManager.get_units_by_team(team_id)
	var nearest_damaged: BaseUnit = null
	var nearest_distance: float = repair_range
	
	for unit in player_units:
		if not is_instance_valid(unit) or unit == self:
			continue
		
		if unit.current_health < unit.max_health:
			var distance = global_position.distance_to(unit.global_position)
			if distance < nearest_distance:
				nearest_damaged = unit
				nearest_distance = distance
	
	if nearest_damaged:
		repair_target = nearest_damaged
		# Could start a repair command here
		# For now, just stay idle but track the target

# Repair functionality would be expanded here
# Currently provides the framework for repair mechanics
