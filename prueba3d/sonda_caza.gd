extends SceneTree

## PRUEBA 3D — sonda de la caza. No es una prueba: no falla, imprime.
##
##     Godot --headless --path <repo> --script prueba3d/sonda_caza.gd
##     ... -- --segundos=240 --semillas=4
##
## Juega sola con las criaturas sueltas y apunta lo que la vista no enseña:
##
##   1. EL GRAFO: que ningún nodo esté suelto, que se llegue de todos a todos y
##      que ninguna arista roce nada (repasada cada 2 px, más fino que al hacerla).
##   2. GOLPES DE MENTIRA: desde cada nodo, en dieciséis direcciones y a dos
##      velocidades, se la manda volar. Tiene que volver a la plaza siempre.
##   3. PARTIDAS: cuánto pasa en cada estado y el rato MÁS LARGO seguido en cada
##      uno (todos tienen tope), los contadores que tienen que dar cero, golpes
##      y capturas por minuto, y con qué velocidad le llega la bola.
##   4. LA MESA, CON Y SIN FAUNA: si las criaturas le cambian la vida a la bola
##      —duración, paradas, recorridos—. No deberían estorbar.
##   5. DETERMINISMO: la misma semilla dos veces tiene que dar la misma caza.
##
## Es la pregunta de `CLAUDE.md` para todo rincón nuevo: no si cabe, sino si se
## queda.

const MesaOrbita := preload("res://prueba3d/mesa_orbita.gd")
const Caza := preload("res://prueba3d/caza_orbita.gd")
const Criatura := preload("res://prueba3d/criatura.gd")

const DT := 1.0 / 120.0

func _init() -> void:
	var segundos := 180.0
	var semillas := 3
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--segundos="):
			segundos = float(arg.trim_prefix("--segundos="))
		elif arg.begins_with("--semillas="):
			semillas = int(arg.trim_prefix("--semillas="))

	_grafo()
	_golpes_de_mentira()

	print("== PARTIDAS: %d semillas de %.0f s ==" % [semillas, segundos])
	var total := {}
	for s in semillas:
		var r := _partida(100 + s, segundos, true)
		_sumar(total, r)
		print("  semilla %d: golpes %d · recogidas %d · aseguradas %d · escapadas %d · huella %s" % [
			100 + s, r["golpeada"], r["recogida"], r["asegurada"], r["escapada"], r["huella"]])
	_informe(total, segundos * float(semillas))

	print("== LA MESA, CON Y SIN FAUNA (misma semilla, %.0f s) ==" % segundos)
	var con := _partida(100, segundos, true)
	var sin := _partida(100, segundos, false)
	for clave in ["bolas", "paradas_bola", "orbita", "cometa", "estacion", "gusano", "soles"]:
		print("  %-13s con %5d · sin %5d" % [clave, con[clave], sin[clave]])
	print("  dónde se para la bola CON fauna (celdas de 10 px): ", con["celdas"])
	print("  dónde se para la bola SIN fauna: ", sin["celdas"])

	var otra := _partida(100, segundos, true)
	print("== DETERMINISMO: %s ==" % ("IGUAL" if otra["huella"] == con["huella"] \
		else "DISTINTO  %s / %s" % [con["huella"], otra["huella"]]))
	quit()

# ----------------------------------------------------------------------- grafo

func _grafo() -> void:
	var mesa: Mesa = MesaOrbita.new()
	var caza := Caza.new()
	caza.preparar(mesa, 1)
	print("== GRAFO: %d nodos (%d de plaza, %d bocas) ==" % [caza.nodos.size(),
		Caza.PLAZA.size(), caza.bocas.size()])
	var aristas := 0
	var malas := 0
	for i in caza.nodos.size():
		var v: PackedInt32Array = caza.vecinos[i]
		if v.is_empty():
			print("  NODO SUELTO %d en %s" % [i, caza.nodos[i]])
		if not caza.cabe(mesa, caza.nodos[i], 19.0):
			print("  NODO SIN SITIO %d en %s" % [i, caza.nodos[i]])
		for j in v:
			if j < i:
				continue
			aristas += 1
			var a := caza.nodos[i]
			var b := caza.nodos[j]
			var pasos := maxi(int(ceil(a.distance_to(b) / 2.0)), 1)
			for k in pasos + 1:
				if not caza.cabe(mesa, a.lerp(b, float(k) / float(pasos)), 19.0):
					malas += 1
					print("  ARISTA QUE ROZA: %d-%d" % [i, j])
					break
	var visto := {0: true}
	var cola := [0]
	while not cola.is_empty():
		var n: int = cola.pop_back()
		for k in (caza.vecinos[n] as PackedInt32Array):
			if not visto.has(k):
				visto[k] = true
				cola.append(k)
	print("  aristas %d · que rozan %d · alcanzables desde el 0: %d de %d" % [
		aristas, malas, visto.size(), caza.nodos.size()])
	var lineas := ""
	for i in caza.nodos.size():
		lineas += "%d:%s " % [i, str(caza.vecinos[i])]
	print("  ", lineas)

# -------------------------------------------------------------- golpes de mentira

func _golpes_de_mentira() -> void:
	var mesa: Mesa = MesaOrbita.new()
	var caza := Caza.new()
	caza.preparar(mesa, 1)
	mesa.bolas[0].viva = false
	var vuelven := 0
	var rescatadas := 0
	var tarde := 0
	var total := 0
	var peor := 0.0
	for especie_i in [0, 2]:
		var c: Criatura = caza.criaturas[especie_i]
		for nodo in Caza.PLAZA.size():
			for d in 16:
				for v in [220.0, 520.0]:
					total += 1
					var antes := caza.rescates
					c.activa = true
					c.asegurada = false
					c.miedo = 0.0
					c.volcando = false
					c.empujada = false
					c.espera = -1.0
					c.pos = caza.nodos[nodo]
					c.vel = Vector2.from_angle(TAU * float(d) / 16.0) * v
					c.cambiar(Criatura.Estado.VOLAR)
					var t := 0.0
					var en_plaza := false
					while t < 6.0:
						caza.avanzar(mesa, DT)
						t += DT
						if c.estado == Criatura.Estado.CORRER or c.estado == Criatura.Estado.HUIR:
							en_plaza = true
							break
					if caza.rescates > antes:
						rescatadas += 1
					if en_plaza:
						vuelven += 1
						peor = maxf(peor, t)
					else:
						tarde += 1
		c.cambiar(Criatura.Estado.FUERA)
		c.espera = -1.0
	print("== GOLPES DE MENTIRA: %d ==" % total)
	print("  vuelven a la plaza %d · de ellas por rescate %d · NO vuelven en 6 s %d · la que más tarda %.2f s" % [
		vuelven, rescatadas, tarde, peor])
	print("  sin salida %d · vigía %d · rama por defecto %d" % [
		caza.sin_salida, caza.saltos_de_vigia, caza.ramas_por_defecto])

# --------------------------------------------------------------------- partidas

func _partida(semilla: int, segundos: float, con_fauna: bool) -> Dictionary:
	var mesa: Mesa = MesaOrbita.new()
	mesa.rng.seed = semilla
	var caza := Caza.new()
	caza.preparar(mesa, semilla)
	if con_fauna:
		mesa.set("caza", caza)
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla * 7 + 1

	var r := {"alerta": 0, "golpeada": 0, "blindada": 0, "volcada": 0, "partida": 0,
		"reunida": 0, "acorralada": 0, "rehecha": 0, "recogida": 0, "asegurada": 0,
		"enteras": 0, "escapada": 0, "escondida": 0, "expulsada": 0, "tapada": 0,
		"olas": 0, "bolas": 1, "paradas_bola": 0, "orbita": 0, "cometa": 0,
		"estacion": 0, "gusano": 0, "soles": 0, "fuerzas": [],
		"nan": 0, "fuera_de_sitio": 0}
	caza.criatura_alerta.connect(func(_c: RefCounted) -> void: r["alerta"] += 1)
	caza.criatura_golpeada.connect(func(_c: RefCounted, _p: Vector2, f: float, _n: Vector2) -> void:
		r["golpeada"] += 1
		(r["fuerzas"] as Array).append(f))
	caza.criatura_blindada.connect(func(_c: RefCounted, _p: Vector2, _f: float) -> void: r["blindada"] += 1)
	caza.criatura_volcada.connect(func(_c: RefCounted, _p: Vector2) -> void: r["volcada"] += 1)
	caza.criatura_partida.connect(func(_c: RefCounted, _p: Vector2) -> void: r["partida"] += 1)
	caza.criatura_reunida.connect(func(_c: RefCounted, _p: Vector2) -> void: r["reunida"] += 1)
	caza.criatura_acorralada.connect(func(_c: RefCounted) -> void: r["acorralada"] += 1)
	caza.criatura_rehecha.connect(func(_c: RefCounted) -> void: r["rehecha"] += 1)
	caza.criatura_recogida.connect(func(_c: RefCounted, _p: Vector2) -> void: r["recogida"] += 1)
	caza.criatura_asegurada.connect(func(c: RefCounted, _p: Vector2) -> void:
		r["asegurada"] += 1
		if bool(c.get("principal")):
			r["enteras"] += 1)
	caza.criatura_escapada.connect(func(_c: RefCounted, _p: Vector2) -> void: r["escapada"] += 1)
	caza.criatura_escondida.connect(func(_c: RefCounted, _p: Vector2) -> void: r["escondida"] += 1)
	caza.criatura_expulsada.connect(func(_c: RefCounted, _p: Vector2) -> void: r["expulsada"] += 1)
	caza.boca_tapada.connect(func(_b: int, _p: Vector2) -> void: r["tapada"] += 1)
	caza.caza_completa.connect(func(_o: int) -> void: r["olas"] += 1)
	var celdas := {}
	r["celdas"] = celdas
	mesa.busqueda_bola.connect(func(pt: Vector2) -> void:
		r["paradas_bola"] += 1
		var clave := "%d,%d" % [int(pt.x / 10.0) * 10, int(pt.y / 10.0) * 10]
		celdas[clave] = int(celdas.get(clave, 0)) + 1)
	mesa.bumper_golpeado.connect(func(_p: Vector2, _f: float) -> void: r["soles"] += 1)
	mesa.rampa_salida.connect(func(_p: Vector2, i: int) -> void:
		var nombre: String = mesa.rampas[i].nombre
		if r.has(nombre):
			r[nombre] += 1)
	var drenada := [false]
	mesa.bola_drenada.connect(func() -> void: drenada[0] = true)

	var n_estados := Criatura.Estado.size()
	var n := caza.criaturas.size()
	var en_estado: Array = []
	var racha: Array = []
	var racha_max: Array = []
	var estado_antes := PackedInt32Array()
	for i in n:
		var a: Array = []
		var b: Array = []
		for _k in n_estados:
			a.append(0.0)
			b.append(0.0)
		en_estado.append(a)
		racha_max.append(b)
		racha.append(0.0)
		estado_antes.append(-1)

	var t := 0.0
	var carga := 0.0
	var pulso_i := 0.0
	var pulso_d := 0.0
	var descanso_i := 0.0
	var descanso_d := 0.0
	var huella := 0
	var siguiente_huella := 1.0
	var lados: Array = mesa.get("lado_pala")
	mesa.nueva_bola()
	while t < segundos:
		if drenada[0]:
			drenada[0] = false
			mesa.nueva_bola()
			r["bolas"] += 1
		var bola: Bola = mesa.bolas[0]
		var lanzar := false
		if bola.en_carril and bola.libre():
			carga += DT
			lanzar = carga < 1.0
			if carga > 1.2:
				carga = 0.0
		else:
			carga = 0.0
		if lanzar:
			mesa.cargar_lanzador(DT)
		elif mesa.cargando:
			mesa.soltar_lanzador()
		pulso_i = maxf(pulso_i - DT, 0.0)
		pulso_d = maxf(pulso_d - DT, 0.0)
		descanso_i = maxf(descanso_i - DT, 0.0)
		descanso_d = maxf(descanso_d - DT, 0.0)
		# EL FIGURANTE SUELTA LA PALA: un palazo y un descanso. Si vuelve a
		# pulsar mientras la bola siga cerca, la deja acunada para siempre y la
		# sonda mide una mesa en la que no pasa nada (ver `sonda_orbita.gd`).
		if bola.libre() and bola.vel.y > -20.0:
			for k in mesa.flippers.size():
				var f: Flipper = mesa.flippers[k]
				if not f.en_capa(bola.capa):
					continue
				var d := bola.pos - f.eje
				var lado: int = lados[k]
				var ocupada := (pulso_i > 0.0 or descanso_i > 0.0) if lado < 0 \
					else (pulso_d > 0.0 or descanso_d > 0.0)
				if ocupada:
					continue
				if absf(d.y + 12.0) < 18.0 and d.x * float(-lado) > f.longitud * 0.25 \
						and absf(d.x) < f.longitud + 8.0 and rng.randf() < 0.5:
					var pulso := rng.randf_range(0.08, 0.2)
					if lado < 0:
						pulso_i = pulso
						descanso_i = pulso + 0.35
					else:
						pulso_d = pulso
						descanso_d = pulso + 0.35
		for k in mesa.flippers.size():
			var lado: int = lados[k]
			mesa.flippers[k].pulsado = (pulso_i if lado < 0 else pulso_d) > 0.0
		mesa.avanzar(DT)
		if not con_fauna:
			t += DT
			continue
		t += DT

		for i in n:
			var c: Criatura = caza.criaturas[i]
			var tiempos: Array = en_estado[i]
			tiempos[c.estado] = float(tiempos[c.estado]) + DT
			if c.estado == estado_antes[i]:
				racha[i] = float(racha[i]) + DT
			else:
				racha[i] = 0.0
				estado_antes[i] = c.estado
			var fila: Array = racha_max[i]
			fila[c.estado] = maxf(float(fila[c.estado]), float(racha[i]))
			if is_nan(c.pos.x) or is_nan(c.pos.y) or is_nan(c.vel.x) or is_nan(c.vel.y):
				r["nan"] += 1
			# Andando o quieta tiene que estar en la plaza, y con sitio.
			if c.a_pie() or c.estado == Criatura.Estado.ACORRALADA \
					or c.estado == Criatura.Estado.ATURDIDA:
				if c.pos.y > caza.y_rescate + 1.0 or not caza.cabe(mesa, c.pos, c.radio - 3.0):
					r["fuera_de_sitio"] += 1
		if t >= siguiente_huella:
			siguiente_huella += 1.0
			for i in n:
				var c: Criatura = caza.criaturas[i]
				huella = (huella * 31 + int(c.pos.x * 10.0) + int(c.pos.y * 10.0) * 7
					+ c.estado * 131) % 1000000007

	r["huella"] = huella
	r["en_estado"] = en_estado
	r["racha_max"] = racha_max
	r["rescates"] = caza.rescates
	r["sin_salida"] = caza.sin_salida
	r["vigia"] = caza.saltos_de_vigia
	r["defecto"] = caza.ramas_por_defecto
	r["capturas"] = caza.capturas
	var nombres: Array = []
	for c in caza.criaturas:
		nombres.append(c.nombre)
	r["nombres"] = nombres
	return r

func _sumar(total: Dictionary, r: Dictionary) -> void:
	for clave in r:
		var v: Variant = r[clave]
		if v is int:
			total[clave] = int(total.get(clave, 0)) + int(v)
		elif clave == "fuerzas":
			if not total.has(clave):
				total[clave] = []
			(total[clave] as Array).append_array(v)
		elif clave == "en_estado" or clave == "racha_max":
			if not total.has(clave):
				total[clave] = v
				continue
			var acumulado: Array = total[clave]
			for i in acumulado.size():
				var a: Array = acumulado[i]
				var b: Array = (v as Array)[i]
				for k in a.size():
					a[k] = float(a[k]) + float(b[k]) if clave == "en_estado" 						else maxf(float(a[k]), float(b[k]))
		elif clave == "nombres":
			total[clave] = v

func _informe(r: Dictionary, segundos: float) -> void:
	var minutos := segundos / 60.0
	print("  sucesos: alerta %d · golpes %d · coraza %d · volcado %d · partida %d · reunida %d" % [
		r["alerta"], r["golpeada"], r["blindada"], r["volcada"], r["partida"], r["reunida"]])
	print("           acorralada %d · rehecha %d · escondida %d · expulsada %d · boca tapada %d" % [
		r["acorralada"], r["rehecha"], r["escondida"], r["expulsada"], r["tapada"]])
	print("           recogidas %d · aseguradas %d (enteras %d) · escapadas %d · olas %d" % [
		r["recogida"], r["asegurada"], r["enteras"], r["escapada"], r["olas"]])
	print("  por minuto: golpes %.1f · criaturas aseguradas %.2f" % [
		float(r["golpeada"]) / minutos, float(r["enteras"]) / minutos])
	var fuerzas: Array = r["fuerzas"]
	fuerzas.sort()
	if fuerzas.size() > 3:
		print("  velocidad del golpe (px/s): mínima %.0f · cuartil %.0f · mediana %.0f · cuartil %.0f · máxima %.0f" % [
			fuerzas[0], fuerzas[fuerzas.size() / 4], fuerzas[fuerzas.size() / 2],
			fuerzas[fuerzas.size() * 3 / 4], fuerzas[fuerzas.size() - 1]])
	print("  TIENEN QUE DAR CERO: sin salida %d · vigía %d · rama por defecto %d · NaN %d · fuera de sitio %d" % [
		r["sin_salida"], r["vigia"], r["defecto"], r["nan"], r["fuera_de_sitio"]])
	print("  rescates (salió volando de la plaza): %d" % r["rescates"])
	var estados := Criatura.Estado.keys()
	var nombres: Array = r["nombres"]
	print("  reparto del tiempo, y entre paréntesis el rato más largo seguido:")
	for i in nombres.size():
		var fila: Array = (r["en_estado"] as Array)[i]
		var rachas: Array = (r["racha_max"] as Array)[i]
		var texto := ""
		for k in estados.size():
			if float(fila[k]) > segundos * 0.002:
				texto += "%s %.0f%% (%.1f s)  " % [estados[k],
					100.0 * float(fila[k]) / segundos, float(rachas[k])]
		print("    %-7s %s" % [nombres[i], texto])
