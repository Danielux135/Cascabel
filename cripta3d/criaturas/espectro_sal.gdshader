shader_type spatial;
// `vertex_lighting`: la luz de la cripta por vértice y no por píxel. Con la luz
// entera de Godot tardaba 6,7 s en compilar en un navegador; así, 0,83 (banco,
// ANGLE, 21-nov-2026). La sal SÍ tiene que recibir la luz de la mesa como la
// losa, y sobre todo el charco violeta del propio espectro, así que no es
// `unshaded`: la luz se queda, pero se calcula en los vértices del plano, que
// `espectro.gd` subdivide para eso (con los cuatro de las esquinas, el charco
// del centro no llegaba al cerco).
// Probado y descartado: `unshaded` con la luz propia del espectro por vértice
// (`espectro_luz.gdshaderinc` con sitio y atenuación por luz). Costaba 1,06 s:
// más que la de Godot por vértice, y había que imitarle hasta cómo suma las
// luces con sombra.
render_mode blend_mix, depth_draw_never, cull_back, vertex_lighting;

// CRIPTA — lo que el espectro tiene pintado en la losa: UN CERCO DE SAL. Es lo
// que se echa en el suelo para atrapar a un espíritu, y aquí es su indicador:
//
//   · EL MIEDO LO VA CERCANDO. Con miedo, la sal aparece por detrás (lo más
//     lejos de la cámara) y se va cerrando por los dos lados hacia delante:
//     `miedo` = 0,5 es medio cerco. Cuando se cierra delante de la cámara,
//     está ACORRALADO.
//   · ACORRALADO, el cerco está entero y se encienden cuatro RUNAS violetas
//     (es lo único violeta de la mesa, y es suyo). Y la sal se va BARRIENDO con
//     el tiempo que queda (`queda`, de 1 a 0), empezando por delante: lo
//     barrido deja un rastro de granos sueltos, y al final lo que queda tiembla.
//     Es el mismo reloj que el cerco de tiza de la calavera, en otro material.
//   · `aviso`: la sal se repasa (avisar_aro: le ha subido el miedo).
//   · `onda`: el polvo que levanta el respingo de la alerta, un anillo que se
//     abre y se posa.
//   · Una sombra muy floja, que FLOTA: lo que hay debajo es poco.
//
// La sal recibe la luz de la cripta como la losa (por vértice: ver el
// `render_mode`); solo las runas emiten.

uniform vec3 c_sal : source_color = vec3(0.96, 0.91, 0.81);
uniform vec3 c_polvo : source_color = vec3(0.63, 0.61, 0.54);
uniform vec3 c_runa : source_color = vec3(0.66, 0.48, 0.85);
uniform float radio = 0.78;
uniform float miedo = 0.0;
uniform float cerrado = 0.0;
uniform float queda = 1.0;
uniform float aviso = 0.0;
uniform float onda = 0.0;
uniform float sombra = 0.0;
uniform float semilla = 0.0;
uniform float reloj = 0.0;

// El ruido, de una textura (antes, por código: ver `espectro_ruido.gdshaderinc`).
#include "res://cripta3d/criaturas/espectro_ruido.gdshaderinc"

float ruido2(vec2 x) {
	return esp_ruido2(x);
}

// Granos: una rejilla con un grano por celda, de tamaño y sitio al azar (los
// tres azares de la celda, de una lectura).
float granos(vec2 p, float escala, float cuantos) {
	vec2 g = p * escala;
	vec2 i = floor(g);
	vec2 f = fract(g);
	vec4 az = esp_azar(i + floor(semilla * 7.0));
	float h = az.r;
	vec2 c = az.ba * 0.6 + 0.2;
	float d = length(f - c);
	return (1.0 - smoothstep(0.16 + 0.14 * h, 0.30 + 0.12 * h, d)) * step(1.0 - cuantos, h);
}

// Un trazo de runa: distancia a un segmento.
float trazo(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

float runa(vec2 p, float cual) {
	// Tres trazos: un palo y dos ramas, con el ángulo de cada runa distinto.
	float ab = 0.45 + 0.25 * fract(cual * 0.37);
	float d = trazo(p, vec2(0.0, -1.0), vec2(0.0, 1.0));
	d = min(d, trazo(p, vec2(0.0, 0.2 * (cual - 1.5)), vec2(ab, 0.75)));
	d = min(d, trazo(p, vec2(0.0, -0.3), vec2(-ab, 0.25 - 0.2 * cual)));
	// Encerrada en su círculo: así es un sello y no una raya suelta.
	d = min(d, abs(length(p) - 1.45));
	return 1.0 - smoothstep(0.07, 0.16, d);
}

// La runa `i` (0..3) del cerco, ya apagada si el barrido ha pasado por ella.
float runa_en(vec2 p, float r_cerco, float i) {
	float a = 0.785398 + i * 1.570796;
	vec2 c = vec2(sin(a), -cos(a)) * (r_cerco + 0.13);
	vec2 q = p - c;
	// Cada runa mira hacia fuera del cerco.
	vec2 fuera = normalize(c);
	vec2 lado = vec2(-fuera.y, fuera.x);
	vec2 lq = vec2(dot(q, lado), dot(q, fuera)) / 0.065;
	float a_rel = a > 3.14159265 ? a - 6.2831853 : a;
	float viva = 1.0 - smoothstep(queda, queda + 0.04, abs(a_rel) / 3.14159265);
	return runa(lq, i) * viva;
}

// LA RUGOSIDAD DE LAS LUCES, EN EL VÉRTICE (arreglo tras la gira 6). Con
// `vertex_lighting` Godot alumbra en el vértice con la rugosidad que escriba
// `vertex()`, y si no escribe nada usa 1,0 (`scene.glsl`: `float roughness =
// 1.0`): la de `fragment()` no llega. Y no hace GGX: hace un Blinn normalizado
// de exponente (1,2 − r)⁵·2000. Con 1,0 el exponente es 0,6, un brillo tan
// abierto que no es brillo, y se perdía el brillo de las luces sobre la sombra
// de debajo, que es casi negra: bajo el cuerpo la losa salía 30 niveles más
// oscura que en la gira 5 (toma `c0_v5_00`, luminancia 142 → 111).
// El GGX de antes (0,55, α = 0,30) tiene el lóbulo de un Blinn de ~20, y 20 sale
// con 0,80; los dos dan el mismo pico (~2,8·f0). Devuelve un tercio (111 → 119):
// el resto es la cola larga del GGX, que un Blinn no tiene (con 0,90, más
// abierto, sale peor: 114). Medido el 21-nov-2026.
void vertex() {
	ROUGHNESS = 0.80;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	// 0 detrás (lejos de la cámara), ±π delante.
	float ang = atan(p.x, -p.y);
	float de_detras = abs(ang) / 3.14159265;

	// --- El cerco: una banda de radio que no es de compás (se echó a mano).
	// SIN PUNTEADO. La sal se dibujaba con granos de una rejilla de 95 y 160 celdas
	// por lado: cada grano medía UN PÍXEL a 1080p, y el cerco salía como un
	// tramado de puntos blancos que hormigueaba al moverse —«el único efecto que
	// parece de otra mesa» (crítica técnica, nov-2026)—. Ahora la sal es un trazo
	// continuo con terrones grandes (ruido de 9 a 26 celdas: varios píxeles cada
	// uno) y el borde suavizado a la medida del píxel (`fwidth`).
	float r_cerco = radio + 0.025 * sin(ang * 3.0 + semilla) + 0.012 * sin(ang * 7.0 + semilla * 2.3);
	float ancho = 0.050 + 0.020 * ruido2(vec2(ang * 3.0, semilla));
	float px = max(fwidth(r), 0.002);
	float banda = 1.0 - smoothstep(ancho * 0.40, ancho + px, abs(r - r_cerco));
	float suelto = 1.0 - smoothstep(ancho, ancho * 2.4, abs(r - r_cerco));

	// Hasta dónde llega: el miedo, o entero si está acorralado.
	float hecho = max(miedo, cerrado);
	float tramo = 1.0 - smoothstep(hecho - 0.03, hecho + 0.01, de_detras);
	// Acorralado: lo barrido empieza por delante (de_detras = 1) y va hacia atrás.
	// Barrido es lo que está más adelante que `queda`: con queda = 1, nada.
	float barrido = cerrado * smoothstep(queda, queda + 0.04, de_detras);
	// Terrones: la sal echada a puñados es más espesa en unos sitios que en otros.
	float terron = ruido2(p * 9.0 + semilla) * 0.55 + ruido2(p * 26.0 + semilla * 1.7) * 0.45;
	float sal = banda * smoothstep(0.18, 0.60, terron + banda * 0.22) * 0.92;
	// Lo barrido: quedan granos sueltos, esparcidos hacia fuera. Granos GRANDES
	// (34 celdas: unos cinco píxeles), no polvo de un píxel.
	float esparcido = suelto * granos(p * 1.03 + vec2(0.11, 0.0), 34.0, 0.30);
	sal = tramo * mix(sal, esparcido * 0.8, barrido);
	// Con poco tiempo, lo que queda tiembla.
	float prisa = cerrado * (1.0 - smoothstep(0.0, 0.30, queda));
	sal *= 1.0 - prisa * 0.45 * (0.5 + 0.5 * sin(reloj * 19.0 + ang * 4.0));
	sal = clamp(sal * (0.85 + aviso * 0.8), 0.0, 1.0);

	// --- Las cuatro runas, solo acorralado. Se apagan con el tiempo, cada una
	// cuando el barrido pasa por ella. Escritas una a una y no en un bucle:
	// Direct3D lo despliega igual, en cada variante.
	float luz_runas = runa_en(p, r_cerco, 0.0) + runa_en(p, r_cerco, 1.0)
		+ runa_en(p, r_cerco, 2.0) + runa_en(p, r_cerco, 3.0);
	luz_runas *= cerrado;

	// --- El polvo de la alerta: un anillo que se abre y se posa.
	float r_onda = mix(0.25, 1.0, sqrt(onda));
	float polvo = (1.0 - smoothstep(0.0, 0.10 + 0.08 * onda, abs(r - r_onda)))
		* ruido2(p * 11.0 + semilla) * step(0.001, onda) * (1.0 - onda) * 0.85;

	// --- La sombra de debajo: floja, que flota.
	float bajo = sombra * 0.30 * (1.0 - smoothstep(0.05, 0.55, r));

	float pinta = max(sal, polvo);
	float alfa = max(max(pinta, luz_runas * 0.9), bajo * (1.0 - pinta));
	// Continua, la sal entera blanca era una raya de tiza recién pintada: los
	// terrones la ensucian hacia el polvo, que es lo que la hace sal echada.
	vec3 color = mix(c_polvo, c_sal * (0.72 + 0.28 * terron), sal / max(pinta, 0.001));
	color = mix(vec3(0.01, 0.008, 0.015), color, pinta / max(alfa, 0.001));
	color = mix(color, c_runa * 0.4, luz_runas * (1.0 - pinta));
	ALBEDO = color;
	// Esta rugosidad ya solo la usa el reflejo del cielo, que va por píxel; la de
	// las luces va en `vertex()`.
	ROUGHNESS = 0.55;
	SPECULAR = 0.35;
	// Sin granos que destellen: a un píxel cada uno, era lo que hacía hormiguear el
	// cerco. La sal solo se aviva entera cuando se repasa (`aviso`).
	EMISSION = c_runa * luz_runas * 1.1 + c_sal * aviso * sal * 0.25;
	ALPHA = alfa * (1.0 - smoothstep(0.97, 1.0, r));
}
