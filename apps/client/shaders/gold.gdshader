shader_type canvas_item;

// --- Uniforms --- //
uniform float influence: hint_range(0.0, 1.0, 0.1) = 0.8;
uniform float offset: hint_range(0.0, 360.0, 1.0);
uniform float brightness: hint_range(0.5, 2.0, 0.1) = 1.2;
uniform float contrast: hint_range(0.5, 2.0, 0.1) = 1.5;
uniform float noise_intensity: hint_range(0.0, 1.0, 0.1) = 0.2;

const float TWO_PI = 6.28318530718;

// --- Functions --- //
vec3 hsv2rgb(vec3 _c) {
    vec4 _K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 _p = abs(fract(_c.xxx + _K.xyz) * 6.0 - _K.www);
    return _c.z * mix(_K.xxx, clamp(_p - _K.xxx, 0.0, 1.0), _c.y);
}

// Simple noise function for subtle texture
float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 pos = vec2(0.5) - UV;
    float angle = atan(pos.y, pos.x) + radians(offset);
    float dist = length(pos) * 2.0;

    // Base gold color using HSV
    vec3 gold_color = hsv2rgb(vec3(0.1, 0.8, 1.0)); // Hue for gold

    // Metallic effect with contrast and brightness
    gold_color = pow(gold_color * brightness, vec3(contrast));

    // Adding radial variation
    float radial_factor = sin(angle * 5.0) * 0.1;
    gold_color += radial_factor;

    // Add subtle noise
    float noise = rand(UV * 100.0) * noise_intensity;
    gold_color += vec3(noise);

    // Check if the existing color is white
    float is_white = step(0.99, dot(COLOR.rgb, vec3(1.0)) / 3.0); // Detects if it's close to white

    // Apply gold only to white areas
    COLOR.rgb = mix(COLOR.rgb, gold_color, is_white * influence);
}
