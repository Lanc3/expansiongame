extends Node
## Automatically adds hover and click sounds to all buttons in the scene tree

func _ready():
	# Wait for scene to fully load
	await get_tree().process_frame
	
	# Connect to scene tree changes to catch dynamically created buttons
	get_tree().node_added.connect(_on_node_added)
	
	# Apply sounds to existing buttons
	apply_sounds_to_all_buttons()

func _on_node_added(node: Node):
	"""Handle newly added nodes"""
	if node is Button:
		# Small delay to ensure button is fully initialized
		call_deferred("apply_sounds_to_button", node)

func apply_sounds_to_all_buttons():
	"""Find and apply sounds to all existing buttons"""
	var root = get_tree().root
	var all_buttons = _find_all_buttons(root)
	
	for button in all_buttons:
		if is_instance_valid(button):
			apply_sounds_to_button(button)
	
	print("ButtonSoundHelper: Applied sounds to %d buttons" % all_buttons.size())

func _find_all_buttons(node: Node) -> Array:
	"""Recursively find all Button nodes"""
	var buttons = []
	
	if node is Button:
		buttons.append(node)
	
	for child in node.get_children():
		buttons.append_array(_find_all_buttons(child))
	
	return buttons

func apply_sounds_to_button(button: Button):
	"""Apply hover and click sounds to a button"""
	if not is_instance_valid(button):
		return
	
	# Avoid duplicate connections
	if button.has_meta("sounds_applied"):
		return
	
	# Connect hover sound
	if not button.mouse_entered.is_connected(_on_button_hover):
		button.mouse_entered.connect(_on_button_hover.bind(button))
	
	# Connect click sound (deferred to play after button logic)
	if not button.pressed.is_connected(_on_button_clicked):
		button.pressed.connect(_on_button_clicked.bind(button), CONNECT_DEFERRED)
	
	# Mark as processed
	button.set_meta("sounds_applied", true)

func _on_button_hover(_button: Button):
	"""Play hover sound when mouse enters button"""
	if AudioManager:
		AudioManager.play_ui_hover_sound()

func _on_button_clicked(_button: Button):
	"""Play click sound when button is pressed"""
	if AudioManager:
		AudioManager.play_ui_click_sound()

