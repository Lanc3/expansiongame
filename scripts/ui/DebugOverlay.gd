extends Panel
## Debug overlay showing performance metrics

@onready var fps_label: Label = $VBoxContainer/FPSLabel
@onready var entity_label: Label = $VBoxContainer/EntityLabel
@onready var memory_label: Label = $VBoxContainer/MemoryLabel
@onready var selection_label: Label = $VBoxContainer/SelectionLabel

func _ready():
	# Position in top-left corner
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(10, 10)
	size = Vector2(250, 150)

func _process(_delta: float):
	update_debug_info()

func update_debug_info():
	if fps_label:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	
	if entity_label:
		entity_label.text = "Units: %d | Resources: %d" % [
			EntityManager.units.size(),
			EntityManager.resources.size()
		]
	
	if memory_label:
		var mem_mb = OS.get_static_memory_usage() / 1024.0 / 1024.0
		memory_label.text = "Memory: %.1f MB" % mem_mb
	
	#if selection_label:
		##selection_label.text = "Selected: %d" % SelectionManager.get_selection_count()
