// CRIPTA 3D — BRASA: lo que comparten las dos capas de la llama.
//
// La llama no es una textura ni un humo: son DOS MALLAS con volumen, una dentro
// de otra, que arden con el mismo ruido:
//   · la MELENA  la corona entera, translúcida en el canto
//   · el NÚCLEO  la llama clara de dentro: es la cara
// Las dos van con el MISMO sombreador (`brasa_llama`, ver allí por qué). Aquí
// están el ruido, el movimiento y el COLOR, para que las dos se muevan y se
// tiñan igual: donde la melena se abre y deja ver el núcleo, los dos tienen el
// mismo color a la misma altura, y no queda borde.
//
// EL FUEGO ES LUZ, NO PINTURA. Antes el color salía de lo de frente que se mirase
// cada punto (un sombreado difuso fingido) en bandas de borde duro: salía una
// llama de vinilo, con el canto rojo cortando el naranja como una capucha. Ahora
// sale de la ALTURA, en el espacio del objeto: blanco amarillento en la base, que
// es donde está la cara, naranja a media lengua y rojo en las puntas, sin bandas
// (los pasos son anchos). Y emite por encima de 1, para que el brillo del entorno
// coja la llama y los ojos y nada más.
//
// El color de vértice viene de Blender: R oclusión (lo hundido entre lenguas),
// G cuánto de lengua es el punto (0 cuerpo, 1 punta), B la fase de su lengua.

uniform float tiempo = 0.0;
uniform float semilla = 0.0;
// De dónde a dónde va el modelo en reposo: el fondo del cráter y la punta.
uniform float pie = 0.05;
uniform float altura = 0.30;
// Cuánto se quedan atrás las puntas (en unidades, en el marco de la malla).
uniform vec3 arrastre = vec3(0.0);
uniform float vaiven = 1.0;
// 1 ardiendo, 0 apagada. Apagándose se ENCOGE y se enfría: un fuego que se
// apaga no se agujerea (ver `brasa_mover`).
uniform float vida = 1.0;
// Avivada: más clara, más alta.
uniform float avivar = 0.0;
// El fogonazo del golpe.
uniform float golpe = 0.0;
// Las ascuas son la misma llama un escalón más fría.
uniform float templado = 0.0;
// Cuánto hierve la piel donde no hay lengua. El núcleo casi nada: lleva los ojos
// encima, a dos milímetros, y si la cara hierve se los traga.
uniform float hervor_base = 0.18;
// Lo de debajo de esta altura no se encoge al apagarse: la cara y los ojos. Lo
// pone `brasa.gd`, de dónde acaban los ojos.
uniform float encoge_desde = 0.15;

uniform vec3 c_oro_claro : source_color = vec3(0.97, 0.85, 0.42);
uniform vec3 c_oro : source_color = vec3(0.88, 0.65, 0.24);
uniform vec3 c_naranja : source_color = vec3(0.91, 0.51, 0.29);
uniform vec3 c_rojo_luz : source_color = vec3(0.78, 0.29, 0.24);
uniform vec3 c_rojo : source_color = vec3(0.55, 0.18, 0.18);
uniform vec3 c_cobre : source_color = vec3(0.42, 0.23, 0.13);

// EL RUIDO SE LEE, NO SE CALCULA (web, 21-nov-2026). Era un ruido de valor 3D
// por código —ocho `hash` y siete mezclas por llamada— y la llama lo llamaba once
// veces: Direct3D, que es quien compila WebGL en Windows, lo despliega entero en
// cada variante, y la melena tardaba 2,5 s en compilar y el núcleo 1,1.
//
// `brasa_ruido.png` (de `brasa_ruido.gd`) es EL MISMO ruido de valor, horneado:
// la rejilla de azar con la curva suave ya dentro (8 píxeles por celda, 32 celdas
// por lado). La tercera dimensión, con el truco de siempre: el canal G es el R
// corrido (37, 17) celdas, así que una sola lectura trae el plano z = k en R y el
// z = k + 1 en G, y mezclarlos con la misma curva es lo que hacía la cuenta de
// antes. Mismo grano, mismo reparto de valores, los mismos umbrales valen. Lo que
// cambia es que se repite cada 32 celdas, y la llama entera son 17 a la escala
// más fina. El B es otro ruido, suelto, para lo que solo necesita un plano.
uniform sampler2D ruido_brasa : filter_linear, repeat_enable;

float brasa_ruido(vec3 x) {
	float k = floor(x.z);
	vec2 t = textureLod(ruido_brasa, (x.xy + vec2(37.0, 17.0) * k) * (1.0 / 32.0), 0.0).rg;
	float f = x.z - k;
	return mix(t.r, t.g, f * f * (3.0 - 2.0 * f));
}

// Un solo plano: el `tiron` y el `late` de las lenguas, que no tienen fondo (eran
// el ruido 3D en z = 1 y z = 3, o sea, ruido 2D).
float brasa_ruido_plano(vec2 x) {
	return textureLod(ruido_brasa, x * (1.0 / 32.0), 0.0).b;
}

// El ruido que SUBE: el dibujo entero viaja hacia arriba, así que una veta que
// nace en el cuerpo acaba saliéndose por la punta. Va estirado en vertical
// (`estira` < 1), porque las vetas de una llama son largas, y un poco
// retorcido, porque no suben derechas. `prisa` deja que cada capa suba a su
// paso: si las dos suben a la vez se ve una textura, no una llama con fondo.
float brasa_veta(vec3 p, float escala, float prisa, float estira) {
	vec3 q = vec3(p.x, p.y * estira, p.z) * escala + vec3(semilla * 7.3, semilla * 3.1, semilla * 5.7);
	q.xz += vec2(sin(p.y * 31.0 + semilla), cos(p.y * 27.0 + semilla * 1.7)) * 0.35;
	q.y -= tiempo * prisa;
	float a = brasa_ruido(q);
	float b = brasa_ruido(q * 2.07 + vec3(5.2, -tiempo * prisa * 0.7, 1.3));
	return a * 0.62 + b * 0.38;
}

// Lo alta que está una altura de reposo dentro de la llama: 0 en el pie, 1 arriba.
float brasa_alto(float y) {
	return clamp((y - pie) / (altura - pie), 0.0, 1.0);
}

// Cuánto queda de las lenguas: 1 ardiendo, 0,4 aturdida (un rescoldo bajo), y
// casi nada al prender. Un fuego que se apaga se achica; no se roe.
float brasa_talla_lenguas() {
	return clamp(0.40 + (vida - 0.24) / 0.76 * 0.60, 0.12, 1.0) + avivar * 0.10;
}

// De la postura de reposo a la de este cuadro. Se mueve lo de ARRIBA: el peso es
// la altura al cuadrado, así que la base y la cara se quedan donde están y las
// puntas son las que bailan y las que se quedan atrás. Antes el arrastre ladeaba
// la llama entera como un sólido —con la cara dentro— y al correr se veían las
// láminas cruzarse y los ojos de canto.
vec3 brasa_mover(vec3 p, vec3 n, float lengua, float fase, float cuanto) {
	float h = brasa_alto(p.y);
	float peso = h * h;
	float punta = lengua * lengua;
	float k = max(punta, peso * 0.5) * cuanto;
	// Apagada, las lenguas se achican hacia el cuerpo: lo de encima de la cara baja
	// y se recoge hacia el eje. Lo de debajo (la cara) no se toca.
	float talla = brasa_talla_lenguas();
	float sobra = max(p.y - encoge_desde, 0.0);
	p.y -= sobra * (1.0 - talla);
	p.xz *= 1.0 - (1.0 - talla) * 0.30 * smoothstep(0.0, 0.6, lengua);
	// El vaivén: una onda que sube por cada lengua, cada una a su fase.
	float f = fase * 6.2831 + semilla * 4.0;
	// Más ancho que al principio (0,020): con tan poco, las lenguas parecían
	// talladas y la llama quieta, una pieza de cerámica (crítica de arte, nov-2026).
	// Y un tercer tirón, rápido y a golpes, que es el lametazo de una llama.
	float a = sin(tiempo * 6.1 - p.y * 23.0 + f);
	float b = sin(tiempo * 9.3 - p.y * 36.0 + f * 2.3 + 1.7);
	float tiron = brasa_ruido_plano(vec2(fase * 7.0 + semilla, tiempo * 4.3 - p.y * 9.0)) - 0.5;
	p += vec3(a * 0.7 + b * 0.3 + tiron * 0.9, 0.0, b * 0.7 - a * 0.3 - tiron * 0.5) * 0.032 * k * vaiven;
	// Cada lengua se estira y se encoge a su aire: el parpadeo de las puntas.
	float late = brasa_ruido_plano(vec2(fase * 13.0 + semilla * 9.0 + 11.0, tiempo * 2.6 + 23.0));
	p.y += (late - 0.40) * 0.12 * punta * cuanto * (0.7 + avivar * 0.9) * talla;
	// El ruido que sube también empuja la piel: arriba mucho, abajo casi nada.
	float hervor = brasa_ruido(vec3(p.x * 19.0, p.y * 12.0 - tiempo * 2.8, p.z * 19.0) + vec3(semilla * 2.0));
	p += n * (hervor - 0.5) * 0.020 * (hervor_base + k);
	// Y se queda atrás cuando el cuerpo se mueve.
	p += arrastre * peso * cuanto;
	return p;
}

// LA TEMPERATURA de un punto, de 0 (punta fría) a 1 (base al blanco). Sale de la
// altura y de lo lengua que es, con el ruido que sube encima: las vetas viajan
// hacia arriba y la frontera entre el naranja y el rojo nunca está quieta.
float brasa_temperatura(float h, float lengua, float veta) {
	// Las vetas pesan más que al principio (0,44): con el degradado casi limpio la
	// melena era un esmalte liso de naranja a rosa.
	float q = 1.04 - 0.78 * h - 0.34 * lengua + (veta - 0.5) * 0.62;
	q += avivar * 0.14 - templado;
	// Apagada, todo el degradado se corre hacia el rojo y el granate.
	q -= (1.0 - vida) * 0.46;
	return q;
}

// Del frío al caliente por los colores del sprite, con pasos ANCHOS: un
// degradado de fuego, no bandas pintadas. Devuelve LUZ (pasa de 1 en la base).
vec3 brasa_color(float q) {
	vec3 c = mix(c_cobre, c_rojo, 0.5);
	c = mix(c, c_rojo, smoothstep(-0.05, 0.18, q));
	c = mix(c, c_rojo_luz, smoothstep(0.10, 0.36, q));
	c = mix(c, c_naranja, smoothstep(0.28, 0.58, q));
	c = mix(c, c_oro, smoothstep(0.50, 0.78, q));
	c = mix(c, c_oro_claro, smoothstep(0.70, 0.94, q));
	// SIN BLANCO (remate, nov-2026). El núcleo pasaba a `c_blanco` y emitía casi
	// al doble: en la MESA (AgX con exposición 1,5 y el brillo) eso salía como un
	// bulbo crema opaco, una lámpara. El sprite tiene el núcleo AMARILLO. Lo más
	// caliente se queda en oro claro, y la saturación lo empuja al amarillo puro.
	// Se le devuelve la saturación que la curva de tono le quita a los naranjas.
	float gris = dot(c, vec3(0.2126, 0.7152, 0.0722));
	c = max(mix(vec3(gris), c, 1.55 + 0.35 * smoothstep(0.55, 0.95, q)), vec3(0.0));
	// La luz: las puntas por debajo de 1 (un rojo claro, con la curva de tono, se
	// va al naranja; solo un rojo OSCURO sigue rojo) y el cuerpo apenas por
	// encima: lo justo para que el núcleo roce el brillo sin quemarse a crema.
	// Antes la base subía a ~2 y era lo que la hacía lámpara.
	float luz = mix(0.50, 0.80, smoothstep(0.08, 0.62, q)) * (1.0 + 0.14 * smoothstep(0.72, 1.12, q));
	// Apagada emite menos: es un rescoldo, no un fuego.
	luz *= mix(0.62, 1.0, smoothstep(0.15, 0.85, vida));
	return c * luz;
}

// El fogonazo AVIVA cada color en vez de taparlo con blanco: el degradado sigue
// ahí, solo que ya pasa de 1 y hace halo. Tapado en blanco, el golpe era un
// borrón sin forma.
vec3 brasa_fogonazo(vec3 col, float cuanto) {
	float g = clamp(golpe, 0.0, 1.0) * cuanto;
	return col * (1.0 + 1.15 * g) + vec3(0.30, 0.20, 0.06) * g;
}
