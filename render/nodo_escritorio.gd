class_name NodoEscritorio
extends CanvasLayer

## El escritorio de TILT OS detrás de la mesa, en una capa fija que no se mueve
## con la cámara.
##
## OJO: esto NO es la cáscara. Es solo el fondo, para que los 560 px que sobran
## a los lados de la mesa no sean un vacío negro mientras se ajusta la cámara.
## Ventanas, barra de tareas y botón Inicio son la fase 5, y esos 560 px (280
## por lado) son justo el sitio donde van.
##
## El fondo es 320x180 y la ventana 960x540: exactamente x3, así que se dibuja
## con escalado entero y no se rompe ningún píxel. Y no se cuantiza a la paleta
## de la mazmorra, que no es la suya.

const C_VACIO := Paleta.CABINA

var _tex: Texture2D
var _lienzo: Node2D
var _p: ParametrosCamara
var _anim: ParametrosAnimacion

func _init(parametros: ParametrosCamara, animacion: ParametrosAnimacion) -> void:
	_p = parametros
	_anim = animacion
	layer = -10

func _ready() -> void:
	_tex = load("res://assets/shell/fondo_escritorio.png")
	_lienzo = Node2D.new()
	_lienzo.draw.connect(_dibujar)
	add_child(_lienzo)
	_lienzo.queue_redraw()

func _dibujar() -> void:
	# El rect sale del viewport DE VERDAD, no de ancho_visible. Con
	# stretch/aspect="expand" el viewport crece cuando la pantalla no da 16:9
	# exacto, y dibujando sobre 960x540 fijos quedaba una banda gris a la
	# derecha: el fondo no llegaba al borde.
	var pantalla := _lienzo.get_viewport_rect().size
	var rect := Rect2(Vector2.ZERO, pantalla.ceil())
	_lienzo.draw_rect(rect, C_VACIO)
	if _tex != null:
		# La textura es 320x180 y se sube por ENTEROS, nunca por 3,04: un
		# escalado fraccionario aquí hierve los píxeles del fondo. Se coge el
		# múltiplo entero que cubre la pantalla y se centra; lo que sobresale
		# se sale por los lados, que es donde luego van las ventanas.
		var tam := Vector2(_tex.get_width(), _tex.get_height())
		var escala := maxf(ceilf(pantalla.x / tam.x), ceilf(pantalla.y / tam.y))
		var destino := tam * escala
		var esquina := ((pantalla - destino) * 0.5).floor()
		_lienzo.draw_texture_rect(_tex, Rect2(esquina, destino), false)
	# Apagado general durante el combate.
	_lienzo.draw_rect(rect, Color(C_VACIO, _anim.escritorio_oscurecido))
	# El fondo no se mueve con la cámara, pero sí cambia si cambia la ventana.
	if not get_viewport().size_changed.is_connected(_lienzo.queue_redraw):
		get_viewport().size_changed.connect(_lienzo.queue_redraw)
	# Y unos escalones más oscuros pegados al borde, para cerrar el encuadre
	# hacia el centro. En pasos de píxel entero, como todo lo demás.
	var pasos := 4
	for i in pasos:
		var grosor := _anim.escritorio_borde_ancho - i * (_anim.escritorio_borde_ancho / pasos)
		var alfa := _anim.escritorio_borde / float(pasos)
		_lienzo.draw_rect(Rect2(0, 0, grosor, rect.size.y), Color(C_VACIO, alfa))
		_lienzo.draw_rect(Rect2(rect.size.x - grosor, 0, grosor, rect.size.y),
			Color(C_VACIO, alfa))
