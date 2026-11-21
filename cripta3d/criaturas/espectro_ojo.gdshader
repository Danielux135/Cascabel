shader_type spatial;
// `unshaded`: la luz se la pone `espectro_luz.gdshaderinc`. Con la de Godot
// tardaba 6,5 s en compilar en un navegador (banco, ANGLE, 21-nov-2026).
render_mode blend_mix, cull_back, unshaded;

// CRIPTA — un OJO del espectro. Los tres son el personaje: globos blancos con la
// pupila negra, como en el sprite. El globo es una esfera de verdad metida en su
// cuenca; todo lo demás se dibuja aquí, en el marco del propio globo (z hacia
// fuera de la piel, y hacia arriba):
//
//   · LOS PÁRPADOS son de la misma gelatina que el cuerpo y tapan el globo por
//     arriba y por abajo. `abre` = 1 es el ojo normal; 0, cerrado (parpadeo,
//     golpe); por encima de 1, desorbitado (alerta, miedo). Tienen forma de
//     almendra: más abiertos en el centro que en los rabillos.
//   · LA PUPILA mira hacia `mirada` (unitario, en el marco del globo) y mide
//     `pupila` (radianes): con miedo se encoge a un punto.
//   · UN BRILLO húmedo fijo en la vista, además del que pongan las luces: sin
//     él, desde arriba y con poca luz, el ojo se quedaba en una canica gris.
//   · El blanco emite un poco: en la cripta hay rincones sin luz y los ojos
//     tienen que leerse siempre, también de lejos.

uniform vec3 c_blanco : source_color = vec3(0.89, 0.90, 0.93);
uniform vec3 c_sombra : source_color = vec3(0.55, 0.55, 0.60);
uniform vec3 c_pupila : source_color = vec3(0.078, 0.071, 0.10);
uniform vec3 c_parpado : source_color = vec3(0.42, 0.25, 0.62);
uniform vec3 c_parpado_luz : source_color = vec3(0.66, 0.48, 0.85);
uniform vec3 mirada = vec3(0.0, 0.0, 1.0);
uniform float pupila = 0.40;
uniform float abre = 1.0;
uniform float destello = 0.0;
uniform float palidez = 0.0;
// Cuánto se BAJA el párpado de abajo (radianes). El ojo de arriba mira al techo,
// y de frente lo que se le ve es justo la parte de abajo del globo: con el
// párpado de los otros, de frente parecía un ojo medio dormido.
uniform float bajo_libre = 0.0;

#include "res://cripta3d/criaturas/espectro_luz.gdshaderinc"

varying vec3 pos_obj;
// Hacia dónde mira el globo, en el espacio de la vista.
varying vec3 frente_vista;

void vertex() {
	pos_obj = VERTEX;
	frente_vista = normalize((MODELVIEW_MATRIX * vec4(0.0, 0.0, 1.0, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(pos_obj);
	// Lo hondo del globo, metido en la gelatina, no se pinta: la masa es
	// translúcida y su silueta se transparentaba como un aro alrededor del ojo.
	// (El globo entra en la piel a 0,28 de radio por encima de su centro: lo que
	// está por debajo de 0,12 no se ve nunca de frente. Con el corte en −0,12,
	// de espaldas asomaba el ecuador como un anillo.)
	if (n.z < 0.12) {
		discard;
	}
	// --- Los párpados: por el ángulo alrededor del eje x (0 de frente, + arriba).
	float a = atan(n.y, max(n.z, -1.0));
	float ab = clamp(abre, 0.0, 1.6);
	// El de arriba va ALTO: la cámara de juego mira desde arriba y lo que ve del
	// globo es justo su casquete de arriba. Con el párpado a media altura, de
	// lejos los tres ojos eran tres medias lunas grises. El de abajo cubre más,
	// que es lo que la cámara no ve (y le da cara de cansado, que le va).
	float sup = -0.20 + 1.55 * ab - 0.50 * n.x * n.x;
	float inf = -0.55 * min(ab, 1.0) - 0.35 * max(ab - 1.0, 0.0) + 0.40 * n.x * n.x
		- bajo_libre * min(ab, 1.0);
	float en_parpado = max(smoothstep(sup - 0.02, sup + 0.02, a),
		1.0 - smoothstep(inf - 0.02, inf + 0.02, a));
	// Lo de detrás del globo es párpado siempre (queda dentro de la cuenca).
	en_parpado = max(en_parpado, 1.0 - smoothstep(-0.15, 0.05, n.z));
	// Y lo que queda DENTRO de la gelatina es oscuro como su interior: la masa es
	// translúcida, y un globo entero pálido se transparentaba como un aro
	// alrededor de cada ojo.
	float dentro = 1.0 - smoothstep(-0.30, 0.10, n.z);
	float filo = 1.0 - smoothstep(0.0, 0.10, min(abs(a - sup), abs(a - inf)));

	// --- La pupila, algo ovalada en vertical.
	vec3 m = normalize(mirada);
	vec3 der = normalize(cross(vec3(0.0, 1.0, 0.0), m) + vec3(0.0001));
	vec3 arr = cross(m, der);
	vec2 q = vec2(dot(n, der) / 0.82, dot(n, arr));
	float r = length(q) * step(0.0, dot(n, m));
	float rp = sin(pupila);
	float es_pupila = (1.0 - smoothstep(rp - 0.025, rp + 0.01, r)) * step(0.0, dot(n, m));
	float aro = (1.0 - smoothstep(rp + 0.02, rp + 0.10, r)) * (1.0 - es_pupila) * step(0.0, dot(n, m));

	// --- El blanco: más gris hacia el canto y a la sombra del párpado de arriba,
	// y con un tinte LILA en el borde, que es la gelatina que lo envuelve
	// trasluciéndose. Sin él, el globo era una bola de billar blanca y dura.
	float canto = smoothstep(0.15, 0.85, n.z);
	float bajo_parpado = smoothstep(sup - 0.45, sup - 0.02, a);
	vec3 lila = mix(c_sombra, c_parpado_luz, 0.55);
	vec3 blanco = mix(lila, c_blanco, canto * 0.80 + 0.20) * (1.0 - 0.35 * bajo_parpado);
	blanco = mix(blanco, c_sombra * 0.8, aro * 0.35);
	vec3 ojo = mix(blanco, c_pupila, es_pupila);

	// EL OJO CERRADO es un párpado sobre el globo, con la raya por donde se
	// juntan. Sin la raya, un ojo cerrado era una bola violeta en una cuenca: un
	// aro vacío que parecía un fallo.
	float medio = (sup + inf) * 0.5;
	float juntos = 1.0 - smoothstep(0.08, 0.45, sup - inf);
	float raya = (1.0 - smoothstep(0.015, 0.06, abs(a - medio))) * juntos * en_parpado;

	vec3 parpado = mix(c_parpado * 0.65, c_parpado_luz, 0.25 + 0.35 * (n.y * 0.5 + 0.5));
	// Con miedo, el párpado palidece como el cuerpo: hacia el arcano claro, no al blanco.
	parpado = mix(parpado, mix(c_parpado_luz, c_blanco, 0.2), palidez * 0.45);
	parpado = mix(parpado, c_pupila, raya * 0.85);
	// (El tono de la gelatina por dentro, no negro: de espaldas se veían tres
	// discos oscuros dentro de la cabeza.)
	parpado = mix(parpado, mix(c_parpado, c_parpado_luz, 0.25) * 0.55, dentro);
	// Poco albedo y bastante emisión, con el sombreado ya puesto (el de arriba):
	// los ojos se tienen que leer en cualquier rincón de la cripta, también de
	// lejos, y el fuego por un lado y la luna por el otro partían el globo en
	// dos tonos.
	vec3 albedo = mix(ojo * 0.45, parpado * 0.35, en_parpado);
	// Húmedo, no esmaltado: con 0,12 de rugosidad y especular 0,6 cada ojo era
	// una bola de billar con su reflejo de ventana. (Los dos van a `luz_propia`.)
	float rugosidad = mix(mix(0.32, 0.20, es_pupila), 0.50, en_parpado);
	// Y poco especular: el cielo se reflejaba partido en dos en el blanco.
	float especular = mix(0.12, 0.08, en_parpado);

	// --- El brillo húmedo, fijo en la vista, arriba a la izquierda: pequeño.
	float brillo = smoothstep(0.980, 0.992, dot(NORMAL, normalize(vec3(-0.38, 0.52, 0.76))));
	// El párpado alumbra como la gelatina del cuerpo (que es emisiva): más
	// apagado, era una copa granate bajo cada ojo.
	vec3 em = ojo * 0.62 * (1.0 - en_parpado) + parpado * 0.55 * en_parpado;
	em += vec3(1.0) * brillo * (1.0 - en_parpado);
	em += c_parpado_luz * filo * en_parpado * (1.0 - juntos) * 0.30;
	em += c_parpado_luz * en_parpado * (1.0 - dentro) * pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0) * 0.5;
	// VISTO POR DETRÁS (a través de la gelatina) el globo se funde con el humo
	// de dentro: de espaldas se veían tres cuencos de borde duro en la cabeza.
	float detras = smoothstep(0.15, -0.35, dot(frente_vista, normalize(VIEW)));
	vec3 humo = mix(c_parpado, c_parpado_luz, 0.35 + 0.3 * palidez);
	albedo = mix(albedo, humo * 0.15, detras);
	especular = mix(especular, 0.0, detras);
	ALBEDO = luz_propia(albedo, mix(em, humo * 0.32, detras) + vec3(destello * 1.2),
		normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz),
		normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz), especular, rugosidad);
}
