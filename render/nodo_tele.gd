class_name NodoTele
extends Node2D

## La tele de la mesa: una pantalla empotrada entre los slingshots y los
## flippers, donde ya vivía el número del multiplicador.
##
## NO ES UN OBJETO FÍSICO Y NO PUEDE SERLO. No tiene colisionador: la bola pasa
## por encima y se dibuja delante. Meter una caja ahí sería cambiar la geometría
## de la mesa —que es artesanía y es invariante— y además crear justo el tipo de
## rincón donde la bola se acuña, en el peor sitio posible: el hueco entre palas.
## Es una pantalla empotrada en el tablero, como los insertos de un pinball de
## verdad.
##
## VA DONDE VA POR UNA RAZÓN: la cámara, sin bola, se ancla abajo, y ahí es
## donde tienes el ojo mientras juegas. El multiplicador ya estaba dibujado en
## ese punto exacto, así que la tele es el marco de lo que ya mirabas. Y cuando
## toca recompensa, la misma tele gira la ruleta: el premio sale donde estabas
## mirando, no en otra pantalla.
##
## Qué enseña, por orden de mando:
##   1. la ruleta, si está girando
##   2. la reliquia que ha tocado, en grande
##   3. el multiplicador, que es el estado normal

const C_CABINA      := Paleta.CABINA
const C_MESA_BAJA   := Paleta.MESA_BAJA
const C_METAL       := Paleta.METAL
const C_METAL_LUZ   := Paleta.METAL_LUZ
const C_TEXTO       := Paleta.TEXTO
const C_TEXTO_TENUE := Paleta.TEXTO_TENUE
const C_ORO         := Paleta.ORO
const C_ORO_CLARO   := Paleta.ORO_CLARO
const C_ARCANO      := Paleta.ARCANO
const C_VERDE       := Paleta.VERDE
const C_FUEGO       := Paleta.FUEGO
const C_GOMA_LUZ    := Paleta.GOMA_LUZ

## El hueco de pantalla, en coordenadas de mesa. Centrado en el eje y por encima
## de los flippers, que a plena subida llegan a y~1150.
const MARCO := Rect2(112, 1042, 176, 116)
const GROSOR_MARCO := 4.0

## Fases de la recompensa. La ruleta ya está sorteada antes de que esto empiece:
## esto solo lo cuenta.
enum Fase { QUIETA, GIRANDO, PARADA, MOSTRANDO }

## Cuánto dura cada trozo. La suma es lo que tarda la recompensa de principio a
## fin, y es EL número de esta pantalla: si pasa de unos cuatro segundos, vuelve
## a ser una parada y volvemos al problema que la ruleta venía a resolver.
const DUR_GIRO := 1.30
const DUR_PARADA := 0.85
const DUR_MOSTRAR := 2.00

var vista: VistaMesa
var run: Run
var _fuente: Font
var fase: int = Fase.QUIETA
var _t: float = 0.0
## Posición continua del carrete, en casillas. Solo animación.
var _rodillo: float = 0.0
var _velocidad: float = 0.0
var _texturas: Dictionary = {}
## Para que el tic de la ruleta suene una vez por casilla y no por fotograma.
var _casilla_sonada: int = -1
## Latido al subir de tramo. Es lo único que hace que el número se note sin
## taparte la bola, y venía del suelo, de donde se ha mudado el combo.
var _pulso: float = 0.0

func pulsar() -> void:
	_pulso = 1.0

func _init(la_vista: VistaMesa, el_run: Run) -> void:
	vista = la_vista
	run = el_run
	# Por encima del suelo y del enemigo, por debajo de la bola y las paredes,
	# igual que el número del combo al que sustituye.
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _ready() -> void:
	_fuente = FuenteUI.obtener()

func activa() -> bool:
	return fase != Fase.QUIETA

## Arranca la secuencia. El premio ya está decidido en `run`.
func empezar() -> void:
	fase = Fase.GIRANDO
	_t = 0.0
	_rodillo = 0.0
	_velocidad = 26.0
	_casilla_sonada = -1

## Otra tirada, si queda. Devuelve si ha girado de verdad.
func repetir() -> bool:
	if fase != Fase.PARADA or not run.repetir_tirada():
		return false
	fase = Fase.GIRANDO
	_t = 0.0
	_velocidad = 26.0
	_casilla_sonada = -1
	return true

## Salta al final de lo que esté haciendo. Nunca cambia el premio: el premio se
## sorteó antes de girar nada.
func saltar() -> void:
	match fase:
		Fase.GIRANDO: _parar()
		Fase.PARADA: _mostrar()
		Fase.MOSTRANDO: _cerrar()

func avanzar(delta: float) -> void:
	if fase == Fase.QUIETA:
		return
	_t += delta
	match fase:
		Fase.GIRANDO:
			# Frenado exponencial y parada en seco al final del tiempo: si se
			# dejara frenar hasta cero, la última casilla tardaría siglos en
			# entrar y la ruleta se sentiría rota.
			_velocidad = maxf(_velocidad * exp(-2.6 * delta), 1.5)
			_rodillo += _velocidad * delta
			var casilla := int(_rodillo)
			if casilla != _casilla_sonada:
				_casilla_sonada = casilla
				vista.sonar_ruleta(minf(_t / DUR_GIRO, 1.0))
			if _t >= DUR_GIRO:
				_parar()
		Fase.PARADA:
			if _t >= DUR_PARADA:
				_mostrar()
		Fase.MOSTRANDO:
			if _t >= DUR_MOSTRAR:
				_cerrar()

func _parar() -> void:
	fase = Fase.PARADA
	_t = 0.0
	# El carrete se cuadra en la casilla 0, que es el premio.
	_rodillo = 0.0
	vista.sonar_premio()

func _mostrar() -> void:
	fase = Fase.MOSTRANDO
	_t = 0.0

func _cerrar() -> void:
	fase = Fase.QUIETA
	_t = 0.0
	run.aceptar_premio()
	vista.terminar_ruleta()

# ------------------------------------------------------------------- dibujo

func _process(delta: float) -> void:
	_pulso = maxf(_pulso - delta * 2.6, 0.0)
	# Mientras juegas la tele va DEBAJO de la bola, como iba el número del combo:
	# no puede taparte el juego. Durante la ruleta sube por encima del velo, que
	# es lo único que la deja leerse con el resto de la mesa apagada.
	z_index = 5 if activa() else -1
	queue_redraw()

func _draw() -> void:
	_dibujar_mueble()
	match fase:
		Fase.GIRANDO: _dibujar_rodillo()
		Fase.PARADA: _dibujar_premio(false)
		Fase.MOSTRANDO: _dibujar_premio(true)
		_: _dibujar_combo()

## El mueble de la tele. Va apagado a propósito: está debajo de la bola y no
## puede competir con ella mientras juegas.
func _dibujar_mueble() -> void:
	var fuera := MARCO.grow(GROSOR_MARCO)
	draw_rect(fuera, C_METAL)
	draw_rect(fuera, C_METAL_LUZ, false, 1.0)
	draw_rect(MARCO, C_CABINA)
	# Dos tornillos, uno a cada lado: dicen "aparato atornillado a la mesa" sin
	# gastar un sprite.
	for x in [fuera.position.x + 2.0, fuera.end.x - 3.0]:
		draw_rect(Rect2(x, fuera.position.y + 2.0, 2.0, 2.0), C_METAL_LUZ)
		draw_rect(Rect2(x, fuera.end.y - 4.0, 2.0, 2.0), C_METAL_LUZ)

func _centro() -> Vector2:
	return MARCO.position + MARCO.size * 0.5

## El estado normal: LA MISIÓN, que es lo que hace que un combate de tres
## minutos no sea el mismo minuto repetido tres veces. Es el display del pinball
## del XP: siempre dice qué toca ahora.
##
## El multiplicador se queda debajo, pequeño. Cambió de sitio a propósito: era
## el número grande de la mesa, pero el multiplicador dice cómo vas y la misión
## dice qué hacer, y lo que hace falta mientras juegas es lo segundo.
func _dibujar_combo() -> void:
	var combate := vista.combate
	if combate == null or combate.enemigo == null:
		return
	if combate.mision() != null:
		_dibujar_mision(combate)
		return
	_dibujar_multiplicador_grande(combate)

## Cuando ya no queda misión que hacer en este combate, la tele vuelve a ser el
## marcador del multiplicador, que es lo que era antes.
func _dibujar_multiplicador_grande(combate: Combate) -> void:
	var factor := combate.multiplicador()
	var estilo: Dictionary = VistaMesa.COMBO_ESTILO.get(factor,
		VistaMesa.COMBO_ESTILO[1])
	var col: Color = estilo["col"]
	col.a = float(estilo["alfa"]) * (1.0 if not combate.terminado() else 0.35)
	var c := _centro()
	# El latido escala el número desde su centro. En pasos de píxel no: es texto,
	# no un sprite, y aquí el temblor no se nota como en la rejilla de la mesa.
	var escala := 1.0 + _pulso * 0.30
	draw_set_transform(c, 0.0, Vector2(escala, escala))
	draw_string(_fuente, Vector2(-MARCO.size.x * 0.5, 8.0), "x%d" % factor,
		HORIZONTAL_ALIGNMENT_CENTER, MARCO.size.x, 48, col)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var faltan := _golpes_para_subir(combate)
	if faltan > 0 and not combate.terminado():
		draw_string(_fuente, Vector2(MARCO.position.x, MARCO.end.y - 12.0),
			"%d para x%d" % [faltan, factor + 1],
			HORIZONTAL_ALIGNMENT_CENTER, MARCO.size.x, 8, Color(col, col.a * 0.85))

## Un color por rareza, que es lo que dice de un vistazo lo que hay en juego.
static func color_de_rareza(rareza: int) -> Color:
	match rareza:
		Mision.Rareza.RARA: return Paleta.ORO_CLARO
		Mision.Rareza.ARCANA: return Paleta.ARCANO
	return Paleta.ORO

## La misión en curso: rareza, qué pide, y una barra por paso.
##
## Las barras son lo que de verdad se lee de reojo. Un "2/3" en 9 px no se lee
## mientras persigues una bola; tres cuadraditos, sí.
func _dibujar_mision(combate: Combate) -> void:
	var m := combate.mision()
	var col := NodoTele.color_de_rareza(m.rareza)
	var x := MARCO.position.x + 4.0
	var ancho := MARCO.size.x - 8.0

	draw_string(_fuente, Vector2(x, MARCO.position.y + 13.0),
		m.rotulo_rareza().to_upper(), HORIZONTAL_ALIGNMENT_LEFT, ancho, 8, col)
	draw_string(_fuente, Vector2(x, MARCO.position.y + 13.0),
		"x%d" % combate.multiplicador(), HORIZONTAL_ALIGNMENT_RIGHT, ancho, 8,
		Color(C_TEXTO_TENUE, 0.9))
	draw_string(_fuente, Vector2(x, MARCO.position.y + 30.0), m.nombre,
		HORIZONTAL_ALIGNMENT_CENTER, ancho, 16, C_TEXTO)
	draw_multiline_string(_fuente, Vector2(x, MARCO.position.y + 47.0), m.texto,
		HORIZONTAL_ALIGNMENT_CENTER, ancho, 8, 2, Color(C_TEXTO_TENUE, 0.95))

	# Una fila de casillas por paso. Con `orden`, el paso en curso se enciende y
	# los que aún no tocan van apagados: es lo que cuenta que hay una secuencia.
	var paso := combate.paso_actual()
	var y := MARCO.end.y - 22.0
	var total := 0
	for i in m.tiros.size():
		total += m.veces(i)
	var hueco := ancho / float(maxi(total, 1))
	var lado := minf(hueco - 2.0, 10.0)
	var cx := x
	for i in m.tiros.size():
		var activo := not m.orden or i <= paso or paso < 0
		for k in m.veces(i):
			var hecho := k < combate.llevas(i)
			var caja := Rect2(roundf(cx), roundf(y), lado, lado)
			if hecho:
				draw_rect(caja, col)
			else:
				draw_rect(caja, Color(col, 0.5 if activo else 0.18), false, 1.0)
			cx += hueco
		cx += 2.0
	# Y el tiro que toca ahora, escrito: las casillas dicen cuánto falta, no qué.
	if paso >= 0:
		draw_string(_fuente, Vector2(x, MARCO.end.y - 4.0),
			m.rotulo_tiro(paso).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, ancho, 8,
			Color(col, 0.9))
	if m.sin_drenar:
		draw_string(_fuente, Vector2(x, MARCO.position.y + 30.0), "SIN DRENAR",
			HORIZONTAL_ALIGNMENT_RIGHT, ancho, 8, Color(C_GOMA_LUZ, 0.85))

func _golpes_para_subir(combate: Combate) -> int:
	var factor := combate.multiplicador()
	# Contra `tramos()`, no contra los parámetros: con una reliquia que adelante
	# los tramos, los parámetros dirían un número que ya no es el de tu partida.
	for tramo in combate.tramos():
		if int((tramo as Dictionary)["factor"]) > factor:
			return int((tramo as Dictionary)["golpes"]) - combate.golpes
	return 0

## El carrete girando. Se dibujan tres casillas —la de arriba, la centrada y la
## de abajo— recortadas por la pantalla.
func _dibujar_rodillo() -> void:
	if run.casillas.is_empty():
		return
	var alto := MARCO.size.y
	var desplazado := fposmod(_rodillo, 1.0)
	for k in [-1, 0, 1]:
		var indice := posmod(int(floor(_rodillo)) + k, run.casillas.size())
		var y := MARCO.position.y + alto * (0.5 + float(k) - desplazado)
		_dibujar_casilla(run.casillas[indice], y, 1.0 if k == 0 else 0.45)
	# La ranura de lectura, para que se lea que lo que vale es lo del centro.
	var c := _centro()
	draw_line(Vector2(MARCO.position.x, c.y), Vector2(MARCO.end.x, c.y),
		Color(C_ORO, 0.35), 1.0)

func _dibujar_casilla(r: Reliquia, centro_y: float, alfa: float) -> void:
	if centro_y < MARCO.position.y - MARCO.size.y \
			or centro_y > MARCO.end.y + MARCO.size.y:
		return
	var col := NodoTele.color_de_eje(r.eje)
	var c := _centro()
	var tex := _icono(r)
	if tex != null:
		draw_texture_rect(tex,
			Rect2(roundf(c.x - 32.0), roundf(centro_y - 40.0), 64, 64), false,
			Color(1, 1, 1, alfa))
	else:
		draw_rect(Rect2(c.x - 22.0, centro_y - 30.0, 44, 44), Color(col, alfa * 0.5))
	draw_string(_fuente, Vector2(MARCO.position.x + 4.0, centro_y + 40.0), r.nombre,
		HORIZONTAL_ALIGNMENT_CENTER, MARCO.size.x - 8.0, 8, Color(col, alfa))

## Lo que ha tocado. En `grande` se dibuja además lo que hace: es el momento en
## el que el jugador se entera de qué le acaban de dar, y si no se lee aquí no
## se lee en ninguna parte, porque la lista del mapa solo trae el nombre.
func _dibujar_premio(grande: bool) -> void:
	if run.premio == null:
		return
	var r := run.premio
	var col := NodoTele.color_de_eje(r.eje)
	var c := _centro()
	draw_rect(MARCO, Color(col, 0.10))
	var tex := _icono(r)
	if tex != null:
		draw_texture_rect(tex, Rect2(roundf(c.x - 32.0),
			roundf(MARCO.position.y + 6.0), 64, 64), false)
	else:
		draw_rect(Rect2(c.x - 22.0, MARCO.position.y + 16.0, 44, 44),
			Color(col, 0.55))
	draw_string(_fuente, Vector2(MARCO.position.x + 4.0, MARCO.position.y + 86.0),
		r.nombre, HORIZONTAL_ALIGNMENT_CENTER, MARCO.size.x - 8.0, 8, col)
	if not grande:
		# La ventana de repetir. Se dice con la tecla que ya tienes en la mano.
		if run.repeticiones > 0:
			draw_string(_fuente, Vector2(MARCO.position.x + 4.0, MARCO.end.y - 8.0),
				"A o D: otra tirada", HORIZONTAL_ALIGNMENT_CENTER,
				MARCO.size.x - 8.0, 8, C_ORO_CLARO)
		return
	draw_string(_fuente, Vector2(MARCO.position.x + 4.0, MARCO.position.y + 100.0),
		r.rotulo_eje().to_upper(), HORIZONTAL_ALIGNMENT_CENTER,
		MARCO.size.x - 8.0, 8, C_TEXTO_TENUE)

## El texto de lo que hace NO cabe dentro de una tele de 176x116, así que sale
## debajo, sobre el velo oscuro. La tele enseña el objeto; el velo, la letra.
func dibujar_explicacion(en: CanvasItem, ancho: float, centro_x: float) -> void:
	if fase != Fase.MOSTRANDO or run.premio == null:
		return
	var r := run.premio
	var y := MARCO.end.y + 34.0
	en.draw_multiline_string(_fuente, Vector2(centro_x - ancho * 0.5, y), r.texto,
		HORIZONTAL_ALIGNMENT_CENTER, ancho, 16, 3, C_ORO_CLARO)
	en.draw_string(_fuente, Vector2(centro_x - ancho * 0.5, y + 52.0), r.gancho,
		HORIZONTAL_ALIGNMENT_CENTER, ancho, 8, C_TEXTO_TENUE)

## Cuánto hay que oscurecer el resto de la mesa. Entra y sale con la secuencia
## en vez de encenderse de golpe: un corte a negro se lee como un fallo.
func velo() -> float:
	match fase:
		Fase.GIRANDO: return minf(_t / 0.30, 1.0) * 0.72
		Fase.PARADA: return 0.72
		Fase.MOSTRANDO: return 0.72 * (1.0 - clampf(
			(_t - (DUR_MOSTRAR - 0.35)) / 0.35, 0.0, 1.0))
	return 0.0

static func color_de_eje(eje: int) -> Color:
	match eje:
		Reliquia.Eje.COMBO: return Paleta.ORO_CLARO
		Reliquia.Eje.GOLPE_UNICO: return Paleta.FUEGO
		Reliquia.Eje.SUPERVIVENCIA: return Paleta.VERDE
		Reliquia.Eje.ESCALADO: return Paleta.ARCANO
		Reliquia.Eje.CAOS: return Paleta.GOMA_LUZ
	return Paleta.TEXTO

func _icono(r: Reliquia) -> Texture2D:
	var ruta := r.ruta_icono(64)
	if ruta == "":
		return null
	if not _texturas.has(ruta):
		_texturas[ruta] = load(ruta) as Texture2D if ResourceLoader.exists(ruta) else null
	return _texturas[ruta] as Texture2D
