shader_type canvas_item;
render_mode blend_mix;

// Jagged branching lightning bolt shader for Tesla Coil
// Creates procedural zigzag lightning with forks and electric glow

uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);  // White-hot core
uniform vec4 glow_color : source_color = vec4(0.3, 0.7, 1.0, 1.0);  // Electric blue glow
uniform vec4 outer_color : source_color = vec4(0.1, 0.3, 0.8, 0.5); // Faint outer glow

uniform float bolt_thickness : hint_range(0.01, 0.2) = 0.06;  // Main bolt width
uniform float glow_size : hint_range(0.0, 0.5) = 0.15;  // Glow around bolt
uniform float jaggedness : hint_range(0.0, 0.3) = 0.12;  // How much bolt zigzags
uniform float segment_count : hint_range(4.0, 20.0) = 10.0;  // Number of zigzag segments
uniform float fork_chance : hint_range(0.0, 1.0) = 0.3;  // Chance of fork at each segment
uniform float fork_length : hint_range(0.1, 0.5) = 0.25;  // Length of fork branches
uniform float flicker_speed : hint_range(0.0, 50.0) = 25.0;  // Animation speed
uniform float intensity : hint_range(0.5, 3.0) = 1.5;  // Overall brightness

// Hash function for pseudo-random values
float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Get jagged offset for a segment
float get_jag_offset(float segment_id, float time_seed) {
    float h = hash(segment_id * 17.3 + time_seed);
    return (h - 0.5) * 2.0 * jaggedness;
}

// Calculate distance to a line segment
float dist_to_segment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * t);
}

void fragment() {
    vec2 uv = UV;
    
    // Time-based seed for animation (changes every frame for flicker)
    float time_seed = floor(TIME * flicker_speed);
    float flicker = 0.7 + 0.3 * hash(time_seed * 0.1);
    
    // Build the lightning path as connected segments
    float min_dist = 1.0;
    float fork_contribution = 0.0;
    
    // Main bolt path
    vec2 prev_point = vec2(0.0, 0.5);  // Start at left center
    
    for (float i = 1.0; i <= segment_count; i += 1.0) {
        float t = i / segment_count;
        
        // Base point along the bolt (left to right)
        vec2 base_point = vec2(t, 0.5);
        
        // Add jagged offset (perpendicular to bolt direction)
        float jag = get_jag_offset(i, time_seed);
        vec2 current_point = base_point + vec2(0.0, jag);
        
        // Clamp to valid UV range
        current_point.y = clamp(current_point.y, 0.05, 0.95);
        
        // Distance to this segment
        float d = dist_to_segment(uv, prev_point, current_point);
        min_dist = min(min_dist, d);
        
        // Check for fork at this segment
        float fork_seed = hash(i * 31.7 + time_seed);
        if (fork_seed < fork_chance && i > 1.0 && i < segment_count - 1.0) {
            // Create a fork branch
            float fork_angle = (hash(i * 47.3 + time_seed) - 0.5) * 2.0;  // Random angle
            vec2 fork_dir = normalize(vec2(1.0, fork_angle * 2.0));
            vec2 fork_end = current_point + fork_dir * fork_length;
            fork_end = clamp(fork_end, vec2(0.0), vec2(1.0));
            
            // Add small jags to fork
            vec2 fork_mid = (current_point + fork_end) * 0.5;
            fork_mid.y += get_jag_offset(i + 100.0, time_seed) * 0.5;
            
            float fork_d1 = dist_to_segment(uv, current_point, fork_mid);
            float fork_d2 = dist_to_segment(uv, fork_mid, fork_end);
            float fork_d = min(fork_d1, fork_d2);
            
            // Forks are thinner
            fork_contribution = max(fork_contribution, 1.0 - smoothstep(0.0, bolt_thickness * 0.6, fork_d));
        }
        
        prev_point = current_point;
    }
    
    // Calculate bolt intensity layers
    float core = 1.0 - smoothstep(0.0, bolt_thickness * 0.4, min_dist);
    float main_bolt = 1.0 - smoothstep(0.0, bolt_thickness, min_dist);
    float glow = 1.0 - smoothstep(0.0, glow_size, min_dist);
    float outer = 1.0 - smoothstep(0.0, glow_size * 2.0, min_dist);
    
    // Combine layers
    vec4 result = vec4(0.0);
    
    // Outer glow
    result += outer_color * outer * 0.3;
    
    // Main glow
    result += glow_color * glow * 0.6;
    
    // Main bolt body
    result += glow_color * main_bolt * 0.8;
    
    // White-hot core
    result += core_color * core;
    
    // Add fork contribution (slightly dimmer)
    float fork_glow = fork_contribution * 0.7;
    result += glow_color * fork_glow * 0.5;
    result += core_color * fork_contribution * 0.6;
    
    // Apply flicker and intensity
    result.rgb *= flicker * intensity;
    
    // Alpha based on visibility - ensure we have visible alpha
    float alpha = max(max(glow, fork_contribution * 0.7), outer * 0.5);
    result.a = alpha;
    
    // Make sure we have some minimum visibility for the lightning
    if (alpha > 0.01) {
        result.rgb = max(result.rgb, glow_color.rgb * alpha * 0.3);
    }
    
    // Clamp final result
    result = clamp(result, vec4(0.0), vec4(3.0, 3.0, 3.0, 1.0));
    
    COLOR = result;
}

