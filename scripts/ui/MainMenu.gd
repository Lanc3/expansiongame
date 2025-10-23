extends Control
## Main menu scene

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var load_button: Button = $VBoxContainer/LoadButton
@onready var blueprint_button: Button = $VBoxContainer/BlueprintButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $VBoxContainer/TitleLabel

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	blueprint_button.pressed.connect(_on_blueprint_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Enable/disable load button based on save file existence
	_update_load_button_state()

func _update_load_button_state():
	"""Update load button enabled state based on save file existence"""
	if SaveLoadManager.has_save_file():
		load_button.disabled = false
		load_button.tooltip_text = "Load your saved game"
	else:
		load_button.disabled = true
		load_button.tooltip_text = "No saved game found"

func _on_start_pressed():
	GameManager.change_scene("res://scenes/main/GameScene.tscn")

func _on_load_pressed():
	"""Load saved game"""
	SaveLoadManager.load_game()

func _on_blueprint_pressed():
	# Could open blueprint editor in menu mode
	# For now, just start game with editor open
	GameManager.change_scene("res://scenes/main/GameScene.tscn")

func _on_settings_pressed():
	# Open settings panel (implement later)
	print("Settings button pressed")

func _on_quit_pressed():
	get_tree().quit()
