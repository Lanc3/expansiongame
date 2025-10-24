extends Control
class_name EventNotification
## Warning notification for incoming random events

@onready var panel: Panel = $Panel if has_node("Panel") else null
@onready var title_label: Label = $Panel/VBox/Title if has_node("Panel/VBox/Title") else null
@onready var timer_label: Label = $Panel/VBox/Timer if has_node("Panel/VBox/Timer") else null
@onready var location_button: Button = $Panel/VBox/LocationButton if has_node("Panel/VBox/LocationButton") else null

var event_location: Vector2
var time_remaining: float
var pulse_tween: Tween

func _ready():
	z_index = 150  # Above most UI
	
	# Start pulse animation
	start_pulse_animation()

func setup(description: String, location: Vector2, warning_time: float):
	"""Initialize the notification with event data"""
	event_location = location
	time_remaining = warning_time
	
	if title_label:
		title_label.text = description
	
	if location_button:
		location_button.pressed.connect(_on_location_button_pressed)
	
	# Play warning sound
	if AudioManager:
		AudioManager.play_sound("ui_warning")

func _process(delta: float):
	time_remaining -= delta
	
	if timer_label:
		timer_label.text = "%.1f seconds" % time_remaining
	
	# Remove when time runs out
	if time_remaining <= 0:
		fade_out_and_remove()

func start_pulse_animation():
	"""Pulsing border animation"""
	if pulse_tween:
		pulse_tween.kill()
	
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(self, "modulate:a", 0.7, 0.5)
	pulse_tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_location_button_pressed():
	"""Pan camera to event location"""
	# Find camera
	var camera = get_viewport().get_camera_2d()
	if camera:
		camera.global_position = event_location
	
	# Play UI sound
	if AudioManager:
		AudioManager.play_sound("ui_click")

func fade_out_and_remove():
	"""Fade out animation then remove"""
	if pulse_tween:
		pulse_tween.kill()
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

