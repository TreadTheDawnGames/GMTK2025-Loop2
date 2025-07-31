shader_type canvas_item;
render_mode blend_add; //Comment this if you want another render mode.
uniform vec2 center = vec2(0.5);
uniform float size: hint_range(0.0,5.0) = 1.0; //change size to well, change the size of your gradient
uniform vec2 squishness = vec2(1.0); // how squashed your gradient is

//choose colors in the inspector
uniform vec4 color1 : source_color;
uniform vec4 color2 : source_color;
uniform vec4 color3 : source_color;
uniform vec4 color4 : source_color;
uniform vec4 color5 : source_color;
uniform vec4 color6 : source_color;

//choose how far the colors are from each other in the inspector
uniform float step1 : hint_range(0.0,1.0) = 0.159;
uniform float step2 : hint_range(0.0,1.0) = 0.182;
uniform float step3 : hint_range(0.0,1.0) = 0.233;
uniform float step4 : hint_range(0.0,1.0) = 0.264;
uniform float step5 : hint_range(0.0,1.0) = 0.265;
uniform float step6 : hint_range(0.0,1.0) = 0.266;

void fragment() {
	float dist = distance(center*squishness,UV*squishness);
	vec4 color = mix(color1, color2, smoothstep(step1*size, step2*size, dist));
	color = mix(color, color3, smoothstep(step2*size, step3*size, dist));
	color = mix(color, color4, smoothstep(step3*size, step4*size, dist));
	color = mix(color, color5, smoothstep(step4*size, step5*size, dist));
	color = mix(color, color6, smoothstep(step5*size, step6*size, dist));
	COLOR = color;
}