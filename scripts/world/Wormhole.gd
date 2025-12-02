extends Area2D
class_name Wormhole
## Portal connecting zones (lateral or depth)

enum WormholeType {
	DEPTH,    # Connects to different difficulty (forward/backward)
	LATERAL   # Connects to same difficulty (sideways)
}

signal units_traveled(units: Array, target_zone_id: String)
signal wormhole_selected(wormhole: Wormhole)

@export var source_zone_id: String = ""
@export var target_zone_id: String = ""
@export var is_active: bool = true
@export var wormhole_type: WormholeType = WormholeType.DEPTH
@export var is_undiscovered: bool = false  # True if leads to undiscovered zone

var is_selected: bool = false
var is_generating_zone: bool = false  # Flag to prevent multiple simultaneous zone generations

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var glow_particles: CPUParticles2D = $GlowParticles
@onready var label: Label = $Label

var is_hovered: bool = false
var base_modulate: Color = Color(0.6, 0.3, 1.0, 1.0)  # Purple for depth
var wormhole_direction: float = 0.0  # Direction angle for lateral wormholes

func _ready():
	print("Wormhole_debug : ~~~ WORMHOLE._ready() CALLED ~~~")
	print("Wormhole_debug :   Source zone: %s" % source_zone_id)
	print("Wormhole_debug :   Target zone: %s" % ("UNDISCOVERED" if target_zone_id.is_empty() else target_zone_id))
	print("Wormhole_debug :   Type at _ready: %d (0=DEPTH, 1=LATERAL)" % wormhole_type)
	print("Wormhole_debug :   Position: %s" % global_position)
	
	# Setup collision for selection and input
	collision_layer = 0
	collision_mask = 0
	
	# Enable input detection
	input_pickable = true
	
	# Add to selectable group
	add_to_group("selectable")
	add_to_group("wormholes")
	
	# Set color based on wormhole type
	if wormhole_type == WormholeType.LATERAL:
		base_modulate = Color(0.3, 0.8, 0.8, 1.0)  # Cyan/teal for lateral
		print("Wormhole_debug :   Color set: CYAN (lateral)")
	else:  # DEPTH
		var is_forward = get_meta("is_forward", true)
		if is_forward:
			base_modulate = Color(0.6, 0.3, 1.0, 1.0)  # Purple for forward
			print("Wormhole_debug :   Color set: PURPLE (depth forward)")
		else:
			base_modulate = Color(0.3, 0.6, 1.0, 1.0)  # Blue for return
			print("Wormhole_debug :   Color set: BLUE (depth backward)")
	
	# Setup visual
	setup_visual()
	
	# Connect mouse signals for hover effect
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Note: Click detection is handled by InputHandler, not Area2D input_event
	
	# Register with ZoneManager
	if ZoneManager:
		var wh_type = "lateral" if wormhole_type == WormholeType.LATERAL else "depth"
		print("Wormhole_debug :   Registering with ZoneManager as: %s" % wh_type)
		ZoneManager.set_zone_wormhole(source_zone_id, self, wh_type)
	
	# Update label based on type and destination
	update_label()
	
	print("Wormhole_debug :   Type after _ready complete: %d (0=DEPTH, 1=LATERAL)" % wormhole_type)
	print("Wormhole_debug : ~~~ WORMHOLE._ready() COMPLETE ~~~\n")
	

func setup_visual():
	"""Setup wormhole visuals"""
	if sprite:
		# Load the wormhole shader
		var shader = load("res://shaders/wormhole_object.gdshader")
		if shader:
			var material = ShaderMaterial.new()
			material.shader = shader
			material.set_shader_parameter("base_color", base_modulate)
			
			# Adjust parameters based on type
			if wormhole_type == WormholeType.LATERAL:
				material.set_shader_parameter("swirl_strength", 6.0)
				material.set_shader_parameter("core_size", 0.25)
			else:
				material.set_shader_parameter("swirl_strength", 8.0)
				material.set_shader_parameter("core_size", 0.2)
				
			sprite.material = material
			
			# Use a simple placeholder texture for the shader to work on
			# The shader discards pixels based on UV, so a square texture is fine
			var image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
			image.fill(Color.WHITE)
			var texture = ImageTexture.create_from_image(image)
			sprite.texture = texture
			sprite.scale = Vector2(1.5, 1.5)
			
			# Reset rotation as shader handles rotation internally
			sprite.rotation = 0.0
		else:
			print("Wormhole: Failed to load shader!")
			# Fallback to simple circle if shader fails
			sprite.modulate = base_modulate
			var image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
			image.fill(Color.TRANSPARENT)
			for x in range(128):
				for y in range(128):
					var dx = x - 64
					var dy = y - 64
					var dist = sqrt(dx * dx + dy * dy)
					if dist < 50:
						image.set_pixel(x, y, Color(1, 1, 1, 1))
			sprite.texture = ImageTexture.create_from_image(image)
	
	# Setup swirling particles
	if particles:
		particles.emitting = true
		particles.amount = 30
		particles.lifetime = 3.0
		particles.explosiveness = 0.0
		particles.randomness = 0.5
		
		# Orbital motion
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 60.0
		
		particles.direction = Vector2(0, 0)
		particles.spread = 180.0
		particles.initial_velocity_min = 20.0
		particles.initial_velocity_max = 40.0
		
		# Swirl effect using tangential acceleration
		particles.tangential_accel_min = 50.0
		particles.tangential_accel_max = 100.0
		
		# Color
		particles.color = base_modulate
		particles.color_ramp = create_wormhole_gradient()
		
		# Scale
		particles.scale_amount_min = 2.0
		particles.scale_amount_max = 4.0
		
		# Fade
		particles.color.a = 0.8
	
	# Setup glow particles
	if glow_particles:
		glow_particles.emitting = true
		glow_particles.amount = 15
		glow_particles.lifetime = 2.0
		glow_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		glow_particles.emission_sphere_radius = 40.0
		
		glow_particles.direction = Vector2(0, 0)
		glow_particles.spread = 180.0
		glow_particles.initial_velocity_min = 5.0
		glow_particles.initial_velocity_max = 15.0
		
		glow_particles.color = Color(1.0, 1.0, 1.0, 0.6)
		glow_particles.scale_amount_min = 1.0
		glow_particles.scale_amount_max = 2.0

func create_wormhole_gradient() -> Gradient:
	"""Create color gradient for particles"""
	var gradient = Gradient.new()
	gradient.add_point(0.0, base_modulate)
	gradient.add_point(0.5, base_modulate * 1.2)
	gradient.add_point(1.0, Color(base_modulate.r, base_modulate.g, base_modulate.b, 0.0))
	return gradient

func _process(delta: float):
	"""Animate wormhole rotation and selection glow"""
	if sprite:
		# sprite.rotation += delta * 0.5 # Shader handles rotation now
		
		# Pulsing glow when selected
		if sprite.material is ShaderMaterial:
			var mat = sprite.material as ShaderMaterial
			if is_selected:
				# Increase pulse amount and speed when selected
				mat.set_shader_parameter("pulse_amount", 0.15)
				mat.set_shader_parameter("pulse_speed", 5.0)
				# Also brighten the base color slightly
				mat.set_shader_parameter("base_color", base_modulate * 1.5)
			else:
				mat.set_shader_parameter("pulse_amount", 0.05)
				mat.set_shader_parameter("pulse_speed", 2.0)
				mat.set_shader_parameter("base_color", base_modulate)
		else:
			# Fallback for non-shader
			if is_selected:
				var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.003) * 0.3
				sprite.modulate = base_modulate * pulse
			else:
				sprite.modulate = base_modulate

func select_wormhole():
	"""Select this wormhole and emit signal"""
	is_selected = true
	wormhole_selected.emit(self)

func deselect_wormhole():
	"""Deselect this wormhole"""
	is_selected = false
	if sprite.material is ShaderMaterial:
		(sprite.material as ShaderMaterial).set_shader_parameter("base_color", base_modulate)
		(sprite.material as ShaderMaterial).set_shader_parameter("pulse_amount", 0.05)
		(sprite.material as ShaderMaterial).set_shader_parameter("pulse_speed", 2.0)
	else:
		sprite.modulate = base_modulate

func _on_mouse_entered():
	"""Handle mouse hover"""
	is_hovered = true
	if sprite and not is_selected:
		if sprite.material is ShaderMaterial:
			(sprite.material as ShaderMaterial).set_shader_parameter("base_color", base_modulate * 1.5)
		else:
			sprite.modulate = base_modulate * 1.5

func _on_mouse_exited():
	"""Handle mouse exit"""
	is_hovered = false
	if sprite and not is_selected:
		if sprite.material is ShaderMaterial:
			(sprite.material as ShaderMaterial).set_shader_parameter("base_color", base_modulate)
		else:
			sprite.modulate = base_modulate

func update_label():
	"""Update wormhole label based on type and destination"""
	if not label:
		return
	
	if is_undiscovered:
		label.text = "??? Undiscovered Region"
	elif wormhole_type == WormholeType.LATERAL:
		# Get target zone name if it exists
		var target_zone = ZoneManager.get_zone(target_zone_id) if ZoneManager else {}
		var zone_name = target_zone.get("procedural_name", "Unknown Zone")
		label.text = "↔ %s" % zone_name
	else:  # DEPTH
		var is_forward = get_meta("is_forward", true)
		var target_zone = ZoneManager.get_zone(target_zone_id) if ZoneManager else {}
		var zone_name = target_zone.get("procedural_name", "Unknown Zone")
		var arrow = "↓" if is_forward else "↑"
		label.text = "%s %s" % [arrow, zone_name]

func can_travel() -> bool:
	"""Check if wormhole is active and ready for travel"""
	if not is_active:
		return false
	
	# If undiscovered, can still travel (it will trigger generation)
	if is_undiscovered:
		return true
	
	return ZoneManager and ZoneManager.is_valid_zone(target_zone_id)

func travel_units(units: Array):
	"""Issue move commands to units to travel to wormhole (they'll teleport when in range)"""
	print("Wormhole_debug : !!! TRAVEL_UNITS CALLED (wormhole clicked) !!!")
	print("Wormhole_debug :   Wormhole position: %s" % global_position)
	print("Wormhole_debug :   Wormhole type: %d (0=DEPTH, 1=LATERAL)" % wormhole_type)
	print("Wormhole_debug :   Wormhole color: %s" % base_modulate)
	print("Wormhole_debug :   Target zone: %s" % ("UNDISCOVERED" if target_zone_id.is_empty() else target_zone_id))
	print("Wormhole_debug :   Units being sent: %d" % units.size())
	
	if not can_travel():
		print("Wormhole_debug :   ERROR: can_travel() returned false!")
		return
	
	if units.is_empty():
		print("Wormhole_debug :   No units to send")
		return
	
	# Command units to move to wormhole position
	# When they arrive in range, they'll automatically teleport
	for unit in units:
		if is_instance_valid(unit) and unit.has_method("add_command"):
			unit.add_command(CommandSystem.CommandType.TRAVEL_WORMHOLE, global_position, self, false)

func teleport_unit(unit: Node2D):
	"""Teleport a single unit that has arrived at the wormhole"""
	print("Wormhole_debug : --- TELEPORT_UNIT START ---")
	print("Wormhole_debug :   Wormhole type: %s" % ("LATERAL" if wormhole_type == WormholeType.LATERAL else "DEPTH"))
	print("Wormhole_debug :   Is undiscovered: %s" % is_undiscovered)
	print("Wormhole_debug :   Current target: %s" % ("NONE" if target_zone_id.is_empty() else target_zone_id))
	
	if not can_travel() or not is_instance_valid(unit):
		return
	
	# If zone is currently being generated, wait
	if is_generating_zone:
		print("Wormhole_debug :   Zone generation in progress, waiting...")
		return
	
	# If undiscovered, generate zone first
	if is_undiscovered and ZoneDiscoveryManager:
		print("Wormhole_debug :   Wormhole is UNDISCOVERED - generating new zone...")
		is_generating_zone = true  # Lock to prevent concurrent generation
		
		var new_zone_id = ""
		
		if wormhole_type == WormholeType.LATERAL:
			print("Wormhole_debug :   Generating LATERAL zone...")
			# Generate lateral zone
			new_zone_id = ZoneDiscoveryManager.generate_and_discover_lateral_zone(
				source_zone_id, self, wormhole_direction
			)
		else:  # DEPTH
			print("Wormhole_debug :   Generating DEPTH zone...")
			# Generate depth zone
			var source_zone = ZoneManager.get_zone(source_zone_id) if ZoneManager else {}
			if not source_zone.is_empty():
				var is_forward = get_meta("is_forward", true)
				var target_difficulty = source_zone.difficulty + (1 if is_forward else -1)
				print("Wormhole_debug :   Calling generate_and_discover_depth_zone(source=%s, target_diff=%d)" % [source_zone_id, target_difficulty])
				new_zone_id = ZoneDiscoveryManager.generate_and_discover_depth_zone(
					source_zone_id, target_difficulty, wormhole_direction
				)
				print("Wormhole_debug :   Generated zone: %s" % new_zone_id)
		
		# Update target zone ID
		if new_zone_id:
			print("Wormhole_debug :   Zone generation SUCCESS - updating wormhole target to: %s" % new_zone_id)
			target_zone_id = new_zone_id
			is_undiscovered = false
			update_label()
		else:
			print("Wormhole_debug :   ERROR - Failed to generate zone!")
			is_generating_zone = false
			return
	
	# Get source and target zone info for debugging
	var source_zone = ZoneManager.get_zone(source_zone_id) if ZoneManager else {}
	var target_zone = ZoneManager.get_zone(target_zone_id) if ZoneManager else {}
	if target_zone.is_empty():
		print("Wormhole: Target zone '%s' not found!" % target_zone_id)
		return
	
	# DEBUG: Print teleport information
	print("Wormhole_debug : === FINAL TELEPORT CHECK ===")
	print("Wormhole_debug :   FROM: %s (difficulty %d, size %.0f)" % [source_zone_id, source_zone.difficulty, source_zone.spawn_area_size])
	print("Wormhole_debug :   TO: %s (difficulty %d, size %.0f)" % [target_zone_id, target_zone.difficulty, target_zone.spawn_area_size])
	print("Wormhole_debug :   Wormhole Type: %s (enum: %d)" % [("DEPTH" if wormhole_type == WormholeType.DEPTH else "LATERAL"), wormhole_type])
	print("Wormhole_debug :   Size change: %.0f -> %.0f" % [source_zone.spawn_area_size, target_zone.spawn_area_size])
	print("Wormhole_debug :   Difficulty change: %d -> %d" % [source_zone.difficulty, target_zone.difficulty])
	
	# CRITICAL CHECKS
	if wormhole_type == WormholeType.DEPTH and source_zone.difficulty == target_zone.difficulty:
		print("Wormhole_debug :   *** BUG *** DEPTH wormhole but SAME difficulty! This is WRONG!")
	if wormhole_type == WormholeType.LATERAL and source_zone.difficulty != target_zone.difficulty:
		print("Wormhole_debug :   *** BUG *** LATERAL wormhole but DIFFERENT difficulty! This is WRONG!")
	if wormhole_type == WormholeType.DEPTH and source_zone.spawn_area_size == target_zone.spawn_area_size:
		print("Wormhole_debug :   *** BUG *** DEPTH wormhole but SAME SIZE! This is WRONG!")
	
	print("Wormhole_debug : ===========================")
	
	# OLD DEBUG (keep for compatibility)
	print("=== TELEPORT DEBUG ===")
	if not source_zone.is_empty():
		print("Source Zone: %s (difficulty %d, size %.0fx%.0f)" % [source_zone_id, source_zone.difficulty, source_zone.spawn_area_size, source_zone.spawn_area_size])
	print("Target Zone: %s (difficulty %d, size %.0fx%.0f)" % [target_zone_id, target_zone.difficulty, target_zone.spawn_area_size, target_zone.spawn_area_size])
	print("Wormhole Type: %s" % ("DEPTH" if wormhole_type == WormholeType.DEPTH else "LATERAL"))
	if wormhole_type == WormholeType.DEPTH:
		var is_forward_meta = get_meta("is_forward", true)
		print("Direction: %s (is_forward=%s)" % ["FORWARD (toward center/higher diff)" if is_forward_meta else "BACKWARD (toward outer/lower diff)", is_forward_meta])
	print("======================")
	
	# CRITICAL: Wait for zone layer to be created if it doesn't exist yet
	if not target_zone.layer_node:
		# Wait a few frames to allow layer creation to complete
		for i in range(10):
			await get_tree().process_frame
			# Re-fetch zone data
			target_zone = ZoneManager.get_zone(target_zone_id) if ZoneManager else {}
			if not target_zone.is_empty() and target_zone.layer_node:
				is_generating_zone = false  # Unlock for other units
				break
		
		if target_zone.is_empty() or not target_zone.layer_node:
			print("Wormhole: Zone layer not ready for '%s' after waiting!" % target_zone_id)
			is_generating_zone = false  # Unlock even on failure
			return
	else:
		# Layer already exists, unlock immediately
		is_generating_zone = false
	
	# Find spawn position (return wormhole or zone center)
	var target_position = Vector2.ZERO
	
	# Look for return wormhole in the SAME type of wormhole array
	var return_wormholes = []
	var wormhole_type_name = ""
	if wormhole_type == WormholeType.LATERAL:
		return_wormholes = target_zone.lateral_wormholes
		wormhole_type_name = "lateral"
	else:
		return_wormholes = target_zone.depth_wormholes
		wormhole_type_name = "depth"
	
	print("Wormhole: Looking for return %s wormhole to '%s' in target zone '%s'" % [wormhole_type_name, source_zone_id, target_zone_id])
	print("Wormhole: Target zone has %d %s wormholes" % [return_wormholes.size(), wormhole_type_name])
	
	var target_wormhole = null
	for wormhole in return_wormholes:
		if is_instance_valid(wormhole):
			print("  - %s wormhole pointing to: %s" % [wormhole_type_name.capitalize(), wormhole.target_zone_id])
			if wormhole.target_zone_id == source_zone_id:
				target_wormhole = wormhole
				break
	
	if target_wormhole:
		target_position = target_wormhole.global_position
		print("Wormhole: Found return wormhole at %s" % target_position)
	else:
		# No return wormhole, spawn near center of zone
		target_position = Vector2.ZERO
		print("Wormhole: WARNING - No return wormhole found! Spawning at zone center (0,0)")
	
	# Clear unit's command queue and reset state BEFORE teleporting
	if unit.has_method("clear_commands"):
		unit.clear_commands()
	
	# Create travel effect
	spawn_travel_effect()
	
	# Transfer this unit through ZoneManager (this changes the unit's parent and position)
	if ZoneManager:
		ZoneManager.transfer_units_to_zone([unit], target_zone_id, target_position)
		
		# Switch camera to target zone so player can see/control units
		ZoneManager.switch_to_zone(target_zone_id)
		
		# Pan camera to arrival position
		var camera = get_viewport().get_camera_2d()
		if camera and camera.has_method("focus_on_position"):
			camera.focus_on_position(target_position, 0.5)
	
	# Wait for physics frame to ensure position/reparenting is complete
	await get_tree().physics_frame
	
	# After teleport, ensure unit is completely reset
	if is_instance_valid(unit):
		# Ensure complete stop
		unit.velocity = Vector2.ZERO
		unit.target_entity = null
		unit.target_position = unit.global_position  # Target is current position
		unit.ai_state = 0  # AIState.IDLE
		
		# Reset navigation agent to prevent old path from executing
		if unit.has_node("NavigationAgent2D"):
			var nav_agent = unit.get_node("NavigationAgent2D")
			# Clear the navigation path completely
			nav_agent.target_position = unit.global_position
			nav_agent.set_velocity(Vector2.ZERO)
		
		# Reveal fog of war around arrival position
		if FogOfWarManager:
			FogOfWarManager.reveal_position(target_zone_id, target_position, 800.0)
			
	
	# Spawn arrival effect at target
	if is_instance_valid(target_wormhole):
		target_wormhole.spawn_arrival_effect()
	
	units_traveled.emit([unit], target_zone_id)
	

func spawn_travel_effect():
	"""Visual effect when units depart through wormhole"""
	var burst = CPUParticles2D.new()
	burst.global_position = global_position
	burst.emitting = true
	burst.one_shot = true
	burst.explosiveness = 0.8
	
	burst.amount = 30
	burst.lifetime = 1.0
	burst.speed_scale = 2.0
	
	burst.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 20.0
	
	burst.direction = Vector2(0, 0)
	burst.spread = 180.0
	burst.initial_velocity_min = 80.0
	burst.initial_velocity_max = 150.0
	
	burst.color = base_modulate
	burst.scale_amount_min = 2.0
	burst.scale_amount_max = 4.0
	
	get_parent().add_child(burst)
	
	# Cleanup after effect
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(burst):
		burst.queue_free()

func spawn_arrival_effect():
	"""Visual effect when units arrive through wormhole"""
	var burst = CPUParticles2D.new()
	burst.global_position = global_position
	burst.emitting = true
	burst.one_shot = true
	burst.explosiveness = 0.7
	
	burst.amount = 25
	burst.lifetime = 0.8
	burst.speed_scale = 1.5
	
	burst.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 50.0
	
	burst.direction = Vector2(0, 0)
	burst.spread = 180.0
	burst.initial_velocity_min = 50.0
	burst.initial_velocity_max = 100.0
	
	burst.color = Color(1.0, 1.0, 1.0, 0.8)
	burst.scale_amount_min = 1.5
	burst.scale_amount_max = 3.0
	
	get_parent().add_child(burst)
	
	# Cleanup
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(burst):
		burst.queue_free()

func get_display_name() -> String:
	"""Get display name for UI"""
	return "Wormhole to Zone %s" % target_zone_id

func get_description() -> String:
	"""Get description for UI"""
	return "Right-click with units selected to travel to Zone %s" % target_zone_id
