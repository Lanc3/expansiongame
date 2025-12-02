extends Node
## Object pool for projectiles to reduce GC pressure and improve spawn performance
## Supports all 21 weapon types

const POOL_SIZE: int = 100  # Increased for more weapon types
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/effects/Projectile.tscn")

# Weapon type constants (must match Projectile.gd)
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

# Pre-loaded textures (avoid file I/O on every spawn)
# Base textures - loaded once
var laser_texture: Texture2D
var plasma_texture: Texture2D
var missile_texture: Texture2D
var energy_texture: Texture2D
var bullet_texture: Texture2D

# Texture mapping for all weapon types
var texture_map: Dictionary = {}

var available_pool: Array[Node] = []  # Available projectiles
var active_projectiles: Array[Node] = []  # Currently active projectiles

func _ready():
	# Pre-load base textures
	_load_textures()
	
	# Pre-populate pool
	for i in range(POOL_SIZE):
		var projectile = PROJECTILE_SCENE.instantiate()
		projectile.set_process(false)  # Disable processing
		projectile.visible = false
		projectile.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(projectile)
		available_pool.append(projectile)

func _load_textures():
	"""Pre-load all projectile textures"""
	# Load base textures (some may not exist, use fallbacks)
	laser_texture = _safe_load("res://assets/sprites/Lasers/laserRed01.png")
	plasma_texture = _safe_load("res://assets/sprites/Lasers/laserBlue01.png")
	missile_texture = _safe_load("res://assets/sprites/Missiles/missile.png")
	energy_texture = _safe_load("res://assets/sprites/Lasers/laserGreen01.png", laser_texture)
	bullet_texture = _safe_load("res://assets/sprites/Lasers/laserRed01.png", laser_texture)
	
	# Map weapon types to appropriate textures
	texture_map = {
		# Kinetic
		WT_LASER: laser_texture,
		WT_AUTOCANNON: bullet_texture,
		WT_RAILGUN: plasma_texture,
		WT_GATLING: bullet_texture,
		WT_SNIPER: energy_texture,
		WT_SHOTGUN: bullet_texture,
		
		# Energy
		WT_ION_CANNON: plasma_texture,
		WT_PLASMA_CANNON: energy_texture,
		WT_PARTICLE_BEAM: plasma_texture,
		WT_TESLA_COIL: plasma_texture,
		WT_DISRUPTOR: plasma_texture,
		
		# Explosive
		WT_MISSILE: missile_texture,
		WT_FLAK_CANNON: missile_texture,
		WT_TORPEDO: missile_texture,
		WT_ROCKET_POD: missile_texture,
		WT_MORTAR: missile_texture,
		WT_MINE_LAYER: missile_texture,
		
		# Special
		WT_CRYO_CANNON: plasma_texture,
		WT_EMP_BURST: plasma_texture,
		WT_GRAVITY_WELL: plasma_texture,
		WT_REPAIR_BEAM: energy_texture
	}

func _safe_load(path: String, fallback: Texture2D = null) -> Texture2D:
	"""Safely load a texture with fallback"""
	if ResourceLoader.exists(path):
		return load(path)
	return fallback

func get_projectile() -> Projectile:
	"""Get a projectile from the pool (or create new if pool empty)"""
	var projectile: Projectile = null
	
	# Try to get from pool
	if available_pool.size() > 0:
		projectile = available_pool.pop_back() as Projectile
	else:
		# Pool exhausted - create new one (unlikely but possible)
		projectile = PROJECTILE_SCENE.instantiate() as Projectile
		add_child(projectile)
	
	# Activate the projectile
	projectile.process_mode = Node.PROCESS_MODE_INHERIT
	projectile.visible = true
	projectile.set_process(true)
	
	# Track as active
	if projectile not in active_projectiles:
		active_projectiles.append(projectile)
	
	return projectile

func return_projectile(projectile: Projectile):
	"""Return a projectile to the pool for reuse"""
	if not is_instance_valid(projectile):
		return
	
	# Remove from active list
	active_projectiles.erase(projectile)
	
	# Reset projectile state for reuse
	projectile.set_process(false)
	projectile.visible = false
	projectile.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Use projectile's reset method if available
	if projectile.has_method("reset_for_pool"):
		projectile.reset_for_pool()
	
	# Return to pool for reuse
	if projectile not in available_pool:
		available_pool.append(projectile)

func get_texture_for_type(weapon_type: int) -> Texture2D:
	"""Get pre-loaded texture for weapon type"""
	return texture_map.get(weapon_type, laser_texture)

func get_active_count() -> int:
	"""Get count of currently active projectiles"""
	return active_projectiles.size()

func get_available_count() -> int:
	"""Get count of available projectiles in pool"""
	return available_pool.size()
