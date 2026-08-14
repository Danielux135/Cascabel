class_name NodoEnemigo
extends Node2D

## El enemigo va en su propio nodo porque necesita material propio: en Godot el
## material es por CanvasItem, no por comando de dibujo, y el destello y la
## disolución son shader.
##
## YA NO VIVE EN LA MESA. Estaba dentro del campo de juego, con z_index −1 para
## colarse entre el suelo y todo lo demás; ahora lo cuelga `NodoPanelEnemigo` de
## una capa de pantalla, dentro del panel `enemigo.exe` de la banda derecha. Este
## nodo no sabe dónde está: dibuja donde le digan que están los pies, y por eso
## sirve igual en coordenadas de mundo (la prueba de respiración) que en
## coordenadas de pantalla (el juego).
##
## Todo lo que deforma o mueve el sprite va en píxeles enteros.

const RUTA_SHADER := "res://render/enemigo.gdshader"

var p: ParametrosAnimacion
var textura: Texture2D
## Los pies del enemigo. La respiración pivota aquí: crece hacia arriba.
var suelo := Vector2(200, 158)
var flota := false

var _tiempo := 0.0
var _destello := 0.0
var _disolucion := 0.0
var _muriendo := false
## 0 = quieto, sube a 1 en la ida de la embestida y vuelve a 0.
var _embestida := 0.0
var _embestida_subiendo := false
var _material: ShaderMaterial

func _init(parametros: ParametrosAnimacion) -> void:
	p = parametros
	z_index = -1
	_material = ShaderMaterial.new()
	_material.shader = load(RUTA_SHADER)
	material = _material

func configurar(tex: Texture2D, es_flotante: bool) -> void:
	textura = tex
	flota = es_flotante
	_tiempo = 0.0
	_destello = 0.0
	_disolucion = 0.0
	_muriendo = false
	_embestida = 0.0
	_embestida_subiendo = false
	if tex != null:
		_material.set_shader_parameter("tam_textura",
			Vector2(tex.get_width(), tex.get_height()))

func recibir_dano() -> void:
	_destello = 1.0

func embestir() -> void:
	_embestida_subiendo = true

func morir() -> void:
	_muriendo = true
	_destello = 1.0

func disuelto() -> bool:
	return _muriendo and _disolucion >= 1.0

func _process(delta: float) -> void:
	_tiempo += delta
	if _destello > 0.0:
		_destello = maxf(_destello - delta / p.destello_duracion, 0.0)
	if _muriendo:
		_disolucion = minf(_disolucion + delta / p.disolucion_duracion, 1.0)
	if _embestida_subiendo:
		_embestida += delta / p.embestida_ida
		if _embestida >= 1.0:
			_embestida = 1.0
			_embestida_subiendo = false
	elif _embestida > 0.0:
		_embestida = maxf(_embestida - delta / p.embestida_vuelta, 0.0)

	_material.set_shader_parameter("destello", _destello)
	_material.set_shader_parameter("color_destello", p.destello_color)
	_material.set_shader_parameter("disolucion", _disolucion)
	_material.set_shader_parameter("borde_disolucion", p.disolucion_borde)
	_material.set_shader_parameter("color_borde", p.disolucion_color_borde)
	queue_redraw()

## Squash y stretch en pasos de píxel entero: el alto sube y baja un número
## entero de píxeles y el ancho hace lo contrario, para que parezca que
## conserva volumen. El borde de abajo no se mueve: el pivote son los pies.
func _paso_respiracion() -> int:
	if _muriendo or p.respiracion_pixeles <= 0:
		return 0
	var fase := _tiempo / p.respiracion_periodo * TAU
	return int(roundf(sin(fase) * float(p.respiracion_pixeles)))

## Vaivén de los que flotan y empujón de la embestida, los dos en enteros.
func _desplazamiento() -> float:
	var d := 0.0
	if flota:
		var fase := _tiempo / p.flotante_periodo * TAU
		d += -float(p.flotante_altura) + roundf(sin(fase) * float(p.flotante_pixeles))
	d += roundf(_embestida * float(p.embestida_pixeles))
	return d

## El rectángulo con el que se dibuja el sprite ahora mismo. Es público para
## poder comprobar en headless las dos cosas que importan: que todo cae en
## píxeles enteros y que los pies no se mueven al respirar.
func rect_dibujo() -> Rect2:
	if textura == null:
		return Rect2()
	var paso := _paso_respiracion()
	var ancho := textura.get_width() - paso
	var alto := textura.get_height() + paso
	var esquina := Vector2(
		suelo.x - float(ancho) * 0.5,
		suelo.y - float(alto) + _desplazamiento())
	return Rect2(esquina.round(), Vector2(ancho, alto))

func _draw() -> void:
	if textura == null or disuelto():
		return
	draw_texture_rect(textura, rect_dibujo(), false)
