class_name VistaMesa
extends Node2D

## Banco de pruebas del combate. Dibuja la simulación y la deja jugar.
##
## OJO: esto NO es la cáscara de TILT OS. No hay ventanas de XP, ni barra de
## tareas, ni mapa, ni reliquias. Solo la mesa, un enemigo y el bucle de un
## combate hasta que uno de los dos muera. Las paredes y los flippers se dibujan
## por código; bumpers, postes, targets, bola y enemigo van con sprite.

# Paleta cerrada (CONTEXTO.md).
const C_CABINA      := Color("14121A")
const C_MESA        := Color("2A2A33")
const C_MESA_BAJA   := Color("43434F")
const C_PARED       := Color("8C8D99")
const C_PARED_LUZ   := Color("B9BAC4")
const C_CARRIL      := Color("274A63")
const C_GOMA        := Color("8C2E2E")
const C_GOMA_LUZ    := Color("C74A3C")
const C_ORO         := Color("E0A63C")
const C_ORO_CLARO   := Color("F7D86B")
const C_TEXTO       := Color("B9BAC4")
const C_TEXTO_TENUE := Color("62636F")
const C_ARCANO      := Color("A97BD9")
const C_DRENAJE     := Color("4A3A42")
const C_VERDE       := Color("7BA84A")
const C_FLIPPER       := Color("2A2A33")
const C_FLIPPER_BORDE := Color("14121A")
const C_FLIPPER_LINEA := Color("E4E6EC")
const C_METAL         := Color("8C8D99")
const C_METAL_LUZ     := Color("E4E6EC")

## Los flippers van por código, no con sprite: se dibuja la misma cápsula que
## usa el colisionador, así que el arte sigue solo a `flipper_longitud` y
## `flipper_radio` mientras se ajusta el tacto.
const GROSOR_BORDE_FLIPPER := 1.5

## El enemigo vive en la parte alta del campo, detrás de los bumpers. Los
## sprites son 96x96 con los pies ya alineados dentro del marco, así que basta
## con posar el borde inferior del marco en el suelo.
const ENEMIGO_CENTRO_X := 200.0
const ENEMIGO_SUELO_Y := 158.0
const ALTO_TARGET := 30.0

var combate: Combate
var mesa: Mesa

var _catalogo: Array = []
var _indice_enemigo: int = 0
var _depuracion := false
var _sacudida: float = 0.0
var _tiempo: float = 0.0
var _flash_enemigo: float = 0.0
var _flash_jugador: float = 0.0
var _destellos: Array[Dictionary] = []
var _numeros: Array[Dictionary] = []

var _tex_bola: Texture2D
var _tex_poste: Texture2D
var _tex_bumper: Texture2D
var _tex_target: Array[Texture2D] = []
var _tex_enemigo: Texture2D
var _fuente: Font

func _ready() -> void:
	_fuente = ThemeDB.fallback_font
	_tex_bola = load("res://assets/mesa/bola.png")
	_tex_poste = load("res://assets/mesa/poste_goma.png")
	_tex_bumper = load("res://assets/mesa/bumper_gargola.png")
	_tex_target = [
		load("res://assets/mesa/target_escudo.png"),
		load("res://assets/mesa/target_lapida.png"),
	]

	combate = Combate.new()
	mesa = combate.mesa
	mesa.slingshot_golpeado.connect(_al_golpear_slingshot)
	mesa.poste_golpeado.connect(_al_golpear_poste)
	mesa.bumper_golpeado.connect(_al_golpear_bumper)
	mesa.busqueda_bola.connect(_al_buscar_bola)
	combate.dano_sumado.connect(_al_sumar_dano)
	combate.golpe_resuelto.connect(_al_resolver_golpe)
	combate.enemigo_ataca.connect(_al_atacar_enemigo)

	_catalogo = CatalogoEnemigos.cargar()
	if _catalogo.is_empty():
		push_error("Sin enemigos en data/enemigos.json")
		return
	_empezar_combate(0)

# ------------------------------------------------------------------- juego

func _empezar_combate(indice: int) -> void:
	_indice_enemigo = clampi(indice, 0, _catalogo.size() - 1)
	_tex_enemigo = load(str((_catalogo[_indice_enemigo] as Dictionary)["sprite"]))
	combate.iniciar(Enemigo.new(_catalogo[_indice_enemigo]))
	_destellos.clear()
	_numeros.clear()

func _physics_process(delta: float) -> void:
	mesa.flipper_izq.pulsado = Input.is_physical_key_pressed(KEY_A) \
		or Input.is_physical_key_pressed(KEY_LEFT) \
		or Input.is_physical_key_pressed(KEY_SHIFT)
	mesa.flipper_der.pulsado = Input.is_physical_key_pressed(KEY_D) \
		or Input.is_physical_key_pressed(KEY_RIGHT) \
		or Input.is_physical_key_pressed(KEY_CTRL)

	if Input.is_physical_key_pressed(KEY_SPACE):
		mesa.cargar_lanzador(delta)
	elif mesa.cargando:
		mesa.soltar_lanzador()

	combate.avanzar(delta)

func _process(delta: float) -> void:
	_tiempo += delta
	_sacudida = maxf(_sacudida - delta * 26.0, 0.0)
	_flash_enemigo = maxf(_flash_enemigo - delta * 2.2, 0.0)
	_flash_jugador = maxf(_flash_jugador - delta * 2.2, 0.0)
	position = Vector2(roundf(randf_range(-_sacudida, _sacudida)),
		roundf(randf_range(-_sacudida, _sacudida)))
	_destellos = _caducar(_destellos, delta)
	_numeros = _caducar(_numeros, delta)
	queue_redraw()

func _caducar(lista: Array[Dictionary], delta: float) -> Array[Dictionary]:
	var vivos: Array[Dictionary] = []
	for d in lista:
		d["t"] -= delta
		if d["t"] > 0.0:
			vivos.append(d)
	return vivos

func _unhandled_key_input(evento: InputEvent) -> void:
	var tecla := evento as InputEventKey
	if not tecla.pressed or tecla.echo:
		return
	match tecla.physical_keycode:
		KEY_R:
			_empezar_combate(_indice_enemigo)
		KEY_N:
			_empezar_combate((_indice_enemigo + 1) % _catalogo.size())
		KEY_F1:
			_depuracion = not _depuracion
		KEY_ESCAPE:
			get_tree().quit()

func _al_golpear_bumper(punto: Vector2, fuerza: float) -> void:
	_destellos.append({"pos": punto, "t": 0.16, "r": 26.0, "col": C_ORO})
	_sacudida = maxf(_sacudida, minf(fuerza / 260.0, 2.5))

func _al_golpear_slingshot(punto: Vector2, _fuerza: float) -> void:
	_destellos.append({"pos": punto, "t": 0.12, "r": 16.0, "col": C_GOMA_LUZ})

func _al_golpear_poste(punto: Vector2, _fuerza: float) -> void:
	_destellos.append({"pos": punto, "t": 0.10, "r": 14.0, "col": C_GOMA_LUZ})

func _al_buscar_bola(punto: Vector2) -> void:
	_destellos.append({"pos": punto, "t": 0.3, "r": 34.0, "col": C_ARCANO})
	_sacudida = 3.0

func _al_sumar_dano(_total: int, incremento: int, punto: Vector2) -> void:
	_numeros.append({"pos": punto, "t": 0.7, "texto": "+%d" % incremento, "col": C_ORO_CLARO})

func _al_resolver_golpe(dano: int) -> void:
	_flash_enemigo = 1.0
	_sacudida = maxf(_sacudida, 2.0 if dano > 0 else 0.0)

func _al_atacar_enemigo(_dano: int) -> void:
	_flash_jugador = 1.0
	_sacudida = 3.0

# ------------------------------------------------------------------- dibujo

func _draw() -> void:
	draw_rect(Rect2(0, 0, Mesa.ANCHO, Mesa.ALTO), C_CABINA)
	draw_rect(Rect2(20, 60, 360, 620), C_MESA)
	draw_rect(Rect2(20, 560, 360, 140), C_MESA_BAJA)
	draw_rect(Rect2(358, 300, 22, 360), C_CARRIL)
	draw_rect(Rect2(0, int(mesa.p.y_drenaje) - 8, Mesa.ANCHO, 8), C_DRENAJE)

	_dibujar_enemigo()
	_dibujar_inlanes()
	_dibujar_paredes()
	_dibujar_objetos()
	_dibujar_destellos()
	_dibujar_bola()
	_dibujar_numeros()
	if _depuracion:
		_dibujar_depuracion()
	_dibujar_hud()

func _dibujar_enemigo() -> void:
	if _tex_enemigo == null or combate.enemigo == null:
		return
	var alto := float(_tex_enemigo.get_height())
	var y := ENEMIGO_SUELO_Y - alto
	if combate.enemigo.flota:
		# La calavera llameante no se apoya en el suelo: flota con vaivén propio.
		y += -10.0 + sin(_tiempo * 2.2) * 3.0
	var tinte := Color.WHITE
	if not combate.enemigo.vivo():
		tinte = Color(0.45, 0.4, 0.45, 0.55)
	elif _flash_enemigo > 0.0:
		tinte = Color.WHITE.lerp(C_GOMA_LUZ, _flash_enemigo)
	draw_texture(_tex_enemigo,
		Vector2(ENEMIGO_CENTRO_X - _tex_enemigo.get_width() * 0.5, y).round(), tinte)

## Los carriles de retorno del arreglo 1, sombreados para que se lean.
func _dibujar_inlanes() -> void:
	var tinte := Color(C_CARRIL, 0.55)
	draw_line(Vector2(48, 494), Vector2(112, 578), tinte, 26.0)
	draw_line(Vector2(332, 480), Vector2(288, 578), tinte, 24.0)

func _dibujar_paredes() -> void:
	for c in mesa.colisionadores:
		match c.tipo:
			Colisionador.Tipo.PARED:
				draw_line(c.a, c.b, C_PARED, 3.0)
			Colisionador.Tipo.PUERTA:
				draw_line(c.a, c.b, C_ORO, 2.0)
			Colisionador.Tipo.SLINGSHOT:
				draw_line(c.a, c.b, C_GOMA, 6.0)
				draw_line(c.a, c.b, C_GOMA_LUZ, 2.0)

func _dibujar_objetos() -> void:
	for c in mesa.targets:
		if c.activo:
			_dibujar_sprite_centrado(_tex_target[c.banco % _tex_target.size()],
				c.a, ALTO_TARGET, 60.0)
		else:
			# Abatido: se ve la ranura por la que ha bajado.
			draw_rect(Rect2(c.a.x - 11, c.a.y + 8, 22, 3), C_CABINA)
	for centro in mesa.bumpers:
		_dibujar_sprite_centrado(_tex_bumper, centro, mesa.p.bumper_radio * 2.0, 60.0)
	# Los postes van ANTES que los flippers: solapan con la cápsula del eje (es
	# lo que sella el hueco del atasco) y dibujar la pala encima deja el perno
	# del pivote a la vista.
	for centro in mesa.postes:
		_dibujar_sprite_centrado(_tex_poste, centro, mesa.p.poste_radio * 2.0, 60.0)
	_dibujar_flipper(mesa.flipper_izq)
	_dibujar_flipper(mesa.flipper_der)

## Los objetos fijos se pegan a la rejilla de píxeles.
func _dibujar_sprite_centrado(tex: Texture2D, centro: Vector2, tamano: float, visible_px: float) -> void:
	var escala := tamano / visible_px
	var mitad := Vector2(tex.get_width(), tex.get_height()) * 0.5
	draw_set_transform(centro.round(), 0.0, Vector2(escala, escala))
	draw_texture(tex, -mitad)
	draw_set_transform_matrix(Transform2D.IDENTITY)

## Cápsula idéntica a la del colisionador: mismo eje, misma punta, mismo radio.
func _dibujar_flipper(f: Flipper) -> void:
	var punta := f.punta()
	var r := f.radio
	var borde := r + GROSOR_BORDE_FLIPPER

	draw_line(f.eje, punta, C_FLIPPER_BORDE, borde * 2.0)
	draw_circle(f.eje, borde, C_FLIPPER_BORDE)
	draw_circle(punta, borde, C_FLIPPER_BORDE)

	draw_line(f.eje, punta, C_FLIPPER, r * 2.0)
	draw_circle(f.eje, r, C_FLIPPER)
	draw_circle(punta, r, C_FLIPPER)

	var dir := (punta - f.eje) / f.longitud
	draw_line(f.eje + dir * (r * 1.6), punta - dir * (r * 0.8), C_FLIPPER_LINEA, 1.0)

	# Perno del pivote.
	draw_circle(f.eje, r * 0.62, C_MESA_BAJA)
	draw_circle(f.eje, r * 0.46, C_METAL)
	draw_circle(f.eje + Vector2(-1, -1), r * 0.18, C_METAL_LUZ)

## La bola NO se pega a la rejilla: a 1500 px/s tiritaría de forma horrible.
func _dibujar_bola() -> void:
	if not mesa.bola.viva:
		return
	var escala := mesa.p.radio_bola * 2.0 / 20.0
	var mitad := Vector2(_tex_bola.get_width(), _tex_bola.get_height()) * 0.5
	draw_set_transform(mesa.bola.pos, 0.0, Vector2(escala, escala))
	draw_texture(_tex_bola, -mitad)
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _dibujar_destellos() -> void:
	for d in _destellos:
		var col: Color = d["col"]
		col.a = clampf(d["t"] * 4.0, 0.0, 0.8)
		draw_circle(d["pos"], d["r"] * (1.4 - d["t"]), col, false, 2.0)

func _dibujar_numeros() -> void:
	for d in _numeros:
		var col: Color = d["col"]
		col.a = clampf(d["t"] * 2.0, 0.0, 1.0)
		var subida: float = (0.7 - float(d["t"])) * 22.0
		draw_string(_fuente, (d["pos"] as Vector2) + Vector2(-10, -10 - subida),
			d["texto"], HORIZONTAL_ALIGNMENT_CENTER, 20, 9, col)

func _dibujar_depuracion() -> void:
	for c in mesa.colisionadores:
		if not c.activo:
			continue
		if c.a.is_equal_approx(c.b):
			draw_circle(c.a, c.radio, C_ARCANO, false, 1.0)
		else:
			draw_line(c.a, c.b, C_ARCANO, 1.0)
	for f in [mesa.flipper_izq, mesa.flipper_der]:
		draw_line(f.eje, f.punta(), C_ARCANO, 1.0)
		draw_circle(f.eje, f.radio, C_ARCANO, false, 1.0)
		draw_circle(f.punta(), f.radio, C_ARCANO, false, 1.0)
	if mesa.bola.viva:
		draw_circle(mesa.bola.pos, mesa.p.radio_bola, C_ORO, false, 1.0)
		draw_line(mesa.bola.pos, mesa.bola.pos + mesa.bola.vel * 0.08, C_ORO, 1.0)

# ---------------------------------------------------------------------- HUD

func _barra(rect: Rect2, proporcion: float, color: Color) -> void:
	draw_rect(rect, C_CABINA)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(proporcion, 0.0, 1.0),
		rect.size.y)), color)

func _dibujar_hud() -> void:
	var e := combate.enemigo
	if e != null:
		draw_string(_fuente, Vector2(22, 16), e.nombre,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, C_TEXTO)
		draw_string(_fuente, Vector2(0, 16), "%d/%d" % [e.vida, e.vida_maxima],
			HORIZONTAL_ALIGNMENT_RIGHT, 378, 10, C_TEXTO_TENUE)
		var col_enemigo := C_GOMA_LUZ if _flash_enemigo <= 0.0 else C_ORO_CLARO
		_barra(Rect2(22, 22, 356, 8), float(e.vida) / float(e.vida_maxima), col_enemigo)

	var col_jugador := C_VERDE if _flash_jugador <= 0.0 else C_GOMA_LUZ
	draw_string(_fuente, Vector2(22, 654),
		"VIDA %d/%d" % [combate.vida_jugador, combate.p.vida_jugador],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, C_TEXTO)
	_barra(Rect2(22, 658, 160, 7),
		float(combate.vida_jugador) / float(combate.p.vida_jugador), col_jugador)

	draw_string(_fuente, Vector2(210, 654), "DANO ACUMULADO  %d" % combate.dano_pendiente,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
		C_ORO_CLARO if combate.dano_pendiente > 0 else C_TEXTO_TENUE)

	if mesa.cargando or mesa.carga_lanzador > 0.0:
		draw_rect(Rect2(366, 600, 6, 50), C_CABINA)
		var alto := 50.0 * mesa.carga_lanzador
		draw_rect(Rect2(366, 650 - alto, 6, alto), C_ORO)

	_dibujar_mensaje()
	draw_string(_fuente, Vector2(22, 690),
		"A/D flippers  ESPACIO lanzar  R reiniciar  N otro enemigo  F1 colisiones",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, C_TEXTO_TENUE)

func _dibujar_mensaje() -> void:
	var texto := ""
	var col := C_TEXTO
	match combate.fase:
		Combate.Fase.LANZANDO:
			if mesa.bola.viva and mesa.bola.en_carril:
				texto = "ESPACIO: mantener y soltar para lanzar"
				col = C_TEXTO_TENUE
		Combate.Fase.RESOLVIENDO_GOLPE:
			texto = "GOLPE  -%d" % combate.ultimo_golpe
			col = C_ORO_CLARO
		Combate.Fase.RESOLVIENDO_ATAQUE:
			texto = "%s ATACA  -%d" % [combate.enemigo.nombre.to_upper(), combate.ultimo_ataque]
			col = C_GOMA_LUZ
		Combate.Fase.VICTORIA:
			texto = "VICTORIA"
			col = C_VERDE
		Combate.Fase.DERROTA:
			texto = "DERROTA"
			col = C_GOMA_LUZ
	if texto == "":
		return
	draw_string(_fuente, Vector2(0, 400), texto, HORIZONTAL_ALIGNMENT_CENTER,
		Mesa.ANCHO, 14, col)
	if combate.terminado():
		draw_string(_fuente, Vector2(0, 420), "R para repetir  ·  N para otro enemigo",
			HORIZONTAL_ALIGNMENT_CENTER, Mesa.ANCHO, 9, C_TEXTO_TENUE)
