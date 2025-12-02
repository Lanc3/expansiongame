extends StaticBody2D
class_name Shipyard

signal ship_production_started(blueprint_name: String)
signal ship_production_completed(ship: Node2D)
signal production_queue_updated()
signal building_selected()
signal building_deselected()
signal building_destroyed()

# Building properties
@export var max_health: float = 1500.0
@export var team_id: int = 0  # Player team
@export var zone_id: String = ""

var current_health: float
var is_selected: bool = false
var is_destroyed: bool = false
var is_under_construction: bool = false
var construction_progress: float = 0.0
var building_name: String = "Shipyard"
var building_type: String = "Shipyard"

# Production queue
var production_queue: Array[CosmoteerShipBlueprint] = []
var current_production: Dictionary = {}  # {blueprint, progress, build_time}
var is_producing: bool = false
var production_timer: float = 0.0

const MAX_QUEUE_SIZE = 5

func _ready():
	current_health = max_health
	add_to_group("buildings")
	add_to_group("player_buildings")
	
	# Register with EntityManager
	if EntityManager:
		EntityManager.register_building(self, zone_id)
	
	# Connect to zone manager for ship spawning
	if ZoneManager:
		ZoneManager.zone_switched.connect(_on_zone_switched)
	
	print("Shipyard _ready() called at position: ", global_position)

func _process(delta: float):
	# Handle production
	if is_producing and not current_production.is_empty():
		production_timer += delta
		var progress = production_timer / current_production.get("build_time", 1.0)
		
		if progress >= 1.0:
			_complete_current_production()
	
	# Always update UI if panel is open (for both producing and idle states)
	_update_shipyard_panel_progress()

func add_to_queue(blueprint: CosmoteerShipBlueprint) -> bool:
	"""Add a blueprint to the production queue"""
	print("Shipyard: add_to_queue() called for: ", blueprint.blueprint_name)
	
	if production_queue.size() >= MAX_QUEUE_SIZE:
		print("Shipyard: Queue is full")
		if FeedbackManager:
			FeedbackManager.show_message("Production queue is full!")
		return false
	
	# Check global unit limit
	var current_units = EntityManager.get_units_by_team(0).size()
	var queued_count = production_queue.size()
	if is_producing:
		queued_count += 1
		
	if (current_units + queued_count) >= GameManager.MAX_PLAYER_UNITS:
		if FeedbackManager:
			FeedbackManager.show_message("Unit limit reached!")
		return false
	
	# Validate blueprint
	print("Shipyard: Validating blueprint...")
	var validation_errors = validate_blueprint(blueprint)
	if not validation_errors.is_empty():
		print("Shipyard: Validation failed: ", validation_errors)
		if FeedbackManager:
			FeedbackManager.show_message("Invalid blueprint: " + validation_errors.join(", "))
		return false
	print("Shipyard: Validation passed")
	
	# Check resource costs
	var cost = CosmoteerShipStatsCalculator.calculate_cost(blueprint)
	print("Shipyard: Blueprint cost: ", cost)
	if not can_afford_cost(cost):
		print("Shipyard: Cannot afford cost")
		if FeedbackManager:
			FeedbackManager.show_message("Insufficient resources!")
		return false
	print("Shipyard: Can afford cost")
	
	# Deduct resources
	deduct_blueprint_cost(cost)
	print("Shipyard: Resources deducted")
	
	# Add to queue
	production_queue.append(blueprint)
	production_queue_updated.emit()
	print("Shipyard: Blueprint added to queue. Queue size: ", production_queue.size())
	
	# Start production if idle
	if not is_producing:
		print("Shipyard: Starting production...")
		_start_next_production()
	
	if FeedbackManager:
		FeedbackManager.show_message("Ship queued for construction!")
	
	print("Shipyard: add_to_queue() completed successfully")
	return true

func validate_blueprint(blueprint: CosmoteerShipBlueprint) -> Array[String]:
	"""Validate blueprint meets minimum requirements"""
	var errors: Array[String] = []
	
	if blueprint.hull_cells.is_empty():
		errors.append("No hull cells")
	
	# Calculate individual stats
	var power = CosmoteerShipStatsCalculator.calculate_power(blueprint)
	var weight_thrust = CosmoteerShipStatsCalculator.calculate_weight_thrust(blueprint)
	
	# Count components
	var num_power_cores = CosmoteerShipStatsCalculator.count_components_by_type(blueprint, "power_core")
	var num_engines = CosmoteerShipStatsCalculator.count_components_by_type(blueprint, "engine")
	var num_lasers = CosmoteerShipStatsCalculator.count_components_by_type(blueprint, "laser_weapon")
	var num_missiles = CosmoteerShipStatsCalculator.count_components_by_type(blueprint, "missile_launcher")
	var num_weapons = num_lasers + num_missiles
	
	if num_power_cores < 1:
		errors.append("Requires at least 1 Power Core")
	
	if num_engines < 1:
		errors.append("Requires at least 1 Engine")
	
	if num_weapons < 1:
		errors.append("Requires at least 1 Weapon")
	
	if power.get("generated", 0) < power.get("consumed", 0):
		errors.append("Power deficit")
	
	var total_thrust = weight_thrust.get("thrust", 0)
	var total_weight = weight_thrust.get("weight", 1)
	var thrust_ratio = float(total_thrust) / max(1.0, float(total_weight))
	if thrust_ratio < 1.0:
		errors.append("Insufficient thrust")
	
	return errors

func can_afford_cost(cost: Dictionary) -> bool:
	"""Check if player can afford the blueprint cost"""
	if not ResourceManager:
		return false
	
	for resource_id in cost.keys():
		var required = cost[resource_id]
		var available = ResourceManager.get_resource_count(resource_id)
		if available < required:
			return false
	
	return true

func deduct_blueprint_cost(cost: Dictionary):
	"""Deduct resources for blueprint construction"""
	if not ResourceManager:
		return
	
	for resource_id in cost.keys():
		var amount = cost[resource_id]
		ResourceManager.remove_resource(resource_id, amount)

func calculate_build_time(blueprint: CosmoteerShipBlueprint) -> float:
	"""Calculate build time based on blueprint complexity"""
	var base_time = 60.0  # 60 seconds base
	var hull_cells = blueprint.get_hull_cell_count()
	var component_count = blueprint.components.size()
	
	# +5 seconds per hull cell, +10 seconds per component
	var complexity_time = hull_cells * 5.0 + component_count * 10.0
	
	# Apply research bonuses (placeholder)
	var research_bonus = 1.0
	if ResearchManager:
		# Could add ship construction speed research
		pass
	
	return (base_time + complexity_time) * research_bonus

func _start_next_production():
	"""Start producing the next ship in queue"""
	if production_queue.is_empty():
		is_producing = false
		return
	
	var blueprint = production_queue.pop_front()
	var build_time = calculate_build_time(blueprint)
	
	current_production = {
		"blueprint": blueprint,
		"build_time": build_time,
		"progress": 0.0
	}
	
	is_producing = true
	production_timer = 0.0
	
	ship_production_started.emit(blueprint.blueprint_name)
	production_queue_updated.emit()
	
	print("Shipyard: Starting production of '%s' (%.1f seconds)" % [blueprint.blueprint_name, build_time])

func _complete_current_production():
	"""Complete the current ship production"""
	if current_production.is_empty():
		return
	
	var blueprint = current_production.get("blueprint")
	if not blueprint:
		return
	
	# Spawn the ship
	var ship = spawn_ship(blueprint)
	if ship:
		ship_production_completed.emit(ship)
		print("Shipyard: Completed production of '%s'" % blueprint.blueprint_name)
	
	# Clear current production
	current_production.clear()
	is_producing = false
	production_timer = 0.0
	
	# Start next production if queue has items
	if not production_queue.is_empty():
		_start_next_production()
	else:
		production_queue_updated.emit()

func spawn_ship(blueprint: CosmoteerShipBlueprint) -> Node2D:
	"""Spawn a ship from blueprint near the shipyard"""
	# Load CustomShip scene
	var ship_scene = load("res://scenes/units/CustomShip.tscn")
	if not ship_scene:
		print("Shipyard: Could not load CustomShip scene")
		return null
	
	var ship = ship_scene.instantiate()
	
	# Position near shipyard (offset to avoid overlap)
	var spawn_offset = Vector2(100, 0).rotated(randf() * TAU)  # Random direction
	ship.global_position = global_position + spawn_offset
	ship.team_id = 0  # Player team
	
	# Add to shipyard's zone (not current viewing zone!)
	var spawn_zone_id = zone_id  # Use shipyard's zone_id property
	var zone_layer = ZoneManager.get_zone(spawn_zone_id).layer_node if ZoneManager else null
	
	if zone_layer:
		var units_container = zone_layer.get_node_or_null("Entities/Units")
		if units_container:
			units_container.add_child(ship)
			
			# Initialize from blueprint AFTER adding to scene tree
			if ship.has_method("initialize_from_cosmoteer_blueprint"):
				ship.initialize_from_cosmoteer_blueprint(blueprint)
			
			# Register with EntityManager
			if EntityManager:
				EntityManager.register_unit(ship, spawn_zone_id)
			
			print("Shipyard: Ship '%s' spawned in Zone %s at %s with %d weapons" % [blueprint.blueprint_name, spawn_zone_id, ship.global_position, ship.get_weapon_count() if ship.has_method("get_weapon_count") else 0])
			return ship
	
	print("Shipyard: Failed to spawn ship - no valid zone")
	ship.queue_free()
	return null

func cancel_queue_item(index: int) -> bool:
	"""Cancel a specific item in the production queue"""
	if index < 0 or index >= production_queue.size():
		return false
	
	# Refund resources for cancelled item
	var blueprint = production_queue[index]
	var cost = CosmoteerShipStatsCalculator.calculate_cost(blueprint)
	refund_blueprint_cost(cost)
	
	production_queue.remove_at(index)
	production_queue_updated.emit()
	
	if FeedbackManager:
		FeedbackManager.show_message("Ship construction cancelled")
	
	return true

func refund_blueprint_cost(cost: Dictionary):
	"""Refund resources for cancelled blueprint"""
	if not ResourceManager:
		return
	
	for resource_id in cost.keys():
		var amount = cost[resource_id]
		ResourceManager.add_resource(resource_id, amount)

func get_production_progress() -> float:
	"""Get current production progress (0.0 to 1.0)"""
	if not is_producing or current_production.is_empty():
		return 0.0
	
	return production_timer / current_production.get("build_time", 1.0)

func get_queue_info() -> Dictionary:
	"""Get information about the production queue"""
	return {
		"queue": production_queue.duplicate(),
		"current_production": current_production.duplicate(),
		"is_producing": is_producing,
		"progress": get_production_progress()
	}

func _update_shipyard_panel_progress():
	"""Update the shipyard panel UI with current production progress"""
	# Find panel - it could be in UILayer or root
	var panel = null
	var game_scene = get_tree().current_scene
	if game_scene:
		var ui_layer = game_scene.get_node_or_null("UILayer")
		if ui_layer:
			panel = ui_layer.get_node_or_null("ShipyardPanel")
	
	if not panel:
		panel = get_tree().root.get_node_or_null("ShipyardPanel")
	
	if not panel:
		# Panel not open, don't update
		return
	
	# Update progress label
	var progress_label = panel.get_node_or_null("VBox/ProgressLabel")
	if progress_label:
		if is_producing and not current_production.is_empty():
			var current_bp = current_production.get("blueprint")
			var build_time = current_production.get("build_time", 1.0)
			var time_remaining = max(0.0, build_time - production_timer)
			progress_label.text = "Building: %s\nTime Remaining: %.0fs" % [current_bp.blueprint_name if current_bp else "Unknown", time_remaining]
		else:
			progress_label.text = "Idle - Select a Blueprint"
	
	# Update progress bar
	var progress_bar = panel.get_node_or_null("VBox/ProgressBar")
	if progress_bar:
		progress_bar.value = get_production_progress() * 100.0
	
	# Update queue list (throttle this to avoid recreating every frame)
	# Only update queue list once per second
	if not has_meta("last_queue_update") or Time.get_ticks_msec() - get_meta("last_queue_update") > 1000:
		set_meta("last_queue_update", Time.get_ticks_msec())
		
		var queue_scroll = panel.get_node_or_null("VBox/QueueScroll")
		if queue_scroll:
			var queue_list = queue_scroll.get_node_or_null("QueueList")
			if queue_list:
				# Clear existing items
				for child in queue_list.get_children():
					child.queue_free()
				
				# Add current production
				if is_producing and not current_production.is_empty():
					var current_bp = current_production.get("blueprint")
					if current_bp:
						var current_item = Label.new()
						current_item.text = "🔧 Building: %s (%.0f%%)" % [current_bp.blueprint_name, get_production_progress() * 100]
						current_item.modulate = Color(0.3, 1.0, 0.3)  # Green for active
						queue_list.add_child(current_item)
				
				# Add queued ships
				for i in range(production_queue.size()):
					var blueprint = production_queue[i]
					var item_label = Label.new()
					item_label.text = "%d. %s (Queued)" % [i + 1, blueprint.blueprint_name]
					item_label.modulate = Color(0.8, 0.8, 0.8)  # Gray for queued
					queue_list.add_child(item_label)

func _on_zone_switched(old_zone: String, new_zone: String):
	"""Handle zone switching - pause production if shipyard not in current zone"""
	# For now, allow production to continue across zones
	# Could implement zone-specific shipyards if needed
	pass

func on_clicked():
	"""Handle building click - open shipyard UI"""
	print("Shipyard on_clicked() called!")
	
	if is_under_construction:
		print("Shipyard is under construction")
		if FeedbackManager:
			FeedbackManager.show_message("Shipyard is still under construction")
		return
	
	print("Opening shipyard panel...")
	# Open shipyard panel
	open_shipyard_panel()

func open_shipyard_panel():
	"""Open the shipyard UI panel - create dynamically to avoid loading issues"""
	print("open_shipyard_panel: Starting...")
	
	# Check if panel already exists
	var existing_panel = get_tree().root.get_node_or_null("ShipyardPanel")
	if existing_panel:
		print("open_shipyard_panel: Found existing panel, removing it")
		existing_panel.queue_free()
	
	# Create panel dynamically
	print("open_shipyard_panel: Creating panel dynamically...")
	var panel = create_shipyard_panel_ui()
	
	if not panel:
		push_error("Failed to create ShipyardPanel")
		return
	
	print("open_shipyard_panel: Panel created, adding to UI layer...")
	
	# Try to find UILayer in current scene
	var game_scene = get_tree().current_scene
	var ui_layer = null
	
	if game_scene:
		ui_layer = game_scene.get_node_or_null("UILayer")
		if ui_layer:
			print("open_shipyard_panel: Found UILayer, adding panel there")
			ui_layer.add_child(panel)
		else:
			print("open_shipyard_panel: No UILayer found, adding to game scene: ", game_scene.name)
			game_scene.add_child(panel)
	else:
		print("open_shipyard_panel: No current scene, adding to root")
		get_tree().root.add_child(panel)
	
	# Force update to ensure it's visible
	panel.show()
	panel.move_to_front()
	
	print("open_shipyard_panel: Panel added to tree")
	print("open_shipyard_panel: Panel visible: ", panel.visible)
	print("open_shipyard_panel: Panel position: ", panel.position)
	print("open_shipyard_panel: Panel global position: ", panel.global_position)
	print("open_shipyard_panel: Panel size: ", panel.size)
	print("Shipyard panel opened successfully!")

func create_shipyard_panel_ui() -> PanelContainer:
	"""Create the shipyard UI panel programmatically"""
	var panel = PanelContainer.new()
	panel.name = "ShipyardPanel"
	panel.custom_minimum_size = Vector2(400, 500)
	panel.position = Vector2(820, 100)
	panel.size = Vector2(400, 500)
	panel.z_index = 100
	panel.top_level = true  # Make it independent of parent transform
	panel.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure it receives mouse input
	
	# Create VBox container
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Shipyard - Ship Construction"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Select Blueprint Button
	var select_btn = Button.new()
	select_btn.text = "Select Blueprint"
	select_btn.custom_minimum_size = Vector2(0, 40)
	select_btn.pressed.connect(_on_shipyard_select_blueprint.bind(self))
	vbox.add_child(select_btn)
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Progress Label
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	if is_producing and not current_production.is_empty():
		var current_bp = current_production.get("blueprint")
		var build_time = current_production.get("build_time", 1.0)
		var time_remaining = build_time - production_timer
		progress_label.text = "Building: %s\nTime Remaining: %.0fs" % [current_bp.blueprint_name if current_bp else "Unknown", time_remaining]
	else:
		progress_label.text = "Idle - Select a Blueprint"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(progress_label)
	
	# Progress Bar
	var progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.max_value = 100.0
	progress_bar.value = get_production_progress() * 100.0
	progress_bar.show_percentage = true
	progress_bar.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(progress_bar)
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Queue Label
	var queue_label = Label.new()
	queue_label.text = "Production Queue:"
	vbox.add_child(queue_label)
	
	# Queue Scroll Container
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 250)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var queue_list = VBoxContainer.new()
	queue_list.name = "QueueList"
	scroll.add_child(queue_list)
	
	# Display current production if active
	if is_producing and not current_production.is_empty():
		var current_bp = current_production.get("blueprint")
		if current_bp:
			var current_item = Label.new()
			current_item.text = "🔧 Building: %s (%.0f%%)" % [current_bp.blueprint_name, get_production_progress() * 100]
			current_item.modulate = Color(0.3, 1.0, 0.3)  # Green for active
			queue_list.add_child(current_item)
	
	# Display queued ships
	for i in range(production_queue.size()):
		var blueprint = production_queue[i]
		var item_label = Label.new()
		item_label.text = "%d. %s (Queued)" % [i + 1, blueprint.blueprint_name]
		item_label.modulate = Color(0.8, 0.8, 0.8)  # Gray for queued
		queue_list.add_child(item_label)
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Close Button
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(_on_shipyard_close.bind(panel))
	vbox.add_child(close_btn)
	
	print("create_shipyard_panel_ui: Panel created with ", vbox.get_child_count(), " children")
	return panel

func _on_shipyard_select_blueprint(shipyard: Shipyard):
	"""Handle blueprint selection button"""
	print("Shipyard: Select blueprint button pressed")
	
	# Create blueprint library UI dynamically
	var library = create_blueprint_library_ui()
	if not library:
		print("Shipyard: Failed to create blueprint library")
		if FeedbackManager:
			FeedbackManager.show_message("No blueprints available")
		return
	
	# Add to UI layer
	var game_scene = get_tree().current_scene
	var ui_layer = null
	if game_scene:
		ui_layer = game_scene.get_node_or_null("UILayer")
	
	if ui_layer:
		ui_layer.add_child(library)
	else:
		get_tree().root.add_child(library)
	
	print("Shipyard: Blueprint library opened")

func create_blueprint_library_ui() -> PanelContainer:
	"""Create blueprint library UI dynamically"""
	print("create_blueprint_library_ui: Starting...")
	
	# Get blueprint files
	var blueprint_files = BlueprintPaths.get_all_blueprint_files()
	print("create_blueprint_library_ui: Found ", blueprint_files.size(), " blueprint files")
	
	if blueprint_files.is_empty():
		if FeedbackManager:
			FeedbackManager.show_message("No blueprints found. Create one in the Blueprint Builder!")
		return null
	
	# Load blueprints
	var blueprints: Array[CosmoteerShipBlueprint] = []
	for file_path in blueprint_files:
		print("create_blueprint_library_ui: Loading: ", file_path)
		var blueprint = BlueprintPaths.load_blueprint(file_path)
		if blueprint:
			blueprints.append(blueprint)
			print("create_blueprint_library_ui: Loaded: ", blueprint.blueprint_name)
	
	if blueprints.is_empty():
		if FeedbackManager:
			FeedbackManager.show_message("No valid blueprints found")
		return null
	
	# Create panel
	var panel = PanelContainer.new()
	panel.name = "BlueprintLibrary"
	panel.custom_minimum_size = Vector2(500, 600)
	panel.position = Vector2(390, 60)
	panel.size = Vector2(500, 600)
	panel.z_index = 110
	panel.top_level = true
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Select Blueprint"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	# Scroll container for blueprints
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 480)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var list = VBoxContainer.new()
	scroll.add_child(list)
	
	# Add button for each blueprint
	for blueprint in blueprints:
		var item_vbox = VBoxContainer.new()
		item_vbox.custom_minimum_size = Vector2(0, 80)
		
		# Name button
		var btn = Button.new()
		btn.text = blueprint.blueprint_name
		btn.custom_minimum_size = Vector2(0, 40)
		btn.pressed.connect(_on_blueprint_library_selected.bind(blueprint, panel))
		item_vbox.add_child(btn)
		
		# Stats preview
		var power = CosmoteerShipStatsCalculator.calculate_power(blueprint)
		var weight_thrust = CosmoteerShipStatsCalculator.calculate_weight_thrust(blueprint)
		var cost = CosmoteerShipStatsCalculator.calculate_cost(blueprint)
		
		var stats_label = Label.new()
		var power_text = "Power: %d/%d" % [power.get("generated", 0), power.get("consumed", 0)]
		var thrust_text = "Thrust: %d Weight: %d" % [weight_thrust.get("thrust", 0), weight_thrust.get("weight", 0)]
		var cost_text = "Cost: " + _format_blueprint_cost(cost)
		stats_label.text = power_text + " | " + thrust_text + "\n" + cost_text
		stats_label.add_theme_font_size_override("font_size", 10)
		stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_vbox.add_child(stats_label)
		
		list.add_child(item_vbox)
	
	vbox.add_child(HSeparator.new())
	
	# Cancel button
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 40)
	cancel_btn.pressed.connect(_on_blueprint_library_cancelled.bind(panel))
	vbox.add_child(cancel_btn)
	
	print("create_blueprint_library_ui: Created library with ", blueprints.size(), " blueprints")
	return panel

func _on_blueprint_library_selected(blueprint: CosmoteerShipBlueprint, panel: PanelContainer):
	"""Handle blueprint selected from library"""
	print("Shipyard: _on_blueprint_library_selected() called")
	print("Shipyard: Blueprint selected: ", blueprint.blueprint_name)
	print("Shipyard: Closing library panel...")
	panel.queue_free()
	print("Shipyard: Calling _on_blueprint_selected_for_queue()...")
	_on_blueprint_selected_for_queue(blueprint)

func _on_blueprint_library_cancelled(panel: PanelContainer):
	"""Handle library cancelled"""
	print("Shipyard: Blueprint library cancelled")
	panel.queue_free()

func _format_blueprint_cost(cost: Dictionary) -> String:
	"""Format cost dictionary for display"""
	if cost.is_empty():
		return "Free"
	var parts: Array[String] = []
	for res_id in cost.keys():
		var res_name = ResourceDatabase.get_resource_name(res_id) if ResourceDatabase else "Res%d" % res_id
		parts.append("%s:%d" % [res_name, cost[res_id]])
	return ", ".join(parts)

func _on_blueprint_selected_for_queue(blueprint: CosmoteerShipBlueprint):
	"""Handle blueprint selected from library"""
	print("Shipyard: _on_blueprint_selected_for_queue() called")
	print("Shipyard: Blueprint selected: ", blueprint.blueprint_name)
	print("Shipyard: Calling add_to_queue()...")
	var success = add_to_queue(blueprint)
	print("Shipyard: add_to_queue() returned: ", success)
	
	# Refresh the panel if it's open
	var panel = get_tree().root.get_node_or_null("ShipyardPanel")
	if panel:
		print("Shipyard: Refreshing shipyard panel...")
		panel.queue_free()
		call_deferred("open_shipyard_panel")
	else:
		print("Shipyard: No shipyard panel found to refresh")

func _on_shipyard_close(panel: PanelContainer):
	"""Close the shipyard panel"""
	print("Shipyard: Closing panel")
	if is_instance_valid(panel):
		panel.queue_free()

func set_selected(selected: bool):
	"""Set building selection state"""
	print("Shipyard set_selected() called with: ", selected)
	is_selected = selected
	if selected:
		building_selected.emit()
	else:
		building_deselected.emit()

func take_damage(amount: float, _attacker: Node2D = null):
	"""Apply damage to building"""
	if is_destroyed:
		return
	
	current_health -= amount
	
	if current_health <= 0:
		destroy()

func destroy():
	"""Destroy the building"""
	if is_destroyed:
		return
	
	is_destroyed = true
	building_destroyed.emit()
	
	# Cancel production
	production_queue.clear()
	current_production.clear()
	is_producing = false
	
	# Cleanup
	if EntityManager:
		EntityManager.unregister_building(self)
	
	queue_free()

func set_construction_progress(progress: float):
	"""Update construction progress"""
	construction_progress = clamp(progress, 0.0, 1.0)
	is_under_construction = progress < 1.0

func complete_construction():
	"""Complete building construction"""
	is_under_construction = false
	construction_progress = 1.0
	print("Shipyard construction complete!")

func get_building_info() -> Dictionary:
	"""Get building information for UI"""
	return {
		"name": building_name,
		"type": building_type,
		"health": current_health,
		"max_health": max_health,
		"is_producing": is_producing,
		"queue_size": production_queue.size()
	}

func get_save_data() -> Dictionary:
	"""Get save data for shipyard-specific state"""
	# Note: position, health, zone_id are handled by SaveLoadManager
	return {
		"is_under_construction": is_under_construction,
		"construction_progress": construction_progress,
		"is_producing": is_producing,
		"production_timer": production_timer,
		"current_production": current_production.duplicate(),
		# Note: production_queue blueprints can't be easily serialized
		# Users will need to re-queue ships after loading
	}

func load_save_data(data: Dictionary):
	"""Load save data for shipyard-specific state"""
	# Note: position, health, zone_id are handled by SaveLoadManager
	if data.has("is_under_construction"):
		is_under_construction = data.is_under_construction
	if data.has("construction_progress"):
		construction_progress = data.construction_progress
	if data.has("is_producing"):
		is_producing = data.is_producing
	if data.has("production_timer"):
		production_timer = data.production_timer
	if data.has("current_production"):
		current_production = data.current_production.duplicate()
	
	# Note: Production queue is not saved (blueprint resources can't serialize easily)
	# Clear any production state if no current production
	if current_production.is_empty():
		is_producing = false
		production_timer = 0.0
