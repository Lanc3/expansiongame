extends PanelContainer
## Compact 32x32 unit icon for large selections with object pooling support

@onready var icon_sprite: TextureRect = $VBox/IconSprite
@onready var health_bar: ProgressBar = $VBox/HealthBar

var linked_unit: BaseUnit = null
var update_counter: float = 0.0
var update_interval: float = 0.05  # 20 FPS updates
var tooltip_update_counter: float = 0.0
var is_hovered: bool = false
var original_modulate: Color = Color.WHITE

func _ready():
	custom_minimum_size = Vector2(32, 32)
	tooltip_text = ""
	original_modulate = modulate
	
	# Connect mouse signals for hover effect
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup_for_unit(unit: BaseUnit):
	if not is_instance_valid(unit):
		return
	
	linked_unit = unit
	
	# Set sprite based on unit type
	if icon_sprite:
		var sprite_path = get_unit_sprite_path(unit)
		if ResourceLoader.exists(sprite_path):
			icon_sprite.texture = load(sprite_path)
			icon_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Setup health bar
	if health_bar:
		health_bar.max_value = unit.max_health
		health_bar.value = unit.current_health
	
	# Setup tooltip
	update_tooltip()
	
	# Connect to health changes
	if not unit.health_changed.is_connected(_on_unit_health_changed):
		unit.health_changed.connect(_on_unit_health_changed)
	
	if not unit.died.is_connected(_on_unit_died):
		unit.died.connect(_on_unit_died)

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

func update_tooltip():
	if not is_instance_valid(linked_unit):
		tooltip_text = ""
		return
	
	var tip = "%s\nHP: %d/%d" % [
		linked_unit.unit_name,
		int(linked_unit.current_health),
		int(linked_unit.max_health)
	]
	
	# Add AI state
	var state_name = get_state_name(linked_unit.ai_state)
	tip += "\nState: %s" % state_name
	
	# Add cargo for mining drones
	if linked_unit is MiningDrone:
		var miner = linked_unit as MiningDrone
		tip += "\nCargo: %d/%d" % [int(miner.carrying_resources), int(miner.max_cargo)]
	
	# Add current command info
	if linked_unit.command_queue.size() > 0:
		var cmd_count = linked_unit.command_queue.size()
		var current_cmd = linked_unit.command_queue[0]
		var cmd_name = get_command_name(current_cmd.type)
		if cmd_count > 1:
			tip += "\nCommand: %s (+%d queued)" % [cmd_name, cmd_count - 1]
		else:
			tip += "\nCommand: %s" % cmd_name
	
	tooltip_text = tip

func get_state_name(state: int) -> String:
	match state:
		0: return "Idle"
		1: return "Moving"
		2: return "Gathering"
		3: return "Returning"
		4: return "Combat"
		5: return "Fleeing"
		6: return "Hold Position"
		_: return "Unknown"

func get_command_name(cmd_type: int) -> String:
	match cmd_type:
		0: return "None"
		1: return "Move"
		2: return "Attack"
		3: return "Mine"
		4: return "Return Cargo"
		5: return "Hold Position"
		6: return "Patrol"
		7: return "Scan"
		_: return "Unknown"

func _process(delta: float):
	if not is_instance_valid(linked_unit):
		return
	
	# Throttled updates (20 FPS)
	update_counter += delta
	if update_counter >= update_interval:
		update_counter = 0.0
		update_display()
	
	# Update tooltip periodically when hovered
	if is_hovered:
		tooltip_update_counter += delta
		if tooltip_update_counter >= 0.5:  # Update tooltip every 0.5s
			tooltip_update_counter = 0.0
			update_tooltip()

func update_display():
	if not is_instance_valid(linked_unit):
		return
	
	if health_bar:
		health_bar.value = linked_unit.current_health

func _on_unit_health_changed(new_health: float):
	if health_bar:
		health_bar.value = new_health

func _on_unit_died():
	queue_free()

func reset():
	"""Reset icon for object pool reuse"""
	linked_unit = null
	tooltip_text = ""
	visible = true
	is_hovered = false
	modulate = original_modulate
	if health_bar:
		health_bar.value = 100

func _on_mouse_entered():
	is_hovered = true
	# Brighten on hover
	modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_mouse_exited():
	is_hovered = false
	tooltip_update_counter = 0.0
	# Reset to original
	modulate = original_modulate

