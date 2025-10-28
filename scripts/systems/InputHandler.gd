extends Node
## Handles all game input including selection and commands

var camera: Camera2D
var ui_layer: CanvasLayer

# Control group double-tap detection
var last_group_key_pressed: int = -1
var last_group_key_time: float = 0.0
const DOUBLE_TAP_THRESHOLD: float = 0.3

# Paint mode state
var paint_mode_active: bool = false
var paint_mode_type: String = ""  # "scout", "mining", "combat"
var paint_target_units: Array = []  # Units to receive queued commands
var paint_circle_radius: float = 150.0  # Adjustable
var paint_is_dragging: bool = false
var paint_queued_targets: Array = []  # Targets collected during drag

func _ready():
	camera = get_viewport().get_camera_2d()
	# Find the UI layer
	ui_layer = get_tree().root.get_node_or_null("Game/UI")
	
	# Connect to SelectedUnitsPanel signals
	await get_tree().process_frame  # Wait for scene tree to be ready
	var selected_units_panel = get_tree().root.find_child("SelectedUnitsPanel", true, false)
	if selected_units_panel:
		if selected_units_panel.has_signal("paint_mode_activated"):
			selected_units_panel.paint_mode_activated.connect(_on_paint_mode_activated)
		if selected_units_panel.has_signal("paint_mode_deactivated"):
			selected_units_panel.paint_mode_deactivated.connect(_on_paint_mode_deactivated)

func _input(event: InputEvent):
	# Paint mode takes priority
	if paint_mode_active:
		handle_paint_mode_input(event)
		return
	
	# Check if mouse is over UI - if so, don't process input
	if event is InputEventMouseButton:
		# Use comprehensive UI detection
		if is_mouse_over_ui(event.position):
			return  # Let UI handle it
		
		handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)
	elif event is InputEventKey:
		handle_keyboard(event)

func handle_mouse_button(event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_selection(event.position)
		else:
			end_selection(event.position)
	
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		issue_command(event.position, event.shift_pressed)

func handle_mouse_motion(event: InputEventMouseMotion):
	if SelectionManager.is_dragging:
		SelectionManager.drag_end = event.position

func handle_keyboard(event: InputEventKey):
	if event.pressed:
		# DEBUG: J key triggers random event for testing
		if event.keycode == KEY_J:
			trigger_debug_event()
			return
		
		# DEBUG: K key spawns blueprint ship for testing
		if event.keycode == KEY_K:
			spawn_debug_blueprint_ship()
			return
		
		# DEBUG: F key reveals fog at camera position (for testing)
		if event.keycode == KEY_F:
			if camera and FogOfWarManager and ZoneManager:
				var zone_id = ZoneManager.current_zone_id
				FogOfWarManager.reveal_position(zone_id, camera.global_position, 1000.0)
				print("DEBUG: Revealed fog at camera position in Zone %d: %s" % [zone_id, camera.global_position])
			return
		
		# Handle control group assignment (Ctrl+1-9)
		if event.ctrl_pressed and not event.shift_pressed:
			var group_num = _get_number_key_pressed(event.keycode)
			if group_num > 0:
				_assign_control_group(group_num)
				return
		
		# Handle control group selection (1-9)
		if not event.ctrl_pressed and not event.shift_pressed:
			var group_num = _get_number_key_pressed(event.keycode)
			if group_num > 0:
				_select_control_group(group_num)
				return
		
		# Don't handle unit commands if no units are selected
		var has_selection = SelectionManager.has_selection()
		
		match event.keycode:
			KEY_ESCAPE:
				# Check if any panels are open first
				if _any_panel_open():
					_close_open_panels()
				# Then check if there's a selection
				elif has_selection:
					SelectionManager.clear_selection()
				# Finally, toggle pause menu if nothing is selected
				else:
					toggle_pause_menu()
			KEY_M:
				# Toggle galaxy map
				toggle_galaxy_map()
			KEY_P:
				_toggle_blueprint_builder()
			KEY_H:
				# Hold position - only if units are selected
				if has_selection:
					CommandSystem.issue_hold_command(SelectionManager.selected_units)
			KEY_I:
				# Toggle resource inventory
				if not event.shift_pressed and not event.ctrl_pressed:
					toggle_resource_inventory()
			KEY_K:
				# Stop command - only if units selected AND not using WASD camera
				# To avoid conflict, we require Ctrl+S for stop
				if has_selection and event.ctrl_pressed:
					CommandSystem.issue_hold_command(SelectionManager.selected_units)

func start_selection(screen_pos: Vector2):
	var add_to_selection = Input.is_action_pressed("add_to_selection")
	
	if not add_to_selection:
		SelectionManager.clear_selection()
	
	SelectionManager.is_dragging = true
	SelectionManager.drag_start = screen_pos

func end_selection(screen_pos: Vector2):
	if not SelectionManager.is_dragging:
		return
	
	SelectionManager.is_dragging = false
	SelectionManager.drag_end = screen_pos
	
	var drag_distance = SelectionManager.drag_start.distance_to(screen_pos)
	
	# Increased threshold to 10 pixels to be more forgiving
	if drag_distance < 10:
		# Click selection
		single_unit_selection(screen_pos)
	else:
		# Box selection
		box_selection(SelectionManager.drag_start, screen_pos)

func single_unit_selection(screen_pos: Vector2):
	var world_pos = screen_to_world(screen_pos)
	
	# First check for wormholes (manual check since they use Area2D)
	var wormhole = check_for_wormhole_at_position(world_pos)
	if wormhole:
		if wormhole.has_method("select_wormhole"):
			wormhole.select_wormhole()
		return
	
	# Raycast to find unit - FIXED: Use get_tree().root instead of get_world_2d()
	var space_state = get_tree().root.get_world_2d().direct_space_state
	
	# First check for units (layer 1)
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 1  # Units layer
	
	var result = space_state.intersect_point(query, 1)
	
	if result.size() > 0:
		var unit = result[0].collider
		# Only select units in current zone
		if unit is BaseUnit and unit.team_id == 0:
			if ZoneManager and ZoneManager.get_unit_zone(unit) == ZoneManager.current_zone_id:
				var add_to_selection = Input.is_action_pressed("add_to_selection")
				SelectionManager.select_unit(unit, add_to_selection)
				return
	
	# Check for buildings (layer 2)
	query.collision_mask = 2  # Buildings layer
	result = space_state.intersect_point(query, 1)
	
	if result.size() > 0:
		var building = result[0].collider
		# Check if it's a player building in current zone
		if "team_id" in building and building.team_id == 0:
			if ZoneManager and ZoneManager.get_unit_zone(building) == ZoneManager.current_zone_id:
				SelectionManager.select_building(building)
				return
	
	# If no unit or building found, check for asteroids (layer 4)
	query.collision_mask = 4  # Resources layer
	result = space_state.intersect_point(query, 1)
	
	if result.size() > 0:
		var asteroid = result[0].collider
		# Only select asteroids in current zone
		if asteroid is ResourceNode:
			if ZoneManager and ZoneManager.get_unit_zone(asteroid) == ZoneManager.current_zone_id:
				SelectionManager.select_unit(asteroid, false)  # Asteroids are single-select only

func check_for_wormhole_at_position(world_pos: Vector2) -> Node2D:
	"""Check if there's a wormhole at the clicked position"""
	var wormholes = get_tree().get_nodes_in_group("wormholes")
	var click_radius = 80.0  # Same as wormhole collision radius
	
	for wormhole in wormholes:
		if not is_instance_valid(wormhole):
			continue
		
		# Check if in current zone and within click radius
		if ZoneManager and ZoneManager.get_unit_zone(wormhole) == ZoneManager.current_zone_id:
			if world_pos.distance_to(wormhole.global_position) < click_radius:
				return wormhole
	
	return null

func box_selection(start_screen: Vector2, end_screen: Vector2):
	var world_start = screen_to_world(start_screen)
	var world_end = screen_to_world(end_screen)
	
	var rect = Rect2(
		Vector2(min(world_start.x, world_end.x), min(world_start.y, world_end.y)),
		Vector2(abs(world_end.x - world_start.x), abs(world_end.y - world_start.y))
	)
	
	var add_to_selection = Input.is_action_pressed("add_to_selection")
	SelectionManager.select_units_in_rect(rect, add_to_selection)

func issue_command(screen_pos: Vector2, queue: bool = false):
	var world_pos = screen_to_world(screen_pos)
	var selected_units = SelectionManager.selected_units
	
	if selected_units.is_empty():
		return
	
	var cmd = CommandSystem.get_command_at_position(world_pos)
	cmd.queue_command = queue
	CommandSystem.issue_command(cmd, selected_units)
	
	# Visual feedback
	FeedbackManager.spawn_move_indicator(world_pos)
	
	# Audio feedback
	if cmd.type == 0:  # MOVE
		AudioManager.play_sound("move_command")
	elif cmd.type == 1:  # ATTACK
		AudioManager.play_sound("attack_command")
	elif cmd.type == 2:  # MINE
		AudioManager.play_sound("mine_command")
func command_move(target_pos: Vector2):
	for unit in SelectionManager.selected_units:
		if is_instance_valid(unit) and unit.has_method("move_to"):
			unit.move_to(target_pos)
	
	AudioManager.play_sound("unit_move")

func command_mine(resource: ResourceNode):
	"""Handle mining command - scouts scan, miners mine"""
	var scouts = []
	var miners = []
	
	# Separate scouts from miners
	for unit in SelectionManager.selected_units:
		if not is_instance_valid(unit):
			continue
		if unit is ScoutDrone:
			scouts.append(unit)
		elif unit.has_method("start_mining") and unit.can_mine():
			miners.append(unit)
	
	# Issue scan command to scouts
	if not scouts.is_empty():
		CommandSystem.issue_scan_command(scouts, resource)
	
	# Issue mine command to miners
	if not miners.is_empty():
		CommandSystem.issue_mine_command(miners, resource)
	
	if not miners.is_empty():
		AudioManager.play_sound("command_mine")

func command_attack(target: BaseUnit):
	for unit in SelectionManager.selected_units:
		if is_instance_valid(unit) and unit.has_method("attack_target"):
			unit.attack_target(target)
	
	AudioManager.play_sound("command_attack")

func screen_to_world(screen_pos: Vector2) -> Vector2:
	if not camera:
		return screen_pos
	
	var viewport_size = get_viewport().get_visible_rect().size
	return camera.global_position + (screen_pos - viewport_size / 2) / camera.zoom

func toggle_blueprint_editor():
	var editor = get_tree().root.find_child("BlueprintEditor", true, false)
	if editor:
		editor.visible = !editor.visible

func _toggle_blueprint_builder():
	var builder = get_tree().root.find_child("BlueprintBuilderUI", true, false)
	if builder:
		builder.visible = !builder.visible

func toggle_resource_inventory():
	var inventory = get_tree().root.find_child("ResourceInventoryPanel", true, false)
	if inventory:
		if inventory.visible:
			inventory.hide_panel()
		else:
			inventory.show_panel()

func toggle_galaxy_map():
	"""Toggle the galaxy map"""
	var galaxy_map = get_tree().root.find_child("GalaxyMapUI", true, false)
	if galaxy_map:
		print("InputHandler: Found GalaxyMapUI, toggling (currently visible: %s)" % galaxy_map.visible)
		if galaxy_map.visible:
			galaxy_map.close_map()
		else:
			galaxy_map.open_map()
	else:
		print("InputHandler: ERROR - GalaxyMapUI not found!")

func toggle_pause_menu():
	"""Toggle the pause menu"""
	var pause_menu = get_tree().root.find_child("PauseMenu", true, false)
	if pause_menu:
		if pause_menu.visible:
			pause_menu.hide_menu()
		else:
			pause_menu.show_menu()

func _any_panel_open() -> bool:
	"""Check if any UI panel is currently open"""
	var blueprint_editor = get_tree().root.find_child("BlueprintEditor", true, false)
	if blueprint_editor and blueprint_editor.visible:
		return true

	var blueprint_builder = get_tree().root.find_child("BlueprintBuilderUI", true, false)
	if blueprint_builder and blueprint_builder.visible:
		return true
	
	var inventory = get_tree().root.find_child("ResourceInventoryPanel", true, false)
	if inventory and inventory.visible:
		return true
	
	var asteroid_panel = get_tree().root.find_child("AsteroidInfoPanel", true, false)
	if asteroid_panel and asteroid_panel.visible:
		return true
	
	# Note: CommandShipPanel is now a permanent side panel, not a closeable popup
	
	var wormhole_panel = get_tree().root.find_child("WormholeInfoPanel", true, false)
	if wormhole_panel and wormhole_panel.visible:
		return true
	
	var galaxy_map = get_tree().root.find_child("GalaxyMapUI", true, false)
	if galaxy_map and galaxy_map.visible:
		return true
	
	return false

func _close_open_panels():
	"""Close all open UI panels"""
	var blueprint_editor = get_tree().root.find_child("BlueprintEditor", true, false)
	if blueprint_editor and blueprint_editor.visible:
		blueprint_editor.visible = false
	
	var inventory = get_tree().root.find_child("ResourceInventoryPanel", true, false)
	if inventory and inventory.visible:
		inventory.hide_panel()
	
	var asteroid_panel = get_tree().root.find_child("AsteroidInfoPanel", true, false)
	if asteroid_panel and asteroid_panel.visible:
		asteroid_panel.visible = false
	
	# Note: CommandShipPanel is now a permanent side panel, don't close with ESC
	
	var wormhole_panel = get_tree().root.find_child("WormholeInfoPanel", true, false)
	if wormhole_panel and wormhole_panel.visible:
		wormhole_panel.visible = false
	
	# Close galaxy map if open
	var galaxy_map = get_tree().root.find_child("GalaxyMapUI", true, false)
	if galaxy_map and galaxy_map.visible:
		galaxy_map.close_map()

func is_mouse_over_ui(mouse_pos: Vector2) -> bool:
	"""Check if mouse is over any UI element"""
	var viewport = get_viewport()
	if not viewport:
		return false
	
	# Use Godot's built-in UI detection first
	if viewport.gui_is_dragging():
		return true
	
	# Check if focus owner contains the mouse
	var gui_owner = viewport.gui_get_focus_owner()
	if gui_owner and gui_owner.get_global_rect().has_point(mouse_pos):
		return true
	
	# Check TopInfoBar (top bar with resources)
	var top_info_bar = get_tree().root.find_child("TopInfoBar", true, false)
	if top_info_bar and top_info_bar.visible:
		if top_info_bar is Control and top_info_bar.get_global_rect().has_point(mouse_pos):
			return true
	
	# Check SelectedUnitsPanel
	var selected_units_panel = get_tree().root.find_child("SelectedUnitsPanel", true, false)
	if selected_units_panel and selected_units_panel.visible:
		if selected_units_panel is Control and selected_units_panel.get_global_rect().has_point(mouse_pos):
			return true
	
	# Check BlueprintEditor
	var blueprint_editor = get_tree().root.find_child("BlueprintEditor", true, false)
	if blueprint_editor and blueprint_editor.visible:
		if blueprint_editor is Control and blueprint_editor.get_global_rect().has_point(mouse_pos):
			return true
	
	# Check CommandShipPanel
	var command_ship_panel = get_tree().root.find_child("CommandShipPanel", true, false)
	if command_ship_panel and command_ship_panel.visible:
		if command_ship_panel is Control and command_ship_panel.get_global_rect().has_point(mouse_pos):
			return true
	
	# Check BuilderDronePanel
	var builder_panel = get_tree().root.find_child("BuilderDronePanel", true, false)
	if builder_panel and builder_panel.visible:
		if builder_panel is Control and builder_panel.get_global_rect().has_point(mouse_pos):
			return true
	
	# Check TechTreeUI
	var tech_tree = get_tree().root.find_child("TechTreeUI", true, false)
	if tech_tree and tech_tree.visible:
		if tech_tree is Control and tech_tree.get_global_rect().has_point(mouse_pos):
			return true
	
	# Check BlueprintBuilderUI
	var blueprint_builder = get_tree().root.find_child("BlueprintBuilderUI", true, false)
	if blueprint_builder and blueprint_builder.visible:
		if blueprint_builder is Control and blueprint_builder.get_global_rect().has_point(mouse_pos):
			return true
	
	# Check WormholeInfoPanel
	var wormhole_info_panel = get_tree().root.find_child("WormholeInfoPanel", true, false)
	if wormhole_info_panel and wormhole_info_panel.visible:
		if wormhole_info_panel is Control and wormhole_info_panel.get_global_rect().has_point(mouse_pos):
			return true
	
	# Check AsteroidInfoPanel
	var asteroid_info_panel = get_tree().root.find_child("AsteroidInfoPanel", true, false)
	if asteroid_info_panel and asteroid_info_panel.visible:
		if asteroid_info_panel is Control and asteroid_info_panel.get_global_rect().has_point(mouse_pos):
			return true
	
	# Check ResourceInventoryPanel
	var inventory_panel = get_tree().root.find_child("ResourceInventoryPanel", true, false)
	if inventory_panel and inventory_panel.visible:
		if inventory_panel is Control and inventory_panel.get_global_rect().has_point(mouse_pos):
			return true
	
	# Check Minimap
	var minimap = get_tree().root.find_child("Minimap", true, false)
	if minimap and minimap.visible:
		if minimap is Control and minimap.get_global_rect().has_point(mouse_pos):
			return true
	
	# Check ZoneSwitcher
	var zone_switcher = get_tree().root.find_child("ZoneSwitcher", true, false)
	if zone_switcher and zone_switcher.visible:
		if zone_switcher is Control and zone_switcher.get_global_rect().has_point(mouse_pos):
			return true
	
	# Check GalaxyMapUI
	var galaxy_map = get_tree().root.find_child("GalaxyMapUI", true, false)
	if galaxy_map and galaxy_map.visible:
		if galaxy_map is Control and galaxy_map.get_global_rect().has_point(mouse_pos):
			return true
	
	return false

## Get number (1-9) from keycode, returns 0 if not a number key
func _get_number_key_pressed(keycode: int) -> int:
	match keycode:
		KEY_1, KEY_KP_1: return 1
		KEY_2, KEY_KP_2: return 2
		KEY_3, KEY_KP_3: return 3
		KEY_4, KEY_KP_4: return 4
		KEY_5, KEY_KP_5: return 5
		KEY_6, KEY_KP_6: return 6
		KEY_7, KEY_KP_7: return 7
		KEY_8, KEY_KP_8: return 8
		KEY_9, KEY_KP_9: return 9
	return 0

## Assign currently selected units to a control group
func _assign_control_group(group_num: int):
	if not SelectionManager.has_selection():
		return
	
	var selected = SelectionManager.selected_units
	ControlGroupManager.assign_group(group_num, selected)
	
	# Show feedback
	if FeedbackManager:
		FeedbackManager.show_message("Control Group %d assigned (%d units)" % [group_num, selected.size()])

## Select units in a control group (double-tap to center camera)
func _select_control_group(group_num: int):
	var group_units = ControlGroupManager.get_group(group_num)
	
	if group_units.is_empty():
		return
	
	# Check for double-tap
	var current_time = Time.get_ticks_msec() / 1000.0
	var is_double_tap = (group_num == last_group_key_pressed and 
						 current_time - last_group_key_time < DOUBLE_TAP_THRESHOLD)
	
	# Update double-tap tracking
	last_group_key_pressed = group_num
	last_group_key_time = current_time
	
	# Select the group (clear then select each unit)
	SelectionManager.clear_selection()
	for unit in group_units:
		if is_instance_valid(unit):
			SelectionManager.select_unit(unit, true)
	
	# If double-tap, center camera on group
	if is_double_tap:
		_center_camera_on_units(group_units)
		if FeedbackManager:
			FeedbackManager.show_message("Centered on Control Group %d" % group_num)
	else:
		if FeedbackManager:
			FeedbackManager.show_message("Control Group %d selected (%d units)" % [group_num, group_units.size()])

# Paint Mode Handlers
func _on_paint_mode_activated(mode: String, units: Array):
	"""Activate paint mode"""
	paint_mode_active = true
	paint_mode_type = mode
	paint_target_units = units.duplicate()
	paint_queued_targets.clear()
	paint_is_dragging = false
	
	# Show circle cursor at mouse position
	var mouse_pos = get_viewport().get_mouse_position()
	var world_pos = screen_to_world(mouse_pos)
	PaintModeVisualizer.show_circle(paint_circle_radius, world_pos)

func _on_paint_mode_deactivated():
	"""Deactivate paint mode"""
	paint_mode_active = false
	paint_mode_type = ""
	paint_target_units.clear()
	paint_queued_targets.clear()
	paint_is_dragging = false
	
	PaintModeVisualizer.hide_circle()
	PaintModeVisualizer.clear_highlights()

func handle_paint_mode_input(event: InputEvent):
	"""Handle input during paint mode"""
	# Handle mouse wheel for circle radius adjustment (disable camera zoom)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			paint_circle_radius = clampf(paint_circle_radius + 25.0, 50.0, 500.0)
			PaintModeVisualizer.update_circle_radius(paint_circle_radius)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			paint_circle_radius = clampf(paint_circle_radius - 25.0, 50.0, 500.0)
			PaintModeVisualizer.update_circle_radius(paint_circle_radius)
			return
		
		# Left-click-drag to paint targets
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start painting
				paint_is_dragging = true
				paint_queued_targets.clear()
				PaintModeVisualizer.clear_highlights()
				_collect_paint_targets(screen_to_world(event.position))
			else:
				# Finish painting and issue commands
				if paint_is_dragging:
					_finalize_paint_queue()
	
	# Update circle position on mouse motion
	elif event is InputEventMouseMotion:
		var world_pos = screen_to_world(event.position)
		PaintModeVisualizer.update_circle_position(world_pos)
		
		# Collect targets while dragging
		if paint_is_dragging:
			_collect_paint_targets(world_pos)
	
	# ESC key to cancel paint mode
	elif event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_paint_mode_deactivated()

func _collect_paint_targets(world_pos: Vector2):
	"""Collect targets within paint circle radius"""
	var space_state = get_tree().root.get_world_2d().direct_space_state
	
	# Query for objects in radius
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = paint_circle_radius
	query.shape = shape
	query.transform = Transform2D(0, world_pos)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	match paint_mode_type:
		"scout", "mining":
			# Collect asteroids (layer 2 - Resources)
			query.collision_mask = 4  # Resources layer
			var results = space_state.intersect_shape(query)
			
			for result in results:
				var target = result.collider
				
				# Check if it's a resource node (asteroid) and not already queued
				if target.is_in_group("resources") and target not in paint_queued_targets:
					# Check if in current zone
					if ZoneManager and ZoneManager.get_unit_zone(target) == ZoneManager.current_zone_id:
						paint_queued_targets.append(target)
						PaintModeVisualizer.highlight_target(target, paint_queued_targets.size())
		
		"combat":
			# Collect enemies (layer 1 - Units)
			query.collision_mask = 1  # Units layer
			var results = space_state.intersect_shape(query)
			
			for result in results:
				var target = result.collider
				
				# Check if it's an enemy unit and not already queued
				if "team_id" in target and target.team_id != 0 and target not in paint_queued_targets:
					# Check if in current zone
					if ZoneManager and ZoneManager.get_unit_zone(target) == ZoneManager.current_zone_id:
						paint_queued_targets.append(target)
						PaintModeVisualizer.highlight_target(target, paint_queued_targets.size())

func _finalize_paint_queue():
	"""Distribute targets across units and issue commands"""
	print("Paint: Finalizing queue with %d targets and %d units" % [paint_queued_targets.size(), paint_target_units.size()])
	
	if paint_queued_targets.is_empty() or paint_target_units.is_empty():
		_on_paint_mode_deactivated()
		return
	
	# Remove invalid targets
	var valid_targets = []
	for target in paint_queued_targets:
		if is_instance_valid(target):
			valid_targets.append(target)
	
	if valid_targets.is_empty():
		_on_paint_mode_deactivated()
		return
	
	# Clear existing commands on all units (paint mode replaces queue)
	for unit in paint_target_units:
		if is_instance_valid(unit) and unit.has_method("clear_commands"):
			unit.clear_commands()
	
	# Distribute targets evenly across units
	var unit_count = paint_target_units.size()
	var targets_per_unit = ceili(float(valid_targets.size()) / float(unit_count))
	
	var target_index = 0
	for unit in paint_target_units:
		if not is_instance_valid(unit):
			continue
		
		# Assign targets to this unit
		var unit_targets = []
		for i in range(targets_per_unit):
			if target_index >= valid_targets.size():
				break
			unit_targets.append(valid_targets[target_index])
			target_index += 1
		
		# Issue commands via CommandSystem (queue=true to build up the queue)
		match paint_mode_type:
			"scout":
				# Issue scan commands
				for j in range(unit_targets.size()):
					var target = unit_targets[j]
					var should_queue = (j > 0)  # First command replaces, rest queue
					CommandSystem.issue_scan_command([unit], target, should_queue)
			"mining":
				# Issue mine commands
				for j in range(unit_targets.size()):
					var target = unit_targets[j]
					var should_queue = (j > 0)  # First command replaces, rest queue
					CommandSystem.issue_mine_command([unit], target, should_queue)
			"combat":
				# Issue attack commands
				for j in range(unit_targets.size()):
					var target = unit_targets[j]
					var should_queue = (j > 0)  # First command replaces, rest queue
					CommandSystem.issue_attack_command([unit], target, should_queue)
	
	# Feedback
	if FeedbackManager:
		FeedbackManager.show_message("Queued %d targets for %d units" % [valid_targets.size(), unit_count])
	
	# Play sound
	if AudioManager:
		AudioManager.play_sound("button_click")
	
	# Deactivate paint mode
	_on_paint_mode_deactivated()

## Center camera on a group of units
func _center_camera_on_units(units: Array):
	if units.is_empty() or not camera:
		return
	
	# Calculate centroid
	var centroid = Vector2.ZERO
	var valid_count = 0
	
	for unit in units:
		if is_instance_valid(unit):
			centroid += unit.global_position
			valid_count += 1
	
	if valid_count > 0:
		centroid /= valid_count
		camera.focus_on_position(centroid, 0.3)

# DEBUG FUNCTIONS
func trigger_debug_event():
	"""DEBUG: Trigger a random event for testing (J key)"""
	if not EventManager or not ZoneManager:
		print("EventManager or ZoneManager not available")
		return
	
	var zone_id = ZoneManager.current_zone_id
	var event_id = EventManager.pick_random_event_for_zone(zone_id)
	
	print("DEBUG: Triggering event '%s' in Zone %d (Press J)" % [event_id, zone_id])
	EventManager.trigger_event(event_id)

func spawn_debug_blueprint_ship():
	"""DEBUG: Spawn a blueprint ship at camera position (K key)"""
	# Get all blueprint files using centralized system
	var blueprint_files = BlueprintPaths.get_all_blueprint_files()
	
	if blueprint_files.is_empty():
		print("DEBUG: No blueprint files found")
		return
	
	# Load the last blueprint (most recent save)
	var blueprint_path = blueprint_files.back()
	var blueprint = BlueprintPaths.load_blueprint(blueprint_path)
	
	if not blueprint:
		print("DEBUG: Invalid blueprint file")
		return
	
	print("DEBUG: Spawning blueprint ship '%s' (Press K)" % blueprint.blueprint_name)
	
	# Get camera position
	var camera = get_tree().root.get_camera_2d()
	var spawn_pos = camera.global_position if camera else Vector2.ZERO
	
	# Instantiate CustomShip
	var ship_scene = load("res://scenes/units/CustomShip.tscn")
	if not ship_scene:
		print("DEBUG: Could not load CustomShip scene")
		return
	
	var ship = ship_scene.instantiate()
	ship.global_position = spawn_pos
	ship.team_id = 0  # Player team
	
	# Initialize from Cosmoteer blueprint
	if ship.has_method("initialize_from_cosmoteer_blueprint"):
		ship.initialize_from_cosmoteer_blueprint(blueprint)
	
	# Add to current zone
	var zone_id = ZoneManager.current_zone_id if ZoneManager else 1
	var zone_layer = ZoneManager.get_zone(zone_id).layer_node if ZoneManager else null
	
	if zone_layer:
		var units_container = zone_layer.get_node_or_null("Entities/Units")
		if units_container:
			units_container.add_child(ship)
			
			if EntityManager:
				EntityManager.register_unit(ship, zone_id)
			
			print("DEBUG: Blueprint ship spawned at ", spawn_pos)
