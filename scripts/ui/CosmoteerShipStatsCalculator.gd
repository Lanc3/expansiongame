class_name CosmoteerShipStatsCalculator
extends RefCounted
## Calculates ship stats from blueprint data

static func calculate_power(blueprint: CosmoteerShipBlueprint) -> Dictionary:
	"""Returns {generated: X, consumed: Y, balance: Z}"""
	var generated: float = 0.0
	var consumed: float = 0.0
	
	for comp_data in blueprint.components:
		var comp_id = comp_data.get("type", "")
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_id)
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
		var comp_id = comp_data.get("type", "")
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_id)
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
		var comp_id = comp_data.get("type", "")
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_id)
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
		var comp_id = comp_data.get("type", "")
		var parsed = CosmoteerComponentDefs.parse_component_id(comp_id)
		if parsed["type"] == "engine":
			engine_count += 1
			var comp_def = CosmoteerComponentDefs.get_component_data(comp_id)
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
	
	# Factor in engine placement efficiency
	var engine_placement = validate_engine_placement(blueprint)
	var placement_efficiency = engine_placement.get("efficiency", 1.0)
	
	return base_speed * efficiency * placement_efficiency

static func count_components_by_type(blueprint: CosmoteerShipBlueprint, comp_type: String) -> int:
	"""Count how many of a specific component type exist (any level)"""
	var count = 0
	for comp_data in blueprint.components:
		var comp_id = comp_data.get("type", "")
		var parsed = CosmoteerComponentDefs.parse_component_id(comp_id)
		if parsed["type"] == comp_type:
			count += 1
	return count

static func validate_engine_placement(blueprint: CosmoteerShipBlueprint) -> Dictionary:
	"""Check if engines are properly placed at the rear of the ship
	Returns: {efficiency: float, properly_placed: int, total: int, message: String}
	"""
	var center_of_mass = blueprint.calculate_center_of_mass()
	var forward_dir = blueprint.forward_direction
	var rear_dir = -forward_dir  # Opposite of forward is rear
	
	var engine_count = 0
	var properly_placed = 0
	var total_efficiency = 0.0
	
	for comp_data in blueprint.components:
		var comp_id = comp_data.get("type", "")
		var parsed = CosmoteerComponentDefs.parse_component_id(comp_id)
		if parsed["type"] != "engine":
			continue
		
		engine_count += 1
		var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
		var comp_size = comp_data.get("size", Vector2i.ONE)
		
		# Get engine center position
		var engine_center = Vector2(comp_pos) + Vector2(comp_size) * 0.5
		
		# Calculate vector from center of mass to engine
		var to_engine = engine_center - center_of_mass
		
		# Check if engine is in the rear direction (dot product with rear direction)
		# Normalize to avoid magnitude influence
		if to_engine.length() > 0.1:
			to_engine = to_engine.normalized()
			var alignment = to_engine.dot(rear_dir)
			
			# alignment: 1.0 = perfect rear, 0.0 = side, -1.0 = front
			var engine_efficiency = 0.0
			if alignment > 0.5:  # Rear (> 60 degrees from perpendicular)
				engine_efficiency = 1.0
				properly_placed += 1
			elif alignment > -0.5:  # Side
				engine_efficiency = 0.7
			else:  # Front
				engine_efficiency = 0.4
			
			total_efficiency += engine_efficiency
		else:
			# Engine at center of mass - count as properly placed
			total_efficiency += 1.0
			properly_placed += 1
	
	var avg_efficiency = 1.0
	if engine_count > 0:
		avg_efficiency = total_efficiency / engine_count
	
	return {
		"efficiency": avg_efficiency,
		"properly_placed": properly_placed,
		"total": engine_count,
		"message": "%d/%d engines at rear" % [properly_placed, engine_count]
	}

static func validate_ship(blueprint: CosmoteerShipBlueprint) -> Array:
	"""Returns array of validation results with severity levels
	Each entry: {message: String, severity: String, component_type: String}
	Severity: "critical", "warning", "info"
	"""
	var results: Array = []
	
	# Check if ship has any cells
	if blueprint.get_hull_cell_count() == 0:
		results.append({
			"message": "Ship has no hull",
			"severity": "critical",
			"component_type": "hull"
		})
		return results  # No point checking further
	
	# Check hull contiguity (CRITICAL)
	if not blueprint.is_hull_contiguous():
		var islands = blueprint.get_hull_islands()
		results.append({
			"message": "Hull not contiguous (%d separate pieces)" % islands.size(),
			"severity": "critical",
			"component_type": "hull"
		})
	
	# Check for required components
	var power_core_count = count_components_by_type(blueprint, "power_core")
	var engine_count = count_components_by_type(blueprint, "engine")
	var weapon_count = 0
	
	for comp_type in ["laser_weapon", "missile_launcher"]:
		weapon_count += count_components_by_type(blueprint, comp_type)
	
	if power_core_count == 0:
		results.append({
			"message": "Missing Power Core (at least 1 required)",
			"severity": "critical",
			"component_type": "power_core"
		})
	
	if engine_count == 0:
		results.append({
			"message": "Missing Engine (at least 1 required)",
			"severity": "critical",
			"component_type": "engine"
		})
	
	if weapon_count == 0:
		results.append({
			"message": "Missing Weapon (at least 1 required)",
			"severity": "warning",
			"component_type": "weapon"
		})
	
	# Check power balance
	var power = calculate_power(blueprint)
	if power.get("balance", 0) < 0:
		results.append({
			"message": "Insufficient power (%.1f shortage)" % abs(power.get("balance", 0)),
			"severity": "critical",
			"component_type": "power_core"
		})
	elif power.get("balance", 0) < 2:
		results.append({
			"message": "Low power margin (%.1f surplus)" % power.get("balance", 0),
			"severity": "warning",
			"component_type": "power_core"
		})
	
	# Check weight/thrust
	var weight_thrust = calculate_weight_thrust(blueprint)
	if weight_thrust.get("status", "") == "insufficient":
		results.append({
			"message": "Insufficient thrust (need %.1f, have %.1f)" % [
				weight_thrust.get("weight", 0),
				weight_thrust.get("thrust", 0)
			],
			"severity": "critical",
			"component_type": "engine"
		})
	elif weight_thrust.get("status", "") == "warning":
		results.append({
			"message": "Low thrust margin (%.1f%%)" % (weight_thrust.get("ratio", 0) * 100),
			"severity": "warning",
			"component_type": "engine"
		})
	
	# Check engine placement
	if engine_count > 0:
		var engine_placement = validate_engine_placement(blueprint)
		if engine_placement.get("efficiency", 1.0) < 1.0:
			results.append({
				"message": "Engines: %d rear, %d other (%.0f%% efficiency)" % [
					engine_placement.get("properly_placed", 0),
					engine_placement.get("total", 0) - engine_placement.get("properly_placed", 0),
					engine_placement.get("efficiency", 1.0) * 100
				],
				"severity": "warning",
				"component_type": "engine"
			})
	
	# Check weapon coverage
	if weapon_count > 0:
		var coverage = calculate_weapon_coverage(blueprint)
		var uncovered_sides: Array = []
		
		if coverage.get("forward", 0) == 0:
			uncovered_sides.append("front")
		if coverage.get("rear", 0) == 0:
			uncovered_sides.append("rear")
		if coverage.get("left", 0) == 0:
			uncovered_sides.append("left")
		if coverage.get("right", 0) == 0:
			uncovered_sides.append("right")
		
		if uncovered_sides.size() > 0:
			results.append({
				"message": "No weapon coverage: %s" % ", ".join(uncovered_sides),
				"severity": "info",
				"component_type": "weapon"
			})
	
	return results

static func calculate_weapon_coverage(blueprint: CosmoteerShipBlueprint) -> Dictionary:
	"""Calculate weapon coverage in each direction
	Returns: {forward: float, rear: float, left: float, right: float, total_weapons: int}
	"""
	var coverage = {
		"forward": 0.0,
		"rear": 0.0,
		"left": 0.0,
		"right": 0.0,
		"total_weapons": 0
	}
	
	var center_of_mass = blueprint.calculate_center_of_mass()
	var forward_dir = blueprint.forward_direction
	
	for comp_data in blueprint.components:
		var comp_id = comp_data.get("type", "")
		var parsed = CosmoteerComponentDefs.parse_component_id(comp_id)
		var comp_type = parsed["type"]
		if comp_type != "laser_weapon" and comp_type != "missile_launcher":
			continue
		
		coverage["total_weapons"] += 1
		
		var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
		var comp_size = comp_data.get("size", Vector2i.ONE)
		var weapon_center = Vector2(comp_pos) + Vector2(comp_size) * 0.5
		
		# Calculate weapon direction relative to center of mass
		var to_weapon = weapon_center - center_of_mass
		if to_weapon.length() < 0.1:
			# Weapon at center - can cover all directions
			coverage["forward"] += 0.25
			coverage["rear"] += 0.25
			coverage["left"] += 0.25
			coverage["right"] += 0.25
			continue
		
		to_weapon = to_weapon.normalized()
		
		# Determine primary coverage direction
		var forward_alignment = to_weapon.dot(forward_dir)
		var right_dir = Vector2(-forward_dir.y, forward_dir.x)  # Perpendicular
		var right_alignment = to_weapon.dot(right_dir)
		
		# Assign to primary and secondary coverage zones
		if abs(forward_alignment) > abs(right_alignment):
			# Forward/Rear dominant
			if forward_alignment > 0:
				coverage["forward"] += 1.0
			else:
				coverage["rear"] += 1.0
		else:
			# Left/Right dominant
			if right_alignment > 0:
				coverage["right"] += 1.0
			else:
				coverage["left"] += 1.0
	
	# Normalize to percentages
	var total = coverage["total_weapons"]
	if total > 0:
		coverage["forward"] = (coverage["forward"] / total) * 100.0
		coverage["rear"] = (coverage["rear"] / total) * 100.0
		coverage["left"] = (coverage["left"] / total) * 100.0
		coverage["right"] = (coverage["right"] / total) * 100.0
	
	return coverage

static func format_cost(cost: Dictionary) -> String:
	"""Format cost dictionary as readable string with resource names"""
	if cost.is_empty():
		return "Free"
	
	var parts: Array = []
	for resource_id in cost.keys():
		var amount = cost[resource_id]
		var resource_name = get_resource_name(resource_id)
		parts.append("%s: %d" % [resource_name, amount])
	
	return ", ".join(parts)

static func get_resource_name(resource_id: int) -> String:
	"""Get the display name for a resource ID"""
	if ResourceDatabase and resource_id >= 0 and resource_id < ResourceDatabase.RESOURCES.size():
		return ResourceDatabase.RESOURCES[resource_id].get("name", "Unknown")
	return "Resource %d" % resource_id

