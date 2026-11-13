shader_type spatial;
render_mode unshaded, shadows_disabled;

// ÓRBITA — un sol. No recibe luz: la da. La superficie hierve con dos capas de
// ruido que se mueven a distinta velocidad, el borde lleva corona, y al
// golpearlo se pone al blanco.

uniform vec3 color_a : source_color = vec3(1.0, 0.36, 0.04);
uniform vec3 color_b : source_color = vec3(1.0, 0.86, 0.45);
uniform float destello = 0.0;
uniform float fase = 0.0;

varying vec3 local;

float azar(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float ruido(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(azar(i), azar(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(azar(i + vec3(0.0, 1.0, 0.0)), azar(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(azar(i + vec3(0.0, 0.0, 1.0)), azar(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(azar(i + vec3(0.0, 1.0, 1.0)), azar(i + vec3(1.0, 1.0, 1.0)), f.x), f.y),
		f.z);
}

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec3 q = local * 22.0;
	float n = ruido(q + vec3(0.0, TIME * 0.6 + fase, 0.0)) * 0.6
		+ ruido(q * 2.3 - vec3(TIME * 0.8, 0.0, fase)) * 0.4;
	float calor = smoothstep(0.30, 0.75, n);
	float borde = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	vec3 col = mix(color_a * 1.1, color_b * 2.6, calor);
	col += color_a * borde * 3.0;
	col = mix(col, vec3(5.0, 4.6, 4.0), destello * 0.75);
	ALBEDO = col * (1.0 + destello * 1.5);
}
