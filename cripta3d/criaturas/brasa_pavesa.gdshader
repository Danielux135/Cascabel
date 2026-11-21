shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// CRIPTA 3D — BRASA: la luz SUELTA, la que se suma a lo de detrás: las PAVESAS
// (y las chispas del golpe, que son pavesas con otros tonos) y el HILO entre las
// dos ascuas de una brasa partida. `es_hilo` dice cuál es.
//
// Eran dos sombreadores con el mismo modo de pintar, y en el navegador cada
// sombreador, por vacío que esté, cuesta 0,3 s de compilar (ANGLE → Direct3D):
// juntos, 0,4 s en vez de 0,7 (medido con el banco, 21-nov-2026).
//
// LA PAVESA: los rombos rojos que flotan a los lados de la llama en el sprite. Es
// LUZ: sin iluminar y sumada a lo de detrás. Antes era un rombo opaco con un
// sombreado fingido (claro de frente, oscuro de canto) y de cerca se leía como
// confeti de plástico rojo. Una pavesa es un punto de fuego que se enfría: brilla
// recién saltada, parpadea mientras flota y se apaga al final de su vida.
// El color sale de la EDAD de la partícula (recién saltada, a medias, ya vieja),
// con los tres tonos puestos aquí, y no del color de la propia partícula: ese
// no llega igual a los dos motores, y las mismas pavesas salían rojas en
// Compatibility y rosa pálido en Forward+.
//
// EL HILO: es lo que dice, sin una palabra, que las dos ascuas son UNA que se ha
// roto y que se van a juntar: un hilo de chispas que corre de una a otra y que se
// TENSA —más fino, más brillante, más deprisa— cuanto más cerca están. Sin él, al
// partirla se veían dos brasas sueltas (crítica de juego, nov-2026). La malla es
// un cilindro fino a lo largo de su Y (de 0 a 1 = de un ascua a la otra); aquí se
// pinta un reguero de motas que viajan en los dos sentidos.

// 0 una pavesa (o una chispa), 1 el hilo.
uniform float es_hilo = 0.0;
// Cuánta luz da: en la pavesa, una recién nacida (las chispas del golpe, más); en
// el hilo, 0 apagado.
uniform float fuerza = 2.4;

// --- La pavesa
uniform vec3 c_nueva : source_color = vec3(0.91, 0.51, 0.29);
uniform vec3 c_media : source_color = vec3(0.78, 0.29, 0.24);
uniform vec3 c_vieja : source_color = vec3(0.55, 0.18, 0.18);

// --- El hilo
uniform vec3 color : source_color = vec3(0.91, 0.51, 0.29);
uniform vec3 color_vivo : source_color = vec3(0.97, 0.85, 0.42);
uniform float tension = 0.0;   // 0 lejos, 1 a punto de juntarse
uniform float largo = 1.0;     // en unidades, para que las motas no se estiren

varying float edad;
varying float fase;
varying float u;

void vertex() {
	edad = INSTANCE_CUSTOM.y;
	fase = float(INSTANCE_ID) * 1.618;
	u = VERTEX.y + 0.5;
}

void fragment() {
	if (es_hilo > 0.5) {
		float t = TIME * (2.0 + 4.0 * tension);
		float n = largo * 26.0;
		// Dos trenes de motas, uno en cada sentido: el fuego va de una a otra.
		float ida = fract(u * n - t);
		float vuelta = fract(u * n * 0.73 + t * 0.8 + 0.37);
		float motas = max(1.0 - smoothstep(0.0, 0.28, abs(ida - 0.5)),
			(1.0 - smoothstep(0.0, 0.22, abs(vuelta - 0.5))) * 0.7);
		// Un hilo de fondo, que con la tensión se hace continuo.
		float hilo = 0.18 + 0.50 * tension;
		// Las puntas se apagan: el hilo nace DENTRO de cada ascua.
		float puntas = smoothstep(0.0, 0.12, u) * smoothstep(1.0, 0.88, u);
		float parpadeo = 0.75 + 0.25 * sin(TIME * 31.0 + u * 40.0);
		float k = max(motas, hilo) * puntas * parpadeo * fuerza;
		ALBEDO = mix(color, color_vivo, tension * 0.7 + motas * 0.3) * k * (0.9 + 1.3 * tension);
	} else {
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
}
