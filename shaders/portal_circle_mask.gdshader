shader_type canvas_item;

void fragment() {
	// Get the texture color
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Calculate distance from center (0.5, 0.5) in UV space
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	
	// Create circular mask - fade out edges
	float radius = 0.5;
	float edge_softness = 0.05;
	float circle_alpha = 1.0 - smoothstep(radius - edge_softness, radius, dist);
	
	// Apply circular mask AND modulate color (which includes alpha from sprite)
	COLOR = tex_color * COLOR;
	COLOR.a *= circle_alpha;
}

