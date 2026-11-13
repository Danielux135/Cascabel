shader_type sky;

// ÓRBITA — el fondo: una nebulosa con estrellas, y encima de todo un foco que
// la cámara nunca ve y que existe para que el cromo tenga algo que reflejar.
// No usa TIME a propósito: así el mapa de reflejos se calcula una sola vez.
//
// LA NEBULOSA NO SE CALCULA AQUÍ: viene pintada en `nebulosa`, que la dibuja
// `nebulosa.gdshader` una sola vez al arrancar. Aquí solo se lee. Lo que sí se
// sigue calculando es lo barato y lo que tiene que salir nítido: las estrellas
// y los dos focos.

uniform sampler2D nebulosa : filter_linear, repeat_enable;
// No pinta nada: `mundo_orbita.gd` la cambia cuando la nebulosa ya está pintada,
// que es lo que le dice al motor que rehaga el mapa de reflejos del cromo.
uniform float horneada = 0.0;

float azar(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 d = normalize(EYEDIR);
	// La misma vuelta con la que se pintó: longitud a lo ancho, latitud a lo
	// alto. Los polos se sujetan a medio píxel del borde para que el de arriba
	// no se mezcle con el de abajo al filtrar.
	vec2 uv = vec2(atan(d.x, d.z) / 6.2831853 + 0.5,
		clamp(0.5 - asin(clamp(d.y, -1.0, 1.0)) / 3.14159265, 0.0005, 0.9995));
	vec3 col = pow(textureLod(nebulosa, uv, 0.0).rgb, vec3(2.2)) + horneada * 0.0;
	vec3 c = d * 150.0;
	vec3 celda = floor(c);
	float h = azar(celda);
	float punto = smoothstep(0.30, 0.0, length(fract(c) - 0.5));
	col += vec3(0.85, 0.92, 1.0) * step(0.990, h) * punto * (0.5 + 3.0 * azar(celda + 7.0));
	float foco = smoothstep(0.90, 0.99, d.y);
	col += vec3(1.1, 1.3, 1.6) * foco;
	float lateral = smoothstep(0.10, 0.0, abs(d.y - 0.35)) * smoothstep(0.3, 0.8, abs(d.x));
	col += vec3(0.6, 0.15, 0.45) * lateral;
	COLOR = col;
}
