class_name CatalogoRecuperable
extends RefCounted

## Carga `data/recuperable.json`: lo que se puede recuperar del disco, o sea el
## contenido de la carpeta `RECUPERADO` del escritorio (`PROPÓSITO.md` §2).
##
## Mismo patrón que `CatalogoReliquias`: la lectura de fichero vive en `data/`
## para que `sim/` no toque el sistema de archivos.
##
## LA TRAMPA QUE ESTE FICHERO TIENE QUE EVITAR, y está en `CLAUDE.md`: un dato
## mal escrito en un JSON no da error, deja una pieza que no hace nada. Aquí eso
## sería una pieza imposible de recuperar, y el jugador lo diagnosticaría como
## "el juego no me da nada". Por eso hay pruebas que comprueban que alguien LEE
## cada clave y que los sprites declarados existen de verdad.

const RUTA := "res://data/recuperable.json"

class Pieza extends RefCounted:
	var id: String = ""
	var tipo: String = ""
	var nombre: String = ""
	var fichero: String = ""
	var sprite: String = ""
	var inicial: bool = false
	var texto: String = ""

	func _init(d: Dictionary) -> void:
		id = str(d.get("id", ""))
		tipo = str(d.get("tipo", ""))
		nombre = str(d.get("nombre", ""))
		fichero = str(d.get("fichero", ""))
		sprite = str(d.get("sprite", ""))
		inicial = bool(d.get("inicial", false))
		texto = str(d.get("texto", ""))

	## Dónde vive el dibujo de esta pieza, o "" si no lleva. Las cáscaras y las
	## criaturas están en carpetas distintas y con tamaños distintos: la cáscara
	## se dibuja pequeña porque rueda, la criatura a 64 porque es el retrato.
	## LOS TAMAÑOS NO SON CAPRICHO: en la carpeta se dibujan a 16, así que la
	## fuente tiene que dividir por un entero o el icono hierve. `bolas_64` y
	## `criaturas_64` son ÷4 y los iconos del sistema ÷2. La carpeta `bolas/`, que
	## es la que usa la mesa, mide 24 y NO vale aquí: 24→16 es ×0,66.
	func ruta_sprite() -> String:
		match tipo:
			"cascabel":
				return "res://assets/bolas_64/%s.png" % sprite if sprite != "" else ""
			"criatura":
				return "res://assets/criaturas_64/%s.png" % sprite if sprite != "" else ""
			"registro":
				# Un registro es texto: no tiene dibujo propio y lleva el icono
				# de fichero del sistema, como en un explorador de verdad.
				return "res://assets/ui/iconos/registro.png"
		return ""

	## Lo que se lee en la carpeta cuando NO la tienes. No es "bloqueado": es un
	## fichero que el sistema sabe que estuvo ahí y ya no puede leer. La longitud
	## se conserva para que el hueco tenga forma —ocho interrogantes donde había
	## ocho letras se lee como un nombre perdido, no como una casilla vacía.
	func nombre_ilegible() -> String:
		var punto := fichero.rfind(".")
		var base := fichero if punto < 0 else fichero.substr(0, punto)
		var ext := "" if punto < 0 else fichero.substr(punto)
		return "?".repeat(base.length()) + ext

static var _cache: Array = []

static func cargar() -> Array:
	if not _cache.is_empty():
		return _cache
	var lista: Array = []
	var f := FileAccess.open(RUTA, FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir %s" % RUTA)
		return lista
	var crudo: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(crudo) != TYPE_DICTIONARY or not (crudo as Dictionary).has("piezas"):
		push_error("%s no tiene la forma esperada" % RUTA)
		return lista
	for datos in (crudo as Dictionary)["piezas"]:
		lista.append(Pieza.new(datos as Dictionary))
	_cache = lista
	return lista

static func por_id(el_id: String) -> Pieza:
	for p in cargar():
		if (p as Pieza).id == el_id:
			return p
	return null

static func por_tipo(el_tipo: String) -> Array:
	var lista: Array = []
	for p in cargar():
		if (p as Pieza).tipo == el_tipo:
			lista.append(p)
	return lista

## Las que se pueden ganar jugando: todo lo que no viene de fábrica.
static func recuperables() -> Array:
	var lista: Array = []
	for p in cargar():
		if not (p as Pieza).inicial:
			lista.append(p)
	return lista

## Las que hay que dar la primera vez que alguien abre el juego. Se aplican al
## cargar el guardado, no al crearlo: así, si mañana una pieza pasa a ser inicial,
## los guardados que ya existen también la reciben.
static func sembrar(g: Guardado) -> void:
	for p in cargar():
		if (p as Pieza).inicial:
			g.recuperar((p as Pieza).id)

## LA SIGUIENTE PIEZA QUE TOCA, y es determinista a propósito: en el orden del
## JSON, la primera que no tengas. Un sorteo daría la sensación de tragaperras y,
## peor, podría repetir el mismo hueco tres runs seguidos; en orden, cada run
## avanza un escalón visible y el jugador ve cuál es el siguiente antes de
## ganárselo. Devuelve "" si ya está todo.
static func siguiente_para(g: Guardado) -> String:
	for p in recuperables():
		if not g.tiene((p as Pieza).id):
			return (p as Pieza).id
	return ""
