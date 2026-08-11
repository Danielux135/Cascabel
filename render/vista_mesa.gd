class_name VistaMesa
extends Node2D

## Banco de pruebas del combate. Dibuja la simulación y la deja jugar.
##
## OJO: esto NO es la cáscara de TILT OS. No hay ventanas de XP, ni barra de
## tareas, ni mapa, ni reliquias. Solo la mesa, un enemigo y el bucle de un
## combate hasta que uno de los dos muera. Las paredes, los flippers y los
## targets se dibujan por código; bumpers, postes, bola y enemigo van con sprite.

# Paleta cerrada: los hex viven en render/paleta.gd y en ningún sitio más.
const C_CABINA      := Paleta.CABINA
const C_MESA        := Paleta.MESA
const C_MESA_BAJA   := Paleta.MESA_BAJA
const C_PARED       := Paleta.PARED
const C_PARED_LUZ   := Paleta.PARED_LUZ
const C_CARRIL      := Paleta.CARRIL
const C_GOMA        := Paleta.GOMA
const C_GOMA_LUZ    := Paleta.GOMA_LUZ
const C_ORO         := Paleta.ORO
const C_ORO_CLARO   := Paleta.ORO_CLARO
const C_TEXTO       := Paleta.TEXTO
const C_TEXTO_TENUE := Paleta.TEXTO_TENUE
const C_ARCANO      := Paleta.ARCANO
const C_DRENAJE     := Paleta.DRENAJE
const C_VERDE       := Paleta.VERDE
const C_FUEGO       := Paleta.FUEGO
const C_PIEDRA      := Paleta.PIEDRA

## El multiplicador va grande, en el hueco entre los slingshots y los flippers,
## que es donde tienes puesto el ojo mientras juegas. Se dibuja pegado al suelo,
## por debajo de paredes, objetos y bola, así que nunca tapa el juego: lo que
## hace que se vea es que se enciende conforme sube.
## Y no más abajo: con los flippers levantados las palas llegan a y=559 y se
## comían la línea de debajo del número.
const COMBO_CENTRO := Vector2(200, 1120)
const COMBO_TAMANO := 46
const COMBO_ESTILO := {
	1: {"col": C_TEXTO_TENUE, "alfa": 0.22},
	2: {"col": C_ORO,         "alfa": 0.45},
	3: {"col": C_ORO_CLARO,   "alfa": 0.62},
	4: {"col": C_FUEGO,       "alfa": 0.82},
}
const C_FLIPPER       := Paleta.FLIPPER
const C_FLIPPER_BORDE := Paleta.FLIPPER_BORDE
const C_FLIPPER_LINEA := Paleta.FLIPPER_LINEA
const C_METAL         := Paleta.METAL
const C_METAL_LUZ     := Paleta.METAL_LUZ

## Los flippers van por código, no con sprite: se dibuja la misma cápsula que
## usa el colisionador, así que el arte sigue solo a `flipper_longitud` y
## `flipper_radio` mientras se ajusta el tacto.
const GROSOR_BORDE_FLIPPER := 1.5

## El enemigo vive en la parte alta del campo, detrás de los bumpers. Los
## sprites son 96x96 con los pies ya alineados dentro del marco, así que basta
## con posar el borde inferior del marco en el suelo.
const ENEMIGO_CENTRO_X := 200.0
const ENEMIGO_SUELO_Y := 758.0
## El target no lleva sprite: se dibuja del tamaño exacto del colisionador, que
## sale de `target_ancho` y `target_canto`. Esto es solo lo que se enciende de su
## cara, en píxeles.
const GROSOR_CARA_TARGET := 2.0

## El campo de juego de verdad: la mesa validada, con su suelo de piedra.
const CAMPO := Rect2(20, 660, 360, 620)
## Los 660 px de arriba NO son campo de juego: son el hueco por el que sube la
## órbita. Van en oscuro para que se lea que el raíl va elevado por detrás y no
## que la mesa sigue.
const ZONA_ALTA := Rect2(20, 20, 360, 640)
## Por donde cae la bola al drenar, bajo los flippers. Nada de adornos aquí
## salvo la rejilla, que va justo ahí a propósito.
const CORREDOR_DRENAJE := Rect2(170, 1200, 60, 100)

## Adornos del suelo, puestos a mano.
##
## Los de abajo van en los outlanes y en la franja bajo los flippers; los del
## final, en campo abierto arriba. Por todos pasa poco la bola, y la prueba lo
## mide en vez de darlo por supuesto.
##
## Escalas de 1.0 o 0.5 y espejo en vez de giros libres: rotar pixelart en
## ángulos sueltos rompe la rejilla de píxeles y se nota.
##
## Antes ocho de estos estaban en zona muerta de verdad, con 0,00 % de
## ocupación medida. Al abrir los OUTLANES esa zona dejó de ser muerta: es por
## donde se pierde la bola ahora. Siguen valiendo de adorno de carril, y la
## prueba pasó de exigir cero a exigir poco tráfico y medirlo.
const ADORNOS := [
	# outlane izquierdo
	{"tex": "grieta",       "pos": Vector2(56, 1212),  "escala": 1.0, "espejo": false},
	{"tex": "huesos",       "pos": Vector2(50, 1252),  "escala": 1.0, "espejo": true},
	{"tex": "musgo",        "pos": Vector2(88, 1240),  "escala": 0.5, "espejo": false},
	# outlane derecho
	{"tex": "baldosa_rota", "pos": Vector2(326, 1216), "escala": 1.0, "espejo": true},
	{"tex": "mancha",       "pos": Vector2(324, 1251), "escala": 1.0, "espejo": false},
	{"tex": "musgo",        "pos": Vector2(342, 1230), "escala": 0.5, "espejo": true},
	# franja bajo los flippers, a los lados del corredor de drenaje
	{"tex": "remaches",     "pos": Vector2(126, 1264), "escala": 1.0, "espejo": false},
	{"tex": "remaches",     "pos": Vector2(274, 1264), "escala": 1.0, "espejo": true},
	# la rejilla, en el drenaje: aquí sí pasa la bola, y es el sitio que le toca
	{"tex": "rejilla",      "pos": Vector2(200, 1250), "escala": 1.0, "espejo": false},
	# campo alto. La bola vive abajo, así que aquí arriba apenas pasa: 2,6 % y
	# 0,5 % de los fotogramas. Sitios sacados del mapa de ocupación, no a ojo.
	{"tex": "espiral",      "pos": Vector2(285, 895), "escala": 1.0, "espejo": false},
	{"tex": "sigilo",       "pos": Vector2(285, 730), "escala": 1.0, "espejo": false},
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
var impacto := ParametrosImpacto.new()
var impactos: Impactos
var cam := ParametrosCamara.new()
var camara: CamaraMesa

const TAMANO_GIRADOR := 32

var run: Run
var _pantalla_mapa: NodoPantallaMapa
## Con el mapa delante la simulación no corre y las palas no responden: el
## combate está congelado esperando, no jugándose de fondo.
var _en_mapa := false
## Combate resuelto, esperando que el jugador confirme para volver al mapa. Sin
## esto la pantalla de victoria duraría un fotograma.
var _esperando_confirmacion := false

var _catalogo: Array = []
var _depuracion := false
var _sacudida: float = 0.0
var _tiempo: float = 0.0
var flash_enemigo: float = 0.0
var flash_jugador: float = 0.0
var _hitstop: float = 0.0
var _rng := RandomNumberGenerator.new()
var _flipper_izq_antes := false
var _flipper_der_antes := false
var _sonido: NodoSonido
var _nodo_suelo: NodoSuelo
var _nodo_enemigo: NodoEnemigo
var _tex_girador: Array[Texture2D] = []
var _giro: Array[float] = []
var _giro_velocidad: Array[float] = []
var _flash_bumper: Array[float] = []
var _numeros: Array[Dictionary] = []

var _tex_bola: Texture2D
var _tex_poste: Texture2D
var _tex_bumper: Texture2D
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
	_tex_girador = Girador.generar(load("res://assets/mesa/girador.png"),
		anim.girador_fotogramas, TAMANO_GIRADOR)

	combate = Combate.new()
	mesa = combate.mesa
	mesa.slingshot_golpeado.connect(_al_golpear_slingshot)
	mesa.poste_golpeado.connect(_al_golpear_poste)
	mesa.bumper_golpeado.connect(_al_golpear_bumper)
	mesa.busqueda_bola.connect(_al_buscar_bola)
	mesa.girador_girado.connect(_al_girar_girador)
	mesa.target_abatido.connect(_al_abatir_target)
	mesa.banco_completado.connect(_al_completar_banco)
	mesa.rampa_entrada.connect(func(_pt: Vector2, _i: int) -> void:
		_sonido.reproducir("rampa_entrada"))
	mesa.rampa_salida.connect(_al_salir_de_rampa)
	mesa.platillo_capturado.connect(func(_pt: Vector2, _i: int) -> void:
		_sonido.reproducir("platillo"))
	mesa.bola_drenada.connect(_al_drenar_bola)
	combate.dano_infligido.connect(_al_infligir_dano)
	combate.combo_cambiado.connect(_al_cambiar_combo)
	combate.enemigo_ataca.connect(_al_atacar_enemigo)
	combate.reloj_avisa.connect(_al_avisar_reloj)
	combate.reloj_atrasado.connect(_al_atrasar_reloj)
	combate.combate_terminado.connect(_al_terminar_combate)

	_giro.resize(mesa.giradores.size())
	_giro_velocidad.resize(mesa.giradores.size())
	_flash_bumper.resize(mesa.bumpers.size())
	impactos = Impactos.new(impacto)
	_sonido = NodoSonido.new()
	add_child(_sonido)
	add_child(NodoEscritorio.new(cam, anim))
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
	_nuevo_run()

# ------------------------------------------------------------------- el run

func _nuevo_run() -> void:
	run = Run.new(ParametrosRun.new(), combate.p, _catalogo)
	if _pantalla_mapa != null:
		_pantalla_mapa.queue_free()
	_pantalla_mapa = NodoPantallaMapa.new(run, cam)
	add_child(_pantalla_mapa)
	_volver_al_mapa()

func _volver_al_mapa() -> void:
	_en_mapa = true
	_esperando_confirmacion = false
	_pantalla_mapa.visible = true

## Entra en el nodo marcado del mapa. Un descanso se resuelve solo y te devuelve
## al mapa; un combate baja a la mesa con la vida que traigas.
func _entrar_en_nodo() -> void:
	var nodo := _pantalla_mapa.confirmar()
	if nodo == null:
		return
	if not nodo.es_combate():
		_sonido.reproducir("atrasar")
		return
	_en_mapa = false
	_pantalla_mapa.visible = false
	_empezar_combate(nodo)

func _empezar_combate(nodo: NodoMapa) -> void:
	_tex_enemigo = load(str(nodo.enemigo.get("sprite", "")))
	# La vida del run entra tal cual: no se cura entre combates, y eso es lo
	# que hace que elegir rama importe.
	combate.iniciar(Enemigo.new(nodo.enemigo), run.vida)
	_nodo_enemigo.suelo = Vector2(ENEMIGO_CENTRO_X, ENEMIGO_SUELO_Y)
	_nodo_enemigo.configurar(_tex_enemigo, combate.enemigo.flota)
	impactos.limpiar()
	_numeros.clear()

## Cierra el combate contra el run y vuelve al mapa. La vida que quede es la que
## sigues teniendo: es el único sitio donde se traspasa.
func _cerrar_combate() -> void:
	run.resolver_combate(combate.fase == Combate.Fase.VICTORIA, combate.vida_jugador)
	_volver_al_mapa()

func _physics_process(delta: float) -> void:
	if _en_mapa:
		return
	mesa.flipper_izq.pulsado = Input.is_physical_key_pressed(KEY_A) \
		or Input.is_physical_key_pressed(KEY_LEFT) \
		or Input.is_physical_key_pressed(KEY_SHIFT)
	mesa.flipper_der.pulsado = Input.is_physical_key_pressed(KEY_D) \
		or Input.is_physical_key_pressed(KEY_RIGHT) \
		or Input.is_physical_key_pressed(KEY_CTRL)

	if mesa.flipper_izq.pulsado != _flipper_izq_antes 			or mesa.flipper_der.pulsado != _flipper_der_antes:
		if mesa.flipper_izq.pulsado or mesa.flipper_der.pulsado:
			_sonido.reproducir("flipper")
	_flipper_izq_antes = mesa.flipper_izq.pulsado
	_flipper_der_antes = mesa.flipper_der.pulsado

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
	# La cámara se mueve AQUÍ, pegada a la física: en `_process` iba un
	# fotograma por detrás de la bola y en la órbita eso la metía tras el HUD.
	camara.avanzar(delta, mesa.bola.pos.y, mesa.bola.vel.y, mesa.bola.viva)

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
	# La sacudida va en el offset de la CÁMARA, y SIEMPRE en píxeles enteros:
	# moviendo el nodo de la mesa no se vería, porque la cámara es hija suya y
	# se movería con él; y a medio píxel, con filtro nearest y escalado entero,
	# la mesa se ve borrosa justo en el momento en el que más se mira.
	# Aquí solo la sacudida: el seguimiento de la bola va en _physics_process.
	camara.aplicar_sacudida(anim.desplazamiento_sacudida(_sacudida, _rng))

	for i in _flash_bumper.size():
		_flash_bumper[i] = maxf(
			_flash_bumper[i] - delta / anim.bumper_destello_duracion, 0.0)
	for i in _giro.size():
		_giro[i] += _giro_velocidad[i] * delta
		_giro_velocidad[i] = maxf(_giro_velocidad[i] - anim.girador_frenado * delta, 0.0)

	impactos.avanzar(delta)
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
			_nuevo_run()
		KEY_F1:
			_depuracion = not _depuracion
		KEY_ESCAPE:
			get_tree().quit()
		KEY_LEFT, KEY_A:
			if _en_mapa:
				_pantalla_mapa.mover(-1)
		KEY_RIGHT, KEY_D:
			if _en_mapa:
				_pantalla_mapa.mover(1)
		KEY_ENTER, KEY_KP_ENTER:
			if _en_mapa:
				_entrar_en_nodo()
			elif _esperando_confirmacion:
				_cerrar_combate()

func _al_golpear_bumper(punto: Vector2, fuerza: float) -> void:
	_sonido.reproducir("bumper")
	_sacudir(anim.sacudida_bumper)
	_congelar(fuerza)
	var i := _bumper_mas_cercano(punto)
	if i >= 0:
		_flash_bumper[i] = 1.0
	# La dirección del material sale del bumper hacia el punto de contacto: es
	# por donde ha entrado la bola, y por donde tiene sentido que salte todo.
	var fuera := Vector2.ZERO if i < 0 else (punto - (mesa.bumpers[i] as Vector2))
	impactos.onda(punto, C_ORO, 1.0)
	impactos.chispas(punto, fuera, C_ORO_CLARO, 1.0)
	impactos.polvo(punto, fuera, C_PIEDRA, 0.6)

## El target cae hacia dentro de la mesa, así que el polvo sale hacia el
## centro: hacia fuera se metería dentro de la pared.
func _al_abatir_target(punto: Vector2, _banco: int) -> void:
	_sonido.reproducir("target")
	var adentro := Vector2(signf(Mesa.ANCHO * 0.5 - punto.x), -0.35)
	impactos.onda(punto, C_ORO, 0.5)
	impactos.chispas(punto, adentro, C_ORO_CLARO, 0.7)
	impactos.polvo(punto, adentro, C_PIEDRA, 1.0)

func _al_drenar_bola() -> void:
	_sonido.reproducir("drenaje")
	impactos.polvo(Vector2(Mesa.ANCHO * 0.5, mesa.p.y_drenaje - 26.0),
		Vector2.UP, C_PIEDRA, 1.4)

func _bumper_mas_cercano(punto: Vector2) -> int:
	var mejor := -1
	var d := INF
	for i in mesa.bumpers.size():
		var dd: float = (mesa.bumpers[i] as Vector2).distance_squared_to(punto)
		if dd < d:
			d = dd
			mejor = i
	return mejor

## Cada recorrido suena distinto, igual que paga distinto. La órbita no suena
## aquí: su premio es subir de tramo, y ya suena el arpegio del multiplicador.
func _al_salir_de_rampa(punto: Vector2, indice: int) -> void:
	var r: Rampa = mesa.rampas[indice]
	match r.premio:
		Rampa.Premio.DANO_FUERTE:
			_sonido.reproducir("rampa_fuerte")
			impactos.onda(punto, C_FUEGO, 1.4)
			impactos.chispas(punto, Vector2.DOWN, C_FUEGO, 1.2)
		Rampa.Premio.MULTIPLICADOR:
			impactos.onda(punto, C_ORO_CLARO, 1.1)
		_:
			_sonido.reproducir("rampa_salida")
			impactos.onda(punto, C_ORO, 0.7)

func _al_girar_girador(_punto: Vector2, indice: int, fuerza: float) -> void:
	var ratio := clampf(fuerza / mesa.p.velocidad_maxima, 0.2, 1.0)
	_giro_velocidad[indice] = anim.girador_velocidad_maxima * ratio

func _al_golpear_slingshot(punto: Vector2, _fuerza: float) -> void:
	impactos.onda(punto, C_GOMA_LUZ, 0.55)
	impactos.chispas(punto, Vector2.ZERO, C_GOMA_LUZ, 0.5)

func _al_golpear_poste(punto: Vector2, _fuerza: float) -> void:
	impactos.onda(punto, C_GOMA_LUZ, 0.42)

## Cerrar el banco entero es un premio y sonaba igual que abatir el tercer
## target, o sea que no se notaba. Con el criterio de la fase 3B —distinguir por
## el oído qué acabas de conseguir— eso es un tiro sin identidad.
func _al_completar_banco(punto: Vector2, _banco: int) -> void:
	_sonido.reproducir("banco")
	impactos.onda(punto, C_ORO_CLARO, 1.2)
	impactos.chispas(punto, Vector2(signf(Mesa.ANCHO * 0.5 - punto.x), -0.35),
		C_ORO_CLARO, 1.4)

func _al_buscar_bola(punto: Vector2) -> void:
	impactos.onda(punto, C_ARCANO, 1.3)
	_sacudir(anim.sacudida_ataque)

func _al_infligir_dano(dano: int, _multiplicador: int, punto: Vector2) -> void:
	_numeros.append({"pos": punto, "t": 0.7, "texto": "%d" % dano, "col": C_ORO_CLARO})
	flash_enemigo = maxf(flash_enemigo, 0.7)
	_nodo_enemigo.recibir_dano()
	_sacudir(anim.sacudida_dano)
	impactos.chispas(punto, Vector2.ZERO, C_ORO_CLARO, 0.6)

## Solo salta cuando el multiplicador cambia de tramo, no en cada golpe.
func _al_cambiar_combo(multiplicador: int, golpes: int) -> void:
	_nodo_suelo.pulsar()
	# `combo_cambiado` también salta al drenar, cuando cae a x1. Ahí no suena:
	# el sonido de subir de tramo es un premio y sonaría a burla.
	# Y sube de tono con el tramo: x2, x3 y x4 son el mismo arpegio cada vez
	# más agudo, así que el oído sabe por dónde va sin mirar el número.
	if golpes > 0:
		_sonido.reproducir("combo", _tono_combo(multiplicador))
	if multiplicador > 1:
		_sacudir(anim.sacudida_dano)

## Transposición del arpegio por tramo. Van en intervalos musicales, no en un
## porcentaje fijo: un 12 % por tramo es medio semitono largo y el oído lo lee
## como "el mismo sonido desafinado", no como "más alto". x2 suena en su tono,
## x3 una tercera menor arriba, x4 una quinta.
const TONO_COMBO := [1.0, 1.19, 1.50]

func _tono_combo(multiplicador: int) -> float:
	return TONO_COMBO[clampi(multiplicador - 2, 0, TONO_COMBO.size() - 1)]

func _al_atacar_enemigo(_dano: int) -> void:
	flash_jugador = 1.0
	_nodo_enemigo.embestir()
	_sonido.reproducir("ataque")
	_sacudir(anim.sacudida_ataque)
	_hitstop = maxf(_hitstop, anim.hitstop)

## La cuenta atrás del reloj. Sube de tono según se acerca el golpe: es el mismo
## tic tres veces y lo que cambia es la urgencia, no la información.
func _al_avisar_reloj(segundos: int) -> void:
	_sonido.reproducir("reloj", 1.0 + 0.18 * float(3 - segundos))

## El platillo atrasando el reloj. El número sale donde estaba el platillo, no
## sobre el enemigo: lo que acabas de ganar es tiempo, y el tiempo se ha ganado
## ahí abajo.
func _al_atrasar_reloj(segundos: float) -> void:
	_sonido.reproducir("atrasar")
	var centro := mesa.platillos[0].centro if not mesa.platillos.is_empty() \
		else Vector2(Mesa.ANCHO * 0.5, 200.0)
	_numeros.append({"pos": centro, "t": 1.1,
		"texto": "+%.0f s" % segundos, "col": C_ARCANO})
	impactos.onda(centro, C_ARCANO, 1.6)

func _al_terminar_combate(victoria: bool) -> void:
	_esperando_confirmacion = true
	if victoria:
		_sonido.reproducir("muerte")
		_nodo_enemigo.morir()
		var centro := Vector2(ENEMIGO_CENTRO_X, ENEMIGO_SUELO_Y - 40.0)
		impactos.onda(centro, C_FUEGO, 2.2)
		impactos.chispas(centro, Vector2.ZERO, C_FUEGO, 3.0)
		impactos.polvo(centro, Vector2.ZERO, C_PIEDRA, 2.5)
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
	draw_rect(Rect2(20, 1160, 360, 120), Color(C_MESA_BAJA, 0.30))
	draw_rect(Rect2(358, 900, 22, 360), Color(C_CARRIL, 0.80))
	draw_rect(Rect2(0, int(mesa.p.y_drenaje) - 8, Mesa.ANCHO, 8), C_DRENAJE)

	# El enemigo NO se dibuja aquí: vive en _nodo_enemigo, que tiene material
	# propio para el destello y la disolución y se cuela por z_index entre el
	# suelo y todo lo demás.
	_dibujar_inlanes()
	_dibujar_rampas()
	_dibujar_platillos()
	_dibujar_paredes()
	_dibujar_objetos()
	impactos.dibujar(self)
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
	draw_rect(Rect2(366, 1200, 6, 50), C_CABINA)
	var alto := 50.0 * mesa.carga_lanzador
	draw_rect(Rect2(366, 1250 - alto, 6, alto), C_ORO)

## La órbita es una curva, no paredes, así que se dibuja como lo que es: un
## carril elevado. La bola se pinta después, encima, porque va por arriba.
func _dibujar_rampas() -> void:
	for r in mesa.rampas:
		draw_polyline(r.puntos, Color(C_CABINA, 0.85), 15.0)
		draw_polyline(r.puntos, Color(C_MESA_BAJA, 0.9), 11.0)
		draw_polyline(r.puntos, Color(C_PARED, 0.55), 1.0)
		for extremo in [r.puntos[0], r.puntos[r.puntos.size() - 1]]:
			draw_circle(extremo, r.entrada_radio, Color(C_ORO, 0.30))
			draw_circle(extremo, r.entrada_radio, C_ORO, false, 1.0)

func _dibujar_platillos() -> void:
	for pl in mesa.platillos:
		draw_circle(pl.centro, pl.radio + 3.0, C_METAL)
		draw_circle(pl.centro, pl.radio, C_CABINA)
		draw_line(pl.centro, pl.centro + pl.direccion * (pl.radio + 8.0),
			Color(C_ORO, 0.5), 1.0)

## Los carriles de retorno del arreglo 1, sombreados para que se lean.
func _dibujar_inlanes() -> void:
	var tinte := Color(C_CARRIL, 0.55)
	draw_line(Vector2(48, 1094), Vector2(112, 1178), tinte, 26.0)
	draw_line(Vector2(332, 1080), Vector2(288, 1178), tinte, 24.0)

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
			_dibujar_target(c)
		else:
			# Abatido: se ve la ranura por la que ha bajado. La ranura es la
			# huella de la plancha, así que mide lo mismo que ella.
			var centro := c.centro()
			draw_rect(Rect2(centro.x - mesa.p.target_canto * 0.5,
				centro.y - mesa.p.target_ancho * 0.5,
				mesa.p.target_canto, mesa.p.target_ancho), C_CABINA)
	_dibujar_giradores()
	_dibujar_bumpers()
	# Los postes van ANTES que los flippers: solapan con la cápsula del eje (es
	# lo que sella el hueco del atasco) y dibujar la pala encima deja el perno
	# del pivote a la vista.
	for centro in mesa.postes:
		_dibujar_sprite_centrado(_tex_poste, centro, mesa.p.poste_radio * 2.0, 60.0)
	_dibujar_flipper(mesa.flipper_izq)
	_dibujar_flipper(mesa.flipper_der)

## El target va por código, no con sprite, por la misma razón que el flipper:
## `target_canto` es un dial que todavía se está ajustando y el arte tiene que
## medir exactamente lo que mide el colisionador. Cuando el número se quede
## quieto se puede volver a los sprites de escudo y lápida.
##
## Se dibuja la huella de la plancha y se le enciende la cara que mira al campo,
## que es la única que la bola puede golpear. El color separa los dos bancos:
## era lo que hacían el escudo y la lápida.
func _dibujar_target(c: Colisionador) -> void:
	var centro := c.centro().round()
	var canto := roundf(mesa.p.target_canto)
	var cara := roundf(mesa.p.target_ancho)
	var esquina := Vector2(centro.x - canto * 0.5, centro.y - cara * 0.5).round()
	draw_rect(Rect2(esquina, Vector2(canto, cara)), C_CABINA)
	draw_rect(Rect2(esquina + Vector2.ONE, Vector2(canto - 2.0, cara - 2.0)), C_MESA_BAJA)
	# La cara encendida, en el lado que mira al centro de la mesa.
	var hacia_dentro := signf(Mesa.ANCHO * 0.5 - centro.x)
	var x_cara := esquina.x + canto - GROSOR_CARA_TARGET if hacia_dentro > 0.0 else esquina.x
	var col: Color = C_ORO_CLARO if c.banco % 2 == 0 else C_ARCANO
	draw_rect(Rect2(Vector2(x_cara, esquina.y + 1.0),
		Vector2(GROSOR_CARA_TARGET, cara - 2.0)), col)

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
		# El WHITE de aquí NO es un color de la paleta: es el tinte neutro de
		# draw_texture_rect, o sea "no tiñas". Poner E4E6EC oscurecería el
		# sprite. Se queda.
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
	if mesa.bola.rampa >= 0:
		# Va por encima de la mesa: una sombra debajo lo cuenta sin texto.
		draw_circle(mesa.bola.pos + Vector2(3, 6), mesa.p.radio_bola * 0.8,
			Color(C_CABINA, 0.5))
	var escala := mesa.p.radio_bola * 2.0 / 20.0
	var mitad := Vector2(_tex_bola.get_width(), _tex_bola.get_height()) * 0.5
	draw_set_transform(mesa.bola.pos, 0.0, Vector2(escala, escala))
	draw_texture(_tex_bola, -mitad)
	draw_set_transform_matrix(Transform2D.IDENTITY)


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



