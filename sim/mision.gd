class_name Mision
extends RefCounted

## Una misión de mesa: la lista de tiros que hay que encadenar para ganarte una
## reliquia. `DISEÑO.md` §4 y §10, revisados.
##
## DE DÓNDE VIENE: del pinball del XP y de Pokémon Pinball. En los dos, el
## display te dice SIEMPRE qué toca ahora, y lo que ganas lo ganas jugando la
## mesa, no en un menú. Aquí pasa lo mismo: la tele anuncia la misión, tú la
## completas con las palas, y la ruleta te paga.
##
## LO QUE ARREGLA, que es más de lo que parece:
##   · Las reliquias se ganan en la mesa, no al ganar el combate.
##   · Un combate de tres minutos deja de ser un saco de vida. Sin misión, un
##     enemigo largo es el mismo minuto repetido tres veces; con ella hay una
##     escalera con un siguiente escalón siempre visible.
##   · El margen por habilidad se paga en objetos: quien aguanta la bola sube
##     tres escalones en un combate y quien no, uno. `DISEÑO.md` §2.
##
## Los nombres de tiro son los que emite `Mesa` y cuenta `Combate`:
##   bumper · girador · target · banco · orbita · retorno · canon · platillo

## Cuánto paga completarla. Es la rareza de la reliquia que sortea la ruleta.
enum Rareza { COMUN, RARA, ARCANA }

## LA CLAVE con la que la rareza viene escrita en el JSON. Es un identificador:
## va sin tilde y no se toca, porque cambiarla rompe los ficheros de datos.
const NOMBRE_RAREZA := {
	Rareza.COMUN: "comun",
	Rareza.RARA: "rara",
	Rareza.ARCANA: "arcana",
}

## CÓMO SE ESCRIBE en pantalla. Un identificador y un rótulo no son la misma
## cadena, y usar el identificador para pintar es lo que ponía **"COMUN"** en la
## tele desde que existen las misiones: la fuente sabe dibujar la Ú, pero nadie
## se la estaba pidiendo. Misma trampa en `tiro`: "canon" y "orbita" son claves,
## y salían así escritas encima de las casillas de progreso.
const ROTULO_RAREZA := {
	Rareza.COMUN: "común",
	Rareza.RARA: "rara",
	Rareza.ARCANA: "arcana",
}

## Los tiros que puede pedir una misión, con su nombre bien escrito. La clave es
## la que emite `Mesa`; el valor es lo que lee el jugador.
const ROTULO_TIRO := {
	"bumper": "bumper",
	"girador": "girador",
	"target": "target",
	"banco": "banco",
	"orbita": "órbita",
	"retorno": "retorno",
	"canon": "cañón",
	"platillo": "platillo",
}

var id: String
var nombre: String
## Qué hay que hacer, en lenguaje de jugador y corto: cabe en la tele.
var texto: String
var rareza: int
## `[{"tiro": "banco", "veces": 2}, ...]`
var tiros: Array = []
## Si hay que hacerlos EN ORDEN. Un tiro que no toca no rompe nada, simplemente
## no cuenta: romper el progreso por fallar un tiro castiga dos veces —ya has
## perdido la posición— y es lo que hace que la gente deje de intentar la misión.
var orden: bool
## Si drenar reinicia el progreso. Es lo que separa una misión arcana de una
## rara sin pedir más tiros: aguantar la bola es la habilidad, `DISEÑO.md` §2.
var sin_drenar: bool

func _init(datos: Dictionary) -> void:
	id = str(datos.get("id", ""))
	nombre = str(datos.get("nombre", "?"))
	texto = str(datos.get("texto", ""))
	rareza = int(datos.get("rareza", Rareza.COMUN))
	tiros = (datos.get("tiros", []) as Array).duplicate(true)
	orden = bool(datos.get("orden", false))
	sin_drenar = bool(datos.get("sin_drenar", false))

func nombre_rareza() -> String:
	return str(NOMBRE_RAREZA.get(rareza, "?"))

## Para PINTAR. `nombre_rareza()` es la clave del JSON y no se lee en pantalla.
func rotulo_rareza() -> String:
	return str(ROTULO_RAREZA.get(rareza, "?"))

## El rótulo del paso `i`, bien escrito. Si el tiro no está en la tabla se
## devuelve la clave: mejor "girador" mal puesto que un hueco.
func rotulo_tiro(i: int) -> String:
	var clave := tiro(i)
	return str(ROTULO_TIRO.get(clave, clave))

static func rareza_desde(texto_rareza: String) -> int:
	for clave in NOMBRE_RAREZA:
		if str(NOMBRE_RAREZA[clave]) == texto_rareza:
			return int(clave)
	return Rareza.COMUN

## Cuántas veces pide el paso `i`.
func veces(i: int) -> int:
	return int((tiros[i] as Dictionary).get("veces", 1))

func tiro(i: int) -> String:
	return str((tiros[i] as Dictionary).get("tiro", ""))
