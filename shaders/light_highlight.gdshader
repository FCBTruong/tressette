shader_type canvas_item;

uniform sampler2D vertical_gradient;
uniform sampler2D color_gradient;
uniform float size_effect: hint_range(-5.0, 5.0, 0.05) = 0.1;
uniform float speed = 1.0;
uniform float highlight_strength: hint_range(-4.0, 4.0, 0.05) = 0.5;
uniform bool color_mode_toggle = false;
uniform bool is_horizontal = false;
uniform float delay = 0.5; // New delay parameter between effect cycles

void fragment() {
    // Set up base parameters
    vec4 old_color = COLOR;
    float time = TIME * speed;

    // Adjust time to include delay between cycles
    float cycle_duration = 1.0 + delay;
    float cycle_time = mod(time, cycle_duration);

    // If within the delay period, freeze the effect
    float current_time = (cycle_time <= 1.0) ? cycle_time : 1.0;

    // Adjust the effect bounds
    current_time = mix(0.0 - size_effect, 1.0 + size_effect, current_time);
    float effect_lower_bound = current_time - size_effect;
    float effect_upper_bound = current_time + size_effect;
    float position_value = (is_horizontal) ? UV.x : UV.y;

    // Smooth the effect transition
    float effect_distance = smoothstep(effect_lower_bound, current_time, position_value)
                          - smoothstep(current_time, effect_upper_bound, position_value);

    // Calculate position for the inner gradient
    float inner_effect_position = smoothstep(effect_lower_bound, effect_upper_bound, position_value);
    vec2 color_position = (color_mode_toggle) ? vec2(UV.x, inner_effect_position) : vec2(current_time);

    // Get the new color from the gradient
    vec4 new_color = vec4(texture(color_gradient, color_position));

    // Calculate vertical gradient alpha values
    new_color = mix(old_color, new_color, vec4(texture(vertical_gradient, vec2(current_time))));

    // Apply the effect to the texture
    COLOR.rgb = mix(old_color.rgb, new_color.rgb, vec3(effect_distance * highlight_strength));
}
