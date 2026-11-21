// CRIPTA — LA LUZ PROPIA del espectro: la de la gelatina (cuerpo y jirones) y la
// de los ojos.
//
// POR QUÉ. Eran sombreadores «con luz» y en un navegador costaban 6,5–7,8 s de
// compilar CADA UNO (banco, ANGLE, en frío, 21-nov-2026): la luz entera de
// Godot se compila cuatro o cinco veces por sombreador, con todos los tipos de
// luz dentro (y `vertex_lighting` seguía costando 0,86). Ahora son `unshaded`
// (0,33 s de base) y la luz se la pone esto: LAS CUATRO LUCES QUE MÁS LE DAN, que
// `espectro.gd` elige en cada cuadro y atenúa EN EL CENTRO del cuerpo con las
// cuentas de Godot (la atenuación de la omni, el cono del foco), y que aquí, por
// píxel y con la normal de verdad, alumbran como alumbra Godot: el difuso de
// Lambert y el brillo GGX de Schlick con su Fresnel. Lo que dan las demás va al
// ambiente. El cuerpo mide un palmo y los fuegos están a más de medio metro: no
// se ve que la atenuación sea la del centro. Probado y descartado: atenuar cada
// luz en cada píxel costaba 0,7 s más por sombreador.
//
// (El cerco de sal no usa esto: es `vertex_lighting`, ver `espectro_sal.gdshader`.)
//
// OJO CON EL COLOR (lo que costó, 21-nov-2026). En Compatibility, Godot pasa
// ALBEDO y EMISSION de sRGB a lineal ANTES de alumbrar, también en `unshaded`
// (`albedo = srgb_to_linear(albedo)` en su `scene.glsl`), y vuelve a sRGB al
// final. Alumbrar el color tal cual alumbraba en sRGB: una esfera gris bajo el
// fuego salía naranja chillón y con las sombras hundidas. Aquí se pasa a lineal,
// se alumbra y se devuelve en sRGB para que Godot lo deshaga.
//
// Y OJO CON LAS LUCES CON SOMBRA. Godot (Compatibility) no las suma con las
// demás: las pinta en una pasada aparte, ya en sRGB, y la SUMA sobre lo ya
// pintado, que da más luz y menos color que sumarlas en lineal (medido con una
// esfera gris en el visor, que tiene la luna y el fuego con sombra: sin esto
// los ojos salían grises). Así que cada luz dice si va aparte (w = 1) y lo
// suyo se pasa a sRGB por separado (las que van aparte, juntas: con una sola,
// que es lo normal, sale exacto). En web no hay ninguna luz con sombra, y
// entonces todo va junto.
//
// Con `#define ESPECTRO_LUZ_SIN_BRILLO` antes del `#include` no hay GGX (la
// gelatina: no se le veía y costaba 0,2 s). Probado y descartado: sumar todas
// las luces juntas aunque tengan sombra; solo ahorra 0,03–0,05 s.
//
// Lo que se pierde frente a la luz de Godot: el reflejo del cielo (con SPECULAR
// 0,12 es un 0,2 % de cara) y las sombras que caigan ENCIMA del espectro (no
// las hay en web, y el espectro no hace).

// El ambiente de la escena (lineal × energía), más lo de las luces que no caben.
uniform vec3 luz_ambiente = vec3(0.04, 0.05, 0.08);

// Las dos conversiones de Godot. La de vuelta, sin el tope de 1: lo que pasa de
// 1 es lo que hace brillar (glow), y Godot lo vuelve a subir igual.
vec3 luz_lineal(vec3 c) {
	c = max(c, vec3(0.0));
	return mix(pow((c + 0.055) * (1.0 / 1.055), vec3(2.4)), c * (1.0 / 12.92), lessThan(c, vec3(0.04045)));
}

vec3 luz_srgb(vec3 c) {
	c = max(c, vec3(0.0));
	return mix(1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, c * 12.92, lessThan(c, vec3(0.0031308)));
}

// Una luz que llega por `l` con color `col` (ya atenuado) y `brillo` de
// especular: el difuso de LAMBERT a `dif` y el GGX a `esp` (D_GGX, V_GGX y el
// Fresnel con f90, como Godot; el 1/π de los dos se va con el π que Godot mete
// en el color de la luz). `a` es rug².
//
// LAMBERT, NO BURLEY (arreglo tras la gira 6). En Compatibility un sombreador
// sin `diffuse_burley` cae en el `#else` de `scene.glsl`, que es Lambert (la
// skill `prueba-3d` lo cuenta con la piedra). Con Burley y la luz detrás de la
// cámara, lo que se mira de canto sale hasta 2,5 veces más claro (el término
// 1 + (2·ldh²·rug − 0,5)·(1 − n·v)⁵, por dos): en la mesa, el jirón de la
// izquierda, que se ve de lado, salía más claro (toma `c0_v5_00`: 117,8 de
// luminancia con Burley, 115,1 con Lambert; la gira 5, 108, y lo que falta es el
// azar del ruido de su deshilachado, no la luz). Y Lambert compila antes.
void luz_una(vec3 l, vec3 col, float brillo, vec3 n, vec3 v, float a,
		float f0, float f90, out vec3 dif, out vec3 esp) {
	float ndl = max(dot(n, l), 0.0);
	vec3 c = col * ndl;
	dif = c;
#ifdef ESPECTRO_LUZ_SIN_BRILLO
	esp = vec3(0.0);
#else
	vec3 h = normalize(v + l);
	float ndh = clamp(dot(n, h), 0.0, 1.0);
	float ldh = clamp(dot(l, h), 0.0, 1.0);
	float ndv = max(dot(n, v), 0.0001);
	float k = a / (1.0 - ndh * ndh + ndh * ndh * a * a);
	float g = 0.5 / mix(2.0 * ndl * ndv, ndl + ndv, a);
	float f5 = 1.0 - ldh;
	float f52 = f5 * f5;
	float f = f0 + (f90 - f0) * f52 * f52 * f5;
	esp = c * (k * k * g * f * brillo);
#endif
}

// xyz: HACIA la luz, en el mundo, unitario; w: 1 si Godot la pinta aparte
// (tiene sombra).
uniform vec4 luz_dir[4];
// rgb: lo que le llega de ella (color lineal × energía × atenuación); a: cuánto
// especular (lo que Godot llama `specular_amount`).
uniform vec4 luz_col[4];

// Lo que se escribe en ALBEDO en vez de ALBEDO y EMISSION. `albedo` y `emision`
// como se le daban a Godot (en sRGB); `n` y `v` (hacia la cámara) en el MUNDO;
// `especular` y `rug` son el SPECULAR y el ROUGHNESS de antes.
vec3 luz_propia(vec3 albedo, vec3 emision, vec3 n, vec3 v, float especular, float rug) {
	float f0 = 0.16 * especular * especular;
	float f90 = clamp(50.0 * f0, 0.0, 1.0);
	float a = rug * rug;
	vec3 alb = luz_lineal(albedo);
	vec3 d0, d1, d2, d3, e0, e1, e2, e3;
	luz_una(luz_dir[0].xyz, luz_col[0].rgb, luz_col[0].a, n, v, a, f0, f90, d0, e0);
	luz_una(luz_dir[1].xyz, luz_col[1].rgb, luz_col[1].a, n, v, a, f0, f90, d1, e1);
	// Las cuatro CON brillo, como en Godot. Se le quitó a las dos más flojas («el
	// destello de una luz floja no se ve») y no vale: van ordenadas por lo que
	// le dan al CENTRO, y la tercera de la mesa es el fuego de detrás, que no
	// alumbra casi la cara pero es el que enciende, a contraluz y con el Fresnel,
	// el filo claro de la coronilla (toma `c0_v5_00`: sin su brillo, en lo alto
	// del cuerpo la desviación cae de 28,7 a 24,1).
	luz_una(luz_dir[2].xyz, luz_col[2].rgb, luz_col[2].a, n, v, a, f0, f90, d2, e2);
	luz_una(luz_dir[3].xyz, luz_col[3].rgb, luz_col[3].a, n, v, a, f0, f90, d3, e3);
	vec4 w = vec4(luz_dir[0].w, luz_dir[1].w, luz_dir[2].w, luz_dir[3].w);
	vec3 dif = d0 * w.x + d1 * w.y + d2 * w.z + d3 * w.w;
	vec3 esp = e0 * w.x + e1 * w.y + e2 * w.z + e3 * w.w;
	vec3 junta = alb * (luz_ambiente + d0 + d1 + d2 + d3 - dif)
		+ (e0 + e1 + e2 + e3 - esp) + luz_lineal(emision);
	return luz_srgb(junta) + luz_srgb(alb * dif + esp);
}
