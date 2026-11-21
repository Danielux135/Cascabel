shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, fog_disabled;

// CRIPTA — una voluta del humo del espectro: el rastro que deja, el humo del que
// cuaja al aparecer y los fuegos fatuos de cuando está aturdido. Una tarjeta que
// mira a la cámara, con la redondez y las hebras calculadas aquí.
//
// Sin textura a propósito: con un `GradientTexture2D` redondo y el modo
// «billboard de partículas» de StandardMaterial3D, las volutas salían como
// CUADRADOS blancos (19-nov-2026). Aquí no hay nada que cargar ni que filtrar.
//
// Suma luz (blend_add) y poca: el humo de un espectro alumbra, no tapa.

uniform vec3 color : source_color = vec3(0.66, 0.48, 0.85);
uniform float fuerza = 0.25;
uniform float hebras = 1.0;
// 1 = tarjeta de partícula (la orienta su instancia), 0 = MeshInstance suelta.
uniform float particula = 1.0;

varying float azar;

void vertex() {
	// Mirando a la cámara, conservando la escala de la partícula.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	azar = fract(sin(dot(MODEL_MATRIX[3].xyz, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = fract(sin(dot(i, vec2(12.9898, 78.233))) * 43758.5453);
	float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(12.9898, 78.233))) * 43758.5453);
	float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(12.9898, 78.233))) * 43758.5453);
	float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(12.9898, 78.233))) * 43758.5453);
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float suave = exp(-r * r * 3.2) * (1.0 - smoothstep(0.75, 1.0, r));
	// Hebras: el borde de la voluta se deshilacha (cada una a su manera).
	float h = ruido(p * 3.5 + azar * 17.0) * 0.6 + ruido(p * 8.0 - azar * 9.0) * 0.4;
	suave *= mix(1.0, smoothstep(0.15, 0.75, h + (1.0 - r) * 0.5), hebras);
	vec4 col = mix(vec4(1.0), COLOR, particula);
	ALBEDO = color * col.rgb * col.a * suave * fuerza;
}
