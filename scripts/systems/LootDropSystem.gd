extends Node
## Manages resource drops from killed enemies
## Auto-collected by mining drones

signal loot_dropped(position: Vector2, resources: Dictionary)

# Drop configuration
const BASE_DROP_AMOUNT = 10  # Base resources per kill
const ZONE_MULTIPLIER = 1.5  # Multiplier per zone level
const BOSS_MULTIPLIER = 5.0  # Bosses drop 5x more

# Rarity tiers for enemy types
const RARITY_RANGES = {
	"fighter": {"min": 0, "max": 19, "count": 1},      # 1 common resource
	"cruiser": {"min": 0, "max": 39, "count": 2},      # 1 common + 1 rare
	"bomber": {"min": 0, "max": 59, "count": 3},       # common + rare + exotic
}

# Preload loot orb scene
var loot_orb_scene: PackedScene = null

func _ready():
	# Load loot orb scene (will create later)
	loot_orb_scene = load("res://scenes/effects/LootOrb.tscn")

func drop_loot(enemy: Node2D):
	"""Called when enemy dies - spawns resource drops"""
	var zone_id = enemy.get_meta("zone_id", 1)
	var is_boss = enemy.get_meta("is_boss", false)
	var enemy_type = get_enemy_type(enemy)
	
	# Calculate drop amount
	var drop_amount = calculate_drop_amount(zone_id, is_boss)
	
	# Determine which resources to drop
	var resources = roll_resource_drops(enemy_type, drop_amount, zone_id)
	
	# Spawn visual loot drops
	spawn_loot_visual(enemy.global_position, resources, zone_id)
	
	# Emit signal for mining drones to collect
	loot_dropped.emit(enemy.global_position, resources)

func calculate_drop_amount(zone_id: int, is_boss: bool) -> int:
	"""Calculate total resource amount to drop"""
	var amount = float(BASE_DROP_AMOUNT)
	
	# Zone scaling
	amount *= pow(ZONE_MULTIPLIER, zone_id - 1)
	
	# Boss bonus
	if is_boss:
		amount *= BOSS_MULTIPLIER
	
	return int(amount)

func roll_resource_drops(enemy_type: String, total_amount: int, zone_id: int) -> Dictionary:
	"""Roll which specific resources to drop"""
	var drops = {}
	var rarity_config = RARITY_RANGES.get(enemy_type, RARITY_RANGES["fighter"])
	
	# Split amount across multiple resource types
	var drops_per_type = total_amount / rarity_config["count"]
	
	for i in range(rarity_config["count"]):
		# Pick random resource ID within rarity range
		var resource_id = randi_range(rarity_config["min"], rarity_config["max"])
		
		# Zone bonus: higher zones have chance for better resources
		if zone_id > 5 and randf() < 0.3:
			resource_id = min(resource_id + 10, rarity_config["max"])
		
		drops[resource_id] = int(drops_per_type)
	
	return drops

func get_enemy_type(enemy: Node2D) -> String:
	"""Determine enemy type from class name"""
	# Check script name
	if "EnemyFighter" in str(enemy):
		return "fighter"
	elif "EnemyCruiser" in str(enemy):
		return "cruiser"
	elif "EnemyBomber" in str(enemy):
		return "bomber"
	
	# Fallback - check node name
	var node_name = enemy.name.to_lower()
	if "fighter" in node_name:
		return "fighter"
	elif "cruiser" in node_name:
		return "cruiser"
	elif "bomber" in node_name:
		return "bomber"
	
	return "fighter"

func spawn_loot_visual(position: Vector2, resources: Dictionary, zone_id: int):
	"""Spawn visual loot pickups (glowing orbs)"""
	if not loot_orb_scene:
		return
	
	for resource_id in resources.keys():
		var amount = resources[resource_id]
		var loot_orb = create_loot_orb(position, resource_id, amount, zone_id)
		
		# Add to scene tree
		var zone_layer = ZoneManager.get_zone(zone_id).layer_node if ZoneManager else null
		if zone_layer:
			var effects_container = zone_layer.get_node_or_null("Entities/Effects")
			if not effects_container:
				effects_container = zone_layer.get_node_or_null("Entities")
			if effects_container:
				effects_container.add_child(loot_orb)

func create_loot_orb(position: Vector2, resource_id: int, amount: int, zone_id: int) -> Node2D:
	"""Create a glowing orb representing dropped loot"""
	var orb = loot_orb_scene.instantiate()
	orb.global_position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	
	# Set up orb properties
	if orb.has_method("setup"):
		orb.setup(resource_id, amount)
	else:
		# Fallback if scene doesn't have setup method
		orb.set_meta("resource_id", resource_id)
		orb.set_meta("amount", amount)
	
	# Add to loot group for mining drones to find
	orb.add_to_group("loot")
	orb.set_meta("zone_id", zone_id)
	
	return orb

func get_resource_color(resource_id: int) -> Color:
	"""Get color based on rarity tier"""
	if resource_id < 20:
		return Color(0.8, 0.8, 0.8)  # Common - gray/white
	elif resource_id < 40:
		return Color(0.3, 0.7, 1.0)  # Rare - blue
	elif resource_id < 60:
		return Color(0.9, 0.3, 0.9)  # Exotic - purple
	else:
		return Color(1.0, 0.8, 0.0)  # Legendary - gold

