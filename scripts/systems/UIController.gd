extends Node
## Controls UI interactions and connections

@onready var asteroid_info_panel: PanelContainer = null
@onready var wormhole_info_panel: Panel = null
@onready var travel_animation: CanvasLayer = null
@onready var command_ship_panel: Panel = null
@onready var tech_tree_ui: Control = null
@onready var builder_drone_panel: Panel = null

func _ready():
	# Find the asteroid info panel
	asteroid_info_panel = get_tree().root.find_child("AsteroidInfoPanel", true, false)
	
	if not asteroid_info_panel:
		push_warning("AsteroidInfoPanel not found in scene")
	
	# Find the wormhole info panel
	wormhole_info_panel = get_tree().root.find_child("WormholeInfoPanel", true, false)
	
	if not wormhole_info_panel:
		push_warning("WormholeInfoPanel not found in scene")
	else:
		# Connect to wormhole panel signals
		if wormhole_info_panel.has_signal("travel_requested"):
			wormhole_info_panel.travel_requested.connect(_on_wormhole_travel_requested)
	
	# Find travel animation
	travel_animation = get_tree().root.find_child("WormholeTravelEffect", true, false)
	
	if not travel_animation:
		push_warning("WormholeTravelEffect not found in scene")
	else:
		if travel_animation.has_signal("travel_complete"):
			travel_animation.travel_complete.connect(_on_travel_complete)
	
	# Find command ship panel
	command_ship_panel = get_tree().root.find_child("CommandShipPanel", true, false)
	
	if not command_ship_panel:
		push_warning("CommandShipPanel not found in scene")
	
	# Find tech tree UI
	tech_tree_ui = get_tree().root.find_child("TechTreeUI", true, false)
	
	if not tech_tree_ui:
		push_warning("TechTreeUI not found in scene")
	
	# Find builder drone panel
	builder_drone_panel = get_tree().root.find_child("BuilderDronePanel", true, false)
	
	if not builder_drone_panel:
		push_warning("BuilderDronePanel not found in scene")
	
	# Connect to selection manager signals
	SelectionManager.asteroid_selected.connect(_on_asteroid_selected)
	SelectionManager.asteroid_deselected.connect(_on_asteroid_deselected)
	SelectionManager.selection_changed.connect(_on_selection_changed)
	SelectionManager.building_selected.connect(_on_building_selected)
	SelectionManager.building_deselected.connect(_on_building_deselected)
	
	# Connect to wormhole selections
	connect_wormhole_signals()
	
	print("UIController ready - connected to SelectionManager")

func _on_asteroid_selected(asteroid: ResourceNode):
	"""Show asteroid info panel when asteroid selected"""
	if asteroid_info_panel and asteroid_info_panel.has_method("show_asteroid"):
		asteroid_info_panel.show_asteroid(asteroid)

func _on_asteroid_deselected():
	"""Hide asteroid info panel when deselected"""
	if asteroid_info_panel and asteroid_info_panel.has_method("hide_panel"):
		asteroid_info_panel.hide_panel()

func connect_wormhole_signals():
	"""Connect to all wormhole selection signals in the scene"""
	await get_tree().process_frame  # Wait for wormholes to be ready
	
	var wormholes = get_tree().get_nodes_in_group("wormholes")
	for wormhole in wormholes:
		if wormhole.has_signal("wormhole_selected"):
			if not wormhole.wormhole_selected.is_connected(_on_wormhole_selected):
				wormhole.wormhole_selected.connect(_on_wormhole_selected)

func _on_wormhole_selected(wormhole):
	"""Show wormhole info panel when wormhole selected"""
	print("UIController: Wormhole selected")
	
	if wormhole_info_panel and wormhole_info_panel.has_method("show_for_wormhole"):
		wormhole_info_panel.show_for_wormhole(wormhole)

func _on_wormhole_travel_requested(target_zone_id: int):
	"""Handle travel button press - start cinematic travel"""
	print("UIController: Travel requested to Zone %d" % target_zone_id)
	
	if not travel_animation or not travel_animation.has_method("play_travel_animation"):
		push_error("Travel animation not available")
		# Fallback to instant travel
		ZoneManager.switch_to_zone(target_zone_id)
		return
	
	# Get current zone for animation
	var from_zone_id = ZoneManager.current_zone_id
	
	# Play cinematic travel animation
	travel_animation.play_travel_animation(from_zone_id, target_zone_id)

func _on_travel_complete():
	"""Handle travel animation completion"""
	print("UIController: Travel animation complete")
	# Animation system will have switched zones, we just finalize here

func _on_selection_changed(selected_units: Array):
	"""Handle selection changes - show appropriate panel"""
	# Check if single unit selected
	if selected_units.size() == 1:
		var unit = selected_units[0]
		if is_instance_valid(unit):
			# Check if it's the command ship
			if "is_command_ship" in unit and unit.is_command_ship:
				if command_ship_panel and command_ship_panel.has_method("show_for_command_ship"):
					command_ship_panel.show_for_command_ship(unit)
					hide_builder_panel()
					return
			
			# Check if it's a builder drone
			if unit is BuilderDrone:
				if builder_drone_panel and builder_drone_panel.has_method("show_for_builder"):
					builder_drone_panel.show_for_builder(unit)
					hide_command_ship_panel()
					return
	
	# Hide panels when nothing special is selected
	hide_command_ship_panel()
	hide_builder_panel()

func hide_command_ship_panel():
	"""Hide the command ship panel"""
	if command_ship_panel:
		command_ship_panel.visible = false

func hide_builder_panel():
	"""Hide the builder drone panel"""
	if builder_drone_panel:
		builder_drone_panel.visible = false

func _on_building_selected(building: Node2D):
	"""Handle building selection - show tech tree for Research Buildings"""
	if not is_instance_valid(building):
		return
	
	# Check if it's a Research Building
	if building is ResearchBuilding:
		if tech_tree_ui and tech_tree_ui.has_method("show_for_building"):
			tech_tree_ui.show_for_building(building)
			print("UIController: Showing tech tree for Research Building")

func _on_building_deselected():
	"""Handle building deselection - hide tech tree"""
	if tech_tree_ui and tech_tree_ui.has_method("hide_tree"):
		tech_tree_ui.hide_tree()
