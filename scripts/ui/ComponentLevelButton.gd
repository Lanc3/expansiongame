extends PanelContainer
class_name ComponentLevelButton
## Custom button with level selector for blueprint components

signal component_selected(comp_type: String, level: int)
signal level_changed(comp_type: String, new_level: int)

var component_type: String = ""
var current_level: int = 1
var max_level: int = 9
var unlocked_levels: int = 9  # How many levels are unlocked (for research integration)

# UI Elements
var main_button: Button
var level_label: Label
var decrease_btn: Button
var increase_btn: Button
var stats_label: Label

func _init():
	custom_minimum_size = Vector2(0, 60)

func _ready():
	_build_ui()

func setup(comp_type: String, default_level: int = 1):
	"""Initialize button with component type"""
	component_type = comp_type
	current_level = clamp(default_level, 1, 9)
	max_level = CosmoteerComponentDefs.get_max_level(comp_type)
	unlocked_levels = _get_unlocked_levels_for_component(comp_type)
	
	_update_display()

func _get_unlocked_levels_for_component(comp_type: String) -> int:
	"""Get how many levels are unlocked for this component type"""
	# TODO: Integrate with research system
	# For now, all levels are unlocked for testing
	# Future: Check ResearchManager for "power_core_l2", "power_core_l3", etc.
	return CosmoteerComponentDefs.get_max_level(comp_type)

func _build_ui():
	"""Build the button UI structure"""
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)
	
	# Top row: Component name + level selector
	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 4)
	vbox.add_child(top_hbox)
	
	# Main button (component name)
	main_button = Button.new()
	main_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_button.custom_minimum_size = Vector2(0, 28)
	main_button.pressed.connect(_on_main_button_pressed)
	top_hbox.add_child(main_button)
	
	# Level control container
	var level_control = HBoxContainer.new()
	level_control.add_theme_constant_override("separation", 2)
	top_hbox.add_child(level_control)
	
	# Decrease level button
	decrease_btn = Button.new()
	decrease_btn.text = "◄"
	decrease_btn.custom_minimum_size = Vector2(25, 28)
	decrease_btn.pressed.connect(_on_decrease_pressed)
	level_control.add_child(decrease_btn)
	
	# Level label
	level_label = Label.new()
	level_label.text = "L1/9"
	level_label.custom_minimum_size = Vector2(35, 0)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_control.add_child(level_label)
	
	# Increase level button
	increase_btn = Button.new()
	increase_btn.text = "►"
	increase_btn.custom_minimum_size = Vector2(25, 28)
	increase_btn.pressed.connect(_on_increase_pressed)
	level_control.add_child(increase_btn)
	
	# Bottom row: Stats display
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 10)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)

func _update_display():
	"""Update all UI elements with current component/level data"""
	if not is_inside_tree():
		return
	
	var comp_data = CosmoteerComponentDefs.get_component_data_by_level(component_type, current_level)
	if comp_data.is_empty():
		return
	
	# Update main button text
	main_button.text = comp_data.get("name", "Unknown")
	
	# Update level label
	level_label.text = "L%d/%d" % [current_level, max_level]
	
	# Update level buttons
	decrease_btn.disabled = (current_level <= 1)
	increase_btn.disabled = (current_level >= unlocked_levels)
	
	# Show lock icon if at max unlocked but more exist
	if current_level >= unlocked_levels and unlocked_levels < max_level:
		increase_btn.text = "🔒"
	else:
		increase_btn.text = "►"
	
	# Update stats display
	var stats_parts: Array = []
	
	# Cost
	var cost = comp_data.get("cost", {})
	var cost_str = _format_cost_compact(cost)
	stats_parts.append(cost_str)
	
	# Size
	var size = comp_data.get("size", Vector2i.ONE)
	stats_parts.append("%dx%d" % [size.x, size.y])
	
	# Key stat
	var key_stat = _get_key_stat(comp_data)
	stats_parts.append(key_stat)
	
	stats_label.text = " | ".join(stats_parts)
	
	# Update tooltip
	_update_tooltip(comp_data)

func _format_cost_compact(cost: Dictionary) -> String:
	"""Format cost compactly"""
	if cost.is_empty():
		return "Free"
	
	var parts: Array = []
	for resource_id in cost.keys():
		var amount = cost[resource_id]
		var resource_name = CosmoteerShipStatsCalculator.get_resource_name(resource_id)
		var short_name = resource_name.split(" ")[0]
		parts.append("%d%s" % [amount, short_name.substr(0, 1)])  # Just first letter
	
	return ", ".join(parts)

func _get_key_stat(comp_data: Dictionary) -> String:
	"""Get the key stat to display for this component"""
	if comp_data.has("power_generated") and comp_data.power_generated > 0:
		return "%d⚡" % comp_data.power_generated
	elif comp_data.has("thrust"):
		return "%.0f🚀" % comp_data.thrust
	elif comp_data.has("damage"):
		return "%.0f💥" % comp_data.damage
	elif comp_data.has("shield_hp"):
		return "%.0f🛡" % comp_data.shield_hp
	elif comp_data.has("repair_rate"):
		return "%.0f❤/s" % comp_data.repair_rate
	return ""

func _update_tooltip(comp_data: Dictionary):
	"""Update tooltip with full component stats"""
	var tooltip = comp_data.get("description", "")
	tooltip += "\n\nLevel %d Stats:" % current_level
	tooltip += "\nSize: %dx%d" % [comp_data.get("size", Vector2i.ONE).x, comp_data.get("size", Vector2i.ONE).y]
	tooltip += "\nWeight: %.0f" % comp_data.get("weight", 0)
	
	if comp_data.has("power_generated") and comp_data.power_generated > 0:
		tooltip += "\nPower Generated: %d" % comp_data.power_generated
	if comp_data.has("power_consumed") and comp_data.power_consumed > 0:
		tooltip += "\nPower Consumed: %d" % comp_data.power_consumed
	if comp_data.has("thrust"):
		tooltip += "\nThrust: %.0f" % comp_data.thrust
	if comp_data.has("speed_boost"):
		tooltip += "\nSpeed Boost: %.0f" % comp_data.speed_boost
	if comp_data.has("damage"):
		tooltip += "\nDamage: %.0f" % comp_data.damage
	if comp_data.has("shield_hp"):
		tooltip += "\nShield HP: %.0f" % comp_data.shield_hp
	if comp_data.has("repair_rate"):
		tooltip += "\nRepair Rate: %.0f/s" % comp_data.repair_rate
	
	tooltip += "\n\nClick arrows to change level"
	tooltip += "\nClick name to select for painting"
	
	main_button.tooltip_text = tooltip

func _on_main_button_pressed():
	"""Main button clicked - select this component at current level"""
	component_selected.emit(component_type, current_level)

func _on_decrease_pressed():
	"""Decrease component level"""
	if current_level > 1:
		current_level -= 1
		_update_display()
		level_changed.emit(component_type, current_level)

func _on_increase_pressed():
	"""Increase component level"""
	if current_level < unlocked_levels:
		current_level += 1
		_update_display()
		level_changed.emit(component_type, current_level)

func get_current_level() -> int:
	"""Get currently selected level"""
	return current_level

func set_unlocked_levels(unlocked: int):
	"""Set how many levels are unlocked (for research integration)"""
	unlocked_levels = clamp(unlocked, 1, max_level)
	_update_display()

