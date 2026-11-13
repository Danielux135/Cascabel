extends Node3D

## PRUEBA 3D — el aspecto de «ÓRBITA». Todo lo que se ve sale de aquí y de seis
## shaders, y NADA viene de los gráficos de Cascabel: ni una textura, ni la
## paleta, ni la fuente. No hay un solo modelo ni una sola imagen en disco:
## cada pieza se levanta por código a partir de la geometría de la mesa, así
## que el arte y el colisionador son la misma medida por construcción.
##
## LA IDEA VISUAL: una losa de cristal oscuro flotando sobre una nebulosa. El
## cristal refleja la mesa de verdad. Encima, metal oscuro con filos de neón,
## soles que hierven, raíles cromados con luz que corre por dentro y una bola de
## cromo que deja estela. Cada tiro tiene su color y lo lleva de la boca al
## final: órbita violeta, cometa cian, estación magenta, sol ámbar.

const M := preload("res://prueba3d/mallas_3d.gd")
const MesaOrbita := preload("res://prueba3d/mesa_orbita.gd")
const Criatura := preload("res://prueba3d/criatura.gd")
const Cuerpo := preload("res://prueba3d/criatura_3d.gd")
const Caza := preload("res://prueba3d/caza_orbita.gd")
const E := 0.01
const COLOR_BOLA := Color(0.55, 0.78, 1.0)

const H_PARED := 0.16
const H_ALTA := 0.24
const H_TUNEL := -0.36
const TRAMOS := 3
const Y_ARRIBA := 548.0
const Y_ABAJO := 1300.0

const CIAN := Color(0.20, 0.88, 1.0)
const MAGENTA := Color(1.0, 0.22, 0.60)
const AMBAR := Color(1.0, 0.60, 0.16)
const VIOLETA := Color(0.58, 0.40, 1.0)
const BLANCO := Color(0.92, 0.95, 1.0)
const ACERO := Color(0.055, 0.065, 0.095)
const ACERO_CLARO := Color(0.15, 0.17, 0.24)
const GOMA := Color(0.03, 0.03, 0.045)

## Lo que queda por debajo del cristal va en esta capa de dibujo, que la cámara
## del reflejo no mira: si no, el canto de la losa saldría reflejado encima.
const CAPA_BAJO_CRISTAL := 2

## Y en esta va lo que el reflejo no necesita: lo que está pintado a ras de
## cristal (su reflejo cae encima de sí mismo y no se ve nunca), los rótulos y
## las chispas. No es por gusto: en un navegador cada llamada de dibujo cuesta
## unas treinta millonésimas de segundo del hilo principal —medido: 133 llamadas
## de reflejo, 4 ms por fotograma—, y la cámara del reflejo las repetía todas.
const CAPA_SIN_REFLEJO := 4

## Lo menudo de las criaturas —patas, ojos, antenas—. La cámara del reflejo solo
## mira esta capa en las cámaras de cerca, que es donde se le ve el reflejo a
## una criatura con detalle; en la de juego se lo ahorra (`prueba_3d.gd`).
const CAPA_DETALLE := 8

var mesa: MesaOrbita
var entorno: Environment
var entorno_reflejo: Environment
var luz_sol: DirectionalLight3D
var _mat_cielo: ShaderMaterial
var _horno: SubViewport
var _cuadros := 0
var mat_suelo: ShaderMaterial
var sacudida := 0.0

var _r_bola: float
var _tiempo := 0.0
var _latido := 0.0
var _fuente: Font

var _mat_pintado: StandardMaterial3D
var _mat_cromo: StandardMaterial3D

var _bolas: Array[MeshInstance3D] = []
var _luces_bola: Array[OmniLight3D] = []
var _y_bola: Dictionary = {}
var _rastro: Dictionary = {}
var _malla_estela: ImmediateMesh
var _mat_estela: StandardMaterial3D
var _flippers: Array[Node3D] = []
var _targets: Array[MeshInstance3D] = []
var _soles: Array[Dictionary] = []
var _slings: Array[Dictionary] = []
var _giradores: Array[Dictionary] = []
var _platillos: Array[Dictionary] = []
var _portales: Dictionary = {}
var _cintas: Dictionary = {}
var _ondas: Array[Dictionary] = []
var _onda_siguiente := 0
var _chispas: Array[CPUParticles3D] = []
var _chispa_siguiente := 0
var _lanzador: Node3D
var _lanzador_z := 0.0

## LA CAZA (`caza_orbita.gd`) y los cuerpos de sus criaturas, en el mismo orden.
var caza: Caza = null
var _bichos: Array[Node3D] = []
var _mats_bola: Array[StandardMaterial3D] = []
## Qué bola dibujó cada hueco el cuadro anterior. El material es del HUECO y las
## bolas cambian de hueco (multibola) o se reutilizan (`nueva_bola`).
var _bola_del_hueco: Array = []
## Bola → color de la criatura que lleva dentro.
var _tinte: Dictionary = {}
var _almas: Array[Dictionary] = []

# ------------------------------------------------------------------- montaje

func montar(la_mesa: MesaOrbita) -> void:
	mesa = la_mesa
	_r_bola = mesa.p.radio_bola * E
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Bahnschrift", "Segoe UI Semibold", "Arial"])
	f.font_weight = 600
	_fuente = f
	_materiales()
	_montar_entorno()
	_montar_suelo()
	_montar_paredes()
	_montar_mueble()
	_montar_estacion()
	_montar_pintura()
	_montar_recorridos()
	_montar_soles()
	_montar_slingshots()
	_montar_postes()
	_montar_targets()
	_montar_flippers()
	_montar_giradores()
	_montar_platillos()
	_montar_lanzador()
	_montar_rotulos()
	_montar_bolas()
	_montar_chispas()
	_montar_ondas()
	_montar_polvo()
	mesa.bumper_golpeado.connect(_al_golpear_sol)
	mesa.slingshot_golpeado.connect(_al_golpear_slingshot)
	mesa.poste_golpeado.connect(_al_golpear_poste)
	mesa.girador_girado.connect(_al_girar)
	mesa.target_abatido.connect(_al_abatir)
	mesa.bola_cayo.connect(_al_caer)
	mesa.rampa_entrada.connect(_al_entrar_rampa)
	mesa.rampa_salida.connect(_al_salir_rampa)
	mesa.platillo_capturado.connect(_al_capturar)
	mesa.platillo_expulsado.connect(_al_expulsar)
	_aligerar_reflejo(self)

func _aligerar_reflejo(raiz: Node) -> void:
	for n in raiz.get_children():
		_aligerar_reflejo(n)
		var gi := n as GeometryInstance3D
		if gi == null or (gi.layers & 1) == 0:
			continue
		var fuera := gi is Label3D or gi is CPUParticles3D
		if not fuera:
			var caja: AABB = gi.global_transform * gi.get_aabb()
			fuera = caja.position.y + caja.size.y < 0.03
		if fuera:
			gi.layers = CAPA_SIN_REFLEJO

func _materiales() -> void:
	_mat_pintado = StandardMaterial3D.new()
	_mat_pintado.vertex_color_use_as_albedo = true
	_mat_pintado.metallic = 0.55
	_mat_pintado.roughness = 0.34
	_mat_cromo = StandardMaterial3D.new()
	_mat_cromo.albedo_color = Color(0.80, 0.85, 0.95)
	_mat_cromo.metallic = 1.0
	_mat_cromo.roughness = 0.20

func _neon(col: Color, energia: float = 2.4) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col.darkened(0.7)
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energia
	return m

func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st

func _malla(st: SurfaceTool, mat: Material, sombra: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi

func _luz(donde: Vector3, col: Color, energia: float, alcance: float) -> OmniLight3D:
	var luz := OmniLight3D.new()
	luz.light_color = col
	luz.light_energy = energia
	luz.omni_range = alcance
	luz.position = donde
	add_child(luz)
	return luz

func _tramo(y_mesa: float) -> int:
	return clampi(int((y_mesa - Y_ARRIBA) / ((Y_ABAJO - Y_ARRIBA) / float(TRAMOS))),
		0, TRAMOS - 1)

# ------------------------------------------------------------ luz y ambiente

func _montar_entorno() -> void:
	var cielo := Sky.new()
	_mat_cielo = ShaderMaterial.new()
	_mat_cielo.shader = load("res://prueba3d/cielo.gdshader")
	_hornear_nebulosa()
	cielo.sky_material = _mat_cielo
	cielo.radiance_size = Sky.RADIANCE_SIZE_256

	entorno = Environment.new()
	entorno.background_mode = Environment.BG_SKY
	entorno.sky = cielo
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.30, 0.36, 0.62)
	entorno.ambient_light_energy = 0.55
	entorno.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	# La cámara del reflejo usa el mismo mundo, pero sin brillo ni curva de
	# tono: su imagen no va a la pantalla, va al cristal, y el cristal ya pasa
	# luego por todo eso. Con los dos, el reflejo se quemaría dos veces.
	entorno_reflejo = entorno.duplicate()
	entorno.tonemap_mode = Environment.TONE_MAPPER_ACES
	entorno.tonemap_white = 6.0
	entorno.glow_enabled = true
	entorno.glow_intensity = 1.0
	entorno.glow_strength = 1.05
	entorno.glow_bloom = 0.05
	entorno.glow_hdr_threshold = 0.95
	entorno.adjustment_enabled = true
	entorno.adjustment_contrast = 1.07
	entorno.adjustment_saturation = 1.12
	var we := WorldEnvironment.new()
	we.environment = entorno
	add_child(we)

	luz_sol = DirectionalLight3D.new()
	luz_sol.light_color = Color(0.78, 0.86, 1.0)
	luz_sol.light_energy = 0.95
	luz_sol.rotation_degrees = Vector3(-56.0, -34.0, 0.0)
	luz_sol.shadow_enabled = true
	luz_sol.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	luz_sol.directional_shadow_max_distance = 30.0
	luz_sol.shadow_blur = 1.4
	add_child(luz_sol)

## LA NEBULOSA SE PINTA UNA VEZ. El cielo no cambia nunca y son quince capas
## de ruido: calculadas en cada píxel de cada fotograma eran más de la mitad de
## lo que costaba un píxel en una gráfica integrada (medido en el navegador:
## 3,9 ms de 15 a 1141×590). Aquí se dibuja en una textura que da la vuelta
## entera, una sola vez, y `cielo.gdshader` solo la lee.
func _hornear_nebulosa() -> void:
	_horno = SubViewport.new()
	_horno.size = Vector2i(2048, 1024)
	_horno.disable_3d = true
	_horno.render_target_update_mode = SubViewport.UPDATE_ONCE
	var lienzo := ColorRect.new()
	lienzo.size = Vector2(_horno.size)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://prueba3d/nebulosa.gdshader")
	lienzo.material = mat
	_horno.add_child(lienzo)
	add_child(_horno)
	_mat_cielo.set_shader_parameter("nebulosa", _horno.get_texture())

func _montar_suelo() -> void:
	mat_suelo = ShaderMaterial.new()
	mat_suelo.shader = load("res://prueba3d/suelo.gdshader")
	mat_suelo.set_shader_parameter("centro_sol", Vector2(160.0, 742.0) * E)
	var largo := (Y_ABAJO - Y_ARRIBA) * E / float(TRAMOS)
	for i in TRAMOS:
		var plano := PlaneMesh.new()
		plano.size = Vector2(Mesa.ANCHO * E, largo)
		var mi := MeshInstance3D.new()
		mi.mesh = plano
		mi.material_override = mat_suelo
		mi.position = Vector3(Mesa.ANCHO * E * 0.5, 0.0,
			Y_ARRIBA * E + largo * (float(i) + 0.5))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)

# -------------------------------------------------------------------- paredes

func _montar_paredes() -> void:
	var acero: Array[SurfaceTool] = []
	for _i in TRAMOS:
		acero.append(_st())
	var filo_cian := _st()
	var filo_magenta := _st()
	var hay_magenta := false
	for c in mesa.colisionadores:
		if c.tipo != Colisionador.Tipo.PARED:
			continue
		var t := _tramo(c.centro().y)
		if c.capas == Colisionador.TODAS:
			M.estadio(acero[t], c.a, c.b, 3.0, 0.0, H_PARED, 0.02,
				ACERO, ACERO_CLARO, 3)
			M.estadio(filo_cian, c.a, c.b, 1.1, H_PARED, H_PARED + 0.014, 0.004,
				CIAN, CIAN, 3)
		elif c.capas == Colisionador.bit(Mesa.CAPA_ALTA):
			# Las barandillas de la estación: más bajas y de otro color, para
			# que la cubierta se lea como otro sitio.
			M.estadio(acero[t], c.a, c.b, 2.2, H_ALTA, H_ALTA + 0.12, 0.015,
				ACERO, ACERO_CLARO, 3)
			M.estadio(filo_magenta, c.a, c.b, 1.0, H_ALTA + 0.12,
				H_ALTA + 0.132, 0.004, MAGENTA, MAGENTA, 3)
			hay_magenta = true
	for st in acero:
		_malla(st, _mat_pintado)
	_malla(filo_cian, _neon(CIAN, 1.35), false)
	if hay_magenta:
		_malla(filo_magenta, _neon(MAGENTA, 1.5), false)

## El mueble: una losa gruesa con el canto a la vista, que es lo que la hace
## flotar. Lo que sobresale del cristal se refleja; el canto de abajo, no.
func _montar_mueble() -> void:
	var g := 20.0
	var x0 := -g
	var x1 := Mesa.ANCHO + g
	var y0 := Y_ARRIBA - g
	var y1 := Y_ABAJO + g * 1.6
	var marcos := [
		Rect2(x0, y0, g, y1 - y0),
		Rect2(Mesa.ANCHO, y0, g, y1 - y0),
		Rect2(0.0, y0, Mesa.ANCHO, g),
		Rect2(0.0, Y_ABAJO, Mesa.ANCHO, y1 - Y_ABAJO),
	]
	var arriba := _st()
	var abajo := _st()
	for r in marcos:
		M.caja(arriba, r, 0.0, 0.22, ACERO, ACERO.lightened(0.03))
		M.caja(abajo, r, -0.42, 0.0, ACERO, ACERO)
	# El fondo de la losa, para que no se vea hueca desde los lados.
	M.caja(abajo, Rect2(0.0, Y_ARRIBA, Mesa.ANCHO, Y_ABAJO - Y_ARRIBA),
		-0.42, -0.02, ACERO, ACERO)
	_malla(arriba, _mat_pintado)
	var mi := _malla(abajo, _mat_pintado, false)
	mi.layers = CAPA_BAJO_CRISTAL

	# Las dos enjutas: el hueco entre el arco y las esquinas del mueble.
	var enjutas := _st()
	var c := mesa.arco_centro
	for lado in [-1.0, 1.0]:
		var pol := PackedVector2Array()
		for i in mesa.arco.size():
			var pt := mesa.arco[i]
			if (pt.x - c.x) * lado >= 0.0:
				pol.append(pt)
		if lado > 0.0:
			# El arco va de derecha a izquierda: esta mitad empieza en la banda.
			pol.append(Vector2(c.x, Y_ARRIBA))
			pol.append(Vector2(Mesa.ANCHO, Y_ARRIBA))
			pol.append(Vector2(Mesa.ANCHO, c.y))
		else:
			pol.append(Vector2(0.0, c.y))
			pol.append(Vector2(0.0, Y_ARRIBA))
			pol.append(Vector2(c.x, Y_ARRIBA))
		M.prisma(enjutas, pol, 0.0, H_PARED - 0.012, ACERO, ACERO.lightened(0.04))
	_malla(enjutas, _mat_pintado)

	# Un filo violeta alrededor del mueble, arriba y abajo.
	var filo := _st()
	var e := 2.0
	for y in [0.22, -0.42]:
		var h0: float = y - 0.006
		var h1: float = y + 0.008
		M.caja(filo, Rect2(x0, y0, x1 - x0, e), h0, h1, VIOLETA, VIOLETA)
		M.caja(filo, Rect2(x0, y1 - e, x1 - x0, e), h0, h1, VIOLETA, VIOLETA)
		M.caja(filo, Rect2(x0, y0, e, y1 - y0), h0, h1, VIOLETA, VIOLETA)
		M.caja(filo, Rect2(x1 - e, y0, e, y1 - y0), h0, h1, VIOLETA, VIOLETA)
	var mf := _malla(filo, _neon(VIOLETA, 1.5), false)
	mf.layers = CAPA_BAJO_CRISTAL | 1

	# La boca del drenaje.
	var drenaje := _st()
	M.caja(drenaje, Rect2(42.0, mesa.p.y_drenaje - 6.0, 294.0, 5.0),
		0.0, 0.012, MAGENTA, MAGENTA)
	_malla(drenaje, _neon(Color(1.0, 0.12, 0.2), 2.0), false)

# ------------------------------------------------------------------- estación

func _montar_estacion() -> void:
	for pl in mesa.plataformas:
		var bloque := _st()
		M.prisma(bloque, pl.poligono, 0.0, H_ALTA, ACERO, Color(0.06, 0.045, 0.11))
		_malla(bloque, _mat_pintado)
		var canto := _st()
		var n := pl.poligono.size()
		for i in n:
			var a := pl.poligono[i]
			var b := pl.poligono[(i + 1) % n]
			M.estadio(canto, a, b, 1.0, H_ALTA - 0.004, H_ALTA + 0.01, 0.003,
				MAGENTA, MAGENTA, 2)
			# Tiras de luz en el faldón, a media altura.
			M.estadio(canto, a, b, 0.7, H_ALTA * 0.45, H_ALTA * 0.45 + 0.012,
				0.003, MAGENTA, MAGENTA, 2)
		_malla(canto, _neon(MAGENTA, 1.4), false)
		var centro := Vector2.ZERO
		for pt in pl.poligono:
			centro += pt
		centro /= float(n)
		_luz(M.a3(centro, H_ALTA + 0.6), MAGENTA, 0.9, 2.2)

# -------------------------------------------------------- lo pintado en el vidrio

func _montar_pintura() -> void:
	var ambar := _st()
	var cian := _st()
	var c_sol := Vector2(160.0, 742.0)
	M.anillo(ambar, c_sol, 64.0, 66.0, 0.004, AMBAR, 64)
	M.anillo(ambar, c_sol, 73.0, 74.0, 0.004, AMBAR, 64)
	for centro in mesa.bumpers:
		M.anillo(ambar, centro, mesa.p.bumper_radio + 3.0,
			mesa.p.bumper_radio + 5.0, 0.005, AMBAR, 32)
	# Las tres luces de los carriles de arriba.
	for x in [100.0, 160.0, 216.0]:
		M.disco(cian, Vector2(x, 650.0), 4.5, 0.004, CIAN, 14)
		M.anillo(cian, Vector2(x, 650.0), 7.0, 8.0, 0.004, CIAN, 20)
	# Una marca delante de cada inlane.
	for x in [70.0, 322.0]:
		M.disco(cian, Vector2(x, 1070.0), 3.5, 0.004, CIAN, 12)
	# El emblema del centro: un sistema solar dibujado, con sus planetas. Llena
	# el hueco entre los slingshots, que es por donde más se mira.
	var violeta := _st()
	var c_emb := Vector2(214.0, 1018.0)
	M.disco(ambar, c_emb, 6.5, 0.004, AMBAR, 20)
	var planetas := [[18.0, 0.6, cian], [31.0, 2.5, ambar], [45.0, 4.1, cian],
		[59.0, 5.4, violeta]]
	for pl in planetas:
		var radio: float = pl[0]
		var ang: float = pl[1]
		M.anillo(violeta, c_emb, radio - 0.6, radio + 0.6, 0.004, VIOLETA, 56)
		M.disco(pl[2], c_emb + Vector2(cos(ang), sin(ang)) * radio, 3.4, 0.005,
			Color.WHITE, 14)
	_malla(ambar, _neon(AMBAR, 1.3), false)
	_malla(cian, _neon(CIAN, 1.3), false)
	_malla(violeta, _neon(VIOLETA, 0.9), false)

# ------------------------------------------------------------------ recorridos

func altura_rampa(r: Rampa, d: float) -> float:
	var t := clampf(d / maxf(r.largo, 1.0), 0.0, 1.0)
	var base := lerpf(_altura_capa(r.capa_entrada), _altura_capa(r.capa_salida),
		smoothstep(0.0, 1.0, t))
	var subida := smoothstep(0.0, 70.0, d) * smoothstep(0.0, 70.0, r.largo - d)
	if r.subterranea:
		return base + H_TUNEL * subida
	var info: Dictionary = mesa.info_rampas.get(r.nombre, {})
	return base + float(info.get("lomo", 0.4)) * subida

func _altura_capa(capa: int) -> float:
	if capa >= Mesa.CAPA_ALTA:
		return H_ALTA
	if capa <= Mesa.CAPA_TUNEL:
		return H_TUNEL
	return 0.0

func _color_recorrido(nombre: String) -> Color:
	match nombre:
		"orbita":
			return VIOLETA
		"cometa":
			return CIAN
		"estacion", "bajada":
			return MAGENTA
		"gusano":
			return CIAN
	return BLANCO

func _cinta_de_luz(pts: PackedVector3Array, ancho: float, col: Color,
		energia: float, velocidad: float, clave: String) -> void:
	var st := _st()
	M.cinta(st, pts, ancho)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://prueba3d/flujo.gdshader")
	mat.set_shader_parameter("color", col)
	mat.set_shader_parameter("energia", energia)
	mat.set_shader_parameter("velocidad", velocidad)
	_malla(st, mat, false)
	if clave != "":
		if not _cintas.has(clave):
			_cintas[clave] = []
		(_cintas[clave] as Array).append({"mat": mat, "impulso": 0.0})

func _montar_recorridos() -> void:
	var cromo := _st()
	var hay_cromo := false
	for r in mesa.rampas:
		var col := _color_recorrido(r.nombre)
		var n := r.puntos.size()
		var info: Dictionary = mesa.info_rampas.get(r.nombre, {})
		var lomo := float(info.get("lomo", 0.4))

		if r.subterranea:
			_portal(r.nombre + "_a", r.puntos[0], 0.0,
				Color(0.04, 0.30, 1.0), Color(0.45, 1.0, 1.0), 1.0)
			_portal(r.nombre + "_b", r.puntos[n - 1], 0.0,
				Color(0.55, 0.10, 1.0), Color(1.0, 0.55, 0.95), -1.0)
			_flecha_de_boca(r, col, r.nombre)
			continue

		# La línea 3D del recorrido, con su altura.
		var eje := PackedVector3Array()
		var perps: Array[Vector2] = []
		var alturas := PackedFloat32Array()
		var d := 0.0
		for j in n:
			if j > 0:
				d += r.puntos[j - 1].distance_to(r.puntos[j])
			var h := altura_rampa(r, d)
			var tg := (r.puntos[mini(j + 1, n - 1)] - r.puntos[maxi(j - 1, 0)]).normalized()
			perps.append(Vector2(-tg.y, tg.x))
			alturas.append(h)
			eje.append(M.a3(r.puntos[j], h + 0.008))

		if lomo <= 0.001 and r.capa_entrada == r.capa_salida:
			# A ras de tablero: un carril de luz pintado en el cristal.
			_cinta_de_luz(eje, 0.26, col, 1.1, 2.4, r.nombre)
		else:
			# Por el aire: cuatro raíles de cromo y la luz corriendo por dentro.
			var bajo_i := PackedVector3Array()
			var bajo_d := PackedVector3Array()
			var alto_i := PackedVector3Array()
			var alto_d := PackedVector3Array()
			var ultimo_apoyo := -999.0
			d = 0.0
			for j in n:
				if j > 0:
					d += r.puntos[j - 1].distance_to(r.puntos[j])
				var pt := r.puntos[j]
				var perp := perps[j]
				var h := alturas[j]
				bajo_i.append(M.a3(pt - perp * 5.0, h + 0.010))
				bajo_d.append(M.a3(pt + perp * 5.0, h + 0.010))
				alto_i.append(M.a3(pt - perp * 11.0, h + _r_bola * 1.15))
				alto_d.append(M.a3(pt + perp * 11.0, h + _r_bola * 1.15))
				if h > 0.2 and d - ultimo_apoyo > 110.0:
					ultimo_apoyo = d
					M.tubo(cromo, PackedVector3Array([
						alto_i[j], bajo_i[j], bajo_d[j], alto_d[j]]), 0.007, BLANCO, 4)
					# Un pie hasta el suelo, salvo que caiga encima de la estación.
					if not mesa.estacion.contiene(pt):
						var pie: Vector2 = pt + perp * 11.0
						M.estadio(cromo, pie, pie, 1.0, 0.0, h + _r_bola * 1.15,
							0.004, BLANCO, BLANCO, 3)
			for linea in [bajo_i, bajo_d, alto_i, alto_d]:
				M.tubo(cromo, linea, 0.010, BLANCO, 5)
			hay_cromo = true
			var fuerza := 1.2 if r.nombre != "lanzadera" and r.nombre != "bajada" else 0.5
			_cinta_de_luz(eje, 0.13, col, fuerza, 2.8, r.nombre)

		if r.velocidad_minima < 100000.0 and r.nombre != "lanzadera" \
				and r.nombre != "bajada":
			_flecha_de_boca(r, col, r.nombre)
	if hay_cromo:
		_malla(cromo, _mat_cromo)

## La pista de luz que lleva a una boca: es la flecha de una máquina de verdad,
## pero corriendo.
func _flecha_de_boca(r: Rampa, col: Color, clave: String) -> void:
	var boca := r.puntos[0]
	var fuera := -r.tangente_en(0.0)
	var pts := PackedVector3Array()
	for k in 5:
		pts.append(M.a3(boca + fuera * (62.0 - 12.0 * float(k)), 0.007))
	_cinta_de_luz(pts, 0.20, col, 1.3, 3.2, clave)

func _portal(clave: String, centro: Vector2, altura: float, col_a: Color,
		col_b: Color, giro: float) -> void:
	var plano := PlaneMesh.new()
	plano.size = Vector2(0.38, 0.38)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://prueba3d/portal.gdshader")
	mat.set_shader_parameter("color_a", col_a)
	mat.set_shader_parameter("color_b", col_b)
	mat.set_shader_parameter("giro", giro)
	var mi := MeshInstance3D.new()
	mi.mesh = plano
	mi.material_override = mat
	mi.position = M.a3(centro, altura + 0.009)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var luz := _luz(M.a3(centro, altura + 0.25), col_b, 0.7, 1.2)
	_portales[clave] = {"mat": mat, "luz": luz, "activo": 0.0}

# ------------------------------------------------------------------------ soles

func _montar_soles() -> void:
	var bases := _st()
	for i in mesa.bumpers.size():
		var centro: Vector2 = mesa.bumpers[i]
		var radio := mesa.p.bumper_radio
		M.estadio(bases, centro, centro, radio, 0.0, 0.075, 0.025,
			ACERO, ACERO_CLARO, 12)
		M.estadio(bases, centro, centro, radio * 0.6, 0.075, 0.10, 0.01,
			ACERO_CLARO, ACERO_CLARO, 10)
		var esfera := SphereMesh.new()
		esfera.radius = radio * E * 0.84
		esfera.height = esfera.radius * 2.0
		esfera.radial_segments = 28
		esfera.rings = 14
		var mat := ShaderMaterial.new()
		mat.shader = load("res://prueba3d/plasma.gdshader")
		mat.set_shader_parameter("fase", float(i) * 3.7)
		var sol := MeshInstance3D.new()
		sol.mesh = esfera
		sol.material_override = mat
		sol.position = M.a3(centro, 0.17)
		sol.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(sol)
		# El anillo que lo rodea: baja de golpe al recibir la bola.
		var toro := TorusMesh.new()
		toro.inner_radius = radio * E * 1.02
		toro.outer_radius = radio * E * 1.14
		toro.rings = 32
		toro.ring_segments = 8
		var mat_aro := _neon(AMBAR, 2.2)
		var aro := MeshInstance3D.new()
		aro.mesh = toro
		aro.material_override = mat_aro
		aro.position = M.a3(centro, 0.30)
		aro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(aro)
		var luz := _luz(M.a3(centro, 0.46), AMBAR, 1.0, 1.9)
		_soles.append({"centro": centro, "mat": mat, "sol": sol, "aro": aro,
			"mat_aro": mat_aro, "luz": luz, "flash": 0.0})
	_malla(bases, _mat_pintado)

func _al_golpear_sol(punto: Vector2, fuerza: float) -> void:
	var mejor := -1
	var dist := INF
	for i in _soles.size():
		var d: float = (_soles[i]["centro"] as Vector2).distance_squared_to(punto)
		if d < dist:
			dist = d
			mejor = i
	if mejor < 0:
		return
	_soles[mejor]["flash"] = 1.0
	_latido = 1.0
	_chispear(punto, 0.10, AMBAR, 12)
	_onda(_soles[mejor]["centro"], 0.02, AMBAR, 0.75)
	sacudida = maxf(sacudida, clampf(fuerza / 900.0, 0.35, 1.0))

# ----------------------------------------------------------------- slingshots

func _montar_slingshots() -> void:
	var postes := _st()
	var hay := false
	for c in mesa.colisionadores:
		if c.tipo != Colisionador.Tipo.SLINGSHOT:
			continue
		hay = true
		var st := _st()
		M.estadio(st, c.a, c.b, 3.0, 0.04, 0.135, 0.03, MAGENTA, MAGENTA, 4)
		var mat := _neon(MAGENTA, 1.3)
		_malla(st, mat)
		M.estadio(postes, c.a, c.a, 4.2, 0.0, 0.19, 0.015, BLANCO, BLANCO, 6)
		M.estadio(postes, c.b, c.b, 4.2, 0.0, 0.19, 0.015, BLANCO, BLANCO, 6)
		_slings.append({"centro": c.centro(), "mat": mat, "flash": 0.0})
	if hay:
		_malla(postes, _mat_cromo)

func _al_golpear_slingshot(punto: Vector2, _fuerza: float) -> void:
	var mejor := -1
	var dist := INF
	for i in _slings.size():
		var d: float = (_slings[i]["centro"] as Vector2).distance_squared_to(punto)
		if d < dist:
			dist = d
			mejor = i
	if mejor >= 0:
		_slings[mejor]["flash"] = 1.0
	_chispear(punto, 0.09, MAGENTA, 8)
	sacudida = maxf(sacudida, 0.4)

func _montar_postes() -> void:
	if mesa.postes.is_empty():
		return
	var vastagos := _st()
	var aros := _st()
	for centro in mesa.postes:
		M.estadio(vastagos, centro, centro, mesa.p.poste_radio * 0.5, 0.0, 0.20,
			0.015, BLANCO, BLANCO, 8)
		M.estadio(aros, centro, centro, mesa.p.poste_radio, 0.05, 0.115, 0.02,
			MAGENTA, MAGENTA, 10)
	_malla(vastagos, _mat_cromo)
	_malla(aros, _neon(MAGENTA, 1.1))

func _al_golpear_poste(punto: Vector2, _fuerza: float) -> void:
	_chispear(punto, 0.09, MAGENTA, 4)

# -------------------------------------------------------------------- satélites

func _montar_targets() -> void:
	if mesa.targets.is_empty():
		return
	var mat := _neon(CIAN, 0.8)
	var medio := Vector2.ZERO
	for c in mesa.targets:
		var st := _st()
		M.estadio(st, c.a, c.b, c.radio, 0.0, 0.19, 0.02, CIAN, CIAN, 4)
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = mat
		add_child(mi)
		_targets.append(mi)
		medio += c.centro()
	medio /= float(mesa.targets.size())
	_luz(M.a3(medio + Vector2(0.0, 26.0), 0.3), CIAN, 0.8, 1.4)

func _al_abatir(punto: Vector2, _banco: int) -> void:
	_chispear(punto, 0.1, CIAN, 10)
	_onda(punto, 0.02, CIAN, 0.4)

# -------------------------------------------------------------------- las palas

func _montar_flippers() -> void:
	for f in mesa.flippers:
		var arriba := f.capas == Colisionador.bit(Mesa.CAPA_ALTA)
		var col: Color = MAGENTA if arriba else CIAN
		var punta := Vector2(f.longitud, 0.0)
		var cuerpo := _st()
		# El cuerpo, claro y pulido, y alrededor la goma: esa es la que mide
		# EXACTAMENTE lo que el colisionador, porque es lo que toca la bola.
		M.estadio(cuerpo, Vector2.ZERO, punta, f.radio - 1.3, 0.02, 0.155, 0.03,
			Color(0.62, 0.66, 0.74), Color(0.90, 0.93, 0.98), 7)
		M.estadio(cuerpo, Vector2.ZERO, punta, f.radio, 0.05, 0.115, 0.02,
			GOMA, GOMA, 7)
		M.estadio(cuerpo, Vector2.ZERO, Vector2.ZERO, f.radio * 0.5, 0.0, 0.175,
			0.012, ACERO_CLARO, ACERO_CLARO, 8)
		var linea := _st()
		M.estadio(linea, Vector2(7.0, 0.0), Vector2(f.longitud - 5.0, 0.0), 1.5,
			0.155, 0.163, 0.003, col, col, 3)
		var raiz := Node3D.new()
		raiz.position = M.a3(f.eje, H_ALTA if arriba else 0.0)
		add_child(raiz)
		var mi := MeshInstance3D.new()
		mi.mesh = cuerpo.commit()
		mi.material_override = _mat_pintado
		raiz.add_child(mi)
		var ml := MeshInstance3D.new()
		ml.mesh = linea.commit()
		ml.material_override = _neon(col, 1.5)
		ml.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(ml)
		_flippers.append(raiz)

# ---------------------------------------------------------------------- púlsar

func _montar_giradores() -> void:
	if mesa.giradores.is_empty():
		return
	var postes := _st()
	for centro in mesa.giradores:
		var radio := mesa.p.girador_radio
		for s in [-1.0, 1.0]:
			var pie: Vector2 = centro + Vector2((radio + 2.0) * s, 0.0)
			M.estadio(postes, pie, pie, 1.3, 0.0, 0.24, 0.006, BLANCO, BLANCO, 4)
		var chapa := BoxMesh.new()
		chapa.size = Vector3(radio * 2.0 * E, 0.15, 0.014)
		var mat := _neon(VIOLETA, 0.6)
		mat.albedo_color = Color(0.5, 0.5, 0.6)
		mat.metallic = 1.0
		mat.roughness = 0.25
		var mi := MeshInstance3D.new()
		mi.mesh = chapa
		mi.material_override = mat
		mi.position = M.a3(centro, 0.14)
		add_child(mi)
		_giradores.append({"nodo": mi, "mat": mat, "vel": 0.0})
	_malla(postes, _mat_cromo)

func _al_girar(_punto: Vector2, indice: int, fuerza: float) -> void:
	if indice >= 0 and indice < _giradores.size():
		_giradores[indice]["vel"] = clampf(fuerza * 0.06, 14.0, 70.0)

# --------------------------------------------------------------- agujero negro

func _montar_platillos() -> void:
	for i in mesa.platillos.size():
		var pl := mesa.platillos[i]
		var altura := H_ALTA if mesa.estacion.contiene(pl.centro) else 0.0
		var clave := "platillo_%d" % i
		_portal(clave, pl.centro, altura,
			Color(1.0, 0.30, 0.04), Color(0.80, 0.45, 1.0), 1.5)
		_platillos.append({"clave": clave, "altura": altura})

func _al_capturar(_punto: Vector2, indice: int) -> void:
	if indice < _platillos.size():
		_portales[_platillos[indice]["clave"]]["activo"] = 1.0
	_latido = 1.0
	sacudida = maxf(sacudida, 0.6)

func _al_expulsar(punto: Vector2, indice: int) -> void:
	var altura: float = _platillos[indice]["altura"] if indice < _platillos.size() else 0.0
	_onda(punto, altura + 0.02, VIOLETA, 0.6)
	_chispear(punto, altura + 0.1, VIOLETA, 12)

func _al_entrar_rampa(punto: Vector2, indice: int) -> void:
	var r := mesa.rampas[indice]
	for cinta in _cintas.get(r.nombre, []):
		cinta["impulso"] = 1.0
	if r.subterranea:
		_portales[r.nombre + "_a"]["activo"] = 1.0
		_onda(punto, 0.02, CIAN, 0.5)

func _al_salir_rampa(punto: Vector2, indice: int) -> void:
	var r := mesa.rampas[indice]
	if r.subterranea:
		_portales[r.nombre + "_b"]["activo"] = 1.0
		_onda(punto, 0.02, MAGENTA, 0.5)
		_chispear(punto, 0.1, MAGENTA, 10)

# -------------------------------------------------------------------- lanzador

func _montar_lanzador() -> void:
	var vastago := CylinderMesh.new()
	vastago.top_radius = 0.04
	vastago.bottom_radius = 0.04
	vastago.height = 0.5
	var mi := MeshInstance3D.new()
	mi.mesh = vastago
	mi.material_override = _mat_cromo
	mi.rotation_degrees.x = 90.0
	_lanzador_z = (mesa.p.inicio_bola.y + mesa.p.radio_bola + 3.0) * E + 0.25
	mi.position = Vector3(mesa.p.inicio_bola.x * E, _r_bola, _lanzador_z)
	add_child(mi)
	_lanzador = mi

# --------------------------------------------------------------------- rótulos

func _montar_rotulos() -> void:
	_rotulo("S O L", Vector2(160, 800), AMBAR, 0.0, 44)
	_rotulo("SATÉLITES", Vector2(160, 862), CIAN, 0.0, 30)
	_rotulo("ÓRBITA", Vector2(74, 1000), VIOLETA, 90.0, 34)
	_rotulo("COMETA", Vector2(128, 930), CIAN, 0.0, 30)
	_rotulo("ESTACIÓN", Vector2(238, 938), MAGENTA, 0.0, 30)
	_rotulo("GUSANO", Vector2(292, 1002), CIAN, 0.0, 28)

func _rotulo(texto: String, donde: Vector2, col: Color, giro: float, cuerpo: int) -> void:
	var l := Label3D.new()
	l.text = texto
	l.font = _fuente
	l.font_size = cuerpo
	l.pixel_size = 0.003
	l.modulate = col
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	l.position = M.a3(donde, 0.006)
	l.rotation_degrees = Vector3(-90.0, giro, 0.0)
	add_child(l)

# ----------------------------------------------------------------------- bolas

func _montar_bolas() -> void:
	var esfera := SphereMesh.new()
	esfera.radius = _r_bola
	esfera.height = _r_bola * 2.0
	esfera.radial_segments = 32
	esfera.rings = 16
	for _i in maxi(mesa.p.bolas_maximas, 1):
		# Un material POR BOLA: la que lleva una criatura dentro se tiñe de su
		# color, y con uno compartido se teñirían todas.
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.95, 0.97, 1.0)
		mat.metallic = 0.92
		mat.roughness = 0.10
		# Un punto de luz propia: sobre un cielo casi negro, un cromo perfecto
		# refleja negro y la bola —que es lo único que hay que no perder de
		# vista— se pierde.
		mat.emission_enabled = true
		mat.emission = COLOR_BOLA
		mat.emission_energy_multiplier = 0.45
		_mats_bola.append(mat)
		_bola_del_hueco.append(null)
		var mi := MeshInstance3D.new()
		mi.mesh = esfera
		mi.material_override = mat
		mi.visible = false
		add_child(mi)
		_bolas.append(mi)
		var luz := _luz(Vector3.ZERO, Color(0.75, 0.9, 1.0), 0.7, 1.3)
		luz.visible = false
		_luces_bola.append(luz)

	_malla_estela = ImmediateMesh.new()
	_mat_estela = StandardMaterial3D.new()
	_mat_estela.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_estela.vertex_color_use_as_albedo = true
	_mat_estela.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_estela.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat_estela.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi_estela := MeshInstance3D.new()
	mi_estela.mesh = _malla_estela
	mi_estela.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi_estela)

func _altura_bola(b: Bola) -> float:
	if b.rampa >= 0:
		return altura_rampa(mesa.rampas[b.rampa], b.rampa_distancia) + _r_bola
	if b.platillo >= 0 and b.platillo < _platillos.size():
		return float(_platillos[b.platillo]["altura"]) + _r_bola * 0.35
	return _altura_capa(b.capa) + _r_bola

func posicion_bola(b: Bola) -> Vector3:
	return M.a3(b.pos, float(_y_bola.get(b, _r_bola)))

func _al_caer(punto: Vector2, _desde: int, _hasta: int) -> void:
	_chispear(punto, 0.05, BLANCO, 6)

# ------------------------------------------------------------ chispas y ondas

func _montar_chispas() -> void:
	var cubo := BoxMesh.new()
	cubo.size = Vector3(0.03, 0.03, 0.03)
	for _i in 10:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = BLANCO
		var ch := CPUParticles3D.new()
		ch.emitting = false
		ch.one_shot = true
		ch.amount = 12
		ch.lifetime = 0.5
		ch.explosiveness = 1.0
		ch.direction = Vector3.UP
		ch.spread = 75.0
		ch.initial_velocity_min = 1.0
		ch.initial_velocity_max = 3.2
		ch.gravity = Vector3(0.0, -8.0, 0.0)
		ch.scale_amount_min = 0.4
		ch.scale_amount_max = 1.1
		ch.mesh = cubo
		ch.material_override = mat
		ch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ch)
		_chispas.append(ch)

func _chispear(punto: Vector2, altura: float, col: Color, cuantas: int) -> void:
	var ch := _chispas[_chispa_siguiente]
	_chispa_siguiente = (_chispa_siguiente + 1) % _chispas.size()
	var c := col.lightened(0.35)
	(ch.material_override as StandardMaterial3D).albedo_color = Color(c.r * 2.5, c.g * 2.5, c.b * 2.5)
	ch.amount = cuantas
	ch.position = M.a3(punto, altura)
	ch.restart()
	ch.emitting = true

## Ondas de choque: un aro que se abre sobre el cristal y se apaga.
func _montar_ondas() -> void:
	for _i in 8:
		var st := _st()
		M.anillo(st, Vector2.ZERO, 92.0, 100.0, 0.0, Color.WHITE, 48)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var mi := _malla(st, mat, false)
		mi.visible = false
		_ondas.append({"nodo": mi, "mat": mat, "t": 1.0, "col": Color.WHITE,
			"radio": 0.5})

func _onda(punto: Vector2, altura: float, col: Color, radio: float) -> void:
	var o: Dictionary = _ondas[_onda_siguiente]
	_onda_siguiente = (_onda_siguiente + 1) % _ondas.size()
	o["t"] = 0.0
	o["col"] = col
	o["radio"] = radio
	(o["nodo"] as MeshInstance3D).position = M.a3(punto, altura)
	(o["nodo"] as MeshInstance3D).visible = true

## Motas de polvo flotando sobre la mesa. No hacen nada, y son lo que hace que
## el aire entre la cámara y el cristal exista.
func _montar_polvo() -> void:
	var mota := QuadMesh.new()
	mota.size = Vector2(0.022, 0.022)
	# Una mota redonda y blanda: un degradado radial hecho aquí mismo.
	var degradado := Gradient.new()
	degradado.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	degradado.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var redonda := GradientTexture2D.new()
	redonda.gradient = degradado
	redonda.fill = GradientTexture2D.FILL_RADIAL
	redonda.fill_from = Vector2(0.5, 0.5)
	redonda.fill_to = Vector2(1.0, 0.5)
	redonda.width = 32
	redonda.height = 32
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(0.5, 0.75, 1.0, 0.5)
	mat.albedo_texture = redonda
	var polvo := CPUParticles3D.new()
	polvo.amount = 150
	polvo.lifetime = 9.0
	polvo.preprocess = 9.0
	polvo.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	polvo.emission_box_extents = Vector3(2.6, 0.7, 4.2)
	polvo.direction = Vector3(0.3, 1.0, 0.1)
	polvo.spread = 60.0
	polvo.initial_velocity_min = 0.02
	polvo.initial_velocity_max = 0.10
	polvo.gravity = Vector3.ZERO
	polvo.scale_amount_min = 0.4
	polvo.scale_amount_max = 1.4
	polvo.mesh = mota
	polvo.material_override = mat
	polvo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	polvo.position = Vector3(2.0, 1.0, 9.3)
	add_child(polvo)

# ---------------------------------------------------------------- cada cuadro

func actualizar(delta: float) -> void:
	_tiempo += delta
	# Al tercer cuadro la nebulosa ya está pintada: tocarle un mando al cielo es
	# lo que le dice al motor que rehaga el mapa de reflejos del cromo, que el
	# primero lo hizo con la textura todavía en negro.
	if _cuadros < 3:
		_cuadros += 1
		if _cuadros == 3:
			_mat_cielo.set_shader_parameter("horneada", 1.0)
	sacudida = maxf(sacudida - delta * 4.0, 0.0)
	_latido = maxf(_latido - delta * 2.5, 0.0)
	mat_suelo.set_shader_parameter("latido", _latido)

	# Qué bola lleva a quién dentro, para teñirla.
	_tinte.clear()
	if caza != null:
		for i in _bichos.size():
			var c: Criatura = caza.criaturas[i]
			if c.estado == Criatura.Estado.EN_BOLA and c.portadora != null:
				_tinte[c.portadora] = (_bichos[i] as Cuerpo).color()

	# Bolas. La altura no la sabe la simulación —para ella la mesa es plana y la
	# capa es un entero—, así que aquí se le da cuerpo: sube pegada al raíl y
	# CAE con peso cuando se queda sin suelo.
	var vivas := {}
	for i in _bolas.size():
		var hay := i < mesa.bolas.size() and mesa.bolas[i].viva
		if not hay:
			_bolas[i].visible = false
			_luces_bola[i].visible = false
			_bola_del_hueco[i] = null
			continue
		var b := mesa.bolas[i]
		vivas[b] = true
		var destino := _altura_bola(b)
		var y: float = _y_bola.get(b, destino)
		if destino < y:
			y = maxf(destino, y - 2.8 * delta)
		else:
			y = minf(destino, y + 6.0 * delta)
		_y_bola[b] = y
		var pos := M.a3(b.pos, y)
		var a_la_vista := y > -0.03
		_bolas[i].position = pos
		_bolas[i].visible = a_la_vista
		_luces_bola[i].position = pos + Vector3(0.0, 0.2, 0.0)
		_luces_bola[i].visible = a_la_vista
		# Con una criatura dentro, la bola es de su color y brilla más: a este
		# tamaño es lo único que se lee, y basta.
		var lleva: bool = _tinte.has(b)
		var color_bola: Color = _tinte[b] if lleva else COLOR_BOLA
		var mat_bola := _mats_bola[i]
		var energia: float = (1.9 + 0.5 * sin(_tiempo * 9.0)) if lleva else 0.45
		var k := 1.0 - exp(-10.0 * delta)
		# Si el hueco ha cambiado de bola, o la bola acaba de servirse, el color
		# se fija de golpe: fundiéndolo, durante un tercio de segundo brillaba
		# del color de la criatura la bola que NO la llevaba.
		if _bola_del_hueco[i] != b or b.en_carril:
			k = 1.0
		_bola_del_hueco[i] = b
		mat_bola.emission = mat_bola.emission.lerp(color_bola, k)
		mat_bola.emission_energy_multiplier = lerpf(
			mat_bola.emission_energy_multiplier, energia, k)
		_luces_bola[i].light_color = Color(0.75, 0.9, 1.0).lerp(color_bola, 0.8 if lleva else 0.0)
		# La estela: los últimos puntos por los que ha pasado.
		var rastro: Array = _rastro.get(b, [])
		if not a_la_vista or (not rastro.is_empty() \
				and (rastro[0] as Vector3).distance_to(pos) > 0.7):
			rastro.clear()
		if a_la_vista:
			rastro.push_front(pos)
		if rastro.size() > 16:
			rastro.resize(16)
		_rastro[b] = rastro
	for b in _y_bola.keys():
		if not vivas.has(b):
			_y_bola.erase(b)
			_rastro.erase(b)
	_dibujar_estelas()

	for i in _flippers.size():
		_flippers[i].rotation.y = -mesa.flippers[i].angulo

	for i in _targets.size():
		var abajo := -0.185 if not mesa.targets[i].activo else 0.0
		_targets[i].position.y = move_toward(_targets[i].position.y, abajo, delta * 2.6)

	for s in _soles:
		var f: float = maxf(float(s["flash"]) - delta * 4.5, 0.0)
		s["flash"] = f
		(s["mat"] as ShaderMaterial).set_shader_parameter("destello", f)
		(s["luz"] as OmniLight3D).light_energy = 1.0 + f * 5.0
		(s["aro"] as MeshInstance3D).position.y = 0.30 - 0.11 * f
		var escala := 1.0 + 0.16 * f
		(s["aro"] as MeshInstance3D).scale = Vector3(escala, 1.0, escala)
		(s["sol"] as MeshInstance3D).scale = Vector3.ONE * (1.0 + 0.10 * f)
		(s["mat_aro"] as StandardMaterial3D).emission_energy_multiplier = 2.2 + f * 6.0

	for sl in _slings:
		var f: float = maxf(float(sl["flash"]) - delta * 6.0, 0.0)
		sl["flash"] = f
		(sl["mat"] as StandardMaterial3D).emission_energy_multiplier = 1.3 + f * 7.0

	for gi in _giradores:
		var v: float = gi["vel"]
		(gi["nodo"] as MeshInstance3D).rotation.x += v * delta
		gi["vel"] = v * exp(-1.5 * delta)
		(gi["mat"] as StandardMaterial3D).emission_energy_multiplier = \
			0.6 + minf(v * 0.12, 5.0)

	for clave in _portales:
		var pt: Dictionary = _portales[clave]
		var a: float = maxf(float(pt["activo"]) - delta * 1.2, 0.0)
		pt["activo"] = a
		(pt["mat"] as ShaderMaterial).set_shader_parameter("activo", a)
		(pt["luz"] as OmniLight3D).light_energy = 0.7 + a * 3.5

	for clave in _cintas:
		for cinta in _cintas[clave]:
			var k: float = maxf(float(cinta["impulso"]) - delta * 1.6, 0.0)
			cinta["impulso"] = k
			(cinta["mat"] as ShaderMaterial).set_shader_parameter("impulso", k)

	for o in _ondas:
		var t: float = o["t"]
		if t >= 1.0:
			continue
		t = minf(t + delta * 2.6, 1.0)
		o["t"] = t
		var nodo: MeshInstance3D = o["nodo"]
		var r: float = float(o["radio"]) * (0.15 + 0.85 * (1.0 - pow(1.0 - t, 3.0)))
		nodo.scale = Vector3(r, 1.0, r)
		var col: Color = o["col"]
		var alfa := (1.0 - t) * (1.0 - t)
		(o["mat"] as StandardMaterial3D).albedo_color = Color(col.r * 2.5, col.g * 2.5, col.b * 2.5, alfa)
		nodo.visible = t < 1.0

	_lanzador.position.z = _lanzador_z + mesa.carga_lanzador * 0.22
	_actualizar_caza(delta)

func _dibujar_estelas() -> void:
	_malla_estela.clear_surfaces()
	for b in _rastro:
		var rastro: Array = _rastro[b]
		var n := rastro.size()
		if n < 3:
			continue
		var fuerza := clampf((b as Bola).velocidad() / 700.0, 0.0, 1.0)
		if (b as Bola).rampa >= 0:
			fuerza = maxf(fuerza, 0.7)
		if fuerza < 0.08:
			continue
		_malla_estela.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _mat_estela)
		for i in n:
			var p0: Vector3 = rastro[i]
			var p1: Vector3 = rastro[mini(i + 1, n - 1)]
			var pm: Vector3 = rastro[maxi(i - 1, 0)]
			var lateral := (pm - p1).cross(Vector3.UP)
			if lateral.length_squared() < 1e-8:
				lateral = Vector3.RIGHT
			var k := 1.0 - float(i) / float(n - 1)
			lateral = lateral.normalized() * _r_bola * 0.85 * k
			var base: Color = _tinte[b] if _tinte.has(b) else Color(0.35, 0.85, 1.0)
			var col := Color(base.r, base.g, base.b, 0.55 * k * k * fuerza)
			_malla_estela.surface_set_color(col)
			_malla_estela.surface_add_vertex(p0 - lateral)
			_malla_estela.surface_set_color(col)
			_malla_estela.surface_add_vertex(p0 + lateral)
		_malla_estela.surface_end()

# -------------------------------------------------------------------- la caza

## Pone en la mesa los cuerpos de las criaturas de una caza y escucha lo que les
## pasa, para darle chispa. La caza decide; esto solo lo enseña.
func montar_caza(la_caza: Caza) -> void:
	caza = la_caza
	for c in caza.criaturas:
		var cuerpo := Cuerpo.new()
		cuerpo.t_cierre = caza.t_cierre
		cuerpo.t_volcada = caza.t_volcada
		cuerpo.arco_blindaje = caza.arco_blindaje
		add_child(cuerpo)
		cuerpo.montar(c, _fuente)
		_bichos.append(cuerpo)
	_montar_almas()
	caza.criatura_aparecio.connect(_al_aparecer_criatura)
	caza.criatura_golpeada.connect(_al_golpear_criatura)
	caza.criatura_blindada.connect(_al_blindar_criatura)
	caza.criatura_volcada.connect(_al_volcar_criatura)
	caza.criatura_partida.connect(_al_partir_criatura)
	caza.criatura_reunida.connect(_al_reunir_criatura)
	caza.criatura_acorralada.connect(_al_acorralar_criatura)
	caza.criatura_recogida.connect(_al_recoger_criatura)
	caza.criatura_asegurada.connect(_al_asegurar_criatura)
	caza.criatura_escapada.connect(_al_escapar_criatura)
	caza.criatura_escondida.connect(_al_esconder_criatura)
	caza.criatura_asoma.connect(_al_asomar_criatura)
	caza.criatura_expulsada.connect(_al_expulsar_criatura)
	caza.criatura_rescatada.connect(_al_rescatar_criatura)
	caza.boca_tapada.connect(_al_tapar_boca)
	caza.susto_general.connect(_al_susto_general)
	caza.caza_completa.connect(_al_completar_caza)

func _cuerpo_de(c: Criatura) -> Cuerpo:
	return _bichos[c.indice] as Cuerpo

## Dónde está el cuerpo de una criatura, para la cámara. Devuelve false en
## `visible` si ahora mismo no hay nada que mirar.
func posicion_criatura(indice: int) -> Vector3:
	if indice < 0 or indice >= _bichos.size():
		return Vector3.ZERO
	return (_bichos[indice] as Cuerpo).centro()

func _portal_de_boca(boca: int) -> String:
	if caza == null or caza.tunel == null:
		return ""
	return caza.tunel.nombre + ("_a" if boca == 0 else "_b")

func _encender_boca(boca: int) -> void:
	var clave := _portal_de_boca(boca)
	if _portales.has(clave):
		_portales[clave]["activo"] = 1.0

func _al_aparecer_criatura(c: Criatura, punto: Vector2) -> void:
	var col := _cuerpo_de(c).color()
	_onda(punto, 0.02, col, 0.35)
	_chispear(punto, 0.08, col, 8)

func _al_golpear_criatura(c: Criatura, punto: Vector2, fuerza: float,
		normal: Vector2) -> void:
	var cuerpo := _cuerpo_de(c)
	cuerpo.golpear(normal)
	var col := cuerpo.color()
	_chispear(punto, 0.12, col, 14)
	_onda(c.pos, 0.02, col, 0.45)
	sacudida = maxf(sacudida, clampf(fuerza / 1100.0, 0.35, 0.8))

func _al_blindar_criatura(c: Criatura, punto: Vector2, fuerza: float) -> void:
	_cuerpo_de(c).blindar()
	_chispear(punto, 0.12, Color(0.65, 0.88, 1.0), 16)
	_onda(punto, 0.02, BLANCO, 0.28)
	sacudida = maxf(sacudida, clampf(fuerza / 900.0, 0.4, 0.9))

func _al_volcar_criatura(c: Criatura, punto: Vector2) -> void:
	var col := _cuerpo_de(c).color()
	_onda(punto, 0.02, col, 0.55)
	_chispear(punto, 0.10, col, 10)

func _al_partir_criatura(c: Criatura, punto: Vector2) -> void:
	var col := _cuerpo_de(c).color()
	_onda(c.pos, 0.02, col, 0.6)
	_chispear(punto, 0.12, col, 16)

func _al_reunir_criatura(c: Criatura, punto: Vector2) -> void:
	var col := _cuerpo_de(c).color()
	_onda(punto, 0.02, col, 0.5)
	_chispear(punto, 0.10, col, 12)

func _al_acorralar_criatura(c: Criatura) -> void:
	_latido = 1.0
	_onda(c.pos, 0.02, Color(1.0, 0.2, 0.15), 0.6)

func _al_recoger_criatura(c: Criatura, punto: Vector2) -> void:
	var col := _cuerpo_de(c).color()
	_onda(punto, 0.02, col, 0.4)
	if c.portadora != null:
		_soltar_almas(M.a3(c.pos, 0.14), c.portadora, col, 7)

func _al_asegurar_criatura(c: Criatura, punto: Vector2) -> void:
	var col := _cuerpo_de(c).color()
	_onda(punto, 0.02, col, 0.5)
	_chispear(punto, 0.12, col, 12)
	if c.principal:
		# La entera, a salvo: onda doble desde la pala y la mesa late.
		_onda(punto, 0.03, BLANCO, 0.95)
		_chispear(punto, 0.16, BLANCO, 16)
		_latido = 1.0
		sacudida = maxf(sacudida, 0.5)

func _al_escapar_criatura(_c: Criatura, punto: Vector2) -> void:
	_onda(punto, 0.02, Color(0.6, 0.65, 0.75), 0.5)

func _al_esconder_criatura(c: Criatura, punto: Vector2) -> void:
	_encender_boca(c.boca_entrada)
	_onda(punto, 0.02, _cuerpo_de(c).color(), 0.3)

## Medio segundo antes de salir, la boca por la que va a asomar se enciende: es
## el aviso que hace justo esperarla.
func _al_asomar_criatura(_c: Criatura, boca: int) -> void:
	_encender_boca(boca)

func _al_expulsar_criatura(c: Criatura, punto: Vector2) -> void:
	var col := _cuerpo_de(c).color()
	_onda(punto, 0.02, col, 0.5)
	_chispear(punto, 0.10, col, 12)

func _al_rescatar_criatura(c: Criatura, punto: Vector2) -> void:
	_chispear(punto, 0.08, _cuerpo_de(c).color(), 8)

func _al_tapar_boca(_boca: int, punto: Vector2) -> void:
	_onda(punto, 0.02, Color(1.0, 0.25, 0.2), 0.26)

func _al_susto_general(cuanto: float) -> void:
	_latido = maxf(_latido, clampf(cuanto * 4.0, 0.2, 1.0))
	# Y el aro de LUMI parpadea: es lo que ata "le he dado a un sol" con "le ha
	# subido el miedo". Un efecto se enseña donde se mide.
	for i in _bichos.size():
		var c: Criatura = caza.criaturas[i]
		if c.especie == "corredor" and c.activa and c.a_la_vista():
			(_bichos[i] as Cuerpo).avisar_aro()

func _al_completar_caza(_ola: int) -> void:
	_latido = 1.0
	sacudida = maxf(sacudida, 0.6)
	_onda(Vector2(214.0, 1018.0), 0.03, BLANCO, 1.4)
	_onda(Vector2(214.0, 1018.0), 0.03, AMBAR, 0.9)

func _actualizar_caza(delta: float) -> void:
	if caza == null:
		return
	for i in _bichos.size():
		var c: Criatura = caza.criaturas[i]
		var donde := Vector3.ZERO
		if c.estado == Criatura.Estado.EN_BOLA and c.portadora != null:
			donde = posicion_bola(c.portadora)
		(_bichos[i] as Cuerpo).actualizar(delta, donde)
	# Una boca tapada se apaga y se pone roja: por ahí no se esconde nadie.
	for k in caza.bocas.size():
		var clave := _portal_de_boca(k)
		if not _portales.has(clave):
			continue
		var pt: Dictionary = _portales[clave]
		var meta := 1.0 if caza.boca_cierre[k] > 0.0 else 0.0
		var ahora := lerpf(float(pt.get("tapada", 0.0)), meta, 1.0 - exp(-12.0 * delta))
		pt["tapada"] = ahora
		(pt["mat"] as ShaderMaterial).set_shader_parameter("tapada", ahora)
	_mover_almas(delta)

## Las "almas": unas motas de luz que van de la criatura a la bola al recogerla.
## Es lo que cuenta, sin una palabra, que ahora va DENTRO.
func _montar_almas() -> void:
	for _i in 21:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var esfera := SphereMesh.new()
		esfera.radius = 0.016
		esfera.height = 0.032
		esfera.radial_segments = 6
		esfera.rings = 3
		var mi := MeshInstance3D.new()
		mi.mesh = esfera
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		_almas.append({"nodo": mi, "mat": mat, "t": 1.0, "espera": 0.0,
			"desde": Vector3.ZERO, "bola": null, "fase": 0.0})

func _soltar_almas(desde: Vector3, bola: Bola, col: Color, cuantas: int) -> void:
	var puestas := 0
	for a in _almas:
		if puestas >= cuantas:
			return
		if float(a["t"]) < 1.0:
			continue
		a["t"] = 0.0
		a["espera"] = 0.035 * float(puestas)
		a["desde"] = desde
		a["bola"] = bola
		a["fase"] = float(puestas) * 2.4
		(a["mat"] as StandardMaterial3D).albedo_color = Color(col.r * 2.6, col.g * 2.6, col.b * 2.6)
		puestas += 1

func _mover_almas(delta: float) -> void:
	for a in _almas:
		var t: float = a["t"]
		var nodo: MeshInstance3D = a["nodo"]
		if t >= 1.0:
			nodo.visible = false
			continue
		var espera: float = a["espera"]
		if espera > 0.0:
			a["espera"] = espera - delta
			continue
		t = minf(t + delta / 0.42, 1.0)
		a["t"] = t
		var bola: Bola = a["bola"]
		var hasta: Vector3 = a["desde"]
		if bola != null and bola.viva:
			hasta = posicion_bola(bola)
		var desde: Vector3 = a["desde"]
		var giro: float = float(a["fase"]) + t * 9.0
		var radio := 0.16 * (1.0 - t)
		nodo.position = desde.lerp(hasta, t * t) + Vector3(cos(giro) * radio,
			0.10 * sin(PI * t), sin(giro) * radio)
		nodo.scale = Vector3.ONE * (1.4 - 0.8 * t)
		nodo.visible = t < 1.0
