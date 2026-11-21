shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_disabled;

// CRIPTA 3D · «suelo» · LA LOSA.
//
// La superficie más grande de la pantalla, así que aquí no vale el sombreador
// de todo lo demás (`superficie.gdshaderinc`): ese sabe hacer piedra en
// cualquier cara, y el suelo necesita cosas que solo tiene el suelo. Lee las
// MISMAS texturas de ruido, con los mismos colores de la paleta, para que case
// con el sillar de las paredes; lo demás es suyo:
//
//   · LAS LOSAS, grandes y desiguales: hiladas de alto distinto, juntas que no
//     van a escuadra, alguna losa doble y alguna partida. Todo en coordenadas
//     de mundo: el suelo va en trozos y no se ve ninguna costura.
//   · EL ADOQUÍN del pie, de las palas al desagüe: el mismo aparejo, en chico.
//   · EL USO: pulida, con lustre, donde pasa la bola; basta y con mugre en los
//     bordes. La piedra varía a BAJA frecuencia (de losa a losa, manchas de un
//     palmo) y lo único fino son los poros.
//   · EL AGUA: en las juntas y al pie de las paredes, con borde ancho y blando, y
//     SECA en la zona de palas y en el camino de la bola.
//   · EL REFLEJO DE VERDAD: la imagen de la cámara espejo, SUMADA a la losa
//     mojada y con Fresnel, abierta en vertical según la rugosidad (el reguero
//     de luz del suelo mojado de Saltline), torcida por el relieve.
//   · EL EMBLEMA: una rosa de los vientos de teselas en el centro de la plaza.
//
// LO QUE SE CALCULA AQUÍ Y LO QUE VIENE HORNEADO. En el navegador (ANGLE) este
// sombreador costaba 13,7 s de compilar: Direct3D despliega cada línea del
// `fragment` en cuatro o cinco variantes de Godot, y aquí se calculaban en cada
// píxel el aparejo (3,3 s), la rosa (0,9) y todo lo demás. Ahora lo que NO
// depende de la cámara, del tiempo ni del grano fino lo dibuja UNA vez, al
// arrancar, `suelo_horno.gdshader`, con las mismas cuentas (qué lleva cada canal
// está en su cabecera), y aquí se lee. Se queda aquí lo que cambia de píxel a
// píxel por debajo de lo que cabe en un mapa (la mella del canto, los poros, el
// relieve del grano y de las celdas), el borde del latón (que se suaviza según
// la distancia, con `fwidth`), las gotas y el reflejo. Cada línea de más aquí
// son décimas de segundo en el navegador: lo que se pueda hornear, al horno.
//
// LO QUE NO SE PUEDE TOCAR: `reflejo` y `fuerza_reflejo` se llaman así porque
// los escribe la escena, y el reflejo se lee en (x, 1 − y) de pantalla porque la
// cámara espejo es la de juego reflejada en el plano y = 0.

uniform sampler2D reflejo : source_color, filter_linear, repeat_disable, hint_default_black;
// Interruptor: la escena escribe 1 o 0 según la calidad. Cuánto refleja cada
// cosa es de aquí abajo.
uniform float fuerza_reflejo = 1.0;
// Cuántas lecturas del reflejo por píxel para abrirlo en reguero. El suelo es
// la superficie más grande de la pantalla: en MEDIA (la web) bajan a la mitad
// (`suelo.gd`, `calidad`).
uniform int muestras = 8;
// EL SUELO MOJADO NO MIENTE (decisión 5 del remate): el reflejo de lo que
// emite —las velas del altar, una llama, un fogonazo— no puede brillar más que
// la bola ni parecerse a ella. Por debajo de `rodilla_reflejo` (luminancia de
// la imagen reflejada, 0..1) pasa tal cual; por encima se aplasta en curva
// hasta no pasar nunca de `techo_reflejo`. Medido en la rasante: con el reflejo
// entero, el de las velas daba un óvalo de 254 de luminancia con el p95 en
// 236, y la bola 181.
uniform float rodilla_reflejo = 0.1;
uniform float techo_reflejo = 0.3;

uniform sampler2D tex_grano : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_celdas : filter_linear_mipmap_anisotropic, repeat_enable;
// Los tres atlas del horno. Se leen SIN mipmaps (`textureLod` a 0): las juntas
// son una distancia, y una distancia promediada de lejos borra la junta; así
// cada píxel ve lo mismo que veía cuando se calculaba aquí. La excepción es la
// rampa del latón, que se leía del mapa A CON mipmaps: sin ellos, de lejos el
// listón fino y los aros salían más duros que antes (se veía en la cenital).
uniform sampler2D horno_fino : filter_linear_mipmap, repeat_disable;
uniform sampler2D horno_basto : filter_linear, repeat_disable;
uniform sampler2D horno_rosa : filter_linear, repeat_disable, hint_default_black;
// x, z, ancho y fondo de mundo que cubren los atlas del suelo, y los de la rosa.
uniform vec4 rect_mapa = vec4(0.0, 5.48, 4.0, 7.52);
uniform vec4 rect_rosa = vec4(1.7, 9.74, 0.88, 0.88);
// Un píxel del mapa fino, en unidades de mundo (para la pendiente del latón).
uniform float paso_mapa = 0.004;
uniform float z_adoquin = 12.46;
uniform float lluvia = 1.0;            // las gotas que caen en los charcos

uniform vec3 piedra_a : source_color = vec3(0.16, 0.16, 0.20);
uniform vec3 color_mugre : source_color = vec3(0.03, 0.025, 0.02);
uniform vec3 color_hollin : source_color = vec3(0.025, 0.02, 0.018);
uniform vec3 color_laton : source_color = vec3(0.88, 0.65, 0.24);
uniform vec3 color_laton_viejo : source_color = vec3(0.54, 0.40, 0.14);
uniform vec3 color_cardenillo : source_color = vec3(0.17, 0.20, 0.12);

#ifdef SUELO_DEPURA
// Los modos de mirar (`-- --suelo-depura=N`): 1 oclusión · 2 agua · 3 uso ·
// 4 latón, surco y hueco · 5 normal · 6 losas · 7 charco, hollín y relleno ·
// 8 solo el reflejo. NO van en el sombreador del juego: `suelo.gd` monta una
// copia con SUELO_DEPURA definido solo cuando se pide. Una rama de más también
// se compila, y en el navegador costaba medio segundo.
uniform int depura = 0;
#endif

// Lo que cubren los canales horneados (los mismos números que el horno).
const float RAJA = 0.04;
const float BAJO_DESDE = 0.4;
const float BAJO_ANCHO = 0.7;
const float CELDA_GOTA = 0.45;
// Las regiones del atlas basto (`suelo_horno.gdshader`): seis, de 0 a 5.
const float BASTO = 6.0;

varying vec3 v_mundo;

// La luz de Godot, copiada a mano por lo que tarda en compilar la suya en un
// navegador (ver el fichero). Por eso arriba va `specular_disabled`.
#include "res://cripta3d/materiales/luz_godot.gdshaderinc"

void vertex() {
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = v_mundo.xz;
	vec3 n_malla = NORMAL;

	// --------------------------------------------------------------- lecturas
	// Un píxel dentro del borde: los atlas llevan las regiones pegadas, y en el
	// borde la lectura cogería medio píxel de la de al lado (bajo las paredes).
	vec2 uv = clamp((p - rect_mapa.xy) / rect_mapa.zw, 0.001, 0.999);
	vec2 uf = vec2(uv.x * 0.5, uv.y);
	vec2 ub = vec2(uv.x / BASTO, uv.y);
	vec4 f1 = textureLod(horno_fino, uf, 0.0);                           // junta, hacia, raja
	vec4 f2 = textureLod(horno_fino, uf + vec2(0.5, 0.0), 0.0);          // color seco, latón
	vec4 b_rug = textureLod(horno_basto, ub, 0.0);                       // P, Q, lo bajo, lo seco
	vec4 b_pend = textureLod(horno_basto, ub + vec2(1.0 / BASTO, 0.0), 0.0);   // inclinación, pendiente
	vec4 b_col = textureLod(horno_basto, ub + vec2(2.0 / BASTO, 0.0), 0.0);    // K, C
	vec4 b_losa = textureLod(horno_basto, ub + vec2(3.0 / BASTO, 0.0), 0.0);   // basto, luz, junta, bisel
	vec4 b_mas = textureLod(horno_basto, ub + vec2(4.0 / BASTO, 0.0), 0.0);    // hoyos, hollín, hueco, tizne
	// Las teselas de grano (0,55) son las de la piedra de la biblioteca: una
	// sola piedra.
	vec4 grano = texture(tex_grano, p / 0.55);
	vec4 fino = texture(tex_grano, p / 0.19 + vec2(0.53, 0.29));
	vec4 celdas = texture(tex_celdas, p / 1.3 + vec2(0.21, 0.71));

	float basto = b_losa.r;
	float luz_horno = b_losa.g;
	float ancho_j = 0.002 + b_losa.b * 0.0025;
	float bisel = 0.011 + b_losa.a * 0.013;
	float hol = b_mas.g;
	float hueco = b_mas.b;
	// En el adoquín la junta es más clara y el canto menos hundido: con los de
	// la losa, a esa escala, la junta era un contorno negro de dibujo animado.
	float ad = step(z_adoquin, p.y);

	// ------------------------------------------------------------- las juntas
	// Dos cosas distintas: la JUNTA (el hueco con mortero, estrecho) y el BISEL
	// (el canto gastado que cae hacia ella). El canto, mellado por el grano: lo
	// basto más que lo pulido. La mella es más fina que cualquier mapa, por eso
	// se suma aquí a la distancia horneada.
	float dj = f1.r * 0.13 + (grano.r - 0.55) * 0.007 + (fino.a - 0.5) * 0.004 * basto;
	float sj = clamp((dj - ancho_j) / bisel, 0.0, 1.0);
	float en_junta = 1.0 - smoothstep(ancho_j * 0.5, ancho_j + 0.0022, dj);
	float en_bisel = 1.0 - sj * sj * (3.0 - 2.0 * sj);
	// La raja de la losa partida, con su temblor de grano.
	float d_raja = abs((f1.a - 0.5) * (2.0 * RAJA) + (grano.r - 0.5) * 0.03 + (fino.r - 0.5) * 0.006);
	float en_raja = 1.0 - smoothstep(0.0012, 0.0035, d_raja);
	float junta = max(en_junta, en_raja);
	// La pendiente: el bisel hacia fuera de la losa, cada losa (y cada mitad de
	// una rota) un poco inclinada, el relieve suave del grano y de las celdas
	// (más en lo basto: el grano en la normal era la mitad del «fieltro»), y el
	// surco y el labio del rebaje, horneados.
	vec2 pend = (1.0 - f1.gb * 2.0) * (6.0 * sj * (1.0 - sj) / bisel * 0.0035)
			+ (b_pend.rg - 0.5) * (0.025 * (1.0 - en_bisel))
			+ (grano.gb - 0.5) * (0.02 + 0.06 * basto) + (celdas.gb - 0.5) * (0.03 * basto)
			+ (b_pend.ba - 0.5) * 0.5;

	// -------------------------------------------------------------- el color
	// El color seco viene horneado (losa a losa, manchas, veta, mugre, pulido).
	// Aquí, lo fino: el grano apenas (±3 %) y los POROS, oscuros, pequeños y
	// salteados (del grano FINO, y solo de su cola: con el grande salían
	// manchas de camuflaje). El mortero de la junta, oscuro y no negro (un
	// trazo negro es un dibujo a tinta), y alguna grieta fina en lo basto.
	float poro = smoothstep(0.93, 0.985, 1.0 - fino.a) * smoothstep(0.3, 0.6, grano.r);
	float hoyo = (1.0 - smoothstep(0.0, 0.09, celdas.a)) * b_mas.r;
	vec3 alb = f2.rgb * f2.rgb * ((0.97 + 0.06 * grano.a) * (1.0 - poro * 0.3));
	alb = mix(alb, mix(color_mugre, piedra_a * 0.45, 0.5), junta * (1.0 - ad * 0.4))
			* ((1.0 - en_bisel * (0.22 - ad * 0.12)) * (1.0 - hoyo * 0.55));
	// El surco, el hollín (con su grano de ceniza) y el rebaje, en una cuenta.
	alb = alb * (b_col.r * 1.1) + b_col.gba * 0.05 + color_hollin * (b_mas.a * 0.5 * fino.a);
	// La rugosidad: P sin la junta, y la junta la sube (Q).
	float rug = b_rug.r + b_rug.g * junta;

	// ------------------------------------------------------------- la rosa
	// Cada tesela, horneada con su color, su lechada y lo torcida que está; aquí
	// solo el grano fino encima.
	vec2 ur = clamp((p - rect_rosa.xy) / rect_rosa.zw, 0.001, 0.999) * vec2(0.5, 1.0);
	vec4 r1 = textureLod(horno_rosa, ur, 0.0);
	vec4 r2 = textureLod(horno_rosa, ur + vec2(0.5, 0.0), 0.0);
	float en_rosa = r2.a;
	alb = mix(alb, mix(r1.rgb * r1.rgb * (0.875 + 0.25 * fino.a), color_mugre, r1.a * 0.85), en_rosa);
	pend = mix(pend, (r2.rg - 0.5) * (0.09 * (1.0 - r1.a)) + (fino.gb - 0.5) * 0.04, en_rosa);
	rug = mix(rug, mix(0.34 + 0.18 * r2.b, 0.9, r1.a), en_rosa);

	// ------------------------------------------------------------- el latón
	// El latón es lo único que brilla LIMPIO (LEEME). La pátina va SOLO EN LOS
	// HUECOS: la orilla donde el metal se mete bajo la piedra (la rampa cerca de
	// 0,5) y al pie de lo que tapa (la oclusión horneada). Lo de en medio,
	// limpio y casi liso. Su borde se recorta aquí, con `fwidth`, para que salga
	// nítido de cerca y no chispee de lejos.
	float lr = texture(horno_fino, uf + vec2(0.5, 0.0)).a;
	float w = max(fwidth(lr) * 0.8, 0.02);
	float laton = smoothstep(0.5 - w, 0.5 + w, lr);
	float al_pie = 1.0 - luz_horno;
	float viejo = clamp((1.0 - smoothstep(0.5, 0.75, lr)) * 0.8 + al_pie * 0.9, 0.0, 1.0) * (0.5 + 0.5 * basto);
	vec3 lc = mix(color_laton, color_laton_viejo, 0.2 + viejo * 0.45) * (0.935 + 0.05 * fino.a);
	lc = mix(lc, color_cardenillo, viejo * al_pie * 0.4) * (1.0 - hol * 0.75);
	alb = mix(alb, lc, laton);
	// El rayado fino, en la rugosidad y en la normal, casi nada: era la otra
	// mitad del moteado. El latón embutido queda a ras; el canto, gastado, cae
	// un poco.
	rug = mix(rug, mix(0.28, 0.53, viejo) + 0.04 * fino.r + hol * 0.3, laton);
	float lr_x = texture(horno_fino, uf + vec2(0.5 + 0.5 * paso_mapa / rect_mapa.z, 0.0)).a;
	float lr_z = texture(horno_fino, uf + vec2(0.5, paso_mapa / rect_mapa.w)).a;
	pend = mix(pend, (vec2(lr_x, lr_z) - lr) * (0.005 / paso_mapa) + (fino.gb - 0.5) * 0.012, laton);
	// La costura: donde el metal se mete bajo la piedra, una línea de mugre.
	alb = mix(alb, color_mugre * 0.5, (1.0 - smoothstep(0.0, 0.09, abs(lr - 0.5))) * 0.75);

	// --------------------------------------------------------------- el agua
	// Dónde se encharca viene horneado («lo bajo», con la zona de palas y el
	// camino de la bola ya SECOS); la junta le suma un poco, porque el agua
	// corre por ella. Un borde ancho y blando: de seco a húmedo en un palmo, de
	// húmedo a charco en dos o tres dedos.
	float sobre = b_rug.b * BAJO_ANCHO - BAJO_DESDE + junta * 0.1;
	float charco = smoothstep(0.0, 0.18, sobre) * b_rug.a;
	float humedo = smoothstep(-0.24, 0.04, sobre) * b_rug.a;
	// La piedra mojada oscurece y se satura, pero SIGUE SIENDO PIEDRA: el charco
	// deja la losa a media luz, no a un 30 % (sin nada que reflejar, un hueco
	// negro).
	float g2 = dot(alb, vec3(0.3, 0.59, 0.11));
	alb = mix(vec3(g2), alb, 1.0 + 0.25 * max(humedo * 0.7, charco))
			* (1.0 - (0.26 * humedo + 0.2 * charco) * (1.0 - laton));
	// EL BORDE DE LO MOJADO NO PUEDE SER EL SITIO MÁS LISO: la rugosidad de la
	// luz directa y la normal van con la máscara de humedad SUAVIZADA (en S), de
	// lo seco al 0,46 del charco sin pasar por un mínimo (si no, cada mancha que
	// sigue a una grieta salía con un ribete blanco bajo la luna). `rug` es la
	// del reflejo, que no hacía anillo; el charco no es un espejo de 0,04: con
	// 0,2 conserva parte del lustre y el reflejo sale algo abierto.
	float moja_s = smoothstep(0.0, 1.0, max(humedo, charco));
	float rug_luz = mix(rug, 0.46, moja_s);
	rug = mix(rug * (1.0 - 0.36 * humedo), 0.2, charco);
	// Lo de dentro del charco se queda como estaba (0,1 de la pendiente).
	pend *= (1.0 - moja_s * 0.45) * (1.0 - charco * 0.82);

	// Gotas que caen del techo en los charcos: anillos que se abren y se apagan.
	// El azar de cada celda, horneado en su centro.
	if (charco > 0.01 && lluvia > 0.0) {
		vec2 celda = floor(p / CELDA_GOTA);
		vec2 dentro = p / CELDA_GOTA - celda;
		vec2 ug = clamp(((celda + 0.5) * CELDA_GOTA - rect_mapa.xy) / rect_mapa.zw, 0.001, 0.999);
		vec3 gota = textureLod(horno_basto, vec2((ug.x + 5.0) / BASTO, ug.y), 0.0).rgb;
		float t = fract(TIME / (2.6 + 3.0 * gota.r) + gota.r);
		vec2 dv = (dentro - 0.3 - 0.4 * gota.gb) * CELDA_GOTA;
		float dist = length(dv);
		float radio = t * 0.16;
		float anillo = sin((dist - radio) * 120.0) * exp(-abs(dist - radio) * 60.0) * (1.0 - t);
		pend += normalize(dv + 1.0e-5) * anillo * 0.05 * charco * lluvia;
	}

	// ------------------------------------------------- las grietas, rellenas
	// LA JUNTA Y LA RAJA VAN LLENAS DE MUGRE, Y LA MUGRE ES MATE. El agua busca
	// la junta, así que el charco le dejaba a la junta, a la raja y a su labio la
	// rugosidad del agua con la pendiente del bisel: bajo el charco de luna cada
	// grieta salía como un rayo blanco-azulado (revisión del remate). El hueco y
	// su labio —el bisel ENTERO— van mates, sin pendiente y casi sin especular ni
	// reflejo; el agua se queda en la losa de al lado, que es donde brilla. En la
	// rosa no hay junta que rellenar.
	float labio_j = 1.0 - smoothstep(ancho_j, ancho_j + bisel * 1.1, dj);
	float labio_r = 1.0 - smoothstep(0.0012, 0.016, d_raja);
	float relleno = max(junta, max(labio_j, labio_r) * 0.85) * (1.0 - laton) * (1.0 - en_rosa);
	rug = mix(rug, 0.9, relleno);
	rug_luz = mix(rug_luz, 0.9, relleno);
	// La pendiente se queda en parte (el canto se sigue leyendo por la sombra);
	// lo que se va es el brillo.
	pend *= 1.0 - relleno * 0.6;

	// ------------------------------------------------------------- la luz
	// La oclusión horneada apaga también la luz directa: el ambiente es casi
	// cero en una cripta, y una oclusión que solo tocara el ambiente no se vería.
	float sombra = luz_horno * (1.0 - junta * (0.55 - ad * 0.25))
			* (1.0 - en_bisel * (0.2 - ad * 0.1)) * (1.0 - hoyo * 0.3);

	vec3 n_mundo = normalize(vec3(-pend.x, 1.0, -pend.y));
	vec3 n_vista = normalize((VIEW_MATRIX * vec4(n_mundo, 0.0)).xyz);

	ALBEDO = alb * mix(1.0, sombra, 0.75);
	// LA LUZ DIRECTA VE EL AGUA UN PUNTO MÁS ÁSPERA QUE EL ESPEJO. Con 0,2, el
	// brillo de una llama o de la luna en un charco era un óvalo blanco del
	// tamaño de la bola y más claro que ella (la bola falsa de la rasante: 254
	// de luminancia frente a 181 de la bola; con 0,46, 213 y sin forma de
	// óvalo). La imagen de la sala ya la pone el reflejo, con su techo.
	ROUGHNESS = clamp(rug_luz, 0.03, 1.0);
	// No del todo metal: a la luz del fuego, un latón metálico puro solo se ve
	// donde le da un brillo, y embutido en el suelo casi nunca le da.
	METALLIC = laton * 0.75;
	// El agua devuelve un 2 % de frente (SPECULAR 0,25), la piedra un 3-4 %, con
	// la misma máscara suavizada que la rugosidad.
	SPECULAR = mix(0.42, 0.25, moja_s) * mix(1.0, sombra, 0.85) * (1.0 - hueco) * (1.0 - relleno * 0.7);
	v_especular = SPECULAR;
	NORMAL = n_vista;
	AO = sombra;

	// ------------------------------------------------------------- el reflejo
	vec3 luz = vec3(0.0);
	if (fuerza_reflejo > 0.0) {
		// Cuánto refleja: el charco mucho, lo mojado y pulido algo, lo seco casi
		// nada, la junta y el hollín nada. Sube hacia lo rasante (Fresnel), pero
		// con suelo: desde la cámara de juego, casi a plomo, el agua de verdad
		// apenas refleja y el reflejo es media escena.
		float nv = clamp(dot(n_vista, VIEW), 0.0, 1.0);
		float rasante = pow(1.0 - nv, 3.0);
		float liso = 1.0 - clamp(rug, 0.0, 1.0);
		// El reflejo se SUMA a la losa mojada (que sigue alumbrada debajo), y con
		// Fresnel: el charco pequeño de un carril exterior, que se ve casi de
		// frente, refleja la mitad que uno visto a ras.
		float cuanto = charco * mix(0.35, 0.95, rasante)
				+ (1.0 - charco) * liso * liso * mix(0.08, 0.5, rasante) * (0.35 + humedo * 0.65);
		cuanto = mix(cuanto, 0.55 * mix(0.6, 1.0, rasante), laton);
		cuanto *= (1.0 - hol * 0.9) * (1.0 - hueco) * mix(1.0, sombra, 0.6) * (1.0 - relleno * 0.9);
		if (cuanto > 0.003) {
			vec2 suv = vec2(SCREEN_UV.x, 1.0 - SCREEN_UV.y) + (n_vista.xy - n_malla.xy) * mix(0.06, 0.025, charco);
			// Abierto en vertical: el reguero de luz del suelo mojado.
			// El latón refleja nítido aunque no sea un espejo: si se emborrona, el
			// metal se queda en un naranja liso, que es pintura.
			float abre = mix(0.0012, 0.022, clamp(rug * 1.4, 0.0, 1.0) * (1.0 - laton * 0.85));
			vec2 eje = vec2(abre * 0.45, abre * 1.6);
			vec3 imagen = vec3(0.0);
			// Giro fijo: con uno al azar por píxel, el reflejo emborronado salía a
			// granos (sal y pimienta) en cuanto la imagen tenía contraste.
			float giro = 0.4;
			for (int i = 0; i < muestras; i++) {
				float a = float(i) * 2.3999632 + giro;
				float rr = sqrt((float(i) + 0.5) / float(muestras));
				imagen += textureLod(reflejo, suv + vec2(cos(a), sin(a)) * rr * eje, 0.0).rgb;
			}
			imagen /= float(max(muestras, 1));
			// El techo: se aplasta la luminancia y se conserva el color, así un
			// reflejo de fuego sigue siendo cálido pero ya no es un foco.
			float l_ref = dot(imagen, vec3(0.2126, 0.7152, 0.0722));
			if (l_ref > rodilla_reflejo) {
				float holgura = max(techo_reflejo - rodilla_reflejo, 1.0e-3);
				float l_nueva = rodilla_reflejo + holgura * (1.0 - exp(-(l_ref - rodilla_reflejo) / holgura));
				imagen *= l_nueva / l_ref;
			}
			luz += imagen * mix(vec3(1.0), alb * 1.6, laton) * cuanto;
		}
	}
	EMISSION = luz * fuerza_reflejo;

#ifdef SUELO_DEPURA
	if (depura > 0) {
		vec3 dd = vec3(0.0);
		if (depura == 1) { dd = vec3(sombra); }
		else if (depura == 2) { dd = vec3(charco, humedo, 0.0); }
		else if (depura == 3) { dd = vec3(1.0 - basto, hol, hueco); }
		else if (depura == 4) { dd = vec3(lr, b_col.r, hueco); }
		else if (depura == 5) { dd = n_mundo * 0.5 + 0.5; }
		else if (depura == 7) { dd = vec3(charco, hol, relleno); }
		else if (depura == 8) { dd = luz * fuerza_reflejo; }
		else { dd = vec3(f2.r, f2.g, en_junta); }
		ALBEDO = vec3(0.0);
		SPECULAR = 0.0;
		v_especular = 0.0;
		ROUGHNESS = 1.0;
		METALLIC = 0.0;
		EMISSION = dd;
	}
#endif
}
