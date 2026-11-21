extends Control
## LA PUERTA DEL BUILD WEB DE LAS PRUEBAS 3D.
##
## El build «Web 3D» lleva las dos pruebas dentro, y esta escena es la que
## arranca en él (`run/main_scene.prueba3d` en `project.godot`): mira la
## dirección de la página y abre la mesa que se le pide.
##
##     https://danielux.es/cascabel-3d/                 ÓRBITA, como siempre
##     https://danielux.es/cascabel-3d/?mesa=cripta     CRIPTA
##
## POR QUÉ ASÍ. Un sitio de proyecto de Pages vive bajo el nombre de su repo:
## otra dirección sería otro repo y otra receta. Con un mando en la dirección la
## página es la misma, la receta que publica no se toca, y quien tenía el enlace
## de ÓRBITA sigue viendo ÓRBITA. Los demás mandos (`?calidad=`, `?medir=1`) los
## lee luego cada mesa, y se juntan con `&`: `?mesa=cripta&calidad=alta`.
##
## CRIPTA depende de `prueba3d/` (la caza y las criaturas son las de ÓRBITA), así
## que no podía ir en un build aparte sin llevársela igual.
##
## Antes de abrir la mesa pinta UN fotograma con su nombre: montar CRIPTA son
## unos segundos de página parada, y sin esto serían unos segundos en negro.
##
## En escritorio no se usa —el proyecto arranca en el juego—, pero se puede
## probar: `res://cripta3d/puerta_web.tscn -- --mesa=cripta`.

const MESAS := {
	"orbita": "res://prueba3d/prueba_3d.tscn",
	"cripta": "res://cripta3d/cripta_3d.tscn",
}
const ROTULOS := {"orbita": "Ó R B I T A", "cripta": "C R I P T A"}
const POR_DEFECTO := "orbita"

const FONDO := Color(0.027, 0.031, 0.047)
const HUESO := Color(0.93, 0.89, 0.80)

var _mesa := POR_DEFECTO

func _ready() -> void:
	# Para repartir el arranque en frío al medirlo desde fuera: en qué milisegundo
	# de la página llega el motor hasta aquí (las mesas apuntan los demás hitos).
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(window.__hitos = window.__hitos || {})['puerta'] = Math.round(performance.now())", true)
	_mesa = clave(_pedida())
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# El proyecto escala por enteros (es lo suyo para el pixelart del juego) y en
	# una pestaña el rótulo saldría diminuto: lo mismo que hace cada mesa.
	get_window().content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	resized.connect(queue_redraw)
	queue_redraw()
	# Dos fotogramas: el primero dibuja el rótulo y el segundo lo enseña. Cambiar
	# de escena desde el `_ready` de la que está entrando, además, es un error.
	await get_tree().process_frame
	await get_tree().process_frame
	# Si la mesa pedida no abre, la de siempre: mejor ÓRBITA que el rótulo eterno.
	if get_tree().change_scene_to_file(MESAS[_mesa]) != OK and _mesa != POR_DEFECTO:
		get_tree().change_scene_to_file(MESAS[POR_DEFECTO])

func _draw() -> void:
	# El primer dibujo puede llegar antes de que la ventana le dé tamaño, y una
	# letra de cuerpo cero es un error por la salida.
	if size.y < 8.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), FONDO)
	var letra := ThemeDB.fallback_font
	var u := size.y / 540.0
	_centrado(letra, ROTULOS[_mesa], size * 0.5 + Vector2(0.0, -34.0 * u), int(40.0 * u), HUESO)
	_centrado(letra, "MONTANDO LA MESA", size * 0.5 + Vector2(0.0, 30.0 * u), int(11.0 * u),
		Color(HUESO, 0.75))

func _centrado(letra: Font, texto: String, donde: Vector2, cuerpo: int, color: Color) -> void:
	var ancho := letra.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1.0, cuerpo).x
	draw_string(letra, donde - Vector2(ancho * 0.5, 0.0), texto,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, cuerpo, color)

## La mesa que se ha pedido, tal cual viene: por la dirección en web y por la
## línea de órdenes en escritorio. Vacío si no se ha pedido ninguna.
func _pedida() -> String:
	var pedida := ""
	if OS.has_feature("web"):
		pedida = de_la_consulta(str(JavaScriptBridge.eval("window.location.search", true)))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mesa="):
			pedida = arg.trim_prefix("--mesa=")
	return pedida

## «?calidad=alta&mesa=cripta» → «cripta». Vacío si no trae el mando.
static func de_la_consulta(consulta: String) -> String:
	for trozo in consulta.trim_prefix("?").split("&", false):
		var par := trozo.split("=")
		if par.size() == 2 and par[0] == "mesa":
			return par[1]
	return ""

## La mesa pedida, o la de siempre si no se conoce: un enlace mal escrito no
## deja a nadie delante de una página en negro.
static func clave(pedida: String) -> String:
	var limpia := pedida.strip_edges().to_lower()
	return limpia if MESAS.has(limpia) else POR_DEFECTO
