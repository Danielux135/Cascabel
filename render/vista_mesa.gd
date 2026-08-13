class_name VistaMesa
extends Node2D

## La mesa: dibuja la simulación y la deja jugar, y coordina a todo lo demás.
##
## Las capas, de atrás a delante: la cáscara (escritorio, barra de tareas,
## iconos de reliquia) en −10, el suelo en −2, el enemigo en −1, la mesa aquí
## en 0, la tele por encima cuando gira la ruleta, el HUD en 10, el mapa en 20 y
## la pantalla de TILT en 40.
##
## Las paredes, los flippers y los targets se dibujan por código; bumpers,
## postes, bola, enemigo y reliquias van con sprite.

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
const COMBO_TAMANO := 48
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
## La tele de la mesa: enseña el multiplicador mientras juegas y la ruleta de la
## recompensa cuando toca. Sustituye a la pantalla de "elige una de tres", que
## sacaba de la mesa cada minuto y cansaba más de lo que aportaba.
var tele: NodoTele
## LA CÁSCARA: escritorio, barra de tareas, marco de la mesa y las reliquias
## como iconos con tooltip. Sustituye a `NodoEscritorio`, que era solo el fondo.
var cascara: NodoCascara
## La pantalla azul de derrota. Es lo último que ve el jugador de un run, así
## que es donde salen los dos números que hacen falta para cuadrar el balance.
var tilt: NodoTilt
var _catalogo_reliquias: Array[Reliquia] = []
var _catalogo_misiones: Array[Mision] = []
## Durante la ruleta la simulación está congelada y la cámara baja a la tele.
## No es una pantalla aparte: es la misma mesa, quieta y oscurecida.
var _en_ruleta := false
## Con el mapa delante la simulación no corre y las palas no responden: el
## combate está congelado esperando, no jugándose de fondo.
var _en_mapa := false
## Combate resuelto, esperando que el jugador confirme para volver al mapa. Sin
## esto la pantalla de victoria duraría un fotograma.
var _esperando_confirmacion := false
## Al GANAR no se espera a que pulse nadie: se cuenta esto y se pasa solo a la
## ruleta. Una tecla para cerrar una victoria es una parada más, y las paradas
## son justo lo que sobraba. Al perder sí se espera: ahí se acaba el run y hay
## que poder leerlo.
var _espera_victoria: float = 0.0

func en_ruleta() -> bool:
	return _en_ruleta

var _catalogo: Array = []
var _depuracion := false
var _sacudida: float = 0.0
var _tiempo: float = 0.0
var flash_enemigo: float = 0.0
var flash_jugador: float = 0.0
## El platillo acaba de devolver tiempo. Enciende la BARRA DEL RELOJ, que está
## arriba, mientras el número sale abajo en el platillo: sin esto el "+6 s"
## flota en mitad de la mesa sin decir de qué contador habla, y está visto que
## un jugador puede hacer un run entero sin enterarse de que el platillo da
## tiempo. La causa se ve donde pasa; el efecto, donde se mide.
var flash_reloj: float = 0.0
## Segundos que devolvió el último platillo, para escribirlos junto a la barra.
var ultimo_atraso: float = 0.0
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
## Cuántas veces se ha atrapado la bola en esta partida. Solo para dejar de dar
## la pista una vez que se ve que ya la sabes.
var veces_atrapada: int = 0

var _tex_bola: Texture2D
var _tex_poste: Texture2D
var _tex_bumper: Texture2D
var _tex_enemigo: Texture2D
var _fuente: Font

func _ready() -> void:
	# El suelo se dibuja repitiendo la baldosa de 128x128, así que este
	# CanvasItem tiene que permitir repetición de textura.
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_fuente = FuenteUI.obtener()
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
	mesa.atrape_cambiado.connect(_al_cambiar_atrape)
	combate.dano_infligido.connect(_al_infligir_dano)
	combate.combo_cambiado.connect(_al_cambiar_combo)
	combate.enemigo_ataca.connect(_al_atacar_enemigo)
	combate.reloj_avisa.connect(_al_avisar_reloj)
	combate.reloj_atrasado.connect(_al_atrasar_reloj)
	combate.mision_completada.connect(_al_completar_mision)
	combate.mision_cambiada.connect(_al_cambiar_mision)
	combate.mision_reiniciada.connect(_al_reiniciar_mision)
	combate.golpe_critico.connect(_al_criticar)
	combate.curado.connect(_al_curar)
	combate.drenaje_perdonado.connect(_al_perdonar_drenaje)
	combate.combate_terminado.connect(_al_terminar_combate)

	_giro.resize(mesa.giradores.size())
	_giro_velocidad.resize(mesa.giradores.size())
	_flash_bumper.resize(mesa.bumpers.size())
	impactos = Impactos.new(impacto)
	_sonido = NodoSonido.new()
	add_child(_sonido)
	cascara = NodoCascara.new(self, cam, anim)
	add_child(cascara)
	_nodo_suelo = NodoSuelo.new(self)
	add_child(_nodo_suelo)
	_nodo_enemigo = NodoEnemigo.new(anim)
	add_child(_nodo_enemigo)

	camara = CamaraMesa.new(cam, Mesa.ALTO, Mesa.ANCHO * 0.5)
	add_child(camara)
	camara.make_current()
	add_child(NodoHud.new(self, cam))
	tilt = NodoTilt.new(self, cam)
	add_child(tilt)

	# EL TAMAÑO REAL DE LA PANTALLA, antes que nada. Con `aspect = expand` el
	# viewport crece en una pantalla que no sea 16:9 exacto, y si `cam` se queda
	# en 960x540 la cáscara mide contra el viewport de verdad mientras el HUD, el
	# mapa y la cámara miden contra 960x540: dos sistemas de coordenadas para la
	# misma pantalla, y todo desalineado por la diferencia.
	_medir_pantalla()
	get_viewport().size_changed.connect(_medir_pantalla)

	_catalogo = CatalogoEnemigos.cargar()
	if _catalogo.is_empty():
		push_error("Sin enemigos en data/enemigos.json")
		return
	# Sin reliquias el run se juega igual, solo que sin ellas: un fichero que
	# falte no puede tumbar la partida.
	_catalogo_reliquias = CatalogoReliquias.cargar()
	_catalogo_misiones = CatalogoMisiones.cargar()
	_nuevo_run()

# ------------------------------------------------------------------- el run

func _nuevo_run() -> void:
	run = Run.new(ParametrosRun.new(), combate.p, _catalogo,
		int(Time.get_unix_time_from_system()), _catalogo_reliquias,
		_catalogo_misiones)
	# Las reliquias del run entran en el combate por aquí, y es el único sitio
	# donde se cruzan las dos capas: `Combate` no sabe que existe un run.
	combate.bolsa = run.bolsa
	if _pantalla_mapa != null:
		_pantalla_mapa.queue_free()
	if tele != null:
		tele.queue_free()
	_pantalla_mapa = NodoPantallaMapa.new(run, cam)
	add_child(_pantalla_mapa)
	tele = NodoTele.new(self, run)
	add_child(tele)
	_volver_al_mapa()

func _volver_al_mapa() -> void:
	# Perder el run no lleva al mapa: lleva a la pantalla azul. Es la derrota de
	# `DISEÑO.md` §3, y es donde se leen los números del run.
	if run.terminada() and not run.victoria:
		_en_mapa = true
		_en_ruleta = false
		_esperando_confirmacion = false
		_pantalla_mapa.visible = false
		tilt.visible = true
		return
	_en_mapa = true
	_en_ruleta = false
	_esperando_confirmacion = false
	_pantalla_mapa.visible = true
	tilt.visible = false

## LA RULETA YA NO SALTA AL GANAR EL COMBATE. Salta al completar una misión, en
## mitad del juego: la bola se queda donde está, la cámara baja a la tele, la
## mesa se apaga, gira, y luego se reanuda todo con la bola en el mismo sitio.
## Es lo que pidió Daniel y es lo que hacen el pinball del XP y Pokémon Pinball:
## lo que ganas, lo ganas jugando.
func _al_completar_mision(mision: Mision) -> void:
	if not run.abrir_ruleta(mision.rareza):
		return
	_en_ruleta = true
	_pantalla_mapa.visible = false
	tele.empezar()

## Lo llama la tele al cerrarse: la reliquia ya está en la bolsa. Se vuelve al
## combate, no al mapa: la bola sigue viva y donde estaba.
func terminar_ruleta() -> void:
	_en_ruleta = false
	# Si el combate se acabó mientras giraba la ruleta —el mismo golpe puede
	# completar la misión y matar al enemigo— hay que cerrarlo de verdad, no solo
	# volver al mapa: volver al mapa sin cerrar el combate dejaba el run en una
	# fase sin salidas y la pantalla no respondía a nada.
	if combate.terminado():
		_cerrar_combate()

func sonar_ruleta(avance: float) -> void:
	# El mismo tic del reloj, subiendo de tono según se acerca la parada: es el
	# sonido de algo que frena, y no hace falta uno nuevo para contarlo.
	_sonido.reproducir("reloj", 0.85 + 0.5 * avance)

func sonar_premio() -> void:
	_sonido.reproducir("combo", 1.19)

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
	combate.iniciar(Enemigo.new(nodo.enemigo), run.vida,
		run.escalera_de_misiones())
	_nodo_enemigo.suelo = Vector2(ENEMIGO_CENTRO_X, ENEMIGO_SUELO_Y)
	_nodo_enemigo.configurar(_tex_enemigo, combate.enemigo.flota)
	_esperando_confirmacion = false
	_espera_victoria = 0.0
	_mayor_golpe = 1
	impactos.limpiar()
	_numeros.clear()

## Cierra el combate contra el run y vuelve al mapa. La vida que quede es la que
## sigues teniendo: es el único sitio donde se traspasa.
func _cerrar_combate() -> void:
	run.apuntar_medida(combate.bolas_jugadas, combate.dano_total,
		combate.tiempo_jugado)
	run.resolver_combate(combate.fase == Combate.Fase.VICTORIA, combate.vida_jugador)
	_volver_al_mapa()

func _physics_process(delta: float) -> void:
	if _en_mapa:
		return
	# Durante la ruleta la simulación NO corre y las palas no mueven nada, pero
	# la cámara sí: baja hasta el ancla de abajo, que es donde está la tele.
	# Congelar también la cámara dejaría la tele fuera de plano justo cuando es
	# lo único que hay que mirar.
	if _en_ruleta:
		camara.avanzar(delta, 0.0, 0.0, false)
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

## Le dice a todo el mundo cuánta pantalla hay de verdad. Es un solo sitio a
## propósito: en cuanto haya dos, uno se queda viejo y vuelve el desalineado.
func _medir_pantalla() -> void:
	var v := get_viewport_rect().size
	if v.x <= 0.0 or v.y <= 0.0:
		return
	cam.ancho_visible = v.x
	cam.alto_visible = v.y

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
	# Más lento que los otros dos a propósito: este no es un golpe, es una
	# lectura, y hay que darle tiempo al ojo a subir del platillo a la barra.
	flash_reloj = maxf(flash_reloj - delta * 0.7, 0.0)
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
	# La ruleta va en `_process` y no en la física: es animación, no simulación,
	# y durante ella la física está parada a propósito.
	if tele != null:
		tele.avanzar(delta)
	# La cuenta atrás de la victoria NO corre con la ruleta delante: si corriera,
	# el combate se cerraría por debajo de la ruleta y el run se quedaría colgado
	# en la fase de la ruleta para siempre. Es el cuelgue de la pantalla del mapa.
	if _espera_victoria > 0.0 and not _en_ruleta:
		_espera_victoria = maxf(_espera_victoria - delta, 0.0)
		if _espera_victoria <= 0.0 and _esperando_confirmacion:
			_cerrar_combate()
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
			# Durante la ruleta las palas piden otra tirada. Es la única entrada
			# que ya tienes en la mano, así que no hay que aprender nada nuevo.
			if _en_ruleta:
				tele.repetir()
			elif _en_mapa:
				_pantalla_mapa.mover(-1)
		KEY_RIGHT, KEY_D:
			if _en_ruleta:
				tele.repetir()
			elif _en_mapa:
				_pantalla_mapa.mover(1)
		KEY_ENTER, KEY_KP_ENTER:
			# Saltar lo que quede de la ruleta. Nunca cambia el premio: el premio
			# se sortea antes de que gire nada.
			if _en_ruleta:
				tele.saltar()
			elif _en_mapa:
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

## Atrapar la bola es la técnica con la que se elige un tiro, y no se anunciaba
## de ninguna manera: Daniel jugó una tanda entera dándole a las palas "a ver
## qué pasa" porque nada le decía que podía parar la bola y apuntar.
##
## El aviso es deliberadamente pequeño —un clic y una línea— porque no es un
## premio: es "ya la tienes, mira la mesa". Y no le da ninguna habilidad al
## gesto de mantener el flipper, que es invariante: enseña lo que ya pasaba.
func _al_cambiar_atrape(atrapada: bool) -> void:
	if atrapada:
		_sonido.reproducir("atrapar")
		veces_atrapada += 1

func _al_buscar_bola(punto: Vector2) -> void:
	impactos.onda(punto, C_ARCANO, 1.3)
	_sacudir(anim.sacudida_ataque)

## EL NÚMERO DE DAÑO, que ahora sale en TODO lo que pegas y con el tamaño que
## merece. Antes era un 9 px igual para un bumper de 6 que para un cañón de 300,
## así que no contaba nada: el número estaba, pero no informaba.
##
## Ahora el tamaño y el color salen de lo gordo que es el golpe COMPARADO CON EL
## RESTO DE TU PARTIDA, no de un umbral fijo: con reliquias de daño, un umbral
## escrito a mano se queda viejo a los tres combates y todo sale del mismo color.
func _al_infligir_dano(dano: int, multiplicador: int, punto: Vector2) -> void:
	_numeros.append(_numero_de_dano(dano, multiplicador, punto))
	flash_enemigo = maxf(flash_enemigo, 0.7)
	_nodo_enemigo.recibir_dano()
	_sacudir(anim.sacudida_dano)
	impactos.chispas(punto, Vector2.ZERO, C_ORO_CLARO, 0.6)

## Solo salta cuando el multiplicador cambia de tramo, no en cada golpe.
func _al_cambiar_combo(multiplicador: int, golpes: int) -> void:
	if tele != null:
		tele.pulsar()
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

## Lo que TE pegan también lleva número, y sale abajo, sobre el drenaje, que es
## donde miras cuando pierdes la bola. Antes solo parpadeaba la barra de vida:
## el golpe se veía, pero no se sabía cuánto había costado.
func _al_atacar_enemigo(dano: int) -> void:
	_numeros.append({"pos": Vector2(Mesa.ANCHO * 0.5, mesa.p.y_drenaje - 90.0),
		"t": 1.1, "texto": "-%d" % dano, "col": C_GOMA_LUZ,
		"tam": 24.0, "subida": 18.0})
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
	flash_reloj = 1.0
	ultimo_atraso = segundos
	var centro := mesa.platillos[0].centro if not mesa.platillos.is_empty() \
		else Vector2(Mesa.ANCHO * 0.5, 200.0)
	_numeros.append({"pos": centro, "t": 1.1,
		"texto": "+%.0f s" % segundos, "col": C_ARCANO})
	impactos.onda(centro, C_ARCANO, 1.6)

## El golpe de referencia con el que se juzga si un número es grande: lo mejor
## que has hecho en este combate. Se guarda aquí y no en la simulación porque es
## puro dibujo.
var _mayor_golpe: int = 1

func _numero_de_dano(dano: int, multiplicador: int, punto: Vector2) -> Dictionary:
	_mayor_golpe = maxi(_mayor_golpe, dano)
	var peso := float(dano) / float(maxi(_mayor_golpe, 1))
	var col := C_TEXTO
	if multiplicador >= 4:
		col = C_FUEGO
	elif multiplicador == 3:
		col = C_ORO_CLARO
	elif multiplicador == 2:
		col = C_ORO
	return {
		"pos": punto, "t": 0.75, "texto": "%d" % dano, "col": col,
		# De 10 a 22 px según el peso. Un bumper suelto se lee pequeño y un
		# cañón a x4 se lee de lejos, que es justo la información que falta.
		# El tamaño se redondea al múltiplo de la celda de la fuente: un 14 la
		# escalaría por 1,75 y le comería filas de píxeles a media letra.
		"tam": float(FuenteUI.tam(8.0 + 16.0 * peso)), "subida": 26.0,
	}

## El crítico. Se anuncia APARTE del número: si solo cambiara el número, no se
## lee "he tenido suerte", se lee "el daño de este juego es aleatorio".
func _al_criticar(punto: Vector2, dano: int) -> void:
	_numeros.append({"pos": punto + Vector2(0, -20), "t": 0.9,
		"texto": "CRÍTICO", "col": C_FUEGO, "tam": 8.0, "subida": 30.0})
	_numeros.append({"pos": punto, "t": 0.9, "texto": "%d" % dano,
		"col": C_FUEGO, "tam": 24.0, "subida": 30.0})
	impactos.onda(punto, C_FUEGO, 1.5)
	impactos.chispas(punto, Vector2.ZERO, C_FUEGO, 1.4)
	_sacudir(anim.sacudida_dano * 1.6)
	_congelar(900.0)

## Curarse también lleva número. Sale en verde y donde estaba la bola, que es
## donde ha pasado.
func _al_curar(cantidad: int, punto: Vector2) -> void:
	_numeros.append({"pos": punto, "t": 1.0, "texto": "+%d" % cantidad,
		"col": C_VERDE, "tam": 16.0, "subida": 24.0})

## La red de seguridad se ha comido el drenaje. Se dice donde se MIDE el
## castigo: sobre el corredor de drenaje, que es de donde no ha salido el golpe.
func _al_perdonar_drenaje() -> void:
	_numeros.append({"pos": Vector2(Mesa.ANCHO * 0.5, mesa.p.y_drenaje - 40.0),
		"t": 1.2, "texto": "RECUPERADA", "col": C_VERDE})
	impactos.onda(Vector2(Mesa.ANCHO * 0.5, mesa.p.y_drenaje - 40.0), C_VERDE, 1.6)
	_sonido.reproducir("atrasar")

## Misión nueva o progreso: suena distinto según sea empezar o avanzar. Sin
## sonido, el progreso de la misión solo existe si estás mirando la tele, y
## mientras juegas estás mirando la bola.
func _al_cambiar_mision(mision: Mision) -> void:
	if mision == null:
		return
	_sonido.reproducir("target", 1.35)

func _al_reiniciar_mision(_mision: Mision) -> void:
	_sonido.reproducir("drenaje", 0.8)
	_numeros.append({"pos": Vector2(Mesa.ANCHO * 0.5, mesa.p.y_drenaje - 60.0),
		"t": 1.2, "texto": "MISIÓN PERDIDA", "col": C_GOMA_LUZ})

func _al_terminar_combate(victoria: bool) -> void:
	_esperando_confirmacion = true
	# Lo justo para que se vea morir al enemigo. Luego la ruleta, sola.
	_espera_victoria = 1.2 if victoria else 0.0
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
	_dibujar_atrape()
	_dibujar_numeros()
	_dibujar_lanzador()
	_dibujar_velo()
	if _depuracion:
		_dibujar_depuracion()

## El velo de la ruleta: apaga la mesa entera menos la tele, que sube por encima
## por z_index. Va aquí, en el mundo, y no en una capa de pantalla, porque lo que
## se apaga es LA MESA: el escritorio de los lados no es parte del juego y
## oscurecerlo también convertiría esto en un cambio de pantalla, que es
## exactamente lo que se ha quitado.
func _dibujar_velo() -> void:
	if tele == null:
		return
	var alfa := tele.velo()
	if alfa <= 0.0:
		return
	draw_rect(camara.rect_visible(), Color(C_CABINA, alfa))
	# Y el texto de lo que hace la reliquia, que no cabe dentro de la tele.
	tele.dibujar_explicacion(self, Mesa.ANCHO - 48.0, Mesa.ANCHO * 0.5)

## Que se vea que la bola está parada y es tuya. Un anillo y ya.
##
## AQUÍ HABÍA UNA LÍNEA DE PUNTERÍA Y SE QUITÓ, porque mentía: predecía la
## dirección con ω × r en el punto de contacto y la bola salía a 101° de ahí.
## Y aunque no mintiera, no diría nada: está medido que la bola se asienta
## SIEMPRE en el mismo punto de la pala, así que la línea sería idéntica cada
## vez. Una ayuda que enseña siempre lo mismo no ayuda a elegir nada.
func _dibujar_atrape() -> void:
	if mesa.flipper_atrapando == null or not mesa.bola.viva:
		return
	draw_circle(mesa.bola.pos, mesa.p.radio_bola + 4.0, Color(C_ORO_CLARO, 0.55),
		false, 1.0)

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
## Qué paga cada recorrido, escrito en su boca. `DISEÑO.md` §1 dice que la mesa
## es un menú de tiros, y un menú sin los platos escritos no es un menú: Daniel
## jugó una tanda entera sin llegar a saber qué era el platillo.
const ETIQUETA_RAMPA := {
	Rampa.Premio.MULTIPLICADOR: "MULTIPLICADOR",
	Rampa.Premio.DANO_FUERTE: "CANON  DANO x2",
	Rampa.Premio.DANO: "OTRA PALA",
}

func _dibujar_rampas() -> void:
	for r in mesa.rampas:
		draw_polyline(r.puntos, Color(C_CABINA, 0.85), 15.0)
		draw_polyline(r.puntos, Color(C_MESA_BAJA, 0.9), 11.0)
		draw_polyline(r.puntos, Color(C_PARED, 0.55), 1.0)
		var bocas := [r.puntos[0]] if not r.bidireccional \
			else [r.puntos[0], r.puntos[r.puntos.size() - 1]]
		for extremo in [r.puntos[0], r.puntos[r.puntos.size() - 1]]:
			draw_circle(extremo, r.entrada_radio, Color(C_ORO, 0.30))
			draw_circle(extremo, r.entrada_radio, C_ORO, false, 1.0)
		for boca in bocas:
			_etiqueta(boca, str(ETIQUETA_RAMPA.get(r.premio, "")))

## Rótulo pequeño y apagado junto a una boca. Va tenue a propósito: tiene que
## poder leerse entre bola y bola, no competir con la bola.
func _etiqueta(donde: Vector2, texto: String) -> void:
	if texto == "":
		return
	var ancho := _fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var x := clampf(donde.x - ancho * 0.5, 24.0, Mesa.ANCHO - ancho - 24.0)
	draw_string(_fuente, Vector2(x, donde.y - r_separacion()), texto,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(C_TEXTO_TENUE, 0.85))

func r_separacion() -> float:
	return 22.0

func _dibujar_platillos() -> void:
	for pl in mesa.platillos:
		draw_circle(pl.centro, pl.radio + 3.0, C_METAL)
		draw_circle(pl.centro, pl.radio, C_CABINA)
		draw_line(pl.centro, pl.centro + pl.direccion * (pl.radio + 8.0),
			Color(C_ORO, 0.5), 1.0)
		# El platillo es el tiro que paga en tiempo, y era el único que no se
		# anunciaba. Sin esto no existe como decisión.
		_etiqueta(pl.centro + Vector2(0, pl.radio + 34.0), "ATRASA EL RELOJ")

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


## Cada número trae su tamaño y su recorrido. `tam` y `subida` son opcionales
## para que los avisos viejos sigan funcionando sin tocarlos.
func _dibujar_numeros() -> void:
	for d in _numeros:
		var col: Color = d["col"]
		col.a = clampf(float(d["t"]) * 2.5, 0.0, 1.0)
		var tam: float = float(FuenteUI.tam(float(d.get("tam", 8.0))))
		var recorrido: float = float(d.get("subida", 22.0))
		var vivido: float = maxf(0.75 - float(d["t"]), 0.0)
		var pos := (d["pos"] as Vector2) + Vector2(0, -10.0 - vivido * recorrido)
		# Sombra de un píxel: sobre la piedra clara un número de oro se pierde,
		# y estos números son la información principal del combate.
		draw_string(_fuente, pos + Vector2(-59, 1), d["texto"],
			HORIZONTAL_ALIGNMENT_CENTER, 120, int(tam), Color(C_CABINA, col.a * 0.8))
		draw_string(_fuente, pos + Vector2(-60, 0), d["texto"],
			HORIZONTAL_ALIGNMENT_CENTER, 120, int(tam), col)

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
