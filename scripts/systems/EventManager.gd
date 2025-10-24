extends Node
## Manages random events (combat waves, discoveries, environmental hazards)

signal event_triggered(event_data: Dictionary)
signal event_warning(event_data: Dictionary, time_until_start: float)
signal event_completed(event_data: Dictionary)

# Event timing
var time_based_timer: float = 0.0
const TIME_BASED_INTERVAL: float = 300.0  # 5 minutes

# Activity tracking
var asteroids_mined: int = 0
var objects_scanned: int = 0
const MINING_THRESHOLD: int = 50
const SCANNING_THRESHOLD: int = 30

# Zone entry tracking
var last_zone_id: int = 1
var zone_events_triggered: Dictionary = {}  # Track events per zone

# Active events
var active_events: Array[Dictionary] = []

# Event types registry
var event_types: Dictionary = {}

func _ready():
	register_default_events()
	
	# Connect to game systems (deferred to ensure they exist)
	call_deferred("connect_to_game_systems")

func connect_to_game_systems():
	"""Connect to various game systems for event triggers"""
	if ZoneManager:
		if not ZoneManager.zone_switched.is_connected(_on_zone_changed):
			ZoneManager.zone_switched.connect(_on_zone_changed)

func _process(delta: float):
	time_based_timer += delta
	
	# Check time-based events
	if time_based_timer >= TIME_BASED_INTERVAL:
		time_based_timer = 0.0
		try_trigger_time_event()
	
	# Update active events
	update_active_events(delta)

func register_default_events():
	"""Register built-in event types"""
	register_event("pirate_ambush", {
		"type": "combat_wave",
		"warning_time": 15.0,
		"enemies": ["fighter", "fighter", "cruiser"],
		"spawn_radius": 400.0,
		"description": "⚠️ Pirate Ambush Detected!"
	})
	
	register_event("alien_swarm", {
		"type": "combat_wave",
		"warning_time": 20.0,
		"enemies": ["fighter", "fighter", "fighter", "fighter", "bomber"],
		"spawn_radius": 500.0,
		"description": "⚠️ Alien Swarm Incoming!"
	})
	
	register_event("derelict_ship", {
		"type": "discovery",
		"warning_time": 5.0,
		"loot_bonus": 3.0,
		"description": "📡 Derelict Ship Detected"
	})
	
	register_event("resource_cache", {
		"type": "discovery",
		"warning_time": 3.0,
		"resource_bonus": {"amount": 200, "rarity_range": [20, 39]},
		"description": "💎 Resource Cache Located"
	})
	
	register_event("asteroid_storm", {
		"type": "environmental",
		"warning_time": 10.0,
		"duration": 30.0,
		"damage_per_second": 5.0,
		"description": "🌪️ Asteroid Storm Approaching!"
	})
	
	register_event("boss_encounter", {
		"type": "combat_wave",
		"warning_time": 25.0,
		"enemies": ["boss_cruiser", "fighter", "fighter"],
		"spawn_radius": 600.0,
		"description": "💀 BOSS ENCOUNTER!"
	})

func register_event(event_id: String, event_data: Dictionary):
	"""Register a new event type (extendable for future events)"""
	event_types[event_id] = event_data

func try_trigger_time_event():
	"""Try to trigger a time-based event"""
	if not ZoneManager:
		return
	
	var zone_id = ZoneManager.current_zone_id
	
	# 30% chance to trigger event
	if randf() < 0.3:
		var event_id = pick_random_event_for_zone(zone_id)
		trigger_event(event_id)

func try_trigger_activity_event(activity_type: String):
	"""Try to trigger activity-based event"""
	if not ZoneManager:
		return
	
	var zone_id = ZoneManager.current_zone_id
	
	# Different events for different activities
	if activity_type == "mining":
		if asteroids_mined >= MINING_THRESHOLD:
			asteroids_mined = 0
			if randf() < 0.4:  # 40% chance
				trigger_event("resource_cache")
	
	elif activity_type == "scanning":
		if objects_scanned >= SCANNING_THRESHOLD:
			objects_scanned = 0
			if randf() < 0.5:  # 50% chance
				trigger_event("derelict_ship")

func try_trigger_zone_entry_event(zone_id: int):
	"""Trigger event when entering new zone"""
	# Don't re-trigger in same zone
	if zone_events_triggered.get(zone_id, false):
		return
	
	# Higher zones = more likely to trigger
	var chance = 0.2 + (zone_id * 0.05)  # 20% + 5% per zone
	if randf() < chance:
		zone_events_triggered[zone_id] = true
		var event_id = pick_random_event_for_zone(zone_id)
		trigger_event(event_id)

func pick_random_event_for_zone(zone_id: int) -> String:
	"""Pick appropriate event based on zone difficulty"""
	var available_events = []
	
	if zone_id <= 3:
		available_events = ["pirate_ambush", "resource_cache", "derelict_ship"]
	elif zone_id <= 6:
		available_events = ["pirate_ambush", "alien_swarm", "asteroid_storm", "resource_cache"]
	else:
		available_events = ["alien_swarm", "boss_encounter", "asteroid_storm", "derelict_ship"]
	
	return available_events[randi() % available_events.size()]

func trigger_event(event_id: String):
	"""Trigger an event with warning period"""
	if not event_id in event_types:
		return
	
	var event_data = event_types[event_id].duplicate(true)
	event_data["id"] = event_id
	event_data["state"] = "warning"
	event_data["timer"] = event_data.get("warning_time", 10.0)
	
	# Pick spawn location (near player fleet)
	event_data["location"] = pick_event_location()
	
	# Create portal at event location DURING warning
	var portal = create_spawn_portal(event_data)
	event_data["portal"] = portal
	
	active_events.append(event_data)
	
	# Emit warning
	event_warning.emit(event_data, event_data["warning_time"])
	
	# Audio/visual warning
	show_event_warning(event_data)

func pick_event_location() -> Vector2:
	"""Pick location for event near player units"""
	var player_units = get_tree().get_nodes_in_group("units").filter(
		func(u): return u.team_id == 0
	)
	
	print("Finding event location - player units found: ", player_units.size())
	
	if player_units.is_empty():
		# Fallback: use camera position
		var camera = get_tree().root.get_camera_2d()
		if camera:
			print("No player units, using camera position: ", camera.global_position)
			return camera.global_position + Vector2(randf_range(-400, 400), randf_range(-400, 400))
		return Vector2(500, 500)  # Default fallback
	
	# Pick random player unit and offset
	var unit = player_units[randi() % player_units.size()]
	var offset = Vector2(randf_range(-600, 600), randf_range(-600, 600))
	var event_pos = unit.global_position + offset
	print("Event location chosen: ", event_pos, " (near unit at ", unit.global_position, ")")
	return event_pos

func show_event_warning(event_data: Dictionary):
	"""Show on-screen warning with audio/visual"""
	# Play warning sound
	if AudioManager:
		AudioManager.play_sound("ui_warning")
	
	# Show notification UI
	if FeedbackManager and FeedbackManager.has_method("show_event_notification"):
		FeedbackManager.show_event_notification(
			event_data["description"],
			event_data["location"],
			event_data["warning_time"]
		)

func update_active_events(delta: float):
	"""Update all active events"""
	var events_to_remove = []
	
	for event in active_events:
		event["timer"] -= delta
		
		if event["state"] == "warning" and event["timer"] <= 0:
			# Warning over - start event
			start_event(event)
			event["state"] = "active"
			event["timer"] = event.get("duration", 60.0)
		
		elif event["state"] == "active" and event["timer"] <= 0:
			# Event complete
			complete_event(event)
			events_to_remove.append(event)
	
	# Remove completed events
	for event in events_to_remove:
		active_events.erase(event)

func start_event(event_data: Dictionary):
	"""Start the actual event"""
	# Portal is already created and visible during warning
	# Signal it to begin spawning
	if "portal" in event_data and is_instance_valid(event_data["portal"]):
		event_data["portal"].on_countdown_complete()
	else:
		# Fallback if no portal - use old direct spawn method
		match event_data["type"]:
			"combat_wave":
				spawn_combat_wave(event_data)
			"discovery":
				spawn_discovery(event_data)
			"environmental":
				start_environmental_hazard(event_data)
	
	event_triggered.emit(event_data)

func spawn_combat_wave(event_data: Dictionary):
	"""Spawn enemy wave at event location"""
	if not ZoneManager:
		return
	
	var location = event_data["location"]
	var zone_id = ZoneManager.current_zone_id
	
	for enemy_type in event_data["enemies"]:
		var enemy_scene = load_enemy_scene(enemy_type)
		if enemy_scene:
			var enemy = enemy_scene.instantiate()
			enemy.global_position = location + Vector2(randf_range(-100, 100), randf_range(-100, 100))
			enemy.set_meta("zone_id", zone_id)
			enemy.set_meta("from_event", true)
			
			# Boss variants
			if "boss" in enemy_type:
				enemy.set_meta("is_boss", true)
				enemy.scale *= 1.5
			
			# Add to scene
			var zone_layer = ZoneManager.get_zone(zone_id).layer_node
			if zone_layer:
				var units_container = zone_layer.get_node_or_null("Entities/Units")
				if units_container:
					units_container.add_child(enemy)
					
					# Register with EntityManager
					if EntityManager:
						EntityManager.register_unit(enemy, zone_id)

func spawn_discovery(event_data: Dictionary):
	"""Spawn discovery loot"""
	if not ZoneManager or not LootDropSystem:
		return
	
	var zone_id = ZoneManager.current_zone_id
	
	# Resource Cache event - specific resources
	if "resource_bonus" in event_data:
		var bonus = event_data["resource_bonus"]
		var drops = {}
		for i in range(3):
			var res_id = randi_range(bonus["rarity_range"][0], bonus["rarity_range"][1])
			drops[res_id] = bonus["amount"] / 3
		
		LootDropSystem.spawn_loot_visual(event_data["location"], drops, zone_id)
		LootDropSystem.loot_dropped.emit(event_data["location"], drops)
	
	# Derelict Ship event - loot bonus multiplier
	elif "loot_bonus" in event_data:
		var bonus_multiplier = event_data["loot_bonus"]
		var drops = {}
		
		# Generate random loot with bonus multiplier
		# Mix of common, rare, and exotic resources
		var base_amount = 100 * bonus_multiplier  # 300 resources total
		
		# Common resources (40%)
		var common_id = randi_range(0, 19)
		drops[common_id] = int(base_amount * 0.4)
		
		# Rare resources (40%)
		var rare_id = randi_range(20, 39)
		drops[rare_id] = int(base_amount * 0.4)
		
		# Exotic resources (20%)
		var exotic_id = randi_range(40, 59)
		drops[exotic_id] = int(base_amount * 0.2)
		
		LootDropSystem.spawn_loot_visual(event_data["location"], drops, zone_id)
		LootDropSystem.loot_dropped.emit(event_data["location"], drops)

func start_environmental_hazard(event_data: Dictionary):
	"""Start environmental damage over time"""
	# TODO: Implement hazard zones that damage units
	pass

func complete_event(event_data: Dictionary):
	"""Event complete"""
	event_completed.emit(event_data)

func create_spawn_portal(event_data: Dictionary) -> EventSpawnPortal:
	"""Create a spawn portal at event location"""
	var portal_scene = load("res://scenes/effects/EventSpawnPortal.tscn")
	if not portal_scene:
		print("ERROR: Could not load EventSpawnPortal.tscn")
		return null
	
	var portal = portal_scene.instantiate()
	print("Portal created: ", portal)
	
	# Position portal at event location
	portal.global_position = event_data["location"]
	print("Portal position set to: ", event_data["location"])
	
	# Build entity list based on event type
	var entities = []
	if event_data["type"] == "combat_wave":
		entities = prepare_combat_entities(event_data)
	elif event_data["type"] == "discovery":
		entities = prepare_discovery_entities(event_data)
	elif event_data["type"] == "environmental":
		entities = prepare_environmental_entities(event_data)
	
	print("Portal will spawn %d entities" % entities.size())
	
	# Setup portal with duration and entity list
	portal.setup(event_data["warning_time"], entities)
	
	# Add to zone
	if ZoneManager:
		var zone_layer = ZoneManager.get_zone(ZoneManager.current_zone_id).layer_node
		if zone_layer:
			var effects_container = zone_layer.get_node_or_null("Entities/Effects")
			if not effects_container:
				effects_container = zone_layer.get_node_or_null("Entities")
			if effects_container:
				effects_container.add_child(portal)
				print("Portal added to scene at: ", portal.global_position)
			else:
				print("ERROR: No effects container found")
		else:
			print("ERROR: No zone layer found")
	
	return portal

func prepare_combat_entities(event_data: Dictionary) -> Array:
	"""Prepare enemy units for combat wave"""
	var entities = []
	var zone_id = ZoneManager.current_zone_id if ZoneManager else 1
	
	for enemy_type in event_data["enemies"]:
		var enemy_scene = load_enemy_scene(enemy_type)
		if enemy_scene:
			var enemy = enemy_scene.instantiate()
			enemy.set_meta("zone_id", zone_id)
			enemy.set_meta("from_event", true)
			
			# Boss variants
			if "boss" in enemy_type:
				enemy.set_meta("is_boss", true)
				enemy.scale *= 1.5
			
			entities.append(enemy)
	
	return entities

func prepare_discovery_entities(event_data: Dictionary) -> Array:
	"""Prepare loot orbs for discovery events"""
	var entities = []
	var zone_id = ZoneManager.current_zone_id if ZoneManager else 1
	
	# Calculate loot based on event type
	var drops = {}
	
	if "resource_bonus" in event_data:
		# Resource Cache event
		var bonus = event_data["resource_bonus"]
		for i in range(3):
			var res_id = randi_range(bonus["rarity_range"][0], bonus["rarity_range"][1])
			drops[res_id] = bonus["amount"] / 3
	
	elif "loot_bonus" in event_data:
		# Derelict Ship event
		var bonus_multiplier = event_data["loot_bonus"]
		var base_amount = 100 * bonus_multiplier
		
		drops[randi_range(0, 19)] = int(base_amount * 0.4)  # Common
		drops[randi_range(20, 39)] = int(base_amount * 0.4)  # Rare
		drops[randi_range(40, 59)] = int(base_amount * 0.2)  # Exotic
	
	# Create loot orbs
	if LootDropSystem:
		for resource_id in drops.keys():
			var amount = drops[resource_id]
			var loot_orb = LootDropSystem.create_loot_orb(
				event_data["location"],
				resource_id,
				amount,
				zone_id
			)
			entities.append(loot_orb)
	
	return entities

func prepare_environmental_entities(event_data: Dictionary) -> Array:
	"""Prepare environmental hazard entities"""
	# Environmental events currently have no spawnable entities
	return []

func load_enemy_scene(enemy_type: String) -> PackedScene:
	"""Load enemy scene by type name"""
	match enemy_type:
		"fighter", "boss_fighter":
			return load("res://scenes/units/enemies/EnemyFighter.tscn")
		"cruiser", "boss_cruiser":
			return load("res://scenes/units/enemies/EnemyCruiser.tscn")
		"bomber", "boss_bomber":
			return load("res://scenes/units/enemies/EnemyBomber.tscn")
	return null

# Activity tracking callbacks
func on_asteroid_mined():
	"""Called when an asteroid is mined"""
	asteroids_mined += 1
	try_trigger_activity_event("mining")

func on_object_scanned():
	"""Called when an object is scanned"""
	objects_scanned += 1
	try_trigger_activity_event("scanning")

func _on_zone_changed(old_zone: int, new_zone: int):
	"""Called when player changes zones"""
	last_zone_id = new_zone
	try_trigger_zone_entry_event(new_zone)
