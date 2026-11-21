shader_type canvas_item;
render_mode blend_disabled, unshaded;

// CRIPTA 3D · «suelo» · EL HORNO DE LA LOSA.
//
// POR QUÉ EXISTE. En un navegador de Windows el sombreador del suelo se compila
// con Direct3D (ANGLE), y allí cada línea del `fragment` se paga cuatro o cinco
// veces, una por variante de Godot. La losa calculada entera en cada píxel
// costaba 13,7 s de compilar (21-nov-2026, banco + ANGLE): el aparejo 3,3 s, la
// rosa 0,9 y el resto del cuerpo otros 3,3. Y casi nada de eso depende de la
// cámara ni del tiempo: es el mismo suelo en cada fotograma.
//
// Así que se calcula UNA vez, al arrancar, aquí: un sombreador de lienzo (sin
// luces no hay variantes, y compila en décimas) que dibuja el suelo visto desde
// arriba en tres atlas. La losa (`suelo_losa.gdshader`) los lee y hace solo lo
// que cambia de píxel a píxel por debajo de lo que cabe en un mapa (la mella
// del canto, los poros, el relieve del grano y de las celdas), el borde del
// latón, el agua que se mueve, las gotas y el reflejo.
//
// LAS CUENTAS SON LAS DE ANTES, copiadas de la losa: lo que se ve no cambia.
// Las cadenas que la losa aplicaba una detrás de otra a un color o a una
// rugosidad (el surco, el hollín, el labio y el hueco del rebaje) eran mezclas
// con pesos que no dependen de la cámara: aquí se componen en UN factor y UN
// sumando (`K`, `C`, `P`, `Q`), y la losa hace una cuenta en vez de cuatro.
//
// LOS ATLAS (`atlas` y `regiones` los pone `suelo.gd`; cada región cubre el
// suelo entero, o el cuadrado de la rosa):
//   FINO (256 px por unidad, como el mapa A; dos regiones)
//     0  R distancia a la junta (÷0,13) · GB hacia dónde queda la junta · A la raja
//     1  RGB el color de la losa seca (raíz cuadrada) · A la rampa del latón
//   BASTO (128 px por unidad, como el mapa B; seis regiones)
//     2  R rugosidad sin juntas (P) · G cuánto la sube la junta (Q) · B lo bajo (el agua) · A lo seco
//     3  RG inclinación de cada losa · BA pendiente del surco y del labio del rebaje
//     4  R factor del color (K ÷ 1,1) · GBA sumando del color (C ÷ 0,05)
//     5  R basto · G luz (oclusión) · B ancho de la junta · A bisel
//     6  R hoyos · G hollín · B hueco del rebaje · A grano del tizne (S ÷ 0,5)
//     7  las gotas, en el centro de cada celda de 0,45: R semilla · GB origen
//   ROSA (~1160 px por unidad; dos regiones)
//     8  RGB el color de cada tesela (raíz cuadrada) · A la lechada
//     9  RG lo torcida que está · B cuál (su azar) · A dentro de la rosa
//
// Los colores van con su raíz cuadrada: en 8 bits los oscuros de la piedra
// (0,02–0,1) se escalonaban; con la raíz el paso en los oscuros es un tercio.

uniform int atlas = 0;
uniform int regiones = 2;
// x, z, ancho y fondo de mundo que cubre cada región (el suelo, o el cuadrado
// de la rosa).
uniform vec4 rect = vec4(0.0, 5.48, 4.0, 7.52);
// Lo que cubren los mapas A y B, y un píxel del A en unidades de mundo.
uniform vec4 rect_mapa = vec4(0.0, 5.48, 4.0, 7.52);
uniform float paso_mapa = 0.004;

uniform sampler2D tex_manchas : filter_linear_mipmap, repeat_enable;
// Mapa A: R latón (rampa, borde en 0,5) · G surco · B rebaje.
uniform sampler2D mapa_a : filter_linear, repeat_disable, hint_default_black;
// Mapa B: R luz (oclusión, 1 al aire) · G hollín · B uso.
uniform sampler2D mapa_b : filter_linear, repeat_disable, hint_default_white;

// --- la piedra (los tintes salen de la paleta del juego, `suelo.gd`) --------
uniform vec3 piedra_a : source_color = vec3(0.16, 0.16, 0.20);
uniform vec3 piedra_b : source_color = vec3(0.23, 0.22, 0.20);
uniform vec3 piedra_c : source_color = vec3(0.33, 0.32, 0.29);
uniform vec3 color_mugre : source_color = vec3(0.03, 0.025, 0.02);
uniform vec3 color_hollin : source_color = vec3(0.025, 0.02, 0.018);

// --- el aparejo ---------------------------------------------------------------
uniform float alto_hilada = 0.66;
uniform float largo_losa = 0.98;
uniform float partidas = 0.2;          // cuántas losas están rotas
uniform float dobles = 0.35;           // cuántas juntas pares faltan (losa doble)
// EL PIE: de esta z hacia el jugador (bajo las palas, hasta el desagüe) el
// suelo es ADOQUINADO, piezas de un palmo (ver `suelo.gd`, Y_ADOQUIN).
uniform float z_adoquin = 12.46;
uniform vec2 adoquin = vec2(0.21, 0.16);   // largo y alto de una pieza
uniform float adoquin_partidas = 0.12;

// --- el agua ------------------------------------------------------------------
// `bajo` va de 0 a ~1,4; el charco empieza en `nivel_agua` (más bajo = más charco).
uniform float nivel_agua = 0.58;
// Centro (x, z) y radios de la elipse que queda seca alrededor de las palas.
uniform vec4 zona_palas = vec4(2.0, 11.95, 1.25, 0.6);

// --- el emblema ---------------------------------------------------------------
uniform vec3 emblema = vec3(2.14, 10.18, 0.42);   // x, z, radio de las teselas
uniform vec3 tesela_hueso : source_color = vec3(0.55, 0.48, 0.37);
uniform vec3 tesela_ocre : source_color = vec3(0.42, 0.30, 0.12);
uniform vec3 tesela_teja : source_color = vec3(0.36, 0.17, 0.10);
uniform vec3 tesela_pizarra : source_color = vec3(0.09, 0.09, 0.11);
uniform vec3 tesela_carbon : source_color = vec3(0.035, 0.03, 0.03);

// La raja, en el canal A de la región 0: ±0,04 alrededor de 0,5. La losa le
// suma el grano (±0,018), así que lo que pasa de 0,04 ya no puede llegar a su
// labio (0,016): las losas sin raja van a 1.
const float RAJA = 0.04;
// Lo bajo (el agua), en el canal B de la región 2: solo importa la ventana en
// la que cambian el charco y lo húmedo (de nivel − 0,34 a nivel + 0,18, contando
// el +0,1 que le suma la junta en la losa).
const float BAJO_DESDE = 0.4;
const float BAJO_ANCHO = 0.7;
// Las gotas caen en celdas de este lado (la losa lo repite).
const float CELDA_GOTA = 0.45;

float azar(vec2 p) {
	// Sin senos, como en la superficie: en móvil el seno pierde precisión.
	vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

// ----------------------------------------------------------------- el aparejo
// Las juntas entre hiladas no son rectas: cada una tiene su sitio (±14 % del
// alto) y su pendiente. Las juntas de testa, igual dentro de cada hilada.

float junta_hilada(float k, float x, float alto) {
	return k * alto + (azar(vec2(k, 1.3)) - 0.5) * 0.28 * alto
			+ (azar(vec2(k, 4.1)) - 0.5) * 0.05 * (x - 2.0);
}

float junta_testa(float j, float k, float largo, float z, float zc) {
	return (j + azar(vec2(k, 8.7))) * largo + (azar(vec2(j, k + 0.5)) - 0.5) * 0.34 * largo
			+ (azar(vec2(j + 3.1, k)) - 0.5) * 0.14 * (z - zc);
}

bool falta_testa(float j, float k, float prob) {
	return mod(j, 2.0) < 0.5 && azar(vec2(j + 9.2, k + 1.7)) < prob;
}

// Devuelve la distancia al borde de la losa; `id` es quién es, `c` su centro,
// `t` su tamaño y `hacia` la dirección del borde más cercano. El mismo aparejo
// sirve para las losas y para el adoquín del pie: cambian el alto de la
// hilada, el largo, cuántas piezas dobles hay y lo romo de la esquina.
float losa(vec2 p, float alto, float largo_base, float prob_doble, float r,
		out vec2 id, out vec2 c, out vec2 t, out vec2 hacia) {
	float k = floor(p.y / alto);
	float z0 = junta_hilada(k, p.x, alto);
	float z1 = junta_hilada(k + 1.0, p.x, alto);
	if (p.y < z0) {
		k -= 1.0;
		z1 = z0;
		z0 = junta_hilada(k, p.x, alto);
	} else if (p.y >= z1) {
		k += 1.0;
		z0 = z1;
		z1 = junta_hilada(k + 1.0, p.x, alto);
	}
	float zc = 0.5 * (z0 + z1);
	float largo = largo_base * (0.72 + 0.56 * azar(vec2(k, 2.2)));
	float j = floor(p.x / largo - azar(vec2(k, 8.7)));
	float x0 = junta_testa(j, k, largo, p.y, zc);
	float x1 = junta_testa(j + 1.0, k, largo, p.y, zc);
	if (p.x < x0) {
		j -= 1.0;
		x1 = x0;
		x0 = junta_testa(j, k, largo, p.y, zc);
	} else if (p.x >= x1) {
		j += 1.0;
		x0 = x1;
		x1 = junta_testa(j + 1.0, k, largo, p.y, zc);
	}
	// La losa doble: la junta que falta une esta losa con su vecina.
	if (falta_testa(j, k, prob_doble)) {
		j -= 1.0;
		x0 = junta_testa(j, k, largo, p.y, zc);
	} else if (falta_testa(j + 1.0, k, prob_doble)) {
		x1 = junta_testa(j + 2.0, k, largo, p.y, zc);
	}
	id = vec2(j, k);
	c = vec2(0.5 * (x0 + x1), zc);
	t = vec2(x1 - x0, z1 - z0);
	vec4 d = vec4(p.x - x0, x1 - p.x, p.y - z0, z1 - p.y);
	float dx = min(d.x, d.y);
	float dz = min(d.z, d.w);
	hacia = dx < dz ? vec2(d.x < d.y ? -1.0 : 1.0, 0.0) : vec2(0.0, d.z < d.w ? -1.0 : 1.0);
	// Esquinas romas: una esquina a escuadra en piedra vieja no existe.
	if (dx < r && dz < r) {
		vec2 q = vec2(r) - vec2(dx, dz);
		hacia = normalize(vec2(d.x < d.y ? -q.x : q.x, d.z < d.w ? -q.y : q.y) + 1.0e-5);
		return r - length(q);
	}
	return min(dx, dz);
}

// -------------------------------------------------------------- la rosa
// Devuelve qué tesela va en `q` (coordenadas relativas al radio): 0 pizarra,
// 1 hueso, 2 ocre, 3 teja, 4 carbón. −1 fuera.
int rosa(vec2 q) {
	float r = length(q);
	if (r > 1.0) {
		return -1;
	}
	float ang = atan(q.y, q.x);
	if (r > 0.86) {
		// La cenefa: dientes de sierra en teja y hueso.
		float s = fract(ang / 6.2831853 * 28.0);
		float diente = 0.86 + 0.14 * abs(s * 2.0 - 1.0);
		return r < diente ? 3 : 1;
	}
	if (r > 0.80) {
		return 4;
	}
	// Los cuatro vientos grandes, luego los cuatro medios, luego el anillo.
	for (int i = 0; i < 4; i++) {
		float a = float(i) * 1.5707963;
		vec2 f = vec2(cos(a), sin(a));
		vec2 l = vec2(-f.y, f.x);
		float u = dot(q, f);
		float v = dot(q, l);
		if (u > 0.0 && abs(v) < 0.17 * (1.0 - u / 0.78)) {
			return v > 0.0 ? 1 : 2;
		}
	}
	for (int i = 0; i < 4; i++) {
		float a = float(i) * 1.5707963 + 0.7853982;
		vec2 f = vec2(cos(a), sin(a));
		vec2 l = vec2(-f.y, f.x);
		float u = dot(q, f);
		float v = dot(q, l);
		if (u > 0.0 && abs(v) < 0.13 * (1.0 - u / 0.55)) {
			return v > 0.0 ? 3 : 4;
		}
	}
	if (r < 0.08) {
		return 2;
	}
	if (abs(r - 0.62) < 0.025) {
		return 4;
	}
	return 0;
}

// Las teselas van en ANILLOS, como se colocan de verdad alrededor de un emblema
// redondo (en cuadrícula salía una pared de ladrillo pixelada): cada anillo con
// su número de piezas y corrido al azar respecto al de dentro.
vec4 teselas(vec2 p, int modo) {
	float r_emb = length(p - emblema.xy);
	float lado = 0.018;
	vec2 dq = p - emblema.xy;
	float anillo = floor(r_emb / lado);
	float rc = (anillo + 0.5) * lado;
	float cuantas = max(floor(6.2831853 * rc / lado), 3.0);
	float desf = azar(vec2(anillo, 4.4));
	float pos = (atan(dq.y, dq.x) / 6.2831853 + 0.5) * cuantas + desf;
	float celda = floor(pos);
	float fa = fract(pos);
	float fr_r = fract(r_emb / lado);
	vec2 cel = vec2(anillo, mod(celda, cuantas));
	float a_c = ((celda + 0.5 - desf) / cuantas - 0.5) * 6.2831853;
	vec2 centro_t = vec2(cos(a_c), sin(a_c)) * rc;
	float cual = azar(cel + vec2(11.0, 3.0));
	int t = rosa(centro_t / emblema.z);
	if (modo == 9) {
		// Cada tesela un pelo torcida: es lo que hace chispear un mosaico.
		float dentro = (r_emb < emblema.z && t >= 0) ? 1.0 : 0.0;
		return vec4(azar(cel + 1.3), azar(cel + 8.1), cual, dentro);
	}
	float ancho_t = 6.2831853 * rc / cuantas / lado;
	float borde_t = min(min(fr_r, 1.0 - fr_r), min(fa, 1.0 - fa) * ancho_t);
	float lechada = 1.0 - smoothstep(0.06, 0.16, borde_t + (cual - 0.5) * 0.08);
	vec3 tc = tesela_pizarra;
	if (t == 1) { tc = tesela_hueso; }
	else if (t == 2) { tc = tesela_ocre; }
	else if (t == 3) { tc = tesela_teja; }
	else if (t == 4) { tc = tesela_carbon; }
	tc *= 0.82 + 0.36 * cual;
	return vec4(sqrt(tc), lechada);
}

// El suelo en un punto: todo lo que la losa calculaba en cada píxel y no
// depende de la cámara, del tiempo ni del grano fino.
vec4 suelo(vec2 p, int modo) {
	if (modo == 7) {
		// Las gotas: el azar de la celda, leído por la losa en su centro.
		vec2 celda = floor(p / CELDA_GOTA);
		return vec4(azar(celda + 17.0), azar(celda + 2.0), azar(celda + 5.0), 1.0);
	}
	vec2 uv_mapa = (p - rect_mapa.xy) / rect_mapa.zw;
	vec3 ma = textureLod(mapa_a, uv_mapa, 0.0).rgb;
	vec3 mb = textureLod(mapa_b, uv_mapa, 0.0).rgb;
	vec4 manchas = textureLod(tex_manchas, p / 2.2 + vec2(0.37, 0.11), 0.0);
	// La misma mancha a una escala media (un palmo): la forma del charco y la
	// variación de tono dentro de una losa.
	vec4 medio = textureLod(tex_manchas, p / 0.83 + vec2(0.61, 0.23), 0.0);
	float uso = mb.b;
	float luz_horno = mb.r;
	float pulido = clamp(uso * 1.15, 0.0, 1.0);
	float basto = 1.0 - pulido;
	float al_pie = 1.0 - luz_horno;

	// ------------------------------------------------------------- las losas
	// El borde, un pelo ondulado por la mancha grande.
	vec2 pw = p + (manchas.gb - 0.5) * 0.026;
	vec2 id;
	vec2 c;
	vec2 tam;
	vec2 hacia;
	bool en_adoquin = p.y > z_adoquin;
	// Una sola llamada con los números de cada aparejo (dos llamadas son el
	// doble de código que compilar, también en un lienzo).
	float d = losa(pw, en_adoquin ? adoquin.y : alto_hilada, en_adoquin ? adoquin.x : largo_losa,
			en_adoquin ? 0.0 : dobles, en_adoquin ? 0.018 : 0.035, id, c, tam, hacia);
	// Otra familia de piezas: que no compartan su azar con las losas.
	if (en_adoquin) {
		id += vec2(311.0, 517.0);
	}
	// La losa partida: una raja que cruza cerca del centro y la deja en dos
	// mitades que se han asentado distinto. (El temblor de grano de la raja lo
	// pone la losa.)
	float s_raja = 1.0e3;
	if (azar(id + vec2(5.5, 2.9)) < (en_adoquin ? adoquin_partidas : partidas)) {
		float a = azar(id + vec2(1.1, 6.3)) * 3.14159;
		vec2 nr = vec2(cos(a), sin(a));
		vec2 o = c + (vec2(azar(id + 2.3), azar(id + 4.9)) - 0.5) * tam * 0.4;
		s_raja = dot(pw - o, nr);
	}
	// El emblema va en una piedra redonda propia: dentro no hay aparejo.
	float r_emb = length(p - emblema.xy);
	float borde_emb = emblema.z + 0.06;
	bool en_emblema = r_emb < borde_emb;
	if (en_emblema) {
		d = borde_emb - r_emb;
		hacia = normalize(p - emblema.xy + 1.0e-5);
		id = vec2(-77.0, -77.0);
		s_raja = 1.0e3;
	} else if (r_emb < borde_emb + 0.08) {
		// Las losas de alrededor se cortan contra la piedra redonda.
		float d_aro = r_emb - borde_emb;
		if (d_aro < d) {
			d = d_aro;
			hacia = -normalize(p - emblema.xy + 1.0e-5);
		}
	}
	if (modo == 0) {
		return vec4(clamp(d / 0.13, 0.0, 1.0), hacia * 0.5 + 0.5,
				clamp(0.5 + s_raja / (2.0 * RAJA), 0.0, 1.0));
	}
	// Cada mitad de una losa rota con su asiento.
	vec2 sem = id + (s_raja > 0.0 ? vec2(7.0, 3.0) : vec2(0.0));
	// El adoquín, con la junta más fina (es piedra de cantería, no ladrillo) y
	// un pelo más romo que la losa: la MISMA piedra en chico.
	float ancho_j = mix(0.0042, 0.003, pulido) * (en_adoquin ? 0.7 : 1.0);
	float bisel = mix(0.012, 0.02, pulido) * (en_adoquin ? 1.15 : 1.0);
	if (modo == 5) {
		return vec4(basto, luz_horno, (ancho_j - 0.002) / 0.0025, (bisel - 0.011) / 0.013);
	}
	if (modo == 1) {
		// --------------------------------------------------- el color, seco
		// PIEDRA PULIDA POR EL USO, NO FIELTRO: la variación es de baja
		// frecuencia (de losa a losa, y manchas de un palmo). Lo fino (los poros,
		// el grano) lo pone la losa encima, en cada píxel.
		// Cuánto se distingue una pieza de la de al lado: en el adoquín, un tercio
		// que en la losa (pieza a pieza con el contraste de una losa era un damero).
		float var_pieza = en_adoquin ? 0.35 : 1.0;
		vec3 alb = mix(piedra_b, piedra_a, 0.5 + (smoothstep(0.1, 0.9, azar(id + 2.1)) - 0.5) * var_pieza);
		alb = mix(alb, piedra_c, step(0.75, azar(id + 3.3)) * 0.55 * var_pieza);
		// Unas más calientes, otras más frías: no todas salieron de la misma cantera.
		alb *= mix(vec3(1.0), mix(vec3(1.04, 1.0, 0.95), vec3(0.96, 0.99, 1.03), azar(id + 7.7)), var_pieza);
		alb *= 0.86 + 0.28 * manchas.r;
		alb *= 0.93 + 0.14 * medio.r;
		// Alguna veta clara, como de caliza, solo en unas losas.
		float veta = smoothstep(0.9, 0.97, manchas.b) * step(0.6, azar(id + 9.9));
		alb = mix(alb, piedra_c * 1.1, veta * 0.25);
		// La mugre: en el fondo de la junta, al pie de las paredes y a parches
		// donde no se pisa. Lo pulido está limpio. (Con la distancia sin mellar:
		// la mella mueve el canto medio milímetro, y aquí el alcance es de 7 cm.)
		// En el adoquín, un palmo de mugre junto a la junta era la pieza entera.
		float parche = smoothstep(0.55, 0.85, manchas.g + (medio.g - 0.5) * 0.3) * basto;
		float cerca_junta = 1.0 - smoothstep(ancho_j, ancho_j + (en_adoquin ? 0.025 : 0.07), d);
		float m_mugre = clamp(parche * 0.5 + cerca_junta * 0.3 * basto + al_pie * 0.5, 0.0, 1.0);
		alb = mix(alb, color_mugre, m_mugre * 0.55);
		// Lo pulido es más oscuro y más saturado: le falta el polvo que lo blanquea.
		float gris = dot(alb, vec3(0.3, 0.59, 0.11));
		alb = mix(vec3(gris), alb, 1.0 + pulido * 0.3) * (1.0 - pulido * 0.15);
		return vec4(sqrt(max(alb, vec3(0.0))), ma.r);
	}

	// Lo que va detrás de la junta, en el orden en que la losa lo aplicaba: el
	// surco (gastado por la bola: más liso, un pelo más claro, piedra fresca), el
	// hollín, el labio y el hueco del rebaje. Son cuatro zonas que no se tocan
	// con el latón ni con la rosa, así que pueden ir delante de ellos.
	float surco = ma.g;
	float hueco = smoothstep(0.42, 0.62, ma.b);
	float labio = smoothstep(0.1, 0.42, ma.b) * (1.0 - hueco);
	// El hollín de los braseros: por dentro del aro de latón (mb.g ≥ 0,7),
	// tizne entero; por fuera, un cerco de ceniza que se va apagando, con la
	// forma de la mancha media. Nada fino toca la forma (era piel de vaca), y
	// fuera del aro no pasa de media ceniza.
	float dentro = 0.0;
	float hol = 0.0;
	if (mb.g > 0.0) {
		dentro = smoothstep(0.55, 0.85, mb.g);
		float cerco = smoothstep(0.0, 0.8, mb.g + (manchas.g - 0.5) * 0.3 + (medio.g - 0.5) * 0.25);
		hol = max(dentro * 0.9, cerco * cerco * 0.5);
	}
	if (modo == 6) {
		// Alguna grieta fina, a trozos y solo en lo basto (dónde; el hoyo lo
		// pone la losa con las celdas). Y el grano del tizne: la ceniza del
		// centro varía de tono con el grano fino (la losa le pone el grano).
		float hoyos = smoothstep(0.8, 0.93, manchas.b * 0.6 + manchas.r * 0.4) * basto;
		float s_tizne = 0.475 * hol * dentro * (1.0 - 0.55 * labio) * (1.0 - hueco);
		return vec4(hoyos, hol, hueco, s_tizne / 0.5);
	}
	if (modo == 4) {
		// El color: alb ← alb·K + C, compuesto paso a paso.
		//   surco   mix(alb, alb·1,12 + 0,006, surco·0,5)
		//   hollín  mix(alb, mix(alb·0,55 + hollín, hollín·(0,8 + 0,5·grano), tizne), hol·0,95)
		//   labio   alb·(1 − 0,55·labio)
		//   hueco   mix(alb, (0,006; 0,005; 0,005), hueco)
		float k = 1.0 + 0.06 * surco;
		vec3 cc = vec3(0.003 * surco);
		float k_h = 1.0 - 0.95 * hol + 0.5225 * hol * (1.0 - dentro);
		k *= k_h;
		cc = cc * k_h + color_hollin * (0.95 * hol * (1.0 - 0.2 * dentro));
		k *= 1.0 - 0.55 * labio;
		cc *= 1.0 - 0.55 * labio;
		k *= 1.0 - hueco;
		cc = cc * (1.0 - hueco) + vec3(0.006, 0.005, 0.005) * hueco;
		return vec4(k / 1.1, clamp(cc / 0.05, 0.0, 1.0));
	}
	if (modo == 3) {
		// Cada losa (y cada mitad de una rota) un poco inclinada. El surco y el
		// labio del rebaje, con las pendientes del mapa A como siempre.
		vec3 ma_x = textureLod(mapa_a, uv_mapa + vec2(paso_mapa / rect_mapa.z, 0.0), 0.0).rgb;
		vec3 ma_z = textureLod(mapa_a, uv_mapa + vec2(0.0, paso_mapa / rect_mapa.w), 0.0).rgb;
		vec3 dma_x = (ma_x - ma) / paso_mapa;
		vec3 dma_z = (ma_z - ma) / paso_mapa;
		vec2 pend = -vec2(dma_x.g, dma_z.g) * 0.0025 - vec2(dma_x.b, dma_z.b) * 0.006 * labio;
		return vec4(azar(sem + 1.7), azar(sem + 5.1), clamp(pend * 2.0 + 0.5, 0.0, 1.0));
	}

	// modo 2: la rugosidad y el agua.
	// Lo pulido coge un lustre suave (rugosidad media, no espejo); lo basto,
	// mate. La variación, a la escala del palmo y no a la del grano. Detrás de la
	// junta (que la sube a 0,95 en la losa) van el surco, el hollín y el hueco:
	// rug ← A·rug + B, así que rug = P + Q·junta.
	float rug = mix(0.8, 0.5, pulido) + (medio.g - 0.5) * 0.12;
	float a_r = (1.0 - 0.8 * surco) * (1.0 - hol) * (1.0 - hueco);
	float b_r = ((0.256 * surco) * (1.0 - hol) + 0.93 * hol) * (1.0 - hueco) + hueco;
	// --------------------------------------------------------- el agua
	// DÓNDE SE ENCHARCA: en la JUNTA (corre por ella) y al PIE DE LAS PAREDES,
	// con la forma de la mancha grande y la media, y lo que pisa la bola queda
	// SECO. Es un PRODUCTO y no una suma: la forma solo llega a charco en un
	// SITIO donde el agua para. Con `d` y no con la distancia mellada: la mella
	// metía el grano en el borde del agua (dientes blancos).
	float hundida = azar(sem + 6.6);
	float junto_junta = 1.0 - smoothstep(0.0, 0.13, d);
	float forma = manchas.a * 0.6 + medio.a * 0.4;
	float sitio = clamp(max(al_pie * 2.2, junto_junta * 0.85), 0.0, 1.0);
	float bajo = forma * (0.45 + 0.75 * sitio) + hundida * 0.05 - uso * 0.42;
	if (en_emblema) {
		bajo -= 0.3;
	}
	// LA ZONA DE PALAS, SECA SIEMPRE: es lo que más tiene que leerse, y un
	// charco oscuro ahí se come la bola justo cuando hay que golpear.
	float en_palas = 1.0 - smoothstep(0.75, 1.0, length((p - zona_palas.xy) / zona_palas.zw));
	float seco = (1.0 - hueco) * (1.0 - hol * 0.7) * (1.0 - en_palas);
	// El umbral (charco y húmedo) lo cruza la losa, porque la junta le suma 0,1
	// a «lo bajo» en sus 4 mm: el agua corre por ella. Horneándolo entero, las
	// juntas de lo húmedo salían un pelo más claras (se ve a 4×, en el adoquín).
	return vec4(a_r * rug + b_r, a_r * (0.95 - rug) * 0.8,
			clamp((bajo - (nivel_agua - BAJO_DESDE)) / BAJO_ANCHO, 0.0, 1.0), seco);
}

void fragment() {
	// Qué región del atlas es este píxel, y qué punto del suelo (o de la rosa).
	float x = UV.x * float(regiones);
	float region = floor(x);
	vec2 p = rect.xy + vec2(x - region, UV.y) * rect.zw;
	if (atlas == 2) {
		COLOR = teselas(p, 8 + int(region));
	} else {
		COLOR = suelo(p, (atlas == 0 ? 0 : 2) + int(region));
	}
}
