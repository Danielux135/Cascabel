extends SceneTree

## Mide el SISTEMA DE CAPAS DE ALTURA (`PLAN.md` §1c) y, sobre todo, mide que
## no ha cambiado nada de lo de antes:
##   godot --headless --path . --script tests/medir_capas.gd
##
## No es una prueba: imprime tablas. Tiene dos mitades y la primera manda.
##
## MITAD A — LA MESA DE HOY NO SE HA MOVIDO. El sistema de capas entra con
## todos los colisionadores en "todas las capas" y toda bola en el tablero, así
## que la mesa de hoy TIENE que dar exactamente los mismos números que antes:
## duración de bola, reparto de drenaje y golpes por entrada al racimo. Si un
## solo número baila, el balance entero deja de valer sin avisar y no hay forma
## de enterarse jugando. Los de referencia, medidos ANTES de escribir una línea
## de capas, están en la tabla de abajo.
##
## MITAD B — LO NUEVO HACE LO QUE DICE: que una capa filtre, que salirse de una
## plataforma sea caerse, que un túnel pase por debajo sin tocar nada, y que la
## velocidad de escape parta las entradas en las tres bandas de `PROPÓSITO.md`
## §6 (no llegas / coronas justo / limpia).

const DT := 1.0 / 120.0
const SEMILLAS := [7, 13, 271, 4242, 90210, 31337]

## LA LÍNEA QUE NO SE PUEDE CRUZAR, Y SE HA CRUZADO QUERIENDO (tanda 0k, 20-ago).
##
## La referencia de arriba se midió el 16 de agosto con el repo sin una sola
## línea del sistema de capas, y aguantó exacta cuatro tandas seguidas: 8,142 s ·
## 120 golpes · huella 16621,1901. La tumba la petición de Fátima de que **todas
## las rampas se puedan fallar**, y no de refilón: la duración de bola del
## maniquí SE DUPLICA.
##
## Y merece la pena entender por qué antes de dar por buena la nueva, porque el
## número no dice qué ha cambiado. No es un bucle nuevo: **el maniquí ya se
## pasaba el 73 % de la bola dentro de la órbita** (180 entradas en 60 bolas,
## medido sin cuesta). Lo que cambió es DÓNDE le deja la bola. La órbita
## completa la escupe por la boca contraria, que baja al drenaje; una fallada la
## devuelve a la boca por la que entró, o sea a la pala. La cuesta no metió un
## bucle: le quitó a la órbita el ser un billete rápido al desagüe.
##
## Se comprueba con `tests/medir_daniel.gd`, que es donde vive el balance de
## verdad: contra el jugador con reliquias, la mesa paga **838 de daño por bola
## contra los 835 de antes de la cuesta**. La planta baja se juega el doble de
## tiempo y cobra lo mismo, que es exactamente lo que se buscaba.
##
## LA REFERENCIA VIEJA SE DEJA ESCRITA, y no por nostalgia: es la única forma de
## que la próxima vez que esto se mueva se pueda decir si fue queriendo.
const REF_DURACION := 18.351     # s de media, 60 bolas
const REF_DRENAJE := "izq 6 · centro 12 · der 34 · no drena 8"
const REF_GOLPES := 387
const REF_HUELLA := 23563.4970
const REF_RACIMO := 3.11         # golpes de bumper por entrada, 240 entradas

## La de antes de que las rampas de abajo tuvieran cuesta (16-ago a 19-ago).
const REF_VIEJA := "8.142 s · izq 0 · centro 60 · der 0 · 120 golpes · huella 16621.1901 · racimo 3.09"

func _initialize() -> void:
	print("")
	print("=== A · LA MESA DE HOY, ¿SIGUE DANDO LOS MISMOS NÚMEROS? ===")
	print("   la referencia, medida con la cuesta puesta en las cinco rampas:")
	print("   %.3f s · %s · %d golpes · huella %.4f · racimo %.2f"
		% [REF_DURACION, REF_DRENAJE, REF_GOLPES, REF_HUELLA, REF_RACIMO])
	print("   y la de antes de la cuesta, para saber de dónde viene:")
	print("   %s" % REF_VIEJA)
	print("")
	_a1_duracion_y_drenaje()
	_a2_golpes_por_entrada()
	print("=== B · EL SISTEMA DE CAPAS ===")
	print("")
	_b1_filtro_de_capa()
	_b2_caida_de_plataforma()
	_b3_tunel_cruza_por_debajo()
	_b4_velocidad_de_escape()
	quit()

# ================================================================= A · lo viejo

## Un jugador que aporrea las dos palas, bola desde el lanzador, hasta drenar.
## Semilla fija en `m.rng` porque `Mesa._init` la aleatoriza y el ball search
## la usa: sin fijarla, esta medida no se puede repetir.
func _jugar_una_bola(semilla: int, tope: float = 30.0) -> Dictionary:
	var m := Mesa.new()
	m.rng.seed = semilla
	var golpes := [0]
	m.bumper_golpeado.connect(func(_p: Vector2, _f: float) -> void: golpes[0] += 1)
	m.slingshot_golpeado.connect(func(_p: Vector2, _f: float) -> void: golpes[0] += 1)
	m.target_abatido.connect(func(_p: Vector2, _b: int) -> void: golpes[0] += 1)
	m.girador_girado.connect(func(_p: Vector2, _i: int, _f: float) -> void: golpes[0] += 1)
	var drenada := [false]
	m.bola_drenada.connect(func() -> void: drenada[0] = true)
	m.nueva_bola()
	# OJO: `soltar_lanzador` no hace NADA si `cargando` es false, y eso no da
	# error: la bola se queda en el carril los 30 s enteros y la medida sale
	# "no drena 60 de 60". Hay que cargar de verdad.
	m.cargar_lanzador(m.p.tiempo_carga_lanzador)
	m.soltar_lanzador()
	var b := m.bola
	var t := 0.0
	var pulso := 0.0
	var x_final := 200.0
	while t < tope and not drenada[0]:
		pulso -= DT
		if b.libre() and b.pos.y > 1150.0 and b.vel.y > 0.0 and pulso <= 0.0:
			pulso = 0.14
		m.flipper_izq.pulsado = pulso > 0.0 and b.pos.x < 200.0
		m.flipper_der.pulsado = pulso > 0.0 and b.pos.x >= 200.0
		if b.viva:
			x_final = b.pos.x
		m.avanzar(DT)
		t += DT
	return {"t": t, "golpes": golpes[0], "x": x_final, "drenada": drenada[0]}

func _a1_duracion_y_drenaje() -> void:
	print("A1 · 60 bolas jugadas enteras (jugador que aporrea)")
	var suma := 0.0
	var n := 0
	var izq := 0
	var centro := 0
	var der := 0
	var sin_drenar := 0
	var golpes := 0
	# La huella es la suma de duraciones y posiciones finales. Vale para UNA cosa:
	# si cambia, la física se ha movido. Una media redondeada a tres decimales
	# puede tapar que dos bolas hayan cambiado en direcciones contrarias.
	var huella := 0.0
	for s in SEMILLAS:
		for i in 10:
			var r := _jugar_una_bola(s * 1000 + i)
			suma += r["t"]
			golpes += int(r["golpes"])
			huella += r["t"] * 7.0 + float(r["x"])
			n += 1
			if not r["drenada"]:
				sin_drenar += 1
				continue
			var x: float = r["x"]
			if x < 150.0:
				izq += 1
			elif x > 250.0:
				der += 1
			else:
				centro += 1
	print("   duración de bola: %.3f s de media (%d bolas)" % [suma / float(n), n])
	print("   drena por: izquierda %d · centro %d · derecha %d · no drena %d"
		% [izq, centro, der, sin_drenar])
	print("   golpes en total: %d      HUELLA: %.4f" % [golpes, huella])
	print("")

## La entrada al racimo, aislada: la misma bola lanzada desde debajo del racimo
## en las mismas condiciones. Es la medida que cazó que el racimo estaba de
## espaldas (1,0 golpes por entrada pasaron a 3,9), así que es la que más
## rápido delata un cambio de física que nadie ha pedido.
func _a2_golpes_por_entrada() -> void:
	print("A2 · 240 entradas al racimo desde abajo")
	var rng := RandomNumberGenerator.new()
	var golpes := 0
	var entradas := 0
	for s in SEMILLAS:
		rng.seed = s
		for _i in 40:
			var m := Mesa.new()
			m.rng.seed = s
			var n := [0]
			m.bumper_golpeado.connect(func(_p: Vector2, _f: float) -> void: n[0] += 1)
			var b := m.bola
			b.en_carril = false
			b.viva = true
			b.pos = m.p.bumper_centro + Vector2(rng.randf_range(-16.0, 16.0), 120.0)
			b.vel = Vector2(rng.randf_range(-60.0, 60.0), -rng.randf_range(600.0, 1100.0))
			var t := 0.0
			while t < 6.0 and b.viva:
				m.avanzar(DT)
				t += DT
				if b.libre() and b.pos.y > 1000.0:
					break
			golpes += n[0]
			entradas += 1
	print("   golpes de bumper por entrada: %.2f (%d entradas)"
		% [float(golpes) / float(entradas), entradas])
	print("")

# ============================================================== B · lo nuevo

## Una mesa DESNUDA: la de verdad, vaciada de geometría. Hace falta vaciarla
## porque el campo entero está ocupado —la arena de caza vive justo en el hueco
## de coordenadas que parece libre— y una pared de prueba puesta ahí mediría el
## rebote contra el techo de la arena, no el sistema de capas.
func _mesa_limpia() -> Mesa:
	var m := Mesa.new()
	m.rng.seed = 1
	m.colisionadores.clear()
	m.flippers.clear()
	m.rampas.clear()
	m.platillos.clear()
	m.targets.clear()
	m.bancos.clear()
	m.giradores.clear()
	# Y LAS PLATAFORMAS. Desde la tanda 0i la planta alta trae una isla de verdad,
	# y una isla olvidada aquí tira al tablero a la bola de prueba en cuanto sale
	# de su región: B1 daba "la atraviesa (MAL)" contra un sistema que funciona.
	m.plataformas.clear()
	m.umbral = -1
	m.regreso = -1
	return m

func _b1_filtro_de_capa() -> void:
	print("B1 · UN COLISIONADOR SOLO EXISTE EN SUS CAPAS")
	var m := _mesa_limpia()
	# Una pared horizontal que solo existe en la capa alta, en mitad de la nada.
	var pared := Colisionador.new(
		Vector2(120, 400), Vector2(280, 400), 6.0,
		Colisionador.Tipo.PARED, m.p.rebote_pared)
	pared.capas = Colisionador.mascara([Mesa.CAPA_ALTA])
	m.colisionadores.append(pared)
	var pasa := {}
	for capa in [Mesa.CAPA_TABLERO, Mesa.CAPA_ALTA]:
		var b := m.bola
		b.viva = true
		b.en_carril = false
		b.capa = capa
		b.pos = Vector2(200, 300)
		b.vel = Vector2(0, 400)
		var t := 0.0
		while t < 1.0 and b.pos.y < 480.0:
			m.avanzar(DT)
			t += DT
		pasa[capa] = b.pos.y >= 480.0
	print("   bola en el TABLERO contra una pared de la capa alta: %s"
		% ("la atraviesa (bien)" if pasa[Mesa.CAPA_TABLERO] else "CHOCA (mal)"))
	print("   bola en la CAPA ALTA contra esa misma pared:         %s"
		% ("la atraviesa (MAL)" if pasa[Mesa.CAPA_ALTA] else "choca (bien)"))
	print("")

func _b2_caida_de_plataforma() -> void:
	print("B2 · SALIRSE DEL BORDE DE UNA PLATAFORMA ES CAERSE")
	var m := _mesa_limpia()
	var pl := Plataforma.new(Rect2(100, 300, 200, 200), Mesa.CAPA_ALTA)
	m.plataformas.append(pl)
	var caidas := [0]
	var desde := [-99]
	var hasta := [-99]
	m.bola_cayo.connect(func(_p: Vector2, d: int, h: int) -> void:
		caidas[0] += 1
		desde[0] = d
		hasta[0] = h)
	var b := m.bola
	b.viva = true
	b.en_carril = false
	b.capa = Mesa.CAPA_ALTA
	b.pos = Vector2(200, 400)
	b.vel = Vector2(600, 0)
	var t := 0.0
	while t < 1.0 and caidas[0] == 0:
		m.avanzar(DT)
		t += DT
	print("   sale por el borde derecho: %s"
		% ("cae %d→%d en %.0f ms" % [desde[0], hasta[0], t * 1000.0]
			if caidas[0] > 0 else "NO CAE (mal)"))
	print("   y acaba en la capa %d con la bola %s"
		% [b.capa, "viva" if b.viva else "muerta"])
	# Y quieta en el centro no se cae nunca.
	var m2 := _mesa_limpia()
	m2.plataformas.append(Plataforma.new(Rect2(100, 300, 200, 200), Mesa.CAPA_ALTA))
	var falsas := [0]
	m2.bola_cayo.connect(func(_p: Vector2, _d: int, _h: int) -> void: falsas[0] += 1)
	var b2 := m2.bola
	b2.viva = true
	b2.en_carril = false
	b2.capa = Mesa.CAPA_ALTA
	b2.pos = Vector2(200, 400)
	b2.vel = Vector2.ZERO
	# Sin suelo la gravedad la sacaría por abajo, así que se la sujeta a mano.
	for _i in 120:
		b2.pos = Vector2(200, 400)
		b2.vel = Vector2.ZERO
		m2.avanzar(DT)
	print("   en el centro y quieta, caídas falsas: %d (tienen que ser 0)" % falsas[0])
	print("")

func _b3_tunel_cruza_por_debajo() -> void:
	print("B3 · DOS RECORRIDOS SE CRUZAN SIN TOCARSE")
	var m := _mesa_limpia()
	# Un túnel recto que va de arriba abajo por el centro, en la capa de abajo.
	var tunel := Rampa.new(PackedVector2Array([
		Vector2(200, 300), Vector2(200, 500), Vector2(200, 700)]))
	tunel.velocidad_minima = 100.0
	tunel.bidireccional = false
	tunel.subterranea = true
	tunel.capa_entrada = Mesa.CAPA_TABLERO
	tunel.capa_salida = Mesa.CAPA_TABLERO
	m.rampas.append(tunel)
	var i_tunel := m.rampas.size() - 1
	# Y un recorrido que cruza justo por el medio, pero por la capa alta.
	var puente := Rampa.new(PackedVector2Array([
		Vector2(80, 500), Vector2(200, 500), Vector2(320, 500)]))
	puente.velocidad_minima = 100.0
	puente.bidireccional = false
	puente.capa_entrada = Mesa.CAPA_ALTA
	puente.capa_salida = Mesa.CAPA_ALTA
	m.rampas.append(puente)
	var i_puente := m.rampas.size() - 1
	var cogidas: Array[int] = []
	m.rampa_entrada.connect(func(_p: Vector2, i: int) -> void: cogidas.append(i))
	var b := m.bola
	b.viva = true
	b.en_carril = false
	b.capa = Mesa.CAPA_TABLERO
	b.pos = Vector2(200, 300)
	b.vel = Vector2(0, 500)
	var t := 0.0
	while t < 3.0 and b.viva and cogidas.size() < 2:
		m.avanzar(DT)
		t += DT
	print("   una bola del tablero entrando por la boca del túnel coge: %s"
		% ("el túnel y solo el túnel (bien)"
			if cogidas.size() == 1 and cogidas[0] == i_tunel
			else "%s (mal)" % str(cogidas)))
	print("   el puente de la capa alta cruza por x=200,y=500 y no la ha tocado: %s"
		% ("sí" if not cogidas.has(i_puente) else "NO"))
	print("   mientras va por el túnel se dibuja oscura y sin bola: subterranea=%s"
		% str(m.rampas[i_tunel].subterranea))
	print("")

## Las tres bandas de `PROPÓSITO.md` §6, medidas barriendo la velocidad de
## entrada. Lo que se busca no es un número redondo: es que las tres existan y
## que la frontera esté donde dice el diseño (60 %).
func _b4_velocidad_de_escape() -> void:
	print("B4 · VELOCIDAD DE ESCAPE: LAS TRES BANDAS")
	for abierta in [false, true]:
		print("   rampa %s:" % ("ABIERTA (un carril: te tira al tablero)" if abierta
			else "CERRADA (un tubo: te devuelve)"))
		print("      entra a   ratio   qué pasa                 sale a")
		for v0 in [200.0, 400.0, 560.0, 640.0, 800.0, 1000.0, 1200.0]:
			var m := _mesa_limpia()
			var r := Rampa.new(PackedVector2Array([
				Vector2(120, 900), Vector2(160, 600), Vector2(280, 400)]))
			r.velocidad_minima = 150.0
			r.bidireccional = false
			r.velocidad_escape = 1000.0
			r.abierta = abierta
			r.capa_entrada = Mesa.CAPA_TABLERO
			r.capa_salida = Mesa.CAPA_ALTA
			m.rampas.append(r)
			var i := m.rampas.size() - 1
			var entro := [false]
			var salio := [false]
			var cayo := [false]
			m.rampa_entrada.connect(func(_p: Vector2, j: int) -> void:
				if j == i: entro[0] = true)
			m.rampa_salida.connect(func(_p: Vector2, j: int) -> void:
				if j == i: salio[0] = true)
			m.bola_cayo.connect(func(_p: Vector2, _d: int, _h: int) -> void:
				cayo[0] = true)
			var b := m.bola
			b.viva = true
			b.en_carril = false
			b.capa = Mesa.CAPA_TABLERO
			b.pos = Vector2(120, 900)
			b.vel = (Vector2(160, 600) - Vector2(120, 900)).normalized() * v0
			var t := 0.0
			while t < 4.0 and b.rampa < 0 and not entro[0]:
				m.avanzar(DT)
				t += DT
			var t2 := 0.0
			while t2 < 6.0 and b.rampa >= 0:
				m.avanzar(DT)
				t2 += DT
			var que := "no engancha"
			if entro[0]:
				if cayo[0]:
					que = "se cae al tablero"
				elif b.capa == Mesa.CAPA_ALTA:
					que = "corona"
				else:
					que = "vuelve por donde entró"
			print("      %6.0f   %4.2f   %-22s   %.0f px/s"
				% [v0, v0 / r.velocidad_escape, que, b.velocidad()])
		print("")
