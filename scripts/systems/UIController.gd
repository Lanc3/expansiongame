extends Node
## Controls UI interactions and connections

@onready var asteroid_info_panel: PanelContainer = null
@onready var wormhole_info_panel: Panel = null
@onready var travel_animation: CanvasLayer = null
@onready var command_ship_panel: Panel = null
@onready var tech_tree_ui: Control = null
@onready var builder_drone_panel: Panel = null
@onready var bottom_hud: Panel = null

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
	
	# Find bottom HUD manager
	bottom_hud = get_tree().root.find_child("BottomHUD", true, false)
	
	# Get panels from bottom HUD if available
	if bottom_hud and bottom_hud.has_method("get_command_ship_panel"):
		await get_tree().process_frame  # Wait for BottomHUD to setup
		command_ship_panel = bottom_hud.get_command_ship_panel()
		builder_drone_panel = bottom_hud.get_builder_drone_panel()
	else:
		# Fallback to finding panels directly
		command_ship_panel = get_tree().root.find_child("CommandShipPanel", true, false)
		builder_drone_panel = get_tree().root.find_child("BuilderDronePanel", true, false)
	
	if not command_ship_panel:
		push_warning("CommandShipPanel not found in scene")
	
	if not builder_drone_panel:
		push_warning("BuilderDronePanel not found in scene")
	
	# Find tech tree UI
	tech_tree_ui = get_tree().root.find_child("TechTreeUI", true, false)
	
	if not tech_tree_ui:
		push_warning("TechTreeUI not found in scene")
	
	# Connect to selection manager signals
	SelectionManager.asteroid_selected.connect(_on_asteroid_selected)
	SelectionManager.asteroid_deselected.connect(_on_asteroid_deselected)
	SelectionManager.selection_changed.connect(_on_selection_changed)
	SelectionManager.building_selected.connect(_on_building_selected)
	SelectionManager.building_deselected.connect(_on_building_deselected)
	
	# Connect to wormhole selections
	connect_wormhole_signals()
	

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
	
	if wormhole_info_panel and wormhole_info_panel.has_method("show_for_wormhole"):
		wormhole_info_panel.show_for_wormhole(wormhole)

func _on_wormhole_travel_requested(target_zone_id: String):
	"""Handle travel button press - start cinematic travel"""
	
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
					if bottom_hud and bottom_hud.has_method("show_command_ship_panel"):
						bottom_hud.show_command_ship_panel()
					else:
						hide_builder_panel()
					return
			
			# Check if it's a builder drone
			if unit is BuilderDrone:
				if builder_drone_panel and builder_drone_panel.has_method("show_for_builder"):
					builder_drone_panel.show_for_builder(unit)
					if bottom_hud and bottom_hud.has_method("show_builder_panel"):
						bottom_hud.show_builder_panel()
					else:
						hide_command_ship_panel()
					return
	
	# Hide panels when nothing special is selected
	if bottom_hud and bottom_hud.has_method("hide_center_panels"):
		bottom_hud.hide_center_panels()
	else:
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
	"""Handle building selection - show appropriate UI for each building type"""
	print("UIController: Building selected - ", building)
	
	if not is_instance_valid(building):
		print("UIController: Building not valid!")
		return
	
	# Check if it's a Research Building
	if building is ResearchBuilding:
		print("UIController: It's a ResearchBuilding")
		if tech_tree_ui and tech_tree_ui.has_method("show_for_building"):
			tech_tree_ui.show_for_building(building)
	
	# Check if it's a Shipyard
	elif building is Shipyard:
		print("UIController: It's a Shipyard, calling on_clicked()")
		if building.has_method("on_clicked"):
			building.on_clicked()
		else:
			print("UIController: Shipyard doesn't have on_clicked method!")
	else:
		print("UIController: Building type not recognized: ", building.get_class())

func _on_building_deselected():
	"""Handle building deselection - hide tech tree"""
	if tech_tree_ui and tech_tree_ui.has_method("hide_tree"):
		tech_tree_ui.hide_tree()
