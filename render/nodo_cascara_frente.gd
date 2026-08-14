class_name NodoCascaraFrente
extends CanvasLayer

## LA MITAD DE LA CÁSCARA QUE VA DELANTE DE LA MESA.
##
## Existe por un fallo que estaba a la vista y no se veía. La cáscara vive en la
## capa −10, o sea detrás de todo, y `NodoSuelo` pinta un rectángulo de cabina
## OPACO sobre los 400 px de ancho de la mesa, de arriba abajo de la pantalla.
## Así que todo lo que la cáscara dibujaba en esa columna quedaba tapado:
##
## - **La barra de título de la ventana de la mesa**, con su "cascabel.exe" y sus
##   tres botones, no se veía nunca. De la ventana solo sobrevivían las cuatro
##   tiras de 8 px que sobresalen por los lados.
## - **La barra de tareas** quedaba partida por la mitad. Se salvaba de milagro:
##   el botón Inicio, la pestaña del proceso y el reloj caen todos fuera de la
##   columna de la mesa, así que lo único que se perdía era el mueble del medio.
##
## Es la avería de siempre —un sistema que el jugador no ve no existe— y el
## docstring de `NodoCascara` ya prometía esta capa desde la primera pasada. Lo
## que faltaba era la capa, no el dibujo.
##
## Aquí va lo que TIENE que ir por encima de la mesa: el marco de su ventana, la
## barra de tareas (una barra de tareas de verdad está siempre encima de todo) y
## el tooltip de las reliquias, que puede desbordar hacia la mesa y cortado no se
## lee. Lo que se queda detrás es lo que nunca pisa la columna de la mesa: el
## fondo, los iconos de las dos bandas y los paneles de la derecha.
##
## No dibuja nada por su cuenta: le pide el dibujo a la cáscara, que es la dueña
## de la geometría y de los marcos. Dos sitios midiendo la misma pantalla es
## exactamente lo que descuadró el encuadre en el portátil de Daniel.

var cascara: NodoCascara
var _lienzo: Node2D

func _init(la_cascara: NodoCascara) -> void:
	cascara = la_cascara
	# Por delante de la mesa (0) y por detrás del enemigo (8), del HUD (10), del
	# mapa (20) y de TILT (40).
	layer = 5

func _ready() -> void:
	_lienzo = Node2D.new()
	_lienzo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Los marcos se REPITEN, no se estiran: sin repetición de textura los bordes
	# saldrían escalados y el pixelart se rompe.
	_lienzo.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_lienzo.draw.connect(_dibujar)
	add_child(_lienzo)

func _process(_delta: float) -> void:
	_lienzo.queue_redraw()

func _dibujar() -> void:
	if cascara == null:
		return
	cascara.dibujar_marco_mesa(_lienzo)
	cascara.dibujar_barra_tareas(_lienzo)
	cascara.dibujar_tooltip(_lienzo)
