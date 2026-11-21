// CRIPTA 3D · la LLAMARADA de un brasero golpeado (módulo «piezas»).
//
// POR QUÉ EXISTE. El búmper es la pieza que más suena en un pinball, y aquí no
// se veía sonar: al golpear un brasero el ascua se ponía algo más blanca DENTRO
// del cuenco, a 0,12 de alto, y desde las cámaras de juego eso no se distingue
// a 30 px; encima, las lápidas de delante le tapaban la mitad de abajo
// (revisión de juego, z_campana_golpes). El golpe tiene que SUBIR hacia la
// cámara: una lengua de fuego que sale del cuenco, sube medio palmo por encima
// de las lápidas y se apaga en un cuarto de segundo.
//
// No es una superficie de la mesa (esas salen de la biblioteca): es fuego, como
// las chispas de «efectos». Aditivo, sin sombra y fuera del reflejo (lo pone
// `piezas.gd`).
//
// SIEMPRE DE CARA A LA CÁMARA, PERO DE PIE. Gira sobre el eje vertical para que
// desde la cámara de juego sea una lengua que sube; pero en la CENITAL, que mira
// recto hacia abajo, el giro sobre el eje vertical no existe (el cruce de «arriba»
// con la mirada da cero y la llama saldría de canto, invisible o hecha NaN): ahí
// se vuelve un cartel corriente, de cara a la cámara. Entre medias se mezclan.
//
// UV.y: 0 arriba (la punta de la llama), 1 abajo (la boca del cuenco).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 color_nucleo : source_color = vec3(1.0, 0.92, 0.7);
uniform vec3 color_llama : source_color = vec3(1.0, 0.55, 0.18);
uniform vec3 color_borde : source_color = vec3(0.8, 0.18, 0.08);
// 0..1: cuánto queda del golpe. Lo baja `piezas.gd` en cada cuadro.
uniform float fuerza = 0.0;
uniform float brillo = 2.2;
uniform float semilla = 0.0;

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(azar(i), azar(i + vec2(1.0, 0.0)), f.x),
		mix(azar(i + vec2(0.0, 1.0)), azar(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	vec3 atras = INV_VIEW_MATRIX[2].xyz;
	vec3 cruce = cross(vec3(0.0, 1.0, 0.0), atras);
	float de_pie = smoothstep(0.15, 0.45, length(cruce));
	vec3 der = normalize(mix(INV_VIEW_MATRIX[0].xyz, cruce / max(length(cruce), 0.0001), de_pie));
	vec3 arriba = normalize(mix(INV_VIEW_MATRIX[1].xyz, vec3(0.0, 1.0, 0.0), de_pie));
	vec3 frente = normalize(cross(der, arriba));
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(der * sx, 0.0), vec4(arriba * sy, 0.0),
		vec4(frente, 0.0), MODEL_MATRIX[3]);
}

void fragment() {
	float h = 1.0 - UV.y;
	float x = (UV.x - 0.5) * 2.0;
	float t = TIME * 7.0 + semilla;
	// La lengua ondula más cuanto más sube, y se estrecha hasta la punta.
	float onda = (sin(h * 8.0 - t * 1.3) * 0.13 + sin(h * 15.0 - t * 2.3) * 0.06) * h;
	float ancho = mix(0.8, 0.06, pow(h, 0.75));
	float d = abs(x + onda) / ancho;
	float cuerpo = 1.0 - smoothstep(0.3, 1.0, d);
	// El ruido que sube se come la llama por arriba: lenguas, no una gota.
	float n = ruido(vec2(x * 3.2 + semilla, h * 5.0 - t * 0.9));
	float alto = 0.35 + 0.65 * fuerza;
	float corte = smoothstep(alto, alto - 0.35, h + (n - 0.5) * 0.45);
	// La boca, a ras del cuenco, se funde (no corta en recto).
	float boca = smoothstep(0.0, 0.08, h);
	float a = cuerpo * corte * boca * clamp(fuerza * 1.6, 0.0, 1.0);
	// Núcleo casi blanco abajo y en el eje; naranja; borde rojo arriba y fuera.
	float calor = clamp((1.0 - d) * 1.3 - h * 0.7, 0.0, 1.0);
	vec3 col = mix(color_borde, color_llama, smoothstep(0.0, 0.45, calor));
	// El blanco, solo en el corazón: con más, desde lejos era una vela, no fuego.
	col = mix(col, color_nucleo, smoothstep(0.68, 1.0, calor));
	ALBEDO = col * brillo;
	ALPHA = clamp(a, 0.0, 1.0);
}
