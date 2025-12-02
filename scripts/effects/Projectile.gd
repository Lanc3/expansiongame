extends Area2D
class_name Projectile
## Projectile with optional homing capability and support for 21 weapon types

var damage: float
var speed: float
var direction: Vector2
var lifetime: float = 3.0
var age: float = 0.0
var weapon_type: int
var homing_target: Node2D = null
var owner_unit: Node2D = null
var owner_team_id: int = 0
var owner_zone_id: String = ""  # Zone where projectile was fired

# Extended weapon properties
var aoe_radius: float = 0.0
var aoe_type: int = 0  # AOEType enum from WeaponComponent
var special_effect: int = 0  # SpecialEffect enum from WeaponComponent
var effect_duration: float = 0.0
var effect_strength: float = 0.0
var chain_count: int = 0
var chain_range: float = 100.0
var chain_damage_falloff: float = 0.7
var already_hit: Array[Node2D] = []  # For pierce/chain tracking

# Flak projectile properties
var is_flak_projectile: bool = false
var target_destination: Vector2 = Vector2.ZERO  # Where flak/torpedo/mine aims to explode
var flak_mini_aoe: float = 22.0  # Small explosion radius for flak bullets

# Torpedo projectile properties
var is_torpedo_projectile: bool = false
var torpedo_aoe_radius: float = 50.0  # Full explosion radius for torpedo

# Mine projectile properties
var is_mine_projectile: bool = false
var mine_armed: bool = false  # True when mine has reached destination and is waiting
var mine_timer: float = 30.0  # Countdown timer (30 seconds default)
var mine_max_timer: float = 30.0  # Store initial value for urgency calculation
var mine_proximity_radius: float = 50.0  # Same as explosion radius
var mine_timer_label: Label = null  # Floating timer display

# Mortar projectile properties
var is_mortar_projectile: bool = false
var mortar_mini_aoe: float = 40.0  # Large explosion radius for mortar shells

@onready var sprite: Sprite2D = $Sprite2D

var trail_effect: Line2D = null
var trail_points: Array[Vector2] = []
const MAX_TRAIL_POINTS: int = 8

# Weapon type enum values (must match WeaponComponent.WeaponType)
const WT_LASER = 0
const WT_MISSILE = 1
const WT_AUTOCANNON = 2
const WT_RAILGUN = 3
const WT_GATLING = 4
const WT_SNIPER = 5
const WT_SHOTGUN = 6
const WT_ION_CANNON = 7
const WT_PLASMA_CANNON = 8
const WT_PARTICLE_BEAM = 9
const WT_TESLA_COIL = 10
const WT_DISRUPTOR = 11
const WT_FLAK_CANNON = 12
const WT_TORPEDO = 13
const WT_ROCKET_POD = 14
const WT_MORTAR = 15
const WT_MINE_LAYER = 16
const WT_CRYO_CANNON = 17
const WT_EMP_BURST = 18
const WT_GRAVITY_WELL = 19
const WT_REPAIR_BEAM = 20

# Special effect enum values (must match WeaponComponent.SpecialEffect)
const SE_NONE = 0
const SE_EMP = 1
const SE_SLOW = 2
const SE_PIERCE = 3
const SE_SHIELD_BYPASS = 4
const SE_CHAIN = 5
const SE_DOT = 6
const SE_PULL = 7
const SE_HEAL = 8

# AOE type enum values
const AOE_NONE = 0
const AOE_CIRCLE = 1
const AOE_CONE = 2
const AOE_LINE = 3
const AOE_RING = 4

# Color definitions for each weapon type
const WEAPON_COLORS = {
	WT_LASER: Color(1.0, 0.3, 0.3, 1.0),        # Red
	WT_MISSILE: Color(1.0, 0.7, 0.2, 1.0),      # Orange
	WT_AUTOCANNON: Color(0.9, 0.8, 0.4, 1.0),   # Brass/Yellow
	WT_RAILGUN: Color(0.3, 0.5, 1.0, 1.0),      # Blue streak
	WT_GATLING: Color(1.0, 1.0, 0.9, 1.0),      # White tracer
	WT_SNIPER: Color(0.3, 1.0, 0.3, 1.0),       # Green tracer
	WT_SHOTGUN: Color(1.0, 0.9, 0.5, 1.0),      # Light brass
	WT_ION_CANNON: Color(0.3, 0.6, 1.0, 1.0),   # Blue
	WT_PLASMA_CANNON: Color(0.3, 1.0, 0.4, 1.0),# Green
	WT_PARTICLE_BEAM: Color(0.8, 0.3, 1.0, 1.0),# Purple
	WT_TESLA_COIL: Color(0.4, 0.8, 1.0, 1.0),   # Electric blue
	WT_DISRUPTOR: Color(1.0, 0.4, 0.8, 1.0),    # Pink
	WT_FLAK_CANNON: Color(1.0, 0.5, 0.2, 1.0),  # Dark orange
	WT_TORPEDO: Color(0.7, 0.9, 1.0, 1.0),      # Light blue
	WT_ROCKET_POD: Color(1.0, 0.6, 0.3, 1.0),   # Light orange
	WT_MORTAR: Color(0.6, 0.5, 0.4, 1.0),       # Brown
	WT_MINE_LAYER: Color(0.8, 0.2, 0.2, 1.0),   # Dark red
	WT_CRYO_CANNON: Color(0.6, 0.9, 1.0, 1.0),  # Light blue
	WT_EMP_BURST: Color(0.5, 0.3, 1.0, 1.0),    # Electric purple
	WT_GRAVITY_WELL: Color(0.4, 0.0, 0.6, 1.0), # Dark purple
	WT_REPAIR_BEAM: Color(0.3, 1.0, 0.3, 1.0)   # Green
}

# Scale definitions for each weapon type
const WEAPON_SCALES = {
	WT_LASER: Vector2(0.8, 0.8),
	WT_MISSILE: Vector2(0.05, 0.05),
	WT_AUTOCANNON: Vector2(0.6, 0.6),
	WT_RAILGUN: Vector2(1.2, 0.4),
	WT_GATLING: Vector2(0.4, 0.4),
	WT_SNIPER: Vector2(1.0, 0.3),
	WT_SHOTGUN: Vector2(0.5, 0.5),
	WT_ION_CANNON: Vector2(0.7, 0.7),
	WT_PLASMA_CANNON: Vector2(1.0, 1.0),
	WT_PARTICLE_BEAM: Vector2(0.6, 0.6),
	WT_TESLA_COIL: Vector2(0.5, 0.5),
	WT_DISRUPTOR: Vector2(0.7, 0.7),
	WT_FLAK_CANNON: Vector2(0.3, 1.2),  # Thin, elongated tracer
	WT_TORPEDO: Vector2(0.08, 0.08),
	WT_ROCKET_POD: Vector2(0.04, 0.04),
	WT_MORTAR: Vector2(0.9, 0.9),
	WT_MINE_LAYER: Vector2(0.6, 0.6),
	WT_CRYO_CANNON: Vector2(0.7, 0.7),
	WT_EMP_BURST: Vector2(0.8, 0.8),
	WT_GRAVITY_WELL: Vector2(1.0, 1.0),
	WT_REPAIR_BEAM: Vector2(0.6, 0.6)
}

# Original setup for backward compatibility
func setup(wep_type: int, dmg: float, start_pos: Vector2, target_pos: Vector2, spd: float, homing: Node2D = null, owner: Node2D = null):
	setup_extended(wep_type, dmg, start_pos, target_pos, spd, homing, owner, 0.0, 0, 0, 0.0, 0.0, 0, 100.0, 0.7)

# Extended setup with all weapon properties
func setup_extended(wep_type: int, dmg: float, start_pos: Vector2, target_pos: Vector2, spd: float, 
		homing: Node2D, owner: Node2D, aoe_rad: float, aoe_t: int, spec_effect: int, 
		eff_duration: float, eff_strength: float, chain_cnt: int, chain_rng: float, chain_falloff: float):
	global_position = start_pos
	damage = dmg
	speed = spd
	direction = (target_pos - start_pos).normalized()
	rotation = direction.angle()
	weapon_type = wep_type
	homing_target = homing
	owner_unit = owner
	
	# Extended properties
	aoe_radius = aoe_rad
	aoe_type = aoe_t
	special_effect = spec_effect
	effect_duration = eff_duration
	effect_strength = eff_strength
	chain_count = chain_cnt
	chain_range = chain_rng
	chain_damage_falloff = chain_falloff
	already_hit.clear()
	
	# Store owner's team_id for friendly fire prevention
	if owner and "team_id" in owner:
		owner_team_id = owner.team_id
	
	# Store zone for visibility filtering
	if ZoneManager:
		if owner and ZoneManager.has_method("get_unit_zone"):
			owner_zone_id = ZoneManager.get_unit_zone(owner)
		else:
			owner_zone_id = ZoneManager.current_zone_id
	
	# Set z_index early to ensure proper rendering order
	z_index = 10
	z_as_relative = false
	
	# Set visual based on weapon type
	_apply_weapon_visuals()

func setup_flak(dmg: float, start_pos: Vector2, destination: Vector2, spd: float, owner: Node2D, mini_aoe: float):
	"""Setup specifically for flak cannon bullets - destination-based with small AOE"""
	global_position = start_pos
	damage = dmg
	speed = spd
	direction = (destination - start_pos).normalized()
	rotation = direction.angle()
	weapon_type = WT_FLAK_CANNON
	homing_target = null
	owner_unit = owner
	
	# Flak-specific properties
	is_flak_projectile = true
	target_destination = destination
	flak_mini_aoe = mini_aoe
	aoe_radius = mini_aoe  # Small AOE per bullet
	aoe_type = AOE_CIRCLE
	
	# Reset other properties
	special_effect = SE_NONE
	effect_duration = 0.0
	effect_strength = 0.0
	chain_count = 0
	already_hit.clear()
	
	# Store owner's team_id for friendly fire prevention
	if owner and "team_id" in owner:
		owner_team_id = owner.team_id
	
	# Store zone for visibility filtering
	if ZoneManager:
		if owner and ZoneManager.has_method("get_unit_zone"):
			owner_zone_id = ZoneManager.get_unit_zone(owner)
		else:
			owner_zone_id = ZoneManager.current_zone_id
	
	# Set z_index early to ensure proper rendering order
	z_index = 10
	z_as_relative = false
	
	# Set visual based on weapon type
	_apply_weapon_visuals()

func setup_torpedo(dmg: float, start_pos: Vector2, destination: Vector2, spd: float, owner: Node2D, full_aoe_radius: float):
	"""Setup specifically for torpedo - destination-based with full AOE explosion"""
	global_position = start_pos
	damage = dmg
	speed = spd
	direction = (destination - start_pos).normalized()
	rotation = direction.angle()
	weapon_type = WT_TORPEDO
	homing_target = null
	owner_unit = owner
	
	# Torpedo-specific properties
	is_torpedo_projectile = true
	target_destination = destination
	torpedo_aoe_radius = full_aoe_radius
	aoe_radius = full_aoe_radius  # Full AOE explosion
	aoe_type = AOE_CIRCLE
	
	# Reset other properties
	special_effect = SE_NONE
	effect_duration = 0.0
	effect_strength = 0.0
	chain_count = 0
	already_hit.clear()
	
	# Store owner's team_id for friendly fire prevention
	if owner and "team_id" in owner:
		owner_team_id = owner.team_id
	
	# Store zone for visibility filtering
	if ZoneManager:
		if owner and ZoneManager.has_method("get_unit_zone"):
			owner_zone_id = ZoneManager.get_unit_zone(owner)
		else:
			owner_zone_id = ZoneManager.current_zone_id
	
	# Set z_index early to ensure proper rendering order
	z_index = 10
	z_as_relative = false
	
	# Set visual based on weapon type
	_apply_weapon_visuals()

func setup_mine(dmg: float, start_pos: Vector2, destination: Vector2, spd: float, owner: Node2D, proximity_radius: float, timer_duration: float = 30.0):
	"""Setup specifically for proximity mine - travels to destination, then waits for enemies"""
	global_position = start_pos
	damage = dmg
	speed = spd
	direction = (destination - start_pos).normalized()
	rotation = direction.angle()
	weapon_type = WT_MINE_LAYER
	homing_target = null
	owner_unit = owner
	
	# Mine-specific properties
	is_mine_projectile = true
	mine_armed = false  # Not armed until reaching destination
	mine_timer = timer_duration
	mine_max_timer = timer_duration
	mine_proximity_radius = proximity_radius
	target_destination = destination
	aoe_radius = proximity_radius  # Explosion radius matches proximity
	aoe_type = AOE_CIRCLE
	
	# Longer lifetime for mines (timer + travel time)
	lifetime = timer_duration + 60.0  # Extra time for travel
	
	# Reset other properties
	special_effect = SE_NONE
	effect_duration = 0.0
	effect_strength = 0.0
	chain_count = 0
	already_hit.clear()
	
	# Store owner's team_id for friendly fire prevention
	if owner and "team_id" in owner:
		owner_team_id = owner.team_id
	
	# Store zone for visibility filtering
	if ZoneManager:
		if owner and ZoneManager.has_method("get_unit_zone"):
			owner_zone_id = ZoneManager.get_unit_zone(owner)
		else:
			owner_zone_id = ZoneManager.current_zone_id
	
	# Set z_index early to ensure proper rendering order
	z_index = 10
	z_as_relative = false
	
	# Set visual based on weapon type
	_apply_weapon_visuals()
	
	# Create timer label for mine countdown
	_create_mine_timer_label()

func setup_mortar(dmg: float, start_pos: Vector2, destination: Vector2, spd: float, owner: Node2D, mini_aoe: float):
	"""Setup specifically for mortar shells - destination-based with large AOE explosion"""
	global_position = start_pos
	damage = dmg
	speed = spd
	direction = (destination - start_pos).normalized()
	rotation = direction.angle()
	weapon_type = WT_MORTAR
	homing_target = null
	owner_unit = owner
	
	# Mortar-specific properties
	is_mortar_projectile = true
	target_destination = destination
	mortar_mini_aoe = mini_aoe
	aoe_radius = mini_aoe  # Large AOE per shell
	aoe_type = AOE_CIRCLE
	
	# Reset other properties
	special_effect = SE_NONE
	effect_duration = 0.0
	effect_strength = 0.0
	chain_count = 0
	already_hit.clear()
	
	# Store owner's team_id for friendly fire prevention
	if owner and "team_id" in owner:
		owner_team_id = owner.team_id
	
	# Store zone for visibility filtering
	if ZoneManager:
		if owner and ZoneManager.has_method("get_unit_zone"):
			owner_zone_id = ZoneManager.get_unit_zone(owner)
		else:
			owner_zone_id = ZoneManager.current_zone_id
	
	# Set z_index early to ensure proper rendering order
	z_index = 10
	z_as_relative = false
	
	# Set visual based on weapon type
	_apply_weapon_visuals()

func _create_mine_timer_label():
	"""Create floating label to show mine countdown timer"""
	if mine_timer_label:
		return  # Already exists
	
	mine_timer_label = Label.new()
	mine_timer_label.name = "MineTimerLabel"
	mine_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mine_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mine_timer_label.add_theme_font_size_override("font_size", 14)
	mine_timer_label.add_theme_color_override("font_color", Color.WHITE)
	mine_timer_label.add_theme_color_override("font_outline_color", Color.BLACK)
	mine_timer_label.add_theme_constant_override("outline_size", 3)
	mine_timer_label.position = Vector2(-20, -40)  # Above the mine
	mine_timer_label.size = Vector2(40, 20)
	mine_timer_label.visible = false  # Hidden until armed
	add_child(mine_timer_label)

func _apply_weapon_visuals():
	"""Apply color, scale, and shaders based on weapon type"""
	var color = WEAPON_COLORS.get(weapon_type, Color(1.0, 0.3, 0.3, 1.0))
	var scale_val = WEAPON_SCALES.get(weapon_type, Vector2(0.8, 0.8))
	var color_end = Color(color.r, color.g, color.b, 0.0)
	
	if sprite:
		# Check if this weapon type uses a special shader
		var shader_path = _get_shader_for_weapon_type(weapon_type)
		
		if shader_path != "":
			# Use shader-based visual
			_apply_shader_visual(shader_path, color, scale_val)
		else:
			# Use standard texture-based visual
			if ProjectilePool:
				var texture = ProjectilePool.get_texture_for_type(weapon_type)
				sprite.texture = texture
			
			sprite.material = null  # Clear any previous shader
			sprite.modulate = color
			sprite.scale = scale_val
			
			# Set z_index for all projectiles to appear above turrets (z_index 5)
			# Set on both root node and sprite for maximum compatibility
			z_index = 10  # Root node z_index
			sprite.z_index = 10  # Sprite z_index (above ship components z_index 0 and turrets z_index 5)
			z_as_relative = false  # Use absolute z_index for proper rendering across different parent hierarchies
	
	# Setup trail effect (skip for shader-based projectiles that handle their own trails)
	if VfxDirector and weapon_type not in [WT_TESLA_COIL, WT_ION_CANNON, WT_PARTICLE_BEAM, WT_CRYO_CANNON, WT_EMP_BURST, WT_GRAVITY_WELL, WT_REPAIR_BEAM]:
		if trail_effect and is_instance_valid(trail_effect):
			VfxDirector.recycle(trail_effect)
		trail_effect = VfxDirector.spawn_trail(self, color, color_end, PackedVector2Array())

func _get_shader_for_weapon_type(wtype: int) -> String:
	"""Get shader path for weapon types that use special visuals"""
	match wtype:
		WT_TESLA_COIL:
			return "res://shaders/projectile_lightning.gdshader"
		WT_PLASMA_CANNON:
			return "res://shaders/projectile_plasma.gdshader"
		WT_ION_CANNON:
			return "res://shaders/projectile_ion_ball.gdshader"
		WT_CRYO_CANNON:
			return "res://shaders/projectile_cryo.gdshader"
		WT_EMP_BURST:
			return "res://shaders/projectile_emp.gdshader"
		WT_PARTICLE_BEAM:
			return "res://shaders/projectile_particle_beam.gdshader"
		WT_GRAVITY_WELL:
			return "res://shaders/projectile_gravity_well.gdshader"
		WT_REPAIR_BEAM:
			return "res://shaders/projectile_repair_beam.gdshader"
		WT_RAILGUN:
			return "res://shaders/projectile_railgun.gdshader"
		WT_FLAK_CANNON:
			return "res://shaders/projectile_flak.gdshader"
		WT_TORPEDO:
			return "res://shaders/projectile_torpedo.gdshader"
		WT_MINE_LAYER:
			return "res://shaders/projectile_mine.gdshader"
		WT_MORTAR:
			return "res://shaders/projectile_mine.gdshader"  # Reuse mine visual for mortar
		_:
			return ""

func _apply_shader_visual(shader_path: String, color: Color, scale_val: Vector2):
	"""Apply a shader-based visual to the projectile sprite"""
	if not sprite:
		return
	
	# Load and apply shader
	var shader = load(shader_path) as Shader
	if not shader:
		push_warning("Failed to load projectile shader: " + shader_path)
		return
	
	var mat = ShaderMaterial.new()
	mat.shader = shader
	
	# Set common shader parameters based on weapon type
	match weapon_type:
		WT_TESLA_COIL:
			mat.set_shader_parameter("lightning_color", color)
			mat.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
			mat.set_shader_parameter("speed", 25.0)
			mat.set_shader_parameter("cycle", 10.0)
			scale_val = Vector2(1.5, 3.0)  # Elongated for lightning bolt
		
		WT_PLASMA_CANNON:
			mat.set_shader_parameter("plasma_color", color)
			mat.set_shader_parameter("core_color", Color(1.0, 1.0, 0.9, 1.0))
			mat.set_shader_parameter("pulse_speed", 10.0)
			scale_val = Vector2(2.0, 2.0)  # Bigger blob
		
		WT_ION_CANNON:
			# Electric ball shader with noise textures
			var noise_textures = _get_or_create_noise_textures()
			mat.set_shader_parameter("noise", noise_textures[0])
			mat.set_shader_parameter("noise2", noise_textures[1])
			mat.set_shader_parameter("brightness", 2.5)
			mat.set_shader_parameter("time_scale", 1.0)
			scale_val = Vector2(0.75, 0.75)  # Circular ball shape (30% of original size)
		
		WT_CRYO_CANNON:
			mat.set_shader_parameter("ice_color", color)
			mat.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
			mat.set_shader_parameter("shimmer_speed", 5.0)
			scale_val = Vector2(1.2, 2.5)  # Beam shape
		
		WT_EMP_BURST:
			mat.set_shader_parameter("emp_color", color)
			mat.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
			mat.set_shader_parameter("expansion_speed", 2.5)
			scale_val = Vector2(3.0, 3.0)  # Expanding ring
		
		WT_PARTICLE_BEAM:
			mat.set_shader_parameter("beam_color", color)
			mat.set_shader_parameter("core_color", Color(1.0, 0.9, 1.0, 1.0))
			mat.set_shader_parameter("particle_speed", 12.0)
			scale_val = Vector2(1.0, 3.0)  # Long beam
		
		WT_GRAVITY_WELL:
			mat.set_shader_parameter("void_color", Color(0.05, 0.0, 0.1, 1.0))
			mat.set_shader_parameter("edge_color", color)
			mat.set_shader_parameter("swirl_speed", 4.0)
			scale_val = Vector2(4.0, 4.0)  # Large vortex
		
		WT_REPAIR_BEAM:
			mat.set_shader_parameter("heal_color", color)
			mat.set_shader_parameter("sparkle_color", Color(1.0, 1.0, 0.9, 1.0))
			mat.set_shader_parameter("sparkle_speed", 10.0)
			scale_val = Vector2(1.0, 2.5)  # Healing beam
		
		WT_RAILGUN:
			mat.set_shader_parameter("trail_color", color)
			mat.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
			mat.set_shader_parameter("streak_speed", 35.0)
			scale_val = Vector2(1.5, 4.0)  # Long streak
		
		WT_FLAK_CANNON:
			# Yellow-hot glowing tracer
			mat.set_shader_parameter("core_color", Color(1.0, 1.0, 0.9, 1.0))  # White-hot
			mat.set_shader_parameter("hot_color", Color(1.0, 0.9, 0.3, 1.0))   # Yellow
			mat.set_shader_parameter("glow_color", Color(1.0, 0.5, 0.1, 1.0))  # Orange
			mat.set_shader_parameter("elongation", 4.0)
			mat.set_shader_parameter("core_size", 0.08)
			mat.set_shader_parameter("glow_falloff", 0.35)
			mat.set_shader_parameter("shimmer_speed", 15.0)
			scale_val = Vector2(0.5, 1.5)  # Thin, elongated tracer
		
		WT_TORPEDO:
			# Heavy torpedo with blue exhaust trail
			mat.set_shader_parameter("body_color", Color(0.4, 0.5, 0.6, 1.0))      # Dark metallic
			mat.set_shader_parameter("engine_color", Color(0.5, 0.8, 1.0, 1.0))   # Blue-white
			mat.set_shader_parameter("exhaust_color", Color(0.3, 0.6, 1.0, 1.0))  # Blue trail
			mat.set_shader_parameter("glow_color", Color(0.4, 0.7, 1.0, 0.6))     # Ambient glow
			mat.set_shader_parameter("body_length", 0.25)
			mat.set_shader_parameter("body_width", 0.08)
			mat.set_shader_parameter("trail_length", 0.5)
			mat.set_shader_parameter("glow_intensity", 1.5)
			mat.set_shader_parameter("pulse_speed", 4.0)
			scale_val = Vector2(1.5, 2.5)  # Large torpedo
		
		WT_MINE_LAYER:
			# Proximity mine with pulsing red core
			mat.set_shader_parameter("core_color", Color(0.9, 0.2, 0.1, 1.0))     # Red core
			mat.set_shader_parameter("shell_color", Color(0.3, 0.3, 0.35, 1.0))  # Dark shell
			mat.set_shader_parameter("ring_color", Color(0.8, 0.2, 0.2, 0.4))    # Proximity ring
			mat.set_shader_parameter("warning_color", Color(1.0, 0.3, 0.1, 1.0)) # Warning blink
			mat.set_shader_parameter("core_size", 0.12)
			mat.set_shader_parameter("shell_size", 0.22)
			mat.set_shader_parameter("ring_radius", 0.4)
			mat.set_shader_parameter("ring_thickness", 0.03)
			mat.set_shader_parameter("pulse_speed", 3.0)
			mat.set_shader_parameter("armed", 0.0 if not is_mine_projectile or not mine_armed else 1.0)
			mat.set_shader_parameter("urgency", 0.0)
			scale_val = Vector2(2.0, 2.0)  # Medium size mine
		
		WT_MORTAR:
			# Mortar shell - brown/orange colors, larger, always "armed" look
			mat.set_shader_parameter("core_color", Color(1.0, 0.6, 0.2, 1.0))     # Orange core
			mat.set_shader_parameter("shell_color", Color(0.5, 0.4, 0.3, 1.0))   # Brown shell
			mat.set_shader_parameter("ring_color", Color(1.0, 0.5, 0.2, 0.3))    # Orange ring (subtle)
			mat.set_shader_parameter("warning_color", Color(1.0, 0.7, 0.3, 1.0)) # Yellow-orange
			mat.set_shader_parameter("core_size", 0.15)
			mat.set_shader_parameter("shell_size", 0.25)
			mat.set_shader_parameter("ring_radius", 0.35)
			mat.set_shader_parameter("ring_thickness", 0.02)
			mat.set_shader_parameter("pulse_speed", 2.0)
			mat.set_shader_parameter("armed", 1.0)  # Always looks armed
			mat.set_shader_parameter("urgency", 0.3)  # Slight urgency for visual interest
			scale_val = Vector2(2.5, 2.5)  # Larger than mine
	
	sprite.material = mat
	sprite.modulate = Color.WHITE  # Let shader handle colors
	sprite.scale = scale_val
	
	# Set z_index for all projectiles to appear above turrets (z_index 5)
	# Set on both root node and sprite for maximum compatibility
	z_index = 10  # Root node z_index
	sprite.z_index = 10  # Sprite z_index (above ship components z_index 0 and turrets z_index 5)
	z_as_relative = false  # Use absolute z_index for proper rendering across different parent hierarchies
	
	# Always use the shader base texture for shader-based projectiles
	# This ensures consistent rendering regardless of what texture was previously set
	sprite.texture = _create_shader_base_texture()

# Cache for shader base texture
static var _shader_base_texture: ImageTexture = null

# Cache for noise textures (used by ion ball shader)
static var _noise_texture_1: NoiseTexture2D = null
static var _noise_texture_2: NoiseTexture2D = null

func _create_shader_base_texture() -> ImageTexture:
	"""Create a simple white texture for shaders to use as a base"""
	if _shader_base_texture:
		return _shader_base_texture
	
	# Create a 64x64 white image
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	
	_shader_base_texture = ImageTexture.create_from_image(img)
	return _shader_base_texture

func _get_or_create_noise_textures() -> Array:
	"""Create and cache noise textures for energy ball shaders"""
	if not _noise_texture_1:
		var noise1 = FastNoiseLite.new()
		noise1.noise_type = FastNoiseLite.TYPE_SIMPLEX
		noise1.frequency = 0.05
		_noise_texture_1 = NoiseTexture2D.new()
		_noise_texture_1.noise = noise1
		_noise_texture_1.seamless = true
		_noise_texture_1.width = 128
		_noise_texture_1.height = 128
		
		var noise2 = FastNoiseLite.new()
		noise2.noise_type = FastNoiseLite.TYPE_CELLULAR
		noise2.frequency = 0.08
		_noise_texture_2 = NoiseTexture2D.new()
		_noise_texture_2.noise = noise2
		_noise_texture_2.seamless = true
		_noise_texture_2.width = 128
		_noise_texture_2.height = 128
	
	return [_noise_texture_1, _noise_texture_2]

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	EntityManager.register_projectile(self)
	
	# Set to pausable so projectiles respect game pause
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# Set z_index on the root node to appear above turrets (z_index 5)
	# Since projectiles are in ProjectilePool and turrets are in VisualContainer,
	# we need a high z_index to ensure proper rendering order
	z_index = 10
	
	# Setup collision
	collision_layer = 16  # Layer 5 (Projectiles)
	collision_mask = 1 + 2  # Layers 1-2 (Units, Resources)

func _exit_tree():
	EntityManager.unregister_projectile(self)

func _process(delta: float):
	# Check if projectile is in current zone
	if ZoneManager and not owner_zone_id.is_empty():
		if owner_zone_id != ZoneManager.current_zone_id:
			visible = false
			return
		else:
			visible = true
	
	# Mine processing (handles armed state, timer, proximity)
	if is_mine_projectile:
		_process_mine(delta)
		return  # Mine handles its own movement
	
	# Homing behavior (for missiles, non-AOE torpedoes)
	if homing_target and is_instance_valid(homing_target) and not is_torpedo_projectile:
		var target_direction = (homing_target.global_position - global_position).normalized()
		var turn_speed = 2.0
		# Torpedoes turn slower
		if weapon_type == WT_TORPEDO:
			turn_speed = 1.0
		direction = direction.lerp(target_direction, turn_speed * delta)
		rotation = direction.angle()
	
	# Move
	global_position += direction * speed * delta
	
	# Torpedo projectile destination check - explode when reaching target
	if is_torpedo_projectile and target_destination != Vector2.ZERO:
		var dist_to_dest = global_position.distance_to(target_destination)
		if dist_to_dest < speed * delta * 1.5:  # Close enough to destination
			_explode_torpedo()
			return
	
	# Flak projectile destination check - explode when reaching target
	if is_flak_projectile and target_destination != Vector2.ZERO:
		var dist_to_dest = global_position.distance_to(target_destination)
		if dist_to_dest < speed * delta * 1.5:  # Close enough to destination
			_explode_flak()
			return
	
	# Mortar projectile destination check - explode when reaching target
	if is_mortar_projectile and target_destination != Vector2.ZERO:
		var dist_to_dest = global_position.distance_to(target_destination)
		if dist_to_dest < speed * delta * 1.5:  # Close enough to destination
			_explode_mortar()
			return
	
	# Trail effect
	if trail_effect and is_instance_valid(trail_effect):
		trail_points.append(global_position)
		var max_points := MAX_TRAIL_POINTS
		var budget = RenderingServer.global_shader_parameter_get("vfx_trail_point_budget")
		if typeof(budget) in [TYPE_FLOAT, TYPE_INT]:
			max_points = clamp(int(budget / 500), 4, MAX_TRAIL_POINTS)
		if trail_points.size() > max_points:
			trail_points.pop_front()
		var local_points := PackedVector2Array()
		for point in trail_points:
			local_points.append((point - global_position).rotated(-rotation))
		trail_effect.points = local_points
	
	# Lifetime
	age += delta
	if age >= lifetime:
		_on_lifetime_expired()

func _process_mine(delta: float):
	"""Process mine behavior - travel, arm, proximity detect, countdown"""
	if not mine_armed:
		# Still traveling to destination
		global_position += direction * speed * delta
		
		# Check if reached destination
		var dist_to_dest = global_position.distance_to(target_destination)
		if dist_to_dest < speed * delta * 1.5:
			# Arrived at destination - arm the mine
			global_position = target_destination
			mine_armed = true
			speed = 0.0  # Stop moving
			
			# Update shader to show armed state
			_update_mine_shader_state()
			
			# Show timer label
			if mine_timer_label:
				mine_timer_label.visible = true
			
			# Play arming sound if available
			if AudioManager:
				AudioManager.play_weapon_sound(global_position)
	else:
		# Mine is armed - check proximity and countdown
		
		# Update timer
		mine_timer -= delta
		
		# Update timer label
		_update_mine_timer_label()
		
		# Update shader urgency based on remaining time
		_update_mine_shader_state()
		
		# Check for timer expiration
		if mine_timer <= 0:
			_explode_mine()
			return
		
		# Check for enemies in proximity
		if _check_mine_proximity():
			_explode_mine()
			return

func _update_mine_timer_label():
	"""Update the mine's floating timer label"""
	if not mine_timer_label:
		return
	
	# Format time as integer seconds
	var seconds_left = int(ceil(mine_timer))
	mine_timer_label.text = str(seconds_left) + "s"
	
	# Color based on urgency
	if mine_timer > 15.0:
		mine_timer_label.add_theme_color_override("font_color", Color.WHITE)
	elif mine_timer > 5.0:
		mine_timer_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		# Blink red when critical
		var blink = fmod(mine_timer * 4.0, 1.0) > 0.5
		if blink:
			mine_timer_label.add_theme_color_override("font_color", Color.RED)
		else:
			mine_timer_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))

func _update_mine_shader_state():
	"""Update mine shader parameters for armed state and urgency"""
	if not sprite or not sprite.material:
		return
	
	var mat = sprite.material as ShaderMaterial
	if not mat:
		return
	
	# Set armed state
	mat.set_shader_parameter("armed", 1.0 if mine_armed else 0.0)
	
	# Calculate urgency (0 = full time, 1 = about to explode)
	var urgency = 1.0 - (mine_timer / mine_max_timer)
	urgency = clampf(urgency, 0.0, 1.0)
	mat.set_shader_parameter("urgency", urgency)

func _check_mine_proximity() -> bool:
	"""Check if any enemy is within mine proximity radius"""
	if not mine_armed:
		return false
	
	# Query physics space for enemies in proximity
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = mine_proximity_radius
	query.shape = circle_shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 1 + 2  # Units and resources
	
	var results = space_state.intersect_shape(query, 16)
	
	for result in results:
		var body = result.collider
		if body == owner_unit:
			continue
		
		# Check if enemy (different team)
		if "team_id" in body and body.team_id != owner_team_id:
			return true
	
	return false

func _explode_torpedo():
	"""Handle torpedo reaching destination - large AOE explosion"""
	# Store values before returning to pool
	var explosion_pos = global_position
	
	# Apply AOE damage (this handles visual effect via _spawn_aoe_effect)
	_apply_aoe_damage(explosion_pos)
	
	# Return to pool
	if ProjectilePool:
		ProjectilePool.return_projectile(self)
	else:
		queue_free()

func _explode_mine():
	"""Handle mine detonation - proximity or timer triggered"""
	# Store values before returning to pool
	var explosion_pos = global_position
	
	# Apply AOE damage (this handles visual effect via _spawn_aoe_effect)
	_apply_aoe_damage(explosion_pos)
	
	# Play explosion sound if available
	if AudioManager:
		AudioManager.play_weapon_sound(explosion_pos)
	
	# Return to pool
	if ProjectilePool:
		ProjectilePool.return_projectile(self)
	else:
		queue_free()

func _on_lifetime_expired():
	"""Handle projectile expiring (can trigger AOE for mines, mortars, etc)"""
	# Some weapons detonate at end of life
	if weapon_type in [WT_MINE_LAYER, WT_GRAVITY_WELL]:
		_apply_aoe_damage(global_position)
	
	# Flak projectiles also explode at end of life
	if is_flak_projectile:
		_explode_flak()
		return
	
	# Mortar projectiles explode at end of life
	if is_mortar_projectile:
		_explode_mortar()
		return
	
	if ProjectilePool:
		ProjectilePool.return_projectile(self)
	else:
		queue_free()

func _explode_flak():
	"""Handle flak projectile reaching destination - small AOE explosion"""
	# Apply small AOE damage at destination (this spawns AOE visual via _spawn_aoe_effect)
	_apply_aoe_damage(global_position)
	
	# Note: Don't call _spawn_flak_impact_effect here - _apply_aoe_damage already spawns
	# the visual effect via _spawn_aoe_effect. Calling both creates double effects.
	
	# Return to pool
	if ProjectilePool:
		ProjectilePool.return_projectile(self)
	else:
		queue_free()

func _explode_mortar():
	"""Handle mortar shell reaching destination - large AOE explosion"""
	# Store values before returning to pool
	var explosion_pos = global_position
	
	# Apply AOE damage (this handles visual effect via _spawn_aoe_effect)
	_apply_aoe_damage(explosion_pos)
	
	# Return to pool
	if ProjectilePool:
		ProjectilePool.return_projectile(self)
	else:
		queue_free()

func _spawn_flak_impact_effect():
	"""Spawn a small explosion effect for flak bullet impact"""
	if not VfxDirector:
		return
	
	# Small AOE circle for flak - keep it visually subtle
	# flak_mini_aoe is typically 18-26, so this creates small 9-13 pixel circles
	var flak_color = Color(1.0, 0.6, 0.2, 0.7)  # Orange-yellow with some transparency
	VfxDirector.spawn_aoe_circle(global_position, flak_mini_aoe * 0.4, flak_color, 0.12)

func _on_body_entered(body: Node2D):
	if body == owner_unit:
		return  # Don't hit self
	
	# Track already hit targets for pierce weapons
	if body in already_hit:
		return
	
	# FRIENDLY FIRE CHECK
	if "team_id" in body:
		# For repair beam projectiles (support weapons), hit friendlies
		if special_effect == SE_HEAL:
			if body.team_id != owner_team_id:
				return  # Heal beam only hits allies
		else:
			if body.team_id == owner_team_id:
				return  # Damage projectiles pass through allies
	
	# Apply damage and effects
	_apply_hit(body)
	
	# For pierce weapons, continue through
	if special_effect == SE_PIERCE:
		already_hit.append(body)
		return  # Don't destroy projectile
	
	# For chain weapons (tesla), jump to next target
	if special_effect == SE_CHAIN and chain_count > 0:
		_apply_chain_damage(body)
	
	# Create impact effect
	_spawn_impact_effect()
	
	# Return to pool
	if ProjectilePool:
		ProjectilePool.return_projectile(self)
	else:
		queue_free()

func _apply_hit(body: Node2D):
	"""Apply damage and special effects to a target"""
	var attacker = owner_unit if is_instance_valid(owner_unit) else null
	
	# Handle healing (repair beam)
	if special_effect == SE_HEAL:
		if body.has_method("heal"):
			body.heal(damage)
		if FeedbackManager and FeedbackManager.has_method("spawn_damage_number"):
			FeedbackManager.spawn_damage_number(global_position, damage, true)  # Heal number
		return
	
	# Check for AOE damage
	if aoe_radius > 0 and aoe_type != AOE_NONE:
		_apply_aoe_damage(global_position)
	else:
		# Single target damage
		if body.has_method("take_damage"):
			# Shield bypass check
			var bypass_shield = (special_effect == SE_SHIELD_BYPASS)
			if bypass_shield and body.has_method("take_damage_bypass_shield"):
				body.take_damage_bypass_shield(damage, attacker, global_position)
			else:
				body.take_damage(damage, attacker, global_position)
			
			# Spawn damage number
			if FeedbackManager and FeedbackManager.has_method("spawn_damage_number"):
				var is_player_damage = (owner_team_id == 0)
				FeedbackManager.spawn_damage_number(global_position, damage, is_player_damage)
	
	# Apply special effects
	_apply_special_effect(body)

func _apply_special_effect(body: Node2D):
	"""Apply status effects to target"""
	if special_effect == SE_NONE:
		return
	
	if not body.has_method("apply_status_effect"):
		return
	
	match special_effect:
		SE_EMP:
			body.apply_status_effect("emp", effect_duration, effect_strength)
		SE_SLOW:
			body.apply_status_effect("slow", effect_duration, effect_strength)
		SE_DOT:
			body.apply_status_effect("burn", effect_duration, effect_strength)
		SE_PULL:
			body.apply_status_effect("pull", effect_duration, effect_strength, global_position)

func _apply_aoe_damage(center: Vector2):
	"""Apply AOE damage to all enemies in radius"""
	var space_state = get_world_2d().direct_space_state
	
	# Find all bodies in AOE radius
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = aoe_radius
	query.shape = circle_shape
	query.transform = Transform2D(0, center)
	query.collision_mask = 1 + 2  # Units and resources
	
	var results = space_state.intersect_shape(query, 32)
	var attacker = owner_unit if is_instance_valid(owner_unit) else null
	
	for result in results:
		var body = result.collider
		if body == owner_unit:
			continue
		if body in already_hit:
			continue
		
		# Friendly fire check
		if "team_id" in body and body.team_id == owner_team_id:
			continue
		
		# Calculate damage falloff based on distance
		var distance = center.distance_to(body.global_position)
		var falloff = 1.0 - (distance / aoe_radius) * 0.5  # 50% at edge
		var final_damage = damage * falloff
		
		if body.has_method("take_damage"):
			body.take_damage(final_damage, attacker, body.global_position)
			
			if FeedbackManager and FeedbackManager.has_method("spawn_damage_number"):
				var is_player_damage = (owner_team_id == 0)
				FeedbackManager.spawn_damage_number(body.global_position, final_damage, is_player_damage)
		
		# Apply status effects to all AOE targets
		_apply_special_effect(body)
		already_hit.append(body)
	
	# Spawn AOE visual effect
	_spawn_aoe_effect(center)

func _apply_chain_damage(initial_target: Node2D):
	"""Chain damage to nearby enemies (Tesla Coil)"""
	var current_target = initial_target
	var current_damage = damage * chain_damage_falloff
	var remaining_chains = chain_count
	
	while remaining_chains > 0 and current_damage > 1.0:
		# Find next target
		var next_target = _find_chain_target(current_target)
		if not next_target:
			break
		
		# Spawn chain lightning effect
		if VfxDirector:
			var color = WEAPON_COLORS.get(weapon_type, Color(0.4, 0.8, 1.0, 1.0))
			VfxDirector.spawn_beam_effect(current_target.global_position, next_target.global_position, color, 2.0, 0.15)
		
		# Apply damage
		var attacker = owner_unit if is_instance_valid(owner_unit) else null
		if next_target.has_method("take_damage"):
			next_target.take_damage(current_damage, attacker, next_target.global_position)
			
			if FeedbackManager and FeedbackManager.has_method("spawn_damage_number"):
				var is_player_damage = (owner_team_id == 0)
				FeedbackManager.spawn_damage_number(next_target.global_position, current_damage, is_player_damage)
		
		already_hit.append(next_target)
		current_target = next_target
		current_damage *= chain_damage_falloff
		remaining_chains -= 1

func _find_chain_target(from_target: Node2D) -> Node2D:
	"""Find nearest enemy for chain lightning"""
	var nearest: Node2D = null
	var nearest_dist := chain_range
	
	# Get units in chain range (use -1 for all teams, we filter below)
	var units_in_range = EntityManager.get_units_in_radius(from_target.global_position, chain_range, -1)
	
	for unit in units_in_range:
		if unit == owner_unit or unit == from_target:
			continue
		if unit in already_hit:
			continue
		if "team_id" in unit and unit.team_id == owner_team_id:
			continue
		
		var dist = from_target.global_position.distance_to(unit.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = unit
	
	return nearest

func _spawn_impact_effect():
	"""Spawn appropriate impact VFX"""
	if not VfxDirector and not FeedbackManager:
		return
	
	# Flak projectiles use their own smaller impact effect, skip full explosion
	if is_flak_projectile:
		_spawn_flak_impact_effect()
		return
	
	var explosion_scale = 0.6
	
	# Larger explosions for explosive weapons (but NOT flak - handled above)
	if weapon_type in [WT_MISSILE, WT_TORPEDO, WT_MORTAR, WT_MINE_LAYER, WT_ROCKET_POD]:
		explosion_scale = 1.0 + (aoe_radius / 100.0)
	
	# Clamp explosion scale to reasonable values to prevent screen-filling effects
	explosion_scale = clampf(explosion_scale, 0.3, 3.0)
	
	if VfxDirector and get_tree().current_scene:
		VfxDirector.spawn_explosion(get_tree().current_scene, global_position, explosion_scale)
	elif FeedbackManager:
		FeedbackManager.spawn_explosion(global_position)

func _spawn_aoe_effect(center: Vector2):
	"""Spawn AOE visual effect"""
	if not VfxDirector:
		return
	
	var color = WEAPON_COLORS.get(weapon_type, Color(1.0, 0.5, 0.2, 1.0))
	
	match aoe_type:
		AOE_CIRCLE:
			# Clamp radius to prevent oversized circles
			var clamped_radius = clampf(aoe_radius, 5.0, 200.0)
			VfxDirector.spawn_aoe_circle(center, clamped_radius, color, 0.3)
		AOE_RING:
			var clamped_radius = clampf(aoe_radius, 5.0, 200.0)
			VfxDirector.spawn_aoe_ring(center, clamped_radius, color, 0.4)
		_:
			# Clamp explosion scale to prevent screen-filling effects
			var explosion_scale = clampf(1.0 + (aoe_radius / 100.0), 0.5, 3.0)
			VfxDirector.spawn_explosion(get_tree().current_scene, center, explosion_scale)

func _on_area_entered(_area: Area2D):
	# Handle area collisions if needed
	pass

func reset_for_pool():
	"""Reset projectile state when returning to pool"""
	# Clear trail
	if trail_points:
		trail_points.clear()
	if trail_effect and is_instance_valid(trail_effect):
		VfxDirector.recycle(trail_effect)
	trail_effect = null
	
	# Reset all properties
	age = 0.0
	lifetime = 3.0  # Reset lifetime to default (mines set it very high)
	speed = 500.0  # Reset speed (mines set it to 0 when armed)
	damage = 0.0  # Reset damage
	homing_target = null
	owner_unit = null
	owner_team_id = 0
	owner_zone_id = ""
	direction = Vector2.ZERO
	global_position = Vector2.ZERO
	rotation = 0.0
	weapon_type = 0  # Reset weapon type
	
	# Reset extended properties
	aoe_radius = 0.0
	aoe_type = 0
	special_effect = 0
	effect_duration = 0.0
	effect_strength = 0.0
	chain_count = 0
	chain_range = 100.0
	chain_damage_falloff = 0.7
	already_hit.clear()
	
	# Reset flak properties
	is_flak_projectile = false
	target_destination = Vector2.ZERO
	flak_mini_aoe = 22.0
	
	# Reset torpedo properties
	is_torpedo_projectile = false
	torpedo_aoe_radius = 50.0
	
	# Reset mine properties
	is_mine_projectile = false
	mine_armed = false
	mine_timer = 30.0
	mine_max_timer = 30.0
	mine_proximity_radius = 50.0
	
	# Remove and cleanup mine timer label
	if mine_timer_label and is_instance_valid(mine_timer_label):
		mine_timer_label.queue_free()
	mine_timer_label = null
	
	# Reset mortar properties
	is_mortar_projectile = false
	mortar_mini_aoe = 40.0
	
	# Reset sprite visual properties to prevent shader/scale carryover
	if sprite:
		sprite.material = null  # Clear shader material
		sprite.scale = Vector2(0.8, 0.8)  # Reset to default scale
		sprite.modulate = Color.WHITE  # Reset modulate
		# Keep the default texture, it will be set by _apply_weapon_visuals