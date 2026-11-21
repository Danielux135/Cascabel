shader_type sky;

// CRIPTA 3D — EL CIELO DE LA CRIPTA, que casi nadie ve.
//
// Hace dos trabajos distintos, y por eso pinta distinto según quién lo mire:
//
//   · A LA VISTA (el fondo de la cámara) es NOCHE: azul noche muy oscuro, cerca
//     de #05070C, un poco más claro hacia el horizonte, que es donde la niebla
//     lejana se encuentra con él. Ni luna ni fuego: la sala la cierra la bóveda
//     de «arquitectura», y la luna solo entra por el óculo (es un foco).
//     *Antes:* la mitad de abajo era marrón rojizo y arriba asomaba la luna
//     entera, gigante, por detrás del muro. Una luna azul sobre un cielo granate
//     no casaba, los oscuros se leían como barro, y con la luna a la vista el
//     rayo no necesitaba entrar por el óculo.
//   · EN LOS REFLEJOS (`AT_CUBEMAP_PASS`: el mapa de radiancia que reflejan el
//     metal y el suelo mojado) lleva una franja cálida y baja —el fuego de las
//     antorchas y los braseros— y una mancha fría alta hacia la luna. Sin ella el
//     latón y el acero reflejan negro y se quedan en silueta.
//
// No usa TIME a propósito: un cielo quieto se hornea UNA vez en el mapa de
// radiancia y no cuesta nada por cuadro.

uniform vec3 fondo_horizonte = vec3(0.0042, 0.0062, 0.0115);
uniform vec3 fondo_hondo = vec3(0.0012, 0.0017, 0.0032);
uniform vec3 noche_alta = vec3(0.0020, 0.0028, 0.0055);
uniform vec3 franja_fuego = vec3(0.14, 0.068, 0.030);
uniform vec3 cenit = vec3(0.010, 0.013, 0.024);
uniform vec3 luna = vec3(0.50, 0.62, 0.95);
// Hacia DÓNDE está la luna (lo contrario de hacia dónde va su luz).
uniform vec3 hacia_luna = vec3(-0.293, 0.432, -0.853);
uniform float halo = 0.35;
uniform float disco = 1.6;

void sky() {
	vec3 d = normalize(EYEDIR);
	float y = d.y;
	vec3 abajo = mix(fondo_horizonte, fondo_hondo, smoothstep(-0.12, -0.75, y));
	vec3 arriba;
	if (AT_CUBEMAP_PASS) {
		// La franja del fuego no es pareja: a manchas alrededor, como las llamas
		// que habría repartidas por la sala. Un aro uniforme se reflejaba como un
		// neón.
		float az = atan(d.x, d.z);
		float manchas = 0.55 + 0.45 * (0.5 + 0.5 * sin(az * 3.0 + 1.3)) * (0.6 + 0.4 * sin(az * 7.0 - 0.4));
		arriba = mix(franja_fuego * manchas, cenit, smoothstep(0.0, 0.42, y));
		float l = max(dot(d, normalize(hacia_luna)), 0.0);
		arriba += luna * (halo * pow(l, 18.0) + disco * pow(l, 500.0));
	} else {
		arriba = mix(fondo_horizonte, noche_alta, smoothstep(0.0, 0.5, y));
	}
	COLOR = mix(abajo, arriba, smoothstep(-0.03, 0.05, y));
}
