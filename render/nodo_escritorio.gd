class_name NodoEscritorio
extends CanvasLayer

## El escritorio de TILT OS detrás de la mesa, en una capa fija que no se mueve
## con la cámara.
##
## OJO: esto NO es la cáscara. Es solo el fondo, para que los ~240 px que
## sobran a los lados de la mesa no sean un vacío negro mientras se ajusta la
## cámara. Ventanas, barra de tareas y botón Inicio son la fase 5.
##
## El fondo es 320x180 y la ventana 640x360: exactamente x2, así que se dibuja
## con escalado entero y no se rompe ningún píxel. Y no se cuantiza a la paleta
## de la mazmorra, que no es la suya.

const C_VACIO := Color("14121A")

var _tex: Texture2D
var _lienzo: Node2D
var _p: ParametrosCamara

func _init(parametros: ParametrosCamara) -> void:
	_p = parametros
	layer = -10

func _ready() -> void:
	_tex = load("res://assets/shell/fondo_escritorio.png")
	_lienzo = Node2D.new()
	_lienzo.draw.connect(_dibujar)
	add_child(_lienzo)
	_lienzo.queue_redraw()

func _dibujar() -> void:
	var rect := Rect2(0, 0, _p.ancho_visible, _p.alto_visible)
	_lienzo.draw_rect(rect, C_VACIO)
	if _tex != null:
		_lienzo.draw_texture_rect(_tex, rect, false)
