extends Control
## Fullscreen blueprint builder UI

@export var grid_cols: int = 30
@export var grid_rows: int = 18
@export var cell_px: int = 32

@onready var components_list: VBoxContainer = $RightPanel/Scroll/VBox
@onready var grid: Control = $LeftPanel/BlueprintGrid
@onready var total_cost_label: Label = $BottomBar/TotalCost
@onready var validate_label: Label = $BottomBar/Validation
@onready var save_button: Button = $BottomBar/SaveButton
@onready var build_button: Button = $BottomBar/BuildButton
@onready var clear_button: Button = $BottomBar/ClearButton

var current_component_id: String = ""
var placements: Array = []  # [{id, x, y}]

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rebuild_components_list()
	if grid.has_method("configure_grid"):
		grid.configure_grid(grid_cols, grid_rows, cell_px)
	if grid.has_signal("cell_clicked"):
		grid.cell_clicked.connect(_on_cell_clicked)
	if BlueprintManager and BlueprintManager.has_signal("unlocked_components_changed"):
		BlueprintManager.unlocked_components_changed.connect(_rebuild_components_list)
	_update_costs_and_validation()
	# Wire buttons
	save_button.pressed.connect(_on_SaveButton_pressed)
	build_button.pressed.connect(_on_BuildButton_pressed)
	clear_button.pressed.connect(_on_ClearButton_pressed)

func _rebuild_components_list():
	for c in components_list.get_children():
		c.queue_free()
	var all = BlueprintDatabase.get_all_components()
	all.sort_custom(func(a, b): return a.category < b.category or (a.category == b.category and a.tier < b.tier))
	for comp in all:
		var btn = Button.new()
		btn.text = "%s (T%d)" % [comp.name, comp.tier + 1]
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.disabled = not BlueprintManager.is_component_unlocked(comp.id)
		btn.pressed.connect(func():
			current_component_id = comp.id
		)
		components_list.add_child(btn)

func _on_cell_clicked(cell: Vector2i):
	if current_component_id == "":
		return
	# Place component at cell origin if valid (simple overlap check)
	var comp = BlueprintDatabase.get_component_by_id(current_component_id)
	if comp.is_empty():
		return
	var size: Vector2i = comp.size
	# Prevent overlap
	for p in placements:
		var c2 = BlueprintDatabase.get_component_by_id(p.id)
		if c2.is_empty():
			continue
		var rect1 = Rect2i(cell.x, cell.y, size.x, size.y)
		var rect2 = Rect2i(p.x, p.y, c2.size.x, c2.size.y)
		if rect1.intersects(rect2):
			return
	placements.append({ "id": current_component_id, "x": cell.x, "y": cell.y })
	if grid.has_method("set_placements"):
		grid.set_placements(placements)
	_update_costs_and_validation()

func _update_costs_and_validation():
	var total = BlueprintManager.compute_total_cost(placements)
	var parts := []
	for rid in total.keys():
		parts.append("%s:%d" % [str(rid), int(total[rid])])
	total_cost_label.text = "Cost: " + ", ".join(parts)
	var validation = BlueprintManager.validate_layout(placements, grid_cols, grid_rows)
	validate_label.text = ("Valid" if validation.ok else ("Invalid: %s" % validation.reason))
	build_button.disabled = not validation.ok or not ResourceManager.can_afford_cost(total)

func _on_SaveButton_pressed():
	BlueprintManager.save_blueprint("custom", grid_cols, grid_rows, cell_px, placements)

func _on_BuildButton_pressed():
	var zone_id = ZoneManager.current_zone_id
	var cam = get_viewport().get_camera_2d()
	var spawn_pos = cam.global_position if cam else Vector2.ZERO
	if BlueprintManager.build_blueprint(placements, zone_id, spawn_pos):
		hide()

func _on_ClearButton_pressed():
	placements.clear()
	if grid.has_method("set_placements"):
		grid.set_placements(placements)
	_update_costs_and_validation()
