extends Node
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
## En escritorio no se usa —el proyecto arranca en el juego—, pero se puede
## probar: `res://cripta3d/puerta_web.tscn -- --mesa=cripta`.

const MESAS := {
	"orbita": "res://prueba3d/prueba_3d.tscn",
	"cripta": "res://cripta3d/cripta_3d.tscn",
}
const POR_DEFECTO := "orbita"

func _ready() -> void:
	var escena := elegir(_pedida())
	# Diferido: cambiar de escena desde el `_ready` de la que está entrando es un
	# error («parent node is busy»), y a la siguiente vuelta ya no lo es.
	get_tree().change_scene_to_file.call_deferred(escena)

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

## La escena de la mesa pedida. Lo que no se conoce —o nada— es la de siempre:
## un enlace mal escrito no deja a nadie delante de una página en negro.
static func elegir(pedida: String) -> String:
	return MESAS.get(pedida.strip_edges().to_lower(), MESAS[POR_DEFECTO])
