extends SceneTree

## Mide qué hace cada reliquia, SIN abrir ventana:
##   godot --headless --path . --script tests/medir_reliquias.gd
##
## Esto NO es una prueba: no falla nunca, imprime tablas. Es el hermano de
## `medir_balance.gd` y existe por la misma razón que él: la tabla de enemigos
## se hizo dos veces a ojo y las dos se llevó el run por delante. Cuarenta y
## cinco reliquias escritas a ojo se lo llevarían otra vez, y encima de una forma peor,
## porque una reliquia rota no se nota como un muro sino como "esta no la cojo
## nunca", que es un fallo invisible.
##
## Lo que se mide, en este orden:
##
##   1. DAÑO POR BOLA de cada perfil con cada reliquia suelta. Dice cuánto pesa
##      cada una y contra quién: una reliquia que solo sirve al jugador bueno es
##      una reliquia que no existe para el que la necesita.
##   2. RUNS ENTEROS con una reliquia puesta desde el principio, contra el run
##      pelado. Es lo único que dice si la reliquia CAMBIA la partida, que es el
##      criterio de salida de la fase.
##   3. RUNS POR EJE, cogiendo solo reliquias de un eje. `DISEÑO.md` §8: dos
##      partidas con ejes distintos tienen que sentirse como juegos distintos,
##      no como el mismo con números más grandes. Si los cinco ejes dan la misma
##      tabla, el reparto está mal aunque cada reliquia esté bien.
##
## LO QUE ESTO NO PUEDE CONTESTAR, igual que el otro medidor: los perfiles no
## juegan con las palas. Miden la economía del combate, no si un tiro es cazable
## ni cómo se siente nada. Una reliquia que cambie a qué tiro vas —el cascabel de
## plata es la clara— aquí sale como un número y en las manos es otra cosa.

const DT := 1.0 / 60.0
const MAX_BOLAS := 200
const SEMILLAS := [13, 271, 4242, 90210, 31337]

## Los mismos tres perfiles que `medir_balance.gd`, copiados a propósito: si un
## día se tocan allí, esto tiene que seguir midiendo lo que medía hasta que se
## decida traerlos, y no cambiar solo bajo los pies.
const PERFILES := [
	{
		"nombre": "malo",
		"segundos": 6.0,
		"golpes": 4, "targets": 1, "bancos": 0,
		"orbitas": 0, "retornos": 0, "canones": 0, "platillos": 0,
	},
	{
		"nombre": "normal",
		"segundos": 10.0,
		"golpes": 9, "targets": 2, "bancos": 0,
		"orbitas": 1, "retornos": 1, "canones": 0, "platillos": 0,
	},
	{
		"nombre": "bueno",
		"segundos": 16.0,
		"golpes": 14, "targets": 4, "bancos": 1,
		"orbitas": 1, "retornos": 1, "canones": 1, "platillos": 1,
	},
]

func _initialize() -> void:
	var enemigos := CatalogoEnemigos.cargar()
	var catalogo := CatalogoReliquias.cargar()
	print("")
	print("MEDIDA DE RELIQUIAS  ·  %d reliquias  ·  vida %d  ·  reloj %.0f s"
		% [catalogo.size(), ParametrosCombate.new().vida_jugador,
			ParametrosCombate.new().reloj_carga])
	print("")
	_tabla_dano(catalogo)
	_tabla_runs(catalogo, enemigos)
	_tabla_ejes(catalogo, enemigos)
	quit(0)

# ------------------------------------------------------- 1. daño por bola

## Cuánto sube el daño de una bola con la reliquia puesta, por perfil.
##
## Se mide con la bolsa a media partida (cuatro victorias) además de a cero,
## porque el eje de escalado no existe al empezar: medirlo solo en el combate
## uno diría que `interés compuesto` no hace nada, que es justo lo contrario de
## lo que hace.
func _tabla_dano(catalogo: Array[Reliquia]) -> void:
	print("── dano por bola, reliquia suelta ─────────────────────────")
	print("  entre parentesis, con 4 combates ya ganados (el eje de escalado)")
	print("")
	print("  %-24s %-13s %-15s %-15s" % ["reliquia", "malo", "normal", "bueno"])
	var base: Array[int] = []
	for perfil in PERFILES:
		base.append(_dano_por_bola(perfil as Dictionary, null, 0))
	print("  %-24s %-13d %-15d %-15d" % ["(sin reliquias)", base[0], base[1], base[2]])
	for r in catalogo:
		var linea := "  %-24s" % r.nombre
		for i in PERFILES.size():
			var ahora := _dano_por_bola(PERFILES[i] as Dictionary, r, 0)
			var luego := _dano_por_bola(PERFILES[i] as Dictionary, r, 4)
			linea += " %-15s" % ("%+d%% (%+d%%)" % [
				_pct(ahora, base[i]), _pct(luego, base[i])])
		print(linea)
	print("")

func _pct(valor: int, base: int) -> int:
	return int(round((float(valor) / float(maxi(base, 1)) - 1.0) * 100.0))

func _dano_por_bola(perfil: Dictionary, r: Reliquia, victorias: int) -> int:
	var p := ParametrosCombate.new()
	p.vida_jugador = 1000000
	var c := Combate.new(p)
	c.bolsa = _bolsa([r], victorias)
	c.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000000, "ataque": 1}))
	_jugar_una_bola(c, perfil)
	return c.dano_de_la_bola

## Una bolsa con lo que se le pase. La semilla es fija: las reliquias de caos
## llevan azar, y si la semilla cambiara entre dos medidas no se podría comparar
## una tabla con la anterior.
func _bolsa(lista: Array, victorias: int) -> BolsaReliquias:
	var b := BolsaReliquias.new(20260812)
	for r in lista:
		if r != null:
			b.anadir(r as Reliquia)
	b.victorias = victorias
	return b

# ------------------------------------------------------------ 2. runs

## Lo único que dice si una reliquia cambia la partida: runs enteros con ella
## puesta desde el primer combate, contra el run pelado.
##
## Se le da al jugador `normal`, que es el perfil que estaba justo en el filo
## (acaba 2 de 5). Ahí es donde una reliquia se nota: al bueno casi todo le
## sobra y al malo casi nada le llega.
func _tabla_runs(catalogo: Array[Reliquia], enemigos: Array) -> void:
	print("── runs enteros del jugador normal, con la reliquia puesta ─")
	print("  %d semillas  ·  el pelado es la referencia" % SEMILLAS.size())
	print("")
	var perfil := PERFILES[1] as Dictionary
	var pelado := _runs(perfil, enemigos, [])
	print("  %-24s %8s %8s %11s" % ["reliquia", "acaba", "nodos", "vida final"])
	print("  %-24s %6d/%d %8.1f %11s" % ["(sin reliquias)",
		int(pelado["acabados"]), SEMILLAS.size(), float(pelado["nodos"]),
		_vida(pelado)])
	for r in catalogo:
		var res := _runs(perfil, enemigos, [r])
		print("  %-24s %6d/%d %8.1f %11s   %s" % [r.nombre,
			int(res["acabados"]), SEMILLAS.size(), float(res["nodos"]),
			_vida(res), _juicio(res, pelado)])
	print("")
	print("  MUERTA = no mueve ni los nodos ni la vida. Es la que hay que")
	print("  rehacer: el jugador la coge, no la nota, y culpa al balance.")
	print("")

func _vida(res: Dictionary) -> String:
	return ("%.0f" % float(res["vida_final"])) if int(res["acabados"]) > 0 else "—"

## Una reliquia sirve si mueve algo. No hay umbral fino aquí a propósito: esto
## marca las sospechosas para mirarlas, no decide por nadie.
func _juicio(res: Dictionary, pelado: Dictionary) -> String:
	var d_nodos: float = float(res["nodos"]) - float(pelado["nodos"])
	var d_acaba := int(res["acabados"]) - int(pelado["acabados"])
	if d_acaba == 0 and absf(d_nodos) < 0.4:
		return "MUERTA?"
	if d_acaba > 0 or d_nodos > 1.5:
		return "fuerte"
	if d_acaba < 0:
		return "estorba"
	return ""

# --------------------------------------------------------- 3. por eje

## `DISEÑO.md` §8: dos partidas con ejes distintos tienen que sentirse como
## juegos distintos. Aquí se juega un run cogiendo SOLO reliquias de un eje —que
## es lo que hace alguien que sabe lo que monta— y se mira si las cinco tablas se
## parecen. Si salen las cinco iguales, el reparto está mal aunque cada reliquia
## por separado esté bien.
func _tabla_ejes(catalogo: Array[Reliquia], enemigos: Array) -> void:
	print("── runs por eje de build (jugador normal, todo el eje) ─────")
	print("")
	print("  %-16s %8s %8s %11s %s" % [
		"eje", "acaba", "nodos", "vida final", "reliquias"])
	var perfil := PERFILES[1] as Dictionary
	for eje in Reliquia.NOMBRE_EJE:
		var del_eje: Array[Reliquia] = []
		for r in catalogo:
			if r.eje == int(eje):
				del_eje.append(r)
		var res := _runs(perfil, enemigos, del_eje)
		print("  %-16s %6d/%d %8.1f %11s %d" % [
			str(Reliquia.NOMBRE_EJE[eje]), int(res["acabados"]), SEMILLAS.size(),
			float(res["nodos"]), _vida(res), del_eje.size()])
	print("")

# ----------------------------------------------------------- maquinaria

## Runs de verdad con el mapa generado, igual que en `medir_balance.gd`: la rama
## se elige con la regla más tonta —la primera— porque eso da la COTA MALA, y si
## el peor camino se aguanta, el bueno también.
##
## La diferencia con el otro medidor: las reliquias se dan puestas desde el
## principio en vez de elegirse por el camino. Es a propósito. Medir la elección
## mediría a la vez la reliquia y la suerte del reparto, y lo que se quiere
## saber aquí es qué hace la reliquia.
func _runs(perfil: Dictionary, enemigos: Array, lista: Array) -> Dictionary:
	var acabados := 0
	var nodos := 0
	var vida_final := 0
	for semilla in SEMILLAS:
		var r := Run.new(ParametrosRun.new(), ParametrosCombate.new(), enemigos,
			int(semilla))
		for reliquia in lista:
			r.bolsa.anadir(reliquia as Reliquia)
		while not r.terminada():
			var opciones := r.opciones()
			if opciones.is_empty():
				break
			var nodo := r.elegir(opciones[0])
			if nodo == null:
				break
			if not nodo.es_combate():
				continue
			var res := _un_combate(perfil, nodo.enemigo, r.bolsa)
			var restante: int = r.vida - int(res["vida_perdida"])
			r.resolver_combate(restante > 0, maxi(restante, 0))
			if restante <= 0:
				break
		nodos += r.nodos_superados
		if r.victoria:
			acabados += 1
			vida_final += r.vida
	return {
		"acabados": acabados,
		"nodos": float(nodos) / float(maxi(SEMILLAS.size(), 1)),
		"vida_final": float(vida_final) / float(maxi(acabados, 1)),
	}

## Un combate con vida infinita, para medir lo que CUESTA aunque no se pueda
## pagar. Si se cortara al morir, un enemigo imposible y uno duro darían el
## mismo número.
func _un_combate(perfil: Dictionary, datos: Dictionary,
		bolsa: BolsaReliquias) -> Dictionary:
	var p := ParametrosCombate.new()
	p.vida_jugador = 1000000
	var c := Combate.new(p)
	c.bolsa = bolsa
	c.iniciar(Enemigo.new(datos))

	var perdida := [0]
	c.enemigo_ataca.connect(func(d: int) -> void: perdida[0] += d)

	var bolas := 0
	while not c.terminado() and bolas < MAX_BOLAS:
		bolas += 1
		_jugar_una_bola(c, perfil)
		if c.terminado():
			break
		_drenar(c)
		_avanzar(c, p.pausa_drenaje + p.pausa_ataque + 4.0 * DT)
	return {"bolas": bolas, "vida_perdida": perdida[0]}

func _jugar_una_bola(c: Combate, perfil: Dictionary) -> float:
	c.mesa.bola.en_carril = false
	c.avanzar(DT)

	var eventos: Array[String] = []
	for _i in int(perfil["golpes"]):
		eventos.append("bumper")
	for _i in int(perfil["targets"]):
		eventos.append("target")
	for _i in int(perfil["bancos"]):
		eventos.append("banco")
	for _i in int(perfil["orbitas"]):
		eventos.append("orbita")
	for _i in int(perfil["retornos"]):
		eventos.append("retorno")
	for _i in int(perfil["canones"]):
		eventos.append("canon")
	for _i in int(perfil["platillos"]):
		eventos.append("platillo")
	_barajar_estable(eventos)

	var hueco := float(perfil["segundos"]) / float(maxi(eventos.size(), 1))
	var gastado := 0.0
	for e in eventos:
		_avanzar(c, hueco)
		gastado += hueco
		if c.terminado():
			return gastado
		_evento(c, e)
		if c.terminado():
			return gastado
	return gastado

func _barajar_estable(lista: Array[String]) -> void:
	var salida: Array[String] = []
	var i := 0
	while not lista.is_empty():
		i = (i + 3) % lista.size()
		salida.append(lista[i])
		lista.remove_at(i)
	lista.assign(salida)

func _evento(c: Combate, cual: String) -> void:
	var punto := Vector2(200, 800)
	match cual:
		"bumper": c.mesa.bumper_golpeado.emit(punto, 500.0)
		"target": c.mesa.target_abatido.emit(punto, 0)
		"banco": c.mesa.banco_completado.emit(punto, 0)
		"platillo": c.mesa.platillo_expulsado.emit(punto, 0)
		_: _rampa(c, cual, punto)

func _rampa(c: Combate, cual: String, punto: Vector2) -> void:
	var premio := Rampa.Premio.MULTIPLICADOR
	if cual == "canon":
		premio = Rampa.Premio.DANO_FUERTE
	elif cual == "retorno":
		premio = Rampa.Premio.DANO
	for i in c.mesa.rampas.size():
		if (c.mesa.rampas[i] as Rampa).premio == premio:
			c.mesa.rampa_salida.emit(punto, i)
			return

func _drenar(c: Combate) -> void:
	c.mesa.bola.viva = false
	c.mesa.bola.vel = Vector2.ZERO
	c.mesa.bola_drenada.emit()

func _avanzar(c: Combate, segundos: float) -> void:
	for _i in int(segundos / DT):
		c.avanzar(DT)
