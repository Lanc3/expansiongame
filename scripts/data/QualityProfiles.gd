extends Resource
class_name QualityProfiles

@export var profiles: Dictionary = {
	"low": {
		"max_gpu_particles": 40000,
		"max_heavy_emitters": 4,
		"max_dynamic_lights": 48,
		"trail_point_budget": 1500,
		"light_lifetime": 0.2
	},
	"medium": {
		"max_gpu_particles": 80000,
		"max_heavy_emitters": 8,
		"max_dynamic_lights": 96,
		"trail_point_budget": 3000,
		"light_lifetime": 0.25
	},
	"high": {
		"max_gpu_particles": 120000,
		"max_heavy_emitters": 12,
		"max_dynamic_lights": 150,
		"trail_point_budget": 5000,
		"light_lifetime": 0.3
	},
	"ultra": {
		"max_gpu_particles": 150000,
		"max_heavy_emitters": 16,
		"max_dynamic_lights": 200,
		"trail_point_budget": 6000,
		"light_lifetime": 0.35
	}
}

@export var default_profile: StringName = &"high"

func get_profile(name: StringName) -> Dictionary:
	if profiles.has(name):
		return profiles[name]
	return profiles.get(default_profile, profiles.values()[0])

func get_clamped_value(profile_name: StringName, key: StringName, fallback):
	var profile := get_profile(profile_name)
	return profile.get(key, fallback)

