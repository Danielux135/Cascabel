shader_type spatial;

// CRIPTA 3D · efectos · LO QUE ARDE Y VUELA: chispas de hierro, pavesas y motas.
//
// Un solo sombreador para todo lo pequeño que da luz, en dos formas:
//   forma 0  RAYA: una chispa de hierro. La malla es una cruz de dos tiras a lo
//            largo de Y, y la partícula alinea su Y con la velocidad
//            (`particle_flag_align_y`), así que se estira hacia donde vuela.
//            UV.y = 0 es la cabeza (lo más caliente), 1 la cola.
//   forma 1  PUNTO: una pavesa o una mota, que mira siempre a la cámara.
// El color y lo que le queda de vida vienen en COLOR (la rampa de la partícula:
// del blanco amarillo al rojo apagado). `energia` lo sube por encima de 1 para
// que el brillo de pantalla lo coja: es lo único de la cripta que debe cogerlo,
// junto con el fuego y los ojos.

render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform int forma = 0;
uniform float energia = 3.0;
// Solo en la forma 1: cuánto halo blando lleva el punto alrededor del núcleo.
// *Probado y quitado:* 0,5 para todo. Con el brillo de pantalla, cada pavesa
// era un disco blanco desenfocado (un «bokeh») que competía con el polvo del
// rayo de luna; una pavesa es un punto, y el halo grande se queda para la magia.
uniform float halo = 0.5;

void vertex() {
	if (forma == 1) {
		// Cara a la cámara, conservando el tamaño de la partícula (lo mismo que
		// hace el material estándar con «billboard» de partículas).
		mat4 mv = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
				INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		mv = mv * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
				vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
				vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
				vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_MATRIX = mv;
	}
}

void fragment() {
	float a;
	if (forma == 0) {
		float x = abs(UV.x - 0.5) * 2.0;
		a = (1.0 - x * x) * pow(1.0 - UV.y, 1.6);
	} else {
		float r = length(UV - vec2(0.5)) * 2.0;
		float nucleo = 1.0 - smoothstep(0.0, 0.35, r);
		float blando = pow(max(1.0 - r, 0.0), 2.5);
		a = nucleo * 0.7 + blando * halo;
	}
	ALBEDO = COLOR.rgb * a * energia * COLOR.a;
}
