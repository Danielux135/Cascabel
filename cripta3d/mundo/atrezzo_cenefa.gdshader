shader_type spatial;

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

varying float v_oclu;

void vertex() {
	v_oclu = COLOR.r;
}

void fragment() {
	float hacia = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float forma = mix(0.78, 1.0, hacia) * mix(0.72, 1.0, clamp(v_oclu, 0.0, 1.0));
	vec3 c = mix(color_bajo, color_alto, clamp(calor, 0.0, 1.0));
	ALBEDO = color_apagado;
	METALLIC = 0.7;
	ROUGHNESS = 0.5;
	AO = clamp(v_oclu, 0.0, 1.0);
	EMISSION = c * (max(energia, 0.0) * brillo * forma);
}
