extends Node2D
class_name ConstructionGhost
## Visual preview of building during construction

signal construction_cancelled()
signal construction_confirmed(building_type: String, position: Vector2)

var building_type: String = ""
var building_data: Dictionary = {}
var is_valid_placement: bool = true
var zone_id: String = ""

# Visual components
var sprite: Sprite2D
var range_indicator: Line2D
var collision_indicator: ColorRect
var progress_bar: ProgressBar
var construction_label: Label

# Construction progress
var construction_progress: float = 0.0
var builder_drone: Node2D = null

func _ready():
	# Create visual components
	create_visuals()
	
	# DON'T follow mouse initially - this is the construction ghost, not placement ghost
	# Placement ghost is separate (in PlacementController)
	set_process(false)
	
	print("ConstructionGhost: _ready() called")

func initialize(b_type: String, b_data: Dictionary, z_id: String):
	"""Initialize ghost with building data"""
	building_type = b_type
	building_data = b_data
	zone_id = z_id
	
	
	# Update range circle immediately
	if "collision_radius" in building_data:
		update_range_circle(building_data.collision_radius)
	
	if sprite and "icon_path" in building_data:
		# Try to load building sprite
		var texture_path = building_data.icon_path
		if ResourceLoader.exists(texture_path):
			sprite.texture = load(texture_path)

func create_visuals():
	"""Create visual components for ghost"""
	# Main sprite
	sprite = Sprite2D.new()
	sprite.name = "GhostSprite"
	sprite.modulate = Color(0.5, 1.0, 0.5, 0.4)  # Green transparent
	sprite.scale = Vector2(1.0, 1.0)
	add_child(sprite)
	
	# Pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "modulate:a", 0.6, 1.0)
	tween.tween_property(sprite, "modulate:a", 0.3, 1.0)
	
	# Collision radius indicator
	range_indicator = Line2D.new()
	range_indicator.name = "RangeIndicator"
	range_indicator.width = 2.0
	range_indicator.default_color = Color(0.5, 1.0, 0.5, 0.5)
	add_child(range_indicator)
	
	# Progress bar (hidden initially)
	progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.size = Vector2(120, 16)
	progress_bar.position = Vector2(-60, -100)
	progress_bar.show_percentage = true
	progress_bar.value = 0
	progress_bar.visible = false
	
	# Style the progress bar
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_bg.border_width_left = 1
	style_bg.border_width_top = 1
	style_bg.border_width_right = 1
	style_bg.border_width_bottom = 1
	style_bg.border_color = Color(0.5, 0.5, 0.5, 1.0)
	progress_bar.add_theme_stylebox_override("background", style_bg)
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.3, 0.8, 0.3, 0.9)
	progress_bar.add_theme_stylebox_override("fill", style_fill)
	
	add_child(progress_bar)
	
	# Add construction label
	construction_label = Label.new()
	construction_label.name = "ConstructionLabel"
	construction_label.text = "CONSTRUCTING..."
	construction_label.position = Vector2(-60, -120)
	construction_label.add_theme_font_size_override("font_size", 12)
	construction_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
	construction_label.visible = false
	add_child(construction_label)

func _process(_delta: float):
	# Update placement validity check
	update_placement_validity()

func update_placement_validity():
	"""Check if current position is valid for placement"""
	var mouse_pos = get_global_mouse_position()
	
	# Check with building database
	is_valid_placement = BuildingDatabase.is_valid_placement(building_type, mouse_pos, zone_id)
	
	# Update color based on validity
	if is_valid_placement:
		sprite.modulate = Color(0.5, 1.0, 0.5, 0.5)  # Green = valid
		range_indicator.default_color = Color(0.5, 1.0, 0.5, 0.5)
	else:
		sprite.modulate = Color(1.0, 0.3, 0.3, 0.5)  # Red = invalid
		range_indicator.default_color = Color(1.0, 0.3, 0.3, 0.5)
	
	# Update range indicator circle
	if "collision_radius" in building_data:
		update_range_circle(building_data.collision_radius)

func update_range_circle(radius: float):
	"""Update the range indicator circle"""
	var points = []
	var segments = 32
	
	for i in range(segments + 1):
		var angle = (i * TAU) / segments
		var point = Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	range_indicator.points = PackedVector2Array(points)

func start_construction(drone: Node2D):
	"""Begin construction with a builder drone"""
	builder_drone = drone
	construction_progress = 0.0
	
	# Show progress indicators
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = 0
	
	if construction_label:
		construction_label.visible = true
	
	# Stop pulsing animation and following mouse
	set_process(false)
	
	# Update visual to show construction state
	if sprite:
		sprite.modulate = Color(0.8, 0.8, 1.0, 0.5)  # Blue tint for construction
	

func update_construction_progress(progress: float):
	"""Update construction progress (0.0 to 1.0)"""
	construction_progress = clamp(progress, 0.0, 1.0)
	
	if progress_bar:
		progress_bar.value = construction_progress * 100.0
	
	# Update transparency based on progress
	if sprite:
		sprite.modulate.a = 0.3 + (construction_progress * 0.7)
	
	# Check if complete
	if construction_progress >= 1.0:
		complete_construction()

func complete_construction():
	"""Finish construction and spawn actual building"""
	
	# Spawn the actual building
	spawn_real_building()
	
	# Remove ghost
	queue_free()

func spawn_real_building():
	"""Spawn the actual building at this location"""
	if "scene" not in building_data:
		return
	
	var scene_path = building_data.scene
	if not ResourceLoader.exists(scene_path):
		return
	
	var building_scene = load(scene_path)
	var building = building_scene.instantiate()
	building.global_position = global_position
	building.zone_id = zone_id
	
	# Add to appropriate zone layer
	var zone_data = ZoneManager.get_zone(zone_id) if ZoneManager else {}
	var zone_layer = zone_data.get("layer_node", null)
	if zone_layer and is_instance_valid(zone_layer):
		var buildings_container = zone_layer.get_node_or_null("Entities/Buildings")
		if buildings_container:
			buildings_container.add_child(building)
		else:
			zone_layer.add_child(building)
	else:
		# Fallback
		get_tree().current_scene.add_child(building)
	
	# Register with EntityManager
	if EntityManager:
		EntityManager.register_building(building)
	

func cancel_construction():
	"""Cancel construction and refund resources"""
	
	# Refund resources
	if ResourceManager and "cost" in building_data:
		ResourceManager.refund_resources(building_data.cost)
	
	# Emit signal
	construction_cancelled.emit()
	
	# Remove ghost
	queue_free()

func get_construction_info() -> Dictionary:
	"""Get construction information for UI"""
	return {
		"building_type": building_type,
		"progress": construction_progress,
		"progress_percent": construction_progress * 100.0,
		"position": global_position,
		"zone_id": zone_id,
		"is_valid": is_valid_placement
	}
