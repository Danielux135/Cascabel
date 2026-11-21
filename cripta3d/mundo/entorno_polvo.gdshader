shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

// CRIPTA 3D — EL POLVO DEL RAYO. Motas que solo existen donde las toca la luna
// (lo que en una iglesia de verdad hace que el haz se vea): fuera del haz no
// pintan nada, dentro brillan frías y titilan al girar.
//
// No se mueven desde el guion: cada mota guarda en su transformación una
// posición DENTRO del haz (u, v en la sección, t a lo largo, todo de 0 a 1) y
// aquí se le suma una deriva lenta que se envuelve, así que salen de un lado y
// entran por el otro sin que nadie las recicle. Cero trabajo por cuadro en el
// procesador, y vale igual en WebGL.
//
// `agitacion` la sube el guion cuando toca la campana mayor: el golpe suelta
// polvo de la bóveda, las motas bajan más deprisa y brillan más.

uniform vec3 color : source_color = vec3(0.70, 0.80, 1.0);
uniform float fuerza = 1.4;
uniform float tam = 0.010;
uniform float agitacion = 0.0;
uniform vec3 origen = vec3(0.0);
uniform vec3 eje = vec3(0.0, -1.0, 0.0);
uniform vec3 lado_u = vec3(1.0, 0.0, 0.0);
uniform vec3 lado_v = vec3(0.0, 0.0, 1.0);
uniform float largo = 3.6;
uniform float radio_0 = 0.27;
uniform float radio_1 = 0.36;

varying float v_brillo;
varying vec2 v_local;

void vertex() {
	vec4 semilla = INSTANCE_CUSTOM;
	vec3 base = MODEL_MATRIX[3].xyz;
	float tiempo = TIME * (1.0 + agitacion * 2.5);
	// Deriva: un vaivén pequeño en la sección y una caída lentísima a lo largo
	// del haz (el polvo baja, pero tan despacio que parece flotar).
	float u = base.x + 0.18 * sin(tiempo * (0.11 + 0.10 * semilla.x) + semilla.y * 6.283);
	float v = base.y + 0.18 * cos(tiempo * (0.09 + 0.08 * semilla.z) + semilla.x * 6.283);
	float t = fract(base.z + tiempo * (0.004 + 0.006 * semilla.w) + agitacion * semilla.y * 0.02);
	vec2 sec = vec2(u, v);
	float rho = length(sec);
	if (rho > 1.0) {
		// Envuelve dentro del círculo: la que sale por un lado entra por el otro.
		sec = sec / rho * (2.0 - rho) * -1.0;
		rho = length(sec);
	}
	float r = mix(radio_0, radio_1, t);
	vec3 p = origen + eje * (t * largo) + (lado_u * sec.x + lado_v * sec.y) * r;
	// Titila como una mota que gira y enseña una cara a la luz de vez en cuando.
	float giro = 0.5 + 0.5 * sin(TIME * (1.3 + 2.1 * semilla.z) + semilla.w * 40.0);
	giro = giro * giro * giro;
	float canto = 1.0 - rho * rho;
	float extremos = smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(0.85, 1.0, t));
	v_brillo = canto * extremos * (0.25 + 0.75 * giro) * (1.0 + agitacion * 1.5);
	vec3 vista = (VIEW_MATRIX * vec4(p, 1.0)).xyz;
	vista.xy += VERTEX.xy * tam * (0.55 + 0.9 * semilla.y);
	POSITION = PROJECTION_MATRIX * vec4(vista, 1.0);
	v_local = VERTEX.xy;
}

void fragment() {
	float d = length(v_local);
	float punto = exp(-d * d * 5.0) * step(d, 1.0);
	ALBEDO = color * (fuerza * v_brillo * punto);
}
