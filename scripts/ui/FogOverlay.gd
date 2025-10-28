extends ColorRect
## Renders fog of war overlay using shader

var fog_shader: ShaderMaterial
var fog_texture: ImageTexture
var current_zone_id: String = ""
var camera: Camera2D

func _ready():
	# Setup shader material
	var shader = load("res://shaders/fog_of_war.gdshader")
	fog_shader = ShaderMaterial.new()
	fog_shader.shader = shader
	material = fog_shader
	
	# Find camera
	camera = get_tree().current_scene.get_node_or_null("Camera2D")
	
	# Make fullscreen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Connect to zone manager
	if ZoneManager:
		ZoneManager.zone_switched.connect(_on_zone_switched)
		current_zone_id = ZoneManager.current_zone_id
	
	# Connect to fog manager
	if FogOfWarManager:
		FogOfWarManager.fog_updated.connect(_on_fog_updated)
	
	# Initial fog texture generation
	update_fog_texture()

func _process(_delta: float):
	if not camera or not fog_shader:
		return
	
	# Update shader uniforms
	update_shader_uniforms()
	
	# Regenerate fog texture if dirty
	if FogOfWarManager and FogOfWarManager.is_fog_dirty(current_zone_id):
		update_fog_texture()

func update_shader_uniforms():
	"""Update shader uniforms with current camera and zone data (with adaptive tile size)"""
	if not fog_shader or not camera:
		return
	
	var zone = ZoneManager.get_zone(current_zone_id)
	if zone.is_empty():
		return
	
	var bounds = zone.boundaries
	var viewport = get_viewport()
	var viewport_size_vec = viewport.get_visible_rect().size
	
	# Get camera zoom (camera.zoom is a Vector2, we use x component)
	var camera_zoom = camera.zoom.x if camera.zoom else 1.0
	
	# Get adaptive tile size for current zone
	var tile_size = FogOfWarManager.get_tile_size(current_zone_id)
	
	# Debug: Log shader parameters when zone changes or periodically
	if Engine.get_frames_drawn() % 300 == 0:  # Every 5 seconds at 60fps
		var grid = FogOfWarManager.get_fog_grid(current_zone_id)
		var grid_size = Vector2i(grid[0].size() if not grid.is_empty() else 0, grid.size())
		print("FogOverlay DEBUG Zone %s:" % current_zone_id)
		print("  - Zone bounds: pos=%s size=%s" % [bounds.position, bounds.size])
		print("  - Fog grid: %dx%d tiles, tile_size=%.0fpx" % [grid_size.x, grid_size.y, tile_size])
		print("  - Expected coverage: %.0fx%.0f = %.0fx%.0f" % [grid_size.x * tile_size, grid_size.y * tile_size, bounds.size.x, bounds.size.y])
	
	fog_shader.set_shader_parameter("camera_position", camera.global_position)
	fog_shader.set_shader_parameter("zone_offset", bounds.position)
	fog_shader.set_shader_parameter("zone_size", bounds.size)
	fog_shader.set_shader_parameter("tile_size", tile_size)
	fog_shader.set_shader_parameter("camera_zoom", 1.0 / camera_zoom)  # Inverse zoom for world space conversion
	fog_shader.set_shader_parameter("viewport_size", viewport_size_vec)

func update_fog_texture():
	"""Generate fog texture from fog grid with partial update optimization"""
	if not FogOfWarManager:
		return
	
	var grid = FogOfWarManager.get_fog_grid(current_zone_id)
	if grid.is_empty():
		return
	
	var width = grid[0].size()
	var height = grid.size()
	
	# Check if we can do a partial update (dirty region exists and texture already exists)
	var dirty_region = FogOfWarManager.get_dirty_region(current_zone_id)
	var can_partial_update = fog_texture != null and not dirty_region.is_empty()
	
	# Also check texture size matches grid size (prevents partial update after zone switch)
	if can_partial_update and fog_texture:
		var texture_size = fog_texture.get_size()
		if texture_size.x != width or texture_size.y != height:
			can_partial_update = false  # Size changed, need full regeneration
	
	if can_partial_update:
		# OPTIMIZATION: Partial texture update for changed region only
		var min_tile = dirty_region.min
		var max_tile = dirty_region.max
		var region_width = max_tile.x - min_tile.x + 1
		var region_height = max_tile.y - min_tile.y + 1
		
		# Only do partial update if region is small enough (< 50% of texture)
		var region_pixels = region_width * region_height
		var total_pixels = width * height
		if region_pixels < total_pixels * 0.5:
			# Get existing image from texture
			var image = fog_texture.get_image()
			
			# Update only the dirty region
			for y in range(min_tile.y, max_tile.y + 1):
				for x in range(min_tile.x, max_tile.x + 1):
					if y >= 0 and y < height and x >= 0 and x < width:
						var explored = grid[y][x]
						var color = Color.WHITE if explored else Color.BLACK
						image.set_pixel(x, y, color)
			
			# Update texture with modified image
			fog_texture.update(image)
			
			# Mark fog as clean
			FogOfWarManager.clear_fog_dirty(current_zone_id)
			FogOfWarManager.clear_dirty_region(current_zone_id)
			
			#print("FogOverlay: Partial update Zone %s (%dx%d region)" % [current_zone_id, region_width, region_height])
			return
	
	# Full texture regeneration (first time or large changes)
	var image = Image.create(width, height, false, Image.FORMAT_L8)
	
	for y in range(height):
		for x in range(width):
			var explored = grid[y][x]
			var color = Color.WHITE if explored else Color.BLACK
			image.set_pixel(x, y, color)
	
	# Check if texture size changed - need to recreate texture
	var texture_size_changed = false
	if fog_texture:
		var old_size = fog_texture.get_size()
		texture_size_changed = (old_size.x != width or old_size.y != height)
	
	# Create or update texture
	if fog_texture and not texture_size_changed:
		# Same size - can update existing texture
		fog_texture.update(image)
	else:
		# New texture or size changed - must recreate
		fog_texture = ImageTexture.create_from_image(image)
		
		# Set texture in shader (required for new texture)
		if fog_shader:
			fog_shader.set_shader_parameter("fog_texture", fog_texture)
	
	# Always update shader parameter for consistency
	if fog_shader and not texture_size_changed:
		fog_shader.set_shader_parameter("fog_texture", fog_texture)
	
	# Mark fog as clean
	FogOfWarManager.clear_fog_dirty(current_zone_id)
	FogOfWarManager.clear_dirty_region(current_zone_id)
	
	if texture_size_changed:
		print("FogOverlay: RECREATED texture for Zone %s (%dx%d) - size changed!" % [current_zone_id, width, height])
	else:
		print("FogOverlay: Full texture update Zone %s (%dx%d)" % [current_zone_id, width, height])

func _on_zone_switched(from_zone_id: String, to_zone_id: String):
	"""Handle zone switch - load new zone's fog"""
	current_zone_id = to_zone_id
	update_fog_texture()
	
	# Immediately update shader uniforms for new zone
	update_shader_uniforms()

func _on_fog_updated(zone_id: String):
	"""Handle fog update notification"""
	if zone_id == current_zone_id:
		# Fog will be updated in next _process() call
		pass

