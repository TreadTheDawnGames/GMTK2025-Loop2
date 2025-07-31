shader_type canvas_item;

uniform float paralax = 0.001;
uniform vec2 offset = vec2(0,0);


void vertex() {
	// Called for every vertex the material is visible on.
	UV += offset * paralax;
}