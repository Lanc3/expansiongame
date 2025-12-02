extends BaseUnit
class_name MiningStation

const SCOUT_SCENE: PackedScene = preload("res://scenes/units/ScoutDrone.tscn")
const MINING_DRONE_SCENE: PackedScene = preload("res://scenes/units/MiningDrone.tscn")

@export var scan_radius: float = 700.0
@export var scan_interval: float = 1.5
@export var slow_move_speed: float = 35.0

var scan_timer: float = 0.0
var scan_indicator: Line2D = null
var zone_layer: Node = null

var scout_drones: Array[ScoutDrone] = []
var mining_drones: Array[MiningDrone] = []
var scan_targets: Array = []
var mining_queue: Array = []
var scout_assign_index: int = 0
var miner_assign_index: int = 0
var status_label: Label = null

func _ready():
	super._ready()
	unit_name = "Mining Station"
	max_health = 1800.0
	current_health = max_health
	move_speed = slow_move_speed
	vision_range = max(vision_range, scan_radius)
	collision_layer = 2
	collision_mask = 0

	add_to_group("buildings")
	add_to_group("player_buildings")
	add_to_group("mining_stations")

	if ZoneManager:
		zone_id = ZoneManager.get_unit_zone(self)
		_resolve_zone_layer()

	if EntityManager:
		EntityManager.register_building(self, zone_id)

	_create_scan_indicator()
	_spawn_initial_drones()
	_create_status_label()

func _process(delta: float):
	super._process(delta)
	scan_timer += delta
	if scan_timer >= scan_interval:
		scan_timer = 0.0
		_scan_area_for_asteroids()
	_update_mining_queue()
	_update_status_label()

func _create_scan_indicator():
	if scan_indicator and is_instance_valid(scan_indicator):
		scan_indicator.queue_free()

	scan_indicator = Line2D.new()
	scan_indicator.name = "ScanIndicator"
	scan_indicator.z_index = -1
	scan_indicator.width = 2.0
	scan_indicator.default_color = Color(0.2, 0.6, 1.0, 0.4)
	add_child(scan_indicator)

	_update_scan_indicator()

func _create_status_label():
	status_label = Label.new()
	status_label.name = "MiningStationStatus"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.position = Vector2(0, -110)
	status_label.top_level = false
	status_label.z_index = 200
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	add_child(status_label)

func _update_status_label():
	if not status_label:
		return

	status_label.text = "Scan: %d  Mine: %d" % [scan_targets.size(), mining_queue.size()]

func _update_scan_indicator():
	if not scan_indicator:
		return

	var points := PackedVector2Array()
	var segments := 32
	for i in range(segments + 1):
		var angle := (TAU * i) / segments
		var point := Vector2(cos(angle), sin(angle)) * scan_radius
		points.append(point)
	scan_indicator.points = points

func _scan_area_for_asteroids():
	if not EntityManager or zone_id == "":
		return

	var zone_resources: Array = EntityManager.resources_by_zone.get(zone_id, [])
	for resource in zone_resources:
		if not is_instance_valid(resource):
			continue
		if resource.is_scanned or resource.is_depleted():
			continue
		if resource in mining_queue:
			continue
		var distance := global_position.distance_to(resource.global_position)
		if distance <= scan_radius:
			if resource in scan_targets:
				continue
			scan_targets.append(resource)
			_assign_scout_to_resource(resource)
			print("MiningStation: Assigned scout to asteroid %s" % resource.name)

func _update_mining_queue():
	if scan_targets.is_empty():
		return

	var completed: Array = []
	for resource in scan_targets:
		if not is_instance_valid(resource):
			completed.append(resource)
			continue
		if resource.is_scanned:
			if resource not in mining_queue:
				mining_queue.append(resource)
				_assign_miner_to_resource(resource)
				print("MiningStation: Assigned miner to asteroid %s" % resource.name)
			completed.append(resource)

	for resource in completed:
		scan_targets.erase(resource)

func _resolve_zone_layer():
	if not ZoneManager or zone_id == "":
		return

	var zone_data = ZoneManager.get_zone(zone_id)
	if zone_data:
		zone_layer = zone_data.get("layer_node", null)

func _spawn_initial_drones():
	_clear_station_drones()

	var scout_offsets := [Vector2(120, -40), Vector2(120, 40)]
	for offset in scout_offsets:
		var scout = SCOUT_SCENE.instantiate() as ScoutDrone
		_prepare_station_drone(scout, offset)
		scout_drones.append(scout)

	var miner_offsets := [Vector2(80, -60), Vector2(80, 0), Vector2(80, 60)]
	for offset in miner_offsets:
		var miner = MINING_DRONE_SCENE.instantiate() as MiningDrone
		_prepare_station_drone(miner, offset)
		mining_drones.append(miner)

func _clear_station_drones():
	for drone in scout_drones + mining_drones:
		if is_instance_valid(drone):
			drone.queue_free()
	scout_drones.clear()
	mining_drones.clear()

func _prepare_station_drone(drone: Node2D, offset: Vector2):
	drone.global_position = global_position + offset
	if drone.has_method("set_meta"):
		drone.set_meta("station_drone", true)
		drone.set_meta("command_source", self)
	drone.team_id = team_id
	_add_unit_to_zone(drone)

func _assign_scout_to_resource(resource: Node2D):
	if scout_drones.is_empty():
		return

	var scout: ScoutDrone = _get_next_scout()
	if scout and scout.has_method("start_scanning"):
		if scout.has_method("clear_commands"):
			scout.clear_commands()
		scout.start_scanning(resource)

func _assign_miner_to_resource(resource: Node2D):
	if mining_drones.is_empty():
		return

	var miner: MiningDrone = _get_next_miner()
	if miner and miner.has_method("start_mining"):
		if miner.has_method("clear_commands"):
			miner.clear_commands()
		miner.start_mining(resource)

func _get_next_scout() -> ScoutDrone:
	for _i in range(scout_drones.size()):
		var index = scout_assign_index % scout_drones.size()
		scout_assign_index += 1
		var scout := scout_drones[index]
		if is_instance_valid(scout):
			return scout
	return null

func _get_next_miner() -> MiningDrone:
	for _i in range(mining_drones.size()):
		var index = miner_assign_index % mining_drones.size()
		miner_assign_index += 1
		var miner := mining_drones[index]
		if is_instance_valid(miner):
			return miner
	return null

func _add_unit_to_zone(unit: Node2D):
	var container := _get_units_container()
	if container:
		container.add_child(unit)
	else:
		get_tree().current_scene.add_child(unit)

func _get_units_container() -> Node:
	if zone_layer and is_instance_valid(zone_layer):
		var units_node := zone_layer.get_node_or_null("Entities/Units")
		if units_node:
			return units_node

	var game_scene = get_tree().current_scene
	if game_scene:
		var world_layer = game_scene.get_node_or_null("WorldLayer")
		if world_layer:
			var entities = world_layer.get_node_or_null("Entities/Units")
			if entities:
				return entities

	return null

func deposit_resources(common: float, rare: float, exotic: float) -> bool:
	"""Allow mining drones to deposit into the station"""
	if ResourceManager:
		ResourceManager.add_resources(common, rare, exotic)
	return true
