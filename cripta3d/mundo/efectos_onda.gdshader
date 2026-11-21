shader_type spatial;

// CRIPTA 3D · efectos · LA ONDA DE POLVO: lo que se levanta a ras de losa
// cuando algo pega fuerte. Sustituye al aro de neón de ÓRBITA.
//
// La malla es un anillo bajo con lomo (`efectos.gd`): UV.x da la vuelta, UV.y
// va del borde de dentro (0) al de fuera (1). El polvo se ILUMINA como el de
// las bocanadas; encima, si el suceso tiene color (una criatura, la campana, el
// fuego de un brasero), el frente de la onda lo lleva como un resplandor
// rasante y débil, lo justo para que se lea de quién era. Lo de piedra no brilla.
//
// SE SUMA, no se pinta encima: el polvo no tapa la luz, la esparce. Donde no
// le da nada no se ve, y donde le da el fuego se enciende de fuego.
// *Probado y quitado:* mezclarlo (`blend_mix`): en la penumbra el polvo
// iluminado salía casi negro y la onda era una mancha oscura en la losa.

render_mode blend_add, depth_draw_never, cull_disabled, shadows_disabled, diffuse_lambert_wrap, specular_disabled;

uniform sampler2D tex_manchas : filter_linear_mipmap, repeat_enable;
uniform vec3 color_polvo : source_color = vec3(0.55, 0.52, 0.46);
uniform vec3 color_brillo : source_color = vec3(1.0, 0.6, 0.3);
uniform float brillo = 0.0;
// 0 → 1 a lo largo de la vida de la onda.
uniform float t = 0.0;
uniform float semilla = 0.0;
uniform float opacidad = 0.6;
// Lo deprisa que se apaga: 2 la de un golpe, que se posa enseguida; menos de 1
// el tañido de la campana, que tiene que llegar vivo hasta las palas.
uniform float fundido = 2.0;
// Dónde se puede ver, en el suelo (x mín, z mín, x máx, z máx; mundo). Por
// defecto, en todas partes. El tañido lo recorta a la mesa: es un anillo de
// cinco unidades de radio a la altura del tablero, y fuera del mueble el suelo
// de la sala está casi un metro más abajo, así que sus arcos FLOTABAN en el aire
// a los dos lados de la mesa.
uniform vec4 recorte = vec4(-1000.0, -1000.0, 1000.0, 1000.0);

varying vec3 v_mundo;

void vertex() {
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float dentro = step(recorte.x, v_mundo.x) * step(v_mundo.x, recorte.z)
			* step(recorte.y, v_mundo.z) * step(v_mundo.z, recorte.w);
	if (dentro < 0.5) {
		discard;
	}
	float vuelta = UV.x;
	float n1 = texture(tex_manchas, vec2(vuelta * 5.0 + semilla, UV.y * 0.6 - t * 0.5)).r;
	float n2 = texture(tex_manchas, vec2(vuelta * 13.0 - semilla * 0.7, UV.y * 1.3 + t * 0.3)).r;
	float nube = smoothstep(0.2, 0.85, n1 * 0.6 + n2 * 0.5);
	// El frente es denso; por detrás queda un velo que se posa.
	float frente = smoothstep(0.0, 0.55, UV.y) * (1.0 - smoothstep(0.7, 1.0, UV.y));
	float vida = pow(1.0 - t, fundido) * smoothstep(0.0, 0.06, t);
	float a = frente * mix(0.25, 1.0, nube) * vida * opacidad;
	ALBEDO = color_polvo;
	ALPHA = clamp(a, 0.0, 1.0);
	ROUGHNESS = 1.0;
	float filo = smoothstep(0.45, 0.8, UV.y) * (1.0 - smoothstep(0.8, 1.0, UV.y));
	EMISSION = color_brillo * brillo * filo * nube * vida;
}
