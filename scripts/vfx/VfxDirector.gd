extends Node

const EFFECTS := {
	&"shield_hit": {
		"scene": preload("res://vfx/library/shield/ShieldHit.tscn"),
		"lifetime": 0.65,
		"type": &"shader"
	},
	&"explosion_flash": {
		"scene": preload("res://vfx/library/explosion/ExplosionFlash.tscn"),
		"type": &"particles"
	},
	&"explosion_core": {
		"scene": preload("res://vfx/library/explosion/ExplosionCore.tscn"),
		"type": &"particles"
	},
	&"explosion_smoke": {
		"scene": preload("res://vfx/library/explosion/ExplosionSmoke.tscn"),
		"type": &"particles"
	},
	&"engine_plume_small": {
		"scene": preload("res://vfx/library/engine/EnginePlume_S.tscn"),
		"type": &"particles"
	},
	&"engine_plume_medium": {
		"scene": preload("res://vfx/library/engine/EnginePlume_M.tscn"),
		"type": &"particles"
	},
	&"engine_plume_large": {
		"scene": preload("res://vfx/library/engine/EnginePlume_L.tscn"),
		"type": &"particles"
	},
	&"trail_ribbon": {
		"scene": preload("res://vfx/library/engine/TrailRibbon.tscn"),
		"type": &"node"
	},
	&"hologram_ring": {
		"scene": preload("res://vfx/library/hologram/HologramRing.tscn"),
		"lifetime": 1.1,
		"type": &"shader"
	},
	&"scan_wave": {
		"scene": preload("res://vfx/library/hologram/ScanWave.tscn"),
		"lifetime": 1.3,
		"type": &"shader"
	},
	&"mining_beam": {
		"scene": preload("res://vfx/library/mining/MiningBeam.tscn"),
		"lifetime": 0.55,
		"type": &"particles"
	}
}

const QUALITY_RESOURCE_PATH := "res://config/quality_profiles.tres"
const SCORCH_DECAL_MATERIAL: ShaderMaterial = preload("res://vfx/library/decals/ScorchDecal.tres")
const WELD_DECAL_MATERIAL: ShaderMaterial = preload("res://vfx/library/decals/WeldDecal.tres")
const SCORCH_TEXTURES: Array[Texture2D] = [
	preload("res://assets/vfx_textures/scorch_01.png"),
	preload("res://assets/vfx_textures/scorch_02.png"),
	preload("res://assets/vfx_textures/scorch_03.png")
]
const WELD_TEXTURES: Array[Texture2D] = [
	preload("res://assets/vfx_textures/slash_01.png"),
	preload("res://assets/vfx_textures/slash_02.png"),
	preload("res://assets/vfx_textures/slash_03.png"),
	preload("res://assets/vfx_textures/slash_04.png"),
	preload("res://assets/vfx_textures/scratch_01.png")
]

var pools: Dictionary = {}
var active_effects: Dictionary = {}
var quality_profiles: QualityProfiles
var current_profile: StringName = &"high"
var current_profile_data: Dictionary = {}
var _flash_light_texture: GradientTexture1D

func _ready() -> void:
	quality_profiles = ResourceLoader.load(QUALITY_RESOURCE_PATH) as QualityProfiles
	if quality_profiles:
		current_profile = quality_profiles.default_profile
	_apply_global_quality()

func set_quality_profile(name: StringName) -> void:
	if quality_profiles == null:
		return
	current_profile = name
	_apply_global_quality()

func spawn_shield_hit(parent: Node, position: Vector2, radius: float = 128.0, color: Color = Color(0.2, 0.8, 1.0), hit_origin := Vector2(0.5, 0.5)) -> Node:
	var effect := _spawn_effect(&"shield_hit", parent, position)
	if effect == null:
		return null
	effect.scale = Vector2.ONE * (radius / 128.0)

	var polygon := effect.get_node_or_null("Pulse") as Polygon2D
	if polygon and polygon.material is ShaderMaterial:
		var material := polygon.material as ShaderMaterial
		material.set_shader_parameter("hit_time", 0.0)
		material.set_shader_parameter("base_color", color)
		material.set_shader_parameter("hit_origin", hit_origin)

		var tween := effect.create_tween()
		tween.tween_method(Callable(self, "_set_shader_uniform").bind(material, "hit_time"), 0.0, 1.2, 0.6)
		tween.tween_callback(Callable(self, "_return_to_pool").bind(&"shield_hit", effect))

	return effect

func spawn_explosion(parent: Node, position: Vector2, scale_multiplier: float = 1.0) -> void:
	# Safety clamp scale to prevent screen-filling explosions
	scale_multiplier = clampf(scale_multiplier, 0.1, 5.0)
	
	var flash := _spawn_effect(&"explosion_flash", parent, position)
	var core := _spawn_effect(&"explosion_core", parent, position)
	var smoke := _spawn_effect(&"explosion_smoke", parent, position)
	_scale_particles(flash, scale_multiplier)
	_scale_particles(core, scale_multiplier)
	_scale_particles(smoke, scale_multiplier)
	_spawn_flash_light(parent, position, scale_multiplier)

func spawn_engine_plume(size: StringName, parent: Node, position: Vector2, rotation: float = 0.0, intensity: float = 1.0) -> Node:
	# Create EngineBeam2D instead of particle system
	var beam_scene = preload("res://scenes/components/EngineBeam2D.tscn")
	if not beam_scene:
		push_warning("Failed to load EngineBeam2D scene")
		return null
	
	var beam = beam_scene.instantiate() as EngineBeam2D
	if not beam:
		return null
	
	# Set beam properties based on size
	var beam_length: float = 80.0
	var beam_color: Color = Color(0.2, 0.9, 1.0, 1.0)  # Bright cyan for small
	var base_width: float = 8.0  # Increased from 2.5
	
	match size:
		&"medium":
			beam_length = 120.0
			beam_color = Color(0.3, 0.8, 1.0, 1.0)  # Electric blue
			base_width = 12.0  # Increased from 3.5
		&"large":
			beam_length = 160.0
			beam_color = Color(0.4, 0.85, 1.0, 1.0)  # Intense blue-white
			base_width = 16.0  # Increased from 4.5
	
	beam.beam_length = beam_length
	beam.beam_color = beam_color
	beam.base_width = base_width
	beam.intensity = intensity
	beam.position = position
	beam.rotation = rotation
	
	parent.add_child(beam)
	return beam

func spawn_trail(parent: Node, color_start: Color, color_end: Color, points: PackedVector2Array) -> Node:
	var trail := _spawn_effect(&"trail_ribbon", parent, Vector2.ZERO)
	if trail is Line2D:
		trail.set_points(points)
		var material: ShaderMaterial = trail.material as ShaderMaterial
		if material:
			material.set_shader_parameter("color_start", color_start)
			material.set_shader_parameter("color_end", color_end)
	return trail

func spawn_hologram_ring(parent: Node, position: Vector2, radius: float = 1.0, color: Color = Color(0.3, 0.9, 1.0)) -> Node:
	var ring := _spawn_effect(&"hologram_ring", parent, position)
	if ring:
		ring.scale = Vector2.ONE * radius
		_tint_polygon_material(ring, color)
	return ring

func spawn_scan_wave(parent: Node, position: Vector2, radius: float = 1.0, color: Color = Color(0.3, 0.9, 0.6)) -> Node:
	var wave := _spawn_effect(&"scan_wave", parent, position)
	if wave:
		wave.scale = Vector2.ONE * radius
		_tint_polygon_material(wave, color)
	return wave

func spawn_mining_beam(parent: Node, start_position: Vector2, end_position: Vector2) -> Node:
	var beam := _spawn_effect(&"mining_beam", parent, start_position)
	if beam:
		var line := beam.get_node_or_null("Beam") as Line2D
		if line:
			var local_end := end_position - start_position
			line.points = PackedVector2Array([Vector2.ZERO, local_end])
		var particles := beam.get_node_or_null("ChipParticles") as GPUParticles2D
		if particles:
			particles.position = beam.to_local(end_position)
	_spawn_flash_light(parent, end_position, 0.6)
	return beam

func recycle(effect: Node) -> void:
	if active_effects.has(effect):
		var id: StringName = active_effects[effect]
		_return_to_pool(id, effect)

func _spawn_effect(effect_id: StringName, parent: Node, position: Vector2) -> Node:
	var definition: Dictionary = EFFECTS.get(effect_id, {})
	if definition.is_empty():
		push_warning("Unknown VFX effect id: %s" % effect_id)
		return null

	var instance: Node = _take_from_pool(effect_id)
	if instance == null:
		var packed_scene_variant: Variant = definition.get("scene", null)
		if packed_scene_variant == null or not (packed_scene_variant is PackedScene):
			push_warning("Missing scene for VFX effect id: %s" % effect_id)
			return null
		var packed_scene: PackedScene = packed_scene_variant
		instance = packed_scene.instantiate()
	_apply_profile_recursive(instance)

	instance.position = position
	instance.visible = true
	parent.add_child(instance)

	_register_release(definition, effect_id, instance)
	active_effects[instance] = effect_id

	return instance

func _register_release(definition: Dictionary, effect_id: StringName, instance: Node) -> void:
	var effect_type: StringName = definition.get("type", &"particles")
	instance.set_meta("effect_id", effect_id)

	if effect_type == &"particles":
		var emitters: Array[GPUParticles2D] = _collect_emitters(instance)
		var count := emitters.size()
		instance.set_meta("pending_emitters", count)

		if count == 0:
			_schedule_release(effect_id, instance, definition.get("lifetime", 0.6))
			return

		for emitter in emitters:
			emitter.finished.connect(Callable(self, "_on_emitter_finished").bind(instance), CONNECT_ONE_SHOT)
			emitter.restart()
	else:
		_schedule_release(effect_id, instance, definition.get("lifetime", 0.7))

func _on_emitter_finished(effect_instance: Node) -> void:
	if not effect_instance.has_meta("pending_emitters"):
		return
	var remaining: int = effect_instance.get_meta("pending_emitters") - 1
	if remaining <= 0:
		var effect_id: StringName = effect_instance.get_meta("effect_id")
		_return_to_pool(effect_id, effect_instance)
	else:
		effect_instance.set_meta("pending_emitters", remaining)

func _schedule_release(effect_id: StringName, instance: Node, duration: float) -> void:
	var timer := get_tree().create_timer(max(duration, 0.1))
	timer.timeout.connect(Callable(self, "_return_to_pool").bind(effect_id, instance), CONNECT_ONE_SHOT)

func _take_from_pool(effect_id: StringName) -> Node:
	var pool: Array = pools.get(effect_id, []) as Array
	if pool.size() > 0:
		return pool.pop_back()
	return null

func _return_to_pool(effect_id: StringName, instance: Node) -> void:
	if instance == null:
		return
	if not active_effects.has(instance):
		return

	active_effects.erase(instance)
	instance.visible = false
	instance.scale = Vector2.ONE
	
	for emitter in _collect_emitters(instance):
		emitter.emitting = false
		emitter.speed_scale = 1.0
		# Reset particle amount from stored original to prevent accumulation
		if emitter.has_meta("original_amount"):
			emitter.amount = emitter.get_meta("original_amount")
		# Reset material to original (will be re-duplicated on next spawn)
		# Note: The original material is stored in the scene, so we can't easily restore it here
		# But since we duplicate it each time in _scale_particles, this should be fine
	if instance.has_meta("pending_emitters"):
		instance.remove_meta("pending_emitters")
	if instance.has_meta("effect_id"):
		instance.remove_meta("effect_id")

	# Note: Tweens are not Node children; they exist in the animation system separately
	# This loop is kept for compatibility but Tweens won't be found here in Godot 4.5
	for child in instance.get_children():
		if child.get_class() == "Tween":
			if child.has_method("kill"):
				child.call("kill")
			child.queue_free()

	_apply_profile_recursive(instance)

	if instance.get_parent():
		instance.get_parent().remove_child(instance)

	var pool: Array = pools.get(effect_id, []) as Array
	pool.append(instance)
	pools[effect_id] = pool

func _apply_profile_recursive(node: Node) -> void:
	if node is ParticleProfile2D:
		(node as ParticleProfile2D).apply_profile(current_profile)
	for child in node.get_children():
		_apply_profile_recursive(child)

func _collect_emitters(root: Node) -> Array[GPUParticles2D]:
	var emitters: Array[GPUParticles2D] = []
	if root is GPUParticles2D:
		emitters.append(root)
	for child in root.get_children():
		emitters.append_array(_collect_emitters(child))
	return emitters

func _apply_global_quality() -> void:
	if quality_profiles == null:
		return
	current_profile_data = quality_profiles.get_profile(current_profile)
	RenderingServer.global_shader_parameter_set("vfx_max_gpu_particles", current_profile_data.get("max_gpu_particles", 80000))
	RenderingServer.global_shader_parameter_set("vfx_max_heavy_emitters", current_profile_data.get("max_heavy_emitters", 8))
	RenderingServer.global_shader_parameter_set("vfx_light_lifetime", current_profile_data.get("light_lifetime", 0.25))
	RenderingServer.global_shader_parameter_set("vfx_trail_point_budget", current_profile_data.get("trail_point_budget", 3000))

func _set_shader_uniform(value: float, material: ShaderMaterial, parameter: StringName) -> void:
	if material:
		material.set_shader_parameter(parameter, value)

func _scale_particles(instance: Node, multiplier: float) -> void:
	if instance == null:
		return
	instance.scale = Vector2.ONE * multiplier
	
	# Also scale particle material properties for proper visual scaling
	# GPU particles with local_coords=false don't respect node scale well
	# We need to duplicate the material to avoid modifying shared resources
	for emitter in _collect_emitters(instance):
		# Store original amount before modification (for later restoration)
		if not emitter.has_meta("original_amount"):
			emitter.set_meta("original_amount", emitter.amount)
		
		# Scale particle amount from the ORIGINAL value (not current, to prevent accumulation)
		var original_amount: int = emitter.get_meta("original_amount")
		emitter.amount = max(1, int(original_amount * multiplier))
		
		if emitter.process_material is ParticleProcessMaterial:
			var original_material = emitter.process_material as ParticleProcessMaterial
			# Duplicate the material so we don't modify the shared resource
			var material = original_material.duplicate() as ParticleProcessMaterial
			emitter.process_material = material
			
			# Set gravity to zero for top-down game (particles should spiral out, not fall down)
			material.gravity = Vector3.ZERO
			
			# Scale velocities (but keep them visible - ensure minimum 10% of original)
			var scaled_vel_min = original_material.initial_velocity_min * multiplier
			var min_vel_min = original_material.initial_velocity_min * 0.1
			material.initial_velocity_min = max(min_vel_min, scaled_vel_min)
			
			var scaled_vel_max = original_material.initial_velocity_max * multiplier
			var min_vel_max = original_material.initial_velocity_max * 0.1
			material.initial_velocity_max = max(min_vel_max, scaled_vel_max)
			
			# Scale radial velocity (if it exists - some materials have this property)
			# Access directly - if it doesn't exist, this will be ignored
			var radial_val = original_material.get("radial_velocity")
			if radial_val != null and radial_val is float:
				var scaled_radial = radial_val * multiplier
				var min_radial = radial_val * 0.1
				material.set("radial_velocity", max(min_radial, scaled_radial))
			
			# Scale particle sizes (but keep minimum visible size - don't go below 0.01)
			material.scale_min = max(0.01, original_material.scale_min * multiplier)
			material.scale_max = max(0.01, original_material.scale_max * multiplier)
			
			# Scale emission radius if it's a sphere emission (but keep minimum 1.0)
			if material.emission_shape == ParticleProcessMaterial.EMISSION_SHAPE_SPHERE:
				var original_radius = original_material.get("emission_sphere_radius")
				if original_radius != null and original_radius is float:
					material.set("emission_sphere_radius", max(1.0, original_radius * multiplier))

func _adjust_particles_strength(instance: Node, intensity: float) -> void:
	intensity = clamp(intensity, 0.2, 2.0)
	for emitter in _collect_emitters(instance):
		emitter.speed_scale = intensity

func _scale_engine_particles(instance: Node, multiplier: float) -> void:
	"""Scale engine particle sizes (similar to _scale_particles but for engines)"""
	if instance == null:
		return
	
	for emitter in _collect_emitters(instance):
		if emitter.process_material is ParticleProcessMaterial:
			var original_material = emitter.process_material as ParticleProcessMaterial
			# Duplicate the material so we don't modify the shared resource
			var material = original_material.duplicate() as ParticleProcessMaterial
			emitter.process_material = material
			
			# Scale particle sizes
			material.scale_min *= multiplier
			material.scale_max *= multiplier
			
			# Scale velocities proportionally to maintain visual consistency
			material.initial_velocity_min *= multiplier
			material.initial_velocity_max *= multiplier

func _spawn_flash_light(parent: Node, position: Vector2, scale: float) -> void:
	if parent == null:
		return
	var light: PointLight2D = PointLight2D.new()
	light.texture = _get_flash_light_texture()
	light.energy = 1.0 * max(scale, 0.5)
	light.texture_scale = 1.5 * max(scale, 0.6)
	light.color = Color(1.0, 0.75, 0.4)
	light.shadow_enabled = false
	light.z_index = 15
	parent.add_child(light)
	light.global_position = position

	var lifetime: float = current_profile_data.get("light_lifetime", 0.25)
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(Callable(light, "queue_free"), CONNECT_ONE_SHOT)

func _get_flash_light_texture() -> GradientTexture1D:
	if _flash_light_texture == null:
		var gradient := Gradient.new()
		gradient.add_point(0.0, Color(1, 0.85, 0.6, 1))
		gradient.add_point(1.0, Color(0.2, 0.05, 0.0, 0))
		_flash_light_texture = GradientTexture1D.new()
		_flash_light_texture.gradient = gradient
	return _flash_light_texture

func _tint_polygon_material(node: Node, color: Color) -> void:
	if node is Polygon2D:
		_set_polygon_material(node, color)
	for child in node.get_children():
		_tint_polygon_material(child, color)

func _set_polygon_material(polygon: Polygon2D, color: Color) -> void:
	if polygon.material is ShaderMaterial:
		var mat: ShaderMaterial = polygon.material as ShaderMaterial
		if mat:
			# In Godot 4.5, we don't have get_shader_parameter_list(), so just set the parameter directly
			mat.set_shader_parameter("base_color", color)

func spawn_scorch_decal(parent: Node, position: Vector2, radius: float = 1.0, rotation: float = 0.0) -> Polygon2D:
	return _spawn_decal(parent, position, radius, rotation, SCORCH_DECAL_MATERIAL)

func spawn_weld_decal(parent: Node, position: Vector2, radius: float = 1.0, rotation: float = 0.0) -> Polygon2D:
	return _spawn_decal(parent, position, radius, rotation, WELD_DECAL_MATERIAL)

func _spawn_decal(parent: Node, position: Vector2, radius: float, rotation: float, material: ShaderMaterial) -> Polygon2D:
	if parent == null or material == null:
		return null
	var decal := Polygon2D.new()
	var size := 128.0 * radius
	decal.polygon = PackedVector2Array([
		Vector2(-size, -size),
		Vector2(size, -size),
		Vector2(size, size),
		Vector2(-size, size)
	])
	decal.uv = PackedVector2Array([Vector2.ZERO, Vector2(1, 0), Vector2.ONE, Vector2(0, 1)])
	var mat_instance: ShaderMaterial = material.duplicate(true) as ShaderMaterial
	if mat_instance is ShaderMaterial:
		var shader_mat: ShaderMaterial = mat_instance
		# In Godot 4.5, just set shader parameters directly without checking list
		shader_mat.set_shader_parameter("distortion", randf_range(0.15, 0.35))
		if material == SCORCH_DECAL_MATERIAL and SCORCH_TEXTURES.size() > 0:
			var scorch_tex: Texture2D = SCORCH_TEXTURES[randi() % SCORCH_TEXTURES.size()]
			shader_mat.set_shader_parameter("mask_tex", scorch_tex)
		elif material == WELD_DECAL_MATERIAL and WELD_TEXTURES.size() > 0:
			var weld_tex: Texture2D = WELD_TEXTURES[randi() % WELD_TEXTURES.size()]
			shader_mat.set_shader_parameter("mask_tex", weld_tex)
	decal.material = mat_instance
	decal.position = position
	decal.rotation = rotation
	decal.z_index = -1
	parent.add_child(decal)
	return decal

# ============================================================================
# NEW WEAPON VFX FUNCTIONS - For 21 weapon types
# ============================================================================

# Weapon type colors (must match Projectile.gd)
const WEAPON_COLORS := {
	0: Color(1.0, 0.3, 0.3, 1.0),        # LASER - Red
	1: Color(1.0, 0.7, 0.2, 1.0),        # MISSILE - Orange
	2: Color(0.9, 0.8, 0.4, 1.0),        # AUTOCANNON - Brass/Yellow
	3: Color(0.3, 0.5, 1.0, 1.0),        # RAILGUN - Blue streak
	4: Color(1.0, 1.0, 0.9, 1.0),        # GATLING - White tracer
	5: Color(0.3, 1.0, 0.3, 1.0),        # SNIPER - Green tracer
	6: Color(1.0, 0.9, 0.5, 1.0),        # SHOTGUN - Light brass
	7: Color(0.3, 0.6, 1.0, 1.0),        # ION_CANNON - Blue
	8: Color(0.3, 1.0, 0.4, 1.0),        # PLASMA_CANNON - Green
	9: Color(0.8, 0.3, 1.0, 1.0),        # PARTICLE_BEAM - Purple
	10: Color(0.4, 0.8, 1.0, 1.0),       # TESLA_COIL - Electric blue
	11: Color(1.0, 0.4, 0.8, 1.0),       # DISRUPTOR - Pink
	12: Color(1.0, 0.5, 0.2, 1.0),       # FLAK_CANNON - Dark orange
	13: Color(0.7, 0.9, 1.0, 1.0),       # TORPEDO - Light blue
	14: Color(1.0, 0.6, 0.3, 1.0),       # ROCKET_POD - Light orange
	15: Color(0.6, 0.5, 0.4, 1.0),       # MORTAR - Brown
	16: Color(0.8, 0.2, 0.2, 1.0),       # MINE_LAYER - Dark red
	17: Color(0.6, 0.9, 1.0, 1.0),       # CRYO_CANNON - Light blue
	18: Color(0.5, 0.3, 1.0, 1.0),       # EMP_BURST - Electric purple
	19: Color(0.4, 0.0, 0.6, 1.0),       # GRAVITY_WELL - Dark purple
	20: Color(0.3, 1.0, 0.3, 1.0)        # REPAIR_BEAM - Green
}

func get_weapon_color(weapon_type: int) -> Color:
	"""Get the VFX color for a weapon type"""
	return WEAPON_COLORS.get(weapon_type, Color(1.0, 0.3, 0.3, 1.0))

# ============================================================================
# BEAM EFFECTS - For Ion Cannon, Particle Beam, Repair Beam, Tesla Coil
# ============================================================================

func spawn_beam_effect(start_pos: Vector2, end_pos: Vector2, color: Color, width: float = 4.0, duration: float = 0.2) -> Line2D:
	"""Spawn a beam effect between two points"""
	var beam := Line2D.new()
	beam.points = PackedVector2Array([start_pos, end_pos])
	beam.width = width
	beam.default_color = color
	beam.begin_cap_mode = Line2D.LINE_CAP_ROUND
	beam.end_cap_mode = Line2D.LINE_CAP_ROUND
	beam.z_index = 10
	
	# Add glow effect via modulate
	beam.modulate = Color(color.r * 1.5, color.g * 1.5, color.b * 1.5, 1.0)
	
	# Add to scene
	if get_tree().current_scene:
		get_tree().current_scene.add_child(beam)
	
	# Animate fade out
	var tween := beam.create_tween()
	tween.tween_property(beam, "modulate:a", 0.0, duration)
	tween.tween_callback(beam.queue_free)
	
	# Spawn a flash at the impact point
	_spawn_flash_light(beam.get_parent(), end_pos, width / 8.0)
	
	return beam

func spawn_ion_beam(start_pos: Vector2, end_pos: Vector2, width: float = 5.0) -> Line2D:
	"""Blue pulse beam for Ion Cannon"""
	var beam := spawn_beam_effect(start_pos, end_pos, Color(0.3, 0.6, 1.0, 1.0), width, 0.25)
	
	# Add secondary inner beam for pulse effect
	var inner_beam := Line2D.new()
	inner_beam.points = PackedVector2Array([start_pos, end_pos])
	inner_beam.width = width * 0.5
	inner_beam.default_color = Color(0.8, 0.9, 1.0, 0.8)
	inner_beam.z_index = 11
	if beam.get_parent():
		beam.get_parent().add_child(inner_beam)
	
	var tween := inner_beam.create_tween()
	tween.tween_property(inner_beam, "modulate:a", 0.0, 0.2)
	tween.tween_callback(inner_beam.queue_free)
	
	return beam

func spawn_particle_beam(start_pos: Vector2, end_pos: Vector2, width: float = 4.0) -> Line2D:
	"""Purple sustained beam for Particle Beam"""
	return spawn_beam_effect(start_pos, end_pos, Color(0.8, 0.3, 1.0, 1.0), width, 0.15)

func spawn_repair_beam(start_pos: Vector2, end_pos: Vector2, width: float = 4.0) -> Line2D:
	"""Green healing beam for Repair Beam"""
	var beam := spawn_beam_effect(start_pos, end_pos, Color(0.3, 1.0, 0.3, 1.0), width, 0.3)
	
	# Add sparkle particles along beam
	_spawn_beam_particles(start_pos, end_pos, Color(0.5, 1.0, 0.5, 1.0), 5)
	
	return beam

func spawn_cryo_beam(start_pos: Vector2, end_pos: Vector2, width: float = 5.0) -> Line2D:
	"""Light blue freezing beam for Cryo Cannon"""
	return spawn_beam_effect(start_pos, end_pos, Color(0.6, 0.9, 1.0, 1.0), width, 0.25)

func spawn_tesla_beam(start_pos: Vector2, end_pos: Vector2, width: float = 6.0, duration: float = 0.2) -> Node2D:
	"""Legacy lightning beam - redirects to new jagged lightning"""
	return spawn_tesla_lightning(start_pos, end_pos, width, duration)

func spawn_tesla_lightning(start_pos: Vector2, end_pos: Vector2, width: float = 6.0, duration: float = 0.3) -> Node2D:
	"""Jagged branching lightning bolt for Tesla Coil with new shader"""
	var direction := (end_pos - start_pos)
	var length := direction.length()
	
	# Debug - remove after confirming it works
	print("Tesla Lightning: ", start_pos, " -> ", end_pos, " length=", length)
	
	if length < 5.0:
		length = 5.0  # Minimum visible length
	direction = direction.normalized()
	
	# Calculate beam height based on width for proper aspect ratio
	# Height needs to be significant enough to show the jagged lightning
	var beam_height: float = maxf(width * 4.0, 30.0)
	
	# Create a Sprite2D with the shader (more reliable than Polygon2D)
	var beam_sprite := Sprite2D.new()
	
	# Create a texture sized for the beam
	var tex_width: int = int(maxf(length, 64.0))
	var tex_height: int = int(maxf(beam_height, 32.0))
	var img := Image.create(tex_width, tex_height, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex := ImageTexture.create_from_image(img)
	beam_sprite.texture = tex
	
	# Load new jagged lightning shader
	var shader := load("res://shaders/tesla_lightning.gdshader") as Shader
	if not shader:
		push_error("Failed to load tesla lightning shader at res://shaders/tesla_lightning.gdshader")
		# Fallback to simple beam
		return spawn_beam_effect(start_pos, end_pos, Color(0.4, 0.8, 1.0, 1.0), width, duration)
	
	var mat := ShaderMaterial.new()
	mat.shader = shader
	
	# Configure shader parameters for jagged lightning - more visible settings
	mat.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))  # White-hot core
	mat.set_shader_parameter("glow_color", Color(0.4, 0.8, 1.0, 1.0))  # Electric blue
	mat.set_shader_parameter("outer_color", Color(0.2, 0.5, 1.0, 0.6))  # Blue outer
	mat.set_shader_parameter("bolt_thickness", 0.08)  # Thicker bolt
	mat.set_shader_parameter("glow_size", 0.2)  # Larger glow
	mat.set_shader_parameter("jaggedness", 0.15)  # More jagged
	mat.set_shader_parameter("segment_count", 12.0)
	mat.set_shader_parameter("fork_chance", 0.4)
	mat.set_shader_parameter("fork_length", 0.25)
	mat.set_shader_parameter("flicker_speed", 25.0)
	mat.set_shader_parameter("intensity", 2.0)  # Brighter
	
	beam_sprite.material = mat
	beam_sprite.z_index = 15
	beam_sprite.z_as_relative = false
	
	# Position at midpoint, rotated toward target
	var midpoint := (start_pos + end_pos) * 0.5
	beam_sprite.global_position = midpoint
	beam_sprite.rotation = direction.angle()
	
	# Scale to match beam length
	beam_sprite.scale = Vector2(length / tex_width, beam_height / tex_height)
	
	# Add to scene
	if get_tree().current_scene:
		get_tree().current_scene.add_child(beam_sprite)
	
	# Also spawn a simple Line2D as a visible backup/base layer
	var backup_line := _spawn_jagged_line(start_pos, end_pos, Color(0.4, 0.8, 1.0, 0.8), width * 0.5)
	
	# Animate with quick flash then fade
	var tween := beam_sprite.create_tween()
	# Start bright
	beam_sprite.modulate = Color(1.5, 1.5, 1.5, 1.0)
	# Quick bright flash
	tween.tween_property(beam_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.05)
	# Then fade out
	tween.tween_property(beam_sprite, "modulate:a", 0.0, duration)
	tween.tween_callback(beam_sprite.queue_free)
	
	# Fade backup line too
	if backup_line:
		var line_tween := backup_line.create_tween()
		line_tween.tween_property(backup_line, "modulate:a", 0.0, duration * 1.2)
		line_tween.tween_callback(backup_line.queue_free)
	
	return beam_sprite

func _spawn_jagged_line(start_pos: Vector2, end_pos: Vector2, color: Color, width: float) -> Line2D:
	"""Spawn a jagged line as lightning effect (fallback/backup visual)"""
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	line.z_index = 12
	
	# Generate jagged points between start and end
	var direction := (end_pos - start_pos)
	var length := direction.length()
	var perpendicular := Vector2(-direction.y, direction.x).normalized()
	var segments := int(max(length / 20.0, 4))  # ~20px per segment
	
	line.add_point(start_pos)
	
	for i in range(1, segments):
		var t: float = float(i) / float(segments)
		var base_point: Vector2 = start_pos.lerp(end_pos, t)
		# Random offset perpendicular to direction
		var jag_amount: float = randf_range(-15.0, 15.0) * (1.0 - abs(t - 0.5) * 2.0)  # Less jag at ends
		var jagged_point: Vector2 = base_point + perpendicular * jag_amount
		line.add_point(jagged_point)
	
	line.add_point(end_pos)
	
	# Add glow effect with gradient
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 0.3))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 1.0))
	gradient.add_point(0.5, color)
	line.gradient = gradient
	line.width_curve = _get_lightning_width_curve()
	
	if get_tree().current_scene:
		get_tree().current_scene.add_child(line)
	
	return line

func _get_lightning_width_curve() -> Curve:
	"""Get a curve that makes lightning thicker in middle, thinner at ends"""
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(0.2, 0.8))
	curve.add_point(Vector2(0.5, 1.0))
	curve.add_point(Vector2(0.8, 0.8))
	curve.add_point(Vector2(1.0, 0.3))
	return curve

# Cache for tesla beam noise textures
static var _tesla_noise_1: NoiseTexture2D = null
static var _tesla_noise_2: NoiseTexture2D = null

func _get_tesla_noise_textures() -> Array:
	"""Create and cache noise textures for tesla beam shader"""
	if not _tesla_noise_1:
		var noise1 = FastNoiseLite.new()
		noise1.noise_type = FastNoiseLite.TYPE_SIMPLEX
		noise1.frequency = 0.1
		_tesla_noise_1 = NoiseTexture2D.new()
		_tesla_noise_1.noise = noise1
		_tesla_noise_1.seamless = true
		_tesla_noise_1.width = 256
		_tesla_noise_1.height = 256
		
		var noise2 = FastNoiseLite.new()
		noise2.noise_type = FastNoiseLite.TYPE_CELLULAR
		noise2.frequency = 0.15
		_tesla_noise_2 = NoiseTexture2D.new()
		_tesla_noise_2.noise = noise2
		_tesla_noise_2.seamless = true
		_tesla_noise_2.width = 256
		_tesla_noise_2.height = 256
	
	return [_tesla_noise_1, _tesla_noise_2]

func _spawn_beam_particles(start_pos: Vector2, end_pos: Vector2, color: Color, count: int) -> void:
	"""Spawn small particles along a beam path"""
	var direction := (end_pos - start_pos)
	var length := direction.length()
	direction = direction.normalized()
	
	for i in range(count):
		var t := randf()
		var pos := start_pos + direction * (length * t)
		_spawn_simple_particle(pos, color, 0.3)

func _spawn_simple_particle(position: Vector2, color: Color, duration: float) -> void:
	"""Spawn a simple fading particle"""
	var particle := Polygon2D.new()
	particle.polygon = PackedVector2Array([
		Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)
	])
	particle.color = color
	particle.position = position
	particle.z_index = 12
	
	if get_tree().current_scene:
		get_tree().current_scene.add_child(particle)
	
	var tween := particle.create_tween()
	tween.set_parallel(true)
	tween.tween_property(particle, "modulate:a", 0.0, duration)
	tween.tween_property(particle, "scale", Vector2(0.1, 0.1), duration)
	tween.chain().tween_callback(particle.queue_free)

# ============================================================================
# AOE EFFECTS - For Flak Cannon, Mortar, Torpedo, EMP Burst, Gravity Well
# ============================================================================

func spawn_aoe_circle(center: Vector2, radius: float, color: Color, duration: float = 0.3) -> Node2D:
	"""Spawn a circular AOE explosion effect"""
	# Safety clamp radius to prevent oversized effects
	radius = clampf(radius, 5.0, 300.0)
	
	var container := Node2D.new()
	container.position = center
	container.z_index = 8
	
	if get_tree().current_scene:
		get_tree().current_scene.add_child(container)
	
	# Create expanding circle
	var circle := _create_circle_polygon(radius, color, 32)
	container.add_child(circle)
	
	# Create shockwave ring
	var ring := _create_ring_polygon(radius * 0.8, radius, color, 32)
	container.add_child(ring)
	
	# Animate expansion
	var tween := container.create_tween()
	tween.set_parallel(true)
	
	# Circle expands and fades
	circle.scale = Vector2(0.1, 0.1)
	tween.tween_property(circle, "scale", Vector2(1.0, 1.0), duration * 0.5)
	tween.tween_property(circle, "modulate:a", 0.0, duration)
	
	# Ring expands outward
	ring.scale = Vector2(0.5, 0.5)
	tween.tween_property(ring, "scale", Vector2(1.2, 1.2), duration)
	tween.tween_property(ring, "modulate:a", 0.0, duration)
	
	tween.chain().tween_callback(container.queue_free)
	
	# Add flash light
	_spawn_flash_light(container.get_parent(), center, radius / 50.0)
	
	return container

func spawn_aoe_ring(center: Vector2, radius: float, color: Color, duration: float = 0.4) -> Node2D:
	"""Spawn an expanding ring AOE effect (EMP burst style)"""
	var container := Node2D.new()
	container.position = center
	container.z_index = 8
	
	if get_tree().current_scene:
		get_tree().current_scene.add_child(container)
	
	# Create multiple expanding rings
	for i in range(3):
		var ring := _create_ring_polygon(radius * 0.9, radius, color, 48)
		ring.modulate.a = 1.0 - (i * 0.25)
		container.add_child(ring)
		
		var delay := i * 0.1
		var tween := ring.create_tween()
		tween.tween_interval(delay)
		ring.scale = Vector2(0.1, 0.1)
		tween.tween_property(ring, "scale", Vector2(1.0, 1.0), duration - delay)
		tween.parallel().tween_property(ring, "modulate:a", 0.0, duration - delay)
	
	# Cleanup container after all rings done
	var cleanup_tween := container.create_tween()
	cleanup_tween.tween_interval(duration + 0.1)
	cleanup_tween.tween_callback(container.queue_free)
	
	return container

func spawn_aoe_cone(origin: Vector2, direction: Vector2, angle: float, length: float, color: Color, duration: float = 0.25) -> Node2D:
	"""Spawn a cone AOE effect (shotgun spread)"""
	var container := Node2D.new()
	container.position = origin
	container.rotation = direction.angle()
	container.z_index = 8
	
	if get_tree().current_scene:
		get_tree().current_scene.add_child(container)
	
	# Create cone polygon
	var cone := _create_cone_polygon(length, angle, color, 12)
	container.add_child(cone)
	
	# Animate
	cone.scale = Vector2(0.1, 1.0)
	cone.modulate.a = 0.8
	
	var tween := container.create_tween()
	tween.set_parallel(true)
	tween.tween_property(cone, "scale", Vector2(1.0, 1.0), duration * 0.3)
	tween.tween_property(cone, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(container.queue_free)
	
	return container

func spawn_gravity_well_effect(center: Vector2, radius: float, duration: float = 4.0) -> Node2D:
	"""Spawn a gravity well visual effect with swirling particles"""
	var container := Node2D.new()
	container.position = center
	container.z_index = 5
	
	if get_tree().current_scene:
		get_tree().current_scene.add_child(container)
	
	# Dark purple center
	var core := _create_circle_polygon(radius * 0.3, Color(0.2, 0.0, 0.4, 0.8), 24)
	container.add_child(core)
	
	# Outer distortion ring
	var outer := _create_ring_polygon(radius * 0.85, radius, Color(0.4, 0.1, 0.6, 0.4), 32)
	container.add_child(outer)
	
	# Animate rotation
	var tween := container.create_tween()
	tween.set_loops()
	tween.tween_property(container, "rotation", TAU, 2.0)
	
	# Fade out at end of duration
	var fade_tween := container.create_tween()
	fade_tween.tween_interval(duration - 0.5)
	fade_tween.tween_property(container, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(container.queue_free)
	
	return container

func _create_circle_polygon(radius: float, color: Color, segments: int = 32) -> Polygon2D:
	"""Create a filled circle polygon"""
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	return polygon

func _create_ring_polygon(inner_radius: float, outer_radius: float, color: Color, segments: int = 32) -> Polygon2D:
	"""Create a ring (donut) polygon using Line2D for better performance"""
	var line := Line2D.new()
	line.width = outer_radius - inner_radius
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	var points := PackedVector2Array()
	var mid_radius := (inner_radius + outer_radius) / 2.0
	for i in range(segments + 1):
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * mid_radius)
	
	line.points = points
	
	# Wrap in Node2D to match return type
	var container := Node2D.new()
	container.add_child(line)
	
	# Return the Line2D cast as Polygon2D won't work, so we adjust
	# Actually, let's create a proper ring using Polygon2D
	var polygon := Polygon2D.new()
	var outer_points := PackedVector2Array()
	var inner_points := PackedVector2Array()
	
	for i in range(segments):
		var angle := (float(i) / segments) * TAU
		outer_points.append(Vector2(cos(angle), sin(angle)) * outer_radius)
	
	for i in range(segments - 1, -1, -1):
		var angle := (float(i) / segments) * TAU
		inner_points.append(Vector2(cos(angle), sin(angle)) * inner_radius)
	
	outer_points.append_array(inner_points)
	polygon.polygon = outer_points
	polygon.color = color
	
	container.queue_free()  # Clean up unused Line2D container
	return polygon

func _create_cone_polygon(length: float, angle_deg: float, color: Color, segments: int = 12) -> Polygon2D:
	"""Create a cone/fan polygon"""
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)  # Origin point
	
	var half_angle: float = deg_to_rad(angle_deg / 2.0)
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var current_angle: float = lerpf(-half_angle, half_angle, t)
		points.append(Vector2(cos(current_angle), sin(current_angle)) * length)
	
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	return polygon

# ============================================================================
# CHAIN LIGHTNING - For Tesla Coil
# ============================================================================

func spawn_chain_lightning(points: Array[Vector2], color: Color = Color(0.4, 0.8, 1.0, 1.0), duration: float = 0.15) -> Node2D:
	"""Spawn chain lightning effect through multiple points"""
	var container := Node2D.new()
	container.z_index = 10
	
	if get_tree().current_scene:
		get_tree().current_scene.add_child(container)
	
	# Create lightning segments between each pair of points
	for i in range(points.size() - 1):
		var start := points[i]
		var end := points[i + 1]
		var lightning := _create_lightning_segment(start, end, color)
		container.add_child(lightning)
	
	# Animate fade
	var tween := container.create_tween()
	tween.tween_property(container, "modulate:a", 0.0, duration)
	tween.tween_callback(container.queue_free)
	
	return container

func spawn_lightning_arc(start_pos: Vector2, end_pos: Vector2, color: Color = Color(0.4, 0.8, 1.0, 1.0), duration: float = 0.15) -> Line2D:
	"""Spawn a single lightning arc between two points"""
	var lightning := _create_lightning_segment(start_pos, end_pos, color)
	lightning.z_index = 10
	
	if get_tree().current_scene:
		get_tree().current_scene.add_child(lightning)
	
	var tween := lightning.create_tween()
	tween.tween_property(lightning, "modulate:a", 0.0, duration)
	tween.tween_callback(lightning.queue_free)
	
	# Add flash at endpoints
	_spawn_flash_light(lightning.get_parent(), start_pos, 0.3)
	_spawn_flash_light(lightning.get_parent(), end_pos, 0.4)
	
	return lightning

func _create_lightning_segment(start: Vector2, end: Vector2, color: Color) -> Line2D:
	"""Create a jagged lightning segment"""
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	# Create jagged path
	var points := PackedVector2Array()
	points.append(start)
	
	var direction := (end - start)
	var length := direction.length()
	var segments: int = maxi(3, int(length / 30.0))
	var perpendicular := direction.normalized().rotated(PI / 2)
	
	for i in range(1, segments):
		var t: float = float(i) / float(segments)
		var base_pos := start + direction * t
		var offset := perpendicular * randf_range(-15.0, 15.0)
		points.append(base_pos + offset)
	
	points.append(end)
	line.points = points
	
	# Add glow via bright modulate
	line.modulate = Color(color.r * 1.5, color.g * 1.5, color.b * 1.5, 1.0)
	
	return line

# ============================================================================
# STATUS EFFECT INDICATORS - Frozen, EMPed, Burning, Slowed
# ============================================================================

func spawn_status_indicator(target: Node2D, effect_type: String, duration: float = 2.0) -> Node2D:
	"""Spawn a status effect visual indicator on a target"""
	if not is_instance_valid(target):
		return null
	
	var indicator := Node2D.new()
	indicator.z_index = 15
	target.add_child(indicator)
	
	match effect_type:
		"emp", "disabled":
			_create_emp_indicator(indicator, duration)
		"frozen", "slow":
			_create_frozen_indicator(indicator, duration)
		"burn", "dot":
			_create_burn_indicator(indicator, duration)
		"pull":
			_create_pull_indicator(indicator, duration)
		_:
			_create_generic_indicator(indicator, duration, Color.WHITE)
	
	return indicator

func _create_emp_indicator(parent: Node2D, duration: float) -> void:
	"""Create EMP/disabled visual - electric sparks"""
	var spark_count := 4
	for i in range(spark_count):
		var spark := Line2D.new()
		spark.width = 2.0
		spark.default_color = Color(0.5, 0.3, 1.0, 0.8)
		spark.z_index = 15
		parent.add_child(spark)
		
		# Animate random sparks
		var tween := spark.create_tween()
		tween.set_loops(int(duration / 0.15))
		tween.tween_callback(_update_spark_points.bind(spark))
		tween.tween_interval(0.15)
	
	# Cleanup after duration
	var cleanup := parent.create_tween()
	cleanup.tween_interval(duration)
	cleanup.tween_property(parent, "modulate:a", 0.0, 0.3)
	cleanup.tween_callback(parent.queue_free)

func _update_spark_points(spark: Line2D) -> void:
	"""Update spark line with random jagged points"""
	var points := PackedVector2Array()
	var start := Vector2(randf_range(-20, 20), randf_range(-20, 20))
	var end := Vector2(randf_range(-20, 20), randf_range(-20, 20))
	
	points.append(start)
	points.append((start + end) / 2 + Vector2(randf_range(-10, 10), randf_range(-10, 10)))
	points.append(end)
	
	spark.points = points

func _create_frozen_indicator(parent: Node2D, duration: float) -> void:
	"""Create frozen/slow visual - ice crystals"""
	# Blue tint overlay
	var tint := Polygon2D.new()
	tint.polygon = PackedVector2Array([
		Vector2(-25, -25), Vector2(25, -25), Vector2(25, 25), Vector2(-25, 25)
	])
	tint.color = Color(0.6, 0.9, 1.0, 0.3)
	tint.z_index = 14
	parent.add_child(tint)
	
	# Ice crystal shapes
	for i in range(6):
		var crystal := _create_ice_crystal()
		crystal.position = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		crystal.rotation = randf() * TAU
		crystal.scale = Vector2.ONE * randf_range(0.5, 1.0)
		parent.add_child(crystal)
	
	# Animate fade
	var tween := parent.create_tween()
	tween.tween_interval(duration - 0.5)
	tween.tween_property(parent, "modulate:a", 0.0, 0.5)
	tween.tween_callback(parent.queue_free)

func _create_ice_crystal() -> Polygon2D:
	"""Create a small ice crystal shape"""
	var crystal := Polygon2D.new()
	crystal.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(4, 0), Vector2(0, 8), Vector2(-4, 0)
	])
	crystal.color = Color(0.8, 0.95, 1.0, 0.7)
	crystal.z_index = 15
	return crystal

func _create_burn_indicator(parent: Node2D, duration: float) -> void:
	"""Create burning/DOT visual - flickering flames"""
	var flame_count := 5
	for i in range(flame_count):
		var flame := Polygon2D.new()
		flame.polygon = PackedVector2Array([
			Vector2(0, -10), Vector2(5, 0), Vector2(3, 8), Vector2(-3, 8), Vector2(-5, 0)
		])
		flame.color = Color(1.0, 0.5, 0.1, 0.8)
		flame.position = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		flame.z_index = 15
		parent.add_child(flame)
		
		# Animate flicker
		var tween := flame.create_tween()
		tween.set_loops()
		tween.tween_property(flame, "scale", Vector2(1.2, 1.3), 0.1)
		tween.tween_property(flame, "scale", Vector2(0.8, 0.9), 0.1)
	
	# Cleanup
	var cleanup := parent.create_tween()
	cleanup.tween_interval(duration)
	cleanup.tween_property(parent, "modulate:a", 0.0, 0.3)
	cleanup.tween_callback(parent.queue_free)

func _create_pull_indicator(parent: Node2D, duration: float) -> void:
	"""Create gravity pull visual - inward arrows"""
	for i in range(4):
		var angle := (float(i) / 4) * TAU
		var arrow := _create_arrow_shape()
		arrow.position = Vector2(cos(angle), sin(angle)) * 30
		arrow.rotation = angle + PI  # Point inward
		arrow.modulate = Color(0.5, 0.2, 0.8, 0.7)
		arrow.z_index = 15
		parent.add_child(arrow)
		
		# Animate inward movement
		var tween := arrow.create_tween()
		tween.set_loops()
		tween.tween_property(arrow, "position", Vector2(cos(angle), sin(angle)) * 10, 0.5)
		tween.tween_property(arrow, "position", Vector2(cos(angle), sin(angle)) * 30, 0.0)
	
	# Cleanup
	var cleanup := parent.create_tween()
	cleanup.tween_interval(duration)
	cleanup.tween_property(parent, "modulate:a", 0.0, 0.3)
	cleanup.tween_callback(parent.queue_free)

func _create_arrow_shape() -> Polygon2D:
	"""Create an arrow polygon"""
	var arrow := Polygon2D.new()
	arrow.polygon = PackedVector2Array([
		Vector2(8, 0), Vector2(-4, 5), Vector2(-2, 0), Vector2(-4, -5)
	])
	arrow.color = Color.WHITE
	return arrow

func _create_generic_indicator(parent: Node2D, duration: float, color: Color) -> void:
	"""Create a generic status indicator"""
	var circle := _create_circle_polygon(15, color, 16)
	circle.modulate.a = 0.5
	parent.add_child(circle)
	
	var tween := parent.create_tween()
	tween.set_loops()
	tween.tween_property(circle, "scale", Vector2(1.2, 1.2), 0.3)
	tween.tween_property(circle, "scale", Vector2(0.8, 0.8), 0.3)
	
	var cleanup := parent.create_tween()
	cleanup.tween_interval(duration)
	cleanup.tween_property(parent, "modulate:a", 0.0, 0.3)
	cleanup.tween_callback(parent.queue_free)

# ============================================================================
# PROJECTILE TRAIL EFFECTS - Per weapon type
# ============================================================================

func spawn_projectile_trail(weapon_type: int, parent: Node, points: PackedVector2Array) -> Node:
	"""Spawn a trail effect for a specific weapon type"""
	var color := get_weapon_color(weapon_type)
	var color_end := Color(color.r, color.g, color.b, 0.0)
	return spawn_trail(parent, color, color_end, points)

func spawn_weapon_muzzle_flash(position: Vector2, weapon_type: int, scale: float = 1.0) -> void:
	"""Spawn muzzle flash appropriate for weapon type"""
	var color := get_weapon_color(weapon_type)
	
	# Flash light
	if get_tree().current_scene:
		var light := PointLight2D.new()
		light.texture = _get_flash_light_texture()
		light.energy = 0.8 * scale
		light.texture_scale = 1.0 * scale
		light.color = color
		light.shadow_enabled = false
		light.z_index = 15
		light.position = position
		get_tree().current_scene.add_child(light)
		
		var tween := light.create_tween()
		tween.tween_property(light, "energy", 0.0, 0.1)
		tween.tween_callback(light.queue_free)
