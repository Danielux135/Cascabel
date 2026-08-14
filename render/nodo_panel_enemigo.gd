class_name NodoPanelEnemigo
extends CanvasLayer

## EL ENEMIGO, FUERA DEL TABLERO.
##
## `PLAN.md` Fase 5: "enemigo en su panel". Hasta ahora vivía dentro del campo
## de juego, en `y=758` de la mesa, y eso tenía dos problemas de los que se
## notan jugando:
##
## 1. Con la cámara vertical anclada abajo, el enemigo se salía de plano casi
##    siempre. Un enemigo que solo se ve cuando la bola sube por la órbita no es
##    un enemigo, es un adorno de la zona alta.
## 2. Y el invariante dice que los enemigos normales viven FUERA del campo de
##    juego. Estaba dibujado dentro.
##
## Ahora vive en una capa de pantalla, dentro del panel `enemigo.exe` de la banda
## derecha, así que está siempre visible mientras juegas, que es lo que hace que
## se lea el destello al pegarle y la disolución al matarlo.
##
## Se lleva sus propias partículas: `Impactos` dibuja en el CanvasItem que se le
## pase, y las de la vista están en coordenadas de mundo. La explosión de la
## muerte tiene que salir donde está el bicho, no donde estaba antes.

var cascara: NodoCascara
var enemigo: NodoEnemigo
var efectos: Impactos

var _lienzo: Node2D

func _init(la_cascara: NodoCascara, anim: ParametrosAnimacion,
		impacto: ParametrosImpacto) -> void:
	cascara = la_cascara
	# Por encima de la mesa (0) y del marco de su ventana (5), por debajo del
	# HUD (10): el HUD escribe el nombre y la barra sobre este mismo panel.
	layer = 8
	enemigo = NodoEnemigo.new(anim)
	# Dentro de una capa de pantalla el z_index negativo que trae para colarse
	# entre el suelo y la mesa no pinta nada, y en −1 quedaría por debajo del
	# lienzo de efectos, que es justo al revés de lo que hace falta.
	enemigo.z_index = 0
	efectos = Impactos.new(impacto)

func _ready() -> void:
	_lienzo = Node2D.new()
	_lienzo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_lienzo.z_index = 1
	_lienzo.draw.connect(_dibujar)
	add_child(enemigo)
	add_child(_lienzo)

func configurar(tex: Texture2D, flota: bool) -> void:
	efectos.limpiar()
	enemigo.suelo = cascara.suelo_enemigo()
	enemigo.configurar(tex, flota)

func avanzar(delta: float) -> void:
	# La posición se refresca cada fotograma y no solo al empezar el combate: la
	# ventana puede cambiar de tamaño, y con `aspect = expand` cambia de verdad.
	enemigo.suelo = cascara.suelo_enemigo()
	efectos.avanzar(delta)
	_lienzo.queue_redraw()

## El centro del bicho, que es donde salen los efectos. No son los pies: una
## explosión a la altura de los pies parece que se lo traga el suelo.
func centro() -> Vector2:
	return cascara.suelo_enemigo() - Vector2(0.0, NodoCascara.LADO_RETRATO_PANEL * 0.5)

func _dibujar() -> void:
	efectos.dibujar(_lienzo)
