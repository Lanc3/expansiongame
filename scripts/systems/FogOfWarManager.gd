extends Node
## Manages tile-based fog of war system with per-zone persistence
## Optimized for performance with adaptive tile sizing and current-zone-only updates

signal fog_updated(zone_id: String)
signal fog_revealed(zone_id: String)  # Emitted when fog is revealed for performance optimization
signal fog_dirty_region_updated(zone_id: String, min_tile: Vector2i, max_tile: Vector2i)

# Fog grids: Dictionary[zone_id -> Array[Array[bool]]]
var fog_grids: Dictionary = {}

# Tile configuration - adaptive sizing based on zone
const BASE_TILE_SIZE: float = 200.0

# Update configuration - reduced from 1.5s to 0.5s for responsive fog reveal
var update_interval: float = 0.5
var time_since_update: float = 0.0
var fog_dirty: Dictionary = {}  # Tracks which zones need texture regeneration

# Dirty region tracking for partial texture updates
var dirty_regions: Dictionary = {}  # zone_id -> {min: Vector2i, max: Vector2i}

func _ready():
	# Fog grids will be initialized on-demand when zones are discovered
	# Connect to zone discovery to initialize fog for new zones
	if ZoneManager:
		ZoneManager.zone_discovered.connect(_on_zone_discovered)
		# Initialize fog for starting zone
		if not ZoneManager.current_zone_id.is_empty():
			initialize_zone_fog(ZoneManager.current_zone_id)

func _on_zone_discovered(zone_id: String):
	"""Initialize fog for newly discovered zone"""
	initialize_zone_fog(zone_id)

func _process(delta: float):
	time_since_update += delta
	
	if time_since_update >= update_interval:
		time_since_update = 0.0
		update_fog_from_units()

func get_tile_size_for_zone(zone_id: String) -> float:
	"""Get adaptive tile size based on zone (larger zones = larger tiles for performance)"""
	# Get zone difficulty
	var difficulty = 1
	if ZoneManager:
		var zone = ZoneManager.get_zone(zone_id)
		if not zone.is_empty():
			difficulty = zone.difficulty
	
	if difficulty <= 3:
		return BASE_TILE_SIZE  # 200px for difficulty 1-3
	elif difficulty <= 6:
		return BASE_TILE_SIZE * 1.5  # 300px for difficulty 4-6
	else:
		return BASE_TILE_SIZE * 2.0  # 400px for difficulty 7-9

func initialize_zone_fog(zone_id: String):
	"""Create fog grid for a zone with adaptive tile sizing"""
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty():
		return
	
	var zone_size = zone.boundaries.size
	var tile_size = get_tile_size_for_zone(zone_id)
	# Use round instead of ceil to avoid oversizing the grid
	# This ensures grid_width * tile_size ≈ zone_size.x
	var grid_width = int(round(zone_size.x / tile_size))
	var grid_height = int(round(zone_size.y / tile_size))
	
	# Create 2D grid initialized to false (unexplored)
	var grid: Array = []
	for y in range(grid_height):
		var row: Array = []
		for x in range(grid_width):
			row.append(false)
		grid.append(row)
	
	fog_grids[zone_id] = grid
	fog_dirty[zone_id] = true
	dirty_regions[zone_id] = {"min": Vector2i.ZERO, "max": Vector2i(grid_width - 1, grid_height - 1)}
	
	print("FogOfWarManager: Initialized fog for Zone '%s' (%dx%d tiles, %.0fpx tile size)" % [zone_id, grid_width, grid_height, tile_size])

func update_fog_from_units():
	"""Update fog based on player units in ALL zones where they exist"""
	if not EntityManager or not ZoneManager:
		return
	
	var current_zone_id = ZoneManager.current_zone_id
	if current_zone_id.is_empty():
		return
	
	# Get all player units (team_id 0)
	var player_units = EntityManager.get_units_by_team(0)
	
	# Track units per zone for debugging
	var units_per_zone: Dictionary = {}
	
	# Update fog for ALL units regardless of which zone is being viewed
	# This ensures fog reveals in zones you have units even when not viewing them
	for unit in player_units:
		if not is_instance_valid(unit):
			continue
		
		# Get unit's zone
		var zone_id = ZoneManager.get_unit_zone(unit)
		
		# Skip invalid/empty zones
		if zone_id.is_empty() or not ZoneManager.is_valid_zone(zone_id):
			continue
		
		# Track for debug
		if not units_per_zone.has(zone_id):
			units_per_zone[zone_id] = 0
		units_per_zone[zone_id] += 1
		
		# Get vision range (default to 800 if not specified - doubled from 400)
		var vision_range = unit.get("vision_range")
		if vision_range == null:
			vision_range = 800.0
		
		# Reveal area around unit in its zone
		reveal_position(zone_id, unit.global_position, vision_range)
	
	# Debug: Print unit distribution every 5 seconds with more details
	if Time.get_ticks_msec() % 5000 < update_interval * 1000:
		if not units_per_zone.is_empty():
			var debug_msg = "FogOfWar: Units revealing fog - "
			for z_id in units_per_zone.keys():
				debug_msg += "Zone %d: %d units, " % [z_id, units_per_zone[z_id]]
			debug_msg = debug_msg.trim_suffix(", ")
			debug_msg += " (Total player units: %d)" % player_units.size()
			print(debug_msg)
			
		# Extra detail for debugging - check all zones with difficulty 2+
		for zone_id_key in units_per_zone.keys():
			var zone_data = ZoneManager.get_zone(zone_id_key)
			if not zone_data.is_empty() and zone_data.difficulty >= 2:
				print("  -> Zone '%s' (difficulty %d) player units detected:" % [zone_data.procedural_name, zone_data.difficulty])
				for unit in player_units:
					if is_instance_valid(unit):
						var u_zone = ZoneManager.get_unit_zone(unit)
						if u_zone == zone_id_key:
							var u_name = unit.unit_name if "unit_name" in unit else "Unknown"
							var u_pos = unit.global_position
							print("     - %s at (%.0f, %.0f)" % [u_name, u_pos.x, u_pos.y])

func reveal_position(zone_id: String, position: Vector2, radius: float):
	"""Mark tiles within radius of position as explored with dirty region tracking"""
	if not zone_id in fog_grids:
		return
	
	var grid = fog_grids[zone_id]
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty():
		return
	
	var tile_size = get_tile_size_for_zone(zone_id)
	var center_tile = position_to_tile(position, zone_id)
	var radius_tiles = int(ceil(radius / tile_size))
	
	var changed = false
	var min_changed_tile = Vector2i(999999, 999999)
	var max_changed_tile = Vector2i(-999999, -999999)
	
	# Mark circular area as explored
	for y in range(-radius_tiles, radius_tiles + 1):
		for x in range(-radius_tiles, radius_tiles + 1):
			# Circle check
			if x*x + y*y <= radius_tiles * radius_tiles:
				var tile = center_tile + Vector2i(x, y)
				if is_valid_tile(tile, grid):
					if not grid[tile.y][tile.x]:
						grid[tile.y][tile.x] = true
						changed = true
						
						# Track dirty region bounds
						min_changed_tile.x = min(min_changed_tile.x, tile.x)
						min_changed_tile.y = min(min_changed_tile.y, tile.y)
						max_changed_tile.x = max(max_changed_tile.x, tile.x)
						max_changed_tile.y = max(max_changed_tile.y, tile.y)
	
	if changed:
		fog_dirty[zone_id] = true
		
		# Update dirty region for partial texture updates
		if zone_id in dirty_regions:
			var region = dirty_regions[zone_id]
			region.min.x = min(region.min.x, min_changed_tile.x)
			region.min.y = min(region.min.y, min_changed_tile.y)
			region.max.x = max(region.max.x, max_changed_tile.x)
			region.max.y = max(region.max.y, max_changed_tile.y)
		else:
			dirty_regions[zone_id] = {"min": min_changed_tile, "max": max_changed_tile}
		
		fog_updated.emit(zone_id)
		fog_revealed.emit(zone_id)
		fog_dirty_region_updated.emit(zone_id, min_changed_tile, max_changed_tile)

func is_position_revealed(zone_id: String, position: Vector2) -> bool:
	"""Check if a position has been explored"""
	if not zone_id in fog_grids:
		return false
	
	var tile = position_to_tile(position, zone_id)
	var grid = fog_grids[zone_id]
	
	if is_valid_tile(tile, grid):
		return grid[tile.y][tile.x]
	
	return false

func position_to_tile(position: Vector2, zone_id: String) -> Vector2i:
	"""Convert world position to tile coordinates using adaptive tile size"""
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty():
		return Vector2i.ZERO
	
	var bounds = zone.boundaries
	var tile_size = get_tile_size_for_zone(zone_id)
	var relative_x = position.x - bounds.position.x
	var relative_y = position.y - bounds.position.y
	
	var tile_x = int(relative_x / tile_size)
	var tile_y = int(relative_y / tile_size)
	
	return Vector2i(tile_x, tile_y)

func is_valid_tile(tile: Vector2i, grid: Array) -> bool:
	"""Check if tile coordinates are within grid bounds"""
	if grid.is_empty():
		return false
	
	return tile.y >= 0 and tile.y < grid.size() and tile.x >= 0 and tile.x < grid[0].size()

func get_fog_grid(zone_id: String) -> Array:
	"""Get fog grid for a zone"""
	if zone_id in fog_grids:
		return fog_grids[zone_id]
	return []

func is_fog_dirty(zone_id: String) -> bool:
	"""Check if zone fog needs texture regeneration"""
	return fog_dirty.get(zone_id, false)

func clear_fog_dirty(zone_id: String):
	"""Mark zone fog as clean (texture updated)"""
	fog_dirty[zone_id] = false

func get_dirty_region(zone_id: String) -> Dictionary:
	"""Get dirty region bounds for partial texture updates"""
	if zone_id in dirty_regions:
		return dirty_regions[zone_id]
	return {}

func clear_dirty_region(zone_id: String):
	"""Clear dirty region after texture update"""
	if zone_id in dirty_regions:
		dirty_regions.erase(zone_id)

func clear_zone_fog(zone_id: String):
	"""Reset fog for a zone (all unexplored)"""
	initialize_zone_fog(zone_id)

func reset():
	"""Reset all fog state for a new game"""
	fog_grids.clear()
	fog_dirty.clear()
	dirty_regions.clear()
	time_since_update = 0.0
	
	# Fog will be reinitialized on-demand as zones are discovered
	# Initialize fog for current starting zone if available
	if ZoneManager and not ZoneManager.current_zone_id.is_empty():
		initialize_zone_fog(ZoneManager.current_zone_id)
	
	print("FogOfWarManager: Reset complete - fog cleared, will reinitialize on-demand")

func get_tile_size(zone_id: String) -> float:
	"""Public accessor for tile size (used by FogOverlay shader)"""
	return get_tile_size_for_zone(zone_id)

func save_fog_data() -> Dictionary:
	"""Serialize fog grids for saving"""
	var data = {}
	
	for zone_id in fog_grids:
		data[str(zone_id)] = fog_grids[zone_id]
	
	return data

func load_fog_data(data: Dictionary):
	"""Restore fog grids from save data"""
	for zone_id_str in data:
		var zone_id = int(zone_id_str)
		fog_grids[zone_id] = data[zone_id_str]
		fog_dirty[zone_id] = true
	
	print("FogOfWarManager: Loaded fog data for %d zones" % data.size())
