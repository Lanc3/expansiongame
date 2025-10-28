extends Control
## UI for switching between zones

@onready var zone_label: Label = $Panel/VBoxContainer/ZoneLabel
@onready var prev_button: Button = $Panel/VBoxContainer/HBoxContainer/PrevButton
@onready var next_button: Button = $Panel/VBoxContainer/HBoxContainer/NextButton
@onready var unit_indicators: HBoxContainer = $Panel/VBoxContainer/UnitIndicators

var current_zone_id: String = ""

func _ready():
	# Connect to ZoneManager signals
	if ZoneManager:
		ZoneManager.zone_switched.connect(_on_zone_switched)
		current_zone_id = ZoneManager.current_zone_id
	
	# Connect button signals
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	
	# Initialize UI
	update_ui()

func _on_zone_switched(from_zone_id: String, to_zone_id: String):
	"""Handle zone switch"""
	current_zone_id = to_zone_id
	update_ui()

func _on_prev_pressed():
	"""Switch to previous zone - TODO: Redesign for multi-zone system"""
	# For now, disable since we have multiple zones per difficulty
	pass

func _on_next_pressed():
	"""Switch to next zone - TODO: Redesign for multi-zone system"""
	# For now, disable since we have multiple zones per difficulty
	pass

func update_ui():
	"""Update UI elements"""
	# Update zone label
	if zone_label and ZoneManager:
		var zone = ZoneManager.get_zone(current_zone_id)
		if not zone.is_empty():
			zone_label.text = "%s (D%d)" % [zone.procedural_name, zone.difficulty]
	
	# Disable buttons for now - TODO: Implement zone list navigation
	if prev_button:
		prev_button.disabled = true
	
	if next_button:
		next_button.disabled = true
	
	# Update unit indicators
	update_unit_indicators()

func update_unit_indicators():
	"""Show which zones have player units"""
	if not unit_indicators or not ZoneManager:
		return
	
	# Clear existing indicators
	for child in unit_indicators.get_children():
		child.queue_free()
	
	# Create indicators for each discovered zone (sorted by difficulty)
	var discovered_zones = ZoneManager.get_discovered_zones()
	
	# Sort by difficulty
	var sorted_zones = discovered_zones.duplicate()
	sorted_zones.sort_custom(func(a, b):
		var zone_a = ZoneManager.get_zone(a)
		var zone_b = ZoneManager.get_zone(b)
		return zone_a.difficulty < zone_b.difficulty
	)
	
	for zone_id in sorted_zones:
		var indicator = Panel.new()
		indicator.custom_minimum_size = Vector2(8, 8)
		
		# Check if zone has player units
		var has_units = false
		if EntityManager:
			var units = EntityManager.get_units_in_zone(zone_id)
			for unit in units:
				if is_instance_valid(unit) and unit.team_id == 0:  # Player team
					has_units = true
					break
		
		# Color code: green if has units, gray if empty, white if current
		var style = StyleBoxFlat.new()
		if zone_id == current_zone_id:
			style.bg_color = Color.WHITE
		elif has_units:
			style.bg_color = Color.GREEN
		else:
			style.bg_color = Color(0.3, 0.3, 0.3)
		
		indicator.add_theme_stylebox_override("panel", style)
		unit_indicators.add_child(indicator)

func _process(_delta: float):
	"""Update indicators periodically"""
	if Engine.get_frames_drawn() % 60 == 0:  # Update every 60 frames (~1 second)
		update_unit_indicators()

