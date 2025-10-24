extends Node
## Manages blueprint components, validation, costing, and build/save

signal blueprint_saved(name: String)
signal blueprint_built(data: Dictionary)
signal unlocked_components_changed()

var unlocked_component_ids: Array[String] = []

func _ready():
	if ResearchManager and ResearchManager.has_signal("research_unlocked"):
		ResearchManager.research_unlocked.connect(_on_research_unlocked)
	_recompute_unlocked_components()

func _on_research_unlocked(_rid: String):
	_recompute_unlocked_components()
	unlocked_components_changed.emit()

func _recompute_unlocked_components():
	unlocked_component_ids.clear()
	for comp in BlueprintDatabase.get_all_components():
		var ok := true
		for rid in comp.research_ids:
			if not ResearchManager.is_unlocked(rid):
				ok = false
				break
		if ok:
			unlocked_component_ids.append(comp.id)

func is_component_unlocked(component_id: String) -> bool:
	return component_id in unlocked_component_ids

func compute_total_cost(placements: Array) -> Dictionary:
	var total := {}
	for p in placements:
		var comp := BlueprintDatabase.get_component_by_id(p.id)
		if comp.is_empty():
			continue
		for res_id in comp.cost.keys():
			if res_id in total:
				total[res_id] += comp.cost[res_id]
			else:
				total[res_id] = comp.cost[res_id]
	return total

func validate_layout(placements: Array, grid_cols: int, grid_rows: int) -> Dictionary:
	# Build occupancy grid of categories
	var hull_cells: = {}
	var engine_count := 0
	var core_count := 0
	
	for p in placements:
		var comp := BlueprintDatabase.get_component_by_id(p.id)
		if comp.is_empty():
			continue
		var size: Vector2i = comp.size
		var origin: Vector2i = Vector2i(p.x, p.y)
		# Bounds
		if origin.x < 0 or origin.y < 0 or origin.x + size.x > grid_cols or origin.y + size.y > grid_rows:
			return { ok = false, reason = "Out of bounds" }
		# Occupy cells
		for cx in range(size.x):
			for cy in range(size.y):
				var cell := Vector2i(origin.x + cx, origin.y + cy)
				if comp.category == "hull":
					hull_cells[cell] = true
		# Required uniques
		if comp.category == "engine":
			engine_count += 1
		if comp.category == "core":
			core_count += 1
	# Check adjacency for non-hull components
	for p in placements:
		var comp := BlueprintDatabase.get_component_by_id(p.id)
		if comp.is_empty():
			continue
		if comp.category == "hull":
			continue
		var size: Vector2i = comp.size
		var origin: Vector2i = Vector2i(p.x, p.y)
		var touches_hull := false
		for cx in range(size.x):
			for cy in range(size.y):
				var cell := Vector2i(origin.x + cx, origin.y + cy)
				# 4-neighborhood
				var neighbors = [
					Vector2i(cell.x + 1, cell.y),
					Vector2i(cell.x - 1, cell.y),
					Vector2i(cell.x, cell.y + 1),
					Vector2i(cell.x, cell.y - 1)
				]
				for n in neighbors:
					if n in hull_cells:
						touches_hull = true
						break
				if touches_hull:
					break
			if touches_hull:
				break
		if not touches_hull:
			return { ok = false, reason = "%s must touch hull" % comp.name }
	# Unique required checks
	if engine_count != 1:
		return { ok = false, reason = "Exactly one engine required" }
	if core_count != 1:
		return { ok = false, reason = "Exactly one power core required" }
	return { ok = true }

func save_blueprint(name: String, grid_cols: int, grid_rows: int, cell_px: int, placements: Array) -> bool:
	var dir_path = "user://blueprints"
	DirAccess.make_dir_recursive_absolute(dir_path)
	var path = dir_path + "/" + name + ".json"
	var data = {
		"grid_cols": grid_cols,
		"grid_rows": grid_rows,
		"cell_px": cell_px,
		"placements": placements,
	}
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open blueprint file for write: %s" % path)
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	blueprint_saved.emit(name)
	return true

func load_blueprint(name: String) -> Dictionary:
	var path = "user://blueprints/" + name + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	var txt = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}

func build_blueprint(placements: Array, zone_id: int, spawn_pos: Vector2) -> bool:
	var total_cost = compute_total_cost(placements)
	if not ResourceManager.can_afford_cost(total_cost):
		return false
	var validation = validate_layout(placements, 999, 999)  # Assume placements already bounded by UI
	if not validation.ok:
		return false
	if not ResourceManager.consume_resources(total_cost):
		return false
	# Instantiate ship
	var ship_scene: PackedScene = preload("res://scenes/units/CustomShip.tscn")
	var ship = ship_scene.instantiate()
	if "initialize_from_blueprint" in ship:
		ship.initialize_from_blueprint({ "placements": placements })
	ship.global_position = spawn_pos
	var zone = ZoneManager.get_zone(zone_id)
	if zone and zone.layer_node:
		var units_container = zone.layer_node.get_node_or_null("Entities/Units")
		if units_container:
			units_container.add_child(ship)
			if EntityManager.has_method("register_unit"):
				EntityManager.register_unit(ship, zone_id)
	blueprint_built.emit({ "placements": placements })
	return true
