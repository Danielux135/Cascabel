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
## Los avisos de bola fuera de plano. `MARGEN` es lo que se separan del borde de
## la pantalla para no quedar pegados al canto, y `ALCANCE` es a qué distancia la
## flecha llega a su transparencia mínima: es la altura de una pantalla, o sea
## que una bola a más de una pantalla de distancia se ve igual de tenue que a
## dos, que es lo correcto — a esa distancia lo único que importa es por dónde.
const AVISO_MARGEN := 10.0
const AVISO_ALCANCE := 540.0
const C_ORO_CLARO   := Paleta.ORO_CLARO
const C_TEXTO       := Paleta.TEXTO
const C_TEXTO_TENUE := Paleta.TEXTO_TENUE
const C_ARCANO      := Paleta.ARCANO
const C_DRENAJE     := Paleta.DRENAJE
const C_VERDE       := Paleta.VERDE
const C_FUEGO       := Paleta.FUEGO
const C_PIEDRA      := Paleta.PIEDRA
## Las dos caras de una plataforma. La de arriba lleva luz y el canto no: es lo
## único que hace que una losa se lea como ALTA en dos dimensiones.
const C_PIEDRA_LUZ    := Paleta.PIEDRA_4
const C_PIEDRA_CANTO  := Paleta.PIEDRA_1
## Lo alto que se dibuja una plataforma. No es física —la física es plana y de
## capas— es cuánto canto se ve. Está aquí y no en `ParametrosMesa` porque no
## cambia ningún número: se ajusta mirando.
const GROSOR_PLATAFORMA := 12.0

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

## EL ENEMIGO YA NO ESTÁ EN LA MESA. Vivía en la parte alta del campo, en
## y=758, y de ahí se han quitado dos cosas a la vez: el invariante dice que los
## enemigos normales viven FUERA del campo de juego, y con la cámara anclada
## abajo casi nunca se le veía, así que el destello al pegarle —que es la
## respuesta a cada golpe— pasaba fuera de plano. Ahora vive en el panel
## `enemigo.exe` de la banda derecha (`NodoPanelEnemigo`) y está siempre a la
## vista. Los sprites siguen siendo 96x96 con los pies alineados dentro del
## marco: lo único que cambia es dónde se posan.
## El target no lleva sprite: se dibuja del tamaño exacto del colisionador, que
## sale de `target_ancho` y `target_canto`. Esto es solo lo que se enciende de su
## cara, en píxeles.
const GROSOR_CARA_TARGET := 2.0

## El campo de juego de verdad: la mesa validada, con su suelo de piedra.
const CAMPO := Rect2(20, 660, 360, 620)
## Los 660 px de arriba fueron durante mucho tiempo el hueco por el que sube la
## órbita, y por eso iban en oscuro: se leía que el raíl va elevado por detrás y
## no que la mesa sigue.
const ZONA_ALTA := Rect2(20, 20, 360, 640)
## Y AHORA LA PLANTA ALTA ES UNA MESA, así que tiene el mismo suelo de piedra que
## la de abajo. Con el hueco oscuro debajo de una planta con palas, isla, túneles
## y órbita, lo que se veía era una mesa flotando en un pozo — y el invariante
## dice lo contrario: LAS DOS PLANTAS SON MESAS.
##
## Lo que se queda oscuro es lo que de verdad no es mesa: por encima del techo, y
## los 12 px entre el fondo del embudo de arriba (648) y el arco de abajo (660),
## que son el hueco que impide que las dos plantas se comuniquen por gravedad.
const CAMPO_ALTO := Rect2(20, 150, 360, 498)
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
## LA CÁSCARA: escritorio, barra de tareas, paneles laterales y las reliquias
## como iconos con tooltip. Va DETRÁS de la mesa (capa −10).
var cascara: NodoCascara
## Y la otra mitad de la cáscara, DELANTE (capa 5): el marco de la ventana de la
## mesa, la barra de tareas y el tooltip. Son dos nodos porque la mesa se dibuja
## en medio, y el fondo negro del tablero se comía todo lo que cayera dentro de
## su columna de 400 px.
var cascara_frente: NodoCascaraFrente
## El enemigo, en su panel de la banda derecha. Se lleva sus propias partículas.
var panel_enemigo: NodoPanelEnemigo
## El puntero del sistema falso, dibujado en la rejilla de píxeles del juego.
var cursor: NodoCursor
## Lo que sobrevive a cerrar el juego, y el sistema operativo que lo enseña.
var guardado: Guardado
var sistema: NodoSistema
## Lo elegido antes del run: cascabel, criatura y palas (`DISEÑO.md` §5).
var preparacion: Preparacion
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
## Cuánto está apagada la planta de abajo, de 0 a 1. Sube mientras dura la caza.
var _dormida: float = 0.0
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
var _musica: NodoMusica
var _nodo_suelo: NodoSuelo
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

	_montar_combate(ParametrosMesa.new())
	impactos = Impactos.new(impacto)
	_sonido = NodoSonido.new()
	add_child(_sonido)
	_musica = NodoMusica.new()
	add_child(_musica)
	# EL ARRANQUE SUENA UNA VEZ Y AQUÍ, que es lo único que pasa antes del
	# escritorio (`assets/prompts_musica.md` §4.10). En cuanto `_musica_que_toca`
	# empiece a mandar, la cruzará por la del escritorio ella sola.
	_musica.poner("arranque")
	cascara = NodoCascara.new(self, cam, anim)
	add_child(cascara)
	_nodo_suelo = NodoSuelo.new(self)
	add_child(_nodo_suelo)
	# LA CÁMARA MIDE CONTRA LA CÁSCARA, no contra un número escrito a mano. Lo
	# que puede tapar la bola por arriba es el marco de la ventana de la mesa con
	# su barra de título, y eso lo sabe la cáscara. Con el número copiado aquí,
	# cambiar el grosor del marco dejaría a la cámara midiendo el marco viejo y
	# la bola volvería a esconderse en lo alto de la órbita sin que nada avisara.
	cam.alto_franja_hud = NodoCascara.chrome_superior()
	cascara_frente = NodoCascaraFrente.new(cascara)
	add_child(cascara_frente)
	panel_enemigo = NodoPanelEnemigo.new(cascara, anim, impacto)
	add_child(panel_enemigo)

	camara = CamaraMesa.new(cam, Mesa.ALTO, Mesa.ANCHO * 0.5)
	add_child(camara)
	camara.make_current()
	add_child(NodoHud.new(self, cam))
	tilt = NodoTilt.new(self, cam)
	add_child(tilt)
	cursor = NodoCursor.new(self)
	add_child(cursor)

	# EL GUARDADO, y va antes que el sistema porque el sistema lo enseña. Cargar
	# NUNCA falla: si no hay fichero, o no se entiende, sale uno vacío y válido.
	# Sembrar después de cargar y no al crear es lo que hace que una pieza que
	# mañana pase a ser inicial llegue también a los guardados que ya existen.
	guardado = Guardado.cargar()
	CatalogoRecuperable.sembrar(guardado)
	# LA PREPARACIÓN SALE DEL GUARDADO, para que lo que elegiste siga elegido
	# mañana. `sanear` la deja en algo que exista: un guardado viejo puede traer
	# una criatura que ya no está, y una elección que apunta a la nada no da
	# error, deja la bola sin dibujo.
	preparacion = Preparacion.new()
	preparacion.cascabel = guardado.pre_cascabel
	preparacion.criatura = guardado.pre_criatura
	preparacion.palas = guardado.pre_palas
	preparacion.sanear(guardado)
	sistema = NodoSistema.new(self, guardado)
	add_child(sistema)

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


## MONTA EL COMBATE Y SU MESA CON UNOS PARÁMETROS CONCRETOS.
##
## Existe porque **las palas no se pueden cambiar sobre una mesa ya hecha**:
## `Mesa.new()` copia los parámetros dentro de cada colisionador en el
## constructor, así que tocar `m.p.flipper_longitud` después no hace nada. Es una
## trampa de `CLAUDE.md` y ya se llevó por delante un barrido entero, que midió
## seis veces lo mismo. Elegir palas en la preparación obliga, por tanto, a
## rehacer la mesa, y eso es lo que hace esta función.
##
## Se llama al arrancar y al empezar cada run. Lo viejo se suelta sin más: `Mesa`
## y `Combate` son `RefCounted`, así que al perder la referencia se van solos con
## todas sus conexiones detrás.
func _montar_combate(pm: ParametrosMesa) -> void:
	combate = Combate.new(null, Mesa.new(pm))
	mesa = combate.mesa
	mesa.slingshot_golpeado.connect(_al_golpear_slingshot)
	mesa.poste_golpeado.connect(_al_golpear_poste)
	mesa.bumper_golpeado.connect(_al_golpear_bumper)
	# La caza no estrena sonido: entra con el de recorrido gordo y sale con el
	# del banco. Un sonido nuevo por cada cosa nueva acaba en un banco que nadie
	# distingue, y estos dos ya significan "algo grande" y "algo se ha cerrado".
	mesa.caza_empezada.connect(func(_pt: Vector2) -> void:
		_sonido.reproducir("rampa_fuerte")
		_encuadrar_la_caza())
	mesa.caza_terminada.connect(func(_pt: Vector2) -> void:
		_sonido.reproducir("banco")
		camara.soltar_banda())
	mesa.bola_salvada.connect(_al_salvar_bola)
	mesa.busqueda_bola.connect(_al_buscar_bola)
	mesa.girador_girado.connect(_al_girar_girador)
	mesa.target_abatido.connect(_al_abatir_target)
	mesa.banco_completado.connect(_al_completar_banco)
	mesa.rampa_entrada.connect(func(_pt: Vector2, _i: int) -> void:
		_sonido.reproducir("rampa_entrada"))
	mesa.rampa_salida.connect(_al_salir_de_rampa)
	mesa.rampa_fallada.connect(_al_fallar_rampa)
	mesa.rampa_devuelta.connect(_al_devolver_rampa)
	mesa.carga_cambiada.connect(_al_cambiar_carga)
	mesa.descarga_empezada.connect(_al_empezar_descarga)
	mesa.descarga_terminada.connect(_al_terminar_descarga)
	mesa.bola_cayo.connect(_al_caer_bola)
	mesa.platillo_capturado.connect(func(_pt: Vector2, _i: int) -> void:
		_sonido.reproducir("platillo"))
	mesa.bola_drenada.connect(_al_drenar_bola)
	mesa.bola_perdida.connect(_al_perder_bola)
	mesa.bola_extra.connect(_al_entrar_bola_extra)
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

# ------------------------------------------------------------------- el run

## Empieza un run con lo que haya elegido la preparación. Lo llama el botón
## "Empezar" de `NodoSistema`, y es público por eso: la tecla R hace lo mismo.
func nueva_partida() -> void:
	_nuevo_run()

func _nuevo_run() -> void:
	# LAS PALAS SE PONEN REHACIENDO LA MESA, y tiene que ser aquí: la mesa copia
	# sus parámetros dentro de los colisionadores al construirse, así que no hay
	# forma de cambiar de palas a mitad de run aunque quisiéramos. Y no la hay
	# tampoco a propósito: `DISEÑO.md` §5 dice que la mesa y las palas se eligen
	# ANTES, porque cambiarle a alguien las manos en el combate siete es
	# castigarle por haber aprendido a jugar.
	if preparacion != null:
		preparacion.sanear(guardado)
		_montar_combate(preparacion.parametros_mesa())
	run = Run.new(ParametrosRun.new(), combate.p, _catalogo,
		int(Time.get_unix_time_from_system()), _catalogo_reliquias,
		_catalogo_misiones)
	# Las reliquias del run entran en el combate por aquí, y es el único sitio
	# donde se cruzan las dos capas: `Combate` no sabe que existe un run.
	combate.bolsa = run.bolsa
	# Y EL CASCABEL entra por la bolsa BASE, separado de lo que ganes jugando.
	# Colado entre las reliquias saldría como un icono más del escritorio y la
	# ruleta podría volver a ofrecerlo.
	if preparacion != null:
		var casc := preparacion.como_reliquia()
		# La lista va tipada A MANO y no con un ternario: `[casc] if ... else []`
		# deja un `Array` sin tipo y la asignación falla en tiempo de ejecución,
		# no al compilar. Ahí el cascabel no llegaba a la bolsa y el juego seguía
		# corriendo como si no hubiera capa de preparación.
		var puesto: Array[Reliquia] = []
		if casc != null:
			puesto.append(casc)
		run.bolsa.base = puesto
	if _pantalla_mapa != null:
		_pantalla_mapa.queue_free()
	if tele != null:
		tele.queue_free()
	# ES AQUÍ DONDE PERDER EMPIEZA A COSTAR ALGO. Hasta ahora, acabar un run no
	# dejaba ni un número: no existía ninguna frase que empezara por "la próxima
	# vez" (`PROPÓSITO.md` §1). Ahora el run cierra contra el guardado, paga lo
	# que haya ganado y lo escribe a disco. Se conecta aquí y no en `_ready`
	# porque cada `_nuevo_run` crea un `Run` nuevo.
	run.run_terminada.connect(_al_terminar_run)
	_pantalla_mapa = NodoPantallaMapa.new(run, cam)
	add_child(_pantalla_mapa)
	tele = NodoTele.new(self, run)
	add_child(tele)
	_volver_al_mapa()

func _volver_al_mapa() -> void:
	# SE TIRA EL DADO DEL FONDO, y este es el único momento en el que se puede:
	# entre combate y combate. El acto decide cuántas variantes hay —el 1 va
	# limpio, el 3 tiene cuatro maneras distintas de estar roto— y el dado dice
	# cuál toca. Tirarlo cada fotograma haría parpadear el escritorio, y eso no
	# se lee como un sistema corrompiéndose: se lee como un juego con un fallo.
	if cascara != null:
		cascara.tirar_fondo()
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
	# LA CÁMARA FIJA DE LA CAZA SE SUELTA PARA LA RULETA, y no es un detalle:
	# `objetivo_completo` deja que la banda mande sobre las cuatro reglas, así que
	# durante la caza la cámara se queda plantada en la arena y la ruleta gira
	# 643 px por debajo de lo que se está viendo. Medido: la tele está en y=1030
	# y la cámara no se movía de y=387. **Ganabas la reliquia y no la veías.**
	#
	# Y se suelta aquí y no dentro de la cámara porque la razón es de juego, no
	# de encuadre: la banda existe para que la caza se lea como un bonus, y
	# mientras la ruleta está delante no se está jugando la caza.
	camara.soltar_banda()
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
		return
	# Y SI LA CAZA SIGUE ABIERTA, SE VUELVE A ENCUADRAR. La bola no se ha movido
	# —la ruleta congela la simulación— así que sigue arriba y el bonus sigue
	# corriendo: dejar la cámara suelta la devolvería a las cuatro reglas con la
	# bola en el fondo del embudo, que es exactamente el encuadre que la caza
	# quería evitar. El muelle hace el viaje de vuelta, igual que el de ida.
	if mesa.en_caza:
		_encuadrar_la_caza()

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
	panel_enemigo.configurar(_tex_enemigo, combate.enemigo.flota)
	_esperando_confirmacion = false
	_espera_victoria = 0.0
	_mayor_golpe = 1
	impactos.limpiar()
	_numeros.clear()

## Se acabó el run, se gane o se pierda. Es el único sitio donde se escribe a
## disco: guardar en cada golpe sería escribir cientos de veces por combate, y
## guardar solo al ganar dejaría sin premio justo al run que más falta le hace.
func _al_terminar_run(victoria: bool) -> void:
	if guardado == null:
		return
	var nuevas := guardado.cerrar_run(victoria, run)
	if not guardado.guardar():
		# Que no se pueda escribir no puede tumbar la partida, pero tampoco se
		# calla: un progreso que no se guarda y no lo dice es lo peor de los dos.
		push_error("No se ha podido guardar la partida")
	if not nuevas.is_empty() and sistema != null:
		sistema.anunciar(str(nuevas[0]))

## Cierra el combate contra el run y vuelve al mapa. La vida que quede es la que
## sigues teniendo: es el único sitio donde se traspasa.
func _cerrar_combate() -> void:
	run.apuntar_medida(combate.bolas_jugadas, combate.dano_total,
		combate.tiempo_jugado)
	run.resolver_combate(combate.fase == Combate.Fase.VICTORIA, combate.vida_jugador)
	_volver_al_mapa()

## Si el mapa está delante. Lo pregunta `NodoSistema` para no dejar pulsar los
## iconos del escritorio cuando están tapados por el explorador maximizado: un
## icono que responde debajo de una ventana es un clic que hace lo que no ves.
func mapa_visible() -> bool:
	return _en_mapa

func _physics_process(delta: float) -> void:
	if _en_mapa:
		return
	# UNA VENTANA DEL SISTEMA CONGELA LA MESA, igual que la ruleta. Una ventana
	# de 520 px encima del tablero tapa justo la bola, así que dejarla viva sería
	# perderla mientras lees. La cámara sí sigue, como en la ruleta: congelarla
	# también dejaría la vuelta descuadrada.
	if sistema != null and sistema.congela_la_mesa():
		var quieta := mesa.bola_en_peligro()
		camara.avanzar(delta, quieta.pos.y, quieta.vel.y, false)
		return
	# Durante la ruleta la simulación NO corre y las palas no mueven nada, pero
	# la cámara sí: baja hasta el ancla de abajo, que es donde está la tele.
	# Congelar también la cámara dejaría la tele fuera de plano justo cuando es
	# lo único que hay que mirar.
	if _en_ruleta:
		camara.avanzar(delta, 0.0, 0.0, false)
		return
	# LAS CUATRO PALAS CON LAS MISMAS DOS TECLAS, y es lo que hace una máquina de
	# verdad con un flipper superior: el botón izquierdo mueve todas las
	# izquierdas. No se aprende un control nuevo, se aprende una mesa nueva — y
	# como la planta alta y la de abajo nunca se juegan a la vez (el umbral no
	# traga con multibola), no hay ambigüedad posible.
	var izq := Input.is_physical_key_pressed(KEY_A) \
		or Input.is_physical_key_pressed(KEY_LEFT) \
		or Input.is_physical_key_pressed(KEY_SHIFT)
	var der := Input.is_physical_key_pressed(KEY_D) \
		or Input.is_physical_key_pressed(KEY_RIGHT) \
		or Input.is_physical_key_pressed(KEY_CTRL)
	mesa.flipper_izq.pulsado = izq
	mesa.flipper_alto_izq.pulsado = izq
	mesa.flipper_der.pulsado = der
	mesa.flipper_alto_der.pulsado = der

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
	#
	# CON VARIAS BOLAS MIRA LA MÁS BAJA (decisión de Daniel). A la cámara se le
	# sigue pasando UNA bola, así que las cuatro reglas y el escalado entero no se
	# tocan: no hay zoom, y sin zoom el pixelart no hierve. El efecto secundario
	# es parte de la elección — con dos bolas casi siempre hay una abajo, así que
	# durante una multibola la cámara vive anclada en la banda de las palas, que
	# es donde se juega.
	var seguida := mesa.bola_en_peligro()
	camara.avanzar(delta, seguida.pos.y, seguida.vel.y, mesa.bolas_vivas() > 0)

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

## QUÉ PIEZA TOCA AHORA. Se llama cada fotograma y no dispara nada por su
## cuenta: mira el estado y lo dice. `NodoMusica.poner` con lo que ya suena no
## hace nada, así que aquí no hay que acordarse de apagar ni de encender.
##
## ESO ES LA DECISIÓN, no un detalle de implementación. La otra forma de
## escribir esto es que cada sitio que cambia de pantalla ponga su música al
## pasar, y eso es exactamente la avería de la caza que cruzaba de un combate
## al siguiente: un estado que se enciende en un sitio y hay que acordarse de
## apagar en otro acaba puesto donde no toca. Preguntando cada fotograma no hay
## nada que se quede encendido.
##
## El orden de los casos ES la prioridad, y va de lo más raro a lo más común:
## lo de arriba tapa a lo de abajo.
func _musica_que_toca() -> void:
	if _musica == null:
		return
	# CON VARIAS BOLAS LA MÚSICA SE AGACHA (`prompts_musica.md` §3). Cuatro
	# bolas son cuatro veces más golpes por segundo, y ahí la música estorba.
	_musica.agachar(mesa != null and mesa.bolas.size() > 1)

	if tilt != null and tilt.visible:
		_musica.poner("tilt")
		return
	# La carpeta RECUPERADO manda sobre todo lo demás porque es lo único que se
	# abre ENCIMA de otra cosa: se llega a ella desde el escritorio o desde el
	# menú de Inicio, y su pieza es la recompensa de `PROPÓSITO.md` §2.
	if sistema != null and sistema.abierto == "recuperado":
		_musica.poner("recuperado")
		return
	# Y CUALQUIER OTRA VENTANA DEL SISTEMA TAMBIÉN MANDA, porque congela la
	# mesa: con la preparación o la papelera delante ya no se está jugando, se
	# está en la cáscara, y la pieza de la cáscara es `escritorio`. Se pregunta
	# por `congela_la_mesa` y no por `hay_algo` a propósito — el menú de Inicio
	# abierto no congela nada, así que no cambia lo que suena.
	if sistema != null and sistema.congela_la_mesa():
		_musica.poner("escritorio")
		return
	if mesa != null and mesa.en_caza:
		_musica.poner("caza")
		return
	if not _en_mapa and run != null and not run.terminada():
		var n := run.nodo_actual()
		var es_jefe: bool = n != null and n.tipo == NodoMapa.Tipo.JEFE
		_musica.poner("jefe" if es_jefe else "combate")
		return
	if _en_mapa and _pantalla_mapa != null and _pantalla_mapa.visible:
		_musica.poner("mapa")
		return
	_musica.poner("escritorio")

func _process(delta: float) -> void:
	_tiempo += delta
	_musica_que_toca()
	# El reloj de la descarga lo lleva la mesa; aquí solo se copia para poder
	# dibujarla vaciándose entre subpasos. Copiar en vez de restar por nuestra
	# cuenta es lo que impide que la barra y el daño doblado dejen de cuadrar.
	_descarga = mesa.descarga_restante if mesa != null else 0.0
	_dormida = move_toward(_dormida, 1.0 if mesa.en_caza else 0.0, delta * 2.0)
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
	# El panel del enemigo lleva sus propias partículas, en coordenadas de
	# pantalla: hay que avanzárselas igual que a las de la mesa o se quedarían
	# congeladas y no caducarían nunca, que es la trampa de "todo efecto tiene
	# que caducar solo".
	if panel_enemigo != null:
		# Y de paso le decimos si estamos en hitstop. Las partículas siguen
		# corriendo durante el parón —son la capa visual—, pero los fotogramas
		# de la hoja no: 70 ms de parón se comerían justo el fotograma de golpe
		# que el parón quiere enseñar.
		panel_enemigo.enemigo.congelado = _hitstop > 0.0
		panel_enemigo.avanzar(delta)
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
		KEY_F2:
			# SUELTA UNA BOLA EXTRA A MANO, y solo con la depuración encendida
			# (F1 primero). Es banco de pruebas, no un atajo del juego: por el
			# camino normal la multibola sale de las reliquias de Caos, que son 5
			# de 50, o sea una de cada diez tiradas de ruleta, y con eso no se
			# puede juzgar si la multibola se juega bien.
			if _depuracion and combate != null and not combate.terminado():
				mesa.soltar_bola_extra()
		KEY_F3:
			# SUBE LA BOLA A LA PLANTA ALTA A MANO, y solo con la depuración
			# encendida (F1 primero). El andamio de capas que había aquí ya no
			# hace falta: la geometría de la planta alta usa capas de verdad
			# desde la tanda 0i.
			#
			# Lo pidió Fátima con estas palabras: *"si es de prueba vale, pero no
			# quiero cosas aleatorias para probar"*. El umbral se abre hoy en 3 de
			# cada 100 entradas al racimo, así que juzgar la planta alta por el
			# camino normal es juzgarla dos veces por run: lo que se está midiendo
			# es LA MESA, no la puerta de entrada (`CAZA.md` §5, puerta B).
			if _depuracion:
				mesa.abrir_caza_a_mano()
		KEY_ESCAPE:
			# ESC cierra lo que haya abierto ANTES de salir del juego. Antes
			# salía siempre, y con un menú de Inicio delante eso es cerrar la
			# partida por querer cerrar un menú. Para salir está "Apagar".
			if sistema != null and sistema.hay_algo():
				sistema.cerrar()
			else:
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
	# LA CÁSCARA REACCIONA (`PROPÓSITO.md` §8): el sistema escribe una línea en
	# el registro. Con multibola esto solo pasa con la ÚLTIMA bola —es la señal
	# `bola_drenada`, no `bola_perdida`—, así que la línea siempre corresponde
	# a un turno de verdad perdido.
	if sistema != null:
		var proceso := "cascabel.exe"
		if combate != null and combate.enemigo != null:
			proceso = combate.enemigo.nombre.to_lower().replace(" ", "_") + ".exe"
		sistema.anotar_registro("fallo de segmentacion en %s" % proceso)

## Ha caído una bola pero quedan otras. NO SUENA COMO UN DRENAJE, y esa es toda
## la gracia: el sonido de drenar es el que dice "has perdido el turno", y aquí
## no has perdido nada. Se queda en polvo, en el sitio, y sin sacudida.
func _al_perder_bola(_restantes: int, punto: Vector2) -> void:
	impactos.polvo(Vector2(punto.x, mesa.p.y_drenaje - 26.0), Vector2.UP,
		C_PIEDRA, 0.7)

## Ha entrado una bola extra. Se anuncia en el carril, que es de donde sale: si
## no se ve salir, aparece una bola de la nada en mitad de la pantalla.
func _al_entrar_bola_extra(punto: Vector2, _total: int) -> void:
	_sonido.reproducir("combo")
	impactos.polvo(punto, Vector2.UP, C_ORO_CLARO, 1.2)

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
			# LA CÁSCARA REACCIONA (`PROPÓSITO.md` §8): el cañón abre un cuadro de
			# error que se cierra solo. Es el golpe gordo de la mesa, así que es el
			# único que se gana un mueble nuevo en pantalla.
			if cascara != null:
				cascara.mostrar_error("kernel32.dll\nha dejado de responder")
		Rampa.Premio.MULTIPLICADOR:
			impactos.onda(punto, C_ORO_CLARO, 1.1)
		_:
			_sonido.reproducir("rampa_salida")
			impactos.onda(punto, C_ORO, 0.7)

## LA RAMPA QUE NO CORONA. Existía desde las capas de altura y no sonaba ni se
## veía, o sea que no existía: es la avería del platillo otra vez —un sistema que
## el jugador no ve se diagnostica como que falta—. Y ahora pasa de verdad, que
## es lo que la trae a esta tanda: la subida a la isla suelta a quien no le pega
## fuerte.
##
## El `ratio` (lo cerca que se quedó) NO toca el tono, y eso es una decisión
## medida, no un olvido: en 60 cazas sale entre 0,47 y 0,57 —cinco veces, todas
## en la misma banda—, así que mapearlo daría un ±5 % de tono que no se oye y
## haría creer que la información está dada. Cuando la subida sea fallable en
## grados y no en binario, aquí es donde se engancha.
func _al_fallar_rampa(punto: Vector2, _indice: int, _ratio: float) -> void:
	_sonido.reproducir("rampa_fallada")
	impactos.onda(punto, C_PIEDRA_LUZ, 0.5)

## LA BOLA VUELVE A APARECER POR LA BOCA POR LA QUE ENTRÓ. `rampa_fallada` ya
## sonó al quedarse sin cuesta, medio recorrido antes; lo que falta aquí es
## DÓNDE reaparece, que es lo único que el jugador necesita para llegar a
## tiempo. Sin la onda, la bola sale de un tubo oscuro sin avisar y lo que se
## siente es que el juego la ha escupido de la nada.
##
## Sin sonido a propósito: el fallo ya sonó. Dos sonidos para un fallo lo
## convierten en el evento más ruidoso de la mesa, y es el más corriente.
func _al_devolver_rampa(punto: Vector2, _indice: int) -> void:
	impactos.onda(punto, C_PIEDRA_LUZ, 0.7)

# ------------------------------------------------------- la barra de carga

var _carga: float = 0.0
var _carga_armada := false
## Cuánto queda de descarga, para dibujarla vaciándose. Se lleva aparte del reloj
## de la mesa porque la vista dibuja entre subpasos.
var _descarga: float = 0.0
var _descarga_total: float = 1.0

func _al_cambiar_carga(fraccion: float, armada: bool) -> void:
	# El aviso de LLENA suena una vez, cuando se llena: es una promesa que el
	# jugador tiene que oír aunque esté mirando la bola y no la barra.
	if armada and not _carga_armada:
		_sonido.reproducir("combo")
	_carga = fraccion
	_carga_armada = armada

func _al_empezar_descarga(punto: Vector2, segundos: float) -> void:
	_descarga = segundos
	_descarga_total = maxf(segundos, 0.001)
	_carga_armada = false
	_sonido.reproducir("rampa_fuerte")
	impactos.onda(punto, C_ORO_CLARO, 1.6)
	# LA CÁSCARA REACCIONA (`PROPÓSITO.md` §8): la barra de tareas parpadea
	# mientras dura la descarga, el mismo tiempo que la barra de la mesa.
	if cascara != null:
		cascara.parpadear_barra_tareas(segundos)

func _al_terminar_descarga() -> void:
	_descarga = 0.0

## CAERSE DE UNA ALTURA, las dos formas en el mismo sitio porque son el mismo
## evento (invariante de `CLAUDE.md`): salirse del borde de la isla y
## desprenderse de una rampa abierta se sienten igual en la mano.
##
## El polvo sale hacia arriba porque la bola llega de arriba: es material que
## salta del suelo, no chispas que salen de un golpe. Y no sacude la cámara — la
## sacudida está reservada al ataque del enemigo y a la búsqueda de bola, y
## caerse de la isla pasa 1,7 veces por caza: sacudir por algo tan corriente
## gasta el gesto. Si al jugarlo se pide peso, ese es el mando.
func _al_caer_bola(punto: Vector2, _desde: int, _hasta: int) -> void:
	_sonido.reproducir("caida")
	impactos.onda(punto, C_PIEDRA_LUZ, 0.8)
	impactos.polvo(punto, Vector2.UP, C_PIEDRA, 0.9)

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
	panel_enemigo.enemigo.recibir_dano()
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
		# LA CÁSCARA REACCIONA (`PROPÓSITO.md` §8): los iconos del escritorio dan
		# un salto. Solo en el paso de subida, con el mismo guardián que el
		# sonido: el reinicio a x1 no es un premio.
		if cascara != null:
			cascara.pulsar_iconos()
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
	panel_enemigo.enemigo.embestir()
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

## PLANTAR LA CÁMARA EN LA PLANTA ALTA. Lo pidió Fátima: *"un modo de cámara
## fija para el modo de caza no estaría mal si cabe todo en la pantalla: además,
## da sensación de estar en un bonus"*.
##
## La banda se saca de los parámetros de la mesa y no de dos números escritos
## aquí, que es la diferencia entre un encuadre y un encuadre que se queda viejo:
## la planta alta se está rediseñando (`CAZA.md` §3.1) y `arena_hombro_y`,
## `arena_techo_ry` y `arena_fondo_y` se van a mover.
##
## Si no cabe, `fijar_banda` no rompe nada: `y_de_banda()` devuelve −1 y la caza
## se juega con las cuatro reglas de siempre. Y el viaje hasta el encuadre lo hace
## el muelle, o sea que la cámara SUBE a la planta alta en vez de aparecer allí:
## ese cuarto de segundo de subida es la mitad de la sensación de bonus.
func _encuadrar_la_caza() -> void:
	if not camara.p.caza_camara_fija:
		return
	var m := camara.p.caza_margen
	camara.fijar_banda(
		mesa.p.arena_hombro_y - mesa.p.arena_techo_ry - m,
		mesa.p.arena_fondo_y + m)

## LA CAZA TE HA SALVADO LA BOLA. Se dice EN EL DESAGÜE de la planta alta, o
## sea donde el jugador acaba de ver desaparecer la bola: es el mismo criterio
## que la red de seguridad de abajo —un efecto se enseña donde se mide— y aquí
## importa el doble, porque una bola que se cae por un agujero y reaparece
## arriba sin decir nada no se lee como un salvabolas, se lee como un fallo.
##
## Va en verde y con SU PROPIO SONIDO. Estuvo sonando con el de `atrasar`, que
## es el de la red de seguridad de la planta baja, y eran dos mensajes distintos
## con la misma voz: aquel dice que el reloj se ha movido hacia atrás y este dice
## que sigues dentro del bonus. `salvaguarda` baja y vuelve a subir, que es la
## forma de lo que acaba de pasar y no la tiene ningún otro sonido de la mesa.
##
## Y lleva la cuenta, que es la única forma de que el jugador sepa que la mesa lo
## está sujetando y cuánto.
func _al_salvar_bola(punto: Vector2, salvadas: int) -> void:
	var donde := Vector2(Mesa.ANCHO * 0.5, mesa.p.arena_fondo_y - 30.0)
	_numeros.append({"pos": donde, "t": 1.2,
		"texto": "SALVADA x%d" % salvadas if salvadas > 1 else "SALVADA",
		"col": C_VERDE})
	impactos.onda(donde, C_VERDE, 1.4)
	impactos.chispas(punto, Vector2.UP, C_VERDE, 1.0)
	_sonido.reproducir("salvaguarda")

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
		# A LA PAPELERA. `DISEÑO.md` §3 dice que los monstruos son procesos: al
		# matarlos, el sistema los manda donde manda los procesos muertos.
		if guardado != null and combate.enemigo != null:
			guardado.apuntar_muerte(combate.enemigo.id)
		_sonido.reproducir("muerte")
		panel_enemigo.enemigo.morir()
		# LOS EFECTOS DE LA MUERTE VAN EN EL PANEL, no en `impactos`, que dibuja
		# en coordenadas de MUNDO: con el enemigo fuera de la mesa, esa explosión
		# saldría en el sitio vacío del tablero donde el enemigo estaba antes.
		# Es el mismo fallo de siempre —un efecto se muestra donde se mide— y
		# aquí se ve enseguida porque no hay nada que explotar ahí.
		var centro := panel_enemigo.centro()
		panel_enemigo.efectos.onda(centro, C_FUEGO, 2.2)
		panel_enemigo.efectos.chispas(centro, Vector2.ZERO, C_FUEGO, 3.0)
		panel_enemigo.efectos.polvo(centro, Vector2.ZERO, C_PIEDRA, 2.5)
		_sacudir(anim.sacudida_muerte)
		_hitstop = maxf(_hitstop, anim.hitstop)

# ------------------------------------------------------------------- dibujo

func _draw() -> void:
	# Las capas, de atrás a delante: escritorio y paneles (−10), suelo y adornos
	# (z −2, `_nodo_suelo`), la mesa aquí (0), el marco de su ventana (5), el
	# enemigo en su panel (8), el HUD (10), el mapa (20), TILT (40) y el puntero
	# (100). Todo lo que no es mesa va en CanvasLayer aparte para que no se lo
	# lleve la cámara. Aquí empieza la capa 0.
	# Sombreados de profundidad. Van translúcidos para que la piedra siga
	# viéndose por debajo; antes eran planos y tapaban el suelo.
	draw_rect(Rect2(20, 1160, 360, 120), Color(C_MESA_BAJA, 0.30))
	draw_rect(Rect2(358, 900, 22, 360), Color(C_CARRIL, 0.80))
	draw_rect(Rect2(0, int(mesa.p.y_drenaje) - 8, Mesa.ANCHO, 8), C_DRENAJE)

	# El enemigo NO se dibuja aquí ni está en la mesa: vive en `panel_enemigo`,
	# en la banda derecha, con material propio para el destello y la disolución.
	_dibujar_inlanes()
	# EL ORDEN ES LA ALTURA, y hay tres capas de terreno, no dos. Primero los
	# TÚNELES, que van por debajo del tablero; encima las plataformas, que son
	# terreno elevado; y encima de todo las rampas, que vuelan. Con las
	# plataformas antes que los túneles, el túnel que pasa por debajo de la isla
	# se dibujaba ENCIMA de la losa y se leía como un puente: exactamente lo
	# contrario de lo que es.
	_dibujar_rampas(true)
	_dibujar_plataformas()
	_dibujar_rampas(false)
	_dibujar_platillos()
	_dibujar_paredes()
	_dibujar_objetos()
	impactos.dibujar(self)
	_dibujar_bola()
	_dibujar_bolas_fuera()
	_dibujar_atrape()
	_dibujar_numeros()
	_dibujar_lanzador()
	_dibujar_carga()
	_dibujar_planta_dormida()
	_dibujar_velo()
	if _depuracion:
		_dibujar_depuracion()

## LA PLANTA DE ABAJO SE APAGA MIENTRAS JUEGAS ARRIBA (`CAZA.md` §3.7). Ya era
## medio cierto —las dos plantas no se juegan a la vez, el umbral no traga con
## multibola— y lo que faltaba era que SE VIERA: si las dos se dibujan igual de
## encendidas, la planta alta parece la misma mesa con la cámara subida, que es
## exactamente la queja que tumbó la versión anterior.
##
## No hace falta congelar nada: con una sola bola y esa bola arriba, abajo no hay
## nada que simular. Lo que cuesta es el píxel, y es un rectángulo.
##
## Entra y sale con una rampa de medio segundo: de golpe sería un corte de
## pantalla, y lo que se está contando es que te has ido a otro sitio, no que ha
## cambiado la escena.
func _dibujar_planta_dormida() -> void:
	if _dormida <= 0.005:
		return
	var y := mesa.p.arena_fondo_y
	draw_rect(Rect2(0, y, Mesa.ANCHO, mesa.p.y_drenaje + 8.0 - y),
		Color(C_CABINA, 0.82 * _dormida))

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
## El halo va en LA BOLA MÁS BAJA y no en `mesa.bola`: una bola atrapada en una
## cuna es, por definición, la que está más abajo de todas.
func _dibujar_atrape() -> void:
	if mesa.flipper_atrapando == null:
		return
	var b := mesa.bola_en_peligro()
	if not b.viva:
		return
	draw_circle(b.pos, mesa.p.radio_bola + 4.0, Color(C_ORO_CLARO, 0.55),
		false, 1.0)

## AVISOS DE LAS BOLAS QUE NO SE VEN, y esto no es un adorno: está medido.
##
## La mesa mide 1300 de alto y por la ventana caben 540, así que con la cámara
## siguiendo a UNA bola las demás se salen por definición. Mirándolo de verdad
## con el display virtual, **el 90 % de los fotogramas con dos o más bolas tenía
## alguna fuera de plano**, y casi siempre por arriba: la que está dando la
## vuelta a la órbita.
##
## Con una bola esto no podía pasar y por eso no existía. La salida NO es alejar
## la cámara —rompe el escalado entero y la mesa hierve, ver `CLAUDE.md`—: es
## decir DÓNDE está lo que no se ve, que es lo que hace una mesa de verdad con
## sus luces. Una punta de flecha pegada al borde por el que se ha ido, en la x
## de la bola, y del tamaño de la bola para que se lea como "una bola ahí".
func _dibujar_bolas_fuera() -> void:
	if mesa.bolas.size() < 2:
		return
	var rect := camara.rect_visible()
	# Por arriba hay que bajar lo que mide el marco de la ventana de la mesa: la
	# cáscara se dibuja en la capa 5 y la mesa en la 0, así que una flecha pegada
	# al canto de la pantalla queda DETRÁS de la barra de título y no se ve. Es la
	# misma trampa que escondía la bola en lo alto de la órbita, y por eso el
	# número sale del mismo sitio que usa la cámara y no de una constante nueva.
	var arriba := rect.position.y + cam.alto_franja_hud + AVISO_MARGEN
	var abajo := rect.position.y + rect.size.y - AVISO_MARGEN
	var r := mesa.p.radio_bola
	for b in mesa.bolas:
		if not b.viva:
			continue
		var sube := b.pos.y < rect.position.y
		var baja := b.pos.y > rect.position.y + rect.size.y
		if not (sube or baja):
			continue
		# En píxeles enteros como todo lo demás: en fracciones, la flecha
		# tirita contra la rejilla mientras la bola se mueve.
		var x := roundf(clampf(b.pos.x, 20.0 + r, Mesa.ANCHO - 20.0 - r))
		var y := roundf(arriba if sube else abajo)
		var dir := -1.0 if sube else 1.0
		# Cuanto más lejos está la bola, más pálida la flecha: así el borde
		# distingue "se acaba de salir" de "está en lo alto de la órbita".
		var lejos := absf(b.pos.y - (rect.position.y if sube
			else rect.position.y + rect.size.y))
		var alfa := clampf(1.0 - lejos / AVISO_ALCANCE, 0.25, 1.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - r, y - r * dir),
			Vector2(x + r, y - r * dir),
			Vector2(x, y + r * dir),
		]), Color(C_ORO, alfa))

## El medidor de carga del lanzador va pegado al carril, en el mundo: es parte
## de la mesa, no del HUD.
func _dibujar_lanzador() -> void:
	if not (mesa.cargando or mesa.carga_lanzador > 0.0):
		return
	draw_rect(Rect2(366, 1200, 6, 50), C_CABINA)
	var alto := 50.0 * mesa.carga_lanzador
	draw_rect(Rect2(366, 1250 - alto, 6, alto), C_ORO)

## LA BARRA DE CARGA, y es literalmente una barra de progreso de Windows
## (`PROPÓSITO.md` §6). Va en el delantal, abajo del todo y cruzando la mesa: es
## el único trozo de tablero que no se juega, y es donde una máquina de verdad
## pone la chapa serigrafiada.
##
## VA EN EL MUNDO Y NO EN EL HUD, por lo mismo que el medidor del lanzador: lo
## que mide es cómo de fuerte le estás pegando A LA MESA, y leerlo obliga a
## mirar el tablero, no el marco. Un dato de mesa en el HUD se convierte en un
## número, y `DISEÑO.md` dice que la mesa es un menú de tiros, no un marcador.
##
## Tres estados y se leen de un vistazo, que es todo lo que se le pide:
##   - **llenándose**: bloques de oro sobre el hueco hundido.
##   - **llena**: parpadea entera. Es una promesa sin cobrar.
##   - **descargando**: se vacía de derecha a izquierda en cuatro segundos, en
##     claro. Es un cronómetro, y por eso se vacía en vez de llenarse.
const CARGA_CAJA := Rect2(56, 1264, 288, 14)
const CARGA_BLOQUES := 24

func _dibujar_carga() -> void:
	var caja := CARGA_CAJA
	# El hueco hundido: claro abajo-derecha, oscuro arriba-izquierda. Es el
	# bisel de Windows y es lo que hace que se lea como un hueco y no como una
	# pegatina.
	draw_rect(caja.grow(1.0), C_PARED_LUZ)
	draw_rect(caja, C_CABINA)
	draw_line(caja.position, Vector2(caja.end.x, caja.position.y), C_PARED, 1.0)
	draw_line(caja.position, Vector2(caja.position.x, caja.end.y), C_PARED, 1.0)
	var lleno := _carga
	var color := C_ORO
	if _descarga > 0.0:
		lleno = _descarga / _descarga_total
		color = C_ORO_CLARO
	elif _carga_armada:
		# Parpadeo de medio segundo. No se apaga del todo: una barra llena que
		# desaparece se lee como que se ha perdido.
		color = C_ORO_CLARO if fmod(_tiempo, 0.5) < 0.25 else C_ORO
	var bloques := int(round(lleno * float(CARGA_BLOQUES)))
	var ancho := (caja.size.x - 4.0) / float(CARGA_BLOQUES)
	for i in bloques:
		draw_rect(Rect2(caja.position.x + 2.0 + float(i) * ancho,
			caja.position.y + 2.0, ancho - 1.0, caja.size.y - 4.0), color)

## La órbita es una curva, no paredes, así que se dibuja como lo que es: un
## carril elevado. La bola se pinta después, encima, porque va por arriba.
## Qué paga cada recorrido, escrito en su boca. `DISEÑO.md` §1 dice que la mesa
## es un menú de tiros, y un menú sin los platos escritos no es un menú: Daniel
## jugó una tanda entera sin llegar a saber qué era el platillo.
## Y VA POR NOMBRE, NO POR PREMIO. Estuvo indexada por premio y en cuanto la
## planta alta tuvo recorridos propios empezó a mentir: la subida a la isla paga
## `DANO_FUERTE` igual que el cañón, así que el rótulo de la boca de arriba decía
## "CANON DANO x2" a un metro de donde está el cañón de verdad. Es la trampa de
## "un identificador no es un rótulo" otra vez, y se ve jugando, no en la batería.
##
## Lo que se lee tiene que decir A DÓNDE VA ese recorrido; lo que paga lo decide
## el premio, y son dos cosas distintas.
const ETIQUETA_RAMPA := {
	"orbita": "MULTIPLICADOR",
	"retorno": "OTRA PALA",
	"canon": "CANON  DANO x2",
	"orbita_alta": "MULTIPLICADOR",
	"subida_isla": "A LA ISLA",
}

## UNA PLATAFORMA SE TIENE QUE VER, O ES UNA TRAMPA. Lo único que hace en la
## física es cambiar de capa a quien se sale de ella, así que si el jugador no
## sabe dónde acaba, caerse no es información: es que el juego le quita la bola
## sin decir por qué.
##
## Se dibuja como suelo elevado —relleno claro— con el BORDE marcado, que es lo
## que hay que leer de un vistazo: no importa dónde está el centro, importa
## dónde se acaba.
func _dibujar_plataformas() -> void:
	for pl in mesa.plataformas:
		var puntos := pl.poligono
		if puntos.size() < 3:
			var r := pl.region
			puntos = PackedVector2Array([
				r.position, r.position + Vector2(r.size.x, 0),
				r.end, r.position + Vector2(0, r.size.y)])
		# LO QUE HACE QUE UNA LOSA SE LEA COMO ALTA ES EL CANTO, NO LA SOMBRA.
		# La primera versión era el polígono translúcido con una sombra oscura
		# detrás, y encima de un tablero casi negro eso no dice nada: parecía un
		# panel de la cáscara puesto encima del campo. Lo que se lee en dos
		# dimensiones es un bloque: una cara de arriba clara y OPACA, un canto
		# recto y oscuro debajo, y una sombra dura más allá. Son tres piezas y
		# hacen falta las tres.
		var canto := GROSOR_PLATAFORMA
		var sombra := PackedVector2Array()
		var lateral := PackedVector2Array()
		for punto in puntos:
			sombra.append(punto + Vector2(canto + 5.0, canto + 5.0))
			lateral.append(punto + Vector2(0, canto))
		draw_colored_polygon(sombra, C_CABINA)
		# El canto es la cara de abajo desplazada MÁS la de arriba: entre las dos
		# queda la banda vertical que es el grosor de la losa.
		draw_colored_polygon(lateral, C_PIEDRA_CANTO)
		draw_colored_polygon(puntos, C_PIEDRA)
		var cerrado := puntos
		cerrado.append(puntos[0])
		# El filo de arriba con luz: es el que separa la cara del canto.
		draw_polyline(cerrado, C_PIEDRA_LUZ, 2.0)

## Las tiras de tablero que cruzan por encima de un túnel. Son lo que dice que
## la curva va por DEBAJO: sin ellas es una rampa pintada de otro color.
func _tapar_a_trozos(puntos: PackedVector2Array) -> void:
	var recorrido := 0.0
	for i in puntos.size() - 1:
		var a := puntos[i]
		var b := puntos[i + 1]
		var tramo := a.distance_to(b)
		if tramo <= 0.001:
			continue
		# Un trozo tapado de 14 px cada 26: la bola mide 18, así que se ve pasar
		# por los huecos sin que llegue a desaparecer del todo.
		var d := 0.0
		while d < tramo:
			var global := recorrido + d
			if int(global / 26.0) % 2 == 0:
				var t0 := d / tramo
				var t1 := minf(d + 14.0, tramo) / tramo
				draw_line(a.lerp(b, t0), a.lerp(b, t1), C_MESA, 19.0)
			d += 14.0
		recorrido += tramo

## `bajo_tierra` parte el dibujo en las dos alturas: los túneles se pintan antes
## que las plataformas y las rampas después, porque un túnel pasa por debajo de
## una isla y una rampa por encima.
func _dibujar_rampas(bajo_tierra: bool) -> void:
	for r in mesa.rampas:
		if r.subterranea != bajo_tierra:
			continue
		# UN TÚNEL VA POR DEBAJO DEL TABLERO y se dibuja como tal: sin la tira
		# clara que hace que una rampa parezca elevada, y con la boca apagada.
		# Es lo único que lo separa de una rampa, porque en la física son la
		# misma curva.
		# UN TÚNEL ES UN AGUJERO, Y UN AGUJERO SE LEE POR LOS BORDES. Pintado de
		# negro sobre un tablero casi negro no se veía nada. Lo que lo cuenta es
		# que EL TABLERO PASA POR ENCIMA: se dibuja el canal oscuro y luego se
		# tapa a trozos con el color del tablero, así que se ve a rachas, como
		# una alcantarilla. Y las dos bocas van marcadas, que es por donde de
		# verdad interactúas con él.
		if r.subterranea:
			draw_polyline(r.puntos, C_CABINA, 17.0)
			draw_polyline(r.puntos, Color(C_PIEDRA_CANTO, 0.9), 11.0)
			_tapar_a_trozos(r.puntos)
			for extremo in [r.puntos[0], r.puntos[r.puntos.size() - 1]]:
				draw_circle(extremo, r.entrada_radio, C_CABINA)
				draw_circle(extremo, r.entrada_radio, C_PIEDRA_LUZ, false, 2.0)
			continue
		draw_polyline(r.puntos, Color(C_CABINA, 0.85), 15.0)
		draw_polyline(r.puntos, Color(C_MESA_BAJA, 0.9), 11.0)
		draw_polyline(r.puntos, Color(C_PARED, 0.55), 1.0)
		var bocas := [r.puntos[0]] if not r.bidireccional \
			else [r.puntos[0], r.puntos[r.puntos.size() - 1]]
		for extremo in [r.puntos[0], r.puntos[r.puntos.size() - 1]]:
			draw_circle(extremo, r.entrada_radio, Color(C_ORO, 0.30))
			draw_circle(extremo, r.entrada_radio, C_ORO, false, 1.0)
		for boca in bocas:
			_etiqueta(boca, str(ETIQUETA_RAMPA.get(r.nombre, "")))

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
		# UNA PARED QUE SOLO EXISTE EN UNA CAPA NO ES UNA PARED DE LA MESA: es lo
		# que sostiene algo. Hoy son las cuatro de la falda de la isla, y la isla
		# ya dibuja su cara, su canto y su sombra en `_dibujar_plataformas`;
		# pintarlas otra vez como pared deja un recuadro claro metido 8 px dentro
		# de la losa, que se lee como un marco y no como un bloque.
		if c.capas != Colisionador.TODAS:
			continue
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
	for f in mesa.flippers:
		_dibujar_flipper(f)

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
##
## Se dibujan TODAS las que haya. Todas iguales y a propósito: una bola extra no
## es una bola de segunda, pega lo mismo y se pierde igual, y pintarla distinta
## haría creer que sí.
func _dibujar_bola() -> void:
	var escala := mesa.p.radio_bola * 2.0 / 20.0
	var mitad := Vector2(_tex_bola.get_width(), _tex_bola.get_height()) * 0.5
	for b in mesa.bolas:
		if not b.viva:
			continue
		if b.rampa >= 0:
			# POR UN TÚNEL LA BOLA NO SE VE. Va por debajo del tablero, así que
			# lo único que queda es un bulto oscuro moviéndose por la curva: es
			# lo que hace que un túnel se lea como túnel y no como una rampa
			# pintada de otro color.
			if (mesa.rampas[b.rampa] as Rampa).subterranea:
				draw_circle(b.pos, mesa.p.radio_bola * 0.7, Color(C_CABINA, 0.9))
				continue
			# Va por encima de la mesa: una sombra debajo lo cuenta sin texto.
			draw_circle(b.pos + Vector2(3, 6), mesa.p.radio_bola * 0.8,
				Color(C_CABINA, 0.5))
		elif b.capa > Mesa.CAPA_TABLERO:
			# Subida a una plataforma. La MISMA sombra que en una rampa, y a
			# propósito: para el jugador las dos cosas son "esta bola va por
			# arriba", y darles dos lenguajes distintos sería pedirle que
			# aprenda dos.
			draw_circle(b.pos + Vector2(3, 6), mesa.p.radio_bola * 0.8,
				Color(C_CABINA, 0.5))
		draw_set_transform(b.pos, 0.0, Vector2(escala, escala))
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
	for f in mesa.flippers:
		draw_line(f.eje, f.punta(), C_ARCANO, 1.0)
		draw_circle(f.eje, f.radio, C_ARCANO, false, 1.0)
		draw_circle(f.punta(), f.radio, C_ARCANO, false, 1.0)
	for b in mesa.bolas:
		if not b.viva:
			continue
		draw_circle(b.pos, mesa.p.radio_bola, C_ORO, false, 1.0)
		draw_line(b.pos, b.pos + b.vel * 0.08, C_ORO, 1.0)
