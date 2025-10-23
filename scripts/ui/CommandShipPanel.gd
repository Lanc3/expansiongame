extends Panel
## Command Ship production panel - compact side panel showing buildable units and build queue

@onready var unit_buttons_container: HBoxContainer = $VBox/BuildButtonsRow/ButtonScroll/UnitButtons if has_node("VBox/BuildButtonsRow/ButtonScroll/UnitButtons") else null
@onready var queue_container: HBoxContainer = $VBox/QueueRow/QueueScroll/QueueList if has_node("VBox/QueueRow/QueueScroll/QueueList") else null

var command_ship: Node2D = null
var unit_button_scene: PackedScene
var queue_item_scene: PackedScene
var update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.1  # Update UI every 0.1 seconds

func _ready():
	# Use compact button scene
	unit_button_scene = preload("res://scenes/ui/CompactProductionButton.tscn")
	queue_item_scene = preload("res://scenes/ui/QueueItem.tscn")
	
	visible = false
	
	# Ensure panel blocks input to game world
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(delta: float):
	if not visible or not is_instance_valid(command_ship):
		return
	
	# Update UI periodically
	update_timer += delta
	if update_timer >= UPDATE_INTERVAL:
		update_timer = 0.0
		update_queue_display()

func show_for_command_ship(ship: Node2D):
	"""Display panel for the given command ship"""
	if not is_instance_valid(ship):
		return
	
	command_ship = ship
	visible = true
	
	# Connect to ship signals
	if command_ship.queue_updated.is_connected(_on_queue_updated):
		command_ship.queue_updated.disconnect(_on_queue_updated)
	command_ship.queue_updated.connect(_on_queue_updated)
	
	rebuild_ui()

func rebuild_ui():
	"""Rebuild the entire UI"""
	clear_unit_buttons()
	build_unit_buttons()
	update_queue_display()

func clear_unit_buttons():
	"""Clear all unit buttons"""
	if not unit_buttons_container:
		return
	
	for child in unit_buttons_container.get_children():
		child.queue_free()

func build_unit_buttons():
	"""Create unit build buttons"""
	if not unit_buttons_container:
		return
	
	var buildable_units = UnitProductionDatabase.get_all_buildable_units()
	
	for unit_type in buildable_units:
		var data = UnitProductionDatabase.get_production_data(unit_type)
		var button = unit_button_scene.instantiate()
		
		unit_buttons_container.add_child(button)
		
		# Setup button with data
		if button.has_method("setup"):
			button.setup(unit_type, data, command_ship)
		
		# Connect build request signal
		if button.has_signal("build_requested"):
			if button.build_requested.is_connected(_on_build_requested):
				button.build_requested.disconnect(_on_build_requested)
			button.build_requested.connect(_on_build_requested)

func update_queue_display():
	"""Update the build queue display with aggregated items"""
	if not queue_container or not is_instance_valid(command_ship):
		return
	
	# Clear queue display
	for child in queue_container.get_children():
		child.queue_free()
	
	# First, show current production if any
	if command_ship.is_producing and not command_ship.current_production.is_empty():
		var order = command_ship.current_production
		create_queue_item(order, -1, 1, true)
	
	# Aggregate queue items by type
	var aggregated = {}
	for i in range(command_ship.production_queue.size()):
		var order = command_ship.production_queue[i]
		var unit_type = order.unit_type
		
		if unit_type in aggregated:
			aggregated[unit_type].count += 1
			aggregated[unit_type].indices.append(i)
		else:
			aggregated[unit_type] = {
				"order": order,
				"count": 1,
				"first_index": i,
				"indices": [i]
			}
	
	# Show aggregated queue items
	for unit_type in aggregated:
		var data = aggregated[unit_type]
		create_queue_item(data.order, data.first_index, data.count, false)

func create_queue_item(order: Dictionary, index: int, count: int, is_current: bool):
	"""Create a queue item display"""
	if not queue_container:
		return
	
	var item = queue_item_scene.instantiate()
	queue_container.add_child(item)
	
	if item.has_method("setup"):
		item.setup(order, index, command_ship, count)

func _on_build_requested(unit_type: String):
	"""Handle build button press"""
	if is_instance_valid(command_ship) and command_ship.has_method("add_to_queue"):
		var success = command_ship.add_to_queue(unit_type)
		if success:
			# UI will update via signal
			pass

func _on_queue_updated():
	"""Handle queue update from command ship"""
	update_queue_display()

