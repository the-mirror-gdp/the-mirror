shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;

uniform vec4 color : source_color = vec4( 1.0, 1.0, 1.0, 1.0 );
uniform float scale = 1.0;
uniform float grid_size = 0.5;
uniform float line_thickness = 0.05;

void fragment()
{
	vec2 grid_uv = fract(UV / (grid_size / scale));
	float half_line_thickness = line_thickness * 0.5 / grid_size;

	float grid_mask = step(grid_uv.x, half_line_thickness) + step(1.0 - half_line_thickness, grid_uv.x);
	grid_mask += step(grid_uv.y, half_line_thickness) + step(1.0 - half_line_thickness, grid_uv.y);

	if(grid_mask < 1.0 || UV.x <= line_thickness || UV.x >= 1.0 - line_thickness || UV.y <= line_thickness || UV.y >= 1.0 - line_thickness)
	{
		discard;
	}

	ALBEDO = color.rgb;
	ALPHA = color.a;
}
