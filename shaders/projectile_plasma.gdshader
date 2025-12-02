shader_type canvas_item;

// Glowing plasma blob shader for Plasma Cannon
uniform vec4 plasma_color : source_color = vec4(0.3, 1.0, 0.4, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 0.8, 1.0);
uniform float pulse_speed : hint_range(0.0, 20.0) = 8.0;
uniform float wobble_amount : hint_range(0.0, 0.2) = 0.05;
uniform float glow_size : hint_range(0.0, 1.0) = 0.4;

void fragment() {
    vec2 uv = UV - 0.5;
    
    // Wobble effect
    float angle = atan(uv.y, uv.x);
    float wobble = sin(angle * 5.0 + TIME * pulse_speed) * wobble_amount;
    
    // Distance from center with wobble
    float dist = length(uv) + wobble;
    
    // Pulsing effect
    float pulse = 0.9 + 0.1 * sin(TIME * pulse_speed * 2.0);
    
    // Core (bright center)
    float core = 1.0 - smoothstep(0.0, 0.15 * pulse, dist);
    
    // Inner glow
    float inner = 1.0 - smoothstep(0.1, 0.25 * pulse, dist);
    
    // Outer glow
    float outer = 1.0 - smoothstep(0.15, glow_size * pulse, dist);
    
    // Combine layers
    vec4 result = vec4(0.0);
    result += core_color * core;
    result += plasma_color * 1.5 * inner * (1.0 - core);
    result += plasma_color * 0.6 * outer * (1.0 - inner);
    
    result.a = outer;
    
    COLOR = result;
}

