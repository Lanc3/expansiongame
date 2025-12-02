shader_type canvas_item;
render_mode unshaded;

uniform vec4 color_start : source_color = vec4(0.9, 0.2, 0.2, 1.0);
uniform vec4 color_end : source_color = vec4(1.0, 0.9, 0.2, 0.0);
uniform float fade_distance : hint_range(0.05, 1.0) = 0.35;
uniform float width_fade : hint_range(0.0, 1.0) = 0.2;
uniform float mask_scale : hint_range(0.1, 4.0) = 1.0;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.25;
uniform float noise_speed : hint_range(0.0, 4.0) = 0.6;
uniform sampler2D mask_tex : hint_default_white;
uniform sampler2D noise_tex : hint_default_black;

void fragment() {
	float along = clamp(UV.x, 0.0, 1.0);
	float across = abs(UV.y - 0.5) * 2.0;

	vec4 color = mix(color_start, color_end, along);
	float mask = texture(mask_tex, vec2(along * mask_scale, 0.5)).r;
	float noise = texture(noise_tex, vec2(along * mask_scale, (UV.y - 0.5) * 3.5) + vec2(TIME * noise_speed, 0.0)).r;

	float alpha = color.a * smoothstep(1.0, 1.0 - fade_distance, along);
	alpha *= smoothstep(1.0, width_fade, across);
	alpha *= mask;
	alpha *= mix(1.0 - noise_strength, 1.0, noise);

	if (alpha <= 0.001) {
		discard;
	}

	vec3 tinted = color.rgb * (0.8 + mask * 0.4);
	tinted = mix(tinted, tinted * (0.8 + noise * noise_strength), 0.5);

	COLOR = vec4(tinted, alpha);
}

