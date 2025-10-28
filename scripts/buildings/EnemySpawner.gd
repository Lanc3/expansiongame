extends StaticBody2D
class_name EnemySpawner
## Enemy spawner building that generates enemy units over time

signal unit_spawned(unit: Node2D)
signal spawner_destroyed()

# Spawner properties
@export var max_health: float = 500.0
@export var spawn_interval: float = 30.0  # Seconds between spawns
@export var zone_id: String = ""
@export var team_id: int = 1  # Enemy team
@export var boss_spawn_chance: float = 0.05  # 5% chance to spawn boss

var current_health: float
var spawn_timer: float = 0.0
var spawned_units: Array[Node2D] = []
var is_destroyed: bool = false
var regeneration_timer: float = 0.0
var regeneration_delay: float = 300.0  # 5 minutes

# Performance optimization
var processing_active: bool = true

# Enemy unit scenes
var fighter_scene: PackedScene
var cruiser_scene: PackedScene
var bomber_scene: PackedScene

# Visual components
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var health_bar: ProgressBar = $HealthBar if has_node("HealthBar") else null
@onready var spawn_particles: CPUParticles2D = $SpawnParticles if has_node("SpawnParticles") else null
@onready var core_glow: Sprite2D = $CoreGlow if has_node("CoreGlow") else null

func _ready():
	current_health = max_health
	
	# Load enemy scenes
	fighter_scene = load("res://scenes/units/enemies/EnemyFighter.tscn")
	cruiser_scene = load("res://scenes/units/enemies/EnemyCruiser.tscn")
	bomber_scene = load("res://scenes/units/enemies/EnemyBomber.tscn")
	
	# Add to groups
	add_to_group("enemies")
	add_to_group("enemy_buildings")
	add_to_group("spawners")
	
	# Setup collision
	collision_layer = 2  # Buildings layer
	collision_mask = 0
	
	# Initialize visuals
	update_health_bar()
	
	# Start spawn timer with small random offset
	spawn_timer = randf_range(5.0, 15.0)
	
	

func set_processing_active(active: bool):
	"""Set processing state for optimization"""
	processing_active = active

func _process(delta: float):
	# Skip processing if in inactive zone
	if not processing_active:
		return
	
	if is_destroyed:
		# Handle regeneration
		regeneration_timer += delta
		if regeneration_timer >= regeneration_delay:
			regenerate()
		return
	
	# Update spawn timer
	spawn_timer += delta
	
	# Pulsing glow effect
	if core_glow:
		var pulse = 0.6 + sin(Time.get_ticks_msec() * 0.003) * 0.4
		core_glow.modulate.a = pulse
	
	# Check if time to spawn
	if spawn_timer >= spawn_interval:
		attempt_spawn()
		spawn_timer = 0.0
	
	# Clean up destroyed units from tracking
	clean_spawned_units()

func attempt_spawn():
	"""Try to spawn a new enemy unit"""
	# Check max unit cap
	var max_units = get_max_units_for_zone()
	var active_units = count_active_units()
	
	if active_units >= max_units:
		
		return
	
	# Check if spawning a boss
	var is_boss_spawn = randf() < boss_spawn_chance
	
	# Determine which enemy type to spawn
	var enemy_scene = get_spawn_type_for_zone(is_boss_spawn)
	if not enemy_scene:
		return
	
	# Spawn the unit
	spawn_enemy_unit(enemy_scene, is_boss_spawn)

func spawn_enemy_unit(enemy_scene: PackedScene, is_boss: bool = false):
	"""Spawn an enemy unit at spawner location"""
	var enemy = enemy_scene.instantiate()
	
	# Position near spawner with random offset
	var spawn_offset = Vector2(
		randf_range(-80, 80),
		randf_range(-80, 80)
	)
	enemy.global_position = global_position + spawn_offset
	
	# Set patrol center to spawner location
	if enemy.has_method("set"):
		enemy.patrol_center = global_position
	
	# Set zone_id metadata for planet finding
	enemy.set_meta("zone_id", zone_id)
	
	# Mark as boss if appropriate
	if is_boss:
		enemy.set_meta("is_boss", true)
		enemy.scale *= 1.5  # Visually larger
	
	# Add to scene tree
	var zone_layer = ZoneManager.get_zone(zone_id).layer_node
	if zone_layer:
		var units_container = zone_layer.get_node_or_null("Entities/Units")
		if units_container:
			units_container.add_child(enemy)
			
			# Track spawned unit
			spawned_units.append(enemy)
			
			# Register with EntityManager
			if EntityManager.has_method("register_unit"):
				EntityManager.register_unit(enemy, zone_id)
			
			# Spawn visual effect
			play_spawn_animation()
			
			unit_spawned.emit(enemy)
			

func get_spawn_type_for_zone(is_boss: bool = false) -> PackedScene:
	"""Determine which enemy type to spawn based on zone"""
	# Get zone difficulty
	var difficulty = 1
	if ZoneManager and not zone_id.is_empty():
		var zone = ZoneManager.get_zone(zone_id)
		if not zone.is_empty():
			difficulty = zone.difficulty
	
	# Boss spawns get upgraded enemy types
	if is_boss:
		if difficulty <= 3:
			return cruiser_scene  # Cruiser boss in early zones
		elif difficulty <= 6:
			return bomber_scene  # Bomber boss in mid zones
		else:
			return bomber_scene  # Still bomber but with boss stats
	
	# Normal spawns
	if difficulty <= 3:
		# Difficulty 2-3: Fighters only
		return fighter_scene
	elif difficulty <= 5:
		# Difficulty 4-5: Fighters + Cruisers
		if randf() < 0.6:
			return fighter_scene
		else:
			return cruiser_scene
	else:
		# Difficulty 6-9: All types
		var roll = randf()
		if roll < 0.4:
			return fighter_scene
		elif roll < 0.75:
			return cruiser_scene
		else:
			return bomber_scene

func get_max_units_for_zone() -> int:
	"""Calculate max units this spawner can have active"""
	# Get zone difficulty
	var difficulty = 1
	if ZoneManager and not zone_id.is_empty():
		var zone = ZoneManager.get_zone(zone_id)
		if not zone.is_empty():
			difficulty = zone.difficulty
	return difficulty * 5  # Difficulty 2 = 10, Difficulty 3 = 15, etc.

func count_active_units() -> int:
	"""Count how many spawned units are still alive"""
	var count = 0
	for unit in spawned_units:
		if is_instance_valid(unit):
			count += 1
	return count

func clean_spawned_units():
	"""Remove invalid unit references"""
	spawned_units = spawned_units.filter(func(unit): return is_instance_valid(unit))

func take_damage(amount: float, attacker: Node2D = null):
	"""Handle damage to spawner"""
	if is_destroyed:
		return
	
	current_health -= amount
	update_health_bar()
	
	# Visual feedback
	if sprite:
		# Flash red
		sprite.modulate = Color(1.5, 0.5, 0.5, 1)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self):
			sprite.modulate = Color(1, 1, 1, 1)
	
	if current_health <= 0:
		die()

func die():
	"""Spawner destroyed"""
	is_destroyed = true
	regeneration_timer = 0.0
	
	# Hide visuals
	if sprite:
		sprite.visible = false
	if core_glow:
		core_glow.visible = false
	if health_bar:
		health_bar.visible = false
	
	# Disable collision
	set_collision_layer_value(2, false)
	
	# Explosion effect (will be added later)
	
	
	spawner_destroyed.emit()

func regenerate():
	"""Regenerate the spawner after destruction"""
	is_destroyed = false
	regeneration_timer = 0.0
	current_health = max_health * 0.5  # Regenerate at 50% HP
	
	# Show visuals
	if sprite:
		sprite.visible = true
	if core_glow:
		core_glow.visible = true
	if health_bar:
		health_bar.visible = true
	
	# Enable collision
	set_collision_layer_value(2, true)
	
	update_health_bar()
	play_spawn_animation()
	


func update_health_bar():
	"""Update health bar visual"""
	if health_bar:
		health_bar.value = (current_health / max_health) * 100.0
		health_bar.visible = current_health < max_health

func play_spawn_animation():
	"""Play spawn visual effect"""
	if spawn_particles:
		spawn_particles.emitting = true
	
	# Glow flash
	if core_glow:
		core_glow.modulate = Color(1, 0.5, 0.5, 1)
		var tween = create_tween()
		tween.tween_property(core_glow, "modulate:a", 0.8, 0.5)
