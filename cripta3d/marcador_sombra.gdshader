shader_type canvas_item;

// LA SOMBRA DEL MARCADOR: una penumbra blanda detrás de cada bloque de texto, en
// vez de una caja. El marcador va encima de una imagen con fuego y con negro de
// verdad, y una caja opaca la tapa; esto solo oscurece lo justo para que la
// letra se lea, y se apaga en unos treinta píxeles sin dejar borde.
//
// `cajas` son rectángulos en píxeles del lienzo (x, y, ancho, alto) y `fuerzas`
// lo oscura que es cada una (0 = no está). Las rellena `marcador.gd` cada
// fotograma, porque los bloques crecen, encogen y aparecen.

uniform vec2 tam = vec2(960.0, 540.0);
uniform vec4 cajas[8];
uniform float fuerzas[8];
uniform float pluma = 30.0;

float distancia_caja(vec2 p, vec4 c) {
	vec2 centro = c.xy + c.zw * 0.5;
	vec2 d = abs(p - centro) - c.zw * 0.5;
	return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}

void fragment() {
	vec2 p = UV * tam;
	float a = 0.0;
	for (int i = 0; i < 8; i++) {
		if (fuerzas[i] <= 0.0) {
			continue;
		}
		float d = max(distancia_caja(p, cajas[i]), 0.0) / pluma;
		a = max(a, exp(-d * d * 2.2) * fuerzas[i]);
	}
	// Un grano de un nivel de color: sin él, un degradado tan oscuro y tan
	// suave se ve a escalones.
	float g = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453);
	a = clamp(a + (g - 0.5) / 255.0, 0.0, 1.0);
	COLOR = vec4(0.0, 0.0, 0.0, a);
}
