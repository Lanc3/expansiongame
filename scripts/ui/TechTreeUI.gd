extends Control
class_name TechTreeUI
## Full-screen tech tree UI overlay

signal tree_closed()

# UI References
@onready var background: ColorRect = $Background
@onready var top_bar: Panel = $TopBar
@onready var close_button: Button = $TopBar/CloseButton
@onready var resource_display: HBoxContainer = $TopBar/ResourceDisplay
@onready var category_tabs: VBoxContainer = $LeftSidebar/CategoryTabs
@onready var tree_scroll: ScrollContainer = $TreeScroll
@onready var tree_canvas: Control = $TreeScroll/TreeCanvas
@onready var details_panel: Panel = $RightSidebar/DetailsPanel
@onready var details_name: Label = $RightSidebar/DetailsPanel/VBox/NameLabel
@onready var details_desc: Label = $RightSidebar/DetailsPanel/VBox/DescriptionLabel
@onready var details_cost: VBoxContainer = $RightSidebar/DetailsPanel/VBox/CostList
@onready var details_effects: VBoxContainer = $RightSidebar/DetailsPanel/VBox/EffectsList
@onready var research_button: Button = $RightSidebar/DetailsPanel/VBox/ResearchButton

# State
var research_building: Node2D = null
var current_category: String = "all"
var selected_research_id: String = ""
var tech_nodes: Dictionary = {}  # research_id -> TechTreeNode
var zoom_level: float = 1.0
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO

# Layout
# Adjusted for 0.66 scale nodes (2/3 size)
const NODE_SPACING: Vector2 = Vector2(150, 120)
const CATEGORY_OFFSET: Vector2 = Vector2(80, 220)  # Pushed down another 70 pixels (150 + 70)

func _ready():
	# Initially hidden
	visible = false
	
	# Connect signals
	close_button.pressed.connect(_on_close_pressed)
	research_button.pressed.connect(_on_research_button_pressed)
	
	# Setup background
	background.color = Color(0.05, 0.05, 0.1, 0.95)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Setup category tabs
	create_category_tabs()
	
	# Setup scroll container
	tree_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	tree_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	
	# Setup canvas for drawing connections (script is set in scene)
	tree_canvas.custom_minimum_size = Vector2(4000, 3000)
	
	# Listen for research unlocks
	if ResearchManager:
		ResearchManager.research_unlocked.connect(_on_research_unlocked)
	

func show_for_building(building: Node2D):
	"""Show tech tree for a research building"""
	research_building = building
	
	# Build the tech tree
	rebuild_tech_tree()
	
	# Update resource display
	update_resource_display()
	
	# Show UI
	visible = true
	

func hide_tree():
	"""Hide the tech tree"""
	visible = false
	tree_closed.emit()

func create_category_tabs():
	"""Create category filter tabs"""
	var categories = ["all"] + ResearchDatabase.get_all_categories()
	
	for cat in categories:
		var button = Button.new()
		button.text = cat.capitalize() if cat != "all" else "All"
		button.custom_minimum_size = Vector2(0, 40)
		button.pressed.connect(_on_category_selected.bind(cat))
		category_tabs.add_child(button)

func rebuild_tech_tree():
	"""Rebuild the entire tech tree display"""
	# Clear existing nodes
	clear_tree_nodes()
	
	# Get research nodes to display
	var research_nodes = get_filtered_research_nodes()
	
	# Create node UI elements
	for research in research_nodes:
		create_tech_node(research)
	
	# Update canvas with tech nodes and redraw connections
	if tree_canvas and tree_canvas.has_method("set_tech_nodes"):
		tree_canvas.set_tech_nodes(tech_nodes)
	else:
		tree_canvas.queue_redraw()

func get_filtered_research_nodes() -> Array:
	"""Get research nodes filtered by current category"""
	if current_category == "all":
		return ResearchDatabase.RESEARCH_NODES
	else:
		return ResearchDatabase.get_research_by_category(current_category)

func create_tech_node(research: Dictionary):
	"""Create a visual node for research"""
	var node_scene = preload("res://scenes/ui/TechTreeNode.tscn")
	var node = node_scene.instantiate()
	
	# Position node BEFORE adding to tree
	# Note: Nodes are scaled to 0.66, positions adjusted for visual alignment
	if "position" in research:
		node.position = research.position
	else:
		# Auto-position based on tier and index
		var tier = research.get("tier", 0)
		var index = tech_nodes.size()
		var base_pos = Vector2(tier * NODE_SPACING.x, (index % 10) * NODE_SPACING.y) + CATEGORY_OFFSET
		
		# No offset needed - scale is applied from top-left, which is what we want
		node.position = base_pos
	
	# Add to canvas FIRST (this triggers _ready() and sets up @onready vars)
	tree_canvas.add_child(node)
	tech_nodes[research.id] = node
	
	# Connect signals before initializing
	node.node_clicked.connect(_on_node_clicked)
	node.node_hovered.connect(_on_node_hovered)
	node.node_unhovered.connect(_on_node_unhovered)
	
	# Initialize after _ready() completes (deferred to next frame)
	node.initialize.call_deferred(research.id, research)

func clear_tree_nodes():
	"""Clear all tech nodes"""
	for node in tech_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	
	tech_nodes.clear()

func focus_on_category(category: String):
	"""Scroll viewport to focus on selected category's nodes"""
	if not tree_scroll or tech_nodes.is_empty():
		return
	
	# Find the first node in this category
	var category_nodes = []
	for research_id in tech_nodes:
		var research = ResearchDatabase.get_research_by_id(research_id)
		if not research.is_empty() and research.category == category:
			category_nodes.append(tech_nodes[research_id])
	
	if category_nodes.is_empty():
		return
	
	# Find the topmost, leftmost node (minimum x and y)
	var min_x = INF
	var min_y = INF
	for node in category_nodes:
		if is_instance_valid(node):
			if node.position.x < min_x:
				min_x = node.position.x
			if node.position.y < min_y:
				min_y = node.position.y
	
	# Calculate scroll target (account for node scale 0.66)
	var node_scale = 0.66
	var target_x = max(0, min_x - 100)  # Add 100px padding from left
	var target_y = max(0, min_y - 150)  # Add 150px padding from top
	
	# Smooth scroll to position
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(tree_scroll, "scroll_horizontal", int(target_x), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(tree_scroll, "scroll_vertical", int(target_y), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	print("TechTreeUI: Focused on category '%s' at position (%d, %d)" % [category, int(target_x), int(target_y)])

func _on_category_selected(category: String):
	"""Handle category tab selection"""
	current_category = category
	rebuild_tech_tree()
	
	# Auto-scroll to focus on selected category
	call_deferred("focus_on_category", category)

func _on_node_clicked(research_id: String):
	"""Handle node click - show details in right panel"""
	# Deselect previous node
	if selected_research_id != "" and selected_research_id in tech_nodes:
		var old_node = tech_nodes[selected_research_id]
		if is_instance_valid(old_node) and old_node.has_method("set_node_selected"):
			old_node.set_node_selected(false)
	
	# Select new node
	selected_research_id = research_id
	if research_id in tech_nodes:
		var new_node = tech_nodes[research_id]
		if is_instance_valid(new_node) and new_node.has_method("set_node_selected"):
			new_node.set_node_selected(true)
	
	update_details_panel(research_id)

func _on_node_hovered(research_id: String, research_data: Dictionary):
	"""Handle node hover - just visual feedback, no details change"""
	# Don't update details panel on hover - click only!
	pass

func _on_node_unhovered():
	"""Handle node unhover"""
	# Don't change details panel
	pass

func update_details_panel(research_id: String):
	"""Update the right sidebar details panel"""
	var research = ResearchDatabase.get_research_by_id(research_id)
	if research.is_empty():
		return
	
	# Update name
	if details_name:
		var research_time = ResearchDatabase.get_research_time(research_id)
		details_name.text = "%s\n(Research Time: %ds)" % [research.name, int(research_time)]
	
	# Update description
	if details_desc:
		details_desc.text = research.description
	
	# Update cost
	if details_cost:
		update_cost_list(research.cost)
	
	# Update effects
	if details_effects:
		update_effects_list(research.effects)
	
	# Update research button
	if research_button:
		if ResearchManager:
			if ResearchManager.is_unlocked(research_id):
				research_button.text = "✓ Researched"
				research_button.disabled = true
			elif ResearchManager.is_researching():
				if ResearchManager.current_research_id == research_id:
					research_button.text = "Researching..."
					research_button.disabled = true
				else:
					research_button.text = "Already Researching"
					research_button.disabled = true
			elif ResearchManager.can_research(research_id):
				research_button.text = "Start Research"
				research_button.disabled = false
			else:
				research_button.text = "Locked"
				research_button.disabled = true

func update_cost_list(cost: Dictionary):
	"""Update cost display in details panel"""
	# Clear existing
	for child in details_cost.get_children():
		child.queue_free()
	
	# Add cost items
	for resource_id in cost:
		var amount = cost[resource_id]
		var resource_name = ResourceDatabase.get_resource_name(resource_id)
		var resource_color = ResourceDatabase.get_resource_color(resource_id)
		var current_amount = ResourceManager.get_resource_count(resource_id) if ResourceManager else 0
		
		var cost_label = Label.new()
		cost_label.text = "%s: %d / %d" % [resource_name, current_amount, amount]
		cost_label.modulate = resource_color
		
		# Red if not enough
		if current_amount < amount:
			cost_label.modulate = Color(1.0, 0.3, 0.3)
		
		details_cost.add_child(cost_label)

func update_effects_list(effects: Dictionary):
	"""Update effects display in details panel"""
	# Clear existing
	for child in details_effects.get_children():
		child.queue_free()
	
	# Add effect items
	for effect_key in effects:
		var effect_value = effects[effect_key]
		var effect_text = format_effect_text(effect_key, effect_value)
		
		var effect_label = Label.new()
		effect_label.text = effect_text
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details_effects.add_child(effect_label)

func format_effect_text(effect_key: String, effect_value: Variant) -> String:
	"""Format effect for display"""
	# Remove stat_ prefix
	var display_name = effect_key.replace("stat_", "").replace("_", " ").capitalize()
	
	# Format value based on type
	if typeof(effect_value) == TYPE_FLOAT:
		if effect_value > 1.0:
			# Multiplier
			var percent = (effect_value - 1.0) * 100.0
			return "%s +%.0f%%" % [display_name, percent]
		else:
			return "%s: %.2f" % [display_name, effect_value]
	elif typeof(effect_value) == TYPE_INT:
		return "%s: %d" % [display_name, effect_value]
	elif typeof(effect_value) == TYPE_BOOL:
		return "%s: %s" % [display_name, "Enabled" if effect_value else "Disabled"]
	else:
		return "%s: %s" % [display_name, str(effect_value)]

func _on_research_button_pressed():
	"""Handle research button press"""
	if selected_research_id == "":
		return
	
	if ResearchManager:
		if ResearchManager.unlock_research(selected_research_id):
			# Success - update UI
			update_details_panel(selected_research_id)
			update_resource_display()
			
			# Update all node visuals
			for node in tech_nodes.values():
				if is_instance_valid(node):
					node.update_visual_state()
			
			# Redraw connections
			if tree_canvas and tree_canvas.has_method("set_tech_nodes"):
				tree_canvas.set_tech_nodes(tech_nodes)

func _on_research_unlocked(research_id: String):
	"""Handle research unlock signal"""
	
	# Update ALL node visuals (some may have become available)
	for node_id in tech_nodes:
		var node = tech_nodes[node_id]
		if is_instance_valid(node) and node.has_method("update_visual_state"):
			node.update_visual_state()
	
	# Redraw connections
	if tree_canvas and tree_canvas.has_method("set_tech_nodes"):
		tree_canvas.set_tech_nodes(tech_nodes)
	
	# Update details panel if the unlocked research is selected
	if selected_research_id == research_id:
		update_details_panel(research_id)

func update_resource_display():
	"""Update top bar resource display"""
	if not resource_display:
		return
	
	# Clear existing
	for child in resource_display.get_children():
		child.queue_free()
	
	# Show first 10 resources
	for i in range(min(10, 100)):
		var amount = ResourceManager.get_resource_count(i) if ResourceManager else 0
		if amount > 0:
			var resource_name = ResourceDatabase.get_resource_name(i)
			var resource_color = ResourceDatabase.get_resource_color(i)
			
			var label = Label.new()
			label.text = "%s: %d" % [resource_name, amount]
			label.modulate = resource_color
			label.add_theme_font_size_override("font_size", 12)
			resource_display.add_child(label)

func _on_close_pressed():
	"""Handle close button"""
	hide_tree()

func _input(event: InputEvent):
	if not visible:
		return
	
	# ESC to close
	if event.is_action_pressed("ui_cancel"):
		hide_tree()
		get_viewport().set_input_as_handled()
	
	# Mouse wheel zoom (future enhancement)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = min(zoom_level * 1.1, 2.0)
			tree_canvas.scale = Vector2(zoom_level, zoom_level)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = max(zoom_level * 0.9, 0.5)
			tree_canvas.scale = Vector2(zoom_level, zoom_level)
