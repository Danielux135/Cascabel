shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

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
//     serpenteante de la bóveda, TALLADA como ranura en la normal, no pintada—,
//     que es lo que hace que desde arriba se lea «calavera» y no «bola»;
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
/// Fuerza del relieve fino.
uniform float relieve = 1.0;
/// Cuánta luz devuelve: por debajo de 1 para que el fuego no la queme.
uniform float claridad = 0.88;
/// Cuánto color se le quita al hueso para compensar el fuego (0 = el de la paleta).
/// Poco: la base ya es marfil frío (con el tono de la paleta salía melocotón).
uniform float desatura = 0.14;

varying vec3 local;
varying vec3 mundo;

float azar(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float ruido(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(azar(i), azar(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(azar(i + vec3(0.0, 1.0, 0.0)), azar(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(azar(i + vec3(0.0, 0.0, 1.0)), azar(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(azar(i + vec3(0.0, 1.0, 1.0)), azar(i + vec3(1.0, 1.0, 1.0)), f.x), f.y),
		f.z);
}

float fbm(vec3 p) {
	return 0.55 * ruido(p) + 0.30 * ruido(p * 2.07 + 3.1) + 0.15 * ruido(p * 4.3 + 7.7);
}

// Celdas: la distancia al borde entre las dos celdas más cercanas. Donde vale
// casi cero hay una raya recta que se quiebra en los cruces: una GRIETA, no un
// garabato.
float borde_de_celda(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int a = -1; a <= 1; a++) {
		for (int b = -1; b <= 1; b++) {
			for (int c = -1; c <= 1; c++) {
				vec3 g = vec3(float(a), float(b), float(c));
				vec3 celda = i + g;
				vec3 o = vec3(azar(celda), azar(celda + 19.7), azar(celda + 43.3));
				vec3 r = g + o - f;
				float d = dot(r, r);
				if (d < d1) {
					d2 = d1;
					d1 = d;
				} else if (d < d2) {
					d2 = d;
				}
			}
		}
	}
	return sqrt(d2) - sqrt(d1);
}

// El relieve fino: un grano casi liso y el poro, menudo y somero. Solo altura;
// el color va aparte.
// SIN PICADURAS. Hubo un término de hoyos (`1 - smoothstep(ruido·170)`, con peso
// 0,36) que de cerca picaba la bóveda entera como la piel de una naranja: con la
// base crema, la crítica la llamó «plastilina naranja con piel de naranja». El
// hueso viejo es mate y casi liso al tacto; lo que tiene son GRIETAS, que van
// talladas aparte (ver `fragment`).
float altura(vec3 p) {
	float ondula = ruido(p * 34.0 + 5.0);
	float poro = ruido(p * 300.0 + 11.0);
	return ondula * 0.30 + poro * 0.10;
}

// El serpenteo de una sutura a lo largo de `t`: no es un diente de sierra (eso
// se leía a textura de código), sino un meandro de amplitud y paso cambiantes
// con rizos menudos encima, que es como engranan dos placas de hueso.
float meandro(float t, float s) {
	float ancho = 0.35 + 0.85 * ruido(vec3(t * 9.0, s, 1.3));
	float a = (ruido(vec3(t * 48.0, s, 0.0)) - 0.5) * 0.0060 * ancho;
	a += (ruido(vec3(t * 140.0, s, 5.0)) - 0.5) * 0.0034 * ancho;
	a += (ruido(vec3(t * 330.0, s, 9.0)) - 0.5) * 0.0013;
	return a;
}

// Las tres suturas de la bóveda, en coordenadas del cráneo. Devuelve la
// distancia a la más cercana (en unidades), o un número grande donde no hay.
// Cada una se va borrando a tramos (el último sumando de cada una): en un cráneo
// viejo las suturas se sueldan y no se ven enteras.
float distancia_sutura(vec3 p) {
	float lejos = 1.0;
	float ax = abs(p.x);
	// Sagital: por la línea media, de la coronilla hacia atrás.
	float sag = abs(p.x - meandro(p.z, 1.0) - 0.0025 * sin(p.z * 21.0));
	sag += smoothstep(0.034, 0.050, p.z) + (1.0 - smoothstep(-0.116, -0.098, p.z))
		+ (1.0 - smoothstep(0.0, 0.020, p.y));
	sag += (1.0 - smoothstep(0.30, 0.45, ruido(vec3(p.z * 30.0, 2.0, 7.0)))) * 0.01;
	lejos = min(lejos, sag);
	// Coronal: cruza de lado a lado por delante de la coronilla y baja a las sienes.
	float cor = abs(p.z - (0.044 - ax * 0.30 - ax * ax * 1.1) - meandro(p.x, 4.0));
	cor += smoothstep(0.100, 0.118, ax) + (1.0 - smoothstep(-0.030, -0.005, p.y));
	cor += (1.0 - smoothstep(0.28, 0.42, ruido(vec3(p.x * 34.0, 5.0, 3.0)))) * 0.01;
	lejos = min(lejos, cor);
	// Lambdoidea: la uve de atrás, más rizada (es la que más engrana).
	float lam = abs(p.z - (-0.106 + ax * 0.50) - meandro(p.x, 8.0) * 1.3);
	lam += smoothstep(0.098, 0.116, ax) + (1.0 - smoothstep(-0.050, -0.020, p.y));
	lam += (1.0 - smoothstep(0.25, 0.40, ruido(vec3(p.x * 28.0, 9.0, 1.0)))) * 0.01;
	lejos = min(lejos, lam);
	return lejos;
}

// La sutura como RANURA: la profundidad (0 a 1) del surco en cada punto. Es fina
// —menos de un milímetro de la criatura— y con el labio algo romo.
float surco(vec3 p) {
	float d = distancia_sutura(p);
	return 1.0 - smoothstep(0.00025, 0.00105, d);
}

void vertex() {
	local = VERTEX;
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
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

	// --- El dibujo -----------------------------------------------------------
	float manchas = fbm(p * 8.0);
	float moteado = fbm(p * 36.0 + 2.3);
	float poro = ruido(p * 210.0);

	// Grietas finas: bordes de celda, POCAS y solo a parches. Una red entera
	// de rayas es loza cuarteada, no hueso.
	// (Con el retorcido fuerte las rayas se rizaban en lazos: se queda en un
	// temblor.)
	float celda = borde_de_celda(p * 8.5 + (vec3(ruido(p * 30.0), ruido(p * 30.0 + 13.0),
		ruido(p * 30.0 + 29.0)) - 0.5) * 0.14);
	float parche = smoothstep(0.50, 0.66, fbm(p * 4.2 + 5.7)) * grietas * (1.0 - diente);
	// Finas: más gruesas, en la sombra se leían como venas pintadas.
	float grieta = (1.0 - smoothstep(0.002, 0.008, celda)) * parche;
	float junto_grieta = (1.0 - smoothstep(0.02, 0.10, celda)) * parche;

	// La sutura no se pinta: se TALLA. Aquí solo se mide el surco (para la mugre
	// que guarda dentro y el amarilleo del borde); la ranura la hace la normal,
	// abajo, y es la luz la que la dibuja: un labio iluminado y otro en sombra.
	float sutura = 0.0;
	float cerco = 0.0;
	if (suturas > 0.5) {
		sutura = surco(local);
		cerco = 1.0 - smoothstep(0.001, 0.006, distancia_sutura(local));
	}
	// La frente que para la bola: el morro de la bóveda, por ENCIMA de las cejas.
	// (Más abajo se comía las cuencas y la cara dejaba de leerse.) Con el borde
	// mordido por el ruido, como hueso sobado a manchas, no una pegatina.
	float morro = smoothstep(0.035, 0.085, local.z) * smoothstep(0.046, 0.066, local.y)
		* smoothstep(0.118, 0.090, local.y) * suturas;
	morro *= smoothstep(0.25, 0.55, morro + (fbm(local * 60.0 + semilla) - 0.5) * 0.6);

	// --- El color --------------------------------------------------------------
	// La base es el hueso del sprite (TIERRA_5) con un punto de crema; el tono
	// medio, a manchas. (Con la base a un 30 % del medio, bajo el fuego de la mesa
	// —y junto a la llama, que alumbra— salía color calabaza, no hueso.)
	vec3 col = mix(hueso, hueso_luz, 0.10);
	col = mix(col, hueso_medio, smoothstep(0.42, 0.72, manchas) * 0.55);
	col = mix(col, hueso, (1.0 - smoothstep(0.30, 0.50, manchas)) * 0.55);
	col = mix(col, hueso_luz, smoothstep(0.56, 0.82, moteado) * 0.22);
	// Y manchas viejas, anchas y a parches: el hueso no envejece parejo. Es lo
	// que hace el sprite con su trama de TIERRA_4 por el lado en sombra.
	float vieja = smoothstep(0.50, 0.72, fbm(p * 3.3 + 9.2)) * (1.0 - diente);
	col = mix(col, hueso_sombra, vieja * 0.26);
	// El poro va en el COLOR y no en el relieve: motas oscuras sueltas y menudas,
	// como el hueso de verdad. (Con el poro modulando todo el tono al ±13 % y en la
	// normal, de cerca salía piel de naranja.)
	col *= 0.95 + 0.07 * poro;
	col *= 1.0 - 0.22 * smoothstep(0.78, 0.95, ruido(p * 330.0 + 21.0)) * (1.0 - diente);
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
	// de mugre en el fondo del surco (poca: lo oscuro lo pone la sombra de la ranura).
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
	ALBEDO = col * sombra_propia * claridad;
	AO = mix(0.15, 1.0, oclusion);

	// --- El tacto ---------------------------------------------------------------
	// MATE. Con la rugosidad a 0,58 en los cantos y el especular a 0,3–0,6, el
	// fuego le sacaba un brillo cremoso de plastilina. El hueso viejo apenas
	// devuelve brillo: algo en el filo gastado, nada en lo hondo (la cuenca es un
	// pozo, rugosidad 1 y sin especular: si brilla, parece una pupila).
	float rug = 0.90 - filo * 0.10 + sucio * 0.08 - (moteado - 0.5) * 0.08;
	rug = mix(rug, 1.0, smoothstep(0.45, 0.80, sucio));
	// Los dientes: esmalte gastado, algo menos mate que el hueso.
	rug = mix(rug, 0.52 + sucio * 0.40, diente);
	rug = mix(rug, 0.16 + 0.10 * moteado, coraza);
	ROUGHNESS = clamp(rug, 0.14, 1.0);
	SPECULAR = mix(0.18, 0.34, max(diente, filo * 0.5)) * sombra_propia
		* (1.0 - smoothstep(0.40, 0.75, sucio));
	SPECULAR = mix(SPECULAR, 0.95, coraza);
	METALLIC = 0.45 * coraza;

	// El hueso deja pasar un pelo de luz: le quita el aire de yeso. Poco: con 0,07
	// era una de las cosas que lo hacían cera.
	BACKLIGHT = hueso * 0.03 * oclusion;

	// --- El relieve fino -----------------------------------------------------------
	if (relieve > 0.001) {
		float e = 0.0011 / escala_detalle;
		float h0 = altura(p);
		vec3 grad = vec3(
			altura((local + vec3(e, 0.0, 0.0)) * escala_detalle + semilla) - h0,
			altura((local + vec3(0.0, e, 0.0)) * escala_detalle + semilla) - h0,
			altura((local + vec3(0.0, 0.0, e)) * escala_detalle + semilla) - h0) / e;
		// La mitad que antes (0,0027): el relieve es un temblor de la superficie, no
		// un picado.
		float fuerza = 0.0013 * relieve * (1.0 - diente * 0.75) * (1.0 - coraza * 0.8)
			/ escala_detalle;
		// La ranura de la sutura: su pendiente, con un paso más fino que el del
		// grano porque el surco es más estrecho que él.
		if (suturas > 0.5 && cerco > 0.0) {
			float es = 0.00022;
			float s0 = surco(local);
			vec3 gs = vec3(surco(local + vec3(es, 0.0, 0.0)) - s0,
				surco(local + vec3(0.0, es, 0.0)) - s0,
				surco(local + vec3(0.0, 0.0, es)) - s0) / es;
			// El surco sube de 0 a 1 en menos de un milímetro (pendiente ~1.200);
			// por 0,24 y por la fuerza del relieve, el labio queda a unos 40°.
			grad -= gs * 0.24;
		}
		vec3 gv = (VIEW_MATRIX * MODEL_MATRIX * vec4(grad, 0.0)).xyz;
		gv -= NORMAL * dot(gv, NORMAL);
		NORMAL = normalize(NORMAL - gv * fuerza);
	}

	// --- El golpe --------------------------------------------------------------------
	float de_frente = frente * morro;
	EMISSION = hueso * (golpe * 0.30 + de_frente * 0.20) * mix(0.3, 1.0, oclusion);
}
