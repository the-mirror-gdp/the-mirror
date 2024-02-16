shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

//used to swap between standard and without tiling sampling
#define TEXTURE_SPACE_SAMPLER untiled_texture
//#define TEXTURE_SPACE_SAMPLER texture

group_uniforms textureA;
group_uniforms textureA.textures_top;
uniform vec4 albedo_top_a : source_color;
uniform sampler2D texture_albedo_top_a : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D texture_normalmap_top_a : hint_roughness_normal, filter_linear_mipmap_anisotropic,repeat_enable;
uniform float uv_scale_top_a = 1.0;
uniform float roughness_top_a = 1.0;
uniform float normal_strength_top_a = 1.0;
uniform float layer_height_top_a = 0.5;
group_uniforms;
group_uniforms textureA.textures_sides;
uniform vec4 albedo_side_a : source_color;
uniform sampler2D texture_albedo_side_a : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D texture_normalmap_side_a : hint_roughness_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float roughness_side_a = 1.0;
uniform float uv_scale_side_a = 1.0;
uniform float normal_strength_side_a = 1.0;
uniform float layer_height_side_a = 0.0;
group_uniforms;

group_uniforms textureB;

group_uniforms textureB.textures_top;
uniform vec4 albedo_top_b : source_color;
uniform sampler2D texture_albedo_top_b : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D texture_normalmap_top_b : hint_roughness_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float roughness_top_b = 1.0;
uniform float uv_scale_top_b = 1.0;
uniform float normal_strength_top_b = 1.0;
uniform float layer_height_top_b = 0.5;
group_uniforms;
group_uniforms textureB.textures_sides;
uniform vec4 albedo_side_b : source_color;
uniform sampler2D texture_blbedo_side_b : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D texture_normalmap_side_b : hint_roughness_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float roughness_side_b = 1.0;
uniform float uv_scale_side_b = 1.0;
uniform float normal_strength_side_b = 1.0;
uniform float layer_height_side_b = 0.0;
group_uniforms;

uniform float blend_weight_offset = 0.0;
uniform float triplanar_blend_softness: hint_range(0.05,1.0) = 0.1;
uniform float specular;
uniform float metallic;
// TODO: This could probably use 1 texture noise?
uniform sampler2D texture_noise : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform sampler3D texture_noise_3d : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform float paint_softness: hint_range(0.05,1.0) = 0.2;
uniform float paint_blend_mask_scale = 1.0;
uniform float max_bump_strength = 1.0;

const float FLOAT_EPSILON = 0.000001;

varying vec3 v_triplanar_pos;
varying vec3 v_triplanar_weights;
varying vec3 v_world_normal;
varying vec4 v_vertex_paint_weights;

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
						  float roughness_top, float roughness_side, out float roughness
) {
	vec3 tex_sample = vec3(0.0);
	vec3 normal_y = vec3(0.0);
	vec3 normal_x = vec3(0.0);
	vec3 normal_z = vec3(0.0);
	roughness = 0.0;

	if(p_weights.x > FLOAT_EPSILON) {
		tex_sample = TEXTURE_SPACE_SAMPLER(p_sampler, p_triplanar_pos.zy).xyz;
		roughness += tex_sample.z * roughness_side * p_weights.x;
		normal_x = unpack_normalmap(tex_sample, strength);
		//perform UDN
		normal_x = vec3(normal_x.xy + p_world_normal.zy, p_world_normal.x);
	}

	if(p_weights.y > FLOAT_EPSILON) {
		if(p_world_normal.y >0.0){
			tex_sample = TEXTURE_SPACE_SAMPLER(p_sampler_top, p_top_pos.xz).xyz;
			roughness += tex_sample.z * roughness_top * p_weights.y;
			normal_y = unpack_normalmap(tex_sample, top_strength);
		} else {
			tex_sample = TEXTURE_SPACE_SAMPLER(p_sampler, p_triplanar_pos.xz).xyz;
			roughness += tex_sample.z * roughness_side * p_weights.y;
			normal_y = unpack_normalmap(tex_sample, strength);
		}
		normal_y = vec3(normal_y.xy + p_world_normal.xz, p_world_normal.y);
	}
	if(p_weights.z > FLOAT_EPSILON) {
		tex_sample = TEXTURE_SPACE_SAMPLER(p_sampler, p_triplanar_pos.xy).xyz;
		roughness += tex_sample.z * roughness_side * p_weights.z;
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

// Utility function to decode components.
// It returns 4 values in the range [0..255]
// https://voxel-tools.readthedocs.io/en/latest/smooth_terrain/#shader
vec4 decode_8bit_vec4(float v) {
	uint i = floatBitsToUint(v);
	return vec4(
		float(i & uint(0xff)),
		float((i >> uint(8)) & uint(0xff)),
		float((i >> uint(16)) & uint(0xff)),
		float((i >> uint(24)) & uint(0xff)));
}

// This function is using varyings so needs to stay here
// TODO: it might be a good idea to pack it to structs for better readability
void paint_layer_sample(float  uv_scale_top,
						float uv_scale_side,
						sampler2D texture_albedo_side,
						sampler2D texture_albedo_top,
						vec4 albedo_top,
						vec4 albedo_side,
						sampler2D texture_normalmap_side,
						float normal_strength_side,
						sampler2D texture_normalmap_top,
						float normal_strength_top,
						vec3 triplanar_weights,
						vec3 world_norm,
						float roughness_top,
						float roughness_side,
						out vec3 albedo,
						out vec3 normal_ws,
						out float roughness_blend,
) {
	float roughness = 0.0;
	vec3 word_pos_scaled_top = v_triplanar_pos * uv_scale_top;
	vec3 word_pos_scaled_sides = v_triplanar_pos * uv_scale_side;
	vec4 albedo_tex = triplanar_top_texture(texture_albedo_side,triplanar_weights,word_pos_scaled_sides,
			texture_albedo_top, word_pos_scaled_top, world_norm, albedo_side, albedo_top);
	normal_ws = triplanar_top_normal(texture_normalmap_side,triplanar_weights,
			word_pos_scaled_sides,world_norm, normal_strength_side,
			texture_normalmap_top, word_pos_scaled_top, normal_strength_top,
			roughness_top, roughness_side, roughness);
	albedo = albedo_tex.rgb;
	float top_weight = triplanar_weights.y * step(0.0, v_world_normal.y);
	roughness_blend = roughness;
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

// Two functions to calcuate blending weights with noise based sharp transition
// Roughly based on https://bgolus.medium.com/normal-mapping-for-a-triplanar-shader-10bf39dca05a#38e5
// and Zylann heightmap shader
vec3 calcuate_triplanar_blend(vec3 noise, float noise_blend) {
	// Height Map Triplanar Blend
	vec3 blend = abs(vec3(v_world_normal.x, v_world_normal.y * (1.0 + blend_weight_offset), v_world_normal.z));
	blend /= dot(blend, vec3(1.0));
	vec3 heights = vec3(0.0, noise.y, 0.0) + (blend * 3.0); // blend noise only for Y axis
	float height_start = max(max(heights.x, heights.y), heights.z) - noise_blend;
	vec3 h = max(heights - height_start, vec3(0.0));
	blend = h / max(dot(h, vec3(1.0)), FLOAT_EPSILON);
	return blend;
}

vec4 calculate_vpaint_blend(vec4 input_weights, vec4 noise, float noise_blend) {
	vec4 blend = abs(input_weights);
	blend /= max(dot(blend, vec4(1.0)), FLOAT_EPSILON);
	blend.x = 1.0 - dot(blend.yzw, vec3(1.0));
	vec4 heights = noise + (blend);
	float height_start = max(max(max(heights.x, heights.y), heights.z), heights.w) - noise_blend;
	vec4 h = max(heights - height_start, vec4(0.0));
	blend = h / max(dot(h, vec4(1.0)), FLOAT_EPSILON);
	return blend;
}

void vertex() {
	v_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = MODEL_NORMAL_MATRIX * NORMAL;

	// TODO: uncomment for voxel terrrain
	//v_vertex_paint_weights = decode_8bit_vec4(CUSTOM1.y) / 255.0;
	// TODO: extend this to 4 layers when avaible
	//v_vertex_paint_weights.x += dot(v_vertex_paint_weights.zw, vec2(1.0));
	//v_vertex_paint_weights.zw = vec2(0.0);
	// This is just for a bit of randomisation:
	float noise = texture( texture_noise, v_triplanar_pos.xz ).x;
	float value = clamp(COLOR.g * noise, 0.0, 1.0);
	v_vertex_paint_weights = vec4( 1.0 - value, value, 0.0,0.0);
}

void fragment() {
	vec3 albedo_a = vec3(0.0), albedo_b = vec3(0.0);
	vec3 normal_ws_a = vec3(0.0), normal_ws_b = vec3(0.0);
	float roughness_a = 0.0, roughness_b = 0.0;
	vec4 world_noise = texture(texture_noise_3d, v_triplanar_pos * paint_blend_mask_scale);

	// Blend calculation in fragment shader for higher precision and quality visuals
	vec3 triplanar_weights = calcuate_triplanar_blend(world_noise.rgb, triplanar_blend_softness);
	vec4 vertex_paint_weights = calculate_vpaint_blend(v_vertex_paint_weights, world_noise, paint_softness);
	// TODO: this used only because of two instead of 4 layers are implemented
	vec2 tmp2_way_blend = vertex_paint_weights.xy;
	tmp2_way_blend.x = 1.0 - tmp2_way_blend.y;
	float top_weight = triplanar_weights.y * step(0.0, v_world_normal.y);

	float bump_weighted = mix(layer_height_side_a, layer_height_top_a, top_weight) * tmp2_way_blend.x +
			mix(layer_height_side_b, layer_height_top_b, top_weight) * tmp2_way_blend.y;

	vec2 dh_xy = dh_xy_fwd(bump_weighted, max_bump_strength);
	vec3 bump_norm_ws = perturb_normal_arb(v_triplanar_pos, v_world_normal, dh_xy, FRONT_FACING);

	paint_layer_sample(uv_scale_top_a, uv_scale_side_a,texture_albedo_side_a,texture_albedo_top_a,
			albedo_top_a, albedo_side_a, texture_normalmap_side_a,normal_strength_side_a,
			texture_normalmap_top_a, normal_strength_top_a, triplanar_weights, bump_norm_ws,
			roughness_top_a, roughness_side_a, albedo_a, normal_ws_a, roughness_a);
	paint_layer_sample(uv_scale_top_b, uv_scale_side_b,texture_blbedo_side_b,texture_albedo_top_b,
			albedo_top_b, albedo_side_b, texture_normalmap_side_b,normal_strength_side_b,
			texture_normalmap_top_b, normal_strength_top_b, triplanar_weights, bump_norm_ws,
			roughness_top_b, roughness_side_b, albedo_b, normal_ws_b, roughness_b);

	ALBEDO = albedo_a * vertex_paint_weights.x + albedo_b * vertex_paint_weights.y;
	METALLIC = metallic;
	ROUGHNESS = roughness_a * vertex_paint_weights.x + roughness_b * vertex_paint_weights.y;

	vec3 normal_tex_ws = normalize(normal_ws_a * vertex_paint_weights.x + normal_ws_b * vertex_paint_weights.y);
	NORMAL = (VIEW_MATRIX * vec4(normal_tex_ws, 0.0)).xyz;
	SPECULAR = specular;
}
