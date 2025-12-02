extends Control
## Main UI controller for Cosmoteer-style ship builder

# Node references
@onready var ship_grid: CosmoteerShipGrid = $CenterPanel/MarginContainer/VBox/GridContainer/ShipGrid
@onready var component_list: VBoxContainer = $LeftPanel/VBox/ComponentScroll/ComponentList
@onready var component_scroll: ScrollContainer = $LeftPanel/VBox/ComponentScroll
@onready var ship_name_edit: LineEdit = $LeftPanel/VBox/ShipNameEdit
@onready var left_vbox: VBoxContainer = $LeftPanel/VBox

# Search filter
var search_filter: LineEdit
var clear_search_btn: Button

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
@onready var cost_list: VBoxContainer = $RightPanel/VBox/CostScroll/CostList
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
	rotate_ccw_btn.tooltip_text = "Rotate ship counter-clockwise 60° (Q)"
	rotate_cw_btn.tooltip_text = "Rotate ship clockwise 60° (E)"
	
	# Connect grid signals
	ship_grid.grid_changed.connect(_on_grid_changed)
	
	# Connect dialogs
	save_dialog.file_selected.connect(_on_save_dialog_confirmed)
	load_dialog.file_selected.connect(_on_load_dialog_confirmed)
	
	# Create search filter UI
	_create_search_filter()
	
	# Build component palette
	build_component_palette()
	
	# Connect to resource changes to update cost display
	if ResourceManager:
		ResourceManager.resource_count_changed.connect(_on_resource_count_changed)
	
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

func _create_search_filter():
	"""Create the search filter UI above the component scroll"""
	# Create container for search with clear button
	var search_container = HBoxContainer.new()
	search_container.add_theme_constant_override("separation", 4)
	
	# Create search icon/label
	var search_icon = Label.new()
	search_icon.text = "🔍"
	search_icon.add_theme_font_size_override("font_size", 14)
	search_container.add_child(search_icon)
	
	# Create search input
	search_filter = LineEdit.new()
	search_filter.placeholder_text = "Search components..."
	search_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_filter.custom_minimum_size = Vector2(0, 28)
	search_filter.clear_button_enabled = true
	search_filter.text_changed.connect(_on_search_filter_changed)
	search_container.add_child(search_filter)
	
	# Style the search box
	var search_style = StyleBoxFlat.new()
	search_style.bg_color = Color(0.1, 0.12, 0.16, 0.9)
	search_style.border_width_bottom = 2
	search_style.border_color = Color(0.3, 0.35, 0.4, 0.8)
	search_style.corner_radius_top_left = 4
	search_style.corner_radius_top_right = 4
	search_style.corner_radius_bottom_right = 4
	search_style.corner_radius_bottom_left = 4
	search_style.content_margin_left = 8
	search_style.content_margin_right = 8
	search_filter.add_theme_stylebox_override("normal", search_style)
	
	# Insert search container before component scroll
	var scroll_index = component_scroll.get_index()
	left_vbox.add_child(search_container)
	left_vbox.move_child(search_container, scroll_index)

func _on_search_filter_changed(new_text: String):
	"""Filter components based on search text"""
	var search = new_text.strip_edges().to_lower()
	
	# Iterate through all children in component list
	for child in component_list.get_children():
		if child is ComponentLevelButton:
			# Use the button's filter method
			child.visible = child.matches_filter(search)
		elif child is Label:
			# Category labels - check if any components in this category are visible
			var category_name = child.text.trim_suffix(":")
			var has_visible_components = false
			
			# Look ahead to find components in this category
			var idx = child.get_index()
			for i in range(idx + 1, component_list.get_child_count()):
				var next_child = component_list.get_child(i)
				if next_child is Label:
					# Hit next category, stop
					break
				elif next_child is ComponentLevelButton:
					if next_child.matches_filter(search):
						has_visible_components = true
						break
			
			child.visible = has_visible_components or search.is_empty()
		elif child is Control and child.custom_minimum_size.y > 0:
			# Spacers - hide if search is active
			child.visible = search.is_empty()

func _on_rotate_ccw_pressed():
	"""Rotate ship direction counter-clockwise"""
	ship_grid.rotate_ship_direction(false)
	update_stats()

func _on_rotate_cw_pressed():
	"""Rotate ship direction clockwise"""
	ship_grid.rotate_ship_direction(true)
	update_stats()

func build_component_palette():
	"""Create level-selectable buttons for all components - supports all 21 weapon types"""
	# Define component categories - organized by type with weapon subcategories
	var categories = {
		"Energy": ["power_core"],
		"Propulsion": ["engine"],
		"Kinetic Weapons": ["laser_weapon", "autocannon", "railgun", "gatling", "sniper_cannon", "shotgun"],
		"Energy Weapons": ["ion_cannon", "plasma_cannon", "particle_beam", "tesla_coil", "disruptor"],
		"Explosive Weapons": ["missile_launcher", "flak_cannon", "torpedo", "rocket_pod", "mortar", "mine_layer"],
		"Special Weapons": ["cryo_cannon", "emp_burst", "gravity_well", "repair_beam"],
		"Defense": ["shield_generator", "repair_bot"],
		"Operations": ["scanner", "miner"]
	}
	
	# Category order for display
	var category_order = ["Energy", "Propulsion", "Kinetic Weapons", "Energy Weapons", "Explosive Weapons", "Special Weapons", "Defense", "Operations"]
	
	for category_name in category_order:
		if not categories.has(category_name):
			continue
			
		# Add category label with styling
		var category_label = Label.new()
		category_label.text = category_name
		category_label.add_theme_font_size_override("font_size", 13)
		
		# Get category color from definitions
		var label_color = CosmoteerComponentDefs.get_category_color(category_name)
		category_label.add_theme_color_override("font_color", label_color)
		component_list.add_child(category_label)
		
		# Add subtle separator line
		var separator = HSeparator.new()
		separator.modulate = label_color
		separator.modulate.a = 0.4
		component_list.add_child(separator)
		
		# Add components in this category with level selectors
		for comp_type in categories[category_name]:
			# Check if this component type is defined
			if not CosmoteerComponentDefs.COMPONENT_TYPES.has(comp_type):
				continue
				
			# Create ComponentLevelButton
			var level_btn = ComponentLevelButton.new()
			level_btn.setup(comp_type, 1)  # Default to level 1
			level_btn.component_selected.connect(_on_component_level_selected)
			level_btn.level_changed.connect(_on_component_level_changed)
			
			component_list.add_child(level_btn)
			component_level_buttons[comp_type] = level_btn
			selected_component_levels[comp_type] = 1  # Default to level 1
		
		# Add spacer after category (except last)
		if category_name != "Operations":
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
	
	# Cost - Display as color-coded resource list
	var cost = CosmoteerShipStatsCalculator.calculate_cost(blueprint)
	_update_cost_display(cost)
	
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

func _update_cost_display(cost: Dictionary):
	"""Update the resource cost display with color-coded, sorted resources"""
	if not cost_list:
		return
	
	# Clear existing items
	for child in cost_list.get_children():
		child.queue_free()
	
	if cost.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Free"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_list.add_child(empty_label)
		return
	
	# Get ResourceManager for availability checking
	var resource_manager = ResourceManager if ResourceManager else null
	
	# Sort resources by tier, then by resource ID
	var sorted_resources = []
	for resource_id in cost.keys():
		var amount = cost[resource_id]
		var resource_data = ResourceDatabase.get_resource_by_id(resource_id) if ResourceDatabase else {}
		var tier = resource_data.get("tier", 0) if not resource_data.is_empty() else 0
		var name = resource_data.get("name", "Unknown") if not resource_data.is_empty() else "Resource %d" % resource_id
		var color = resource_data.get("color", Color.WHITE) if not resource_data.is_empty() else Color.WHITE
		
		# Get current amount from ResourceManager
		var current_amount = 0
		if resource_manager:
			current_amount = resource_manager.get_resource_count(resource_id)
		
		sorted_resources.append({
			"id": resource_id,
			"amount": amount,
			"current": current_amount,
			"tier": tier,
			"name": name,
			"color": color
		})
	
	# Sort by tier (ascending), then by name
	sorted_resources.sort_custom(func(a, b):
		if a.tier != b.tier:
			return a.tier < b.tier
		return a.name < b.name
	)
	
	# Group by tier and create labels
	var current_tier = -1
	for resource in sorted_resources:
		# Add tier separator if tier changed
		if resource.tier != current_tier:
			if current_tier != -1:
				# Add spacing between tiers
				var spacer = Control.new()
				spacer.custom_minimum_size = Vector2(0, 4)
				cost_list.add_child(spacer)
			
			# Add tier header
			var tier_label = Label.new()
			tier_label.text = "Tier %d:" % resource.tier
			tier_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
			tier_label.add_theme_font_size_override("font_size", 11)
			cost_list.add_child(tier_label)
			
			current_tier = resource.tier
		
		# Create resource item (HBoxContainer with colored background)
		var resource_item = HBoxContainer.new()
		resource_item.custom_minimum_size = Vector2(0, 20)
		
		# Color indicator (small colored square)
		var color_indicator = ColorRect.new()
		color_indicator.custom_minimum_size = Vector2(4, 20)
		color_indicator.color = resource.color
		resource_item.add_child(color_indicator)
		
		# Resource name and amount label
		var resource_label = Label.new()
		resource_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		resource_label.text = "%s: %d" % [resource.name, resource.amount]
		
		# Color code based on availability
		if resource_manager:
			if resource.current >= resource.amount:
				resource_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1))  # Green
			else:
				resource_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1))  # Red
				# Show current/needed
				resource_label.text = "%s: %d/%d" % [resource.name, resource.current, resource.amount]
		else:
			resource_label.add_theme_color_override("font_color", Color.WHITE)
		
		resource_item.add_child(resource_label)
		cost_list.add_child(resource_item)

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

func _on_resource_count_changed(resource_id: int, new_count: int):
	"""Refresh cost display when resources change"""
	# Only refresh if we have a blueprint with costs
	var blueprint = ship_grid.get_current_blueprint()
	var cost = CosmoteerShipStatsCalculator.calculate_cost(blueprint)
	if cost.has(resource_id):
		_update_cost_display(cost)
