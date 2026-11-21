shader_type spatial;

// CRIPTA 3D · efectos · EL POLVO DE PIEDRA, en sus dos formas:
//   forma 0  LA BOCANADA que suelta un golpe contra un sillar, una lápida que se
//            hunde o una bola que cae a la losa (las partículas de `efectos.gd`)
//   forma 1  LA ONDA: lo que se levanta a ras de losa cuando algo pega fuerte, y
//            el tañido de la campana. Sustituye al aro de neón de ÓRBITA.
//
// UN SOLO SOMBREADOR PARA LOS DOS (21-nov-2026, para la web). Eran dos, con el
// mismo modo de render y el mismo papel (polvo que se ilumina y se suma), y con
// luz por píxel tardaban 3,4 y 3,2 s en compilar con ANGLE. Cada sombreador es
// un programa más que compila el navegador; juntos y con la luz por vértice, uno
// de 1,0 s.
//
// Es polvo y no luz: se ILUMINA (la llama de un brasero lo pone naranja, la luz
// de la propia bola lo enciende junto a la pared, y en lo oscuro casi no se ve,
// que es como se ve el polvo). Se SUMA, no se pinta encima: el polvo no tapa la
// luz, la esparce. *Probado y quitado:* mezclarlo (`blend_mix`): en la penumbra
// el polvo iluminado salía casi negro, como una mancha en la losa.
//
// LA LUZ VA POR VÉRTICE. La bocanada es un cuadro de 0,12 (como mucho el doble
// al abrirse) y la onda un anillo de 48 lados con lomo; las luces que los tocan
// están a medio metro o más, así que la luz por vértice no se distingue de la de
// por píxel. La envoltura es la de antes (`diffuse_lambert_wrap` con rugosidad
// 1, que por vértice es su valor de partida). Lo único que había que mover: la
// bocanada inclinaba su normal hacia arriba en `fragment`, y por vértice eso ya
// no llegaría a la luz; ahora se inclina en `vertex`.
//
// LA BOCANADA: una mancha de ruido y no un círculo. Cada una coge un trozo
// distinto de `ruido_manchas.png` según el ángulo de su partícula
// (INSTANCE_CUSTOM.x) y se va deshaciendo con la edad (.y). Su color es el de la
// partícula (COLOR).
//
// LA ONDA: la malla es un anillo bajo con lomo (`efectos.gd`): UV.x da la
// vuelta, UV.y va del borde de dentro (0) al de fuera (1). Encima del polvo
// iluminado, si el suceso tiene color (una criatura, la campana, el fuego de un
// brasero), el frente lleva un resplandor rasante y débil, lo justo para que se
// lea de quién era. Lo de piedra no brilla.

render_mode blend_add, depth_draw_never, cull_disabled, shadows_disabled, diffuse_lambert_wrap, specular_disabled, vertex_lighting;

uniform int forma = 0;
uniform sampler2D tex_manchas : filter_linear_mipmap, repeat_enable;
uniform float opacidad = 0.55;
// Lo demás, solo de la onda.
uniform vec3 color_polvo : source_color = vec3(0.55, 0.52, 0.46);
uniform vec3 color_brillo : source_color = vec3(1.0, 0.6, 0.3);
uniform float brillo = 0.0;
// 0 → 1 a lo largo de la vida de la onda.
uniform float t = 0.0;
uniform float semilla = 0.0;
// Lo deprisa que se apaga: 2 la de un golpe, que se posa enseguida; menos de 1
// el tañido de la campana, que tiene que llegar vivo hasta las palas.
uniform float fundido = 2.0;
// Dónde se puede ver, en el suelo (x mín, z mín, x máx, z máx; mundo). Por
// defecto, en todas partes. El tañido lo recorta a la mesa: es un anillo de
// cinco unidades de radio a la altura del tablero, y fuera del mueble el suelo
// de la sala está casi un metro más abajo, así que sus arcos FLOTABAN en el aire
// a los dos lados de la mesa.
uniform vec4 recorte = vec4(-1000.0, -1000.0, 1000.0, 1000.0);
// La envoltura de la luz de la onda (ver `vertex`): por vértice y de espaldas a
// la luz, lo que llega es w / (1 + w)², sea cual sea el ángulo. Medido en la
// escena A/B (lo que suma la onda en rojo, en lineal; antes 0,0569): con 0,1 da
// 0,0498 y con 0,2, 0,0662; el tañido, a ras y lejos del fuego, pedía algo más
// (0,2 le dejaba igual que antes). 0,15 queda entre los dos.
uniform float envoltura_onda = 0.15;

// La bocanada: (semilla, edad, —). La onda: dónde está, en el mundo.
varying vec3 v_dato;

void vertex() {
	if (forma == 0) {
		// Cara a la cámara, conservando el tamaño de la partícula.
		mat4 mv = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
				INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		mv = mv * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
				vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
				vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
				vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_MATRIX = mv;
		// Mira a la cámara, pero la luz que viene de arriba también la toca: la
		// misma normal que se ponía en `fragment` (la suya, un 40 % hacia arriba),
		// ya en espacio de vista, así que su matriz pasa a ser la identidad.
		vec3 propia = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);
		NORMAL = normalize(mix(propia, (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz, 0.4));
		MODELVIEW_NORMAL_MATRIX = mat3(1.0);
		v_dato = vec3(INSTANCE_CUSTOM.x, INSTANCE_CUSTOM.y, 0.0);
	} else {
		v_dato = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		// LA ONDA SE ALUMBRABA POR DEBAJO, y así tiene que seguir. Su anillo
		// (`efectos.gd`) está devanado de modo que desde arriba se ven sus caras
		// de ATRÁS, y por píxel, con `cull_disabled`, Godot le da la vuelta a la
		// normal en las caras de atrás: la onda se alumbraba como si mirara al
		// suelo, y del fuego (que está encima) solo le llegaba lo que pasa por la
		// envoltura, `(1 + N·L) / 4` con N·L negativo. Por vértice no hay vuelta
		// (no se sabe qué cara se verá) y la envoltura recorta N·L a cero antes de
		// sumar: con la normal hacia arriba salía el doble de clara (medido en la
		// escena de prueba A/B: lo que suma la onda en rojo, ×2,05). Así que la
		// normal va hacia abajo (la cámara nunca baja del suelo) y la envoltura
		// se queda en `envoltura_onda`, que deja la luz del fuego que le llega en
		// lo que le llegaba antes.
		NORMAL = -NORMAL;
		ROUGHNESS = envoltura_onda;
	}
}

void fragment() {
	// Las dos lecturas de ruido van FUERA de las ramas, cada forma solo decide
	// dónde lee: Direct3D no quiere un `texture` dentro de un `if`.
	vec2 uv1;
	vec2 uv2;
	vec2 c = UV - vec2(0.5);
	if (forma == 0) {
		float giro = v_dato.x;
		vec2 q = mat2(vec2(cos(giro), sin(giro)), vec2(-sin(giro), cos(giro))) * c;
		vec2 sitio = vec2(fract(v_dato.x * 0.731), fract(v_dato.x * 0.377));
		uv1 = q * 0.55 + sitio;
		uv2 = q * 1.4 + sitio.yx + vec2(v_dato.y * 0.15);
	} else {
		float dentro = step(recorte.x, v_dato.x) * step(v_dato.x, recorte.z)
				* step(recorte.y, v_dato.z) * step(v_dato.z, recorte.w);
		if (dentro < 0.5) {
			discard;
		}
		uv1 = vec2(UV.x * 5.0 + semilla, UV.y * 0.6 - t * 0.5);
		uv2 = vec2(UV.x * 13.0 - semilla * 0.7, UV.y * 1.3 + t * 0.3);
	}
	float n1 = texture(tex_manchas, uv1).r;
	float n2 = texture(tex_manchas, uv2).r;
	ROUGHNESS = 1.0;
	if (forma == 0) {
		float edad = v_dato.y;
		float nube = smoothstep(0.25, 0.8, n1 * 0.65 + n2 * 0.45);
		// Se abre y se deshace: al principio es un bulto denso, al final jirones.
		float r = length(c) * 2.0;
		float borde = 1.0 - smoothstep(0.35 - edad * 0.2, 1.0, r);
		float vida = smoothstep(0.0, 0.08, edad) * (1.0 - smoothstep(0.35, 1.0, edad));
		ALBEDO = COLOR.rgb;
		ALPHA = clamp(borde * mix(0.35, 1.0, nube) * (nube * 0.6 + 0.4) * vida * opacidad * COLOR.a, 0.0, 1.0);
		EMISSION = vec3(0.0);
	} else {
		float nube = smoothstep(0.2, 0.85, n1 * 0.6 + n2 * 0.5);
		// El frente es denso; por detrás queda un velo que se posa.
		float frente = smoothstep(0.0, 0.55, UV.y) * (1.0 - smoothstep(0.7, 1.0, UV.y));
		float vida = pow(1.0 - t, fundido) * smoothstep(0.0, 0.06, t);
		ALBEDO = color_polvo;
		ALPHA = clamp(frente * mix(0.25, 1.0, nube) * vida * opacidad, 0.0, 1.0);
		float filo = smoothstep(0.45, 0.8, UV.y) * (1.0 - smoothstep(0.8, 1.0, UV.y));
		EMISSION = color_brillo * brillo * filo * nube * vida;
	}
}
