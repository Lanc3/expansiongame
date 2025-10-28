extends PanelContainer
class_name ShipWeaponPanel
## UI panel for controlling ship weapons

signal weapon_toggled(weapon_index: int, enabled: bool)

var current_ship: Node2D = null
var weapon_buttons: Array[CheckButton] = []

func _ready():
	custom_minimum_size = Vector2(250, 150)
	size = Vector2(250, 150)
	visible = false
	z_index = 50
	
	# Position in bottom right
	position = Vector2(get_viewport().size.x - 270, get_viewport().size.y - 170)

func show_for_ship(ship: Node2D):
	"""Display weapon controls for a ship"""
	if not ship or not ship.has_method("get_weapon_count"):
		hide()
		return
	
	current_ship = ship
	_rebuild_ui()
	visible = true

func _rebuild_ui():
	"""Rebuild the weapon control UI"""
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	weapon_buttons.clear()
	
	if not current_ship:
		return
	
	# Create VBox container
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Weapon Systems"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	# Get weapon count
	var weapon_count = current_ship.get_weapon_count()
	
	if weapon_count == 0:
		var no_weapons = Label.new()
		no_weapons.text = "No weapons installed"
		no_weapons.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(no_weapons)
		return
	
	# Weapon list in scroll container
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 80)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var weapon_list = VBoxContainer.new()
	scroll.add_child(weapon_list)
	
	# Add controls for each weapon
	for i in range(weapon_count):
		var weapon_hbox = HBoxContainer.new()
		
		# Toggle button
		var toggle = CheckButton.new()
		toggle.text = "Weapon %d" % (i + 1)
		toggle.button_pressed = true  # Default enabled
		toggle.toggled.connect(_on_weapon_toggled.bind(i))
		weapon_hbox.add_child(toggle)
		weapon_buttons.append(toggle)
		
		# Get weapon info from ship
		if current_ship.has_method("get_weapon_info"):
			var info = current_ship.get_weapon_info(i)
			if not info.is_empty():
				var type_label = Label.new()
				type_label.text = info.get("type", "")
				type_label.add_theme_font_size_override("font_size", 10)
				weapon_hbox.add_child(type_label)
		
		weapon_list.add_child(weapon_hbox)
	
	# Control buttons
	vbox.add_child(HSeparator.new())
	
	var button_hbox = HBoxContainer.new()
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var enable_all = Button.new()
	enable_all.text = "Enable All"
	enable_all.pressed.connect(_on_enable_all_pressed)
	button_hbox.add_child(enable_all)
	
	var disable_all = Button.new()
	disable_all.text = "Disable All"
	disable_all.pressed.connect(_on_disable_all_pressed)
	button_hbox.add_child(disable_all)
	
	vbox.add_child(button_hbox)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(_on_close_pressed)
	vbox.add_child(close_btn)

func _on_weapon_toggled(enabled: bool, weapon_index: int):
	"""Handle weapon toggle"""
	if current_ship and current_ship.has_method("toggle_weapon"):
		current_ship.toggle_weapon(weapon_index, enabled)
		weapon_toggled.emit(weapon_index, enabled)

func _on_enable_all_pressed():
	"""Enable all weapons"""
	for i in range(weapon_buttons.size()):
		weapon_buttons[i].button_pressed = true
		if current_ship and current_ship.has_method("toggle_weapon"):
			current_ship.toggle_weapon(i, true)

func _on_disable_all_pressed():
	"""Disable all weapons"""
	for i in range(weapon_buttons.size()):
		weapon_buttons[i].button_pressed = false
		if current_ship and current_ship.has_method("toggle_weapon"):
			current_ship.toggle_weapon(i, false)

func _on_close_pressed():
	"""Close the panel"""
	hide()
	current_ship = null


