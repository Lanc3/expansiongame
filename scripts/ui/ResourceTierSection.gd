extends VBoxContainer
class_name ResourceTierSection

## Collapsible section for resources grouped by tier

@onready var header_button: Button = $HeaderButton
@onready var content_grid: GridContainer = $ContentGrid

var tier_range: Array[int] = [0, 2]  # [min_tier, max_tier]
var tier_name: String = "Common"
var is_expanded: bool = true
var resource_slots: Array[ResourceSlot] = []

signal toggled(is_expanded: bool)

func _ready():
	if header_button:
		header_button.pressed.connect(_on_header_pressed)

func setup(min_tier: int, max_tier: int, name: String):
	tier_range = [min_tier, max_tier]
	tier_name = name
	update_header()

func add_resource_slot(slot: ResourceSlot):
	content_grid.add_child(slot)
	resource_slots.append(slot)

func update_header():
	var collected_count = get_collected_count()
	var arrow = "▼" if is_expanded else "▶"
	var tier_str = "Tier %d" % tier_range[0] if tier_range[0] == tier_range[1] else "Tier %d-%d" % [tier_range[0], tier_range[1]]
	
	if header_button:
		header_button.text = "%s %s: %s (%d collected)" % [arrow, tier_str, tier_name, collected_count]

func get_collected_count() -> int:
	var count = 0
	for slot in resource_slots:
		if slot.current_count > 0:
			count += 1
	return count

func _on_header_pressed():
	is_expanded = !is_expanded
	content_grid.visible = is_expanded
	update_header()
	toggled.emit(is_expanded)

func set_expanded(expanded: bool):
	is_expanded = expanded
	if content_grid:
		content_grid.visible = is_expanded
	update_header()

func refresh():
	update_header()

