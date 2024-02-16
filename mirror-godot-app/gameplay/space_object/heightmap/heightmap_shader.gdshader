// NOTE: Shader automatically converted from Godot Engine 4.1.dev's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

//used to swap between standard and without tiling sampling
#define TEXTURE_SPACE_SAMPLER untiled_texture
//#define TEXTURE_SPACE_SAMPLER texture

group_uniforms script_autoupdated;
uniform float scale_z = 1.0;
uniform float map_size = 1081.0;
uniform vec3 map_center_position = vec3(0);
uniform float map_yaw_rotation = 0.0;
uniform sampler2D texture_heightmap : hint_default_black, filter_linear, repeat_disable;
uniform sampler2D texture_global_normalmap : hint_roughness_normal, filter_linear_mipmap, repeat_disable;


group_uniforms global_section;
uniform sampler2D texture_noise : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform sampler3D texture_noise_3d : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform float blend_weight_offset = 0.0;
uniform float triplanar_softness = 4.0;
uniform float triplanar_noise_blend_strenth = 1.0;
uniform float max_bump_strength = 1.0;
uniform sampler2D texture_color_map : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float colormap_strength = 0.5;
uniform bool colormap_present = false;
uniform vec2 offset_normal = vec2(0.0);

group_uniforms materials;
group_uniforms materials.top;
uniform vec4 albedo_top : source_color = vec4(1.0);
uniform sampler2D texture_albedo_top : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D texture_normalmap_top : hint_roughness_normal, filter_linear_mipmap_anisotropic,repeat_enable;
uniform float uv_scale_top = 1.0;
uniform sampler2D texture_roughness_top : hint_default_white, filter_linear_mipmap_anisotropic,repeat_enable;
uniform float normal_strength_top = 1.0;
uniform float roughness_offset_top = 0.0;
uniform float layer_height_top = 0.5;
group_uniforms;
group_uniforms materials.sides;
uniform vec4 albedo_side : source_color = vec4(1.0);
uniform sampler2D texture_albedo_side : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D texture_normalmap_side : hint_roughness_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D texture_roughness_side : hint_default_white, filter_linear_mipmap_anisotropic,repeat_enable;
uniform float uv_scale_side = 1.0;
uniform float normal_strength_side = 1.0;
uniform float layer_height_side = 0.0;
group_uniforms;

const float FLOAT_EPSILON = 0.000001;

varying float v_world_height;
varying vec2 v_world_uv;
varying vec3 v_world_pos;

vec2 rotateUV(vec2 uv, vec2 pivot, float rotation) {
    float cosa = cos(rotation);
    float sina = sin(rotation);
    uv -= pivot;
    return vec2(
        cosa * uv.x - sina * uv.y,
        cosa * uv.y + sina * uv.x
    ) + pivot;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	vec2 world_pos = v_world_pos.xz - map_center_position.xz;
	v_world_uv = (world_pos / map_size) + 0.5;
	v_world_uv = rotateUV(v_world_uv, vec2(0.5), map_yaw_rotation);
	vec2 half_pixel_size = (1.0 / vec2(textureSize(texture_heightmap, 0))) * 0.5;
	v_world_uv = v_world_uv + half_pixel_size;
	float y_value = texture(texture_heightmap, v_world_uv).x;
	//float y_value = sample_heightmap(texture_heightmap, world_pos, map_size);
	if(v_world_uv.x < 0.0 || v_world_uv.y < 0.0 || v_world_uv.x > 1.0 || v_world_uv.y > 1.0) {
		y_value = 0.0;
	}
	VERTEX.y += (y_value)  * scale_z;// - noise_residuals;
	v_world_height = y_value;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
}

// This untiles textures with only two sample lookups
// http://www.iquilezles.org/www/articles/texturerepetition/texturerepetition.htm
float sum( vec4 v ) { return v.x+v.y+v.z; }
vec4 untiled_texture(sampler2D samp, in vec2 uv) {
	 // sample variation pattern
	float k = texture( texture_noise, 0.005 * uv ).x; // cheap (cache friendly) lookup
	// compute index
	float index = k * 8.0;
	float i = floor( index );
	float f = fract( index );
	// offsets for the different virtual patterns
	vec2 offa = sin(vec2(3.0, 7.0) * (i + 0.0)); // can replace with any other hash
	vec2 offb = sin(vec2(3.0, 7.0) * (i + 1.0)); // can replace with any other hash
	// compute derivatives for mip-mapping
	vec2 dx = dFdx(uv);
	vec2 dy = dFdy(uv);
	// sample the two closest virtual patterns
	vec4 cola = textureGrad( samp, uv + offa, dx, dy );
	vec4 colb = textureGrad( samp, uv + offb, dx, dy );
	// interpolate between the two virtual patterns
	return mix( cola, colb, smoothstep(0.2, 0.8, f - 0.1 * sum(cola - colb)) );
}



vec3 unpack_normalmap(vec3 normal_map, float strength) {
	normal_map.xy = clamp((normal_map.xy * 2.0 - 1.0) * strength, vec2(-1.0), vec2(1.0));
	normal_map.z = sqrt(max(0.0, 1.0 - dot(normal_map.xy, normal_map.xy)));
	//reorient y axis, this basically creates normal map in DX coords
	return vec3(normal_map.x, -normal_map.y, normal_map.z);
}

// Two functions to calcuate blending weights with noise based sharp transition
// Roughly based on https://bgolus.medium.com/normal-mapping-for-a-triplanar-shader-10bf39dca05a#38e5
// and Zylann heightmap shader
vec3 calcuate_triplanar_blend(vec3 world_norm, vec3 noise, float noise_blend) {
	// Height Map Triplanar Blend
	vec3 blend = abs(vec3(world_norm.x, world_norm.y * (1.0 + blend_weight_offset), world_norm.z));
	blend /= dot(blend, vec3(1.0));
	vec3 heights = vec3(0.0, noise.y - 0.5, 0.0) + (blend * 3.0); // blend noise only for Y axis
	float height_start = max(max(heights.x, heights.y), heights.z) - noise_blend;
	vec3 h = max(heights - height_start, vec3(0.0));
	blend = h / max(dot(h, vec3(1.0)), FLOAT_EPSILON);
	return blend;
}



// Conditional Triplanar - ugly but we are trying to improve perf by skipping texture samples
// https://ryandowlingsoka.com/Triplanar-Dithered-Triplanar-and-Biplanar-Mapping-in-Unreal-7844313e458e4316aca1e40e6394109e
vec4 triplanar_top_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos,
						   sampler2D p_sampler_top, vec3 p_top_pos, vec3 p_world_normal,
						   vec4 tint, vec4 tint_top
) {
	vec4 samp = vec4(0.0);
	if(p_weights.z > FLOAT_EPSILON) {
		samp += TEXTURE_SPACE_SAMPLER(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	}
	if(p_weights.x > FLOAT_EPSILON) {
		samp += TEXTURE_SPACE_SAMPLER(p_sampler,p_triplanar_pos.zy) * p_weights.x;
	}
	samp *= tint;
	if(p_weights.y > FLOAT_EPSILON) {
		//try catching in conditional only one texture sample
		if(p_world_normal.y >0.0) {
			samp += TEXTURE_SPACE_SAMPLER(p_sampler_top,p_top_pos.xz) * tint_top * p_weights.y;
		} else {
			samp += TEXTURE_SPACE_SAMPLER(p_sampler,p_triplanar_pos.xz) * tint  * p_weights.y;
		}
	}

	return samp;
}

// Conditional Triplanar  Normalmap with UDN reorienting - ugly but we are trying to improve perf by skipping texture samples
// https://ryandowlingsoka.com/Triplanar-Dithered-Triplanar-and-Biplanar-Mapping-in-Unreal-7844313e458e4316aca1e40e6394109e
vec3 triplanar_top_normal(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos,
						  vec3 p_world_normal, float strength,
						  sampler2D p_sampler_top, vec3 p_top_pos, float top_strength,
						  sampler2D p_sampler_roughness_top, sampler2D p_sampler_roughness_side,
						  float p_roughness_offset_top, out float roughness
) {
	vec3 tex_sample = vec3(0.0);
	float tex_r_sample = 1.0;
	vec3 normal_y = vec3(0.0);
	vec3 normal_x = vec3(0.0);
	vec3 normal_z = vec3(0.0);
	roughness = 0.0;

	if(p_weights.x > FLOAT_EPSILON) {
		tex_sample = TEXTURE_SPACE_SAMPLER(p_sampler, p_triplanar_pos.zy).xyz;
		tex_r_sample = TEXTURE_SPACE_SAMPLER(p_sampler_roughness_top, p_triplanar_pos.zy).r;
		roughness += tex_r_sample * p_weights.x;
		normal_x = unpack_normalmap(tex_sample, strength);
		//perform UDN
		normal_x = vec3(normal_x.xy + p_world_normal.zy, p_world_normal.x);
	}

	if(p_weights.y > FLOAT_EPSILON) {
		if(p_world_normal.y >0.0){
			tex_sample = TEXTURE_SPACE_SAMPLER(p_sampler_top, p_top_pos.xz).xyz;
			tex_r_sample = TEXTURE_SPACE_SAMPLER(p_sampler_roughness_top, p_top_pos.xz).r;
			tex_r_sample = clamp(tex_r_sample + p_roughness_offset_top, 0.0, 1.0);
			roughness += tex_r_sample * p_weights.y;
			normal_y = unpack_normalmap(tex_sample, top_strength);
		} else {
			tex_sample = TEXTURE_SPACE_SAMPLER(p_sampler, p_triplanar_pos.xz).xyz;
			tex_r_sample = TEXTURE_SPACE_SAMPLER(p_sampler_roughness_side, p_triplanar_pos.xz).r;
			roughness += tex_r_sample * p_weights.y;
			normal_y = unpack_normalmap(tex_sample, strength);
		}
		normal_y = vec3(normal_y.xy + p_world_normal.xz, p_world_normal.y);
	}
	if(p_weights.z > FLOAT_EPSILON) {
		tex_sample = TEXTURE_SPACE_SAMPLER(p_sampler, p_triplanar_pos.xy).xyz;
		tex_r_sample = TEXTURE_SPACE_SAMPLER(p_sampler_roughness_side, p_triplanar_pos.xy).r;
		roughness += tex_r_sample * p_weights.z;
		normal_z = unpack_normalmap(tex_sample, strength);
		normal_z = vec3(normal_z.xy + p_world_normal.xy, p_world_normal.z);
	}

	//swizzle to match world orientation and blend
	return normalize(
		normal_x.zyx * p_weights.x +
		normal_y.xzy * p_weights.y +
		normal_z.xyz * p_weights.z
	);
}



// Based on Bump Mapping Unparametrized Surfaces on the GPU by Morten S. Mikkelsen
// http://api.unrealengine.com/attachments/Engine/Rendering/LightingAndShadows/BumpMappingWithoutTangentSpace/mm_sfgrad_bump.pdf
// Evaluate the derivative of the height w.r.t. screen-space using forward differencing (listing 2)
vec2 dh_xy_fwd(float blend_top, float bump_scale) {
	float hdx = dFdx( blend_top );
	float hdy = dFdy( blend_top );
	float hll = bump_scale * blend_top;
	float db_x = bump_scale * (blend_top + hdx) - hll;
	float db_y = bump_scale * (blend_top + hdy) - hll;

	return vec2( db_x, db_y );
}

vec3 perturb_normal_arb( vec3 surf_pos, vec3 surf_norm, vec2 dh_xy, bool front_facing ) {
	// Workaround for Adreno 3XX dFd*( vec3 ) bug. See #9988
	vec3 v_sigma_x = vec3( dFdx( surf_pos.x ), dFdx( surf_pos.y ), dFdx( surf_pos.z ) );
	vec3 v_sigma_y = vec3( dFdy( surf_pos.x ), dFdy( surf_pos.y ), dFdy( surf_pos.z ) );
	vec3 v_n = surf_norm; // normalized
	vec3 r1 = cross( v_sigma_y, v_n );
	vec3 r2 = cross( v_n, v_sigma_x );
	float f_det = dot( v_sigma_x, r1 );
	f_det *= ( float( front_facing ) * 2.0 - 1.0 );
	vec3 v_grad = sign( f_det ) * ( dh_xy.x * r1 + dh_xy.y * r2 );
	return normalize( abs( f_det ) * surf_norm - v_grad );
}


void fragment() {
	if(v_world_uv.x < 0.00 || v_world_uv.y < 0.00 || v_world_uv.x > 1.0|| v_world_uv.y > 1.0) {
		discard;
	}
	vec2 texel_size = vec2(1.0)/vec2(textureSize(texture_global_normalmap, 0));
	// correcting by 1.75 texel size units. TODO: proof that it makes sense (based on normalmap algorithm)
	vec3 norm = texture(texture_global_normalmap, v_world_uv - offset_normal * texel_size).rgb;

	vec3 world_norm = normalize(unpack_normalmap(norm, 1.0).rbg);
	vec3 view_norm = (VIEW_MATRIX * vec4(world_norm,0.0)).xyz;
	NORMAL = view_norm;
	TANGENT = cross(vec3(1.0,0.0,0.0), NORMAL);
	BINORMAL = cross(TANGENT, NORMAL);
	//ALBEDO = vec3(0.2);
	vec2 top_uv = v_world_pos.xz *  uv_scale_top;
	ALBEDO = texture(texture_albedo_top, top_uv).rgb;

	vec4 world_noise = texture(texture_noise_3d, v_world_pos * triplanar_noise_blend_strenth);

	// Blend calculation in fragment shader for higher precision and quality visuals
	vec3 triplanar_weights = calcuate_triplanar_blend(world_norm, world_noise.rgb, triplanar_softness);
	vec3 word_pos_scaled_top = v_world_pos * uv_scale_top;
	vec3 word_pos_scaled_sides = v_world_pos * uv_scale_side;
	float roughness_out = 0.0;

	vec2 dh_xy = dh_xy_fwd(-triplanar_weights.y, max_bump_strength);


	vec4 albedo_tex = triplanar_top_texture(texture_albedo_side,triplanar_weights,word_pos_scaled_sides,
			texture_albedo_top, word_pos_scaled_top, world_norm, albedo_side, albedo_top);
	vec3 normal_ws = triplanar_top_normal(texture_normalmap_side,triplanar_weights,
			word_pos_scaled_sides,world_norm, normal_strength_side,
			texture_normalmap_top, word_pos_scaled_top, normal_strength_top,
			texture_roughness_top, texture_roughness_side, roughness_offset_top, roughness_out);
	vec3 bump_norm_ws = perturb_normal_arb(v_world_pos, normal_ws, dh_xy, false);


	ALBEDO = albedo_tex.rgb;
	if(colormap_present) {
		ALBEDO = mix(ALBEDO,texture(texture_color_map, v_world_uv).rgb, colormap_strength);
	}
	NORMAL = (VIEW_MATRIX * vec4(bump_norm_ws, 0.0)).xyz;
	SPECULAR = 0.15;
	ROUGHNESS = roughness_out;
}
