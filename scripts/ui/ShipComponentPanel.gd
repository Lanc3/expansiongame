extends Control
class_name ShipComponentPanel

signal selection_changed(component_type: String, selected_indices: Array)
signal command_mode_changed(mode: String) # "scan", "mine", "attack", ""

var ship: Node = null
var current_type: String = "miner" # default tab
var selected_indices: Dictionary = {"scanner": [], "miner": []}

var health_bar: ProgressBar
var shield_bar: ProgressBar
var tabs: HBoxContainer
var list: GridContainer
var footer: HBoxContainer
var stats_container: VBoxContainer  # Container for component stats display

const ICONS_DIR := "res://assets/ui/Ship Component Ui/"
const TYPE_TO_ICON := {
	"scanner": "scanner icon.png",
	"miner": "mining laser icon.png",
	"engine": "engine icon.png",
	"power_core": "energy core icon.png",
	"laser_weapon": "laser weapon icon.png",
	"missile_launcher": "misile weapon icon.png",
	"shield_generator": "shield icon.png",
	"repair_bot": "",
	# All weapons use the same base icon for now
	"autocannon": "laser weapon icon.png",
	"railgun": "laser weapon icon.png",
	"gatling": "laser weapon icon.png",
	"sniper_cannon": "laser weapon icon.png",
	"shotgun": "laser weapon icon.png",
	"ion_cannon": "laser weapon icon.png",
	"plasma_cannon": "laser weapon icon.png",
	"particle_beam": "laser weapon icon.png",
	"tesla_coil": "laser weapon icon.png",
	"disruptor": "laser weapon icon.png",
	"flak_cannon": "misile weapon icon.png",
	"torpedo": "misile weapon icon.png",
	"rocket_pod": "misile weapon icon.png",
	"mortar": "misile weapon icon.png",
	"mine_layer": "misile weapon icon.png",
	"cryo_cannon": "laser weapon icon.png",
	"emp_burst": "laser weapon icon.png",
	"gravity_well": "laser weapon icon.png",
	"repair_beam": "laser weapon icon.png"
}

const COMPONENT_ORDER = ["scanner", "miner", "weapons", "shield_generator", "engine", "power_core", "repair_bot"]
const HOTKEY_MAPPING = {
	KEY_Q: "scanner",
	KEY_W: "miner",
	KEY_E: "weapons",
	KEY_R: "weapons",
	KEY_T: "shield_generator",
	KEY_Y: "engine",
	KEY_U: "power_core",
	KEY_I: "repair_bot"
}

# Text labels for tabs (no icons)
const TAB_LABELS = {
	"scanner": "Scanner",
	"miner": "Miner",
	"weapons": "Weapons",
	"laser_weapon": "Laser",
	"missile_launcher": "Missile"
}

# Selectable component types (shown in tabs) - weapons are now grouped
const SELECTABLE_TYPES = ["scanner", "miner", "weapons"]

# All weapon type IDs that should be counted under "weapons" tab
const ALL_WEAPON_TYPES = [
	"laser_weapon", "missile_launcher", "autocannon", "railgun", "gatling",
	"sniper_cannon", "shotgun", "ion_cannon", "plasma_cannon", "particle_beam",
	"tesla_coil", "disruptor", "flak_cannon", "torpedo", "rocket_pod",
	"mortar", "mine_layer", "cryo_cannon", "emp_burst", "gravity_well", "repair_beam"
]

func _ready() -> void:
	_setup_ui_layout()
	_build_type_bar()
	_update_footer_content()
	_rebuild_list()
	_update_component_stats()
	set_process_unhandled_input(true)

func _setup_ui_layout() -> void:
	# Clear all children to rebuild layout
	for c in get_children():
		c.queue_free()
	
	# Main split container (40/60)
	var main_split = HBoxContainer.new()
	main_split.name = "MainSplit"
	main_split.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_split.offset_left = 12
	main_split.offset_top = 12
	main_split.offset_right = -12
	main_split.offset_bottom = -12
	main_split.add_theme_constant_override("separation", 10)
	add_child(main_split)
	
	# LEFT PANEL (40% width) - use stretch ratio 2 (2:3 = 40:60)
	var left_panel = VBoxContainer.new()
	left_panel.name = "LeftPanel"
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 2  # 2/(2+3) = 40%
	main_split.add_child(left_panel)
	
	# Left panel split: 33% top (health/shield), 66% bottom (stats)
	_setup_left_panel(left_panel)
	
	# RIGHT PANEL (60% width) - use stretch ratio 3 (2:3 = 40:60)
	var right_panel = VBoxContainer.new()
	right_panel.name = "RightPanel"
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_stretch_ratio = 3  # 3/(2+3) = 60%
	main_split.add_child(right_panel)
	
	_setup_right_panel(right_panel)

func _setup_left_panel(container: VBoxContainer) -> void:
	# Top section (33%): Health & Shield bars
	var top_section = VBoxContainer.new()
	top_section.name = "TopSection"
	top_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_section.add_theme_constant_override("separation", 4)
	container.add_child(top_section)
	
	# Header Label
	var header = Label.new()
	header.text = "SHIP STATUS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 12)
	header.modulate = Color(0.7, 0.8, 1.0)
	top_section.add_child(header)
	
	# Health Bar
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.custom_minimum_size = Vector2(0, 24)
	health_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	health_bar.show_percentage = false
	
	var hp_bg = StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.1, 0.05, 0.05, 0.8)
	hp_bg.border_width_left = 1
	hp_bg.border_width_top = 1
	hp_bg.border_width_right = 1
	hp_bg.border_width_bottom = 1
	hp_bg.border_color = Color(0.3, 0.1, 0.1)
	hp_bg.corner_radius_top_left = 4
	hp_bg.corner_radius_top_right = 4
	hp_bg.corner_radius_bottom_right = 4
	hp_bg.corner_radius_bottom_left = 4
	health_bar.add_theme_stylebox_override("background", hp_bg)
	
	var hp_fill = StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.8, 0.2, 0.2, 1.0)
	hp_fill.corner_radius_top_left = 4
	hp_fill.corner_radius_top_right = 4
	hp_fill.corner_radius_bottom_right = 4
	hp_fill.corner_radius_bottom_left = 4
	health_bar.add_theme_stylebox_override("fill", hp_fill)
	
	top_section.add_child(health_bar)
	
	# Shield Bar
	shield_bar = ProgressBar.new()
	shield_bar.name = "ShieldBar"
	shield_bar.custom_minimum_size = Vector2(0, 16)
	shield_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shield_bar.show_percentage = false
	
	var sh_bg = StyleBoxFlat.new()
	sh_bg.bg_color = Color(0.0, 0.1, 0.2, 0.8)
	sh_bg.border_width_left = 1
	sh_bg.border_width_top = 1
	sh_bg.border_width_right = 1
	sh_bg.border_width_bottom = 1
	sh_bg.border_color = Color(0.0, 0.2, 0.4)
	sh_bg.corner_radius_top_left = 4
	sh_bg.corner_radius_top_right = 4
	sh_bg.corner_radius_bottom_right = 4
	sh_bg.corner_radius_bottom_left = 4
	shield_bar.add_theme_stylebox_override("background", sh_bg)
	
	var sh_fill = StyleBoxFlat.new()
	sh_fill.bg_color = Color(0.2, 0.6, 1.0, 1.0)
	sh_fill.corner_radius_top_left = 4
	sh_fill.corner_radius_top_right = 4
	sh_fill.corner_radius_bottom_right = 4
	sh_fill.corner_radius_bottom_left = 4
	shield_bar.add_theme_stylebox_override("fill", sh_fill)
	
	top_section.add_child(shield_bar)
	
	# Bottom section (66%): Component stats display
	var bottom_section = VBoxContainer.new()
	bottom_section.name = "BottomSection"
	bottom_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_section.add_theme_constant_override("separation", 4)
	container.add_child(bottom_section)
	
	# Use ratio to enforce 33/66 split
	top_section.size_flags_stretch_ratio = 1.0
	bottom_section.size_flags_stretch_ratio = 2.0
	
	# Build stats display
	_build_stats_display(bottom_section)

func _setup_right_panel(container: VBoxContainer) -> void:
	# Component Tabs
	tabs = HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.custom_minimum_size.y = 40
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(tabs)
	
	# Component List Area
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollList"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_child(scroll)
	
	list = GridContainer.new()
	list.name = "List"
	list.columns = 4  # Fewer columns for larger icons
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("h_separation", 6)
	list.add_theme_constant_override("v_separation", 6)
	scroll.add_child(list)
	
	# Footer (Dynamic Content)
	footer = HBoxContainer.new()
	footer.name = "Footer"
	footer.custom_minimum_size.y = 40
	footer.add_theme_constant_override("separation", 10)
	container.add_child(footer)

func _process(delta: float) -> void:
	if not visible or not is_instance_valid(ship):
		return
	
	# Update Health
	if health_bar:
		health_bar.max_value = ship.get("max_health") if "max_health" in ship else 100.0
		health_bar.value = ship.get("current_health") if "current_health" in ship else 0.0
		health_bar.tooltip_text = "Hull Integrity: %d/%d" % [health_bar.value, health_bar.max_value]
	
	# Update Shield
	if shield_bar:
		var shield_vals = ship.get_shield_values() if ship.has_method("get_shield_values") else {"max": 0, "current": 0}
		var max_shield = shield_vals.get("max", 0.0)
		if max_shield > 0:
			shield_bar.visible = true
			shield_bar.max_value = max_shield
			shield_bar.value = shield_vals.get("current", 0.0)
			shield_bar.tooltip_text = "Shield Status: %d/%d" % [shield_bar.value, max_shield]
		else:
			shield_bar.visible = false
	
	# Update component stats
	_update_component_stats()

func set_ship(s):
	ship = s
	_build_type_bar()
	_rebuild_list()
	_update_footer_content()
	_update_component_stats()

func _on_tab_pressed(new_type: String) -> void:
	current_type = new_type
	_update_tab_visuals()
	_rebuild_list()
	_update_footer_content()

func _rebuild_list() -> void:
	if list == null or ship == null:
		return
	for c in list.get_children():
		c.queue_free()
	var items_count = _get_component_count(current_type)
	
	for i in range(items_count):
		# Create a container for the icon with glow background
		var item_container = PanelContainer.new()
		item_container.custom_minimum_size = Vector2(52, 52)
		
		var is_selected = i in selected_indices.get(current_type, [])
		
		# Create stylebox for background glow effect
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_right = 6
		style.corner_radius_bottom_left = 6
		
		if is_selected:
			# Bright glow for selected/ON
			style.bg_color = Color(0.2, 0.5, 0.8, 0.6)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.border_color = Color(0.4, 0.8, 1.0, 0.9)
		else:
			# Dimmed for unselected/OFF
			style.bg_color = Color(0.15, 0.15, 0.15, 0.5)
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.border_color = Color(0.3, 0.3, 0.3, 0.5)
		
		item_container.add_theme_stylebox_override("panel", style)
		
		# Button inside the container
		var toggle := Button.new()
		toggle.toggle_mode = true
		
		# For weapons tab, show weapon type name instead of just number
		var display_text = "%d" % [i + 1]
		var icon_type = current_type
		
		if current_type == "weapons" and "weapon_components" in ship and i < ship.weapon_components.size():
			var weapon = ship.weapon_components[i]
			# Get short weapon type name
			var type_name = weapon.get_display_name() if weapon.has_method("get_display_name") else "Wpn"
			# Abbreviate long names
			if type_name.length() > 4:
				type_name = type_name.left(3)
			display_text = "%s%d" % [type_name, i + 1]
			# Use appropriate icon based on weapon type
			if weapon.weapon_type == WeaponComponent.WeaponType.MISSILE or \
			   weapon.weapon_type == WeaponComponent.WeaponType.TORPEDO or \
			   weapon.weapon_type == WeaponComponent.WeaponType.FLAK_CANNON or \
			   weapon.weapon_type == WeaponComponent.WeaponType.ROCKET_POD or \
			   weapon.weapon_type == WeaponComponent.WeaponType.MORTAR or \
			   weapon.weapon_type == WeaponComponent.WeaponType.MINE_LAYER:
				icon_type = "missile_launcher"
			else:
				icon_type = "laser_weapon"
		
		toggle.text = display_text
		toggle.icon = _load_icon_for_type(icon_type)
		toggle.expand_icon = true
		toggle.flat = true
		toggle.button_pressed = is_selected
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toggle.size_flags_vertical = Control.SIZE_EXPAND_FILL
		toggle.add_theme_font_size_override("font_size", 9)  # Smaller font for longer labels
		
		# Color modulation for glow effect
		if is_selected:
			toggle.modulate = Color(1.4, 1.4, 1.4)  # Bright glow
			toggle.add_theme_color_override("font_color", Color.WHITE)
		else:
			toggle.modulate = Color(0.5, 0.5, 0.5, 0.8)  # Dimmed
			toggle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		
		toggle.connect("pressed", Callable(self, "_on_toggle_pressed").bind(i))
		item_container.add_child(toggle)
		list.add_child(item_container)

func _get_component_count(type: String) -> int:
	if ship == null: return 0
	
	match type:
		"scanner":
			return ship.get_scanner_components().size() if ship.has_method("get_scanner_components") else 0
		"miner":
			return ship.get_mining_components().size() if ship.has_method("get_mining_components") else 0
		"weapons":
			# Count all weapon types
			if "weapon_components" in ship:
				return ship.weapon_components.size()
			return 0
		"laser_weapon":
			if "weapon_components" in ship:
				var count = 0
				for w in ship.weapon_components:
					if w.weapon_type == WeaponComponent.WeaponType.LASER:
						count += 1
				return count
			return 0
		"missile_launcher":
			if "weapon_components" in ship:
				var count = 0
				for w in ship.weapon_components:
					if w.weapon_type == WeaponComponent.WeaponType.MISSILE:
						count += 1
				return count
			return 0
		"shield_generator":
			return 1 if ship.has_method("get_shield_values") and ship.get_shield_values().get("max", 0.0) > 0 else 0
		"engine", "power_core", "repair_bot":
			return ship.get_component_count(type) if ship.has_method("get_component_count") else 0
	return 0

func _on_toggle_pressed(idx: int) -> void:
	var sel = selected_indices.get(current_type, []).duplicate()
	if Input.is_key_pressed(KEY_CTRL):
		if idx in sel:
			sel.erase(idx)
		else:
			sel.append(idx)
	else:
		# single select or toggle if clicking same
		if sel == [idx]:
			sel = [] # Deselect if clicking active
		else:
			sel = [idx]
			
	selected_indices[current_type] = sel
	selection_changed.emit(current_type, sel)
	_rebuild_list()
	_update_footer_content()

func _update_footer_content() -> void:
	if footer == null: return
	for c in footer.get_children():
		c.queue_free()
	
	if not is_instance_valid(ship):
		return
	
	# Get stats for current component type
	var all_stats = _get_component_stats()
	var stats = all_stats.get(current_type, {})
	
	# For "weapons" tab, aggregate stats from all weapon types
	if current_type == "weapons":
		stats = _get_all_weapons_stats()
	
	# Create stats label
	var info = Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 11)
	info.modulate = Color(0.85, 0.9, 1.0)
	
	var count = stats.get("count", 0)
	if count == 0:
		info.text = "No %s equipped" % TAB_LABELS.get(current_type, current_type)
		info.modulate = Color(0.6, 0.6, 0.6)
	else:
		match current_type:
			"weapons":
				var total_dps = stats.get("total_dps", 0.0)
				var power = stats.get("power_consumed", 0)
				var max_range = stats.get("max_range", 0.0)
				info.text = "Total DPS: %.0f  |  Range: %.0f  |  Power: %d  |  Count: %d" % [total_dps, max_range, power, count]
			
			"laser_weapon":
				var total_dmg = stats.get("total_damage", 0)
				var power = stats.get("power_consumed", 0)
				# Calculate DPS (assuming fire_rate of 2.0 for lasers)
				var dps = total_dmg * 2.0
				info.text = "Total DPS: %.0f  |  Power: %d  |  Count: %d" % [dps, power, count]
			
			"missile_launcher":
				var total_dmg = stats.get("total_damage", 0)
				var power = stats.get("power_consumed", 0)
				# Calculate DPS (assuming fire_rate of 0.5 for missiles)
				var dps = total_dmg * 0.5
				info.text = "Total DPS: %.0f  |  Power: %d  |  Count: %d" % [dps, power, count]
			
			"scanner":
				var scan_mult = stats.get("scan_multiplier", 0.0)
				var range_val = stats.get("range", 0.0)
				info.text = "Scan Rate: %.1fx  |  Range: %.0f  |  Count: %d" % [scan_mult, range_val, count]
			
			"miner":
				var mining_rate = stats.get("total_mining_rate", 0.0)
				var cargo_bonus = stats.get("total_cargo_bonus", 0)
				info.text = "Mining: %.1f/s  |  Cargo: +%d  |  Count: %d" % [mining_rate, cargo_bonus, count]
			
			_:
				info.text = "%d %s" % [count, TAB_LABELS.get(current_type, current_type)]
	
	footer.add_child(info)

func _get_all_weapons_stats() -> Dictionary:
	"""Get aggregated stats for all weapons on the ship"""
	var result = {"count": 0, "total_dps": 0.0, "power_consumed": 0, "max_range": 0.0}
	
	if not is_instance_valid(ship) or not "weapon_components" in ship:
		return result
	
	for weapon in ship.weapon_components:
		result["count"] += 1
		# Calculate DPS: damage * fire_rate
		var dps = weapon.damage * weapon.fire_rate
		result["total_dps"] += dps
		result["max_range"] = max(result["max_range"], weapon.rangeAim)
	
	# Get power from blueprint
	if "runtime_blueprint" in ship and ship.runtime_blueprint:
		for comp_data in ship.runtime_blueprint.components:
			var parsed = CosmoteerComponentDefs.parse_component_id(comp_data.get("type", ""))
			if parsed["type"] in ALL_WEAPON_TYPES:
				var comp_def = CosmoteerComponentDefs.get_component_data_by_level(parsed["type"], parsed["level"])
				result["power_consumed"] += comp_def.get("power_consumed", 0)
	
	return result

func _on_select_all_pressed() -> void:
	var count = _get_component_count(current_type)
	var sel = []
	for i in range(count):
		sel.append(i)
	selected_indices[current_type] = sel
	selection_changed.emit(current_type, sel)
	_rebuild_list()
	_update_footer_content()

func _load_icon_for_type(t: String) -> Texture2D:
	var file_name: String = TYPE_TO_ICON.get(t, "")
	if file_name == "":
		return null
	var path := ICONS_DIR + file_name
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	return tex

func _build_type_bar() -> void:
	if tabs == null or ship == null:
		return
	for c in tabs.get_children():
		c.queue_free()
	var types: Array = []
	if ship.has_method("get_component_types_present"):
		types = ship.get_component_types_present()
	
	for t in COMPONENT_ORDER:
		# Only create tabs for selectable component types present on ship
		if t in types and t in SELECTABLE_TYPES:
			# Create a container for the tab (text + underline)
			var tab_container = VBoxContainer.new()
			tab_container.add_theme_constant_override("separation", 2)
			
			var btn := Button.new()
			btn.name = "Tab_" + t
			btn.toggle_mode = true
			btn.focus_mode = Control.FOCUS_NONE
			btn.flat = true
			btn.text = TAB_LABELS.get(t, t.capitalize().replace("_", " "))
			btn.add_theme_font_size_override("font_size", 13)
			btn.pressed.connect(Callable(self, "_on_tab_pressed").bind(t))
			
			# Style based on selection
			if t == current_type:
				btn.button_pressed = true
				btn.add_theme_color_override("font_color", Color(1.0, 1.0, 0.7))
				btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 0.7))
			else:
				btn.button_pressed = false
				btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
				btn.add_theme_color_override("font_hover_color", Color(0.9, 0.9, 0.9))
			
			tab_container.add_child(btn)
			
			# Underline indicator
			var underline = ColorRect.new()
			underline.custom_minimum_size = Vector2(0, 3)
			underline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if t == current_type:
				underline.color = Color(0.3, 0.8, 1.0)  # Cyan underline for selected
			else:
				underline.color = Color(0.2, 0.2, 0.2, 0.5)  # Dim underline for unselected
			tab_container.add_child(underline)
			
			tabs.add_child(tab_container)

func _update_tab_visuals() -> void:
	if tabs == null: return
	_build_type_bar()

func _build_stats_display(container: VBoxContainer) -> void:
	# Header
	var stats_header = Label.new()
	stats_header.text = "COMPONENT STATS"
	stats_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_header.add_theme_font_size_override("font_size", 12)
	stats_header.modulate = Color(0.7, 0.8, 1.0)
	container.add_child(stats_header)
	
	# Scroll container for stats list
	var stats_scroll = ScrollContainer.new()
	stats_scroll.name = "StatsScroll"
	stats_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_child(stats_scroll)
	
	# Stats container
	stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_container.add_theme_constant_override("separation", 4)
	stats_scroll.add_child(stats_container)

func _update_component_stats() -> void:
	if not stats_container:
		return
	if not is_instance_valid(ship):
		# Clear stats if no ship
		for c in stats_container.get_children():
			c.queue_free()
		return
	
	# Clear existing stats
	for c in stats_container.get_children():
		c.queue_free()
	
	# Get aggregated stats for all component types
	var all_stats = _get_component_stats()
	
	# Display stats for each component type in order
	for comp_type in COMPONENT_ORDER:
		var stats = all_stats.get(comp_type, {})
		var has_component = stats.get("count", 0) > 0
		
		var stat_label = Label.new()
		stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_label.add_theme_font_size_override("font_size", 10)
		
		if has_component:
			var stat_text = _format_component_stats(comp_type, stats)
			stat_label.text = stat_text
			stat_label.modulate = Color.WHITE
		else:
			var comp_name = comp_type.capitalize().replace("_", " ")
			stat_label.text = "%s: N/A" % comp_name
			stat_label.modulate = Color(1.0, 0.2, 0.2)  # Red for N/A
		
		stats_container.add_child(stat_label)

func _format_component_stats(comp_type: String, stats: Dictionary) -> String:
	var comp_name = comp_type.capitalize().replace("_", " ")
	var lines: Array[String] = [comp_name + ":"]
	
	match comp_type:
		"power_core":
			lines.append("  Power Generated: %d" % stats.get("power_generated", 0))
			lines.append("  Count: %d" % stats.get("count", 0))
		
		"engine":
			lines.append("  Total Thrust: %.0f" % stats.get("total_thrust", 0))
			lines.append("  Speed Boost: %d" % stats.get("total_speed_boost", 0))
			lines.append("  Power Consumed: %d" % stats.get("power_consumed", 0))
			lines.append("  Count: %d" % stats.get("count", 0))
		
		"weapons":
			lines.append("  Total DPS: %.1f" % stats.get("total_dps", 0.0))
			lines.append("  Max Range: %.0f" % stats.get("max_range", 0.0))
			lines.append("  Power Consumed: %d" % stats.get("power_consumed", 0))
			lines.append("  Count: %d" % stats.get("count", 0))
		
		"laser_weapon":
			lines.append("  Total Damage: %d" % stats.get("total_damage", 0))
			lines.append("  Power Consumed: %d" % stats.get("power_consumed", 0))
			lines.append("  Count: %d" % stats.get("count", 0))
		
		"missile_launcher":
			lines.append("  Total Damage: %d" % stats.get("total_damage", 0))
			lines.append("  Power Consumed: %d" % stats.get("power_consumed", 0))
			lines.append("  Count: %d" % stats.get("count", 0))
		
		"shield_generator":
			lines.append("  Max Shield: %d" % stats.get("max_shield", 0))
			lines.append("  Current Shield: %d" % stats.get("current_shield", 0))
			lines.append("  Power Consumed: %d" % stats.get("power_consumed", 0))
		
		"scanner":
			lines.append("  Scan Multiplier: %.1fx" % stats.get("scan_multiplier", 0))
			lines.append("  Range: %.0f" % stats.get("range", 0))
			lines.append("  Power Consumed: %d" % stats.get("power_consumed", 0))
			lines.append("  Count: %d" % stats.get("count", 0))
		
		"miner":
			lines.append("  Mining Rate: %.1f" % stats.get("total_mining_rate", 0))
			lines.append("  Cargo Bonus: %d" % stats.get("total_cargo_bonus", 0))
			lines.append("  Range: %.0f" % stats.get("range", 0))
			lines.append("  Power Consumed: %d" % stats.get("power_consumed", 0))
			lines.append("  Count: %d" % stats.get("count", 0))
		
		"repair_bot":
			lines.append("  Total Repair Rate: %.1f" % stats.get("total_repair_rate", 0))
			lines.append("  Power Consumed: %d" % stats.get("power_consumed", 0))
			lines.append("  Count: %d" % stats.get("count", 0))
	
	return "\n".join(lines)

func _get_component_stats() -> Dictionary:
	var stats: Dictionary = {}
	if not is_instance_valid(ship):
		return stats
	
	# Check if ship has runtime_blueprint
	if not ("runtime_blueprint" in ship) or ship.runtime_blueprint == null:
		return stats
	
	var blueprint = ship.runtime_blueprint
	
	# Aggregate stats for each component type
	for comp_type in COMPONENT_ORDER:
		stats[comp_type] = _aggregate_component_type_stats(comp_type, blueprint)
	
	return stats

func _aggregate_component_type_stats(comp_type: String, blueprint) -> Dictionary:
	var result = {"count": 0}
	
	match comp_type:
		"power_core":
			var total_power = 0
			for comp_data in blueprint.components:
				var parsed = CosmoteerComponentDefs.parse_component_id(comp_data.get("type", ""))
				if parsed["type"] == "power_core":
					var comp_def = CosmoteerComponentDefs.get_component_data_by_level("power_core", parsed["level"])
					total_power += comp_def.get("power_generated", 0)
					result["count"] += 1
			result["power_generated"] = total_power
		
		"engine":
			var total_thrust = 0.0
			var total_speed_boost = 0
			var total_power = 0
			for comp_data in blueprint.components:
				var parsed = CosmoteerComponentDefs.parse_component_id(comp_data.get("type", ""))
				if parsed["type"] == "engine":
					var comp_def = CosmoteerComponentDefs.get_component_data_by_level("engine", parsed["level"])
					total_thrust += comp_def.get("thrust", 0.0)
					total_speed_boost += comp_def.get("speed_boost", 0)
					total_power += comp_def.get("power_consumed", 0)
					result["count"] += 1
			result["total_thrust"] = total_thrust
			result["total_speed_boost"] = total_speed_boost
			result["power_consumed"] = total_power
		
		"weapons":
			# Aggregate all weapon types
			var total_dps = 0.0
			var max_range = 0.0
			var total_power = 0
			if "weapon_components" in ship:
				for w in ship.weapon_components:
					total_dps += w.damage * w.fire_rate
					max_range = max(max_range, w.rangeAim)
					result["count"] += 1
			# Get power from blueprint
			for comp_data in blueprint.components:
				var parsed = CosmoteerComponentDefs.parse_component_id(comp_data.get("type", ""))
				if parsed["type"] in ALL_WEAPON_TYPES:
					var comp_def = CosmoteerComponentDefs.get_component_data_by_level(parsed["type"], parsed["level"])
					total_power += comp_def.get("power_consumed", 0)
			result["total_dps"] = total_dps
			result["max_range"] = max_range
			result["power_consumed"] = total_power
		
		"laser_weapon":
			var total_damage = 0
			var total_power = 0
			# Count weapons and aggregate damage from ship
			if "weapon_components" in ship:
				for w in ship.weapon_components:
					if w.weapon_type == WeaponComponent.WeaponType.LASER:
						total_damage += w.damage
						result["count"] += 1
			# Aggregate power consumed from blueprint components
			for comp_data in blueprint.components:
				var parsed = CosmoteerComponentDefs.parse_component_id(comp_data.get("type", ""))
				if parsed["type"] == "laser_weapon":
					var comp_def = CosmoteerComponentDefs.get_component_data_by_level("laser_weapon", parsed["level"])
					total_power += comp_def.get("power_consumed", 0)
			result["total_damage"] = total_damage
			result["power_consumed"] = total_power
		
		"missile_launcher":
			var total_damage = 0
			var total_power = 0
			# Count weapons and aggregate damage from ship
			if "weapon_components" in ship:
				for w in ship.weapon_components:
					if w.weapon_type == WeaponComponent.WeaponType.MISSILE:
						total_damage += w.damage
						result["count"] += 1
			# Aggregate power consumed from blueprint components
			for comp_data in blueprint.components:
				var parsed = CosmoteerComponentDefs.parse_component_id(comp_data.get("type", ""))
				if parsed["type"] == "missile_launcher":
					var comp_def = CosmoteerComponentDefs.get_component_data_by_level("missile_launcher", parsed["level"])
					total_power += comp_def.get("power_consumed", 0)
			result["total_damage"] = total_damage
			result["power_consumed"] = total_power
		
		"shield_generator":
			if ship.has_method("get_shield_values"):
				var shield_vals = ship.get_shield_values()
				if shield_vals.get("max", 0) > 0:
					result["max_shield"] = shield_vals.get("max", 0)
					result["current_shield"] = shield_vals.get("current", 0)
					# Get power consumed from blueprint
					for comp_data in blueprint.components:
						var parsed = CosmoteerComponentDefs.parse_component_id(comp_data.get("type", ""))
						if parsed["type"] == "shield_generator":
							var comp_def = CosmoteerComponentDefs.get_component_data_by_level("shield_generator", parsed["level"])
							result["power_consumed"] = comp_def.get("power_consumed", 0)
							result["count"] = 1
							break
		
		"scanner":
			var scan_mult = 0.0
			var range_val = 0.0
			var total_power = 0
			if ship.has_method("get_scanner_components"):
				var scanners = ship.get_scanner_components()
				result["count"] = scanners.size()
				# Aggregate from blueprint components
				for comp_data in blueprint.components:
					var parsed = CosmoteerComponentDefs.parse_component_id(comp_data.get("type", ""))
					if parsed["type"] == "scanner":
						var comp_def = CosmoteerComponentDefs.get_component_data_by_level("scanner", parsed["level"])
						scan_mult += comp_def.get("scan_multiplier", 0.0)
						range_val = max(range_val, comp_def.get("range_px", 0.0))  # Max range
						total_power += comp_def.get("power_consumed", 0)
			result["scan_multiplier"] = scan_mult
			result["range"] = range_val
			result["power_consumed"] = total_power
		
		"miner":
			var total_mining_rate = 0.0
			var total_cargo_bonus = 0
			var range_val = 0.0
			var total_power = 0
			if ship.has_method("get_mining_components"):
				var miners = ship.get_mining_components()
				result["count"] = miners.size()
				# Aggregate from blueprint components
				for comp_data in blueprint.components:
					var parsed = CosmoteerComponentDefs.parse_component_id(comp_data.get("type", ""))
					if parsed["type"] == "miner":
						var comp_def = CosmoteerComponentDefs.get_component_data_by_level("miner", parsed["level"])
						total_mining_rate += comp_def.get("mining_rate", 0.0)
						total_cargo_bonus += comp_def.get("cargo_bonus", 0)
						range_val = max(range_val, comp_def.get("range_px", 0.0))  # Max range
						total_power += comp_def.get("power_consumed", 0)
			result["total_mining_rate"] = total_mining_rate
			result["total_cargo_bonus"] = total_cargo_bonus
			result["range"] = range_val
			result["power_consumed"] = total_power
		
		"repair_bot":
			var total_repair_rate = 0.0
			var total_power = 0
			for comp_data in blueprint.components:
				var parsed = CosmoteerComponentDefs.parse_component_id(comp_data.get("type", ""))
				if parsed["type"] == "repair_bot":
					var comp_def = CosmoteerComponentDefs.get_component_data_by_level("repair_bot", parsed["level"])
					total_repair_rate += comp_def.get("repair_rate", 0.0)
					total_power += comp_def.get("power_consumed", 0)
					result["count"] += 1
			result["total_repair_rate"] = total_repair_rate
			result["power_consumed"] = total_power
	
	return result

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	
	if event is InputEventKey and event.pressed:
		# Tab Switching
		if event.keycode in HOTKEY_MAPPING:
			var type = HOTKEY_MAPPING[event.keycode]
			if ship and ship.has_method("get_component_count") and _get_component_count(type) > 0:
				_on_tab_pressed(type)
				get_viewport().set_input_as_handled()
				return
		
		# Number Selection (1-9) - Toggles individual weapons or selects for others
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var idx = event.keycode - KEY_1
			var count = _get_component_count(current_type)
			if idx < count:
				# Toggle logic: If present, remove. If absent, add.
				# This matches user request "toggle on or off"
				var sel = selected_indices.get(current_type, []).duplicate()
				
				# Check if user is holding CTRL or if we are in weapon mode (multi-select default)
				# User requested toggling, so we treat it as multi-select toggle always for weapons?
				# Or stick to CTRL convention?
				# "press the key 1 or 2 or 3 ... the icon toggles" implies direct toggle.
				
				if idx in sel:
					sel.erase(idx)
				else:
					sel.append(idx)
				
				selected_indices[current_type] = sel
				selection_changed.emit(current_type, sel)
				_rebuild_list()
				_update_footer_content()
				get_viewport().set_input_as_handled()
