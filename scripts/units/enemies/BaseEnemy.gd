extends BaseUnit
class_name BaseEnemy
## Base class for all enemy units with hybrid AI (patrol/aggressive)

enum AIMode { PATROL, AGGRESSIVE }

# AI behavior
@export var ai_mode: AIMode = AIMode.PATROL
@export var patrol_radius: float = 300.0
@export var aggro_duration: float = 30.0  # Stay aggressive for 30 seconds
@export var max_chase_distance: float = 600.0  # Max distance to chase from patrol center
# vision_range inherited from BaseUnit (set in child classes)

var patrol_center: Vector2
var aggro_timer: float = 0.0
var patrol_angle: float = 0.0
var patrol_speed: float = 50.0  # Speed while patrolling
var patrol_planet: Node2D = null  # Planet to orbit during patrol
var patrol_orbital_radius: float = 0.0  # Radius to orbit planet at

# Performance optimization
var ai_update_timer: float = 0.0
var ai_update_interval: float = 0.3  # Update AI every 0.3 seconds (staggered)

func _ready():
	super._ready()
	team_id = 1  # Enemy team
	
	# Apply zone-based scaling BEFORE anything else
	apply_zone_scaling()
	
	# Find nearest planet to patrol around
	find_nearest_planet_for_patrol()
	patrol_angle = randf() * TAU  # Random starting angle
	
	# Stagger AI updates
	ai_update_timer = randf() * ai_update_interval
	
	# Add to enemy group
	add_to_group("enemies")

func find_nearest_planet_for_patrol():
	"""Find nearest planet and set up orbital patrol"""
	var planets = get_tree().get_nodes_in_group("planets")
	var nearest_planet = null
	var nearest_distance = INF
	
	for planet in planets:
		if is_instance_valid(planet):
			var distance = global_position.distance_to(planet.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_planet = planet
	
	if nearest_planet:
		patrol_planet = nearest_planet
		# Set patrol center to planet position
		patrol_center = nearest_planet.global_position
		
		# Get zone size to match asteroid orbital radius
		var zone_id = ""
		if has_meta("zone_id"):
			zone_id = get_meta("zone_id")
		elif ZoneManager:
			zone_id = ZoneManager.current_zone_id
		var zone = ZoneManager.get_zone(zone_id) if ZoneManager else {}
		var zone_size = zone.spawn_area_size if not zone.is_empty() else 3000.0
		
		# Set patrol radius to match asteroid belt (25-40% of zone size)
		patrol_orbital_radius = zone_size * randf_range(0.25, 0.4)
		patrol_radius = patrol_orbital_radius
		
	else:
		# No planet found, use spawn position
		patrol_center = global_position
		patrol_radius = 300.0

func apply_zone_scaling():
	"""Scale enemy stats based on zone difficulty"""
	var zone_id = get_meta("zone_id", "")
	var is_boss = get_meta("is_boss", false)
	
	# Get zone difficulty for scaling
	var difficulty = 1
	if not zone_id.is_empty() and ZoneManager:
		var zone_data = ZoneManager.get_zone(zone_id)
		if not zone_data.is_empty():
			difficulty = zone_data.difficulty
	
	# Health scaling: +30% per difficulty
	# Difficulty 1: 1.0x, Difficulty 5: 2.2x, Difficulty 9: 3.4x
	var health_multiplier = 1.0 + (difficulty - 1) * 0.3
	
	# Boss multiplier: 3-5x stats
	if is_boss:
		health_multiplier *= randf_range(3.0, 5.0)
	
	max_health *= health_multiplier
	current_health = max_health
	
	# Damage scaling: +20% per difficulty (less aggressive than health)
	# Difficulty 1: 1.0x, Difficulty 5: 1.8x, Difficulty 9: 2.6x
	var damage_multiplier = 1.0 + (difficulty - 1) * 0.2
	if is_boss:
		damage_multiplier *= randf_range(3.0, 5.0)
	
	# Apply to weapon component if it exists
	if has_node("WeaponComponent"):
		var weapon = get_node("WeaponComponent")
		if "damage" in weapon:
			weapon.damage *= damage_multiplier
	
	# Speed scaling: +5% per difficulty (subtle)
	var speed_multiplier = 1.0 + (difficulty - 1) * 0.05
	if is_boss:
		speed_multiplier *= 0.9  # Bosses are slightly slower
	
	move_speed *= speed_multiplier

func is_boss() -> bool:
	"""Check if this enemy is a boss variant"""
	return get_meta("is_boss", false)

func _physics_process(delta: float):
	# Skip if in reduced processing
	if processing_state == ProcessingState.REDUCED:
		return
	
	super._physics_process(delta)
	
	# Update aggro timer
	if ai_mode == AIMode.AGGRESSIVE:
		aggro_timer -= delta
		if aggro_timer <= 0:
			return_to_patrol()
	
	# Staggered AI updates (every 0.3 seconds instead of every frame)
	ai_update_timer += delta
	if ai_update_timer >= ai_update_interval:
		ai_update_timer = 0.0
		perform_ai_update()
	
	# Process AI based on mode
	if ai_state == AIState.IDLE:
		if ai_mode == AIMode.PATROL:
			patrol_behavior(delta)
		elif ai_mode == AIMode.AGGRESSIVE:
			aggressive_behavior(delta)

func patrol_behavior(delta: float):
	"""Circle around patrol center, engage enemies in vision"""
	# Check if too far from patrol center
	var distance_from_center = global_position.distance_to(patrol_center)
	
	if distance_from_center > patrol_radius * 1.5:
		# Return to patrol center
		target_position = patrol_center
		ai_state = AIState.MOVING
		return
	
	# Circular patrol movement
	patrol_angle += delta * (patrol_speed / patrol_radius)
	if patrol_angle > TAU:
		patrol_angle -= TAU
	
	# If we have a patrol planet, update patrol center to planet's position
	# (in case planet moves or for dynamic tracking)
	if is_instance_valid(patrol_planet):
		patrol_center = patrol_planet.global_position
	
	var patrol_target = patrol_center + Vector2(
		cos(patrol_angle) * patrol_radius,
		sin(patrol_angle) * patrol_radius
	)
	
	# Move toward patrol point
	var direction = (patrol_target - global_position).normalized()
	velocity = direction * (move_speed * 0.3)  # Slower patrol speed
	
	# Look for player units within vision range
	if can_attack():
		auto_scan_for_targets()

func aggressive_behavior(delta: float):
	"""Actively hunt player units"""
	# Check if too far from patrol center
	var distance_from_center = global_position.distance_to(patrol_center)
	
	if distance_from_center > max_chase_distance:
		# Too far from base, return to patrol
		return_to_patrol()
		return
	
	# Actively search for targets
	if can_attack():
		auto_scan_for_targets()
	
	# If no target, move toward patrol center
	if not is_instance_valid(target_entity):
		if distance_from_center > 50:
			target_position = patrol_center
			ai_state = AIState.MOVING

func auto_scan_for_targets():
	"""Scan for player units to attack"""
	# Get enemy's current zone
	var enemy_zone_id = ZoneManager.get_unit_zone(self) if ZoneManager else ""
	if enemy_zone_id.is_empty():
		return  # Can't find targets if we don't know our zone
	
	# Find nearest player unit (team_id 0) IN THE SAME ZONE
	var detection_range = vision_range  # Use class property (set in child classes)
	if ai_mode == AIMode.AGGRESSIVE:
		detection_range = vision_range * 1.5  # Extended vision when aggressive
	
	var nearest_player = EntityManager.get_nearest_unit_in_zone(global_position, 0, enemy_zone_id, self)
	
	if nearest_player and is_instance_valid(nearest_player):
		var distance = global_position.distance_to(nearest_player.global_position)
		
		if distance <= detection_range:
			# Found target, attack it
			print("%s detected player at distance %.0f (range: %.0f) in zone %s" % [unit_name, distance, detection_range, enemy_zone_id])
			if ai_state == AIState.IDLE or (ai_state == AIState.MOVING and command_queue.is_empty()):
				start_attack(nearest_player)
				# Switch to aggressive mode when engaging
				become_aggressive()

func take_damage(amount: float, attacker: Node2D = null):
	"""Override to trigger aggressive behavior when damaged"""
	super.take_damage(amount, attacker)
	
	# Become aggressive when attacked
	become_aggressive()
	
	# Alert nearby allies
	alert_nearby_allies()

func become_aggressive():
	"""Switch to aggressive AI mode"""
	if ai_mode != AIMode.AGGRESSIVE:
		ai_mode = AIMode.AGGRESSIVE
		aggro_timer = aggro_duration

func return_to_patrol():
	"""Return to patrol AI mode"""
	ai_mode = AIMode.PATROL
	aggro_timer = 0.0
	
	# Clear current target
	target_entity = null
	
	# Recenter on planet if we have one
	if is_instance_valid(patrol_planet):
		patrol_center = patrol_planet.global_position
	
	# Move back to patrol center if far
	var distance_from_center = global_position.distance_to(patrol_center)
	if distance_from_center > patrol_radius:
		target_position = patrol_center
		ai_state = AIState.MOVING
	else:
		ai_state = AIState.IDLE
	

func alert_nearby_allies():
	"""Alert nearby enemy units in the same zone to become aggressive"""
	var alert_radius = 400.0
	var my_zone_id = ZoneManager.get_unit_zone(self) if ZoneManager else ""
	if my_zone_id.is_empty():
		return  # Can't alert if we don't know our zone
	
	var nearby_enemies = EntityManager.get_units_in_radius_zone(global_position, alert_radius, 1, my_zone_id)
	
	for enemy in nearby_enemies:
		if enemy == self or not is_instance_valid(enemy):
			continue
		
		if enemy.has_method("become_aggressive"):
			enemy.become_aggressive()

func perform_ai_update():
	"""Staggered AI update - expensive operations (targeting, decisions)"""
	if ai_mode == AIMode.PATROL:
		# Look for targets while patrolling
		auto_scan_for_targets()
	elif ai_mode == AIMode.AGGRESSIVE:
		# Actively search for targets
		auto_scan_for_targets()

func process_reduced_update(delta: float):
	"""Override for background simulation (1 FPS)"""
	# Just update timers, no movement or AI
	if ai_mode == AIMode.AGGRESSIVE:
		aggro_timer -= delta
		if aggro_timer <= 0:
			ai_mode = AIMode.PATROL
	
	# Call parent for basic movement simulation
	super.process_reduced_update(delta)

func die():
	"""Override to handle enemy death"""
	# Explosion effect will be added later
	queue_free()
