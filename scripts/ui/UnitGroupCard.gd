extends PanelContainer
## Displays a group of units of the same type with aggregate stats

signal group_clicked(unit_type: String)
signal group_expanded(unit_type: String)

@onready var header_box: HBoxContainer = $VBox/Header
@onready var unit_icon: TextureRect = $VBox/Header/Icon
@onready var unit_label: Label = $VBox/Header/Label
@onready var count_label: Label = $VBox/Header/Count
@onready var health_bar: ProgressBar = $VBox/HealthBar
@onready var stats_label: Label = $VBox/StatsLabel
@onready var expand_button: Button = $VBox/ExpandButton

var unit_type_name: String = ""
var units: Array = []

func _ready():
	if expand_button:
		expand_button.pressed.connect(_on_expand_pressed)
	
	# Make header clickable
	if header_box:
		header_box.gui_input.connect(_on_header_clicked)

func setup_group(type_name: String, unit_list: Array):
	unit_type_name = type_name
	units = unit_list
	
	if units.is_empty():
		return
	
	# Get first unit as template
	var template_unit = units[0]
	
	# Set icon
	if unit_icon and is_instance_valid(template_unit):
		var sprite_path = get_unit_sprite_path(template_unit)
		if ResourceLoader.exists(sprite_path):
			unit_icon.texture = load(sprite_path)
	
	# Set labels
	if unit_label:
		unit_label.text = type_name
	
	if count_label:
		count_label.text = "x%d" % units.size()
	
	# Calculate aggregate health
	update_aggregate_stats()
	
	# Setup expand button
	if expand_button:
		expand_button.text = "Show all (%d)" % units.size()

func update_aggregate_stats():
	if units.is_empty():
		return
	
	var total_health = 0.0
	var max_total_health = 0.0
	var total_cargo = 0.0
	var max_cargo = 0.0
	var has_cargo = false
	
	for unit in units:
		if not is_instance_valid(unit):
			continue
		
		total_health += unit.current_health
		max_total_health += unit.max_health
		
		# Check for cargo (mining drones)
		if unit is MiningDrone:
			has_cargo = true
			var miner = unit as MiningDrone
			total_cargo += miner.carrying_resources
			max_cargo += miner.max_cargo
	
	# Update health bar
	if health_bar:
		health_bar.max_value = 100
		var health_percent = (total_health / max_total_health * 100) if max_total_health > 0 else 0
		health_bar.value = health_percent
	
	# Update stats label
	if stats_label:
		var stats_text = "HP: %.0f%%" % ((total_health / max_total_health * 100) if max_total_health > 0 else 0)
		
		if has_cargo and max_cargo > 0:
			var cargo_percent = (total_cargo / max_cargo * 100)
			stats_text += " | Cargo: %.0f%%" % cargo_percent
		
		stats_label.text = stats_text

func get_unit_sprite_path(unit: BaseUnit) -> String:
	if "is_command_ship" in unit and unit.is_command_ship:
		return "res://assets/sprites/ufoRed.png"
	elif unit is MiningDrone:
		return "res://assets/sprites/UI/cursor.png"
	elif unit is CombatDrone:
		return "res://assets/sprites/playerShip1_blue.png"
	elif unit is ScoutDrone:
		return "res://assets/sprites/playerShip2_green.png"
	else:
		return "res://assets/sprites/playerShip3_red.png"

func _on_expand_pressed():
	group_expanded.emit(unit_type_name)

func _on_header_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		group_clicked.emit(unit_type_name)

func _process(_delta: float):
	# Periodic stat updates (not every frame)
	pass

