shader_type canvas_item;

uniform sampler2D fog_texture : hint_default_black;
uniform vec2 camera_position;
uniform vec2 zone_offset;
uniform vec2 zone_size;
uniform float tile_size = 200.0;
uniform float camera_zoom = 1.0;
uniform vec2 viewport_size;

void fragment() {
	// Calculate world position from screen position
	// FRAGCOORD is in screen pixels, need to convert to world coordinates
	vec2 screen_pos = FRAGCOORD.xy;
	
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
		
		// Output black for unexplored areas (alpha = 1 for black, 0 for explored)
		COLOR = vec4(0.0, 0.0, 0.0, 1.0 - explored);
	}
}

