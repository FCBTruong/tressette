shader_type canvas_item;
render_mode world_vertex_coords;

uniform float outline_width;
uniform vec2 lower_limit;
uniform vec2 upper_limit;

uniform vec4 color : source_color;

void vertex() {
	vec2 disp;

	// resizes the
	switch (VERTEX_ID)
	{
		case 0:
			disp = vec2(lower_limit.x, lower_limit.y);
			break;
		case 1:
			disp = vec2(lower_limit.x, upper_limit.y);
			break;
		case 2:
			disp = vec2(upper_limit.x, upper_limit.y);
			break;
		case 3:
			disp = vec2(upper_limit.x, lower_limit.y);
			break;
	}

	VERTEX = disp;
}

void fragment() {
	float alpha;

	// use sdf to calculate the alpha of the highlight
	alpha = 1.0 - texture_sdf(screen_uv_to_sdf(SCREEN_UV)) / float(outline_width);
	COLOR = color;
	COLOR.a = alpha;
}