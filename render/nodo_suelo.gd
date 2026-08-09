class_name NodoSuelo
extends Node2D

## El suelo, los adornos y el número del combo, en su propia capa.
##
## Están aquí y no en el `_draw` de la vista por una razón concreta: el enemigo
## necesita nodo propio (lleva shader) y tiene que quedar ENTRE el suelo y el
## resto. Un solo CanvasItem no se puede partir por la mitad, así que las capas
## quedan por z_index: suelo (-2), enemigo (-1), y todo lo demás en la vista (0).

const C_MESA := Color("2A2A33")
const C_CABINA := Color("14121A")
const C_HUECO := Color("1C1A22")

var vista: VistaMesa
var _tex_suelo: Texture2D
var _tex_deco: Dictionary = {}
var _fuente: Font
var _pulso: float = 0.0

func _init(la_vista: VistaMesa) -> void:
	vista = la_vista
	z_index = -2
	# El suelo tesela una baldosa de 128x128: hace falta repetición de textura.
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func _ready() -> void:
	_fuente = ThemeDB.fallback_font
	_tex_suelo = load("res://assets/mesa_suelo/suelo_piedra.png")
	for adorno in VistaMesa.ADORNOS:
		var nombre: String = adorno["tex"]
		if not _tex_deco.has(nombre):
			_tex_deco[nombre] = load("res://assets/mesa_deco/%s.png" % nombre)

func pulsar() -> void:
	_pulso = 1.0

func _process(delta: float) -> void:
	_pulso = maxf(_pulso - delta * 2.6, 0.0)
	queue_redraw()

func _draw() -> void:
	# El fondo de cabina va aquí y no en la vista: allí es un rect opaco a z 0
	# y taparía estas capas enteras.
	draw_rect(Rect2(0, 0, Mesa.ANCHO, Mesa.ALTO), C_CABINA)
	_dibujar_suelo()
	_dibujar_adornos()
	_dibujar_combo()

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

## El multiplicador de combo, que es lo que más importa mientras juegas. Va
## pegado al suelo, por debajo de todo, así que nunca tapa el juego: lo que hace
## que se vea es que se enciende conforme sube.
func _dibujar_combo() -> void:
	var combate := vista.combate
	if combate == null or combate.enemigo == null:
		return
	var factor := combate.multiplicador()
	var estilo: Dictionary = VistaMesa.COMBO_ESTILO.get(factor,
		VistaMesa.COMBO_ESTILO[1])
	var col: Color = estilo["col"]
	col.a = float(estilo["alfa"]) * (1.0 if not combate.terminado() else 0.35)
	var escala := 1.0 + _pulso * 0.35

	draw_set_transform(VistaMesa.COMBO_CENTRO, 0.0, Vector2(escala, escala))
	draw_string(_fuente, Vector2(-100, 0), "x%d" % factor,
		HORIZONTAL_ALIGNMENT_CENTER, 200, VistaMesa.COMBO_TAMANO, col)
	draw_set_transform_matrix(Transform2D.IDENTITY)

	# Cuántos golpes faltan para el tramo siguiente: sin esto el número grande
	# sube de golpe y no sabes si te falta uno o doce.
	var siguiente := _golpes_para_subir(combate)
	if siguiente > 0 and not combate.terminado():
		draw_string(_fuente,
			Vector2(VistaMesa.COMBO_CENTRO.x - 100, VistaMesa.COMBO_CENTRO.y + 14),
			"%d para x%d" % [siguiente, factor + 1],
			HORIZONTAL_ALIGNMENT_CENTER, 200, 9, Color(col, col.a * 0.8))

## Golpes que faltan para el siguiente tramo, o 0 si ya está en el último.
func _golpes_para_subir(combate: Combate) -> int:
	var factor := combate.multiplicador()
	for tramo in combate.p.tramos_combo:
		if int((tramo as Dictionary)["factor"]) > factor:
			return int((tramo as Dictionary)["golpes"]) - combate.golpes
	return 0
