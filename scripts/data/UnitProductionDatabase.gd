extends Node
## Database for unit production data - costs, build times, and metadata

# Production data for each unit type
var production_data = {
	"ScoutDrone": {
		"build_time": 5.0,
		"base_cost": {0: 10, 1: 10, 2: 10},  # Tier 0 resource IDs
		"display_name": "Scout Drone",
		"description": "Fast reconnaissance unit",
		"scene": "res://scenes/units/ScoutDrone.tscn",
		"icon_path": "res://assets/sprites/playerShip1_blue.png"
	},
	"MiningDrone": {
		"build_time": 8.0,
		"base_cost": {0: 15, 1: 15, 2: 15},
		"display_name": "Mining Drone",
		"description": "Resource gathering unit",
		"scene": "res://scenes/units/MiningDrone.tscn",
		"icon_path": "res://assets/sprites/playerShip2_blue.png"
	},
	"CombatDrone": {
		"build_time": 10.0,
		"base_cost": {0: 20, 1: 20, 2: 20},
		"display_name": "Combat Drone",
		"description": "Basic combat unit",
		"scene": "res://scenes/units/CombatDrone.tscn",
		"icon_path": "res://assets/sprites/playerShip3_blue.png"
	},
	"BuilderDrone": {
		"build_time": 12.0,
		"base_cost": {0: 25, 1: 25, 2: 25},
		"display_name": "Builder Drone",
		"description": "Construction unit",
		"scene": "res://scenes/units/BuilderDrone.tscn",
		"icon_path": "res://assets/sprites/playerShip1_green.png"
	},
	"SupportDrone": {
		"build_time": 15.0,
		"base_cost": {0: 30, 1: 30, 2: 30},
		"display_name": "Support Drone",
		"description": "Repair and support unit",
		"scene": "res://scenes/units/SupportDrone.tscn",
		"icon_path": "res://assets/sprites/playerShip2_green.png"
	},
	"HeavyDrone": {
		"build_time": 18.0,
		"base_cost": {0: 35, 1: 35, 2: 35},
		"display_name": "Heavy Drone",
		"description": "Heavy assault unit",
		"scene": "res://scenes/units/HeavyDrone.tscn",
		"icon_path": "res://assets/sprites/playerShip3_green.png"
	}
}


func get_production_data(unit_type: String) -> Dictionary:
	"""Get production data for a specific unit type"""
	return production_data.get(unit_type, {})

func get_all_buildable_units() -> Array:
	"""Get list of all buildable unit types"""
	return production_data.keys()

func get_base_cost(unit_type: String) -> Dictionary:
	"""Get base resource cost for a unit type"""
	var data = get_production_data(unit_type)
	return data.get("base_cost", {})

func get_build_time(unit_type: String) -> float:
	"""Get build time for a unit type"""
	var data = get_production_data(unit_type)
	return data.get("build_time", 10.0)

func get_scene_path(unit_type: String) -> String:
	"""Get scene path for a unit type"""
	var data = get_production_data(unit_type)
	return data.get("scene", "")
