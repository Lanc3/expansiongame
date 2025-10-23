extends Node
## Manages game audio including music and sound effects

var sound_effects: Dictionary = {}
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.8

# Movement sound cooldown tracking
var move_sound_cooldown: Dictionary = {}  # Track last move sound per unit
const MOVE_SOUND_COOLDOWN_TIME: float = 0.5

# Spatial audio settings
const MAX_AUDIO_DISTANCE: float = 2000.0  # Max distance where sound is audible
const MIN_AUDIO_DISTANCE: float = 100.0   # Distance where sound is at full volume
const AUDIO_FALLOFF_EXPONENT: float = 2.0  # How quickly sound fades (1.0=linear, 2.0=realistic)

func _ready():
	# Create audio players first
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	
	music_player.name = "MusicPlayer"
	sfx_player.name = "SFXPlayer"
	
	add_child(music_player)
	add_child(sfx_player)
	
	# Load settings and apply volumes
	load_settings()
	
	# Set initial volumes (in case load_settings didn't find a file)
	music_player.volume_db = linear_to_db(music_volume)
	sfx_player.volume_db = linear_to_db(sfx_volume)
	
	# Load common sound effects
	load_sound_effects()
	
	# Start background music automatically (deferred to allow scene to load)
	call_deferred("start_background_music")

func load_sound_effects():
	# Load sound effects from Assets/Audio folder
	var audio_files = [
		"move_command",
		"attack_command", 
		"mine_command",
		"unit_selected",
		"unit_died",
		"explosion",
		"mining_sound",
		"weapon_fire",
		"button_click",
		"error_sound"
	]
	
	for sound_name in audio_files:
		var sound_path = "res://Assets/Audio/" + sound_name + ".wav"
		if FileAccess.file_exists(sound_path):
			var audio_stream = load(sound_path)
			if audio_stream:
				sound_effects[sound_name] = audio_stream

func play_sound(sound_name: String, pitch_scale: float = 1.0):
	if sound_name in sound_effects:
		sfx_player.stream = sound_effects[sound_name]
		sfx_player.pitch_scale = pitch_scale
		sfx_player.play()
	else:
		# Don't print error for optional/missing sounds, just skip silently
		pass

func play_music(music_stream: AudioStream, fade_in: bool = true):
	if not music_stream:
		return
	
	music_player.stream = music_stream
	
	if fade_in:
		music_player.volume_db = -80.0  # Start silent
		music_player.play()
		
		# Fade in music
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), 1.0)
	else:
		music_player.volume_db = linear_to_db(music_volume)
		music_player.play()

func stop_music(fade_out: bool = true):
	if fade_out and music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, 1.0)
		tween.tween_callback(music_player.stop)
	else:
		music_player.stop()

func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	if music_player:
		music_player.volume_db = linear_to_db(music_volume)

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	if sfx_player:
		sfx_player.volume_db = linear_to_db(sfx_volume)

func get_master_volume() -> float:
	return master_volume

func get_music_volume() -> float:
	return music_volume

func get_sfx_volume() -> float:
	return sfx_volume

func start_background_music():
	"""Start looping background music"""
	var music = load("res://assets/audio/ambient background music.mp3")
	if music:
		music_player.stream = music
		music_player.volume_db = linear_to_db(music_volume)
		music_player.play()
		# Note: AudioStreamMP3 doesn't have a loop property in Godot 4
		# Use finished signal to restart
		if not music_player.finished.is_connected(_on_music_finished):
			music_player.finished.connect(_on_music_finished)
		print("AudioManager: Started background music")

func _on_music_finished():
	"""Restart background music when it finishes (manual looping)"""
	if music_player.stream:
		music_player.play()

func play_weapon_sound(world_position: Vector2 = Vector2.ZERO):
	"""Play weapon firing sound with spatial audio"""
	var sound = load("res://assets/audio/weapon shound.wav")
	if sound:
		# Use separate player for weapon sounds to allow multiple simultaneous shots
		var weapon_player = AudioStreamPlayer.new()
		add_child(weapon_player)
		weapon_player.stream = sound
		
		# Calculate spatial volume
		var base_volume = linear_to_db(sfx_volume)
		if world_position != Vector2.ZERO:
			weapon_player.volume_db = calculate_spatial_volume(world_position, base_volume)
		else:
			weapon_player.volume_db = base_volume
		
		weapon_player.play()
		weapon_player.finished.connect(func(): weapon_player.queue_free())

func play_ship_move_sound(unit: Node2D):
	"""Play ship movement sound with cooldown and spatial audio"""
	if not unit:
		return
	
	# Cooldown check
	var current_time = Time.get_ticks_msec()
	if unit in move_sound_cooldown:
		if current_time - move_sound_cooldown[unit] < MOVE_SOUND_COOLDOWN_TIME * 1000:
			return  # Still on cooldown
	
	move_sound_cooldown[unit] = current_time
	
	var sound = load("res://assets/audio/ship_start_move_sound.wav")
	if sound:
		# Create one-shot player for movement sounds
		var move_player = AudioStreamPlayer.new()
		add_child(move_player)
		move_player.stream = sound
		
		# Calculate spatial volume based on unit position
		var base_volume = linear_to_db(sfx_volume)
		move_player.volume_db = calculate_spatial_volume(unit.global_position, base_volume)
		
		move_player.play()
		move_player.finished.connect(func(): move_player.queue_free())

func play_ui_hover_sound():
	"""Play UI button hover sound"""
	var sound = load("res://assets/audio/ui-onhover.mp3")
	if sound:
		var ui_player = AudioStreamPlayer.new()
		add_child(ui_player)
		ui_player.stream = sound
		ui_player.volume_db = linear_to_db(sfx_volume) - 5.0  # Slightly quieter
		ui_player.play()
		ui_player.finished.connect(func(): ui_player.queue_free())

func play_ui_click_sound():
	"""Play UI button click sound"""
	var sound = load("res://assets/audio/ui-clicked.mp3")
	if sound:
		var ui_player = AudioStreamPlayer.new()
		add_child(ui_player)
		ui_player.stream = sound
		ui_player.volume_db = linear_to_db(sfx_volume)
		ui_player.play()
		ui_player.finished.connect(func(): ui_player.queue_free())

func calculate_spatial_volume(world_position: Vector2, base_volume_db: float) -> float:
	"""Calculate volume based on distance from camera"""
	# Get camera
	var viewport = get_viewport()
	var camera = viewport.get_camera_2d() if viewport else null
	if not camera:
		return base_volume_db  # No camera, use base volume
	
	# Calculate distance from camera to sound source
	var distance = camera.global_position.distance_to(world_position)
	
	# If within min distance, use full volume
	if distance <= MIN_AUDIO_DISTANCE:
		return base_volume_db
	
	# If beyond max distance, mute completely
	if distance >= MAX_AUDIO_DISTANCE:
		return -80.0  # Effectively muted
	
	# Calculate attenuation based on distance
	var distance_ratio = (distance - MIN_AUDIO_DISTANCE) / (MAX_AUDIO_DISTANCE - MIN_AUDIO_DISTANCE)
	distance_ratio = clamp(distance_ratio, 0.0, 1.0)
	
	# Apply exponential falloff for realistic audio
	var attenuation_factor = pow(1.0 - distance_ratio, AUDIO_FALLOFF_EXPONENT)
	
	# Convert to decibels (attenuate up to -40dB at max distance)
	var attenuation_db = linear_to_db(attenuation_factor)
	
	return base_volume_db + attenuation_db

func save_settings():
	"""Save audio settings to disk"""
	var settings = {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume
	}
	
	var file = FileAccess.open("user://audio_settings.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings, "\t"))
		file.close()
		print("AudioManager: Settings saved")

func load_settings():
	"""Load audio settings from disk"""
	if FileAccess.file_exists("user://audio_settings.json"):
		var file = FileAccess.open("user://audio_settings.json", FileAccess.READ)
		if file:
			var json = JSON.new()
			var parse_result = json.parse(file.get_as_text())
			file.close()
			
			if parse_result == OK:
				var settings = json.data
				if settings:
					set_master_volume(settings.get("master_volume", 1.0))
					set_music_volume(settings.get("music_volume", 0.7))
					set_sfx_volume(settings.get("sfx_volume", 0.8))
					print("AudioManager: Settings loaded")
			else:
				print("AudioManager: Failed to parse settings file")
	else:
		print("AudioManager: No settings file found, using defaults")
