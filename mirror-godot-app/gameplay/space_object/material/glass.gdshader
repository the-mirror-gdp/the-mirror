shader_type spatial;
render_mode blend_mix,depth_draw_always,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform float albedo_mix : hint_range(0,1.0) = 1.0;
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_metallic : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform sampler2D texture_roughness : hint_roughness_r,filter_linear_mipmap,repeat_enable;
uniform float specular;
uniform float metallic;
uniform sampler2D texture_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform float normal_scale : hint_range(-16,16) = 1.0;
uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset;
uniform float refraction : hint_range(-16,16) = 0.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D depth_texture : source_color, hint_depth_texture, filter_nearest;

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}


void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * mix(vec3(1.0),albedo_tex.rgb, albedo_mix);
	float metallic_tex = texture(texture_metallic,base_uv).r;
	METALLIC = metallic_tex * metallic;
	float roughness_tex = texture(texture_roughness,base_uv).r;
	ROUGHNESS = clamp(roughness_tex * roughness, 0.0, 1.0);
	SPECULAR = specular;
	NORMAL_MAP = texture(texture_normal,base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;

	if(refraction > 0.001){
		vec3 ref_normal = NORMAL;
		vec2 ref_ofs = SCREEN_UV - ref_normal.xy * refraction;
		float depth = texture(depth_texture, ref_ofs).x;
  		vec3 ndc = vec3(ref_ofs * 2.0 - 1.0, depth);
		vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
		view.xyz /= view.w;
		float linear_depth = -view.z;
		ref_ofs = mix(ref_ofs, SCREEN_UV, float(linear_depth <= -VERTEX.z));
		float ref_amount = 1.0 - albedo.a * albedo_tex.a;
		EMISSION += textureLod(screen_texture, ref_ofs,ROUGHNESS * 8.0).rgb * ref_amount * EXPOSURE;
		ALBEDO *= 1.0 - ref_amount;
		ALPHA = 1.0;
	} else {
		ALPHA = albedo.a * albedo_tex.a;
	}
}
