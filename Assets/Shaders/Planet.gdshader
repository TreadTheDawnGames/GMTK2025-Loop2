shader_type canvas_item;

uniform float radius = .3;
uniform int cell_amount = 10;
uniform vec3 period = vec3(9.5, 9.5, 9.5);

// color palette to skin the noise map
uniform vec4 tangerine : source_color = vec4(.968, .573, .337, 1.);
uniform vec4 sunset : source_color = vec4(.984, .82, .635, 1.);
uniform vec4 moonstone : source_color = vec4(0., .698, .792, 1.);
uniform vec4 ylnmn_blue : source_color = vec4(.114, .306, .537, 1.);
uniform vec4 emerald : source_color = vec4(.2, .792, .498, 1.);
uniform vec4 cal_poly_green : source_color = vec4(.078, .349, .114, 1.);

// modulo function that returns positive wrapped values. (13 % 5 = 3, but -13 % 5 = 2)
vec3 modulo(vec3 divident, vec3 divisor){
	vec3 positiveDivident = mod(divident, divisor) + divisor;
	return mod(positiveDivident, divisor);
}

// 3 dimensional pseudo random number generator
vec3 random(vec3 value){
	vec3 return_value = vec3( dot(value, vec3(127.1,311.7, 201.9) ),
				  dot(value, vec3(269.5,183.3, 367.7) ),
				  dot(value, vec3(245.1,367.7, 105.6) ) );
	return -1.0 + 2.0 * fract(sin(return_value) * 43758.5453123);
}

// seamless noise function adapted from Godot Shaders seamless Perlin Noise function
float seamless_noise(vec2 uv, vec3 _period, mat3 rot_p) {
	// equation of a sphere at coordinates (0.5, 0.5)
	// (x-.5)^2 + (y-.5)^2 + z^2 = radius^2
	float w = sqrt(pow(radius, 2.) - pow(uv.x - .5, 2.) - pow(uv.y - .5, 2.)); // calculate z-position of sphere surphace
	vec3 uvw = rot_p * vec3(uv, w); // multiply by rotation vector to spin world
	uvw = vec3(uvw * float(cell_amount)); // multiply by cell amount and then round to create discrete cells
	vec3 cellsMinimum = floor(uvw);
	vec3 cellsMaximum = ceil(uvw);
	vec3 uvw_fract = fract(uvw);
	
	// wrap every period
	cellsMinimum = modulo(cellsMinimum, _period);
	cellsMaximum = modulo(cellsMaximum, _period);
	
	// calc lerp
	vec3 blur = smoothstep(0.0, 1.0, uvw_fract);
	
	// generate cube of pseudo-random values for every pixel
	vec3 p_000 = random(vec3(cellsMinimum.x, cellsMinimum.y, cellsMinimum.z));
	vec3 p_100 = random(vec3(cellsMaximum.x, cellsMinimum.y, cellsMinimum.z));
	vec3 p_010 = random(vec3(cellsMinimum.x, cellsMaximum.y, cellsMinimum.z));
	vec3 p_110 = random(vec3(cellsMaximum.x, cellsMaximum.y, cellsMinimum.z));
	vec3 p_001 = random(vec3(cellsMinimum.x, cellsMinimum.y, cellsMaximum.z));
	vec3 p_101 = random(vec3(cellsMaximum.x, cellsMinimum.y, cellsMaximum.z));
	vec3 p_011 = random(vec3(cellsMinimum.x, cellsMaximum.y, cellsMaximum.z));
	vec3 p_111 = random(vec3(cellsMaximum.x, cellsMaximum.y, cellsMaximum.z));
	
	vec3 fraction = fract(uvw);
	
	// return a smoothed version of the noise
	return mix(mix( mix( dot( p_000, fraction - vec3(0, 0, 0) ),
                     dot( p_100, fraction - vec3(1, 0, 0) ), blur.x),
                mix( dot( p_010, fraction - vec3(0, 1, 0) ),
                     dot( p_110, fraction - vec3(1, 1, 0) ), blur.x), blur.y),
			mix( mix( dot( p_001, fraction - vec3(0, 0, 1) ),
                     dot( p_101, fraction - vec3(1, 0, 1) ), blur.x),
                mix( dot( p_011, fraction - vec3(0, 1, 1) ),
                     dot( p_111, fraction - vec3(1, 1, 1) ), blur.x), blur.y), blur.z) * 0.8 + 0.5;
}

// map perlin noise to color pallette
// fluxuate moonstone color by sin(time) to create waves
vec4 pixel_color_noise(vec2 uv, vec3 _period, mat3 rot_p){
	vec2 grid_uv = round(uv * float(300)) / float(300);
	float perlin = seamless_noise(grid_uv, _period, rot_p);
	vec4 color = vec4(0);
	
	if (perlin < 0.44+sin(TIME)/40.){
		color = ylnmn_blue;
	}else if (perlin < 0.5+sin(TIME)/25.){
		color = moonstone;
	}else if (perlin < 0.54){
		color = sunset;
	}else if (perlin < 0.58){
		color = tangerine;
	}else if (perlin < .69){
		color = emerald;
	}else if (perlin < 1.){
		color = cal_poly_green;
	};
	return color;
}

// shade clouds from new perlin noise
vec4 clouds(vec2 uv, vec3 _period, mat3 rot_p){
	uv = round(uv * float(300)) / float(300);
	
	// equation of a sphere at coordinates (0.5, 0.5)
	// (x-.5)^2 + (y-.5)^2 + z^2 = radius^2
	float w = sqrt(pow(radius*1.18, 2.) - pow(uv.x - .5, 2.) - pow(uv.y - .5, 2.));
	float theta = TIME / 20.;
	// rotate about 0,0 on UV coords and with the rot_p matrix (see below)
	mat3 rot_0 = mat3(vec3(1, 0, 0), vec3(0, cos(theta), -sin(theta)), vec3(0, sin(theta), cos(theta)));
	vec3 uvw = rot_0*(rot_p * vec3(uv, w));
	uvw = vec3(uvw * float(cell_amount) * .8);
	vec3 cellsMinimum = floor(uvw);
	vec3 cellsMaximum = ceil(uvw);
	vec3 uvw_fract = fract(uvw);
	
	vec3 blur = smoothstep(0.0, 1.0, uvw_fract);
	
	cellsMinimum = modulo(cellsMinimum, _period);
	cellsMaximum = modulo(cellsMaximum, _period);
	
	// see smooth_noise function for comments on this part
	vec3 p_000 = random(random(vec3(cellsMinimum.x, cellsMinimum.y, cellsMinimum.z)));
	vec3 p_100 = random(random(vec3(cellsMaximum.x, cellsMinimum.y, cellsMinimum.z)));
	vec3 p_010 = random(random(vec3(cellsMinimum.x, cellsMaximum.y, cellsMinimum.z)));
	vec3 p_110 = random(random(vec3(cellsMaximum.x, cellsMaximum.y, cellsMinimum.z)));
	vec3 p_001 = random(random(vec3(cellsMinimum.x, cellsMinimum.y, cellsMaximum.z)));
	vec3 p_101 = random(random(vec3(cellsMaximum.x, cellsMinimum.y, cellsMaximum.z)));
	vec3 p_011 = random(random(vec3(cellsMinimum.x, cellsMaximum.y, cellsMaximum.z)));
	vec3 p_111 = random(random(vec3(cellsMaximum.x, cellsMaximum.y, cellsMaximum.z)));
	
	float perlin =  mix(mix( mix( dot( p_000, uvw_fract - vec3(0, 0, 0) ),
                     dot( p_100, uvw_fract - vec3(1, 0, 0) ), blur.x),
                mix( dot( p_010, uvw_fract - vec3(0, 1, 0) ),
                     dot( p_110, uvw_fract - vec3(1, 1, 0) ), blur.x), blur.y),
					mix( mix( dot( p_001, uvw_fract - vec3(0, 0, 1) ),
                     dot( p_101, uvw_fract - vec3(1, 0, 1) ), blur.x),
                mix( dot( p_011, uvw_fract - vec3(0, 1, 1) ),
                     dot( p_111, uvw_fract - vec3(1, 1, 1) ), blur.x), blur.y), blur.z) * 0.8 + 0.5;
	
	vec4 color = vec4(0.);
	if (perlin < 0.5){
		color = vec4(0.0);
	}else if (perlin < 0.6){
		color = vec4(0.5);
	}else if (perlin < 0.62){
		color = vec4(0.8);
	}else if (perlin < 1.){
		color = vec4(1.);
	};
	return color;
}

void fragment() {
	float theta = float(-TIME/8.);
	// construct rotation matrix about 1/sqrt(2)i, 1/sqrt(2)j, 0k unit vector
	// because UV coordinates start at the top left and rotating the noise
	// rotates all the noise, not just the sphere so if you rotate about any
	// axis of the coordinate system the noise moves through the sphere
	// and it doesn't look like it's spinning (duh)
	// it's also why it rotates on a tilted axis
	// because this was the easiest solution I found
	vec3 rot_1 = vec3(.5*(1.-cos(theta)) + cos(theta), .5*(1.-cos(theta)), -(1./sqrt(2))*sin(theta));
	vec3 rot_2 = vec3(.5*(1.-cos(theta)), .5*(1.-cos(theta)) + cos(theta),(1./sqrt(2))*sin(theta));
	vec3 rot_3 = vec3((1./sqrt(2))*sin(theta), -(1./sqrt(2))*sin(theta), cos(theta));
	mat3 rot = mat3(rot_1, rot_2, rot_3);
	
	float dis = distance(vec2(.5, .5), UV);
	
	vec4 color = pixel_color_noise(UV, period, rot); // get world colors
	vec4 clouds = clouds(UV, period, rot); // get cloud colors
	
	COLOR = vec4(0., 0., 0., 1);
	if (dis < radius) {
		COLOR.rgb = color.rgb; // draw the world
	}
	
	if (COLOR.rgb == vec3(0.)) {
		COLOR.a = .0;
	}
	
	COLOR = COLOR + clouds; // add the clouds
	
}