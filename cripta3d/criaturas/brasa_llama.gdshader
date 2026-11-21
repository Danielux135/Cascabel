shader_type spatial;
// Sin iluminar, translúcida en el canto y con el alfa PREMULTIPLICADO: el color
// que sale ya va multiplicado por su opacidad, así que donde el alfa baja y el
// color no, el fuego SUMA luz a lo de detrás (el borde aditivo) sin dejar de
// tapar lo que tiene detrás donde es espeso. La pasada previa de profundidad
// hace que de cada lengua solo se pinte la cara de delante: sin ella, una lengua
// de detrás se pintaba encima de una de delante y se veían láminas cruzadas.
render_mode unshaded, blend_premul_alpha, depth_prepass_alpha, cull_back, shadows_disabled;

// CRIPTA 3D — BRASA: la LLAMA, sus dos capas: la MELENA (la corona entera) y el
// NÚCLEO (la llama clara de dentro, que es la cara). `es_nucleo` dice cuál es.
//
// UN SOLO SOMBREADOR PARA LAS DOS (web, 21-nov-2026). Eran dos, y cada uno pagaba
// al compilar su `brasa_mover` en el vértice: en el navegador (ANGLE → Direct3D)
// eso solo son ~0,3 s por sombreador, y el núcleo, con el ruido ya leído de una
// textura, seguía en 0,8 s por el movimiento (sin él, 0,47). ANGLE compila el
// vértice y el píxel a la vez y cuesta el más caro de los dos: juntas, las dos
// capas compilan en 1,0 s; eran 2,5 + 1,1. El núcleo era opaco y aquí sale con
// alfa 1, que con el alfa premultiplicado es lo mismo (tapa y no suma); va un
// puesto antes que la melena (`render_priority`, en `brasa.gd`) para que ella se
// pinte encima.
//
// Es luz, no superficie (ver `brasa_fuego.gdshaderinc`): el color sale de la
// altura y de un ruido que sube. Encima, en la melena, dos cosas que la hacen
// fuego y no vinilo:
//   · EL CANTO, por Fresnel: donde la piel se mira de lado, la llama es fina, y
//     ahí se vuelve transparente y suma luz, en vez de cerrarse en un filo rojo
//     opaco (lo que la hacía capucha);
//   · LAS PUNTAS se desvanecen en vez de cortarse: el alfa se va con la lengua,
//     con el ruido encima, y la punta parpadea.
//
// LA MELENA LLEVA UNA VENTANA: por delante se abre y deja ver el núcleo, que es
// la cara. El hueco viene ya cortado en la malla (más pequeño), y aquí el alfa se
// va a cero ANTES de llegar a él: no hay filo, la melena se desvanece sobre la
// cara, que a esa altura es del mismo color. La forma de la ventana es la MISMA
// cuenta que `ancho_ventana` en el guion de Blender: si se toca una, se toca la
// otra.
//
// EL NÚCLEO es la zona amarilla del centro del sprite. Opaco —es lo más espeso
// del fuego y lleva los ojos encima— y con el MISMO degradado por altura que la
// melena, un punto más caliente: donde la melena se desvanece sobre la cara no
// queda filo. Se mueve la mitad (una cara que baila no se lee) y no se le abre
// ningún agujero.

#include "res://cripta3d/criaturas/brasa_fuego.gdshaderinc"

// 0 la melena, 1 el núcleo.
uniform float es_nucleo = 0.0;
// Cuánto se mueve: la melena entera (1), el núcleo algo más de la mitad (0,55).
uniform float cuanto = 1.0;
// La ventana, en el marco de la malla: medio ancho, y de abajo, y donde empieza
// a cerrarse, y de la punta. Se la pone `brasa.gd` según dónde caen los ojos.
uniform vec4 cara = vec4(0.092, 0.054, 0.151, 0.200);
// La opacidad general de la melena: al prender y al colarse en la bola.
uniform float opacidad = 1.0;
// El punto más caliente del núcleo (entre los ojos, un poco por debajo) y su tamaño.
uniform float foco_radio = 0.060;
uniform vec3 foco = vec3(0.0, 0.10, 0.07);

varying vec3 reposo;
varying vec3 normal_reposo;
varying vec4 dato;

void vertex() {
	reposo = VERTEX;
	normal_reposo = NORMAL;
	dato = COLOR;
	VERTEX = brasa_mover(VERTEX, NORMAL, COLOR.g, COLOR.b, cuanto);
}

// Cuánto de la ventana es este punto: 1 dentro, 0 fuera, con un margen ancho
// por fuera para que la melena se desvanezca sobre la cara y no la recorte.
float ventana(vec3 p, vec3 n, float roce) {
	float t = clamp((p.y - cara.z) / (cara.w - cara.z), 0.0, 1.0);
	float ancho = cara.x * pow(1.0 - t, 0.8);
	// Redonda por abajo: la barbilla.
	ancho *= sqrt(clamp((p.y - cara.y) / 0.034, 0.0, 1.0));
	ancho += roce;
	float dentro = 1.0 - smoothstep(ancho - 0.010, ancho + 0.034, abs(p.x));
	dentro *= smoothstep(cara.y - 0.004, cara.y + 0.020, p.y);
	// Solo lo que mira hacia delante: la espalda no se abre.
	return dentro * smoothstep(-0.05, 0.30, n.z) * smoothstep(-0.03, 0.01, p.z);
}

void fragment() {
	vec3 p = reposo;
	float lengua = dato.g;
	float h = brasa_alto(p.y);
	// La veta grande es la misma cuenta en las dos capas, cada una con su escala y
	// su paso (las dos son 0 o 1: `mix` da el número exacto de antes).
	float n = brasa_veta(p, mix(21.0, 19.0, es_nucleo), mix(1.6, 0.9, es_nucleo),
		mix(0.30, 0.35, es_nucleo));
	float veta = n;
	float q;
	if (es_nucleo > 0.5) {
		vec3 d = p - foco;
		float centro = exp(-dot(d, d) / (foco_radio * foco_radio));
		// El punto caliente de la cara empuja al AMARILLO del sprite (no al blanco:
		// `brasa_color` ya no pasa de oro claro).
		q = brasa_temperatura(h, lengua, veta) + 0.02 + 0.20 * centro;
		// Donde se mete en el cráter se enfría un poco: la sombra de la barbilla.
		q -= (1.0 - smoothstep(pie, pie + 0.035, p.y)) * 0.16;
	} else {
		float fino = brasa_veta(p, 57.0, 2.7, 0.5);
		veta = n * 0.75 + fino * 0.25;
		q = brasa_temperatura(h, lengua, veta);
		// Lo hundido entre lenguas, un poco más frío: el volumen sin sombrear.
		q -= 0.08 * (1.0 - dato.r);
	}
	// El color, una vez para las dos (el fogonazo pesa algo menos en la cara).
	vec3 col = brasa_fogonazo(brasa_color(q), mix(1.0, 0.8, es_nucleo));

	if (es_nucleo > 0.5) {
		ALBEDO = col;
		ALPHA = 1.0;
	} else {
		// --- La opacidad. Espesa en el cuerpo; en el canto (Fresnel) y en las puntas
		// se vuelve luz que se suma.
		// Con tope: por redondeo puede dar 1,0000001, y `pow` de un negativo es
		// NaN (un píxel sin alfa justo donde se mira la llama de frente).
		float de_frente = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
		float canto = pow(1.0 - de_frente, 2.2);
		float a = 1.0 - 0.80 * canto;
		// Las puntas se van, cada una a su ritmo: el ruido que sube se come el alfa.
		float se_va = smoothstep(0.35, 1.0, lengua + (veta - 0.5) * 0.45);
		a *= 1.0 - 0.92 * se_va;
		// LO ROTO. Arriba la llama se deshace en jirones que SUBEN: un ruido estirado
		// en vertical, que viaja hacia arriba más deprisa que las vetas, se come el
		// alfa cuanto más alto y más lengua es el punto. Sin esto la melena era una
		// piel cerrada y lisa —la crítica la llamó tulipán y pantalla de lámpara—: una
		// llama de verdad tiene el borde de arriba abierto, roto y nunca igual. Abajo
		// (la cara, la barbilla) no se come nada.
		float jiron = brasa_veta(p + vec3(1.7, 0.0, 2.9), 13.0, 3.1, 0.35);
		float jiron_fino = brasa_veta(p + vec3(4.3, 0.0, 0.7), 34.0, 4.2, 0.45);
		float masa = jiron * 0.72 + jiron_fino * 0.28;
		float come = smoothstep(0.40, 1.0, h) * 0.62 + smoothstep(0.30, 1.0, lengua) * 0.30;
		float queda = smoothstep(come - 0.07, come + 0.05, masa + 0.12);
		queda = mix(1.0, queda, step(0.001, come));
		a *= queda;
		// Donde se rompe, el filo arde un punto más: es gas caliente, no un recorte.
		float filo_roto = queda * (1.0 - queda) * 4.0 * step(0.001, come);

		// La ventana de la cara, con su borde roído por el mismo ruido.
		a *= 1.0 - ventana(p, normal_reposo, (n - 0.5) * 0.030);
		// Abajo, donde se mete en el cráter, se funde con el carbón en vez de cortarse.
		a *= smoothstep(pie - 0.004, pie + 0.022, p.y);
		a = clamp(a * opacidad, 0.0, 1.0);

		// Lo que suma: el canto y las puntas brillan un poco MÁS que su color, como un
		// filo de gas caliente, aunque ya casi no tapen.
		// Abajo no: el bajo de la llama se curva hacia dentro, sobre el carbón, y su
		// canto encendido salía como el filo claro de una taza.
		float suma = (canto * 0.55 * smoothstep(pie + 0.02, pie + 0.08, p.y) + se_va * 0.35
			+ filo_roto * 0.45) * opacidad;
		ALBEDO = col * (a + suma * (1.0 - a));
		ALPHA = a;
	}
}
