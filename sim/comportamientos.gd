class_name Comportamientos
extends RefCounted

## LO QUE HACE UN ENEMIGO ADEMÁS DE TENER VIDA (`DISEÑO.md` §11, Fase 6).
##
## *"Uno con más vida no es un enemigo nuevo. Cada uno altera qué tiro
## compensa."* Con combates de dos minutos un enemigo que solo tiene vida y un
## ataque se nota que es un saco, y el barrido de `medir_daniel.gd` lleva desde
## la tanda del rebalance diciendo que con un ataque por reloj no hay tabla que
## deje el run en la banda de dificultad que se busca.
##
## LA FORMA ES LA DE `Estados`, no la de las reliquias. Una reliquia es una
## bolsa de modificadores, y `CLAUDE.md` tiene escrito por qué eso no vale aquí:
## *"un modificador NO es una mecánica"* —una bolsa solo sabe producir
## porcentajes—. Y meter al enemigo en la bolsa del jugador obligaría a sacarlo
## al acabar el combate, que es la trampa del estado que se enciende en un sitio
## y hay que apagar en otro. Así que:
##
##   - **los datos** son filas en `data/enemigos.json`, `"comportamientos":
##     [{"id": ...}]`, con claves opcionales que pisan el parámetro con nombre
##     de `ParametrosCombate`;
##   - **el estado** vive aquí y se rehace entero en cada `preparar`, que llama
##     `Combate.iniciar` al lado de `estados.limpiar()`: los comportamientos no
##     cruzan de un combate a otro;
##   - **`Combate` pregunta** en los sitios donde ya tomaba la decisión, y CON LA
##     LISTA VACÍA CADA PREGUNTA DEVUELVE EL NEUTRO EXACTO —el mismo 1.0, el
##     mismo daño—: es lo que deja las medidas viejas valiendo.
##
## Y NADA DE AQUÍ GASTA AZAR. El dado del crítico se tira en cada golpe contra el
## RNG de la bolsa, así que una tirada de más desplazaría todos los críticos del
## resto del run y ninguna medida volvería a ser comparable.

## Los que existen. Lista CERRADA: un id mal escrito en el JSON no da error, deja
## un enemigo que no hace nada, y eso se diagnostica como balance. Hay prueba.
const IDS := ["caza_acelera"]

## Las claves que cada uno sabe leer del JSON, además de `id`. Misma razón: una
## clave mal escrita no pisa nada y nadie se entera. Hay prueba.
const CLAVES := {
	"caza_acelera": ["factor"],
}

var p: ParametrosCombate
## id -> Dictionary con los números ya resueltos (el del JSON si lo trae, si no
## el parámetro con nombre).
var activos: Dictionary = {}

## Prepara los comportamientos de un enemigo y deja el estado a cero. `lista` es
## lo que trae `Enemigo.comportamientos`; los ids que no existen se ignoran (la
## batería es la que los caza, no la partida: una fila rota no puede tumbarla).
func preparar(lista: Array, parametros: ParametrosCombate) -> void:
	p = parametros if parametros != null else ParametrosCombate.new()
	activos.clear()
	for fila in lista:
		if typeof(fila) != TYPE_DICTIONARY:
			continue
		var d := fila as Dictionary
		var el_id := str(d.get("id", ""))
		if not IDS.has(el_id):
			continue
		activos[el_id] = _resolver(el_id, d)

func tiene(el_id: String) -> bool:
	return activos.has(el_id)

func vacio() -> bool:
	return activos.is_empty()

## Los números de cada uno: lo que traiga la fila del JSON o, si no, el
## parámetro con nombre. Así un enemigo puede llevar su propia variante sin que
## el número quede escrito a mano en el código.
func _resolver(el_id: String, fila: Dictionary) -> Dictionary:
	var r := {}
	match el_id:
		"caza_acelera":
			r["factor"] = float(fila.get("factor", p.caza_factor_reloj))
	return r

# ------------------------------------------------------- acelera al cazar

## (6) ACELERA SU RELOJ CUANDO SUBES A CAZAR: *"castiga farmear"*. Subir ya
## cuesta reloj —el del enemigo no para mientras estás arriba, `DISEÑO.md` §5—,
## y este enemigo lo cobra más caro: la caza es un bonus, pero contra él no es
## gratis.
##
## Se le pasa `en_caza` en cada llamada en vez de encenderse con
## `caza_empezada`: la caza se corta al servir bola nueva sin pasar por
## `_terminar_caza`, y un booleano propio se quedaba puesto. Es la regla de la
## música. Y lo llama SOLO `Combate.ritmo_reloj()`, que es el único sitio del que
## salen la barra, los segundos que se enseñan y lo que roba el platillo.
func factor_reloj(en_caza: bool) -> float:
	if not en_caza or not activos.has("caza_acelera"):
		return 1.0
	return maxf(float(activos["caza_acelera"]["factor"]), 0.0)

# ------------------------------------------------------------- lo que se ve

## Lo que el panel del enemigo escribe de cada comportamiento: un rótulo y una
## línea de detalle. Un comportamiento que no se ve no existe —es la avería del
## platillo de `CLAUDE.md`—, y además es lo que le dice al jugador qué tiro le
## compensa contra este enemigo, que es para lo que están.
##
## `en_caza` hace falta para encender el que está actuando ahora mismo.
func rotulos(en_caza: bool) -> Array:
	var salida: Array = []
	for el_id in IDS:
		if not activos.has(el_id):
			continue
		match el_id:
			"caza_acelera":
				salida.append({"rotulo": "ACELERA", "detalle": "en la caza",
					"activo": en_caza})
	return salida
