// Adopted from https://godotshaders.com/shader/ball-of-fire/ by https://godotshaders.com/author/ahaugas/
// 
shader_type canvas_item;
render_mode blend_mix;

// For manual Animation
uniform float time : hint_range(0.0, 10.0);
// Change the size of the fireball in the 'frame' of the shader
uniform float frame_scope : hint_range(0.1, 10.0) = 3.0;
// Use system time to animate the fireball
uniform bool use_system_time = true;
// Change the speed of the animation when using system time
uniform float time_accel : hint_range(0.0, 10.0, 0.1) = 5.0;

float snoise(vec3 uv, float res)
{
    const vec3 s = vec3(1e0, 1e2, 1e3);
    uv *= res;
    
    vec3 uv0 = floor(mod(uv, res)) * s;
    vec3 uv1 = floor(mod(uv + vec3(1.0), res)) * s;
    
    vec3 f = fract(uv);
    f = f * f * (3.0 - 2.0 * f);

    vec4 v = vec4(uv0.x + uv0.y + uv0.z, uv1.x + uv0.y + uv0.z,
                  uv0.x + uv1.y + uv0.z, uv1.x + uv1.y + uv0.z);

    vec4 r = fract(sin(v * 1e-1) * 1e3);
    float r0 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);

    r = fract(sin((v + uv1.z - uv0.z) * 1e-1) * 1e3);
    float r1 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
    
    return mix(r0, r1, f.z) * 2.0 - 1.0;
}

void fragment() 
{
    // Calcular las coordenadas de la pantalla usando SCREEN_PIXEL_SIZE
    //vec2 screen_size = vec2(500, 400); //vec2(1.0 / SCREEN_PIXEL_SIZE.x, 1.0 / SCREEN_PIXEL_SIZE.y);
    //vec2 fragCoord = FRAGCOORD.xy;
    //
    //vec2 p = -0.5 + fragCoord.xy / screen_size;
    //p.x *= screen_size.x / screen_size.y;
    
	vec2 p = 2.0 * UV - 1.0; // Reset origin and scale
    float color = 3.0 - (frame_scope * length(2.0 * p));
    
    vec3 coord = vec3(atan(p.x, p.y) / 6.2832 + 0.5, length(p) * 0.4, 0.5);
    
    
    for (int i = 1; i <= 8; i++) 
    {
        float power = pow(2.0, float(i));
		if (use_system_time) {
			color += (1.5 / power) * snoise(coord + vec3(0.0, -TIME * 0.05 * time_accel, TIME * 0.01 * time_accel), power * 16.0);
		} else {
        	color += (1.5 / power) * snoise(coord + vec3(0.0, -time * 0.05, time * 0.01), power * 16.0);
		}
    }
	if (color < 0.0) {
		COLOR = vec4(0,0,0,0);
	} else {
	    vec3 colortemp = vec3(color, pow(max(color, 0.0), 2.0) * 0.4, pow(max(color, 0.0), 3.0) * 0.15);
		COLOR = vec4(colortemp, length(colortemp));
	}
}
