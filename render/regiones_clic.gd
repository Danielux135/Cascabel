class_name RegionesClic
extends RefCounted

## DÓNDE SE PUEDE PULSAR. Antes de esto el ratón solo movía el puntero y servía
## para el tooltip de las reliquias: no había ni una región pulsable en todo el
## juego, así que el sistema operativo era un decorado.
##
## NO ES UN GESTOR DE VENTANAS y no lo va a ser (invariante de `CLAUDE.md`).
## Esto no arrastra, no redimensiona, no da foco y no apila: solo dice qué hay
## debajo del ratón. Los paneles siguen en posiciones fijas.
##
## POR QUÉ VA CON PROVEEDORES Y NO CON UNA LISTA QUE SE RELLENA AL DIBUJAR.
## La tentación es que cada nodo apunte sus rectángulos dentro de `_draw` y que
## el ratón consulte esa lista. Eso ata el ratón al ORDEN DE FOTOGRAMA: el input
## de Godot se procesa ANTES que el dibujo, así que el primer clic de cada
## fotograma pregunta por la lista del fotograma anterior. Con menús que se
## abren y se cierran, eso es un clic que cae en un botón que ya no está — y no
## da error, simplemente hace lo que no querías. Aquí cada dueño registra una
## FUNCIÓN que calcula sus regiones cuando se le pregunta, así que la respuesta
## siempre es la de ahora mismo. Cuesta unas decenas de comprobaciones de
## rectángulo por evento de ratón, que es nada.
##
## Y la geometría sigue viviendo donde vivía: quien registra devuelve rectángulos
## calculados con las mismas funciones con las que dibuja (`NodoCascara.
## caja_icono`, `panel_enemigo`...), nunca con números copiados. Dos sitios
## midiendo la misma pantalla es la avería que ya costó una sesión.

class Region extends RefCounted:
	var id: String = ""
	var caja: Rect2 = Rect2()
	## Lo que se enseña al pasar por encima. "" = sin tooltip.
	var ayuda: String = ""

	func _init(el_id: String, la_caja: Rect2, la_ayuda: String = "") -> void:
		id = el_id
		caja = la_caja
		ayuda = la_ayuda

## Proveedores, con la capa en la que dibuja cada uno. La capa es la MISMA que la
## del nodo que dibuja (ver la tabla de capas de `CLAUDE.md`), para que lo que se
## ve encima sea lo que se pulsa. Si aquí se pusiera otro número, el jugador
## pulsaría una cosa y le respondería la de debajo.
var _proveedores: Array = []

func registrar(capa: int, fn: Callable) -> void:
	_proveedores.append({"capa": capa, "fn": fn})
	# De más alta a más baja: la de delante contesta primero.
	_proveedores.sort_custom(func(a, b): return int(a["capa"]) > int(b["capa"]))

func olvidar_todo() -> void:
	_proveedores.clear()

## Todas las regiones de ahora mismo, de delante a atrás. Público para la prueba:
## sin esto no hay forma de comprobar que dos botones no se solapan, y dos
## botones solapados no dan error, solo hacen lo que no toca.
func todas() -> Array:
	var lista: Array = []
	for prov in _proveedores:
		var fn: Callable = prov["fn"]
		if not fn.is_valid():
			continue
		var trozo = fn.call()
		if not (trozo is Array):
			continue
		# Dentro de un mismo proveedor, lo ÚLTIMO registrado es lo último
		# dibujado, o sea lo que está encima: se pregunta al revés.
		for i in range(trozo.size() - 1, -1, -1):
			lista.append(trozo[i])
	return lista

## Qué hay bajo el punto, o "" si nada. Lo de delante gana.
func en(punto: Vector2) -> String:
	for r in todas():
		if (r as Region).caja.has_point(punto):
			return (r as Region).id
	return ""

func region(el_id: String) -> Region:
	for r in todas():
		if (r as Region).id == el_id:
			return r
	return null

# ------------------------------------------------------------------- el estado

## Sobre qué región está el ratón. "" = ninguna.
var encima: String = ""
## Qué región se apretó y sigue apretada. Sirve para dos cosas: dibujar el botón
## hundido, y sobre todo para la regla de abajo.
var apretada: String = ""

func mover(punto: Vector2) -> void:
	encima = en(punto)

## Devuelve la región que se ACTIVA, o "" si el clic no cuenta.
##
## LA REGLA, que es la de cualquier interfaz de verdad y evita el peor fallo de
## ratón: **un botón se activa si sueltas ENCIMA DEL MISMO en el que apretaste.**
## Sin esto, apretar en un sitio, arrastrar y soltar en otro activa el segundo, y
## no hay forma de arrepentirse de un clic. Con "Apagar" en el menú de Inicio eso
## no es un detalle.
func pulsar(punto: Vector2, apretado: bool) -> String:
	var aqui := en(punto)
	encima = aqui
	if apretado:
		apretada = aqui
		return ""
	var soltada := apretada
	apretada = ""
	return aqui if aqui != "" and aqui == soltada else ""
