extends StaticBody2D
class_name ResearchBuilding
## Research facility that unlocks tech tree when selected

signal building_selected()
signal building_deselected()
signal building_destroyed()

# Building properties
@export var max_health: float = 1500.0
@export var team_id: int = 0  # Player team
@export var zone_id: int = 1

var current_health: float
var is_selected: bool = false
var is_destroyed: bool = false
var is_under_construction: bool = false
var construction_progress: float = 0.0

# Visual components
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var health_bar: ProgressBar = $HealthBar if has_node("HealthBar") else null
@onready var selection_indicator: Sprite2D = $SelectionIndicator if has_node("SelectionIndicator") else null
@onready var research_particles: CPUParticles2D = $ResearchParticles if has_node("ResearchParticles") else null
@onready var construction_particles: CPUParticles2D = $ConstructionParticles if has_node("ConstructionParticles") else null

# Building type identifier
var building_type: String = "ResearchBuilding"

func _ready():
	current_health = max_health
	
	# Add to groups
	add_to_group("buildings")
	add_to_group("player_buildings")
	add_to_group("research_buildings")
	
	# Setup collision
	collision_layer = 2  # Buildings layer
	collision_mask = 0  # Don't collide with anything
	
	# Initialize visuals
	if selection_indicator:
		selection_indicator.visible = false
	
	update_health_bar()
	update_visual_state()
	
	# Register with EntityManager
	if EntityManager:
		EntityManager.register_building(self)
	
	# Set zone
	if ZoneManager:
		zone_id = ZoneManager.get_unit_zone(self)
	

func _input(event: InputEvent):
	# Handle click on building
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_mouse_over():
				on_clicked()

func is_mouse_over() -> bool:
	"""Check if mouse is over building"""
	var mouse_pos = get_global_mouse_position()
	var distance = global_position.distance_to(mouse_pos)
	return distance < 75.0  # Collision radius

func on_clicked():
	"""Handle building being clicked"""
	if is_destroyed:
		return
	
	# Select this building
	if SelectionManager:
		SelectionManager.select_building(self)
	
	building_selected.emit()

func set_selected(selected: bool):
	"""Set selection state"""
	is_selected = selected
	
	if selection_indicator:
		selection_indicator.visible = selected
	
	if not selected:
		building_deselected.emit()

func take_damage(amount: float, _attacker: Node2D = null):
	"""Take damage from attack"""
	if is_destroyed:
		return
	
	current_health -= amount
	current_health = max(0, current_health)
	
	update_health_bar()
	
	# Check for destruction
	if current_health <= 0:
		destroy()

func destroy():
	"""Destroy the building"""
	if is_destroyed:
		return
	
	is_destroyed = true
	
	# Deselect if selected
	if is_selected:
		if SelectionManager:
			SelectionManager.clear_selection()
	
	# Visual effects
	create_destruction_effect()
	
	# Emit signal
	building_destroyed.emit()
	
	# Unregister
	if EntityManager:
		EntityManager.unregister_building(self)
	
	# Remove from scene
	queue_free()
	

func create_destruction_effect():
	"""Create explosion effect on destruction"""
	# Simple explosion particles
	var explosion = CPUParticles2D.new()
	explosion.global_position = global_position
	explosion.emitting = true
	explosion.one_shot = true
	explosion.explosiveness = 0.9
	explosion.amount = 50
	explosion.lifetime = 1.0
	explosion.speed_scale = 2.0
	explosion.initial_velocity_min = 100.0
	explosion.initial_velocity_max = 200.0
	explosion.color = Color(1.0, 0.5, 0.0)
	
	get_tree().current_scene.add_child(explosion)
	
	# Auto-delete after emission
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(explosion):
		explosion.queue_free()

func update_health_bar():
	"""Update health bar display"""
	if not health_bar:
		return
	
	var health_percent = (current_health / max_health) * 100.0
	health_bar.value = health_percent
	
	# Color code health bar
	if health_percent > 66:
		health_bar.modulate = Color(0.0, 1.0, 0.0)  # Green
	elif health_percent > 33:
		health_bar.modulate = Color(1.0, 1.0, 0.0)  # Yellow
	else:
		health_bar.modulate = Color(1.0, 0.0, 0.0)  # Red

func update_visual_state():
	"""Update visual appearance based on state"""
	if is_under_construction:
		# Show construction state
		if sprite:
			sprite.modulate = Color(1.0, 1.0, 1.0, 0.5)
		
		if construction_particles:
			construction_particles.emitting = true
		
		if research_particles:
			research_particles.emitting = false
	else:
		# Show operational state
		if sprite:
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		
		if construction_particles:
			construction_particles.emitting = false
		
		if research_particles:
			research_particles.emitting = true

func set_construction_progress(progress: float):
	"""Set construction progress (0.0 to 1.0)"""
	construction_progress = clamp(progress, 0.0, 1.0)
	is_under_construction = construction_progress < 1.0
	
	if sprite:
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.3 + construction_progress * 0.7)
	
	if construction_progress >= 1.0:
		complete_construction()

func complete_construction():
	"""Complete construction of the building"""
	is_under_construction = false
	construction_progress = 1.0
	update_visual_state()
	

func get_building_info() -> Dictionary:
	"""Get building information for UI display"""
	return {
		"name": "Research Facility",
		"type": building_type,
		"health": current_health,
		"max_health": max_health,
		"health_percent": (current_health / max_health) * 100.0,
		"zone_id": zone_id,
		"is_operational": not is_under_construction and not is_destroyed,
		"description": "Central research hub for unlocking new technologies"
	}

# Save/Load support
func get_save_data() -> Dictionary:
	"""Get save data for building"""
	return {
		"type": building_type,
		"position": {
			"x": global_position.x,
			"y": global_position.y
		},
		"health": current_health,
		"zone_id": zone_id,
		"team_id": team_id,
		"construction_progress": construction_progress
	}

func load_save_data(data: Dictionary):
	"""Load building from save data"""
	if "health" in data:
		current_health = data.health
		update_health_bar()
	
	if "zone_id" in data:
		zone_id = data.zone_id
	
	if "team_id" in data:
		team_id = data.team_id
	
	if "construction_progress" in data:
		set_construction_progress(data.construction_progress)


