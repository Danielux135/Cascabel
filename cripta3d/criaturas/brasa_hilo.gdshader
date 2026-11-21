shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// CRIPTA 3D — BRASA: el HILO entre las dos ascuas de una brasa partida. Es lo que
// dice, sin una palabra, que las dos son UNA que se ha roto y que se van a juntar:
// un hilo de chispas que corre de una a otra y que se TENSA —más fino, más
// brillante, más deprisa— cuanto más cerca están. Sin él, al partirla se veían dos
// brasas sueltas (crítica de juego, nov-2026).
//
// La malla es un cilindro fino a lo largo de su Y (de 0 a 1 = de un ascua a la
// otra); aquí se pinta un reguero de motas que viajan en los dos sentidos.

uniform vec3 color : source_color = vec3(0.91, 0.51, 0.29);
uniform vec3 color_vivo : source_color = vec3(0.97, 0.85, 0.42);
uniform float tension = 0.0;   // 0 lejos, 1 a punto de juntarse
uniform float fuerza = 1.0;    // 0 apagado
uniform float largo = 1.0;     // en unidades, para que las motas no se estiren

varying float u;

void vertex() {
	u = VERTEX.y + 0.5;
}

void fragment() {
	float t = TIME * (2.0 + 4.0 * tension);
	float n = largo * 26.0;
	// Dos trenes de motas, uno en cada sentido: el fuego va de una a otra.
	float ida = fract(u * n - t);
	float vuelta = fract(u * n * 0.73 + t * 0.8 + 0.37);
	float motas = max(1.0 - smoothstep(0.0, 0.28, abs(ida - 0.5)),
		(1.0 - smoothstep(0.0, 0.22, abs(vuelta - 0.5))) * 0.7);
	// Un hilo de fondo, que con la tensión se hace continuo.
	float hilo = 0.18 + 0.50 * tension;
	// Las puntas se apagan: el hilo nace DENTRO de cada ascua.
	float puntas = smoothstep(0.0, 0.12, u) * smoothstep(1.0, 0.88, u);
	float parpadeo = 0.75 + 0.25 * sin(TIME * 31.0 + u * 40.0);
	float k = max(motas, hilo) * puntas * parpadeo * fuerza;
	ALBEDO = mix(color, color_vivo, tension * 0.7 + motas * 0.3) * k * (0.9 + 1.3 * tension);
}
