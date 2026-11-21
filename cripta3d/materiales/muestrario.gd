extends Node

## CRIPTA 3D — EL MUESTRARIO. Todos los materiales de la biblioteca, cada uno
## sobre tres formas, con la luz de la cripta. Es donde se juzga un material
## antes de que llegue a la mesa, y donde se mira qué hace cada variante.
##
##   python cripta3d/herramientas/godot3d.py escena res://cripta3d/materiales/muestrario.tscn \
##       --fotogramas 140 -- --capturas=C:/ruta/salida
##
##   --capturas=   carpeta donde deja los PNG (si falta, solo se mira)
##   --detalle     además de las tres tomas, un primer plano de cada material
##                 (son 14 más: lánzalo con --fotogramas 340)
##   --solo=       solo el primer plano de esos materiales (separados por comas)
##   --pagina=     materiales (por defecto) | variantes: en vez de los catorce,
##                 los mandos —mojado, desgaste, suciedad, escala, veta, juntas,
##                 local, tinte, emision— puestos en fila para ver qué hace cada uno
##                 | piedra: la piedra tal como la piden los módulos (tiene que
##                 salir UNA), y la goma, el latón, el hierro y la madera en las
##                 formas donde fallaban (ver `_montar_piedra`)
##                 | remate: el hierro tal como lo piden las piezas (pala, engranaje,
##                 oxidado, barandilla), la piedra en un canto romo de DOS caras (el
##                 de las albardillas, donde el grano salía peinado), y la madera y
##                 la cera (ver `_montar_remate`)
##   --prueba      usa `biblioteca_prueba.gd` si existe: la copia de trabajo, para
##                 probar un cambio del sombreador sin romper la mesa de nadie.
##                 Se copia de `biblioteca.gd` cambiando sus `preload` a una copia
##                 del sombreador, y se borra al pasar el cambio a los de verdad
##   --depura=N    pinta una máscara en vez del material: 1 canto, 2 suciedad,
##                 3 oclusión, 4 mojado, 5 normal
##   --sin-espejo  sin la cámara espejo: el suelo deja de reflejar la escena
##   --fuego=      foco (por defecto) | omni: cómo da sombra el fuego (ver abajo)
##   --tam=        1600x900 por defecto
##
## LAS TRES FORMAS no son un capricho: cada una enseña una cosa.
##   - El BLOQUE lleva los cantos biselados de verdad y COLOR DE VÉRTICE (G=1 en
##     el bisel, R bajando hacia la base): es la prueba de «vertice».
##   - La ESFERA no tiene una sola cara plana: es donde se ve si el triplanar
##     deja costura, y donde el metal enseña todo lo que refleja.
##   - El CILINDRO lleva el canto redondeado y NO lleva color de vértice: ahí el
##     desgaste sale solo del giro de la normal.
##
## No hay ninguna forma de salir escrita aquí a propósito: la batería del juego
## no deja. Se cierra con `--fotogramas`.

const Biblioteca := preload("res://cripta3d/materiales/biblioteca.gd")

## El orden de la fila: delante lo que más superficie va a cubrir en la mesa.
const FILA_DELANTE: Array[String] = ["piedra", "losa", "hierro", "oxido", "bronce", "laton", "acero"]
const FILA_DETRAS: Array[String] = ["madera", "hueso", "goma", "cera", "carbon", "ascua", "arcano"]
const PASO := 0.66          # de un material al siguiente
const FONDO := -0.80        # la fila de atrás, que sube a un poyo
const ALTO_POYO := 0.20
const ESPERA_PRIMERA := 50  # fotogramas: el cielo tarda en hornear su reflejo
const ESPERA := 10

var _dir := ""
var _ancho := 1600
var _alto := 900
var _detalle := false
var _pagina := "materiales"
var _depura := 0
var _espejo := true
var _fuego := "foco"
var _solo := ""

var vp: SubViewport
var vp_espejo: SubViewport
var camara: Camera3D
var camara_espejo: Camera3D
var mat: RefCounted
var _tomas: Array[Dictionary] = []
var _n := 0

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capturas="):
			_dir = arg.trim_prefix("--capturas=")
		elif arg == "--detalle":
			_detalle = true
		elif arg == "--sin-espejo":
			_espejo = false
		elif arg.begins_with("--fuego="):
			_fuego = arg.trim_prefix("--fuego=")
		elif arg.begins_with("--solo="):
			_solo = arg.trim_prefix("--solo=")
		elif arg.begins_with("--pagina="):
			_pagina = arg.trim_prefix("--pagina=")
		elif arg.begins_with("--depura="):
			_depura = int(arg.trim_prefix("--depura="))
		elif arg.begins_with("--tam="):
			var t := arg.trim_prefix("--tam=").split("x")
			if t.size() == 2:
				_ancho = maxi(int(t[0]), 64)
				_alto = maxi(int(t[1]), 64)
	get_window().title = "Cripta 3D · muestrario de materiales"
	get_window().content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	if _dir != "":
		DirAccess.make_dir_recursive_absolute(_dir)
	mat = Biblioteca.new()
	if OS.get_cmdline_user_args().has("--prueba"):
		# La copia de trabajo de la biblioteca y su sombreador, si existe: así se
		# prueba un cambio aquí sin dejar a los demás con materiales rosas.
		var ruta := "res://cripta3d/materiales/biblioteca_prueba.gd"
		if ResourceLoader.exists(ruta):
			mat = (load(ruta) as GDScript).new()
			print("MUESTRARIO: con la biblioteca de prueba")
	_montar_plato()
	if _pagina == "variantes":
		_montar_variantes()
	elif _pagina == "piedra":
		_montar_piedra()
	elif _pagina == "remate":
		_montar_remate()
	else:
		_montar_materiales()
	print("MUESTRARIO: %d tomas: lánzalo con --fotogramas %d o más" % [
		_tomas.size(), ESPERA_PRIMERA + _tomas.size() * (ESPERA + 2) + 20])
	_guion()

# --------------------------------------------------------------------- el plató

## LA LUZ DE LA CRIPTA, la misma del plató de `visor.gd`: fuego cálido y bajo por
## delante, luna fría y alta por detrás, casi nada de ambiente, ACES y brillo.
## Lo único que cambia es que aquí la fila mide cuatro metros y allí había un
## bicho: el fuego se repite a lo largo para que a todos les llegue el suyo.
func _montar_plato() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(_ancho, _alto)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	# Una sombra por cuadrante del atlas, y el atlas grande: es un plató de fotos,
	# no la mesa.
	vp.positional_shadow_atlas_size = 8192
	for cuadrante in 3:
		vp.set_positional_shadow_atlas_quadrant_subdiv(cuadrante, Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_1)
	RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_ULTRA)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var cielo := Sky.new()
	var mat_cielo := ProceduralSkyMaterial.new()
	mat_cielo.sky_top_color = Color(0.05, 0.06, 0.10)
	mat_cielo.sky_horizon_color = Color(0.16, 0.13, 0.11)
	mat_cielo.ground_bottom_color = Color(0.02, 0.02, 0.02)
	mat_cielo.ground_horizon_color = Color(0.12, 0.09, 0.07)
	mat_cielo.sun_angle_max = 0.0
	cielo.sky_material = mat_cielo
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.032, 0.04)
	env.sky = cielo
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.36, 0.42, 0.62)
	env.ambient_light_energy = 0.22
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_strength = 1.0
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)

	var luna := DirectionalLight3D.new()
	luna.light_color = Color(0.62, 0.72, 0.95)
	luna.light_energy = 0.9
	luna.rotation_degrees = Vector3(-52.0, 150.0, 0.0)
	luna.shadow_enabled = true
	luna.directional_shadow_max_distance = 12.0
	vp.add_child(luna)
	for x: float in [-2.3, 0.0, 2.3]:
		_fuego_en(Vector3(x, 0.65, 1.6))
	for x: float in [-1.2, 1.4]:
		var relleno := OmniLight3D.new()
		relleno.light_color = Color(1.0, 0.80, 0.60)
		relleno.light_energy = 0.45
		relleno.omni_range = 3.0
		relleno.position = Vector3(x, 0.3, 1.3)
		vp.add_child(relleno)

	camara = Camera3D.new()
	camara.near = 0.02
	camara.far = 60.0
	vp.add_child(camara)
	camara.current = true

	if _espejo:
		# LA CÁMARA ESPEJO, como en `prueba3d/prueba_3d.gd`: la misma cámara, puesta
		# del revés por debajo del suelo, mirando el mismo mundo. Su imagen es lo
		# que refleja la losa. Va ANTES en el árbol para que se dibuje primero.
		vp_espejo = SubViewport.new()
		vp_espejo.size = Vector2i(_ancho, _alto) / 2
		vp_espejo.world_3d = vp.find_world_3d()
		vp_espejo.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(vp_espejo)
		move_child(vp_espejo, 0)
		camara_espejo = Camera3D.new()
		camara_espejo.near = 0.02
		camara_espejo.far = 60.0
		# El suelo va en la capa 2 y esta cámara solo ve la 1: no se refleja a sí
		# mismo.
		camara_espejo.cull_mask = 1
		vp_espejo.add_child(camara_espejo)
		camara_espejo.current = true

	var capa := CanvasLayer.new()
	add_child(capa)
	var pantalla := TextureRect.new()
	pantalla.texture = vp.get_texture()
	pantalla.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pantalla.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pantalla.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(pantalla)

## Un fuego. POR QUÉ ES UN FOCO Y NO UN OMNI: en Compatibility la sombra de un
## omni va a un cubo de poca resolución, y de cerca sale a escalones de ocho
## píxeles por mucho que crezca el atlas (probado con 4096 y con 8192: igual).
## Un foco gasta toda su casilla del atlas en su cono y la sombra sale limpia.
## Así que el fuego es un foco con sombra hacia la fila, más un omni flojo y sin
## sombra para lo que queda fuera del cono. En la mesa esto es cosa del
## entorno; aquí solo importa que la sombra no distraiga de la superficie.
func _fuego_en(pos: Vector3) -> void:
	var color := Color(1.0, 0.62, 0.30)
	if _fuego == "omni":
		var fuego := OmniLight3D.new()
		fuego.light_color = color
		fuego.light_energy = 2.2
		fuego.omni_range = 3.5
		fuego.shadow_enabled = true
		fuego.position = pos
		vp.add_child(fuego)
		return
	var foco := SpotLight3D.new()
	foco.light_color = color
	foco.light_energy = 1.75
	foco.spot_range = 3.5
	foco.spot_angle = 62.0
	foco.spot_angle_attenuation = 0.5
	foco.shadow_enabled = true
	foco.shadow_bias = 0.3
	foco.shadow_normal_bias = 2.5
	vp.add_child(foco)
	foco.look_at_from_position(pos, Vector3(pos.x, 0.1, -0.5), Vector3.UP)
	var resto := OmniLight3D.new()
	resto.light_color = color
	resto.light_energy = 0.45
	resto.omni_range = 3.5
	resto.position = pos
	vp.add_child(resto)

## El suelo y el fondo: losa mojada, un poyo de sillar para la fila de atrás y
## una pared detrás. EL SUELO VA EN TROZOS de 1,5: Compatibility aplica como
## mucho ocho luces por malla, y un suelo entero se queda sin las que le sobran.
func _montar_cripta(ancho: float) -> void:
	var de_losa := {}
	if _espejo:
		de_losa = {"reflejo": vp_espejo.get_texture(), "fuerza_reflejo": 0.7}
	var losa: Material = mat.dame("losa", _con_depura(de_losa))
	var plano := PlaneMesh.new()
	plano.size = Vector2(1.5, 1.5)
	var nx := int(ceil((ancho + 7.0) / 1.5))
	for j in 4:
		for i in nx:
			var mi := MeshInstance3D.new()
			mi.mesh = plano
			mi.material_override = losa
			mi.layers = 2
			mi.position = Vector3((float(i) - float(nx - 1) * 0.5) * 1.5, 0.0, 2.25 - float(j) * 1.5)
			vp.add_child(mi)
	# El poyo, de una pieza y con su canto: es lo que más cerca queda de la cámara.
	var poyo := MeshInstance3D.new()
	poyo.mesh = _malla_bloque(Vector3(ancho + 6.0, ALTO_POYO, 0.78), 0.014, false)
	poyo.material_override = mat.dame("piedra", _con_depura({"juntas": Vector3(0.62, 0.30, 0.42)}))
	poyo.position = Vector3(0.0, ALTO_POYO * 0.5, FONDO - 0.02)
	vp.add_child(poyo)
	# La pared, en tramos a tope y sin bisel: las juntas las pinta el material.
	var tramos := int(ceil((ancho + 7.0) / 1.5))
	var caja := BoxMesh.new()
	caja.size = Vector3(1.5, 2.4, 0.3)
	for i in tramos:
		var pared := MeshInstance3D.new()
		pared.mesh = caja
		pared.material_override = mat.dame("piedra", _con_depura({"juntas": Vector3(0.62, 0.30, 0.42),
			"mojado": 0.35, "escala": 0.9}))
		pared.position = Vector3((float(i) - float(tramos - 1) * 0.5) * 1.5, 1.2, FONDO - 0.02 - 0.39 - 0.15)
		vp.add_child(pared)

func _con_depura(variante: Dictionary) -> Dictionary:
	if _depura > 0:
		variante["depura"] = _depura
	return variante

# --------------------------------------------------------------- los catorce

func _montar_materiales() -> void:
	var ancho := float(FILA_DELANTE.size()) * PASO
	_montar_cripta(ancho)
	var centros: Dictionary = {}
	for fila in 2:
		# Sin ternario: de un ternario, un `Array[String]` sale sin tipar.
		var lista: Array[String] = FILA_DELANTE
		if fila == 1:
			lista = FILA_DETRAS
		for i in lista.size():
			var base := _sitio(i, lista.size(), fila)
			_grupo(lista[i], {}, base)
			centros[lista[i]] = base
	# El ascua y el arcano, cada uno con su luz al lado: sin ella son una pegatina.
	_luz_al_lado(centros["ascua"], Color(1.0, 0.55, 0.22), 1.3)
	_luz_al_lado(centros["arcano"], Color(0.62, 0.42, 0.95), 0.9)

	var mitad := Vector3(0.0, 0.16, FONDO * 0.5)
	if _solo == "":
		_tomas.append({"nombre": "01_general", "pos": Vector3(0.0, 2.0, 4.0),
			"mira": mitad + Vector3(0.0, 0.0, 0.05), "fov": 36.0})
		_tomas.append({"nombre": "02_rasante", "pos": Vector3(-2.9, 0.36, 1.05),
			"mira": Vector3(-0.55, 0.13, -0.32), "fov": 34.0})
		_tomas.append({"nombre": "03_cenital", "pos": Vector3(0.0, 5.3, FONDO * 0.5 + 0.55),
			"mira": Vector3(0.0, 0.0, FONDO * 0.5 + 0.02), "fov": 36.0})
	if _detalle or _solo != "":
		var pedidos := _solo.split(",", false)
		var todos: Array[String] = []
		todos.append_array(FILA_DELANTE)
		todos.append_array(FILA_DETRAS)
		for k in todos.size():
			var nombre := todos[k]
			if _solo != "" and not pedidos.has(nombre):
				continue
			var c: Vector3 = centros[nombre]
			_tomas.append({"nombre": "%02d_%s" % [10 + k, nombre], "pos": c + Vector3(0.32, 0.40, 0.78),
				"mira": c + Vector3(0.0, 0.11, 0.0), "fov": 30.0})

func _sitio(i: int, cuantos: int, fila: int) -> Vector3:
	return Vector3((float(i) - float(cuantos - 1) * 0.5) * PASO,
		ALTO_POYO if fila == 1 else 0.0, FONDO if fila == 1 else 0.0)

## Un material sobre sus tres formas, alrededor de «base». «giro» es lo que va
## girado el bloque: con el dibujo en el mundo (lo normal) da igual, y con
## «local» es lo que enseña que el dibujo gira con la pieza.
func _grupo(nombre: String, variante: Dictionary, base: Vector3, giro: float = 12.0) -> void:
	var con_vertice := variante.duplicate()
	con_vertice["vertice"] = true
	var bloque := MeshInstance3D.new()
	bloque.mesh = _malla_bloque(Vector3(0.36, 0.24, 0.20), 0.016, true)
	bloque.material_override = mat.dame(nombre, _con_depura(con_vertice))
	bloque.position = base + Vector3(-0.02, 0.12, -0.13)
	bloque.rotation_degrees.y = giro
	vp.add_child(bloque)
	var liso: Material = mat.dame(nombre, _con_depura(variante.duplicate()))
	# El cilindro de madera es un poste: su veta sube. Con la veta de través, un
	# torneado enseña los anillos como manchas y parece una piedra rara.
	var de_pie := variante.duplicate()
	if nombre == "madera" and not de_pie.has("veta"):
		de_pie["veta"] = Vector3.UP
	var poste: Material = mat.dame(nombre, _con_depura(de_pie))
	var esfera := MeshInstance3D.new()
	var bola := SphereMesh.new()
	bola.radius = 0.105
	bola.height = 0.21
	bola.radial_segments = 56
	bola.rings = 28
	esfera.mesh = bola
	esfera.material_override = liso
	esfera.position = base + Vector3(-0.13, 0.105, 0.14)
	vp.add_child(esfera)
	var cilindro := MeshInstance3D.new()
	cilindro.mesh = _malla_cilindro(0.075, 0.25, 0.014)
	cilindro.material_override = poste
	cilindro.position = base + Vector3(0.14, 0.0, 0.11)
	vp.add_child(cilindro)

func _luz_al_lado(base: Vector3, color: Color, energia: float) -> void:
	var luz := OmniLight3D.new()
	luz.light_color = color
	luz.light_energy = energia
	luz.omni_range = 1.1
	luz.position = base + Vector3(0.02, 0.2, 0.32)
	vp.add_child(luz)

# --------------------------------------------------------------- las variantes

## Los mandos, de dos en dos o de tres en tres: se ve de un vistazo qué hace cada
## clave de la variante, y si alguna no hace nada.
func _montar_variantes() -> void:
	# nombre, variante, giro del bloque
	var delante: Array[Array] = [
		["piedra", {"mojado": 0.0}, 12.0], ["piedra", {"mojado": 0.5}, 12.0], ["piedra", {"mojado": 1.0}, 12.0],
		["hierro", {"desgaste": 0.0, "suciedad": 0.0}, 12.0], ["hierro", {"desgaste": 1.0}, 12.0],
		["hierro", {"suciedad": 1.0}, 12.0], ["piedra", {"escala": 0.15}, 12.0],
	]
	var detras: Array[Array] = [
		["madera", {}, 55.0], ["madera", {"local": true, "semilla": 3.0}, 55.0],
		["bronce", {"suciedad": 0.0, "rugosidad": 0.6}, 12.0], ["bronce", {"suciedad": 1.0}, 12.0],
		["piedra", {"tinte": Paleta.COBRE_3, "juntas": 0.16}, 12.0],
		["carbon", {"emision": 3.0}, 12.0], ["cera", {"emision": 1.2}, 12.0],
	]
	_montar_cripta(float(delante.size()) * PASO)
	var centros: Array[Vector3] = []
	for fila in 2:
		var lista: Array[Array] = delante
		if fila == 1:
			lista = detras
		for i in lista.size():
			var base := _sitio(i, lista.size(), fila)
			_grupo(str(lista[i][0]), lista[i][1], base, float(lista[i][2]))
			centros.append(base)
	_luz_al_lado(_sitio(5, 7, 1), Color(1.0, 0.55, 0.22), 1.0)
	var mitad := Vector3(0.0, 0.16, FONDO * 0.5)
	_tomas.append({"nombre": "v00_general", "pos": Vector3(0.0, 2.0, 4.0),
		"mira": mitad + Vector3(0.0, 0.0, 0.05), "fov": 36.0})
	_tomas.append({"nombre": "v01_cenital", "pos": Vector3(0.0, 5.3, FONDO * 0.5 + 0.55),
		"mira": Vector3(0.0, 0.0, FONDO * 0.5 + 0.02), "fov": 36.0})
	var rotulos: Array[String] = ["piedra_seca", "piedra_mojado05", "piedra_mojado1", "hierro_nuevo",
		"hierro_desgaste1", "hierro_suciedad1", "piedra_escala015", "madera_mundo_girada",
		"madera_local_girada", "bronce_limpio", "bronce_suciedad1", "piedra_tinte_juntas",
		"carbon_emision3", "cera_emision"]
	for k in centros.size():
		_tomas.append({"nombre": "v%02d_%s" % [10 + k, rotulos[k]], "pos": centros[k] + Vector3(0.32, 0.40, 0.78),
			"mira": centros[k] + Vector3(0.0, 0.11, 0.0), "fov": 30.0})

# ------------------------------------------------------------- una sola piedra

## LA PÁGINA DE LA PIEDRA (`--pagina=piedra`): delante, la piedra tal como la
## piden de verdad los módulos (con sus escalas, tintes y juntas), cada una en un
## bloque con el bisel plano a 45° —el de las albardillas— y un fuste. Tienen que
## parecer LA MISMA piedra. Detrás, lo demás que la crítica vio mal, en las
## formas donde fallaba: la goma en una banda de normal «de almohada» (la de las
## hondas), el latón en tubos finos con color de vértice (los raíles), el hierro y
## la madera del coro y de la viga.
func _montar_piedra() -> void:
	var delante: Array[Array] = [
		["piedra", {"vertice": true, "escala": 0.9}, "arq_piedra"],
		["piedra", {"vertice": true, "escala": 1.1, "semilla": 3.0}, "arq_sillar"],
		["piedra", {"vertice": true, "escala": 1.0, "semilla": 7.0, "juntas": Vector3(0.74, 0.34, 0.74)}, "arq_aparejo"],
		["piedra", {"vertice": true, "escala": 1.4, "semilla": 11.0, "tinte": Color(0.78, 0.78, 0.82),
			"juntas": Vector3(1.1, 0.46, 1.1)}, "arq_sala"],
		["piedra", {"vertice": true, "juntas": Vector3.ZERO, "escala": 0.3, "tinte": Color(0.7, 0.68, 0.68),
			"suciedad": 0.65}, "railes_piedra"],
		["piedra", {"escala": 0.18}, "piezas_piedra"],
		["piedra", {"escala": 0.35, "juntas": true}, "piedra_sillar"],
	]
	var detras: Array[Array] = [
		["goma", {"local": true, "escala": 0.15}, "piezas_goma"],
		["laton", {"vertice": true, "escala": 0.25}, "railes_laton"],
		["hierro", {"vertice": true, "escala": 0.22}, "railes_hierro"],
		["madera", {"vertice": true, "escala": 0.5, "veta": Vector3(0.0, 0.0, 1.0),
			"juntas": Vector3(1.1, 0.0, 0.11)}, "madera_tablas"],
		["madera", {"vertice": true, "escala": 0.5, "veta": Vector3(0.0, 0.0, 1.0)}, "arq_madera"],
		["madera", {"veta": Vector3.RIGHT, "escala": 0.8}, "atrezzo_viga"],
		["piedra", {"vertice": true, "juntas": Vector3.ZERO, "escala": 0.4, "tinte": Color(0.42, 0.42, 0.45),
			"mojado": 0.85, "semilla": 3.0}, "railes_losa"],
	]
	_montar_cripta(float(delante.size()) * PASO)
	var centros: Array[Vector3] = []
	var rotulos: Array[String] = []
	for i in delante.size():
		var base := _sitio(i, delante.size(), 0)
		var m: Material = mat.dame(str(delante[i][0]), _con_depura((delante[i][1] as Dictionary).duplicate()))
		var bloque := MeshInstance3D.new()
		bloque.mesh = _malla_albardilla(Vector3(0.46, 0.26, 0.22), 0.035)
		bloque.material_override = m
		bloque.position = base + Vector3(-0.04, 0.13, -0.1)
		vp.add_child(bloque)
		var fuste := MeshInstance3D.new()
		fuste.mesh = _malla_cilindro(0.05, 0.3, 0.01)
		fuste.material_override = m
		fuste.position = base + Vector3(0.17, 0.0, 0.14)
		vp.add_child(fuste)
		centros.append(base)
		rotulos.append(str(delante[i][2]))
	for i in detras.size():
		var base := _sitio(i, detras.size(), 1)
		var nombre := str(detras[i][0])
		var variante: Dictionary = detras[i][1]
		_grupo(nombre, variante, base)
		var m: Material = mat.dame(nombre, _con_depura(variante.duplicate()))
		if nombre == "goma":
			var banda := MeshInstance3D.new()
			banda.mesh = _malla_banda(0.32, 0.05, 0.05, 0.11)
			banda.material_override = m
			banda.position = base + Vector3(0.0, 0.0, 0.26)
			vp.add_child(banda)
		elif nombre == "laton":
			for k in 2:
				var tubo := MeshInstance3D.new()
				tubo.mesh = _malla_tubo(0.0065, 0.55)
				tubo.material_override = m
				tubo.position = base + Vector3(0.0, 0.06 + 0.05 * float(k), 0.27 - 0.03 * float(k))
				vp.add_child(tubo)
		centros.append(base)
		rotulos.append(str(detras[i][2]))
	var mitad := Vector3(0.0, 0.16, FONDO * 0.5)
	_tomas.append({"nombre": "p00_general", "pos": Vector3(0.0, 2.0, 4.0),
		"mira": mitad + Vector3(0.0, 0.0, 0.05), "fov": 36.0})
	_tomas.append({"nombre": "p01_rasante", "pos": Vector3(-2.9, 0.36, 1.05),
		"mira": Vector3(-0.55, 0.13, -0.32), "fov": 34.0})
	for k in centros.size():
		_tomas.append({"nombre": "p%02d_%s" % [10 + k, rotulos[k]], "pos": centros[k] + Vector3(0.30, 0.42, 0.74),
			"mira": centros[k] + Vector3(0.0, 0.11, 0.0), "fov": 30.0})

# ------------------------------------------------------------------ el remate

## LA PÁGINA DEL REMATE (`--pagina=remate`): lo que la segunda crítica vio mal en
## la biblioteca, en las formas y con las variantes con que lo piden los módulos.
##   Delante, el HIERRO de las piezas: la pala (local, desgaste 0,95, relieve
##   0,7), el engranaje del brasero, el hierro oxidado del brasero y la barandilla
##   del coro (tubos con color de vértice). Y la PIEDRA en un canto romo de solo
##   DOS caras, largo y fino como el de las albardillas: ahí el grano salía
##   peinado a rayas porque el plano de proyección saltaba de faceta en faceta.
##   Detrás, la MADERA (las tablas del coro, la de arquitectura y la viga de la
##   campana) y la CERA de serie y encendida.
func _montar_remate() -> void:
	var delante: Array[Array] = [
		["hierro", {"local": true, "vertice": true, "escala": 0.3, "relieve": 0.7, "desgaste": 0.95}, "pala"],
		["hierro", {"local": true, "vertice": true, "escala": 0.16}, "engranaje"],
		["hierro", {"local": true, "vertice": true, "escala": 0.12, "suciedad": 0.95, "desgaste": 0.8}, "oxidado"],
		["hierro", {"vertice": true, "escala": 0.2}, "barandilla"],
		["hierro", {"escala": 0.2}, "sin_vertice"],
	]
	var detras: Array[Array] = [
		["madera", {"vertice": true, "escala": 0.5, "veta": Vector3(0.0, 0.0, 1.0),
			"juntas": Vector3(1.1, 0.0, 0.11)}, "madera_tablas"],
		["madera", {"vertice": true, "escala": 0.5, "veta": Vector3(0.0, 0.0, 1.0)}, "arq_madera"],
		["madera", {"veta": Vector3.RIGHT, "escala": 0.8}, "atrezzo_viga"],
		["cera", {}, "cera"],
		["cera", {"emision": 1.2}, "cera_encendida"],
	]
	# Siete de ancho: el canto romo ocupa los dos sitios de la derecha delante.
	_montar_cripta(7.0 * PASO)
	var centros: Array[Vector3] = []
	var rotulos: Array[String] = []
	for i in delante.size():
		var base := _sitio(i, 7, 0)
		var nombre := str(delante[i][0])
		var variante: Dictionary = delante[i][1]
		_grupo(nombre, variante, base)
		if str(delante[i][2]) == "barandilla":
			var m: Material = mat.dame(nombre, _con_depura(variante.duplicate()))
			for k in 2:
				var tubo := MeshInstance3D.new()
				tubo.mesh = _malla_tubo(0.0065, 0.55)
				tubo.material_override = m
				tubo.position = base + Vector3(0.0, 0.06 + 0.05 * float(k), 0.27 - 0.03 * float(k))
				vp.add_child(tubo)
		centros.append(base)
		rotulos.append(str(delante[i][2]))
	# El canto romo: un metro de albardilla con sus dos aristas de arriba en dos
	# facetas, a lo largo de X (como el carril del lanzador va a lo largo de Z:
	# lo que importa es que vaya a un eje), con «vertice» como la pide arquitectura.
	var canto_base := _sitio(5, 7, 0) + Vector3(PASO * 0.5, 0.0, 0.0)
	var romo := MeshInstance3D.new()
	romo.mesh = _malla_canto_romo(Vector3(1.1, 0.26, 0.24), 0.05)
	romo.material_override = mat.dame("piedra", _con_depura({"vertice": true, "escala": 0.9}))
	romo.position = canto_base + Vector3(0.0, 0.13, 0.0)
	vp.add_child(romo)
	for i in detras.size():
		var base := _sitio(i + 1, 7, 1)
		_grupo(str(detras[i][0]), detras[i][1], base)
		centros.append(base)
		rotulos.append(str(detras[i][2]))
	var mitad := Vector3(0.0, 0.16, FONDO * 0.5)
	_tomas.append({"nombre": "r00_general", "pos": Vector3(0.0, 2.0, 4.0),
		"mira": mitad + Vector3(0.0, 0.0, 0.05), "fov": 36.0})
	for k in centros.size():
		_tomas.append({"nombre": "r%02d_%s" % [10 + k, rotulos[k]], "pos": centros[k] + Vector3(0.30, 0.42, 0.74),
			"mira": centros[k] + Vector3(0.0, 0.11, 0.0), "fov": 30.0})
	# El canto romo, de cerca y a ras (como lo ve RASANTE al pie de la mesa) y
	# desde arriba en diagonal (como SEGUIMIENTO).
	# La cámara queda dentro del largo de la pieza: la albardilla no tiene tapas.
	_tomas.append({"nombre": "r30_canto_rasante", "pos": canto_base + Vector3(-0.30, 0.33, 0.55),
		"mira": canto_base + Vector3(0.35, 0.22, 0.0), "fov": 30.0})
	_tomas.append({"nombre": "r31_canto_alto", "pos": canto_base + Vector3(-0.15, 0.85, 0.75),
		"mira": canto_base + Vector3(0.1, 0.22, 0.05), "fov": 30.0})

## Una albardilla con las dos aristas largas de arriba REDONDEADAS EN DOS FACETAS
## (0°, 45° y 90°), con la normal suave en el arco: es el canto romo de pocas
## caras de `arquitectura`. Las caras son triángulos largos y finos, de punta a
## punta: exactamente lo que hace saltar la normal sacada de las derivadas.
## Color de vértice: G=0,7 en el arco, R bajando hacia el pie.
func _malla_canto_romo(tam: Vector3, radio: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hx := tam.x * 0.5
	var hz := tam.z * 0.5
	var y0 := -tam.y * 0.5
	var y1 := tam.y * 0.5
	# El perfil de la sección (z, y, normal z, normal y, canto), de un pie al otro
	# pasando por arriba.
	var perfil: Array[Array] = []
	perfil.append([hz, y0, 1.0, 0.0, 0.0])
	for k in 3:
		var a := deg_to_rad(45.0 * float(k))
		perfil.append([hz - radio + cos(a) * radio, y1 - radio + sin(a) * radio, cos(a), sin(a), 0.7])
	for k in range(2, -1, -1):
		var a := deg_to_rad(45.0 * float(k))
		perfil.append([-(hz - radio + cos(a) * radio), y1 - radio + sin(a) * radio, -cos(a), sin(a), 0.7])
	perfil.append([-hz, y0, -1.0, 0.0, 0.0])
	for k in perfil.size() - 1:
		var p0: Array = perfil[k]
		var p1: Array = perfil[k + 1]
		# Una cara plana entre dos puntos del arco con la misma normal en los dos
		# extremos sería otra cosa: aquí cada punto lleva SU normal, como en la mesa.
		var a0 := Vector3(-hx, float(p0[1]), float(p0[0]))
		var b0 := Vector3(hx, float(p0[1]), float(p0[0]))
		var a1 := Vector3(-hx, float(p1[1]), float(p1[0]))
		var b1 := Vector3(hx, float(p1[1]), float(p1[0]))
		var n0 := Vector3(0.0, float(p0[3]), float(p0[2])).normalized()
		var n1 := Vector3(0.0, float(p1[3]), float(p1[2])).normalized()
		# En las caras de pie la normal no se suaviza con el arco: va la de la cara.
		if k == 0 or k == perfil.size() - 2:
			var cara := n0 if k == 0 else n1
			n0 = cara
			n1 = cara
		var c0 := Color(lerpf(0.45, 1.0, clampf((float(p0[1]) - y0) / tam.y, 0.0, 1.0)), float(p0[4]), 0.0)
		var c1 := Color(lerpf(0.45, 1.0, clampf((float(p1[1]) - y0) / tam.y, 0.0, 1.0)), float(p1[4]), 0.0)
		var pts: Array[Vector3] = [a0, b0, b1, a1]
		var nrs: Array[Vector3] = [n0, n0, n1, n1]
		var cols: Array[Color] = [c0, c0, c1, c1]
		var orden: Array[int] = [0, 1, 2, 0, 2, 3]
		if (b0 - a0).cross(b1 - a0).dot(n0 + n1) > 0.0:
			orden = [0, 2, 1, 0, 3, 2]
		for o in orden:
			st.set_color(cols[o])
			st.set_normal(nrs[o])
			st.add_vertex(pts[o])
	return st.commit()

## Un bloque con el bisel PLANO a 45° en las cuatro aristas de arriba, como el
## de las albardillas y los sillares de `arquitectura`: caras planas a normal
## fija, y en el color de vértice G=0,7 en el bisel y R bajando hacia el pie.
func _malla_albardilla(tam: Vector3, bisel: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hx := tam.x * 0.5
	var hz := tam.z * 0.5
	var y0 := -tam.y * 0.5
	var y1 := tam.y * 0.5
	var yb := y1 - bisel
	var ix := hx - bisel
	var iz := hz - bisel
	var aire := func(y: float) -> float: return lerpf(0.4, 1.0, clampf((y - y0) / tam.y, 0.0, 1.0))
	# Arriba.
	_cuadro(st, Vector3(-ix, y1, -iz), Vector3(ix, y1, -iz), Vector3(ix, y1, iz), Vector3(-ix, y1, iz),
		Vector3.UP, Color(1.0, 0.0, 0.0))
	# Los cuatro lados y sus biseles: (dirección de fuera, eje a lo largo, medio largo, medio fondo)
	for lado: Array in [[Vector3.RIGHT, Vector3.BACK, hz, hx], [Vector3.LEFT, Vector3.BACK, hz, hx],
			[Vector3.BACK, Vector3.RIGHT, hx, hz], [Vector3.FORWARD, Vector3.RIGHT, hx, hz]]:
		var f: Vector3 = lado[0]
		var a: Vector3 = lado[1]
		var largo: float = lado[2]
		var fondo: float = lado[3]
		var dentro := largo - bisel
		var r0: float = aire.call(y0)
		var r1: float = aire.call(yb)
		_cuadro(st, f * fondo + a * -largo + Vector3.UP * y0, f * fondo + a * largo + Vector3.UP * y0,
			f * fondo + a * largo + Vector3.UP * yb, f * fondo + a * -largo + Vector3.UP * yb,
			f, Color(r0, 0.0, 0.0), Color(r1, 0.0, 0.0))
		_cuadro(st, f * fondo + a * -largo + Vector3.UP * yb, f * fondo + a * largo + Vector3.UP * yb,
			f * (fondo - bisel) + a * dentro + Vector3.UP * y1, f * (fondo - bisel) + a * -dentro + Vector3.UP * y1,
			(f + Vector3.UP).normalized(), Color(r1, 0.7, 0.0), Color(1.0, 0.7, 0.0))
	return st.commit()

## Un cuadrilátero plano, vuelto hacia «n». Los dos primeros vértices llevan
## «c0» y los dos últimos «c1».
func _cuadro(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3,
		c0: Color, c1: Color = Color(-1.0, 0.0, 0.0)) -> void:
	if c1.r < 0.0:
		c1 = c0
	var pts: Array[Vector3] = [a, b, c, d]
	var cols: Array[Color] = [c0, c0, c1, c1]
	var orden: Array[int] = [0, 1, 2, 0, 2, 3]
	# Godot pinta la cara cuyo triángulo va a derechas visto desde fuera.
	if (b - a).cross(c - a).dot(n) > 0.0:
		orden = [0, 2, 1, 0, 3, 2]
	for k in orden:
		st.set_color(cols[k])
		st.set_normal(n)
		st.add_vertex(pts[k])

## Una banda de goma como la de las hondas de `piezas`: un lazo de estadio con la
## sección de esquinas romas y la NORMAL «DE ALMOHADA» (girada hacia arriba en la
## mitad alta de la cara de pie). Es la forma en que el triplanar chorreaba.
func _malla_banda(recto: float, radio: float, alto: float, y_base: float) -> ArrayMesh:
	var camino := PackedVector2Array()
	for lado in 2:
		var cx := recto * 0.5 * (1.0 if lado == 0 else -1.0)
		for s in 13:
			var ang := -PI * 0.5 + PI * float(s) / 12.0 + (PI if lado == 1 else 0.0)
			camino.append(Vector2(cx + cos(ang) * radio, sin(ang) * radio))
	var grueso := 0.012
	var romo := 0.004
	var perfil: Array[Vector2] = []
	var y0 := y_base - alto * 0.5
	var y1 := y_base + alto * 0.5
	for esquina: Array in [[grueso - romo, y0 + romo, -90.0], [grueso - romo, y1 - romo, 0.0],
			[-grueso + romo, y1 - romo, 90.0], [-grueso + romo, y0 + romo, 180.0]]:
		for s in 4:
			var ang := deg_to_rad(float(esquina[2]) + 30.0 * float(s))
			perfil.append(Vector2(float(esquina[0]) + cos(ang) * romo, float(esquina[1]) + sin(ang) * romo))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var m := camino.size()
	var np := perfil.size()
	var anillos: Array[PackedVector3Array] = []
	var normales: Array[PackedVector3Array] = []
	for i in m:
		var tg := (camino[(i + 1) % m] - camino[(i - 1 + m) % m]).normalized()
		var fuera := Vector2(tg.y, -tg.x)
		if fuera.dot(camino[i]) < 0.0:
			fuera = -fuera
		var anillo := PackedVector3Array()
		var nrm := PackedVector3Array()
		for k in np:
			var pr := perfil[k]
			var base := camino[i] + fuera * pr.x
			anillo.append(Vector3(base.x, pr.y, base.y))
			var dn := pr - Vector2(0.0, y_base)
			dn.y *= 2.5
			dn = dn.normalized()
			nrm.append(Vector3(fuera.x * dn.x, dn.y, fuera.y * dn.x).normalized())
		anillos.append(anillo)
		normales.append(nrm)
	for i in m:
		var a := anillos[i]
		var b := anillos[(i + 1) % m]
		var na := normales[i]
		var nb := normales[(i + 1) % m]
		for k in np:
			var k2 := (k + 1) % np
			var hacia := na[k] + na[k2] + nb[k] + nb[k2]
			var tri: Array[Array] = [[a[k], na[k]], [a[k2], na[k2]], [b[k2], nb[k2]],
				[a[k], na[k]], [b[k2], nb[k2]], [b[k], nb[k]]]
			for t in 2:
				var p0: Vector3 = tri[t * 3][0]
				var p1: Vector3 = tri[t * 3 + 1][0]
				var p2: Vector3 = tri[t * 3 + 2][0]
				var orden: Array[int] = [0, 1, 2]
				if (p1 - p0).cross(p2 - p0).dot(hacia) > 0.0:
					orden = [0, 2, 1]
				for o in orden:
					st.set_normal(tri[t * 3 + o][1])
					st.add_vertex(tri[t * 3 + o][0])
	return st.commit()

## Un tubo fino a lo largo de X, con el color de vértice de `railes`: R por lo
## que mira arriba, G bajo (un tubo no es un filo).
func _malla_tubo(radio: float, largo: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const LADOS := 12
	const TRAMOS := 8
	for t in TRAMOS:
		var x0 := -largo * 0.5 + largo * float(t) / float(TRAMOS)
		var x1 := -largo * 0.5 + largo * float(t + 1) / float(TRAMOS)
		for s in LADOS:
			var a0 := TAU * float(s) / float(LADOS)
			var a1 := TAU * float(s + 1) / float(LADOS)
			var n0 := Vector3(0.0, cos(a0), sin(a0))
			var n1 := Vector3(0.0, cos(a1), sin(a1))
			var quad: Array[Array] = [[x0, n0], [x1, n0], [x1, n1], [x0, n0], [x1, n1], [x0, n1]]
			var p0 := Vector3(x0, 0.0, 0.0) + n0 * radio
			var p1 := Vector3(x1, 0.0, 0.0) + n0 * radio
			var p2 := Vector3(x1, 0.0, 0.0) + n1 * radio
			var orden: Array[int] = [0, 1, 2, 3, 4, 5]
			if (p1 - p0).cross(p2 - p0).dot(n0 + n1) > 0.0:
				orden = [0, 2, 1, 3, 5, 4]
			for o in orden:
				var x: float = quad[o][0]
				var n: Vector3 = quad[o][1]
				st.set_color(Color(lerpf(0.5, 1.0, n.y * 0.5 + 0.5), 0.2, 0.0))
				st.set_normal(n)
				st.add_vertex(Vector3(x, 0.0, 0.0) + n * radio)
	return st.commit()

# ------------------------------------------------------------------ las mallas

## Los cortes de una cara a lo largo de un eje de media longitud «m»: el arco del
## bisel (repartido en ángulo, no en distancia), el arranque del bisel, una
## franja «franja» más adentro —donde el desgaste se apaga— y el resto a partes
## iguales.
func _cortes(m: float, radio: float, franja: float, partes: int) -> PackedFloat32Array:
	const ARCO := 3
	var l := PackedFloat32Array()
	var plano := m - radio
	for k in range(ARCO, 0, -1):
		l.append(-(plano + radio * tan(deg_to_rad(45.0) * float(k) / float(ARCO))))
	l.append(-plano)
	var dentro := maxf(plano - franja, plano * 0.5)
	l.append(-dentro)
	for k in range(1, partes):
		l.append(lerpf(-dentro, dentro, float(k) / float(partes)))
	l.append(dentro)
	l.append(plano)
	for k in range(1, ARCO + 1):
		l.append(plano + radio * tan(deg_to_rad(45.0) * float(k) / float(ARCO)))
	return l

## Una caja con los cantos REDONDEADOS de verdad: cada cara es una rejilla, cada
## punto se sujeta a la caja interior (la caja menos el radio) y se empuja el
## radio hacia fuera. La normal sale de ese mismo empujón, así que la cara es
## plana, el bisel es un arco y la esquina un octavo de esfera, sin costuras.
##
## Con «pintar», lleva el color de vértice de la convención: G=1 en el bisel,
## apagándose centímetro y medio cara adentro; R=1 arriba y bajando hacia la
## base, que es donde se junta la mugre y no llega la luz.
func _malla_bloque(tam: Vector3, radio: float, pintar: bool) -> ArrayMesh:
	var medio := tam * 0.5
	var dentro := medio - Vector3.ONE * radio
	var vertices := PackedVector3Array()
	var normales := PackedVector3Array()
	var colores := PackedColorArray()
	var indices := PackedInt32Array()
	const FRANJA := 0.015
	# eje de la normal, eje U, eje V, y el signo con el que U×V sale hacia fuera
	var caras: Array[Array] = [[0, 2, 1, -1.0], [1, 0, 2, -1.0], [2, 0, 1, 1.0]]
	for cara: Array in caras:
		var ew: int = cara[0]
		var eu: int = cara[1]
		var ev: int = cara[2]
		var us := _cortes(medio[eu], radio, FRANJA, maxi(int(tam[eu] / 0.08), 2))
		var vs := _cortes(medio[ev], radio, FRANJA, maxi(int(tam[ev] / 0.08), 2))
		for signo: float in [-1.0, 1.0]:
			var primero := vertices.size()
			for j in vs.size():
				for i in us.size():
					var p := Vector3.ZERO
					p[eu] = us[i]
					p[ev] = vs[j]
					p[ew] = signo * medio[ew]
					var c := p.clamp(-dentro, dentro)
					var n := (p - c).normalized()
					var pos := c + n * radio
					vertices.append(pos)
					normales.append(n)
					var a_borde := minf(dentro[eu] - absf(us[i]), dentro[ev] - absf(vs[j]))
					var canto := 1.0 - smoothstep(0.0, FRANJA, a_borde)
					var aire := lerpf(0.35, 1.0, smoothstep(-medio.y, -medio.y + tam.y * 0.45, pos.y))
					colores.append(Color(aire, canto, 1.0, 1.0))
			var hacia_fuera: bool = float(cara[3]) * signo > 0.0
			for j in vs.size() - 1:
				for i in us.size() - 1:
					var a := primero + j * us.size() + i
					var b := a + 1
					var d := a + us.size()
					var c2 := d + 1
					# Godot pinta la cara cuyo triángulo va a derechas visto desde fuera.
					if hacia_fuera:
						indices.append_array(PackedInt32Array([a, c2, b, a, d, c2]))
					else:
						indices.append_array(PackedInt32Array([a, b, c2, a, c2, d]))
	var datos: Array = []
	datos.resize(Mesh.ARRAY_MAX)
	datos[Mesh.ARRAY_VERTEX] = vertices
	datos[Mesh.ARRAY_NORMAL] = normales
	if pintar:
		datos[Mesh.ARRAY_COLOR] = colores
	datos[Mesh.ARRAY_INDEX] = indices
	var malla := ArrayMesh.new()
	malla.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, datos)
	return malla

## Un cilindro torneado, con la base en y=0 y el canto de arriba redondeado. SIN
## color de vértice: es el testigo de lo que se ve cuando nadie lo ha pintado.
func _malla_cilindro(radio: float, alto: float, bisel: float) -> ArrayMesh:
	# El perfil: (radio, altura, normal en r, normal en y)
	var perfil: Array[Vector4] = []
	perfil.append(Vector4(radio, 0.0, 1.0, 0.0))
	perfil.append(Vector4(radio, alto * 0.5, 1.0, 0.0))
	const ARCO := 5
	for k in ARCO + 1:
		var a := deg_to_rad(90.0) * float(k) / float(ARCO)
		perfil.append(Vector4(radio - bisel + cos(a) * bisel, alto - bisel + sin(a) * bisel, cos(a), sin(a)))
	perfil.append(Vector4((radio - bisel) * 0.5, alto, 0.0, 1.0))
	perfil.append(Vector4(0.0, alto, 0.0, 1.0))
	const GAJOS := 48
	var vertices := PackedVector3Array()
	var normales := PackedVector3Array()
	var indices := PackedInt32Array()
	for g in GAJOS + 1:
		var ang := TAU * float(g) / float(GAJOS)
		var ca := cos(ang)
		var sa := sin(ang)
		for pt: Vector4 in perfil:
			vertices.append(Vector3(ca * pt.x, pt.y, sa * pt.x))
			normales.append(Vector3(ca * pt.z, pt.w, sa * pt.z))
	var np := perfil.size()
	for g in GAJOS:
		for k in np - 1:
			var a := g * np + k
			var b := a + np
			indices.append_array(PackedInt32Array([a, b + 1, a + 1, a, b, b + 1]))
	var datos: Array = []
	datos.resize(Mesh.ARRAY_MAX)
	datos[Mesh.ARRAY_VERTEX] = vertices
	datos[Mesh.ARRAY_NORMAL] = normales
	datos[Mesh.ARRAY_INDEX] = indices
	var malla := ArrayMesh.new()
	malla.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, datos)
	return malla

# ------------------------------------------------------------------ las tomas

func _guion() -> void:
	for k in ESPERA_PRIMERA:
		await get_tree().process_frame
	for toma: Dictionary in _tomas:
		var pos: Vector3 = toma["pos"]
		var mira: Vector3 = toma["mira"]
		camara.fov = float(toma["fov"])
		camara.look_at_from_position(pos, mira, Vector3.UP)
		if camara_espejo != null:
			# La misma, simétrica respecto al suelo (y=0).
			camara_espejo.fov = camara.fov
			camara_espejo.look_at_from_position(Vector3(pos.x, -pos.y, pos.z),
				Vector3(mira.x, -mira.y, mira.z), Vector3.UP)
		for k in ESPERA:
			await get_tree().process_frame
		if _dir != "":
			await RenderingServer.frame_post_draw
			var img := vp.get_texture().get_image()
			var ruta := _dir.path_join(str(toma["nombre"]) + ".png")
			img.save_png(ruta)
			_n += 1
			print("captura: ", ruta)
	print("MUESTRARIO: fin, %d capturas en %s" % [_n, _dir])
