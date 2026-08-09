class_name Mesa
extends RefCounted

## Simulación de la mesa. Sin dependencias del motor más allá de Vector2:
## se puede ejecutar entera en headless (ver tests/prueba_sim.gd).
##
## Lienzo 400 x 700, Y hacia abajo.

signal bumper_golpeado(punto: Vector2, fuerza: float)
signal slingshot_golpeado(punto: Vector2, fuerza: float)
signal poste_golpeado(punto: Vector2, fuerza: float)
signal flipper_golpeado(punto: Vector2, fuerza: float)
signal target_abatido(punto: Vector2, banco: int)
signal banco_completado(punto: Vector2, banco: int)
signal bola_drenada()
signal busqueda_bola(punto: Vector2)

const ANCHO := 400.0
const ALTO := 700.0
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

func _construir() -> void:
	_construir_arco()

	# Paredes laterales del campo de juego.
	_pared(Vector2(20, 130), Vector2(20, 480))
	_pared(Vector2(380, 130), Vector2(380, 660))   # exterior del carril lanzador

	# --- Carril lanzador ---
	# El tramo bajo se estrecha a 22 px para dejar sitio al inlane derecho.
	# La bola (18 px) sigue pasando holgada.
	_pared(Vector2(350, 300), Vector2(350, 440))
	_pared(Vector2(350, 440), Vector2(355, 458))
	_pared(Vector2(355, 458), Vector2(358, 470))
	_pared(Vector2(358, 470), Vector2(358, 660))
	_pared(Vector2(358, 660), Vector2(380, 660))   # suelo del carril
	# Puerta antirretorno. Inclinada a propósito: una bola que cae encima rueda
	# hacia la izquierda y entra al campo en vez de quedarse parada en la repisa.
	var puerta := _pared(Vector2(350, 304), Vector2(380, 296))
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
	_pared(Vector2(20, 480), Vector2(99, 584))          # retorno izquierdo
	_slingshot(Vector2(75, 505), Vector2(128, 575))
	_poste(Vector2(102, 596))

	_pared(Vector2(355, 458), Vector2(301, 584))        # retorno derecho
	_slingshot(Vector2(306, 512), Vector2(262, 582))
	_poste(Vector2(298, 596))

	# --- Bumpers ---
	_bumper(Vector2(140, 225))
	_bumper(Vector2(260, 225))
	_bumper(Vector2(200, 165))

	# --- Bancos de targets ---
	# Pegados a las paredes pero sin sellarlas: quedan 23 px de carril por fuera
	# (la bola mide 18) para poder seguir bajando al inlane con el banco en pie.
	# Entre target y target solo quedan 14 px, así que por ahí no se cuela.
	_banco_targets(Vector2(56, 320), Vector2(56, 400), 3)
	_banco_targets(Vector2(314, 320), Vector2(314, 400), 3)

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
		arco.append(Vector2(200.0 + 180.0 * cos(t), 130.0 - 70.0 * sin(t)))
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

	bola.vel.y += p.gravedad * h
	bola.vel *= exp(-p.rozamiento * h)
	_limitar_velocidad()
	bola.pos += bola.vel * h

	_colisionar()
	_actualizar_estado()
	_ball_search(h)

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
	if bola.en_carril and bola.pos.y < 295.0:
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
