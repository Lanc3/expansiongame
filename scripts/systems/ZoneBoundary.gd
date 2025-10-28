extends Node2D
## Hard boundary system to prevent units from crossing zones without wormholes

var zone_id: String = ""
var boundaries: Rect2 = Rect2()
var boundary_thickness: float = 50.0

func _ready():
	pass

func setup_for_zone(p_zone_id: String, zone_bounds: Rect2):
	"""Setup boundary for a specific zone"""
	zone_id = p_zone_id
	boundaries = zone_bounds

func _process(_delta: float):
	"""Check and clamp all units within zone boundaries"""
	if not EntityManager:
		return
	
	var zone_units = EntityManager.get_units_in_zone(zone_id)
	
	for unit in zone_units:
		if not is_instance_valid(unit):
			continue
		
		# Check if unit is outside boundaries
		if not boundaries.has_point(unit.global_position):
			# Clamp unit position to boundaries
			clamp_unit_to_boundaries(unit)

func clamp_unit_to_boundaries(unit: Node2D):
	"""Clamp unit position to stay within zone boundaries"""
	var pos = unit.global_position
	var bounds_min = boundaries.position
	var bounds_max = boundaries.position + boundaries.size
	
	var clamped_pos = Vector2(
		clamp(pos.x, bounds_min.x + boundary_thickness, bounds_max.x - boundary_thickness),
		clamp(pos.y, bounds_min.y + boundary_thickness, bounds_max.y - boundary_thickness)
	)
	
	# Only update if position changed
	if clamped_pos != pos:
		unit.global_position = clamped_pos
		
		# Stop unit movement if it has velocity
		if "velocity" in unit:
			unit.velocity = Vector2.ZERO
		
		# Cancel current command if unit hit boundary
		if unit.has_method("clear_commands"):
			# Don't clear completely, just stop current movement
			pass

func is_position_within_boundaries(position: Vector2) -> bool:
	"""Check if a position is within zone boundaries"""
	var bounds_min = boundaries.position + Vector2(boundary_thickness, boundary_thickness)
	var bounds_max = boundaries.position + boundaries.size - Vector2(boundary_thickness, boundary_thickness)
	
	return position.x >= bounds_min.x and position.x <= bounds_max.x and \
		   position.y >= bounds_min.y and position.y <= bounds_max.y

