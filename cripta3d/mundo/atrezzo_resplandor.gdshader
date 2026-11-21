shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

// CRIPTA 3D · «atrezzo» · EL RESPLANDOR DE LA CAMPANA ARMADA.
//
// Armada, la campana pide algo al jugador («completa un recorrido»), y desde
// SEGUIMIENTO, con la bola abajo, la campana se sale del plano: el campo era
// idéntico armada y sin armar (la crítica de juego, revisión 2). Esto es lo que
// se ve en el campo: un disco de polvo dorado a ras de suelo, bajo la vertical
// de la campana, que respira despacio, y un aro que se CIERRA hacia el centro
// cada pocos segundos, como la cuerda tensa que tira de ella. Se cierra y no se
// abre a propósito: la onda que se abre es el tañido (decisión 9), y armada
// todavía no ha tocado.
//
// Suma luz y no escribe profundidad: lo que hay encima (los braseros, las
// lápidas, la bola) lo tapa. Va bajo y apagado: nunca más claro que la bola
// (decisión 5: lo que brilla en el suelo no puede parecer una bola).

uniform vec3 color : source_color = vec3(0.88, 0.65, 0.24);
// 0 apagado, 1 armada del todo. Lo sube y lo baja `atrezzo.gd`.
uniform float fuerza = 0.0;
// Lo que tarda el aro en cerrarse, en segundos.
uniform float periodo = 2.2;

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r = length(q);
	// El disco: blando, sin borde que se lea como un foco.
	float disco = 1.0 - smoothstep(0.0, 1.0, r);
	disco *= disco;
	float respira = 0.62 + 0.38 * sin(TIME * 2.4);
	// El aro que se cierra: nace en el borde, apagado, y se aviva al llegar.
	float f = fract(TIME / periodo);
	float radio = mix(0.95, 0.12, f * f * (3.0 - 2.0 * f));
	// Al cuadrado a mano: `pow` con base negativa es NaN en GLSL, y un NaN en un
	// sombreador aditivo se come el plano entero (la primera prueba no pintó nada).
	float dr = (r - radio) / 0.07;
	float aro = exp(-dr * dr) * smoothstep(0.0, 0.25, f) * (1.0 - smoothstep(0.8, 1.0, f));
	aro *= 1.0 - smoothstep(0.85, 1.0, r);
	ALBEDO = color * (disco * 0.8 * respira + aro * 0.75) * fuerza;
}
