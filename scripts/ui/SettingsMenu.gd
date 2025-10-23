extends Control
## Settings menu with volume controls

signal closed

@onready var master_slider: HSlider = $SettingsPanel/VBoxContainer/MasterVolumeSection/HBox/MasterSlider
@onready var music_slider: HSlider = $SettingsPanel/VBoxContainer/MusicVolumeSection/HBox/MusicSlider
@onready var sfx_slider: HSlider = $SettingsPanel/VBoxContainer/SFXVolumeSection/HBox/SFXSlider
@onready var master_value_label: Label = $SettingsPanel/VBoxContainer/MasterVolumeSection/HBox/ValueLabel
@onready var music_value_label: Label = $SettingsPanel/VBoxContainer/MusicVolumeSection/HBox/ValueLabel
@onready var sfx_value_label: Label = $SettingsPanel/VBoxContainer/SFXVolumeSection/HBox/ValueLabel
@onready var close_button: Button = $SettingsPanel/VBoxContainer/CloseButton
@onready var settings_panel: Panel = $SettingsPanel
@onready var background_overlay: ColorRect = $BackgroundOverlay

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect sliders
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Load current settings
	if AudioManager:
		master_slider.value = AudioManager.get_master_volume() * 100
		music_slider.value = AudioManager.get_music_volume() * 100
		sfx_slider.value = AudioManager.get_sfx_volume() * 100
		
		_update_value_labels()

func show_settings():
	"""Show settings menu with fade-in animation"""
	visible = true
	
	# Animate fade-in
	background_overlay.modulate = Color.TRANSPARENT
	settings_panel.modulate = Color.TRANSPARENT
	settings_panel.scale = Vector2(0.9, 0.9)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(background_overlay, "modulate", Color.WHITE, 0.2)
	tween.tween_property(settings_panel, "modulate", Color.WHITE, 0.25)
	tween.tween_property(settings_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_settings():
	"""Hide settings menu with fade-out animation"""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(background_overlay, "modulate", Color.TRANSPARENT, 0.15)
	tween.tween_property(settings_panel, "modulate", Color.TRANSPARENT, 0.15)
	tween.tween_property(settings_panel, "scale", Vector2(0.95, 0.95), 0.15)
	
	await tween.finished
	visible = false
	closed.emit()

func _on_master_volume_changed(value: float):
	if AudioManager:
		AudioManager.set_master_volume(value / 100.0)
		AudioManager.save_settings()
		_update_value_labels()

func _on_music_volume_changed(value: float):
	if AudioManager:
		AudioManager.set_music_volume(value / 100.0)
		AudioManager.save_settings()
		_update_value_labels()

func _on_sfx_volume_changed(value: float):
	if AudioManager:
		AudioManager.set_sfx_volume(value / 100.0)
		AudioManager.save_settings()
		_update_value_labels()

func _update_value_labels():
	master_value_label.text = "%d%%" % master_slider.value
	music_value_label.text = "%d%%" % music_slider.value
	sfx_value_label.text = "%d%%" % sfx_slider.value

func _on_close_pressed():
	hide_settings()

func _input(event: InputEvent):
	"""Handle ESC key to close settings"""
	if visible and event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			hide_settings()
			accept_event()

