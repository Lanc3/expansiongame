shader_type canvas_item;

// Particle Beam sustained purple beam shader
uniform vec4 beam_color : source_color = vec4(0.8, 0.3, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.8, 1.0, 1.0);
uniform float beam_width : hint_range(0.0, 0.5) = 0.12;
uniform float particle_speed : hint_range(0.0, 20.0) = 10.0;
uniform float particle_density : hint_range(1.0, 50.0) = 20.0;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    
    // Core beam
    float dist_from_center = abs(uv.x - 0.5);
    float core = 1.0 - smoothstep(0.0, beam_width * 0.4, dist_from_center);
    float beam = 1.0 - smoothstep(0.0, beam_width, dist_from_center);
    
    // Flowing particles along beam
    vec2 particle_uv = vec2(uv.x * 5.0, uv.y * particle_density - TIME * particle_speed);
    float particles = random(floor(particle_uv));
    particles = step(0.85, particles) * beam;
    
    // Energy waves
    float wave = sin(uv.y * 30.0 - TIME * particle_speed * 2.0) * 0.5 + 0.5;
    wave *= beam;
    
    // Pulsing intensity
    float pulse = 0.8 + 0.2 * sin(TIME * 8.0);
    
    // Combine
    vec4 result = vec4(0.0);
    result += core_color * core * pulse;
    result += beam_color * beam * (0.5 + wave * 0.3);
    result += core_color * particles * 0.8;
    
    result.a *= beam;
    result.a *= 1.0 - smoothstep(0.45, 0.5, abs(uv.y - 0.5));
    
    COLOR = result;
}

