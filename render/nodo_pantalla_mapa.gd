class_name NodoPantallaMapa
extends CanvasLayer

## La pantalla del mapa del run.
##
## OJO: esto NO es la cáscara del sistema operativo. El mapa como explorador de carpetas de
## Windows XP es Fase 5. Esto es lo mínimo para que el mapa se pueda JUGAR: ver
## las ramas, ver qué hay en cada una, elegir y que la vida que traes se vea.
##
## Se enseña un acto cada vez, no el run entero. Quince filas en 540 px salen a
## 36 px por fila y no se lee nada; cinco salen a 100 y se lee todo. Y además el
## acto es la unidad que importa al decidir: lo que hay dos actos más allá no
## cambia lo que eliges ahora.

const C_FONDO      := Paleta.MAPA_FONDO
const C_CABINA     := Paleta.CABINA
const C_RAMA       := Paleta.MAPA_RAMA
const C_RAMA_VIVA  := Paleta.MAPA_RAMA_VIVA
const C_HECHO      := Paleta.NODO_HECHO
const C_TEXTO      := Paleta.TEXTO
const C_TEXTO_TENUE := Paleta.TEXTO_TENUE
const C_ORO_CLARO  := Paleta.ORO_CLARO
const C_VERDE      := Paleta.VERDE
const C_GOMA_LUZ   := Paleta.GOMA_LUZ

const RADIO := 20.0
const MARGEN_ARRIBA := 96.0
## Deja sitio abajo para la ficha del nodo marcado.
const MARGEN_ABAJO := 150.0

## Lado del retrato dentro de un nodo del mapa, y dentro de la ficha. Los
## sprites son de 96 (128 los jefes), así que 24 y 96 son divisiones ENTERAS:
## cualquier otro tamaño escala en fracciones y el pixelart hierve.
const RETRATO_NODO := 24.0
const RETRATO_FICHA := 96.0
const ALTO_FICHA := 118.0

static func color_de(tipo: int) -> Color:
	match tipo:
		NodoMapa.Tipo.ELITE: return Paleta.NODO_ELITE
		NodoMapa.Tipo.DESCANSO: return Paleta.NODO_DESCANSO
		NodoMapa.Tipo.JEFE: return Paleta.NODO_JEFE
	return Paleta.NODO_COMBATE

## Una letra por tipo. Con nodos de 11 px de radio no cabe la palabra, y el
## color solo no basta: hay que poder distinguirlos sin depender del color.
static func letra_de(tipo: int) -> String:
	match tipo:
		NodoMapa.Tipo.ELITE: return "E"
		NodoMapa.Tipo.DESCANSO: return "D"
		NodoMapa.Tipo.JEFE: return "J"
	return "C"

var run: Run
var _p: ParametrosCamara
var _fuente: Font
var _lienzo: Node2D
## Cuál de las opciones está marcada. Índice dentro de `run.opciones()`.
var seleccion: int = 0
## Texturas de enemigo por ruta. El mapa se redibuja cada fotograma, así que
## cargar aquí sería cargar sesenta veces por segundo.
var _texturas: Dictionary = {}

## El retrato del enemigo de un nodo, o null si no tiene. Un nodo sin sprite no
## es un error: el descanso no tiene enemigo.
func _retrato(nodo: NodoMapa) -> Texture2D:
	if nodo == null or nodo.enemigo.is_empty():
		return null
	var ruta := str(nodo.enemigo.get("sprite", ""))
	if ruta == "":
		return null
	if not _texturas.has(ruta):
		_texturas[ruta] = load(ruta) as Texture2D if ResourceLoader.exists(ruta) else null
	return _texturas[ruta] as Texture2D

## Dibuja un retrato encajado en un cuadrado de `lado`, centrado en `centro`.
## El lado tiene que dividir al tamaño del sprite: ver RETRATO_NODO.
func _dibujar_retrato(tex: Texture2D, centro: Vector2, lado: float) -> void:
	if tex == null:
		return
	var esquina := Vector2(round(centro.x - lado * 0.5), round(centro.y - lado * 0.5))
	_lienzo.draw_texture_rect(tex, Rect2(esquina, Vector2(lado, lado)), false)

func _init(el_run: Run, parametros: ParametrosCamara) -> void:
	run = el_run
	_p = parametros
	layer = 20

func _ready() -> void:
	_fuente = ThemeDB.fallback_font
	_lienzo = Node2D.new()
	# Sin esto los retratos salen suavizados al escalarlos y desentonan con
	# todo lo demás, que es pixelart.
	_lienzo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_lienzo.draw.connect(_dibujar)
	add_child(_lienzo)

func _process(_delta: float) -> void:
	_lienzo.queue_redraw()

## El acto que se está enseñando: el del nodo en el que estás, o el del que
## viene si aún no has entrado en ninguno.
func acto_visible() -> int:
	return run.mapa.acto_de_fila(maxi(run.fila, 0))

## Filas del acto visible, de la primera a la del jefe.
func _filas_del_acto() -> Array[int]:
	var por_acto := run.p.filas_por_acto + 1
	var desde := acto_visible() * por_acto
	var lista: Array[int] = []
	for i in por_acto:
		if desde + i < run.mapa.alto():
			lista.append(desde + i)
	return lista

func mover(paso: int) -> void:
	var n := run.opciones().size()
	if n <= 0:
		return
	seleccion = posmod(seleccion + paso, n)

## Entra en el nodo marcado. Devuelve el nodo, o null si no había nada que
## elegir. Quien lo llama decide qué hacer con él.
func confirmar() -> NodoMapa:
	var opciones := run.opciones()
	if opciones.is_empty():
		return null
	var elegido := run.elegir(opciones[clampi(seleccion, 0, opciones.size() - 1)])
	seleccion = 0
	return elegido

# ------------------------------------------------------------------- dibujo

## De abajo arriba: la fila 0 abajo y el jefe arriba, como se lee un camino que
## se sube. La bola sube por la mesa y el run sube por el mapa.
func _posicion(fila_i: int, columna: int, filas: Array[int]) -> Vector2:
	var indice := filas.find(fila_i)
	var alto := _p.alto_visible - MARGEN_ARRIBA - MARGEN_ABAJO
	var paso := alto / float(maxi(filas.size() - 1, 1))
	var y := _p.alto_visible - MARGEN_ABAJO - paso * float(indice)
	var ancho_fila: int = (run.mapa.fila(fila_i) as Array).size()
	var util := _p.ancho_visible * 0.62
	var x := _p.ancho_visible * 0.5
	if ancho_fila > 1:
		x += (float(columna) / float(ancho_fila - 1) - 0.5) * util
	return Vector2(round(x), round(y))

func _dibujar() -> void:
	_lienzo.draw_rect(Rect2(0, 0, _p.ancho_visible, _p.alto_visible), C_FONDO)
	var filas := _filas_del_acto()
	var opciones := run.opciones()
	_dibujar_ramas(filas, opciones)
	_dibujar_nodos(filas, opciones)
	_dibujar_cabecera()
	_dibujar_ficha(opciones)
	_dibujar_pie(opciones)
	if run.terminada():
		_dibujar_final()

## El final del run. Lo importante aquí no es el cartel: es el "has llegado
## hasta el nodo N", porque el criterio de salida de la fase es que pierdas y
## quieras volver a intentarlo, y para eso hay que ver hasta dónde llegaste.
func _dibujar_final() -> void:
	var y := _p.alto_visible * 0.5
	_lienzo.draw_rect(Rect2(0, y - 46, _p.ancho_visible, 92), Color(C_CABINA, 0.92))
	_lienzo.draw_string(_fuente, Vector2(0, y - 8),
		"RUN GANADO" if run.victoria else "RUN PERDIDO",
		HORIZONTAL_ALIGNMENT_CENTER, _p.ancho_visible, 22,
		C_VERDE if run.victoria else C_GOMA_LUZ)
	_lienzo.draw_string(_fuente, Vector2(0, y + 16),
		"acto %d  ·  %d nodos superados" % [acto_visible() + 1, run.nodos_superados],
		HORIZONTAL_ALIGNMENT_CENTER, _p.ancho_visible, 11, C_TEXTO)
	_lienzo.draw_string(_fuente, Vector2(0, y + 34), "R para otro run",
		HORIZONTAL_ALIGNMENT_CENTER, _p.ancho_visible, 10, C_TEXTO_TENUE)

func _dibujar_ramas(filas: Array[int], opciones: Array[int]) -> void:
	for fila_i in filas:
		if fila_i >= run.mapa.alto() - 1:
			continue
		if not filas.has(fila_i + 1):
			continue
		for n in run.mapa.fila(fila_i):
			var nodo := n as NodoMapa
			var desde := _posicion(fila_i, nodo.columna, filas)
			for c in nodo.salidas:
				var hasta := _posicion(fila_i + 1, c, filas)
				# Viva solo la rama que sale de donde estás Y lleva a una opción:
				# es lo que hace que se vea de un vistazo qué puedes elegir.
				var viva := fila_i == run.fila and nodo.columna == run.columna \
					and opciones.has(c)
				_lienzo.draw_line(desde, hasta,
					C_RAMA_VIVA if viva else C_RAMA, 3.0 if viva else 2.0)

func _dibujar_nodos(filas: Array[int], opciones: Array[int]) -> void:
	var elegible := run.fila + 1
	for fila_i in filas:
		for n in run.mapa.fila(fila_i):
			var nodo := n as NodoMapa
			var centro := _posicion(fila_i, nodo.columna, filas)
			var pasado := fila_i < run.fila \
				or (fila_i == run.fila and nodo.columna != run.columna)
			var aqui := fila_i == run.fila and nodo.columna == run.columna
			var abierto := fila_i == elegible and opciones.has(nodo.columna)
			var col := C_HECHO if pasado else color_de(nodo.tipo)

			_lienzo.draw_circle(centro, RADIO, Color(C_CABINA, 0.85))
			if aqui or abierto:
				_lienzo.draw_circle(centro, RADIO - 3.0, Color(col, 0.35))

			# El retrato manda: se reconoce a la Gárgola de un vistazo mucho
			# antes de leer "Gárgola". La letra se queda como respaldo para el
			# descanso, que no tiene enemigo, y para un sprite que falte.
			var tex := _retrato(nodo)
			if tex != null and not pasado:
				_dibujar_retrato(tex, centro, RETRATO_NODO)
			else:
				_lienzo.draw_string(_fuente, centro + Vector2(-4, 4),
					letra_de(nodo.tipo), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
			# El anillo va DESPUÉS del retrato: es el que dice el tipo, y con el
			# sprite encima se perdía justo en los nodos que más importan.
			_lienzo.draw_circle(centro, RADIO, col, false, 2.0)

			# El marcador de lo que vas a elegir: un anillo por fuera. Sin esto
			# no se sabe cuál de las ramas abiertas está marcada.
			var marcada := abierto and not opciones.is_empty() \
				and opciones[clampi(seleccion, 0, opciones.size() - 1)] == nodo.columna
			if marcada:
				_lienzo.draw_circle(centro, RADIO + 5.0, C_ORO_CLARO, false, 2.0)
			if aqui:
				_lienzo.draw_circle(centro, RADIO + 5.0, C_TEXTO, false, 1.0)

			# AQUÍ IBA el "nombre + N pv" pegado a cada nodo. La información
			# estaba y era correcta, pero escrita a 9 px al lado de TODOS los
			# nodos a la vez, así que se leía como ruido: Daniel jugó un run
			# entero sin usarla y pidió "saber qué enemigo hay". No faltaba
			# dato, faltaba jerarquía. Ahora sale grande abajo, y SOLO del
			# nodo marcado.

## El nodo que tienes marcado ahora mismo, o null si no hay nada que elegir.
func nodo_marcado(opciones: Array[int]) -> NodoMapa:
	if opciones.is_empty():
		return null
	var siguiente := run.fila + 1
	if siguiente >= run.mapa.alto():
		return null
	return run.mapa.nodo(siguiente, opciones[clampi(seleccion, 0, opciones.size() - 1)])

## La ficha del nodo marcado: retrato grande, nombre, tipo y números.
##
## Existe porque el mapa TENÍA todos estos datos repartidos en textitos de 9 px
## por toda la pantalla y no se leía ninguno. Un dato por nodo multiplicado por
## doce nodos no informa, satura. Aquí sale uno solo, el que estás a punto de
## elegir, y del tamaño que merece la única decisión de la pantalla.
##
## NO hay línea de recompensa a propósito: hasta la Fase 4 ganar un combate no
## da nada, y una fila vacía o un "próximamente" sería prometer lo que no hay.
## Cuando existan chatarra y reliquias, la fila entra debajo de los números.
func _dibujar_ficha(opciones: Array[int]) -> void:
	var base := _p.alto_visible - ALTO_FICHA
	_lienzo.draw_rect(Rect2(0, base, _p.ancho_visible, ALTO_FICHA),
		Color(C_CABINA, 0.94))
	var nodo := nodo_marcado(opciones)
	if nodo == null:
		return

	var col := color_de(nodo.tipo)
	# Una línea del color del tipo cruzando la ficha: ata el nodo de arriba con
	# su ficha sin tener que leer nada.
	_lienzo.draw_rect(Rect2(0, base, _p.ancho_visible, 2.0), col)

	var centro_retrato := Vector2(24 + RETRATO_FICHA * 0.5, base + 10 + RETRATO_FICHA * 0.5)
	var tex := _retrato(nodo)
	if tex != null:
		_dibujar_retrato(tex, centro_retrato, RETRATO_FICHA)
	else:
		_lienzo.draw_string(_fuente, centro_retrato + Vector2(-14, 16),
			letra_de(nodo.tipo), HORIZONTAL_ALIGNMENT_LEFT, -1, 44, col)

	var x := 24.0 + RETRATO_FICHA + 24.0
	_lienzo.draw_string(_fuente, Vector2(x, base + 34),
		NodoMapa.nombre_de(nodo.tipo), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)

	if nodo.es_combate() and not nodo.enemigo.is_empty():
		_lienzo.draw_string(_fuente, Vector2(x, base + 64),
			str(nodo.enemigo.get("nombre", "?")),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, C_TEXTO)
		# Vida y ataque juntos: son las dos cifras que deciden si esta rama te
		# la puedes permitir con la vida que traes.
		_lienzo.draw_string(_fuente, Vector2(x, base + 92),
			"%d pv  ·  pega %d por golpe de reloj" % [
				int(nodo.enemigo.get("vida", 0)),
				int(nodo.enemigo.get("ataque", 0))],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_ORO_CLARO)
	elif nodo.tipo == NodoMapa.Tipo.DESCANSO:
		var cura := int(round(float(run.vida_maxima) * run.p.curacion_descanso))
		_lienzo.draw_string(_fuente, Vector2(x, base + 64), "Descanso",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, C_TEXTO)
		_lienzo.draw_string(_fuente, Vector2(x, base + 92),
			"recuperas %d pv  ·  te quedarías en %d/%d" % [
				cura, mini(run.vida + cura, run.vida_maxima), run.vida_maxima],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_VERDE)

	# Cuántas ramas hay, para que se vea que esto es UNA de varias.
	if opciones.size() > 1:
		_lienzo.draw_string(_fuente, Vector2(0, base + 34),
			"rama %d de %d" % [
				clampi(seleccion, 0, opciones.size() - 1) + 1, opciones.size()],
			HORIZONTAL_ALIGNMENT_RIGHT, _p.ancho_visible - 24, 11, C_TEXTO_TENUE)

func _dibujar_cabecera() -> void:
	_lienzo.draw_rect(Rect2(0, 0, _p.ancho_visible, 62), Color(C_CABINA, 0.9))
	_lienzo.draw_string(_fuente, Vector2(24, 26),
		"ACTO %d de %d" % [acto_visible() + 1, run.p.actos],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_TEXTO)
	_lienzo.draw_string(_fuente, Vector2(24, 46),
		"%d nodos superados" % run.nodos_superados,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, C_TEXTO_TENUE)

	# La vida, que es LA información del mapa: no se cura entre combates, así
	# que es lo que decide por qué rama te la juegas.
	var proporcion := float(run.vida) / float(maxi(run.vida_maxima, 1))
	var col := C_VERDE if proporcion > 0.35 else C_GOMA_LUZ
	_lienzo.draw_string(_fuente, Vector2(_p.ancho_visible - 320, 26),
		"VIDA %d/%d" % [run.vida, run.vida_maxima],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
	_lienzo.draw_rect(Rect2(_p.ancho_visible - 190, 14, 166, 10), C_CABINA)
	_lienzo.draw_rect(Rect2(_p.ancho_visible - 190, 14, 166.0 * proporcion, 10), col)
	_lienzo.draw_string(_fuente, Vector2(_p.ancho_visible - 190, 46),
		"no se cura entre combates", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, C_TEXTO_TENUE)

func _dibujar_pie(opciones: Array[int]) -> void:
	var texto := "IZQUIERDA/DERECHA elegir rama  ·  ENTER entrar  ·  R reiniciar el run"
	if opciones.is_empty():
		texto = "R para empezar otro run"
	# Justo ENCIMA de la ficha, no al borde de la pantalla: abajo ya no hay
	# sitio libre, ahí está el retrato.
	_lienzo.draw_string(_fuente, Vector2(24, _p.alto_visible - ALTO_FICHA - 10),
		texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, C_TEXTO_TENUE)
