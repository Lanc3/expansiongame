class_name CosmoteerComponentDefs
extends RefCounted
## Static definitions for Cosmoteer-style ship components with 9-level progression

# Component types with 9 levels each
const COMPONENT_TYPES = {
	"power_core": {
		"name": "Power Core",
		"base_sprite": "res://assets/sprites/UI/PowerCore.png",
		"description": "Generates power for ship systems",
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_generated": 5, "power_consumed": 0, "weight": 8.0, "cost": {0: 25, 1: 10}},
			{"level": 2, "size": Vector2i(1, 2), "power_generated": 7, "power_consumed": 0, "weight": 10.0, "cost": {0: 20, 10: 15}},
			{"level": 3, "size": Vector2i(2, 1), "power_generated": 10, "power_consumed": 0, "weight": 13.0, "cost": {10: 30, 20: 20}},
			{"level": 4, "size": Vector2i(2, 2), "power_generated": 15, "power_consumed": 0, "weight": 16.0, "cost": {20: 40, 30: 30}},
			{"level": 5, "size": Vector2i(2, 2), "power_generated": 20, "power_consumed": 0, "weight": 20.0, "cost": {30: 50, 40: 40}},
			{"level": 6, "size": Vector2i(2, 3), "power_generated": 30, "power_consumed": 0, "weight": 26.0, "cost": {40: 60, 50: 50}},
			{"level": 7, "size": Vector2i(3, 2), "power_generated": 40, "power_consumed": 0, "weight": 33.0, "cost": {50: 70, 60: 60}},
			{"level": 8, "size": Vector2i(3, 3), "power_generated": 60, "power_consumed": 0, "weight": 43.0, "cost": {60: 80, 70: 70}},
			{"level": 9, "size": Vector2i(3, 3), "power_generated": 80, "power_consumed": 0, "weight": 56.0, "cost": {70: 100, 80: 80}}
		]
	},
	"engine": {
		"name": "Engine",
		"base_sprite": "res://assets/sprites/UI/engineImage.png",
		"description": "Provides thrust for movement",
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 2, "thrust": 30.0, "speed_boost": 25, "weight": 10.0, "cost": {0: 15, 2: 5}},
			{"level": 2, "size": Vector2i(1, 2), "power_consumed": 2, "thrust": 50.0, "speed_boost": 35, "weight": 13.0, "cost": {0: 12, 10: 8}},
			{"level": 3, "size": Vector2i(2, 2), "power_consumed": 3, "thrust": 100.0, "speed_boost": 50, "weight": 20.0, "cost": {10: 18, 20: 12}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 4, "thrust": 150.0, "speed_boost": 70, "weight": 26.0, "cost": {20: 25, 30: 18}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 5, "thrust": 220.0, "speed_boost": 90, "weight": 34.0, "cost": {30: 35, 40: 25}},
			{"level": 6, "size": Vector2i(2, 3), "power_consumed": 7, "thrust": 320.0, "speed_boost": 120, "weight": 44.0, "cost": {40: 50, 50: 35}},
			{"level": 7, "size": Vector2i(3, 2), "power_consumed": 9, "thrust": 450.0, "speed_boost": 160, "weight": 57.0, "cost": {50: 70, 60: 50}},
			{"level": 8, "size": Vector2i(3, 3), "power_consumed": 12, "thrust": 650.0, "speed_boost": 210, "weight": 75.0, "cost": {60: 100, 70: 70}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 16, "thrust": 900.0, "speed_boost": 280, "weight": 97.0, "cost": {70: 140, 80: 100}}
		]
	},
	"laser_weapon": {
		"name": "Laser Weapon",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Rapid-fire laser turret",
		"firing_arc": 180,
		"arc_direction": "forward",
		"weapon_type": "LASER",
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 1, "damage": 5, "fire_rate": 3.0, "range": 300, "projectile_speed": 500, "weight": 4.0, "cost": {0: 10, 1: 8}},
			{"level": 2, "size": Vector2i(1, 2), "power_consumed": 2, "damage": 8, "fire_rate": 3.2, "range": 315, "projectile_speed": 520, "weight": 6.0, "cost": {0: 8, 10: 10}},
			{"level": 3, "size": Vector2i(1, 2), "power_consumed": 2, "damage": 10, "fire_rate": 3.4, "range": 330, "projectile_speed": 540, "weight": 8.0, "cost": {10: 12, 20: 15}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 3, "damage": 15, "fire_rate": 3.6, "range": 345, "projectile_speed": 560, "weight": 10.0, "cost": {20: 18, 30: 20}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 22, "fire_rate": 3.8, "range": 360, "projectile_speed": 580, "weight": 13.0, "cost": {30: 25, 40: 28}},
			{"level": 6, "size": Vector2i(2, 2), "power_consumed": 6, "damage": 32, "fire_rate": 4.0, "range": 375, "projectile_speed": 600, "weight": 17.0, "cost": {40: 35, 50: 40}},
			{"level": 7, "size": Vector2i(2, 3), "power_consumed": 8, "damage": 45, "fire_rate": 4.2, "range": 390, "projectile_speed": 620, "weight": 22.0, "cost": {50: 50, 60: 55}},
			{"level": 8, "size": Vector2i(3, 2), "power_consumed": 12, "damage": 65, "fire_rate": 4.4, "range": 405, "projectile_speed": 640, "weight": 29.0, "cost": {60: 70, 70: 75}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 16, "damage": 90, "fire_rate": 4.6, "range": 420, "projectile_speed": 660, "weight": 38.0, "cost": {70: 100, 80: 110}}
		]
	},
	"missile_launcher": {
		"name": "Missile Launcher",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Launches explosive missiles",
		"firing_arc": 90,
		"arc_direction": "forward",
		"weapon_type": "MISSILE",
		"homing": true,
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 1, "damage": 20, "fire_rate": 0.5, "range": 400, "projectile_speed": 300, "weight": 10.0, "cost": {0: 20, 4: 10}},
			{"level": 2, "size": Vector2i(1, 2), "power_consumed": 2, "damage": 30, "fire_rate": 0.5, "range": 420, "projectile_speed": 320, "weight": 13.0, "cost": {0: 15, 10: 12}},
			{"level": 3, "size": Vector2i(2, 2), "power_consumed": 3, "damage": 50, "fire_rate": 0.6, "range": 440, "projectile_speed": 340, "weight": 17.0, "cost": {10: 25, 20: 20}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 75, "fire_rate": 0.6, "range": 460, "projectile_speed": 360, "weight": 22.0, "cost": {20: 35, 30: 30}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 5, "damage": 110, "fire_rate": 0.7, "range": 480, "projectile_speed": 380, "weight": 29.0, "cost": {30: 50, 40: 45}},
			{"level": 6, "size": Vector2i(2, 3), "power_consumed": 7, "damage": 160, "fire_rate": 0.7, "range": 500, "projectile_speed": 400, "weight": 38.0, "cost": {40: 70, 50: 65}},
			{"level": 7, "size": Vector2i(3, 2), "power_consumed": 10, "damage": 230, "fire_rate": 0.8, "range": 520, "projectile_speed": 420, "weight": 49.0, "cost": {50: 100, 60: 90}},
			{"level": 8, "size": Vector2i(3, 3), "power_consumed": 14, "damage": 330, "fire_rate": 0.8, "range": 540, "projectile_speed": 440, "weight": 64.0, "cost": {60: 140, 70: 130}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 20, "damage": 470, "fire_rate": 0.9, "range": 560, "projectile_speed": 460, "weight": 83.0, "cost": {70: 200, 80: 180}}
		]
	},
	# === KINETIC WEAPONS ===
	"autocannon": {
		"name": "Autocannon",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Rapid-fire ballistic cannon with brass tracers",
		"firing_arc": 120,
		"arc_direction": "forward",
		"weapon_type": "AUTOCANNON",
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 1, "damage": 6, "fire_rate": 4.0, "range": 280, "projectile_speed": 600, "weight": 5.0, "cost": {0: 12, 1: 8}},
			{"level": 2, "size": Vector2i(1, 2), "power_consumed": 2, "damage": 9, "fire_rate": 4.2, "range": 290, "projectile_speed": 620, "weight": 7.0, "cost": {0: 10, 10: 10}},
			{"level": 3, "size": Vector2i(1, 2), "power_consumed": 2, "damage": 12, "fire_rate": 4.4, "range": 300, "projectile_speed": 640, "weight": 9.0, "cost": {10: 14, 20: 12}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 3, "damage": 16, "fire_rate": 4.6, "range": 310, "projectile_speed": 660, "weight": 12.0, "cost": {20: 20, 30: 18}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 21, "fire_rate": 4.8, "range": 320, "projectile_speed": 680, "weight": 15.0, "cost": {30: 28, 40: 24}},
			{"level": 6, "size": Vector2i(2, 2), "power_consumed": 5, "damage": 28, "fire_rate": 5.0, "range": 330, "projectile_speed": 700, "weight": 19.0, "cost": {40: 38, 50: 32}},
			{"level": 7, "size": Vector2i(2, 3), "power_consumed": 7, "damage": 37, "fire_rate": 5.2, "range": 340, "projectile_speed": 720, "weight": 24.0, "cost": {50: 52, 60: 44}},
			{"level": 8, "size": Vector2i(3, 2), "power_consumed": 10, "damage": 49, "fire_rate": 5.4, "range": 350, "projectile_speed": 740, "weight": 31.0, "cost": {60: 72, 70: 60}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 13, "damage": 65, "fire_rate": 5.6, "range": 360, "projectile_speed": 760, "weight": 40.0, "cost": {70: 100, 80: 85}}
		]
	},
	"railgun": {
		"name": "Railgun",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "High-damage piercing weapon with blue energy streak",
		"firing_arc": 60,
		"arc_direction": "forward",
		"weapon_type": "RAILGUN",
		"special_effect": 3,
		"levels": [
			{"level": 1, "size": Vector2i(1, 2), "power_consumed": 3, "damage": 40, "fire_rate": 0.4, "range": 450, "projectile_speed": 1200, "weight": 12.0, "cost": {0: 25, 10: 15}},
			{"level": 2, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 55, "fire_rate": 0.4, "range": 480, "projectile_speed": 1250, "weight": 16.0, "cost": {10: 30, 20: 20}},
			{"level": 3, "size": Vector2i(2, 2), "power_consumed": 5, "damage": 75, "fire_rate": 0.45, "range": 510, "projectile_speed": 1300, "weight": 20.0, "cost": {20: 40, 30: 28}},
			{"level": 4, "size": Vector2i(2, 3), "power_consumed": 7, "damage": 100, "fire_rate": 0.45, "range": 540, "projectile_speed": 1350, "weight": 26.0, "cost": {30: 55, 40: 38}},
			{"level": 5, "size": Vector2i(2, 3), "power_consumed": 9, "damage": 130, "fire_rate": 0.5, "range": 570, "projectile_speed": 1400, "weight": 33.0, "cost": {40: 75, 50: 52}},
			{"level": 6, "size": Vector2i(3, 2), "power_consumed": 12, "damage": 170, "fire_rate": 0.5, "range": 600, "projectile_speed": 1450, "weight": 42.0, "cost": {50: 100, 60: 70}},
			{"level": 7, "size": Vector2i(3, 3), "power_consumed": 16, "damage": 220, "fire_rate": 0.55, "range": 630, "projectile_speed": 1500, "weight": 54.0, "cost": {60: 135, 70: 95}},
			{"level": 8, "size": Vector2i(3, 3), "power_consumed": 21, "damage": 290, "fire_rate": 0.55, "range": 660, "projectile_speed": 1550, "weight": 69.0, "cost": {70: 180, 80: 125}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 28, "damage": 380, "fire_rate": 0.6, "range": 700, "projectile_speed": 1600, "weight": 88.0, "cost": {80: 240, 90: 170}}
		]
	},
	"gatling": {
		"name": "Gatling Gun",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Very high fire rate minigun with white tracers",
		"firing_arc": 90,
		"arc_direction": "forward",
		"weapon_type": "GATLING",
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 2, "damage": 2, "fire_rate": 12.0, "range": 220, "projectile_speed": 550, "weight": 6.0, "cost": {0: 15, 1: 10}},
			{"level": 2, "size": Vector2i(1, 2), "power_consumed": 3, "damage": 3, "fire_rate": 13.0, "range": 230, "projectile_speed": 570, "weight": 8.0, "cost": {0: 12, 10: 12}},
			{"level": 3, "size": Vector2i(2, 1), "power_consumed": 3, "damage": 4, "fire_rate": 14.0, "range": 240, "projectile_speed": 590, "weight": 10.0, "cost": {10: 18, 20: 15}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 5, "fire_rate": 15.0, "range": 250, "projectile_speed": 610, "weight": 13.0, "cost": {20: 26, 30: 20}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 5, "damage": 7, "fire_rate": 16.0, "range": 260, "projectile_speed": 630, "weight": 17.0, "cost": {30: 36, 40: 28}},
			{"level": 6, "size": Vector2i(2, 2), "power_consumed": 7, "damage": 9, "fire_rate": 17.0, "range": 270, "projectile_speed": 650, "weight": 22.0, "cost": {40: 50, 50: 38}},
			{"level": 7, "size": Vector2i(2, 3), "power_consumed": 9, "damage": 12, "fire_rate": 18.0, "range": 280, "projectile_speed": 670, "weight": 28.0, "cost": {50: 68, 60: 52}},
			{"level": 8, "size": Vector2i(3, 2), "power_consumed": 12, "damage": 16, "fire_rate": 19.0, "range": 290, "projectile_speed": 690, "weight": 36.0, "cost": {60: 92, 70: 70}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 16, "damage": 21, "fire_rate": 20.0, "range": 300, "projectile_speed": 710, "weight": 46.0, "cost": {70: 125, 80: 95}}
		]
	},
	"sniper_cannon": {
		"name": "Sniper Cannon",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Extreme range precision weapon with green tracer",
		"firing_arc": 45,
		"arc_direction": "forward",
		"weapon_type": "SNIPER",
		"levels": [
			{"level": 1, "size": Vector2i(1, 2), "power_consumed": 2, "damage": 35, "fire_rate": 0.3, "range": 550, "projectile_speed": 900, "weight": 8.0, "cost": {0: 18, 10: 12}},
			{"level": 2, "size": Vector2i(2, 2), "power_consumed": 3, "damage": 50, "fire_rate": 0.32, "range": 580, "projectile_speed": 950, "weight": 11.0, "cost": {10: 25, 20: 18}},
			{"level": 3, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 70, "fire_rate": 0.34, "range": 610, "projectile_speed": 1000, "weight": 14.0, "cost": {20: 35, 30: 25}},
			{"level": 4, "size": Vector2i(2, 3), "power_consumed": 5, "damage": 95, "fire_rate": 0.36, "range": 640, "projectile_speed": 1050, "weight": 18.0, "cost": {30: 48, 40: 35}},
			{"level": 5, "size": Vector2i(2, 3), "power_consumed": 7, "damage": 130, "fire_rate": 0.38, "range": 670, "projectile_speed": 1100, "weight": 23.0, "cost": {40: 65, 50: 48}},
			{"level": 6, "size": Vector2i(3, 2), "power_consumed": 9, "damage": 175, "fire_rate": 0.40, "range": 700, "projectile_speed": 1150, "weight": 30.0, "cost": {50: 88, 60: 65}},
			{"level": 7, "size": Vector2i(3, 3), "power_consumed": 12, "damage": 235, "fire_rate": 0.42, "range": 730, "projectile_speed": 1200, "weight": 38.0, "cost": {60: 120, 70: 88}},
			{"level": 8, "size": Vector2i(3, 3), "power_consumed": 16, "damage": 315, "fire_rate": 0.44, "range": 760, "projectile_speed": 1250, "weight": 49.0, "cost": {70: 160, 80: 120}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 21, "damage": 420, "fire_rate": 0.46, "range": 800, "projectile_speed": 1300, "weight": 63.0, "cost": {80: 215, 90: 160}}
		]
	},
	"shotgun": {
		"name": "Shotgun",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Close-range cone spread weapon",
		"firing_arc": 180,
		"arc_direction": "forward",
		"weapon_type": "SHOTGUN",
		"projectile_count": 6,
		"spread_angle": 30.0,
		"aoe_type": 2,
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 1, "damage": 30, "fire_rate": 0.8, "range": 180, "projectile_speed": 450, "weight": 5.0, "cost": {0: 12, 1: 8}},
			{"level": 2, "size": Vector2i(1, 2), "power_consumed": 2, "damage": 42, "fire_rate": 0.85, "range": 190, "projectile_speed": 470, "weight": 7.0, "cost": {0: 10, 10: 10}},
			{"level": 3, "size": Vector2i(2, 1), "power_consumed": 2, "damage": 58, "fire_rate": 0.9, "range": 200, "projectile_speed": 490, "weight": 9.0, "cost": {10: 16, 20: 12}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 3, "damage": 80, "fire_rate": 0.95, "range": 210, "projectile_speed": 510, "weight": 12.0, "cost": {20: 22, 30: 18}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 110, "fire_rate": 1.0, "range": 220, "projectile_speed": 530, "weight": 15.0, "cost": {30: 32, 40: 25}},
			{"level": 6, "size": Vector2i(2, 2), "power_consumed": 5, "damage": 150, "fire_rate": 1.05, "range": 230, "projectile_speed": 550, "weight": 19.0, "cost": {40: 45, 50: 35}},
			{"level": 7, "size": Vector2i(2, 3), "power_consumed": 7, "damage": 205, "fire_rate": 1.1, "range": 240, "projectile_speed": 570, "weight": 25.0, "cost": {50: 62, 60: 48}},
			{"level": 8, "size": Vector2i(3, 2), "power_consumed": 9, "damage": 280, "fire_rate": 1.15, "range": 250, "projectile_speed": 590, "weight": 32.0, "cost": {60: 85, 70: 65}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 12, "damage": 380, "fire_rate": 1.2, "range": 260, "projectile_speed": 610, "weight": 41.0, "cost": {70: 115, 80: 90}}
		]
	},
	# === ENERGY WEAPONS ===
	"ion_cannon": {
		"name": "Ion Cannon",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Electric energy ball with EMP effect - disables enemy systems",
		"firing_arc": 90,
		"arc_direction": "forward",
		"weapon_type": "ION_CANNON",
		"is_beam": false,
		"special_effect": 1,
		"effect_duration": 2.0,
		"levels": [
			{"level": 1, "size": Vector2i(1, 2), "power_consumed": 3, "damage": 12, "fire_rate": 1.5, "range": 320, "beam_width": 4, "weight": 8.0, "cost": {0: 20, 10: 12}},
			{"level": 2, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 17, "fire_rate": 1.6, "range": 340, "beam_width": 5, "weight": 11.0, "cost": {10: 28, 20: 18}},
			{"level": 3, "size": Vector2i(2, 2), "power_consumed": 5, "damage": 23, "fire_rate": 1.7, "range": 360, "beam_width": 5, "weight": 14.0, "cost": {20: 38, 30: 25}},
			{"level": 4, "size": Vector2i(2, 3), "power_consumed": 7, "damage": 32, "fire_rate": 1.8, "range": 380, "beam_width": 6, "weight": 18.0, "cost": {30: 52, 40: 35}},
			{"level": 5, "size": Vector2i(2, 3), "power_consumed": 9, "damage": 44, "fire_rate": 1.9, "range": 400, "beam_width": 6, "weight": 23.0, "cost": {40: 70, 50: 48}},
			{"level": 6, "size": Vector2i(3, 2), "power_consumed": 12, "damage": 60, "fire_rate": 2.0, "range": 420, "beam_width": 7, "weight": 30.0, "cost": {50: 95, 60: 65}},
			{"level": 7, "size": Vector2i(3, 3), "power_consumed": 16, "damage": 82, "fire_rate": 2.1, "range": 440, "beam_width": 7, "weight": 38.0, "cost": {60: 128, 70: 88}},
			{"level": 8, "size": Vector2i(3, 3), "power_consumed": 21, "damage": 112, "fire_rate": 2.2, "range": 460, "beam_width": 8, "weight": 49.0, "cost": {70: 172, 80: 120}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 28, "damage": 152, "fire_rate": 2.3, "range": 480, "beam_width": 8, "weight": 63.0, "cost": {80: 230, 90: 160}}
		]
	},
	"plasma_cannon": {
		"name": "Plasma Cannon",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Slow-moving green plasma blob with high damage",
		"firing_arc": 120,
		"arc_direction": "forward",
		"weapon_type": "PLASMA_CANNON",
		"levels": [
			{"level": 1, "size": Vector2i(1, 2), "power_consumed": 2, "damage": 25, "fire_rate": 0.6, "range": 300, "projectile_speed": 280, "weight": 9.0, "cost": {0: 18, 10: 10}},
			{"level": 2, "size": Vector2i(2, 2), "power_consumed": 3, "damage": 36, "fire_rate": 0.65, "range": 320, "projectile_speed": 295, "weight": 12.0, "cost": {10: 25, 20: 15}},
			{"level": 3, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 50, "fire_rate": 0.7, "range": 340, "projectile_speed": 310, "weight": 15.0, "cost": {20: 35, 30: 22}},
			{"level": 4, "size": Vector2i(2, 3), "power_consumed": 5, "damage": 70, "fire_rate": 0.75, "range": 360, "projectile_speed": 325, "weight": 20.0, "cost": {30: 48, 40: 32}},
			{"level": 5, "size": Vector2i(2, 3), "power_consumed": 7, "damage": 97, "fire_rate": 0.8, "range": 380, "projectile_speed": 340, "weight": 26.0, "cost": {40: 66, 50: 44}},
			{"level": 6, "size": Vector2i(3, 2), "power_consumed": 9, "damage": 135, "fire_rate": 0.85, "range": 400, "projectile_speed": 355, "weight": 33.0, "cost": {50: 90, 60: 60}},
			{"level": 7, "size": Vector2i(3, 3), "power_consumed": 12, "damage": 187, "fire_rate": 0.9, "range": 420, "projectile_speed": 370, "weight": 43.0, "cost": {60: 122, 70: 82}},
			{"level": 8, "size": Vector2i(3, 3), "power_consumed": 16, "damage": 260, "fire_rate": 0.95, "range": 440, "projectile_speed": 385, "weight": 55.0, "cost": {70: 165, 80: 110}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 21, "damage": 360, "fire_rate": 1.0, "range": 460, "projectile_speed": 400, "weight": 71.0, "cost": {80: 222, 90: 150}}
		]
	},
	"particle_beam": {
		"name": "Particle Beam",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Sustained purple energy beam",
		"firing_arc": 60,
		"arc_direction": "forward",
		"weapon_type": "PARTICLE_BEAM",
		"is_beam": true,
		"levels": [
			{"level": 1, "size": Vector2i(1, 2), "power_consumed": 4, "damage": 8, "fire_rate": 4.0, "range": 350, "beam_width": 3, "weight": 10.0, "cost": {0: 22, 10: 14}},
			{"level": 2, "size": Vector2i(2, 2), "power_consumed": 5, "damage": 11, "fire_rate": 4.2, "range": 370, "beam_width": 3, "weight": 13.0, "cost": {10: 30, 20: 20}},
			{"level": 3, "size": Vector2i(2, 2), "power_consumed": 7, "damage": 15, "fire_rate": 4.4, "range": 390, "beam_width": 4, "weight": 17.0, "cost": {20: 42, 30: 28}},
			{"level": 4, "size": Vector2i(2, 3), "power_consumed": 9, "damage": 21, "fire_rate": 4.6, "range": 410, "beam_width": 4, "weight": 22.0, "cost": {30: 58, 40: 38}},
			{"level": 5, "size": Vector2i(2, 3), "power_consumed": 12, "damage": 29, "fire_rate": 4.8, "range": 430, "beam_width": 5, "weight": 28.0, "cost": {40: 78, 50: 52}},
			{"level": 6, "size": Vector2i(3, 2), "power_consumed": 16, "damage": 40, "fire_rate": 5.0, "range": 450, "beam_width": 5, "weight": 36.0, "cost": {50: 105, 60: 70}},
			{"level": 7, "size": Vector2i(3, 3), "power_consumed": 21, "damage": 55, "fire_rate": 5.2, "range": 470, "beam_width": 6, "weight": 46.0, "cost": {60: 142, 70: 95}},
			{"level": 8, "size": Vector2i(3, 3), "power_consumed": 28, "damage": 76, "fire_rate": 5.4, "range": 490, "beam_width": 6, "weight": 59.0, "cost": {70: 190, 80: 128}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 37, "damage": 105, "fire_rate": 5.6, "range": 520, "beam_width": 7, "weight": 76.0, "cost": {80: 255, 90: 172}}
		]
	},
	"tesla_coil": {
		"name": "Tesla Coil",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Lightning beam that chains between nearby enemies",
		"firing_arc": 360,
		"arc_direction": "all",
		"weapon_type": "TESLA_COIL",
		"is_beam": true,
		"beam_width": 6.0,
		"special_effect": 5,
		"chain_count": 3,
		"chain_range": 100,
		"chain_damage_falloff": 0.7,
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 3, "damage": 15, "fire_rate": 1.2, "range": 250, "beam_width": 5, "weight": 7.0, "cost": {0: 20, 10: 12}},
			{"level": 2, "size": Vector2i(2, 1), "power_consumed": 4, "damage": 21, "fire_rate": 1.3, "range": 265, "beam_width": 5, "weight": 9.0, "cost": {10: 28, 20: 18}},
			{"level": 3, "size": Vector2i(2, 2), "power_consumed": 5, "damage": 29, "fire_rate": 1.4, "range": 280, "beam_width": 6, "weight": 12.0, "cost": {20: 38, 30: 25}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 7, "damage": 40, "fire_rate": 1.5, "range": 295, "beam_width": 6, "weight": 16.0, "cost": {30: 52, 40: 35}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 9, "damage": 55, "fire_rate": 1.6, "range": 310, "beam_width": 7, "weight": 20.0, "cost": {40: 72, 50: 48}},
			{"level": 6, "size": Vector2i(2, 3), "power_consumed": 12, "damage": 76, "fire_rate": 1.7, "range": 325, "beam_width": 7, "weight": 26.0, "cost": {50: 98, 60: 65}},
			{"level": 7, "size": Vector2i(3, 2), "power_consumed": 16, "damage": 105, "fire_rate": 1.8, "range": 340, "beam_width": 8, "weight": 33.0, "cost": {60: 132, 70: 88}},
			{"level": 8, "size": Vector2i(3, 3), "power_consumed": 21, "damage": 145, "fire_rate": 1.9, "range": 355, "beam_width": 8, "weight": 43.0, "cost": {70: 178, 80: 120}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 28, "damage": 200, "fire_rate": 2.0, "range": 370, "beam_width": 9, "weight": 55.0, "cost": {80: 240, 90: 160}}
		]
	},
	"disruptor": {
		"name": "Disruptor",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Pink energy projectile that bypasses shields",
		"firing_arc": 120,
		"arc_direction": "forward",
		"weapon_type": "DISRUPTOR",
		"special_effect": 4,
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 2, "damage": 10, "fire_rate": 1.8, "range": 280, "projectile_speed": 480, "weight": 5.0, "cost": {0: 15, 10: 10}},
			{"level": 2, "size": Vector2i(1, 2), "power_consumed": 3, "damage": 14, "fire_rate": 1.9, "range": 295, "projectile_speed": 500, "weight": 7.0, "cost": {10: 22, 20: 14}},
			{"level": 3, "size": Vector2i(2, 1), "power_consumed": 3, "damage": 19, "fire_rate": 2.0, "range": 310, "projectile_speed": 520, "weight": 9.0, "cost": {20: 30, 30: 20}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 26, "fire_rate": 2.1, "range": 325, "projectile_speed": 540, "weight": 12.0, "cost": {30: 42, 40: 28}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 6, "damage": 36, "fire_rate": 2.2, "range": 340, "projectile_speed": 560, "weight": 15.0, "cost": {40: 58, 50: 38}},
			{"level": 6, "size": Vector2i(2, 2), "power_consumed": 8, "damage": 50, "fire_rate": 2.3, "range": 355, "projectile_speed": 580, "weight": 19.0, "cost": {50: 78, 60: 52}},
			{"level": 7, "size": Vector2i(2, 3), "power_consumed": 10, "damage": 69, "fire_rate": 2.4, "range": 370, "projectile_speed": 600, "weight": 25.0, "cost": {60: 105, 70: 70}},
			{"level": 8, "size": Vector2i(3, 2), "power_consumed": 14, "damage": 95, "fire_rate": 2.5, "range": 385, "projectile_speed": 620, "weight": 32.0, "cost": {70: 142, 80: 95}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 18, "damage": 131, "fire_rate": 2.6, "range": 400, "projectile_speed": 640, "weight": 41.0, "cost": {80: 190, 90: 128}}
		]
	},
	# === EXPLOSIVE WEAPONS ===
	"flak_cannon": {
		"name": "Flak Cannon",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Fires a burst of explosive rounds that blanket an area. Use +/- to adjust AOE size.",
		"firing_arc": 180,
		"arc_direction": "forward",
		"weapon_type": "FLAK_CANNON",
		"aoe_type": 1,
		"levels": [
			{"level": 1, "size": Vector2i(1, 2), "power_consumed": 2, "damage": 25, "fire_rate": 0.8, "range": 300, "aoe_radius": 50, "projectile_speed": 450, "flak_bullet_count": 18, "flak_mini_aoe": 18, "weight": 8.0, "cost": {0: 18, 4: 10}},
			{"level": 2, "size": Vector2i(2, 2), "power_consumed": 3, "damage": 35, "fire_rate": 0.85, "range": 320, "aoe_radius": 55, "projectile_speed": 470, "flak_bullet_count": 20, "flak_mini_aoe": 19, "weight": 11.0, "cost": {10: 25, 20: 15}},
			{"level": 3, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 48, "fire_rate": 0.9, "range": 340, "aoe_radius": 60, "projectile_speed": 490, "flak_bullet_count": 22, "flak_mini_aoe": 20, "weight": 14.0, "cost": {20: 35, 30: 22}},
			{"level": 4, "size": Vector2i(2, 3), "power_consumed": 5, "damage": 65, "fire_rate": 0.95, "range": 360, "aoe_radius": 65, "projectile_speed": 510, "flak_bullet_count": 24, "flak_mini_aoe": 21, "weight": 18.0, "cost": {30: 48, 40: 32}},
			{"level": 5, "size": Vector2i(2, 3), "power_consumed": 7, "damage": 88, "fire_rate": 1.0, "range": 380, "aoe_radius": 70, "projectile_speed": 530, "flak_bullet_count": 26, "flak_mini_aoe": 22, "weight": 24.0, "cost": {40: 66, 50: 44}},
			{"level": 6, "size": Vector2i(3, 2), "power_consumed": 9, "damage": 120, "fire_rate": 1.05, "range": 400, "aoe_radius": 75, "projectile_speed": 550, "flak_bullet_count": 28, "flak_mini_aoe": 23, "weight": 31.0, "cost": {50: 90, 60: 60}},
			{"level": 7, "size": Vector2i(3, 3), "power_consumed": 12, "damage": 165, "fire_rate": 1.1, "range": 420, "aoe_radius": 80, "projectile_speed": 570, "flak_bullet_count": 30, "flak_mini_aoe": 24, "weight": 40.0, "cost": {60: 122, 70: 82}},
			{"level": 8, "size": Vector2i(3, 3), "power_consumed": 16, "damage": 225, "fire_rate": 1.15, "range": 440, "aoe_radius": 85, "projectile_speed": 590, "flak_bullet_count": 32, "flak_mini_aoe": 25, "weight": 52.0, "cost": {70: 165, 80: 110}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 21, "damage": 310, "fire_rate": 1.2, "range": 460, "aoe_radius": 90, "projectile_speed": 610, "flak_bullet_count": 35, "flak_mini_aoe": 26, "weight": 67.0, "cost": {80: 222, 90: 150}}
		]
	},
	"torpedo": {
		"name": "Torpedo",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Heavy explosive torpedo. Fires to target area center with adjustable AOE explosion. Use +/- to adjust blast radius.",
		"firing_arc": 60,
		"arc_direction": "forward",
		"weapon_type": "TORPEDO",
		"homing": false,
		"aoe_type": 1,
		"levels": [
			{"level": 1, "size": Vector2i(1, 2), "power_consumed": 3, "damage": 60, "fire_rate": 0.2, "range": 500, "aoe_radius": 40, "projectile_speed": 180, "weight": 12.0, "cost": {0: 25, 10: 15}},
			{"level": 2, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 85, "fire_rate": 0.22, "range": 530, "aoe_radius": 45, "projectile_speed": 190, "weight": 16.0, "cost": {10: 35, 20: 22}},
			{"level": 3, "size": Vector2i(2, 2), "power_consumed": 5, "damage": 120, "fire_rate": 0.24, "range": 560, "aoe_radius": 50, "projectile_speed": 200, "weight": 21.0, "cost": {20: 48, 30: 32}},
			{"level": 4, "size": Vector2i(2, 3), "power_consumed": 7, "damage": 168, "fire_rate": 0.26, "range": 590, "aoe_radius": 55, "projectile_speed": 210, "weight": 27.0, "cost": {30: 68, 40: 45}},
			{"level": 5, "size": Vector2i(2, 3), "power_consumed": 9, "damage": 235, "fire_rate": 0.28, "range": 620, "aoe_radius": 60, "projectile_speed": 220, "weight": 35.0, "cost": {40: 95, 50: 62}},
			{"level": 6, "size": Vector2i(3, 2), "power_consumed": 12, "damage": 330, "fire_rate": 0.30, "range": 650, "aoe_radius": 65, "projectile_speed": 230, "weight": 46.0, "cost": {50: 132, 60: 88}},
			{"level": 7, "size": Vector2i(3, 3), "power_consumed": 16, "damage": 462, "fire_rate": 0.32, "range": 680, "aoe_radius": 70, "projectile_speed": 240, "weight": 59.0, "cost": {60: 182, 70: 122}},
			{"level": 8, "size": Vector2i(3, 3), "power_consumed": 21, "damage": 647, "fire_rate": 0.34, "range": 710, "aoe_radius": 75, "projectile_speed": 250, "weight": 76.0, "cost": {70: 252, 80: 168}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 28, "damage": 905, "fire_rate": 0.36, "range": 750, "aoe_radius": 80, "projectile_speed": 260, "weight": 98.0, "cost": {80: 350, 90: 235}}
		]
	},
	"rocket_pod": {
		"name": "Rocket Pod",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Launches multiple small rockets in a volley",
		"firing_arc": 90,
		"arc_direction": "forward",
		"weapon_type": "ROCKET_POD",
		"projectile_count": 4,
		"spread_angle": 15.0,
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 2, "damage": 32, "fire_rate": 0.6, "range": 350, "projectile_speed": 380, "weight": 6.0, "cost": {0: 15, 4: 8}},
			{"level": 2, "size": Vector2i(1, 2), "power_consumed": 3, "damage": 45, "fire_rate": 0.65, "range": 365, "projectile_speed": 395, "weight": 8.0, "cost": {10: 22, 20: 12}},
			{"level": 3, "size": Vector2i(2, 1), "power_consumed": 3, "damage": 63, "fire_rate": 0.7, "range": 380, "projectile_speed": 410, "weight": 10.0, "cost": {20: 30, 30: 18}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 88, "fire_rate": 0.75, "range": 395, "projectile_speed": 425, "weight": 14.0, "cost": {30: 42, 40: 25}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 6, "damage": 123, "fire_rate": 0.8, "range": 410, "projectile_speed": 440, "weight": 18.0, "cost": {40: 58, 50: 35}},
			{"level": 6, "size": Vector2i(2, 2), "power_consumed": 8, "damage": 172, "fire_rate": 0.85, "range": 425, "projectile_speed": 455, "weight": 23.0, "cost": {50: 80, 60: 48}},
			{"level": 7, "size": Vector2i(2, 3), "power_consumed": 10, "damage": 241, "fire_rate": 0.9, "range": 440, "projectile_speed": 470, "weight": 30.0, "cost": {60: 110, 70: 66}},
			{"level": 8, "size": Vector2i(3, 2), "power_consumed": 14, "damage": 337, "fire_rate": 0.95, "range": 455, "projectile_speed": 485, "weight": 39.0, "cost": {70: 150, 80: 90}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 18, "damage": 472, "fire_rate": 1.0, "range": 470, "projectile_speed": 500, "weight": 50.0, "cost": {80: 205, 90: 125}}
		]
	},
	"mortar": {
		"name": "Mortar",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Fires heavy shells that blanket a large area. Fewer but bigger explosions than flak. Use +/- to adjust AOE size.",
		"firing_arc": 360,
		"arc_direction": "all",
		"weapon_type": "MORTAR",
		"aoe_type": 1,
		"levels": [
			{"level": 1, "size": Vector2i(1, 2), "power_consumed": 2, "damage": 28, "fire_rate": 0.5, "range": 400, "aoe_radius": 80, "projectile_speed": 200, "mortar_bullet_count": 6, "mortar_mini_aoe": 35, "weight": 9.0, "cost": {0: 18, 10: 10}},
			{"level": 2, "size": Vector2i(2, 2), "power_consumed": 3, "damage": 40, "fire_rate": 0.52, "range": 420, "aoe_radius": 85, "projectile_speed": 210, "mortar_bullet_count": 7, "mortar_mini_aoe": 37, "weight": 12.0, "cost": {10: 25, 20: 15}},
			{"level": 3, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 56, "fire_rate": 0.54, "range": 440, "aoe_radius": 90, "projectile_speed": 220, "mortar_bullet_count": 7, "mortar_mini_aoe": 39, "weight": 15.0, "cost": {20: 35, 30: 22}},
			{"level": 4, "size": Vector2i(2, 3), "power_consumed": 5, "damage": 78, "fire_rate": 0.56, "range": 460, "aoe_radius": 95, "projectile_speed": 230, "mortar_bullet_count": 8, "mortar_mini_aoe": 41, "weight": 20.0, "cost": {30: 48, 40: 30}},
			{"level": 5, "size": Vector2i(2, 3), "power_consumed": 7, "damage": 109, "fire_rate": 0.58, "range": 480, "aoe_radius": 100, "projectile_speed": 240, "mortar_bullet_count": 9, "mortar_mini_aoe": 43, "weight": 26.0, "cost": {40: 66, 50: 42}},
			{"level": 6, "size": Vector2i(3, 2), "power_consumed": 9, "damage": 153, "fire_rate": 0.60, "range": 500, "aoe_radius": 105, "projectile_speed": 250, "mortar_bullet_count": 10, "mortar_mini_aoe": 45, "weight": 34.0, "cost": {50: 92, 60: 58}},
			{"level": 7, "size": Vector2i(3, 3), "power_consumed": 12, "damage": 214, "fire_rate": 0.62, "range": 520, "aoe_radius": 110, "projectile_speed": 260, "mortar_bullet_count": 10, "mortar_mini_aoe": 47, "weight": 44.0, "cost": {60: 128, 70: 80}},
			{"level": 8, "size": Vector2i(3, 3), "power_consumed": 16, "damage": 300, "fire_rate": 0.64, "range": 540, "aoe_radius": 115, "projectile_speed": 270, "mortar_bullet_count": 11, "mortar_mini_aoe": 49, "weight": 57.0, "cost": {70: 175, 80: 110}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 21, "damage": 420, "fire_rate": 0.66, "range": 560, "aoe_radius": 120, "projectile_speed": 280, "mortar_bullet_count": 12, "mortar_mini_aoe": 50, "weight": 73.0, "cost": {80: 240, 90: 150}}
		]
	},
	"mine_layer": {
		"name": "Mine Layer",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Deploys proximity mines to target area. Mines arm on arrival, detect enemies, and explode. Timer shows countdown.",
		"firing_arc": 360,
		"arc_direction": "all",
		"weapon_type": "MINE_LAYER",
		"aoe_type": 1,
		"mine_timer": 30.0,
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 1, "damage": 45, "fire_rate": 0.3, "range": 200, "aoe_radius": 45, "projectile_speed": 150, "mine_timer": 30.0, "weight": 5.0, "cost": {0: 12, 4: 8}},
			{"level": 2, "size": Vector2i(1, 2), "power_consumed": 2, "damage": 63, "fire_rate": 0.32, "range": 210, "aoe_radius": 50, "projectile_speed": 155, "mine_timer": 30.0, "weight": 7.0, "cost": {10: 18, 20: 12}},
			{"level": 3, "size": Vector2i(2, 1), "power_consumed": 2, "damage": 88, "fire_rate": 0.34, "range": 220, "aoe_radius": 55, "projectile_speed": 160, "mine_timer": 30.0, "weight": 9.0, "cost": {20: 25, 30: 16}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 3, "damage": 123, "fire_rate": 0.36, "range": 230, "aoe_radius": 60, "projectile_speed": 165, "mine_timer": 30.0, "weight": 12.0, "cost": {30: 35, 40: 22}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 172, "fire_rate": 0.38, "range": 240, "aoe_radius": 65, "projectile_speed": 170, "mine_timer": 30.0, "weight": 16.0, "cost": {40: 48, 50: 30}},
			{"level": 6, "size": Vector2i(2, 2), "power_consumed": 5, "damage": 241, "fire_rate": 0.40, "range": 250, "aoe_radius": 70, "projectile_speed": 175, "mine_timer": 30.0, "weight": 20.0, "cost": {50: 66, 60: 42}},
			{"level": 7, "size": Vector2i(2, 3), "power_consumed": 7, "damage": 337, "fire_rate": 0.42, "range": 260, "aoe_radius": 75, "projectile_speed": 180, "mine_timer": 30.0, "weight": 26.0, "cost": {60: 92, 70: 58}},
			{"level": 8, "size": Vector2i(3, 2), "power_consumed": 9, "damage": 472, "fire_rate": 0.44, "range": 270, "aoe_radius": 80, "projectile_speed": 185, "mine_timer": 30.0, "weight": 34.0, "cost": {70: 128, 80: 80}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 12, "damage": 661, "fire_rate": 0.46, "range": 280, "aoe_radius": 85, "projectile_speed": 190, "mine_timer": 30.0, "weight": 43.0, "cost": {80: 175, 90: 110}}
		]
	},
	# === SPECIAL WEAPONS ===
	"cryo_cannon": {
		"name": "Cryo Cannon",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Light blue projectile that slows enemies",
		"firing_arc": 120,
		"arc_direction": "forward",
		"weapon_type": "CRYO_CANNON",
		"special_effect": 2,
		"effect_duration": 3.0,
		"effect_strength": 0.5,
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 2, "damage": 8, "fire_rate": 1.5, "range": 280, "projectile_speed": 420, "weight": 5.0, "cost": {0: 15, 10: 10}},
			{"level": 2, "size": Vector2i(1, 2), "power_consumed": 3, "damage": 11, "fire_rate": 1.6, "range": 295, "projectile_speed": 440, "weight": 7.0, "cost": {10: 22, 20: 14}},
			{"level": 3, "size": Vector2i(2, 1), "power_consumed": 3, "damage": 15, "fire_rate": 1.7, "range": 310, "projectile_speed": 460, "weight": 9.0, "cost": {20: 30, 30: 20}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 21, "fire_rate": 1.8, "range": 325, "projectile_speed": 480, "weight": 12.0, "cost": {30: 42, 40: 28}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 6, "damage": 29, "fire_rate": 1.9, "range": 340, "projectile_speed": 500, "weight": 15.0, "cost": {40: 58, 50: 38}},
			{"level": 6, "size": Vector2i(2, 2), "power_consumed": 8, "damage": 40, "fire_rate": 2.0, "range": 355, "projectile_speed": 520, "weight": 19.0, "cost": {50: 80, 60: 52}},
			{"level": 7, "size": Vector2i(2, 3), "power_consumed": 10, "damage": 55, "fire_rate": 2.1, "range": 370, "projectile_speed": 540, "weight": 25.0, "cost": {60: 110, 70: 72}},
			{"level": 8, "size": Vector2i(3, 2), "power_consumed": 14, "damage": 76, "fire_rate": 2.2, "range": 385, "projectile_speed": 560, "weight": 32.0, "cost": {70: 150, 80: 98}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 18, "damage": 105, "fire_rate": 2.3, "range": 400, "projectile_speed": 580, "weight": 41.0, "cost": {80: 205, 90: 135}}
		]
	},
	"emp_burst": {
		"name": "EMP Burst",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Ring AOE that disables all enemies in area",
		"firing_arc": 360,
		"arc_direction": "all",
		"weapon_type": "EMP_BURST",
		"aoe_type": 4,
		"special_effect": 1,
		"effect_duration": 2.5,
		"levels": [
			{"level": 1, "size": Vector2i(1, 2), "power_consumed": 4, "damage": 5, "fire_rate": 0.2, "range": 300, "aoe_radius": 80, "weight": 10.0, "cost": {0: 25, 10: 15}},
			{"level": 2, "size": Vector2i(2, 2), "power_consumed": 5, "damage": 7, "fire_rate": 0.22, "range": 320, "aoe_radius": 90, "weight": 13.0, "cost": {10: 35, 20: 22}},
			{"level": 3, "size": Vector2i(2, 2), "power_consumed": 7, "damage": 10, "fire_rate": 0.24, "range": 340, "aoe_radius": 100, "weight": 17.0, "cost": {20: 48, 30: 30}},
			{"level": 4, "size": Vector2i(2, 3), "power_consumed": 9, "damage": 14, "fire_rate": 0.26, "range": 360, "aoe_radius": 110, "weight": 22.0, "cost": {30: 66, 40: 42}},
			{"level": 5, "size": Vector2i(2, 3), "power_consumed": 12, "damage": 19, "fire_rate": 0.28, "range": 380, "aoe_radius": 120, "weight": 28.0, "cost": {40: 90, 50: 58}},
			{"level": 6, "size": Vector2i(3, 2), "power_consumed": 16, "damage": 26, "fire_rate": 0.30, "range": 400, "aoe_radius": 130, "weight": 36.0, "cost": {50: 122, 60: 78}},
			{"level": 7, "size": Vector2i(3, 3), "power_consumed": 21, "damage": 36, "fire_rate": 0.32, "range": 420, "aoe_radius": 140, "weight": 46.0, "cost": {60: 165, 70: 105}},
			{"level": 8, "size": Vector2i(3, 3), "power_consumed": 28, "damage": 50, "fire_rate": 0.34, "range": 440, "aoe_radius": 150, "weight": 59.0, "cost": {70: 222, 80: 142}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 37, "damage": 69, "fire_rate": 0.36, "range": 460, "aoe_radius": 160, "weight": 76.0, "cost": {80: 300, 90: 192}}
		]
	},
	"gravity_well": {
		"name": "Gravity Well",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Creates a gravity field that pulls enemies toward center",
		"firing_arc": 360,
		"arc_direction": "all",
		"weapon_type": "GRAVITY_WELL",
		"aoe_type": 1,
		"special_effect": 7,
		"effect_duration": 4.0,
		"levels": [
			{"level": 1, "size": Vector2i(2, 2), "power_consumed": 5, "damage": 3, "fire_rate": 0.15, "range": 350, "aoe_radius": 100, "weight": 14.0, "cost": {0: 30, 10: 18}},
			{"level": 2, "size": Vector2i(2, 2), "power_consumed": 7, "damage": 4, "fire_rate": 0.16, "range": 370, "aoe_radius": 110, "weight": 18.0, "cost": {10: 42, 20: 26}},
			{"level": 3, "size": Vector2i(2, 3), "power_consumed": 9, "damage": 6, "fire_rate": 0.17, "range": 390, "aoe_radius": 120, "weight": 23.0, "cost": {20: 58, 30: 36}},
			{"level": 4, "size": Vector2i(2, 3), "power_consumed": 12, "damage": 8, "fire_rate": 0.18, "range": 410, "aoe_radius": 130, "weight": 30.0, "cost": {30: 80, 40: 50}},
			{"level": 5, "size": Vector2i(3, 2), "power_consumed": 16, "damage": 11, "fire_rate": 0.19, "range": 430, "aoe_radius": 140, "weight": 38.0, "cost": {40: 110, 50: 68}},
			{"level": 6, "size": Vector2i(3, 3), "power_consumed": 21, "damage": 15, "fire_rate": 0.20, "range": 450, "aoe_radius": 150, "weight": 49.0, "cost": {50: 150, 60: 92}},
			{"level": 7, "size": Vector2i(3, 3), "power_consumed": 28, "damage": 21, "fire_rate": 0.21, "range": 470, "aoe_radius": 160, "weight": 63.0, "cost": {60: 205, 70: 125}},
			{"level": 8, "size": Vector2i(3, 3), "power_consumed": 37, "damage": 29, "fire_rate": 0.22, "range": 490, "aoe_radius": 170, "weight": 81.0, "cost": {70: 280, 80: 170}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 48, "damage": 40, "fire_rate": 0.23, "range": 510, "aoe_radius": 180, "weight": 104.0, "cost": {80: 380, 90: 230}}
		]
	},
	"repair_beam": {
		"name": "Repair Beam",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Green healing beam - repairs friendly ships",
		"firing_arc": 360,
		"arc_direction": "all",
		"weapon_type": "REPAIR_BEAM",
		"is_beam": true,
		"is_support": true,
		"special_effect": 8,
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 2, "damage": 8, "fire_rate": 2.0, "range": 250, "beam_width": 4, "weight": 4.0, "cost": {0: 15, 1: 8}},
			{"level": 2, "size": Vector2i(1, 2), "power_consumed": 3, "damage": 11, "fire_rate": 2.1, "range": 265, "beam_width": 4, "weight": 5.0, "cost": {10: 22, 20: 12}},
			{"level": 3, "size": Vector2i(2, 1), "power_consumed": 3, "damage": 15, "fire_rate": 2.2, "range": 280, "beam_width": 5, "weight": 7.0, "cost": {20: 30, 30: 18}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 4, "damage": 21, "fire_rate": 2.3, "range": 295, "beam_width": 5, "weight": 9.0, "cost": {30: 42, 40: 25}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 6, "damage": 29, "fire_rate": 2.4, "range": 310, "beam_width": 6, "weight": 11.0, "cost": {40: 58, 50: 35}},
			{"level": 6, "size": Vector2i(2, 2), "power_consumed": 8, "damage": 40, "fire_rate": 2.5, "range": 325, "beam_width": 6, "weight": 14.0, "cost": {50: 80, 60: 48}},
			{"level": 7, "size": Vector2i(2, 3), "power_consumed": 10, "damage": 55, "fire_rate": 2.6, "range": 340, "beam_width": 7, "weight": 18.0, "cost": {60: 110, 70: 66}},
			{"level": 8, "size": Vector2i(3, 2), "power_consumed": 14, "damage": 76, "fire_rate": 2.7, "range": 355, "beam_width": 7, "weight": 23.0, "cost": {70: 150, 80: 90}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 18, "damage": 105, "fire_rate": 2.8, "range": 370, "beam_width": 8, "weight": 30.0, "cost": {80: 205, 90: 125}}
		]
	},
	"shield_generator": {
		"name": "Shield Generator",
		"base_sprite": "res://assets/sprites/UI/ShieldGen.png",
		"description": "Generates protective energy shield",
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 2, "shield_hp": 50, "weight": 6.0, "cost": {1: 20, 3: 5}},
			{"level": 2, "size": Vector2i(2, 1), "power_consumed": 3, "shield_hp": 75, "weight": 8.0, "cost": {1: 15, 10: 10}},
			{"level": 3, "size": Vector2i(2, 1), "power_consumed": 4, "shield_hp": 100, "weight": 10.0, "cost": {10: 25, 20: 15}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 6, "shield_hp": 150, "weight": 13.0, "cost": {20: 35, 30: 25}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 9, "shield_hp": 220, "weight": 17.0, "cost": {30: 50, 40: 40}},
			{"level": 6, "size": Vector2i(2, 2), "power_consumed": 13, "shield_hp": 320, "weight": 22.0, "cost": {40: 70, 50: 60}},
			{"level": 7, "size": Vector2i(2, 3), "power_consumed": 18, "shield_hp": 460, "weight": 29.0, "cost": {50: 100, 60: 85}},
			{"level": 8, "size": Vector2i(3, 2), "power_consumed": 26, "shield_hp": 660, "weight": 38.0, "cost": {60: 140, 70: 120}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 36, "shield_hp": 950, "weight": 49.0, "cost": {70: 200, 80: 170}}
		]
	},
	"repair_bot": {
		"name": "Repair Bot",
		"base_sprite": "res://assets/sprites/UI/RepairBot.png",
		"description": "Repairs hull damage over time",
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 1, "repair_rate": 2, "weight": 3.0, "cost": {0: 8, 1: 5}},
			{"level": 2, "size": Vector2i(1, 1), "power_consumed": 1, "repair_rate": 3, "weight": 4.0, "cost": {0: 6, 10: 7}},
			{"level": 3, "size": Vector2i(1, 1), "power_consumed": 2, "repair_rate": 5, "weight": 5.0, "cost": {10: 10, 20: 10}},
			{"level": 4, "size": Vector2i(1, 2), "power_consumed": 3, "repair_rate": 8, "weight": 7.0, "cost": {20: 15, 30: 12}},
			{"level": 5, "size": Vector2i(2, 1), "power_consumed": 4, "repair_rate": 12, "weight": 9.0, "cost": {30: 20, 40: 18}},
			{"level": 6, "size": Vector2i(2, 2), "power_consumed": 6, "repair_rate": 18, "weight": 12.0, "cost": {40: 28, 50: 25}},
			{"level": 7, "size": Vector2i(2, 2), "power_consumed": 8, "repair_rate": 26, "weight": 16.0, "cost": {50: 40, 60: 35}},
			{"level": 8, "size": Vector2i(2, 3), "power_consumed": 12, "repair_rate": 38, "weight": 21.0, "cost": {60: 55, 70: 50}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 16, "repair_rate": 55, "weight": 27.0, "cost": {70: 80, 80: 70}}
		]
	},
	"scanner": {
		"name": "Scanner Laser",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Scans asteroids much faster than scout drones",
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 1, "scan_multiplier": 5.0, "range_px": 350, "weight": 3.0, "cost": {0: 12, 1: 6}},
			{"level": 2, "size": Vector2i(1, 1), "power_consumed": 1, "scan_multiplier": 6.0, "range_px": 360, "weight": 3.5, "cost": {0: 10, 10: 8}},
			{"level": 3, "size": Vector2i(1, 2), "power_consumed": 2, "scan_multiplier": 7.0, "range_px": 370, "weight": 4.0, "cost": {10: 12, 20: 10}},
			{"level": 4, "size": Vector2i(1, 2), "power_consumed": 2, "scan_multiplier": 8.0, "range_px": 380, "weight": 4.5, "cost": {20: 16, 30: 12}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 3, "scan_multiplier": 9.0, "range_px": 400, "weight": 5.0, "cost": {30: 20, 40: 14}},
			{"level": 6, "size": Vector2i(2, 2), "power_consumed": 3, "scan_multiplier": 10.0, "range_px": 420, "weight": 5.5, "cost": {40: 26, 50: 16}},
			{"level": 7, "size": Vector2i(2, 2), "power_consumed": 4, "scan_multiplier": 11.0, "range_px": 440, "weight": 6.0, "cost": {50: 32, 60: 18}},
			{"level": 8, "size": Vector2i(2, 3), "power_consumed": 4, "scan_multiplier": 12.0, "range_px": 460, "weight": 6.5, "cost": {60: 40, 70: 20}},
			{"level": 9, "size": Vector2i(3, 2), "power_consumed": 5, "scan_multiplier": 13.0, "range_px": 480, "weight": 7.0, "cost": {70: 50, 80: 25}}
		]
	},
	"miner": {
		"name": "Mining Laser",
		"base_sprite": "res://assets/sprites/UI/WeaponTexture.png",
		"description": "Mines asteroid resources with built-in cargo capacity",
		"levels": [
			{"level": 1, "size": Vector2i(1, 1), "power_consumed": 1, "mining_rate": 1.0, "cargo_bonus": 100, "range_px": 300, "weight": 4.0, "cost": {0: 12, 2: 6}},
			{"level": 2, "size": Vector2i(1, 2), "power_consumed": 2, "mining_rate": 1.1, "cargo_bonus": 150, "range_px": 310, "weight": 5.0, "cost": {0: 10, 10: 8}},
			{"level": 3, "size": Vector2i(2, 1), "power_consumed": 2, "mining_rate": 1.2, "cargo_bonus": 200, "range_px": 320, "weight": 6.0, "cost": {10: 12, 20: 10}},
			{"level": 4, "size": Vector2i(2, 2), "power_consumed": 3, "mining_rate": 1.3, "cargo_bonus": 250, "range_px": 330, "weight": 7.0, "cost": {20: 16, 30: 12}},
			{"level": 5, "size": Vector2i(2, 2), "power_consumed": 3, "mining_rate": 1.4, "cargo_bonus": 300, "range_px": 340, "weight": 8.0, "cost": {30: 20, 40: 14}},
			{"level": 6, "size": Vector2i(2, 3), "power_consumed": 4, "mining_rate": 1.5, "cargo_bonus": 350, "range_px": 350, "weight": 9.0, "cost": {40: 26, 50: 16}},
			{"level": 7, "size": Vector2i(3, 2), "power_consumed": 4, "mining_rate": 1.6, "cargo_bonus": 400, "range_px": 360, "weight": 10.0, "cost": {50: 32, 60: 18}},
			{"level": 8, "size": Vector2i(3, 2), "power_consumed": 5, "mining_rate": 1.7, "cargo_bonus": 450, "range_px": 370, "weight": 11.0, "cost": {60: 40, 70: 20}},
			{"level": 9, "size": Vector2i(3, 3), "power_consumed": 6, "mining_rate": 1.8, "cargo_bonus": 500, "range_px": 380, "weight": 12.0, "cost": {70: 50, 80: 25}}
		]
	}
}

# Legacy COMPONENTS dict for backward compatibility - maps to level 3 (current default)
# This is populated at runtime via _init_legacy_components()
var COMPONENTS = {}

const HULL_COSTS = {
	CosmoteerShipBlueprint.HullType.LIGHT: {0: 5},  # metal: 5
	CosmoteerShipBlueprint.HullType.MEDIUM: {0: 10, 5: 2},  # metal: 10, alloy (placeholder): 2
	CosmoteerShipBlueprint.HullType.HEAVY: {0: 15, 5: 5}  # metal: 15, alloy: 5
}

const HULL_WEIGHTS = {
	CosmoteerShipBlueprint.HullType.LIGHT: 2.0,
	CosmoteerShipBlueprint.HullType.MEDIUM: 5.0,
	CosmoteerShipBlueprint.HullType.HEAVY: 10.0
}

const HULL_COLORS = {
	CosmoteerShipBlueprint.HullType.LIGHT: Color(0.4, 0.6, 1.0, 0.6),  # Light blue
	CosmoteerShipBlueprint.HullType.MEDIUM: Color(0.4, 1.0, 0.4, 0.6),  # Green
	CosmoteerShipBlueprint.HullType.HEAVY: Color(1.0, 0.4, 0.4, 0.6)   # Red
}

const HULL_NAMES = {
	CosmoteerShipBlueprint.HullType.LIGHT: "Light Armor",
	CosmoteerShipBlueprint.HullType.MEDIUM: "Medium Armor",
	CosmoteerShipBlueprint.HullType.HEAVY: "Heavy Armor"
}

const HULL_TEXTURES = {
	CosmoteerShipBlueprint.HullType.LIGHT: "res://assets/sprites/UI/Hull1.png",
	CosmoteerShipBlueprint.HullType.MEDIUM: "res://assets/sprites/UI/Hull2.png",
	CosmoteerShipBlueprint.HullType.HEAVY: "res://assets/sprites/UI/Hull3.png"
}

static func parse_component_id(comp_id: String) -> Dictionary:
	"""Parse component ID into type and level
	Returns: {type: String, level: int}
	Examples: 'power_core_l5' -> {type: 'power_core', level: 5}
	          'power_core' -> {type: 'power_core', level: 3} (backward compat)
	"""
	if "_l" in comp_id:
		var parts = comp_id.rsplit("_l", true, 1)
		var comp_type = parts[0]
		var level = int(parts[1]) if parts.size() > 1 else 1
		return {"type": comp_type, "level": level}
	else:
		# Backward compatibility - old IDs default to level 3
		return {"type": comp_id, "level": 3}

static func build_component_id(comp_type: String, level: int) -> String:
	"""Build component ID from type and level
	Example: ('power_core', 5) -> 'power_core_l5'
	"""
	return "%s_l%d" % [comp_type, level]

static func get_component_data_by_level(comp_type: String, level: int) -> Dictionary:
	"""Get component data for a specific type and level"""
	var type_data = COMPONENT_TYPES.get(comp_type, {})
	if type_data.is_empty():
		return {}
	
	var levels = type_data.get("levels", [])
	if level < 1 or level > levels.size():
		return {}
	
	# Get level data and add common properties
	var level_data = levels[level - 1].duplicate()
	level_data["name"] = type_data.get("name", "Unknown")
	level_data["sprite"] = type_data.get("base_sprite", "")
	level_data["description"] = type_data.get("description", "")
	
	# Add weapon-specific properties if present
	if type_data.has("firing_arc"):
		level_data["firing_arc"] = type_data.get("firing_arc")
	if type_data.has("arc_direction"):
		level_data["arc_direction"] = type_data.get("arc_direction")
	
	return level_data

static func get_component_data(component_id: String) -> Dictionary:
	"""Get component data from full ID (e.g., 'power_core_l5' or 'power_core')"""
	var parsed = parse_component_id(component_id)
	return get_component_data_by_level(parsed["type"], parsed["level"])

static func get_all_component_types() -> Array:
	"""Get array of all component type names (without levels)"""
	return COMPONENT_TYPES.keys()

static func get_max_level(comp_type: String) -> int:
	"""Get maximum level for a component type"""
	var type_data = COMPONENT_TYPES.get(comp_type, {})
	var levels = type_data.get("levels", [])
	return levels.size()

static func get_component_type_info(comp_type: String) -> Dictionary:
	"""Get component type metadata (name, sprite, description)"""
	return COMPONENT_TYPES.get(comp_type, {})

static func is_valid_component_type(component_type: String) -> bool:
	"""Check if component type exists"""
	# Handle both old format and new format
	var parsed = parse_component_id(component_type)
	return COMPONENT_TYPES.has(parsed["type"])

static func get_component_base_sprite(comp_type: String) -> String:
	"""Get base sprite path for a component type"""
	var type_data = COMPONENT_TYPES.get(comp_type, {})
	return type_data.get("base_sprite", "")

static func get_hull_cost(hull_type: CosmoteerShipBlueprint.HullType) -> Dictionary:
	return HULL_COSTS.get(hull_type, {})

static func get_hull_weight(hull_type: CosmoteerShipBlueprint.HullType) -> float:
	return HULL_WEIGHTS.get(hull_type, 0.0)

static func get_hull_color(hull_type: CosmoteerShipBlueprint.HullType) -> Color:
	return HULL_COLORS.get(hull_type, Color.WHITE)

static func get_hull_name(hull_type: CosmoteerShipBlueprint.HullType) -> String:
	return HULL_NAMES.get(hull_type, "Unknown")

static func get_hull_texture(hull_type: CosmoteerShipBlueprint.HullType) -> String:
	return HULL_TEXTURES.get(hull_type, "")

# Weapon categories for UI organization
const WEAPON_CATEGORIES = {
	"kinetic": ["laser_weapon", "autocannon", "railgun", "gatling", "sniper_cannon", "shotgun"],
	"energy": ["ion_cannon", "plasma_cannon", "particle_beam", "tesla_coil", "disruptor"],
	"explosive": ["missile_launcher", "flak_cannon", "torpedo", "rocket_pod", "mortar", "mine_layer"],
	"special": ["cryo_cannon", "emp_burst", "gravity_well", "repair_beam"]
}

const WEAPON_CATEGORY_NAMES = {
	"kinetic": "Kinetic",
	"energy": "Energy",
	"explosive": "Explosive",
	"special": "Special"
}

# UI Category colors for component buttons
const CATEGORY_COLORS = {
	"Energy": Color(1.0, 0.85, 0.2, 1.0),        # Yellow/gold for power cores
	"Propulsion": Color(0.2, 0.9, 0.95, 1.0),    # Cyan for engines
	"Kinetic Weapons": Color(0.9, 0.75, 0.35, 1.0),  # Brass/amber
	"Energy Weapons": Color(0.4, 0.7, 1.0, 1.0),  # Blue
	"Explosive Weapons": Color(1.0, 0.5, 0.25, 1.0),  # Orange/red
	"Special Weapons": Color(0.75, 0.45, 1.0, 1.0),  # Purple
	"Defense": Color(0.35, 0.9, 0.45, 1.0),       # Green
	"Operations": Color(0.3, 0.8, 0.75, 1.0)     # Teal
}

# Map component types to their UI categories
const COMPONENT_CATEGORY_MAP = {
	"power_core": "Energy",
	"engine": "Propulsion",
	"laser_weapon": "Kinetic Weapons",
	"autocannon": "Kinetic Weapons",
	"railgun": "Kinetic Weapons",
	"gatling": "Kinetic Weapons",
	"sniper_cannon": "Kinetic Weapons",
	"shotgun": "Kinetic Weapons",
	"ion_cannon": "Energy Weapons",
	"plasma_cannon": "Energy Weapons",
	"particle_beam": "Energy Weapons",
	"tesla_coil": "Energy Weapons",
	"disruptor": "Energy Weapons",
	"missile_launcher": "Explosive Weapons",
	"flak_cannon": "Explosive Weapons",
	"torpedo": "Explosive Weapons",
	"rocket_pod": "Explosive Weapons",
	"mortar": "Explosive Weapons",
	"mine_layer": "Explosive Weapons",
	"cryo_cannon": "Special Weapons",
	"emp_burst": "Special Weapons",
	"gravity_well": "Special Weapons",
	"repair_beam": "Special Weapons",
	"shield_generator": "Defense",
	"repair_bot": "Defense",
	"scanner": "Operations",
	"miner": "Operations"
}

static func get_component_category(comp_type: String) -> String:
	"""Get the UI category for a component type"""
	return COMPONENT_CATEGORY_MAP.get(comp_type, "")

static func get_category_color(category: String) -> Color:
	"""Get the color for a UI category"""
	return CATEGORY_COLORS.get(category, Color.WHITE)

static func get_component_category_color(comp_type: String) -> Color:
	"""Get the category color for a component type"""
	var category = get_component_category(comp_type)
	return get_category_color(category)

# Map component type IDs to WeaponComponent.WeaponType enum values
const WEAPON_TYPE_MAP = {
	"laser_weapon": 0,      # LASER
	"missile_launcher": 1,  # MISSILE
	"autocannon": 2,        # AUTOCANNON
	"railgun": 3,           # RAILGUN
	"gatling": 4,           # GATLING
	"sniper_cannon": 5,     # SNIPER
	"shotgun": 6,           # SHOTGUN
	"ion_cannon": 7,        # ION_CANNON
	"plasma_cannon": 8,     # PLASMA_CANNON
	"particle_beam": 9,     # PARTICLE_BEAM
	"tesla_coil": 10,       # TESLA_COIL
	"disruptor": 11,        # DISRUPTOR
	"flak_cannon": 12,      # FLAK_CANNON
	"torpedo": 13,          # TORPEDO
	"rocket_pod": 14,       # ROCKET_POD
	"mortar": 15,           # MORTAR
	"mine_layer": 16,       # MINE_LAYER
	"cryo_cannon": 17,      # CRYO_CANNON
	"emp_burst": 18,        # EMP_BURST
	"gravity_well": 19,     # GRAVITY_WELL
	"repair_beam": 20       # REPAIR_BEAM
}

static func get_all_weapon_types() -> Array:
	"""Get all weapon component type IDs"""
	var weapons = []
	for category in WEAPON_CATEGORIES.values():
		weapons.append_array(category)
	return weapons

static func get_weapon_category(comp_type: String) -> String:
	"""Get category for a weapon component type"""
	for category in WEAPON_CATEGORIES:
		if comp_type in WEAPON_CATEGORIES[category]:
			return category
	return ""

static func get_weapons_in_category(category: String) -> Array:
	"""Get all weapon types in a category"""
	return WEAPON_CATEGORIES.get(category, [])

static func is_weapon_type(comp_type: String) -> bool:
	"""Check if component type is a weapon"""
	return comp_type in get_all_weapon_types()

static func get_weapon_enum_value(comp_type: String) -> int:
	"""Get the WeaponComponent.WeaponType enum value for a component type"""
	return WEAPON_TYPE_MAP.get(comp_type, 0)

static func is_aoe_weapon(comp_type: String) -> bool:
	"""Check if weapon has AOE damage"""
	var type_data = COMPONENT_TYPES.get(comp_type, {})
	return type_data.get("aoe_type", 0) != 0

static func is_beam_weapon(comp_type: String) -> bool:
	"""Check if weapon is a beam type"""
	var type_data = COMPONENT_TYPES.get(comp_type, {})
	return type_data.get("is_beam", false)

static func is_support_weapon(comp_type: String) -> bool:
	"""Check if weapon targets friendlies (repair beam)"""
	var type_data = COMPONENT_TYPES.get(comp_type, {})
	return type_data.get("is_support", false)

static func get_weapon_aoe_radius(comp_type: String, level: int) -> float:
	"""Get AOE radius for a weapon at specific level"""
	var level_data = get_component_data_by_level(comp_type, level)
	return level_data.get("aoe_radius", 0.0)

