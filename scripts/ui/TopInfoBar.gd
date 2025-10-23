extends Panel
## Smart top bar showing pinned + important resources and unit counts

@onready var resources_flow: HBoxContainer = $HBoxContainer/ResourcesSection/ResourcesFlow
@onready var units_section: HBoxContainer = $HBoxContainer/UnitsSection

# Scenes
var resource_slot_scene: PackedScene
var unit_button_scene: PackedScene

# Key resource slots (10-15)
var key_resource_slots: Array[ResourceSlot] = []
const MAX_KEY_RESOURCES: int = 15

# Unit buttons
var unit_buttons: Dictionary = {}

# Unit type emoji mapping
const UNIT_TYPE_EMOJIS = {
	"CommandShip": "⭐",
	"MiningDrone": "⚒",
	"CombatDrone": "⚔",
	"ScoutDrone": "🔍",
	"BuilderDrone": "🏗",
	"HeavyDrone": "🛡",
	"SupportDrone": "⚕"
}

# Update timers
var unit_update_timer: float = 0.0
var resource_refresh_timer: float = 0.0
const UNIT_UPDATE_INTERVAL: float = 0.5
const RESOURCE_REFRESH_INTERVAL: float = 2.0

func _ready():
	# Load scenes
	resource_slot_scene = preload("res://scenes/ui/ResourceSlot.tscn")
	unit_button_scene = preload("res://scenes/ui/UnitTypeButton.tscn")
	
	# Create key resource slots
	_create_key_resource_slots()
	
	# Create unit buttons
	_create_unit_buttons()
	
	# Connect to resource changes
	ResourceManager.resource_count_changed.connect(_on_resource_count_changed)
	ResourcePinManager.pins_changed.connect(_on_pins_changed)

func _process(delta: float):
	# Update unit counts periodically
	unit_update_timer += delta
	if unit_update_timer >= UNIT_UPDATE_INTERVAL:
		unit_update_timer = 0.0
		_update_unit_counts()
	
	# Refresh key resources periodically
	resource_refresh_timer += delta
	if resource_refresh_timer >= RESOURCE_REFRESH_INTERVAL:
		resource_refresh_timer = 0.0
		_refresh_key_resources()

func _create_key_resource_slots():
	"""Create slots for key resources"""
	var key_resource_ids = _get_key_resources()
	
	for res_id in key_resource_ids:
		var res_data = ResourceDatabase.get_resource_by_id(res_id)
		if res_data.is_empty():
			continue
		
		var slot = resource_slot_scene.instantiate() as ResourceSlot
		resources_flow.add_child(slot)  # Add to tree FIRST so @onready variables initialize
		slot.setup(res_id, res_data)  # THEN call setup with initialized nodes
		var count = ResourceManager.get_resource_count(res_id)
		slot.update_count(count)
		key_resource_slots.append(slot)

func _get_key_resources() -> Array[int]:
	"""Get list of key resources to display"""
	var key_resources: Array[int] = []
	
	# 1. Add all pinned resources
	var pinned = ResourcePinManager.get_pinned_resources()
	key_resources.append_array(pinned)
	
	# 2. Fill remaining slots with auto-important resources
	var slots_left = MAX_KEY_RESOURCES - key_resources.size()
	if slots_left > 0:
		var auto_resources = _get_auto_important_resources(slots_left)
		key_resources.append_array(auto_resources)
	
	return key_resources

func _get_auto_important_resources(count: int) -> Array[int]:
	"""Get automatically selected important resources"""
	var candidates: Array[int] = []
	
	# Get all resources with count > 0 that aren't pinned
	var has_resources = []
	var no_resources = []
	
	for i in range(100):
		if not ResourcePinManager.is_pinned(i):
			if ResourceManager.get_resource_count(i) > 0:
				has_resources.append(i)
			else:
				no_resources.append(i)
	
	# Sort resources with count by quantity (highest first)
	has_resources.sort_custom(func(a, b):
		return ResourceManager.get_resource_count(a) > ResourceManager.get_resource_count(b)
	)
	
	# Combine: prioritize resources we have, then fill with tier 0-2 at zero
	candidates.append_array(has_resources)
	
	# If we still have slots, add some basic tier 0-2 resources even at 0 count
	if candidates.size() < count:
		for i in range(min(30, no_resources.size())):  # Only from first 30 (tier 0-2)
			if no_resources[i] < 30:  # Ensure it's tier 0-2
				candidates.append(no_resources[i])
				if candidates.size() >= count:
					break
	
	# Return top N
	return candidates.slice(0, min(count, candidates.size()))

func _refresh_key_resources():
	"""Rebuild key resource display"""
	# Clear existing slots
	for slot in key_resource_slots:
		if is_instance_valid(slot):
			slot.queue_free()
	key_resource_slots.clear()
	
	# Recreate with current key resources
	_create_key_resource_slots()

func _on_resource_count_changed(resource_id: int, new_count: int):
	"""Update specific resource when count changes"""
	for slot in key_resource_slots:
		if slot.resource_id == resource_id:
			slot.update_count(new_count)
			return

func _on_pins_changed():
	"""Refresh when user pins/unpins resources"""
	_refresh_key_resources()

func _create_unit_buttons():
	"""Create button for each unit type"""
	for unit_type in UNIT_TYPE_EMOJIS.keys():
		var button = unit_button_scene.instantiate() as UnitTypeButton
		units_section.add_child(button)  # Add to tree FIRST so @onready vars initialize
		button.setup(unit_type, "")  # Then call setup with initialized nodes
		unit_buttons[unit_type] = button
	
	_update_unit_counts()

func _update_unit_counts():
	"""Update unit type counts"""
	var player_units = EntityManager.get_units_by_team(0)
	
	var counts = {
		"CommandShip": 0,
		"MiningDrone": 0,
		"CombatDrone": 0,
		"ScoutDrone": 0,
		"BuilderDrone": 0,
		"HeavyDrone": 0,
		"SupportDrone": 0
	}
	
	for unit in player_units:
		if not is_instance_valid(unit):
			continue
		
		if "is_command_ship" in unit and unit.is_command_ship:
			counts["CommandShip"] += 1
		elif unit is MiningDrone:
			counts["MiningDrone"] += 1
		elif unit is CombatDrone:
			counts["CombatDrone"] += 1
		elif unit is ScoutDrone:
			counts["ScoutDrone"] += 1
		elif unit is BuilderDrone:
			counts["BuilderDrone"] += 1
		elif unit is HeavyDrone:
			counts["HeavyDrone"] += 1
		elif unit is SupportDrone:
			counts["SupportDrone"] += 1
	
	for unit_type in counts.keys():
		if unit_type in unit_buttons:
			unit_buttons[unit_type].update_count(counts[unit_type])
