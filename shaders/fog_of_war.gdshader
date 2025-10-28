shader_type canvas_item;

uniform sampler2D fog_texture : filter_linear, hint_default_black;
uniform vec2 camera_position;
uniform vec2 zone_offset;
uniform vec2 zone_size;
uniform float tile_size = 200.0;
uniform float camera_zoom = 1.0;
uniform vec2 viewport_size;

void fragment() {
	// Calculate world position from UV coordinates
	// For ColorRect, UV goes from 0.0 to 1.0 across the control
	// Convert UV to screen pixels (0.0-1.0 -> 0 to viewport_size)
	vec2 screen_pos = UV * viewport_size;
	
	// Convert screen position to viewport center offset
	vec2 screen_offset = screen_pos - (viewport_size * 0.5);
	
	// Apply camera zoom and add camera world position
	vec2 world_pos = camera_position + (screen_offset * camera_zoom);
	
	// Convert to zone-relative position
	vec2 relative_pos = world_pos - zone_offset;
	
	// Convert to tile coordinates (0-based indices)
	vec2 tile_coord = relative_pos / tile_size;
	
	// Get fog texture dimensions
	vec2 texture_dimensions = vec2(textureSize(fog_texture, 0));
	
	// Convert tile coordinates to UV (0.0 to 1.0)
	vec2 fog_uv = tile_coord / texture_dimensions;
	
	// Check if we're outside the fog texture bounds
	if (fog_uv.x < 0.0 || fog_uv.x > 1.0 || fog_uv.y < 0.0 || fog_uv.y > 1.0) {
		// Outside zone bounds - show as unexplored
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		// Sample fog texture (1.0 = explored/white, 0.0 = unexplored/black)
		float explored = texture(fog_texture, fog_uv).r;
		
		// SHADER-BASED SOFT EDGES: Multi-tap blur for smooth fog transitions
		// Sample at 2-pixel radius for more pronounced blur
		vec2 pixel_size = 1.0 / texture_dimensions;
		vec2 blur_radius = pixel_size * 2.0;
		
		// 9-tap box blur (center + 8 neighbors)
		float explored_smooth = explored * 0.25;  // Center pixel
		
		// Cardinal directions (4 samples)
		explored_smooth += texture(fog_texture, fog_uv + vec2(blur_radius.x, 0.0)).r * 0.125;
		explored_smooth += texture(fog_texture, fog_uv - vec2(blur_radius.x, 0.0)).r * 0.125;
		explored_smooth += texture(fog_texture, fog_uv + vec2(0.0, blur_radius.y)).r * 0.125;
		explored_smooth += texture(fog_texture, fog_uv - vec2(0.0, blur_radius.y)).r * 0.125;
		
		// Diagonal directions (4 samples)
		explored_smooth += texture(fog_texture, fog_uv + blur_radius).r * 0.0625;
		explored_smooth += texture(fog_texture, fog_uv - blur_radius).r * 0.0625;
		explored_smooth += texture(fog_texture, fog_uv + vec2(blur_radius.x, -blur_radius.y)).r * 0.0625;
		explored_smooth += texture(fog_texture, fog_uv + vec2(-blur_radius.x, blur_radius.y)).r * 0.0625;
		
		// Apply smoothstep for soft falloff at edges
		explored_smooth = smoothstep(0.2, 0.8, explored_smooth);
		
		// Output black for unexplored areas (alpha = 1 for black, 0 for explored)
		COLOR = vec4(0.0, 0.0, 0.0, 1.0 - explored_smooth);
	}
}

