extends Control

## Loading Scene
## Handles asynchronous loading of the game scene and displays progress

# Scene to load
var target_scene_path: String = "res://scenes/main/GameScene.tscn"
var is_save_game: bool = false

# UI Components
@onready var progress_bar: ProgressBar = $Panel/VBoxContainer/ProgressBar
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var press_key_label: Label = $Panel/VBoxContainer/PressKeyLabel

var _load_status: int = 0
var _progress: Array = []
var _loading_complete: bool = false

func _ready():
	# Initialize UI
	press_key_label.visible = false
	progress_bar.value = 0
	status_label.text = "Initializing..."
	
	# Start background loading
	_start_loading()

func _process(_delta):
	if _loading_complete:
		# Pulse the "Press any key" label
		var alpha = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005)
		press_key_label.modulate.a = alpha
		return
		
	_update_loading_status()

func _input(event):
	if _loading_complete and event is InputEventKey and event.pressed:
		_transition_to_game()

func _start_loading():
	# Request threaded loading
	var error = ResourceLoader.load_threaded_request(target_scene_path)
	if error != OK:
		push_error("Failed to start threaded loading for: " + target_scene_path)
		status_label.text = "Error loading game!"

func _update_loading_status():
	_load_status = ResourceLoader.load_threaded_get_status(target_scene_path, _progress)
	
	match _load_status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			progress_bar.value = _progress[0] * 100
			status_label.text = "Loading resources... %d%%" % int(_progress[0] * 100)
			
		ResourceLoader.THREAD_LOAD_LOADED:
			progress_bar.value = 100
			_on_loading_complete()
			
		ResourceLoader.THREAD_LOAD_FAILED:
			status_label.text = "Loading failed!"
			push_error("Loading failed for: " + target_scene_path)
			
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			status_label.text = "Invalid resource!"
			push_error("Invalid resource: " + target_scene_path)

func _on_loading_complete():
	_loading_complete = true
	status_label.text = "Ready!"
	press_key_label.visible = true
	
	# If it's a save game, we might want to do some pre-processing here if possible,
	# but usually we need the scene tree active.

func _transition_to_game():
	# Get the loaded resource
	var scene_resource = ResourceLoader.load_threaded_get(target_scene_path)
	
	if scene_resource:
		# Change scene
		get_tree().change_scene_to_packed(scene_resource)
		
		# If loading a save, trigger the second phase of loading
		if is_save_game and SaveLoadManager:
			# We need to wait for the scene to be ready, but SaveLoadManager 
			# should handle that via its own logic or signal connection.
			# However, since we are changing scene, the current LoadingScene will be destroyed.
			# SaveLoadManager needs to know it should continue loading.
			SaveLoadManager.continue_loading()
			
		# Clean up loading scene
		queue_free()
