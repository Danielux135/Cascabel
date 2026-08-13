class_name Run
extends RefCounted

## El estado de una partida entera: el mapa, dónde estás y la vida que te queda.
##
## LO QUE HACE QUE ESTO SEA UN RUN Y NO UNA LISTA DE COMBATES: la vida no se
## cura entre nodos. Lo que te dejas en el tercer combate lo sigues debiendo en
## el sexto, y por eso elegir rama importa. `DISEÑO.md` §9.

signal entrado_en_nodo(nodo: NodoMapa)
signal descansado(curado: int)
## La ruleta ha sacado una reliquia tras ganar un combate. `DISEÑO.md` §10.
signal ruleta_tirada(premio: Reliquia)
signal reliquia_tomada(reliquia: Reliquia)
signal run_terminada(victoria: bool)

enum Fase { ELIGIENDO, EN_COMBATE, RULETA, TERMINADA }

var p: ParametrosRun
var pc: ParametrosCombate
var mapa: Mapa
## Lo que llevas encima. Es lo único que hace que dos runs se jueguen distinto,
## porque la geometría de la mesa no cambia nunca (invariante).
var bolsa: BolsaReliquias

var vida: int = 0
var vida_maxima: int = 0
var fase: int = Fase.ELIGIENDO
var victoria := false

## Las casillas que se ven girando en la tele. La primera es siempre el premio:
## la ruleta se sortea aquí y la animación solo cuenta lo que ya pasó, que es lo
## único que permite que la animación se pueda saltar sin cambiar el resultado.
var casillas: Array[Reliquia] = []
## Dónde ha parado. Null fuera del momento de la ruleta.
var premio: Reliquia = null
## Tiradas que quedan. `DISEÑO.md`: la ruleta no te quita la decisión del todo,
## te deja rechazar una vez con un toque de flipper. Sin menú y sin salir de la
## mesa, que es lo que cansaba.
var repeticiones: int = 0
## De dónde salen. Sin catálogo el run se juega igual, solo que sin reliquias:
## así las medidas viejas siguen midiendo lo que medían.
var _reliquias_disponibles: Array[Reliquia] = []
## Y las misiones, que son de donde salen las reliquias. Sin ellas el run se
## juega igual, solo que sin premios: es lo que deja correr los medidores.
var _misiones_disponibles: Array[Mision] = []
var _rng := RandomNumberGenerator.new()

## Dónde estás. `fila` es -1 antes de entrar en el primer nodo: se empieza fuera
## del mapa y la primera decisión es por cuál de los nodos de la fila 0 entras.
var fila: int = -1
var columna: int = 0
var nodos_superados: int = 0

## LA MEDIDA DEL JUGADOR DE VERDAD, acumulada a lo largo del run. Existe porque
## la tabla de enemigos se ha calibrado dos veces contra un perfil inventado y
## las dos salió mal: con estos dos números se escribe exacta.
var bolas_jugadas: int = 0
var dano_total: int = 0
var tiempo_jugado: float = 0.0
var combates_jugados: int = 0

func dano_por_bola() -> float:
	return float(dano_total) / float(maxi(bolas_jugadas, 1))

func segundos_por_combate() -> float:
	return tiempo_jugado / float(maxi(combates_jugados, 1))

## Se llama al cerrar cada combate con lo que ha medido el combate.
func apuntar_medida(bolas: int, dano: int, segundos: float) -> void:
	bolas_jugadas += bolas
	dano_total += dano
	tiempo_jugado += segundos
	combates_jugados += 1

func _init(parametros: ParametrosRun = null, parametros_combate: ParametrosCombate = null,
		catalogo: Array = [], semilla: int = 0,
		catalogo_reliquias: Array[Reliquia] = [],
		catalogo_misiones: Array[Mision] = []) -> void:
	p = parametros if parametros != null else ParametrosRun.new()
	pc = parametros_combate if parametros_combate != null else ParametrosCombate.new()
	mapa = Mapa.new(p, catalogo, semilla)
	bolsa = BolsaReliquias.new(semilla)
	_reliquias_disponibles = catalogo_reliquias.duplicate()
	_misiones_disponibles = catalogo_misiones.duplicate()
	_rng.seed = semilla if semilla != 0 else 20260812
	vida_maxima = pc.vida_jugador
	vida = vida_maxima

## La vida máxima con lo que sumen las reliquias. Se recalcula en vez de
## guardarse porque el eje de ESCALADO la mueve a cada victoria, y un valor
## guardado se quedaría viejo justo cuando importa.
func _actualizar_vida_maxima() -> void:
	var antes := vida_maxima
	vida_maxima = maxi(pc.vida_jugador
		+ int(round(bolsa.suma("suma_vida_maxima"))), 1)
	# La vida que da una reliquia se da PUESTA, no como hueco vacío: un "+30 de
	# vida máxima" que te deja igual de tocado no se lee como una mejora.
	if vida_maxima > antes:
		vida += vida_maxima - antes
	vida = clampi(vida, 0, vida_maxima)

func nodo_actual() -> NodoMapa:
	if fila < 0 or fila >= mapa.alto():
		return null
	return mapa.nodo(fila, columna)

## A qué columnas de la fila siguiente puedes ir desde donde estás. Estando
## fuera del mapa, a cualquier nodo de la primera fila.
func opciones() -> Array[int]:
	if fase != Fase.ELIGIENDO:
		return []
	if fila < 0:
		var todas: Array[int] = []
		for c in (mapa.fila(0) as Array).size():
			todas.append(c)
		return todas
	if fila >= mapa.alto() - 1:
		return []
	return (nodo_actual() as NodoMapa).salidas.duplicate()

## Entra en un nodo de la fila siguiente. Devuelve el nodo, o null si esa
## columna no era alcanzable desde aquí: elegir rama es la decisión del mapa, y
## saltarse las ramas la vaciaría.
func elegir(columna_destino: int) -> NodoMapa:
	if not opciones().has(columna_destino):
		return null
	fila += 1
	columna = columna_destino
	var n := nodo_actual()
	if n.tipo == NodoMapa.Tipo.DESCANSO:
		_descansar()
	else:
		fase = Fase.EN_COMBATE
	entrado_en_nodo.emit(n)
	return n

func _descansar() -> void:
	var antes := vida
	vida = mini(vida + int(round(float(vida_maxima) * p.curacion_descanso)),
		vida_maxima)
	nodos_superados += 1
	descansado.emit(vida - antes)
	_comprobar_final()

## Cierra el combate del nodo actual con la vida que haya quedado. Perder acaba
## el run: no hay vidas ni continuaciones, que es lo que hace que la vida pese.
## EL CUELGUE DE LA PANTALLA DEL MAPA VENÍA DE AQUÍ, y merece quedar escrito:
## el golpe que completaba la última misión podía ser el mismo que mataba al
## enemigo. Entonces el run entraba en RULETA y, un segundo después, el combate
## intentaba cerrarse; este `return` lo mandaba a paseo sin decir nada y el run
## se quedaba en RULETA para siempre. Como `opciones()` devuelve vacío fuera de
## ELIGIENDO, el mapa aparecía sin ninguna rama viva y no respondía a nada.
##
## Ni un error ni un aviso: una pantalla muerta. Por eso ahora un combate que se
## cierra con la ruleta abierta la COBRA primero en vez de irse de puntillas —la
## reliquia estaba ganada, faltaba recogerla— y por eso hay una prueba de esto.
func resolver_combate(gano: bool, vida_restante: int) -> void:
	if fase == Fase.RULETA:
		aceptar_premio()
	if fase != Fase.EN_COMBATE:
		return
	vida = clampi(vida_restante, 0, vida_maxima)
	if not gano or vida <= 0:
		fase = Fase.TERMINADA
		victoria = false
		run_terminada.emit(false)
		return
	nodos_superados += 1
	# El gancho "al matar", en este orden a propósito: primero se apunta la
	# victoria, porque el eje de escalado se paga por victorias y la que acabas
	# de conseguir cuenta; luego se cura, ya con la vida máxima nueva.
	bolsa.victorias += 1
	_actualizar_vida_maxima()
	var cura := int(round(float(vida_maxima) * bolsa.suma("suma_curacion_al_matar")))
	if cura > 0:
		vida = mini(vida + cura, vida_maxima)
	_comprobar_final()

# ------------------------------------------------------------- la ruleta

## `DISEÑO.md` §10, revisado dos veces:
##
## 1. La recompensa dejó de ser una pantalla de "elige una de tres" y pasó a ser
##    una ruleta dentro de la mesa, porque parar cada minuto a leer tres
##    tarjetas cansaba más de lo que aportaba.
## 2. Y dejó de darse por GANAR EL COMBATE: ahora se gana COMPLETANDO MISIONES,
##    que es lo que pidió Daniel y lo que hacen el pinball del XP y Pokémon
##    Pinball. Ganar el combate no da objeto; te deja pasar.
##
## Eso cambia quién manda: el combate avisa de que se ha completado una misión y
## el run sortea una reliquia DE ESA RAREZA. Una misión arcana paga arcano.
func abrir_ruleta(rareza: int) -> bool:
	if fase == Fase.TERMINADA:
		return false
	repeticiones = p.repeticiones_ruleta
	if not _tirar(rareza):
		return false
	# La ruleta salta A MITAD DE COMBATE, así que hay que volver a donde estabas
	# y no a "eligiendo rama": el combate sigue justo donde lo dejaste, con la
	# bola donde estaba.
	_fase_antes = fase
	fase = Fase.RULETA
	ruleta_tirada.emit(premio)
	return true

var _fase_antes: int = Fase.EN_COMBATE

## Sortea las casillas dentro de una rareza. El premio es `casillas[0]`: se
## decide ANTES de que gire nada, y así la animación se puede saltar, acelerar o
## perder un fotograma sin que cambie lo que te toca.
##
## Si esa rareza se ha agotado se BAJA de rareza en vez de no dar nada: quedarte
## sin premio por haber jugado bien sería el peor castigo posible.
var _rareza_tirada: int = Mision.Rareza.COMUN

func _tirar(rareza: int = -1) -> bool:
	if rareza >= 0:
		_rareza_tirada = rareza
	casillas.clear()
	premio = null
	var candidatas := _candidatas(_rareza_tirada)
	var baja := _rareza_tirada
	while candidatas.is_empty() and baja > Mision.Rareza.COMUN:
		baja -= 1
		candidatas = _candidatas(baja)
	if candidatas.is_empty():
		return false
	for _i in mini(p.casillas_ruleta, candidatas.size()):
		var i := _rng.randi_range(0, candidatas.size() - 1)
		casillas.append(candidatas[i])
		candidatas.remove_at(i)
	premio = casillas[0]
	return true

## Las de esa rareza que no llevas todavía.
func _candidatas(rareza: int) -> Array[Reliquia]:
	var lista: Array[Reliquia] = []
	for r in _reliquias_disponibles:
		if r.rareza == rareza and not bolsa.tiene(r.id):
			lista.append(r)
	return lista

## La escalera de misiones de un combate: una común, una rara y una arcana,
## sorteadas. Se sortea aquí y no en el combate porque el combate no lee ficheros
## y porque así dos combates del mismo run no repiten la misma misión seguida.
func escalera_de_misiones() -> Array[Mision]:
	var salida: Array[Mision] = []
	for rareza in [Mision.Rareza.COMUN, Mision.Rareza.RARA, Mision.Rareza.ARCANA]:
		var candidatas: Array[Mision] = []
		for m in _misiones_disponibles:
			if m.rareza == rareza:
				candidatas.append(m)
		if candidatas.is_empty():
			continue
		salida.append(candidatas[_rng.randi_range(0, candidatas.size() - 1)])
	return salida

## Vuelve a tirar, si queda tirada. Devuelve si de verdad ha girado.
func repetir_tirada() -> bool:
	if fase != Fase.RULETA or repeticiones <= 0:
		return false
	repeticiones -= 1
	if not _tirar():
		return false
	ruleta_tirada.emit(premio)
	return true

## Se queda con lo que haya salido y cierra la ruleta. Devuelve la reliquia.
##
## No hay forma de rechazarla: con una repetición ya hay agencia, y un "no
## quiero ninguna" convierte otra vez la recompensa en una pregunta.
func aceptar_premio() -> Reliquia:
	if fase != Fase.RULETA:
		return null
	var ganada := premio
	if ganada != null:
		bolsa.anadir(ganada)
		_actualizar_vida_maxima()
		reliquia_tomada.emit(ganada)
	casillas.clear()
	premio = null
	repeticiones = 0
	fase = _fase_antes
	return ganada

func _comprobar_final() -> void:
	if fila >= mapa.alto() - 1:
		fase = Fase.TERMINADA
		victoria = true
		run_terminada.emit(true)
		return
	fase = Fase.ELIGIENDO

func terminada() -> bool:
	return fase == Fase.TERMINADA
