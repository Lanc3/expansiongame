extends Node
## Manages pinned resources for top bar display

signal pins_changed()

var pinned_resource_ids: Array[int] = []
const MAX_PINS: int = 10
const SAVE_PATH: String = "user://pinned_resources.save"

func _ready():
	load_pins()

func pin_resource(resource_id: int):
	"""Add a resource to pinned favorites"""
	if resource_id in pinned_resource_ids:
		return
	
	if pinned_resource_ids.size() >= MAX_PINS:
		# Remove oldest pin to make room
		pinned_resource_ids.pop_front()
	
	pinned_resource_ids.append(resource_id)
	save_pins()
	pins_changed.emit()

func unpin_resource(resource_id: int):
	"""Remove a resource from pinned favorites"""
	pinned_resource_ids.erase(resource_id)
	save_pins()
	pins_changed.emit()

func toggle_pin(resource_id: int):
	"""Toggle pin state of a resource"""
	if is_pinned(resource_id):
		unpin_resource(resource_id)
	else:
		pin_resource(resource_id)

func is_pinned(resource_id: int) -> bool:
	"""Check if a resource is pinned"""
	return resource_id in pinned_resource_ids

func get_pinned_resources() -> Array[int]:
	"""Get array of all pinned resource IDs"""
	return pinned_resource_ids.duplicate()

func save_pins():
	"""Save pinned resources to disk"""
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(pinned_resource_ids)
		file.close()

func load_pins():
	"""Load pinned resources from disk"""
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			if data is Array:
				pinned_resource_ids = []
				for id in data:
					if id is int:
						pinned_resource_ids.append(id)
			file.close()
	
	# Default pins for new players
	if pinned_resource_ids.is_empty():
		pinned_resource_ids = [0, 1, 2]  # Iron, Carbon, Silicon
		save_pins()

