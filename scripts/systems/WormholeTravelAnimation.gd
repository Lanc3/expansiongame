extends CanvasLayer
## Cinematic wormhole travel animation controller

signal travel_complete

@onready var spiral_texture: TextureRect = $SpiralTexture
@onready var shader_rect: ColorRect = $ShaderRect
@onready var vignette: ColorRect = $VignetteRect
@onready var center_glow: ColorRect = $CenterGlow
@onready var particles_layer1: CPUParticles2D = $ParticlesLayer1
@onready var particles_layer2: CPUParticles2D = $ParticlesLayer2
@onready var particles_layer3: CPUParticles2D = $ParticlesLayer3

var is_animating: bool = false
var animation_tween: Tween
var shader_material: ShaderMaterial
var camera_original_position: Vector2
var time_accumulator: float = 0.0
var spiral_rotation: float = 0.0

# Animation phases duration
const APPROACH_DURATION = 0.5
const ENTER_DURATION = 0.8
const TRANSIT_DURATION = 1.2
const EXIT_DURATION = 0.8
const ARRIVE_DURATION = 0.5

func _ready():
	layer = 150  # Very high layer to be on top of everything
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS  # Keep running even if paused
	
	# Get shader material
	if shader_rect:
		shader_rect.position = Vector2.ZERO
		shader_rect.size = get_viewport().get_visible_rect().size
		if shader_rect.material is ShaderMaterial:
			shader_material = shader_rect.material
	
	# Setup vignette (ensure it covers full screen)
	if vignette:
		vignette.color = Color(0.1, 0.05, 0.2, 0.0)
		vignette.position = Vector2.ZERO
		vignette.size = get_viewport().get_visible_rect().size
	
	# Hide center glow completely (was causing purple square)
	if center_glow:
		center_glow.visible = false
	
	# Setup particle layers
	setup_particles()

func _process(delta: float):
	"""Update shader time parameter and spiral rotation"""
	if is_animating:
		# Update shader time
		if shader_material:
			time_accumulator += delta * 3.0  # Faster rotation
			shader_material.set_shader_parameter("time_offset", time_accumulator)
		
		# Rotate spiral continuously
		if spiral_texture:
			spiral_rotation += delta * 120.0  # 120 degrees per second
			spiral_texture.rotation = deg_to_rad(spiral_rotation)

func setup_particles():
	"""Initialize particle systems for travel effect - radial/spiral motion"""
	var particle_layers = [particles_layer1, particles_layer2, particles_layer3]
	
	for i in range(particle_layers.size()):
		var particles = particle_layers[i]
		if not particles:
			continue
		
		# Position at center of screen
		particles.position = get_viewport().get_visible_rect().size / 2
		
		particles.emitting = false
		particles.amount = 100 + (i * 30)
		particles.lifetime = 2.0
		particles.explosiveness = 0.0  # Continuous stream
		particles.randomness = 0.3
		
		# Point emission from center
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
		
		# Radial outward direction
		particles.direction = Vector2(0, 0)
		particles.spread = 180.0
		particles.initial_velocity_min = 150.0 + (i * 80)
		particles.initial_velocity_max = 250.0 + (i * 80)
		
		# DISABLE GRAVITY - particles move radially outward
		particles.gravity = Vector2.ZERO
		
		# Strong spiral effect using tangential acceleration
		particles.tangential_accel_min = 150.0
		particles.tangential_accel_max = 250.0
		
		# Radial acceleration (push outward from center)
		particles.radial_accel_min = 50.0
		particles.radial_accel_max = 100.0
		
		# Linear damping to slow particles as they move out
		particles.damping_min = 5.0
		particles.damping_max = 10.0
		
		# Color based on layer (purple → blue → cyan)
		match i:
			0:
				particles.color = Color(0.7, 0.4, 1.0, 0.6)
			1:
				particles.color = Color(0.4, 0.6, 1.0, 0.6)
			2:
				particles.color = Color(0.3, 0.8, 1.0, 0.6)
		
		# Particle scaling
		particles.scale_amount_min = 3.0 + i
		particles.scale_amount_max = 6.0 + i
		
		# Fade out over lifetime
		var gradient = Gradient.new()
		gradient.add_point(0.0, Color(1, 1, 1, 0.0))
		gradient.add_point(0.2, Color(1, 1, 1, 1.0))
		gradient.add_point(0.8, Color(1, 1, 1, 1.0))
		gradient.add_point(1.0, Color(1, 1, 1, 0.0))
		particles.color_ramp = gradient

func play_travel_animation(from_zone_id: String, to_zone_id: String):
	"""Play full travel animation sequence"""
	if is_animating:
		return
	
	is_animating = true
	show()
	time_accumulator = 0.0
	
	# Store camera position
	var camera = get_viewport().get_camera_2d()
	if camera:
		camera_original_position = camera.global_position
	
	
	# Reset shader parameters
	reset_shader_parameters()
	
	# Play sequence with enhanced effects
	await play_approach_phase()
	await play_enter_phase()
	await play_transit_phase()
	
	# Switch zones at peak of transit (before exit)
	if ZoneManager:
		ZoneManager.switch_to_zone(to_zone_id)
		
		# Move camera to the return wormhole (the one we entered through)
		var target_zone = ZoneManager.get_zone(to_zone_id)
		if not target_zone.is_empty():
			if camera:
				# Find the wormhole that connects back to our source zone
				var return_wormhole = null
				
				# Check both lateral and depth wormholes
				var all_wormholes = target_zone.lateral_wormholes + target_zone.depth_wormholes
				
				for wormhole in all_wormholes:
					if is_instance_valid(wormhole) and wormhole.target_zone_id == from_zone_id:
						return_wormhole = wormhole
						break
				
				# Position at return wormhole, or fallback to first wormhole
				if return_wormhole:
					camera.global_position = return_wormhole.global_position
				elif all_wormholes.size() > 0:
					camera.global_position = all_wormholes[0].global_position
	
	await play_exit_phase()
	await play_arrive_phase()
	
	# Clean up
	hide()
	is_animating = false
	Engine.time_scale = 1.0  # Ensure time scale is reset
	travel_complete.emit()
	

func reset_shader_parameters():
	"""Reset all shader parameters and spiral to zero"""
	if shader_material:
		shader_material.set_shader_parameter("warp_intensity", 0.0)
		shader_material.set_shader_parameter("swirl_amount", 0.0)
		shader_material.set_shader_parameter("chromatic_aberration", 0.0)
		shader_material.set_shader_parameter("speed_lines", 0.0)
	
	# Reset spiral
	if spiral_texture:
		spiral_texture.modulate.a = 0.0
		spiral_texture.scale = Vector2(1.0, 1.0)
		spiral_texture.rotation = 0.0
	
	spiral_rotation = 0.0

func play_approach_phase() -> void:
	"""Phase 1: Approach the wormhole"""
	
	if animation_tween:
		animation_tween.kill()
	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	animation_tween.set_ease(Tween.EASE_IN)
	animation_tween.set_trans(Tween.TRANS_QUAD)
	
	# Fade in vignette
	animation_tween.tween_property(vignette, "color:a", 0.3, APPROACH_DURATION)
	
	# Fade in spiral (to 50% alpha)
	if spiral_texture:
		animation_tween.tween_property(spiral_texture, "modulate:a", 0.5, APPROACH_DURATION)
		animation_tween.tween_property(spiral_texture, "scale", Vector2(1.2, 1.2), APPROACH_DURATION)
	
	# Start shader distortion
	if shader_material:
		animation_tween.tween_method(set_shader_warp, 0.0, 0.2, APPROACH_DURATION)
		animation_tween.tween_method(set_shader_swirl, 0.0, 1.0, APPROACH_DURATION)
	
	# Start camera shake
	start_camera_shake(0.5, 5.0)
	
	# Slight slow-mo
	Engine.time_scale = 0.9
	
	await animation_tween.finished

func play_enter_phase() -> void:
	"""Phase 2: Enter wormhole - tunnel effect begins"""
	
	if animation_tween:
		animation_tween.kill()
	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	animation_tween.set_ease(Tween.EASE_IN_OUT)
	animation_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Darken vignette more
	animation_tween.tween_property(vignette, "color:a", 0.6, ENTER_DURATION)
	animation_tween.tween_property(vignette, "color", Color(0.3, 0.1, 0.5, 0.6), ENTER_DURATION)
	
	# Intensify shader effects
	if shader_material:
		animation_tween.tween_method(set_shader_warp, 0.2, 0.5, ENTER_DURATION)
		animation_tween.tween_method(set_shader_swirl, 1.0, 3.0, ENTER_DURATION)
		animation_tween.tween_method(set_shader_chromatic, 0.0, 0.015, ENTER_DURATION)
		animation_tween.tween_method(set_shader_speed_lines, 0.0, 0.3, ENTER_DURATION)
	
	# Pulse spiral (pulsing scale animation)
	if spiral_texture:
		# Pulse between 1.2 and 1.6
		animation_tween.tween_property(spiral_texture, "scale", Vector2(1.6, 1.6), ENTER_DURATION * 0.5)
		animation_tween.tween_property(spiral_texture, "scale", Vector2(1.4, 1.4), ENTER_DURATION * 0.5).set_delay(ENTER_DURATION * 0.5)
	
	# Start particle systems
	if particles_layer1:
		particles_layer1.emitting = true
	if particles_layer2:
		particles_layer2.emitting = true
	
	# Increase camera shake
	start_camera_shake(ENTER_DURATION, 10.0)
	
	# Slow down more
	Engine.time_scale = 0.7
	
	await animation_tween.finished

func play_transit_phase() -> void:
	"""Phase 3: Full wormhole transit - peak of effect"""
	
	if animation_tween:
		animation_tween.kill()
	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	animation_tween.set_ease(Tween.EASE_IN_OUT)
	animation_tween.set_trans(Tween.TRANS_SINE)
	
	# Peak darkness
	animation_tween.tween_property(vignette, "color:a", 0.85, TRANSIT_DURATION * 0.3)
	animation_tween.tween_property(vignette, "color:a", 0.6, TRANSIT_DURATION * 0.7).set_delay(TRANSIT_DURATION * 0.3)
	
	# Color shifts: purple → blue → cyan
	animation_tween.tween_property(vignette, "color", Color(0.2, 0.3, 0.7, 0.85), TRANSIT_DURATION * 0.5)
	animation_tween.tween_property(vignette, "color", Color(0.1, 0.5, 0.8, 0.6), TRANSIT_DURATION * 0.5).set_delay(TRANSIT_DURATION * 0.5)
	
	# PEAK SHADER EFFECTS (balanced intensities)
	if shader_material:
		# Maximum warp (reduced from 0.8 to 0.6)
		animation_tween.tween_method(set_shader_warp, 0.5, 0.6, TRANSIT_DURATION * 0.4)
		animation_tween.tween_method(set_shader_warp, 0.6, 0.5, TRANSIT_DURATION * 0.6).set_delay(TRANSIT_DURATION * 0.4)
		
		# Intense swirl (reduced from 6.0 to 4.5)
		animation_tween.tween_method(set_shader_swirl, 3.0, 4.5, TRANSIT_DURATION * 0.5)
		animation_tween.tween_method(set_shader_swirl, 4.5, 3.5, TRANSIT_DURATION * 0.5).set_delay(TRANSIT_DURATION * 0.5)
		
		# Maximum chromatic aberration (reduced from 0.03 to 0.02)
		animation_tween.tween_method(set_shader_chromatic, 0.015, 0.02, TRANSIT_DURATION * 0.4)
		animation_tween.tween_method(set_shader_chromatic, 0.02, 0.015, TRANSIT_DURATION * 0.6).set_delay(TRANSIT_DURATION * 0.4)
		
		# Speed lines peak (reduced from 0.7 to 0.5)
		animation_tween.tween_method(set_shader_speed_lines, 0.3, 0.5, TRANSIT_DURATION * 0.5)
		animation_tween.tween_method(set_shader_speed_lines, 0.5, 0.3, TRANSIT_DURATION * 0.5).set_delay(TRANSIT_DURATION * 0.5)
	
	# Spiral PEAKS - intense pulsing
	if spiral_texture:
		# Large pulse animation
		animation_tween.tween_property(spiral_texture, "scale", Vector2(2.2, 2.2), TRANSIT_DURATION * 0.4)
		animation_tween.tween_property(spiral_texture, "scale", Vector2(1.9, 1.9), TRANSIT_DURATION * 0.3).set_delay(TRANSIT_DURATION * 0.4)
		animation_tween.tween_property(spiral_texture, "scale", Vector2(2.0, 2.0), TRANSIT_DURATION * 0.3).set_delay(TRANSIT_DURATION * 0.7)
	
	# All particles active
	if particles_layer3:
		particles_layer3.emitting = true
	
	# Heavy camera shake
	start_camera_shake(TRANSIT_DURATION, 15.0)
	
	# Speed up at peak
	await get_tree().create_timer(TRANSIT_DURATION * 0.3, false).timeout
	Engine.time_scale = 1.2
	
	await get_tree().create_timer(TRANSIT_DURATION * 0.7, false).timeout

func play_exit_phase() -> void:
	"""Phase 4: Exit wormhole - reverse tunnel effect"""
	
	if animation_tween:
		animation_tween.kill()
	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	animation_tween.set_ease(Tween.EASE_OUT)
	animation_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Lighten vignette
	animation_tween.tween_property(vignette, "color:a", 0.3, EXIT_DURATION)
	animation_tween.tween_property(vignette, "color", Color(0.2, 0.4, 0.6, 0.3), EXIT_DURATION)
	
	# Reduce shader effects
	if shader_material:
		animation_tween.tween_method(set_shader_warp, 0.5, 0.15, EXIT_DURATION)
		animation_tween.tween_method(set_shader_swirl, 4.0, 1.0, EXIT_DURATION)
		animation_tween.tween_method(set_shader_chromatic, 0.015, 0.005, EXIT_DURATION)
		animation_tween.tween_method(set_shader_speed_lines, 0.4, 0.1, EXIT_DURATION)
	
	# Spiral calms down
	if spiral_texture:
		animation_tween.tween_property(spiral_texture, "scale", Vector2(1.3, 1.3), EXIT_DURATION)
	
	# Stop some particles
	if particles_layer3:
		particles_layer3.emitting = false
	if particles_layer2:
		particles_layer2.emitting = false
	
	# Reduce camera shake
	start_camera_shake(EXIT_DURATION, 7.0)
	
	# Return to normal time
	Engine.time_scale = 1.0
	
	await animation_tween.finished

func play_arrive_phase() -> void:
	"""Phase 5: Arrival - fade back to normal"""
	
	if animation_tween:
		animation_tween.kill()
	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	animation_tween.set_ease(Tween.EASE_OUT)
	animation_tween.set_trans(Tween.TRANS_QUAD)
	
	# Fade out vignette completely
	animation_tween.tween_property(vignette, "color:a", 0.0, ARRIVE_DURATION)
	
	# Reset shader effects
	if shader_material:
		animation_tween.tween_method(set_shader_warp, 0.15, 0.0, ARRIVE_DURATION)
		animation_tween.tween_method(set_shader_swirl, 1.0, 0.0, ARRIVE_DURATION)
		animation_tween.tween_method(set_shader_chromatic, 0.005, 0.0, ARRIVE_DURATION)
		animation_tween.tween_method(set_shader_speed_lines, 0.1, 0.0, ARRIVE_DURATION)
	
	# Fade out spiral completely
	if spiral_texture:
		animation_tween.tween_property(spiral_texture, "modulate:a", 0.0, ARRIVE_DURATION)
		animation_tween.tween_property(spiral_texture, "scale", Vector2(1.0, 1.0), ARRIVE_DURATION)
	
	# Stop remaining particles
	if particles_layer1:
		particles_layer1.emitting = false
	
	# Gentle shake fadeout
	start_camera_shake(ARRIVE_DURATION, 3.0)
	
	await animation_tween.finished

func get_total_duration() -> float:
	"""Get total animation duration"""
	return APPROACH_DURATION + ENTER_DURATION + TRANSIT_DURATION + EXIT_DURATION + ARRIVE_DURATION

# === SHADER PARAMETER SETTERS ===

func set_shader_warp(value: float):
	"""Set warp intensity shader parameter"""
	if shader_material:
		shader_material.set_shader_parameter("warp_intensity", value)

func set_shader_swirl(value: float):
	"""Set swirl amount shader parameter"""
	if shader_material:
		shader_material.set_shader_parameter("swirl_amount", value)

func set_shader_chromatic(value: float):
	"""Set chromatic aberration shader parameter"""
	if shader_material:
		shader_material.set_shader_parameter("chromatic_aberration", value)

func set_shader_speed_lines(value: float):
	"""Set speed lines shader parameter"""
	if shader_material:
		shader_material.set_shader_parameter("speed_lines", value)

# === CAMERA EFFECTS ===

func start_camera_shake(duration: float, intensity: float):
	"""Apply camera shake effect"""
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	# Create shake using offset property
	var shake_tween = create_tween()
	shake_tween.set_loops(int(duration / 0.05))
	
	var shake_offset = Vector2(
		randf_range(-intensity, intensity),
		randf_range(-intensity, intensity)
	)
	
	shake_tween.tween_property(camera, "offset", shake_offset, 0.05)
	shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
	
	# Reset offset after duration
	await get_tree().create_timer(duration, false).timeout
	camera.offset = Vector2.ZERO
