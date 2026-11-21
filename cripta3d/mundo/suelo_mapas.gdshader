shader_type canvas_item;
render_mode blend_disabled, unshaded;

// CRIPTA 3D · «suelo» · LOS MAPAS HORNEADOS.
//
// En Compatibility no hay oclusión ambiental de pantalla, y sin ella las
// paredes y las piezas flotan sobre la losa: la luz del fuego llega igual al
// pie de una pared que al centro de la plaza. Esto la sustituye. Se dibuja UNA
// vez, al arrancar, en dos SubViewport que miran el suelo desde arriba
// (`suelo.gd` los lee, les hace mipmaps y los suelta), y el sombreador de la
// losa los multiplica.
//
// No se pinta con polígonos superpuestos: dos tramos de pared que se tocan
// sumarían su sombra en la junta y saldría un rosario de manchas. Cada píxel
// mide su DISTANCIA a todas las piezas de una vez y se queda con la que manda.
// Son ciento y pico cápsulas por píxel, pero se hace una sola vez.
//
// Todo va en PÍXELES DE MESA (la mesa mide 400 × 1300), que es en lo que vienen
// los datos de `mesa`.
//
//   modo 0  (mapa A, fino):  R latón  · G surco  · B rebaje
//   modo 1  (mapa B, basto): R luz (1 = al aire, la oclusión)  · G hollín  · B uso
//
// El latón NO es una máscara de 0 o 1: es una RAMPA de distancia (0,5 justo en
// el borde). Así el sombreador de la losa recorta en 0,5 y el borde sale nítido
// de cerca aunque el mapa tenga cuatro píxeles por milímetro de mesa.

uniform int modo = 0;
// x0, y0, ancho y alto del mapa, en píxeles de mesa.
uniform vec4 rect_px = vec4(0.0, 548.0, 400.0, 752.0);

// Las listas largas van en una textura de datos (una columna por pieza), porque
// un navegador no garantiza más de 224 vectores de uniformes:
//   fila 0  cápsula de oclusión: a.x, a.y, b.x, b.y
//   fila 1  su forma: radio, alcance de la sombra, fuerza, —
//   fila 2  surco: a.x, a.y, b.x, b.y
//   fila 3  su forma: medio ancho, hondura, —, —
uniform sampler2D datos : filter_nearest, repeat_disable;
uniform int n_capsulas = 0;
uniform int n_surcos = 0;

// Las guías de latón: cheurones. Centro (la punta), dirección (hacia la boca).
uniform vec4 flechas[16];
// Medio ancho, fondo (de la punta a los brazos), grosor.
uniform vec4 flechas_forma[16];
uniform int n_flechas = 0;
// Aros de latón: centro, radio, grosor.
uniform vec4 aros[12];
uniform int n_aros = 0;
// Listones rectos de latón: de a.xy a b.xy, con su grosor en `bandas_g[i].x`.
uniform vec4 bandas[4];
uniform vec4 bandas_g[4];
uniform int n_bandas = 0;
// Braseros: centro, radio de la pieza, hasta dónde llega el hollín.
uniform vec4 braseros[4];
uniform int n_braseros = 0;
// Bocas de la catacumba: centro, radio del hueco.
uniform vec4 bocas[4];
uniform int n_bocas = 0;
// Zonas de paso (uso): centro y radios; y su peso en `zonas_peso[i].x`.
uniform vec4 zonas[8];
uniform vec4 zonas_peso[8];
uniform int n_zonas = 0;

float segmento(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1.0e-6), 0.0, 1.0);
	return length(pa - ba * h);
}

void fragment() {
	vec2 p = rect_px.xy + UV * rect_px.zw;

	if (modo == 0) {
		// ------------------------------------------------------------ el latón
		float d_laton = 1.0e5;
		for (int i = 0; i < n_flechas; i++) {
			vec2 c = flechas[i].xy;
			vec2 f = flechas[i].zw;
			vec2 l = vec2(-f.y, f.x);
			vec2 q = vec2(dot(p - c, f), dot(p - c, l));
			vec3 fo = flechas_forma[i].xyz;
			float brazo = min(segmento(q, vec2(-fo.y, fo.x), vec2(0.0)),
					segmento(q, vec2(-fo.y, -fo.x), vec2(0.0)));
			d_laton = min(d_laton, brazo - fo.z * 0.5);
		}
		for (int i = 0; i < n_aros; i++) {
			d_laton = min(d_laton, abs(length(p - aros[i].xy) - aros[i].z) - aros[i].w * 0.5);
		}
		for (int i = 0; i < n_bandas; i++) {
			d_laton = min(d_laton, segmento(p, bandas[i].xy, bandas[i].zw) - bandas_g[i].x * 0.5);
		}
		float laton = clamp(0.5 - d_laton / 2.6, 0.0, 1.0);

		// ------------------------------------------------------------ los surcos
		// Perfil de canal: hondo en el centro, cero en el borde, sin escalón.
		float surco = 0.0;
		for (int i = 0; i < n_surcos; i++) {
			vec4 s = texelFetch(datos, ivec2(i, 2), 0);
			vec4 e = texelFetch(datos, ivec2(i, 3), 0);
			float g = clamp(1.0 - segmento(p, s.xy, s.zw) / e.x, 0.0, 1.0);
			surco = max(surco, g * g * (3.0 - 2.0 * g) * e.y);
		}

		// ------------------------------------------- el rebaje de las bocas
		float rebaje = 0.0;
		for (int i = 0; i < n_bocas; i++) {
			float d = length(p - bocas[i].xy);
			rebaje = max(rebaje, clamp((bocas[i].z + 4.0 - d) / 8.0, 0.0, 1.0));
		}
		COLOR = vec4(laton, surco, rebaje, 1.0);
	} else {
		// ---------------------------------------------------------- la oclusión
		// Cada pieza oscurece con una caída suave hasta su alcance y una línea de
		// contacto más dura al pie. Manda la que más tapa; las demás suman un
		// tercio, que es lo que oscurece los rincones sin hacer rosario en las
		// juntas de un muro partido en tramos.
		float o_max = 0.0;
		float o_suma = 0.0;
		for (int i = 0; i < n_capsulas; i++) {
			vec4 s = texelFetch(datos, ivec2(i, 0), 0);
			vec4 e = texelFetch(datos, ivec2(i, 1), 0);
			float d = segmento(p, s.xy, s.zw) - e.x;
			float t = clamp(d / e.y, 0.0, 1.0);
			float o = e.z * (pow(1.0 - t, 2.2) * 0.78 + 0.32 * (1.0 - smoothstep(0.0, 3.0, d)));
			o = min(o, 1.0);
			o_max = max(o_max, o);
			o_suma += o;
		}
		float oscuro = clamp(o_max + 0.3 * (o_suma - o_max), 0.0, 0.94);

		// ------------------------------------------------------------- el hollín
		// Una rampa que crece hacia el brasero; el borde roto lo pone la losa con
		// su ruido, que aquí no hay.
		float hollin = 0.0;
		for (int i = 0; i < n_braseros; i++) {
			float d = length(p - braseros[i].xy) - braseros[i].z;
			hollin = max(hollin, clamp(1.0 - d / braseros[i].w, 0.0, 1.0));
		}

		// ---------------------------------------------------------------- el uso
		// Por dónde pasa la bola: las zonas de juego, y una franja ancha a cada
		// lado de los surcos. Lo que no se pisa se queda basto.
		float uso = 0.0;
		for (int i = 0; i < n_zonas; i++) {
			vec2 q = (p - zonas[i].xy) / zonas[i].zw;
			uso += exp(-dot(q, q) * 2.0) * zonas_peso[i].x;
		}
		for (int i = 0; i < n_surcos; i++) {
			vec4 s = texelFetch(datos, ivec2(i, 2), 0);
			float d = segmento(p, s.xy, s.zw);
			uso = max(uso, exp(-d * d / 400.0) * 0.85);
		}
		COLOR = vec4(1.0 - oscuro, hollin, clamp(uso, 0.0, 1.0), 1.0);
	}
}
