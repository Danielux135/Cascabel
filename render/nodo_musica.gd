class_name NodoMusica
extends Node

## Reproduce los bucles de assets/musica/, recortados por musica.py.
##
## VA CON DOS REPRODUCTORES Y CRUZA DE UNO A OTRO, y esa es toda la diferencia
## con `NodoSonido`. Un efecto empieza y acaba; una pieza de música dura lo que
## dure el estado, así que cambiar de estado significa PARAR una y ARRANCAR
## otra, y hacerlo de golpe se oye como un corte de cinta. Entre la mesa y el
## mapa se cambia de pieza varias veces por run.
##
## La otra mitad del sistema no está aquí: está en el bus `Musica` de
## `audio_bus_layout.tres`, ocho decibelios por debajo de los efectos, que es
## donde `assets/prompts_musica.md` §3 dice que se arregla la mezcla.

const RUTA := "res://assets/musica/%s.ogg"
const BUS := "Musica"

## Ajuste por pieza. `db` es el volumen relativo dentro del bus de música —el
## nivel general ya lo pone el bus, así que esto solo sirve para que unas no
## tapen a otras— y `bucle` dice si la pieza se repite o suena una vez y calla.
##
## ES UN CANDADO, no una comodidad: la batería comprueba que no hay ni un OGG
## en `assets/musica/` fuera de esta tabla ni una fila sin archivo. Es la misma
## avería que abrió la tanda 0h2 —un wav generado y sin enganchar es un evento
## mudo esperando— y la misma que la tanda 7, con dos criaturas cortadas que no
## cargaba nadie.
const PIEZAS := {
	# El 80 % de la partida. Va la más baja de todas porque es la única que
	# suena CON la bola encima: las demás suenan con la mesa parada.
	"combate":    {"db": -3.0, "bucle": true},
	# Casi silencio a propósito (§4.2). Sube porque no tiene con qué pelearse.
	"escritorio": {"db":  0.0, "bucle": true},
	# La pieza bonita, y la única. Suena entera y sin nada delante.
	"recuperado": {"db":  0.0, "bucle": true},
	"jefe":       {"db": -2.0, "bucle": true},
	"mapa":       {"db": -1.0, "bucle": true},
	# La caza es prisa, no volumen (§4.6). Al nivel del combate.
	"caza":       {"db": -3.0, "bucle": true},
	# Las dos que terminan. `tilt` es lo último que se oye de un run y detrás
	# va silencio, así que no puede quedar por debajo de nada.
	"arranque":   {"db":  0.0, "bucle": false},
	"tilt":       {"db":  1.0, "bucle": false},
}

## Cuánto tarda un cambio de pieza, en segundos. Corto para que el estado nuevo
## se note enseguida, y no tanto como para que se oigan las dos a la vez.
const CRUCE := 0.8

## Cuánto se agacha la música mientras hay más de una bola en juego, y lo que
## tarda en subir y bajar. §3 lo pide con esas palabras: "la música agachándose
## un par de dB durante el multibola". Con cuatro bolas en la mesa hay cuatro
## veces más golpes por segundo, y ahí la música estorba.
const AGACHE_DB := -4.0
const AGACHE_SUBIDA := 0.25

var _streams: Dictionary = {}
## Los dos reproductores. `_vivo` es el índice del que lleva la pieza actual.
var _voces: Array[AudioStreamPlayer] = []
## Qué pieza lleva cada voz. Se guarda aparte en vez de sacarlo del recurso que
## tiene puesto: la voz que se está apagando sigue necesitando SU ajuste de
## volumen durante todo el cruce, y preguntárselo al stream para volver a
## buscarlo en la tabla es dar un rodeo para llegar a un dato que ya se sabía.
var _lleva: Array[String] = ["", ""]
var _vivo: int = 0
## Qué suena ahora. "" es silencio.
var sonando: String = ""
## De 0 a 1: cuánto ha avanzado el cruce. En 1 el cruce está hecho.
var _cruce: float = 1.0
var _agache: float = 0.0
var _agachando := false

func _ready() -> void:
	preparar()

## CARGA LAS PIEZAS Y MONTA LAS VOCES, y va aparte de `_ready` a propósito.
##
## La batería corre sobre un `SceneTree` pelado, y ahí meter un nodo en `root`
## NO dispara `_ready`: medido, cero hijos y cero piezas cargadas. Con todo esto
## dentro de `_ready`, las pruebas del catálogo estarían comprobando un nodo
## vacío y pasarían siempre — una prueba que no puede fallar es peor que no
## tenerla, porque además da tranquilidad.
##
## Es idempotente: llamarla dos veces no monta catorce voces.
func preparar() -> void:
	if not _voces.is_empty():
		return
	for nombre in PIEZAS:
		var ruta: String = RUTA % nombre
		if ResourceLoader.exists(ruta):
			var s: AudioStream = load(ruta)
			# EL BUCLE SE PONE AQUÍ Y NO EN EL .import. Godot sirve la copia de
			# `.godot/imported/`, así que un `loop` puesto a mano en el archivo
			# de importación se pierde en cuanto alguien reimporta sin abrir el
			# editor — y reimportar es justo lo primero que hay que hacer al
			# regenerar audio, que ya es una trampa escrita en `CLAUDE.md`.
			# Puesto en el recurso cargado, la tabla de arriba es la única
			# fuente de verdad y hay una prueba que lo comprueba.
			if s is AudioStreamOggVorbis:
				(s as AudioStreamOggVorbis).loop = bool(
					(PIEZAS[nombre] as Dictionary)["bucle"])
			_streams[nombre] = s
		else:
			push_warning("Falta %s. Se genera con: python musica.py cortar"
				% ruta)
	for _i in 2:
		var v := AudioStreamPlayer.new()
		v.bus = BUS
		add_child(v)
		_voces.append(v)

## PONE LA PIEZA QUE TOCA. Llamarla con lo que ya suena no hace nada, así que
## se puede llamar cada fotograma sin pensar: quien decide la música mira el
## estado del juego, no se acuerda de lo que pidió la última vez. Un sistema
## que hay que acordarse de apagar acaba sonando en el sitio equivocado, que es
## la avería de la caza que cruzaba de un combate al siguiente.
func poner(nombre: String) -> void:
	# Sin voces montadas no hay nada que poner. Pasa entre el `_init` y el
	# `_ready`, y quien decide la música ya está preguntando en ese hueco.
	if _voces.is_empty() or nombre == sonando:
		return
	if nombre != "" and not _streams.has(nombre):
		return
	# UNA PIEZA QUE TERMINA NO SE INTERRUMPE. `arranque` y `tilt` duran lo que
	# duran y las dos son el principio y el final de algo: el arranque es lo
	# único que se oye antes del escritorio, y el sting de TILT es lo último
	# que se oye de un run, con su silencio detrás formando parte del efecto
	# (§4.9). Como quien pide la música mira el estado del juego cada
	# fotograma, sin esto el escritorio pisaría al arranque en el primero.
	#
	# No hace falta acordarse de nada al acabar: la petición se sigue haciendo
	# cada fotograma, así que en cuanto la voz calla, entra sola la que toque.
	if protegida():
		return
	sonando = nombre
	_vivo = 1 - _vivo
	_cruce = 0.0
	_lleva[_vivo] = nombre
	var v: AudioStreamPlayer = _voces[_vivo]
	if nombre == "":
		v.stop()
		return
	v.stream = _streams[nombre]
	v.volume_db = -60.0
	# Fuera del árbol no se puede reproducir, y la batería corre justo así: sin
	# esta guarda, cada prueba que pide una pieza deja un ERROR de Godot en la
	# salida. Y un error suelto en la batería no es cosmético — hay una trampa
	# escrita sobre esto: el contador de pruebas cambia sin que nadie lo diga.
	if v.is_inside_tree():
		v.play()

## Si lo que suena es de las que TERMINAN y todavía no ha acabado. Mientras sea
## cierto, `poner` no cambia de pieza.
##
## Está separado de `poner` para poder comprobarlo: la mitad que depende de que
## la voz siga sonando no se puede probar sin tarjeta de sonido, pero la otra
## mitad —qué piezas son de las que terminan— sí, y es la que se equivoca al
## añadir una pieza nueva.
func protegida() -> bool:
	if _voces.is_empty() or sonando == "" or not PIEZAS.has(sonando):
		return false
	if bool((PIEZAS[sonando] as Dictionary)["bucle"]):
		return false
	return _voces[_vivo].playing

## Agacha la música mientras dure algo que necesita el sitio. Es continuo, no
## un disparo: se llama con `true` mientras haga falta y con `false` cuando ya
## no, y el nivel viaja solo.
func agachar(si: bool) -> void:
	_agachando = si

func _process(delta: float) -> void:
	_agache = move_toward(_agache, AGACHE_DB if _agachando else 0.0,
		absf(AGACHE_DB) / AGACHE_SUBIDA * delta)
	if _cruce < 1.0:
		_cruce = minf(1.0, _cruce + delta / CRUCE)
	for i in _voces.size():
		var v: AudioStreamPlayer = _voces[i]
		if not v.playing:
			continue
		var parte: float = _cruce if i == _vivo else 1.0 - _cruce
		# SOLO SE PARA LA QUE SE VA, y el `i != _vivo` no es una precaución: la
		# voz que ENTRA empieza el cruce con parte 0 —`_cruce` arranca en 0 en
		# el mismo `poner`— así que sin esta condición cada pieza nueva se
		# paraba a sí misma en su primer fotograma y no llegaba a sonar nunca.
		if parte <= 0.0 and i != _vivo:
			v.stop()
			continue
		# Y el volumen se recorta por abajo antes de pasar a decibelios: el
		# logaritmo de 0 es menos infinito, y eso no es un silencio, es un NaN
		# viajando hacia el mezclador.
		parte = maxf(parte, 0.0001)
		var ajuste: Dictionary = PIEZAS.get(_lleva[i], {})
		# EL CRUCE VA EN DECIBELIOS Y NO EN LINEAL. Repartir el volumen a
		# medias entre las dos deja un bache justo en la mitad del cambio: dos
		# fuentes al 50 % de amplitud no suenan como una al 100 %. Pasar la
		# parte por `linear_to_db` es lo que hace que el cruce suene plano.
		v.volume_db = (float(ajuste.get("db", 0.0)) + _agache
			+ linear_to_db(parte))
