class_name HojaAnimada
extends RefCounted

## UNA HOJA DE FOTOGRAMAS, que es lo que el juego no sabía leer.
##
## Hasta esta tanda todo bicho era UN sprite estático deformado por código
## (`NodoEnemigo`: respiración y embestida son squash/stretch en píxeles
## enteros, sin un solo fotograma de verdad). `assets/criaturas_anim/` llevaba
## dos criaturas cortadas, limpias y con sus ocho fotogramas **sin que las
## cargara nadie**: la misma avería del wav generado y no enganchado, con otra
## cara. Esto es lo que las carga.
##
## LOS FOTOGRAMAS SON PNG SUELTOS, no un atlas. Es lo que escupe `procesar.py`
## y lo que ya hay en disco, y un atlas obligaría a un paso de empaquetado más
## que no compra nada: a 64 px la diferencia de memoria es ruido.
##
## EL NOMBRE ES EL CONTRATO: `<estado>_<n>.png`, con n empezando en 1, que es
## exactamente lo que pide `--nombres` en `assets/prompts_animacion.md` §4 y §5.
##
## EL CATÁLOGO SE ESCRIBE A MANO Y LA BATERÍA LO SUJETA. Es el mismo trato que
## `NodoSonido.AJUSTES`: la tabla dice lo que el juego pide, y hay una prueba
## que comprueba que no queda ninguna carpeta en disco fuera de ella. Una hoja
## generada y no enganchada no da ningún error — deja un bicho quieto, y eso se
## diagnostica como "el arte no se nota".

const CARPETA := "res://assets/criaturas_anim/"

## El estado al que se vuelve siempre. Si una hoja no tiene una fila, se cae
## aquí (ver `Reproductor`), porque un sprite en blanco no da error.
const QUIETO := "idle"

## Los estados de un solo tiro: se piden, se reproducen enteros y se acaban.
## Los demás (hoy solo `idle`) van en bucle.
const UNA_VEZ := ["golpe", "ataque", "muerte"]

## `muerte` NO vuelve a `idle`: se queda clavada en el último fotograma y deja
## que la disolución del shader haga el resto. Un bicho que muere y vuelve a
## respirar mientras se disuelve es exactamente lo que no se quiere ver.
const SE_QUEDA := "muerte"

## Cadencias, en fotogramas por segundo.
##
## **TIENEN QUE DIVIDIR A 60 SIN RESTO.** No es purismo: con una cadencia que no
## divide, el reproductor gasta unos fotogramas en 3 ticks y otros en 4, y a
## ocho fotogramas de bucle eso se ve como un cojeo — la misma familia que la
## rejilla de píxeles, pero en el tiempo. 10 → 6 ticks, 20 → 3, 15 → 4, 12 → 5.
const FPS := {
	"idle": 10.0,
	"golpe": 20.0,
	"ataque": 15.0,
	"muerte": 12.0,
}

## QUÉ HOJAS PIDE EL JUEGO, y qué filas trae cada una. Hoy son dos criaturas con
## solo `idle`, que es lo que hay generado (`assets/prompts_animacion.md` §4:
## las presas de §5 van detrás de la puerta B de `CAZA.md`). Cuando entren las
## otras siete, se añaden aquí y la prueba deja de protestar.
const CATALOGO := {
	"cr_brasa": ["idle"],
	"cr_calavera": ["idle"],
}

var id := ""
## estado -> Array[Texture2D], en orden.
var filas := {}

static var _cache := {}

## La hoja de una criatura, o null si no está en el catálogo. Cacheada: la
## pantalla de preparación la pide cada fotograma.
static func de(el_id: String) -> HojaAnimada:
	if el_id == "" or not CATALOGO.has(el_id):
		return null
	if _cache.has(el_id):
		return _cache[el_id] as HojaAnimada
	var h := HojaAnimada.new()
	h.id = el_id
	for estado in CATALOGO[el_id]:
		var lista: Array[Texture2D] = []
		var n := 1
		while true:
			var ruta := "%s%s/%s_%d.png" % [CARPETA, el_id, str(estado), n]
			if not ResourceLoader.exists(ruta):
				break
			var tex := load(ruta) as Texture2D
			if tex == null:
				break
			lista.append(tex)
			n += 1
		if not lista.is_empty():
			h.filas[str(estado)] = lista
	_cache[el_id] = h
	return h

func tiene(estado: String) -> bool:
	return filas.has(estado) and not (filas[estado] as Array).is_empty()

func cuantos(estado: String) -> int:
	return (filas[estado] as Array).size() if tiene(estado) else 0

## El fotograma i de un estado. Sin envolver: envolver es trabajo del
## reproductor, que es quien sabe si el estado va en bucle o de un solo tiro.
func fotograma(estado: String, i: int) -> Texture2D:
	if not tiene(estado):
		return null
	var lista := filas[estado] as Array
	return lista[clampi(i, 0, lista.size() - 1)] as Texture2D

static func fps_de(estado: String) -> float:
	return float(FPS.get(estado, FPS[QUIETO]))

static func va_en_bucle(estado: String) -> bool:
	return not UNA_VEZ.has(estado)
