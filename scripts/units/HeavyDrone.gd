extends BaseUnit
class_name HeavyDrone

## Heavy armored combat drone - high health, slow, strong attacks

@export var attack_range: float = 180.0
# vision_range set in _ready() for fog of war
@export var armor_bonus: float = 0.5  # Takes 50% less damage

var current_target: Node2D = null

func _ready():
	super._ready()
	unit_name = "Heavy Drone"
	max_health = 200.0  # Double the health of combat drones
	current_health = max_health
	move_speed = 100.0  # Slower than other drones
	vision_range = 700.0  # Heavy drones have decent vision (doubled from 350)
	
func can_attack() -> bool:
	return true

func can_mine() -> bool:
	return false

func take_damage(amount: float, attacker: Node2D = null):
	# Apply armor bonus - takes reduced damage
	var reduced_damage = amount * (1.0 - armor_bonus)
	super.take_damage(reduced_damage, attacker)

func process_combat_state(delta: float):
	if not is_instance_valid(target_entity):
		complete_current_command()
		return
	
	var distance = global_position.distance_to(target_entity.global_position)
	
	# Move into attack range if too far
	if distance > attack_range:
		target_position = target_entity.global_position
		
		# Use NavigationAgent2D for pathfinding
		if navigation_agent:
			navigation_agent.target_position = target_position
			if not navigation_agent.is_navigation_finished():
				var next_position = navigation_agent.get_next_path_position()
				var direction = (next_position - global_position).normalized()
				desired_velocity = direction * move_speed
		else:
			# Fallback to direct movement
			desired_velocity = (target_position - global_position).normalized() * move_speed
		
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	else:
		# In range, stop and attack
		velocity = Vector2.ZERO
		
		# Fire weapon
		var weapon = get_node_or_null("WeaponComponent")
		if weapon and weapon.has_method("fire_at"):
			weapon.fire_at(target_entity, global_position)
