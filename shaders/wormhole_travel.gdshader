shader_type canvas_item;

uniform float warp_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float swirl_amount : hint_range(0.0, 10.0) = 0.0;
uniform float chromatic_aberration : hint_range(0.0, 0.05) = 0.0;
uniform float speed_lines : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center = vec2(0.5, 0.5);
uniform float time_offset = 0.0;

// Rotate UV coordinates around a point
vec2 rotate_uv(vec2 uv, vec2 pivot, float angle) {
	vec2 dir = uv - pivot;
	float cos_angle = cos(angle);
	float sin_angle = sin(angle);
	vec2 rotated = vec2(
		dir.x * cos_angle - dir.y * sin_angle,
		dir.x * sin_angle + dir.y * cos_angle
	);
	return rotated + pivot;
}

void fragment() {
	vec2 uv = UV;
	vec2 centered_uv = uv - center;
	float dist_from_center = length(centered_uv);
	
	// === RADIAL WARP/SWIRL ===
	// Create vortex effect - stronger near center
	float warp_factor = warp_intensity * (1.0 - dist_from_center);
	float angle = swirl_amount * (1.0 - dist_from_center) * 3.14159;
	angle += time_offset * 2.0;  // Continuous rotation
	
	vec2 warped_uv = rotate_uv(uv, center, angle);
	
	// Radial displacement - pull toward/push from center
	vec2 radial_dir = normalize(centered_uv);
	warped_uv += radial_dir * warp_factor * 0.3;
	
	// === SPEED LINES (Radial Stretch) ===
	float stretch_factor = speed_lines * dist_from_center;
	warped_uv = center + (warped_uv - center) * (1.0 + stretch_factor * 2.0);
	
	// === CHROMATIC ABERRATION ===
	vec4 color;
	if (chromatic_aberration > 0.001) {
		// Sample RGB channels separately with radial offset
		float aberration_offset = chromatic_aberration * dist_from_center;
		vec2 offset_dir = normalize(centered_uv);
		
		float r = texture(SCREEN_TEXTURE, warped_uv + offset_dir * aberration_offset).r;
		float g = texture(SCREEN_TEXTURE, warped_uv).g;
		float b = texture(SCREEN_TEXTURE, warped_uv - offset_dir * aberration_offset).b;
		
		color = vec4(r, g, b, 1.0);
	} else {
		color = texture(SCREEN_TEXTURE, warped_uv);
	}
	
	// === VIGNETTE ===
	float vignette = 1.0 - (dist_from_center * dist_from_center * warp_intensity);
	vignette = clamp(vignette, 0.0, 1.0);
	
	// === COLOR TINTING (animated) ===
	vec3 tint_color = mix(
		vec3(0.6, 0.3, 1.0),  // Purple
		vec3(0.2, 0.6, 1.0),  // Cyan
		sin(time_offset) * 0.5 + 0.5
	);
	
	color.rgb = mix(color.rgb, tint_color, warp_intensity * 0.4);
	color.rgb *= vignette;
	
	COLOR = color;
}

