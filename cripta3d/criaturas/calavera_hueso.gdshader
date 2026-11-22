shader_type spatial;
// LUZ POR VÉRTICE (nov-2026, para la web). Con la luz entera (burley + GGX) y el
// ruido por código, este sombreador tardaba 31,7 s en compilar con ANGLE: el
// 89 % de la familia y el más caro de la mesa (banco, en frío). Con ANGLE el GLSL
// lo compila Direct3D, que despliega cada bucle y cada ruido en cada una de las
// cuatro o cinco variantes que Godot compila de un sombreador. El hueso es MATE:
// su especular era el 1 % de la difusa, y la malla del cráneo tiene 1.898
// vértices, así que la luz por vértice (0,86 s de base) aguanta. Lo que la luz
// por vértice no puede hacer —la ranura de la sutura tallada en la normal y el
// reflejo duro de la frente blindada— se hace aquí a mano con las tres luces que
// más le dan, que pone `calavera.gd` (ver «LAS TRES LUCES»). Así: 1,3 s.
//
// LO QUE SE PIERDE, Y POR QUÉ NO SE ARREGLA. Con una luz CON SOMBRA (el fuego del
// visor; en la mesa, las de la calidad alta), la sombra propia del cráneo sale
// blanda y algo más ancha que por píxel: en el retrato picado del visor, una
// franja de la bóveda junto al terminador del fuego queda más fría (138, 158, 195
// contra 187, 187, 204). En la web no hay luces con sombra, y ahí no pasa.
// PROBADO Y DESCARTADO: el mismo dibujo con luz por píxel y `specular_disabled`
// (y la ranura tallada en la normal, como antes) la devolvía casi exacta (175,
// 174, 194), pero costaba 5,2–5,8 s; y sin relieve, sin reflejo de la coraza y
// sin BACKLIGHT, aún 4,4: con luz por píxel el código propio pesa tres veces
// más (1,5 s contra 0,45), y el objetivo era 4,0.
render_mode cull_back, vertex_lighting;

// CRIPTA — el hueso de la calavera.
//
// El sprite es «hueso y sombra»: TIERRA_5 y TIERRA_6 con las sombras en
// TIERRA_3, y las cuencas, la nariz y la boca en negro. Aquí cada uno de esos
// tonos tiene un MOTIVO, que es lo que separa un hueso de una bola de yeso:
//
//   · lo que sobresale (el canto, G) está gastado y pálido, y algo pulido;
//   · lo que queda en hueco (la oclusión, R) guarda la mugre, y cuanto más
//     hondo, más negro: la cuenca no es negra porque se pinte, sino porque no
//     le llega nada;
//   · por encima, manchas grandes de hueso viejo, un moteado y el poro;
//   · grietas finas, a parches; y en el cráneo, las SUTURAS —la costura
//     serpenteante de la bóveda, una RANURA con un labio que coge la luz y otro
//     que no—, que es lo que hace que desde arriba se lea «calavera» y no «bola»;
//   · y los dientes (B) son esmalte: más claros y más lisos, con sarro en la raíz.
//
// LA LUZ LA PONE LA CRIPTA, NO EL COLOR. El fuego es fuerte y anaranjado: con el
// hueso pintado en sus tonos claros la pieza se quema, pierde el dibujo y le
// sale un halo —o sea, plástico con neón—. Por eso la base es el tono MEDIO del
// sprite y el claro se guarda para los cantos: el claro de verdad lo da la luz.
//
// El dibujo va en coordenadas LOCALES de cada pieza: va pegado al hueso, no al
// mundo, y no resbala cuando la pieza se mueve.
//
// NI RUIDO NI BUCLES POR CÓDIGO. Todo el dibujo se LEE:
//   · de las texturas de ruido de la casa (`cripta3d/texturas/`), por tres
//     planos de la coordenada local: el moteado y el poro de `ruido_grano`, las
//     manchas, las manchas viejas y los parches de grieta de `ruido_manchas`;
//   · y de `calavera_marcas.png` (la genera `generar_marcas.py`, aquí al lado):
//     las suturas ya medidas desde arriba, las grietas y las motas del poro.
// Los canales de la casa están ECUALIZADOS (un umbral es una cobertura), y los
// ruidos de antes no: cada umbral de antes va aquí pasado a su percentil, medido
// sobre el ruido de antes (0,42 en el `fbm` de las manchas es el percentil 0,29),
// para que cada cosa cubra lo mismo que cubría.
//
// Convención de color de vértice (cripta3d/LEEME.md): R oclusión (1 = al aire),
// G canto (1 = filo), B libre (aquí, diente).

uniform vec3 hueso_luz : source_color = vec3(0.96, 0.91, 0.81);
uniform vec3 hueso : source_color = vec3(0.85, 0.75, 0.58);
uniform vec3 hueso_medio : source_color = vec3(0.66, 0.54, 0.41);
uniform vec3 hueso_sombra : source_color = vec3(0.46, 0.37, 0.32);
uniform vec3 mugre : source_color = vec3(0.29, 0.23, 0.26);
uniform vec3 hondo : source_color = vec3(0.08, 0.07, 0.10);
/// El amarillo viejo de los dientes y del borde de las suturas.
uniform vec3 amarillo : source_color = vec3(0.78, 0.74, 0.60);
/// El gris frío al que se va el hueso en lo hondo (cuencas, nariz, boca).
uniform vec3 gris_hondo : source_color = vec3(0.40, 0.40, 0.40);
/// La frente blindada: hueso sobado, oscuro.
uniform vec3 pulido : source_color = vec3(0.27, 0.26, 0.25);
/// 0 a 1: cuánto está blindada la frente (oscura, pulida, con reflejo duro).
uniform float blindaje = 0.0;
/// 1 en el cráneo: dibuja las suturas de la bóveda.
uniform float suturas = 0.0;
/// Cuánto se ensucia hacia abajo (en Y local): la bóveda y la mandíbula rozan la losa.
uniform float roce = 0.0;
/// Cuántas grietas: la bóveda, que es la que se lleva los golpes, las que más.
uniform float grietas = 1.0;
/// Las piezas pequeñas llevan el dibujo más menudo.
uniform float escala_detalle = 1.0;
/// Desplaza el dibujo: cada pieza, el suyo.
uniform vec3 semilla = vec3(0.0);
/// El fogonazo del golpe: el hueso palidece un instante.
uniform float golpe = 0.0;
/// El golpe parado con la frente: solo se enciende por delante.
uniform float frente = 0.0;
/// Por debajo de esta altura (en el mundo) no se dibuja: así sale del suelo.
uniform float corte = -1000.0;
/// Fuerza del relieve: aquí, de la ranura de la sutura (las esquirlas lo ponen a 0).
uniform float relieve = 1.0;
/// Cuánta luz devuelve: por debajo de 1 para que el fuego no la queme.
uniform float claridad = 0.88;
/// Cuánto color se le quita al hueso para compensar el fuego (0 = el de la paleta).
/// Poco: la base ya es marfil frío (con el tono de la paleta salía melocotón).
uniform float desatura = 0.14;

/// Las texturas: las tres de ruido de la casa y las marcas propias. Las pone
/// `calavera.gd`.
uniform sampler2D tex_grano : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_manchas : filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_marcas : filter_linear_mipmap_anisotropic, repeat_enable;

/// LAS TRES LUCES que más le dan a la calavera en este cuadro (las elige
/// `calavera.gd` entre todas las de la escena). `sitio`: xyz, la posición (w = 1)
/// o la dirección hacia la luz (w = 0, la luna direccional del visor).
/// `color`: lo que llega al centro de la calavera, en lineal y con la energía
/// (lo mismo que suma Godot): la DIFUSA de esa luz. `luz_especular`, la parte
/// especular de cada una (`light_specular`), solo para el reflejo de la coraza.
/// (Iban juntas, y las luces se elegían por su especular: la brasa y el relleno,
/// con 0,3, quedaban fuera aunque fueran las que más alumbran; ver `calavera.gd`.)
/// Tres y no dos: en el visor la luna le da por detrás y no hace reflejo en la
/// frente; con dos, el segundo reflejo de la coraza (el de la luz de relleno)
/// se perdía.
uniform vec4 luz_a_sitio = vec4(0.0, 1.0, 0.0, 0.0);
uniform vec3 luz_a_color = vec3(0.0);
uniform vec4 luz_b_sitio = vec4(0.0, 1.0, 0.0, 0.0);
uniform vec3 luz_b_color = vec3(0.0);
uniform vec4 luz_c_sitio = vec4(0.0, 1.0, 0.0, 0.0);
uniform vec3 luz_c_color = vec3(0.0);
uniform vec3 luz_especular = vec3(0.5);

// --- Las marcas (`generar_marcas.py`): no cambiar sin regenerar la textura ----
// El recuadro del cráneo, visto desde arriba, que cubren R y G.
const vec2 SUTURA_DESDE = vec2(-0.125, -0.1855);
const vec2 SUTURA_MIDE = vec2(0.25, 0.25);
// La distancia a la sutura va guardada hasta 0,0065 (donde acaba el cerco).
const float SUTURA_RANGO = 0.0065;
// Lo que mide la tesela de grietas y poro: 4 celdas de 1/8,5, las de antes (y
// lleva 5).
const float TESELA_GRIETA = 0.47059;
// Hasta dónde va guardada la distancia a la grieta (F2 − F1 en celdas de 1/8,5).
const float RANGO_GRIETA = 0.10;
const float TEXEL = 1.0 / 1024.0;

varying vec3 local;
varying vec3 mundo;
varying vec3 normal_local;
// El N·L de cada una de las tres luces EN LOS VÉRTICES, interpolado igual que
// interpola Godot su luz por vértice: es lo que de verdad le ha llegado a cada
// píxel, y lo que «La luz por píxel» corrige.
varying vec3 lambert_vertice;

void vertex() {
	local = VERTEX;
	normal_local = NORMAL;
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 n = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	lambert_vertice = vec3(
		max(dot(n, normalize(mix(luz_a_sitio.xyz, luz_a_sitio.xyz - mundo, luz_a_sitio.w))), 0.0),
		max(dot(n, normalize(mix(luz_b_sitio.xyz, luz_b_sitio.xyz - mundo, luz_b_sitio.w))), 0.0),
		max(dot(n, normalize(mix(luz_c_sitio.xyz, luz_c_sitio.xyz - mundo, luz_c_sitio.w))), 0.0));
}

// Lo que se ve de las suturas en un punto del cráneo (x, z) a la altura y. R es
// la sagital y G la coronal o la lambdoidea; lo que depende de la altura —que no
// cabe en una proyección desde arriba— se suma aquí, igual que antes: las tres se
// borran por debajo de la bóveda, cada una a su altura. La coronal va por delante
// de z = −0,026 y la lambdoidea por detrás.
// Sin mipmap (`textureLod` 0): el mipmap promedia la uve de la distancia junto a
// la línea, la ranura sale roma y el labio no coge luz. La de antes se calculaba
// exacta en cada píxel, sin filtrar: así sigue.
float distancia_sutura(vec2 uv, float y, float z) {
	vec2 rg = textureLod(tex_marcas, uv, 0.0).rg * SUTURA_RANGO;
	float abajo_sag = 1.0 - smoothstep(0.0, 0.020, y);
	float abajo_otra = mix(1.0 - smoothstep(-0.050, -0.020, y), 1.0 - smoothstep(-0.030, -0.005, y),
		step(-0.026, z));
	return min(rg.r + abajo_sag, rg.g + abajo_otra);
}

// Hacia dónde queda una de las tres luces desde un punto.
vec3 hacia_luz(vec4 sitio, vec3 punto) {
	return normalize(mix(sitio.xyz, sitio.xyz - punto, sitio.w));
}

// La difusa de Burley de Godot (`scene.glsl`, `DIFFUSE_BURLEY`) por N·L, sin
// el 1/π: lo que daba una luz antes de la luz por vértice.
float burley(vec3 n, vec3 v, vec3 l, float rug) {
	float ndl = max(dot(n, l), 0.0);
	float ldh = max(dot(l, normalize(v + l)), 0.0);
	float f90 = 2.0 * ldh * ldh * rug - 0.5;
	float mv = 1.0 - max(dot(n, v), 1e-4);
	float ml = 1.0 - ndl;
	float sv = mv * mv;
	float sl = ml * ml;
	return (1.0 + f90 * sv * sv * mv) * (1.0 + f90 * sl * sl * ml) * ndl;
}

// El brillo duro de la coraza: el mismo GGX que pone Godot con la luz entera
// (D_GGX y V_GGX de `scene.glsl`, con Schlick), para UNA luz.
vec3 brillo(vec3 n, vec3 v, vec3 l, vec3 radiancia, float rug, vec3 f0) {
	vec3 h = normalize(v + l);
	float ndl = max(dot(n, l), 0.0);
	float ndv = max(dot(n, v), 1e-4);
	float ndh = max(dot(n, h), 0.0);
	float a = rug * rug;
	float k = a / (1.0 - ndh * ndh + ndh * ndh * a * a);
	float d = k * k * (1.0 / PI);
	float vis = 0.5 / mix(2.0 * ndl * ndv, ndl + ndv, a);
	float m = 1.0 - max(dot(l, h), 0.0);
	float m2 = m * m;
	vec3 f = f0 + (1.0 - f0) * (m2 * m2 * m);
	return d * vis * f * ndl * radiancia;
}

void fragment() {
	if (mundo.y < corte) {
		discard;
	}
	// La oclusión horneada llega suave; se le aprieta el contraste para que los
	// huecos a medias (bajo la ceja, entre los dientes, la sien) también cuenten.
	float oclusion = pow(clamp(COLOR.r, 0.0, 1.0), 1.7);
	float canto = COLOR.g;
	float diente = COLOR.b;
	vec3 p = local * escala_detalle + semilla;

	// --- Las lecturas ------------------------------------------------------------
	// Tres planos de la coordenada local, pesados por la normal LOCAL a la octava:
	// la franja donde se mezclan dos queda estrecha y no se ve el dibujo doble.
	// Mezclar dos ruidos ecualizados los aplana (la variación cae con la raíz de
	// los pesos al cuadrado): `kw` se la devuelve (como `superficie.gdshaderinc`).
	vec3 w = abs(normalize(normal_local));
	w *= w;
	w *= w;
	w *= w;
	w /= w.x + w.y + w.z;
	float kw = inversesqrt(dot(w, w));
	// Grano, tesela de 0,25: su moteado (A, de 9 por tesela) tiene el tamaño del
	// `fbm(p·36)` de antes, y su relieve fino (R) el del poro (`ruido(p·210)`).
	vec3 pg = p * 4.0;
	vec4 gr = texture(tex_grano, pg.zy + vec2(0.31, 0.67)) * w.x + texture(tex_grano, pg.xz) * w.y
		+ texture(tex_grano, pg.xy + vec2(0.59, 0.13)) * w.z;
	// Manchas, tesela de 0,31: su variación grande (R, 2,5 por tesela) es el
	// `fbm(p·8)` de antes.
	vec3 pm = p * 3.2;
	vec4 ma = texture(tex_manchas, pm.zy + vec2(0.43, 0.29)) * w.x + texture(tex_manchas, pm.xz) * w.y
		+ texture(tex_manchas, pm.xy + vec2(0.77, 0.51)) * w.z;
	ma = clamp(0.5 + (ma - 0.5) * kw, 0.0, 1.0);
	// Grietas (B, la distancia) y motas del poro (A), en su tesela: 5 celdas, algo
	// más menudas que las de antes porque la red de antes era 3D cortada por la
	// cúpula (ver `generar_marcas.py`). SIN MIPMAP (`textureLod` 0), como se calculaban antes, a
	// pelo en cada píxel: con mipmap la mota se emborronaba en una mancha blanda y
	// redonda y la distancia a la grieta se quedaba sin su cero (la raya se iba).
	// Cada plano por separado: la raya se saca de cada uno (ver «Grietas»).
	vec3 pc = p / TESELA_GRIETA;
	vec4 mc_x = textureLod(tex_marcas, pc.zy + vec2(0.17, 0.83), 0.0);
	vec4 mc_y = textureLod(tex_marcas, pc.xz, 0.0);
	vec4 mc_z = textureLod(tex_marcas, pc.xy + vec2(0.71, 0.37), 0.0);
	float motas = mc_x.a * w.x + mc_y.a * w.y + mc_z.a * w.z;

	// Lo que antes eran ruidos por código, como percentil (0 a 1, repartido igual).
	float u_manchas = ma.r;
	float u_moteado = clamp(0.5 + (gr.a - 0.5) * kw, 0.0, 1.0);
	// Y en valor, para lo que se usaba sin umbral: la media y la desviación del
	// ruido de antes (fbm·8: 0,51 ± 0,155; fbm·36: 0,504 ± 0,120). Un reparto
	// uniforme de 0 a 1 tiene una desviación de 0,289.
	float manchas = 0.51 + (u_manchas - 0.5) * 0.536;
	float moteado = 0.504 + (u_moteado - 0.5) * 0.415;
	// El poro: el relieve fino del grano (media 0,654) centrado como `ruido(p·210)`.
	float poro = 0.5 + (gr.r - 0.654) * kw;

	// Grietas finas, a parches. En los huesos sueltos, pocas: el parche es el
	// `fbm(p·4,2)` de antes por encima de 0,50–0,66, percentiles 0,37–0,97 de las
	// hondonadas (A) de las manchas. EN LA BÓVEDA (`suturas`), una RED: el parche
	// de antes es un ruido del tamaño del cráneo entero, y en el cráneo de antes
	// caía alto: la bóveda de la gira 5 sale cuarteada de punta a punta, con rayas
	// largas y ramificadas. Con el percentil, aquí caía a medias, y la crítica de
	// la gira 6 lo vio: «menos grietas, más cortas y a trozos». Por eso en la
	// bóveda el parche se abre: cubre casi todo, y entero más de la mitad. (Con
	// las celdas de antes, 4 por tesela, eso da en la bóveda de c2_02 las seis o
	// siete rayas largas de la gira 5.)
	// SOLO EN LA BÓVEDA (22-nov-2026). Abierto en todo el cráneo, una raya larga
	// bajaba por la frente entre los ojos hasta la nariz y otra cruzaba la sien
	// (crítica de la gira 7, c2_v5_01 y v1_01): «la frente blindada se ha
	// agrietado». En la gira 5 la frente y la cara salían lisas, solo con poro,
	// y las grietas se quedaban arriba. Así que en el cráneo el parche se apaga
	// por delante de z = 0,015 —la frente que para la bola (`morro`, de z = 0,035
	// en adelante) y la cara quedan fuera entera—, y lo que queda es la bóveda y
	// la nuca. Los demás huesos (`suturas` = 0) siguen con sus pocas grietas.
	// Y EN LA BÓVEDA, A TRES CUARTOS: la red de la gira 5 era de «marrón medio»
	// porque su parche (un `fbm` por encima de 0,50–0,66) casi nunca llegaba a 1
	// en el cráneo; con el parche entero, la raya salía al tono más oscuro y la
	// crítica la vio «más oscura que cualquiera de la gira 5».
	float boveda = mix(1.0, 0.75 * (1.0 - smoothstep(0.015, 0.045, local.z)), suturas);
	// (En la bóveda, de 0,02 a 0,30: «una malla pareja por toda la bóveda», la
	// gira 7 la tenía a parches, «concentrada en un nudo en Y».)
	float parche = smoothstep(mix(0.37, 0.02, suturas), mix(0.97, 0.30, suturas), ma.a)
		* grietas * (1.0 - diente) * boveda;
	// LA RAYA, de la DISTANCIA (`generar_marcas.py`, en F2 − F1 de celda). La de
	// antes era 1 − smoothstep(0,002, 0,008); aquí algo más fina, (0,001,
	// 0,0065), porque la interpolación entre texeles ya la abre un poco (con la
	// de antes tal cual salía de 2–3 píxeles en el visor, y en c2_02 el triple
	// de píxeles muy oscuros que la gira 5). Para que no se rompa en una fila de
	// puntos (gira 6: «negro y claro alternos»), el canto de fuera nunca baja de
	// 1,1 píxeles (`fwidth`): la raya queda de un píxel como poco, suave. Y cuanto
	// más se ensancha para llegar a ese píxel, más clara (hasta el 65 %): la de
	// antes, más fina que un píxel, se veía a medio tono, y a tono entero y ancha
	// salía una red de venas negras.
	// Cada plano saca la suya; donde dos se mezclan van las dos (con la media de
	// las distancias, se borraban en la franja de mezcla).
	// Y TAMPOCO DE MÁS DE UN PÍXEL (22-nov-2026). Con el medio ancho fijo en
	// 0,0065, donde el plano del triplanar cae sesgado sobre el hueso la distancia
	// crece despacio en la pantalla y la raya salía de dos y tres píxeles, y
	// oscura: «dos o tres tramos más oscuros y algo más gruesos que cualquiera de
	// la gira 5» (crítica de la gira 7, c2_v5_03). Ahora el medio ancho va entre
	// 0,5 y 0,9 píxeles (`fwidth`): ni se corta ni engorda. Su canto empieza en el
	// 30 % de ese ancho, porque entre dos texeles la distancia no baja de cero
	// (medio texel, ~0,004): con el canto en 0,001 la raya iba a tramos más y
	// menos negros según cayera la línea sobre la rejilla. Lo que se ensancha
	// para llegar al medio píxel se aclara, hasta el 60 %: la de antes, más fina
	// que un píxel, se veía marrón medio. (Medido sobre una bóveda de mentira con
	// la de antes al lado: `arreglos3_calavera/pruebas/esfera.py`, modo «tope».)
	vec3 d_grieta = vec3(mc_x.b, mc_y.b, mc_z.b) * RANGO_GRIETA;
	vec3 px_grieta = fwidth(d_grieta);
	vec3 ancho = clamp(vec3(0.0060), px_grieta * 0.5, px_grieta * 0.9);
	vec3 raya = (1.0 - smoothstep(ancho * 0.3, ancho + px_grieta * 0.5, d_grieta))
		* clamp(w * 1.6, 0.0, 1.0) * clamp(0.0060 / ancho, 0.6, 1.0);
	float grieta = max(max(raya.x, raya.y), raya.z) * parche;
	// El cerco de mugre de alrededor: 1 − smoothstep(0,02, 0,10) de antes.
	float junto_grieta = dot(1.0 - smoothstep(vec3(0.02), vec3(0.10), d_grieta), w) * parche;

	// La sutura: la ranura (`sutura`, 0 a 1) y su cerco amarillento. La ranura no
	// se pinta: se TALLA (abajo, en «La ranura»). Las tres lecturas van siempre,
	// fuera de la rama (aunque sin mipmap: ver `distancia_sutura`).
	vec2 uv_sutura = clamp((local.xz - SUTURA_DESDE) / SUTURA_MIDE, vec2(0.5 * TEXEL), vec2(1.0 - 0.5 * TEXEL));
	float d_sutura = distancia_sutura(uv_sutura, local.y, local.z);
	float d_x = distancia_sutura(uv_sutura + vec2(TEXEL, 0.0), local.y, local.z);
	float d_z = distancia_sutura(uv_sutura + vec2(0.0, TEXEL), local.y, local.z);
	// La ranura mide 0,8 mm: en la mesa, un píxel, y en el perfil de la bóveda,
	// donde la sagital se ve de canto, mucho menos. Ahí, a pelo, salía a puntos
	// negros sueltos (gira 6). Como la grieta: el canto de fuera no baja de 1,2
	// píxeles, y lo que se ensancha se aclara. `resuelta` (1 = la ranura cabe en
	// su píxel) apaga también su luz tallada cuando ya no cabe: un labio claro y
	// otro oscuro dentro del mismo píxel dan el tono de en medio, no negro.
	float px_sutura = fwidth(d_sutura);
	float fuera_sutura = max(0.00105, px_sutura * 1.2);
	float resuelta = clamp(0.00105 / fuera_sutura, 0.0, 1.0);
	float sutura = (1.0 - smoothstep(0.00025, fuera_sutura, d_sutura)) * suturas
		* max(resuelta, 0.5);
	float cerco = (1.0 - smoothstep(0.001, 0.006, d_sutura)) * suturas;

	// La frente que para la bola: el morro de la bóveda, por ENCIMA de las cejas.
	// (Más abajo se comía las cuencas y la cara dejaba de leerse.) Con el borde
	// mordido por el moteado, como hueso sobado a manchas, no una pegatina.
	float morro = smoothstep(0.035, 0.085, local.z) * smoothstep(0.046, 0.066, local.y)
		* smoothstep(0.118, 0.090, local.y) * suturas;
	morro *= smoothstep(0.25, 0.55, morro + (u_moteado - 0.5) * 0.25);

	// --- El color --------------------------------------------------------------
	// La base es el hueso del sprite (TIERRA_5) con un punto de crema; el tono
	// medio, a manchas. (Con la base a un 30 % del medio, bajo el fuego de la mesa
	// —y junto a la llama, que alumbra— salía color calabaza, no hueso.)
	// Umbrales de antes → percentiles: manchas 0,42–0,72 → 0,29–0,90; 0,30–0,50 →
	// 0,13–0,46; moteado 0,56–0,82 → 0,67–1,0.
	vec3 col = mix(hueso, hueso_luz, 0.10);
	col = mix(col, hueso_medio, smoothstep(0.29, 0.90, u_manchas) * 0.55);
	col = mix(col, hueso, (1.0 - smoothstep(0.13, 0.46, u_manchas)) * 0.55);
	// El moteado claro, (0,76, 1,10) y no (0,67, 1,0): el percentil de los dos
	// cortes no basta, porque el ruido de antes no se reparte igual —el `fbm`
	// es casi normal y su smoothstep subía despacio—. Con (0,67, 1,0) aclaraba el
	// DOBLE (media 0,165 contra 0,082; en el percentil 84, 0,52 contra 0,16) y
	// la bóveda salía moteada a manchas claras y oscuras (crítica de la gira 7).
	// El par nuevo sale de ajustar las dos curvas (`arreglos3_calavera/pruebas/
	// ajuste.py`): media 0,078.
	// Y CON LA MITAD DE FUERZA (0,10 y no 0,22): con la misma media, el canal A
	// del grano hace manchas de canto duro, y el `fbm` de antes, nubes que se
	// funden; pintadas sobre una bóveda de mentira (`pruebas/moteado.py`), las de
	// antes casi no se ven y las de la textura salen a lunares claros. Con la
	// mitad quedan tan quietas como las de la gira 5.
	col = mix(col, hueso_luz, smoothstep(0.76, 1.10, u_moteado) * 0.10);
	// Y manchas viejas, anchas y a parches: el hueso no envejece parejo. Es lo
	// que hace el sprite con su trama de TIERRA_4 por el lado en sombra. Cubren
	// lo que cubría el `fbm(p·3,3)` de antes sobre el cráneo: un 8 %. Salen de
	// lo más bajo de las hondonadas (A), que son anchas y suaves como aquel; con
	// la mugre (G), que es rota, salían lunares de borde duro.
	// Y CON LA FUERZA DE ANTES, que era poca: aquel ruido, sobre el cráneo, vale
	// 0,42 ± 0,06 y apenas pasa de 0,57, así que su smoothstep(0,50, 0,72) no
	// subía de 0,3 (`calavera/pruebas/distribuciones.py`). Llevado a percentil
	// sin ese tope llegaba a 1: manchas grises más de tres veces más hondas, lo
	// primero que vio la crítica de la gira 6 («el hueso parece más sucio»).
	float vieja = smoothstep(0.91, 1.0, 1.0 - ma.a) * 0.3 * (1.0 - diente);
	col = mix(col, hueso_sombra, vieja * 0.26);
	// El poro va en el COLOR y no en el relieve: motas oscuras sueltas y menudas,
	// como el hueso de verdad. (Con el poro modulando todo el tono al ±13 % y en la
	// normal, de cerca salía piel de naranja.)
	col *= 0.95 + 0.07 * poro;
	col *= 1.0 - 0.22 * motas * (1.0 - diente);
	// Los cantos, gastados: más pálidos.
	float filo = clamp(canto * (0.70 + 0.6 * moteado), 0.0, 1.0);
	col = mix(col, hueso_luz, filo * 0.62);
	// Los huecos guardan la mugre, y lo hondo se va al negro. Y lo que roza el
	// suelo se ensucia de abajo arriba.
	float abajo = roce * (1.0 - smoothstep(-0.105, 0.010, local.y));
	float sucio = pow(clamp(1.0 - oclusion, 0.0, 1.0), 1.15);
	sucio = clamp(sucio * (0.80 + 0.50 * moteado) + cerco * 0.08 + junto_grieta * 0.10
		+ abajo * (0.16 + 0.22 * manchas), 0.0, 1.0);
	col = mix(col, hueso_medio, smoothstep(0.03, 0.26, sucio));
	col = mix(col, hueso_sombra, smoothstep(0.20, 0.50, sucio));
	col = mix(col, mugre, smoothstep(0.44, 0.74, sucio));
	col = mix(col, hondo, smoothstep(0.68, 0.92, sucio));
	// Las grietas, una raya oscura. Las suturas amarillean el borde y guardan algo
	// de mugre en el fondo del surco (poca: lo oscuro lo pone el labio en sombra).
	col = mix(col, amarillo, cerco * 0.30);
	col = mix(col, mix(hueso_sombra, mugre, 0.55), grieta * 0.80);
	col = mix(col, mix(amarillo, hueso_sombra, 0.55), sutura * 0.55);
	// En lo hondo (las cuencas, la nariz, la boca) el hueso se va al gris frío, y
	// no al pardo: es lo que hace el sprite con su sombra gris-parda.
	col = mix(col, gris_hondo, smoothstep(0.15, 0.55, sucio) * 0.45 * (1.0 - diente));
	// Los dientes: esmalte amarillento, con el sarro en la raíz y entre diente y diente.
	vec3 esmalte = mix(hueso_luz, amarillo, 0.35 + 0.35 * manchas);
	esmalte = mix(esmalte, hueso_medio, smoothstep(0.08, 0.42, sucio));
	esmalte = mix(esmalte, mugre, smoothstep(0.45, 0.85, sucio));
	col = mix(col, esmalte, diente);
	// La frente blindada: oscura y pulida, como hueso sobado o hierro viejo. No
	// brilla por sí sola: es el fuego de la cripta el que le saca un reflejo duro.
	float coraza = blindaje * morro * (1.0 - diente);
	col = mix(col, pulido * (0.85 + 0.30 * manchas), coraza * 0.80);
	// El sprite se ve con luz blanca; la cripta alumbra con fuego. Un hueso con
	// TODO su color, bajo el fuego, sale naranja: se le quita un poco de color para
	// que en la mesa se siga leyendo hueso y no barro.
	col = mix(col, vec3(dot(col, vec3(0.30, 0.59, 0.11))), desatura);

	// La oclusión también apaga la luz directa: dentro de una cuenca no hay fuego
	// que entre. (En Compatibility no hay oclusión de pantalla que lo haga.)
	float sombra_propia = mix(0.10, 1.0, smoothstep(0.0, 0.55, oclusion));
	AO = mix(0.15, 1.0, oclusion);

	// --- El tacto ---------------------------------------------------------------
	// MATE. Con la rugosidad a 0,58 en los cantos y el especular a 0,3–0,6, el
	// fuego le sacaba un brillo cremoso de plastilina. El hueso viejo apenas
	// devuelve brillo: algo en el filo gastado, nada en lo hondo (la cuenca es un
	// pozo, rugosidad 1 y sin especular: si brilla, parece una pupila).
	// (Con luz por vértice esto manda en el reflejo del ambiente y en la difusa de
	// «La luz por píxel»; el brillo de las luces es el ancho de la rugosidad 1 del
	// `vertex()`, y en el hueso, con un especular de 0,2–0,3, es el 1 % de la
	// difusa: lo mismo que antes.)
	float rug = 0.90 - filo * 0.10 + sucio * 0.08 - (moteado - 0.5) * 0.08;
	rug = mix(rug, 1.0, smoothstep(0.45, 0.80, sucio));
	// Los dientes: esmalte gastado, algo menos mate que el hueso.
	rug = mix(rug, 0.52 + sucio * 0.40, diente);
	rug = mix(rug, 0.16 + 0.10 * moteado, coraza);
	rug = clamp(rug, 0.14, 1.0);
	float especular = mix(0.18, 0.34, max(diente, filo * 0.5)) * sombra_propia
		* (1.0 - smoothstep(0.40, 0.75, sucio));
	especular = mix(especular, 0.95, coraza);
	float metal = 0.45 * coraza;
	ROUGHNESS = rug;
	SPECULAR = especular;
	METALLIC = metal;

	// --- La luz por píxel ----------------------------------------------------------
	// Con luz por vértice Godot pone una difusa LAMBERT calculada en los vértices
	// con la normal de la malla. Antes era BURLEY por píxel con la normal tallada.
	// Las dos diferencias que se ven se corrigen aquí, en el color, con las tres
	// luces que más le dan:
	//   · BURLEY. En un hueso rugoso (0,9) aclara la luz rasante: el fuego, bajo,
	//     le da a la bóveda casi de canto, y con Lambert la bóveda vista desde
	//     arriba salía un 8 % más oscura y más azul (la luna ganaba al fuego).
	//   · LA RANURA de la sutura. Antes se tallaba en la NORMAL y la luz la
	//     dibujaba: un labio iluminado y otro en sombra. Se hace la misma cuenta:
	//     cuánto inclinaba la ranura la normal (la pendiente del surco por 0,24 y
	//     por la fuerza del relieve de antes, 0,0013: el labio a unos 30°).
	// Lo que da cada luz con Burley y la normal tallada, entre lo que da con
	// Lambert y la de la malla, multiplica el color. CANAL A CANAL, no en gris
	// (21-nov-2026): cada luz se equivoca por su lado, y en la mesa son de colores
	// distintos —el relleno, cálido y de frente, y la luna, fría y de lado—. En el
	// canto de arriba a la izquierda los vértices le daban luna de más y relleno
	// de menos; un cociente gris aclaraba los dos por igual y el canto salía con
	// un filo frío, blanco azulado (la crítica de juego, v1_01; en la gira 5 ese
	// canto era cálido, B − R = −36, y en la 6, −4). Con el cociente por canal
	// cada luz se lleva su parte.
	vec3 n_mundo = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 v_mundo = normalize(CAMERA_POSITION_WORLD - mundo);
	vec3 l_a = hacia_luz(luz_a_sitio, mundo);
	vec3 l_b = hacia_luz(luz_b_sitio, mundo);
	vec3 l_c = hacia_luz(luz_c_sitio, mundo);
	float t_surco = clamp((d_sutura - 0.00025) / 0.0008, 0.0, 1.0);
	// La pendiente del surco (de 0 a 1 en 0,8 mm): hacia la línea.
	vec2 pendiente = -vec2(d_x - d_sutura, d_z - d_sutura) / (TEXEL * SUTURA_MIDE.x)
		* (6.0 * t_surco * (1.0 - t_surco) / 0.0008);
	vec3 inclina = (MODEL_MATRIX * vec4(pendiente.x, 0.0, pendiente.y, 0.0)).xyz
		* (0.24 * 0.0013 * relieve * (1.0 - coraza * 0.8) * suturas * resuelta);
	inclina -= n_mundo * dot(inclina, n_mundo);
	vec3 n_ranura = normalize(n_mundo + inclina);
	// Lo que puso Godot: Lambert en los vértices, interpolado (ver `vertex()`). Así
	// también se corrige lo que la interpolación aplana: sin esto, la luz del
	// fuego se apagaba antes de tiempo hacia el terminador y la frontera entre el
	// fuego y la luna en la bóveda salía blanda y corrida.
	vec3 luz_antes = luz_a_color * lambert_vertice.x + luz_b_color * lambert_vertice.y
		+ luz_c_color * lambert_vertice.z;
	vec3 luz_ahora = luz_a_color * burley(n_ranura, v_mundo, l_a, rug)
		+ luz_b_color * burley(n_ranura, v_mundo, l_b, rug)
		+ luz_c_color * burley(n_ranura, v_mundo, l_c, rug);
	// El ambiente y las demás luces no cambian: cuentan como un fondo fijo, poco.
	vec3 fondo = 0.10 * (luz_a_color + luz_b_color + luz_c_color) + 1e-3;
	// Con topes, porque el cociente multiplica TODO el color, también el ambiente
	// y las demás luces:
	//   · por arriba, 1,5 (era 2), y en el perfil, mirado de refilón, nada: ahí
	//     Burley dobla lo de Lambert y los vértices del canto apenas reciben luz,
	//     así que el cociente se disparaba y aclaraba también el ambiente: el
	//     filo frío, blanco azulado, del borde del cráneo (crítica de juego,
	//     v1_01). Antes ese refuerzo solo tocaba a una luz, y en un píxel.
	//   · por abajo, en la sutura, 0,45. El labio en sombra de la ranura, visto de
	//     canto en el perfil de la bóveda, dejaba el cociente en casi cero y le
	//     quitaba también el ambiente: puntitos negros a lo largo del borde de
	//     arriba (gira 6). Antes ese labio solo perdía su luz directa.
	//   · y la banda de 2–3 píxeles junto al perfil, donde el tope aún subía,
	//     salía clara y crema en toda la silueta de la bóveda (crítica de la
	//     gira 7, c2_02 y c2_03; la gira 5 no la tiene). Es este cociente: con
	//     él a 1 la banda desaparece (comprobado en c2_v5_01, la misma postura que
	//     la gira 5). Junto al perfil los vértices reciben la luz interpolada de
	//     menos y el cociente la sube, pero Burley de verdad, mirado de refilón,
	//     no aclara (su término de vista resta con la luz de lado o de atrás). Así
	//     que el tope llega a 1,5 bien adentro, de N·V 0,45 a 0,75.
	float tope = mix(1.0, 1.5, smoothstep(0.45, 0.75, dot(n_mundo, v_mundo)));
	col *= clamp((luz_ahora + fondo) / (luz_antes + fondo), vec3(0.45 * cerco), vec3(tope));

	vec3 albedo = col * sombra_propia * claridad;

	// LA CORAZA BRILLA CON EL FUEGO, a mano. Con la luz entera era GGX de
	// rugosidad 0,16–0,26: un reflejo duro de cada luz. Por vértice saldría a
	// manchas de triángulo, así que se calcula aquí con las tres luces, igual que
	// lo calculaba Godot. Y la luz por vértice le deja a la coraza un brillo ANCHO
	// (Blinn de rugosidad 1 por su f0, que es alto): unos 0,3·f0 de albedo de más,
	// neutro como el gris pulido. Se le quita al albedo para que no se aclare.
	vec3 f0 = mix(vec3(0.16 * especular * especular), albedo, metal);
	albedo = max(albedo - coraza * 0.30 * f0 / (1.0 - metal), vec3(0.0));
	ALBEDO = albedo;
	vec3 duro = brillo(n_mundo, v_mundo, l_a, luz_a_color * luz_especular.x, rug, f0)
		+ brillo(n_mundo, v_mundo, l_b, luz_b_color * luz_especular.y, rug, f0)
		+ brillo(n_mundo, v_mundo, l_c, luz_c_color * luz_especular.z, rug, f0);

	// --- El golpe --------------------------------------------------------------------
	float de_frente = frente * morro;
	EMISSION = hueso * (golpe * 0.30 + de_frente * 0.20) * mix(0.3, 1.0, oclusion) + duro * coraza;
}
