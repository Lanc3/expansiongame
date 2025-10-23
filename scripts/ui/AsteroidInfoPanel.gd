extends PanelContainer
## Floating panel that displays asteroid composition and stats

@onready var asteroid_name_label: Label = $VBox/Header/NameLabel
@onready var total_label: Label = $VBox/Header/TotalLabel
@onready var composition_container: VBoxContainer = $VBox/CompositionScroll/CompositionContainer
@onready var status_label: Label = $VBox/Footer/StatusLabel
@onready var value_label: Label = $VBox/Footer/ValueLabel

var current_asteroid: ResourceNode = null
var update_timer: float = 0.0
var update_interval: float = 0.2  # Update 5 times per second

# Resource bar template scene
var resource_bar_template: PackedScene

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(delta: float):
	if not visible or not is_instance_valid(current_asteroid):
		return
	
	# Throttled updates
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		update_display()

func show_asteroid(asteroid: ResourceNode):
	"""Display information for selected asteroid"""
	if not is_instance_valid(asteroid):
		hide_panel()
		return
	
	current_asteroid = asteroid
	visible = true
	update_display()
	position_panel()

func hide_panel():
	"""Hide the panel"""
	visible = false
	current_asteroid = null

func update_display():
	"""Update all asteroid information"""
	if not is_instance_valid(current_asteroid):
		hide_panel()
		return
	
	# Update header
	if asteroid_name_label:
		asteroid_name_label.text = "Asteroid #%d" % current_asteroid.asteroid_id
	
	if total_label:
		total_label.text = "Total: %d units" % int(current_asteroid.get_remaining_resources())
	
	# Update composition
	update_composition()
	
	# Update footer
	if status_label:
		if current_asteroid.is_scanned:
			status_label.text = "Status: Scanned"
			status_label.modulate = Color(0.3, 1.0, 0.3)
		else:
			if current_asteroid.scanning_unit != null:
				var progress = current_asteroid.get_scan_progress_percent()
				status_label.text = "Scanning: %.0f%%" % progress
				status_label.modulate = Color(0.3, 0.8, 1.0)
			else:
				status_label.text = "Status: Not Scanned"
				status_label.modulate = Color(1.0, 0.5, 0.3)
	
	if value_label:
		if current_asteroid.is_scanned:
			var estimated_value = current_asteroid.get_estimated_value()
			value_label.text = "Est. Value: %d" % int(estimated_value)
			value_label.visible = true
		else:
			value_label.visible = false

func update_composition():
	"""Update composition display with progress bars"""
	if not composition_container:
		return
	
	# Clear existing bars
	for child in composition_container.get_children():
		child.queue_free()
	
	if not current_asteroid.is_scanned:
		# Show "Not Scanned" message
		var label = Label.new()
		label.text = "Scan asteroid to reveal composition"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		composition_container.add_child(label)
		return
	
	# Get composition data
	var composition = current_asteroid.get_composition_display()
	
	# Create bars for each resource type
	for comp in composition:
		var bar_container = create_resource_bar(comp)
		composition_container.add_child(bar_container)

func create_resource_bar(comp: Dictionary) -> HBoxContainer:
	"""Create a single resource bar entry"""
	var container = HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 25)
	
	# Progress bar
	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(100, 20)
	progress_bar.max_value = 100.0
	progress_bar.value = comp.percent
	progress_bar.show_percentage = false
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Style the progress bar with resource color
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	progress_bar.add_theme_stylebox_override("background", style_bg)
	
	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = comp.color
	progress_bar.add_theme_stylebox_override("fill", style_fg)
	
	container.add_child(progress_bar)
	
	# Label with name and percentage
	var label = Label.new()
	label.text = "%s (%.0f%%)" % [comp.name, comp.percent]
	label.custom_minimum_size = Vector2(150, 0)
	label.add_theme_color_override("font_color", comp.color)
	container.add_child(label)
	
	return container

func position_panel():
	"""Position panel near the selected asteroid"""
	if not is_instance_valid(current_asteroid):
		return
	
	# Get camera and viewport
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Convert asteroid world position to screen position
	var asteroid_world_pos = current_asteroid.global_position
	var screen_pos = (asteroid_world_pos - camera.global_position) * camera.zoom + viewport_size / 2
	
	# Offset to the right and slightly down
	var offset = Vector2(100, 50)
	var panel_pos = screen_pos + offset
	
	# Keep panel on screen
	var panel_size = size
	if panel_pos.x + panel_size.x > viewport_size.x:
		panel_pos.x = screen_pos.x - panel_size.x - 100
	if panel_pos.y + panel_size.y > viewport_size.y:
		panel_pos.y = viewport_size.y - panel_size.y - 20
	
	panel_pos.x = clamp(panel_pos.x, 10, viewport_size.x - panel_size.x - 10)
	panel_pos.y = clamp(panel_pos.y, 10, viewport_size.y - panel_size.y - 10)
	
	global_position = panel_pos

