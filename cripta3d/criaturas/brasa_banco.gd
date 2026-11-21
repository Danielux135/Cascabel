extends Node

## CRIPTA 3D — el BANCO de BRASA. Una tira de fotogramas de lo que el visor no
## puede enseñar: el visor saca UNA criatura en UN estado, y lo de BRASA es justo
## lo que pasa ENTRE estados y entre tres cuerpos —la entera que se parte en dos
## ascuas, las ascuas que se buscan y vuelven a ser una, la que se cuela en la
## bola que la toca—. Aquí se monta eso con tres `Criatura` de mentira, movidas
## como las movería la caza, y se guarda un fotograma cada `--cada` cuadros (por
## defecto 6: una décima de segundo).
##
##   python cripta3d/herramientas/godot3d.py escena res://cripta3d/criaturas/brasa_banco.tscn \
##       --fotogramas 620 -- --capturas=C:/ruta/temporal [--cada=6] [--tam=640x480]
##   python cripta3d/herramientas/hoja.py C:/ruta/temporal/_tira.png C:/ruta/temporal --cols 10 --alto 200
##
## El guion, que dura unos 10 s: la entera NACE, BOTA, ve venir la bola (ALERTA) y
## el golpe la PARTE; las dos ascuas salen rodando, se quedan ATURDIDAS, se
## BUSCAN y vuelven a ser una; la parten otra vez y una bola lenta RECOGE a una.
## El nombre de cada fotograma dice en qué paso está.
##
## No es una prueba ni mide nada, y el juego no lo carga: es para MIRAR el
## movimiento, que es lo que se juzga de «partida en dos ascuas» y «recogida». Se
## cierra con `--fotogramas`, como el visor, y las capturas van fuera del repo.

const Criatura := preload("res://prueba3d/criatura.gd")
const Cuerpo := preload("res://cripta3d/criaturas/brasa.gd")
const E := 0.01
const CENTRO := Vector2(200.0, 1000.0)

var _dir := ""
var _cada := 6
var _ancho := 640
var _alto := 480

var vp: SubViewport
var camara: Camera3D
var _bola_mi: MeshInstance3D
var entera: Criatura
var mitades: Array[Criatura] = []
var cuerpos: Array[Node3D] = []
var _tic := 0
var _t := 0.0
var _n := 0
var _fase := "nacer"
var _t_fase := 0.0
var _bola := Vector2(60.0, 1000.0)
var _bola_vel := Vector2.ZERO
var _aire: Dictionary = {}
var _reloj_bote: Dictionary = {}
var _avisado := false
var _mira := Vector3.ZERO

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capturas="):
			_dir = arg.trim_prefix("--capturas=")
		elif arg.begins_with("--cada="):
			_cada = maxi(int(arg.trim_prefix("--cada=")), 1)
		elif arg.begins_with("--tam="):
			var t := arg.trim_prefix("--tam=").split("x")
			if t.size() == 2:
				_ancho = maxi(int(t[0]), 64)
				_alto = maxi(int(t[1]), 64)
	if _dir != "":
		DirAccess.make_dir_recursive_absolute(_dir)
	_montar_plato()
	entera = _crear("saltarin", 13.0, 40.0, 0.30)
	mitades.append(_crear("gotita", 9.0, 34.0, 0.24))
	mitades.append(_crear("gotita", 9.0, 34.0, 0.24))
	entera.pos = CENTRO + Vector2(-55.0, 10.0)
	entera.rumbo = Vector2.RIGHT
	entera.cambiar(Criatura.Estado.APARECER)
	print("BANCO: la entera nace, bota, la parten, las ascuas se juntan y una bola recoge a la que queda")

## La misma luz que el visor: fuego bajo por delante, luna fría por detrás.
func _montar_plato() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(_ancho, _alto)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.032, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.36, 0.42, 0.62)
	env.ambient_light_energy = 0.22
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.8
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
	vp.add_child(luna)
	var fuego := OmniLight3D.new()
	fuego.light_color = Color(1.0, 0.62, 0.30)
	fuego.light_energy = 2.2
	fuego.omni_range = 3.5
	fuego.shadow_enabled = true
	fuego.position = centro + Vector3(-0.7, 0.55, 0.6)
	vp.add_child(fuego)
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
	# Como se ve jugando, pero más cerca: desde el lado del jugador y desde arriba.
	camara = Camera3D.new()
	camara.fov = 36.0
	vp.add_child(camara)
	_mira = centro
	_encuadrar(1.0)
	camara.current = true
	var capa := CanvasLayer.new()
	add_child(capa)
	var pantalla := TextureRect.new()
	pantalla.texture = vp.get_texture()
	pantalla.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pantalla.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pantalla.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(pantalla)

## La cámara sigue, sin prisa, al centro de lo que haya a la vista.
func _encuadrar(peso: float) -> void:
	var suma := Vector3.ZERO
	var cuantas := 0
	for c: Criatura in [entera, mitades[0] if mitades.size() > 0 else null,
			mitades[1] if mitades.size() > 1 else null]:
		if c != null and c.estado != Criatura.Estado.FUERA:
			suma += Vector3(c.pos.x * E, 0.0, c.pos.y * E)
			cuantas += 1
	if cuantas > 0:
		_mira = _mira.lerp(suma / float(cuantas), peso)
	camara.position = _mira + Vector3(0.0, 1.30, 1.60)
	camara.look_at(_mira + Vector3(0.0, 0.08, 0.0), Vector3.UP)

func _crear(especie: String, radio: float, largo: float, tiempo: float) -> Criatura:
	var c := Criatura.new()
	c.indice = cuerpos.size()
	c.especie = especie
	c.radio = radio
	c.salta = true
	c.bote_largo = largo
	c.bote_tiempo = tiempo
	c.pos = CENTRO
	var cuerpo := Cuerpo.new() as Node3D
	vp.add_child(cuerpo)
	cuerpo.call("montar", c, null)
	cuerpos.append(cuerpo)
	_aire[c] = false
	_reloj_bote[c] = 0.0
	return c

## Un bote, como los da `caza_orbita.gd`: posada un rato y luego `bote_largo` en
## `bote_tiempo`, con `bote_u` de 0 a 1 en el aire.
func _botar(c: Criatura, hacia: Vector2, posada: float, delta: float) -> void:
	var dir := hacia.normalized() if hacia.length_squared() > 1e-6 else c.rumbo
	_reloj_bote[c] = float(_reloj_bote[c]) + delta
	if bool(_aire[c]):
		var v := c.bote_largo / c.bote_tiempo
		c.pos += dir * v * delta
		c.vel = dir * v
		c.rumbo = dir
		c.bote_u = clampf(float(_reloj_bote[c]) / c.bote_tiempo, 0.0, 1.0)
		if float(_reloj_bote[c]) >= c.bote_tiempo:
			_aire[c] = false
			_reloj_bote[c] = 0.0
			c.bote_u = -1.0
			c.vel = Vector2.ZERO
	else:
		c.bote_u = -1.0
		c.vel = Vector2.ZERO
		if float(_reloj_bote[c]) >= posada:
			_aire[c] = true
			_reloj_bote[c] = 0.0
			c.bote_u = 0.0

func _pasar(fase: String) -> void:
	_fase = fase
	_t_fase = 0.0

func _process(delta: float) -> void:
	_t += delta
	_t_fase += delta
	var S := Criatura.Estado
	for c: Criatura in [entera, mitades[0], mitades[1]]:
		c.t_estado += delta
		c.t_recarga = maxf(c.t_recarga - delta, 0.0)
		c.mira = _bola
	_bola += _bola_vel * delta
	_bola_vel *= exp(-0.6 * delta)

	match _fase:
		"nacer":
			if _t_fase >= 0.6:
				entera.cambiar(S.CORRER)
				_pasar("botes")
		"botes":
			_botar(entera, Vector2.RIGHT, 0.30, delta)
			if _t_fase >= 1.5:
				# La bola viene por la izquierda: la criatura se agacha…
				_bola = entera.pos + Vector2(-150.0, 6.0)
				_bola_vel = Vector2(820.0, 0.0)
				entera.bote_u = -1.0
				entera.vel = Vector2.ZERO
				_aire[entera] = false
				entera.cambiar(S.ALERTA)
				_pasar("alerta")
		"alerta":
			if _bola.distance_to(entera.pos) <= entera.radio + 9.0:
				# …y el golpe la parte en dos, como `_partir` en la caza.
				var n := (_bola - entera.pos).normalized()
				cuerpos[0].call("golpear", n)
				var lado := Vector2(-n.y, n.x)
				var signo := 1.0
				for m in mitades:
					m.pos = entera.pos + lado * signo * 7.0
					m.vel = -n * 130.0 + lado * signo * 240.0
					m.rumbo = m.vel.normalized()
					m.t_recarga = 0.6
					m.bote_u = -1.0
					m.cambiar(S.VOLAR)
					signo = -signo
				entera.cambiar(S.FUERA)
				_bola_vel = n * 260.0 + Vector2(0.0, -120.0)
				_pasar("partida")
		"partida":
			var quietas := 0
			for m in mitades:
				if m.estado == S.VOLAR:
					m.pos += m.vel * delta
					m.vel *= exp(-4.5 * delta)
					if m.t_estado >= 0.9 or m.vel.length() < 30.0:
						m.vel = Vector2.ZERO
						m.cambiar(S.ATURDIDA)
				elif m.estado == S.ATURDIDA and m.t_estado >= 0.4:
					m.cambiar(S.CORRER)
				elif m.estado == S.CORRER:
					quietas += 1
			if quietas == 2:
				_pasar("buscarse")
		"buscarse":
			var a := mitades[0]
			var b := mitades[1]
			# La segunda se queda atrás a propósito: es la que recogerá la bola.
			_botar(a, b.pos - a.pos, 0.22, delta)
			if _t_fase < 0.8:
				_botar(b, a.pos - b.pos, 0.22, delta)
			# Como en la caza: basta con que se acerquen, vayan como vayan.
			if a.pos.distance_to(b.pos) <= 20.0:
				var donde := (a.pos + b.pos) * 0.5
				a.cambiar(S.FUERA)
				b.cambiar(S.FUERA)
				entera.pos = donde
				entera.rumbo = Vector2.DOWN
				entera.bote_u = -1.0
				entera.cambiar(S.APARECER)
				_pasar("reunida")
		"reunida":
			if entera.estado == S.APARECER and entera.t_estado >= 0.6:
				entera.cambiar(S.CORRER)
			if entera.estado == S.CORRER:
				_botar(entera, Vector2(-0.6, 0.8), 0.30, delta)
			if _t_fase >= 1.5:
				# Otra vez partida, de un golpe seco hacia el fondo, y esta vez una
				# bola lenta pasa a recoger una de las ascuas.
				var n := Vector2(0.0, 1.0)
				var lado := Vector2(1.0, 0.0)
				var signo := 1.0
				for m in mitades:
					m.pos = entera.pos + lado * signo * 7.0
					m.vel = -n * 60.0 + lado * signo * 200.0
					m.rumbo = m.vel.normalized()
					m.t_recarga = 0.6
					m.bote_u = -1.0
					_aire[m] = false
					_reloj_bote[m] = 0.0
					m.cambiar(S.VOLAR)
					signo = -signo
				cuerpos[0].call("golpear", n)
				entera.cambiar(S.FUERA)
				_pasar("recoger")
		"recoger":
			for m in mitades:
				if m.estado == S.VOLAR:
					m.pos += m.vel * delta
					m.vel *= exp(-4.5 * delta)
					if m.t_estado >= 0.9 or m.vel.length() < 30.0:
						m.vel = Vector2.ZERO
						m.cambiar(S.ATURDIDA)
				elif m.estado == S.ATURDIDA and m.t_estado >= 0.4:
					m.cambiar(S.CORRER)
			# La que no es la presa sigue a lo suyo, botando.
			if mitades[1].estado == S.CORRER:
				_botar(mitades[1], Vector2(0.3, 1.0), 0.22, delta)
			var presa := mitades[0]
			if _t_fase >= 1.1 and not _avisado:
				_avisado = true
				_bola = presa.pos + Vector2(170.0, 30.0)
				_bola_vel = (presa.pos - _bola).normalized() * 260.0
			if _avisado and presa.estado != S.EN_BOLA and presa.estado != S.FUERA \
					and _bola.distance_to(presa.pos) <= presa.radio + 9.0:
				presa.cambiar(S.EN_BOLA)
			if presa.estado == S.EN_BOLA:
				presa.pos = _bola

	_encuadrar(1.0 - exp(-2.5 * delta))
	var bola3 := Vector3(_bola.x * E, 0.09, _bola.y * E)
	_bola_mi.position = bola3
	var todas: Array[Criatura] = [entera, mitades[0], mitades[1]]
	for i in cuerpos.size():
		var donde := bola3 if todas[i].estado == S.EN_BOLA else Vector3.ZERO
		cuerpos[i].call("actualizar", delta, donde)
	_tic += 1
	if _dir != "" and _tic % _cada == 0:
		_capturar("%03d_%s.png" % [_n, _fase])
		_n += 1

func _capturar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.save_png(_dir.path_join(nombre))
