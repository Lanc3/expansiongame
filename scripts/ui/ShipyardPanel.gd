extends PanelContainer
class_name ShipyardPanel

signal closed()

@onready var title_label: Label = $VBox/TitleLabel
@onready var select_blueprint_btn: Button = $VBox/SelectBlueprintBtn
@onready var queue_list: VBoxContainer = $VBox/QueueScroll/QueueList
@onready var progress_bar: ProgressBar = $VBox/ProductionProgress
@onready var progress_label: Label = $VBox/ProgressLabel
@onready var close_btn: Button = $VBox/CloseBtn

var selected_shipyard: Shipyard = null

func _ready():
	select_blueprint_btn.pressed.connect(_on_select_blueprint_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	
	visible = false

func open_for_shipyard(shipyard: Shipyard):
	print("ShipyardPanel: open_for_shipyard() called")
	selected_shipyard = shipyard
	
	if selected_shipyard:
		print("ShipyardPanel: Connecting signals to shipyard")
		selected_shipyard.production_queue_updated.connect(_on_queue_updated)
		selected_shipyard.ship_production_started.connect(_on_production_started)
		selected_shipyard.ship_production_completed.connect(_on_production_completed)
	
	visible = true
	print("ShipyardPanel: Set visible = true, position = ", position, ", size = ", size)
	refresh_ui()

func close_panel():
	if selected_shipyard:
		selected_shipyard.production_queue_updated.disconnect(_on_queue_updated)
		selected_shipyard.ship_production_started.disconnect(_on_production_started)
		selected_shipyard.ship_production_completed.disconnect(_on_production_completed)
		selected_shipyard = null
	
	visible = false
	closed.emit()

func refresh_ui():
	if not selected_shipyard:
		return
	
	var queue_info = selected_shipyard.get_queue_info()
	
	# Update production progress
	if queue_info.is_producing:
		var current = queue_info.current_production
		var bp = current.get("blueprint")
		if bp:
			progress_label.text = "Building: %s" % bp.blueprint_name
			progress_bar.value = queue_info.progress * 100.0
			progress_bar.visible = true
	else:
		progress_label.text = "Idle"
		progress_bar.value = 0.0
		progress_bar.visible = false
	
	# Update queue list
	_rebuild_queue_list(queue_info.queue)

func _rebuild_queue_list(queue: Array):
	# Clear existing queue items
	for child in queue_list.get_children():
		child.queue_free()
	
	# Add queue items
	for i in range(queue.size()):
		var blueprint = queue[i]
		var item = _create_queue_item(blueprint, i)
		queue_list.add_child(item)

func _create_queue_item(blueprint: CosmoteerShipBlueprint, index: int) -> Control:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 40)
	
	# Name label
	var name_label = Label.new()
	name_label.text = "%d. %s" % [index + 1, blueprint.blueprint_name]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)
	
	# Cancel button
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(60, 0)
	cancel_btn.pressed.connect(func(): _on_cancel_queue_item(index))
	hbox.add_child(cancel_btn)
	
	return hbox

func _on_select_blueprint_pressed():
	# Load blueprint library scene at runtime
	var library_scene = load("res://scenes/ui/CosmoteerBlueprintLibrary.tscn")
	if not library_scene:
		push_error("Failed to load CosmoteerBlueprintLibrary scene")
		return
	
	var library = library_scene.instantiate()
	library.blueprint_selected.connect(_on_blueprint_selected)
	get_tree().root.add_child(library)

func _on_blueprint_selected(blueprint: CosmoteerShipBlueprint):
	if selected_shipyard:
		selected_shipyard.add_to_queue(blueprint)

func _on_cancel_queue_item(index: int):
	if selected_shipyard:
		selected_shipyard.cancel_queue_item(index)

func _on_queue_updated():
	refresh_ui()

func _on_production_started(blueprint_name: String):
	refresh_ui()

func _on_production_completed(ship: Node2D):
	refresh_ui()

func _on_close_pressed():
	close_panel()

func _process(_delta: float):
	if visible and selected_shipyard:
		var progress = selected_shipyard.get_production_progress()
		if progress > 0.0:
			progress_bar.value = progress * 100.0
