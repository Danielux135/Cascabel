class_name NodoCursor
extends CanvasLayer

## EL PUNTERO DEL SISTEMA FALSO.
##
## Existe porque el arte estaba recortado desde la tanda anterior y sin conectar,
## y porque un escritorio con tooltips que se abren al pasar el ratón enseñaba el
## puntero DEL SISTEMA DE VERDAD: una flecha suave y antialiaseada encima de una
## cáscara de pixelart. Es exactamente el fallo de la fuente del sistema —
## material mezclado— y se ve igual de mal.
##
## SE DIBUJA, NO SE PONE CON `set_custom_mouse_cursor`. La diferencia importa: el
## cursor del sistema se dibuja en píxeles de PANTALLA, así que en 1080p una
## flecha de 12x18 sale cuatro veces más pequeña que todo lo demás y vuelve a
## desentonar. Dibujado aquí va en coordenadas del viewport, o sea que lo escala
## el mismo entero que escala el resto del juego.
##
## Va en la capa 100, por encima incluso de la pantalla azul: un puntero que se
## esconde detrás de algo es un puntero perdido.

## La punta de la flecha está en su esquina de arriba a la izquierda: ahí es
## donde apunta de verdad, y donde tiene que caer la posición del ratón. Los
## otros dos son símbolos y van centrados.
const PUNTA_FLECHA := Vector2(0, 0)

var vista: VistaMesa
var _lienzo: Node2D
var _flecha: Texture2D
var _reloj: Texture2D
var _ocupado: Texture2D
## Si no hay arte no se toca el ratón del sistema: es peor quedarse sin puntero
## que tener uno que no pega.
var _hay_arte := false

func _init(la_vista: VistaMesa) -> void:
	vista = la_vista
	layer = 100

func _ready() -> void:
	_flecha = _cargar("res://assets/ui/cursor/flecha.png")
	_reloj = _cargar("res://assets/ui/cursor/reloj.png")
	_ocupado = _cargar("res://assets/ui/cursor/ocupado.png")
	_hay_arte = _flecha != null
	_lienzo = Node2D.new()
	_lienzo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_lienzo.draw.connect(_dibujar)
	add_child(_lienzo)

static func _cargar(ruta: String) -> Texture2D:
	return load(ruta) as Texture2D if ResourceLoader.exists(ruta) else null

func _process(_delta: float) -> void:
	if not _hay_arte:
		return
	# Solo se esconde el puntero de verdad mientras la ventana tiene el foco. Sin
	# esta condición, al cambiar de ventana con alt-tab el ratón desaparece
	# dentro del área del juego y hay que adivinar dónde está.
	var foco := get_window() != null and get_window().has_focus()
	var quiere := Input.MOUSE_MODE_HIDDEN if foco else Input.MOUSE_MODE_VISIBLE
	if Input.get_mouse_mode() != quiere:
		Input.set_mouse_mode(quiere)
	_lienzo.queue_redraw()

func _exit_tree() -> void:
	# Que el ratón no se quede escondido si esta capa se va antes que el juego.
	if _hay_arte:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

## Qué puntero toca. Es el chiste de siempre de un sistema operativo: el reloj de
## arena sale cuando el programa está haciendo algo y tú no puedes tocar nada, y
## aquí eso es exactamente la ruleta.
func textura() -> Texture2D:
	if vista != null and vista.run != null and vista.run.terminada() and _ocupado != null:
		return _ocupado
	if vista != null and vista.en_ruleta() and _reloj != null:
		return _reloj
	return _flecha

func _dibujar() -> void:
	if not _hay_arte:
		return
	var foco := get_window() != null and get_window().has_focus()
	if not foco:
		return
	var tex := textura()
	if tex == null:
		return
	var tam := Vector2(tex.get_width(), tex.get_height())
	var punta := PUNTA_FLECHA if tex == _flecha else (tam * 0.5).floor()
	# En píxeles enteros, como todo: a medio píxel el puntero hierve igual que
	# hierve la mesa.
	var donde := (_lienzo.get_local_mouse_position() - punta).floor()
	_lienzo.draw_texture_rect(tex, Rect2(donde, tam), false)
