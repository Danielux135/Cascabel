shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, specular_disabled, shadows_disabled;

// CRIPTA 3D — LA BRUMA DEL SUELO DE LA NAVE. Sábanas de niebla tendidas a ras
// del suelo que rodea la mesa, a dos alturas, que se mueven despacio y en
// sentidos distintos: es lo que hace que los laterales tengan capas en vez de
// ser un suelo liso que se oscurece.
//
// La niebla de profundidad del `Environment` ya oscurece y funde; esto pone
// TEXTURA y LUZ: la bruma recibe las luces de verdad con un `light()` propio que
// no mira hacia dónde da la cara (la niebla no tiene cara: dispersa), así que al
// lado de un fuego se enciende naranja y bajo la luna se queda fría. Sin motivo,
// no brilla.
//
// Se funde con lo que atraviesa de DOS maneras, y hacen falta las dos:
//
//   · POR ALTURA: lo opaco que se ve a través de la sábana solo se vela según
//     cuánto queda POR DEBAJO de ella, en altura de mundo. *Antes* se fundía por
//     la distancia EN PANTALLA entre la sábana y lo de detrás, y eso falla justo
//     donde más se ve: con la cámara cerca de la altura de la sábana, un píxel
//     apenas por debajo del corte con un barril ya mira la sábana un metro por
//     delante del barril, así que el barril salía cortado en recto —arriba nítido,
//     abajo velado—. Medido por altura, el barril se vela poco a poco hacia el
//     suelo, como si la niebla tuviera grosor.
//   · POR ÁNGULO: una sábana vista de canto se apaga. Si no, cuando la cámara
//     queda a su altura se ve como una raya clara que cruza la pantalla.

uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform sampler2D profundidad : hint_depth_texture, filter_nearest;
uniform vec3 color : source_color = vec3(0.42, 0.40, 0.40);
uniform float densidad = 0.55;
uniform float fundido = 0.35;          // la distancia (en pantalla) a la que se funde con lo opaco
uniform float grosor = 0.22;           // cuánto por debajo de la sábana se vela del todo
uniform float escala = 0.13;
uniform vec2 viento = vec2(0.012, 0.005);
uniform float semilla = 0.0;

varying vec3 v_pos;

void vertex() {
	v_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = v_pos.xz + vec2(semilla * 7.3, semilla * 3.1);
	float a = texture(ruido, p * escala + viento * TIME).r;
	float b = texture(ruido, p * escala * 2.3 + vec2(0.37, 0.71) - viento.yx * TIME * 1.7).r;
	float n = smoothstep(0.30, 0.90, a * 0.65 + b * 0.35);
	// Bordes de la sábana: nunca se ve dónde acaba.
	vec2 e = min(UV, 1.0 - UV);
	float borde = smoothstep(0.0, 0.32, e.x) * smoothstep(0.0, 0.32, e.y);
	// Lo opaco que tiene detrás, en la vista y en el mundo.
	float z = texture(profundidad, SCREEN_UV).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, z * 2.0 - 1.0);
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, z);
#endif
	vec4 pv = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	pv.xyz /= pv.w;
	vec3 opaco = (INV_VIEW_MATRIX * vec4(pv.xyz, 1.0)).xyz;
	float suave = clamp((VERTEX.z - pv.z) / fundido, 0.0, 1.0);
	float hondo = smoothstep(0.0, grosor, v_pos.y - opaco.y);
	float de_canto = smoothstep(0.03, 0.22, abs(dot(NORMAL, VIEW)));
	ALBEDO = color;
	ALPHA = densidad * n * borde * suave * hondo * de_canto;
}

void light() {
	// La luna alumbra la nave entera y pareja, así que no se le deja todo: con
	// toda (1,0) la bruma se volvía una sábana azul; con poca (0,3) era más oscura
	// que el suelo y lo ensuciaba en vez de flotar. El fuego, entero.
	float cuanto = LIGHT_IS_DIRECTIONAL ? 0.8 : 1.0;
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * cuanto * (0.55 + 0.45 * max(dot(NORMAL, LIGHT), 0.0)) / PI;
}
