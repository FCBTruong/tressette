shader_type canvas_item;

uniform vec2 ripple_origin = vec2(0.0, 0.0);
uniform float ripple_radius : hint_range(0.0, 1.0) = 0.0;
uniform float ripple_width : hint_range(0.01, 0.1) = 0.05;
uniform vec4 ripple_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 base_color : source_color = vec4(1.0,1.0,1.0,1.0);
uniform vec2 uv_scale = vec2 (1.0,0.5);

void fragment() {
    vec2 uv = UV * uv_scale - ripple_origin;
    float dist = length(uv);

    float ripple = smoothstep(ripple_radius, ripple_radius - ripple_width, dist) *
                   smoothstep(ripple_radius + ripple_width, ripple_radius, dist);

	float center_blend = smoothstep(0.0, ripple_radius - ripple_width, dist);

    COLOR = mix(base_color, mix(base_color, ripple_color, ripple), center_blend);
}
