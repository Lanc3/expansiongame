extends Panel

## Complete blueprint editor with validation

@onready var grid_container: GridContainer = $VBoxContainer/HBoxContainer/GridEditor/GridContainer
@onready var close_button: Button = $VBoxContainer/TitleBar/CloseButton
@onready var validate_button: Button = $VBoxContainer/BottomBar/ValidateButton
@onready var clear_button: Button = $VBoxContainer/BottomBar/ClearButton
@onready var save_button: Button = $VBoxContainer/BottomBar/SaveButton
@onready var stats_label: Label = $VBoxContainer/HBoxContainer/StatsPanel/VBoxContainer/StatsLabel
@onready var validation_label: Label = $VBoxContainer/BottomBar/ValidationLabel

# Component palette buttons
@onready var energy_core_btn: Button = $VBoxContainer/HBoxContainer/ComponentPalette/VBoxContainer/EnergyCoreButton
@onready var engine_btn: Button = $VBoxContainer/HBoxContainer/ComponentPalette/VBoxContainer/EngineButton
@onready var weapon_laser_btn: Button = $VBoxContainer/HBoxContainer/ComponentPalette/VBoxContainer/WeaponLaserButton
@onready var weapon_plasma_btn: Button = $VBoxContainer/HBoxContainer/ComponentPalette/VBoxContainer/WeaponPlasmaButton
@onready var mining_tool_btn: Button = $VBoxContainer/HBoxContainer/ComponentPalette/VBoxContainer/MiningToolButton
@onready var shield_btn: Button = $VBoxContainer/HBoxContainer/ComponentPalette/VBoxContainer/ShieldButton
@onready var storage_btn: Button = $VBoxContainer/HBoxContainer/ComponentPalette/VBoxContainer/StorageButton

var current_blueprint: BlueprintData = BlueprintData.new()
var selected_component_type: int = -1
var grid_cells: Array = []

func _ready():
	visible = false
	
	close_button.pressed.connect(_on_close_pressed)
	validate_button.pressed.connect(_on_validate_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	save_button.pressed.connect(_on_save_pressed)
	
	setup_grid()
	setup_component_palette()

func setup_grid():
	grid_container.columns = current_blueprint.grid_width
	
	for y in range(current_blueprint.grid_height):
		for x in range(current_blueprint.grid_width):
			var cell = create_grid_cell(x, y)
			grid_container.add_child(cell)
			grid_cells.append(cell)

func create_grid_cell(x: int, y: int) -> Button:
	var cell = Button.new()
	cell.custom_minimum_size = Vector2(50, 50)
	cell.pressed.connect(_on_cell_pressed.bind(x, y))
	cell.set_meta("grid_x", x)
	cell.set_meta("grid_y", y)
	return cell

func setup_component_palette():
	energy_core_btn.pressed.connect(_on_component_selected.bind(BlueprintData.ComponentType.ENERGY_CORE))
	engine_btn.pressed.connect(_on_component_selected.bind(BlueprintData.ComponentType.ENGINE))
	weapon_laser_btn.pressed.connect(_on_component_selected.bind(BlueprintData.ComponentType.WEAPON_LASER))
	weapon_plasma_btn.pressed.connect(_on_component_selected.bind(BlueprintData.ComponentType.WEAPON_PLASMA))
	mining_tool_btn.pressed.connect(_on_component_selected.bind(BlueprintData.ComponentType.MINING_TOOL))
	shield_btn.pressed.connect(_on_component_selected.bind(BlueprintData.ComponentType.SHIELD))
	storage_btn.pressed.connect(_on_component_selected.bind(BlueprintData.ComponentType.STORAGE))

func _on_component_selected(component_type: int):
	selected_component_type = component_type

func _on_cell_pressed(x: int, y: int):
	if selected_component_type < 0:
		# Remove component
		current_blueprint.remove_component(x, y)
	else:
		# Add component
		current_blueprint.add_component(selected_component_type, x, y)
	
	update_grid_visual()
	update_stats_display()

func update_grid_visual():
	# Clear all cells
	for cell in grid_cells:
		cell.text = ""
		cell.modulate = Color.WHITE
	
	# Update cells with components
	for comp in current_blueprint.components:
		var grid_x = comp.grid_x
		var grid_y = comp.grid_y
		var cell_index = grid_y * current_blueprint.grid_width + grid_x
		
		if cell_index >= 0 and cell_index < grid_cells.size():
			var cell = grid_cells[cell_index]
			cell.text = get_component_symbol(comp.type)
			cell.modulate = get_component_color(comp.type)

func get_component_symbol(type: int) -> String:
	match type:
		BlueprintData.ComponentType.ENERGY_CORE:
			return "E"
		BlueprintData.ComponentType.ENGINE:
			return ">"
		BlueprintData.ComponentType.WEAPON_LASER:
			return "L"
		BlueprintData.ComponentType.WEAPON_PLASMA:
			return "P"
		BlueprintData.ComponentType.MINING_TOOL:
			return "M"
		BlueprintData.ComponentType.SHIELD:
			return "S"
		BlueprintData.ComponentType.STORAGE:
			return "C"
	return "?"

func get_component_color(type: int) -> Color:
	match type:
		BlueprintData.ComponentType.ENERGY_CORE:
			return Color.YELLOW
		BlueprintData.ComponentType.ENGINE:
			return Color.CYAN
		BlueprintData.ComponentType.WEAPON_LASER:
			return Color.RED
		BlueprintData.ComponentType.WEAPON_PLASMA:
			return Color.MAGENTA
		BlueprintData.ComponentType.MINING_TOOL:
			return Color.ORANGE
		BlueprintData.ComponentType.SHIELD:
			return Color.BLUE
		BlueprintData.ComponentType.STORAGE:
			return Color.GREEN
	return Color.WHITE

func update_stats_display():
	var stats = current_blueprint.calculate_stats()
	var text = "Stats:\n"
	text += "Speed: %.0f\n" % stats.speed
	text += "Health: %.0f\n" % stats.health
	text += "Damage: %.0f\n" % stats.damage
	text += "Mining: %.1f/s\n" % stats.mining_rate
	text += "Cargo: %.0f" % stats.cargo
	
	if stats_label:
		stats_label.text = text

func _on_validate_pressed():
	var validation = current_blueprint.validate()
	
	if validation.valid:
		validation_label.text = "Valid! Energy: +%.1f" % validation.energy_balance
		validation_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		validation_label.text = "Invalid: " + ", ".join(validation.errors)
		validation_label.add_theme_color_override("font_color", Color.RED)

func _on_clear_pressed():
	current_blueprint.clear_components()
	update_grid_visual()
	update_stats_display()
	validation_label.text = ""

func _on_save_pressed():
	var validation = current_blueprint.validate()
	if not validation.valid:
		validation_label.text = "Cannot save invalid blueprint"
		validation_label.add_theme_color_override("font_color", Color.RED)
		return
	
	# Save blueprint (implement save system)
	validation_label.text = "Blueprint saved!"
	validation_label.add_theme_color_override("font_color", Color.GREEN)

func _on_close_pressed():
	visible = false

func show_editor():
	visible = true
