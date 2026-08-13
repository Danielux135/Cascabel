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

const NOMBRE_RAREZA := {
	Rareza.COMUN: "comun",
	Rareza.RARA: "rara",
	Rareza.ARCANA: "arcana",
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
