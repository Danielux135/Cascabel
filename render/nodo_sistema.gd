class_name NodoSistema
extends CanvasLayer

## EL SISTEMA OPERATIVO, ahora que se puede pulsar. El menú de Inicio, la carpeta
## `RECUPERADO`, las estadísticas y la papelera.
##
## `PROPÓSITO.md` §2: el propósito del juego es terminar de reconstruir el juego
## que nunca se terminó, y este nodo es donde eso se VE. Sin esto, perder un run
## no dejaba nada en pantalla y no había ninguna frase que empezara por "la
## próxima vez".
##
## SIGUE SIN HABER GESTOR DE VENTANAS. Nada se arrastra, nada se redimensiona,
## no hay foco ni orden de apilado: hay UNA ventana abierta como mucho, en una
## posición fija, y se cierra con su aspa o con ESC. El invariante prohibía el
## gestor, no que las cosas se pulsen.
##
## CAPA 30: por encima del mapa (20), por debajo de TILT (40). TILT es el sistema
## cayéndose, y un sistema que se cae se lleva por delante sus propias ventanas.
##
## Y CONGELA LA MESA MIENTRAS HAY ALGO ABIERTO, igual que la ruleta. No es un
## detalle de comodidad: una ventana de 520 px encima del tablero tapa justo la
## bola, y dejarla viva sería perderla mientras lees. Que un cuadro de diálogo te
## robe el foco a mitad de partida es, además, exactamente la broma.

const C_TEXTO       := Paleta.TEXTO
const C_TEXTO_TENUE := Paleta.TEXTO_TENUE
const C_BLANCO      := Paleta.DESTELLO
const C_VACIO       := Paleta.CABINA
const C_ORO         := Paleta.ORO
const C_ORO_CLARO   := Paleta.ORO_CLARO
const C_VERDE       := Paleta.VERDE
const C_ARCANO      := Paleta.ARCANO
const C_METAL       := Paleta.METAL
const C_GOMA_LUZ    := Paleta.GOMA_LUZ

## El menú. Ancho fijo y alto por entradas: 24 px es la unidad de la barra de
## tareas y el menú tiene que cuadrar con ella.
const ANCHO_MENU := 168.0
const ALTO_ENTRADA := 24.0
const ALTO_SEPARADOR := 6.0

## La ventana. Tamaño fijo, centrada: sin gestor de ventanas no hay nada que
## decidir, y una ventana que cambia de tamaño según lo que enseña se lee como
## un fallo.
const ANCHO_VENTANA := 520.0
const ALTO_VENTANA := 372.0
## Alto de una fila de la lista de ficheros. 36 deja sitio para un icono de 32.
const ALTO_FILA := 36.0

## Las entradas del menú de Inicio, en orden. El identificador es el que se
## enruta; el rótulo es lo que se lee. No pueden ser la misma cadena: es la
## trampa del "COMUN" pintado en pantalla que ya está en `CLAUDE.md`.
const ENTRADAS := [
	{"id": "preparacion", "rotulo": "Nueva partida", "icono": "cascabel"},
	{"id": "recuperado", "rotulo": "Recuperado", "icono": "carpeta"},
	{"id": "maquina", "rotulo": "Mi máquina", "icono": "mi_maquina"},
	{"id": "papelera", "rotulo": "Papelera", "icono": "papelera"},
	{"id": "registro", "rotulo": "Registro", "icono": "registro"},
	{"id": "", "rotulo": "", "icono": ""},
	{"id": "apagar", "rotulo": "Apagar...", "icono": "error"},
]

## Qué icono del escritorio abre qué. Los que no están aquí no hacen nada, como
## la mitad de los iconos de un escritorio de verdad.
const ICONO_ABRE := {
	"mi_maquina": "maquina",
	"papelera": "papelera",
	"registro": "registro",
	"carpeta": "recuperado",
	"disco": "recuperado",
	"cascabel": "recuperado",
}

var vista: VistaMesa
var guardado: Guardado
var regiones := RegionesClic.new()

## Qué hay abierto: "" (nada), "inicio" (el menú), o el id de una ventana.
var abierto: String = ""
## Dentro de `registro`, qué fichero se está leyendo. "" = la lista.
var leyendo: String = ""

var _lienzo: Node2D

## EL RETRATO DE LA PREPARACIÓN. Un solo reproductor: solo hay una criatura
## marcada a la vez y la ventana es única.
var _repro := Reproductor.new()
var _repro_id := ""
var _fuente: Font
var _iconos: Dictionary = {}
var _sprites: Dictionary = {}
## Lo último que se ha recuperado, para el aviso. Se apaga solo.
var aviso_pieza: String = ""
var aviso_tiempo: float = 0.0

func _init(la_vista: VistaMesa, el_guardado: Guardado) -> void:
	vista = la_vista
	guardado = el_guardado
	layer = 30

func _ready() -> void:
	_fuente = FuenteUI.obtener()
	_lienzo = Node2D.new()
	_lienzo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_lienzo.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_lienzo.draw.connect(_dibujar)
	add_child(_lienzo)
	regiones.registrar(30, _regiones_sistema)
	regiones.registrar(5, _regiones_barra)
	regiones.registrar(-10, _regiones_escritorio)

static func _cargar(ruta: String) -> Texture2D:
	return load(ruta) as Texture2D if ResourceLoader.exists(ruta) else null

func _icono(nombre: String) -> Texture2D:
	if not _iconos.has(nombre):
		_iconos[nombre] = _cargar("res://assets/ui/iconos/%s.png" % nombre)
	return _iconos[nombre] as Texture2D

func _sprite(ruta: String) -> Texture2D:
	if ruta == "":
		return null
	if not _sprites.has(ruta):
		_sprites[ruta] = _cargar(ruta)
	return _sprites[ruta] as Texture2D

# ------------------------------------------------------------------ el estado

## Si hay algo abierto que tenga que congelar la mesa. El MENÚ no cuenta: es una
## tira de 168 px en una esquina, no tapa la bola, y cerrarlo para seguir jugando
## sería un paso de más. Las ventanas sí.
func congela_la_mesa() -> bool:
	return abierto != "" and abierto != "inicio"

func hay_algo() -> bool:
	return abierto != ""

## SI EL SISTEMA SE PUEDE TOCAR AHORA MISMO.
##
## No es una comodidad, es evitar un clic invisible. El mapa (capa 20) y TILT
## (40) se dibujan MAXIMIZADOS y tapan la barra de tareas, que va en la 5. Sin
## esta comprobación, el botón Inicio seguiría siendo pulsable debajo del mapa:
## pulsas un sitio donde no hay nada dibujado y se abre un menú. Es la misma
## familia de averías que el resto de `CLAUDE.md` —algo que responde donde no se
## ve— y no habría dado ningún error.
##
## Efecto secundario que hay que saber: **el escritorio solo se toca durante el
## combate**, que es el único momento en el que se ve. Está anotado en
## `ESTADO.md` como pregunta abierta, porque la salida buena es que el mapa deje
## de tapar la barra de tareas, y eso es geometría del mapa, no de aquí.
func disponible() -> bool:
	if vista == null:
		return false
	if vista.mapa_visible():
		return false
	if vista.tilt != null and vista.tilt.visible:
		return false
	return true

func cerrar() -> void:
	abierto = ""
	leyendo = ""
	if vista != null and vista.cascara != null:
		vista.cascara.inicio_hundido = false

func abrir(que: String) -> void:
	abierto = que
	leyendo = ""
	if vista != null and vista.cascara != null:
		vista.cascara.inicio_hundido = (que == "inicio")

func anunciar(id_pieza: String) -> void:
	aviso_pieza = id_pieza
	aviso_tiempo = 6.0

# ------------------------------------------------------------------- el ratón

func mover(punto: Vector2) -> void:
	regiones.mover(punto)
	if vista != null and vista.cascara != null:
		var i := -1
		if not hay_algo():
			var marcada := regiones.encima
			if marcada.begins_with("esc:"):
				i = int(marcada.substr(4))
		vista.cascara.icono_decorativo_marcado = i

## Devuelve si el clic lo ha consumido el sistema. Quien llama tiene que
## respetarlo: si no, un clic en el menú además hace lo que hubiera debajo.
func pulsar(punto: Vector2, apretado: bool) -> bool:
	var dentro := regiones.en(punto) != ""
	var activada := regiones.pulsar(punto, apretado)
	if activada == "":
		# Un clic FUERA del menú lo cierra, que es lo que hace cualquier menú.
		# Solo al soltar: cerrarlo al apretar haría que el propio clic que abre
		# el menú lo cerrara en el mismo gesto.
		if not apretado and not dentro and abierto == "inicio":
			cerrar()
		return dentro or hay_algo()
	_activar(activada)
	return true

func _activar(id: String) -> void:
	if id == "inicio":
		if abierto == "inicio":
			cerrar()
		else:
			abrir("inicio")
		return
	if id == "cerrar":
		cerrar()
		return
	if id == "volver":
		leyendo = ""
		return
	if id == "apagar":
		get_tree().quit()
		return
	if id == "vaciar":
		guardado.vaciar_papelera()
		guardado.guardar()
		return
	if id.begins_with("menu:"):
		abrir(id.substr(5))
		return
	if id.begins_with("leer:"):
		leyendo = id.substr(5)
		return
	# LA PREPARACIÓN. Elegir escribe el guardado en el acto: si se guardara solo
	# al empezar la partida, cerrar el juego después de elegir perdería la
	# elección y el jugador lo leería como que el juego no se acuerda.
	if id.begins_with("pre_"):
		var trozo := id.split(":")
		if trozo.size() == 2 and vista != null and vista.preparacion != null:
			match trozo[0]:
				"pre_c": vista.preparacion.cascabel = trozo[1]
				"pre_b": vista.preparacion.criatura = trozo[1]
				"pre_p": vista.preparacion.palas = trozo[1]
			if guardado != null:
				guardado.pre_cascabel = vista.preparacion.cascabel
				guardado.pre_criatura = vista.preparacion.criatura
				guardado.pre_palas = vista.preparacion.palas
				guardado.guardar()
		return
	if id == "empezar":
		cerrar()
		if vista != null:
			vista.nueva_partida()
		return
	if id.begins_with("esc:"):
		var i := int(id.substr(4))
		var nombres := NodoCascara.ICONOS_DECORATIVOS
		if i >= 0 and i < nombres.size():
			var destino := str(ICONO_ABRE.get(nombres[i], ""))
			if destino != "":
				abrir(destino)
		return

# --------------------------------------------------------------- las regiones

func _regiones_barra() -> Array:
	if vista == null or vista.cascara == null or not disponible():
		return []
	return [RegionesClic.Region.new("inicio", vista.cascara.caja_inicio())]

## Los iconos del escritorio. Solo cuando no hay nada abierto encima: con una
## ventana delante, el escritorio no se pulsa.
func _regiones_escritorio() -> Array:
	if vista == null or vista.cascara == null or hay_algo() or not disponible():
		return []
	var lista: Array = []
	for i in NodoCascara.ICONOS_DECORATIVOS.size():
		if not ICONO_ABRE.has(NodoCascara.ICONOS_DECORATIVOS[i]):
			continue
		lista.append(RegionesClic.Region.new("esc:%d" % i,
			vista.cascara.caja_icono_decorativo(i).grow(4.0)))
	return lista

func _regiones_sistema() -> Array:
	if abierto == "":
		return []
	if abierto == "inicio":
		var lista: Array = []
		var caja := caja_menu()
		var y := caja.position.y + 4.0
		for e in ENTRADAS:
			if str(e["id"]) == "":
				y += ALTO_SEPARADOR
				continue
			lista.append(RegionesClic.Region.new("menu:%s" % str(e["id"]),
				Rect2(caja.position.x + 3.0, y, caja.size.x - 6.0, ALTO_ENTRADA)))
			y += ALTO_ENTRADA
		# "Apagar" no abre ventana, sale del juego.
		for r in lista:
			if (r as RegionesClic.Region).id == "menu:apagar":
				(r as RegionesClic.Region).id = "apagar"
		return lista

	var lista2: Array = []
	var v := caja_ventana()
	lista2.append(RegionesClic.Region.new("cerrar", caja_aspa(v)))
	if abierto == "preparacion":
		for col in 3:
			var i := 0
			for op in _opciones_columna(col):
				lista2.append(RegionesClic.Region.new(
					"%s:%s" % [_PREFIJO[col], str(op["id"])], caja_opcion(v, col, i)))
				i += 1
		lista2.append(RegionesClic.Region.new("empezar", caja_boton_vaciar(v)))
	if abierto == "papelera" and guardado != null and guardado.total_matados() > 0:
		lista2.append(RegionesClic.Region.new("vaciar", caja_boton_vaciar(v)))
	if abierto == "registro":
		if leyendo != "":
			lista2.append(RegionesClic.Region.new("volver", caja_boton_vaciar(v)))
		else:
			var i := 0
			for p in CatalogoRecuperable.por_tipo("registro"):
				if guardado != null and guardado.tiene((p as CatalogoRecuperable.Pieza).id):
					lista2.append(RegionesClic.Region.new(
						"leer:%s" % (p as CatalogoRecuperable.Pieza).id, caja_fila(v, i)))
				i += 1
	return lista2

# -------------------------------------------------------------- la geometría

func pantalla() -> Vector2:
	return _lienzo.get_viewport_rect().size.ceil() if _lienzo != null else Vector2(960, 540)

func caja_menu() -> Rect2:
	var p := pantalla()
	var alto := 8.0
	for e in ENTRADAS:
		alto += ALTO_SEPARADOR if str(e["id"]) == "" else ALTO_ENTRADA
	return Rect2(4.0, p.y - NodoCascara.ALTO_BARRA - alto, ANCHO_MENU, alto)

func caja_ventana() -> Rect2:
	var p := pantalla()
	return Rect2(roundf((p.x - ANCHO_VENTANA) * 0.5),
		roundf((p.y - NodoCascara.ALTO_BARRA - ALTO_VENTANA) * 0.5),
		ANCHO_VENTANA, ALTO_VENTANA)

## El aspa de cerrar, dentro de la barra de título. Mismo sitio y mismo tamaño
## que los tres botones decorativos de la ventana de la mesa: si el jugador ya
## ha aprendido que ahí no se puede pulsar, esta tiene que estar exactamente
## donde estarían los de verdad.
func caja_aspa(v: Rect2) -> Rect2:
	return Rect2(v.end.x - NodoCascara.GROSOR_VENTANA - 14.0,
		v.position.y + NodoCascara.GROSOR_VENTANA + 2.0, 12.0, 12.0)

func _interior(v: Rect2) -> Rect2:
	if vista != null and vista.cascara != null:
		return vista.cascara.interior_panel(v)
	return v.grow(-8.0)

func caja_fila(v: Rect2, i: int) -> Rect2:
	var d := _interior(v)
	return Rect2(d.position.x + 4.0, d.position.y + 6.0 + float(i) * ALTO_FILA,
		d.size.x - 8.0, ALTO_FILA - 2.0)

## LAS TRES COLUMNAS DE LA PREPARACIÓN: cascabel, criatura y palas. Es
## `DISEÑO.md` §5 tal cual, y van en columnas y no en pestañas porque **las tres
## elecciones se leen juntas**: elegir palas cortas con un cascabel de combo es
## una decisión distinta que elegirlas con uno de golpe único, y con pestañas no
## se ve nunca lo que llevas puesto en las otras dos.
const _PREFIJO := ["pre_c", "pre_b", "pre_p"]
const _TITULO_COLUMNA := ["Cascabel", "Criatura", "Palas"]
const ALTO_OPCION := 20.0

## Las opciones de una columna, ya en la forma que dibuja: id y rótulo. La
## criatura sale del guardado porque es lo único de las tres que se gana; las
## otras dos están abiertas desde el primer día y eso es lo que mantiene en pie
## el invariante de `DISEÑO.md` §13.
func _opciones_columna(col: int) -> Array:
	var lista: Array = []
	match col:
		0:
			for c in Preparacion.cascabeles():
				var el_id := str((c as Dictionary).get("id", ""))
				var p := CatalogoRecuperable.por_id(el_id)
				lista.append({"id": el_id, "rotulo": p.nombre if p != null else el_id,
					"texto": str((c as Dictionary).get("resumen", "")),
					"sprite": p.ruta_sprite() if p != null else ""})
		1:
			for pz in Preparacion.criaturas_de(guardado):
				var p2 := pz as CatalogoRecuperable.Pieza
				lista.append({"id": p2.id, "rotulo": p2.nombre, "texto": p2.texto,
					"sprite": p2.ruta_sprite()})
		2:
			for pa in Preparacion.palas_disponibles():
				lista.append({"id": str((pa as Dictionary).get("id", "")),
					"rotulo": str((pa as Dictionary).get("nombre", "")),
					"texto": str((pa as Dictionary).get("resumen", "")),
					"sprite": ""})
	return lista

func _elegido_en(col: int) -> String:
	if vista == null or vista.preparacion == null:
		return ""
	match col:
		0: return vista.preparacion.cascabel
		1: return vista.preparacion.criatura
		2: return vista.preparacion.palas
	return ""

func caja_opcion(v: Rect2, col: int, i: int) -> Rect2:
	var d := _interior(v)
	var ancho := (d.size.x - 16.0) / 3.0
	return Rect2(d.position.x + 6.0 + float(col) * ancho, d.position.y + 24.0
		+ float(i) * ALTO_OPCION, ancho - 6.0, ALTO_OPCION - 2.0)

## EL RETRATO DE 64 DE LA PREPARACIÓN: la cáscara elegida con la criatura
## elegida encima. Va debajo de las tres columnas y encima de la franja de
## explicación, que es el único hueco de la ventana que no usa nadie.
##
## 64 Y NO 128. Los PNG miden 64, así que 64 es escala ×1 y ×2 sería 128, que no
## cabe en los 94 px libres. Cualquier otro número sería escala fraccionaria y
## el pixelart hierve — la misma regla del icono que tiene que dividir al PNG.
func caja_retrato(v: Rect2) -> Rect2:
	var d := _interior(v)
	var ancho := (d.size.x - 16.0) / 3.0
	return Rect2(
		roundf(d.position.x + 6.0 + ancho + (ancho - 6.0 - 64.0) * 0.5),
		roundf(d.position.y + 24.0 + 9.0 * ALTO_OPCION + 6.0), 64.0, 64.0)

func caja_boton_vaciar(v: Rect2) -> Rect2:
	var d := _interior(v)
	return Rect2(d.end.x - 92.0, d.end.y - 26.0, 88.0, 20.0)

# ------------------------------------------------------------------ el dibujo

## EL RATÓN ENTRA POR AQUÍ Y POR NINGÚN OTRO SITIO. Marcar el evento como
## atendido cuando cae dentro del sistema no es cortesía: sin eso, un clic en
## "Apagar" además pulsa lo que hubiera debajo en el escritorio.
func _input(evento: InputEvent) -> void:
	var mov := evento as InputEventMouseMotion
	if mov != null:
		mover(mov.position)
		return
	var boton := evento as InputEventMouseButton
	if boton == null or boton.button_index != MOUSE_BUTTON_LEFT:
		return
	if pulsar(boton.position, boton.pressed):
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if aviso_tiempo > 0.0:
		aviso_tiempo = maxf(aviso_tiempo - delta, 0.0)
	# Si el mapa o TILT se ponen delante con algo abierto, se cierra solo. Dejarlo
	# abierto lo dibujaría encima del mapa —esta capa es la 30— y además dejaría
	# la mesa congelada detrás de una pantalla que ya no la enseña.
	if hay_algo() and not disponible():
		cerrar()
	_avanzar_retrato(delta)
	if _lienzo != null:
		_lienzo.queue_redraw()

## La criatura marcada respira. Se resincroniza cuando cambia de criatura y no
## en cada fotograma: `poner` reinicia el bucle, así que llamarlo siempre
## dejaría la hoja clavada en el primer fotograma sin dar ningún error.
func _avanzar_retrato(delta: float) -> void:
	if abierto != "preparacion":
		return
	var el_id := _elegido_en(1)
	if el_id != _repro_id:
		_repro_id = el_id
		_repro.poner(HojaAnimada.de(el_id))
	_repro.avanzar(delta)

func _dibujar() -> void:
	if aviso_tiempo > 0.0:
		_dibujar_aviso()
	if abierto == "":
		return
	if abierto == "inicio":
		_dibujar_menu()
		return
	_dibujar_ventana()

func _dibujar_menu() -> void:
	var caja := caja_menu()
	if vista != null and vista.cascara != null:
		vista.cascara.dibujar_marco(_lienzo, caja)
	# La banda vertical de la izquierda, que es lo que hace que un menú de Inicio
	# se lea como un menú de Inicio y no como una lista cualquiera.
	var banda := Rect2(caja.position.x + 3.0, caja.position.y + 3.0, 18.0,
		caja.size.y - 6.0)
	_lienzo.draw_rect(banda, Color(C_ARCANO, 0.55))
	# El nombre en la banda, LETRA POR LETRA hacia abajo. `draw_string` no sabe
	# rotar —el parámetro que lo parece es la dirección del texto, no un ángulo—
	# y una fuente de rejilla girada media vuelta se sale de la rejilla de todas
	# formas. Apiladas quedan en píxel entero y se leen igual.
	var letras := "CASCABEL"
	var y0 := banda.end.y - 6.0 - float(letras.length()) * 10.0
	for i in letras.length():
		_lienzo.draw_string(_fuente,
			Vector2(banda.position.x + 6.0, y0 + float(i) * 10.0), letras[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8, Color(C_BLANCO, 0.85))

	var y := caja.position.y + 4.0
	for e in ENTRADAS:
		var el_id := str(e["id"])
		if el_id == "":
			var sy := y + ALTO_SEPARADOR * 0.5
			_lienzo.draw_line(Vector2(caja.position.x + 26.0, sy),
				Vector2(caja.end.x - 6.0, sy), Color(C_METAL, 0.7), 1.0)
			y += ALTO_SEPARADOR
			continue
		var fila := Rect2(caja.position.x + 3.0, y, caja.size.x - 6.0, ALTO_ENTRADA)
		var marcada := regiones.encima == ("apagar" if el_id == "apagar" else "menu:" + el_id)
		if marcada:
			_lienzo.draw_rect(fila, Color(C_ARCANO, 0.85))
		var tex := _icono(str(e["icono"]))
		if tex != null:
			_lienzo.draw_texture_rect(tex,
				Rect2(fila.position.x + 22.0, fila.position.y + 4.0, 16, 16), false)
		_lienzo.draw_string(_fuente,
			Vector2(fila.position.x + 44.0, fila.position.y + 16.0), str(e["rotulo"]),
			HORIZONTAL_ALIGNMENT_LEFT, fila.size.x - 48.0, 8,
			C_BLANCO if marcada else C_TEXTO)
		y += ALTO_ENTRADA

func _titulo_ventana() -> String:
	match abierto:
		"preparacion": return "nueva_partida.exe"
		"recuperado": return "C:\\cascabel\\RECUPERADO"
		"maquina": return "mi_maquina.sys"
		"papelera": return "papelera"
		"registro":
			if leyendo == "":
				return "registro.log"
			# EL IDENTIFICADOR NO ES EL RÓTULO, y esto se coló entero: `leyendo`
			# es la clave del JSON (`log_arranque`), así que la ventana ponía
			# "log_arranque.log" en vez de "arranque.log". Es la misma avería del
			# "COMUN" en la tele que ya está en `CLAUDE.md`, y sale igual de
			# rápido: cualquier cadena que se DIBUJE tiene que salir del dato de
			# rótulo, nunca de la clave.
			var p := CatalogoRecuperable.por_id(leyendo)
			return p.fichero if p != null else leyendo
	return abierto

## El nombre de un enemigo para pintarlo, a partir de su id. Otra vez lo mismo:
## la papelera guarda `goblin_carroniero`, que es la clave y va sin tilde por
## fuerza, y escribirlo tal cual dejaba un proceso llamado "goblin_carroniero"
## al lado de un mapa que pone "goblin_carroñero". El id se guarda; el nombre se
## pinta.
func _proceso_de(id: String) -> String:
	if _nombres_enemigo.is_empty():
		for d in CatalogoEnemigos.cargar():
			_nombres_enemigo[str((d as Dictionary).get("id", ""))] = \
				str((d as Dictionary).get("nombre", ""))
	var nombre := str(_nombres_enemigo.get(id, ""))
	if nombre == "":
		nombre = id
	return nombre.to_lower().replace(" ", "_") + ".exe"

var _nombres_enemigo: Dictionary = {}

func _dibujar_ventana() -> void:
	var v := caja_ventana()
	# El velo de detrás. Sin él, una ventana encima de la mesa encendida se lee
	# como parte del tablero.
	_lienzo.draw_rect(Rect2(Vector2.ZERO, pantalla()), Color(C_VACIO, 0.55))
	if vista != null and vista.cascara != null:
		vista.cascara.dibujar_panel(_lienzo, v, _titulo_ventana())
	else:
		_lienzo.draw_rect(v, C_VACIO)
	var d := _interior(v)
	_lienzo.draw_rect(d, Color(C_VACIO, 0.85))

	# El aspa, que aquí SÍ cierra. Los tres botones de la ventana de la mesa son
	# decorado a propósito; este no, y por eso se enciende al pasar por encima:
	# es lo único que distingue un botón vivo de uno pintado.
	var aspa := caja_aspa(v)
	var sobre_aspa := regiones.encima == "cerrar"
	_lienzo.draw_rect(aspa, Color(C_GOMA_LUZ if sobre_aspa else C_METAL, 1.0))
	_lienzo.draw_rect(aspa, C_VACIO, false, 1.0)
	_lienzo.draw_line(aspa.position + Vector2(3, 3), aspa.end - Vector2(3, 3), C_VACIO, 1.0)
	_lienzo.draw_line(Vector2(aspa.end.x - 3, aspa.position.y + 3),
		Vector2(aspa.position.x + 3, aspa.end.y - 3), C_VACIO, 1.0)

	match abierto:
		"preparacion": _dibujar_preparacion(d, v)
		"recuperado": _dibujar_recuperado(d)
		"maquina": _dibujar_maquina(d)
		"papelera": _dibujar_papelera(d, v)
		"registro": _dibujar_registro(d, v)

## LA CARPETA. Lo que no tienes TAMBIÉN sale, como un fichero de 0 bytes con el
## nombre ilegible: ver el hueco es el gancho, y una lista de logros bloqueados
## no se lee igual que una carpeta con ficheros que el sistema no puede abrir.
func _dibujar_recuperado(d: Rect2) -> void:
	var piezas: Array = []
	for t in ["cascabel", "criatura", "registro"]:
		for p in CatalogoRecuperable.por_tipo(t):
			piezas.append(p)
	var tengo := 0
	for p in piezas:
		if guardado != null and guardado.tiene((p as CatalogoRecuperable.Pieza).id):
			tengo += 1

	# Dos columnas: con 22 piezas, una sola se sale de la ventana.
	var por_columna := int((d.size.y - 30.0) / 22.0)
	var ancho_col := d.size.x * 0.5
	for i in piezas.size():
		var p := piezas[i] as CatalogoRecuperable.Pieza
		var lo_tengo := guardado != null and guardado.tiene(p.id)
		var col := i / por_columna
		var fila := i % por_columna
		var x := d.position.x + 8.0 + float(col) * ancho_col
		var y := d.position.y + 20.0 + float(fila) * 22.0
		if y > d.end.y - 24.0:
			continue
		var tex := _sprite(p.ruta_sprite()) if lo_tengo else null
		if tex != null:
			_lienzo.draw_texture_rect(tex, Rect2(x, y - 12.0, 16, 16), false)
		else:
			# El icono de un fichero que no se puede leer. Un rectángulo vacío
			# dice "aquí había algo" mejor que un hueco.
			_lienzo.draw_rect(Rect2(x + 2, y - 11.0, 12, 14),
				Color(C_METAL, 0.30 if not lo_tengo else 1.0))
			_lienzo.draw_rect(Rect2(x + 2, y - 11.0, 12, 14),
				Color(C_TEXTO_TENUE, 0.5), false, 1.0)
		_lienzo.draw_string(_fuente, Vector2(x + 22.0, y),
			p.fichero if lo_tengo else p.nombre_ilegible(),
			HORIZONTAL_ALIGNMENT_LEFT, ancho_col - 84.0, 8,
			C_TEXTO if lo_tengo else C_TEXTO_TENUE)
		_lienzo.draw_string(_fuente,
			Vector2(x + ancho_col - 58.0, y), "%d KB" % _tamano_falso(p) if lo_tengo else "0 KB",
			HORIZONTAL_ALIGNMENT_RIGHT, 44.0, 8,
			C_TEXTO_TENUE if lo_tengo else Color(C_TEXTO_TENUE, 0.55))

	# La barra de estado, que es donde se lee el progreso sin que sea una barra
	# de progreso: "18 de 22 objetos" es un escritorio, no un juego con logros.
	_lienzo.draw_string(_fuente, Vector2(d.position.x + 8.0, d.end.y - 8.0),
		"%d de %d objetos · %d sin recuperar" % [tengo, piezas.size(), piezas.size() - tengo],
		HORIZONTAL_ALIGNMENT_LEFT, d.size.x - 16.0, 8, C_ORO)

## Un tamaño de fichero verosímil y ESTABLE. Sale del nombre, no de un dado: un
## tamaño que cambia cada vez que abres la carpeta se lee como un fallo.
func _tamano_falso(p: CatalogoRecuperable.Pieza) -> int:
	var n := 0
	for c in p.id:
		n += c.unicode_at(0)
	return 4 + (n % 60)

func _dibujar_maquina(d: Rect2) -> void:
	var g := guardado
	if g == null:
		return
	var filas := [
		["runs jugados", str(g.runs_jugados)],
		["runs ganados", str(g.runs_ganados)],
		["combates ganados", str(g.combates_ganados)],
		["bolas jugadas", str(g.bolas_jugadas)],
		["daño total", str(g.dano_total)],
		["mejor daño por bola", "%.0f" % g.mejor_dano_por_bola],
		["tiempo jugado", "%d min" % int(g.segundos_jugados / 60.0)],
		["procesos terminados", str(g.total_matados())],
		["objetos recuperados", str(g.cuantas_recuperadas())],
	]
	var y := d.position.y + 22.0
	for f in filas:
		_lienzo.draw_string(_fuente, Vector2(d.position.x + 10.0, y), str(f[0]),
			HORIZONTAL_ALIGNMENT_LEFT, d.size.x * 0.6, 8, C_TEXTO_TENUE)
		_lienzo.draw_string(_fuente, Vector2(d.position.x + 10.0, y), str(f[1]),
			HORIZONTAL_ALIGNMENT_RIGHT, d.size.x - 20.0, 8, C_TEXTO)
		y += 22.0
	if g.ilegible:
		_lienzo.draw_string(_fuente, Vector2(d.position.x + 10.0, d.end.y - 10.0),
			"aviso: el guardado anterior no se pudo leer",
			HORIZONTAL_ALIGNMENT_LEFT, d.size.x - 20.0, 8, C_GOMA_LUZ)

## LA PAPELERA: los enemigos que has matado. `DISEÑO.md` §3 dice que los
## monstruos son procesos, así que matarlos los manda aquí.
func _dibujar_papelera(d: Rect2, v: Rect2) -> void:
	var g := guardado
	if g == null:
		return
	if g.matados.is_empty():
		_lienzo.draw_string(_fuente,
			Vector2(d.position.x + 10.0, d.position.y + d.size.y * 0.5),
			"La papelera está vacía.", HORIZONTAL_ALIGNMENT_CENTER,
			d.size.x - 20.0, 8, C_TEXTO_TENUE)
		if g.papelera_vaciada >= 3:
			# El easter egg: algo que el sistema no debería tener. No da nada.
			_lienzo.draw_string(_fuente,
				Vector2(d.position.x + 10.0, d.position.y + d.size.y * 0.5 + 22.0),
				"...otra vez.", HORIZONTAL_ALIGNMENT_CENTER,
				d.size.x - 20.0, 8, Color(C_ARCANO, 0.9))
		return
	var claves := g.matados.keys()
	claves.sort()
	var y := d.position.y + 22.0
	for k in claves:
		if y > d.end.y - 34.0:
			break
		_lienzo.draw_string(_fuente, Vector2(d.position.x + 10.0, y),
			_proceso_de(str(k)), HORIZONTAL_ALIGNMENT_LEFT, d.size.x * 0.7, 8, C_TEXTO)
		_lienzo.draw_string(_fuente, Vector2(d.position.x + 10.0, y),
			"×%d" % int(g.matados[k]), HORIZONTAL_ALIGNMENT_RIGHT,
			d.size.x - 110.0, 8, C_TEXTO_TENUE)
		y += 20.0
	var b := caja_boton_vaciar(v)
	_boton(b, "Vaciar", regiones.encima == "vaciar")

func _dibujar_registro(d: Rect2, v: Rect2) -> void:
	if leyendo != "":
		var p := CatalogoRecuperable.por_id(leyendo)
		if p != null:
			_lienzo.draw_multiline_string(_fuente,
				Vector2(d.position.x + 10.0, d.position.y + 24.0), p.texto,
				HORIZONTAL_ALIGNMENT_LEFT, d.size.x - 20.0, 8, -1, C_VERDE)
		_boton(caja_boton_vaciar(v), "Atrás", regiones.encima == "volver")
		return
	var i := 0
	for pz in CatalogoRecuperable.por_tipo("registro"):
		var p2 := pz as CatalogoRecuperable.Pieza
		var lo_tengo := guardado != null and guardado.tiene(p2.id)
		var fila := caja_fila(v, i)
		if fila.end.y > d.end.y:
			break
		if lo_tengo and regiones.encima == "leer:" + p2.id:
			_lienzo.draw_rect(fila, Color(C_ARCANO, 0.55))
		var tex := _icono("registro")
		if tex != null:
			_lienzo.draw_texture_rect(tex,
				Rect2(fila.position.x + 4.0, fila.position.y + 2.0, 24, 24), false,
				Color(1, 1, 1, 1.0 if lo_tengo else 0.25))
		_lienzo.draw_string(_fuente,
			Vector2(fila.position.x + 34.0, fila.position.y + 18.0),
			p2.fichero if lo_tengo else p2.nombre_ilegible(),
			HORIZONTAL_ALIGNMENT_LEFT, fila.size.x - 40.0, 8,
			C_TEXTO if lo_tengo else C_TEXTO_TENUE)
		i += 1

## LA PANTALLA DE PREPARACIÓN (`DISEÑO.md` §5). Tres elecciones que definen el
## run, a la vista a la vez, y **abierto todo desde el primer día**: elegir antes
## del run no es desbloquear entre runs, así que esto no toca §13. Lo único que
## depende del guardado son las criaturas, que son skin pura.
##
## Debajo va SIEMPRE el texto de lo que tienes marcado. Sin eso, nueve nombres en
## una columna no dicen nada y la elección se hace a suertes — que es exactamente
## lo que `DISEÑO.md` §1 quiere evitar.
func _dibujar_preparacion(d: Rect2, v: Rect2) -> void:
	var ancho := (d.size.x - 16.0) / 3.0
	# DOS TEXTOS, no uno. Lo que se lee abajo tiene que ser lo que el ratón está
	# señalando, y solo si no señala nada, lo que llevas puesto. Con una sola
	# variable ganaba la última columna que se dibujara, así que pasar el ratón
	# por un cascabel enseñaba la descripción de las palas: justo lo contrario de
	# lo que hace falta para elegir.
	var explicacion := ""
	var senalado := ""
	for col in 3:
		_lienzo.draw_string(_fuente,
			Vector2(d.position.x + 8.0 + float(col) * ancho, d.position.y + 14.0),
			_TITULO_COLUMNA[col], HORIZONTAL_ALIGNMENT_LEFT, ancho - 8.0, 8, C_ORO)
		var elegido := _elegido_en(col)
		var i := 0
		for op in _opciones_columna(col):
			var caja := caja_opcion(v, col, i)
			var es_este: bool = str(op["id"]) == elegido
			var marcado := regiones.encima == "%s:%s" % [_PREFIJO[col], str(op["id"])]
			if es_este:
				_lienzo.draw_rect(caja, Color(C_ARCANO, 0.75))
			elif marcado:
				_lienzo.draw_rect(caja, Color(C_METAL, 0.45))
			if marcado:
				senalado = str(op["texto"])
			elif es_este and explicacion == "":
				explicacion = str(op["texto"])
			var x := caja.position.x + 4.0
			var tex := _sprite(str(op["sprite"]))
			if tex != null:
				_lienzo.draw_texture_rect(tex,
					Rect2(x, caja.position.y + 1.0, 16, 16), false)
				x += 20.0
			_lienzo.draw_string(_fuente, Vector2(x, caja.position.y + 13.0),
				str(op["rotulo"]), HORIZONTAL_ALIGNMENT_LEFT,
				caja.end.x - x - 2.0, 8, C_BLANCO if es_este else C_TEXTO)
			i += 1

	if senalado != "":
		explicacion = senalado

	_dibujar_retrato(caja_retrato(v))

	# La franja de explicación, pegada abajo y por encima del botón.
	var franja := Rect2(d.position.x + 6.0, d.end.y - 58.0, d.size.x - 12.0, 30.0)
	_lienzo.draw_rect(franja, Color(C_VACIO, 0.8))
	_lienzo.draw_multiline_string(_fuente,
		Vector2(franja.position.x + 4.0, franja.position.y + 12.0), explicacion,
		HORIZONTAL_ALIGNMENT_LEFT, franja.size.x - 8.0, 8, 2, C_TEXTO_TENUE)

	# Y el aviso que hay que dar sin letra pequeña: esto EMPIEZA UN RUN NUEVO.
	# Un botón que tira la partida en curso sin decirlo es el peor botón posible.
	_lienzo.draw_string(_fuente,
		Vector2(d.position.x + 8.0, d.end.y - 14.0),
		"Empezar tira la partida en curso.", HORIZONTAL_ALIGNMENT_LEFT,
		d.size.x - 110.0, 8, C_GOMA_LUZ)
	_boton(caja_boton_vaciar(v), "Empezar", regiones.encima == "empezar")

## LA CÁSCARA DETRÁS Y LA CRIATURA DELANTE, y ese orden no es indiferente: está
## mirado en un mosaico de las dos criaturas contra tres cáscaras. Al revés la
## cáscara tapa a la criatura entera y lo que queda es una bola con una ranura
## negra — el bicho desaparece y no da ningún error. Con la criatura delante,
## las manos de `cr_calavera` se agarran al borde de la ranura y las dos capas
## se leen como UN bicho asomándose, que es exactamente lo que pedía
## `assets/prompts_animacion.md` §4.
##
## Y NO GIRA. `DISEÑO.md` §4 dice que la cáscara rueda y la criatura no, pero eso
## es en la mesa; aquí es un retrato de interfaz a 64 px, que es donde la
## combinatoria de 81 se puede ver de verdad (en la mesa la bola mide 18).
func _dibujar_retrato(caja: Rect2) -> void:
	var casc := CatalogoRecuperable.por_id(_elegido_en(0))
	if casc != null:
		var tc := _sprite(casc.ruta_sprite())
		if tc != null:
			_lienzo.draw_texture_rect(tc, caja, false)
	# El fotograma si la criatura tiene hoja; el retrato estático si no. Las
	# nueve acabarán teniendo hoja, pero hoy solo hay dos y un hueco donde
	# debería haber un bicho se lee como un fallo de la pantalla.
	var tex := _repro.textura()
	if tex == null:
		var cr := CatalogoRecuperable.por_id(_elegido_en(1))
		if cr != null:
			tex = _sprite(cr.ruta_sprite())
	if tex != null:
		_lienzo.draw_texture_rect(tex, caja, false)

func _boton(caja: Rect2, texto: String, marcado: bool) -> void:
	_lienzo.draw_rect(caja, Color(C_METAL, 1.0 if marcado else 0.75))
	_lienzo.draw_rect(caja, C_VACIO, false, 1.0)
	_lienzo.draw_string(_fuente,
		Vector2(caja.position.x, caja.position.y + caja.size.y * 0.5 + 4.0), texto,
		HORIZONTAL_ALIGNMENT_CENTER, caja.size.x, 8, C_VACIO)

## EL AVISO DE QUE HAS RECUPERADO ALGO. Es lo único de todo este nodo que sale
## sin que lo pidas, y por eso es pequeño y se apaga solo: sale abajo a la
## derecha, encima de la barra de tareas, como un globo de sistema.
func _dibujar_aviso() -> void:
	var p := CatalogoRecuperable.por_id(aviso_pieza)
	if p == null:
		return
	var pt := pantalla()
	var caja := Rect2(pt.x - 240.0, pt.y - NodoCascara.ALTO_BARRA - 62.0, 232.0, 54.0)
	if vista != null and vista.cascara != null:
		vista.cascara.dibujar_panel(_lienzo, caja, "recuperacion.exe")
	var d := _interior(caja)
	var tex := _sprite(p.ruta_sprite())
	if tex != null:
		_lienzo.draw_texture_rect(tex,
			Rect2(d.position.x + 2.0, d.position.y + 2.0, 24, 24), false)
	_lienzo.draw_string(_fuente, Vector2(d.position.x + 32.0, d.position.y + 12.0),
		"Recuperado: " + p.fichero, HORIZONTAL_ALIGNMENT_LEFT,
		d.size.x - 36.0, 8, C_ORO_CLARO)
