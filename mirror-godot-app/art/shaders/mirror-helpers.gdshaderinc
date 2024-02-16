global uniform sampler2D world_heightmap_01: hint_default_black, filter_linear, repeat_disable;
global uniform sampler2D world_colormap_01: source_color,hint_default_black, filter_linear;

global uniform float world_map_max_height_01;
global uniform vec2 world_map_size_01;
global uniform float world_map_max_height_offset_01;

float sample_heightmap(vec2 position_xz_world_space) {
	vec2 uv = clamp(position_xz_world_space/world_map_size_01 + 0.5, vec2(0.0), vec2(1.0));
	uv += vec2(0.5/world_map_size_01);
	return world_map_max_height_01 * textureLod(world_heightmap_01, uv, 0).r + world_map_max_height_offset_01;
}

vec4 sample_colormap(vec2 position_xz_world_space) {
	vec2 uv = clamp(position_xz_world_space/world_map_size_01 + 0.5, vec2(0.0), vec2(1.0));
	uv += vec2(0.5/world_map_size_01);
	return textureLod(world_colormap_01, uv, 0);
}

vec3 rgb2hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	c = vec3(c.x, clamp(c.yz, 0.0, 1.0));
	vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
	return c.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), c.y);
}

vec3 hsv_offset(in vec3 color, float hue, float saturation, float value) {
	vec3 hsv = rgb2hsv(color);
	hsv += vec3(hue, saturation, value);
	return hsv2rgb(hsv);
}
