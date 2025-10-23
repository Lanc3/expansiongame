extends Node
## Manages all 9 zones in the game universe

signal zone_switched(from_zone_id: int, to_zone_id: int)
signal unit_transferred(unit: Node2D, from_zone_id: int, to_zone_id: int)
signal zones_initialized()

# Zone data structure
var zones: Array[Dictionary] = []
var current_zone_id: int = 1
var zones_ready: bool = false

# Base spawn area for Zone 1 (4000x4000)
const BASE_ZONE_SIZE: float = 4000.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	initialize_zones()
	

func initialize_zones():
	"""Create all 9 zones at game start"""
	zones.clear()
	
	for i in range(1, 10):  # Zones 1-9
		var zone = {
			"id": i,
			"name": "Zone %d" % i,
			"size_multiplier": float(i),
			"spawn_area_size": BASE_ZONE_SIZE * float(i),
			"boundaries": calculate_zone_boundaries(i),
			"layer_node": null,  # Will be set when GameScene initializes
			"wormholes": [],  # Array of wormholes in this zone
			"max_resource_tier": i - 1,  # Zone 1 = Tier 0, Zone 2 = Tier 0-1, etc.
		}
		zones.append(zone)
	
	

func calculate_zone_boundaries(zone_id: int) -> Rect2:
	"""Calculate rectangular boundaries for a zone"""
	var size = BASE_ZONE_SIZE * float(zone_id)
	var half_size = size / 2.0
	return Rect2(-half_size, -half_size, size, size)

func get_zone(zone_id: int) -> Dictionary:
	"""Get zone data by ID (1-9)"""
	if zone_id >= 1 and zone_id <= 9:
		return zones[zone_id - 1]
	return {}

func get_current_zone() -> Dictionary:
	"""Get the currently active zone"""
	return get_zone(current_zone_id)

func switch_to_zone(zone_id: int) -> bool:
	"""Switch camera view to a different zone"""
	if zone_id < 1 or zone_id > 9:
		return false
	
	if zone_id == current_zone_id:
		return false
	
	var old_zone = current_zone_id
	current_zone_id = zone_id
	
	# Update processing states
	if ZoneProcessingManager:
		ZoneProcessingManager.set_active_zone(zone_id)
	
	# Hide old zone layer, show new zone layer
	update_zone_visibility()
	
	# Update camera bounds
	var new_zone = get_zone(zone_id)
	if new_zone.is_empty():
		return false
	
	# Notify camera system
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("set_zone_bounds"):
		camera.set_zone_bounds(new_zone.boundaries)
	
	zone_switched.emit(old_zone, zone_id)
	
	return true

func update_zone_visibility():
	"""Update visibility of zone layers"""
	for zone in zones:
		if zone.layer_node and is_instance_valid(zone.layer_node):
			zone.layer_node.visible = (zone.id == current_zone_id)

func set_zone_layer(zone_id: int, layer_node: Node2D):
	"""Associate a zone with its scene layer node"""
	var zone = get_zone(zone_id)
	if not zone.is_empty():
		zone.layer_node = layer_node

func set_zone_wormhole(zone_id: int, wormhole: Node2D):
	"""Add a wormhole to a zone (zones can have multiple wormholes)"""
	var zone = get_zone(zone_id)
	if not zone.is_empty():
		if wormhole not in zone.wormholes:
			zone.wormholes.append(wormhole)

func transfer_units_to_zone(units: Array, target_zone_id: int, spawn_position: Vector2):
	"""Transfer units from current zone to target zone"""
	if target_zone_id < 1 or target_zone_id > 9:
		return
	
	var target_zone = get_zone(target_zone_id)
	if target_zone.is_empty() or not target_zone.layer_node:
		return
	
	for unit in units:
		if not is_instance_valid(unit):
			continue
		
		var old_zone_id = get_unit_zone(unit)
		
		# Reparent to target zone's Units container
		var target_units_node = target_zone.layer_node.get_node_or_null("Entities/Units")
		if target_units_node:
			# Calculate random offset near spawn position
			var random_offset = Vector2(
				randf_range(-100, 100),
				randf_range(-100, 100)
			)
			var new_position = spawn_position + random_offset
			
			# Store old parent for reparenting
			var old_parent = unit.get_parent()
			
			# Reparent unit
			old_parent.remove_child(unit)
			target_units_node.add_child(unit)
			unit.global_position = new_position
			
			# Update EntityManager
			if EntityManager.has_method("update_unit_zone"):
				EntityManager.update_unit_zone(unit, old_zone_id, target_zone_id)
			
			unit_transferred.emit(unit, old_zone_id, target_zone_id)
		
func get_unit_zone(unit: Node2D) -> int:
	"""Get which zone a unit is currently in"""
	for zone in zones:
		if zone.layer_node and is_instance_valid(zone.layer_node):
			if zone.layer_node.is_ancestor_of(unit):
				return zone.id
	return 1  # Default to zone 1

func get_zone_count() -> int:
	"""Get total number of zones"""
	return zones.size()

func is_valid_zone(zone_id: int) -> bool:
	"""Check if zone ID is valid"""
	return zone_id >= 1 and zone_id <= 9

func get_adjacent_zones(zone_id: int) -> Array[int]:
	"""Get adjacent zone IDs (for wormhole connections)"""
	var adjacent: Array[int] = []
	
	if zone_id > 1:
		adjacent.append(zone_id - 1)  # Previous zone
	
	if zone_id < 9:
		adjacent.append(zone_id + 1)  # Next zone
	
	return adjacent

func get_zone_wormhole_spawn_position(zone_id: int) -> Vector2:
	"""Get a random position at the edge of a zone for wormhole placement"""
	var zone = get_zone(zone_id)
	if zone.is_empty():
		return Vector2.ZERO
	
	var bounds = zone.boundaries
	var edge = randi() % 4  # 0=top, 1=right, 2=bottom, 3=left
	
	match edge:
		0:  # Top edge
			return Vector2(
				randf_range(bounds.position.x + 200, bounds.position.x + bounds.size.x - 200),
				bounds.position.y + 100
			)
		1:  # Right edge
			return Vector2(
				bounds.position.x + bounds.size.x - 100,
				randf_range(bounds.position.y + 200, bounds.position.y + bounds.size.y - 200)
			)
		2:  # Bottom edge
			return Vector2(
				randf_range(bounds.position.x + 200, bounds.position.x + bounds.size.x - 200),
				bounds.position.y + bounds.size.y - 100
			)
		3:  # Left edge
			return Vector2(
				bounds.position.x + 100,
				randf_range(bounds.position.y + 200, bounds.position.y + bounds.size.y - 200)
			)
	
	return Vector2.ZERO

func mark_zones_initialized():
	"""Called by ZoneSetup when all zones are ready"""
	zones_ready = true
	zones_initialized.emit()
	

func get_zone_statistics(zone_id: int) -> Dictionary:
	"""Get comprehensive statistics for a zone"""
	var zone = get_zone(zone_id)
	if zone.is_empty():
		return {}
	
	var max_tier = zone_id - 1  # Zone 1 = tier 0, Zone 2 = tiers 0-1, etc.
	var available_tiers = range(0, max_tier + 1)
	
	# Count resources in this zone
	var resource_count = 0
	if EntityManager:
		var zone_resources = EntityManager.get_resources_in_zone(zone_id)
		resource_count = zone_resources.size()
	
	# Calculate resource type count (how many unique types can spawn)
	var resource_types_count = 0
	for tier in available_tiers:
		resource_types_count += ResourceDatabase.get_resources_by_tier(tier).size()
	
	# Calculate rarity distribution
	var distribution = calculate_rarity_distribution(zone_id)
	
	return {
		"zone_id": zone_id,
		"zone_name": "Zone %d" % zone_id,
		"size_multiplier": zone.size_multiplier,
		"max_tier": max_tier,
		"available_tiers": available_tiers,
		"resource_types_count": resource_types_count,
		"total_asteroids": resource_count,
		"rarity_distribution": distribution,
		"estimated_value": calculate_zone_value_rating(zone_id)
	}

func calculate_rarity_distribution(zone_id: int) -> Dictionary:
	"""Calculate percentage distribution of resource rarities"""
	var max_tier = zone_id - 1
	
	# Tier groupings: Common (0-2), Uncommon (3-5), Rare (6-7), Ultra-Rare (8-9)
	var common_weight = 0.0
	var uncommon_weight = 0.0
	var rare_weight = 0.0
	var ultra_rare_weight = 0.0
	
	for tier in range(0, max_tier + 1):
		var weight = ResourceDatabase.TIER_WEIGHTS.get(tier, 0.0)
		if tier <= 2:
			common_weight += weight
		elif tier <= 5:
			uncommon_weight += weight
		elif tier <= 7:
			rare_weight += weight
		else:
			ultra_rare_weight += weight
	
	var total = common_weight + uncommon_weight + rare_weight + ultra_rare_weight
	
	if total == 0:
		return {"common": 100, "uncommon": 0, "rare": 0, "ultra_rare": 0}
	
	return {
		"common": int((common_weight / total) * 100),
		"uncommon": int((uncommon_weight / total) * 100),
		"rare": int((rare_weight / total) * 100),
		"ultra_rare": int((ultra_rare_weight / total) * 100)
	}

func calculate_zone_value_rating(zone_id: int) -> int:
	"""Calculate 1-5 star rating for zone based on available tiers"""
	var max_tier = zone_id - 1
	
	# Simple rating based on max tier
	if max_tier >= 8:
		return 5  # ★★★★★
	elif max_tier >= 6:
		return 4  # ★★★★☆
	elif max_tier >= 4:
		return 3  # ★★★☆☆
	elif max_tier >= 2:
		return 2  # ★★☆☆☆
	else:
		return 1  # ★☆☆☆☆

