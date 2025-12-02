extends BaseUnit
class_name MiningDrone

@export var mining_rate: float = 10.0  # Resources per second
@export var mining_range: float = 250.0  # Increased further for longer range
@export var mining_start_range: float = 400.0  # Distance at which ship stops moving and starts mining
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
var laser_2d: Laser2D = null
var laser_2d_scene: PackedScene = preload("res://scenes/components/Laser2D.tscn")

# Cargo indicator UI
var cargo_indicator: Control = null
var cargo_indicator_scene: PackedScene = null

func _ready():
	super._ready()
	unit_name = "Mining Drone"
	max_health = 50.0
	vision_range = 600.0  # Mining drones have limited vision (doubled from 300)
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
	
	# Connect to loot system for auto-collection
	if LootDropSystem:
		LootDropSystem.loot_dropped.connect(_on_loot_dropped)

func _process(_delta: float):
	update_cargo_bar()

func _exit_tree():
	if is_instance_valid(cargo_indicator):
		cargo_indicator.queue_free()
	# Clean up mining beam when drone is destroyed
	hide_mining_laser()

func clear_commands():
	"""Override to ensure mining laser is stopped when commands are cleared"""
	hide_mining_laser()
	super.clear_commands()

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
	
	# Move to resource if not in mining start range
	var distance = global_position.distance_to(target_entity.global_position)
	if distance > mining_start_range:
		hide_mining_laser()  # Hide laser when moving to asteroid
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
	
	# Check if asteroid is scanned
	if not target_entity.is_scanned:
		# Cannot mine unscanned asteroid - wait or idle
		velocity = Vector2.ZERO
		hide_mining_laser()
		return
	
	# Update laser visual - only when actively mining (in mining start range, scanned, not moving)
	if target_entity and distance <= mining_start_range and target_entity.is_scanned and velocity.length() < 5.0:
		update_mining_laser(target_entity, delta)
	else:
		hide_mining_laser()
	
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
				
				# Notify event system for activity tracking
				if EventManager:
					EventManager.on_asteroid_mined()
				
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
	
	# Get current zone
	var current_zone = ZoneManager.get_unit_zone(self) if ZoneManager else 1
	
	# Only search resources in current zone
	var zone_resources = EntityManager.get_resources_in_zone(current_zone) if EntityManager else []
	for resource in zone_resources:
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
	# Look for command ship or base with deposit capability in same zone
	var current_zone = ZoneManager.get_unit_zone(self) if ZoneManager else 1
	var zone_units = EntityManager.get_units_in_zone(current_zone) if EntityManager else []
	
	for unit in zone_units:
		if not is_instance_valid(unit) or unit == self:
			continue
		
		if unit.team_id == team_id:
			# Check if it's a command ship or has deposit method
			if "is_command_ship" in unit and unit.is_command_ship:
				return unit
			elif unit.has_method("deposit_resources"):
				return unit
	
	var zone_buildings = []
	if EntityManager:
		zone_buildings = EntityManager.get_buildings_in_zone(current_zone)

	for building in zone_buildings:
		if not is_instance_valid(building):
			continue
		if building.has_method("deposit_resources"):
			return building

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
	
	# Move to resource first if not in mining start range
	if global_position.distance_to(resource.global_position) > mining_start_range:
		target_position = resource.global_position
		ai_state = AIState.MOVING
		# Will transition to GATHERING once we arrive
	else:
		ai_state = AIState.GATHERING

func start_move_to(target: Vector2):
	"""Override to ensure mining laser stops when moving"""
	hide_mining_laser()
	super.start_move_to(target)

func check_movement_transitions():
	"""Override to use mining_start_range for mining transitions"""
	# Check if we should transition from MOVING to GATHERING for mining
	if ai_state != AIState.MOVING:
		return
	
	if not is_instance_valid(target_entity):
		return
	
	if current_command_index >= command_queue.size():
		return
	
	var cmd = command_queue[current_command_index]
	
	# For mining commands, transition when in mining_start_range
	if cmd.type == 3 and can_mine():  # MINE command
		var distance = global_position.distance_to(target_entity.global_position)
		if distance <= mining_start_range:
			ai_state = AIState.GATHERING
			velocity = Vector2.ZERO
			return
	
	# Call parent for other transitions
	super.check_movement_transitions()

## Mining Laser Methods

func create_mining_laser():
	"""Create and configure Laser2D component"""
	if laser_2d_scene:
		laser_2d = laser_2d_scene.instantiate()
		add_child(laser_2d)
		
		# Configure laser for mining context
		laser_2d.max_length = mining_start_range * 1.5  # Long enough to reach asteroids at mining start range
		laser_2d.start_distance = 25.0  # Small offset from drone center
		laser_2d.color = Color(0.3, 1.0, 0.3, 0.8)  # Mining green
		laser_2d.cast_speed = 7000.0  # Fast extension
		laser_2d.growth_time = 0.1  # Quick appearance
		
		# Configure collision layers - hit asteroids (layer 3, value 4) but not ships
		laser_2d.collision_mask = 4  # Layer 3 = Resources/Asteroids (collision_layer = 4)
		laser_2d.is_casting = false  # Start inactive

func update_mining_laser(target: Node2D, delta: float):
	"""Update laser visual connecting drone to asteroid"""
	if not target or not is_instance_valid(target):
		hide_mining_laser()
		return
	
	# Ensure laser is created
	if not laser_2d:
		create_mining_laser()
	
	if not laser_2d or not is_instance_valid(laser_2d):
		return
	
	# Point laser at asteroid relative to drone's rotation
	# The laser extends along Vector2.RIGHT in its local space
	# Convert target position to local space to get relative direction
	var local_target_pos = to_local(target.global_position)
	var local_direction = local_target_pos.normalized()
	# Set rotation so laser fires from front of ship toward asteroid
	laser_2d.rotation = local_direction.angle()
	
	# Update max_length to ensure laser can reach asteroid (but let collision detection stop it)
	var distance = global_position.distance_to(target.global_position)
	# Set max_length to at least the distance plus a buffer, but ensure it's long enough
	# The raycast will stop at the collision point, so max_length just needs to be long enough
	laser_2d.max_length = max(distance + 50.0, mining_start_range * 1.2)
	
	# Reset target_position to ensure laser extends from start when first activated
	# Don't force it to full length - let collision detection handle stopping at asteroid
	if not laser_2d.is_casting:
		laser_2d.target_position = Vector2.ZERO
		laser_2d.is_casting = true

func hide_mining_laser():
	"""Hide the mining laser"""
	if laser_2d and is_instance_valid(laser_2d):
		laser_2d.is_casting = false

func spawn_laser_impact_effect(position: Vector2):
	"""Spawn particle effect at laser impact point"""
	var parent_node = get_parent()
	if VfxDirector and parent_node:
		var local_pos = parent_node.to_local(position)
		VfxDirector.spawn_scorch_decal(parent_node, local_pos, 0.12, randf_range(0.0, TAU))

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

## Loot Collection Methods

func _on_loot_dropped(position: Vector2, resources: Dictionary):
	"""When loot drops nearby, check if we should collect it"""
	# Only collect if we're idle or close enough
	var distance = global_position.distance_to(position)
	
	# Check if we have cargo space
	if carrying_resources >= max_cargo:
		return  # Cargo full
	
	# Auto-collect if close enough (500 units) and not busy
	if distance < 500.0 and (ai_state == AIState.IDLE or ai_state == AIState.RETURNING):
		# Scan for loot orbs near this position
		scan_for_loot_orbs()

func scan_for_loot_orbs():
	"""Scan for nearby loot orbs and collect them"""
	var loot_orbs = get_tree().get_nodes_in_group("loot")
	var closest_loot = null
	var closest_dist = 300.0  # Scan range
	
	for orb in loot_orbs:
		if not is_instance_valid(orb):
			continue
		
		# Check if it's in our zone
		var orb_zone = orb.get_meta("zone_id", "")
		if orb_zone.is_empty() and ZoneManager:
			orb_zone = ZoneManager.get_unit_zone(orb)
		
		var my_zone = ZoneManager.get_unit_zone(self) if ZoneManager else ""
		
		if orb_zone != my_zone or my_zone.is_empty():
			continue
		
		var dist = global_position.distance_to(orb.global_position)
		if dist < closest_dist:
			closest_loot = orb
			closest_dist = dist
	
	if closest_loot:
		# Collect loot directly if close
		if closest_dist < 30.0:
			collect_loot_orb(closest_loot)
		# Otherwise move towards it if idle
		elif ai_state == AIState.IDLE:
			target_position = closest_loot.global_position
			ai_state = AIState.MOVING

func _physics_process(delta: float):
	super._physics_process(delta)
	
	# Check for nearby loot while moving or idle
	if ai_state == AIState.IDLE or ai_state == AIState.MOVING:
		check_for_nearby_loot()

func check_for_nearby_loot():
	"""Check if we're near any loot orbs"""
	if carrying_resources >= max_cargo:
		return  # Cargo full
	
	var loot_orbs = get_tree().get_nodes_in_group("loot")
	for orb in loot_orbs:
		if not is_instance_valid(orb):
			continue
		
		# Check if it's in our zone
		var orb_zone = orb.get_meta("zone_id", "")
		if orb_zone.is_empty() and ZoneManager:
			orb_zone = ZoneManager.get_unit_zone(orb)
		
		var my_zone = ZoneManager.get_unit_zone(self) if ZoneManager else ""
		
		if orb_zone != my_zone or my_zone.is_empty():
			continue
		
		var dist = global_position.distance_to(orb.global_position)
		if dist < 30.0:  # Collection range
			collect_loot_orb(orb)
			break  # Only collect one per frame

func collect_loot_orb(orb: Node2D):
	"""Collect a loot orb"""
	if not is_instance_valid(orb):
		return
	
	# Get resource data
	var resource_id = orb.get_meta("resource_id", 0)
	var amount = orb.get_meta("amount", 0)
	
	# Call orb's collect method if it has one
	if orb.has_method("collect"):
		orb.collect()
	else:
		# Fallback: add resources directly and remove orb
		if ResourceManager:
			ResourceManager.add_resource(resource_id, amount)
		
		# Audio feedback
		if AudioManager:
			AudioManager.play_sound("loot_pickup")
		
		orb.queue_free()
