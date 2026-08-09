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
const C_FUEGO       := Color("E8814A")

## El multiplicador va grande, en el hueco entre los slingshots y los flippers,
## que es donde tienes puesto el ojo mientras juegas. Se dibuja pegado al suelo,
## por debajo de paredes, objetos y bola, así que nunca tapa el juego: lo que
## hace que se vea es que se enciende conforme sube.
## Y no más abajo: con los flippers levantados las palas llegan a y=559 y se
## comían la línea de debajo del número.
const COMBO_CENTRO := Vector2(200, 520)
const COMBO_TAMANO := 46
const COMBO_ESTILO := {
	1: {"col": C_TEXTO_TENUE, "alfa": 0.22},
	2: {"col": C_ORO,         "alfa": 0.45},
	3: {"col": C_ORO_CLARO,   "alfa": 0.62},
	4: {"col": C_FUEGO,       "alfa": 0.82},
}
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

## El campo de juego, donde va el suelo de piedra.
const CAMPO := Rect2(20, 60, 360, 620)
## Por donde cae la bola al drenar, bajo los flippers. Nada de adornos aquí
## salvo la rejilla, que va justo ahí a propósito.
const CORREDOR_DRENAJE := Rect2(170, 600, 60, 100)

## Adornos del suelo, puestos a mano.
##
## Los de "zona muerta" están en sitios a los que la bola no puede llegar: bajo
## los carriles de retorno, que quedan sellados por los postes de goma. Los del
## final son campo abierto, que la bola cruza pero donde no se queda.
##
## Escalas de 1.0 o 0.5 y espejo en vez de giros libres: rotar pixelart en
## ángulos sueltos rompe la rejilla de píxeles y se nota.
## `muerta` marca los que están en sitios a los que la bola NO PUEDE llegar.
## No es una intención: está medido, esos ocho dan 0,00 % de ocupación en las
## partidas aleatorias de tests/prueba_sim.gd, y la prueba lo exige.
const ADORNOS := [
	# zona muerta bajo el carril de retorno izquierdo
	{"tex": "grieta",       "pos": Vector2(56, 612),  "escala": 1.0, "espejo": false, "muerta": true},
	{"tex": "huesos",       "pos": Vector2(50, 652),  "escala": 1.0, "espejo": true,  "muerta": true},
	{"tex": "musgo",        "pos": Vector2(88, 640),  "escala": 0.5, "espejo": false, "muerta": true},
	# zona muerta bajo el carril de retorno derecho
	{"tex": "baldosa_rota", "pos": Vector2(326, 616), "escala": 1.0, "espejo": true,  "muerta": true},
	{"tex": "mancha",       "pos": Vector2(324, 651), "escala": 1.0, "espejo": false, "muerta": true},
	{"tex": "musgo",        "pos": Vector2(342, 630), "escala": 0.5, "espejo": true,  "muerta": true},
	# franja bajo los flippers, a los lados del corredor de drenaje
	{"tex": "remaches",     "pos": Vector2(126, 664), "escala": 1.0, "espejo": false, "muerta": true},
	{"tex": "remaches",     "pos": Vector2(274, 664), "escala": 1.0, "espejo": true,  "muerta": true},
	# la rejilla, en el drenaje: aquí sí pasa la bola, y es el sitio que le toca
	{"tex": "rejilla",      "pos": Vector2(200, 650), "escala": 1.0, "espejo": false, "muerta": false},
	# campo alto. La bola vive abajo, así que aquí arriba apenas pasa: 2,6 % y
	# 0,5 % de los fotogramas. Sitios sacados del mapa de ocupación, no a ojo.
	{"tex": "espiral",      "pos": Vector2(128, 300), "escala": 1.0, "espejo": false, "muerta": false},
	{"tex": "sigilo",       "pos": Vector2(285, 130), "escala": 1.0, "espejo": false, "muerta": false},
]

## Rectángulo que ocupa un adorno en la mesa, contando solo su parte opaca:
## varios sprites tienen relleno transparente y medir el marco de 64x64 daría
## una caja mucho mayor de la que se ve.
static func caja_adorno(adorno: Dictionary, tex: Texture2D) -> Rect2:
	var usado := tex.get_image().get_used_rect()
	var escala: float = adorno["escala"]
	var centro: Vector2 = adorno["pos"]
	var origen := centro - Vector2(tex.get_width(), tex.get_height()) * 0.5 * escala
	return Rect2(origen + Vector2(usado.position) * escala,
		Vector2(usado.size) * escala)

var combate: Combate
var mesa: Mesa
var anim := ParametrosAnimacion.new()
var cam := ParametrosCamara.new()
var camara: CamaraMesa

const TAMANO_GIRADOR := 32

var _catalogo: Array = []
var _indice_enemigo: int = 0
var _depuracion := false
var _sacudida: float = 0.0
var _tiempo: float = 0.0
var flash_enemigo: float = 0.0
var flash_jugador: float = 0.0
var _hitstop: float = 0.0
var _rng := RandomNumberGenerator.new()
var _nodo_suelo: NodoSuelo
var _nodo_enemigo: NodoEnemigo
var _tex_girador: Array[Texture2D] = []
var _giro: Array[float] = []
var _giro_velocidad: Array[float] = []
var _flash_bumper: Array[float] = []
var _destellos: Array[Dictionary] = []
var _numeros: Array[Dictionary] = []

var _tex_bola: Texture2D
var _tex_poste: Texture2D
var _tex_bumper: Texture2D
var _tex_target: Array[Texture2D] = []
var _tex_enemigo: Texture2D
var _fuente: Font

func _ready() -> void:
	# El suelo se dibuja repitiendo la baldosa de 128x128, así que este
	# CanvasItem tiene que permitir repetición de textura.
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_fuente = ThemeDB.fallback_font
	_tex_bola = load("res://assets/mesa/bola.png")
	_tex_poste = load("res://assets/mesa/poste_goma.png")
	_tex_bumper = load("res://assets/mesa/bumper_gargola.png")
	_tex_target = [
		load("res://assets/mesa/target_escudo.png"),
		load("res://assets/mesa/target_lapida.png"),
	]
	_tex_girador = Girador.generar(load("res://assets/mesa/girador.png"),
		anim.girador_fotogramas, TAMANO_GIRADOR)

	combate = Combate.new()
	mesa = combate.mesa
	mesa.slingshot_golpeado.connect(_al_golpear_slingshot)
	mesa.poste_golpeado.connect(_al_golpear_poste)
	mesa.bumper_golpeado.connect(_al_golpear_bumper)
	mesa.busqueda_bola.connect(_al_buscar_bola)
	mesa.girador_girado.connect(_al_girar_girador)
	combate.dano_infligido.connect(_al_infligir_dano)
	combate.combo_cambiado.connect(_al_cambiar_combo)
	combate.enemigo_ataca.connect(_al_atacar_enemigo)
	combate.combate_terminado.connect(_al_terminar_combate)

	_giro.resize(mesa.giradores.size())
	_giro_velocidad.resize(mesa.giradores.size())
	_flash_bumper.resize(mesa.bumpers.size())
	add_child(NodoEscritorio.new(cam))
	_nodo_suelo = NodoSuelo.new(self)
	add_child(_nodo_suelo)
	_nodo_enemigo = NodoEnemigo.new(anim)
	add_child(_nodo_enemigo)

	camara = CamaraMesa.new(cam, Mesa.ALTO, Mesa.ANCHO * 0.5)
	add_child(camara)
	camara.make_current()
	add_child(NodoHud.new(self, cam))

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
	_nodo_enemigo.suelo = Vector2(ENEMIGO_CENTRO_X, ENEMIGO_SUELO_Y)
	_nodo_enemigo.configurar(_tex_enemigo, combate.enemigo.flota)
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

	# HITSTOP: se congela la SIMULACIÓN, no el dibujado. La capa visual sigue
	# corriendo durante el parón, así que el destello y la sacudida se ven
	# mientras el juego está quieto, que es lo que hace que el golpe suene seco.
	if _hitstop > 0.0:
		_hitstop = maxf(_hitstop - delta, 0.0)
		return

	combate.avanzar(delta)

## Congela el juego, pero solo si el impacto es de los fuertes: si no, un
## bumper rozado daría tirones todo el rato.
func _congelar(fuerza: float) -> void:
	_hitstop = maxf(_hitstop, anim.congelacion(fuerza))

func _sacudir(cantidad: float) -> void:
	_sacudida = minf(maxf(_sacudida, cantidad), anim.sacudida_maxima)

func _process(delta: float) -> void:
	_tiempo += delta
	_sacudida = maxf(_sacudida - delta * anim.sacudida_frenado, 0.0)
	flash_enemigo = maxf(flash_enemigo - delta * 2.2, 0.0)
	flash_jugador = maxf(flash_jugador - delta * 2.2, 0.0)
	# La sacudida SIEMPRE en píxeles enteros: a medio píxel, con el filtro
	# nearest y el escalado entero del proyecto, la mesa entera se ve borrosa
	# justo en el momento en que más se mira.
	# La sacudida va en el offset de la CÁMARA. Moviendo el nodo de la mesa no
	# se vería: la cámara es hija suya y se movería con él.
	camara.sacudida = anim.desplazamiento_sacudida(_sacudida, _rng)
	camara.avanzar(delta, mesa.bola.pos.y, mesa.bola.vel.y, mesa.bola.viva)

	for i in _flash_bumper.size():
		_flash_bumper[i] = maxf(
			_flash_bumper[i] - delta / anim.bumper_destello_duracion, 0.0)
	for i in _giro.size():
		_giro[i] += _giro_velocidad[i] * delta
		_giro_velocidad[i] = maxf(_giro_velocidad[i] - anim.girador_frenado * delta, 0.0)

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
	_sacudir(anim.sacudida_bumper)
	_congelar(fuerza)
	var i := _bumper_mas_cercano(punto)
	if i >= 0:
		_flash_bumper[i] = 1.0

func _bumper_mas_cercano(punto: Vector2) -> int:
	var mejor := -1
	var d := INF
	for i in mesa.bumpers.size():
		var dd: float = (mesa.bumpers[i] as Vector2).distance_squared_to(punto)
		if dd < d:
			d = dd
			mejor = i
	return mejor

func _al_girar_girador(_punto: Vector2, indice: int, fuerza: float) -> void:
	var ratio := clampf(fuerza / mesa.p.velocidad_maxima, 0.2, 1.0)
	_giro_velocidad[indice] = anim.girador_velocidad_maxima * ratio

func _al_golpear_slingshot(punto: Vector2, _fuerza: float) -> void:
	_destellos.append({"pos": punto, "t": 0.12, "r": 16.0, "col": C_GOMA_LUZ})

func _al_golpear_poste(punto: Vector2, _fuerza: float) -> void:
	_destellos.append({"pos": punto, "t": 0.10, "r": 14.0, "col": C_GOMA_LUZ})

func _al_buscar_bola(punto: Vector2) -> void:
	_destellos.append({"pos": punto, "t": 0.3, "r": 34.0, "col": C_ARCANO})
	_sacudir(anim.sacudida_ataque)

func _al_infligir_dano(dano: int, _multiplicador: int, punto: Vector2) -> void:
	_numeros.append({"pos": punto, "t": 0.7, "texto": "%d" % dano, "col": C_ORO_CLARO})
	flash_enemigo = maxf(flash_enemigo, 0.7)
	_nodo_enemigo.recibir_dano()
	_sacudir(anim.sacudida_dano)

## Solo salta cuando el multiplicador cambia de tramo, no en cada golpe.
func _al_cambiar_combo(multiplicador: int, _golpes: int) -> void:
	_nodo_suelo.pulsar()
	if multiplicador > 1:
		_sacudir(anim.sacudida_dano)

func _al_atacar_enemigo(_dano: int) -> void:
	flash_jugador = 1.0
	_nodo_enemigo.embestir()
	_sacudir(anim.sacudida_ataque)
	_hitstop = maxf(_hitstop, anim.hitstop)

func _al_terminar_combate(victoria: bool) -> void:
	if victoria:
		_nodo_enemigo.morir()
		_sacudir(anim.sacudida_muerte)
		_hitstop = maxf(_hitstop, anim.hitstop)

# ------------------------------------------------------------------- dibujo

func _draw() -> void:
	# Las capas: el fondo, el suelo, los adornos y el combo los pinta _nodo_suelo
	# (z -2) y el enemigo _nodo_enemigo (z -1), porque el enemigo tiene que
	# quedar entre medias y un solo CanvasItem no se puede partir. El HUD y el
	# escritorio van en CanvasLayer aparte, para que no se los lleve la cámara.
	# Aquí empieza la capa 0.
	# Sombreados de profundidad. Van translúcidos para que la piedra siga
	# viéndose por debajo; antes eran planos y tapaban el suelo.
	draw_rect(Rect2(20, 560, 360, 120), Color(C_MESA_BAJA, 0.30))
	draw_rect(Rect2(358, 300, 22, 360), Color(C_CARRIL, 0.80))
	draw_rect(Rect2(0, int(mesa.p.y_drenaje) - 8, Mesa.ANCHO, 8), C_DRENAJE)

	# El enemigo NO se dibuja aquí: vive en _nodo_enemigo, que tiene material
	# propio para el destello y la disolución y se cuela por z_index entre el
	# suelo y todo lo demás.
	_dibujar_inlanes()
	_dibujar_paredes()
	_dibujar_objetos()
	_dibujar_destellos()
	_dibujar_bola()
	_dibujar_numeros()
	_dibujar_lanzador()
	if _depuracion:
		_dibujar_depuracion()

## El medidor de carga del lanzador va pegado al carril, en el mundo: es parte
## de la mesa, no del HUD.
func _dibujar_lanzador() -> void:
	if not (mesa.cargando or mesa.carga_lanzador > 0.0):
		return
	draw_rect(Rect2(366, 600, 6, 50), C_CABINA)
	var alto := 50.0 * mesa.carga_lanzador
	draw_rect(Rect2(366, 650 - alto, 6, alto), C_ORO)

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
	_dibujar_giradores()
	_dibujar_bumpers()
	# Los postes van ANTES que los flippers: solapan con la cápsula del eje (es
	# lo que sella el hueco del atasco) y dibujar la pala encima deja el perno
	# del pivote a la vista.
	for centro in mesa.postes:
		_dibujar_sprite_centrado(_tex_poste, centro, mesa.p.poste_radio * 2.0, 60.0)
	_dibujar_flipper(mesa.flipper_izq)
	_dibujar_flipper(mesa.flipper_der)

## El bumper crece un número ENTERO de píxeles al golpearlo y se enciende.
## Crecer con una escala continua sobre un sprite de 38 px deja el borde
## temblando durante todo el destello.
func _dibujar_bumpers() -> void:
	var base := int(roundf(mesa.p.bumper_radio * 2.0))
	for i in mesa.bumpers.size():
		var flash: float = _flash_bumper[i]
		var crecimiento := int(roundf(flash * float(anim.bumper_crecimiento_pixeles)))
		var lado := base + crecimiento
		var centro: Vector2 = mesa.bumpers[i]
		var esquina := (centro - Vector2(lado, lado) * 0.5).round()
		var tinte := Color.WHITE.lerp(C_ORO_CLARO, flash * 0.8)
		draw_texture_rect(_tex_bumper, Rect2(esquina, Vector2(lado, lado)), false, tinte)

## Ocho escorzos pregenerados: se elige uno, no se rota nada en vivo.
func _dibujar_giradores() -> void:
	if _tex_girador.is_empty():
		return
	for i in mesa.giradores.size():
		var indice := int(_giro[i]) % _tex_girador.size()
		var tex := _tex_girador[indice]
		var esquina := ((mesa.giradores[i] as Vector2)
			- Vector2(tex.get_width(), tex.get_height()) * 0.5).round()
		draw_texture(tex, esquina)

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



