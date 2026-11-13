shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

// ÓRBITA — el aro de una criatura, pintado en el cristal debajo de ella. Es su
// único indicador y va DONDE SE MIDE, pegado al bicho, no en un panel.
//
//   · LUMI: se llena como un reloj con el MIEDO, de verde a rojo.
//   · Rendida (acorralada o panza arriba): late, y el aro se va VACIANDO con el
//     tiempo que queda para recogerla.
//   · TANQUE: en vez de miedo enseña la CORAZA, un arco que marca por dónde no
//     le entra la bola. Lo que no está iluminado es por donde hay que darle.

uniform float miedo = 0.0;
uniform float rendida = 0.0;
uniform float aviso = 0.0;
uniform float escudo = 0.0;
uniform vec2 direccion = vec2(0.0, 1.0);
uniform float arco = 1.22;
uniform float choque = 0.0;
uniform vec3 color_calma : source_color = vec3(0.30, 1.0, 0.45);
uniform vec3 color_panico : source_color = vec3(1.0, 0.16, 0.10);
uniform vec3 color_escudo : source_color = vec3(0.55, 0.85, 1.0);

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float aro = smoothstep(0.74, 0.80, r) * smoothstep(0.98, 0.92, r);
	float pulso = 0.5 + 0.5 * sin(TIME * 13.0);
	vec3 col;
	float luz;
	if (escudo > 0.5) {
		// El frente blindado: un arco ancho hacia donde mira.
		float dentro = dot(p / max(r, 0.001), normalize(direccion));
		float frente = smoothstep(cos(arco) - 0.06, cos(arco) + 0.02, dentro);
		float banda = smoothstep(0.66, 0.74, r) * smoothstep(1.0, 0.94, r);
		col = mix(color_escudo, vec3(1.0), choque);
		luz = banda * frente * (0.75 + choque * 2.5) + aro * 0.10;
	} else {
		// De 0 a 1 dando la vuelta en el sentido del reloj, empezando por el
		// lado que da a la camara: es el que el cuerpo no tapa.
		float a = atan(p.x, -p.y) / 6.2831853 + 0.5;
		float lleno = step(a, miedo);
		col = mix(color_calma, color_panico, smoothstep(0.25, 0.95, miedo));
		luz = aro * (0.14 + 0.86 * lleno);
	}
	if (rendida > 0.5) {
		col = mix(color_panico, vec3(1.0, 0.9, 0.7), pulso * 0.5);
		luz += pulso * smoothstep(0.98, 0.0, r) * 0.45 + aro * pulso * 0.8;
	}
	luz += aviso * smoothstep(0.98, 0.3, r) * 0.5;
	ALBEDO = col * luz * 2.0;
}
