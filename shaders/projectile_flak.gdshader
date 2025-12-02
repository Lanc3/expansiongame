shader_type canvas_item;

// Flak cannon tracer - yellow-hot glowing elongated ellipse
// Thin, long, small tracer with hot core and orange glow falloff
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 0.9, 1.0);  // White-hot center
uniform vec4 hot_color : source_color = vec4(1.0, 0.9, 0.3, 1.0);   // Yellow-hot
uniform vec4 glow_color : source_color = vec4(1.0, 0.5, 0.1, 1.0);  // Orange glow
uniform float elongation : hint_range(1.0, 10.0) = 4.0;  // How stretched the ellipse is
uniform float core_size : hint_range(0.01, 0.2) = 0.08;  // Bright core width
uniform float glow_falloff : hint_range(0.1, 1.0) = 0.4;  // Outer glow size
uniform float shimmer_speed : hint_range(0.0, 30.0) = 15.0;  // Heat shimmer

void fragment() {
    vec2 uv = UV - 0.5;
    
    // Elongate along Y axis (projectile travels in Y direction)
    vec2 stretched_uv = vec2(uv.x, uv.y / elongation);
    
    // Distance from center (elliptical)
    float dist = length(stretched_uv);
    
    // Heat shimmer effect - subtle wobble
    float shimmer = sin(uv.y * 20.0 + TIME * shimmer_speed) * 0.02;
    dist += shimmer * (1.0 - smoothstep(0.0, 0.3, dist));
    
    // Core - bright white-hot center
    float core = 1.0 - smoothstep(0.0, core_size, dist);
    
    // Hot layer - yellow surrounding core
    float hot = 1.0 - smoothstep(core_size * 0.5, core_size * 2.0, dist);
    
    // Outer glow - orange falloff
    float glow = 1.0 - smoothstep(core_size, glow_falloff, dist);
    
    // Intensity falloff toward the back (tail of tracer)
    float tail_fade = smoothstep(-0.5, 0.2, uv.y);  // Brighter at front
    
    // Speed streaks for motion effect
    float streak = sin(uv.y * 40.0 + TIME * shimmer_speed * 2.0) * 0.5 + 0.5;
    streak = pow(streak, 4.0) * glow * 0.3;
    
    // Combine layers
    vec4 result = vec4(0.0);
    result += core_color * core * tail_fade;
    result += hot_color * hot * (1.0 - core) * tail_fade;
    result += glow_color * glow * (1.0 - hot) * tail_fade * 0.7;
    result += hot_color * streak;
    
    // Alpha based on glow with minimum for visibility
    result.a = glow * tail_fade;
    
    // Boost brightness for that "hot metal" look
    result.rgb *= 1.5;
    
    COLOR = result;
}

