shader_type canvas_item;

// Spiral galaxy shader for galaxy map background
uniform float spiral_tightness : hint_range(0.0, 1.0) = 0.5;
uniform int num_arms : hint_range(2, 5) = 3;
uniform vec3 outer_color : source_color = vec3(0.2, 0.4, 0.8);  // Blue
uniform vec3 center_color : source_color = vec3(0.8, 0.3, 0.2);  // Red-orange
uniform float star_density : hint_range(0.0, 0.02) = 0.005;
uniform float nebula_intensity : hint_range(0.0, 1.0) = 0.3;

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
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(p * frequency);
		frequency *= 2.0;
		amplitude *= 0.5;
	}
	
	return value;
}

// Generate spiral arm pattern
float spiral_arms(vec2 polar_pos, float angle, float radius) {
	float intensity = 0.0;
	
	for (int i = 0; i < num_arms; i++) {
		// Calculate arm angle
		float arm_angle = float(i) * (6.28318 / float(num_arms));
		
		// Logarithmic spiral equation
		float spiral_angle = arm_angle + radius * spiral_tightness * 3.0;
		
		// Angle difference
		float angle_diff = abs(angle - spiral_angle);
		
		// Wrap around for continuity
		angle_diff = min(angle_diff, 6.28318 - angle_diff);
		
		// Calculate intensity based on distance from spiral arm
		float arm_width = 0.3 + radius * 0.2;  // Wider arms at outer edge
		float arm_intensity = exp(-angle_diff * angle_diff / (arm_width * arm_width));
		
		intensity = max(intensity, arm_intensity);
	}
	
	// Add density variation along radius (more dense in middle)
	float radial_density = exp(-pow(radius - 0.5, 2.0) * 4.0);
	intensity *= radial_density;
	
	return intensity;
}

void fragment() {
	// Convert to polar coordinates from center
	vec2 uv = UV;
	vec2 centered = uv - vec2(0.5, 0.5);
	float radius = length(centered);
	float angle = atan(centered.y, centered.x);
	
	// === BACKGROUND (Space) ===
	vec3 color = vec3(0.02, 0.02, 0.05);  // Dark space
	
	// === STARS ===
	float star_value = hash(floor(uv * 800.0));
	if (star_value > (1.0 - star_density)) {
		float star_brightness = (star_value - (1.0 - star_density)) / star_density;
		color += vec3(star_brightness * 0.8);
	}
	
	// === NEBULA CLOUDS ===
	vec2 nebula_uv = uv * 3.0;
	float nebula = fbm(nebula_uv) * nebula_intensity;
	
	// Color nebula based on region (blue outer, red center)
	vec3 nebula_color = mix(outer_color, center_color, radius);
	color += nebula_color * nebula * 0.3;
	
	// === SPIRAL ARMS ===
	if (radius < 0.48 && radius > 0.05) {  // Galaxy disk
		float arm_intensity = spiral_arms(centered, angle, radius);
		
		// Add noise to spiral arms for organic look
		float arm_noise = fbm(vec2(angle * 5.0, radius * 10.0));
		arm_intensity *= (0.7 + arm_noise * 0.3);
		
		// Color gradient from outer (blue) to center (orange/red)
		vec3 arm_color = mix(outer_color, center_color, pow(radius * 2.0, 1.5));
		
		color = mix(color, arm_color * 1.2, arm_intensity * 0.8);
	}
	
	// === GALACTIC CORE ===
	if (radius < 0.08) {
		float core_intensity = 1.0 - (radius / 0.08);
		vec3 core_color = vec3(1.0, 0.8, 0.6);  // Bright yellow-white
		color = mix(color, core_color, core_intensity * 0.9);
	}
	
	// === RADIAL GRADIENT (Fade outer edges) ===
	float edge_fade = smoothstep(0.50, 0.45, radius);
	color *= edge_fade;
	
	// === VIGNETTE ===
	float vignette = 1.0 - smoothstep(0.3, 0.5, radius);
	color *= (0.4 + vignette * 0.6);
	
	COLOR = vec4(color, 1.0);
}


