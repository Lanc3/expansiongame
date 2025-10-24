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
	
	# Set contrasting text color for readability
	var text_color = get_contrasting_text_color(base_color)
	if acronym_label:
		acronym_label.add_theme_color_override("font_color", text_color)
	if count_label:
		count_label.add_theme_color_override("font_color", text_color)
	if pin_button:
		pin_button.add_theme_color_override("font_color", text_color)
	
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
		count_label.text = format_compact_number(count)
	
	# Dim if zero, full color if has resources
	if count == 0:
		modulate = Color(0.4, 0.4, 0.4, 0.7)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func update_pin_display():
	if pin_button:
		if ResourcePinManager and ResourcePinManager.is_pinned(resource_id):
			pin_button.text = "⭐"
		else:
			pin_button.text = "☆"

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

func get_contrasting_text_color(bg_color: Color) -> Color:
	# Calculate perceived luminance (0.0 to 1.0)
	var luminance = (0.299 * bg_color.r) + (0.587 * bg_color.g) + (0.114 * bg_color.b)
	# Return black for bright backgrounds, white for dark backgrounds
	if luminance > 0.5:
		return Color.BLACK
	else:
		return Color.WHITE

func format_compact_number(n: int) -> String:
	var value := float(n)
	var suffix := ""
	if n >= 1000000000:
		value = value / 1000000000.0
		suffix = "b"
	elif n >= 1000000:
		value = value / 1000000.0
		suffix = "m"
	elif n >= 1000:
		value = value / 1000.0
		suffix = "k"
	var s := ("%.1f" % value) if suffix != "" else str(n)
	if s.ends_with(".0"):
		s = s.substr(0, s.length() - 2)
	return s + suffix
