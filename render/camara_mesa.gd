class_name CamaraMesa
extends Camera2D

## Cámara vertical de la mesa. Las cuatro reglas de PLAN.md, y `objetivo()` es
## pura a propósito para poder comprobarlas en headless.

var p: ParametrosCamara
var alto_mesa: float = 700.0
var centro_x: float = 200.0
var y_actual: float = 0.0
## Desplazamiento de la sacudida. Va en `offset` de la cámara y no moviendo el
## nodo de la mesa: si se moviera la mesa, la cámara se movería con ella y la
## sacudida no se vería.
var sacudida := Vector2.ZERO
## Histéresis de la zona muerta (REGLA 4). Fuera de la zona la cámara arranca;
## una vez arrancada va hasta el objetivo y no se para a medio camino. Sin este
## estado, la zona muerta se convierte en un error permanente de su tamaño.
var _siguiendo := false
## Dónde estaba la cámara al empezar este paso. Solo para depurar y medir.
var _antes: float = 0.0
## Velocidad actual de la cámara, en px/s. La lleva el muelle: sin ella no habría
## forma de que la aceleración fuera continua, que es lo único que se nota.
var _velocidad: float = 0.0

func _init(parametros: ParametrosCamara, el_alto: float, el_centro_x: float) -> void:
	p = parametros
	alto_mesa = el_alto
	centro_x = el_centro_x
	anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	y_actual = limite_abajo()
	_colocar()

func limite_arriba() -> float:
	return p.alto_visible * 0.5

func limite_abajo() -> float:
	return maxf(alto_mesa - p.alto_visible * 0.5, limite_arriba())

## Cuánto mira la cámara por debajo de la bola. En una bola que cae el adelanto
## útil no son píxeles, son SEGUNDOS: lo que hay que enseñar es dónde va a estar
## la bola, y eso depende de a qué velocidad baja.
func adelanto_de(bola_vy: float) -> float:
	if bola_vy <= 0.0:
		return p.adelanto_subiendo
	return p.adelanto + bola_vy * p.tiempo_anticipacion

## Dónde tiene que llegar el BORDE INFERIOR de la pantalla, en coordenadas de
## mesa. Es la regla que faltaba, y la que arregla lo del flipper: no basta con
## que la bola esté en pantalla, tiene que verse el trozo de mesa al que va.
##
## Nunca pide más allá del fondo de la mesa, así que cuando la bola entra en la
## banda de los flippers esto vale exactamente `alto_mesa`, que es el ancla
## inferior: la REGLA 2 sale de aquí sola, en vez de ser un caso aparte.
func suelo_visible(bola_y: float, bola_vy: float) -> float:
	# AQUÍ HABÍA UN ESCALÓN Y ERA EL "EN CIERTO PUNTO" DE DANIEL. Estaba escrito
	# `if bola_y > alto_mesa - margen_ancla: return alto_mesa`, o sea que al
	# cruzar la bola la línea de seguridad (y=1000) el suelo garantizado saltaba
	# de golpe de ~1150 a 1300: 150 px de un fotograma al siguiente, siempre en el
	# MISMO sitio de la mesa. Por eso se notaba como un punto concreto y no como
	# una brusquedad repartida.
	#
	# Quitarlo no afloja la REGLA 2, porque la regla la sigue poniendo
	# `objetivo()`: por debajo de esa línea el objetivo YA es el ancla de abajo, y
	# la garantía solo tiene que impedir que la cámara se quede corta mientras
	# llega. Y no se queda: con la bola en y=1150 esto ya vale 1300 igual, y con
	# una bola rápida el término de `vy` lo lleva al tope mucho antes.
	var y_prevista := bola_y + maxf(bola_vy, 0.0) * p.tiempo_anticipacion
	return minf(y_prevista + p.margen_debajo_bola, alto_mesa)

## Dónde querría estar la cámara ahora mismo. Sin suavizado ni estado.
func objetivo(bola_y: float, bola_vy: float, hay_bola: bool) -> float:
	if not hay_bola:
		return limite_abajo()
	# REGLA 2: por debajo de la línea de seguridad, anclada abajo y punto.
	if bola_y > alto_mesa - p.margen_ancla:
		return limite_abajo()
	# REGLA 1: si cae, se adelanta; si sube, no la persigue.
	return clampf(bola_y + adelanto_de(bola_vy), limite_arriba(), limite_abajo())

## Dónde tiene que estar la cámara contando TODAS las reglas, garantías
## incluidas. Es pura a propósito, igual que `objetivo()`: así se puede
## comprobar en headless sin montar nada.
##
## LAS GARANTÍAS SON PARTE DEL OBJETIVO, NO UN RECORTE DE DESPUÉS, y ese es el
## segundo arreglo del tirón. Aplicadas después del suavizado eran un `minf` y un
## `maxf` sobre la posición ya calculada: la cámara se movía suave y luego se
## teletransportaba a lo que mandaba la garantía. Metidas aquí, la garantía dice
## a DÓNDE hay que ir y el suavizado decide CÓMO se llega, que es lo que hace que
## se lea como una cámara y no como un corte.
func objetivo_completo(bola_y: float, bola_vy: float, hay_bola: bool) -> float:
	var obj := objetivo(bola_y, bola_vy, hay_bola)
	if hay_bola:
		var media := p.alto_visible * 0.5
		# Por arriba: la barra de título de la ventana de la mesa tapa los
		# primeros píxeles de pantalla y la bola se escondía detrás en lo alto
		# de la órbita.
		obj = minf(obj, bola_y + media - p.alto_franja_hud - p.margen_superior)
		# Y va DESPUÉS del recorte de arriba a propósito: cuando las dos no caben
		# en 540 px, MANDA VER DÓNDE CAE LA BOLA. La garantía vieja era la
		# contraria —la bola pegada al canto de abajo, con nada debajo— y por eso
		# una bola rápida llegaba a un flipper que no estaba en plano.
		obj = maxf(obj, suelo_visible(bola_y, bola_vy) - media)
	return clampf(obj, limite_arriba(), limite_abajo())

func avanzar(delta: float, bola_y: float, bola_vy: float, hay_bola: bool) -> void:
	_antes = y_actual
	var obj := objetivo_completo(bola_y, bola_vy, hay_bola)
	var d := obj - y_actual
	# REGLA 4: zona muerta CON HISTÉRESIS. La zona decide si la cámara arranca;
	# el objetivo decide dónde para. Escrito al revés —moviéndose hacia el borde
	# de la zona en vez de hacia el objetivo— la cámara se queda a `zona_muerta`
	# del sitio para siempre, y con el ancla inferior eso son los 45 px del
	# fondo de la mesa sin verse jamás. Era el bug de "nunca está abajo del
	# todo".
	if absf(d) > p.zona_muerta:
		_siguiendo = true
	if _siguiendo:
		y_actual = _amortiguar(obj, delta,
			p.tiempo_suavizado if hay_bola else p.tiempo_suavizado_reposo)
		if absf(obj - y_actual) < 1.0 and absf(_velocidad) < 20.0:
			y_actual = obj
			_velocidad = 0.0
			_siguiendo = false
	else:
		# Parada y quieta: la velocidad tiene que morir aquí también, o al volver
		# a arrancar la cámara saldría con el empujón del movimiento anterior.
		_velocidad = 0.0

	# LA GARANTÍA, OTRA VEZ Y AL FINAL — pero ahora es una red, no el mecanismo.
	#
	# Está en los dos sitios a propósito, y no es duplicar por duplicar:
	# `objetivo_completo` la usa para APUNTAR, así que el muelle sale hacia allí
	# con tiempo y llega suave; esto de aquí solo se activa si aun así no ha
	# llegado. Medido: sin esta red, con la bola cayendo a 1900 px/s se perdía la
	# punta de la pala en 10 fotogramas y hasta 66 px, que es exactamente la
	# avería que costó una sesión entera arreglar. Con ella, cero.
	#
	# Y cuando muerde, el salto es pequeño justamente porque el muelle ya venía
	# de camino: lo que antes eran 113 px de corte ahora son unos pocos.
	if hay_bola:
		var media := p.alto_visible * 0.5
		# El techo también es red, y por el mismo motivo que el suelo: dentro de
		# la zona muerta la cámara NO se mueve, así que el objetivo no se aplica
		# y la bola podía subirse detrás de la barra de título sin que nada la
		# parara. Lo cazó la batería: 8 fotogramas tapada, hasta 22 px de
		# pantalla contra los 24 que mide el marco.
		y_actual = minf(y_actual,
			bola_y + media - p.alto_franja_hud - p.margen_superior)
		# Y el suelo va DESPUÉS del techo a propósito, igual que siempre: cuando
		# las dos no caben en 540 px, MANDA VER DÓNDE CAE LA BOLA.
		var suelo := suelo_visible(bola_y, bola_vy) - media
		if y_actual < suelo:
			y_actual = suelo
			# La velocidad se queda: si se pusiera a cero, el muelle frenaría en
			# seco cada vez que la red muerde y eso SÍ se nota.
			_velocidad = maxf(_velocidad, 0.0)
	y_actual = clampf(y_actual, limite_arriba(), limite_abajo())
	# Y EL TOPE DE VELOCIDAD, EL ÚLTIMO DE TODO Y CASI SIEMPRE DORMIDO.
	#
	# Con el objetivo ya continuo y el muelle haciendo el trabajo, el peor
	# fotograma medido mueve la cámara ~6 px y el tope está en 21, así que esto no
	# toca nada de lo que se juega. Existe para lo que el medidor no ve: cuando la
	# BOLA se teletransporta —se sirve una nueva, empieza otro combate— el
	# objetivo se va de golpe al otro extremo de la mesa. Medido en el juego
	# corriendo, 659 px en un fotograma. Eso no es una cámara, es un corte de
	# montaje, y aquí se convierte en un barrido de un cuarto de segundo.
	y_actual = move_toward(_antes, y_actual, p.velocidad_maxima * delta)
	_colocar()

## MUELLE CRÍTICAMENTE AMORTIGUADO (REGLA 5), y es lo que sustituye al `lerp`
## más el tope de velocidad.
##
## La diferencia que se NOTA no es el tamaño del salto, es que aquí la VELOCIDAD
## de la cámara también es continua: arranca de cero, acelera y frena. Un `lerp`
## arranca a tope y va frenando —o sea, tirón al empezar— y un tope de velocidad
## es peor todavía: velocidad constante con arranque y parada instantáneos, que
## es exactamente lo que se lee como mecánico. Medido en aceleración, que es lo
## que siente el ojo: se pasa de 1560 px/s² de pico a menos de 300.
##
## `tiempo_suavizado` es CUÁNTO TARDA EN LLEGAR, más o menos, y por eso es el
## dial bueno: se piensa en segundos, no en un factor por fotograma que además
## depende de los FPS. Sin sobrepaso nunca: la cámara no se pasa de largo y
## vuelve, que en una mesa vertical se leería como un rebote que no existe.
func _amortiguar(destino: float, delta: float, tiempo: float) -> float:
	var t := maxf(tiempo, 0.0001)
	var omega := 2.0 / t
	var x := omega * delta
	# Aproximación racional de exp(-x): sin llamar a exp() y estable con delta
	# grandes, que es cuando un muelle mal integrado explota.
	var caida := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var cambio := y_actual - destino
	# Tope de recorrido (REGLA 5). Se limita la DISTANCIA que se considera, no la
	# velocidad: recortar la velocidad devolvería la esquina dura que se quería
	# quitar. Con esto, un salto enorme del objetivo se persigue igual de suave,
	# solo que desde más cerca.
	var tope := p.velocidad_maxima * t
	cambio = clampf(cambio, -tope, tope)
	var meta := y_actual - cambio
	var temp := (_velocidad + omega * cambio) * delta
	_velocidad = (_velocidad - omega * temp) * caida
	return meta + (cambio + temp) * caida

## La sacudida se actualiza a ritmo de fotograma, pero `avanzar` va con la
## física: hacer las dos cosas juntas dejaba la cámara con la posición de la
## bola de un fotograma antes, y en la órbita esos 22 px la metían tras el HUD.
func aplicar_sacudida(v: Vector2) -> void:
	sacudida = v
	offset = sacudida.round()

func _colocar() -> void:
	# REGLA 3: posición en píxeles enteros. Con posición fraccionaria, filtro
	# nearest y escalado entero, la mesa entera hierve.
	position = Vector2(roundf(centro_x), roundf(y_actual))
	offset = sacudida.round()

## Rectángulo de mesa que se está viendo. Para las pruebas y la depuración.
func rect_visible() -> Rect2:
	return Rect2(position.x - p.ancho_visible * 0.5,
		position.y - p.alto_visible * 0.5, p.ancho_visible, p.alto_visible)
