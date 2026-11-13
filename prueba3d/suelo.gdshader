shader_type spatial;

// ÓRBITA — el tablero: una losa de cristal oscuro.
//
// Tres cosas a la vez, y las tres son lo que le da cuerpo:
//   1. REFLEJA la mesa de verdad. No es un truco de brillo: una segunda cámara
//      mira la escena desde debajo del cristal y su imagen se pega aquí.
//   2. Lleva una rejilla hexagonal encendida, y del SOL salen ondas que la
//      recorren, así que la mesa entera late desde su centro.
//   3. Debajo del cristal hay fondo: unas estrellas con paralaje, que se
//      desplazan al mover la cámara y lo hacen parecer hondo.

uniform sampler2D reflejo : source_color, filter_linear, repeat_disable;
uniform float fuerza_reflejo = 0.5;
uniform vec3 color_base : source_color = vec3(0.045, 0.055, 0.105);
uniform vec3 color_rejilla : source_color = vec3(0.10, 0.55, 1.0);
uniform vec3 color_sol : source_color = vec3(1.0, 0.55, 0.12);
uniform vec2 centro_sol = vec2(1.6, 7.42);
uniform float latido = 0.0;

varying vec3 mundo;

float azar2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// El hexagono de Inigo Quilez: xy = celda, z = distancia al borde.
vec3 hexagono(vec2 p) {
	vec2 q = vec2(p.x * 2.0 * 0.5773503, p.y + p.x * 0.5773503);
	vec2 pi = floor(q);
	vec2 pf = fract(q);
	float v = mod(pi.x + pi.y, 3.0);
	float ca = step(1.0, v);
	float cb = step(2.0, v);
	vec2 ma = step(pf.xy, pf.yx);
	float e = dot(ma, 1.0 - pf.yx + ca * (pf.x + pf.y - 1.0) + cb * (pf.yx - 2.0 * pf.xy));
	return vec3(pi + ca - cb * ma, e);
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = mundo.xz;
	vec3 h = hexagono(p * 6.0);
	float linea = smoothstep(0.07, 0.0, h.z);
	float celda = azar2(h.xy);

	float r = distance(p, centro_sol);
	float onda = pow(0.5 + 0.5 * sin(r * 5.0 - TIME * 2.2), 10.0) * exp(-r * 0.30);
	float cerca = exp(-r * 0.9);

	vec3 emis = color_rejilla * linea * 0.34;
	emis += mix(color_rejilla, color_sol, cerca) * linea * onda * (1.4 + latido * 3.0);
	emis += color_sol * cerca * 0.10 * (1.0 + latido * 2.0);
	float chispa = step(0.975, celda) * (0.5 + 0.5 * sin(TIME * 1.7 + celda * 40.0));
	emis += color_rejilla * chispa * smoothstep(0.0, 0.12, h.z) * 0.18;

	// Estrellas bajo el cristal, a dos profundidades.
	vec3 vista = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	vec2 corr = -vista.xz / max(vista.y, 0.25);
	for (int i = 0; i < 2; i++) {
		float prof = 0.5 + float(i) * 0.9;
		vec2 q = (p + corr * prof) * (22.0 - float(i) * 8.0);
		vec2 c = floor(q);
		float a = azar2(c + float(i) * 17.0);
		vec2 centro = fract(q) - 0.5 - (vec2(azar2(c + 3.0), azar2(c + 9.0)) - 0.5) * 0.5;
		float pt = smoothstep(0.28, 0.0, length(centro));
		emis += vec3(0.6, 0.8, 1.0) * step(0.88, a) * pt * (0.55 - float(i) * 0.18);
	}

	// El reflejo: la imagen de la camara espejo, vuelta del reves en vertical,
	// algo emborronada y deformada por la rejilla.
	vec2 suv = vec2(SCREEN_UV.x, 1.0 - SCREEN_UV.y);
	suv += (vec2(celda, azar2(h.xy + 5.0)) - 0.5) * 0.0025 * linea;
	vec2 px = vec2(0.0022, 0.0035);
	vec3 refl = texture(reflejo, suv).rgb * 0.36;
	refl += texture(reflejo, suv + vec2(px.x, 0.0)).rgb * 0.16;
	refl += texture(reflejo, suv - vec2(px.x, 0.0)).rgb * 0.16;
	refl += texture(reflejo, suv + vec2(0.0, px.y)).rgb * 0.16;
	refl += texture(reflejo, suv - vec2(0.0, px.y)).rgb * 0.16;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);

	ALBEDO = color_base;
	ROUGHNESS = 0.22;
	METALLIC = 0.0;
	SPECULAR = 0.6;
	EMISSION = emis + refl * fuerza_reflejo * mix(0.45, 1.0, fres);
}
