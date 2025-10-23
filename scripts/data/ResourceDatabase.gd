extends Node
## Database of 100 unique resource types with rarity tiers and properties

# Resource data structure: {name, tier, value, color}
const RESOURCES = [
	# Tier 0 - Common (10 types)
	{name="Iron Ore", tier=0, value=1.0, color=Color(0.6, 0.6, 0.6)},
	{name="Carbon", tier=0, value=1.1, color=Color(0.2, 0.2, 0.2)},
	{name="Silicon", tier=0, value=1.0, color=Color(0.7, 0.7, 0.5)},
	{name="Aluminum", tier=0, value=1.2, color=Color(0.8, 0.8, 0.9)},
	{name="Magnesium", tier=0, value=1.1, color=Color(0.7, 0.7, 0.7)},
	{name="Calcium", tier=0, value=1.0, color=Color(0.9, 0.9, 0.8)},
	{name="Sulfur", tier=0, value=1.1, color=Color(0.9, 0.9, 0.3)},
	{name="Phosphorus", tier=0, value=1.2, color=Color(0.9, 0.5, 0.3)},
	{name="Oxygen Ice", tier=0, value=1.0, color=Color(0.7, 0.8, 0.9)},
	{name="Nitrogen Ice", tier=0, value=1.1, color=Color(0.6, 0.7, 0.8)},
	
	# Tier 1 - Common (10 types)
	{name="Copper", tier=1, value=1.5, color=Color(0.8, 0.5, 0.2)},
	{name="Zinc", tier=1, value=1.4, color=Color(0.7, 0.7, 0.8)},
	{name="Lead", tier=1, value=1.3, color=Color(0.5, 0.5, 0.5)},
	{name="Tin", tier=1, value=1.4, color=Color(0.7, 0.7, 0.7)},
	{name="Nickel", tier=1, value=1.6, color=Color(0.8, 0.8, 0.7)},
	{name="Cobalt", tier=1, value=1.7, color=Color(0.5, 0.5, 0.7)},
	{name="Manganese", tier=1, value=1.5, color=Color(0.6, 0.5, 0.5)},
	{name="Chromium", tier=1, value=1.6, color=Color(0.7, 0.7, 0.8)},
	{name="Vanadium", tier=1, value=1.7, color=Color(0.6, 0.6, 0.7)},
	{name="Graphite", tier=1, value=1.5, color=Color(0.3, 0.3, 0.3)},
	
	# Tier 2 - Common (10 types)
	{name="Silver", tier=2, value=2.0, color=Color(0.9, 0.9, 0.95)},
	{name="Lithium", tier=2, value=2.2, color=Color(0.8, 0.8, 0.9)},
	{name="Beryllium", tier=2, value=2.3, color=Color(0.7, 0.8, 0.7)},
	{name="Boron", tier=2, value=2.1, color=Color(0.6, 0.5, 0.4)},
	{name="Tungsten", tier=2, value=2.4, color=Color(0.5, 0.5, 0.6)},
	{name="Molybdenum", tier=2, value=2.2, color=Color(0.6, 0.6, 0.7)},
	{name="Zirconium", tier=2, value=2.3, color=Color(0.8, 0.8, 0.8)},
	{name="Niobium", tier=2, value=2.4, color=Color(0.7, 0.7, 0.8)},
	{name="Ruthenium", tier=2, value=2.5, color=Color(0.6, 0.7, 0.7)},
	{name="Cesium", tier=2, value=2.1, color=Color(0.9, 0.8, 0.5)},
	
	# Tier 3 - Uncommon (10 types)
	{name="Gold", tier=3, value=3.0, color=Color(1.0, 0.84, 0.0)},
	{name="Titanium", tier=3, value=3.2, color=Color(0.75, 0.76, 0.78)},
	{name="Gallium", tier=3, value=3.1, color=Color(0.7, 0.8, 0.9)},
	{name="Germanium", tier=3, value=3.3, color=Color(0.6, 0.7, 0.7)},
	{name="Indium", tier=3, value=3.2, color=Color(0.7, 0.7, 0.8)},
	{name="Hafnium", tier=3, value=3.4, color=Color(0.8, 0.8, 0.85)},
	{name="Tantalum", tier=3, value=3.5, color=Color(0.6, 0.6, 0.7)},
	{name="Rhenium", tier=3, value=3.6, color=Color(0.7, 0.7, 0.75)},
	{name="Osmium", tier=3, value=3.4, color=Color(0.5, 0.6, 0.7)},
	{name="Scandium", tier=3, value=3.3, color=Color(0.8, 0.8, 0.9)},
	
	# Tier 4 - Uncommon (10 types)
	{name="Platinum", tier=4, value=4.5, color=Color(0.9, 0.89, 0.89)},
	{name="Palladium", tier=4, value=4.3, color=Color(0.8, 0.8, 0.85)},
	{name="Rhodium", tier=4, value=4.7, color=Color(0.75, 0.75, 0.8)},
	{name="Iridium", tier=4, value=4.6, color=Color(0.85, 0.85, 0.9)},
	{name="Europium", tier=4, value=4.2, color=Color(0.9, 0.7, 0.8)},
	{name="Gadolinium", tier=4, value=4.3, color=Color(0.8, 0.8, 0.9)},
	{name="Terbium", tier=4, value=4.4, color=Color(0.7, 0.9, 0.8)},
	{name="Dysprosium", tier=4, value=4.5, color=Color(0.8, 0.9, 0.9)},
	{name="Holmium", tier=4, value=4.4, color=Color(0.9, 0.8, 0.7)},
	{name="Erbium", tier=4, value=4.3, color=Color(0.9, 0.7, 0.9)},
	
	# Tier 5 - Uncommon (10 types)
	{name="Lutetium", tier=5, value=5.5, color=Color(0.9, 0.9, 0.95)},
	{name="Thulium", tier=5, value=5.3, color=Color(0.8, 0.9, 0.8)},
	{name="Ytterbium", tier=5, value=5.4, color=Color(0.85, 0.85, 0.95)},
	{name="Praseodymium", tier=5, value=5.2, color=Color(0.7, 0.9, 0.7)},
	{name="Neodymium", tier=5, value=5.6, color=Color(0.8, 0.8, 1.0)},
	{name="Promethium", tier=5, value=5.7, color=Color(0.9, 0.8, 0.95)},
	{name="Samarium", tier=5, value=5.4, color=Color(0.85, 0.9, 0.85)},
	{name="Lanthanum", tier=5, value=5.3, color=Color(0.8, 0.85, 0.9)},
	{name="Cerium", tier=5, value=5.2, color=Color(0.9, 0.85, 0.8)},
	{name="Yttrium", tier=5, value=5.5, color=Color(0.85, 0.85, 0.9)},
	
	# Tier 6 - Rare (10 types)
	{name="Exotic Alloy", tier=6, value=8.0, color=Color(0.5, 0.8, 1.0)},
	{name="Crystalline Matrix", tier=6, value=8.5, color=Color(0.7, 0.9, 1.0)},
	{name="Quantum Crystal", tier=6, value=9.0, color=Color(0.6, 1.0, 0.9)},
	{name="Graviton Particle", tier=6, value=8.7, color=Color(0.8, 0.7, 1.0)},
	{name="Neutronium Fragment", tier=6, value=9.2, color=Color(0.9, 0.9, 1.0)},
	{name="Plasma Core", tier=6, value=8.3, color=Color(1.0, 0.5, 0.5)},
	{name="Fusion Catalyst", tier=6, value=8.8, color=Color(1.0, 0.8, 0.3)},
	{name="Antimatter Trace", tier=6, value=9.5, color=Color(1.0, 0.3, 0.8)},
	{name="Higgs Boson", tier=6, value=9.3, color=Color(0.3, 0.8, 1.0)},
	{name="Quark Matter", tier=6, value=8.9, color=Color(0.7, 0.3, 1.0)},
	
	# Tier 7 - Rare (10 types)
	{name="Dark Energy Cell", tier=7, value=12.0, color=Color(0.2, 0.1, 0.4)},
	{name="Singularity Fragment", tier=7, value=13.5, color=Color(0.1, 0.0, 0.3)},
	{name="Spacetime Fabric", tier=7, value=14.0, color=Color(0.3, 0.2, 0.5)},
	{name="Warp Particle", tier=7, value=12.8, color=Color(0.4, 0.3, 0.7)},
	{name="Tachyon Crystal", tier=7, value=13.2, color=Color(0.5, 0.4, 0.8)},
	{name="Zero-Point Energy", tier=7, value=14.5, color=Color(0.6, 0.5, 0.9)},
	{name="Neutrino Condensate", tier=7, value=12.5, color=Color(0.3, 0.5, 0.7)},
	{name="Muon Cluster", tier=7, value=13.0, color=Color(0.4, 0.6, 0.8)},
	{name="Photonic Lattice", tier=7, value=12.7, color=Color(0.8, 0.9, 1.0)},
	{name="Gluon Plasma", tier=7, value=13.8, color=Color(0.9, 0.4, 0.6)},
	
	# Tier 8 - Ultra-Rare (10 types)
	{name="Chrono Crystal", tier=8, value=20.0, color=Color(0.8, 0.2, 1.0)},
	{name="Dimensional Shard", tier=8, value=22.0, color=Color(0.6, 0.1, 0.9)},
	{name="Void Essence", tier=8, value=25.0, color=Color(0.1, 0.0, 0.2)},
	{name="Reality Anchor", tier=8, value=23.5, color=Color(0.9, 0.3, 0.9)},
	{name="Temporal Paradox", tier=8, value=24.0, color=Color(0.7, 0.2, 0.8)},
	{name="Quantum Foam", tier=8, value=21.5, color=Color(0.5, 0.6, 1.0)},
	{name="Planck Particle", tier=8, value=26.0, color=Color(1.0, 0.9, 1.0)},
	{name="Hawking Radiation", tier=8, value=22.5, color=Color(0.3, 0.3, 0.5)},
	{name="Cosmic String", tier=8, value=24.5, color=Color(0.4, 0.2, 0.6)},
	{name="Entropy Reversal", tier=8, value=23.0, color=Color(0.6, 0.3, 0.7)},
	
	# Tier 9 - Ultra-Rare (10 types)
	{name="Dark Matter", tier=9, value=50.0, color=Color(0.15, 0.0, 0.3)},
	{name="Strange Matter", tier=9, value=55.0, color=Color(0.2, 0.1, 0.4)},
	{name="Exotic Matter", tier=9, value=60.0, color=Color(0.3, 0.0, 0.5)},
	{name="Omnium", tier=9, value=70.0, color=Color(1.0, 0.5, 1.0)},
	{name="Unobtainium", tier=9, value=65.0, color=Color(0.0, 1.0, 1.0)},
	{name="Impossibilium", tier=9, value=75.0, color=Color(1.0, 0.0, 1.0)},
	{name="Paradoxite", tier=9, value=80.0, color=Color(0.5, 0.0, 0.5)},
	{name="Infinitum", tier=9, value=90.0, color=Color(1.0, 1.0, 1.0)},
	{name="Negentropy", tier=9, value=85.0, color=Color(0.9, 0.0, 0.9)},
	{name="Cosmicite", tier=9, value=95.0, color=Color(0.7, 0.3, 1.0)},
]

# Tier spawn weights (used for weighted random selection)
const TIER_WEIGHTS = {
	0: 15.0,  # 15%
	1: 15.0,  # 15%
	2: 30.0,  # 30% (Total Tier 0-2: 60%)
	3: 10.0,  # 10%
	4: 8.0,   # 8%
	5: 7.0,   # 7% (Total Tier 3-5: 25%)
	6: 5.0,   # 5%
	7: 5.0,   # 5% (Total Tier 6-7: 10%)
	8: 3.0,   # 3%
	9: 2.0,   # 2% (Total Tier 8-9: 5%)
}


func get_resource_by_id(id: int) -> Dictionary:
	"""Get resource data by ID (array index)"""
	if id >= 0 and id < RESOURCES.size():
		return RESOURCES[id]
	return {}

func get_resource_name(id: int) -> String:
	"""Get resource name by ID"""
	var resource = get_resource_by_id(id)
	if resource.is_empty():
		return "Unknown"
	return resource.name

func get_resource_color(id: int) -> Color:
	"""Get resource color by ID"""
	var resource = get_resource_by_id(id)
	if resource.is_empty():
		return Color.WHITE
	return resource.color

func get_resource_value(id: int) -> float:
	"""Get resource base value multiplier by ID"""
	var resource = get_resource_by_id(id)
	if resource.is_empty():
		return 1.0
	return resource.value

func get_resource_tier(id: int) -> int:
	"""Get resource tier by ID"""
	var resource = get_resource_by_id(id)
	if resource.is_empty():
		return 0
	return resource.tier

func get_weighted_random_resource() -> int:
	"""Get a random resource ID weighted by tier rarity"""
	# First, select a tier based on weights
	var tier = select_weighted_tier()
	
	# Then, get a random resource from that tier
	return get_random_resource_by_tier(tier)

func get_weighted_random_resource_for_zone(zone_id: int) -> int:
	"""Get a random resource ID for a specific zone (cumulative tiers)
	Zone 1 = Tier 0 only
	Zone 2 = Tiers 0-1
	Zone 3 = Tiers 0-2
	...
	Zone 9 = Tiers 0-8
	"""
	var max_tier = zone_id - 1  # Zone 1 = max tier 0, Zone 2 = max tier 1, etc.
	max_tier = clamp(max_tier, 0, 9)
	
	# Select tier using weighted distribution, but only from available tiers
	var tier = select_weighted_tier_for_zone(max_tier)
	
	# Get random resource from that tier
	return get_random_resource_by_tier(tier)

func select_weighted_tier() -> int:
	"""Select a tier based on weighted probabilities"""
	var total_weight = 0.0
	for weight in TIER_WEIGHTS.values():
		total_weight += weight
	
	var rand_value = randf() * total_weight
	var cumulative = 0.0
	
	for tier in range(10):
		cumulative += TIER_WEIGHTS[tier]
		if rand_value <= cumulative:
			return tier
	
	return 0  # Fallback

func select_weighted_tier_for_zone(max_tier: int) -> int:
	"""Select a tier based on weighted probabilities, limited to max_tier"""
	# Calculate total weight for available tiers only
	var total_weight = 0.0
	for tier in range(max_tier + 1):
		if tier in TIER_WEIGHTS:
			total_weight += TIER_WEIGHTS[tier]
	
	if total_weight <= 0:
		return 0
	
	var rand_value = randf() * total_weight
	var cumulative = 0.0
	
	for tier in range(max_tier + 1):
		if tier in TIER_WEIGHTS:
			cumulative += TIER_WEIGHTS[tier]
			if rand_value <= cumulative:
				return tier
	
	return 0  # Fallback

func get_random_resource_by_tier(tier: int) -> int:
	"""Get a random resource ID from a specific tier"""
	var tier_resources = []
	
	for i in range(RESOURCES.size()):
		if RESOURCES[i].tier == tier:
			tier_resources.append(i)
	
	if tier_resources.is_empty():
		return 0  # Fallback to first resource
	
	return tier_resources[randi() % tier_resources.size()]

func get_all_resources() -> Array:
	"""Get all resource data"""
	return RESOURCES

func get_resource_count() -> int:
	"""Get total number of resource types"""
	return RESOURCES.size()

func get_resources_by_tier(tier: int) -> Array:
	"""Get all resources of a specific tier"""
	var tier_resources = []
	for i in range(RESOURCES.size()):
		if RESOURCES[i].tier == tier:
			tier_resources.append(i)
	return tier_resources
