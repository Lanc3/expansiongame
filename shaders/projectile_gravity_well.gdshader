shader_type canvas_item;

// Gravity Well dark swirling vortex shader
uniform vec4 void_color : source_color = vec4(0.1, 0.0, 0.2, 1.0);
uniform vec4 edge_color : source_color = vec4(0.6, 0.2, 0.8, 1.0);
uniform float swirl_speed : hint_range(0.0, 10.0) = 3.0;
uniform float distortion : hint_range(0.0, 1.0) = 0.3;
uniform float spiral_arms : hint_range(1.0, 8.0) = 3.0;

void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);
    
    // Swirling distortion
    float swirl = angle + dist * 5.0 - TIME * swirl_speed;
    
    // Spiral arms
    float spiral = sin(swirl * spiral_arms) * 0.5 + 0.5;
    spiral *= 1.0 - dist * 2.0;  // Fade toward center
    spiral = max(0.0, spiral);
    
    // Dark center (event horizon)
    float center = 1.0 - smoothstep(0.0, 0.2, dist);
    
    // Edge glow
    float edge = smoothstep(0.3, 0.4, dist) * (1.0 - smoothstep(0.4, 0.5, dist));
    
    // Particles being pulled in
    float pull_angle = angle + TIME * swirl_speed * 0.5;
    float particles = fract(sin(dot(vec2(pull_angle * 5.0, dist * 10.0 + TIME), vec2(12.9898, 78.233))) * 43758.5453);
    particles = step(0.97, particles) * (1.0 - center);
    
    // Combine
    vec4 result = vec4(0.0);
    result += void_color * center;
    result += edge_color * spiral * 0.6;
    result += edge_color * edge * 1.5;
    result += edge_color * particles * 2.0;
    
    result.a = smoothstep(0.5, 0.3, dist);
    result.a = max(result.a, center);
    result.a = max(result.a, edge * 0.8);
    
    COLOR = result;
}

