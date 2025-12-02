extends BaseUnit
class_name CustomShip
## Runtime-assembled ship from a blueprint layout

var placements: Array = []
var cell_px: float = 7.5  # Half of CELL_SIZE from CosmoteerShipGrid (15.0 / 2)
var cosmoteer_blueprint: CosmoteerShipBlueprint = null

# Weapon system
var weapon_components: Array[WeaponComponent] = []
var weapon_enabled: Array[bool] = []  # Track which weapons are enabled
var weapon_positions: Array[Vector2] = []  # Local positions of weapons on ship
var weapon_turrets: Array[Sprite2D] = []  # Visual turret sprites
var turret_recoil: Array[float] = []  # Recoil animation state per turret (0.0 = no recoil, 1.0 = full recoil)
var turret_base_positions: Array[Vector2] = []  # Base positions of turrets (for recoil translation)

# Shield system
var shield_component: ShieldComponent = null
var shield_visual_node: ColorRect = null
var shield_hit_timer: float = 0.0

# Aim Visuals (manual aiming)
var aim_visuals: Node2D = null

# Range indicators (removed)
var weapon_targets: Array[Node2D] = []  # Target for each weapon (independent targeting)

# Weapon panel UI
var weapon_panel: ShipWeaponPanel = null

# Engine beam system
var engine_particles: Array = []  # Array of dictionaries: {beam, effect, local_position} - beam is EngineBeam2D
var engine_thrust_direction: Vector2 = Vector2.ZERO  # Cached from blueprint
var selection_ring_effect: Node = null

# Cargo system for mining components
@export var max_cargo: float = 0.0
var carrying_resources: float = 0.0
var cargo_by_type: Dictionary = {}
var return_target: Node2D = null
var last_mined_resource: Node2D = null
var cargo_indicator: Control = null
var cargo_indicator_scene: PackedScene = null

# Destructible hull system
var hull_cell_data: Dictionary = {}  # Vector2i (hex pos) -> {health, max_health, hull_type, visual_node}
var runtime_blueprint: CosmoteerShipBlueprint = null  # Runtime copy of blueprint for modifications
var component_panel: Control = null
var component_command_mode: String = ""  # "", "scan", "mine"
var _attack_cursor: Texture2D = null
var scanner_components: Array = []
var mining_components: Array = []
var attack_ground_marker: Node2D = null
var attack_ground_active: bool = false
var active_weapon_indices: Array = []

# Weapon attack marker system
var weapon_markers: Array = []  # One marker per weapon (null if no marker set)
var marker_scene: PackedScene = null
var _right_click_was_pressed: bool = false  # For detecting "just pressed"

func _ready():
	super._ready()
	unit_name = "Custom Ship"
	
	# Add to proper groups for selection and combat
	add_to_group("units")
	add_to_group("player_units")
	
	# Load and create cargo indicator (floating UI like MiningDrone)
	cargo_indicator_scene = preload("res://scenes/ui/CargoIndicator.tscn")
	_create_cargo_indicator()
	
	# Load weapon marker scene
	marker_scene = preload("res://scenes/ui/WeaponAttackMarker.tscn")
	
	# Create aim visuals node
	aim_visuals = Node2D.new()
	aim_visuals.name = "AimVisuals"
	aim_visuals.z_index = 100 # Always on top
	aim_visuals.set_script(load("res://scripts/units/AimVisuals.gd")) # We'll create this script dynamically or inline
	# For simplicity, let's use inline drawing logic via _draw signal or just a child node with _draw
	# Actually, connecting to a draw function on the ship or using a dedicated script is cleaner.
	# Let's use a dedicated script for the AimVisuals node to handle its own drawing
	var script = GDScript.new()
	script.source_code = """
extends Node2D

var ship: Node2D = null

func _process(_delta):
	queue_redraw()

func _draw():
	if not is_instance_valid(ship) or not "active_weapon_indices" in ship or not "weapon_turrets" in ship:
		return
		
	var mouse_pos = get_global_mouse_position()
	var indices = ship.active_weapon_indices
	
	if indices.is_empty():
		return
		
	for i in indices:
		if i < ship.weapon_turrets.size():
			var turret = ship.weapon_turrets[i]
			if is_instance_valid(turret):
				var start_pos = turret.global_position
				# Draw line from turret to mouse
				draw_line(to_local(start_pos), to_local(mouse_pos), Color(1, 0, 0, 0.5), 2.0)
				
				# Draw arrow head at mouse
				var dir = (mouse_pos - start_pos).normalized()
				var arrow_size = 15.0
				var end_pos = to_local(mouse_pos)
				var angle = dir.angle()
				var p1 = end_pos + Vector2(cos(angle + 2.5), sin(angle + 2.5)) * arrow_size
				var p2 = end_pos + Vector2(cos(angle - 2.5), sin(angle - 2.5)) * arrow_size
				draw_line(end_pos, p1, Color(1, 0, 0, 0.8), 2.0)
				draw_line(end_pos, p2, Color(1, 0, 0, 0.8), 2.0)
"""
	if script.reload() == OK:
		aim_visuals.set_script(script)
		aim_visuals.set("ship", self)
		add_child(aim_visuals)
	else:
		push_error("Failed to load AimVisuals script")

func _process(delta: float):
	"""Process per-weapon targeting and firing"""
	super._process(delta)
	
	# Process weapon targeting and firing independently
	_process_weapon_targeting(delta)
	_process_weapon_firing(delta)
	
	# Update turret rotations based on per-weapon targets (Auto)
	# _update_turret_rotations(delta) # Only for non-manual weapons
	
	# Manual Control Logic (Aiming & Firing)
	var mouse_pos = get_global_mouse_position()
	var visual_container = get_node_or_null("VisualContainer")
	
	if not active_weapon_indices.is_empty() and visual_container:
		# Manual Aiming: Rotate selected turrets toward mouse OR their markers
		var container_global_rotation = rotation + visual_container.rotation
		
		for i in active_weapon_indices:
			if i < weapon_turrets.size():
				var turret = weapon_turrets[i]
				if is_instance_valid(turret):
					# Determine target position: marker if exists, otherwise mouse
					var target_pos = mouse_pos
					if _has_weapon_marker(i):
						target_pos = _get_weapon_marker_position(i)
					
					# Calculate direction from turret to target
					var turret_world_pos = turret.global_position
					var direction_to_target = (target_pos - turret_world_pos).normalized()
					var target_angle_world = direction_to_target.angle()
					
					# Calculate local rotation needed (add PI/2 for 90-degree offset)
					var turret_local_rotation = target_angle_world - container_global_rotation + PI / 2.0
					
					# Instant rotation for manual control feels snappier
					turret.rotation = turret_local_rotation
					
					# Apply recoil as position offset (turret moves backward when firing)
					if i < turret_recoil.size() and i < turret_base_positions.size():
						var recoil_amount = turret_recoil[i]
						if recoil_amount > 0.0:
							# Calculate backward direction (opposite of turret's forward direction)
							# Turret rotation has PI/2 offset, so actual forward is rotation - PI/2
							var actual_forward_angle = turret.rotation - PI / 2.0
							var forward_dir = Vector2(cos(actual_forward_angle), sin(actual_forward_angle))
							var backward_dir = -forward_dir
							# Move turret backward by recoil amount (max 8 pixels)
							var recoil_offset = backward_dir * recoil_amount * 8.0
							turret.position = turret_base_positions[i] + recoil_offset
						else:
							turret.position = turret_base_positions[i]
					else:
						turret.position = turret_base_positions[i] if i < turret_base_positions.size() else turret.position
		
		# Right-click places markers for selected weapons (not direct firing)
		var right_click_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		if right_click_pressed and not _right_click_was_pressed:
			_place_markers_for_selected_weapons(mouse_pos)
		_right_click_was_pressed = right_click_pressed
	else:
		# Track right-click state even when no weapons selected
		_right_click_was_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	
	# Update auto-turrets (only those NOT selected manually)
	_update_turret_rotations_auto(delta)
	
	# Update turret recoil animation
	_update_turret_recoil(delta)
	
	# Update cargo UI
	_update_cargo_bar()
	
	# Update shield visual
	if shield_visual_node and is_instance_valid(shield_visual_node):
		if shield_hit_timer > 0.0:
			shield_hit_timer -= delta
			var strength = clamp(shield_hit_timer, 0.0, 1.0)
			if shield_visual_node.material:
				shield_visual_node.material.set_shader_parameter("hit_strength", strength)
		
		# Ensure shield is visible only if we have shield HP
		if shield_component and shield_component.current_shield <= 0:
			shield_visual_node.visible = false
		elif shield_component and shield_component.current_shield > 0:
			shield_visual_node.visible = true

func process_current_command(delta: float):
	"""Override to prevent idle drift behavior - CustomShip should stop when idle"""
	# Handle IDLE state specially - stop movement instead of drifting
	if ai_state == AIState.IDLE:
		velocity = Vector2.ZERO
		return
	
	# For all other states, use parent class behavior
	super.process_current_command(delta)

func _exit_tree():
	for entry in engine_particles:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var effect = entry.get("effect")
		if effect and is_instance_valid(effect):
			effect.queue_free()
	engine_particles.clear()
	for c in scanner_components:
		if is_instance_valid(c):
			c.queue_free()
	scanner_components.clear()
	for c in mining_components:
		if is_instance_valid(c):
			c.queue_free()
	mining_components.clear()
	if is_instance_valid(cargo_indicator):
		cargo_indicator.queue_free()
	_clear_selection_ring()
	_clear_all_weapon_markers()

func initialize_from_blueprint(data: Dictionary):
	"""Legacy blueprint system"""
	if data.has("placements"):
		placements = data["placements"]
	_build_visuals()

func initialize_from_cosmoteer_blueprint(blueprint: CosmoteerShipBlueprint):
	"""Initialize from Cosmoteer-style blueprint"""
	cosmoteer_blueprint = blueprint
	
	# Create runtime copy of blueprint for modifications
	runtime_blueprint = blueprint.duplicate_blueprint()
	
	# Apply stats from blueprint
	apply_blueprint_stats(blueprint)
	
	# Build visual representation
	_build_visuals_cosmoteer(blueprint)
	
	# Instantiate functional components (needs to happen after visuals for VisualContainer access)
	_instantiate_weapon_components(blueprint)
	_instantiate_shield_components(blueprint)
	_instantiate_engine_particles(blueprint)
	
	# Initialize weapon markers array
	_init_weapon_markers()
	
	# Recalculate cargo capacity based on mining components (100 per miner)
	_recalc_cargo_capacity()
	
	# Create UI elements (range indicators removed for manual aim system)
	
	# Set unit name from blueprint
	unit_name = blueprint.blueprint_name
	
	# Store blueprint reference
	set_meta("source_blueprint", blueprint.blueprint_name)
	set_meta("blueprint_type", "cosmoteer")
	
	print("CustomShip '%s' initialized with %d weapons" % [unit_name, weapon_components.size()])

func apply_blueprint_stats(blueprint: CosmoteerShipBlueprint):
	"""Calculate and apply stats from blueprint"""
	# Health will be calculated from hull cells after visuals are built
	# Initial health calculation happens in _update_ship_health()
	
	# Speed from calculator
	move_speed = CosmoteerShipStatsCalculator.calculate_speed(blueprint)
	
	# Other stats
	var power = CosmoteerShipStatsCalculator.calculate_power(blueprint)
	set_meta("power_generated", power.get("generated", 0))
	set_meta("power_consumed", power.get("consumed", 0))
	
	var weight_thrust = CosmoteerShipStatsCalculator.calculate_weight_thrust(blueprint)
	set_meta("weight", weight_thrust.get("weight", 0))
	set_meta("thrust", weight_thrust.get("thrust", 0))
	
	print("CustomShip stats applied: Speed=%.1f" % move_speed)

func _update_ship_health():
	"""Update ship health from sum of all hull cell health"""
	var total_health: float = 0.0
	for hex_pos in hull_cell_data.keys():
		var cell_data = hull_cell_data[hex_pos]
		total_health += cell_data.get("health", 0.0)
	
	max_health = total_health
	current_health = total_health


func _build_visuals_cosmoteer(blueprint: CosmoteerShipBlueprint):
	"""Build visual representation from Cosmoteer blueprint"""
	# Clear existing visual container
	var existing_visual = get_node_or_null("VisualContainer")
	if existing_visual:
		existing_visual.queue_free()
	
	# Create a rotated visual container for the ship graphics
	var visual_container = Node2D.new()
	visual_container.name = "VisualContainer"
	
	# Calculate rotation from blueprint's forward_direction
	# The old hardcoded rotation was -PI/2 for forward_direction (0, -1)
	# When forward_direction rotates by Δθ in the builder, visual rotation needs to compensate by -Δθ
	# Formula: rotation = default_rotation - (forward_angle - default_forward_angle) + PI (180° correction)
	var forward_angle = blueprint.forward_direction.angle()
	var default_forward_angle = Vector2(0, -1).angle()  # -PI/2
	var default_rotation = -PI / 2.0  # Worked for default forward_direction
	visual_container.rotation = default_rotation - (forward_angle - default_forward_angle) + PI
	add_child(visual_container)
	
	# Calculate bounding box to properly center the ship (using hex coordinates)
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	# Convert hex positions to pixel positions to find bounds
	for hull_pos in blueprint.hull_cells.keys():
		var pixel_pos = HexGrid.hex_to_pixel(hull_pos, cell_px)
		var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, cell_px)
		# Check all vertices of hexagon for bounds
		for vertex in hex_vertices:
			min_x = min(min_x, vertex.x)
			max_x = max(max_x, vertex.x)
			min_y = min(min_y, vertex.y)
			max_y = max(max_y, vertex.y)
	
	# Calculate center offset from pixel bounds
	var center_offset = Vector2(
		(min_x + max_x) * 0.5,
		(min_y + max_y) * 0.5
	)
	
	# Initialize hull cell data and render hull cells in the visual container (using hex grid)
	hull_cell_data.clear()
	for hull_pos in blueprint.hull_cells.keys():
		var hull_type = blueprint.get_hull_type(hull_pos)
		var texture_path = CosmoteerComponentDefs.get_hull_texture(hull_type)
		
		# Calculate max health based on hull type
		var max_hp: float = 5.0  # Light
		match hull_type:
			CosmoteerShipBlueprint.HullType.MEDIUM:
				max_hp = 15.0
			CosmoteerShipBlueprint.HullType.HEAVY:
				max_hp = 30.0
		
		# Convert hex coordinates to pixel position
		var pixel_pos = HexGrid.hex_to_pixel(hull_pos, cell_px)
		var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, cell_px)
		
		# Adjust vertices relative to center offset
		var adjusted_vertices = PackedVector2Array()
		for vertex in hex_vertices:
			adjusted_vertices.append(vertex - center_offset)
		
		var visual_node: Node2D = null
		
		# Try to use texture, fallback to colored hexagon
		if texture_path and ResourceLoader.exists(texture_path):
			var texture = load(texture_path)
			if texture:
				# Use Node2D with _draw() to render textured hexagon (like CosmoteerShipGrid does)
				var hull_drawer = Node2D.new()
				hull_drawer.set_script(load("res://scripts/units/HullHexDrawer.gd"))
				hull_drawer.z_index = -1
				
				# Calculate UV coordinates for texture mapping
				var bounds = _get_hex_bounds_from_vertices(adjusted_vertices)
				var uv_coords = PackedVector2Array()
				for vertex in adjusted_vertices:
					var uv_x = (vertex.x - bounds.position.x) / bounds.size.x if bounds.size.x > 0 else 0.5
					var uv_y = (vertex.y - bounds.position.y) / bounds.size.y if bounds.size.y > 0 else 0.5
					uv_coords.append(Vector2(uv_x, uv_y))
				
				# Set data for drawing
				hull_drawer.set_meta("vertices", adjusted_vertices)
				hull_drawer.set_meta("uv_coords", uv_coords)
				hull_drawer.set_meta("texture", texture)
				hull_drawer.set_meta("hull_type", hull_type)
				visual_container.add_child(hull_drawer)
				visual_node = hull_drawer
			else:
				# Fallback to colored hexagon
				var hull_polygon = Polygon2D.new()
				hull_polygon.polygon = adjusted_vertices
				hull_polygon.color = CosmoteerComponentDefs.get_hull_color(hull_type)
				hull_polygon.z_index = -1
				visual_container.add_child(hull_polygon)
				visual_node = hull_polygon
		else:
			# Fallback to colored hexagon
			var hull_polygon = Polygon2D.new()
			hull_polygon.polygon = adjusted_vertices
			hull_polygon.color = CosmoteerComponentDefs.get_hull_color(hull_type)
			hull_polygon.z_index = -1
			visual_container.add_child(hull_polygon)
			visual_node = hull_polygon
		
		# Store hull cell data
		# Store base modulate (white for full brightness) and node type for color management
		var base_modulate = Color.WHITE
		var is_polygon = visual_node is Polygon2D
		hull_cell_data[hull_pos] = {
			"health": max_hp,
			"max_health": max_hp,
			"hull_type": hull_type,
			"visual_node": visual_node,
			"local_position": pixel_pos - center_offset,
			"base_modulate": base_modulate,
			"is_polygon": is_polygon
		}
	
	# Update ship health from hull cells
	_update_ship_health()
	
	# Render components on top in the visual container
	for comp_data in blueprint.components:
		var comp_type = comp_data.get("type", "")
		var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
		var comp_size = comp_data.get("size", Vector2i.ONE)
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_type)
		
		if comp_def.is_empty():
			continue
		
		var sprite_path = comp_def.get("sprite", "")
		
		# Get hex cells occupied by this component
		var hex_cells = HexGrid.get_component_hex_cells(comp_pos, comp_size)
		
		# Calculate center position from hex cells
		var center_hex = Vector2.ZERO
		for hex_pos in hex_cells:
			center_hex += HexGrid.hex_to_pixel(hex_pos, cell_px)
		center_hex /= hex_cells.size()
		
		# Try to use texture, fallback to colored rectangle
		if sprite_path and ResourceLoader.exists(sprite_path):
			var texture = load(sprite_path)
			if texture:
				var comp_sprite = Sprite2D.new()
				comp_sprite.texture = texture
				# Position at center of component hex cells
				comp_sprite.position = center_hex - center_offset
				comp_sprite.centered = true
				# Calculate bounding box from hex cells for scaling
				var comp_min_x = INF
				var comp_max_x = -INF
				var comp_min_y = INF
				var comp_max_y = -INF
				for hex_pos in hex_cells:
					var pixel_pos = HexGrid.hex_to_pixel(hex_pos, cell_px)
					var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, cell_px)
					for vertex in hex_vertices:
						comp_min_x = min(comp_min_x, vertex.x)
						comp_max_x = max(comp_max_x, vertex.x)
						comp_min_y = min(comp_min_y, vertex.y)
						comp_max_y = max(comp_max_y, vertex.y)
				var target_size = Vector2(comp_max_x - comp_min_x, comp_max_y - comp_min_y)
				var texture_size = texture.get_size()
				comp_sprite.scale = Vector2(target_size.x / texture_size.x, target_size.y / texture_size.y)
				
				# Set z_index: weapons go below turret, others at 0
				if comp_type == "laser_weapon" or comp_type == "missile_launcher":
					comp_sprite.z_index = 0  # Below turret (which is at z_index 5)
				else:
					comp_sprite.z_index = 0
				
				visual_container.add_child(comp_sprite)
			else:
				# Fallback to ColorRect
				_create_component_colorrect(comp_type, comp_pos, comp_size, center_offset, visual_container)
		else:
			# Fallback to ColorRect
			_create_component_colorrect(comp_type, comp_pos, comp_size, center_offset, visual_container)
	
	# Generate collision shape from hull
	_generate_collision_from_hull(blueprint)

func _create_component_colorrect(comp_type: String, comp_pos: Vector2i, comp_size: Vector2i, center_offset: Vector2, visual_container: Node2D):
	"""Create colored hexagons fallback for components without textures"""
	var color = Color(0.5, 0.5, 0.8, 0.8)
	
	# Color by component type
	match comp_type:
		"power_core":
			color = Color(0.6, 0.9, 0.6, 0.9)
		"engine":
			color = Color(0.9, 0.6, 0.4, 0.9)
		"laser_weapon", "missile_launcher":
			color = Color(0.9, 0.4, 0.4, 0.9)
		"shield_generator":
			color = Color(0.6, 0.6, 0.9, 0.9)
		"repair_bot":
			color = Color(0.7, 0.7, 0.7, 0.9)
	
	# Get hex cells occupied by this component
	var hex_cells = HexGrid.get_component_hex_cells(comp_pos, comp_size)
	
	# Draw hexagon for each cell
	for hex_pos in hex_cells:
		var pixel_pos = HexGrid.hex_to_pixel(hex_pos, cell_px)
		var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, cell_px)
		
		# Adjust vertices relative to center offset
		var adjusted_vertices = PackedVector2Array()
		for vertex in hex_vertices:
			adjusted_vertices.append(vertex - center_offset)
		
		var comp_polygon = Polygon2D.new()
		comp_polygon.polygon = adjusted_vertices
		comp_polygon.color = color
		comp_polygon.z_index = 0
		visual_container.add_child(comp_polygon)

func _get_hex_bounds_from_vertices(hex_vertices: PackedVector2Array) -> Rect2:
	"""Get bounding rectangle for hex vertices"""
	if hex_vertices.is_empty():
		return Rect2()
	
	var min_x = hex_vertices[0].x
	var max_x = hex_vertices[0].x
	var min_y = hex_vertices[0].y
	var max_y = hex_vertices[0].y
	
	for vertex in hex_vertices:
		min_x = min(min_x, vertex.x)
		max_x = max(max_x, vertex.x)
		min_y = min(min_y, vertex.y)
		max_y = max(max_y, vertex.y)
	
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)

func _generate_collision_from_hull(blueprint: CosmoteerShipBlueprint):
	"""Create collision shape based on hull cells"""
	# Simple approach: use a circle based on hull extent
	var hull_count = blueprint.get_hull_cell_count()
	if hull_count == 0:
		return
	
	# Calculate approximate radius from hex grid bounds
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for hull_pos in blueprint.hull_cells.keys():
		var pixel_pos = HexGrid.hex_to_pixel(hull_pos, cell_px)
		var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, cell_px)
		for vertex in hex_vertices:
			min_x = min(min_x, vertex.x)
			max_x = max(max_x, vertex.x)
			min_y = min(min_y, vertex.y)
			max_y = max(max_y, vertex.y)
	
	var width = max_x - min_x
	var height = max_y - min_y
	var radius = max(width, height) * 0.5
	
	# Create collision shape if it doesn't exist
	var collision_shape = get_node_or_null("CollisionShape2D")
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)
	
	var circle = CircleShape2D.new()
	circle.radius = radius
	collision_shape.shape = circle

func _instantiate_engine_particles(blueprint: CosmoteerShipBlueprint):
	"""Create engine beam effects for engines"""
	# Store thrust direction from blueprint (in blueprint coordinates)
	# This will be rotated to match VisualContainer coordinate system
	var blueprint_thrust_direction = -blueprint.forward_direction  # Opposite of forward = thrust direction
	
	# Get the visual container rotation (same as calculated in _build_visuals_cosmoteer)
	var visual_container = get_node_or_null("VisualContainer")
	var container_rotation = 0.0
	if visual_container:
		container_rotation = visual_container.rotation
	else:
		# Calculate rotation the same way as in _build_visuals_cosmoteer
		var forward_angle = blueprint.forward_direction.angle()
		var default_forward_angle = Vector2(0, -1).angle()  # -PI/2
		var default_rotation = -PI / 2.0
		container_rotation = default_rotation - (forward_angle - default_forward_angle) + PI  # Match _build_visuals_cosmoteer
	
	# Calculate thrust direction as opposite of forward direction (engines exhaust backward)
	# In VisualContainer local space (blueprint coordinate system), thrust points opposite to forward
	engine_thrust_direction = -blueprint.forward_direction.normalized()
	
	# Calculate the same center offset used for visuals (using hex coordinates)
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	# Convert hex positions to pixel positions to find bounds
	for hull_pos in blueprint.hull_cells.keys():
		var pixel_pos = HexGrid.hex_to_pixel(hull_pos, cell_px)
		var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, cell_px)
		# Check all vertices of hexagon for bounds
		for vertex in hex_vertices:
			min_x = min(min_x, vertex.x)
			max_x = max(max_x, vertex.x)
			min_y = min(min_y, vertex.y)
			max_y = max(max_y, vertex.y)
	
	var center_offset = Vector2(
		(min_x + max_x) * 0.5,
		(min_y + max_y) * 0.5
	)
	
	# visual_container already retrieved at the start of function
	if not visual_container:
		return
	
	for comp_data in blueprint.components:
		var comp_id = comp_data.get("type", "")
		var parsed = CosmoteerComponentDefs.parse_component_id(comp_id)
		var comp_type = parsed["type"]
		var comp_level = parsed["level"]
		
		if comp_type == "engine":
			# Existing engine handling (moved into a block)
			var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
			var comp_size = comp_data.get("size", Vector2i.ONE)
			
			# Calculate engine center in local coordinates (using hex grid)
			var hex_cells = HexGrid.get_component_hex_cells(comp_pos, comp_size)
			var center_hex = Vector2.ZERO
			for hex_pos in hex_cells:
				center_hex += HexGrid.hex_to_pixel(hex_pos, cell_px)
			center_hex /= hex_cells.size()
			var engine_local_pos = center_hex - center_offset
			
			# Determine plume configuration based on component level
			var plume_size: StringName = &"small"
			if comp_level >= 7:
				plume_size = &"large"
			elif comp_level >= 4:
				plume_size = &"medium"
			
			var num_streams = 2
			if comp_level >= 7:
				num_streams = 4
			elif comp_level >= 4:
				num_streams = 3
			
			# Calculate beam rotation based on thrust direction
			# EngineBeam2D points DOWN (+Y) by default when rotation is 0
			# We want it to point in the thrust direction (opposite of forward_direction)
			# beam_rotation = angle to rotate from DOWN to thrust_direction
			var beam_rotation = Vector2.DOWN.angle_to(engine_thrust_direction)
			
			# Calculate perpendicular vector for stream offsetting
			# Perpendicular to thrust direction (rotated 90 degrees)
			var perpendicular = engine_thrust_direction.rotated(PI / 2.0)
			
			var stream_offset = cell_px * 0.2
			var intensity = 1.0 + float(comp_level - 1) * 0.12
			
			for stream_idx in range(num_streams):
				var offset_multiplier = 0.0
				if num_streams == 2:
					offset_multiplier = 1.0 if stream_idx == 0 else -1.0
				elif num_streams == 3:
					offset_multiplier = float(stream_idx - 1)
				else:
					offset_multiplier = (stream_idx - 1.5) * 0.7
				
				var stream_pos = engine_local_pos + perpendicular * offset_multiplier * stream_offset
				var beam = VfxDirector.spawn_engine_plume(plume_size, visual_container, stream_pos, beam_rotation, intensity)
				if beam and beam is EngineBeam2D:
					beam.intensity = 0.0
					engine_particles.append({
						"beam": beam,
						"effect": beam,
						"local_position": stream_pos
					})
			continue
		
		# Add scanner/miner components
		if comp_type == "scanner" or comp_type == "miner":
			var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
			var comp_size = comp_data.get("size", Vector2i.ONE)
			var hex_cells = HexGrid.get_component_hex_cells(comp_pos, comp_size)
			var center_hex = Vector2.ZERO
			for hex_pos in hex_cells:
				center_hex += HexGrid.hex_to_pixel(hex_pos, cell_px)
			center_hex /= hex_cells.size()
			var local_pos = center_hex - center_offset
			
			if comp_type == "scanner":
				var scanner_scene = preload("res://scenes/components/ScannerComponent.tscn")
				var scanner = scanner_scene.instantiate() as ScannerComponent
				visual_container.add_child(scanner)
				scanner.position = local_pos
				var def = CosmoteerComponentDefs.get_component_data_by_level("scanner", comp_level)
				scanner.setup_from_defs(def)
				scanner_components.append(scanner)
			elif comp_type == "miner":
				var miner_scene = preload("res://scenes/components/MiningComponent.tscn")
				var miner = miner_scene.instantiate() as MiningComponent
				visual_container.add_child(miner)
				miner.position = local_pos
				# Assign owning ship for cargo delivery
				if "owner_ship" in miner:
					miner.owner_ship = self
				var defm = CosmoteerComponentDefs.get_component_data_by_level("miner", comp_level)
				miner.setup_from_defs(defm)
				mining_components.append(miner)
			continue
		
	
	print("Created %d engine beam systems" % engine_particles.size())

func _recalc_cargo_capacity() -> void:
	# 100 cargo per mining component
	max_cargo = float(mining_components.size() * 100)
	# Clamp carrying_resources to new max
	carrying_resources = min(carrying_resources, max_cargo)
	_update_cargo_bar()

func add_cargo_from_extraction(extracted_by_type: Dictionary) -> float:
	"""Add extracted resources to ship cargo. Returns amount actually accepted (total)."""
	if max_cargo <= 0.0:
		return 0.0
	var available: float = max(0.0, max_cargo - carrying_resources)
	if available <= 0.0:
		return 0.0
	# Sum total requested
	var total_requested: float = 0.0
	for type_id in extracted_by_type.keys():
		total_requested += float(extracted_by_type[type_id])
	# Determine how much we can take
	var total_accepted = min(available, total_requested)
	if total_accepted <= 0.0:
		return 0.0
	# Distribute accepted proportionally across types to preserve composition
	var remaining_to_accept = total_accepted
	var keys = extracted_by_type.keys()
	for i in range(keys.size()):
		var type_id = keys[i]
		var amount: float = float(extracted_by_type[type_id])
		if amount <= 0.0:
			continue
		var share = amount / max(0.0001, total_requested)
		var accept_amount = (total_accepted * share)
		# Avoid tiny remainders on last item
		if i == keys.size() - 1:
			accept_amount = remaining_to_accept
		else:
			accept_amount = min(accept_amount, remaining_to_accept)
		if accept_amount > 0.0:
			if not type_id in cargo_by_type:
				cargo_by_type[type_id] = 0.0
			cargo_by_type[type_id] += accept_amount
			remaining_to_accept -= accept_amount
	# Update totals
	carrying_resources += total_accepted
	_update_cargo_bar()
	return total_accepted

func start_returning():
	ai_state = AIState.RETURNING
	return_target = _find_deposit_target()
	if return_target:
		target_position = return_target.global_position

func process_returning_state(delta: float):
	# Move to deposit target and deposit cargo
	if return_target == null or not is_instance_valid(return_target):
		return_target = _find_deposit_target()
	if return_target == null:
		# No target - idle
		ai_state = AIState.IDLE
		return
	# Move toward target
	var distance = global_position.distance_to(return_target.global_position)
	if distance > 80.0:
		target_position = return_target.global_position
		desired_velocity = (target_position - global_position).normalized() * move_speed
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	else:
		velocity = Vector2.ZERO
		_deposit_resources()
		# After deposit, return to idle
		complete_current_command()

func _find_deposit_target() -> Node2D:
	# Prefer command ships or units with deposit_resources in same zone
	var current_zone = ZoneManager.get_unit_zone(self) if ZoneManager else 1
	var zone_units = EntityManager.get_units_in_zone(current_zone) if EntityManager else []
	for unit in zone_units:
		if not is_instance_valid(unit) or unit == self:
			continue
		if unit.team_id != team_id:
			continue
		if "is_command_ship" in unit and unit.is_command_ship:
			return unit
		if unit.has_method("deposit_resources"):
			return unit
	return null

func _deposit_resources():
	if carrying_resources <= 0.0:
		return
	if not return_target or not is_instance_valid(return_target):
		return
	# Use both legacy 3-tier and new 100-type systems like MiningDrone
	var common: float = 0.0
	var rare: float = 0.0
	var exotic: float = 0.0
	# Map resource_id to tier groups: 0-2 common, 3-5 rare, 6+ exotic
	for type_id in cargo_by_type.keys():
		var amount: float = float(cargo_by_type[type_id])
		var tier: int = 0
		if ResourceDatabase and type_id >= 0 and type_id < ResourceDatabase.RESOURCES.size():
			var res = ResourceDatabase.RESOURCES[type_id]
			tier = int(res.get("tier", 0))
		if tier <= 2:
			common += amount
		elif tier <= 5:
			rare += amount
		else:
			exotic += amount
		# Also add to new resource inventory
		if ResourceManager:
			ResourceManager.add_resource(type_id, int(amount))
	# Deposit to command ship (legacy)
	if return_target and return_target.has_method("deposit_resources"):
		var deposited = return_target.deposit_resources(common, rare, exotic)
		if deposited and AudioManager:
			AudioManager.play_sound("resource_deposit")
	# Clear cargo
	carrying_resources = 0.0
	cargo_by_type.clear()
	_update_cargo_bar()

func _create_cargo_indicator():
	if cargo_indicator_scene:
		cargo_indicator = cargo_indicator_scene.instantiate()
		# The indicator expects a target_unit property
		if "target_unit" in cargo_indicator:
			cargo_indicator.target_unit = self
		var ui_layer = get_tree().root.find_child("UILayer", true, false)
		if ui_layer:
			ui_layer.add_child(cargo_indicator)

func _update_cargo_bar():
	# Floating UI update (like MiningDrone)
	if cargo_indicator and cargo_indicator.has_method("update_cargo"):
		cargo_indicator.update_cargo(carrying_resources, max_cargo)

func _create_fade_curve() -> Curve:
	"""Create a curve that fades particles out over their lifetime"""
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))  # Start at full scale
	curve.add_point(Vector2(0.5, 0.8))  # Maintain most of scale mid-life
	curve.add_point(Vector2(1.0, 0.0))  # Fade to nothing at end
	return curve

func _create_color_ramp() -> Gradient:
	"""Create a color gradient that fades particles from bright to transparent"""
	var gradient = Gradient.new()
	# Start bright cyan/blue
	gradient.set_color(0, Color(0.6, 0.9, 1.0, 1.0))
	# Mid-point slightly dimmer
	gradient.set_color(1, Color(0.3, 0.5, 0.8, 0.0))  # Fade to transparent
	return gradient

func _build_visuals():
	"""Legacy blueprint system visuals"""
	# Simple per-piece rectangles as children for MVP
	for p in placements:
		var comp = BlueprintDatabase.get_component_by_id(p.id)
		if comp.is_empty():
			continue
		var node = ColorRect.new()
		var color := Color(0.7, 0.7, 1.0, 0.25)
		match comp.category:
			"hull": color = Color(0.8, 0.8, 0.9, 0.25)
			"engine": color = Color(0.9, 0.6, 0.4, 0.35)
			"core": color = Color(0.6, 0.9, 0.6, 0.35)
			"weapon": color = Color(0.9, 0.4, 0.4, 0.35)
			"shield": color = Color(0.6, 0.6, 0.9, 0.35)
		node.color = color
		node.size = Vector2(comp.size.x * cell_px, comp.size.y * cell_px)
		node.position = Vector2(p.x * cell_px, p.y * cell_px)
		add_child(node)

# ============================================================================
# WEAPON SYSTEM
# ============================================================================

func _create_weapon_turret(local_pos: Vector2, weapon_type: String) -> Sprite2D:
	"""Create a visual turret sprite for a weapon"""
	var turret = Sprite2D.new()
	turret.name = "WeaponTurret_%d" % weapon_turrets.size()
	turret.texture = load("res://assets/sprites/weaponTurret.png")
	
	# Position at same location as weapon component (in VisualContainer coordinate space)
	turret.position = local_pos
	turret.z_index = 5  # Above ship components
	
	# Store base position for recoil translation
	turret_base_positions.append(local_pos)
	
	# Scale 2x base size, further adjusted by weapon type
	if weapon_type == "laser_weapon":
		turret.scale = Vector2(0.8, 0.8)  # 2x * 0.4 for lasers
	elif weapon_type == "missile_launcher":
		turret.scale = Vector2(1.2, 1.2)  # 2x * 0.6 for missiles
	
	# Add to VisualContainer so turret is in same coordinate space as weapon visuals
	var visual_container = get_node_or_null("VisualContainer")
	if visual_container:
		visual_container.add_child(turret)
	else:
		# Fallback: add to ship directly
		add_child(turret)
	
	return turret

func _instantiate_weapon_components(blueprint: CosmoteerShipBlueprint):
	"""Create functional weapon components from blueprint data - supports all 21 weapon types"""
	var weapon_index = 0
	
	# Calculate the same center offset used for visuals (using hex coordinates)
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	# Convert hex positions to pixel positions to find bounds
	for hull_pos in blueprint.hull_cells.keys():
		var pixel_pos = HexGrid.hex_to_pixel(hull_pos, cell_px)
		var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, cell_px)
		# Check all vertices of hexagon for bounds
		for vertex in hex_vertices:
			min_x = min(min_x, vertex.x)
			max_x = max(max_x, vertex.x)
			min_y = min(min_y, vertex.y)
			max_y = max(max_y, vertex.y)
	
	var center_offset = Vector2(
		(min_x + max_x) * 0.5,
		(min_y + max_y) * 0.5
	)
	
	# Get all weapon type IDs
	var all_weapon_types = CosmoteerComponentDefs.get_all_weapon_types()
	
	for comp_data in blueprint.components:
		var comp_id = comp_data.get("type", "")
		var parsed = CosmoteerComponentDefs.parse_component_id(comp_id)
		var comp_type = parsed["type"]
		var comp_level = parsed["level"]
		
		# Only process weapon components (check against all weapon types)
		if comp_type not in all_weapon_types:
			continue
		
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_id)
		if comp_def.is_empty():
			continue
		
		# Create weapon component
		var weapon = WeaponComponent.new()
		weapon.name = "Weapon_%d" % weapon_index
		
		# Get the weapon type enum value from the component type
		var weapon_type_enum = CosmoteerComponentDefs.get_weapon_enum_value(comp_type)
		
		# Build level data dictionary from component definition
		var level_data = {
			"damage": comp_def.get("damage", 10.0),
			"fire_rate": comp_def.get("fire_rate", 2.0),
			"range": comp_def.get("range", 300.0),
			"projectile_speed": comp_def.get("projectile_speed", 500.0),
			"homing": comp_def.get("homing", false) if "homing" in comp_def else CosmoteerComponentDefs.COMPONENT_TYPES.get(comp_type, {}).get("homing", false),
			"aoe_radius": comp_def.get("aoe_radius", 0.0),
			"aoe_type": comp_def.get("aoe_type", CosmoteerComponentDefs.COMPONENT_TYPES.get(comp_type, {}).get("aoe_type", 0)),
			"special_effect": comp_def.get("special_effect", CosmoteerComponentDefs.COMPONENT_TYPES.get(comp_type, {}).get("special_effect", 0)),
			"effect_duration": comp_def.get("effect_duration", CosmoteerComponentDefs.COMPONENT_TYPES.get(comp_type, {}).get("effect_duration", 0.0)),
			"effect_strength": comp_def.get("effect_strength", CosmoteerComponentDefs.COMPONENT_TYPES.get(comp_type, {}).get("effect_strength", 0.0)),
			"projectile_count": comp_def.get("projectile_count", CosmoteerComponentDefs.COMPONENT_TYPES.get(comp_type, {}).get("projectile_count", 1)),
			"spread_angle": comp_def.get("spread_angle", CosmoteerComponentDefs.COMPONENT_TYPES.get(comp_type, {}).get("spread_angle", 0.0)),
			"is_beam": comp_def.get("is_beam", CosmoteerComponentDefs.COMPONENT_TYPES.get(comp_type, {}).get("is_beam", false)),
			"beam_width": comp_def.get("beam_width", 4.0),
			"is_support": comp_def.get("is_support", CosmoteerComponentDefs.COMPONENT_TYPES.get(comp_type, {}).get("is_support", false)),
			"chain_count": comp_def.get("chain_count", CosmoteerComponentDefs.COMPONENT_TYPES.get(comp_type, {}).get("chain_count", 0)),
			"chain_range": comp_def.get("chain_range", CosmoteerComponentDefs.COMPONENT_TYPES.get(comp_type, {}).get("chain_range", 100.0)),
			"chain_damage_falloff": comp_def.get("chain_damage_falloff", CosmoteerComponentDefs.COMPONENT_TYPES.get(comp_type, {}).get("chain_damage_falloff", 0.7)),
			# Flak cannon properties
			"flak_bullet_count": comp_def.get("flak_bullet_count", 25),
			"flak_mini_aoe": comp_def.get("flak_mini_aoe", 22.0)
		}
		
		# Configure weapon with all properties
		WeaponComponent.configure_from_type(weapon, weapon_type_enum, level_data)
		
		# Calculate weapon position at component grid location (centered, matching visual offset)
		var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
		var comp_size = comp_data.get("size", Vector2i.ONE)
		# Use hex grid to calculate center position
		var hex_cells = HexGrid.get_component_hex_cells(comp_pos, comp_size)
		var center_hex = Vector2.ZERO
		for hex_pos in hex_cells:
			center_hex += HexGrid.hex_to_pixel(hex_pos, cell_px)
		center_hex /= hex_cells.size()
		var local_pos = center_hex - center_offset
		
		add_child(weapon)
		weapon_components.append(weapon)
		weapon_enabled.append(true)  # All weapons enabled by default
		weapon_positions.append(local_pos)  # Store position separately
		
		# Create visual turret sprite for this weapon
		var turret_sprite = _create_weapon_turret(local_pos, comp_type)
		weapon_turrets.append(turret_sprite)
		turret_recoil.append(0.0)  # Initialize recoil state
		# Note: turret_base_positions is set in _create_weapon_turret()
		
		weapon_index += 1
	
	print("Created %d weapon components with turrets" % weapon_components.size())

func _instantiate_shield_components(blueprint: CosmoteerShipBlueprint):
	"""Create shield component if blueprint has shield generator"""
	var total_shield_hp = 0.0
	var shield_count = 0
	
	for comp_data in blueprint.components:
		var comp_id = comp_data.get("type", "")
		var parsed = CosmoteerComponentDefs.parse_component_id(comp_id)
		if parsed["type"] == "shield_generator":
			var comp_def = CosmoteerComponentDefs.get_component_data(comp_id)
			if not comp_def.is_empty():
				total_shield_hp += comp_def.get("shield_hp", 100.0)
				shield_count += 1
	
	# Create shield component if we have shield generators
	if shield_count > 0:
		shield_component = ShieldComponent.new()
		shield_component.name = "ShieldComponent"
		shield_component.max_shield = total_shield_hp
		shield_component.recharge_rate = 5.0 * shield_count  # More generators = faster recharge
		shield_component.recharge_delay = 3.0
		
		# Calculate shield radius based on ship size
		var radius = _compute_hull_radius() * 1.5  # Ensure it covers everything with margin
		shield_component.shield_radius = radius
		
		add_child(shield_component)
		print("Created shield component with %d HP" % total_shield_hp)
		
		# Create shield visual
		_create_shield_visual(radius)

func _create_shield_visual(radius: float):
	if shield_visual_node and is_instance_valid(shield_visual_node):
		shield_visual_node.queue_free()
	
	var visual_container = get_node_or_null("VisualContainer")
	if not visual_container:
		return

	shield_visual_node = ColorRect.new()
	shield_visual_node.name = "ShieldVisual"
	shield_visual_node.size = Vector2(radius * 2, radius * 2)
	shield_visual_node.position = Vector2(-radius, -radius) # Centered
	shield_visual_node.color = Color.TRANSPARENT # Shader handles color
	shield_visual_node.z_index = 20 # Above everything
	shield_visual_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var shader = load("res://shaders/shield_ripple.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("shield_color", Color(0.0, 0.8, 1.0, 0.4))
	mat.set_shader_parameter("intensity", 1.0)
	mat.set_shader_parameter("hit_strength", 0.0)
	shield_visual_node.material = mat
	
	visual_container.add_child(shield_visual_node)

# ============================================================================
# UI ELEMENTS
# ============================================================================

# ============================================================================
# WEAPON ATTACK MARKER SYSTEM
# ============================================================================

func _init_weapon_markers():
	"""Initialize weapon markers array to match weapon count"""
	weapon_markers.resize(weapon_components.size())
	for i in range(weapon_markers.size()):
		weapon_markers[i] = null

func get_weapon_turret_position(weapon_index: int) -> Vector2:
	"""Get the world position of a weapon turret"""
	if weapon_index < 0 or weapon_index >= weapon_turrets.size():
		return Vector2.ZERO
	
	var turret = weapon_turrets[weapon_index]
	if turret and is_instance_valid(turret):
		return turret.global_position
	return global_position

func _get_weapon_label(weapon_index: int) -> String:
	"""Get per-type label for a weapon (e.g., 'Laser 2', 'Missile 1')"""
	if weapon_index < 0 or weapon_index >= weapon_components.size():
		return "Weapon"
	
	var weapon = weapon_components[weapon_index]
	
	# Get display name from WeaponComponent constant
	var type_name = weapon.get_display_name() if weapon.has_method("get_display_name") else "Weapon"
	
	# Count weapons of same type up to this index
	var type_count = 0
	for i in range(weapon_index + 1):
		if weapon_components[i].weapon_type == weapon.weapon_type:
			type_count += 1
	
	return "%s %d" % [type_name, type_count]

func _get_spread_positions(center: Vector2, count: int, radius: float = 30.0) -> Array:
	"""Calculate circle spread positions for multiple markers"""
	var positions: Array = []
	if count == 1:
		positions.append(center)
	else:
		for i in range(count):
			var angle = (TAU / count) * i - PI / 2.0  # Start from top
			positions.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return positions

func _place_weapon_marker(weapon_index: int, world_pos: Vector2):
	"""Create or move a weapon attack marker"""
	if weapon_index < 0 or weapon_index >= weapon_components.size():
		return
	
	# Ensure markers array is correct size
	if weapon_markers.size() != weapon_components.size():
		_init_weapon_markers()
	
	# Remove existing marker for this weapon
	_remove_weapon_marker(weapon_index)
	
	# Create new marker
	if not marker_scene:
		marker_scene = preload("res://scenes/ui/WeaponAttackMarker.tscn")
	
	var marker = marker_scene.instantiate() as WeaponAttackMarker
	if not marker:
		return
	
	var weapon = weapon_components[weapon_index]
	var weapon_type_int = weapon.weapon_type  # WeaponComponent.WeaponType enum
	var label_text = _get_weapon_label(weapon_index)
	
	# Get AOE radius if weapon has it
	var aoe_radius = weapon.get_aoe_radius() if weapon.has_method("get_aoe_radius") else 0.0
	
	marker.setup(weapon_index, weapon_type_int, label_text, self, aoe_radius)
	marker.global_position = world_pos
	marker.marker_clicked.connect(_on_marker_clicked)
	
	# Add to scene (world space)
	var parent = get_tree().current_scene
	if parent:
		parent.add_child(marker)
	
	weapon_markers[weapon_index] = marker
	
	# Update marker selection visual based on current selection
	marker.set_weapon_selected(weapon_index in active_weapon_indices)

func _remove_weapon_marker(weapon_index: int):
	"""Remove a weapon's attack marker"""
	if weapon_index < 0 or weapon_index >= weapon_markers.size():
		return
	
	var marker = weapon_markers[weapon_index]
	if marker and is_instance_valid(marker):
		marker.queue_free()
	weapon_markers[weapon_index] = null

func _clear_all_weapon_markers():
	"""Remove all weapon markers"""
	for i in range(weapon_markers.size()):
		_remove_weapon_marker(i)

func _on_marker_clicked(marker: WeaponAttackMarker):
	"""Handle click on a weapon marker to remove it"""
	if marker and is_instance_valid(marker):
		var weapon_index = marker.weapon_index
		_remove_weapon_marker(weapon_index)

func _place_markers_for_selected_weapons(world_pos: Vector2):
	"""Place markers for all currently selected weapons with spread pattern"""
	if active_weapon_indices.is_empty():
		return
	
	var count = active_weapon_indices.size()
	var positions = _get_spread_positions(world_pos, count, 35.0)
	
	for i in range(count):
		var weapon_idx = active_weapon_indices[i]
		var pos = positions[i]
		_place_weapon_marker(weapon_idx, pos)

func _update_weapon_marker_selection():
	"""Update marker visuals based on current weapon selection"""
	for i in range(weapon_markers.size()):
		var marker = weapon_markers[i]
		if marker and is_instance_valid(marker):
			marker.set_weapon_selected(i in active_weapon_indices)

func _has_weapon_marker(weapon_index: int) -> bool:
	"""Check if a weapon has an active marker"""
	if weapon_index < 0 or weapon_index >= weapon_markers.size():
		return false
	var marker = weapon_markers[weapon_index]
	return marker != null and is_instance_valid(marker)

func _get_weapon_marker_position(weapon_index: int) -> Vector2:
	"""Get the position of a weapon's marker, or Vector2.ZERO if none"""
	if weapon_index < 0 or weapon_index >= weapon_markers.size():
		return Vector2.ZERO
	var marker = weapon_markers[weapon_index]
	if marker and is_instance_valid(marker):
		return marker.global_position
	return Vector2.ZERO

# ============================================================================
# COMBAT OVERRIDE
# ============================================================================

func process_combat_state(delta: float):
	"""Override combat behavior - simplified to only handle movement"""
	if not is_instance_valid(target_entity):
		complete_current_command()
		return
	
	# Get max weapon range from all enabled weapons
	var max_range = 0.0
	for i in range(weapon_components.size()):
		if weapon_enabled[i]:
			max_range = max(max_range, weapon_components[i].get_range())
	
	# Fallback if no weapons
	if max_range == 0:
		max_range = 150.0
	
	var distance = global_position.distance_to(target_entity.global_position)
	
	# Move to optimal range (80% of max weapon range)
	if distance > max_range * 0.8:
		# Move closer
		target_position = target_entity.global_position
		var direction = (target_entity.global_position - global_position).normalized()
		desired_velocity = direction * move_speed
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	else:
		# In range - slow down
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta * 2.0)
		
		# Rotate to face target
		var direction_to_target = (target_entity.global_position - global_position).normalized()
		var target_rotation = direction_to_target.angle()
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)
	
	# Weapon firing is now handled independently in _process_weapon_firing()

# ============================================================================
# DESTRUCTIBLE HULL SYSTEM
# ============================================================================

func _find_nearest_hull_cell(world_pos: Vector2) -> Vector2i:
	"""Find the nearest hull cell to a world position"""
	if hull_cell_data.is_empty():
		return Vector2i(-999, -999)
	
	var visual_container = get_node_or_null("VisualContainer")
	if not visual_container:
		return Vector2i(-999, -999)
	
	# Convert world position to VisualContainer local space (rotated)
	var local_pos_rotated = visual_container.to_local(world_pos)
	
	# Unrotate to get unrotated local coordinates
	var unrotated_local_pos = local_pos_rotated.rotated(-visual_container.rotation)
	
	# Calculate center offset (same as used when rendering hull cells)
	var center_offset = _calculate_center_offset()
	
	# Add center_offset back to get absolute pixel position (matching blueprint coordinate system)
	var absolute_pixel_pos = unrotated_local_pos + center_offset
	
	# Convert to hex coordinates (now matching blueprint hex coordinates)
	var hit_hex = HexGrid.pixel_to_hex(absolute_pixel_pos, cell_px)
	
	# Check if this hex has a hull cell
	if hull_cell_data.has(hit_hex):
		return hit_hex
	
	# If not, find nearest neighbor with hull by checking pixel distance
	var nearest_hex = hit_hex
	var min_distance_sq = INF
	
	for hex_pos in hull_cell_data.keys():
		var cell_pixel_pos = HexGrid.hex_to_pixel(hex_pos, cell_px)
		var distance_sq = absolute_pixel_pos.distance_squared_to(cell_pixel_pos)
		if distance_sq < min_distance_sq:
			min_distance_sq = distance_sq
			nearest_hex = hex_pos
	
	# Check if we found a reasonable match (within 1.5 hex cell radius in pixels)
	var max_distance = cell_px * 1.5
	if sqrt(min_distance_sq) <= max_distance:
		return nearest_hex
	
	return Vector2i(-999, -999)  # No valid hull cell found

func _damage_hull_cell(hex_pos: Vector2i, damage: float):
	"""Apply damage to a specific hull cell"""
	if not hull_cell_data.has(hex_pos):
		return
	
	var cell_data = hull_cell_data[hex_pos]
	cell_data["health"] = max(0, cell_data["health"] - damage)
	
	# Calculate health percentage for darkening
	var health_percent = cell_data["health"] / cell_data["max_health"]
	
	# Apply progressive darkening based on health
	var visual_node = cell_data.get("visual_node")
	if visual_node and is_instance_valid(visual_node):
		# Calculate darkened color: lerp from black (0% health) to white (100% health)
		var darkened_modulate = lerp(Color.BLACK, Color.WHITE, health_percent)
		
		# Apply darkening to visual node
		# Both Node2D and Polygon2D have modulate property
		if cell_data.get("is_polygon", false):
			# For Polygon2D, apply darkening to color property for better visual effect
			var base_color = CosmoteerComponentDefs.get_hull_color(cell_data.get("hull_type", CosmoteerShipBlueprint.HullType.LIGHT))
			visual_node.color = base_color * darkened_modulate
			# Also set modulate for flash effect compatibility
			visual_node.modulate = Color.WHITE
		else:
			# For Node2D (HullHexDrawer), use modulate directly
			visual_node.modulate = darkened_modulate
		
		# Flash red briefly on hit
		var tween = create_tween()
		if cell_data.get("is_polygon", false):
			# For Polygon2D, flash the modulate (color is already darkened)
			tween.tween_property(visual_node, "modulate", Color.RED, 0.05)
			tween.tween_property(visual_node, "modulate", Color.WHITE, 0.15)
		else:
			# For Node2D (HullHexDrawer), flash modulate directly
			tween.tween_property(visual_node, "modulate", Color.RED, 0.05)
			tween.tween_property(visual_node, "modulate", darkened_modulate, 0.15)
	
	if VfxDirector and not cell_data.get("scorch_spawned", false) and health_percent < 0.95:
		_spawn_scorch_decal(cell_data)
		cell_data["scorch_spawned"] = true
	
	# Check if hull cell is destroyed
	if cell_data["health"] <= 0:
		_destroy_hull_cell(hex_pos)
	else:
		# Update ship health (which will update segments)
		_update_ship_health()

func _spawn_scorch_decal(cell_data: Dictionary) -> void:
	var visual_container = get_node_or_null("VisualContainer")
	if not visual_container or not VfxDirector:
		return
	var local_pos = cell_data.get("local_position", Vector2.ZERO)
	var radius = randf_range(0.08, 0.18)
	var rotation = randf_range(0.0, TAU)
	VfxDirector.spawn_scorch_decal(visual_container, local_pos, radius, rotation)

func _destroy_hull_cell(hex_pos: Vector2i):
	"""Destroy a hull cell and create destruction effects"""
	print("DEBUG: _destroy_hull_cell called for hex_pos: ", hex_pos)
	if not hull_cell_data.has(hex_pos):
		print("DEBUG: hex_pos not in hull_cell_data!")
		return
	
	var cell_data = hull_cell_data[hex_pos]
	var hull_type = cell_data.get("hull_type", CosmoteerShipBlueprint.HullType.LIGHT)
	var visual_node = cell_data.get("visual_node")
	var local_pos = cell_data.get("local_position", Vector2.ZERO)
	
	print("DEBUG: local_pos = ", local_pos, ", hull_type = ", hull_type)

	var visual_container = get_node_or_null("VisualContainer")
	if VfxDirector and visual_container:
		VfxDirector.spawn_explosion(visual_container, local_pos, .50)
		VfxDirector.spawn_scorch_decal(visual_container, local_pos, randf_range(0.1, 0.24), randf_range(0.0, TAU))
	
	# Capture darkened color before removing cell data
	var darkened_color = Color.BLACK
	if visual_node and is_instance_valid(visual_node):
		if cell_data.get("is_polygon", false):
			# For Polygon2D, get the darkened color from color property
			darkened_color = visual_node.color
		else:
			# For Node2D (HullHexDrawer), get from modulate property
			darkened_color = visual_node.modulate
		print("DEBUG: captured darkened_color = ", darkened_color)
	else:
		print("DEBUG: visual_node is invalid!")
	
	# Hide/remove visual node
	if visual_node and is_instance_valid(visual_node):
		visual_node.visible = false
		visual_node.queue_free()
	
	# Remove from hull cell data
	hull_cell_data.erase(hex_pos)
	
	# Remove from runtime blueprint
	if runtime_blueprint:
		runtime_blueprint.remove_hull_cell(hex_pos)
	
	# Create destruction pieces with darkened color
	print("DEBUG: Calling _create_destruction_pieces...")
	_create_destruction_pieces(hex_pos, hull_type, local_pos, darkened_color)
	print("DEBUG: _create_destruction_pieces returned")
	
	# Check if components need to be destroyed
	_check_component_destruction(hex_pos)
	
	# Update ship health
	_update_ship_health()
	
	# Check if all hull cells are destroyed - ship dies
	if hull_cell_data.is_empty():
		die()
		return
	
	# Check if ship health is zero - ship dies
	if current_health <= 0:
		die()

func _create_destruction_pieces(hex_pos: Vector2i, hull_type: CosmoteerShipBlueprint.HullType, local_pos: Vector2, darkened_color: Color):
	"""Create physics-based destruction pieces for a destroyed hull cell"""
	print("DEBUG: _create_destruction_pieces called")
	var visual_container = get_node_or_null("VisualContainer")
	if not visual_container:
		print("DEBUG: VisualContainer not found!")
		return
	
	print("DEBUG: VisualContainer found, local_pos = ", local_pos)
	
	# Get hex vertices
	var pixel_pos = HexGrid.hex_to_pixel(hex_pos, cell_px)
	var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, cell_px)
	print("DEBUG: pixel_pos = ", pixel_pos, ", hex_vertices count = ", hex_vertices.size())
	
	var hull_texture_path = CosmoteerComponentDefs.get_hull_texture(hull_type)
	var hull_texture = null
	if hull_texture_path and ResourceLoader.exists(hull_texture_path):
		hull_texture = load(hull_texture_path)
	
	# Split hexagon into 6 triangular pieces (center to each pair of adjacent vertices)
	# Pieces should be relative to the hull cell center (which is at local_pos in VisualContainer space)
	# So vertices should be relative to pixel_pos (the hull cell center in blueprint space)
	var adjusted_vertices = PackedVector2Array()
	for vertex in hex_vertices:
		adjusted_vertices.append(vertex - pixel_pos)  # Vertices relative to hull cell center
	var adjusted_center = Vector2.ZERO  # Pieces are centered at hull cell center
	
	var pieces = []
	for i in range(hex_vertices.size()):
		var next_i = (i + 1) % hex_vertices.size()
		var v1 = adjusted_vertices[i]
		var v2 = adjusted_vertices[next_i]
		
		# Create triangle piece (center, vertex1, vertex2)
		var piece_vertices = PackedVector2Array([adjusted_center, v1, v2])
		pieces.append(piece_vertices)
	
	print("DEBUG: Created ", pieces.size(), " pieces")
	
	# Convert local position to world position correctly
	# local_pos is already in VisualContainer local space (relative to center_offset)
	# The hull cells are positioned at (0,0) in VisualContainer with vertices offset by -center_offset
	# So local_pos is the correct position in VisualContainer local space
	var world_pos = visual_container.to_global(local_pos)
	var ship_rotation = rotation
	var container_rotation = visual_container.rotation
	var total_rotation = ship_rotation + container_rotation
	
	print("DEBUG: local_pos = ", local_pos)
	print("DEBUG: world_pos = ", world_pos, ", total_rotation = ", total_rotation)
	print("DEBUG: ship global_position = ", global_position, ", ship rotation = ", ship_rotation)
	print("DEBUG: visual_container position = ", visual_container.position, ", rotation = ", container_rotation)
	
	# Get parent node to add pieces to (world space)
	var parent_node = get_parent()
	if not parent_node:
		parent_node = get_tree().current_scene
	
	if not parent_node:
		print("DEBUG: ERROR - No parent node found!")
		return
	
	print("DEBUG: Parent node = ", parent_node.name, " (", parent_node.get_class(), ")")
	
	# Create RigidBody2D for each piece
	var piece_count = 0
	for piece_verts in pieces:
		var rigid_body = RigidBody2D.new()
		rigid_body.name = "DestructionPiece_%d" % piece_count
		rigid_body.gravity_scale = 1.0
		rigid_body.lock_rotation = false
		rigid_body.collision_layer = 0  # Don't collide with anything
		rigid_body.collision_mask = 0  # Don't collide with anything
		
		# Scale up pieces slightly for visibility (pieces are small from 7.5px hex)
		var scale_factor = 2.0
		var scaled_verts = PackedVector2Array()
		for v in piece_verts:
			scaled_verts.append(v * scale_factor)
		
		# Create collision shape with scaled vertices
		var collision_shape = CollisionShape2D.new()
		var polygon_shape = ConvexPolygonShape2D.new()
		polygon_shape.points = scaled_verts
		collision_shape.shape = polygon_shape
		rigid_body.add_child(collision_shape)
		
		# Use darkened color from hull damage, or lighter version if too dark
		var piece_color = darkened_color
		if darkened_color.r < 0.1 and darkened_color.g < 0.1 and darkened_color.b < 0.1:
			# Too dark, use lighter version of base hull color
			var base_hull_color = CosmoteerComponentDefs.get_hull_color(hull_type)
			piece_color = base_hull_color * Color(0.6, 0.6, 0.6, 1.0)  # 60% brightness
		
		# Create visual polygon with appropriate color
		var polygon = Polygon2D.new()
		polygon.polygon = scaled_verts
		polygon.color = piece_color
		polygon.z_index = 10  # Render above ship but not excessive
		rigid_body.add_child(polygon)
		
		# Position in world space
		rigid_body.global_position = world_pos
		rigid_body.rotation = total_rotation
		
		# Ensure rigid body starts with full opacity for fade-out
		rigid_body.modulate = Color.WHITE
		
		# Calculate piece center for velocity direction
		var piece_center = (piece_verts[0] + piece_verts[1] + piece_verts[2]) / 3.0
		var direction_local = piece_center.normalized() if piece_center.length() > 0 else Vector2(1, 0)
		
		# Convert direction to world space (rotate by total rotation)
		var direction_world = direction_local.rotated(total_rotation)
		
		# Apply random velocity (outward + downward in world space)
		var random_angle = randf() * PI * 2.0
		var random_dir = Vector2(cos(random_angle), sin(random_angle))
		var velocity = (direction_world + random_dir * 0.5) * 100.0 + Vector2(0, 50).rotated(total_rotation)
		rigid_body.linear_velocity = velocity
		
		# Apply random angular velocity
		rigid_body.angular_velocity = (randf() - 0.5) * 10.0
		
		print("DEBUG: Created piece ", piece_count, " at world_pos = ", rigid_body.global_position, " with velocity = ", velocity)
		
		# Add to parent (world space) instead of VisualContainer
		parent_node.add_child(rigid_body)
		piece_count += 1
		
		# Fade out and remove after delay (2.5 seconds)
		var tween = create_tween()
		tween.tween_property(rigid_body, "modulate:a", 0.0, 2.5)
		tween.tween_callback(rigid_body.queue_free)
	
	print("DEBUG: Created ", piece_count, " destruction pieces total")

func _check_component_destruction(destroyed_hex: Vector2i):
	"""Check if any components need to be destroyed when hull is destroyed"""
	if not runtime_blueprint:
		return
	
	# Iterate backwards through components to safely remove while iterating
	for i in range(runtime_blueprint.components.size() - 1, -1, -1):
		var comp_data = runtime_blueprint.components[i]
		var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
		var comp_size = comp_data.get("size", Vector2i.ONE)
		
		# Get hex cells occupied by this component
		var hex_cells = HexGrid.get_component_hex_cells(comp_pos, comp_size)
		
		# Check if destroyed hex is in component's hex cells
		if destroyed_hex in hex_cells:
			# Destroy this component
			var comp_id = comp_data.get("type", "")
			var parsed = CosmoteerComponentDefs.parse_component_id(comp_id)
			var comp_type = parsed["type"]
			
			# Remove component from blueprint
			runtime_blueprint.components.remove_at(i)
			
			# Remove component visual
			_remove_component_visual(comp_data)
			
			# Handle component-specific cleanup
			match comp_type:
				"laser_weapon", "missile_launcher":
					_destroy_weapon_component(comp_data)
				"engine":
					_destroy_engine_component(comp_data)
				"shield_generator":
					_destroy_shield_component()
			
			# Create destruction effect
			var comp_local_pos = Vector2.ZERO
			var hex_cells_list = HexGrid.get_component_hex_cells(comp_pos, comp_size)
			for hex_pos in hex_cells_list:
				comp_local_pos += HexGrid.hex_to_pixel(hex_pos, cell_px)
			comp_local_pos /= hex_cells_list.size()
			
			# Get center offset for positioning
			var visual_container = get_node_or_null("VisualContainer")
			if visual_container:
				var center_offset = _calculate_center_offset()
				comp_local_pos -= center_offset
				_create_component_destruction_effect(comp_local_pos)

func _remove_component_visual(comp_data: Dictionary):
	"""Remove component visual from scene"""
	var visual_container = get_node_or_null("VisualContainer")
	if not visual_container:
		return
	
	var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
	var comp_size = comp_data.get("size", Vector2i.ONE)
	
	# Find and remove component sprite/polygon
	var hex_cells = HexGrid.get_component_hex_cells(comp_pos, comp_size)
	var center_hex = Vector2.ZERO
	for hex_pos in hex_cells:
		center_hex += HexGrid.hex_to_pixel(hex_pos, cell_px)
	center_hex /= hex_cells.size()
	
	var center_offset = _calculate_center_offset()
	var comp_local_pos = center_hex - center_offset
	
	# Find visual nodes near this position
	for child in visual_container.get_children():
		if child is Sprite2D or child is Polygon2D:
			if child.position.distance_to(comp_local_pos) < cell_px * 2:
				child.queue_free()
				break

func _destroy_weapon_component(comp_data: Dictionary):
	"""Destroy a weapon component"""
	# Find weapon by position
	var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
	var comp_size = comp_data.get("size", Vector2i.ONE)
	var hex_cells = HexGrid.get_component_hex_cells(comp_pos, comp_size)
	var center_hex = Vector2.ZERO
	for hex_pos in hex_cells:
		center_hex += HexGrid.hex_to_pixel(hex_pos, cell_px)
	center_hex /= hex_cells.size()
	var center_offset = _calculate_center_offset()
	var weapon_local_pos = center_hex - center_offset
	
	# Find and remove weapon
	for i in range(weapon_components.size()):
		if weapon_positions[i].distance_to(weapon_local_pos) < cell_px * 2:
			# Disable weapon
			weapon_enabled[i] = false
			
			# Remove turret visual
			if i < weapon_turrets.size() and is_instance_valid(weapon_turrets[i]):
				weapon_turrets[i].queue_free()
			
			# Remove weapon component
			if i < weapon_components.size() and is_instance_valid(weapon_components[i]):
				weapon_components[i].queue_free()
			
			# Remove from arrays
			weapon_components.remove_at(i)
			weapon_enabled.remove_at(i)
			weapon_positions.remove_at(i)
			weapon_turrets.remove_at(i)
			weapon_targets.remove_at(i)
			if i < turret_recoil.size():
				turret_recoil.remove_at(i)
			if i < turret_base_positions.size():
				turret_base_positions.remove_at(i)
			
			break

func _destroy_engine_component(comp_data: Dictionary):
	"""Destroy an engine component"""
	# Find engine particles by position
	var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
	var comp_size = comp_data.get("size", Vector2i.ONE)
	var hex_cells = HexGrid.get_component_hex_cells(comp_pos, comp_size)
	var center_hex = Vector2.ZERO
	for hex_pos in hex_cells:
		center_hex += HexGrid.hex_to_pixel(hex_pos, cell_px)
	center_hex /= hex_cells.size()
	var center_offset = _calculate_center_offset()
	var engine_local_pos = center_hex - center_offset
	
	# Find and remove engine beams
	for i in range(engine_particles.size() - 1, -1, -1):
		var entry = engine_particles[i]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var local_pos = entry.get("local_position", Vector2.ZERO)
		if local_pos.distance_to(engine_local_pos) > cell_px * 3:
			continue
		var beam = entry.get("beam")
		if beam and is_instance_valid(beam) and beam is EngineBeam2D:
			beam.intensity = 0.0
		var effect = entry.get("effect")
		if effect and is_instance_valid(effect):
			effect.queue_free()
		engine_particles.remove_at(i)

func _destroy_shield_component():
	"""Destroy shield component"""
	if shield_component and is_instance_valid(shield_component):
		shield_component.queue_free()
		shield_component = null

func _create_component_destruction_effect(local_pos: Vector2):
	"""Create visual effect when component is destroyed"""
	var visual_container = get_node_or_null("VisualContainer")
	if not visual_container:
		return
	
	# Create explosion effect at component position
	if VfxDirector:
		VfxDirector.spawn_explosion(visual_container, local_pos, .50)
	elif FeedbackManager:
		var world_pos = visual_container.to_global(local_pos)
		FeedbackManager.spawn_explosion(world_pos)

func _calculate_center_offset() -> Vector2:
	"""Calculate center offset for coordinate conversion"""
	if not runtime_blueprint:
		return Vector2.ZERO
	
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for hull_pos in runtime_blueprint.hull_cells.keys():
		var pixel_pos = HexGrid.hex_to_pixel(hull_pos, cell_px)
		var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, cell_px)
		for vertex in hex_vertices:
			min_x = min(min_x, vertex.x)
			max_x = max(max_x, vertex.x)
			min_y = min(min_y, vertex.y)
			max_y = max(max_y, vertex.y)
	
	return Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)

# ============================================================================
# DAMAGE HANDLING
# ============================================================================

func take_damage(amount: float, attacker: Node2D = null, hit_position: Vector2 = Vector2.ZERO):
	"""Override damage to route through shields first, then apply to specific hull cell"""
	var actual_damage = amount
	
	var hit_pos = hit_position
	if hit_pos == Vector2.ZERO and attacker and attacker is Projectile:
		hit_pos = attacker.global_position
	if hit_pos == Vector2.ZERO:
		hit_pos = global_position
	
	# Shield absorbs damage first
	if shield_component and shield_component.current_shield > 0:
		if VfxDirector:
			var local_hit = shield_component.to_local(hit_pos)
			VfxDirector.spawn_shield_hit(shield_component, local_hit, shield_component.shield_radius, Color(0.25, 0.8, 1.0))
		
		# Update shield visual shader
		if shield_visual_node and is_instance_valid(shield_visual_node) and shield_visual_node.visible:
			var visual_container = get_node_or_null("VisualContainer")
			if visual_container:
				var local_hit = visual_container.to_local(hit_pos)
				var radius = shield_component.shield_radius
				# UV = (local_hit + radius) / (2 * radius)
				# Shield node is centered at 0,0 in VisualContainer if we adjusted correctly, 
				# but in _create_shield_visual we put it at -radius,-radius and size 2r, 2r.
				# So position 0,0 in VisualContainer corresponds to center of shield visual.
				var uv_hit = (local_hit + Vector2(radius, radius)) / (radius * 2.0)
				if shield_visual_node.material:
					shield_visual_node.material.set_shader_parameter("hit_position", uv_hit)
					shield_visual_node.material.set_shader_parameter("hit_strength", 1.0)
					shield_hit_timer = 1.0
		
		var excess_damage = shield_component.take_damage(amount)
		actual_damage = excess_damage
	
	# Apply remaining damage to specific hull cell
	if actual_damage > 0:
		# Find nearest hull cell to hit position
		var hit_hex = _find_nearest_hull_cell(hit_pos)
		if hit_hex != Vector2i(-999, -999):  # Valid hex found
			_damage_hull_cell(hit_hex, actual_damage)
		else:
			# Fallback: apply damage to ship health if no hull cell found
			current_health = max(0, current_health - actual_damage)
			health_changed.emit(current_health)
			
			if current_health <= 0:
				die()

# ============================================================================
# UPDATE VISUAL
# ============================================================================

func update_visual():
	"""Override to update engine particles and effects"""
	super.update_visual()
	
	# Update engine particles based on movement
	_update_engine_particles()
	
	if selection_ring_effect and is_instance_valid(selection_ring_effect):
		selection_ring_effect.global_position = global_position
		selection_ring_effect.rotation = 0.0

func _update_engine_particles():
	"""Enable/disable engine beams based on ship velocity"""
	if engine_particles.is_empty():
		return
	
	# Check if ship is moving (velocity magnitude > threshold)
	var is_moving = velocity.length() > 10.0
	
	# Calculate intensity based on velocity (throttle)
	var throttle = clamp(velocity.length() / 300.0, 0.35, 1.0)
	
	# Enable/disable all engine beams
	for entry in engine_particles:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var beam = entry.get("beam")
		if beam and is_instance_valid(beam) and beam is EngineBeam2D:
			if is_moving:
				beam.intensity = throttle
			else:
				beam.intensity = 0.0
		var effect = entry.get("effect")
		if effect and is_instance_valid(effect):
			effect.visible = is_moving

# ============================================================================
# SELECTION HANDLING
# ============================================================================

func set_selected(selected: bool):
	"""Override selection behavior"""
	super.set_selected(selected)
	
	if selected:
		_spawn_selection_ring()
		_show_component_panel()
	else:
		_clear_selection_ring()
		_hide_component_panel()
		# Clear weapon selection and aiming when deselected
		active_weapon_indices.clear()
		component_command_mode = ""
		Input.set_custom_mouse_cursor(null)
		
		# Force update turret rotations to return to neutral
		_update_turret_rotations_auto(0.0)
		
		# Update marker visuals (hide targeting lines when deselected)
		_update_weapon_marker_selection()
	
	# Range indicators are always visible now, no need to show/hide
	
	# Handle weapon panel - only for player ships with weapons
	if selected and team_id == 0 and weapon_components.size() > 0:
		_create_weapon_panel_if_needed()
	elif weapon_panel:
		weapon_panel.hide()

func _show_component_panel() -> void:
	# Reuse existing panel if already present
	if component_panel and is_instance_valid(component_panel):
		component_panel.show()
		return
	# Try to find a global UI layer first
	var ui_layer = get_tree().root.find_child("UILayer", true, false)
	if ui_layer == null:
		# Create a CanvasLayer to ensure UI renders above world
		var scene_root = get_tree().current_scene
		if scene_root:
			ui_layer = CanvasLayer.new()
			ui_layer.name = "UILayer"
			scene_root.add_child(ui_layer)
	# Reuse existing ShipComponentPanel if one exists in UI layer
	var existing_panel: Node = null
	if ui_layer:
		existing_panel = ui_layer.find_child("ShipComponentPanel", true, false)
	if existing_panel and existing_panel is Control:
		component_panel = existing_panel
		_position_component_panel()
		component_panel.show()
		return
	# Create new panel
	var panel_scene = preload("res://scenes/ui/ShipComponentPanel.tscn")
	component_panel = panel_scene.instantiate()
	component_panel.name = "ShipComponentPanel"
	var panel = component_panel as ShipComponentPanel
	if panel:
		panel.set_ship(self)
		var tabs = panel.get_node_or_null("Tabs")
		if tabs:
			var scanner_btn = tabs.get_node_or_null("ScannerTab")
			if scanner_btn:
				scanner_btn.connect("pressed", Callable(panel, "_on_tab_pressed").bind("scanner"))
			var miner_btn = tabs.get_node_or_null("MinerTab")
			if miner_btn:
				miner_btn.connect("pressed", Callable(panel, "_on_tab_pressed").bind("miner"))
		panel.selection_changed.connect(Callable(self, "_on_component_selection_changed"))
		panel.command_mode_changed.connect(Callable(self, "_on_component_command_mode_changed"))
	# Attach to UI layer (or current scene as fallback)
	if ui_layer:
		ui_layer.add_child(component_panel)
	else:
		get_tree().current_scene.add_child(component_panel)
	_position_component_panel()
	component_panel.show()

func _position_component_panel() -> void:
	if component_panel == null or not (component_panel is Control):
		return
	var ui_layer = get_tree().root.find_child("UILayer", true, false)
	if ui_layer == null:
		return
	var selected_panel: Control = ui_layer.get_node_or_null("SelectedUnitsPanel")
	var minimap: Control = ui_layer.get_node_or_null("Minimap")
	# Default placement if references missing (height increased from 100 to 200)
	var left := 520.0
	var top := 520.0
	var right := 1005.0
	var bottom := 720.0
	# Compute from actual panels if available
	if selected_panel and minimap:
		var sel_rect: Rect2 = selected_panel.get_global_rect()
		var mini_rect: Rect2 = minimap.get_global_rect()
		var padding := 8.0
		left = sel_rect.position.x + sel_rect.size.x + padding
		# Double the height by extending upwards
		# Original: top = sel_rect.position.y
		# New: top = sel_rect.position.y - sel_rect.size.y
		top = sel_rect.position.y - sel_rect.size.y
		right = mini_rect.position.x - padding
		bottom = sel_rect.position.y + sel_rect.size.y
	# Apply
	var ctrl := component_panel as Control
	ctrl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ctrl.position = Vector2(left, top)
	ctrl.custom_minimum_size = Vector2(max(0.0, right - left), max(0.0, bottom - top))
	ctrl.size = ctrl.custom_minimum_size

func _hide_component_panel() -> void:
	if component_panel and is_instance_valid(component_panel):
		component_panel.hide()
	component_command_mode = ""
	_clear_component_selections()

func _get_global_weapon_indices(type_str: String, relative_indices: Array) -> Array:
	var global_indices = []
	var target_enum = -1
	
	if type_str == "laser_weapon":
		target_enum = WeaponComponent.WeaponType.LASER
	elif type_str == "missile_launcher":
		target_enum = WeaponComponent.WeaponType.MISSILE
	else:
		return []
		
	var type_counter = 0
	for i in range(weapon_components.size()):
		var w = weapon_components[i]
		if w.weapon_type == target_enum:
			if type_counter in relative_indices:
				global_indices.append(i)
			type_counter += 1
			
	return global_indices

func _on_component_selection_changed(component_type: String, selected_indices: Array) -> void:
	for i in range(scanner_components.size()):
		var c = scanner_components[i]
		if is_instance_valid(c):
			c.set_selected(component_type == "scanner" and i in selected_indices)
	for i in range(mining_components.size()):
		var m = mining_components[i]
		if is_instance_valid(m):
			m.set_selected(component_type == "miner" and i in selected_indices)
	
	# Weapon selection update
	if component_type == "weapons":
		# "weapons" tab uses global indices directly
		active_weapon_indices = selected_indices.duplicate()
		if selected_indices.size() > 0:
			component_command_mode = "attack"
		else:
			component_command_mode = ""
	elif component_type == "laser_weapon" or component_type == "missile_launcher":
		# Convert relative indices (from UI tab) to global weapon indices
		var global_indices = _get_global_weapon_indices(component_type, selected_indices)
		
		active_weapon_indices = global_indices.duplicate()
		component_command_mode = "attack" # Force attack mode when weapons selected
	elif component_type == "scanner" or component_type == "miner":
		# Non-weapon component selected, clear weapon selection
		active_weapon_indices.clear()
		# Auto-select command mode based on type if there is an active selection
		if component_type == "scanner" and selected_indices.size() > 0:
			component_command_mode = "scan"
		elif component_type == "miner" and selected_indices.size() > 0:
			component_command_mode = "mine"
	
	# Update weapon marker visuals based on selection
	_update_weapon_marker_selection()

func _on_component_command_mode_changed(mode: String) -> void:
	component_command_mode = mode

func _clear_component_selections() -> void:
	for c in scanner_components:
		if is_instance_valid(c):
			c.set_selected(false)
	for m in mining_components:
		if is_instance_valid(m):
			m.set_selected(false)

func get_scanner_components() -> Array:
	return scanner_components

func get_mining_components() -> Array:
	return mining_components

func has_active_component_command() -> bool:
	return component_command_mode == "scan" or component_command_mode == "mine"

func get_component_count(comp_type: String) -> int:
	match comp_type:
		"scanner":
			return scanner_components.size()
		"miner":
			return mining_components.size()
		"laser_weapon":
			return weapon_components.size()
		"shield_generator":
			return 1 if shield_component != null else 0
		"engine":
			return engine_particles.size()
		"power_core", "repair_bot", "missile_launcher":
			if runtime_blueprint:
				var count := 0
				for comp_data in runtime_blueprint.components:
					var parsed = CosmoteerComponentDefs.parse_component_id(comp_data.get("type", ""))
					if parsed["type"] == comp_type:
						count += 1
				return count
			return 0
		_:
			return 0

func get_component_types_present() -> Array:
	var types := ["scanner","miner","shield_generator","engine","power_core","repair_bot"]
	var present: Array = []
	for t in types:
		if get_component_count(t) > 0:
			present.append(t)
	
	# Add "weapons" aggregate type if any weapon components exist
	if weapon_components.size() > 0:
		present.append("weapons")
	
	return present

func get_shield_values() -> Dictionary:
	if shield_component:
		return {"current": shield_component.current_shield, "max": shield_component.max_shield}
	return {"current": 0.0, "max": 0.0}

func process_component_command(world_pos: Vector2) -> bool:
	# Infer mode if not set (based on selection)
	if component_command_mode == "":
		var any_scanner_selected := false
		for c in scanner_components:
			if is_instance_valid(c) and c.is_selected:
				any_scanner_selected = true
				break
		var any_miner_selected := false
		for m in mining_components:
			if is_instance_valid(m) and m.is_selected:
				any_miner_selected = true
				break
		if any_scanner_selected:
			component_command_mode = "scan"
		elif any_miner_selected:
			component_command_mode = "mine"
	# Assign targets if we have a mode
	if component_command_mode == "":
		return false
	
	# WEAPON COMMAND LOGIC
	if component_command_mode == "attack":
		# In manual attack mode, right-click is handled by _process for firing.
		# We just need to return true to consume the input and prevent movement.
		if not active_weapon_indices.is_empty():
			return true
			
		# Legacy/Auto logic for attack ground if no specific weapon selected but in attack mode
		# 1. Check for enemy under cursor/near click
		if EntityManager and EntityManager.has_method("get_units_in_radius_zone"):
			var current_zone_id = ZoneManager.get_unit_zone(self)
			# Search radius 60px
			var enemies = EntityManager.get_units_in_radius_zone(world_pos, 60.0, 1, current_zone_id)
			if not enemies.is_empty():
				# Find closest enemy
				var closest = enemies[0]
				var closest_dist = world_pos.distance_to(closest.global_position)
				for e in enemies:
					var d = world_pos.distance_to(e.global_position)
					if d < closest_dist:
						closest = e
						closest_dist = d
				
				# Attack Entity
				_order_attack_entity(closest)
				return true
		
		# 2. No enemy found -> Attack Ground
		_order_attack_ground(world_pos)
		return true

	# Prefer the closest asteroid to the click for precision
	var all = _find_resources_near(world_pos, 180.0)
	var targets: Array = []
	if not all.is_empty():
		all.sort_custom(func(a, b):
			return world_pos.distance_to(a.global_position) < world_pos.distance_to(b.global_position)
		)
		# Take top N depending on component count and mode
		if component_command_mode == "scan":
			targets = [all[0]]  # single precise target for scanners unless multi-queued later
		else:
			targets = all  # miners can distribute to nearest first
	
	if targets.is_empty():
		return false
		
	if component_command_mode == "scan":
		_assign_scanners_to_targets(targets)
	elif component_command_mode == "mine":
		_assign_miners_to_targets(targets)
	return true

func _order_attack_entity(target: Node2D):
	# Clear ground attack
	attack_ground_active = false
	_update_attack_marker(Vector2.ZERO, false)
	
	# Assign target to selected weapons
	for i in range(weapon_targets.size()):
		# Only affect selected weapons if we have a selection, otherwise all
		if active_weapon_indices.is_empty() or i in active_weapon_indices:
			weapon_targets[i] = target

func _order_attack_ground(pos: Vector2):
	# Set persistent ground attack
	attack_ground_active = true
	_update_attack_marker(pos, true)
	
	# Clear entity targets for selected weapons
	for i in range(weapon_targets.size()):
		if active_weapon_indices.is_empty() or i in active_weapon_indices:
			weapon_targets[i] = null

func _update_attack_marker(pos: Vector2, visible: bool):
	if not attack_ground_marker:
		# Create marker if missing
		attack_ground_marker = Sprite2D.new()
		var tex = load("res://assets/ui/cursors/crosshair.png")
		if tex:
			attack_ground_marker.texture = tex
			# If texture is large, scale it (same logic as cursor)
			if tex.get_width() > 32:
				attack_ground_marker.scale = Vector2(32.0 / tex.get_width(), 32.0 / tex.get_height())
		attack_ground_marker.modulate = Color(1.0, 0.2, 0.2, 0.8) # Red tint
		attack_ground_marker.z_index = 100
		get_tree().current_scene.add_child(attack_ground_marker)
	
	if visible:
		attack_ground_marker.global_position = pos
		attack_ground_marker.visible = true
	else:
		attack_ground_marker.visible = false

func attack_ground(target_pos: Vector2):
	# Legacy/Left-click fallback: one-shot or persistent?
	# Updating to use new persistent system
	_order_attack_ground(target_pos)

func _unhandled_input(event: InputEvent) -> void:
	if not is_selected:
		return
	
	# Spacebar clears markers for selected weapons
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if not active_weapon_indices.is_empty():
			for weapon_idx in active_weapon_indices:
				_remove_weapon_marker(weapon_idx)
			get_viewport().set_input_as_handled()
			return
	
	# +/- keys adjust AOE radius for selected AOE weapons with active markers
	if event is InputEventKey and event.pressed:
		var adjust_amount = 0.0
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:  # + key
			adjust_amount = 10.0
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:  # - key
			adjust_amount = -10.0
		
		if adjust_amount != 0.0:
			var adjusted_any = false
			for weapon_idx in active_weapon_indices:
				if _has_weapon_marker(weapon_idx) and weapon_idx < weapon_components.size():
					var weapon = weapon_components[weapon_idx]
					if weapon.is_aoe_weapon():
						var marker = weapon_markers[weapon_idx]
						if marker and is_instance_valid(marker):
							# Get base and current radius
							var base_radius = weapon.aoe_radius
							var current_radius = marker.get_current_aoe_radius()
							if current_radius <= 0:
								current_radius = base_radius
							
							# Apply adjustment with narrow bounds (50% to 150% of base)
							var new_radius = current_radius + adjust_amount
							var min_radius = base_radius * 0.5
							var max_radius = base_radius * 1.5
							new_radius = clampf(new_radius, min_radius, max_radius)
							
							# Update marker and weapon
							marker.set_aoe_radius(new_radius)
							weapon.set_target_aoe_radius(new_radius)
							adjusted_any = true
			
			if adjusted_any:
				get_viewport().set_input_as_handled()
				return
	
	# If no explicit mode set, infer from selection
	if component_command_mode == "":
		var any_scanner_selected := false
		for c in scanner_components:
			if is_instance_valid(c) and c.is_selected:
				any_scanner_selected = true
				break
		var any_miner_selected := false
		for m in mining_components:
			if is_instance_valid(m) and m.is_selected:
				any_miner_selected = true
				break
		if any_scanner_selected:
			component_command_mode = "scan"
		elif any_miner_selected:
			component_command_mode = "mine"
	
	# Handle "attack" mode cursor
	if component_command_mode == "attack":
		if not _attack_cursor:
			var tex = load("res://assets/ui/cursors/crosshair.png")
			if tex:
				var img = tex.get_image()
				if img:
					# Resize to 32x32 if larger
					if img.get_width() > 32:
						img.resize(32, 32, Image.INTERPOLATE_BILINEAR)
						_attack_cursor = ImageTexture.create_from_image(img)
					else:
						_attack_cursor = tex
		
		if _attack_cursor:
			# Hotspot at center (16, 16 for a 32x32 image)
			Input.set_custom_mouse_cursor(_attack_cursor, Input.CURSOR_ARROW, Vector2(16, 16))
	else:
		Input.set_custom_mouse_cursor(null)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_pos = get_global_mouse_position()
		
		if component_command_mode == "attack":
			attack_ground(world_pos)
			get_viewport().set_input_as_handled() # Stop propagation
			return # Consume event
			
		var targets = _find_resources_near(world_pos, 120.0)
		if targets.is_empty():
			return
		if component_command_mode == "scan":
			_assign_scanners_to_targets(targets)
			get_viewport().set_input_as_handled()
		elif component_command_mode == "mine":
			_assign_miners_to_targets(targets)
			get_viewport().set_input_as_handled()

func _find_resources_near(world_pos: Vector2, radius: float) -> Array:
	var result: Array = []
	var nodes = get_tree().get_nodes_in_group("resources")
	for n in nodes:
		if not (n is ResourceNode):
			continue
		var dist = world_pos.distance_to(n.global_position)
		if dist <= radius:
			result.append(n)
	return result

func _assign_scanners_to_targets(targets: Array) -> void:
	var scanners: Array = []
	for c in scanner_components:
		if is_instance_valid(c) and c.is_selected:
			scanners.append(c)
	if scanners.is_empty():
		scanners = scanner_components.duplicate()
	if scanners.is_empty():
		return
	for i in range(scanners.size()):
		var t = targets[min(i, targets.size() - 1)]
		scanners[i].scan(t)

func _assign_miners_to_targets(targets: Array) -> void:
	var miners: Array = []
	for m in mining_components:
		if is_instance_valid(m) and m.is_selected:
			miners.append(m)
	if miners.is_empty():
		miners = mining_components.duplicate()
	if miners.is_empty():
		return
	for i in range(miners.size()):
		var t = targets[min(i, targets.size() - 1)]
		miners[i].mine(t)

func _spawn_selection_ring():
	if not VfxDirector:
		return
	var scale_factor = max(_compute_hull_radius() / 128.0, 0.8)
	if selection_ring_effect and is_instance_valid(selection_ring_effect):
		VfxDirector.recycle(selection_ring_effect)
	selection_ring_effect = VfxDirector.spawn_hologram_ring(self, Vector2.ZERO, scale_factor, Color(0.3, 0.9, 1.0))
	if selection_ring_effect:
		selection_ring_effect.set_as_top_level(true)
		selection_ring_effect.global_position = global_position
		selection_ring_effect.rotation = 0.0

func _clear_selection_ring():
	if selection_ring_effect and is_instance_valid(selection_ring_effect):
		VfxDirector.recycle(selection_ring_effect)
	selection_ring_effect = null

func _compute_hull_radius() -> float:
	if not runtime_blueprint:
		return 96.0
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	for hull_pos in runtime_blueprint.hull_cells.keys():
		var pixel_pos = HexGrid.hex_to_pixel(hull_pos, cell_px)
		var hex_vertices = HexGrid.get_hex_vertices(pixel_pos, cell_px)
		for vertex in hex_vertices:
			min_x = min(min_x, vertex.x)
			max_x = max(max_x, vertex.x)
			min_y = min(min_y, vertex.y)
			max_y = max(max_y, vertex.y)
	return max(max_x - min_x, max_y - min_y) * 0.5

func _create_weapon_panel_if_needed():
	"""Create weapon panel UI if it doesn't exist"""
	if weapon_panel and is_instance_valid(weapon_panel):
		weapon_panel.show_for_ship(self)
		return
	
	# Find or create weapon panel in UI layer
	var game_scene = get_tree().current_scene
	if not game_scene:
		return
	
	var ui_layer = game_scene.get_node_or_null("UILayer")
	if not ui_layer:
		ui_layer = game_scene
	
	# Check if panel already exists globally
	var existing_panel = ui_layer.get_node_or_null("ShipWeaponPanel")
	if existing_panel:
		weapon_panel = existing_panel
		weapon_panel.show_for_ship(self)
		return
	
	# Create new panel
	weapon_panel = ShipWeaponPanel.new()
	weapon_panel.name = "ShipWeaponPanel"
	ui_layer.add_child(weapon_panel)
	weapon_panel.show_for_ship(self)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func can_attack() -> bool:
	"""Override to check if ship has weapons"""
	return weapon_components.size() > 0

func get_max_weapon_range() -> float:
	"""Get the maximum range of all weapons"""
	var max_range = 0.0
	for weapon in weapon_components:
		max_range = max(max_range, weapon.get_range())
	return max_range

func toggle_weapon(weapon_index: int, enabled: bool):
	"""Enable or disable a specific weapon"""
	if weapon_index >= 0 and weapon_index < weapon_enabled.size():
		weapon_enabled[weapon_index] = enabled

func get_weapon_count() -> int:
	"""Get total number of weapons"""
	return weapon_components.size()

func _process_weapon_targeting(delta: float):
	"""Process per-weapon targeting - each weapon independently finds enemies in range"""
	if not EntityManager or not ZoneManager:
		return
	
	# Ensure weapon_targets array is correct size
	if weapon_targets.size() != weapon_components.size():
		weapon_targets.resize(weapon_components.size())
		for i in range(weapon_targets.size()):
			weapon_targets[i] = null
	
	var current_zone_id = ZoneManager.get_unit_zone(self)
	if current_zone_id.is_empty():
		# Clear all targets if not in a zone
		for i in range(weapon_targets.size()):
			weapon_targets[i] = null
		return
	
	# Get VisualContainer for coordinate space
	var visual_container = get_node_or_null("VisualContainer")
	if not visual_container:
		return
	
	# For each weapon, find nearest enemy in range
	for i in range(weapon_components.size()):
		if not weapon_enabled[i]:
			weapon_targets[i] = null
			continue
		
		var weapon = weapon_components[i]
		var weapon_range = weapon.get_range()
		
		# Calculate weapon world position
		var container_global_rotation = rotation + visual_container.rotation
		var weapon_world_pos = global_position + weapon_positions[i].rotated(container_global_rotation)
		
		# Find nearest enemy in zone within weapon range
		var nearest_enemy = null
		var min_distance_sq = weapon_range * weapon_range  # Use squared for comparison
		
		if EntityManager.has_method("get_units_in_radius_zone"):
			# Get all enemies within weapon range
			var enemies_in_range = EntityManager.get_units_in_radius_zone(weapon_world_pos, weapon_range, 1, current_zone_id)  # team_id 1 = enemies
			
			# Find nearest enemy from those in range
			for enemy in enemies_in_range:
				if not is_instance_valid(enemy) or enemy == self:
					continue
				var distance_sq = weapon_world_pos.distance_squared_to(enemy.global_position)
				if distance_sq < min_distance_sq:
					min_distance_sq = distance_sq
					nearest_enemy = enemy
		
		weapon_targets[i] = nearest_enemy

func _process_weapon_firing(delta: float):
	"""Process per-weapon firing - weapons fire independently when targets are in range"""
	# Ensure arrays are correct size
	if weapon_targets.size() != weapon_components.size():
		return
	
	var visual_container = get_node_or_null("VisualContainer")
	if not visual_container:
		return
	
	# For each weapon, fire if target is in range
	for i in range(weapon_components.size()):
		if not weapon_enabled[i]:
			continue
		
		var weapon = weapon_components[i]
		var target_pos = Vector2.ZERO
		var has_target = false
		var is_entity_target = false
		var target_entity_for_fire: Node2D = null
		
		# Priority 1: Check for weapon-specific marker (highest priority)
		if _has_weapon_marker(i):
			target_pos = _get_weapon_marker_position(i)
			has_target = true
			# Update weapon's target AOE radius from marker (for flak cannon adjustments)
			var marker = weapon_markers[i]
			if marker and is_instance_valid(marker) and weapon.has_method("set_target_aoe_radius"):
				weapon.set_target_aoe_radius(marker.get_current_aoe_radius())
		# Priority 2: For non-manually-controlled weapons, check auto-acquired target
		elif i not in active_weapon_indices:
			var target = weapon_targets[i]
			if target and is_instance_valid(target):
				target_pos = target.global_position
				has_target = true
				is_entity_target = true
				target_entity_for_fire = target
			# Priority 3: Legacy attack ground marker (only if no weapons manually selected)
			elif attack_ground_active and attack_ground_marker and attack_ground_marker.visible:
				if active_weapon_indices.is_empty():
					target_pos = attack_ground_marker.global_position
					has_target = true
		
		if not has_target:
			continue
		
		# Check if target is still in range
		var container_global_rotation = rotation + visual_container.rotation
		var weapon_world_pos = global_position + weapon_positions[i].rotated(container_global_rotation)
		var distance = weapon_world_pos.distance_to(target_pos)
		
		if distance <= weapon.get_range() and weapon.can_fire():
			# Trigger recoil animation BEFORE firing
			if i < turret_recoil.size():
				turret_recoil[i] = 1.0  # Start recoil animation
			
			# Fire weapon
			if is_entity_target and target_entity_for_fire:
				weapon.fire_at(target_entity_for_fire, weapon_world_pos)
			else:
				weapon.fire_at_position(target_pos, weapon_world_pos)

func _update_turret_rotations_auto(delta: float):
	"""Update weapon turrets to rotate toward their individual targets (excluding manually controlled)"""
	# Get VisualContainer for coordinate space reference
	var visual_container = get_node_or_null("VisualContainer")
	if not visual_container:
		return
	
	# Ensure arrays are correct size
	if weapon_targets.size() != weapon_turrets.size():
		return
	
	for i in range(weapon_turrets.size()):
		if i >= weapon_turrets.size() or i >= weapon_targets.size():
			continue
			
		# Skip manually controlled turrets (they're handled in _process)
		if i in active_weapon_indices:
			continue
		
		var turret = weapon_turrets[i]
		if not is_instance_valid(turret):
			continue
		
		var target_pos = Vector2.ZERO
		var has_target = false
		
		# Priority 1: Weapon-specific marker (highest priority)
		if _has_weapon_marker(i):
			target_pos = _get_weapon_marker_position(i)
			has_target = true
		# Priority 2: Auto-acquired target
		else:
			var target = weapon_targets[i]
			if target and is_instance_valid(target):
				target_pos = target.global_position
				has_target = true
			# Priority 3: Legacy attack ground marker
			elif attack_ground_active and attack_ground_marker and attack_ground_marker.visible:
				if active_weapon_indices.is_empty():
					target_pos = attack_ground_marker.global_position
					has_target = true
		
		if has_target:
			# Get turret's global position (Godot handles parent transformations)
			var turret_world_pos = turret.global_position
			
			# Calculate direction from turret to target in world space
			var direction_to_target = (target_pos - turret_world_pos).normalized()
			var target_angle_world = direction_to_target.angle()
			
			# Calculate what rotation the turret needs in its local space (VisualContainer space)
			# VisualContainer's global rotation = ship.rotation + VisualContainer.rotation
			var container_global_rotation = rotation + visual_container.rotation
			var turret_local_rotation = target_angle_world - container_global_rotation + PI / 2.0  # Add 90-degree offset
			
			# Smoothly rotate turret (2x faster than ship rotation for responsive tracking)
			turret.rotation = lerp_angle(turret.rotation, turret_local_rotation, rotation_speed * 2.0 * delta)
			
			# Apply recoil as position offset (turret moves backward when firing)
			if i < turret_recoil.size() and i < turret_base_positions.size():
				var recoil_amount = turret_recoil[i]
				if recoil_amount > 0.0:
					# Calculate backward direction (opposite of turret's forward direction)
					# Turret rotation has PI/2 offset, so actual forward is rotation - PI/2
					var actual_forward_angle = turret.rotation - PI / 2.0
					var forward_dir = Vector2(cos(actual_forward_angle), sin(actual_forward_angle))
					var backward_dir = -forward_dir
					# Move turret backward by recoil amount (max 8 pixels)
					var recoil_offset = backward_dir * recoil_amount * 8.0
					turret.position = turret_base_positions[i] + recoil_offset
				else:
					# Smoothly return to base position
					turret.position = turret.position.lerp(turret_base_positions[i], delta * 10.0)
			else:
				if i < turret_base_positions.size():
					turret.position = turret_base_positions[i]
		else:
			# No target - return turret to neutral position (0 rotation, accounting for 90-degree offset)
			var neutral_rotation = PI / 2.0  # 90 degrees offset
			turret.rotation = lerp_angle(turret.rotation, neutral_rotation, rotation_speed * delta)
			
			# Return to base position (with recoil if active)
			if i < turret_recoil.size() and i < turret_base_positions.size():
				var recoil_amount = turret_recoil[i]
				if recoil_amount > 0.0:
					# Calculate backward direction (opposite of turret's forward direction)
					# Turret rotation has PI/2 offset, so actual forward is rotation - PI/2
					var actual_forward_angle = turret.rotation - PI / 2.0
					var forward_dir = Vector2(cos(actual_forward_angle), sin(actual_forward_angle))
					var backward_dir = -forward_dir
					# Move turret backward by recoil amount (max 8 pixels)
					var recoil_offset = backward_dir * recoil_amount * 8.0
					turret.position = turret_base_positions[i] + recoil_offset
				else:
					# Smoothly return to base position
					turret.position = turret.position.lerp(turret_base_positions[i], delta * 10.0)
			else:
				if i < turret_base_positions.size():
					turret.position = turret_base_positions[i]

func _update_turret_recoil(delta: float):
	"""Update recoil animation for all turrets"""
	for i in range(turret_recoil.size()):
		if turret_recoil[i] > 0.0:
			# Decay recoil over time (0.3 seconds to return to 0 for more visible effect)
			turret_recoil[i] = max(0.0, turret_recoil[i] - delta * 3.33)

func get_weapon_info(weapon_index: int) -> Dictionary:
	"""Get information about a specific weapon"""
	if weapon_index < 0 or weapon_index >= weapon_components.size():
		return {}
	
	var weapon = weapon_components[weapon_index]
	var type_str = weapon.get_display_name() if weapon.has_method("get_display_name") else "Weapon"
	
	return {
		"type": type_str,
		"damage": weapon.damage,
		"range": weapon.get_range(),
		"fire_rate": weapon.fire_rate,
		"enabled": weapon_enabled[weapon_index] if weapon_index < weapon_enabled.size() else true
	}

func manual_fire_weapon(weapon_index: int, target_pos: Vector2) -> bool:
	"""Manually fire a single weapon at target position. Returns true if fired."""
	if weapon_index < 0 or weapon_index >= weapon_components.size():
		return false
	if not weapon_enabled[weapon_index]:
		return false
	
	var weapon = weapon_components[weapon_index]
	if not weapon.can_fire():
		return false  # On cooldown
	
	# Calculate weapon world position
	var visual_container = get_node_or_null("VisualContainer")
	if not visual_container:
		return false
	
	var container_global_rotation = rotation + visual_container.rotation
	var weapon_world_pos = global_position + weapon_positions[weapon_index].rotated(container_global_rotation)
	
	# Trigger recoil animation
	if weapon_index < turret_recoil.size():
		turret_recoil[weapon_index] = 1.0
	
	# Rotate turret toward target instantly for manual fire
	if weapon_index < weapon_turrets.size():
		var turret = weapon_turrets[weapon_index]
		if is_instance_valid(turret):
			var direction_to_target = (target_pos - weapon_world_pos).normalized()
			var target_angle_world = direction_to_target.angle()
			var turret_local_rotation = target_angle_world - container_global_rotation + PI / 2.0
			turret.rotation = turret_local_rotation
	
	# Fire the weapon
	weapon.fire_at_position(target_pos, weapon_world_pos)
	return true

func get_weapon_cooldown_percent(weapon_index: int) -> float:
	"""Returns 0.0 when ready to fire, 1.0 when just fired (full cooldown)"""
	if weapon_index < 0 or weapon_index >= weapon_components.size():
		return 0.0
	var weapon = weapon_components[weapon_index]
	return weapon.get_cooldown_percent() if weapon.has_method("get_cooldown_percent") else 0.0

# ============================================================================
# SAVE/LOAD SYSTEM
# ============================================================================

func get_save_data() -> Dictionary:
	"""Save custom ship blueprint data for persistence"""
	var data = {}
	
	# Save blueprint reference
	if has_meta("source_blueprint"):
		data["source_blueprint"] = get_meta("source_blueprint")
	if has_meta("blueprint_type"):
		data["blueprint_type"] = get_meta("blueprint_type")
	
	# Save Cosmoteer blueprint path if available
	if cosmoteer_blueprint:
		data["cosmoteer_blueprint_name"] = cosmoteer_blueprint.blueprint_name
	
	# Save legacy placements if available
	if placements.size() > 0:
		data["placements"] = placements
	
	# Save weapon states
	if weapon_enabled.size() > 0:
		data["weapon_enabled"] = weapon_enabled
	
	return data

func restore_from_save_data(data: Dictionary):
	"""Restore custom ship from saved data"""
	# Restore cosmoteer blueprint
	if data.has("cosmoteer_blueprint_name"):
		var blueprint_name = data["cosmoteer_blueprint_name"]
		var blueprint_path = "res://ship_blueprints/" + blueprint_name + ".tres"
		
		if ResourceLoader.exists(blueprint_path):
			var blueprint = ResourceLoader.load(blueprint_path)
			if blueprint is CosmoteerShipBlueprint:
				initialize_from_cosmoteer_blueprint(blueprint)
				print("CustomShip: Restored from Cosmoteer blueprint '%s' with %d engines" % [blueprint_name, engine_particles.size()])
			else:
				push_error("CustomShip: Invalid blueprint at %s" % blueprint_path)
		else:
			push_error("CustomShip: Blueprint not found at %s" % blueprint_path)
	
	# Restore legacy placements
	elif data.has("placements"):
		initialize_from_blueprint({"placements": data["placements"]})
		print("CustomShip: Restored from legacy placements")
	
	# Restore weapon states
	if data.has("weapon_enabled") and weapon_enabled.size() > 0:
		var saved_states = data["weapon_enabled"]
		for i in range(min(saved_states.size(), weapon_enabled.size())):
			weapon_enabled[i] = saved_states[i]
			# Note: weapon_enabled array controls firing behavior in process_combat_state()
	
	# Restore metadata
	if data.has("source_blueprint"):
		set_meta("source_blueprint", data["source_blueprint"])
	if data.has("blueprint_type"):
		set_meta("blueprint_type", data["blueprint_type"])
