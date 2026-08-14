class_name NodoPantallaMapa
extends CanvasLayer

## EL MAPA DEL RUN, COMO UN EXPLORADOR DE CARPETAS.
##
## Era la última pieza que le quedaba a la Fase 5. Antes era una pantalla suelta
## con un fondo plano: se jugaba bien, pero era lo único del juego que no
## pertenecía al sistema operativo falso, y la fase entera se juzga por si la
## broma se entiende de un vistazo.
##
## Ahora es una ventana maximizada de explorador: barra de título con la ruta,
## barra de menú, barra de herramientas con la dirección, panel de tareas a la
## izquierda y barra de estado abajo. **Los nodos son archivos**: icono grande
## con el nombre debajo, y el marcado sale resaltado en azul, como en una carpeta
## de verdad. Las ramas se siguen dibujando como líneas, porque un explorador no
## sabe enseñar un grafo y el grafo es lo que hay que poder leer.
##
## VA MAXIMIZADA, ocupando la pantalla entera, y no es pereza: la mesa se sigue
## dibujando por debajo (capa 0) mientras el mapa está delante (capa 20), así que
## una ventana con márgenes dejaría ver el tablero alrededor en vez del
## escritorio, que está aún más atrás.
##
## Se enseña un acto cada vez, no el run entero: quince filas en 540 px salen a
## 36 px por fila y no se lee nada. Y además el acto es la unidad que importa al
## decidir: lo que hay dos actos más allá no cambia lo que eliges ahora.

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
const C_BLANCO     := Paleta.DESTELLO
## El azul de selección del explorador. Es el mismo azul de los carriles: no hace
## falta un color nuevo y así la paleta sigue cerrada.
const C_SELECCION  := Paleta.CARRIL

## El mueble de la ventana. Todo en múltiplos de 8, que es la unidad de los
## marcos: cualquier otro número deja el último trozo cortado.
const GROSOR := 8.0
const ALTO_TITULO := 16.0
const ALTO_MENU := 16.0
const ALTO_HERRAMIENTAS := 24.0
const ALTO_ESTADO := 24.0
const ANCHO_TAREAS := 228.0

const MARGEN_ARRIBA := 40.0
const MARGEN_ABAJO := 56.0

## Lado del retrato dentro de un nodo y dentro del panel de detalles. Los sprites
## son de 96 (128 los jefes), así que 32 y 96 son divisiones ENTERAS: cualquier
## otro tamaño escala en fracciones y el pixelart hierve.
const RETRATO_NODO := 32.0
const RETRATO_FICHA := 96.0

static func color_de(tipo: int) -> Color:
	match tipo:
		NodoMapa.Tipo.ELITE: return Paleta.NODO_ELITE
		NodoMapa.Tipo.DESCANSO: return Paleta.NODO_DESCANSO
		NodoMapa.Tipo.JEFE: return Paleta.NODO_JEFE
	return Paleta.NODO_COMBATE

## Una letra por tipo. Con un icono de 32 px no cabe la palabra, y el color solo
## no basta: hay que poder distinguirlos sin depender del color.
static func letra_de(tipo: int) -> String:
	match tipo:
		NodoMapa.Tipo.ELITE: return "E"
		NodoMapa.Tipo.DESCANSO: return "D"
		NodoMapa.Tipo.JEFE: return "J"
	return "C"

## La extensión de archivo de cada tipo. Es el chiste y a la vez informa: un
## `.exe` es un combate, un `.sys` es un jefe y un `.tmp` es un descanso.
static func extension_de(tipo: int) -> String:
	match tipo:
		NodoMapa.Tipo.ELITE: return ".dll"
		NodoMapa.Tipo.DESCANSO: return ".tmp"
		NodoMapa.Tipo.JEFE: return ".sys"
	return ".exe"

var run: Run
var _p: ParametrosCamara
var _fuente: Font
var _lienzo: Node2D
## Cuál de las opciones está marcada. Índice dentro de `run.opciones()`.
var seleccion: int = 0
## Texturas de enemigo por ruta. El mapa se redibuja cada fotograma, así que
## cargar aquí sería cargar sesenta veces por segundo.
var _texturas: Dictionary = {}
var _ventana: NueveTrozos
var _titulo: NueveTrozos
var _barra: NueveTrozos
var _boton: NueveTrozos
var _dialogo: NueveTrozos

func _init(el_run: Run, parametros: ParametrosCamara) -> void:
	run = el_run
	_p = parametros
	layer = 20

func _ready() -> void:
	_fuente = FuenteUI.obtener()
	_ventana = NueveTrozos.cargar("res://assets/ui/ventana")
	_titulo = NueveTrozos.cargar("res://assets/ui/titulo")
	_barra = NueveTrozos.cargar("res://assets/ui/barra")
	_boton = NueveTrozos.cargar("res://assets/ui/boton")
	_dialogo = NueveTrozos.cargar("res://assets/ui/dialogo")
	_lienzo = Node2D.new()
	# Sin esto los retratos salen suavizados al escalarlos y desentonan con
	# todo lo demás, que es pixelart.
	_lienzo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Y sin esto los marcos de nueve trozos saldrían estirados en vez de
	# repetidos, que es lo único que un marco de nueve trozos no puede hacer.
	_lienzo.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_lienzo.draw.connect(_dibujar)
	add_child(_lienzo)

func _process(_delta: float) -> void:
	_lienzo.queue_redraw()

# --------------------------------------------------------------- la selección

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

## El nodo que tienes marcado ahora mismo, o null si no hay nada que elegir.
func nodo_marcado(opciones: Array[int]) -> NodoMapa:
	if opciones.is_empty():
		return null
	var siguiente := run.fila + 1
	if siguiente >= run.mapa.alto():
		return null
	return run.mapa.nodo(siguiente, opciones[clampi(seleccion, 0, opciones.size() - 1)])

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

# ------------------------------------------------------------------- el mueble

func _ventana_entera() -> Rect2:
	return Rect2(0.0, 0.0, _p.ancho_visible, _p.alto_visible)

## El hueco de contenido: por debajo del título, del menú y de la barra de
## herramientas, y por encima de la barra de estado.
func _hueco_contenido() -> Rect2:
	var v := _ventana_entera()
	var arriba := GROSOR + ALTO_TITULO + ALTO_MENU + ALTO_HERRAMIENTAS
	return Rect2(v.position.x + GROSOR, arriba,
		v.size.x - GROSOR * 2.0,
		v.size.y - arriba - ALTO_ESTADO - GROSOR)

## El panel de tareas de la izquierda, que es de donde XP sacaba el "detalles".
func _hueco_tareas() -> Rect2:
	var c := _hueco_contenido()
	return Rect2(c.position, Vector2(ANCHO_TAREAS, c.size.y))

## Y la carpeta en sí, que es donde están los nodos.
func _hueco_carpeta() -> Rect2:
	var c := _hueco_contenido()
	return Rect2(c.position.x + ANCHO_TAREAS, c.position.y,
		maxf(c.size.x - ANCHO_TAREAS, 0.0), c.size.y)

## La ruta que se enseña arriba. Es la premisa contada por una barra de
## direcciones: el run es una carpeta y cada combate es un archivo dentro.
func _ruta() -> String:
	return "C:\\cascabel\\actos\\acto_%d" % (acto_visible() + 1)

# ------------------------------------------------------------------- dibujo

## De abajo arriba: la fila 0 abajo y el jefe arriba, como se lee un camino que
## se sube. La bola sube por la mesa y el run sube por el mapa.
func _posicion(fila_i: int, columna: int, filas: Array[int]) -> Vector2:
	var carpeta := _hueco_carpeta()
	var indice := filas.find(fila_i)
	var alto := carpeta.size.y - MARGEN_ARRIBA - MARGEN_ABAJO
	var paso := alto / float(maxi(filas.size() - 1, 1))
	var y := carpeta.end.y - MARGEN_ABAJO - paso * float(indice)
	var ancho_fila: int = (run.mapa.fila(fila_i) as Array).size()
	var util := carpeta.size.x * 0.68
	var x := carpeta.position.x + carpeta.size.x * 0.5
	if ancho_fila > 1:
		x += (float(columna) / float(ancho_fila - 1) - 0.5) * util
	return Vector2(round(x), round(y))

func _dibujar() -> void:
	var v := _ventana_entera()
	# Fondo opaco antes de nada: por debajo está la mesa, y una ventana
	# translúcida enseñaría el tablero en vez del escritorio.
	_lienzo.draw_rect(v, C_CABINA)
	if _ventana.completo():
		_ventana.dibujar(_lienzo, v)
	_dibujar_titulo(v)
	_dibujar_menu(v)
	_dibujar_herramientas(v)

	# El fondo de la carpeta, más claro que el mueble: es "papel", como el fondo
	# blanco de una carpeta de verdad, pero en la temperatura de la mazmorra.
	var carpeta := _hueco_carpeta()
	_lienzo.draw_rect(carpeta, C_FONDO)

	var filas := _filas_del_acto()
	var opciones := run.opciones()
	_dibujar_ramas(filas, opciones)
	_dibujar_nodos(filas, opciones)
	_dibujar_tareas(opciones)
	_dibujar_estado(opciones)
	if run.terminada():
		_dibujar_final()

func _dibujar_titulo(v: Rect2) -> void:
	var barra := Rect2(v.position.x + GROSOR, v.position.y + GROSOR,
		v.size.x - GROSOR * 2.0, ALTO_TITULO)
	if _titulo.completo():
		_titulo.dibujar(_lienzo, barra)
	_lienzo.draw_string(_fuente, Vector2(barra.position.x + 6.0,
		barra.position.y + 12.0), _ruta(),
		HORIZONTAL_ALIGNMENT_LEFT, barra.size.x - 60.0, 8, C_BLANCO)

## La barra de menú. No hace nada y no tiene que hacerlo: es el marco de la
## broma, igual que los tres botones de la ventana de la mesa.
func _dibujar_menu(v: Rect2) -> void:
	var barra := Rect2(v.position.x + GROSOR, v.position.y + GROSOR + ALTO_TITULO,
		v.size.x - GROSOR * 2.0, ALTO_MENU)
	var x := barra.position.x + 8.0
	for palabra in ["Archivo", "Edición", "Ver", "Favoritos", "Ayuda"]:
		_lienzo.draw_string(_fuente, Vector2(x, barra.position.y + 12.0),
			str(palabra), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, C_TEXTO_TENUE)
		x += float(str(palabra).length()) * 6.0 + 14.0

## La barra de herramientas, con su barra de direcciones. Aquí sí hay una cosa
## que informa de verdad: en qué acto estás.
func _dibujar_herramientas(v: Rect2) -> void:
	var y := v.position.y + GROSOR + ALTO_TITULO + ALTO_MENU
	var barra := Rect2(v.position.x + GROSOR, y, v.size.x - GROSOR * 2.0,
		ALTO_HERRAMIENTAS)
	if _barra.completo():
		_barra.dibujar(_lienzo, barra)

	var x := barra.position.x + 6.0
	for palabra in ["Atrás", "Arriba"]:
		var caja := Rect2(x, barra.position.y + 4.0,
			float(str(palabra).length()) * 6.0 + 14.0, ALTO_HERRAMIENTAS - 8.0)
		if _boton.completo():
			_boton.dibujar(_lienzo, caja)
		_lienzo.draw_string(_fuente, Vector2(caja.position.x + 7.0,
			caja.position.y + 12.0), str(palabra),
			HORIZONTAL_ALIGNMENT_LEFT, caja.size.x - 10.0, 8, C_CABINA)
		x = caja.end.x + 6.0

	# La barra de direcciones, hundida como las de verdad.
	var direccion := Rect2(x + 34.0, barra.position.y + 4.0,
		barra.end.x - x - 40.0, ALTO_HERRAMIENTAS - 8.0)
	_lienzo.draw_string(_fuente, Vector2(x + 2.0, barra.position.y + 16.0),
		"Dirección", HORIZONTAL_ALIGNMENT_LEFT, 32.0, 8, C_CABINA)
	_lienzo.draw_rect(direccion, C_CABINA)
	_lienzo.draw_rect(direccion, Color(C_TEXTO_TENUE, 0.7), false, 1.0)
	_lienzo.draw_string(_fuente, Vector2(direccion.position.x + 6.0,
		direccion.position.y + 11.0), _ruta() + "\\",
		HORIZONTAL_ALIGNMENT_LEFT, direccion.size.x - 12.0, 8, C_TEXTO)

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

## LOS NODOS, COMO ARCHIVOS. Icono arriba, nombre debajo, y el marcado con el
## rectángulo azul de selección detrás del nombre, que es como se ve un archivo
## elegido en una carpeta. El anillo del color del tipo se queda porque el color
## es lo que distingue un élite de un combate normal sin tener que leer.
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
			var marcada := abierto and not opciones.is_empty() \
				and opciones[clampi(seleccion, 0, opciones.size() - 1)] == nodo.columna

			var nombre := _nombre_de_archivo(nodo)
			var ancho_texto := float(nombre.length()) * 6.0 + 8.0
			var caja_texto := Rect2(roundf(centro.x - ancho_texto * 0.5),
				roundf(centro.y + RETRATO_NODO * 0.5 + 4.0), ancho_texto, 12.0)

			# El icono. Un cuadro oscuro debajo para que el sprite no se pierda
			# sobre el fondo de la carpeta.
			var caja_icono := Rect2(
				roundf(centro.x - RETRATO_NODO * 0.5),
				roundf(centro.y - RETRATO_NODO * 0.5),
				RETRATO_NODO, RETRATO_NODO)
			_lienzo.draw_rect(caja_icono.grow(2.0), Color(C_CABINA, 0.6))
			var tex := _retrato(nodo)
			if tex != null:
				_dibujar_retrato(tex, centro, RETRATO_NODO)
				if pasado:
					# Los ya hechos van apagados, no borrados: el camino
					# recorrido tiene que verse.
					_lienzo.draw_rect(caja_icono, Color(C_CABINA, 0.6))
			else:
				_lienzo.draw_string(_fuente, centro + Vector2(-4, 6),
					letra_de(nodo.tipo), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
			_lienzo.draw_rect(caja_icono.grow(2.0), col, false, 1.0)

			# El nombre, con la selección azul detrás si es el que vas a abrir.
			if marcada:
				_lienzo.draw_rect(caja_texto, C_SELECCION)
				_lienzo.draw_rect(caja_texto, C_ORO_CLARO, false, 1.0)
			_lienzo.draw_string(_fuente,
				Vector2(caja_texto.position.x, caja_texto.position.y + 9.0),
				nombre, HORIZONTAL_ALIGNMENT_CENTER, caja_texto.size.x, 8,
				C_BLANCO if marcada else (C_TEXTO_TENUE if pasado else C_TEXTO))
			# Dónde estás ahora: el archivo "abierto".
			if aqui:
				_lienzo.draw_rect(caja_icono.grow(4.0), C_BLANCO, false, 1.0)

## El nombre de archivo de un nodo. Corto a propósito: en una carpeta los nombres
## se leen en fila, y uno largo empuja a los de al lado.
func _nombre_de_archivo(nodo: NodoMapa) -> String:
	if nodo.tipo == NodoMapa.Tipo.DESCANSO:
		return "descanso" + extension_de(nodo.tipo)
	var nombre := str(nodo.enemigo.get("nombre", "?"))
	return nombre.to_lower().replace(" ", "_") + extension_de(nodo.tipo)

## EL PANEL DE TAREAS de la izquierda. Es el sitio de XP donde salía "Detalles"
## del archivo elegido, y aquí cumple exactamente esa función: la ficha del nodo
## que vas a abrir, con el retrato grande y los números que deciden si esa rama
## te la puedes permitir con la vida que traes.
##
## La ficha existe porque el mapa TENÍA todos estos datos repartidos en textitos
## de 8 px al lado de cada nodo y no se leía ninguno. Un dato por nodo
## multiplicado por doce nodos no informa, satura.
func _dibujar_tareas(opciones: Array[int]) -> void:
	var caja := _hueco_tareas()
	_lienzo.draw_rect(caja, Color(C_CABINA, 0.85))
	_lienzo.draw_rect(Rect2(caja.end.x - 1.0, caja.position.y, 1.0, caja.size.y),
		Color(C_TEXTO_TENUE, 0.5))
	var x := caja.position.x + 12.0
	var ancho := caja.size.x - 24.0

	# LA VIDA, que es LA información del mapa: no se cura entre combates, así
	# que es lo que decide por qué rama te la juegas.
	var y := caja.position.y + 20.0
	_lienzo.draw_string(_fuente, Vector2(x, y), "Estado del sistema",
		HORIZONTAL_ALIGNMENT_LEFT, ancho, 8, C_ORO_CLARO)
	var proporcion := float(run.vida) / float(maxi(run.vida_maxima, 1))
	var col := C_VERDE if proporcion > 0.35 else C_GOMA_LUZ
	_lienzo.draw_string(_fuente, Vector2(x, y + 22.0),
		"VIDA %d/%d" % [run.vida, run.vida_maxima],
		HORIZONTAL_ALIGNMENT_LEFT, ancho, 16, col)
	_lienzo.draw_rect(Rect2(x, y + 30.0, ancho, 10.0), C_CABINA)
	_lienzo.draw_rect(Rect2(x, y + 30.0, ancho * proporcion, 10.0), col)
	_lienzo.draw_string(_fuente, Vector2(x, y + 54.0),
		"no se cura entre combates", HORIZONTAL_ALIGNMENT_LEFT, ancho, 8,
		C_TEXTO_TENUE)
	_lienzo.draw_string(_fuente, Vector2(x, y + 70.0),
		"acto %d de %d  ·  %d nodos superados" % [
			acto_visible() + 1, run.p.actos, run.nodos_superados],
		HORIZONTAL_ALIGNMENT_LEFT, ancho, 8, C_TEXTO_TENUE)

	# DETALLES del archivo marcado.
	var nodo := nodo_marcado(opciones)
	y += 100.0
	_lienzo.draw_string(_fuente, Vector2(x, y), "Detalles",
		HORIZONTAL_ALIGNMENT_LEFT, ancho, 8, C_ORO_CLARO)
	if nodo == null:
		_lienzo.draw_string(_fuente, Vector2(x, y + 22.0),
			"ningún elemento seleccionado",
			HORIZONTAL_ALIGNMENT_LEFT, ancho, 8, C_TEXTO_TENUE)
		return

	var col_tipo := color_de(nodo.tipo)
	var centro_retrato := Vector2(caja.position.x + caja.size.x * 0.5,
		y + 18.0 + RETRATO_FICHA * 0.5)
	var tex := _retrato(nodo)
	if tex != null:
		_dibujar_retrato(tex, centro_retrato, RETRATO_FICHA)
	else:
		_lienzo.draw_string(_fuente, centro_retrato + Vector2(-14, 16),
			letra_de(nodo.tipo), HORIZONTAL_ALIGNMENT_LEFT, -1, 48, col_tipo)

	var yf := y + 24.0 + RETRATO_FICHA
	_lienzo.draw_string(_fuente, Vector2(x, yf), NodoMapa.nombre_de(nodo.tipo),
		HORIZONTAL_ALIGNMENT_LEFT, ancho, 8, col_tipo)
	if nodo.es_combate() and not nodo.enemigo.is_empty():
		_lienzo.draw_string(_fuente, Vector2(x, yf + 24.0),
			str(nodo.enemigo.get("nombre", "?")),
			HORIZONTAL_ALIGNMENT_LEFT, ancho, 16, C_TEXTO)
		# Vida y ataque juntos: son las dos cifras que deciden si esta rama te
		# la puedes permitir con la vida que traes.
		_lienzo.draw_string(_fuente, Vector2(x, yf + 44.0),
			"%d pv" % int(nodo.enemigo.get("vida", 0)),
			HORIZONTAL_ALIGNMENT_LEFT, ancho, 8, C_ORO_CLARO)
		_lienzo.draw_string(_fuente, Vector2(x, yf + 58.0),
			"pega %d por golpe de reloj" % int(nodo.enemigo.get("ataque", 0)),
			HORIZONTAL_ALIGNMENT_LEFT, ancho, 8, C_ORO_CLARO)
	elif nodo.tipo == NodoMapa.Tipo.DESCANSO:
		var cura := int(round(float(run.vida_maxima) * run.p.curacion_descanso))
		_lienzo.draw_string(_fuente, Vector2(x, yf + 24.0), "Descanso",
			HORIZONTAL_ALIGNMENT_LEFT, ancho, 16, C_TEXTO)
		_lienzo.draw_string(_fuente, Vector2(x, yf + 44.0),
			"recuperas %d pv" % cura, HORIZONTAL_ALIGNMENT_LEFT, ancho, 8, C_VERDE)
		_lienzo.draw_string(_fuente, Vector2(x, yf + 58.0),
			"te quedarías en %d/%d" % [mini(run.vida + cura, run.vida_maxima),
				run.vida_maxima], HORIZONTAL_ALIGNMENT_LEFT, ancho, 8, C_VERDE)

	# Lo que llevas encima. Va en el mapa porque es donde se decide la rama, y la
	# build que llevas es la mitad de esa decisión: con reliquias de aguantar
	# compensa el élite, y sin ellas no.
	if run.bolsa != null and not run.bolsa.vacia():
		_lienzo.draw_string(_fuente, Vector2(x, yf + 84.0), "Módulos cargados",
			HORIZONTAL_ALIGNMENT_LEFT, ancho, 8, C_ORO_CLARO)
		_lienzo.draw_multiline_string(_fuente, Vector2(x, yf + 100.0),
			", ".join(run.bolsa.nombres()), HORIZONTAL_ALIGNMENT_LEFT, ancho,
			8, 5, C_TEXTO_TENUE)

## LA BARRA DE ESTADO. Cuenta los "objetos" de la carpeta, como el explorador de
## verdad, y ahí es donde van las teclas: abajo del todo y siempre en el mismo
## sitio, que es donde un explorador pone lo que no urge.
func _dibujar_estado(opciones: Array[int]) -> void:
	var v := _ventana_entera()
	var caja := Rect2(v.position.x + GROSOR, v.end.y - GROSOR - ALTO_ESTADO,
		v.size.x - GROSOR * 2.0, ALTO_ESTADO)
	if _barra.completo():
		_barra.dibujar(_lienzo, caja)
	var texto := "%d objetos" % opciones.size()
	if opciones.is_empty():
		texto = "carpeta vacía"
	elif opciones.size() > 1:
		texto = "%d objetos  ·  1 seleccionado (%d de %d)" % [opciones.size(),
			clampi(seleccion, 0, opciones.size() - 1) + 1, opciones.size()]
	_lienzo.draw_string(_fuente, Vector2(caja.position.x + 8.0,
		caja.position.y + 15.0), texto, HORIZONTAL_ALIGNMENT_LEFT,
		caja.size.x * 0.5, 8, C_CABINA)
	var teclas := "IZQUIERDA/DERECHA elegir  ·  ENTER abrir  ·  R reiniciar"
	if opciones.is_empty():
		teclas = "R para empezar otro run"
	_lienzo.draw_string(_fuente, Vector2(caja.position.x,
		caja.position.y + 15.0), teclas, HORIZONTAL_ALIGNMENT_RIGHT,
		caja.size.x - 8.0, 8, C_CABINA)

## El final del run, como un cuadro de diálogo de Windows. Lo importante aquí no
## es el cartel: es el "has llegado hasta el nodo N", porque el criterio de
## salida de la Fase 3C era que pierdas y quieras volver a intentarlo, y para eso
## hay que ver hasta dónde llegaste.
func _dibujar_final() -> void:
	var v := _ventana_entera()
	_lienzo.draw_rect(v, Color(C_CABINA, 0.6))
	var ancho := 460.0
	var alto := 172.0
	var caja := Rect2(roundf((v.size.x - ancho) * 0.5),
		roundf((v.size.y - alto) * 0.5), ancho, alto)
	var dentro := caja.grow(-8.0)
	if _dialogo.completo():
		_dialogo.dibujar(_lienzo, caja)
		dentro = _dialogo.interior(caja)
	else:
		_lienzo.draw_rect(caja, Paleta.PERGAMINO)
	# Dentro de un diálogo se escribe en NEGRO: el relleno es el gris claro de
	# Windows y el blanco del resto de la interfaz ahí no se lee.
	var x := dentro.position.x
	var w := dentro.size.x
	_lienzo.draw_string(_fuente, Vector2(x, dentro.position.y + 30.0),
		"RUN GANADO" if run.victoria else "RUN PERDIDO",
		HORIZONTAL_ALIGNMENT_CENTER, w, 24, C_CABINA)
	_lienzo.draw_string(_fuente, Vector2(x, dentro.position.y + 58.0),
		"acto %d  ·  %d nodos superados" % [acto_visible() + 1, run.nodos_superados],
		HORIZONTAL_ALIGNMENT_CENTER, w, 8, C_CABINA)
	# LA MEDIDA DE ESTE RUN, que es lo que hace falta para escribir la tabla de
	# enemigos exacta. Se ha calibrado dos veces contra un jugador inventado y
	# las dos salió mal; estos dos números son los del jugador de verdad.
	if run.combates_jugados > 0:
		_lienzo.draw_string(_fuente, Vector2(x, dentro.position.y + 82.0),
			"tu daño por bola: %.0f" % run.dano_por_bola(),
			HORIZONTAL_ALIGNMENT_CENTER, w, 8, C_CABINA)
		_lienzo.draw_string(_fuente, Vector2(x, dentro.position.y + 98.0),
			"combate medio: %.0f s  ·  %d bolas" % [
				run.segundos_por_combate(), run.bolas_jugadas],
			HORIZONTAL_ALIGNMENT_CENTER, w, 8, C_CABINA)
	var boton := Rect2(roundf(dentro.position.x + (w - 120.0) * 0.5),
		dentro.end.y - 28.0, 120.0, 20.0)
	if _boton.completo():
		_boton.dibujar(_lienzo, boton)
	_lienzo.draw_string(_fuente, Vector2(boton.position.x,
		boton.position.y + 14.0), "R para reintentar",
		HORIZONTAL_ALIGNMENT_CENTER, boton.size.x, 8, C_CABINA)
