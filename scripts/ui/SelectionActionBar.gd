extends HBoxContainer
## Quick action bar for mass unit commands

@onready var stop_btn: Button = $StopBtn
@onready var attack_move_btn: Button = $AttackMoveBtn
@onready var patrol_btn: Button = $PatrolBtn
@onready var return_cargo_btn: Button = $ReturnCargoBtn

var awaiting_command: String = ""

func _ready():
	if stop_btn:
		stop_btn.pressed.connect(_on_stop_pressed)
	if attack_move_btn:
		attack_move_btn.pressed.connect(_on_attack_move_pressed)
	if patrol_btn:
		patrol_btn.pressed.connect(_on_patrol_pressed)
	if return_cargo_btn:
		return_cargo_btn.pressed.connect(_on_return_cargo_pressed)
	
	# Update button availability based on selection
	SelectionManager.selection_changed.connect(_on_selection_changed)
	update_button_states()

func _on_selection_changed(_units: Array):
	update_button_states()

func update_button_states():
	"""Enable/disable buttons based on what's selected"""
	var units = SelectionManager.selected_units
	
	# Stop button - always available if units selected
	if stop_btn:
		stop_btn.disabled = units.is_empty()
	
	# Attack-move - only for combat units
	if attack_move_btn:
		var has_combat = false
		for unit in units:
			if is_instance_valid(unit) and unit.can_attack():
				has_combat = true
				break
		attack_move_btn.disabled = not has_combat
	
	# Return cargo - only for mining drones with cargo
	if return_cargo_btn:
		var has_cargo = false
		for unit in units:
			if is_instance_valid(unit) and unit is MiningDrone:
				var miner = unit as MiningDrone
				if miner.carrying_resources > 0:
					has_cargo = true
					break
		return_cargo_btn.disabled = not has_cargo
	
	# Patrol - available for all mobile units
	if patrol_btn:
		patrol_btn.disabled = units.is_empty()

func _on_stop_pressed():
	var units = SelectionManager.selected_units
	CommandSystem.issue_hold_command(units)
	AudioManager.play_sound("button_click")

func _on_attack_move_pressed():
	# Set attack-move mode (player clicks where to attack-move)
	awaiting_command = "attack_move"
	# TODO: Change cursor, wait for player to click position
	print("Attack-move mode activated - click to set destination")

func _on_patrol_pressed():
	# Set patrol mode
	awaiting_command = "patrol"
	# TODO: Change cursor, wait for player to set patrol points
	print("Patrol mode activated - click to set patrol waypoints")

func _on_return_cargo_pressed():
	var units = SelectionManager.selected_units
	CommandSystem.issue_return_command(units)
	AudioManager.play_sound("button_click")

