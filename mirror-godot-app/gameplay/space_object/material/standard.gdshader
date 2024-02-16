shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float albedo_mix : hint_range(0,1.0) = 1.0;
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_metallic : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform sampler2D texture_roughness : hint_roughness_r,filter_linear_mipmap,repeat_enable;
uniform float specular;
uniform float metallic;
uniform sampler2D texture_normal : hint_roughness_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float normal_scale : hint_range(-16,16) = 1.0;
uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset;
uniform bool triplanar;

varying vec3 v_triplanar_pos;
varying vec3 v_world_normal;


vec3 unpack_normalmap(vec3 normal_map, float strength) {
	normal_map.xy = clamp((normal_map.xy * 2.0 - 1.0) * strength, vec2(-1.0), vec2(1.0));
	normal_map.z = sqrt(max(0.0, 1.0 - dot(normal_map.xy, normal_map.xy)));
	//reorient y axis, this basically creates normal map in DX coords
	return vec3(normal_map.x, -normal_map.y, normal_map.z);
}

// Conditional Triplanar - ugly but we are trying to improve perf by skipping texture samples
// https://ryandowlingsoka.com/Triplanar-Dithered-Triplanar-and-Biplanar-Mapping-in-Unreal-7844313e458e4316aca1e40e6394109e
vec4 triplanar_amr(sampler2D p_sampler_albedo, sampler2D p_sampler_metallic, sampler2D p_sampler_roughness, vec3 p_weights, vec3 p_triplanar_pos,
	out float metallic_out, out float roughness_out
) {
	vec4 samp_albedo = vec4(0.0);
	//if(p_weights.z > 0.0) {
		samp_albedo += texture(p_sampler_albedo,p_triplanar_pos.xy) * p_weights.z;
		metallic_out += texture(p_sampler_metallic, p_triplanar_pos.xy).b * p_weights.z;
		roughness_out += texture(p_sampler_roughness,p_triplanar_pos.xy).g * p_weights.z;
	//}
	//if(p_weights.x > 0.0) {
		samp_albedo += texture(p_sampler_albedo,p_triplanar_pos.zy) * p_weights.x;
		metallic_out += texture(p_sampler_metallic,p_triplanar_pos.zy).b * p_weights.x;
		roughness_out += texture(p_sampler_roughness,p_triplanar_pos.zy).g * p_weights.x;
	//}
	//if(p_weights.y > 0.0) {
		samp_albedo += texture(p_sampler_albedo,p_triplanar_pos.xz) * p_weights.y;
		metallic_out += texture(p_sampler_metallic,p_triplanar_pos.xz).b * p_weights.y;
		roughness_out += texture(p_sampler_roughness,p_triplanar_pos.xz).g * p_weights.y;
	//}

	return samp_albedo;
}

// Conditional Triplanar  Normalmap with UDN reorienting - ugly but we are trying to improve perf by skipping texture samples
// https://ryandowlingsoka.com/Triplanar-Dithered-Triplanar-and-Biplanar-Mapping-in-Unreal-7844313e458e4316aca1e40e6394109e
vec3 triplanar_normal(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos,
						 float strength, vec3 p_world_normal
) {
	vec3 tex_sample = vec3(0.0);
	vec3 normal_y = vec3(0.0);
	vec3 normal_x = vec3(0.0);
	vec3 normal_z = vec3(0.0);

	//if(p_weights.x > 0.0) {
		tex_sample = texture(p_sampler, p_triplanar_pos.zy).xyz;
		normal_x = unpack_normalmap(tex_sample, strength);
		//perform UDN
		normal_x = vec3(normal_x.xy + p_world_normal.zy, p_world_normal.x);
	//}
	//if(p_weights.y > 0.0) {
		tex_sample = texture(p_sampler, p_triplanar_pos.xz).xyz;
		normal_y = unpack_normalmap(tex_sample, strength);
		normal_y = vec3(normal_y.xy + p_world_normal.xz, p_world_normal.y);
	//}
	//if(p_weights.z > 0.0) {
		tex_sample = texture(p_sampler, p_triplanar_pos.xy).xyz;
		normal_z = unpack_normalmap(tex_sample, strength);
		normal_z = vec3(normal_z.xy + p_world_normal.xy, p_world_normal.z);
	//}

	//swizzle to match world orientation and blend
	return normalize(
		normal_x.zyx * p_weights.x +
		normal_y.xzy * p_weights.y +
		normal_z.xyz * p_weights.z
	);
}

// Two functions to calcuate blending weights with noise based sharp transition
// based on https://bgolus.medium.com/normal-mapping-for-a-triplanar-shader-10bf39dca05a#38e5
vec3 calcuate_triplanar_blend(vec3 world_normal, float blend_weight_offset) {
	vec3 blend = vec3(0);
	// Asymmetric Triplanar Blendfloat3 blend = 0;// Blend for sides only
	vec2 xzBlend = abs(normalize(world_normal.xz));
	blend.xz = max(vec2(0.0), xzBlend - 0.67);
	blend.xz /= max(0.00001, dot(blend.xz, vec2(1)));
	blend.y = clamp((abs(world_normal.y + blend_weight_offset) - 0.675) * 80.0, 0.0, 1.0);
	blend.xz *= (1.0 - blend.y);
	return blend;
}

void vertex() {
	v_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * uv1_scale + uv1_offset;
	v_world_normal = MODEL_NORMAL_MATRIX * NORMAL;
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}

void fragment() {
	if(triplanar) {
		vec3 blend = calcuate_triplanar_blend(v_world_normal, 0.0);
		float metallic_trip =0.0, roughness_trip = 0.0;
		vec4 albedo_trip = triplanar_amr(texture_albedo, texture_metallic, texture_roughness,
										blend, v_triplanar_pos, metallic_trip, roughness_trip);
		ALBEDO = albedo.rgb * mix(vec3(1.0), albedo_trip.rgb, albedo_mix);
		METALLIC = metallic_trip * metallic;
		ROUGHNESS = clamp(roughness_trip * roughness, 0.0, 1.0);
		vec3 normal_ws = triplanar_normal(texture_normal,blend, v_triplanar_pos, normal_scale,
										 v_world_normal);
		NORMAL = (VIEW_MATRIX * vec4(normal_ws, 0.0)).xyz;
	} else {
		vec2 base_uv = UV;
		vec4 albedo_tex = texture(texture_albedo,base_uv);
		ALBEDO = albedo.rgb * mix(vec3(1.0),albedo_tex.rgb, albedo_mix);
		float metallic_tex = texture(texture_metallic,base_uv).b;
		METALLIC = metallic_tex * metallic;
		float roughness_tex = texture(texture_roughness,base_uv).g;
		ROUGHNESS = clamp(roughness_tex * roughness, 0.0, 1.0);
		NORMAL_MAP = texture(texture_normal,base_uv).rgb;
		NORMAL_MAP_DEPTH = normal_scale;
	}

	SPECULAR = specular;
}
