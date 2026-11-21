// CRIPTA — el RUIDO del espectro, leído de `espectro_ruido.png` (cómo se hace y
// por qué esa textura y no las de la casa: `espectro_ruido.gd`).
//
// Antes era un ruido de valor calculado aquí, con un `hash` por nudo (ocho por
// lectura en 3D). En un navegador Direct3D lo despliega todo en cada variante:
// el cuerpo con su ruido por código costaba 0,75 s más de compilar que con
// esto (banco, ANGLE, 21-nov-2026). Ahora cada lectura es UNA lectura de
// textura, y da el MISMO ruido de valor (misma rejilla, misma curva suave, mismo
// reparto); cambia el azar de los nudos, o sea dónde cae cada mancha.
//
// Siempre `textureLod(…, 0.0)`: la textura no tiene mipmaps (cada nudo ocupa
// varios píxeles, como el ruido de antes, que tampoco se filtraba) y algunas
// lecturas van dentro de una rama.

// La pone `espectro.gd` en cada material.
uniform sampler2D ruido_espectro : filter_linear, repeat_enable;

// Ruido de valor 3D, 0..1. La rodaja z de la rejilla es la textura desplazada
// (37, 17)·z, y G es R una rodaja más allá: una lectura trae las dos rodajas.
float esp_ruido3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	vec2 uv = i.xy + vec2(37.0, 17.0) * i.z + f.xy + 0.5;
	vec2 rg = textureLod(ruido_espectro, uv * (1.0 / 256.0), 0.0).rg;
	return mix(rg.x, rg.y, f.z);
}

// Ruido de valor 2D, 0..1 (la rodaja 0).
float esp_ruido2(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return textureLod(ruido_espectro, (i + f + 0.5) * (1.0 / 256.0), 0.0).r;
}

// Los cuatro azares sueltos de una celda entera (en el centro del texel el
// filtro lineal no mezcla nada).
vec4 esp_azar(vec2 celda) {
	return textureLod(ruido_espectro, (floor(celda) + 0.5) * (1.0 / 256.0), 0.0);
}
