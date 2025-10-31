extends BaseUnit
## Runtime-assembled ship from a blueprint layout

var placements: Array = []
var cell_px: int = 32
var cosmoteer_blueprint: CosmoteerShipBlueprint = null

# Weapon system
var weapon_components: Array[WeaponComponent] = []
var weapon_enabled: Array[bool] = []  # Track which weapons are enabled
var weapon_positions: Array[Vector2] = []  # Local positions of weapons on ship
var weapon_turrets: Array[Sprite2D] = []  # Visual turret sprites

# Shield system
var shield_component: ShieldComponent = null
var shield_bar: ProgressBar = null

# Range indicator
var range_indicator: WeaponRangeIndicator = null

# Weapon panel UI
var weapon_panel: ShipWeaponPanel = null

# Engine particle system
var engine_particles: Array[GPUParticles2D] = []
var engine_thrust_direction: Vector2 = Vector2.ZERO  # Cached from blueprint

func _ready():
	super._ready()
	unit_name = "Custom Ship"
	
	# Add to proper groups for selection and combat
	add_to_group("units")
	add_to_group("player_units")

func initialize_from_blueprint(data: Dictionary):
	"""Legacy blueprint system"""
	if data.has("placements"):
		placements = data["placements"]
	_build_visuals()

func initialize_from_cosmoteer_blueprint(blueprint: CosmoteerShipBlueprint):
	"""Initialize from Cosmoteer-style blueprint"""
	cosmoteer_blueprint = blueprint
	
	# Apply stats from blueprint
	apply_blueprint_stats(blueprint)
	
	# Build visual representation
	_build_visuals_cosmoteer(blueprint)
	
	# Instantiate functional components (needs to happen after visuals for VisualContainer access)
	_instantiate_weapon_components(blueprint)
	_instantiate_shield_components(blueprint)
	_instantiate_engine_particles(blueprint)
	
	# Create UI elements
	_create_shield_bar()
	_create_weapon_range_indicator(blueprint)
	
	# Set unit name from blueprint
	unit_name = blueprint.blueprint_name
	
	# Store blueprint reference
	set_meta("source_blueprint", blueprint.blueprint_name)
	set_meta("blueprint_type", "cosmoteer")
	
	print("CustomShip '%s' initialized with %d weapons" % [unit_name, weapon_components.size()])

func apply_blueprint_stats(blueprint: CosmoteerShipBlueprint):
	"""Calculate and apply stats from blueprint"""
	# Health = 10 HP per hull cell
	max_health = blueprint.get_hull_cell_count() * 10.0
	current_health = max_health
	
	# Speed from calculator
	move_speed = CosmoteerShipStatsCalculator.calculate_speed(blueprint)
	
	# Other stats
	var power = CosmoteerShipStatsCalculator.calculate_power(blueprint)
	set_meta("power_generated", power.get("generated", 0))
	set_meta("power_consumed", power.get("consumed", 0))
	
	var weight_thrust = CosmoteerShipStatsCalculator.calculate_weight_thrust(blueprint)
	set_meta("weight", weight_thrust.get("weight", 0))
	set_meta("thrust", weight_thrust.get("thrust", 0))
	
	print("CustomShip stats applied: HP=%.0f, Speed=%.1f" % [max_health, move_speed])

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
	
	# Calculate bounding box to properly center the ship
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for hull_pos in blueprint.hull_cells.keys():
		min_x = min(min_x, hull_pos.x)
		max_x = max(max_x, hull_pos.x)
		min_y = min(min_y, hull_pos.y)
		max_y = max(max_y, hull_pos.y)
	
	# Calculate center offset
	var center_offset = Vector2(
		(min_x + max_x) * 0.5 * cell_px + cell_px * 0.5,
		(min_y + max_y) * 0.5 * cell_px + cell_px * 0.5
	)
	
	# Render hull cells in the visual container
	for hull_pos in blueprint.hull_cells.keys():
		var hull_type = blueprint.get_hull_type(hull_pos)
		var texture_path = CosmoteerComponentDefs.get_hull_texture(hull_type)
		
		# Try to use texture, fallback to colored rectangle
		if texture_path and ResourceLoader.exists(texture_path):
			var texture = load(texture_path)
			if texture:
				var hull_sprite = Sprite2D.new()
				hull_sprite.texture = texture
				hull_sprite.position = Vector2(hull_pos.x * cell_px, hull_pos.y * cell_px) - center_offset
				hull_sprite.position += Vector2(cell_px * 0.5, cell_px * 0.5)  # Center sprite
				hull_sprite.centered = true
				# Scale to fit cell size
				var texture_size = texture.get_size()
				hull_sprite.scale = Vector2(cell_px / texture_size.x, cell_px / texture_size.y)
				hull_sprite.z_index = -1
				visual_container.add_child(hull_sprite)
			else:
				# Fallback to color rect
				var hull_rect = ColorRect.new()
				hull_rect.color = CosmoteerComponentDefs.get_hull_color(hull_type)
				hull_rect.size = Vector2(cell_px, cell_px)
				hull_rect.position = Vector2(hull_pos.x * cell_px, hull_pos.y * cell_px) - center_offset
				hull_rect.z_index = -1
				visual_container.add_child(hull_rect)
		else:
			# Fallback to color rect
			var hull_rect = ColorRect.new()
			hull_rect.color = CosmoteerComponentDefs.get_hull_color(hull_type)
			hull_rect.size = Vector2(cell_px, cell_px)
			hull_rect.position = Vector2(hull_pos.x * cell_px, hull_pos.y * cell_px) - center_offset
			hull_rect.z_index = -1
			visual_container.add_child(hull_rect)
	
	# Render components on top in the visual container
	for comp_data in blueprint.components:
		var comp_type = comp_data.get("type", "")
		var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
		var comp_size = comp_data.get("size", Vector2i.ONE)
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_type)
		
		if comp_def.is_empty():
			continue
		
		var sprite_path = comp_def.get("sprite", "")
		
		# Try to use texture, fallback to colored rectangle
		if sprite_path and ResourceLoader.exists(sprite_path):
			var texture = load(sprite_path)
			if texture:
				var comp_sprite = Sprite2D.new()
				comp_sprite.texture = texture
				# Position at center of component area
				comp_sprite.position = Vector2(comp_pos.x * cell_px, comp_pos.y * cell_px) - center_offset
				comp_sprite.position += Vector2(comp_size.x * cell_px * 0.5, comp_size.y * cell_px * 0.5)
				comp_sprite.centered = true
				# Scale to fit component size
				var texture_size = texture.get_size()
				var target_size = Vector2(comp_size.x * cell_px, comp_size.y * cell_px)
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
	"""Create a colored rectangle fallback for components without textures"""
	var comp_rect = ColorRect.new()
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
	
	comp_rect.color = color
	comp_rect.size = Vector2(comp_size.x * cell_px, comp_size.y * cell_px)
	comp_rect.position = Vector2(comp_pos.x * cell_px, comp_pos.y * cell_px) - center_offset
	comp_rect.z_index = 0
	visual_container.add_child(comp_rect)

func _generate_collision_from_hull(blueprint: CosmoteerShipBlueprint):
	"""Create collision shape based on hull cells"""
	# Simple approach: use a circle based on hull extent
	var hull_count = blueprint.get_hull_cell_count()
	if hull_count == 0:
		return
	
	# Calculate approximate radius
	var radius = sqrt(hull_count) * cell_px * 0.5
	
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
	"""Create particle effects for engines"""
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
		container_rotation = default_rotation - (forward_angle - default_forward_angle)
	
	# Rotate thrust direction to match VisualContainer coordinate system
	engine_thrust_direction = blueprint_thrust_direction.rotated(container_rotation)
	
	# Calculate the same center offset used for visuals
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for hull_pos in blueprint.hull_cells.keys():
		min_x = min(min_x, hull_pos.x)
		max_x = max(max_x, hull_pos.x)
		min_y = min(min_y, hull_pos.y)
		max_y = max(max_y, hull_pos.y)
	
	var center_offset = Vector2(
		(min_x + max_x) * 0.5 * cell_px + cell_px * 0.5,
		(min_y + max_y) * 0.5 * cell_px + cell_px * 0.5
	)
	
	# visual_container already retrieved at the start of function
	if not visual_container:
		return
	
	for comp_data in blueprint.components:
		var comp_id = comp_data.get("type", "")
		var parsed = CosmoteerComponentDefs.parse_component_id(comp_id)
		var comp_type = parsed["type"]
		var comp_level = parsed["level"]
		
		if comp_type != "engine":
			continue
		
		var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
		var comp_size = comp_data.get("size", Vector2i.ONE)
		
		# Calculate engine center in local coordinates
		var engine_local_pos = Vector2(comp_pos.x * cell_px, comp_pos.y * cell_px) - center_offset
		engine_local_pos += Vector2(comp_size.x * cell_px * 0.5, comp_size.y * cell_px * 0.5)
		
		# Scale particle count with engine level
		var num_streams = 2  # Base for levels 1-3
		if comp_level >= 7:
			num_streams = 4  # Levels 7-9
		elif comp_level >= 4:
			num_streams = 3  # Levels 4-6
		
		var particles_per_stream = 40 + (comp_level - 1) * 5  # Scale up with level
		
		# Create dual/triple/quad particle streams for powerful effect
		var perpendicular = Vector2(-engine_thrust_direction.y, engine_thrust_direction.x)
		var stream_offset = cell_px * 0.2  # Offset between streams
		
		# Create particle streams per engine
		for stream_idx in range(num_streams):
			# Calculate stream position offset
			var offset_multiplier = 0.0
			if num_streams == 2:
				offset_multiplier = 1.0 if stream_idx == 0 else -1.0
			elif num_streams == 3:
				offset_multiplier = (stream_idx - 1.0) * 1.0  # -1, 0, 1
			else:  # 4 streams
				offset_multiplier = (stream_idx - 1.5) * 0.7  # -1.05, -0.35, 0.35, 1.05
			
			var offset_dir = perpendicular * offset_multiplier
			var stream_pos = engine_local_pos + offset_dir * stream_offset
			
			var particles = GPUParticles2D.new()
			particles.name = "EngineParticles_%d_%d" % [engine_particles.size(), stream_idx]
			particles.position = stream_pos
			particles.amount = particles_per_stream
			particles.lifetime = 0.6  # Slightly longer
			particles.preprocess = 0.2
			particles.explosiveness = 0.0
			particles.randomness = 0.2  # Less random for tighter trails
			particles.z_index = -2  # Behind ship
			particles.emitting = false  # Start off, will enable when moving
			
			# Create particle material
			var material = ParticleProcessMaterial.new()
			
			# Emission shape - point
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
			
			# Direction - emit in thrust direction
			# In VisualContainer space, the thrust direction is already correct
			# We just need to use it directly (no rotation needed since particles are in VisualContainer)
			material.direction = Vector3(engine_thrust_direction.x, engine_thrust_direction.y, 0)
			material.spread = 1.5  # Very tight cone for trail effect
			
			# Velocity - higher for trail effect
			material.initial_velocity_min = 100.0
			material.initial_velocity_max = 150.0
			
			# Linear accel (slow down gradually)
			material.linear_accel_min = -50.0
			material.linear_accel_max = -30.0
			
			# Scale - elongated particles for trail effect
			material.scale_min = 2.0
			material.scale_max = 3.5
			material.scale_curve = _create_fade_curve()
			
			# Particle flags for trail effect
			material.particle_flag_align_y = true  # Align particles to velocity direction
			
			# Color (cyan/blue thrust with gradient)
			material.color = Color(0.5, 0.8, 1.0, 1.0)
			material.color_ramp = _create_color_ramp()
			
			particles.process_material = material
			
			# Add to visual container
			visual_container.add_child(particles)
			engine_particles.append(particles)
	
	print("Created %d engine particle systems" % engine_particles.size())

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
	"""Create functional weapon components from blueprint data"""
	var weapon_index = 0
	
	# Calculate the same center offset used for visuals
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for hull_pos in blueprint.hull_cells.keys():
		min_x = min(min_x, hull_pos.x)
		max_x = max(max_x, hull_pos.x)
		min_y = min(min_y, hull_pos.y)
		max_y = max(max_y, hull_pos.y)
	
	var center_offset = Vector2(
		(min_x + max_x) * 0.5 * cell_px + cell_px * 0.5,
		(min_y + max_y) * 0.5 * cell_px + cell_px * 0.5
	)
	
	for comp_data in blueprint.components:
		var comp_id = comp_data.get("type", "")
		var parsed = CosmoteerComponentDefs.parse_component_id(comp_id)
		var comp_type = parsed["type"]
		
		# Only process weapon components
		if comp_type != "laser_weapon" and comp_type != "missile_launcher":
			continue
		
		var comp_def = CosmoteerComponentDefs.get_component_data(comp_id)
		if comp_def.is_empty():
			continue
		
		# Create weapon component
		var weapon = WeaponComponent.new()
		weapon.name = "Weapon_%d" % weapon_index
		
		# Configure weapon from component definition (level-specific damage)
		if comp_type == "laser_weapon":
			weapon.weapon_type = WeaponComponent.WeaponType.LASER
			weapon.damage = comp_def.get("damage", 10.0)
			weapon.fire_rate = 2.0  # 2 shots per second
			weapon.rangeAim = 250.0
			weapon.projectile_speed = 600.0
			weapon.homing = false
		elif comp_type == "missile_launcher":
			weapon.weapon_type = WeaponComponent.WeaponType.MISSILE
			weapon.damage = comp_def.get("damage", 50.0)
			weapon.fire_rate = 0.5  # 0.5 shots per second
			weapon.rangeAim = 400.0
			weapon.projectile_speed = 400.0
			weapon.homing = true
		
		# Calculate weapon position at component grid location (centered, matching visual offset)
		var comp_pos = comp_data.get("grid_position", Vector2i.ZERO)
		var comp_size = comp_data.get("size", Vector2i.ONE)
		var local_pos = Vector2(comp_pos.x * cell_px, comp_pos.y * cell_px) - center_offset
		local_pos += Vector2(comp_size.x * cell_px * 0.5, comp_size.y * cell_px * 0.5)  # Center of component
		
		add_child(weapon)
		weapon_components.append(weapon)
		weapon_enabled.append(true)  # All weapons enabled by default
		weapon_positions.append(local_pos)  # Store position separately
		
		# Create visual turret sprite for this weapon
		var turret_sprite = _create_weapon_turret(local_pos, comp_type)
		weapon_turrets.append(turret_sprite)
		
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
		var hull_count = blueprint.get_hull_cell_count()
		shield_component.shield_radius = sqrt(hull_count) * cell_px * 0.6
		
		add_child(shield_component)
		print("Created shield component with %d HP" % total_shield_hp)

# ============================================================================
# UI ELEMENTS
# ============================================================================

func _create_shield_bar():
	"""Create shield progress bar above health bar"""
	shield_bar = ProgressBar.new()
	shield_bar.name = "ShieldBar"
	shield_bar.custom_minimum_size = Vector2(40, 6)
	shield_bar.size = Vector2(40, 6)
	shield_bar.show_percentage = false
	shield_bar.top_level = true
	shield_bar.z_index = 100
	
	# Style the shield bar
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.2, 0.8)
	shield_bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.3, 0.7, 1.0, 0.9)  # Cyan for shields
	shield_bar.add_theme_stylebox_override("fill", fill_style)
	
	add_child(shield_bar)
	
	# Set max value
	if shield_component:
		shield_bar.max_value = shield_component.max_shield
		shield_bar.value = shield_component.current_shield
		shield_bar.visible = true
	else:
		shield_bar.visible = false

func _create_weapon_range_indicator(blueprint: CosmoteerShipBlueprint):
	"""Create weapon range indicator"""
	# Find max weapon range
	var max_range = 0.0
	var has_laser = false
	var has_missile = false
	
	for weapon in weapon_components:
		max_range = max(max_range, weapon.rangeAim)
		if weapon.weapon_type == WeaponComponent.WeaponType.LASER:
			has_laser = true
		elif weapon.weapon_type == WeaponComponent.WeaponType.MISSILE:
			has_missile = true
	
	if max_range > 0:
		range_indicator = WeaponRangeIndicator.new()
		range_indicator.name = "WeaponRangeIndicator"
		range_indicator.range_radius = max_range
		
		# Set weapon type based on what weapons we have
		if has_laser and has_missile:
			range_indicator.weapon_type = WeaponRangeIndicator.WeaponType.MIXED
		elif has_missile:
			range_indicator.weapon_type = WeaponRangeIndicator.WeaponType.MISSILE
		else:
			range_indicator.weapon_type = WeaponRangeIndicator.WeaponType.LASER
		
		range_indicator.z_index = -10
		add_child(range_indicator)
		
		# Initially hidden, shown when selected
		range_indicator.visible = false

# ============================================================================
# COMBAT OVERRIDE
# ============================================================================

func process_combat_state(delta: float):
	"""Override combat behavior for multi-weapon ships"""
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
	
	# Update turret rotations to track target (always, even when moving)
	_update_turret_rotations(target_entity, delta)
	
	# Move to optimal range (80% of max weapon range)
	if distance > max_range * 0.8:
		# Move closer
		target_position = target_entity.global_position
		var direction = (target_entity.global_position - global_position).normalized()
		desired_velocity = direction * move_speed
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	else:
		# In range - slow down and fire
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta * 2.0)
		
		# Rotate to face target
		var direction_to_target = (target_entity.global_position - global_position).normalized()
		var target_rotation = direction_to_target.angle()
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)
		
		# Fire all enabled weapons that are in range
		for i in range(weapon_components.size()):
			if weapon_enabled[i]:
				var weapon = weapon_components[i]
				if distance <= weapon.get_range():
					# Calculate weapon world position using stored position
					# Apply -90 degree offset for visual rotation, then apply ship rotation
					var rotated_pos = weapon_positions[i].rotated(-PI / 2.0)
					var weapon_world_pos = global_position + rotated_pos.rotated(rotation)
					weapon.fire_at(target_entity, weapon_world_pos)

# ============================================================================
# DAMAGE HANDLING
# ============================================================================

func take_damage(amount: float, attacker: Node2D = null):
	"""Override damage to route through shields first"""
	var actual_damage = amount
	
	# Shield absorbs damage first
	if shield_component and shield_component.current_shield > 0:
		var excess_damage = shield_component.take_damage(amount)
		actual_damage = excess_damage
	
	# Apply remaining damage to hull
	if actual_damage > 0:
		super.take_damage(actual_damage, attacker)

# ============================================================================
# UPDATE VISUAL
# ============================================================================

func update_visual():
	"""Override to update shield bar position"""
	super.update_visual()
	
	# Update shield bar position and value
	if shield_bar and shield_component:
		if shield_bar.top_level:
			shield_bar.global_position = global_position + Vector2(-20, -45)
			shield_bar.rotation = 0
		shield_bar.value = shield_component.current_shield
		shield_bar.visible = shield_component.max_shield > 0
	
	# Update engine particles based on movement
	_update_engine_particles()

func _update_engine_particles():
	"""Enable/disable engine particles based on ship velocity"""
	if engine_particles.is_empty():
		return
	
	# Check if ship is moving (velocity magnitude > threshold)
	var is_moving = velocity.length() > 10.0
	
	# Enable/disable all engine particles
	for particles in engine_particles:
		if is_instance_valid(particles):
			particles.emitting = is_moving

# ============================================================================
# SELECTION HANDLING
# ============================================================================

func set_selected(selected: bool):
	"""Override to show/hide range indicator on selection"""
	super.set_selected(selected)
	
	# Show/hide weapon range indicator
	if range_indicator:
		if selected:
			range_indicator.show_range()
		else:
			range_indicator.hide_range()
	
	# Handle weapon panel - only for player ships with weapons
	if selected and team_id == 0 and weapon_components.size() > 0:
		_create_weapon_panel_if_needed()
	elif weapon_panel:
		weapon_panel.hide()

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

func _update_turret_rotations(target: Node2D, delta: float):
	"""Update all weapon turrets to rotate toward target"""
	if not is_instance_valid(target):
		return
	
	# Get VisualContainer for coordinate space reference
	var visual_container = get_node_or_null("VisualContainer")
	if not visual_container:
		return
	
	for i in range(weapon_turrets.size()):
		if i >= weapon_turrets.size():
			continue
		
		var turret = weapon_turrets[i]
		if not is_instance_valid(turret):
			continue
		
		# Get turret's global position (Godot handles parent transformations)
		var turret_world_pos = turret.global_position
		
		# Calculate direction from turret to target in world space
		var direction_to_target = (target.global_position - turret_world_pos).normalized()
		var target_angle_world = direction_to_target.angle()
		
		# Calculate what rotation the turret needs in its local space (VisualContainer space)
		# VisualContainer's global rotation = ship.rotation + VisualContainer.rotation
		var container_global_rotation = rotation + visual_container.rotation
		var turret_local_rotation = target_angle_world - container_global_rotation
		
		# Smoothly rotate turret (2x faster than ship rotation for responsive tracking)
		turret.rotation = lerp_angle(turret.rotation, turret_local_rotation, rotation_speed * 2.0 * delta)

func get_weapon_info(weapon_index: int) -> Dictionary:
	"""Get information about a specific weapon"""
	if weapon_index < 0 or weapon_index >= weapon_components.size():
		return {}
	
	var weapon = weapon_components[weapon_index]
	var type_str = "Laser"
	if weapon.weapon_type == WeaponComponent.WeaponType.MISSILE:
		type_str = "Missile"
	elif weapon.weapon_type == WeaponComponent.WeaponType.PLASMA:
		type_str = "Plasma"
	
	return {
		"type": type_str,
		"damage": weapon.damage,
		"range": weapon.get_range(),
		"fire_rate": weapon.fire_rate,
		"enabled": weapon_enabled[weapon_index] if weapon_index < weapon_enabled.size() else true
	}

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
