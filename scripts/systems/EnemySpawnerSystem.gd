extends Node
## System for placing enemy spawners and turrets in zones

var spawner_scene: PackedScene
var bullet_turret_scene: PackedScene
var laser_turret_scene: PackedScene
var missile_turret_scene: PackedScene

func _ready():
	# Load building scenes
	spawner_scene = load("res://scenes/buildings/EnemySpawner.tscn")
	bullet_turret_scene = load("res://scenes/buildings/BulletTurret.tscn")
	laser_turret_scene = load("res://scenes/buildings/LaserTurret.tscn")
	missile_turret_scene = load("res://scenes/buildings/MissileTurret.tscn")
	
	# Wait for zones to initialize
	await ZoneManager.zones_initialized
	
	
	
	# Setup enemies for zones 2-9
	for zone_id in range(2, 10):
		setup_zone_enemies(zone_id)
	
	

func setup_zone_enemies(zone_id: int):
	"""Create enemy clusters for a zone"""
	if zone_id == 1:
		return  # Zone 1 has no enemies
	
	var cluster_count = zone_id - 1  # Zone 2=1, Zone 3=2, etc.
	
	
	
	for i in range(cluster_count):
		create_enemy_cluster(zone_id, i)

func create_enemy_cluster(zone_id: int, cluster_index: int):
	"""Create a spawner with surrounding turrets"""
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty() or not zone.layer_node:
		
		return
	
	# Get buildings container
	var buildings_container = zone.layer_node.get_node_or_null("Entities/Buildings")
	if not buildings_container:
		
		return
	
	# Calculate cluster position (at zone edges, alternating)
	var cluster_position = get_cluster_position(zone_id, cluster_index)
	
	# Create spawner
	var spawner = spawner_scene.instantiate()
	spawner.global_position = cluster_position
	spawner.zone_id = zone_id
	buildings_container.add_child(spawner)
	
	
	# Create turrets around spawner
	var turret_count = get_turrets_per_cluster(zone_id)
	var turret_types = get_turret_types_for_zone(zone_id)
	
	for j in range(turret_count):
		var turret_offset = get_turret_offset(j, turret_count)
		var turret_position = cluster_position + turret_offset
		var turret_type = turret_types[j % turret_types.size()]
		
		create_turret(turret_type, turret_position, zone_id, buildings_container)

func get_cluster_position(zone_id: int, cluster_index: int) -> Vector2:
	"""Calculate position for enemy cluster at zone edge"""
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty():
		return Vector2.ZERO
	
	var bounds = zone.boundaries
	var cluster_count = zone_id - 1
	
	# Divide the zone perimeter into sections for clusters
	var angle_step = TAU / cluster_count
	var base_angle = angle_step * cluster_index
	
	# Add some randomness to angle
	var angle = base_angle + randf_range(-angle_step * 0.2, angle_step * 0.2)
	
	# Position at 70-90% of the zone radius (near edge but not exactly at boundary)
	var distance_factor = randf_range(0.7, 0.9)
	var radius = (bounds.size.x * 0.5) * distance_factor
	
	var position = Vector2(
		cos(angle) * radius,
		sin(angle) * radius
	)
	
	return position

func get_turrets_per_cluster(zone_id: int) -> int:
	"""Calculate how many turrets per cluster"""
	return clamp(zone_id - 1, 1, 4)  # 1-4 turrets per cluster

func get_turret_types_for_zone(zone_id: int) -> Array:
	"""Determine which turret types are available in this zone"""
	var types = []
	
	if zone_id <= 3:
		# Zones 2-3: Bullet turrets only
		types = ["bullet", "bullet"]
	elif zone_id <= 6:
		# Zones 4-6: Bullet + Laser
		types = ["bullet", "laser", "bullet"]
	else:
		# Zones 7-9: All types
		types = ["bullet", "laser", "missile", "bullet"]
	
	return types

func get_turret_offset(turret_index: int, total_turrets: int) -> Vector2:
	"""Calculate offset position for turret around spawner"""
	var angle = (TAU / total_turrets) * turret_index
	var distance = randf_range(150, 250)  # Distance from spawner
	
	return Vector2(
		cos(angle) * distance,
		sin(angle) * distance
	)

func create_turret(turret_type: String, position: Vector2, zone_id: int, parent: Node):
	"""Instantiate a turret at the given position"""
	var turret: Node2D = null
	
	match turret_type:
		"bullet":
			turret = bullet_turret_scene.instantiate()
		"laser":
			turret = laser_turret_scene.instantiate()
		"missile":
			turret = missile_turret_scene.instantiate()
	
	if turret:
		turret.global_position = position
		turret.zone_id = zone_id
		parent.add_child(turret)
