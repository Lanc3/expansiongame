extends Node2D
class_name WeaponAttackMarker
## Visual marker for weapon ground attack targeting
## Supports AOE radius visualization for explosive weapons

signal marker_clicked(marker: WeaponAttackMarker)

# References set by CustomShip
var weapon_index: int = -1
var weapon_type: int = 0  # WeaponComponent.WeaponType enum value
var ship: Node2D = null  # Reference to owning CustomShip

# AOE properties
var aoe_radius: float = 0.0  # Base AOE radius (0 = non-AOE weapon)
var current_aoe_radius: float = 0.0  # Adjustable AOE radius
var is_aoe_weapon: bool = false

# Visual components
var icon_sprite: Sprite2D = null
var label_node: Label = null
var targeting_line: Line2D = null
var click_area: Area2D = null
var aoe_circle: Line2D = null  # AOE radius indicator

# State
var is_in_range: bool = true
var is_weapon_selected: bool = false

# Textures - default icons
const LASER_ICON_PATH = "res://assets/ui/Ship Component Ui/laser weapon icon.png"
const MISSILE_ICON_PATH = "res://assets/sprites/Missiles/missile.png"

# Weapon type icon mapping (can be expanded)
const WEAPON_ICONS = {
	0: "res://assets/ui/Ship Component Ui/laser weapon icon.png",      # LASER
	1: "res://assets/sprites/Missiles/missile.png",                    # MISSILE
	2: "res://assets/ui/Ship Component Ui/laser weapon icon.png",      # AUTOCANNON
	3: "res://assets/ui/Ship Component Ui/laser weapon icon.png",      # RAILGUN
	4: "res://assets/ui/Ship Component Ui/laser weapon icon.png",      # GATLING
	5: "res://assets/ui/Ship Component Ui/laser weapon icon.png",      # SNIPER
	6: "res://assets/ui/Ship Component Ui/laser weapon icon.png",      # SHOTGUN
	7: "res://assets/ui/Ship Component Ui/laser weapon icon.png",      # ION_CANNON
	8: "res://assets/ui/Ship Component Ui/laser weapon icon.png",      # PLASMA_CANNON
	9: "res://assets/ui/Ship Component Ui/laser weapon icon.png",      # PARTICLE_BEAM
	10: "res://assets/ui/Ship Component Ui/laser weapon icon.png",     # TESLA_COIL
	11: "res://assets/ui/Ship Component Ui/laser weapon icon.png",     # DISRUPTOR
	12: "res://assets/sprites/Missiles/missile.png",                   # FLAK_CANNON (AOE)
	13: "res://assets/sprites/Missiles/missile.png",                   # TORPEDO (AOE)
	14: "res://assets/sprites/Missiles/missile.png",                   # ROCKET_POD
	15: "res://assets/sprites/Missiles/missile.png",                   # MORTAR (AOE)
	16: "res://assets/sprites/Missiles/missile.png",                   # MINE_LAYER (AOE)
	17: "res://assets/ui/Ship Component Ui/laser weapon icon.png",     # CRYO_CANNON
	18: "res://assets/ui/Ship Component Ui/laser weapon icon.png",     # EMP_BURST (AOE)
	19: "res://assets/ui/Ship Component Ui/laser weapon icon.png",     # GRAVITY_WELL (AOE)
	20: "res://assets/ui/Ship Component Ui/laser weapon icon.png"      # REPAIR_BEAM
}

# Weapon type colors for AOE circles and tinting
const WEAPON_COLORS = {
	0: Color(1.0, 0.3, 0.3, 1.0),        # LASER - Red
	1: Color(1.0, 0.7, 0.2, 1.0),        # MISSILE - Orange
	2: Color(0.9, 0.8, 0.4, 1.0),        # AUTOCANNON - Brass
	3: Color(0.3, 0.5, 1.0, 1.0),        # RAILGUN - Blue
	4: Color(1.0, 1.0, 0.9, 1.0),        # GATLING - White
	5: Color(0.3, 1.0, 0.3, 1.0),        # SNIPER - Green
	6: Color(1.0, 0.9, 0.5, 1.0),        # SHOTGUN - Light brass
	7: Color(0.3, 0.6, 1.0, 1.0),        # ION_CANNON - Blue
	8: Color(0.3, 1.0, 0.4, 1.0),        # PLASMA_CANNON - Green
	9: Color(0.8, 0.3, 1.0, 1.0),        # PARTICLE_BEAM - Purple
	10: Color(0.4, 0.8, 1.0, 1.0),       # TESLA_COIL - Electric blue
	11: Color(1.0, 0.4, 0.8, 1.0),       # DISRUPTOR - Pink
	12: Color(1.0, 0.5, 0.2, 1.0),       # FLAK_CANNON - Dark orange
	13: Color(0.7, 0.9, 1.0, 1.0),       # TORPEDO - Light blue
	14: Color(1.0, 0.6, 0.3, 1.0),       # ROCKET_POD - Light orange
	15: Color(0.6, 0.5, 0.4, 1.0),       # MORTAR - Brown
	16: Color(0.8, 0.2, 0.2, 1.0),       # MINE_LAYER - Dark red
	17: Color(0.6, 0.9, 1.0, 1.0),       # CRYO_CANNON - Light blue
	18: Color(0.5, 0.3, 1.0, 1.0),       # EMP_BURST - Electric purple
	19: Color(0.4, 0.0, 0.6, 1.0),       # GRAVITY_WELL - Dark purple
	20: Color(0.3, 1.0, 0.3, 1.0)        # REPAIR_BEAM - Green
}

func _ready():
	# Create nodes if not already created (setup may have been called first)
	if not icon_sprite:
		_create_nodes()

func _create_nodes():
	"""Create all child nodes - called from _ready or setup, whichever comes first"""
	if icon_sprite:
		return  # Already created
	
	# Create AOE circle (rendered behind everything else)
	aoe_circle = Line2D.new()
	aoe_circle.name = "AOECircle"
	aoe_circle.width = 3.0
	aoe_circle.default_color = Color(1.0, 0.5, 0.2, 0.6)
	aoe_circle.visible = false
	aoe_circle.z_index = -2
	add_child(aoe_circle)
	
	# Create icon sprite
	icon_sprite = Sprite2D.new()
	icon_sprite.name = "Icon"
	add_child(icon_sprite)
	
	# Create label for weapon number
	label_node = Label.new()
	label_node.name = "WeaponLabel"
	label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_node.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label_node.add_theme_font_size_override("font_size", 12)
	label_node.add_theme_color_override("font_color", Color.WHITE)
	label_node.add_theme_color_override("font_outline_color", Color.BLACK)
	label_node.add_theme_constant_override("outline_size", 2)
	add_child(label_node)
	
	# Create targeting line (hidden by default)
	targeting_line = Line2D.new()
	targeting_line.name = "TargetingLine"
	targeting_line.width = 2.0
	targeting_line.default_color = Color(1.0, 0.3, 0.3, 0.6)
	targeting_line.visible = false
	targeting_line.z_index = -1  # Behind marker icon
	add_child(targeting_line)
	
	# Create click detection area
	click_area = Area2D.new()
	click_area.name = "ClickArea"
	click_area.input_pickable = true
	click_area.collision_layer = 0
	click_area.collision_mask = 0
	
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 20.0
	collision_shape.shape = circle_shape
	click_area.add_child(collision_shape)
	
	click_area.input_event.connect(_on_click_area_input_event)
	add_child(click_area)
	
	# Set z_index to render above game world
	z_index = 50

func setup(p_weapon_index: int, p_weapon_type: int, p_label: String, p_ship: Node2D, p_aoe_radius: float = 0.0):
	"""Initialize the marker with weapon info"""
	weapon_index = p_weapon_index
	weapon_type = p_weapon_type
	ship = p_ship
	aoe_radius = p_aoe_radius
	current_aoe_radius = p_aoe_radius  # Initialize adjustable radius to base
	is_aoe_weapon = p_aoe_radius > 0
	
	# Ensure nodes are created (in case setup is called before _ready)
	if not icon_sprite:
		_create_nodes()
	
	# Set appropriate icon based on weapon type
	var icon_path = WEAPON_ICONS.get(p_weapon_type, LASER_ICON_PATH)
	
	if ResourceLoader.exists(icon_path):
		var texture = load(icon_path)
		if texture and icon_sprite:
			icon_sprite.texture = texture
			# Scale icon to reasonable size (32x32)
			var tex_size = texture.get_size()
			if tex_size.x > 0 and tex_size.y > 0:
				icon_sprite.scale = Vector2(32.0 / tex_size.x, 32.0 / tex_size.y)
	
	# Tint icon based on weapon type
	var weapon_color = WEAPON_COLORS.get(p_weapon_type, Color.WHITE)
	if icon_sprite:
		icon_sprite.modulate = weapon_color
	
	# Set label text
	if label_node:
		label_node.text = p_label
		# Position label below icon
		label_node.position = Vector2(-30, 18)
		label_node.size = Vector2(60, 20)
	
	# Set targeting line color to match weapon
	if targeting_line:
		targeting_line.default_color = Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.6)
	
	# Update AOE circle
	if is_aoe_weapon:
		_create_aoe_circle(current_aoe_radius, weapon_color)
		aoe_circle.visible = true
	else:
		aoe_circle.visible = false
	
	# Update collision shape to match icon size
	if click_area and click_area.get_child_count() > 0:
		var collision = click_area.get_child(0) as CollisionShape2D
		if collision and collision.shape is CircleShape2D:
			# Make click area larger for AOE weapons
			if is_aoe_weapon:
				collision.shape.radius = max(25.0, aoe_radius * 0.5)
			else:
				collision.shape.radius = 18.0

func _create_aoe_circle(radius: float, color: Color):
	"""Create the AOE radius indicator circle"""
	if not aoe_circle:
		return
	
	# Generate circle points
	var points = PackedVector2Array()
	var segments = 48
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	aoe_circle.points = points
	aoe_circle.default_color = Color(color.r, color.g, color.b, 0.5)
	aoe_circle.width = 2.0

func _process(_delta: float):
	# Update targeting line if visible
	if targeting_line.visible and ship and is_instance_valid(ship):
		_update_targeting_line()
	
	# Update out-of-range visual state
	_update_range_visual()
	
	# Animate AOE circle if visible
	if aoe_circle and aoe_circle.visible:
		_animate_aoe_circle(_delta)

func _animate_aoe_circle(_delta: float):
	"""Subtle pulse animation for AOE circle"""
	var time = Time.get_ticks_msec() / 1000.0
	var pulse = 1.0 + sin(time * 3.0) * 0.05  # 5% pulse
	aoe_circle.scale = Vector2(pulse, pulse)
	
	# Also pulse the alpha
	var alpha = 0.4 + sin(time * 2.0) * 0.15
	var base_color = aoe_circle.default_color
	aoe_circle.default_color = Color(base_color.r, base_color.g, base_color.b, alpha)

func _update_targeting_line():
	"""Update the line from turret to this marker"""
	if weapon_index < 0 or not ship:
		return
	
	# Get turret position from ship
	if ship.has_method("get_weapon_turret_position"):
		var turret_pos = ship.get_weapon_turret_position(weapon_index)
		if turret_pos != Vector2.ZERO:
			# Line points are in local space
			targeting_line.clear_points()
			targeting_line.add_point(to_local(turret_pos))
			targeting_line.add_point(Vector2.ZERO)  # Marker is at origin

func _update_range_visual():
	"""Update visual state based on whether marker is in weapon range"""
	if not ship or not is_instance_valid(ship):
		return
	
	# Check if in range
	var in_range = _check_in_range()
	
	if in_range != is_in_range:
		is_in_range = in_range
		# Dim the marker when out of range
		if is_in_range:
			modulate = Color.WHITE
			if aoe_circle:
				aoe_circle.modulate = Color.WHITE
		else:
			modulate = Color(0.5, 0.5, 0.5, 0.7)
			if aoe_circle:
				aoe_circle.modulate = Color(0.5, 0.5, 0.5, 0.5)

func _check_in_range() -> bool:
	"""Check if this marker is within weapon range"""
	if weapon_index < 0 or not ship or not is_instance_valid(ship):
		return false
	
	if not "weapon_components" in ship:
		return false
	
	if weapon_index >= ship.weapon_components.size():
		return false
	
	var weapon = ship.weapon_components[weapon_index]
	var weapon_range = weapon.get_range()
	
	# Get weapon world position
	var weapon_pos = ship.global_position
	if ship.has_method("get_weapon_turret_position"):
		weapon_pos = ship.get_weapon_turret_position(weapon_index)
	
	var distance = weapon_pos.distance_to(global_position)
	return distance <= weapon_range

func set_weapon_selected(selected: bool):
	"""Show/hide targeting line based on weapon selection"""
	is_weapon_selected = selected
	targeting_line.visible = selected
	
	# Get weapon color
	var weapon_color = WEAPON_COLORS.get(weapon_type, Color(1.0, 0.3, 0.3))
	
	# Update line color based on selection
	if selected:
		targeting_line.default_color = Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.8)
		targeting_line.width = 3.0
	else:
		targeting_line.default_color = Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.4)
		targeting_line.width = 2.0

func get_aoe_radius() -> float:
	"""Get the base AOE radius for this marker's weapon"""
	return aoe_radius

func get_current_aoe_radius() -> float:
	"""Get the current adjustable AOE radius"""
	return current_aoe_radius if current_aoe_radius > 0 else aoe_radius

func set_aoe_radius(new_radius: float):
	"""Set a new AOE radius and update the visual circle"""
	current_aoe_radius = new_radius
	if is_aoe_weapon and aoe_circle:
		var weapon_color = WEAPON_COLORS.get(weapon_type, Color(1.0, 0.5, 0.2, 0.6))
		_create_aoe_circle(new_radius, weapon_color)

func is_aoe() -> bool:
	"""Check if this marker is for an AOE weapon"""
	return is_aoe_weapon

func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	"""Handle clicks on the marker"""
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			# Emit signal for ship to handle removal
			marker_clicked.emit(self)
			get_viewport().set_input_as_handled()
