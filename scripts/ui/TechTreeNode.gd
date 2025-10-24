extends PanelContainer
class_name TechTreeNode
## Individual research node in the tech tree

signal node_clicked(research_id: String)
signal node_hovered(research_id: String, research_data: Dictionary)
signal node_unhovered()

var research_id: String = ""
var research_data: Dictionary = {}
var node_status: String = "locked"  # locked, available, researched
var is_node_selected: bool = false  # If this node is selected in details panel

# UI Components (from scene)
@onready var status_indicator: ColorRect = $VBox/StatusIndicator if has_node("VBox/StatusIndicator") else null
@onready var icon_texture: TextureRect = $VBox/Icon if has_node("VBox/Icon") else null
@onready var name_label: Label = $VBox/NameLabel if has_node("VBox/NameLabel") else null
@onready var cost_container: HBoxContainer = $VBox/CostContainer if has_node("VBox/CostContainer") else null
@onready var glow_effect: ColorRect = $GlowEffect if has_node("GlowEffect") else null

# Dynamic UI components
var research_progress_bar: ProgressBar = null
var researching_label: Label = null

func _ready():
	# Setup hover detection
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Set node to 2/3 size (2x from previous 1/3)
	scale = Vector2(0.66, 0.66)
	
	# Create progress bar for research
	create_progress_bar()
	
	# Listen for research progress updates
	if ResearchManager:
		ResearchManager.research_progress_updated.connect(_on_research_progress)
		ResearchManager.research_started.connect(_on_research_started)
		ResearchManager.research_unlocked.connect(_on_research_completed)
	
	print("TechTreeNode: _ready() called")

func create_progress_bar():
	"""Create progress bar for research progress"""
	research_progress_bar = ProgressBar.new()
	research_progress_bar.name = "ResearchProgress"
	research_progress_bar.custom_minimum_size = Vector2(140, 12)
	research_progress_bar.position = Vector2(10, size.y - 22)
	research_progress_bar.show_percentage = true
	research_progress_bar.value = 0
	research_progress_bar.visible = false
	
	# Style
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	research_progress_bar.add_theme_stylebox_override("background", style_bg)
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.3, 0.7, 1.0, 0.9)
	research_progress_bar.add_theme_stylebox_override("fill", style_fill)
	
	add_child(research_progress_bar)
	
	# "RESEARCHING..." label
	researching_label = Label.new()
	researching_label.name = "ResearchingLabel"
	researching_label.text = "RESEARCHING..."
	researching_label.position = Vector2(10, size.y - 38)
	researching_label.add_theme_font_size_override("font_size", 9)
	researching_label.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	researching_label.visible = false
	add_child(researching_label)

func initialize(r_id: String, r_data: Dictionary):
	"""Initialize node with research data"""
	research_id = r_id
	research_data = r_data
	
	# Update content first (sets up labels and icons)
	update_content()
	
	# Then update visual state (sets colors and styling)
	update_visual_state()
	
	print("TechTreeNode: Initialized %s" % research_data.get("name", r_id))

func update_content():
	"""Update node content from research data"""
	if research_data.is_empty():
		return
	
	# Update name with better formatting
	if name_label:
		if "name" in research_data:
			name_label.text = research_data.name

		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

	# Update icon - use category-based placeholder
	if icon_texture:
		# Create a colored rectangle as placeholder icon
		var category = research_data.get("category", "")
		var category_color = get_category_color()
		
		# Create icon image programmatically
		var image = Image.create(80, 80, false, Image.FORMAT_RGBA8)
		image.fill(category_color)
		
		# Add icon symbol based on category
		var icon_text = get_category_icon_symbol(category)
		
		# Set as texture
		var texture = ImageTexture.create_from_image(image)
		icon_texture.texture = texture
		
		# Add colored background
		icon_texture.modulate = Color(1.0, 1.0, 1.0)
		icon_texture.self_modulate = category_color
	
	# Update cost display
	if cost_container and "cost" in research_data:
		update_cost_display(research_data.cost)

func get_category_icon_symbol(category: String) -> String:
	"""Get icon symbol for category"""
	match category:
		"hull": return "🛡"
		"shield": return "⚡"
		"weapon": return "⚔"
		"ability": return "✦"
		"building": return "🏭"
		"economy": return "💰"
		_: return "?"

func update_cost_display(cost: Dictionary):
	"""Update cost icons and amounts"""
	# Clear existing
	for child in cost_container.get_children():
		child.queue_free()
	
	# Check affordability for each resource
	var all_affordable = true
	
	# Add cost items (limit to 3 to fit in compact view)
	var count = 0
	for resource_id in cost:
		if count >= 3:
			break
		
		var amount = cost[resource_id]
		var current_amount = ResourceManager.get_resource_count(resource_id) if ResourceManager else 0
		var resource_color = ResourceDatabase.get_resource_color(resource_id)
		
		var can_afford_this = current_amount >= amount
		if not can_afford_this:
			all_affordable = false
		
		# Create cost label with current/required format
		var cost_label = Label.new()
		cost_label.text = "%d" % amount
		cost_label.add_theme_font_size_override("font_size", 9)
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Color based on affordability
		if can_afford_this:
			cost_label.modulate = resource_color * 1.2  # Brighter
		else:
			cost_label.modulate = Color(1.0, 0.3, 0.3)  # Red - can't afford
		
		cost_container.add_child(cost_label)
		
		count += 1
	
	# If more than 3, add "..." indicator
	if cost.size() > 3:
		var more_label = Label.new()
		more_label.text = "..."
		more_label.add_theme_font_size_override("font_size", 9)
		more_label.modulate = Color(0.7, 0.7, 0.7)
		more_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost_container.add_child(more_label)

func update_visual_state():
	"""Update visual appearance based on status"""
	var old_status = node_status
	
	# Determine status
	var can_afford = false
	if ResearchManager:
		if ResearchManager.is_unlocked(research_id):
			node_status = "researched"
		elif ResearchManager.can_research(research_id):
			node_status = "available"
			can_afford = true
		else:
			# Check if only resources are missing (prerequisites met)
			var research = ResearchDatabase.get_research_by_id(research_id)
			if not research.is_empty():
				var prereqs_met = true
				for prereq_id in research.prerequisites:
					if not ResearchManager.is_unlocked(prereq_id):
						prereqs_met = false
						break
				
				# If prerequisites met but can't research, it's a resource issue
				if prereqs_met and ResourceManager:
					can_afford = ResourceManager.can_afford_cost(research.cost)
			
			node_status = "locked"
	else:
		node_status = "locked"
	
	# Update colors based on status
	match node_status:
		"researched":
			# Green - completed
			if status_indicator:
				status_indicator.color = Color(0.0, 0.8, 0.0)
			self_modulate = Color(0.7, 1.0, 0.7, 1.0)  # Bright green tint
			
		"available":
			# Bright green if can afford, yellow if prerequisites met but can't afford
			if status_indicator:
				if can_afford:
					status_indicator.color = Color(0.0, 1.0, 0.0)  # Bright green
				else:
					status_indicator.color = Color(1.0, 0.6, 0.0)  # Orange
			
			if can_afford:
				self_modulate = Color(0.8, 1.0, 0.8, 1.0)  # Bright - can afford!
			else:
				self_modulate = Color(1.0, 0.9, 0.7, 1.0)  # Yellow - need resources
			
		"locked":
			# Red if prereqs not met, orange if only resources needed
			if status_indicator:
				if can_afford:
					status_indicator.color = Color(1.0, 0.6, 0.0)  # Orange - only resources
				else:
					status_indicator.color = Color(0.6, 0.0, 0.0)  # Dark red - prereqs
			self_modulate = Color(0.5, 0.5, 0.5, 0.7)  # Grayed out
	
	# Update background color based on category
	var category_color = get_category_color()
	var style = StyleBoxFlat.new()
	style.bg_color = category_color * 0.4
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	
	# Border color based on status and affordability
	if node_status == "researched":
		style.border_color = Color(0.0, 1.0, 0.0, 0.8)  # Green
	elif node_status == "available" and can_afford:
		style.border_color = Color(0.3, 1.0, 0.3, 1.0)  # Bright green
	elif node_status == "available":
		style.border_color = Color(1.0, 0.8, 0.0, 0.8)  # Yellow
	else:
		style.border_color = Color(0.4, 0.4, 0.4, 0.5)  # Gray
	
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	
	add_theme_stylebox_override("panel", style)
	
	# Update cost display to reflect current resources
	if "cost" in research_data:
		update_cost_display(research_data.cost)
	
	# Debug: Log status changes
	if old_status != node_status:
		print("TechTreeNode: %s status changed: %s → %s (can_afford=%s)" % [research_data.get("name", research_id), old_status, node_status, can_afford])

func get_category_color() -> Color:
	"""Get color for research category"""
	if "category" in research_data:
		return ResearchDatabase.get_category_color(research_data.category)
	return Color.WHITE

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			on_clicked()
			accept_event()  # Mark event as handled

func on_clicked():
	"""Handle node click"""
	print("TechTreeNode: Clicked on %s (status: %s)" % [research_data.get("name", research_id), node_status])
	
	# Visual click feedback - quick scale pulse
	var click_tween = create_tween()
	click_tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
	click_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.05)
	
	# Emit click signal
	node_clicked.emit(research_id)
	
	# Try to start research if available
	if node_status == "available" and ResearchManager:
		pass  # Research can be started from details panel
	elif node_status == "locked":
		pass  # Prerequisites not met
	elif node_status == "researched":
		pass  # Already researched
	elif ResearchManager and ResearchManager.is_researching():
		pass  # Already researching something

func play_unlock_animation():
	"""Play animation when research is unlocked"""
	if not glow_effect:
		return
	
	# Flash effect
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(glow_effect, "color", Color(1.0, 1.0, 0.0, 0.6), 0.3)
	tween.tween_property(self, "scale", Vector2(0.76, 0.76), 0.2)
	
	tween.set_parallel(false)
	tween.tween_property(glow_effect, "color", Color(1.0, 1.0, 0.0, 0.0), 0.5)
	tween.tween_property(self, "scale", Vector2(0.66, 0.66), 0.3)

func _on_mouse_entered():
	"""Handle mouse hover"""
	# Scale up slightly from 0.66 to 0.70
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.70, 0.70), 0.1)
	
	# Show hover glow only if not already selected
	if glow_effect and not is_node_selected:
		var tween2 = create_tween()
		tween2.tween_property(glow_effect, "color:a", 0.15, 0.1)
	
	# Emit hover signal (but don't update details panel)
	node_hovered.emit(research_id, research_data)

func _on_mouse_exited():
	"""Handle mouse exit"""
	# Scale back to 0.66
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.66, 0.66), 0.1)
	
	# Hide hover glow only if not selected
	if glow_effect and not is_node_selected:
		var tween2 = create_tween()
		tween2.tween_property(glow_effect, "color:a", 0.0, 0.1)
	# If selected, keep the selection glow (yellow)
	
	# Emit unhover signal
	node_unhovered.emit()

func set_node_selected(selected: bool):
	"""Set whether this node is currently selected in details panel"""
	is_node_selected = selected
	
	# Add visual indicator if selected
	if glow_effect:
		if selected:
			glow_effect.color = Color(1.0, 1.0, 0.5, 0.3)  # Yellow glow
		else:
			glow_effect.color = Color(1.0, 1.0, 1.0, 0.0)  # Hidden

func get_center_position() -> Vector2:
	"""Get center position for drawing connections"""
	return global_position + (size / 2.0)

func _on_research_started(started_research_id: String, research_time: float):
	"""Handle research started signal"""
	if started_research_id == research_id:
		# This node is being researched!
		if research_progress_bar:
			research_progress_bar.visible = true
			research_progress_bar.value = 0
		
		if researching_label:
			researching_label.visible = true
		
		print("TechTreeNode: Research started on %s (%.0fs)" % [research_data.get("name", research_id), research_time])

func _on_research_progress(progress_research_id: String, progress: float):
	"""Handle research progress update"""
	if progress_research_id == research_id:
		# Update progress bar
		if research_progress_bar:
			research_progress_bar.value = progress * 100.0

func _on_research_completed(completed_research_id: String):
	"""Handle research completed signal"""
	if completed_research_id == research_id:
		# Hide progress indicators
		if research_progress_bar:
			research_progress_bar.visible = false
		
		if researching_label:
			researching_label.visible = false
		
		# Update visual state
		update_visual_state()
		
		print("TechTreeNode: Research completed on %s" % research_data.get("name", research_id))
