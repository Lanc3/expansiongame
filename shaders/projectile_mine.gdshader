shader_type canvas_item;

// Proximity mine - pulsing red core with proximity ring indicator
// Blinking warning effect that intensifies as timer decreases
uniform vec4 core_color : source_color = vec4(0.9, 0.2, 0.1, 1.0);       // Red core
uniform vec4 shell_color : source_color = vec4(0.3, 0.3, 0.35, 1.0);    // Dark metallic shell
uniform vec4 ring_color : source_color = vec4(0.8, 0.2, 0.2, 0.4);      // Proximity ring
uniform vec4 warning_color : source_color = vec4(1.0, 0.3, 0.1, 1.0);   // Warning blink

uniform float core_size : hint_range(0.05, 0.2) = 0.12;      // Size of glowing core
uniform float shell_size : hint_range(0.1, 0.35) = 0.22;     // Size of outer shell
uniform float ring_radius : hint_range(0.3, 0.5) = 0.4;      // Proximity ring radius
uniform float ring_thickness : hint_range(0.01, 0.1) = 0.03; // Ring line thickness
uniform float pulse_speed : hint_range(1.0, 8.0) = 3.0;      // Core pulse rate
uniform float armed : hint_range(0.0, 1.0) = 1.0;            // 0 = traveling, 1 = armed
uniform float urgency : hint_range(0.0, 1.0) = 0.0;          // 0 = full time, 1 = about to explode

void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv);
    
    // Pulse rate increases with urgency
    float current_pulse_speed = pulse_speed * (1.0 + urgency * 3.0);
    float pulse = 0.7 + 0.3 * sin(TIME * current_pulse_speed);
    
    // Blink rate for warning (faster when urgent)
    float blink_rate = 2.0 + urgency * 8.0;
    float blink = step(0.5, fract(TIME * blink_rate));
    
    // Core glow - pulsing center
    float core_glow = 1.0 - smoothstep(0.0, core_size, dist);
    core_glow *= pulse;
    
    // Inner bright spot
    float inner_bright = 1.0 - smoothstep(0.0, core_size * 0.4, dist);
    
    // Outer shell (metallic ring around core)
    float shell_inner = smoothstep(core_size * 0.8, core_size, dist);
    float shell_outer = 1.0 - smoothstep(shell_size * 0.9, shell_size, dist);
    float shell_mask = shell_inner * shell_outer;
    
    // Shell detail - segments
    float angle = atan(uv.y, uv.x);
    float segments = step(0.9, fract(angle * 3.0 / TAU + 0.5));
    shell_mask *= (1.0 - segments * 0.3);
    
    // Proximity ring (only when armed)
    float ring_dist = abs(dist - ring_radius);
    float ring_mask = (1.0 - smoothstep(0.0, ring_thickness, ring_dist)) * armed;
    
    // Ring pulse - expanding outward
    float ring_pulse = fract(TIME * 0.8);
    float expanding_ring_dist = abs(dist - ring_radius * ring_pulse);
    float expanding_ring = (1.0 - smoothstep(0.0, ring_thickness * 2.0, expanding_ring_dist));
    expanding_ring *= (1.0 - ring_pulse) * armed * 0.5;  // Fade as it expands
    
    // Warning indicators at cardinal points (blink faster when urgent)
    float indicator_angle = mod(angle + PI, TAU / 4.0);
    float indicator_mask = step(indicator_angle, 0.15) * step(ring_radius - 0.05, dist);
    indicator_mask *= step(dist, ring_radius + 0.05);
    indicator_mask *= blink * armed * (0.5 + urgency * 0.5);
    
    // Combine colors
    vec4 result = vec4(0.0);
    
    // Background glow when armed
    float bg_glow = (1.0 - smoothstep(0.0, shell_size * 1.5, dist)) * 0.15 * armed;
    result += core_color * bg_glow;
    
    // Proximity ring
    result += ring_color * ring_mask;
    result += ring_color * expanding_ring;
    
    // Warning indicators
    result += warning_color * indicator_mask;
    
    // Shell
    result += shell_color * shell_mask;
    
    // Core glow
    vec4 core_final = mix(core_color, warning_color, urgency * blink);
    result += core_final * core_glow;
    
    // Inner bright spot
    result += vec4(1.0, 0.9, 0.8, 1.0) * inner_bright * 0.5;
    
    // Alpha calculation
    result.a = max(max(core_glow, shell_mask), max(ring_mask * 0.6, expanding_ring * 0.4));
    result.a = max(result.a, indicator_mask * 0.8);
    result.a = max(result.a, bg_glow);
    result.a = clamp(result.a, 0.0, 1.0);
    
    // Boost brightness
    result.rgb *= 1.3;
    
    COLOR = result;
}

