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
	else:  # DEPTH
		var is_forward = get_meta("is_forward", true)
		if is_forward:
			base_modulate = Color(0.6, 0.3, 1.0, 1.0)  # Purple for forward
		else:
			base_modulate = Color(0.3, 0.6, 1.0, 1.0)  # Blue for return
	
	# Setup visual
	setup_visual()
	
	# Connect mouse signals for hover effect
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Note: Click detection is handled by InputHandler, not Area2D input_event
	
	# Register with ZoneManager
	if ZoneManager:
		var wh_type = "lateral" if wormhole_type == WormholeType.LATERAL else "depth"
		ZoneManager.set_zone_wormhole(source_zone_id, self, wh_type)
	
	# Update label based on type and destination
	update_label()
	

func setup_visual():
	"""Setup wormhole visuals"""
	if sprite:
		# Use a circular sprite (we'll use a simple colored circle)
		sprite.modulate = base_modulate
		
		# Create a simple circular texture procedurally
		var image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		
		# Draw a circle
		for x in range(128):
			for y in range(128):
				var dx = x - 64
				var dy = y - 64
				var dist = sqrt(dx * dx + dy * dy)
				if dist < 50:
					var alpha = 1.0 - (dist / 50.0) * 0.5
					image.set_pixel(x, y, Color(base_modulate.r, base_modulate.g, base_modulate.b, alpha))
		
		var texture = ImageTexture.create_from_image(image)
		sprite.texture = texture
		sprite.scale = Vector2(1.5, 1.5)
	
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
		sprite.rotation += delta * 0.5
		
		# Pulsing glow when selected
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
	sprite.modulate = base_modulate

func _on_mouse_entered():
	"""Handle mouse hover"""
	is_hovered = true
	if sprite and not is_selected:
		sprite.modulate = base_modulate * 1.5

func _on_mouse_exited():
	"""Handle mouse exit"""
	is_hovered = false
	if sprite and not is_selected:
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
	if not can_travel():
		return
	
	if units.is_empty():
		return
	
	# Command units to move to wormhole position
	# When they arrive in range, they'll automatically teleport
	for unit in units:
		if is_instance_valid(unit) and unit.has_method("add_command"):
			unit.add_command(CommandSystem.CommandType.TRAVEL_WORMHOLE, global_position, self, false)

func teleport_unit(unit: Node2D):
	"""Teleport a single unit that has arrived at the wormhole"""
	if not can_travel() or not is_instance_valid(unit):
		return
	
	# If zone is currently being generated, wait
	if is_generating_zone:
		return
	
	# If undiscovered, generate zone first
	if is_undiscovered and ZoneDiscoveryManager:
		is_generating_zone = true  # Lock to prevent concurrent generation
		
		var new_zone_id = ""
		
		if wormhole_type == WormholeType.LATERAL:
			# Generate lateral zone
			new_zone_id = ZoneDiscoveryManager.generate_and_discover_lateral_zone(
				source_zone_id, self, wormhole_direction
			)
		else:  # DEPTH
			# Generate depth zone
			var source_zone = ZoneManager.get_zone(source_zone_id) if ZoneManager else {}
			if not source_zone.is_empty():
				var is_forward = get_meta("is_forward", true)
				var target_difficulty = source_zone.difficulty + (1 if is_forward else -1)
				new_zone_id = ZoneDiscoveryManager.generate_and_discover_depth_zone(
					source_zone_id, target_difficulty, wormhole_direction
				)
		
		# Update target zone ID
		if new_zone_id:
			target_zone_id = new_zone_id
			is_undiscovered = false
			update_label()
		else:
			print("Wormhole: Failed to generate zone!")
			is_generating_zone = false
			return
	
	# Get target zone
	var target_zone = ZoneManager.get_zone(target_zone_id) if ZoneManager else {}
	if target_zone.is_empty():
		print("Wormhole: Target zone '%s' not found!" % target_zone_id)
		return
	
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
	
	# Look for return wormhole
	var return_wormholes = []
	if wormhole_type == WormholeType.LATERAL:
		return_wormholes = target_zone.lateral_wormholes
	else:
		return_wormholes = target_zone.depth_wormholes
	
	print("Wormhole: Looking for return wormhole to '%s' in target zone '%s'" % [source_zone_id, target_zone_id])
	print("Wormhole: Target zone has %d depth wormholes" % return_wormholes.size())
	
	var target_wormhole = null
	for wormhole in return_wormholes:
		if is_instance_valid(wormhole):
			print("  - Depth wormhole pointing to: %s" % wormhole.target_zone_id)
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
