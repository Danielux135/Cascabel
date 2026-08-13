class_name NodoSuelo
extends Node2D

## El suelo y los adornos, en su propia capa.
##
## Están aquí y no en el `_draw` de la vista por una razón concreta: el enemigo
## necesita nodo propio (lleva shader) y tiene que quedar ENTRE el suelo y el
## resto. Un solo CanvasItem no se puede partir por la mitad, así que las capas
## quedan por z_index: suelo (-2), enemigo (-1), y todo lo demás en la vista (0).

const C_MESA := Paleta.MESA
const C_CABINA := Paleta.CABINA
const C_HUECO := Paleta.HUECO

var vista: VistaMesa
var _tex_suelo: Texture2D
var _tex_deco: Dictionary = {}

func _init(la_vista: VistaMesa) -> void:
	vista = la_vista
	z_index = -2
	# El suelo tesela una baldosa de 128x128: hace falta repetición de textura.
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func _ready() -> void:
	_tex_suelo = load("res://assets/mesa_suelo/suelo_piedra.png")
	for adorno in VistaMesa.ADORNOS:
		var nombre: String = adorno["tex"]
		if not _tex_deco.has(nombre):
			_tex_deco[nombre] = load("res://assets/mesa_deco/%s.png" % nombre)

func _draw() -> void:
	# El fondo de cabina va aquí y no en la vista: allí es un rect opaco a z 0
	# y taparía estas capas enteras.
	draw_rect(Rect2(0, 0, Mesa.ANCHO, Mesa.ALTO), C_CABINA)
	_dibujar_suelo()
	_dibujar_adornos()
	# EL MULTIPLICADOR YA NO SE DIBUJA AQUÍ. Se ha mudado dentro de la tele
	# (`render/nodo_tele.gd`), que ocupa ese mismo sitio: es la misma información
	# en el mismo punto de la mesa, pero ahora con un mueble alrededor que sirve
	# además para la ruleta de la recompensa. Dibujarlo en los dos sitios lo
	# pintaba dos veces.

## Baldosa de 128x128 que repite sin costuras, teselada sobre todo el campo.
func _dibujar_suelo() -> void:
	# La zona alta es hueco de raíl, no mesa: se queda oscura.
	draw_rect(VistaMesa.ZONA_ALTA, C_HUECO)
	draw_rect(VistaMesa.CAMPO, C_MESA)      # base por si faltara la textura
	if _tex_suelo != null:
		draw_texture_rect(_tex_suelo, VistaMesa.CAMPO, true)

func _dibujar_adornos() -> void:
	for adorno in VistaMesa.ADORNOS:
		var tex: Texture2D = _tex_deco.get(adorno["tex"])
		if tex == null:
			continue
		var escala: float = adorno["escala"]
		var ancho: float = -escala if adorno["espejo"] else escala
		var mitad := Vector2(tex.get_width(), tex.get_height()) * 0.5
		draw_set_transform((adorno["pos"] as Vector2).round(), 0.0,
			Vector2(ancho, escala))
		draw_texture(tex, -mitad)
		draw_set_transform_matrix(Transform2D.IDENTITY)
