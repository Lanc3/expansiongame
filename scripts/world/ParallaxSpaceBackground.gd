extends ParallaxBackground

## Vibrant Sci-Fi Space Background
## Features: Glowing stars, multi-layer nebulae, GPU particles, camera-reactive effects

# Configuration
const STAR_COUNTS = {
	"layer1": 400,  # Far distant stars
	"layer2": 300,  # Medium distance stars
	"layer3": 200   # Near stars
}

const STAR_SIZES = {
	"layer1": [4, 8],      # Small stars with glow
	"layer2": [8, 12],     # Medium stars
	"layer3": [12, 20]     # Large, bright stars
}

const GENERATION_AREA = Vector2(6000, 6000)

# Vibrant star color palette
const STAR_COLORS = [
	Color(1.0, 1.0, 1.0, 1.0),       # Pure white
	Color(0.6, 0.8, 1.0, 1.0),       # Bright blue
	Color(1.0, 0.7, 1.0, 1.0),       # Purple-pink
	Color(1.0, 0.9, 0.5, 1.0),       # Yellow
	Color(1.0, 0.5, 0.3, 1.0),       # Orange
	Color(0.5, 0.9, 1.0, 1.0),       # Cyan
	Color(1.0, 0.4, 0.8, 1.0),       # Hot pink
]

# Multi-layer vibrant nebula colors
const NEBULA_COLOR_SCHEMES = [
	# Purple -> Pink -> Blue
	[Color(0.6, 0.2, 0.8, 0.25), Color(0.9, 0.3, 0.7, 0.2), Color(0.4, 0.3, 0.9, 0.15)],
	# Cyan -> Green -> Teal
	[Color(0.2, 0.8, 0.9, 0.23), Color(0.3, 0.9, 0.6, 0.18), Color(0.3, 0.7, 0.8, 0.15)],
	# Orange -> Red -> Purple
	[Color(0.9, 0.5, 0.2, 0.22), Color(0.9, 0.2, 0.3, 0.2), Color(0.7, 0.2, 0.6, 0.15)],
	# Blue -> Purple -> Pink
	[Color(0.3, 0.4, 0.9, 0.24), Color(0.6, 0.3, 0.9, 0.2), Color(0.9, 0.4, 0.8, 0.16)],
	# Green -> Yellow -> Orange
	[Color(0.4, 0.9, 0.4, 0.2), Color(0.9, 0.9, 0.3, 0.18), Color(0.9, 0.6, 0.2, 0.15)],
]

# Galaxy colors
const GALAXY_COLORS = [
	Color(0.5, 0.6, 0.9, 0.3),       # Blue spiral
	Color(0.8, 0.5, 0.7, 0.28),      # Purple spiral
	Color(0.6, 0.8, 0.6, 0.25),      # Green spiral
	Color(0.9, 0.7, 0.5, 0.3),       # Orange spiral
]

var star_tweens = []
var nebula_pulse_tweens = []
var camera: Camera2D = null
var last_camera_pos: Vector2 = Vector2.ZERO
var camera_velocity: Vector2 = Vector2.ZERO

@onready var star_layer1 = $StarLayer1
@onready var star_layer2 = $StarLayer2
@onready var star_layer3 = $StarLayer3
@onready var nebula_layer = $NebulaLayer
@onready var celestial_layer = $CelestialLayer
@onready var galaxy_layer = $GalaxyLayer
@onready var dust_particles_layer = $DustParticlesLayer
@onready var sparkle_particles_layer = $SparkleParticlesLayer
@onready var drift_particles_layer = $DriftParticlesLayer
@onready var cosmic_dust_shader_layer = $CosmicDustShaderLayer


func _ready():
	randomize()
	
	# Find camera for velocity tracking
	await get_tree().process_frame
	camera = get_viewport().get_camera_2d()
	if camera:
		last_camera_pos = camera.global_position
	
	_generate_stars()
	_generate_nebulae()
	_generate_celestial_objects()
	_generate_distant_galaxies()
	_generate_gpu_particles()
	_generate_cosmic_dust_shader()


func _process(delta):
	# Track camera velocity for dynamic effects
	if camera and is_instance_valid(camera):
		var current_pos = camera.global_position
		camera_velocity = (current_pos - last_camera_pos) / delta
		last_camera_pos = current_pos
		
		# Apply camera-speed effects
		_apply_camera_speed_effects()


# ============================================================================
# GLOWING STAR GENERATION
# ============================================================================

func _generate_stars():
	_create_stars_for_layer(star_layer1, STAR_COUNTS["layer1"], STAR_SIZES["layer1"], 2.5)
	_create_stars_for_layer(star_layer2, STAR_COUNTS["layer2"], STAR_SIZES["layer2"], 2.0)
	_create_stars_for_layer(star_layer3, STAR_COUNTS["layer3"], STAR_SIZES["layer3"], 1.5)


func _create_stars_for_layer(layer: ParallaxLayer, count: int, size_range: Array, glow_mult: float):
	for i in range(count):
		var star = _create_glowing_star(size_range, glow_mult)
		star.position = Vector2(
			randf_range(-GENERATION_AREA.x / 2, GENERATION_AREA.x / 2),
			randf_range(-GENERATION_AREA.y / 2, GENERATION_AREA.y / 2)
		)
		layer.add_child(star)
		_start_twinkling(star)


func _create_glowing_star(size_range: Array, glow_multiplier: float) -> Sprite2D:
	var star = Sprite2D.new()
	var base_size = randf_range(size_range[0], size_range[1])
	var glow_size = base_size * glow_multiplier
	
	# Create radial gradient for glow effect
	var gradient = Gradient.new()
	var star_color = STAR_COLORS[randi() % STAR_COLORS.size()]
	
	# Clear default gradient points first
	gradient.remove_point(1)
	gradient.remove_point(0)
	
	# Multi-stop gradient for better glow with proper transparency
	gradient.add_point(0.0, star_color)  # Bright center
	gradient.add_point(0.3, Color(star_color.r, star_color.g, star_color.b, 0.8))
	gradient.add_point(0.6, Color(star_color.r, star_color.g, star_color.b, 0.3))
	gradient.add_point(1.0, Color(star_color.r, star_color.g, star_color.b, 0.0))  # Fully transparent
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0.5, 0.5)
	gradient_texture.fill_to = Vector2(1.0, 0.5)
	gradient_texture.fill = GradientTexture2D.FILL_RADIAL
	gradient_texture.width = int(glow_size * 2)
	gradient_texture.height = int(glow_size * 2)
	
	star.texture = gradient_texture
	star.centered = true
	
	# Additive blend mode for glow
	var material = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	star.material = material
	
	# Vary initial brightness
	star.modulate.a = randf_range(0.5, 1.0)
	
	return star


func _start_twinkling(star: Sprite2D):
	# Random initial delay
	await get_tree().create_timer(randf_range(0, 3.0)).timeout
	_twinkling_loop(star)


func _twinkling_loop(star: Sprite2D):
	if not is_instance_valid(star):
		return
	
	var tween = create_tween()
	tween.set_loops()
	
	# Random twinkling parameters
	var min_alpha = randf_range(0.4, 0.6)
	var max_alpha = randf_range(0.8, 1.0)
	var duration = randf_range(1.5, 5.0)
	
	# Fade out
	tween.tween_property(star, "modulate:a", min_alpha, duration / 2).set_ease(Tween.EASE_IN_OUT)
	# Fade in
	tween.tween_property(star, "modulate:a", max_alpha, duration / 2).set_ease(Tween.EASE_IN_OUT)
	
	star_tweens.append(tween)


# ============================================================================
# ENHANCED VIBRANT NEBULAE
# ============================================================================

func _generate_nebulae():
	var nebula_count = randi_range(6, 8)
	
	for i in range(nebula_count):
		# Create multi-layer nebula
		var nebula_group = Node2D.new()
		nebula_group.position = Vector2(
			randf_range(-GENERATION_AREA.x / 2, GENERATION_AREA.x / 2),
			randf_range(-GENERATION_AREA.y / 2, GENERATION_AREA.y / 2)
		)
		
		var color_scheme = NEBULA_COLOR_SCHEMES[randi() % NEBULA_COLOR_SCHEMES.size()]
		var base_size = randf_range(1200, 2500)
		
		# Create 2-3 layers with different sizes and rotations
		var layer_count = randi_range(2, 3)
		for layer_idx in range(layer_count):
			var nebula_layer_sprite = _create_nebula_layer(color_scheme, base_size, layer_idx, layer_count)
			nebula_group.add_child(nebula_layer_sprite)
		
		nebula_layer.add_child(nebula_group)
		_start_nebula_rotation(nebula_group)
		_start_nebula_pulsing(nebula_group)


func _create_nebula_layer(color_scheme: Array, base_size: float, layer_idx: int, total_layers: int) -> Sprite2D:
	var nebula = Sprite2D.new()
	
	# Vary size per layer
	var size_variation = 1.0 - (layer_idx * 0.15)
	var size = base_size * size_variation
	
	# Create multi-stop gradient
	var gradient = Gradient.new()
	
	# Clear default gradient points
	gradient.remove_point(1)
	gradient.remove_point(0)
	
	# Add color scheme points with adjusted spacing for smoother fade
	for i in range(color_scheme.size()):
		# Compress the gradient toward center so edges fade to transparent
		var offset = float(i) / float(color_scheme.size() - 1) * 0.7
		gradient.add_point(offset, color_scheme[i])
	
	# Add extra transparent points to ensure corners are invisible
	var last_color = color_scheme[color_scheme.size() - 1]
	gradient.add_point(0.85, Color(last_color.r, last_color.g, last_color.b, last_color.a * 0.3))
	gradient.add_point(1.0, Color(last_color.r, last_color.g, last_color.b, 0.0))
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0.5, 0.5)
	gradient_texture.fill_to = Vector2(1.0, 0.5)
	gradient_texture.fill = GradientTexture2D.FILL_RADIAL
	gradient_texture.width = int(size)
	gradient_texture.height = int(size)
	
	nebula.texture = gradient_texture
	nebula.centered = true
	
	# Additive blend for glow
	var material = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	nebula.material = material
	
	# Rotate each layer differently
	nebula.rotation = randf() * TAU
	
	return nebula


func _start_nebula_rotation(nebula_group: Node2D):
	var tween = create_tween()
	tween.set_loops()
	
	var rotation_duration = randf_range(80.0, 150.0)
	var rotation_direction = 1 if randf() > 0.5 else -1
	
	tween.tween_property(nebula_group, "rotation", rotation_direction * TAU, rotation_duration).set_ease(Tween.EASE_IN_OUT)


func _start_nebula_pulsing(nebula_group: Node2D):
	await get_tree().create_timer(randf_range(0, 5.0)).timeout
	
	var tween = create_tween()
	tween.set_loops()
	
	var pulse_duration = randf_range(4.0, 8.0)
	var min_alpha = 0.12
	var max_alpha = 0.25
	
	# Pulse breathing effect
	tween.tween_property(nebula_group, "modulate:a", max_alpha, pulse_duration / 2).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(nebula_group, "modulate:a", min_alpha, pulse_duration / 2).set_ease(Tween.EASE_IN_OUT)
	
	nebula_pulse_tweens.append(tween)


# ============================================================================
# CELESTIAL OBJECTS
# ============================================================================

func _generate_celestial_objects():
	var object_count = randi_range(4, 6)
	
	for i in range(object_count):
		var celestial = _create_celestial_object()
		celestial.position = Vector2(
			randf_range(-GENERATION_AREA.x / 2, GENERATION_AREA.x / 2),
			randf_range(-GENERATION_AREA.y / 2, GENERATION_AREA.y / 2)
		)
		celestial_layer.add_child(celestial)


func _create_celestial_object() -> Sprite2D:
	var celestial = Sprite2D.new()
	var radius = randf_range(50, 120)
	
	# Create circular gradient
	var gradient = Gradient.new()
	var base_color = Color(
		randf_range(0.3, 0.9),
		randf_range(0.3, 0.9),
		randf_range(0.3, 0.9),
		randf_range(0.4, 0.7)
	)
	
	# Clear default gradient points
	gradient.remove_point(1)
	gradient.remove_point(0)
	
	gradient.add_point(0.0, base_color)
	gradient.add_point(0.7, Color(base_color.r * 0.6, base_color.g * 0.6, base_color.b * 0.6, base_color.a))
	gradient.add_point(1.0, Color(base_color.r * 0.3, base_color.g * 0.3, base_color.b * 0.3, 0.0))  # Fully transparent
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0.5, 0.5)
	gradient_texture.fill_to = Vector2(1.0, 0.5)
	gradient_texture.fill = GradientTexture2D.FILL_RADIAL
	gradient_texture.width = int(radius * 2)
	gradient_texture.height = int(radius * 2)
	
	celestial.texture = gradient_texture
	celestial.centered = true
	
	return celestial


# ============================================================================
# DISTANT GALAXIES
# ============================================================================

func _generate_distant_galaxies():
	var galaxy_count = randi_range(3, 5)
	
	for i in range(galaxy_count):
		var galaxy = _create_galaxy()
		galaxy.position = Vector2(
			randf_range(-GENERATION_AREA.x / 2, GENERATION_AREA.x / 2),
			randf_range(-GENERATION_AREA.y / 2, GENERATION_AREA.y / 2)
		)
		galaxy_layer.add_child(galaxy)
		_start_galaxy_rotation(galaxy)


func _create_galaxy() -> Sprite2D:
	var galaxy = Sprite2D.new()
	var size = randf_range(300, 600)
	
	# Create spiral-like gradient
	var gradient = Gradient.new()
	var galaxy_color = GALAXY_COLORS[randi() % GALAXY_COLORS.size()]
	
	# Clear default gradient points
	gradient.remove_point(1)
	gradient.remove_point(0)
	
	gradient.add_point(0.0, Color(galaxy_color.r * 1.2, galaxy_color.g * 1.2, galaxy_color.b * 1.2, galaxy_color.a))
	gradient.add_point(0.3, galaxy_color)
	gradient.add_point(0.7, Color(galaxy_color.r * 0.5, galaxy_color.g * 0.5, galaxy_color.b * 0.5, galaxy_color.a * 0.5))
	gradient.add_point(1.0, Color(galaxy_color.r * 0.2, galaxy_color.g * 0.2, galaxy_color.b * 0.2, 0.0))  # Fully transparent
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0.5, 0.5)
	gradient_texture.fill_to = Vector2(1.0, 0.5)
	gradient_texture.fill = GradientTexture2D.FILL_RADIAL
	gradient_texture.width = int(size)
	gradient_texture.height = int(size * 0.6)  # Elliptical
	
	galaxy.texture = gradient_texture
	galaxy.centered = true
	galaxy.rotation = randf() * TAU
	
	# Additive blend
	var material = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	galaxy.material = material
	
	return galaxy


func _start_galaxy_rotation(galaxy: Sprite2D):
	var tween = create_tween()
	tween.set_loops()
	
	var rotation_duration = randf_range(200.0, 400.0)
	var current_rotation = galaxy.rotation
	
	# Linear easing is default in Godot 4, no need to set explicitly
	tween.tween_property(galaxy, "rotation", current_rotation + TAU, rotation_duration)


# ============================================================================
# GPU PARTICLE SYSTEMS
# ============================================================================

func _generate_gpu_particles():
	_create_cosmic_dust_particles()
	_create_sparkle_particles()
	_create_drift_particles()


func _create_cosmic_dust_particles():
	var particles = GPUParticles2D.new()
	particles.amount = 800
	particles.lifetime = 15.0
	particles.preprocess = 10.0
	particles.explosiveness = 0.0
	particles.randomness = 0.5
	particles.visibility_rect = Rect2(-3000, -3000, 6000, 6000)
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(3000, 3000, 0)
	
	material.direction = Vector3(1, 0.2, 0)
	material.spread = 180
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 15.0
	
	material.gravity = Vector3.ZERO
	material.scale_min = 1.0
	material.scale_max = 3.0
	
	# Semi-transparent white/blue
	material.color = Color(0.7, 0.8, 1.0, 0.3)
	
	particles.process_material = material
	particles.emitting = true
	
	dust_particles_layer.add_child(particles)


func _create_sparkle_particles():
	var particles = GPUParticles2D.new()
	particles.amount = 200
	particles.lifetime = 3.0
	particles.preprocess = 2.0
	particles.explosiveness = 0.0
	particles.randomness = 0.8
	particles.visibility_rect = Rect2(-3000, -3000, 6000, 6000)
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(3000, 3000, 0)
	
	material.direction = Vector3(0, 0, 0)
	material.spread = 180
	material.initial_velocity_min = 0.0
	material.initial_velocity_max = 5.0
	
	material.gravity = Vector3.ZERO
	material.scale_min = 2.0
	material.scale_max = 6.0
	
	# Bright colors with alpha variation
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 1, 1))
	gradient.add_point(0.5, Color(0.8, 0.9, 1.0, 0.8))
	gradient.add_point(1.0, Color(0.5, 0.7, 1.0, 0))
	material.color_ramp = gradient
	
	particles.process_material = material
	particles.emitting = true
	
	# Additive blend for sparkle
	particles.material = CanvasItemMaterial.new()
	particles.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	
	sparkle_particles_layer.add_child(particles)


func _create_drift_particles():
	var particles = GPUParticles2D.new()
	particles.amount = 300
	particles.lifetime = 12.0
	particles.preprocess = 8.0
	particles.explosiveness = 0.0
	particles.randomness = 0.6
	particles.visibility_rect = Rect2(-3000, -3000, 6000, 6000)
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(3000, 3000, 0)
	
	material.direction = Vector3(0.5, 0.3, 0)
	material.spread = 180
	material.initial_velocity_min = 10.0
	material.initial_velocity_max = 30.0
	
	material.gravity = Vector3.ZERO
	material.scale_min = 4.0
	material.scale_max = 10.0
	
	# Vibrant colored particles
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.8, 0.3, 1.0, 0.6))  # Purple
	gradient.add_point(0.5, Color(0.3, 0.8, 1.0, 0.5))  # Cyan
	gradient.add_point(1.0, Color(1.0, 0.5, 0.3, 0))    # Orange fade
	material.color_ramp = gradient
	
	particles.process_material = material
	particles.emitting = true
	
	# Additive blend
	particles.material = CanvasItemMaterial.new()
	particles.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	
	drift_particles_layer.add_child(particles)


# ============================================================================
# CAMERA-SPEED DYNAMIC EFFECTS
# ============================================================================

func _apply_camera_speed_effects():
	var speed = camera_velocity.length()
	var speed_threshold = 500.0
	
	if speed > speed_threshold:
		# Calculate stretch direction (opposite to movement)
		var stretch_direction = -camera_velocity.normalized()
		var stretch_amount = clamp((speed - speed_threshold) / 1000.0, 0.0, 2.0)
		
		# Apply stretching to star layers
		_apply_star_stretch(star_layer3, stretch_direction, stretch_amount, 1.5)
		_apply_star_stretch(star_layer2, stretch_direction, stretch_amount, 1.0)
		_apply_star_stretch(star_layer1, stretch_direction, stretch_amount, 0.5)
	else:
		# Reset to normal scale
		_reset_star_stretch(star_layer3, 0.05)
		_reset_star_stretch(star_layer2, 0.05)
		_reset_star_stretch(star_layer1, 0.05)


func _apply_star_stretch(layer: ParallaxLayer, direction: Vector2, amount: float, intensity: float):
	for star in layer.get_children():
		if star is Sprite2D:
			var target_scale = Vector2(
				1.0 + amount * abs(direction.x) * intensity,
				1.0 + amount * abs(direction.y) * intensity
			)
			star.scale = star.scale.lerp(target_scale, 0.1)


func _reset_star_stretch(layer: ParallaxLayer, lerp_weight: float):
	for star in layer.get_children():
		if star is Sprite2D:
			star.scale = star.scale.lerp(Vector2.ONE, lerp_weight)


# ============================================================================
# COSMIC DUST SHADER LAYER
# ============================================================================

func _generate_cosmic_dust_shader():
	# Create multiple dust layers with different colors and scales
	var dust_configs = [
		{"tint": Vector3(0.5, 0.3, 0.8), "intensity": 0.12, "scale": 2.0},  # Purple
		{"tint": Vector3(0.2, 0.5, 0.8), "intensity": 0.10, "scale": 3.0},  # Cyan
		{"tint": Vector3(0.8, 0.4, 0.2), "intensity": 0.08, "scale": 2.5},  # Orange
	]
	
	for i in range(dust_configs.size()):
		var config = dust_configs[i]
		var dust_rect = _create_cosmic_dust_rect(config)
		dust_rect.position = Vector2(-3000, -3000) + Vector2(i * 100, i * 100)  # Slight offset per layer
		cosmic_dust_shader_layer.add_child(dust_rect)


func _create_cosmic_dust_rect(config: Dictionary) -> ColorRect:
	var dust = ColorRect.new()
	dust.size = Vector2(6000, 6000)
	dust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Load cosmic dust shader
	var shader = load("res://shaders/cosmic_dust.gdshader")
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	
	# Set shader parameters
	shader_material.set_shader_parameter("dust_tint", config["tint"])
	shader_material.set_shader_parameter("dust_intensity", config["intensity"])
	shader_material.set_shader_parameter("scale", config["scale"])
	shader_material.set_shader_parameter("animation_speed", randf_range(0.03, 0.07))
	shader_material.set_shader_parameter("octaves", 4)
	
	dust.material = shader_material
	
	return dust


# ============================================================================
# CLEANUP
# ============================================================================

func _exit_tree():
	# Clean up tweens
	for tween in star_tweens:
		if is_instance_valid(tween):
			tween.kill()
	star_tweens.clear()
	
	for tween in nebula_pulse_tweens:
		if is_instance_valid(tween):
			tween.kill()
	nebula_pulse_tweens.clear()
