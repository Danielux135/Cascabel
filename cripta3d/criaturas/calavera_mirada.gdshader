shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled;

// CRIPTA — la mirada de la calavera: un punto de luz FRÍA y muy tenue en el fondo
// de cada cuenca, que sigue a la bola. El sprite no lleva brillos —es hueso y
// sombra—, así que esto es lo justo para que la cuenca mire: una mota con el
// centro encendido y el borde deshecho, no una bombilla. Con `fuerza` a 1 no
// llega al umbral del brillo de la cripta; solo lo pasa cuando se asusta.

uniform vec3 color : source_color = vec3(0.50, 0.68, 0.95);
uniform float fuerza = 1.0;

void fragment() {
	float f = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float nucleo = pow(f, 9.0);
	float halo = pow(f, 2.5) * 0.16;
	ALBEDO = color * (nucleo * 0.95 + halo) * fuerza;
}
