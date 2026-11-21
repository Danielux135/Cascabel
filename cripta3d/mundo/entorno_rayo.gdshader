shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, fog_disabled, shadows_disabled;

// CRIPTA 3D — EL RAYO DE LUNA.
//
// En Compatibility no hay niebla volumétrica, así que el haz que entra por el
// óculo es una malla: un cono abierto que solo sirve de «dónde mirar». La luz
// no se pinta en su piel —eso da un tubo de cristal con los bordes duros—, se
// INTEGRA por dentro: cada píxel calcula por dónde entra y por dónde sale su
// rayo de vista del cilindro y suma OCHO muestras de aire iluminado entre los
// dos puntos. Así sale solo lo que tiene un haz de verdad: más denso en el eje,
// sin borde, y cortado limpio donde hay algo delante o donde llega al suelo
// (se para en la profundidad de la escena).
//
// El aire de dentro tiene tres cosas, todas leídas en la SECCIÓN del haz (u, v)
// y que por eso se estiran a lo largo de él como hacen los rayos de verdad:
//   · LA REJA del óculo: dos barras en cruz y un aro que oscurecen sus vetas;
//   · el humo: dos lecturas de manchas que corren despacio, una a lo ancho y
//     otra a lo largo (bocanadas que bajan por el haz);
//   · y el canto: el haz se apaga hacia fuera con una curva, no de golpe.
//
// Se queda en la capa sin reflejo: un haz reflejado en el suelo mojado era el
// doble de coste para algo que casi no se distingue.

uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform sampler2D profundidad : hint_depth_texture, filter_nearest;

uniform vec3 color : source_color = vec3(0.55, 0.68, 1.0);
uniform float fuerza = 0.55;           // luz por unidad de recorrido dentro del haz
uniform float vida = 1.0;              // la mueve el guion: la luna respira con las nubes
uniform vec3 origen = vec3(0.0);       // el centro del óculo
uniform vec3 eje = vec3(0.0, -1.0, 0.0);
uniform vec3 lado_u = vec3(1.0, 0.0, 0.0);
uniform vec3 lado_v = vec3(0.0, 0.0, 1.0);
uniform float largo = 3.6;             // del óculo al suelo
uniform float radio_0 = 0.27;          // en el óculo
uniform float radio_1 = 0.36;          // en el suelo
uniform float reja = 1.0;              // 0 = sin reja (los rayos de la bóveda)
uniform float humo = 0.65;             // cuánto manchan las bocanadas
uniform float prisa = 1.0;
// Las muestras por píxel. Un `uniform` y no un 8 escrito: con el largo fijo,
// Direct3D desplegaba el bucle (ocho copias de `denso`, cada una con sus dos
// lecturas) en cada una de las variantes que compila Godot.
uniform int muestras = 8;
uniform float nucleo = 2.0;           // 2 = denso en el eje (el del óculo); 1 = parejo (los de la bóveda)

float denso(vec3 p) {
	vec3 d = p - origen;
	float t = dot(d, eje);
	float tn = t / largo;
	if (tn < 0.0 || tn > 1.08) {
		return 0.0;
	}
	vec3 radial = d - eje * t;
	float r = mix(radio_0, radio_1, clamp(tn, 0.0, 1.0));
	float u = dot(radial, lado_u) / r;
	float v = dot(radial, lado_v) / r;
	float rho2 = u * u + v * v;
	if (rho2 >= 1.0) {
		return 0.0;
	}
	// Canto suave: lo de fuera pesa poco, y el eje casi el doble que el resto.
	float canto = pow(1.0 - rho2, nucleo);
	// La reja: dos barras y un aro, con la sombra algo borrosa (la luna no es un
	// punto, y a dos unidades del óculo la sombra de una barra ya se ha abierto).
	float abre = 0.05 + 0.10 * tn;
	float barra_u = smoothstep(0.035, 0.035 + abre, abs(u + 0.02));
	float barra_v = smoothstep(0.035, 0.035 + abre, abs(v - 0.05));
	float aro = smoothstep(0.03, 0.03 + abre, abs(sqrt(rho2) - 0.58));
	float sombra_reja = mix(1.0, barra_u * barra_v * aro, reja * 0.78);
	// El humo: a lo ancho (vetas, se estiran solas a lo largo del haz) y a lo
	// largo (bocanadas que bajan despacio).
	// `textureLod` y no `texture`: esto va dentro del bucle de las muestras, y
	// ahí Direct3D no sabe sacar las derivadas (despliega el bucle entero para
	// poder). Nivel 0: las manchas van tan estiradas (un tercio de textura de
	// lado a lado del haz) que el nivel que elegía `texture` ya era el 0.
	float vetas = textureLod(ruido, vec2(u, v) * 0.33 + vec2(tn * 0.05, TIME * 0.004 * prisa), 0.0).r;
	float bocanadas = textureLod(ruido, vec2(tn * 0.55 - TIME * 0.018 * prisa, u * 0.12 + v * 0.07 + 0.31), 0.0).r;
	float aire = mix(1.0, smoothstep(0.15, 0.85, vetas) * 1.35, humo)
		* mix(1.0, 0.45 + 1.1 * bocanadas, humo * 0.7);
	// Entra con un fundido corto por el óculo; abajo lo corta el suelo solo.
	float entra = smoothstep(0.0, 0.07, tn);
	return canto * sombra_reja * aire * entra;
}

void fragment() {
	vec3 ojo = CAMERA_POSITION_WORLD;
	vec3 piel = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 rd = normalize(piel - ojo);

	// Dónde está lo opaco que hay detrás, en distancia sobre este mismo rayo.
	float z = texture(profundidad, SCREEN_UV).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, z * 2.0 - 1.0);
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, z);
#endif
	vec4 pv = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	pv.xyz /= pv.w;
	vec3 opaco = (INV_VIEW_MATRIX * vec4(pv.xyz, 1.0)).xyz;
	float s_opaco = length(opaco - ojo);

	// Entrada y salida del cilindro que envuelve el cono (con el radio grande:
	// lo que sobra lo pone a cero `denso`).
	vec3 w = ojo - origen;
	vec3 rd_p = rd - eje * dot(rd, eje);
	vec3 w_p = w - eje * dot(w, eje);
	float R = max(radio_0, radio_1) * 1.02;
	float A = max(dot(rd_p, rd_p), 1e-5);
	float B = 2.0 * dot(w_p, rd_p);
	float C = dot(w_p, w_p) - R * R;
	float disc = B * B - 4.0 * A * C;
	if (disc <= 0.0) {
		discard;
	}
	float raiz = sqrt(disc);
	float s0 = max((-B - raiz) / (2.0 * A), 0.0);
	float s1 = min((-B + raiz) / (2.0 * A), s_opaco);
	if (s1 <= s0) {
		discard;
	}
	// Ocho muestras con el punto de partida movido por píxel: sin eso salen
	// rodajas; con eso, un grano finísimo que el posprocesado se come.
	float paso = (s1 - s0) / float(muestras);
	float salto = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453);
	float suma = 0.0;
	for (int i = 0; i < muestras; i++) {
		float s = s0 + paso * (float(i) + salto);
		suma += denso(ojo + rd * s);
	}
	suma *= paso;
	ALBEDO = color * (fuerza * vida * suma);
}
