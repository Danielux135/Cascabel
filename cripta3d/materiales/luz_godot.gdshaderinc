// CRIPTA 3D — LA LUZ DE GODOT, COPIADA A MANO.
//
// Es `light_compute` (Lambert + GGX) de `drivers/gles3/shaders/scene.glsl`, de
// Godot 4.7.1, cuenta por cuenta: lo que alumbra es lo mismo que con la luz que
// trae el motor. Está aquí por lo que cuesta COMPILAR en un navegador.
//
// La primera vez que usa un sombreador, Godot compila cuatro variantes «por
// defecto» con todos los tipos de luz dentro, también las luces de área, que
// la mesa no tiene. Con `render_mode specular_disabled` esas variantes se
// quedan sin su especular, que es lo caro, y con esta `light()` las luces de
// verdad (omni y foco) lo siguen teniendo. Medido con ANGLE
// (`banco_sombreadores.gd`): la piedra, de 11,2 a 7,4 s.
//
// CÓMO SE USA, en los dos sombreadores que llevan la luz entera (la piedra y el
// suelo):
//   - `render_mode specular_disabled` en el `.gdshader`;
//   - `#define LUZ_CON_TRASLUZ` antes de incluir esto si el `fragment` escribe
//     BACKLIGHT (si no lo escribe, nombrarlo aquí no compila);
//   - y en el `fragment`, junto a SPECULAR, lo mismo en `v_especular`: Godot no
//     le pasa a `light()` el especular del material.
//
// LO QUE NO PASA POR AQUÍ y por eso no cambia: el ambiente, el reflejo del
// cielo en los metales y la niebla.
//
// Si un día una luz de la mesa lleva tamaño (`light_size`), esto deja de ser
// igual que lo del motor: allí el tamaño ablanda N·L y aquí no se ve.

varying float v_especular;

void light() {
	float n_l = min(dot(NORMAL, LIGHT), 1.0);
	float c_nl = max(n_l, 0.0);
	float c_nv = max(dot(NORMAL, VIEW), 1e-4);
	vec3 h = normalize(VIEW + LIGHT);
	float c_nh = clamp(dot(NORMAL, h), 0.0, 1.0);
	float c_lh = clamp(dot(LIGHT, h), 0.0, 1.0);

	if (METALLIC < 1.0) {
		// LAMBERT, no Burley. En el renderizador Compatibility un sombreador que
		// no pide `diffuse_burley` alumbra con Lambert (en `scene.glsl` no hay
		// difuso por defecto: cae en el `#else`), y ni la piedra ni el suelo lo
		// piden. La primera versión de esto copió Burley y la comparación de
		// tomas fijas lo cazó: toda la piedra un 2,8 % más clara.
		float difusa = c_nl * (1.0 / PI);
		DIFFUSE_LIGHT += LIGHT_COLOR * difusa * ATTENUATION;
#ifdef LUZ_CON_TRASLUZ
		DIFFUSE_LIGHT += LIGHT_COLOR * (vec3(1.0 / PI) - difusa) * BACKLIGHT * ATTENUATION;
#endif
	}

	if (ROUGHNESS > 0.0) {
		// GGX con Fresnel de Schlick.
		float alfa = ROUGHNESS * ROUGHNESS;
		float a = c_nh * alfa;
		float k = alfa / (1.0 - c_nh * c_nh + a * a);
		float d = k * k * (1.0 / PI);
		float g = 0.5 / mix(2.0 * c_nl * c_nv, c_nl + c_nv, alfa);
		float mh = 1.0 - c_lh;
		float h5 = mh * mh;
		h5 = h5 * h5 * mh;
		vec3 f0 = mix(vec3(0.16 * v_especular * v_especular), ALBEDO, vec3(METALLIC));
		float f90 = clamp(50.0 * f0.g, 0.0, 1.0);
		vec3 fresnel = f0 + (f90 - f0) * h5;
		SPECULAR_LIGHT += c_nl * d * fresnel * g * LIGHT_COLOR * ATTENUATION * SPECULAR_AMOUNT;
	}
}
