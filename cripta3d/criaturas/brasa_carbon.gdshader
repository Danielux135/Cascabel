shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// CRIPTA 3D — BRASA: el CARBÓN. El tizón del que nace la llama y lo que queda a
// la vista cuando se aplasta o se apaga.
//
// Este SÍ recibe luz: es lo que le da peso a la criatura. Carbón negro mate con
// la ceniza en los cantos y un brillo de grafito en las caras de rotura, y el
// ASCUA por dentro: asoma por los surcos y en el cráter, y respira.
//
// Color de vértice (de Blender): R oclusión, G canto, B ascua.

uniform float tiempo = 0.0;
uniform float semilla = 0.0;
// Cuánto arde por dentro: 1 normal, menos casi apagada, más avivada.
uniform float calor = 1.0;
uniform float golpe = 0.0;

uniform vec3 c_negro : source_color = vec3(0.08, 0.07, 0.10);
uniform vec3 c_carbon : source_color = vec3(0.16, 0.16, 0.20);
uniform vec3 c_ceniza : source_color = vec3(0.55, 0.55, 0.60);
uniform vec3 c_ceniza_calida : source_color = vec3(0.63, 0.61, 0.54);
uniform vec3 c_rojo : source_color = vec3(0.55, 0.18, 0.18);
uniform vec3 c_rojo_luz : source_color = vec3(0.78, 0.29, 0.24);
uniform vec3 c_naranja : source_color = vec3(0.91, 0.51, 0.29);
uniform vec3 c_oro_claro : source_color = vec3(0.97, 0.85, 0.42);

varying vec3 local;

float azar(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.17, 0.23));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float ruido(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(azar(i), azar(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(azar(i + vec3(0.0, 1.0, 0.0)), azar(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(azar(i + vec3(0.0, 0.0, 1.0)), azar(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(azar(i + vec3(0.0, 1.0, 1.0)), azar(i + vec3(1.0, 1.0, 1.0)), f.x), f.y),
		f.z);
}

void vertex() {
	local = VERTEX;
}

void fragment() {
	float ao = COLOR.r;
	float canto = COLOR.g;
	float ascua = COLOR.b;
	vec3 p = local + vec3(semilla);

	// Tres escalas de detalle: la mancha grande, el grano y las grietas menudas
	// (las líneas donde un ruido cruza su mitad: salen finas y con recorrido).
	float mancha = ruido(p * 21.0);
	float grano = ruido(p * 95.0);
	float linea = abs(ruido(p * 46.0 + vec3(3.7)) - 0.5);
	float grieta = 1.0 - smoothstep(0.0, 0.035, linea);
	float fibra = abs(ruido(vec3(p.x * 30.0, p.y * 150.0, p.z * 30.0)) - 0.5);

	// --- El carbón
	vec3 col = mix(c_negro, c_carbon, mancha * 0.75 + grano * 0.25);
	// La ceniza se posa en los cantos y mira hacia arriba; nunca pareja.
	float posada = clamp(canto * 1.25 + (mancha - 0.45) * 0.6, 0.0, 1.0) * (0.35 + 0.65 * grano);
	col = mix(col, mix(c_ceniza, c_ceniza_calida, mancha), posada * 0.40);
	col *= 1.0 - grieta * 0.40;
	col *= mix(0.30, 1.0, ao);

	// El relieve fino: el grano y las grietas mueven la normal.
	float alto = grano * 0.5 + mancha * 0.9 - grieta * 1.0 + smoothstep(0.0, 0.2, fibra) * 0.25;
	vec3 dpx = dFdx(VERTEX);
	vec3 dpy = dFdy(VERTEX);
	float dhx = dFdx(alto);
	float dhy = dFdy(alto);
	vec3 r1 = cross(dpy, NORMAL);
	vec3 r2 = cross(NORMAL, dpx);
	float det = dot(dpx, r1);
	vec3 grad = sign(det) * (dhx * r1 + dhy * r2);
	NORMAL = normalize(abs(det) * NORMAL - 0.0030 * grad);

	ALBEDO = col;
	// Mate, salvo las caras de rotura: ahí el carbón tiene un brillo de grafito.
	ROUGHNESS = mix(0.95, 0.56, clamp(canto * 0.9 + (1.0 - grano) * 0.25 - posada, 0.0, 1.0));
	SPECULAR = 0.35;
	METALLIC = 0.0;

	// --- El ascua: por los surcos, en el cráter y un hilo por las grietas.
	float respira = 0.72 + 0.28 * sin(tiempo * 1.7 + p.x * 23.0 + p.z * 17.0 + mancha * 5.0);
	float e = clamp(ascua * (0.80 + 0.45 * mancha) + grieta * ascua * 0.5 + grieta * 0.10 * calor, 0.0, 1.0);
	e *= respira * calor;
	// El golpe aviva lo que ya ardía: los surcos, no el carbón entero.
	e = clamp(e + golpe * (ascua * 0.9 + grieta * 0.25), 0.0, 1.6);
	vec3 brasa = mix(c_rojo, c_rojo_luz, smoothstep(0.10, 0.40, e));
	brasa = mix(brasa, c_naranja, smoothstep(0.38, 0.70, e));
	brasa = mix(brasa, c_oro_claro, smoothstep(0.75, 1.15, e));
	EMISSION = brasa * e * (1.2 + 1.6 * e);
	// Donde arde no hay carbón que ver: el negro se lo come la luz.
	ALBEDO *= 1.0 - 0.7 * clamp(e, 0.0, 1.0);
}
