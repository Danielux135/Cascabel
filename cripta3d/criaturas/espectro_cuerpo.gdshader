shader_type spatial;
// Translúcido con prepaso de profundidad: la gelatina se tapa a sí misma bien
// (sin él, los goterones de detrás se pintaban encima de la panza) y aun así
// deja ver un poco la losa.
render_mode blend_mix, depth_prepass_alpha, cull_back;

// CRIPTA — el CUERPO del espectro: la masa y su faldón. El color es el de
// `espectro_gel.gdshaderinc`; aquí, cómo se mueve la piel:
//   · TIEMBLA COMO GELATINA: dos ondas lentas que no paran nunca y, con miedo,
//     un temblor rápido y menudo (`temblor`).
//   · EL FALDÓN (color de vértice B: 1 en la punta de cada goterón) ondea solo
//     y SE QUEDA ATRÁS: `arrastre` es hacia dónde lo tira la marcha, ya en el
//     espacio de la malla (lo calcula `espectro.gd`).
//   · `encoge` recoge el faldón hacia la panza: acorralado, se hace una bola.

#include "res://cripta3d/criaturas/espectro_gel.gdshaderinc"

uniform float temblor = 0.0;
uniform vec3 arrastre = vec3(0.0);
uniform float encoge = 0.0;
uniform float ondear = 1.0;

varying vec3 pos_obj;

void vertex() {
	float t = reloj;
	vec3 p = VERTEX;
	float w = COLOR.b;
	float lento = sin(t * 3.1 + p.y * 38.0 + p.x * 24.0 + semilla) * 0.55
		+ sin(t * 2.3 - p.z * 33.0 + p.y * 12.0) * 0.45;
	float rapido = sin(t * 37.0 + p.y * 95.0 + p.z * 40.0) * sin(t * 29.0 + p.x * 80.0);
	VERTEX += NORMAL * (0.0022 * lento * ondear + 0.0040 * temblor * rapido);

	// El faldón: cada goterón con su fase, según por dónde cuelga.
	float ang = atan(p.z, p.x);
	float vaiven = sin(t * 3.6 + ang * 3.0 + semilla) * 0.5 + sin(t * 5.3 - ang * 2.0) * 0.5;
	VERTEX.xz += normalize(p.xz + vec2(0.0001)) * w * 0.007 * vaiven * ondear;
	VERTEX.y += w * 0.004 * sin(t * 4.4 + ang * 2.0);
	VERTEX += arrastre * w * w;
	// Recogido: los goterones suben y se meten bajo la panza.
	VERTEX.y += encoge * w * 0.040;
	VERTEX.xz *= 1.0 - encoge * w * 0.30;
	pos_obj = p;
}

void fragment() {
	vec3 albedo;
	vec3 emision;
	float alfa;
	float rugosidad;
	gel(pos_obj, NORMAL, VIEW, COLOR.r, COLOR.g, albedo, emision, alfa, rugosidad);
	// SIN FINAL DURO POR ABAJO: el último tercio del cuerpo se desvanece por
	// altura, con el borde roto en hebras (un ruido que sube despacio), y los
	// goterones se acaban antes de acabarse. La primera versión los tenía
	// opacos hasta la punta y de frente eran patas.
	float hebras = gel_ruido3(vec3(pos_obj.x * 70.0, pos_obj.y * 12.0 - reloj * 0.6,
		pos_obj.z * 70.0 + semilla));
	float fundido = smoothstep(0.050, 0.140, pos_obj.y + (hebras - 0.5) * 0.050);
	alfa *= fundido;
	emision *= 0.55 + 0.45 * fundido;
	ALBEDO = albedo;
	EMISSION = emision;
	ALPHA = alfa;
	ROUGHNESS = rugosidad;
	// Casi sin especular: con 0,55 el fuego le sacaba brillos de globo de látex.
	SPECULAR = 0.12;
}
