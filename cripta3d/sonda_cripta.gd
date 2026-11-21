extends SceneTree

## SEGUNDA PRUEBA 3D — sonda de la mesa «CRIPTA». No es una prueba: no falla, imprime.
##
##     python cripta3d/herramientas/godot3d.py guion res://cripta3d/sonda_cripta.gd --tiempo 600 --lineas 60
##     ... -- --semillas=5                             (cinco series, para ver cuánto baila la media)
##     ... -- --semillas=5 --desde=5                   (las cinco series siguientes: otras semillas)
##     ... -- --mesa=res://prueba3d/mesa_orbita.gd     (la MISMA sonda sobre ÓRBITA: la línea de base)
##
## Es la de `prueba3d/sonda_orbita.gd` con la mesa de la cripta: el mismo jugador
## de mentira, las mismas dos semillas (7 la mesa, 11 el figurante) y las mismas
## sesenta bolas, así que sin argumentos y con la mesa sin tocar da los números de
## ÓRBITA uno por uno. Eso es lo que la hace servir de regla: lo que cambie al
## añadir una pieza es de la pieza.
##
## Lo que apunta de más, porque es lo que CRIPTA añade encima:
##
##   · LA CAMPANA (la barra de carga): cuánto carga cada bola —en «entradas
##     limpias», la unidad de `carga_entradas`—, cuántas veces se arma, cuántas
##     toca y en qué recorrido, y cuántas veces se pierde armada al drenar. Y lo
##     que cuesta que toque: cuántas veces drena la bola justo después de
##     coronar cada recorrido, con la campana recién tocada y sin ella.
##   · LOS TORNOS, uno por uno: cuántas entradas a su boca pasaron por él y con
##     qué rumbo lo cruza la bola.
##   · LOS BANCOS, uno por uno (lápidas y escudos).
##   · LOS PLATILLOS, uno por uno: cuántas bolas se tragan y cuántas se pierden
##     antes de 3 s de escupirlas.
##   · POR DÓNDE SE VA la bola: outlane izquierdo, centro u outlane derecho. Una
##     pieza pegada a una banda puede no parar ni una bola y aun así mandarlas
##     todas al outlane de debajo.
##   · DÓNDE SE PARA, con el píxel medio de cada celda. Es la pregunta de la skill
##     `mesa-geometria` para cualquier rincón nuevo: no si la bola cabe, sino si
##     se queda.
##
## Ningún oyente de aquí toca la mesa: solo cuentan. Con las mismas semillas, la
## partida es la misma con la sonda vieja y con esta.

const MESA_POR_DEFECTO := "res://cripta3d/mesa_cripta.gd"
const DT := 1.0 / 120.0
const BOLAS := 60
## A los 90 s se corta la bola: es un figurante atascado en un bucle, no un récord.
const TOPE_BOLA := 90.0
## Una entrada «pasó por el torno» si el torno de esa boca giró este rato antes.
## A 500 px/s, que es lo mínimo con lo que engancha una rampa, 0,35 s son 175 px.
const VENTANA_TORNO := 0.35
## Un torno es «de» la boca que tenga a menos de esto. El de la galería está a 35.
const TORNO_ALCANCE := 80.0
## Cuántas series se juegan a la vez, cada una en su hilo.
const HILOS := 5

func _init() -> void:
	var ruta := MESA_POR_DEFECTO
	var semillas := 1
	var desde := 0
	var bolas := BOLAS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mesa="):
			ruta = arg.trim_prefix("--mesa=")
		elif arg.begins_with("--semillas="):
			semillas = maxi(int(arg.trim_prefix("--semillas=")), 1)
		elif arg.begins_with("--desde="):
			desde = maxi(int(arg.trim_prefix("--desde=")), 0)
		elif arg.begins_with("--bolas="):
			bolas = maxi(int(arg.trim_prefix("--bolas=")), 1)
	var guion := load(ruta) as GDScript
	if guion == null:
		print("no encuentro la mesa: ", ruta)
		quit()
		return

	var series: Array = []
	if semillas == 1:
		series.append(_serie(guion, desde, bolas))
	else:
		# CADA SERIE EN SU HILO, DE CINCO EN CINCO. No comparten nada —cada una
		# tiene su mesa y sus dos semillas, y `Mesa` no guarda estado fuera de sí
		# misma—, así que el resultado es el mismo que una detrás de otra
		# (comprobado: las cinco medias salen iguales al decimal). Se gana poco:
		# una serie tarda 35 s y cinco en hilos entre 125 y 155 s.
		#
		# Y NO MÁS DE CINCO A LA VEZ: quince hilos tardaron 963 s, casi el doble
		# que quince series en fila. En este equipo hay cuatro núcleos, y con más
		# hilos que núcleos se pasan el rato esperándose unos a otros. Un Godot de
		# 16 minutos, además, deja sin turno a quien esté esperando el candado:
		# para más de cinco series, la sonda se lanza varias veces con `--desde`.
		var k := 0
		while k < semillas:
			var hilos: Array[Thread] = []
			for j in mini(HILOS, semillas - k):
				var hilo := Thread.new()
				hilo.start(_serie.bind(guion, desde + k + j, bolas))
				hilos.append(hilo)
			for hilo in hilos:
				series.append(hilo.wait_to_finish())
			k += hilos.size()
	if semillas == 1:
		_informe(series[0], ruta)
	else:
		# Con varias series lo que se mira es la dispersión: sesenta bolas de un
		# figurante al azar bailan varios segundos de una semilla a otra, y una
		# pieza nueva solo «desploma» la bola media si la saca de ese baile.
		print("== %d SERIES de %d bolas · %s ==" % [semillas, bolas, ruta])
		var medias: Array = []
		for k in semillas:
			var r: Dictionary = series[k]
			var d: Array = r["duraciones"]
			medias.append(_media(d))
			print("  serie %d (semillas %d/%d): media %.1f s · mediana %.1f s · paradas %d · drena izq %d centro %d der %d" % [
				desde + k, 7 + 100 * (desde + k), 11 + 100 * (desde + k), _media(d),
				_mediana(d), _total(r["paradas"]),
				r["drenajes"]["izq"], r["drenajes"]["centro"], r["drenajes"]["der"]])
		var m := _media(medias)
		var var_ := 0.0
		for x in medias:
			var_ += (float(x) - m) * (float(x) - m)
		print("  media de las medias %.1f s · desviación entre series %.1f s" % [
			m, sqrt(var_ / float(maxi(medias.size() - 1, 1)))])
		_informe(_juntar(series), ruta)
	quit()

# ------------------------------------------------------------------- una serie

func _serie(guion: GDScript, k: int, bolas: int) -> Dictionary:
	var mesa: Mesa = guion.new()
	mesa.rng.seed = 7 + 100 * k
	var rng := RandomNumberGenerator.new()
	rng.seed = 11 + 100 * k

	var entradas := {}
	var salidas := {}
	var falladas := {}
	var paradas := {}
	var paradas_xy := {}
	var cuenta := {"bumper": 0, "sling": 0, "target": 0, "banco": 0,
		"girador": 0, "platillo": 0, "caida": 0}
	var reloj := [0.0]
	var nombres: Array = []
	for r in mesa.rampas:
		nombres.append(r.nombre)

	mesa.rampa_salida.connect(func(_p: Vector2, i: int) -> void:
		var n: String = mesa.rampas[i].nombre
		salidas[n] = int(salidas.get(n, 0)) + 1)
	mesa.rampa_fallada.connect(func(_p: Vector2, i: int, _r: float) -> void:
		var n: String = mesa.rampas[i].nombre
		falladas[n] = int(falladas.get(n, 0)) + 1)
	mesa.busqueda_bola.connect(func(pt: Vector2) -> void:
		var clave := "%d,%d" % [int(pt.x / 10.0) * 10, int(pt.y / 10.0) * 10]
		paradas[clave] = int(paradas.get(clave, 0)) + 1
		paradas_xy[clave] = (paradas_xy.get(clave, Vector2.ZERO) as Vector2) + pt)
	mesa.bumper_golpeado.connect(func(_p: Vector2, _f: float) -> void: cuenta["bumper"] += 1)
	mesa.slingshot_golpeado.connect(func(_p: Vector2, _f: float) -> void: cuenta["sling"] += 1)
	mesa.bola_cayo.connect(func(_p: Vector2, _d: int, _h: int) -> void: cuenta["caida"] += 1)

	# --- LOS PLATILLOS, uno por uno, y si lo que escupen llega a algún sitio -----
	# «Que la bola drene no significa que el juego funcione»: de un platillo se
	# apunta cuántas veces la bola se pierde antes de 3 s de haberla escupido.
	var tragadas: Array = []
	var escupe_y_drena: Array = []
	var escupida := {"i": -1, "t": -1000.0}
	for _i in mesa.platillos.size():
		tragadas.append(0)
		escupe_y_drena.append(0)
	mesa.platillo_capturado.connect(func(_p: Vector2, i: int) -> void:
		cuenta["platillo"] += 1
		tragadas[i] += 1)
	mesa.platillo_expulsado.connect(func(_p: Vector2, i: int) -> void:
		escupida["i"] = i
		escupida["t"] = reloj[0])

	# --- LOS BANCOS, uno por uno --------------------------------------------
	var abatidos: Array = []
	var completos: Array = []
	for _i in mesa.bancos.size():
		abatidos.append(0)
		completos.append(0)
	mesa.target_abatido.connect(func(_p: Vector2, b: int) -> void:
		cuenta["target"] += 1
		abatidos[b] += 1)
	mesa.banco_completado.connect(func(_p: Vector2, b: int) -> void:
		cuenta["banco"] += 1
		completos[b] += 1)

	# --- LOS TORNOS, uno por uno, y de qué boca es cada uno -------------------
	var giros: Array = []
	var ultimo_giro: Array = []
	var boca_de: Array = []
	var con_giro: Array = []
	var subiendo: Array = []
	var rumbo: Array = []
	for g in mesa.giradores:
		giros.append(0)
		ultimo_giro.append(-1000.0)
		con_giro.append(0)
		subiendo.append(0)
		rumbo.append(Vector2.ZERO)
		var mejor := -1
		var mejor_d := TORNO_ALCANCE
		for i in mesa.rampas.size():
			var d := g.distance_to(mesa.rampas[i].puntos[0])
			if d < mejor_d:
				mejor_d = d
				mejor = i
		boca_de.append(mejor)
	mesa.girador_girado.connect(func(_p: Vector2, i: int, _f: float) -> void:
		cuenta["girador"] += 1
		giros[i] += 1
		ultimo_giro[i] = reloj[0]
		# Por dónde lo cruza la bola cuando SUBE, que es cuando va a la boca: de
		# ahí sale hacia dónde tiene que mirar el eje del molinete al dibujarlo.
		var v: Vector2 = mesa.bolas[0].vel
		if v.y < 0.0:
			subiendo[i] += 1
			rumbo[i] = (rumbo[i] as Vector2) + v.normalized())

	# --- LA CAMPANA ------------------------------------------------------------
	# `unidades` es lo que cargaría cada entrada con `carga_entradas` a 1: el
	# cuadrado de (velocidad de entrada / velocidad de escape). Es la cuenta de
	# `Mesa.cargar_barra`, hecha aquí para poder medirla con la barra apagada.
	var campana := {"cambios": 0, "armadas": 0, "descargas": 0, "terminadas": 0,
		"perdidas_armada": 0, "cortadas": 0, "segundos": 0.0}
	var unidades := {}
	var toca_en := {}
	var recien := [false]
	var armada_antes := [false]
	mesa.rampa_entrada.connect(func(_p: Vector2, i: int) -> void:
		var r: Rampa = mesa.rampas[i]
		entradas[r.nombre] = int(entradas.get(r.nombre, 0)) + 1
		var escape := r.velocidad_escape if r.velocidad_escape > 0.0 \
			else mesa.p.carga_escape_llano
		var ratio := mesa.bolas[0].rampa_velocidad / maxf(escape, 1.0)
		unidades[r.nombre] = float(unidades.get(r.nombre, 0.0)) + ratio * ratio
		for g in boca_de.size():
			if boca_de[g] == i and reloj[0] - float(ultimo_giro[g]) < VENTANA_TORNO:
				con_giro[g] += 1)
	mesa.carga_cambiada.connect(func(_f: float, armada: bool) -> void:
		campana["cambios"] += 1
		if armada and not armada_antes[0]:
			campana["armadas"] += 1
		armada_antes[0] = armada)
	mesa.descarga_empezada.connect(func(_p: Vector2, _s: float) -> void:
		campana["descargas"] += 1
		recien[0] = true)
	mesa.descarga_terminada.connect(func() -> void: campana["terminadas"] += 1)
	# Va DESPUÉS de conectar el contador de salidas: `rampa_salida` sale justo
	# detrás de `descarga_empezada`, y así se sabe qué recorrido la ha tocado.
	#
	# Y LO QUE CUESTA QUE TOQUE. La descarga puede sacar la bola de la rampa más
	# rápido (`descarga_factor_salida`), y una bola que llega a la pala al doble
	# de velocidad se pierde. Se apunta, por recorrido, cuántas veces la bola
	# drena antes de `descarga_tiempo` de haberlo coronado, separando las que
	# salieron con la campana recién tocada de las que no: la diferencia entre las
	# dos columnas es lo que cuesta el toque.
	var ultima := {"nombre": "", "t": -1000.0, "campana": false}
	var tras_salida := {}
	var tras_campana := {}
	mesa.rampa_salida.connect(func(_p: Vector2, i: int) -> void:
		var n: String = mesa.rampas[i].nombre
		ultima["nombre"] = n
		ultima["t"] = reloj[0]
		ultima["campana"] = recien[0]
		if recien[0]:
			recien[0] = false
			toca_en[n] = int(toca_en.get(n, 0)) + 1)

	var drenada := [false]
	var drenajes := {"izq": 0, "centro": 0, "der": 0}
	mesa.bola_drenada.connect(func() -> void:
		drenada[0] = true
		# Las palas dejan en medio un hueco de x=168 a x=232; lo que cae por
		# fuera de 110 o de 290 ha bajado por un outlane.
		var x: float = mesa.bolas[0].pos.x
		drenajes["izq" if x < 110.0 else ("der" if x > 290.0 else "centro")] += 1
		if mesa.descarga_armada:
			campana["perdidas_armada"] += 1
		if mesa.descarga_restante > 0.0:
			campana["cortadas"] += 1
		if reloj[0] - float(ultima["t"]) < mesa.p.descarga_tiempo:
			var n: String = ultima["nombre"]
			tras_salida[n] = int(tras_salida.get(n, 0)) + 1
			if bool(ultima["campana"]):
				tras_campana[n] = int(tras_campana.get(n, 0)) + 1
		if int(escupida["i"]) >= 0 and reloj[0] - float(escupida["t"]) < 3.0:
			escupe_y_drena[int(escupida["i"])] += 1)

	var dt := DT
	var total := 0.0
	var sin_lanzar := 0
	var cortadas := 0
	var en_estacion := 0.0
	var duraciones: Array = []
	for _n in bolas:
		mesa.nueva_bola()
		mesa.reiniciar_targets()
		drenada[0] = false
		ultima["t"] = -1000.0
		escupida["t"] = -1000.0
		var t := 0.0
		var carga := 0.0
		var pulso_i := 0.0
		var pulso_d := 0.0
		var descanso_i := 0.0
		var descanso_d := 0.0
		while not drenada[0] and t < TOPE_BOLA:
			var b: Bola = mesa.bolas[0]
			var lanzar := false
			if b.en_carril and b.libre():
				carga += dt
				lanzar = carga < 1.0
				if carga > 1.2:
					carga = 0.0
			else:
				carga = 0.0
			if lanzar:
				mesa.cargar_lanzador(dt)
			elif mesa.cargando:
				mesa.soltar_lanzador()
			pulso_i = maxf(pulso_i - dt, 0.0)
			pulso_d = maxf(pulso_d - dt, 0.0)
			descanso_i = maxf(descanso_i - dt, 0.0)
			descanso_d = maxf(descanso_d - dt, 0.0)
			# EL FIGURANTE, palabra por palabra el de `sonda_orbita.gd`: un palazo
			# y un descanso, y solo cuando la bola ya ha rodado un trecho por la
			# pala. No se le toca ni una coma: cada `randf` de más o de menos
			# descuadra la partida entera respecto de la línea de base.
			if b.libre() and b.vel.y > -20.0:
				for k2 in mesa.flippers.size():
					var f: Flipper = mesa.flippers[k2]
					if not f.en_capa(b.capa):
						continue
					var d := b.pos - f.eje
					var lado: int = mesa.get("lado_pala")[k2]
					var ocupada := (pulso_i > 0.0 or descanso_i > 0.0) if lado < 0 \
						else (pulso_d > 0.0 or descanso_d > 0.0)
					if ocupada:
						continue
					if absf(d.y + 12.0) < 18.0 and d.x * float(-lado) > f.longitud * 0.25 \
							and absf(d.x) < f.longitud + 8.0 \
							and rng.randf() < 0.5:
						var pulso := rng.randf_range(0.08, 0.2)
						if lado < 0:
							pulso_i = pulso
							descanso_i = pulso + 0.35
						else:
							pulso_d = pulso
							descanso_d = pulso + 0.35
			for k2 in mesa.flippers.size():
				var lado: int = mesa.get("lado_pala")[k2]
				mesa.flippers[k2].pulsado = (pulso_i if lado < 0 else pulso_d) > 0.0
			mesa.avanzar(dt)
			if b.capa == Mesa.CAPA_ALTA:
				en_estacion += dt
			if mesa.descarga_restante > 0.0:
				campana["segundos"] += dt
			t += dt
			reloj[0] += dt
		if t >= TOPE_BOLA:
			cortadas += 1
		if t < 3.0:
			sin_lanzar += 1
		total += t
		duraciones.append(t)

	var tornos: Array = []
	for g in mesa.giradores.size():
		var de := int(boca_de[g])
		tornos.append({"punto": mesa.giradores[g],
			"boca": (nombres[de] as String) if de >= 0 else "", "giros": giros[g],
			"con_giro": con_giro[g], "subiendo": subiendo[g], "rumbo": rumbo[g]})
	var bancos: Array = []
	for i in mesa.bancos.size():
		bancos.append({"centro": mesa.centro_banco(i), "piezas": mesa.bancos[i].size(),
			"abatidos": abatidos[i], "completos": completos[i]})
	var platillos: Array = []
	for i in mesa.platillos.size():
		platillos.append({"centro": mesa.platillos[i].centro, "tragadas": tragadas[i],
			"escupe_y_drena": escupe_y_drena[i]})
	return {"bolas": bolas, "duraciones": duraciones, "cortadas": cortadas,
		"sin_lanzar": sin_lanzar, "en_estacion": en_estacion, "nombres": nombres,
		"entradas": entradas, "salidas": salidas, "falladas": falladas,
		"cuenta": cuenta, "paradas": paradas, "paradas_xy": paradas_xy,
		"tornos": tornos, "bancos": bancos, "platillos": platillos, "campana": campana,
		"unidades": unidades, "toca_en": toca_en, "drenajes": drenajes,
		"tras_salida": tras_salida, "tras_campana": tras_campana,
		"carga_entradas": mesa.p.carga_entradas,
		"descarga_tiempo": mesa.p.descarga_tiempo,
		"descarga_factor_salida": mesa.p.descarga_factor_salida,
		"piezas": "%d bumpers · %d targets en %d bancos · %d tornos · %d platillos · %d recorridos · %d colisionadores" % [
			mesa.bumpers.size(), mesa.targets.size(), mesa.bancos.size(),
			mesa.giradores.size(), mesa.platillos.size(), mesa.rampas.size(),
			mesa.colisionadores.size()]}

# --------------------------------------------------------------------- informe

func _informe(r: Dictionary, ruta: String) -> void:
	var bolas := int(r["bolas"])
	var duraciones: Array = r["duraciones"]
	var entradas: Dictionary = r["entradas"]
	var salidas: Dictionary = r["salidas"]
	var falladas: Dictionary = r["falladas"]
	print("== CRIPTA · %d bolas · %.1f s de media ==   (%s)" % [bolas, _media(duraciones), ruta])
	print("   ", r["piezas"])
	var orden := duraciones.duplicate()
	orden.sort()
	print("mediana %.1f s · la más corta %.1f s · la más larga %.1f s" % [
		_mediana(duraciones), orden[0], orden[orden.size() - 1]])
	print("cortadas a los 90 s: %d · drenadas antes de 3 s: %d" % [r["cortadas"], r["sin_lanzar"]])
	print("tiempo en el coro: %.1f s" % float(r["en_estacion"]))
	var d: Dictionary = r["drenajes"]
	print("por dónde se va: outlane izquierdo %d · centro %d · outlane derecho %d" % [
		d["izq"], d["centro"], d["der"]])
	var entradas_total := 0
	for n: String in r["nombres"]:
		entradas_total += int(entradas.get(n, 0))
		print("  %-10s entradas %4d · coronadas %4d · falladas %4d" % [n,
			int(entradas.get(n, 0)), int(salidas.get(n, 0)), int(falladas.get(n, 0))])
	print("  ", r["cuenta"])
	var tornos: Array = r["tornos"]
	for i in tornos.size():
		var t: Dictionary = tornos[i]
		var rumbo: Vector2 = (t["rumbo"] as Vector2) / float(maxi(int(t["subiendo"]), 1))
		print("  torno %d en %s: %d giros · boca de «%s»: %d entradas, %d de ellas por el torno" % [
			i, t["punto"], t["giros"], t["boca"], int(entradas.get(t["boca"], 0)), t["con_giro"]])
		print("          %d giros subiendo, con rumbo medio (%.2f, %.2f)" % [
			t["subiendo"], rumbo.x, rumbo.y])
	var bancos: Array = r["bancos"]
	for i in bancos.size():
		var b: Dictionary = bancos[i]
		print("  banco %d en %s (%d piezas): %d abatidas · %d veces completo" % [
			i, b["centro"], b["piezas"], b["abatidos"], b["completos"]])
	var platillos: Array = r["platillos"]
	for i in platillos.size():
		var pl: Dictionary = platillos[i]
		print("  platillo %d en %s: se traga %d bolas · %d se pierden antes de 3 s de escupirlas" % [
			i, pl["centro"], pl["tragadas"], pl["escupe_y_drena"]])

	var c: Dictionary = r["campana"]
	var unidades: Dictionary = r["unidades"]
	var suma := 0.0
	var texto := ""
	for n: String in r["nombres"]:
		suma += float(unidades.get(n, 0.0))
		texto += "%s %.2f  " % [n, float(unidades.get(n, 0.0)) / float(bolas)]
	print("LA CAMPANA · carga_entradas %s · descarga %.1f s · factor de salida %.2f" % [
		str(r["carga_entradas"]), float(r["descarga_tiempo"]), float(r["descarga_factor_salida"])])
	print("  entradas de rampa por bola %.2f · carga por bola %.2f entradas limpias" % [
		float(entradas_total) / float(bolas), suma / float(bolas)])
	print("  de dónde sale esa carga, por bola: ", texto)
	print("  carga_cambiada %d · armada %d · descarga_empezada %d · descarga_terminada %d" % [
		c["cambios"], c["armadas"], c["descargas"], c["terminadas"]])
	print("  toca una vez cada %s bolas · %.1f s sonando · se pierde armada al drenar %d · cortada al drenar %d" % [
		("%.2f" % (float(bolas) / float(c["descargas"]))) if int(c["descargas"]) > 0 else "—",
		float(c["segundos"]), c["perdidas_armada"], c["cortadas"]])
	print("  en qué recorrido toca: ", r["toca_en"])
	var toca_en: Dictionary = r["toca_en"]
	var tras_salida: Dictionary = r["tras_salida"]
	var tras_campana: Dictionary = r["tras_campana"]
	print("  drena antes de %.0f s de coronar…        sin campana          con la campana recién tocada" % float(r["descarga_tiempo"]))
	var suma_sin := [0, 0]
	var suma_con := [0, 0]
	for n: String in r["nombres"]:
		var n_con := int(toca_en.get(n, 0))
		var n_sin := int(salidas.get(n, 0)) - n_con
		var d_con := int(tras_campana.get(n, 0))
		var d_sin := int(tras_salida.get(n, 0)) - d_con
		suma_sin[0] += d_sin
		suma_sin[1] += n_sin
		suma_con[0] += d_con
		suma_con[1] += n_con
		print("    %-10s                         %4d de %4d (%3.0f %%)      %4d de %4d (%3.0f %%)" % [n,
			d_sin, n_sin, 100.0 * float(d_sin) / float(maxi(n_sin, 1)),
			d_con, n_con, 100.0 * float(d_con) / float(maxi(n_con, 1))])
	print("    %-10s                         %4d de %4d (%3.0f %%)      %4d de %4d (%3.0f %%)" % ["TOTAL",
		suma_sin[0], suma_sin[1], 100.0 * float(suma_sin[0]) / float(maxi(suma_sin[1], 1)),
		suma_con[0], suma_con[1], 100.0 * float(suma_con[0]) / float(maxi(suma_con[1], 1))])

	var paradas: Dictionary = r["paradas"]
	var paradas_xy: Dictionary = r["paradas_xy"]
	var claves := paradas.keys()
	claves.sort_custom(func(a: String, b: String) -> bool:
		return paradas[a] > paradas[b] if paradas[a] != paradas[b] else a < b)
	print("paradas (ball search): %d en total. Por celda de 10 px, con el píxel medio:" % _total(paradas))
	for clave: String in claves.slice(0, 16):
		var pt: Vector2 = (paradas_xy[clave] as Vector2) / float(paradas[clave])
		print("  %s × %d   (%.0f, %.0f)" % [clave, paradas[clave], pt.x, pt.y])

# ------------------------------------------------------------------ utilidades

func _media(lista: Array) -> float:
	var s := 0.0
	for x in lista:
		s += float(x)
	return s / float(maxi(lista.size(), 1))

func _mediana(lista: Array) -> float:
	var orden := lista.duplicate()
	orden.sort()
	return float(orden[orden.size() / 2]) if not orden.is_empty() else 0.0

func _total(d: Dictionary) -> int:
	var s := 0
	for clave in d:
		s += int(d[clave])
	return s

func _sumar_claves(a: Dictionary, b: Dictionary) -> void:
	for clave in b:
		var v: Variant = b[clave]
		if v is Vector2:
			a[clave] = (a.get(clave, Vector2.ZERO) as Vector2) + (v as Vector2)
		elif v is float:
			a[clave] = float(a.get(clave, 0.0)) + float(v)
		else:
			a[clave] = int(a.get(clave, 0)) + int(v)

## Varias series en una: se suman las cuentas y se juntan las duraciones.
func _juntar(series: Array) -> Dictionary:
	var primera: Dictionary = series[0]
	var t := primera.duplicate(true)
	for k in range(1, series.size()):
		var r: Dictionary = series[k]
		t["bolas"] = int(t["bolas"]) + int(r["bolas"])
		(t["duraciones"] as Array).append_array(r["duraciones"])
		t["cortadas"] = int(t["cortadas"]) + int(r["cortadas"])
		t["sin_lanzar"] = int(t["sin_lanzar"]) + int(r["sin_lanzar"])
		t["en_estacion"] = float(t["en_estacion"]) + float(r["en_estacion"])
		for clave: String in ["entradas", "salidas", "falladas", "cuenta", "paradas",
				"paradas_xy", "campana", "unidades", "toca_en", "drenajes",
				"tras_salida", "tras_campana"]:
			_sumar_claves(t[clave], r[clave])
		for clave: String in ["tornos", "bancos", "platillos"]:
			var mias: Array = t[clave]
			var suyas: Array = r[clave]
			for i in mias.size():
				for campo: String in ["giros", "con_giro", "subiendo", "abatidos", "completos",
						"tragadas", "escupe_y_drena"]:
					if (mias[i] as Dictionary).has(campo):
						mias[i][campo] = int(mias[i][campo]) + int(suyas[i][campo])
				if (mias[i] as Dictionary).has("rumbo"):
					mias[i]["rumbo"] = (mias[i]["rumbo"] as Vector2) + (suyas[i]["rumbo"] as Vector2)
	return t
