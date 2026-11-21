shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled,
	skip_vertex_transform, fog_disabled;

// CRIPTA 3D · «atrezzo» · LA LLAMA de antorchas, braseros y velas.
//
// Una llama no es un cono ni un sprite que da vueltas: es un gas que SUBE. Aquí
// es una lámina que mira a la cámara (girando solo alrededor de la vertical,
// para que la llama siga de pie aunque la cámara mire desde arriba), y todo lo
// que se ve sale del fragmento:
//   - el perfil de lágrima, redondo abajo y en punta arriba;
//   - dos ruidos que suben a distinta prisa y TUERCEN la lágrima (más cuanto
//     más arriba: la base está quieta, la punta baila);
//   - el segundo ruido además MUERDE la parte de arriba, que se rompe en
//     lenguas que se sueltan;
//   - y cuatro capas de color por «densidad»: borde rojo, cuerpo naranja,
//     corazón oro y un núcleo casi blanco que solo vive en la mitad de abajo.
// Va SIEMPRE en un MultiMesh: el dato propio de cada instancia (x) es su fase,
// para que dos llamas vecinas no bailen a la vez, (y) cuánto se aviva y (z)
// cuánto está apagada (los cirios de la carga de la campana).
// Suma luz (blend_add) y no escribe profundidad: el brillo de la escena hace el
// halo. La luz de verdad la pone `mundo.luz_fuego`.

uniform sampler2D tex_ruido : filter_linear_mipmap, repeat_enable;
uniform vec3 color_borde : source_color = vec3(0.55, 0.10, 0.04);
uniform vec3 color_cuerpo : source_color = vec3(1.0, 0.38, 0.08);
uniform vec3 color_corazon : source_color = vec3(1.0, 0.72, 0.30);
uniform vec3 color_nucleo : source_color = vec3(1.0, 0.93, 0.75);
uniform float energia = 2.4;
uniform float prisa = 1.0;
// Cuánto se acorta vista desde arriba: desde la cenital, una llama alta parece
// una raya clavada en el suelo.
uniform float acorta_arriba = 0.55;

varying float v_fase;
varying float v_aviva;
varying float v_viva;

void vertex() {
	vec3 centro = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	v_fase = INSTANCE_CUSTOM.x;
	v_aviva = INSTANCE_CUSTOM.y;
	// (z) cuánto está APAGADA: 0 arde entera, 1 no está. Va al revés para que
	// lo que no dice nada (0) arda: así solo la mueve quien la quiere apagar.
	v_viva = 1.0 - clamp(INSTANCE_CUSTOM.z, 0.0, 1.0);
	float ancho = length(MODEL_MATRIX[0].xyz) * mix(0.35, 1.0, v_viva);
	float alto = length(MODEL_MATRIX[1].xyz) * v_viva;
	vec3 a_cam = normalize(INV_VIEW_MATRIX[3].xyz - centro);
	// El lado: horizontal y de cara a la cámara. Mirando desde encima, el lado
	// horizontal no existe y se coge el de la cámara.
	vec3 lado = cross(vec3(0.0, 1.0, 0.0), a_cam);
	float de_lado = length(lado);
	lado = normalize(mix(INV_VIEW_MATRIX[0].xyz, lado / max(de_lado, 1e-4), smoothstep(0.08, 0.3, de_lado)));
	vec3 sube = normalize(cross(a_cam, lado));
	// Respira: se estira y se encoge con dos senos de periodo raro.
	float t = TIME * prisa;
	float resp = 1.0 + 0.09 * sin(t * 7.3 + v_fase * 11.0) + 0.06 * sin(t * 13.1 + v_fase * 5.0)
			+ v_aviva * 0.5;
	float h = alto * resp * mix(acorta_arriba, 1.0, smoothstep(0.15, 0.6, de_lado));
	vec3 p = centro + lado * VERTEX.x * ancho * (1.0 + v_aviva * 0.25) + sube * VERTEX.y * h;
	VERTEX = (VIEW_MATRIX * vec4(p, 1.0)).xyz;
	NORMAL = normalize((VIEW_MATRIX * vec4(a_cam, 0.0)).xyz);
}

void fragment() {
	float x = UV.x * 2.0 - 1.0;
	float y = UV.y;
	float t = TIME * prisa;
	// Los dos ruidos que suben: uno grande y lento, otro fino y rápido.
	float n1 = texture(tex_ruido, vec2(UV.x * 0.55 + v_fase, y * 0.55 - t * 0.85)).r;
	float n2 = texture(tex_ruido, vec2(UV.x * 1.4 - v_fase * 0.7, y * 1.3 - t * 1.9)).g;
	float n3 = texture(tex_ruido, vec2(UV.x * 2.6 + v_fase * 0.3, y * 2.2 - t * 3.1)).b;
	// Se tuerce: abajo quieta, arriba baila.
	float meneo = (n1 - 0.5) * 0.75 * y * y + sin(t * 2.7 + v_fase * 6.0) * 0.10 * y * y
			+ (n3 - 0.5) * 0.18 * y;
	float xx = x - meneo;
	// La lágrima: lo ancha que es la llama a cada altura (1 = el borde de la lámina).
	float ancho = 1.85 * sqrt(max(y, 0.0)) * pow(max(1.0 - y, 0.0), 0.95);
	float d = 1.0 - abs(xx) / max(ancho, 0.001);
	// Las lenguas: el ruido fino se come la mitad de arriba.
	d -= (1.0 - n2) * smoothstep(0.25, 1.0, y) * 0.95;
	d -= (1.0 - n3) * 0.25 * y;
	d = clamp(d, 0.0, 1.0);
	float cuerpo = smoothstep(0.0, 0.32, d);
	// El núcleo, abajo y en el centro: es lo que la hace fuego y no humo naranja.
	float nucleo = smoothstep(0.45, 0.92, d) * (1.0 - smoothstep(0.15, 0.6, y));
	vec3 c = mix(color_borde, color_cuerpo, smoothstep(0.05, 0.45, d));
	c = mix(c, color_corazon, smoothstep(0.35, 0.8, d) * (1.0 - 0.5 * y));
	c = mix(c, color_nucleo, nucleo);
	// La punta se enfría y se apaga antes que el borde.
	float apaga = 1.0 - smoothstep(0.55, 1.0, y) * 0.55;
	ALBEDO = c * energia * (1.0 + v_aviva * 1.5) * apaga;
	ALPHA = cuerpo * smoothstep(0.0, 0.25, v_viva);
}
