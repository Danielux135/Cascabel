shader_type canvas_item;

// ÓRBITA — la nebulosa del cielo, pintada UNA VEZ en una textura que da la
// vuelta entera (longitud a lo ancho, latitud a lo alto).
//
// El cielo no cambia nunca, y son quince capas de ruido: calculadas en cada
// píxel de cada fotograma se llevaban más de la mitad del coste por píxel en
// una gráfica integrada. `mundo_orbita.gd` dibuja esto una vez al arrancar y
// `cielo.gdshader` solo lo lee.
//
// Va guardada con curva (potencia 1/2,2) y un grano de un nivel, porque la
// textura es de 8 bits y la nebulosa es casi toda oscura: sin la curva, los
// degradados salen a escalones.

float azar(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
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

float nubes(vec3 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 5; i++) {
		s += a * ruido(p);
		p = p * 2.03 + 11.7;
		a *= 0.5;
	}
	return s;
}

void fragment() {
	float lon = (UV.x - 0.5) * 6.2831853;
	float lat = (0.5 - UV.y) * 3.14159265;
	vec3 d = vec3(cos(lat) * sin(lon), sin(lat), cos(lat) * cos(lon));
	float n1 = nubes(d * 2.2 + vec3(3.1, 0.0, 1.7));
	float n2 = nubes(d * 4.5 + vec3(n1 * 2.0));
	vec3 col = vec3(0.004, 0.006, 0.016);
	float banda = smoothstep(0.30, 0.80, n1 + 0.30 * (1.0 - abs(d.y + 0.15) * 1.4));
	float tono = nubes(d * 1.3 + vec3(7.0, 2.0, 5.0));
	vec3 fria = mix(vec3(0.07, 0.02, 0.24), vec3(0.0, 0.18, 0.27), n2);
	vec3 calida = mix(vec3(0.26, 0.03, 0.20), vec3(0.30, 0.10, 0.04), n2);
	col += mix(fria, calida, smoothstep(0.42, 0.62, tono)) * banda * 1.4;
	col += vec3(0.45, 0.08, 0.24) * pow(max(n2 - 0.45, 0.0) * 2.0, 2.0) * banda;
	float grano = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
	COLOR = vec4(pow(clamp(col, 0.0, 1.0), vec3(1.0 / 2.2)) + grano / 255.0, 1.0);
}
