extends Node

## CRIPTA 3D — EL VISOR. Un plató para mirar UN cuerpo de criatura (o un GLB) sin
## la mesa, con la luz de la cripta, y sacarle capturas de cada estado.
##
##   python cripta3d/herramientas/godot3d.py escena res://cripta3d/visor.tscn --fotogramas 900 \
##       -- --guion=res://cripta3d/criaturas/brasa.gd --especie=saltarin --capturas=C:/ruta/salida
##
##   --guion=     el guion del cuerpo. Tiene que tener el mismo contrato que
##                `prueba3d/criatura_3d.gd`: montar(criatura, fuente),
##                actualizar(delta, bola), golpear(normal), blindar(), centro()
##   --especie=   corredor | saltarin | gotita | escarabajo  (lo que lee de `Criatura`)
##   --glb=       en vez de un cuerpo, un modelo: lo gira y lo captura por ocho lados
##   --capturas=  carpeta donde deja los PNG (si falta, solo se mira)
##   --solo=      lista de prefijos separados por comas: solo esas escenas
##   --tam=       1280x960 por defecto
##
## El guion entero dura unos 16 s: con `--fotogramas 1000` sobra. Al acabar lo
## dice por la salida, con cuántas capturas ha dejado.
##
## LO QUE HACE EL VISOR POR LA CRIATURA es lo que haría la caza: le va cambiando
## el estado a una `Criatura` de mentira —correr, alerta, huir, golpe, aturdida,
## volcada, en la bola— y le mueve la posición, la velocidad y el rumbo como se
## los movería `caza_orbita.gd`. El cuerpo solo lee, igual que en la mesa.
##
## No hay ninguna forma de salir escrita aquí a propósito: la batería del juego
## no deja. Se cierra con `--fotogramas` (que es `--quit-after`).

const Criatura := preload("res://prueba3d/criatura.gd")
const E := 0.01
const CENTRO := Vector2(200.0, 1000.0)

## Los mismos números que `caza_orbita.gd`: el visor tiene que moverla igual.
const FICHAS := {
	"corredor": {"radio": 12.0, "masa": 0.5, "v_correr": 90.0, "v_huir": 185.0, "salta": false},
	"saltarin": {"radio": 13.0, "masa": 1.0, "v_correr": 0.0, "v_huir": 0.0, "salta": true,
		"bote_largo": 40.0, "bote_tiempo": 0.30, "posada_paseo": 0.30, "posada_huida": 0.10},
	"gotita": {"radio": 9.0, "masa": 0.45, "v_correr": 0.0, "v_huir": 0.0, "salta": true,
		"bote_largo": 34.0, "bote_tiempo": 0.24, "posada_paseo": 0.22, "posada_huida": 0.07},
	"escarabajo": {"radio": 17.0, "masa": 4.0, "v_correr": 42.0, "v_huir": 42.0, "salta": false},
}

## Desde dónde se mira, respecto al centro del cuerpo.
const CAMARAS := {
	"frente": {"pos": Vector3(0.0, 0.20, 0.80), "mira": Vector3(0.0, 0.13, 0.0), "fov": 30.0},
	"tres_cuartos": {"pos": Vector3(0.50, 0.52, 0.66), "mira": Vector3(0.0, 0.10, 0.0), "fov": 30.0},
	"espalda": {"pos": Vector3(-0.35, 0.40, -0.75), "mira": Vector3(0.0, 0.10, 0.0), "fov": 30.0},
	"picado": {"pos": Vector3(0.0, 1.05, 0.55), "mira": Vector3(0.0, 0.05, 0.0), "fov": 30.0},
	## Como se ve jugando: lejos y desde arriba. Si aquí no se lee, no se lee.
	"juego": {"pos": Vector3(0.0, 3.2, 2.6), "mira": Vector3(0.0, 0.0, -0.3), "fov": 36.0},
}

var _guion := ""
var _glb := ""
var _especie := "corredor"
var _dir := ""
var _solo := ""
var _ancho := 1280
var _alto := 960

var vp: SubViewport
var camara: Camera3D
var cuerpo: Node3D
var c: Criatura
var _bola_mi: MeshInstance3D
var _escenas: Array = []
var _i := -1
var _t := 0.0
var _t_escena := 0.0
var _hechas: Dictionary = {}
var _n := 0
var _ang := 0.0
var _hop := 0.0
var _en_aire := false
var _cam_centro := Vector3.ZERO
var _cam_salto := true
var _fin := false
var _glb_centro := Vector3.ZERO
var _glb_radio := 0.3

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--guion="):
			_guion = arg.trim_prefix("--guion=")
		elif arg.begins_with("--glb="):
			_glb = arg.trim_prefix("--glb=")
		elif arg.begins_with("--especie="):
			_especie = arg.trim_prefix("--especie=")
		elif arg.begins_with("--capturas="):
			_dir = arg.trim_prefix("--capturas=")
		elif arg.begins_with("--solo="):
			_solo = arg.trim_prefix("--solo=")
		elif arg.begins_with("--tam="):
			var t := arg.trim_prefix("--tam=").split("x")
			if t.size() == 2:
				_ancho = maxi(int(t[0]), 64)
				_alto = maxi(int(t[1]), 64)
	get_window().title = "Cripta 3D · visor"
	get_window().content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	if _dir != "":
		DirAccess.make_dir_recursive_absolute(_dir)
	_montar_plato()
	if _glb != "":
		_montar_glb()
	else:
		_montar_criatura()
	if _solo != "":
		var prefijos := _solo.split(",")
		var filtradas: Array = []
		for esc: Dictionary in _escenas:
			for pre in prefijos:
				if str(esc["nombre"]).begins_with(pre):
					filtradas.append(esc)
					break
		_escenas = filtradas
	var total := 0.0
	for esc: Dictionary in _escenas:
		total += float(esc["dur"])
	print("VISOR: %d escenas, %.1f s de guion: lánzalo con --fotogramas %d o más" % [
		_escenas.size(), total, int(total * 60.0) + 40])

# --------------------------------------------------------------------- el plató

func _montar_plato() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(_ancho, _alto)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	# LA LUZ DE LA CRIPTA, en pequeño: fuego cálido y bajo por delante, luna fría
	# y alta por detrás, y casi nada de ambiente. Una criatura se juzga con la luz
	# con la que se va a ver, no con la de un estudio blanco.
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

	var centro := Vector3(CENTRO.x * E, 0.0, CENTRO.y * E)
	var luna := DirectionalLight3D.new()
	luna.light_color = Color(0.62, 0.72, 0.95)
	luna.light_energy = 0.9
	luna.rotation_degrees = Vector3(-52.0, 150.0, 0.0)
	luna.shadow_enabled = true
	luna.directional_shadow_max_distance = 12.0
	vp.add_child(luna)
	var fuego := OmniLight3D.new()
	fuego.light_color = Color(1.0, 0.62, 0.30)
	fuego.light_energy = 2.2
	fuego.omni_range = 3.5
	fuego.shadow_enabled = true
	fuego.position = centro + Vector3(-0.7, 0.55, 0.6)
	vp.add_child(fuego)
	var relleno := OmniLight3D.new()
	relleno.light_color = Color(1.0, 0.80, 0.60)
	relleno.light_energy = 0.45
	relleno.omni_range = 3.0
	relleno.position = centro + Vector3(0.8, 0.3, 0.9)
	vp.add_child(relleno)

	var suelo := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(8.0, 8.0)
	suelo.mesh = plano
	var mat_suelo := StandardMaterial3D.new()
	mat_suelo.albedo_color = Color(0.16, 0.155, 0.15)
	mat_suelo.roughness = 0.62
	suelo.material_override = mat_suelo
	suelo.position = centro
	vp.add_child(suelo)

	# La bola, de testigo: mide 18 px, y todo lo demás se juzga contra ella.
	_bola_mi = MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.09
	esfera.height = 0.18
	_bola_mi.mesh = esfera
	var mat_bola := StandardMaterial3D.new()
	mat_bola.albedo_color = Color(0.75, 0.77, 0.80)
	mat_bola.metallic = 0.9
	mat_bola.roughness = 0.25
	_bola_mi.material_override = mat_bola
	vp.add_child(_bola_mi)

	camara = Camera3D.new()
	camara.near = 0.02
	camara.far = 60.0
	vp.add_child(camara)
	camara.current = true

	var capa := CanvasLayer.new()
	add_child(capa)
	var pantalla := TextureRect.new()
	pantalla.texture = vp.get_texture()
	pantalla.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pantalla.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pantalla.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(pantalla)

# ------------------------------------------------------------------ la criatura

func _montar_criatura() -> void:
	var ficha: Dictionary = FICHAS.get(_especie, FICHAS["corredor"])
	c = Criatura.new()
	c.especie = _especie
	c.nombre = _especie.to_upper()
	c.radio = ficha["radio"]
	c.masa = ficha["masa"]
	c.v_correr = ficha["v_correr"]
	c.v_huir = ficha["v_huir"]
	c.salta = ficha["salta"]
	if c.salta:
		c.bote_largo = ficha["bote_largo"]
		c.bote_tiempo = ficha["bote_tiempo"]
		c.posada_paseo = ficha["posada_paseo"]
		c.posada_huida = ficha["posada_huida"]
	c.pos = CENTRO
	c.rumbo = Vector2.DOWN

	var recurso: Resource = load(_guion) if _guion != "" else null
	if recurso == null or not (recurso is GDScript):
		print("VISOR: no puedo cargar el guion del cuerpo: ", _guion)
		_escenas = []
		return
	cuerpo = (recurso as GDScript).new() as Node3D
	if cuerpo == null:
		print("VISOR: el guion no es un Node3D: ", _guion)
		_escenas = []
		return
	if "t_cierre" in cuerpo:
		cuerpo.set("t_cierre", 5.0)
	if "t_volcada" in cuerpo:
		cuerpo.set("t_volcada", 5.0)
	if "arco_blindaje" in cuerpo:
		cuerpo.set("arco_blindaje", 70.0)
	vp.add_child(cuerpo)
	var fuente := SystemFont.new()
	fuente.font_names = PackedStringArray(["Georgia", "Constantia", "Arial"])
	cuerpo.call("montar", c, fuente)
	_escenas = _guion_criatura()

func _guion_criatura() -> Array:
	var S := Criatura.Estado
	var lista: Array = [
		{"nombre": "retrato_frente", "estado": S.CORRER, "dur": 1.4, "tomas": [1.1],
			"cam": "frente", "quieta": true},
		{"nombre": "retrato_tres_cuartos", "estado": S.CORRER, "dur": 0.8, "tomas": [0.6],
			"cam": "tres_cuartos", "quieta": true},
		{"nombre": "retrato_espalda", "estado": S.CORRER, "dur": 0.8, "tomas": [0.6],
			"cam": "espalda", "quieta": true},
		{"nombre": "retrato_picado", "estado": S.CORRER, "dur": 0.8, "tomas": [0.6],
			"cam": "picado", "quieta": true},
		{"nombre": "como_en_juego", "estado": S.CORRER, "dur": 1.0, "tomas": [0.8], "cam": "juego"},
		{"nombre": "aparecer", "estado": S.APARECER, "dur": 0.7, "tomas": [0.2, 0.5],
			"cam": "tres_cuartos", "quieta": true},
		{"nombre": "correr", "estado": S.CORRER, "dur": 1.6, "tomas": [0.55, 1.2],
			"cam": "tres_cuartos"},
		{"nombre": "alerta", "estado": S.ALERTA, "dur": 0.6, "tomas": [0.35],
			"cam": "tres_cuartos", "quieta": true},
		{"nombre": "huir", "estado": S.HUIR, "dur": 1.4, "tomas": [0.5, 1.0], "cam": "tres_cuartos"},
		{"nombre": "golpe", "estado": S.VOLAR, "dur": 0.9, "tomas": [0.05, 0.35],
			"cam": "tres_cuartos", "golpe": true},
		{"nombre": "aturdida", "estado": S.ATURDIDA, "dur": 1.1, "tomas": [0.7],
			"cam": "tres_cuartos", "quieta": true},
	]
	if _especie == "corredor":
		lista.append({"nombre": "miedo_medio", "estado": S.HUIR, "dur": 1.0, "tomas": [0.7],
			"cam": "tres_cuartos", "miedo": 0.6})
		lista.append({"nombre": "acorralada", "estado": S.ACORRALADA, "dur": 1.2, "tomas": [0.8],
			"cam": "tres_cuartos", "quieta": true, "miedo": 1.0})
	if _especie == "escarabajo":
		lista.append({"nombre": "blindada", "estado": S.CORRER, "dur": 0.7, "tomas": [0.08, 0.3],
			"cam": "frente", "quieta": true, "blindar": true})
		lista.append({"nombre": "volcada", "estado": S.VOLCADA, "dur": 1.4, "tomas": [0.5, 1.1],
			"cam": "tres_cuartos", "quieta": true})
	lista.append({"nombre": "en_bola", "estado": S.EN_BOLA, "dur": 0.5, "tomas": [0.10, 0.22],
		"cam": "tres_cuartos", "quieta": true})
	return lista

func _tangente() -> Vector2:
	return Vector2(-sin(_ang), cos(_ang))

func _bola2() -> Vector2:
	return CENTRO + Vector2(cos(_t * 0.7), sin(_t * 0.7)) * 120.0 + Vector2(0.0, 40.0)

func _bola3() -> Vector3:
	var b := _bola2()
	return Vector3(b.x * E, 0.09, b.y * E)

func _entrar(esc: Dictionary) -> void:
	_cam_salto = true
	if _glb != "":
		return
	c.miedo = float(esc.get("miedo", 0.0))
	c.vel = Vector2.ZERO
	c.bote_u = -1.0
	_hop = 0.0
	_en_aire = false
	if esc.get("quieta", false):
		c.pos = CENTRO
		c.rumbo = Vector2.DOWN
	c.cambiar(int(esc["estado"]))
	if esc.get("golpe", false):
		c.vel = Vector2(430.0, -120.0)
		c.golpes += 1
		cuerpo.call("golpear", Vector2(1.0, -0.28).normalized())
	if esc.get("blindar", false) and cuerpo.has_method("blindar"):
		cuerpo.call("blindar")

## Lo que le haría la caza: moverla según el estado.
func _mover(delta: float, esc: Dictionary) -> void:
	c.t_estado += delta
	c.mira = _bola2()
	if esc.get("quieta", false):
		return
	var estado: int = esc["estado"]
	if estado == Criatura.Estado.VOLAR:
		c.pos += c.vel * delta
		c.vel *= exp(-4.5 * delta)
		return
	var huyendo := estado == Criatura.Estado.HUIR
	var radio := 70.0
	if c.salta:
		var posada := c.posada_huida if huyendo else c.posada_paseo
		_hop += delta
		if _en_aire:
			var v := c.bote_largo / c.bote_tiempo
			_ang += v / radio * delta
			c.vel = _tangente() * v
			c.bote_u = clampf(_hop / c.bote_tiempo, 0.0, 1.0)
			if _hop >= c.bote_tiempo:
				_en_aire = false
				_hop = 0.0
				c.bote_u = -1.0
				c.vel = Vector2.ZERO
		else:
			c.bote_u = -1.0
			c.vel = Vector2.ZERO
			if _hop >= posada:
				_en_aire = true
				_hop = 0.0
				c.bote_u = 0.0
	else:
		var v := c.v_huir if huyendo else c.v_correr
		_ang += v / radio * delta
		c.vel = _tangente() * v
	c.pos = CENTRO + Vector2(cos(_ang), sin(_ang)) * radio
	c.rumbo = _tangente()

# ---------------------------------------------------------------------- un GLB

func _montar_glb() -> void:
	_bola_mi.position = Vector3(CENTRO.x * E + 0.0, 0.09, CENTRO.y * E + 0.0)
	var recurso: Resource = load(_glb)
	if recurso == null or not (recurso is PackedScene):
		print("VISOR: no puedo cargar el modelo: ", _glb)
		return
	var nodo := (recurso as PackedScene).instantiate() as Node3D
	if nodo == null:
		print("VISOR: el modelo no es un Node3D: ", _glb)
		return
	vp.add_child(nodo)
	nodo.position = Vector3(CENTRO.x * E, 0.0, CENTRO.y * E)
	var caja := _caja(nodo)
	# Se posa en el suelo y se aparta la bola testigo a un lado, fuera del modelo.
	nodo.position.y -= caja.position.y
	caja.position.y = 0.0
	_glb_centro = caja.position + caja.size * 0.5
	_glb_radio = maxf(caja.size.length() * 0.5, 0.05)
	_bola_mi.position = Vector3(caja.position.x + caja.size.x + 0.14, 0.09, _glb_centro.z)
	print("VISOR: modelo %s, caja %s (alto %.3f)" % [_glb, str(caja.size), caja.size.y])
	for k in 8:
		_escenas.append({"nombre": "giro_%03d" % (k * 45), "dur": 0.4, "tomas": [0.3],
			"ang": float(k) * 45.0, "elev": 28.0})
	_escenas.append({"nombre": "picado", "dur": 0.4, "tomas": [0.3], "ang": 20.0, "elev": 75.0})
	_escenas.append({"nombre": "rasante", "dur": 0.4, "tomas": [0.3], "ang": 20.0, "elev": 6.0})

func _caja(raiz: Node) -> AABB:
	var caja := AABB()
	var primera := true
	var pila: Array = [raiz]
	while not pila.is_empty():
		var n: Node = pila.pop_back()
		for h in n.get_children():
			pila.append(h)
		var vi := n as VisualInstance3D
		if vi == null:
			continue
		var c2: AABB = vi.global_transform * vi.get_aabb()
		if primera:
			caja = c2
			primera = false
		else:
			caja = caja.merge(c2)
	return caja

# ------------------------------------------------------------------ cada cuadro

func _process(delta: float) -> void:
	_t += delta
	if _fin or _escenas.is_empty():
		return
	if _i < 0 or _t_escena >= float(_escenas[_i]["dur"]):
		_i += 1
		if _i >= _escenas.size():
			_fin = true
			print("VISOR: fin del guion a los %.1f s, %d capturas en %s" % [_t, _n, _dir])
			return
		_t_escena = 0.0
		_entrar(_escenas[_i])
	var esc: Dictionary = _escenas[_i]
	_t_escena += delta
	if _glb != "":
		var ang := deg_to_rad(float(esc["ang"]))
		var elev := deg_to_rad(float(esc["elev"]))
		var d := _glb_radio * 3.4
		camara.fov = 30.0
		camara.position = _glb_centro + Vector3(sin(ang) * cos(elev), sin(elev), cos(ang) * cos(elev)) * d
		camara.look_at(_glb_centro, Vector3.UP)
	else:
		_mover(delta, esc)
		_bola_mi.position = _bola3()
		cuerpo.call("actualizar", delta, _bola3())
		_encuadrar(delta, esc)
	var tomas: Array = esc["tomas"]
	for k in tomas.size():
		var clave := "%d_%d" % [_i, k]
		if not _hechas.has(clave) and _t_escena >= float(tomas[k]):
			_hechas[clave] = true
			var sufijo := "" if tomas.size() == 1 else "_%d" % k
			_capturar("%02d_%s%s.png" % [_i, str(esc["nombre"]), sufijo])

func _encuadrar(_delta: float, esc: Dictionary) -> void:
	var cam: Dictionary = CAMARAS.get(str(esc.get("cam", "tres_cuartos")), CAMARAS["tres_cuartos"])
	# LA CÁMARA VA PEGADA AL CENTRO DEL CUERPO, SIN RETRASO. Iba detrás con un
	# muelle de 8/s y, huyendo a 185 px/s o despedida por un golpe, la criatura se
	# le escapaba del cuadro: huir_0 y golpe_1 salían cortadas en las tres. Aquí
	# no se juzga la cámara sino el cuerpo, así que no hay nada que suavizar.
	var objetivo := Vector3(c.pos.x * E, 0.0, c.pos.y * E)
	if cuerpo != null and cuerpo.has_method("centro"):
		var centro: Vector3 = cuerpo.call("centro")
		objetivo = Vector3(centro.x, 0.0, centro.z)
	_cam_centro = objetivo
	_cam_salto = false
	# La distancia sale del tamaño del bicho: el encuadre que vale para uno de 12
	# le corta las manos a uno de 17.
	var k := 1.0 if str(esc.get("cam", "")) == "juego" else maxf(c.radio / 10.5, 1.0)
	camara.fov = float(cam["fov"])
	camara.position = _cam_centro + (cam["pos"] as Vector3) * k
	camara.look_at(_cam_centro + (cam["mira"] as Vector3) * k, Vector3.UP)

func _capturar(nombre: String) -> void:
	if _dir == "":
		return
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	var ruta := _dir.path_join(nombre)
	img.save_png(ruta)
	_n += 1
	print("captura: ", ruta)
