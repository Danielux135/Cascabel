shader_type spatial;

// CRIPTA 3D · la bola · EL BARRIDO: lo que deja en el ojo una bola muy rápida.
//
// No es una cinta de luz (eso era ÓRBITA): es el emborronado de un metal que
// refleja fuego, así que es tenue, ancho como la bola, se deshace por los bordes
// y por la cola, y solo existe a mucha velocidad. El color y la fuerza vienen en
// el color de vértice (`bola.gd`); UV.x va de un borde al otro, UV.y de la bola
// (0) a la cola (1).

render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

void fragment() {
	float x = abs(UV.x - 0.5) * 2.0;
	// El borde se deshace: un emborronado no tiene canto.
	float ancho = 1.0 - smoothstep(0.15, 1.0, x);
	// Una veta a lo largo: el reflejo del fuego corriendo por la bola deja rayas.
	float vetas = 0.75 + 0.25 * sin(UV.x * 18.0 + UV.y * 2.0);
	float cola = 1.0 - UV.y;
	ALBEDO = COLOR.rgb * ancho * ancho * vetas * cola * cola * COLOR.a;
}
