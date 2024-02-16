// NOTE: Shader automatically converted from Godot Engine 4.1.dev's StandardMaterial3D.

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

uniform sampler2D texture_heightmap : hint_default_black,filter_linear_mipmap,repeat_enable;
uniform float heightmap_scale = 0.5;
uniform int heightmap_min_layers = 16;
uniform int heightmap_max_layers = 48;
uniform float min_depth = 0.0;
uniform float max_depth = 1.0;

const float PROXIMITY_FADE_DISTANCE = 0.3;

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}

float get_depth(float depth)
{
	return mix(min_depth, max_depth, depth);
}

float sample_depth(sampler2D depth_texture, vec2 uv, vec4 dd)
{
	return 1.0 - textureGrad(depth_texture, uv, dd.xy, dd.zw).r;
}

float sample_depth_value(sampler2D depth_texture, vec2 uv, vec4 dd,float depth)
{
	return sample_depth(depth_texture, uv, dd) * get_depth(depth);
}

vec2 raytrace_loop_uv(in vec4 dd, in float layerN, in sampler2D depth_texture, in float depth, in vec2 current_uv, in vec2 delta_uv, inout float current_depth, inout float current_layer_depth, in float layer_depth)
{
	for (float j = 0.0; j < layerN; j++)
	{
		//if we're beneath the surface, exit the loop
		if (current_layer_depth >= current_depth)
		{
			break;
		}

		//update current_uv
		current_uv -= delta_uv;
		//resample height map
		current_depth = sample_depth_value(depth_texture, current_uv, dd, depth);
		//update current_layer_depth
		current_layer_depth += layer_depth;
	}

	return current_uv;
}

float hash_2d(vec2 p) {
	return fract(1.0e4 * sin(17.0 * p.x + 0.1 * p.y) *
			(0.1 + abs(sin(13.0 * p.y + p.x))));
}

float hash_3d(vec3 p) {
	return hash_2d(vec2(hash_2d(p.xy), p.z));
}

void fragment() {
	vec2 base_uv = UV;
	float current_depth = 0.0;
	float start_depth = 0.0;
	vec4 dd = vec4(dFdx(base_uv), dFdy(base_uv));
	vec3 view_dir = normalize(normalize(-VERTEX)*mat3(TANGENT,-BINORMAL,NORMAL));
	{
		float num_layers = mix(float(heightmap_max_layers),float(heightmap_min_layers), abs(dot(vec3(0.0, 0.0, 1.0), view_dir)));
		float layer_depth = 1.0 / num_layers;
		float current_layer_depth = 0.0;
		float depth = heightmap_scale;
		vec2 P = view_dir.xy * get_depth(depth);
		//vec2 delta = P / num_layers;
		vec2 delta = P/ (256.0);

		vec2 current_uv = base_uv;

		current_depth = sample_depth(texture_heightmap, current_uv, dd);
		start_depth = current_depth * get_depth(depth);
		//get parallax-offsetted uv (see raytrace_uv_loop function before for more details)
		current_uv = raytrace_loop_uv(dd, num_layers, texture_heightmap, depth, current_uv, delta, current_depth, current_layer_depth, layer_depth);

		//if (contact_refinement) {
			current_uv += delta;

			current_depth = sample_depth(texture_heightmap, current_uv, dd);
			//adjust the precision of delta_uv and layer_depth
			delta /= num_layers;
			layer_depth /= num_layers;
			//get contact num_layers uv by raytrace again with better precision
			current_uv = raytrace_loop_uv(dd, num_layers, texture_heightmap, depth, current_uv, delta, current_depth, current_layer_depth, layer_depth);
		//}
		base_uv=current_uv;
	}
		vec4 albedo_tex = texture(texture_albedo,base_uv);
		ALBEDO = albedo.rgb * mix(vec3(1.0),albedo_tex.rgb, albedo_mix);
		float metallic_tex = texture(texture_metallic,base_uv).r;
		METALLIC = metallic_tex * metallic;
		float roughness_tex = texture(texture_roughness,base_uv).r;
		ROUGHNESS = clamp(roughness_tex * roughness, 0.0, 1.0);
		NORMAL_MAP = texture(texture_normal,base_uv).rgb;
		NORMAL_MAP_DEPTH = normal_scale;
		SPECULAR = specular;
}
