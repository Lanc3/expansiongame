shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.6, 0.3, 1.0, 1.0);
uniform float swirl_strength : hint_range(0.0, 20.0) = 8.0;
uniform float time_speed : hint_range(0.0, 5.0) = 1.0;
uniform float core_size : hint_range(0.0, 1.0) = 0.2;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.1;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;
uniform float pulse_amount : hint_range(0.0, 0.2) = 0.05;

// Noise function for texture detail
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 uv) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    mat2 rot = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.5)));
    for (int i = 0; i < 5; ++i) {
        v += a * noise(uv);
        uv = rot * uv * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv) * 2.0; // 0 at center, 1 at edge
    float angle = atan(uv.y, uv.x);
    
    // Discard outside circle
    if (dist > 1.0) {
        discard;
    }
    
    // Pulsing effect
    float pulse = sin(TIME * pulse_speed) * pulse_amount;
    float current_core_size = core_size + pulse;
    
    // Swirl distortion
    float swirl = (1.0 - dist) * swirl_strength;
    float spiral_angle = angle + swirl - TIME * time_speed;
    
    // Create accretion disk texture using noise
    vec2 polar_uv = vec2(dist, spiral_angle / (2.0 * 3.14159));
    
    // Layer multiple noise patterns for complexity
    float n1 = fbm(polar_uv * vec2(3.0, 10.0) + vec2(TIME * 0.2, 0.0));
    float n2 = fbm(polar_uv * vec2(5.0, 15.0) - vec2(TIME * 0.5, 0.0));
    
    // Combine noise
    float energy = n1 * 0.6 + n2 * 0.4;
    
    // Enhance brightness at certain bands
    energy = pow(energy, 1.5) * 2.0;
    
    // Event horizon (dark center)
    float horizon = smoothstep(current_core_size, current_core_size + edge_softness, dist);
    
    // Fade out at edges
    float edge_fade = smoothstep(1.0, 0.8, dist);
    
    // Color composition
    vec3 final_color = base_color.rgb * energy;
    
    // Add a hot core ring
    float ring = smoothstep(current_core_size, current_core_size + 0.05, dist) * 
                 smoothstep(current_core_size + 0.15, current_core_size + 0.05, dist);
    final_color += base_color.rgb * ring * 2.0; // Bright ring
    
    // Apply event horizon and edge fade
    float alpha = horizon * edge_fade * base_color.a;
    
    // Final output
    COLOR = vec4(final_color, alpha);
}
