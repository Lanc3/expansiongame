extends PanelContainer
class_name ComponentLevelButton
## Card-style button with icon, level selector, and stats for blueprint components

signal component_selected(comp_type: String, level: int)
signal level_changed(comp_type: String, new_level: int)

var component_type: String = ""
var current_level: int = 1
var max_level: int = 9
var unlocked_levels: int = 9  # How many levels are unlocked (for research integration)
var category_color: Color = Color.WHITE

# UI Elements
var icon_rect: TextureRect
var main_button: Button
var name_label: Label
var level_label: Label
var decrease_btn: Button
var increase_btn: Button
var stats_label: Label
var power_label: Label
var size_label: Label
var accent_bar: ColorRect
var card_style: StyleBoxFlat

func _init():
	custom_minimum_size = Vector2(0, 72)

func _ready():
	_build_ui()
	# Call _update_display() here in case setup() was called before entering tree
	if component_type != "":
		_update_display()

func setup(comp_type: String, default_level: int = 1):
	"""Initialize button with component type"""
	component_type = comp_type
	current_level = clamp(default_level, 1, 9)
	max_level = CosmoteerComponentDefs.get_max_level(comp_type)
	unlocked_levels = _get_unlocked_levels_for_component(comp_type)
	category_color = CosmoteerComponentDefs.get_component_category_color(comp_type)
	
	_update_display()

func _get_unlocked_levels_for_component(comp_type: String) -> int:
	"""Get how many levels are unlocked for this component type"""
	# TODO: Integrate with research system
	# For now, all levels are unlocked for testing
	return CosmoteerComponentDefs.get_max_level(comp_type)

func _build_ui():
	"""Build the card-style button UI structure"""
	# Create card style
	card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.1, 0.14, 0.95)
	card_style.border_width_left = 4
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(0.3, 0.35, 0.4, 0.6)
	card_style.corner_radius_top_left = 4
	card_style.corner_radius_top_right = 4
	card_style.corner_radius_bottom_right = 4
	card_style.corner_radius_bottom_left = 4
	card_style.content_margin_left = 6
	card_style.content_margin_right = 6
	card_style.content_margin_top = 4
	card_style.content_margin_bottom = 4
	add_theme_stylebox_override("panel", card_style)
	
	# Main horizontal layout
	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 8)
	add_child(main_hbox)
	
	# Icon container with background
	var icon_container = PanelContainer.new()
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = Color(0.12, 0.14, 0.18, 0.8)
	icon_style.corner_radius_top_left = 4
	icon_style.corner_radius_top_right = 4
	icon_style.corner_radius_bottom_right = 4
	icon_style.corner_radius_bottom_left = 4
	icon_container.add_theme_stylebox_override("panel", icon_style)
	icon_container.custom_minimum_size = Vector2(48, 48)
	main_hbox.add_child(icon_container)
	
	# Component icon
	icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(40, 40)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_container.add_child(icon_rect)
	
	# Right side content
	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 2)
	main_hbox.add_child(content_vbox)
	
	# Top row: Name button + level controls
	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 4)
	content_vbox.add_child(top_hbox)
	
	# Main button (component name) - clickable area
	main_button = Button.new()
	main_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_button.custom_minimum_size = Vector2(0, 26)
	main_button.pressed.connect(_on_main_button_pressed)
	main_button.flat = true
	main_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	top_hbox.add_child(main_button)
	
	# Level control container
	var level_control = HBoxContainer.new()
	level_control.add_theme_constant_override("separation", 2)
	top_hbox.add_child(level_control)
	
	# Decrease level button
	decrease_btn = Button.new()
	decrease_btn.text = "◄"
	decrease_btn.custom_minimum_size = Vector2(22, 24)
	decrease_btn.pressed.connect(_on_decrease_pressed)
	decrease_btn.flat = true
	level_control.add_child(decrease_btn)
	
	# Level label
	level_label = Label.new()
	level_label.text = "L1"
	level_label.custom_minimum_size = Vector2(28, 0)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 11)
	level_control.add_child(level_label)
	
	# Increase level button
	increase_btn = Button.new()
	increase_btn.text = "►"
	increase_btn.custom_minimum_size = Vector2(22, 24)
	increase_btn.pressed.connect(_on_increase_pressed)
	increase_btn.flat = true
	level_control.add_child(increase_btn)
	
	# Stats row
	var stats_hbox = HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 12)
	content_vbox.add_child(stats_hbox)
	
	# Key stat label (damage, power, etc.)
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 10)
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 1.0))
	stats_hbox.add_child(stats_label)
	
	# Power consumption label
	power_label = Label.new()
	power_label.add_theme_font_size_override("font_size", 10)
	power_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 0.9))
	stats_hbox.add_child(power_label)
	
	# Size label
	size_label = Label.new()
	size_label.add_theme_font_size_override("font_size", 10)
	size_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7, 0.9))
	stats_hbox.add_child(size_label)
	
	# Cost label (at the end)
	var cost_label = Label.new()
	cost_label.name = "CostLabel"
	cost_label.add_theme_font_size_override("font_size", 10)
	cost_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5, 0.9))
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_hbox.add_child(cost_label)
	
	# Add hover effects
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _update_display():
	"""Update all UI elements with current component/level data"""
	if not is_inside_tree():
		return
	
	var comp_data = CosmoteerComponentDefs.get_component_data_by_level(component_type, current_level)
	if comp_data.is_empty():
		return
	
	# Update category color on left border
	card_style.border_color = Color(0.3, 0.35, 0.4, 0.6)
	card_style.set_border_width(SIDE_LEFT, 4)
	var left_color = category_color
	left_color.a = 0.9
	card_style.border_color = card_style.border_color  # Keep other borders
	# Create gradient effect by using the category color for left border
	var modified_style = card_style.duplicate()
	modified_style.border_color = left_color
	modified_style.border_width_top = 1
	modified_style.border_width_right = 1
	modified_style.border_width_bottom = 1
	# Actually update left border separately isn't possible with StyleBoxFlat
	# So we'll tint the entire border subtly and rely on accent
	card_style.border_color = category_color.lerp(Color(0.3, 0.35, 0.4), 0.5)
	
	# Update icon
	var sprite_path = comp_data.get("sprite", "")
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		var texture = load(sprite_path)
		if texture:
			icon_rect.texture = texture
			icon_rect.modulate = category_color.lerp(Color.WHITE, 0.3)
	
	# Update main button text with component name
	var comp_name = comp_data.get("name", "Unknown")
	main_button.text = comp_name
	main_button.add_theme_color_override("font_color", category_color)
	main_button.add_theme_color_override("font_hover_color", category_color.lightened(0.2))
	
	# Update level label
	level_label.text = "L%d" % current_level
	level_label.add_theme_color_override("font_color", category_color.lerp(Color.WHITE, 0.5))
	
	# Update level buttons
	decrease_btn.disabled = (current_level <= 1)
	increase_btn.disabled = (current_level >= unlocked_levels)
	
	# Show lock icon if at max unlocked but more exist
	if current_level >= unlocked_levels and unlocked_levels < max_level:
		increase_btn.text = "🔒"
	else:
		increase_btn.text = "►"
	
	# Update key stat display
	var key_stat = _get_key_stat(comp_data)
	stats_label.text = key_stat
	
	# Update power display
	var power_gen = comp_data.get("power_generated", 0)
	var power_con = comp_data.get("power_consumed", 0)
	if power_gen > 0:
		power_label.text = "+%d⚡" % power_gen
		power_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))
	elif power_con > 0:
		power_label.text = "-%d⚡" % power_con
		power_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 0.9))
	else:
		power_label.text = ""
	
	# Update size display
	var size = comp_data.get("size", Vector2i.ONE)
	size_label.text = "%dx%d" % [size.x, size.y]
	
	# Update cost display
	var cost = comp_data.get("cost", {})
	var cost_label = get_node_or_null("HBoxContainer/VBoxContainer/HBoxContainer2/CostLabel")
	if cost_label == null:
		# Find cost label by traversing
		for child in get_children():
			if child is HBoxContainer:
				for subchild in child.get_children():
					if subchild is VBoxContainer:
						for subsubchild in subchild.get_children():
							if subsubchild is HBoxContainer:
								for stat_child in subsubchild.get_children():
									if stat_child.name == "CostLabel":
										cost_label = stat_child
										break
	if cost_label:
		cost_label.text = _format_cost_compact(cost)
	
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
		parts.append("%d%s" % [amount, short_name.substr(0, 1)])
	
	return " ".join(parts)

func _get_key_stat(comp_data: Dictionary) -> String:
	"""Get the key stat to display for this component"""
	if comp_data.has("damage") and comp_data.damage > 0:
		var fire_rate = comp_data.get("fire_rate", 1.0)
		var dps = comp_data.damage * fire_rate
		return "%.0f DPS" % dps
	elif comp_data.has("power_generated") and comp_data.power_generated > 0:
		return "%d⚡ gen" % comp_data.power_generated
	elif comp_data.has("thrust"):
		return "%.0f thrust" % comp_data.thrust
	elif comp_data.has("shield_hp"):
		return "%.0f shield" % comp_data.shield_hp
	elif comp_data.has("repair_rate"):
		return "%.0f HP/s" % comp_data.repair_rate
	elif comp_data.has("mining_rate"):
		return "%.1fx mining" % comp_data.mining_rate
	elif comp_data.has("scan_multiplier"):
		return "%.0fx scan" % comp_data.scan_multiplier
	return ""

func _update_tooltip(comp_data: Dictionary):
	"""Update tooltip with full component stats"""
	var tooltip = "[b]%s[/b] (Level %d)\n" % [comp_data.get("name", "Unknown"), current_level]
	tooltip += comp_data.get("description", "") + "\n"
	tooltip += "\n[u]Stats:[/u]"
	tooltip += "\nSize: %dx%d" % [comp_data.get("size", Vector2i.ONE).x, comp_data.get("size", Vector2i.ONE).y]
	tooltip += "\nWeight: %.0f" % comp_data.get("weight", 0)
	
	if comp_data.has("power_generated") and comp_data.power_generated > 0:
		tooltip += "\nPower Generated: +%d" % comp_data.power_generated
	if comp_data.has("power_consumed") and comp_data.power_consumed > 0:
		tooltip += "\nPower Consumed: -%d" % comp_data.power_consumed
	if comp_data.has("thrust"):
		tooltip += "\nThrust: %.0f" % comp_data.thrust
	if comp_data.has("speed_boost"):
		tooltip += "\nSpeed Boost: +%.0f" % comp_data.speed_boost
	if comp_data.has("damage"):
		tooltip += "\nDamage: %.0f" % comp_data.damage
		tooltip += "\nFire Rate: %.1f/s" % comp_data.get("fire_rate", 1.0)
		tooltip += "\nRange: %d" % comp_data.get("range", 0)
	if comp_data.has("shield_hp"):
		tooltip += "\nShield HP: %.0f" % comp_data.shield_hp
	if comp_data.has("repair_rate"):
		tooltip += "\nRepair Rate: %.0f/s" % comp_data.repair_rate
	if comp_data.has("mining_rate"):
		tooltip += "\nMining Rate: %.1fx" % comp_data.mining_rate
		tooltip += "\nCargo Bonus: +%d" % comp_data.get("cargo_bonus", 0)
	if comp_data.has("scan_multiplier"):
		tooltip += "\nScan Speed: %.0fx" % comp_data.scan_multiplier
	
	# Cost breakdown
	var cost = comp_data.get("cost", {})
	if not cost.is_empty():
		tooltip += "\n\n[u]Cost:[/u]"
		for resource_id in cost.keys():
			var amount = cost[resource_id]
			var resource_name = CosmoteerShipStatsCalculator.get_resource_name(resource_id)
			tooltip += "\n  %s: %d" % [resource_name, amount]
	
	tooltip += "\n\n[i]Click to select • ◄/► to change level[/i]"
	
	tooltip_text = tooltip

func _on_mouse_entered():
	"""Hover effect"""
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	# Lighten background
	var hover_style = card_style.duplicate()
	hover_style.bg_color = Color(0.12, 0.14, 0.18, 0.98)
	add_theme_stylebox_override("panel", hover_style)
	tween.tween_property(self, "modulate", Color(1.05, 1.05, 1.05, 1.0), 0.1)

func _on_mouse_exited():
	"""Remove hover effect"""
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	add_theme_stylebox_override("panel", card_style)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func _on_main_button_pressed():
	"""Main button clicked - select this component at current level"""
	component_selected.emit(component_type, current_level)
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(self, "modulate", category_color.lightened(0.3), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)

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

func matches_filter(filter_text: String) -> bool:
	"""Check if this component matches a search filter"""
	if filter_text.is_empty():
		return true
	
	var search = filter_text.to_lower()
	var type_data = CosmoteerComponentDefs.get_component_type_info(component_type)
	var name = type_data.get("name", "").to_lower()
	var category = CosmoteerComponentDefs.get_component_category(component_type).to_lower()
	
	return name.contains(search) or category.contains(search) or component_type.to_lower().contains(search)
