extends SceneTree

## PRUEBA 3D — sonda de la mesa «ÓRBITA». No es una prueba: no falla, imprime.
##
##     Godot --headless --path <repo> --script prueba3d/sonda_orbita.gd
##
## Suelta bolas con un jugador de mentira y apunta lo que pasa: cuántas veces se
## entra en cada recorrido, cuántas se corona, dónde se queda parada una bola
## (el ball search, con el píxel) y cuánto dura. Es la pregunta de `CLAUDE.md`
## para cualquier rincón nuevo: no si la bola cabe, sino si se queda.

const MesaOrbita := preload("res://prueba3d/mesa_orbita.gd")

func _init() -> void:
	var mesa: Mesa = MesaOrbita.new()
	mesa.rng.seed = 7
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var entradas := {}
	var salidas := {}
	var falladas := {}
	var paradas := {}
	var cuenta := {"bumper": 0, "sling": 0, "target": 0, "banco": 0,
		"girador": 0, "platillo": 0, "caida": 0}
	mesa.rampa_entrada.connect(func(_p: Vector2, i: int) -> void:
		var n: String = mesa.rampas[i].nombre
		entradas[n] = int(entradas.get(n, 0)) + 1)
	mesa.rampa_salida.connect(func(_p: Vector2, i: int) -> void:
		var n: String = mesa.rampas[i].nombre
		salidas[n] = int(salidas.get(n, 0)) + 1)
	mesa.rampa_fallada.connect(func(_p: Vector2, i: int, _r: float) -> void:
		var n: String = mesa.rampas[i].nombre
		falladas[n] = int(falladas.get(n, 0)) + 1)
	mesa.busqueda_bola.connect(func(pt: Vector2) -> void:
		var clave := "%d,%d" % [int(pt.x / 10.0) * 10, int(pt.y / 10.0) * 10]
		paradas[clave] = int(paradas.get(clave, 0)) + 1)
	mesa.bumper_golpeado.connect(func(_p: Vector2, _f: float) -> void: cuenta["bumper"] += 1)
	mesa.slingshot_golpeado.connect(func(_p: Vector2, _f: float) -> void: cuenta["sling"] += 1)
	mesa.target_abatido.connect(func(_p: Vector2, _b: int) -> void: cuenta["target"] += 1)
	mesa.banco_completado.connect(func(_p: Vector2, _b: int) -> void: cuenta["banco"] += 1)
	mesa.girador_girado.connect(func(_p: Vector2, _i: int, _f: float) -> void: cuenta["girador"] += 1)
	mesa.platillo_capturado.connect(func(_p: Vector2, _i: int) -> void: cuenta["platillo"] += 1)
	mesa.bola_cayo.connect(func(_p: Vector2, _d: int, _h: int) -> void: cuenta["caida"] += 1)

	var drenada := [false]
	mesa.bola_drenada.connect(func() -> void: drenada[0] = true)

	var bolas := 60
	var dt := 1.0 / 120.0
	var total := 0.0
	var sin_lanzar := 0
	var cortadas := 0
	var en_estacion := 0.0
	for _n in bolas:
		mesa.nueva_bola()
		mesa.reiniciar_targets()
		drenada[0] = false
		var t := 0.0
		var carga := 0.0
		var pulso_i := 0.0
		var pulso_d := 0.0
		var descanso_i := 0.0
		var descanso_d := 0.0
		while not drenada[0] and t < 90.0:
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
			# EL FIGURANTE TIENE QUE SOLTAR LA PALA. La primera versión volvía a
			# pulsar mientras la bola siguiera cerca, o sea que la dejaba acunada
			# para siempre: una bola de cuatro minutos y casi ningún golpe. Y con
			# la pala pulsada el ball search no salta, así que no avisaba nadie.
			# Ahora da un palazo y descansa, y solo cuando la bola ya ha rodado
			# un trecho por la pala: junto al eje no hay palanca.
			if b.libre() and b.vel.y > -20.0:
				for k in mesa.flippers.size():
					var f: Flipper = mesa.flippers[k]
					if not f.en_capa(b.capa):
						continue
					var d := b.pos - f.eje
					var lado: int = mesa.get("lado_pala")[k]
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
			for k in mesa.flippers.size():
				var lado: int = mesa.get("lado_pala")[k]
				mesa.flippers[k].pulsado = (pulso_i if lado < 0 else pulso_d) > 0.0
			mesa.avanzar(dt)
			if b.capa == Mesa.CAPA_ALTA:
				en_estacion += dt
			t += dt
		if t >= 90.0:
			cortadas += 1
		if t < 3.0:
			sin_lanzar += 1
		total += t

	print("== ÓRBITA · %d bolas · %.1f s de media ==" % [bolas, total / float(bolas)])
	print("cortadas a los 90 s: %d · drenadas antes de 3 s: %d" % [cortadas, sin_lanzar])
	print("tiempo en la estación: %.1f s" % en_estacion)
	for r in mesa.rampas:
		print("  %-10s entradas %4d · coronadas %4d · falladas %4d" % [r.nombre,
			int(entradas.get(r.nombre, 0)), int(salidas.get(r.nombre, 0)),
			int(falladas.get(r.nombre, 0))])
	print("  ", cuenta)
	var claves := paradas.keys()
	claves.sort_custom(func(a: String, b: String) -> bool: return paradas[a] > paradas[b])
	print("paradas (ball search), por celda de 10 px:")
	for c in claves.slice(0, 14):
		print("  ", c, " × ", paradas[c])
	quit()
