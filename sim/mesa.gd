class_name Mesa
extends RefCounted

## Simulación de la mesa. Sin dependencias del motor más allá de Vector2:
## se puede ejecutar entera en headless (ver tests/prueba_sim.gd).
##
## Lienzo 400 x 1300, Y hacia abajo.

signal bumper_golpeado(punto: Vector2, fuerza: float)
signal slingshot_golpeado(punto: Vector2, fuerza: float)
signal poste_golpeado(punto: Vector2, fuerza: float)
signal flipper_golpeado(punto: Vector2, fuerza: float)
signal target_abatido(punto: Vector2, banco: int)
signal girador_girado(punto: Vector2, indice: int, fuerza: float)
signal banco_completado(punto: Vector2, banco: int)
signal bola_drenada()
signal busqueda_bola(punto: Vector2)
signal rampa_entrada(punto: Vector2, indice: int)
signal rampa_salida(punto: Vector2, indice: int)
signal platillo_capturado(punto: Vector2, indice: int)
signal platillo_expulsado(punto: Vector2, indice: int)

const ANCHO := 400.0
const ALTO := 1300.0
## La zona baja (y 660..1300) es la mesa de 700 validada, bajada estos px. Todo
## lo de `_construir` se escribe con las coordenadas ORIGINALES y pasa por _v(),
## para que los números sigan siendo los del prototipo y se puedan comparar.
const DESPLAZAMIENTO := 600.0
const SEGMENTOS_ARCO := 48

var p: ParametrosMesa
var rng := RandomNumberGenerator.new()

var colisionadores: Array[Colisionador] = []
var flipper_izq: Flipper
var flipper_der: Flipper
var bola := Bola.new()

## Solo para dibujar: la polilínea del arco superior.
var arco := PackedVector2Array()
## Solo para dibujar: centros y radios de bumpers y postes.
var bumpers: Array[Vector2] = []
var postes: Array[Vector2] = []
## Targets abatibles, agrupados en bancos. `activo` dice si están en pie.
var targets: Array[Colisionador] = []
var bancos: Array[Array] = []
var _reset_banco: Array[float] = []
## Giradores: no colisionan, la bola los atraviesa y los hace girar.
var giradores: Array[Vector2] = []
var _girador_dentro: Array[bool] = []
## Rampas y platillos: no son colisionadores, son curvas y trampas.
var rampas: Array[Rampa] = []
var platillos: Array[Platillo] = []

var carga_lanzador: float = 0.0
var cargando := false

var _contactos: Array[Contacto] = []
var _temporizador_busqueda: float = 0.0
var _tocando_flipper_sostenido := false

func _init(parametros: ParametrosMesa = null) -> void:
	p = parametros if parametros != null else ParametrosMesa.new()
	rng.randomize()
	_construir()

# ---------------------------------------------------------------- construcción

## Coordenada de la mesa validada de 700, ya bajada a su sitio.
func _v(x: float, y: float) -> Vector2:
	return Vector2(x, y + DESPLAZAMIENTO)

func _construir() -> void:
	_construir_arco()

	# Paredes laterales del campo de juego.
	_pared(_v(20, 130), _v(20, 480))
	_pared(_v(380, 130), _v(380, 660))   # exterior del carril lanzador

	# --- Carril lanzador ---
	# El tramo bajo se estrecha a 22 px para dejar sitio al inlane derecho.
	# La bola (18 px) sigue pasando holgada.
	_pared(_v(350, 300), _v(350, 440))
	_pared(_v(350, 440), _v(355, 458))
	_pared(_v(355, 458), _v(358, 470))
	_pared(_v(358, 470), _v(358, 660))
	_pared(_v(358, 660), _v(380, 660))   # suelo del carril
	# Puerta antirretorno. Inclinada a propósito: una bola que cae encima rueda
	# hacia la izquierda y entra al campo en vez de quedarse parada en la repisa.
	var puerta := _pared(_v(350, 304), _v(380, 296))
	puerta.tipo = Colisionador.Tipo.PUERTA
	puerta.una_direccion = true

	# --- ARREGLO 1: inlanes de verdad ---
	# El bug: la rampa acababa en (105,592) y el eje del flipper estaba en
	# (118,600). Quedaban 7,3 px de hueco para una bola de 9 px de radio: no
	# cabía, pero se acuñaba. La rampa ahora es la pared exterior de un carril
	# de retorno que muere en un poste de goma, y el poste solapa con la cápsula
	# del eje del flipper (11 + 8 = 19 px de radios contra 8,5 px de distancia).
	# No queda hueco: no hay dónde acuñarse. La bola sale por la boca del inlane
	# (22 px libres entre el poste y la punta del slingshot) y cae sobre el
	# flipper, que es lo que hace un inlane real.
	_pared(_v(20, 480), _v(99, 584))          # retorno izquierdo
	_slingshot(_v(75, 505), _v(128, 575))
	_poste(_v(102, 596))

	_pared(_v(355, 458), _v(301, 584))        # retorno derecho
	_slingshot(_v(306, 512), _v(262, 582))
	_poste(_v(298, 596))

	# --- Bumpers ---
	_bumper(_v(140, 225))
	_bumper(_v(260, 225))
	_bumper(_v(200, 165))

	# --- Bancos de targets ---
	# Pegados a las paredes pero sin sellarlas: quedan 23 px de carril por fuera
	# (la bola mide 18) para poder seguir bajando al inlane con el banco en pie.
	# Entre target y target solo quedan 14 px, así que por ahí no se cuela.
	_banco_targets(_v(56, 320), _v(56, 400), 3)
	_banco_targets(_v(314, 320), _v(314, 400), 3)

	# --- Giradores, en mitad de cada carril de retorno ---
	_girador(_v(87, 545))
	_girador(_v(300, 545))

	# --- La órbita: la única forma de llegar a la zona alta ---
	# Con gravedad 1750 y tope de 1500 px/s la bola no sube más de 643 px por su
	# cuenta, así que los 660 px de arriba solo se recorren enganchada a esta
	# curva. Es bidireccional, como las órbitas de verdad: entras por un lado y
	# sales por el otro. Las bocas están a y=880: un lanzamiento al 88 % o más
	# llega con velocidad de sobra para engancharse y uno más flojo no. Ahí está
	# la habilidad del tiro inicial.
	_orbita()

	# --- Platillo, metido bajo el arco a la izquierda ---
	# Hay que buscarlo: no está en el camino de la bola. Captura, pausa, y
	# escupe hacia el campo.
	_platillo(_v(70, 170), Vector2(0.75, 1.0))

	flipper_izq = Flipper.new(
		p.flipper_eje_izq, p.flipper_longitud, p.flipper_radio, p.flipper_rebote,
		p.flipper_reposo_izq, p.flipper_activo_izq, p.flipper_velocidad_giro)
	flipper_der = Flipper.new(
		p.flipper_eje_der, p.flipper_longitud, p.flipper_radio, p.flipper_rebote,
		p.flipper_reposo_der, p.flipper_activo_der, p.flipper_velocidad_giro)

func _construir_arco() -> void:
	# Elipse centro (200,130), rx 180, ry 70. De (380,130) a (20,130) por arriba.
	arco.clear()
	for i in SEGMENTOS_ARCO + 1:
		var t := PI * float(i) / float(SEGMENTOS_ARCO)
		arco.append(_v(200.0 + 180.0 * cos(t), 130.0 - 70.0 * sin(t)))
	for i in SEGMENTOS_ARCO:
		_pared(arco[i], arco[i + 1])

func _pared(a: Vector2, b: Vector2) -> Colisionador:
	var c := Colisionador.new(a, b, 0.0, Colisionador.Tipo.PARED, p.rebote_pared)
	colisionadores.append(c)
	return c

func _slingshot(a: Vector2, b: Vector2) -> Colisionador:
	var c := Colisionador.new(a, b, 0.0, Colisionador.Tipo.SLINGSHOT,
		p.slingshot_rebote, p.slingshot_empuje, p.slingshot_velocidad_minima)
	colisionadores.append(c)
	return c

func _bumper(centro: Vector2) -> Colisionador:
	var c := Colisionador.new(centro, centro, p.bumper_radio, Colisionador.Tipo.BUMPER,
		p.bumper_rebote, p.bumper_empuje, p.bumper_velocidad_minima)
	colisionadores.append(c)
	bumpers.append(centro)
	return c

func _banco_targets(desde: Vector2, hasta: Vector2, cantidad: int) -> void:
	var indice := bancos.size()
	var banco: Array[Colisionador] = []
	for i in cantidad:
		var t := float(i) / float(cantidad - 1) if cantidad > 1 else 0.0
		var centro := desde.lerp(hasta, t)
		var c := Colisionador.new(centro, centro, p.target_radio,
			Colisionador.Tipo.TARGET, p.target_rebote, 0.0, p.target_velocidad_minima)
		c.banco = indice
		colisionadores.append(c)
		targets.append(c)
		banco.append(c)
	bancos.append(banco)
	_reset_banco.append(0.0)

func _orbita() -> void:
	# En absoluto: la órbita cruza la mesa entera, no es de la zona baja.
	var control := PackedVector2Array([
		Vector2(44, 880),                                    # boca izquierda
		Vector2(38, 740), Vector2(40, 560), Vector2(70, 400),
		Vector2(130, 305), Vector2(200, 275), Vector2(270, 305),
		Vector2(330, 400), Vector2(360, 560), Vector2(362, 740),
		Vector2(356, 880),                                   # boca derecha
	])
	var r := Rampa.new(control)
	r.entrada_radio = p.rampa_entrada_radio
	r.velocidad_minima = p.rampa_velocidad_minima
	rampas.append(r)

func _platillo(centro: Vector2, direccion: Vector2) -> void:
	platillos.append(Platillo.new(centro, direccion, p.platillo_radio,
		p.platillo_tiempo, p.platillo_impulso))

func _girador(centro: Vector2) -> void:
	giradores.append(centro)
	_girador_dentro.append(false)

## Los giradores no colisionan: la bola los atraviesa. Se disparan al ENTRAR,
## una vez por pasada, así que mientras la bola siga dentro no vuelven a avisar.
func _avanzar_giradores() -> void:
	for i in giradores.size():
		var dentro := bola.viva \
			and bola.pos.distance_to(giradores[i]) < p.girador_radio
		if dentro and not _girador_dentro[i] \
				and bola.velocidad() >= p.girador_velocidad_minima:
			girador_girado.emit(giradores[i], i, bola.velocidad())
		_girador_dentro[i] = dentro

## Vuelve a poner todos los targets en pie. Para empezar un combate nuevo.
func reiniciar_targets() -> void:
	for c in targets:
		c.activo = true
	for i in _reset_banco.size():
		_reset_banco[i] = 0.0

func centro_banco(indice: int) -> Vector2:
	var suma := Vector2.ZERO
	for c in bancos[indice]:
		suma += c.a
	return suma / float(bancos[indice].size())

func _abatir(c: Colisionador) -> void:
	c.activo = false
	target_abatido.emit(c.a, c.banco)
	for otro in bancos[c.banco]:
		if otro.activo:
			return
	_reset_banco[c.banco] = p.target_tiempo_reset
	banco_completado.emit(centro_banco(c.banco), c.banco)

func _avanzar_bancos(h: float) -> void:
	for i in _reset_banco.size():
		if _reset_banco[i] <= 0.0:
			continue
		_reset_banco[i] -= h
		if _reset_banco[i] <= 0.0:
			for c in bancos[i]:
				c.activo = true

func _poste(centro: Vector2) -> Colisionador:
	var c := Colisionador.new(centro, centro, p.poste_radio, Colisionador.Tipo.POSTE,
		p.poste_rebote, p.poste_empuje, p.poste_velocidad_minima)
	colisionadores.append(c)
	postes.append(centro)
	return c

# ------------------------------------------------------------------- bola/juego

func nueva_bola() -> void:
	bola.pos = p.inicio_bola
	bola.vel = Vector2.ZERO
	bola.viva = true
	bola.en_carril = true
	bola.rampa = -1
	bola.platillo = -1
	carga_lanzador = 0.0
	cargando = false
	_temporizador_busqueda = 0.0

func cargar_lanzador(dt: float) -> void:
	if not (bola.viva and bola.en_carril):
		return
	cargando = true
	carga_lanzador = minf(carga_lanzador + dt / p.tiempo_carga_lanzador, 1.0)

func soltar_lanzador() -> void:
	if not cargando:
		return
	cargando = false
	if bola.viva and bola.en_carril:
		var ratio := p.ratio_minimo_lanzador + (1.0 - p.ratio_minimo_lanzador) * carga_lanzador
		bola.vel.y -= p.impulso_lanzador * ratio
	carga_lanzador = 0.0

# ---------------------------------------------------------------------- avance

func avanzar(dt: float) -> void:
	var h := dt / float(p.subpasos)
	for _i in p.subpasos:
		_subpaso(h)

func _subpaso(h: float) -> void:
	flipper_izq.avanzar(h)
	flipper_der.avanzar(h)
	_avanzar_bancos(h)
	if not bola.viva:
		return

	# Enganchada a una curva o capturada en un platillo: aquí no hay física.
	if bola.rampa >= 0:
		_avanzar_rampa(h)
		return
	if bola.platillo >= 0:
		_avanzar_platillo(h)
		return

	bola.vel.y += p.gravedad * h
	bola.vel *= exp(-p.rozamiento * h)
	_limitar_velocidad()
	bola.pos += bola.vel * h

	_colisionar()
	_avanzar_giradores()
	_comprobar_rampas()
	_comprobar_platillos()
	_actualizar_estado()
	_ball_search(h)

# ------------------------------------------------------------ rampas

## La bola recorre la curva a la velocidad con la que entró, constante. Es a
## propósito: determinista, sabes cuánto tarda y no hay forma de que se atasque
## a mitad de rampa.
func _avanzar_rampa(h: float) -> void:
	var r := rampas[bola.rampa]
	bola.rampa_distancia += bola.rampa_velocidad * float(bola.rampa_sentido) * h
	if bola.rampa_distancia > 0.0 and bola.rampa_distancia < r.largo:
		bola.pos = r.punto_en(bola.rampa_distancia)
		return
	# Salida: vuelve a la física con la velocidad tangente.
	var d := clampf(bola.rampa_distancia, 0.0, r.largo)
	var indice := bola.rampa
	bola.pos = r.punto_en(d)
	bola.vel = r.tangente_en(d) * float(bola.rampa_sentido) * bola.rampa_velocidad
	bola.rampa = -1
	rampa_salida.emit(bola.pos, indice)

func _comprobar_rampas() -> void:
	if not bola.libre():
		return
	for i in rampas.size():
		var sentido := rampas[i].sentido_entrada(bola.pos, bola.vel)
		if sentido == 0:
			continue
		bola.rampa = i
		bola.rampa_sentido = sentido
		bola.rampa_velocidad = bola.velocidad()
		bola.rampa_distancia = 0.0 if sentido > 0 else rampas[i].largo
		bola.pos = rampas[i].punto_en(bola.rampa_distancia)
		bola.vel = Vector2.ZERO
		rampa_entrada.emit(bola.pos, i)
		return

# ------------------------------------------------------------ platillos

func _avanzar_platillo(h: float) -> void:
	bola.platillo_espera -= h
	if bola.platillo_espera > 0.0:
		return
	var pl := platillos[bola.platillo]
	var indice := bola.platillo
	bola.vel = pl.direccion * pl.impulso
	bola.pos = pl.centro + pl.direccion * (pl.radio + p.radio_bola + 1.0)
	bola.platillo = -1
	platillo_expulsado.emit(pl.centro, indice)

func _comprobar_platillos() -> void:
	if not bola.libre():
		return
	for i in platillos.size():
		if not platillos[i].captura(bola.pos):
			continue
		bola.platillo = i
		bola.platillo_espera = platillos[i].tiempo_captura
		bola.pos = platillos[i].centro
		bola.vel = Vector2.ZERO
		platillo_capturado.emit(platillos[i].centro, i)
		return

func _limitar_velocidad() -> void:
	var v := bola.vel.length()
	if v > p.velocidad_maxima:
		bola.vel *= p.velocidad_maxima / v

func _colisionar() -> void:
	_contactos.clear()
	for c in colisionadores:
		c.consultar(bola.pos, bola.vel, p.radio_bola, _contactos)
	flipper_izq.consultar(bola.pos, bola.vel, p.radio_bola, _contactos)
	flipper_der.consultar(bola.pos, bola.vel, p.radio_bola, _contactos)
	if _contactos.is_empty():
		return

	_tocando_flipper_sostenido = false
	var mas_profundo := _contactos[0]
	for c in _contactos:
		if c.profundidad > mas_profundo.profundidad:
			mas_profundo = c
		if c.origen is Flipper and (c.origen as Flipper).pulsado:
			_tocando_flipper_sostenido = true

	# --- ARREGLO 2: resolver POSICIÓN solo contra el contacto más profundo ---
	# Corregir contra todos los contactos a la vez es lo que acuñaba la bola:
	# cada colisionador la empujaba contra el otro. Con uno solo, y dejando
	# `tolerancia_posicion` px de penetración sin corregir, no hay pelea ni
	# vibración en reposo. Los impulsos de todos los contactos van después.
	if mas_profundo.profundidad > p.tolerancia_posicion:
		bola.pos += mas_profundo.normal * (mas_profundo.profundidad - p.tolerancia_posicion)

	_contactos.sort_custom(func(x: Contacto, y: Contacto) -> bool:
		return x.profundidad > y.profundidad)

	for c in _contactos:
		# Impulso contra la velocidad RELATIVA a la superficie. Esto es lo que
		# hace que un flipper en movimiento lance en vez de rebotar.
		var v_rel := bola.vel - c.velocidad_superficie
		var vn := v_rel.dot(c.normal)
		if vn >= 0.0:
			continue    # ya se separa: no dupliques el rebote en las juntas
		var velocidad := -vn
		var e := c.restitucion
		var empuje := 0.0
		if c.empuje > 0.0:
			if velocidad >= c.velocidad_minima:
				empuje = c.empuje
			else:
				e = p.rebote_pared   # por debajo del umbral el interruptor no salta
		bola.vel += c.normal * (-(1.0 + e) * vn + empuje)
		_avisar(c, velocidad, empuje)
	_limitar_velocidad()

## Los avisos son la fuente del daño del combate, así que tienen que salir UNA
## vez por golpe de verdad. Sin el filtro, una bola rodando apoyada en un bumper
## emitía un aviso por subpaso: 480 golpes por segundo.
func _avisar(c: Contacto, fuerza: float, empuje: float) -> void:
	match c.tipo:
		Colisionador.Tipo.BUMPER:
			if empuje > 0.0:
				bumper_golpeado.emit(c.punto, fuerza)
		Colisionador.Tipo.SLINGSHOT:
			if empuje > 0.0:
				slingshot_golpeado.emit(c.punto, fuerza)
		Colisionador.Tipo.POSTE:
			if empuje > 0.0:
				poste_golpeado.emit(c.punto, fuerza)
		Colisionador.Tipo.FLIPPER:
			if fuerza >= 50.0:
				flipper_golpeado.emit(c.punto, fuerza)
		Colisionador.Tipo.TARGET:
			# El target se abate y deja de colisionar, así que no se repite.
			var col := c.origen as Colisionador
			if col.activo and fuerza >= col.velocidad_minima:
				_abatir(col)

func _actualizar_estado() -> void:
	if bola.en_carril and bola.pos.y < _v(0, 295).y:
		bola.en_carril = false
	var fuera := bola.pos.x < -60.0 or bola.pos.x > ANCHO + 60.0 \
		or bola.pos.y < -60.0 or bola.pos.y > p.y_drenaje
	if fuera:
		bola.viva = false
		bola.vel = Vector2.ZERO
		bola_drenada.emit()

# --- ARREGLO 3: ball search ---
# Si la bola se queda por debajo de `busqueda_velocidad` durante
# `busqueda_tiempo`, empujón automático. Las máquinas reales lo hacen.
func _ball_search(h: float) -> void:
	if not bola.viva or bola.en_carril:
		_temporizador_busqueda = 0.0
		return
	if p.busqueda_ignora_flipper_sostenido and _tocando_flipper_sostenido:
		_temporizador_busqueda = 0.0
		return
	if bola.vel.length() >= p.busqueda_velocidad:
		_temporizador_busqueda = 0.0
		return
	_temporizador_busqueda += h
	if _temporizador_busqueda < p.busqueda_tiempo:
		return
	_temporizador_busqueda = 0.0
	var ang := -PI * 0.5 + rng.randf_range(-p.busqueda_dispersion, p.busqueda_dispersion)
	bola.vel += Vector2(cos(ang), sin(ang)) * p.busqueda_impulso
	_limitar_velocidad()
	busqueda_bola.emit(bola.pos)
