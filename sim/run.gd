class_name Run
extends RefCounted

## El estado de una partida entera: el mapa, dónde estás y la vida que te queda.
##
## LO QUE HACE QUE ESTO SEA UN RUN Y NO UNA LISTA DE COMBATES: la vida no se
## cura entre nodos. Lo que te dejas en el tercer combate lo sigues debiendo en
## el sexto, y por eso elegir rama importa. `DISEÑO.md` §9.

signal entrado_en_nodo(nodo: NodoMapa)
signal descansado(curado: int)
signal run_terminada(victoria: bool)

enum Fase { ELIGIENDO, EN_COMBATE, TERMINADA }

var p: ParametrosRun
var pc: ParametrosCombate
var mapa: Mapa

var vida: int = 0
var vida_maxima: int = 0
var fase: int = Fase.ELIGIENDO
var victoria := false

## Dónde estás. `fila` es -1 antes de entrar en el primer nodo: se empieza fuera
## del mapa y la primera decisión es por cuál de los nodos de la fila 0 entras.
var fila: int = -1
var columna: int = 0
var nodos_superados: int = 0

func _init(parametros: ParametrosRun = null, parametros_combate: ParametrosCombate = null,
		catalogo: Array = [], semilla: int = 0) -> void:
	p = parametros if parametros != null else ParametrosRun.new()
	pc = parametros_combate if parametros_combate != null else ParametrosCombate.new()
	mapa = Mapa.new(p, catalogo, semilla)
	vida_maxima = pc.vida_jugador
	vida = vida_maxima

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
func resolver_combate(gano: bool, vida_restante: int) -> void:
	if fase != Fase.EN_COMBATE:
		return
	vida = clampi(vida_restante, 0, vida_maxima)
	if not gano or vida <= 0:
		fase = Fase.TERMINADA
		victoria = false
		run_terminada.emit(false)
		return
	nodos_superados += 1
	_comprobar_final()

func _comprobar_final() -> void:
	if fila >= mapa.alto() - 1:
		fase = Fase.TERMINADA
		victoria = true
		run_terminada.emit(true)
		return
	fase = Fase.ELIGIENDO

func terminada() -> bool:
	return fase == Fase.TERMINADA
