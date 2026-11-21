shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

// CRIPTA 3D — EL CIELO DEL ÓCULO: la tarjeta que hay detrás de la reja.
//
// El óculo es el motivo de toda la luz fría de la cripta y, mirado desde la
// mesa, se leía como un disco OSCURO: el muro tiene 0,42 de grueso y desde la
// cámara de juego se mira el hueco a unos 40° de su eje, así que se veía el
// cielo de la noche (casi negro) o el propio taladro en sombra. Esto es un
// disco en el plano del muro, metido un poco DETRÁS de la reja (que se recorta
// negra encima), que da la noche iluminada por la luna: azul luna, más claro
// hacia el centro y con nubes que pasan muy despacio. Lo que sobra del disco
// queda dentro de la piedra y no se ve.
//
// Moderado a propósito: tiene que leerse como el sitio de donde sale la luz,
// no como una lámpara. Por eso va por debajo del umbral del brillo.

uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform vec3 color : source_color = vec3(0.58, 0.70, 1.0);
uniform float fuerza = 0.6;
uniform float vida = 1.0;   // la mueve el guion con el rayo: la luna respira igual

void fragment() {
	vec2 c = UV * 2.0 - 1.0;
	float r = length(c);
	// La luna está arriba y detrás (de ahí baja el rayo): el cielo, algo más
	// claro hacia arriba y hacia el centro, sin un disco de luna que se recorte.
	float centro = 1.0 - smoothstep(0.0, 1.0, r);
	float alto = 0.5 + 0.5 * clamp(-c.y, -1.0, 1.0);
	float nubes = texture(ruido, UV * 0.6 + vec2(TIME * 0.0035, TIME * 0.0012)).r;
	float v = fuerza * vida * (0.50 + 0.38 * centro + 0.12 * alto) * mix(0.82, 1.12, nubes);
	ALBEDO = color * v;
}
