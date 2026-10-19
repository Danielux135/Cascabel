class_name NodoEncendido
extends CanvasLayer

## LO QUE SOLO EXISTE PORQUE EL JUEGO CORRE EN UN NAVEGADOR: la máquina apagada y
## la pausa al perder el foco. `WEB.md` tiene la auditoría de donde sale.
##
## EN ESCRITORIO NO HACE NADA, y eso es la mitad del diseño: arranca encendida,
## apagar no la apaga y nunca se pausa, así que el juego de escritorio es
## exactamente el de antes. Hay una prueba que lo sujeta.
##
## LA MÁQUINA APAGADA arregla tres cosas de una vez, y ninguna daba error:
## - el navegador no deja sonar nada hasta el primer gesto, así que el arranque
##   se lanzaba en `_ready` contra un audio suspendido, se quedaba "sonando" sin
##   sonar y, como es de las piezas que terminan, no dejaba entrar ni al mapa ni
##   al combate hasta el primer clic más sus 7,84 s;
## - dentro del iframe de itch el teclado no llega al juego hasta que se hace clic
##   en él, y mientras tanto flechas y Espacio desplazan la página;
## - y nada en pantalla decía que había que hacer clic.
## Godot reanuda el audio DENTRO del gesto, antes de que el evento llegue aquí,
## así que lanzar el arranque desde esa primera tecla hace que suene en el acto.
## Y no hace falta salirse de la ficción para pedirlo: es el equipo, que está
## apagado.
##
## Y ES ADONDE VA "APAGAR". En una página, `get_tree().quit()` no cierra nada:
## apaga el motor y deja el lienzo muerto con el último fotograma, mudo y sin un
## mensaje, hasta que se recarga. Aquí apagar deja la máquina apagada, como una de
## verdad, y se vuelve a encender con una tecla.
##
## LA PAUSA. Un clic fuera del juego —en la página de itch, en otra ventana— le
## quita el foco, y el navegador suelta las teclas, así que las palas bajan. Pero
## la bola y el reloj del enemigo seguían, y al volver faltaba vida sin saber por
## qué. Ahora la mesa se congela igual que con una ventana del sistema delante.
##
## Y EL FOCO SE SABE POR EL AVISO, NO PREGUNTANDO, que es justo al revés que la
## música y no por gusto: en web `Window.has_focus()` dice siempre que sí
## (`DisplayServerWeb::window_is_focused` devuelve `true` a pelo en la 4.7.2).
## Escrito preguntando, la pausa no salía nunca, y eso solo se vio en el
## navegador. Lo que sí llega es el `blur` del lienzo, convertido en
## `NOTIFICATION_WM_WINDOW_FOCUS_OUT`. Y para que un aviso perdido no deje la
## mesa en pausa para siempre, cualquier tecla o clic que llegue la quita: si
## llegan al juego, es que el lienzo tiene el foco.
##
## CAPA 50: por encima de TILT (40), porque una máquina apagada tapa también la
## pantalla azul; por debajo del puntero (100).

## Se ha encendido. `reinicio` dice si venía de "Apagar...": ahí lo que hubiera
## en marcha se perdió al apagar, como en una máquina de verdad, y toca un run
## nuevo. La primera vez no, que el run ya está montado detrás.
signal encendido(reinicio: bool)

const C_FONDO := Paleta.CABINA
const C_TEXTO := Paleta.TEXTO
const C_TENUE := Paleta.TEXTO_TENUE
const C_AVISO := Paleta.GOMA_LUZ
const C_ORO   := Paleta.ORO

## Si la máquina está apagada. Solo puede estarlo en web.
var apagado := false
## Si la mesa está en pausa por haber perdido el foco.
var en_pausa := false
## Si el lienzo ha perdido el foco, según el último aviso que ha llegado.
var _sin_foco := false
var _en_web := false
var _veces_apagado := 0
## El clic que enciende (o que devuelve el foco) tiene dos mitades. La de apretar
## se la queda este nodo; la de soltar también, o llegaría sola al sistema.
var _tragar_suelta := false
var _fuente: Font
var _lienzo: Node2D

## `en_web` se puede forzar para probarlo: la batería corre en escritorio.
func _init(en_web: bool = OS.has_feature("web")) -> void:
	_en_web = en_web
	apagado = en_web
	layer = 50
	visible = apagado

func _ready() -> void:
	_fuente = FuenteUI.obtener()
	_lienzo = Node2D.new()
	_lienzo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_lienzo.draw.connect(_dibujar)
	add_child(_lienzo)

## Si la mesa tiene que estar quieta por culpa de este nodo.
func bloquea() -> bool:
	return apagado or en_pausa

## Apaga la máquina. En escritorio no hace nada: ahí "Apagar" cierra la ventana,
## que es lo que se espera de un programa.
func apagar() -> void:
	if not _en_web:
		return
	apagado = true
	en_pausa = false
	_veces_apagado += 1
	visible = true

## SI UN EVENTO ENCIENDE LA MÁQUINA: una tecla que no sea Esc, o un botón del
## ratón de verdad. Ni la rueda ni Esc, y no por gusto: el navegador no cuenta
## ninguno de los dos como gesto del usuario (Godot ni siquiera intenta reanudar
## el audio con la rueda), así que encender con ellos dejaba el arranque sonando
## contra un audio todavía bloqueado, que es justo lo que este nodo arregla. Y la
## rueda llega sola: basta con desplazar la página de itch con el puntero encima.
static func enciende(evento: InputEvent) -> bool:
	var tecla := evento as InputEventKey
	if tecla != null:
		return tecla.pressed and not tecla.echo and tecla.keycode != KEY_ESCAPE \
			and tecla.physical_keycode != KEY_ESCAPE
	var boton := evento as InputEventMouseButton
	if boton != null:
		return boton.pressed and boton.button_index in [
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
	return false

## Lo primero que se pulse con la máquina apagada la enciende. Devuelve si la ha
## encendido, para que quien llama sepa si el evento era suyo.
func pulsar() -> bool:
	if not apagado:
		return false
	apagado = false
	encendido.emit(_veces_apagado > 0)
	return true

func _notification(que: int) -> void:
	if not _en_web:
		return
	if que == NOTIFICATION_WM_WINDOW_FOCUS_OUT or que == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_sin_foco = true
	elif que == NOTIFICATION_WM_WINDOW_FOCUS_IN or que == NOTIFICATION_APPLICATION_FOCUS_IN:
		_sin_foco = false

func _process(_delta: float) -> void:
	if not _en_web:
		return
	en_pausa = not apagado and _sin_foco
	visible = apagado or en_pausa
	if visible and _lienzo != null:
		_lienzo.queue_redraw()

func _input(evento: InputEvent) -> void:
	if not _en_web:
		return
	var boton := evento as InputEventMouseButton
	# Lo que llega es que el lienzo tiene el foco, aunque el aviso se perdiera.
	if evento is InputEventKey or (boton != null and boton.pressed):
		_sin_foco = false
	if boton != null and not boton.pressed and _tragar_suelta:
		_tragar_suelta = false
		get_viewport().set_input_as_handled()
		return
	if apagado:
		if enciende(evento):
			pulsar()
			_tragar_suelta = boton != null
		# CON LA MÁQUINA APAGADA NO PASA NADA MÁS: ni el ratón llega al
		# escritorio ni las teclas al mapa. Una tecla que enciende y además elige
		# rama en el mapa son dos cosas con un gesto.
		get_viewport().set_input_as_handled()
		return
	# EL CLIC QUE DEVUELVE EL FOCO no hace nada más que eso, por lo mismo.
	if en_pausa and boton != null and boton.pressed:
		_tragar_suelta = true
		get_viewport().set_input_as_handled()

func _dibujar() -> void:
	var p := _lienzo.get_viewport_rect().size.ceil()
	var ancho := p.x
	var medio := floorf(p.y * 0.5)
	if apagado:
		_lienzo.draw_rect(Rect2(Vector2.ZERO, p), C_FONDO)
		# Después de "Apagar...", la frase de toda la vida antes de quitarle la
		# corriente al equipo.
		if _veces_apagado > 0:
			_texto(medio - 48.0, "Ya puede apagar el equipo.", 16, C_ORO, ancho)
		_texto(medio, "Pulsa una tecla para encender", 16, C_TEXTO, ancho)
		_texto(medio + 24.0, "o haz clic aquí", 8, C_TENUE, ancho)
		# SI EL NAVEGADOR NO VA A GUARDAR, SE DICE ANTES DE JUGAR. En incógnito, o
		# con las cookies de terceros bloqueadas —el juego va dentro del iframe de
		# otro dominio—, lo recuperado desaparece al recargar, y `Guardado`
		# devuelve un guardado vacío y válido que no se distingue de "primera vez
		# que juegas". La doc de Godot avisa de que esto puede dar falsos
		# positivos; un falso negativo no lo da.
		if not OS.is_userfs_persistent():
			_texto(p.y - 24.0, "aviso: este navegador no guarda la partida (¿modo incógnito?)",
				8, C_AVISO, ancho)
		return
	if en_pausa:
		_lienzo.draw_rect(Rect2(Vector2.ZERO, p), Color(C_FONDO, 0.6))
		_texto(medio, "EN PAUSA", 16, C_TEXTO, ancho)
		_texto(medio + 24.0, "haz clic en el juego para seguir", 8, C_TENUE, ancho)

func _texto(y: float, txt: String, tam: int, col: Color, ancho: float) -> void:
	_lienzo.draw_string(_fuente, Vector2(0.0, floorf(y)), txt,
		HORIZONTAL_ALIGNMENT_CENTER, ancho, tam, col)
