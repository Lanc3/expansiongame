extends Control
## In-game pause menu with glass-morphism design

signal resume_requested
signal save_requested
signal load_requested

@onready var background_overlay: ColorRect = $BackgroundOverlay
@onready var menu_panel: Panel = $MenuPanel
@onready var resume_button: Button = $MenuPanel/VBoxContainer/ResumeButton
@onready var save_button: Button = $MenuPanel/VBoxContainer/SaveButton
@onready var load_button: Button = $MenuPanel/VBoxContainer/LoadButton
@onready var quit_menu_button: Button = $MenuPanel/VBoxContainer/QuitMenuButton
@onready var quit_desktop_button: Button = $MenuPanel/VBoxContainer/QuitDesktopButton
@onready var status_label: Label = $MenuPanel/VBoxContainer/StatusLabel

var tween: Tween

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	quit_menu_button.pressed.connect(_on_quit_menu_pressed)
	quit_desktop_button.pressed.connect(_on_quit_desktop_pressed)
	
	# Setup initial state
	status_label.text = ""
	status_label.modulate = Color.TRANSPARENT

func show_menu():
	"""Show the pause menu with fade-in animation"""
	visible = true
	GameManager.pause_game()
	
	# Animate fade-in
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	
	background_overlay.modulate = Color.TRANSPARENT
	menu_panel.modulate = Color.TRANSPARENT
	menu_panel.scale = Vector2(0.9, 0.9)
	
	tween.tween_property(background_overlay, "modulate", Color.WHITE, 0.2)
	tween.tween_property(menu_panel, "modulate", Color.WHITE, 0.25)
	tween.tween_property(menu_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Play sound
	if AudioManager.has_method("play_ui_sound"):
		AudioManager.play_ui_sound("menu_open")

func hide_menu():
	"""Hide the pause menu with fade-out animation"""
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(background_overlay, "modulate", Color.TRANSPARENT, 0.15)
	tween.tween_property(menu_panel, "modulate", Color.TRANSPARENT, 0.15)
	tween.tween_property(menu_panel, "scale", Vector2(0.95, 0.95), 0.15)
	
	await tween.finished
	visible = false
	GameManager.resume_game()
	
	# Play sound
	if AudioManager.has_method("play_ui_sound"):
		AudioManager.play_ui_sound("menu_close")

func _on_resume_pressed():
	"""Resume the game"""
	hide_menu()

func _on_save_pressed():
	"""Save the game"""
	status_label.text = "Saving..."
	status_label.modulate = Color.WHITE
	
	var success = await SaveLoadManager.save_game()
	
	if success:
		status_label.text = "Game saved successfully!"
		status_label.add_theme_color_override("font_color", Color.GREEN)
		# Play success sound
		if AudioManager.has_method("play_ui_sound"):
			AudioManager.play_ui_sound("save_success")
	else:
		status_label.text = "Save failed!"
		status_label.add_theme_color_override("font_color", Color.RED)
		# Play error sound
		if AudioManager.has_method("play_ui_sound"):
			AudioManager.play_ui_sound("error")
	
	# Fade out status after 2 seconds
	await get_tree().create_timer(2.0).timeout
	var fade_tween = create_tween()
	fade_tween.tween_property(status_label, "modulate", Color.TRANSPARENT, 0.5)

func _on_load_pressed():
	"""Load the most recent save"""
	status_label.text = "Loading..."
	status_label.modulate = Color.WHITE
	
	var success = await SaveLoadManager.load_game()
	
	if success:
		# Game will reload, no need for status message
		hide_menu()
	else:
		status_label.text = "No save file found!"
		status_label.add_theme_color_override("font_color", Color.RED)
		# Play error sound
		if AudioManager.has_method("play_ui_sound"):
			AudioManager.play_ui_sound("error")
		
		# Fade out status after 2 seconds
		await get_tree().create_timer(2.0).timeout
		var fade_tween = create_tween()
		fade_tween.tween_property(status_label, "modulate", Color.TRANSPARENT, 0.5)

func _on_quit_menu_pressed():
	"""Quit to main menu"""
	GameManager.reset_game()
	get_tree().paused = false
	GameManager.change_scene("res://scenes/main/MainMenu.tscn")

func _on_quit_desktop_pressed():
	"""Quit to desktop"""
	get_tree().quit()

func _input(event: InputEvent):
	"""Handle ESC key to close menu"""
	if visible and event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_resume_pressed()
			accept_event()

