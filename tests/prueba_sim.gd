extends SceneTree

## Pruebas de la simulación sin abrir ventana:
##   godot --headless --path . --script tests/prueba_sim.gd
##
## Comprueban justamente las tres cosas del arreglo del atasco: que la bola no
## se escapa por las juntas, que no se acuña en la zona del bug, y que el ball
## search la rescata si se para.

const DT := 1.0 / 120.0
const SEMILLA := 20260809

var _fallos: int = 0
var _pruebas: int = 0

func _initialize() -> void:
	_prueba_ajustes()
	_prueba_geometria_sellada()
	_prueba_barrido_del_flipper()
	_prueba_no_se_escapa()
	_prueba_sin_atasco_en_el_inlane()
	_prueba_flipper_empuja()
	_prueba_ball_search()
	_prueba_lanzador()
	_prueba_apertura()
	_prueba_targets()
	_prueba_combate()
	_prueba_escena_principal()
	_prueba_adornos()
	_prueba_giradores()
	_prueba_animacion()
	_prueba_camara()
	_prueba_rampas()
	_prueba_sonido()
	_prueba_impactos()
	_prueba_racimo()
	_prueba_sin_rebote_encerrado()
	_prueba_slingshot_tiene_espalda()
	_prueba_outlanes()
	_prueba_agarre()
	_prueba_identidad_recorridos()
	_prueba_mapa()
	_prueba_run()
	_prueba_reliquias()
	_prueba_misiones()
	_prueba_criticos()
	_prueba_fuente()
	_prueba_cascara()
	_prueba_paleta()

	print("")
	if _fallos == 0:
		print("OK  %d/%d pruebas" % [_pruebas, _pruebas])
	else:
		print("FALLO  %d de %d pruebas" % [_fallos, _pruebas])
	quit(1 if _fallos > 0 else 0)

# ------------------------------------------------------------------ utilidades

func _comprobar(nombre: String, condicion: bool, detalle: String = "") -> void:
	_pruebas += 1
	if condicion:
		print("  ok    ", nombre)
	else:
		_fallos += 1
		print("  FALLO ", nombre, "  ", detalle)

func _nueva_mesa() -> Mesa:
	var m := Mesa.new()
	m.rng.seed = SEMILLA
	return m

## Simula hasta que la bola drene o se agote el tiempo. Devuelve un diccionario
## con lo que ha pasado por el camino.
func _simular(m: Mesa, segundos: float) -> Dictionary:
	var pasos := int(segundos / DT)
	var escapes := 0
	var quieta_max := 0.0
	var quieta := 0.0
	# Las lambdas de GDScript capturan las locales por valor: hace falta un
	# contenedor por referencia para contar desde dentro de la señal.
	var busquedas := [0]
	m.busqueda_bola.connect(func(_pt: Vector2) -> void: busquedas[0] += 1)
	for _i in pasos:
		if not m.bola.viva:
			break
		m.avanzar(DT)
		if not m.bola.viva:
			break
		var pos := m.bola.pos
		if not m.bola.libre():
			continue
		if pos.x < 20.0 or pos.x > 380.0 or pos.y < 655.0 or pos.y > 1301.0:
			escapes += 1
		if m.bola.velocidad() < 12.0:
			quieta += DT
			quieta_max = maxf(quieta_max, quieta)
		else:
			quieta = 0.0
	return {
		"drenada": not m.bola.viva,
		"escapes": escapes,
		"quieta_max": quieta_max,
		"busquedas": busquedas[0],
		"pos": m.bola.pos,
	}

# -------------------------------------------------------------------- pruebas

func _prueba_ajustes() -> void:
	_comprobar("physics_ticks_per_second = 120",
		ProjectSettings.get_setting("physics/common/physics_ticks_per_second") == 120)
	_comprobar("default_texture_filter = 0 (Nearest)",
		ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter") == 0)
	_comprobar("stretch/scale_mode = integer",
		ProjectSettings.get_setting("display/window/stretch/scale_mode") == "integer")
	# 960x540 con escalado entero: x2 = 1080p, x4 = 4K. La mesa sigue midiendo
	# 400 de ancho y los 560 que sobran son el escritorio de la fase 5.
	_comprobar("viewport 960x540",
		ProjectSettings.get_setting("display/window/size/viewport_width") == 960
		and ProjectSettings.get_setting("display/window/size/viewport_height") == 540)
	# Con escalado entero la ventana tiene que caber en un múltiplo exacto: a
	# 1908x960 caía a x1 y el juego se veía a tamaño de sello.
	_comprobar("arranca en pantalla completa",
		ProjectSettings.get_setting("display/window/size/mode") == 3)
	_comprobar("ventana de prueba 1920x1080 (x2 exacto)",
		ProjectSettings.get_setting("display/window/size/window_width_override") == 1920
		and ProjectSettings.get_setting("display/window/size/window_height_override") == 1080)

## El arreglo 1 depende de que no quede ningún hueco por el que quepa la bola
## entre el final del carril de retorno, el poste y el eje del flipper.
func _prueba_geometria_sellada() -> void:
	var m := _nueva_mesa()
	var d := m.p.radio_bola * 2.0
	for lado in [
			{"poste": Vector2(102, 1196), "fin_rampa": Vector2(99, 1184), "eje": m.p.flipper_eje_izq},
			{"poste": Vector2(298, 1196), "fin_rampa": Vector2(301, 1184), "eje": m.p.flipper_eje_der}]:
		var hueco_rampa: float = (lado["poste"] as Vector2).distance_to(lado["fin_rampa"]) - m.p.poste_radio
		var hueco_eje: float = (lado["poste"] as Vector2).distance_to(lado["eje"]) \
			- m.p.poste_radio - m.p.flipper_radio
		_comprobar("hueco poste<->fin de rampa < diametro de bola",
			hueco_rampa < d, "hueco %.2f px, bola %.1f px" % [hueco_rampa, d])
		_comprobar("hueco poste<->eje del flipper < diametro de bola",
			hueco_eje < d, "hueco %.2f px, bola %.1f px" % [hueco_eje, d])

	# Y el desagüe central sí tiene que dejar pasar la bola.
	var punta_izq := m.flipper_izq.punta()
	var punta_der := m.flipper_der.punta()
	var hueco_central := punta_izq.distance_to(punta_der) - m.p.flipper_radio * 2.0
	_comprobar("el desague central deja pasar la bola",
		hueco_central > d, "hueco %.2f px, bola %.1f px" % [hueco_central, d])

## Nada puede meterse dentro del arco que barre la pala. Si un colisionador cae
## ahí, la bola apoyada en la pala levantada lo toca y sale disparada, y
## entonces no se puede ni atrapar ni apuntar: el juego se queda en tiros de
## rebote. Se comprueba paseando una bola de mentira por encima de la pala en
## todas sus posiciones y mirando que no toque nada.
func _prueba_barrido_del_flipper() -> void:
	var m := _nueva_mesa()
	# La bola apoyada tiene el centro a esta distancia del eje de la cápsula.
	var separacion: float = m.p.flipper_radio + m.p.radio_bola
	# Se empieza a 15 px del eje: más adentro está el poste de goma, que SOLAPA
	# con el eje a propósito para sellar el hueco del inlane (ver
	# `_prueba_geometria_sellada`). Ahí no cabe la bola de todas formas.
	var desde := 15.0
	var pasos := 24
	for lado in [{"n": "izquierdo", "f": m.flipper_izq}, {"n": "derecho", "f": m.flipper_der}]:
		var f: Flipper = lado["f"]
		var peor := INF
		var culpable := ""
		var donde := Vector2.ZERO
		for i in pasos + 1:
			var ang: float = lerpf(f.angulo_reposo, f.angulo_activo, float(i) / float(pasos))
			var dir := Vector2(cos(ang), sin(ang))
			# La perpendicular por la que se apoya la bola es la de arriba.
			var arriba := Vector2(dir.y, -dir.x)
			if arriba.y > 0.0:
				arriba = -arriba
			var d := desde
			while d <= f.longitud:
				var centro: Vector2 = f.eje + dir * d + arriba * separacion
				for c in m.colisionadores:
					var hueco: float = c.punto_mas_cercano(centro).distance_to(centro) \
						- c.radio - m.p.radio_bola
					if hueco < peor:
						peor = hueco
						culpable = Colisionador.Tipo.keys()[c.tipo]
						donde = centro
				d += 2.0
		_comprobar("nada se mete en el barrido del flipper %s" % lado["n"],
			peor > 0.0, "%s a %.2f px, con la bola en %s" % [culpable, peor, str(donde.round())])

## Nada de tunelar por las juntas del arco teselado ni por las esquinas.
func _prueba_no_se_escapa() -> void:
	var escapes := 0
	var sin_drenar := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA
	for i in 120:
		var m := _nueva_mesa()
		m.nueva_bola()
		m.bola.en_carril = false
		m.bola.pos = Vector2(rng.randf_range(40, 340), rng.randf_range(760, 1050))
		var ang := rng.randf_range(0.0, TAU)
		m.bola.vel = Vector2(cos(ang), sin(ang)) * rng.randf_range(200.0, 1500.0)
		var r := _simular(m, 60.0)
		escapes += r["escapes"]
		if not r["drenada"]:
			sin_drenar += 1
	_comprobar("120 lanzamientos aleatorios sin salirse de la mesa",
		escapes == 0, "%d fotogramas fuera" % escapes)
	_comprobar("120 lanzamientos aleatorios drenan en menos de 60 s",
		sin_drenar == 0, "%d bolas sin drenar" % sin_drenar)

## La prueba del bug original: soltar la bola en el carril de retorno y en el
## punto exacto donde se acuñaba. Tiene que salir al flipper y acabar drenando.
func _prueba_sin_atasco_en_el_inlane() -> void:
	var puntos := [
		Vector2(55, 1120), Vector2(80, 1155), Vector2(95, 1175),   # inlane izquierdo
		Vector2(111, 1194), Vector2(105, 1192),                   # el punto del bug
		Vector2(330, 1095), Vector2(310, 1145), Vector2(290, 1175),# inlane derecho
		Vector2(289, 1194),
	]
	var atascadas := 0
	var sin_drenar := 0
	for punto in puntos:
		var m := _nueva_mesa()
		m.nueva_bola()
		m.bola.en_carril = false
		m.bola.pos = punto
		m.bola.vel = Vector2(0, 120)
		var r := _simular(m, 20.0)
		if not r["drenada"]:
			sin_drenar += 1
		if r["quieta_max"] > 3.0:
			atascadas += 1
	_comprobar("la bola no se queda quieta en la zona del atasco",
		atascadas == 0, "%d de %d se pararon mas de 3 s" % [atascadas, puntos.size()])
	_comprobar("la bola sale del inlane y drena",
		sin_drenar == 0, "%d de %d no drenaron" % [sin_drenar, puntos.size()])

## Un flipper quieto rebota; uno en movimiento lanza. Si esto se rompe, el
## juego se siente muerto.
func _prueba_flipper_empuja() -> void:
	var salidas := []
	for pulsado in [false, true]:
		var m := _nueva_mesa()
		m.nueva_bola()
		m.bola.en_carril = false
		# Apoyada sobre la pala izquierda, a media longitud del eje.
		var dir := Vector2(cos(m.flipper_izq.angulo), sin(m.flipper_izq.angulo))
		m.bola.pos = m.p.flipper_eje_izq + dir * 40.0 \
			+ Vector2(-dir.y, dir.x) * -(m.p.flipper_radio + m.p.radio_bola + 0.5)
		m.bola.vel = Vector2(0, 60)
		m.flipper_izq.pulsado = pulsado
		var maxima := 0.0
		for _i in int(0.35 / DT):
			m.avanzar(DT)
			maxima = maxf(maxima, m.bola.velocidad())
		salidas.append(maxima)
	_comprobar("el flipper en movimiento lanza mas fuerte que uno quieto",
		salidas[1] > salidas[0] * 2.0,
		"quieto %.0f px/s, en movimiento %.0f px/s" % [salidas[0], salidas[1]])
	_comprobar("el flipper quieto no lanza",
		salidas[0] < 400.0, "quieto %.0f px/s" % salidas[0])

func _prueba_ball_search() -> void:
	var m := _nueva_mesa()
	m.nueva_bola()
	m.bola.en_carril = false
	m.bola.pos = Vector2(200, 1000)
	m.bola.vel = Vector2.ZERO
	# Suelo falso justo debajo para que se quede parada de verdad.
	m.colisionadores.append(Colisionador.new(
		Vector2(120, 1020), Vector2(280, 1020), 0.0, Colisionador.Tipo.PARED, 0.0))
	var disparos := [0]
	m.busqueda_bola.connect(func(_pt: Vector2) -> void: disparos[0] += 1)
	for _i in int(3.0 / DT):
		m.avanzar(DT)
	_comprobar("el ball search dispara tras %.0f s parada" % m.p.busqueda_tiempo,
		disparos[0] >= 1, "%d disparos en 3 s" % disparos[0])

	# Cazar la bola con el flipper no debe contar como atasco.
	var m2 := _nueva_mesa()
	m2.nueva_bola()
	m2.bola.en_carril = false
	var dir := Vector2(cos(m2.flipper_izq.angulo_activo), sin(m2.flipper_izq.angulo_activo))
	m2.flipper_izq.pulsado = true
	m2.bola.pos = m2.p.flipper_eje_izq + dir * 45.0 \
		+ Vector2(-dir.y, dir.x) * -(m2.p.flipper_radio + m2.p.radio_bola - 0.2)
	m2.bola.vel = Vector2.ZERO
	var disparos2 := [0]
	m2.busqueda_bola.connect(func(_pt: Vector2) -> void: disparos2[0] += 1)
	for _i in int(4.0 / DT):
		m2.avanzar(DT)
	_comprobar("cazar la bola con el flipper no dispara el ball search",
		disparos2[0] == 0, "%d disparos en 4 s" % disparos2[0])

func _prueba_targets() -> void:
	var m := _nueva_mesa()
	_comprobar("hay dos bancos de tres targets",
		m.bancos.size() == 2 and m.targets.size() == 6,
		"%d bancos, %d targets" % [m.bancos.size(), m.targets.size()])

	# El target es una PLANCHA, no un bolo: la cápsula mide `target_ancho` de
	# punta a punta y solo `target_canto` de fondo. Con el círculo de radio 13 de
	# antes metía 26 px de cuerpo redondo en el campo y rebotaba de refilón.
	for c in m.targets:
		var largo: float = c.a.distance_to(c.b) + c.radio * 2.0
		_comprobar("el target mide la cara que dice el parametro",
			is_equal_approx(largo, m.p.target_ancho),
			"cara de %.1f px, parametro %.1f" % [largo, m.p.target_ancho])
		_comprobar("y sobresale menos que el radio de la bola",
			c.radio * 2.0 < m.p.radio_bola, "canto de %.1f px" % (c.radio * 2.0))

	# Los targets no pueden sellar el carril lateral: con el banco en pie se
	# tiene que poder seguir bajando al inlane. Ese carril va por FUERA y no
	# depende del canto: al adelgazar la plancha se abre campo por delante del
	# banco, no por detrás.
	for datos in [{"banco": 0, "pared_x": 20.0}, {"banco": 1, "pared_x": 350.0}]:
		var c: Colisionador = m.bancos[datos["banco"]][0]
		var carril: float = absf(c.centro().x - (datos["pared_x"] as float)) \
			- m.p.target_canto * 0.5
		_comprobar("el carril del banco %d sigue midiendo 23 px" % datos["banco"],
			is_equal_approx(carril, 23.0), "mide %.1f px" % carril)
		_comprobar("y por el carril del banco %d pasa la bola" % datos["banco"],
			carril - m.p.radio_bola * 2.0 > 2.0,
			"solo %.1f px libres" % (carril - m.p.radio_bola * 2.0))

	# Y entre target y target NO tiene que caber, o se acuñaría.
	var banco: Array = m.bancos[0]
	var hueco: float = (banco[0] as Colisionador).centro().distance_to(
		(banco[1] as Colisionador).centro()) - m.p.target_ancho
	_comprobar("entre dos targets no cabe la bola",
		hueco < m.p.radio_bola * 2.0, "hueco %.1f px" % hueco)

	# Abatir el banco entero lo vuelve a levantar tras el retardo.
	var completados := [0]
	m.banco_completado.connect(func(_pt: Vector2, _b: int) -> void: completados[0] += 1)
	for c in m.bancos[0]:
		m._abatir(c)
	_comprobar("abatir los tres avisa de banco completado", completados[0] == 1,
		"%d avisos" % completados[0])
	_comprobar("los targets abatidos dejan de colisionar",
		not (m.bancos[0][0] as Colisionador).activo)
	for _i in int(m.p.target_tiempo_reset / DT) + 4:
		m.avanzar(DT)
	_comprobar("el banco se vuelve a levantar solo",
		(m.bancos[0][0] as Colisionador).activo)

## Un bumper solo puede dar un aviso por golpe. Sin el filtro de `empuje`, una
## bola apoyada emitía uno por subpaso: 480 golpes por segundo de daño gratis.
func _prueba_bumper_no_repite() -> void:
	# El bumper de más a la izquierda del racimo, sacado de la mesa y no escrito
	# a mano: el racimo se recoloca solo desde `bumper_hueco` y una coordenada
	# fija aquí se quedaría vieja al primer ajuste.
	var m := _nueva_mesa()
	var arriba: Vector2 = m.bumpers[0]
	for b in m.bumpers:
		if (b as Vector2).x < arriba.x:
			arriba = b
	m.nueva_bola()
	m.bola.en_carril = false
	m.bola.pos = arriba - Vector2(0, m.p.bumper_radio + m.p.radio_bola + 40.0)
	m.bola.vel = Vector2(0, 200)
	var avisos := [0]
	m.bumper_golpeado.connect(func(_pt: Vector2, _f: float) -> void: avisos[0] += 1)
	# No vale medir por ventana de tiempo: con restitución 1,8 la bola sale al
	# tope de 1500 px/s, rebota en el arco y vuelve a caer en 0,26 s, y ese
	# segundo aviso es legítimo. Se mide el contacto: en cuanto sale despedida
	# se dejan correr unos ticks más y no puede haber aparecido otro aviso.
	var golpeada := false
	var extra := 0
	for _i in int(1.0 / DT):
		m.avanzar(DT)
		if golpeada:
			extra += 1
			if extra >= 6:
				break
		elif m.bola.vel.y < -100.0:
			golpeada = true
	_comprobar("un golpe de bumper da exactamente un aviso",
		golpeada and avisos[0] == 1, "%d avisos" % avisos[0])

	# Y una bola apoyada encima, sin fuerza para disparar el interruptor, no
	# tiene que dar ninguno.
	var m2 := _nueva_mesa()
	m2.nueva_bola()
	m2.bola.en_carril = false
	m2.bola.pos = arriba - Vector2(0, m2.p.bumper_radio + m2.p.radio_bola - 0.2)
	m2.bola.vel = Vector2.ZERO
	var avisos2 := [0]
	m2.bumper_golpeado.connect(func(_pt: Vector2, _f: float) -> void: avisos2[0] += 1)
	for _i in int(0.5 / DT):
		m2.avanzar(DT)
	_comprobar("una bola apoyada en un bumper no da avisos",
		avisos2[0] == 0, "%d avisos en 0,5 s" % avisos2[0])

func _avanzar_combate(c: Combate, segundos: float) -> void:
	for _i in int(segundos / DT):
		c.avanzar(DT)

## Drena como lo haría la mesa de verdad: mata la bola y luego avisa.
func _drenar(c: Combate) -> void:
	c.mesa.bola.viva = false
	c.mesa.bola.vel = Vector2.ZERO
	c.mesa.bola_drenada.emit()

## Golpea un bumper `veces` veces, como si la bola fuera dando tumbos.
func _golpear(c: Combate, veces: int) -> void:
	for _i in veces:
		c.mesa.bumper_golpeado.emit(Vector2(200, 800), 500.0)

## Pone el combate en juego con la bola fuera del carril.
func _en_juego(c: Combate) -> void:
	c.mesa.bola.en_carril = false
	c.avanzar(DT)

func _prueba_combate() -> void:
	_prueba_bumper_no_repite()

	var c := Combate.new()
	c.iniciar(Enemigo.new({"nombre": "Prueba", "vida": 500, "ataque": 10}))
	_comprobar("el combate arranca con la vida del jugador a tope",
		c.vida_jugador == c.p.vida_jugador)
	_comprobar("y con la bola en el carril", c.mesa.bola.en_carril)
	_en_juego(c)

	# El daño se aplica EN VIVO, no al drenar.
	_golpear(c, 1)
	_comprobar("golpear un bumper le quita vida al enemigo en el acto",
		c.enemigo.vida == 500 - c.p.dano_bumper, "vida %d" % c.enemigo.vida)
	_comprobar("y cuenta como un golpe del combo", c.golpes == 1)

	# Drenar no pega: solo tira el combo y trae el contraataque.
	_golpear(c, 6)
	var vida_enemigo := c.enemigo.vida
	_drenar(c)
	_comprobar("drenar no le hace dano al enemigo",
		c.enemigo.vida == vida_enemigo, "vida %d" % c.enemigo.vida)
	_comprobar("drenar resetea el combo a x1",
		c.golpes == 0 and c.multiplicador() == 1,
		"%d golpes, x%d" % [c.golpes, c.multiplicador()])
	_comprobar("el jugador aun no ha recibido el ataque",
		c.vida_jugador == c.p.vida_jugador)
	_avanzar_combate(c, c.p.pausa_drenaje + DT * 4.0)
	# Drenar pega la mitad que el reloj: sigue costando vida, pero ya no es la
	# única presión del combate.
	var golpe_drenaje := int(round(10.0 * c.p.factor_ataque_drenaje))
	_comprobar("tras la pausa el enemigo contraataca",
		c.vida_jugador == c.p.vida_jugador - golpe_drenaje, "vida %d" % c.vida_jugador)
	_comprobar("y el golpe por drenaje pesa menos que el del reloj",
		golpe_drenaje < 10 and golpe_drenaje >= 1, "%d" % golpe_drenaje)
	_avanzar_combate(c, c.p.pausa_ataque + DT * 4.0)
	_comprobar("y se sirve otra bola",
		c.mesa.bola.viva and c.mesa.bola.en_carril and c.fase == Combate.Fase.LANZANDO)

	# Golpear entre turnos no debe contar.
	_drenar(c)
	var antes := c.enemigo.vida
	_golpear(c, 1)
	_comprobar("durante la resolucion los golpes no cuentan",
		c.enemigo.vida == antes and c.golpes == 0,
		"vida %d, %d golpes" % [c.enemigo.vida, c.golpes])

	_prueba_reloj()
	_prueba_combo()
	_prueba_victoria()
	_prueba_derrota()
	_prueba_catalogo()

## El reloj del enemigo (DISEÑO.md §2): pega llegue o no la bola al drenaje.
## La bola se deja en el carril a propósito: el reloj tiene que correr también
## ahí, y así la prueba no depende de cuánto aguante una bola suelta.
func _prueba_reloj() -> void:
	var c := Combate.new()
	c.p.reloj_carga = 4.0
	c.p.reloj_aviso = 3.0
	c.iniciar(Enemigo.new({"nombre": "Reloj", "vida": 100000, "ataque": 7}))
	var avisos: Array[int] = []
	c.reloj_avisa.connect(func(s: int) -> void: avisos.append(s))

	_avanzar_combate(c, 1.0)
	_comprobar("el reloj carga mientras juegas",
		absf(c.carga_reloj - 0.25) < 0.02, "carga %.3f" % c.carga_reloj)
	_comprobar("y todavia no ha pegado", c.vida_jugador == c.p.vida_jugador)

	_avanzar_combate(c, 3.1)
	_comprobar("al llenarse el reloj el enemigo pega sin haber drenado",
		c.vida_jugador == c.p.vida_jugador - 7, "vida %d" % c.vida_jugador)
	_comprobar("y consta que el golpe vino del reloj", c.ultimo_ataque_por_reloj)
	_comprobar("el golpe del reloj no para la bola ni el combate",
		not c.terminado() and c.fase == Combate.Fase.LANZANDO,
		"fase %d" % c.fase)
	_comprobar("el reloj se rearma solo",
		c.carga_reloj < 0.2, "carga %.3f" % c.carga_reloj)
	_comprobar("avisa una vez por cada segundo de la cuenta atras",
		avisos == [3, 2, 1], str(avisos))

	# Drenar no alivia el reloj: si lo reseteara, perder la bola sería una
	# jugada defensiva y el reloj dejaría de presionar.
	var carga_antes := c.carga_reloj
	_drenar(c)
	_avanzar_combate(c, c.p.pausa_drenaje + c.p.pausa_ataque + DT * 8.0)
	_comprobar("drenar no rearma el reloj",
		c.carga_reloj >= carga_antes, "%.3f -> %.3f" % [carga_antes, c.carga_reloj])
	_comprobar("y el reloj no corre durante la resolucion del drenaje",
		c.carga_reloj - carga_antes < 0.05, "subio %.3f" % (c.carga_reloj - carga_antes))

## Los tramos: x1 hasta 4 golpes, x2 hasta 9, x3 hasta 19, x4 a partir de 20.
func _prueba_combo() -> void:
	var c := Combate.new()
	c.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000, "ataque": 1}))
	_en_juego(c)
	var esperado := {0: 1, 1: 1, 4: 1, 5: 2, 9: 2, 10: 3, 19: 3, 20: 4, 60: 4}
	var mal: Array[String] = []
	var dados := 0
	for golpes in [0, 1, 4, 5, 9, 10, 19, 20, 60]:
		_golpear(c, golpes - dados)
		dados = golpes
		if c.multiplicador() != esperado[golpes]:
			mal.append("%d golpes -> x%d (esperado x%d)"
				% [golpes, c.multiplicador(), esperado[golpes]])
	_comprobar("los tramos del combo son los que dice el parametro",
		mal.is_empty(), str(mal))

	# El multiplicador se aplica al golpe que cruza el tramo, no al siguiente.
	var c2 := Combate.new()
	c2.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000, "ataque": 1}))
	_en_juego(c2)
	_golpear(c2, 4)
	var tras_cuatro := c2.enemigo.vida
	# El quinto golpe se mide con un TARGET, no con otro bumper: el
	# multiplicador ya no se aplica al relleno. Lo que sigue comprobándose es lo
	# mismo de antes —que el tramo entra en el quinto golpe— pero medido donde
	# el multiplicador existe. Ver `escala` en Combate._golpear.
	c2.mesa.target_abatido.emit(Vector2(200, 800), 0)
	_comprobar("el quinto golpe ya vale x2",
		tras_cuatro - c2.enemigo.vida == c2.p.dano_target * 2,
		"quito %d" % (tras_cuatro - c2.enemigo.vida))
	_comprobar("los cuatro primeros valieron x1",
		c2.p.vida_jugador > 0 and (100000 - tras_cuatro) == c2.p.dano_bumper * 4,
		"quitaron %d" % (100000 - tras_cuatro))

	# Y la otra mitad de la regla: un bumper con el combo alto sigue pagando su
	# daño pelado. Sin esto, quitarle el `escala` a un bumper por accidente no
	# rompería ninguna prueba.
	var c2b := Combate.new()
	c2b.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000, "ataque": 1}))
	_en_juego(c2b)
	_golpear(c2b, 12)
	var alto := c2b.enemigo.vida
	_golpear(c2b, 1)
	_comprobar("un bumper NO cobra del multiplicador, ni con el combo alto",
		c2b.multiplicador() >= 3 and alto - c2b.enemigo.vida == c2b.p.dano_bumper,
		"x%d, quito %d" % [c2b.multiplicador(), alto - c2b.enemigo.vida])

	# Completar un banco da daño pero no es un golpe: si contara, el target que
	# lo cierra sumaría dos veces al combo.
	var c3 := Combate.new()
	c3.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000, "ataque": 1}))
	_en_juego(c3)
	var vida_antes := c3.enemigo.vida
	c3.mesa.banco_completado.emit(Vector2(56, 960), 0)
	_comprobar("la bonificacion de banco hace dano pero no suma golpe",
		c3.golpes == 0 and vida_antes - c3.enemigo.vida == c3.p.dano_banco,
		"%d golpes, %d de dano" % [c3.golpes, vida_antes - c3.enemigo.vida])

func _prueba_victoria() -> void:
	var c := Combate.new()
	# La vida sale de los parámetros: con `vida: 5` escrito a mano, subir la
	# escala de daño hizo que UN bumper ya lo matara, y la prueba dejó de medir
	# lo que dice medir —que tras la victoria los golpes no cuentan— para pasar
	# a medir la escala. Tres bumpers a x1 tienen que matarlo exactamente.
	c.iniciar(Enemigo.new({
		"nombre": "Debil", "vida": c.p.dano_bumper * 3, "ataque": 99}))
	_en_juego(c)
	_golpear(c, 3)
	_comprobar("matar al enemigo da la victoria en el acto, sin drenar",
		c.fase == Combate.Fase.VICTORIA)
	_comprobar("y se retira la bola", not c.mesa.bola.viva)
	_avanzar_combate(c, 3.0)
	_comprobar("un enemigo muerto no contraataca",
		c.vida_jugador == c.p.vida_jugador, "vida %d" % c.vida_jugador)
	var vida_muerto := c.enemigo.vida
	_golpear(c, 5)
	_comprobar("tras la victoria los golpes ya no hacen nada",
		c.enemigo.vida == vida_muerto and c.golpes == 3,
		"vida %d, %d golpes" % [c.enemigo.vida, c.golpes])

func _prueba_derrota() -> void:
	var c := Combate.new()
	c.iniciar(Enemigo.new({"nombre": "Duro", "vida": 9999, "ataque": 1000}))
	_en_juego(c)
	_drenar(c)
	_avanzar_combate(c, c.p.pausa_drenaje + 0.1)
	_comprobar("quedarse sin vida es derrota", c.fase == Combate.Fase.DERROTA)
	_comprobar("la vida no baja de cero", c.vida_jugador == 0,
		"vida %d" % c.vida_jugador)
	_avanzar_combate(c, 3.0)
	_comprobar("tras la derrota no se sirven mas bolas", not c.mesa.bola.viva)

func _prueba_catalogo() -> void:
	var lista := CatalogoEnemigos.cargar()
	_comprobar("data/enemigos.json carga", lista.size() == 9,
		"%d enemigos" % lista.size())
	var faltan: Array[String] = []
	for datos in lista:
		var e := Enemigo.new(datos)
		if e.sprite == "" or not ResourceLoader.exists(e.sprite):
			faltan.append(e.id)
		if e.vida_maxima <= 0 or e.ataque <= 0:
			faltan.append(e.id + " (stats)")
	_comprobar("todos los enemigos tienen sprite y stats validos",
		faltan.is_empty(), str(faltan))

	# El orden del catálogo NO es decorativo: sim/mapa.gd lo parte en tercios y
	# cada tercio es un acto. Si alguien reordena la lista, el acto I se puede
	# llevar a la Gárgola sin que falle nada más. Ver data/enemigos.json.
	var desordenados: Array[String] = []
	for i in range(1, lista.size()):
		var antes := Enemigo.new(lista[i - 1])
		var ahora := Enemigo.new(lista[i])
		if ahora.vida_maxima < antes.vida_maxima:
			desordenados.append("%s tras %s" % [ahora.id, antes.id])
	_comprobar("el catalogo va de menos a mas vida, que es lo que reparte los actos",
		desordenados.is_empty(), str(desordenados))

	# El golpe de reloj cobra el ataque ENTERO de una vez. Medido en
	# tests/medir_balance.gd: con 60 de vida, pasar de un quinto de la barra por
	# golpe hace que el ataque pese mas que la vida y la tabla deje de ordenarse
	# por dificultad.
	var pc := ParametrosCombate.new()
	var brutos: Array[String] = []
	for datos in lista:
		var e := Enemigo.new(datos)
		if float(e.ataque) > float(pc.vida_jugador) * 0.2:
			brutos.append("%s pega %d" % [e.id, e.ataque])
	_comprobar("ningun ataque pasa de un quinto de la vida del jugador",
		brutos.is_empty(), str(brutos))

	# El reloj de cada enemigo tiene que crecer con su vida, y por la misma razón
	# por la que el reloj es suyo: la vida dice cuánto DURA el combate y el reloj
	# cuánto APRIETA. Un enemigo del acto III con el reloj del acto I dura el
	# doble y come el doble de golpes, o sea que cuesta cuatro veces más sin que
	# nadie lo haya decidido. Es la trampa de "cobrar por tiempo se paga al
	# cuadrado", ahora a escala de tabla.
	var relojes: Array[String] = []
	for i in range(1, lista.size()):
		var antes := Enemigo.new(lista[i - 1])
		var ahora := Enemigo.new(lista[i])
		if ahora.reloj < antes.reloj:
			relojes.append("%s (%.0f) tras %s (%.0f)" % [
				ahora.id, ahora.reloj, antes.id, antes.reloj])
	_comprobar("el reloj crece con la vida a lo largo del catalogo",
		relojes.is_empty(), str(relojes))

## Los adornos del suelo están colocados a mano, que es justo lo que se
## descoloca sin avisar. Aquí se comprueba que caben en el campo, que solo la
## rejilla pisa el corredor del drenaje, y —midiéndolo de verdad— que la bola
## apenas pasa por encima de ellos.
func _prueba_adornos() -> void:
	var fuera: Array[String] = []
	var en_corredor: Array[String] = []
	var cajas: Array[Rect2] = []
	var nombres: Array[String] = []
	for adorno in VistaMesa.ADORNOS:
		var ruta := "res://assets/mesa_deco/%s.png" % adorno["tex"]
		if not ResourceLoader.exists(ruta):
			fuera.append(str(adorno["tex"]) + " (no existe)")
			continue
		var caja := VistaMesa.caja_adorno(adorno, load(ruta))
		cajas.append(caja)
		nombres.append(str(adorno["tex"]))
		if not VistaMesa.CAMPO.encloses(caja):
			fuera.append("%s %s" % [adorno["tex"], str(caja)])
		if adorno["tex"] != "rejilla" and VistaMesa.CORREDOR_DRENAJE.intersects(caja):
			en_corredor.append(str(adorno["tex"]))
	_comprobar("los adornos caben dentro del campo", fuera.is_empty(), str(fuera))
	_comprobar("solo la rejilla pisa el corredor del drenaje",
		en_corredor.is_empty(), str(en_corredor))

	# Ocupación real: se muestrea la bola en partidas aleatorias y se cuenta
	# cuántos fotogramas la tapa cada adorno.
	var visitas := PackedInt32Array()
	visitas.resize(cajas.size())
	var muestras := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA
	for _i in 40:
		var m := _nueva_mesa()
		m.nueva_bola()
		m.bola.en_carril = false
		m.bola.pos = Vector2(rng.randf_range(40, 340), rng.randf_range(760, 1050))
		var ang := rng.randf_range(0.0, TAU)
		m.bola.vel = Vector2(cos(ang), sin(ang)) * rng.randf_range(200.0, 1500.0)
		for paso in int(25.0 / DT):
			if not m.bola.viva:
				break
			m.avanzar(DT)
			if paso % 4 != 0 or not m.bola.viva:
				continue
			muestras += 1
			for j in cajas.size():
				if cajas[j].grow(m.p.radio_bola).has_point(m.bola.pos):
					visitas[j] += 1

	# Por ninguno puede pasar mucho la bola. La rejilla queda exenta: está en el
	# drenaje a propósito y marca un 13 %.
	var ruidosos: Array[String] = []
	for j in cajas.size():
		var pct := 100.0 * float(visitas[j]) / float(maxi(muestras, 1))
		print("      %-14s %.2f%%" % [nombres[j], pct])
		if nombres[j] != "rejilla" and pct > 3.0:
			ruidosos.append("%s %.2f%%" % [nombres[j], pct])
	_comprobar("por los adornos apenas pasa la bola (%d muestras)" % muestras,
		ruidosos.is_empty(), str(ruidosos))

## El racimo estaba tan abierto que la bola pasaba por el medio sin tocar nada:
## medido, 0,0 bumpers por bola lanzada. Lo que hay que asegurar es el hueco y,
## sobre todo, que al entrar rebote varias veces seguidas.
func _prueba_racimo() -> void:
	var m := _nueva_mesa()
	_comprobar("el racimo son tres bumpers", m.bumpers.size() == 3)

	var huecos: Array[float] = []
	for i in m.bumpers.size():
		for j in range(i + 1, m.bumpers.size()):
			huecos.append((m.bumpers[i] as Vector2).distance_to(m.bumpers[j])
				- m.p.bumper_radio * 2.0)
	_comprobar("es un triangulo con el hueco que dice el parametro",
		absf(huecos.min() - m.p.bumper_hueco) < 1.0
		and absf(huecos.max() - m.p.bumper_hueco) < 1.0,
		"huecos entre %.1f y %.1f, pedido %.1f"
			% [huecos.min(), huecos.max(), m.p.bumper_hueco])
	_comprobar("y la bola entra, que si no el racimo es una pared",
		huecos.min() > m.p.radio_bola * 2.0,
		"hueco %.1f px, bola %.1f" % [huecos.min(), m.p.radio_bola * 2.0])

	# Lo que de verdad importa: entrar por el medio tiene que dar cadena.
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA
	var total := 0
	var intentos := 24
	for _i in intentos:
		var m2 := _nueva_mesa()
		m2.nueva_bola()
		m2.bola.en_carril = false
		# Entrando de verdad por el hueco de arriba, no rozando el racimo de
		# refilón: con un cono ancho la mitad de las bolas ni entran, y lo que
		# se quiere medir es qué pasa cuando SÍ entra.
		m2.bola.pos = m2.p.bumper_centro + Vector2(rng.randf_range(-14, 14), -120)
		m2.bola.vel = Vector2(rng.randf_range(-60, 60), 480)
		var golpes := [0]
		m2.bumper_golpeado.connect(func(_pt: Vector2, _f: float) -> void:
			golpes[0] += 1)
		for _j in int(2.5 / DT):
			if not m2.bola.viva:
				break
			m2.avanzar(DT)
		total += golpes[0]
	var media := float(total) / float(intentos)
	# Medido: 3,7 de media con hueco 24 y dos bumpers arriba. Con uno arriba
	# eran 1,4. El umbral va en 3 para dejar margen sin perder el diente.
	_comprobar("cayendo dentro del racimo, la bola encadena golpes",
		media >= 3.0, "%.1f bumpers por entrada" % media)

## Los outlanes son la válvula de dificultad: sin ellos solo se pierde la bola
## por el hueco entre palas, que es un objetivo pequeño.
func _prueba_outlanes() -> void:
	var m := _nueva_mesa()
	# La boca tiene que medir lo que dice el parámetro y tragar la bola.
	_comprobar("la boca del outlane es mas ancha que la bola",
		m.p.ancho_outlane > m.p.radio_bola * 2.0,
		"boca %.0f px, bola %.0f" % [m.p.ancho_outlane, m.p.radio_bola * 2.0])

	# Una bola que baja pegada a la pared de fuera se pierde por el outlane.
	# Una que baja más hacia dentro cae en el carril de retorno y sobrevive.
	for lado in [
			{"nombre": "izquierdo", "pegada": 32.0, "dentro": 66.0},
			{"nombre": "derecho", "pegada": 346.0, "dentro": 312.0}]:
		var m2 := _nueva_mesa()
		m2.nueva_bola()
		m2.bola.en_carril = false
		m2.bola.pos = Vector2(lado["pegada"], 1020)
		m2.bola.vel = Vector2(0, 260)
		var r := _simular(m2, 6.0)
		_comprobar("pegada a la pared, el outlane %s se traga la bola" % lado["nombre"],
			r["drenada"], "acabo en %s" % str(r["pos"].round()))

		var m3 := _nueva_mesa()
		m3.nueva_bola()
		m3.bola.en_carril = false
		m3.bola.pos = Vector2(lado["dentro"], 1020)
		m3.bola.vel = Vector2(0, 260)
		var toca_flipper := [false]
		m3.flipper_golpeado.connect(func(_pt: Vector2, _f: float) -> void:
			toca_flipper[0] = true)
		for _i in int(3.0 / DT):
			if not m3.bola.viva or toca_flipper[0]:
				break
			m3.avanzar(DT)
		_comprobar("y por dentro baja al flipper por el retorno %s" % lado["nombre"],
			toca_flipper[0], "no llego a la pala")

## Atrapar la bola: con la pala arriba y quieta, la bola se asienta en vez de
## resbalar. Es lo que permite apuntar antes de soltar.
func _prueba_agarre() -> void:
	var m := _nueva_mesa()
	m.nueva_bola()
	m.bola.en_carril = false
	m.flipper_izq.pulsado = true
	# Que la pala llegue arriba y se quede quieta.
	for _i in int(0.3 / DT):
		m.avanzar(DT)
	_comprobar("la pala llega arriba y se para",
		absf(m.flipper_izq.omega) < m.p.flipper_omega_quieta)

	# Bola apoyada encima de la pala levantada, a media longitud del eje.
	var dir := Vector2(cos(m.flipper_izq.angulo), sin(m.flipper_izq.angulo))
	var normal := Vector2(-dir.y, dir.x)
	m.bola.pos = m.p.flipper_eje_izq + dir * 42.0 \
		+ normal * -(m.p.flipper_radio + m.p.radio_bola - 0.5)
	m.bola.vel = dir * 150.0
	for _i in int(1.2 / DT):
		m.avanzar(DT)
	_comprobar("con la pala arriba y quieta, la bola se asienta",
		m.bola.viva and m.bola.velocidad() < 40.0,
		"viva=%s a %.0f px/s" % [m.bola.viva, m.bola.velocidad()])

	# Y SE ASIENTA DONDE LA PALA TIENE PALANCA. Esto es lo que decide si la cuna
	# sirve de algo: la velocidad que le mete la pala es omega por radio, así que
	# una bola posada junto al eje no se puede disparar a ningún sitio.
	#
	# Con la pala levantada a -32° la bola rodaba hasta 0,18 de la pala, o sea
	# 11 px de 64: el tiro subía 40 px y no llegaba a ninguna boca. Y encima no
	# llegaba a asentarse, porque se caía por el canto del eje y la pala la
	# volvía a coger en bucle. Aplanar la pala levantada arregla las dos cosas.
	var dir_izq := m.flipper_izq.punta() - m.p.flipper_eje_izq
	var donde := (m.bola.pos - m.p.flipper_eje_izq).dot(dir_izq) \
		/ dir_izq.length_squared()
	_comprobar("y se asienta lejos del eje, donde la pala tiene palanca",
		donde > 0.60, "acabo a %.2f de la pala; junto al eje no hay tiro" % donde)

	# Con la bola asentada, la simulación tiene que SABER que está atrapada: es
	# lo que enciende el aviso y la línea de puntería.
	_comprobar("la mesa sabe que la bola esta atrapada",
		m.flipper_atrapando != null,
		"velocidad %.0f, umbral %.0f" % [m.bola.velocidad(), m.p.velocidad_atrapada])

	# Y con la pala sostenida se queda QUIETA de verdad, no botando encima. Con
	# la pala a -32° la bola daba picos de 137 px/s estando "atrapada": rodaba
	# hasta el canto del eje, se caía por ahí y la pala la volvía a coger.
	var pico := 0.0
	for _i in int(1.0 / DT):
		m.avanzar(DT)
		pico = maxf(pico, m.bola.velocidad())
	_comprobar("y se queda quieta, no botando sobre la pala",
		pico < 45.0, "llego a %.0f px/s con la pala sostenida" % pico)

	# Y soltar sigue lanzando: el agarre no puede matar el tacto del flipper.
	var antes := m.bola.velocidad()
	m.flipper_izq.pulsado = false
	for _i in int(0.2 / DT):
		m.avanzar(DT)
	m.flipper_izq.pulsado = true
	var maxima := 0.0
	for _i in int(0.3 / DT):
		m.avanzar(DT)
		maxima = maxf(maxima, m.bola.velocidad())
	_comprobar("y soltar y volver a dar sigue lanzando",
		maxima > antes + 300.0, "de %.0f a %.0f px/s" % [antes, maxima])
	_prueba_no_se_queda_pegada()
	_prueba_cae_acelerando()
	_prueba_la_cuna_alcanza()

## EL PILAR, medido: `DISEÑO.md` §1 dice que la mesa es un menú de tiros, y el
## único tiro repetible que hay es el de la bola atrapada en la cuna. Si ese
## tiro no llega a la altura de las bocas, no hay menú: le das a las palas y que
## sea lo que Dios quiera, que es literalmente lo que reportó Daniel.
##
## Con la pala a 22 rad/s el tiro subía a y=1032 y las bocas están a y=790 (el
## retorno y el cañón) y y=880/935 (la órbita). No llegaba a ninguna. Con 30
## sube a y=787.
##
## Se mide la ALTURA, no qué toca: adónde apunta exactamente depende de la
## geometría de cada boca y eso se ajusta jugando; lo que no es negociable es
## que la bola tenga fuerza para llegar arriba.
func _prueba_la_cuna_alcanza() -> void:
	var m := _nueva_mesa()
	m.nueva_bola()
	m.bola.en_carril = false
	var f := m.flipper_izq
	f.pulsado = true
	for _i in int(0.35 / DT):
		m.avanzar(DT)
	var dir := Vector2(cos(f.angulo), sin(f.angulo))
	var normal := Vector2(-dir.y, dir.x)
	m.bola.pos = f.eje + dir * (m.p.flipper_longitud * 0.55) \
		- normal * (m.p.flipper_radio + m.p.radio_bola - 0.5)
	m.bola.vel = Vector2.ZERO
	for _i in int(1.2 / DT):
		m.avanzar(DT)
	_comprobar("la bola llega a atraparse para el tiro",
		m.flipper_atrapando != null, "%.0f px/s" % m.bola.velocidad())

	var toco := [false]
	m.target_abatido.connect(func(_p: Vector2, _b: int) -> void: toco[0] = true)
	m.bumper_golpeado.connect(func(_p: Vector2, _x: float) -> void: toco[0] = true)
	m.rampa_entrada.connect(func(_p: Vector2, _i: int) -> void: toco[0] = true)
	m.platillo_capturado.connect(func(_p: Vector2, _i: int) -> void: toco[0] = true)

	f.pulsado = false
	for _i in int(0.12 / DT):
		m.avanzar(DT)
	f.pulsado = true
	var t := 0.0
	var alto := 9999.0
	while m.bola.viva and t < 6.0:
		m.avanzar(DT)
		t += DT
		alto = minf(alto, m.bola.pos.y)

	# La boca más baja donde se ENTRA está en y=935 (la órbita por la izquierda).
	# Llegar ahí es el mínimo para que el tiro sirva de algo.
	_comprobar("el tiro desde la cuna llega a la altura de las bocas",
		alto < 935.0, "solo subio a y=%.0f; la boca mas baja esta en y=935" % alto)
	_comprobar("y toca algo por el camino, no se pierde en vacio",
		toco[0], "no toco nada")

## Al soltar la pala con la bola atrapada, la bola tiene que ir BAJANDO CADA VEZ
## MÁS RÁPIDO. Lo cazó Daniel jugando: bajaba a velocidad constante.
##
## La causa era el modelo: el arrastre de rodadura iba proporcional a la
## velocidad, y eso le pone velocidad límite (gravedad·sen(cuesta)/rodadura).
## Con rodadura 20 esa límite salía a 41 px/s, o sea que la bola alcanzaba su
## tope en cuanto empezaba a moverse y de ahí no pasaba. Se ve falso al instante
## porque una bola con peso no hace eso.
##
## La prueba mide lo que se ve, no el parámetro: velocidad cada 0,15 s tras
## soltar. Si se aplana, es que la límite ha vuelto a caer dentro del rango que
## la bola alcanza en una pala.
func _prueba_cae_acelerando() -> void:
	var m := _nueva_mesa()
	m.nueva_bola()
	m.bola.en_carril = false
	m.flipper_izq.pulsado = true
	for _i in int(0.35 / DT):
		m.avanzar(DT)
	var f := m.flipper_izq
	var dir := Vector2(cos(f.angulo), sin(f.angulo))
	var normal := Vector2(-dir.y, dir.x)
	# Se mide rodando por la pala EN REPOSO, que es la cuesta limpia: soltando
	# desde la cuna hay un bote de por medio y el número se ensucia. Lo que se
	# comprueba es lo mismo: que la gravedad la acelere de verdad.
	m.flipper_izq.pulsado = false
	for _i in int(0.4 / DT):
		m.avanzar(DT)
	var dir2 := Vector2(cos(f.angulo), sin(f.angulo))
	var normal2 := Vector2(-dir2.y, dir2.x)
	m.bola.pos = f.eje + dir2 * (m.p.flipper_longitud * 0.35) \
		- normal2 * (m.p.flipper_radio + m.p.radio_bola - 0.5)
	m.bola.vel = Vector2.ZERO
	var v: Array[float] = []
	for _tramo in 3:
		for _i in int(0.10 / DT):
			m.avanzar(DT)
		v.append(m.bola.velocidad())
	var texto := "%.0f, %.0f, %.0f" % [v[0], v[1], v[2]]
	_comprobar("rodando por la pala, la bola va ACELERANDO",
		v[1] > v[0] + 20.0 and v[2] > v[1] + 20.0, "px/s cada 0,1 s: %s" % texto)

	# Y la razón de fondo, por si alguien vuelve a subir la rodadura: la
	# velocidad límite del arrastre tiene que quedar MUY por encima de lo que la
	# bola alcanza rodando por una pala, o vuelve a verse plana.
	var cuesta := sin(deg_to_rad(m.p.flipper_reposo_izq))
	var limite := m.p.gravedad * cuesta / maxf(m.p.rodadura, 0.001)
	_comprobar("la velocidad limite de la rodadura queda fuera de rango",
		limite > 150.0, "limite %.0f px/s con rodadura %.1f" % [limite, m.p.rodadura])

## La otra mitad, y la que se rompió una vez: una bola apoyada en una pala EN
## REPOSO tiene que rodar y acabar yéndose. Una bola rueda, no se sostiene en
## una cuesta, y el rozamiento de Coulomb sí puede sostenerla: por eso el
## contacto sostenido va con rodadura y no con Coulomb. Si esta prueba falla,
## `rodadura` se ha subido demasiado y la bola vuelve a soldarse a la pala.
func _prueba_no_se_queda_pegada() -> void:
	var m := _nueva_mesa()
	m.nueva_bola()
	m.bola.en_carril = false
	for _i in int(0.3 / DT):
		m.avanzar(DT)
	# Posada quieta a media pala, sin nada de velocidad que la ayude.
	var dir := Vector2(cos(m.flipper_izq.angulo), sin(m.flipper_izq.angulo))
	var normal := Vector2(-dir.y, dir.x)
	m.bola.pos = m.p.flipper_eje_izq + dir * (m.p.flipper_longitud * 0.55) \
		+ normal * -(m.p.flipper_radio + m.p.radio_bola - 0.5)
	m.bola.vel = Vector2.ZERO
	var salio := -1.0
	var t := 0.0
	while t < 3.0 and salio < 0.0:
		m.avanzar(DT)
		t += DT
		if m.bola.pos.y > m.p.flipper_eje_izq.y + 24.0 or not m.bola.viva:
			salio = t
	_comprobar("posada en una pala en reposo, la bola rueda y se va",
		salio > 0.0, "sigue en la pala tras 3 s a %.1f px/s" % m.bola.velocidad())
	_comprobar("y no tarda una eternidad en hacerlo",
		salio > 0.0 and salio < 2.0, "tardo %.2f s" % salio)

## Los tres recorridos tienen que pagar cosas distintas, o son un tiro repetido.
func _prueba_identidad_recorridos() -> void:
	var m := _nueva_mesa()
	var premios := {}
	var nombres: Array[String] = []
	for r in m.rampas:
		premios[r.premio] = true
		nombres.append(r.nombre)
	_comprobar("los tres recorridos pagan tres cosas distintas",
		premios.size() == 3 and nombres.size() == 3,
		"%d premios distintos en %s" % [premios.size(), str(nombres)])

	# La órbita sube el multiplicador de tramo, sin encadenar golpes.
	var c := Combate.new()
	c.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000, "ataque": 1}))
	_en_juego(c)
	var indice_orbita := -1
	var indice_fuerte := -1
	for i in c.mesa.rampas.size():
		var r: Rampa = c.mesa.rampas[i]
		if r.premio == Rampa.Premio.MULTIPLICADOR:
			indice_orbita = i
		elif r.premio == Rampa.Premio.DANO_FUERTE:
			indice_fuerte = i
	c.mesa.rampa_salida.emit(Vector2(200, 900), indice_orbita)
	_comprobar("completar la orbita sube el multiplicador de golpe",
		c.multiplicador() == 2, "quedo en x%d con %d golpes"
			% [c.multiplicador(), c.golpes])

	# Y el cañón pega más que un carril normal.
	var c2 := Combate.new()
	c2.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000, "ataque": 1}))
	_en_juego(c2)
	var vida := c2.enemigo.vida
	c2.mesa.rampa_salida.emit(Vector2(200, 900), indice_fuerte)
	var golpe_fuerte := vida - c2.enemigo.vida
	_comprobar("el canon pega mas que un carril normal",
		golpe_fuerte > c2.p.dano_rampa,
		"%d contra %d" % [golpe_fuerte, c2.p.dano_rampa])

	_prueba_canon_escupe(m)
	_prueba_platillo_atrasa_reloj()

## El cañón no deja la bola puesta: la escupe CRUZADA Y RÁPIDA hacia la pala
## contraria. Es lo que paga el golpe gordo, y lo que lo distingue del carril de
## retorno, que sí te la deja servida. Si esta prueba falla, el cañón ha vuelto
## a ser un segundo carril de retorno.
func _prueba_canon_escupe(m: Mesa) -> void:
	var indice := -1
	for i in m.rampas.size():
		if (m.rampas[i] as Rampa).premio == Rampa.Premio.DANO_FUERTE:
			indice = i
	var r: Rampa = m.rampas[indice]
	m.nueva_bola()
	m.bola.en_carril = false
	m.bola.rampa = indice
	m.bola.rampa_sentido = 1
	m.bola.rampa_velocidad = 900.0
	m.bola.rampa_distancia = r.largo - 1.0

	var v_salida := 0.0
	var t_salida := -1.0
	var t_pala := -1.0
	var t := 0.0
	while m.bola.viva and t < 4.0:
		m.avanzar(DT)
		t += DT
		if m.bola.rampa >= 0:
			continue
		if t_salida < 0.0:
			t_salida = t
			v_salida = m.bola.velocidad()
		if t_pala < 0.0 and m.bola.pos.distance_to(m.p.flipper_eje_der) < 75.0:
			t_pala = t
	_comprobar("el canon escupe la bola, no la posa",
		v_salida > 250.0, "salio a %.0f px/s" % v_salida)
	_comprobar("y cruzada hacia la pala contraria",
		t_pala > 0.0, "no llego a la pala derecha")

	# LA PRUEBA QUE ESTABA MAL ESCRITA: exigía que saliera RÁPIDA, y eso es
	# justo lo que hacía el tiro imposible. Un humano reacciona en 250 ms; si la
	# bola llega antes, el premio del cañón es perder la bola con pasos extra.
	# Lo que hay que exigir no es velocidad, es que dé tiempo a jugarla.
	_comprobar("y con tiempo humano para cazarla (>250 ms)",
		t_pala > 0.0 and (t_pala - t_salida) > 0.25,
		"solo %.0f ms" % ((t_pala - t_salida) * 1000.0))

## El platillo paga en TIEMPO, no en daño: es el único tiro que da algo que no
## es pegar, y es lo que hace que la mesa tenga una decisión de verdad cuando
## vas justo de vida.
func _prueba_platillo_atrasa_reloj() -> void:
	var c := Combate.new()
	c.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000, "ataque": 1}))
	_en_juego(c)
	_avanzar_combate(c, c.p.reloj_carga * 0.6)
	var antes := c.carga_reloj
	var ganado := [0.0]
	c.reloj_atrasado.connect(func(s: float) -> void: ganado[0] = s)
	c.mesa.platillo_expulsado.emit(Vector2(70, 170), 0)
	_comprobar("sacar la bola del platillo atrasa el reloj",
		c.carga_reloj < antes - 0.3,
		"de %.2f a %.2f" % [antes, c.carga_reloj])
	# Contra los PARÁMETROS, no contra un 4 escrito a mano. El 4 venía de cuando
	# el reloj cargaba en 18 s: al partirlo en 9 los segundos ganados pasaron a
	# ~3 y la prueba empezó a fallar sin que nada estuviera roto. Lo que hay que
	# comprobar es que se avisa de lo que de verdad se ha robado.
	var esperado := c.p.platillo_atrasa_reloj * c.p.reloj_carga
	_comprobar("y avisa de cuantos segundos se han ganado",
		absf(ganado[0] - esperado) < 0.2,
		"%.1f s, se esperaban %.1f" % [ganado[0], esperado])
	_comprobar("pero paga menos dano que el canon",
		c.p.dano_platillo < c.p.dano_rampa_fuerte,
		"%d contra %d" % [c.p.dano_platillo, c.p.dano_rampa_fuerte])

	# Y no puede dejar el reloj en negativo ni pasarse de rosca.
	c.carga_reloj = 0.1
	c.mesa.platillo_expulsado.emit(Vector2(70, 170), 0)
	_comprobar("y nunca deja el reloj por debajo de cero",
		c.carga_reloj == 0.0, "quedo en %.2f" % c.carga_reloj)

## El mapa del run. Lo que hay que blindar de un mapa generado no es que salga
## bonito, sino que sea RECORRIBLE: sin nodos huérfanos, sin ramas que se ven y
## no se pueden tomar, y con un jefe cerrando cada acto.
func _prueba_mapa() -> void:
	var catalogo := CatalogoEnemigos.cargar()
	var huerfanos := 0
	var sin_salida := 0
	var jefes := 0
	var descansos := 0
	var anchos_uno := 0
	# Cien mapas con semillas distintas: un mapa generado hay que probarlo
	# muchas veces, porque el caso que rompe sale una de cada treinta.
	for s in range(1, 101):
		var m := Mapa.new(ParametrosRun.new(), catalogo, s)
		for i in m.alto():
			var f: Array = m.fila(i)
			if f.is_empty():
				anchos_uno += 1
			for n in f:
				var nodo := n as NodoMapa
				if nodo.tipo == NodoMapa.Tipo.JEFE:
					jefes += 1
				elif nodo.tipo == NodoMapa.Tipo.DESCANSO:
					descansos += 1
				if i < m.alto() - 1 and nodo.salidas.is_empty():
					sin_salida += 1
				for c in nodo.salidas:
					if c < 0 or c >= (m.fila(i + 1) as Array).size():
						sin_salida += 1
			if i == 0:
				continue
			for c in f.size():
				var alcanzable := false
				for n in m.fila(i - 1):
					if (n as NodoMapa).salidas.has(c):
						alcanzable = true
				if not alcanzable:
					huerfanos += 1
	_comprobar("ningun nodo del mapa queda inalcanzable",
		huerfanos == 0, "%d huerfanos en 100 mapas" % huerfanos)
	_comprobar("y ningun nodo se queda sin salida valida",
		sin_salida == 0, "%d fallos" % sin_salida)
	_comprobar("no hay filas vacias", anchos_uno == 0)
	var pr := ParametrosRun.new()
	_comprobar("hay un jefe por acto",
		jefes == 100 * pr.actos, "%d jefes en 100 mapas" % jefes)
	_comprobar("y descansos, pero no en todos los actos de todos los mapas",
		descansos > 0 and descansos < 100 * pr.actos,
		"%d descansos" % descansos)

	# El enemigo de cada nodo se decide AL GENERAR, no al llegar: hay que poder
	# mirar el camino y elegir sabiendo lo que viene.
	var m2 := Mapa.new(ParametrosRun.new(), catalogo, 7)
	var sin_enemigo := 0
	var jefe_flojo := 0
	for i in m2.alto():
		for n in m2.fila(i):
			var nodo := n as NodoMapa
			if not nodo.es_combate():
				continue
			if nodo.enemigo.is_empty() or int(nodo.enemigo.get("vida", 0)) <= 0:
				sin_enemigo += 1
	for a in ParametrosRun.new().actos:
		var f_jefe: Array = m2.fila((a + 1) * (ParametrosRun.new().filas_por_acto + 1) - 1)
		var vida_jefe := int((f_jefe[0] as NodoMapa).enemigo.get("vida", 0))
		var vida_normal := 0
		for n in m2.fila((a + 1) * (ParametrosRun.new().filas_por_acto + 1) - 2):
			vida_normal = maxi(vida_normal, int((n as NodoMapa).enemigo.get("vida", 0)))
		if vida_jefe <= 0:
			jefe_flojo += 1
	_comprobar("todo nodo de combate trae su enemigo ya decidido",
		sin_enemigo == 0, "%d nodos sin enemigo" % sin_enemigo)
	_comprobar("y el jefe de cada acto tiene vida propia",
		jefe_flojo == 0, "%d jefes sin vida" % jefe_flojo)

## El run: la vida NO se cura entre combates. Es lo que separa un run de una
## lista de combates, y el criterio de salida de la fase 3C depende de ello.
func _prueba_run() -> void:
	var catalogo := CatalogoEnemigos.cargar()
	var r := Run.new(ParametrosRun.new(), ParametrosCombate.new(), catalogo, 11)
	_comprobar("el run arranca fuera del mapa y con la vida a tope",
		r.fila == -1 and r.vida == r.vida_maxima and r.vida > 0)
	_comprobar("y puede entrar por cualquier nodo de la primera fila",
		r.opciones().size() == (r.mapa.fila(0) as Array).size())

	_comprobar("no se puede saltar a una rama que no sale de aqui",
		r.elegir(99) == null)

	var primero := r.elegir(r.opciones()[0])
	_comprobar("entrar en un nodo de combate abre el combate",
		primero != null and primero.es_combate()
			and r.fase == Run.Fase.EN_COMBATE, "tipo %s" % NodoMapa.nombre_de(
				primero.tipo if primero != null else -1))

	# Ganar con 20 de vida deja el run con 20: lo que te dejas, te lo debes.
	r.resolver_combate(true, 20)
	_comprobar("la vida NO se cura al ganar un combate",
		r.vida == 20, "quedo con %d" % r.vida)
	_comprobar("y el run sigue, eligiendo rama",
		r.fase == Run.Fase.ELIGIENDO and not r.opciones().is_empty())

	# Solo se puede ir a donde lleva el nodo en el que estás.
	var validas := r.opciones()
	var invalida := -1
	for c in range((r.mapa.fila(r.fila + 1) as Array).size()):
		if not validas.has(c):
			invalida = c
	if invalida >= 0:
		_comprobar("las ramas que no salen de tu nodo no se pueden tomar",
			r.elegir(invalida) == null)
	else:
		_comprobar("las ramas que no salen de tu nodo no se pueden tomar",
			true, "esta fila conectaba con todas")

	_prueba_run_descanso(catalogo)
	_prueba_run_derrota(catalogo)
	_prueba_run_victoria(catalogo)
	_prueba_pantalla_mapa(catalogo)

## La pantalla del mapa sin dibujar nada: lo que puede romperse aquí es la
## elección, no el dibujo. Marcar una rama y entrar por otra sería el fallo.
func _prueba_pantalla_mapa(catalogo: Array) -> void:
	var r := Run.new(ParametrosRun.new(), ParametrosCombate.new(), catalogo, 13)
	var pantalla := NodoPantallaMapa.new(r, ParametrosCamara.new())
	get_root().add_child(pantalla)

	var opciones := r.opciones()
	pantalla.seleccion = 0
	pantalla.mover(1)
	_comprobar("mover la seleccion no se sale de las opciones",
		pantalla.seleccion >= 0 and pantalla.seleccion < opciones.size(),
		"seleccion %d de %d" % [pantalla.seleccion, opciones.size()])
	pantalla.mover(-1)
	pantalla.mover(-1)
	_comprobar("y da la vuelta por los dos lados",
		pantalla.seleccion == opciones.size() - 1, "%d" % pantalla.seleccion)

	# La ficha tiene que describir el nodo en el que vas a ENTRAR. Si enseña uno
	# y te mete en otro, el mapa miente y elegir rama deja de significar nada:
	# es el fallo más caro que puede tener esta pantalla, porque no se nota
	# hasta que ya estás dentro del combate equivocado.
	for i in opciones.size():
		pantalla.seleccion = i
		var ficha := pantalla.nodo_marcado(opciones)
		_comprobar("la ficha describe la rama marcada (%d)" % i,
			ficha != null and ficha.columna == opciones[i] and ficha.fila == r.fila + 1,
			"ficha en columna %s, marcada %d" % [
				"null" if ficha == null else str(ficha.columna), opciones[i]])

	# Todo enemigo del catálogo tiene que traer un sprite que exista, o el
	# retrato de la ficha sale vacío justo en el nodo que estás mirando.
	for e in catalogo:
		var ruta := str((e as Dictionary).get("sprite", ""))
		_comprobar("el enemigo %s tiene retrato" % str((e as Dictionary).get("id", "?")),
			ruta != "" and ResourceLoader.exists(ruta), "sprite '%s'" % ruta)

	# Y NINGUNO PUEDE SER MÁS GRANDE QUE SU HUECO. El enemigo se dibuja a su
	# tamaño nativo con los pies posados dentro del panel, así que un sprite de
	# 128 —los de `assets/jefes/`— se saldría por arriba y se metería en la barra
	# de título. No daría ningún error: dejaría un bicho cortado. Y el retrato
	# del mapa además escalaría 128 a 96, que no es división entera y hierve.
	var grandes: Array[String] = []
	for e in catalogo:
		var ruta := str((e as Dictionary).get("sprite", ""))
		if ruta == "" or not ResourceLoader.exists(ruta):
			continue
		var tex := load(ruta) as Texture2D
		if tex == null:
			continue
		var lado := NodoCascara.LADO_RETRATO_PANEL
		if float(tex.get_height()) > lado or float(tex.get_width()) > lado \
				or int(NodoPantallaMapa.RETRATO_NODO) == 0 \
				or tex.get_height() % int(NodoPantallaMapa.RETRATO_NODO) != 0:
			grandes.append("%s %dx%d" % [ruta, tex.get_width(), tex.get_height()])
	_comprobar("todos los retratos caben en el panel y escalan por enteros",
		grandes.is_empty(), str(grandes))

	pantalla.seleccion = 0
	var esperado: int = opciones[0]
	var entrado := pantalla.confirmar()
	_comprobar("entrar mete en el nodo que estaba marcado",
		entrado != null and r.columna == esperado and r.fila == 0,
		"entro en (%d,%d), se esperaba columna %d" % [r.fila, r.columna, esperado])
	_comprobar("el acto visible es el del nodo en el que estas",
		pantalla.acto_visible() == 0, "%d" % pantalla.acto_visible())

	# Todos los tipos tienen letra y color propios, o el mapa no se lee.
	var letras := {}
	var colores := {}
	for tipo in [NodoMapa.Tipo.COMBATE, NodoMapa.Tipo.ELITE,
			NodoMapa.Tipo.DESCANSO, NodoMapa.Tipo.JEFE]:
		letras[NodoPantallaMapa.letra_de(tipo)] = true
		colores[NodoPantallaMapa.color_de(tipo)] = true
	_comprobar("cada tipo de nodo tiene letra y color propios",
		letras.size() == 4 and colores.size() == 4,
		"%d letras, %d colores" % [letras.size(), colores.size()])

	pantalla.queue_free()

func _prueba_run_descanso(catalogo: Array) -> void:
	# Se busca un descanso recorriendo el mapa, y se comprueba que cura algo
	# pero no del todo: si curara entero, descansar sería siempre lo correcto.
	var r := Run.new(ParametrosRun.new(), ParametrosCombate.new(), catalogo, 3)
	var curado := [-1]
	r.descansado.connect(func(c: int) -> void: curado[0] = c)
	var encontrado := false
	var vueltas := 0
	while not r.terminada() and vueltas < 40:
		vueltas += 1
		var opciones := r.opciones()
		if opciones.is_empty():
			break
		# Se elige siempre la rama que lleve a un descanso si la hay.
		var destino: int = opciones[0]
		for c in opciones:
			if (r.mapa.nodo(r.fila + 1, c) as NodoMapa).tipo == NodoMapa.Tipo.DESCANSO:
				destino = c
		var n := r.elegir(destino)
		if n == null:
			break
		if n.tipo == NodoMapa.Tipo.DESCANSO:
			encontrado = true
			break
		r.resolver_combate(true, 10)
	_comprobar("descansar cura, pero no del todo",
		not encontrado or (curado[0] > 0 and r.vida < r.vida_maxima),
		"curo %d y quedo en %d/%d" % [curado[0], r.vida, r.vida_maxima])

func _prueba_run_derrota(catalogo: Array) -> void:
	var r := Run.new(ParametrosRun.new(), ParametrosCombate.new(), catalogo, 5)
	var aviso := [2]
	r.run_terminada.connect(func(v: bool) -> void: aviso[0] = 1 if v else 0)
	r.elegir(r.opciones()[0])
	r.resolver_combate(false, 0)
	_comprobar("perder un combate acaba el run",
		r.terminada() and not r.victoria and aviso[0] == 0)
	_comprobar("y despues ya no se puede elegir nada",
		r.opciones().is_empty() and r.elegir(0) == null)

func _prueba_run_victoria(catalogo: Array) -> void:
	# Recorrer el mapa entero ganándolo todo tiene que acabar en victoria de run.
	var r := Run.new(ParametrosRun.new(), ParametrosCombate.new(), catalogo, 9)
	var combates := 0
	var vueltas := 0
	while not r.terminada() and vueltas < 100:
		vueltas += 1
		var opciones := r.opciones()
		if opciones.is_empty():
			break
		var n := r.elegir(opciones[0])
		if n == null:
			break
		if n.es_combate():
			combates += 1
			r.resolver_combate(true, r.vida)
	_comprobar("ganarlo todo termina el run en victoria",
		r.terminada() and r.victoria, "acabo en fila %d de %d"
			% [r.fila, r.mapa.alto()])
	_comprobar("y el camino son los doce a quince combates de DISENO.md",
		combates >= 12 and combates <= 15, "%d combates" % combates)

## LA PRUEBA QUE FALTABA, y por eso el fallo llegó a manos de Daniel: la
## batería entera pasaba mientras el juego era injugable.
##
## Un lanzamiento a tope engancha la órbita SIEMPRE, y la órbita salía por
## (44,880), pegada a la pared izquierda y bajando casi vertical: la bola daba
## tres rebotes contra la banda y se iba por el outlane izquierdo sin acercarse
## a una pala. O sea que la apertura de TODAS las bolas era perderla sin jugar.
##
## Ninguna prueba lo veía porque todas miraban que la bola no se saliera, no se
## atascara y acabara drenando, y eso lo cumplía: drenaba de maravilla. Lo que
## no había era nadie comprobando que la bola llegue a donde se juega.
func _prueba_apertura() -> void:
	var malas: Array[String] = []
	for i in 5:
		var carga := 0.80 + 0.05 * float(i)
		var m := _nueva_mesa()
		m.nueva_bola()
		var t_carga := 0.0
		while t_carga < m.p.tiempo_carga_lanzador * carga:
			m.cargar_lanzador(DT)
			t_carga += DT
		m.soltar_lanzador()
		var t := 0.0
		var llego := false
		var salio := false
		while m.bola.viva and t < 30.0:
			m.avanzar(DT)
			t += DT
			if m.bola.en_carril:
				continue
			salio = true
			if m.bola.pos.distance_to(m.p.flipper_eje_izq) < 80.0 \
					or m.bola.pos.distance_to(m.p.flipper_eje_der) < 80.0:
				llego = true
				break
		if salio and not llego:
			malas.append("%.0f%% muere en x=%.0f" % [carga * 100.0, m.bola.pos.x])
	_comprobar("una bola lanzada llega a una pala, no al desague",
		malas.is_empty(), str(malas))

	# Y lo mismo por los dos sentidos de la órbita y a varias velocidades: la
	# regla no es dónde está la boca —los dos lados de la mesa tienen geometría
	# distinta y medirlo por simetría da un falso positivo— sino que después de
	# salir la bola llegue a una pala. Completar la órbita es el tiro difícil de
	# la mesa: acabar en el desagüe por haberlo clavado no se sostiene.
	var fallos: Array[String] = []
	for sentido in [1, -1]:
		for velocidad in [600.0, 800.0, 1000.0]:
			var m2 := _nueva_mesa()
			var orbita := -1
			for i in m2.rampas.size():
				if (m2.rampas[i] as Rampa).nombre == "orbita":
					orbita = i
			var r: Rampa = m2.rampas[orbita]
			m2.nueva_bola()
			m2.bola.en_carril = false
			m2.bola.rampa = orbita
			m2.bola.rampa_sentido = sentido
			m2.bola.rampa_velocidad = velocidad
			m2.bola.rampa_distancia = (r.largo - 1.0) if sentido > 0 else 1.0
			var t := 0.0
			var llego := false
			while m2.bola.viva and t < 30.0 and not llego:
				m2.avanzar(DT)
				t += DT
				if m2.bola.rampa >= 0:
					continue
				if m2.bola.pos.distance_to(m2.p.flipper_eje_izq) < 80.0 \
						or m2.bola.pos.distance_to(m2.p.flipper_eje_der) < 80.0:
					llego = true
			if not llego:
				fallos.append("sentido %d a %.0f muere en x=%.0f"
					% [sentido, velocidad, m2.bola.pos.x])
	_comprobar("salir de la orbita deja la bola en una pala, no en el desague",
		fallos.is_empty(), str(fallos))

## La bola no puede quedarse ENCERRADA rebotando. Es distinto de un atasco: en
## un atasco se para y el ball search la saca; aquí va a toda velocidad en un
## palmo de mesa, así que el ball search no salta y el jugador mira sin poder
## hacer nada.
##
## Pasaba en el pasillo entre la banda del outlane y el slingshot, que van casi
## paralelos: el slingshot empujaba también por su espalda, o sea que le pegaba
## un patadón contra la pared, la bola volvía, y otro patadón. Medido: hasta
## 4,1 s a 340 px/s. Lo vio Daniel jugando y lo mandó en una captura.
##
## La prueba no busca ese sitio: barre la mesa entera, porque el próximo rincón
## así no va a estar donde uno lo busque.
func _prueba_sin_rebote_encerrado() -> void:
	var peor := 0.0
	var donde := Vector2.ZERO
	for tirada in 60:
		var m := _nueva_mesa()
		m.rng.seed = tirada + 1
		m.nueva_bola()
		m.bola.en_carril = false
		m.bola.pos = Vector2(60.0 + 280.0 * (float(tirada % 10) / 9.0), 700.0)
		var ang := -PI * (0.15 + 0.7 * (float(tirada / 10) / 5.0))
		m.bola.vel = Vector2(cos(ang), sin(ang)) * 900.0
		var t := 0.0
		var ancla := m.bola.pos
		var desde := 0.0
		while m.bola.viva and t < 25.0:
			m.avanzar(DT)
			t += DT
			if m.bola.pos.distance_to(ancla) > 45.0 or m.bola.velocidad() < 250.0:
				ancla = m.bola.pos
				desde = t
				continue
			if t - desde > peor:
				peor = t - desde
				donde = ancla
	_comprobar("la bola no se queda encerrada rebotando en ningun rincon",
		peor < 1.5, "%.1f s dando vueltas en 45 px alrededor de (%.0f,%.0f)"
			% [peor, donde.x, donde.y])

## Y la razón de fondo: un slingshot tiene espalda. Empuja hacia el campo, y por
## detrás solo rebota. Si vuelve a empujar por los dos lados, cualquier pasillo
## paralelo a él se convierte en una trampa.
func _prueba_slingshot_tiene_espalda() -> void:
	var m := _nueva_mesa()
	var sling: Colisionador = null
	for c in m.colisionadores:
		if c.tipo == Colisionador.Tipo.SLINGSHOT and c.centro().x < 200.0:
			sling = c
	_comprobar("el slingshot sabe cual es su cara buena",
		sling != null and sling.cara != Vector2.ZERO)
	if sling == null:
		return
	# Y esa cara mira al campo, no a la banda.
	_comprobar("y esa cara mira al centro de la mesa",
		sling.cara.x > 0.0, "cara %s" % str(sling.cara))

	var salida := {}
	for lado in [1.0, -1.0]:
		var m2 := _nueva_mesa()
		m2.nueva_bola()
		m2.bola.en_carril = false
		m2.bola.pos = sling.centro() + sling.cara * lado * 30.0
		m2.bola.vel = -sling.cara * lado * 500.0
		var v := 0.0
		for _i in int(0.25 / DT):
			m2.avanzar(DT)
			v = maxf(v, m2.bola.velocidad())
		salida[lado] = v
	_comprobar("de frente patea la bola",
		float(salida[1.0]) > 800.0, "salio a %.0f px/s de 500" % salida[1.0])
	_comprobar("y por la espalda solo rebota, no patea",
		float(salida[-1.0]) < 600.0, "salio a %.0f px/s de 500" % salida[-1.0])

## Onda, polvo y chispas. Lo que hay que asegurar de un sistema de partículas
## no es que se vea bonito —eso se mira— sino que se apague solo: si algo no
## caduca, una partida larga acaba arrastrando miles de partículas.
func _prueba_impactos() -> void:
	var pi := ParametrosImpacto.new()
	var fx := Impactos.new(pi)
	fx.rng.seed = SEMILLA

	fx.onda(Vector2(200, 900), Color.WHITE)
	fx.polvo(Vector2(200, 900), Vector2.UP, Color.WHITE)
	fx.chispas(Vector2(200, 900), Vector2.UP, Color.WHITE)
	_comprobar("un impacto crea onda, polvo y chispas",
		fx.vivos() == 1 + pi.polvo_cantidad + pi.chispa_cantidad,
		"%d partículas" % fx.vivos())

	# Todo tiene que apagarse solo, y antes de la duración más larga.
	var mas_largo: float = maxf(pi.onda_duracion,
		maxf(pi.polvo_duracion, pi.chispa_duracion))
	for _i in int((mas_largo + 0.2) / DT):
		fx.avanzar(DT)
	_comprobar("y todo se apaga solo", fx.vivos() == 0,
		"quedan %d tras %.2f s" % [fx.vivos(), mas_largo + 0.2])

	# El tope aguanta aunque se dispare sin parar.
	for _i in 200:
		fx.chispas(Vector2(200, 900), Vector2.ZERO, Color.WHITE)
		fx.polvo(Vector2(200, 900), Vector2.ZERO, Color.WHITE)
	_comprobar("el tope de particulas aguanta un aporreo",
		fx.vivos() <= pi.maximo_particulas + 1,
		"%d vivas, tope %d" % [fx.vivos(), pi.maximo_particulas])

	# Dirección omni (Vector2.ZERO) no puede dar NaN al normalizar.
	fx.limpiar()
	fx.chispas(Vector2(200, 900), Vector2.ZERO, Color.WHITE)
	fx.polvo(Vector2(200, 900), Vector2.ZERO, Color.WHITE)
	for _i in 30:
		fx.avanzar(DT)
	var malas := 0
	for lista in [fx._polvo, fx._chispas]:
		for part in lista:
			var pos: Vector2 = part["pos"]
			if not (is_finite(pos.x) and is_finite(pos.y)):
				malas += 1
	_comprobar("sin direccion, las particulas salen en todas y sin NaN",
		malas == 0, "%d posiciones invalidas" % malas)

	# La escala manda en cuántas salen: es el mando para distinguir un roce de
	# una muerte sin tocar los parámetros.
	fx.limpiar()
	fx.chispas(Vector2.ZERO, Vector2.UP, Color.WHITE, 3.0)
	_comprobar("la escala multiplica la cantidad",
		fx.vivos() == pi.chispa_cantidad * 3, "%d chispas" % fx.vivos())

## Los wav los genera sonidos.py y no están en el control de nadie más, así que
## lo que hay que comprobar es que existan todos los que el juego pide: si se
## renombra uno en el script y se olvida regenerar, el juego se queda mudo en
## ese golpe y no da ningún error.
func _prueba_sonido() -> void:
	var faltan: Array[String] = []
	var vacios: Array[String] = []
	for nombre in NodoSonido.AJUSTES:
		var ruta: String = NodoSonido.RUTA % nombre
		if not ResourceLoader.exists(ruta):
			faltan.append(str(nombre))
			continue
		var stream := load(ruta) as AudioStream
		if stream == null or stream.get_length() <= 0.005:
			vacios.append(str(nombre))
	_comprobar("esta el wav de todos los sonidos que pide el juego",
		faltan.is_empty() and NodoSonido.AJUSTES.size() >= 10,
		"faltan %s (hay %d ajustes)" % [str(faltan), NodoSonido.AJUSTES.size()])
	_comprobar("y ninguno esta vacio", vacios.is_empty(), str(vacios))

	# Los que suenan en racimo necesitan desafine, o el oído los junta en un
	# zumbido. Los que suenan una vez van clavados a propósito.
	var repetidos := ["bumper", "target", "flipper"]
	var sin_variacion: Array[String] = []
	for nombre in repetidos:
		if float((NodoSonido.AJUSTES[nombre] as Dictionary)["tono"]) <= 0.0:
			sin_variacion.append(nombre)
	_comprobar("los golpes que se repiten llevan variacion de tono",
		sin_variacion.is_empty(), str(sin_variacion))

	# El arpegio del multiplicador tiene que durar bastante más que un golpe:
	# si dura lo mismo, en mitad del racimo pasa por un bumper más y subir de
	# tramo no se nota. Y va fuera de la rueda de voces para que nada lo pise.
	var combo := load(NodoSonido.RUTA % "combo") as AudioStream
	var bumper := load(NodoSonido.RUTA % "bumper") as AudioStream
	_comprobar("el arpegio del multiplicador dura mas que un golpe",
		combo.get_length() > 3.0 * bumper.get_length(),
		"combo %.3f s, bumper %.3f s" % [combo.get_length(), bumper.get_length()])
	_comprobar("y suena mas fuerte que los golpes que lo rodean",
		float((NodoSonido.AJUSTES["combo"] as Dictionary)["db"])
			> float((NodoSonido.AJUSTES["bumper"] as Dictionary)["db"]))
	_comprobar("el multiplicador tiene reproductor propio",
		NodoSonido.PROPIOS.has("combo"), str(NodoSonido.PROPIOS))

	# Y cada tramo suena más agudo que el anterior, con separación suficiente
	# para leerse como otra nota y no como el mismo sonido desafinado.
	var tonos: Array = VistaMesa.TONO_COMBO
	var asciende := true
	for i in range(1, tonos.size()):
		if float(tonos[i]) < float(tonos[i - 1]) * 1.08:
			asciende = false
	_comprobar("cada tramo del multiplicador suena mas agudo que el anterior",
		asciende and tonos.size() >= 3, str(tonos))

## El criterio de salida de la fase 1: la bola sube por una rampa, desaparece
## de vista, y sabes dónde va a salir. Aquí se comprueba que sale SIEMPRE por
## el mismo sitio, que tarda lo que tiene que tardar, y que no hay forma de que
## se quede a medias.
func _prueba_rampas() -> void:
	var m := _nueva_mesa()
	_comprobar("hay tres recorridos y un platillo",
		m.rampas.size() == 3 and m.platillos.size() == 1,
		"%d rampas, %d platillos" % [m.rampas.size(), m.platillos.size()])
	var r: Rampa = m.rampas[0]
	_comprobar("la orbita llega a la zona alta",
		r.punto_en(r.largo * 0.5).y < 320.0,
		"lo mas alto que llega es y=%.0f" % r.punto_en(r.largo * 0.5).y)

	# Entra por la boca izquierda y sale por la derecha, y al reves. Siempre.
	for sentido in [1, -1]:
		var boca := r.boca(sentido)
		var salida := r.boca(-sentido)
		var m2 := _nueva_mesa()
		m2.nueva_bola()
		m2.bola.en_carril = false
		m2.bola.pos = boca
		m2.bola.vel = Vector2(0, -700)
		var salidas := []
		m2.rampa_salida.connect(func(pt: Vector2, _i: int) -> void: salidas.append(pt))
		var pasos := 0
		for _i in int(8.0 / DT):
			m2.avanzar(DT)
			pasos += 1
			if not salidas.is_empty():
				break
		_comprobar("entrando por un lado se sale por el otro (sentido %d)" % sentido,
			not salidas.is_empty()
			and (salidas[0] as Vector2).distance_to(salida) < 4.0,
			"salio en %s, se esperaba %s" % [str(salidas), str(salida)])
		var segundos := float(pasos) * DT
		_comprobar("y el viaje dura lo que dice la curva (sentido %d)" % sentido,
			absf(segundos - r.largo / 700.0) < 0.25,
			"tardo %.2f s, la curva mide %.0f px a 700 px/s" % [segundos, r.largo])

	# Los tres recorridos tienen que devolver la bola a sitios DISTINTOS, y sus
	# bocas tienen que estar separadas: si se solapan, no puedes elegir a cuál
	# tiras y dejan de ser tres tiros para ser uno con suerte.
	var salidas_finales: Array[Vector2] = []
	var bocas: Array[Vector2] = []
	for ra in m.rampas:
		salidas_finales.append(ra.punto_en(ra.largo))
		bocas.append(ra.boca(1))
		if ra.bidireccional:
			bocas.append(ra.boca(-1))
	var juntas: Array[String] = []
	for i in salidas_finales.size():
		for j in range(i + 1, salidas_finales.size()):
			if salidas_finales[i].distance_to(salidas_finales[j]) < 60.0:
				juntas.append("%s y %s" % [str(salidas_finales[i]), str(salidas_finales[j])])
	_comprobar("los tres recorridos sueltan la bola en sitios distintos",
		juntas.is_empty(), str(juntas))

	var pegadas: Array[String] = []
	for i in bocas.size():
		for j in range(i + 1, bocas.size()):
			if bocas[i].distance_to(bocas[j]) < m.p.rampa_entrada_radio * 2.0:
				pegadas.append("%s y %s" % [str(bocas[i]), str(bocas[j])])
	_comprobar("y sus bocas no se pisan entre ellas",
		pegadas.is_empty(), str(pegadas))

	# Ninguna boca ni salida puede caer dentro de un colisionador, o la bola
	# aparecería empotrada y el solver la escupiría a cualquier sitio.
	var empotradas: Array[String] = []
	for punto in bocas + salidas_finales:
		for c in m.colisionadores:
			if c.punto_mas_cercano(punto).distance_to(punto) < c.radio + m.p.radio_bola:
				empotradas.append(str(punto))
				break
	_comprobar("ninguna boca ni salida cae dentro de un colisionador",
		empotradas.is_empty(), str(empotradas))

	# Al menos un carril de retorno tiene que dejar la bola ABAJO, al alcance de
	# la pala. El bug que esto blinda: el cañón acababa en (200,690), o sea
	# dentro del racimo y arriba del todo, así que entre él y la órbita dos de
	# los tres recorridos te devolvían la bola a la mitad de arriba. Como el
	# cañón es el que más daño paga, el bucle se alimentaba solo y el enemigo
	# moría sin que las palas tocaran la bola. Daniel lo describió jugando.
	var abajo := 0
	for ra in m.rampas:
		if not ra.bidireccional and ra.punto_en(ra.largo).y > 950.0:
			abajo += 1
	_comprobar("los carriles de retorno dejan la bola al alcance de la pala",
		abajo >= 2, "solo %d de los carriles sueltan por debajo de y=950" % abajo)

	# Una bola lenta no engancha: rebota de largo.
	var m3 := _nueva_mesa()
	m3.nueva_bola()
	m3.bola.en_carril = false
	m3.bola.pos = r.boca(1)
	m3.bola.vel = Vector2(0, -(m3.p.rampa_velocidad_minima - 80.0))
	m3.avanzar(DT)
	_comprobar("una bola lenta no engancha en la orbita", m3.bola.rampa < 0)

	# El platillo captura, espera y escupe.
	var m4 := _nueva_mesa()
	m4.nueva_bola()
	m4.bola.en_carril = false
	m4.bola.pos = (m4.platillos[0] as Platillo).centro
	m4.bola.vel = Vector2(0, 60)
	var capturas := [0]
	var expulsiones := [0]
	m4.platillo_capturado.connect(func(_pt: Vector2, _i: int) -> void: capturas[0] += 1)
	m4.platillo_expulsado.connect(func(_pt: Vector2, _i: int) -> void: expulsiones[0] += 1)
	# La velocidad hay que medirla EN el aviso: un par de fotogramas después la
	# bola ya ha rebotado en un bumper y marca 1486.
	# La lambda captura la BOLA, no la mesa: capturando `m4` se cierra un ciclo
	# (mesa -> señal -> lambda -> mesa) y la mesa no se libera nunca.
	var salio_a := [0.0]
	var bola4 := m4.bola
	m4.platillo_expulsado.connect(func(_pt: Vector2, _i: int) -> void:
		salio_a[0] = bola4.velocidad())
	m4.avanzar(DT)
	_comprobar("el platillo captura la bola",
		capturas[0] == 1 and m4.bola.platillo >= 0 and m4.bola.velocidad() == 0.0)
	for _i in int((m4.p.platillo_tiempo + 0.1) / DT):
		m4.avanzar(DT)
	_comprobar("y la escupe tras la pausa con impulso fijo",
		expulsiones[0] == 1 and m4.bola.platillo < 0
		and absf(salio_a[0] - m4.p.platillo_impulso) < 1.0,
		"salio a %.0f px/s" % salio_a[0])

	# La zona alta es inalcanzable, pero NO por el tope de subida: la bola sube
	# 643 px y el desplazamiento son 600, o sea que por ahí llegaría. Lo que la
	# sella es el arco, que es techo macizo de la zona baja. Se comprueba
	# jugando, que es la única forma de estar seguro.
	var mas_arriba := INF
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA
	for _i in 30:
		var m6 := _nueva_mesa()
		m6.nueva_bola()
		m6.bola.en_carril = false
		m6.bola.pos = Vector2(rng.randf_range(40, 340), rng.randf_range(760, 1050))
		var ang := rng.randf_range(0.0, TAU)
		m6.bola.vel = Vector2(cos(ang), sin(ang)) * rng.randf_range(800.0, 1500.0)
		for _j in int(20.0 / DT):
			if not m6.bola.viva:
				break
			m6.avanzar(DT)
			if m6.bola.viva and m6.bola.libre():
				mas_arriba = minf(mas_arriba, m6.bola.pos.y)
	_comprobar("el arco sella la zona alta: sin la orbita no se sube",
		mas_arriba > Mesa.DESPLAZAMIENTO + 55.0,
		"una bola suelta llego a y=%.0f" % mas_arriba)

	# Y el lanzamiento a tope sí engancha: es el tiro de habilidad.
	var m5 := _nueva_mesa()
	m5.nueva_bola()
	m5.cargar_lanzador(1.0)
	m5.soltar_lanzador()
	var engancho := false
	for _i in int(3.0 / DT):
		m5.avanzar(DT)
		if m5.bola.rampa >= 0:
			engancho = true
			break
	_comprobar("un lanzamiento a tope engancha la orbita", engancho)

## Las cuatro reglas de la cámara de PLAN.md, una por una y encima jugando.
func _prueba_camara() -> void:
	var cp := ParametrosCamara.new()
	var camara := CamaraMesa.new(cp, Mesa.ALTO, Mesa.ANCHO * 0.5)

	# REGLA 1: con la bola cayendo, la cámara mira por DEBAJO de ella.
	var cayendo := camara.objetivo(400.0, 800.0, true)
	var subiendo := camara.objetivo(400.0, -800.0, true)
	_comprobar("regla 1: cayendo, la camara se adelanta por debajo de la bola",
		cayendo > 400.0 and cayendo > subiendo,
		"cayendo %.0f, subiendo %.0f" % [cayendo, subiendo])

	# REGLA 2: por debajo de la línea de seguridad, anclada abajo.
	var y_baja := Mesa.ALTO - cp.margen_ancla + 10.0
	_comprobar("regla 2: bajo la linea de seguridad la camara se ancla abajo",
		is_equal_approx(camara.objetivo(y_baja, 400.0, true), camara.limite_abajo()),
		"objetivo %.0f, ancla %.0f" % [camara.objetivo(y_baja, 400.0, true),
			camara.limite_abajo()])
	_comprobar("y con los flippers a la vista",
		camara.limite_abajo() + cp.alto_visible * 0.5 >= Mesa.ALTO - 1.0)

	# REGLA 4: un temblorcito de la bola no mueve la cámara.
	camara.y_actual = 300.0
	camara.avanzar(DT, 300.0 - cp.adelanto + cp.zona_muerta * 0.5, 500.0, true)
	_comprobar("regla 4: dentro de la zona muerta la camara no se mueve",
		is_equal_approx(camara.y_actual, 300.0), "se movio a %.2f" % camara.y_actual)

	# REGLA 3 y garantía de la 1, jugando de verdad.
	var fraccionarias := 0
	var fuera := 0
	var m := _nueva_mesa()
	m.nueva_bola()
	m.cargar_lanzador(1.0)
	m.soltar_lanzador()
	camara.y_actual = camara.limite_abajo()
	for _i in int(30.0 / DT):
		if not m.bola.viva:
			break
		m.avanzar(DT)
		camara.avanzar(DT, m.bola.pos.y, m.bola.vel.y, m.bola.viva)
		if camara.position != camara.position.round():
			fraccionarias += 1
		var vista := camara.rect_visible()
		if m.bola.viva and m.bola.pos.y < Mesa.ALTO - 20.0 \
				and (m.bola.pos.y < vista.position.y
					or m.bola.pos.y > vista.position.y + vista.size.y):
			fuera += 1
	_comprobar("regla 3: la camara siempre en pixeles enteros",
		fraccionarias == 0, "%d fotogramas a medio pixel" % fraccionarias)
	_comprobar("regla 1: la bola nunca se sale de la pantalla",
		fuera == 0, "%d fotogramas con la bola fuera" % fuera)

	# Lo que hay dibujado encima de la mesa por arriba (antes 58 px de franja de
	# HUD, ahora los 24 del marco de la ventana con su barra de título): en lo
	# alto de la órbita la bola se metía detrás, y el tiro más largo de la mesa
	# era el único que no se veía. Se recorren las tres rampas midiéndolo.
	var tapada := 0
	var mas_arriba_pantalla := INF
	for indice in 3:
		var m2 := _nueva_mesa()
		m2.nueva_bola()
		m2.bola.en_carril = false
		var ra: Rampa = m2.rampas[indice]
		m2.bola.pos = ra.boca(1)
		m2.bola.vel = Vector2(0, -720)
		var cam2 := CamaraMesa.new(cp, Mesa.ALTO, Mesa.ANCHO * 0.5)
		cam2.y_actual = cam2.limite_abajo()
		for _i in int(6.0 / DT):
			m2.avanzar(DT)
			cam2.avanzar(DT, m2.bola.pos.y, m2.bola.vel.y, m2.bola.viva)
			if m2.bola.rampa != indice:
				continue
			var en_pantalla := m2.bola.pos.y - cam2.y_actual + cp.alto_visible * 0.5
			mas_arriba_pantalla = minf(mas_arriba_pantalla, en_pantalla)
			if en_pantalla < cp.alto_franja_hud:
				tapada += 1
		cam2.free()
	_comprobar("la bola nunca se esconde tras la franja del HUD",
		tapada == 0, "%d fotogramas tapada; lo mas alto fue y=%.0f de pantalla"
			% [tapada, mas_arriba_pantalla])

	# Y nunca se enseña fuera de la mesa.
	_comprobar("la camara no se sale de la mesa",
		camara.limite_arriba() >= cp.alto_visible * 0.5
		and camara.limite_abajo() <= Mesa.ALTO - cp.alto_visible * 0.5 + 0.01)
	camara.free()

func _prueba_giradores() -> void:
	var m := _nueva_mesa()
	_comprobar("hay un girador en cada carril de retorno",
		m.giradores.size() == 2, "%d giradores" % m.giradores.size())

	# Hay que soltarla BAJANDO POR EL CARRIL: el carril de retorno izquierdo va
	# en diagonal, y a plomo desde arriba la bola cae fuera, sobre el slingshot.
	var carril := (Vector2(99, 1184) - Vector2(20, 1080)).normalized()

	# Pasada rápida: un aviso, no uno por subpaso.
	m.nueva_bola()
	m.bola.en_carril = false
	m.bola.pos = m.giradores[0] - carril * 40.0
	m.bola.vel = carril * 400.0
	var avisos := [0]
	m.girador_girado.connect(func(_pt: Vector2, _i: int, _f: float) -> void:
		avisos[0] += 1)
	# Se corta en cuanto la bola ha pasado de largo: si se deja correr, rebota
	# en el poste, vuelve a subir y lo cruza otra vez, y ese aviso es legítimo.
	for _i in int(0.5 / DT):
		m.avanzar(DT)
		if (m.bola.pos - m.giradores[0]).dot(carril) > 20.0:
			break
	_comprobar("una pasada por el girador da un solo aviso",
		avisos[0] == 1, "%d avisos" % avisos[0])

	# Y no colisiona. Dos cosas: que no exista colisionador donde está, y que la
	# bola pase POR DENTRO en vez de rodearlo.
	# (No vale comprobar que no se desvía: bajando por el carril la bola se
	# apoya en la pared, que es el suelo del carril, y eso sí la desvía.)
	var sobre_girador: Array[String] = []
	for c in m.colisionadores:
		for g in m.giradores:
			if c.punto_mas_cercano(g).distance_to(g) < c.radio + m.p.girador_radio:
				sobre_girador.append(str(g))
	_comprobar("no hay ningun colisionador encima de un girador",
		sobre_girador.is_empty(), str(sobre_girador))

	var m2 := _nueva_mesa()
	m2.nueva_bola()
	m2.bola.en_carril = false
	m2.bola.pos = m2.giradores[0] - carril * 40.0
	m2.bola.vel = carril * 400.0
	var mas_cerca := INF
	for _i in int(0.5 / DT):
		m2.avanzar(DT)
		mas_cerca = minf(mas_cerca, m2.bola.pos.distance_to(m2.giradores[0]))
		if (m2.bola.pos - m2.giradores[0]).dot(carril) > 20.0:
			break
	_comprobar("la bola atraviesa el girador por dentro",
		mas_cerca < m2.p.girador_radio
		and m2.bola.pos.y > (m2.giradores[0] as Vector2).y,
		"paso a %.1f px del centro" % mas_cerca)

## Ocho escorzos pregenerados, no rotación continua. Lo que hay que comprobar
## es que salen ocho, que todos miden lo mismo y que el escorzo es de verdad.
func _prueba_animacion() -> void:
	var anim := ParametrosAnimacion.new()
	var fotogramas := Girador.generar(
		load("res://assets/mesa/girador.png"), anim.girador_fotogramas, 32)
	_comprobar("el girador tiene ocho fotogramas pregenerados",
		fotogramas.size() == anim.girador_fotogramas,
		"%d fotogramas" % fotogramas.size())

	var alturas: Array[int] = []
	var tamanos_mal: Array[String] = []
	for f in fotogramas:
		if f.get_width() != 32 or f.get_height() != 32:
			tamanos_mal.append("%dx%d" % [f.get_width(), f.get_height()])
		alturas.append(f.get_image().get_used_rect().size.y)
	_comprobar("todos los fotogramas del girador miden lo mismo",
		tamanos_mal.is_empty(), str(tamanos_mal))
	_comprobar("el girador escorza: de frente es alto y de canto una raya",
		alturas[0] > alturas[anim.girador_fotogramas / 2] * 3,
		"de frente %d px, de canto %d px" % [alturas[0], alturas[anim.girador_fotogramas / 2]])
	_comprobar("y ningun fotograma desaparece del todo",
		alturas.min() >= 1, "el mas fino mide %d px" % alturas.min())

	# Hitstop: solo en los golpes fuertes, o serían tirones todo el rato.
	_comprobar("un impacto fuerte congela %.0f ms" % (anim.hitstop * 1000.0),
		is_equal_approx(anim.congelacion(anim.hitstop_fuerza_minima), anim.hitstop),
		"congelo %.3f s" % anim.congelacion(anim.hitstop_fuerza_minima))
	_comprobar("un roce no congela nada",
		anim.congelacion(anim.hitstop_fuerza_minima - 1.0) == 0.0)

	# Sacudida: siempre en píxeles enteros y dentro del tope.
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA
	var no_enteros := 0
	var pasados := 0
	for _i in 500:
		var d := anim.desplazamiento_sacudida(anim.sacudida_maxima * 2.0, rng)
		if d != d.round():
			no_enteros += 1
		if absf(d.x) > anim.sacudida_maxima or absf(d.y) > anim.sacudida_maxima:
			pasados += 1
	_comprobar("la sacudida siempre cae en pixeles enteros",
		no_enteros == 0, "%d de 500 a medio pixel" % no_enteros)
	_comprobar("y nunca se pasa del tope",
		pasados == 0, "%d de 500 se pasaron" % pasados)

	_prueba_respiracion(anim)

## La respiración va en pasos de píxel entero y con el pivote en los pies.
func _prueba_respiracion(anim: ParametrosAnimacion) -> void:
	var nodo := NodoEnemigo.new(anim)
	nodo.suelo = Vector2(200, 158)
	nodo.configurar(load("res://assets/enemigos/esqueleto.png"), false)

	var no_enteros: Array[String] = []
	var pies: Array[float] = []
	var altos := {}
	for _i in int(anim.respiracion_periodo * 2.0 / DT):
		nodo._process(DT)
		var r := nodo.rect_dibujo()
		if r.position != r.position.round() or r.size != r.size.round():
			no_enteros.append(str(r))
		pies.append(r.position.y + r.size.y)
		altos[int(r.size.y)] = true
	_comprobar("la respiracion cae siempre en pixeles enteros",
		no_enteros.is_empty(), str(no_enteros.slice(0, 3)))
	_comprobar("los pies no se mueven al respirar (el pivote esta abajo)",
		pies.min() == 158.0 and pies.max() == 158.0,
		"pies entre %.1f y %.1f" % [pies.min(), pies.max()])
	_comprobar("y el sprite cambia de alto de verdad",
		altos.size() >= 3, "%d alturas distintas" % altos.size())

	# Los que flotan no se apoyan en el suelo.
	var flotante := NodoEnemigo.new(anim)
	flotante.suelo = Vector2(200, 158)
	flotante.configurar(load("res://assets/enemigos/calavera_llameante.png"), true)
	var pies_flota: Array[float] = []
	for _i in int(anim.flotante_periodo * 2.0 / DT):
		flotante._process(DT)
		var r := flotante.rect_dibujo()
		pies_flota.append(r.position.y + r.size.y)
	_comprobar("el que flota se despega del suelo y se mueve",
		pies_flota.max() < 158.0 and pies_flota.max() > pies_flota.min(),
		"pies entre %.0f y %.0f" % [pies_flota.min(), pies_flota.max()])
	nodo.free()
	flotante.free()

## La suite solo tocaba sim/, así que un error de sintaxis en la vista pasaba
## desapercibido y solo se veía al abrir el juego. Esto la carga y la arranca.
func _prueba_escena_principal() -> void:
	var ruta := str(ProjectSettings.get_setting("application/run/main_scene"))
	var escena: PackedScene = load(ruta)
	_comprobar("la escena principal carga", escena != null, ruta)
	if escena == null:
		return
	var nodo := escena.instantiate()
	var guion := nodo.get_script() as GDScript
	_comprobar("la vista tiene guion y compila",
		guion != null and guion.can_instantiate(),
		"un error de sintaxis en render/ se ve aqui, no al abrir el juego")
	nodo.free()

func _prueba_lanzador() -> void:
	var m := _nueva_mesa()
	m.nueva_bola()
	_comprobar("la bola nueva nace en el carril", m.bola.en_carril)
	m.cargar_lanzador(1.0)
	m.soltar_lanzador()
	var salio := false
	for _i in int(4.0 / DT):
		m.avanzar(DT)
		if not m.bola.en_carril:
			salio = true
			break
	_comprobar("el lanzador saca la bola del carril al campo", salio,
		"la bola sigue en el carril, y=%.0f" % m.bola.pos.y)

	# La puerta antirretorno no debe dejar la bola parada encima de la repisa:
	# está inclinada para que ruede hacia el campo. Si atrapara la bola, esto
	# no drenaría nunca.
	var m2 := _nueva_mesa()
	m2.nueva_bola()
	m2.cargar_lanzador(1.0)
	m2.soltar_lanzador()
	var r := _simular(m2, 45.0)
	_comprobar("una bola lanzada a tope acaba drenando", r["drenada"],
		"se quedo en %s" % str(r["pos"]))
	_comprobar("una bola lanzada a tope no se sale de la mesa",
		r["escapes"] == 0, "%d fotogramas fuera" % r["escapes"])

## Las reliquias (DISEÑO.md §10 y §8).
##
## LO QUE SE COMPRUEBA AQUÍ NO ES QUE LOS NÚMEROS SEAN BUENOS —eso lo mide
## `tests/medir_reliquias.gd`, que no falla nunca— sino tres cosas que sí son
## condiciones y no juicios:
##
##   1. que el catálogo cumpla el reparto que pide el diseño
##   2. que una bolsa VACÍA sea exactamente neutra, o sea que un combate sin
##      reliquias siga siendo el combate de antes y las medidas viejas valgan
##   3. que ninguna reliquia tenga un efecto MUERTO: una clave escrita en el
##      JSON que ningún sitio del código lea es una reliquia que no hace nada, y
##      eso no da error, solo miente
func _prueba_reliquias() -> void:
	var catalogo := CatalogoReliquias.cargar()
	_comprobar("el catalogo de reliquias carga", catalogo.size() >= 45,
		"hay %d" % catalogo.size())

	var ids := {}
	var por_eje := {}
	var ganchos := {}
	var sin_texto: Array[String] = []
	for r in catalogo:
		ids[r.id] = int(ids.get(r.id, 0)) + 1
		por_eje[r.eje] = int(por_eje.get(r.eje, 0)) + 1
		ganchos[r.gancho] = true
		if r.texto == "" or r.efectos.is_empty():
			sin_texto.append(r.id)
	_comprobar("no hay dos reliquias con el mismo id", ids.size() == catalogo.size())
	_comprobar("todas dicen lo que hacen y hacen algo", sin_texto.is_empty(),
		str(sin_texto))

	# DISEÑO.md §8: los cinco ejes, repartidos por igual. Es lo que impide que
	# sean cuarenta y cinco variantes de "+2 de daño".
	var reparto_ok := por_eje.size() == Reliquia.NOMBRE_EJE.size()
	var por_lado := catalogo.size() / maxi(Reliquia.NOMBRE_EJE.size(), 1)
	for eje in por_eje:
		if int(por_eje[eje]) != por_lado:
			reparto_ok = false
	_comprobar("los cinco ejes tienen las mismas reliquias cada uno", reparto_ok,
		str(por_eje))
	_comprobar("y cubren al menos seis ganchos distintos", ganchos.size() >= 6,
		"%d ganchos" % ganchos.size())

	# El pool tiene que ser MAYOR que lo que se ve en un run, o dos partidas
	# enseñan lo mismo. Con 3 por combate y ~12 combates se ven ~36.
	var pr := ParametrosRun.new()
	var vistas := pr.actos * (pr.filas_por_acto + 1)
	_comprobar("el cajon es mucho mayor que lo que cabe en un run",
		catalogo.size() > vistas * 2,
		"%d reliquias contra %d combates" % [catalogo.size(), vistas])

	_prueba_la_vida_no_se_pasa()
	_prueba_reloj_por_enemigo()
	_prueba_bolsa_vacia_es_neutra()
	_prueba_ningun_efecto_muerto(catalogo)
	_prueba_condiciones(catalogo)
	_prueba_iconos(catalogo)
	_prueba_efectos_de_reliquia()
	_prueba_run_con_reliquias(catalogo)

## Las condiciones son la parte que puede fallar EN SILENCIO: un `cuando` mal
## escrito no da error, solo apaga la reliquia para siempre. Y una condición con
## umbral 0 en una comparación "mayor o igual" está siempre encendida, que es la
## misma avería por el otro lado.
func _prueba_condiciones(catalogo: Array[Reliquia]) -> void:
	var raras: Array[String] = []
	var sin_umbral: Array[String] = []
	const PIDEN_UMBRAL := ["vida_baja", "vida_alta", "combo_alto", "reloj_cargado",
		"reloj_frio", "enemigo_tocado", "enemigo_intacto"]
	for r in catalogo:
		if r.cuando == "":
			continue
		if not BolsaReliquias.CONDICIONES.has(r.cuando):
			raras.append("%s: %s" % [r.id, r.cuando])
		elif PIDEN_UMBRAL.has(r.cuando) and r.umbral <= 0.0:
			sin_umbral.append(r.id)
	_comprobar("ninguna condicion esta mal escrita", raras.is_empty(), str(raras))
	_comprobar("toda condicion que compara trae su umbral", sin_umbral.is_empty(),
		str(sin_umbral))

	# Y que de verdad enciendan y apaguen. Se prueba con la bolsa a pelo, sin
	# combate: lo que puede romperse aquí es la comparación, no el combate.
	var b := BolsaReliquias.new()
	var baja := Reliquia.new({"id": "x", "cuando": "vida_baja", "umbral": 0.3,
		"efectos": {"factor_dano_global": 2.0}})
	b.anadir(baja)
	b.contexto = {"vida": 0.9}
	_comprobar("una reliquia condicional esta apagada si no se cumple",
		is_equal_approx(b.factor("factor_dano_global"), 1.0))
	b.contexto = {"vida": 0.2}
	_comprobar("y encendida cuando se cumple",
		is_equal_approx(b.factor("factor_dano_global"), 2.0))
	b.contexto = {}
	_comprobar("sin contexto se da por apagada, que es el lado seguro",
		is_equal_approx(b.factor("factor_dano_global"), 1.0))

## Los iconos que se declaran tienen que existir en los dos tamaños. Una ruta
## mal escrita deja una tarjeta sin dibujo y no da error: otra vez lo mismo.
func _prueba_iconos(catalogo: Array[Reliquia]) -> void:
	var faltan: Array[String] = []
	var con_icono := 0
	for r in catalogo:
		if r.icono == "":
			continue
		con_icono += 1
		for lado in [64, 32]:
			if not ResourceLoader.exists(r.ruta_icono(lado)):
				faltan.append(r.ruta_icono(lado))
	_comprobar("todos los iconos declarados existen", faltan.is_empty(), str(faltan))
	_comprobar("y hay arte para las 18 que lo tienen asignado", con_icono == 18,
		"%d con icono" % con_icono)

## LA VIDA NO SE PASA DE LA MÁXIMA. Nunca, por ninguna vía.
##
## Salió jugando: "215/180". El fallo no era la curación —esa estaba topada— era
## que el HUD dividía por `p.vida_jugador`, o sea la vida de partida, sin contar
## lo que suman las reliquias. El dato estaba bien y el denominador no, que es
## la avería de siempre con otra cara. Se comprueban las dos vías: la que cura
## dentro del combate y la que sube el techo a mitad de run.
func _prueba_la_vida_no_se_pasa() -> void:
	var purga := _combate_con(["valvula_de_purga"])
	for _i in 40:
		_recorrido(purga, Rampa.Premio.DANO)
	_comprobar("curarse en combate no pasa del maximo",
		purga.vida_jugador <= purga.vida_maxima(),
		"%d/%d" % [purga.vida_jugador, purga.vida_maxima()])

	# Y la vida máxima que enseña el combate tiene que ser la MISMA que lleva el
	# run: si se separan, una de las dos pantallas miente.
	var enemigos := CatalogoEnemigos.cargar()
	var chapa := CatalogoReliquias.por_id("chapa_remachada")
	var memoria := CatalogoReliquias.por_id("memoria_reservada")
	var r := Run.new(ParametrosRun.new(), ParametrosCombate.new(), enemigos, 5)
	r.bolsa.anadir(chapa)
	r.bolsa.anadir(memoria)
	r.elegir(r.opciones()[0])
	r.resolver_combate(true, r.vida)
	var c := Combate.new(ParametrosCombate.new())
	c.bolsa = r.bolsa
	c.iniciar(Enemigo.new({"nombre": "Saco", "vida": 1000, "ataque": 1}), r.vida)
	_comprobar("el maximo del combate y el del run son el mismo numero",
		c.vida_maxima() == r.vida_maxima,
		"combate %d, run %d" % [c.vida_maxima(), r.vida_maxima])
	_comprobar("y la vida del run nunca lo pasa", r.vida <= r.vida_maxima,
		"%d/%d" % [r.vida, r.vida_maxima])

## Cada enemigo tiene su reloj. Es lo que separa cuánto DURA un combate de
## cuánto APRIETA, y sin eso los combates de dos a cinco minutos no cuadran:
## el coste crece con el tiempo, así que con un reloj único todos acababan
## costando lo mismo en proporción.
func _prueba_reloj_por_enemigo() -> void:
	var p := ParametrosCombate.new()
	var lento := Combate.new(p)
	lento.iniciar(Enemigo.new({"nombre": "Lento", "vida": 100000, "ataque": 5,
		"reloj": 30.0}))
	_comprobar("un enemigo con reloj propio lo usa",
		is_equal_approx(lento.reloj_carga(), 30.0)
			and lento.reloj_restante() > p.reloj_carga,
		"carga %.1f" % lento.reloj_carga())

	var sin_reloj := Combate.new(ParametrosCombate.new())
	sin_reloj.iniciar(Enemigo.new({"nombre": "Normal", "vida": 100000, "ataque": 5}))
	_comprobar("y sin reloj propio cae en el del parametro",
		is_equal_approx(sin_reloj.reloj_carga(), sin_reloj.p.reloj_carga))

	# Todos los del catálogo tienen que traerlo: uno sin él se colaría con el
	# reloj de reserva y duraría lo mismo pero apretando el doble.
	var faltan: Array[String] = []
	for datos in CatalogoEnemigos.cargar():
		if float((datos as Dictionary).get("reloj", 0.0)) <= 0.0:
			faltan.append(str((datos as Dictionary).get("id", "?")))
	_comprobar("todos los enemigos del catalogo traen su reloj",
		faltan.is_empty(), str(faltan))

## Una bolsa vacía tiene que devolver el neutro de cada tipo. Si no, TODO el
## balance medido en la sesión anterior deja de valer sin avisar.
func _prueba_bolsa_vacia_es_neutra() -> void:
	var b := BolsaReliquias.new()
	_comprobar("una bolsa vacia suma cero", is_equal_approx(b.suma("lo_que_sea"), 0.0))
	_comprobar("una bolsa vacia multiplica por uno",
		is_equal_approx(b.factor("lo_que_sea"), 1.0))
	_comprobar("una bolsa vacia no levanta ninguna bandera",
		not b.bandera("lo_que_sea"))
	_comprobar("y no gasta azar si nadie le da probabilidad",
		not b.azar("suma_prob_critico"))

	# Y el combate con ella tiene que pegar lo de siempre.
	var c := Combate.new()
	c.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000, "ataque": 1}))
	_en_juego(c)
	var vida := c.enemigo.vida
	c.mesa.target_abatido.emit(Vector2(200, 800), 0)
	_comprobar("sin reliquias un target pega exactamente su dano base",
		vida - c.enemigo.vida == c.p.dano_target,
		"pego %d, base %d" % [vida - c.enemigo.vida, c.p.dano_target])
	_comprobar("y la vida maxima es la de los parametros",
		c.vida_maxima() == c.p.vida_jugador)

## Ningún efecto muerto: cada clave del JSON tiene que leerla alguien.
##
## Esta es la prueba que de verdad protege el sistema. Un `factor_dano_canom`
## mal escrito en el JSON no da error, no rompe nada y deja una reliquia que no
## hace absolutamente nada: el jugador la coge, ve que "no se nota" y el fallo
## se diagnostica como balance. Ya pasó con el platillo, en otra forma.
func _prueba_ningun_efecto_muerto(catalogo: Array[Reliquia]) -> void:
	var codigo := ""
	for archivo in ["combate.gd", "run.gd", "bolsa_reliquias.gd"]:
		codigo += FileAccess.get_file_as_string("res://sim/" + archivo)
	var muertos: Array[String] = []
	for r in catalogo:
		for clave in r.efectos:
			var base := str(clave).trim_suffix(BolsaReliquias.SUFIJO_VICTORIA)
			if not codigo.contains('"%s"' % base):
				muertos.append("%s: %s" % [r.id, str(clave)])
	_comprobar("ninguna reliquia tiene un efecto que nadie lee",
		muertos.is_empty(), str(muertos))

	# Y al revés: los prefijos deciden cómo se acumula, así que una clave con un
	# prefijo raro se acumularía de una forma que quien la escribió no eligió.
	var raras: Array[String] = []
	for r in catalogo:
		for clave in r.efectos:
			var c := str(clave)
			if not (c.begins_with("suma_") or c.begins_with("factor_")
					or c.begins_with("bandera_")):
				raras.append("%s: %s" % [r.id, c])
	_comprobar("todas las claves llevan un prefijo conocido", raras.is_empty(),
		str(raras))

## Un combate con las reliquias puestas. Se comparan contra el mismo combate sin
## ellas, y todo se escribe contra los PARÁMETROS: un número a mano aquí mediría
## la escala de daño, no la reliquia.
func _combate_con(ids: Array) -> Combate:
	var c := Combate.new()
	for el_id in ids:
		var r := CatalogoReliquias.por_id(str(el_id))
		if r != null:
			c.bolsa.anadir(r)
	c.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000000, "ataque": 20}))
	_en_juego(c)
	return c

## Daño de un evento suelto, con la bolsa que se le ponga.
func _dano_de(c: Combate, evento: String) -> int:
	var vida := c.enemigo.vida
	var punto := Vector2(200, 800)
	match evento:
		"target": c.mesa.target_abatido.emit(punto, 0)
		"banco": c.mesa.banco_completado.emit(punto, 0)
		"bumper": c.mesa.bumper_golpeado.emit(punto, 500.0)
		"canon":
			for i in c.mesa.rampas.size():
				if (c.mesa.rampas[i] as Rampa).premio == Rampa.Premio.DANO_FUERTE:
					c.mesa.rampa_salida.emit(punto, i)
					break
	return vida - c.enemigo.vida

func _prueba_efectos_de_reliquia() -> void:
	# El cañón, que es el eje de golpe único: la reliquia toca ESE tiro y no los
	# demás. Si tocara todo sería un "+ daño" con nombre bonito.
	var pelado := _combate_con([])
	var canon := _combate_con(["culata_reforzada"])
	_comprobar("la culata sube el canon y solo el canon",
		_dano_de(canon, "canon") > _dano_de(pelado, "canon")
			and _dano_de(canon, "target") == _dano_de(pelado, "target"))

	# El banco.
	var banco := _combate_con(["punteria_fria"])
	_comprobar("la punteria fria dobla lo que paga cerrar un banco",
		_dano_de(banco, "banco") == _dano_de(pelado, "banco") * 2,
		"%d contra %d" % [_dano_de(banco, "banco"), _dano_de(pelado, "banco")])

	# El primer golpe de la bola, y SOLO el primero.
	var cerrojo := _combate_con(["cerrojo"])
	var primero := _dano_de(cerrojo, "target")
	var segundo := _dano_de(cerrojo, "target")
	_comprobar("el cerrojo triplica el primer golpe de la bola",
		primero > segundo, "%d y luego %d" % [primero, segundo])

	# El relleno: sin reliquia el bumper NO cobra del multiplicador, con ella sí.
	# Es la que cambia CÓMO juegas, y por eso se comprueba con el combo alto.
	var normal := _combate_con([])
	var plata := _combate_con(["cascabel_de_plata"])
	for c in [normal, plata]:
		_golpear(c, 12)
	_comprobar("el racimo sigue sin cobrar del combo si no llevas el cascabel",
		normal.multiplicador() > 1
			and _dano_de(normal, "bumper") == normal.p.dano_bumper,
		"x%d, pego %d" % [normal.multiplicador(), _dano_de(normal, "bumper")])
	_comprobar("y con el cascabel el racimo cobra del combo aunque pegue la mitad",
		_dano_de(plata, "bumper") > plata.p.dano_bumper,
		"x%d, pego %d" % [plata.multiplicador(), _dano_de(plata, "bumper")])

	# Los tramos del combo. Se comparan contra `tramos()`, no contra un número.
	var muelle := _combate_con(["muelle_tenso"])
	_comprobar("el muelle adelanta los tramos sin tocar los parametros",
		int((muelle.tramos()[1] as Dictionary)["golpes"])
			< int((pelado.tramos()[1] as Dictionary)["golpes"])
			and pelado.p.tramos_combo.size() == muelle.p.tramos_combo.size(),
		str(muelle.tramos()))
	var cuerda := _combate_con(["cuerda_de_mas"])
	_comprobar("la cuerda anade un tramo por encima del ultimo",
		cuerda.tramos().size() == pelado.tramos().size() + 1
			and int((cuerda.tramos().back() as Dictionary)["factor"])
				> int((pelado.tramos().back() as Dictionary)["factor"]))

	_prueba_reliquias_defensivas()
	_prueba_ganchos_nuevos()

## Los ganchos que existen para que las cuarenta y cinco quepan sin escribir
## código por reliquia. Cada uno se mide por su efecto observable, no por la
## clave: si mañana la clave cambia de nombre, esto tiene que seguir valiendo.
func _prueba_ganchos_nuevos() -> void:
	# "al entrar en combate": empezar con el reloj atrasado.
	var frio := _combate_con(["arranque_en_frio"])
	_comprobar("una reliquia puede atrasar el reloj antes de empezar",
		frio.carga_reloj < 0.0 and frio.reloj_restante() > frio.p.reloj_carga,
		"carga %.2f, quedan %.1f s" % [frio.carga_reloj, frio.reloj_restante()])

	# "al empezar la bola": combo puesto de salida, en la primera bola y en las
	# siguientes. La segunda es la que se olvida y la que de verdad importa.
	var caliente := _combate_con(["arranque_en_caliente"])
	var combo_inicial := caliente.multiplicador()
	_comprobar("la bola puede llegar con combo puesto", combo_inicial > 1,
		"x%d con %d golpes" % [combo_inicial, caliente.golpes])
	_drenar(caliente)
	_avanzar_combate(caliente, caliente.p.pausa_drenaje + caliente.p.pausa_ataque
		+ DT * 8.0)
	_comprobar("y la bola siguiente tambien, no solo la primera",
		caliente.multiplicador() == combo_inicial,
		"x%d con %d golpes" % [caliente.multiplicador(), caliente.golpes])

	# "al drenar": conservar parte del combo.
	var nudo := _combate_con(["nudo_corredizo"])
	_golpear(nudo, 12)
	var antes_de_drenar := nudo.golpes
	_drenar(nudo)
	_comprobar("una reliquia puede salvar parte del combo al drenar",
		nudo.golpes > 0 and nudo.golpes < antes_de_drenar,
		"%d de %d" % [nudo.golpes, antes_de_drenar])

	# "al completar un recorrido": subir combo y curar, que son premios que NO
	# son daño y por eso no caben dentro de `_golpear`.
	var tren := _combate_con(["tren_de_engranajes"])
	var golpes_antes := tren.golpes
	_recorrido(tren, Rampa.Premio.DANO)
	_comprobar("un recorrido puede sumar golpes de combo",
		tren.golpes >= golpes_antes + 3, "%d y luego %d" % [golpes_antes, tren.golpes])

	var purga := _combate_con(["valvula_de_purga"])
	purga.vida_jugador = 50
	_recorrido(purga, Rampa.Premio.DANO)
	_comprobar("y un recorrido puede curar", purga.vida_jugador > 50,
		"vida %d" % purga.vida_jugador)

	# Robar reloj desde un target, que antes solo sabía hacer el platillo.
	var seda := _combate_con(["carrete_de_seda"])
	_avanzar_combate(seda, 3.0)
	var carga := seda.carga_reloj
	seda.mesa.target_abatido.emit(Vector2(200, 800), 0)
	_comprobar("un target puede robarle reloj al enemigo", seda.carga_reloj < carga,
		"%.3f y luego %.3f" % [carga, seda.carga_reloj])

	# El ataque del enemigo, que baja igual venga del reloj o del drenaje.
	var duro := _combate_con([])
	var blindado := _combate_con(["amortiguador"])
	for c in [duro, blindado]:
		_drenar(c)
		_avanzar_combate(c, c.p.pausa_drenaje + DT * 4.0)
	_comprobar("una armadura baja el golpe del enemigo",
		blindado.ultimo_ataque < duro.ultimo_ataque,
		"%d contra %d" % [blindado.ultimo_ataque, duro.ultimo_ataque])

	_prueba_condicion_en_combate()

## Una condicional dentro del combate de verdad, que es donde se puede romper:
## el contexto lo publica `Combate` y si se publicara tarde, la reliquia miraría
## el estado del golpe anterior.
func _prueba_condicion_en_combate() -> void:
	var panico := _combate_con(["panico_del_kernel"])
	panico.vida_jugador = panico.vida_maxima()
	var sano := _dano_de(panico, "target")
	panico.vida_jugador = int(float(panico.vida_maxima()) * 0.1)
	var tocado := _dano_de(panico, "target")
	_comprobar("una reliquia condicional se enciende dentro del combate",
		tocado > sano, "%d sano, %d tocado" % [sano, tocado])

	# Y el combo alto: el golpe que CRUZA el umbral no se cobra a sí mismo el
	# premio de haberlo cruzado. Si lo hiciera, el escalón se movería un golpe y
	# la reliquia diría x3 cuando en realidad empieza a x2.
	var metro := _combate_con(["metronomo"])
	_golpear(metro, 9)
	var cruza := _dano_de(metro, "target")
	var siguiente := _dano_de(metro, "target")
	_comprobar("el contexto se lee antes de sumar el golpe, no despues",
		metro.multiplicador() >= 3 and siguiente > cruza,
		"x%d, cruza %d, siguiente %d" % [metro.multiplicador(), cruza, siguiente])

## Dispara la rampa que tenga ese premio, como hace el medidor.
func _recorrido(c: Combate, premio: int) -> void:
	for i in c.mesa.rampas.size():
		if (c.mesa.rampas[i] as Rampa).premio == premio:
			c.mesa.rampa_salida.emit(Vector2(200, 800), i)
			return

## Las que tocan el castigo, no el daño. Se miden por lo que le cuesta al
## jugador, que es la unidad en la que está escrito el balance.
func _prueba_reliquias_defensivas() -> void:
	# Drenar más barato.
	var duro := _combate_con([])
	var blando := _combate_con(["gomas_nuevas"])
	for c in [duro, blando]:
		_drenar(c)
		_avanzar_combate(c, c.p.pausa_drenaje + DT * 4.0)
	var coste_duro := duro.vida_maxima() - duro.vida_jugador
	var coste_blando := blando.vida_maxima() - blando.vida_jugador
	_comprobar("las gomas nuevas abaratan el drenaje", coste_blando < coste_duro,
		"%d contra %d" % [coste_blando, coste_duro])

	# La red de seguridad: una vez por combate, y la segunda ya cobra.
	var red := _combate_con(["copia_de_seguridad"])
	_golpear(red, 6)
	_drenar(red)
	_avanzar_combate(red, red.p.pausa_drenaje + red.p.pausa_ataque + DT * 8.0)
	_comprobar("la copia de seguridad se come el primer drenaje entero",
		red.vida_jugador == red.vida_maxima() and red.golpes == 6,
		"vida %d, %d golpes" % [red.vida_jugador, red.golpes])
	_drenar(red)
	_avanzar_combate(red, red.p.pausa_drenaje + red.p.pausa_ataque + DT * 8.0)
	_comprobar("y el segundo drenaje ya cuesta como siempre",
		red.vida_jugador < red.vida_maxima() and red.golpes == 0,
		"vida %d, %d golpes" % [red.vida_jugador, red.golpes])

	# El reloj más lento. Se mide en la carga de la barra, que es lo que ve el
	# jugador, y en los segundos que se le enseñan, que tienen que cuadrar.
	var rapido := _combate_con([])
	var lento := _combate_con(["placa_termica"])
	for c in [rapido, lento]:
		_avanzar_combate(c, 3.0)
	_comprobar("la placa termica frena el reloj del enemigo",
		lento.carga_reloj < rapido.carga_reloj,
		"%.3f contra %.3f" % [lento.carga_reloj, rapido.carga_reloj])
	_comprobar("y los segundos que se ensenan cuadran con lo que tarda de verdad",
		lento.reloj_restante() > rapido.reloj_restante()
			and lento.reloj_restante() > lento.p.reloj_carga - 3.0,
		"quedan %.2f s" % lento.reloj_restante())

## El run con reliquias: que se ofrezcan tres, que no se repitan, que se pueda
## que se pueda repetir la tirada y que el eje de escalado crezca con las
## victorias y no antes.
func _prueba_run_con_reliquias(catalogo: Array[Reliquia]) -> void:
	var enemigos := CatalogoEnemigos.cargar()
	var r := Run.new(ParametrosRun.new(), ParametrosCombate.new(), enemigos, 77,
		catalogo)
	_comprobar("un run empieza sin reliquias", r.bolsa.vacia())

	# Un run SIN catálogo de reliquias tiene que comportarse como antes, o las
	# medidas de las sesiones anteriores dejan de valer.
	var pelado := Run.new(ParametrosRun.new(), ParametrosCombate.new(), enemigos, 77)
	pelado.elegir(pelado.opciones()[0])
	pelado.resolver_combate(true, 100)
	_comprobar("sin catalogo de reliquias el run no tira ruleta y sigue igual",
		pelado.fase == Run.Fase.ELIGIENDO and pelado.premio == null)

	var tomadas: Array[String] = []
	var vueltas := 0
	var rarezas := [Mision.Rareza.COMUN, Mision.Rareza.RARA, Mision.Rareza.ARCANA]
	while not r.terminada() and vueltas < 60:
		vueltas += 1
		if r.fase == Run.Fase.RULETA:
			_comprobar_una_vez("la ruleta trae sus casillas y un premio",
				r.premio != null and r.casillas.size() == r.p.casillas_ruleta
					and r.casillas[0] == r.premio,
				"%d casillas" % r.casillas.size())
			var repetida := false
			for c in r.casillas:
				if r.bolsa.tiene(c.id):
					repetida = true
			_comprobar_una_vez("y nunca sale una que ya llevas", not repetida)
			var ganada := r.aceptar_premio()
			if ganada != null:
				tomadas.append(ganada.id)
			continue
		var opciones := r.opciones()
		if opciones.is_empty():
			break
		var nodo := r.elegir(opciones[0])
		if nodo == null:
			break
		if nodo.es_combate():
			# Las reliquias se ganan completando misiones DENTRO del combate.
			r.abrir_ruleta(int(rarezas[vueltas % 3]))
			if r.fase == Run.Fase.RULETA:
				var g := r.aceptar_premio()
				if g != null:
					tomadas.append(g.id)
			r.resolver_combate(true, r.vida)
	_comprobar("un run entero acumula reliquias distintas",
		tomadas.size() >= 3 and tomadas.size() == _sin_repetir(tomadas).size(),
		"%d tomadas: %s" % [tomadas.size(), str(tomadas)])
	# El eje de escalado se paga por COMBATES ganados, no por nodos: un descanso
	# es un nodo superado y no tiene que contar, o descansar daría poder además
	# de vida.
	_comprobar("las victorias no pueden pasar de los nodos superados",
		r.bolsa.victorias > 0 and r.bolsa.victorias <= r.nodos_superados,
		"%d victorias, %d nodos" % [r.bolsa.victorias, r.nodos_superados])

	_prueba_ruleta(enemigos, catalogo)
	_prueba_no_se_cuelga(enemigos, catalogo)
	_prueba_descanso_no_da_poder(enemigos, catalogo)

## La ruleta. Lo que puede romperse aquí no es el sorteo, es que la repetición
## cambie algo que no debe, o que la animación pueda alterar el premio.
func _prueba_ruleta(enemigos: Array, catalogo: Array[Reliquia]) -> void:
	var r := Run.new(ParametrosRun.new(), ParametrosCombate.new(), enemigos, 99,
		catalogo)
	r.elegir(r.opciones()[0])
	# GANAR EL COMBATE YA NO DA NADA. La ruleta la abre completar una misión, y
	# la abre a mitad de combate: es lo que pidió Daniel y lo que hacen el
	# pinball del XP y Pokémon Pinball.
	r.resolver_combate(true, 100)
	_comprobar("ganar un combate NO abre la ruleta",
		r.fase == Run.Fase.ELIGIENDO and r.premio == null)
	_comprobar("la ruleta la abre una mision, con su rareza",
		r.abrir_ruleta(Mision.Rareza.RARA) and r.premio != null
			and r.premio.rareza == Mision.Rareza.RARA,
		"salio %s" % (r.premio.nombre_rareza() if r.premio != null else "nada"))
	_comprobar("y trae una repeticion, ni cero ni dos",
		r.repeticiones == r.p.repeticiones_ruleta and r.repeticiones == 1,
		"%d" % r.repeticiones)

	# EL PREMIO SE SORTEA ANTES DE GIRAR NADA. Es lo que permite que la
	# animación se pueda saltar o perder un fotograma sin cambiar lo que toca.
	var antes := r.premio
	_comprobar("mirar la ruleta no la cambia", r.premio == antes)

	var primero := r.premio
	_comprobar("se puede repetir la tirada una vez", r.repetir_tirada())
	_comprobar("y solo una", not r.repetir_tirada() and r.repeticiones == 0)
	_comprobar("repetir deja un premio valido", r.premio != null,
		"antes %s" % (primero.id if primero != null else "—"))

	var ganada := r.aceptar_premio()
	_comprobar("aceptar mete la reliquia en la bolsa y cierra la ruleta",
		ganada != null and r.bolsa.tiene(ganada.id) and r.premio == null
			and r.fase != Run.Fase.RULETA)
	_comprobar("aceptar dos veces no regala una segunda",
		r.aceptar_premio() == null and r.bolsa.reliquias.size() == 1)

	# Y perder no regala nada.
	var r3 := Run.new(ParametrosRun.new(), ParametrosCombate.new(), enemigos, 99,
		catalogo)
	r3.elegir(r3.opciones()[0])
	r3.resolver_combate(false, 0)
	_comprobar("con el run perdido la ruleta ya no se abre",
		r3.terminada() and not r3.abrir_ruleta(Mision.Rareza.COMUN))

## EL CUELGUE DE LA PANTALLA DEL MAPA. El golpe que completaba la última misión
## podía ser el mismo que mataba al enemigo: el run entraba en RULETA, el
## combate intentaba cerrarse, `resolver_combate` se iba de puntillas por estar
## en otra fase, y el run se quedaba en RULETA para siempre. El mapa salía sin
## ninguna rama viva y no respondía a nada. Ni error ni aviso: pantalla muerta.
func _prueba_no_se_cuelga(enemigos: Array, catalogo: Array[Reliquia]) -> void:
	var r := Run.new(ParametrosRun.new(), ParametrosCombate.new(), enemigos, 4,
		catalogo)
	r.elegir(r.opciones()[0])
	_comprobar("se puede abrir la ruleta en mitad de un combate",
		r.abrir_ruleta(Mision.Rareza.COMUN) and r.fase == Run.Fase.RULETA)
	# Y ahora el combate se acaba con la ruleta abierta, que es el caso que
	# colgaba la partida.
	r.resolver_combate(true, 500)
	_comprobar("un combate que acaba con la ruleta abierta no cuelga el run",
		r.fase == Run.Fase.ELIGIENDO and not r.opciones().is_empty(),
		"fase %d, %d opciones" % [r.fase, r.opciones().size()])
	_comprobar("y la reliquia que ya estaba ganada no se pierde por el camino",
		not r.bolsa.vacia())

	# La regla de fondo: FUERA de un run terminado, el mapa nunca puede quedarse
	# sin salidas. Si esto falla, la pantalla no responde y no hay error.
	var vueltas := 0
	while not r.terminada() and vueltas < 60:
		vueltas += 1
		if r.fase == Run.Fase.RULETA:
			r.aceptar_premio()
			continue
		_comprobar_una_vez("el mapa nunca se queda sin ramas",
			not r.opciones().is_empty(),
			"fila %d, fase %d" % [r.fila, r.fase])
		if r.opciones().is_empty():
			break
		var nodo := r.elegir(r.opciones()[0])
		if nodo == null:
			break
		if nodo.es_combate():
			r.abrir_ruleta(Mision.Rareza.COMUN)
			r.resolver_combate(true, r.vida)

func _prueba_descanso_no_da_poder(enemigos: Array, catalogo: Array[Reliquia]) -> void:
	# Se busca una semilla que tenga descanso alcanzable y se recorre hasta él.
	for semilla in [3, 7, 11, 19, 23, 29, 31, 37]:
		var r := Run.new(ParametrosRun.new(), ParametrosCombate.new(), enemigos,
			int(semilla), catalogo)
		var vueltas := 0
		while not r.terminada() and vueltas < 60:
			vueltas += 1
			if r.fase == Run.Fase.RULETA:
				r.aceptar_premio()
				continue
			var opciones := r.opciones()
			if opciones.is_empty():
				break
			var antes := r.bolsa.victorias
			# Se va a por el descanso si lo hay en la fila siguiente: es lo que
			# se quiere medir, y la rama por la que se llegue da igual.
			var destino: int = opciones[0]
			for c in opciones:
				var candidato := r.mapa.nodo(r.fila + 1, c)
				if candidato.tipo == NodoMapa.Tipo.DESCANSO:
					destino = c
					break
			var nodo := r.elegir(destino)
			if nodo == null:
				break
			if not nodo.es_combate():
				_comprobar("descansar no cuenta como victoria ni tira ruleta",
					r.bolsa.victorias == antes and r.premio == null,
					"%d antes, %d despues" % [antes, r.bolsa.victorias])
				return
			r.resolver_combate(true, r.vida)
	_comprobar("descansar no cuenta como victoria ni tira ruleta", true,
		"ninguna semilla paso por un descanso")

func _sin_repetir(lista: Array[String]) -> Array[String]:
	var vistos := {}
	var salida: Array[String] = []
	for x in lista:
		if not vistos.has(x):
			vistos[x] = true
			salida.append(x)
	return salida

## Para las comprobaciones dentro de un bucle: interesa que se cumpla siempre,
## no contar doce pruebas iguales en el listado.
var _una_vez := {}

func _comprobar_una_vez(nombre: String, condicion: bool, detalle: String = "") -> void:
	if _una_vez.has(nombre):
		if not condicion and bool(_una_vez[nombre]):
			_una_vez[nombre] = false
		return
	_una_vez[nombre] = condicion
	_comprobar(nombre, condicion, detalle)

## Los críticos. Lo que puede romperse: que la probabilidad no llegue al golpe,
## o que una reliquia de crítico no sume nada.
func _prueba_criticos() -> void:
	var c := Combate.new()
	_comprobar("hay probabilidad de critico de base",
		c.prob_critico() > 0.0 and c.factor_critico() > 1.0,
		"%.2f x%.1f" % [c.prob_critico(), c.factor_critico()])

	var cargado := _combate_con(["excepcion_no_capturada"])
	_comprobar("una reliquia sube la probabilidad de critico",
		cargado.prob_critico() > cargado.p.prob_critico,
		"%.2f contra %.2f" % [cargado.prob_critico(), cargado.p.prob_critico])

	# Con la probabilidad a tope, TODOS los golpes tienen que salir críticos y
	# pegar el doble. Se fuerza por parámetro, no por reliquia: lo que se está
	# comprobando es el mecanismo, no una reliquia concreta.
	var p := ParametrosCombate.new()
	p.prob_critico = 1.0
	var seguro := Combate.new(p)
	seguro.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000000, "ataque": 1}))
	_en_juego(seguro)
	var criticos := 0
	seguro.golpe_critico.connect(func(_pt: Vector2, _d: int) -> void: criticos += 1)
	var pegado := _dano_de(seguro, "target")
	_comprobar("con la probabilidad al 100% el golpe sale critico y avisa",
		criticos == 1 and pegado == int(round(float(seguro.p.dano_target)
			* seguro.factor_critico())),
		"%d criticos, pego %d" % [criticos, pegado])

	# Y a cero no sale ninguno: el azar no puede colarse en una medida.
	var nunca := ParametrosCombate.new()
	nunca.prob_critico = 0.0
	var limpio := Combate.new(nunca)
	limpio.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000000, "ataque": 1}))
	_en_juego(limpio)
	_comprobar("y a cero no hay criticos, asi que las medidas siguen siendo fijas",
		_dano_de(limpio, "target") == limpio.p.dano_target)

## Las misiones de mesa, que son la ÚNICA forma de ganar una reliquia.
##
## Lo que puede romperse aquí y no daría error: un tiro mal escrito en el JSON
## deja una misión imposible, y una misión imposible corta la escalera entera de
## ese combate. El jugador no ve un error: ve que no le dan nada.
func _prueba_misiones() -> void:
	var catalogo := CatalogoMisiones.cargar()
	_comprobar("el catalogo de misiones carga", catalogo.size() >= 12,
		"hay %d" % catalogo.size())

	# Los tiros tienen que ser los que cuenta `Combate`. La lista se saca del
	# propio código, no de una copia a mano: una copia se queda vieja.
	var codigo := FileAccess.get_file_as_string("res://sim/combate.gd")
	var malos: Array[String] = []
	var por_rareza := {}
	for m in catalogo:
		por_rareza[m.rareza] = int(por_rareza.get(m.rareza, 0)) + 1
		if m.tiros.is_empty() or m.texto == "":
			malos.append(m.id + " (vacia)")
		for i in m.tiros.size():
			if not codigo.contains('_apuntar("%s")' % m.tiro(i)):
				malos.append("%s: %s" % [m.id, m.tiro(i)])
	_comprobar("ningun tiro de mision esta mal escrito", malos.is_empty(),
		str(malos))
	_comprobar("hay misiones de las tres rarezas",
		por_rareza.size() == Mision.NOMBRE_RAREZA.size(), str(por_rareza))

	_prueba_escalera_de_misiones(catalogo)

func _prueba_escalera_de_misiones(catalogo: Array[Mision]) -> void:
	# Una escalera hecha a mano para no depender del sorteo.
	var comun: Mision = null
	var arcana: Mision = null
	for m in catalogo:
		if comun == null and m.rareza == Mision.Rareza.COMUN:
			comun = m
		if arcana == null and m.rareza == Mision.Rareza.ARCANA and m.sin_drenar:
			arcana = m
	var escalera: Array[Mision] = [comun, arcana]

	var c := Combate.new()
	var completadas: Array[Mision] = []
	c.mision_completada.connect(func(m: Mision) -> void: completadas.append(m))
	c.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000000, "ataque": 5}),
		-1, escalera)
	_en_juego(c)
	_comprobar("el combate arranca con la primera mision puesta",
		c.mision() == comun and c.paso_actual() == 0)

	# Completarla entera sube al escalón siguiente y avisa una sola vez.
	for i in comun.tiros.size():
		for _k in comun.veces(i):
			_tiro_de_mision(c, comun.tiro(i))
	_comprobar("completar una mision pasa a la siguiente y avisa",
		completadas.size() == 1 and completadas[0] == comun
			and c.mision() == arcana,
		"%d completadas" % completadas.size())

	# Y una misión que pide no drenar se reinicia al drenar.
	_tiro_de_mision(c, arcana.tiro(0))
	var llevaba := c.llevas(0)
	_drenar(c)
	_comprobar("drenar reinicia una mision que pedia aguantar la bola",
		llevaba > 0 and c.llevas(0) == 0,
		"llevaba %d, lleva %d" % [llevaba, c.llevas(0)])

	# Sin escalera el combate se juega igual: es lo que deja correr los medidores.
	var pelado := Combate.new()
	pelado.iniciar(Enemigo.new({"nombre": "Saco", "vida": 1000, "ataque": 5}))
	_en_juego(pelado)
	_golpear(pelado, 5)
	_comprobar("sin misiones el combate se juega igual",
		pelado.mision() == null and pelado.golpes == 5)

	# Y la medida del jugador, que es lo que permite escribir la tabla exacta.
	_comprobar("el combate mide el dano por bola del jugador de verdad",
		pelado.dano_por_bola() > 0.0 and pelado.bolas_jugadas >= 1,
		"%.0f en %d bolas" % [pelado.dano_por_bola(), pelado.bolas_jugadas])

## Dispara el evento de mesa que corresponde a un tiro de misión.
func _tiro_de_mision(c: Combate, tiro: String) -> void:
	var punto := Vector2(200, 800)
	match tiro:
		"bumper": c.mesa.bumper_golpeado.emit(punto, 500.0)
		"girador": c.mesa.girador_girado.emit(punto, 0, 500.0)
		"target": c.mesa.target_abatido.emit(punto, 0)
		"banco": c.mesa.banco_completado.emit(punto, 0)
		"platillo": c.mesa.platillo_expulsado.emit(punto, 0)
		"orbita": _recorrido(c, Rampa.Premio.MULTIPLICADOR)
		"canon": _recorrido(c, Rampa.Premio.DANO_FUERTE)
		"retorno": _recorrido(c, Rampa.Premio.DANO)

## La fuente tiene que saber escribir en castellano.
##
## Salió jugando: no había ni acentos ni ñ en ninguna pantalla. La causa era que
## todo cogía la fuente de reserva de Godot, que solo trae ASCII, así que
## "MANTÉN" salía como "MANTN". Un glifo que falta no da error: deja un hueco, y
## nadie mira un hueco. Por eso esto se comprueba y no se supone.
func _prueba_fuente() -> void:
	_comprobar("la fuente sabe escribir acentos y enes",
		FuenteUI.tiene_castellano(),
		"faltan glifos de '%s' — relanza `python3 fuente.py`" % FuenteUI.LETRAS)

	# LA FUENTE ES NUESTRA Y ES PIXELART. Si esto cae en la de reserva de Godot,
	# el texto vuelve a ser una tipografía suave alrededor de una mesa de
	# píxeles duros, que es lo que hacía que la cáscara pareciera dos programas
	# distintos pegados.
	_comprobar("la fuente es la de mapa de bits del juego, no una de reserva",
		FuenteUI.obtener() is FontFile and FuenteUI.alto() == 8,
		"alto %d" % FuenteUI.alto())

	# Y todo el texto tiene que pedir múltiplos de la celda: un 11 escala la
	# fuente por 1,375 y le come filas de píxeles a media letra. Es la misma
	# regla de escalado por enteros que la mesa, aplicada a las letras.
	var u := FuenteUI.alto()
	_comprobar("los tamanos se redondean al multiplo de la celda",
		FuenteUI.tam(11) == u and FuenteUI.tam(22) == u * 3
			and FuenteUI.tam(2) == u,
		"%d %d %d" % [FuenteUI.tam(11), FuenteUI.tam(22), FuenteUI.tam(2)])

	var sueltos_tam: Array[String] = []
	var re_tam := RegEx.new()
	# EL PATRÓN LLEVABA UN AGUJERO y por él se coló un 11 durante toda la Fase 5:
	# solo miraba los tamaños seguidos de una constante `C_ALGO` o de un
	# `Color(...)`, así que un `draw_string(..., 11, col)` con el color en una
	# variable en minúsculas pasaba de largo. Era el nombre de la reliquia en la
	# tele, escalado por 1,375 y con filas de píxeles comidas. Ahora también
	# entran las variables y los `Paleta.ALGO` sueltos.
	re_tam.compile(r",\s*(\d+),\s*\n?\s*(?:C_[A-Z_]+|Color\(|Paleta\.|[a-z_][a-z0-9_]*\s*\))")
	for archivo in (DirAccess.open("res://render").get_files()
			if DirAccess.open("res://render") else PackedStringArray()):
		if not archivo.ends_with(".gd"):
			continue
		var texto := FileAccess.get_file_as_string("res://render/" + archivo)
		for m in re_tam.search_all(texto):
			var n := int(m.get_string(1))
			if n >= 7 and n % u != 0:
				sueltos_tam.append("%s: %d" % [archivo, n])
	_comprobar("ningun texto pide un tamano que no sea multiplo de la celda",
		sueltos_tam.is_empty(), str(sueltos_tam))

	# Y que nadie se haya vuelto a coger la fuente de reserva por su cuenta:
	# con una sola que lo haga, esa pantalla pierde los acentos y las demás no,
	# que es peor que perderlos en todas porque parece cosa del texto.
	var dir := DirAccess.open("res://render")
	var sueltos: Array[String] = []
	for archivo in (dir.get_files() if dir else PackedStringArray()):
		if not archivo.ends_with(".gd") or archivo == "fuente_ui.gd":
			continue
		if FileAccess.get_file_as_string("res://render/" + archivo) \
				.contains("ThemeDB.fallback_font"):
			sueltos.append(archivo)
	_comprobar("nadie coge la fuente de reserva por su cuenta",
		sueltos.is_empty(), str(sueltos))

## LA CÁSCARA (Fase 5). Lo que se comprueba aquí es la geometría del marco de
## nueve trozos, que es la pieza técnica de la fase, y que los huecos donde van
## las cosas caen donde tienen que caer.
##
## Lo que NO se comprueba y hay que mirar jugando: si la broma se entiende. Eso
## es el criterio de salida y no se lee en una prueba.
func _prueba_cascara() -> void:
	var marco := NueveTrozos.cargar("res://assets/ui/ventana")
	var faltan: Array[String] = []
	for n in NueveTrozos.NOMBRES:
		if marco.tiene(n) == null:
			faltan.append(n)
	_comprobar("el marco de nueve trozos tiene sus nueve piezas",
		faltan.is_empty(), str(faltan))

	# LA COMPROBACIÓN QUE DE VERDAD IMPORTA de un atlas de nueve trozos: las
	# cuatro esquinas tienen que medir lo mismo. Si no, es que se cortó por
	# SILUETA en vez de en rejilla fija —que es lo que hace `procesar.py` por
	# defecto, y lo correcto para un icono— y entonces las esquinas no cuadran
	# con los bordes. No da error: deja un marco descuadrado por 2 px.
	# Los cinco marcos de la cáscara los genera `fuente.py`, así que salen
	# cuadrados por construcción. La comprobación se queda porque es la que se
	# lleva por delante un marco recortado por silueta, que fue el fallo de la
	# primera pasada: cada pieza medía lo que medía su dibujo y el borde
	# izquierdo no era igual que el derecho.
	var descuadrados: Array[String] = []
	for nombre in ["ventana", "titulo", "barra", "boton", "tooltip"]:
		var m := NueveTrozos.cargar("res://assets/ui/" + nombre)
		if not m.completo() or not m.esquinas_cuadran():
			descuadrados.append(nombre)
	_comprobar("los cinco marcos de la cascara cuadran",
		descuadrados.is_empty(),
		"%s — relanza `python3 fuente.py`" % str(descuadrados))

	# El interior tiene que ser el hueco de dentro, y nunca salirse de la caja.
	var g := marco.grosor()
	var caja := Rect2(100, 100, 400, 300)
	var dentro := marco.interior(caja)
	_comprobar("el interior del marco cae dentro del marco",
		caja.encloses(dentro) and is_equal_approx(dentro.position.x, 100.0 + g.x)
			and is_equal_approx(dentro.size.x, 400.0 - g.x - g.z),
		str(dentro))

	# Y con una caja más pequeña que el propio marco no puede salir un interior
	# de tamaño negativo: un botón puede ser más pequeño que su marco.
	var enano := marco.interior(Rect2(0, 0, 4, 4))
	_comprobar("un marco mas grande que su caja no da tamanos negativos",
		enano.size.x >= 0.0 and enano.size.y >= 0.0, str(enano))

	_prueba_huecos_de_la_cascara()

## Los huecos: la franja de la mesa y las bandas de escritorio. Son los 280 px
## por lado que `PLAN.md` reservó desde la Fase 1, y lo que puede romperse es
## que un icono caiga encima de la mesa o debajo de la barra de tareas.
func _prueba_huecos_de_la_cascara() -> void:
	# Sin `VistaMesa`: montarla aquí arrancaría un run entero y cargaría todos
	# los sprites para medir cuatro rectángulos. La cáscara aguanta sin ella,
	# que además es lo que hace que se pueda probar.
	var cascara := NodoCascara.new(null, ParametrosCamara.new(),
		ParametrosAnimacion.new())
	get_root().add_child(cascara)

	var franja := cascara.franja_mesa()
	var ventana := cascara.ventana_mesa()
	var izq := cascara.banda_izquierda()
	var der := cascara.banda_derecha()
	_comprobar("la mesa va centrada y mide lo que mide la mesa",
		is_equal_approx(franja.size.x, Mesa.ANCHO)
			and is_equal_approx(ventana.position.x, izq.size.x),
		"franja %s" % str(franja))
	# La ventana tiene que ENVOLVER a la mesa: si el marco se metiera dentro,
	# comería campo de juego, y la anchura de la mesa es intocable.
	_comprobar("la ventana envuelve la mesa sin comerle campo",
		ventana.encloses(franja) and ventana.position.y < franja.position.y,
		"ventana %s" % str(ventana))
	_comprobar("y quedan dos bandas de escritorio del mismo ancho",
		is_equal_approx(izq.size.x, der.size.x) and izq.size.x > 200.0,
		"%.0f y %.0f" % [izq.size.x, der.size.x])

	# Ningún icono puede pisar la mesa ni meterse bajo la barra de tareas: el
	# escritorio es lo que sobra, y lo que sobra tiene un borde.
	var intrusos: Array[String] = []
	for i in 12:
		var caja := cascara.caja_icono(i)
		if caja.end.x > ventana.position.x or caja.end.y > izq.end.y:
			intrusos.append("%d en %s" % [i, str(caja)])
	_comprobar("ningun icono de reliquia pisa la mesa ni la barra de tareas",
		intrusos.is_empty(), str(intrusos))

	_prueba_paneles_de_la_cascara(cascara, ventana, der)
	_prueba_fondos_por_acto(cascara)
	cascara.free()

## LOS PANELES DE LA BANDA DERECHA, que es donde vive el HUD desde que dejó de
## estar encima de la mesa. Lo que puede romperse aquí es exactamente lo mismo
## que con los iconos: que un panel pise el campo de juego o se meta debajo de la
## barra de tareas. Y una cosa más, que solo pasa con los paneles: que se solapen
## entre ellos, porque sus alturas están escritas a mano y la suma tiene que
## caber en la banda.
func _prueba_paneles_de_la_cascara(cascara: NodoCascara, ventana: Rect2,
		der: Rect2) -> void:
	var paneles := {
		"enemigo": cascara.panel_enemigo(),
		"jugador": cascara.panel_jugador(),
		"ayuda": cascara.panel_ayuda(),
	}
	var fuera: Array[String] = []
	for nombre in paneles:
		var caja: Rect2 = paneles[nombre]
		if caja.position.x < ventana.end.x or caja.end.x > der.end.x \
				or caja.position.y < 0.0 or caja.end.y > der.end.y:
			fuera.append("%s en %s" % [str(nombre), str(caja)])
	_comprobar("ningun panel pisa la mesa ni la barra de tareas",
		fuera.is_empty(), "banda %s — %s" % [str(der), str(fuera)])

	var solapados: Array[String] = []
	var lista: Array = paneles.keys()
	for i in lista.size():
		for j in range(i + 1, lista.size()):
			var a: Rect2 = paneles[lista[i]]
			var b: Rect2 = paneles[lista[j]]
			if a.intersects(b):
				solapados.append("%s con %s" % [str(lista[i]), str(lista[j])])
	_comprobar("los tres paneles caben en la banda sin solaparse",
		solapados.is_empty(), str(solapados))

	# Y el enemigo tiene que caber ENTERO dentro del suyo. Un sprite de 96 px que
	# se sale por abajo se come el nombre y la barra de vida, y eso no da error:
	# deja un panel con un bicho cortado y sin datos.
	var dentro := cascara.interior_panel(cascara.panel_enemigo())
	var pies := cascara.suelo_enemigo()
	var techo := pies.y - NodoCascara.LADO_RETRATO_PANEL
	_comprobar("el enemigo cabe entero dentro de su panel",
		techo >= dentro.position.y and pies.y <= dentro.end.y
			and dentro.size.x >= NodoCascara.LADO_RETRATO_PANEL,
		"pies en %s, hueco %s" % [str(pies), str(dentro)])

	# LA CÁMARA MIDE CONTRA ESTO. Si el marco de la ventana engorda y el
	# parámetro se queda viejo, la bola vuelve a esconderse en lo alto de la
	# órbita —el tiro más largo de la mesa— y no salta ningún error: solo deja de
	# verse. Es la misma avería del denominador escrito a mano.
	_comprobar("la camara mide el chrome de verdad, no un numero copiado",
		is_equal_approx(ParametrosCamara.new().alto_franja_hud,
			NodoCascara.chrome_superior()),
		"parametro %.0f, chrome %.0f" % [ParametrosCamara.new().alto_franja_hud,
			NodoCascara.chrome_superior()])

## LOS FONDOS DEL ESCRITORIO, uno por acto y con variantes. `DISEÑO.md` §3 dice
## que el sistema se corrompe acto a acto, así que la corrupción tiene que
## CRECER: si el acto 3 no trae más variantes que el 1, el escritorio no está
## contando nada.
##
## Y se comprueba que cargan de verdad, no que estén en el disco: un PNG sin
## importar no da error, deja el escritorio en negro y se diagnostica como un
## fallo de dibujo.
func _prueba_fondos_por_acto(cascara: NodoCascara) -> void:
	var faltan: Array[String] = []
	for lista in NodoCascara.FONDOS_POR_ACTO:
		for nombre in lista:
			var ruta := "res://assets/shell/%s.png" % str(nombre)
			if not ResourceLoader.exists(ruta):
				faltan.append(str(nombre))
	_comprobar("todos los fondos de la cascara existen y se importan",
		faltan.is_empty(), "%s — abre el proyecto una vez para importarlos"
			% str(faltan))

	var por_acto: Array[int] = []
	for acto in NodoCascara.FONDOS_POR_ACTO.size():
		por_acto.append(cascara.variantes_de_acto(acto))
	_comprobar("cada acto tiene al menos un fondo",
		not por_acto.has(0), str(por_acto))
	_comprobar("la corrupcion crece: el acto 3 tiene mas variantes que el 1",
		por_acto[por_acto.size() - 1] > por_acto[0], str(por_acto))

	# Tirar el dado muchas veces tiene que dar TODAS las variantes de cada acto.
	# Con un módulo mal puesto saldría siempre la misma y el trabajo de arte de
	# la tanda anterior no se vería nunca — y no daría ningún error, que es la
	# forma cara de perder assets.
	var cortos: Array[String] = []
	for acto in NodoCascara.FONDOS_POR_ACTO.size():
		var vistas := {}
		for _i in 300:
			cascara.tirar_fondo()
			var t := cascara.fondo_de_acto(acto)
			if t != null:
				vistas[t.resource_path] = true
		if vistas.size() != por_acto[acto]:
			cortos.append("acto %d: %d de %d" % [acto + 1, vistas.size(),
				por_acto[acto]])
	_comprobar("el dado del fondo llega a todas las variantes de cada acto",
		cortos.is_empty(), str(cortos))

## Bloque 2, coherencia visual: la paleta de CONTEXTO.md manda.
##
## Antes cada archivo que dibujaba se copiaba su propio bloque de hex y había
## tres colores inventados (1C1A22 para los huecos y dos blancos puros). Con
## cuatro copias del mismo bloque, cambiar un color era acordarse de cuatro
## sitios, y no acordarse no rompía nada: solo se quedaba un color viejo.
func _prueba_paleta() -> void:
	var permitidos := {}
	for c in Paleta.TODOS:
		permitidos[c.to_html(false).to_upper()] = true
	_comprobar("la paleta tiene los colores de CONTEXTO.md",
		Paleta.TODOS.size() == 33, "hay %d" % Paleta.TODOS.size())

	# Ningún Color("...") suelto fuera de paleta.gd. Se permite el hex que ya
	# esté en la paleta (no molesta), pero no uno inventado.
	var dir := DirAccess.open("res://render")
	var intrusos: Array[String] = []
	var re := RegEx.new()
	re.compile(r'Color\("([0-9A-Fa-f]{6})"\)')
	for archivo in (dir.get_files() if dir else PackedStringArray()):
		if not archivo.ends_with(".gd") or archivo == "paleta.gd":
			continue
		var texto := FileAccess.get_file_as_string("res://render/" + archivo)
		for m in re.search_all(texto):
			var hex := m.get_string(1).to_upper()
			if not permitidos.has(hex):
				intrusos.append("%s: %s" % [archivo, hex])
	_comprobar("ningun color inventado fuera de la paleta",
		intrusos.is_empty(), str(intrusos))

	# Y los alias por uso tienen que ser colores de la paleta de verdad, no un
	# hex escrito a mano que se parezca.
	var fuera: Array[String] = []
	for pareja in [
			["CABINA", Paleta.CABINA], ["MESA", Paleta.MESA],
			["MESA_BAJA", Paleta.MESA_BAJA], ["HUECO", Paleta.HUECO],
			["PARED", Paleta.PARED], ["PARED_LUZ", Paleta.PARED_LUZ],
			["CARRIL", Paleta.CARRIL], ["GOMA", Paleta.GOMA],
			["GOMA_LUZ", Paleta.GOMA_LUZ], ["DRENAJE", Paleta.DRENAJE],
			["PIEDRA", Paleta.PIEDRA], ["FUEGO", Paleta.FUEGO],
			["FLIPPER", Paleta.FLIPPER], ["FLIPPER_BORDE", Paleta.FLIPPER_BORDE],
			["FLIPPER_LINEA", Paleta.FLIPPER_LINEA], ["METAL", Paleta.METAL],
			["METAL_LUZ", Paleta.METAL_LUZ], ["TEXTO", Paleta.TEXTO],
			["TEXTO_TENUE", Paleta.TEXTO_TENUE], ["DESTELLO", Paleta.DESTELLO]]:
		if not Paleta.TODOS.has(pareja[1]):
			fuera.append(str(pareja[0]))
	_comprobar("todos los alias por uso salen de la paleta",
		fuera.is_empty(), str(fuera))
