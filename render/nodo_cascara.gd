class_name NodoCascara
extends CanvasLayer

## LA CÁSCARA: el sistema operativo falso dentro del que vive la mesa.
##
## Aquí está el escritorio: fondo, barra de tareas con botón Inicio y reloj, los
## iconos de reliquia con su tooltip amarillo, los iconos decorativos, y los
## PANELES DE LA BANDA DERECHA, que es donde vive ahora lo que antes era el HUD
## encima de la mesa.
##
## NO HAY GESTOR DE VENTANAS y no lo va a haber (invariante). Los paneles están
## en posiciones fijas y solo PARECEN ventanas: no se arrastran, no se
## redimensionan, no hay foco ni orden de apilado.
##
## VA EN DOS CAPAS, y esto es un arreglo de verdad, no un detalle: esta capa va
## DETRÁS de la mesa (−10), y el marco de la ventana de la mesa se dibuja desde
## `NodoCascaraFrente`, que va DELANTE (5). Hasta ahora el marco se dibujaba también
## aquí detrás, y el fondo negro que pinta `NodoSuelo` sobre los 400 px de la
## mesa se comía la barra de título entera: quedaban solo las cuatro tiras de
## 8 px de los lados. O sea que la ventana estaba dibujada y no se veía —la misma
## avería del platillo, con otra cara—. El docstring ya prometía la capa 5; lo
## que faltaba era la capa.
##
## Esta clase sigue siendo la dueña de la GEOMETRÍA (dónde cae cada hueco) y de
## los marcos cargados. Quien dibuja encima —el HUD, el marco de la mesa— le
## pregunta a ella, para que no haya dos sitios midiendo la misma pantalla.

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
## El texto que va DENTRO de un cuadro de diálogo se escribe en NEGRO. El relleno
## del marco es el gris claro de Windows, así que reusar ahí el blanco del resto
## de la interfaz deja un cartel ilegible, y eso no da ningún error.
const C_TEXTO_DIALOGO := Paleta.CABINA

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

## LOS PANELES DE LA BANDA DERECHA. Alturas fijas y en múltiplos de 8, como todo
## lo demás: el de arriba tiene que darle sitio a un retrato de 96 px con su
## nombre y su barra debajo.
const MARGEN_PANEL := 10.0
const ALTO_PANEL_ENEMIGO := 216.0
const ALTO_PANEL_JUGADOR := 136.0
const ALTO_PANEL_AYUDA := 80.0
## El retrato dentro del panel del enemigo. Los sprites son de 96 (128 los
## jefes) y se dibujan a su tamaño: escalarlos a cualquier otro número los
## hierve, y aquí sobra sitio para no tener que hacerlo.
const LADO_RETRATO_PANEL := 96.0
const MARGEN_RETRATO := 8.0

## LOS FONDOS, por acto y con variantes. `DISEÑO.md` §3 dice que el sistema se
## corrompe acto a acto, y la corrupción no puede ser siempre el mismo dibujo: el
## acto 1 va limpio (una sola), el 2 empieza a fallar y el 3 se cae a trozos.
## El dado se tira al VOLVER AL ESCRITORIO, entre combate y combate, no cada
## fotograma: un fondo que parpadea entre variantes no se lee como un fallo del
## sistema, se lee como un fallo del juego.
const FONDOS_POR_ACTO := [
	["fondo_acto1"],
	["fondo_acto2", "fondo_acto2_a", "fondo_acto2_b"],
	["fondo_acto3", "fondo_acto3_a", "fondo_acto3_b", "fondo_acto3_c"],
]

var vista: VistaMesa
var _p: ParametrosCamara
var _anim: ParametrosAnimacion
## Una lista de texturas por acto. Las variantes que no se puedan cargar se caen
## de la lista al construirla: un PNG sin importar no puede dejar el escritorio
## en negro.
var _fondos_acto: Array = []
## Qué variante toca. Es un número grande al que se le hace el módulo con el
## tamaño de la lista del acto, así que sirve para los tres actos a la vez sin
## tener que guardar tres índices.
var _variante: int = 0
var _rng := RandomNumberGenerator.new()
## Los marcos, generados por `fuente.py`. Salen cuadrados por construcción: las
## nueve piezas miden la unidad y los cuatro lados son el mismo perfil reflejado.
var _ventana: NueveTrozos
var _titulo: NueveTrozos
var _barra: NueveTrozos
var _boton: NueveTrozos
var _tooltip: NueveTrozos
## El marco de diálogo de Windows: gris claro, para lo que interrumpe. Se usa en
## los carteles que PARAN el juego (victoria, derrota, ataque resolviéndose) y en
## el final del run. Los avisos que salen mientras juegas NO lo llevan: un cuadro
## de diálogo encima de la mesa con la bola viva tapa justo lo que hay que mirar.
var _dialogo: NueveTrozos
## La barra de progreso: canal, relleno normal y relleno de alarma.
var _tex_canal: Texture2D
var _tex_relleno: Texture2D
var _tex_relleno_alarma: Texture2D
var _lienzo: Node2D
var _fuente: Font
var _texturas: Dictionary = {}
## Botones de la barra de título (min/max/cerrar) y el botón Inicio, con
## identidad propia: el cascabel es el logo del sistema.
var _tex_botones: Dictionary = {}
var _tex_inicio: Texture2D
var _tex_inicio_pulsado: Texture2D
## Los iconos decorativos del escritorio. No hacen nada, como cualquier icono de
## escritorio real.
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
	_rng.randomize()

func _ready() -> void:
	_fuente = FuenteUI.obtener()
	_cargar_fondos()
	_ventana = NueveTrozos.cargar("res://assets/ui/ventana")
	_titulo = NueveTrozos.cargar("res://assets/ui/titulo")
	_barra = NueveTrozos.cargar("res://assets/ui/barra")
	_boton = NueveTrozos.cargar("res://assets/ui/boton")
	_tooltip = NueveTrozos.cargar("res://assets/ui/tooltip")
	_dialogo = NueveTrozos.cargar("res://assets/ui/dialogo")
	_tex_canal = _cargar("res://assets/ui/progreso/canal.png")
	_tex_relleno = _cargar("res://assets/ui/progreso/relleno.png")
	_tex_relleno_alarma = _cargar("res://assets/ui/progreso/relleno_alarma.png")
	for nombre in ["min", "max", "cerrar"]:
		var t := _cargar("res://assets/ui/botones/%s.png" % nombre)
		if t != null:
			_tex_botones[nombre] = t
	_tex_inicio = _cargar("res://assets/ui/inicio/inicio.png")
	_tex_inicio_pulsado = _cargar("res://assets/ui/inicio/inicio_pulsado.png")
	for nombre in ICONOS_DECORATIVOS:
		_tex_iconos_decorativos.append(_cargar("res://assets/ui/iconos/%s.png" % nombre))
	_lienzo = Node2D.new()
	_lienzo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Sin esto los bordes del marco no se pueden repetir y saldrían estirados,
	# que es justo lo que un marco de nueve trozos existe para evitar.
	_lienzo.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_lienzo.draw.connect(_dibujar)
	add_child(_lienzo)

static func _cargar(ruta: String) -> Texture2D:
	return load(ruta) as Texture2D if ResourceLoader.exists(ruta) else null

func _cargar_fondos() -> void:
	_fondos_acto = []
	for lista in FONDOS_POR_ACTO:
		var texturas: Array[Texture2D] = []
		for nombre in lista:
			var t := _cargar("res://assets/shell/%s.png" % str(nombre))
			if t != null:
				texturas.append(t)
		_fondos_acto.append(texturas)

# ------------------------------------------------------------------- el fondo

## Cuántas variantes de fondo hay para un acto. Público para que la prueba pueda
## comprobar que la corrupción CRECE: si el acto 3 no trae más que el 1, el
## escritorio no cuenta nada de lo que dice `DISEÑO.md` §3.
func variantes_de_acto(acto: int) -> int:
	if _fondos_acto.is_empty():
		return 0
	var lista: Array = _fondos_acto[clampi(acto, 0, _fondos_acto.size() - 1)]
	return lista.size()

## Vuelve a tirar el dado del fondo. Lo llama la vista al volver al escritorio,
## que es el único momento en el que el fondo se puede cambiar sin que se vea
## cambiar: entre combate y combate.
func tirar_fondo() -> void:
	_variante = _rng.randi_range(0, 4095)

## El fondo de un acto con la variante de esta vuelta. Público para que la prueba
## pueda tirar el dado muchas veces y comprobar que salen TODAS: con el módulo
## mal puesto saldría siempre la misma y el arte de las variantes no se vería
## nunca, sin que nada diera error.
func fondo_de_acto(acto: int) -> Texture2D:
	if _fondos_acto.is_empty():
		return null
	var lista: Array = _fondos_acto[clampi(acto, 0, _fondos_acto.size() - 1)]
	if lista.is_empty():
		return null
	return lista[_variante % lista.size()] as Texture2D

## Qué fondo toca según el acto del run. Sin run (menú, pruebas) se queda en el
## del acto 1, que es el que siempre existe.
func fondo_actual() -> Texture2D:
	var acto := 0
	if vista != null and vista.run != null and vista.run.mapa != null:
		acto = vista.run.mapa.acto_de_fila(maxi(vista.run.fila, 0))
	return fondo_de_acto(acto)

# ------------------------------------------------------------------- huecos

func pantalla() -> Vector2:
	return _lienzo.get_viewport_rect().size.ceil()

## Lo que la ventana de la mesa le come a la pantalla por arriba: el marco más la
## barra de título. Es el número con el que la cámara sabe hasta dónde puede
## dejar subir la bola sin que se esconda detrás de nada.
static func chrome_superior() -> float:
	return GROSOR_VENTANA + ALTO_TITULO

## La franja de la mesa en pantalla: 400 px centrados.
func franja_mesa() -> Rect2:
	var p := pantalla()
	# La mesa empieza por debajo de la barra de título de su ventana y acaba por
	# encima de la barra de tareas. Los 400 px de ancho son intocables: la física
	# está ajustada a esa anchura.
	var arriba := chrome_superior()
	return Rect2(roundf((p.x - Mesa.ANCHO) * 0.5), arriba, Mesa.ANCHO,
		p.y - ALTO_BARRA - GROSOR_VENTANA - arriba)

## La ventana entera: la mesa más su marco y su barra de título.
func ventana_mesa() -> Rect2:
	var f := franja_mesa()
	return Rect2(f.position - Vector2(GROSOR_VENTANA, GROSOR_VENTANA + ALTO_TITULO),
		f.size + Vector2(GROSOR_VENTANA * 2.0, GROSOR_VENTANA * 2.0 + ALTO_TITULO))

## El escritorio libre de cada lado. Es el sitio que `PLAN.md` reservó desde la
## Fase 1: ~270 px por banda.
func banda_izquierda() -> Rect2:
	var v := ventana_mesa()
	var p := pantalla()
	return Rect2(0.0, 0.0, v.position.x, p.y - ALTO_BARRA)

func banda_derecha() -> Rect2:
	var v := ventana_mesa()
	var p := pantalla()
	return Rect2(v.end.x, 0.0, p.x - v.end.x, p.y - ALTO_BARRA)

## LOS TRES PANELES DE LA DERECHA. La banda izquierda ya está ocupada por los
## iconos (reliquias desde arriba, decorativos desde abajo), así que lo que salga
## del HUD viene aquí, que es el sitio que estaba vacío.
func panel_enemigo() -> Rect2:
	var b := banda_derecha()
	return Rect2(roundf(b.position.x + MARGEN_PANEL), MARGEN_PANEL,
		roundf(maxf(b.size.x - MARGEN_PANEL * 2.0, 0.0)), ALTO_PANEL_ENEMIGO)

func panel_jugador() -> Rect2:
	var e := panel_enemigo()
	return Rect2(e.position.x, e.end.y + MARGEN_PANEL, e.size.x, ALTO_PANEL_JUGADOR)

## El de las teclas cuelga desde ABAJO, no desde el panel de arriba: así en una
## pantalla más alta el hueco que sobra queda en medio y no debajo del todo.
func panel_ayuda() -> Rect2:
	var b := banda_derecha()
	var e := panel_enemigo()
	return Rect2(e.position.x,
		roundf(maxf(b.end.y - MARGEN_PANEL - ALTO_PANEL_AYUDA, panel_jugador().end.y)),
		e.size.x, ALTO_PANEL_AYUDA)

## DÓNDE SE POSAN LOS PIES DEL ENEMIGO dentro de su panel. Sale de aquí y no de
## cada nodo que lo necesite porque son dos los que lo miran —el que dibuja al
## bicho y el que escribe su nombre y su barra debajo—, y con dos copias del
## número una se queda vieja en cuanto cambie el alto del panel.
func suelo_enemigo() -> Vector2:
	var d := interior_panel(panel_enemigo())
	return Vector2(roundf(d.position.x + d.size.x * 0.5),
		roundf(d.position.y + MARGEN_RETRATO + LADO_RETRATO_PANEL))

## El hueco de dentro de un panel: por debajo de su barra de título y dentro de
## su marco. Es donde el HUD escribe.
func interior_panel(caja: Rect2) -> Rect2:
	return Rect2(caja.position.x + GROSOR_VENTANA,
		caja.position.y + GROSOR_VENTANA + ALTO_TITULO,
		maxf(caja.size.x - GROSOR_VENTANA * 2.0, 0.0),
		maxf(caja.size.y - GROSOR_VENTANA * 2.0 - ALTO_TITULO, 0.0))

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

func _input(evento: InputEvent) -> void:
	var raton := evento as InputEventMouseMotion
	if raton == null:
		return
	_icono_marcado = _icono_en(raton.position)

func _process(_delta: float) -> void:
	_lienzo.queue_redraw()

# ------------------------------------------------- piezas que dibujan los demás

## Un panel con su marco y su barra de título. Público porque lo usan el HUD y el
## mapa: si cada uno se dibujara el suyo, en cuanto cambie el grosor del marco
## habría tres sitios que actualizar y solo se actualizarían dos.
func dibujar_panel(en: CanvasItem, caja: Rect2, titulo_texto: String,
		activo: bool = true) -> void:
	if _ventana.completo():
		_ventana.dibujar(en, caja)
	else:
		en.draw_rect(caja, C_VACIO)
	var barra := Rect2(caja.position.x + GROSOR_VENTANA,
		caja.position.y + GROSOR_VENTANA,
		maxf(caja.size.x - GROSOR_VENTANA * 2.0, 0.0), ALTO_TITULO)
	if _titulo.completo():
		_titulo.dibujar(en, barra, Color(1, 1, 1, 1.0 if activo else 0.7))
	en.draw_string(_fuente, Vector2(barra.position.x + 6.0, barra.position.y + 12.0),
		titulo_texto, HORIZONTAL_ALIGNMENT_LEFT, barra.size.x - 12.0, 8,
		C_BLANCO if activo else C_TEXTO_TENUE)

## El marco de diálogo, para lo que INTERRUMPE. Devuelve el hueco de dentro.
func dibujar_dialogo(en: CanvasItem, caja: Rect2) -> Rect2:
	if _dialogo.completo():
		_dialogo.dibujar(en, caja)
		return _dialogo.interior(caja)
	en.draw_rect(caja, C_PERGAMINO)
	return caja.grow(-8.0)

## LA BARRA DE PROGRESO de verdad, con el arte que llevaba recortado y sin
## conectar desde la tanda anterior. Es la del reloj del enemigo, y por eso tiene
## dos rellenos: el azul de "esto va progresando" y el rojo de "esto va a pasar
## ya". Se REPITEN los dos, como cualquier otro trozo de la cáscara.
func dibujar_progreso(en: CanvasItem, caja: Rect2, proporcion: float,
		alarma: bool, tinte: Color = Color.WHITE) -> void:
	var r := Rect2(caja.position.round(), caja.size.round())
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	if _tex_canal != null:
		en.draw_texture_rect(_tex_canal, r, true, tinte)
	else:
		en.draw_rect(r, C_VACIO)
	var dentro := r.grow(-2.0)
	var ancho := floorf(dentro.size.x * clampf(proporcion, 0.0, 1.0))
	if ancho <= 0.0 or dentro.size.y <= 0.0:
		return
	var relleno := _tex_relleno_alarma if alarma else _tex_relleno
	var lleno := Rect2(dentro.position, Vector2(ancho, dentro.size.y))
	if relleno != null:
		en.draw_texture_rect(relleno, lleno, true, tinte)
	else:
		en.draw_rect(lleno, C_GOMA_LUZ if alarma else C_VERDE)

## EL MARCO DE LA VENTANA DE LA MESA. Lo dibuja `NodoCascaraFrente` por DELANTE
## de la mesa (capa 5): aquí detrás se lo comía el fondo negro del tablero.
##
## Dentro de la barra de título va la barra de progreso del reloj del enemigo, y
## ese sitio no es un capricho: es el único que está pegado a la mesa, dentro de
## sus 400 px de ancho, y NO le quita ni un píxel de campo de juego. El reloj
## tiene que verse de reojo sin dejar de mirar la bola —esa era la razón de
## tenerlo en el HUD— y la barra de título ya estaba ahí gastando 16 px en decir
## "cascabel.exe". Ahora dice además cuánto falta para que te peguen, que es
## exactamente la broma: una ventana con una barra de progreso que no querrías
## que se llenara.
func dibujar_marco_mesa(en: CanvasItem) -> void:
	if not _ventana.completo():
		return
	var v := ventana_mesa()
	var f := franja_mesa()
	# El marco se dibuja SIN relleno en el hueco de la mesa: el relleno taparía
	# el campo. Se pintan las cuatro bandas de alrededor y ya.
	_marco_hueco(en, _ventana, v, f)
	var barra := Rect2(v.position.x + GROSOR_VENTANA, v.position.y + GROSOR_VENTANA,
		v.size.x - GROSOR_VENTANA * 2.0, ALTO_TITULO)
	_titulo.dibujar(en, barra)
	en.draw_string(_fuente, Vector2(barra.position.x + 6.0,
		barra.position.y + 12.0), "cascabel.exe",
		HORIZONTAL_ALIGNMENT_LEFT, 78.0, 8, C_BLANCO)
	# Los tres botones de la derecha. No hacen nada y no tienen que hacerlo:
	# son decorado, y `DISEÑO.md` §13 dice que no hay gestor de ventanas.
	var bx := barra.end.x - 14.0
	for nombre in ["cerrar", "max", "min"]:
		var caja_b := Rect2(bx, barra.position.y + 2.0, 12, 12)
		if _tex_botones.has(nombre):
			en.draw_texture_rect(_tex_botones[nombre], caja_b, false)
		else:
			en.draw_rect(caja_b, C_METAL)
			en.draw_rect(caja_b, C_VACIO, false, 1.0)
		bx -= 14.0
	_dibujar_reloj_en_titulo(en, barra, bx)

## El reloj del enemigo, escrito y con barra, dentro de la barra de título.
##
## Los segundos van ESCRITOS y siempre, no solo en los últimos tres: una barra
## pelada no se lee como un reloj, y sin el número el jugador solo se entera de
## que existe cuando ya le está pegando.
func _dibujar_reloj_en_titulo(en: CanvasItem, barra: Rect2, tope_der: float) -> void:
	if vista == null or vista.combate == null or vista.combate.enemigo == null:
		return
	var combate := vista.combate
	var restante := combate.reloj_restante()
	var avisando := restante <= combate.p.reloj_aviso
	var col := C_TEXTO_TENUE
	if avisando:
		# Parpadeo por tramos enteros de tiempo, no por seno: a medio camino
		# quedaría medio píxel de color.
		col = C_ORO_CLARO if int(restante * 6.0) % 2 == 0 else C_GOMA_LUZ
	# El platillo acaba de robarle tiempo al reloj: se enciende la barra, que es
	# el contador del que habla el "+N s" que ha salido abajo en la mesa. La
	# causa se ve donde pasa; el efecto, donde se mide.
	var robado := vista.flash_reloj > 0.0
	if robado:
		col = C_ARCANO

	var x := barra.position.x + 90.0
	en.draw_string(_fuente, Vector2(x, barra.position.y + 12.0),
		"ATAQUE EN %ds" % int(ceil(restante)),
		HORIZONTAL_ALIGNMENT_LEFT, 84.0, 8, col)
	var izq := x + 88.0
	var ancho := tope_der - 6.0 - izq
	if ancho < 24.0:
		return
	dibujar_progreso(en, Rect2(izq, barra.position.y + 2.0, ancho, 12.0),
		combate.carga_reloj, avisando,
		Color(C_ARCANO, 1.0) if robado else Color.WHITE)

## Dibuja un marco alrededor de `hueco` sin pintar dentro. Es lo que hace falta
## para enmarcar algo que ya se está dibujando por su cuenta, como la mesa.
func _marco_hueco(en: CanvasItem, marco: NueveTrozos, fuera: Rect2,
		hueco: Rect2) -> void:
	var g := marco.grosor()
	marco.dibujar(en, Rect2(fuera.position,
		Vector2(fuera.size.x, hueco.position.y - fuera.position.y)))
	marco.dibujar(en, Rect2(fuera.position.x, hueco.end.y,
		fuera.size.x, fuera.end.y - hueco.end.y))
	marco.dibujar(en, Rect2(fuera.position.x, hueco.position.y,
		g.x, hueco.size.y))
	marco.dibujar(en, Rect2(hueco.end.x, hueco.position.y,
		fuera.end.x - hueco.end.x, hueco.size.y))

# ------------------------------------------------------------------- dibujo

## LO QUE VA DETRÁS DE LA MESA, y solo eso: el fondo, los iconos de las dos
## bandas y los paneles de la derecha. Ninguna de esas cosas pisa la columna de
## 400 px de la mesa, así que la mesa no puede taparlas. Lo que sí la pisa —el
## marco de su ventana, la barra de tareas y el tooltip— lo dibuja
## `NodoCascaraFrente` en la capa 5.
func _dibujar() -> void:
	var p := pantalla()
	_lienzo.draw_rect(Rect2(Vector2.ZERO, p), C_VACIO)
	_dibujar_fondo(p)
	# Los paneles van DESPUÉS del apagado del escritorio: son interfaz, no
	# decorado, y tienen que leerse igual de bien con la mesa encendida.
	_dibujar_paneles()
	_dibujar_iconos()
	_dibujar_iconos_decorativos()
	if not get_viewport().size_changed.is_connected(_lienzo.queue_redraw):
		get_viewport().size_changed.connect(_lienzo.queue_redraw)

## El fondo es 320x180 y la ventana 960x540: exactamente ×3. Se sube por
## ENTEROS, nunca por 3,04, o los píxeles del fondo hierven. Y no se cuantiza a
## la paleta de la mazmorra, que no es la suya: es cáscara, no contenido.
func _dibujar_fondo(p: Vector2) -> void:
	var fondo := fondo_actual()
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

## Los marcos vacíos de los tres paneles de la derecha. Lo de dentro lo escribe
## el HUD, que es quien tiene los datos del combate: aquí solo va el mueble.
func _dibujar_paneles() -> void:
	if vista == null:
		return
	var nombre := "enemigo.exe"
	if vista.combate != null and vista.combate.enemigo != null:
		nombre = vista.combate.enemigo.nombre.to_lower().replace(" ", "_") + ".exe"
	dibujar_panel(_lienzo, panel_enemigo(), nombre)
	dibujar_panel(_lienzo, panel_jugador(), "jugador.sys")
	dibujar_panel(_lienzo, panel_ayuda(), "ayuda.hlp", false)

## LA BARRA DE TAREAS, con el botón Inicio y el reloj. No hace nada y no tiene
## que hacerlo: es el marco de la broma. Lo único que sí informa es el reloj,
## que enseña la hora de verdad, porque un reloj parado se lee como un fallo.
##
## LA DIBUJA LA CAPA DE DELANTE. Una barra de tareas de verdad está siempre
## encima de todo, y esta además cruza la columna de la mesa: dibujada detrás, el
## negro del tablero la partía por la mitad. No se notaba porque el botón Inicio,
## la pestaña del proceso y el reloj caen los tres FUERA de esa columna, así que
## lo único que se perdía era el mueble del medio.
func dibujar_barra_tareas(en: CanvasItem) -> void:
	var p := pantalla()
	var caja := Rect2(0.0, p.y - ALTO_BARRA, p.x, ALTO_BARRA)
	if _barra.completo():
		_barra.dibujar(en, caja)
	else:
		en.draw_rect(caja, C_METAL)

	# El botón de Inicio. Con sprite propio, el cascabel de la esquina es su
	# logo: es lo único de toda la barra con identidad, así que va primero.
	var inicio := Rect2(4.0, caja.position.y + 4.0, 64.0, ALTO_BARRA - 8.0)
	if _tex_inicio != null:
		en.draw_texture_rect(_tex_inicio, inicio, false)
	elif _boton.completo():
		_boton.dibujar(en, inicio)
	en.draw_string(_fuente, Vector2(inicio.position.x + 24.0,
		inicio.position.y + 12.0), "Inicio",
		HORIZONTAL_ALIGNMENT_LEFT, inicio.size.x - 20.0, 8, C_VACIO)
	# El reloj, en su propia bandeja hundida: pegado al borde como texto suelto
	# no se distinguía de nada.
	var hora := Time.get_time_dict_from_system()
	var texto_hora := "%02d:%02d" % [int(hora["hour"]), int(hora["minute"])]
	var ancho_bandeja := 12.0 + FuenteUI.tam(8) * texto_hora.length() * 0.6
	var bandeja := Rect2(p.x - ancho_bandeja - 6.0, caja.position.y + 5.0,
		ancho_bandeja, ALTO_BARRA - 10.0)
	en.draw_rect(bandeja, C_VACIO)
	en.draw_rect(bandeja, Color(C_METAL, 0.6), false, 1.0)
	en.draw_string(_fuente, Vector2(bandeja.position.x + 6.0,
		bandeja.position.y + 12.0), texto_hora,
		HORIZONTAL_ALIGNMENT_LEFT, bandeja.size.x - 8.0, 8, C_VERDE)

	# El proceso que corre, que es la premisa entera en una línea: el sistema
	# lleva desde el principio intentando ejecutar un juego que no existe.
	var titulo_texto := "cascabel.exe"
	if vista != null and vista.run != null and vista.run.terminada():
		titulo_texto = "cascabel.exe  (no responde)"
	var pestana := Rect2(74.0, caja.position.y + 4.0, 150.0, ALTO_BARRA - 8.0)
	if _boton.completo():
		_boton.dibujar(en, pestana)
	en.draw_string(_fuente, Vector2(pestana.position.x + 6.0,
		pestana.position.y + 12.0), titulo_texto,
		HORIZONTAL_ALIGNMENT_LEFT, pestana.size.x - 10.0, 8, C_VACIO)

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
##
## LO DIBUJA LA CAPA DE DELANTE, porque se sale de su banda: nace a la derecha
## del icono y con la bolsa llena puede desbordar hacia la columna de la mesa.
## Detrás quedaba cortado justo por donde empieza el texto.
func dibujar_tooltip(en: CanvasItem) -> void:
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
		_tooltip.dibujar(en, marco)
	else:
		en.draw_rect(marco, C_PERGAMINO)
	var x := origen.x + 6.0
	en.draw_string(_fuente, Vector2(x, origen.y + 13.0), r.nombre,
		HORIZONTAL_ALIGNMENT_LEFT, ancho - 12.0, 8, C_VACIO)
	en.draw_multiline_string(_fuente, Vector2(x, origen.y + 27.0), r.texto,
		HORIZONTAL_ALIGNMENT_LEFT, ancho - 12.0, 8, 3, C_VACIO)
	if r.cuando != "":
		var encendida := vista.run.bolsa.activa(r)
		en.draw_string(_fuente, Vector2(x, origen.y + alto - 6.0),
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
