shader_type canvas_item;

// ÓRBITA — lo último que pasa antes de la pantalla: una pizca de aberración
// cromática hacia las esquinas, viñeta y grano. Poco de cada cosa.

uniform float aberracion = 0.010;
uniform float vineta = 0.50;
uniform float grano = 0.030;

void fragment() {
	vec2 c = UV - 0.5;
	float d = dot(c, c);
	vec2 des = c * d * aberracion;
	vec3 col = vec3(
		texture(TEXTURE, UV + des).r,
		texture(TEXTURE, UV).g,
		texture(TEXTURE, UV - des).b);
	col *= 1.0 - vineta * smoothstep(0.10, 0.60, d);
	float n = fract(sin(dot(UV * 917.0 + TIME, vec2(12.9898, 78.233))) * 43758.5453);
	col += (n - 0.5) * grano;
	COLOR = vec4(col, 1.0);
}
