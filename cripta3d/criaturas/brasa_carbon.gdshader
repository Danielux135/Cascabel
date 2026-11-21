shader_type spatial;
render_mode vertex_lighting;

// CRIPTA 3D — BRASA: lo SÓLIDO de la llama, en un sombreador: el CARBÓN (el tizón
// del que nace la llama y lo que queda a la vista cuando se aplasta o se apaga) y
// los dos OJOS. `es_ojo` dice cuál es.
//
// POR QUÉ ASÍ (web, 21-nov-2026). En el navegador, WebGL pasa por ANGLE y
// Direct3D compila cada sombreador varias veces; medido con el banco:
//   · el carbón con la luz entera de Godot (burley + GGX) y su ruido por código
//     eran 7,2 s. Con la luz POR VÉRTICE y el ruido leído de `brasa_ruido.png`,
//     0,9. Sigue respondiendo a todas las luces de la mesa (es lo que le da peso a
//     la criatura), pero la luz se calcula en los vértices: el relieve fino que
//     antes movía la normal ya no cambia la luz directa, y se lleva al color (ver
//     abajo; +0,2 s). Sin luz y con una luz propia salía en 0,65, pero dejaba de
//     verse la luna y los braseros encima: no valía;
//   · los ojos eran otro sombreador sin luz, 0,5 s, que es casi todo lo que cuesta
//     un sombreador vacío. Aquí van por la otra rama: sin color propio y con todo
//     en EMISSION, que es exactamente «sin iluminar» (comprobado en el visor: los
//     ojos salen iguales). Todo junto, 1,1 s.
//
// El carbón: negro mate con la ceniza en los cantos y un brillo de grafito en las
// caras de rotura, y el ASCUA por dentro: asoma por los surcos y en el cráter, y
// respira. Color de vértice (de Blender): R oclusión, G canto, B ascua.
//
// El ojo: la malla es la cuenca (un disco ajustado a la cara, con el reborde
// levantado) y aquí se dibuja lo de dentro, con las coordenadas UV del disco: así
// la pupila se mueve, se encoge y se tapa sin tocar un vértice y el dibujo sale
// limpio se mire desde donde se mire. Es el ojo del sprite: cuenca naranja
// oscura, reborde más oscuro todavía y una ranura alta y dorada que es lo más
// brillante de la criatura. Los párpados son de la piel de la cara: al cerrarse,
// el ojo se queda en una raya.

// 0 el carbón, 1 un ojo.
uniform float es_ojo = 0.0;

// --- El carbón
uniform float tiempo = 0.0;
uniform float semilla = 0.0;
// Cuánto arde por dentro: 1 normal, menos casi apagada, más avivada.
uniform float calor = 1.0;
// El golpe: en el carbón aviva los surcos; en el ojo lo aclara entero.
uniform float golpe = 0.0;

uniform vec3 c_negro : source_color = vec3(0.08, 0.07, 0.10);
uniform vec3 c_carbon : source_color = vec3(0.16, 0.16, 0.20);
uniform vec3 c_ceniza : source_color = vec3(0.55, 0.55, 0.60);
uniform vec3 c_ceniza_calida : source_color = vec3(0.63, 0.61, 0.54);
uniform vec3 c_rojo : source_color = vec3(0.55, 0.18, 0.18);
uniform vec3 c_rojo_luz : source_color = vec3(0.78, 0.29, 0.24);
uniform vec3 c_naranja : source_color = vec3(0.91, 0.51, 0.29);
uniform vec3 c_oro_claro : source_color = vec3(0.97, 0.85, 0.42);

// El mismo ruido que la llama (ver `brasa_fuego.gdshaderinc`): el ruido de valor
// 3D de antes, horneado. Aquí eran cuatro llamadas de ocho `hash` cada una.
uniform sampler2D ruido_brasa : filter_linear, repeat_enable;

// --- El ojo
uniform vec2 mirada = vec2(0.0);       // dónde cae la pupila en la cuenca, de −1 a 1
uniform float abre = 1.0;              // 0 cerrado, 1 abierto, más de 1 de par en par
uniform float pupila = 1.0;            // el tamaño de la pupila
uniform float ceja = 0.0;              // + ceño (cae hacia el centro), − susto (cae hacia fuera)
uniform float lado = 1.0;              // −1 el ojo izquierdo
uniform float brillo = 1.0;

uniform vec3 c_cuenca : source_color = vec3(0.55, 0.18, 0.18);
uniform vec3 c_reborde : source_color = vec3(0.42, 0.23, 0.13);
uniform vec3 c_fondo : source_color = vec3(0.17, 0.13, 0.16);
uniform vec3 c_parpado : source_color = vec3(0.88, 0.65, 0.24);
uniform vec3 c_pupila : source_color = vec3(0.97, 0.85, 0.42);

varying vec3 local;

// Cuánto pesa en el color el relieve fino (ver abajo), a ojo contra las capturas
// de cuando la luz era por píxel.
const float RELIEVE = 2.5;

float ruido(vec3 x) {
	float k = floor(x.z);
	vec2 t = textureLod(ruido_brasa, (x.xy + vec2(37.0, 17.0) * k) * (1.0 / 32.0), 0.0).rg;
	float f = x.z - k;
	return mix(t.r, t.g, f * f * (3.0 - 2.0 * f));
}

float superelipse(vec2 p, vec2 r, float k) {
	vec2 q = abs(p / r);
	return pow(pow(q.x, k) + pow(q.y, k), 1.0 / k);
}

void vertex() {
	local = VERTEX;
	// Con la luz por vértice, la aspereza que cuenta para el brillo es la del
	// vértice: la de antes sin el grano (su media, 0,5) ni la mancha (0,5).
	// Mate, salvo las caras de rotura: ahí el carbón tiene un brillo de grafito.
	float posada = clamp(COLOR.g * 1.25 + 0.03, 0.0, 1.0) * 0.675;
	ROUGHNESS = mix(0.95, 0.56, clamp(COLOR.g * 0.9 + 0.125 - posada, 0.0, 1.0));
}

void fragment() {
	if (es_ojo > 0.5) {
		// De −1 a 1, con la y hacia arriba (el GLB trae la v del revés).
		vec2 p = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y * 2.0);
		// La superelipse de grado 3, con el cubo a mano.
		vec2 q3 = abs(p);
		q3 = q3 * q3 * q3;
		float e = pow(q3.x + q3.y, 1.0 / 3.0);

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

		// Sin iluminar: nada de color propio ni de brillo, todo es luz que emite.
		ALBEDO = vec3(0.0);
		SPECULAR = 0.0;
		ROUGHNESS = 1.0;
		EMISSION = col * (1.0 + 0.9 * clamp(golpe, 0.0, 1.0));
	} else {
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

		// EL RELIEVE FINO, AL COLOR. El grano y las grietas movían la normal, y con la
		// luz por píxel eso tallaba el carbón: cada grieta con su filo claro y su filo
		// oscuro. Con la luz por vértice la normal del píxel ya no cambia la luz, así
		// que se calcula igual que antes y lo que habría cambiado la luz que le cae
		// DESDE ARRIBA (su propia llama, y la sala) se lleva al color.
		float alto = grano * 0.5 + mancha * 0.9 - grieta * 1.0 + smoothstep(0.0, 0.2, fibra) * 0.25;
		vec3 dpx = dFdx(VERTEX);
		vec3 dpy = dFdy(VERTEX);
		float dhx = dFdx(alto);
		float dhy = dFdy(alto);
		vec3 r1 = cross(dpy, NORMAL);
		vec3 r2 = cross(NORMAL, dpx);
		float det = dot(dpx, r1);
		vec3 grad = sign(det) * (dhx * r1 + dhy * r2);
		vec3 tallada = normalize(abs(det) * NORMAL - 0.0030 * grad);
		vec3 arriba = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
		col *= clamp(1.0 + RELIEVE * (dot(tallada, arriba) - dot(NORMAL, arriba)), 0.0, 2.0);

		ALBEDO = col;
		// El brillo del reflejo del entorno sí es por píxel: el de antes, con el grano.
		ROUGHNESS = mix(0.95, 0.56, clamp(canto * 0.9 + (1.0 - grano) * 0.25 - posada, 0.0, 1.0));
		SPECULAR = 0.35;

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
}
