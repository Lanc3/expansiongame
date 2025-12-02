shader_type canvas_item;

uniform vec4 shield_color : source_color = vec4(0.0, 0.8, 1.0, 0.4);
uniform float intensity : hint_range(0.0, 1.0) = 1.0;
uniform vec2 hit_position = vec2(0.5, 0.5); // Normalized UV coordinates of hit (0.0 to 1.0)
uniform float hit_strength : hint_range(0.0, 1.0) = 0.0;
uniform float ripple_speed : hint_range(0.1, 10.0) = 3.0;
uniform float wobble_frequency : hint_range(1.0, 20.0) = 10.0;
uniform float wobble_amplitude : hint_range(0.0, 0.1) = 0.02;

// Pseudo-random noise function
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Simple noise based on value noise
float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    vec2 to_pixel = UV - center;
    float angle = atan(to_pixel.y, to_pixel.x);
    float dist = length(to_pixel);
    
    // Wobble / Displacement Logic
    // We displace the distance field locally at the hit angle
    float displacement = 0.0;
    
    if (hit_strength > 0.0) {
        vec2 to_hit = hit_position - center;
        float hit_angle = atan(to_hit.y, to_hit.x);
        
        // Calculate angular distance (shortest path around circle)
        float angle_diff = angle - hit_angle;
        // Normalize to -PI to PI
        if (angle_diff > 3.14159) angle_diff -= 6.28318;
        if (angle_diff < -3.14159) angle_diff += 6.28318;
        
        // Localized wobble effect based on angle closeness to hit
        // Gaussian-like falloff for the wobble area
        float angle_mask = exp(-2.0 * angle_diff * angle_diff);
        
        // Sine wave wobble over time
        float wave = sin(TIME * 20.0) * hit_strength * wobble_amplitude;
        displacement = wave * angle_mask;
        
        // Also add radial ripple moving outwards from impact site
        // This is visual color ripple, effectively handled below, but let's distort UVs slightly too?
        // For now, let's stick to boundary deformation.
    }
    
    // Apply displacement to distance (makes boundary wobble)
    // Subtracting displacement effectively "pulls" the boundary out or pushes it in
    float distorted_dist = dist - displacement;
    
    // Masking to fix square box artifact
    // Hard cutoff at 0.5 (radius) but using distorted_dist to include wobble
    // 0.48 to leave room for soft edge within 0.5 box
    float radius = 0.48; 
    
    // Main shield body
    // Soft edge at the boundary
    float alpha = 1.0 - smoothstep(radius - 0.02, radius, distorted_dist);
    
    // Inner Energy Field (Animated Noise)
    float energy = noise(UV * 8.0 + vec2(TIME * 0.5, TIME * 0.2));
    energy = energy * 0.3 + 0.7; // Normalize roughly
    
    // Impact Ripple (Visual Brightness)
    float ripple = 0.0;
    if (hit_strength > 0.0) {
        float d_hit = distance(UV, hit_position);
        // Ring expanding from hit position
        float wave_phase = fract(TIME * ripple_speed); // 0 to 1 loops
        // Map phase to distance? No, just let time run.
        // Let's make a ring that expands
        float ring_dist = 0.0; // We want ring to start at hit and go out.
        
        // Simple ripple: sine wave based on distance from hit
        // Decays with distance from hit
        float wave = sin(d_hit * 30.0 - TIME * 15.0);
        float mask = smoothstep(0.4, 0.0, d_hit); // Restrict ripple to area around hit
        ripple = max(0.0, wave) * mask * hit_strength * 2.0;
    }
    
    // Rim Light / Edge Glow (Inner)
    // Brighten near the edge of the shield
    float rim = smoothstep(radius - 0.1, radius, distorted_dist);
    
    // Combine
    vec4 color = shield_color;
    
    // Apply energy texture to alpha and color
    color.a *= alpha * intensity * (0.8 + 0.2 * energy);
    
    // Add rim glow
    color.rgb += vec3(rim * 0.5);
    color.a += rim * 0.4 * alpha; // Boost alpha at rim, but strictly masked by alpha
    
    // Add ripple brightness
    color.rgb += vec3(ripple);
    color.a += ripple * 0.5; // Make ripples more opaque
    
    // Hard clamp to ensure no square box (alpha = 0 if outside radius)
    // Smoothstep already handles this mostly (returns 1 for > edge), so 1.0 - 1.0 = 0.0
    // But just to be sure, we multiply by a hard step if needed, but smoothstep 0.48->0.5 effectively hits 0.
    // However, let's ensure we don't draw outside 0.5 UV distance to avoid clipping corner artifacts if rect is tight
    if (dist > 0.5) {
        color.a = 0.0;
    }
    
    COLOR = color;
}
