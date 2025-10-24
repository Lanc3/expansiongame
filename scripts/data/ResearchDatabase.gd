extends Node
## Comprehensive research tech tree database with 130+ nodes across 7 categories

# Research node structure:
# {
#   id: String - unique identifier
#   name: String - display name
#   description: String - detailed effect description
#   prerequisites: Array[String] - research IDs that must be unlocked first
#   cost: Dictionary - {resource_id: amount}
#   research_time: float - seconds to research (10-120 based on tier)
#   category: String - hull/shield/weapon/ability/building/economy/blueprint
#   tier: int - difficulty tier (0-9)
#   effects: Dictionary - stat modifiers or unlocks
#   unlock_type: String - "upgrade", "building", "ability", "unit", "blueprint_component"
#   position: Vector2 - UI position in tech tree (optional, can be calculated)
# }

const RESEARCH_NODES = [
	# ============================================================================
	# HULL RESEARCH BRANCH (15 nodes)
	# ============================================================================
	{
		id = "hull_reinforced_1",
		name = "Reinforced Hull I",
		description = "Basic hull reinforcement. +15% hull strength for all units.",
		prerequisites = [],
		cost = {0: 50, 1: 30},  # Iron Ore, Carbon
		category = "hull",
		tier = 0,
		effects = {stat_hull_multiplier = 1.15},
		unlock_type = "upgrade",
		position = Vector2(100, 100)
	},
	{
		id = "hull_reinforced_2",
		name = "Reinforced Hull II",
		description = "Improved hull reinforcement. +30% hull strength for all units.",
		prerequisites = ["hull_reinforced_1"],
		cost = {0: 100, 1: 60, 2: 40},  # Iron, Carbon, Silicon
		category = "hull",
		tier = 1,
		effects = {stat_hull_multiplier = 1.30},
		unlock_type = "upgrade",
		position = Vector2(250, 100)
	},
	{
		id = "hull_composite_1",
		name = "Composite Armor I",
		description = "Advanced composite materials. +50% hull strength.",
		prerequisites = ["hull_reinforced_2"],
		cost = {3: 80, 10: 50, 11: 40},  # Aluminum, Copper, Zinc
		category = "hull",
		tier = 2,
		effects = {stat_hull_multiplier = 1.50},
		unlock_type = "upgrade",
		position = Vector2(400, 100)
	},
	{
		id = "hull_composite_2",
		name = "Composite Armor II",
		description = "Enhanced composite plating. +75% hull strength.",
		prerequisites = ["hull_composite_1"],
		cost = {20: 100, 21: 80, 22: 60},  # Silver, Lithium, Beryllium
		category = "hull",
		tier = 3,
		effects = {stat_hull_multiplier = 1.75},
		unlock_type = "upgrade",
		position = Vector2(550, 100)
	},
	{
		id = "hull_alloy_advanced",
		name = "Advanced Alloy Plating",
		description = "Exotic alloy construction. +100% hull strength.",
		prerequisites = ["hull_composite_2"],
		cost = {30: 120, 31: 100, 32: 80},  # Gold, Titanium, Gallium
		category = "hull",
		tier = 4,
		effects = {stat_hull_multiplier = 2.0},
		unlock_type = "upgrade",
		position = Vector2(700, 100)
	},
	{
		id = "hull_crystalline_1",
		name = "Crystalline Matrix Hull",
		description = "Crystalline-reinforced structure. +150% hull strength.",
		prerequisites = ["hull_alloy_advanced"],
		cost = {40: 150, 41: 120, 61: 100},  # Platinum, Palladium, Crystalline Matrix
		category = "hull",
		tier = 5,
		effects = {stat_hull_multiplier = 2.5},
		unlock_type = "upgrade",
		position = Vector2(850, 100)
	},
	{
		id = "hull_crystalline_2",
		name = "Quantum Crystal Hull",
		description = "Quantum-enhanced crystalline armor. +200% hull strength.",
		prerequisites = ["hull_crystalline_1"],
		cost = {62: 180, 63: 150, 64: 120},  # Quantum Crystal, Graviton, Neutronium
		category = "hull",
		tier = 6,
		effects = {stat_hull_multiplier = 3.0},
		unlock_type = "upgrade",
		position = Vector2(1000, 100)
	},
	{
		id = "hull_neutronium",
		name = "Neutronium Plating",
		description = "Ultra-dense neutronium armor. +300% hull strength.",
		prerequisites = ["hull_crystalline_2"],
		cost = {64: 200, 70: 180, 71: 150},  # Neutronium, Dark Energy, Singularity
		category = "hull",
		tier = 7,
		effects = {stat_hull_multiplier = 4.0},
		unlock_type = "upgrade",
		position = Vector2(1150, 100)
	},
	{
		id = "hull_exotic_matter",
		name = "Exotic Matter Hull",
		description = "Exotic matter construction. +400% hull strength, +10% damage resistance.",
		prerequisites = ["hull_neutronium"],
		cost = {82: 250, 92: 200, 93: 180},  # Chrono Crystal, Exotic Matter, Omnium
		category = "hull",
		tier = 8,
		effects = {stat_hull_multiplier = 5.0, stat_damage_resistance = 0.10},
		unlock_type = "upgrade",
		position = Vector2(1300, 100)
	},
	{
		id = "hull_dimensional",
		name = "Dimensional Armor",
		description = "Phase-shifted dimensional plating. +500% hull, +20% resistance.",
		prerequisites = ["hull_exotic_matter"],
		cost = {83: 300, 94: 250, 97: 200},  # Dimensional Shard, Unobtainium, Infinitum
		category = "hull",
		tier = 9,
		effects = {stat_hull_multiplier = 6.0, stat_damage_resistance = 0.20},
		unlock_type = "upgrade",
		position = Vector2(1450, 100)
	},
	
	# Additional hull variants for branching
	{
		id = "hull_regenerative",
		name = "Regenerative Hull",
		description = "Self-repairing hull plating. +50% hull, +2 HP/sec regeneration.",
		prerequisites = ["hull_composite_1"],
		cost = {24: 100, 31: 80, 50: 60},  # Tungsten, Titanium, Erbium
		category = "hull",
		tier = 3,
		effects = {stat_hull_multiplier = 1.50, stat_hull_regen = 2.0},
		unlock_type = "upgrade",
		position = Vector2(400, 250)
	},
	{
		id = "hull_reactive",
		name = "Reactive Armor",
		description = "Explosive reactive armor. +40% hull, reflects 15% damage to attacker.",
		prerequisites = ["hull_composite_2"],
		cost = {35: 120, 44: 100, 55: 80},  # Tantalum, Dysprosium, Samarium
		category = "hull",
		tier = 4,
		effects = {stat_hull_multiplier = 1.40, stat_damage_reflection = 0.15},
		unlock_type = "upgrade",
		position = Vector2(550, 250)
	},
	{
		id = "hull_adaptive",
		name = "Adaptive Armor",
		description = "Self-adapting smart armor. +80% hull, adapts to damage types.",
		prerequisites = ["hull_reactive"],
		cost = {60: 150, 61: 120, 80: 100},  # Exotic Alloy, Crystalline Matrix, Chrono Crystal
		category = "hull",
		tier = 6,
		effects = {stat_hull_multiplier = 1.80, stat_adaptive_armor = true},
		unlock_type = "upgrade",
		position = Vector2(850, 250)
	},
	{
		id = "hull_living",
		name = "Living Hull",
		description = "Bio-engineered living armor. +120% hull, +5 HP/sec regen, adaptive.",
		prerequisites = ["hull_regenerative", "hull_adaptive"],
		cost = {85: 200, 92: 180, 98: 150},  # Void Essence, Exotic Matter, Negentropy
		category = "hull",
		tier = 8,
		effects = {stat_hull_multiplier = 2.20, stat_hull_regen = 5.0, stat_adaptive_armor = true},
		unlock_type = "upgrade",
		position = Vector2(1000, 400)
	},
	{
		id = "hull_ultimate",
		name = "Transcendent Armor",
		description = "Ultimate armor technology. +600% hull, +25% resistance, +10 HP/sec regen.",
		prerequisites = ["hull_dimensional", "hull_living"],
		cost = {94: 350, 95: 300, 97: 280, 99: 250},  # Unobtainium, Impossibilium, Infinitum, Cosmicite
		category = "hull",
		tier = 9,
		effects = {stat_hull_multiplier = 7.0, stat_damage_resistance = 0.25, stat_hull_regen = 10.0},
		unlock_type = "upgrade",
		position = Vector2(1600, 250)
	},
	
	# ============================================================================
	# SHIELD RESEARCH BRANCH (15 nodes)
	# ============================================================================
	{
		id = "shield_basic",
		name = "Basic Deflector",
		description = "Basic energy shield generator. Adds 50 shield points to all units.",
		prerequisites = [],
		cost = {2: 60, 10: 40, 11: 30},  # Silicon, Copper, Zinc
		category = "shield",
		tier = 0,
		effects = {stat_shield_max = 50},
		unlock_type = "upgrade",
		position = Vector2(100, 600)
	},
	{
		id = "shield_improved",
		name = "Improved Deflector",
		description = "Enhanced shield generator. +100 shield points.",
		prerequisites = ["shield_basic"],
		cost = {12: 80, 13: 60, 20: 50},  # Lead, Tin, Silver
		category = "shield",
		tier = 1,
		effects = {stat_shield_max = 100},
		unlock_type = "upgrade",
		position = Vector2(250, 600)
	},
	{
		id = "shield_energy_barrier",
		name = "Energy Barrier I",
		description = "Advanced energy field. +200 shields, 5% damage absorption.",
		prerequisites = ["shield_improved"],
		cost = {21: 100, 22: 80, 23: 60},  # Lithium, Beryllium, Boron
		category = "shield",
		tier = 2,
		effects = {stat_shield_max = 200, stat_shield_absorption = 0.05},
		unlock_type = "upgrade",
		position = Vector2(400, 600)
	},
	{
		id = "shield_energy_barrier_2",
		name = "Energy Barrier II",
		description = "Reinforced energy field. +350 shields, 10% absorption.",
		prerequisites = ["shield_energy_barrier"],
		cost = {30: 120, 31: 100, 32: 80},  # Gold, Titanium, Gallium
		category = "shield",
		tier = 3,
		effects = {stat_shield_max = 350, stat_shield_absorption = 0.10},
		unlock_type = "upgrade",
		position = Vector2(550, 600)
	},
	{
		id = "shield_phase",
		name = "Phase Shield",
		description = "Phase-shifted protection. +500 shields, 15% absorption, phase chance.",
		prerequisites = ["shield_energy_barrier_2"],
		cost = {40: 150, 41: 120, 42: 100},  # Platinum, Palladium, Rhodium
		category = "shield",
		tier = 4,
		effects = {stat_shield_max = 500, stat_shield_absorption = 0.15, stat_phase_chance = 0.10},
		unlock_type = "upgrade",
		position = Vector2(700, 600)
	},
	{
		id = "shield_regenerative",
		name = "Regenerative Shield",
		description = "Self-repairing shields. +400 shields, +10 shield/sec regen.",
		prerequisites = ["shield_energy_barrier"],
		cost = {33: 130, 43: 100, 53: 80},  # Germanium, Iridium, Cerium
		category = "shield",
		tier = 3,
		effects = {stat_shield_max = 400, stat_shield_regen = 10.0},
		unlock_type = "upgrade",
		position = Vector2(400, 750)
	},
	{
		id = "shield_adaptive",
		name = "Adaptive Shield",
		description = "Smart shield matrix. +600 shields, adapts to damage types.",
		prerequisites = ["shield_phase", "shield_regenerative"],
		cost = {60: 180, 61: 150, 62: 120},  # Exotic Alloy, Crystalline Matrix, Quantum Crystal
		category = "shield",
		tier = 5,
		effects = {stat_shield_max = 600, stat_adaptive_shield = true, stat_shield_regen = 15.0},
		unlock_type = "upgrade",
		position = Vector2(850, 675)
	},
	{
		id = "shield_quantum_1",
		name = "Quantum Shield I",
		description = "Quantum-entangled barrier. +800 shields, 20% absorption.",
		prerequisites = ["shield_adaptive"],
		cost = {62: 200, 63: 180, 64: 150},  # Quantum Crystal, Graviton, Neutronium
		category = "shield",
		tier = 6,
		effects = {stat_shield_max = 800, stat_shield_absorption = 0.20, stat_shield_regen = 20.0},
		unlock_type = "upgrade",
		position = Vector2(1000, 600)
	},
	{
		id = "shield_quantum_2",
		name = "Quantum Shield II",
		description = "Enhanced quantum field. +1200 shields, 30% absorption.",
		prerequisites = ["shield_quantum_1"],
		cost = {70: 250, 71: 220, 72: 200},  # Dark Energy, Singularity, Spacetime Fabric
		category = "shield",
		tier = 7,
		effects = {stat_shield_max = 1200, stat_shield_absorption = 0.30, stat_shield_regen = 30.0},
		unlock_type = "upgrade",
		position = Vector2(1150, 600)
	},
	{
		id = "shield_reality_barrier",
		name = "Reality Barrier",
		description = "Warps local reality. +1500 shields, 40% absorption, 20% phase.",
		prerequisites = ["shield_quantum_2"],
		cost = {83: 300, 85: 280, 86: 250},  # Dimensional Shard, Void Essence, Reality Anchor
		category = "shield",
		tier = 8,
		effects = {stat_shield_max = 1500, stat_shield_absorption = 0.40, stat_phase_chance = 0.20, stat_shield_regen = 40.0},
		unlock_type = "upgrade",
		position = Vector2(1300, 600)
	},
	{
		id = "shield_temporal",
		name = "Temporal Shield",
		description = "Time-dilated protection. +1000 shields, rewinds damage over time.",
		prerequisites = ["shield_quantum_1"],
		cost = {82: 280, 87: 250, 88: 220},  # Chrono Crystal, Temporal Paradox, Quantum Foam
		category = "shield",
		tier = 7,
		effects = {stat_shield_max = 1000, stat_temporal_rewind = true, stat_shield_regen = 35.0},
		unlock_type = "upgrade",
		position = Vector2(1000, 750)
	},
	{
		id = "shield_singularity",
		name = "Singularity Shield",
		description = "Micro black hole defense. +1800 shields, absorbs projectiles.",
		prerequisites = ["shield_reality_barrier", "shield_temporal"],
		cost = {71: 320, 84: 300, 90: 280},  # Singularity Fragment, Void Essence, Planck Particle
		category = "shield",
		tier = 8,
		effects = {stat_shield_max = 1800, stat_projectile_absorption = 0.25, stat_shield_regen = 50.0},
		unlock_type = "upgrade",
		position = Vector2(1300, 800)
	},
	{
		id = "shield_absolute",
		name = "Absolute Barrier",
		description = "Perfect defense field. +2500 shields, 50% absorption, full adaptation.",
		prerequisites = ["shield_reality_barrier", "shield_singularity"],
		cost = {94: 400, 95: 380, 97: 350, 99: 320},  # Unobtainium, Impossibilium, Infinitum, Cosmicite
		category = "shield",
		tier = 9,
		effects = {stat_shield_max = 2500, stat_shield_absorption = 0.50, stat_adaptive_shield = true, stat_shield_regen = 60.0},
		unlock_type = "upgrade",
		position = Vector2(1600, 700)
	},
	{
		id = "shield_overcharge",
		name = "Shield Overcharge System",
		description = "Emergency shield boost. Unlocks shield overcharge ability (+200% for 10s).",
		prerequisites = ["shield_adaptive"],
		cost = {65: 150, 74: 130, 75: 110},  # Plasma Core, Warp Particle, Tachyon Crystal
		category = "shield",
		tier = 5,
		effects = {ability_shield_overcharge = true},
		unlock_type = "ability",
		position = Vector2(850, 850)
	},
	{
		id = "shield_bubble",
		name = "Shield Bubble Projector",
		description = "Area shield generator. Projects protective bubble around nearby allies.",
		prerequisites = ["shield_quantum_1"],
		cost = {73: 200, 76: 180, 77: 160},  # Zero-Point Energy, Neutrino, Muon Cluster
		category = "shield",
		tier = 6,
		effects = {ability_shield_bubble = true},
		unlock_type = "ability",
		position = Vector2(1000, 850)
	},
	
	# ============================================================================
	# WEAPONS RESEARCH BRANCH (30 nodes)
	# ============================================================================
	
	# Kinetic Weapons (5 nodes)
	{
		id = "weapon_kinetic_basic",
		name = "Mass Driver I",
		description = "Basic kinetic accelerator. +20% projectile damage.",
		prerequisites = [],
		cost = {0: 40, 10: 30, 14: 20},  # Iron, Copper, Nickel
		category = "weapon",
		tier = 0,
		effects = {stat_kinetic_damage = 1.20},
		unlock_type = "upgrade",
		position = Vector2(100, 1100)
	},
	{
		id = "weapon_kinetic_advanced",
		name = "Mass Driver II",
		description = "Advanced mass accelerator. +50% projectile damage.",
		prerequisites = ["weapon_kinetic_basic"],
		cost = {24: 80, 25: 60, 34: 50},  # Tungsten, Molybdenum, Hafnium
		category = "weapon",
		tier = 2,
		effects = {stat_kinetic_damage = 1.50},
		unlock_type = "upgrade",
		position = Vector2(250, 1100)
	},
	{
		id = "weapon_railgun",
		name = "Electromagnetic Railgun",
		description = "EM railgun system. +100% kinetic damage, armor piercing.",
		prerequisites = ["weapon_kinetic_advanced"],
		cost = {41: 120, 46: 100, 56: 80},  # Palladium, Gadolinium, Lanthanum
		category = "weapon",
		tier = 4,
		effects = {stat_kinetic_damage = 2.0, stat_armor_piercing = 0.30},
		unlock_type = "upgrade",
		position = Vector2(400, 1100)
	},
	{
		id = "weapon_gauss",
		name = "Gauss Cannon",
		description = "Magnetic acceleration cannon. +150% kinetic damage, high penetration.",
		prerequisites = ["weapon_railgun"],
		cost = {62: 180, 64: 150, 66: 130},  # Quantum Crystal, Neutronium, Fusion Catalyst
		category = "weapon",
		tier = 6,
		effects = {stat_kinetic_damage = 2.50, stat_armor_piercing = 0.50},
		unlock_type = "upgrade",
		position = Vector2(550, 1100)
	},
	{
		id = "weapon_kinetic_ultimate",
		name = "Singularity Driver",
		description = "Compressed singularity projectiles. +300% kinetic damage, total penetration.",
		prerequisites = ["weapon_gauss"],
		cost = {71: 250, 84: 220, 90: 200},  # Singularity, Void Essence, Planck Particle
		category = "weapon",
		tier = 8,
		effects = {stat_kinetic_damage = 4.0, stat_armor_piercing = 1.0},
		unlock_type = "upgrade",
		position = Vector2(700, 1100)
	},
	
	# Energy Weapons (5 nodes)
	{
		id = "weapon_laser_basic",
		name = "Pulse Laser I",
		description = "Basic laser weapon. +20% energy damage.",
		prerequisites = [],
		cost = {2: 40, 21: 30, 22: 20},  # Silicon, Lithium, Beryllium
		category = "weapon",
		tier = 0,
		effects = {stat_energy_damage = 1.20},
		unlock_type = "upgrade",
		position = Vector2(100, 1250)
	},
	{
		id = "weapon_laser_advanced",
		name = "Pulse Laser II",
		description = "High-powered laser. +50% energy damage.",
		prerequisites = ["weapon_laser_basic"],
		cost = {31: 80, 32: 60, 33: 50},  # Titanium, Gallium, Germanium
		category = "weapon",
		tier = 2,
		effects = {stat_energy_damage = 1.50},
		unlock_type = "upgrade",
		position = Vector2(250, 1250)
	},
	{
		id = "weapon_plasma",
		name = "Plasma Projector",
		description = "Superheated plasma weapon. +100% energy damage, burn effect.",
		prerequisites = ["weapon_laser_advanced"],
		cost = {65: 120, 66: 100, 67: 80},  # Plasma Core, Fusion Catalyst, Antimatter Trace
		category = "weapon",
		tier = 5,
		effects = {stat_energy_damage = 2.0, stat_burn_damage = 5.0},
		unlock_type = "upgrade",
		position = Vector2(400, 1250)
	},
	{
		id = "weapon_particle_beam",
		name = "Particle Beam Cannon",
		description = "Focused particle beam. +180% energy damage, shield penetration.",
		prerequisites = ["weapon_plasma"],
		cost = {68: 180, 69: 150, 78: 130},  # Higgs Boson, Quark Matter, Photonic Lattice
		category = "weapon",
		tier = 6,
		effects = {stat_energy_damage = 2.80, stat_shield_penetration = 0.40},
		unlock_type = "upgrade",
		position = Vector2(550, 1250)
	},
	{
		id = "weapon_energy_ultimate",
		name = "Reality Disruptor",
		description = "Tears reality itself. +400% energy damage, ignores all defenses.",
		prerequisites = ["weapon_particle_beam"],
		cost = {83: 280, 85: 250, 86: 230},  # Dimensional Shard, Void Essence, Reality Anchor
		category = "weapon",
		tier = 8,
		effects = {stat_energy_damage = 5.0, stat_ignore_defenses = true},
		unlock_type = "upgrade",
		position = Vector2(700, 1250)
	},
	
	# Missile Weapons (5 nodes)
	{
		id = "weapon_missile_basic",
		name = "Missile Launcher I",
		description = "Basic guided missiles. +25% explosive damage.",
		prerequisites = [],
		cost = {1: 50, 7: 40, 15: 30},  # Carbon, Sulfur, Cobalt
		category = "weapon",
		tier = 0,
		effects = {stat_explosive_damage = 1.25},
		unlock_type = "upgrade",
		position = Vector2(100, 1400)
	},
	{
		id = "weapon_missile_advanced",
		name = "Missile Launcher II",
		description = "Advanced targeting missiles. +60% explosive damage.",
		prerequisites = ["weapon_missile_basic"],
		cost = {16: 90, 17: 70, 18: 60},  # Manganese, Chromium, Vanadium
		category = "weapon",
		tier = 2,
		effects = {stat_explosive_damage = 1.60},
		unlock_type = "upgrade",
		position = Vector2(250, 1400)
	},
	{
		id = "weapon_torpedo",
		name = "Plasma Torpedo",
		description = "Heavy plasma warheads. +120% explosive, area damage.",
		prerequisites = ["weapon_missile_advanced"],
		cost = {44: 130, 54: 110, 65: 90},  # Dysprosium, Promethium, Plasma Core
		category = "weapon",
		tier = 4,
		effects = {stat_explosive_damage = 2.20, stat_aoe_radius = 1.5},
		unlock_type = "upgrade",
		position = Vector2(400, 1400)
	},
	{
		id = "weapon_antimatter_missile",
		name = "Antimatter Warhead",
		description = "Matter-antimatter annihilation. +200% explosive, massive area.",
		prerequisites = ["weapon_torpedo"],
		cost = {67: 200, 68: 180, 69: 160},  # Antimatter Trace, Higgs Boson, Quark Matter
		category = "weapon",
		tier = 6,
		effects = {stat_explosive_damage = 3.0, stat_aoe_radius = 2.5},
		unlock_type = "upgrade",
		position = Vector2(550, 1400)
	},
	{
		id = "weapon_missile_ultimate",
		name = "Entropy Missile",
		description = "Accelerates heat death. +500% explosive, erases target from reality.",
		prerequisites = ["weapon_antimatter_missile"],
		cost = {91: 300, 98: 280, 99: 260},  # Entropy Reversal, Negentropy, Cosmicite
		category = "weapon",
		tier = 9,
		effects = {stat_explosive_damage = 6.0, stat_reality_erasure = true},
		unlock_type = "upgrade",
		position = Vector2(700, 1400)
	},
	
	# Specialized Weapons (5 nodes)
	{
		id = "weapon_emp",
		name = "EMP Disruptor",
		description = "Electromagnetic pulse. Disables shields temporarily.",
		prerequisites = ["weapon_laser_basic"],
		cost = {21: 70, 44: 60, 45: 50},  # Lithium, Dysprosium, Holmium
		category = "weapon",
		tier = 2,
		effects = {ability_emp = true},
		unlock_type = "ability",
		position = Vector2(100, 1550)
	},
	{
		id = "weapon_tractor_beam",
		name = "Tractor Beam",
		description = "Graviton beam projector. Pull/push enemies.",
		prerequisites = ["weapon_laser_advanced"],
		cost = {63: 100, 72: 90, 74: 80},  # Graviton, Spacetime Fabric, Warp Particle
		category = "weapon",
		tier = 4,
		effects = {ability_tractor_beam = true},
		unlock_type = "ability",
		position = Vector2(250, 1550)
	},
	{
		id = "weapon_time_dilation",
		name = "Temporal Disruptor",
		description = "Slow time around target. -50% enemy speed.",
		prerequisites = ["weapon_tractor_beam"],
		cost = {82: 150, 87: 130, 88: 120},  # Chrono Crystal, Temporal Paradox, Quantum Foam
		category = "weapon",
		tier = 7,
		effects = {ability_time_slow = true},
		unlock_type = "ability",
		position = Vector2(400, 1550)
	},
	{
		id = "weapon_nanite_swarm",
		name = "Nanite Disassembler",
		description = "Self-replicating nanites. Damage over time, spreads to nearby enemies.",
		prerequisites = ["weapon_kinetic_advanced"],
		cost = {60: 130, 61: 110, 92: 100},  # Exotic Alloy, Crystalline Matrix, Exotic Matter
		category = "weapon",
		tier = 5,
		effects = {ability_nanite_swarm = true},
		unlock_type = "ability",
		position = Vector2(250, 1700)
	},
	{
		id = "weapon_reality_anchor",
		name = "Reality Anchor Projector",
		description = "Anchors target to this reality. Prevents warp/teleport, +100% damage to target.",
		prerequisites = ["weapon_time_dilation"],
		cost = {86: 200, 93: 180, 94: 160},  # Reality Anchor, Omnium, Unobtainium
		category = "weapon",
		tier = 8,
		effects = {ability_reality_anchor = true},
		unlock_type = "ability",
		position = Vector2(550, 1550)
	},
	
	# Multi-weapon Systems (10 nodes)
	{
		id = "weapon_dual_cannons",
		name = "Dual Weapon System",
		description = "Mount 2 weapons simultaneously. +30% fire rate.",
		prerequisites = ["weapon_kinetic_basic", "weapon_laser_basic"],
		cost = {10: 100, 11: 80, 12: 70},  # Copper, Zinc, Lead
		category = "weapon",
		tier = 1,
		effects = {stat_weapon_slots = 2, stat_fire_rate = 1.30},
		unlock_type = "upgrade",
		position = Vector2(200, 1850)
	},
	{
		id = "weapon_triple_cannons",
		name = "Triple Weapon System",
		description = "Mount 3 weapons. +50% fire rate.",
		prerequisites = ["weapon_dual_cannons"],
		cost = {30: 150, 40: 130, 50: 110},  # Gold, Platinum, Lutetium
		category = "weapon",
		tier = 4,
		effects = {stat_weapon_slots = 3, stat_fire_rate = 1.50},
		unlock_type = "upgrade",
		position = Vector2(350, 1850)
	},
	{
		id = "weapon_quad_cannons",
		name = "Quad Weapon System",
		description = "Mount 4 weapons. +80% fire rate.",
		prerequisites = ["weapon_triple_cannons"],
		cost = {60: 200, 70: 180, 80: 160},  # Exotic Alloy, Dark Energy, Chrono Crystal
		category = "weapon",
		tier = 6,
		effects = {stat_weapon_slots = 4, stat_fire_rate = 1.80},
		unlock_type = "upgrade",
		position = Vector2(500, 1850)
	},
	{
		id = "weapon_targeting_basic",
		name = "Targeting Computer I",
		description = "Basic targeting AI. +15% accuracy.",
		prerequisites = ["weapon_kinetic_basic"],
		cost = {2: 60, 21: 50, 32: 40},  # Silicon, Lithium, Gallium
		category = "weapon",
		tier = 1,
		effects = {stat_accuracy = 1.15},
		unlock_type = "upgrade",
		position = Vector2(100, 2000)
	},
	{
		id = "weapon_targeting_advanced",
		name = "Targeting Computer II",
		description = "Advanced AI targeting. +35% accuracy, +10% crit chance.",
		prerequisites = ["weapon_targeting_basic"],
		cost = {33: 100, 43: 80, 53: 70},  # Germanium, Iridium, Cerium
		category = "weapon",
		tier = 3,
		effects = {stat_accuracy = 1.35, stat_crit_chance = 0.10},
		unlock_type = "upgrade",
		position = Vector2(250, 2000)
	},
	{
		id = "weapon_targeting_quantum",
		name = "Quantum Targeting",
		description = "Quantum prediction. +60% accuracy, +25% crit, predict enemy movement.",
		prerequisites = ["weapon_targeting_advanced"],
		cost = {62: 150, 68: 130, 88: 120},  # Quantum Crystal, Higgs Boson, Quantum Foam
		category = "weapon",
		tier = 6,
		effects = {stat_accuracy = 1.60, stat_crit_chance = 0.25, stat_predictive_targeting = true},
		unlock_type = "upgrade",
		position = Vector2(400, 2000)
	},
	{
		id = "weapon_range_extender",
		name = "Range Extender",
		description = "Weapon range amplification. +40% weapon range.",
		prerequisites = ["weapon_laser_advanced"],
		cost = {31: 90, 34: 80, 35: 70},  # Titanium, Hafnium, Tantalum
		category = "weapon",
		tier = 2,
		effects = {stat_weapon_range = 1.40},
		unlock_type = "upgrade",
		position = Vector2(250, 2150)
	},
	{
		id = "weapon_cooldown_reduction",
		name = "Rapid Fire Actuators",
		description = "Faster weapon cycling. +30% fire rate.",
		prerequisites = ["weapon_kinetic_advanced"],
		cost = {15: 100, 16: 80, 17: 70},  # Cobalt, Manganese, Chromium
		category = "weapon",
		tier = 2,
		effects = {stat_fire_rate = 1.30},
		unlock_type = "upgrade",
		position = Vector2(250, 2300)
	},
	{
		id = "weapon_ammo_efficiency",
		name = "Ammo Fabrication",
		description = "Onboard ammo creation. Unlimited ammo, +20% damage.",
		prerequisites = ["weapon_cooldown_reduction"],
		cost = {60: 140, 61: 120, 66: 100},  # Exotic Alloy, Crystalline Matrix, Fusion Catalyst
		category = "weapon",
		tier = 5,
		effects = {stat_unlimited_ammo = true, stat_all_weapon_damage = 1.20},
		unlock_type = "upgrade",
		position = Vector2(400, 2300)
	},
	{
		id = "weapon_overcharge",
		name = "Weapon Overcharge",
		description = "Emergency firepower boost. Ability: +300% damage for 15 seconds.",
		prerequisites = ["weapon_ammo_efficiency"],
		cost = {70: 200, 76: 180, 82: 160},  # Dark Energy, Zero-Point Energy, Chrono Crystal
		category = "weapon",
		tier = 6,
		effects = {ability_weapon_overcharge = true},
		unlock_type = "ability",
		position = Vector2(550, 2300)
	},
	
	# ============================================================================
	# ABILITY RESEARCH BRANCH (20 nodes)
	# ============================================================================
	{
		id = "ability_scan_basic",
		name = "Long-Range Sensors",
		description = "Extended sensor range. +50% vision range for all units.",
		prerequisites = [],
		cost = {2: 60, 32: 50, 33: 40},  # Silicon, Gallium, Germanium
		category = "ability",
		tier = 0,
		effects = {stat_vision_range = 1.50},
		unlock_type = "upgrade",
		position = Vector2(2000, 100)
	},
	{
		id = "ability_scan_advanced",
		name = "Advanced Sensors",
		description = "High-resolution sensors. +100% vision, detect cloaked units.",
		prerequisites = ["ability_scan_basic"],
		cost = {43: 100, 46: 80, 62: 70},  # Iridium, Gadolinium, Quantum Crystal
		category = "ability",
		tier = 3,
		effects = {stat_vision_range = 2.0, stat_detect_stealth = true},
		unlock_type = "upgrade",
		position = Vector2(2150, 100)
	},
	{
		id = "ability_satellite_deploy",
		name = "Reconnaissance Satellite",
		description = "Deploy permanent satellites. Reveals 500-unit radius in any zone continuously.",
		prerequisites = ["ability_scan_advanced"],
		cost = {50: 150, 62: 130, 72: 120},  # Lutetium, Quantum Crystal, Spacetime Fabric
		category = "ability",
		tier = 5,
		effects = {ability_deploy_satellite = true},
		unlock_type = "ability",
		position = Vector2(2300, 100)
	},
	{
		id = "ability_satellite_combat",
		name = "Combat Satellite",
		description = "Armed satellites. Satellites have weapons and can attack enemies.",
		prerequisites = ["ability_satellite_deploy"],
		cost = {65: 200, 74: 180, 82: 160},  # Plasma Core, Warp Particle, Chrono Crystal
		category = "ability",
		tier = 6,
		effects = {ability_combat_satellite = true},
		unlock_type = "ability",
		position = Vector2(2450, 100)
	},
	{
		id = "ability_stealth_basic",
		name = "Stealth Generator I",
		description = "Basic cloaking device. Selected units can activate stealth (60% detection reduction).",
		prerequisites = ["ability_scan_basic"],
		cost = {40: 120, 62: 100, 72: 90},  # Platinum, Quantum Crystal, Spacetime Fabric
		category = "ability",
		tier = 4,
		effects = {ability_stealth = true, stat_stealth_level = 0.60},
		unlock_type = "ability",
		position = Vector2(2000, 250)
	},
	{
		id = "ability_stealth_advanced",
		name = "Stealth Generator II",
		description = "Advanced cloaking. 90% detection reduction, move while cloaked.",
		prerequisites = ["ability_stealth_basic"],
		cost = {70: 180, 83: 160, 85: 150},  # Dark Energy, Dimensional Shard, Void Essence
		category = "ability",
		tier = 7,
		effects = {ability_stealth = true, stat_stealth_level = 0.90, stat_stealth_move = true},
		unlock_type = "ability",
		position = Vector2(2150, 250)
	},
	{
		id = "ability_warp_basic",
		name = "Emergency Warp",
		description = "Short-range teleport. Escape combat by warping 1000 units away.",
		prerequisites = ["ability_scan_basic"],
		cost = {72: 150, 74: 130, 75: 120},  # Spacetime Fabric, Warp Particle, Tachyon Crystal
		category = "ability",
		tier = 5,
		effects = {ability_emergency_warp = true, stat_warp_range = 1000},
		unlock_type = "ability",
		position = Vector2(2000, 400)
	},
	{
		id = "ability_warp_advanced",
		name = "Tactical Warp",
		description = "Combat teleportation. Warp up to 2000 units, no cooldown in combat.",
		prerequisites = ["ability_warp_basic"],
		cost = {83: 200, 86: 180, 89: 170},  # Dimensional Shard, Reality Anchor, Planck Particle
		category = "ability",
		tier = 8,
		effects = {ability_tactical_warp = true, stat_warp_range = 2000, stat_combat_warp = true},
		unlock_type = "ability",
		position = Vector2(2150, 400)
	},
	{
		id = "ability_warp_gate",
		name = "Warp Gate Network",
		description = "Create wormholes. Link any two zones with permanent warp gates.",
		prerequisites = ["ability_warp_advanced"],
		cost = {92: 300, 93: 280, 97: 260},  # Exotic Matter, Omnium, Infinitum
		category = "ability",
		tier = 9,
		effects = {ability_create_wormhole = true},
		unlock_type = "ability",
		position = Vector2(2300, 400)
	},
	{
		id = "ability_repair_drone",
		name = "Repair Drone Bay",
		description = "Deploy repair drones. Auto-repair nearby friendly units.",
		prerequisites = [],
		cost = {0: 80, 10: 60, 20: 50},  # Iron, Copper, Silver
		category = "ability",
		tier = 1,
		effects = {ability_repair_drone = true},
		unlock_type = "ability",
		position = Vector2(2000, 550)
	},
	{
		id = "ability_nanite_repair",
		name = "Nanite Repair System",
		description = "Self-repairing nanites. All units regenerate hull at +3 HP/sec.",
		prerequisites = ["ability_repair_drone"],
		cost = {60: 150, 61: 130, 66: 120},  # Exotic Alloy, Crystalline Matrix, Fusion Catalyst
		category = "ability",
		tier = 5,
		effects = {stat_hull_regen = 3.0},
		unlock_type = "upgrade",
		position = Vector2(2150, 550)
	},
	{
		id = "ability_energy_vampire",
		name = "Energy Drain",
		description = "Steal enemy shields. Drain 20% of damage dealt from enemy shields to yours.",
		prerequisites = ["ability_nanite_repair"],
		cost = {70: 180, 76: 160, 85: 150},  # Dark Energy, Zero-Point Energy, Void Essence
		category = "ability",
		tier = 7,
		effects = {ability_energy_drain = true, stat_drain_percentage = 0.20},
		unlock_type = "ability",
		position = Vector2(2300, 550)
	},
	{
		id = "ability_resource_scanner",
		name = "Resource Scanner",
		description = "Detect resources. Reveals all resource nodes in current zone on minimap.",
		prerequisites = [],
		cost = {2: 50, 21: 40, 32: 30},  # Silicon, Lithium, Gallium
		category = "ability",
		tier = 1,
		effects = {ability_resource_scanner = true},
		unlock_type = "ability",
		position = Vector2(2000, 700)
	},
	{
		id = "ability_resource_magnet",
		name = "Resource Magnet",
		description = "Attract resources. Automatically collect nearby resources without mining.",
		prerequisites = ["ability_resource_scanner"],
		cost = {63: 130, 72: 110, 74: 100},  # Graviton, Spacetime Fabric, Warp Particle
		category = "ability",
		tier = 5,
		effects = {ability_resource_magnet = true},
		unlock_type = "ability",
		position = Vector2(2150, 700)
	},
	{
		id = "ability_force_field",
		name = "Defensive Force Field",
		description = "Temporary invulnerability. Activate to become immune for 5 seconds.",
		prerequisites = ["ability_scan_advanced"],
		cost = {70: 200, 76: 180, 86: 170},  # Dark Energy, Zero-Point Energy, Reality Anchor
		category = "ability",
		tier = 7,
		effects = {ability_force_field = true},
		unlock_type = "ability",
		position = Vector2(2300, 250)
	},
	{
		id = "ability_command_aura",
		name = "Command Aura",
		description = "Leadership bonus. Nearby allies gain +30% damage and +20% speed.",
		prerequisites = [],
		cost = {30: 100, 50: 80, 60: 70},  # Gold, Lutetium, Exotic Alloy
		category = "ability",
		tier = 3,
		effects = {ability_command_aura = true},
		unlock_type = "ability",
		position = Vector2(2000, 850)
	},
	{
		id = "ability_rally_point",
		name = "Rally Point",
		description = "Strategic coordination. Set rally points that buff units in area.",
		prerequisites = ["ability_command_aura"],
		cost = {62: 140, 70: 120, 82: 110},  # Quantum Crystal, Dark Energy, Chrono Crystal
		category = "ability",
		tier = 6,
		effects = {ability_rally_point = true},
		unlock_type = "ability",
		position = Vector2(2150, 850)
	},
	{
		id = "ability_time_stop",
		name = "Temporal Stasis",
		description = "Freeze time. All enemies in 1000-unit radius stop for 10 seconds.",
		prerequisites = ["ability_warp_advanced"],
		cost = {82: 350, 87: 320, 97: 300},  # Chrono Crystal, Temporal Paradox, Infinitum
		category = "ability",
		tier = 9,
		effects = {ability_time_stop = true},
		unlock_type = "ability",
		position = Vector2(2300, 550)
	},
	{
		id = "ability_resurrection",
		name = "Resurrection Protocol",
		description = "Revive destroyed units. Brings destroyed units back with 50% health (1 per 60s).",
		prerequisites = ["ability_nanite_repair"],
		cost = {86: 280, 91: 260, 98: 250},  # Reality Anchor, Entropy Reversal, Negentropy
		category = "ability",
		tier = 8,
		effects = {ability_resurrection = true},
		unlock_type = "ability",
		position = Vector2(2300, 700)
	},
	{
		id = "ability_mass_production",
		name = "Mass Production",
		description = "Rapid manufacturing. -50% unit build time, -30% build cost.",
		prerequisites = [],
		cost = {0: 120, 10: 100, 30: 80},  # Iron, Copper, Gold
		category = "ability",
		tier = 2,
		effects = {stat_build_time_reduction = 0.50, stat_build_cost_reduction = 0.30},
		unlock_type = "upgrade",
		position = Vector2(2000, 1000)
	},
	
	# ============================================================================
	# BUILDING RESEARCH BRANCH (15 nodes)
	# ============================================================================
	{
		id = "building_turret_basic",
		name = "Basic Turret Construction",
		description = "Unlock construction of Bullet Turrets.",
		prerequisites = [],
		cost = {0: 100, 10: 80, 11: 60},  # Iron, Copper, Zinc
		category = "building",
		tier = 0,
		effects = {unlock_building = "BulletTurret"},
		unlock_type = "building",
		position = Vector2(2700, 100)
	},
	{
		id = "building_turret_laser",
		name = "Laser Turret Construction",
		description = "Unlock construction of Laser Turrets.",
		prerequisites = ["building_turret_basic"],
		cost = {2: 150, 21: 120, 31: 100},  # Silicon, Lithium, Titanium
		category = "building",
		tier = 2,
		effects = {unlock_building = "LaserTurret"},
		unlock_type = "building",
		position = Vector2(2850, 100)
	},
	{
		id = "building_turret_missile",
		name = "Missile Turret Construction",
		description = "Unlock construction of Missile Turrets.",
		prerequisites = ["building_turret_basic"],
		cost = {1: 150, 7: 120, 15: 100},  # Carbon, Sulfur, Cobalt
		category = "building",
		tier = 2,
		effects = {unlock_building = "MissileTurret"},
		unlock_type = "building",
		position = Vector2(2850, 250)
	},
	{
		id = "building_turret_plasma",
		name = "Plasma Turret Construction",
		description = "Unlock construction of Plasma Turrets. High damage, splash.",
		prerequisites = ["building_turret_laser"],
		cost = {65: 200, 66: 180, 67: 160},  # Plasma Core, Fusion Catalyst, Antimatter
		category = "building",
		tier = 5,
		effects = {unlock_building = "PlasmaTurret"},
		unlock_type = "building",
		position = Vector2(3000, 100)
	},
	{
		id = "building_factory",
		name = "Drone Factory",
		description = "Unlock construction of Drone Factories. Produces units automatically.",
		prerequisites = ["building_turret_basic"],
		cost = {0: 200, 10: 150, 30: 120},  # Iron, Copper, Gold
		category = "building",
		tier = 3,
		effects = {unlock_building = "DroneFactory"},
		unlock_type = "building",
		position = Vector2(2700, 400)
	},
	{
		id = "building_refinery",
		name = "Resource Refinery",
		description = "Unlock construction of Refineries. Convert resources to higher tiers.",
		prerequisites = [],
		cost = {0: 150, 2: 120, 10: 100},  # Iron, Silicon, Copper
		category = "building",
		tier = 2,
		effects = {unlock_building = "Refinery"},
		unlock_type = "building",
		position = Vector2(2700, 550)
	},
	{
		id = "building_refinery_advanced",
		name = "Advanced Refinery",
		description = "Unlock Advanced Refineries. 2x refining speed, better conversion rates.",
		prerequisites = ["building_refinery"],
		cost = {30: 200, 40: 180, 60: 160},  # Gold, Platinum, Exotic Alloy
		category = "building",
		tier = 5,
		effects = {unlock_building = "AdvancedRefinery"},
		unlock_type = "building",
		position = Vector2(2850, 550)
	},
	{
		id = "building_shield_generator",
		name = "Shield Generator",
		description = "Unlock Shield Generator. Projects protective shield over area.",
		prerequisites = ["building_turret_laser"],
		cost = {21: 180, 62: 150, 70: 130},  # Lithium, Quantum Crystal, Dark Energy
		category = "building",
		tier = 6,
		effects = {unlock_building = "ShieldGenerator"},
		unlock_type = "building",
		position = Vector2(3000, 250)
	},
	{
		id = "building_repair_station",
		name = "Repair Station",
		description = "Unlock Repair Stations. Automatically repairs nearby damaged units.",
		prerequisites = ["building_factory"],
		cost = {0: 180, 20: 150, 60: 130},  # Iron, Silver, Exotic Alloy
		category = "building",
		tier = 4,
		effects = {unlock_building = "RepairStation"},
		unlock_type = "building",
		position = Vector2(2850, 400)
	},
	{
		id = "building_sensor_array",
		name = "Sensor Array",
		description = "Unlock Sensor Arrays. Massively extends vision in zone.",
		prerequisites = [],
		cost = {2: 120, 32: 100, 62: 90},  # Silicon, Gallium, Quantum Crystal
		category = "building",
		tier = 3,
		effects = {unlock_building = "SensorArray"},
		unlock_type = "building",
		position = Vector2(2700, 700)
	},
	{
		id = "building_mining_platform",
		name = "Mining Platform",
		description = "Unlock Mining Platforms. Automated resource extraction.",
		prerequisites = [],
		cost = {0: 150, 1: 120, 10: 100},  # Iron, Carbon, Copper
		category = "building",
		tier = 1,
		effects = {unlock_building = "MiningPlatform"},
		unlock_type = "building",
		position = Vector2(2700, 850)
	},
	{
		id = "building_teleporter",
		name = "Teleport Pad",
		description = "Unlock Teleport Pads. Instant unit transport between pads.",
		prerequisites = ["building_factory"],
		cost = {72: 250, 74: 220, 83: 200},  # Spacetime Fabric, Warp Particle, Dimensional Shard
		category = "building",
		tier = 7,
		effects = {unlock_building = "TeleportPad"},
		unlock_type = "building",
		position = Vector2(3000, 400)
	},
	{
		id = "building_superweapon",
		name = "Superweapon Platform",
		description = "Unlock Superweapon Platform. Devastating zone-wide attack.",
		prerequisites = ["building_turret_plasma", "building_shield_generator"],
		cost = {70: 350, 85: 320, 92: 300, 97: 280},  # Dark Energy, Void Essence, Exotic Matter, Infinitum
		category = "building",
		tier = 9,
		effects = {unlock_building = "SuperweaponPlatform"},
		unlock_type = "building",
		position = Vector2(3150, 175)
	},
	{
		id = "building_upgrade_turret",
		name = "Turret Enhancement",
		description = "All turrets gain +50% damage and +30% range.",
		prerequisites = ["building_turret_basic"],
		cost = {10: 120, 14: 100, 24: 90},  # Copper, Nickel, Tungsten
		category = "building",
		tier = 2,
		effects = {stat_turret_damage = 1.50, stat_turret_range = 1.30},
		unlock_type = "upgrade",
		position = Vector2(2700, 250)
	},
	{
		id = "building_construction_speed",
		name = "Rapid Construction",
		description = "Buildings construct 50% faster.",
		prerequisites = [],
		cost = {0: 100, 10: 80, 15: 70},  # Iron, Copper, Cobalt
		category = "building",
		tier = 1,
		effects = {stat_construction_speed = 1.50},
		unlock_type = "upgrade",
		position = Vector2(2700, 1000)
	},
	
	# ============================================================================
	# ECONOMY RESEARCH BRANCH (15 nodes)
	# ============================================================================
	{
		id = "economy_mining_1",
		name = "Mining Efficiency I",
		description = "Improved mining techniques. +25% mining speed.",
		prerequisites = [],
		cost = {0: 50, 1: 40, 10: 30},  # Iron, Carbon, Copper
		category = "economy",
		tier = 0,
		effects = {stat_mining_speed = 1.25},
		unlock_type = "upgrade",
		position = Vector2(3400, 100)
	},
	{
		id = "economy_mining_2",
		name = "Mining Efficiency II",
		description = "Advanced mining tech. +60% mining speed.",
		prerequisites = ["economy_mining_1"],
		cost = {10: 90, 14: 70, 24: 60},  # Copper, Nickel, Tungsten
		category = "economy",
		tier = 2,
		effects = {stat_mining_speed = 1.60},
		unlock_type = "upgrade",
		position = Vector2(3550, 100)
	},
	{
		id = "economy_mining_3",
		name = "Mining Efficiency III",
		description = "Quantum mining. +120% mining speed.",
		prerequisites = ["economy_mining_2"],
		cost = {30: 140, 40: 120, 62: 100},  # Gold, Platinum, Quantum Crystal
		category = "economy",
		tier = 5,
		effects = {stat_mining_speed = 2.20},
		unlock_type = "upgrade",
		position = Vector2(3700, 100)
	},
	{
		id = "economy_cargo_1",
		name = "Cargo Expansion I",
		description = "Larger cargo holds. +30% cargo capacity.",
		prerequisites = [],
		cost = {0: 60, 3: 50, 11: 40},  # Iron, Aluminum, Zinc
		category = "economy",
		tier = 0,
		effects = {stat_cargo_capacity = 1.30},
		unlock_type = "upgrade",
		position = Vector2(3400, 250)
	},
	{
		id = "economy_cargo_2",
		name = "Cargo Expansion II",
		description = "Advanced storage. +70% cargo capacity.",
		prerequisites = ["economy_cargo_1"],
		cost = {20: 100, 21: 80, 22: 70},  # Silver, Lithium, Beryllium
		category = "economy",
		tier = 2,
		effects = {stat_cargo_capacity = 1.70},
		unlock_type = "upgrade",
		position = Vector2(3550, 250)
	},
	{
		id = "economy_cargo_3",
		name = "Cargo Expansion III",
		description = "Dimensional storage. +150% cargo capacity.",
		prerequisites = ["economy_cargo_2"],
		cost = {60: 150, 72: 130, 83: 120},  # Exotic Alloy, Spacetime Fabric, Dimensional Shard
		category = "economy",
		tier = 6,
		effects = {stat_cargo_capacity = 2.50},
		unlock_type = "upgrade",
		position = Vector2(3700, 250)
	},
	{
		id = "economy_yield_1",
		name = "Resource Yield I",
		description = "Better extraction. +20% resources per asteroid.",
		prerequisites = ["economy_mining_1"],
		cost = {1: 70, 2: 60, 10: 50},  # Carbon, Silicon, Copper
		category = "economy",
		tier = 1,
		effects = {stat_resource_yield = 1.20},
		unlock_type = "upgrade",
		position = Vector2(3400, 400)
	},
	{
		id = "economy_yield_2",
		name = "Resource Yield II",
		description = "Nanite extractors. +50% resources per asteroid.",
		prerequisites = ["economy_yield_1"],
		cost = {30: 120, 31: 100, 60: 90},  # Gold, Titanium, Exotic Alloy
		category = "economy",
		tier = 4,
		effects = {stat_resource_yield = 1.50},
		unlock_type = "upgrade",
		position = Vector2(3550, 400)
	},
	{
		id = "economy_yield_3",
		name = "Resource Yield III",
		description = "Quantum extraction. +100% resources per asteroid.",
		prerequisites = ["economy_yield_2"],
		cost = {62: 180, 63: 160, 68: 150},  # Quantum Crystal, Graviton, Higgs Boson
		category = "economy",
		tier = 6,
		effects = {stat_resource_yield = 2.0},
		unlock_type = "upgrade",
		position = Vector2(3700, 400)
	},
	{
		id = "economy_refining_speed",
		name = "Rapid Refining",
		description = "Faster resource conversion. Refineries work 2x faster.",
		prerequisites = [],
		cost = {2: 80, 21: 70, 65: 60},  # Silicon, Lithium, Plasma Core
		category = "economy",
		tier = 3,
		effects = {stat_refining_speed = 2.0},
		unlock_type = "upgrade",
		position = Vector2(3400, 550)
	},
	{
		id = "economy_refining_efficiency",
		name = "Refining Efficiency",
		description = "Better conversion rates. +50% output from refineries.",
		prerequisites = ["economy_refining_speed"],
		cost = {40: 130, 60: 110, 66: 100},  # Platinum, Exotic Alloy, Fusion Catalyst
		category = "economy",
		tier = 5,
		effects = {stat_refining_efficiency = 1.50},
		unlock_type = "upgrade",
		position = Vector2(3550, 550)
	},
	{
		id = "economy_trade_network",
		name = "Trade Network",
		description = "Automated resource trading. Sell excess resources automatically.",
		prerequisites = [],
		cost = {30: 100, 40: 80, 50: 70},  # Gold, Platinum, Lutetium
		category = "economy",
		tier = 3,
		effects = {ability_auto_trade = true},
		unlock_type = "ability",
		position = Vector2(3400, 700)
	},
	{
		id = "economy_replicator",
		name = "Matter Replicator",
		description = "Create resources from energy. Slowly generate all resource types.",
		prerequisites = ["economy_trade_network"],
		cost = {76: 250, 85: 230, 92: 210},  # Zero-Point Energy, Void Essence, Exotic Matter
		category = "economy",
		tier = 8,
		effects = {ability_matter_replicator = true},
		unlock_type = "ability",
		position = Vector2(3550, 700)
	},
	{
		id = "economy_worker_efficiency",
		name = "Worker Drones",
		description = "Automated labor. Mining/Building drones work 30% faster.",
		prerequisites = [],
		cost = {0: 90, 10: 70, 20: 60},  # Iron, Copper, Silver
		category = "economy",
		tier = 1,
		effects = {stat_worker_speed = 1.30},
		unlock_type = "upgrade",
		position = Vector2(3400, 850)
	},
	{
		id = "economy_energy_core",
		name = "Zero-Point Reactor",
		description = "Unlimited energy. All units have infinite energy (for future systems).",
		prerequisites = ["economy_worker_efficiency"],
		cost = {76: 300, 92: 280, 97: 260},  # Zero-Point Energy, Exotic Matter, Infinitum
		category = "economy",
		tier = 8,
		effects = {stat_infinite_energy = true},
		unlock_type = "upgrade",
		position = Vector2(3550, 850)
	},
	
	# ============================================================================
	# BLUEPRINT COMPONENTS BRANCH (20 nodes)
	# Components for future blueprint builder system
	# ============================================================================
	
	# Blueprint Weapon Components (5 tiers)
	{
		id = "blueprint_weapon_1",
		name = "Blueprint Weapon I",
		description = "Unlocks basic weapon components for blueprint builder.",
		prerequisites = ["weapon_damage_1"],
		cost = {0: 100, 3: 50},  # Iron Ore, Aluminum
		category = "blueprint",
		tier = 0,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(100, 1500)
	},
	{
		id = "blueprint_weapon_2",
		name = "Blueprint Weapon II",
		description = "Unlocks improved weapon components for blueprint builder.",
		prerequisites = ["blueprint_weapon_1"],
		cost = {0: 200, 3: 100, 4: 50},  # Iron, Aluminum, Titanium
		category = "blueprint",
		tier = 1,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(250, 1500)
	},
	{
		id = "blueprint_weapon_3",
		name = "Blueprint Weapon III",
		description = "Unlocks advanced weapon components for blueprint builder.",
		prerequisites = ["blueprint_weapon_2"],
		cost = {0: 350, 3: 200, 4: 100, 10: 50},  # Iron, Aluminum, Titanium, Tungsten
		category = "blueprint",
		tier = 2,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(400, 1500)
	},
	{
		id = "blueprint_weapon_4",
		name = "Blueprint Weapon IV",
		description = "Unlocks high-grade weapon components for blueprint builder.",
		prerequisites = ["blueprint_weapon_3"],
		cost = {0: 500, 3: 350, 4: 200, 10: 100, 15: 50},  # Iron, Aluminum, Titanium, Tungsten, Iridium
		category = "blueprint",
		tier = 3,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(550, 1500)
	},
	{
		id = "blueprint_weapon_5",
		name = "Blueprint Weapon V",
		description = "Unlocks ultimate weapon components for blueprint builder.",
		prerequisites = ["blueprint_weapon_4"],
		cost = {0: 750, 3: 500, 4: 350, 10: 200, 15: 100, 20: 50},  # Iron, Aluminum, Titanium, Tungsten, Iridium, Platinum
		category = "blueprint",
		tier = 4,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(700, 1500)
	},
	
	# Blueprint Shield Components (5 tiers)
	{
		id = "blueprint_shield_1",
		name = "Blueprint Shield I",
		description = "Unlocks basic shield components for blueprint builder.",
		prerequisites = ["shield_basic_1"],
		cost = {1: 100, 5: 50},  # Carbon, Cobalt
		category = "blueprint",
		tier = 0,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(100, 1650)
	},
	{
		id = "blueprint_shield_2",
		name = "Blueprint Shield II",
		description = "Unlocks improved shield components for blueprint builder.",
		prerequisites = ["blueprint_shield_1"],
		cost = {1: 200, 5: 100, 6: 50},  # Carbon, Cobalt, Nickel
		category = "blueprint",
		tier = 1,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(250, 1650)
	},
	{
		id = "blueprint_shield_3",
		name = "Blueprint Shield III",
		description = "Unlocks advanced shield components for blueprint builder.",
		prerequisites = ["blueprint_shield_2"],
		cost = {1: 350, 5: 200, 6: 100, 11: 50},  # Carbon, Cobalt, Nickel, Chromium
		category = "blueprint",
		tier = 2,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(400, 1650)
	},
	{
		id = "blueprint_shield_4",
		name = "Blueprint Shield IV",
		description = "Unlocks high-grade shield components for blueprint builder.",
		prerequisites = ["blueprint_shield_3"],
		cost = {1: 500, 5: 350, 6: 200, 11: 100, 16: 50},  # Carbon, Cobalt, Nickel, Chromium, Osmium
		category = "blueprint",
		tier = 3,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(550, 1650)
	},
	{
		id = "blueprint_shield_5",
		name = "Blueprint Shield V",
		description = "Unlocks ultimate shield components for blueprint builder.",
		prerequisites = ["blueprint_shield_4"],
		cost = {1: 750, 5: 500, 6: 350, 11: 200, 16: 100, 21: 50},  # Carbon, Cobalt, Nickel, Chromium, Osmium, Rhodium
		category = "blueprint",
		tier = 4,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(700, 1650)
	},
	
	# Blueprint Energy Core Components (5 tiers)
	{
		id = "blueprint_energy_1",
		name = "Blueprint Energy Core I",
		description = "Unlocks basic energy core components for blueprint builder.",
		prerequisites = ["energy_efficiency_1"],
		cost = {2: 100, 7: 50},  # Silicon, Lithium
		category = "blueprint",
		tier = 0,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(100, 1800)
	},
	{
		id = "blueprint_energy_2",
		name = "Blueprint Energy Core II",
		description = "Unlocks improved energy core components for blueprint builder.",
		prerequisites = ["blueprint_energy_1"],
		cost = {2: 200, 7: 100, 8: 50},  # Silicon, Lithium, Uranium
		category = "blueprint",
		tier = 1,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(250, 1800)
	},
	{
		id = "blueprint_energy_3",
		name = "Blueprint Energy Core III",
		description = "Unlocks advanced energy core components for blueprint builder.",
		prerequisites = ["blueprint_energy_2"],
		cost = {2: 350, 7: 200, 8: 100, 12: 50},  # Silicon, Lithium, Uranium, Palladium
		category = "blueprint",
		tier = 2,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(400, 1800)
	},
	{
		id = "blueprint_energy_4",
		name = "Blueprint Energy Core IV",
		description = "Unlocks high-grade energy core components for blueprint builder.",
		prerequisites = ["blueprint_energy_3"],
		cost = {2: 500, 7: 350, 8: 200, 12: 100, 17: 50},  # Silicon, Lithium, Uranium, Palladium, Thorium
		category = "blueprint",
		tier = 3,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(550, 1800)
	},
	{
		id = "blueprint_energy_5",
		name = "Blueprint Energy Core V",
		description = "Unlocks ultimate energy core components for blueprint builder.",
		prerequisites = ["blueprint_energy_4"],
		cost = {2: 750, 7: 500, 8: 350, 12: 200, 17: 100, 22: 50},  # Silicon, Lithium, Uranium, Palladium, Thorium, Antimatter
		category = "blueprint",
		tier = 4,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(700, 1800)
	},
	
	# Blueprint Hull Components (5 tiers)
	{
		id = "blueprint_hull_1",
		name = "Blueprint Hull I",
		description = "Unlocks basic hull components for blueprint builder.",
		prerequisites = ["hull_reinforced_1"],
		cost = {0: 100, 9: 50},  # Iron Ore, Copper
		category = "blueprint",
		tier = 0,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(100, 1950)
	},
	{
		id = "blueprint_hull_2",
		name = "Blueprint Hull II",
		description = "Unlocks improved hull components for blueprint builder.",
		prerequisites = ["blueprint_hull_1"],
		cost = {0: 200, 9: 100, 13: 50},  # Iron, Copper, Zinc
		category = "blueprint",
		tier = 1,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(250, 1950)
	},
	{
		id = "blueprint_hull_3",
		name = "Blueprint Hull III",
		description = "Unlocks advanced hull components for blueprint builder.",
		prerequisites = ["blueprint_hull_2"],
		cost = {0: 350, 9: 200, 13: 100, 14: 50},  # Iron, Copper, Zinc, Lead
		category = "blueprint",
		tier = 2,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(400, 1950)
	},
	{
		id = "blueprint_hull_4",
		name = "Blueprint Hull IV",
		description = "Unlocks high-grade hull components for blueprint builder.",
		prerequisites = ["blueprint_hull_3"],
		cost = {0: 500, 9: 350, 13: 200, 14: 100, 18: 50},  # Iron, Copper, Zinc, Lead, Beryllium
		category = "blueprint",
		tier = 3,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(550, 1950)
	},
	{
		id = "blueprint_hull_5",
		name = "Blueprint Hull V",
		description = "Unlocks ultimate hull components for blueprint builder.",
		prerequisites = ["blueprint_hull_4"],
		cost = {0: 750, 9: 500, 13: 350, 14: 200, 18: 100, 19: 50},  # Iron, Copper, Zinc, Lead, Beryllium, Graphene
		category = "blueprint",
		tier = 4,
		effects = {},
		unlock_type = "blueprint_component",
		position = Vector2(700, 1950)
	},
]

# Helper functions
func get_research_by_id(research_id: String) -> Dictionary:
	"""Get research node by ID"""
	for research in RESEARCH_NODES:
		if research.id == research_id:
			return research
	return {}

func get_research_by_category(category: String) -> Array:
	"""Get all research nodes in a category"""
	var result = []
	for research in RESEARCH_NODES:
		if research.category == category:
			result.append(research)
	return result

func get_all_categories() -> Array:
	"""Get list of all unique categories"""
	return ["hull", "shield", "weapon", "ability", "building", "economy", "blueprint"]

func get_category_display_name(category: String) -> String:
	"""Get display name for category"""
	match category:
		"hull": return "Hull Systems"
		"shield": return "Shield Technology"
		"weapon": return "Weapons"
		"ability": return "Special Abilities"
		"building": return "Structures"
		"economy": return "Economy"
		"blueprint": return "Blueprint Components"
		_: return category.capitalize()

func get_category_color(category: String) -> Color:
	"""Get UI color for category"""
	match category:
		"hull": return Color(0.7, 0.5, 0.3)  # Bronze
		"shield": return Color(0.3, 0.6, 1.0)  # Blue
		"weapon": return Color(1.0, 0.3, 0.3)  # Red
		"ability": return Color(0.5, 1.0, 0.5)  # Green
		"building": return Color(0.8, 0.8, 0.3)  # Yellow
		"economy": return Color(1.0, 0.8, 0.2)  # Gold
		"blueprint": return Color(0.6, 0.3, 0.8)  # Purple
		_: return Color.WHITE

func get_total_research_count() -> int:
	"""Get total number of research nodes"""
	return RESEARCH_NODES.size()

func get_research_time(research_id: String) -> float:
	"""Get research time for a research node (calculated from tier if not specified)"""
	var research = get_research_by_id(research_id)
	if research.is_empty():
		return 30.0
	
	# Check if research_time is specified
	if "research_time" in research:
		return research.research_time
	
	# Calculate from tier (Tier 0 = 10s, Tier 9 = 120s)
	var tier = research.get("tier", 0)
	return 10.0 + (tier * 12.0)  # Tier 0=10s, Tier 1=22s, Tier 2=34s ... Tier 9=118s

