shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// CRIPTA 3D · «suelo» · LA LOSA.
//
// La superficie más grande de la pantalla, así que aquí no vale el sombreador
// de todo lo demás (`superficie.gdshaderinc`): ese sabe hacer piedra en
// cualquier cara, y el suelo necesita cosas que solo tiene el suelo. Lee las
// MISMAS tres texturas de ruido, con los mismos colores de la paleta, para que
// case con el sillar de las paredes; lo demás es suyo:
//
//   · LAS LOSAS, grandes y desiguales: hiladas de alto distinto, juntas que no
//     van a escuadra, alguna losa doble y alguna partida. Todo en coordenadas
//     de mundo: el suelo va en trozos y no se ve ninguna costura.
//   · EL ADOQUÍN del pie, de las palas al desagüe: el mismo aparejo, en chico.
//   · EL USO: pulida, con lustre, donde pasa la bola; basta y con mugre en los
//     bordes. La piedra varía a BAJA frecuencia (de losa a losa, manchas de un
//     palmo) y lo único fino son los poros: el grano fino en el color y en la
//     normal fue lo que la revisión llamó «fieltro».
//   · EL AGUA: en las juntas y al pie de las paredes, con borde ancho y blando, y
//     SECA en la zona de palas y en el camino de la bola. Moja la losa (la
//     oscurece la mitad, no a negro) y encima le suma el reflejo.
//   · EL REFLEJO DE VERDAD: la imagen de la cámara espejo, SUMADA a la losa
//     mojada y con Fresnel, abierta en vertical según la rugosidad (el reguero
//     de luz del suelo mojado de Saltline), torcida por el relieve.
//   · LO HORNEADO (`suelo_mapas.gdshader`): la oclusión al pie de cada pieza, el
//     latón embutido, los surcos, el hollín de los braseros, el rebaje de las
//     bocas.
//   · EL EMBLEMA: una rosa de los vientos de teselas en el centro de la plaza.
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
uniform sampler2D tex_manchas : filter_linear_mipmap, repeat_enable;
// Mapa A: R latón (rampa, borde en 0,5) · G surco · B rebaje.
uniform sampler2D mapa_a : filter_linear_mipmap, repeat_disable, hint_default_black;
// Mapa B: R luz (oclusión, 1 al aire) · G hollín · B uso.
uniform sampler2D mapa_b : filter_linear_mipmap, repeat_disable, hint_default_white;
// x, z, ancho y fondo de mundo que cubren los dos mapas.
uniform vec4 rect_mapa = vec4(0.0, 5.48, 4.0, 7.52);
// Un píxel del mapa A, en unidades de mundo (para sacar pendientes).
uniform float paso_mapa = 0.004;

// --- la piedra (los tintes salen de la paleta del juego, `suelo.gd`) --------
uniform vec3 piedra_a : source_color = vec3(0.16, 0.16, 0.20);
uniform vec3 piedra_b : source_color = vec3(0.23, 0.22, 0.20);
uniform vec3 piedra_c : source_color = vec3(0.33, 0.32, 0.29);
uniform vec3 color_mugre : source_color = vec3(0.03, 0.025, 0.02);
uniform vec3 color_hollin : source_color = vec3(0.025, 0.02, 0.018);
uniform vec3 color_laton : source_color = vec3(0.88, 0.65, 0.24);
uniform vec3 color_laton_viejo : source_color = vec3(0.54, 0.40, 0.14);
uniform vec3 color_cardenillo : source_color = vec3(0.17, 0.20, 0.12);

// --- el aparejo ---------------------------------------------------------------
uniform float alto_hilada = 0.66;
uniform float largo_losa = 0.98;
uniform float partidas = 0.2;          // cuántas losas están rotas
uniform float dobles = 0.35;           // cuántas juntas pares faltan (losa doble)
// EL PIE: de esta z hacia el jugador (bajo las palas, hasta el desagüe) el
// suelo es ADOQUINADO, piezas de un palmo. Entre las palas y el desagüe había
// cuatro losas enormes sin nada (el «tercio muerto» de la revisión): el adoquín
// le da escala a la zona que más ve el jugador sin poner nada que estorbe. Un
// listón de latón (`suelo.gd`, BANDAS) tapa la costura entre los dos aparejos.
uniform float z_adoquin = 12.46;
uniform vec2 adoquin = vec2(0.21, 0.16);   // largo y alto de una pieza
uniform float adoquin_partidas = 0.12;

// --- el agua ------------------------------------------------------------------
// `bajo` (ver «el agua» abajo) va de 0 a ~1,4; el charco empieza en `nivel_agua`.
uniform float nivel_agua = 0.58;      // más bajo = más charco
uniform float lluvia = 1.0;            // las gotas que caen en los charcos
// Centro (x, z) y radios de la elipse que queda seca alrededor de las palas.
uniform vec4 zona_palas = vec4(2.0, 11.95, 1.25, 0.6);

// --- el emblema ---------------------------------------------------------------
uniform vec3 emblema = vec3(2.14, 10.18, 0.42);   // x, z, radio de las teselas
uniform vec3 tesela_hueso : source_color = vec3(0.55, 0.48, 0.37);
uniform vec3 tesela_ocre : source_color = vec3(0.42, 0.30, 0.12);
uniform vec3 tesela_teja : source_color = vec3(0.36, 0.17, 0.10);
uniform vec3 tesela_pizarra : source_color = vec3(0.09, 0.09, 0.11);
uniform vec3 tesela_carbon : source_color = vec3(0.035, 0.03, 0.03);

uniform int depura = 0;   // 1 oclusión · 2 agua · 3 uso · 4 mapa A · 5 normal · 6 losas · 7 charco, hollín y relleno · 8 solo el reflejo

varying vec3 v_mundo;

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

void vertex() {
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = v_mundo.xz;
	vec3 n_malla = NORMAL;

	// --------------------------------------------------------------- lecturas
	// Las teselas de grano (0,55) y de manchas (2,2) son las de la piedra de la
	// biblioteca (`PIEDRA_GRANO`, `PIEDRA_MANCHAS`): una sola piedra.
	vec4 manchas = texture(tex_manchas, p / 2.2 + vec2(0.37, 0.11));
	// La misma mancha a una escala media (un palmo): la forma del charco y la
	// variación de tono dentro de una losa. Nada de lo que da forma al agua o al
	// color de la losa seca baja de aquí: lo fino es solo poro y relieve.
	vec4 medio = texture(tex_manchas, p / 0.83 + vec2(0.61, 0.23));
	vec4 grano = texture(tex_grano, p / 0.55);
	vec4 fino = texture(tex_grano, p / 0.19 + vec2(0.53, 0.29));
	vec4 celdas = texture(tex_celdas, p / 1.3 + vec2(0.21, 0.71));
	vec2 uv_mapa = (p - rect_mapa.xy) / rect_mapa.zw;
	vec3 ma = texture(mapa_a, uv_mapa).rgb;
	vec3 mb = texture(mapa_b, uv_mapa).rgb;
	vec3 ma_x = texture(mapa_a, uv_mapa + vec2(paso_mapa / rect_mapa.z, 0.0)).rgb;
	vec3 ma_z = texture(mapa_a, uv_mapa + vec2(0.0, paso_mapa / rect_mapa.w)).rgb;
	// Pendientes de lo horneado (por unidad de mundo).
	vec3 dma_x = (ma_x - ma) / paso_mapa;
	vec3 dma_z = (ma_z - ma) / paso_mapa;

	float luz_horno = mb.r;
	float uso = mb.b;
	float surco = ma.g;
	float rebaje = ma.b;

	// ------------------------------------------------------------- las losas
	// El borde, un pelo ondulado por la mancha grande y mellado por el grano.
	vec2 pw = p + (manchas.gb - 0.5) * 0.026;
	vec2 id;
	vec2 c;
	vec2 tam;
	vec2 hacia;
	bool en_adoquin = p.y > z_adoquin;
	float d;
	if (en_adoquin) {
		d = losa(pw, adoquin.y, adoquin.x, 0.0, 0.018, id, c, tam, hacia);
		// Otra familia de piezas: que no compartan su azar con las losas.
		id += vec2(311.0, 517.0);
	} else {
		d = losa(pw, alto_hilada, largo_losa, dobles, 0.035, id, c, tam, hacia);
	}
	float de_losa = azar(id + vec2(3.7, 11.1));

	// La losa partida: una raja que cruza cerca del centro y la deja en dos
	// mitades que se han asentado distinto.
	float mitad = 0.0;
	float d_raja = 1.0e3;
	if (azar(id + vec2(5.5, 2.9)) < (en_adoquin ? adoquin_partidas : partidas)) {
		float a = azar(id + vec2(1.1, 6.3)) * 3.14159;
		vec2 nr = vec2(cos(a), sin(a));
		vec2 o = c + (vec2(azar(id + 2.3), azar(id + 4.9)) - 0.5) * tam * 0.4;
		float s = dot(pw - o, nr) + (grano.r - 0.5) * 0.03 + (fino.r - 0.5) * 0.006;
		d_raja = abs(s);
		mitad = s > 0.0 ? 1.0 : 0.0;
	}

	// El emblema va en una piedra redonda propia: dentro no hay aparejo.
	float r_emb = length(p - emblema.xy);
	float borde_emb = emblema.z + 0.06;
	bool en_emblema = r_emb < borde_emb;
	if (en_emblema) {
		d = borde_emb - r_emb;
		hacia = normalize(p - emblema.xy + 1.0e-5);
		id = vec2(-77.0, -77.0);
		de_losa = 0.62;
		d_raja = 1.0e3;
	} else if (r_emb < borde_emb + 0.08) {
		// Las losas de alrededor se cortan contra la piedra redonda.
		float d_aro = r_emb - borde_emb;
		if (d_aro < d) {
			d = d_aro;
			hacia = -normalize(p - emblema.xy + 1.0e-5);
		}
	}

	// Lo pulido tiene el canto más redondo y la junta más limpia; lo basto, el
	// canto mellado.
	float pulido = clamp(uso * 1.15, 0.0, 1.0);
	float mella = (grano.r - 0.55) * 0.007 + (fino.a - 0.5) * 0.004 * (1.0 - pulido);
	float dj = d + mella;
	// El adoquín, con la junta más fina: es piedra de cantería, no ladrillo.
	float ancho_j = mix(0.0042, 0.003, pulido) * (en_adoquin ? 0.7 : 1.0);
	// El adoquín, un pelo más romo que la losa. Llegó a llevar el canto al doble
	// (1,9) y con la junta oscura cada pieza salía como un cojín con contorno
	// negro: «otro idioma», dijo la revisión. Es la MISMA piedra en chico.
	float bisel = mix(0.012, 0.02, pulido) * (en_adoquin ? 1.15 : 1.0);
	// Cuánto se distingue una pieza de la de al lado: en el adoquín, un tercio
	// que en la losa (pieza a pieza con el contraste de una losa era un damero).
	float var_pieza = en_adoquin ? 0.35 : 1.0;
	// Dos cosas distintas: la JUNTA (el hueco con mortero, estrecho) y el
	// BISEL (el canto gastado que cae hacia ella). Pintar el bisel del color de
	// la junta daba un trazo negro el triple de ancho: un dibujo a tinta.
	float sj = clamp((dj - ancho_j) / bisel, 0.0, 1.0);
	float en_junta = 1.0 - smoothstep(ancho_j * 0.5, ancho_j + 0.0022, dj);
	float en_bisel = 1.0 - sj * sj * (3.0 - 2.0 * sj);
	float en_raja = 1.0 - smoothstep(0.0012, 0.0035, d_raja);
	// La pendiente del bisel, hacia fuera de la losa.
	vec2 pend = -hacia * (6.0 * sj * (1.0 - sj) / bisel) * 0.0035;

	// Cada losa (y cada mitad de una rota) un poco inclinada y un poco hundida.
	vec2 sem = id + vec2(mitad * 7.0, mitad * 3.0);
	vec2 inclina = (vec2(azar(sem + 1.7), azar(sem + 5.1)) - 0.5);
	float hundida = azar(sem + 6.6);
	pend += inclina * 0.025 * (1.0 - en_bisel);

	// -------------------------------------------------------------- el color
	// PIEDRA PULIDA POR EL USO, NO FIELTRO. La versión anterior modulaba el color
	// con el grano fino (±21 % a 0,62 m y ±8 % a 0,19 m), le ponía «motas» claras
	// de árido y le metía a la normal el relieve de los dos granos: con la luz
	// rasante de la luna aquello era un moteado blanco de alta frecuencia que la
	// revisión leyó como moqueta. Una losa pisada durante siglos es lisa: su
	// variación es de baja frecuencia (de losa a losa, y manchas de un palmo) y lo
	// único fino que le queda son los POROS, oscuros y pequeños.
	vec3 alb = mix(piedra_b, piedra_a, 0.5 + (smoothstep(0.1, 0.9, azar(id + 2.1)) - 0.5) * var_pieza);
	alb = mix(alb, piedra_c, step(0.75, azar(id + 3.3)) * 0.55 * var_pieza);
	// Unas más calientes, otras más frías: no todas salieron de la misma cantera.
	alb *= mix(vec3(1.0), mix(vec3(1.04, 1.0, 0.95), vec3(0.96, 0.99, 1.03), azar(id + 7.7)), var_pieza);
	alb *= 0.86 + 0.28 * manchas.r;
	alb *= 0.93 + 0.14 * medio.r;
	alb *= 1.0 + (grano.a - 0.5) * 0.06;
	// Alguna veta clara, como de caliza, solo en unas losas.
	float veta = smoothstep(0.9, 0.97, manchas.b) * step(0.6, azar(id + 9.9));
	alb = mix(alb, piedra_c * 1.1, veta * 0.25);
	// Los poros: oscuros, pequeños y salteados. Rellenos de mugre, así que no
	// los borra el pulido.
	// (Con el grano grande salían manchas de camuflaje de dos dedos: el poro sale
	// del grano FINO, y solo de su cola.)
	float poro = smoothstep(0.93, 0.985, 1.0 - fino.a) * smoothstep(0.3, 0.6, grano.r);
	alb *= 1.0 - poro * 0.3;

	// La mugre: en el fondo de la junta, al pie de las paredes y a parches donde
	// no se pisa. Lo pulido está limpio.
	float basto = 1.0 - pulido;
	float al_pie = 1.0 - luz_horno;
	float parche = smoothstep(0.55, 0.85, manchas.g + (medio.g - 0.5) * 0.3) * basto;
	// En el adoquín, un palmo de mugre junto a la junta era la pieza entera.
	float cerca_junta = 1.0 - smoothstep(ancho_j, ancho_j + (en_adoquin ? 0.025 : 0.07), dj);
	float m_mugre = clamp(parche * 0.5 + cerca_junta * 0.3 * basto + al_pie * 0.5, 0.0, 1.0);
	alb = mix(alb, color_mugre, m_mugre * 0.55);
	// Lo pulido es más oscuro y más saturado: le falta el polvo que lo blanquea.
	float gris = dot(alb, vec3(0.3, 0.59, 0.11));
	alb = mix(vec3(gris), alb, 1.0 + pulido * 0.3) * (1.0 - pulido * 0.15);
	// El mortero que queda en la junta: oscuro, no negro (un trazo negro es un
	// dibujo a tinta, no una junta).
	// En el adoquín, la junta más clara y el canto menos hundido: con los de la
	// losa, a esa escala, la junta era un contorno negro de dibujo animado.
	alb = mix(alb, mix(color_mugre, piedra_a * 0.45, 0.5), max(en_junta, en_raja) * (en_adoquin ? 0.6 : 1.0));
	alb *= 1.0 - en_bisel * (en_adoquin ? 0.1 : 0.22);

	// Lo pulido coge un lustre suave (rugosidad media, no espejo); lo basto,
	// mate. La variación, a la escala del palmo y no a la del grano.
	float rug = mix(0.8, 0.5, pulido) + (medio.g - 0.5) * 0.12;
	rug = mix(rug, 0.95, max(en_junta, en_raja) * 0.8);

	// El relieve: una ondulación suave y poco más. El grano en la normal era la
	// otra mitad del fieltro (cada píxel cogía la luz distinto).
	float relieve = mix(0.2, 0.05, pulido);
	pend += (grano.gb - 0.5) * 2.0 * relieve * 0.2;
	pend += (celdas.gb - 0.5) * 0.03 * basto;
	// Alguna grieta fina, a trozos y solo en lo basto: la red entera de las
	// celdas era barro seco, no piedra.
	float hoyo = (1.0 - smoothstep(0.0, 0.09, celdas.a))
			* smoothstep(0.8, 0.93, manchas.b * 0.6 + manchas.r * 0.4) * basto;
	alb *= 1.0 - hoyo * 0.55;

	// ------------------------------------------------------------- el surco
	// Gastado por la bola: más liso, un pelo más claro (piedra fresca), y hondo.
	pend += -vec2(dma_x.g, dma_z.g) * 0.0025;
	alb = mix(alb, alb * 1.12 + 0.006, surco * 0.5);
	rug = mix(rug, 0.32, surco * 0.8);

	// ------------------------------------------------------------- la rosa
	float laton = 0.0;
	if (en_emblema && r_emb < emblema.z) {
		// Las teselas van en ANILLOS, como se colocan de verdad alrededor de un
		// emblema redondo (en cuadrícula salía una pared de ladrillo pixelada):
		// cada anillo con su número de piezas y corrido al azar respecto al de
		// dentro.
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
		float ancho_t = 6.2831853 * rc / cuantas / lado;
		float borde_t = min(min(fr_r, 1.0 - fr_r), min(fa, 1.0 - fa) * ancho_t);
		float lechada = 1.0 - smoothstep(0.06, 0.16, borde_t + (cual - 0.5) * 0.08);
		vec3 tc = tesela_pizarra;
		if (t == 1) { tc = tesela_hueso; }
		else if (t == 2) { tc = tesela_ocre; }
		else if (t == 3) { tc = tesela_teja; }
		else if (t == 4) { tc = tesela_carbon; }
		tc *= 0.82 + 0.36 * cual;
		tc *= 1.0 + (fino.a - 0.5) * 0.25;
		if (t >= 0) {
			alb = mix(tc, color_mugre, lechada * 0.85);
			// Cada tesela un pelo torcida: es lo que hace chispear un mosaico.
			pend = (vec2(azar(cel + 1.3), azar(cel + 8.1)) - 0.5) * 0.09 * (1.0 - lechada)
					+ (fino.gb - 0.5) * 0.04;
			rug = mix(0.34 + 0.18 * cual, 0.9, lechada);
		}
	}

	// ------------------------------------------------------------- el hollín
	float hol = 0.0;
	if (mb.g > 0.0) {
		// Por dentro del aro de latón (mb.g ≥ 0,7), tizne entero. Por fuera, un
		// cerco de ceniza que se va apagando, con la forma de la mancha media.
		// Antes el borde de fuera salía de un umbral corto (0,42–0,58) sobre el
		// grano y el poro: manchones casi negros de borde recortado, a pimienta en
		// la orilla, que la revisión leyó como piel de vaca y como charcos duros
		// en la zona de los braseros. Ahora nada fino toca la forma, el borde
		// cae en todo el alcance y fuera del aro no pasa de media ceniza.
		float dentro = smoothstep(0.55, 0.85, mb.g);
		float cerco = smoothstep(0.0, 0.8, mb.g + (manchas.g - 0.5) * 0.3 + (medio.g - 0.5) * 0.25);
		hol = max(dentro * 0.9, cerco * cerco * 0.5);
		// La ceniza de la orilla es gris, no negra: tizne en el centro, polvo
		// quemado alrededor (la variación de tono dentro de la mancha).
		vec3 tizne = mix(alb * 0.55 + color_hollin, color_hollin * (0.8 + 0.5 * fino.a), dentro);
		alb = mix(alb, tizne, hol * 0.95);
		rug = mix(rug, 0.93, hol);
	}

	// ------------------------------------------------------------- el latón
	float w = max(fwidth(ma.r) * 0.8, 0.02);
	laton = smoothstep(0.5 - w, 0.5 + w, ma.r);
	float costura = 1.0 - smoothstep(0.0, 0.09, abs(ma.r - 0.5));
	if (laton > 0.0 || costura > 0.0) {
		// El latón es lo único que brilla LIMPIO (LEEME). Con la pátina sacada del
		// grano fino salía a lunares, y sacada de las manchas de un palmo, a
		// manchas de leopardo a lo largo del listón (lo mismo que se les quitó a
		// los raíles). La pátina va SOLO EN LOS HUECOS: la orilla donde el metal
		// se mete bajo la piedra (el mapa cerca de 0,5) y al pie de lo que tapa
		// (la oclusión horneada). Lo de en medio, limpio y casi liso.
		float orilla = 1.0 - smoothstep(0.5, 0.75, ma.r);
		float viejo = clamp(orilla * 0.8 + al_pie * 0.9, 0.0, 1.0) * (1.0 - pulido * 0.5);
		vec3 lc = mix(color_laton, color_laton_viejo, 0.2 + viejo * 0.45);
		lc *= 0.96 + 0.05 * (fino.a - 0.5);
		lc = mix(lc, color_cardenillo, viejo * al_pie * 0.4);
		lc *= 1.0 - hol * 0.75;
		alb = mix(alb, lc, laton);
		// El rayado fino, en la rugosidad y en la normal, casi nada: era la otra
		// mitad del moteado.
		rug = mix(rug, mix(0.3, 0.55, viejo) + (fino.r - 0.5) * 0.04 + hol * 0.3, laton);
		// El latón embutido queda a ras; el canto, gastado, cae un poco.
		pend = mix(pend, vec2(dma_x.r, dma_z.r) * 0.005 + (fino.gb - 0.5) * 0.012, laton);
		alb = mix(alb, color_mugre * 0.5, costura * 0.75);
	}

	// ------------------------------------------------------------- el rebaje
	float hueco = smoothstep(0.42, 0.62, rebaje);
	float labio = smoothstep(0.1, 0.42, rebaje) * (1.0 - hueco);
	pend -= vec2(dma_x.b, dma_z.b) * 0.006 * labio;
	alb = mix(alb, alb * 0.45, labio);
	alb = mix(alb, vec3(0.006, 0.005, 0.005), hueco);
	rug = mix(rug, 1.0, hueco);

	// --------------------------------------------------------------- el agua
	// DÓNDE SE ENCHARCA. Antes el agua seguía la losa —la losa hundida entera,
	// el lado al que se inclina—, así que el charco acababa en el canto recto de
	// la junta: rectángulos de espejo pegados a losas secas, que se leían como
	// agujeros. Y sumaba el USO, o sea que mojaba justo el camino de la bola y la
	// zona de palas. Ahora el agua busca la JUNTA (corre por ella) y el PIE DE LAS
	// PAREDES (la oclusión horneada), con la forma de la mancha grande y la media,
	// y lo que pisa la bola queda SECO (decisión 5 de la revisión). Nada de ruido
	// fino en el umbral: el borde roto en flecos era tela rasgada.
	// Es un PRODUCTO y no una suma: la forma (las dos manchas) solo llega a
	// charco en un SITIO donde el agua para (junta, pie de pared). Sumando, la
	// junta sola ya mojaba una red entera por todo el campo.
	// Con `d` y no con `dj`: la mella del canto metía el grano en el borde del
	// agua y la orilla salía escarchada, en dientes blancos.
	float junto_junta = 1.0 - smoothstep(0.0, 0.13, d);
	float forma = manchas.a * 0.6 + medio.a * 0.4;
	float sitio = clamp(max(al_pie * 2.2, junto_junta * 0.85), 0.0, 1.0);
	float bajo = forma * (0.45 + 0.75 * sitio) + max(en_junta, en_raja) * 0.1
			+ hundida * 0.05 - uso * 0.42;
	if (en_emblema) {
		bajo -= 0.3;
	}
	// LA ZONA DE PALAS, SECA SIEMPRE: es lo que más tiene que leerse, y un charco
	// oscuro ahí se come la bola justo cuando hay que golpear (decisión 5).
	float en_palas = 1.0 - smoothstep(0.75, 1.0, length((p - zona_palas.xy) / zona_palas.zw));
	float seco = (1.0 - hueco) * (1.0 - hol * 0.7) * (1.0 - en_palas);
	// Un borde ancho y blando: de seco a húmedo en un palmo, de húmedo a charco
	// en dos o tres dedos.
	// (0,18 y no 0,1: con el borde corto, el charco suelto junto a un brasero
	// salía recortado, una mancha pegada y no agua que se seca hacia fuera.)
	float charco = smoothstep(nivel_agua, nivel_agua + 0.18, bajo) * seco;
	float humedo = smoothstep(nivel_agua - 0.24, nivel_agua + 0.04, bajo) * seco;
	// La piedra mojada oscurece y se satura, pero SIGUE SIENDO PIEDRA: el charco
	// deja la losa a media luz, no a un 30 % (lo que, sin nada que reflejar,
	// dejaba un hueco negro).
	float g2 = dot(alb, vec3(0.3, 0.59, 0.11));
	float moja = max(humedo * 0.7, charco);
	alb = mix(vec3(g2), alb, 1.0 + 0.25 * moja) * (1.0 - (0.26 * humedo + 0.2 * charco) * (1.0 - laton));
	// El charco no es un espejo de 0,04: alrededor, la piedra pulida coge el
	// lustre ancho de la luna y del fuego, y un charco perfectamente liso lo
	// pierde y se queda más OSCURO que su orilla seca (otra vez el agujero). Con
	// 0,2 conserva parte de ese lustre y el reflejo sale algo abierto.
	// EL BORDE DE LO MOJADO NO PUEDE SER EL SITIO MÁS LISO (último retoque). La
	// luz directa veía lo húmedo a max(rug·0,56; 0,35) y el charco a 0,46: entre
	// los dos —justo donde lo húmedo ya estaba entero y el charco aún no
	// empezaba— quedaba un anillo MÁS LISO que lo de dentro y lo de fuera, y
	// además con todo el grano en la normal, que solo se alisaba con el charco.
	// Bajo la luna cada mancha que sigue a una grieta salía con un ribete blanco
	// (no da error: se ve). Ahora la rugosidad de la luz directa y la normal van
	// con la máscara de humedad SUAVIZADA (en S, sin pendiente en los extremos), de
	// lo seco al 0,46 del charco sin pasar por un mínimo. `rug` sigue siendo la
	// del reflejo, que no hacía anillo.
	float rug_seco = rug;
	float moja_s = smoothstep(0.0, 1.0, max(humedo, charco));
	rug = mix(rug, rug * 0.55, humedo * 0.8);
	rug = mix(rug, 0.2, charco);
	float rug_luz = mix(rug_seco, 0.46, moja_s);
	// Lo de dentro del charco se queda como estaba (0,1 de la pendiente).
	pend *= (1.0 - moja_s * 0.45) * (1.0 - charco * 0.82);

	// Gotas que caen del techo en los charcos: anillos que se abren y se apagan.
	if (charco > 0.01 && lluvia > 0.0) {
		vec2 celda = floor(p / 0.45);
		vec2 dentro = fract(p / 0.45);
		float semilla = azar(celda + 17.0);
		float periodo = 2.6 + 3.0 * semilla;
		float t = fract(TIME / periodo + semilla);
		vec2 origen = 0.3 + 0.4 * vec2(azar(celda + 2.0), azar(celda + 5.0));
		vec2 dv = (dentro - origen) * 0.45;
		float dist = length(dv);
		float radio = t * 0.16;
		float anillo = sin((dist - radio) * 120.0) * exp(-abs(dist - radio) * 60.0) * (1.0 - t);
		pend += normalize(dv + 1.0e-5) * anillo * 0.05 * charco * lluvia;
	}

	// ------------------------------------------------- las grietas, rellenas
	// LA JUNTA Y LA RAJA VAN LLENAS DE MUGRE, Y LA MUGRE ES MATE. El agua busca
	// la junta, así que el charco le dejaba a la junta, a la raja y a su labio
	// la rugosidad del agua (0,2) con la pendiente del bisel: una tira estrecha,
	// lisa y curvada que cogía el especular de la luna de lleno. Bajo el charco
	// de luna cada grieta salía como un rayo blanco-azulado, el brillo de más
	// contraste del campo después de la bola (revisión del remate). Ahora el
	// hueco y su labio van mates, sin pendiente y casi sin especular ni
	// reflejo; el agua se queda en la losa de al lado, que es donde brilla.
	// El labio es el bisel ENTERO: con solo el arranque (0,7 del bisel) el
	// canto de fuera, mojado y en pendiente, seguía dejando un hilo blanco a lo
	// largo de cada junta en la vista de juego.
	float labio_j = 1.0 - smoothstep(ancho_j, ancho_j + bisel * 1.1, dj);
	float labio_r = 1.0 - smoothstep(0.0012, 0.016, d_raja);
	float relleno = max(max(en_junta, en_raja), max(labio_j, labio_r) * 0.85) * (1.0 - laton);
	if (en_emblema && r_emb < emblema.z) {
		relleno = 0.0;
	}
	rug = mix(rug, 0.9, relleno);
	rug_luz = mix(rug_luz, 0.9, relleno);
	// La pendiente se queda en parte (el canto se sigue leyendo por la sombra);
	// lo que se va es el brillo.
	pend *= 1.0 - relleno * 0.6;

	// ------------------------------------------------------------- la luz
	// La oclusión horneada apaga también la luz directa: el ambiente es casi
	// cero en una cripta, y una oclusión que solo tocara el ambiente no se vería.
	float sombra = luz_horno * (1.0 - max(en_junta, en_raja) * (en_adoquin ? 0.3 : 0.55))
			* (1.0 - en_bisel * (en_adoquin ? 0.1 : 0.2)) * (1.0 - hoyo * 0.3);

	vec3 n_mundo = normalize(vec3(-pend.x, 1.0, -pend.y));
	vec3 n_vista = normalize((VIEW_MATRIX * vec4(n_mundo, 0.0)).xyz);

	ALBEDO = alb * mix(1.0, sombra, 0.75);
	// LA LUZ DIRECTA VE EL AGUA UN PUNTO MÁS ÁSPERA QUE EL ESPEJO. Con 0,2, el
	// brillo de una llama o de la luna en un charco era un óvalo blanco del
	// tamaño de la bola y más claro que ella (la bola falsa de la rasante, bajo
	// las lápidas: 254 de luminancia frente a 181 de la bola). La imagen de la
	// sala ya la pone el reflejo, con su techo: aquí basta un lustre ancho.
	// `rug` sigue mandando en cuánto se abre el reflejo (más abajo).
	// (Medido en la misma toma de la rasante: con 0,2 el óvalo daba 253 en el
	// p95; con 0,36, una columna de 221; con 0,46, 213 y sin forma de óvalo, y
	// lo que queda es la losa entera alumbrada, no un punto.)
	// (Era max(rug, 0,46·max(charco, húmedo·0,75)): ver «el borde de lo mojado».)
	ROUGHNESS = clamp(rug_luz, 0.03, 1.0);
	// No del todo metal: a la luz del fuego, un latón metálico puro solo se ve
	// donde le da un brillo, y embutido en el suelo casi nunca le da.
	METALLIC = laton * 0.75;
	// El agua devuelve un 2 % de frente (SPECULAR 0,25), la piedra un 3-4 %. Con
	// 0,36 el charco devolvía la llama más que la losa seca de al lado.
	// Con la misma máscara suavizada que la rugosidad: con «húmedo·0,6» la orilla
	// húmeda se quedaba en 0,32 y el charco de dentro en 0,25, y aun sin el hilo
	// blanco la orilla era una banda más clara que lo de dentro y lo de fuera.
	SPECULAR = mix(0.42, 0.25, moja_s) * mix(1.0, sombra, 0.85) * (1.0 - hueco) * (1.0 - relleno * 0.7);
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

	if (depura > 0) {
		vec3 dd = vec3(0.0);
		if (depura == 1) { dd = vec3(sombra); }
		else if (depura == 2) { dd = vec3(charco, humedo, 0.0); }
		else if (depura == 3) { dd = vec3(uso, hol, surco); }
		else if (depura == 4) { dd = ma; }
		else if (depura == 5) { dd = n_mundo * 0.5 + 0.5; }
		else if (depura == 7) { dd = vec3(charco, hol, relleno); }
		else if (depura == 8) { dd = luz * fuerza_reflejo; }
		else { dd = vec3(azar(id), azar(id + 1.0), en_junta); }
		ALBEDO = vec3(0.0);
		SPECULAR = 0.0;
		ROUGHNESS = 1.0;
		METALLIC = 0.0;
		EMISSION = dd;
	}
}
