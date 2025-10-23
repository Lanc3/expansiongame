extends PanelContainer
## Display for individual item in production queue

@onready var icon_rect: TextureRect = $VBox/TopRow/IconRect if has_node("VBox/TopRow/IconRect") else null
@onready var name_label: Label = $VBox/TopRow/NameLabel if has_node("VBox/TopRow/NameLabel") else null
@onready var count_label: Label = $VBox/TopRow/CountLabel if has_node("VBox/TopRow/CountLabel") else null
@onready var progress_bar: ProgressBar = $VBox/ProgressBar if has_node("VBox/ProgressBar") else null
@onready var eta_label: Label = $VBox/ETALabel if has_node("VBox/ETALabel") else null
@onready var cancel_button: Button = $VBox/TopRow/CancelButton if has_node("VBox/TopRow/CancelButton") else null

var queue_index: int = -1
var command_ship: Node2D = null
var unit_count: int = 1

func _ready():
	# Ensure this item blocks input
	mouse_filter = Control.MOUSE_FILTER_STOP

func setup(order: Dictionary, index: int, ship: Node2D, count: int = 1):
	"""Setup queue item with order data"""
	queue_index = index
	command_ship = ship
	unit_count = count
	
	var data = UnitProductionDatabase.get_production_data(order.unit_type)
	
	# Set icon
	if icon_rect:
		var icon_path = data.get("icon_path", "")
		if icon_path != "":
			var texture = load(icon_path)
			if texture:
				icon_rect.texture = texture
	
	# Set name (compact - remove "Drone" suffix)
	if name_label:
		var display_name = data.get("display_name", order.unit_type)
		display_name = display_name.replace(" Drone", "")
		name_label.text = display_name
	
	# Set count
	if count_label:
		if count > 1:
			count_label.text = "x%d" % count
			count_label.visible = true
		else:
			count_label.visible = false
	
	# Set progress
	if progress_bar:
		progress_bar.value = order.get("progress", 0.0) * 100.0
	
	# Set ETA
	if eta_label:
		var remaining = order.build_time * (1.0 - order.get("progress", 0.0))
		eta_label.text = "%.1fs" % remaining
	
	# Connect cancel button
	if cancel_button:
		if cancel_button.pressed.is_connected(_on_cancel_pressed):
			cancel_button.pressed.disconnect(_on_cancel_pressed)
		cancel_button.pressed.connect(_on_cancel_pressed)

func _on_cancel_pressed():
	"""Handle cancel button press"""
	if is_instance_valid(command_ship) and command_ship.has_method("cancel_production"):
		command_ship.cancel_production(queue_index)

