shader_type spatial;
// LUZ POR VÉRTICE (nov-2026, para la web): con `specular_disabled` y el ruido de
// valor por código tardaba 3,6 s en compilar con ANGLE (banco, en frío); la luz
// por vértice cuesta 0,86 de base. La tiza tiene que seguir APAGÁNDOSE en lo
// oscuro como la losa que pisa —no brilla sola—, así que no puede ir sin luz: va
// por vértice, y para que la luz de un fuego cercano no se interpole a lo largo
// de un plano de 0,8 de lado con solo cuatro esquinas, `calavera.gd` lo
// subdivide (16 × 16). La sombra se sigue mirando por píxel.
render_mode blend_mix, depth_draw_never, cull_back, vertex_lighting;

// CRIPTA — lo que la calavera lleva pintado en el suelo. En ÓRBITA era un aro de
// neón; aquí es TIZA sobre la losa, como el cerco de un conjuro, y recibe la luz
// y la sombra de la cripta igual que la piedra que tiene debajo. No brilla.
//
//   · EL ARCO DEL FRENTE (escudo): dos rayas, una gruesa y otra fina, cerradas
//     en las puntas, hacia donde mira. Es por donde NO le entra la bola. Con
//     `choque` se repasa de golpe —la tiza recién marcada es más blanca—.
//   · EL CERCO (circulo): cuando la vuelcan, un círculo entero con doce marcas,
//     como un reloj. Se va BORRANDO con el tiempo que le queda (`queda`): lo
//     borrado deja el fantasma de la tiza, y al final lo que queda tiembla.
//   · LA SOMBRA de contacto, que en Compatibility no la pone nadie más, y la
//     mancha negra de cuando sale del suelo.

uniform vec3 color : source_color = vec3(0.96, 0.91, 0.81);
uniform float escudo = 0.0;
uniform vec2 direccion = vec2(0.0, 1.0);
uniform float arco = 1.22;
uniform float choque = 0.0;
/// 0 a 1: blindada. El arco grueso, con las rayas del rebote.
uniform float rebote = 0.0;
uniform float circulo = 0.0;
uniform float queda = 1.0;
uniform float aviso = 0.0;
uniform float contacto = 0.0;
uniform float fosa = 0.0;
uniform float semilla = 0.0;
/// EL CERCO DE RENDIDA no es tiza blanca: es el aro que dice «recógeme», el
/// mismo papel que el aro del espectro acorralado. Blanco y sin luz se perdía en la
/// losa a oscuras y la volcada no se leía (crítica de juego, nov-2026): va en oro
/// y con un pelo de luz propia, que pulsa.
uniform vec3 color_cerco : source_color = vec3(0.97, 0.85, 0.42);
uniform float luz_cerco = 0.0;
/// Dónde va el cerco (1 = el borde del plano). Era 0,80 y en oro: la calavera se
/// rinde casi siempre sobre la rosa, y su aro caía ENCIMA del anillo dorado del
/// mosaico y se leía como parte de él (crítica de juego, remate nov-2026). Ahora
/// va más pegado a ella, de hueso claro (lo pone `calavera.gd`), con un contorno
/// oscuro que lo despega de lo que tenga debajo, y late en grosor y en luz.
uniform float radio_cerco = 0.60;
/// El grano de la casa (`cripta3d/texturas/ruido_grano.png`): lo pone `calavera.gd`.
uniform sampler2D tex_grano : filter_linear_mipmap_anisotropic, repeat_enable;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	vec2 u = p / max(r, 0.001);
	float ang = atan(p.x, -p.y);
	float vuelta = ang / 6.2831853 + 0.5;
	// El grano de la tiza: la losa es rugosa y la tiza solo se queda en lo alto.
	// Antes eran dos ruidos de valor, 0,55 a 70 casillas por unidad de `p` y 0,45
	// a 190; ahora, dos lecturas del relieve fino del grano de la casa (R), a 1,2
	// y 2,4 teselas por unidad: su octava más fina (160 por tesela) cae a 190 y
	// 380, y el resto de sus octavas pone el bulto que ponía el de 70. Pasado al
	// reparto de aquel por sus percentiles (medidos: con mediana 0,671 → 0,5 y
	// pendiente 1,15 coinciden el 5 % y el 25 % de los dos). Probado y descartado:
	// una lectura a 0,5 teselas (la tiza salía lisa) y otra a 0,45 (los hoyos del
	// grano, a esa escala, mordían la raya a bocados y no a motas).
	float g = 0.5 + ((texture(tex_grano, (p + semilla) * 1.2).r - 0.671) * 0.55
		+ (texture(tex_grano, (p + semilla) * 2.4 + vec2(0.37, 0.61)).r - 0.671) * 0.45) * 1.15;

	// --- El arco del frente -----------------------------------------------------
	float hacia = dot(u, normalize(direccion));
	float dentro = smoothstep(cos(arco) - 0.05, cos(arco) + 0.01, hacia);
	// El pulso de la mano: el radio y el grosor no son de compás.
	float r_arco = 0.91 + 0.012 * sin(ang * 5.0 + semilla) + 0.008 * sin(ang * 11.0 + 2.0);
	float raya = 1.0 - smoothstep(0.013, 0.027, abs(r - r_arco));
	// Por dentro, una segunda raya más fina: dos trazos son una barrera, uno es
	// una raya cualquiera.
	float r_fina = r_arco - 0.085 + 0.007 * sin(ang * 7.0 + semilla * 2.0);
	float fina = 1.0 - smoothstep(0.005, 0.014, abs(r - r_fina));
	// Y el remate en cada punta, que las cierra.
	float punta = (1.0 - smoothstep(0.010, 0.026, abs(hacia - cos(arco)) * r))
		* smoothstep(r_fina - 0.03, r_fina - 0.01, r) * (1.0 - smoothstep(r_arco + 0.02, r_arco + 0.04, r));
	// BLINDADA (`rebote`): el arco se repasa grueso y le salen rayas hacia fuera,
	// como el cerco de la volcada pero abierto: «por aquí, la bola rebota». En una
	// foto fija es lo que la separa del reposo.
	float gruesa = 1.0 - smoothstep(0.022, 0.040, abs(r - r_arco));
	float paso_ang = arco / 4.5;
	float cerca_raya = abs(fract(ang / paso_ang + 0.5) - 0.5) * paso_ang * r;
	float rayo = (1.0 - smoothstep(0.012, 0.024, cerca_raya))
		* smoothstep(r_arco + 0.022, r_arco + 0.034, r)
		* (1.0 - smoothstep(r_arco + 0.060 - 0.015 * g, r_arco + 0.072, r));
	float t_rebote = max(gruesa, rayo) * dentro * rebote;
	float t_arco = max(max(raya, fina * 0.75) * dentro, punta) * escudo;
	t_arco *= 0.50 + 0.50 * choque;
	t_arco = max(t_arco, t_rebote);

	// --- El cerco de cuando está volcada ------------------------------------------
	float r_cerco = radio_cerco + 0.016 * sin(ang * 3.0 + semilla * 1.7) + 0.009 * sin(ang * 8.0 + 0.7)
		+ 0.005 * sin(ang * 17.0 + 4.0);
	// El latido: «recógeme» no se está quieto. Más grueso y más claro a golpes.
	float latido = 0.5 + 0.5 * sin(TIME * 6.0);
	// Grueso: es lo que se tiene que ver desde la cámara de juego, a 40 píxeles.
	float grosor = 0.024 + 0.010 * latido;
	float anillo = 1.0 - smoothstep(grosor, grosor + 0.016, abs(r - r_cerco));
	// El contorno oscuro a los dos lados del trazo: lo separa del oro de la rosa.
	float contorno = (1.0 - smoothstep(grosor + 0.030, grosor + 0.052, abs(r - r_cerco)));
	float doce = floor(vuelta * 12.0 + 0.5);
	float al_lado = abs(vuelta * 12.0 - doce) * r * 0.5236;
	float marca = (1.0 - smoothstep(0.014, 0.026, al_lado))
		* smoothstep(r_cerco + 0.060, r_cerco + 0.080, r)
		* (1.0 - smoothstep(r_cerco + 0.155, r_cerco + 0.175, r));
	// Lo que aún no se ha borrado. El final del trazo tiembla cuando queda poco.
	float prisa = (1.0 - smoothstep(0.0, 0.35, queda)) * (0.5 + 0.5 * sin(TIME * 17.0));
	float viva_raya = 1.0 - smoothstep(queda - 0.006, queda + 0.006, vuelta);
	float viva_marca = step(doce / 12.0, queda - 0.001) * step(0.5, doce);
	float fantasma = 0.16;
	float t_cerco = anillo * mix(fantasma, 1.0 - prisa * 0.45, viva_raya)
		+ marca * mix(fantasma, 1.0, viva_marca);
	// Se dibuja de una pasada al caer: el trazo da la vuelta.
	float trazado = (1.0 - smoothstep(circulo - 0.02, circulo + 0.02, vuelta)) * step(0.001, circulo);
	t_cerco *= trazado;
	// El contorno va con lo que queda vivo del trazo (el fantasma no lo lleva).
	contorno *= trazado * viva_raya * 0.62;

	// --- La tiza -----------------------------------------------------------------
	float tiza = max(t_arco, t_cerco);
	tiza *= smoothstep(0.22, 0.52, g + tiza * 0.30);
	tiza = clamp(tiza * (0.72 + aviso * 0.6), 0.0, 1.0);

	// --- Lo oscuro: la sombra de contacto y la fosa ---------------------------------
	float sombra = contacto * 0.55 * (1.0 - smoothstep(0.10, 0.56, r));
	// El borde de la fosa, mordido: el moteado del grano (A, ecualizado) leído en
	// un círculo, unas diez mordidas por vuelta como el `ruido2(u·3)` de antes.
	float muerde = texture(tex_grano, u * 0.25 + vec2(semilla * 0.37, 0.5)).a;
	float borde = r + (muerde - 0.5) * 0.07 + (g - 0.5) * 0.05;
	float hoyo = fosa * (1.0 - smoothstep(0.36, 0.50, borde));
	float oscuro = max(max(sombra, hoyo), contorno);

	float alfa = max(tiza, oscuro * (1.0 - tiza));
	// Cuánto de lo pintado aquí es el cerco (y no el arco del frente).
	float del_cerco = t_cerco / max(max(t_arco, t_cerco), 0.001);
	vec3 pintura = mix(color, color_cerco, del_cerco) * (0.80 + 0.20 * g);
	ALBEDO = mix(vec3(0.004, 0.004, 0.006), pintura, tiza / max(alfa, 0.001));
	EMISSION = color_cerco * luz_cerco * tiza * del_cerco * (0.45 + 0.55 * latido);
	ROUGHNESS = 1.0;
	ALPHA = alfa * (1.0 - smoothstep(0.985, 1.0, r));
}
