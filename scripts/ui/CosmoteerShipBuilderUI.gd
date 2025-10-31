extends Control
## Main UI controller for Cosmoteer-style ship builder

# Node references
@onready var ship_grid: CosmoteerShipGrid = $CenterPanel/MarginContainer/VBox/GridContainer/ShipGrid
@onready var component_list: VBoxContainer = $LeftPanel/VBox/ComponentScroll/ComponentList
@onready var ship_name_edit: LineEdit = $LeftPanel/VBox/ShipNameEdit

# Hull buttons
@onready var light_btn: Button = $LeftPanel/VBox/HullButtons/LightBtn
@onready var medium_btn: Button = $LeftPanel/VBox/HullButtons/MediumBtn
@onready var heavy_btn: Button = $LeftPanel/VBox/HullButtons/HeavyBtn
@onready var eraser_btn: Button = $LeftPanel/VBox/HullButtons/EraserBtn

# Rotation buttons
@onready var rotate_ccw_btn: Button = $CenterPanel/MarginContainer/VBox/RotationControls/RotateCCWBtn
@onready var rotate_cw_btn: Button = $CenterPanel/MarginContainer/VBox/RotationControls/RotateCWBtn

# Stats labels
@onready var power_label: Label = $RightPanel/VBox/PowerLabel
@onready var power_bar: ProgressBar = $RightPanel/VBox/PowerBar
@onready var thrust_label: Label = $RightPanel/VBox/ThrustLabel
@onready var thrust_bar: ProgressBar = $RightPanel/VBox/ThrustBar
@onready var weight_label: Label = $RightPanel/VBox/WeightLabel
@onready var speed_label: Label = $RightPanel/VBox/SpeedLabel
@onready var cost_label: Label = $RightPanel/VBox/CostLabel
@onready var validation_label: Label = $RightPanel/VBox/ValidationScroll/ValidationLabel

# Action buttons
@onready var build_btn: Button = $RightPanel/VBox/ActionButtons/BuildBtn
@onready var save_btn: Button = $RightPanel/VBox/ActionButtons/SaveLoadHBox/SaveBtn
@onready var load_btn: Button = $RightPanel/VBox/ActionButtons/SaveLoadHBox/LoadBtn
@onready var clear_btn: Button = $RightPanel/VBox/ActionButtons/ClearBtn
@onready var undo_btn: Button = $RightPanel/VBox/ActionButtons/UndoRedoHBox/UndoBtn
@onready var redo_btn: Button = $RightPanel/VBox/ActionButtons/UndoRedoHBox/RedoBtn
@onready var exit_btn: Button = $RightPanel/VBox/ActionButtons/ExitBtn

# Dialogs
@onready var save_dialog: FileDialog = $SaveDialog
@onready var load_dialog: FileDialog = $LoadDialog

# State
var undo_redo_manager: CosmoteerUndoRedoManager
var current_blueprint: CosmoteerShipBlueprint
var component_level_buttons: Dictionary = {}  # comp_type -> ComponentLevelButton
var selected_component_levels: Dictionary = {}  # comp_type -> int

func _ready():
	undo_redo_manager = CosmoteerUndoRedoManager.new()
	current_blueprint = ship_grid.get_current_blueprint()
	
	# Connect ship name field
	ship_name_edit.text = current_blueprint.blueprint_name
	ship_name_edit.text_changed.connect(_on_ship_name_changed)
	
	# Connect hull buttons
	light_btn.pressed.connect(_on_hull_light_pressed)
	medium_btn.pressed.connect(_on_hull_medium_pressed)
	heavy_btn.pressed.connect(_on_hull_heavy_pressed)
	eraser_btn.pressed.connect(_on_eraser_pressed)
	
	# Add tooltips to hull buttons
	light_btn.tooltip_text = "Light Armor: Fast but fragile\nCost: 5 Metal per cell"
	medium_btn.tooltip_text = "Medium Armor: Balanced protection\nCost: 10 Metal per cell"
	heavy_btn.tooltip_text = "Heavy Armor: Maximum protection\nCost: 15 Metal per cell"
	eraser_btn.tooltip_text = "Erase hull and components\nRight-click or press this to erase"
	
	# Connect rotation buttons
	rotate_ccw_btn.pressed.connect(_on_rotate_ccw_pressed)
	rotate_cw_btn.pressed.connect(_on_rotate_cw_pressed)
	
	# Connect action buttons
	build_btn.pressed.connect(_on_build_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	load_btn.pressed.connect(_on_load_pressed)
	clear_btn.pressed.connect(_on_clear_pressed)
	undo_btn.pressed.connect(_on_undo_pressed)
	redo_btn.pressed.connect(_on_redo_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	
	# Add tooltips to buttons
	build_btn.tooltip_text = "Build this ship in the current zone"
	save_btn.tooltip_text = "Save blueprint to file (Ctrl+S)"
	load_btn.tooltip_text = "Load blueprint from file"
	clear_btn.tooltip_text = "Clear all hull and components (Ctrl+N)"
	undo_btn.tooltip_text = "Undo last change (Ctrl+Z)"
	redo_btn.tooltip_text = "Redo last undone change (Ctrl+Y)"
	exit_btn.tooltip_text = "Close blueprint builder (ESC)"
	rotate_ccw_btn.tooltip_text = "Rotate ship counter-clockwise (Q)"
	rotate_cw_btn.tooltip_text = "Rotate ship clockwise (E)"
	
	# Connect grid signals
	ship_grid.grid_changed.connect(_on_grid_changed)
	
	# Connect dialogs
	save_dialog.file_selected.connect(_on_save_dialog_confirmed)
	load_dialog.file_selected.connect(_on_load_dialog_confirmed)
	
	# Build component palette
	build_component_palette()
	
	# Initial state
	record_undo_state()
	update_stats()
	update_undo_redo_buttons()

func _input(event: InputEvent):
	if not event is InputEventKey or not event.pressed:
		return
	
	# Rotation with Q/E
	if event.keycode == KEY_Q:
		ship_grid.rotate_ship_direction(false)  # Counter-clockwise
		update_stats()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_E:
		ship_grid.rotate_ship_direction(true)  # Clockwise
		update_stats()
		get_viewport().set_input_as_handled()
	
	# Undo/Redo with Ctrl+Z/Y
	elif event.ctrl_pressed and event.keycode == KEY_Z:
		_on_undo_pressed()
		get_viewport().set_input_as_handled()
	elif event.ctrl_pressed and event.keycode == KEY_Y:
		_on_redo_pressed()
		get_viewport().set_input_as_handled()
	
	# Save with Ctrl+S
	elif event.ctrl_pressed and event.keycode == KEY_S:
		_on_save_pressed()
		get_viewport().set_input_as_handled()
	
	# Clear with Ctrl+N
	elif event.ctrl_pressed and event.keycode == KEY_N:
		_on_clear_pressed()
		get_viewport().set_input_as_handled()
	
	# Exit with ESC
	elif event.keycode == KEY_ESCAPE:
		_on_exit_pressed()
		get_viewport().set_input_as_handled()

func _on_ship_name_changed(new_name: String):
	"""Update blueprint name when user edits the field"""
	current_blueprint.blueprint_name = new_name

func _on_rotate_ccw_pressed():
	"""Rotate ship direction counter-clockwise"""
	ship_grid.rotate_ship_direction(false)
	update_stats()

func _on_rotate_cw_pressed():
	"""Rotate ship direction clockwise"""
	ship_grid.rotate_ship_direction(true)
	update_stats()

func build_component_palette():
	"""Create level-selectable buttons for all components"""
	# Define component categories
	var categories = {
		"Energy": ["power_core"],
		"Propulsion": ["engine"],
		"Weapons": ["laser_weapon", "missile_launcher"],
		"Defense": ["shield_generator", "repair_bot"]
	}
	
	for category_name in categories.keys():
		# Add category label
		var category_label = Label.new()
		category_label.text = category_name + ":"
		category_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		component_list.add_child(category_label)
		
		# Add components in this category with level selectors
		for comp_type in categories[category_name]:
			# Create ComponentLevelButton
			var level_btn = ComponentLevelButton.new()
			level_btn.setup(comp_type, 1)  # Default to level 1
			level_btn.component_selected.connect(_on_component_level_selected)
			level_btn.level_changed.connect(_on_component_level_changed)
			
			component_list.add_child(level_btn)
			component_level_buttons[comp_type] = level_btn
			selected_component_levels[comp_type] = 1  # Default to level 1
		
		# Add spacer after category (except last)
		if category_name != "Defense":
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(0, 8)
			component_list.add_child(spacer)

func _on_hull_light_pressed():
	ship_grid.set_paint_mode_hull(CosmoteerShipBlueprint.HullType.LIGHT)
	highlight_button(light_btn)

func _on_hull_medium_pressed():
	ship_grid.set_paint_mode_hull(CosmoteerShipBlueprint.HullType.MEDIUM)
	highlight_button(medium_btn)

func _on_hull_heavy_pressed():
	ship_grid.set_paint_mode_hull(CosmoteerShipBlueprint.HullType.HEAVY)
	highlight_button(heavy_btn)

func _on_eraser_pressed():
	ship_grid.set_paint_mode_erase()
	highlight_button(eraser_btn)

func _on_component_level_selected(comp_type: String, level: int):
	"""Component selected for painting at specific level"""
	var comp_id = CosmoteerComponentDefs.build_component_id(comp_type, level)
	ship_grid.set_paint_mode_component(comp_id)
	print("Selected component: %s (Level %d)" % [comp_type, level])

func _on_component_level_changed(comp_type: String, new_level: int):
	"""Component level changed via arrow buttons"""
	selected_component_levels[comp_type] = new_level
	# If this component is currently selected, update paint mode
	if ship_grid.current_component_type != "":
		var parsed = CosmoteerComponentDefs.parse_component_id(ship_grid.current_component_type)
		if parsed["type"] == comp_type:
			var comp_id = CosmoteerComponentDefs.build_component_id(comp_type, new_level)
			ship_grid.set_paint_mode_component(comp_id)

func _on_grid_changed():
	"""Called when grid state changes"""
	record_undo_state()
	update_stats()

func record_undo_state():
	"""Record current state for undo"""
	var blueprint = ship_grid.get_current_blueprint()
	undo_redo_manager.record_state(blueprint)
	update_undo_redo_buttons()

func update_stats():
	"""Update all stat displays"""
	var blueprint = ship_grid.get_current_blueprint()
	
	# Power
	var power = CosmoteerShipStatsCalculator.calculate_power(blueprint)
	var power_gen = power.get("generated", 0)
	var power_con = power.get("consumed", 0)
	var power_bal = power.get("balance", 0)
	power_label.text = "⚡ Power: %.0f / %.0f (+%.0f)" % [power_gen, power_con, power_bal]
	
	# Update power bar
	if power_gen > 0:
		power_bar.max_value = power_gen
		power_bar.value = power_con
	else:
		power_bar.max_value = 1.0
		power_bar.value = 0.0
	
	# Color code power bar
	if power_bal < 0:
		power_bar.modulate = Color.RED
	elif power_bal < 2:
		power_bar.modulate = Color.YELLOW
	else:
		power_bar.modulate = Color.GREEN
	
	# Weight/Thrust
	var weight_thrust = CosmoteerShipStatsCalculator.calculate_weight_thrust(blueprint)
	thrust_label.text = "🚀 Thrust: %.0f / %.0f (%.0f%%)" % [weight_thrust.get("thrust", 0), weight_thrust.get("weight", 0), weight_thrust.get("ratio", 0) * 100]
	weight_label.text = "⚖ Weight: %.0f units" % weight_thrust.get("weight", 0)
	
	# Update thrust bar
	if weight_thrust.get("weight", 0) > 0:
		thrust_bar.max_value = 2.0  # 200% = optimal
		thrust_bar.value = weight_thrust.get("ratio", 0)
	else:
		thrust_bar.max_value = 1.0
		thrust_bar.value = 1.0
	
	# Color code thrust bar
	match weight_thrust.get("status", ""):
		"good":
			thrust_bar.modulate = Color.GREEN
		"warning":
			thrust_bar.modulate = Color.YELLOW
		"insufficient":
			thrust_bar.modulate = Color.RED
		_:
			thrust_bar.modulate = Color.GRAY
	
	# Update grid background tint
	ship_grid.set_thrust_status(weight_thrust.get("status", "good"))
	
	# Speed
	var speed = CosmoteerShipStatsCalculator.calculate_speed(blueprint)
	speed_label.text = "🏃 Speed: %.1f" % speed
	
	# Cost
	var cost = CosmoteerShipStatsCalculator.calculate_cost(blueprint)
	cost_label.text = "💰 Cost: " + CosmoteerShipStatsCalculator.format_cost(cost)
	
	# Validation - Enhanced with severity
	var validation_results = CosmoteerShipStatsCalculator.validate_ship(blueprint)
	var critical_errors = []
	var warnings = []
	var infos = []
	
	for result in validation_results:
		match result.get("severity", "info"):
			"critical":
				critical_errors.append(result.get("message", ""))
			"warning":
				warnings.append(result.get("message", ""))
			"info":
				infos.append(result.get("message", ""))
	
	# Build validation text with color coding and icons
	var validation_text = ""
	var has_critical = critical_errors.size() > 0
	var can_build = not has_critical
	
	if has_critical:
		validation_label.modulate = Color.RED
		validation_text = "✗ CRITICAL:\n"
		for error in critical_errors:
			validation_text += " • " + error + "\n"
		save_btn.disabled = true
		build_btn.disabled = true
	elif warnings.size() > 0:
		validation_label.modulate = Color.YELLOW
		validation_text = "⚠ WARNINGS:\n"
		for warning in warnings:
			validation_text += " • " + warning + "\n"
		save_btn.disabled = false
		build_btn.disabled = false
	else:
		validation_label.modulate = Color.GREEN
		validation_text = "✓ Ship Ready to Build"
		save_btn.disabled = false
		build_btn.disabled = false
	
	# Add info messages
	if infos.size() > 0:
		if validation_text != "":
			validation_text += "\n"
		validation_text += "ℹ INFO:\n"
		for info in infos:
			validation_text += " • " + info + "\n"
	
	# Add warnings after critical errors
	if critical_errors.size() > 0 and warnings.size() > 0:
		validation_text += "\n⚠ WARNINGS:\n"
		for warning in warnings:
			validation_text += " • " + warning + "\n"
	
	validation_label.text = validation_text

func update_undo_redo_buttons():
	"""Update undo/redo button states"""
	undo_btn.disabled = not undo_redo_manager.can_undo()
	redo_btn.disabled = not undo_redo_manager.can_redo()

func highlight_button(btn: Button):
	"""Highlight selected button"""
	# Reset all hull buttons
	light_btn.modulate = Color.WHITE
	medium_btn.modulate = Color.WHITE
	heavy_btn.modulate = Color.WHITE
	eraser_btn.modulate = Color.WHITE
	
	# Highlight selected
	btn.modulate = Color.YELLOW

func _on_clear_pressed():
	ship_grid.clear_grid()
	record_undo_state()
	update_stats()

func _on_undo_pressed():
	var state = undo_redo_manager.undo()
	if state:
		ship_grid.load_blueprint(state)
		update_stats()
		update_undo_redo_buttons()

func _on_redo_pressed():
	var state = undo_redo_manager.redo()
	if state:
		ship_grid.load_blueprint(state)
		update_stats()
		update_undo_redo_buttons()

func _on_save_pressed():
	save_dialog.current_dir = BlueprintPaths.BLUEPRINT_DIR
	save_dialog.current_file = "my_ship.tres"
	save_dialog.popup_centered()

func _on_load_pressed():
	load_dialog.current_dir = BlueprintPaths.BLUEPRINT_DIR
	load_dialog.popup_centered()

func _on_save_dialog_confirmed(path: String):
	"""Save blueprint to file"""
	var blueprint = ship_grid.get_current_blueprint()
	
	# Generate thumbnail (simple for now - can be enhanced later)
	# TODO: Implement proper thumbnail generation
	
	# Extract filename as blueprint name
	var filename = path.get_file().get_basename()
	blueprint.blueprint_name = filename
	
	# Save using centralized system
	var success = BlueprintPaths.save_blueprint(blueprint, path)
	
	if success:
		if FeedbackManager:
			FeedbackManager.show_message("Blueprint saved!")
	else:
		if FeedbackManager:
			FeedbackManager.show_message("Failed to save!")

func _on_load_dialog_confirmed(path: String):
	"""Load blueprint from file"""
	var blueprint = BlueprintPaths.load_blueprint(path)
	
	if blueprint:
		ship_grid.load_blueprint(blueprint)
		undo_redo_manager.clear()
		record_undo_state()
		update_stats()
		print("Blueprint loaded: ", path)
		if FeedbackManager:
			FeedbackManager.show_message("Blueprint loaded!")
	else:
		print("Failed to load blueprint: ", path)
		if FeedbackManager:
			FeedbackManager.show_message("Invalid blueprint file!")

func _on_build_pressed():
	"""Build the ship in the current zone"""
	var blueprint = ship_grid.get_current_blueprint()
	
	# Validate ship first
	var validation_results = CosmoteerShipStatsCalculator.validate_ship(blueprint)
	var has_critical = false
	for result in validation_results:
		if result.get("severity", "") == "critical":
			has_critical = true
			break
	
	if has_critical:
		print("Cannot build ship - critical errors present")
		return
	
	# Get spawn position (camera center)
	var zone_id = ZoneManager.current_zone_id
	var cam = get_viewport().get_camera_2d()
	var spawn_pos = cam.global_position if cam else Vector2.ZERO
	
	# Build the ship
	var shipyard = get_tree().get_first_node_in_group("shipyards")
	if shipyard and shipyard.has_method("build_cosmoteer_ship"):
		shipyard.build_cosmoteer_ship(blueprint, spawn_pos)
		print("Ship '%s' built successfully" % blueprint.blueprint_name)
		queue_free()
	else:
		print("No shipyard found - cannot build ship")

func _on_exit_pressed():
	queue_free()
