extends Node
## Global game state manager - handles time, pausing, and scene management

signal game_paused
signal game_resumed
signal scene_changed(scene_name: String)

var game_time: float = 0.0
var game_paused_bool: bool = false
var current_zone: Dictionary = {
	"id": 0,
	"name": "Starting Sector",
	"visited": true
}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float):
	if not game_paused_bool:
		game_time += delta

func pause_game():
	if not game_paused_bool:
		game_paused_bool = true
		get_tree().paused = true
		game_paused.emit()

func resume_game():
	if game_paused_bool:
		game_paused_bool = false
		get_tree().paused = false
		game_resumed.emit()

func toggle_pause():
	if game_paused_bool:
		resume_game()
	else:
		pause_game()

func reset_game():
	"""Reset all game state for starting fresh"""
	game_time = 0.0
	game_paused_bool = false
	get_tree().paused = false
	
	# Clear SaveLoadManager flag
	if SaveLoadManager:
		SaveLoadManager.is_loading_save = false
	
	# Clear EntityManager registrations
	if EntityManager:
		EntityManager.clear_all()
	
	# Clear SelectionManager
	if SelectionManager:
		SelectionManager.clear_selection()
	
	# Clear ZoneManager state
	if ZoneManager:
		ZoneManager.reset()
	
	# Clear FogOfWarManager state
	if FogOfWarManager:
		FogOfWarManager.reset()
func get_game_time_formatted() -> String:
	var minutes = int(game_time / 60)
	var seconds = int(game_time) % 60
	return "%02d:%02d" % [minutes, seconds]

func reset_game_time():
	game_time = 0.0
	
func change_scene(scene_path: String):
	scene_changed.emit(scene_path)
	get_tree().change_scene_to_file(scene_path)
