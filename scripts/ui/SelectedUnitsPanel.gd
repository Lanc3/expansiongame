extends Panel
## Compact selection panel with horizontal scrolling and auto-mode switching

enum DisplayMode {COMPACT, GROUPED}

# Signals
signal paint_mode_activated(mode: String, units: Array)
signal paint_mode_deactivated()

# UI References
@onready var paint_scout_btn: Button = $VBoxContainer/TopBar/PaintButtons/PaintScoutBtn
@onready var paint_mining_btn: Button = $VBoxContainer/TopBar/PaintButtons/PaintMiningBtn
@onready var paint_combat_btn: Button = $VBoxContainer/TopBar/PaintButtons/PaintCombatBtn
@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer
@onready var content_container: HBoxContainer = $VBoxContainer/ScrollContainer/ContentContainer

# Action bar buttons
@onready var action_stop_btn: Button = $VBoxContainer/TopBar/ActionButtons/StopBtn
@onready var action_attack_move_btn: Button = $VBoxContainer/TopBar/ActionButtons/AttackMoveBtn
@onready var action_patrol_btn: Button = $VBoxContainer/TopBar/ActionButtons/PatrolBtn
@onready var action_return_btn: Button = $VBoxContainer/TopBar/ActionButtons/ReturnCargoBtn

# Formation buttons
@onready var formation_buttons_container: HBoxContainer = $VBoxContainer/TopBar/FormationButtons
@onready var formation_line_btn: Button = $VBoxContainer/TopBar/FormationButtons/LineBtn
@onready var formation_wedge_btn: Button = $VBoxContainer/TopBar/FormationButtons/WedgeBtn
@onready var formation_circle_btn: Button = $VBoxContainer/TopBar/FormationButtons/CircleBtn
@onready var formation_grid_btn: Button = $VBoxContainer/TopBar/FormationButtons/GridBtn

# Scenes
var compact_icon_scene: PackedScene

# State
var current_mode: DisplayMode = DisplayMode.COMPACT
var selected_units_cache: Array = []

# Object pooling
var compact_icon_pool: Array = []
var active_icons: Array = []

# Performance
var rebuild_queued: bool = false
var last_selection_hash: int = 0

func _ready():
	# Load scenes
	compact_icon_scene = preload("res://scenes/ui/CompactUnitIcon.tscn")
	
	# Set mouse filter to stop events from propagating through the panel
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Connect to selection manager
	if SelectionManager.selection_changed.is_connected(_on_selection_changed):
		SelectionManager.selection_changed.disconnect(_on_selection_changed)
	SelectionManager.selection_changed.connect(_on_selection_changed)
	
	# Setup paint mode buttons
	if paint_scout_btn:
		paint_scout_btn.pressed.connect(_on_paint_scout_pressed)
	if paint_mining_btn:
		paint_mining_btn.pressed.connect(_on_paint_mining_pressed)
	if paint_combat_btn:
		paint_combat_btn.pressed.connect(_on_paint_combat_pressed)
	
	# Setup action bar buttons
	if action_stop_btn:
		action_stop_btn.pressed.connect(_on_action_stop)
	if action_return_btn:
		action_return_btn.pressed.connect(_on_action_return_cargo)
	
	# Setup formation buttons
	if formation_line_btn:
		formation_line_btn.pressed.connect(_on_formation_line_pressed)
	if formation_wedge_btn:
		formation_wedge_btn.pressed.connect(_on_formation_wedge_pressed)
	if formation_circle_btn:
		formation_circle_btn.pressed.connect(_on_formation_circle_pressed)
	if formation_grid_btn:
		formation_grid_btn.pressed.connect(_on_formation_grid_pressed)
	
	# Connect to FormationManager signal
	if FormationManager.default_formation_changed.is_connected(_on_formation_changed):
		FormationManager.default_formation_changed.disconnect(_on_formation_changed)
	FormationManager.default_formation_changed.connect(_on_formation_changed)
	
	# Set initial button states
	_update_formation_button_states(FormationManager.get_default_formation())
	
	# Initially hidden
	visible = false
	

func _on_selection_changed(selected_units: Array):
	# Calculate hash to detect actual changes
	var new_hash = hash(selected_units)
	if new_hash == last_selection_hash:
		return
	last_selection_hash = new_hash
	
	selected_units_cache = selected_units.duplicate()
	
	# Hide if no selection
	if selected_units.is_empty():
		visible = false
		clear_display()
		return
	
	# Show panel
	visible = true
	
	# Auto-select mode based on unit count
	auto_select_mode(selected_units.size())
	
	# Queue rebuild (deferred to avoid multiple rebuilds per frame)
	if not rebuild_queued:
		rebuild_queued = true
		rebuild_ui.call_deferred()

func auto_select_mode(unit_count: int):
	"""Automatically select the best display mode based on unit count"""
	if unit_count <= 50:
		current_mode = DisplayMode.COMPACT
	else:
		current_mode = DisplayMode.GROUPED

func rebuild_ui():
	rebuild_queued = false
	
	# Clear existing display
	clear_display()
	
	# Build appropriate display
	match current_mode:
		DisplayMode.COMPACT:
			build_compact_view(selected_units_cache)
		DisplayMode.GROUPED:
			build_grouped_view(selected_units_cache)
	
	# Update action bar button states
	update_action_bar_states()
	
	# Update paint button states
	update_paint_button_states()

func build_compact_view(units: Array):
	"""Show compact horizontal row with scrolling"""
	# Add icons horizontally
	for unit in units:
		if not is_instance_valid(unit):
			continue
		
		var icon = get_compact_icon()
		if not is_instance_valid(icon):
			continue
		
		content_container.add_child(icon)
		active_icons.append(icon)
		
		if icon.has_method("setup_for_unit"):
			icon.setup_for_unit(unit)

func build_grouped_view(units: Array):
	"""Show grouped text summary"""
	var groups = group_units_by_type(units)
	
	# Create text summary
	var summary_text = ""
	var group_names = groups.keys()
	
	for i in range(group_names.size()):
		var type_name = group_names[i]
		var count = groups[type_name].count
		summary_text += "%s ×%d" % [type_name, count]
		if i < group_names.size() - 1:
			summary_text += " | "
	
	# Create label to display summary
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.custom_minimum_size = Vector2(0, 60)
	label.text = summary_text
	label.add_theme_font_size_override("normal_font_size", 14)
	
	content_container.add_child(label)
	active_icons.append(label)

func group_units_by_type(units: Array) -> Dictionary:
	"""Group units by their class name"""
	var groups = {}
	
	for unit in units:
		if not is_instance_valid(unit):
			continue
		
		var type_name = unit.get_class()
		
		# Use readable names
		if unit is MiningDrone:
			type_name = "Mining Drone"
		elif unit is CombatDrone:
			type_name = "Combat Drone"
		elif unit is ScoutDrone:
			type_name = "Scout Drone"
		elif "is_command_ship" in unit and unit.is_command_ship:
			type_name = "Command Ship"
		
		if not type_name in groups:
			groups[type_name] = {
				"units": [],
				"count": 0
			}
		
		groups[type_name].units.append(unit)
		groups[type_name].count += 1
	
	return groups

# Object Pooling
func get_compact_icon() -> Node:
	if compact_icon_pool.is_empty():
		var icon = compact_icon_scene.instantiate()
		return icon
	else:
		# Get icon from pool, validate it's still valid
		while not compact_icon_pool.is_empty():
			var icon = compact_icon_pool.pop_back()
			
			# Check if icon is still valid
			if is_instance_valid(icon):
				if icon.has_method("reset"):
					icon.reset()
				icon.visible = true
				return icon
			# Icon was freed, skip it and try next one
		
		# Pool was empty or all icons were invalid, create new one
		var icon = compact_icon_scene.instantiate()
		return icon

func return_icon_to_pool(icon: Node):
	"""Return icon to pool instead of destroying"""
	if not is_instance_valid(icon):
		return
	
	icon.visible = false
	if icon.get_parent():
		icon.get_parent().remove_child(icon)
	compact_icon_pool.append(icon)

func clear_display():
	"""Clear all displayed icons (return to pool when possible)"""
	if not content_container:
		return
	
	# Return icons to pool
	for icon in active_icons:
		if is_instance_valid(icon):
			if icon.has_method("setup_for_unit"):
				return_icon_to_pool(icon)
			else:
				icon.queue_free()
	
	active_icons.clear()
	
	# Clear remaining children
	for child in content_container.get_children():
		child.queue_free()

# Paint Mode Handlers
func _on_paint_scout_pressed():
	"""Activate paint mode for scout drones"""
	var scout_units = _get_units_of_type("scout")
	if scout_units.is_empty():
		return
	
	paint_mode_activated.emit("scout", scout_units)
	AudioManager.play_sound("button_click")

func _on_paint_mining_pressed():
	"""Activate paint mode for mining drones"""
	var mining_units = _get_units_of_type("mining")
	if mining_units.is_empty():
		return
	
	paint_mode_activated.emit("mining", mining_units)
	AudioManager.play_sound("button_click")

func _on_paint_combat_pressed():
	"""Activate paint mode for combat drones"""
	var combat_units = _get_units_of_type("combat")
	if combat_units.is_empty():
		return
	
	paint_mode_activated.emit("combat", combat_units)
	AudioManager.play_sound("button_click")

func _get_units_of_type(type: String) -> Array:
	"""Get selected units of a specific type"""
	var units = []
	
	for unit in selected_units_cache:
		if not is_instance_valid(unit):
			continue
		
		match type:
			"scout":
				if unit is ScoutDrone:
					units.append(unit)
			"mining":
				if unit is MiningDrone:
					units.append(unit)
			"combat":
				if unit.has_method("can_attack") and unit.can_attack():
					units.append(unit)
	
	return units

func update_paint_button_states():
	"""Enable/disable paint buttons based on selection"""
	if not visible:
		return
	
	# Count unit types in selection
	var has_scouts = false
	var has_miners = false
	var has_combat = false
	
	for unit in selected_units_cache:
		if not is_instance_valid(unit):
			continue
		
		if unit is ScoutDrone:
			has_scouts = true
		if unit is MiningDrone:
			has_miners = true
		if unit.has_method("can_attack") and unit.can_attack():
			has_combat = true
	
	# Enable/disable buttons
	if paint_scout_btn:
		paint_scout_btn.disabled = not has_scouts
	if paint_mining_btn:
		paint_mining_btn.disabled = not has_miners
	if paint_combat_btn:
		paint_combat_btn.disabled = not has_combat

# Action Bar Handlers
func _on_action_stop():
	CommandSystem.issue_hold_command(selected_units_cache)
	AudioManager.play_sound("button_click")

	# TODO: Implement patrol mode

func _on_action_return_cargo():
	CommandSystem.issue_return_command(selected_units_cache)
	AudioManager.play_sound("button_click")

func update_action_bar_states():
	"""Enable/disable action buttons based on selection"""
	if not visible:
		return
	
	var units = selected_units_cache
	
	# Stop - always available
	if action_stop_btn:
		action_stop_btn.disabled = units.is_empty()
	
	# Attack-move - only for combat units
	if action_attack_move_btn:
		var has_combat = false
		for unit in units:
			if is_instance_valid(unit) and unit.can_attack():
				has_combat = true
				break
		action_attack_move_btn.disabled = not has_combat
	
	# Return cargo - only for mining drones with cargo
	if action_return_btn:
		var has_cargo = false
		for unit in units:
			if is_instance_valid(unit) and unit is MiningDrone:
				var miner = unit as MiningDrone
				if miner.carrying_resources > 0:
					has_cargo = true
					break
		action_return_btn.disabled = not has_cargo
	
	# Patrol - available for all
	if action_patrol_btn:
		action_patrol_btn.disabled = units.is_empty()

# Cleanup pooled objects on exit
func _exit_tree():
	for icon in compact_icon_pool:
		if is_instance_valid(icon):
			icon.queue_free()
	compact_icon_pool.clear()

## Set the current formation type
func set_formation(formation_type: FormationManager.FormationType):
	if FormationManager:
		FormationManager.set_default_formation(formation_type)

func _on_formation_changed(formation_type: FormationManager.FormationType):
	"""Update formation button states when formation changes"""
	_update_formation_button_states(formation_type)

func _on_formation_line_pressed():
	FormationManager.set_default_formation(FormationManager.FormationType.LINE)
	AudioManager.play_sound("button_click")

func _on_formation_wedge_pressed():
	FormationManager.set_default_formation(FormationManager.FormationType.WEDGE)
	AudioManager.play_sound("button_click")

func _on_formation_circle_pressed():
	FormationManager.set_default_formation(FormationManager.FormationType.CIRCLE)
	AudioManager.play_sound("button_click")

func _on_formation_grid_pressed():
	FormationManager.set_default_formation(FormationManager.FormationType.GRID)
	AudioManager.play_sound("button_click")

func _update_formation_button_states(active_formation: FormationManager.FormationType):
	"""Update toggle states of formation buttons to show active formation"""
	if not formation_line_btn:
		return
	
	# Unpress all buttons first
	formation_line_btn.button_pressed = false
	formation_wedge_btn.button_pressed = false
	formation_circle_btn.button_pressed = false
	formation_grid_btn.button_pressed = false
	
	# Press the active formation button
	match active_formation:
		FormationManager.FormationType.LINE:
			formation_line_btn.button_pressed = true
		FormationManager.FormationType.WEDGE:
			formation_wedge_btn.button_pressed = true
		FormationManager.FormationType.CIRCLE:
			formation_circle_btn.button_pressed = true
		FormationManager.FormationType.GRID:
			formation_grid_btn.button_pressed = true
