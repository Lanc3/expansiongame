extends Node
## Global research manager - tracks unlocked research and applies effects

signal research_unlocked(research_id: String)
signal research_available(research_id: String)
signal research_failed(research_id: String, reason: String)
signal research_started(research_id: String, research_time: float)
signal research_progress_updated(research_id: String, progress: float)

# Unlocked research tracking
var unlocked_research: Dictionary = {}  # research_id -> true

# Current research in progress
var current_research_id: String = ""
var research_progress: float = 0.0
var research_time_total: float = 0.0

# Applied effects tracking (for stat multipliers)
var applied_effects: Dictionary = {
	# Hull
	stat_hull_multiplier = 1.0,
	stat_hull_regen = 0.0,
	stat_damage_resistance = 0.0,
	stat_damage_reflection = 0.0,
	stat_adaptive_armor = false,
	
	# Shields
	stat_shield_max = 0,
	stat_shield_regen = 0.0,
	stat_shield_absorption = 0.0,
	stat_phase_chance = 0.0,
	stat_adaptive_shield = false,
	stat_temporal_rewind = false,
	stat_projectile_absorption = 0.0,
	
	# Weapons
	stat_kinetic_damage = 1.0,
	stat_energy_damage = 1.0,
	stat_explosive_damage = 1.0,
	stat_all_weapon_damage = 1.0,
	stat_armor_piercing = 0.0,
	stat_shield_penetration = 0.0,
	stat_burn_damage = 0.0,
	stat_aoe_radius = 1.0,
	stat_ignore_defenses = false,
	stat_reality_erasure = false,
	stat_weapon_slots = 1,
	stat_fire_rate = 1.0,
	stat_accuracy = 1.0,
	stat_crit_chance = 0.0,
	stat_predictive_targeting = false,
	stat_weapon_range = 1.0,
	stat_unlimited_ammo = false,
	
	# Abilities
	stat_vision_range = 1.0,
	stat_detect_stealth = false,
	stat_stealth_level = 0.0,
	stat_stealth_move = false,
	stat_warp_range = 0,
	stat_combat_warp = false,
	stat_drain_percentage = 0.0,
	
	# Economy
	stat_mining_speed = 1.0,
	stat_cargo_capacity = 1.0,
	stat_resource_yield = 1.0,
	stat_refining_speed = 1.0,
	stat_refining_efficiency = 1.0,
	stat_worker_speed = 1.0,
	stat_infinite_energy = false,
	stat_build_time_reduction = 0.0,
	stat_build_cost_reduction = 0.0,
	
	# Buildings
	stat_turret_damage = 1.0,
	stat_turret_range = 1.0,
	stat_construction_speed = 1.0,
}

# Unlocked abilities
var unlocked_abilities: Dictionary = {}  # ability_name -> true
var unlocked_buildings: Dictionary = {}  # building_name -> true

func _ready():
	# Initialize with no research
	set_process(true)

func _process(delta: float):
	"""Process ongoing research"""
	if current_research_id == "":
		return
	
	# Increment research progress
	research_progress += delta
	
	# Emit progress update
	var progress_percent = clamp(research_progress / research_time_total, 0.0, 1.0)
	research_progress_updated.emit(current_research_id, progress_percent)
	
	# Check if research complete
	if research_progress >= research_time_total:
		complete_research()

func is_researching() -> bool:
	"""Check if currently researching something"""
	return current_research_id != ""

func can_research(research_id: String) -> bool:
	"""Check if research can be started (prerequisites and resources)"""
	# Check if already researching something
	if is_researching():
		return false
	
	# Check if already unlocked
	if is_unlocked(research_id):
		return false
	
	var research = ResearchDatabase.get_research_by_id(research_id)
	if research.is_empty():
		return false
	
	# Check prerequisites
	for prereq_id in research.prerequisites:
		if not is_unlocked(prereq_id):
			return false
	
	# Check resource costs
	if not ResourceManager:
		return false
	
	var can_afford = ResourceManager.can_afford_cost(research.cost)
	return can_afford

func start_research(research_id: String) -> bool:
	"""Start researching (consumes resources, takes time)"""
	if not can_research(research_id):
		research_failed.emit(research_id, "Cannot research: prerequisites, resources, or already researching")
		return false
	
	var research = ResearchDatabase.get_research_by_id(research_id)
	if research.is_empty():
		research_failed.emit(research_id, "Research not found")
		return false
	
	# Consume resources upfront
	if not ResourceManager.consume_resources(research.cost):
		research_failed.emit(research_id, "Failed to consume resources")
		return false
	
	# Start research
	current_research_id = research_id
	research_progress = 0.0
	research_time_total = ResearchDatabase.get_research_time(research_id)
	
	# Emit signal
	research_started.emit(research_id, research_time_total)
	
	print("ResearchManager: Started research on %s - %s (%.0f seconds)" % [research_id, research.name, research_time_total])
	
	return true

func complete_research():
	"""Complete current research and apply effects"""
	if current_research_id == "":
		return
	
	var research = ResearchDatabase.get_research_by_id(current_research_id)
	if research.is_empty():
		current_research_id = ""
		return
	
	
	# Mark as unlocked
	unlocked_research[current_research_id] = true
	
	# Apply effects
	apply_research_effects_internal(research)
	
	# Store completed ID before clearing
	var completed_id = current_research_id
	
	# Clear current research BEFORE emitting signal
	current_research_id = ""
	research_progress = 0.0
	research_time_total = 0.0
	
	# Emit signal (after clearing so can_research works correctly)
	research_unlocked.emit(completed_id)
	
	
	# Check for newly available research
	check_newly_available_research()

func unlock_research(research_id: String) -> bool:
	"""Backwards compatibility - starts research"""
	return start_research(research_id)

func cancel_research():
	"""Cancel current research (refunds resources)"""
	if current_research_id == "":
		return
	
	var research = ResearchDatabase.get_research_by_id(current_research_id)
	if not research.is_empty() and ResourceManager:
		ResourceManager.refund_resources(research.cost)
	
	
	current_research_id = ""
	research_progress = 0.0
	research_time_total = 0.0

func is_unlocked(research_id: String) -> bool:
	"""Check if research is unlocked"""
	return research_id in unlocked_research and unlocked_research[research_id]

func get_unlocked_count() -> int:
	"""Get total number of unlocked research"""
	return unlocked_research.size()

func get_available_research() -> Array:
	"""Get all research that can currently be researched"""
	var available = []
	
	for research in ResearchDatabase.RESEARCH_NODES:
		if can_research(research.id):
			available.append(research)
	
	return available

func get_locked_research() -> Array:
	"""Get research that is locked (prerequisites not met)"""
	var locked = []
	
	for research in ResearchDatabase.RESEARCH_NODES:
		if is_unlocked(research.id):
			continue
		
		# Check if prerequisites are met
		var prereqs_met = true
		for prereq_id in research.prerequisites:
			if not is_unlocked(prereq_id):
				prereqs_met = false
				break
		
		if not prereqs_met:
			locked.append(research)
	
	return locked

func apply_research_effects_internal(research: Dictionary):
	"""Apply research effects to global stats"""
	for effect_key in research.effects:
		var effect_value = research.effects[effect_key]
		
		# Handle different effect types
		if effect_key.begins_with("stat_"):
			# Stat modification
			if effect_key in applied_effects:
				# For multipliers, multiply together; for additive stats, add
				if effect_key.ends_with("_multiplier") or effect_key.ends_with("_damage") or \
				   effect_key.ends_with("_speed") or effect_key.ends_with("_rate") or \
				   effect_key.ends_with("_capacity") or effect_key.ends_with("_range") or \
				   effect_key.ends_with("_efficiency") or effect_key.ends_with("_accuracy"):
					# Multiplicative (convert from 1.25 to *1.25 cumulative)
					if typeof(applied_effects[effect_key]) == TYPE_FLOAT or typeof(applied_effects[effect_key]) == TYPE_INT:
						if effect_value > 1.0:
							# It's a multiplier like 1.25 (25% increase)
							var bonus = effect_value - 1.0
							var current_bonus = applied_effects[effect_key] - 1.0
							applied_effects[effect_key] = 1.0 + current_bonus + bonus
						else:
							applied_effects[effect_key] = effect_value
				else:
					# Additive
					if typeof(effect_value) == TYPE_BOOL:
						applied_effects[effect_key] = effect_value
					elif typeof(effect_value) == TYPE_INT:
						applied_effects[effect_key] += effect_value
					else:
						applied_effects[effect_key] += effect_value
		
		elif effect_key.begins_with("ability_"):
			# Ability unlock
			var ability_name = effect_key
			unlocked_abilities[ability_name] = true
		
		elif effect_key == "unlock_building":
			# Building unlock
			unlocked_buildings[effect_value] = true

func has_ability(ability_name: String) -> bool:
	"""Check if ability is unlocked"""
	return ability_name in unlocked_abilities and unlocked_abilities[ability_name]

func can_build(building_name: String) -> bool:
	"""Check if building can be constructed"""
	return building_name in unlocked_buildings and unlocked_buildings[building_name]

func get_stat(stat_name: String) -> Variant:
	"""Get current value of a stat"""
	if stat_name in applied_effects:
		return applied_effects[stat_name]
	return null

func apply_research_to_unit(unit: Node2D):
	"""Apply all unlocked research effects to a unit"""
	if not is_instance_valid(unit):
		return
	
	# Apply hull multipliers
	if "max_health" in unit:
		var base_health = unit.max_health
		unit.max_health = base_health * applied_effects.stat_hull_multiplier
		if unit.current_health > unit.max_health:
			unit.current_health = unit.max_health
	
	# Apply shield additions
	if "max_shield" in unit:
		unit.max_shield = applied_effects.stat_shield_max
	
	# Apply vision range
	if "vision_range" in unit:
		var base_vision = unit.vision_range
		unit.vision_range = base_vision * applied_effects.stat_vision_range
	
	# Apply weapon range
	if "attack_range" in unit:
		var base_range = unit.attack_range
		unit.attack_range = base_range * applied_effects.stat_weapon_range
	
	# Apply mining speed
	if unit.can_mine() and "mining_speed" in unit:
		var base_speed = unit.mining_speed
		unit.mining_speed = base_speed * applied_effects.stat_mining_speed
	
	# Apply cargo capacity
	if "max_cargo" in unit:
		var base_cargo = unit.max_cargo
		unit.max_cargo = int(base_cargo * applied_effects.stat_cargo_capacity)

func apply_research_to_building(building: Node2D):
	"""Apply all unlocked research effects to a building"""
	if not is_instance_valid(building):
		return
	
	# Apply turret bonuses
	if building.is_in_group("turrets"):
		if "damage" in building:
			var base_damage = building.damage
			building.damage = base_damage * applied_effects.stat_turret_damage
		
		if "attack_range" in building:
			var base_range = building.attack_range
			building.attack_range = base_range * applied_effects.stat_turret_range

func check_newly_available_research():
	"""Check for research that just became available and emit signals"""
	for research in ResearchDatabase.RESEARCH_NODES:
		if is_unlocked(research.id):
			continue
		
		# Check if all prerequisites are met
		var all_prereqs_met = true
		for prereq_id in research.prerequisites:
			if not is_unlocked(prereq_id):
				all_prereqs_met = false
				break
		
		if all_prereqs_met:
			research_available.emit(research.id)

# Save/Load support
func get_save_data() -> Dictionary:
	"""Get save data for persistence"""
	return {
		"unlocked_research": unlocked_research,
		"unlocked_abilities": unlocked_abilities,
		"unlocked_buildings": unlocked_buildings
	}

func load_save_data(data: Dictionary):
	"""Load research state from save data"""
	if "unlocked_research" in data:
		unlocked_research = data.unlocked_research
	
	if "unlocked_abilities" in data:
		unlocked_abilities = data.unlocked_abilities
	
	if "unlocked_buildings" in data:
		unlocked_buildings = data.unlocked_buildings
	
	# Recalculate all effects
	recalculate_effects()
	
	print("ResearchManager: Loaded %d researches" % unlocked_research.size())

func recalculate_effects():
	"""Recalculate all effects from scratch (used after loading)"""
	# Reset to defaults
	applied_effects = {
		stat_hull_multiplier = 1.0,
		stat_hull_regen = 0.0,
		stat_damage_resistance = 0.0,
		stat_damage_reflection = 0.0,
		stat_adaptive_armor = false,
		stat_shield_max = 0,
		stat_shield_regen = 0.0,
		stat_shield_absorption = 0.0,
		stat_phase_chance = 0.0,
		stat_adaptive_shield = false,
		stat_temporal_rewind = false,
		stat_projectile_absorption = 0.0,
		stat_kinetic_damage = 1.0,
		stat_energy_damage = 1.0,
		stat_explosive_damage = 1.0,
		stat_all_weapon_damage = 1.0,
		stat_armor_piercing = 0.0,
		stat_shield_penetration = 0.0,
		stat_burn_damage = 0.0,
		stat_aoe_radius = 1.0,
		stat_ignore_defenses = false,
		stat_reality_erasure = false,
		stat_weapon_slots = 1,
		stat_fire_rate = 1.0,
		stat_accuracy = 1.0,
		stat_crit_chance = 0.0,
		stat_predictive_targeting = false,
		stat_weapon_range = 1.0,
		stat_unlimited_ammo = false,
		stat_vision_range = 1.0,
		stat_detect_stealth = false,
		stat_stealth_level = 0.0,
		stat_stealth_move = false,
		stat_warp_range = 0,
		stat_combat_warp = false,
		stat_drain_percentage = 0.0,
		stat_mining_speed = 1.0,
		stat_cargo_capacity = 1.0,
		stat_resource_yield = 1.0,
		stat_refining_speed = 1.0,
		stat_refining_efficiency = 1.0,
		stat_worker_speed = 1.0,
		stat_infinite_energy = false,
		stat_build_time_reduction = 0.0,
		stat_build_cost_reduction = 0.0,
		stat_turret_damage = 1.0,
		stat_turret_range = 1.0,
		stat_construction_speed = 1.0,
	}
	
	# Reapply all unlocked research
	for research_id in unlocked_research:
		var research = ResearchDatabase.get_research_by_id(research_id)
		if not research.is_empty():
			apply_research_effects_internal(research)

func reset_all_research():
	"""Reset all research (for debugging/testing)"""
	unlocked_research.clear()
	unlocked_abilities.clear()
	unlocked_buildings.clear()
	recalculate_effects()
