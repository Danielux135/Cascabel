class_name NodoTilt
extends CanvasLayer

## La pantalla de derrota: una pantalla azul de sistema, con volcado de error.
##
## **TILT es la palabra exacta y por eso funciona doble**: es lo que hace una
## máquina de pinball de verdad cuando alguien la empuja, y a la vez es un fallo
## del sistema. `DISEÑO.md` §3: perder no es morir, es que el gestor de
## excepciones captura el fallo. La broma solo funciona si se reconoce al
## instante, así que el azul es azul de verdad y el texto imita el tono seco de
## un volcado, no el de un juego diciéndote que has perdido.
##
## Y lo que de verdad tiene que leerse aquí NO es el cartel: es hasta dónde
## llegaste y con qué. El criterio de salida de la Fase 3C era "puedes perder en
## el cuarto combate y querer volver a intentarlo", y eso se sostiene con datos,
## no con un "has muerto".
##
## Aquí van también LOS DOS NÚMEROS que hacen falta para escribir la tabla de
## enemigos: el daño por bola de verdad y el combate medio. Se enseñan al perder
## porque es cuando el jugador está mirando la pantalla sin prisa.

const C_FONDO       := Paleta.TILT_FONDO
const C_TEXTO       := Paleta.TEXTO
const C_BLANCO      := Paleta.DESTELLO
const C_TEXTO_TENUE := Paleta.TEXTO_TENUE
const C_ORO_CLARO   := Paleta.ORO_CLARO
const C_GOMA_LUZ    := Paleta.GOMA_LUZ

var vista: VistaMesa
var _p: ParametrosCamara
var _fuente: Font
var _lienzo: Node2D

func _init(la_vista: VistaMesa, parametros: ParametrosCamara) -> void:
	vista = la_vista
	_p = parametros
	layer = 40
	visible = false

func _ready() -> void:
	_fuente = FuenteUI.obtener()
	_lienzo = Node2D.new()
	_lienzo.draw.connect(_dibujar)
	add_child(_lienzo)

func _process(_delta: float) -> void:
	_lienzo.queue_redraw()

func _dibujar() -> void:
	var run := vista.run
	if run == null:
		return
	var p := _lienzo.get_viewport_rect().size.ceil()
	_lienzo.draw_rect(Rect2(Vector2.ZERO, p), C_FONDO)

	var x := 72.0
	var y := 84.0
	# El cartel, en negativo, como los de verdad.
	var titulo := Rect2(x, y - 16.0, 60.0, 20.0)
	_lienzo.draw_rect(titulo, C_BLANCO)
	_lienzo.draw_string(_fuente, Vector2(x + 8.0, y - 2.0), "TILT",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, C_FONDO)

	y += 34.0
	for linea in _volcado(run):
		_lienzo.draw_string(_fuente, Vector2(x, y), str(linea),
			HORIZONTAL_ALIGNMENT_LEFT, p.x - x * 2.0, 8, C_BLANCO)
		y += 18.0

	y += 12.0
	# LA MEDIDA, que es lo que de verdad sirve para arreglar el juego. Sale aquí
	# y no en un menú de opciones porque aquí es donde el jugador mira.
	if run.combates_jugados > 0:
		_lienzo.draw_string(_fuente, Vector2(x, y),
			"daño por bola: %.0f      combate medio: %.0f s      bolas: %d" % [
				run.dano_por_bola(), run.segundos_por_combate(), run.bolas_jugadas],
			HORIZONTAL_ALIGNMENT_LEFT, p.x - x * 2.0, 8, C_ORO_CLARO)
		y += 24.0

	if not run.bolsa.vacia():
		_lienzo.draw_string(_fuente, Vector2(x, y),
			"módulos cargados: " + ", ".join(run.bolsa.nombres()),
			HORIZONTAL_ALIGNMENT_LEFT, p.x - x * 2.0, 8, C_TEXTO)
		y += 22.0

	_lienzo.draw_string(_fuente, Vector2(x, p.y - 60.0),
		"Pulsa R para reiniciar el proceso.",
		HORIZONTAL_ALIGNMENT_LEFT, p.x - x * 2.0, 8, C_BLANCO)

## El volcado. Es la premisa contada por mensajes de error, que es lo que
## `DISEÑO.md` §3 pide en vez de cinemáticas: cero coste y cuenta lo mismo.
func _volcado(run: Run) -> Array:
	var acto := run.mapa.acto_de_fila(maxi(run.fila, 0)) + 1
	return [
		"Se ha detectado un problema y cascabel.exe se ha detenido.",
		"",
		"EXCEPCION_NO_CONTROLADA  0x%04X   proceso: cascabel.exe" % (
			0x1000 + run.nodos_superados * 0x40 + acto),
		"El proceso se detuvo en el acto %d, nodo %d." % [acto, run.nodos_superados],
		"Integridad del contenedor: 0 de %d." % run.vida_maxima,
	]
