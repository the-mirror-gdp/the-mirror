shader_type sky;
render_mode use_half_res_pass, use_quarter_res_pass;

uniform vec4 sky_top_color : source_color = vec4(0.385, 0.454, 0.55, 1.0);
uniform vec4 sky_horizon_color : source_color = vec4(0.646, 0.656, 0.67, 1.0);
uniform float sky_curve : hint_range(0, 1) = 0.15;
uniform float sky_energy = 1.0;
uniform vec4 fog_color : source_color = vec4(0.5,0.5,0.5,1.0);
uniform vec4 sky_stars_modulate : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 sky_bottom_color : source_color = vec4(0.2, 0.169, 0.133, 1.0);
uniform float ground_curve : hint_range(0, 1) = 0.02;
uniform float ground_energy = 1.0;
uniform float sun_angle_max = 30.0;
uniform float sun_curve : hint_range(0, 1) = 0.15;

const int VOLUMETRIC_STEPS = 15;

// Based on http://casual-effects.blogspot.com/2013/08/starfield-shader.html
// Based on Star Nest by Kali  and  Morgan McGuire
// https://www.shadertoy.com/view/4dfGDM
// That shader and this one are open source under the MIT license
vec3 star_volumetric(vec3 dir, float frequencyVariation, float sparsity, float brightness, float distfading, float stepsize) {
	vec3 origin = vec3(-0.5, 0.3, -0.7);
	vec3 result = vec3(0.0);
	//stabilze direction
	dir = floor(dir * 386.0)/386.0;
	float s = 0.1, fade = 0.01;
	for (int r = 0; r < VOLUMETRIC_STEPS; ++r) {
		vec3 p = origin + dir * (s * 0.6);
		p = abs(vec3(frequencyVariation) - mod(p, vec3(frequencyVariation * 2.0)));

		float prevlen = 0.0, a = 0.0;
		for (int i = 0; i < VOLUMETRIC_STEPS; ++i) {
			p = abs(p);
			p = p * (1.0 / dot(p, p)) + (-sparsity); // the magic formula
			float len = length(p);
			a += abs(len - prevlen); // absolute sum of average change
			prevlen = len;
		}
		a *= pow(a, 2.0); // add contrast
		result+=fade;

		// coloring based on distance
		result += (vec3(s, s*s, s*s*s*s) * a * brightness) * fade;
		fade *= distfading; // distance fading
		s += stepsize;
	}
	result = mix(vec3(length(result)), result, 0.9);
	return result * 0.02;
}


vec3 starbox(vec3 dir, float time) {
	dir *= 1.3;
	return star_volumetric(dir.xyz, 1.4, 0.42,
			mix(0.0035, 0.001, abs(sin(time * 0.3 + dir.x * 3.3 + dir.z  + 0.4 + sin(dir.y) ))),
			0.75, 0.2);
}

void sky() {
	float v_angle = acos(clamp(EYEDIR.y, -1.0, 1.0));
	float c = (1.0 - v_angle / (PI * 0.5));
	vec3 sky = mix(sky_horizon_color.rgb, sky_top_color.rgb, (clamp(1.0 - pow(1.0 - c, 1.0 / sky_curve), 0.0, 1.0)));
	sky *= sky_energy;

	if (LIGHT0_ENABLED) {
		float sun_angle = acos(dot(LIGHT0_DIRECTION, EYEDIR));
		if (sun_angle < LIGHT0_SIZE) {
			sky = LIGHT0_COLOR * LIGHT0_ENERGY;
		} else if (sun_angle < sun_angle_max) {
			float c2 = (sun_angle - LIGHT0_SIZE) / (sun_angle_max - LIGHT0_SIZE) ;
			sky = mix(LIGHT0_COLOR * LIGHT0_ENERGY, sky, clamp(1.0 - pow(1.0 - c2, 1.0 / sun_curve), 0.0, 1.0));
		}
	}

	if (LIGHT1_ENABLED) {
		float sun_angle = acos(dot(LIGHT1_DIRECTION, EYEDIR));
		if (sun_angle < LIGHT1_SIZE) {
			sky = LIGHT1_COLOR * LIGHT1_ENERGY;
		} else if (sun_angle < sun_angle_max) {
			float c2 = (sun_angle - LIGHT1_SIZE) / (sun_angle_max - LIGHT1_SIZE);
			sky = mix(LIGHT1_COLOR * LIGHT1_ENERGY, sky, clamp(1.0 - pow(1.0 - c2, 1.0 / sun_curve), 0.0, 1.0));
		}
	}

	if (LIGHT2_ENABLED) {
		float sun_angle = acos(dot(LIGHT2_DIRECTION, EYEDIR));
		if (sun_angle < LIGHT2_SIZE) {
			sky = LIGHT2_COLOR * LIGHT2_ENERGY;
		} else if (sun_angle < sun_angle_max) {
			float c2 = (sun_angle - LIGHT2_SIZE) / (sun_angle_max - LIGHT2_SIZE);
			sky = mix(LIGHT2_COLOR * LIGHT2_ENERGY, sky, clamp(1.0 - pow(1.0 - c2, 1.0 / sun_curve), 0.0, 1.0));
		}
	}

	if (LIGHT3_ENABLED) {
		float sun_angle = acos(dot(LIGHT3_DIRECTION, EYEDIR));
		if (sun_angle < LIGHT3_SIZE) {
			sky = LIGHT3_COLOR * LIGHT3_ENERGY;
		} else if (sun_angle < sun_angle_max) {
			float c2 = (sun_angle - LIGHT3_SIZE) / (sun_angle_max - LIGHT3_SIZE);
			sky = mix(LIGHT3_COLOR * LIGHT3_ENERGY, sky, clamp(1.0 - pow(1.0 - c2, 1.0 / sun_curve), 0.0, 1.0));
		}
	}

	c = (v_angle - (PI * 0.5)) / (PI * 0.5);
	vec3 ground = mix(sky_horizon_color.rgb, sky_bottom_color.rgb, pow(clamp(1.0 - pow(1.0 - c, 1.0 / ground_curve), 0.0, 1.0), 0.5));
	ground *= ground_energy;


	// Draw to quarter res buffer for reflections (no stars)
	// Draw to half res buffer for stars sky
	if (AT_QUARTER_RES_PASS && AT_CUBEMAP_PASS) {
		COLOR = mix(ground, sky, step(0.0, EYEDIR.y));
	} else if(AT_HALF_RES_PASS && !AT_CUBEMAP_PASS){
		vec3 sky_stars = starbox(EYEDIR, TIME);
		COLOR = mix(ground, sky, step(0.0, EYEDIR.y));
		COLOR += mix(sky_stars,
					vec3(0.0),
					clamp(pow(1.0 - max(dot(EYEDIR + vec3(0.0,0.2,0.0), vec3(0.0,1.0,0.0)), 0.0), 2.5 ), 0.0,1.0) );
	} else if (AT_CUBEMAP_PASS) {
		COLOR = QUARTER_RES_COLOR.rgb;
	} else {
		COLOR = HALF_RES_COLOR.rgb;
	}
}
