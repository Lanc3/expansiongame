extends BaseUnit
class_name ScoutDrone

enum ScoutState {IDLE, MOVING, SCANNING}

# Vision range set in _ready() instead of export to avoid conflicts
@export var scan_interval: float = 2.0   # Time between passive scans
@export var scan_range: float = 80.0     # Distance needed to scan asteroid
@export var orbit_radius: float = 120.0  # Radius to orbit around asteroid while scanning (2x original)
@export var orbit_speed: float = 2.0     # Radians per second (about 1 full circle per 3 seconds)

var scout_state: ScoutState = ScoutState.IDLE
var target_asteroid: ResourceNode = null
var scan_timer: float = 0.0
var discovered_resources: Array = []
var discovered_enemies: Array = []
var orbit_angle: float = 0.0  # Current angle in orbit around asteroid

func _ready():
	super._ready()
	unit_name = "Scout Drone"
	max_health = 60.0
	current_health = max_health
	move_speed = 180.0  # Fast movement
	vision_range = 1200.0  # Scouts have extended vision for fog of war (doubled from 600)
	
func can_attack() -> bool:
	return false  # Scouts are unarmed

func can_mine() -> bool:
	return false

func _physics_process(delta: float):
	super._physics_process(delta)
	
	# Periodic passive scanning
	scan_timer += delta
	if scan_timer >= scan_interval:
		scan_timer = 0.0
		passive_scan_area()
	
	# Process scanning state
	if scout_state == ScoutState.SCANNING:
		process_scanning_state(delta)

func passive_scan_area():
	"""Passively discover resources and enemies (doesn't scan composition)"""
	# Get current zone
	var current_zone = ZoneManager.get_unit_zone(self) if ZoneManager else 1
	
	# Scan for resources in current zone only
	var zone_resources = EntityManager.get_resources_in_zone(current_zone) if EntityManager else []
	for resource in zone_resources:
		if is_instance_valid(resource):
			var distance = global_position.distance_to(resource.global_position)
			if distance <= vision_range:
				if resource not in discovered_resources:
					discovered_resources.append(resource)
					on_resource_discovered(resource)
	
	# Scan for enemy units in current zone only
	var enemies = EntityManager.get_units_in_radius(global_position, vision_range, 1)  # team_id 1 = enemy
	for enemy in enemies:
		# Verify enemy is in same zone
		if ZoneManager:
			var enemy_zone = ZoneManager.get_unit_zone(enemy)
			if enemy_zone != current_zone:
				continue
		
		if enemy not in discovered_enemies:
			discovered_enemies.append(enemy)
			on_enemy_discovered(enemy)

func start_scanning(asteroid: ResourceNode):
	"""Begin scanning an asteroid for composition"""
	if not is_instance_valid(asteroid):
		return
	
	# Verify asteroid is in same zone as scout
	if ZoneManager:
		var scout_zone = ZoneManager.get_unit_zone(self)
		var asteroid_zone = ZoneManager.get_unit_zone(asteroid)
		if scout_zone != asteroid_zone:
			print("Scout: Ignoring scan command - asteroid in different zone (Scout: %s, Asteroid: %s)" % [scout_zone, asteroid_zone])
			complete_current_command()  # Skip this command
			return
	
	target_asteroid = asteroid
	target_entity = asteroid  # CRITICAL: Set BaseUnit's target_entity!
	scout_state = ScoutState.SCANNING
	
	# Move into range if needed
	var distance = global_position.distance_to(asteroid.global_position)
	if distance > scan_range:
		print("Scout: Moving to asteroid (distance: %.1f)" % distance)
		# Set move target and initiate movement
		target_position = asteroid.global_position
		ai_state = AIState.MOVING
		# Use NavigationAgent2D for pathfinding
		if navigation_agent:
			navigation_agent.target_position = target_position
	else:
		# Already in range, start scanning and circling
		if asteroid.start_scan(self):
			ai_state = AIState.SCANNING
			# Initialize orbit angle based on current position
			var to_scout = global_position - asteroid.global_position
			orbit_angle = atan2(to_scout.y, to_scout.x)

func process_scanning_state(delta: float):
	"""Process active scanning behavior"""
	if not is_instance_valid(target_asteroid):
		cancel_scan()
		return
	
	# If scan not started yet and we're in range, start it
	if target_asteroid.scanning_unit == null:
		var distance = global_position.distance_to(target_asteroid.global_position)
		if distance <= scan_range:
			if target_asteroid.start_scan(self):
				ai_state = AIState.SCANNING
				# Initialize orbit angle based on current position
				var to_scout = global_position - target_asteroid.global_position
				orbit_angle = atan2(to_scout.y, to_scout.x)
			else:
				complete_scan()
		return  # Wait until next frame to start circling
	
	# Circle around the asteroid while scanning
	if target_asteroid.scanning_unit == self:
		# Update orbit angle
		orbit_angle += orbit_speed * delta
		
		# Calculate tangent velocity for smooth circular motion
		# Tangent is perpendicular to radius: (-sin(angle), cos(angle))
		var tangent_direction = Vector2(-sin(orbit_angle), cos(orbit_angle))
		velocity = tangent_direction * move_speed * 0.5  # Slower speed while orbiting
		
		# Update scan progress
		target_asteroid.update_scan(delta)
		
		# Check if scan complete
		if target_asteroid.is_scanned:
			complete_scan()

func complete_scan():
	"""Scanning complete"""
	# Notify event system for activity tracking
	if EventManager:
		EventManager.on_object_scanned()
	
	target_asteroid = null
	scout_state = ScoutState.IDLE
	orbit_angle = 0.0  # Reset orbit angle
	
	# Complete current command and move to next
	current_command_index += 1
	if current_command_index < command_queue.size():
		process_next_command()
	else:
		ai_state = AIState.IDLE
		velocity = Vector2.ZERO

func cancel_scan():
	"""Cancel current scanning operation"""
	if is_instance_valid(target_asteroid):
		target_asteroid.cancel_scan()
	
	target_asteroid = null
	scout_state = ScoutState.IDLE
	ai_state = AIState.IDLE
	orbit_angle = 0.0  # Reset orbit angle

func on_resource_discovered(resource: Node2D):
	# Could emit signal or show on minimap
	pass

func on_enemy_discovered(enemy: Node2D):
	# Could emit signal or alert player
	pass

# Override command processing to handle SCAN commands
func process_next_command():
	print("ScoutDrone.process_next_command: current_index=", current_command_index, " queue_size=", command_queue.size())
	
	if current_command_index >= command_queue.size():
		ai_state = AIState.IDLE
		velocity = Vector2.ZERO
		return
	
	var cmd = command_queue[current_command_index]
	
	# Check if it's a SCAN command
	if cmd.type == 7:  # SCAN (CommandSystem.CommandType.SCAN)
		if cmd.target_entity and cmd.target_entity is ResourceNode:
			start_scanning(cmd.target_entity)
		return
	
	# Let base class handle other commands
	super.process_next_command()
