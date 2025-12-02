extends PanelContainer
## Individual unit production button showing costs and build time

signal build_requested(unit_type: String)

var unit_type: String
var production_data: Dictionary
var command_ship: Node2D
var is_compact: bool = false

# Try both layouts (VBox for full, HBox for compact)
@onready var icon_rect: TextureRect = null
@onready var name_label: Label = null
@onready var cost_container: VBoxContainer = null
@onready var time_label: Label = null
@onready var build_button: Button = null
@onready var multiplier_label: Label = null

func _ready():
	# Ensure this button blocks input
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Detect layout type
	if has_node("HBox"):
		# Compact layout
		is_compact = true
		icon_rect = $HBox/IconRect if has_node("HBox/IconRect") else null
		name_label = $HBox/VBox/NameLabel if has_node("HBox/VBox/NameLabel") else null
		build_button = $HBox/VBox/BuildButton if has_node("HBox/VBox/BuildButton") else null
	else:
		# Full layout
		is_compact = false
		icon_rect = $VBox/IconRect if has_node("VBox/IconRect") else null
		name_label = $VBox/NameLabel if has_node("VBox/NameLabel") else null
		cost_container = $VBox/CostContainer if has_node("VBox/CostContainer") else null
		time_label = $VBox/TimeLabel if has_node("VBox/TimeLabel") else null
		build_button = $VBox/BuildButton if has_node("VBox/BuildButton") else null
		multiplier_label = $VBox/MultiplierLabel if has_node("VBox/MultiplierLabel") else null
	
	# Add hover effects
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	"""Add hover glow effect"""
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate", Color(1.1, 1.1, 1.1, 1.0), 0.15)
	tween.parallel().tween_property(self, "scale", Vector2(1.02, 1.02), 0.15)
	
	# Play hover sound
	if AudioManager and AudioManager.has_method("play_ui_sound"):
		AudioManager.play_ui_sound("hover")

func _on_mouse_exited():
	"""Remove hover effect"""
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.15)

func setup(type: String, data: Dictionary, ship: Node2D):
	"""Setup button with unit data"""
	unit_type = type
	production_data = data
	command_ship = ship
	
	# Set icon
	if icon_rect:
		var icon_path = data.get("icon_path", "")
		if icon_path != "":
			var texture = load(icon_path)
			if texture:
				icon_rect.texture = texture
	
	# Set name
	if name_label:
		var display_name = data.get("display_name", type)
		# For compact mode, abbreviate long names
		if is_compact and display_name.length() > 10:
			display_name = display_name.substr(0, 8) + ".."
		name_label.text = display_name
	
	# Set build time (only in full mode)
	if time_label:
		time_label.text = "Build: %.0fs" % data.get("build_time", 10.0)
	
	# Calculate and display cost with multiplier
	if not is_compact:
		update_cost_display()
	
	# Setup tooltip for compact mode
	if is_compact:
		setup_compact_tooltip()
	
	# Connect button
	if build_button:
		if build_button.pressed.is_connected(_on_build_pressed):
			build_button.pressed.disconnect(_on_build_pressed)
		build_button.pressed.connect(_on_build_pressed)
	
	# Check affordability
	update_availability()

func setup_compact_tooltip():
	"""Setup detailed tooltip for compact mode"""
	var tooltip_text = production_data.get("display_name", unit_type)
	tooltip_text += "\nBuild Time: %.0fs" % production_data.get("build_time", 10.0)
	
	# Add costs
	if is_instance_valid(command_ship):
		var cost = command_ship.calculate_production_cost(unit_type)
		tooltip_text += "\n\nCost:"
		for resource_id in cost:
			var resource_data = ResourceDatabase.get_resource_by_id(resource_id)
			if not resource_data.is_empty():
				var current = ResourceManager.get_resource_count(resource_id)
				var needed = cost[resource_id]
				tooltip_text += "\n  %s: %d/%d" % [resource_data.name, current, needed]
	
	tooltip_text = tooltip_text
	if build_button:
		build_button.tooltip_text = tooltip_text

func update_cost_display():
	"""Update cost labels with current pricing"""
	if not cost_container or not is_instance_valid(command_ship):
		return
	
	# Clear existing cost labels
	for child in cost_container.get_children():
		child.queue_free()
	
	# Calculate actual cost
	var cost = command_ship.calculate_production_cost(unit_type)
	var base_cost = production_data.get("base_cost", {})
	
	# Show each resource cost
	for resource_id in cost:
		var resource_data = ResourceDatabase.get_resource_by_id(resource_id)
		if resource_data.is_empty():
			continue
		
		var cost_label = Label.new()
		var current_amount = ResourceManager.get_resource_count(resource_id)
		var needed = cost[resource_id]
		
		# Color code based on affordability
		var color = Color.GREEN if current_amount >= needed else Color.RED
		cost_label.add_theme_color_override("font_color", color)
		cost_label.text = "%s: %d/%d" % [resource_data.name, current_amount, needed]
		
		cost_container.add_child(cost_label)
	
	# Show multiplier if scaling is active
	if multiplier_label:
		var existing_count = command_ship.count_existing_units(unit_type)
		if existing_count > 0:
			var multiplier = 1.0 + (existing_count * 0.1)
			multiplier_label.text = "x%.1f (have %d)" % [multiplier, existing_count]
			multiplier_label.visible = true
		else:
			multiplier_label.visible = false

func update_availability():
	"""Update button enabled state based on affordability"""
	if not build_button or not is_instance_valid(command_ship):
		return
	
	var cost = command_ship.calculate_production_cost(unit_type)
	var can_afford = ResourceManager.can_afford_cost(cost)
	var queue_not_full = command_ship.production_queue.size() < command_ship.MAX_QUEUE_SIZE
	
	var limit_reached = false
	if command_ship.has_method("can_build_more_units"):
		if not command_ship.can_build_more_units():
			limit_reached = true
	
	build_button.disabled = not (can_afford and queue_not_full and not limit_reached)
	
	# Update button text
	if limit_reached:
		build_button.text = "Limit Reached"
	elif not queue_not_full:
		build_button.text = "Queue Full"
	elif not can_afford:
		build_button.text = "Need Resources"
	else:
		build_button.text = "Build"

func _on_build_pressed():
	"""Handle build button press"""
	# Click flash effect
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.3, 1.3, 1.3, 1.0), 0.05)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
	
	# Play click sound
	if AudioManager and AudioManager.has_method("play_ui_sound"):
		AudioManager.play_ui_sound("click")
	
	build_requested.emit(unit_type)
	
	# Update display after build attempt
	call_deferred("update_cost_display")
	call_deferred("update_availability")

