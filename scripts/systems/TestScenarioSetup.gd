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

func _ready():

	
	# Skip initial spawn if loading from save
	if SaveLoadManager and SaveLoadManager.is_loading_save:
		
		return
	
	if not ZoneManager:
		
		return
	
	# Wait for zones to be initialized
	if not ZoneManager.zones_ready:
		
		await ZoneManager.zones_initialized
	
	
	setup_test_scenario()

func setup_test_scenario():
	# Spawn units in Zone 1
	var zone1 = ZoneManager.get_zone(1)
	if zone1.is_empty() or not zone1.layer_node:
		
		return
	
	var units_node = zone1.layer_node.get_node_or_null("Entities/Units")
	if not units_node:
		
		return
	
	
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
		for unit in player_units:
			if is_instance_valid(unit):
				var unit_vision = unit.get("vision_range")
				if unit_vision == null:
					unit_vision = 400.0
				FogOfWarManager.reveal_position(1, unit.global_position, unit_vision)
		
		print("TestScenarioSetup: Initial fog revealed around %d starting units" % player_units.size())
