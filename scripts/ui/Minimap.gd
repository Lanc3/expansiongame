extends Panel
## Minimap display showing game world overview

@onready var minimap_rect: ColorRect = $MinimapRect
@onready var viewport_indicator: ColorRect = $ViewportIndicator

@export var minimap_size: Vector2 = Vector2(200, 200)

var camera: Camera2D
var update_interval: float = 0.1  # Update 10 times per second
var time_since_update: float = 0.0
var current_zone_id: int = 1
var world_size: Vector2 = Vector2(4000, 4000)

func _ready():
	# Find camera
	camera = get_tree().current_scene.get_node_or_null("Camera2D")
	if not camera:
		push_error("Minimap: Could not find Camera2D")
	
	# Connect to zone manager
	if ZoneManager:
		ZoneManager.zone_switched.connect(_on_zone_switched)
		current_zone_id = ZoneManager.current_zone_id
		update_world_size()
	
	# Set minimap background
	if minimap_rect:
		minimap_rect.color = Color(0.1, 0.1, 0.15, 0.9)
		minimap_rect.size = minimap_size
		minimap_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Setup viewport indicator
	if viewport_indicator:
		viewport_indicator.color = Color(0.3, 0.5, 1.0, 0.25)  # Blue and more transparent
		viewport_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		viewport_indicator.z_index = 10  # Draw on top
	else:
		push_error("Minimap: ViewportIndicator not found")
	
	# Set panel size
	custom_minimum_size = minimap_size

func _process(delta: float):
	time_since_update += delta
	
	if time_since_update >= update_interval:
		time_since_update = 0.0
		update_minimap()
		update_viewport_indicator()

func _draw():
	# Draw all entities on the minimap
	draw_entities()

func update_minimap():
	queue_redraw()  # Request a redraw

func _on_zone_switched(from_zone_id: int, to_zone_id: int):
	"""Handle zone switch"""
	current_zone_id = to_zone_id
	update_world_size()

func update_world_size():
	"""Update world size based on current zone"""
	if ZoneManager:
		var zone = ZoneManager.get_zone(current_zone_id)
		if not zone.is_empty():
			var bounds = zone.boundaries
			world_size = bounds.size
			print("Minimap: Updated world size to ", world_size, " for Zone ", current_zone_id)

func draw_entities():
	# Draw fog of war first (as background)
	if FogOfWarManager:
		draw_fog_overlay()
	
	# Only draw entities from current zone
	var zone_resources = EntityManager.get_resources_in_zone(current_zone_id)
	var zone_units = EntityManager.get_units_in_zone(current_zone_id)
	
	# Draw resources (only if revealed)
	for resource in zone_resources:
		if is_instance_valid(resource):
			# Check if position is revealed
			if FogOfWarManager and not FogOfWarManager.is_position_revealed(current_zone_id, resource.global_position):
				continue  # Skip unrevealed resources
			
			var minimap_pos = world_to_minimap(resource.global_position)
			var color = get_resource_color(resource)
			draw_circle(minimap_pos, 2.0, color)
	
	# Draw units (only if revealed)
	for unit in zone_units:
		if is_instance_valid(unit):
			# Check if position is revealed
			if FogOfWarManager and not FogOfWarManager.is_position_revealed(current_zone_id, unit.global_position):
				continue  # Skip unrevealed units
			
			var minimap_pos = world_to_minimap(unit.global_position)
			var color = get_unit_color(unit)
			draw_circle(minimap_pos, 3.0, color)
	
	# Draw enemy buildings (spawners and turrets) - only if revealed
	var enemy_buildings = get_tree().get_nodes_in_group("enemy_buildings")
	for building in enemy_buildings:
		if is_instance_valid(building):
			# Only draw if in current zone and revealed
			if ZoneManager and ZoneManager.get_unit_zone(building) == current_zone_id:
				if FogOfWarManager and not FogOfWarManager.is_position_revealed(current_zone_id, building.global_position):
					continue  # Skip unrevealed buildings
				
				var minimap_pos = world_to_minimap(building.global_position)
				
				# Different visuals for spawners vs turrets
				if building.is_in_group("spawners"):
					# Spawners: Larger pulsing red squares
					var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.004) * 0.2
					var spawner_color = Color(1.0, 0.2, 0.2) * pulse
					draw_rect(Rect2(minimap_pos - Vector2(4, 4), Vector2(8, 8)), spawner_color)
					# Outline
					draw_rect(Rect2(minimap_pos - Vector2(4, 4), Vector2(8, 8)), Color.WHITE, false, 1.0)
				elif building.is_in_group("turrets"):
					# Turrets: Smaller red squares
					draw_rect(Rect2(minimap_pos - Vector2(2.5, 2.5), Vector2(5, 5)), Color(0.8, 0.3, 0.3))
	
	# Draw wormholes (prominent markers) - only if revealed
	var wormholes = get_tree().get_nodes_in_group("wormholes")
	for wormhole in wormholes:
		if is_instance_valid(wormhole):
			# Only draw wormhole if it's in current zone and revealed
			if ZoneManager and ZoneManager.get_unit_zone(wormhole) == current_zone_id:
				if FogOfWarManager and not FogOfWarManager.is_position_revealed(current_zone_id, wormhole.global_position):
					continue  # Skip unrevealed wormholes
				
				var minimap_pos = world_to_minimap(wormhole.global_position)
				
				# Different colors for forward vs return wormholes
				var is_forward = wormhole.get_meta("is_forward", true)
				var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.005) * 0.3
				var wormhole_color = Color(0.7, 0.4, 1.0) * pulse if is_forward else Color(0.4, 0.7, 1.0) * pulse
				
				draw_circle(minimap_pos, 5.0, wormhole_color)
				# Draw outline
				draw_arc(minimap_pos, 6.0, 0, TAU, 16, Color.WHITE, 1.0)

func world_to_minimap(world_pos: Vector2) -> Vector2:
	# Convert world coordinates to minimap coordinates
	# Get current zone to properly center the map
	var zone = ZoneManager.get_zone(current_zone_id) if ZoneManager else {}
	var zone_center = Vector2.ZERO
	
	if not zone.is_empty() and zone.has("boundaries"):
		var bounds: Rect2 = zone.boundaries
		zone_center = bounds.position + bounds.size / 2
	
	# Calculate relative position from zone center
	var relative_pos = world_pos - zone_center
	
	var normalized_x = (relative_pos.x + world_size.x / 2) / world_size.x
	var normalized_y = (relative_pos.y + world_size.y / 2) / world_size.y
	
	return Vector2(
		normalized_x * minimap_size.x,
		normalized_y * minimap_size.y
	)

func minimap_to_world(minimap_pos: Vector2) -> Vector2:
	# Convert minimap coordinates back to world coordinates
	var zone = ZoneManager.get_zone(current_zone_id) if ZoneManager else {}
	var zone_center = Vector2.ZERO
	
	if not zone.is_empty() and zone.has("boundaries"):
		var bounds: Rect2 = zone.boundaries
		zone_center = bounds.position + bounds.size / 2
	
	var normalized_x = minimap_pos.x / minimap_size.x
	var normalized_y = minimap_pos.y / minimap_size.y
	
	var relative_world_pos = Vector2(
		(normalized_x * world_size.x) - world_size.x / 2,
		(normalized_y * world_size.y) - world_size.y / 2
	)
	
	return relative_world_pos + zone_center

func draw_fog_overlay():
	"""Draw black overlay for unexplored tiles on minimap"""
	if not FogOfWarManager:
		return
	
	var grid = FogOfWarManager.get_fog_grid(current_zone_id)
	if grid.is_empty():
		return
	
	var grid_height = grid.size()
	var grid_width = grid[0].size()
	
	# Calculate tile size on minimap
	var tile_size_minimap = Vector2(
		minimap_size.x / grid_width,
		minimap_size.y / grid_height
	)
	
	# Draw black rectangles for unexplored tiles
	for y in range(grid_height):
		for x in range(grid_width):
			if not grid[y][x]:  # Unexplored
				var tile_pos = Vector2(x * tile_size_minimap.x, y * tile_size_minimap.y)
				draw_rect(Rect2(tile_pos, tile_size_minimap), Color(0, 0, 0, 0.8))

func get_resource_color(resource: Node2D) -> Color:
	# Show brown for unscanned asteroids
	if not resource.is_scanned:
		return Color(0.6, 0.5, 0.4)  # Brown
	
	# For scanned asteroids, show color of most valuable resource
	if resource.has_method("get_composition_display"):
		var composition = resource.get_composition_display()
		if not composition.is_empty():
			# First entry is most valuable (sorted by amount)
			return composition[0].color
	
	return Color(0.5, 0.5, 0.5)  # Fallback gray

func get_unit_color(unit: Node2D) -> Color:
	
	if unit.team_id == 0:
	# Player units - green
		return Color(0.2, 1.0, 0.3)
	else:
			# Enemy units - red
		return Color(1.0, 0.2, 0.2)
	 # Unknown - yellow

func update_viewport_indicator():
	if not camera or not viewport_indicator:
		return
	
	# Calculate visible area in world space
	var viewport_size = camera.get_viewport_rect().size
	var viewport_world_size = viewport_size / camera.zoom
	var camera_pos = camera.global_position
	
	# Convert camera center to minimap space
	var camera_minimap_pos = world_to_minimap(camera_pos)
	
	# Calculate the size of the viewport in minimap space
	var size_minimap = Vector2(
		viewport_world_size.x / world_size.x * minimap_size.x,
		viewport_world_size.y / world_size.y * minimap_size.y
	)
	
	# Position the viewport indicator (centered on camera position)
	viewport_indicator.position = camera_minimap_pos - size_minimap / 2
	viewport_indicator.size = size_minimap
	viewport_indicator.visible = true

func _gui_input(event: InputEvent):
	# Click on minimap to move camera or select wormhole
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var local_click = event.position
			
			# Check if clicking near a wormhole
			var clicked_wormhole = get_wormhole_at_minimap_position(local_click)
			if clicked_wormhole:
				# Jump to wormhole and select it
				if camera:
					camera.global_position = clicked_wormhole.global_position
				if clicked_wormhole.has_method("select_wormhole"):
					clicked_wormhole.select_wormhole()
				return
			
			# Otherwise move camera
			var world_pos = minimap_to_world(local_click)
			if camera:
				camera.global_position = world_pos

func get_wormhole_at_minimap_position(minimap_pos: Vector2) -> Node2D:
	"""Check if click is near a wormhole on minimap"""
	var wormholes = get_tree().get_nodes_in_group("wormholes")
	var click_threshold = 8.0  # pixels on minimap
	
	for wormhole in wormholes:
		if is_instance_valid(wormhole):
			if ZoneManager and ZoneManager.get_unit_zone(wormhole) == current_zone_id:
				var wormhole_minimap_pos = world_to_minimap(wormhole.global_position)
				if minimap_pos.distance_to(wormhole_minimap_pos) < click_threshold:
					return wormhole
	
	return null
