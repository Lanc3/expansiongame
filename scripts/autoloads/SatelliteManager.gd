extends Node
## Manages deployed reconnaissance and combat satellites across all zones

signal satellite_deployed(satellite: Node2D, zone_id: int)
signal satellite_destroyed(satellite: Node2D, zone_id: int)

# Satellite tracking
var satellites_by_zone: Dictionary = {}  # zone_id -> Array[Satellite]
var all_satellites: Array = []

# Satellite costs
const SATELLITE_DEPLOY_COST = {
	50: 100,  # Lutetium
	62: 80,   # Quantum Crystal
	72: 60    # Spacetime Fabric
}

const COMBAT_SATELLITE_DEPLOY_COST = {
	65: 150,  # Plasma Core
	74: 120,  # Warp Particle
	82: 100   # Chrono Crystal
}

# Satellite properties
const SATELLITE_VISION_RADIUS = 500.0
const SATELLITE_HEALTH = 200.0
const COMBAT_SATELLITE_HEALTH = 400.0
const COMBAT_SATELLITE_DAMAGE = 25.0
const COMBAT_SATELLITE_RANGE = 350.0
const COMBAT_SATELLITE_FIRE_RATE = 2.0  # Shots per second

func _ready():
	# Initialize satellite tracking for all zones
	for zone_id in range(1, 10):
		satellites_by_zone[zone_id] = []
	
	print("SatelliteManager: Initialized")

func can_deploy_satellite() -> bool:
	"""Check if player has unlocked satellite deployment"""
	return ResearchManager and ResearchManager.has_ability("ability_deploy_satellite")

func can_deploy_combat_satellite() -> bool:
	"""Check if player has unlocked combat satellites"""
	return ResearchManager and ResearchManager.has_ability("ability_combat_satellite")

func deploy_satellite(world_pos: Vector2, zone_id: int, is_combat: bool = false) -> Node2D:
	"""Deploy a satellite at the specified position"""
	# Check research
	if not can_deploy_satellite():
		print("SatelliteManager: Satellite deployment not researched")
		return null
	
	if is_combat and not can_deploy_combat_satellite():
		print("SatelliteManager: Combat satellites not researched")
		return null
	
	# Check resources
	var cost = COMBAT_SATELLITE_DEPLOY_COST if is_combat else SATELLITE_DEPLOY_COST
	if not ResourceManager or not ResourceManager.can_afford_cost(cost):
		print("SatelliteManager: Insufficient resources for satellite")
		return null
	
	# Consume resources
	if not ResourceManager.consume_resources(cost):
		return null
	
	# Create satellite
	var satellite = create_satellite_node(world_pos, zone_id, is_combat)
	
	# Track satellite
	satellites_by_zone[zone_id].append(satellite)
	all_satellites.append(satellite)
	
	# Reveal fog of war
	if FogOfWarManager:
		FogOfWarManager.reveal_circle(world_pos, SATELLITE_VISION_RADIUS, zone_id, true)
	
	# Emit signal
	satellite_deployed.emit(satellite, zone_id)
	
	print("SatelliteManager: Deployed %s satellite in zone %d" % ["combat" if is_combat else "reconnaissance", zone_id])
	
	return satellite

func create_satellite_node(world_pos: Vector2, zone_id: int, is_combat: bool) -> Node2D:
	"""Create the actual satellite node"""
	var satellite = StaticBody2D.new()
	satellite.name = "Satellite_%d" % Time.get_ticks_msec()
	satellite.global_position = world_pos
	satellite.collision_layer = 2  # Buildings layer
	satellite.collision_mask = 0
	
	# Add to appropriate zone layer
	var zone_data = ZoneManager.get_zone(zone_id) if ZoneManager else {}
	var zone_layer = zone_data.get("layer_node", null)
	if zone_layer and is_instance_valid(zone_layer):
		var buildings_container = zone_layer.get_node_or_null("Entities/Buildings")
		if buildings_container:
			buildings_container.add_child(satellite)
		else:
			zone_layer.add_child(satellite)
	else:
		# Fallback: add to current scene
		get_tree().current_scene.add_child(satellite)
	
	# Add custom properties
	satellite.set_meta("is_satellite", true)
	satellite.set_meta("satellite_type", "combat" if is_combat else "recon")
	satellite.set_meta("zone_id", zone_id)
	satellite.set_meta("health", COMBAT_SATELLITE_HEALTH if is_combat else SATELLITE_HEALTH)
	satellite.set_meta("max_health", COMBAT_SATELLITE_HEALTH if is_combat else SATELLITE_HEALTH)
	satellite.set_meta("team_id", 0)  # Player team
	
	# Create visual sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	if is_combat:
		# Use a combat-looking sprite (turret-like)
		sprite.texture = load("res://assets/sprites/playerShip3_red.png")
		sprite.modulate = Color(1.0, 0.3, 0.3)
	else:
		# Use a sensor-looking sprite
		sprite.texture = load("res://assets/sprites/ufoBlue.png")
		sprite.modulate = Color(0.3, 0.7, 1.0)
	sprite.scale = Vector2(0.3, 0.3)
	satellite.add_child(sprite)
	
	# Create glow effect
	var glow = Sprite2D.new()
	glow.name = "Glow"
	glow.texture = sprite.texture
	glow.scale = Vector2(0.35, 0.35)
	glow.modulate = Color(0.5, 0.8, 1.0, 0.3) if not is_combat else Color(1.0, 0.3, 0.3, 0.3)
	glow.z_index = -1
	satellite.add_child(glow)
	
	# Create collision shape
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape"
	var circle = CircleShape2D.new()
	circle.radius = 25.0
	collision.shape = circle
	satellite.add_child(collision)
	
	# Create health bar
	var health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.size = Vector2(50, 6)
	health_bar.position = Vector2(-25, -40)
	health_bar.show_percentage = false
	health_bar.value = 100
	satellite.add_child(health_bar)
	
	# Create vision indicator (circle showing range)
	var vision_indicator = create_vision_indicator(is_combat)
	satellite.add_child(vision_indicator)
	
	# Add rotation animation
	var tween = satellite.create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "rotation", TAU, 4.0)
	
	# Combat satellites need attack capability
	if is_combat:
		satellite.set_meta("attack_damage", COMBAT_SATELLITE_DAMAGE)
		satellite.set_meta("attack_range", COMBAT_SATELLITE_RANGE)
		satellite.set_meta("fire_rate", COMBAT_SATELLITE_FIRE_RATE)
		satellite.set_meta("fire_timer", 0.0)
		
		# Add attack processing
		satellite.set_process(true)
		satellite.process.connect(_satellite_combat_process.bind(satellite))
	
	return satellite

func create_vision_indicator(is_combat: bool) -> Node2D:
	"""Create visual indicator showing satellite vision range"""
	var indicator = Node2D.new()
	indicator.name = "VisionIndicator"
	indicator.z_index = -2
	
	# Draw circle showing range
	var line = Line2D.new()
	line.name = "RangeLine"
	line.width = 2.0
	line.default_color = Color(0.3, 0.7, 1.0, 0.3) if not is_combat else Color(1.0, 0.3, 0.3, 0.3)
	
	# Create circle points
	var points = []
	var segments = 32
	for i in range(segments + 1):
		var angle = (i * TAU) / segments
		var point = Vector2(cos(angle), sin(angle)) * SATELLITE_VISION_RADIUS
		points.append(point)
	
	line.points = PackedVector2Array(points)
	indicator.add_child(line)
	
	return indicator

func _satellite_combat_process(delta: float, satellite: StaticBody2D):
	"""Process combat satellite targeting and firing"""
	if not is_instance_valid(satellite):
		return
	
	var fire_timer = satellite.get_meta("fire_timer", 0.0)
	fire_timer += delta
	satellite.set_meta("fire_timer", fire_timer)
	
	var fire_interval = 1.0 / satellite.get_meta("fire_rate", 1.0)
	
	if fire_timer >= fire_interval:
		fire_timer = 0.0
		satellite.set_meta("fire_timer", 0.0)
		
		# Find nearest enemy
		var attack_range = satellite.get_meta("attack_range", 350.0)
		var enemy = find_nearest_enemy(satellite.global_position, attack_range)
		
		if enemy:
			fire_at_target(satellite, enemy)

func find_nearest_enemy(pos: Vector2, range: float) -> Node2D:
	"""Find nearest enemy unit within range"""
	if not EntityManager:
		return null
	
	var nearest_enemy = null
	var nearest_dist = range
	
	var enemies = EntityManager.get_units_by_team(1)  # Team 1 = enemies
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var dist = pos.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_enemy = enemy
	
	return nearest_enemy

func fire_at_target(satellite: StaticBody2D, target: Node2D):
	"""Fire projectile at target"""
	if not is_instance_valid(satellite) or not is_instance_valid(target):
		return
	
	var damage = satellite.get_meta("attack_damage", 25.0)
	
	# Apply damage directly (simple implementation)
	if target.has_method("take_damage"):
		target.take_damage(damage)
	
	# Visual effect: create laser beam
	create_laser_effect(satellite.global_position, target.global_position)

func create_laser_effect(from: Vector2, to: Vector2):
	"""Create visual laser effect"""
	var laser = Line2D.new()
	laser.add_point(from)
	laser.add_point(to)
	laser.width = 3.0
	laser.default_color = Color(1.0, 0.3, 0.3, 0.8)
	laser.z_index = 100
	
	get_tree().current_scene.add_child(laser)
	
	# Fade out and delete
	var tween = laser.create_tween()
	tween.tween_property(laser, "modulate:a", 0.0, 0.2)
	tween.tween_callback(laser.queue_free)

func destroy_satellite(satellite: Node2D):
	"""Remove satellite from tracking and scene"""
	if not is_instance_valid(satellite):
		return
	
	var zone_id = satellite.get_meta("zone_id", 1)
	
	# Remove from tracking
	if zone_id in satellites_by_zone:
		satellites_by_zone[zone_id].erase(satellite)
	all_satellites.erase(satellite)
	
	# Emit signal
	satellite_destroyed.emit(satellite, zone_id)
	
	# Remove from scene
	satellite.queue_free()
	
	print("SatelliteManager: Satellite destroyed in zone %d" % zone_id)

func get_satellites_in_zone(zone_id: int) -> Array:
	"""Get all satellites in a specific zone"""
	if zone_id in satellites_by_zone:
		return satellites_by_zone[zone_id].duplicate()
	return []

func get_satellite_count() -> int:
	"""Get total number of deployed satellites"""
	return all_satellites.size()

# Save/Load support
func get_save_data() -> Dictionary:
	"""Get save data for satellites"""
	var satellite_data = []
	
	for satellite in all_satellites:
		if not is_instance_valid(satellite):
			continue
		
		satellite_data.append({
			"position": {
				"x": satellite.global_position.x,
				"y": satellite.global_position.y
			},
			"zone_id": satellite.get_meta("zone_id", 1),
			"is_combat": satellite.get_meta("satellite_type", "recon") == "combat",
			"health": satellite.get_meta("health", SATELLITE_HEALTH)
		})
	
	return {
		"satellites": satellite_data
	}

func load_save_data(data: Dictionary):
	"""Load satellites from save data"""
	# Clear existing satellites
	for satellite in all_satellites.duplicate():
		if is_instance_valid(satellite):
			satellite.queue_free()
	
	all_satellites.clear()
	for zone_id in satellites_by_zone:
		satellites_by_zone[zone_id].clear()
	
	# Recreate satellites
	if "satellites" in data:
		for sat_data in data.satellites:
			var pos = Vector2(sat_data.position.x, sat_data.position.y)
			var zone_id = sat_data.zone_id
			var is_combat = sat_data.get("is_combat", false)
			var health = sat_data.get("health", SATELLITE_HEALTH)
			
			# Recreate satellite (without consuming resources)
			var satellite = create_satellite_node(pos, zone_id, is_combat)
			satellite.set_meta("health", health)
			
			satellites_by_zone[zone_id].append(satellite)
			all_satellites.append(satellite)
			
			# Restore fog revelation
			if FogOfWarManager:
				FogOfWarManager.reveal_circle(pos, SATELLITE_VISION_RADIUS, zone_id, true)
	
	print("SatelliteManager: Loaded %d satellites" % all_satellites.size())

