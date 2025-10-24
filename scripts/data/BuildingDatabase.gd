extends Node
## Database for building construction - costs, build times, and metadata

# Building data structure:
# {
#   scene: String - path to building scene
#   build_time: float - seconds to construct
#   cost: Dictionary - {resource_id: amount}
#   max_per_zone: int - maximum buildings per zone (-1 = unlimited)
#   collision_radius: float - minimum spacing from other buildings
#   display_name: String
#   description: String
#   icon_path: String
#   health: float
#   requires_research: String - research ID that must be unlocked (empty = always available)
# }

const BUILDINGS = {
	"ResearchBuilding": {
		scene = "res://scenes/buildings/ResearchBuilding.tscn",
		build_time = 120.0,
		cost = {0: 300, 1: 250, 2: 200, 10: 150},  # Iron, Carbon, Silicon, Copper
		max_per_zone = 1,
		collision_radius = 100.0,
		display_name = "Research Facility",
		description = "Central research hub. Unlocks new technologies through the tech tree.",
		icon_path = "res://assets/ui/Grey/panel_beveledGrey.png",
		health = 1500.0,
		requires_research = ""
	},
	
	"BulletTurret": {
		scene = "res://scenes/buildings/BulletTurret.tscn",
		build_time = 30.0,
		cost = {0: 100, 10: 80, 14: 60},  # Iron, Copper, Nickel
		max_per_zone = -1,
		collision_radius = 60.0,
		display_name = "Bullet Turret",
		description = "Basic defensive turret. Fires kinetic projectiles at enemies.",
		icon_path = "res://assets/ui/Grey/panel_beveledGrey.png",
		health = 400.0,
		requires_research = "building_turret_basic"
	},
	
	"LaserTurret": {
		scene = "res://scenes/buildings/LaserTurret.tscn",
		build_time = 45.0,
		cost = {2: 120, 21: 100, 31: 80},  # Silicon, Lithium, Titanium
		max_per_zone = -1,
		collision_radius = 60.0,
		display_name = "Laser Turret",
		description = "Energy weapon turret. Fires concentrated laser beams.",
		icon_path = "res://assets/ui/Grey/panel_beveledGrey.png",
		health = 450.0,
		requires_research = "building_turret_laser"
	},
	
	"MissileTurret": {
		scene = "res://scenes/buildings/MissileTurret.tscn",
		build_time = 50.0,
		cost = {1: 130, 7: 110, 15: 90},  # Carbon, Sulfur, Cobalt
		max_per_zone = -1,
		collision_radius = 60.0,
		display_name = "Missile Turret",
		description = "Long-range missile turret. Fires guided missiles with splash damage.",
		icon_path = "res://assets/ui/Grey/panel_beveledGrey.png",
		health = 500.0,
		requires_research = "building_turret_missile"
	},
	
	"PlasmaTurret": {
		scene = "res://scenes/buildings/PlasmaTurret.tscn",
		build_time = 75.0,
		cost = {65: 200, 66: 180, 67: 160},  # Plasma Core, Fusion Catalyst, Antimatter
		max_per_zone = -1,
		collision_radius = 70.0,
		display_name = "Plasma Turret",
		description = "Advanced energy turret. Fires superheated plasma with splash damage.",
		icon_path = "res://assets/ui/Grey/panel_beveledGrey.png",
		health = 700.0,
		requires_research = "building_turret_plasma"
	},
	
	"DroneFactory": {
		scene = "res://scenes/buildings/DroneFactory.tscn",
		build_time = 90.0,
		cost = {0: 250, 10: 200, 30: 150},  # Iron, Copper, Gold
		max_per_zone = 3,
		collision_radius = 90.0,
		display_name = "Drone Factory",
		description = "Automated production facility. Continuously produces drones.",
		icon_path = "res://assets/ui/Grey/panel_beveledGrey.png",
		health = 1000.0,
		requires_research = "building_factory"
	},
	
	"Refinery": {
		scene = "res://scenes/buildings/Refinery.tscn",
		build_time = 60.0,
		cost = {0: 180, 2: 150, 10: 120},  # Iron, Silicon, Copper
		max_per_zone = 5,
		collision_radius = 80.0,
		display_name = "Resource Refinery",
		description = "Converts lower-tier resources into higher-tier materials.",
		icon_path = "res://assets/ui/Grey/panel_beveledGrey.png",
		health = 600.0,
		requires_research = "building_refinery"
	},
	
	"AdvancedRefinery": {
		scene = "res://scenes/buildings/AdvancedRefinery.tscn",
		build_time = 90.0,
		cost = {30: 250, 40: 220, 60: 200},  # Gold, Platinum, Exotic Alloy
		max_per_zone = 3,
		collision_radius = 90.0,
		display_name = "Advanced Refinery",
		description = "High-speed refinery with better conversion rates.",
		icon_path = "res://assets/ui/Grey/panel_beveledGrey.png",
		health = 900.0,
		requires_research = "building_refinery_advanced"
	},
	
	"ShieldGenerator": {
		scene = "res://scenes/buildings/ShieldGenerator.tscn",
		build_time = 80.0,
		cost = {21: 200, 62: 180, 70: 160},  # Lithium, Quantum Crystal, Dark Energy
		max_per_zone = 2,
		collision_radius = 100.0,
		display_name = "Shield Generator",
		description = "Projects protective energy shield over surrounding area.",
		icon_path = "res://assets/ui/Grey/panel_beveledGrey.png",
		health = 800.0,
		requires_research = "building_shield_generator"
	},
	
	"RepairStation": {
		scene = "res://scenes/buildings/RepairStation.tscn",
		build_time = 70.0,
		cost = {0: 200, 20: 170, 60: 150},  # Iron, Silver, Exotic Alloy
		max_per_zone = 4,
		collision_radius = 80.0,
		display_name = "Repair Station",
		description = "Automatically repairs damaged units in range.",
		icon_path = "res://assets/ui/Grey/panel_beveledGrey.png",
		health = 750.0,
		requires_research = "building_repair_station"
	},
	
	"SensorArray": {
		scene = "res://scenes/buildings/SensorArray.tscn",
		build_time = 50.0,
		cost = {2: 150, 32: 130, 62: 110},  # Silicon, Gallium, Quantum Crystal
		max_per_zone = 3,
		collision_radius = 70.0,
		display_name = "Sensor Array",
		description = "Advanced sensors. Greatly extends vision range in zone.",
		icon_path = "res://assets/ui/Grey/panel_beveledGrey.png",
		health = 500.0,
		requires_research = "building_sensor_array"
	},
	
	"MiningPlatform": {
		scene = "res://scenes/buildings/MiningPlatform.tscn",
		build_time = 40.0,
		cost = {0: 150, 1: 130, 10: 110},  # Iron, Carbon, Copper
		max_per_zone = -1,
		collision_radius = 70.0,
		display_name = "Mining Platform",
		description = "Automated mining station. Extracts resources from nearby asteroids.",
		icon_path = "res://assets/ui/Grey/panel_beveledGrey.png",
		health = 550.0,
		requires_research = "building_mining_platform"
	},
	
	"TeleportPad": {
		scene = "res://scenes/buildings/TeleportPad.tscn",
		build_time = 100.0,
		cost = {72: 280, 74: 250, 83: 230},  # Spacetime Fabric, Warp Particle, Dimensional Shard
		max_per_zone = 2,
		collision_radius = 80.0,
		display_name = "Teleport Pad",
		description = "Enables instant unit transport between teleport pads.",
		icon_path = "res://assets/ui/Grey/panel_beveledGrey.png",
		health = 1200.0,
		requires_research = "building_teleporter"
	},
	
	"SuperweaponPlatform": {
		scene = "res://scenes/buildings/SuperweaponPlatform.tscn",
		build_time = 180.0,
		cost = {70: 400, 85: 380, 92: 350, 97: 330},  # Dark Energy, Void Essence, Exotic Matter, Infinitum
		max_per_zone = 1,
		collision_radius = 120.0,
		display_name = "Superweapon Platform",
		description = "Ultimate weapon. Devastating zone-wide attack capability.",
		icon_path = "res://assets/ui/Grey/panel_beveledGrey.png",
		health = 3000.0,
		requires_research = "building_superweapon"
	}
}

func get_building_data(building_type: String) -> Dictionary:
	"""Get building data by type name"""
	if building_type in BUILDINGS:
		return BUILDINGS[building_type]
	return {}

func get_all_buildings() -> Dictionary:
	"""Get all building data"""
	return BUILDINGS

func get_buildable_buildings() -> Array:
	"""Get list of buildings that can be built (research requirements met)"""
	var buildable = []
	for building_name in BUILDINGS:
		var data = BUILDINGS[building_name]
		var research_req = data.requires_research
		
		# Check if research requirement is met
		if research_req == "" or (ResearchManager and ResearchManager.is_unlocked(research_req)):
			buildable.append(building_name)
	
	return buildable

func can_build_in_zone(building_type: String, zone_id: int) -> bool:
	"""Check if building can be built in zone (zone limit check)"""
	var data = get_building_data(building_type)
	if data.is_empty():
		return false
	
	var max_per_zone = data.max_per_zone
	if max_per_zone == -1:
		return true  # Unlimited
	
	# Count existing buildings of this type in zone
	var count = get_building_count_in_zone(building_type, zone_id)
	return count < max_per_zone

func get_building_count_in_zone(building_type: String, zone_id: int) -> int:
	"""Count how many buildings of this type exist in zone"""
	if not EntityManager:
		return 0
	
	var count = 0
	var buildings_in_zone = EntityManager.get_buildings_in_zone(zone_id)
	
	for building in buildings_in_zone:
		if not is_instance_valid(building):
			continue
		
		# Check building type by class name or custom property
		if "building_type" in building and building.building_type == building_type:
			count += 1
	
	return count

func is_valid_placement(building_type: String, world_pos: Vector2, zone_id: int) -> bool:
	"""Check if building can be placed at position"""
	var data = get_building_data(building_type)
	if data.is_empty():
		return false
	
	var radius = data.collision_radius
	
	# Check collision with other buildings
	if EntityManager:
		var nearby_buildings = EntityManager.get_buildings_in_zone(zone_id)
		for building in nearby_buildings:
			if not is_instance_valid(building):
				continue
			
			var distance = world_pos.distance_to(building.global_position)
			if distance < radius:
				return false
	
	# Check collision with resources
	if EntityManager:
		var nearby_resources = EntityManager.get_resources_in_zone(zone_id)
		for resource in nearby_resources:
			if not is_instance_valid(resource):
				continue
			
			var distance = world_pos.distance_to(resource.global_position)
			if distance < 50:  # Minimum distance from resources
				return false
	
	return true

func get_construction_cost_text(building_type: String) -> String:
	"""Get formatted cost string for UI display"""
	var data = get_building_data(building_type)
	if data.is_empty():
		return ""
	
	var cost_parts = []
	for resource_id in data.cost:
		var amount = data.cost[resource_id]
		var resource_name = ResourceDatabase.get_resource_name(resource_id)
		cost_parts.append("%s: %d" % [resource_name, amount])
	
	return ", ".join(cost_parts)

func get_build_time_text(building_type: String) -> String:
	"""Get formatted build time for UI display"""
	var data = get_building_data(building_type)
	if data.is_empty():
		return ""
	
	var time = data.build_time
	if time < 60:
		return "%ds" % int(time)
	else:
		var minutes = int(time / 60)
		var seconds = int(time) % 60
		return "%dm %ds" % [minutes, seconds]


