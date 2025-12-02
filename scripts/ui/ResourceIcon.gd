extends PanelContainer
class_name ResourceIcon

## Displays a single resource with colored background, acronym, and count

@onready var icon_texture: TextureRect = $VBox/IconTexture
@onready var background: ColorRect = $VBox/Background
@onready var acronym_label: Label = $VBox/AcronymLabel
@onready var count_label: Label = $VBox/CountLabel

var resource_id: int = 0
var resource_data: Dictionary = {}
var current_count: int = 0

func setup(res_id: int, res_data: Dictionary):
	resource_id = res_id
	resource_data = res_data
	
	if background:
		background.color = res_data.color
		
		# Set contrasting text color for readability
		var text_color = get_contrasting_text_color(res_data.color)
		if acronym_label:
			acronym_label.add_theme_color_override("font_color", text_color)
		if count_label:
			count_label.add_theme_color_override("font_color", text_color)
	
	if acronym_label:
		acronym_label.text = generate_3letter_acronym(res_data.name)
	
	# Load and set resource icon
	if icon_texture:
		var icon_path = ResourceDatabase.get_resource_icon_path(res_id)
		if icon_path != "" and ResourceLoader.exists(icon_path):
			var texture = load(icon_path)
			if texture:
				icon_texture.texture = texture
				icon_texture.visible = true
				icon_texture.custom_minimum_size = Vector2(30, 30)
				
				# Apply shader to remove white backgrounds
				var shader_path = "res://shaders/remove_white_background.gdshader"
				if ResourceLoader.exists(shader_path):
					var shader = load(shader_path) as Shader
					if shader:
						var material = ShaderMaterial.new()
						material.shader = shader
						icon_texture.material = material
				
				# Hide acronym label when icon is present
				if acronym_label:
					acronym_label.visible = false
			else:
				icon_texture.visible = false
				if acronym_label:
					acronym_label.visible = true
		else:
			icon_texture.visible = false
			if acronym_label:
				acronym_label.visible = true
	
	tooltip_text = "%s (Tier %d)" % [res_data.name, res_data.tier]
	update_count(0)

func update_count(count: int):
	current_count = count
	
	if count_label:
		count_label.text = str(count)
	
	# Dim if zero, full opacity if has resources
	if count == 0:
		modulate = Color(0.5, 0.5, 0.5, 0.6)  # Dimmed/grayed
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)  # Full brightness

func get_contrasting_text_color(bg_color: Color) -> Color:
	"""Calculate contrasting text color based on background brightness"""
	# Calculate perceived luminance (0.0 to 1.0)
	var luminance = (0.299 * bg_color.r) + (0.587 * bg_color.g) + (0.114 * bg_color.b)
	
	# Return black for bright backgrounds, white for dark backgrounds
	if luminance > 0.5:
		return Color.BLACK
	else:
		return Color.WHITE

func generate_3letter_acronym(name: String) -> String:
	var words = name.split(" ")
	var result = ""
	
	if words.size() >= 3:
		# 3+ words: first letter of each word
		result = words[0][0] + words[1][0] + words[2][0]
	elif words.size() == 2:
		# 2 words: first letter of first + first 2 of second
		result = words[0][0] + words[1].substr(0, 2)
	else:
		# 1 word: first 3 letters
		result = name.substr(0, min(3, name.length()))
	
	# Always uppercase
	return result.to_upper()

