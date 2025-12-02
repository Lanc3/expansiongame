shader_type canvas_item;

// Lightning bolt shader for Tesla Coil projectiles
uniform vec4 lightning_color : source_color = vec4(0.4, 0.8, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float size : hint_range(0.0, 1.0) = 0.15;
uniform float width : hint_range(0.0, 1.0) = 0.3;
uniform float speed : hint_range(0.0, 50.0) = 20.0;
uniform float cycle : hint_range(1.0, 20.0) = 8.0;
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.5;

float rand(float x) {
    return fract(sin(x) * 100000.0);
}

void fragment() {
    vec2 uv = UV;
    
    // Create jagged lightning bolt along length
    float bolt = abs(mod(uv.y * cycle + rand(floor(TIME * speed)) * 0.5, 0.5) - 0.25) - 0.125;
    bolt *= 4.0 * width;
    
    // Scale down at start and end for tapering
    bolt *= (0.5 - abs(uv.y - 0.5)) * 2.0;
    
    // Create the lightning line
    float wave = abs(uv.x - 0.5 + bolt);
    float core = 1.0 - smoothstep(0.0, size * 0.3, wave);
    float glow = 1.0 - smoothstep(0.0, size * 0.8, wave);
    
    // Flickering effect
    float flicker = 0.7 + 0.3 * sin(TIME * 30.0 + rand(floor(TIME * 10.0)) * 6.28);
    
    // Combine core and glow
    vec4 result = core_color * core + lightning_color * glow * glow_intensity;
    result.a *= flicker;
    result.a *= (1.0 - smoothstep(0.4, 0.5, abs(uv.y - 0.5)));  // Fade at ends
    
    COLOR = result;
}

