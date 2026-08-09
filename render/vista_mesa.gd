class_name VistaMesa
extends Node2D

## Banco de pruebas de la mesa. Dibuja la simulación y la deja jugar.
##
## OJO: esto NO es la cáscara de TILT OS. Aquí solo hay mesa. Las paredes se
## dibujan por código porque no tienen sprite; los objetos de mesa (bumpers,
## postes, flippers, bola) van con los sprites de assets/mesa. La ventana de XP,
## la barra de tareas y todo lo demás son otra capa y vienen después.

const BOLAS_POR_COMBATE := 3
const RETARDO_NUEVA_BOLA := 0.7

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
const C_TEXTO       := Color("B9BAC4")
const C_TEXTO_TENUE := Color("62636F")
const C_ARCANO      := Color("A97BD9")
const C_DRENAJE     := Color("4A3A42")

# flipper_der.png tiene el eje en el píxel (14,32) y la punta en (62,32): apunta
# a +X. flipper_izq.png es ese mismo reflejado, así que su eje cae en (50,32),
# su punta en (2,32) y apunta a -X.
#
# El flipper IZQUIERDO de la mesa apunta a +X (reposo 28°) y el DERECHO a -X
# (reposo 152°), o sea que los ficheros van al revés que la geometría. Y al
# sprite que apunta a -X hay que sumarle 180° de giro base: su dirección natural
# ya es -X, y rotarlo por `angulo` a secas lo manda arriba-derecha, al carril
# lanzador. Sumar PI (en vez de reflejar en Y) deja el sombreado bien.
const SPRITE_FLIPPER_IZQ := {
	"tex": "res://assets/mesa/flipper_der.png",
	"eje": Vector2(14, 32), "punta": Vector2(62, 32), "giro_base": 0.0,
}
const SPRITE_FLIPPER_DER := {
	"tex": "res://assets/mesa/flipper_izq.png",
	"eje": Vector2(50, 32), "punta": Vector2(2, 32), "giro_base": PI,
}
## PENDIENTE DE ARTE: el sprite mide 48 px de largo por 28 de grueso en la base
## (1,7:1). La cápsula validada mide 78 x 16 (4,9:1). Se escala por LARGO, para
## que la bola golpee donde se ve que está el flipper; el precio es que la base
## se ve gorda. Lo suyo es redibujar el flipper más largo y más fino.
const LARGO_SPRITE_FLIPPER := 48.0

## La transformación con la que se dibuja un flipper. Está aparte y es estática
## para poder comprobar en headless que la punta del sprite cae sobre la punta
## de la cápsula (tests/prueba_sim.gd). Mirar la captura no vale: así se me coló
## el flipper derecho girado 180°.
static func transformada_flipper(angulo: float, eje_mundo: Vector2,
		longitud: float, giro_base: float) -> Transform2D:
	var escala := longitud / LARGO_SPRITE_FLIPPER
	return Transform2D(angulo + giro_base, Vector2(escala, escala), 0.0, eje_mundo)

var mesa: Mesa
var bolas_restantes: int = BOLAS_POR_COMBATE
var _espera_bola: float = -1.0
var _depuracion := false
var _sacudida: float = 0.0
var _destellos: Array[Dictionary] = []

var _tex_bola: Texture2D
var _tex_poste: Texture2D
var _tex_bumper: Texture2D
var _tex_flipper_izq: Texture2D
var _tex_flipper_der: Texture2D
var _fuente: Font

func _ready() -> void:
	_fuente = ThemeDB.fallback_font
	_tex_bola = load("res://assets/mesa/bola.png")
	_tex_poste = load("res://assets/mesa/poste_goma.png")
	_tex_bumper = load("res://assets/mesa/bumper_gargola.png")
	_tex_flipper_izq = load(SPRITE_FLIPPER_IZQ["tex"])
	_tex_flipper_der = load(SPRITE_FLIPPER_DER["tex"])

	mesa = Mesa.new()
	mesa.bumper_golpeado.connect(_al_golpear_bumper)
	mesa.slingshot_golpeado.connect(_al_golpear_slingshot)
	mesa.poste_golpeado.connect(_al_golpear_poste)
	mesa.busqueda_bola.connect(_al_buscar_bola)
	mesa.bola_drenada.connect(_al_drenar)
	mesa.nueva_bola()

# ------------------------------------------------------------------- juego

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

	mesa.avanzar(delta)

	if _espera_bola > 0.0:
		_espera_bola -= delta
		if _espera_bola <= 0.0:
			_espera_bola = -1.0
			mesa.nueva_bola()

func _process(delta: float) -> void:
	_sacudida = maxf(_sacudida - delta * 26.0, 0.0)
	position = Vector2(roundf(randf_range(-_sacudida, _sacudida)),
		roundf(randf_range(-_sacudida, _sacudida)))
	var vivos: Array[Dictionary] = []
	for d in _destellos:
		d["t"] -= delta
		if d["t"] > 0.0:
			vivos.append(d)
	_destellos = vivos
	queue_redraw()

func _unhandled_key_input(evento: InputEvent) -> void:
	var tecla := evento as InputEventKey
	if not tecla.pressed or tecla.echo:
		return
	match tecla.physical_keycode:
		KEY_R:
			bolas_restantes = BOLAS_POR_COMBATE
			_espera_bola = -1.0
			mesa.nueva_bola()
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
	# Arreglo 3: la máquina se sacude sola, como las de verdad.
	_destellos.append({"pos": punto, "t": 0.3, "r": 34.0, "col": C_ARCANO})
	_sacudida = 3.0

func _al_drenar() -> void:
	bolas_restantes -= 1
	if bolas_restantes > 0:
		_espera_bola = RETARDO_NUEVA_BOLA

# ------------------------------------------------------------------- dibujo

func _draw() -> void:
	draw_rect(Rect2(0, 0, Mesa.ANCHO, Mesa.ALTO), C_CABINA)
	draw_rect(Rect2(20, 60, 360, 620), C_MESA)
	draw_rect(Rect2(20, 560, 360, 140), C_MESA_BAJA)
	draw_rect(Rect2(358, 300, 22, 360), C_CARRIL)
	draw_rect(Rect2(0, int(mesa.p.y_drenaje) - 8, Mesa.ANCHO, 8), C_DRENAJE)

	_dibujar_inlanes()
	_dibujar_paredes()
	_dibujar_objetos()
	_dibujar_destellos()
	_dibujar_bola()
	if _depuracion:
		_dibujar_depuracion()
	_dibujar_hud()

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
	for centro in mesa.bumpers:
		_dibujar_sprite_redondo(_tex_bumper, centro, mesa.p.bumper_radio * 2.0, 60.0)
	_dibujar_flipper(mesa.flipper_izq, _tex_flipper_izq, SPRITE_FLIPPER_IZQ)
	_dibujar_flipper(mesa.flipper_der, _tex_flipper_der, SPRITE_FLIPPER_DER)
	# Los postes van DESPUÉS de los flippers: solapan con la cápsula del eje (es
	# lo que sella el hueco del atasco) y si se dibujan antes quedan tapados.
	for centro in mesa.postes:
		_dibujar_sprite_redondo(_tex_poste, centro, mesa.p.poste_radio * 2.0, 60.0)

## Los objetos fijos se pegan a la rejilla de píxeles.
func _dibujar_sprite_redondo(tex: Texture2D, centro: Vector2, diametro: float, visible_px: float) -> void:
	var escala := diametro / visible_px
	var mitad := Vector2(tex.get_width(), tex.get_height()) * 0.5
	draw_set_transform(centro.round(), 0.0, Vector2(escala, escala))
	draw_texture(tex, -mitad)
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _dibujar_flipper(f: Flipper, tex: Texture2D, desc: Dictionary) -> void:
	draw_set_transform_matrix(
		transformada_flipper(f.angulo, f.eje, f.longitud, desc["giro_base"]))
	draw_texture(tex, -(desc["eje"] as Vector2))
	draw_set_transform_matrix(Transform2D.IDENTITY)

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

func _dibujar_depuracion() -> void:
	for c in mesa.colisionadores:
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

func _dibujar_hud() -> void:
	for i in bolas_restantes:
		draw_circle(Vector2(12 + i * 11, 690), 4.0, C_PARED_LUZ)

	if mesa.cargando or mesa.carga_lanzador > 0.0:
		draw_rect(Rect2(366, 600, 6, 50), C_CABINA)
		var alto := 50.0 * mesa.carga_lanzador
		draw_rect(Rect2(366, 650 - alto, 6, alto), C_ORO)

	var estado := ""
	if bolas_restantes <= 0 and not mesa.bola.viva:
		estado = "SIN BOLAS  ·  R para reiniciar"
	elif mesa.bola.viva and mesa.bola.en_carril:
		estado = "ESPACIO mantener y soltar para lanzar"
	if estado != "":
		draw_string(_fuente, Vector2(10, 20), estado,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9, C_TEXTO)

	draw_string(_fuente, Vector2(10, 680),
		"A/D flippers   ESPACIO lanzar   R nueva bola   F1 colisiones",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, C_TEXTO_TENUE)
	if _depuracion:
		draw_string(_fuente, Vector2(10, 34),
			"v %.0f px/s" % mesa.bola.velocidad(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, C_ORO)
