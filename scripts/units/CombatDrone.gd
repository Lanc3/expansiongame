extends BaseUnit
class_name CombatDrone

@export var attack_range: float = 200.0  # Weapon range
# vision_range set in _ready() for fog of war
@export var auto_attack: bool = true     # Automatically attack enemies in range

var current_target: Node2D = null
var target_scan_timer: float = 0.0
var target_scan_interval: float = 0.5  # Scan for targets every 0.5 seconds

func _ready():
	super._ready()
	unit_name = "Combat Drone"
	max_health = 80.0
	current_health = max_health
	move_speed = 140.0
	vision_range = 800.0  # Combat drones have good vision (doubled from 400)
	
	# OPTIMIZATION: Stagger initial scan to avoid spikes (random offset)
	target_scan_timer = randf() * target_scan_interval

func can_attack() -> bool:
	return true

func can_mine() -> bool:
	return false

func _physics_process(delta: float):
	super._physics_process(delta)
	
	# Auto-target enemies when idle or moving
	if auto_attack and (ai_state == AIState.IDLE or ai_state == AIState.MOVING):
		target_scan_timer += delta
		if target_scan_timer >= target_scan_interval:
			target_scan_timer = 0.0
			auto_target_enemy()

func auto_target_enemy():
	# OPTIMIZATION: Use zone-aware targeting (only check units in current zone)
	var current_zone_id = ZoneManager.get_unit_zone(self)
	var nearest_enemy: Node2D = null
	var vision_range_sq = vision_range * vision_range  # Use squared for faster comparison
	
	# Only search in the same zone - combat drones should not attack across zones
	if not current_zone_id.is_empty() and EntityManager.has_method("get_nearest_unit_in_zone"):
		nearest_enemy = EntityManager.get_nearest_unit_in_zone(global_position, 1, current_zone_id, self)  # team_id 1 = enemy
	# No fallback - combat drones should only attack enemies in their zone
	
	if nearest_enemy and is_instance_valid(nearest_enemy):
		# Check distance using squared values (avoid sqrt)
		var distance_sq = global_position.distance_squared_to(nearest_enemy.global_position)
		
		if distance_sq <= vision_range_sq:
			# Enemy in range, attack it
			current_target = nearest_enemy
			
			# If idle, automatically engage
			if ai_state == AIState.IDLE:
				start_attack(nearest_enemy)
			# If moving, can optionally interrupt to attack (aggressive behavior)
			elif ai_state == AIState.MOVING and command_queue.is_empty():
				start_attack(nearest_enemy)

func process_combat_state(delta: float):
	if not is_instance_valid(target_entity):
		# Target died or disappeared, look for new target
		auto_target_enemy()
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
		
		# Rotate to face target
		var direction_to_target = (target_entity.global_position - global_position).normalized()
		var target_rotation = direction_to_target.angle()
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)
		
		# Fire weapon
		var weapon = get_node_or_null("WeaponComponent")
		if weapon and weapon.has_method("fire_at"):
			weapon.fire_at(target_entity, global_position)
	
	# Check if target left vision range (stop chasing)
	if distance > vision_range * 1.5:  # 50% buffer to prevent flickering
		complete_current_command()

func start_attack(target: Node2D):
	target_entity = target
	ai_state = AIState.COMBAT
	
	# Clear move commands if auto-attacking
	if auto_attack and command_queue.size() == 0:
		# This is an automatic attack, not from command queue
		pass
	else:
		# This is a commanded attack, part of command queue
		pass
