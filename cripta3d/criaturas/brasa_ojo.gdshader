shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled;

// CRIPTA 3D — BRASA: un OJO. La malla es la cuenca (un disco ajustado a la cara,
// con el reborde levantado) y aquí se dibuja lo de dentro, con las coordenadas
// UV del disco: así la pupila se mueve, se encoge y se tapa sin tocar un vértice
// y el dibujo sale limpio se mire desde donde se mire.
//
// Es el ojo del sprite: cuenca naranja oscura, reborde más oscuro todavía y una
// pupila alta y amarilla que es lo más brillante de la criatura. Los párpados
// son de la piel de la cara: al cerrarse, el ojo se queda en una raya.

uniform vec2 mirada = vec2(0.0);       // dónde cae la pupila en la cuenca, de −1 a 1
uniform float abre = 1.0;              // 0 cerrado, 1 abierto, más de 1 de par en par
uniform float pupila = 1.0;            // el tamaño de la pupila
uniform float ceja = 0.0;              // + ceño (cae hacia el centro), − susto (cae hacia fuera)
uniform float lado = 1.0;              // −1 el ojo izquierdo
uniform float brillo = 1.0;
uniform float golpe = 0.0;

uniform vec3 c_cuenca : source_color = vec3(0.55, 0.18, 0.18);
uniform vec3 c_reborde : source_color = vec3(0.42, 0.23, 0.13);
uniform vec3 c_fondo : source_color = vec3(0.17, 0.13, 0.16);
uniform vec3 c_parpado : source_color = vec3(0.88, 0.65, 0.24);
uniform vec3 c_pupila : source_color = vec3(0.97, 0.85, 0.42);
uniform vec3 c_pupila_luz : source_color = vec3(0.96, 0.91, 0.81);

float superelipse(vec2 p, vec2 r, float k) {
	vec2 q = abs(p / r);
	return pow(pow(q.x, k) + pow(q.y, k), 1.0 / k);
}

void fragment() {
	// De −1 a 1, con la y hacia arriba (el GLB trae la v del revés).
	vec2 p = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y * 2.0);
	float e = superelipse(p, vec2(1.0), 3.0);

	// EL OJO DEL SPRITE: una CUENCA OSCURA con una RANURA DORADA encendida dentro.
	// Hubo dos versiones que no lo eran: cuenca negra con pupila clara (dos
	// agujeros en la llama) y, después, la cuenca entera encendida casi al blanco
	// con una raya oscura de pupila. En la mesa, con AgX y el brillo, esa segunda
	// salía como dos cuadrados BLANCOS con pupila negra: ojos de dibujo animado
	// (remate, nov-2026). Ahora lo oscuro es la cuenca y lo que brilla es la
	// ranura, en oro y sin blanco, y es la ranura la que mira a la bola.
	float hondo = smoothstep(0.20, 0.90, e);
	// La cuenca: ascua apagada en el fondo, casi negra hacia el reborde.
	vec3 col = mix(mix(c_fondo, c_cuenca, 0.45), c_fondo * 0.7, hondo);
	// El reborde, un punto más claro: es la piel de la cara que la rodea.
	col = mix(col, c_reborde * 0.9, smoothstep(0.80, 0.94, e));

	// La ranura: alta y estrecha, con las puntas redondas. Se mueve hacia la bola
	// sin salirse de la cuenca y se estrecha con el susto (`pupila` < 1).
	vec2 pp = p - clamp(mirada, vec2(-0.30), vec2(0.30)) * vec2(1.0, 0.7);
	vec2 tam = vec2(0.34 * mix(0.75, 1.0, pupila), 0.64);
	float ep = superelipse(pp, tam, 2.2);
	float ranura = (1.0 - smoothstep(0.84, 1.0, ep)) * (1.0 - smoothstep(0.74, 0.84, e));
	// Oro claro en el centro, oro más hondo hacia el canto y abajo: el ojo del
	// sprite, con un poco más de luz que la cara para que mande, sin llegar al blanco.
	vec3 oro = mix(c_pupila * 1.15, c_parpado * 1.05, smoothstep(0.25, 1.0, ep));
	oro = mix(oro, c_parpado * 0.95, smoothstep(0.1, -0.8, pp.y) * 0.45);
	// Más saturado de lo que es: la curva de tono de la mesa (AgX, exposición 1,5)
	// lava el oro claro a crema, y la ranura tiene que leerse DORADA.
	float gris = dot(oro, vec3(0.2126, 0.7152, 0.0722));
	oro = max(mix(vec3(gris), oro, 1.7), vec3(0.0));
	col = mix(col, oro * brillo, ranura);
	// El resplandor de la ranura en la cuenca: está encendida, no pintada.
	float halo = exp(-max(ep - 1.0, 0.0) * 3.2) * (1.0 - ranura) * (1.0 - smoothstep(0.66, 0.86, e));
	col += c_parpado * 0.30 * halo * brillo;

	// Los párpados: el de arriba baja más que sube el de abajo, y se inclina.
	float hacia_dentro = -lado * p.x;
	float arriba = abre - ceja * hacia_dentro * 0.5;
	float abajo = -abre * 0.92;
	float tapa = max(smoothstep(arriba - 0.03, arriba + 0.03, p.y),
		1.0 - smoothstep(abajo - 0.03, abajo + 0.03, p.y));
	// La raya de las pestañas: lo que queda cuando está cerrado.
	float raya = max(1.0 - smoothstep(0.0, 0.11, abs(p.y - arriba)),
		(1.0 - smoothstep(0.0, 0.08, abs(p.y - abajo))) * 0.7);
	vec3 piel = mix(c_parpado, c_cuenca, smoothstep(0.80, 0.98, e) * 0.6);
	col = mix(col, piel, tapa * step(abre, 1.04));
	col = mix(col, c_reborde * 0.8, raya * step(abre, 1.04) * (1.0 - smoothstep(0.9, 1.0, e)));

	col = col * (1.0 + 0.9 * clamp(golpe, 0.0, 1.0));
	ALBEDO = col;
}
