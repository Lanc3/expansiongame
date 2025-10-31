extends Node
## Handles saving and loading game state

const SAVE_DIR = "user://saves/"
const SAVE_FILE = "save_game.json"

signal save_completed(success: bool)
signal load_completed(success: bool)

# Flag to prevent initial spawning when loading from save
var is_loading_save: bool = false

func _ready():
	# Ensure save directory exists
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)

func save_game() -> bool:
	"""Save the current game state to disk"""
	
	print("SaveLoadManager: Saving game - Current zone: %s" % (ZoneManager.current_zone_id if ZoneManager else "NONE"))
	
	var save_data = {
		"version": "2.2",  # Updated for zone network persistence
		"timestamp": Time.get_unix_time_from_system(),
		"game_time": GameManager.game_time,
		"current_zone_id": ZoneManager.current_zone_id if ZoneManager else "",
		"zone_network": _save_zone_network(),  # NEW: Save zone network data
		"resources": _save_resources(),
		"units": _save_units_by_zone(),
		"buildings": _save_buildings_by_zone(),
		"resource_nodes": _save_resource_nodes_by_zone(),
		"wormhole_positions": _save_wormhole_positions(),
		"control_groups": _save_control_groups(),
		"camera_position": _save_camera_position(),
		"fog_of_war": FogOfWarManager.save_fog_data() if FogOfWarManager else {},
		"planets": _save_planets(),
		"asteroid_orbits": _save_asteroid_orbits(),
		"research": _save_research(),
		"satellites": _save_satellites()
	}
	
	var json_string = JSON.stringify(save_data, "\t")
	
	var file = FileAccess.open(SAVE_DIR + SAVE_FILE, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing: " + str(FileAccess.get_open_error()))
		save_completed.emit(false)
		return false
	
	file.store_string(json_string)
	file.close()
	
	save_completed.emit(true)
	return true

func load_game() -> bool:
	"""Load game state from disk"""
	
	var file_path = SAVE_DIR + SAVE_FILE
	if not FileAccess.file_exists(file_path):
		push_error("Save file does not exist: " + file_path)
		load_completed.emit(false)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading: " + str(FileAccess.get_open_error()))
		load_completed.emit(false)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("Failed to parse save file JSON")
		load_completed.emit(false)
		return false
	
	var save_data = json.data
	
	# Set flag BEFORE reloading scene to prevent initial spawning
	is_loading_save = true
	
	# Load the game scene fresh
	GameManager.reset_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/GameScene.tscn")
	
	# Wait for scene to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Restore game state
	_load_game_state(save_data)
	
	# Clear flag after loading completes
	is_loading_save = false
	
	load_completed.emit(true)
	return true

func _save_resources() -> Dictionary:
	"""Save resource inventory"""
	var resources = {
		"resource_counts": ResourceManager.get_all_resource_counts(),
		"legacy_common": ResourceManager.common_material,
		"legacy_rare": ResourceManager.rare_material,
		"legacy_exotic": ResourceManager.exotic_material
	}
	
	return resources

func _save_units() -> Dictionary:
	"""Save all unit data (updated for zone system)"""
	return _save_units_by_zone()

func _save_units_by_zone() -> Dictionary:
	"""Save all units organized by zone"""
	var units_by_zone = {}
	
	if not EntityManager or not ZoneManager:
		return units_by_zone
	
	# Save units for each discovered zone
	for zone_id in ZoneManager.zones_by_id.keys():
		var zone_units = EntityManager.get_units_in_zone(zone_id)
		var units_data = []
		
		for unit in zone_units:
			if not is_instance_valid(unit):
				continue
			
			var unit_data = {
				"scene_path": unit.scene_file_path,
				"position": {
					"x": unit.global_position.x,
					"y": unit.global_position.y
				},
				"team_id": unit.team_id if "team_id" in unit else 0,
				"health": unit.current_health if "current_health" in unit else 100,
				"max_health": unit.max_health if "max_health" in unit else 100
			}
			
			# Save additional unit-specific data
			if unit.has_method("get_save_data"):
				unit_data["custom_data"] = unit.get_save_data()
			
			units_data.append(unit_data)
		
		if units_data.size() > 0:
			units_by_zone[str(zone_id)] = units_data
	
	return units_by_zone

func _save_buildings_by_zone() -> Dictionary:
	"""Save all buildings organized by zone"""
	var buildings_by_zone = {}
	
	if not EntityManager or not ZoneManager:
		return buildings_by_zone
	
	# Save buildings for each zone
	for zone_id in ZoneManager.zones_by_id.keys():
		var zone_buildings = EntityManager.get_buildings_in_zone(zone_id)
		var buildings_data = []
		
		for building in zone_buildings:
			if not is_instance_valid(building):
				continue
			
			# Get building type
			var building_type = "Unknown"
			if "building_type" in building:
				building_type = building.building_type
			elif building is ResearchBuilding:
				building_type = "ResearchBuilding"
			
			var building_data = {
				"type": building_type,
				"position": {
					"x": building.global_position.x,
					"y": building.global_position.y
				},
				"team_id": building.team_id if "team_id" in building else 0,
				"health": building.current_health if "current_health" in building else 100,
				"max_health": building.max_health if "max_health" in building else 100,
				"zone_id": zone_id
			}
			
			# Save additional building-specific data
			if building.has_method("get_save_data"):
				building_data["custom_data"] = building.get_save_data()
			
			buildings_data.append(building_data)
		
		if buildings_data.size() > 0:
			buildings_by_zone[str(zone_id)] = buildings_data
	
	print("SaveLoadManager: Saved %d buildings across all zones" % buildings_by_zone.size())
	return buildings_by_zone

func _save_zone_network() -> Dictionary:
	"""Save the zone network data for persistence"""
	if not ZoneManager:
		return {}
	
	var zones_data = []
	
	# Save each discovered zone's data
	for zone_id in ZoneManager.zones_by_id.keys():
		var zone = ZoneManager.get_zone(zone_id)
		if zone.is_empty():
			continue
		
		# Save zone metadata (without layer_node reference)
		var zone_data = {
			"zone_id": zone.zone_id,
			"difficulty": zone.difficulty,
			"zone_index": zone.get("zone_index", 0),  # CRITICAL: Needed for ring structure
			"procedural_name": zone.procedural_name,
			"discovered": zone.discovered,
			"ring_position": zone.ring_position,
			"size_multiplier": zone.size_multiplier,
			"spawn_area_size": zone.spawn_area_size,
			"max_resource_tier": zone.max_resource_tier
		}
		
		zones_data.append(zone_data)
	
	print("SaveLoadManager: Saved %d zones in network" % zones_data.size())
	
	return {
		"zone_network_seed": ZoneManager.zone_network_seed,
		"zones": zones_data
	}

func _save_control_groups() -> Dictionary:
	"""Save control group assignments"""
	var groups = {}
	
	if ControlGroupManager and ControlGroupManager.has_method("get_all_groups"):
		groups = ControlGroupManager.get_all_groups()
	elif ControlGroupManager and "control_groups" in ControlGroupManager:
		# Save control group unit indices or identifiers
		# This is simplified - actual implementation may need unit IDs
		for i in range(1, 10):
			if ControlGroupManager.control_groups.has(i):
				groups[str(i)] = ControlGroupManager.control_groups[i].size()
	
	return groups

func _save_camera_position() -> Dictionary:
	"""Save camera position"""
	var camera = get_viewport().get_camera_2d()
	if camera:
		return {
			"x": camera.global_position.x,
			"y": camera.global_position.y,
			"zoom_x": camera.zoom.x,
			"zoom_y": camera.zoom.y
		}
	return {}

func _load_game_state(save_data: Dictionary):
	"""Restore game state from save data"""
	
	# Extract the actual saved zone FIRST
	var saved_zone_id = save_data.get("current_zone_id", "")
	print("SaveLoadManager: Loading game with saved zone: %s" % saved_zone_id)
	
	# Restore zone network FIRST (before anything else)
	if save_data.has("zone_network") and ZoneManager:
		await _load_zone_network(save_data["zone_network"], saved_zone_id)
	
	# Wait for ZoneSetup to complete and create zone layers for loaded zones
	await get_tree().create_timer(0.9).timeout
	
	# Now update zone visibility for the correct current zone
	if ZoneManager:
		ZoneManager.update_zone_visibility()
		print("SaveLoadManager: Zone visibility updated for zone: %s" % ZoneManager.current_zone_id)
		
		# Explicitly sync ZoneProcessingManager with current zone
		if ZoneProcessingManager:
			print("SaveLoadManager: Syncing processing states for zone: %s" % ZoneManager.current_zone_id)
			ZoneProcessingManager.set_active_zone(ZoneManager.current_zone_id)
		
		# Debug: Print zone tracking info
		print("SaveLoadManager: Zones in network: %s" % str(ZoneManager.zones_by_id.keys()))
		print("SaveLoadManager: Current zone ID: %s" % ZoneManager.current_zone_id)
	
	# Clear any existing entities first (safety measure)
	_clear_existing_entities()
	
	# Restore game manager state
	if save_data.has("game_time"):
		GameManager.game_time = save_data["game_time"]
	
	# Restore resources
	if save_data.has("resources"):
		_load_resources(save_data["resources"])
	
	# Restore units (zone-aware)
	if save_data.has("units"):
		if save_data["units"] is Dictionary:
			_load_units_by_zone(save_data["units"])
		else:
			# Legacy format
			_load_units(save_data["units"])
	
	# Restore buildings (zone-aware)
	if save_data.has("buildings"):
		_load_buildings_by_zone(save_data["buildings"])
	
	# Restore resource nodes (zone-aware)
	if save_data.has("resource_nodes"):
		if save_data["resource_nodes"] is Dictionary:
			_load_resource_nodes_by_zone(save_data["resource_nodes"])
		else:
			# Legacy format
			_load_resource_nodes(save_data["resource_nodes"])
	
	# Restore wormholes (CRITICAL: Must be done after zones are loaded)
	if save_data.has("wormhole_positions"):
		await _load_wormhole_positions(save_data["wormhole_positions"])
	
	# Restore camera position (zone already switched earlier)
	if save_data.has("camera_position"):
		_load_camera_position(save_data["camera_position"], save_data.get("current_zone_id", ""))
	
	# Restore fog of war
	if save_data.has("fog_of_war") and FogOfWarManager:
		FogOfWarManager.load_fog_data(save_data["fog_of_war"])
	
	# Restore planets and asteroid orbits
	if save_data.has("planets"):
		_load_planets(save_data["planets"])
	
	# Restore research progress
	if save_data.has("research") and ResearchManager:
		_load_research(save_data["research"])
	
	# Restore satellites
	if save_data.has("satellites") and SatelliteManager:
		_load_satellites(save_data["satellites"])
	
	if save_data.has("asteroid_orbits"):
		_load_asteroid_orbits(save_data["asteroid_orbits"])
	

func _load_zone_network(zone_network_data: Dictionary, actual_current_zone: String = ""):
	"""Restore the zone network from save data"""
	if not zone_network_data or not ZoneManager:
		return
	
	print("SaveLoadManager: Restoring zone network...")
	
	# Restore zone network seed
	if zone_network_data.has("zone_network_seed"):
		ZoneManager.zone_network_seed = zone_network_data["zone_network_seed"]
		print("SaveLoadManager: Restored zone network seed: %d" % ZoneManager.zone_network_seed)
	
	# Clear existing zones and reinitialize with saved network
	ZoneManager.zones_by_id.clear()
	
	# Restore all discovered zones
	if zone_network_data.has("zones"):
		for zone_data in zone_network_data["zones"]:
			# Recreate zone data structure
			var zone = {
				"zone_id": zone_data.zone_id,
				"difficulty": int(zone_data.difficulty),
				"zone_index": int(zone_data.get("zone_index", 0)),  # CRITICAL: Needed for ring structure (must be int for modulo)
				"procedural_name": zone_data.procedural_name,
				"discovered": zone_data.discovered,
				"ring_position": zone_data.ring_position,
				"size_multiplier": zone_data.size_multiplier,
				"spawn_area_size": zone_data.spawn_area_size,
				"max_resource_tier": zone_data.max_resource_tier,
				"layer_node": null,  # Will be set by ZoneSetup
				"lateral_wormholes": [],  # Will be populated by wormhole loading
				"depth_wormholes": [],  # Will be populated by wormhole loading
				"boundaries": ZoneManager.calculate_zone_boundaries(int(zone_data.difficulty))  # Calculate boundaries properly!
			}
			
			ZoneManager.zones_by_id[zone_data.zone_id] = zone
			print("SaveLoadManager: Restored zone %s with boundaries: %s" % [zone_data.zone_id, zone.boundaries])
		
		print("SaveLoadManager: Restored %d zones to network" % zone_network_data["zones"].size())
		
		# Set to ACTUAL current zone from save, not first zone
		if not actual_current_zone.is_empty():
			ZoneManager.current_zone_id = actual_current_zone
			print("SaveLoadManager: Set current_zone_id to saved value: %s" % actual_current_zone)
		elif ZoneManager.current_zone_id.is_empty() and zone_network_data["zones"].size() > 0:
			ZoneManager.current_zone_id = zone_network_data["zones"][0].zone_id
			print("SaveLoadManager: Set current_zone_id to first zone (fallback): %s" % ZoneManager.current_zone_id)
	
	# Now trigger ZoneSetup to create zone layers for ALL discovered zones
	await get_tree().process_frame
	
	var zone_setup = get_tree().root.find_child("ZoneSetup", true, false)
	if zone_setup:
		if zone_setup.has_method("create_zone_layers_for_loaded_zones"):
			var num_zones = zone_network_data.get("zones", []).size()
			print("SaveLoadManager: Triggering ZoneSetup to create layers for %d loaded zones..." % num_zones)
			zone_setup.create_zone_layers_for_loaded_zones()
		else:
			print("SaveLoadManager: ERROR - ZoneSetup doesn't have create_zone_layers_for_loaded_zones method!")
	else:
		print("SaveLoadManager: ERROR - ZoneSetup not found!")

func _load_resources(resources_data: Dictionary):
	"""Restore resource inventory"""
	# Restore new resource system
	if resources_data.has("resource_counts"):
		var counts = resources_data["resource_counts"]
		for i in range(min(counts.size(), 100)):
			ResourceManager.set_resource_count(i, counts[i])
	
	# Restore legacy system
	if resources_data.has("legacy_common"):
		ResourceManager.common_material = resources_data["legacy_common"]
	if resources_data.has("legacy_rare"):
		ResourceManager.rare_material = resources_data["legacy_rare"]
	if resources_data.has("legacy_exotic"):
		ResourceManager.exotic_material = resources_data["legacy_exotic"]
	
	# Emit signals
	ResourceManager.resources_changed.emit(
		ResourceManager.common_material,
		ResourceManager.rare_material,
		ResourceManager.exotic_material
	)

func _load_units(units_data: Array):
	"""Restore all units"""
	print("SaveLoadManager: Loading ", units_data.size(), " units...")
	
	for unit_data in units_data:
		if not unit_data.has("scene_path"):
			continue
		
		var unit_scene = load(unit_data["scene_path"])
		if not unit_scene:
			push_error("Failed to load unit scene: " + unit_data["scene_path"])
			continue
		
		var unit = unit_scene.instantiate()
		
		# Set position
		if unit_data.has("position"):
			unit.global_position = Vector2(unit_data["position"]["x"], unit_data["position"]["y"])
		
		# Set team
		if unit_data.has("team_id") and "team_id" in unit:
			unit.team_id = unit_data["team_id"]
		
		# Set health
		if unit_data.has("health") and "current_health" in unit:
			unit.current_health = unit_data["health"]
		if unit_data.has("max_health") and "max_health" in unit:
			unit.max_health = unit_data["max_health"]
		
		# Restore custom data
		if unit_data.has("custom_data") and unit.has_method("load_save_data"):
			unit.load_save_data(unit_data["custom_data"])
		
		# Add to scene
		var units_container = get_tree().root.find_child("Units", true, false)
		if units_container:
			units_container.add_child(unit)
			
			# Register with EntityManager
			if EntityManager.has_method("register_unit"):
				EntityManager.register_unit(unit)
	

func _load_camera_position(camera_data: Dictionary, saved_zone_id: String = ""):
	"""Restore camera position and zone"""
	await get_tree().process_frame
	
	var camera = get_viewport().get_camera_2d()
	if not camera:
		print("SaveLoadManager: ERROR - Camera not found!")
		return
	
	print("SaveLoadManager: _load_camera_position called with zone: %s" % saved_zone_id)
	
	# Switch to saved zone first
	if not saved_zone_id.is_empty() and ZoneManager:
		print("SaveLoadManager: Camera switching to saved zone: %s (current: %s)" % [saved_zone_id, ZoneManager.current_zone_id])
		# Only switch if not already in correct zone
		if ZoneManager.current_zone_id != saved_zone_id:
			ZoneManager.switch_to_zone(saved_zone_id)
			await get_tree().process_frame
		else:
			# Already in correct zone, but need to set camera bounds manually
			var zone = ZoneManager.get_zone(saved_zone_id)
			if not zone.is_empty() and camera.has_method("set_zone_bounds"):
				camera.set_zone_bounds(zone.boundaries)
				print("SaveLoadManager: Set camera bounds for zone: %s" % saved_zone_id)
			
			# Manually update UI systems since zone_switched signal wasn't emitted
			print("SaveLoadManager: Manually updating UI systems for zone: %s" % saved_zone_id)
			
			# Update FogOverlay
			var fog_overlay = get_tree().root.find_child("FogOverlay", true, false)
			if fog_overlay and fog_overlay.has_method("_on_zone_switched"):
				fog_overlay._on_zone_switched("", saved_zone_id)
			
			# Update Minimap
			var minimap = get_tree().root.find_child("Minimap", true, false)
			if minimap and minimap.has_method("_on_zone_switched"):
				minimap._on_zone_switched("", saved_zone_id)
			
			# Update ZoneSwitcher UI
			var zone_switcher = get_tree().root.find_child("ZoneSwitcher", true, false)
			if zone_switcher and zone_switcher.has_method("_on_zone_switched"):
				zone_switcher._on_zone_switched("", saved_zone_id)
		print("SaveLoadManager: Zone switch complete, current zone: %s" % ZoneManager.current_zone_id)
	else:
		print("SaveLoadManager: WARNING - No zone ID to switch to (saved_zone_id: '%s')" % saved_zone_id)
	
	# Restore camera position and zoom
	if camera_data.has("x") and camera_data.has("y"):
		camera.global_position = Vector2(camera_data["x"], camera_data["y"])
		print("SaveLoadManager: Camera positioned at %s" % camera.global_position)
	
	if camera_data.has("zoom_x") and camera_data.has("zoom_y"):
		camera.zoom = Vector2(camera_data["zoom_x"], camera_data["zoom_y"])
	
	# Ensure zone visibility is correct after all loading
	await get_tree().process_frame
	print("SaveLoadManager: Final zone visibility update after load complete")
	ZoneManager.update_zone_visibility()


func _save_resource_nodes() -> Array:
	"""Save resource node data (legacy, kept for compatibility)"""
	return []

func _save_resource_nodes_by_zone() -> Dictionary:
	"""Save resource nodes organized by zone"""
	var resources_by_zone = {}
	
	if not EntityManager or not ZoneManager:
		return resources_by_zone
	
	# Save resources for each zone
	for zone_id in ZoneManager.zones_by_id.keys():
		var zone_resources = EntityManager.get_resources_in_zone(zone_id)
		var resources_data = []
		
		for resource in zone_resources:
			if not is_instance_valid(resource):
				continue
			
			var resource_data = {
				"scene_path": resource.scene_file_path,
				"position": {
					"x": resource.global_position.x,
					"y": resource.global_position.y
				}
			}
			
			# Save resource-specific data
			if "resource_composition" in resource:
				resource_data["resource_composition"] = resource.resource_composition
			if "total_resources" in resource:
				resource_data["total_resources"] = resource.total_resources
			if "remaining_resources" in resource:
				resource_data["remaining_resources"] = resource.remaining_resources
			if "depleted" in resource:
				resource_data["depleted"] = resource.depleted
			if "is_scanned" in resource:
				resource_data["is_scanned"] = resource.is_scanned
			if "sprite_color_set" in resource:
				resource_data["sprite_color_set"] = resource.sprite_color_set
			if "base_scale" in resource:
				resource_data["base_scale"] = resource.base_scale
			
			# Save orbital data (for planetary orbits)
			if resource.has_meta("orbital_planet_position"):
				resource_data["orbital_planet_position"] = {
					"x": resource.get_meta("orbital_planet_position").x,
					"y": resource.get_meta("orbital_planet_position").y
				}
			if resource.has_meta("orbital_radius"):
				resource_data["orbital_radius"] = resource.get_meta("orbital_radius")
			if resource.has_meta("orbital_angle"):
				resource_data["orbital_angle"] = resource.get_meta("orbital_angle")
			
			resources_data.append(resource_data)
		
		if resources_data.size() > 0:
			resources_by_zone[str(zone_id)] = resources_data
	
	return resources_by_zone

func _save_wormhole_positions() -> Dictionary:
	"""Save wormhole positions for each zone"""
	var wormholes_data = {}
	
	if not ZoneManager:
		return wormholes_data
	
	for zone_id in ZoneManager.zones_by_id.keys():  # All discovered zones
		var zone = ZoneManager.get_zone(zone_id)
		if zone.is_empty():
			continue
		
		# Save all wormholes in this zone (both lateral and depth)
		var zone_wormholes = []
		var all_wormholes = zone.lateral_wormholes + zone.depth_wormholes
		for wormhole in all_wormholes:
			if is_instance_valid(wormhole):
				var wormhole_data = {
					"x": wormhole.global_position.x,
					"y": wormhole.global_position.y,
					"target_zone_id": wormhole.target_zone_id,
					"source_zone_id": wormhole.source_zone_id,
					"wormhole_type": wormhole.wormhole_type,
					"is_undiscovered": wormhole.is_undiscovered
				}
				# Save direction for lateral wormholes
				if "wormhole_direction" in wormhole:
					wormhole_data["wormhole_direction"] = wormhole.wormhole_direction
				# Save forward flag for depth wormholes
				if wormhole.has_meta("is_forward"):
					wormhole_data["is_forward"] = wormhole.get_meta("is_forward")
				
				zone_wormholes.append(wormhole_data)
		
		if zone_wormholes.size() > 0:
			wormholes_data[str(zone_id)] = zone_wormholes
	
	print("SaveLoadManager: Saved %d zones with wormholes" % wormholes_data.size())
	return wormholes_data

func _load_wormhole_positions(wormholes_data: Dictionary):
	"""Load and recreate wormholes for each zone"""
	if not ZoneManager:
		return
	
	print("SaveLoadManager: Loading wormholes...")
	
	var wormhole_scene = load("res://scenes/world/Wormhole.tscn")
	if not wormhole_scene:
		push_error("Failed to load Wormhole scene!")
		return
	
	var total_wormholes = 0
	
	for zone_id_str in wormholes_data.keys():
		var zone_id = zone_id_str
		var zone = ZoneManager.get_zone(zone_id)
		
		if zone.is_empty() or not zone.layer_node:
			print("SaveLoadManager: WARNING - Zone '%s' not ready for wormhole loading" % zone_id)
			continue
		
		var wormholes_container = zone.layer_node.get_node_or_null("Wormholes")
		if not wormholes_container:
			print("SaveLoadManager: WARNING - No Wormholes container in zone '%s'" % zone_id)
			continue
		
		# Clear existing wormholes (if any)
		for child in wormholes_container.get_children():
			child.queue_free()
		
		# Clear wormhole arrays in zone data
		zone.lateral_wormholes.clear()
		zone.depth_wormholes.clear()
		
		# Load wormholes for this zone
		for wormhole_data in wormholes_data[zone_id_str]:
			var wormhole = wormhole_scene.instantiate()
			
			# Set wormhole properties BEFORE adding to scene
			wormhole.source_zone_id = wormhole_data.get("source_zone_id", zone_id)
			wormhole.target_zone_id = wormhole_data.get("target_zone_id", "")
			wormhole.wormhole_type = wormhole_data.get("wormhole_type", Wormhole.WormholeType.DEPTH)
			wormhole.is_undiscovered = wormhole_data.get("is_undiscovered", false)
			
			# Restore additional metadata
			if wormhole_data.has("wormhole_direction"):
				wormhole.wormhole_direction = wormhole_data["wormhole_direction"]
			if wormhole_data.has("is_forward"):
				wormhole.set_meta("is_forward", wormhole_data["is_forward"])
			
			# Add to scene
			wormholes_container.add_child(wormhole)
			
			# Set position AFTER adding to scene
			wormhole.global_position = Vector2(wormhole_data["x"], wormhole_data["y"])
			
			# Wait for wormhole to initialize
			await get_tree().process_frame
			
			# Register with ZoneManager
			if wormhole.wormhole_type == Wormhole.WormholeType.LATERAL:
				zone.lateral_wormholes.append(wormhole)
			else:
				zone.depth_wormholes.append(wormhole)
			
			total_wormholes += 1
		
		print("SaveLoadManager: Loaded %d wormholes for zone '%s'" % [wormholes_data[zone_id_str].size(), zone_id])
	
	print("SaveLoadManager: Loaded %d total wormholes across %d zones" % [total_wormholes, wormholes_data.size()])

func _load_resource_nodes(resources_data: Array):
	"""Restore resource nodes"""
	print("SaveLoadManager: Loading ", resources_data.size(), " resource nodes...")
	
	for resource_data in resources_data:
		if not resource_data.has("scene_path"):
			continue
		
		var resource_scene = load(resource_data["scene_path"])
		if not resource_scene:
			push_error("Failed to load resource scene: " + resource_data["scene_path"])
			continue
		
		var resource = resource_scene.instantiate()
		
		# Set resource data BEFORE adding to scene (so _ready() can check if data exists)
		if resource_data.has("resource_composition") and "resource_composition" in resource:
			# Convert regular Array to typed Array[Dictionary] to avoid type mismatch
			var composition_array: Array[Dictionary] = []
			for item in resource_data["resource_composition"]:
				if item is Dictionary:
					composition_array.append(item)
			resource.resource_composition = composition_array
		if resource_data.has("total_resources") and "total_resources" in resource:
			resource.total_resources = resource_data["total_resources"]
		if resource_data.has("remaining_resources") and "remaining_resources" in resource:
			resource.remaining_resources = resource_data["remaining_resources"]
		if resource_data.has("depleted") and "depleted" in resource:
			resource.depleted = resource_data["depleted"]
		if resource_data.has("is_scanned") and "is_scanned" in resource:
			resource.is_scanned = resource_data["is_scanned"]
		if resource_data.has("sprite_color_set") and "sprite_color_set" in resource:
			resource.sprite_color_set = resource_data["sprite_color_set"]
		if resource_data.has("base_scale") and "base_scale" in resource:
			resource.base_scale = resource_data["base_scale"]
		
		# Restore orbital data (must happen after adding to scene)
		var orbital_planet_pos: Vector2 = Vector2.ZERO
		var orbital_radius: float = 0.0
		var orbital_angle: float = 0.0
		var has_orbital_data = false
		
		if resource_data.has("orbital_planet_position"):
			orbital_planet_pos = Vector2(
				resource_data["orbital_planet_position"]["x"],
				resource_data["orbital_planet_position"]["y"]
			)
			has_orbital_data = true
		if resource_data.has("orbital_radius"):
			orbital_radius = resource_data["orbital_radius"]
		if resource_data.has("orbital_angle"):
			orbital_angle = resource_data["orbital_angle"]
		
		# Set position
		if resource_data.has("position"):
			resource.global_position = Vector2(
				resource_data["position"]["x"],
				resource_data["position"]["y"]
			)
		
		# Add to scene (this triggers _ready())
		var resources_container = get_tree().root.find_child("Resources", true, false)
		if resources_container:
			resources_container.add_child(resource)
			
			# Register with EntityManager
			if EntityManager.has_method("register_resource"):
				EntityManager.register_resource(resource)
			
			# Restore orbital mechanics if data exists
			if has_orbital_data and OrbitalManager:
				OrbitalManager.restore_asteroid_orbit(resource, orbital_planet_pos, orbital_radius, orbital_angle)
	

func _clear_existing_entities():
	"""Clear all existing units and resources before loading"""
	
	# Clear units
	if EntityManager and "units" in EntityManager:
		for unit in EntityManager.units.duplicate():
			if is_instance_valid(unit):
				unit.queue_free()
		EntityManager.units.clear()
	
	# Clear resources
	if EntityManager and "resources" in EntityManager:
		for resource in EntityManager.resources.duplicate():
			if is_instance_valid(resource):
				resource.queue_free()
		EntityManager.resources.clear()
	
	# Wait a frame for queue_free to process
	await get_tree().process_frame
	

func has_save_file() -> bool:
	"""Check if a save file exists"""
	return FileAccess.file_exists(SAVE_DIR + SAVE_FILE)

func delete_save_file() -> bool:
	"""Delete the save file"""
	var file_path = SAVE_DIR + SAVE_FILE
	if FileAccess.file_exists(file_path):
		var dir = DirAccess.open(SAVE_DIR)
		return dir.remove(SAVE_FILE) == OK
	return false

func get_save_info() -> Dictionary:
	"""Get information about the save file without loading it"""
	if not has_save_file():
		return {}
	
	var file = FileAccess.open(SAVE_DIR + SAVE_FILE, FileAccess.READ)
	if file == null:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {}
	
	var save_data = json.data
	
	return {
		"timestamp": save_data.get("timestamp", 0),
		"game_time": save_data.get("game_time", 0),
		"version": save_data.get("version", "unknown")
	}

func _load_units_by_zone(units_by_zone: Dictionary):
	"""Restore units to their respective zones"""
	
	for zone_id_str in units_by_zone.keys():
		var zone_id = zone_id_str  # Zone IDs are now strings, no conversion needed
		var units_data = units_by_zone[zone_id_str]
		
		var zone = ZoneManager.get_zone(zone_id)
		if zone.is_empty() or not zone.layer_node:
			continue
		
		var units_container = zone.layer_node.get_node_or_null("Entities/Units")
		if not units_container:
			continue
		
		for unit_data in units_data:
			if not unit_data.has("scene_path"):
				continue
			
			var unit_scene = load(unit_data["scene_path"])
			if not unit_scene:
				push_error("Failed to load unit scene: " + unit_data["scene_path"])
				continue
			
			var unit = unit_scene.instantiate()
			
			# Set position BEFORE adding to scene
			var unit_pos = Vector2(unit_data["position"]["x"], unit_data["position"]["y"]) if unit_data.has("position") else Vector2.ZERO
			unit.global_position = unit_pos
			print("SaveLoadManager: Loading unit to zone %s at position %s" % [zone_id, unit_pos])
			
			# Set team
			if unit_data.has("team_id") and "team_id" in unit:
				unit.team_id = unit_data["team_id"]
			
			# Set health
			if unit_data.has("health") and "current_health" in unit:
				unit.current_health = unit_data["health"]
			if unit_data.has("max_health") and "max_health" in unit:
				unit.max_health = unit_data["max_health"]
			
			# Add to zone's units container FIRST (needed for proper initialization)
			units_container.add_child(unit)
			
			# Register with EntityManager with explicit zone_id
			if EntityManager.has_method("register_unit"):
				EntityManager.register_unit(unit, zone_id)
			
			# Restore custom data AFTER adding to scene (blueprint ships need scene tree access)
			if unit_data.has("custom_data"):
				if unit.has_method("restore_from_save_data"):
					unit.restore_from_save_data(unit_data["custom_data"])
				elif unit.has_method("load_save_data"):
					unit.load_save_data(unit_data["custom_data"])
	

func _load_buildings_by_zone(buildings_by_zone: Dictionary):
	"""Restore buildings to their respective zones"""
	
	for zone_id_str in buildings_by_zone.keys():
		var zone_id = zone_id_str  # Zone IDs are now strings, no conversion needed
		var buildings_data = buildings_by_zone[zone_id_str]
		
		var zone = ZoneManager.get_zone(zone_id)
		if zone.is_empty() or not zone.layer_node:
			continue
		
		var buildings_container = zone.layer_node.get_node_or_null("Entities/Buildings")
		if not buildings_container:
			continue
		
		for building_data in buildings_data:
			if not building_data.has("type"):
				continue
			
			var building_type = building_data["type"]
			
			# Get building scene from BuildingDatabase
			var building_info = BuildingDatabase.get_building_data(building_type)
			if building_info.is_empty() or not building_info.has("scene"):
				continue
			
			var building_scene = load(building_info["scene"])
			if not building_scene:
				push_error("Failed to load building scene: " + building_info["scene"])
				continue
			
			var building = building_scene.instantiate()
			
			# Set position
			if building_data.has("position"):
				building.global_position = Vector2(building_data["position"]["x"], building_data["position"]["y"])
			
			# Set team
			if building_data.has("team_id") and "team_id" in building:
				building.team_id = building_data["team_id"]
			
			# Set health
			if building_data.has("health") and "current_health" in building:
				building.current_health = building_data["health"]
			if building_data.has("max_health") and "max_health" in building:
				building.max_health = building_data["max_health"]
			
			# Set zone
			if building_data.has("zone_id") and "zone_id" in building:
				building.zone_id = building_data["zone_id"]
			
			# Restore custom data
			if building_data.has("custom_data") and building.has_method("load_save_data"):
				building.load_save_data(building_data["custom_data"])
			
			# Add to zone's buildings container
			buildings_container.add_child(building)
			
			# Register with EntityManager
			if EntityManager.has_method("register_building"):
				EntityManager.register_building(building)
			
	

func _load_resource_nodes_by_zone(resources_by_zone: Dictionary):
	"""Restore resource nodes to their respective zones"""
	
	for zone_id_str in resources_by_zone.keys():
		var zone_id = zone_id_str  # Zone IDs are now strings, no conversion needed
		var resources_data = resources_by_zone[zone_id_str]
		
		var zone = ZoneManager.get_zone(zone_id)
		if zone.is_empty() or not zone.layer_node:
			continue
		
		var resources_container = zone.layer_node.get_node_or_null("Entities/Resources")
		if not resources_container:
			continue
		
		for resource_data in resources_data:
			if not resource_data.has("scene_path"):
				continue
			
			var resource_scene = load(resource_data["scene_path"])
			if not resource_scene:
				push_error("Failed to load resource scene: " + resource_data["scene_path"])
				continue
			
			var resource = resource_scene.instantiate()
			
			# Set resource data BEFORE adding to scene
			if resource_data.has("resource_composition") and "resource_composition" in resource:
				var composition_array: Array[Dictionary] = []
				for item in resource_data["resource_composition"]:
					if item is Dictionary:
						composition_array.append(item)
				resource.resource_composition = composition_array
			if resource_data.has("total_resources") and "total_resources" in resource:
				resource.total_resources = resource_data["total_resources"]
			if resource_data.has("remaining_resources") and "remaining_resources" in resource:
				resource.remaining_resources = resource_data["remaining_resources"]
			if resource_data.has("depleted") and "depleted" in resource:
				resource.depleted = resource_data["depleted"]
			if resource_data.has("is_scanned") and "is_scanned" in resource:
				resource.is_scanned = resource_data["is_scanned"]
			if resource_data.has("sprite_color_set") and "sprite_color_set" in resource:
				resource.sprite_color_set = resource_data["sprite_color_set"]
			if resource_data.has("base_scale") and "base_scale" in resource:
				resource.base_scale = resource_data["base_scale"]
			
			# Set position
			if resource_data.has("position"):
				resource.global_position = Vector2(
					resource_data["position"]["x"],
					resource_data["position"]["y"]
				)
			
			# Add to zone's resources container
			resources_container.add_child(resource)
			
			# Register with EntityManager
			if EntityManager.has_method("register_resource"):
				EntityManager.register_resource(resource, zone_id)
	

func _save_planets() -> Dictionary:
	"""Save all planet data"""
	var planets_data = {}
	
	# Get all planets in all zones
	for zone_id in ZoneManager.zones_by_id.keys():
		var zone = ZoneManager.get_zone(zone_id)
		if zone.is_empty() or not zone.layer_node:
			continue
		
		var planets_container = zone.layer_node.get_node_or_null("Planets")
		if not planets_container:
			continue
		
		var zone_planets = []
		for planet in planets_container.get_children():
			if is_instance_valid(planet) and planet.has_method("get"):
				var planet_data = {
					"position": {"x": planet.global_position.x, "y": planet.global_position.y},
					"scale": {"x": planet.scale.x, "y": planet.scale.y},
					"rotation": planet.rotation,
					"texture_path": planet.texture.resource_path if planet.texture else "",
					"zone_id": planet.zone_id if planet.has_method("get") and "zone_id" in planet else zone_id
				}
				zone_planets.append(planet_data)
		
		if zone_planets.size() > 0:
			planets_data[str(zone_id)] = zone_planets
	
	print("SaveLoadManager: Saved %d zones with planets" % planets_data.size())
	return planets_data

func _save_asteroid_orbits() -> Dictionary:
	"""Save all asteroid orbital data"""
	var orbits_data = {}
	
	# Get all resource nodes (asteroids) with orbital data
	for zone_id in ZoneManager.zones_by_id.keys():
		var zone_resources = EntityManager.get_resources_in_zone(zone_id)
		var zone_orbits = []
		
		for resource in zone_resources:
			if not is_instance_valid(resource):
				continue
			
			# Check if this resource has orbital data
			if resource.has_meta("orbital_planet_position") and resource.has_meta("orbital_radius") and resource.has_meta("orbital_angle"):
				var orbit_data = {
					"resource_position": {"x": resource.global_position.x, "y": resource.global_position.y},
					"orbital_planet_position": {"x": resource.get_meta("orbital_planet_position").x, "y": resource.get_meta("orbital_planet_position").y},
					"orbital_radius": resource.get_meta("orbital_radius"),
					"orbital_angle": resource.get_meta("orbital_angle"),
					"resource_type": resource.resource_type if "resource_type" in resource else "unknown",
					"resource_amount": resource.resource_amount if "resource_amount" in resource else 100
				}
				zone_orbits.append(orbit_data)
		
		if zone_orbits.size() > 0:
			orbits_data[str(zone_id)] = zone_orbits
	
	print("SaveLoadManager: Saved %d zones with orbital asteroids" % orbits_data.size())
	return orbits_data

func _load_planets(planets_data: Dictionary):
	"""Load planet data and recreate planets"""
	
	for zone_id_str in planets_data.keys():
		var zone_id = zone_id_str  # Zone IDs are now strings, no conversion needed
		var zone = ZoneManager.get_zone(zone_id)
		if zone.is_empty() or not zone.layer_node:
			continue
		
		# Get or create planets container
		var planets_container = zone.layer_node.get_node_or_null("Planets")
		if not planets_container:
			planets_container = Node2D.new()
			planets_container.name = "Planets"
			zone.layer_node.add_child(planets_container)
		
		# Clear existing planets in this zone
		for planet in planets_container.get_children():
			planet.queue_free()
		
		# Recreate planets from save data
		var planet_scene = preload("res://scenes/world/Planet.tscn")
		for planet_data in planets_data[zone_id_str]:
			var planet = planet_scene.instantiate()
			planets_container.add_child(planet)
			
			# Set planet properties
			planet.global_position = Vector2(planet_data["position"]["x"], planet_data["position"]["y"])
			planet.scale = Vector2(planet_data["scale"]["x"], planet_data["scale"]["y"])
			planet.rotation = planet_data["rotation"]
			planet.zone_id = planet_data["zone_id"]
			
			# Load texture
			if planet_data["texture_path"] != "":
				var texture = load(planet_data["texture_path"])
				if texture:
					planet.texture = texture
			
			# Add to planets group
			planet.add_to_group("planets")
		
		print("SaveLoadManager: Loaded %d planets for Zone %s" % [planets_data[zone_id_str].size(), zone_id])

func _load_asteroid_orbits(orbits_data: Dictionary):
	"""Load asteroid orbital data and restore orbits"""
	
	for zone_id_str in orbits_data.keys():
		var zone_id = zone_id_str  # Zone IDs are now strings, no conversion needed
		var zone_resources = EntityManager.get_resources_in_zone(zone_id)
		
		for orbit_data in orbits_data[zone_id_str]:
			# Find the resource node at this position
			var target_position = Vector2(orbit_data["resource_position"]["x"], orbit_data["resource_position"]["y"])
			var found_resource = null
			
			for resource in zone_resources:
				if is_instance_valid(resource) and resource.global_position.distance_to(target_position) < 50:
					found_resource = resource
					break
			
			if found_resource:
				# Restore orbital metadata
				var planet_pos = Vector2(orbit_data["orbital_planet_position"]["x"], orbit_data["orbital_planet_position"]["y"])
				found_resource.set_meta("orbital_planet_position", planet_pos)
				found_resource.set_meta("orbital_radius", orbit_data["orbital_radius"])
				found_resource.set_meta("orbital_angle", orbit_data["orbital_angle"])
				
				# Restore orbit with OrbitalManager
				if OrbitalManager:
					OrbitalManager.restore_asteroid_orbit(found_resource, planet_pos, orbit_data["orbital_radius"], orbit_data["orbital_angle"])
		
		print("SaveLoadManager: Restored %d orbital asteroids for Zone %s" % [orbits_data[zone_id_str].size(), zone_id])

# ============================================================================
# RESEARCH SYSTEM SAVE/LOAD
# ============================================================================

func _save_research() -> Dictionary:
	"""Save research progress"""
	if not ResearchManager:
		return {}
	
	return ResearchManager.get_save_data()

func _load_research(data: Dictionary):
	"""Load research progress"""
	if not ResearchManager:
		return
	
	ResearchManager.load_save_data(data)

# ============================================================================
# SATELLITE SYSTEM SAVE/LOAD
# ============================================================================

func _save_satellites() -> Dictionary:
	"""Save deployed satellites"""
	if not SatelliteManager:
		return {}
	
	return SatelliteManager.get_save_data()

func _load_satellites(data: Dictionary):
	"""Load deployed satellites"""
	if not SatelliteManager:
		return
	
	SatelliteManager.load_save_data(data)
