class_name CosmoteerUndoRedoManager
extends RefCounted
## Manages undo/redo history for ship builder

var undo_stack: Array[CosmoteerShipBlueprint] = []
var redo_stack: Array[CosmoteerShipBlueprint] = []
const MAX_HISTORY = 50

func record_state(blueprint: CosmoteerShipBlueprint):
	"""Record current state for undo"""
	# Clear redo stack when new action is taken
	redo_stack.clear()
	
	# Add to undo stack
	undo_stack.append(blueprint.duplicate_blueprint())
	
	# Limit stack size
	if undo_stack.size() > MAX_HISTORY:
		undo_stack.remove_at(0)

func undo() -> CosmoteerShipBlueprint:
	"""Undo last action and return previous state"""
	if not can_undo():
		return null
	
	# Move current state to redo stack
	var current = undo_stack.pop_back()
	redo_stack.append(current)
	
	# Return previous state
	if undo_stack.is_empty():
		# Return empty blueprint if nothing left
		return CosmoteerShipBlueprint.new()
	
	return undo_stack.back().duplicate_blueprint()

func redo() -> CosmoteerShipBlueprint:
	"""Redo last undone action"""
	if not can_redo():
		return null
	
	# Get state from redo stack
	var state = redo_stack.pop_back()
	undo_stack.append(state)
	
	return state.duplicate_blueprint()

func can_undo() -> bool:
	return not undo_stack.is_empty()

func can_redo() -> bool:
	return not redo_stack.is_empty()

func clear():
	"""Clear all history"""
	undo_stack.clear()
	redo_stack.clear()

func get_undo_count() -> int:
	return undo_stack.size()

func get_redo_count() -> int:
	return redo_stack.size()

