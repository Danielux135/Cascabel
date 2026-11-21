shader_type spatial;
render_mode blend_add, depth_draw_never, cull_back, unshaded, fog_disabled;

// CRIPTA — la LUZ VIOLETA que el espectro echa en la losa, y la que se le ve
// cuando va por dentro de la catacumba.
//
//   · `charco`: un poco de luz bajo él, que se suma a la de su OmniLight. La
//     luz de verdad alumbra la piedra con su relieve; esto solo le da cuerpo
//     al centro, donde la luz omni cae de canto.
//   · `filtra`: ESCONDIDO no se le ve; solo una luz que corre POR DEBAJO del
//     suelo y se cuela por las grietas y las juntas de las losas. Las grietas
//     van en coordenadas de MUNDO, así que la luz pasa por debajo de ellas
//     como una linterna bajo un entarimado, en vez de llevarlas pegadas.

uniform vec3 color : source_color = vec3(0.66, 0.48, 0.85);
uniform float charco = 0.0;
uniform float filtra = 0.0;
uniform float reloj = 0.0;
uniform float semilla = 0.0;

varying vec3 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float azar2(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float ruido2(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(azar2(i), azar2(i + vec2(1.0, 0.0)), f.x),
		mix(azar2(i + vec2(0.0, 1.0)), azar2(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Grietas: el ruido "con cresta" (1 − |2n − 1|) afilado deja líneas finas.
// Finas y pocas: con más, la mancha entera era una red de relámpagos (neón).
float grietas(vec2 p) {
	float n1 = 1.0 - abs(ruido2(p * 8.0) * 2.0 - 1.0);
	float n2 = 1.0 - abs(ruido2(p * 19.0 + 4.3) * 2.0 - 1.0);
	return pow(n1, 16.0) * 0.8 + pow(n2, 22.0) * 0.35;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float suave = exp(-r * r * 4.5);

	float c = charco * suave * 0.22;

	// Escondido: un resplandor difuso por las juntas y las grietas, que late.
	vec2 w = mundo.xz;
	float junta = grietas(w + vec2(semilla));
	float late = 0.75 + 0.25 * sin(reloj * 3.3) * sin(reloj * 1.7 + 1.0);
	float f = filtra * (exp(-r * r * 7.0) * 0.16 + junta * exp(-r * r * 6.5) * 0.50) * late;

	ALBEDO = color * (c + f);
	ALPHA = 1.0;
}
