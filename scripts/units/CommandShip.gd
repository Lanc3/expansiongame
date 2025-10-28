extends BaseUnit
class_name CommandShip

@export var resource_storage_capacity: float = 10000.0

var is_command_ship: bool = true
var stored_common: float = 0.0
var stored_rare: float = 0.0
var stored_exotic: float = 0.0

# Production system
signal production_started(unit_type: String)
signal production_completed(unit_type: String)
signal production_cancelled(index: int)
signal queue_updated()

var production_queue: Array = []  # Array of production orders
var current_production: Dictionary = {}  # Current unit being built
var is_producing: bool = false
var production_timer: float = 0.0
const MAX_QUEUE_SIZE: int = 10

func _ready():
	super._ready()
	unit_name = "Command Ship"
	max_health = 500.0
	current_health = max_health
	move_speed = 20.0
	vision_range = 1600.0  # Command ship has largest vision (doubled from 800)

func _process(delta: float):
	super._process(delta)
	
	if is_producing:
		process_production(delta)

func deposit_resources(common: float, rare: float, exotic: float) -> bool:
	var total_incoming = common + rare + exotic
	var total_stored = stored_common + stored_rare + stored_exotic
	
	if total_stored + total_incoming <= resource_storage_capacity:
		stored_common += common
		stored_rare += rare
		stored_exotic += exotic
		
		# Visual feedback - flash the command ship
		if sprite:
			var deposit_color = Color.YELLOW
			if exotic > 0:
				deposit_color = Color.MAGENTA  # Exotic
			elif rare > 0:
				deposit_color = Color.CYAN  # Rare
			
			FeedbackManager.flash_sprite(sprite, deposit_color, 0.3)
		
		return true
	
	return false

func get_storage_percent() -> float:
	var total = stored_common + stored_rare + stored_exotic
	return (total / resource_storage_capacity) * 100.0

func can_attack() -> bool:
	return true  # Command ship has weapons

func can_mine() -> bool:
	return false

# ============================================================================
# PRODUCTION SYSTEM
# ============================================================================

func process_production(delta: float):
	"""Process current production progress"""
	if current_production.is_empty():
		start_next_production()
		return
	
	production_timer += delta
	current_production.progress = production_timer / current_production.build_time
	
	# Emit update for UI
	queue_updated.emit()
	
	# Check if production complete
	if production_timer >= current_production.build_time:
		complete_production()

func add_to_queue(unit_type: String) -> bool:
	"""Add a unit to the production queue"""
	if production_queue.size() >= MAX_QUEUE_SIZE:
		return false
	
	var cost = calculate_production_cost(unit_type)
	var build_time = UnitProductionDatabase.get_build_time(unit_type)
	
	# Check if resources available
	if not ResourceManager.can_afford_cost(cost):
		return false
	
	# Deduct resources
	ResourceManager.consume_resources(cost)
	
	# Add to queue
	var order = {
		"unit_type": unit_type,
		"build_time": build_time,
		"resource_cost": cost,
		"progress": 0.0
	}
	production_queue.append(order)
	
	print("CommandShip: Added %s to queue (cost: %s)" % [unit_type, cost])
	
	# Start production if not already producing
	if not is_producing:
		start_next_production()
	
	queue_updated.emit()
	return true

func start_next_production():
	"""Start building the next unit in queue"""
	if production_queue.is_empty():
		is_producing = false
		current_production = {}
		queue_updated.emit()
		return
	
	current_production = production_queue.pop_front()
	production_timer = 0.0
	is_producing = true
	
	production_started.emit(current_production.unit_type)

func complete_production():
	"""Complete current production and spawn unit"""
	var unit_type = current_production.unit_type
	
	# Spawn unit at command ship
	spawn_unit(unit_type)
	
	production_completed.emit(unit_type)
	
	# Start next in queue
	start_next_production()

func cancel_production(index: int):
	"""Cancel production at index (-1 for current)"""
	if index == -1:  # Cancel current production
		if not current_production.is_empty():
			# Refund resources
			ResourceManager.refund_resources(current_production.resource_cost)
			
			production_cancelled.emit(-1)
			start_next_production()
	else:  # Cancel from queue
		if index >= 0 and index < production_queue.size():
			var order = production_queue[index]
			ResourceManager.refund_resources(order.resource_cost)
			production_queue.remove_at(index)
			
			production_cancelled.emit(index)
			queue_updated.emit()

func spawn_unit(unit_type: String):
	"""Spawn a completed unit near the command ship"""
	var scene_path = UnitProductionDatabase.get_scene_path(unit_type)
	if scene_path.is_empty():
		push_error("CommandShip: No scene path for %s" % unit_type)
		return
	
	var unit_scene = load(scene_path)
	if not unit_scene:
		push_error("CommandShip: Failed to load scene %s" % scene_path)
		return
	
	var unit = unit_scene.instantiate()
	
	# Position near command ship with random offset
	var spawn_offset = Vector2(
		randf_range(-100, 100),
		randf_range(-100, 100)
	)
	unit.global_position = global_position + spawn_offset
	
	# Add to scene tree (same zone as command ship)
	var parent = get_parent()
	if parent:
		parent.add_child(unit)
		
		# Register with EntityManager
		var zone_id = ZoneManager.get_unit_zone(self) if ZoneManager else 1
		if EntityManager.has_method("register_unit"):
			EntityManager.register_unit(unit, zone_id)
		

func calculate_production_cost(unit_type: String) -> Dictionary:
	"""Calculate production cost with scaling based on existing units"""
	var base_cost = UnitProductionDatabase.get_base_cost(unit_type)
	var existing_count = count_existing_units(unit_type)
	var multiplier = 1.0 + (existing_count * 0.1)
	
	var final_cost = {}
	for resource_id in base_cost:
		final_cost[resource_id] = ceil(base_cost[resource_id] * multiplier)
	
	return final_cost

func count_existing_units(unit_type: String) -> int:
	"""Count how many units of this type already exist"""
	var count = 0
	var all_units = EntityManager.units if EntityManager else []
	
	for unit in all_units:
		if is_instance_valid(unit):
			# Check class name
			if unit.get_class() == unit_type:
				count += 1
	
	return count
