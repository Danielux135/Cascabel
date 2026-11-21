extends Control

## EL MARCADOR DE LA CRIPTA. Presentación pura: la escena (`cripta_3d.gd`) le dice
## QUÉ pasa —los puntos, la bola, el multiplicador, la campana, la caza, un
## aviso— y aquí se decide CÓMO se enseña. No cuenta, no puntúa y no lee teclas.
##
## EL LISTÓN es Saltline: casi no hay marcador. Cuatro bloques pequeños pegados a
## las esquinas, un aviso que entra y se va arriba en el centro, y nada encima
## del campo de juego. Todo lo demás es imagen.
##
##   arriba a la izquierda   LA CAZA, que es el objetivo: una raya vertical, la
##                           ola y las tres criaturas, cada una con lo que le pasa
##   arriba en el centro     EL AVISO, entre dos filetes que se abren
##   arriba a la derecha     la cámara y la calidad, SOLO un momento al cambiarlas
##   abajo a la izquierda    LA CAMPANA MAYOR, que es la mecánica de esta mesa
##   abajo a la derecha      LOS PUNTOS, la bola y el multiplicador con su combo
##   a la izquierda, a media altura   el sello de lugar al empezar y, debajo,
##                           las teclas, que se van solas; con H, el panel
##
## Las cuentas (braseros, lápidas, recorridos…) son estadística y solo salen con
## la ayuda. Ningún bloque lleva caja: detrás de cada uno hay una penumbra blanda
## (`marcador_sombra.gdshader`) y la letra lleva sombra fina, para que se lea
## igual sobre el fuego que sobre la piedra a oscuras.
##
## EL LIENZO es de 960×540 lógicos y crece por el lado que sobre (`aspect =
## expand`): en una ventana más cuadrada sale más alto, en una más ancha, más
## ancho. Por eso todo se coloca contra las esquinas de `size` y nada contra
## números fijos del centro.
##
## LA LETRA son dos familias del sistema con su reserva. En web no hay fuentes del
## sistema y cae en la de Godot, que trae tildes y eñes; el espaciado sale de
## `FontVariation`, así que se sigue viendo ordenado aunque cambie la letra.
##   PALO SECO   Bahnschrift condensada (o Segoe UI, o Arial): rótulos y datos,
##               siempre en versales y espaciada, como las de Saltline
##   INSCRIPCIÓN Palatino Linotype (o Cambria, o Georgia): el número, el aviso y
##               el sello. Con cifras ALINEADAS y de ancho fijo: Georgia las trae
##               de estilo antiguo, con el 3 y el 7 colgando, y un marcador así
##               baila al subir.
## Tres cuerpos y no más: PEQ para todo lo que se lee de reojo, MED para los
## nombres y el aviso, GRA para el número y el sello.

const MARFIL := Paleta.TIERRA_6
const ORO := Paleta.ORO
const TENUE := Paleta.TIERRA_4
const ALERTA := Paleta.ROJO_LUZ
const NEGRO := Color(0.0, 0.0, 0.0)

const PEQ := 9
const MED := 14
const GRA := 34

## Los márgenes contra el canto del lienzo. Los bloques de abajo van pegados al
## canto: con 20 tocaban las esquinas de la mesa a 16:9.
const MARGEN := 24.0
const ARRIBA := 20.0
const ABAJO := 14.0
## Lo que mide cada bloque de abajo, como mucho. A 16:9 se queda en 150: con 178
## la barra de la campana pasaba por encima del borde de piedra de la mesa y la
## de los puntos, por el pie del carril del lanzador.
const ANCHO_ESQUINA := 178.0
const ANCHO_ESQUINA_MIN := 150.0
## EL AVISO va más arriba que los bloques de las esquinas (su filete de arriba
## en `ARRIBA_AVISO`) y con el renglón apretado: en dos líneas acababa al 10,5 %
## del alto, encima de los arcos de raíles del ábside.
const ARRIBA_AVISO := 11.0
const RENGLON_AVISO := 16.0
## Lo que se separa el aviso del bloque que tenga más cerca a cada lado, de
## lado y de alto.
const AIRE_AVISO := 22.0
const AIRE_AVISO_ALTO := 6.0
## El panel de ayuda: cabe entre la mesa y el canto. Con 226 tapaba los raíles
## de la derecha a 16:9.
const ANCHO_AYUDA := 194.0

## Cómo está cada criatura, de la que no cuenta a la que hay que ir a por ella.
## La escena lo decide (sabe de la caza); aquí solo se pinta.
const FUERA := 0        # fuera de juego (teclas 1, 2 y 3)
const ASEGURADA := 1    # ya está: se apaga
const QUIETA := 2       # suelta o llegando
const VIVA := 3         # huye, está aturdida, escondida o partida
const LLAMA := 4        # rendida, acorralada, volcada o en la bola: LLAMA

## Las teclas de debajo del sello: lo mínimo para jugar. El resto, en el panel.
const TECLAS_CORTAS := [["A / D", "PALAS"], ["ESPACIO", "LANZAR"], ["C", "CÁMARA"],
	["H", "AYUDA"]]
const TECLAS := [["A / D", "PALAS"], ["ESPACIO", "LANZAR (MANTENER)"],
	["C", "CAMBIAR DE CÁMARA"], ["X", "SEGUIR A OTRA CRIATURA"],
	["1 2 3", "BRASA · CALAVERA · ESPECTRO"], ["M", "BOLA EXTRA"], ["R", "BOLA NUEVA"],
	["T", "PILOTO AUTOMÁTICO"], ["G", "CALIDAD DE LOS GRÁFICOS"], ["H", "CERRAR LA AYUDA"]]

const SOMBRA := preload("res://cripta3d/marcador_sombra.gdshader")

# ------------------------------------------------- lo que dice la escena

var puntos := 0
var bola := 1
var multiplicador := 1
## Lo que le queda al combo, de 1 (acaba de completar un recorrido) a 0.
var combo := 0.0
var piloto := false
var rotulo_campana := "CAMPANA MAYOR"
## La campana: cuánto lleva cargado (0..1), si está armada y, mientras toca,
## lo que le queda de los segundos que dura (de 1 a 0; 0 = no toca).
var carga := 0.0
var armada := false
var tocando := 0.0
var ola := 1
## Una fila por criatura: {nombre, estado, color, consejo, nivel}. Ver `poner_caza`.
var filas: Array[Dictionary] = []
## Las cuentas del panel de ayuda, por orden: [rótulo, número].
var cuentas: Array = []
## Solo en web: la página está abierta y nadie ha tocado nada todavía.
var falta_clic := false
var web := false
## Dónde cae la bola en peligro, en coordenadas del lienzo (x < 0: no se sabe).
## Cuando corre por el raíl del campanario pasa por detrás de la franja del
## aviso, y el aviso se aparta para no taparla.
var bola_pantalla := Vector2(-1.0, -1.0)

# ------------------------------------------------------- lo suyo

var _letra_rotulo: FontVariation
var _letra_panel: FontVariation
var _letra_nombre: FontVariation
var _letra_cifra: FontVariation
var _letra_aviso: FontVariation
var _letra_sello: FontVariation

var _tinta: Control
var _sombra: ColorRect
var _cajas: Array[Vector4] = []
var _fuerzas: Array[float] = []

var _t := 0.0
var _mostrado := 0.0
var _brillo_puntos := 0.0
var _multi_antes := 1
var _brillo_multi := 0.0

var _aviso := PackedStringArray()
var _aviso_texto := ""
var _aviso_col := MARFIL
var _aviso_t := 0.0
var _aviso_dura := 0.0

var _vista := ""
var _calidad := ""
var _vista_t := 99.0

var _ayuda := false
## Desde cuándo se está jugando, para que las teclas se vayan solas.
var _jugando_t := 0.0
var _falta_antes := false

## El consejo de cómo se captura va en una línea propia debajo de las tres
## criaturas, con el rombo de la que toca: la que está más cerca de caer, o, si
## ninguna lo está, cada una un rato. Antes se abría debajo de su fila y hacía
## la caza tan ancha que el aviso de arriba no cabía en una línea.
var _foco := 0
var _foco_t := 0.0
var _consejo_a := 0.0
var _consejo_texto := ""
var _hueco_consejo := 0.0

## Cada renglón de la caza como (alto de arriba, alto de abajo, borde derecho):
## el aviso solo se aparta de los que le caen a su altura.
var _caza_lineas: Array[Vector3] = []
var _vista_izq := 0.0
## Lo que el aviso se aparta cuando la bola pasa por detrás, y por dónde cae.
var _aviso_tapa := 1.0
var _aviso_rect := Rect2()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var palo := PackedStringArray(["Bahnschrift", "Segoe UI", "Arial"])
	var inscripcion := PackedStringArray(["Palatino Linotype", "Cambria", "Georgia"])
	# Bahnschrift es una sola fuente variable: lo condensado y el peso se le
	# piden por sus ejes. Una letra sin esos ejes los ignora.
	_letra_rotulo = _letra(palo, 500, 2, {"wdth": 80, "wght": 450})
	_letra_nombre = _letra(palo, 600, 1, {"wdth": 85, "wght": 600})
	# La del panel de ayuda, menos espaciada: es una tabla que se lee de arriba
	# abajo, y así el panel cabe entre la mesa y el canto de la pantalla.
	_letra_panel = _letra(palo, 500, 1, {"wdth": 80, "wght": 450})
	var cifras := {"lnum": 1, "tnum": 1}
	_letra_cifra = _letra(inscripcion, 400, 0, {}, cifras)
	# El aviso, con un punto de espaciado y no dos: con dos, los de todos los días
	# («CAMPANA MAYOR ARMADA · COMPLETA UN RECORRIDO») no cabían en una línea.
	_letra_aviso = _letra(inscripcion, 400, 1, {}, cifras)
	_letra_sello = _letra(inscripcion, 400, 9, {}, cifras)

	_sombra = ColorRect.new()
	_sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = SOMBRA
	_sombra.material = m
	add_child(_sombra)
	_tinta = Control.new()
	_tinta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tinta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tinta.draw.connect(_dibujar)
	add_child(_tinta)

func _letra(nombres: PackedStringArray, peso: int, espacio: int, ejes: Dictionary,
		rasgos: Dictionary = {}) -> FontVariation:
	var s := SystemFont.new()
	# En un navegador no hay fuentes del sistema: pedida con nombres o sin ellos,
	# sale la de reserva de Godot. Sin nombres pasa lo mismo en escritorio, y así
	# `-- --como-web` enseña el marcador tal como lo verá quien entre por la web.
	if not web:
		s.font_names = nombres
	s.font_weight = peso
	# Sin ajuste a la rejilla: Bahnschrift se pide condensada por su eje de
	# anchura, y las instrucciones de ajuste son las de la anchura normal. Con
	# ellas, a cuerpo pequeño, la D salía sin barriga y la E y la S partidas.
	s.hinting = TextServer.HINTING_NONE
	var f := FontVariation.new()
	f.base_font = s
	# La de reserva es más ancha que una condensada: con un punto menos de
	# espaciado el renglón del consejo deja de meterse en los raíles de la mesa.
	f.spacing_glyph = maxi(espacio - 1, 0) if web else espacio
	var ts := TextServerManager.get_primary_interface()
	if not ejes.is_empty():
		var v := {}
		for eje: String in ejes:
			v[ts.name_to_tag(eje)] = ejes[eje]
		f.variation_opentype = v
	if not rasgos.is_empty():
		var r := {}
		for rasgo: String in rasgos:
			r[ts.name_to_tag(rasgo)] = rasgos[rasgo]
		f.opentype_features = r
	return f

# ------------------------------------------------- lo que pide la escena

## Un aviso de una línea. Dura según lo largo que sea: lo que no da tiempo a
## leer no se ha dicho.
func avisar(texto: String, color: Color) -> void:
	# Los números del aviso, con sus millares como los del marcador: «+15000» al
	# lado de «71.857» parecían dos cosas distintas.
	var cifras := RegEx.create_from_string("[0-9]{4,}")
	for hallado: RegExMatch in cifras.search_all(texto):
		texto = texto.replace(hallado.get_string(), _miles(int(hallado.get_string())))
	_aviso_texto = texto
	_aviso_col = color
	_aviso_t = 0.0
	_aviso_dura = clampf(1.6 + 0.035 * texto.length(), 2.0, 3.4)

func poner_caza(nueva_ola: int, nuevas_filas: Array[Dictionary]) -> void:
	ola = nueva_ola
	filas = nuevas_filas

## La cámara y la calidad salen un momento cuando cambian, no siempre.
func poner_vista(camara: String, calidad: String) -> void:
	if camara == _vista and calidad == _calidad:
		return
	if _vista != "":
		_vista_t = 0.0
	_vista = camara
	_calidad = calidad

func alternar_ayuda() -> void:
	_ayuda = not _ayuda

# ------------------------------------------------------------ el reloj

func _process(delta: float) -> void:
	_t += delta
	_aviso_t += delta
	_vista_t += delta
	_jugando_t += delta
	if _falta_antes and not falta_clic:
		_jugando_t = 0.0
	_falta_antes = falta_clic

	# Los puntos RUEDAN hasta el número de verdad: rápido si el salto es grande,
	# y nunca más despacio de lo que se lee.
	var d := float(puntos) - _mostrado
	if absf(d) < 1.0:
		_mostrado = float(puntos)
	else:
		var paso := maxf(absf(d) * (1.0 - exp(-7.0 * delta)), minf(absf(d), 900.0 * delta))
		_mostrado += signf(d) * paso
		_brillo_puntos = 1.0
	_brillo_puntos = maxf(_brillo_puntos - delta * 2.5, 0.0)
	if multiplicador > _multi_antes:
		_brillo_multi = 1.0
	_multi_antes = multiplicador
	_brillo_multi = maxf(_brillo_multi - delta * 1.5, 0.0)
	var tapada := bola_pantalla.x >= 0.0 and _aviso_rect.grow(14.0).has_point(bola_pantalla)
	_aviso_tapa = lerpf(_aviso_tapa, 0.55 if tapada else 1.0, 1.0 - exp(-8.0 * delta))

	_elegir_foco(delta)
	var quiere := 1.0 if _consejo_texto != "" else 0.0
	_hueco_consejo = lerpf(_hueco_consejo, quiere, 1.0 - exp(-10.0 * delta))
	_tinta.queue_redraw()

## A quién se le pone el consejo: a la que está más cerca de caer; si ninguna
## destaca, a cada una un rato. Al cambiar, el consejo entra de nuevo.
func _elegir_foco(delta: float) -> void:
	var mejor := -1
	var nivel_mejor := QUIETA
	for i in filas.size():
		var n: int = filas[i].get("nivel", QUIETA)
		if n > nivel_mejor:
			mejor = i
			nivel_mejor = n
	if mejor < 0:
		_foco_t += delta
		if _foco_t > 7.0 or not _sirve_de_foco(_foco):
			_foco_t = 0.0
			for paso in range(1, filas.size() + 1):
				var i := (_foco + paso) % maxi(filas.size(), 1)
				if _sirve_de_foco(i):
					mejor = i
					break
			if mejor < 0:
				mejor = _foco
		else:
			mejor = _foco
	var texto := ""
	if mejor >= 0 and mejor < filas.size() and _sirve_de_foco(mejor):
		texto = str(filas[mejor].get("consejo", "")).to_upper()
		# Con el nombre delante: la línea va debajo de las TRES filas, y sin él
		# no se sabía a cuál de las tres le hablaba («TÓCALA CON LA BOLA»: ¿a
		# cuál?). Lo cazó el crítico de jugabilidad en la segunda mirada.
		if texto != "":
			texto = "%s · %s" % [str(filas[mejor].get("nombre", "")).to_upper(), texto]
	if mejor != _foco or texto != _consejo_texto:
		_consejo_a = 0.0
	_foco = maxi(mejor, 0)
	_consejo_texto = texto
	_consejo_a = minf(_consejo_a + delta * 3.0, 1.0)

func _sirve_de_foco(i: int) -> bool:
	if i < 0 or i >= filas.size():
		return false
	var n: int = filas[i].get("nivel", QUIETA)
	return n >= QUIETA

# ------------------------------------------------------------- dibujar

func _dibujar() -> void:
	var lienzo := size
	_cajas.clear()
	_fuerzas.clear()
	_dibujar_caza()
	_dibujar_vista(lienzo)
	_dibujar_aviso(lienzo)
	_dibujar_campana(lienzo)
	_dibujar_puntos(lienzo)
	_dibujar_teclas(lienzo)
	_dibujar_clic(lienzo)
	_dibujar_ayuda(lienzo)
	_dibujar_sello(lienzo)
	var m := _sombra.material as ShaderMaterial
	while _cajas.size() < 8:
		_cajas.append(Vector4.ZERO)
		_fuerzas.append(0.0)
	m.set_shader_parameter("tam", lienzo)
	m.set_shader_parameter("cajas", PackedVector4Array(_cajas))
	m.set_shader_parameter("fuerzas", PackedFloat32Array(_fuerzas))

## Una penumbra detrás de un bloque. Ocho como mucho: las del sombreador.
func _penumbra(r: Rect2, fuerza: float) -> void:
	if fuerza <= 0.01 or _cajas.size() >= 8:
		return
	_cajas.append(Vector4(r.position.x, r.position.y, r.size.x, r.size.y))
	_fuerzas.append(fuerza)

## Lo que mide un texto. El espaciado entre letras también se pone detrás de la
## última, y alineando a la derecha eso deja un hueco: se descuenta.
func _ancho(f: FontVariation, cuerpo: int, texto: String) -> float:
	return f.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1.0, cuerpo).x \
		- float(f.spacing_glyph)

## Escribe con sombra fina y devuelve el ancho. `alinear`: 0 izquierda, 1
## derecha, 2 centro, respecto a `pos.x`. `pos.y` es la línea base.
func _texto(f: FontVariation, cuerpo: int, pos: Vector2, texto: String, col: Color,
		alinear: int = 0, densidad: float = 0.32) -> float:
	if texto == "" or col.a <= 0.005:
		return _ancho(f, cuerpo, texto)
	var w := _ancho(f, cuerpo, texto)
	var x := pos.x
	if alinear == 1:
		x -= w
	elif alinear == 2:
		x -= w * 0.5
	var p := Vector2(x, pos.y)
	var halo := Color(0.0, 0.0, 0.0, densidad * col.a)
	_tinta.draw_string_outline(f, p, texto, HORIZONTAL_ALIGNMENT_LEFT, -1.0, cuerpo,
		maxi(int(cuerpo * 0.25), 2), halo)
	_tinta.draw_string(f, p + Vector2(0.0, 1.0), texto, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
		cuerpo, Color(0.0, 0.0, 0.0, 0.7 * col.a))
	_tinta.draw_string(f, p, texto, HORIZONTAL_ALIGNMENT_LEFT, -1.0, cuerpo, col)
	return w

func _raya(desde: Vector2, hasta: Vector2, col: Color, grueso: float = 1.0) -> void:
	_tinta.draw_line(desde + Vector2(0.0, 1.0), hasta + Vector2(0.0, 1.0),
		Color(0.0, 0.0, 0.0, 0.5 * col.a), grueso)
	_tinta.draw_line(desde, hasta, col, grueso)

## Una raya que se apaga por las puntas: los filetes del aviso.
func _filete(centro: Vector2, largo: float, col: Color) -> void:
	if largo < 1.0:
		return
	var a := Vector2(centro.x - largo * 0.5, centro.y)
	var b := Vector2(centro.x + largo * 0.5, centro.y)
	var sin_color := Color(col.r, col.g, col.b, 0.0)
	_tinta.draw_polyline_colors(PackedVector2Array([a, centro, b]),
		PackedColorArray([sin_color, col, sin_color]), 1.0, true)

## El rombo de color de cada criatura.
func _rombo(c: Vector2, r: float, col: Color, lleno: bool) -> void:
	var p := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r),
		c + Vector2(-r, 0)])
	if lleno:
		_tinta.draw_colored_polygon(p, col)
	else:
		p.append(p[0])
		_tinta.draw_polyline(p, col, 1.0, true)

func _pulso(rapidez: float = 5.0) -> float:
	return 0.5 + 0.5 * sin(_t * rapidez)

# --------------------------------------------------------- los bloques

## LA CAZA: el objetivo, arriba a la izquierda, con su raya vertical. Una fila
## por criatura y, debajo de las tres, el consejo de la que toca.
func _dibujar_caza() -> void:
	_caza_lineas.clear()
	var x := MARGEN + 11.0
	var y := ARRIBA + 7.0
	var der := x
	var activas := 0
	var hechas := 0
	for fila: Dictionary in filas:
		var n: int = fila.get("nivel", QUIETA)
		if n != FUERA:
			activas += 1
		if n == ASEGURADA:
			hechas += 1
	# La cuenta va detrás de otro «·»: con un hueco a secas, a 1280×720
	# «OLA 1   0 / 3» se leía «OLA 10 / 3».
	# El espacio del final no cuenta al medir un texto: se suma aparte.
	var cabecera := "CAZA · OLA %d ·" % ola
	_texto(_letra_rotulo, PEQ, Vector2(x, y), cabecera, TENUE)
	var espacio := _ancho(_letra_rotulo, PEQ, "A A") - _ancho(_letra_rotulo, PEQ, "AA")
	var cuenta_x := x + _ancho(_letra_rotulo, PEQ, cabecera) 		+ 2.0 * float(_letra_rotulo.spacing_glyph) + espacio
	der = maxf(der, cuenta_x + _texto(_letra_rotulo, PEQ, Vector2(cuenta_x, y),
		"%d / %d" % [hechas, activas], MARFIL if hechas > 0 else TENUE))
	_caza_lineas.append(Vector3(y - 9.0, y + 2.0, der))
	y += 19.0
	for i in filas.size():
		var fila: Dictionary = filas[i]
		var n: int = fila.get("nivel", QUIETA)
		var propio: Color = fila.get("color", MARFIL)
		var alfa := 1.0
		if n == FUERA:
			alfa = 0.3
		elif n == ASEGURADA:
			alfa = 0.45
		var llama := n == LLAMA
		var latido := _pulso(7.0) if llama else 0.0
		var marca := propio
		marca.a = alfa
		_rombo(Vector2(x + 3.5, y - 4.5), 3.5 + latido * 1.2, marca, n != ASEGURADA)
		var nombre_col := MARFIL
		nombre_col.a = alfa
		var xn := x + 13.0
		var wn := _texto(_letra_nombre, MED, Vector2(xn, y), str(fila.get("nombre", "")),
			nombre_col)
		var estado_col := TENUE
		if llama:
			estado_col = ORO.lerp(MARFIL, latido * 0.6)
		elif n == VIVA:
			estado_col = propio.lerp(MARFIL, 0.25)
		estado_col.a = alfa
		var xe := xn + wn + 9.0
		var fin := xe + _texto(_letra_rotulo, PEQ, Vector2(xe, y),
			str(fila.get("estado", "")), estado_col)
		der = maxf(der, fin)
		_caza_lineas.append(Vector3(y - 11.0, y + 2.0, fin))
		y += 18.0
	var alto := y - 18.0 + 5.0
	# EL CONSEJO, en su línea, con el rombo (pequeño y hueco) de la criatura a la
	# que se refiere: así se sabe de quién habla sin repetir el nombre.
	if _hueco_consejo > 0.02 and _foco < filas.size():
		var c := TENUE
		c.a = 0.9 * minf(_hueco_consejo, _consejo_a)
		var propio: Color = filas[_foco].get("color", MARFIL)
		propio.a = c.a
		var yc := y - 2.0
		_rombo(Vector2(x + 3.5, yc - 3.5), 2.5, propio, false)
		var fin := x + 13.0 + _texto(_letra_rotulo, PEQ, Vector2(x + 13.0, yc), _consejo_texto, c)
		der = maxf(der, fin)
		alto += 16.0 * _hueco_consejo
	_raya(Vector2(MARGEN, ARRIBA - 4.0), Vector2(MARGEN, alto), Color(ORO.r, ORO.g, ORO.b, 0.8), 1.5)
	_penumbra(Rect2(MARGEN, ARRIBA - 6.0, der - MARGEN, alto - ARRIBA + 6.0), 0.45)

## LA CÁMARA Y LA CALIDAD: arriba a la derecha, solo un momento al cambiarlas.
func _dibujar_vista(lienzo: Vector2) -> void:
	# Con la ayuda abierta, lo que ocupa la esquina es el panel: el aviso no
	# puede pasar de su borde.
	_vista_izq = lienzo.x - MARGEN - _ancho_ayuda() if _ayuda else lienzo.x
	if _ayuda or _vista_t > 2.6:
		return
	var a := clampf(_vista_t / 0.2, 0.0, 1.0) * clampf((2.6 - _vista_t) / 0.5, 0.0, 1.0)
	var x := lienzo.x - MARGEN - 11.0
	var y := ARRIBA + 7.0
	var w1 := _texto(_letra_rotulo, PEQ, Vector2(x, y), "CÁMARA · " + _vista,
		Color(MARFIL.r, MARFIL.g, MARFIL.b, a), 1)
	var w2 := _texto(_letra_rotulo, PEQ, Vector2(x, y + 13.0), "GRÁFICOS · " + _calidad,
		Color(TENUE.r, TENUE.g, TENUE.b, a), 1)
	_raya(Vector2(lienzo.x - MARGEN, ARRIBA - 4.0), Vector2(lienzo.x - MARGEN, y + 17.0),
		Color(ORO.r, ORO.g, ORO.b, 0.8 * a), 1.5)
	_vista_izq = x - maxf(w1, w2)
	_penumbra(Rect2(_vista_izq, ARRIBA - 6.0, lienzo.x - MARGEN - _vista_izq, 30.0), 0.45 * a)

## EL AVISO: centrado arriba, entre dos filetes que se abren desde el medio. Si
## no cabe entre la caza y la esquina de la derecha, va en dos líneas: bajar de
## cuerpo lo haría más pequeño que lo que pisa.
##
## Cae sobre lo más iluminado de la imagen —el ábside con las velas y el rayo de
## luna—, así que la letra va SIEMPRE en marfil, con un halo denso y una
## penumbra más fuerte que la de las esquinas, ancha hasta los filetes. El color
## del suceso (el oro, el de la criatura, el rojo) va en los filetes y en el
## rombo del medio: en el texto, el violeta del espectro no se leía sobre la
## piedra dorada.
func _dibujar_aviso(lienzo: Vector2) -> void:
	_aviso_rect = Rect2()
	if _aviso_texto == "" or _aviso_t > _aviso_dura:
		return
	# Se prueba en una línea y, si no cabe, en dos. El hueco se mide contra los
	# renglones de la caza que caen A LA ALTURA del aviso (la cabecera y la
	# primera fila; el consejo va más abajo), y contra lo que haya en la esquina
	# de la derecha. Se mide cada fotograma: si una fila crece mientras el aviso
	# está en pantalla, el aviso se parte antes que pisarla.
	var der_ocupado := lienzo.x - _vista_izq
	var cabe_una := _ancho(_letra_aviso, MED, _aviso_texto)
	_aviso = PackedStringArray([_aviso_texto])
	if cabe_una > _hueco_aviso(lienzo, 1, der_ocupado):
		_aviso = _partir(_aviso_texto)
	var entra := clampf(_aviso_t / 0.25, 0.0, 1.0)
	var sale := clampf((_aviso_dura - _aviso_t) / 0.5, 0.0, 1.0)
	var a := entra * sale * _aviso_tapa
	var abre := 1.0 - pow(1.0 - clampf(_aviso_t / 0.4, 0.0, 1.0), 3.0)
	var cx := lienzo.x * 0.5
	var y_filete := ARRIBA_AVISO
	var y := y_filete + 15.0
	var ancho := 0.0
	for linea in _aviso:
		ancho = maxf(ancho, _ancho(_letra_aviso, MED, linea))
	# Lo que solo informa («NO LLEGA», «SE ESCAPÓ») sigue más apagado que lo que
	# se celebra.
	var col := MARFIL if _aviso_col != TENUE else TENUE.lerp(MARFIL, 0.4)
	col.a = a
	var tono := _aviso_col.lerp(MARFIL, 0.15)
	var filete := Color(tono.r, tono.g, tono.b, 0.9 * a)
	var largo := ancho + 70.0
	var y_bajo := y + RENGLON_AVISO * float(_aviso.size() - 1) + 6.0
	_penumbra(Rect2(cx - largo * 0.5, y_filete - 3.0, largo, y_bajo - y_filete + 6.0), 0.72 * a)
	_filete(Vector2(cx, y_filete), largo * abre, filete)
	_rombo(Vector2(cx, y_filete), 3.0 * abre, Color(tono.r, tono.g, tono.b, a), true)
	for linea in _aviso:
		_texto(_letra_aviso, MED, Vector2(cx, y), linea, col, 2, 0.55)
		y += RENGLON_AVISO
	_filete(Vector2(cx, y_bajo), largo * abre, filete)
	_aviso_rect = Rect2(cx - largo * 0.5, y_filete - 4.0, largo, y_bajo - y_filete + 8.0)

## El hueco que le queda al aviso, en `lineas` líneas, entre la caza y lo que
## ocupe la esquina de la derecha. Es simétrico: el aviso va centrado.
func _hueco_aviso(lienzo: Vector2, lineas: int, der_ocupado: float) -> float:
	var arriba := ARRIBA_AVISO - AIRE_AVISO_ALTO
	var abajo := ARRIBA_AVISO + 15.0 + RENGLON_AVISO * float(lineas - 1) + 6.0 + AIRE_AVISO_ALTO
	var izq := MARGEN
	for r: Vector3 in _caza_lineas:
		if r.x < abajo and r.y > arriba:
			izq = maxf(izq, r.z)
	return lienzo.x - 2.0 * (maxf(izq, der_ocupado) + AIRE_AVISO)

## Parte el aviso por el «·» que deje las dos mitades más iguales; si no hay, por
## el espacio más centrado.
func _partir(texto: String) -> PackedStringArray:
	var sep := " · "
	var trozos := texto.split(sep)
	if trozos.size() < 2:
		sep = " "
		trozos = texto.split(sep)
	if trozos.size() < 2:
		return PackedStringArray([texto])
	var mejor := PackedStringArray([texto])
	var peor_mejor := 1.0e9
	for corte in range(1, trozos.size()):
		var a := sep.join(trozos.slice(0, corte))
		var b := sep.join(trozos.slice(corte))
		var peor := maxf(_ancho(_letra_aviso, MED, a), _ancho(_letra_aviso, MED, b))
		if peor < peor_mejor:
			peor_mejor = peor
			mejor = PackedStringArray([a, b])
	return mejor

## LA CAMPANA MAYOR: abajo a la izquierda. Una barra fina que se llena; armada,
## entera en oro y latiendo; tocando, se vacía con los segundos que le quedan.
## La línea de debajo dice siempre qué hacer con ella.
func _dibujar_campana(lienzo: Vector2) -> void:
	var x0 := MARGEN
	var x1 := MARGEN + _ancho_esquina(lienzo)
	var y_alto := lienzo.y - ABAJO - 19.0
	var y_barra := lienzo.y - ABAJO - 11.0
	var y_bajo := lienzo.y - ABAJO
	var estado := "%d %%" % roundi(carga * 100.0)
	var estado_col := TENUE
	var lleno := carga
	var barra := Color(MARFIL.r, MARFIL.g, MARFIL.b, 0.7)
	var pie := "SE CARGA EN LAS RAMPAS"
	var pie_col := Color(TENUE.r, TENUE.g, TENUE.b, 0.8)
	var brillo := 0.0
	if tocando > 0.0:
		estado = "TOCA"
		estado_col = ORO
		lleno = tocando
		barra = ORO.lerp(MARFIL, 0.35 * _pulso(12.0))
		pie = "TODO VALE DOBLE"
		pie_col = ORO
		brillo = 0.35
	elif armada:
		var latido := _pulso(5.0)
		estado = "ARMADA"
		estado_col = ORO
		lleno = 1.0
		barra = Color(ORO.r, ORO.g, ORO.b, 0.6 + 0.4 * latido)
		pie = "COMPLETA UN RECORRIDO"
		pie_col = ORO.lerp(MARFIL, 0.3 * latido)
		brillo = 0.12 + 0.2 * latido
	elif carga >= 1.0:
		# Al perder una bola con la campana armada, la mesa la desarma pero le
		# deja la carga entera: una barra llena no puede decir «se carga». La
		# siguiente rampa la vuelve a armar (`Mesa`, al sumar carga).
		estado = "LLENA"
		estado_col = MARFIL
		pie = "UNA RAMPA LA ARMA"
	_texto(_letra_rotulo, PEQ, Vector2(x0, y_alto), rotulo_campana, MARFIL)
	_texto(_letra_rotulo, PEQ, Vector2(x1, y_alto), estado, estado_col, 1)
	_tinta.draw_line(Vector2(x0, y_barra), Vector2(x1, y_barra),
		Color(TENUE.r, TENUE.g, TENUE.b, 0.28), 2.0)
	if brillo > 0.0:
		_tinta.draw_line(Vector2(x0, y_barra), Vector2(x0 + (x1 - x0) * lleno, y_barra),
			Color(ORO.r, ORO.g, ORO.b, brillo), 6.0)
	if lleno > 0.0:
		_tinta.draw_line(Vector2(x0, y_barra), Vector2(x0 + (x1 - x0) * lleno, y_barra),
			barra, 2.0)
	_texto(_letra_rotulo, PEQ, Vector2(x0, y_bajo), pie, pie_col)
	_penumbra(Rect2(x0, y_alto - 9.0, x1 - x0, y_bajo - y_alto + 11.0), 0.45)

## LOS PUNTOS: abajo a la derecha. El número rueda; debajo, el combo se gasta
## en una raya fina, y la bola y el multiplicador.
func _dibujar_puntos(lienzo: Vector2) -> void:
	var x1 := lienzo.x - MARGEN
	var x0 := x1 - _ancho_esquina(lienzo)
	var y_alto := lienzo.y - ABAJO - 19.0
	var y_barra := lienzo.y - ABAJO - 11.0
	var y_bajo := lienzo.y - ABAJO
	var col := MARFIL.lerp(ORO, 0.55 * _brillo_puntos)
	var w := _texto(_letra_cifra, GRA, Vector2(x1, y_alto + 1.0), _miles(roundi(_mostrado)),
		col, 1)
	_tinta.draw_line(Vector2(x0, y_barra), Vector2(x1, y_barra),
		Color(TENUE.r, TENUE.g, TENUE.b, 0.28), 2.0)
	if combo > 0.0:
		_tinta.draw_line(Vector2(x0, y_barra), Vector2(x0 + (x1 - x0) * combo, y_barra),
			ORO, 2.0)
	var izq := "BOLA %d" % bola
	var wb := _texto(_letra_rotulo, PEQ, Vector2(x0, y_bajo), izq, MARFIL)
	if piloto:
		_texto(_letra_rotulo, PEQ, Vector2(x0 + wb + 12.0, y_bajo), "PILOTO", TENUE)
	if multiplicador > 1:
		var mc := ORO.lerp(MARFIL, 0.6 * _brillo_multi)
		_texto(_letra_aviso, MED, Vector2(x1, y_bajo + 1.0), "×%d" % multiplicador, mc, 1)
	else:
		_texto(_letra_rotulo, PEQ, Vector2(x1, y_bajo), "×1", TENUE, 1)
	var izquierda := minf(x0, x1 - w)
	_penumbra(Rect2(izquierda, y_alto - 22.0, x1 - izquierda, y_bajo - y_alto + 24.0), 0.45)

## Lo que mide un bloque de abajo: en una ventana ancha, lo de siempre; a 16:9,
## lo justo para no llegar a las esquinas de la mesa.
func _ancho_esquina(lienzo: Vector2) -> float:
	return clampf(lienzo.x * 0.16, ANCHO_ESQUINA_MIN, ANCHO_ESQUINA)

## 1234567 → «1.234.567».
func _miles(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out

## LAS TECLAS: debajo del sello de lugar, a la izquierda y a media altura, en
## cuatro renglones, y se van solas a los pocos segundos de empezar a jugar.
## Antes iban en una línea abajo en el centro y caían enteras encima del
## delantal de la mesa, justo donde se miran las palas; aquí, como en Saltline,
## caen en el suelo de la sala. Con la ayuda abierta o esperando el clic, no.
func _dibujar_teclas(lienzo: Vector2) -> void:
	if _ayuda or falta_clic:
		return
	var a := clampf((_jugando_t - 0.8) / 0.6, 0.0, 1.0) 		* clampf((7.5 - _jugando_t) / 1.5, 0.0, 1.0)
	if a <= 0.0:
		return
	var x := MARGEN + 3.0
	var y := _y_sello(lienzo) + 50.0
	var y0 := y
	var ancho := 0.0
	# La segunda columna empieza donde acaba la tecla más ancha: con la letra de
	# reserva de la web, que no es condensada, «ESPACIO» llegaba hasta «LANZAR».
	var columna := 54.0
	for par: Array in TECLAS_CORTAS:
		columna = maxf(columna, _ancho(_letra_rotulo, PEQ, str(par[0])) + 10.0)
	for par: Array in TECLAS_CORTAS:
		_texto(_letra_rotulo, PEQ, Vector2(x, y), str(par[0]),
			Color(MARFIL.r, MARFIL.g, MARFIL.b, 0.8 * a))
		ancho = maxf(ancho, columna + _texto(_letra_rotulo, PEQ, Vector2(x + columna, y),
			str(par[1]), Color(TENUE.r, TENUE.g, TENUE.b, 0.8 * a)))
		y += 13.0
	_penumbra(Rect2(x, y0 - 9.0, ancho, y - y0), 0.35 * a)

## EN WEB, mientras falta el primer clic: el cartel, con su fondo, abajo en el
## centro. Suelto no vale: caería sobre la mesa y lo cruzaría lo que haya debajo.
func _dibujar_clic(lienzo: Vector2) -> void:
	if not falta_clic:
		return
	var texto := "HAZ CLIC O PULSA UNA TECLA PARA JUGAR"
	var w := _ancho(_letra_nombre, MED, texto)
	var r := Rect2((lienzo.x - w) * 0.5 - 18.0, lienzo.y - ABAJO - 26.0, w + 36.0, 28.0)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.03, 0.02, 0.02, 0.82)
	fondo.border_color = Color(ORO.r, ORO.g, ORO.b, 0.45 + 0.25 * _pulso(4.0))
	fondo.set_border_width_all(1)
	fondo.set_corner_radius_all(2)
	_tinta.draw_style_box(fondo, r)
	_texto(_letra_nombre, MED, Vector2(lienzo.x * 0.5, r.position.y + 19.0), texto,
		MARFIL.lerp(ORO, 0.25 * _pulso(4.0)), 2)

## Con la letra de reserva de la web, que es más ancha, el renglón «BRASA ·
## CALAVERA · ESPECTRO» tocaba el borde del panel: allí va un poco más ancho.
func _ancho_ayuda() -> float:
	return ANCHO_AYUDA + (22.0 if web else 0.0)

## LA AYUDA (H): un panel a la derecha, con su fondo, entre la esquina de arriba
## y los puntos. Las teclas, las cuentas, la cámara y la calidad.
func _dibujar_ayuda(lienzo: Vector2) -> void:
	if not _ayuda:
		return
	var ancho := _ancho_ayuda()
	var x1 := lienzo.x - MARGEN
	var x0 := x1 - ancho
	var y := ARRIBA + 8.0
	var paso := 12.5
	var teclas: Array = TECLAS.duplicate()
	if not web:
		teclas.append(["F12", "CAPTURA"])
	var alto := 14.0 + 16.0 + teclas.size() * paso + 12.0 + 16.0 + cuentas.size() * paso \
		+ 12.0 + 2.0 * paso + 6.0
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.025, 0.02, 0.018, 0.8)
	fondo.border_color = Color(ORO.r, ORO.g, ORO.b, 0.22)
	fondo.set_border_width_all(1)
	fondo.set_corner_radius_all(2)
	_tinta.draw_style_box(fondo, Rect2(x0, ARRIBA - 4.0, ancho, alto))
	var xi := x0 + 14.0
	var xc := xi + 46.0
	var xd := x1 - 14.0
	y += 6.0
	_texto(_letra_rotulo, PEQ, Vector2(xi, y), "TECLAS", ORO)
	y += 16.0
	for par: Array in teclas:
		_texto(_letra_panel, PEQ, Vector2(xi, y), str(par[0]), MARFIL)
		_texto(_letra_panel, PEQ, Vector2(xc, y), str(par[1]), TENUE)
		y += paso
	y += 12.0
	_raya(Vector2(xi, y - 14.0), Vector2(xd, y - 14.0), Color(TENUE.r, TENUE.g, TENUE.b, 0.3))
	_texto(_letra_rotulo, PEQ, Vector2(xi, y), "CUENTAS", ORO)
	y += 16.0
	for par: Array in cuentas:
		_texto(_letra_panel, PEQ, Vector2(xi, y), str(par[0]), TENUE)
		_texto(_letra_panel, PEQ, Vector2(xd, y), str(par[1]), MARFIL, 1)
		y += paso
	y += 12.0
	_raya(Vector2(xi, y - 14.0), Vector2(xd, y - 14.0), Color(TENUE.r, TENUE.g, TENUE.b, 0.3))
	_texto(_letra_panel, PEQ, Vector2(xi, y), "CÁMARA", TENUE)
	_texto(_letra_panel, PEQ, Vector2(xd, y), _vista, MARFIL, 1)
	y += paso
	_texto(_letra_panel, PEQ, Vector2(xi, y), "GRÁFICOS", TENUE)
	_texto(_letra_panel, PEQ, Vector2(xd, y), _calidad, MARFIL, 1)

## EL SELLO DE LUGAR, como el de Saltline: al empezar, a la izquierda, aparece,
## se queda un momento y se va. Fuera de eso no hay título en pantalla.
func _dibujar_sello(lienzo: Vector2) -> void:
	var a := clampf((_t - 0.4) / 0.9, 0.0, 1.0) * clampf((5.6 - _t) / 1.4, 0.0, 1.0)
	if a <= 0.0:
		return
	var x := MARGEN + 2.0 + 6.0 * (1.0 - a)
	var y := _y_sello(lienzo)
	var w := _texto(_letra_sello, GRA, Vector2(x, y), "CRIPTA",
		Color(MARFIL.r, MARFIL.g, MARFIL.b, 0.92 * a))
	_raya(Vector2(x + 1.0, y + 9.0), Vector2(x + 1.0 + 44.0 * a, y + 9.0),
		Color(ORO.r, ORO.g, ORO.b, 0.85 * a), 1.5)
	_texto(_letra_rotulo, PEQ, Vector2(x + 1.0, y + 24.0), "MESA DE PRUEBA 3D",
		Color(TENUE.r, TENUE.g, TENUE.b, a))
	_penumbra(Rect2(x, y - 24.0, w, 50.0), 0.4 * a)

## La altura del sello (y de las teclas, que van debajo): algo por encima de la
## mitad, porque la mesa se estrecha hacia arriba. A 4:3, a media altura, la «A»
## de CRIPTA tocaba el borde de piedra de la mesa.
func _y_sello(lienzo: Vector2) -> float:
	return roundf(lienzo.y * 0.45)
