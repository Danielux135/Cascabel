shader_type spatial;
// LUZ POR VÉRTICE (21-nov-2026, para la web). Con la luz entera de Godot este
// sombreador tardaba 5,5–5,7 s en compilar con ANGLE, en frío; por vértice, 1,0.
// Apagada, la cenefa es bronce oscuro que alumbran los braseros de debajo, y eso
// sigue: la malla da 32 lados por vuelta (6 cm en una campana de 30 de radio) y
// las luces están a medio metro o más, así que la luz por vértice no se nota a
// facetas. Lo que cambia es la forma del brillo: Blinn por vértice en vez de GGX
// por píxel, más ancho y más flojo; encendida, la cenefa es casi toda EMISSION,
// que no depende de la luz. Y apagada, el filo de bronce de su canto no salía
// por vértice: se pinta a mano (ver `fuego_a`). Con él, 1,15 s con ANGLE (límite 1,4; sin él, 1,23).
render_mode vertex_lighting;

// CRIPTA 3D · «atrezzo» · LAS CENEFAS DE LA CAMPANA MAYOR.
//
// Lo que se enciende en el surco de cada cenefa: la barra de carga de la mesa.
// Es una BANDA CONTINUA Y LISA de ámbar, de ORO_OSCURO a ORO, que solo cambia de
// INTENSIDAD (la carga, el latido de armada, el golpe del badajo).
//
// POR QUÉ NO ES EL «ASCUA» DE LA BIBLIOTECA (último retoque, 21-nov-2026). Las
// cenefas llevaban una copia del ascua con su paleta bajada a ámbar, y armadas
// salían con un estampado de jirafa —el craquelado negro de las placas de costra
// y sus grietas encendidas, con el hervor corriendo en diagonal por encima— en
// tonos crema y rosa: lo caliente de cada mancha se quemaba a blanco con la curva
// de tono. Desde la RASANTE, a 30 px, eso se leía como una cinta de obra amarilla
// y negra a bloques. Un brasero es carbón y tiene costra; un surco de metal
// fundido no. Aquí no hay ni una lectura de textura: ni costra, ni grietas, ni
// ruido de alto contraste.
//
// Lo único que modela la banda (para que tenga volumen y no sea una pegatina) es
// de bajo contraste y no cambia el tono: un pelo más apagada en los bordes del
// surco (la oclusión horneada, canal R del color de vértice) y hacia lo que no
// mira a la cámara.

// Lo frío y lo caliente de la banda: `calor` va de uno a otro. Nunca más claro
// que ORO: con ORO_CLARO la curva de tono ya lo lleva a crema.
uniform vec3 color_bajo : source_color = vec3(0.541, 0.396, 0.141);
uniform vec3 color_alto : source_color = vec3(0.878, 0.651, 0.235);
// El surco apagado: bronce oscuro, que es lo que se ve sin carga.
uniform vec3 color_apagado : source_color = vec3(0.16, 0.11, 0.05);
// Cuánto arde (lo anima `atrezzo.gd`), y de qué color, 0..1.
uniform float energia = 0.0;
uniform float calor = 0.5;
// El techo de la luz: con `energia` 1 la banda da esto por canal (en lineal).
// Por encima de ~1 la curva de tono empieza a llevar el ámbar a blanco.
uniform float brillo = 0.85;

// EL FILO DE LA CINTA APAGADA, A MANO. Con la luz por píxel, el fuego de la
// esquina izquierda (a un lado de la campana, casi a su altura) dejaba un brillo
// de bronce en la mitad de abajo de la cinta, por el lado que lo mira: medido en
// sala/01_abside (x 690–725), de 15 a 38 de rojo hacia el canto. Por vértice no
// sale NADA (0–2: la cinta, una franja negra lisa que parecía 2–4 px más gruesa),
// y ni subiendo la rugosidad del vértice a 0,62 o 0,75 vuelve. Así que se pinta:
// el reflejo de los dos fuegos de las esquinas (`atrezzo.gd` pone dónde están;
// los de aquí son los de la mesa de hoy), con su caída por distancia, que es la
// que deja el de la derecha casi sin brillo, como antes.
// *Ojo:* SIN el N·L. Con él no sale nada: las normales de esta cinta no miran
// hacia fuera (con −N tampoco), y por eso la luz por vértice la deja a cero.
// Medido en la misma caja (mediana de rojo, cinta de arriba / de abajo): gira5
// 21 / 25, la luz por píxel con las luces de hoy 18 / 17, gira6 1 / 1, y esto
// 19 / 28 (con `canto` 0,7 se quedaba en 9 / 14).
uniform vec3 fuego_a = vec3(0.16, 1.49, 7.28);
uniform vec3 fuego_b = vec3(3.84, 1.49, 7.28);
uniform float alcance_fuego = 2.4;
uniform vec3 color_canto : source_color = vec3(1.0, 0.62, 0.34);
uniform float canto = 1.0;
uniform float canto_apretado = 8.0;

varying float v_oclu;

// El brillo de un fuego en `p` (espacio de vista): lóbulo de reflejo y la caída
// de una omni de Godot, (1 − (d/alcance)⁴)² / d².
float de_un_fuego(vec3 p, vec3 v, vec3 r) {
	vec3 d = p - v;
	float dist = length(d);
	float x = dist / alcance_fuego;
	float a = clamp(1.0 - x * x * x * x, 0.0, 1.0);
	return pow(max(dot(r, d / dist), 0.0), canto_apretado) * a * a / (dist * dist);
}

void vertex() {
	v_oclu = COLOR.r;
	// Con luz por vértice la rugosidad del brillo se lee AQUÍ: la de `fragment`
	// ya no llega a la luz directa (sin esto valdría 1 y no habría brillo).
	ROUGHNESS = 0.5;
}

void fragment() {
	float hacia = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float forma = mix(0.78, 1.0, hacia) * mix(0.72, 1.0, clamp(v_oclu, 0.0, 1.0));
	vec3 c = mix(color_bajo, color_alto, clamp(calor, 0.0, 1.0));
	ALBEDO = color_apagado;
	METALLIC = 0.7;
	ROUGHNESS = 0.5;
	AO = clamp(v_oclu, 0.0, 1.0);
	vec3 r = reflect(-VIEW, NORMAL);
	float filo = de_un_fuego((VIEW_MATRIX * vec4(fuego_a, 1.0)).xyz, VERTEX, r)
		+ de_un_fuego((VIEW_MATRIX * vec4(fuego_b, 1.0)).xyz, VERTEX, r);
	EMISSION = c * (max(energia, 0.0) * brillo * forma) + color_canto * (canto * filo);
}
