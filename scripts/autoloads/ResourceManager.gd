extends Node
## Manages player resources - both legacy 3-tier system and new 100-resource system

# Legacy signals (kept for backward compatibility)
signal resources_changed(common: float, rare: float, exotic: float)

# New signal for individual resource changes
signal resource_count_changed(resource_id: int, new_count: int)

# Legacy 3-tier system (kept for backward compatibility)
var common_material: float = 1000.0
var rare_material: float = 100.0
var exotic_material: float = 10.0

# New 100-resource system
var resource_counts: Array[int] = []

func _ready():
	# Initialize resource counts array with 100 zeros
	resource_counts.resize(100)
	for i in range(100):
		resource_counts[i] = 0
	
	# Give generous starter resources for testing building system
	# Enough for 2 Research Buildings + research costs
	resource_counts[0] = 1000   # Iron Ore (Research Building needs 300 each)
	resource_counts[1] = 800    # Carbon (Research Building needs 250 each)
	resource_counts[2] = 600    # Silicon (Research Building needs 200 each)
	resource_counts[10] = 500   # Copper (Research Building needs 150 each)
	resource_counts[11] = 300   # Zinc (for research costs)
	resource_counts[14] = 200   # Nickel (for turrets after research)
	resource_counts[20] = 300   # Silver (for research)
	resource_counts[21] = 200   # Lithium (for research)
	resource_counts[30] = 150   # Gold (for research)
	resource_counts[31] = 100   # Titanium (for research)
	
	# Emit initial resource state (legacy)
	resources_changed.emit(common_material, rare_material, exotic_material)
	
	# Emit signals for initial resources (new system)
	# Defer to next frame so UI is ready to receive signals
	call_deferred("_emit_initial_resource_signals")

func _emit_initial_resource_signals():
	"""Emit resource_count_changed for all non-zero starting resources"""
	for i in range(100):
		if resource_counts[i] > 0:
			resource_count_changed.emit(i, resource_counts[i])

# ============================================================================
# NEW 100-RESOURCE SYSTEM
# ============================================================================

func get_resource_count(resource_id: int) -> int:
	"""Get count of a specific resource by ID"""
	if resource_id >= 0 and resource_id < resource_counts.size():
		return resource_counts[resource_id]
	return 0

func add_resource(resource_id: int, amount: int):
	"""Add amount to a specific resource"""
	if resource_id >= 0 and resource_id < resource_counts.size():
		resource_counts[resource_id] += amount
		resource_counts[resource_id] = max(0, resource_counts[resource_id])
		resource_count_changed.emit(resource_id, resource_counts[resource_id])

func remove_resource(resource_id: int, amount: int) -> bool:
	"""Remove amount from a specific resource. Returns true if successful."""
	if resource_id >= 0 and resource_id < resource_counts.size():
		if resource_counts[resource_id] >= amount:
			resource_counts[resource_id] -= amount
			resource_count_changed.emit(resource_id, resource_counts[resource_id])
			return true
	return false

func set_resource_count(resource_id: int, count: int):
	"""Set exact count for a specific resource"""
	if resource_id >= 0 and resource_id < resource_counts.size():
		resource_counts[resource_id] = max(0, count)
		resource_count_changed.emit(resource_id, resource_counts[resource_id])

func get_all_resource_counts() -> Array[int]:
	"""Get copy of all resource counts"""
	return resource_counts.duplicate()

func can_afford_cost(cost: Dictionary) -> bool:
	"""Check if player can afford a cost dictionary {resource_id: amount}"""
	for resource_id in cost:
		var amount = cost[resource_id]
		if get_resource_count(resource_id) < amount:
			return false
	return true

func consume_resources(cost: Dictionary) -> bool:
	"""Consume resources from a cost dictionary. Returns true if successful."""
	if not can_afford_cost(cost):
		return false
	
	for resource_id in cost:
		remove_resource(resource_id, cost[resource_id])
	
	return true

func refund_resources(cost: Dictionary):
	"""Refund resources from a cost dictionary (100% refund)"""
	for resource_id in cost:
		add_resource(resource_id, cost[resource_id])

func get_resource_amount(resource_id: int) -> int:
	"""Alias for get_resource_count for consistency"""
	return get_resource_count(resource_id)

# ============================================================================
# LEGACY 3-TIER SYSTEM (Backward Compatibility)
# ============================================================================

func add_resources(common: float = 0, rare: float = 0, exotic: float = 0):
	common_material += common
	rare_material += rare
	exotic_material += exotic
	
	# Ensure no negative values
	common_material = max(0, common_material)
	rare_material = max(0, rare_material)
	exotic_material = max(0, exotic_material)
	
	resources_changed.emit(common_material, rare_material, exotic_material)

func spend_resources(common: float = 0, rare: float = 0, exotic: float = 0) -> bool:
	# Check if we have enough resources
	if common_material >= common and rare_material >= rare and exotic_material >= exotic:
		common_material -= common
		rare_material -= rare
		exotic_material -= exotic
		
		resources_changed.emit(common_material, rare_material, exotic_material)
		return true
	
	return false

func get_total_resources() -> float:
	return common_material + rare_material + exotic_material

func can_afford(common: float = 0, rare: float = 0, exotic: float = 0) -> bool:
	return common_material >= common and rare_material >= rare and exotic_material >= exotic

func set_resources(common: float, rare: float, exotic: float):
	common_material = common
	rare_material = rare
	exotic_material = exotic
	resources_changed.emit(common_material, rare_material, exotic_material)
