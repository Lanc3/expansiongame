shader_type canvas_item;

// Cryo Cannon ice/frost beam shader
uniform vec4 ice_color : source_color = vec4(0.6, 0.9, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float crystal_density : hint_range(1.0, 20.0) = 8.0;
uniform float shimmer_speed : hint_range(0.0, 10.0) = 3.0;
uniform float frost_spread : hint_range(0.0, 0.5) = 0.2;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    
    // Core beam
    float dist_from_center = abs(uv.x - 0.5);
    float core = 1.0 - smoothstep(0.0, 0.08, dist_from_center);
    float beam = 1.0 - smoothstep(0.0, frost_spread, dist_from_center);
    
    // Ice crystal pattern
    vec2 crystal_uv = uv * crystal_density;
    float crystals = random(floor(crystal_uv));
    crystals *= step(0.7, crystals);  // Only show some crystals
    
    // Shimmer effect
    float shimmer = sin(uv.y * 20.0 + TIME * shimmer_speed) * 0.5 + 0.5;
    shimmer *= sin(uv.x * 15.0 - TIME * shimmer_speed * 0.7) * 0.5 + 0.5;
    
    // Sparkle points
    float sparkle = random(floor(uv * 30.0 + TIME * 2.0));
    sparkle = step(0.98, sparkle);
    
    // Combine
    vec4 result = vec4(0.0);
    result += core_color * core;
    result += ice_color * beam * (0.6 + shimmer * 0.4);
    result += ice_color * crystals * beam * 0.5;
    result += core_color * sparkle * beam;
    
    // Fade at ends
    result.a *= beam;
    result.a *= 1.0 - smoothstep(0.4, 0.5, abs(uv.y - 0.5));
    
    COLOR = result;
}

