extends ColorRect
class_name ResourceSlot

## Compact 25×25px resource display with pin functionality

@onready var pin_button: Button = $VBox/TopRow/PinButton
@onready var acronym_label: Label = $VBox/AcronymLabel
@onready var count_label: Label = $VBox/CountLabel

var resource_id: int = 0
var resource_data: Dictionary = {}
var current_count: int = 0
var base_color: Color = Color.WHITE

func _ready():
	if pin_button:
		pin_button.pressed.connect(_on_pin_pressed)

func setup(res_id: int, res_data: Dictionary):
	resource_id = res_id
	resource_data = res_data
	base_color = res_data.color
	
	# Set background color to resource color
	color = base_color
	
	if acronym_label:
		acronym_label.text = generate_3letter_acronym(res_data.name)
	
	tooltip_text = "%s (Tier %d)\nValue: %.1f" % [res_data.name, res_data.tier, res_data.value]
	
	update_count(0)
	update_pin_display()
	
	# Connect to pin manager
	if ResourcePinManager and not ResourcePinManager.pins_changed.is_connected(_on_pins_changed):
		ResourcePinManager.pins_changed.connect(_on_pins_changed)

func update_count(count: int):
	current_count = count
	
	if count_label:
		if count > 999:
			count_label.text = "999+"
		else:
			count_label.text = str(count)
	
	# Dim if zero, full color if has resources
	if count == 0:
		modulate = Color(0.4, 0.4, 0.4, 0.7)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func update_pin_display():
	if pin_button:
		if ResourcePinManager and ResourcePinManager.is_pinned(resource_id):
			pin_button.text = "⭐"
			pin_button.modulate = Color(1, 1, 0.5, 1)
		else:
			pin_button.text = "☆"
			pin_button.modulate = Color(1, 1, 1, 0.8)

func _on_pin_pressed():
	if ResourcePinManager:
		ResourcePinManager.toggle_pin(resource_id)

func _on_pins_changed():
	update_pin_display()

func generate_3letter_acronym(name: String) -> String:
	var words = name.split(" ")
	var result = ""
	
	if words.size() >= 3:
		result = words[0][0] + words[1][0] + words[2][0]
	elif words.size() == 2:
		result = words[0][0] + words[1].substr(0, 2)
	else:
		result = name.substr(0, min(3, name.length()))
	
	return result.to_upper()
