extends Panel
## Full resource inventory overlay with search and filtering

@onready var title_label: Label = $VBox/Header/TitleLabel
@onready var collected_label: Label = $VBox/Header/CollectedLabel
@onready var close_button: Button = $VBox/Header/CloseButton
@onready var search_box: LineEdit = $VBox/Toolbar/SearchBox
@onready var filter_dropdown: OptionButton = $VBox/Toolbar/FilterDropdown
@onready var tier_sections_container: VBoxContainer = $VBox/ScrollContainer/TierSectionsContainer

var resource_slot_scene: PackedScene
var tier_section_scene: PackedScene

var tier_sections: Array[ResourceTierSection] = []
var all_resource_slots: Array[ResourceSlot] = []

var current_filter: int = 0  # 0=All, 1=Common, 2=Uncommon, 3=Rare+
var current_search: String = ""

func _ready():
	resource_slot_scene = preload("res://scenes/ui/ResourceSlot.tscn")
	tier_section_scene = preload("res://scenes/ui/ResourceTierSection.tscn")
	
	close_button.pressed.connect(_on_close_pressed)
	search_box.text_changed.connect(_on_search_changed)
	filter_dropdown.item_selected.connect(_on_filter_selected)
	
	_create_tier_sections()
	_populate_resources()
	
	# Initially hidden
	visible = false

func _create_tier_sections():
	"""Create collapsible sections for each tier group"""
	var tier_groups = [
		{"range": [0, 2], "name": "Common"},
		{"range": [3, 5], "name": "Uncommon"},
		{"range": [6, 7], "name": "Rare"},
		{"range": [8, 9], "name": "Ultra-Rare"}
	]
	
	for group in tier_groups:
		var section = tier_section_scene.instantiate() as ResourceTierSection
		section.setup(group.range[0], group.range[1], group.name)
		tier_sections_container.add_child(section)
		tier_sections.append(section)

func _populate_resources():
	"""Create resource slots for all 100 resources"""
	var all_resources = ResourceDatabase.get_all_resources()
	
	# Sort by tier then alphabetically
	var sorted_resources = []
	for i in range(all_resources.size()):
		sorted_resources.append({"id": i, "data": all_resources[i]})
	
	sorted_resources.sort_custom(func(a, b):
		if a.data.tier != b.data.tier:
			return a.data.tier < b.data.tier
		return a.data.name < b.data.name
	)
	
	# Add to appropriate tier sections
	for item in sorted_resources:
		var slot = resource_slot_scene.instantiate() as ResourceSlot
		slot.setup(item.id, item.data)
		all_resource_slots.append(slot)
		
		# Find correct tier section
		for section in tier_sections:
			if item.data.tier >= section.tier_range[0] and item.data.tier <= section.tier_range[1]:
				section.add_resource_slot(slot)
				break
	
	# Connect to resource changes
	ResourceManager.resource_count_changed.connect(_on_resource_count_changed)

func show_panel():
	"""Show the inventory panel"""
	visible = true
	refresh()

func hide_panel():
	"""Hide the inventory panel"""
	visible = false

func refresh():
	"""Refresh all counts and sections"""
	if not visible:
		return
	
	# Update all resource counts
	for slot in all_resource_slots:
		var count = ResourceManager.get_resource_count(slot.resource_id)
		slot.update_count(count)
	
	# Update collected count
	var collected = 0
	for i in range(100):
		if ResourceManager.get_resource_count(i) > 0:
			collected += 1
	
	if collected_label:
		collected_label.text = "%d/100" % collected
	
	# Update tier section headers
	for section in tier_sections:
		section.refresh()
	
	# Apply current filter
	_apply_filter_and_search()

func _apply_filter_and_search():
	"""Apply current filter and search to visibility"""
	for slot in all_resource_slots:
		var show_slot = true
		
		# Apply tier filter
		match current_filter:
			1:  # Common
				show_slot = slot.resource_data.tier <= 2
			2:  # Uncommon
				show_slot = slot.resource_data.tier >= 3 and slot.resource_data.tier <= 5
			3:  # Rare+
				show_slot = slot.resource_data.tier >= 6
		
		# Apply search filter
		if current_search != "" and show_slot:
			var name_lower = slot.resource_data.name.to_lower()
			var search_lower = current_search.to_lower()
			show_slot = name_lower.contains(search_lower)
		
		slot.visible = show_slot

func _on_resource_count_changed(resource_id: int, new_count: int):
	"""Update specific resource when it changes"""
	if visible and resource_id < all_resource_slots.size():
		all_resource_slots[resource_id].update_count(new_count)
		
		# Refresh headers
		for section in tier_sections:
			section.refresh()

func _on_close_pressed():
	hide_panel()

func _on_search_changed(new_text: String):
	current_search = new_text
	_apply_filter_and_search()

func _on_filter_selected(index: int):
	current_filter = index
	_apply_filter_and_search()

func _input(event: InputEvent):
	if visible and event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			hide_panel()
			accept_event()

