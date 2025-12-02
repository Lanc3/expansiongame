extends StaticBody2D
class_name ResourceNode
## Asteroid/resource node with multi-resource composition and scanning

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var collision: CollisionShape2D = $CollisionShape2D

# Multi-resource composition (up to 5 types)
var resource_composition: Array[Dictionary] = []
# Example: [{type_id: 12, amount: 300.0}, {type_id: 45, amount: 200.0}]

# Scanning state
var is_scanned: bool = false
var scan_progress: float = 0.0
var scanning_unit = null  # ScoutDrone reference
var scan_progress_bar = null  # Visual feedback node

# Orbital mechanics (for planets)
var orbital_planet: Node2D = null  # Planet being orbited
var orbital_radius: float = 0.0  # Distance from planet
var orbital_angle: float = 0.0  # Current angle in orbit

# Visual
var base_color: Color = Color(0.6, 0.5, 0.4)  # Brown for all asteroids
@export var visual_scale_on_depletion: bool = true

# Animation
var idle_time: float = 0.0
var base_rotation_speed: float = 0.5  # degrees per second
var current_rotation_speed: float = 0.5
var float_amplitude: float = 5.0
var float_speed: float = 1.0
var base_position: Vector2
var current_size_tier: int = -1  # Initialize to -1 to force initial texture load, then 0=big, 1=med, 2=small, 3=tiny

# Sprite variety
var sprite_color_set: String = ""  # "Brown" or "Grey" (kept for backward compatibility, not used for new asteroids)
var base_scale: float = 1.0  # Determined by total resources
var selected_asteroid_image: String = ""  # Randomly selected asteroid image path

# Array of 20 asteroid images
const ASTEROID_IMAGES: Array[String] = [
	"asteroid_1.png",
	"asteroid_2.png",
	"asteroid_3.png",
	"asteroid_4.png",
	"asteroid_5.png",
	"asteroid_6.png",
	"asteroid_7.png",
	"asteroid_8.png",
	"asteroid_9.png",
	"asteroid_10.png",
	"asteroid_11.png",
	"asteroid_ 12.png",  # Note: has a space in filename
	"asteroid_13.png",
	"asteroid_14.png",
	"asteroid_15.png",
	"asteroid_16.png",
	"asteroid_17.png",
	"asteroid_18.png",
	"asteroid_19.png",
	"asteroid_20.png"
]

# Updated sprite texture arrays - now 2D arrays [tier][variant] (kept for backward compatibility)
var brown_sprites: Array = [
	["meteorBrown_big1.png", "meteorBrown_big2.png", "meteorBrown_big3.png", "meteorBrown_big4.png"],
	["meteorBrown_med1.png", "meteorBrown_med3.png"],
	["meteorBrown_small1.png", "meteorBrown_small2.png"],
	["meteorBrown_tiny1.png", "meteorBrown_tiny2.png"]
]

var grey_sprites: Array = [
	["meteorGrey_big1.png", "meteorGrey_big2.png", "meteorGrey_big3.png", "meteorGrey_big4.png"],
	["meteorGrey_med1.png", "meteorGrey_med2.png"],
	["meteorGrey_small1.png", "meteorGrey_small2.png"],
	["meteorGrey_tiny1.png", "meteorGrey_tiny2.png"]
]

# Totals
var total_resources: float = 0.0
var remaining_resources: float = 0.0
var depleted: bool = false

# Unique ID for UI
var asteroid_id: int = 0

func _ready():
	# Generate unique ID
	asteroid_id = randi() % 10000
	
	# Generate random composition only if not already set (e.g., from save load)
	if resource_composition.is_empty():
		generate_composition()
		# Set initial values only for new asteroids
		remaining_resources = total_resources
	
	# Store base position for floating animation
	base_position = global_position
	
	# Randomize animation timing to avoid synchronization
	idle_time = randf() * TAU
	
	# Randomly select one of the 20 asteroid images
	var random_index = randi() % ASTEROID_IMAGES.size()
	selected_asteroid_image = ASTEROID_IMAGES[random_index]
	
	# Keep sprite_color_set for backward compatibility (not used for new asteroids)
	sprite_color_set = "Brown" if randf() < 0.5 else "Grey"
	
	# Calculate base scale based on total resources
	base_scale = calculate_base_scale(total_resources)
	
	# Randomize starting rotation (0 to 360 degrees)
	rotation = randf() * TAU
	
	# Set color for asteroids (dimmed if unscanned)
	if sprite:
		if is_scanned:
			sprite.modulate = base_color
		else:
			sprite.modulate = base_color * Color(0.7, 0.7, 0.7)  # Dimmer when unscanned
	
	update_visual()
	setup_collision()
	
	# Set to pausable so resources respect game pause
	# Note: Off-screen processing is handled by visibility settings, not process_mode
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	EntityManager.register_resource(self)
	add_to_group("resources")
	add_to_group("selectable")

func _exit_tree():
	EntityManager.unregister_resource(self)
	if scan_progress_bar:
		scan_progress_bar.queue_free()

func _process(delta: float):
	"""Idle animation - floating and rotation (optimized for performance)"""
	if depleted:
		return
	
	# Performance optimization: only animate asteroids in current zone
	if has_meta("zone_id") and ZoneManager:
		var zone_id = get_meta("zone_id")
		if zone_id != ZoneManager.current_zone_id:
			# Skip animation for asteroids not in current zone
			return
	
	idle_time += delta
	
	# Floating motion (sine wave)
	var float_offset = sin(idle_time * float_speed) * float_amplitude
	global_position = base_position + Vector2(0, float_offset)
	
	# Idle rotation
	rotation += deg_to_rad(current_rotation_speed * delta)

func setup_collision():
	collision_layer = 4  # Layer 2 (Resources)
	collision_mask = 0

func generate_composition():
	"""Generate 1-5 random resources totaling 500-2000"""
	var total = randf_range(500.0, 2000.0)
	var num_types = randi_range(1, 5)
	var remaining = total
	
	resource_composition.clear()
	
	for i in range(num_types):
		var is_last = (i == num_types - 1)
		var amount: float
		
		if is_last:
			amount = remaining
		else:
			# Allocate between 15% and 60% of remaining
			var min_percent = 0.15
			var max_percent = 0.60
			amount = randf_range(remaining * min_percent, remaining * max_percent)
		
		var resource_id = ResourceDatabase.get_weighted_random_resource()
		
		resource_composition.append({
			"type_id": resource_id,
			"amount": amount,
			"initial_amount": amount
		})
		
		remaining -= amount
	
	# Calculate total
	total_resources = 0.0
	for comp in resource_composition:
		total_resources += comp.amount
	

func extract_resource(amount: float) -> Dictionary:
	"""Extract resources proportionally from composition. Returns dict of extracted amounts by type_id"""
	if depleted or not is_scanned:
		return {}
	
	var extracted_by_type = {}
	var extraction_ratio = min(amount / remaining_resources, 1.0)
	
	for comp in resource_composition:
		if comp.amount > 0:
			var extracted = comp.amount * extraction_ratio
			comp.amount -= extracted
			extracted_by_type[comp.type_id] = extracted
	
	remaining_resources -= amount
	remaining_resources = max(0.0, remaining_resources)
	
	if remaining_resources <= 0:
		depleted = true
		on_depleted()
	
	update_visual()
	return extracted_by_type

func start_scan(scout) -> bool:
	"""Initiate scanning process"""
	if is_scanned:
		return false  # Already scanned
	
	if scanning_unit != null:
		return false  # Already being scanned
	
	scanning_unit = scout
	scan_progress = 0.0
	
	# Create visual progress bar
	create_scan_progress_bar()
	
	return true

func update_scan(delta: float):
	"""Progress the scan based on delta time"""
	if is_scanned or scanning_unit == null:
		return
	
	var scan_duration = get_scan_duration()
	scan_progress += delta / scan_duration
	
	# Update progress bar
	if scan_progress_bar:
		scan_progress_bar.value = scan_progress * 100.0
	
	if scan_progress >= 1.0:
		complete_scan()

func complete_scan():
	"""Mark scan as complete"""
	is_scanned = true
	scan_progress = 1.0
	scanning_unit = null
	
	# Remove progress bar
	if scan_progress_bar:
		scan_progress_bar.queue_free()
		scan_progress_bar = null
	
	# Brighten the asteroid (remove dim effect)
	if sprite:
		sprite.modulate = base_color
	
	# Add subtle glow based on most valuable resource
	add_scan_glow()
	
	# Update visual to show resource count
	update_visual()
	

func cancel_scan():
	"""Cancel ongoing scan"""
	scanning_unit = null
	scan_progress = 0.0
	
	if scan_progress_bar:
		scan_progress_bar.queue_free()
		scan_progress_bar = null

func get_scan_duration() -> float:
	"""Calculate scan duration: 60s at 1000 resources, 30s at 500"""
	return 60.0 * (total_resources / 1000.0)

func get_scan_progress_percent() -> float:
	"""Get scan progress as percentage (0-100)"""
	return scan_progress * 100.0

func create_scan_progress_bar():
	"""Create visual progress bar above asteroid"""
	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(60, 8)
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	
	# Style the progress bar
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	progress_bar.add_theme_stylebox_override("background", style_bg)
	
	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = Color(0.3, 0.8, 1.0, 1.0)  # Cyan
	progress_bar.add_theme_stylebox_override("fill", style_fg)
	
	# Position above sprite
	progress_bar.position = Vector2(-30, -50)
	add_child(progress_bar)
	scan_progress_bar = progress_bar

func add_scan_glow():
	"""Add subtle colored glow based on most valuable resource"""
	if not sprite:
		return
	
	# Find most valuable resource
	var max_value = 0.0
	var max_color = Color.WHITE
	
	for comp in resource_composition:
		var value = ResourceDatabase.get_resource_value(comp.type_id)
		if value > max_value:
			max_value = value
			max_color = ResourceDatabase.get_resource_color(comp.type_id)
	
	# Add subtle glow (blend with brown base)
	sprite.modulate = base_color.lerp(max_color, 0.3)

func update_visual():
	"""Update visual representation with progressive sizing"""
	# Update label - only show for scanned asteroids
	if label:
		if is_scanned:
			label.text = str(int(remaining_resources))
			label.visible = true
		else:
			label.visible = false  # Hide label for unscanned
	
	if not sprite:
		return
	
	# Progressive size based on depletion percentage
	var depletion_percent = remaining_resources / total_resources if total_resources > 0 else 0
	
	# Determine size tier (0=big, 1=med, 2=small, 3=tiny) - used for rotation speed and particles
	var new_tier = 0
	if depletion_percent > 0.75:
		new_tier = 0  # Big
	elif depletion_percent > 0.5:
		new_tier = 1  # Med
	elif depletion_percent > 0.25:
		new_tier = 2  # Small
	else:
		new_tier = 3  # Tiny
	
	# Set sprite texture to selected asteroid image
	if selected_asteroid_image.is_empty():
		# Fallback: randomly select if not set (for backward compatibility)
		var random_index = randi() % ASTEROID_IMAGES.size()
		selected_asteroid_image = ASTEROID_IMAGES[random_index]
	
	# Load the selected asteroid image (Godot caches loaded resources, so this is efficient)
	sprite.texture = load("res://assets/sprites/Meteors/" + selected_asteroid_image)
	
	# Spawn particle burst on size transition (when tier changes)
	if new_tier != current_size_tier:
		current_size_tier = new_tier
		
		# Spawn particle burst on size transition
		if is_scanned:  # Only show particles if scanned
			spawn_size_transition_particles()
		
		# Play crack sound
		if AudioManager.has_method("play_sound"):
			AudioManager.play_sound("asteroid_crack")
	
	# Update rotation speed (faster as smaller)
	current_rotation_speed = base_rotation_speed * (1.5 + (1.0 - depletion_percent))
	
	# Apply base scale from resources (dynamic sizing) and depletion percentage
	# Scale down as asteroid gets depleted
	var depletion_scale = lerp(0.25, 0.5, depletion_percent)  # Scale from 25% to 50% based on depletion (further reduced)
	sprite.scale = Vector2.ONE * base_scale * depletion_scale

func on_depleted():
	"""Called when asteroid is fully mined - EPIC DESTRUCTION!"""
	
	# 1. Warning shake
	await create_shake_effect(0.2)
	
	# 2. Flash effect
	if sprite:
		var original_modulate = sprite.modulate
		sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = original_modulate
	
	# 3. Spawn debris pieces
	spawn_debris_pieces()
	
	# 4. Spawn explosion particles
	spawn_explosion_particles()
	
	# 5. Hide original sprite and label
	if sprite:
		sprite.visible = false
	if label:
		label.visible = false
	
	# 6. Play explosion sound
	if AudioManager.has_method("play_sound"):
		AudioManager.play_sound("asteroid_explode")
	
	# 7. Wait for debris animation
	await get_tree().create_timer(2.0).timeout
	
	# 8. Cleanup
	if is_instance_valid(self):
		queue_free()

func is_depleted() -> bool:
	return depleted

func get_composition_display() -> Array:
	"""Get composition data formatted for UI display"""
	var display = []
	
	for comp in resource_composition:
		var percent = (comp.amount / total_resources) * 100.0 if total_resources > 0 else 0.0
		display.append({
			"type_id": comp.type_id,
			"name": ResourceDatabase.get_resource_name(comp.type_id),
			"amount": comp.amount,
			"percent": percent,
			"color": ResourceDatabase.get_resource_color(comp.type_id),
			"value": ResourceDatabase.get_resource_value(comp.type_id)
		})
	
	# Sort by amount (descending)
	display.sort_custom(func(a, b): return a.amount > b.amount)
	
	return display

func get_total_resources() -> float:
	return total_resources

func get_remaining_resources() -> float:
	return remaining_resources

func get_estimated_value() -> float:
	"""Calculate estimated value based on composition"""
	var value = 0.0
	for comp in resource_composition:
		var resource_value = ResourceDatabase.get_resource_value(comp.type_id)
		value += comp.amount * resource_value
	return value

func calculate_base_scale(resources: float) -> float:
	"""Calculate base scale factor based on total resources"""
	# Scale between 0.15 and 0.35 (further reduced)
	var min_resources = 500.0
	var max_resources = 2000.0
	var min_scale = 0.15
	var max_scale = 0.35
	
	var normalized = (resources - min_resources) / (max_resources - min_resources)
	normalized = clamp(normalized, 0.0, 1.0)
	
	return lerp(min_scale, max_scale, normalized)

func get_visual_radius() -> float:
	"""Get the approximate visual radius of the asteroid for orbit calculations"""
	# Base meteor sprite is approximately 101x84 pixels, so radius ~50
	var base_radius = 50.0
	
	# Apply the asteroid's scale
	var scaled_radius = base_radius * base_scale
	
	return scaled_radius

## Visual Effects Methods

func create_shake_effect(duration: float):
	"""Create rapid shake effect"""
	var shake_intensity = 10.0
	var shake_timer = 0.0
	var original_pos = global_position
	
	while shake_timer < duration:
		global_position = original_pos + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_timer += get_process_delta_time()
		await get_tree().process_frame
	
	global_position = original_pos

func spawn_debris_pieces():
	"""Spawn debris pieces that fly outward"""
	var num_pieces = randi_range(4, 6)
	
	for i in range(num_pieces):
		var debris = Sprite2D.new()
		# Randomly select from asteroid images for debris
		var random_debris_index = randi() % ASTEROID_IMAGES.size()
		debris.texture = load("res://assets/sprites/Meteors/" + ASTEROID_IMAGES[random_debris_index])
		debris.global_position = global_position
		debris.modulate = sprite.modulate if sprite else Color.WHITE
		# Scale down debris pieces
		debris.scale = Vector2.ONE * randf_range(0.3, 0.6)
		
		# Calculate outward direction
		var angle = (TAU / num_pieces) * i + randf_range(-0.3, 0.3)
		var velocity = Vector2(cos(angle), sin(angle)) * randf_range(100, 200)
		var angular_velocity = randf_range(-5, 5)
		
		# Add to parent
		get_parent().add_child(debris)
		
		# Animate debris
		animate_debris(debris, velocity, angular_velocity)

func animate_debris(debris: Sprite2D, velocity: Vector2, angular_velocity: float):
	"""Animate a single debris piece"""
	var lifetime = 2.0
	var elapsed = 0.0
	var gravity = Vector2(0, 50)  # Slight downward pull
	
	while elapsed < lifetime and is_instance_valid(debris):
		var delta = get_process_delta_time()
		elapsed += delta
		
		# Move with velocity and gravity
		debris.global_position += velocity * delta
		velocity += gravity * delta
		velocity *= 0.98  # Drag
		
		# Rotate
		debris.rotation += angular_velocity * delta
		
		# Fade out
		var fade_progress = elapsed / lifetime
		debris.modulate.a = 1.0 - fade_progress
		
		await get_tree().process_frame
	
	if is_instance_valid(debris):
		debris.queue_free()

func spawn_explosion_particles():
	"""Spawn explosion particle effect"""
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	
	# Particle settings
	particles.amount = 20
	particles.lifetime = 1.0
	particles.speed_scale = 2.0
	
	# Emission
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 10.0
	
	# Direction and spread
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 150.0
	
	# Gravity
	particles.gravity = Vector2(0, 98)
	
	# Color
	particles.color = Color.ORANGE
	particles.color_ramp = create_particle_gradient()
	
	# Scale
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.5
	
	# Add to scene
	get_parent().add_child(particles)
	
	# Auto-remove after particles finish
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func spawn_size_transition_particles():
	"""Spawn small particle burst on size transition"""
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.5
	
	# Smaller burst
	particles.amount = 10
	particles.lifetime = 0.5
	particles.speed_scale = 1.5
	
	# Emission
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 5.0
	
	# Direction
	particles.spread = 180.0
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 80.0
	
	# Color - brown dust
	particles.color = Color(0.6, 0.5, 0.4)
	
	# Scale
	particles.scale_amount_min = 0.3
	particles.scale_amount_max = 0.8
	
	# Add to scene
	get_parent().add_child(particles)
	
	# Auto-remove
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func create_particle_gradient() -> Gradient:
	"""Create color gradient for explosion particles"""
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color.WHITE)
	gradient.add_point(0.3, Color.ORANGE)
	gradient.add_point(0.7, Color.RED)
	gradient.add_point(1.0, Color(0.5, 0.1, 0.1, 0.0))  # Dark red, transparent
	return gradient
