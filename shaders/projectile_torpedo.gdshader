shader_type canvas_item;

// Heavy torpedo projectile - blue-white engine trail with exhaust glow
// Pulsing glow around missile body with motion blur effect
uniform vec4 body_color : source_color = vec4(0.4, 0.5, 0.6, 1.0);       // Dark metallic body
uniform vec4 engine_color : source_color = vec4(0.5, 0.8, 1.0, 1.0);    // Blue-white engine
uniform vec4 exhaust_color : source_color = vec4(0.3, 0.6, 1.0, 1.0);   // Blue exhaust trail
uniform vec4 glow_color : source_color = vec4(0.4, 0.7, 1.0, 0.6);      // Ambient glow

uniform float body_length : hint_range(0.1, 0.4) = 0.25;     // Length of torpedo body
uniform float body_width : hint_range(0.02, 0.15) = 0.08;    // Width of torpedo body
uniform float trail_length : hint_range(0.2, 0.8) = 0.5;     // Length of exhaust trail
uniform float glow_intensity : hint_range(0.5, 3.0) = 1.5;   // Glow brightness
uniform float pulse_speed : hint_range(1.0, 10.0) = 4.0;     // Engine pulse rate

void fragment() {
    vec2 uv = UV - 0.5;
    
    // Rotate so torpedo points right (along X axis)
    // Torpedo travels in +Y direction in game, so we work with that
    
    // Create torpedo body (ellipse at front)
    float body_dist_x = uv.x / body_width;
    float body_dist_y = (uv.y + 0.15) / body_length;  // Offset forward
    float body_dist = length(vec2(body_dist_x, body_dist_y));
    float body_mask = 1.0 - smoothstep(0.8, 1.0, body_dist);
    
    // Only show body in the front half
    body_mask *= step(-0.1, uv.y);
    
    // Engine glow at back of torpedo
    float engine_y = uv.y + 0.2;  // Position at back
    float engine_dist = length(vec2(uv.x / (body_width * 1.5), engine_y / 0.08));
    float engine_pulse = 0.8 + 0.2 * sin(TIME * pulse_speed);
    float engine_mask = (1.0 - smoothstep(0.0, 1.0, engine_dist)) * engine_pulse;
    engine_mask *= step(uv.y, 0.0);  // Only at back
    
    // Exhaust trail - extends behind torpedo
    float trail_x = abs(uv.x) / (body_width * 0.8);
    float trail_y = (-uv.y - 0.1) / trail_length;  // Behind torpedo
    
    // Trail tapers and fades
    float trail_taper = 1.0 - smoothstep(0.0, 1.0, trail_y);
    float trail_width = trail_x / (trail_taper * 0.8 + 0.2);
    float trail_mask = (1.0 - smoothstep(0.0, 1.0, trail_width)) * trail_taper;
    trail_mask *= step(0.0, -uv.y);  // Only behind
    trail_mask *= step(trail_y, 1.0);  // Limit length
    
    // Add some turbulence to trail
    float turbulence = sin(uv.y * 30.0 + TIME * 15.0) * 0.3 + 0.7;
    trail_mask *= turbulence;
    
    // Particle sparks in exhaust
    float spark_phase = fract(uv.y * 8.0 - TIME * 10.0);
    float spark = step(0.7, spark_phase) * step(trail_y, 0.8);
    spark *= step(abs(uv.x), body_width * 0.5 * (1.0 - trail_y));
    
    // Outer glow around entire torpedo
    float glow_dist = length(uv * vec2(1.0, 0.5));
    float outer_glow = (1.0 - smoothstep(0.0, 0.3, glow_dist)) * 0.3;
    outer_glow *= 0.8 + 0.2 * sin(TIME * pulse_speed * 0.5);
    
    // Combine all elements
    vec4 result = vec4(0.0);
    
    // Layer from back to front
    result += glow_color * outer_glow * glow_intensity;
    result += exhaust_color * trail_mask * 0.8;
    result += engine_color * spark * 0.6;
    result += engine_color * engine_mask * glow_intensity;
    result += body_color * body_mask;
    
    // Highlight on body
    float highlight = (1.0 - smoothstep(0.0, 0.5, body_dist)) * body_mask * 0.3;
    result.rgb += vec3(highlight);
    
    // Alpha
    result.a = max(max(body_mask, engine_mask * 0.9), max(trail_mask * 0.7, outer_glow * 0.5));
    result.a = clamp(result.a, 0.0, 1.0);
    
    // Boost colors
    result.rgb *= 1.2;
    
    COLOR = result;
}

