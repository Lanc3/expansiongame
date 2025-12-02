extends Node2D
class_name ParticleProfile2D

@export_node_path("GPUParticles2D") var particle_path: NodePath
@export var max_particles_low: int = 24
@export var max_particles_medium: int = 48
@export var max_particles_high: int = 72
@export var max_particles_ultra: int = 96
@export var lifetime: float = -1.0

func _ready():
	if Engine.is_editor_hint():
		return
	apply_profile(&"high")

func get_particles() -> GPUParticles2D:
	if particle_path.is_empty():
		return null
	return get_node_or_null(particle_path)

func apply_profile(profile: StringName) -> void:
	var particles := get_particles()
	if particles == null:
		return

	var amount := _resolve_amount(profile)
	if amount > 0:
		particles.amount = amount

	if lifetime > 0.0:
		particles.lifetime = lifetime

func _resolve_amount(profile: StringName) -> int:
	match profile:
		&"low":
			return max_particles_low
		&"medium":
			return max_particles_medium
		&"ultra":
			return max_particles_ultra
		_:
			return max_particles_high
