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
const IDS := ["cura", "castiga_combo", "caza_acelera"]

## Las claves que cada uno sabe leer del JSON, además de `id`. Misma razón: una
## clave mal escrita no pisa nada y nadie se entera. Hay prueba.
const CLAVES := {
	"cura": ["espera", "periodo", "fraccion"],
	"castiga_combo": ["desde", "factor_por_tramo", "tramos_robados"],
	"caza_acelera": ["factor"],
}

var p: ParametrosCombate
## id -> Dictionary con los números ya resueltos (el del JSON si lo trae, si no
## el parámetro con nombre).
var activos: Dictionary = {}

## (2) Segundos de juego sin que le toquen. Solo corre con la bola en juego.
var sin_tocar: float = 0.0

## Prepara los comportamientos de un enemigo y deja el estado a cero. `lista` es
## lo que trae `Enemigo.comportamientos`; los ids que no existen se ignoran (la
## batería es la que los caza, no la partida: una fila rota no puede tumbarla).
func preparar(lista: Array, parametros: ParametrosCombate) -> void:
	p = parametros if parametros != null else ParametrosCombate.new()
	activos.clear()
	sin_tocar = 0.0
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
		"cura":
			r["espera"] = maxf(float(fila.get("espera", p.cura_espera)), 0.0)
			r["periodo"] = maxf(float(fila.get("periodo", p.cura_periodo)), 0.05)
			r["fraccion"] = maxf(float(fila.get("fraccion", p.cura_fraccion)), 0.0)
		"castiga_combo":
			r["desde"] = maxi(int(fila.get("desde", p.castigo_desde)), 2)
			r["factor_por_tramo"] = maxf(float(fila.get("factor_por_tramo",
				p.castigo_factor_por_tramo)), 0.0)
			r["tramos_robados"] = maxi(int(fila.get("tramos_robados",
				p.castigo_tramos_robados)), 0)
		"caza_acelera":
			r["factor"] = float(fila.get("factor", p.caza_factor_reloj))
	return r

# ------------------------------------------------------------------- la cura

## (2) SE CURA SI NO LE TOCAS EN N SEGUNDOS: *"prohíbe jugar seguro"*. Un
## combate de dos minutos se puede jugar aguantando la bola en la cuna hasta que
## el reloj te obligue, y contra este enemigo esperar cuesta vida suya.
##
## Lo llama `Combate._golpear` cada vez que le aplica daño de verdad.
func tocado() -> void:
	sin_tocar = 0.0

## Avanza el reloj de la cura y devuelve cuánto se cura en este paso. SOLO lo
## llama `Combate.avanzar` con la bola en juego: en las pausas de drenaje y de
## ataque el jugador no tiene la bola, y cobrarle ahí sería cobrarle por esperar.
##
## Los instantes de cura caen en `espera`, `espera + periodo`, ... desde el
## último toque, y se cuentan los que caen dentro del paso: así sale lo mismo con
## pasos de 1/120 que de 1/30, que es lo que hace que la medida no dependa de los
## fotogramas (la misma regla que los ticks de `Estados`).
func avanzar_cura(dt: float, vida_maxima: int) -> int:
	if not activos.has("cura") or dt <= 0.0:
		return 0
	var c: Dictionary = activos["cura"]
	var espera := float(c["espera"])
	var periodo := float(c["periodo"])
	var antes := sin_tocar
	sin_tocar += dt
	if sin_tocar < espera:
		return 0
	var ya := -1 if antes < espera else int(floorf((antes - espera) / periodo))
	var ahora := int(floorf((sin_tocar - espera) / periodo))
	var veces := ahora - ya
	if veces <= 0:
		return 0
	return veces * maxi(int(round(float(vida_maxima) * float(c["fraccion"]))), 1)

## (5) CASTIGA EL MULTIPLICADOR ALTO: *"obliga a gastarlo"*. Lo pregunta
## `Combate._atacar` SOLO cuando pega el reloj —el golpe del drenaje ya llega con
## el combo perdido—, con el multiplicador de ese instante. Devuelve por cuánto
## multiplicar el golpe y cuántos tramos quitar; con el combo por debajo del
## umbral, o sin el comportamiento, el neutro exacto: 1.0 y 0.
func castigo_combo(multiplicador: int) -> Dictionary:
	if not activos.has("castiga_combo"):
		return {"factor": 1.0, "tramos": 0}
	var c: Dictionary = activos["castiga_combo"]
	var desde := int(c["desde"])
	if multiplicador < desde:
		return {"factor": 1.0, "tramos": 0}
	return {
		"factor": 1.0 + float(c["factor_por_tramo"]) * float(multiplicador - desde + 1),
		"tramos": int(c["tramos_robados"]),
	}

func castigo_desde() -> int:
	return int(activos["castiga_combo"]["desde"]) if activos.has("castiga_combo") else 0

## Lo que le falta para empezar a curarse, para enseñarlo. Cero si ya se cura.
func cura_en() -> float:
	if not activos.has("cura"):
		return 0.0
	return maxf(float(activos["cura"]["espera"]) - sin_tocar, 0.0)

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
func rotulos(en_caza: bool, multiplicador: int = 1) -> Array:
	var salida: Array = []
	for el_id in IDS:
		if not activos.has(el_id):
			continue
		match el_id:
			"cura":
				var falta := cura_en()
				salida.append({"rotulo": "SE CURA",
					"detalle": "curándose" if falta <= 0.0 else "en %d s" % int(ceilf(falta)),
					"activo": falta <= 0.0})
			"castiga_combo":
				# Se enciende en cuanto estás en el umbral, que es justo cuando hay
				# que gastar el combo antes de que llegue el reloj.
				salida.append({"rotulo": "CASTIGA",
					"detalle": "combo x%d" % castigo_desde(),
					"activo": multiplicador >= castigo_desde()})
			"caza_acelera":
				salida.append({"rotulo": "ACELERA", "detalle": "en la caza",
					"activo": en_caza})
	return salida
