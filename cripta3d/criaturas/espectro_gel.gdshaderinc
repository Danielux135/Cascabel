// CRIPTA — la GELATINA del espectro: lo que comparten el cuerpo, los zarcillos
// y las gotas que suelta. Cada uno pone su vértice (cómo se mueve) y llama a
// `gel()` para el color.
//
// CÓMO SE VE, y por qué así:
//   · NO ES PLÁSTICO. La primera versión tenía albedo violeta entero, rugosidad
//     0,2 y especular 0,55: bajo el fuego era un caramelo de látex con brillos
//     naranjas duros, y solo parecía espectro cuando le pegaban (el destello lo
//     volvía lavanda translúcido). Ahora ESE es el estado base, más denso: la
//     piel apenas recibe luz (poco albedo, rugosa, casi sin especular) y el
//     violeta va POR DENTRO, en la emisión.
//   · EL BORDE BRILLA (fresnel) en un arcano claro, suave: es lo que lo recorta
//     sobre la piedra oscura y lo que se lee de lejos.
//   · POR DENTRO hay humo: volutas que suben despacio, y un núcleo que alumbra
//     un poco, a cuentagotas, desde el centro (lo que se ve de frente) y no
//     desde la piel.
//   · ES TRANSLÚCIDO SIEMPRE: deja pasar un cuarto de lo de detrás, menos en el
//     núcleo y en el borde, que es lo que impide que desaparezca sobre la losa.
//   · EL MIEDO ES UN SOLO EJE: de violeta denso a violeta claro CASI
//     TRANSPARENTE. Antes tiraba a blanco y, con el fuego encima, todos los
//     estados de miedo eran el mismo rosa pálido.
// Los colores llegan de `Paleta` desde `espectro.gd`.
//
// SIN LUZ DE GODOT (21-nov-2026, para la web): quien incluye esto es `unshaded`
// y se alumbra con `espectro_luz.gdshaderinc`; el ruido se lee de una textura
// (`espectro_ruido.gdshaderinc`). Cuerpo y jirón costaban 7,8 s de compilar
// cada uno con ANGLE; las cuentas, en esos dos ficheros.

#include "res://cripta3d/criaturas/espectro_ruido.gdshaderinc"
#include "res://cripta3d/criaturas/espectro_luz.gdshaderinc"

uniform vec3 c_hondo : source_color = vec3(0.10, 0.05, 0.16);
uniform vec3 c_cuerpo : source_color = vec3(0.42, 0.25, 0.62);
uniform vec3 c_luz : source_color = vec3(0.66, 0.48, 0.85);
uniform vec3 c_palido : source_color = vec3(0.89, 0.90, 0.93);
uniform float palidez = 0.0;
uniform float destello = 0.0;
// 1 entero; por debajo se deshace en humo (al aparecer, al colarse en la bola).
uniform float cuaja = 1.0;
uniform float agitacion = 0.0;
uniform float semilla = 0.0;
// Reloj propio: `espectro.gd` lo para en la parada del golpe.
uniform float reloj = 0.0;

// El ruido de valor 3D de siempre, ahora de una lectura de textura.
float gel_ruido3(vec3 x) {
	return esp_ruido3(x);
}

// Las volutas: ruido retorcido por otro ruido (domain warping), subiendo.
float gel_volutas(vec3 p, float t) {
	vec3 q = p * 15.0 + vec3(semilla, -t * 0.55 + semilla * 0.7, 0.0);
	float w1 = gel_ruido3(q * 0.8 + vec3(0.0, 0.0, t * 0.21));
	float w2 = gel_ruido3(q * 0.8 + vec3(5.2, 1.3, -t * 0.17));
	float v = gel_ruido3(q * 1.6 + vec3(w1, w2, w1 * w2) * (2.6 + agitacion * 1.5));
	// Hebras: lo que queda en una banda estrecha del ruido son filamentos.
	return 1.0 - smoothstep(0.0, 0.16, abs(v - 0.5));
}

// pos = posición en el objeto (para las volutas), n y v en vista.
// ao = oclusión horneada, canto = lo saliente.
// La rugosidad es para el brillo de `luz_propia`.
void gel(vec3 pos, vec3 n, vec3 v, float ao, float canto,
		out vec3 albedo, out vec3 emision, out float alfa, out float rugosidad) {
	float t = reloj;
	float de_frente = clamp(dot(n, v), 0.0, 1.0);
	float fres = pow(1.0 - de_frente, 2.2);
	// El núcleo: lo que se mira de frente es lo que se ve a través, hacia el centro.
	float nucleo = pow(de_frente, 1.8);
	float hebra = gel_volutas(pos, t);
	float niebla = gel_ruido3(pos * 9.0 + vec3(0.0, -t * 0.4, semilla));
	float m = clamp(palidez, 0.0, 1.0);

	// El tinte, según el miedo: del violeta hondo al arcano claro. Sin blanco.
	vec3 tinte = mix(c_cuerpo, c_luz, m * 0.70);
	vec3 claro = mix(c_luz, c_palido, 0.30 + 0.15 * m);

	// La piel: oscura, rugosa y poca. Es lo único que ve el fuego.
	vec3 piel = mix(c_hondo, tinte, 0.30 + 0.30 * canto) * (0.55 + 0.45 * ao);
	albedo = piel * 0.28 * (1.0 - 0.5 * m);

	// Por dentro: humo violeta con hebras más claras que suben, y un núcleo que
	// alumbra poco. La oclusión lo apaga en los huecos (no es un rótulo).
	vec3 dentro = mix(c_hondo, tinte, 0.40 + 0.45 * niebla);
	dentro = mix(dentro, claro, hebra * (0.22 + 0.25 * agitacion));
	emision = dentro * (0.42 + 0.36 * nucleo) * (0.45 + 0.55 * ao)
		+ c_luz * nucleo * nucleo * (0.08 + 0.20 * hebra)
		+ claro * fres * (0.78 + 0.30 * canto) * (0.45 + 0.55 * ao);
	// Con miedo se vacía pero BRILLA más claro: un fantasma palidece encendiéndose,
	// no apagándose (transparente sobre la losa oscura, sin esto, se oscurecía).
	emision = emision * (1.0 + m * 0.85) + claro * destello * 0.9;

	// Translúcido siempre; más denso en el núcleo y en el borde. Con miedo, se
	// vacía: acorralado es lo más transparente que llega a estar.
	alfa = mix(0.74, 0.88, nucleo);
	alfa = mix(alfa, 0.94, fres * 0.65);
	alfa *= 1.0 - 0.48 * m;
	// Más rugoso abajo, donde se deshace; con algo de variación.
	rugosidad = mix(0.62, 0.46, smoothstep(0.06, 0.24, pos.y)) + (niebla - 0.5) * 0.10;

	// Cuajar: se deshace en hebras de humo. Lo que aún no ha cuajado no existe;
	// el filo de lo que cuaja brilla un poco.
	// Cuaja DE ABAJO ARRIBA, en hebras que suben: con el ruido solo, a medio
	// cuajar eran trozos sueltos flotando (escombro, no humo).
	if (cuaja < 0.999) {
		float humo = gel_ruido3(pos * vec3(16.0, 7.0, 16.0) + vec3(0.0, -t * 2.2, semilla)) * 0.40
			+ gel_ruido3(pos * 40.0 + vec3(t * 0.7)) * 0.15
			+ clamp((pos.y - 0.06) * 2.6, 0.0, 0.45);
		// Con cuaja = 0 el umbral queda por debajo de todo el humo (nada); con 1,
		// por encima (todo).
		float umbral = cuaja * 1.2 - 0.1;
		alfa *= smoothstep(humo - 0.08, humo, umbral);
		emision += c_luz * 0.7 * (1.0 - smoothstep(0.0, 0.10, abs(umbral - humo)))
			* (1.0 - cuaja);
	}
}
