shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

void fragment() {
    vec4 color = vec4(0.0);
    vec2 texel_size = vec2(1.0) / vec2(textureSize(SCREEN_TEXTURE, 0));

    // Sample multiple times around the pixel for a blur effect
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(float(x), float(y)) * texel_size * blur_amount);
        }
    }

    color /= 25.0; // Normalize
    COLOR = color;
}
