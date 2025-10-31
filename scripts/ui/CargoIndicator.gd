extends Control
class_name CargoIndicator
## Floating cargo capacity indicator that follows mining drones

@onready var progress_bar: ProgressBar = $Panel/ProgressBar
@onready var label: Label = $Panel/Label
@onready var panel: Panel = $Panel

var target_unit: Node2D = null
var world_offset: Vector2 = Vector2(0, 35)  # Below the drone in world space
var base_scale: float = 1.0 / 3.0  # 3x smaller than default

func _ready():
	# Style setup
	modulate.a = 0.9
	
func _process(_delta: float):
	if not is_instance_valid(target_unit):
		queue_free()
		return
	
	# Check if target is in current zone
	if ZoneManager:
		var unit_zone = ZoneManager.get_unit_zone(target_unit)
		var current_zone = ZoneManager.current_zone_id
		
		if unit_zone != current_zone:
			visible = false
			return
		else:
			visible = true
	
	# Follow target unit (convert world position to screen position)
	var camera = get_viewport().get_camera_2d()
	if camera:
		# Calculate screen position based on camera
		var viewport_center = get_viewport().get_visible_rect().size / 2
		var relative_pos = (target_unit.global_position - camera.global_position) * camera.zoom
		
		# Apply world offset and convert to screen space
		var screen_offset = world_offset * camera.zoom
		
		# Center the UI by subtracting half its width
		var ui_center_offset = Vector2(size.x * scale.x * 0.5, 0)
		
		global_position = viewport_center + relative_pos + screen_offset - ui_center_offset
		
		# Scale with camera zoom (smaller UI when zoomed out, larger when zoomed in)
		# Combined with base_scale of 1/3 for overall 3x smaller size
		scale = Vector2.ONE * base_scale * camera.zoom.x
	
	# Always face camera (no rotation)
	rotation = 0

func update_cargo(current: float, maximum: float):
	"""Update cargo display with current and max values"""
	if not progress_bar or not label:
		return
	
	progress_bar.max_value = maximum
	progress_bar.value = current
	label.text = "%d/%d" % [int(current), int(maximum)]
	
	# Color coding based on capacity
	var percent = current / maximum if maximum > 0 else 0
	
	if percent >= 0.9:
		progress_bar.modulate = Color(1.0, 0.3, 0.3)  # Red - full
	elif percent >= 0.7:
		progress_bar.modulate = Color(1.0, 0.6, 0.0)  # Orange - getting full
	elif percent >= 0.3:
		progress_bar.modulate = Color(1.0, 1.0, 0.3)  # Yellow - half
	else:
		progress_bar.modulate = Color(0.3, 1.0, 0.3)  # Green - plenty of space

