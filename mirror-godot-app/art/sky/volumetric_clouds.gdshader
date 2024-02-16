
// Based on https://github.com/clayjohn/godot-volumetric-cloud-demo

shader_type fog;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 emission : source_color = vec4(0, 0, 0, 1);

// vol clounds
uniform sampler3D worlnoise : filter_linear_mipmap, repeat_enable;
uniform sampler3D perlworlnoise : filter_linear_mipmap, repeat_enable;
uniform sampler2D weathermap : filter_linear_mipmap, repeat_enable;

uniform float _density : hint_range(0.01, 1.0) = 0.05;
uniform float cloud_coverage :hint_range(0.1, 1.0) = 0.25;
uniform float _time_scale :hint_range(0.0, 20.0) = 1.0;
uniform float _time_offset : hint_range(0.0, 1000.0, 0.5) = 0.0;

uniform float height_offset : hint_range(0.0, 1000.0, 0.5) = 0.0;

// Approximately earth sizes
const float g_radius = 10.0; //ground radius
const float sky_b_radius = 10.0;//bottom of cloud layer
const float sky_t_radius = 150.0;//top of cloud layer


// From: https://www.shadertoy.com/view/4sfGzS credit to iq
float hash(vec3 p) {
	p  = fract( p * 0.3183099 + 0.1 );
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// Utility function that maps a value from one range to another.
float remap(float originalValue,  float originalMin,  float originalMax,  float newMin,  float newMax) {
	return newMin + (((originalValue - originalMin) / (originalMax - originalMin)) * (newMax - newMin));
}


float GetHeightFractionForPoint(float inPosition) {
	float height_fraction = (inPosition -  sky_b_radius) / (sky_t_radius - sky_b_radius);
	return clamp(height_fraction, 0.0, 1.0);
}

vec4 mixGradients(float cloudType){
	const vec4 STRATUS_GRADIENT = vec4(0.02f, 0.05f, 0.09f, 0.11f);
	const vec4 STRATOCUMULUS_GRADIENT = vec4(0.02f, 0.2f, 0.48f, 0.625f);
	const vec4 CUMULUS_GRADIENT = vec4(0.01f, 0.0625f, 0.78f, 1.0f);
	float stratus = 1.0f - clamp(cloudType * 2.0f, 0.0, 1.0);
	float stratocumulus = 1.0f - abs(cloudType - 0.5f) * 2.0f;
	float cumulus = clamp(cloudType - 0.5f, 0.0, 1.0) * 2.0f;
	return STRATUS_GRADIENT * stratus + STRATOCUMULUS_GRADIENT * stratocumulus + CUMULUS_GRADIENT * cumulus;
}

float densityHeightGradient(float heightFrac, float cloudType) {
	vec4 cloudGradient = mixGradients(cloudType);
	return smoothstep(cloudGradient.x, cloudGradient.y, heightFrac) - smoothstep(cloudGradient.z, cloudGradient.w, heightFrac);
}

float intersectSphere(vec3 pos, vec3 dir,float r) {
	float a = dot(dir, dir);
	float b = 2.0 * dot(dir, pos);
	float c = dot(pos, pos) - (r * r);
	float d = sqrt((b*b) - 4.0*a*c);
	float p = -b - d;
	float p2 = -b + d;
	return max(p, p2) / (2.0 * a);
}

// Returns density at a given point
// Heavily based on method from Schneider
float density_clouds(vec3 pip, vec3 weather, float mip) {
	float time = TIME ;
	vec3 p = pip;
	p.y += sin(time * 10.0 * _time_scale + _time_offset);
	vec3 hn = textureLod(worlnoise, p*0.002, mip).rgb;
	vec4 n = textureLod(perlworlnoise, p.xyz*0.002, mip-2.0);
	float height_fraction =  GetHeightFractionForPoint(p.y  + pow(hn.b, 1.0) * 100.0) ;
	float fbm = n.g*0.625+n.b*0.25+n.a*0.125;
	float g = densityHeightGradient(height_fraction, weather.r);
	float base_cloud = remap(n.r, -(1.0-fbm), 1.0, 0.0, 1.0);
	float weather_coverage = cloud_coverage*weather.b;
	base_cloud = remap(base_cloud*g, 1.0-(weather_coverage), 1.0, 0.0, 1.0);
	base_cloud *= weather_coverage;
	return pow(clamp(base_cloud, 0.0, 1.0), (1.0 - height_fraction) * 0.8 + 0.5);
}

void fog() {
	const float weather_scale = .0025;
	float time = TIME * 1.0 * _time_scale;
	vec2 weather_pos = vec2(time * 0.9, time);
	vec3 p = WORLD_POSITION * 1.0;
	p.y -= height_offset;
	vec3 weather_sample = texture(weathermap, p.xz * weather_scale + 0.5 + weather_pos).xyz;
	DENSITY = pow(float(density_clouds(p, weather_sample, 0.0) * 1.0), _density * 100.0 );
	//DENSITY *= pow(clamp(-2.0 * SDF / min(min(SIZE.x, SIZE.y), SIZE.z), 0.0, 1.0), .1);
	ALBEDO = albedo.rgb;
	EMISSION = emission.rgb;
}
