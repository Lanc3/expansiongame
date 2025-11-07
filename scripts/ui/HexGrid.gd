class_name HexGrid
extends RefCounted
## Utility functions for hexagonal grid operations using axial coordinates (q, r)

static func pixel_to_hex(pixel: Vector2, cell_size: float) -> Vector2i:
	"""Convert pixel position to hex coordinates (q, r) - snaps to nearest hex"""
	var q = (sqrt(3) / 3 * pixel.x - 1.0 / 3 * pixel.y) / cell_size
	var r = (2.0 / 3 * pixel.y) / cell_size
	return hex_round(Vector2(q, r))

static func hex_to_pixel(hex: Vector2i, cell_size: float) -> Vector2:
	"""Convert hex coordinates (q, r) to pixel position"""
	var q = float(hex.x)
	var r = float(hex.y)
	var x = cell_size * (sqrt(3) * q + sqrt(3) / 2 * r)
	var y = cell_size * (3.0 / 2 * r)
	return Vector2(x, y)

static func hex_round(hex: Vector2) -> Vector2i:
	"""Round fractional hex coordinates to nearest hex cell"""
	var q = round(hex.x)
	var r = round(hex.y)
	var s = round(-hex.x - hex.y)
	
	var q_diff = abs(q - hex.x)
	var r_diff = abs(r - hex.y)
	var s_diff = abs(s - (-hex.x - hex.y))
	
	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s
	else:
		s = -q - r
	
	return Vector2i(int(q), int(r))

static func get_hex_vertices(center: Vector2, size: float) -> PackedVector2Array:
	"""Get 6 vertices of a hexagon centered at position"""
	var vertices = PackedVector2Array()
	for i in range(6):
		var angle = PI / 3 * i - PI / 6  # Start at top (pointy-top hex)
		vertices.append(center + Vector2(cos(angle), sin(angle)) * size)
	return vertices

static func get_hex_neighbors(hex: Vector2i) -> Array[Vector2i]:
	"""Get 6 neighbors of a hex cell in axial coordinates"""
	return [
		hex + Vector2i(1, 0),   # East
		hex + Vector2i(1, -1),   # Northeast
		hex + Vector2i(0, -1),   # Northwest
		hex + Vector2i(-1, 0),   # West
		hex + Vector2i(-1, 1),   # Southwest
		hex + Vector2i(0, 1)     # Southeast
	]

static func hex_distance(a: Vector2i, b: Vector2i) -> int:
	"""Calculate distance between two hex cells"""
	return (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2

static func get_component_hex_cells(origin_hex: Vector2i, size: Vector2i) -> Array[Vector2i]:
	"""Convert rectangular component size to compact hex pattern
	
	Uses predefined compact shapes for common sizes, falls back to hex spiral for others.
	The pattern starts from origin_hex and creates a natural-looking hex arrangement.
	"""
	var cell_count = size.x * size.y
	var hex_cells: Array[Vector2i] = []
	
	# Predefined compact shapes for common sizes (Option B from plan)
	match cell_count:
		1:
			# Single cell
			hex_cells.append(origin_hex)
		2:
			# Two cells - horizontal line
			hex_cells.append(origin_hex)
			hex_cells.append(origin_hex + Vector2i(1, 0))
		3:
			# Three cells - small triangle
			hex_cells.append(origin_hex)
			hex_cells.append(origin_hex + Vector2i(1, 0))
			hex_cells.append(origin_hex + Vector2i(0, 1))
		4:
			# Four cells - 2x2 square in hex (diamond shape)
			hex_cells.append(origin_hex)
			hex_cells.append(origin_hex + Vector2i(1, 0))
			hex_cells.append(origin_hex + Vector2i(0, 1))
			hex_cells.append(origin_hex + Vector2i(1, -1))
		6:
			# Six cells - hex ring (center + 5 neighbors)
			hex_cells.append(origin_hex)
			for neighbor in get_hex_neighbors(origin_hex):
				hex_cells.append(neighbor)
		9:
			# Nine cells - 3x3 compact hex (center + ring)
			hex_cells.append(origin_hex)
			for neighbor in get_hex_neighbors(origin_hex):
				hex_cells.append(neighbor)
			# Add one more cell to make 7, then add 2 more
			hex_cells.append(origin_hex + Vector2i(2, -1))
			hex_cells.append(origin_hex + Vector2i(1, 1))
		_:
			# Fallback to hex spiral pattern (Option A) for other sizes
			hex_cells = _generate_hex_spiral(origin_hex, cell_count)
	
	return hex_cells

static func _generate_hex_spiral(origin_hex: Vector2i, cell_count: int) -> Array[Vector2i]:
	"""Generate hex spiral pattern starting from origin until cell_count cells are added"""
	var hex_cells: Array[Vector2i] = [origin_hex]
	var visited: Dictionary = {origin_hex: true}
	
	if cell_count <= 1:
		return hex_cells
	
	# Spiral outward in rings
	var radius = 1
	while hex_cells.size() < cell_count:
		# Generate hex ring at this radius
		var ring_cells = _get_hex_ring(origin_hex, radius)
		for cell in ring_cells:
			if hex_cells.size() >= cell_count:
				break
			if not visited.has(cell):
				hex_cells.append(cell)
				visited[cell] = true
		radius += 1
	
	return hex_cells

static func _get_hex_ring(center: Vector2i, radius: int) -> Array[Vector2i]:
	"""Get all hex cells at a given radius from center"""
	if radius == 0:
		return [center]
	
	var ring: Array[Vector2i] = []
	var q = center.x - radius
	var r = center.y + radius
	
	# Walk around the ring (6 sides)
	for i in range(6):
		for j in range(radius):
			ring.append(Vector2i(q, r))
			# Move to next cell on this side
			match i:
				0:  # East side
					q += 1
				1:  # Northeast side
					q += 1
					r -= 1
				2:  # Northwest side
					r -= 1
				3:  # West side
					q -= 1
				4:  # Southwest side
					q -= 1
					r += 1
				5:  # Southeast side
					r += 1
	
	return ring

