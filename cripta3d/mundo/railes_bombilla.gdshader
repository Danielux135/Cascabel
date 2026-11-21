shader_type spatial;
// SIN LUZ DE GODOT (21-nov-2026, para la web). Con la luz entera (burley + GGX)
// este sombreador tardaba 6,5 s en compilar con ANGLE, en frío: más que
// cualquier otra pieza del mundo, para unas bombillas que miden de 3 a 6 px en la
// cámara de juego y que brillan solas. Sin luz son 0,5 s. Lo que le daba la luz
// de verdad al cristal (que el apagado se lea como vidrio pardo y no como un
// agujero, y sus reflejos) se hace aquí a mano: ver `luz_cristal` y `fragment`.
render_mode unshaded, blend_mix, depth_draw_opaque, cull_back;

// LA BOMBILLA de los raíles y de las flechas de boca: vidrio ámbar con su
// filamento. Es el único sombreador propio de «railes», y existe por una sola
// razón: las bombillas se encienden EN CADENA. Con un material por bombilla
// serían doscientos materiales y doscientas llamadas de dibujo.
//
// Y UN SOLO MATERIAL PARA TODAS. Antes había uno por recorrido y otro por flecha
// (diez materiales), y como cada trozo de malla con bombillas de un recorrido
// distinto era otra superficie, solo las bombillas eran unas veinte llamadas de
// dibujo. Ahora cada bombilla dice en su `UV2` dos cosas:
//   UV2.x  «orden»: los píxeles de recorrido a los que está, o su sitio a lo
//          largo de la flecha
//   UV2.y  de qué GUÍA es (el índice del recorrido; su flecha, ese índice + 8)
// y el estado de cada guía va en las listas de abajo, una casilla por guía. Así
// las bombillas de todos los recorridos que caen en el mismo trozo de mesa van en
// la misma superficie.
//
// Tres maneras de encenderse, que se suman:
//   · reposo     el rescoldo de siempre: una bombilla apagada en la oscuridad se
//                lee como un cristal ámbar, no como un agujero
//   · corre      una ola que corre hacia la boca (las flechas): `velocidad` olas
//                por segundo, separadas `periodo` unidades de orden
//   · cadena     encendidas de la boca a la bola (`cabeza`), apagándose detrás
//                de ella en `estela` píxeles: la luz va CON la bola
// Y `fogonazo` las enciende todas a la vez (el destello al entrar).

const int GUIAS = 16;

uniform vec3 vidrio : source_color = vec3(0.26, 0.11, 0.03);
uniform vec3 luz_ambar : source_color = vec3(1.0, 0.50, 0.12);
uniform vec3 luz_clara : source_color = vec3(1.0, 0.86, 0.55);
uniform vec3 tinte : source_color = vec3(1.0);
uniform float energia = 4.0;
uniform float periodo = 1.0;
uniform float estela = 140.0;
// El reloj lo da el módulo (`mundo.tiempo`) y no TIME: así la ola va a paso
// fijo con el resto del mundo y las capturas salen iguales cada vez.
uniform float reloj = 0.0;
uniform float reposo[16];
uniform float corre[16];
uniform float velocidad[16];
uniform float cadena[16];
uniform float cabeza[16];
uniform float fogonazo[16];

// LA LUZ QUE LE PONÍA GODOT, A MANO. Lo que hace que una bombilla apagada se
// lea como VIDRIO y no como plástico mate son sus reflejos: con la luz de verdad
// (gira5, piezas/09) cada una tenía un destello blanco ancho pegado al borde de
// arriba —los braseros, al fondo— y dos o tres puntos blancos abajo —el relleno
// del lado del jugador y el fuego de la derecha—, y entre ellos el cuerpo pardo.
// Medido en las seis apagadas de la 09 (círculo de 15 px): el 5 % más claro, a
// 163–187 de luminancia, y 17–24 px por encima de 200 en cada una.
//   · `luz_cristal` es la luz que recibe el vidrio (en lineal), más por arriba;
//   · `punto`, `apretado` y `hacia_punto`: el destello de arriba, fijo a la
//     dirección de los braseros vistos desde las flechas (bajos y al fondo);
//   · `punto_bajo`, `apretado_bajo` y `hacia_bajo`: el punto de abajo a la
//     izquierda, el relleno que viene del lado del jugador (alto y de frente).
//     Solo lo lleva la apagada (en la encendida no se vería).
// Las direcciones son de MUNDO, así que el reflejo se mueve con la cámara como
// uno de verdad. Se calibraron con una pasada de diagnóstico (cada punto
// pintado de un color, lóbulo ancho) y dos de ajuste: la cúpula asoma poco de
// su copa, y un punto que cae en la parte tapada no se ve.
// *Probado y quitado:* el segundo punto de abajo, a la derecha (el fuego de esa
// banda). En tres direcciones distintas no llegó a pintar ni un píxel.
//
// LA PRIMERA VERSIÓN (gira6) se quedó en «plástico»: un solo punto, de
// exponente 260 y brillo 0,9, que a 30 px de bombilla no llega a pintar ni un
// píxel (en el centro de la esfera la normal gira 3,8° por píxel, y ese lóbulo
// mide 2°): 0 px por encima de 150, p95 de 78–87. Ahora el brillo pasa de 1 y
// se recorta, como el del GGX, y el lóbulo es más ancho: 133–178 de p95 y
// 18–22 px por encima de 200 (la luz de Godot con las luces de hoy: 127–165 y
// 12–18; en gira5, 163–187 y 17–24).
// El punto de abajo, con un lóbulo de 300, tampoco salía: este cristal es una
// esfera de seis lados y seis anillos, y un lóbulo tan fino cae entre píxeles.
// Con 60 y brillo 6 sale de 2–3 px, saturado.
// *Probado y quitado:* un lustre blanco y ancho alrededor del punto (agrisaba el
// cristal, que es pardo rojizo y saturado) y un destello de exponente 28–45
// (una mancha lechosa en mitad de la cúpula: el de verdad está en el borde).
uniform vec3 luz_cristal = vec3(1.3, 0.72, 0.45);
uniform float cristal_bajo = 0.35;
uniform float cristal_alto = 1.35;
// Lo que se oscurece el vidrio visto de canto.
uniform float canto = 0.55;
uniform float punto = 6.0;
uniform float apretado = 150.0;
uniform vec3 hacia_punto = vec3(-0.38, 0.37, -0.85);
uniform float punto_bajo = 6.0;
uniform float apretado_bajo = 60.0;
uniform vec3 hacia_bajo = vec3(-0.34, 0.386, 0.857);

varying float v_luz;

// Godot pasa ALBEDO y EMISSION de sRGB a lineal antes de sumar la luz; sin luz,
// ALBEDO es lo único que pinta. Para que el vidrio iluminado y el filamento se
// sumen igual que antes, se suman en lineal y se devuelven a sRGB.
vec3 a_lineal(vec3 c) {
	return mix(pow((c + 0.055) / 1.055, vec3(2.4)), c / 12.92, lessThan(c, vec3(0.04045)));
}

vec3 a_srgb(vec3 c) {
	return mix(1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, c * 12.92, lessThan(c, vec3(0.0031308)));
}

void vertex() {
	float orden = UV2.x;
	int g = clamp(int(UV2.y + 0.5), 0, GUIAS - 1);
	float l = reposo[g];
	float f = fract(reloj * velocidad[g] - orden / max(periodo, 0.001));
	l += corre[g] * pow(1.0 - f, 3.0);
	float tras = cabeza[g] - orden;
	// Un pelo por delante de la bola ya se enciende: si no, se ve a la bola
	// empujando la luz en vez de llevarla.
	l += cadena[g] * smoothstep(-14.0, 0.0, tras) * exp(-max(tras, 0.0) / max(estela, 1.0));
	l += fogonazo[g];
	v_luz = clamp(l, 0.0, 1.8);
}

void fragment() {
	// El filamento se ve por el centro del cristal; el borde es vidrio.
	float frente = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float filamento = frente * frente * frente;
	float l = clamp(v_luz, 0.0, 1.0);
	vec3 color_luz = mix(luz_ambar, luz_clara, filamento * l);
	vec3 albedo = mix(vidrio, luz_ambar * 0.55, l) * tinte;
	vec3 emision = color_luz * tinte * v_luz * energia * (0.55 + 0.45 * filamento);
	float arriba = 0.5 + 0.5 * (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y;
	vec3 r = reflect(-VIEW, NORMAL);
	vec3 h1 = normalize((VIEW_MATRIX * vec4(hacia_punto, 0.0)).xyz);
	vec3 h2 = normalize((VIEW_MATRIX * vec4(hacia_bajo, 0.0)).xyz);
	// Encendida, el destello casi no se suma: ya es blanca y la luz de Godot
	// tampoco la cambiaba (229,6 → 229,8 en la A/B).
	float brillo = pow(max(dot(r, h1), 0.0), apretado) * punto * (1.0 - 0.7 * l);
	float bajo = pow(max(dot(r, h2), 0.0), apretado_bajo) * punto_bajo * (1.0 - l);
	vec3 cuerpo = a_lineal(albedo) * luz_cristal * mix(cristal_bajo, cristal_alto, arriba)
		* mix(canto, 1.0, frente);
	// Los brillos se recortan a 2 (en lineal): pasan del blanco, como el GGX,
	// pero sin llegar al umbral del resplandor de todo el cristal.
	ALBEDO = a_srgb(cuerpo + a_lineal(emision) + vec3(min(brillo, 2.0))
		+ luz_clara * min(bajo, 2.0));
}
