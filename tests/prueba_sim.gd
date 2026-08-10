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
	_prueba_outlanes()
	_prueba_agarre()
	_prueba_identidad_recorridos()

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
	_comprobar("tras la pausa el enemigo contraataca",
		c.vida_jugador == c.p.vida_jugador - 10, "vida %d" % c.vida_jugador)
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

	_prueba_combo()
	_prueba_victoria()
	_prueba_derrota()
	_prueba_catalogo()

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
	_golpear(c2, 1)
	_comprobar("el quinto golpe ya vale x2",
		tras_cuatro - c2.enemigo.vida == c2.p.dano_bumper * 2,
		"quito %d" % (tras_cuatro - c2.enemigo.vida))
	_comprobar("los cuatro primeros valieron x1",
		c2.p.vida_jugador > 0 and (100000 - tras_cuatro) == c2.p.dano_bumper * 4,
		"quitaron %d" % (100000 - tras_cuatro))

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
	c.iniciar(Enemigo.new({"nombre": "Debil", "vida": 5, "ataque": 99}))
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
		absf(m.flipper_izq.omega) < m.p.flipper_agarre_omega)

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

	# La franja del HUD son 58 px opacos pegados al borde de arriba, y en lo
	# alto de la órbita la bola se metía detrás: el tiro más largo de la mesa
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
