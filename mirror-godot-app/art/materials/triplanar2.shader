/******************************************************
This shader blends two separate top and side textures, each with their own triplanar mapped albedo, normal and ambient occlusion.

Texture A is the top surface.
Texture B are the sides and bottom.

The typical use case would be to have grass on top and a rocky surface on the sides and bottom of a terrain.

This version (v2) adds an untiled texture lookup which hides the repeating pattern that appears when stamping the same texture over
and over. However it costs two additional texture lookups. At lower resolutions the performance cost is marginal, but at 4k the
frame rate cuts in half.

Last modified: 2019-12-23

******************************************************/


shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform float 		AB_mix_offset : hint_range(-11., 2.5) = -6.187;
uniform float 		AB_mix_normal : hint_range(0., 20.) = 8.253;
uniform float 		AB_mix_blend : hint_range(0., 10.) = 2.;

uniform bool		A_albedo_enabled = true;
uniform vec4 		A_albedo_tint : hint_color = vec4(1., 1., 1., 1.);
uniform sampler2D 	A_albedo_map : hint_albedo;

uniform bool		A_normal_enabled = true;
uniform sampler2D 	A_normal_map : hint_normal;
uniform float 		A_normal_strength : hint_range(-16., 16.0) = 1.;

uniform vec4 		A_ao_tex_channel = vec4(.33, .33, .33, 0.);
uniform bool		A_ao_enabled = true;
uniform float 		A_ao_strength : hint_range(-1., 1.0) = 1.;
uniform sampler2D 	A_ao_map : hint_white;

uniform vec3 		A_uv_offset;
uniform int 		A_uv_tiles : hint_range(1, 16) = 1;
uniform float 		A_tri_blend_sharpness : hint_range(0.001, 50.0) = 17.86;

uniform bool		B_albedo_enabled = true;
uniform vec4 		B_albedo_tint : hint_color = vec4(1., 1., 1., 1.);
uniform sampler2D 	B_albedo_map : hint_albedo;

uniform bool		B_normal_enabled = true;
uniform sampler2D 	B_normal_map : hint_normal;
uniform float 		B_normal_strength : hint_range(-16., 16.0) = 1.;
uniform float 		B_normal_distance : hint_range(.001, 1.) = .025;

uniform vec4 		B_ao_tex_channel = vec4(.33, .33, .33, 0.);
uniform bool		B_ao_enabled = true;
uniform float 		B_ao_strength : hint_range(-1., 1.0) = 1.;
uniform sampler2D 	B_ao_map : hint_white;

uniform vec3 		B_uv_offset;
uniform int 		B_uv_tiles : hint_range(1, 16) = 1;
uniform float 		B_tri_blend_sharpness : hint_range(0.001, 50.0) = 17.86;

varying vec3 		A_uv_triplanar_pos;
varying vec3 		A_uv_power_normal;
varying vec3 		B_uv_triplanar_pos;
varying vec3 		B_uv_power_normal;

varying vec3 		vertex_normal;
varying float		vertex_distance;


// This untiles textures with only two sample lookups
// http://www.iquilezles.org/www/articles/texturerepetition/texturerepetition.htm
uniform sampler2D 	noise_texture : hint_white;
float sum( vec4 v ) { return v.x+v.y+v.z; }

vec4 untiled_texture(sampler2D samp, in vec2 uv) {
	 // sample variation pattern
	float k = texture( noise_texture, 0.005*uv ).x; // cheap (cache friendly) lookup

	// compute index
	float index = k*8.0;
	float i = floor( index );
	float f = fract( index );

	// offsets for the different virtual patterns
	vec2 offa = sin(vec2(3.0,7.0)*(i+0.0)); // can replace with any other hash
	vec2 offb = sin(vec2(3.0,7.0)*(i+1.0)); // can replace with any other hash

	// compute derivatives for mip-mapping
	vec2 dx = dFdx(uv);
	vec2 dy = dFdy(uv);

	// sample the two closest virtual patterns
	vec4 cola = textureGrad( samp, uv + offa, dx, dy );
	vec4 colb = textureGrad( samp, uv + offb, dx, dy );

	// interpolate between the two virtual patterns
	return mix( cola, colb, smoothstep(0.2,0.8,f-0.1*sum(cola-colb)) );
}


vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= untiled_texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= untiled_texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= untiled_texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}


void vertex() {
	vertex_normal = NORMAL;

    TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
    TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
    TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
    TANGENT = normalize(TANGENT);
    BINORMAL = vec3(0.0,1.0,0.0) * abs(NORMAL.x);
    BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
    BINORMAL+= vec3(0.0,1.0,0.0) * abs(NORMAL.z);
    BINORMAL = normalize(BINORMAL);

    A_uv_power_normal=pow(abs(NORMAL),vec3(A_tri_blend_sharpness));
    A_uv_power_normal/=dot(A_uv_power_normal,vec3(1.0));
    A_uv_triplanar_pos = VERTEX * float(A_uv_tiles) / (16.) + A_uv_offset;			//On VoxelTerrain 16 is 100% size, so uv_tile is multiples of 16.
	A_uv_triplanar_pos *= vec3(1.0,-1.0, 1.0);

    B_uv_power_normal=pow(abs(NORMAL),vec3(B_tri_blend_sharpness));
    B_uv_power_normal/=dot(B_uv_power_normal,vec3(1.0));
    B_uv_triplanar_pos = VERTEX * float(B_uv_tiles) / (16.)  + B_uv_offset;
	B_uv_triplanar_pos *= vec3(1.0,-1.0, 1.0);


	// Get the distance from camera to VERTEX (VERTEX as if the camera is 0,0,0)
	vertex_distance = (PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z;
}


void fragment() {
	// Calculate Albedo

	vec3 A_albedo, B_albedo;
	float AB_mix_factor;
	if(A_albedo_enabled) {
		ALBEDO = A_albedo = A_albedo_tint.rgb * triplanar_texture(A_albedo_map,A_uv_power_normal,A_uv_triplanar_pos).rgb;
		AB_mix_factor = clamp( AB_mix_normal*dot(vec3(0.,1.,0.), vertex_normal) + AB_mix_offset + AB_mix_blend*A_albedo.g, 0., 1.);
	}
	if(B_albedo_enabled) {
		ALBEDO = B_albedo = B_albedo_tint.rgb * triplanar_texture(B_albedo_map,B_uv_power_normal,B_uv_triplanar_pos).rgb;
	}
	if(A_albedo_enabled==true && B_albedo_enabled==true) {
		ALBEDO = mix(B_albedo, A_albedo, AB_mix_factor);
	}


	// Calculate Normals

	vec3 A_normal=vec3(0.5,0.5,0.5);
	vec3 B_normal=vec3(0.5,0.5,0.5);
	float B_normal_faded=B_normal_strength;
	if(A_normal_enabled)
		A_normal = triplanar_texture(A_normal_map,A_uv_power_normal,A_uv_triplanar_pos).rgb;
	if(B_normal_enabled)
		B_normal = triplanar_texture(B_normal_map,B_uv_power_normal,B_uv_triplanar_pos).rgb;
		// Fade out normal strength as it disappears into the distance
		B_normal_faded = clamp(B_normal_strength/(B_normal_distance*vertex_distance), 0., B_normal_strength);
	if(A_normal_enabled || B_normal_enabled) {
		NORMAL_MAP = mix(B_normal, A_normal, AB_mix_factor);
		NORMAL_MAP_DEPTH = mix(B_normal_faded, A_normal_strength, AB_mix_factor);
	}


	// Calculate Ambient Occlusion

	float A_ao=1., B_ao=1.;
	if(A_ao_enabled)
		AO = A_ao = dot(triplanar_texture(A_ao_map,A_uv_power_normal,A_uv_triplanar_pos),A_ao_tex_channel);
	if(B_ao_enabled)
		AO = B_ao = dot(triplanar_texture(B_ao_map,B_uv_power_normal,B_uv_triplanar_pos),B_ao_tex_channel);
	if(A_ao_enabled || B_ao_enabled) {
		AO = mix(B_ao, A_ao, AB_mix_factor);
		AO_LIGHT_AFFECT = mix(B_ao_strength, A_ao_strength, AB_mix_factor);
	}
}

