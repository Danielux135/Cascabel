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

const DT := 1.0 / 60.0
const MAX_BOLAS := 200
const SEMILLAS := [13, 271, 4242, 90210, 31337]

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
	var enemigos := CatalogoEnemigos.cargar()
	var reliquias := CatalogoReliquias.cargar()
	var misiones := CatalogoMisiones.cargar()
	print("")
	print("MEDIDA CONTRA DANIEL  ·  objetivo %.0f de daño por bola, %.0f s por combate"
		% [DANIEL_DANO_BOLA, DANIEL_SEG_COMBATE])
	print("  catálogo: %d enemigos · %d reliquias · %d misiones"
		% [enemigos.size(), reliquias.size(), misiones.size()])
	print("")
	_calibrar(enemigos, reliquias, misiones)
	_barrido(enemigos, reliquias, misiones)
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
	c.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000000, "ataque": 1}))
	_jugar_una_bola(c, perfil)
	return c.dano_de_la_bola

# ---------------------------------------------------------------- el run real

## Un run entero con reliquias. Devuelve los mismos números que Daniel puede
## leer en su pantalla, para poder compararlos de tú a tú.
func _runs(perfil: Dictionary, enemigos: Array, reliquias: Array[Reliquia],
		misiones: Array[Mision], semillas: Array,
		escala_vida: float, escala_ataque: float) -> Dictionary:
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
		while not r.terminada():
			var opciones := r.opciones()
			if opciones.is_empty():
				break
			var nodo := r.elegir(opciones[0])
			if nodo == null:
				break
			if not nodo.es_combate():
				continue
			var res := _combate_en_run(perfil, r, nodo.enemigo)
			r.apuntar_medida(int(res["bolas"]), int(res["dano"]), float(res["segundos"]))
			r.resolver_combate(bool(res["gano"]), int(res["vida"]))
			if not bool(res["gano"]):
				muertes.append("acto %d fila %d" % [nodo.acto + 1, nodo.fila + 1])
				break
		runs += 1
		nodos += r.nodos_superados
		bolsas += float(r.bolsa.reliquias.size())
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
func _combate_en_run(perfil: Dictionary, r: Run, datos: Dictionary) -> Dictionary:
	var c := Combate.new(_copiar(r.pc))
	c.bolsa = r.bolsa
	var misiones := r.escalera_de_misiones()
	c.mision_completada.connect(func(m: Mision) -> void:
		if r.abrir_ruleta(m.rareza):
			r.aceptar_premio())
	c.iniciar(Enemigo.new(datos), r.vida, misiones)

	var bolas := 0
	var segundos := 0.0
	while not c.terminado() and bolas < MAX_BOLAS:
		bolas += 1
		segundos += _jugar_una_bola(c, perfil)
		if c.terminado():
			break
		_drenar(c)
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
