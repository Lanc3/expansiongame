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

# Visual components
@onready var spiral_sprite: Sprite2D = $SpiralSprite if has_node("SpiralSprite") else null
@onready var vortex_particles: CPUParticles2D = $VortexParticles if has_node("VortexParticles") else null
@onready var ring_particles: CPUParticles2D = $RingParticles if has_node("RingParticles") else null
@onready var spark_particles: CPUParticles2D = $SparkParticles if has_node("SparkParticles") else null
@onready var audio_player: AudioStreamPlayer2D = $AudioPlayer if has_node("AudioPlayer") else null

# Rotation animation
var rotation_speed: float = 2.0  # Radians per second

func _ready():
	z_index = -5  # Behind units
	print("EventSpawnPortal _ready() called")
	print("  - spiral_sprite: ", spiral_sprite)
	print("  - vortex_particles: ", vortex_particles)
	print("  - ring_particles: ", ring_particles)
	print("  - spark_particles: ", spark_particles)

func setup(duration: float, spawn_list: Array):
	"""Initialize portal with warning duration and entities to spawn"""
	print("EventSpawnPortal.setup() called with duration: ", duration, " entities: ", spawn_list.size())
	warning_duration = duration
	entities_to_spawn = spawn_list
	current_state = PortalState.OPENING
	state_timer = 0.0
	
	# Start opening animation
	start_opening_animation()

func _process(delta: float):
	state_timer += delta
	
	# Rotate spiral sprite continuously
	if spiral_sprite:
		spiral_sprite.rotation += rotation_speed * delta
	
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
	
	# Set initial transparency for spiral
	if spiral_sprite:
		spiral_sprite.modulate.a = 0.0
	
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
	
	# Fade in spiral sprite to 50% opacity
	if spiral_sprite:
		var spiral_tween = create_tween()
		spiral_tween.tween_property(spiral_sprite, "modulate:a", 0.5, warning_duration * 0.3)
		start_spiral_pulse()

func process_opening(delta: float):
	"""Update opening animation"""
	# Gradually increase particle intensity
	if vortex_particles:
		var progress = state_timer / warning_duration
		vortex_particles.amount = int(lerp(0, 50, progress))
		vortex_particles.scale_amount_max = lerp(3.0, 5.0, progress)
		vortex_particles.emitting = true
	
	if ring_particles:
		var progress = state_timer / warning_duration
		ring_particles.amount = int(lerp(0, 30, progress))
		ring_particles.emitting = true
	
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
	if spiral_sprite:
		# Flash bright (but maintain transparency at 50%)
		spiral_sprite.modulate = Color(2.0, 2.0, 2.0, 0.7)
		
		var tween = create_tween()
		tween.tween_property(spiral_sprite, "modulate", Color(1.0, 1.0, 1.0, 0.5), 0.3)

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
	if vortex_particles:
		var progress = state_timer / 2.0  # 2 second close
		vortex_particles.amount = int(lerp(50, 0, progress))
	
	if ring_particles:
		var progress = state_timer / 2.0
		ring_particles.amount = int(lerp(30, 0, progress))

func on_portal_closed():
	"""Portal fully closed - cleanup"""
	current_state = PortalState.CLOSED
	portal_closed.emit()
	queue_free()

func start_spiral_pulse():
	"""Pulsing animation for spiral sprite"""
	if not spiral_sprite:
		return
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(spiral_sprite, "modulate:a", 0.35, 0.8)
	tween.tween_property(spiral_sprite, "modulate:a", 0.5, 0.8)

