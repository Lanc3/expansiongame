shader_type canvas_item;

// Ion Cannon blue pulse beam shader
uniform vec4 ion_color : source_color = vec4(0.3, 0.6, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(0.8, 0.95, 1.0, 1.0);
uniform float pulse_speed : hint_range(0.0, 30.0) = 15.0;
uniform float beam_width : hint_range(0.0, 0.5) = 0.15;
uniform float ring_count : hint_range(1.0, 10.0) = 4.0;

void fragment() {
    vec2 uv = UV;
    
    // Moving rings along the beam
    float rings = sin((uv.y - TIME * 0.5) * ring_count * 6.28) * 0.5 + 0.5;
    
    // Core beam
    float dist_from_center = abs(uv.x - 0.5);
    float core = 1.0 - smoothstep(0.0, beam_width * 0.3, dist_from_center);
    float beam = 1.0 - smoothstep(0.0, beam_width, dist_from_center);
    
    // Pulsing glow
    float pulse = 0.7 + 0.3 * sin(TIME * pulse_speed);
    
    // Electric crackling effect
    float crackle = fract(sin(dot(uv * 50.0 + TIME * 10.0, vec2(12.9898, 78.233))) * 43758.5453);
    crackle = step(0.95, crackle) * beam;
    
    // Combine
    vec4 result = vec4(0.0);
    result += core_color * core * pulse;
    result += ion_color * beam * (0.5 + rings * 0.5) * pulse;
    result += core_color * crackle;
    
    // Fade at ends
    result.a *= beam;
    result.a *= 1.0 - smoothstep(0.4, 0.5, abs(uv.y - 0.5));
    
    COLOR = result;
}

