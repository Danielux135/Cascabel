shader_type spatial;

// ÓRBITA — la piel de una criatura.
//
// Recibe luz y sombra como cualquier objeto de la mesa, y encima lleva luz
// propia: un filo encendido en el contorno, que es lo que la separa del cristal
// oscuro y la hace leerse como algo VIVO y no como una pieza más. Cuatro mandos
// la mueven desde el código:
//   golpe     un fogonazo blanco al recibir la bola
//   miedo     palidece y tiembla
//   disolver  se deshace en luz al ser capturada
//   rayas     franjas encendidas, para caparazones

uniform vec3 color : source_color = vec3(0.35, 1.0, 0.40);
uniform vec3 color_borde : source_color = vec3(0.80, 1.0, 0.65);
uniform float brillo = 0.30;
uniform float borde = 1.3;
uniform float rugosidad = 0.30;
uniform float metal = 0.0;
uniform float rayas = 0.0;
uniform float golpe = 0.0;
uniform float miedo = 0.0;
uniform float disolver = 0.0;

varying vec3 local;

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

void vertex() {
	local = VERTEX;
	// El miedo se ve: la piel tirita.
	VERTEX += NORMAL * sin(TIME * 46.0 + VERTEX.y * 60.0 + VERTEX.x * 35.0) * 0.0035 * miedo;
}

void fragment() {
	// Al disolverse se abre por un ruido, con el filo de la herida al blanco.
	float n = ruido(local * 30.0);
	float corte = disolver * 1.2 - 0.1;
	if (n < corte) {
		discard;
	}
	float herida = (1.0 - smoothstep(0.0, 0.10, n - corte)) * step(0.001, disolver);

	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	vec3 base = mix(color, vec3(0.90, 0.94, 1.0), miedo * 0.40);
	vec3 emis = base * brillo + color_borde * fres * borde;
	if (rayas > 0.0) {
		float r = smoothstep(0.40, 0.48, abs(fract(local.z * rayas) - 0.5));
		emis += color_borde * r * 1.6;
	}
	emis = mix(emis, vec3(4.5), clamp(golpe, 0.0, 1.0));
	emis += color_borde * herida * 7.0;

	ALBEDO = base;
	ROUGHNESS = rugosidad;
	METALLIC = metal;
	EMISSION = emis;
}
