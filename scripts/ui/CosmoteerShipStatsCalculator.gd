class_name CosmoteerShipStatsCalculator
extends RefCounted
## Calculates ship stats from blueprint data

static func calculate_power(blueprint: CosmoteerShipBlueprint) -> Dictionary:
	"""Returns {generated: X, consumed: Y, balance: Z}"""
	var generated: float = 0.0
	var consumed: float = 0.0
	
	for comp_data in blueprint.components:
		var comp_type = comp_data.get("type", "")
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_type)
		if comp_def.is_empty():
			continue
		
		generated += comp_def.get("power_generated", 0.0)
		consumed += comp_def.get("power_consumed", 0.0)
	
	return {
		"generated": generated,
		"consumed": consumed,
		"balance": generated - consumed
	}

static func calculate_cost(blueprint: CosmoteerShipBlueprint) -> Dictionary:
	"""Returns {resource_id: amount, ...}"""
	var total_cost: Dictionary = {}
	
	# Add hull costs
	for hull_pos in blueprint.hull_cells.keys():
		var hull_type_int = blueprint.hull_cells[hull_pos]
		var hull_type = hull_type_int as CosmoteerShipBlueprint.HullType
		var hull_cost = CosmoteerComponentDefs.get_hull_cost(hull_type)
		
		for resource_id in hull_cost.keys():
			if resource_id in total_cost:
				total_cost[resource_id] += hull_cost[resource_id]
			else:
				total_cost[resource_id] = hull_cost[resource_id]
	
	# Add component costs
	for comp_data in blueprint.components:
		var comp_type = comp_data.get("type", "")
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_type)
		if comp_def.is_empty():
			continue
		
		var comp_cost = comp_def.get("cost", {})
		for resource_id in comp_cost.keys():
			if resource_id in total_cost:
				total_cost[resource_id] += comp_cost[resource_id]
			else:
				total_cost[resource_id] = comp_cost[resource_id]
	
	return total_cost

static func calculate_weight_thrust(blueprint: CosmoteerShipBlueprint) -> Dictionary:
	"""Returns {weight: W, thrust: T, ratio: R, status: "good"/"warning"/"insufficient"}"""
	var total_weight: float = 0.0
	var total_thrust: float = 0.0
	
	# Calculate hull weight
	for hull_pos in blueprint.hull_cells.keys():
		var hull_type_int = blueprint.hull_cells[hull_pos]
		var hull_type = hull_type_int as CosmoteerShipBlueprint.HullType
		total_weight += CosmoteerComponentDefs.get_hull_weight(hull_type)
	
	# Calculate component weight and thrust
	for comp_data in blueprint.components:
		var comp_type = comp_data.get("type", "")
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_type)
		if comp_def.is_empty():
			continue
		
		total_weight += comp_def.get("weight", 0.0)
		total_thrust += comp_def.get("thrust", 0.0)
	
	var ratio: float = 0.0
	if total_weight > 0:
		ratio = total_thrust / total_weight
	
	# Determine status
	var status: String = "insufficient"
	if ratio >= 1.05:
		status = "good"
	elif ratio >= 1.0:
		status = "warning"
	
	return {
		"weight": total_weight,
		"thrust": total_thrust,
		"ratio": ratio,
		"status": status
	}

static func calculate_speed(blueprint: CosmoteerShipBlueprint) -> float:
	"""Calculate ship speed with diminishing returns on thrust/weight ratio"""
	var weight_thrust = calculate_weight_thrust(blueprint)
	var ratio = weight_thrust.get("ratio", 0.0)
	
	if ratio < 1.0:
		# Can't move if insufficient thrust
		return 0.0
	
	# Count engines for base speed
	var engine_count = 0
	var total_speed_boost = 0.0
	
	for comp_data in blueprint.components:
		var comp_type = comp_data.get("type", "")
		if comp_type == "engine":
			engine_count += 1
			var comp_def = CosmoteerComponentDefs.get_component_data(comp_type)
			total_speed_boost += comp_def.get("speed_boost", 0.0)
	
	if engine_count == 0:
		return 0.0
	
	# Base speed from engines
	var base_speed = total_speed_boost
	
	# Efficiency based on thrust/weight ratio
	# Optimal ratio is 1.5 (150% thrust to weight)
	var optimal_ratio = 1.5
	var efficiency: float
	
	if ratio <= optimal_ratio:
		# Linear increase from 1.0 to 1.5
		efficiency = 0.5 + (ratio - 1.0) * (0.5 / 0.5)  # 0.5 to 1.0
	else:
		# Diminishing returns above optimal
		var excess = ratio - optimal_ratio
		efficiency = 1.0 / (1.0 + excess * 0.5)  # Falls off gradually
	
	return base_speed * efficiency

static func count_components_by_type(blueprint: CosmoteerShipBlueprint, comp_type: String) -> int:
	"""Count how many of a specific component type exist"""
	var count = 0
	for comp_data in blueprint.components:
		if comp_data.get("type", "") == comp_type:
			count += 1
	return count

static func validate_ship(blueprint: CosmoteerShipBlueprint) -> Array:
	"""Returns array of error strings (empty if valid)"""
	var errors: Array = []
	
	# Check for required components
	var power_core_count = count_components_by_type(blueprint, "power_core")
	var engine_count = count_components_by_type(blueprint, "engine")
	var weapon_count = 0
	
	for comp_type in ["laser_weapon", "missile_launcher"]:
		weapon_count += count_components_by_type(blueprint, comp_type)
	
	if power_core_count == 0:
		errors.append("Missing Power Core (at least 1 required)")
	
	if engine_count == 0:
		errors.append("Missing Engine (at least 1 required)")
	
	if weapon_count == 0:
		errors.append("Missing Weapon (at least 1 required)")
	
	# Check power balance
	var power = calculate_power(blueprint)
	if power.get("balance", 0) < 0:
		errors.append("Insufficient power (%.1f shortage)" % abs(power.get("balance", 0)))
	
	# Check weight/thrust
	var weight_thrust = calculate_weight_thrust(blueprint)
	if weight_thrust.get("status", "") == "insufficient":
		errors.append("Insufficient thrust (need %.1f, have %.1f)" % [
			weight_thrust.get("weight", 0),
			weight_thrust.get("thrust", 0)
		])
	
	# Check if ship has any cells
	if blueprint.get_hull_cell_count() == 0:
		errors.append("Ship has no hull")
	
	return errors

static func format_cost(cost: Dictionary) -> String:
	"""Format cost dictionary as readable string"""
	if cost.is_empty():
		return "Free"
	
	var parts: Array = []
	for resource_id in cost.keys():
		var amount = cost[resource_id]
		# For now just show resource ID and amount
		# TODO: Get actual resource names from ResourceManager
		parts.append("R%d: %d" % [resource_id, amount])
	
	return ", ".join(parts)

