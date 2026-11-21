shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// CRIPTA 3D — BRASA: lo que TIZNA. El CERCO pintado en la losa debajo de ella y el
// HUMO de cuando se queda casi apagada. `es_humo` dice cuál es.
//
// Eran dos sombreadores con el mismo modo de pintar, y en el navegador cada
// sombreador, por vacío que esté, cuesta 0,3 s de compilar (ANGLE → Direct3D):
// juntos cuestan lo que costaba el cerco solo (medido con el banco, 21-nov-2026).
// Y el ruido de los dos, que era un ruido de valor por código, se lee de
// `brasa_ruido.png`: es el mismo ruido, horneado (ver `brasa_fuego.gdshaderinc`).
//
// EL CERCO es su único indicador. En ÓRBITA era un aro de neón; aquí es de la
// cripta:
//   · un TIZNE: la mancha de hollín que deja una brasa donde se posa. Hace de
//     sombra de contacto (el motor no tiene oclusión de pantalla) y, cuando la
//     llama va por el aire, dice dónde va a caer;
//   · un CERCO DE RESCOLDOS: brasas menudas desperdigadas por el círculo que de
//     verdad ocupa la criatura. Cada una es un grano de carbón con su lumbre
//     dentro y un poco de resplandor en la losa, no un punto de luz: desiguales,
//     mal alineadas, alguna apagada. Laten cuando basta tocarla para recogerla
//     (`late`), se avivan con el susto (`aviso`) y se quedan en nada si se apaga.
//
// EL HUMO: unas pocas volutas pequeñas, grises y cálidas, de cara a la cámara y
// con el borde roído por un ruido: un hilo de humo de brasero, no una nube. De la
// partícula solo se usa la TRANSPARENCIA (COLOR.a) y la edad; el gris va aquí,
// por lo mismo que en las pavesas: el color de una partícula no llega igual en
// los dos motores.

// 0 el cerco, 1 una voluta de humo.
uniform float es_humo = 0.0;

// --- El cerco
uniform float tiempo = 0.0;
uniform float semilla = 0.0;
// El radio del cerco, en la medida del plano (1 = el borde).
uniform float radio = 0.55;
uniform float brillo = 0.6;
uniform float late = 0.0;
uniform float aviso = 0.0;
// Cuánto tizna: baja cuando la llama está en el aire.
uniform float tizne = 1.0;

uniform vec3 c_hollin : source_color = vec3(0.08, 0.07, 0.10);
uniform vec3 c_rojo : source_color = vec3(0.55, 0.18, 0.18);
uniform vec3 c_naranja : source_color = vec3(0.91, 0.51, 0.29);
uniform vec3 c_oro_claro : source_color = vec3(0.97, 0.85, 0.42);

// --- El humo
uniform vec3 color : source_color = vec3(0.48, 0.46, 0.41);

uniform sampler2D ruido_brasa : filter_linear, repeat_enable;

varying float opaco;
varying float edad;
varying vec2 azar_p;

float azar(float x) {
	return fract(sin(x * 127.1 + semilla * 31.7) * 43758.5453);
}

// El ruido de valor 2D de antes (cuatro `hash` y tres mezclas), leído. Cada
// cuerpo lo lee en otro sitio, como antes cada uno tenía su semilla en el `hash`.
float ruido2(vec2 x) {
	return textureLod(ruido_brasa, (x + vec2(semilla * 5.3, semilla * 2.9)) * (1.0 / 32.0), 0.0).b;
}

void vertex() {
	if (es_humo > 0.5) {
		opaco = COLOR.a;
		edad = INSTANCE_CUSTOM.y;
		azar_p = MODEL_MATRIX[3].xz * 37.0;
		// De cara a la cámara, conservando el tamaño de la partícula.
		float s = length(MODEL_MATRIX[0].xyz);
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s,
			INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (es_humo > 0.5) {
		float n = ruido2(p * 2.4 + azar_p + vec2(0.0, edad * 1.5));
		float n2 = ruido2(p * 5.5 - azar_p);
		float cuerpo = 1.0 - smoothstep(0.25, 0.95, r + (n - 0.5) * 0.75 + (n2 - 0.5) * 0.22);
		ALBEDO = color * (0.75 + 0.5 * n);
		ALPHA = cuerpo * opaco;
	} else {
		float ang = atan(p.y, p.x) + tiempo * 0.10;

		// El tizne: irregular, más negro hacia el centro.
		float borde = radio * (1.10 + (ruido2(p * 3.1) - 0.5) * 0.5);
		float mancha = (1.0 - smoothstep(borde * 0.20, borde, r)) * (0.60 + 0.40 * ruido2(p * 9.0));
		float a_tizne = mancha * 0.55 * tizne;

		// Los rescoldos: el círculo partido en celdas; en cada una, o un grano o nada.
		const float CELDAS = 22.0;
		float celda = floor(ang / 6.2831853 * CELDAS);
		float en_celda = fract(ang / 6.2831853 * CELDAS) - 0.5;
		float hay = step(0.42, azar(celda));
		float r_grano = radio * (0.90 + azar(celda + 7.0) * 0.24);
		float tam = 0.020 + azar(celda + 13.0) * 0.030;
		vec2 d = vec2((en_celda + (azar(celda + 3.0) - 0.5) * 0.5) * 6.2831853 / CELDAS * r, r - r_grano);
		// El contorno, mordido por un ruido: un grano de carbón, no un lunar.
		float dist = length(d * vec2(1.0, 1.2)) + (ruido2(p * 46.0) - 0.5) * tam * 0.7;
		float grano = (1.0 - smoothstep(tam * 0.72, tam, dist)) * hay;
		float lumbre = (1.0 - smoothstep(tam * 0.10, tam * 0.82, dist)) * hay;
		float resplandor = (1.0 - smoothstep(tam * 0.6, tam * 3.2, dist)) * hay;
		// Cada rescoldo respira a su aire.
		float pulso = 0.5 + 0.5 * sin(tiempo * (1.6 + azar(celda + 5.0) * 2.6) + azar(celda) * 6.28);
		float fuerza = brillo * (0.25 + 0.75 * pulso) * (0.55 + 0.9 * azar(celda + 17.0));
		fuerza = mix(fuerza, 0.50 + 0.80 * (0.5 + 0.5 * sin(tiempo * 11.0)), late);
		fuerza += aviso * 1.3;
		vec3 col_lumbre = mix(c_rojo, c_naranja, smoothstep(0.20, 0.70, fuerza));
		col_lumbre = mix(col_lumbre, c_oro_claro, smoothstep(0.80, 1.6, fuerza));
		col_lumbre *= 0.55 + 1.0 * fuerza;

		// Un resplandor muy tenue por dentro del cerco cuando avisa o late.
		float halo = (1.0 - smoothstep(radio * 0.5, radio * 1.25, r)) * smoothstep(0.0, radio * 0.6, r);
		float a_halo = halo * (aviso * 0.28 + late * 0.06);

		// De abajo arriba: el tizne, el resplandor en la losa, el grano y su lumbre.
		vec3 col = c_hollin;
		float a = a_tizne;
		float a_luz = clamp(a_halo + resplandor * 0.30 * clamp(fuerza, 0.0, 1.0), 0.0, 1.0);
		col = mix(col, c_naranja * 1.1, a_luz / max(a + a_luz, 0.001));
		a = clamp(a + a_luz, 0.0, 1.0);
		col = mix(col, c_hollin * 0.7, grano);
		a = max(a, grano * 0.92);
		col = mix(col, col_lumbre, lumbre * clamp(0.25 + fuerza * 1.5, 0.0, 1.0));
		ALBEDO = col;
		ALPHA = a;
	}
}
