extends PanelContainer
## Represents a single selected unit in the UI with detailed stats

# Header
@onready var name_label: Label = $VBoxContainer/HeaderSection/NameLabel
@onready var icon_sprite: TextureRect = $VBoxContainer/HeaderSection/IconSprite

# Health
@onready var health_bar: ProgressBar = $VBoxContainer/HealthSection/HealthBar
@onready var health_label: Label = $VBoxContainer/HealthSection/HealthLabel

# Stats
@onready var stats_container: VBoxContainer = $VBoxContainer/StatsSection
@onready var speed_label: Label = $VBoxContainer/StatsSection/SpeedLabel
@onready var damage_label: Label = $VBoxContainer/StatsSection/DamageLabel

# Cargo (mining drones only)
@onready var cargo_container: VBoxContainer = $VBoxContainer/CargoSection
@onready var cargo_label: Label = $VBoxContainer/CargoSection/CargoLabel
@onready var cargo_total_bar: ProgressBar = $VBoxContainer/CargoSection/CargoTotalBar
@onready var cargo_common_bar: ProgressBar = $VBoxContainer/CargoSection/CargoBreakdown/CommonBar
@onready var cargo_rare_bar: ProgressBar = $VBoxContainer/CargoSection/CargoBreakdown/RareBar
@onready var cargo_exotic_bar: ProgressBar = $VBoxContainer/CargoSection/CargoBreakdown/ExoticBar

var linked_unit: BaseUnit = null

func _ready():
	custom_minimum_size = Vector2(120, 160)

func setup_for_unit(unit: BaseUnit):
	if not is_instance_valid(unit):
		push_error("UnitIcon: Invalid unit passed to setup_for_unit")
		return
	
	linked_unit = unit
	
	# Set unit name
	if name_label:
		name_label.text = unit.unit_name if "unit_name" in unit else "Unit"
	
	# Set health bar
	if health_bar:
		health_bar.max_value = unit.max_health
		health_bar.value = unit.current_health
		
		# Style health bar
		var health_style = StyleBoxFlat.new()
		health_style.bg_color = Color(0.8, 0.2, 0.2)  # Red for health
		health_bar.add_theme_stylebox_override("fill", health_style)
	
	# Set health label
	update_health_display()
	
	# Set icon sprite based on unit type - matching actual in-game sprites
	if icon_sprite:
		var sprite_path = ""
		
		# Select sprite based on unit type (match the actual unit scene sprites)
		if "is_command_ship" in unit and unit.is_command_ship:
			sprite_path = "res://assets/sprites/ufoRed.png"
		elif unit is MiningDrone:
			sprite_path = "res://assets/sprites/UI/cursor.png"
		elif unit is CombatDrone:
			sprite_path = "res://assets/sprites/playerShip1_blue.png"
		elif unit is ScoutDrone:
			sprite_path = "res://assets/sprites/playerShip2_green.png"
		else:
			sprite_path = "res://assets/sprites/playerShip3_red.png"  # Default (BaseUnit)
		
		# Load and set the texture
		if ResourceLoader.exists(sprite_path):
			icon_sprite.texture = load(sprite_path)
			icon_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		else:
			push_warning("UnitIcon: Sprite not found: " + sprite_path)
	
	# Setup stats
	setup_stats_display()
	
	# Setup cargo display for mining drones
	if unit is MiningDrone:
		setup_cargo_display()
	else:
		# Hide cargo section for non-mining units
		if cargo_container:
			cargo_container.visible = false
	
	# Connect to unit signals
	if not unit.health_changed.is_connected(_on_unit_health_changed):
		unit.health_changed.connect(_on_unit_health_changed)
	
	if not unit.died.is_connected(_on_unit_died):
		unit.died.connect(_on_unit_died)

func _on_unit_health_changed(new_health: float):
	if health_bar:
		health_bar.value = new_health

func _on_unit_died():
	queue_free()

func setup_stats_display():
	if not is_instance_valid(linked_unit):
		return
	
	# Movement speed
	if speed_label:
		speed_label.text = "Speed: %.0f" % linked_unit.move_speed
	
	# Damage (combat units only)
	if damage_label:
		if linked_unit.can_attack():
			var weapon = linked_unit.get_node_or_null("WeaponComponent")
			if weapon and "damage" in weapon:
				damage_label.text = "Damage: %.0f" % weapon.damage
			else:
				damage_label.text = "Damage: N/A"
		else:
			damage_label.text = "Damage: -"

func setup_cargo_display():
	if not cargo_container:
		return
	
	cargo_container.visible = true
	
	var miner = linked_unit as MiningDrone
	if not miner:
		return
	
	# Setup cargo bars
	if cargo_total_bar:
		cargo_total_bar.max_value = miner.max_cargo
		cargo_total_bar.value = 0
		
		# Style total cargo bar
		var cargo_style = StyleBoxFlat.new()
		cargo_style.bg_color = Color(0.2, 0.6, 1.0)  # Blue for cargo
		cargo_total_bar.add_theme_stylebox_override("fill", cargo_style)
	
	# Setup breakdown bars
	if cargo_common_bar:
		cargo_common_bar.max_value = miner.max_cargo
		cargo_common_bar.value = 0
		var common_style = StyleBoxFlat.new()
		common_style.bg_color = Color(0.6, 0.6, 0.6)  # Gray for common
		cargo_common_bar.add_theme_stylebox_override("fill", common_style)
	
	if cargo_rare_bar:
		cargo_rare_bar.max_value = miner.max_cargo
		cargo_rare_bar.value = 0
		var rare_style = StyleBoxFlat.new()
		rare_style.bg_color = Color(0.3, 0.8, 1.0)  # Cyan for rare
		cargo_rare_bar.add_theme_stylebox_override("fill", rare_style)
	
	if cargo_exotic_bar:
		cargo_exotic_bar.max_value = miner.max_cargo
		cargo_exotic_bar.value = 0
		var exotic_style = StyleBoxFlat.new()
		exotic_style.bg_color = Color(0.8, 0.2, 1.0)  # Magenta for exotic
		cargo_exotic_bar.add_theme_stylebox_override("fill", exotic_style)

func update_health_display():
	if not is_instance_valid(linked_unit):
		return
	
	if health_bar:
		health_bar.value = linked_unit.current_health
	
	if health_label:
		health_label.text = "HP: %d/%d" % [int(linked_unit.current_health), int(linked_unit.max_health)]

func update_cargo_display():
	if not is_instance_valid(linked_unit):
		return
	
	var miner = linked_unit as MiningDrone
	if not miner:
		return
	
	# Update total cargo
	if cargo_total_bar:
		cargo_total_bar.value = miner.carrying_resources
	
	if cargo_label:
		cargo_label.text = "Cargo: %d/%d" % [int(miner.carrying_resources), int(miner.max_cargo)]
	
	# Update breakdown with new cargo_by_type system
	# Group by rarity tiers for display: Common (0-2), Uncommon (3-5), Rare (6-9)
	var tier_0_2_total = 0.0  # Common
	var tier_3_5_total = 0.0  # Uncommon (shown as "rare")
	var tier_6_9_total = 0.0  # Rare+ (shown as "exotic")
	
	for type_id in miner.cargo_by_type.keys():
		var amount = miner.cargo_by_type[type_id]
		var tier = ResourceDatabase.get_resource_tier(type_id)
		
		if tier <= 2:
			tier_0_2_total += amount
		elif tier <= 5:
			tier_3_5_total += amount
		else:
			tier_6_9_total += amount
	
	if cargo_common_bar:
		cargo_common_bar.value = tier_0_2_total
	
	if cargo_rare_bar:
		cargo_rare_bar.value = tier_3_5_total
	
	if cargo_exotic_bar:
		cargo_exotic_bar.value = tier_6_9_total

func _process(_delta: float):
	if not is_instance_valid(linked_unit):
		return
	
	# Update health display
	update_health_display()
	
	# Update cargo if it's a mining drone
	if linked_unit is MiningDrone:
		update_cargo_display()
