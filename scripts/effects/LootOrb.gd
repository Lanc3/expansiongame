extends Node2D
class_name LootOrb
## Visual representation of loot that can be collected

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var particles: CPUParticles2D = $Particles if has_node("Particles") else null

var resource_id: int = 0
var amount: int = 0
var lifetime: float = 60.0  # Despawn after 60 seconds
var lifetime_timer: float = 0.0
var pulse_timer: float = 0.0

func _ready():
	add_to_group("loot")
	z_index = 5  # Above asteroids, below UI

func setup(res_id: int, res_amount: int):
	"""Initialize the loot orb with resource data"""
	resource_id = res_id
	amount = res_amount
	
	# Store as metadata for easy access
	set_meta("resource_id", resource_id)
	set_meta("amount", amount)
	
	# Set color based on rarity
	var color = LootDropSystem.get_resource_color(resource_id)
	if sprite:
		sprite.modulate = color
	if particles:
		particles.color = color
		particles.emitting = true
	
	# Pop-in animation
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float):
	# Lifetime countdown
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		# Fade out and despawn
		fade_out()
		return
	
	# Pulse animation
	pulse_timer += delta * 3.0
	if sprite:
		var pulse = 1.0 + sin(pulse_timer) * 0.2
		sprite.scale = Vector2.ONE * pulse
	
	# Start fading in last 5 seconds
	if lifetime_timer >= lifetime - 5.0:
		var fade_progress = (lifetime - lifetime_timer) / 5.0
		modulate.a = fade_progress

func fade_out():
	"""Fade out and remove"""
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func collect():
	"""Collect this loot orb"""
	# Add resources to player
	if ResourceManager:
		ResourceManager.add_resource(resource_id, amount)
	
	# Visual/audio feedback
	if AudioManager:
		AudioManager.play_sound("loot_pickup")
	
	# Pop-out animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)

