extends Node
## Global command system for RTS units

enum CommandType {
	NONE,
	MOVE,
	ATTACK,
	MINE,
	RETURN_CARGO,
	HOLD_POSITION,
	PATROL,
	SCAN,
	TRAVEL_WORMHOLE
}

class Command:
	var type: CommandType = CommandType.NONE
	var target_position: Vector2 = Vector2.ZERO
	var target_entity: Node2D = null
	var queue_command: bool = false

func issue_command(command: Command, selected_units: Array):
	if selected_units.is_empty():
		return
	
	match command.type:
		CommandType.MOVE:
			issue_move_command(selected_units, command.target_position, command.queue_command)
		CommandType.ATTACK:
			issue_attack_command(selected_units, command.target_entity, command.queue_command)
		CommandType.MINE:
			issue_mine_command(selected_units, command.target_entity, command.queue_command)
		CommandType.RETURN_CARGO:
			issue_return_command(selected_units, command.queue_command)
		CommandType.HOLD_POSITION:
			issue_hold_command(selected_units)
		CommandType.SCAN:
			issue_scan_command(selected_units, command.target_entity, command.queue_command)
		CommandType.TRAVEL_WORMHOLE:
			issue_wormhole_travel_command(selected_units, command.target_entity)

func issue_move_command(units: Array, target_pos: Vector2, queue: bool = false):
	# Play single move sound for the entire group
	if units.size() > 0 and AudioManager:
		AudioManager.play_ship_move_sound(units[0])
	
	# Use FormationManager for group movement with proper formations
	if units.size() > 1:
		# Assign formation to the group using current default formation
		FormationManager.assign_formation(units, target_pos, FormationManager.FormationType.NONE)
	
	# Issue individual move commands (units will check FormationManager for offsets)
	for unit in units:
		if unit.has_method("add_command"):
			unit.add_command(CommandType.MOVE, target_pos, null, queue)

func issue_attack_command(units: Array, target: Node2D, queue: bool = false):
	for unit in units:
		if unit.has_method("add_command") and unit.has_method("can_attack"):
			if unit.can_attack():
				unit.add_command(CommandType.ATTACK, Vector2.ZERO, target, queue)

func issue_mine_command(units: Array, resource_node: Node2D, queue: bool = false):
	"""Issue mine command - scouts scan, miners mine"""
	
	var scouts = []
	var miners = []
	
	# Separate scouts from miners
	for unit in units:
		if unit is ScoutDrone:
			scouts.append(unit)
		elif unit.has_method("add_command") and unit.has_method("can_mine") and unit.can_mine():
			miners.append(unit)
	
	
	# Issue scan command to scouts
	if not scouts.is_empty():
		
		issue_scan_command(scouts, resource_node, queue)
	
	# Issue mine command to miners
	for unit in miners:
		
		unit.add_command(CommandType.MINE, Vector2.ZERO, resource_node, queue)

func issue_return_command(units: Array, queue: bool = false):
	for unit in units:
		if unit.has_method("add_command") and "carrying_resources" in unit:
			if unit.carrying_resources > 0:
				unit.add_command(CommandType.RETURN_CARGO, Vector2.ZERO, null, queue)

func issue_hold_command(units: Array):
	for unit in units:
		if unit.has_method("clear_commands"):
			unit.clear_commands()
			unit.add_command(CommandType.HOLD_POSITION, unit.global_position, null, false)

func issue_scan_command(units: Array, asteroid: Node2D, queue: bool = false):
	"""Issue scan command to scout drones"""
	
	for unit in units:
		if unit.has_method("add_command") and unit is ScoutDrone:
			
			unit.add_command(CommandType.SCAN, Vector2.ZERO, asteroid, queue)


func issue_wormhole_travel_command(units: Array, wormhole: Node2D):
	"""Issue wormhole travel command - immediately transfers units"""
	if not wormhole or not wormhole.has_method("travel_units"):
		return
	
	wormhole.travel_units(units)

func get_command_at_position(world_pos: Vector2) -> Command:
	var cmd = Command.new()
	
	# Get current zone for filtering
	var current_zone = ZoneManager.current_zone_id if ZoneManager else 1
	
	# Check for wormholes first (highest priority)
	var wormhole = get_nearest_wormhole(world_pos, 80.0)
	if wormhole:
		cmd.type = CommandType.TRAVEL_WORMHOLE
		cmd.target_entity = wormhole
		cmd.target_position = wormhole.global_position
		return cmd
	
	# Check for enemy units in current zone only
	var enemy = EntityManager.get_nearest_unit(world_pos, 1, null)  # team_id 1 = enemy
	if enemy and world_pos.distance_to(enemy.global_position) < 50:
		# Verify enemy is in current zone
		if ZoneManager.get_unit_zone(enemy) == current_zone:
			cmd.type = CommandType.ATTACK
			cmd.target_entity = enemy
			return cmd
	
	# Check for resource nodes in current zone only
	var resource = EntityManager.get_nearest_resource(world_pos)
	if resource and world_pos.distance_to(resource.global_position) < 50:
		# Verify resource is in current zone
		if ZoneManager.get_unit_zone(resource) == current_zone:
			cmd.type = CommandType.MINE
			cmd.target_entity = resource
			return cmd
	
	# Default to move
	cmd.type = CommandType.MOVE
	cmd.target_position = world_pos
	return cmd

func get_nearest_wormhole(world_pos: Vector2, max_distance: float = 100.0) -> Node2D:
	"""Find nearest wormhole within max_distance"""
	var wormholes = get_tree().get_nodes_in_group("wormholes")
	var nearest: Node2D = null
	var min_dist = max_distance
	
	for wormhole in wormholes:
		if not is_instance_valid(wormhole):
			continue
		
		var dist = world_pos.distance_to(wormhole.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = wormhole
	
	return nearest
