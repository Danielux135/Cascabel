shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// CRIPTA 3D — BRASA: una PAVESA. Los rombos rojos que flotan a los lados de la
// llama en el sprite, y las chispas del golpe.
//
// Es LUZ: sin iluminar y sumada a lo de detrás. Antes era un rombo opaco con un
// sombreado fingido (claro de frente, oscuro de canto) y de cerca se leía como
// confeti de plástico rojo. Una pavesa es un punto de fuego que se enfría: brilla
// recién saltada, parpadea mientras flota y se apaga al final de su vida.
//
// El color sale de la EDAD de la partícula (recién saltada, a medias, ya vieja),
// con los tres tonos puestos aquí, y no del color de la propia partícula: ese
// no llega igual a los dos motores, y las mismas pavesas salían rojas en
// Compatibility y rosa pálido en Forward+.

uniform vec3 c_nueva : source_color = vec3(0.91, 0.51, 0.29);
uniform vec3 c_media : source_color = vec3(0.78, 0.29, 0.24);
uniform vec3 c_vieja : source_color = vec3(0.55, 0.18, 0.18);
// Cuánta luz da una recién nacida. Las chispas del golpe, más.
uniform float fuerza = 2.4;

varying float edad;
varying float fase;

void vertex() {
	edad = INSTANCE_CUSTOM.y;
	fase = float(INSTANCE_ID) * 1.618;
}

void fragment() {
	vec3 tinte = mix(c_nueva, c_media, smoothstep(0.0, 0.30, edad));
	tinte = mix(tinte, c_vieja, smoothstep(0.40, 1.0, edad));
	// Saturada a mano, como la llama: la curva de tono dejaba las pavesas en rosa.
	float gris = dot(tinte, vec3(0.2126, 0.7152, 0.0722));
	tinte = max(mix(vec3(gris), tinte, 1.5), vec3(0.0));
	// El brillo según la vida: fuerte al saltar, parpadeando mientras flota (cada
	// una a su fase) y apagándose al final.
	float vive = (1.0 - smoothstep(0.55, 1.0, edad)) * (0.55 + 0.45 * (1.0 - smoothstep(0.0, 0.35, edad)));
	float parpadea = 0.72 + 0.28 * sin(edad * 46.0 + fase) * sin(edad * 17.0 + fase * 2.3);
	// El centro del rombo más caliente que su filo: sin sombrear, solo más luz.
	float f = abs(dot(normalize(NORMAL), normalize(VIEW)));
	ALBEDO = tinte * fuerza * vive * parpadea * mix(0.55, 1.0, f);
}
