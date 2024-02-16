shader_type spatial;

uniform vec4 col1 = vec4(0.75, 0.0, 0.0, 1.0);
uniform vec4 col2 = vec4(0.5, 0.0, 0.0, 1.0);

void fragment() {
	ALBEDO = mix(col1, col2, sin(TIME * 10.0) * 0.5 + 0.5).rgb;
}
