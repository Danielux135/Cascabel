// CRIPTA 3D · la ESTELA de las palas (módulo «piezas»).
//
// No es una superficie de la mesa —esas salen todas de la biblioteca—: es el
// rastro que deja la pala al barrer su recorrido en tres cuadros, lo que hace
// que el golpe se VEA en vez de que la pala salte de un sitio a otro.
//
// Es humo de hierro, no neón: color de acero oscuro, mezclado (no sumado) y
// muy transparente. Lo único que brilla un poco es la punta, que es donde va
// más deprisa y donde la luz del fuego le saca un filo.
//
// UV.x: de la cola del barrido (0) a donde está la pala ahora (1).
// UV.y: del eje (0) a la punta (1).
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 color_humo : source_color = vec3(0.26, 0.25, 0.27);
uniform vec3 color_filo : source_color = vec3(0.86, 0.66, 0.42);
uniform float opacidad = 0.42;

void fragment() {
	// Más denso junto a la pala y hacia la punta; se deshace hacia la cola y
	// hacia el eje, donde la pala apenas se mueve.
	float hacia_pala = smoothstep(0.0, 1.0, UV.x);
	float hacia_punta = smoothstep(0.15, 0.95, UV.y);
	float a = hacia_pala * hacia_pala * hacia_punta * opacidad;
	// El filo: una raya fina en la punta del barrido.
	float filo = smoothstep(0.86, 0.99, UV.y) * hacia_pala;
	ALBEDO = mix(color_humo, color_filo, filo * 0.7);
	ALPHA = clamp(a + filo * 0.25, 0.0, 0.7);
}
