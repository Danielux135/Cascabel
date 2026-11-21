extends Node

## SEGUNDA PRUEBA 3D — «CRIPTA». Escena de usar y mirar: NO es Cascabel.
##
## Es `prueba3d/prueba_3d.gd` portada: la misma física, las mismas cámaras, el
## mismo piloto, las mismas capturas y los mismos mandos de calidad, sobre otra
## mesa (`mesa_cripta.gd`) y otro mundo (`mundo_cripta.gd` y sus ocho módulos).
## La caza es la de ÓRBITA sin tocar (`prueba3d/caza_orbita.gd`): aquí solo se
## les cambia el nombre a las criaturas, que es lo que se lee.
##
## EL MARCADOR vive en `marcador.gd`. Esta escena le dice QUÉ pasa (puntos, bola,
## multiplicador, campana, caza, avisos, cámara, calidad) y él decide CÓMO se
## enseña: aquí no hay ni una etiqueta ni una coordenada de pantalla.
##
##     Godot --path <repo> res://cripta3d/cripta_3d.tscn
##
## TECLAS
##   A / D (o flechas, o Mayús / Ctrl)   palas          ESPACIO   lanzar
##   C  cambiar de cámara                X  a qué criatura sigue la cámara
##   1 / 2 / 3  poner o quitar a BRASA, CALAVERA y ESPECTRO
##   M  bola extra      R  bola nueva    T  piloto automático
##   G  calidad         H  ayuda         F12  captura
##
## OPCIONES (detrás de `--`)
##   --capturas=<carpeta>  juega sola y deja una captura cada `--cada` segundos
##   --vista=N             con qué cámara: 0 SEGUIMIENTO, 1 RASANTE, 2 CENITAL,
##                         3 CORO, 4 PLAZA, 5 CRIATURA
##   --cada=2.5            cada cuánto captura
##   --criatura=N          a cuál sigue la cámara de CRIATURA
##   --piloto              juega sola
##   --demo                fuerza a mano los sucesos de la caza, para verlos
##   --guion=t:n:que,...   otro guion de sucesos forzados en vez del de `--demo`:
##                         segundo, a quién y qué. Ver `_forzar`, que los lista.
##   --ojo=x,y,z --mira=x,y,z [--fov=N]   cámara libre, en unidades 3D
##   --toma=ojo/mira[/fov] VARIAS cámaras libres en una lanzada (se repite la
##                         opción): cada captura sale desde la toma siguiente
##   --cuantas=N           cuántas capturas (12, o una por toma)
##   --ventana=1280x720    otra ventana, para mirar el marcador a otro tamaño o
##                         proporción (el `--resolution` de Godot no la cambia)
##   --medir               un renglón por segundo con lo que cuesta cada cosa
##   --calidad=alta|media|baja
##   --sin-marcador        esconde TODO el marcador, para capturas limpias
##   --reserva             monta el mundo con los materiales de reserva del
##                         núcleo en vez de con la biblioteca (para probarlos)
##
## No hay ninguna forma de salir escrita aquí, a propósito: la batería del juego
## prohíbe cualquier salida que no sea `VistaMesa.salir()`. Se cierra con Alt+F4,
## y en las capturas, con `--fotogramas`.
##
## EN EL NAVEGADOR arranca jugando sola hasta el primer clic o la primera tecla,
## porque hasta entonces el navegador no da ni teclado ni sonido; y las palas
## son solo A / D y las flechas, que Ctrl y Mayús con otra tecla son atajos suyos.

const MundoCripta := preload("res://cripta3d/mundo_cripta.gd")
const MesaCripta := preload("res://cripta3d/mesa_cripta.gd")
const Caza := preload("res://prueba3d/caza_orbita.gd")
const Criatura := preload("res://prueba3d/criatura.gd")
const Marcador := preload("res://cripta3d/marcador.gd")
const E := 0.01

## El posprocesado de pantalla es de otro módulo (`materiales/`): se usa el suyo
## en cuanto existe, y mientras tanto el de ÓRBITA.
const POST_CRIPTA := "res://cripta3d/materiales/post.gdshader"
const POST_ORBITA := "res://prueba3d/post.gdshader"

## Los colores de los avisos salen de la paleta del juego: marfil para lo que se
## lee, oro para lo que se celebra, rojo solo para la alerta.
const MARFIL := Paleta.TIERRA_6
const ORO := Paleta.ORO
const TENUE := Paleta.TIERRA_4
const ALERTA := Paleta.ROJO_LUZ

const VISTAS := ["SEGUIMIENTO", "RASANTE", "CENITAL", "CORO", "PLAZA", "CRIATURA"]

## La vista SEGUIMIENTO entre sus dos tomas: [bola arriba, bola abajo]. Ver
## `_seguimiento`, que dice qué se mide.
const SEGUIMIENTO_OJO: Array[Vector3] = [Vector3(2.0, 4.7, 14.85), Vector3(2.0, 3.8, 14.9)]
const SEGUIMIENTO_MIRA: Array[Vector3] = [Vector3(2.0, 0.0, 10.15), Vector3(2.0, 0.0, 10.5)]
const SEGUIMIENTO_FOV := 48.0

## Lo que vale cada recorrido. El rótulo no está aquí: sale de
## `MesaCripta.ROTULOS`, que es el único sitio donde un identificador se
## convierte en algo que se lee.
const TIROS := {"orbita": 1500, "cometa": 1200, "estacion": 1500, "gusano": 800}

## Lo que cuenta el marcador, en el orden en que lo enseña. Son claves de
## `MesaCripta.ROTULOS`. Si la mesa trae más bancos de dianas (los ESCUDOS), se
## cuelan detrás de las lápidas al arrancar: ver `_preparar_cuentas`.
const CUENTAS := ["bumpers", "targets", "orbita", "cometa", "estacion", "platillo", "gusano"]

## Lo que se dice al tumbar un banco entero, por su clave. El género no se puede
## sacar del rótulo, así que va escrito.
const AVISO_BANCO := {
	"targets": "%s ABATIDAS · BRASEROS ABIERTOS",
	"escudos": "%s ABATIDOS · LA CALLE DE FUERA SE ABRE",
}

## LA CAMPANA MAYOR es la barra de carga de la mesa (`mesa_cripta.gd`): toda
## entrada a una rampa la carga, llena queda ARMADA, y el siguiente recorrido que
## se COMPLETE la hace tocar. La regla de esta prueba: MIENTRAS TOCA, TODO VALE
## DOBLE. En el mundo se ve en la campana (`mundo/atrezzo.gd`); aquí, en el
## marcador y en el altavoz.
const DOBLE_CAMPANA := 2

## LA CALIDAD DE LOS GRÁFICOS, de más a menos. En escritorio va siempre en ALTA.
## En web no puede: el navegador de un portátil dibuja casi siempre con la
## gráfica INTEGRADA aunque el equipo tenga otra. Los números son los de ÓRBITA,
## medidos allí (Intel UHD, 1902×984): ALTA 35 por segundo, MEDIA 78, BAJA 90.
##   mp       MEGAPÍXELES como mucho a los que se dibuja el 3D, que luego se
##            estira a la ventana. Es un tope fijo y no una fracción de la
##            ventana a propósito: con una fracción, una pantalla 4K pediría
##            cuatro veces más píxeles a la misma gráfica.
##   escala   un multiplicador más encima de eso; solo se usa para medir
##   msaa     suavizado de bordes: 0, 2 o 4 muestras
##   reflejo  tamaño de la cámara del reflejo respecto a la principal; 0 = sin él
##   sombras  las de la luna. YA NO HACE NADA con el «entorno» de ahora: la luna
##            es un foco sin sombra, y la única sombra que queda (la de un fuego
##            del campo) la apaga el propio módulo en su `calidad(n)`. Se deja
##            por si un entorno futuro no supiera de calidades: ver
##            `_poner_calidad`
##   cielo    0 = el fondo pasa a color liso (si el entorno usa un cielo)
const CALIDADES := ["ALTA", "MEDIA", "BAJA"]
const AJUSTES_CALIDAD := {
	"ALTA": {"mp": 3.7, "escala": 1.0, "msaa": 4, "reflejo": 0.5, "brillo": 1,
		"sombras": 1, "cielo": 1},
	# MEDIA lleva 2 muestras de suavizado: es la calidad con la que arranca la
	# web, y sin ninguna las varillas de la escalera, los tirantes y las
	# barandillas se rompían en trazos (segunda mirada del crítico técnico).
	"MEDIA": {"mp": 1.05, "escala": 1.0, "msaa": 2, "reflejo": 0.4, "brillo": 1,
		"sombras": 0, "cielo": 1},
	"BAJA": {"mp": 0.67, "escala": 1.0, "msaa": 0, "reflejo": 0.0, "brillo": 1,
		"sombras": 0, "cielo": 1},
}

## Gráficas que se sabe que no pueden con ALTA: con una de estas el vigilante no
## la prueba, y así no hay tres segundos a tirones nada más empezar.
const GRAFICAS_FLOJAS := ["intel", "uhd graphics", "hd graphics", "iris", "mali",
	"adreno", "powervr", "videocore", "swiftshader", "llvmpipe", "basic render"]

## LAS CRIATURAS. La caza las llama por su especie de ÓRBITA; aquí cada especie
## es una criatura de Cascabel, y solo cambia lo que se lee.
const NOMBRES := {
	"saltarin": "BRASA", "gotita": "ASCUA", "escarabajo": "CALAVERA", "corredor": "ESPECTRO",
}
const COLOR_ESPECIE := {
	"saltarin": Paleta.NARANJA, "gotita": Paleta.NARANJA,
	"escarabajo": Paleta.TIERRA_5, "corredor": Paleta.ARCANO,
}
const CONSEJO := {
	"saltarin": "pártela · recoge las dos ascuas",
	"escarabajo": "por la espalda · vuélcala",
	"corredor": "asústalo a golpes · tápale las bocas",
}
## Lo que dura el combo: encadenar otro recorrido antes sube el multiplicador.
const DURACION_COMBO := 8.0

## En qué orden salen en el marcador, que es el de las teclas 1, 2 y 3.
const ORDEN_MARCADOR := ["saltarin", "escarabajo", "corredor"]

## La caza dice qué le pasa a cada una con palabras de ÓRBITA. Las dos que no
## valen aquí se cambian; y el espectro es «él», así que lo suyo va en masculino.
const ESTADOS := {"PANZA ARRIBA": "VOLCADA", "MITAD EN LA BOLA": "ASCUA EN LA BOLA"}
const MASCULINO := {
	"ACORRALADA": "ACORRALADO", "ASEGURADA": "ASEGURADO", "ESCONDIDA": "ESCONDIDO",
	"ATURDIDA": "ATURDIDO", "SUELTA": "SUELTO",
}

var mesa: MesaCripta
var caza: Caza
var mundo: MundoCripta
var vp: SubViewport
var vp_reflejo: SubViewport
var camara: Camera3D
var camara_reflejo: Camera3D
var pantalla: TextureRect
var sonido: NodoSonido
var marcador: Marcador
## Las tres del marcador, en el orden de `ORDEN_MARCADOR`.
var _del_marcador: Array[Criatura] = []

## Solo en web: la página acaba de abrirse y nadie ha tocado nada todavía.
var _web := OS.has_feature("web")
var _falta_clic := false
var _sin_marcador := false
var _reserva := false

## LA CARGA POR PARTES (ver `_preparar_carga`). En web, siempre; en escritorio,
## con `-- --como-web`, que es como se ensaya.
var _con_carga := false
var _cargando := false
## Lo que queda por compilar: [material, con instancias].
var _carga_pasos: Array = []
var _carga_hechos := 0
## Lo que se ha escondido para montar tapado: nodo → sus capas de verdad.
var _carga_capas: Dictionary = {}
## Los sombreadores que ya están en la lista (su huella, y si van con instancias).
var _carga_vistos: Dictionary = {}
## Los primeros cuadros de la carga, en los que se vuelve a recoger lo que los
## módulos crean tarde.
var _carga_cuadros := 0
var _carga_muestra: GeometryInstance3D = null
var _carga_t0 := 0
var _carga_reloj := 0
var _carga_apuntes: Array[String] = []
var _carga_destape := 0
var _telon: Telon = null
## PARA PROBAR (`-- --ssao`, o `?ssao=1` en web): la oclusión de pantalla. El
## renderizador Compatibility la tiene desde Godot 4.6 y «entorno» la daba por
## imposible. No va puesta: cambia el aspecto aprobado, y eso lo deciden Daniel
## y Fátima con la captura delante.
var _ssao := false

## Calidad en uso, lo que vale cada mando y el vigilante que la baja sola.
var calidad := 0
var _cal: Dictionary = {}
var _cal_forzado: Dictionary = {}
var _cal_auto := false
var _cal_t := 0.0
var _cal_n := 0
var _cal_espera := 3.0
var _cal_tope := 0
var _cal_sobrada := 0.0
var _cal_reintento := 6.0
var _cal_desde_subida := 1.0e9
var _grafica := ""
## El fondo que puso el entorno al montarse: es al que se vuelve con "cielo" a 1.
var _fondo_propio: Environment.BGMode = Environment.BG_COLOR

## EL MEDIDOR (`-- --medir` en escritorio, `?medir=1` en web): cada segundo dice
## cuánto se lleva la física, cuánto este guion y cuántas llamadas de dibujo
## salen. No es una prueba: no falla, informa.
var _medir := false
var _med_fisica := 0
var _med_proceso := 0
var _med_n := 0
var _med_t := 0.0
var _med_pico := 0.0
var _med_antes := 0
## PARA BUSCAR UN TIRÓN (`-- --medir --tirones`, `?medir=1&tirones=1`): además
## de lo que dice `--medir`, apunta QUÉ PIEZA se ha visto por primera vez en el
## fotograma largo. Va aparte porque mira el mundo entero en cada fotograma
## (medio milisegundo) y eso falsearía las cifras de `--medir`.
var _tirones := false
var _tir_vistas: Dictionary = {}
var _tir_recien := PackedStringArray()
## PARA MEDIR (`-- --sin-relleno`, `?relleno=0`): en web, sin las dos luces de
## relleno ni el entorno del reflejo igualado (`MundoCripta._unificar_variantes`).
## Las dos luces se cuentan en cada píxel de todo lo alumbrado; en una gráfica
## buena no se nota, y en una integrada no está medido. Con esto se compara.
var _sin_relleno := false

var vista := 0
var piloto := false
var puntos := 0
var multiplicador := 1
var bola_numero := 1
var criatura_camara := 0
var cuentas: Dictionary = {}
## Las claves de `cuentas` en el orden en que salen en el marcador.
var _orden_cuentas: Array[String] = []

## La campana: si estaba armada (para avisar solo al armarse) y si acaba de
## empezar a tocar (para decirlo en el mismo aviso del recorrido que la tocó).
var _campana_armada := false
var _campana_recien := false

var _pide_bola := false
var _tiempo := 0.0
var _combo := 0.0
var _cam_t := 1.0
var _cam_x := 0.0
var _cam_bicho := Vector3(2.14, 0.0, 10.18)
var _pulso_i := 0.0
var _pulso_d := 0.0
var _descanso_i := 0.0
var _descanso_d := 0.0
var _carga_piloto := 0.0
var _izq_antes := false
var _der_antes := false
var _rng := RandomNumberGenerator.new()

## Capturas automáticas, para mirar la prueba sin jugarla:
##     ... res://cripta3d/cripta_3d.tscn -- --capturas=C:/ruta --vista=4 --demo
## `--demo` va forzando a mano los sucesos de la caza —un golpe, una rendición,
## una recogida—, para poder ver cada estado sin esperar a que el piloto acierte.
var _dir_capturas := ""
var _capturas_hechas := 0
var _cada := 2.5
var _demo := false
var _guion: Array = []

## La cámara libre de las capturas. Ver `_process`.
var _camara_libre := false
var _ojo_libre := Vector3(2.0, 5.0, 15.0)
var _mira_libre := Vector3(2.0, 0.0, 9.5)
var _fov_libre := 40.0
## LAS TOMAS (`--toma=ojo/mira[/fov]`, repetida): varias cámaras libres en una
## sola lanzada. Cada captura sale desde la toma siguiente, por orden, y al
## acabarlas vuelve a empezar; el fichero se llama `tNN_VV.png` (toma y vuelta).
## Ahorra una lanzada de Godot por cada pieza que se quiera mirar de cerca.
var _tomas: Array = []
## Cuántas capturas se hacen. 0 = las de siempre: 12, o una por toma.
var _cuantas := 0
var _guion_pedido := ""

## "1.5,0.4,9" → Vector3. Si viene mal escrito se queda el que había.
func _vector_de(texto: String, por_defecto: Vector3) -> Vector3:
	var t := texto.split(",")
	if t.size() != 3:
		return por_defecto
	return Vector3(float(t[0]), float(t[1]), float(t[2]))

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capturas="):
			_dir_capturas = arg.trim_prefix("--capturas=")
			piloto = true
		elif arg.begins_with("--vista="):
			vista = clampi(int(arg.trim_prefix("--vista=")), 0, VISTAS.size() - 1)
		elif arg.begins_with("--cada="):
			_cada = float(arg.trim_prefix("--cada="))
		elif arg.begins_with("--criatura="):
			criatura_camara = maxi(int(arg.trim_prefix("--criatura=")), 0)
		elif arg == "--piloto":
			piloto = true
		elif arg == "--demo":
			_demo = true
		elif arg == "--medir":
			_medir = true
		elif arg == "--tirones":
			_tirones = true
		elif arg == "--sin-marcador":
			_sin_marcador = true
		elif arg == "--reserva":
			_reserva = true
		elif arg == "--como-web":
			_con_carga = true
		elif arg == "--ssao":
			_ssao = true
		elif arg == "--sin-relleno":
			_sin_relleno = true
		elif arg.begins_with("--ojo="):
			_ojo_libre = _vector_de(arg.trim_prefix("--ojo="), _ojo_libre)
			_camara_libre = true
		elif arg.begins_with("--mira="):
			_mira_libre = _vector_de(arg.trim_prefix("--mira="), _mira_libre)
			_camara_libre = true
		elif arg.begins_with("--fov="):
			_fov_libre = clampf(float(arg.trim_prefix("--fov=")), 5.0, 120.0)
		elif arg.begins_with("--toma="):
			var trozos := arg.trim_prefix("--toma=").split("/")
			if trozos.size() >= 2:
				_tomas.append([_vector_de(trozos[0], _ojo_libre),
					_vector_de(trozos[1], _mira_libre),
					clampf(float(trozos[2]), 5.0, 120.0) if trozos.size() > 2 else 40.0])
		elif arg.begins_with("--cuantas="):
			_cuantas = maxi(int(arg.trim_prefix("--cuantas=")), 1)
		elif arg.begins_with("--guion="):
			_guion_pedido = arg.trim_prefix("--guion=")
		elif arg.begins_with("--ventana="):
			# El proyecto arranca a pantalla completa y `--resolution` de Godot no
			# le cambia el tamaño (medido: `godot3d.py --res 1280x720` seguía
			# dando capturas de 1920×1080). Para mirar el marcador en otra
			# ventana hay que pedírselo a la escena: `-- --ventana=1280x720`.
			var lados := arg.trim_prefix("--ventana=").split("x")
			if lados.size() == 2 and int(lados[0]) > 0 and int(lados[1]) > 0:
				get_window().mode = Window.MODE_WINDOWED
				get_window().size = Vector2i(int(lados[0]), int(lados[1]))
		elif arg.begins_with("--calidad="):
			calidad = maxi(CALIDADES.find(arg.trim_prefix("--calidad=").to_upper()), 0)
	if _dir_capturas != "":
		DirAccess.make_dir_recursive_absolute(_dir_capturas)

	# El proyecto escala por enteros, que es lo suyo para el pixelart del juego.
	# Aquí no hay pixelart, y en una pestaña de navegador casi nunca caben dos
	# veces 960×540: por enteros el marcador se quedaría a ×1, diminuto.
	get_window().content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	get_window().title = "Cascabel 3D · CRIPTA"
	if _web:
		piloto = true
		_falta_clic = true
		_con_carga = true
		_leer_direccion()

	mesa = MesaCripta.new()
	caza = Caza.new()
	caza.preparar(mesa, 3)
	# Un identificador no es un rótulo: la especie se queda, el nombre cambia.
	for c: Criatura in caza.criaturas:
		c.nombre = NOMBRES.get(c.especie, c.nombre)
	for especie: String in ORDEN_MARCADOR:
		for c: Criatura in caza.principales():
			if c.especie == especie:
				_del_marcador.append(c)
	mesa.caza = caza
	_preparar_cuentas()
	mesa.nueva_bola()
	_conectar_reglas()
	_conectar_caza()

	sonido = NodoSonido.new()
	add_child(sonido)

	# Dos vistas del MISMO mundo: la del jugador y la del reflejo, que mira la
	# mesa desde debajo del suelo. La del reflejo va antes en el árbol para que
	# su imagen esté lista cuando el suelo la pida.
	var mundo3d := World3D.new()
	vp_reflejo = SubViewport.new()
	vp_reflejo.world_3d = mundo3d
	vp_reflejo.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp_reflejo)
	vp = SubViewport.new()
	vp.world_3d = mundo3d
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	add_child(vp)

	mundo = MundoCripta.new()
	mundo.forzar_reserva = _reserva
	mundo.sin_relleno = _sin_relleno
	vp.add_child(mundo)
	mundo.montar(mesa)
	mundo.montar_caza(caza)
	_fondo_propio = mundo.entorno.background_mode
	if _ssao:
		mundo.entorno.ssao_enabled = true
		mundo.entorno.ssao_radius = 0.45
		mundo.entorno.ssao_intensity = 1.6
		mundo.entorno.ssao_power = 1.3
		mundo.entorno.ssao_light_affect = 0.15

	camara = Camera3D.new()
	camara.near = 0.1
	camara.far = 200.0
	vp.add_child(camara)
	camara.current = true
	camara_reflejo = Camera3D.new()
	camara_reflejo.near = 0.1
	camara_reflejo.far = 200.0
	camara_reflejo.cull_mask = 1
	camara_reflejo.environment = mundo.entorno_reflejo
	vp_reflejo.add_child(camara_reflejo)
	camara_reflejo.current = true
	if mundo.mat_suelo != null:
		mundo.mat_suelo.set_shader_parameter("reflejo", vp_reflejo.get_texture())

	var capa := CanvasLayer.new()
	add_child(capa)
	pantalla = TextureRect.new()
	pantalla.texture = vp.get_texture()
	pantalla.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pantalla.stretch_mode = TextureRect.STRETCH_SCALE
	pantalla.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var post := ShaderMaterial.new()
	post.shader = load(POST_CRIPTA if ResourceLoader.exists(POST_CRIPTA) else POST_ORBITA)
	pantalla.material = post
	capa.add_child(pantalla)

	_montar_marcador(capa)
	get_viewport().size_changed.connect(_ajustar_pantalla)
	_poner_calidad(calidad)

	if _cuantas == 0:
		_cuantas = maxi(_tomas.size(), 1) if not _tomas.is_empty() else 12
	if _guion_pedido != "":
		_guion = _leer_guion(_guion_pedido)
	elif _demo:
		# Índices de `caza.criaturas`: 0 ESPECTRO, 1 BRASA, 2 CALAVERA. Tiempo,
		# quién y qué.
		_guion = [
			[5.2, 0, "golpe"], [5.6, 1, "golpe"], [8.4, 0, "golpe"],
			[9.4, 2, "golpe"], [10.6, 0, "rendir"], [13.2, 0, "recoger"],
			[14.0, 2, "recoger"],
		]
	if _con_carga:
		_preparar_carga(capa)

# ------------------------------------------------------------------------ carga

## LA CARGA POR PARTES (en web; en escritorio, con `-- --como-web`).
##
## En un navegador de Windows cada sombreador tarda en compilar entre tres
## décimas y varios segundos (`banco_sombreadores.gd`), y Godot los compila la
## primera vez que DIBUJA algo con ellos. Sin esto, el primer fotograma de la
## mesa los compilaba todos de golpe —el lienzo congelado sin una palabra— y
## luego, jugando, cada efecto que salía por primera vez (una chispa, la onda de
## un golpe, la campana) era un tirón.
##
## Así que la mesa se monta TAPADA. Se esconde todo lo que se dibuja, y delante
## de la cámara se va poniendo, uno por fotograma, un cuadradito con cada
## material que hay en el mundo —también los de lo que está escondido esperando
## su momento, que es lo que luego daría el tirón—. Cada fotograma compila uno
## y el telón dice por cuál va. Al acabar se destapa todo, ya compilado.
##
##   · Los cuadraditos van en una capa que la cámara del reflejo no mira.
##   · Lo que sale de partículas o de un `MultiMesh` se pone además CON
##     instancias, que para Godot es otro programa del mismo sombreador.
##   · Vale porque en web el núcleo deja una sola variante por sombreador
##     (`MundoCripta._unificar_variantes`): el programa que compila el
##     cuadradito es el mismo que usará la pieza de verdad.
##   · Mientras dura no corre la física ni el piloto: la mesa no se juega sola
##     detrás del telón.
const CAPA_DE_CARGA := 1 << 15

func _preparar_carga(capa: CanvasLayer) -> void:
	_recoger_para_cargar(mundo)
	_cargando = true
	_carga_cuadros = 0
	_carga_t0 = Time.get_ticks_msec()
	_telon = Telon.new()
	_telon.total = _carga_pasos.size()
	_telon.en_web = _web
	_telon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_telon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_telon)

## Apunta cada cosa que se dibuja y la ESCONDE (se queda sin capas), y apunta
## cada material distinto que lleva, para compilarlo. Dos materiales con el
## mismo sombreador son el mismo programa: se cuentan una vez.
##
## SE LLAMA DOS VECES: al acabar de montar y otra vez tras el primer cuadro del
## mundo, porque hay módulos que crean piezas en su primer `actualizar` (el
## cielo del óculo y su halo esperan a que «arquitectura» diga dónde está el
## hueco). La primera versión solo miraba al montar: esos dos se quedaban fuera
## y se compilaban a la vista, medio segundo después de abrirse el telón.
func _recoger_para_cargar(nodo: Node) -> void:
	for hijo in nodo.get_children():
		_recoger_para_cargar(hijo)
	var gi := nodo as GeometryInstance3D
	if gi == null or gi == _carga_muestra:
		return
	if _carga_capas.has(gi):
		# Ya estaba escondido. Si vuelve a tener capas es que su módulo se las ha
		# puesto en su primer cuadro: esas son las buenas, y se esconde otra vez.
		# (Medido: sin esto la piedra se compilaba a destiempo, en el primer paso,
		# y al destapar se le devolvían unas capas que ya no eran las suyas.)
		if gi.layers != 0:
			_carga_capas[gi] = gi.layers
			gi.layers = 0
		return
	_carga_capas[gi] = gi.layers
	gi.layers = 0
	var con_instancias := gi is MultiMeshInstance3D or gi is CPUParticles3D \
		or gi is GPUParticles3D
	for de_la_pieza: Material in _materiales_de(gi):
		var m := de_la_pieza
		while m != null:
			var clave := _clave_de_carga(m, con_instancias)
			if not _carga_vistos.has(clave):
				_carga_vistos[clave] = true
				_carga_pasos.append([m, con_instancias])
			m = m.next_pass

## Lo que distingue un programa de otro para la carga: el sombreador (o el
## material entero, si es de los de Godot) y si va con instancias.
func _clave_de_carga(m: Material, con_instancias: bool) -> String:
	var sombreado := m as ShaderMaterial
	var huella := m.get_rid().get_id()
	if sombreado != null and sombreado.shader != null:
		huella = sombreado.shader.get_rid().get_id()
	return "%d/%d" % [huella, int(con_instancias)]

func _nombre_de_carga(m: Material, con_instancias: bool) -> String:
	var nombre := m.get_class()
	var sombreado := m as ShaderMaterial
	if sombreado != null and sombreado.shader != null:
		nombre = sombreado.shader.resource_path.get_file()
	return nombre + (" (instancias)" if con_instancias else "")

func _materiales_de(gi: GeometryInstance3D) -> Array[Material]:
	var lista: Array[Material] = []
	if gi.material_override != null:
		lista.append(gi.material_override)
	else:
		var malla: Mesh = null
		var pieza := gi as MeshInstance3D
		if pieza != null:
			if pieza.mesh != null:
				for s in pieza.mesh.get_surface_count():
					var activo := pieza.get_active_material(s)
					if activo != null:
						lista.append(activo)
		elif gi is MultiMeshInstance3D:
			var varias := (gi as MultiMeshInstance3D).multimesh
			malla = varias.mesh if varias != null else null
		elif gi is CPUParticles3D:
			malla = (gi as CPUParticles3D).mesh
		if malla != null:
			for s in malla.get_surface_count():
				var suyo := malla.surface_get_material(s)
				if suyo != null:
					lista.append(suyo)
	if gi.material_overlay != null:
		lista.append(gi.material_overlay)
	return lista

## Un paso por fotograma, al final de `_process`, con la cámara ya en su sitio.
func _avanzar_carga() -> void:
	_apuntar_paso()
	if _carga_muestra != null:
		_carga_muestra.queue_free()
		_carga_muestra = null
	if _carga_hechos >= _carga_pasos.size():
		_destapar()
		return
	var paso: Array = _carga_pasos[_carga_hechos]
	_carga_hechos += 1
	var cuadro := QuadMesh.new()
	cuadro.size = Vector2(0.04, 0.04)
	if bool(paso[1]):
		var varias := MultiMesh.new()
		varias.transform_format = MultiMesh.TRANSFORM_3D
		varias.use_colors = true
		varias.use_custom_data = true
		varias.mesh = cuadro
		varias.instance_count = 1
		varias.set_instance_transform(0, Transform3D.IDENTITY)
		varias.set_instance_color(0, Color.WHITE)
		var con_varias := MultiMeshInstance3D.new()
		con_varias.multimesh = varias
		_carga_muestra = con_varias
	else:
		var suelta := MeshInstance3D.new()
		suelta.mesh = cuadro
		_carga_muestra = suelta
	_carga_muestra.material_override = paso[0]
	_carga_muestra.layers = CAPA_DE_CARGA
	_carga_muestra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mundo.add_child(_carga_muestra)
	# A un metro, de cara a la cámara: dentro de plano seguro, y tapado por el telón.
	_carga_muestra.global_transform = camara.global_transform \
		* Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -1.0))
	if _telon != null:
		_telon.hechos = _carga_hechos
		_telon.queue_redraw()

## Con `--medir` (o `?medir=1`): lo que ha tardado el fotograma de cada material,
## que es lo que tarda en compilarse DE VERDAD en esta mesa, con sus luces y su
## entorno. El banco mide cada sombreador suelto; esto, lo que paga el que entra.
func _apuntar_paso() -> void:
	var ahora := Time.get_ticks_msec()
	if _medir and _carga_hechos > 0 and _carga_hechos <= _carga_pasos.size():
		var paso: Array = _carga_pasos[_carga_hechos - 1]
		_carga_apuntes.append("%6.2f s  %s" % [float(ahora - _carga_reloj) / 1000.0,
			_nombre_de_carga(paso[0], bool(paso[1]))])
	_carga_reloj = ahora

## UN TIRÓN JUGANDO (con `--medir` o `?medir=1`): un fotograma de más de 60 ms
## después de la carga. Casi siempre es un sombreador que se compila a la vista
## porque el telón no lo vio: una pieza que no existía al montar, o que ha
## cambiado de material. Dice cuándo, cuánto y qué materiales hay AHORA en el
## mundo que la carga no compiló. «Nada nuevo» apunta a otra cosa: una variante
## del mismo sombreador (otras luces) o el sistema, que estaba ocupado.
const TIRON := 0.06

func _apuntar_tiron(segundos: float) -> void:
	var nuevos := PackedStringArray()
	_buscar_sin_cargar(mundo, nuevos)
	var que := "ningún material nuevo"
	if not nuevos.is_empty():
		que = "sin cargar: " + ", ".join(nuevos)
	if _tirones:
		# Lo que se dibujó por primera vez en ese fotograma: lo apuntó el anterior.
		que += " · recién a la vista: " + (", ".join(_tir_recien.slice(0, 10))
			if not _tir_recien.is_empty() else "nada")
		if _tir_recien.size() > 10:
			que += " y %d más" % (_tir_recien.size() - 10)
	var texto := "tirón: %d ms a los %.1f s · %s" % [int(segundos * 1000.0), _tiempo, que]
	if _web:
		JavaScriptBridge.eval("(window.__tirones = window.__tirones || []).push('%s')" % texto, true)
	else:
		print(texto)

## Con `--tirones`: las piezas del mundo que se ven AHORA y no se habían visto
## nunca (una chispa que salta, una criatura que aparece, algo que su módulo
## enseña por primera vez). Unas partículas cuentan cuando emiten. Se llama en
## cada fotograma; con `apuntar` deja sus nombres en `_tir_recien`.
func _mirar_a_la_vista(nodo: Node, apuntar: bool) -> void:
	for hijo in nodo.get_children():
		_mirar_a_la_vista(hijo, apuntar)
	var gi := nodo as GeometryInstance3D
	if gi == null or gi.layers == 0 or not gi.is_visible_in_tree():
		return
	var de_cpu := gi as CPUParticles3D
	var de_gpu := gi as GPUParticles3D
	if (de_cpu != null and not de_cpu.emitting) or (de_gpu != null and not de_gpu.emitting):
		return
	var quien := gi.get_instance_id()
	if _tir_vistas.has(quien):
		return
	_tir_vistas[quien] = true
	if apuntar:
		var padre := gi.get_parent()
		_tir_recien.append("%s/%s (%s)" % [padre.name if padre != null else &"", gi.name,
			gi.get_class()])

## Los materiales del mundo que la carga no vio. Cada uno se apunta una vez.
func _buscar_sin_cargar(nodo: Node, nuevos: PackedStringArray) -> void:
	for hijo in nodo.get_children():
		_buscar_sin_cargar(hijo, nuevos)
	var gi := nodo as GeometryInstance3D
	if gi == null:
		return
	var con_instancias := gi is MultiMeshInstance3D or gi is CPUParticles3D \
		or gi is GPUParticles3D
	for de_la_pieza: Material in _materiales_de(gi):
		var m := de_la_pieza
		while m != null:
			var clave := _clave_de_carga(m, con_instancias)
			if not _carga_vistos.has(clave):
				_carga_vistos[clave] = true
				nuevos.append(_nombre_de_carga(m, con_instancias))
			m = m.next_pass

func _destapar() -> void:
	for nodo: Variant in _carga_capas:
		# Si alguien le ha puesto capas mientras tanto, manda lo que le ha puesto.
		if is_instance_valid(nodo) and (nodo as GeometryInstance3D).layers == 0:
			(nodo as GeometryInstance3D).layers = int(_carga_capas[nodo])
	_carga_capas.clear()
	_carga_pasos.clear()
	# `_carga_vistos` se queda: con él, `_apuntar_tiron` sabe qué material ha
	# aparecido después que el telón no compiló.
	_cargando = false
	# El fotograma más largo se cuenta desde aquí: los de la carga eran de compilar.
	# También el reloj: `_medida` se llama DESPUÉS de esto en el mismo fotograma,
	# y sin ponerlo a cero el último paso de la carga (medio segundo de compilar
	# el halo del óculo) salía apuntado como un tirón «a los 0,0 s» de juego.
	_med_pico = 0.0
	_med_antes = 0
	# Y lo que ya está a la vista al destapar no es «recién aparecido».
	if _tirones:
		_mirar_a_la_vista(mundo, false)
	# El vigilante de la calidad, a empezar de cero: lo que ha visto hasta aquí
	# eran fotogramas de compilar, no de dibujar.
	_cal_espera = 3.0
	_cal_t = 0.0
	_cal_n = 0
	_cal_sobrada = 0.0
	if _telon != null:
		_telon.abrir()
		_telon = null
		var segundos := float(Time.get_ticks_msec() - _carga_t0) / 1000.0
		var texto := "carga: %d materiales en %.1f s" % [_carga_hechos, segundos]
		if _web:
			JavaScriptBridge.eval("window.__carga = '%s'; window.__carga_pasos = %s" % [
				texto, JSON.stringify(_carga_apuntes)], true)
		else:
			print(texto)
			for apunte in _carga_apuntes:
				print("carga: ", apunte)
		_carga_apuntes.clear()
		# Y lo que tarde el primer fotograma ya destapado: si es largo, es que
		# algo se ha quedado sin compilar detrás del telón.
		_carga_destape = Time.get_ticks_msec()

## EL TELÓN de la carga: tapa la mesa mientras se compila y dice por dónde va.
## Se dibuja a mano y con la letra de reserva de Godot, que es la única que hay
## seguro en un navegador.
class Telon extends Control:
	const FONDO := Color(0.027, 0.031, 0.047)
	const HUESO := Color(0.93, 0.89, 0.80)
	const ORO_VIEJO := Color(0.83, 0.64, 0.30)
	var hechos := 0
	var total := 1
	var en_web := false
	var _abierto := 0.0

	## Se va en medio segundo y se quita solo.
	func abrir() -> void:
		set_process(true)

	func _ready() -> void:
		set_process(false)
		resized.connect(queue_redraw)

	func _process(delta: float) -> void:
		# Con un tope: el fotograma en que se destapa puede ser largo.
		_abierto += minf(delta, 0.05) * 2.0
		if _abierto >= 1.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		# Antes de tener tamaño no hay nada que pintar (y una letra de cuerpo
		# cero es un error por la salida).
		if size.y < 8.0:
			return
		var a := 1.0 - _abierto
		draw_rect(Rect2(Vector2.ZERO, size), Color(FONDO, a))
		var letra := ThemeDB.fallback_font
		var centro := size * 0.5
		var u := size.y / 540.0
		_centrado(letra, "C R I P T A", centro + Vector2(0.0, -34.0 * u), int(40.0 * u),
			Color(HUESO, a))
		var ancho := 220.0 * u
		var barra := Rect2(centro.x - ancho * 0.5, centro.y + 4.0 * u, ancho, 2.0 * u)
		draw_rect(barra, Color(HUESO, 0.18 * a))
		barra.size.x = ancho * clampf(float(hechos) / float(maxi(total, 1)), 0.0, 1.0)
		draw_rect(barra, Color(ORO_VIEJO, a))
		_centrado(letra, "PREPARANDO LA CRIPTA  ·  %d / %d" % [mini(hechos, total), total],
			centro + Vector2(0.0, 30.0 * u), int(11.0 * u), Color(HUESO, 0.75 * a))
		if en_web:
			_centrado(letra, "LA PRIMERA VEZ TARDA  ·  LAS SIGUIENTES, NO",
				centro + Vector2(0.0, 50.0 * u), int(9.0 * u), Color(HUESO, 0.45 * a))

	func _centrado(letra: Font, texto: String, donde: Vector2, cuerpo: int, color: Color) -> void:
		var ancho := letra.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1.0, cuerpo).x
		draw_string(letra, donde - Vector2(ancho * 0.5, 0.0), texto,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, cuerpo, color)

# --------------------------------------------------------------------- marcador

## Todo el marcador es un solo nodo: `--sin-marcador` lo esconde entero.
func _montar_marcador(capa: CanvasLayer) -> void:
	marcador = Marcador.new()
	# Con `--como-web`, también la letra de reserva: es lo que hay en un navegador.
	marcador.web = _web or _con_carga
	marcador.falta_clic = _falta_clic
	marcador.rotulo_campana = _rotulo_campana()
	marcador.visible = not _sin_marcador
	capa.add_child(marcador)

## Le cuenta al marcador cómo está todo. Son unos pocos números: se llama cada
## fotograma (la campana y el combo se gastan solos) y además en cada suceso.
func _refrescar_marcador() -> void:
	if marcador == null:
		return
	marcador.puntos = puntos
	marcador.bola = bola_numero
	marcador.multiplicador = multiplicador
	marcador.combo = clampf(_combo / DURACION_COMBO, 0.0, 1.0)
	marcador.piloto = piloto
	marcador.carga = mesa.carga
	marcador.armada = mesa.descarga_armada
	marcador.tocando = clampf(mesa.descarga_restante / maxf(mesa.p.descarga_tiempo, 0.01),
		0.0, 1.0)
	var lista: Array = []
	for clave: String in _orden_cuentas:
		lista.append([MesaCripta.ROTULOS.get(clave, clave), cuentas[clave]])
	marcador.cuentas = lista
	var camara_texto: String = VISTAS[vista]
	if camara_texto == "CRIATURA":
		var bichos := caza.principales()
		camara_texto += " · " + (bichos[criatura_camara % bichos.size()] as Criatura).nombre
	marcador.poner_vista(camara_texto, "%s%s" % [CALIDADES[calidad],
		" (AUTO)" if _cal_auto else ""])

## Las siete cuentas de siempre y, detrás de las lápidas, una por cada banco de
## dianas que la mesa haya añadido y tenga rótulo. La mesa lo dice en
## `info_bancos`; si no lo trae, no hay más bancos que contar.
func _preparar_cuentas() -> void:
	for clave: String in CUENTAS:
		cuentas[clave] = 0
		_orden_cuentas.append(clave)
	var donde := _orden_cuentas.find("targets") + 1
	for banco in mesa.bancos.size():
		var clave := _clave_banco(banco)
		if not cuentas.has(clave) and MesaCripta.ROTULOS.has(clave):
			cuentas[clave] = 0
			_orden_cuentas.insert(donde, clave)
			donde += 1

## La clave de `ROTULOS` de un banco de dianas: "targets" para las lápidas, y la
## que diga la mesa para los demás.
func _clave_banco(banco: int) -> String:
	var info: Array = mesa.info_bancos if "info_bancos" in mesa else []
	if banco >= 0 and banco < info.size():
		return str((info[banco] as Dictionary).get("clave", "targets"))
	return "targets"

func _estado_de(c: Criatura) -> String:
	var texto: String = caza.estado_de(c)
	texto = ESTADOS.get(texto, texto)
	if c.especie == "corredor":
		texto = MASCULINO.get(texto, texto)
	return texto

## Lo que la caza dice de cada criatura, traducido a lo que el marcador pinta:
## su nombre, qué le pasa, su color, cómo se la captura AHORA y lo cerca que está
## de caer (`Marcador.LLAMA` es que hay que ir a por ella ya).
func _refrescar_caza() -> void:
	var filas: Array[Dictionary] = []
	for c: Criatura in _del_marcador:
		var crudo: String = caza.estado_de(c)
		filas.append({"nombre": c.nombre, "estado": _estado_de(c), "color": _color_de(c),
			"consejo": _consejo_de(c, crudo), "nivel": _nivel_de(c, crudo)})
	marcador.poner_caza(caza.ola, filas)

func _nivel_de(c: Criatura, crudo: String) -> int:
	if not c.activa:
		return Marcador.FUERA
	if c.asegurada:
		return Marcador.ASEGURADA
	if crudo in ["ACORRALADA", "PANZA ARRIBA", "EN LA BOLA", "MITAD EN LA BOLA"]:
		return Marcador.LLAMA
	if crudo in ["HUYENDO", "ATURDIDA", "ESCONDIDA"] or crudo.begins_with("PARTIDA"):
		return Marcador.VIVA
	return Marcador.QUIETA

## El consejo de siempre, salvo cuando lo que toca hacer ya es otra cosa: son las
## mismas palabras que los avisos de esos sucesos.
func _consejo_de(c: Criatura, crudo: String) -> String:
	if crudo.contains("EN LA BOLA"):
		return "lléval%s a una pala" % _o(c).to_lower()
	if crudo == "ACORRALADA" or crudo == "PANZA ARRIBA":
		return "tócal%s con la bola" % _o(c).to_lower()
	if crudo == "ESCONDIDA":
		return "mete la bola en la %s" % MesaCripta.ROTULOS["gusano"].to_lower()
	if crudo.begins_with("PARTIDA"):
		return "recoge las dos ascuas"
	return CONSEJO.get(c.especie, "")

func _avisar(texto: String, col: Color) -> void:
	marcador.avisar(texto, col)

func _sumar(cuanto: int) -> void:
	var campana := DOBLE_CAMPANA if mesa.descarga_restante > 0.0 else 1
	puntos += cuanto * multiplicador * campana

func _rotulo_campana() -> String:
	return MesaCripta.ROTULOS.get("campana", "CAMPANA MAYOR")

# ----------------------------------------------------------------------- reglas

func _conectar_reglas() -> void:
	mesa.bola_drenada.connect(_al_drenar)
	mesa.bumper_golpeado.connect(func(_p: Vector2, _f: float) -> void:
		sonido.reproducir("bumper")
		cuentas["bumpers"] += 1
		_sumar(100)
		_refrescar_marcador())
	mesa.slingshot_golpeado.connect(func(_p: Vector2, _f: float) -> void:
		_sumar(30)
		_refrescar_marcador())
	mesa.target_abatido.connect(func(_p: Vector2, banco: int) -> void:
		sonido.reproducir("target")
		var clave := _clave_banco(banco)
		cuentas[clave if cuentas.has(clave) else "targets"] += 1
		_sumar(250)
		_refrescar_marcador())
	mesa.banco_completado.connect(func(_p: Vector2, banco: int) -> void:
		sonido.reproducir("banco")
		_sumar(2500)
		var clave := _clave_banco(banco)
		var molde: String = AVISO_BANCO.get(clave, "%s · BANCO COMPLETO")
		_avisar(molde % MesaCripta.ROTULOS.get(clave, clave.to_upper()), ORO)
		_refrescar_marcador())
	mesa.girador_girado.connect(func(_p: Vector2, _i: int, _f: float) -> void:
		_sumar(80)
		_refrescar_marcador())
	mesa.rampa_entrada.connect(func(_p: Vector2, _i: int) -> void:
		sonido.reproducir("rampa_entrada"))
	mesa.rampa_fallada.connect(func(_p: Vector2, _i: int, _r: float) -> void:
		sonido.reproducir("rampa_fallada")
		_avisar("NO LLEGA", TENUE))
	mesa.rampa_salida.connect(_al_completar)
	mesa.platillo_capturado.connect(func(_p: Vector2, _i: int) -> void:
		sonido.reproducir("platillo")
		cuentas["platillo"] += 1
		_sumar(5000)
		_avisar("%s +%d" % [MesaCripta.ROTULOS["platillo"], 5000 * multiplicador], ORO)
		_refrescar_marcador())
	mesa.bola_cayo.connect(func(_p: Vector2, _d: int, _h: int) -> void:
		sonido.reproducir("caida"))
	# La campana mayor. Se avisa al ARMARSE, no en cada tirón de cuerda; que ha
	# tocado lo dice el aviso del recorrido que la hizo tocar (`_al_completar`),
	# porque los dos llegan en el mismo instante y solo cabe un aviso.
	mesa.carga_cambiada.connect(func(_fraccion: float, armada: bool) -> void:
		if armada and not _campana_armada:
			sonido.reproducir("atrasar")
			_avisar("%s ARMADA · COMPLETA UN RECORRIDO" % _rotulo_campana(), ORO)
		_campana_armada = armada
		_refrescar_marcador())
	mesa.descarga_empezada.connect(func(_p: Vector2, _s: float) -> void:
		sonido.reproducir("rampa_fuerte")
		_campana_recien = true
		_refrescar_marcador())
	mesa.descarga_terminada.connect(_refrescar_marcador)

## Lo que la caza le cuenta al marcador y al altavoz. Los sonidos son los que ya
## tiene el juego: no hay ninguno nuevo, y eso está por hacer.
func _conectar_caza() -> void:
	caza.criatura_golpeada.connect(func(c: Criatura, _p: Vector2, _f: float, _n: Vector2) -> void:
		sonido.reproducir("target")
		_sumar(300)
		if c.especie == "corredor" and c.miedo >= 1.0:
			_avisar("%s NO PUEDE MÁS" % c.nombre, _color_de(c))
		_refrescar_marcador())
	caza.criatura_blindada.connect(func(c: Criatura, _p: Vector2, _f: float) -> void:
		sonido.reproducir("bumper")
		_avisar("%s · DE FRENTE NO · DALE POR DETRÁS" % c.nombre, _color_de(c)))
	caza.criatura_volcada.connect(func(c: Criatura, _p: Vector2) -> void:
		sonido.reproducir("banco")
		_sumar(500)
		_avisar("%s VOLCAD%s · TÓCAL%s" % [c.nombre, _o(c), _o(c)], _color_de(c))
		_refrescar_marcador())
	caza.criatura_partida.connect(func(c: Criatura, _p: Vector2) -> void:
		sonido.reproducir("banco")
		_sumar(400)
		_avisar("%s SE PARTE · RECOGE LAS DOS ASCUAS" % c.nombre, _color_de(c))
		_refrescar_marcador())
	caza.criatura_reunida.connect(func(c: Criatura, _p: Vector2) -> void:
		_avisar("%s SE HA VUELTO A JUNTAR" % c.nombre, TENUE))
	caza.criatura_acorralada.connect(func(c: Criatura) -> void:
		sonido.reproducir("reloj")
		_avisar("%s ACORRALAD%s · TÓCAL%s" % [c.nombre, _o(c), _o(c)], ALERTA))
	caza.criatura_rehecha.connect(func(c: Criatura) -> void:
		_avisar("%s SE REHACE" % c.nombre, TENUE))
	caza.criatura_recogida.connect(func(c: Criatura, _p: Vector2) -> void:
		sonido.reproducir("atrapar")
		_sumar(1000)
		_avisar("%s EN LA BOLA · LLÉVAL%s A UNA PALA" % [c.nombre, _o(c)], _color_de(c))
		_refrescar_marcador())
	caza.criatura_asegurada.connect(func(c: Criatura, _p: Vector2) -> void:
		sonido.reproducir("combo")
		if c.principal:
			_sumar(5000)
			_avisar("%s ASEGURAD%s +%d" % [c.nombre, _o(c), 5000 * multiplicador], _color_de(c))
		else:
			_sumar(1500)
			_avisar("%s A SALVO" % c.nombre, _color_de(c))
		_refrescar_marcador())
	caza.criatura_escapada.connect(func(c: Criatura, _p: Vector2) -> void:
		sonido.reproducir("caida")
		_avisar("%s SE ESCAPÓ" % c.nombre, TENUE))
	caza.criatura_escondida.connect(func(c: Criatura, _p: Vector2) -> void:
		sonido.reproducir("platillo")
		_avisar("%s SE ESCONDE · METE LA BOLA EN LA %s" % [c.nombre,
			MesaCripta.ROTULOS["gusano"]], _color_de(c)))
	caza.criatura_expulsada.connect(func(c: Criatura, _p: Vector2) -> void:
		_sumar(800)
		_avisar("%s · FUERA DE LA %s" % [c.nombre, MesaCripta.ROTULOS["gusano"]], _color_de(c))
		_refrescar_marcador())
	caza.caza_completa.connect(func(ola: int) -> void:
		sonido.reproducir("salvaguarda")
		_sumar(20000)
		_avisar("CAZA COMPLETA · OLA %d" % ola, ORO)
		_refrescar_marcador())

func _color_de(c: Criatura) -> Color:
	return COLOR_ESPECIE.get(c.especie, MARFIL)

## La última letra de lo que se dice de una criatura: el espectro es «él»; la
## brasa, el ascua y la calavera, «ella».
func _o(c: Criatura) -> String:
	return "O" if c.especie == "corredor" else "A"

func _al_completar(_punto: Vector2, indice: int) -> void:
	var nombre := mesa.rampas[indice].nombre
	var toca := _campana_recien
	_campana_recien = false
	var campanada := "TOCA LA %s · TODO VALE DOBLE" % _rotulo_campana()
	if not TIROS.has(nombre):
		# El campanario y la escalera no puntúan, pero también la hacen tocar.
		if toca:
			_avisar(campanada, ORO)
		return
	sonido.reproducir("rampa_salida")
	# EL OCHO: encadenar recorridos antes de que se apague el combo sube el
	# multiplicador. Es lo que hace que la mesa tenga un camino y no solo piezas.
	if _combo > 0.0:
		multiplicador = mini(multiplicador + 1, 5)
	_combo = DURACION_COMBO
	cuentas[nombre] += 1
	_sumar(int(TIROS[nombre]))
	var texto: String = MesaCripta.ROTULOS[nombre]
	if multiplicador > 1:
		texto += " ×%d" % multiplicador
	if toca:
		texto += " · " + campanada
	_avisar(texto, ORO)
	_refrescar_marcador()

func _al_drenar() -> void:
	sonido.reproducir("drenaje")
	_pide_bola = true
	multiplicador = 1
	_combo = 0.0
	bola_numero += 1
	_avisar("BOLA PERDIDA", ALERTA)
	_refrescar_marcador()

# ---------------------------------------------------------------------- pantalla

func _ajustar_pantalla() -> void:
	var lienzo := get_viewport().get_visible_rect().size
	var escala := maxf(float(get_window().size.x) / lienzo.x, 1.0)
	pantalla.position = Vector2.ZERO
	pantalla.size = lienzo
	var ventana: Vector2 = lienzo * escala
	var cabe := sqrt(float(_cal.get("mp", 100.0)) * 1.0e6 / maxf(ventana.x * ventana.y, 1.0))
	var real: Vector2 = ventana * minf(cabe, 1.0) * float(_cal.get("escala", 1.0))
	vp.size = Vector2i(real).maxi(16)
	vp_reflejo.size = Vector2i(real * maxf(float(_cal.get("reflejo", 0.5)), 0.1)).maxi(16)

## El primer clic o la primera tecla en el navegador: hasta entonces la mesa se
## ha estado jugando sola, y a partir de aquí es del que ha llegado. La tecla se
## da por gastada, para que una T no vuelva a encender el piloto que apaga.
func _input(evento: InputEvent) -> void:
	if not _falta_clic:
		return
	# Con un dedo no se puede jugar a esto: no hay palas que tocar. En un móvil
	# la mesa sigue jugando sola y dice por qué. El clic que el motor inventa a
	# partir del toque no cuenta: viene marcado como de mentira.
	var toque := evento as InputEventScreenTouch
	if toque != null:
		if toque.pressed:
			_avisar("SE JUEGA CON TECLADO · AQUÍ SE JUEGA SOLA", TENUE)
		return
	var boton := evento as InputEventMouseButton
	var tecla := evento as InputEventKey
	var clic := boton != null and boton.pressed \
		and boton.device != InputEvent.DEVICE_ID_EMULATION
	if clic or (tecla != null and tecla.pressed):
		_falta_clic = false
		piloto = false
		marcador.falta_clic = false
		_avisar("TÚ JUEGAS", ORO)
		_refrescar_marcador()
		if tecla != null:
			get_viewport().set_input_as_handled()

func _unhandled_key_input(evento: InputEvent) -> void:
	var tecla := evento as InputEventKey
	if tecla == null or not tecla.pressed or tecla.echo:
		return
	# En el navegador F12 es de las herramientas del navegador, no nuestra.
	if _web and tecla.physical_keycode == KEY_F12:
		return
	match tecla.physical_keycode:
		KEY_C:
			vista = (vista + 1) % VISTAS.size()
			# Otra cámara es otra carga: el vigilante vuelve a probar pronto.
			_cal_reintento = 6.0
		KEY_X:
			criatura_camara = (criatura_camara + 1) % caza.principales().size()
		KEY_1:
			_alternar("saltarin")
		KEY_2:
			_alternar("escarabajo")
		KEY_3:
			_alternar("corredor")
		KEY_T:
			piloto = not piloto
		KEY_M:
			mesa.soltar_bola_extra()
		KEY_R:
			_pide_bola = true
		KEY_H:
			marcador.alternar_ayuda()
		KEY_G:
			# A mano manda el que juega: el vigilante se retira.
			_cal_auto = false
			_poner_calidad((calidad + 1) % CALIDADES.size())
		KEY_F12:
			_capturar("user://cripta_%d.png" % Time.get_ticks_msec())
		_:
			return
	_refrescar_marcador()

func _alternar(especie: String) -> void:
	for c: Criatura in caza.principales():
		if c.especie == especie:
			caza.activar(especie, not c.activa)
			_avisar("%s %s" % [c.nombre, "ENTRA" if c.activa else "FUERA DE JUEGO"],
				_color_de(c))
			return

# ----------------------------------------------------------------------- calidad

## En web se le pueden pasar mandos por la dirección, para medir o para forzar:
##     .../?calidad=baja        ?escala=0.7&msaa=2        ?auto=0
func _leer_direccion() -> void:
	_cal_auto = true
	calidad = 1
	# Qué gráfica usa de verdad el navegador. El motor no lo sabe —WebGL se lo
	# esconde—, pero la página sí puede preguntarlo.
	_grafica = str(JavaScriptBridge.eval("(function(){try{var c=document.createElement('canvas');var g=c.getContext('webgl2')||c.getContext('webgl');if(!g)return '';var e=g.getExtension('WEBGL_debug_renderer_info');return String(e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER));}catch(x){return '';}})()", true))
	var nombre := _grafica.to_lower()
	for floja: String in GRAFICAS_FLOJAS:
		if nombre.contains(floja):
			_cal_tope = 1
			break
	var consulta := str(JavaScriptBridge.eval("window.location.search", true))
	for trozo in consulta.trim_prefix("?").split("&", false):
		var par := trozo.split("=")
		if par.size() != 2:
			continue
		if par[0] == "calidad":
			var cual := CALIDADES.find(par[1].to_upper())
			if cual >= 0:
				calidad = cual
				_cal_auto = false
		elif par[0] == "auto":
			_cal_auto = par[1] != "0"
		elif par[0] == "medir":
			_medir = par[1] != "0"
		elif par[0] == "tirones":
			_tirones = par[1] != "0"
		elif par[0] == "carga":
			# `?carga=0`: sin telón, todo de golpe, para medir cuánto se gana.
			_con_carga = par[1] != "0"
		elif par[0] == "ssao":
			_ssao = par[1] != "0"
		elif par[0] == "relleno":
			_sin_relleno = par[1] == "0"
		elif AJUSTES_CALIDAD["ALTA"].has(par[0]) and par[1].is_valid_float():
			_cal_forzado[par[0]] = float(par[1])

## Lo que la calidad le toca al mundo son cuatro mandos, y los cuatro están en
## el contrato de los módulos «entorno» y «suelo»: el interruptor del reflejo,
## el brillo, la sombra de la luna y el fondo.
func _poner_calidad(cual: int) -> void:
	calidad = clampi(cual, 0, CALIDADES.size() - 1)
	_cal = (AJUSTES_CALIDAD[CALIDADES[calidad]] as Dictionary).duplicate()
	_cal.merge(_cal_forzado, true)
	match int(_cal["msaa"]):
		0: vp.msaa_3d = Viewport.MSAA_DISABLED
		2: vp.msaa_3d = Viewport.MSAA_2X
		_: vp.msaa_3d = Viewport.MSAA_4X
	var con_reflejo := float(_cal["reflejo"]) > 0.0
	if con_reflejo:
		vp_reflejo.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	else:
		vp_reflejo.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if mundo.mat_suelo != null:
		mundo.mat_suelo.set_shader_parameter("fuerza_reflejo", 1.0 if con_reflejo else 0.0)
	mundo.entorno.glow_enabled = int(_cal["brillo"]) != 0
	var fondo: Environment.BGMode = _fondo_propio
	if int(_cal["cielo"]) == 0:
		fondo = Environment.BG_COLOR
	mundo.entorno.background_mode = fondo
	mundo.entorno_reflejo.background_mode = fondo
	# LO QUE PESA LO APAGA QUIEN LO PUSO. La escena solo sabía tocar la sombra de
	# la luna, y en BAJA seguían dibujándose la sombra de un fuego, la bruma y el
	# desenfoque: el núcleo reparte la calidad y cada módulo quita lo suyo
	# (`MundoCripta.poner_calidad`). Va DESPUÉS de lo de arriba, para que un
	# módulo pueda corregirlo. Si «entorno» no supiera de calidades, queda el
	# interruptor de siempre para la sombra de la luna.
	mundo.poner_calidad(calidad)
	var del_entorno: Object = mundo.modulo("entorno")
	if mundo.luz_luna != null and (del_entorno == null or not del_entorno.has_method("calidad")):
		mundo.luz_luna.shadow_enabled = int(_cal["sombras"]) != 0
	_cal_espera = 1.5
	_cal_t = 0.0
	_cal_n = 0
	_cal_sobrada = 0.0
	_ajustar_pantalla()
	_refrescar_marcador()

## EL VIGILANTE: si la página no llega a 47 fotogramas por segundo durante dos
## segundos, baja un nivel; si lleva un rato yendo sobrada, prueba a subir uno.
##
## BAJAR NO ES PARA SIEMPRE. Vuelve a probar, y cada subida que falla hace
## esperar el doble a la siguiente (de 6 s hasta 2 min), así que un equipo que de
## verdad no puede no se pasa la partida a tirones.
##
## Los fotogramas de más de un cuarto de segundo no cuentan: eso es una pestaña
## en segundo plano o un tirón de carga, no un equipo lento. Y los umbrales
## dejan fuera a las pantallas de 48 y 50 Hz, que si no bajarían por ir a tope.
func _vigilar_calidad(delta: float) -> void:
	if not _cal_auto or delta <= 0.0 or delta > 0.25:
		return
	_cal_desde_subida += delta
	if _cal_espera > 0.0:
		_cal_espera -= delta
		return
	_cal_t += delta
	_cal_n += 1
	if _cal_t < 2.0:
		return
	var fps := float(_cal_n) / _cal_t
	var visto := _cal_t
	_cal_t = 0.0
	_cal_n = 0
	if fps < 47.0:
		_cal_sobrada = 0.0
		if calidad < CALIDADES.size() - 1:
			if _cal_desde_subida < 12.0:
				_cal_reintento = minf(_cal_reintento * 2.0, 120.0)
			_poner_calidad(calidad + 1)
	elif fps > 57.0 and calidad > _cal_tope:
		_cal_sobrada += visto
		if _cal_sobrada >= _cal_reintento:
			_cal_desde_subida = 0.0
			_poner_calidad(calidad - 1)
	else:
		_cal_sobrada = 0.0

# ------------------------------------------------------------------------ física

func _physics_process(delta: float) -> void:
	# Detrás del telón de la carga no se juega: ni la física ni el reloj corren.
	if _cargando:
		return
	var t0 := Time.get_ticks_usec()
	_tiempo += delta
	if _pide_bola:
		_pide_bola = false
		mesa.nueva_bola()
	if _combo > 0.0:
		_combo -= delta
		if _combo <= 0.0 and multiplicador > 1:
			multiplicador = 1
			_refrescar_marcador()
	while not _guion.is_empty() and _tiempo >= float(_guion[0][0]):
		var paso: Array = _guion.pop_front()
		_forzar(int(paso[1]), str(paso[2]))

	var izq := Input.is_physical_key_pressed(KEY_A) \
		or Input.is_physical_key_pressed(KEY_LEFT)
	var der := Input.is_physical_key_pressed(KEY_D) \
		or Input.is_physical_key_pressed(KEY_RIGHT)
	if not _web:
		# En una página, Ctrl con otra tecla es un atajo que no se puede parar
		# (Ctrl+W cierra la pestaña, Ctrl+T abre otra), y Mayús cinco veces
		# seguidas saca el diálogo de Teclas especiales de Windows.
		izq = izq or Input.is_physical_key_pressed(KEY_SHIFT)
		der = der or Input.is_physical_key_pressed(KEY_CTRL)
	var lanzar := Input.is_physical_key_pressed(KEY_SPACE)
	if piloto:
		var orden := _pilotar(delta)
		izq = izq or orden[0]
		der = der or orden[1]
		lanzar = lanzar or orden[2]

	# Cada botón mueve TODAS las palas de su lado, como en una máquina con pala
	# superior: la del coro va con la izquierda.
	for i in mesa.flippers.size():
		mesa.flippers[i].pulsado = izq if mesa.lado_pala[i] < 0 else der
	if (izq and not _izq_antes) or (der and not _der_antes):
		sonido.reproducir("flipper")
	_izq_antes = izq
	_der_antes = der

	if lanzar:
		mesa.cargar_lanzador(delta)
	elif mesa.cargando:
		mesa.soltar_lanzador()

	# La caza va dentro: la mesa la mueve antes de mover las bolas.
	mesa.avanzar(delta)
	_med_fisica += Time.get_ticks_usec() - t0

## "5.2:0:golpe,8:0:armar" → [[5.2, 0, "golpe"], [8.0, 0, "armar"]], por orden de
## segundo. Lo que venga mal escrito se salta.
func _leer_guion(texto: String) -> Array:
	var pasos: Array = []
	for trozo in texto.split(",", false):
		var partes := trozo.split(":")
		if partes.size() == 3 and partes[0].is_valid_float():
			pasos.append([float(partes[0]), int(partes[1]), partes[2]])
	pasos.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	return pasos

## FUERZA UN SUCESO A MANO, para poder MIRARLO en una captura sin esperar a que
## el figurante acierte. No es del juego: es de mirar. «quien» es el índice de la
## criatura (0 ESPECTRO, 1 BRASA, 2 CALAVERA) para lo de la caza, y el de la
## pieza para lo demás.
##
##   golpe · rendir · recoger   la caza (`Caza.forzar`), a la criatura «quien»
##   esconder   el espectro se mete en la catacumba por la boca «quien» (0 o 1)
##   tapar      se tapa la boca «quien» de la catacumba
##   armar      la campana mayor queda ARMADA
##   tocar      la campana mayor TOCA (4 s)
##   banco      cae entero el banco «quien» (0 lápidas, 1 escudos)
##   diana      cae la primera diana en pie del banco «quien»
##   platillo   la bola se mete en el sarcófago «quien»
##   brasero    un golpe en el brasero «quien»      torno   gira el torno «quien»
##   poste      un golpe en el poste «quien»        bola    una bola más
##   ayuda      abre o cierra el panel de ayuda     camara  la vista siguiente
##   aviso      el aviso más largo que existe       cartel  el cartel del primer
##                                                          clic de la web
##   llena      la campana llena y sin armar, como queda tras perder una bola armada
func _forzar(quien: int, que: String) -> void:
	match que:
		"golpe", "rendir", "recoger":
			if quien >= 0 and quien < caza.criaturas.size():
				caza.forzar(mesa, caza.criaturas[quien], que)
		"esconder":
			for c: Criatura in caza.criaturas:
				if c.especie == "corredor" and c.activa and c.golpeable():
					caza._esconder(c, clampi(quien, 0, 1))
					break
		"tapar":
			caza._tapar(clampi(quien, 0, 1))
		"armar":
			if mesa.descarga_restante <= 0.0:
				mesa.carga = 1.0
				mesa.descarga_armada = true
				mesa.carga_cambiada.emit(1.0, true)
		"tocar":
			mesa.descarga_armada = true
			mesa.gastar_descarga(Vector2(160.0, 742.0))
		"banco", "diana":
			if quien >= 0 and quien < mesa.bancos.size():
				for c: Colisionador in mesa.bancos[quien]:
					if c.activo:
						mesa._abatir(c)
						if que == "diana":
							break
		"platillo":
			var b := mesa.bola_en_peligro()
			if quien >= 0 and quien < mesa.platillos.size() and b.viva and b.libre():
				var pl := mesa.platillos[quien]
				b.capa = Mesa.CAPA_ALTA
				b.en_carril = false
				b.platillo = quien
				b.platillo_espera = pl.tiempo_captura
				b.pos = pl.centro
				b.vel = Vector2.ZERO
				mesa.platillo_capturado.emit(pl.centro, quien)
		"brasero":
			if quien >= 0 and quien < mesa.bumpers.size():
				mesa.bumper_golpeado.emit(mesa.bumpers[quien], 700.0)
		"poste":
			if quien >= 0 and quien < mesa.postes.size():
				mesa.poste_golpeado.emit(mesa.postes[quien], 700.0)
		"torno":
			if quien >= 0 and quien < mesa.giradores.size():
				mesa.girador_girado.emit(mesa.giradores[quien], quien, 900.0)
		"bola":
			mesa.soltar_bola_extra()
		# Estos cuatro no tocan la mesa: son para fotografiar el marcador (y
		# «llena», más abajo, deja la campana como tras perder una bola armada).
		"ayuda":
			marcador.alternar_ayuda()
		"camara":
			vista = (vista + 1) % VISTAS.size()
		"aviso":
			# El aviso más largo que puede salir: un recorrido con el multiplicador
			# a tope que además hace tocar la campana.
			_avisar("%s ×5 · TOCA LA %s · TODO VALE DOBLE" % [MesaCripta.ROTULOS["cometa"],
				_rotulo_campana()], ORO)
		"cartel":
			marcador.falta_clic = not marcador.falta_clic
		"llena":
			# La campana como queda al perder una bola con ella armada: la mesa la
			# desarma (`cortar_descarga`) pero le deja la carga entera.
			if mesa.descarga_restante <= 0.0:
				mesa.carga = 1.0
				mesa.descarga_armada = false
				_campana_armada = false
				mesa.carga_cambiada.emit(1.0, false)
		_:
			print("GUION: no sé forzar «%s»" % que)

## Un jugador de mentira, lo justo para que la mesa se mueva sola en una captura
## o mientras alguien mira. No sabe apuntar: es un figurante.
func _pilotar(delta: float) -> Array:
	_pulso_i = maxf(_pulso_i - delta, 0.0)
	_pulso_d = maxf(_pulso_d - delta, 0.0)
	_descanso_i = maxf(_descanso_i - delta, 0.0)
	_descanso_d = maxf(_descanso_d - delta, 0.0)
	var en_carril := false
	for b in mesa.bolas:
		if not b.viva:
			continue
		if b.en_carril and b.libre():
			en_carril = true
		if not b.libre() or b.vel.y < -20.0:
			continue
		for i in mesa.flippers.size():
			var f := mesa.flippers[i]
			if not f.en_capa(b.capa):
				continue
			var d := b.pos - f.eje
			var lado := mesa.lado_pala[i]
			# Un palazo y un descanso. Si volviera a pulsar mientras la bola
			# siga cerca, la dejaría acunada en la pala para siempre.
			var ocupada := (_pulso_i > 0.0 or _descanso_i > 0.0) if lado < 0 \
				else (_pulso_d > 0.0 or _descanso_d > 0.0)
			if ocupada:
				continue
			if absf(d.y + 12.0) < 18.0 and d.x * float(-lado) > f.longitud * 0.25 \
					and absf(d.x) < f.longitud + 8.0 and _rng.randf() < 0.5:
				var pulso := _rng.randf_range(0.08, 0.2)
				if lado < 0:
					_pulso_i = pulso
					_descanso_i = pulso + 0.35
				else:
					_pulso_d = pulso
					_descanso_d = pulso + 0.35
	var lanzar := false
	if en_carril:
		_carga_piloto += delta
		lanzar = _carga_piloto < 1.0
		if _carga_piloto > 1.2:
			_carga_piloto = 0.0
	else:
		_carga_piloto = 0.0
	return [_pulso_i > 0.0, _pulso_d > 0.0, lanzar]

# ------------------------------------------------------------------------ cámara

func _process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	if _carga_destape > 0:
		var destape := "destape: %.2f s el primer fotograma a la vista" % [
			float(Time.get_ticks_msec() - _carga_destape) / 1000.0]
		_carga_destape = 0
		if _web:
			JavaScriptBridge.eval("window.__destape = '%s'" % destape, true)
		elif _medir:
			print(destape)
	# Cargando, el mundo avanza a pasitos FIJOS de un sesentavo: cada fotograma
	# dura lo que tarda en compilar un sombreador, y con el tiempo de verdad daría
	# saltos de segundos. Parado del todo no puede estar: hay módulos que acaban
	# de montarse en sus primeros cuadros (el suelo hornea sus atlas en el tercero
	# y los copia en el sexto; el cielo del óculo espera a «arquitectura»), y eso
	# tiene que pasar detrás del telón. Lo que creen en esos cuadros también se
	# esconde y se compila: por eso se vuelve a recoger.
	if _cargando:
		mundo.actualizar(1.0 / 60.0)
		if _carga_cuadros < 8:
			_carga_cuadros += 1
			_recoger_para_cargar(mundo)
			_telon.total = _carga_pasos.size()
	else:
		mundo.actualizar(delta)
	_refrescar_caza()
	_refrescar_marcador()
	if not _cargando:
		_vigilar_calidad(delta)

	var b := mesa.bola_en_peligro()
	var p3 := mundo.posicion_bola(b)
	if b.viva:
		var t := clampf((p3.z - 6.4) / (12.3 - 6.4), 0.0, 1.0)
		# Hacia arriba sigue más deprisa que hacia abajo: una bola que sube
		# rápido se le escaparía por arriba a una cámara que se ha acercado.
		var rapidez := 5.0 if t < _cam_t else 2.5
		_cam_t = lerpf(_cam_t, t, 1.0 - exp(-rapidez * delta))
		_cam_x = lerpf(_cam_x, p3.x - 2.0, 1.0 - exp(-3.0 * delta))
		# Y si aun así se escapara, la cámara se echa atrás lo que haga falta en
		# ese mismo fotograma: la bola en peligro no sale nunca de plano.
		while _cam_t > 0.0 and not _bola_en_plano(p3, _cam_t):
			_cam_t = maxf(_cam_t - 0.05, 0.0)

	var pos: Vector3
	var mira: Vector3
	var fov := 46.0
	match VISTAS[vista]:
		"RASANTE":
			# Baja y cerca de las palas, con la mesa perdiéndose al fondo. Estaba
			# en z = 15 con 56° y gastaba un 20 % de la pantalla en la zona muerta de
			# debajo de las palas, que además era lo más claro del primer plano
			# (lo midió el crítico de jugabilidad). Más cerca y más cerrada, las
			# puntas de las palas caen hacia el 80 % del alto. Y con la bola arriba
			# la mira sube solo 0,6: subiendo 1,2 desde aquí las palas se cortaban.
			pos = Vector3(2.0 + _cam_x * 0.25, 2.3, 14.3)
			mira = Vector3(2.0 + _cam_x * 0.5, 0.2, 10.4 - (1.0 - _cam_t) * 0.6)
			fov = 52.0
		"CENITAL":
			# A plomo, con la mesa llenando el alto. A 13,5 la mesa ocupaba un
			# cuarto del ancho y la bola medía 14 px; a 10,6 se corta el pie.
			pos = Vector3(2.0, 11.0, 9.5)
			mira = Vector3(2.0, 0.0, 9.3)
			fov = 40.0
		"CORO":
			# La tribuna alta, con su pala y el sarcófago, desde el lado.
			pos = Vector3(4.6, 2.6, 9.2)
			mira = Vector3(2.7, 0.2, 7.2)
			fov = 50.0
		"PLAZA":
			# La plaza de las criaturas, de cerca. Las palas quedan fuera: es
			# para mirar, no para jugar.
			pos = Vector3(2.14, 2.9, 12.75)
			mira = Vector3(2.14, 0.0, 9.95)
			fov = 48.0
		"CRIATURA":
			# Pegada a una criatura, para verla de cerca.
			var lista := caza.principales()
			var c: Criatura = lista[criatura_camara % lista.size()]
			if c.partida:
				for g: Criatura in caza.mitades(c):
					if g.a_la_vista():
						c = g
						break
			if c.activa and c.a_la_vista() and c.estado != Criatura.Estado.EN_BOLA:
				_cam_bicho = _cam_bicho.lerp(mundo.posicion_criatura(c.indice),
					1.0 - exp(-5.0 * delta))
			pos = Vector3(_cam_bicho.x + 0.25, 0.72, _cam_bicho.z + 1.15)
			mira = Vector3(_cam_bicho.x, 0.10, _cam_bicho.z)
			fov = 44.0
		_:
			var toma := _seguimiento(_cam_t)
			pos = toma[0]
			mira = toma[1]
			fov = SEGUIMIENTO_FOV
	# LA CÁMARA LIBRE (`--ojo=x,y,z --mira=x,y,z [--fov=N]`, en unidades 3D): manda
	# sobre la vista que haya. Es para acercarse a una pieza al capturar; jugando
	# no existe. Va antes del temblor y del reflejo, para que los dos la sigan.
	var libre := _camara_libre
	if not _tomas.is_empty():
		var toma: Array = _tomas[_capturas_hechas % _tomas.size()]
		pos = toma[0]
		mira = toma[1]
		fov = toma[2]
		libre = true
	elif _camara_libre:
		pos = _ojo_libre
		mira = _mira_libre
		fov = _fov_libre
	if not libre:
		fov = _fov_ventana(fov)
	var s := mundo.sacudida
	if s > 0.0:
		var temblor := Vector3(_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0), 0.0) * s * 0.022
		pos += temblor
		mira += temblor * 0.5
	camara.fov = fov
	camara.look_at_from_position(pos, mira, Vector3.UP)
	# Dónde cae la bola en el lienzo del marcador: el aviso se aparta si la tapa.
	if marcador != null:
		marcador.bola_pantalla = Vector2(-1.0, -1.0)
		if b.viva and not camara.is_position_behind(p3):
			marcador.bola_pantalla = camara.unproject_position(p3) \
				/ Vector2(vp.size) * marcador.size
	# La cámara del reflejo es la misma, simétrica respecto al suelo. De cerca
	# dibuja también lo menudo de las criaturas; en las dos cámaras de juego,
	# que las ven pequeñas y desde arriba, se lo ahorra.
	var de_cerca: bool = libre \
		or (VISTAS[vista] != "SEGUIMIENTO" and VISTAS[vista] != "CENITAL")
	camara_reflejo.cull_mask = 1 | (MundoCripta.CAPA_DETALLE if de_cerca else 0)
	camara_reflejo.fov = fov
	camara_reflejo.look_at_from_position(
		Vector3(pos.x, -pos.y, pos.z), Vector3(mira.x, -mira.y, mira.z), Vector3.UP)
	if _cargando:
		_avanzar_carga()

	if _dir_capturas != "" and _tiempo > 2.0 + float(_capturas_hechas) * _cada \
			and _capturas_hechas < _cuantas:
		var nombre := "v%d_%02d" % [vista, _capturas_hechas]
		if not _tomas.is_empty():
			nombre = "t%02d_%02d" % [_capturas_hechas % _tomas.size(),
				_capturas_hechas / _tomas.size()]
		_capturar("%s/%s.png" % [_dir_capturas, nombre])
		_capturas_hechas += 1
	if _medir:
		_medida(delta, Time.get_ticks_usec() - t0)

## LA CÁMARA DE JUEGO, de `t` = 0 (la bola arriba) a 1 (la bola en las palas).
## Arriba enseña la mesa ENTERA, del ábside a las palas; abajo baja y se acerca,
## y lo alto se puede quedar fuera. Las dos tienen el mismo campo de visión, así
## que el paso de una a otra es un travelling y no un zoom.
## Medido con las dos palas (ejes en z = 12, puntas hasta 12,42) y el ábside
## (z = 5,6), en 16:9: el ábside cae entre el 13 y el 14 % del alto, debajo de
## la franja del aviso (que acaba al 6,7 % en una línea y al 9,6 % en dos), y las
## palas entre el 69 y el 84 %; abajo la mesa ocupa el 54 % del ancho. La mira de
## arriba estaba en z = 10,25 y el ábside caía al 12 %: el aviso en dos líneas
## se montaba en los arcos de los raíles. Probado más cerca (57 %): el ábside se
## iba por arriba y el aviso caía encima de los raíles del coro. Y más ancha
## pisaría los bloques de abajo del marcador.
func _seguimiento(t: float) -> Array:
	var pos := SEGUIMIENTO_OJO[0].lerp(SEGUIMIENTO_OJO[1], t)
	var mira := SEGUIMIENTO_MIRA[0].lerp(SEGUIMIENTO_MIRA[1], t)
	# Un poco hacia el lado de la bola: lo justo para que no se pierdan las
	# palas cuando la bola está en un carril.
	pos.x += _cam_x * 0.10
	mira.x += _cam_x * 0.22
	return [pos, mira]

## Si la bola cae dentro del plano de la cámara de seguimiento con su margen (el
## 9 % de arriba es del aviso). Se calcula a mano y no con la cámara, porque se
## pregunta ANTES de moverla.
func _bola_en_plano(p: Vector3, t: float) -> bool:
	var toma := _seguimiento(t)
	var pos: Vector3 = toma[0]
	var delante: Vector3 = (toma[1] - pos).normalized()
	var derecha := delante.cross(Vector3.UP).normalized()
	var arriba := derecha.cross(delante)
	var d := p - pos
	var hondo := d.dot(delante)
	if hondo <= 0.1:
		return false
	var mitad := tan(deg_to_rad(_fov_ventana(SEGUIMIENTO_FOV)) * 0.5)
	return d.dot(arriba) / hondo / mitad < 0.82

## La cámara guarda el campo de visión VERTICAL. En una ventana más estrecha que
## 16:9 eso recortaría la mesa por los lados (y las palas con ella): ahí se abre,
## pero NO hasta ver el mismo ancho que en 16:9. Abriéndolo entero, a 4:3 la mesa
## no crecía nada y quedaban dos bandas de suelo vacío arriba y abajo (del 21 %
## al 87 % del alto); con la raíz cuadrada de la proporción se ve un 13 % menos
## de ancho, la mesa crece eso, y lo de arriba y lo de abajo siguen cabiendo
## porque el alto que se ve sigue siendo mayor que en 16:9. En una ventana más
## ancha sobra por los lados, y eso es sitio para el marcador.
func _fov_ventana(fov: float) -> float:
	var aspecto := float(vp.size.x) / maxf(float(vp.size.y), 1.0)
	if aspecto >= 16.0 / 9.0:
		return fov
	var mitad := tan(deg_to_rad(fov) * 0.5) * sqrt((16.0 / 9.0) / aspecto)
	return rad_to_deg(2.0 * atan(mitad))

## Un renglón por segundo. Los milisegundos son POR FOTOGRAMA: la física suma
## todos los pasos de 120 Hz que han caído dentro, así que a menos fotogramas
## por segundo, más física por fotograma.
func _medida(delta: float, proceso: int) -> void:
	_med_proceso += proceso
	_med_n += 1
	_med_t += delta
	# El fotograma más largo del segundo: un sombreador que se compila jugando
	# (algo que la carga por partes no vio) sale aquí como un pico suelto. Se
	# mide con el reloj de verdad y no con `delta`: a paso fijo (lo que pone
	# `godot3d.py` si no se le dice `--fps 0`) `delta` vale siempre un sesentavo.
	var ahora := Time.get_ticks_usec()
	if _med_antes > 0:
		var cuadro := float(ahora - _med_antes) / 1.0e6
		_med_pico = maxf(_med_pico, cuadro)
		if cuadro > TIRON and _con_carga and not _cargando:
			_apuntar_tiron(cuadro)
	if _tirones and _con_carga and not _cargando:
		_tir_recien = PackedStringArray()
		_mirar_a_la_vista(mundo, true)
		# Sin contar lo que tarda en mirar: no es del juego.
		ahora = Time.get_ticks_usec()
	_med_antes = ahora
	if _med_t < 1.0:
		return
	var n := float(_med_n)
	var texto := "fps %.1f · pico %d ms · física %.2f ms · guion %.2f ms · dibujos %d · objetos %d · triángulos %d · %s %dx%d" % [
		n / _med_t, int(_med_pico * 1000.0), float(_med_fisica) / 1000.0 / n, float(_med_proceso) / 1000.0 / n,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		CALIDADES[calidad], vp.size.x, vp.size.y]
	if _grafica != "":
		texto += " · " + _grafica.replace("'", "")
	if _web:
		JavaScriptBridge.eval("window.__medida = '%s'" % texto, true)
	else:
		print(texto)
	_med_fisica = 0
	_med_proceso = 0
	_med_n = 0
	_med_t = 0.0
	_med_pico = 0.0

func _capturar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura: ", ProjectSettings.globalize_path(ruta))
