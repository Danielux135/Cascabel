shader_type spatial;

// CRIPTA 3D · la bola · LO QUE LA HACE LEGIBLE (segunda pasada sobre el acero).
//
// Por qué existe: en una cripta casi a oscuras, el acero pulido refleja lo que
// tiene alrededor. Fuera del charco de luna eso es fuego, latón y losa parda, y
// la bola se TIÑE DE BRONCE y desaparece entre los raíles y los engranajes (la
// crítica la perdió en 5 de 12 capturas de la ráfaga RASANTE). Una bola de
// pinball no se puede perder nunca, así que esta pasada le da tres cosas que NO
// dependen de la luz que le caiga:
//   · EL CANTO: el contorno, frío y casi blanco, más fuerte por arriba. Recorta
//     la silueta contra cualquier fondo oscuro o cálido.
//   · EL PISO: un mínimo de claridad fría en toda la cara. Es lo que hace que,
//     donde no llega ninguna luz, la bola siga siendo gris acero y no negro ni
//     bronce. Pequeño: con más, deja de ser metal y es una canica de tiza.
//   · EL PUNTO DE LUZ: un brillo especular fijo a la cámara, arriba a la
//     izquierda, como el de los nueve sprites de bola del juego (`bolas64`). Es
//     lo primero que el ojo busca de una bola de metal, y aquí está siempre.
// Todo frío, del color de la luna: así ni se confunde con nada de lo que arde
// ni con el latón, que es lo único que tiene que brillar cálido.
//
// No es un material de la mesa (eso es el acero de la biblioteca): es luz
// encima, aditiva y sin profundidad propia. La RANURA no la lleva (es otra
// malla, el hueco de carbón): así queda negra y la banda oscura se lee.

render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform vec3 color_canto : source_color = vec3(0.74, 0.82, 1.0);
uniform float fuerza = 0.3;
// Lo fino que es el filo: más alto, más pegado al contorno.
uniform float filo = 3.0;
// El mínimo de claridad, en la cara entera.
uniform float piso = 0.08;
// El punto de luz: cuánto y lo apretado que es.
uniform float punto = 0.9;
uniform float apretado = 60.0;

void fragment() {
	float frente = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float borde = pow(1.0 - frente, filo);
	// Más por arriba que por abajo: la luz viene de lo alto, y un aro parejo
	// alrededor de la bola se lee como un adorno, no como luz.
	vec3 n_mundo = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	float arriba = 0.45 + 0.55 * smoothstep(-0.4, 0.7, n_mundo.y);
	// El punto: una luz fija a la cámara, arriba a la izquierda y algo delante.
	// Va en espacio de vista a propósito: la bola rueda y el punto no se mueve.
	vec3 luz = normalize(vec3(-0.5, 0.75, 0.6));
	vec3 r = reflect(-VIEW, NORMAL);
	float destello = pow(max(dot(r, luz), 0.0), apretado);
	// El piso, más claro arriba que abajo: una esfera pareja parece un disco.
	float claro = piso * (0.55 + 0.45 * smoothstep(-0.6, 0.8, n_mundo.y));
	ALBEDO = color_canto * (borde * arriba * fuerza + claro) + vec3(1.0, 0.98, 0.95) * destello * punto;
}
