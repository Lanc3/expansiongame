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
		var zone_id = 1
		if has_meta("zone_id"):
			zone_id = get_meta("zone_id")
		var zone = ZoneManager.get_zone(zone_id) if ZoneManager else {}
		var zone_size = zone.spawn_area_size if not zone.is_empty() else 3000.0
		
		# Set patrol radius to match asteroid belt (25-40% of zone size)
		patrol_orbital_radius = zone_size * randf_range(0.25, 0.4)
		patrol_radius = patrol_orbital_radius
		
		print("%s: Patrolling around planet at radius %.0f" % [unit_name, patrol_radius])
	else:
		# No planet found, use spawn position
		patrol_center = global_position
		patrol_radius = 300.0

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
	# Find nearest player unit (team_id 0)
	var detection_range = vision_range  # Use class property (set in child classes)
	if ai_mode == AIMode.AGGRESSIVE:
		detection_range = vision_range * 1.5  # Extended vision when aggressive
	
	var nearest_player = EntityManager.get_nearest_unit(global_position, 0, self)
	
	if nearest_player and is_instance_valid(nearest_player):
		var distance = global_position.distance_to(nearest_player.global_position)
		
		if distance <= detection_range:
			# Found target, attack it
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
		print("%s became AGGRESSIVE" % unit_name)

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
	
	print("%s returned to PATROL" % unit_name)

func alert_nearby_allies():
	"""Alert nearby enemy units to become aggressive"""
	var alert_radius = 400.0
	var nearby_enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in nearby_enemies:
		if enemy == self or not is_instance_valid(enemy):
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= alert_radius:
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
	print("%s destroyed!" % unit_name)
	# Explosion effect will be added later
	queue_free()
