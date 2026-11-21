shader_type spatial;
// SIN LUZ DE GODOT. Con luz, este programa tardaba 6,7 s en compilar en un
// navegador (banco con ANGLE, en frío: la luz de Godot sola son 5,5); sin luz,
// 0,7. Lo que arde no necesita que lo alumbren: lo único que recibía luz era la
// costra negra, y esa se alumbra aquí con una luz propia barata («luz_costra»,
// de una dirección fija), que es lo que hacía el fuego que siempre tiene al lado.
render_mode unshaded;

// CRIPTA 3D — EL ASCUA, y con otros colores el ARCANO. Lo único de la mesa que
// da luz propia.
//
// No es una superficie que «solo emite» (eso es el neón de ÓRBITA, y aquí está
// prohibido): es un carbón. Tiene costra negra que recibe la luz de fuera,
// placas que se enfrían, grietas por las que se ve el fuego, y una TEMPERATURA
// por píxel que decide el color —de rojo apagado a casi blanco— y cuánta luz
// da. La temperatura sale de cinco cosas:
//   - lo que mira a la cámara arde más («nucleo»): en cualquier bulto sale el
//     centro casi blanco y el borde rojo sin modelar nada. En negativo es al
//     revés, arde el contorno: eso es el arcano;
//   - la costra va a islas: dentro de una isla, el centro de cada placa se
//     enfría hasta el negro y las grietas entre placas siguen ardiendo;
//   - un ruido que HIERVE: dos lecturas de manchas que corren en sentidos
//     opuestos, multiplicadas. Una sola se ve pasar como una cinta; dos cruzadas
//     no van a ningún sitio y parpadean;
//   - una respiración lenta, con la fase corrida por la posición para que dos
//     ascuas juntas no latan a la vez;
//   - y el canal B del color de vértice, si se pide: dónde está el fuego.
//
// Nueve lecturas de textura. SIEMPRE con una luz de verdad al lado: esto pinta
// la brasa, no ilumina el suelo.

uniform sampler2D tex_grano : filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_celdas : filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_manchas : filter_linear_mipmap, repeat_enable;

uniform mat3 marco;
uniform vec3 desfase = vec3(0.0);
uniform float en_local = 0.0;
uniform float escala = 0.24;            // lo que mide una tesela de placas, en unidades de mundo

uniform vec3 color_costra : source_color = vec3(0.02);
uniform vec3 color_rojo : source_color = vec3(0.5, 0.05, 0.03);
uniform vec3 color_naranja : source_color = vec3(1.0, 0.3, 0.05);
uniform vec3 color_claro : source_color = vec3(1.0, 0.75, 0.25);
uniform vec3 color_nucleo : source_color = vec3(1.0, 0.95, 0.8);
uniform vec3 tinte : source_color = vec3(1.0);
uniform float energia = 3.0;
// La luz que recibe la costra, que antes ponía el fuego de al lado: un color
// LINEAL (como la energía de una luz, no un color de paleta), cuánta, y de dónde
// viene (en el mundo). Con un 20 % que llega por todos lados, para que la cara de
// atrás no se quede en negro puro. Los números de la biblioteca salen de igualar
// el muestrario de antes (la costra a la luz del farol de al lado).
uniform vec3 luz_costra = vec3(1.0, 0.22, 0.08);
uniform float fuerza_costra = 8.7;
uniform vec3 dir_costra = vec3(0.05, 0.6, 0.8);
// LA LUZ DE SU SITIO. Un mismo perfil sirve a braseros que están en luces muy
// distintas: los del campo tienen su fuego entero encima; los de pie de la sala y
// los de las esquinas, un fuego que «entorno» baja a un cuarto o a la mitad
// (`entorno._peso_zona`). Con una sola luz fija la costra de la sala salía
// alumbrada como la del campo: el crítico midió el carbón del brasero de pie de
// 53,5 a 69,0 de luminancia (gira5 → gira6), «una pila roja». Así que la costra
// se alumbra con lo que le toca a su sitio, con los MISMOS cortes que el reparto
// del fuego: |x − eje| > medio campo es albardilla, más allá (o por debajo del
// mueble) es sala, y del campo hacia el fondo (z < ábside) es ábside.
// sitio_peso = (campo, ábside, albardilla, sala); sitio_corte = (eje x, medio
// campo, fuera de la mesa, z del ábside); sitio_y = la y por debajo de la cual es
// sala. Por defecto, todo a 1: igual que sin esto.
uniform vec4 sitio_peso = vec4(1.0);
uniform vec4 sitio_corte = vec4(2.0, 1.7, 2.6, 7.0);
uniform float sitio_y = -0.3;

uniform float calor = 0.6;              // la temperatura de partida, 0..1
uniform float nucleo = 0.4;             // cuánto más arde lo que mira a la cámara
uniform float costra = 0.5;             // cuánta superficie tapan las placas frías
uniform float grietas = 0.5;            // cuánto arden las grietas
uniform float latido = 0.1;             // la respiración
uniform float ritmo = 0.45;             // latidos por segundo
uniform float parpadeo = 0.2;           // el hervor
uniform float prisa = 0.3;              // lo deprisa que hierve
uniform float relieve = 0.6;
uniform float usa_vertice = 0.0;
uniform float suciedad = 0.5;           // ceniza: cuánto apaga la oclusión de la malla

varying vec3 v_pos;
varying vec3 v_nor;
varying float v_sitio;

void vertex() {
	// El sitio, en el mundo y por vértice (en el vértice cuesta tres pasos; una
	// pieza de carbón no cruza nunca un corte, así que no se ve la costura).
	vec3 pm = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float fuera = abs(pm.x - sitio_corte.x);
	float sitio = mix(sitio_peso.x, sitio_peso.y, step(pm.z, sitio_corte.w));
	sitio = mix(sitio, sitio_peso.z, step(sitio_corte.y, fuera));
	v_sitio = mix(sitio, sitio_peso.w, max(step(sitio_corte.z, fuera), step(pm.y, sitio_y)));
	vec3 p;
	vec3 n;
	if (en_local > 0.5) {
		vec3 esc = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
		p = VERTEX * esc;
		n = normalize(NORMAL / esc);
	} else {
		p = pm;
		n = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	}
	v_pos = marco * (p + desfase);
	v_nor = marco * n;
}

void fragment() {
	vec3 p = v_pos;
	vec3 n0 = normalize(v_nor);
	vec3 w = abs(n0);
	w *= w;
	w *= w;
	w *= w;
	w /= (w.x + w.y + w.z);
	float kw = inversesqrt(dot(w, w));

	vec3 pc = p / escala;
	vec4 cx = texture(tex_celdas, pc.zy + vec2(0.17, 0.83));
	vec4 cy = texture(tex_celdas, pc.xz);
	vec4 cz = texture(tex_celdas, pc.xy + vec2(0.71, 0.37));
	float a_grieta = cx.a * w.x + cy.a * w.y + cz.a * w.z;
	vec3 gm = w.x * vec3(0.0, cx.b - 0.5, cx.g - 0.5)
			+ w.y * vec3(cy.g - 0.5, 0.0, cy.b - 0.5)
			+ w.z * vec3(cz.g - 0.5, cz.b - 0.5, 0.0);
	vec3 pd = p / (escala * 0.55);
	vec4 dx = texture(tex_grano, pd.zy + vec2(0.31, 0.67));
	vec4 dy = texture(tex_grano, pd.xz);
	vec4 dz = texture(tex_grano, pd.xy + vec2(0.59, 0.13));
	float h = clamp(0.5 + (dx.r * w.x + dy.r * w.y + dz.r * w.z - 0.5) * kw, 0.0, 1.0);
	vec3 gd = w.x * vec3(0.0, dx.b - 0.5, dx.g - 0.5)
			+ w.y * vec3(dy.g - 0.5, 0.0, dy.b - 0.5)
			+ w.z * vec3(dz.g - 0.5, dz.b - 0.5, 0.0);

	// El hervor. Va en un plano inclinado y no en triplanar: es un ruido grande
	// que se mueve, y ahí un estirón no se ve; son dos lecturas en vez de seis.
	vec2 q = (p.xz + p.y * vec2(0.71, 0.53)) / (escala * 3.1);
	float t = TIME * prisa;
	float a1 = texture(tex_manchas, q + vec2(t, t * 0.37)).r;
	float a2 = texture(tex_manchas, q * 1.37 - vec2(t * 0.61, t) + vec2(0.3, 0.7)).g;
	// Acotado: el producto de dos ruidos tiene la cola larga, y sin el tope esa
	// cola eran llamaradas blancas que se comían el naranja.
	float aire = min(a1 * a2 * 2.0, 1.0);
	// La costra va a ISLAS (la novena lectura, quieta). Con costra por todas
	// partes y todas las grietas encendidas sale una jirafa, no una brasa: lo que
	// se ve en un brasero es carbón al rojo vivo con placas negras encima.
	float isla = texture(tex_manchas, q * 2.3 + vec2(0.61, 0.17)).a;
	float pulso = 0.5 + 0.5 * sin(TIME * ritmo * 6.2832 + (p.x + p.y + p.z) * 2.3);

	float hacia = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	// El calor se cuela desde la grieta placa adentro (cae con la distancia, no
	// de golpe), y no todas las grietas arden igual: las aviva el mismo aire que
	// hace el hervor. Con todas encendidas por igual sale una jirafa.
	// Primero el calor de fondo; después la costra, que cuaja DONDE HACE MENOS
	// CALOR: el centro queda limpio y casi blanco, y hacia el borde, que ya va
	// rojo, salen las placas negras con sus grietas encendidas.
	float base = calor
			+ nucleo * (hacia * hacia - 0.5)
			+ (aire - 0.5) * 2.0 * parpadeo
			+ (pulso - 0.5) * 2.0 * latido;
	float con_costra = smoothstep(0.55 - costra * 0.5, 0.95 - costra * 0.5,
			isla + (0.5 - base) * 1.2 + (h - 0.5) * 0.3);
	float grieta = exp(-a_grieta * 7.0);
	float placa = smoothstep(0.12, 0.7, a_grieta) * con_costra;
	float temp = base
			+ grietas * grieta * 0.5 * con_costra
			- placa * 0.5
			+ (h - 0.6) * 0.14;
	float oclu = 1.0;
	if (usa_vertice > 0.5) {
		temp *= COLOR.b;
		oclu = COLOR.r;
		// En lo hondo se junta la ceniza y el fuego se ahoga un poco.
		temp -= (1.0 - oclu) * 0.35 * suciedad;
	}
	temp = clamp(temp, 0.0, 1.15);

	vec3 c = mix(color_rojo, color_naranja, smoothstep(0.30, 0.58, temp));
	c = mix(c, color_claro, smoothstep(0.52, 0.80, temp));
	c = mix(c, color_nucleo, smoothstep(0.78, 1.05, temp));
	// La luz sube mucho más deprisa que la temperatura: lo rojo apenas alumbra y
	// lo blanco deslumbra. Es lo que separa una brasa de una pegatina naranja.
	float luz = smoothstep(0.06, 0.38, temp) * (0.10 + temp * temp * 1.3);

	vec3 pend = (gm * relieve + gd * relieve * 0.5) * 2.0 * kw;
	pend -= n0 * dot(n0, pend);
	vec3 n = normalize(n0 - pend) * marco;
	if (en_local > 0.5) {
		vec3 esc = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
		n = mat3(MODEL_MATRIX) * (n / esc);
	}

	// Sin luz de Godot, lo que sale es ALBEDO tal cual (EMISSION no se suma): la
	// costra alumbrada por su luz propia, con el relieve de las placas, y encima
	// el fuego. Godot pasa ALBEDO de sRGB a lineal al final (`scene.glsl`); con
	// luz, la luz multiplicaba DESPUÉS de esa cuenta. Por eso la luz propia entra
	// con la potencia 1/2,2: así la costra sale multiplicada en lineal, como antes,
	// y «luz_costra» se lee como una energía.
	float lambert = max(dot(normalize(n), normalize(dir_costra)), 0.0);
	vec3 luz_lineal = luz_costra * (fuerza_costra * v_sitio * (0.2 + 0.8 * lambert));
	vec3 costra_vista = color_costra * (0.7 + h * 0.6) * mix(1.0, oclu, 0.6)
			* pow(luz_lineal, vec3(1.0 / 2.2));
	ALBEDO = costra_vista + c * tinte * (energia * luz);
}
