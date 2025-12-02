shader_type canvas_item;

// EMP Burst expanding ring shader
uniform vec4 emp_color : source_color = vec4(0.5, 0.3, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float ring_width : hint_range(0.01, 0.3) = 0.1;
uniform float expansion_speed : hint_range(0.0, 5.0) = 2.0;
uniform float electric_intensity : hint_range(0.0, 2.0) = 1.0;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);
    
    // Expanding ring
    float ring_pos = fract(TIME * expansion_speed * 0.3);
    float ring = 1.0 - smoothstep(ring_pos - ring_width, ring_pos, dist);
    ring *= smoothstep(ring_pos - ring_width * 2.0, ring_pos - ring_width, dist);
    ring *= (1.0 - ring_pos);  // Fade as it expands
    
    // Electric arcs around the ring
    float arcs = sin(angle * 8.0 + TIME * 20.0) * 0.5 + 0.5;
    arcs *= sin(angle * 12.0 - TIME * 15.0) * 0.5 + 0.5;
    arcs = step(0.7, arcs);
    
    // Core glow
    float core = 1.0 - smoothstep(0.0, 0.15, dist);
    core *= (1.0 - ring_pos * 0.5);
    
    // Random electric sparks
    float sparks = random(floor(vec2(angle * 10.0, dist * 20.0) + TIME * 5.0));
    sparks = step(0.95, sparks) * ring;
    
    // Combine
    vec4 result = vec4(0.0);
    result += core_color * core;
    result += emp_color * ring * (0.7 + arcs * 0.3 * electric_intensity);
    result += core_color * sparks;
    
    result.a = max(core, ring);
    
    // Fade outer edge
    result.a *= 1.0 - smoothstep(0.4, 0.5, dist);
    
    COLOR = result;
}

