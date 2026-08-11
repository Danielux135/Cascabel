class_name NodoHud
extends CanvasLayer

## El HUD, en capa fija: con la cámara vertical, si se dibujara en el mundo se
## iría con el scroll.
##
## Todo va dentro de la franja de la mesa (x 280..680 en pantalla) para que se
## lea como parte del juego y no invada el escritorio de los lados.

const C_CABINA      := Paleta.CABINA
const C_ORO         := Paleta.ORO
const C_ORO_CLARO   := Paleta.ORO_CLARO
const C_GOMA_LUZ    := Paleta.GOMA_LUZ
const C_TEXTO       := Paleta.TEXTO
const C_TEXTO_TENUE := Paleta.TEXTO_TENUE
const C_VERDE       := Paleta.VERDE

## Atrapes tras los cuales se deja de dar la pista de cómo atrapar.
const VECES_PARA_APRENDER := 3

var vista: VistaMesa
var _p: ParametrosCamara
var _fuente: Font
var _lienzo: Node2D
## Borde izquierdo de la mesa en pantalla.
var _izq: float = 120.0

func _init(la_vista: VistaMesa, parametros: ParametrosCamara) -> void:
	vista = la_vista
	_p = parametros
	layer = 10

func _ready() -> void:
	_fuente = ThemeDB.fallback_font
	_izq = (_p.ancho_visible - Mesa.ANCHO) * 0.5
	_lienzo = Node2D.new()
	_lienzo.draw.connect(_dibujar)
	add_child(_lienzo)

func _process(_delta: float) -> void:
	_lienzo.queue_redraw()

func _barra(rect: Rect2, proporcion: float, color: Color) -> void:
	_lienzo.draw_rect(rect, C_CABINA)
	_lienzo.draw_rect(Rect2(rect.position,
		Vector2(rect.size.x * clampf(proporcion, 0.0, 1.0), rect.size.y)), color)

func _texto(pos: Vector2, txt: String, tam: int, col: Color,
		alineado: int = HORIZONTAL_ALIGNMENT_LEFT, ancho: float = -1.0) -> void:
	_lienzo.draw_string(_fuente, pos, txt, alineado, ancho, tam, col)

func _dibujar() -> void:
	var combate := vista.combate
	if combate == null:
		return
	var mesa := vista.mesa
	var d := _izq

	# Franja de arriba: enemigo y jugador, sobre el ancho de la mesa.
	_lienzo.draw_rect(Rect2(d, 0, Mesa.ANCHO, 58), Color(C_CABINA, 0.82))

	var e := combate.enemigo
	if e != null:
		_texto(Vector2(d + 12, 16), e.nombre, 10, C_TEXTO)
		_texto(Vector2(d, 16), "%d/%d" % [e.vida, e.vida_maxima], 10, C_TEXTO_TENUE,
			HORIZONTAL_ALIGNMENT_RIGHT, Mesa.ANCHO - 12)
		var col_enemigo := C_GOMA_LUZ if vista.flash_enemigo <= 0.0 else C_ORO_CLARO
		_barra(Rect2(d + 12, 22, Mesa.ANCHO - 24, 8),
			float(e.vida) / float(e.vida_maxima), col_enemigo)

	var col_jugador := C_VERDE if vista.flash_jugador <= 0.0 else C_GOMA_LUZ
	_texto(Vector2(d + 12, 46),
		"VIDA %d/%d" % [combate.vida_jugador, combate.p.vida_jugador], 9, C_TEXTO)
	_barra(Rect2(d + 78, 40, 94, 7),
		float(combate.vida_jugador) / float(combate.p.vida_jugador), col_jugador)
	_texto(Vector2(d + 200, 46),
		"ESTA BOLA  %d  (%d golpes)" % [combate.dano_de_la_bola, combate.golpes],
		9, C_ORO_CLARO if combate.dano_de_la_bola > 0 else C_TEXTO_TENUE)

	_dibujar_reloj(combate, d)
	_dibujar_mensaje(combate, mesa, d)

	_texto(Vector2(d + 12, _p.alto_visible - 8),
		"A/D flippers  ESPACIO lanzar  R otro run  F1 colisiones",
		8, C_TEXTO_TENUE)

## El reloj del enemigo, pegado al fondo de la franja y a todo lo ancho. Va ahí
## y no en un rincón porque es la presión del combate: si no se ve de reojo sin
## dejar de mirar la bola, no sirve de nada.
##
## En la cuenta atrás parpadea. El parpadeo va por tramos enteros de tiempo, no
## por seno, para que no haya medio píxel de color a medio camino.
func _dibujar_reloj(combate: Combate, d: float) -> void:
	var avisando := combate.reloj_restante() <= combate.p.reloj_aviso
	var col := C_GOMA_LUZ
	if avisando:
		var parpadeo := int(combate.reloj_restante() * 6.0) % 2 == 0
		col = C_ORO_CLARO if parpadeo else C_GOMA_LUZ
	_barra(Rect2(d + 12, 49, Mesa.ANCHO - 24, 6), combate.carga_reloj, col)

func _dibujar_mensaje(combate: Combate, mesa: Mesa, d: float) -> void:
	var texto := ""
	var col := C_TEXTO
	match combate.fase:
		Combate.Fase.LANZANDO:
			if mesa.bola.viva and mesa.bola.en_carril:
				texto = "ESPACIO: mantener y soltar para lanzar"
				col = C_TEXTO_TENUE
		Combate.Fase.BOLA_VIVA:
			# El golpe del reloj no para el juego, así que el aviso es lo único
			# que lo anuncia. Sin esto se lee como un mordisco de la nada.
			if combate.reloj_restante() <= combate.p.reloj_aviso:
				texto = "ATAQUE EN %d" % int(ceil(combate.reloj_restante()))
				col = C_ORO_CLARO
			elif mesa.flipper_atrapando != null:
				texto = "BOLA ATRAPADA"
				col = C_TEXTO_TENUE
			# AQUÍ IBA LA PISTA de "mantén A o D para atrapar y apuntar", y se
			# quitó: está medido que desde la cuna el tiro sube 40 px y no llega
			# a ninguna boca. Enseñar una técnica que no sirve es peor que no
			# enseñar nada. Vuelve cuando la cuna dispare de verdad.
		Combate.Fase.DRENADA:
			texto = "BOLA PERDIDA  ·  COMBO A x1"
			col = C_TEXTO_TENUE
		Combate.Fase.RESOLVIENDO_ATAQUE:
			texto = "%s ATACA  -%d" % [
				combate.enemigo.nombre.to_upper(), combate.ultimo_ataque]
			col = C_GOMA_LUZ
		Combate.Fase.VICTORIA:
			texto = "VICTORIA"
			col = C_VERDE
		Combate.Fase.DERROTA:
			texto = "DERROTA"
			col = C_GOMA_LUZ
	if texto == "":
		return
	var y := _p.alto_visible * 0.5
	_texto(Vector2(d, y), texto, 14, col, HORIZONTAL_ALIGNMENT_CENTER, Mesa.ANCHO)
	if combate.terminado():
		_texto(Vector2(d, y + 20), "ENTER para volver al mapa",
			9, C_TEXTO_TENUE, HORIZONTAL_ALIGNMENT_CENTER, Mesa.ANCHO)
