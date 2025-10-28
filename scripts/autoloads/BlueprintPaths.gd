extends Node
## Centralized blueprint storage paths

const BLUEPRINT_DIR = "res://ship_blueprints"
const BLUEPRINT_EXTENSION = ".tres"

func ensure_blueprint_directory_exists() -> bool:
	"""Ensure blueprint directory exists, create if needed"""
	var dir = DirAccess.open("res://")
	if not dir:
		push_error("Could not access res:// directory")
		return false
	
	if not dir.dir_exists("ship_blueprints"):
		var err = dir.make_dir("ship_blueprints")
		if err != OK:
			push_error("Failed to create ship_blueprints directory: " + str(err))
			return false
		print("Created ship_blueprints directory at: ", BLUEPRINT_DIR)
	
	return true

func get_blueprint_save_path(blueprint_name: String) -> String:
	"""Get full path for saving a blueprint"""
	ensure_blueprint_directory_exists()
	return BLUEPRINT_DIR + "/" + blueprint_name + BLUEPRINT_EXTENSION

func get_all_blueprint_files() -> Array[String]:
	"""Get all blueprint file paths"""
	ensure_blueprint_directory_exists()
	
	var blueprint_files: Array[String] = []
	var dir = DirAccess.open(BLUEPRINT_DIR)
	
	if not dir:
		push_warning("Could not open blueprint directory: " + BLUEPRINT_DIR)
		return blueprint_files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(BLUEPRINT_EXTENSION):
			blueprint_files.append(BLUEPRINT_DIR + "/" + file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	return blueprint_files

func load_blueprint(file_path: String) -> CosmoteerShipBlueprint:
	"""Load a blueprint from file path"""
	var blueprint = ResourceLoader.load(file_path)
	
	if blueprint is CosmoteerShipBlueprint:
		return blueprint
	else:
		push_error("Invalid blueprint file: " + file_path)
		return null

func save_blueprint(blueprint: CosmoteerShipBlueprint, file_path: String) -> bool:
	"""Save a blueprint to file path"""
	ensure_blueprint_directory_exists()
	
	var err = ResourceSaver.save(blueprint, file_path)
	if err == OK:
		print("Blueprint saved: ", file_path)
		return true
	else:
		push_error("Failed to save blueprint: " + str(err))
		return false

func delete_blueprint(file_path: String) -> bool:
	"""Delete a blueprint file"""
	var dir = DirAccess.open(BLUEPRINT_DIR)
	if not dir:
		return false
	
	var err = dir.remove(file_path.get_file())
	return err == OK

