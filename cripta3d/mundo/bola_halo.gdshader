shader_type spatial;

// CRIPTA 3D · la bola · EL HALO DE LA CRIATURA.
//
// «Espectro en la bola, llévalo a una pala» es una orden de juego, y desde la
// cámara de juego la bola con criatura casi no se distinguía de la vacía: la
// ranura encendida mide dos píxeles de alto a 30 px de bola. Esto es un halo
// CORTO del color de la criatura alrededor de la silueta (sale un 40 % del
// radio, no más): se lee a 25 px y no tapa nada. Es una cara que mira a la
// cámara, puesta en el centro de la bola; la propia bola tapa el medio, así que
// solo asoma el aro.
//
// Solo se enciende con criatura (`bola.gd` le pone `fuerza` 0 si no) y late.

render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 color : source_color = vec3(0.66, 0.48, 0.85);
uniform float fuerza = 0.0;
// Dónde acaba la bola dentro del cuadro (radio de la bola / medio lado).
uniform float borde_bola = 0.42;

void vertex() {
	mat4 mv = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
			INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	mv = mv * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = mv;
}

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	// Pegado a la silueta y cayendo deprisa hacia fuera.
	float fuera = clamp((r - borde_bola) / (1.0 - borde_bola), 0.0, 1.0);
	float a = (1.0 - smoothstep(0.0, 1.0, fuera));
	a = a * a * step(borde_bola * 0.7, r);
	ALBEDO = color * a * fuerza;
}
