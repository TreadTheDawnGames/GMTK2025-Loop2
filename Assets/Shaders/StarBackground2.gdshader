shader_type canvas_item;

const float w = 1.0/990.0;
const float h = 1.0/620.0;

void vertex() {
	vec2 uv = UV;
	float w20 = floor(uv.x*20.0);
	float h20 = floor(uv.y*20.0);
	float rand1 = TIME + (153.2*w20/(h20+1.73));
	float rand2 = TIME + (153.2*h20/(w20+1.73));
	vec4 color = COLOR;

	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
