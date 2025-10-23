extends Node
## Manages game audio including music and sound effects

var sound_effects: Dictionary = {}
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.8

func _ready():
	# Create audio players
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	
	music_player.name = "MusicPlayer"
	sfx_player.name = "SFXPlayer"
	
	add_child(music_player)
	add_child(sfx_player)
	
	# Set initial volumes
	music_player.volume_db = linear_to_db(music_volume)
	sfx_player.volume_db = linear_to_db(sfx_volume)
	
	# Load common sound effects
	load_sound_effects()

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
	music_player.volume_db = linear_to_db(music_volume)

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	sfx_player.volume_db = linear_to_db(sfx_volume)

func get_master_volume() -> float:
	return master_volume

func get_music_volume() -> float:
	return music_volume

func get_sfx_volume() -> float:
	return sfx_volume
