shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, fog_disabled;

// CRIPTA — LO QUE EL ESPECTRO SUMA DE LUZ: la luz violeta que echa en la losa y
// las volutas de su humo. Suma luz (blend_add) y poca: lo de un espectro alumbra,
// no tapa.
//
// UN SOLO SOMBREADOR PARA LAS DOS COSAS (21-nov-2026, para la web). Eran dos
// (`espectro_brillo` y `espectro_humo`) con el mismo modo y nada de luz; en un
// navegador cada sombreador se compila entero cuatro o cinco veces, y juntos
// cuestan 0,2 s menos que por separado (banco, ANGLE). El material de las
// volutas lleva `es_humo` = 1 y elige la rama (solo lee uniformes: toda la malla
// va por la misma). El de la losa ya no descarta las caras de atrás: es un
// plano tumbado que se mira desde arriba y está fuera del reflejo.
//
// LA LUZ EN LA LOSA (es_humo = 0):
//   · `charco`: un poco de luz bajo él, que se suma a la de su OmniLight. La
//     luz de verdad alumbra la piedra con su relieve; esto solo le da cuerpo
//     al centro, donde la luz omni cae de canto.
//   · `filtra`: ESCONDIDO no se le ve; solo una luz que corre POR DEBAJO del
//     suelo y se cuela por las grietas y las juntas de las losas. Las grietas
//     van en coordenadas de MUNDO, así que la luz pasa por debajo de ellas
//     como una linterna bajo un entarimado, en vez de llevarlas pegadas.
//
// UNA VOLUTA (es_humo = 1): el rastro que deja, el humo del que cuaja al
// aparecer y los fuegos fatuos de cuando está aturdido. Una tarjeta que mira a
// la cámara, con la redondez y las hebras calculadas aquí. Sin textura de forma
// a propósito: con un `GradientTexture2D` redondo y el modo «billboard de
// partículas» de StandardMaterial3D, las volutas salían como CUADRADOS blancos
// (19-nov-2026).
//
// El ruido de las dos se lee de `espectro_ruido.png` (antes era por código: ver
// `espectro_ruido.gdshaderinc`).

uniform float es_humo = 0.0;
uniform vec3 color : source_color = vec3(0.66, 0.48, 0.85);
// La losa.
uniform float charco = 0.0;
uniform float filtra = 0.0;
uniform float reloj = 0.0;
uniform float semilla = 0.0;
// Las volutas.
uniform float fuerza = 0.25;
uniform float hebras = 1.0;
// 1 = tarjeta de partícula (la orienta su instancia), 0 = MeshInstance suelta.
uniform float particula = 1.0;

#include "res://cripta3d/criaturas/espectro_ruido.gdshaderinc"

varying vec3 mundo;
varying float azar;

// Grietas: el ruido "con cresta" (1 − |2n − 1|) afilado deja líneas finas.
// Finas y pocas: con más, la mancha entera era una red de relámpagos (neón).
float grietas(vec2 p) {
	float n1 = 1.0 - abs(esp_ruido2(p * 8.0) * 2.0 - 1.0);
	float n2 = 1.0 - abs(esp_ruido2(p * 19.0 + 4.3) * 2.0 - 1.0);
	return pow(n1, 16.0) * 0.8 + pow(n2, 22.0) * 0.35;
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	azar = 0.0;
	if (es_humo > 0.5) {
		// Mirando a la cámara, conservando la escala de la partícula.
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
			INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
		azar = fract(sin(dot(MODEL_MATRIX[3].xyz, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
	}
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (es_humo > 0.5) {
		float suave = exp(-r * r * 3.2) * (1.0 - smoothstep(0.75, 1.0, r));
		// Hebras: el borde de la voluta se deshilacha (cada una a su manera).
		float h = esp_ruido2(p * 3.5 + azar * 17.0) * 0.6 + esp_ruido2(p * 8.0 - azar * 9.0) * 0.4;
		suave *= mix(1.0, smoothstep(0.15, 0.75, h + (1.0 - r) * 0.5), hebras);
		vec4 col = mix(vec4(1.0), COLOR, particula);
		ALBEDO = color * col.rgb * col.a * suave * fuerza;
	} else {
		float suave = exp(-r * r * 4.5);
		float c = charco * suave * 0.22;
		// Escondido: un resplandor difuso por las juntas y las grietas, que late.
		float junta = grietas(mundo.xz + vec2(semilla));
		float late = 0.75 + 0.25 * sin(reloj * 3.3) * sin(reloj * 1.7 + 1.0);
		float f = filtra * (exp(-r * r * 7.0) * 0.16 + junta * exp(-r * r * 6.5) * 0.50) * late;
		ALBEDO = color * (c + f);
	}
	ALPHA = 1.0;
}
