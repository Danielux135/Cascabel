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
	_prueba_sprites_de_flipper()

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

## El sprite del flipper tiene que caer encima de su cápsula, no al lado ni
## girado. Mirar una captura no basta: así se coló el derecho girado 180°,
## apuntando al carril lanzador mientras el colisionador iba abajo-izquierda.
func _prueba_sprites_de_flipper() -> void:
	var m := _nueva_mesa()
	for caso in [
			{"nombre": "izquierdo", "f": m.flipper_izq, "desc": VistaMesa.SPRITE_FLIPPER_IZQ},
			{"nombre": "derecho", "f": m.flipper_der, "desc": VistaMesa.SPRITE_FLIPPER_DER}]:
		var f: Flipper = caso["f"]
		var desc: Dictionary = caso["desc"]
		var punta_sprite: Vector2 = desc["punta"]
		var eje_sprite: Vector2 = desc["eje"]

		# En reposo y accionado: la punta dibujada sobre la de la cápsula.
		for pulsado in [false, true]:
			f.pulsado = pulsado
			f.avanzar(1.0)   # un paso largo: llega al tope
			var t := VistaMesa.transformada_flipper(
				f.angulo, f.eje, f.longitud, desc["giro_base"])
			var punta_dibujada := t * (punta_sprite - eje_sprite)
			var error := punta_dibujada.distance_to(f.punta())
			_comprobar("punta del sprite %s sobre la capsula (%s)"
					% [caso["nombre"], "accionado" if pulsado else "reposo"],
				error < 1.0,
				"desviada %.1f px: sprite %s, capsula %s"
					% [error, str(punta_dibujada.round()), str(f.punta().round())])

			# Y el arte no puede quedar boca abajo: el "arriba" del sprite
			# tiene que seguir apuntando hacia arriba en el mundo.
			var arriba := (t.basis_xform(Vector2(0, -1))).normalized()
			_comprobar("el sprite %s no queda boca abajo (%s)"
					% [caso["nombre"], "accionado" if pulsado else "reposo"],
				arriba.y < -0.5, "arriba del sprite = %s" % str(arriba))
		f.pulsado = false
		f.avanzar(1.0)

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
