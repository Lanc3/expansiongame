shader_type canvas_item;
render_mode unshaded;

uniform vec4 base_color : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform float ring_radius : hint_range(0.0, 1.5) = 0.6;
uniform float pulse_speed : hint_range(0.0, 4.0) = 1.5;
uniform float grid_scale : hint_range(1.0, 32.0) = 12.0;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.05;
uniform float fresnel_power : hint_range(0.5, 4.0) = 1.8;
uniform float ring_scale : hint_range(0.25, 4.0) = 1.0;
uniform float hex_strength : hint_range(0.0, 1.0) = 0.6;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.3;
uniform sampler2D hex_tex : hint_default_white;
uniform sampler2D noise_tex : hint_default_black;
uniform sampler2D ring_tex : hint_default_white;

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float dist = length(centered);

	float fresnel = pow(clamp(1.0 - dist, 0.0, 1.0), fresnel_power);
	float ring = smoothstep(ring_radius, ring_radius - 0.05, dist);
	float ring_pattern = texture(ring_tex, vec2(dist * ring_scale + TIME * 0.2, 0.5)).r;
	ring = mix(ring, ring_pattern, 0.5);
	float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed + dist * 6.0);

	vec2 grid_uv = UV * grid_scale;
	float hex = texture(hex_tex, grid_uv).r;
	float noise = texture(noise_tex, grid_uv * 0.5 + vec2(TIME * 0.15, -TIME * 0.1)).r;
	float grid = mix(hex, noise, noise_strength);
	grid = mix(grid, 0.5 + 0.5 * sin(grid_uv.x + TIME * pulse_speed) * sin(grid_uv.y - TIME * (pulse_speed * 0.5)), 0.35);
	grid = mix(0.5, grid, hex_strength);

	float alpha = clamp(fresnel * 0.6 + ring * 0.4, 0.0, 1.0);
	alpha *= pulse * 0.9 + 0.1;

	if (alpha < alpha_cutoff) {
		discard;
	}

	vec3 color = base_color.rgb * (grid * 0.5 + fresnel);
	COLOR = vec4(color, alpha * base_color.a);
}

