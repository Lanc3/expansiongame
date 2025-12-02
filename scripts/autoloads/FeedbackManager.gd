extends Node
## Manages visual and audio feedback effects

var mining_effect_scene: PackedScene
var explosion_effect_scene: PackedScene
var collection_effect_scene: PackedScene
var death_effect_scene: PackedScene
var damage_number_scene: PackedScene
var event_notification_scene: PackedScene

func _ready():
	# Preload effect scenes
	mining_effect_scene = preload("res://scenes/effects/MiningEffect.tscn") if ResourceLoader.exists("res://scenes/effects/MiningEffect.tscn") else null
	explosion_effect_scene = preload("res://scenes/effects/CombatExplosion.tscn") if ResourceLoader.exists("res://scenes/effects/CombatExplosion.tscn") else null
	damage_number_scene = preload("res://scenes/ui/DamageNumber.tscn") if ResourceLoader.exists("res://scenes/ui/DamageNumber.tscn") else null
	event_notification_scene = preload("res://scenes/ui/EventNotification.tscn") if ResourceLoader.exists("res://scenes/ui/EventNotification.tscn") else null
# Add this function to your existing FeedbackManager.gd:

func spawn_move_indicator(position: Vector2):
	# Create a visual indicator at the target position
	var indicator = ColorRect.new()
	indicator.size = Vector2(20, 20)
	indicator.position = position - indicator.size / 2
	indicator.color = Color(0.2, 1.0, 0.2, 0.8)  # Green
	indicator.z_index = 100
	
	# Add to current scene
	get_tree().current_scene.add_child(indicator)
	
	# Animate: fade out and scale up
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(indicator, "modulate:a", 0.0, 0.8)
	tween.tween_property(indicator, "scale", Vector2(2.0, 2.0), 0.8)
	tween.tween_callback(indicator.queue_free)
	
	# Optional: Add a ring sprite for better visual
	var ring = Sprite2D.new()
	ring.position = position
	ring.modulate = Color(0.2, 1.0, 0.2, 0.8)
	ring.z_index = 100
	
	# Create simple circle texture (or use a real sprite)
	var circle_texture = PlaceholderTexture2D.new()
	circle_texture.size = Vector2(32, 32)
	ring.texture = circle_texture
	
	get_tree().current_scene.add_child(ring)
	
	# Animate ring
	var ring_tween = create_tween()
	ring_tween.set_parallel(true)
	ring_tween.tween_property(ring, "modulate:a", 0.0, 0.6)
	ring_tween.tween_property(ring, "scale", Vector2(1.5, 1.5), 0.6)
	ring_tween.tween_callback(ring.queue_free)
func spawn_mining_effect(position: Vector2):
	if mining_effect_scene:
		spawn_effect(mining_effect_scene, position, 2.0)

func spawn_explosion(position: Vector2):
	var parent_scene = get_tree().current_scene
	if VfxDirector and parent_scene:
		VfxDirector.spawn_explosion(parent_scene, position, .10)
	elif explosion_effect_scene:
		var effect = explosion_effect_scene.instantiate()
		effect.global_position = position
		effect.scale = Vector2(1.0, 1.0)  # Scale to 200% of original
		get_tree().root.add_child(effect)
		
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(effect):
			effect.queue_free()
	if AudioManager:
		AudioManager.play_sound("explosion")

func spawn_collection_effect(position: Vector2, color: Color):
	# Create simple particle effect with color
	var particles = CPUParticles2D.new()
	particles.global_position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 10
	particles.lifetime = 0.5
	particles.color = color
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	particles.gravity = Vector2(0, 50)
	
	get_tree().root.add_child(particles)
	
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func spawn_death_effect(position: Vector2):
	spawn_explosion(position)

func spawn_effect(effect_scene: PackedScene, position: Vector2, duration: float):
	var effect = effect_scene.instantiate()
	effect.global_position = position
	get_tree().root.add_child(effect)
	
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(effect):
		effect.queue_free()

func flash_sprite(sprite: Sprite2D, color: Color, duration: float = 0.2):
	if not is_instance_valid(sprite):
		return
	
	var original_modulate = sprite.modulate
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", color, duration / 2.0)
	tween.tween_property(sprite, "modulate", original_modulate, duration / 2.0)

## Show a temporary message at top-center of screen
func show_message(message: String, duration: float = 2.0):
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	
	# Position at top-center
	label.position = Vector2(640 - 100, 100)  # Centered, 100px from top
	label.size = Vector2(200, 30)
	label.z_index = 1000
	
	# Add to a UI layer if available
	var ui_layer = get_tree().root.get_node_or_null("GameScene/UILayer")
	if ui_layer:
		ui_layer.add_child(label)
	else:
		get_tree().current_scene.add_child(label)
	
	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, duration)
	tween.tween_callback(label.queue_free)

func spawn_damage_number(position: Vector2, damage: float, is_player_damage: bool = true):
	"""Spawn floating damage number at position (Diablo-style)"""
	if not damage_number_scene:
		return
	
	var damage_num = damage_number_scene.instantiate() as DamageNumber
	if not damage_num:
		return
	
	# Add to current scene
	get_tree().current_scene.add_child(damage_num)
	
	# Setup and animate
	damage_num.setup(damage, position, is_player_damage)

func show_event_notification(description: String, location: Vector2, warning_time: float):
	"""Show event warning notification"""
	if not event_notification_scene:
		return
	
	var notification = event_notification_scene.instantiate() as EventNotification
	if not notification:
		return
	
	# Add to UI layer (or current scene if no UI layer)
	var ui_layer = get_tree().root.find_child("UILayer", true, false)
	if ui_layer:
		ui_layer.add_child(notification)
	else:
		get_tree().current_scene.add_child(notification)
	
	# Setup notification
	notification.setup(description, location, warning_time)
