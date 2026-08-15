class_name NodoHud
extends CanvasLayer

## EL HUD, QUE YA NO ESTÁ ENCIMA DE LA MESA.
##
## Antes era una franja opaca de 70 px pegada al borde de arriba, dentro de los
## 400 px de la mesa. Costaba dos cosas: tapaba la bola en lo alto de la órbita
## —el tiro más largo de la mesa era el único que no se veía, y hubo que
## inventarle a la cámara un `alto_franja_hud` para taparlo—, y hacía que la
## cáscara fuera decorado mientras la información de verdad seguía flotando
## encima del juego.
##
## Ahora escribe DENTRO de los paneles de la banda derecha, que dibuja
## `NodoCascara`: `enemigo.exe` arriba, `jugador.sys` debajo y `ayuda.hlp`
## abajo del todo. Esa banda estaba vacía; la izquierda ya la ocupaban los
## iconos.
##
## EXCEPCIÓN A PROPÓSITO, y es la que decidió Daniel: **el reloj del enemigo se
## queda en la mesa**. No aquí: lo dibuja la cáscara dentro de la barra de título
## de la ventana de la mesa. La razón está medida en el código de la cámara —si
## el reloj no se ve de reojo sin dejar de mirar la bola, el golpe se lee como
## injusto— y la barra de título ya gastaba 16 px pegados al campo sin decir
## nada. Cero píxeles de campo perdidos y sigue en la línea de visión.
##
## Aquí solo queda una cosa dibujada sobre la mesa: el cartel del centro. Y los
## que INTERRUMPEN el juego llevan marco de diálogo de Windows; los avisos que
## salen con la bola viva, no, que un cuadro de diálogo tapa justo lo que hay
## que mirar.

const C_CABINA      := Paleta.CABINA
const C_ORO         := Paleta.ORO
const C_ORO_CLARO   := Paleta.ORO_CLARO
const C_GOMA_LUZ    := Paleta.GOMA_LUZ
const C_TEXTO       := Paleta.TEXTO
const C_TEXTO_TENUE := Paleta.TEXTO_TENUE
const C_VERDE       := Paleta.VERDE
const C_ARCANO      := Paleta.ARCANO
## Para el porcentaje de crítico cuando lo tienes por encima del base.
const C_FUEGO       := Paleta.FUEGO
const C_BLANCO      := Paleta.DESTELLO

## Atrapes tras los cuales se deja de dar la pista de cómo atrapar.
const VECES_PARA_APRENDER := 3

var vista: VistaMesa
var _p: ParametrosCamara
var _fuente: Font
var _lienzo: Node2D

func _init(la_vista: VistaMesa, parametros: ParametrosCamara) -> void:
	vista = la_vista
	_p = parametros
	layer = 10

func _ready() -> void:
	_fuente = FuenteUI.obtener()
	_lienzo = Node2D.new()
	_lienzo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# El marco de diálogo es de nueve trozos y se repite: sin esto saldría
	# estirado, que es lo único que un marco de nueve trozos no puede hacer.
	_lienzo.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_lienzo.draw.connect(_dibujar)
	add_child(_lienzo)

func _process(_delta: float) -> void:
	_lienzo.queue_redraw()

func _barra(rect: Rect2, proporcion: float, color: Color) -> void:
	_lienzo.draw_rect(rect, C_CABINA)
	_lienzo.draw_rect(Rect2(rect.position,
		Vector2(rect.size.x * clampf(proporcion, 0.0, 1.0), rect.size.y)), color)

func _texto(pos: Vector2, txt: String, tam: int, col: Color,
		alineado: int = HORIZONTAL_ALIGNMENT_LEFT, ancho: float = -1.0) -> void:
	_lienzo.draw_string(_fuente, pos, txt, alineado, ancho, tam, col)

## El tamaño más grande, de los que la fuente sabe dibujar nítidos, con el que
## `txt` CABE en `ancho`.
##
## El `width` de `draw_string` recorta sin avisar, y los carteles del centro se
## escribían a 16 px contra los 400 de la mesa: a 16 el avance son 12 px, o sea
## 33 caracteres. "ESPACIO: mantener y soltar para lanzar" tiene 38 y salía
## **"...para l"**, y "MANTÉN A o D PARA ATRAPAR Y APUNTAR" tiene 35 y también.
## Los dos son pistas que se leen una vez y luego estorban, así que bajar de
## tamaño es mejor que acortar el texto: la frase entera enseña más.
##
## Baja por múltiplos de la celda —`FuenteUI.tam` no deja otra cosa— y nunca por
## debajo de 8, que es el tamaño natural: si a 8 tampoco cabe, el problema es el
## texto y hay que verlo cortado para enterarse.
func _tam_que_cabe(txt: String, ancho: float, preferido: int) -> int:
	var t := FuenteUI.tam(preferido)
	while t > FuenteUI.alto():
		if _fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, t).x <= ancho:
			return t
		t -= FuenteUI.alto()
	return FuenteUI.alto()

func _dibujar() -> void:
	var combate := vista.combate
	if combate == null or vista.cascara == null:
		return
	_panel_enemigo(combate)
	_panel_jugador(combate)
	_panel_ayuda()
	# Lo único que sigue dibujándose sobre la mesa. Durante la ruleta se calla:
	# ahí la mesa está apagada a propósito y solo manda la tele.
	if not vista.en_ruleta():
		_dibujar_mensaje(combate)

# ---------------------------------------------------------------- los paneles

## `enemigo.exe`. El retrato lo dibuja `NodoPanelEnemigo` en su propia capa,
## porque lleva shader; aquí va lo que se escribe debajo.
func _panel_enemigo(combate: Combate) -> void:
	var e := combate.enemigo
	if e == null:
		return
	var cascara := vista.cascara
	var d := cascara.interior_panel(cascara.panel_enemigo())
	var pies := cascara.suelo_enemigo()
	var y := pies.y + 18.0

	_texto(Vector2(d.position.x, y), e.nombre, 8, C_TEXTO,
		HORIZONTAL_ALIGNMENT_CENTER, d.size.x)
	var col_enemigo := C_GOMA_LUZ if vista.flash_enemigo <= 0.0 else C_ORO_CLARO
	_barra(Rect2(d.position.x + 8.0, y + 8.0, d.size.x - 16.0, 8.0),
		float(e.vida) / float(maxi(e.vida_maxima, 1)), col_enemigo)
	_texto(Vector2(d.position.x, y + 30.0), "%d/%d" % [e.vida, e.vida_maxima],
		8, C_TEXTO_TENUE, HORIZONTAL_ALIGNMENT_CENTER, d.size.x)
	_estados_del_enemigo(combate, d, y + 44.0)

## LOS ESTADOS, DEBAJO DE LA BARRA DE VIDA. Sin esto el sistema entero no
## existe: `CLAUDE.md` tiene anotado que un efecto que el jugador no ve se
## diagnostica como que falta, y ya costó un run entero de confusión con el
## platillo. Aquí además hace falta el NÚMERO, no solo el icono, porque la gracia
## del veneno es verlo subir mientras aguantas la bola.
##
## Se dibuja donde se MIDE: pegado a la barra de vida del enemigo, que es sobre
## quien actúan, y no en un rincón del escritorio.
func _estados_del_enemigo(combate: Combate, d: Rect2, y: float) -> void:
	var lista := combate.estados.lista()
	if lista.is_empty():
		return
	var x := d.position.x + 8.0
	for a in lista:
		var act := a as Estados.Activo
		if act.def.sobre != "enemigo":
			continue
		var col := _color_de_estado(act.def.color)
		# La barrita se vacía con lo que le queda de vida al estado: es lo que
		# convierte la brasa en una cuenta atrás que se puede jugar.
		var caja := Rect2(x, y - 8.0, 34.0, 12.0)
		_lienzo.draw_rect(caja, Color(col, 0.18))
		var resto := clampf(act.restante / maxf(act.def.duracion, 0.001), 0.0, 1.0)
		_lienzo.draw_rect(
			Rect2(caja.position.x, caja.end.y - 2.0, caja.size.x * resto, 2.0),
			Color(col, 0.9))
		_texto(Vector2(x + 1.0, y), act.def.simbolo, 8, col)
		_texto(Vector2(x, y), str(act.acumulaciones), 8, C_TEXTO,
			HORIZONTAL_ALIGNMENT_RIGHT, 33.0)
		x += 38.0
		if x > d.end.x - 34.0:
			return

## Los colores salen de `Paleta` por NOMBRE, que es lo que trae el JSON de
## estados. Un color suelto aquí sería un `Color("...")` fuera de la paleta, y
## hay una prueba que lo prohíbe.
func _color_de_estado(nombre: String) -> Color:
	match nombre:
		"verde": return C_VERDE
		"azul": return Paleta.AZUL_LUZ
		"fuego": return C_FUEGO
		"oro": return C_ORO_CLARO
		"arcano": return C_ARCANO
	return C_TEXTO

## `jugador.sys`. Vida, lo que llevas hecho con esta bola y la probabilidad de
## crítico. Las tres cosas que antes ocupaban la franja de arriba de la mesa.
func _panel_jugador(combate: Combate) -> void:
	var cascara := vista.cascara
	var d := cascara.interior_panel(cascara.panel_jugador())
	var x := d.position.x + 8.0
	var ancho := d.size.x - 16.0
	var col_jugador := C_VERDE if vista.flash_jugador <= 0.0 else C_GOMA_LUZ

	# CONTRA `vida_maxima()`, NO contra `p.vida_jugador`. Aquí llegó a estar el
	# parámetro, que es la vida DE PARTIDA y no cuenta lo que suman las
	# reliquias: con una que subiera el techo salía "215/180" y la barra se
	# pasaba de largo. El dato estaba bien; el denominador, no.
	var maxima := combate.vida_maxima()
	_texto(Vector2(x, d.position.y + 14.0), "VIDA", 8, C_TEXTO)
	_texto(Vector2(x, d.position.y + 14.0), "%d/%d" % [combate.vida_jugador, maxima],
		8, C_TEXTO, HORIZONTAL_ALIGNMENT_RIGHT, ancho)
	_barra(Rect2(x, d.position.y + 20.0, ancho, 8.0),
		float(combate.vida_jugador) / float(maxi(maxima, 1)), col_jugador)

	_texto(Vector2(x, d.position.y + 50.0), "ESTA BOLA", 8, C_TEXTO_TENUE)
	_texto(Vector2(x, d.position.y + 50.0), "%d" % combate.dano_de_la_bola, 8,
		C_ORO_CLARO if combate.dano_de_la_bola > 0 else C_TEXTO_TENUE,
		HORIZONTAL_ALIGNMENT_RIGHT, ancho)
	_texto(Vector2(x, d.position.y + 66.0), "golpes", 8, C_TEXTO_TENUE)
	_texto(Vector2(x, d.position.y + 66.0), "%d" % combate.golpes, 8, C_TEXTO,
		HORIZONTAL_ALIGNMENT_RIGHT, ancho)

	# La probabilidad de crítico, escrita. Un porcentaje que no se ve no existe:
	# el jugador vería números grandes de vez en cuando y creería que el daño es
	# aleatorio, en vez de leer que tiene una estadística que puede subir.
	var critico := combate.prob_critico()
	var sube := critico > combate.p.prob_critico
	_texto(Vector2(x, d.position.y + 86.0), "CRÍTICO", 8,
		C_FUEGO if sube else C_TEXTO_TENUE)
	_texto(Vector2(x, d.position.y + 86.0), "%d%%" % int(round(critico * 100.0)),
		8, C_FUEGO if sube else C_TEXTO_TENUE, HORIZONTAL_ALIGNMENT_RIGHT, ancho)

## `ayuda.hlp`. Las teclas, que estaban escritas en el pie de la mesa comiéndose
## una línea de campo. Aquí no molestan a nadie y siguen a la vista.
func _panel_ayuda() -> void:
	var cascara := vista.cascara
	var d := cascara.interior_panel(cascara.panel_ayuda())
	var x := d.position.x + 8.0
	_texto(Vector2(x, d.position.y + 14.0), "A / D  flippers", 8, C_TEXTO_TENUE)
	_texto(Vector2(x, d.position.y + 28.0), "ESPACIO  lanzar", 8, C_TEXTO_TENUE)
	_texto(Vector2(x, d.position.y + 42.0), "R  otro run", 8, C_TEXTO_TENUE)

# ----------------------------------------------------------- sobre la mesa

## El cartel del centro. Lo que interrumpe lleva marco de diálogo; lo que sale
## con la bola viva va como texto suelto, porque un cuadro de diálogo encima de
## la mesa tapa justo lo que hay que mirar.
func _dibujar_mensaje(combate: Combate) -> void:
	var mesa := vista.mesa
	var texto := ""
	var col := C_TEXTO
	var interrumpe := false
	match combate.fase:
		Combate.Fase.LANZANDO:
			if mesa.bola.viva and mesa.bola.en_carril:
				texto = "ESPACIO: mantener y soltar para lanzar"
				col = C_TEXTO_TENUE
		Combate.Fase.BOLA_VIVA:
			# El golpe del reloj no para el juego, así que el aviso es lo único
			# que lo anuncia. Sin esto se lee como un mordisco de la nada.
			if combate.reloj_restante() <= combate.p.reloj_aviso:
				texto = "ATAQUE EN %d" % int(ceil(combate.reloj_restante()))
				col = C_ORO_CLARO
			elif mesa.flipper_atrapando != null:
				texto = "BOLA ATRAPADA  ·  SUELTA PARA TIRAR"
				col = C_TEXTO_TENUE
			elif vista.veces_atrapada < VECES_PARA_APRENDER:
				texto = "MANTÉN A o D PARA ATRAPAR Y APUNTAR"
				col = C_TEXTO_TENUE
			# La pista de atrapar VOLVIÓ, y el porqué importa: se quitó cuando
			# el tiro de la cuna subía 40 px y no llegaba a ninguna boca, y
			# enseñar una técnica que no sirve es peor que no enseñar nada.
			# Ahora la cuna alcanza el banco de targets. Se calla a las tres
			# atrapadas: quien ya sabe no necesita que se lo repitan.
		Combate.Fase.DRENADA:
			texto = "BOLA PERDIDA  ·  COMBO A x1"
			col = C_TEXTO_TENUE
		Combate.Fase.RESOLVIENDO_ATAQUE:
			texto = "%s ATACA  -%d" % [
				combate.enemigo.nombre.to_upper(), combate.ultimo_ataque]
			col = C_GOMA_LUZ
			interrumpe = true
		Combate.Fase.VICTORIA:
			texto = "VICTORIA"
			col = C_VERDE
			interrumpe = true
		Combate.Fase.DERROTA:
			texto = "DERROTA"
			col = C_GOMA_LUZ
			interrumpe = true
	if texto == "":
		return

	var franja := vista.cascara.franja_mesa()
	var y := franja.position.y + franja.size.y * 0.5
	if not interrumpe:
		_texto(Vector2(franja.position.x, y), texto,
			_tam_que_cabe(texto, franja.size.x, 16), col,
			HORIZONTAL_ALIGNMENT_CENTER, franja.size.x)
		return

	# Con marco de diálogo. El texto va en negro porque el relleno del marco es
	# el gris claro de Windows: escribirlo en el blanco del resto de la interfaz
	# lo deja ilegible y eso no da ningún error.
	var pide_tecla := combate.fase == Combate.Fase.DERROTA
	var alto := 72.0 if pide_tecla else 56.0
	var caja := Rect2(franja.position.x + 24.0, y - alto * 0.5,
		franja.size.x - 48.0, alto)
	var dentro := vista.cascara.dibujar_dialogo(_lienzo, caja)
	# El nombre del enemigo entra aquí desde el JSON: "GOBLIN CARROÑERO ATACA
	# −8" son 26 caracteres, y uno más largo se comería el cuadro.
	_texto(Vector2(dentro.position.x, dentro.position.y + 26.0), texto,
		_tam_que_cabe(texto, dentro.size.x, 16),
		NodoCascara.C_TEXTO_DIALOGO, HORIZONTAL_ALIGNMENT_CENTER, dentro.size.x)
	# Una tira del color del estado bajo el texto: ata el cartel a lo que ha
	# pasado sin depender de leer la palabra.
	_lienzo.draw_rect(Rect2(dentro.position.x + 8.0, dentro.position.y + 34.0,
		dentro.size.x - 16.0, 2.0), col)
	# Ganar ya no pide tecla: se pasa solo a la ruleta. Perder sí, que ahí se
	# acaba el run y hay que poder leerlo.
	if pide_tecla:
		_texto(Vector2(dentro.position.x, dentro.position.y + 52.0),
			"ENTER para volver al mapa", 8, NodoCascara.C_TEXTO_DIALOGO,
			HORIZONTAL_ALIGNMENT_CENTER, dentro.size.x)
