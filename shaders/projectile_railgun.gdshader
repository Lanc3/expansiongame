shader_type canvas_item;

// Railgun high-velocity streak shader
uniform vec4 trail_color : source_color = vec4(0.3, 0.5, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float trail_length : hint_range(0.0, 1.0) = 0.8;
uniform float core_width : hint_range(0.0, 0.2) = 0.05;
uniform float streak_speed : hint_range(0.0, 50.0) = 30.0;

void fragment() {
    vec2 uv = UV;
    
    // Core - bright white center line
    float dist_from_center = abs(uv.x - 0.5);
    float core = 1.0 - smoothstep(0.0, core_width, dist_from_center);
    
    // Motion blur / speed streak
    float streak_width = core_width + (1.0 - uv.y) * 0.15;  // Wider at back
    float streak = 1.0 - smoothstep(0.0, streak_width, dist_from_center);
    
    // Fade trail toward back
    float trail_fade = pow(uv.y, 0.5);  // Stronger at front
    
    // Speed lines effect
    float speed_lines = sin(uv.y * 50.0 + TIME * streak_speed) * 0.5 + 0.5;
    speed_lines = step(0.9, speed_lines) * streak * (1.0 - uv.y);
    
    // Electric discharge around core
    float discharge = sin((uv.x - 0.5) * 100.0 + uv.y * 20.0 + TIME * 20.0);
    discharge = step(0.95, discharge) * streak * 0.5;
    
    // Combine
    vec4 result = vec4(0.0);
    result += core_color * core * trail_fade;
    result += trail_color * streak * trail_fade * 0.7;
    result += core_color * speed_lines;
    result += trail_color * discharge;
    
    result.a = streak * trail_fade;
    
    COLOR = result;
}

