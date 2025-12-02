extends Control
## Main menu scene

@onready var start_button: Button = $MenuPanel/VBoxContainer/StartButton
@onready var load_button: Button = $MenuPanel/VBoxContainer/LoadButton
@onready var blueprint_button: Button = $MenuPanel/VBoxContainer/BlueprintButton
@onready var settings_button: Button = $MenuPanel/VBoxContainer/SettingsButton
@onready var quit_button: Button = $MenuPanel/VBoxContainer/QuitButton
@onready var title_label: Label = $MenuPanel/VBoxContainer/TitleLabel

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
	var loading_scene = preload("res://scenes/ui/LoadingScene.tscn").instantiate()
	loading_scene.target_scene_path = "res://scenes/main/GameScene.tscn"
	loading_scene.is_save_game = false
	get_tree().root.add_child(loading_scene)
	# We don't queue_free MainMenu immediately, the LoadingScene covers it
	# and switching scene will destroy the whole tree anyway if using change_scene
	# But LoadingScene uses change_scene_to_packed, so we should probably just let it handle it.
	# However, LoadingScene is added to root, so it persists until it changes the scene.

func _on_load_pressed():
	"""Load saved game"""
	if SaveLoadManager.prepare_load():
		var loading_scene = preload("res://scenes/ui/LoadingScene.tscn").instantiate()
		loading_scene.target_scene_path = "res://scenes/main/GameScene.tscn"
		loading_scene.is_save_game = true
		get_tree().root.add_child(loading_scene)
	else:
		# Show error feedback if load fails
		load_button.disabled = true
		load_button.text = "Load Failed"

func _on_blueprint_pressed():
	# Open Cosmoteer-style ship builder
	var builder = preload("res://scenes/ui/CosmoteerShipBuilderUI.tscn").instantiate()
	get_tree().root.add_child(builder)

func _on_settings_pressed():
	# Open settings panel
	var settings = preload("res://scenes/ui/SettingsMenu.tscn").instantiate()
	add_child(settings)
	settings.show_settings()
	settings.closed.connect(func(): settings.queue_free())

func _on_quit_pressed():
	get_tree().quit()
