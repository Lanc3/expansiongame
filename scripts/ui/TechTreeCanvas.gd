extends Control
## Canvas for drawing tech tree connections

var tech_nodes: Dictionary = {}  # Shared reference from parent

func _ready():
	# Allow clicks to pass through to child nodes
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_tech_nodes(nodes: Dictionary):
	"""Set reference to tech nodes for drawing connections"""
	tech_nodes = nodes
	queue_redraw()

func _draw():
	"""Draw connection lines between research nodes"""
	for research_id in tech_nodes:
		var node = tech_nodes[research_id]
		if not is_instance_valid(node):
			continue
		
		var research = ResearchDatabase.get_research_by_id(research_id)
		if research.is_empty():
			continue
		
		# Draw lines to prerequisites
		for prereq_id in research.prerequisites:
			if prereq_id in tech_nodes:
				var prereq_node = tech_nodes[prereq_id]
				if is_instance_valid(prereq_node):
					draw_connection_line(node, prereq_node, research)

func draw_connection_line(from_node: Control, to_node: Control, research: Dictionary):
	"""Draw a bezier curve connection between two nodes"""
	# Account for node scale when calculating center position
	var from_scale = from_node.scale.x if from_node.scale else 1.0
	var to_scale = to_node.scale.x if to_node.scale else 1.0
	
	var from_pos = from_node.position + (from_node.size * from_scale / 2.0)
	var to_pos = to_node.position + (to_node.size * to_scale / 2.0)
	
	# Determine line color based on research status
	var line_color = Color(0.3, 0.3, 0.3, 0.5)  # Gray - locked
	
	if ResearchManager:
		if ResearchManager.is_unlocked(research.id):
			line_color = Color(0.0, 0.8, 0.0, 0.7)  # Green - researched
		elif ResearchManager.can_research(research.id):
			line_color = Color(1.0, 0.8, 0.0, 0.7)  # Yellow - available
	
	# Calculate control points for bezier curve
	var ctrl_offset = (to_pos - from_pos) * 0.5
	var ctrl1 = from_pos + Vector2(ctrl_offset.x, 0)
	var ctrl2 = to_pos - Vector2(ctrl_offset.x, 0)
	
	# Draw the bezier curve (Godot 4 uses draw_polyline with bezier points)
	var points = []
	var segments = 16
	for i in range(segments + 1):
		var t = float(i) / segments
		var point = bezier_point(from_pos, ctrl1, ctrl2, to_pos, t)
		points.append(point)
	
	draw_polyline(PackedVector2Array(points), line_color, 3.0)

func bezier_point(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	"""Calculate point on cubic bezier curve"""
	var u = 1.0 - t
	var tt = t * t
	var uu = u * u
	var uuu = uu * u
	var ttt = tt * t
	
	var p = p0 * uuu
	p += p1 * 3.0 * uu * t
	p += p2 * 3.0 * u * tt
	p += p3 * ttt
	
	return p

