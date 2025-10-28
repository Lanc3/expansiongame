extends Panel
## Information panel for wormhole destinations

signal travel_requested(target_zone_id: String)

@onready var zone_title: Label = $VBoxContainer/ZoneTitle
@onready var zone_info: Label = $VBoxContainer/ZoneInfo
@onready var common_bar: ProgressBar = $VBoxContainer/Resources/CommonBar
@onready var common_label: Label = $VBoxContainer/Resources/CommonLabel
@onready var uncommon_bar: ProgressBar = $VBoxContainer/Resources/UncommonBar
@onready var uncommon_label: Label = $VBoxContainer/Resources/UncommonLabel
@onready var rare_bar: ProgressBar = $VBoxContainer/Resources/RareBar
@onready var rare_label: Label = $VBoxContainer/Resources/RareLabel
@onready var ultra_rare_bar: ProgressBar = $VBoxContainer/Resources/UltraRareBar
@onready var ultra_rare_label: Label = $VBoxContainer/Resources/UltraRareLabel
@onready var resource_types_label: Label = $VBoxContainer/Stats/ResourceTypesLabel
@onready var asteroid_count_label: Label = $VBoxContainer/Stats/AsteroidCountLabel
@onready var value_rating_label: Label = $VBoxContainer/Stats/ValueRatingLabel
@onready var travel_button: Button = $VBoxContainer/TravelButton
@onready var close_button: Button = $VBoxContainer/CloseButton

var current_zone_id: String = ""
var tween: Tween

func _ready():
	hide()
	travel_button.pressed.connect(_on_travel_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Style the panel
	modulate.a = 0.0

func show_for_wormhole(wormhole: Node2D):
	"""Display info panel for a wormhole's target zone"""
	if not wormhole:
		return
	
	var target_zone_id = wormhole.target_zone_id
	current_zone_id = target_zone_id
	
	# Get zone statistics
	var stats = ZoneManager.get_zone_statistics(target_zone_id)
	if stats.is_empty():
		return
	
	# Update UI
	update_display(stats)
	
	# Fade in animation
	show()
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	scale = Vector2(0.95, 0.95)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3)

func update_display(stats: Dictionary):
	"""Update all UI elements with zone statistics"""
	# Title
	if zone_title:
		zone_title.text = "★ ZONE %s: DEEP SPACE ★" % stats.zone_id
	
	# Info line
	if zone_info:
		var size_text = "%.0fx AREA" % stats.size_multiplier
		var tier_text = "Tiers 0-%d" % stats.max_tier
		zone_info.text = "[%s] [%s]" % [size_text, tier_text]
	
	# Resource distribution
	var dist = stats.rarity_distribution
	
	if common_bar and common_label:
		common_bar.value = dist.common
		common_label.text = "Common (%d%%)" % dist.common
	
	if uncommon_bar and uncommon_label:
		uncommon_bar.value = dist.uncommon
		uncommon_label.text = "Uncommon (%d%%)" % dist.uncommon
	
	if rare_bar and rare_label:
		rare_bar.value = dist.rare
		rare_label.text = "Rare (%d%%)" % dist.rare
	
	if ultra_rare_bar and ultra_rare_label:
		ultra_rare_bar.value = dist.ultra_rare
		ultra_rare_label.text = "Ultra-Rare (%d%%)" % dist.ultra_rare
	
	# Stats
	if resource_types_label:
		resource_types_label.text = "Resource Types: %d" % stats.resource_types_count
	
	if asteroid_count_label:
		asteroid_count_label.text = "Total Asteroids: %d" % stats.total_asteroids
	
	if value_rating_label:
		var stars = ""
		for i in range(5):
			stars += "★" if i < stats.estimated_value else "☆"
		value_rating_label.text = "Estimated Value: %s" % stars
	
	# Travel button
	if travel_button:
		travel_button.text = "✦ TRAVEL TO ZONE %s ✦" % stats.zone_id

func _on_travel_button_pressed():
	"""Handle travel button click"""
	if not current_zone_id.is_empty():
		travel_requested.emit(current_zone_id)
		hide_panel()

func _on_close_button_pressed():
	"""Handle close button click"""
	hide_panel()

func hide_panel():
	"""Fade out and hide panel"""
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(self, "scale", Vector2(0.95, 0.95), 0.2)
	await tween.finished
	hide()
	scale = Vector2.ONE
