shader_type spatial;

// CRIPTA 3D · la bola · LA SOMBRA DE CONTACTO.
//
// Compatibility no tiene oclusión de pantalla, y sin ella una bola encima de la
// losa parece pegada al cristal de la cámara: no se sabe si está en el suelo o
// volando. Esto es un disco oscuro y difuso, pegado al suelo debajo de la bola,
// que la POSA. Se apaga solo a medida que la bola sube (una caída, un raíl).
//
// Negro con transparencia. *Probado y quitado:* multiplicar lo de debajo
// (`blend_mul`); en Compatibility salía el cuadrado entero oscuro.

render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

// 0 = no se ve, 1 = la sombra entera.
uniform float fuerza = 1.0;
// Cuánto oscurece el centro (0 = nada, 1 = negro).
uniform float hondo = 0.82;

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	// Dos caídas: un núcleo apretado justo debajo (el contacto) y una penumbra
	// ancha. Con una sola, o es un punto o es una mancha.
	float nucleo = 1.0 - smoothstep(0.0, 0.42, r);
	float penumbra = 1.0 - smoothstep(0.15, 1.0, r);
	float oscuro = clamp((nucleo * 0.75 + penumbra * penumbra * 0.5) * hondo * fuerza, 0.0, 0.95);
	ALBEDO = vec3(0.0);
	ALPHA = oscuro;
}
