shader_type canvas_item;

// Cosmic dust shader with animated noise for volumetric space clouds

uniform vec3 dust_tint : source_color = vec3(0.5, 0.3, 0.8); // Purple tint
uniform float dust_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float animation_speed : hint_range(0.0, 2.0) = 0.05;
uniform float scale : hint_range(0.1, 10.0) = 2.0;
uniform int octaves : hint_range(1, 8) = 4;

// Simple 2D noise function
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	
	// Smooth interpolation
	f = f * f * (3.0 - 2.0 * f);
	
	// Four corners
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	
	// Bilinear interpolation
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion for organic patterns
float fbm(vec2 p, int num_octaves) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	
	for (int i = 0; i < num_octaves; i++) {
		value += amplitude * noise(p * frequency);
		frequency *= 2.0;
		amplitude *= 0.5;
	}
	
	return value;
}

void fragment() {
	// Get UV coordinates and apply scale
	vec2 uv = UV * scale;
	
	// Animate the dust by offsetting UV over time
	vec2 offset = vec2(TIME * animation_speed * 0.3, TIME * animation_speed * 0.5);
	uv += offset;
	
	// Generate multi-octave noise for organic clouds
	float dust = fbm(uv, octaves);
	
	// Add secondary layer with different movement
	vec2 uv2 = uv * 1.5 - offset * 0.7;
	float dust2 = fbm(uv2, octaves - 1);
	
	// Combine layers
	dust = (dust + dust2 * 0.5) / 1.5;
	
	// Create more defined cloud edges
	dust = pow(dust, 1.5);
	
	// Apply color tint
	vec3 color = dust_tint * dust;
	
	// Set alpha based on dust density
	float alpha = dust * dust_intensity;
	
	COLOR = vec4(color, alpha);
}

