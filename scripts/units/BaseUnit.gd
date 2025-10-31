extends CharacterBody2D
class_name BaseUnit

signal health_changed(new_health: float)
signal died()
signal command_completed()

enum AIState {IDLE, MOVING, GATHERING, RETURNING, COMBAT, FLEEING, HOLD_POSITION, SCANNING}
enum ProcessingState { FULL, REDUCED, PAUSED }

@export var unit_name: String = "Unit"
@export var team_id: int = 0
@export var max_health: float = 100.0
@export var move_speed: float = 150.0
@export var acceleration: float = 500.0
@export var rotation_speed: float = 5.0
@export var avoidance_weight: float = 1.0
@export var separation_distance: float = 50.0

# Fog of war vision
var vision_range: float = 800.0  # Default vision range (doubled from 400), overridden by unit types

var current_health: float
var ai_state: AIState = AIState.IDLE
var is_selected: bool = false

# Performance optimization
var processing_state: ProcessingState = ProcessingState.FULL
var update_timer: float = 0.0
var update_interval: float = 0.0  # 0 = every frame, >0 = reduced frequency
var pathfinding_timer: float = 0.0
var pathfinding_interval: float = 0.5  # Recalculate path every 0.5 seconds
var collision_enabled: bool = true
var distance_check_timer: float = 0.0
const DISTANCE_CHECK_INTERVAL: float = 1.0
const COLLISION_DISABLE_DISTANCE: float = 2000.0

# Command queue
var command_queue: Array = []
var current_command_index: int = 0

# Movement
var target_position: Vector2 = Vector2.ZERO
var target_entity: Node2D = null
var desired_velocity: Vector2 = Vector2.ZERO
var arrival_distance: float = 5.0

# Idle behavior for natural ship movement
var idle_drift_direction: Vector2 = Vector2.ZERO
var idle_drift_timer: float = 0.0
var idle_drift_change_interval: float = 3.0  # Change direction every 3 seconds
var idle_drift_speed: float = 0.0  # Will be set to move_speed * 0.15
var idle_rotation_target: float = 0.0
var idle_orbit_center: Vector2 = Vector2.ZERO
var idle_orbit_radius: float = 80.0
var idle_behavior_initialized: bool = false

# Visual (with null safety)
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var health_bar: ProgressBar = $HealthBar if has_node("HealthBar") else null
@onready var cargo_bar: ProgressBar = $CargoBar if has_node("CargoBar") else null

# Navigation and movement components
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D if has_node("NavigationAgent2D") else null
var flocking_behavior: FlockingBehavior = null

# Visual components (created procedurally)
var selection_circle: SelectionCircle = null
var path_visualizer: PathVisualizer = null
var group_badge: Label = null

# Formation tracking
var formation_target_offset: Vector2 = Vector2.ZERO

func _ready():
	current_health = max_health
	
	# Create visual components
	_create_selection_circle()
	_create_path_visualizer()
	_create_group_badge()
	
	# Setup health bar
	_setup_health_bar()
	
	# Create and configure flocking behavior
	_create_flocking_behavior()
	
	# Configure NavigationAgent2D for RVO avoidance
	_configure_navigation_agent()
	
	# Connect to control group changes
	if ControlGroupManager:
		ControlGroupManager.group_changed.connect(_on_control_group_changed)
	
	# Set to pausable so units respect game pause
	# Note: Off-screen processing is handled by visibility settings, not process_mode
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# Stagger pathfinding updates
	pathfinding_timer = randf() * pathfinding_interval
	
	EntityManager.register_unit(self)
	update_health_bar()

func _process(delta: float):
	# Handle reduced processing state
	if processing_state == ProcessingState.REDUCED:
		update_timer += delta
		if update_timer >= update_interval:
			update_timer = 0.0
			process_reduced_update(delta * 60.0)  # Accumulated delta for 1 FPS
		return
	
	# Periodically check distance for collision optimization
	distance_check_timer += delta
	if distance_check_timer >= DISTANCE_CHECK_INTERVAL:
		distance_check_timer = 0.0
		update_collision_state()

func _physics_process(delta: float):
	# Skip physics if not in full processing
	if processing_state != ProcessingState.FULL:
		return
	
	# Check for automatic state transitions during movement
	check_movement_transitions()
	
	process_current_command(delta)
	
	# Apply flocking behaviors (idle behavior now handled in process_current_command)
	if ai_state == AIState.MOVING:
		apply_flocking_force(delta)
	
	move_and_slide()
	update_visual()

func check_movement_transitions():
	"""Check if we should transition from MOVING to another state based on proximity to target"""
	if ai_state != AIState.MOVING:
		return
	
	if not is_instance_valid(target_entity):
		return
	
	# Check if we have a command with a target entity
	if current_command_index >= command_queue.size():
		return
	
	var cmd = command_queue[current_command_index]
	
	# For mining commands, transition when in range
	if cmd.type == 3 and can_mine():  # MINE command
		var distance = global_position.distance_to(target_entity.global_position)
		# Use larger range for transition (50 units, which is mining_range for MiningDrone)
		if distance <= 60.0:
			ai_state = AIState.GATHERING
			velocity = Vector2.ZERO
			return
	
	# For attack commands, transition when in weapon range
	elif cmd.type == 2 and can_attack():  # ATTACK command
		var distance = global_position.distance_to(target_entity.global_position)
		if distance <= 250.0:  # Typical weapon range
			ai_state = AIState.COMBAT
			velocity = Vector2.ZERO
			return
	
	# For scan commands, let scout handle when in range (ScoutDrone overrides this)
	elif cmd.type == 7:  # SCAN command
		# This is handled in ScoutDrone's process_scanning_state
		# Just keep moving until scout takes over
		pass
	
	# For wormhole travel, check when in range and teleport
	elif cmd.type == 8:  # TRAVEL_WORMHOLE command
		if not is_instance_valid(target_entity):
			return
		
		var distance = global_position.distance_to(target_entity.global_position)
		if distance <= 100.0:  # Within wormhole range
			# Trigger teleport
			if target_entity.has_method("teleport_unit"):
				target_entity.teleport_unit(self)
			# Command is complete (unit will be reparented to new zone)
			return

func add_command(cmd_type: int, target_pos: Vector2, target_ent: Node2D = null, queue: bool = false):
	var cmd = {
		"type": cmd_type,
		"target_position": target_pos,
		"target_entity": target_ent
	}
	
	
	if queue:
		command_queue.append(cmd)
	else:
		command_queue.clear()
		command_queue.append(cmd)
		current_command_index = 0
	
	print("BaseUnit.add_command: Command queue size: ", command_queue.size())
	
	# Update path visualization
	update_path_visualization()
	
	if ai_state == AIState.IDLE or not queue:
		print("BaseUnit.add_command: Calling process_next_command()")
		process_next_command()

func clear_commands():
	command_queue.clear()
	current_command_index = 0
	velocity = Vector2.ZERO
	ai_state = AIState.IDLE
	target_entity = null
	target_position = global_position
	
	# Reset idle behavior
	idle_behavior_initialized = false
	
	# Clear navigation agent path
	if navigation_agent:
		navigation_agent.target_position = global_position
		navigation_agent.set_velocity(Vector2.ZERO)
	
	# Clear path visualization
	update_path_visualization()

func process_next_command():
	if current_command_index >= command_queue.size():
		ai_state = AIState.IDLE
		velocity = Vector2.ZERO
		idle_behavior_initialized = false  # Reset idle behavior for fresh orbit center
		update_path_visualization()
		return
	
	var cmd = command_queue[current_command_index]
	
	# Update path visualization when starting new command
	update_path_visualization()
	
	match cmd.type:
		1:  # MOVE (CommandSystem.CommandType.MOVE)
			start_move_to(cmd.target_position)
		2:  # ATTACK (CommandSystem.CommandType.ATTACK)
			start_attack(cmd.target_entity)
		3:  # MINE (CommandSystem.CommandType.MINE)
			start_mining(cmd.target_entity)
		4:  # RETURN_CARGO (CommandSystem.CommandType.RETURN_CARGO)
			start_returning()
		5:  # HOLD_POSITION (CommandSystem.CommandType.HOLD_POSITION)
			ai_state = AIState.HOLD_POSITION
			velocity = Vector2.ZERO
		7:  # SCAN (CommandSystem.CommandType.SCAN)
			# SCAN command - only scouts can scan, handled in ScoutDrone
			# Base units just ignore this command
			pass
		8:  # TRAVEL_WORMHOLE (CommandSystem.CommandType.TRAVEL_WORMHOLE)
			# Move to wormhole position, will teleport when in range
			target_entity = cmd.target_entity
			target_position = cmd.target_position
			ai_state = AIState.MOVING

func process_current_command(delta: float):
	match ai_state:
		AIState.IDLE:
			process_idle_flying_behavior(delta)
		
		AIState.MOVING:
			process_movement(delta)
		
		AIState.HOLD_POSITION:
			velocity = Vector2.ZERO
		
		AIState.SCANNING:
			# Scanning state - velocity managed by specific unit type (e.g., ScoutDrone)
			pass
		
		AIState.GATHERING:
			process_gathering_state(delta)
		
		AIState.RETURNING:
			process_returning_state(delta)
		
		AIState.COMBAT:
			process_combat_state(delta)

func start_move_to(target: Vector2):
	target_position = target
	ai_state = AIState.MOVING
	target_entity = null  # Clear any target entity
	velocity = Vector2.ZERO  # Reset velocity for new move
	
	# Reset idle behavior
	idle_behavior_initialized = false
	
	# Note: Movement sound is played once per command group in CommandSystem
	
	# Check if unit has formation assignment
	if FormationManager.has_formation(self):
		target_position = FormationManager.get_formation_target(self, target)
	
	# Set navigation target - clear old path first
	if navigation_agent:
		navigation_agent.set_velocity(Vector2.ZERO)
		navigation_agent.target_position = target_position

func process_movement(delta: float):
	# Check distance to target for arrival
	var distance = global_position.distance_to(target_position)
	
	if distance < arrival_distance:
		# Arrived at target
		if is_instance_valid(target_entity):
			if current_command_index < command_queue.size():
				var cmd = command_queue[current_command_index]
				if cmd.type == 3 and can_mine():  # MINE command
					ai_state = AIState.GATHERING
					return
				elif cmd.type == 2 and can_attack():  # ATTACK command
					ai_state = AIState.COMBAT
					return
		
		complete_current_command()
		return
	
	# Optimized pathfinding - only recalculate every 0.5 seconds
	pathfinding_timer += delta
	if pathfinding_timer >= pathfinding_interval:
		pathfinding_timer = 0.0
		update_pathfinding()
	
	# Follow current path
	follow_current_path(delta)

## Apply flocking behavior to moving units for natural group movement
func apply_flocking_force(delta: float):
	if not flocking_behavior:
		return
	
	# Get nearby units for flocking calculations
	var nearby_units = flocking_behavior.get_nearby_units(100.0)
	
	if nearby_units.is_empty():
		return
	
	# Calculate flocking force
	var flocking_force = flocking_behavior.calculate_flocking_force(nearby_units)
	
	# Apply flocking force to desired velocity
	if flocking_force.length() > 0:
		desired_velocity += flocking_force * move_speed * 0.3  # Scale down flocking influence

## Apply separation force to idle units so they maintain personal space
func apply_idle_separation(delta: float):
	if not flocking_behavior:
		return
	
	# Get very nearby units for idle separation
	var nearby_units = flocking_behavior.get_nearby_units(separation_distance * 1.5)
	
	if nearby_units.is_empty():
		velocity = Vector2.ZERO
		return
	
	# Calculate only separation force for idle units
	var separation_force = flocking_behavior.calculate_separation(nearby_units)
	
	if separation_force.length() > 0.1:
		# Idle units slowly push away from each other
		var push_velocity = separation_force * move_speed * 0.5
		velocity = velocity.move_toward(push_velocity, acceleration * delta * 0.5)
	else:
		# No nearby units, stay still
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)

func process_idle_flying_behavior(delta: float):
	"""Natural ship idle behavior - gentle drifting and rotation"""
	# Initialize idle behavior on first idle frame
	if not idle_behavior_initialized:
		idle_drift_speed = move_speed * 0.15  # 15% of normal speed
		idle_orbit_center = global_position
		idle_drift_direction = Vector2.from_angle(randf() * TAU)
		idle_rotation_target = rotation + randf_range(-0.5, 0.5)
		idle_behavior_initialized = true
	
	# Update drift direction periodically
	idle_drift_timer += delta
	if idle_drift_timer >= idle_drift_change_interval:
		idle_drift_timer = 0.0
		# Pick new random direction
		var angle_change = randf_range(-PI/3, PI/3)  # +/- 60 degrees
		idle_drift_direction = idle_drift_direction.rotated(angle_change).normalized()
		# New rotation target
		idle_rotation_target = rotation + randf_range(-0.3, 0.3)
	
	# Check distance from orbit center - keep within radius
	var distance_from_center = global_position.distance_to(idle_orbit_center)
	if distance_from_center > idle_orbit_radius:
		# Drift back toward center
		var to_center = (idle_orbit_center - global_position).normalized()
		idle_drift_direction = idle_drift_direction.lerp(to_center, 0.3)
	
	# Apply gentle drift movement directly
	var drift_velocity = idle_drift_direction * idle_drift_speed
	
	# Set velocity with smooth acceleration
	velocity = velocity.move_toward(drift_velocity, acceleration * delta * 0.5)
	
	# Gentle rotation toward target
	rotation = lerp_angle(rotation, idle_rotation_target, rotation_speed * delta * 0.3)

func start_attack(target: Node2D):
	target_entity = target
	ai_state = AIState.COMBAT

func start_mining(resource: Node2D):
	target_entity = resource
	ai_state = AIState.GATHERING
	# Move to resource first
	if global_position.distance_to(resource.global_position) > 50:
		target_position = resource.global_position
		ai_state = AIState.MOVING

func start_returning():
	ai_state = AIState.RETURNING
	# Find nearest command ship or base in the same zone
	var my_zone_id = ZoneManager.get_unit_zone(self) if ZoneManager else ""
	var command_ship = null
	if not my_zone_id.is_empty():
		command_ship = EntityManager.get_nearest_unit_in_zone(global_position, team_id, my_zone_id, self)
	if command_ship:
		target_position = command_ship.global_position
		ai_state = AIState.MOVING

func process_gathering_state(delta: float):
	# Implemented in subclasses (MiningDrone)
	pass

func process_returning_state(delta: float):
	# Implemented in subclasses (MiningDrone)
	pass

func process_combat_state(delta: float):
	if not is_instance_valid(target_entity):
		complete_current_command()
		return
	
	# Get weapon range
	var weapon = get_node_or_null("WeaponComponent")
	var weapon_range = 150.0
	if weapon and "rangeAim" in weapon:
		weapon_range = weapon.rangeAim
	
	# Check distance to target
	var distance_to_target = global_position.distance_to(target_entity.global_position)
	
	# If out of range, move closer
	if distance_to_target > weapon_range * 0.8:  # Move to 80% of weapon range
		target_position = target_entity.global_position
		
		# Calculate direction and move toward target
		var direction = (target_entity.global_position - global_position).normalized()
		var desired_vel = direction * move_speed
		velocity = velocity.move_toward(desired_vel, acceleration * delta)
	else:
		# In range - slow down and fire
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta * 2.0)
	
	# Fire weapon if in range
	if weapon and weapon.has_method("fire_at") and distance_to_target <= weapon_range:
		weapon.fire_at(target_entity, global_position)

func complete_current_command():
	current_command_index += 1
	command_completed.emit()
	process_next_command()

func can_attack() -> bool:
	return has_node("WeaponComponent")

func can_mine() -> bool:
	return false  # Override in MiningDrone

func take_damage(amount: float, attacker: Node2D = null):
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	update_health_bar()
	
	if current_health <= 0:
		die()
	
	# Flash sprite
	if sprite:
		FeedbackManager.flash_sprite(sprite, Color.RED, 0.2)

func die():
	# Check if enemy - drop loot
	if team_id != 0 and LootDropSystem:  # team_id 0 = player
		LootDropSystem.drop_loot(self)
	
	died.emit()
	EntityManager.unregister_unit(self)
	FeedbackManager.spawn_explosion(global_position)
	queue_free()

func _setup_health_bar():
	"""Initialize health bar appearance and values"""
	if not health_bar:
		return
	
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.show_percentage = false
	
	# Make health bar independent of parent's transform
	health_bar.top_level = true
	health_bar.size = Vector2(40, 6)
	
	update_health_bar()

func set_selected(selected: bool):
	is_selected = selected
	
	# Show/hide selection circle
	if selection_circle:
		if selected:
			selection_circle.show_selection()
		else:
			selection_circle.hide_selection()
	
	# Show/hide path visualizer
	if path_visualizer:
		if selected:
			path_visualizer.show_path()
			update_path_visualization()
		else:
			path_visualizer.hide_path()

func update_health_bar():
	"""Update health bar visual based on current health"""
	if not health_bar:
		return
	
	health_bar.value = current_health
	
	# Update color based on health percentage
	var health_percent = (current_health / max_health) * 100.0
	var fill_style = StyleBoxFlat.new()
	
	if health_percent > 66.0:
		fill_style.bg_color = Color(0.2, 1.0, 0.2)  # Green
	elif health_percent > 33.0:
		fill_style.bg_color = Color(1.0, 0.9, 0.2)  # Yellow
	else:
		fill_style.bg_color = Color(1.0, 0.2, 0.2)  # Red
	
	health_bar.add_theme_stylebox_override("fill", fill_style)
	
	# Show health bar when damaged, fade when full health
	if health_percent >= 100.0:
		health_bar.modulate = Color(1, 1, 1, 0.5)  # Fade to 50% when full
	else:
		health_bar.modulate = Color(1, 1, 1, 1.0)  # Full opacity when damaged

func update_visual():
	# Rotate sprite to face movement direction
	if velocity.length() > 10:
		var target_rotation = velocity.angle()
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * get_physics_process_delta_time())
	
	# Keep health bar above unit (top_level means it needs manual positioning)
	if health_bar and health_bar.top_level:
		# Position health bar above unit in world space (always at top)
		health_bar.global_position = global_position + Vector2(-20, -35)
		health_bar.rotation = 0  # Always horizontal
	
	# Counter-rotate group badge to keep it upright
	if group_badge:
		group_badge.rotation = -rotation


# ============================================================================
# VISUAL COMPONENT MANAGEMENT
# ============================================================================

func _create_selection_circle():
	selection_circle = SelectionCircle.new()
	selection_circle.radius = 35.0  # Slightly larger than typical unit size
	add_child(selection_circle)


func _create_path_visualizer():
	path_visualizer = PathVisualizer.new()
	path_visualizer.set_unit(self)
	add_child(path_visualizer)


func _create_flocking_behavior():
	flocking_behavior = FlockingBehavior.new()
	add_child(flocking_behavior)


func _create_group_badge():
	group_badge = Label.new()
	group_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	group_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	group_badge.position = Vector2(-9, -40)  # Centered above unit
	group_badge.size = Vector2(18, 18)
	group_badge.add_theme_font_size_override("font_size", 12)
	group_badge.add_theme_color_override("font_color", Color.WHITE)
	group_badge.add_theme_color_override("font_outline_color", Color.BLACK)
	group_badge.add_theme_constant_override("outline_size", 2)
	group_badge.z_index = 100  # Always on top
	
	# Create circular background
	var bg = ColorRect.new()
	bg.size = Vector2(18, 18)
	bg.color = Color(0.2, 0.2, 0.2, 0.8)
	bg.z_index = -1
	group_badge.add_child(bg)
	
	group_badge.visible = false  # Hidden by default
	add_child(group_badge)
	
	# Update badge immediately
	update_group_badge()


func update_group_badge():
	if not group_badge or not ControlGroupManager:
		return
	
	var group_num = ControlGroupManager.get_unit_group(self)
	
	if group_num > 0:
		# Unit is in a control group - show badge
		group_badge.text = str(group_num)
		group_badge.visible = true
		
		# Set badge color
		var badge_color = ControlGroupManager.get_badge_color(group_num)
		if group_badge.get_child_count() > 0:
			var bg = group_badge.get_child(0)
			if bg is ColorRect:
				bg.color = Color(badge_color.r, badge_color.g, badge_color.b, 0.9)
	else:
		# Not in any group - hide badge
		group_badge.visible = false


func _on_control_group_changed(group_num: int):
	# Update badge when any group changes
	update_group_badge()


func _configure_navigation_agent():
	if not navigation_agent:
		return
	
	# Wait for navigation map to be ready
	call_deferred("_setup_navigation_agent")

func _setup_navigation_agent():
	if not navigation_agent:
		return
	
	# Configure navigation (RVO avoidance disabled for now - using flocking instead)
	navigation_agent.avoidance_enabled = false
	navigation_agent.radius = 20.0
	navigation_agent.max_speed = move_speed
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = arrival_distance


func update_path_visualization():
	if not path_visualizer:
		return
	
	if not is_selected:
		return
	
	# Get remaining commands (from current index onwards)
	var remaining_commands = []
	for i in range(current_command_index, command_queue.size()):
		remaining_commands.append(command_queue[i])
	
	# Update the path visualizer
	path_visualizer.update_path(remaining_commands, global_position)

## Performance Optimization Methods

func set_processing_state(state: int):
	"""Set unit processing state (0=FULL, 1=REDUCED, 2=PAUSED)"""
	processing_state = state as ProcessingState
	
	match processing_state:
		ProcessingState.FULL:
			update_interval = 0.0
			set_physics_process(true)
			set_process(true)
		
		ProcessingState.REDUCED:
			# Background simulation: 1 FPS
			update_interval = 1.0
			set_physics_process(false)  # Disable physics
			set_process(true)  # Keep process for timers
		
		ProcessingState.PAUSED:
			set_physics_process(false)
			set_process(false)

func process_reduced_update(delta: float):
	"""Simplified update for background zones (called at 1 FPS)"""
	# Only handle basic state management, no complex AI or pathfinding
	if ai_state == AIState.MOVING:
		# Simple linear movement without pathfinding
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)
		
		if distance > arrival_distance:
			global_position += direction * move_speed * delta
		else:
			# Arrived
			complete_current_command()

func update_pathfinding():
	"""Recalculate navigation path (called every 0.5 seconds)"""
	if navigation_agent and not navigation_agent.is_navigation_finished():
		navigation_agent.target_position = target_position

func follow_current_path(delta: float):
	"""Follow cached navigation path without recalculation"""
	# Use NavigationAgent2D if available, otherwise direct movement
	if navigation_agent and not navigation_agent.is_navigation_finished():
		# Get next position from NavigationAgent2D
		var next_position = navigation_agent.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		
		# Calculate desired velocity from navigation
		desired_velocity = direction * move_speed
	else:
		# Direct movement (fallback or when navigation not ready)
		desired_velocity = (target_position - global_position).normalized() * move_speed
	
	# Smooth acceleration toward desired velocity
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)

func update_collision_state():
	"""Conservative collision optimization - disable for very distant units"""
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var distance = global_position.distance_to(camera.global_position)
	var should_enable = distance < COLLISION_DISABLE_DISTANCE
	
	if should_enable != collision_enabled:
		collision_enabled = should_enable
		set_collision_layer_value(1, collision_enabled)
		# Ship-to-ship collisions disabled - ships don't check layer 1 (Units)
		# set_collision_mask_value(1, collision_enabled)
