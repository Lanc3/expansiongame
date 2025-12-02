shader_type canvas_item;

uniform sampler2D noise_tex : hint_default_black;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.0, 0.2) = 0.05;
uniform vec4 edge_color : source_color = vec4(1.0, 0.5, 0.2, 1.0);

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	float noise_sample = texture(noise_tex, UV).r;

	if (noise_sample < amount - edge_width) {
		discard;
	}

	float edge = smoothstep(amount + edge_width, amount - edge_width, noise_sample);
	vec3 color = mix(base_color.rgb, edge_color.rgb, edge);
	float alpha = mix(base_color.a, edge_color.a, edge);

	COLOR = vec4(color, alpha);
}

