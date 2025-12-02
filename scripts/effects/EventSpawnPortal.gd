extends Node2D
class_name EventSpawnPortal
## Animated portal that spawns event entities with particle effects

signal portal_fully_opened
signal portal_closed
signal entity_spawned(entity: Node2D)

enum PortalState { OPENING, OPEN, SPAWNING, CLOSING, CLOSED }

var current_state: PortalState = PortalState.OPENING
var warning_duration: float = 10.0
var entities_to_spawn: Array = []
var spawn_delay_between: float = 0.5
var current_spawn_index: int = 0
var state_timer: float = 0.0
var spawn_timer: float = 0.0

# Visual components - matching Wormhole structure
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var particles: CPUParticles2D = $CPUParticles2D if has_node("CPUParticles2D") else null
@onready var glow_particles: CPUParticles2D = $GlowParticles if has_node("GlowParticles") else null
@onready var spark_particles: CPUParticles2D = $SparkParticles if has_node("SparkParticles") else null
@onready var audio_player: AudioStreamPlayer2D = $AudioPlayer if has_node("AudioPlayer") else null

# Base color for event portal (red/orange theme to differentiate from zone wormholes)
var base_modulate: Color = Color(1.0, 0.4, 0.2, 1.0)  # Orange/red for events

func _ready():
	z_index = -5  # Behind units
	# Setup visual like wormhole
	setup_visual()
	print("EventSpawnPortal _ready() called")

func setup(duration: float, spawn_list: Array):
	"""Initialize portal with warning duration and entities to spawn"""
	print("EventSpawnPortal.setup() called with duration: ", duration, " entities: ", spawn_list.size())
	warning_duration = duration
	entities_to_spawn = spawn_list
	current_state = PortalState.OPENING
	state_timer = 0.0
	
	# Setup visual if not already done
	setup_visual()
	
	# Start opening animation
	start_opening_animation()

func _process(delta: float):
	state_timer += delta
	
	# Shader handles rotation internally, so no manual rotation needed
	
	match current_state:
		PortalState.OPENING:
			process_opening(delta)
		PortalState.SPAWNING:
			process_spawning(delta)
		PortalState.CLOSING:
			process_closing(delta)

func start_opening_animation():
	"""Begin portal opening sequence"""
	print("Portal starting opening animation")
	current_state = PortalState.OPENING
	
	# Start from zero scale
	scale = Vector2.ZERO
	modulate.a = 0.0
	
	print("Portal initial scale: ", scale, " alpha: ", modulate.a)
	
	# Play opening sound
	if AudioManager:
		AudioManager.play_portal_sound("opening", global_position)
	
	# Tween scale and opacity over warning duration
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Grow to full size with elastic easing
	tween.tween_property(self, "scale", Vector2.ONE, warning_duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Fade in (but keep semi-transparent)
	tween.tween_property(self, "modulate:a", 0.8, warning_duration * 0.3)

func process_opening(delta: float):
	"""Update opening animation"""
	# Gradually increase particle intensity (similar to wormhole)
	if particles:
		var progress = state_timer / warning_duration
		particles.amount = int(lerp(0, 30, progress))
		particles.emitting = true
	
	if glow_particles:
		var progress = state_timer / warning_duration
		glow_particles.amount = int(lerp(0, 15, progress))
		glow_particles.emitting = true
	
	# Check if opening complete
	if state_timer >= warning_duration:
		current_state = PortalState.OPEN
		portal_fully_opened.emit()

func on_countdown_complete():
	"""Called when warning countdown reaches 0 - begin spawning"""
	current_state = PortalState.SPAWNING
	spawn_timer = 0.0
	current_spawn_index = 0
	
	# Trigger spark burst
	if spark_particles:
		spark_particles.restart()
	
	# Spawn first entity immediately
	spawn_next_entity()

func process_spawning(delta: float):
	"""Spawn entities one by one with delay"""
	spawn_timer += delta
	
	if spawn_timer >= spawn_delay_between:
		spawn_timer = 0.0
		spawn_next_entity()

func spawn_next_entity():
	"""Spawn the next entity in the queue"""
	if current_spawn_index >= entities_to_spawn.size():
		# All entities spawned - start closing
		start_closing_animation()
		return
	
	var entity = entities_to_spawn[current_spawn_index]
	current_spawn_index += 1
	
	if not is_instance_valid(entity):
		return
	
	# Position entity at portal center with small random offset
	entity.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	
	# Add to scene tree
	var zone_id = ZoneManager.current_zone_id if ZoneManager else 1
	var zone_layer = ZoneManager.get_zone(zone_id).layer_node if ZoneManager else null
	
	if zone_layer:
		# Determine container based on entity type
		var container = null
		if entity is BaseUnit:
			container = zone_layer.get_node_or_null("Entities/Units")
		elif entity.is_in_group("loot"):
			container = zone_layer.get_node_or_null("Entities/Effects")
			if not container:
				container = zone_layer.get_node_or_null("Entities")
		
		if container:
			container.add_child(entity)
			
			# Register with EntityManager if it's a unit
			if entity is BaseUnit and EntityManager:
				EntityManager.register_unit(entity, zone_id)
	
	# Visual feedback
	spawn_flash_effect()
	
	# Play spawn sound
	if AudioManager:
		AudioManager.play_portal_sound("spawn", global_position)
	
	# Spark burst on spawn
	if spark_particles:
		spark_particles.restart()
	
	entity_spawned.emit(entity)

func spawn_flash_effect():
	"""Create flash effect when entity spawns"""
	if sprite and sprite.material is ShaderMaterial:
		var mat = sprite.material as ShaderMaterial
		# Flash bright using shader parameters
		mat.set_shader_parameter("base_color", base_modulate * 2.0)
		var tween = create_tween()
		tween.tween_method(
			func(val): mat.set_shader_parameter("base_color", base_modulate * val),
			2.0, 1.0, 0.3
		)

func start_closing_animation():
	"""Begin portal closing sequence"""
	current_state = PortalState.CLOSING
	state_timer = 0.0
	
	# Play closing sound
	if AudioManager:
		AudioManager.play_portal_sound("closing", global_position)
	
	# Shrink and fade out
	var close_duration = 2.0
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Shrink to zero
	tween.tween_property(self, "scale", Vector2.ZERO, close_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, close_duration)
	
	# Cleanup when done
	tween.finished.connect(on_portal_closed)

func process_closing(delta: float):
	"""Update closing animation"""
	# Reduce particle amounts
	if particles:
		var progress = state_timer / 2.0  # 2 second close
		particles.amount = int(lerp(30, 0, progress))
	
	if glow_particles:
		var progress = state_timer / 2.0
		glow_particles.amount = int(lerp(15, 0, progress))

func on_portal_closed():
	"""Portal fully closed - cleanup"""
	current_state = PortalState.CLOSED
	portal_closed.emit()
	queue_free()

func setup_visual():
	"""Setup portal visuals using same implementation as Wormhole"""
	if sprite:
		# Load the wormhole shader
		var shader = load("res://shaders/wormhole_object.gdshader")
		if shader:
			var material = ShaderMaterial.new()
			material.shader = shader
			material.set_shader_parameter("base_color", base_modulate)
			
			# Use similar parameters to depth wormholes
			material.set_shader_parameter("swirl_strength", 8.0)
			material.set_shader_parameter("core_size", 0.2)
				
			sprite.material = material
			
			# Use a simple placeholder texture for the shader to work on
			var image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
			image.fill(Color.WHITE)
			var texture = ImageTexture.create_from_image(image)
			sprite.texture = texture
			sprite.scale = Vector2(1.5, 1.5)
			
			# Reset rotation as shader handles rotation internally
			sprite.rotation = 0.0
		else:
			print("EventSpawnPortal: Failed to load shader!")
			# Fallback to simple circle if shader fails
			sprite.modulate = base_modulate
			var image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
			image.fill(Color.TRANSPARENT)
			for x in range(128):
				for y in range(128):
					var dx = x - 64
					var dy = y - 64
					var dist = sqrt(dx * dx + dy * dy)
					if dist < 50:
						image.set_pixel(x, y, Color(1, 1, 1, 1))
			sprite.texture = ImageTexture.create_from_image(image)
	
	# Setup swirling particles (same as wormhole)
	if particles:
		particles.emitting = true
		particles.amount = 30
		particles.lifetime = 3.0
		particles.explosiveness = 0.0
		particles.randomness = 0.5
		
		# Orbital motion
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 60.0
		
		particles.direction = Vector2(0, 0)
		particles.spread = 180.0
		particles.initial_velocity_min = 20.0
		particles.initial_velocity_max = 40.0
		
		# Swirl effect using tangential acceleration
		particles.tangential_accel_min = 50.0
		particles.tangential_accel_max = 100.0
		
		# Color
		particles.color = base_modulate
		particles.color_ramp = create_portal_gradient()
		
		# Scale
		particles.scale_amount_min = 2.0
		particles.scale_amount_max = 4.0
		
		# Fade
		particles.color.a = 0.8
	
	# Setup glow particles (same as wormhole)
	if glow_particles:
		glow_particles.emitting = true
		glow_particles.amount = 15
		glow_particles.lifetime = 2.0
		glow_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		glow_particles.emission_sphere_radius = 40.0
		
		glow_particles.direction = Vector2(0, 0)
		glow_particles.spread = 180.0
		glow_particles.initial_velocity_min = 5.0
		glow_particles.initial_velocity_max = 15.0
		
		glow_particles.color = Color(1.0, 1.0, 1.0, 0.6)
		glow_particles.scale_amount_min = 1.0
		glow_particles.scale_amount_max = 2.0

func create_portal_gradient() -> Gradient:
	"""Create color gradient for particles"""
	var gradient = Gradient.new()
	gradient.add_point(0.0, base_modulate)
	gradient.add_point(0.5, base_modulate * 1.2)
	gradient.add_point(1.0, Color(base_modulate.r, base_modulate.g, base_modulate.b, 0.0))
	return gradient

