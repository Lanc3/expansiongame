shader_type canvas_item;

// Shader to make white/light backgrounds transparent
uniform float threshold : hint_range(0.8, 1.0) = 0.95;
uniform float softness : hint_range(0.0, 0.2) = 0.05;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Calculate brightness
	float brightness = (tex_color.r + tex_color.g + tex_color.b) / 3.0;
	
	// Make white/light pixels transparent
	float alpha = 1.0;
	if (brightness > threshold - softness) {
		// Smooth transition to transparent
		alpha = 1.0 - smoothstep(threshold - softness, threshold, brightness);
	}
	
	// Preserve original alpha if it's already transparent
	alpha = min(alpha, tex_color.a);
	
	COLOR = vec4(tex_color.rgb, alpha * COLOR.a);
}


