shader_type canvas_item;

// Repair Beam green healing shader with sparkles
uniform vec4 heal_color : source_color = vec4(0.3, 1.0, 0.4, 1.0);
uniform vec4 sparkle_color : source_color = vec4(1.0, 1.0, 0.8, 1.0);
uniform float beam_width : hint_range(0.0, 0.5) = 0.15;
uniform float sparkle_speed : hint_range(0.0, 20.0) = 8.0;
uniform float wave_intensity : hint_range(0.0, 1.0) = 0.5;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    
    // Core beam with soft edges
    float dist_from_center = abs(uv.x - 0.5);
    float core = 1.0 - smoothstep(0.0, beam_width * 0.4, dist_from_center);
    float beam = 1.0 - smoothstep(0.0, beam_width, dist_from_center);
    
    // Healing wave effect (moving toward target)
    float wave = sin(uv.y * 15.0 - TIME * sparkle_speed) * 0.5 + 0.5;
    wave = pow(wave, 2.0) * wave_intensity;
    
    // Plus signs / cross sparkles for healing aesthetic
    vec2 sparkle_uv = fract(uv * vec2(3.0, 10.0) + vec2(0.0, -TIME * 2.0));
    float cross_h = step(0.4, sparkle_uv.x) * step(sparkle_uv.x, 0.6) * step(0.3, sparkle_uv.y) * step(sparkle_uv.y, 0.7);
    float cross_v = step(0.3, sparkle_uv.x) * step(sparkle_uv.x, 0.7) * step(0.4, sparkle_uv.y) * step(sparkle_uv.y, 0.6);
    float crosses = (cross_h + cross_v) * beam;
    crosses *= random(floor(uv * vec2(3.0, 10.0)));
    crosses = step(0.5, crosses);
    
    // Random sparkles
    float sparkles = random(floor(uv * 40.0 + TIME * 3.0));
    sparkles = step(0.97, sparkles) * beam;
    
    // Pulse effect
    float pulse = 0.85 + 0.15 * sin(TIME * 6.0);
    
    // Combine
    vec4 result = vec4(0.0);
    result += sparkle_color * core * 0.8;
    result += heal_color * beam * (0.6 + wave * 0.4) * pulse;
    result += sparkle_color * (crosses + sparkles);
    
    result.a *= beam;
    result.a *= 1.0 - smoothstep(0.4, 0.5, abs(uv.y - 0.5));
    
    COLOR = result;
}

