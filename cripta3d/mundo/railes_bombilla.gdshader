shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

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

varying float v_luz;

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
	ALBEDO = mix(vidrio, luz_ambar * 0.55, l) * tinte;
	ROUGHNESS = 0.16;
	SPECULAR = 0.6;
	METALLIC = 0.0;
	RIM = 0.25;
	RIM_TINT = 0.6;
	EMISSION = color_luz * tinte * v_luz * energia * (0.55 + 0.45 * filamento);
}
