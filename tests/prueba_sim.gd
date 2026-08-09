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
		if pos.x < 20.0 or pos.x > 380.0 or pos.y < 55.0 or pos.y > 701.0:
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
	_comprobar("viewport 400x700",
		ProjectSettings.get_setting("display/window/size/viewport_width") == 400
		and ProjectSettings.get_setting("display/window/size/viewport_height") == 700)

## El arreglo 1 depende de que no quede ningún hueco por el que quepa la bola
## entre el final del carril de retorno, el poste y el eje del flipper.
func _prueba_geometria_sellada() -> void:
	var m := _nueva_mesa()
	var d := m.p.radio_bola * 2.0
	for lado in [
			{"poste": Vector2(102, 596), "fin_rampa": Vector2(99, 584), "eje": m.p.flipper_eje_izq},
			{"poste": Vector2(298, 596), "fin_rampa": Vector2(301, 584), "eje": m.p.flipper_eje_der}]:
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
		m.bola.pos = Vector2(rng.randf_range(40, 340), rng.randf_range(150, 450))
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
		Vector2(55, 520), Vector2(80, 555), Vector2(95, 575),   # inlane izquierdo
		Vector2(111, 594), Vector2(105, 592),                   # el punto del bug
		Vector2(330, 495), Vector2(310, 545), Vector2(290, 575),# inlane derecho
		Vector2(289, 594),
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
	m.bola.pos = Vector2(200, 400)
	m.bola.vel = Vector2.ZERO
	# Suelo falso justo debajo para que se quede parada de verdad.
	m.colisionadores.append(Colisionador.new(
		Vector2(120, 420), Vector2(280, 420), 0.0, Colisionador.Tipo.PARED, 0.0))
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

	# Los targets no pueden sellar el carril lateral: con el banco en pie se
	# tiene que poder seguir bajando al inlane.
	for datos in [{"banco": 0, "pared_x": 20.0}, {"banco": 1, "pared_x": 350.0}]:
		var c: Colisionador = m.bancos[datos["banco"]][0]
		var carril: float = absf(c.a.x - (datos["pared_x"] as float)) \
			- m.p.target_radio - m.p.radio_bola * 2.0
		_comprobar("queda carril entre el banco %d y la pared" % datos["banco"],
			carril > 2.0, "solo %.1f px libres" % carril)

	# Y entre target y target NO tiene que caber, o se acuñaría.
	var banco: Array = m.bancos[0]
	var hueco: float = (banco[0] as Colisionador).a.distance_to((banco[1] as Colisionador).a) \
		- m.p.target_radio * 2.0
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
	# El bumper izquierdo, no el de arriba: sobre el de arriba la bola rebota en
	# el arco y vuelve a caer dentro de la ventana de medida, y ese segundo
	# aviso es legítimo. Aquí el empuje de 620 se queda 24 px por debajo del
	# arco, así que en 0,4 s no puede haber dos golpes.
	var arriba := Vector2(140, 225)
	var m := _nueva_mesa()
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
		c.mesa.bumper_golpeado.emit(Vector2(200, 200), 500.0)

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
	c3.mesa.banco_completado.emit(Vector2(56, 360), 0)
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
	var muertas: Array[bool] = []
	for adorno in VistaMesa.ADORNOS:
		var ruta := "res://assets/mesa_deco/%s.png" % adorno["tex"]
		if not ResourceLoader.exists(ruta):
			fuera.append(str(adorno["tex"]) + " (no existe)")
			continue
		var caja := VistaMesa.caja_adorno(adorno, load(ruta))
		cajas.append(caja)
		nombres.append(str(adorno["tex"]))
		muertas.append(bool(adorno["muerta"]))
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
		m.bola.pos = Vector2(rng.randf_range(40, 340), rng.randf_range(150, 450))
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

	# Los de zona muerta tienen que dar cero clavado: si uno empieza a marcar
	# algo es que se ha movido a donde la bola sí llega. Los de campo abierto
	# solo tienen que quedarse por debajo del 3 %. La rejilla queda exenta:
	# está en el drenaje a propósito y marca un 13 %.
	var pisados: Array[String] = []
	var ruidosos: Array[String] = []
	for j in cajas.size():
		var pct := 100.0 * float(visitas[j]) / float(maxi(muestras, 1))
		if muertas[j]:
			if visitas[j] > 0:
				pisados.append("%s %.2f%%" % [nombres[j], pct])
		elif nombres[j] != "rejilla" and pct > 3.0:
			ruidosos.append("%s %.2f%%" % [nombres[j], pct])
	_comprobar("la bola no llega a los adornos de zona muerta (%d muestras)" % muestras,
		pisados.is_empty(), str(pisados))
	_comprobar("y por los de campo abierto apenas pasa",
		ruidosos.is_empty(), str(ruidosos))

func _prueba_giradores() -> void:
	var m := _nueva_mesa()
	_comprobar("hay un girador en cada carril de retorno",
		m.giradores.size() == 2, "%d giradores" % m.giradores.size())

	# Hay que soltarla BAJANDO POR EL CARRIL: el carril de retorno izquierdo va
	# en diagonal, y a plomo desde arriba la bola cae fuera, sobre el slingshot.
	var carril := (Vector2(99, 584) - Vector2(20, 480)).normalized()

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
