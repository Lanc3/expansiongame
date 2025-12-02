shader_type canvas_item;
render_mode unshaded;

uniform sampler2D mask_tex : hint_default_white;
uniform sampler2D noise_tex : hint_default_black;
uniform vec4 core_color : source_color = vec4(0.08, 0.04, 0.02, 0.9);
uniform vec4 edge_color : source_color = vec4(0.4, 0.2, 0.05, 0.6);
uniform vec4 rim_color : source_color = vec4(0.9, 0.5, 0.1, 0.35);
uniform float distortion = 0.25;
uniform float radius = 0.5;

void fragment() {
	float mask = texture(mask_tex, UV).r;
	if (mask <= 0.02) {
		discard;
	}

	vec2 centered = UV * 2.0 - 1.0;
	float dist = length(centered);
	float noise_sample = texture(noise_tex, UV * 2.5).r * distortion;

	float falloff = smoothstep(radius, radius - 0.25, dist + noise_sample);
	float rim = smoothstep(radius * 0.9, radius * 0.6, dist + noise_sample * 0.5);

	vec3 color = mix(core_color.rgb, edge_color.rgb, falloff);
	color = mix(color, rim_color.rgb, rim);

	float alpha = max(core_color.a * (1.0 - falloff), rim_color.a * rim);
	alpha *= mask;
	if (alpha <= 0.01) {
		discard;
	}

	COLOR = vec4(color, alpha);
}

