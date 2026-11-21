shader_type spatial;

// CRIPTA 3D · efectos · EL POLVO DE PIEDRA: la bocanada que suelta un golpe
// contra un sillar, una lápida que se hunde o una bola que cae a la losa.
//
// Es polvo y no luz: se ILUMINA (la llama de un brasero lo pone naranja, la
// luz de la propia bola lo enciende junto a la pared, y en lo oscuro casi no
// se ve, que es como se ve el polvo). Una mancha de ruido y no un círculo: cada
// bocanada coge un trozo distinto de `ruido_manchas.png` según el ángulo de su
// partícula (INSTANCE_CUSTOM.x), y se va deshaciendo con la edad (.y).
//
// Se SUMA (como la onda): en la penumbra, mezclado, el polvo iluminado salía
// como una mancha negra.

render_mode blend_add, depth_draw_never, cull_disabled, shadows_disabled, diffuse_lambert_wrap, specular_disabled;

uniform sampler2D tex_manchas : filter_linear_mipmap, repeat_enable;
uniform float opacidad = 0.55;

varying float v_semilla;
varying float v_edad;

void vertex() {
	mat4 mv = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
			INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	mv = mv * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = mv;
	v_semilla = INSTANCE_CUSTOM.x;
	v_edad = INSTANCE_CUSTOM.y;
}

void fragment() {
	vec2 c = UV - vec2(0.5);
	float r = length(c) * 2.0;
	float giro = v_semilla;
	vec2 q = mat2(vec2(cos(giro), sin(giro)), vec2(-sin(giro), cos(giro))) * c;
	vec2 sitio = vec2(fract(v_semilla * 0.731), fract(v_semilla * 0.377));
	float n1 = texture(tex_manchas, q * 0.55 + sitio).r;
	float n2 = texture(tex_manchas, q * 1.4 + sitio.yx + vec2(v_edad * 0.15)).r;
	float nube = smoothstep(0.25, 0.8, n1 * 0.65 + n2 * 0.45);
	// Se abre y se deshace: al principio es un bulto denso, al final jirones.
	float borde = 1.0 - smoothstep(0.35 - v_edad * 0.2, 1.0, r);
	float vida = smoothstep(0.0, 0.08, v_edad) * (1.0 - smoothstep(0.35, 1.0, v_edad));
	ALBEDO = COLOR.rgb;
	ALPHA = clamp(borde * mix(0.35, 1.0, nube) * (nube * 0.6 + 0.4) * vida * opacidad * COLOR.a, 0.0, 1.0);
	ROUGHNESS = 1.0;
	// Mira a la cámara, pero la luz que viene de arriba también la toca.
	NORMAL = normalize(mix(NORMAL, (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz, 0.4));
}
