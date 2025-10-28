extends PanelContainer
class_name CosmoteerBlueprintLibrary

signal blueprint_selected(blueprint: CosmoteerShipBlueprint)
signal cancelled()

@onready var blueprint_list: VBoxContainer = $VBox/BlueprintScroll/BlueprintList
@onready var cancel_btn: Button = $VBox/CancelBtn

func _ready():
	cancel_btn.pressed.connect(_on_cancel_pressed)
	populate_list()

func populate_list():
	# Load all blueprint files using centralized path system
	print("CosmoteerBlueprintLibrary: populate_list() called")
	var blueprint_files = BlueprintPaths.get_all_blueprint_files()
	print("CosmoteerBlueprintLibrary: Found ", blueprint_files.size(), " blueprint files")
	
	if blueprint_files.is_empty():
		print("CosmoteerBlueprintLibrary: No files found, showing message")
		_show_no_blueprints_message()
		return
	
	# Load blueprints
	var blueprints: Array[CosmoteerShipBlueprint] = []
	for file_path in blueprint_files:
		print("CosmoteerBlueprintLibrary: Loading blueprint from: ", file_path)
		var blueprint = BlueprintPaths.load_blueprint(file_path)
		if blueprint:
			print("CosmoteerBlueprintLibrary: Successfully loaded: ", blueprint.blueprint_name)
			blueprints.append(blueprint)
		else:
			print("CosmoteerBlueprintLibrary: Failed to load: ", file_path)
	
	print("CosmoteerBlueprintLibrary: Loaded ", blueprints.size(), " valid blueprints")
	
	if blueprints.is_empty():
		print("CosmoteerBlueprintLibrary: No valid blueprints, showing message")
		_show_no_blueprints_message()
		return
	
	# Create button for each blueprint
	for blueprint in blueprints:
		print("CosmoteerBlueprintLibrary: Creating button for: ", blueprint.blueprint_name)
		var item = _create_blueprint_item(blueprint)
		blueprint_list.add_child(item)

func _show_no_blueprints_message():
	var label = Label.new()
	label.text = "No blueprints found.\nCreate one in the Blueprint Builder!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	blueprint_list.add_child(label)

func _create_blueprint_item(blueprint: CosmoteerShipBlueprint) -> Control:
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(0, 80)
	
	# Name button
	var btn = Button.new()
	btn.text = blueprint.blueprint_name
	btn.custom_minimum_size = Vector2(0, 40)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(func(): _on_blueprint_button_pressed(blueprint))
	vbox.add_child(btn)
	
	# Stats preview
	var power = CosmoteerShipStatsCalculator.calculate_power(blueprint)
	var weight_thrust = CosmoteerShipStatsCalculator.calculate_weight_thrust(blueprint)
	var cost = CosmoteerShipStatsCalculator.calculate_cost(blueprint)
	
	var stats_label = Label.new()
	var power_text = "Power: %d/%d" % [power.get("generated", 0), power.get("consumed", 0)]
	var thrust_text = "Thrust: %d Weight: %d" % [weight_thrust.get("thrust", 0), weight_thrust.get("weight", 0)]
	var cost_text = "Cost: " + _format_cost(cost)
	stats_label.text = power_text + " | " + thrust_text + "\n" + cost_text
	stats_label.add_theme_font_size_override("font_size", 10)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)
	
	return vbox

func _format_cost(cost: Dictionary) -> String:
	if cost.is_empty():
		return "Free"
	var parts: Array[String] = []
	for res_id in cost.keys():
		var res_name = ResourceManager.get_resource_data(res_id).get("name", "Res%d" % res_id) if ResourceManager else "Res%d" % res_id
		parts.append("%s:%d" % [res_name, cost[res_id]])
	return ", ".join(parts)

func _on_blueprint_button_pressed(blueprint: CosmoteerShipBlueprint):
	blueprint_selected.emit(blueprint)
	queue_free()

func _on_cancel_pressed():
	cancelled.emit()
	queue_free()

