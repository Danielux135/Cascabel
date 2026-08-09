shader_type canvas_item;

// Destello blanco al recibir daño y disolución píxel a píxel al morir.
//
// La disolución sortea por TEXEL DEL SPRITE, no por píxel de pantalla: se
// cuantiza la UV a la rejilla de la textura antes de sortear. Si se sorteara
// por píxel de pantalla, al escalar el sprite se verían medios píxeles
// desaparecer y el pixelart se rompería.

uniform float destello : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color_destello : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float disolucion : hint_range(0.0, 1.0) = 0.0;
uniform float borde_disolucion : hint_range(0.0, 1.0) = 0.14;
uniform vec4 color_borde : source_color = vec4(0.91, 0.51, 0.29, 1.0);

// Tamaño de la textura en texels. Lo pone el código al asignar el sprite.
uniform vec2 tam_textura = vec2(96.0, 96.0);

float sorteo(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.01) {
		discard;
	}

	float umbral = sorteo(floor(UV * tam_textura));
	if (disolucion > 0.0) {
		if (umbral < disolucion) {
			discard;
		}
		// los que están a punto de irse se encienden primero
		if (umbral < disolucion + borde_disolucion) {
			c.rgb = mix(c.rgb, color_borde.rgb, 0.85);
		}
	}

	c.rgb = mix(c.rgb, color_destello.rgb, destello);
	COLOR = c;
}
