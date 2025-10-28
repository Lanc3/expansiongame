class_name CosmoteerComponentDefs
extends RefCounted
## Static definitions for Cosmoteer-style ship components and hull types

const COMPONENTS = {
	"power_core": {
		"name": "Power Core",
		"size": Vector2i(2, 2),
		"power_generated": 10,
		"power_consumed": 0,
		"weight": 15.0,
		"cost": {0: 50, 1: 20},  # metal: 50, electronics (placeholder): 20
		"sprite": "res://assets/sprites/UI/cursor.png",  # Placeholder
		"description": "Generates power for ship systems"
	},
	"engine": {
		"name": "Engine",
		"size": Vector2i(2, 2),
		"power_consumed": 3,
		"thrust": 100.0,  # Can handle 100 weight units
		"weight": 20.0,
		"speed_boost": 50,
		"cost": {0: 30, 2: 10},  # metal: 30, fuel (placeholder): 10
		"sprite": "res://assets/sprites/UI/cursor.png",  # Placeholder
		"description": "Provides thrust for movement"
	},
	"laser_weapon": {
		"name": "Laser Weapon",
		"size": Vector2i(1, 2),
		"power_consumed": 2,
		"damage": 10,
		"weight": 8.0,
		"cost": {0: 20, 1: 15},  # metal: 20, electronics: 15
		"sprite": "res://assets/sprites/UI/cursor.png",  # Placeholder
		"description": "Rapid-fire laser turret"
	},
	"shield_generator": {
		"name": "Shield Generator",
		"size": Vector2i(2, 1),
		"power_consumed": 4,
		"shield_hp": 100,
		"weight": 12.0,
		"cost": {1: 40, 3: 10},  # electronics: 40, crystals (placeholder): 10
		"sprite": "res://assets/sprites/UI/cursor.png",  # Placeholder
		"description": "Generates protective energy shield"
	},
	"repair_bot": {
		"name": "Repair Bot",
		"size": Vector2i(1, 1),
		"power_consumed": 1,
		"repair_rate": 5,
		"weight": 5.0,
		"cost": {0: 15, 1: 10},  # metal: 15, electronics: 10
		"sprite": "res://assets/sprites/UI/cursor.png",  # Placeholder
		"description": "Repairs hull damage over time"
	},
	"missile_launcher": {
		"name": "Missile Launcher",
		"size": Vector2i(2, 2),
		"power_consumed": 3,
		"damage": 50,
		"weight": 25.0,
		"cost": {0: 40, 4: 20},  # metal: 40, explosives (placeholder): 20
		"sprite": "res://assets/sprites/UI/cursor.png",  # Placeholder
		"description": "Launches explosive missiles"
	}
}

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

static func get_component_data(component_type: String) -> Dictionary:
	return COMPONENTS.get(component_type, {})

static func get_all_component_types() -> Array:
	return COMPONENTS.keys()

static func is_valid_component_type(component_type: String) -> bool:
	return COMPONENTS.has(component_type)

static func get_hull_cost(hull_type: CosmoteerShipBlueprint.HullType) -> Dictionary:
	return HULL_COSTS.get(hull_type, {})

static func get_hull_weight(hull_type: CosmoteerShipBlueprint.HullType) -> float:
	return HULL_WEIGHTS.get(hull_type, 0.0)

static func get_hull_color(hull_type: CosmoteerShipBlueprint.HullType) -> Color:
	return HULL_COLORS.get(hull_type, Color.WHITE)

static func get_hull_name(hull_type: CosmoteerShipBlueprint.HullType) -> String:
	return HULL_NAMES.get(hull_type, "Unknown")

