extends SceneTree

## Mide el balance CON RELIQUIAS PUESTAS y contra el jugador de verdad:
##   godot --headless --path . --script tests/medir_daniel.gd
##
## POR QUÉ EXISTE ESTO Y NO VALÍA `tests/medir_balance.gd`.
##
## `medir_balance.gd` juega runs de verdad —mapa, élites, jefes, vida que no se
## cura— pero el jugador de mentira NO COMPLETA MISIONES, así que llega al jefe
## del acto 3 con la bolsa vacía. Daniel llega con media tabla de reliquias
## encima. Las reliquias sube-vida-máxima y cura-al-matar son la diferencia
## entre perder 500 de 1080 (lo que decía el modelo) y perder 36 de 1800 (lo que
## pasó de verdad). O sea que el modelo no estaba midiendo un balance flojo:
## estaba midiendo a otro jugador.
##
## Aquí el combate comparte la bolsa del run, recibe la escalera de misiones
## real y, al completar una, tira la ruleta y se queda la reliquia — igual que
## la partida. Y la vida del jugador es la del run, no infinita, para que las
## reliquias condicionales ("cuando estés por debajo de la mitad") se enciendan
## cuando les toca en vez de no encenderse nunca.
##
## LAS BOLAS EXTRA, y por qué hay dos modos (`EXTRA=fisica` o `EXTRA=jugada`).
##
## El perfil describe lo que produce UNA bola y no tiene física dentro, pero el
## combate sí: lleva su `Mesa` de verdad, y una reliquia de Caos que suelta una
## bola la suelta en esa mesa. Lo que se hace con ella es lo que cambia:
##
##   - `fisica` (por defecto): lo de siempre. La extra sale por el lanzador y
##     vuela con física real, pero nadie toca las palas, así que cobra lo que
##     golpee por el camino y se cae; y la que siga viva al acabar el perfil la
##     retira `_drenar`. Es el modo con el que están medidas todas las tablas de
##     `ESTADO.md`, y por eso es el de defecto: cambiarlo movería números viejos.
##   - `jugada`: la extra la juega el MANIQUÍ de `medir_capas.gd` —pulsa la pala
##     de su lado 0,14 s cuando la bola baja de y=1150— con la física de la mesa,
##     y SOBREVIVE a la principal: cuando el perfil se acaba, la principal se cae
##     por `bola_perdida` y el turno sigue hasta que la mesa emite `bola_drenada`
##     con la última, que es el invariante de la multibola. Mientras hay extras,
##     la principal se aparca en el platillo: si no, la extra nace encima de ella
##     en el carril y la puede lanzar al campo (dos bolas jugando el mismo perfil).
##
## Con UNA bola los dos modos son el mismo camino, línea a línea: el maniquí no
## tiene a quién pulsarle y la cola no existe. Lo comprueba `SIN_BOLAS_EXTRA=1`,
## que quita del catálogo las tres reliquias que sueltan bolas.
##
## OJO con lo que `jugada` NO es: el maniquí no es Daniel. El perfil de la bola
## principal está calibrado contra él; las extras las juega un reflejo que
## aporrea. Es la mesa la que decide lo que da cada extra —golpes reales,
## cuestas reales, drenajes reales—, no un número escrito aquí, pero el que
## juega es otro.

const DT := 1.0 / 60.0
## Ver la cabecera. Se lee de `EXTRA` en `_initialize`.
var _modo_extra := "fisica"
## Las tres reliquias que sueltan bolas. Con `SIN_BOLAS_EXTRA=1` salen del
## catálogo y el modelo no puede tener nunca más de una bola: es la forma de
## comprobar que el código de multibola no toca el camino de una sola.
const SUELTAN_BOLAS := ["bifurcacion", "proceso_hijo", "bomba_de_procesos"]
## La bola que juega el perfil en el turno que corre. Con multibola no es
## siempre `mesa.bolas[0]`: tras una cola, la superviviente pasa a ser la [0].
var _principal: Bola = null
## Se está jugando la cola de una multibola: la principal ya se cayó y quedan
## extras. Una extra que salga ahora no aparca a nadie.
var _en_cola := false
var _pulso_izq := 0.0
var _pulso_der := 0.0
## El platillo donde se aparca la principal. Es el único de la planta baja.
const PARQUE := 0
## Tope de una cola de multibola. Con una caza de por medio y su salvabolas una
## extra puede vivir mucho; esto es la red, no una regla de juego.
const COLA_MAXIMA := 60.0
## Contadores de diagnóstico de la sección de Caos. No tocan nada de lo que se
## ejecuta: solo cuentan.
var _extras_soltadas := 0
var _bolas_servidas := 0
var _ticks_multibola := 0
var _ticks_total := 0
## Semilla fija: el modelo tiene que dar el mismo número dos veces seguidas o no
## se puede comparar un cambio de balance contra el de ayer.
var _rng := RandomNumberGenerator.new()
const MAX_BOLAS := 200
## LAS SEMILLAS DE LOS RUNS. Cinco por defecto, que es con lo que están medidas
## todas las tablas viejas. Con `SEMILLAS=N` se añaden hasta N (siempre las
## mismas), y hace falta para comparar dos versiones del juego: con cinco, el
## ruido es del tamaño de lo que se mide. Medido el 15-oct: con las mismas 14
## misiones, cambiar solo el ORDEN en que se sortean movía el daño por bola de
## Daniel de 810 a 690, y el del perfil puntero de 1699 a 1126 —reordenar qué
## reliquias salen ya es un 15-35 %—. Y el `_rng` de las velocidades de entrada
## es uno para todo el proceso, así que una fila depende de las que se midieron
## antes: con un filtro (`BUILDS`, `CASCABELES`) no sale el mismo número.
var SEMILLAS: Array = [13, 271, 4242, 90210, 31337]

## Los dos números de Daniel, medidos en un run ganado entero. Todo lo de aquí
## se juzga contra ellos: si el modelo no los reproduce, el modelo miente.
const DANIEL_DANO_BOLA := 797.0
const DANIEL_SEG_COMBATE := 45.0

## Lo que se busca al rebalancear, que es lo que decidió Daniel: que el combate
## dure y que cada reloj se note.
const DURACION_MIN := 120.0
const DURACION_MAX := 300.0
## Y que llegar al final cueste. Ganar con el 98 % es lo que se está arreglando.
const VIDA_FINAL_MIN := 0.25
const VIDA_FINAL_MAX := 0.60

## Candidatos a "perfil Daniel". El de arriba es el `bueno` de siempre; los de
## abajo bajan intensidad. Se elige el que reproduzca 797 y 45 s CON reliquias.
const CANDIDATOS := [
	{
		"nombre": "d-flojo", "segundos": 15.5,
		"golpes": 12, "targets": 3, "bancos": 0,
		"orbitas": 1, "retornos": 1, "canones": 0, "platillos": 1,
	},
]

func _initialize() -> void:
	_rng.seed = 20260820
	var n_semillas := int(OS.get_environment("SEMILLAS"))
	for i in range(SEMILLAS.size(), n_semillas):
		SEMILLAS.append(1000 + i * 7919)
	var enemigos := CatalogoEnemigos.cargar()
	var reliquias := CatalogoReliquias.cargar()
	var misiones := CatalogoMisiones.cargar()
	var modo := OS.get_environment("EXTRA")
	if modo == "jugada":
		_modo_extra = "jugada"
	elif modo != "" and modo != "fisica":
		push_error("EXTRA=%s no existe: vale 'fisica' o 'jugada'" % modo)
		quit(1)
		return
	if OS.get_environment("SIN_BOLAS_EXTRA") == "1":
		var sin: Array[Reliquia] = []
		for r in reliquias:
			if not SUELTAN_BOLAS.has(r.id):
				sin.append(r)
		reliquias = sin
	print("")
	print("MEDIDA CONTRA DANIEL  ·  objetivo %.0f de daño por bola, %.0f s por combate"
		% [DANIEL_DANO_BOLA, DANIEL_SEG_COMBATE])
	print("  catálogo: %d enemigos · %d reliquias · %d misiones  ·  bolas extra: %s"
		% [enemigos.size(), reliquias.size(), misiones.size(), _modo_extra])
	print("")
	# QUÉ SE MIDE. El barrido entero tarda trece minutos, y tocar balance es
	# darle vueltas al mismo mando: medir las tres secciones cada vez convierte
	# una iteración de un minuto en una de trece, y entonces se deja de medir y
	# se ajusta a ojo, que es exactamente como la tabla de enemigos se fue al
	# traste dos veces. Con `SOLO=cascabeles` (o `calibrar`, o `barrido`) se
	# lanza solo lo que se está tocando.
	var solo := OS.get_environment("SOLO")
	if solo == "" or solo == "calibrar":
		_calibrar(enemigos, reliquias, misiones)
	if solo == "" or solo == "barrido":
		_barrido(enemigos, reliquias, misiones)
	if solo == "" or solo == "cascabeles":
		_barrido_cascabeles(enemigos, reliquias, misiones)
	if solo == "tiros":
		_cruce_de_tiros(enemigos, reliquias, misiones)
	if solo == "caos":
		_barrido_caos(enemigos, reliquias, misiones)
	quit(0)

## El barrido de verdad: vida y ataque a la vez, CON reliquias puestas. Es lo
## que la tanda 1 mandaba hacer, solo que contra el jugador que existe.
const ESCALAS_VIDA := [0.8, 1.0, 1.2]
## Escala sobre TODA la curación de las reliquias. Es el eje que faltaba: el
## barrido de vida x ataque no llegó al objetivo en ninguna de sus 20 casillas
## porque quien decide el run no es la tabla de enemigos, es esto. Ya está
## aplicado en `data/reliquias.json` (la curación bajó a ~un tercio), así que
## aquí 1,0 es la configuración escrita y el resto es margen.
const ESCALAS_CURA := [1.0]
const ESCALAS_ATAQUE := [0.8, 1.0, 1.2]

## Las claves de reliquia que devuelven vida. `suma_vida_maxima` entra porque
## `Run._actualizar_vida_maxima()` da la vida nueva PUESTA: subir el techo cura.
const CLAVES_CURA := [
	"suma_curacion_al_matar",
	"suma_curacion_al_matar_por_victoria",
	"suma_vida_por_recorrido",
	"suma_vida_maxima",
	"suma_vida_maxima_por_victoria",
]

## Copia del catálogo con la curación escalada. Copia, no toca: el original se
## sigue usando en la casilla siguiente.
func _escalar_cura(reliquias: Array[Reliquia], escala: float) -> Array[Reliquia]:
	if is_equal_approx(escala, 1.0):
		return reliquias
	var salida: Array[Reliquia] = []
	for r in reliquias:
		var d := {
			"id": r.id, "nombre": r.nombre, "texto": r.texto, "eje": r.eje,
			"gancho": r.gancho, "cuando": r.cuando, "umbral": r.umbral,
			"icono": r.icono, "rareza": r.rareza,
			"efectos": r.efectos.duplicate(true),
		}
		for clave in CLAVES_CURA:
			if (d["efectos"] as Dictionary).has(clave):
				(d["efectos"] as Dictionary)[clave] = \
					float((d["efectos"] as Dictionary)[clave]) * escala
		salida.append(Reliquia.new(d))
	return salida

func _barrido(enemigos: Array, reliquias: Array[Reliquia],
		misiones: Array[Mision]) -> void:
	print("── barrido CON reliquias: vida x ataque ────────────────────")
	print("  objetivo: acabar el run con el %d-%d %% de vida y combates de %d-%d s"
		% [int(VIDA_FINAL_MIN * 100.0), int(VIDA_FINAL_MAX * 100.0),
			int(DURACION_MIN), int(DURACION_MAX)])
	print("")
	for cand in CANDIDATOS:
		print("  perfil %s" % str((cand as Dictionary)["nombre"]))
		print("  cura x%.2f en todas las filas" % ESCALAS_CURA[0])
		print("  %5s %5s %8s %9s %8s %6s %s" % [
			"vida", "atq", "d/bola", "s/combate", "reliq", "vida", "acaba"])
		for ev in ESCALAS_VIDA:
			for ea in ESCALAS_ATAQUE:
				var ec := ESCALAS_CURA[0]
				var r := _runs(cand as Dictionary, enemigos,
					_escalar_cura(reliquias, ec), misiones, SEMILLAS, ev, ea)
				var dur := float(r["seg_combate"])
				var vf := float(r["vida_frac"])
				var marca := ""
				if int(r["acabados"]) > 0 and vf >= VIDA_FINAL_MIN and vf <= VIDA_FINAL_MAX:
					marca += "  <<<"
				if dur >= DURACION_MIN and dur <= DURACION_MAX:
					marca += "  DURA"
				print("  %5.2f %5.2f %8.0f %9.0f %8.1f %6s %4d/%d%s" % [
					ev, ea, float(r["dano_bola"]), dur, float(r["reliquias"]),
					("%.0f%%" % (vf * 100.0)) if int(r["acabados"]) > 0 else "muere",
					int(r["acabados"]), SEMILLAS.size(), marca])
		print("")
	print("  <<< cumple la vida final   DURA cumple la duración")
	print("  la fila buena lleva las dos marcas.")
	print("")

# --------------------------------------------------------------- calibración

func _calibrar(enemigos: Array, reliquias: Array[Reliquia],
		misiones: Array[Mision]) -> void:
	print("── qué perfil es Daniel ────────────────────────────────────")
	print("  'seco' = sin reliquias (lo que medía el modelo viejo)")
	print("  'run'  = jugando el run entero con misiones y ruleta")
	print("")
	print("  %-8s %6s %8s %8s %8s %7s %6s" % [
		"perfil", "seco", "run d/bola", "s/combate", "reliquias", "vida", "acaba"])
	for cand in CANDIDATOS:
		var seco := _dano_por_bola(cand as Dictionary, null)
		var r := _runs(cand as Dictionary, enemigos, reliquias, misiones,
			SEMILLAS, 1.0, 1.0)
		print("  %-8s %6d %8.0f %8.0f %8.1f %6s %4d/%d" % [
			str((cand as Dictionary)["nombre"]), seco,
			float(r["dano_bola"]), float(r["seg_combate"]), float(r["reliquias"]),
			("%.0f%%" % (float(r["vida_frac"]) * 100.0)) if int(r["acabados"]) > 0 else "—",
			int(r["acabados"]), SEMILLAS.size()])
	print("")
	print("  Daniel de verdad: %.0f de daño por bola y %.0f s por combate, y ganó"
		% [DANIEL_DANO_BOLA, DANIEL_SEG_COMBATE])
	print("  con el 98 %% de la vida. El perfil bueno es el que se acerque a los")
	print("  tres números a la vez, no solo al daño.")
	print("")

## Daño de UNA bola contra un saco, sin reliquias. Es el número comparable con
## la tabla vieja de `medir_balance.gd`.
func _dano_por_bola(perfil: Dictionary, base: ParametrosCombate) -> int:
	var p := _copiar(base)
	p.vida_jugador = 100000000
	var c := Combate.new(p)
	c.mesa.rng.seed = 20260812
	c.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000000, "ataque": 1}))
	_jugar_una_bola(c, perfil)
	return c.dano_de_la_bola

# ---------------------------------------------------------------- el run real

## Un run entero con reliquias. Devuelve los mismos números que Daniel puede
## leer en su pantalla, para poder compararlos de tú a tú.
func _runs(perfil: Dictionary, enemigos: Array, reliquias: Array[Reliquia],
		misiones: Array[Mision], semillas: Array,
		escala_vida: float, escala_ataque: float,
		cascabel: String = "", forzadas: Array[Reliquia] = []) -> Dictionary:
	var catalogo := _escalar(enemigos, escala_vida, escala_ataque)
	var acabados := 0
	var nodos := 0
	var vida_frac := 0.0
	var bolsas := 0.0
	var dano_bola := 0.0
	var seg_combate := 0.0
	var runs := 0
	var muertes: Array[String] = []
	for semilla in semillas:
		var r := Run.new(ParametrosRun.new(), ParametrosCombate.new(), catalogo,
			int(semilla), reliquias, misiones)
		# EL CASCABEL ELEGIDO, si lo hay. Va en la bolsa BASE, igual que en la
		# partida: mete sus modificadores en el combate sin contar como reliquia
		# ganada. Con "" no se toca nada y el modelo mide exactamente lo que
		# medía antes de que existiera la capa de preparación, que es lo que hace
		# que las medidas viejas sigan siendo comparables.
		if cascabel != "":
			var pre := Preparacion.new()
			pre.cascabel = cascabel
			var casc := pre.como_reliquia()
			if casc != null:
				r.bolsa.base = [casc]
		# LAS RELIQUIAS FORZADAS, para medir una build concreta. Van con
		# `anadir` y no en `base`: `tiene()` solo mira `reliquias`, así que
		# desde `base` la ruleta podría volver a darla y el efecto se doblaría.
		# Sin forzadas no se toca nada.
		for rel in forzadas:
			r.bolsa.anadir(rel)
		while not r.terminada():
			var opciones := r.opciones()
			if opciones.is_empty():
				break
			var nodo := r.elegir(opciones[0])
			if nodo == null:
				break
			if not nodo.es_combate():
				continue
			var res := _combate_en_run(perfil, r, nodo.enemigo,
				int(semilla) * 100 + r.nodos_superados)
			r.apuntar_medida(int(res["bolas"]), int(res["dano"]), float(res["segundos"]))
			r.resolver_combate(bool(res["gano"]), int(res["vida"]))
			if not bool(res["gano"]):
				muertes.append("acto %d fila %d" % [nodo.acto + 1, nodo.fila + 1])
				break
		runs += 1
		nodos += r.nodos_superados
		bolsas += float(r.bolsa.reliquias.size() - forzadas.size())
		dano_bola += r.dano_por_bola()
		seg_combate += r.segundos_por_combate()
		if r.victoria:
			acabados += 1
			vida_frac += float(r.vida) / float(maxi(r.vida_maxima, 1))
	return {
		"acabados": acabados,
		"nodos": float(nodos) / float(maxi(runs, 1)),
		"vida_frac": vida_frac / float(maxi(acabados, 1)),
		"reliquias": bolsas / float(maxi(runs, 1)),
		"dano_bola": dano_bola / float(maxi(runs, 1)),
		"seg_combate": seg_combate / float(maxi(runs, 1)),
		"muertes": ", ".join(muertes),
	}

## Un combate dentro del run, con la bolsa del run puesta, la escalera de
## misiones real y la vida de verdad. Si el jugador muere, el combate se corta:
## aquí eso no es perder información, es el resultado.
##
## LA SEMILLA DE LA MESA. `Mesa._init` aleatoriza su `rng`, y lo usa el ball
## search. Con una bola no cambia nada —la principal descansa en el carril y el
## empujón no la saca de ahí ni emite nada que escuche el combate—, pero con
## extras sí, y sin fijarla el modelo deja de ser repetible justo en las builds
## de Caos. Va por run y por nodo, sin gastar azar de nadie.
func _combate_en_run(perfil: Dictionary, r: Run, datos: Dictionary,
		semilla_mesa: int = 0) -> Dictionary:
	var c := Combate.new(_copiar(r.pc))
	c.mesa.rng.seed = semilla_mesa
	c.bolsa = r.bolsa
	var misiones := r.escalera_de_misiones()
	c.mision_completada.connect(func(m: Mision) -> void:
		if r.abrir_ruleta(m.rareza):
			r.aceptar_premio())
	_preparar_extras(c)
	c.iniciar(Enemigo.new(datos), r.vida, misiones)

	var bolas := 0
	var segundos := 0.0
	while not c.terminado() and bolas < MAX_BOLAS:
		bolas += 1
		_bolas_servidas += 1
		segundos += _jugar_una_bola(c, perfil)
		if c.terminado():
			break
		segundos += _cerrar_turno(c)
		if c.terminado():
			break
		_avanzar(c, c.p.pausa_drenaje + c.p.pausa_ataque + 4.0 * DT)
	return {
		"bolas": bolas,
		"segundos": segundos,
		"dano": c.dano_total,
		"vida": c.vida_jugador,
		"gano": c.vida_jugador > 0,
	}

# ------------------------------------------------------------------ utilidad

func _copiar(base: ParametrosCombate) -> ParametrosCombate:
	var p := ParametrosCombate.new()
	if base == null:
		return p
	p.vida_jugador = base.vida_jugador
	p.dano_bumper = base.dano_bumper
	p.dano_target = base.dano_target
	p.dano_banco = base.dano_banco
	p.dano_girador = base.dano_girador
	p.dano_rampa = base.dano_rampa
	p.dano_rampa_fuerte = base.dano_rampa_fuerte
	p.dano_platillo = base.dano_platillo
	p.tramos_combo = base.tramos_combo.duplicate(true)
	p.reloj_carga = base.reloj_carga
	p.reloj_aviso = base.reloj_aviso
	p.factor_ataque_drenaje = base.factor_ataque_drenaje
	p.platillo_atrasa_reloj = base.platillo_atrasa_reloj
	p.golpes_tramo_extra = base.golpes_tramo_extra
	return p

func _escalar(catalogo: Array, escala: float, escala_ataque: float) -> Array:
	var salida: Array = []
	for datos in catalogo:
		var copia: Dictionary = (datos as Dictionary).duplicate()
		copia["vida"] = maxi(int(round(float(copia.get("vida", 100)) * escala)), 1)
		copia["ataque"] = maxi(int(round(
			float(copia.get("ataque", 10)) * escala_ataque)), 1)
		salida.append(copia)
	return salida

func _jugar_una_bola(c: Combate, perfil: Dictionary) -> float:
	# La principal es la servida, que es la [0] justo después de servir: las
	# extras de Bomba se añaden detrás. Si ya está aparcada, se queda aparcada.
	_principal = c.mesa.bolas[0]
	_en_cola = false
	c.mesa.bola.en_carril = false
	_tic(c)

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

	var total := float(perfil["segundos"])
	var hueco := total / float(maxi(eventos.size(), 1))
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

## UN TIRO A UNA RAMPA, Y DESDE QUE LAS RAMPAS TIENEN CUESTA NO ES LO MISMO QUE
## COMPLETARLA. El perfil dice "Daniel mete una órbita por bola"; lo que eso
## significa ahora es que la INTENTA, y si entra por debajo de la velocidad de
## escape se queda a medias y no cobra. Las dos mitades hacen falta para medir:
##
##   - **el fallo quita ingresos**, que es el coste de la cuesta.
##   - **el intento carga la barra igual**, que es lo que lo devuelve.
##
## Si el modelo siguiera emitiendo `rampa_salida` a pelo, mediría una mesa que ya
## no existe y diría que la cuesta es gratis.
##
## Las velocidades salen medidas de `tests/sonda_rampas.gd`: mínimo, los tres
## cuartiles y máximo de las entradas de verdad. **Se sortea POR CUARTILES y no
## uniforme entre el mínimo y el máximo**, y esa diferencia no es un refinamiento:
## las entradas se agolpan abajo —en la órbita, la mitad cae entre 505 y 613 y la
## otra mitad se estira hasta 1169— así que un sorteo uniforme pondría casi todo
## el peso por encima de la frontera y mediría una cuesta que no falla nunca.
##
## Sorteando por cuartiles el modelo reproduce los fallos medidos jugando (23 %
## en la órbita, 25 % en el cañón), que es la única forma de que lo que salga de
## aquí sea el balance de la mesa y no el de un histograma inventado.
const ENTRADA_RAMPA := {
	"orbita": [505.0, 573.0, 613.0, 723.0, 1169.0],
	# El retorno lleva la del cañón: misma boca, misma subida, mismo número de
	# escape. Se juega menos —paga menos— y su muestra propia es de seis.
	"retorno": [545.0, 602.0, 642.0, 786.0, 892.0],
	"canon": [545.0, 602.0, 642.0, 786.0, 892.0],
}

## Un sorteo dentro de la distribución medida: cuartil al azar y uniforme dentro
## de él. Cinco números y sale la forma, sin guardar la muestra entera.
func _velocidad_de_entrada(cual: String) -> float:
	var q: Array = ENTRADA_RAMPA.get(cual, [])
	if q.size() != 5:
		return 700.0
	var i := _rng.randi_range(0, 3)
	return _rng.randf_range(float(q[i]), float(q[i + 1]))

func _rampa(c: Combate, cual: String, punto: Vector2) -> void:
	var premio := Rampa.Premio.MULTIPLICADOR
	if cual == "canon":
		premio = Rampa.Premio.DANO_FUERTE
	elif cual == "retorno":
		premio = Rampa.Premio.DANO
	var v := _velocidad_de_entrada(cual)
	for i in c.mesa.rampas.size():
		var r := c.mesa.rampas[i] as Rampa
		if r.premio != premio:
			continue
		c.mesa.cargar_barra(r, v)
		if not r.corona(v):
			return
		# Completarla es lo que gasta la descarga, y hay que decirlo a mano: el
		# modelo no recorre la curva, así que no pasa por la salida de
		# `Mesa._avanzar_rampa()`, que es quien lo hace jugando.
		c.mesa.gastar_descarga(punto)
		c.mesa.rampa_salida.emit(punto, i)
		return

## Drenar de mentira: el perfil no juega con las palas, así que la bola no se
## pierde sola. RETIRA TODAS LAS BOLAS, no solo la principal: con multibola,
## apagar `mesa.bola` dejaba las extra vivas para siempre, y eso hacía dos
## trampas a la vez —seguían pegando en los bumpers y dejaban `bolas` a más de
## uno, o sea `cuando: multibola` encendido el run entero—. El resultado medido
## de ese fallo: 97 % de vida al acabar contra el 71 % de verdad.
##
## Con `EXTRA=fisica` esto cierra también la multibola: las extras que sigan
## vivas se retiran con la principal. Con `EXTRA=jugada` solo se llega aquí sin
## extras vivas; si las hay, el turno lo cierra `_cola_multibola`.
func _drenar(c: Combate) -> void:
	c.mesa.retirar_bolas()
	c.mesa.bola_drenada.emit()

## Cierra el turno cuando el perfil de la principal se ha acabado. Devuelve los
## segundos de más que se han jugado, que son los de la cola: el reloj del
## enemigo corre durante ella igual que durante la bola.
func _cerrar_turno(c: Combate) -> float:
	if _modo_extra == "jugada" and _quedan_extras(c):
		return _cola_multibola(c)
	_drenar(c)
	return 0.0

func _avanzar(c: Combate, segundos: float) -> void:
	for _i in int(segundos / DT):
		_tic(c)

## UN PASO DEL MODELO. Con una bola es `c.avanzar(DT)` a secas: el maniquí no
## tiene a quién pulsarle y los contadores solo cuentan.
func _tic(c: Combate) -> void:
	if _modo_extra == "jugada":
		_palas_del_maniqui(c)
	c.avanzar(DT)
	_ticks_total += 1
	if c.mesa.bolas_vivas() >= 2:
		_ticks_multibola += 1

# ------------------------------------------------------------ la multibola

## Engancha lo que hace falta para jugar las extras. Va ANTES de `iniciar`: la
## bola de Bomba sale dentro de él, al servir la primera.
func _preparar_extras(c: Combate) -> void:
	_principal = null
	_en_cola = false
	_pulso_izq = 0.0
	_pulso_der = 0.0
	c.bola_extra_soltada.connect(func(cuantas: int, _total: int) -> void:
		_extras_soltadas += cuantas)
	if _modo_extra != "jugada":
		return
	# Con una REFERENCIA DÉBIL al combate: la mesa guarda la conexión, y una
	# lambda que capturase `c` cerraría el ciclo mesa → lambda → combate → mesa,
	# y como los dos son RefCounted no se soltarían nunca. Son mil combates por
	# barrido.
	var debil: WeakRef = weakref(c)
	c.mesa.bola_extra.connect(func(_p: Vector2, _total: int) -> void:
		var cc: Combate = debil.get_ref() as Combate
		if cc != null:
			_al_salir_extra(cc))

## Ha salido una extra. La principal se aparca, si sigue en juego: el perfil la
## sigue jugando por señales, que no necesitan que la bola esté en ningún sitio,
## y así no comparte carril con la extra que acaba de nacer encima de ella.
##
## UN SESGO QUE HAY QUE SABER: se aparca en el platillo, que es el único sitio
## donde una bola se queda quieta sin chocar ni caerse, y en un platillo cabe
## una. Mientras dura la multibola, las extras no pueden caer en él. El platillo
## está escondido bajo el arco y el maniquí casi nunca lo alcanza, así que pesa
## poco, pero es una diferencia con el juego y va a favor de NO cobrar platillos.
func _al_salir_extra(c: Combate) -> void:
	if _en_cola:
		return
	var b := c.mesa.bolas[0]
	if not b.viva or b.platillo == PARQUE:
		return
	_principal = b
	b.vel = Vector2.ZERO
	b.en_carril = false
	b.platillo = PARQUE
	b.platillo_espera = 1.0e9
	b.pos = c.mesa.platillos[PARQUE].centro

func _quedan_extras(c: Combate) -> bool:
	for b in c.mesa.bolas:
		if b.viva and b != _principal:
			return true
	return false

## EL MANIQUÍ, el de `medir_capas.gd`: pulsa la pala de su lado 0,14 s cuando una
## extra libre baja hacia ella. Con un pulso por lado y no uno para las dos,
## porque con dos bolas puede tocar una a cada lado. La principal no cuenta: está
## aparcada, o en el carril.
##
## Y CON LAS DOS PLANTAS: la línea de "baja hacia la pala" es y=1150 abajo y 50 px
## por encima de las palas cortas arriba, y cada tecla mueve las dos palas de su
## lado, como en el juego (`VistaMesa` pulsa las cuatro con A y D). Sin esto, una
## extra que subía a cazar en la cola no la jugaba nadie y el salvabolas la tenía
## veinte segundos rebotando sola.
func _palas_del_maniqui(c: Combate) -> void:
	_pulso_izq -= DT
	_pulso_der -= DT
	for b in c.mesa.bolas:
		if b == _principal or not b.viva or not b.libre() or b.en_carril:
			continue
		var linea := c.mesa.p.arena_y_pala - 50.0 if c.mesa.en_la_arena(b) else 1150.0
		if b.pos.y > linea and b.vel.y > 0.0:
			if b.pos.x < Mesa.ANCHO * 0.5:
				if _pulso_izq <= 0.0:
					_pulso_izq = 0.14
			elif _pulso_der <= 0.0:
				_pulso_der = 0.14
	c.mesa.flipper_izq.pulsado = _pulso_izq > 0.0
	c.mesa.flipper_alto_izq.pulsado = _pulso_izq > 0.0
	c.mesa.flipper_der.pulsado = _pulso_der > 0.0
	c.mesa.flipper_alto_der.pulsado = _pulso_der > 0.0

## LA COLA DE UNA MULTIBOLA. La principal se cae como se caería jugando —por
## abajo— y, como quedan otras, la mesa la saca por `bola_perdida`, sin coste.
## Luego se sigue jugando hasta que caiga la última, que es la que trae
## `bola_drenada` y cierra el turno. Lo decide la mesa, no el modelo.
func _cola_multibola(c: Combate) -> float:
	_en_cola = true
	var b := _principal
	if b != null and c.mesa.bolas.has(b) and b.viva:
		b.platillo = -1
		b.platillo_espera = 0.0
		b.en_carril = false
		b.vel = Vector2.ZERO
		b.pos = Vector2(Mesa.ANCHO * 0.5, c.mesa.p.y_drenaje + 40.0)
	var t := 0.0
	while t < COLA_MAXIMA and not c.terminado() and _jugandose(c):
		_tic(c)
		t += DT
	if not c.terminado() and _jugandose(c):
		_drenar(c)
	_en_cola = false
	return t

func _jugandose(c: Combate) -> bool:
	return c.fase == Combate.Fase.LANZANDO or c.fase == Combate.Fase.BOLA_VIVA


# ------------------------------------------------------- la capa de preparación

## QUÉ LE HACE CADA CASCABEL AL RUN.
##
## `PROPÓSITO.md` §4 pone la regla: **un cascabel cambia qué tiro te compensa, no
## cuánto pegas.** Esta tabla es la que dice si eso se ha cumplido o si lo que
## hay son nueve variantes de "+X de daño" con nombres distintos.
##
## Cómo se lee, y esto importa más que los números sueltos:
##
## - **`casc_acero` tiene que salir CLAVADO al barrido de arriba.** Es el neutro,
##   así que si se desvía, algo de la capa de preparación no es neutro y todas
##   las medidas anteriores han dejado de valer sin avisar.
## - **La columna que interesa NO es el daño, es la DISPERSIÓN.** Nueve
##   cascabeles que acaban el run con la misma vida son nueve cascabeles que no
##   cambian nada, por muy distinto que suene su texto.
## - Un cascabel que acabe SIEMPRE el run es demasiado fuerte, y uno que no lo
##   acabe nunca no es una elección, es una trampa.
##
## Ojo con lo que esto NO mide: **las palas no salen aquí y no pueden salir.**
## Un perfil describe lo que una bola PRODUCE, no juega con las palas: dentro no
## hay física. Así que el efecto de unas palas cortas —más drenajes— es
## exactamente lo que este modelo no ve. Para eso están las tres pruebas de
## `_prueba_palas_jugables` en la batería y, después, jugarlo.
func _barrido_cascabeles(enemigos: Array, reliquias: Array[Reliquia],
		misiones: Array[Mision]) -> void:
	var perfil: Dictionary = CANDIDATOS[0]
	print("")
	print("CASCABELES  ·  el mismo run, %d semillas, cambiando solo el cascabel"
		% SEMILLAS.size())
	print("  %-14s %9s %9s %8s %7s  %s"
		% ["cascabel", "daño/bola", "s/combate", "vida fin", "acaba", "a qué tiro empuja"])
	# Y se puede filtrar a unos pocos: `CASCABELES=casc_vidrio,casc_oxido`. Nueve
	# cascabeles son quince minutos, y ajustar tres de ellos no necesita volver a
	# medir los seis que no se tocan. Acero entra SIEMPRE aunque no se pida: es el
	# neutro, y una medida sin su control no se puede comparar con la anterior.
	var filtro := OS.get_environment("CASCABELES")
	var pedidos: Array = [] if filtro == "" else Array(filtro.split(",", false))
	var vidas: Array[float] = []
	for ficha in Preparacion.cascabeles():
		var el_id := str((ficha as Dictionary).get("id", ""))
		if not pedidos.is_empty() and el_id != "casc_acero" \
				and not pedidos.has(el_id):
			continue
		var r := _runs(perfil, enemigos, reliquias, misiones, SEMILLAS, 1.0, 1.0, el_id)
		var pre := Preparacion.new()
		pre.cascabel = el_id
		if int(r["acabados"]) > 0:
			vidas.append(float(r["vida_frac"]))
		print("  %-14s %9.0f %9.1f %8s %5d/%d  %s" % [
			pre.nombre_cascabel(), float(r["dano_bola"]), float(r["seg_combate"]),
			("%.0f%%" % (float(r["vida_frac"]) * 100.0)) if int(r["acabados"]) > 0 else "—",
			int(r["acabados"]), SEMILLAS.size(),
			str((ficha as Dictionary).get("tiro", ""))])
	if vidas.size() >= 2:
		var lo := vidas[0]
		var hi := vidas[0]
		for v in vidas:
			lo = minf(lo, v)
			hi = maxf(hi, v)
		print("")
		print("  Dispersión de vida al acabar: %.0f puntos (del %.0f %% al %.0f %%)."
			% [(hi - lo) * 100.0, lo * 100.0, hi * 100.0])
		print("  Poca dispersión = los cascabeles no cambian la partida, solo el texto.")
	print("")


## ¿DE VERDAD CAMBIA UN CASCABEL A QUÉ TIRO VAS?
##
## Es el pilar entero (`DISEÑO.md` §1, `PROPÓSITO.md` §4) y hasta ahora NADIE lo
## comprobaba. La tabla de cascabeles dice cuánto pega cada uno con UN jugador;
## esta dice si cada uno prefiere un jugador distinto, que es lo que separa
## "nueve modificadores" de "nueve formas de jugar".
##
##     godot --headless --path . --script tests/medir_daniel.gd   (con SOLO=tiros)
##
## Cómo se lee: **en cada fila hay que ganar con el perfil que dice su `tiro`.**
## Si Piedra —"targets y cañón"— rinde igual con el racimero que con el puntero,
## su tradeoff no existe y es un modificador plano con un texto bonito. Y si
## TODOS los cascabeles prefieren al mismo perfil, lo que hay no son nueve
## elecciones, es un ranking.
##
## Tres semillas y no cinco a propósito: son nueve casillas y con cinco esto
## tarda veinte minutos, o sea que se deja de lanzar. Con tres el ruido sube,
## así que lo que se mira es QUÉ COLUMNA GANA cada fila, no el número exacto.
const PERFILES_TIRO := [
	{
		"nombre": "racimero", "segundos": 15.5,
		"golpes": 16, "targets": 1, "bancos": 0,
		"orbitas": 0, "retornos": 1, "canones": 0, "platillos": 0,
	},
	{
		"nombre": "puntero", "segundos": 15.5,
		"golpes": 6, "targets": 6, "bancos": 1,
		"orbitas": 0, "retornos": 1, "canones": 2, "platillos": 0,
	},
	{
		"nombre": "corredor", "segundos": 15.5,
		"golpes": 6, "targets": 1, "bancos": 0,
		"orbitas": 3, "retornos": 4, "canones": 2, "platillos": 1,
	},
]

## El daño por bola de Acero en cada columna. Es la vara con la que se miden los
## demás: sin ella, la tabla mide qué perfil pega más, que ya se sabe.
var _referencia_tiros: Array[float] = []

func _cruce_de_tiros(enemigos: Array, reliquias: Array[Reliquia],
		misiones: Array[Mision]) -> void:
	var filtro := OS.get_environment("CASCABELES")
	var pedidos: Array = [] if filtro == "" else Array(filtro.split(",", false))
	var semillas := [13, 271, 4242]
	print("")
	print("CASCABEL x TIRO  ·  daño por bola, %d semillas" % semillas.size())
	print("  %-10s %10s %10s %10s   %s"
		% ["cascabel", "racimero", "puntero", "corredor", "a qué tiro dice empujar"])
	for ficha in Preparacion.cascabeles():
		var el_id := str((ficha as Dictionary).get("id", ""))
		# Acero entra SIEMPRE: es la vara con la que se dividen las demás filas,
		# y sin él los ratios saldrían contra 1,0 —o sea, en crudo— sin que nada
		# avisara de que la tabla ha dejado de significar lo que dice.
		if not pedidos.is_empty() and el_id != "casc_acero" \
				and not pedidos.has(el_id):
			continue
		var pre := Preparacion.new()
		pre.cascabel = el_id
		var fila: Array[float] = []
		for perfil in PERFILES_TIRO:
			var r := _runs(perfil, enemigos, reliquias, misiones, semillas,
				1.0, 1.0, el_id)
			fila.append(float(r["dano_bola"]))
		# CONTRA ACERO, NO EN CRUDO. Los tres perfiles no pegan ni parecido —el
		# corredor hace 1999 por bola y el racimero 265, porque los recorridos
		# son el tiro difícil y pagan concentrado—, así que en números crudos
		# GANA SIEMPRE la columna del corredor y la tabla no dice nada del
		# cascabel. Lo que informa es cuánto sube cada uno SOBRE el neutro dentro
		# de su propia columna.
		if el_id == "casc_acero":
			_referencia_tiros = fila.duplicate()
		var celdas: Array[String] = []
		var mejor := 0
		var ratios: Array[float] = []
		for i in fila.size():
			var base: float = 1.0 if i >= _referencia_tiros.size() \
				else maxf(_referencia_tiros[i], 0.001)
			ratios.append(fila[i] / base)
			if ratios[i] > ratios[mejor]:
				mejor = i
		for i in fila.size():
			celdas.append("x%.2f%s" % [ratios[i], " <<" if i == mejor
				and el_id != "casc_acero" else ""])
		print("  %-10s %10s %10s %10s   %s" % [pre.nombre_cascabel(),
			celdas[0], celdas[1], celdas[2],
			str((ficha as Dictionary).get("tiro", ""))])
	print("")
	print("  Si todas las filas ganan por la misma columna, no hay nueve")
	print("  elecciones: hay un ranking con nueve nombres.")
	print("")


# ------------------------------------------------------------- el eje de Caos

## LAS BUILDS DE CAOS, medidas por fin con bolas que se juegan.
##
##     godot --headless --path . --script tests/medir_daniel.gd   (con SOLO=caos)
##
## y con `EXTRA=jugada` para que las extras se jueguen; con `EXTRA=fisica` sale
## lo que medía el modelo hasta ahora, que es la otra punta de la horquilla.
##
## Cada build se FUERZA desde el principio del run (`_runs(..., forzadas)`), y
## eso cambia también la ruleta —quita esas reliquias de las candidatas—, así
## que el run entero mide la build más su efecto sobre lo que te toca después.
## Para separar las dos cosas va la columna SECO: un combate contra un saco con
## SOLO la build en la bolsa, veinte bolas, sin misiones ni ruleta. Esa columna
## es la que dice cuánto pega la build; la del run, cuánto le cambia la partida.
##
## `proceso_hijo` cobra al cerrar un BANCO, y el perfil de Daniel no cierra
## ninguno: con él no salta nunca, salvo que una extra cierre uno por su cuenta.
## Por eso se mide también con el `puntero` de `PERFILES_TIRO`, que cierra uno
## por bola, con su propio control al lado.
const BUILDS_CAOS := [
	{"nombre": "ninguna", "ids": []},
	{"nombre": "bomba", "ids": ["bomba_de_procesos"]},
	{"nombre": "bifurcación", "ids": ["bifurcacion"]},
	{"nombre": "proceso hijo", "ids": ["proceso_hijo"]},
	{"nombre": "carrera", "ids": ["condicion_de_carrera"]},
	{"nombre": "hilo único", "ids": ["hilo_unico"]},
	{"nombre": "bomba+carrera", "ids": ["bomba_de_procesos", "condicion_de_carrera"]},
	{"nombre": "bifurc+carrera", "ids": ["bifurcacion", "condicion_de_carrera"]},
	{"nombre": "bomba+hilo", "ids": ["bomba_de_procesos", "hilo_unico"]},
	{"nombre": "las cinco", "ids": ["bomba_de_procesos", "bifurcacion",
		"proceso_hijo", "condicion_de_carrera", "hilo_unico"]},
	{"nombre": "ninguna (punt.)", "ids": [], "perfil": 1},
	{"nombre": "p. hijo (punt.)", "ids": ["proceso_hijo"], "perfil": 1},
]
## Bolas del combate seco. Veinte da para que una probabilidad de 1/8 por
## recorrido salga unas cuantas veces sin que la columna tarde más que un run.
const BOLAS_SECO := 20

func _barrido_caos(enemigos: Array, reliquias: Array[Reliquia],
		misiones: Array[Mision]) -> void:
	print("")
	print("CAOS  ·  bolas extra: %s  ·  %d semillas  ·  seco = %d bolas contra un saco"
		% [_modo_extra, SEMILLAS.size(), BOLAS_SECO])
	print("  %-16s %7s %9s %9s %7s %6s %8s %7s"
		% ["build", "seco", "d/bola", "s/combate", "vida", "acaba", "extras", "multi"])
	var por_id := {}
	for r in reliquias:
		por_id[r.id] = r
	# Y se puede filtrar: `BUILDS=bomba,las cinco`. La de control entra siempre.
	var filtro := OS.get_environment("BUILDS")
	var pedidas: Array = [] if filtro == "" else Array(filtro.split(",", false))
	for b in BUILDS_CAOS:
		var nombre := str((b as Dictionary)["nombre"])
		if not pedidas.is_empty() and not nombre.begins_with("ninguna") \
				and not pedidas.has(nombre):
			continue
		var forzadas: Array[Reliquia] = []
		var faltan: Array[String] = []
		for id in (b as Dictionary)["ids"]:
			if por_id.has(id):
				forzadas.append(por_id[id])
			else:
				faltan.append(str(id))
		if not faltan.is_empty():
			print("  %-16s  no está en el catálogo: %s" % [nombre, ", ".join(faltan)])
			continue
		var perfil: Dictionary = CANDIDATOS[0]
		if (b as Dictionary).has("perfil"):
			perfil = PERFILES_TIRO[int((b as Dictionary)["perfil"])]
		var seco := _seco_con_bolsa(perfil, forzadas)
		_extras_soltadas = 0
		_ticks_multibola = 0
		_ticks_total = 0
		var bolas_antes := _bolas_servidas
		var r := _runs(perfil, enemigos, reliquias, misiones, SEMILLAS, 1.0, 1.0,
			"", forzadas)
		var servidas := maxi(_bolas_servidas - bolas_antes, 1)
		print("  %-16s %7.0f %9.0f %9.1f %7s %4d/%d %8.2f %6.0f%%" % [
			nombre, seco, float(r["dano_bola"]), float(r["seg_combate"]),
			("%.0f%%" % (float(r["vida_frac"]) * 100.0)) if int(r["acabados"]) > 0 else "—",
			int(r["acabados"]), SEMILLAS.size(),
			float(_extras_soltadas) / float(servidas),
			100.0 * float(_ticks_multibola) / float(maxi(_ticks_total, 1))])
	print("")
	print("  seco     daño por bola servida contra un saco, solo con la build")
	print("  extras   bolas extra soltadas por bola servida, en el run")
	print("  multi    parte del tiempo de juego con dos o más bolas vivas")
	print("")

## Un combate contra un saco con la build y nada más: sin ruleta, sin misiones,
## con su propia bolsa sembrada. Determinista. Devuelve daño por bola servida.
func _seco_con_bolsa(perfil: Dictionary, forzadas: Array[Reliquia]) -> float:
	var p := ParametrosCombate.new()
	p.vida_jugador = 100000000
	var c := Combate.new(p)
	c.mesa.rng.seed = 20260812
	var bolsa := BolsaReliquias.new(20260812)
	for rel in forzadas:
		bolsa.anadir(rel)
	c.bolsa = bolsa
	_preparar_extras(c)
	c.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000000, "ataque": 1}))
	for _i in BOLAS_SECO:
		_jugar_una_bola(c, perfil)
		if c.terminado():
			break
		_cerrar_turno(c)
		if c.terminado():
			break
		_avanzar(c, c.p.pausa_drenaje + c.p.pausa_ataque + 4.0 * DT)
	return float(c.dano_total) / float(BOLAS_SECO)

