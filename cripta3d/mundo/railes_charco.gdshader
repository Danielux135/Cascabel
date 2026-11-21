shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

// EL CHARCO ÁMBAR de una flecha encendida: lo que deja en la losa la luz de sus
// bombillas. No es una luz (el presupuesto es de once omnis y una flecha no
// merece una): es un cuadro aditivo pegado al suelo, con una caída suave desde el
// centro. Todas las flechas van en la misma malla; cada cuadro dice en `UV2.y` de
// qué guía es (el mismo índice que sus bombillas) y `luz` trae lo encendida que
// está cada una. `UV` va de −1 a 1 sobre el cuadro.

uniform vec3 color : source_color = vec3(1.0, 0.55, 0.18);
uniform float fuerza = 0.55;
uniform float luz[16];

varying float v_luz;

void vertex() {
	int g = clamp(int(UV2.y + 0.5), 0, 15);
	v_luz = luz[g];
}

void fragment() {
	vec2 q = UV;
	// Alargado a lo largo de la flecha (UV.x), como la propia flecha.
	float r = length(q * vec2(0.85, 1.15));
	float caida = 1.0 - smoothstep(0.15, 1.0, r);
	caida *= caida;
	ALBEDO = color * caida * v_luz * fuerza;
}
