class_name Guardado
extends RefCounted

## LO QUE SOBREVIVE A CERRAR EL JUEGO. Antes de esto no había NADA: perder un run
## no dejaba ni un número, así que no existía ninguna frase que empezara por "la
## próxima vez". Es la pieza de la que cuelgan los desbloqueos, los logros y los
## easter eggs de `PROPÓSITO.md`, y por eso va primero.
##
## Vive en `sim/` porque no dibuja: usa `FileAccess`, que es del núcleo y no de
## la escena, así que la batería lo prueba en headless igual que el combate.
##
## DOS COSAS QUE NO SE TOCAN SIN PENSAR:
##
## 1. **Un guardado que se corrompe no puede borrar la partida en silencio.**
##    Se escribe a un fichero temporal y se renombra encima: si el juego se cierra
##    a mitad, lo que hay en disco sigue siendo el guardado anterior entero, nunca
##    medio JSON. Y al leer, cualquier cosa que no cuadre —fichero ausente, JSON
##    roto, versión del futuro— deja un guardado VACÍO Y VÁLIDO en vez de reventar.
## 2. **`version` no es decoración.** El día que cambie la forma del fichero, un
##    guardado viejo tiene que poder abrirse. Si no hay migración escrita para una
##    versión, se empieza de cero, y eso es una decisión: mejor perder progreso que
##    cargar datos que el código de hoy no entiende.

const RUTA := "user://cascabel.guardado.json"
const VERSION := 1

## Qué se ha recuperado. Claves del catálogo (`data/recuperable.json`) a `true`.
## Es un diccionario y no una lista a propósito: recuperar dos veces la misma
## pieza no puede duplicarla, y así el caso no hay ni que contemplarlo.
var recuperado: Dictionary = {}

## Las estadísticas de `mi_maquina`. Todas son acumuladas de SIEMPRE, no del run.
var runs_jugados: int = 0
var runs_ganados: int = 0
var combates_ganados: int = 0
var bolas_jugadas: int = 0
var dano_total: int = 0
var mejor_dano_por_bola: float = 0.0
var segundos_jugados: float = 0.0

## Los enemigos matados, por id y cuántas veces. Es lo que hay dentro de la
## papelera: `DISEÑO.md` §3 dice que los monstruos son procesos, así que matarlos
## los manda ahí.
var matados: Dictionary = {}

## Cuántas veces se ha vaciado la papelera. Lo mira un easter egg.
var papelera_vaciada: int = 0

## LO ELEGIDO EN LA PREPARACIÓN. Se guarda para que lo que elegiste siga
## elegido mañana: obligar a repetir la elección cada vez que abres el juego
## convierte una decisión en un trámite. Los valores por defecto son los de la
## partida de siempre, así que un guardado viejo —que no trae estas claves—
## arranca exactamente como arrancaba.
var pre_cascabel: String = "casc_acero"
var pre_criatura: String = "cr_rata"
var pre_palas: String = "pala_fabrica"

# --------------------------------------------------------------------- lectura

## Carga el guardado del disco. NUNCA falla y NUNCA lanza: si no hay nada que
## leer, o lo que hay no se entiende, devuelve un `Guardado` recién hecho. Un
## juego que no arranca porque el guardado está roto es peor que uno que empieza
## de cero, y las dos cosas se distinguen mirando `hubo_fichero`.
static func cargar(ruta: String = RUTA) -> Guardado:
	var g := Guardado.new()
	if not FileAccess.file_exists(ruta):
		return g
	var f := FileAccess.open(ruta, FileAccess.READ)
	if f == null:
		return g
	var texto := f.get_as_text()
	f.close()
	g.hubo_fichero = true
	var datos = JSON.parse_string(texto)
	if not (datos is Dictionary):
		g.ilegible = true
		return g
	return desde_diccionario(datos, g)

## Separado de `cargar` para que la batería pueda meterle diccionarios a mano sin
## tocar disco: lo que se rompe aquí es la FORMA de los datos, no el fichero.
static func desde_diccionario(datos: Dictionary, sobre: Guardado = null) -> Guardado:
	var g := sobre if sobre != null else Guardado.new()
	var v := int(datos.get("version", 0))
	# Una versión del futuro no se adivina. Se empieza de cero y se dice.
	if v > VERSION:
		g.ilegible = true
		return g
	g.recuperado = _dic(datos.get("recuperado", {}))
	g.matados = _dic(datos.get("matados", {}))
	g.runs_jugados = int(datos.get("runs_jugados", 0))
	g.runs_ganados = int(datos.get("runs_ganados", 0))
	g.combates_ganados = int(datos.get("combates_ganados", 0))
	g.bolas_jugadas = int(datos.get("bolas_jugadas", 0))
	g.dano_total = int(datos.get("dano_total", 0))
	g.mejor_dano_por_bola = float(datos.get("mejor_dano_por_bola", 0.0))
	g.segundos_jugados = float(datos.get("segundos_jugados", 0.0))
	g.papelera_vaciada = int(datos.get("papelera_vaciada", 0))
	g.pre_cascabel = str(datos.get("pre_cascabel", g.pre_cascabel))
	g.pre_criatura = str(datos.get("pre_criatura", g.pre_criatura))
	g.pre_palas = str(datos.get("pre_palas", g.pre_palas))
	return g

static func _dic(v) -> Dictionary:
	return v.duplicate() if v is Dictionary else {}

## Si había fichero en disco. Sirve para distinguir "primera vez que juegas" de
## "tu guardado no se ha podido leer", que para el jugador no es lo mismo.
var hubo_fichero := false
## Había fichero y no se ha entendido. El escritorio lo dice en vez de callárselo:
## una partida que desaparece sin explicación se lee como un bug del juego, que
## es exactamente lo que es.
var ilegible := false

# -------------------------------------------------------------------- escritura

func a_diccionario() -> Dictionary:
	return {
		"version": VERSION,
		"recuperado": recuperado,
		"matados": matados,
		"runs_jugados": runs_jugados,
		"runs_ganados": runs_ganados,
		"combates_ganados": combates_ganados,
		"bolas_jugadas": bolas_jugadas,
		"dano_total": dano_total,
		"mejor_dano_por_bola": mejor_dano_por_bola,
		"segundos_jugados": segundos_jugados,
		"papelera_vaciada": papelera_vaciada,
		"pre_cascabel": pre_cascabel,
		"pre_criatura": pre_criatura,
		"pre_palas": pre_palas,
	}

## Escribe a disco de forma ATÓMICA: primero a `.tmp` y luego se renombra encima.
## Escribir directo sobre el bueno es una ventana en la que un cierre a destiempo
## deja medio JSON, y medio JSON es un guardado ilegible, o sea la partida
## perdida. Devuelve si se ha podido.
func guardar(ruta: String = RUTA) -> bool:
	var temporal := ruta + ".tmp"
	var f := FileAccess.open(temporal, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(a_diccionario(), "\t"))
	f.close()
	var d := DirAccess.open(ruta.get_base_dir())
	if d == null:
		return false
	if d.file_exists(ruta):
		d.remove(ruta)
	return d.rename(temporal, ruta) == OK

# ----------------------------------------------------------------------- uso

func tiene(id: String) -> bool:
	return bool(recuperado.get(id, false))

## Devuelve si era NUEVO. Lo que se recupera dos veces no cuenta, y quien llama
## necesita saberlo para no anunciar un hallazgo que ya tenías.
func recuperar(id: String) -> bool:
	if id == "" or tiene(id):
		return false
	recuperado[id] = true
	return true

func cuantas_recuperadas() -> int:
	return recuperado.size()

func apuntar_muerte(id_enemigo: String) -> void:
	if id_enemigo == "":
		return
	matados[id_enemigo] = int(matados.get(id_enemigo, 0)) + 1

func total_matados() -> int:
	var n := 0
	for k in matados:
		n += int(matados[k])
	return n

func vaciar_papelera() -> void:
	matados.clear()
	papelera_vaciada += 1

## CUÁNTO PAGA UN RUN, y es el dial más delicado de toda la meta-progresión.
##
## `PIEZAS_MINIMO` a 1 significa que **un run perdido en el primer combate
## también paga**, y eso es a propósito: `PROPÓSITO.md` §1 dice que el agujero
## no era la dificultad sino que perder no costaba NADA, y un pago de cero deja
## el agujero igual. `NODOS_POR_PIEZA` es lo que separa "he jugado" de "he
## jugado bien": llegar lejos paga más sin que llegar poco pague nada.
##
## Si al jugarlo esto se siente a tragaperras —una pieza cada vez que respiras—
## el dial que se toca es `NODOS_POR_PIEZA` hacia arriba, no `PIEZAS_MINIMO`
## hacia abajo: quitar el pago del run perdido devuelve el problema original.
const PIEZAS_MINIMO := 1
const NODOS_POR_PIEZA := 5

static func piezas_ganadas(nodos_superados: int) -> int:
	return PIEZAS_MINIMO + int(maxi(nodos_superados, 0) / NODOS_POR_PIEZA)

## Cierra un run: mete sus números en el acumulado y recupera lo que haya ganado.
## Se llama UNA vez, al acabar, y no durante: sumar por combate haría que cerrar
## el juego a mitad de run contara medio run.
##
## Devuelve los ids de lo recuperado, para poder anunciarlo. Vacío si no había
## nada nuevo que dar, que es lo que pasa cuando ya está todo: entonces el run
## sigue contando en las estadísticas y no promete un hallazgo que no existe.
func cerrar_run(gano: bool, r: Run) -> Array:
	runs_jugados += 1
	if gano:
		runs_ganados += 1
	var nodos := 0
	if r != null:
		combates_ganados += r.combates_jugados
		bolas_jugadas += r.bolas_jugadas
		dano_total += r.dano_total
		segundos_jugados += r.tiempo_jugado
		mejor_dano_por_bola = maxf(mejor_dano_por_bola, r.dano_por_bola())
		nodos = r.nodos_superados
	var nuevas: Array = []
	for _i in piezas_ganadas(nodos):
		var id := CatalogoRecuperable.siguiente_para(self)
		if id == "":
			break
		if recuperar(id):
			nuevas.append(id)
	return nuevas
