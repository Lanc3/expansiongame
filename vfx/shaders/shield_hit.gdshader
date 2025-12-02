shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec4 base_color : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform vec2 hit_origin = vec2(0.5, 0.5);
uniform float hit_time = 1.0;
uniform float fresnel_power = 2.25;
uniform float refract_strength = 0.02;
uniform float ring_thickness = 0.08;
uniform float ring_fade = 0.35;
uniform float ripple_scale = 1.0;
uniform sampler2D ripple_mask : hint_default_white;
uniform sampler2D noise_tex : hint_default_black;
uniform sampler2D fresnel_gradient : hint_default_white;

void fragment() {
	vec2 dir = UV - hit_origin;
	float dist = length(dir);
	float fresnel = pow(clamp(1.0 - dist, 0.0, 1.0), fresnel_power);

	vec2 ripple_uv = (UV - hit_origin) * ripple_scale + hit_origin;
	float ripple_mask_value = texture(ripple_mask, ripple_uv).r;
	float wave_center = clamp(hit_time, 0.0, 1.2);
	float noise = texture(noise_tex, dir * 6.0 + vec2(TIME * 0.4, TIME * 0.2)).r;
	float ring = smoothstep(ring_thickness + noise * 0.06, 0.0, abs(dist - wave_center));
	ring *= smoothstep(0.0, ring_fade + noise * 0.05, wave_center);
	ring *= ripple_mask_value;

	vec2 refract_uv = SCREEN_UV + normalize(dir) * refract_strength * (fresnel + noise * 0.1);
	vec3 refracted = texture(SCREEN_TEXTURE, refract_uv).rgb;

	vec3 fresnel_color = texture(fresnel_gradient, vec2(clamp(fresnel, 0.0, 1.0), 0.5)).rgb;
	vec3 emissive = mix(base_color.rgb, fresnel_color, 0.6);
	emissive *= (0.4 + fresnel * 0.8 + ring * 1.2);

	float alpha = clamp(fresnel * 0.4 + ring * 0.6, 0.0, 1.0);
	vec3 color = mix(refracted, emissive, 0.65);

	COLOR = vec4(color, alpha);
}

