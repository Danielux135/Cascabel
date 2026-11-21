shader_type spatial;

// CRIPTA 3D · efectos · LAS ALMAS: jirones de luz que salen de la criatura
// capturada y se meten en la bola por la ranura.
//
// Cada alma es una tira que sigue a su cabeza (`efectos.gd` guarda sus últimos
// sitios), de cara a la cámara. No es una cinta de neón: el borde se deshace,
// la luz tiembla a lo largo como una llama fría y la cola se apaga antes de
// llegar a su punta. Color y fuerza vienen en el color de vértice; UV.x va de
// un borde al otro, UV.y de la cabeza (0) a la cola (1).

render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D tex_manchas : filter_linear_mipmap, repeat_enable;
uniform float energia = 1.7;

void fragment() {
	float x = abs(UV.x - 0.5) * 2.0;
	float tira = 1.0 - smoothstep(0.0, 1.0, x);
	float hebra = texture(tex_manchas, vec2(UV.x * 0.35 + COLOR.a * 3.1, UV.y * 1.7 - TIME * 1.3)).r;
	float temblor = smoothstep(0.2, 0.8, hebra);
	float cola = pow(1.0 - UV.y, 1.4);
	float a = tira * tira * mix(0.35, 1.0, temblor) * cola;
	// El corazón, más blanco: una luz de color pura parece pintura.
	vec3 c = mix(COLOR.rgb, vec3(1.0), tira * tira * tira * 0.35);
	ALBEDO = c * a * energia;
}
