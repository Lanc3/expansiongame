extends BaseUnit
class_name BuilderDrone

## Builder drone capable of constructing structures

enum BuildState {IDLE, MOVING_TO_SITE, CONSTRUCTING}

@export var build_range: float = 60.0
@export var build_speed: float = 1.0

var build_state: BuildState = BuildState.IDLE
var construction_ghost = null  # Can't type as ConstructionGhost since it's created dynamically
var construction_target_pos: Vector2 = Vector2.ZERO
var building_type_to_construct: String = ""
var construction_progress: float = 0.0

func _ready():
	super._ready()
	unit_name = "Builder Drone"
	max_health = 100.0
	current_health = max_health
	move_speed = 120.0  # Slower than scouts
	vision_range = 700.0  # Builder drones have moderate vision (doubled from 350)
	
	# Apply research effects on spawn
	if ResearchManager:
		ResearchManager.apply_research_to_unit(self)

func can_attack() -> bool:
	return false

func can_mine() -> bool:
	return false

func can_build() -> bool:
	return true

func _physics_process(delta: float):
	super._physics_process(delta)
	
	# Process construction if active (handles both moving and constructing states)
	if build_state == BuildState.MOVING_TO_SITE or build_state == BuildState.CONSTRUCTING:
		process_construction(delta)

func start_construction(building_type: String, world_pos: Vector2):
	"""Begin construction of a building at specified position"""
	# Check if already constructing
	if build_state != BuildState.IDLE:
		return
	
	# Validate building type
	var building_data = BuildingDatabase.get_building_data(building_type)
	if building_data.is_empty():
		return
	
	# Check resources
	if not ResourceManager or not ResourceManager.can_afford_cost(building_data.cost):
		return
	
	# Check research requirements
	if "requires_research" in building_data and building_data.requires_research != "":
		if not ResearchManager or not ResearchManager.is_unlocked(building_data.requires_research):
			return
	
	# Check zone limit
	var zone_id = ZoneManager.get_unit_zone(self) if ZoneManager else 1
	if not BuildingDatabase.can_build_in_zone(building_type, zone_id):
		return
	
	# Check placement validity
	if not BuildingDatabase.is_valid_placement(building_type, world_pos, zone_id):
		return
	
	# Consume resources
	if not ResourceManager.consume_resources(building_data.cost):
		return
	
	# Store construction info
	building_type_to_construct = building_type
	construction_target_pos = world_pos
	construction_progress = 0.0
	
	# CRITICAL: Clear any existing commands to prevent interference
	command_queue.clear()
	current_command_index = 0
	target_entity = null
	
	# Create construction ghost
	create_construction_ghost(building_type, building_data, world_pos, zone_id)
	
	# Move to construction site
	build_state = BuildState.MOVING_TO_SITE
	move_to_construction_site(world_pos)
	
	print("BuilderDrone: Starting construction of %s at %s (distance: %.1f)" % [building_type, world_pos, global_position.distance_to(world_pos)])

func create_construction_ghost(b_type: String, b_data: Dictionary, pos: Vector2, z_id: String):
	"""Create visual ghost preview of building"""
	var ghost_scene = preload("res://scripts/buildings/ConstructionGhost.gd")
	construction_ghost = Node2D.new()
	construction_ghost.set_script(ghost_scene)
	construction_ghost.global_position = pos
	construction_ghost.name = "ConstructionGhost_%s" % b_type
	
	# Initialize ghost properties BEFORE adding to scene
	construction_ghost.building_type = b_type
	construction_ghost.building_data = b_data
	construction_ghost.zone_id = z_id
	
	# Add to scene (to appropriate zone layer for persistence)
	var zone_data = ZoneManager.get_zone(z_id) if ZoneManager else {}
	var zone_layer = zone_data.get("layer_node", null)
	if zone_layer and is_instance_valid(zone_layer):
		zone_layer.add_child(construction_ghost)
	else:
		get_tree().current_scene.add_child(construction_ghost)
	
	# Wait for _ready() to complete, then initialize
	await get_tree().process_frame
	
	# Call initialize to set up visuals
	construction_ghost.initialize(b_type, b_data, z_id)
	construction_ghost.construction_cancelled.connect(_on_construction_cancelled)
	
	print("BuilderDrone: Construction ghost created at %s, valid=%s" % [pos, is_instance_valid(construction_ghost)])

func move_to_construction_site(target_pos: Vector2):
	"""Move drone to construction site"""
	# Set target position for BaseUnit's movement system
	target_position = target_pos
	ai_state = AIState.MOVING
	
	# Use navigation system if available
	if navigation_agent:
		navigation_agent.target_position = target_pos
		print("BuilderDrone: Moving to construction site at %s (current distance: %.1f)" % [target_pos, global_position.distance_to(target_pos)])
func process_construction(delta: float):
	"""Process building construction"""
	# Debug: Print state periodically
	if not has_meta("last_debug_time") or Time.get_ticks_msec() - get_meta("last_debug_time", 0) > 1000:
		set_meta("last_debug_time", Time.get_ticks_msec())
		print("BuilderDrone: process_construction called, state=%s, ghost_valid=%s, distance=%.1f" % [BuildState.keys()[build_state], is_instance_valid(construction_ghost), global_position.distance_to(construction_target_pos)])
	
	if not is_instance_valid(construction_ghost):
		# Ghost was destroyed, cancel construction
		cancel_construction()
		return
	
	# Check if in range
	var distance = global_position.distance_to(construction_target_pos)
	if distance > build_range:
		# Not in range, move closer
		if build_state == BuildState.CONSTRUCTING:
			print("BuilderDrone: Out of range (%.1f > %.1f), switching back to MOVING_TO_SITE" % [distance, build_range])
			build_state = BuildState.MOVING_TO_SITE
			move_to_construction_site(construction_target_pos)
		return
	
	# In range, construct
	if build_state == BuildState.MOVING_TO_SITE:
		build_state = BuildState.CONSTRUCTING
		ai_state = AIState.IDLE
		
		# Notify ghost that construction started
		if is_instance_valid(construction_ghost):
			construction_ghost.start_construction(self)
	
	# Apply research speed bonuses
	var speed_multiplier = 1.0
	if ResearchManager:
		speed_multiplier *= ResearchManager.get_stat("stat_construction_speed")
		speed_multiplier *= ResearchManager.get_stat("stat_worker_speed")
	
	# Increment progress
	var building_data = BuildingDatabase.get_building_data(building_type_to_construct)
	var build_time = building_data.get("build_time", 60.0)
	var progress_per_second = (1.0 / build_time) * build_speed * speed_multiplier
	
	construction_progress += progress_per_second * delta
	construction_progress = min(construction_progress, 1.0)
	
	# Debug output every 10% progress
	var progress_percent = int(construction_progress * 100)
	if progress_percent % 10 == 0 and progress_percent > 0:
		if not has_meta("last_progress_print") or get_meta("last_progress_print") != progress_percent:
			set_meta("last_progress_print", progress_percent)
	
	# Update ghost
	if is_instance_valid(construction_ghost):
		construction_ghost.update_construction_progress(construction_progress)
	
	# Check completion
	if construction_progress >= 1.0:
		complete_construction()

func complete_construction():
	"""Complete the construction"""
	
	# Ghost handles spawning the real building
	# Just reset builder state
	build_state = BuildState.IDLE
	construction_ghost = null
	construction_progress = 0.0
	building_type_to_construct = ""
	ai_state = AIState.IDLE

func cancel_construction():
	"""Cancel ongoing construction"""
	
	if is_instance_valid(construction_ghost):
		construction_ghost.cancel_construction()
	
	build_state = BuildState.IDLE
	construction_ghost = null
	construction_progress = 0.0
	building_type_to_construct = ""
	ai_state = AIState.IDLE

func _on_construction_cancelled():
	"""Handle construction cancellation signal"""
	cancel_construction()

func get_construction_info() -> Dictionary:
	"""Get current construction status for UI"""
	return {
		"is_constructing": build_state == BuildState.CONSTRUCTING,
		"building_type": building_type_to_construct,
		"progress": construction_progress,
		"progress_percent": construction_progress * 100.0
	}
