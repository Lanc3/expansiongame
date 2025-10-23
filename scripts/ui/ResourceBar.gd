extends Panel
## Top resource bar showing materials, time, and unit count

@onready var common_label: Label = $HBoxContainer/CommonContainer/Label
@onready var rare_label: Label = $HBoxContainer/RareContainer/Label
@onready var exotic_label: Label = $HBoxContainer/ExoticContainer/Label
@onready var time_label: Label = $HBoxContainer/TimeLabel
@onready var unit_count_label: Label = $HBoxContainer/UnitCountLabel

func _ready():
	ResourceManager.resources_changed.connect(_on_resources_changed)
	update_resources(
		ResourceManager.common_material,
		ResourceManager.rare_material,
		ResourceManager.exotic_material
	)

func _process(_delta: float):
	update_time_display()
	update_unit_count()

func _on_resources_changed(common: float, rare: float, exotic: float):
	update_resources(common, rare, exotic)

func update_resources(common: float, rare: float, exotic: float):
	if common_label:
		common_label.text = str(int(common))
	if rare_label:
		rare_label.text = str(int(rare))
	if exotic_label:
		exotic_label.text = str(int(exotic))

func update_time_display():
	if not time_label:
		return
	
	var minutes = int(GameManager.game_time) / 60
	var seconds = int(GameManager.game_time) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

func update_unit_count():
	if not unit_count_label:
		return
	
	var player_units = EntityManager.get_units_by_team(0)
	unit_count_label.text = "Units: %d" % player_units.size()
