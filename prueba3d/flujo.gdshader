shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

// ÓRBITA — luz que corre. Va sobre una cinta: `UV.x` la cruza y `UV.y` es la
// distancia recorrida. Dibuja galones que avanzan en el sentido del tiro y dos
// filos encendidos, y es lo que hace que un carril diga hacia dónde lleva.

uniform vec3 color : source_color = vec3(0.2, 0.9, 1.0);
uniform float velocidad = 1.6;
uniform float energia = 1.4;
uniform float densidad = 5.0;
uniform float impulso = 0.0;

void fragment() {
	float lado = abs(UV.x - 0.5);
	float v = UV.y * densidad - TIME * velocidad;
	float galon = fract(v - lado * 1.4);
	float banda = smoothstep(0.0, 0.10, galon) * smoothstep(0.55, 0.30, galon);
	float dentro = smoothstep(0.46, 0.36, lado);
	float filo = smoothstep(0.36, 0.44, lado) * smoothstep(0.5, 0.46, lado);
	float luz = banda * dentro * 0.85 + filo * 0.9 + 0.05 * dentro;
	ALBEDO = color * energia * luz * (1.0 + impulso * 3.0);
}
