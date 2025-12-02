extends Node
## Manages graphics settings including bloom effect

var glow_enabled: bool = true
var glow_strength: float = 1.2
var glow_bloom: float = 0.3

var world_environment: WorldEnvironment = null

func _ready():
	load_settings()
	# Try to find world environment immediately
	call_deferred("find_world_environment")
	# Also try when scene tree is ready
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node):
	"""Check if added node is WorldEnvironment or GameScene"""
	if node is WorldEnvironment:
		world_environment = node
		apply_settings()
	elif node.name == "GameScene":
		# GameScene loaded, try to find WorldEnvironment
		call_deferred("find_world_environment")

func find_world_environment():
	"""Find the WorldEnvironment node in the current scene"""
	var scene = get_tree().current_scene
	if not scene:
		return
	
	# Try direct path first
	world_environment = scene.get_node_or_null("WorldEnvironment")
	
	# If not found, search recursively
	if not world_environment:
		world_environment = _find_node_recursive(scene, "WorldEnvironment")
	
	# Apply settings if found
	if world_environment:
		apply_settings()

func _find_node_recursive(node: Node, node_name: String) -> Node:
	"""Recursively search for a node by name"""
	if node.name == node_name:
		return node
	
	for child in node.get_children():
		var found = _find_node_recursive(child, node_name)
		if found:
			return found
	
	return null

func apply_settings():
	"""Apply graphics settings to the environment"""
	if not world_environment or not world_environment.environment:
		# If we don't have environment yet, try to find it
		find_world_environment()
		if not world_environment or not world_environment.environment:
			return
	
	var env = world_environment.environment
	env.glow_enabled = glow_enabled
	env.glow_strength = glow_strength
	env.glow_bloom = glow_bloom

func set_glow_enabled(enabled: bool):
	"""Set glow enabled state"""
	glow_enabled = enabled
	apply_settings()
	save_settings()

func set_glow_strength(strength: float):
	"""Set glow strength (0.0 to 3.0)"""
	glow_strength = clamp(strength, 0.0, 3.0)
	apply_settings()
	save_settings()

func set_glow_bloom(bloom: float):
	"""Set glow bloom amount (0.0 to 1.0)"""
	glow_bloom = clamp(bloom, 0.0, 1.0)
	apply_settings()
	save_settings()

func get_glow_enabled() -> bool:
	"""Get glow enabled state"""
	return glow_enabled

func get_glow_strength() -> float:
	"""Get glow strength"""
	return glow_strength

func get_glow_bloom() -> float:
	"""Get glow bloom amount"""
	return glow_bloom

func save_settings():
	"""Save graphics settings to disk"""
	var settings = {
		"glow_enabled": glow_enabled,
		"glow_strength": glow_strength,
		"glow_bloom": glow_bloom
	}
	
	var file = FileAccess.open("user://graphics_settings.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings, "\t"))
		file.close()

func load_settings():
	"""Load graphics settings from disk"""
	if FileAccess.file_exists("user://graphics_settings.json"):
		var file = FileAccess.open("user://graphics_settings.json", FileAccess.READ)
		if file:
			var json = JSON.new()
			var parse_result = json.parse(file.get_as_text())
			file.close()
			
			if parse_result == OK:
				var settings = json.data
				if settings:
					glow_enabled = settings.get("glow_enabled", true)
					glow_strength = settings.get("glow_strength", 1.2)
					glow_bloom = settings.get("glow_bloom", 0.3)

