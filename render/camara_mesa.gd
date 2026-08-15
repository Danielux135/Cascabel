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
	# REGLA 2, y va antes que la predicción porque es más fuerte: con la bola
	# por debajo de la línea de seguridad se ve el fondo de la mesa, corra como
	# corra. El tercio de los flippers es intocable.
	if bola_y > alto_mesa - p.margen_ancla:
		return alto_mesa
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

func avanzar(delta: float, bola_y: float, bola_vy: float, hay_bola: bool) -> void:
	var obj := objetivo(bola_y, bola_vy, hay_bola)
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
		var vel := p.suavizado if hay_bola else p.suavizado_reposo
		y_actual = lerpf(y_actual, obj, clampf(vel * delta, 0.0, 1.0))
		if absf(obj - y_actual) < 1.0:
			y_actual = obj
			_siguiendo = false

	if hay_bola:
		var media := p.alto_visible * 0.5
		# Por arriba: la barra de título de la ventana de la mesa tapa los
		# primeros píxeles de pantalla y la bola se escondía detrás en lo alto
		# de la órbita.
		y_actual = minf(y_actual,
			bola_y + media - p.alto_franja_hud - p.margen_superior)
		# GARANTÍA DURA, y va DESPUÉS del recorte de arriba a propósito: cuando
		# las dos no caben en 540 px, MANDA VER DÓNDE CAE LA BOLA. La vieja
		# garantía era la contraria —la bola pegada al canto de abajo, con nada
		# debajo— y por eso una bola rápida llegaba a un flipper que no estaba
		# en plano. Está medido que con estos números la bola nunca se sube por
		# encima de la barra de título: lo más arriba que llega son 48 px de
		# pantalla contra los 24 que mide el marco.
		y_actual = maxf(y_actual, suelo_visible(bola_y, bola_vy) - media)
	y_actual = clampf(y_actual, limite_arriba(), limite_abajo())
	_colocar()

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
