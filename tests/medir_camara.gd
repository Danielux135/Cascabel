extends SceneTree

## Mide DÓNDE SE QUEDA la cámara, no dónde dice que quiere estar.
##
##     godot --headless --path . --script tests/medir_camara.gd
##
## Existe por un fallo concreto: la batería comprueba `objetivo()`, que es pura
## y dice la verdad, y NADIE comprobaba `y_actual`, que es lo que se ve. Las dos
## averías que reportó Fátima viven justo en ese hueco:
##
##   1. La cámara nunca llega abajo del todo. `avanzar` mueve hacia el BORDE de
##      la zona muerta, no hacia el objetivo, así que se queda parada a
##      `zona_muerta` px del ancla para siempre.
##   2. Con la bola rápida no se ve el flipper. La garantía dura solo promete
##      que la BOLA esté en pantalla; lo que hay debajo de ella —los flippers,
##      que es a donde va— se queda fuera.
##
## Esto no es una prueba: no falla, imprime números.

const DT := 1.0 / 120.0

func _initialize() -> void:
	var cp := ParametrosCamara.new()
	print("")
	print("=== MEDIDA DE CÁMARA ===")
	print("mesa %.0f de alto · ventana %.0f × %.0f · ancla abajo en y=%.0f"
		% [Mesa.ALTO, cp.ancho_visible, cp.alto_visible,
			Mesa.ALTO - cp.alto_visible * 0.5])
	print("ejes de flipper en y=%.0f · punta más baja ~y=%.0f"
		% [1200.0, 1240.0])
	_reposo(cp)
	_caida_recta(cp, 400.0)
	_caida_recta(cp, 900.0)
	_caida_recta(cp, 1400.0)
	_caida_recta(cp, 1900.0)
	_partida_de_verdad(cp)
	_tirones(cp)
	quit()

## ¿Llega la cámara al ancla inferior cuando no hay nada que seguir?
func _reposo(cp: ParametrosCamara) -> void:
	var cam := CamaraMesa.new(cp, Mesa.ALTO, Mesa.ANCHO * 0.5)
	cam.y_actual = 400.0
	for _i in int(20.0 / DT):
		cam.avanzar(DT, 0.0, 0.0, false)
	var borde := cam.y_actual + cp.alto_visible * 0.5
	print("")
	print("[1] SIN BOLA, 20 s para asentarse")
	print("    la cámara se queda en y=%.1f, el ancla está en y=%.1f  →  %s"
		% [cam.y_actual, cam.limite_abajo(),
			"BIEN" if absf(cam.y_actual - cam.limite_abajo()) < 1.0
			else "SE QUEDA %.0f px CORTA" % (cam.limite_abajo() - cam.y_actual)])
	print("    borde inferior de pantalla en y=%.0f; el fondo de la mesa es %.0f"
		% [borde, Mesa.ALTO])
	print("    o sea que los últimos %.0f px de mesa NO SE VEN NUNCA"
		% maxf(Mesa.ALTO - borde, 0.0))
	cam.free()

## Bola cayendo en línea recta a velocidad fija. Es el caso que denuncia Fátima:
## "pelotas de mucha velocidad no llegas a ver el flipper".
func _caida_recta(cp: ParametrosCamara, velocidad: float) -> void:
	var cam := CamaraMesa.new(cp, Mesa.ALTO, Mesa.ANCHO * 0.5)
	cam.y_actual = cam.limite_abajo()
	# Se arranca con la cámara ya arriba, como cuando la bola venía de la órbita.
	var y := 200.0
	for _i in int(1.0 / DT):
		cam.avanzar(DT, y, 0.0, true)
	var sin_flipper := 0
	var total := 0
	var peor := 0.0
	var y_al_perderlos := -1.0
	var bola_mas_alta := INF
	while y < Mesa.ALTO:
		y += velocidad * DT
		cam.avanzar(DT, y, velocidad, true)
		# Dónde cae la bola dentro de la pantalla. Por debajo de
		# `alto_franja_hud` está detrás de la barra de título.
		bola_mas_alta = minf(bola_mas_alta,
			y - cam.y_actual + cp.alto_visible * 0.5)
		# El contrato: por debajo de la línea de seguridad (REGLA 2) la punta
		# del flipper tiene que estar en pantalla, corra la bola lo que corra.
		if y > Mesa.ALTO - cp.margen_ancla:
			total += 1
			var borde := cam.y_actual + cp.alto_visible * 0.5
			if borde < 1240.0:
				sin_flipper += 1
				if y_al_perderlos < 0.0:
					y_al_perderlos = y
				peor = maxf(peor, 1240.0 - borde)
	print("")
	print("[2] BOLA CAYENDO RECTA A %.0f px/s" % velocidad)
	print("    fotogramas bajo la línea de seguridad (y>%.0f): %d"
		% [Mesa.ALTO - cp.margen_ancla, total])
	print("    de esos, SIN LA PUNTA DEL FLIPPER EN PANTALLA: %d" % sin_flipper)
	if sin_flipper > 0:
		print("    empieza a perderlos con la bola en y=%.0f" % y_al_perderlos)
		print("    en el peor fotograma faltaban %.0f px por debajo del borde"
			% peor)
	print("    lo más arriba que sale la bola en pantalla: y=%.0f (el marco tapa %.0f)"
		% [bola_mas_alta, cp.alto_franja_hud])
	cam.free()

## LOS TIRONES: cuánto se mueve la cámara DE UN FOTOGRAMA AL SIGUIENTE.
##
## Existe por lo que dijo Daniel jugando: *"la cámara se siente super mal a la
## hora de ponerse abajo, se teletransporta"*. Y lo dijo con una bola y con
## muchas, o sea que no es de la multibola.
##
## Lo que se sospecha, y esto lo confirma o lo tira: la garantía dura de
## `avanzar` NO pasa por el suavizado, es un `maxf` que se aplica entero en un
## fotograma. Y depende de `vy`, que cambia de golpe cada vez que la bola sale de
## una rampa, pega en un bumper o toca una pala. Cada uno de esos cambios mueve
## el suelo garantizado `vy × 0,18 + 150` px de una vez.
##
## A 120 Hz, 8 px en un fotograma ya son 960 px/s de paneo. Lo que se mira es
## cuántos fotogramas pasan de ahí y cuál es el peor.
func _tirones(cp: ParametrosCamara) -> void:
	print("")
	print("[4] BRUSQUEDAD DE LA CÁMARA, 6 bolas de verdad por fila")
	print("    LA CAUSA no es el suavizado, es que el OBJETIVO da saltos: el")
	print("    suelo garantizado vale bola_y + vy*t_ant + margen, y `vy` cambia")
	print("    de golpe en cada salida de rampa. Con t_ant=0 el objetivo solo")
	print("    depende de la POSICIÓN, que es continua, y entonces el muelle no")
	print("    recibe ningún golpe. El precio es margen: hay que mirar más abajo.")
	print("")
	print("    t_ant  margen  suav   peor salto      aceleración   sin flipper  red")
	for t_ant in [0.18, 0.09, 0.0]:
		for margen in [150.0, 250.0, 350.0]:
			_una_fila(cp, t_ant, margen, 0.16)
	print("")
	print("    y con el mejor de los de arriba, barriendo el suavizado:")
	for suav in [0.10, 0.16, 0.24, 0.32]:
		_una_fila(cp, 0.0, 350.0, suav)

func _una_fila(cp: ParametrosCamara, t_ant: float, margen: float,
		suav: float) -> void:
	var a := cp.tiempo_anticipacion
	var b := cp.margen_debajo_bola
	var c := cp.tiempo_suavizado
	cp.tiempo_anticipacion = t_ant
	cp.margen_debajo_bola = margen
	cp.tiempo_suavizado = suav
	_medir_tirones(cp, t_ant, margen, suav)
	cp.tiempo_anticipacion = a
	cp.margen_debajo_bola = b
	cp.tiempo_suavizado = c

func _medir_tirones(cp: ParametrosCamara, t_ant: float, margen: float,
		suav: float) -> void:
	var cam := CamaraMesa.new(cp, Mesa.ALTO, Mesa.ANCHO * 0.5)
	var m := Mesa.new(ParametrosMesa.new())
	m.rng.seed = 20260815
	cam.y_actual = cam.limite_abajo()
	var peor := 0.0
	var peor_acel := 0.0
	var v_antes := 0.0
	var total := 0
	var bolas := 0
	var sin_flipper := 0
	var bajo_ancla := 0
	var mordidas := 0
	while bolas < 6:
		if not m.bola.viva:
			m.nueva_bola()
			m.cargar_lanzador(1.0)
			m.soltar_lanzador()
			bolas += 1
		for _i in int(30.0 / DT):
			if not m.bola.viva:
				break
			m.avanzar(DT)
			var antes := cam.y_actual
			var suelo_antes := cam.suelo_visible(m.bola.pos.y, m.bola.vel.y) \
				- cp.alto_visible * 0.5
			cam.avanzar(DT, m.bola.pos.y, m.bola.vel.y, m.bola.viva)
			if cam.y_actual <= suelo_antes + 0.6 and suelo_antes > antes:
				mordidas += 1
			var salto := absf(cam.y_actual - antes)
			var v := (cam.y_actual - antes) / DT
			total += 1
			peor = maxf(peor, salto)
			# Cuántas veces la garantía dura tiene que corregir al muelle. Es la
			# medida de cuánto de lo que se ve es suavizado y cuánto es tirón.
			var libre := cam.objetivo_completo(m.bola.pos.y, m.bola.vel.y, true)
			if absf(cam.y_actual - libre) < 0.5 and salto > 2.0:
				mordidas += 0
			peor_acel = maxf(peor_acel, absf(v - v_antes) / DT)
			v_antes = v
			if m.bola.pos.y > Mesa.ALTO - cp.margen_ancla:
				bajo_ancla += 1
				if cam.y_actual + cp.alto_visible * 0.5 < 1240.0:
					sin_flipper += 1
	print("    %4.2f   %5.0f   %4.2f   %6.1f px   %11.0f px/s²   %4.0f %% de %-4d %.1f %%"
		% [t_ant, margen, suav, peor, peor_acel,
			100.0 * float(sin_flipper) / maxf(float(bajo_ancla), 1.0),
			bajo_ancla,
			100.0 * float(mordidas) / maxf(float(total), 1.0)])
	cam.free()

## Una bola de verdad, con la mesa entera, desde el lanzamiento hasta que drena.
func _partida_de_verdad(cp: ParametrosCamara) -> void:
	var cam := CamaraMesa.new(cp, Mesa.ALTO, Mesa.ANCHO * 0.5)
	var m := Mesa.new(ParametrosMesa.new())
	m.nueva_bola()
	m.cargar_lanzador(1.0)
	m.soltar_lanzador()
	cam.y_actual = cam.limite_abajo()
	var sin_flipper := 0
	var bajo_ancla := 0
	var total := 0
	var vel_max := 0.0
	for _i in int(40.0 / DT):
		if not m.bola.viva:
			break
		m.avanzar(DT)
		cam.avanzar(DT, m.bola.pos.y, m.bola.vel.y, m.bola.viva)
		vel_max = maxf(vel_max, m.bola.vel.y)
		if m.bola.pos.y > Mesa.ALTO - cp.margen_ancla:
			total += 1
			bajo_ancla += 1
			if cam.y_actual + cp.alto_visible * 0.5 < 1240.0:
				sin_flipper += 1
	print("")
	print("[3] UNA BOLA DE VERDAD, mesa entera, hasta drenar")
	print("    velocidad de caída máxima alcanzada: %.0f px/s" % vel_max)
	print("    fotogramas bajo la línea de seguridad: %d" % total)
	print("    de esos, sin la punta del flipper en pantalla: %d (%.0f %%)"
		% [sin_flipper, 100.0 * float(sin_flipper) / maxf(float(total), 1.0)])
	print("    la cámara acabó en y=%.1f, ancla en y=%.1f"
		% [cam.y_actual, cam.limite_abajo()])
	print("")
	cam.free()
