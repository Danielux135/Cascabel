extends Node3D

## PRUEBA 3D — el cuerpo de una criatura. Solo LEE una `criatura.gd` y la pone
## en pantalla; no decide nada.
##
## Como todo en esta prueba, está hecho de primitivas y de código: ni un modelo,
## ni un hueso, ni una animación grabada. Lo que la hace parecer viva son cuatro
## cosas, y las cuatro se calculan en cada cuadro:
##
##   1. LOS PIES PISAN. Cada pata es dos tramos con rodilla resueltos por
##      cinemática inversa: el pie se queda clavado en el cristal mientras el
##      cuerpo avanza y da el paso cuando le toca. No hay ciclo de carrera
##      dibujado, así que no patina a ninguna velocidad ni al girar.
##   2. LOS OJOS MIRAN. Las pupilas siguen a la bola, también hacia atrás.
##   3. EL CUERPO PESA: se inclina al correr, bota, rueda de verdad cuando lo
##      mandan por los aires y se aplasta contra el golpe.
##   4. LO QUE LE PASA SE VE DESDE LEJOS: se agacha antes de huir, palidece y
##      tirita, y lleva debajo un aro que dice cuánto le falta.
##
## Los ojos van ARRIBA a propósito: la cámara mira la mesa desde lo alto, y unos
## ojos en la cara solo se verían cuando el bicho corre hacia el jugador.

const Criatura := preload("res://prueba3d/criatura.gd")
const PIEL := preload("res://prueba3d/bicho.gdshader")
const ARO := preload("res://prueba3d/miedo.gdshader")
const E := 0.01

var c: Criatura
## A qué altura está el suelo que pisa (el tablero o la cubierta).
var y_base := 0.0
## Cuánto dura la ventana para recogerla, para que el aro la cuente.
var t_cierre := 5.0
var t_volcada := 5.0
var arco_blindaje := 70.0

var _raiz: Node3D          # se mueve, gira, se inclina y rueda
var _forma: Node3D         # dentro: se aplasta y se estira
var _miembros: Node3D      # patas, brazos y antenas: van en coordenadas de mesa
var _mats: Array[ShaderMaterial] = []
var _mat_ojo: StandardMaterial3D
var _mat_pupila: StandardMaterial3D
var _mat_luz: StandardMaterial3D
var _mat_aro: ShaderMaterial
var _aro: MeshInstance3D
var _charco: MeshInstance3D
var _rastro: MeshInstance3D
var _ojos: Array[Dictionary] = []
var _patas: Array[Dictionary] = []
var _brazos: Array[Dictionary] = []
var _antenas: Array[Dictionary] = []
var _estrellas: Node3D
var _aviso: Label3D

var _color := Color.WHITE
var _color_borde := Color.WHITE
var _alto := 0.14
var _zancada := 0.22
var _alzada := 0.05
var _talla := 1.0
var _rodilla_delante := false

var _fase := 0.0
var _yaw := 0.0
var _vuelco := Quaternion.IDENTITY
var _escala := Vector3.ONE
var _tiempo := 0.0
var _parpadeo := 0.0
var _prox_parpadeo := 2.0
var _estado_antes := -1
var _destello := 0.0
var _choque := 0.0
var _aviso_t := 0.0
var _aro_aviso := 0.0
var _pies_puestos := false
var _golpe_t := 9.0
var _golpe_n := Vector3.FORWARD
var _parada := 0.0
var _desde_recogida := Vector3.ZERO

# ------------------------------------------------------------------- montaje

func montar(criatura: Criatura, fuente: Font) -> void:
	c = criatura
	_raiz = Node3D.new()
	add_child(_raiz)
	_forma = Node3D.new()
	_raiz.add_child(_forma)
	_miembros = Node3D.new()
	add_child(_miembros)

	_mat_ojo = StandardMaterial3D.new()
	_mat_ojo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_ojo.albedo_color = Color(1.7, 1.75, 1.8)
	_mat_pupila = StandardMaterial3D.new()
	_mat_pupila.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_pupila.albedo_color = Color(0.01, 0.01, 0.03)
	_mat_luz = StandardMaterial3D.new()
	_mat_luz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	match c.especie:
		"corredor":
			_montar_corredor()
		"escarabajo":
			_montar_escarabajo()
		"gotita":
			_talla = 0.70
			_montar_saltarin()
		_:
			_montar_saltarin()

	_mat_luz.albedo_color = Color(_color_borde.r * 2.2, _color_borde.g * 2.2,
		_color_borde.b * 2.2)
	_montar_suelo()
	_montar_estrellas()
	_montar_aviso(fuente)
	_prox_parpadeo = 1.0 + float(c.indice) * 0.7
	_fuera_del_reflejo(self)
	_ocultar()

## En el reflejo, de lejos, solo se dibuja el cuerpo. Patas, ojos y antenas son
## cien llamadas de dibujo entre las cinco criaturas, y en un reflejo
## emborronado y pequeño no se distinguen: van en la `CAPA_DETALLE` de
## `mundo_orbita.gd` (8), que la cámara del reflejo solo mira en las cámaras de
## cerca. Lo menudo es justo lo que no hace sombra, así que la regla es esa. Y
## lo que va pintado en el cristal —aro, charco, rastro— y el aviso van en la
## `CAPA_SIN_REFLEJO` (4): su reflejo no se vería nunca.
func _fuera_del_reflejo(raiz: Node) -> void:
	for n in raiz.get_children():
		_fuera_del_reflejo(n)
		var gi := n as GeometryInstance3D
		if gi == null:
			continue
		if gi is Label3D or gi == _aro or gi == _charco or gi == _rastro:
			gi.layers = 4
		elif gi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			gi.layers = 8

func _piel(col: Color, borde: Color, brillo: float = 0.30, fuerza: float = 1.3,
		rugosidad: float = 0.30, metal: float = 0.0, rayas: float = 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = PIEL
	m.set_shader_parameter("color", col)
	m.set_shader_parameter("color_borde", borde)
	m.set_shader_parameter("brillo", brillo)
	m.set_shader_parameter("borde", fuerza)
	m.set_shader_parameter("rugosidad", rugosidad)
	m.set_shader_parameter("metal", metal)
	m.set_shader_parameter("rayas", rayas)
	_mats.append(m)
	return m

func _bola(padre: Node3D, radio: float, donde: Vector3, mat: Material,
		escala: Vector3 = Vector3.ONE, seg: int = 16, sombra: bool = true) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radio
	m.height = radio * 2.0
	m.radial_segments = seg
	m.rings = maxi(seg / 2, 4)
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position = donde
	mi.scale = escala
	if not sombra:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(mi)
	return mi

## Un tramo de pata, brazo o antena: un cilindro de alto 1 y radio 1 que cada
## cuadro se estira entre dos puntos.
func _tramo(mat: Material) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = 1.0
	m.bottom_radius = 1.0
	m.height = 1.0
	m.radial_segments = 6
	m.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_miembros.add_child(mi)
	return mi

static func _tender(mi: MeshInstance3D, a: Vector3, b: Vector3, grosor: float) -> void:
	var d := b - a
	var largo := d.length()
	if largo < 1e-5:
		mi.visible = false
		return
	mi.visible = true
	var y := d / largo
	var ref := Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	var z := x.cross(y)
	mi.transform = Transform3D(Basis(x * grosor, y * largo, z * grosor), (a + b) * 0.5)

func _ojo(padre: Node3D, donde: Vector3, radio: float) -> void:
	var blanco := _bola(padre, radio, donde, _mat_ojo, Vector3.ONE, 12, false)
	var pupila := _bola(padre, radio * 0.55, donde, _mat_pupila, Vector3.ONE, 8, false)
	_ojos.append({"blanco": blanco, "pupila": pupila, "centro": donde, "radio": radio})

func _pata(cadera: Vector3, reposo: Vector2, fase0: float, l1: float, l2: float,
		grosor: float, r_pie: float, mat: Material, mat_pie: Material) -> void:
	var muslo := _tramo(mat)
	var tibia := _tramo(mat)
	var rodilla := _bola(_miembros, grosor * 1.3, Vector3.ZERO, mat, Vector3.ONE, 6, false)
	var zapato := _bola(_miembros, r_pie, Vector3.ZERO, mat_pie, Vector3.ONE, 8, false)
	_patas.append({"cadera": cadera, "reposo": reposo, "fase0": fase0, "l1": l1,
		"l2": l2, "grosor": grosor, "muslo": muslo, "tibia": tibia,
		"rodilla": rodilla, "zapato": zapato, "r_pie": r_pie,
		"pie": Vector3.ZERO, "desde": Vector3.ZERO, "en_aire": false})

func _brazo(hombro: Vector3, largo: float, grosor: float, mat: Material,
		mat_mano: Material, lado: float) -> void:
	var tramo := _tramo(mat)
	var mano := _bola(_miembros, grosor * 1.7, Vector3.ZERO, mat_mano, Vector3.ONE, 6, false)
	_brazos.append({"hombro": hombro, "largo": largo, "grosor": grosor,
		"tramo": tramo, "mano": mano, "lado": lado})

func _antena(base: Vector3, punta: Vector3, grosor: float, mat: Material) -> void:
	var tramo := _tramo(mat)
	var luz := _bola(_miembros, grosor * 2.4, Vector3.ZERO, _mat_luz, Vector3.ONE, 6, false)
	_antenas.append({"base": base, "punta": punta, "grosor": grosor,
		"tramo": tramo, "luz": luz, "fase": float(_antenas.size()) * 1.9})

# ------------------------------------------------------------------ las especies

## LUMI, la que corre. Dos patas, cabeza grande con visera y una antena. Es la
## rápida y la que más se asusta: se le suben las manos a la cabeza.
func _montar_corredor() -> void:
	_color = Color(0.45, 1.0, 0.28)
	_color_borde = Color(0.85, 1.0, 0.50)
	_alto = 0.150
	_zancada = 0.26
	_alzada = 0.06
	_rodilla_delante = true
	var piel := _piel(_color, _color_borde, 0.32, 1.3, 0.35)
	var clara := _piel(_color.lerp(Color.WHITE, 0.45), _color_borde, 0.30, 1.2, 0.25)
	var visera := _piel(Color(0.015, 0.05, 0.035), _color_borde, 0.0, 0.9, 0.08, 0.6)
	_bola(_forma, 0.060, Vector3(0.0, 0.0, 0.0), piel, Vector3(1.0, 1.15, 0.9), 14)
	_bola(_forma, 0.040, Vector3(0.0, 0.01, -0.058), visera, Vector3.ONE, 10)
	_bola(_forma, 0.088, Vector3(0.0, 0.125, 0.010), clara, Vector3.ONE, 26)
	_bola(_forma, 0.079, Vector3(0.0, 0.127, 0.030), visera, Vector3.ONE, 26)
	_ojo(_forma, Vector3(-0.034, 0.158, 0.088), 0.025)
	_ojo(_forma, Vector3(0.034, 0.158, 0.088), 0.025)
	_antena(Vector3(0.0, 0.205, 0.0), Vector3(0.0, 0.30, -0.02), 0.006, piel)
	for lado: float in [-1.0, 1.0]:
		_pata(Vector3(0.034 * lado, -0.045, 0.0), Vector2(0.046 * lado, 0.0),
			0.0 if lado < 0.0 else 0.5, 0.064, 0.064, 0.013, 0.026, piel, _mat_luz)
		_brazo(Vector3(0.068 * lado, 0.030, 0.0), 0.085, 0.011, piel, clara, lado)

## TANQUE, el escarabajo. Seis patas que pisan en dos tríos, caparazón de rayas
## y antenas. Pesa: la bola rebota en él en vez de llevárselo por delante.
func _montar_escarabajo() -> void:
	_color = Color(0.95, 0.15, 0.12)
	_color_borde = Color(1.0, 0.55, 0.32)
	_alto = 0.125
	_zancada = 0.22
	_alzada = 0.05
	var concha := _piel(_color, _color_borde, 0.22, 1.2, 0.16, 0.5, 13.0)
	var oscura := _piel(Color(0.07, 0.025, 0.03), _color_borde, 0.0, 0.9, 0.2, 0.4)
	_bola(_forma, 0.128, Vector3(0.0, 0.014, -0.024), concha, Vector3(1.0, 0.62, 1.22), 22)
	_bola(_forma, 0.110, Vector3(0.0, -0.014, -0.012), oscura, Vector3(1.0, 0.5, 1.2), 14)
	_bola(_forma, 0.070, Vector3(0.0, -0.004, 0.150), oscura, Vector3.ONE, 14)
	_ojo(_forma, Vector3(-0.044, 0.050, 0.178), 0.030)
	_ojo(_forma, Vector3(0.044, 0.050, 0.178), 0.030)
	_antena(Vector3(-0.024, 0.036, 0.200), Vector3(-0.090, 0.125, 0.320), 0.006, oscura)
	_antena(Vector3(0.024, 0.036, 0.200), Vector3(0.090, 0.125, 0.320), 0.006, oscura)
	var filas := [0.104, 0.0, -0.104]
	for i in filas.size():
		var z: float = filas[i]
		for lado: float in [-1.0, 1.0]:
			# Dos tríos alternos: delantera y trasera de un lado con la del medio
			# del otro. Es como andan los insectos, y lo que hace que no cojee.
			var trio_a := (i % 2 == 0) == (lado < 0.0)
			var ancho := 0.245 if i == 1 else 0.220
			_pata(Vector3(0.088 * lado, -0.024, z), Vector2(ancho * lado, z * 1.5),
				0.0 if trio_a else 0.5, 0.135, 0.165, 0.0115, 0.018, oscura, _mat_luz)

## GOTA, la que salta —y sus mitades, que son ella en pequeño—. Sin patas: una
## gota de gelatina que avanza a botes, se aplasta al caer y se estira al subir.
func _montar_saltarin() -> void:
	_color = Color(1.0, 0.84, 0.16)
	_color_borde = Color(1.0, 1.0, 0.60)
	_alto = 0.100 * _talla
	_alzada = 0.15 * _talla
	var gel := _piel(_color, _color_borde, 0.42, 1.6, 0.10)
	_bola(_forma, 0.118, Vector3.ZERO, gel, Vector3(1.0, 0.86, 1.0), 22)
	_bola(_forma, 0.040, Vector3(0.0, 0.098, -0.020), gel, Vector3.ONE, 10)
	_bola(_forma, 0.022, Vector3(0.0, 0.140, -0.034), gel, Vector3.ONE, 8)
	_ojo(_forma, Vector3(-0.046, 0.066, 0.086), 0.031)
	_ojo(_forma, Vector3(0.046, 0.066, 0.086), 0.031)

## Lo que va pintado en el cristal debajo de ella: el aro, un charco de luz de
## su color —en vez de una luz de verdad, que la mesa ya tiene todas las que
## caben— y el rastro que deja cuando va por dentro del túnel.
func _montar_suelo() -> void:
	var plano := PlaneMesh.new()
	var lado := c.radio * E * 4.4
	plano.size = Vector2(lado, lado)
	_mat_aro = ShaderMaterial.new()
	_mat_aro.shader = ARO
	_mat_aro.set_shader_parameter("color_calma", _color)
	_mat_aro.set_shader_parameter("arco", deg_to_rad(arco_blindaje))
	_aro = MeshInstance3D.new()
	_aro.mesh = plano
	_aro.material_override = _mat_aro
	_aro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_aro)

	var degradado := Gradient.new()
	degradado.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	degradado.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var redonda := GradientTexture2D.new()
	redonda.gradient = degradado
	redonda.fill = GradientTexture2D.FILL_RADIAL
	redonda.fill_from = Vector2(0.5, 0.5)
	redonda.fill_to = Vector2(1.0, 0.5)
	redonda.width = 48
	redonda.height = 48
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_texture = redonda
	mat.albedo_color = Color(_color.r, _color.g, _color.b, 0.42)
	var charco := PlaneMesh.new()
	charco.size = Vector2(lado * 1.25, lado * 1.25)
	_charco = MeshInstance3D.new()
	_charco.mesh = charco
	_charco.material_override = mat
	_charco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_charco)

	var mat_rastro := mat.duplicate() as StandardMaterial3D
	mat_rastro.albedo_color = Color(_color.r, _color.g, _color.b, 0.55)
	var rastro := PlaneMesh.new()
	rastro.size = Vector2(lado * 0.7, lado * 0.7)
	_rastro = MeshInstance3D.new()
	_rastro.mesh = rastro
	_rastro.material_override = mat_rastro
	_rastro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_rastro)

func _montar_estrellas() -> void:
	_estrellas = Node3D.new()
	_miembros.add_child(_estrellas)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(2.4, 2.1, 0.7)
	for i in 3:
		var ang := TAU * float(i) / 3.0
		_bola(_estrellas, 0.016, Vector3(cos(ang), 0.0, sin(ang)) * 0.085,
			mat, Vector3.ONE, 6, false)
	_estrellas.visible = false

func _montar_aviso(fuente: Font) -> void:
	_aviso = Label3D.new()
	_aviso.text = "!"
	_aviso.font = fuente
	_aviso.font_size = 96
	_aviso.pixel_size = 0.0024
	_aviso.outline_size = 0
	_aviso.shaded = false
	_aviso.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_aviso.modulate = Color(1.0, 0.25, 0.2)
	_aviso.visible = false
	_miembros.add_child(_aviso)

# ------------------------------------------------------------------- sucesos

## El golpe: fogonazo, y el cuerpo se aplasta contra la dirección del impacto.
func golpear(normal: Vector2) -> void:
	_destello = 1.0
	_golpe_t = 0.0
	_golpe_n = Vector3(normal.x, 0.0, normal.y)
	_parada = 0.05

## La coraza ha parado la bola.
func blindar() -> void:
	_choque = 1.0
	_destello = 0.35

func avisar_aro() -> void:
	_aro_aviso = 1.0

func color() -> Color:
	return _color

## Dónde está el centro del cuerpo, para que la cámara y los efectos lo sigan.
func centro() -> Vector3:
	return _raiz.position

func _ocultar() -> void:
	_raiz.visible = false
	_miembros.visible = false
	_aro.visible = false
	_charco.visible = false
	_rastro.visible = false

# --------------------------------------------------------------- cada cuadro

## `bola` es dónde está la bola que la lleva, si va dentro de una.
func actualizar(delta: float, bola: Vector3) -> void:
	_tiempo += delta
	var estado := c.estado
	var suelo := Vector3(c.pos.x * E, y_base, c.pos.y * E)

	if estado != _estado_antes:
		if estado == Criatura.Estado.ALERTA:
			_aviso_t = 0.7
		if estado == Criatura.Estado.EN_BOLA:
			_desde_recogida = _raiz.position
		if estado == Criatura.Estado.APARECER:
			# Sale de la nada: sin tamaño y ya mirando hacia donde va.
			_escala = Vector3.ONE * 0.02
			_yaw = atan2(c.rumbo.x, c.rumbo.y)
		if _estado_antes == Criatura.Estado.VOLAR \
				or _estado_antes == Criatura.Estado.APARECER \
				or _estado_antes == Criatura.Estado.VOLCADA \
				or _estado_antes == Criatura.Estado.FUERA \
				or _estado_antes == Criatura.Estado.ESCONDIDA or _estado_antes == -1:
			_pies_puestos = false
		_estado_antes = estado

	if not c.activa or estado == Criatura.Estado.FUERA:
		# Fuera no hay golpe que enseñar. Sin tirarlo aquí, el fogonazo y la
		# parada del golpe que partió a GOTA se quedaban guardados y saltaban
		# al reaparecer: un fantasma blanco tres cuadros en el sitio viejo.
		_parada = 0.0
		_destello = 0.0
		_golpe_t = 9.0
		_ocultar()
		return
	if estado == Criatura.Estado.ESCONDIDA:
		# Dentro del túnel no se la ve: solo una luz que corre bajo el cristal.
		_ocultar()
		_rastro.visible = true
		_rastro.position = suelo + Vector3(0.0, 0.006, 0.0)
		return
	if estado == Criatura.Estado.EN_BOLA:
		# La bola se la traga: va hacia ella encogiéndose y girando.
		var u := clampf(c.t_estado / 0.30, 0.0, 1.0)
		_ocultar()
		if u < 1.0:
			_raiz.visible = true
			var k := u * u
			_raiz.position = _desde_recogida.lerp(bola, k)
			_raiz.basis = Basis(Vector3.UP, _yaw + u * 9.0)
			_forma.scale = Vector3.ONE * _talla * (1.0 - k)
			for m in _mats:
				m.set_shader_parameter("golpe", 0.6 * u)
				m.set_shader_parameter("disolver", 0.0)
		return

	_raiz.visible = true
	# Al aparecer, las patas esperan a que el cuerpo tenga tamaño.
	_miembros.visible = estado != Criatura.Estado.APARECER or c.t_estado > 0.22
	_rastro.visible = false

	# La parada del golpe: 50 ms con la pose congelada. Solo aquí, en lo que se
	# ve: la mesa no se detiene.
	if _parada > 0.0:
		_parada -= delta
		_destello = maxf(_destello - delta * 5.0, 0.0)
		for m in _mats:
			m.set_shader_parameter("golpe", _destello)
		return

	var v3 := Vector3(c.vel.x, 0.0, c.vel.y) * E
	var rapidez := v3.length()
	var adelante := Vector3(c.rumbo.x, 0.0, c.rumbo.y)
	if adelante.length_squared() < 1e-6:
		adelante = Vector3(0.0, 0.0, 1.0)
	adelante = adelante.normalized()

	# --- El cuerpo: dónde, hacia dónde y cómo de aplastado -------------------
	var en_suelo := estado == Criatura.Estado.CORRER or estado == Criatura.Estado.HUIR
	var alto := _alto
	var escala := Vector3.ONE
	var inclinacion := 0.0
	var salto := 0.0
	var tiembla := c.miedo * c.miedo * 0.45
	var vuelco_objetivo := Quaternion.IDENTITY
	var endereza := 16.0

	_yaw = lerp_angle(_yaw, atan2(adelante.x, adelante.z), 1.0 - exp(-14.0 * delta))

	if en_suelo:
		var corre := clampf(rapidez / maxf(c.v_huir * E, 0.3), 0.0, 1.0)
		if c.salta:
			# El bote lo dicta la lógica: de 0 a 1 en el aire, −1 posada.
			if c.bote_u >= 0.0:
				var arco_salto := sin(PI * c.bote_u)
				salto = _alzada * arco_salto
				escala = Vector3(0.90, 1.0 + 0.24 * arco_salto, 0.90)
			else:
				# Posada: se aplasta cogiendo impulso.
				var late := 0.5 + 0.5 * sin(_tiempo * 9.0)
				escala = Vector3(1.14, 0.74 + 0.05 * late, 1.14)
			alto = _alto * escala.y
		else:
			_fase = fposmod(_fase + rapidez * delta / _zancada, 1.0)
			alto += absf(sin(_fase * TAU)) * 0.014 * corre * (2.0 if _rodilla_delante else 1.0)
			inclinacion = (0.34 if _rodilla_delante else 0.10) * corre
	elif estado == Criatura.Estado.ALERTA:
		# La anticipación: se agacha un instante. Es el aviso de que va a salir.
		escala = Vector3(1.14, 0.70, 1.14)
		alto = _alto * 0.72
	elif estado == Criatura.Estado.VOLAR:
		# Por los aires: bota cada vez menos y RUEDA de verdad, lo que avanza.
		var t := c.t_estado
		salto = 0.20 * _talla * absf(sin(t * 9.0)) * exp(-t * 3.0)
		if rapidez > 0.02:
			var eje := Vector3.UP.cross(v3 / rapidez)
			_vuelco = (Quaternion(eje, rapidez * delta / maxf(_alto, 0.08)) * _vuelco).normalized()
		vuelco_objetivo = _vuelco
		var toca := 1.0 - smoothstep(0.0, 0.05, salto)
		escala = Vector3(1.0 + 0.10 * toca, 1.0 - 0.14 * toca, 1.0 + 0.10 * toca)
	elif estado == Criatura.Estado.ATURDIDA:
		endereza = 9.0
		var late := sin(_tiempo * 7.0)
		escala = Vector3(1.08 + 0.03 * late, 0.82 - 0.03 * late, 1.08 + 0.03 * late)
		alto = _alto * 0.80
		inclinacion = 0.16 * sin(_tiempo * 3.1)
	elif estado == Criatura.Estado.ACORRALADA:
		escala = Vector3(1.10, 0.74, 1.10)
		alto = _alto * 0.70
		tiembla = 1.0
	elif estado == Criatura.Estado.VOLCADA:
		# Panza arriba, balanceándose sobre el caparazón.
		endereza = 10.0
		vuelco_objetivo = Quaternion(adelante, PI + 0.22 * sin(_tiempo * 5.5))
		alto = _alto * 0.92
		tiembla = 0.25
	elif estado == Criatura.Estado.APARECER:
		var u := clampf(c.t_estado / 0.6, 0.0, 1.0)
		# Sale con un rebote de muelle: se pasa de tamaño y vuelve.
		var muelle := 1.0 - cos(u * PI * 2.6) * exp(-u * 4.0)
		escala = Vector3.ONE * clampf(muelle, 0.02, 1.4)
		# A su altura desde el principio: si naciera a ras de suelo, medio
		# cuerpo quedaría bajo el cristal y la cámara del reflejo lo dibujaría.
		_vuelco = Quaternion.IDENTITY

	if estado != Criatura.Estado.VOLAR:
		_vuelco = _vuelco.slerp(vuelco_objetivo, 1.0 - exp(-endereza * delta))

	# El golpe: aplastada contra la dirección del impacto y vuelta con un muelle.
	_golpe_t += delta
	var base_forma := Basis.IDENTITY
	if _golpe_t < 0.45:
		var cede := 0.45 if _golpe_t < 0.06 else \
			0.45 * exp(-(_golpe_t - 0.06) * 14.0) * cos((_golpe_t - 0.06) * 34.0)
		var giro_inv := (Basis(_vuelco) * Basis(Vector3.UP, _yaw)).inverse()
		var n_local := (giro_inv * _golpe_n).normalized()
		if n_local.length_squared() > 0.5:
			var lado := n_local.cross(Vector3.UP)
			if lado.length_squared() < 1e-6:
				lado = Vector3.RIGHT
			lado = lado.normalized()
			var marco := Basis(lado, Vector3.UP, lado.cross(Vector3.UP).normalized())
			base_forma = marco * Basis.from_scale(
				Vector3(1.0 + cede * 0.5, 1.0 + cede * 0.3, 1.0 - cede)) * marco.inverse()

	_escala = _escala.lerp(escala, 1.0 - exp(-26.0 * delta))
	var base_giro := Basis(_vuelco) * Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, inclinacion)
	_raiz.transform = Transform3D(base_giro, suelo + Vector3(0.0, alto + salto, 0.0))
	_forma.transform = Transform3D(base_forma * Basis.from_scale(_escala * _talla), Vector3.ZERO)

	# --- La piel -----------------------------------------------------------
	_destello = maxf(_destello - delta * 5.0, 0.0)
	_choque = maxf(_choque - delta * 3.5, 0.0)
	for m in _mats:
		m.set_shader_parameter("golpe", _destello)
		m.set_shader_parameter("miedo", tiembla)
		m.set_shader_parameter("disolver", 0.0)

	# --- Lo pintado en el cristal -------------------------------------------
	_aro_aviso = maxf(_aro_aviso - delta * 3.0, 0.0)
	var rendida := estado == Criatura.Estado.ACORRALADA or estado == Criatura.Estado.VOLCADA
	var con_aro := c.especie == "corredor" or c.especie == "escarabajo"
	_aro.visible = con_aro and estado != Criatura.Estado.APARECER
	# Un pelo por encima del disco de las bocas del túnel (0,009): a la misma
	# altura, al pasar LUMI por encima los dos planos se pelean y parpadea.
	_aro.position = suelo + Vector3(0.0, 0.013, 0.0)
	_charco.visible = true
	_charco.position = suelo + Vector3(0.0, 0.011, 0.0)
	var medida := c.miedo
	if estado == Criatura.Estado.ACORRALADA:
		medida = 1.0 - clampf(c.t_estado / maxf(t_cierre, 0.1), 0.0, 1.0)
	elif estado == Criatura.Estado.VOLCADA:
		medida = 1.0 - clampf(c.t_estado / maxf(t_volcada, 0.1), 0.0, 1.0)
	var con_escudo := c.especie == "escarabajo" and estado != Criatura.Estado.VOLCADA
	_mat_aro.set_shader_parameter("miedo", medida)
	_mat_aro.set_shader_parameter("rendida", 1.0 if rendida else 0.0)
	_mat_aro.set_shader_parameter("aviso", _aro_aviso)
	_mat_aro.set_shader_parameter("escudo", 1.0 if con_escudo else 0.0)
	# El rumbo de la LÓGICA, no el giro suavizado del cuerpo: mientras TANQUE
	# gira van 12° separados, y el arco tiene que marcar lo que de verdad para.
	_mat_aro.set_shader_parameter("direccion", Vector2(adelante.x, adelante.z))
	_mat_aro.set_shader_parameter("choque", _choque)

	_mover_ojos(delta, estado)
	_mover_patas(delta, suelo, v3, rapidez, adelante, en_suelo, estado)
	_mover_brazos(estado, rapidez)
	_mover_antenas(rapidez)

	# --- Estrellas y susto ---------------------------------------------------
	_estrellas.visible = estado == Criatura.Estado.ATURDIDA
	if _estrellas.visible:
		_estrellas.position = _raiz.position + Vector3(0.0, _alto * 1.25 + 0.06, 0.0)
		_estrellas.rotation.y = _tiempo * 7.0
	_aviso_t = maxf(_aviso_t - delta, 0.0)
	_aviso.visible = _aviso_t > 0.0 and (estado == Criatura.Estado.ALERTA \
		or estado == Criatura.Estado.HUIR)
	if _aviso.visible:
		var sube := 1.0 - _aviso_t / 0.7
		_aviso.position = _raiz.position + Vector3(0.0, _alto * 1.3 + 0.12 + sube * 0.05, 0.0)
		_aviso.modulate.a = clampf(_aviso_t * 4.0, 0.0, 1.0)

func _mover_ojos(delta: float, estado: int) -> void:
	_prox_parpadeo -= delta
	if _prox_parpadeo <= 0.0:
		_parpadeo = 0.13
		_prox_parpadeo = 2.2 + fposmod(_tiempo * 7.3 + float(c.indice), 2.5)
	_parpadeo = maxf(_parpadeo - delta, 0.0)
	var abre := 1.0
	if estado == Criatura.Estado.ATURDIDA:
		abre = 0.22
	elif estado == Criatura.Estado.ACORRALADA or estado == Criatura.Estado.ALERTA \
			or estado == Criatura.Estado.VOLCADA:
		abre = 1.30
	elif estado == Criatura.Estado.HUIR:
		abre = 1.12
	elif _parpadeo > 0.0:
		abre = 0.12
	var mira3 := Vector3(c.mira.x * E, y_base + 0.09, c.mira.y * E)
	var hacia := _forma.global_transform.affine_inverse() * mira3
	for ojo in _ojos:
		var blanco: MeshInstance3D = ojo["blanco"]
		var pupila: MeshInstance3D = ojo["pupila"]
		var centro: Vector3 = ojo["centro"]
		var radio: float = ojo["radio"]
		blanco.scale = Vector3(1.0, abre, 1.0)
		var d := hacia - centro
		d = d.normalized() if d.length_squared() > 1e-8 else Vector3(0.0, 0.0, 1.0)
		# Que no se le vayan a la nuca del todo: siempre un poco hacia arriba,
		# que es desde donde mira la cámara.
		d = (d + Vector3(0.0, 0.55, 0.15)).normalized()
		pupila.position = centro + d * radio * 0.62
		pupila.visible = estado != Criatura.Estado.ATURDIDA

## LAS PATAS. Cada pie tiene una fase: media vuelta apoyado —clavado donde cayó,
## mientras el cuerpo le pasa por encima— y media en el aire, yendo a donde
## tendrá que estar cuando el cuerpo llegue. La fase avanza con la DISTANCIA
## recorrida y no con el tiempo, así que parada no mueve los pies y a la carrera
## los mueve deprisa, sin tocar ningún número.
func _mover_patas(delta: float, suelo: Vector3, v3: Vector3, rapidez: float,
		adelante: Vector3, en_suelo: bool, estado: int) -> void:
	if _patas.is_empty():
		return
	var cuerpo := _raiz.transform
	var plano := Basis(Vector3.UP, _yaw)
	var dir := v3 / rapidez if rapidez > 0.01 else adelante
	var apoyada := en_suelo or estado == Criatura.Estado.ATURDIDA \
		or estado == Criatura.Estado.ACORRALADA or estado == Criatura.Estado.ALERTA
	if estado == Criatura.Estado.APARECER:
		apoyada = true
	var abierta := 1.0
	if estado == Criatura.Estado.ATURDIDA:
		abierta = 1.25
	elif estado == Criatura.Estado.ACORRALADA or estado == Criatura.Estado.ALERTA:
		abierta = 0.78

	for pata in _patas:
		var reposo2: Vector2 = pata["reposo"]
		var reposo := suelo + plano * Vector3(reposo2.x * abierta, 0.0, reposo2.y * abierta)
		var cadera: Vector3 = cuerpo * (pata["cadera"] as Vector3)
		var l1: float = pata["l1"]
		var l2: float = pata["l2"]
		var pie: Vector3 = pata["pie"]

		if apoyada:
			if not _pies_puestos:
				pie = reposo
				pata["en_aire"] = false
			var fase := fposmod(_fase + float(pata["fase0"]), 1.0)
			var en_aire := en_suelo and fase >= 0.5 and rapidez > 0.03
			if en_aire and not bool(pata["en_aire"]):
				pata["desde"] = pie
			pata["en_aire"] = en_aire
			if en_aire:
				var u := (fase - 0.5) * 2.0
				var destino := reposo + dir * _zancada * (0.5 * (1.0 - u) + 0.25)
				var desde: Vector3 = pata["desde"]
				pie = desde.lerp(destino, smoothstep(0.0, 1.0, u))
				pie.y = y_base + _alzada * sin(PI * u)
			else:
				# Apoyado no se mueve. Salvo que se haya quedado demasiado lejos
				# —un giro en el sitio, un empujón—: entonces recoloca el pie.
				var lejos := Vector2(pie.x - reposo.x, pie.z - reposo.z).length()
				if lejos > _zancada * 0.95 or not en_suelo:
					pie = pie.lerp(reposo, 1.0 - exp(-18.0 * delta))
				pie.y = y_base
		else:
			# Por el aire o panza arriba: las patas van con el cuerpo, encogidas
			# y pataleando.
			var fuera_local: Vector3 = (pata["cadera"] as Vector3)
			fuera_local.y = -0.55 * (l1 + l2)
			var ritmo := 30.0 if estado == Criatura.Estado.VOLAR else 17.0
			var patalea := sin(_tiempo * ritmo + float(pata["fase0"]) * TAU \
				+ fuera_local.z * 20.0) * 0.035
			pie = cuerpo * (fuera_local * 1.25 + Vector3(patalea * 0.5, patalea, patalea))
			# Nunca por debajo del cristal: la cámara del reflejo lo vería.
			pie.y = maxf(pie.y, y_base + 0.012)
		pata["pie"] = pie

		# Cinemática inversa de dos tramos: dónde cae la rodilla.
		var d := pie - cadera
		var dist := d.length()
		var alcance := l1 + l2 - 0.002
		var u_dir := d / dist if dist > 1e-6 else Vector3.DOWN
		if dist > alcance:
			dist = alcance
			pie = cadera + u_dir * dist
		dist = maxf(dist, absf(l1 - l2) + 0.002)
		var a := (l1 * l1 - l2 * l2 + dist * dist) / (2.0 * dist)
		var h := sqrt(maxf(l1 * l1 - a * a, 0.0))
		var lado := cadera - _raiz.position
		lado.y = 0.0
		var doblar := cuerpo.basis * Vector3.UP
		if _rodilla_delante:
			doblar = cuerpo.basis * Vector3(0.0, 0.15, 1.0)
		elif lado.length_squared() > 1e-8:
			doblar = cuerpo.basis * Vector3.UP + lado.normalized() * 0.55
		doblar = doblar - u_dir * doblar.dot(u_dir)
		if doblar.length_squared() < 1e-8:
			doblar = Vector3.UP
		var rodilla := cadera + u_dir * a + doblar.normalized() * h

		var grosor: float = pata["grosor"]
		_tender(pata["muslo"] as MeshInstance3D, cadera, rodilla, grosor)
		_tender(pata["tibia"] as MeshInstance3D, rodilla, pie, grosor * 0.85)
		(pata["rodilla"] as MeshInstance3D).position = rodilla
		(pata["zapato"] as MeshInstance3D).position = pie \
			+ Vector3(0.0, float(pata["r_pie"]) * 0.6, 0.0)
	if apoyada:
		_pies_puestos = true

func _mover_brazos(estado: int, rapidez: float) -> void:
	if _brazos.is_empty():
		return
	var cuerpo := _raiz.transform
	for brazo in _brazos:
		var hombro_l: Vector3 = brazo["hombro"]
		var largo: float = brazo["largo"]
		var lado: float = brazo["lado"]
		var mano_l := hombro_l
		if estado == Criatura.Estado.ACORRALADA or estado == Criatura.Estado.ALERTA:
			# Las manos a la cabeza.
			mano_l = hombro_l + Vector3(-lado * 0.35, 1.0, 0.45).normalized() * largo
		elif estado == Criatura.Estado.HUIR or estado == Criatura.Estado.VOLAR:
			# Pánico: las manos arriba, agitándose.
			var agita := sin(_tiempo * 26.0 + lado * 1.7) * 0.025
			mano_l += Vector3(lado * (0.035 + agita), 1.0, 0.25).normalized() * largo
		elif estado == Criatura.Estado.ATURDIDA:
			mano_l += Vector3(lado * 1.0, -0.25, 0.1).normalized() * largo
		else:
			# Braceo: contrario a la pierna de su lado.
			var corre := clampf(rapidez / maxf(c.v_huir * E, 0.3), 0.0, 1.0)
			var vaiven := sin((_fase + (0.5 if lado < 0.0 else 0.0)) * TAU) * 0.9 * corre
			mano_l += Vector3(lado * 0.25, -1.0, vaiven).normalized() * largo
		var hombro := cuerpo * hombro_l
		var mano := cuerpo * mano_l
		_tender(brazo["tramo"] as MeshInstance3D, hombro, mano, float(brazo["grosor"]))
		(brazo["mano"] as MeshInstance3D).position = mano

func _mover_antenas(rapidez: float) -> void:
	if _antenas.is_empty():
		return
	var cuerpo := _raiz.transform
	for antena in _antenas:
		var base_l: Vector3 = antena["base"]
		var punta_l: Vector3 = antena["punta"]
		var fase: float = antena["fase"]
		# Se cimbrea sola, y se echa hacia atrás al correr.
		var cimbreo := Vector3(sin(_tiempo * 5.0 + fase) * 0.012,
			0.0, cos(_tiempo * 4.1 + fase) * 0.010 - rapidez * 0.022)
		var base := cuerpo * base_l
		var punta := cuerpo * (punta_l + cimbreo)
		_tender(antena["tramo"] as MeshInstance3D, base, punta, float(antena["grosor"]))
		(antena["luz"] as MeshInstance3D).position = punta
