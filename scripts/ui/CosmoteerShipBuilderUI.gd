extends Control
## Main UI controller for Cosmoteer-style ship builder

# Node references
@onready var ship_grid: CosmoteerShipGrid = $CenterPanel/MarginContainer/VBox/GridContainer/ShipGrid
@onready var component_list: VBoxContainer = $LeftPanel/VBox/ComponentScroll/ComponentList

# Hull buttons
@onready var light_btn: Button = $LeftPanel/VBox/HullButtons/LightBtn
@onready var medium_btn: Button = $LeftPanel/VBox/HullButtons/MediumBtn
@onready var heavy_btn: Button = $LeftPanel/VBox/HullButtons/HeavyBtn
@onready var eraser_btn: Button = $LeftPanel/VBox/HullButtons/EraserBtn

# Stats labels
@onready var power_label: Label = $RightPanel/VBox/PowerLabel
@onready var power_bar: ProgressBar = $RightPanel/VBox/PowerBar
@onready var thrust_label: Label = $RightPanel/VBox/ThrustLabel
@onready var thrust_bar: ProgressBar = $RightPanel/VBox/ThrustBar
@onready var weight_label: Label = $RightPanel/VBox/WeightLabel
@onready var speed_label: Label = $RightPanel/VBox/SpeedLabel
@onready var cost_label: Label = $RightPanel/VBox/CostLabel
@onready var validation_label: Label = $RightPanel/VBox/ValidationLabel

# Action buttons
@onready var save_btn: Button = $RightPanel/VBox/ActionButtons/SaveBtn
@onready var load_btn: Button = $RightPanel/VBox/ActionButtons/LoadBtn
@onready var clear_btn: Button = $RightPanel/VBox/ActionButtons/ClearBtn
@onready var undo_btn: Button = $RightPanel/VBox/ActionButtons/UndoBtn
@onready var redo_btn: Button = $RightPanel/VBox/ActionButtons/RedoBtn
@onready var exit_btn: Button = $RightPanel/VBox/ActionButtons/ExitBtn

# Dialogs
@onready var save_dialog: FileDialog = $SaveDialog
@onready var load_dialog: FileDialog = $LoadDialog

# State
var undo_redo_manager: CosmoteerUndoRedoManager
var current_blueprint: CosmoteerShipBlueprint

func _ready():
	undo_redo_manager = CosmoteerUndoRedoManager.new()
	current_blueprint = ship_grid.get_current_blueprint()
	
	# Connect hull buttons
	light_btn.pressed.connect(_on_hull_light_pressed)
	medium_btn.pressed.connect(_on_hull_medium_pressed)
	heavy_btn.pressed.connect(_on_hull_heavy_pressed)
	eraser_btn.pressed.connect(_on_eraser_pressed)
	
	# Connect action buttons
	save_btn.pressed.connect(_on_save_pressed)
	load_btn.pressed.connect(_on_load_pressed)
	clear_btn.pressed.connect(_on_clear_pressed)
	undo_btn.pressed.connect(_on_undo_pressed)
	redo_btn.pressed.connect(_on_redo_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	
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

func build_component_palette():
	"""Create buttons for all components"""
	for comp_type in CosmoteerComponentDefs.get_all_component_types():
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_type)
		if comp_def.is_empty():
			continue
		
		var btn = Button.new()
		btn.text = comp_def.get("name", "Unknown")
		btn.tooltip_text = comp_def.get("description", "")
		btn.custom_minimum_size = Vector2(0, 40)
		btn.pressed.connect(_on_component_button_pressed.bind(comp_type))
		
		component_list.add_child(btn)

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

func _on_component_button_pressed(comp_type: String):
	ship_grid.set_paint_mode_component(comp_type)

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
	power_label.text = "Power: %.0f/%.0f" % [power.get("generated", 0), power.get("consumed", 0)]
	if power.get("consumed", 0) > 0:
		power_bar.value = power.get("generated", 0) / power.get("consumed", 0)
	else:
		power_bar.value = 1.0
	
	# Set power bar color
	if power.get("balance", 0) >= 0:
		power_bar.modulate = Color.GREEN
	else:
		power_bar.modulate = Color.RED
	
	# Weight/Thrust
	var weight_thrust = CosmoteerShipStatsCalculator.calculate_weight_thrust(blueprint)
	thrust_label.text = "Thrust: %.1f/%.1f" % [weight_thrust.get("thrust", 0), weight_thrust.get("weight", 0)]
	weight_label.text = "Weight: %.1f" % weight_thrust.get("weight", 0)
	
	if weight_thrust.get("weight", 0) > 0:
		thrust_bar.value = weight_thrust.get("ratio", 0)
	else:
		thrust_bar.value = 1.0
	
	# Set thrust bar color based on status
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
	speed_label.text = "Speed: %.1f" % speed
	
	# Cost
	var cost = CosmoteerShipStatsCalculator.calculate_cost(blueprint)
	cost_label.text = "Cost: " + CosmoteerShipStatsCalculator.format_cost(cost)
	
	# Validation
	var errors = CosmoteerShipStatsCalculator.validate_ship(blueprint)
	if errors.is_empty():
		validation_label.text = "Status: ✓ Valid"
		validation_label.modulate = Color.GREEN
		save_btn.disabled = false
	else:
		validation_label.text = "Errors:\n" + "\n".join(errors)
		validation_label.modulate = Color.RED
		save_btn.disabled = true

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

func _on_exit_pressed():
	queue_free()
