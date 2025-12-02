extends Node2D
class_name ShieldComponent
## Shield generator component for ships

signal shield_hit(damage: float)
signal shield_depleted()
signal shield_recharged()

@export var max_shield: float = 100.0
@export var recharge_rate: float = 5.0  # HP per second
@export var recharge_delay: float = 3.0  # Seconds after hit before recharge starts
@export var shield_radius: float = 50.0

var current_shield: float = 0.0
var recharge_timer: float = 0.0
var is_recharging: bool = false

# Visual components
var shield_visual: Node2D = null
var shield_sprite: Sprite2D = null
var hit_flash_timer: float = 0.0
var pulse_timer: float = 0.0

func _ready():
	current_shield = max_shield
	_create_shield_visual()

func _process(delta: float):
	# Handle recharge delay
	if recharge_timer > 0:
		recharge_timer -= delta
		if recharge_timer <= 0:
			is_recharging = true
	
	# Recharge shield
	if is_recharging and current_shield < max_shield:
		current_shield = min(current_shield + recharge_rate * delta, max_shield)
		if current_shield >= max_shield:
			shield_recharged.emit()
	
	# Update visual
	_update_shield_visual(delta)

func take_damage(amount: float) -> float:
	"""Apply damage to shield, returns excess damage that bleeds through"""
	var excess_damage = 0.0
	
	if current_shield > 0:
		shield_hit.emit(amount)
		
		if amount > current_shield:
			excess_damage = amount - current_shield
			current_shield = 0.0
			shield_depleted.emit()
		else:
			current_shield -= amount
		
		# Reset recharge timer
		recharge_timer = recharge_delay
		is_recharging = false
		
		# Trigger hit flash
		hit_flash_timer = 0.2
	else:
		# Shield is down, all damage passes through
		excess_damage = amount
	
	return excess_damage

func get_shield_percentage() -> float:
	"""Get shield percentage (0.0 to 1.0)"""
	return current_shield / max_shield if max_shield > 0 else 0.0

func _create_shield_visual():
	"""Create the visual representation of the shield"""
	shield_visual = Node2D.new()
	shield_visual.name = "ShieldVisual"
	shield_visual.z_index = -1
	add_child(shield_visual)
	
	# Create circular shield sprite using Line2D
	var shield_line = Line2D.new()
	shield_line.name = "ShieldCircle"
	shield_line.width = 3.0
	shield_line.default_color = Color(0.3, 0.6, 1.0, 0.2)  # Blue with transparency
	shield_line.antialiased = true
	
	# Generate circle points
	var segments = 32
	for i in range(segments + 1):
		var angle = (i * TAU) / segments
		var point = Vector2(cos(angle), sin(angle)) * shield_radius
		shield_line.add_point(point)
	
	shield_visual.add_child(shield_line)
	
	# Initially visible
	shield_visual.visible = current_shield > 0

func _update_shield_visual(delta: float):
	"""Update shield visual effects"""
	if not shield_visual:
		return
	
	# Show/hide based on shield status
	shield_visual.visible = current_shield > 0
	
	if not shield_visual.visible:
		return
	
	var shield_line = shield_visual.get_node_or_null("ShieldCircle")
	if not shield_line:
		return
	
	# Hit flash effect
	if hit_flash_timer > 0:
		hit_flash_timer -= delta
		var flash_intensity = hit_flash_timer / 0.2
		shield_line.default_color = Color(1.0, 0.9, 1.0, 0.5 * flash_intensity)
	else:
		# Normal shield appearance with subtle pulse
		pulse_timer += delta
		var pulse = 0.15 + 0.05 * sin(pulse_timer * 3.0)
		var shield_pct = get_shield_percentage()
		var alpha = 0.15 + (0.1 * shield_pct) + pulse
		shield_line.default_color = Color(0.3, 0.6, 1.0, alpha)
	
	# Scale based on shield strength
	var scale_factor = 0.9 + (0.1 * get_shield_percentage())
	shield_visual.scale = Vector2(scale_factor, scale_factor)


