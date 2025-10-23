extends BaseUnit
class_name MiningDrone

@export var mining_rate: float = 10.0  # Resources per second
@export var mining_range: float = 50.0
@export var max_cargo: float = 100.0

var carrying_resources: float = 0.0
var carrying_common: float = 0.0
var carrying_rare: float = 0.0
var carrying_exotic: float = 0.0
var cargo_by_type: Dictionary = {}  # New: track resources by type_id
var mining_timer: float = 0.0
var return_target: Node2D = null
var last_mined_resource: Node2D = null  # Remember what we were mining

# Mining laser visual
var mining_laser: Line2D = null
var laser_texture: Texture2D = null
var laser_offset: float = 0.0
var laser_scroll_speed: float = 100.0

# Cargo indicator UI
var cargo_indicator: Control = null
var cargo_indicator_scene: PackedScene = null

func _ready():
	super._ready()
	unit_name = "Mining Drone"
	max_health = 50.0
	vision_range = 300.0  # Mining drones have limited vision
	current_health = max_health
	move_speed = 120.0
	
	# Setup cargo bar if it exists
	if cargo_bar:
		cargo_bar.visible = true
		cargo_bar.max_value = max_cargo
		cargo_bar.value = 0
		
		# Style cargo bar differently from health bar
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.2, 0.6, 1.0, 0.8)  # Blue for cargo
		cargo_bar.add_theme_stylebox_override("fill", style_box)
	
	# Create mining laser
	create_mining_laser()
	
	# Load and create cargo indicator
	cargo_indicator_scene = preload("res://scenes/ui/CargoIndicator.tscn")
	create_cargo_indicator()

func _process(_delta: float):
	update_cargo_bar()

func _exit_tree():
	if is_instance_valid(cargo_indicator):
		cargo_indicator.queue_free()

func update_cargo_bar():
	# Update floating UI
	if cargo_indicator and cargo_indicator.has_method("update_cargo"):
		cargo_indicator.update_cargo(carrying_resources, max_cargo)
	
	# Keep old cargo_bar logic for compatibility
	if cargo_bar:
		cargo_bar.value = carrying_resources
		
		# Change color based on cargo level
		if carrying_resources >= max_cargo:
			cargo_bar.modulate = Color(1.0, 0.5, 0.0)  # Orange when full
		elif carrying_resources > 0:
			cargo_bar.modulate = Color(0.3, 1.0, 0.3)  # Green when carrying
		else:
			cargo_bar.modulate = Color(0.5, 0.5, 0.5)  # Gray when empty

func can_mine() -> bool:
	return true

func process_gathering_state(delta: float):
	if not is_instance_valid(target_entity):
		complete_current_command()
		return
	
	# Check if resource is depleted
	if target_entity.has_method("is_depleted") and target_entity.is_depleted():
		if carrying_resources > 0:
			start_returning()
		else:
			complete_current_command()
		return
	
	# Move to resource if not in range
	var distance = global_position.distance_to(target_entity.global_position)
	if distance > mining_range:
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
		return
	
	# In range - stop and mine
	velocity = Vector2.ZERO
	
	# Update laser visual
	if target_entity and distance <= mining_range:
		update_mining_laser(target_entity, delta)
	else:
		hide_mining_laser()
	
	# Check if asteroid is scanned
	if not target_entity.is_scanned:
		# Cannot mine unscanned asteroid - wait or idle
		velocity = Vector2.ZERO
		hide_mining_laser()
		return
	
	# Mine resource
	mining_timer += delta
	if mining_timer >= 0.5:  # Mine every 0.5 seconds
		mining_timer = 0.0
		
		if target_entity.has_method("extract_resource"):
			var extracted_by_type = target_entity.extract_resource(mining_rate * 0.5)
			
			if not extracted_by_type.is_empty():
				# Track extracted resources by type_id
				var total_extracted = 0.0
				for type_id in extracted_by_type.keys():
					var amount = extracted_by_type[type_id]
					total_extracted += amount
					
					# Store in cargo dictionary
					if not type_id in cargo_by_type:
						cargo_by_type[type_id] = 0.0
					cargo_by_type[type_id] += amount
				
				carrying_resources += total_extracted
				last_mined_resource = target_entity
				
				# Spawn mining effect
				FeedbackManager.spawn_mining_effect(target_entity.global_position)
				
				# Spawn laser impact effect
				spawn_laser_impact_effect(target_entity.global_position)
				
				# Audio feedback
				AudioManager.play_sound("mining_sound")
			
			# Check if cargo full or resource depleted
			if carrying_resources >= max_cargo:
				# Automatically return cargo
				AudioManager.play_sound("cargo_full")
				start_returning()
			elif target_entity.is_depleted() or extracted_by_type.is_empty():
				# Resource depleted
				if carrying_resources > 0:
					start_returning()
				else:
					complete_current_command()

func process_returning_state(delta: float):
	# Find command ship to deposit
	if return_target == null or not is_instance_valid(return_target):
		return_target = find_deposit_target()
	
	if return_target == null:
		# No deposit target found, idle
		ai_state = AIState.IDLE
		return
	
	# Move to command ship
	var distance = global_position.distance_to(return_target.global_position)
	
	if distance > 80.0:
		target_position = return_target.global_position
		
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
		# In range, deposit resources
		velocity = Vector2.ZERO
		deposit_resources()
		
		# Check if we should resume mining
		if is_instance_valid(last_mined_resource) and not last_mined_resource.is_depleted():
			# Resume mining the same resource
			start_mining(last_mined_resource)
		else:
			# Resource was depleted, find any nearby scanned resource
			var nearest = find_nearest_scanned_resource(800.0)
			if nearest:
				start_mining(nearest)
			else:
				# No resources nearby, complete command
				complete_current_command()

func find_nearest_scanned_resource(max_distance: float) -> Node2D:
	"""Find the nearest scanned resource within max_distance"""
	var nearest: Node2D = null
	var min_dist = max_distance
	
	for resource in EntityManager.resources:
		if not is_instance_valid(resource):
			continue
		
		# Only consider scanned, non-depleted resources
		if resource.is_scanned and not resource.is_depleted():
			var dist = global_position.distance_to(resource.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = resource
	
	return nearest

func find_deposit_target() -> Node2D:
	# Look for command ship or base with deposit capability
	for unit in EntityManager.units:
		if not is_instance_valid(unit) or unit == self:
			continue
		
		if unit.team_id == team_id:
			# Check if it's a command ship or has deposit method
			if "is_command_ship" in unit and unit.is_command_ship:
				return unit
			elif unit.has_method("deposit_resources"):
				return unit
	
	return null

func deposit_resources():
	if return_target and return_target.has_method("deposit_resources"):
		# Deposit using old 3-tier system for compatibility with command ships
		var deposited = return_target.deposit_resources(carrying_common, carrying_rare, carrying_exotic)
		if deposited:
			# Add individual resource types to the NEW 100-resource system
			for type_id in cargo_by_type.keys():
				var amount = cargo_by_type[type_id]
				ResourceManager.add_resource(type_id, int(amount))
				print("MiningDrone: Deposited %d of resource %d (%s)" % [int(amount), type_id, ResourceDatabase.get_resource_name(type_id)])
			
			# Also add to legacy system for backward compatibility
			ResourceManager.add_resources(carrying_common, carrying_rare, carrying_exotic)
			
			# Audio and visual feedback
			AudioManager.play_sound("resource_deposit")
			FeedbackManager.spawn_collection_effect(return_target.global_position, Color.GREEN)
			
			# Clear cargo
			carrying_resources = 0.0
			carrying_common = 0.0
			carrying_rare = 0.0
			carrying_exotic = 0.0
			cargo_by_type.clear()
			return_target = null

func start_returning():
	hide_mining_laser()
	ai_state = AIState.RETURNING
	return_target = find_deposit_target()
	if return_target:
		target_position = return_target.global_position

# Override to automatically return when mining completes with full cargo
func start_mining(resource: Node2D):
	target_entity = resource
	
	# Move to resource first if not in range
	if global_position.distance_to(resource.global_position) > mining_range:
		target_position = resource.global_position
		ai_state = AIState.MOVING
		# Will transition to GATHERING once we arrive
	else:
		ai_state = AIState.GATHERING

## Mining Laser Methods

func create_mining_laser():
	"""Create the mining laser Line2D"""
	mining_laser = Line2D.new()
	mining_laser.width = 3.0
	mining_laser.default_color = Color(0.3, 1.0, 0.3, 0.8)  # Green with transparency
	mining_laser.z_index = 10  # Above asteroids and units
	mining_laser.visible = false
	
	# Load laser texture
	laser_texture = load("res://assets/sprites/Lasers/laserGreen07.png")
	mining_laser.texture = laser_texture
	mining_laser.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	
	add_child(mining_laser)

func update_mining_laser(target: Node2D, delta: float):
	"""Update laser visual connecting drone to asteroid"""
	if not mining_laser:
		return
	
	mining_laser.visible = true
	mining_laser.clear_points()
	
	# Start point at drone (slightly forward)
	var start_point = Vector2.ZERO
	
	# End point at asteroid (in local coordinates)
	var end_point = to_local(target.global_position)
	
	mining_laser.add_point(start_point)
	mining_laser.add_point(end_point)
	
	# Animate laser with pulse effect
	laser_offset += laser_scroll_speed * delta
	var pulse = 1.0 + sin(laser_offset * 0.1) * 0.3
	mining_laser.width = 3.0 * pulse
	mining_laser.default_color.a = 0.6 + sin(laser_offset * 0.05) * 0.2

func hide_mining_laser():
	"""Hide the mining laser"""
	if mining_laser:
		mining_laser.visible = false

func spawn_laser_impact_effect(position: Vector2):
	"""Spawn particle effect at laser impact point"""
	var particles = CPUParticles2D.new()
	particles.global_position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 5
	particles.lifetime = 0.3
	particles.explosiveness = 0.8
	particles.z_index = 10  # Above asteroids
	
	# Small sparks
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 40.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.0
	particles.color = Color(0.3, 1.0, 0.3)  # Green to match laser
	
	get_parent().add_child(particles)
	
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(particles):
		particles.queue_free()

## Cargo Indicator Methods

func create_cargo_indicator():
	"""Create floating cargo UI indicator"""
	if cargo_indicator_scene:
		cargo_indicator = cargo_indicator_scene.instantiate()
		cargo_indicator.target_unit = self
		
		# Add to UI layer (so it's always on top)
		var ui_layer = get_tree().root.find_child("UILayer", true, false)
		if ui_layer:
			ui_layer.add_child(cargo_indicator)
