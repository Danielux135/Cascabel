extends Node
## BANCO DE SOMBREADORES: cuánto tarda en COMPILAR cada sombreador.
##
## POR QUÉ EXISTE. Con el OpenGL de escritorio todos compilan en milésimas y
## nadie se entera. En un navegador de Windows, WebGL pasa por ANGLE: el GLSL se
## traduce a HLSL y lo compila Direct3D, que tarda cien veces más. Medido el
## 21-nov-2026: la primera lanzada de CRIPTA con ANGLE tardó 212 s y la segunda,
## con la caché ya caliente, 15. En una página eso son tres minutos de lienzo
## congelado en la primera visita.
##
## El Godot de escritorio trae ANGLE dentro: `--rendering-driver opengl3_angle`
## es el mismo traductor que usa Chrome, y se mide aquí sin exportar nada.
##
##     python cripta3d/herramientas/godot3d.py escena res://cripta3d/banco_sombreadores.tscn --fotogramas 900 --tiempo 1200 --lineas 90 --rendering-driver opengl3_angle -- [--solo=texto] [--caliente] [--patrones] [--luces=of] [--salida=fichero.json]
##
##   --solo=texto   solo los ficheros cuya ruta contenga el texto (se repite)
##   --caliente     NO le cambia la huella al sombreador: mide con lo que haya en
##                  la caché (lo que tarda una segunda visita)
##   --patrones     además, el sombreador vacío con cada modo de render y con
##                  cada salida escrita: lo que cuesta cada trozo de Godot
##   --luces=letras qué luces hay: «o» una omni, «f» un foco, «s» una omni CON
##                  sombra. Por defecto «of», que es lo de MEDIA y BAJA; «ofs» es
##                  lo de ALTA; vacío, sin luces. Godot compila un programa
##                  distinto por cada combinación que le toque a una malla
##   --salida=ruta  además de por consola, lo deja en un JSON (FUERA del repo)
##   --fichero=ruta un sombreador suelto de FUERA del repo (se repite): para
##                  probar una idea sin dejar un fichero de paso en el proyecto.
##                  Con él y sin `--solo`, mide solo los sueltos
##
## LO QUE SE APRENDIÓ CON ÉL (21-nov-2026, GTX 1060 y un procesador de 4 hilos):
##   - Un sombreador VACÍO con luz cuesta 5,6 s; con `specular_disabled`, 2,9;
##     con `vertex_lighting`, 0,9; `unshaded`, 0,3. Escribir CLEARCOAT, 9,2.
##   - Da igual qué luces haya. Godot, la primera vez que usa un sombreador,
##     compila CUATRO variantes «por defecto» (color, color con instancias y las
##     dos de profundidad) con TODOS los tipos de luz dentro —direccional, omni,
##     foco y de área—, que en una escena sin lightmaps no usa nunca, y luego la
##     variante de verdad (`shader_gles3.cpp`, `_initialize_version`).
##   - Por eso el código propio se paga varias veces: cada línea del `fragment`
##     entra en todas esas variantes. La calavera, con su ruido por bucles, eran
##     34,5 s.
##
## CÓMO MIDE. Pone cada sombreador en una esfera delante de la cámara y cuenta lo
## que tarda el fotograma en que se dibuja por primera vez: ahí dentro compila
## Godot todas las variantes que ese fotograma necesita (la de color, la de
## profundidad y, si hay una luz con sombra, la de la sombra y la aditiva). Para
## que la caché de Godot no conteste por él, a cada sombreador se le añade un
## `uniform` de nombre nuevo: cambia el código generado y con él su huella.
##
## Los tres primeros no son de CRIPTA: son PATRONES, para saber cuánto cuesta el
## sombreador de escena de Godot por sí solo, que va dentro de todos los demás.
##
## No es una prueba: no falla, informa. Se cierra con `--quit-after` (la
## herramienta lo pone): cuando escribe «banco: FIN» ha acabado.

const CARPETAS: Array[String] = ["res://cripta3d", "res://prueba3d"]

const PATRONES := {
	"(patrón) vacío con luz": "shader_type spatial;\nvoid fragment() {\n\tALBEDO = vec3(0.5);\n}\n",
	"(patrón) vacío sin luz": "shader_type spatial;\nrender_mode unshaded;\nvoid fragment() {\n\tALBEDO = vec3(0.5);\n}\n",
	"(patrón) vacío sin luz ni niebla": "shader_type spatial;\nrender_mode unshaded, fog_disabled, shadows_disabled;\nvoid fragment() {\n\tALBEDO = vec3(0.5);\n}\n",
}

## Con `--patrones`: el mismo sombreador vacío con cada modo de render, para
## saber cuánto abarata cada uno la parte de Godot. Es lo que dice qué modos
## merece la pena pedir en un sombreador de verdad.
const MODOS_A_PROBAR: Array[String] = [
	"specular_disabled",
	"diffuse_lambert",
	"diffuse_lambert, specular_disabled",
	"shadows_disabled",
	"ambient_light_disabled",
	"fog_disabled",
	"vertex_lighting",
	"diffuse_lambert, specular_disabled, shadows_disabled",
	"diffuse_lambert, specular_disabled, shadows_disabled, ambient_light_disabled, fog_disabled",
	"blend_add, depth_draw_never, cull_disabled",
	"depth_prepass_alpha",
]
## Lo mismo, pero escribiendo lo que escribe un material de verdad: cada salida
## que se toca enciende un trozo más del sombreador de Godot.
const SALIDAS_A_PROBAR := {
	"escribe ROUGHNESS, METALLIC y SPECULAR": "\tROUGHNESS = 0.6;\n\tMETALLIC = 0.2;\n\tSPECULAR = 0.4;\n",
	"escribe NORMAL": "\tNORMAL = normalize(NORMAL + vec3(0.01));\n",
	"escribe NORMAL_MAP": "\tNORMAL_MAP = vec3(0.5, 0.5, 1.0);\n",
	"escribe EMISSION": "\tEMISSION = vec3(0.2);\n",
	"escribe AO": "\tAO = 0.7;\n",
	"escribe RIM": "\tRIM = 0.4;\n",
	"escribe CLEARCOAT": "\tCLEARCOAT = 0.5;\n",
	"escribe BACKLIGHT": "\tBACKLIGHT = vec3(0.2);\n",
	"escribe ALPHA": "\tALPHA = 0.5;\n",
	"función light() propia": "",
}

var _solo: Array[String] = []
## Sombreadores sueltos de FUERA del repo (`--fichero=C:/ruta/prueba.gdshader`):
## para probar una idea sin dejar un fichero de paso en el proyecto.
var _ficheros: Array[String] = []
var _caliente := false
var _con_patrones := false
## Qué luces hay: «o» una omni, «f» un foco, «s» una omni CON sombra.
var _luces := "of"
var _salida := ""
var _entorno: Environment
var _capa: CanvasLayer
var _serie := 0
var _resultados: Array[Dictionary] = []

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--solo="):
			_solo.append(arg.trim_prefix("--solo="))
		elif arg == "--caliente":
			_caliente = true
		elif arg == "--patrones":
			_con_patrones = true
		elif arg.begins_with("--fichero="):
			_ficheros.append(arg.trim_prefix("--fichero="))
		elif arg.begins_with("--luces="):
			_luces = arg.trim_prefix("--luces=").to_lower()
		elif arg.begins_with("--salida="):
			_salida = arg.trim_prefix("--salida=")
	_montar()
	_medir_todo()

## Lo mínimo que hace que Godot elija las mismas variantes que en la mesa: niebla
## de profundidad y de altura, brillo, curva de tono y luces de los dos tipos.
func _montar() -> void:
	_entorno = Environment.new()
	_entorno.background_mode = Environment.BG_COLOR
	_entorno.background_color = Color(0.02, 0.02, 0.04)
	_entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_entorno.ambient_light_color = Color(0.30, 0.37, 0.56)
	_entorno.ambient_light_energy = 0.5
	_entorno.fog_enabled = true
	_entorno.fog_density = 0.01
	_entorno.fog_height = -0.05
	_entorno.fog_height_density = 0.6
	_entorno.glow_enabled = true
	_entorno.tonemap_mode = Environment.TONE_MAPPER_AGX
	_entorno.adjustment_enabled = true
	var mundo := WorldEnvironment.new()
	mundo.environment = _entorno
	add_child(mundo)

	var camara := Camera3D.new()
	camara.position = Vector3(0.0, 0.0, 3.0)
	camara.fov = 40.0
	add_child(camara)
	camara.make_current()

	if _luces.contains("o"):
		var omni := OmniLight3D.new()
		omni.position = Vector3(1.5, 1.5, 2.0)
		omni.omni_range = 8.0
		add_child(omni)
	if _luces.contains("f"):
		var foco := SpotLight3D.new()
		foco.position = Vector3(-1.5, 2.0, 2.0)
		foco.spot_range = 9.0
		add_child(foco)
		foco.look_at(Vector3.ZERO)
	if _luces.contains("s"):
		var con_sombra := OmniLight3D.new()
		con_sombra.position = Vector3(0.0, 2.0, 1.0)
		con_sombra.omni_range = 8.0
		con_sombra.shadow_enabled = true
		add_child(con_sombra)
		# Algo que reciba la sombra, o la pasada aditiva no se llega a pedir.
		var suelo := MeshInstance3D.new()
		var plano := PlaneMesh.new()
		plano.size = Vector2(6.0, 6.0)
		suelo.mesh = plano
		suelo.position = Vector3(0.0, -0.8, 0.0)
		add_child(suelo)

	_capa = CanvasLayer.new()
	add_child(_capa)

func _medir_todo() -> void:
	# Unos fotogramas en vacío: que Godot compile lo suyo (el fondo, el brillo,
	# la curva de tono) antes de empezar a contar.
	for _i in 8:
		await RenderingServer.frame_post_draw

	print("banco: driver %s · luces «%s» · %s" % [RenderingServer.get_video_adapter_name(),
		_luces, "caché tal cual" if _caliente else "en frío"])
	# Los patrones, solo cuando se mide todo o se piden: midiendo UN sombreador
	# una y otra vez son seis segundos tirados en cada lanzada.
	var con_base := _con_patrones or (_ficheros.is_empty() and _solo.is_empty())
	for nombre: String in PATRONES:
		if con_base or (not _solo.is_empty() and _pasa(nombre) and _ficheros.is_empty()):
			await _medir(nombre, PATRONES[nombre], "spatial")
	if _con_patrones:
		for modos in MODOS_A_PROBAR:
			var nombre := "(patrón) luz · %s" % modos
			if _pasa(nombre):
				await _medir(nombre, "shader_type spatial;\nrender_mode %s;\nvoid fragment() {\n\tALBEDO = vec3(0.5);\n}\n" % modos, "spatial")
		for nombre_salida: String in SALIDAS_A_PROBAR:
			var nombre := "(patrón) luz · %s" % nombre_salida
			if not _pasa(nombre):
				continue
			var codigo := "shader_type spatial;\nvoid fragment() {\n\tALBEDO = vec3(0.5);\n%s}\n" % SALIDAS_A_PROBAR[nombre_salida]
			if nombre_salida.begins_with("función light"):
				codigo += "void light() {\n\tDIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;\n}\n"
			await _medir(nombre, codigo, "spatial")

	for fichero in _ficheros:
		var texto := FileAccess.get_file_as_string(fichero)
		if texto == "":
			print("banco: NO SE LEE  %s" % fichero)
			continue
		await _medir("(suelto) " + fichero.get_file(), texto, _tipo(texto))

	var rutas: Array[String] = []
	# Con ficheros sueltos y sin `--solo`, se miden ellos y nada más.
	if _ficheros.is_empty() or not _solo.is_empty():
		for carpeta in CARPETAS:
			_buscar(carpeta, rutas)
	rutas.sort()
	for ruta in rutas:
		if not _pasa(ruta):
			continue
		var original := load(ruta) as Shader
		if original == null:
			print("banco: NO CARGA  %s" % ruta)
			continue
		await _medir(ruta, original.code, _tipo(original.code))

	_resumen()

func _pasa(ruta: String) -> bool:
	if _solo.is_empty():
		return true
	for trozo in _solo:
		if ruta.contains(trozo):
			return true
	return false

func _buscar(carpeta: String, rutas: Array[String]) -> void:
	var dir := DirAccess.open(carpeta)
	if dir == null:
		return
	for nombre in dir.get_files():
		if nombre.ends_with(".gdshader"):
			rutas.append(carpeta.path_join(nombre))
	for sub in dir.get_directories():
		_buscar(carpeta.path_join(sub), rutas)

func _tipo(codigo: String) -> String:
	var busca := RegEx.create_from_string("(?m)^\\s*shader_type\\s+([a-z_]+)")
	var hallado := busca.search(codigo)
	return hallado.get_string(1) if hallado != null else "spatial"

## El sombreador con la huella cambiada: un `uniform` que no usa nadie, con un
## nombre que no se ha visto nunca. Godot lo mete en el bloque de uniformes del
## código que genera, así que la caché no lo reconoce.
func _sombreador(codigo: String) -> Shader:
	var s := Shader.new()
	if _caliente:
		s.code = codigo
	else:
		_serie += 1
		s.code = "%s\nuniform float huella_%d_%d = 0.0;\n" % [codigo, Time.get_ticks_usec(), _serie]
	return s

func _medir(nombre: String, codigo: String, tipo: String) -> void:
	var t0 := Time.get_ticks_usec()
	var mat := ShaderMaterial.new()
	mat.shader = _sombreador(codigo)
	var nodo: Node = null
	var cielo_antes: Sky = _entorno.sky
	match tipo:
		"canvas_item":
			var rect := ColorRect.new()
			rect.size = Vector2(256.0, 256.0)
			rect.material = mat
			_capa.add_child(rect)
			nodo = rect
		"sky":
			var cielo := Sky.new()
			cielo.sky_material = mat
			_entorno.sky = cielo
			_entorno.background_mode = Environment.BG_SKY
		"spatial":
			var esfera := SphereMesh.new()
			esfera.radius = 0.6
			esfera.height = 1.2
			esfera.radial_segments = 24
			esfera.rings = 12
			var malla := MeshInstance3D.new()
			malla.mesh = esfera
			malla.material_override = mat
			add_child(malla)
			nodo = malla
		_:
			print("banco: tipo «%s» sin medir  %s" % [tipo, nombre])
			return
	await RenderingServer.frame_post_draw
	var t1 := Time.get_ticks_usec()
	await RenderingServer.frame_post_draw
	var t2 := Time.get_ticks_usec()
	await RenderingServer.frame_post_draw
	var t3 := Time.get_ticks_usec()
	if nodo != null:
		nodo.queue_free()
	if tipo == "sky":
		_entorno.background_mode = Environment.BG_COLOR
		_entorno.sky = cielo_antes
	await RenderingServer.frame_post_draw

	var fila := {
		"nombre": nombre, "tipo": tipo,
		# Lo que compila cae en el primer fotograma; a veces una variante se pide
		# en el segundo (la del brillo, la de la sombra). El tercero es el de
		# régimen, para restarlo.
		"compila_ms": maxf(float(t2 - t0) / 1000.0 - 2.0 * float(t3 - t2) / 1000.0, 0.0),
		"primero_ms": float(t1 - t0) / 1000.0,
		"segundo_ms": float(t2 - t1) / 1000.0,
		"regimen_ms": float(t3 - t2) / 1000.0,
		"bytes": codigo.length(),
	}
	_resultados.append(fila)
	print("banco: %8.0f ms  (1º %7.0f · 2º %6.0f · régimen %5.1f)  %s" % [
		fila["compila_ms"], fila["primero_ms"], fila["segundo_ms"], fila["regimen_ms"], nombre])

func _resumen() -> void:
	var orden := _resultados.duplicate()
	orden.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["compila_ms"]) > float(b["compila_ms"]))
	var total := 0.0
	for fila in orden:
		total += float(fila["compila_ms"])
	print("banco: ---------------- de más a menos ----------------")
	var acumulado := 0.0
	for fila in orden:
		acumulado += float(fila["compila_ms"])
		print("banco: %7.1f s  %5.1f %%  (acum. %5.1f %%)  %s" % [
			float(fila["compila_ms"]) / 1000.0,
			100.0 * float(fila["compila_ms"]) / maxf(total, 1.0),
			100.0 * acumulado / maxf(total, 1.0), fila["nombre"]])
	print("banco: TOTAL %.1f s en %d sombreadores" % [total / 1000.0, orden.size()])
	if _salida != "":
		var f := FileAccess.open(_salida, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify({"total_ms": total, "luces": _luces,
				"caliente": _caliente, "filas": orden}, "\t"))
			f.close()
			print("banco: escrito %s" % _salida)
	print("banco: FIN")
