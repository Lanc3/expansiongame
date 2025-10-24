extends Label
class_name DamageNumber
## Floating damage number that animates upward and fades out (Diablo-style)

var damage_amount: float = 0.0
var is_player_damage: bool = true
var lifetime: float = 1.0

func setup(damage: float, position: Vector2, player_damage: bool = true):
	damage_amount = damage
	is_player_damage = player_damage
	global_position = position
	
	# Set text
	text = str(int(damage))
	
	# Set consistent font size for all damage numbers
	add_theme_font_size_override("font_size", 18)
	
	# Set color based on who dealt damage
	if player_damage:
		# Player damaging enemy - vibrant red
		add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	else:
		# Enemy damaging player - yellow/warning
		add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	
	# Set outline for readability
	add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	add_theme_constant_override("outline_size", 2)
	
	# Center the label
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Random horizontal offset for visual variety
	var random_offset = Vector2(randf_range(-15, 15), 0)
	global_position += random_offset
	
	# Start animation
	animate()

func animate():
	# Start small and invisible
	scale = Vector2(0.5, 0.5)
	modulate.a = 0.0
	
	# Create tween for bouncy upward movement
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Bounce upward with elastic easing
	var end_pos = global_position + Vector2(0, -80)
	tween.tween_property(self, "global_position:y", end_pos.y, lifetime).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Slight horizontal drift
	var drift = randf_range(-20, 20)
	tween.tween_property(self, "global_position:x", global_position.x + drift, lifetime).set_ease(Tween.EASE_OUT)
	
	# Pop in quickly, then fade out slowly
	tween.tween_property(self, "modulate:a", 1.0, lifetime * 0.15).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "modulate:a", 0.0, lifetime * 0.85).set_ease(Tween.EASE_IN)
	
	# Bouncy scale animation - pop in with overshoot
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), lifetime * 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.chain().tween_property(self, "scale", Vector2(0.6, 0.6), lifetime * 0.8).set_ease(Tween.EASE_IN)
	
	# Add slight rotation for more dynamism
	var rotation_amount = randf_range(-0.3, 0.3)
	tween.tween_property(self, "rotation", rotation_amount, lifetime * 0.3).set_ease(Tween.EASE_OUT)
	
	# Queue free when done
	tween.finished.connect(queue_free)

func _ready():
	# Set z-index high so it appears above units
	z_index = 100

