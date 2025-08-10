shader_type canvas_item;

uniform float pulseSpeed = 2.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 color = COLOR;
	color.a -= 0.3+(0.3* sin(TIME * pulseSpeed));
	COLOR = color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
