## Engine beam effect using Line2D, similar to mining laser but fades out like an engine plume
## Used for custom ship engine visual effects
@tool
extends Node2D
class_name EngineBeam2D

## Length of the beam in pixels
@export var beam_length: float = 100.0: set = set_beam_length
## Base color of the beam (blue/cyan ion colors)
@export var beam_color: Color = Color(0.3, 0.8, 1.0, 1.0): set = set_beam_color
## Speed of width pulsing animation in Hz
@export var pulse_speed: float = 2.5
## Base width of the beam in pixels
@export var base_width: float = 3.0
## Intensity (0.0-1.0) controls visibility and width scaling
@export var intensity: float = 1.0: set = set_intensity

var pulse_time: float = 0.0

@onready var line_2d: Line2D = $Line2D

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if line_2d:
		set_beam_length(beam_length)
		set_beam_color(beam_color)
		set_intensity(intensity)
		line_2d.visible = (intensity > 0.0)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if not line_2d:
		return
	
	# Update pulsing animation
	pulse_time += delta * pulse_speed * TAU
	var pulse_factor = 1.0 + sin(pulse_time) * 0.2  # ±20% variation
	line_2d.width = base_width * intensity * pulse_factor

func set_beam_length(length: float) -> void:
	beam_length = length
	if line_2d:
		# Beam points from origin downward (positive Y = thrust direction)
		# In VisualContainer space, ship faces up (-Y), so thrust is down (+Y)
		line_2d.points = PackedVector2Array([
			Vector2.ZERO,
			Vector2(0, beam_length)  # Points down (+Y) = thrust direction
		])

func set_beam_color(color: Color) -> void:
	beam_color = color
	if line_2d:
		line_2d.modulate = color

func set_intensity(value: float) -> void:
	intensity = clamp(value, 0.0, 1.0)
	if line_2d:
		line_2d.visible = (intensity > 0.0)
		line_2d.width = base_width * intensity

