extends Node
## Object pool for projectiles to reduce GC pressure and improve spawn performance

const POOL_SIZE: int = 50  # Pre-allocate 50 projectiles
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/effects/Projectile.tscn")

# Pre-loaded textures (avoid file I/O on every spawn)
var laser_texture: Texture2D = preload("res://assets/sprites/Lasers/laserRed01.png")
var plasma_texture: Texture2D = preload("res://assets/sprites/Lasers/laserBlue01.png")
var missile_texture: Texture2D = preload("res://assets/sprites/Lasers/laserGreen01.png")

var available_pool: Array[Node] = []  # Available projectiles
var active_projectiles: Array[Node] = []  # Currently active projectiles

func _ready():
	# Pre-populate pool
	for i in range(POOL_SIZE):
		var projectile = PROJECTILE_SCENE.instantiate()
		projectile.set_process(false)  # Disable processing
		projectile.visible = false
		projectile.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(projectile)
		available_pool.append(projectile)

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
	match weapon_type:
		0: return laser_texture  # LASER
		1: return plasma_texture  # PLASMA
		2: return missile_texture  # MISSILE
		_: return laser_texture

func get_active_count() -> int:
	"""Get count of currently active projectiles"""
	return active_projectiles.size()

func get_available_count() -> int:
	"""Get count of available projectiles in pool"""
	return available_pool.size()
