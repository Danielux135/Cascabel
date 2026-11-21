shader_type canvas_item;

// CRIPTA 3D — EL ACABADO: lo último que pasa antes de la pantalla. Parte del de
// ÓRBITA (aberración, viñeta, grano) y le añade lo que hace que una imagen se
// lea como cine y no como un motor: el ETALONAJE y la MAQUETA.
//
// Trabaja sobre la imagen ya tonemapeada (la curva de tono y el brillo los pone
// el `Environment`, en el módulo «entorno»), así que aquí todo es de 0 a 1 y
// en el espacio de la pantalla. La escena no le pasa parámetros: los valores
// por defecto SON el aspecto.
//
// En orden:
//   1. MAQUETA (tilt-shift): un desenfoque suave arriba y abajo, que es lo que
//      hace el ojo con una cosa pequeña fotografiada de cerca. La franja nítida
//      cubre la mesa entera en la cámara de juego (las palas caen al 76 % del
//      alto); solo se van el fondo del ábside y el marco de delante.
//   2. ABERRACIÓN: el rojo y el azul se separan hacia las esquinas. Nada en el
//      centro, donde se juega.
//   3. ETALONAJE: sombras hacia el azul y luces hacia el ámbar (el par luna y
//      fuego, que es lo que cuenta la escena), y unos negros que no se aplastan:
//      se levantan un poco y en frío, como una copia de cine. Las sombras van
//      ahora más al azul y las luces menos al ámbar que la primera vez: con el
//      fuego ya naranja de por sí, el ámbar de las luces dejaba la piedra, la
//      madera y el latón del mismo color. El negro levantado se queda por debajo
//      del 3 % (es de noche: azul, no gris).
//
// `maqueta` lo apaga «entorno» en BAJA (`calidad(n)`); el resto es igual en las
// tres calidades, para que sean la misma cripta.
//   4. VIÑETA: oscurece las esquinas, en óvalo con la forma de la pantalla.
//   5. GRANO: fino, que cambia cada cuadro y pesa más en los medios tonos (en el
//      negro puro y en el blanco no se ve grano en una película).

uniform float maqueta = 1.0;               // 0 = sin desenfoque
uniform float maqueta_radio = 2.6;         // en píxeles de la imagen, en el borde mismo
uniform float maqueta_arriba = 0.20;       // dónde empieza a desenfocar, desde arriba
uniform float maqueta_abajo = 0.86;        // y desde abajo
uniform float aberracion = 0.0045;
uniform vec3 sombras : source_color = vec3(0.91, 0.97, 1.08);
uniform vec3 luces : source_color = vec3(1.03, 1.00, 0.96);
uniform float negros = 0.009;              // cuánto se levanta el negro
uniform vec3 color_negros : source_color = vec3(0.42, 0.60, 1.0);
uniform float contraste = 1.04;
uniform float saturacion = 1.0;
uniform float vineta = 0.55;
uniform float grano = 0.028;

// Ocho direcciones repartidas en espiral: con un disco de verdad y no una cruz,
// el desenfoque no deja estrellas en los puntos de luz.
const vec2 DISCO[8] = vec2[](
	vec2(0.707, 0.000), vec2(-0.354, 0.612), vec2(-0.354, -0.612), vec2(1.000, 0.000),
	vec2(0.500, 0.866), vec2(-0.500, 0.866), vec2(-1.000, 0.000), vec2(0.000, -1.000));

vec3 leer(sampler2D t, vec2 uv, vec2 des) {
	return vec3(texture(t, uv + des).r, texture(t, uv).g, texture(t, uv - des).b);
}

void fragment() {
	vec2 uv = UV;
	vec2 c = uv - 0.5;
	float d = dot(c, c);
	vec2 des = c * d * aberracion;

	// 1. La maqueta.
	// (smoothstep con los bordes al revés no está definido en GLSL ES: se da la vuelta a mano)
	float desenfoque = maqueta * ((1.0 - smoothstep(0.0, maqueta_arriba, uv.y))
		+ smoothstep(maqueta_abajo, 1.0, uv.y));
	vec3 col = leer(TEXTURE, uv, des);
	if (desenfoque > 0.01) {
		vec2 r = TEXTURE_PIXEL_SIZE * maqueta_radio * desenfoque;
		vec3 suma = col;
		for (int i = 0; i < 8; i++) {
			suma += texture(TEXTURE, uv + DISCO[i] * r).rgb;
		}
		col = mix(col, suma / 9.0, clamp(desenfoque * 1.5, 0.0, 1.0));
	}

	// 3. El etalonaje.
	float lum = dot(col, vec3(0.2126, 0.7152, 0.0722));
	vec3 tinte = mix(sombras, luces, smoothstep(0.04, 0.55, lum));
	col *= tinte;
	col = (col - 0.5) * contraste + 0.5;
	float lum2 = dot(col, vec3(0.2126, 0.7152, 0.0722));
	col = mix(vec3(lum2), col, saturacion);
	col = max(col, 0.0);
	col += negros * color_negros * (1.0 - smoothstep(0.0, 0.35, lum2));

	// 4. La viñeta.
	float v = length(c * vec2(1.0, 0.82));
	col *= 1.0 - vineta * smoothstep(0.32, 0.78, v);

	// 5. El grano.
	float n = fract(sin(dot(uv * 1031.0 + fract(TIME * 7.13) * 91.7, vec2(12.9898, 78.233))) * 43758.5453);
	float medios = 4.0 * lum2 * (1.0 - lum2);
	col += (n - 0.5) * grano * (0.35 + 0.65 * medios);

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
