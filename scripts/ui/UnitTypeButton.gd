extends Button
class_name UnitTypeButton

## Clickable button showing unit type icon and count

var unit_type: String = ""
var unit_count: int = 0

@onready var icon_texture: TextureRect = $VBox/IconTexture
@onready var count_label: Label = $VBox/CountLabel

# Unit type sprite mapping
const UNIT_TYPE_SPRITES = {
	"CommandShip": "res://assets/sprites/ufoRed.png",
	"MiningDrone": "res://assets/sprites/UI/cursor.png",
	"CombatDrone": "res://assets/sprites/playerShip1_blue.png",
	"ScoutDrone": "res://assets/sprites/playerShip2_green.png",
	"BuilderDrone": "res://assets/sprites/playerShip2_orange.png",
	"HeavyDrone": "res://assets/sprites/playerShip3_red.png",
	"SupportDrone": "res://assets/sprites/playerShip3_green.png"
}

func setup(type: String, _unused: String):
	unit_type = type
	
	# Load sprite for this unit type
	if icon_texture and type in UNIT_TYPE_SPRITES:
		var sprite_path = UNIT_TYPE_SPRITES[type]
		if ResourceLoader.exists(sprite_path):
			icon_texture.texture = load(sprite_path)
	
	tooltip_text = "%s - Click to select all" % type
	pressed.connect(_on_pressed)
	
	# Add smooth hover transitions
	mouse_entered.connect(_on_button_hover)
	mouse_exited.connect(_on_button_unhover)

func _on_button_hover():
	"""Hover effect with scale"""
	if disabled:
		return
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.2)

func _on_button_unhover():
	"""Remove hover effect"""
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)

func update_count(count: int):
	unit_count = count
	
	if count_label:
		count_label.text = "×%d" % count if count > 0 else "×0"
	
	disabled = count == 0
	
	if count > 0:
		modulate = Color(1, 1, 1, 1)
	else:
		modulate = Color(0.6, 0.6, 0.6, 0.8)

func _on_pressed():
	# Click flash effect
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.05)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
	
	# Play click sound
	if AudioManager and AudioManager.has_method("play_sound"):
		AudioManager.play_sound("button_click")
	
	SelectionManager.select_units_by_type(unit_type)
