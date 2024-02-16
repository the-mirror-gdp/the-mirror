shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx,unshaded,shadows_disabled,ambient_light_disabled;
uniform vec4 albedo : source_color;
uniform float max_alpha : hint_range(0.0,1.0) = 1.0;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform float distance_scale_factor = 16.0;
uniform float aabb_mean_center_distance = 0.0;
uniform float grow = 1.0;

varying vec3 uv1_triplanar_pos;
varying float blend_factor;
varying vec3 world_norm;
varying float scale_distance;

void vertex() {
	vec3 world_camera  = (INV_VIEW_MATRIX * vec4(vec3(0.0), 1.0)).xyz;
	vec3 world_position = (MODEL_MATRIX * vec4(vec3(0.0), 1.0)).xyz;
	float distance_to_object = distance(world_camera, world_position) - aabb_mean_center_distance;
	scale_distance = max(log(distance_to_object)/distance_scale_factor, 1.0);
	blend_factor = smoothstep(0.0,0.5,fract(scale_distance ));
	scale_distance = floor(scale_distance);
	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	VERTEX *= grow;
	world_norm = abs(NORMAL);
	scale_distance = min(scale_distance, log2(aabb_mean_center_distance * 2.0 )*2.0);
}

vec3 saturate(vec3 val){
	return clamp(val, 0.0,1.0);
}

float grid(vec3 triplanar_pos, float thickness, vec3 w_norml, float scale) {
	vec3 moduloWorldCoordinates = mod(triplanar_pos, pow(2.0, scale)) - pow(2.0, scale)/2.0;
	moduloWorldCoordinates =  abs(moduloWorldCoordinates);
	vec3 steppedWorldCoordinates = 1.0 - saturate((moduloWorldCoordinates  - thickness) / fwidth(triplanar_pos * 2.0) + 0.5);
	steppedWorldCoordinates -= steppedWorldCoordinates * w_norml;
	return clamp(steppedWorldCoordinates.x + steppedWorldCoordinates.y + steppedWorldCoordinates.z, 0.0, 1.0);
}

void fragment() {
	float wireframeThickness = 0.01;
	float grid_far = grid(uv1_triplanar_pos, wireframeThickness, world_norm, scale_distance);
	float grid_close = grid(uv1_triplanar_pos, wireframeThickness, world_norm, scale_distance - 1.0);

	float grid_blend = mix(grid_close, grid_far, blend_factor);
	ALPHA = grid_blend * max_alpha;
	ALBEDO = albedo.rgb;
}
