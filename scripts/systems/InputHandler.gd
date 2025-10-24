extends Node
## Handles all game input including selection and commands

var camera: Camera2D
var ui_layer: CanvasLayer

# Control group double-tap detection
var last_group_key_pressed: int = -1
var last_group_key_time: float = 0.0
const DOUBLE_TAP_THRESHOLD: float = 0.3

func _ready():
	camera = get_viewport().get_camera_2d()
	# Find the UI layer
	ui_layer = get_tree().root.get_node_or_null("Game/UI")

func _input(event: InputEvent):
	# Check if mouse is over UI - if so, don't process input
	if event is InputEventMouseButton:
		# Use Godot's built-in UI detection first
		if get_viewport().gui_is_dragging():
			return
		
		# Check if any Control node is under the mouse
		var control_under_mouse = get_viewport().gui_get_focus_owner()
		if control_under_mouse and control_under_mouse.get_global_rect().has_point(event.position):
			return
		
		# Check if CommandShipPanel is visible and mouse is over it (now a side panel)
		var command_ship_panel = get_tree().root.find_child("CommandShipPanel", true, false)
		if command_ship_panel and command_ship_panel.visible:
			if command_ship_panel is Control and command_ship_panel.get_global_rect().has_point(event.position):
				return
		
		# Check if BuilderDronePanel is visible and mouse is over it
		var builder_panel = get_tree().root.find_child("BuilderDronePanel", true, false)
		if builder_panel and builder_panel.visible:
			if builder_panel is Control and builder_panel.get_global_rect().has_point(event.position):
				return
		
		# Check if TechTreeUI is visible and mouse is over it
		var tech_tree = get_tree().root.find_child("TechTreeUI", true, false)
		if tech_tree and tech_tree.visible:
			if tech_tree is Control and tech_tree.get_global_rect().has_point(event.position):
				return
		# Check if BlueprintBuilderUI is visible and mouse is over it
		var blueprint_builder = get_tree().root.find_child("BlueprintBuilderUI", true, false)
		if blueprint_builder and blueprint_builder.visible:
			if blueprint_builder is Control and blueprint_builder.get_global_rect().has_point(event.position):
				return
		
		# Fallback to our custom detection
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
		if unit is BaseUnit and unit.team_id == 0:
			var add_to_selection = Input.is_action_pressed("add_to_selection")
			SelectionManager.select_unit(unit, add_to_selection)
			return
	
	# Check for buildings (layer 2)
	query.collision_mask = 2  # Buildings layer
	result = space_state.intersect_point(query, 1)
	
	if result.size() > 0:
		var building = result[0].collider
		# Check if it's a player building
		if "team_id" in building and building.team_id == 0:
			SelectionManager.select_building(building)
			return
	
	# If no unit or building found, check for asteroids (layer 4)
	query.collision_mask = 4  # Resources layer
	result = space_state.intersect_point(query, 1)
	
	if result.size() > 0:
		var asteroid = result[0].collider
		if asteroid is ResourceNode:
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

func is_mouse_over_ui(mouse_pos: Vector2) -> bool:
	"""Check if mouse is over any UI element"""
	# Get all Control nodes at the mouse position
	var viewport = get_viewport()
	if not viewport:
		return false
	
	# Use the Viewport's gui_get_focus_owner or check for UI elements
	var gui_owner = viewport.gui_get_focus_owner()
	
	# More robust: check if any Control is under the mouse
	# We'll find all UI panels and check if mouse is within their rect
	var selected_units_panel = get_tree().root.find_child("SelectedUnitsPanel", true, false)
	if selected_units_panel and selected_units_panel.visible:
		if selected_units_panel is Control and selected_units_panel.get_global_rect().has_point(mouse_pos):
			return true
	
	var blueprint_editor = get_tree().root.find_child("BlueprintEditor", true, false)
	if blueprint_editor and blueprint_editor.visible:
		if blueprint_editor is Control and blueprint_editor.get_global_rect().has_point(mouse_pos):
			return true
	
	var command_ship_panel = get_tree().root.find_child("CommandShipPanel", true, false)
	if command_ship_panel and command_ship_panel.visible:
		if command_ship_panel is Control and command_ship_panel.get_global_rect().has_point(mouse_pos):
			return true
	
	var builder_panel = get_tree().root.find_child("BuilderDronePanel", true, false)
	if builder_panel and builder_panel.visible:
		if builder_panel is Control and builder_panel.get_global_rect().has_point(mouse_pos):
			return true
	
	var tech_tree = get_tree().root.find_child("TechTreeUI", true, false)
	if tech_tree and tech_tree.visible:
		if tech_tree is Control and tech_tree.get_global_rect().has_point(mouse_pos):
			return true
	
	var wormhole_info_panel = get_tree().root.find_child("WormholeInfoPanel", true, false)
	if wormhole_info_panel and wormhole_info_panel.visible:
		if wormhole_info_panel is Control and wormhole_info_panel.get_global_rect().has_point(mouse_pos):
			return true
	
	var asteroid_info_panel = get_tree().root.find_child("AsteroidInfoPanel", true, false)
	if asteroid_info_panel and asteroid_info_panel.visible:
		if asteroid_info_panel is Control and asteroid_info_panel.get_global_rect().has_point(mouse_pos):
			return true
	
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.visible:
		if hud is Control:
			# Check if mouse is over any visible child controls
			for child in hud.get_children():
				if child is Control and child.visible and child.get_global_rect().has_point(mouse_pos):
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
