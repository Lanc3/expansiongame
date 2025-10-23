extends ColorRect
## Renders fog of war overlay using shader

var fog_shader: ShaderMaterial
var fog_texture: ImageTexture
var current_zone_id: int = 1
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
	"""Update shader uniforms with current camera and zone data"""
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
	
	fog_shader.set_shader_parameter("camera_position", camera.global_position)
	fog_shader.set_shader_parameter("zone_offset", bounds.position)
	fog_shader.set_shader_parameter("zone_size", bounds.size)
	fog_shader.set_shader_parameter("tile_size", FogOfWarManager.TILE_SIZE)
	fog_shader.set_shader_parameter("camera_zoom", 1.0 / camera_zoom)  # Inverse zoom for world space conversion
	fog_shader.set_shader_parameter("viewport_size", viewport_size_vec)

func update_fog_texture():
	"""Generate fog texture from fog grid"""
	if not FogOfWarManager:
		return
	
	var grid = FogOfWarManager.get_fog_grid(current_zone_id)
	if grid.is_empty():
		return
	
	var width = grid[0].size()
	var height = grid.size()
	
	# Create image from fog grid
	var image = Image.create(width, height, false, Image.FORMAT_L8)
	
	for y in range(height):
		for x in range(width):
			var explored = grid[y][x]
			var color = Color.WHITE if explored else Color.BLACK
			image.set_pixel(x, y, color)
	
	# Create texture from image
	if fog_texture:
		fog_texture.update(image)
	else:
		fog_texture = ImageTexture.create_from_image(image)
	
	# Set texture in shader
	if fog_shader:
		fog_shader.set_shader_parameter("fog_texture", fog_texture)
	
	# Mark fog as clean
	FogOfWarManager.clear_fog_dirty(current_zone_id)
	
	print("FogOverlay: Updated fog texture for Zone %d (%dx%d)" % [current_zone_id, width, height])

func _on_zone_switched(from_zone_id: int, to_zone_id: int):
	"""Handle zone switch - load new zone's fog"""
	current_zone_id = to_zone_id
	print("FogOverlay: Switching from Zone %d to Zone %d" % [from_zone_id, to_zone_id])
	update_fog_texture()
	
	# Immediately update shader uniforms for new zone
	update_shader_uniforms()

func _on_fog_updated(zone_id: int):
	"""Handle fog update notification"""
	if zone_id == current_zone_id:
		# Fog will be updated in next _process() call
		pass

