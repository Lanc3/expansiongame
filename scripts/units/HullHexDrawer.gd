extends Node2D
## Helper node to draw textured hexagon hull cells

func _draw():
	var vertices = get_meta("vertices", PackedVector2Array())
	var texture = get_meta("texture", null)
	var uv_coords = get_meta("uv_coords", PackedVector2Array())
	var hull_type = get_meta("hull_type", 0)
	
	if vertices.is_empty():
		return
	
	if texture and uv_coords.size() == vertices.size():
		# Draw textured polygon
		draw_polygon(vertices, [], uv_coords, texture)
	else:
		# Fallback to colored polygon
		var color = CosmoteerComponentDefs.get_hull_color(hull_type)
		draw_colored_polygon(vertices, color)

