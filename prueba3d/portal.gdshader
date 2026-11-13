shader_type spatial;
render_mode unshaded, shadows_disabled;

// ÓRBITA — un remolino. Sirve para el agujero negro y para las dos bocas del
// agujero de gusano: brazos en espiral que giran hacia un centro sin luz.

uniform vec3 color_a : source_color = vec3(0.05, 0.4, 1.0);
uniform vec3 color_b : source_color = vec3(0.5, 1.0, 1.0);
uniform float giro = 1.0;
uniform float activo = 0.0;
uniform float tapada = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float a = atan(p.y, p.x);
	float espiral = sin(a * 3.0 + log(r + 0.04) * 7.0 - TIME * 4.5 * giro);
	float brazos = smoothstep(-0.3, 0.9, espiral);
	float hueco = smoothstep(0.30, 0.46, r);
	float borde = smoothstep(1.0, 0.82, r);
	vec3 col = mix(color_a, color_b, brazos) * (0.35 + 1.9 * brazos) * hueco;
	col += color_b * pow(smoothstep(0.62, 0.42, r) * hueco, 2.0) * 4.0;
	col += color_a * smoothstep(0.80, 1.0, r) * 2.5;
	col *= borde * (1.0 + activo * 2.5);
	// Tapada: se queda en un rescoldo rojo. Por ahi no se esconde nadie.
	vec3 apagada = vec3(1.0, 0.16, 0.10) * (0.10 + 0.9 * smoothstep(0.78, 0.98, r))
		* (0.6 + 0.4 * sin(TIME * 9.0));
	ALBEDO = mix(col, apagada, tapada);
}
