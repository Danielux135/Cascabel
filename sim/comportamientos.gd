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
const IDS := ["bloquea", "cura", "refleja", "blindaje", "castiga_combo",
	"caza_acelera"]

## Las claves que cada uno sabe leer del JSON, además de `id`. Misma razón: una
## clave mal escrita no pisa nada y nadie se entera. Hay prueba.
const CLAVES := {
	"cura": ["espera", "periodo", "fraccion"],
	"bloquea": ["tiro", "rearme"],
	"refleja": ["repeticiones", "factor_ataque"],
	"blindaje": ["capas", "umbral", "factor", "regenera"],
	"castiga_combo": ["desde", "factor_por_tramo", "tramos_robados"],
	"caza_acelera": ["factor"],
}

var p: ParametrosCombate
## id -> Dictionary con los números ya resueltos (el del JSON si lo trae, si no
## el parámetro con nombre).
var activos: Dictionary = {}

## Los tiros que vigila el reflejo y los que se pueden bloquear: los recorridos
## que se APUNTAN. Ni el racimo ni los targets (un banco pide tres targets
## seguidos, y reflejar o bloquear uno haría imposible cerrarlo).
const TIROS_REFLEJABLES := ["orbita", "retorno", "canon", "platillo"]
## Los que ABREN un recorrido bloqueado: cualquier tiro apuntado que no sea él.
## El racimo y el girador no: se los come la bola sola y lo abrirían sin jugar.
const TIROS_QUE_ABREN := ["target", "banco", "orbita", "retorno", "canon", "platillo"]

## (2) Segundos de juego sin que le toquen. Solo corre con la bola en juego.
var sin_tocar: float = 0.0
## (1) El recorrido cerrado ahora mismo ("" si está abierto), y lo que le falta
## para volver a cerrarse.
var bloqueado: String = ""
var rearme: float = 0.0
## (3) El último recorrido vigilado y cuántas veces seguidas va.
var ultimo_tiro: String = ""
var seguidas: int = 0
## (4) Capas de blindaje que le quedan, y lo que lleva regenerando la siguiente.
var capas: int = 0
var _hasta_capa: float = 0.0

## Prepara los comportamientos de un enemigo y deja el estado a cero. `lista` es
## lo que trae `Enemigo.comportamientos`; los ids que no existen se ignoran (la
## batería es la que los caza, no la partida: una fila rota no puede tumbarla).
func preparar(lista: Array, parametros: ParametrosCombate) -> void:
	p = parametros if parametros != null else ParametrosCombate.new()
	activos.clear()
	sin_tocar = 0.0
	bloqueado = ""
	rearme = 0.0
	ultimo_tiro = ""
	seguidas = 0
	capas = 0
	_hasta_capa = 0.0
	for fila in lista:
		if typeof(fila) != TYPE_DICTIONARY:
			continue
		var d := fila as Dictionary
		var el_id := str(d.get("id", ""))
		if not IDS.has(el_id):
			continue
		activos[el_id] = _resolver(el_id, d)
	if activos.has("blindaje"):
		capas = int(activos["blindaje"]["capas"])
	if activos.has("bloquea"):
		bloqueado = str(activos["bloquea"]["tiro"])

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
		"bloquea":
			var t := str(fila.get("tiro", p.bloqueo_tiro))
			# Solo un recorrido: con cualquier otra cosa, el de los parámetros.
			r["tiro"] = t if TIROS_REFLEJABLES.has(t) else p.bloqueo_tiro
			r["rearme"] = maxf(float(fila.get("rearme", p.bloqueo_rearme)), 0.5)
		"refleja":
			r["repeticiones"] = maxi(int(fila.get("repeticiones",
				p.reflejo_repeticiones)), 2)
			r["factor_ataque"] = maxf(float(fila.get("factor_ataque",
				p.reflejo_factor_ataque)), 0.0)
		"blindaje":
			r["capas"] = maxi(int(fila.get("capas", p.blindaje_capas)), 1)
			r["umbral"] = maxf(float(fila.get("umbral", p.blindaje_umbral)), 0.0)
			r["factor"] = clampf(float(fila.get("factor", p.blindaje_factor)), 0.0, 1.0)
			r["regenera"] = maxf(float(fila.get("regenera", p.blindaje_regenera)), 0.1)
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

## Con cada bola servida la espera de la cura empieza de cero. Sin esto, los
## segundos que llevaba la bola anterior pasaban a la nueva y el enemigo podía
## curarse con la bola todavía en el lanzador, sin que hubieras tenido ocasión
## de tocarle. Lo cazó la revisión de la Fase 6.
##
## Y LA RACHA DEL REFLEJO TAMBIÉN: sin esto, la órbita del lanzamiento de una bola
## y la de la siguiente contaban como repetir, y el Esqueleto te devolvía el
## golpe por lanzar. También la cazó una revisión.
func nueva_bola() -> void:
	sin_tocar = 0.0
	ultimo_tiro = ""
	seguidas = 0

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

# ----------------------------------------------------------------- el bloqueo

## (1) BLOQUEA UN RECORRIDO HASTA QUE LE PEGAS POR OTRO SITIO: el tiro que más
## te gusta está cerrado, y para abrirlo tienes que jugar otra parte de la mesa.
## Lo pregunta `Combate._filtrar_tiro` LO PRIMERO: un tiro bloqueado no cuenta ni
## para el reflejo.
func bloquea(tiro: String) -> bool:
	return activos.has("bloquea") and bloqueado != "" and tiro == bloqueado

## Un tiro que ha entrado de verdad. Si es otro sitio, abre el bloqueado y arma
## el reloj del rearme. Devuelve el tiro que se ha abierto, o "".
func tiro_entrado(tiro: String) -> String:
	if not activos.has("bloquea") or bloqueado == "" or tiro == bloqueado \
			or not TIROS_QUE_ABREN.has(tiro):
		return ""
	var abierto := bloqueado
	bloqueado = ""
	rearme = float(activos["bloquea"]["rearme"])
	return abierto

## Avanza el rearme con la bola en juego. Devuelve el tiro que se acaba de
## volver a cerrar, o "".
func avanzar_bloqueo(dt: float) -> String:
	if not activos.has("bloquea") or bloqueado != "":
		return ""
	rearme -= dt
	if rearme > 0.0:
		return ""
	rearme = 0.0
	bloqueado = str(activos["bloquea"]["tiro"])
	return bloqueado

# ------------------------------------------------------------- el reflejo

## (3) REFLEJA SI REPITES TIRO: *"obliga a variar"*. Lo pregunta
## `Combate._filtrar_tiro` con cada tiro apuntado. Lleva la cuenta de los
## seguidos y dice si ESTE se refleja: a partir de `repeticiones` seguidas, y
## mientras no cambies.
##
## LA RACHA LA ROMPE CUALQUIER TIRO APUNTADO, aunque solo los recorridos se
## puedan reflejar. Si un target o un banco no la rompieran, "cañón, banco,
## cañón" contaría como repetir, que no es lo que nadie entiende por repetir, y
## una misión como Cadena larga (cañón → banco → cañón → banco) se reflejaría
## entera sin haber repetido nada. El racimo y el girador no la tocan: no se
## apuntan.
func reflejar(tiro: String) -> bool:
	if not activos.has("refleja") or not TIROS_QUE_ABREN.has(tiro):
		return false
	if tiro == ultimo_tiro:
		seguidas += 1
	else:
		ultimo_tiro = tiro
		seguidas = 1
	return TIROS_REFLEJABLES.has(tiro) \
		and seguidas >= int(activos["refleja"]["repeticiones"])

## Lo que te devuelve un tiro reflejado.
func ataque_reflejo(ataque: int) -> int:
	if not activos.has("refleja"):
		return 0
	return maxi(int(round(float(ataque) * float(activos["refleja"]["factor_ataque"]))), 0)

## El tiro que reflejaría si lo metieras ahora, o "" si ninguno. Es lo que dice
## el panel: no "refleja si repites", sino "REFLEJA: CAÑÓN".
func tiro_vigilado() -> String:
	if not activos.has("refleja") or not TIROS_REFLEJABLES.has(ultimo_tiro):
		return ""
	if seguidas + 1 >= int(activos["refleja"]["repeticiones"]):
		return ultimo_tiro
	return ""

# ------------------------------------------------------------- el blindaje

## (4) BLINDAJE QUE SOLO ROMPE EL DAÑO CONCENTRADO: *"mata al build de combo"*.
## Lo llama `Combate._golpear` con el daño del golpe ya entero —multiplicador,
## reliquias, descarga y crítico— y el daño del cañón, que es la vara del
## umbral. Devuelve el daño que entra; si rompe una capa, la quita.
##
## NO lo pasan los estados: un tic de veneno no es un golpe, y aplicarle un
## umbral dependería de cuántos tics caen en el fotograma. Que el veneno
## atraviese el blindaje es la respuesta a este enemigo, y es diseño: pregunta.
func filtrar_golpe(dano: float, dano_canon: float) -> float:
	if not activos.has("blindaje") or capas <= 0:
		return dano
	var b: Dictionary = activos["blindaje"]
	if dano >= float(b["umbral"]) * dano_canon:
		capas -= 1
		return dano
	return dano * float(b["factor"])

## Regenera capas con la bola en juego. Lo llama `Combate.avanzar` dentro de
## `if _en_juego()`, como la cura: en las pausas no se arregla nada.
func avanzar_blindaje(dt: float) -> void:
	if not activos.has("blindaje"):
		return
	var b: Dictionary = activos["blindaje"]
	var maximo := int(b["capas"])
	if capas >= maximo:
		_hasta_capa = 0.0
		return
	_hasta_capa += dt
	var cada := float(b["regenera"])
	while _hasta_capa >= cada and capas < maximo:
		_hasta_capa -= cada
		capas += 1

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
##
## `herido` es si al enemigo le falta vida: a vida llena no se está curando nada,
## y encender "curándose" en rojo sería mentir.
func rotulos(en_caza: bool, multiplicador: int = 1, herido: bool = true) -> Array:
	var salida: Array = []
	for el_id in IDS:
		if not activos.has(el_id):
			continue
		match el_id:
			"cura":
				var falta := cura_en()
				var curando := falta <= 0.0 and herido
				var detalle := "curándose" if curando else "en %d s" % int(ceilf(falta))
				if falta <= 0.0 and not herido:
					detalle = "en espera"
				salida.append({"rotulo": "SE CURA", "detalle": detalle,
					"activo": curando})
			"bloquea":
				var tiro_b := str(activos["bloquea"]["tiro"])
				salida.append({"rotulo": "BLOQUEA",
					"detalle": str(Mision.ROTULO_TIRO.get(tiro_b, tiro_b)).to_upper()
						if bloqueado != "" else "en %d s" % int(ceilf(rearme)),
					"activo": bloqueado != ""})
			"refleja":
				var vigilado := tiro_vigilado()
				salida.append({"rotulo": "REFLEJA",
					"detalle": "si repites" if vigilado == ""
						else str(Mision.ROTULO_TIRO.get(vigilado, vigilado)).to_upper(),
					"activo": vigilado != ""})
			"blindaje":
				salida.append({"rotulo": "BLINDAJE",
					"detalle": "roto" if capas <= 0 else ("1 capa" if capas == 1
						else "%d capas" % capas),
					"activo": capas > 0})
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
