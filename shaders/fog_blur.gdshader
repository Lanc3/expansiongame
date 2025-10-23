shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 3.0;
uniform float edge_threshold : hint_range(0.0, 1.0) = 0.3;

// Detect if this pixel is near a fog edge
bool is_near_edge(vec2 uv, float check_radius) {
	vec4 center = texture(SCREEN_TEXTURE, uv);
	float center_brightness = (center.r + center.g + center.b) / 3.0;
	
	// Check surrounding pixels for brightness difference
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			if (x == 0 && y == 0) continue;
			
			vec2 offset = vec2(float(x), float(y)) * check_radius * 0.001;
			vec4 sample_color = texture(SCREEN_TEXTURE, uv + offset);
			float sample_brightness = (sample_color.r + sample_color.g + sample_color.b) / 3.0;
			
			// If there's a significant brightness difference, we're near an edge
			if (abs(center_brightness - sample_brightness) > edge_threshold) {
				return true;
			}
		}
	}
	
	return false;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 original_color = texture(SCREEN_TEXTURE, uv);
	
	// Check if we're near a fog edge
	if (is_near_edge(uv, blur_amount)) {
		// Apply blur at fog edges
		vec4 blurred_color = vec4(0.0);
		float total_weight = 0.0;
		
		float blur_size = blur_amount * 0.001;
		int samples = 4;
		
		for (int x = -samples; x <= samples; x++) {
			for (int y = -samples; y <= samples; y++) {
				vec2 offset = vec2(float(x), float(y)) * blur_size;
				float distance_factor = length(offset) / (blur_size * float(samples));
				float weight = exp(-distance_factor * distance_factor * 3.0);
				
				vec4 sample_color = texture(SCREEN_TEXTURE, uv + offset);
				blurred_color += sample_color * weight;
				total_weight += weight;
			}
		}
		
		blurred_color /= total_weight;
		COLOR = blurred_color;
	} else {
		// No blur needed, use original color
		COLOR = original_color;
	}
}

