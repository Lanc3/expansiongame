extends Node
class_name WeaponComponent
## Weapon component for combat units - supports 21 weapon types

# All 21 weapon types organized by category
enum WeaponType {
	# Existing
	LASER = 0,           # Rapid fire red projectile
	MISSILE = 1,         # Homing orange projectile
	
	# Kinetic (index 2-6)
	AUTOCANNON = 2,      # Rapid ballistic, yellow/brass
	RAILGUN = 3,         # High damage piercing, blue streak
	GATLING = 4,         # Very fast fire, small white tracers
	SNIPER = 5,          # Extreme range, slow fire, green tracer
	SHOTGUN = 6,         # Cone spread, close range
	
	# Energy (index 7-11)
	ION_CANNON = 7,      # Blue pulse beam, EMP effect
	PLASMA_CANNON = 8,   # Slow green blob, high damage
	PARTICLE_BEAM = 9,   # Sustained purple beam
	TESLA_COIL = 10,     # Chain lightning, electric blue
	DISRUPTOR = 11,      # Pink projectile, shield bypass
	
	# Explosive (index 12-16)
	FLAK_CANNON = 12,    # Circle AOE burst
	TORPEDO = 13,        # Heavy homing, very slow
	ROCKET_POD = 14,     # Multiple small rockets
	MORTAR = 15,         # Arcing AOE projectile
	MINE_LAYER = 16,     # Deployable mines
	
	# Special (index 17-20)
	CRYO_CANNON = 17,    # Light blue, slows target
	EMP_BURST = 18,      # Ring AOE, disables enemies
	GRAVITY_WELL = 19,   # Pulls enemies toward point
	REPAIR_BEAM = 20     # Green beam, heals friendlies
}

# AOE shape types
enum AOEType {
	NONE = 0,
	CIRCLE = 1,          # Standard circular explosion
	CONE = 2,            # Shotgun/flamethrower spread
	LINE = 3,            # Piercing/railgun
	RING = 4             # Expanding shockwave
}

# Special effects that weapons can apply
enum SpecialEffect {
	NONE = 0,
	EMP = 1,             # Disables target temporarily
	SLOW = 2,            # Reduces movement speed
	PIERCE = 3,          # Passes through targets
	SHIELD_BYPASS = 4,   # Ignores shields
	CHAIN = 5,           # Jumps to nearby targets
	DOT = 6,             # Damage over time (burn)
	PULL = 7,            # Pulls target toward point
	HEAL = 8             # Heals instead of damages (for repair beam)
}

# Weapon category for UI organization
enum WeaponCategory {
	KINETIC = 0,
	ENERGY = 1,
	EXPLOSIVE = 2,
	SPECIAL = 3
}

# Basic weapon properties
@export var weapon_type: WeaponType = WeaponType.LASER
@export var damage: float = 10.0
@export var fire_rate: float = 1.0  # shots per second
@export var rangeAim: float = 300.0
@export var projectile_speed: float = 500.0
@export var homing: bool = false  # For missiles/torpedoes

# AOE properties
@export var aoe_radius: float = 0.0  # 0 = single target
@export var aoe_type: AOEType = AOEType.NONE
@export var cone_angle: float = 45.0  # For cone AOE (degrees)

# Special effect properties
@export var special_effect: SpecialEffect = SpecialEffect.NONE
@export var effect_duration: float = 0.0  # How long effect lasts
@export var effect_strength: float = 0.0  # Effect intensity (slow %, etc)

# Multi-projectile properties
@export var projectile_count: int = 1  # For shotgun, rocket pod
@export var spread_angle: float = 0.0  # Spread for multi-projectile

# Beam weapon properties
@export var is_beam: bool = false  # Continuous beam vs projectile
@export var beam_width: float = 4.0

# Support weapon properties
@export var is_support: bool = false  # Targets friendlies (repair beam)

# Chain properties (tesla coil)
@export var chain_count: int = 0  # Number of chain jumps
@export var chain_range: float = 100.0  # Range for chain jumps
@export var chain_damage_falloff: float = 0.7  # Damage multiplier per jump

# Flak cannon properties
@export var flak_bullet_count: int = 25  # Number of bullets per burst
@export var flak_mini_aoe: float = 22.0  # Small explosion radius per bullet

# Mine layer properties
@export var mine_timer: float = 30.0  # Countdown timer before auto-detonation

# Mortar properties
@export var mortar_bullet_count: int = 8  # Number of shells per burst (fewer than flak)
@export var mortar_mini_aoe: float = 40.0  # Explosion radius per shell (bigger than flak)

var cooldown_timer: float = 0.0
var current_target_aoe_radius: float = 0.0  # Adjustable AOE radius from marker

# Category lookup
const WEAPON_CATEGORIES: Dictionary = {
	WeaponType.LASER: WeaponCategory.KINETIC,
	WeaponType.AUTOCANNON: WeaponCategory.KINETIC,
	WeaponType.RAILGUN: WeaponCategory.KINETIC,
	WeaponType.GATLING: WeaponCategory.KINETIC,
	WeaponType.SNIPER: WeaponCategory.KINETIC,
	WeaponType.SHOTGUN: WeaponCategory.KINETIC,
	
	WeaponType.ION_CANNON: WeaponCategory.ENERGY,
	WeaponType.PLASMA_CANNON: WeaponCategory.ENERGY,
	WeaponType.PARTICLE_BEAM: WeaponCategory.ENERGY,
	WeaponType.TESLA_COIL: WeaponCategory.ENERGY,
	WeaponType.DISRUPTOR: WeaponCategory.ENERGY,
	
	WeaponType.MISSILE: WeaponCategory.EXPLOSIVE,
	WeaponType.FLAK_CANNON: WeaponCategory.EXPLOSIVE,
	WeaponType.TORPEDO: WeaponCategory.EXPLOSIVE,
	WeaponType.ROCKET_POD: WeaponCategory.EXPLOSIVE,
	WeaponType.MORTAR: WeaponCategory.EXPLOSIVE,
	WeaponType.MINE_LAYER: WeaponCategory.EXPLOSIVE,
	
	WeaponType.CRYO_CANNON: WeaponCategory.SPECIAL,
	WeaponType.EMP_BURST: WeaponCategory.SPECIAL,
	WeaponType.GRAVITY_WELL: WeaponCategory.SPECIAL,
	WeaponType.REPAIR_BEAM: WeaponCategory.SPECIAL
}

# Display names for UI
const WEAPON_NAMES: Dictionary = {
	WeaponType.LASER: "Laser",
	WeaponType.MISSILE: "Missile",
	WeaponType.AUTOCANNON: "Autocannon",
	WeaponType.RAILGUN: "Railgun",
	WeaponType.GATLING: "Gatling Gun",
	WeaponType.SNIPER: "Sniper Cannon",
	WeaponType.SHOTGUN: "Shotgun",
	WeaponType.ION_CANNON: "Ion Cannon",
	WeaponType.PLASMA_CANNON: "Plasma Cannon",
	WeaponType.PARTICLE_BEAM: "Particle Beam",
	WeaponType.TESLA_COIL: "Tesla Coil",
	WeaponType.DISRUPTOR: "Disruptor",
	WeaponType.FLAK_CANNON: "Flak Cannon",
	WeaponType.TORPEDO: "Torpedo",
	WeaponType.ROCKET_POD: "Rocket Pod",
	WeaponType.MORTAR: "Mortar",
	WeaponType.MINE_LAYER: "Mine Layer",
	WeaponType.CRYO_CANNON: "Cryo Cannon",
	WeaponType.EMP_BURST: "EMP Burst",
	WeaponType.GRAVITY_WELL: "Gravity Well",
	WeaponType.REPAIR_BEAM: "Repair Beam"
}

func _ready():
	pass

func _process(delta: float):
	if cooldown_timer > 0:
		cooldown_timer -= delta

func can_fire() -> bool:
	return cooldown_timer <= 0

func get_cooldown_percent() -> float:
	"""Returns 0.0 when ready to fire, 1.0 when just fired (full cooldown)"""
	if fire_rate <= 0:
		return 0.0
	if cooldown_timer <= 0:
		return 0.0
	var cooldown_time = 1.0 / fire_rate
	return clampf(cooldown_timer / cooldown_time, 0.0, 1.0)

func get_range() -> float:
	return rangeAim

func get_aoe_radius() -> float:
	return aoe_radius

func get_category() -> WeaponCategory:
	return WEAPON_CATEGORIES.get(weapon_type, WeaponCategory.KINETIC)

func get_display_name() -> String:
	return WEAPON_NAMES.get(weapon_type, "Unknown")

func is_aoe_weapon() -> bool:
	return aoe_radius > 0 and aoe_type != AOEType.NONE

func fire_at(target: Node2D, from_position: Vector2):
	if not can_fire():
		return
	if target and not is_instance_valid(target):
		return
	
	cooldown_timer = 1.0 / fire_rate
	
	# Play weapon sound with spatial audio
	if AudioManager:
		AudioManager.play_weapon_sound(from_position)
	
	var target_pos = target.global_position if target else from_position + Vector2(100, 0)
	
	# Handle different weapon firing modes
	if is_beam:
		_fire_beam(target_pos, from_position, target)
	elif weapon_type == WeaponType.FLAK_CANNON:
		_fire_flak_burst(target_pos, from_position)
	elif weapon_type == WeaponType.MORTAR:
		_fire_mortar_burst(target_pos, from_position)
	elif weapon_type == WeaponType.TORPEDO:
		_fire_torpedo_aoe(target_pos, from_position)
	elif weapon_type == WeaponType.MINE_LAYER:
		_fire_mine(target_pos, from_position)
	elif projectile_count > 1:
		_fire_spread(target_pos, from_position, target)
	else:
		_fire_single_projectile(target_pos, from_position, target if homing else null)

func fire_at_position(target_pos: Vector2, from_position: Vector2):
	if not can_fire():
		return

	cooldown_timer = 1.0 / fire_rate

	if AudioManager:
		AudioManager.play_weapon_sound(from_position)

	# Handle different weapon firing modes
	if is_beam:
		_fire_beam(target_pos, from_position, null)
	elif weapon_type == WeaponType.FLAK_CANNON:
		_fire_flak_burst(target_pos, from_position)
	elif weapon_type == WeaponType.MORTAR:
		_fire_mortar_burst(target_pos, from_position)
	elif weapon_type == WeaponType.TORPEDO:
		_fire_torpedo_aoe(target_pos, from_position)
	elif weapon_type == WeaponType.MINE_LAYER:
		_fire_mine(target_pos, from_position)
	elif projectile_count > 1:
		_fire_spread(target_pos, from_position, null)
	else:
		_fire_single_projectile(target_pos, from_position, null)

func set_target_aoe_radius(radius: float):
	"""Set the target AOE radius (used by marker adjustment)"""
	current_target_aoe_radius = radius

func _fire_single_projectile(target_pos: Vector2, from_position: Vector2, homing_target: Node2D):
	var projectile: Projectile
	if ProjectilePool:
		projectile = ProjectilePool.get_projectile()
	else:
		var projectile_scene = preload("res://scenes/effects/Projectile.tscn")
		projectile = projectile_scene.instantiate()
		get_tree().root.add_child(projectile)

	# Extended setup with new properties
	projectile.setup_extended(
		weapon_type,
		damage,
		from_position,
		target_pos,
		projectile_speed,
		homing_target,
		get_parent(),
		aoe_radius,
		aoe_type,
		special_effect,
		effect_duration,
		effect_strength,
		chain_count,
		chain_range,
		chain_damage_falloff
	)

func _fire_spread(target_pos: Vector2, from_position: Vector2, homing_target: Node2D):
	"""Fire multiple projectiles in a spread pattern (shotgun, rocket pod)"""
	var base_direction = (target_pos - from_position).normalized()
	var base_angle = base_direction.angle()
	
	# Calculate spread
	var angle_step = spread_angle / max(1, projectile_count - 1) if projectile_count > 1 else 0
	var start_angle = base_angle - spread_angle / 2.0
	
	for i in range(projectile_count):
		var shot_angle = start_angle + angle_step * i
		# Calculate direction vector from angle
		# Add PI to flip direction 180 degrees to fix shotgun orientation
		var shot_direction = Vector2(cos(shot_angle + PI), sin(shot_angle + PI))
		# Calculate target position far enough away for proper direction
		# Ensure minimum distance to avoid direction calculation issues
		var min_distance = max(rangeAim, 100.0)
		var shot_target = from_position + shot_direction * min_distance
		
		var projectile: Projectile
		if ProjectilePool:
			projectile = ProjectilePool.get_projectile()
		else:
			var projectile_scene = preload("res://scenes/effects/Projectile.tscn")
			projectile = projectile_scene.instantiate()
			get_tree().root.add_child(projectile)
		
		# Reduce damage per pellet for shotgun-type weapons
		var pellet_damage = damage / projectile_count if weapon_type == WeaponType.SHOTGUN else damage
		
		projectile.setup_extended(
			weapon_type,
			pellet_damage,
			from_position,
			shot_target,
			projectile_speed,
			null,  # No homing for spread weapons
			get_parent(),
			aoe_radius,
			aoe_type,
			special_effect,
			effect_duration,
			effect_strength,
			0, 0, 0  # No chain for spread
		)

func _fire_flak_burst(target_center: Vector2, from_position: Vector2):
	"""Fire multiple small projectiles that spread across the AOE circle"""
	# Use adjusted radius if set, otherwise use base aoe_radius
	var effective_radius = current_target_aoe_radius if current_target_aoe_radius > 0 else aoe_radius
	if effective_radius <= 0:
		effective_radius = 50.0  # Default fallback
	
	# Calculate bullet count - scale with radius, base ~25 at medium size
	var bullet_count = flak_bullet_count
	if bullet_count <= 0:
		bullet_count = int(effective_radius / 2.5)  # ~25 bullets at radius 60
	
	# Damage per bullet (total damage divided among bullets)
	var damage_per_bullet = damage / float(bullet_count)
	
	# Fire bullets to random positions within the AOE circle
	for i in range(bullet_count):
		# Random point within circle using rejection sampling alternative
		var random_angle = randf() * TAU
		var random_dist = sqrt(randf()) * effective_radius  # sqrt for uniform distribution
		var offset = Vector2(cos(random_angle), sin(random_angle)) * random_dist
		var bullet_target = target_center + offset
		
		var projectile: Projectile
		if ProjectilePool:
			projectile = ProjectilePool.get_projectile()
		else:
			var projectile_scene = preload("res://scenes/effects/Projectile.tscn")
			projectile = projectile_scene.instantiate()
			get_tree().root.add_child(projectile)
		
		# Setup as flak projectile with destination-based behavior
		projectile.setup_flak(
			damage_per_bullet,
			from_position,
			bullet_target,
			projectile_speed,
			get_parent(),
			flak_mini_aoe  # Small AOE per bullet explosion
		)

func _fire_mortar_burst(target_center: Vector2, from_position: Vector2):
	"""Fire heavy mortar shells that spread across the AOE circle - fewer but bigger explosions"""
	# Use adjusted radius if set, otherwise use base aoe_radius
	var effective_radius = current_target_aoe_radius if current_target_aoe_radius > 0 else aoe_radius
	if effective_radius <= 0:
		effective_radius = 80.0  # Default fallback (larger than flak)
	
	# Calculate shell count
	var shell_count = mortar_bullet_count
	if shell_count <= 0:
		shell_count = int(effective_radius / 12.0)  # ~8 shells at radius 100
	
	# Damage per shell (total damage divided among shells)
	var damage_per_shell = damage / float(shell_count)
	
	# Fire shells to random positions within the AOE circle
	for i in range(shell_count):
		# Random point within circle using rejection sampling alternative
		var random_angle = randf() * TAU
		var random_dist = sqrt(randf()) * effective_radius  # sqrt for uniform distribution
		var offset = Vector2(cos(random_angle), sin(random_angle)) * random_dist
		var shell_target = target_center + offset
		
		var projectile: Projectile
		if ProjectilePool:
			projectile = ProjectilePool.get_projectile()
		else:
			var projectile_scene = preload("res://scenes/effects/Projectile.tscn")
			projectile = projectile_scene.instantiate()
			get_tree().root.add_child(projectile)
		
		# Setup as mortar projectile with destination-based behavior
		projectile.setup_mortar(
			damage_per_shell,
			from_position,
			shell_target,
			projectile_speed,
			get_parent(),
			mortar_mini_aoe  # Large AOE per shell explosion
		)

func _fire_torpedo_aoe(target_center: Vector2, from_position: Vector2):
	"""Fire a single torpedo to target center with adjustable AOE explosion"""
	# Use adjusted radius if set, otherwise use base aoe_radius
	var effective_radius = current_target_aoe_radius if current_target_aoe_radius > 0 else aoe_radius
	if effective_radius <= 0:
		effective_radius = 50.0  # Default fallback
	
	var projectile: Projectile
	if ProjectilePool:
		projectile = ProjectilePool.get_projectile()
	else:
		var projectile_scene = preload("res://scenes/effects/Projectile.tscn")
		projectile = projectile_scene.instantiate()
		get_tree().root.add_child(projectile)
	
	# Setup as torpedo projectile with destination-based behavior
	projectile.setup_torpedo(
		damage,
		from_position,
		target_center,
		projectile_speed,
		get_parent(),
		effective_radius  # Full AOE explosion radius
	)

func _fire_mine(target_center: Vector2, from_position: Vector2):
	"""Deploy a proximity mine to target center with adjustable AOE"""
	# Use adjusted radius if set, otherwise use base aoe_radius
	var effective_radius = current_target_aoe_radius if current_target_aoe_radius > 0 else aoe_radius
	if effective_radius <= 0:
		effective_radius = 50.0  # Default fallback
	
	var projectile: Projectile
	if ProjectilePool:
		projectile = ProjectilePool.get_projectile()
	else:
		var projectile_scene = preload("res://scenes/effects/Projectile.tscn")
		projectile = projectile_scene.instantiate()
		get_tree().root.add_child(projectile)
	
	# Setup as mine projectile with destination-based behavior and timer
	projectile.setup_mine(
		damage,
		from_position,
		target_center,
		projectile_speed,
		get_parent(),
		effective_radius,  # Proximity/explosion radius
		mine_timer  # Countdown timer
	)

func _fire_beam(target_pos: Vector2, from_position: Vector2, target: Node2D):
	"""Fire a beam weapon (ion cannon, particle beam, repair beam)"""
	# Tesla Coil uses separate method with raycasting
	if weapon_type == WeaponType.TESLA_COIL:
		_fire_tesla_coil(target_pos, from_position, target)
		return
	
	# Other beam weapons use a different system - they create a beam effect
	# and do instant or sustained damage
	if VfxDirector:
		var beam_color = _get_beam_color()
		VfxDirector.spawn_beam_effect(from_position, target_pos, beam_color, beam_width, 0.2)
	
	# Apply damage/effect at target
	if is_support:
		# Repair beam - heal friendly target
		if target and is_instance_valid(target) and target.has_method("heal"):
			target.heal(damage)
	else:
		# Damage beam - find targets along beam path
		_apply_beam_damage(from_position, target_pos, target)

func _fire_tesla_coil(target_pos: Vector2, from_position: Vector2, target: Node2D):
	"""Fire Tesla Coil with raycast hit detection and chain lightning"""
	print("Tesla Coil firing from ", from_position, " to ", target_pos)  # Debug
	
	var owner_unit = get_parent()
	var owner_team_id = owner_unit.team_id if owner_unit and "team_id" in owner_unit else 0
	
	# Raycast to find first enemy hit
	var hit_result = _tesla_raycast(from_position, target_pos, owner_team_id)
	var hit_pos = hit_result.position
	var hit_entity = hit_result.entity
	
	print("Tesla hit result: pos=", hit_pos, " entity=", hit_entity)  # Debug
	
	# Spawn main lightning bolt visual
	if VfxDirector:
		VfxDirector.spawn_tesla_lightning(from_position, hit_pos, beam_width, 0.3)
	else:
		push_warning("VfxDirector not found for Tesla lightning!")
	
	# Apply damage to hit target
	var current_damage = damage
	var hit_targets: Array[Node2D] = []
	
	if hit_entity and is_instance_valid(hit_entity):
		_apply_tesla_damage(hit_entity, current_damage, owner_unit)
		hit_targets.append(hit_entity)
		
		# Chain lightning to nearby enemies
		if chain_count > 0:
			_apply_chain_lightning(hit_entity, current_damage, owner_team_id, owner_unit, hit_targets)

func _tesla_raycast(from_pos: Vector2, to_pos: Vector2, owner_team_id: int) -> Dictionary:
	"""Cast ray to find first enemy in path, returns {position, entity}"""
	var result = {"position": to_pos, "entity": null}
	
	# Get physics space
	var space_state = get_parent().get_world_2d().direct_space_state if get_parent() else null
	if not space_state:
		return result
	
	# Create raycast query
	var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.collision_mask = 1 + 2  # Units and resources (layers 1-2)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	# Perform raycast
	var ray_result = space_state.intersect_ray(query)
	
	if ray_result and ray_result.collider:
		var collider = ray_result.collider
		# Check if it's an enemy (different team)
		if "team_id" in collider and collider.team_id != owner_team_id:
			result.position = ray_result.position
			result.entity = collider
	
	return result

func _apply_tesla_damage(target: Node2D, dmg: float, attacker: Node2D):
	"""Apply Tesla damage to a target"""
	if not target or not is_instance_valid(target):
		return
	
	if target.has_method("take_damage"):
		target.take_damage(dmg, attacker, target.global_position)
	
	# Apply special effect (chain/EMP)
	if special_effect != SpecialEffect.NONE and target.has_method("apply_status_effect"):
		target.apply_status_effect(special_effect, effect_duration, effect_strength)
	
	# Spawn damage number
	if FeedbackManager and FeedbackManager.has_method("spawn_damage_number"):
		var is_player = attacker and "team_id" in attacker and attacker.team_id == 0
		FeedbackManager.spawn_damage_number(target.global_position, dmg, is_player)

func _apply_chain_lightning(from_target: Node2D, base_damage: float, owner_team_id: int, attacker: Node2D, already_hit: Array[Node2D]):
	"""Chain lightning to nearby enemies with visual effect"""
	var current_target = from_target
	var current_damage = base_damage * chain_damage_falloff
	var remaining_chains = chain_count
	var chain_delay = 0.05  # Stagger timing for dramatic effect
	
	while remaining_chains > 0 and current_damage > 1.0:
		# Find next chain target
		var next_target = _find_chain_target(current_target, owner_team_id, already_hit)
		if not next_target:
			break
		
		# Spawn chain lightning visual with delay
		if VfxDirector:
			var from_pos = current_target.global_position
			var to_pos = next_target.global_position
			# Create a timer for staggered effect
			var timer = get_tree().create_timer(chain_delay * (chain_count - remaining_chains + 1))
			timer.timeout.connect(func(): 
				if VfxDirector and is_instance_valid(next_target):
					VfxDirector.spawn_tesla_lightning(from_pos, to_pos, beam_width * 0.7, 0.25)
			)
		
		# Apply damage with delay
		var delay_timer = get_tree().create_timer(chain_delay * (chain_count - remaining_chains + 1))
		var captured_target = next_target
		var captured_damage = current_damage
		var captured_attacker = attacker
		delay_timer.timeout.connect(func():
			if is_instance_valid(captured_target):
				_apply_tesla_damage(captured_target, captured_damage, captured_attacker)
		)
		
		already_hit.append(next_target)
		current_target = next_target
		current_damage *= chain_damage_falloff
		remaining_chains -= 1

func _find_chain_target(from_target: Node2D, owner_team_id: int, already_hit: Array[Node2D]) -> Node2D:
	"""Find nearest enemy for chain lightning within range"""
	if not from_target or not is_instance_valid(from_target):
		return null
	
	var nearest: Node2D = null
	var nearest_dist := chain_range
	
	# Get units in chain range
	if EntityManager:
		var units_in_range = EntityManager.get_units_in_radius(from_target.global_position, chain_range, -1)
		
		for unit in units_in_range:
			if unit == from_target:
				continue
			if unit in already_hit:
				continue
			# Check if enemy
			if "team_id" in unit and unit.team_id == owner_team_id:
				continue
			
			var dist = from_target.global_position.distance_to(unit.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = unit
	
	return nearest

func _apply_beam_damage(from_pos: Vector2, to_pos: Vector2, primary_target: Node2D):
	"""Apply damage along beam path"""
	# For simplicity, just damage the primary target
	# Could be expanded to do line-trace damage
	if primary_target and is_instance_valid(primary_target):
		if primary_target.has_method("take_damage"):
			var attacker = get_parent() if is_instance_valid(get_parent()) else null
			primary_target.take_damage(damage, attacker, to_pos)
			
			# Apply special effect
			if special_effect != SpecialEffect.NONE and primary_target.has_method("apply_status_effect"):
				primary_target.apply_status_effect(special_effect, effect_duration, effect_strength)
			
			# Spawn damage number
			if FeedbackManager and FeedbackManager.has_method("spawn_damage_number"):
				var owner = get_parent()
				var is_player = owner and "team_id" in owner and owner.team_id == 0
				FeedbackManager.spawn_damage_number(to_pos, damage, is_player)

func _get_beam_color() -> Color:
	"""Get beam color based on weapon type"""
	match weapon_type:
		WeaponType.ION_CANNON:
			return Color(0.3, 0.6, 1.0, 1.0)  # Blue
		WeaponType.PARTICLE_BEAM:
			return Color(0.8, 0.3, 1.0, 1.0)  # Purple
		WeaponType.REPAIR_BEAM:
			return Color(0.3, 1.0, 0.3, 1.0)  # Green
		WeaponType.CRYO_CANNON:
			return Color(0.6, 0.9, 1.0, 1.0)  # Light blue
		_:
			return Color(1.0, 0.3, 0.3, 1.0)  # Red default

# Static helper to configure weapon from type
static func configure_from_type(weapon: WeaponComponent, wep_type: WeaponType, level_data: Dictionary):
	"""Configure a weapon component from type and level data"""
	weapon.weapon_type = wep_type
	weapon.damage = level_data.get("damage", 10.0)
	weapon.fire_rate = level_data.get("fire_rate", 1.0)
	weapon.rangeAim = level_data.get("range", 300.0)
	weapon.projectile_speed = level_data.get("projectile_speed", 500.0)
	weapon.homing = level_data.get("homing", false)
	weapon.aoe_radius = level_data.get("aoe_radius", 0.0)
	weapon.aoe_type = level_data.get("aoe_type", AOEType.NONE)
	weapon.cone_angle = level_data.get("cone_angle", 45.0)
	weapon.special_effect = level_data.get("special_effect", SpecialEffect.NONE)
	weapon.effect_duration = level_data.get("effect_duration", 0.0)
	weapon.effect_strength = level_data.get("effect_strength", 0.0)
	weapon.projectile_count = level_data.get("projectile_count", 1)
	weapon.spread_angle = level_data.get("spread_angle", 0.0)
	weapon.is_beam = level_data.get("is_beam", false)
	weapon.beam_width = level_data.get("beam_width", 4.0)
	weapon.is_support = level_data.get("is_support", false)
	weapon.chain_count = level_data.get("chain_count", 0)
	weapon.chain_range = level_data.get("chain_range", 100.0)
	weapon.chain_damage_falloff = level_data.get("chain_damage_falloff", 0.7)
	# Flak cannon properties
	weapon.flak_bullet_count = level_data.get("flak_bullet_count", 25)
	weapon.flak_mini_aoe = level_data.get("flak_mini_aoe", 22.0)
	# Mine layer properties
	weapon.mine_timer = level_data.get("mine_timer", 30.0)
	# Mortar properties
	weapon.mortar_bullet_count = level_data.get("mortar_bullet_count", 8)
	weapon.mortar_mini_aoe = level_data.get("mortar_mini_aoe", 40.0)
