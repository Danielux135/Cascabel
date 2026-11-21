// CRIPTA 3D — LA SUPERFICIE. El sombreador de todo lo opaco de la mesa: piedra,
// losa, hierro, óxido, bronce, latón, acero, madera, hueso, goma, cera y carbón
// son ESTE código con otros números (los pone `biblioteca.gd`).
//
// Que sea uno solo no es pereza: es lo que hace que la mesa parezca UNA mesa
// (todo envejece igual: se ensucia en los huecos, se roza en los cantos, se moja
// por arriba) y lo que deja a la web compilar un programa en vez de doce.
//
// CÓMO ESTÁ HECHO
//   - TRIPLANAR en coordenadas de mundo. Las mallas salen de código y de
//     Blender y no traen UV de fiar; proyectando desde los tres ejes no hay
//     costuras ni estirones, y dos piezas pegadas comparten dibujo. Lo que se
//     MUEVE (palas, torno, bola) pide «local» y lleva el dibujo pegado.
//     El plano lo elige la cara DE VERDAD (la derivada de la posición) cuando
//     la normal de la malla se le aparta mucho: ver «LA NORMAL QUE ELIGE».
//   - NUEVE LECTURAS de textura por píxel y ni un bucle de ruido: tres texturas
//     (`generar_texturas.gd`), cada una en sus tres planos. De ahí salen doce
//     ruidos y dos normales. Todo lo demás es aritmética.
//   - El relieve viene YA DERIVADO en la textura (dos canales de pendiente), así
//     que la normal no cuesta lecturas de más ni sale a cuadros.
//   - Color de vértice, solo si se pide («vertice»): R oclusión (1 al aire),
//     G canto (1 en el filo), B libre (aquí: cuánto brilla la luz propia).
//   - Sin color de vértice, el canto y el hueco se sacan de cuánto GIRA la
//     normal por unidad de mundo: un bisel redondo da positivo, un rincón
//     redondo negativo, una cara plana cero. No depende de la distancia de la
//     cámara, porque se divide por lo que avanza la posición.

uniform sampler2D tex_grano : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_celdas : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_manchas : filter_linear_mipmap, repeat_enable;

// --- el marco: dónde se apoya el dibujo -------------------------------------
uniform mat3 marco;                     // su eje X es la veta de la madera y el cepillado del metal
uniform vec3 desfase = vec3(0.0);       // la semilla: mueve el ruido de sitio
uniform float en_local = 0.0;           // 1 = pegado a la pieza, no al mundo
uniform float escala = 0.5;             // lo que mide una tesela de grano, en unidades de mundo
uniform float escala_celdas = 1.0;      // tesela de celdas / tesela de grano
uniform float escala_manchas = 3.3;     // tesela de manchas / tesela de grano
uniform float estirado = 1.0;           // grano y celdas, alargados por el eje X del marco
uniform float estirado_celdas = 1.0;     // las celdas (martillado, rajas), además, alargadas otro tanto
uniform vec3 estirado_manchas = vec3(1.0);

// --- el color ---------------------------------------------------------------
uniform vec3 color_a : source_color = vec3(0.10);       // lo oscuro de la variación
uniform vec3 color_b : source_color = vec3(0.20);       // el tono medio
uniform vec3 color_c : source_color = vec3(0.35);       // las vetas claras
uniform vec3 color_suciedad : source_color = vec3(0.02);
uniform vec3 color_canto : source_color = vec3(0.50);
uniform vec3 color_grieta : source_color = vec3(0.01);
uniform vec3 tinte : source_color = vec3(1.0);
uniform float variacion = 1.0;          // cuánto se abre la mezcla entre a y b
uniform float claros = 0.5;             // cuánto entra c
uniform float moteado = 0.3;            // cuánto pinta el relieve fino (hoyos oscuros)
uniform float mota_tono = 0.4;          // cuánto pinta la mota fina en el tono: alto = granito de encimera
uniform float picado = 1.0;             // cuánta mugre se mete en los hoyos del grano (los «puntitos»)
uniform float tono_bloque = 0.0;        // con juntas: cuánto cambia el tono de un sillar al de al lado
uniform float parches = 1.0;            // cuánta mugre cae fuera de los huecos, a manchas

// --- la superficie ----------------------------------------------------------
uniform float rugosidad = 0.8;
uniform float rugosidad_var = 0.08;
uniform float rugosidad_canto = 0.5;
uniform float rugosidad_suciedad = 0.95;
uniform float metal = 0.0;
uniform float metal_canto = 0.0;
uniform float metal_suciedad = 0.0;
uniform float especular = 0.5;
uniform float relieve = 0.5;            // el grano
uniform float relieve_celdas = 0.0;     // el martillado (negativo: ampollas)
uniform float relieve_testa = 1.0;      // el relieve en la cara que corta la veta (el eje X del marco)
uniform float grietas = 0.0;            // 0..1: cuánta superficie agrietada
uniform float grieta_ancho = 0.18;

// --- los mandos de envejecer ------------------------------------------------
uniform float suciedad = 0.5;
uniform float desgaste = 0.5;
uniform float roce_blando = 0.0;        // 0 = se pela a desconchones (metal); más = se gasta en degradado (piedra)
// Cuánto mete el ruido en el roce. Con 1, una cresta del grano se pela aunque
// esté en mitad de una cara: en la piedra es la arista mellada; en el hierro
// eran lunares de acero sobre negro, el «granito» de las palas (segunda
// crítica). Bajo, lo pulido se queda en el filo que dice la malla (canal G).
uniform float roce_ruido = 1.0;
// La piedra en un canto romo de pocas caras: el plano de proyección lo elige la
// normal SUAVE de la malla aunque se aparte de la faceta (hasta ~53°), y en las
// caras de canto los pesos se mezclan más anchos. Ver «LA NORMAL QUE ELIGE».
uniform float proy_suave = 0.0;
uniform float mojado = 0.0;
uniform float porosidad = 0.5;          // cuánto oscurece al mojarse
uniform float usa_vertice = 0.0;
uniform float curvatura = 1.0;          // canto y hueco sacados del giro de la normal

// --- los dibujos que no son ruido -------------------------------------------
uniform vec3 bloque = vec3(0.0);        // aparejo: largo, alto y fondo del sillar (0 = sin juntas)
uniform vec3 junta = vec3(0.012, 0.022, 1.0);   // ancho, bisel y hondura
uniform float pulido = 0.0;             // cuánto se alisa el centro de cada losa
uniform float anillos = 0.0;            // madera: anillos por unidad de mundo
uniform float veta = 0.0;               // madera: cuánto pintan

// --- luz propia y luz que atraviesa ------------------------------------------
uniform vec3 color_emision : source_color = vec3(0.0);
uniform float emision = 0.0;            // pareja: toda la pieza (o su canal B)
uniform float emision_grietas = 0.0;    // solo por las grietas: el carbón encendido
uniform vec3 translucido : source_color = vec3(0.0);

// --- lo que solo usa el suelo -------------------------------------------------
// El reflejo plano: la imagen de una cámara espejo (la de juego, del revés por
// debajo del suelo). Mismos nombres que en `prueba3d/suelo.gdshader`, para que
// quien venga de ÓRBITA lo enchufe sin mirar. Son cuatro lecturas más, y solo
// en el material que lo pida.
uniform sampler2D reflejo : source_color, filter_linear, repeat_disable, hint_default_black;
uniform float fuerza_reflejo = 0.0;
// La oclusión horneada: un mapa visto desde arriba. El rectángulo es x, z,
// ancho y fondo, en unidades de mundo; con ancho 0 no hay mapa.
uniform sampler2D mapa_oclusion : filter_linear, repeat_disable, hint_default_white;
uniform vec4 rect_oclusion = vec4(0.0);

uniform int depura = 0;                 // 1 canto · 2 suciedad · 3 oclusión · 4 mojado · 5 normal

varying vec3 v_pos;
varying vec3 v_nor;
varying flat vec3 v_arriba;
varying vec2 v_suelo;

// Los giros de la normal (en 1/unidad de mundo) entre los que nace el canto. Un
// bisel de 1 a 2 px de mesa da de 50 a 100; la bola da 22 y se queda sin él.
const float GIRO_MIN = 26.0;
const float GIRO_MAX = 80.0;

float azar(vec2 p) {
	// Sin senos: el seno pierde precisión en las tarjetas de móvil y el azar
	// sale a rayas.
	vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

// Un aparejo de sillares sobre un plano: hiladas a soga, cada una trabada con la
// de abajo a medio sillar más un poco de azar. Devuelve la distancia al borde
// del sillar; «hacia» apunta a ese borde y «cual» es el azar del sillar.
float aparejo(vec2 q, vec2 tam, out vec2 hacia, out float cual) {
	float hilada = floor(q.y / tam.y);
	q.x += tam.x * (0.5 * mod(hilada, 2.0) + (azar(vec2(hilada, 7.3)) - 0.5) * 0.34);
	vec2 celda = floor(q / tam);
	vec2 f = (fract(q / tam) - 0.5) * tam;
	vec2 d = 0.5 * tam - abs(f);
	cual = azar(celda + vec2(3.7, 11.1));
	if (d.x < d.y) {
		hacia = vec2(sign(f.x), 0.0);
		return d.x;
	}
	hacia = vec2(0.0, sign(f.y));
	return d.y;
}

void vertex() {
	vec3 p;
	vec3 n;
	vec3 arriba;
	if (en_local > 0.5) {
		// Pegado a la pieza. El tamaño sale de la escala del nodo, para que una
		// pieza escalada no lleve el grano escalado con ella.
		vec3 esc = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
		p = VERTEX * esc;
		n = normalize(NORMAL / esc);
		arriba = vec3(MODEL_MATRIX[0].y, MODEL_MATRIX[1].y, MODEL_MATRIX[2].y) / esc;
	} else {
		p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		n = normalize(MODEL_NORMAL_MATRIX * NORMAL);
		arriba = vec3(0.0, 1.0, 0.0);
	}
	v_pos = marco * (p + desfase);
	v_nor = marco * n;
	v_arriba = marco * arriba;
	v_suelo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec3 p = v_pos;
	vec3 n0 = normalize(v_nor);
	vec3 n_malla = NORMAL;                          // la de la malla, antes de tocarla
	float sube = dot(n0, normalize(v_arriba));      // 1 mira al cielo, −1 al suelo

	// LA NORMAL QUE ELIGE EL PLANO no es la del sombreado. Muchas mallas llevan
	// la normal «de almohada» —una banda de goma de cara recta con la normal
	// girada hacia arriba en su mitad alta para que coja brillo—, y con ella el
	// triplanar proyectaba DESDE ARRIBA sobre una cara de pie: cada columna de
	// textura corría vertical y salían chorreones (la goma de las hondas, en la
	// primera crítica). La cara de verdad sale de cómo avanza la posición; si la
	// de la malla se le aparta más de unos 20°, manda la de verdad. Por debajo
	// de eso manda la de la malla, que es suave: en una esfera, la de verdad
	// sería a facetas y el dibujo saltaría de triángulo en triángulo.
	vec3 ng = cross(dFdx(v_pos), dFdy(v_pos));
	float largo_ng = length(ng);
	ng = largo_ng > 1.0e-14 ? ng / largo_ng : n0;
	ng *= dot(ng, n0) < 0.0 ? -1.0 : 1.0;
	//
	// PERO EN UN CANTO ROMO DE POCAS CARAS (la albardilla: el arco de 90° en dos
	// facetas) la de verdad salta de faceta en faceta, se aparta de la suave más
	// de esos 20° en cuanto la faceta mide 45°, y el plano cambia a saltos a lo
	// largo de triángulos de un metro de largo y un píxel de alto: el grano salía
	// peinado a rayas en el canto del pie de la mesa (segunda crítica, técnica).
	// La piedra no tiene normales de almohada, así que con «proy_suave» manda la
	// suave mientras no se aparte más de unos 53° (coseno 0,6).
	float elige_lo = mix(0.80, 0.55, proy_suave);
	float elige_hi = mix(0.94, 0.65, proy_suave);
	vec3 n_proy = normalize(mix(ng, n0, smoothstep(elige_lo, elige_hi, dot(ng, n0))));

	// Los pesos de los tres planos. A la octava: la franja donde se mezclan dos
	// planos queda estrecha y no se ve el dibujo doble. En las caras de canto de
	// la piedra (ni de pie ni tumbadas), a la cuarta: la franja ancha no deja ver
	// dónde se pasa de un plano al otro, que en un canto romo es una raya.
	vec3 w = abs(n_proy);
	w *= w;
	w *= w;
	vec3 w4 = w / (w.x + w.y + w.z);
	w *= w;
	w /= (w.x + w.y + w.z);
	float inclinada = abs(dot(n_proy, normalize(v_arriba)));
	float de_canto = proy_suave * smoothstep(0.25, 0.35, inclinada) * (1.0 - smoothstep(0.85, 0.95, inclinada));
	w = mix(w, w4, de_canto);
	// Mezclar dos ruidos los aplana (la variación cae con la raíz de los pesos al
	// cuadrado): sin devolvérsela, una esfera lleva una cruz lisa a 45 grados.
	float kw = inversesqrt(dot(w, w));

	// ------------------------------------------------------ las nueve lecturas
	vec3 pd = p / escala;
	pd.x /= estirado;
	vec4 dx = texture(tex_grano, pd.zy + vec2(0.31, 0.67));
	vec4 dy = texture(tex_grano, pd.xz);
	vec4 dz = texture(tex_grano, pd.xy + vec2(0.59, 0.13));
	// La madera quiere la fibra corta (si no, la veta es un cepillo de rayas) y
	// las rajas largas (si no, las celdas son un craquelado de barro seco).
	float estira_celdas = estirado * estirado_celdas;
	vec3 pm = p / (escala * escala_celdas);
	pm.x /= estira_celdas;
	vec4 mx = texture(tex_celdas, pm.zy + vec2(0.17, 0.83));
	vec4 my = texture(tex_celdas, pm.xz);
	vec4 mz = texture(tex_celdas, pm.xy + vec2(0.71, 0.37));
	vec3 pg = p / (escala * escala_manchas * estirado_manchas);
	vec4 manchas = texture(tex_manchas, pg.zy + vec2(0.43, 0.29)) * w.x
			+ texture(tex_manchas, pg.xz) * w.y
			+ texture(tex_manchas, pg.xy + vec2(0.77, 0.51)) * w.z;
	manchas = clamp(0.5 + (manchas - 0.5) * kw, 0.0, 1.0);
	float grande = manchas.r;
	float mugre = manchas.g;
	float vena = manchas.b;
	float hondo = manchas.a;

	vec4 grano = dx * w.x + dy * w.y + dz * w.z;
	float h = clamp(0.5 + (grano.r - 0.5) * kw, 0.0, 1.0);
	float mota = clamp(0.5 + (grano.a - 0.5) * kw, 0.0, 1.0);
	// La pendiente de cada plano, puesta en los ejes del marco.
	vec3 gd = w.x * relieve_testa * vec3(0.0, dx.b - 0.5, dx.g - 0.5)
			+ w.y * vec3(dy.g - 0.5, 0.0, dy.b - 0.5)
			+ w.z * vec3(dz.g - 0.5, dz.b - 0.5, 0.0);
	vec4 celdas = mx * w.x + my * w.y + mz * w.z;
	vec3 gm = w.x * vec3(0.0, mx.b - 0.5, mx.g - 0.5)
			+ w.y * vec3(my.g - 0.5, 0.0, my.b - 0.5)
			+ w.z * vec3(mz.g - 0.5, mz.b - 0.5, 0.0);
	gd *= 2.0 * kw;
	gm *= 2.0 * kw;
	// Lo estirado sube más despacio a lo largo: la pendiente en ese eje se encoge.
	gd.x /= estirado;
	gm.x /= estira_celdas;
	float a_grieta = celdas.a;                       // raíz de la distancia al borde de celda

	// ------------------------------------------------- hueco y canto de la malla
	float oclu = 1.0;
	float canto = 0.0;
	float libre = 1.0;
	if (usa_vertice > 0.5) {
		oclu = COLOR.r;
		canto = COLOR.g;
		libre = COLOR.b;
	}
	if (rect_oclusion.z > 0.0) {
		oclu *= texture(mapa_oclusion, (v_suelo - rect_oclusion.xy) / rect_oclusion.zw).r;
	}
	if (curvatura > 0.0) {
		vec3 ax = dFdx(VERTEX);
		vec3 ay = dFdy(VERTEX);
		float giro = dot(dFdx(NORMAL), ax) / max(dot(ax, ax), 1.0e-10)
				+ dot(dFdy(NORMAL), ay) / max(dot(ay, ay), 1.0e-10);
		// Con color de vértice, el canto lo dice la malla y el giro no lo pisa. Un
		// tubo delgado (los raíles miden de 5 a 8 mm de radio) gira MÁS que un
		// bisel: por el giro, el tubo ENTERO era canto, el desgaste lo partía a
		// manchas con el ruido y el latón salía con lunares de leopardo. Quien
		// pinta el vértice ya ha dicho dónde está el filo.
		if (usa_vertice < 0.5) {
			canto = max(canto, smoothstep(GIRO_MIN, GIRO_MAX, giro) * curvatura);
		}
		oclu = min(oclu, 1.0 - smoothstep(GIRO_MIN, GIRO_MAX, -giro) * curvatura * 0.8);
	}

	// ------------------------------------------------------------- las juntas
	float en_junta = 0.0;       // 1 en el fondo de la junta
	float centro = 0.0;         // 1 en mitad de la losa
	float de_losa = 0.5;        // el azar de cada losa
	vec3 g_junta = vec3(0.0);
	if (bloque.x > 0.0) {
		// El aparejo no se mezcla entre planos (dos juntas a medias son dos juntas
		// fantasma): manda el plano que más mira a la cara.
		vec3 an = abs(n_proy);
		vec2 q;
		vec2 tam;
		vec3 eu;
		vec3 ev;
		if (an.y >= an.x && an.y >= an.z) {
			q = p.xz;
			tam = bloque.xz;
			eu = vec3(1.0, 0.0, 0.0);
			ev = vec3(0.0, 0.0, 1.0);
		} else if (an.x >= an.z) {
			q = p.zy;
			tam = bloque.xy;
			eu = vec3(0.0, 0.0, 1.0);
			ev = vec3(0.0, 1.0, 0.0);
		} else {
			q = p.xy;
			tam = bloque.xy;
			eu = vec3(1.0, 0.0, 0.0);
			ev = vec3(0.0, 1.0, 0.0);
		}
		if (tam.x > 0.0 && tam.y > 0.0) {
			vec2 hacia;
			float d = aparejo(q, tam, hacia, de_losa);
			// El canto del sillar, mellado por el relieve: una junta a regla es un
			// dibujo, no una piedra.
			d += (h - 0.55) * junta.y * 0.9 + (mota - 0.5) * junta.y * 0.5;
			float s = clamp((d - junta.x * 0.5) / junta.y, 0.0, 1.0);
			en_junta = 1.0 - s * s * (3.0 - 2.0 * s);
			// La caída del bisel hacia la junta (la derivada del escalón suave), y
			// cada losa un pelo inclinada: es lo que parte el reflejo losa a losa.
			vec3 fuera = hacia.x * eu + hacia.y * ev;
			g_junta = -fuera * (3.0 * s * (1.0 - s) * junta.z);
			g_junta += ((azar(vec2(de_losa, 1.7)) - 0.5) * eu + (azar(vec2(de_losa, 5.1)) - 0.5) * ev)
					* 0.07 * junta.z * (1.0 - en_junta);
			centro = smoothstep(0.0, 0.32 * min(tam.x, tam.y), d);
		}
	}

	// --------------------------------------------------------------- la madera
	float tarde = 0.0;          // 1 en la madera tardía: la línea oscura del anillo
	if (anillos > 0.0) {
		// Anillos de verdad: cilindros alrededor del eje X del marco, con el
		// corazón del tronco fuera de la pieza. Cortados por una cara salen
		// vetas largas; por la testa, arcos.
		float r = length(p.yz - vec2(0.13, -9.0 / anillos)) * anillos;
		r += (grande - 0.5) * 1.8 + (mugre - 0.5) * 0.7 + (h - 0.5) * 0.3;
		float t = fract(r);
		tarde = smoothstep(0.30, 0.90, t) * (1.0 - smoothstep(0.92, 1.0, t));
		// De lejos los anillos caben varios en un píxel: se funden en su media en
		// vez de bailar.
		tarde = mix(tarde, 0.3, clamp(fwidth(r) * 1.6, 0.0, 1.0));
	}

	// ---------------------------------------------------------------- el color
	// El tono medio es «b». Lo grande lo lleva hacia «a» por abajo y hacia «c» por
	// arriba, y nunca del todo: una mezcla que llega a los extremos es camuflaje,
	// no piedra. Tres escalas a la vez (mancha grande, mugre, mota) para que no
	// haya un tamaño de mancha que se repita.
	float tono = (grande - 0.5) + (mugre - 0.5) * 0.5 + (mota - 0.5) * mota_tono;
	// Cada sillar, su piedra: uno sale de la cantera un poco más claro y el de al
	// lado más oscuro. Sin esto el aparejo es un panel con rayas, no cantería.
	tono += (de_losa - 0.5) * tono_bloque * (1.0 - en_junta);
	vec3 alb = mix(color_b, color_a, clamp(-tono * 1.6 * variacion, 0.0, 1.0));
	alb = mix(alb, color_c, clamp(tono * 1.3 * claros, 0.0, 1.0));
	alb = mix(alb, color_a * 0.6, tarde * veta);
	alb *= 1.0 + (h - 0.66) * moteado;

	// La suciedad: en los huecos de la malla, en los hoyos del grano, en el fondo
	// de las juntas, y a parches. Todo roto por el ruido: una mugre con el borde
	// a regla es una pegatina. «suciedad» es cuánta; los parches la leen como
	// cobertura porque el canal está ecualizado.
	float hueco = 1.0 - oclu;
	float hoyo = smoothstep(0.40, 0.10, h);
	float en_hueco = smoothstep(0.25, 1.0, hueco + (mugre - 0.5) * 0.5 + (mota - 0.5) * 0.25);
	float parche = smoothstep(1.0 - suciedad * 0.6, 1.4 - suciedad * 0.6, mugre + (mota - 0.5) * 0.3);
	float posa = mix(0.75, 1.15, smoothstep(-0.2, 0.9, sube));      // el polvo cae: arriba hay más
	float fondo_junta = en_junta * en_junta;
	float m_suc = clamp((en_hueco * 0.9 + hoyo * 0.22 * picado + fondo_junta * 1.3) * min(suciedad * 2.0, 1.0)
			+ parche * suciedad * posa * 0.8 * parches, 0.0, 1.0);

	// El roce: en el canto, pero roto por el relieve (se pela lo que sobresale, y
	// lo que no, sigue sucio). Con mucho desgaste salta también a las crestas de
	// las caras.
	float roce = canto * (0.25 + 0.75 * desgaste) + ((h - 0.5) * 0.6 + (mota - 0.5) * 0.4) * roce_ruido;
	float m_canto = smoothstep(0.50 - roce_blando, 0.75 + roce_blando, roce) * step(0.001, desgaste) * (1.0 - fondo_junta);

	// Las grietas: el borde de las celdas, pero solo donde manda la vena. Una red
	// entera de grietas es un empedrado; a trozos, es algo que se ha roto.
	float m_grieta = 0.0;
	if (grietas > 0.0) {
		float linea = 1.0 - smoothstep(0.0, grieta_ancho, a_grieta + (h - 0.5) * 0.03);
		float donde = smoothstep(1.0 - grietas, 1.25 - grietas, vena * 0.55 + grande * 0.45);
		m_grieta = linea * donde;
	}

	alb = mix(alb, color_suciedad, m_suc * 0.92);
	alb = mix(alb, color_canto, m_canto);
	alb = mix(alb, color_grieta, m_grieta);

	float rug = rugosidad + ((mota - 0.5) * 2.0 + (mugre - 0.5)) * rugosidad_var;
	rug -= centro * pulido;
	rug = mix(rug, rugosidad_suciedad, m_suc);
	rug = mix(rug, rugosidad_canto, m_canto);
	rug = mix(rug, 0.95, m_grieta);
	float met = mix(mix(metal, metal_suciedad, m_suc), metal_canto, m_canto) * (1.0 - m_grieta);
	float esp = especular;

	vec3 pend = gd * relieve + gm * relieve_celdas;
	// En el canto romo de la piedra el relieve, además, a dos tercios: la luz le
	// llega rasante y el grano, aunque ya no salte de plano, se peinaba con ella.
	pend *= 1.0 - 0.35 * de_canto;
	pend *= 1.0 - m_canto * 0.55;                    // lo rozado queda más liso
	pend += g_junta;

	// --------------------------------------------------------------- lo mojado
	float m_agua = 0.0;
	float m_humedo = 0.0;
	if (mojado > 0.0) {
		float boca_arriba = smoothstep(0.35, 0.9, sube);
		float al_aire = smoothstep(-0.6, -0.1, sube);       // por debajo no llueve
		// El agua busca lo bajo: las hondonadas grandes, los hoyos, las juntas y
		// las losas hundidas. «mojado» es el nivel al que sube.
		float bajo = hondo * 0.72 + (1.0 - h) * 0.18 + en_junta * 0.5 + (0.5 - de_losa) * 0.22;
		float nivel = 1.08 - mojado * 0.9;
		m_agua = smoothstep(nivel, nivel + 0.045, bajo) * boca_arriba;
		float cerco = smoothstep(nivel - 0.26, nivel, bajo);
		// En las paredes no hay charco: hay regueros (las manchas van estiradas
		// hacia abajo).
		float reguero = smoothstep(0.30, 0.72, vena * 0.6 + hondo * 0.4);
		m_humedo = clamp(mojado * 1.7, 0.0, 1.0) * al_aire
				* mix(0.08 + 0.62 * reguero, 0.42 + 0.58 * cerco, boca_arriba);
		m_humedo = max(m_humedo, m_agua);
		// Mojada, la piedra oscurece y se satura: el agua llena los poros y la
		// luz deja de rebotar dentro.
		float gris = dot(alb, vec3(0.30, 0.59, 0.11));
		alb = mix(vec3(gris), alb, 1.0 + 0.35 * m_humedo * porosidad) * (1.0 - 0.58 * m_humedo * porosidad);
		rug = mix(rug, rug * 0.40 + 0.03, m_humedo);
		rug = mix(rug, 0.035, m_agua);
		esp = mix(esp, 0.36, m_agua);
		// La película de agua tapa el grano fino; el charco, además, es plano.
		pend *= (1.0 - m_humedo * 0.5) * (1.0 - m_agua * 0.96);
	}

	// -------------------------------------------------------------- la normal
	pend -= n0 * dot(n0, pend);
	vec3 n = normalize(n0 - pend) * marco;           // de vuelta del marco (marco es un giro)
	if (en_local > 0.5) {
		// De la pieza al mundo solo con su GIRO: la escala ya se quitó en el vértice.
		vec3 esc = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
		n = mat3(MODEL_MATRIX) * (n / esc);
	}
	vec3 n_vista = normalize(mat3(VIEW_MATRIX) * n);

	// El relieve que no cabe en el píxel se pasa a rugosidad: sin esto, el metal
	// martillado chispea en cuanto se aleja la cámara.
	vec3 nx = dFdx(n_vista);
	vec3 ny = dFdy(n_vista);
	float baile = min(0.5 * (dot(nx, nx) + dot(ny, ny)), 0.18);
	rug = clamp(rug, 0.03, 1.0);
	float alfa2 = rug * rug;
	alfa2 *= alfa2;
	rug = sqrt(sqrt(min(alfa2 + baile, 1.0)));

	// La oclusión de la malla y la de los hoyos oscurecen también la luz
	// directa: en una cripta el ambiente es casi cero, y una oclusión que solo
	// tocara el ambiente no se vería.
	float sombra = oclu * (1.0 - hoyo * 0.35 * moteado) * (1.0 - m_grieta * 0.6) * (1.0 - fondo_junta * 0.6);

	ALBEDO = alb * tinte * mix(1.0, sombra, 0.62);
	ROUGHNESS = rug;
	METALLIC = clamp(met, 0.0, 1.0);
	SPECULAR = esp * mix(1.0, sombra, 0.8);
	NORMAL = n_vista;
	AO = sombra;
	BACKLIGHT = translucido;

	vec3 luz = color_emision * emision * libre;
	if (emision_grietas > 0.0) {
		// El carbón encendido: arde por las grietas y respira.
		float brasa = (1.0 - smoothstep(0.0, 0.42, a_grieta)) * smoothstep(0.25, 0.75, mugre + (vena - 0.5) * 0.5);
		float aire = 0.72 + 0.28 * sin(TIME * 1.9 + grande * 17.0 + p.x * 5.0 + p.z * 3.0);
		luz += color_emision * emision_grietas * brasa * brasa * aire * libre;
	}
	if (fuerza_reflejo > 0.0) {
		// El espejo es el plano del suelo: solo vale donde la cara mira arriba. El
		// relieve tuerce la imagen, y la rugosidad la abre: lo seco la emborrona
		// hasta que no se ve, el charco es un espejo.
		float plano = smoothstep(0.7, 0.95, sube);
		vec2 suv = vec2(SCREEN_UV.x, 1.0 - SCREEN_UV.y) + (n_vista.xy - n_malla.xy) * 0.07;
		vec2 abre = vec2(0.0015, 0.0025) * (1.0 + rug * 14.0);
		vec3 imagen = (textureLod(reflejo, suv + vec2(abre.x, 0.0), 0.0).rgb
				+ textureLod(reflejo, suv - vec2(abre.x, 0.0), 0.0).rgb
				+ textureLod(reflejo, suv + vec2(0.0, abre.y), 0.0).rgb
				+ textureLod(reflejo, suv - vec2(0.0, abre.y), 0.0).rgb) * 0.25;
		// No es el Fresnel de verdad: desde la cámara de juego, casi a plomo, el
		// agua real apenas refleja y el reflejo es media escena. Se le deja un
		// suelo y sube hacia lo rasante.
		float rasante = pow(1.0 - clamp(dot(n_vista, VIEW), 0.0, 1.0), 3.0);
		float liso = 1.0 - rug;
		luz += imagen * mix(vec3(1.0), alb, clamp(met, 0.0, 1.0))
				* (fuerza_reflejo * mix(0.3, 1.0, rasante) * liso * liso * plano * mix(1.0, sombra, 0.5));
	}
	EMISSION = luz;

	if (depura > 0) {
		vec3 d = vec3(0.0);
		if (depura == 1) {
			d = vec3(m_canto, canto, 0.0);
		} else if (depura == 2) {
			d = vec3(m_suc);
		} else if (depura == 3) {
			d = vec3(sombra);
		} else if (depura == 4) {
			d = vec3(m_agua, m_humedo, 0.0);
		} else {
			d = n * 0.5 + 0.5;
		}
		ALBEDO = vec3(0.0);
		SPECULAR = 0.0;
		ROUGHNESS = 1.0;
		METALLIC = 0.0;
		EMISSION = d;
	}
}
