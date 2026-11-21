shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back;

// CRIPTA — un JIRÓN del espectro (la pieza se llama zarcillo). La malla es una
// CINTA RECTA a lo largo de su +X (ancha en Y, fina en Z, la raíz en el origen,
// metida en la masa); la curva se la pone este shader, y se deshace hacia la
// punta con el mismo fundido en hebras que el faldón.
//
// CÓMO SE RIZA. El ángulo de la tangente crece a lo largo del zarcillo:
//     ángulo(s) = rizo0·s + rizo1·s² + una onda que viaja de la raíz a la punta
// y la línea del centro es la integral de esa tangente, que se suma por tramos
// en cada vértice (doce tramos sobran para quince centímetros). Con rizo0 y
// rizo1 de signo contrario sale una S; con todo a cero, una cinta recta. Así
// `espectro.gd` la curva, la deja colgar, la recoge o la cruza delante de los
// ojos solo cambiando dos números. (Con rizo1 de 200 cerraba un círculo y eran
// asas o cuernos: ahora ninguno pasa de media vuelta.)
//
// `arrastre` es lo que lo tira la marcha (en el espacio de la malla): pesa más
// cuanto más lejos de la raíz, que es lo que hace que vaya A RASTRAS.

#include "res://cripta3d/criaturas/espectro_gel.gdshaderinc"

uniform float largo = 0.15;
uniform float rizo0 = 0.0;
uniform float rizo1 = 0.0;
uniform float onda = 0.0;
uniform float fase = 0.0;
uniform float frecuencia = 5.0;
uniform vec3 arrastre = vec3(0.0);
uniform float temblor = 0.0;
uniform float desvanece = 0.30;

varying vec3 pos_obj;

float angulo(float s) {
	float u = s / largo;
	return rizo0 * s + rizo1 * s * s
		+ onda * u * sin(reloj * frecuencia - u * 5.5 + fase);
}

void vertex() {
	vec3 p = VERTEX;
	pos_obj = p;
	float s = max(p.x, 0.0);
	float u = clamp(s / largo, 0.0, 1.0);
	// La línea del centro, sumada por tramos (punto medio de cada uno).
	vec2 c = vec2(min(p.x, 0.0), 0.0);
	float ds = s / 12.0;
	for (int i = 0; i < 12; i++) {
		float ai = angulo((float(i) + 0.5) * ds);
		c += vec2(cos(ai), sin(ai)) * ds;
	}
	float a = angulo(s);
	vec2 tg = vec2(cos(a), sin(a));
	vec2 per = vec2(-tg.y, tg.x);
	vec3 v = vec3(c + per * p.y, p.z);
	// El temblor del miedo, más en la punta.
	v += vec3(sin(reloj * 41.0 + s * 90.0), sin(reloj * 37.0 + s * 70.0 + 1.0),
		sin(reloj * 33.0 + s * 60.0 + 2.0)) * 0.003 * temblor * u;
	v += arrastre * pow(u, 1.6);
	VERTEX = v;
	vec3 nn = NORMAL;
	NORMAL = vec3(tg * nn.x + per * nn.y, nn.z);
}

void fragment() {
	vec3 albedo;
	vec3 emision;
	float alfa;
	float rugosidad;
	gel(pos_obj, NORMAL, VIEW, COLOR.r, COLOR.g, albedo, emision, alfa, rugosidad);
	// El jirón se DESHACE hacia la punta, con el mismo fundido que el faldón: no
	// termina, se va. El borde del fundido va roto en hebras que corren hacia la
	// punta. `desvanece` es dónde empieza a irse (0 raíz, 1 punta).
	float s = COLOR.b;
	float hebras = gel_ruido3(vec3(s * 9.0 - reloj * 1.4, pos_obj.y * 60.0, fase * 3.0));
	float queda = 1.0 - smoothstep(desvanece, 0.86, s + (hebras - 0.5) * 0.24);
	ALBEDO = albedo;
	EMISSION = emision * (0.5 + 0.5 * queda);
	// Lo que va metido en la masa no se dibuja: la masa es translúcida, y el
	// trozo de dentro se veía a través como un tubo clavado.
	// Y nace FUNDIDO: el corte por donde sale de la piel, con su borde brillante,
	// se leía como un aro pegado al cuerpo.
	ALPHA = alfa * queda * smoothstep(0.0, 0.04, pos_obj.x);
	ROUGHNESS = rugosidad;
	SPECULAR = 0.12;
}
