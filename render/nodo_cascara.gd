class_name NodoCascara
extends CanvasLayer

## LA CÁSCARA: el sistema operativo falso dentro del que vive la mesa.
##
## Sustituye a `NodoEscritorio`, que era solo el fondo con los laterales
## apagados a mano. Aquí ya hay escritorio de verdad, barra de tareas con botón
## Inicio y reloj, un marco de nueve trozos alrededor de la mesa, y los iconos de
## reliquia con su tooltip amarillo.
##
## NO HAY GESTOR DE VENTANAS y no lo va a haber (invariante). Los paneles están
## en posiciones fijas y solo PARECEN ventanas: no se arrastran, no se
## redimensionan, no hay foco ni orden de apilado. Esa era la parte cara y no
## aporta nada; nadie va a querer mover el mapa a otra esquina.
##
## Va en dos capas porque la mesa se dibuja en medio: el escritorio y los
## paneles laterales por detrás (capa −10) y el marco de la mesa por delante
## (capa 5), tapando el borde del campo, que es lo que hace que la mesa parezca
## empotrada en una ventana en vez de pegada encima del fondo.

const C_VACIO       := Paleta.CABINA
const C_TEXTO       := Paleta.TEXTO
const C_TEXTO_TENUE := Paleta.TEXTO_TENUE
const C_ORO         := Paleta.ORO
const C_ORO_CLARO   := Paleta.ORO_CLARO
const C_VERDE       := Paleta.VERDE
const C_GOMA_LUZ    := Paleta.GOMA_LUZ
const C_ARCANO      := Paleta.ARCANO
const C_FUEGO       := Paleta.FUEGO
const C_METAL       := Paleta.METAL
const C_METAL_LUZ   := Paleta.METAL_LUZ
const C_PERGAMINO   := Paleta.PERGAMINO
const C_BLANCO      := Paleta.DESTELLO

## Alto de la barra de tareas y de la barra de título, en múltiplos de la unidad
## de 8 px de los marcos. Cualquier otro número deja el último trozo cortado.
const ALTO_BARRA := 24.0
const ALTO_TITULO := 16.0
## Lo que mide el marco de la ventana por cada lado.
const GROSOR_VENTANA := 8.0
## Lado del icono de reliquia en el escritorio. Los sprites son de 32 y se
## dibujan a 32: cualquier otro tamaño escala en fracciones y hierve.
const LADO_ICONO := 32.0
const SEPARACION_ICONO := 12.0
const MARGEN_ESCRITORIO := 14.0

var vista: VistaMesa
var _p: ParametrosCamara
var _anim: ParametrosAnimacion
## Un fondo por acto: `DISEÑO.md` §3 dice que el sistema se corrompe acto a
## acto, y hasta ahora eso no se veía en ningún sitio salvo el texto del mapa.
var _fondos_acto: Array[Texture2D] = []
## Los marcos, generados por `fuente.py`. Antes esto reusaba el marco de piedra
## de la mazmorra y se veían dos fallos a la vez: no cuadraba —recortado por
## silueta, cada pieza medía una cosa— y no parecía un sistema operativo, porque
## era piedra tallada alrededor de una ventana. Estos salen cuadrados por
## construcción: las nueve piezas miden la unidad y los lados son el mismo
## perfil reflejado.
var _ventana: NueveTrozos
var _titulo: NueveTrozos
var _barra: NueveTrozos
var _boton: NueveTrozos
var _tooltip: NueveTrozos
var _lienzo: Node2D
var _fuente: Font
var _texturas: Dictionary = {}
## Botones de la barra de título (min/max/cerrar) y el botón Inicio, con
## identidad propia: el cascabel es el logo del sistema.
var _tex_botones: Dictionary = {}
var _tex_inicio: Texture2D
var _tex_inicio_pulsado: Texture2D
## Los iconos decorativos del escritorio: llenan la banda derecha, que las
## reliquias no usan. No hacen nada, como cualquier icono de escritorio real.
const ICONOS_DECORATIVOS := ["mi_maquina", "papelera", "carpeta", "disquete",
	"registro", "disco", "error", "cascabel", "monitor"]
var _tex_iconos_decorativos: Array[Texture2D] = []
## Sobre qué icono está el ratón, para el tooltip. −1 = ninguno.
var _icono_marcado: int = -1

func _init(la_vista: VistaMesa, parametros: ParametrosCamara,
		animacion: ParametrosAnimacion) -> void:
	vista = la_vista
	_p = parametros
	_anim = animacion
	layer = -10

func _ready() -> void:
	_fuente = FuenteUI.obtener()
	_fondos_acto = [
		load("res://assets/shell/fondo_acto1.png"),
		load("res://assets/shell/fondo_acto2.png"),
		load("res://assets/shell/fondo_acto3.png"),
	]
	_ventana = NueveTrozos.cargar("res://assets/ui/ventana")
	_titulo = NueveTrozos.cargar("res://assets/ui/titulo")
	_barra = NueveTrozos.cargar("res://assets/ui/barra")
	_boton = NueveTrozos.cargar("res://assets/ui/boton")
	_tooltip = NueveTrozos.cargar("res://assets/ui/tooltip")
	for nombre in ["min", "max", "cerrar"]:
		var ruta := "res://assets/ui/botones/%s.png" % nombre
		if ResourceLoader.exists(ruta):
			_tex_botones[nombre] = load(ruta)
	if ResourceLoader.exists("res://assets/ui/inicio/inicio.png"):
		_tex_inicio = load("res://assets/ui/inicio/inicio.png")
	if ResourceLoader.exists("res://assets/ui/inicio/inicio_pulsado.png"):
		_tex_inicio_pulsado = load("res://assets/ui/inicio/inicio_pulsado.png")
	for nombre in ICONOS_DECORATIVOS:
		var ruta := "res://assets/ui/iconos/%s.png" % nombre
		_tex_iconos_decorativos.append(load(ruta) if ResourceLoader.exists(ruta) else null)
	_lienzo = Node2D.new()
	_lienzo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Sin esto los bordes del marco no se pueden repetir y saldrían estirados,
	# que es justo lo que un marco de nueve trozos existe para evitar.
	_lienzo.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_lienzo.draw.connect(_dibujar)
	add_child(_lienzo)

func _process(_delta: float) -> void:
	_lienzo.queue_redraw()

func _input(evento: InputEvent) -> void:
	var raton := evento as InputEventMouseMotion
	if raton == null:
		return
	_icono_marcado = _icono_en(raton.position)

# ------------------------------------------------------------------- huecos

func pantalla() -> Vector2:
	return _lienzo.get_viewport_rect().size.ceil()

## La franja de la mesa en pantalla: 400 px centrados.
func franja_mesa() -> Rect2:
	var p := pantalla()
	# La mesa empieza por debajo de la barra de título de su ventana y acaba por
	# encima de la barra de tareas. Los 400 px de ancho son intocables: la física
	# está ajustada a esa anchura.
	var arriba := GROSOR_VENTANA + ALTO_TITULO
	return Rect2(roundf((p.x - Mesa.ANCHO) * 0.5), arriba, Mesa.ANCHO,
		p.y - ALTO_BARRA - GROSOR_VENTANA - arriba)

## La ventana entera: la mesa más su marco y su barra de título.
func ventana_mesa() -> Rect2:
	var f := franja_mesa()
	return Rect2(f.position - Vector2(GROSOR_VENTANA, GROSOR_VENTANA + ALTO_TITULO),
		f.size + Vector2(GROSOR_VENTANA * 2.0, GROSOR_VENTANA * 2.0 + ALTO_TITULO))

## El escritorio libre de cada lado, que es donde van los iconos. Es el sitio
## que `PLAN.md` reservó desde la Fase 1: 280 px por banda.
func banda_izquierda() -> Rect2:
	var v := ventana_mesa()
	var p := pantalla()
	return Rect2(0.0, 0.0, v.position.x, p.y - ALTO_BARRA)

func banda_derecha() -> Rect2:
	var v := ventana_mesa()
	var p := pantalla()
	return Rect2(v.end.x, 0.0, p.x - v.end.x, p.y - ALTO_BARRA)

## Dónde cae el icono `i` de la bolsa. Van en columna por la banda izquierda,
## como los iconos de un escritorio de verdad.
func caja_icono(i: int) -> Rect2:
	var banda := banda_izquierda()
	var por_columna := maxi(int((banda.size.y - MARGEN_ESCRITORIO * 2.0)
		/ (LADO_ICONO + SEPARACION_ICONO + 10.0)), 1)
	var col := i / por_columna
	var fila := i % por_columna
	return Rect2(
		roundf(banda.position.x + MARGEN_ESCRITORIO
			+ float(col) * (LADO_ICONO + SEPARACION_ICONO + 46.0)),
		roundf(banda.position.y + MARGEN_ESCRITORIO
			+ float(fila) * (LADO_ICONO + SEPARACION_ICONO + 10.0)),
		LADO_ICONO, LADO_ICONO)

func _icono_en(punto: Vector2) -> int:
	if vista == null or vista.run == null or vista.run.bolsa == null:
		return -1
	for i in vista.run.bolsa.reliquias.size():
		# La caja de captura es más ancha que el icono porque debajo va el
		# nombre: si solo capturara el dibujo, habría que apuntar a 32 px.
		if caja_icono(i).grow(6.0).has_point(punto):
			return i
	return -1

# ------------------------------------------------------------------- dibujo

func _dibujar() -> void:
	var p := pantalla()
	_lienzo.draw_rect(Rect2(Vector2.ZERO, p), C_VACIO)
	_dibujar_fondo(p)
	_dibujar_iconos()
	_dibujar_iconos_decorativos()
	_dibujar_barra(p)
	_dibujar_marco_mesa()
	_dibujar_tooltip()
	if not get_viewport().size_changed.is_connected(_lienzo.queue_redraw):
		get_viewport().size_changed.connect(_lienzo.queue_redraw)

## El fondo es 320x180 y la ventana 960x540: exactamente ×3. Se sube por
## ENTEROS, nunca por 3,04, o los píxeles del fondo hierven. Y no se cuantiza a
## la paleta de la mazmorra, que no es la suya: es cáscara, no contenido.
func _dibujar_fondo(p: Vector2) -> void:
	var fondo := _fondo_actual()
	if fondo == null:
		return
	var tam := Vector2(fondo.get_width(), fondo.get_height())
	var escala := maxf(ceilf(p.x / tam.x), ceilf(p.y / tam.y))
	var destino := tam * escala
	_lienzo.draw_texture_rect(fondo,
		Rect2(((p - destino) * 0.5).floor(), destino), false)
	# Apagado general durante el combate: el escritorio no puede competir con la
	# bola. Con el mapa o la ruleta delante se deja ver más, que ahí sí manda.
	var apagado := _anim.escritorio_oscurecido
	_lienzo.draw_rect(Rect2(Vector2.ZERO, p), Color(C_VACIO, apagado))

## Qué fondo toca según el acto del run. Sin run (menú, pruebas) se queda en
## el del acto 1, que es el que siempre existe.
func _fondo_actual() -> Texture2D:
	if _fondos_acto.is_empty():
		return null
	var acto := 0
	if vista != null and vista.run != null and vista.run.mapa != null:
		acto = vista.run.mapa.acto_de_fila(maxi(vista.run.fila, 0))
	return _fondos_acto[clampi(acto, 0, _fondos_acto.size() - 1)]

## LA BARRA DE TAREAS, con el botón Inicio y el reloj. No hace nada y no tiene
## que hacerlo: es el marco de la broma. Lo único que sí informa es el reloj,
## que enseña la hora de verdad, porque un reloj parado se lee como un fallo.
func _dibujar_barra(p: Vector2) -> void:
	var caja := Rect2(0.0, p.y - ALTO_BARRA, p.x, ALTO_BARRA)
	if _barra.completo():
		_barra.dibujar(_lienzo, caja)
	else:
		_lienzo.draw_rect(caja, C_METAL)

	# El botón de Inicio. Con sprite propio, el cascabel de la esquina es su
	# logo: es lo único de toda la barra con identidad, así que va primero.
	var inicio := Rect2(4.0, caja.position.y + 4.0, 64.0, ALTO_BARRA - 8.0)
	if _tex_inicio != null:
		_lienzo.draw_texture_rect(_tex_inicio, inicio, false)
	elif _boton.completo():
		_boton.dibujar(_lienzo, inicio)
	_lienzo.draw_string(_fuente, Vector2(inicio.position.x + 24.0,
		inicio.position.y + 12.0), "Inicio",
		HORIZONTAL_ALIGNMENT_LEFT, inicio.size.x - 20.0, 8, C_VACIO)
	# El reloj, en su propia bandeja hundida: pegado al borde como texto suelto
	# no se distinguía de nada. Provisional con `draw_rect` hasta que haya un
	# sprite propio — está en la lista de prompts pendientes.
	var hora := Time.get_time_dict_from_system()
	var texto_hora := "%02d:%02d" % [int(hora["hour"]), int(hora["minute"])]
	var ancho_bandeja := 12.0 + FuenteUI.tam(8) * texto_hora.length() * 0.6
	var bandeja := Rect2(p.x - ancho_bandeja - 6.0, caja.position.y + 5.0,
		ancho_bandeja, ALTO_BARRA - 10.0)
	_lienzo.draw_rect(bandeja, C_VACIO)
	_lienzo.draw_rect(bandeja, Color(C_METAL, 0.6), false, 1.0)
	_lienzo.draw_string(_fuente, Vector2(bandeja.position.x + 6.0,
		bandeja.position.y + 12.0), texto_hora,
		HORIZONTAL_ALIGNMENT_LEFT, bandeja.size.x - 8.0, 8, C_VERDE)

	# El proceso que corre, que es la premisa entera en una línea: el sistema
	# lleva desde el principio intentando ejecutar un juego que no existe.
	var titulo := "cascabel.exe"
	if vista != null and vista.run != null and vista.run.terminada():
		titulo = "cascabel.exe  (no responde)"
	var pestana := Rect2(74.0, caja.position.y + 4.0, 150.0, ALTO_BARRA - 8.0)
	if _boton.completo():
		_boton.dibujar(_lienzo, pestana)
	_lienzo.draw_string(_fuente, Vector2(pestana.position.x + 6.0,
		pestana.position.y + 12.0), titulo,
		HORIZONTAL_ALIGNMENT_LEFT, pestana.size.x - 10.0, 8, C_VACIO)

## El marco alrededor de la mesa. Es lo que la convierte en una ventana: sin él
## la mesa es un rectángulo pegado sobre un fondo.
func _dibujar_marco_mesa() -> void:
	if not _ventana.completo():
		return
	var v := ventana_mesa()
	var f := franja_mesa()
	# El marco se dibuja SIN relleno en el hueco de la mesa: el relleno taparía
	# el campo. Se pintan las cuatro bandas de alrededor y ya.
	_marco_hueco(_ventana, v, f)
	# La barra de título, que es lo que de verdad dice "esto es una ventana".
	# Sin ella un rectángulo enmarcado es una caja.
	var barra := Rect2(v.position.x + GROSOR_VENTANA, v.position.y + GROSOR_VENTANA,
		v.size.x - GROSOR_VENTANA * 2.0, ALTO_TITULO)
	_titulo.dibujar(_lienzo, barra)
	_lienzo.draw_string(_fuente, Vector2(barra.position.x + 6.0,
		barra.position.y + 12.0), "cascabel.exe",
		HORIZONTAL_ALIGNMENT_LEFT, barra.size.x - 12.0, 8, C_BLANCO)
	# Los tres botones de la derecha. No hacen nada y no tienen que hacerlo:
	# son decorado, y `DISEÑO.md` §13 dice que no hay gestor de ventanas.
	var bx := barra.end.x - 12.0
	for nombre in ["cerrar", "max", "min"]:
		var caja_b := Rect2(bx, barra.position.y + 2.0, 12, 12)
		if _tex_botones.has(nombre):
			_lienzo.draw_texture_rect(_tex_botones[nombre], caja_b, false)
		else:
			_lienzo.draw_rect(caja_b, C_METAL)
			_lienzo.draw_rect(caja_b, C_VACIO, false, 1.0)
		bx -= 14.0

## Dibuja un marco alrededor de `hueco` sin pintar dentro. Es lo que hace falta
## para enmarcar algo que ya se está dibujando por su cuenta, como la mesa.
func _marco_hueco(marco: NueveTrozos, fuera: Rect2, hueco: Rect2) -> void:
	var g := marco.grosor()
	# Arriba: desde el borde de la ventana hasta el techo del hueco.
	marco.dibujar(_lienzo, Rect2(fuera.position,
		Vector2(fuera.size.x, hueco.position.y - fuera.position.y)))
	marco.dibujar(_lienzo, Rect2(fuera.position.x, hueco.end.y,
		fuera.size.x, fuera.end.y - hueco.end.y))
	marco.dibujar(_lienzo, Rect2(fuera.position.x, hueco.position.y,
		g.x, hueco.size.y))
	marco.dibujar(_lienzo, Rect2(hueco.end.x, hueco.position.y,
		fuera.end.x - hueco.end.x, hueco.size.y))

## LAS RELIQUIAS COMO ICONOS DEL ESCRITORIO, que es lo que pedía `DISEÑO.md` §4
## y a la vez arregla una pega abierta de verdad: hasta ahora lo que llevabas
## solo se veía en el mapa, así que una reliquia condicional se encendía y se
## apagaba durante el combate sin que nada lo dijera. Aquí el icono se ENCIENDE
## cuando la reliquia está activa.
func _dibujar_iconos() -> void:
	if vista == null or vista.run == null or vista.run.bolsa == null:
		return
	var bolsa := vista.run.bolsa
	for i in bolsa.reliquias.size():
		var r := bolsa.reliquias[i]
		var caja := caja_icono(i)
		var activa := bolsa.activa(r)
		var col := NodoTele.color_de_rareza(r.rareza)

		var tex := _icono(r)
		var tinte := Color(1, 1, 1, 1.0 if activa else 0.35)
		if tex != null:
			_lienzo.draw_texture_rect(tex, caja, false, tinte)
		else:
			_lienzo.draw_rect(caja, Color(col, 0.5 if activa else 0.2))
			_lienzo.draw_rect(caja, Color(col, tinte.a), false, 1.0)
		# El halo de rareza. Es lo que dice de un vistazo qué llevas encima sin
		# tener que leer catorce nombres.
		if activa:
			_lienzo.draw_rect(caja.grow(2.0), Color(col, 0.75), false, 1.0)

		_lienzo.draw_string(_fuente,
			Vector2(caja.position.x - 12.0, caja.end.y + 11.0), r.nombre,
			HORIZONTAL_ALIGNMENT_CENTER, LADO_ICONO + 24.0, 8,
			Color(C_TEXTO if activa else C_TEXTO_TENUE, tinte.a))

## Los iconos que NO hacen nada. Van en la banda IZQUIERDA, que es donde de
## verdad se apilan los iconos en un escritorio de Windows — la derecha se
## deja vacía a propósito en el original. Para no chocar con las reliquias,
## que ocupan esa misma banda desde arriba, estos cuelgan desde ABAJO.
func _dibujar_iconos_decorativos() -> void:
	if _tex_iconos_decorativos.is_empty():
		return
	var banda := banda_izquierda()
	var col := 0
	var fila := 0
	var por_columna := maxi(int((banda.size.y - MARGEN_ESCRITORIO * 2.0)
		/ (LADO_ICONO + SEPARACION_ICONO + 10.0)), 1)
	for tex in _tex_iconos_decorativos:
		if tex == null:
			fila += 1
			if fila >= por_columna:
				fila = 0
				col += 1
			continue
		var caja := Rect2(
			roundf(banda.end.x - MARGEN_ESCRITORIO - LADO_ICONO
				- float(col) * (LADO_ICONO + SEPARACION_ICONO)),
			roundf(banda.end.y - MARGEN_ESCRITORIO - LADO_ICONO
				- float(fila) * (LADO_ICONO + SEPARACION_ICONO + 10.0)),
			LADO_ICONO, LADO_ICONO)
		_lienzo.draw_texture_rect(tex, caja, false, Color(1, 1, 1, 0.9))
		fila += 1
		if fila >= por_columna:
			fila = 0
			col += 1

## El tooltip amarillo, que es el sitio donde por fin se lee qué hace una
## reliquia después de haberla cogido. Sin esto, lo que hace tu build solo se
## sabía durante los dos segundos de la ruleta.
func _dibujar_tooltip() -> void:
	if _icono_marcado < 0 or vista == null or vista.run == null:
		return
	var bolsa := vista.run.bolsa
	if _icono_marcado >= bolsa.reliquias.size():
		return
	var r := bolsa.reliquias[_icono_marcado]
	var caja := caja_icono(_icono_marcado)
	var ancho := 190.0
	var alto := 54.0 + (14.0 if r.cuando != "" else 0.0)
	var origen := Vector2(caja.end.x + 8.0, caja.position.y)
	# Que no se salga de la pantalla: un tooltip cortado no se lee.
	origen.x = minf(origen.x, pantalla().x - ancho - 4.0)
	origen.y = minf(origen.y, pantalla().y - ALTO_BARRA - alto - 4.0)
	var marco := Rect2(origen, Vector2(ancho, alto))

	if _tooltip.completo():
		_tooltip.dibujar(_lienzo, marco)
	else:
		_lienzo.draw_rect(marco, C_PERGAMINO)
	var x := origen.x + 6.0
	_lienzo.draw_string(_fuente, Vector2(x, origen.y + 13.0), r.nombre,
		HORIZONTAL_ALIGNMENT_LEFT, ancho - 12.0, 8, C_VACIO)
	_lienzo.draw_multiline_string(_fuente, Vector2(x, origen.y + 27.0), r.texto,
		HORIZONTAL_ALIGNMENT_LEFT, ancho - 12.0, 8, 3, C_VACIO)
	if r.cuando != "":
		var encendida := vista.run.bolsa.activa(r)
		_lienzo.draw_string(_fuente, Vector2(x, origen.y + alto - 6.0),
			"ACTIVA AHORA" if encendida else "apagada ahora",
			HORIZONTAL_ALIGNMENT_LEFT, ancho - 12.0, 8,
			C_VERDE if encendida else C_GOMA_LUZ)

func _icono(r: Reliquia) -> Texture2D:
	var ruta := r.ruta_icono(32)
	if ruta == "":
		return null
	if not _texturas.has(ruta):
		_texturas[ruta] = load(ruta) as Texture2D if ResourceLoader.exists(ruta) else null
	return _texturas[ruta] as Texture2D
