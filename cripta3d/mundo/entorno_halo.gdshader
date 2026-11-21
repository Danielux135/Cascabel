shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

// CRIPTA 3D — EL HALO DEL ÓCULO: el aire que brilla en la boca del hueco.
//
// Una tarjeta que mira siempre a la cámara, delante del óculo, con un
// resplandor frío que cae en campana. Empalma la tarjeta del cielo (detrás de
// la reja) con el arranque del rayo: sin él, el rayo salía de un agujero muerto.
//
// No hace prueba de profundidad del motor (si la hiciera, el muro le cortaría
// medio halo con un canto recto): la hace a mano y BLANDA con la profundidad de
// la escena. Lo que está bien por delante del halo (la campana, un raíl) lo
// tapa; lo que queda detrás o casi a su altura (el muro) no.

uniform sampler2D profundidad : hint_depth_texture, filter_nearest;
uniform vec3 color : source_color = vec3(0.62, 0.74, 1.0);
uniform float fuerza = 0.25;
uniform float vida = 1.0;

void vertex() {
	// Siempre de cara a la cámara, con el tamaño de la malla.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 c = UV * 2.0 - 1.0;
	float r2 = dot(c, c);
	// Campana suave y a cero antes del borde del cuadrado: sin canto.
	float halo = exp(-r2 * 4.5) * (1.0 - smoothstep(0.55, 1.0, r2));

	float z = texture(profundidad, SCREEN_UV).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, z * 2.0 - 1.0);
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, z);
#endif
	vec4 pv = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	pv.xyz /= pv.w;
	// Distancias a lo largo de la vista (positivas hacia delante).
	float d_opaco = -pv.z;
	float d_halo = -VERTEX.z;
	float libre = smoothstep(-0.35, -0.06, d_opaco - d_halo);

	ALBEDO = color * (fuerza * vida * halo * libre);
}
