shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled;

// CRIPTA 3D — BRASA: el NÚCLEO. La llama clara de dentro, que es la cara.
//
// Es la zona amarilla del centro del sprite. Opaca —es lo más espeso del fuego y
// lleva los ojos encima— y con el MISMO degradado por altura que la melena, un
// punto más caliente: donde la melena se desvanece sobre la cara no queda filo,
// porque a esa altura las dos son del mismo color. Se mueve la mitad que la
// melena (una cara que baila no se lee) y no se le abre ningún agujero.

#include "res://cripta3d/criaturas/brasa_fuego.gdshaderinc"

// El punto más caliente (entre los ojos, un poco por debajo) y su tamaño.
uniform float foco_radio = 0.060;
uniform vec3 foco = vec3(0.0, 0.10, 0.07);

varying vec3 reposo;
varying vec4 dato;

void vertex() {
	reposo = VERTEX;
	dato = COLOR;
	VERTEX = brasa_mover(VERTEX, NORMAL, COLOR.g, COLOR.b, 0.55);
}

void fragment() {
	vec3 p = reposo;
	float lengua = dato.g;
	float h = brasa_alto(p.y);
	float veta = brasa_veta(p, 19.0, 0.9, 0.35);
	vec3 d = p - foco;
	float centro = exp(-dot(d, d) / (foco_radio * foco_radio));
	// El punto caliente de la cara empuja al AMARILLO del sprite (no al blanco:
	// `brasa_color` ya no pasa de oro claro).
	float q = brasa_temperatura(h, lengua, veta) + 0.02 + 0.20 * centro;
	// Donde se mete en el cráter se enfría un poco: la sombra de la barbilla.
	q -= (1.0 - smoothstep(pie, pie + 0.035, p.y)) * 0.16;
	ALBEDO = brasa_fogonazo(brasa_color(q), 0.8);
}
