class_name CosmoteerComponentDefs
extends RefCounted
## Static definitions for Cosmoteer-style ship components with 9-level progression

# Component types with 9 levels each
const COMPONENT_TYPES = {
	"power_core": {
		"name": "Power Core",
		"base_sprite": "res://assets/sprites/UI/PowerCore.png",
		"description": "Generates power for ship systems",
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_generated": 5, "power_consumed": 0, "weight": 8.0, "cost": {0: 25, 1: 10}},
			{"level": 2, "size": Vector2i(1, 2), "power_generated": 7, "power_consumed": 0, "weight": 10.0, "cost": {0: 20, 10: 15}},
			{"level": 3, "size": Vector2i(2, 1), "power_generated": 10, "power_consumed": 0, "weight": 13.0, "cost": {10: 30, 20: 20}},
			{"level": 4, "size": Vector2i(2, 2), "power_generated": 15, "power_consumed": 0, "weight": 16.0, "cost": {20: 40, 30: 30}},
			{"level": 5, "size": Vector2i(2, 2), "power_generated": 20, "power_consumed": 0, "weight": 20.0, "cost": {30: 50, 40: 40}},
			{"level": 6, "size": Vector2i(2, 3), "power_generated": 30, "power_consumed": 0, "weight": 26.0, "cost": {40: 60, 50: 50}},
			{"level": 7, "size": Vector2i(3, 2), "power_generated": 40, "power_consumed": 0, "weight": 33.0, "cost": {50: 70, 60: 60}},
			{"level": 8, "size": Vector2i(3, 3), "power_generated": 60, "power_consumed": 0, "weight": 43.0, "cost": {60: 80, 70: 70}},
			{"level": 9, "size": Vector2i(3, 3), "power_generated": 80, "power_consumed": 0, "weight": 56.0, "cost": {70: 100, 80: 80}}
		]
	},
	"engine": {
		"name": "Engine",
		"base_sprite": "res://assets/sprites/UI/engineImage.png",
		"description": "Provides thrust for movement",
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 2, "thrust": 30.0, "speed_boost": 25, "weight": 10.0, "cost": {0: 15, 2: 5}},
			{"level": 2, "size": Vector2i(1, 2), "power_consumed": 2, "thrust": 50.0, "speed_boost": 35, "weight": 13.0, "cost": {0: 12, 10: 8}},
			{"level": 3, "size": Vector2i(2, 2), "power_consumed": 3, "thrust": 100.0, "speed_boost": 50, "weight": 20.0, "cost": {10: 18, 20: 12}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 4, "thrust": 150.0, "speed_boost": 70, "weight": 26.0, "cost": {20: 25, 30: 18}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 5, "thrust": 220.0, "speed_boost": 90, "weight": 34.0, "cost": {30: 35, 40: 25}},
			{"level": 6, "size": Vector2i(2, 3), "power_consumed": 7, "thrust": 320.0, "speed_boost": 120, "weight": 44.0, "cost": {40: 50, 50: 35}},
			{"level": 7, "size": Vector2i(3, 2), "power_consumed": 9, "thrust": 450.0, "speed_boost": 160, "weight": 57.0, "cost": {50: 70, 60: 50}},
			{"level": 8, "size": Vector2i(3, 3), "power_consumed": 12, "thrust": 650.0, "speed_boost": 210, "weight": 75.0, "cost": {60: 100, 70: 70}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 16, "thrust": 900.0, "speed_boost": 280, "weight": 97.0, "cost": {70: 140, 80: 100}}
		]
	},
	"laser_weapon": {
		"name": "Laser Weapon",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Rapid-fire laser turret",
		"firing_arc": 180,
		"arc_direction": "forward",
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 1, "damage": 5, "weight": 4.0, "cost": {0: 10, 1: 8}},
			{"level": 2, "size": Vector2i(1, 2), "power_consumed": 2, "damage": 8, "weight": 6.0, "cost": {0: 8, 10: 10}},
			{"level": 3, "size": Vector2i(1, 2), "power_consumed": 2, "damage": 10, "weight": 8.0, "cost": {10: 12, 20: 15}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 3, "damage": 15, "weight": 10.0, "cost": {20: 18, 30: 20}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 22, "weight": 13.0, "cost": {30: 25, 40: 28}},
			{"level": 6, "size": Vector2i(2, 2), "power_consumed": 6, "damage": 32, "weight": 17.0, "cost": {40: 35, 50: 40}},
			{"level": 7, "size": Vector2i(2, 3), "power_consumed": 8, "damage": 45, "weight": 22.0, "cost": {50: 50, 60: 55}},
			{"level": 8, "size": Vector2i(3, 2), "power_consumed": 12, "damage": 65, "weight": 29.0, "cost": {60: 70, 70: 75}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 16, "damage": 90, "weight": 38.0, "cost": {70: 100, 80: 110}}
		]
	},
	"missile_launcher": {
		"name": "Missile Launcher",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Launches explosive missiles",
		"firing_arc": 90,
		"arc_direction": "forward",
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 1, "damage": 20, "weight": 10.0, "cost": {0: 20, 4: 10}},
			{"level": 2, "size": Vector2i(1, 2), "power_consumed": 2, "damage": 30, "weight": 13.0, "cost": {0: 15, 10: 12}},
			{"level": 3, "size": Vector2i(2, 2), "power_consumed": 3, "damage": 50, "weight": 17.0, "cost": {10: 25, 20: 20}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 75, "weight": 22.0, "cost": {20: 35, 30: 30}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 5, "damage": 110, "weight": 29.0, "cost": {30: 50, 40: 45}},
			{"level": 6, "size": Vector2i(2, 3), "power_consumed": 7, "damage": 160, "weight": 38.0, "cost": {40: 70, 50: 65}},
			{"level": 7, "size": Vector2i(3, 2), "power_consumed": 10, "damage": 230, "weight": 49.0, "cost": {50: 100, 60: 90}},
			{"level": 8, "size": Vector2i(3, 3), "power_consumed": 14, "damage": 330, "weight": 64.0, "cost": {60: 140, 70: 130}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 20, "damage": 470, "weight": 83.0, "cost": {70: 200, 80: 180}}
		]
	},
	"shield_generator": {
		"name": "Shield Generator",
		"base_sprite": "res://assets/sprites/UI/ShieldGen.png",
		"description": "Generates protective energy shield",
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 2, "shield_hp": 50, "weight": 6.0, "cost": {1: 20, 3: 5}},
			{"level": 2, "size": Vector2i(2, 1), "power_consumed": 3, "shield_hp": 75, "weight": 8.0, "cost": {1: 15, 10: 10}},
			{"level": 3, "size": Vector2i(2, 1), "power_consumed": 4, "shield_hp": 100, "weight": 10.0, "cost": {10: 25, 20: 15}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 6, "shield_hp": 150, "weight": 13.0, "cost": {20: 35, 30: 25}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 9, "shield_hp": 220, "weight": 17.0, "cost": {30: 50, 40: 40}},
			{"level": 6, "size": Vector2i(2, 2), "power_consumed": 13, "shield_hp": 320, "weight": 22.0, "cost": {40: 70, 50: 60}},
			{"level": 7, "size": Vector2i(2, 3), "power_consumed": 18, "shield_hp": 460, "weight": 29.0, "cost": {50: 100, 60: 85}},
			{"level": 8, "size": Vector2i(3, 2), "power_consumed": 26, "shield_hp": 660, "weight": 38.0, "cost": {60: 140, 70: 120}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 36, "shield_hp": 950, "weight": 49.0, "cost": {70: 200, 80: 170}}
		]
	},
	"repair_bot": {
		"name": "Repair Bot",
		"base_sprite": "res://assets/sprites/UI/RepairBot.png",
		"description": "Repairs hull damage over time",
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 1, "repair_rate": 2, "weight": 3.0, "cost": {0: 8, 1: 5}},
			{"level": 2, "size": Vector2i(1, 1), "power_consumed": 1, "repair_rate": 3, "weight": 4.0, "cost": {0: 6, 10: 7}},
			{"level": 3, "size": Vector2i(1, 1), "power_consumed": 2, "repair_rate": 5, "weight": 5.0, "cost": {10: 10, 20: 10}},
			{"level": 4, "size": Vector2i(1, 2), "power_consumed": 3, "repair_rate": 8, "weight": 7.0, "cost": {20: 15, 30: 12}},
			{"level": 5, "size": Vector2i(2, 1), "power_consumed": 4, "repair_rate": 12, "weight": 9.0, "cost": {30: 20, 40: 18}},
			{"level": 6, "size": Vector2i(2, 2), "power_consumed": 6, "repair_rate": 18, "weight": 12.0, "cost": {40: 28, 50: 25}},
			{"level": 7, "size": Vector2i(2, 2), "power_consumed": 8, "repair_rate": 26, "weight": 16.0, "cost": {50: 40, 60: 35}},
			{"level": 8, "size": Vector2i(2, 3), "power_consumed": 12, "repair_rate": 38, "weight": 21.0, "cost": {60: 55, 70: 50}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 16, "repair_rate": 55, "weight": 27.0, "cost": {70: 80, 80: 70}}
		]
	}
}

# Legacy COMPONENTS dict for backward compatibility - maps to level 3 (current default)
# This is populated at runtime via _init_legacy_components()
var COMPONENTS = {}

const HULL_COSTS = {
	CosmoteerShipBlueprint.HullType.LIGHT: {0: 5},  # metal: 5
	CosmoteerShipBlueprint.HullType.MEDIUM: {0: 10, 5: 2},  # metal: 10, alloy (placeholder): 2
	CosmoteerShipBlueprint.HullType.HEAVY: {0: 15, 5: 5}  # metal: 15, alloy: 5
}

const HULL_WEIGHTS = {
	CosmoteerShipBlueprint.HullType.LIGHT: 2.0,
	CosmoteerShipBlueprint.HullType.MEDIUM: 5.0,
	CosmoteerShipBlueprint.HullType.HEAVY: 10.0
}

const HULL_COLORS = {
	CosmoteerShipBlueprint.HullType.LIGHT: Color(0.4, 0.6, 1.0, 0.6),  # Light blue
	CosmoteerShipBlueprint.HullType.MEDIUM: Color(0.4, 1.0, 0.4, 0.6),  # Green
	CosmoteerShipBlueprint.HullType.HEAVY: Color(1.0, 0.4, 0.4, 0.6)   # Red
}

const HULL_NAMES = {
	CosmoteerShipBlueprint.HullType.LIGHT: "Light Armor",
	CosmoteerShipBlueprint.HullType.MEDIUM: "Medium Armor",
	CosmoteerShipBlueprint.HullType.HEAVY: "Heavy Armor"
}

const HULL_TEXTURES = {
	CosmoteerShipBlueprint.HullType.LIGHT: "res://assets/sprites/UI/Hull1.png",
	CosmoteerShipBlueprint.HullType.MEDIUM: "res://assets/sprites/UI/Hull2.png",
	CosmoteerShipBlueprint.HullType.HEAVY: "res://assets/sprites/UI/Hull3.png"
}

static func parse_component_id(comp_id: String) -> Dictionary:
	"""Parse component ID into type and level
	Returns: {type: String, level: int}
	Examples: 'power_core_l5' -> {type: 'power_core', level: 5}
	          'power_core' -> {type: 'power_core', level: 3} (backward compat)
	"""
	if "_l" in comp_id:
		var parts = comp_id.rsplit("_l", true, 1)
		var comp_type = parts[0]
		var level = int(parts[1]) if parts.size() > 1 else 1
		return {"type": comp_type, "level": level}
	else:
		# Backward compatibility - old IDs default to level 3
		return {"type": comp_id, "level": 3}

static func build_component_id(comp_type: String, level: int) -> String:
	"""Build component ID from type and level
	Example: ('power_core', 5) -> 'power_core_l5'
	"""
	return "%s_l%d" % [comp_type, level]

static func get_component_data_by_level(comp_type: String, level: int) -> Dictionary:
	"""Get component data for a specific type and level"""
	var type_data = COMPONENT_TYPES.get(comp_type, {})
	if type_data.is_empty():
		return {}
	
	var levels = type_data.get("levels", [])
	if level < 1 or level > levels.size():
		return {}
	
	# Get level data and add common properties
	var level_data = levels[level - 1].duplicate()
	level_data["name"] = type_data.get("name", "Unknown")
	level_data["sprite"] = type_data.get("base_sprite", "")
	level_data["description"] = type_data.get("description", "")
	
	# Add weapon-specific properties if present
	if type_data.has("firing_arc"):
		level_data["firing_arc"] = type_data.get("firing_arc")
	if type_data.has("arc_direction"):
		level_data["arc_direction"] = type_data.get("arc_direction")
	
	return level_data

static func get_component_data(component_id: String) -> Dictionary:
	"""Get component data from full ID (e.g., 'power_core_l5' or 'power_core')"""
	var parsed = parse_component_id(component_id)
	return get_component_data_by_level(parsed["type"], parsed["level"])

static func get_all_component_types() -> Array:
	"""Get array of all component type names (without levels)"""
	return COMPONENT_TYPES.keys()

static func get_max_level(comp_type: String) -> int:
	"""Get maximum level for a component type"""
	var type_data = COMPONENT_TYPES.get(comp_type, {})
	var levels = type_data.get("levels", [])
	return levels.size()

static func get_component_type_info(comp_type: String) -> Dictionary:
	"""Get component type metadata (name, sprite, description)"""
	return COMPONENT_TYPES.get(comp_type, {})

static func is_valid_component_type(component_type: String) -> bool:
	"""Check if component type exists"""
	# Handle both old format and new format
	var parsed = parse_component_id(component_type)
	return COMPONENT_TYPES.has(parsed["type"])

static func get_component_base_sprite(comp_type: String) -> String:
	"""Get base sprite path for a component type"""
	var type_data = COMPONENT_TYPES.get(comp_type, {})
	return type_data.get("base_sprite", "")

static func get_hull_cost(hull_type: CosmoteerShipBlueprint.HullType) -> Dictionary:
	return HULL_COSTS.get(hull_type, {})

static func get_hull_weight(hull_type: CosmoteerShipBlueprint.HullType) -> float:
	return HULL_WEIGHTS.get(hull_type, 0.0)

static func get_hull_color(hull_type: CosmoteerShipBlueprint.HullType) -> Color:
	return HULL_COLORS.get(hull_type, Color.WHITE)

static func get_hull_name(hull_type: CosmoteerShipBlueprint.HullType) -> String:
	return HULL_NAMES.get(hull_type, "Unknown")

static func get_hull_texture(hull_type: CosmoteerShipBlueprint.HullType) -> String:
	return HULL_TEXTURES.get(hull_type, "")

