class_name Mapa
extends RefCounted

## El mapa del run: filas de nodos con ramas, tres actos, un jefe al final de
## cada uno.
##
## El mapa SÍ es procedural, y no contradice el invariante: lo que no puede
## generarse es la GEOMETRÍA DE LA MESA, porque cada ángulo condiciona todos los
## rebotes y eso es artesanía. Un mapa es una lista de decisiones, y ahí la
## variedad entre partidas es justo lo que se busca.
##
## Se genera entero de una vez, al empezar el run, porque hay que poder mirar el
## camino y elegir sabiendo lo que viene. Un mapa que se descubre nodo a nodo no
## es una decisión, es una sorpresa.

var p: ParametrosRun
## `filas[i]` es un `Array[NodoMapa]`. Las filas van seguidas de un acto al
## siguiente: la última fila de cada acto es la del jefe, y tiene un solo nodo.
var filas: Array = []
var rng := RandomNumberGenerator.new()

func _init(parametros: ParametrosRun = null, catalogo: Array = [],
		semilla: int = 0) -> void:
	p = parametros if parametros != null else ParametrosRun.new()
	if semilla != 0:
		rng.seed = semilla
	else:
		rng.randomize()
	_generar(catalogo)

func alto() -> int:
	return filas.size()

func fila(i: int) -> Array:
	return filas[i]

func nodo(fila_i: int, columna: int) -> NodoMapa:
	return filas[fila_i][columna]

## Las filas del jefe son las que cierran cada acto.
func es_fila_de_jefe(i: int) -> bool:
	return (i + 1) % (p.filas_por_acto + 1) == 0

func acto_de_fila(i: int) -> int:
	return i / (p.filas_por_acto + 1)

# ----------------------------------------------------------------- generación

func _generar(catalogo: Array) -> void:
	filas.clear()
	var total := p.actos * (p.filas_por_acto + 1)
	for i in total:
		var acto := acto_de_fila(i)
		var fila_en_acto := i % (p.filas_por_acto + 1)
		var jefe := es_fila_de_jefe(i)
		var ancho := 1 if jefe else rng.randi_range(
			p.nodos_por_fila_min, p.nodos_por_fila_max)
		var nueva: Array[NodoMapa] = []
		for c in ancho:
			var n := NodoMapa.new()
			n.acto = acto
			n.fila = i
			n.columna = c
			n.tipo = _tipo(jefe, fila_en_acto, ancho, c)
			n.enemigo = _enemigo(catalogo, acto, n.tipo)
			nueva.append(n)
		filas.append(nueva)
	_enlazar()

## Un descanso por acto, en la penúltima fila y nunca ocupando la fila entera:
## si la ocupara, curarte dejaría de ser una decisión y sería un peaje.
func _tipo(jefe: bool, fila_en_acto: int, ancho: int, columna: int) -> int:
	if jefe:
		return NodoMapa.Tipo.JEFE
	if fila_en_acto == p.fila_descanso and ancho > 1:
		if columna == rng.randi_range(0, ancho - 1):
			return NodoMapa.Tipo.DESCANSO
	if fila_en_acto >= p.fila_primera_elite and rng.randf() < 0.30:
		return NodoMapa.Tipo.ELITE
	return NodoMapa.Tipo.COMBATE

## El catálogo va ordenado de menos a más vida, así que cada acto se lleva su
## tercio. Es un reparto provisional: la tabla de enemigos se rehace entera
## ahora que hay reloj y tiros con identidad contra los que balancearla.
func _enemigo(catalogo: Array, acto: int, tipo: int) -> Dictionary:
	if catalogo.is_empty():
		return {}
	var por_acto := maxi(catalogo.size() / maxi(p.actos, 1), 1)
	var desde := mini(acto * por_acto, catalogo.size() - 1)
	var hasta := mini(desde + por_acto - 1, catalogo.size() - 1)
	var datos: Dictionary = (catalogo[rng.randi_range(desde, hasta)] as Dictionary).duplicate()
	var factor := 1.0
	if tipo == NodoMapa.Tipo.ELITE:
		factor = p.factor_vida_elite
	elif tipo == NodoMapa.Tipo.JEFE:
		factor = p.factor_vida_jefe
		datos["nombre"] = "%s mayor" % str(datos.get("nombre", "?"))
	datos["vida"] = int(round(float(datos.get("vida", 100)) * factor))
	return datos

## Las ramas. Cada nodo sale hacia su vecino "de enfrente" en la fila siguiente
## y a veces hacia el de al lado, y después se repara: todo nodo de la fila
## siguiente tiene que ser alcanzable desde alguno de la anterior, o el mapa
## tendría caminos muertos que se ven pero no se pueden tomar.
func _enlazar() -> void:
	for i in filas.size() - 1:
		var actual: Array = filas[i]
		var siguiente: Array = filas[i + 1]
		for j in actual.size():
			var base := _proyectar(j, actual.size(), siguiente.size())
			var salidas: Array[int] = [base]
			if siguiente.size() > 1 and rng.randf() < 0.45:
				var vecino := base + (1 if rng.randf() < 0.5 else -1)
				if vecino >= 0 and vecino < siguiente.size():
					salidas.append(vecino)
			salidas.sort()
			(actual[j] as NodoMapa).salidas = salidas
		_reparar_huerfanos(actual, siguiente)

func _proyectar(j: int, ancho: int, ancho_siguiente: int) -> int:
	if ancho <= 1 or ancho_siguiente <= 1:
		return 0 if ancho_siguiente <= 1 else int(round(
			float(ancho_siguiente - 1) * 0.5))
	return int(round(float(j) * float(ancho_siguiente - 1) / float(ancho - 1)))

func _reparar_huerfanos(actual: Array, siguiente: Array) -> void:
	for c in siguiente.size():
		var alcanzable := false
		for n in actual:
			if (n as NodoMapa).salidas.has(c):
				alcanzable = true
				break
		if alcanzable:
			continue
		# Se cuelga del nodo cuya proyección quede más cerca, que es el que no
		# cruza ramas por encima de otras.
		var mejor := 0
		var distancia := 9999
		for j in actual.size():
			var d := absi(_proyectar(j, actual.size(), siguiente.size()) - c)
			if d < distancia:
				distancia = d
				mejor = j
		var n := actual[mejor] as NodoMapa
		n.salidas.append(c)
		n.salidas.sort()
