extends Node
## Handles building placement mode when builder drone selects a building to construct

signal placement_completed()
signal placement_cancelled()

var is_placing: bool = false
var builder_drone: BuilderDrone = null
var building_type: String = ""
var building_data: Dictionary = {}
var placement_ghost: Node2D = null

func _ready():
	set_process_input(false)

func start_placement(builder: BuilderDrone, b_type: String, b_data: Dictionary):
	"""Start building placement mode"""
	if is_placing:
		print("PlacementController: Already in placement mode, ignoring new request")
		return
	
	builder_drone = builder
	building_type = b_type
	building_data = b_data
	is_placing = true
	
	# Create visual ghost
	create_placement_ghost()
	
	# Enable input processing
	set_process_input(true)
	set_process(true)
	
	print("PlacementController: Placement mode started for %s (ghost created)" % building_type)

func create_placement_ghost():
	"""Create a visual ghost that follows the mouse"""
	placement_ghost = Node2D.new()
	placement_ghost.name = "PlacementGhost"
	
	# Add sprite
	var sprite = Sprite2D.new()
	sprite.texture = load("res://assets/ui/Grey/panel_beveledGrey.png")  # Placeholder
	sprite.modulate = Color(0.5, 1.0, 0.5, 0.5)  # Green transparent
	sprite.scale = Vector2(2.0, 2.0)
	placement_ghost.add_child(sprite)
	
	# Add range indicator
	var range_line = Line2D.new()
	range_line.width = 2.0
	range_line.default_color = Color(0.5, 1.0, 0.5, 0.4)
	
	var radius = building_data.get("collision_radius", 75.0)
	var points = []
	var segments = 32
	for i in range(segments + 1):
		var angle = (i * TAU) / segments
		var point = Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	range_line.points = PackedVector2Array(points)
	placement_ghost.add_child(range_line)
	
	# Add to scene
	get_tree().current_scene.add_child(placement_ghost)

func _process(_delta: float):
	if not is_placing or not placement_ghost:
		return
	
	# Update ghost position to follow mouse
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_tree().root.get_camera_2d()
	if camera:
		var world_pos = camera.get_screen_center_position() + (mouse_pos - get_viewport().get_visible_rect().size / 2) / camera.zoom
		placement_ghost.global_position = world_pos
		
		# Update color based on validity
		update_ghost_validity(world_pos)

func update_ghost_validity(world_pos: Vector2):
	"""Update ghost color based on placement validity"""
	if not placement_ghost:
		return
	
	var zone_id = ZoneManager.get_unit_zone(builder_drone) if ZoneManager and builder_drone else 1
	var is_valid = BuildingDatabase.is_valid_placement(building_type, world_pos, zone_id)
	
	# Update sprite color
	var sprite = placement_ghost.get_node_or_null("Sprite2D")
	if sprite:
		if is_valid:
			sprite.modulate = Color(0.5, 1.0, 0.5, 0.5)  # Green
		else:
			sprite.modulate = Color(1.0, 0.3, 0.3, 0.5)  # Red

func _input(event: InputEvent):
	if not is_placing:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Confirm placement
			confirm_placement()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Cancel placement
			cancel_placement()
			get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("ui_cancel"):
		# ESC to cancel
		cancel_placement()
		get_viewport().set_input_as_handled()

func confirm_placement():
	"""Confirm building placement at current ghost position"""
	if not placement_ghost or not is_instance_valid(builder_drone):
		print("PlacementController: Cannot confirm - ghost or builder invalid")
		cancel_placement()
		return
	
	var placement_pos = placement_ghost.global_position
	var zone_id = ZoneManager.get_unit_zone(builder_drone) if ZoneManager else 1
	
	# Validate placement
	if not BuildingDatabase.is_valid_placement(building_type, placement_pos, zone_id):
		print("PlacementController: Invalid placement location")
		return
	
	print("PlacementController: Building placed at %s, starting construction" % placement_pos)
	
	# Start construction
	builder_drone.start_construction(building_type, placement_pos)
	
	# Emit signal before cleaning up
	placement_completed.emit()
	
	# End placement mode (remove the placement ghost)
	cancel_placement()

func cancel_placement():
	"""Cancel building placement"""
	var was_placing = is_placing
	is_placing = false
	
	# Remove ghost
	if is_instance_valid(placement_ghost):
		placement_ghost.queue_free()
	placement_ghost = null
	
	# Disable input
	set_process_input(false)
	set_process(false)
	
	builder_drone = null
	building_type = ""
	building_data = {}
	
	# Emit signal if we were actually placing
	if was_placing:
		placement_cancelled.emit()
	
	print("PlacementController: Placement cancelled")

