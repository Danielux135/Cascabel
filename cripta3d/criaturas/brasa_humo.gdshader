shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// CRIPTA 3D — BRASA: el HUMO de cuando se queda casi apagada. Unas pocas volutas
// pequeñas, grises y cálidas, de cara a la cámara y con el borde roído por un
// ruido: un hilo de humo de brasero, no una nube.
//
// De la partícula solo se usa la TRANSPARENCIA (COLOR.a) y la edad; el gris va
// aquí, por lo mismo que en las pavesas: el color de una partícula no llega
// igual en los dos motores.

uniform vec3 color : source_color = vec3(0.48, 0.46, 0.41);

varying float opaco;
varying float edad;
varying vec2 azar_p;

float azar2(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float ruido2(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(azar2(i), azar2(i + vec2(1.0, 0.0)), f.x),
		mix(azar2(i + vec2(0.0, 1.0)), azar2(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	opaco = COLOR.a;
	edad = INSTANCE_CUSTOM.y;
	azar_p = MODEL_MATRIX[3].xz * 37.0;
	// De cara a la cámara, conservando el tamaño de la partícula.
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s,
		INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float n = ruido2(p * 2.4 + azar_p + vec2(0.0, edad * 1.5));
	float n2 = ruido2(p * 5.5 - azar_p);
	float cuerpo = 1.0 - smoothstep(0.25, 0.95, r + (n - 0.5) * 0.75 + (n2 - 0.5) * 0.22);
	ALBEDO = color * (0.75 + 0.5 * n);
	ALPHA = cuerpo * opaco;
}
