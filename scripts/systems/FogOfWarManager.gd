extends Node
## Manages tile-based fog of war system with per-zone persistence

signal fog_updated(zone_id: int)
signal fog_revealed(zone_id: int)  # Emitted when fog is revealed for performance optimization

# Fog grids: Dictionary[zone_id -> Array[Array[bool]]]
var fog_grids: Dictionary = {}

# Tile configuration
const TILE_SIZE: float = 200.0

# Update configuration
var update_interval: float = 1.5
var time_since_update: float = 0.0
var fog_dirty: Dictionary = {}  # Tracks which zones need texture regeneration

func _ready():
	# Initialize fog grids for all 9 zones
	for zone_id in range(1, 10):
		initialize_zone_fog(zone_id)

func _process(delta: float):
	time_since_update += delta
	
	if time_since_update >= update_interval:
		time_since_update = 0.0
		update_fog_from_units()

func initialize_zone_fog(zone_id: int):
	"""Create fog grid for a zone"""
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty():
		return
	
	var zone_size = zone.boundaries.size
	var grid_width = int(ceil(zone_size.x / TILE_SIZE))
	var grid_height = int(ceil(zone_size.y / TILE_SIZE))
	
	# Create 2D grid initialized to false (unexplored)
	var grid: Array = []
	for y in range(grid_height):
		var row: Array = []
		for x in range(grid_width):
			row.append(false)
		grid.append(row)
	
	fog_grids[zone_id] = grid
	fog_dirty[zone_id] = true
	
	print("FogOfWarManager: Initialized fog for Zone %d (%dx%d tiles)" % [zone_id, grid_width, grid_height])

func update_fog_from_units():
	"""Update fog based on all player unit positions"""
	if not EntityManager:
		return
	
	# Get all player units (team_id 0)
	var player_units = EntityManager.get_units_by_team(0)
	
	for unit in player_units:
		if not is_instance_valid(unit):
			continue
		
		# Get unit's zone
		var zone_id = ZoneManager.get_unit_zone(unit)
		if zone_id == -1:
			continue
		
		# Get vision range (default to 400 if not specified)
		var vision_range = unit.get("vision_range")
		if vision_range == null:
			vision_range = 400.0
		
		# Reveal area around unit
		reveal_position(zone_id, unit.global_position, vision_range)

func reveal_position(zone_id: int, position: Vector2, radius: float):
	"""Mark tiles within radius of position as explored"""
	if not zone_id in fog_grids:
		return
	
	var grid = fog_grids[zone_id]
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty():
		return
	
	var center_tile = position_to_tile(position, zone_id)
	var radius_tiles = int(ceil(radius / TILE_SIZE))
	
	var changed = false
	
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
	
	if changed:
		fog_dirty[zone_id] = true
		fog_updated.emit(zone_id)
		fog_revealed.emit(zone_id)  # Signal for fog overlay redraw

func is_position_revealed(zone_id: int, position: Vector2) -> bool:
	"""Check if a position has been explored"""
	if not zone_id in fog_grids:
		return false
	
	var tile = position_to_tile(position, zone_id)
	var grid = fog_grids[zone_id]
	
	if is_valid_tile(tile, grid):
		return grid[tile.y][tile.x]
	
	return false

func position_to_tile(position: Vector2, zone_id: int) -> Vector2i:
	"""Convert world position to tile coordinates"""
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty():
		return Vector2i.ZERO
	
	var bounds = zone.boundaries
	var relative_x = position.x - bounds.position.x
	var relative_y = position.y - bounds.position.y
	
	var tile_x = int(relative_x / TILE_SIZE)
	var tile_y = int(relative_y / TILE_SIZE)
	
	return Vector2i(tile_x, tile_y)

func is_valid_tile(tile: Vector2i, grid: Array) -> bool:
	"""Check if tile coordinates are within grid bounds"""
	if grid.is_empty():
		return false
	
	return tile.y >= 0 and tile.y < grid.size() and tile.x >= 0 and tile.x < grid[0].size()

func get_fog_grid(zone_id: int) -> Array:
	"""Get fog grid for a zone"""
	if zone_id in fog_grids:
		return fog_grids[zone_id]
	return []

func is_fog_dirty(zone_id: int) -> bool:
	"""Check if zone fog needs texture regeneration"""
	return fog_dirty.get(zone_id, false)

func clear_fog_dirty(zone_id: int):
	"""Mark zone fog as clean (texture updated)"""
	fog_dirty[zone_id] = false

func clear_zone_fog(zone_id: int):
	"""Reset fog for a zone (all unexplored)"""
	initialize_zone_fog(zone_id)

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

