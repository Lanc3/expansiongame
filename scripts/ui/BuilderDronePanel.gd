extends Panel
## Builder Drone panel - shows buildable structures (matches CommandShipPanel style)

signal building_selected(building_type: String)

@onready var building_buttons_container: HBoxContainer = $VBox/BuildButtonsRow/ButtonScroll/BuildingButtons if has_node("VBox/BuildButtonsRow/ButtonScroll/BuildingButtons") else null
@onready var status_label: Label = $VBox/InfoRow/StatusLabel if has_node("VBox/InfoRow/StatusLabel") else null

var selected_builder: BuilderDrone = null
var is_placement_active: bool = false

func _ready():
	visible = false
	
	# Ensure panel blocks input to game world
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	print("BuilderDronePanel: Ready")

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
	"""Create a compact button for a building type"""
	var building_data = BuildingDatabase.get_building_data(building_type)
	if building_data.is_empty():
		return
	
	# Create button similar to CompactProductionButton
	var button = Button.new()
	button.custom_minimum_size = Vector2(100, 0)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Create vertical layout for button content
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(vbox)
	
	# Building name (shortened)
	var name_label = Label.new()
	name_label.text = building_data.display_name
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)
	
	# Build time
	var time_label = Label.new()
	time_label.text = BuildingDatabase.get_build_time_text(building_type)
	time_label.add_theme_font_size_override("font_size", 8)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.modulate = Color(0.7, 0.7, 0.7)
	time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(time_label)
	
	# Cost indicator (just show if affordable)
	var can_afford = ResourceManager.can_afford_cost(building_data.cost) if ResourceManager else false
	var cost_label = Label.new()
	cost_label.text = "✓" if can_afford else "✗"
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.modulate = Color(0.5, 1.0, 0.5) if can_afford else Color(1.0, 0.5, 0.5)
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cost_label)
	
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
		print("BuilderDronePanel: Placement already active, ignoring button press")
		return
	
	print("BuilderDronePanel: Building selected: %s" % building_type)
	
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
		print("BuilderDronePanel: Insufficient resources")
		update_status("Insufficient resources!")
		return
	
	# Check zone limit
	var zone_id = ZoneManager.get_unit_zone(selected_builder) if ZoneManager else 1
	if not BuildingDatabase.can_build_in_zone(building_type, zone_id):
		print("BuilderDronePanel: Cannot build more in this zone")
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
		print("BuilderDronePanel: PlacementController not found, placing at builder location")
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
	print("BuilderDronePanel: Placement completed, resetting state")
	is_placement_active = false
	update_status("Construction in progress...")

func _on_placement_cancelled_signal():
	"""Handle placement cancelled signal"""
	print("BuilderDronePanel: Placement cancelled, resetting state")
	is_placement_active = false
	update_status("Select a building to construct")
