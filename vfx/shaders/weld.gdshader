shader_type canvas_item;
render_mode unshaded;

uniform sampler2D mask_tex : hint_default_white;
uniform sampler2D noise_tex : hint_default_black;
uniform vec4 base_color : source_color = vec4(0.2, 0.6, 1.0, 0.75);
uniform vec4 glow_color : source_color = vec4(0.3, 0.9, 1.2, 0.9);
uniform float stripe_density = 18.0;
uniform float noise_amount = 0.2;

void fragment() {
	float mask = texture(mask_tex, UV).r;
	if (mask <= 0.02) {
		discard;
	}

	float noise_sample = texture(noise_tex, UV * 4.0).r * noise_amount;
	float stripes = 0.5 + 0.5 * sin((UV.y + noise_sample) * stripe_density);
	stripes *= 0.8 + 0.2 * cos((UV.x + noise_sample) * stripe_density * 0.5);
	stripes *= mask;

	vec3 color = mix(base_color.rgb, glow_color.rgb, stripes);
	float alpha = max(base_color.a, glow_color.a * stripes);
	alpha *= mask;

	if (alpha <= 0.02) {
		discard;
	}

	COLOR = vec4(color, alpha);
}

