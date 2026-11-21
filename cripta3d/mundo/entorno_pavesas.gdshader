shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

// CRIPTA 3D — LAS PAVESAS. Pocas: unas chispas que se escapan de los braseros,
// suben dando tumbos, se enfrían de amarillo a rojo y se apagan antes de llegar
// a la campana. Son fuego, así que son de lo poco que pasa del umbral del brillo.
//
// Como el polvo, todo se calcula aquí: la transformación de cada pavesa es su
// punto de salida (encima de un brasero), y la vida sale de TIME con su fase.
// No todas arden en cada vuelta: una tirada por ciclo decide si esta vez sale,
// para que no haya un surtidor regular sino una chispa de vez en cuando.

uniform vec3 color_vivo : source_color = vec3(1.0, 0.82, 0.42);
uniform vec3 color_frio : source_color = vec3(0.85, 0.20, 0.06);
uniform float fuerza = 14.0;
uniform float tam = 0.014;
uniform float altura = 1.3;
uniform float ritmo = 0.22;            // vueltas por segundo
uniform float salen = 0.45;            // qué parte de las vueltas sale de verdad
uniform float avivar = 0.0;            // lo sube el guion con la campana

varying float v_brillo;
varying float v_vida;
varying vec2 v_local;

float azar(float n) {
	return fract(sin(n * 127.1 + 311.7) * 43758.5453);
}

void vertex() {
	vec4 s = INSTANCE_CUSTOM;
	vec3 base = MODEL_MATRIX[3].xyz;
	float ciclo = TIME * ritmo * (0.7 + 0.6 * s.x) + s.y * 17.0;
	float vida = fract(ciclo);
	float vuelta = floor(ciclo);
	float sale = step(1.0 - clamp(salen + avivar * 0.5, 0.0, 1.0), azar(vuelta + s.z * 91.0));
	// Sube frenando (el aire caliente empuja menos arriba) y da tumbos.
	float subida = altura * (0.55 + 0.45 * s.w) * (1.0 - (1.0 - vida) * (1.0 - vida));
	vec3 p = base;
	p.y += subida;
	p.x += 0.10 * vida * sin(vida * 9.0 + s.x * 30.0) + 0.06 * vida * (s.z - 0.5);
	p.z += 0.10 * vida * cos(vida * 7.0 + s.w * 30.0) + 0.05 * vida;
	float parpadeo = 0.6 + 0.4 * sin(TIME * (17.0 + 9.0 * s.z) + s.x * 50.0);
	v_brillo = sale * parpadeo * smoothstep(0.0, 0.04, vida) * (1.0 - smoothstep(0.45, 1.0, vida));
	v_vida = vida;
	vec3 vista = (VIEW_MATRIX * vec4(p, 1.0)).xyz;
	vista.xy += VERTEX.xy * tam * (1.0 - 0.5 * vida) * (0.7 + 0.6 * s.y);
	POSITION = PROJECTION_MATRIX * vec4(vista, 1.0);
	v_local = VERTEX.xy;
}

void fragment() {
	float d = length(v_local);
	float punto = exp(-d * d * 4.0) * step(d, 1.0);
	vec3 c = mix(color_vivo, color_frio, smoothstep(0.1, 0.8, v_vida));
	ALBEDO = c * (fuerza * v_brillo * punto);
}
