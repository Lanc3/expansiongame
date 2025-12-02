extends Node
## Sets up test scenario with units and resources

@export var spawn_command_ship: bool = true
@export var spawn_mining_drones: int = 5
@export var spawn_combat_drones: int = 3
@export var spawn_scout_drones: int = 2
@export var spawn_enemy_units: int = 5

var command_ship_scene = preload("res://scenes/units/CommandShip.tscn")
var mining_drone_scene = preload("res://scenes/units/MiningDrone.tscn")
var combat_drone_scene = preload("res://scenes/units/CombatDrone.tscn")
var scout_drone_scene = preload("res://scenes/units/ScoutDrone.tscn")
var research_building_scene = preload("res://scenes/buildings/ResearchBuilding.tscn")
var builder_drone_scene = preload("res://scenes/units/BuilderDrone.tscn")

func _ready():
	print("TestScenarioSetup: _ready() called")
	
	# Skip initial spawn if loading from save
	if SaveLoadManager and SaveLoadManager.is_loading_save:
		print("TestScenarioSetup: Skipping - loading from save")
		return
	
	if not ZoneManager:
		print("TestScenarioSetup: ERROR - ZoneManager not found!")
		return
	
	# Wait for zones to be initialized
	if not ZoneManager.zones_ready:
		print("TestScenarioSetup: Waiting for zones to be initialized...")
		await ZoneManager.zones_initialized
		print("TestScenarioSetup: Zones initialized signal received!")
	else:
		print("TestScenarioSetup: Zones already ready")
	
	setup_test_scenario()

func setup_test_scenario():
	print("TestScenarioSetup: setup_test_scenario() called")
	
	# Spawn units in starting zone
	if not ZoneManager or ZoneManager.current_zone_id.is_empty():
		print("TestScenarioSetup: ERROR - ZoneManager not found or current_zone_id is empty!")
		print("  ZoneManager exists: %s" % (ZoneManager != null))
		if ZoneManager:
			print("  current_zone_id: '%s'" % ZoneManager.current_zone_id)
		return
	
	print("TestScenarioSetup: Current zone ID: '%s'" % ZoneManager.current_zone_id)
	
	var zone1 = ZoneManager.get_zone(ZoneManager.current_zone_id)
	if zone1.is_empty():
		print("TestScenarioSetup: ERROR - Zone data is empty!")
		print("  Available zones: %s" % ZoneManager.zones_by_id.keys())
		return
	
	print("TestScenarioSetup: Zone data found - %s" % zone1.procedural_name)
	print("  layer_node: %s" % zone1.layer_node)
	
	if not zone1.layer_node:
		print("TestScenarioSetup: ERROR - Zone layer_node is null!")
		return
	
	print("TestScenarioSetup: Layer node found: %s" % zone1.layer_node.name)
	
	var units_node = zone1.layer_node.get_node_or_null("Entities/Units")
	if not units_node:
		print("TestScenarioSetup: ERROR - Units node not found!")
		print("  Layer children: %s" % zone1.layer_node.get_children())
		var entities = zone1.layer_node.get_node_or_null("Entities")
		if entities:
			print("  Entities children: %s" % entities.get_children())
		return
	
	print("TestScenarioSetup: Units node found - spawning units...")
	
	
	# Spawn command ship at center
	if spawn_command_ship:
		var ship = command_ship_scene.instantiate()
		ship.global_position = Vector2.ZERO
		units_node.add_child(ship)
		
	
	# Spawn mining drones in circle
	for i in range(spawn_mining_drones):
		var drone = mining_drone_scene.instantiate()
		var angle = (i / float(spawn_mining_drones)) * TAU
		drone.global_position = Vector2(cos(angle), sin(angle)) * 100
		units_node.add_child(drone)
	
	# Spawn combat drones
	for i in range(spawn_combat_drones):
		var drone = combat_drone_scene.instantiate()
		var angle = (i / float(spawn_combat_drones)) * TAU
		drone.global_position = Vector2(cos(angle), sin(angle)) * 150
		units_node.add_child(drone)
	
	# Spawn scout drones
	for i in range(spawn_scout_drones):
		var drone = scout_drone_scene.instantiate()
		var angle = (i / float(spawn_scout_drones)) * TAU + PI/4
		drone.global_position = Vector2(cos(angle), sin(angle)) * 200
		units_node.add_child(drone)
	
	# Spawn enemy units
	for i in range(spawn_enemy_units):
		var enemy = combat_drone_scene.instantiate()
		enemy.team_id = 1
		if enemy.has_node("Sprite2D"):
			enemy.get_node("Sprite2D").modulate = Color.RED
		enemy.global_position = Vector2(
			randf_range(-800, 800),
			randf_range(-800, 800)
		)
		units_node.add_child(enemy)
	
	var total_units = 0
	if spawn_command_ship: total_units += 1
	total_units += spawn_mining_drones + spawn_combat_drones + spawn_scout_drones + spawn_enemy_units
	
	# Initial fog of war reveal around starting units
	if FogOfWarManager:
		await get_tree().create_timer(0.1).timeout  # Wait for units to fully initialize
		
		# Reveal area around all starting player units
		var player_units = EntityManager.get_units_by_team(0)
		var starting_zone = ZoneManager.current_zone_id if ZoneManager else ""
		for unit in player_units:
			if is_instance_valid(unit):
				var unit_vision = unit.get("vision_range")
				if unit_vision == null:
					unit_vision = 400.0
				if not starting_zone.is_empty():
					FogOfWarManager.reveal_position(starting_zone, unit.global_position, unit_vision)
		
		print("TestScenarioSetup: Initial fog revealed around %d starting units" % player_units.size())

# R key binding removed - now used for missile launcher in ShipComponentPanel
# If you need to test research building spawning, use the Builder Drone UI instead

func spawn_test_research_building():
	"""Spawn a Research Building at camera/mouse position for testing"""
	if not ZoneManager:
		return
	
	var current_zone = ZoneManager.current_zone_id
	var zone_data = ZoneManager.get_zone(current_zone)
	
	if zone_data.is_empty() or not zone_data.layer_node:
		return
	
	var buildings_node = zone_data.layer_node.get_node_or_null("Entities/Buildings")
	if not buildings_node:
		return
	
	# Get camera position or mouse position
	var spawn_pos = Vector2.ZERO
	var camera = get_tree().root.get_camera_2d()
	if camera:
		spawn_pos = camera.global_position
	
	# Spawn the building
	var building = research_building_scene.instantiate()
	building.global_position = spawn_pos
	building.zone_id = current_zone
	building.team_id = 0  # Player team
	buildings_node.add_child(building)
	
	# Register with EntityManager
	if EntityManager:
		EntityManager.register_building(building)
	
	print("TestScenarioSetup: Spawned Research Building at %s in Zone %s (Press R)" % [spawn_pos, current_zone])

func spawn_test_builder():
	"""Spawn a Builder Drone at camera position for testing"""
	if not ZoneManager:
		return
	
	var current_zone = ZoneManager.current_zone_id
	var zone_data = ZoneManager.get_zone(current_zone)
	
	if zone_data.is_empty() or not zone_data.layer_node:
		return
	
	var units_node = zone_data.layer_node.get_node_or_null("Entities/Units")
	if not units_node:
		return
	
	# Get camera position
	var spawn_pos = Vector2.ZERO
	var camera = get_tree().root.get_camera_2d()
	if camera:
		spawn_pos = camera.global_position + Vector2(100, 100)  # Offset slightly
	
	# Spawn the builder
	var builder = builder_drone_scene.instantiate()
	builder.global_position = spawn_pos
	builder.team_id = 0
	units_node.add_child(builder)
	
	print("TestScenarioSetup: Spawned Builder Drone at %s in Zone %s (Press B)" % [spawn_pos, current_zone])
