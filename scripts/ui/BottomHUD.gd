extends Panel
## Unified bottom HUD manager for all bottom panels
## Manages layout zones and panel visibility

# Zone references
@onready var left_zone: Control = $HBox/LeftZone
@onready var center_zone: Control = $HBox/CenterZone

# Panel references (to be set from GameScene)
var selected_units_panel: Panel = null
var command_ship_panel: Panel = null
var builder_drone_panel: Panel = null
var zone_switcher: Control = null
var minimap: Panel = null

# Current state
var current_center_panel: Panel = null

func _ready():
	# Set up proper mouse filtering
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Find and reparent panels
	await get_tree().process_frame
	setup_panels()

func setup_panels():
	"""Find and setup all bottom panels"""
	var ui_layer = get_parent()
	
	# Find panels in UILayer
	selected_units_panel = ui_layer.get_node_or_null("SelectedUnitsPanel")
	command_ship_panel = ui_layer.get_node_or_null("CommandShipPanel")
	builder_drone_panel = ui_layer.get_node_or_null("BuilderDronePanel")
	zone_switcher = ui_layer.get_node_or_null("ZoneSwitcher")
	minimap = ui_layer.get_node_or_null("Minimap")
	
	# Reparent main bottom panels to zones
	if selected_units_panel and left_zone:
		reparent_panel(selected_units_panel, left_zone)
	
	if command_ship_panel and center_zone:
		reparent_panel(command_ship_panel, center_zone)
	
	if builder_drone_panel and center_zone:
		reparent_panel(builder_drone_panel, center_zone)
	
	# ZoneSwitcher and Minimap stay in UILayer (positioned absolutely)
	# They need to extend above the 100px BottomHUD

func reparent_panel(panel: Node, new_parent: Control):
	"""Safely reparent a panel to a new zone"""
	if not is_instance_valid(panel) or not is_instance_valid(new_parent):
		return
	
	var old_parent = panel.get_parent()
	if old_parent:
		old_parent.remove_child(panel)
	
	new_parent.add_child(panel)
	
	# Reset positioning to fill zone
	panel.position = Vector2.ZERO
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

func show_command_ship_panel():
	"""Show command ship panel in center zone"""
	if command_ship_panel:
		hide_center_panels()
		command_ship_panel.visible = true
		current_center_panel = command_ship_panel

func show_builder_panel():
	"""Show builder drone panel in center zone"""
	if builder_drone_panel:
		hide_center_panels()
		builder_drone_panel.visible = true
		current_center_panel = builder_drone_panel

func hide_center_panels():
	"""Hide all center zone panels"""
	if command_ship_panel:
		command_ship_panel.visible = false
	if builder_drone_panel:
		builder_drone_panel.visible = false
	current_center_panel = null

func get_selected_units_panel() -> Panel:
	return selected_units_panel

func get_command_ship_panel() -> Panel:
	return command_ship_panel

func get_builder_drone_panel() -> Panel:
	return builder_drone_panel

func get_zone_switcher() -> Control:
	return zone_switcher

func get_minimap() -> Panel:
	return minimap

