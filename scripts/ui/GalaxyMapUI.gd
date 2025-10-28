extends Control
## Fullscreen galaxy map showing discovered zones and connections

signal zone_clicked(zone_id: String)
signal map_closed()

# Galaxy display settings
const ZONE_MARKER_SIZE: float = 40.0
const UNDISCOVERED_MARKER_SIZE: float = 25.0
const ZONE_LABEL_DISTANCE: float = 50.0

# Galaxy center is calculated dynamically
var galaxy_center: Vector2 = Vector2.ZERO

# Zone marker colors by difficulty
const DIFFICULTY_COLORS: Array[Color] = [
	Color(0.3, 1.0, 0.3),    # 1 - Bright green
	Color(0.5, 1.0, 0.2),    # 2 - Yellow-green
	Color(0.7, 1.0, 0.1),    # 3 - Yellow
	Color(1.0, 0.8, 0.0),    # 4 - Orange-yellow
	Color(1.0, 0.6, 0.0),    # 5 - Orange
	Color(1.0, 0.4, 0.1),    # 6 - Red-orange
	Color(1.0, 0.2, 0.2),    # 7 - Red
	Color(0.9, 0.1, 0.5),    # 8 - Magenta
	Color(0.7, 0.0, 0.8),    # 9 - Purple
]

# UI nodes
@onready var background: ColorRect = $Background
@onready var galaxy_shader_rect: ColorRect = $Background/GalaxyShader
@onready var zone_container: Control = $ZoneContainer
@onready var connection_lines: Control = $ConnectionLines
@onready var info_panel: PanelContainer = $InfoPanel
@onready var info_label: RichTextLabel = $InfoPanel/MarginContainer/InfoLabel
@onready var close_button: Button = $CloseButton

# State
var zone_markers: Dictionary = {}  # zone_id -> marker node
var hovered_zone_id: String = ""
var is_dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var camera_offset: Vector2 = Vector2.ZERO
var original_zone_id: String = ""  # Zone we were in when opening map
var viewed_zone_id: String = ""  # Zone currently being viewed (camera focus)

func _ready():
	# Hide initially
	visible = false
	
	# DEBUG: Check ZoneContainer properties
	if zone_container:
		print("GalaxyMapUI: ZoneContainer z_index = %d, mouse_filter = %d" % [zone_container.z_index, zone_container.mouse_filter])
		print("GalaxyMapUI: ZoneContainer rect: %s" % zone_container.get_rect())
	
	# Calculate galaxy center based on viewport
	await get_tree().process_frame
	galaxy_center = size / 2.0
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# Connect return button
	var return_button = get_node_or_null("ReturnButton")
	if return_button:
		return_button.pressed.connect(_on_return_to_current_pressed)
	
	# Setup galaxy shader
	if galaxy_shader_rect:
		var shader_material = ShaderMaterial.new()
		var shader = load("res://shaders/spiral_galaxy.gdshader")
		shader_material.shader = shader
		galaxy_shader_rect.material = shader_material
	
	# Hide info panel initially
	if info_panel:
		info_panel.visible = false

func _process(_delta):
	# Handle ESC key to close (M is handled by InputHandler via toggle_galaxy_map)
	if visible and Input.is_action_just_pressed("ui_cancel"):
		print("GalaxyMapUI: ESC pressed, closing map")
		close_map()

func open_map():
	"""Open the galaxy map"""
	print("GalaxyMapUI: Opening galaxy map...")
	visible = true
	
	# Store current zone for return button
	if ZoneManager:
		original_zone_id = ZoneManager.current_zone_id
		viewed_zone_id = ZoneManager.current_zone_id
	
	# Recalculate center in case viewport changed
	galaxy_center = size / 2.0
	print("GalaxyMapUI: Galaxy center set to: %s (size: %s)" % [galaxy_center, size])
	
	refresh_zone_display()
	
	# Pause game
	get_tree().paused = true
	print("GalaxyMapUI: Galaxy map opened, game paused")

func close_map():
	"""Close the galaxy map"""
	print("GalaxyMapUI: Closing galaxy map...")
	visible = false
	map_closed.emit()
	
	# Unpause game
	get_tree().paused = false
	print("GalaxyMapUI: Galaxy map closed, game unpaused")

func refresh_zone_display():
	"""Refresh all zone markers and connections"""
	if not ZoneManager:
		print("GalaxyMapUI: ERROR - ZoneManager not found!")
		return
	
	# Clear existing markers
	clear_zone_markers()
	
	# Get all discovered zones
	var discovered_zones = ZoneManager.get_discovered_zones()
	print("GalaxyMapUI: Discovered zones: %s" % discovered_zones)
	print("GalaxyMapUI: Displaying %d discovered zones" % discovered_zones.size())
	
	if discovered_zones.is_empty():
		print("GalaxyMapUI: WARNING - No discovered zones to display!")
		# Show a message to the player
		var no_zones_label = Label.new()
		no_zones_label.text = "No zones discovered yet!\nExplore and travel through wormholes to discover new zones."
		no_zones_label.position = galaxy_center - Vector2(200, 50)
		no_zones_label.custom_minimum_size = Vector2(400, 100)
		no_zones_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_zones_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		no_zones_label.add_theme_font_size_override("font_size", 18)
		no_zones_label.add_theme_color_override("font_color", Color(1, 1, 0.5))
		zone_container.add_child(no_zones_label)
		zone_markers["_no_zones_msg"] = no_zones_label
		return
	
	# Create markers for discovered zones
	for zone_id in discovered_zones:
		create_zone_marker(zone_id, false)
	
	# DEBUG: Add a test marker at center to verify marker creation works
	var test_marker = Panel.new()
	test_marker.process_mode = Node.PROCESS_MODE_ALWAYS  # Process input even when paused!
	test_marker.custom_minimum_size = Vector2(50, 50)
	test_marker.position = galaxy_center - Vector2(25, 25)
	test_marker.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var test_style = StyleBoxFlat.new()
	test_style.bg_color = Color.RED
	test_marker.add_theme_stylebox_override("panel", test_style)
	
	test_marker.mouse_entered.connect(func(): print("GalaxyMapUI: TEST MARKER HOVERED!"))
	test_marker.gui_input.connect(func(event): print("GalaxyMapUI: TEST MARKER CLICKED! Event: %s" % event.get_class()))
	
	zone_container.add_child(test_marker)
	
	# Wait a frame for layout
	await get_tree().process_frame
	
	print("GalaxyMapUI: Added test marker at center: %s" % galaxy_center)
	print("  - Test marker position: %s" % test_marker.position)
	print("  - Test marker size: %s" % test_marker.size)
	print("  - Test marker global_position: %s" % test_marker.global_position)
	print("  - Test marker visible: %s" % test_marker.visible)
	print("  - Test marker mouse_filter: %d" % test_marker.mouse_filter)
	
	# Create markers for undiscovered neighbors
	for zone_id in discovered_zones:
		var neighbors = ZoneManager.get_undiscovered_neighbors(zone_id)
		for neighbor_info in neighbors:
			# Show "???" marker for undiscovered neighbors
			if not zone_markers.has(neighbor_info.zone_id):
				# Position based on wormhole direction
				create_undiscovered_marker(zone_id, neighbor_info)
	
	# Draw connection lines
	draw_zone_connections()

func clear_zone_markers():
	"""Remove all zone markers"""
	for marker in zone_markers.values():
		if is_instance_valid(marker):
			marker.queue_free()
	zone_markers.clear()

func create_zone_marker(zone_id: String, is_undiscovered: bool = false):
	"""Create a visual marker for a zone"""
	print("GalaxyMapUI: Creating zone marker for %s" % zone_id)
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty():
		print("GalaxyMapUI: ERROR - Zone %s not found!" % zone_id)
		return
	
	# Calculate position on galaxy map
	var position = calculate_galaxy_position(zone.difficulty, zone.ring_position)
	print("GalaxyMapUI: Zone %s position: %s" % [zone_id, position])
	
	# Create marker node
	var marker = Panel.new()
	marker.process_mode = Node.PROCESS_MODE_ALWAYS  # Process input even when paused!
	marker.custom_minimum_size = Vector2(ZONE_MARKER_SIZE, ZONE_MARKER_SIZE)
	marker.position = position - Vector2(ZONE_MARKER_SIZE / 2, ZONE_MARKER_SIZE / 2)
	marker.mouse_filter = Control.MOUSE_FILTER_STOP  # Allow mouse events
	
	# Set color based on difficulty
	var style = StyleBoxFlat.new()
	style.bg_color = DIFFICULTY_COLORS[zone.difficulty - 1] if zone.difficulty <= 9 else Color.WHITE
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.WHITE
	style.corner_radius_top_left = ZONE_MARKER_SIZE / 2
	style.corner_radius_top_right = ZONE_MARKER_SIZE / 2
	style.corner_radius_bottom_left = ZONE_MARKER_SIZE / 2
	style.corner_radius_bottom_right = ZONE_MARKER_SIZE / 2
	marker.add_theme_stylebox_override("panel", style)
	
	# Add glow background for visibility
	var glow = ColorRect.new()
	glow.color = style.bg_color * 0.5
	glow.color.a = 0.3
	glow.size = Vector2(ZONE_MARKER_SIZE + 20, ZONE_MARKER_SIZE + 20)
	glow.position = Vector2(-10, -10)
	glow.z_index = -1
	marker.add_child(glow)
	
	# Add label with background for readability
	var label_bg = PanelContainer.new()
	label_bg.position = Vector2(-ZONE_MARKER_SIZE, ZONE_MARKER_SIZE + 5)
	label_bg.custom_minimum_size = Vector2(ZONE_MARKER_SIZE * 3, 25)
	
	var label_style = StyleBoxFlat.new()
	label_style.bg_color = Color(0, 0, 0, 0.7)
	label_style.border_width_left = 1
	label_style.border_width_right = 1
	label_style.border_width_top = 1
	label_style.border_width_bottom = 1
	label_style.border_color = style.bg_color
	label_bg.add_theme_stylebox_override("panel", label_style)
	
	var label = Label.new()
	label.text = zone.procedural_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label_bg.add_child(label)
	marker.add_child(label_bg)
	
	# Add current zone indicator (yellow pulse)
	if zone_id == ZoneManager.current_zone_id:
		var indicator = ColorRect.new()
		indicator.color = Color(1, 1, 0, 0.6)  # Yellow with transparency
		indicator.size = Vector2(ZONE_MARKER_SIZE + 15, ZONE_MARKER_SIZE + 15)
		indicator.position = Vector2(-7.5, -7.5)
		indicator.z_index = -2
		marker.add_child(indicator)
		
		# Add pulsing effect indicator
		var pulse_indicator = ColorRect.new()
		pulse_indicator.color = Color(1, 1, 0, 0.3)
		pulse_indicator.size = Vector2(ZONE_MARKER_SIZE + 25, ZONE_MARKER_SIZE + 25)
		pulse_indicator.position = Vector2(-12.5, -12.5)
		pulse_indicator.z_index = -3
		marker.add_child(pulse_indicator)
	
	# Add viewed zone indicator (cyan border) - different from current zone
	elif zone_id == viewed_zone_id:
		var indicator = ColorRect.new()
		indicator.color = Color(0, 1, 1, 0.5)  # Cyan with transparency
		indicator.size = Vector2(ZONE_MARKER_SIZE + 12, ZONE_MARKER_SIZE + 12)
		indicator.position = Vector2(-6, -6)
		indicator.z_index = -2
		marker.add_child(indicator)
	
	# Make clickable
	marker.mouse_entered.connect(_on_zone_marker_hovered.bind(zone_id))
	marker.mouse_exited.connect(_on_zone_marker_unhovered)
	marker.gui_input.connect(_on_zone_marker_input.bind(zone_id))
	
	zone_container.add_child(marker)
	zone_markers[zone_id] = marker
	
	# Wait a frame for layout
	await get_tree().process_frame
	
	print("GalaxyMapUI: Zone marker %s created and added to container" % zone_id)
	print("  - Marker position: %s" % marker.position)
	print("  - Marker size: %s" % marker.size)
	print("  - Marker custom_minimum_size: %s" % marker.custom_minimum_size)
	print("  - Marker global_position: %s" % marker.global_position)
	print("  - Marker get_rect(): %s" % marker.get_rect())
	print("  - Marker visible: %s" % marker.visible)
	print("  - Marker mouse_filter: %d" % marker.mouse_filter)

func create_undiscovered_marker(source_zone_id: String, neighbor_info: Dictionary):
	"""Create a '???' marker for undiscovered neighboring zone"""
	var source_zone = ZoneManager.get_zone(source_zone_id)
	if source_zone.is_empty():
		return
	
	# Get wormhole to determine direction
	var wormhole = neighbor_info.get("wormhole")
	if not wormhole or not is_instance_valid(wormhole):
		return
	
	var direction = wormhole.wormhole_direction
	var neighbor_type = neighbor_info.get("type", "lateral")
	
	# Calculate estimated position
	var position: Vector2
	if neighbor_type == "lateral":
		# Same difficulty, different ring position
		position = calculate_galaxy_position(source_zone.difficulty, fmod(source_zone.ring_position + direction, TAU))
	else:
		# Different difficulty
		var target_difficulty = source_zone.difficulty + (1 if direction == 0.0 else -1)
		position = calculate_galaxy_position(target_difficulty, source_zone.ring_position)
	
	# Create simple marker
	var marker = Panel.new()
	marker.custom_minimum_size = Vector2(UNDISCOVERED_MARKER_SIZE, UNDISCOVERED_MARKER_SIZE)
	marker.position = position - Vector2(UNDISCOVERED_MARKER_SIZE / 2, UNDISCOVERED_MARKER_SIZE / 2)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.3, 0.3, 0.5)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color.GRAY
	marker.add_theme_stylebox_override("panel", style)
	
	# Add "???" label
	var label = Label.new()
	label.text = "???"
	label.position = Vector2(0, UNDISCOVERED_MARKER_SIZE + 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	marker.add_child(label)
	
	zone_container.add_child(marker)

func calculate_galaxy_position(difficulty: int, ring_position: float) -> Vector2:
	"""Calculate screen position for a zone based on difficulty and ring position"""
	# Spiral calculation - creates a logarithmic spiral effect
	var angle = (difficulty * PI / 2.0) + ring_position
	
	# Increase radius significantly for better visibility
	# Outer zones (difficulty 1) are far from center, inner zones (difficulty 9) are close
	var base_radius = min(galaxy_center.x, galaxy_center.y) * 0.7  # Use 70% of smaller dimension
	var radius = base_radius * (10.0 - difficulty) / 9.0
	
	var x = galaxy_center.x + cos(angle) * radius
	var y = galaxy_center.y + sin(angle) * radius
	
	print("GalaxyMapUI: Position calc - difficulty=%d, ring_pos=%.2f, galaxy_center=%s, radius=%.1f, final_pos=%s" % [difficulty, ring_position, galaxy_center, radius, Vector2(x, y)])
	
	return Vector2(x, y)

func draw_zone_connections():
	"""Draw lines connecting zones via wormholes"""
	if not connection_lines:
		return
	
	# Clear existing lines
	for child in connection_lines.get_children():
		child.queue_free()
	
	# Draw connections between discovered zones
	for zone_id in ZoneManager.get_discovered_zones():
		var zone = ZoneManager.get_zone(zone_id)
		if zone.is_empty():
			continue
		
		var source_pos = calculate_galaxy_position(zone.difficulty, zone.ring_position)
		
		# Draw lateral connections
		for wormhole in zone.lateral_wormholes:
			if is_instance_valid(wormhole) and not wormhole.is_undiscovered:
				var target_zone = ZoneManager.get_zone(wormhole.target_zone_id)
				if not target_zone.is_empty() and ZoneManager.is_zone_discovered(wormhole.target_zone_id):
					var target_pos = calculate_galaxy_position(target_zone.difficulty, target_zone.ring_position)
					draw_connection_line(source_pos, target_pos, Color(0.3, 0.8, 0.8, 0.5))
		
		# Draw depth connections
		for wormhole in zone.depth_wormholes:
			if is_instance_valid(wormhole) and not wormhole.is_undiscovered:
				var target_zone = ZoneManager.get_zone(wormhole.target_zone_id)
				if not target_zone.is_empty() and ZoneManager.is_zone_discovered(wormhole.target_zone_id):
					var target_pos = calculate_galaxy_position(target_zone.difficulty, target_zone.ring_position)
					draw_connection_line(source_pos, target_pos, Color(0.6, 0.3, 1.0, 0.5))

func draw_connection_line(from: Vector2, to: Vector2, color: Color):
	"""Draw a line between two points"""
	var line = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.default_color = color
	line.width = 2.0
	line.z_index = -1
	connection_lines.add_child(line)

func _on_zone_marker_hovered(zone_id: String):
	"""Handle zone marker hover"""
	print("GalaxyMapUI: Zone marker hovered - %s" % zone_id)
	hovered_zone_id = zone_id
	show_zone_info(zone_id)

func _on_zone_marker_unhovered():
	"""Handle zone marker unhover"""
	hovered_zone_id = ""
	if info_panel:
		info_panel.visible = false

func _on_zone_marker_input(event: InputEvent, zone_id: String):
	"""Handle zone marker click"""
	print("GalaxyMapUI: Zone marker input received - %s, event type: %s" % [zone_id, event.get_class()])
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("GalaxyMapUI: Zone marker clicked - %s" % zone_id)
		zone_clicked.emit(zone_id)
		switch_camera_to_zone(zone_id)
		show_detailed_zone_info(zone_id)

func show_zone_info(zone_id: String):
	"""Show basic zone info on hover"""
	if not info_panel or not ZoneManager:
		return
	
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty():
		return
	
	var stats = ZoneManager.get_zone_statistics(zone_id)
	var presence = ZoneManager.get_player_presence_in_zone(zone_id)
	
	var info_text = "[b]%s[/b]\n" % zone.procedural_name
	info_text += "Difficulty: %d/9\n" % zone.difficulty
	info_text += "Resources: Tier 0-%d\n\n" % (zone.difficulty - 1)
	
	# Show unit counts and breakdown
	if EntityManager:
		var zone_units = EntityManager.get_units_in_zone(zone_id)
		var player_units = []
		for unit in zone_units:
			if is_instance_valid(unit) and unit.team_id == 0:
				player_units.append(unit)
		
		if player_units.size() > 0:
			# Count unit types
			var scouts = 0
			var miners = 0
			var combat = 0
			var custom_ships = 0
			var builders = 0
			
			for unit in player_units:
				var unit_type = unit.get_class()
				if "ScoutDrone" in unit_type:
					scouts += 1
				elif "MiningDrone" in unit_type:
					miners += 1
				elif "CombatDrone" in unit_type:
					combat += 1
				elif "BuilderDrone" in unit_type:
					builders += 1
				elif "CustomShip" in unit_type:
					custom_ships += 1
			
			info_text += "[color=green]Units: %d[/color]\n" % player_units.size()
			if scouts > 0:
				info_text += "  • %d Scout%s\n" % [scouts, "s" if scouts > 1 else ""]
			if miners > 0:
				info_text += "  • %d Mining%s\n" % [miners, "" if miners == 1 else ""]
			if combat > 0:
				info_text += "  • %d Combat%s\n" % [combat, "" if combat == 1 else ""]
			if builders > 0:
				info_text += "  • %d Builder%s\n" % [builders, "s" if builders > 1 else ""]
			if custom_ships > 0:
				info_text += "  • %d Custom Ship%s\n" % [custom_ships, "s" if custom_ships > 1 else ""]
		else:
			info_text += "[color=gray]No Units[/color]\n"
	
	if presence.has_buildings:
		info_text += "[color=green]✓ Buildings Present[/color]\n"
	
	info_text += "\n"
	
	if zone_id == ZoneManager.current_zone_id:
		info_text += "[color=yellow]◄ Current Location[/color]\n"
	
	if zone_id == viewed_zone_id and zone_id != ZoneManager.current_zone_id:
		info_text += "[color=cyan]◄ Viewing[/color]\n"
	
	info_text += "\n[color=gray]Click to view zone[/color]"
	
	info_label.text = info_text
	info_panel.visible = true

func show_detailed_zone_info(zone_id: String):
	"""Show detailed zone info panel (future: separate panel)"""
	# For now, just use the hover info
	show_zone_info(zone_id)

func switch_camera_to_zone(zone_id: String):
	"""Switch camera view to a different zone while map is open"""
	if not ZoneManager:
		return
	
	var zone = ZoneManager.get_zone(zone_id)
	if zone.is_empty():
		return
	
	print("GalaxyMapUI: Switching camera to zone '%s'" % zone_id)
	
	# Switch to the zone
	ZoneManager.switch_to_zone(zone_id)
	viewed_zone_id = zone_id
	
	# Get camera and focus on zone center
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("focus_on_position"):
		# Focus on zone center (0,0 in zone coordinates)
		camera.focus_on_position(Vector2.ZERO, 0.3)
	
	# Update zone markers to show which is being viewed
	refresh_zone_display()

func return_to_current_zone():
	"""Return camera to the original current zone"""
	if original_zone_id.is_empty() or not ZoneManager:
		return
	
	print("GalaxyMapUI: Returning to current zone '%s'" % original_zone_id)
	switch_camera_to_zone(original_zone_id)

func _on_return_to_current_pressed():
	"""Handle return to current zone button click"""
	return_to_current_zone()

func _on_close_button_pressed():
	"""Handle close button click"""
	close_map()
