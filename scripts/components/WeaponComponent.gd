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

var cooldown_timer: float = 0.0

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
	
	# Handle different weapon firing modes
	if is_beam:
		_fire_beam(target.global_position if target else from_position + Vector2(100, 0), from_position, target)
	elif projectile_count > 1:
		_fire_spread(target.global_position if target else Vector2.ZERO, from_position, target)
	else:
		_fire_single_projectile(target.global_position if target else Vector2.ZERO, from_position, target if homing else null)

func fire_at_position(target_pos: Vector2, from_position: Vector2):
	if not can_fire():
		return

	cooldown_timer = 1.0 / fire_rate

	if AudioManager:
		AudioManager.play_weapon_sound(from_position)

	# Handle different weapon firing modes
	if is_beam:
		_fire_beam(target_pos, from_position, null)
	elif projectile_count > 1:
		_fire_spread(target_pos, from_position, null)
	else:
		_fire_single_projectile(target_pos, from_position, null)

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

func _fire_beam(target_pos: Vector2, from_position: Vector2, target: Node2D):
	"""Fire a beam weapon (ion cannon, particle beam, repair beam, tesla coil)"""
	# Beam weapons use a different system - they create a beam effect
	# and do instant or sustained damage
	if VfxDirector:
		# Tesla Coil uses special shader-based beam
		if weapon_type == WeaponType.TESLA_COIL:
			VfxDirector.spawn_tesla_beam(from_position, target_pos, beam_width, 0.5)
		else:
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
