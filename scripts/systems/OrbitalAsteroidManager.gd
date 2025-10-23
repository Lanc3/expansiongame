extends Node
## Manages orbital motion of asteroids around planets

# Orbital data structure: { asteroid: { planet: Node2D, radius: float, angle: float, zone_id: int } }
var orbital_data: Dictionary = {}

# Very slow rotation: ~20-30 minutes per full rotation
const ORBIT_SPEED: float = 0.00015  # radians per frame at 60fps

# Performance optimization: update at 10 FPS instead of 60 FPS
var update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.1  # Update every 0.1 seconds (10 FPS)

func _process(delta: float):
	"""Update positions of orbiting asteroids at reduced frequency"""
	# Accumulate time
	update_timer += delta
	
	# Only update every UPDATE_INTERVAL seconds (10 FPS instead of 60 FPS)
	if update_timer < UPDATE_INTERVAL:
		return
	
	# Calculate accumulated delta for smooth motion
	var accumulated_delta = update_timer
	update_timer = 0.0
	
	# Get current active zone for optimization
	var current_zone_id = ZoneManager.current_zone_id if ZoneManager else 1
	
	# Only update asteroids in current zone + adjacent zones
	for asteroid in orbital_data.keys():
		if not is_instance_valid(asteroid):
			orbital_data.erase(asteroid)
			continue
		
		var data = orbital_data[asteroid]
		
		# Skip asteroids not in visible zones (major optimization)
		if data.zone_id != current_zone_id:
			# Optionally update adjacent zones (for smooth transitions)
			var is_adjacent = abs(data.zone_id - current_zone_id) <= 1
			if not is_adjacent:
				continue
		
		var planet = data.planet
		
		if not is_instance_valid(planet):
			# Planet no longer exists, remove orbital data
			orbital_data.erase(asteroid)
			continue
		
		# Increment angle (compensate for reduced update frequency)
		var angle_increment = ORBIT_SPEED * accumulated_delta * 60.0  # Scale to maintain same speed
		data.angle += angle_increment
		if data.angle > TAU:
			data.angle -= TAU
		
		# Update asteroid position
		asteroid.global_position = calculate_orbital_position(
			planet.global_position,
			data.radius,
			data.angle
		)
		
		# Store angle back in asteroid for persistence
		if asteroid.has_meta("orbital_angle"):
			asteroid.set_meta("orbital_angle", data.angle)

func register_asteroid(asteroid: Node2D, planet: Node2D, orbit_radius: float, start_angle: float):
	"""Register an asteroid to orbit a planet"""
	if not is_instance_valid(asteroid) or not is_instance_valid(planet):
		return
	
	# Determine zone_id from asteroid metadata or planet
	var zone_id = 1
	if asteroid.has_meta("zone_id"):
		zone_id = asteroid.get_meta("zone_id")
	elif ZoneManager:
		# Try to determine from planet position
		for z_id in range(1, 10):
			var zone = ZoneManager.get_zone(z_id)
			if not zone.is_empty() and zone.boundaries.has_point(planet.global_position):
				zone_id = z_id
				break
	
	orbital_data[asteroid] = {
		"planet": planet,
		"radius": orbit_radius,
		"angle": start_angle,
		"zone_id": zone_id
	}
	
	# Store orbital data in asteroid metadata for persistence
	asteroid.set_meta("orbital_planet_position", planet.global_position)
	asteroid.set_meta("orbital_radius", orbit_radius)
	asteroid.set_meta("orbital_angle", start_angle)
	
	# Set initial position
	asteroid.global_position = calculate_orbital_position(
		planet.global_position,
		orbit_radius,
		start_angle
	)

func unregister_asteroid(asteroid: Node2D):
	"""Remove asteroid from orbital system"""
	if asteroid in orbital_data:
		orbital_data.erase(asteroid)

func calculate_orbital_position(planet_pos: Vector2, radius: float, angle: float) -> Vector2:
	"""Calculate position on circular orbit"""
	return planet_pos + Vector2(
		cos(angle) * radius,
		sin(angle) * radius
	)

func get_asteroid_orbit_data(asteroid: Node2D) -> Dictionary:
	"""Get orbital data for an asteroid (for save/load)"""
	if asteroid in orbital_data:
		var data = orbital_data[asteroid]
		return {
			"planet_position": data.planet.global_position if is_instance_valid(data.planet) else Vector2.ZERO,
			"radius": data.radius,
			"angle": data.angle
		}
	return {}

func restore_asteroid_orbit(asteroid: Node2D, planet_position: Vector2, radius: float, angle: float):
	"""Restore orbital data after loading (need to find planet by position)"""
	# Find planet near the saved position
	var planet = find_planet_at_position(planet_position)
	if planet:
		register_asteroid(asteroid, planet, radius, angle)

func find_planet_at_position(position: Vector2, tolerance: float = 100.0) -> Node2D:
	"""Find a planet near a given position"""
	var planets = get_tree().get_nodes_in_group("planets")
	for planet in planets:
		if is_instance_valid(planet) and planet.global_position.distance_to(position) < tolerance:
			return planet
	return null

func clear_all():
	"""Clear all orbital data (for scene reset)"""
	orbital_data.clear()

