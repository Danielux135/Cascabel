shader_type spatial;
// Translúcido con prepaso de profundidad: la gelatina se tapa a sí misma bien
// (sin él, los goterones de detrás se pintaban encima de la panza) y aun así
// deja ver un poco la losa.
// `unshaded`: la luz se la pone `espectro_luz.gdshaderinc` (con la de Godot
// tardaba 7,8 s en compilar en un navegador; ver `espectro_gel.gdshaderinc`).
render_mode blend_mix, depth_prepass_alpha, cull_back, unshaded;
// La gelatina SÍ lleva el brillo de las luces (el GGX de `espectro_luz`). Se le
// quitó por ser «un 1 % de la luz» y era verdad contra la LUZ, pero no contra la
// piel, que tiene un albedo de 0,01 en lineal: con SPECULAR 0,12 el brillo de
// cara es tan fuerte como el difuso, y en el filo, con el Fresnel, cincuenta
// veces más. En la mesa era el brillo cálido y blanquecino de la coronilla que
// cogía del fuego de delante, y el filo claro de los jirones y del labio de los
// ojos: sin él, la gelatina salía mate y lila plana (crítica de la gira 6, toma
// `c0_v5_00`: en lo alto del cuerpo la desviación de la luminancia bajó de 28,7
// a 22,1 y el percentil 95, de 146 a 117). Cuesta ~0,2 s de compilar.

// CRIPTA — LA GELATINA del espectro: la masa con su faldón, los seis jirones y
// las gotas que suelta. El color es el de `espectro_gel.gdshaderinc`; aquí, cómo
// se mueve la piel.
//
// UN SOLO SOMBREADOR PARA LA MASA Y LOS JIRONES (21-nov-2026, para la web). Eran
// dos (`espectro_cuerpo` y `espectro_zarcillo`) con el mismo color y distinto
// vértice; en un navegador cada sombreador se compila entero cuatro o cinco
// veces, y juntos cuestan 0,45 s menos que por separado (banco, ANGLE). El
// material de cada jirón lleva `jiron` = 1 y elige la rama; las dos ramas solo
// leen uniformes, así que todos los píxeles de una malla van por la misma.
//
// LA MASA (jiron = 0):
//   · TIEMBLA COMO GELATINA: dos ondas lentas que no paran nunca y, con miedo,
//     un temblor rápido y menudo (`temblor`).
//   · EL FALDÓN (color de vértice B: 1 en la punta de cada goterón) ondea solo
//     y SE QUEDA ATRÁS: `arrastre` es hacia dónde lo tira la marcha, ya en el
//     espacio de la malla (lo calcula `espectro.gd`).
//   · `encoge` recoge el faldón hacia la panza: acorralado, se hace una bola.
//
// UN JIRÓN (jiron = 1; la pieza se llama zarcillo). La malla es una CINTA RECTA
// a lo largo de su +X (ancha en Y, fina en Z, la raíz en el origen, metida en la
// masa); la curva se la pone este sombreador, y se deshace hacia la punta con el
// mismo fundido en hebras que el faldón.
//   · CÓMO SE RIZA. El ángulo de la tangente crece a lo largo del jirón:
//         ángulo(s) = rizo0·s + rizo1·s² + una onda que viaja de la raíz a la punta
//     y la línea del centro es la integral de esa tangente. Esa integral la suma
//     `espectro.gd` UNA vez por cuadro y la deja en `linea` (trece puntos, de la
//     raíz a la punta): antes la sumaba cada vértice por tramos, con un bucle de
//     doce que Direct3D despliega en cada variante. Aquí se interpola entre dos
//     puntos y la tangente sí se calcula en el sitio. Con rizo0 y rizo1 de signo
//     contrario sale una S; con todo a cero, una cinta recta. Así `espectro.gd`
//     la curva, la deja colgar, la recoge o la cruza delante de los ojos solo
//     cambiando dos números. (Con rizo1 de 200 cerraba un círculo y eran asas o
//     cuernos: ahora ninguno pasa de media vuelta.)
//   · `arrastre` es lo que lo tira la marcha (en el espacio de la malla): pesa
//     más cuanto más lejos de la raíz, que es lo que hace que vaya A RASTRAS.

#include "res://cripta3d/criaturas/espectro_gel.gdshaderinc"

// 0 la masa (y las gotas), 1 un jirón.
uniform float jiron = 0.0;
uniform float temblor = 0.0;
uniform vec3 arrastre = vec3(0.0);
// La masa.
uniform float encoge = 0.0;
uniform float ondear = 1.0;
// Los jirones.
uniform float largo = 0.15;
uniform float rizo0 = 0.0;
uniform float rizo1 = 0.0;
uniform float onda = 0.0;
uniform float fase = 0.0;
uniform float frecuencia = 5.0;
uniform float desvanece = 0.30;
// La línea del centro en s = largo·k/12, k = 0..12 (en el plano XY de la cinta).
// La pone `espectro.gd` (`_linea_jiron`) con las mismas cuentas que `angulo`.
uniform vec2 linea[13];

varying vec3 pos_obj;

float angulo(float s) {
	float u = s / largo;
	return rizo0 * s + rizo1 * s * s
		+ onda * u * sin(reloj * frecuencia - u * 5.5 + fase);
}

void vertex() {
	vec3 p = VERTEX;
	pos_obj = p;
	if (jiron > 0.5) {
		float s = max(p.x, 0.0);
		float u = clamp(s / largo, 0.0, 1.0);
		// La línea del centro: entre los dos puntos de `linea` que tocan. Lo que
		// va metido en la masa (x < 0) sigue recto desde la raíz.
		float fi = u * 12.0;
		float i0 = min(floor(fi), 11.0);
		int k = int(i0);
		vec2 c = vec2(min(p.x, 0.0), 0.0) + mix(linea[k], linea[k + 1], fi - i0);
		float a = angulo(s);
		vec2 tg = vec2(cos(a), sin(a));
		vec2 per = vec2(-tg.y, tg.x);
		vec3 v = vec3(c + per * p.y, p.z);
		// El temblor del miedo, más en la punta.
		v += vec3(sin(reloj * 41.0 + s * 90.0), sin(reloj * 37.0 + s * 70.0 + 1.0),
			sin(reloj * 33.0 + s * 60.0 + 2.0)) * 0.003 * temblor * u;
		v += arrastre * pow(u, 1.6);
		VERTEX = v;
		vec3 nn = NORMAL;
		NORMAL = vec3(tg * nn.x + per * nn.y, nn.z);
	} else {
		float t = reloj;
		float w = COLOR.b;
		float lento = sin(t * 3.1 + p.y * 38.0 + p.x * 24.0 + semilla) * 0.55
			+ sin(t * 2.3 - p.z * 33.0 + p.y * 12.0) * 0.45;
		float rapido = sin(t * 37.0 + p.y * 95.0 + p.z * 40.0) * sin(t * 29.0 + p.x * 80.0);
		VERTEX += NORMAL * (0.0022 * lento * ondear + 0.0040 * temblor * rapido);
		// El faldón: cada goterón con su fase, según por dónde cuelga.
		float ang = atan(p.z, p.x);
		float vaiven = sin(t * 3.6 + ang * 3.0 + semilla) * 0.5 + sin(t * 5.3 - ang * 2.0) * 0.5;
		VERTEX.xz += normalize(p.xz + vec2(0.0001)) * w * 0.007 * vaiven * ondear;
		VERTEX.y += w * 0.004 * sin(t * 4.4 + ang * 2.0);
		VERTEX += arrastre * w * w;
		// Recogido: los goterones suben y se meten bajo la panza.
		VERTEX.y += encoge * w * 0.040;
		VERTEX.xz *= 1.0 - encoge * w * 0.30;
	}
}

void fragment() {
	vec3 albedo;
	vec3 emision;
	float alfa;
	float rugosidad;
	gel(pos_obj, NORMAL, VIEW, COLOR.r, COLOR.g, albedo, emision, alfa, rugosidad);
	if (jiron > 0.5) {
		// El jirón se DESHACE hacia la punta, con el mismo fundido que el faldón:
		// no termina, se va. El borde del fundido va roto en hebras que corren
		// hacia la punta. `desvanece` es dónde empieza a irse (0 raíz, 1 punta).
		float s = COLOR.b;
		float hebras = gel_ruido3(vec3(s * 9.0 - reloj * 1.4, pos_obj.y * 60.0, fase * 3.0));
		float queda = 1.0 - smoothstep(desvanece, 0.86, s + (hebras - 0.5) * 0.24);
		emision *= 0.5 + 0.5 * queda;
		// Lo que va metido en la masa no se dibuja: la masa es translúcida, y el
		// trozo de dentro se veía a través como un tubo clavado. Y nace FUNDIDO:
		// el corte por donde sale de la piel, con su borde brillante, se leía
		// como un aro pegado al cuerpo.
		alfa *= queda * smoothstep(0.0, 0.04, pos_obj.x);
	} else {
		// SIN FINAL DURO POR ABAJO: el último tercio del cuerpo se desvanece por
		// altura, con el borde roto en hebras (un ruido que sube despacio), y los
		// goterones se acaban antes de acabarse. La primera versión los tenía
		// opacos hasta la punta y de frente eran patas.
		float hebras = gel_ruido3(vec3(pos_obj.x * 70.0, pos_obj.y * 12.0 - reloj * 0.6,
			pos_obj.z * 70.0 + semilla));
		float fundido = smoothstep(0.050, 0.140, pos_obj.y + (hebras - 0.5) * 0.050);
		alfa *= fundido;
		emision *= 0.55 + 0.45 * fundido;
	}
	// Sin luz de Godot: lo que alumbra la piel lo pone la luz propia (en el
	// mundo, que es como llegan las luces), y la emisión va con ella. SPECULAR
	// 0,12, como cuando era de Godot: con 0,55 el fuego le sacaba brillos de globo
	// de látex.
	ALBEDO = luz_propia(albedo, emision, normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz),
		normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz), 0.12, rugosidad);
	ALPHA = alfa;
}
