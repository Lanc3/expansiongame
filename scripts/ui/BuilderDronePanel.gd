extends Panel
## Builder Drone panel - shows buildable structures (matches CommandShipPanel style)

signal building_selected(building_type: String)

@onready var building_buttons_container: HBoxContainer = $VBox/ButtonRow/ButtonScroll/BuildingButtons if has_node("VBox/ButtonRow/ButtonScroll/BuildingButtons") else null
@onready var status_label: Label = $VBox/TopRow/StatusLabel if has_node("VBox/TopRow/StatusLabel") else null

var selected_builder: BuilderDrone = null
var is_placement_active: bool = false

func _ready():
	visible = false
	
	# Ensure panel blocks input to game world
	mouse_filter = Control.MOUSE_FILTER_STOP
	

func show_for_builder(builder: BuilderDrone):
	"""Display panel for the selected builder drone"""
	if not is_instance_valid(builder):
		return
	
	selected_builder = builder
	visible = true
	
	rebuild_building_list()
	update_status("Select a building to construct")

func rebuild_building_list():
	"""Rebuild the list of buildable structures"""
	clear_buttons()
	
	if not BuildingDatabase:
		return
	
	# Get all buildable buildings
	var buildable = BuildingDatabase.get_buildable_buildings()
	
	for building_type in buildable:
		create_building_button(building_type)

func clear_buttons():
	"""Clear all building buttons"""
	if not building_buttons_container:
		return
	
	for child in building_buttons_container.get_children():
		child.queue_free()

func create_building_button(building_type: String):
	"""Create a larger, more clickable button for a building type"""
	var building_data = BuildingDatabase.get_building_data(building_type)
	if building_data.is_empty():
		return
	
	# Create button with better minimum size for easier clicking
	var button = Button.new()
	button.custom_minimum_size = Vector2(85, 72)  # Wider and taller for easier clicking
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Create vertical layout for button content
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(vbox)
	
	# Building icon/emoji (add visual distinction)
	var icon_label = Label.new()
	icon_label.text = _get_building_icon(building_type)
	icon_label.add_theme_font_size_override("font_size", 20)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_label)
	
	# Building name (shortened to fit)
	var name_label = Label.new()
	var display_name = building_data.display_name
	# Shorten long names
	if display_name == "Research Building":
		display_name = "Research"
	elif display_name.length() > 12:
		display_name = display_name.substr(0, 10) + ".."
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)
	
	# Cost indicator with time (combined for space)
	var can_afford = ResourceManager.can_afford_cost(building_data.cost) if ResourceManager else false
	var info_label = Label.new()
	var time_text = BuildingDatabase.get_build_time_text(building_type)
	info_label.text = ("✓ %s" % time_text) if can_afford else ("✗ %s" % time_text)
	info_label.add_theme_font_size_override("font_size", 8)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.modulate = Color(0.5, 1.0, 0.5) if can_afford else Color(1.0, 0.5, 0.5)
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(info_label)
	
	# Check zone limit
	var zone_id = ZoneManager.get_unit_zone(selected_builder) if ZoneManager and selected_builder else 1
	var can_build = BuildingDatabase.can_build_in_zone(building_type, zone_id)
	
	if not can_build:
		button.disabled = true
		button.tooltip_text = "Zone limit reached"
	else:
		button.tooltip_text = building_data.description
	
	# Connect button
	button.pressed.connect(_on_building_button_pressed.bind(building_type))
	
	# Add to container
	building_buttons_container.add_child(button)

func _on_building_button_pressed(building_type: String):
	"""Handle building button press - enter placement mode"""
	if is_placement_active:
		return
	
	
	update_status("Click to place building (Right-click to cancel)")
	
	# Enter placement mode
	is_placement_active = true
	start_building_placement(building_type)

func start_building_placement(building_type: String):
	"""Start building placement mode"""
	if not is_instance_valid(selected_builder):
		return
	
	# Get building data
	var building_data = BuildingDatabase.get_building_data(building_type)
	if building_data.is_empty():
		return
	
	# Check resources
	if not ResourceManager or not ResourceManager.can_afford_cost(building_data.cost):
		update_status("Insufficient resources!")
		return
	
	# Check zone limit
	var zone_id = ZoneManager.get_unit_zone(selected_builder) if ZoneManager else 1
	if not BuildingDatabase.can_build_in_zone(building_type, zone_id):
		update_status("Zone limit reached!")
		return
	
	# Don't hide panel - keep it visible during placement
	# visible = false
	
	# Start placement mode
	var game_scene = get_tree().current_scene
	var placement_controller = game_scene.get_node_or_null("Systems/PlacementController")
	
	if placement_controller and placement_controller.has_method("start_placement"):
		# Connect to placement controller to know when placement is done
		if not placement_controller.is_connected("placement_completed", _on_placement_completed):
			if placement_controller.has_signal("placement_completed"):
				placement_controller.placement_completed.connect(_on_placement_completed)
		
		if not placement_controller.is_connected("placement_cancelled", _on_placement_cancelled_signal):
			if placement_controller.has_signal("placement_cancelled"):
				placement_controller.placement_cancelled.connect(_on_placement_cancelled_signal)
		
		placement_controller.start_placement(selected_builder, building_type, building_data)
	else:
		# Fallback: place at builder location
		selected_builder.start_construction(building_type, selected_builder.global_position + Vector2(150, 0))
		update_status("Building construction started")
		is_placement_active = false

func update_status(message: String):
	"""Update status message"""
	if status_label:
		status_label.text = message

func hide_panel():
	"""Hide the panel"""
	visible = false
	selected_builder = null
	is_placement_active = false
	update_status("Select a building to construct")

func _on_placement_completed():
	"""Handle placement completed signal"""
	is_placement_active = false
	update_status("Construction in progress...")

func _on_placement_cancelled_signal():
	"""Handle placement cancelled signal"""
	is_placement_active = false
	update_status("Select a building to construct")

func _get_building_icon(building_type: String) -> String:
	"""Get icon emoji for building type"""
	match building_type:
		"ResearchBuilding":
			return "🔬"
		"BulletTurret":
			return "🔫"
		"LaserTurret":
			return "⚡"
		"MissileTurret":
			return "🚀"
		"ShieldGenerator":
			return "🛡"
		"ResourceExtractor":
			return "⛏"
		"PowerPlant":
			return "⚙"
		_:
			return "🏭"  # Default factory icon
