extends Node

## PRUEBA 3D — «ÓRBITA». Escena de usar y mirar: NO es Cascabel.
##
## Una mesa nueva (`mesa_orbita.gd`) con gráficos nuevos (`mundo_orbita.gd`) y
## una caza de criaturas (`caza_orbita.gd`), para contestar antes de gastar más:
## ¿este es el nivel, y estas mecánicas divierten? No toca la escena principal,
## ni el juego 2D, ni la web.
##
##     Godot --path <repo> res://prueba3d/prueba_3d.tscn
##
## TECLAS
##   A / D (o flechas, o Mayús / Ctrl)   palas          ESPACIO   lanzar
##   C  cambiar de cámara                X  a qué criatura sigue la cámara
##   1 / 2 / 3  poner o quitar a LUMI, GOTA y TANQUE
##   M  bola extra      R  bola nueva    T  piloto automático
##   H  ayuda           F12  captura
##
## No hay `get_tree().quit()` a propósito: la batería del juego prohíbe
## cualquier salida que no sea `VistaMesa.salir()`. Se cierra con Alt+F4.
##
## EN EL NAVEGADOR (preset "Web 3D", que la pone de escena principal): arranca
## jugando sola hasta el primer clic o la primera tecla, porque hasta entonces
## el navegador no da ni teclado ni sonido; y las palas son solo A / D y las
## flechas, que Ctrl y Mayús con otra tecla son atajos del navegador.

const MundoOrbita := preload("res://prueba3d/mundo_orbita.gd")
const MesaOrbita := preload("res://prueba3d/mesa_orbita.gd")
const Caza := preload("res://prueba3d/caza_orbita.gd")
const Criatura := preload("res://prueba3d/criatura.gd")
const E := 0.01

const CIAN := Color(0.20, 0.88, 1.0)
const MAGENTA := Color(1.0, 0.22, 0.60)
const AMBAR := Color(1.0, 0.60, 0.16)
const VIOLETA := Color(0.58, 0.40, 1.0)
const BLANCO := Color(0.92, 0.95, 1.0)
const GRIS := Color(0.50, 0.56, 0.70)
const ROJO := Color(1.0, 0.30, 0.24)

const VISTAS := ["SEGUIMIENTO", "RASANTE", "CENITAL", "ESTACIÓN", "PLAZA", "CRIATURA"]

## Lo que vale cada cosa y cómo se llama en pantalla. Clave: nombre del recorrido.
const TIROS := {
	"orbita": {"rotulo": "ÓRBITA", "puntos": 1500, "color": VIOLETA},
	"cometa": {"rotulo": "COMETA", "puntos": 1200, "color": CIAN},
	"estacion": {"rotulo": "ESTACIÓN", "puntos": 1500, "color": MAGENTA},
	"gusano": {"rotulo": "AGUJERO DE GUSANO", "puntos": 800, "color": CIAN},
}

## LA CALIDAD DE LOS GRÁFICOS, de más a menos. En escritorio va siempre en ALTA.
## En web no puede: el navegador de un portátil dibuja casi siempre con la
## gráfica INTEGRADA aunque el equipo tenga otra. Medido en este mismo portátil
## (Intel UHD, ventana de 1902×984, Chrome sin tope de fotogramas): ALTA ronda
## los 35 por segundo, MEDIA 78 y BAJA 90.
##   mp       MEGAPÍXELES como mucho a los que se dibuja el 3D, que luego se
##            estira a la ventana. Es un tope fijo y no una fracción de la
##            ventana a propósito: con una fracción, una pantalla 4K pediría
##            cuatro veces más píxeles a la misma gráfica.
##   escala   un multiplicador más encima de eso; solo se usa para medir
##   msaa     suavizado de bordes: 0, 2 o 4 muestras. A 1080p las 4 muestras
##            cuestan 7 ms en la integrada: es lo más caro de ALTA
##   reflejo  tamaño de la cámara del reflejo respecto a la principal; 0 = sin él
##   sombras  las del sol. MEDIA va sin ellas: sobre un cristal oscuro casi no
##            se ven —mirado en dos capturas iguales, una con y otra sin— y
##            cuestan 3,4 ms, que es la diferencia entre 61 y 78 por segundo
## Probado y descartado como mando: el tamaño del mapa de sombras. De 4096 a
## 1024 no se gana ni medio milisegundo, porque la sombra cuesta por las
## llamadas de dibujo y no por sus píxeles.
const CALIDADES := ["ALTA", "MEDIA", "BAJA"]
const AJUSTES_CALIDAD := {
	"ALTA": {"mp": 3.7, "escala": 1.0, "msaa": 4, "reflejo": 0.5, "brillo": 1,
		"sombras": 1, "cielo": 1},
	"MEDIA": {"mp": 1.05, "escala": 1.0, "msaa": 0, "reflejo": 0.4, "brillo": 1,
		"sombras": 0, "cielo": 1},
	"BAJA": {"mp": 0.67, "escala": 1.0, "msaa": 0, "reflejo": 0.0, "brillo": 1,
		"sombras": 0, "cielo": 1},
}

## Gráficas que se sabe que no pueden con ALTA: con una de estas el vigilante no
## la prueba, y así no hay tres segundos a tirones nada más empezar. Lo que no
## esté en la lista sí la prueba, y si no aguanta vuelve a bajar.
const GRAFICAS_FLOJAS := ["intel", "uhd graphics", "hd graphics", "iris", "mali",
	"adreno", "powervr", "videocore", "swiftshader", "llvmpipe", "basic render"]

## Los colores de las tres, para el marcador. Los mismos que llevan en el cuerpo.
const COLOR_ESPECIE := {
	"corredor": Color(0.45, 1.0, 0.28),
	"saltarin": Color(1.0, 0.84, 0.16),
	"gotita": Color(1.0, 0.84, 0.16),
	"escarabajo": Color(1.0, 0.30, 0.24),
}
const CONSEJO := {
	"corredor": "asústala a golpes · tápale las bocas",
	"saltarin": "pártela · recoge las dos mitades",
	"escarabajo": "por la espalda · vuélcalo",
}

var mesa: MesaOrbita
var caza: Caza
var mundo: MundoOrbita
var vp: SubViewport
var vp_reflejo: SubViewport
var camara: Camera3D
var camara_reflejo: Camera3D
var pantalla: TextureRect
var sonido: NodoSonido
var fuente: Font

var rot_puntos: Label
var rot_multi: Label
var rot_aviso: Label
var rot_lista: Label
var rot_ayuda: Label
var rot_vista: Label
var rot_caza: Label
var rot_criaturas: Array[Label] = []
var rot_clic: Label
var caja_clic: PanelContainer

## Solo en web: la página acaba de abrirse y nadie ha tocado nada todavía.
var _web := OS.has_feature("web")
var _falta_clic := false

## Calidad en uso, lo que vale cada mando y el vigilante que la baja sola.
var calidad := 0
var _cal: Dictionary = {}
var _cal_forzado: Dictionary = {}
var _cal_auto := false
var _cal_t := 0.0
var _cal_n := 0
var _cal_espera := 3.0
var _cal_tope := 0
var _cal_sobrada := 0.0
var _cal_reintento := 6.0
var _cal_desde_subida := 1.0e9
var _grafica := ""

## EL MEDIDOR (`-- --medir` en escritorio, `?medir=1` en web): cada segundo dice
## cuánto se lleva la física, cuánto este guion y cuántas llamadas de dibujo
## salen. No es una prueba: no falla, informa.
var _medir := false
var _med_fisica := 0
var _med_proceso := 0
var _med_n := 0
var _med_t := 0.0

var vista := 0
var piloto := false
var puntos := 0
var multiplicador := 1
var bola_numero := 1
var criatura_camara := 0
var cuentas := {"sol": 0, "satelites": 0, "orbita": 0, "cometa": 0,
	"estacion": 0, "negro": 0, "gusano": 0}

var _pide_bola := false
var _tiempo := 0.0
var _combo := 0.0
var _aviso := 0.0
var _cam_t := 1.0
var _cam_x := 0.0
var _cam_bicho := Vector3(2.14, 0.0, 10.18)
var _pulso_i := 0.0
var _pulso_d := 0.0
var _descanso_i := 0.0
var _descanso_d := 0.0
var _carga_piloto := 0.0
var _izq_antes := false
var _der_antes := false
var _rng := RandomNumberGenerator.new()

## Capturas automáticas, para mirar la prueba sin jugarla:
##     ... res://prueba3d/prueba_3d.tscn -- --capturas=C:/ruta --vista=4 --demo
## `--demo` va forzando a mano los sucesos de la caza —un golpe, una rendición,
## una recogida—, para poder ver cada estado sin esperar a que el piloto acierte.
var _dir_capturas := ""
var _capturas_hechas := 0
var _cada := 2.5
var _demo := false
var _guion: Array = []

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capturas="):
			_dir_capturas = arg.trim_prefix("--capturas=")
			piloto = true
		elif arg.begins_with("--vista="):
			vista = clampi(int(arg.trim_prefix("--vista=")), 0, VISTAS.size() - 1)
		elif arg.begins_with("--cada="):
			_cada = float(arg.trim_prefix("--cada="))
		elif arg.begins_with("--criatura="):
			criatura_camara = maxi(int(arg.trim_prefix("--criatura=")), 0)
		elif arg == "--piloto":
			piloto = true
		elif arg == "--demo":
			_demo = true
		elif arg == "--medir":
			_medir = true
		elif arg.begins_with("--calidad="):
			calidad = maxi(CALIDADES.find(arg.trim_prefix("--calidad=").to_upper()), 0)

	# El proyecto escala por enteros, que es lo suyo para el pixelart del juego.
	# Aquí no hay pixelart, y en una pestaña de navegador casi nunca caben dos
	# veces 960×540: por enteros el marcador se quedaría a ×1, diminuto.
	get_window().content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	get_window().title = "Cascabel 3D · ÓRBITA"
	if _web:
		piloto = true
		_falta_clic = true
		_leer_direccion()

	# En web no hay fuentes del sistema y esto cae en la de reserva de Godot
	# (Open Sans), que sí trae tildes y eñes: está comprobado carácter a carácter.
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Bahnschrift", "Segoe UI Semibold", "Arial"])
	f.font_weight = 600
	fuente = f

	mesa = MesaOrbita.new()
	caza = Caza.new()
	caza.preparar(mesa, 3)
	mesa.caza = caza
	mesa.nueva_bola()
	_conectar_reglas()
	_conectar_caza()

	sonido = NodoSonido.new()
	add_child(sonido)

	# Dos vistas del MISMO mundo: la del jugador y la del reflejo, que mira la
	# mesa desde debajo del cristal. La del reflejo va antes en el árbol para
	# que su imagen esté lista cuando el cristal la pida.
	var mundo3d := World3D.new()
	vp_reflejo = SubViewport.new()
	vp_reflejo.world_3d = mundo3d
	vp_reflejo.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp_reflejo)
	vp = SubViewport.new()
	vp.world_3d = mundo3d
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	add_child(vp)

	mundo = MundoOrbita.new()
	vp.add_child(mundo)
	mundo.montar(mesa)
	mundo.montar_caza(caza)

	camara = Camera3D.new()
	camara.near = 0.1
	camara.far = 200.0
	vp.add_child(camara)
	camara.current = true
	camara_reflejo = Camera3D.new()
	camara_reflejo.near = 0.1
	camara_reflejo.far = 200.0
	camara_reflejo.cull_mask = 1
	camara_reflejo.environment = mundo.entorno_reflejo
	vp_reflejo.add_child(camara_reflejo)
	camara_reflejo.current = true
	mundo.mat_suelo.set_shader_parameter("reflejo", vp_reflejo.get_texture())

	var capa := CanvasLayer.new()
	add_child(capa)
	pantalla = TextureRect.new()
	pantalla.texture = vp.get_texture()
	pantalla.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pantalla.stretch_mode = TextureRect.STRETCH_SCALE
	pantalla.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var post := ShaderMaterial.new()
	post.shader = load("res://prueba3d/post.gdshader")
	pantalla.material = post
	capa.add_child(pantalla)

	_montar_marcador(capa)
	get_viewport().size_changed.connect(_ajustar_pantalla)
	_poner_calidad(calidad)

	if _demo:
		# Índices: 0 LUMI, 1 GOTA, 2 TANQUE. Tiempo, quién y qué.
		_guion = [
			[5.2, 0, "golpe"], [5.6, 1, "golpe"], [8.4, 0, "golpe"],
			[9.4, 2, "golpe"], [10.6, 0, "rendir"], [13.2, 0, "recoger"],
			[14.0, 2, "recoger"],
		]

# --------------------------------------------------------------------- marcador

func _rotulo(padre: Node, cuerpo: int, col: Color) -> Label:
	var l := Label.new()
	var ajustes := LabelSettings.new()
	ajustes.font = fuente
	ajustes.font_size = cuerpo
	ajustes.font_color = col
	ajustes.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	ajustes.shadow_size = 3
	l.label_settings = ajustes
	padre.add_child(l)
	return l

func _montar_marcador(capa: CanvasLayer) -> void:
	var titulo := _rotulo(capa, 30, CIAN)
	titulo.text = "ÓRBITA"
	titulo.position = Vector2(28, 22)
	var sub := _rotulo(capa, 10, GRIS)
	sub.text = "MESA DE PRUEBA · 3D"
	sub.position = Vector2(30, 58)
	rot_puntos = _rotulo(capa, 34, BLANCO)
	rot_puntos.position = Vector2(28, 84)
	rot_multi = _rotulo(capa, 13, AMBAR)
	rot_multi.position = Vector2(30, 126)
	rot_lista = _rotulo(capa, 11, GRIS)
	rot_lista.position = Vector2(30, 160)
	# LA CAZA: una línea por criatura, de su color, con lo que está haciendo y
	# —debajo, en pequeño— cómo se la captura. No hay barra de miedo: el miedo
	# va en el aro, pegado al bicho.
	rot_caza = _rotulo(capa, 13, BLANCO)
	rot_caza.position = Vector2(30, 296)
	for i in 3:
		var linea := _rotulo(capa, 12, BLANCO)
		linea.position = Vector2(30, 322 + 40 * i)
		rot_criaturas.append(linea)
		var consejo := _rotulo(capa, 9, GRIS)
		consejo.position = Vector2(30, 339 + 40 * i)
		var c: Criatura = caza.principales()[i]
		consejo.text = CONSEJO.get(c.especie, "")
	rot_aviso = _rotulo(capa, 26, BLANCO)
	rot_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# El aviso de arranque lleva su propio fondo. Suelto no vale: cae encima de
	# la mesa, y el canto de neón lo cruzaba de lado a lado como si estuviera
	# tachado —visto en la página ya publicada, no antes—.
	caja_clic = PanelContainer.new()
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.0, 0.01, 0.04, 0.78)
	fondo.border_color = Color(CIAN.r, CIAN.g, CIAN.b, 0.6)
	fondo.set_border_width_all(1)
	fondo.set_corner_radius_all(6)
	fondo.content_margin_left = 18.0
	fondo.content_margin_right = 18.0
	fondo.content_margin_top = 7.0
	fondo.content_margin_bottom = 7.0
	caja_clic.add_theme_stylebox_override("panel", fondo)
	capa.add_child(caja_clic)
	rot_clic = _rotulo(caja_clic, 16, BLANCO)
	rot_clic.text = "HAZ CLIC O PULSA UNA TECLA PARA JUGAR"
	caja_clic.visible = _falta_clic
	rot_ayuda = _rotulo(capa, 10, GRIS)
	rot_ayuda.text = "A / D   palas\nESPACIO   lanzar (mantener)\n\nC   cambiar de cámara\nX   seguir a otra criatura\n1 2 3   poner o quitar criaturas\nM   bola extra\nR   bola nueva\nT   piloto automático\nG   calidad de los gráficos\nH   ocultar esto"
	if not _web:
		rot_ayuda.text += "\nF12   captura"
	rot_vista = _rotulo(capa, 10, GRIS)

func _refrescar_marcador() -> void:
	rot_puntos.text = "%07d" % puntos
	rot_multi.text = "BOLA %d      ×%d%s" % [bola_numero, multiplicador,
		"      PILOTO" if piloto else ""]
	rot_lista.text = "SOL   %d\nSATÉLITES   %d\nÓRBITA   %d\nCOMETA   %d\nESTACIÓN   %d\nAGUJERO NEGRO   %d\nGUSANO   %d" % [
		cuentas["sol"], cuentas["satelites"], cuentas["orbita"],
		cuentas["cometa"], cuentas["estacion"], cuentas["negro"],
		cuentas["gusano"]]
	var texto := "CÁMARA · %s" % VISTAS[vista]
	if VISTAS[vista] == "CRIATURA":
		var lista := caza.principales()
		texto += " · " + (lista[criatura_camara % lista.size()] as Criatura).nombre
	texto += "        GRÁFICOS · %s%s" % [CALIDADES[calidad],
		" (auto)" if _cal_auto else ""]
	rot_vista.text = texto

## El estado de las criaturas cambia solo, así que este trozo se escribe cada
## cuadro. Son cuatro etiquetas.
func _refrescar_caza() -> void:
	rot_caza.text = "CAZA · OLA %d      CAPTURAS %d" % [caza.ola, caza.capturas]
	var lista := caza.principales()
	for i in rot_criaturas.size():
		var c: Criatura = lista[i]
		var linea := rot_criaturas[i]
		linea.text = "%s   %s" % [c.nombre, caza.estado_de(c)]
		var col: Color = COLOR_ESPECIE.get(c.especie, BLANCO)
		if not c.activa:
			col = GRIS.darkened(0.3)
		elif c.asegurada:
			col = col.lerp(BLANCO, 0.5)
		linea.label_settings.font_color = col

func _avisar(texto: String, col: Color) -> void:
	rot_aviso.text = texto
	rot_aviso.label_settings.font_color = col
	_aviso = 1.8

func _sumar(cuanto: int) -> void:
	puntos += cuanto * multiplicador

# ----------------------------------------------------------------------- reglas

func _conectar_reglas() -> void:
	mesa.bola_drenada.connect(_al_drenar)
	mesa.bumper_golpeado.connect(func(_p: Vector2, _f: float) -> void:
		sonido.reproducir("bumper")
		cuentas["sol"] += 1
		_sumar(100)
		_refrescar_marcador())
	mesa.slingshot_golpeado.connect(func(_p: Vector2, _f: float) -> void:
		_sumar(30)
		_refrescar_marcador())
	mesa.target_abatido.connect(func(_p: Vector2, _b: int) -> void:
		sonido.reproducir("target")
		cuentas["satelites"] += 1
		_sumar(250)
		_refrescar_marcador())
	mesa.banco_completado.connect(func(_p: Vector2, _b: int) -> void:
		sonido.reproducir("banco")
		_sumar(2500)
		_avisar("SATÉLITES FUERA · SOL ABIERTO", CIAN)
		_refrescar_marcador())
	mesa.girador_girado.connect(func(_p: Vector2, _i: int, _f: float) -> void:
		_sumar(80)
		_refrescar_marcador())
	mesa.rampa_entrada.connect(func(_p: Vector2, _i: int) -> void:
		sonido.reproducir("rampa_entrada"))
	mesa.rampa_fallada.connect(func(_p: Vector2, _i: int, _r: float) -> void:
		sonido.reproducir("rampa_fallada")
		_avisar("NO LLEGA", GRIS))
	mesa.rampa_salida.connect(_al_completar)
	mesa.platillo_capturado.connect(func(_p: Vector2, _i: int) -> void:
		sonido.reproducir("platillo")
		cuentas["negro"] += 1
		_sumar(5000)
		_avisar("AGUJERO NEGRO  +%d" % (5000 * multiplicador), AMBAR)
		_refrescar_marcador())
	mesa.bola_cayo.connect(func(_p: Vector2, _d: int, _h: int) -> void:
		sonido.reproducir("caida"))

## Lo que la caza le cuenta al marcador y al altavoz. Los sonidos son los que ya
## tiene el juego: no hay ninguno nuevo, y eso está por hacer.
func _conectar_caza() -> void:
	caza.criatura_golpeada.connect(func(c: Criatura, _p: Vector2, _f: float, _n: Vector2) -> void:
		sonido.reproducir("target")
		_sumar(300)
		if c.especie == "corredor" and c.miedo >= 1.0:
			_avisar("%s NO PUEDE MÁS" % c.nombre, _color_de(c))
		_refrescar_marcador())
	caza.criatura_blindada.connect(func(c: Criatura, _p: Vector2, _f: float) -> void:
		sonido.reproducir("bumper")
		_avisar("%s · CORAZA · DALE POR DETRÁS" % c.nombre, _color_de(c)))
	caza.criatura_volcada.connect(func(c: Criatura, _p: Vector2) -> void:
		sonido.reproducir("banco")
		_sumar(500)
		_avisar("%s PANZA ARRIBA · TÓCALO" % c.nombre, _color_de(c))
		_refrescar_marcador())
	caza.criatura_partida.connect(func(c: Criatura, _p: Vector2) -> void:
		sonido.reproducir("banco")
		_sumar(400)
		_avisar("%s SE PARTE · RECOGE LAS DOS" % c.nombre, _color_de(c))
		_refrescar_marcador())
	caza.criatura_reunida.connect(func(c: Criatura, _p: Vector2) -> void:
		_avisar("%s SE HA VUELTO A JUNTAR" % c.nombre, GRIS))
	caza.criatura_acorralada.connect(func(c: Criatura) -> void:
		sonido.reproducir("reloj")
		_avisar("%s ACORRALADA · TÓCALA" % c.nombre, ROJO))
	caza.criatura_rehecha.connect(func(c: Criatura) -> void:
		_avisar("%s SE REHACE" % c.nombre, GRIS))
	caza.criatura_recogida.connect(func(c: Criatura, _p: Vector2) -> void:
		sonido.reproducir("atrapar")
		_sumar(1000)
		_avisar("%s EN LA BOLA · LLÉVALA A UNA PALA" % c.nombre, _color_de(c))
		_refrescar_marcador())
	caza.criatura_asegurada.connect(func(c: Criatura, _p: Vector2) -> void:
		sonido.reproducir("combo")
		if c.principal:
			_sumar(5000)
			_avisar("%s ASEGURADA  +%d" % [c.nombre, 5000 * multiplicador], _color_de(c))
		else:
			_sumar(1500)
			_avisar("MITAD A SALVO", _color_de(c))
		_refrescar_marcador())
	caza.criatura_escapada.connect(func(c: Criatura, _p: Vector2) -> void:
		sonido.reproducir("caida")
		_avisar("%s SE ESCAPÓ" % c.nombre, GRIS))
	caza.criatura_escondida.connect(func(c: Criatura, _p: Vector2) -> void:
		sonido.reproducir("platillo")
		_avisar("%s SE ESCONDE · MÉTELE LA BOLA EN EL TÚNEL" % c.nombre, _color_de(c)))
	caza.criatura_expulsada.connect(func(c: Criatura, _p: Vector2) -> void:
		_sumar(800)
		_avisar("%s · FUERA DEL TÚNEL" % c.nombre, _color_de(c))
		_refrescar_marcador())
	caza.caza_completa.connect(func(ola: int) -> void:
		sonido.reproducir("salvaguarda")
		_sumar(20000)
		_avisar("CAZA COMPLETA · OLA %d" % ola, AMBAR)
		_refrescar_marcador())

func _color_de(c: Criatura) -> Color:
	return COLOR_ESPECIE.get(c.especie, BLANCO)

func _al_completar(_punto: Vector2, indice: int) -> void:
	var nombre := mesa.rampas[indice].nombre
	if not TIROS.has(nombre):
		return
	sonido.reproducir("rampa_salida")
	var tiro: Dictionary = TIROS[nombre]
	# EL OCHO: encadenar recorridos antes de que se apague el combo sube el
	# multiplicador. Es lo que hace que la mesa tenga un camino y no solo piezas.
	if _combo > 0.0:
		multiplicador = mini(multiplicador + 1, 5)
	_combo = 8.0
	cuentas[nombre] += 1
	_sumar(int(tiro["puntos"]))
	var texto: String = tiro["rotulo"]
	if multiplicador > 1:
		texto += "  ×%d" % multiplicador
	_avisar(texto, tiro["color"])
	_refrescar_marcador()

func _al_drenar() -> void:
	sonido.reproducir("drenaje")
	_pide_bola = true
	multiplicador = 1
	_combo = 0.0
	bola_numero += 1
	_avisar("BOLA PERDIDA", MAGENTA)
	_refrescar_marcador()

# ---------------------------------------------------------------------- pantalla

func _ajustar_pantalla() -> void:
	var lienzo := get_viewport().get_visible_rect().size
	var escala := maxf(float(get_window().size.x) / lienzo.x, 1.0)
	pantalla.position = Vector2.ZERO
	pantalla.size = lienzo
	var ventana: Vector2 = lienzo * escala
	var cabe := sqrt(float(_cal.get("mp", 100.0)) * 1.0e6 / maxf(ventana.x * ventana.y, 1.0))
	var real: Vector2 = ventana * minf(cabe, 1.0) * float(_cal.get("escala", 1.0))
	vp.size = Vector2i(real).maxi(16)
	vp_reflejo.size = Vector2i(real * maxf(float(_cal.get("reflejo", 0.5)), 0.1)).maxi(16)
	rot_aviso.position = Vector2(0.0, 30.0)
	rot_aviso.size = Vector2(lienzo.x, 40.0)
	# Abajo y en el centro. Arriba quedaba encima de los raíles y no se leía.
	caja_clic.size = caja_clic.get_combined_minimum_size()
	caja_clic.position = Vector2((lienzo.x - caja_clic.size.x) * 0.5, lienzo.y - 72.0)
	rot_ayuda.position = Vector2(lienzo.x - 220.0, lienzo.y - 192.0)
	rot_vista.position = Vector2(30.0, lienzo.y - 30.0)

## El primer clic o la primera tecla en el navegador: hasta entonces la mesa se
## ha estado jugando sola, y a partir de aquí es del que ha llegado. La tecla se
## da por gastada, para que una T no vuelva a encender el piloto que apaga.
func _input(evento: InputEvent) -> void:
	if not _falta_clic:
		return
	# Con un dedo no se puede jugar a esto: no hay palas que tocar. En un móvil
	# la mesa sigue jugando sola y dice por qué. El clic que el motor inventa a
	# partir del toque no cuenta: viene marcado como de mentira.
	var toque := evento as InputEventScreenTouch
	if toque != null:
		if toque.pressed:
			_avisar("SE JUEGA CON TECLADO · AQUÍ SE JUEGA SOLA", GRIS)
		return
	var boton := evento as InputEventMouseButton
	var tecla := evento as InputEventKey
	var clic := boton != null and boton.pressed \
		and boton.device != InputEvent.DEVICE_ID_EMULATION
	if clic or (tecla != null and tecla.pressed):
		_falta_clic = false
		piloto = false
		caja_clic.visible = false
		_avisar("TÚ JUEGAS", CIAN)
		_refrescar_marcador()
		if tecla != null:
			get_viewport().set_input_as_handled()

func _unhandled_key_input(evento: InputEvent) -> void:
	var tecla := evento as InputEventKey
	if tecla == null or not tecla.pressed or tecla.echo:
		return
	# En el navegador F12 es de las herramientas del navegador, no nuestra.
	if _web and tecla.physical_keycode == KEY_F12:
		return
	match tecla.physical_keycode:
		KEY_C:
			vista = (vista + 1) % VISTAS.size()
			# Otra cámara es otra carga: el vigilante vuelve a probar pronto.
			_cal_reintento = 6.0
		KEY_X:
			criatura_camara = (criatura_camara + 1) % caza.principales().size()
		KEY_1:
			_alternar("corredor")
		KEY_2:
			_alternar("saltarin")
		KEY_3:
			_alternar("escarabajo")
		KEY_T:
			piloto = not piloto
		KEY_M:
			mesa.soltar_bola_extra()
		KEY_R:
			_pide_bola = true
		KEY_H:
			rot_ayuda.visible = not rot_ayuda.visible
		KEY_G:
			# A mano manda el que juega: el vigilante se retira.
			_cal_auto = false
			_poner_calidad((calidad + 1) % CALIDADES.size())
		KEY_F12:
			_capturar("user://orbita_%d.png" % Time.get_ticks_msec())
		_:
			return
	_refrescar_marcador()

func _alternar(especie: String) -> void:
	for c in caza.principales():
		if c.especie == especie:
			caza.activar(especie, not c.activa)
			_avisar("%s %s" % [c.nombre, "ENTRA" if c.activa else "FUERA DE JUEGO"],
				_color_de(c))
			return

# ----------------------------------------------------------------------- calidad

## En web se le pueden pasar mandos por la dirección, para medir o para forzar:
##     .../?calidad=baja        ?escala=0.7&msaa=2        ?auto=0
func _leer_direccion() -> void:
	_cal_auto = true
	calidad = 1
	# Qué gráfica usa de verdad el navegador. El motor no lo sabe —WebGL se lo
	# esconde—, pero la página sí puede preguntarlo.
	_grafica = str(JavaScriptBridge.eval("(function(){try{var c=document.createElement('canvas');var g=c.getContext('webgl2')||c.getContext('webgl');if(!g)return '';var e=g.getExtension('WEBGL_debug_renderer_info');return String(e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER));}catch(x){return '';}})()", true))
	var nombre := _grafica.to_lower()
	for floja: String in GRAFICAS_FLOJAS:
		if nombre.contains(floja):
			_cal_tope = 1
			break
	var consulta := str(JavaScriptBridge.eval("window.location.search", true))
	for trozo in consulta.trim_prefix("?").split("&", false):
		var par := trozo.split("=")
		if par.size() != 2:
			continue
		if par[0] == "calidad":
			var cual := CALIDADES.find(par[1].to_upper())
			if cual >= 0:
				calidad = cual
				_cal_auto = false
		elif par[0] == "auto":
			_cal_auto = par[1] != "0"
		elif par[0] == "medir":
			_medir = par[1] != "0"
		elif AJUSTES_CALIDAD["ALTA"].has(par[0]) and par[1].is_valid_float():
			_cal_forzado[par[0]] = float(par[1])

func _poner_calidad(cual: int) -> void:
	calidad = clampi(cual, 0, CALIDADES.size() - 1)
	_cal = (AJUSTES_CALIDAD[CALIDADES[calidad]] as Dictionary).duplicate()
	_cal.merge(_cal_forzado, true)
	match int(_cal["msaa"]):
		0: vp.msaa_3d = Viewport.MSAA_DISABLED
		2: vp.msaa_3d = Viewport.MSAA_2X
		_: vp.msaa_3d = Viewport.MSAA_4X
	var con_reflejo := float(_cal["reflejo"]) > 0.0
	if con_reflejo:
		vp_reflejo.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	else:
		vp_reflejo.render_target_update_mode = SubViewport.UPDATE_DISABLED
	mundo.mat_suelo.set_shader_parameter("fuerza_reflejo", 0.5 if con_reflejo else 0.0)
	mundo.entorno.glow_enabled = int(_cal["brillo"]) != 0
	mundo.luz_sol.shadow_enabled = int(_cal["sombras"]) != 0
	var fondo := Environment.BG_SKY if int(_cal["cielo"]) != 0 else Environment.BG_COLOR
	mundo.entorno.background_mode = fondo
	mundo.entorno_reflejo.background_mode = fondo
	_cal_espera = 1.5
	_cal_t = 0.0
	_cal_n = 0
	_cal_sobrada = 0.0
	_ajustar_pantalla()
	_refrescar_marcador()

## EL VIGILANTE: si la página no llega a 47 fotogramas por segundo durante dos
## segundos, baja un nivel; si lleva un rato yendo sobrada, prueba a subir uno.
##
## BAJAR NO ES PARA SIEMPRE. La primera versión no volvía a probar el nivel que
## había fallado, y bastaba pasar por la cámara de CRIATURA —que carga más— para
## quedarse en BAJA el resto de la partida. Ahora vuelve a probar, y cada subida
## que falla hace esperar el doble a la siguiente (de 6 s hasta 2 min), así que
## un equipo que de verdad no puede no se pasa la partida a tirones.
##
## Los fotogramas de más de un cuarto de segundo no cuentan: eso es una pestaña
## en segundo plano o un tirón de carga, no un equipo lento. Y los umbrales
## dejan fuera a las pantallas de 48 y 50 Hz, que si no bajarían por ir a tope.
func _vigilar_calidad(delta: float) -> void:
	if not _cal_auto or delta <= 0.0 or delta > 0.25:
		return
	_cal_desde_subida += delta
	if _cal_espera > 0.0:
		_cal_espera -= delta
		return
	_cal_t += delta
	_cal_n += 1
	if _cal_t < 2.0:
		return
	var fps := float(_cal_n) / _cal_t
	var visto := _cal_t
	_cal_t = 0.0
	_cal_n = 0
	if fps < 47.0:
		_cal_sobrada = 0.0
		if calidad < CALIDADES.size() - 1:
			if _cal_desde_subida < 12.0:
				_cal_reintento = minf(_cal_reintento * 2.0, 120.0)
			_poner_calidad(calidad + 1)
	elif fps > 57.0 and calidad > _cal_tope:
		_cal_sobrada += visto
		if _cal_sobrada >= _cal_reintento:
			_cal_desde_subida = 0.0
			_poner_calidad(calidad - 1)
	else:
		_cal_sobrada = 0.0

# ------------------------------------------------------------------------ física

func _physics_process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	_tiempo += delta
	if _pide_bola:
		_pide_bola = false
		mesa.nueva_bola()
	if _combo > 0.0:
		_combo -= delta
		if _combo <= 0.0 and multiplicador > 1:
			multiplicador = 1
			_refrescar_marcador()
	while not _guion.is_empty() and _tiempo >= float(_guion[0][0]):
		var paso: Array = _guion.pop_front()
		caza.forzar(mesa, caza.criaturas[int(paso[1])], str(paso[2]))

	var izq := Input.is_physical_key_pressed(KEY_A) \
		or Input.is_physical_key_pressed(KEY_LEFT)
	var der := Input.is_physical_key_pressed(KEY_D) \
		or Input.is_physical_key_pressed(KEY_RIGHT)
	if not _web:
		# En una página, Ctrl con otra tecla es un atajo que no se puede parar
		# (Ctrl+W cierra la pestaña, Ctrl+T abre otra), y Mayús cinco veces
		# seguidas saca el diálogo de Teclas especiales de Windows.
		izq = izq or Input.is_physical_key_pressed(KEY_SHIFT)
		der = der or Input.is_physical_key_pressed(KEY_CTRL)
	var lanzar := Input.is_physical_key_pressed(KEY_SPACE)
	if piloto:
		var orden := _pilotar(delta)
		izq = izq or orden[0]
		der = der or orden[1]
		lanzar = lanzar or orden[2]

	# Cada botón mueve TODAS las palas de su lado, como en una máquina con pala
	# superior: la de la estación va con la izquierda.
	for i in mesa.flippers.size():
		mesa.flippers[i].pulsado = izq if mesa.lado_pala[i] < 0 else der
	if (izq and not _izq_antes) or (der and not _der_antes):
		sonido.reproducir("flipper")
	_izq_antes = izq
	_der_antes = der

	if lanzar:
		mesa.cargar_lanzador(delta)
	elif mesa.cargando:
		mesa.soltar_lanzador()

	# La caza va dentro: la mesa la mueve antes de mover las bolas.
	mesa.avanzar(delta)
	_med_fisica += Time.get_ticks_usec() - t0

## Un jugador de mentira, lo justo para que la mesa se mueva sola en una captura
## o mientras alguien mira. No sabe apuntar: es un figurante.
func _pilotar(delta: float) -> Array:
	_pulso_i = maxf(_pulso_i - delta, 0.0)
	_pulso_d = maxf(_pulso_d - delta, 0.0)
	_descanso_i = maxf(_descanso_i - delta, 0.0)
	_descanso_d = maxf(_descanso_d - delta, 0.0)
	var en_carril := false
	for b in mesa.bolas:
		if not b.viva:
			continue
		if b.en_carril and b.libre():
			en_carril = true
		if not b.libre() or b.vel.y < -20.0:
			continue
		for i in mesa.flippers.size():
			var f := mesa.flippers[i]
			if not f.en_capa(b.capa):
				continue
			var d := b.pos - f.eje
			var lado := mesa.lado_pala[i]
			# Un palazo y un descanso. Si volviera a pulsar mientras la bola
			# siga cerca, la dejaría acunada en la pala para siempre.
			var ocupada := (_pulso_i > 0.0 or _descanso_i > 0.0) if lado < 0 \
				else (_pulso_d > 0.0 or _descanso_d > 0.0)
			if ocupada:
				continue
			if absf(d.y + 12.0) < 18.0 and d.x * float(-lado) > f.longitud * 0.25 \
					and absf(d.x) < f.longitud + 8.0 and _rng.randf() < 0.5:
				var pulso := _rng.randf_range(0.08, 0.2)
				if lado < 0:
					_pulso_i = pulso
					_descanso_i = pulso + 0.35
				else:
					_pulso_d = pulso
					_descanso_d = pulso + 0.35
	var lanzar := false
	if en_carril:
		_carga_piloto += delta
		lanzar = _carga_piloto < 1.0
		if _carga_piloto > 1.2:
			_carga_piloto = 0.0
	else:
		_carga_piloto = 0.0
	return [_pulso_i > 0.0, _pulso_d > 0.0, lanzar]

# ------------------------------------------------------------------------ cámara

func _process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	mundo.actualizar(delta)
	_refrescar_caza()
	_vigilar_calidad(delta)

	if _aviso > 0.0:
		_aviso -= delta
		rot_aviso.modulate.a = clampf(_aviso * 2.0, 0.0, 1.0)
	else:
		rot_aviso.modulate.a = 0.0
	if _falta_clic:
		caja_clic.modulate.a = 0.84 + 0.16 * sin(_tiempo * 4.0)

	var b := mesa.bola_en_peligro()
	var p3 := mundo.posicion_bola(b)
	if b.viva:
		var t := clampf((p3.z - 6.4) / (12.3 - 6.4), 0.0, 1.0)
		_cam_t = lerpf(_cam_t, t, 1.0 - exp(-3.0 * delta))
		_cam_x = lerpf(_cam_x, p3.x - 2.0, 1.0 - exp(-3.0 * delta))

	var pos: Vector3
	var mira: Vector3
	var fov := 46.0
	match VISTAS[vista]:
		"RASANTE":
			# Baja y cerca de las palas, con la mesa perdiéndose al fondo.
			pos = Vector3(2.0 + _cam_x * 0.25, 2.3, 15.0)
			mira = Vector3(2.0 + _cam_x * 0.5, 0.2, 10.4 - (1.0 - _cam_t) * 1.2)
			fov = 56.0
		"CENITAL":
			pos = Vector3(2.0, 13.5, 9.6)
			mira = Vector3(2.0, 0.0, 9.3)
			fov = 40.0
		"ESTACIÓN":
			pos = Vector3(4.6, 2.6, 9.2)
			mira = Vector3(2.7, 0.2, 7.2)
			fov = 50.0
		"PLAZA":
			# La plaza de las criaturas, de cerca. Las palas quedan fuera: es
			# para mirar, no para jugar.
			pos = Vector3(2.14, 2.9, 12.75)
			mira = Vector3(2.14, 0.0, 9.95)
			fov = 48.0
		"CRIATURA":
			# Pegada a una criatura, para verle las patas y los ojos.
			var lista := caza.principales()
			var c: Criatura = lista[criatura_camara % lista.size()]
			if c.partida:
				for g in caza.mitades(c):
					if g.a_la_vista():
						c = g
						break
			if c.activa and c.a_la_vista() and c.estado != Criatura.Estado.EN_BOLA:
				_cam_bicho = _cam_bicho.lerp(mundo.posicion_criatura(c.indice),
					1.0 - exp(-5.0 * delta))
			pos = Vector3(_cam_bicho.x + 0.25, 0.72, _cam_bicho.z + 1.15)
			mira = Vector3(_cam_bicho.x, 0.10, _cam_bicho.z)
			fov = 44.0
		_:
			pos = Vector3(2.0, 6.4, 15.9).lerp(Vector3(2.0, 4.2, 15.95), _cam_t)
			mira = Vector3(2.0, 0.0, 9.3).lerp(Vector3(2.0, 0.0, 10.95), _cam_t)
			pos.x += _cam_x * 0.12
			mira.x += _cam_x * 0.28
	var s := mundo.sacudida
	if s > 0.0:
		var temblor := Vector3(_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0), 0.0) * s * 0.022
		pos += temblor
		mira += temblor * 0.5
	camara.fov = fov
	camara.look_at_from_position(pos, mira, Vector3.UP)
	# La cámara del reflejo es la misma, simétrica respecto al cristal. De cerca
	# dibuja también las patas y los ojos de las criaturas; en las dos cámaras
	# de juego, que las ven pequeñas y desde arriba, se los ahorra.
	var de_cerca: bool = VISTAS[vista] != "SEGUIMIENTO" and VISTAS[vista] != "CENITAL"
	camara_reflejo.cull_mask = 1 | (MundoOrbita.CAPA_DETALLE if de_cerca else 0)
	camara_reflejo.fov = fov
	camara_reflejo.look_at_from_position(
		Vector3(pos.x, -pos.y, pos.z), Vector3(mira.x, -mira.y, mira.z), Vector3.UP)

	if _dir_capturas != "" and _tiempo > 2.0 + float(_capturas_hechas) * _cada \
			and _capturas_hechas < 12:
		_capturar("%s/v%d_%02d.png" % [_dir_capturas, vista, _capturas_hechas])
		_capturas_hechas += 1
	if _medir:
		_medida(delta, Time.get_ticks_usec() - t0)

## Un renglón por segundo. Los milisegundos son POR FOTOGRAMA: la física suma
## todos los pasos de 120 Hz que han caído dentro, así que a menos fotogramas
## por segundo, más física por fotograma.
func _medida(delta: float, proceso: int) -> void:
	_med_proceso += proceso
	_med_n += 1
	_med_t += delta
	if _med_t < 1.0:
		return
	var n := float(_med_n)
	var texto := "fps %.1f · física %.2f ms · guion %.2f ms · dibujos %d · objetos %d · triángulos %d · %s %dx%d" % [
		n / _med_t, float(_med_fisica) / 1000.0 / n, float(_med_proceso) / 1000.0 / n,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		CALIDADES[calidad], vp.size.x, vp.size.y]
	if _grafica != "":
		texto += " · " + _grafica.replace("'", "")
	if _web:
		JavaScriptBridge.eval("window.__medida = '%s'" % texto, true)
	else:
		print(texto)
	_med_fisica = 0
	_med_proceso = 0
	_med_n = 0
	_med_t = 0.0

func _capturar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura: ", ProjectSettings.globalize_path(ruta))
