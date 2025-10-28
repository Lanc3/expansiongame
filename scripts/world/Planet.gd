extends Sprite2D
class_name Planet
## Large planet sprite that serves as orbital center for asteroids

@export var zone_id: String = ""
@export var planet_scale: float = 3.0

func _ready():
	# Scale is set dynamically when created
	scale = Vector2(planet_scale, planet_scale)
	
	# Optional: Add subtle glow effect
	modulate = Color(1.0, 1.0, 1.0, 1.0)

func setup(p_zone_id: String, planet_texture: Texture2D, p_scale: float):
	"""Setup planet with zone-specific properties"""
	zone_id = p_zone_id
	texture = planet_texture
	planet_scale = p_scale
	scale = Vector2(planet_scale, planet_scale)

