extends Node3D

## CRIPTA 3D — el cuerpo del ESPECTRO (`cr_espectro`), que en la caza es la
## especie «corredor», la huidiza. Solo LEE una `criatura.gd` y la pone en
## pantalla; no decide nada. Mismo contrato que `prueba3d/criatura_3d.gd`.
##
## EL PERSONAJE es el del sprite: una masa violeta blanda con TRES OJOS grandes
## —uno arriba y dos abajo— y zarcillos que se rizan a los lados y gotean por
## abajo. Aquí tiene cuerpo:
##
##   · una MASA de gelatina translúcida (`espectro_cuerpo.gdshader`): rugosa y
##     casi sin brillo (no es plástico), el violeta va POR DENTRO, con volutas
##     que suben, el borde se recorta claro y tiembla. Por abajo no se acaba: el
##     último tercio se deshace en hebras y suelta motas sin parar. FLOTA;
##   · TRES OJOS en triángulo, como en el sprite, con la cara levantada hacia la
##     cámara de juego: globos que nacen de un labio de la propia gelatina
##     (`espectro_ojo.gdshader`). Cada uno sigue a la bola a su aire —uno más
##     lento, otro más nervioso— y parpadea a destiempo;
##   · seis JIRONES en cinta (`espectro_zarcillo`), de tamaños distintos, que se
##     curvan en S y se deshacen hacia la punta: dos grandes a los lados (los del
##     sprite), dos menores y dos detrás que van a rastras;
##   · una luz violeta propia, floja, que alumbra la losa: es lo ÚNICO violeta
##     de la mesa. Un espectro no hace sombra: debajo, en vez de sombra, luz;
##   · un rastro tenue de humo violeta cuando se mueve.
##
## NO SE ATRAVIESA A LA VISTA: bajo un raíl se agacha y, a menos de 0,35 de otra
## criatura, su dibujo se aparta y sube, POCO (`APARTE_ESPECTRO`, `SUBE_MAX`; la
## caza no se toca; la cuenta, en `calavera.gd`). `centro()` ya lleva ese
## desplazamiento; el aro de sal, no: marca dónde choca la bola.
##
## El modelo sale de `cripta3d/blender/criatura_espectro.py`, en piezas con
## nombre; dónde caen los ojos y de dónde salen los zarcillos se LEE del GLB.
##
## CÓMO SE MUEVE. Sin huesos ni animaciones grabadas: todo son MUELLES, que es lo
## que hace que una gelatina parezca gelatina (se pasa y vuelve):
##   1. FLOTA deprisa, se inclina hacia donde va y se ESTIRA en esa dirección;
##      al frenar se pasa y se balancea. El faldón y los zarcillos van a rastras.
##   2. LA CARA MIRA AL JUGADOR, con un margen: la cámara de juego mira desde
##      arriba y desde abajo de la mesa, y un espectro de espaldas son tres ojos
##      que no se ven. Hacia dónde VA lo dicen la inclinación y los zarcillos.
##   3. NO TIENE VIDA, TIENE MIEDO (`c.miedo`): cuanto más, más pálido, más
##      tiembla, más abiertos los ojos y más chica la pupila. Y en la losa, el
##      miedo lo va CERCANDO con sal (`espectro_sal.gdshader`).
##   4. LO QUE LE PASA SE VE EN UNA FOTO FIJA:
##        · correr      flota, se mece, los zarcillos rizados
##        · alerta      un respingo hacia arriba, los tres ojos desorbitados, los
##                      zarcillos erizados y un anillo de polvo en la losa
##        · huir        tumbado hacia donde va, estirado, todo a rastras
##        · golpe       se deforma como gelatina, sale girando, cierra los ojos y
##                      salpica gotas
##        · aturdido    desinflado casi en la losa, los ojos a media asta dando
##                      vueltas, los zarcillos colgando y tres fuegos fatuos
##        · acorralado  lo más transparente que se pone, encogido y tiritando,
##                      con los tres ojos desorbitados mirando a la bola y los
##                      jirones grandes cruzados delante de los de abajo, dentro
##                      de un cerco de sal cerrado que se va barriendo: el tiempo
##                      que queda
##        · escondido   no se le ve: solo una luz violeta que corre bajo la losa
##                      y se cuela por las grietas
##        · aparecer    sube del suelo como humo que cuaja
##        · en la bola  se hace una bola con los jirones recogidos y luego se
##                      estira hacia la ranura del cascabel y se cuela

const Criatura := preload("res://prueba3d/criatura.gd")
const MODELO := preload("res://cripta3d/modelos/criatura_espectro.glb")
const SH_CUERPO := preload("res://cripta3d/criaturas/espectro_cuerpo.gdshader")
const SH_ZARCILLO := preload("res://cripta3d/criaturas/espectro_zarcillo.gdshader")
const SH_OJO := preload("res://cripta3d/criaturas/espectro_ojo.gdshader")
const SH_SAL := preload("res://cripta3d/criaturas/espectro_sal.gdshader")
const SH_BRILLO := preload("res://cripta3d/criaturas/espectro_brillo.gdshader")
const SH_HUMO := preload("res://cripta3d/criaturas/espectro_humo.gdshader")
## No atravesarse a la vista (agacharse bajo un raíl, hacerse a un lado): la
## cuenta es la de la calavera, para que los tres cuerpos midan igual.
const Calavera := preload("res://cripta3d/criaturas/calavera.gd")
const E := 0.01
## Lo que sube por cada unidad que se aparta de otra criatura: se quita de en
## medio asustado, hacia arriba. Con la cámara mirando desde lo alto, subir es lo
## que más lo despega de la calavera en la foto.
const SUBE_AL_APARTARSE := 0.85
## PERO POCO (retoque, nov-2026). Con el aparte común (0,16 en planta) y subiendo
## 0,85 por unidad, con la cámara baja el fantasma quedaba pintado lejos de su aro
## de sal, que es donde la bola choca de verdad: el jugador apuntaba al cuerpo y
## fallaba (los tres críticos). Un fantasma que se solapa un poco con otra
## criatura es de fantasma; uno que engaña al apuntar, no. Y el aro (la sal y el
## charco de luz) se queda en el sitio de la caza: no se aparta con el dibujo.
const APARTE_ESPECTRO := 0.10
const SUBE_MAX := 0.10

## Las mismas capas que la mesa: lo pintado en el suelo no sale en el reflejo
## (4) y lo menudo solo se refleja en las cámaras de cerca (8).
const CAPA_SIN_REFLEJO := 4
const CAPA_DETALLE := 8

# --- El tacto: todo lo que es pose está aquí arriba y con nombre ---------------
## Lo que se despega de la losa en reposo, además de lo que ya flota el modelo
## (la punta del goterón más largo está a 3 cm, y se desvanece antes). Se nota
## el hueco desde arriba.
const FLOTE := 0.030
## A qué tamaño se pone el modelo. Con 1,0 medía ~100 px a la distancia de juego
## y se quedaba chico al lado de la bola (crítica del 21-nov-2026: +20-30 %).
## Los shaders trabajan en las unidades del modelo, así que esto no los toca.
const ESCALA := 1.15
## Lo más que la cara se aparta de la cámara, en grados.
const GIRO_MAX := 42.0
## Lo que tarda en colarse por la ranura del cascabel, y qué parte de ese tiempo
## se pasa haciéndose una bola antes del tirón.
const T_COLARSE := 0.34
const RECOGERSE := 0.72
## Lo que tarda en cuajar al aparecer.
const T_CUAJAR := 0.55
## Cuánto se tumba (radianes) y se estira a la carrera, paseando y huyendo.
const INCLINA_CORRER := 0.22
const INCLINA_HUIR := 0.46
const ESTIRA_CORRER := 0.14
const ESTIRA_HUIR := 0.32

## Los jirones: curva de reposo (rizo0, rizo1) por nombre. La punta gira
## rizo0·L + rizo1·L² radianes: se dejan TODOS por debajo de media vuelta. Con
## rizos de 200-250 cerraban un círculo perfecto y eran asas de taza o cuernos
## de carnero. Como en el sprite: el de la derecha sube, el de la izquierda cae.
const RIZOS := {
	# Curvas en S (sube y cae, o al revés), no medias lunas: una media luna fina
	# y en punta, de lejos, sigue siendo un cuerno.
	"zarcillo_i": Vector2(-9.0, 40.0),
	"zarcillo_d": Vector2(13.0, -42.0),
	"zarcillo_i2": Vector2(7.0, -75.0),
	"zarcillo_d2": Vector2(-8.0, 80.0),
	"zarcillo_ti": Vector2(-6.0, 70.0),
	"zarcillo_td": Vector2(8.0, -80.0),
}
## Taparse un ojo: el jirón grande de cada lado se cruza en diagonal por
## delante del ojo de abajo, casi recto (una mano delante de la cara), y se
## deshace más tarde que de normal para que lo que tapa sea gelatina y no humo.
## (La primera versión lo enroscaba en espiral delante del globo y salía un ARO
## con un hueco: parecía un ojo vacío.)
const RIZO_TAPA := Vector2(0.0, 0.0)
const DESVANECE := 0.22
const DESVANECE_TAPA := 0.62

var c: Criatura
## A qué altura está el suelo que pisa.
var y_base := 0.0
## Cuánto dura acorralado, para que el cerco de sal lo cuente.
var t_cierre := 5.0
## Del contrato. El espectro no se vuelca ni lleva coraza.
var t_volcada := 5.0
var arco_blindaje := 70.0
## Hacia dónde está el jugador, en planta de mesa (+y de mesa es +z en 3D). De
## aquí sale hacia dónde se vuelve la cara.
var hacia_camara := Vector2(0.0, 1.0)

var _raiz: Node3D            # dónde está, hacia dónde mira y cuánto se tumba
var _forma: Node3D           # dentro: se estira, se aplasta y se encoge (pivote en el centro)
var _modelo: Node3D          # dentro: el modelo a su ESCALA, con el centro en el pivote
var _cuerpo: MeshInstance3D
var _mat_cuerpo: ShaderMaterial
var _mats_gel: Array[ShaderMaterial] = []
var _ojos: Array[Dictionary] = []
var _zarcillos: Array[Dictionary] = []
var _centro_y := 0.15
var _alto := 0.29
var _mat_sal: ShaderMaterial
var _sal: MeshInstance3D
var _mat_brillo: ShaderMaterial
var _brillo: MeshInstance3D
var _luz: OmniLight3D
var _rastro: CPUParticles3D
var _humo: CPUParticles3D
var _salpicon: CPUParticles3D
var _motas: CPUParticles3D
var _fatuos: Array[MeshInstance3D] = []
var _semilla := 0.0

var _t := 0.0                # el reloj de la gelatina: se para en la parada del golpe
var _estado_antes := -1
var _yaw := 0.0
var _giro := 0.0             # el giro de cuando sale despedido
var _giro_v := 0.0
var _incl := Vector3.ZERO    # la inclinación: un vector en planta (dirección × ángulo)
var _incl_v := Vector3.ZERO
var _estira := 1.0
var _estira_v := 0.0
var _estira_dir := Vector3.BACK
var _esc := Vector3.ONE
var _esc_v := Vector3.ZERO
var _flote := FLOTE
var _flote_v := 0.0
var _brinco := 0.0
var _brinco_v := 0.0
var _arr := Vector3.ZERO     # lo que se quedan atrás faldón y zarcillos
var _arr_v := Vector3.ZERO
var _golpe_t := 9.0
var _golpe_n := Vector3.BACK
var _destello := 0.0
var _parada := 0.0
var _aviso_sal := 0.0
var _onda := 0.0
var _tapa := 0.0
var _cuaja := 1.0
var _palidez := 0.0
var _desde := Vector3.ZERO
## No atravesarse (ver `Calavera.UMBRAL_APARTE`): el espectro cede ante todas.
var _tramos: Array[Dictionary] = []
var _tramos_listos := false
var _agache := 1.0
var _aparte := Vector3.ZERO

# ------------------------------------------------------------------- montaje

func montar(criatura: Criatura, _fuente: Font) -> void:
	c = criatura
	_semilla = 1.3 + float(c.indice) * 2.71
	_raiz = Node3D.new()
	add_child(_raiz)
	_forma = Node3D.new()
	_raiz.add_child(_forma)

	var modelo := MODELO.instantiate() as Node3D
	var p_cuerpo := _pieza_del_modelo(modelo, "cuerpo")
	var caja: AABB = (p_cuerpo["malla"] as Mesh).get_aabb()
	# Todo lo de aquí abajo va ya a escala: el modelo se mete en `_modelo`, y lo
	# que se calcula pieza a pieza (ojos, jirones, la pose de taparse) se queda
	# en las unidades del modelo, que son las de los shaders.
	_centro_y = (caja.position.y + caja.size.y * 0.5) * ESCALA
	_alto = caja.end.y * ESCALA
	_forma.position = Vector3(0.0, _centro_y, 0.0)
	_modelo = Node3D.new()
	_modelo.transform = Transform3D(Basis.from_scale(Vector3.ONE * ESCALA), Vector3(0.0, -_centro_y, 0.0))
	_forma.add_child(_modelo)
	var baja := Transform3D.IDENTITY

	# --- La masa
	_mat_cuerpo = _gel(SH_CUERPO)
	_cuerpo = _meter(p_cuerpo["malla"], _mat_cuerpo, _modelo, 1)
	_cuerpo.transform = baja * (p_cuerpo["transform"] as Transform3D)

	# --- Los ojos, donde los dejó el modelo
	for i in 3:
		var p := _pieza_del_modelo(modelo, "ojo_%d" % i)
		if p.is_empty():
			continue
		var mat := ShaderMaterial.new()
		mat.shader = SH_OJO
		mat.set_shader_parameter("c_blanco", Paleta.BLANCO)
		mat.set_shader_parameter("c_sombra", Paleta.GRIS_4)
		mat.set_shader_parameter("c_pupila", Paleta.NEGRO)
		mat.set_shader_parameter("c_parpado", Paleta.ARCANO_1)
		mat.set_shader_parameter("c_parpado_luz", Paleta.ARCANO)
		mat.set_shader_parameter("bajo_libre", 0.42 if i == 0 else 0.0)
		var ojo := _meter(p["malla"], mat, _modelo, CAPA_DETALLE)
		var reposo: Transform3D = baja * (p["transform"] as Transform3D)
		ojo.transform = reposo
		# Cada ojo, su carácter: el de arriba es el lento y los de abajo, uno
		# nervioso y otro normal. Es lo que hace que miren "a su aire".
		_ojos.append({"nodo": ojo, "mat": mat, "reposo": reposo,
			"radio": (p["malla"] as Mesh).get_aabb().size.x * 0.5,
			"mirada": Vector3.BACK, "prisa": [5.5, 9.0, 7.0][i],
			"parpadeo": 0.0, "prox": 1.4 + float(i) * 1.15 + float(c.indice) * 0.6,
			"tic": Vector3.ZERO, "prox_tic": 0.3 * float(i), "pop": 1.0, "pop_v": 0.0})

	# --- Los zarcillos
	for nombre: String in RIZOS.keys():
		var p := _pieza_del_modelo(modelo, nombre)
		if p.is_empty():
			continue
		var mat := _gel(SH_ZARCILLO)
		var malla: Mesh = p["malla"]
		var largo := malla.get_aabb().end.x
		var rizo: Vector2 = RIZOS[nombre]
		mat.set_shader_parameter("largo", largo)
		mat.set_shader_parameter("fase", float(_zarcillos.size()) * 1.7 + _semilla)
		var z := _meter(malla, mat, _modelo, CAPA_DETALLE)
		var reposo: Transform3D = baja * (p["transform"] as Transform3D)
		z.transform = reposo
		var lado := signf(reposo.origin.x)
		mat.set_shader_parameter("desvanece", DESVANECE)
		# Solo los dos grandes de los lados se tapan los ojos; el resto se recoge.
		_zarcillos.append({"nodo": z, "mat": mat, "reposo": reposo, "lado": lado,
			"detras": not (nombre == "zarcillo_i" or nombre == "zarcillo_d"), "largo": largo,
			"rizo": rizo, "r0": rizo.x, "r1": rizo.y, "onda": 0.6,
			"tapa": _pose_tapar(reposo, lado)})

	var p_gota := _pieza_del_modelo(modelo, "gota")
	modelo.free()

	# --- La luz: una, violeta, floja y sin sombra. OJO con la energía: la losa
	# está a un palmo, y la luz omni de Godot crece con 1/distancia^atenuación;
	# con energía de luz «normal» el suelo se quemaba en blanco (lo aprendió la
	# brasa). Va baja, por debajo del centro: lo que tiene que alumbrar es el suelo.
	_luz = OmniLight3D.new()
	_luz.light_color = Paleta.ARCANO
	# Primera ronda con 0,55 y 0,85 de alcance: teñía de violeta media losa, y
	# eso es neón. Tiene que ser un charco bajo él.
	_luz.light_energy = 0.24
	_luz.omni_range = 0.55
	_luz.omni_attenuation = 1.5
	_luz.shadow_enabled = false
	_luz.light_specular = 0.25
	_luz.position = Vector3(0.0, _centro_y * 0.55, 0.02)
	_raiz.add_child(_luz)

	_montar_suelo()
	_montar_particulas(p_gota.get("malla", null) as Mesh)
	_montar_fatuos()
	_ocultar()

## Una pieza del GLB: su malla y dónde está respecto a la raíz del modelo.
func _pieza_del_modelo(modelo: Node3D, nombre: String) -> Dictionary:
	var nodo := modelo.find_child(nombre, true, false) as MeshInstance3D
	if nodo == null:
		push_warning("espectro: al modelo le falta la pieza «%s»" % nombre)
		return {}
	var t := nodo.transform
	var padre := nodo.get_parent()
	while padre != null and padre != modelo:
		var p3 := padre as Node3D
		if p3 != null:
			t = p3.transform * t
		padre = padre.get_parent()
	return {"malla": nodo.mesh, "transform": t}

func _meter(malla: Mesh, mat: Material, padre: Node3D, capa: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.material_override = mat
	# Un espectro no hace sombra: debajo tiene su luz.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Los shaders mueven los vértices fuera de la caja de la malla (el rizo de
	# un zarcillo sale entero de la suya): sin margen, desaparecen en el borde.
	mi.extra_cull_margin = 0.35
	mi.layers = capa
	padre.add_child(mi)
	return mi

func _gel(shader: Shader) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("c_hondo", Paleta.NEGRO.lerp(Paleta.ARCANO_1, 0.28))
	m.set_shader_parameter("c_cuerpo", Paleta.ARCANO_1)
	m.set_shader_parameter("c_luz", Paleta.ARCANO)
	m.set_shader_parameter("c_palido", Paleta.BLANCO)
	m.set_shader_parameter("semilla", _semilla + float(_mats_gel.size()) * 0.9)
	_mats_gel.append(m)
	return m

## La pose de un jirón tapándose un ojo (en las unidades del modelo). La raíz
## resbala por la gelatina hasta el rabillo de abajo y de fuera del ojo de abajo
## de su lado, y el jirón se CRUZA EN DIAGONAL por delante del globo, plano y
## de cara, hacia arriba y hacia dentro: es una mano delante de la cara, y por
## encima asoma el ojo de arriba. Los otros jirones no tapan: se recogen.
func _pose_tapar(reposo: Transform3D, lado: float) -> Transform3D:
	# El ojo de abajo de su lado (el 0 es el de arriba, en el centro).
	var ojo: Dictionary = {}
	for i in range(1, _ojos.size()):
		var r: Transform3D = _ojos[i]["reposo"]
		if signf(r.origin.x) == lado:
			ojo = _ojos[i]
	if ojo.is_empty():
		return reposo
	var ojo_t: Transform3D = ojo["reposo"]
	var radio: float = ojo["radio"]
	var n := ojo_t.basis.z.normalized()
	var fuera := Vector3(lado, 0.0, 0.0)
	fuera = (fuera - n * fuera.dot(n)).normalized()
	var arriba := Vector3.UP - n * n.y
	arriba = (arriba - fuera * arriba.dot(fuera)).normalized()
	var x := (-fuera * 0.62 + arriba * 0.78).normalized()
	var z := n
	var y := z.cross(x)
	# Pegado al globo: más separado, por paralaje, de tres cuartos se veía al
	# lado del ojo y no encima.
	var raiz := ojo_t.origin + n * radio * 1.12 + (fuera * 0.55 - arriba * 0.75) * radio
	return Transform3D(Basis(x, y, z), raiz)

## Lo pintado en la losa: el cerco de sal (con la sombra floja y el polvo) y la
## luz violeta de debajo.
func _montar_suelo() -> void:
	var lado := c.radio * E * 4.6
	var plano := PlaneMesh.new()
	plano.size = Vector2(lado, lado)
	_mat_sal = ShaderMaterial.new()
	_mat_sal.shader = SH_SAL
	_mat_sal.set_shader_parameter("c_sal", Paleta.TIERRA_6)
	_mat_sal.set_shader_parameter("c_polvo", Paleta.PIEDRA_4)
	_mat_sal.set_shader_parameter("c_runa", Paleta.ARCANO)
	_mat_sal.set_shader_parameter("semilla", _semilla)
	_sal = _meter(plano, _mat_sal, self, CAPA_SIN_REFLEJO)
	_sal.extra_cull_margin = 0.0

	var plano_b := PlaneMesh.new()
	plano_b.size = Vector2(lado * 1.5, lado * 1.5)
	_mat_brillo = ShaderMaterial.new()
	_mat_brillo.shader = SH_BRILLO
	_mat_brillo.set_shader_parameter("color", Paleta.ARCANO)
	_mat_brillo.set_shader_parameter("semilla", _semilla)
	_brillo = _meter(plano_b, _mat_brillo, self, CAPA_SIN_REFLEJO)
	_brillo.extra_cull_margin = 0.0

func _material_humo(color: Color, fuerza: float, de_particula: bool = true,
		hebras: float = 1.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_HUMO
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("fuerza", fuerza)
	m.set_shader_parameter("hebras", hebras)
	m.set_shader_parameter("particula", 1.0 if de_particula else 0.0)
	return m

func _rampa(a: Color, b: Color) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, a)
	g.set_color(1, b)
	g.add_point(0.25, Color(a.r, a.g, a.b, 1.0))
	return g

func _curva(desde: float, hasta: float) -> Curve:
	var cu := Curve.new()
	cu.add_point(Vector2(0.0, desde))
	cu.add_point(Vector2(1.0, hasta))
	return cu

## Tres surtidores, y los tres caducan solos: cada partícula tiene su vida
## contada, así que al esconderse no queda nada colgando.
func _montar_particulas(malla_gota: Mesh) -> void:
	# El rastro: humo violeta tenue que se queda donde estuvo.
	_rastro = CPUParticles3D.new()
	var cuadro := QuadMesh.new()
	cuadro.size = Vector2(0.07, 0.07)
	_rastro.mesh = cuadro
	# Más denso que la primera vez (18 y 0,22): de lejos se perdía.
	_rastro.material_override = _material_humo(Paleta.ARCANO, 0.30)
	_rastro.amount = 30
	_rastro.lifetime = 0.8
	_rastro.local_coords = false
	_rastro.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_rastro.emission_sphere_radius = 0.05
	_rastro.direction = Vector3.UP
	_rastro.spread = 40.0
	_rastro.initial_velocity_min = 0.01
	_rastro.initial_velocity_max = 0.05
	_rastro.gravity = Vector3(0.0, 0.05, 0.0)
	_rastro.damping_min = 0.2
	_rastro.damping_max = 0.6
	_rastro.scale_amount_min = 0.7
	_rastro.scale_amount_max = 1.2
	_rastro.scale_amount_curve = _curva(0.6, 1.5)
	_rastro.color_ramp = _rampa(Color(1.0, 1.0, 1.0, 0.0), Color(1.0, 1.0, 1.0, 0.0))
	_rastro.emitting = false
	_rastro.layers = CAPA_SIN_REFLEJO
	_rastro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_rastro)

	# Las MOTAS: se desprenden sin parar de las puntas del faldón y caen despacio,
	# apagándose antes de tocar la losa. Es lo que dice que por abajo no se
	# acaba, se DESHACE (y no solo al moverse: también quieto).
	_motas = CPUParticles3D.new()
	var cuadro_m := QuadMesh.new()
	cuadro_m.size = Vector2(0.032, 0.032)
	_motas.mesh = cuadro_m
	_motas.material_override = _material_humo(Paleta.ARCANO.lerp(Paleta.BLANCO, 0.15), 0.55, true, 0.5)
	_motas.amount = 16
	_motas.lifetime = 1.1
	_motas.local_coords = false
	_motas.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	_motas.emission_ring_axis = Vector3.UP
	_motas.emission_ring_radius = 0.10
	_motas.emission_ring_inner_radius = 0.03
	_motas.emission_ring_height = 0.02
	_motas.direction = Vector3.DOWN
	_motas.spread = 25.0
	_motas.initial_velocity_min = 0.015
	_motas.initial_velocity_max = 0.05
	_motas.gravity = Vector3(0.0, -0.035, 0.0)
	_motas.damping_min = 0.1
	_motas.damping_max = 0.3
	_motas.scale_amount_min = 0.5
	_motas.scale_amount_max = 1.1
	_motas.scale_amount_curve = _curva(1.0, 0.2)
	_motas.color_ramp = _rampa(Color(1.0, 1.0, 1.0, 0.0), Color(1.0, 1.0, 1.0, 0.0))
	_motas.emitting = false
	_motas.layers = CAPA_SIN_REFLEJO
	_motas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_motas)

	# El humo de aparecer: sube del suelo en corro y cuaja en el cuerpo.
	_humo = CPUParticles3D.new()
	var cuadro_h := QuadMesh.new()
	cuadro_h.size = Vector2(0.12, 0.12)
	_humo.mesh = cuadro_h
	_humo.material_override = _material_humo(Paleta.ARCANO_1.lerp(Paleta.ARCANO, 0.4), 0.85)
	_humo.amount = 26
	_humo.lifetime = 0.85
	_humo.one_shot = true
	_humo.explosiveness = 0.55
	_humo.local_coords = false
	_humo.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	_humo.emission_ring_axis = Vector3.UP
	_humo.emission_ring_radius = 0.11
	_humo.emission_ring_inner_radius = 0.03
	_humo.emission_ring_height = 0.01
	_humo.direction = Vector3.UP
	_humo.spread = 18.0
	_humo.initial_velocity_min = 0.18
	_humo.initial_velocity_max = 0.36
	_humo.gravity = Vector3.ZERO
	_humo.damping_min = 0.25
	_humo.damping_max = 0.45
	_humo.tangential_accel_min = 0.3
	_humo.tangential_accel_max = 0.6
	_humo.scale_amount_curve = _curva(0.5, 1.6)
	_humo.color_ramp = _rampa(Color(1.0, 1.0, 1.0, 0.0), Color(1.0, 1.0, 1.0, 0.0))
	_humo.emitting = false
	_humo.layers = CAPA_SIN_REFLEJO
	_humo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_humo)

	# El salpicón del golpe: gotas de su propia gelatina.
	_salpicon = CPUParticles3D.new()
	_salpicon.mesh = malla_gota if malla_gota != null else SphereMesh.new()
	var mat_gota := _gel(SH_CUERPO)
	mat_gota.set_shader_parameter("ondear", 0.0)
	_salpicon.material_override = mat_gota
	_salpicon.amount = 10
	_salpicon.lifetime = 0.55
	_salpicon.one_shot = true
	_salpicon.explosiveness = 0.95
	_salpicon.local_coords = false
	_salpicon.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_salpicon.emission_sphere_radius = 0.04
	_salpicon.spread = 65.0
	_salpicon.initial_velocity_min = 0.55
	_salpicon.initial_velocity_max = 1.10
	_salpicon.gravity = Vector3(0.0, -2.6, 0.0)
	_salpicon.scale_amount_min = 0.6
	_salpicon.scale_amount_max = 1.4
	_salpicon.scale_amount_curve = _curva(1.0, 0.15)
	_salpicon.emitting = false
	_salpicon.layers = CAPA_SIN_REFLEJO
	_salpicon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_salpicon)

## LA CALIDAD (0 ALTA, 1 MEDIA, 2 BAJA): lo llama el núcleo. Aquí lo único que
## pesa de continuo son las tarjetas de humo del rastro y las motas del faldón:
## en MEDIA y BAJA van menos, y el cuerpo, los ojos y la sal se quedan como están.
func calidad(n: int) -> void:
	if _rastro == null or _motas == null:
		return
	var rastro := 30
	var motas := 16
	if n == 1:
		rastro = 22
		motas = 12
	elif n >= 2:
		rastro = 15
		motas = 8
	if _rastro.amount != rastro:
		_rastro.amount = rastro
	if _motas.amount != motas:
		_motas.amount = motas

## Los fuegos fatuos de cuando está aturdido: sus «estrellas». Son de la cripta:
## tres lucecitas pálidas dando vueltas.
func _montar_fatuos() -> void:
	var cuadro := QuadMesh.new()
	cuadro.size = Vector2(0.045, 0.045)
	var mat := _material_humo(Paleta.ARCANO.lerp(Paleta.BLANCO, 0.45), 1.3, false, 0.25)
	for i in 3:
		var f := _meter(cuadro, mat, self, CAPA_DETALLE)
		f.extra_cull_margin = 0.0
		f.visible = false
		_fatuos.append(f)

# ------------------------------------------------------------------- sucesos

## El golpe: fogonazo, la gelatina se aplasta contra el impacto y sale girando.
func golpear(normal: Vector2) -> void:
	_destello = 0.75
	_golpe_t = 0.0
	_golpe_n = Vector3(normal.x, 0.0, normal.y).normalized()
	_parada = 0.05
	_giro_v = (11.0 + 4.0 * _azar(_t)) * (1.0 if _azar(_t + 3.1) > 0.5 else -1.0)
	if _salpicon != null and _raiz.visible:
		_salpicon.global_position = centro() - _golpe_n * 0.05
		_salpicon.direction = (-_golpe_n + Vector3.UP * 0.9).normalized()
		_salpicon.restart()

## No lleva coraza; si algo lo llama, solo se estremece.
func blindar() -> void:
	_destello = maxf(_destello, 0.3)

## Le ha subido el miedo: la sal se repasa.
func avisar_aro() -> void:
	_aviso_sal = 1.0

func color() -> Color:
	return Paleta.ARCANO

## Dónde está el centro del cuerpo, para que la cámara y los efectos lo sigan.
## Con lo que se haya agachado o apartado (la transformada del propio nodo).
func centro() -> Vector3:
	return transform * _centro_local()

## El mismo centro, en el marco del propio cuerpo: para lo que cuelga de él.
func _centro_local() -> Vector3:
	return _raiz.position + _raiz.basis * Vector3(0.0, _centro_y, 0.0)

func _ocultar() -> void:
	_quieto()
	_raiz.visible = false
	_sal.visible = false
	_brillo.visible = false
	_rastro.emitting = false
	_motas.emitting = false
	for f in _fatuos:
		f.visible = false

static func _azar(n: float) -> float:
	return fposmod(sin(n * 12.9898 + 4.1414) * 43758.5453, 1.0)

## Un estiramiento que conserva el volumen: `s` a lo largo de `d` (unitario) y
## 1/√s de través. Es lo que hace gelatina de un cuerpo.
static func _estirar(d: Vector3, s: float) -> Basis:
	var p := 1.0 / sqrt(maxf(s, 0.2))
	var k := s - p
	return Basis(Vector3(p, 0.0, 0.0) + d * (d.x * k), Vector3(0.0, p, 0.0) + d * (d.y * k),
		Vector3(0.0, 0.0, p) + d * (d.z * k))

# --------------------------------------------------------------- cada cuadro

## `bola` es dónde está la bola que lo lleva, si va dentro de una.
func actualizar(delta: float, bola: Vector3) -> void:
	var estado := c.estado
	var suelo := Vector3(c.pos.x * E, y_base, c.pos.y * E)

	if estado != _estado_antes:
		_entrar(estado, suelo)
		_estado_antes = estado

	if not c.activa or estado == Criatura.Estado.FUERA:
		# Fuera no hay golpe que enseñar: si se quedaran guardados, saltarían al
		# reaparecer (un fogonazo en el sitio viejo).
		_parada = 0.0
		_destello = 0.0
		_golpe_t = 9.0
		_ocultar()
		_luz.visible = false
		return
	if estado == Criatura.Estado.ESCONDIDA:
		_quieto()
		_poner_escondido(delta, suelo)
		return
	if estado == Criatura.Estado.EN_BOLA:
		# `_desde` ya se tomó con la transformada puesta (`centro()`): quitarla
		# ahora no hace saltar nada.
		_quieto()
		_poner_en_bola(delta, bola)
		return

	_apartarse(delta, suelo)
	_raiz.visible = true
	_luz.visible = true
	_sal.visible = true
	_brillo.visible = true

	# La parada del golpe: 50 ms con la pose congelada (solo lo que se ve).
	if _parada > 0.0:
		_parada -= delta
		_destello = maxf(_destello - delta * 4.0, 0.0)
		_poner_gel()
		return
	_t += delta

	var v3 := Vector3(c.vel.x, 0.0, c.vel.y) * E
	var rapidez := v3.length()
	var dir := v3 / rapidez if rapidez > 0.01 else Vector3(c.rumbo.x, 0.0, c.rumbo.y).normalized()
	if dir.length_squared() < 0.5:
		dir = Vector3.BACK
	var corre := clampf(rapidez / maxf(c.v_huir * E, 0.3), 0.0, 1.0)
	var miedo := clampf(c.miedo, 0.0, 1.0)
	var mira3 := Vector3(c.mira.x * E, y_base + 0.09, c.mira.y * E)

	# --- Lo que pide cada estado ------------------------------------------------
	var flote := FLOTE + 0.011 * sin(_t * 2.4 + _semilla)
	var esc := Vector3.ONE
	var incl := Vector3.ZERO
	var estira := 1.0
	var temblor := miedo * miedo * 0.8
	# El miedo es UN eje: de violeta denso a claro y casi transparente (lo hace
	# el shader con `palidez`), con la pupila encogiéndose a un punto.
	var palidez := miedo * 0.78
	var tapa := 0.0
	var encoge := 0.0
	var cuaja := 1.0
	var abre := 1.0 + 0.35 * miedo
	var pupila := lerpf(0.42, 0.17, miedo)
	var mirar := true
	var rodar := 0.0
	var rizo_k := 1.0            # cuánto rizo de reposo
	var rizo_extra := Vector2.ZERO
	var onda := 0.55
	var frecuencia := 4.5
	var arrastra := 1.0
	var sale_rastro := rapidez > 0.15
	var ver_ojos := 1.0
	var t_e := c.t_estado

	match estado:
		Criatura.Estado.APARECER:
			# Sube del suelo como humo que cuaja.
			# Primero es una columna de humo estrecha y alta, que se asienta y se
			# ensancha mientras cuaja; los ojos se abren lo último.
			var u := clampf(t_e / T_CUAJAR, 0.0, 1.0)
			var e := smoothstep(0.15, 1.0, u)
			cuaja = smoothstep(0.0, 1.0, u)
			flote = lerpf(-0.05, FLOTE, 1.0 - pow(1.0 - u, 3.0))
			esc = Vector3(lerpf(0.35, 1.0, e), lerpf(1.35, 1.0, e), lerpf(0.35, 1.0, e))
			abre = smoothstep(0.7, 1.0, u) * 1.25
			ver_ojos = smoothstep(0.50, 0.85, u)
			rizo_k = u
			sale_rastro = false
		Criatura.Estado.CORRER, Criatura.Estado.HUIR:
			var huye := estado == Criatura.Estado.HUIR
			incl = dir * (INCLINA_HUIR if huye else INCLINA_CORRER) * corre
			estira = 1.0 + (ESTIRA_HUIR if huye else ESTIRA_CORRER) * corre
			rizo_k = 1.0 - 0.45 * corre
			onda = 0.55 + 1.1 * corre
			frecuencia = 4.5 + 7.0 * corre
			if huye:
				abre = maxf(abre, 1.22)
				pupila = minf(pupila, 0.32)
				flote += 0.012
		Criatura.Estado.ALERTA:
			# El respingo: arriba, estirado, los ojos desorbitados y los zarcillos
			# de punta. El polvo lo levanta `_entrar`.
			esc = Vector3(0.90, 1.16, 0.90)
			flote += 0.035
			abre = 1.55
			pupila = 0.22
			# Los jirones se abren y aletean, estirados hacia fuera. Erizados
			# hacia arriba (la primera versión) eran cuernos de diablo.
			rizo_k = 0.30
			onda = 0.9
			frecuencia = 16.0
			temblor = maxf(temblor, 0.6)
			palidez = maxf(palidez, 0.25)
		Criatura.Estado.VOLAR:
			# Despedido: girando, los ojos apretados, todo agitado.
			incl = dir * 0.55
			estira = 1.0 + 0.20 * corre
			abre = 0.06 if _golpe_t < 0.45 else 1.30
			rizo_k = 0.4
			onda = 2.2
			frecuencia = 15.0
			flote += 0.02
			temblor = maxf(temblor, 0.5)
			sale_rastro = true
		Criatura.Estado.ATURDIDA:
			# Desinflado, casi tocando la losa, dando vueltas de mareo.
			flote = 0.006 + 0.004 * sin(_t * 3.0)
			esc = Vector3(1.13 + 0.03 * sin(_t * 5.0), 0.80, 1.13 - 0.03 * sin(_t * 5.0))
			incl = Vector3(cos(_t * 2.3), 0.0, sin(_t * 2.3)) * 0.17
			abre = 0.42
			pupila = 0.34
			rodar = 1.0
			# Los zarcillos cuelgan: doblados hacia abajo desde la raíz.
			rizo_k = 0.35
			rizo_extra = Vector2(-17.0, -60.0)
			onda = 0.3
			frecuencia = 2.0
			palidez = maxf(palidez, 0.15)
		Criatura.Estado.ACORRALADA:
			# Encogido, tiritando, casi transparente, tapándose los ojos de abajo
			# con los jirones y con los TRES muy abiertos mirando a la bola por
			# encima y a través de la gelatina. Es lo más pálido que se pone.
			esc = Vector3(0.94, 0.80, 0.94) * 0.90
			flote = 0.014 + 0.003 * sin(_t * 7.0)
			encoge = 1.0
			temblor = 1.0
			palidez = 1.0
			tapa = 1.0
			abre = 1.55
			pupila = 0.17
			onda = 0.15
			frecuencia = 9.0
			sale_rastro = false

	# --- Los muelles: la gelatina se pasa y vuelve ---------------------------------
	_flote_v += (220.0 * (flote - _flote) - 16.0 * _flote_v) * delta
	_flote += _flote_v * delta
	_brinco_v += (-260.0 * _brinco - 9.0 * _brinco_v) * delta
	_brinco += _brinco_v * delta
	_esc_v += (260.0 * (esc - _esc) - 13.0 * _esc_v) * delta
	_esc += _esc_v * delta
	_incl_v += (120.0 * (incl - _incl) - 11.0 * _incl_v) * delta
	_incl += _incl_v * delta
	_estira_v += (150.0 * (estira - _estira) - 12.0 * _estira_v) * delta
	_estira += _estira_v * delta
	if rapidez > 0.05:
		_estira_dir = _estira_dir.slerp(dir, 1.0 - exp(-10.0 * delta)).normalized()
	var arr_obj := -v3 * 0.05 * arrastra
	if arr_obj.length() > 0.045:
		arr_obj = arr_obj.normalized() * 0.045
	_arr_v += (90.0 * (arr_obj - _arr) - 10.0 * _arr_v) * delta
	_arr += _arr_v * delta
	_giro_v *= exp(-3.2 * delta)
	_giro += _giro_v * delta
	if estado != Criatura.Estado.VOLAR:
		# Al aterrizar recupera la cara: el giro vuelve a la vuelta entera más cercana.
		_giro = lerpf(_giro, roundf(_giro / TAU) * TAU, 1.0 - exp(-5.0 * delta))
	_palidez = lerpf(_palidez, palidez, 1.0 - exp(-5.0 * delta))
	_tapa = lerpf(_tapa, tapa, 1.0 - exp(-(9.0 if tapa > _tapa else 5.0) * delta))
	_cuaja = cuaja
	_destello = maxf(_destello - delta * 4.0, 0.0)
	_golpe_t += delta

	# --- La cara: al jugador, con margen hacia donde va y hacia la bola ----------
	var cam := Vector3(hacia_camara.x, 0.0, hacia_camara.y).normalized()
	var deseo := cam
	if rapidez > 0.05:
		deseo += dir * 0.9 * corre
	var a_bola := mira3 - suelo
	a_bola.y = 0.0
	if a_bola.length_squared() > 1e-4:
		# Poco: la bola la siguen las PUPILAS. Con 0,45 la cara entera se torcía
		# hacia ella y de frente ya no era el triángulo del sprite.
		deseo += a_bola.normalized() * 0.2
	var yaw_cam := atan2(cam.x, cam.z)
	var dif := wrapf(atan2(deseo.x, deseo.z) - yaw_cam, -PI, PI)
	dif = clampf(dif, -deg_to_rad(GIRO_MAX), deg_to_rad(GIRO_MAX))
	_yaw = lerp_angle(_yaw, yaw_cam + dif, 1.0 - exp(-6.0 * delta))

	# --- La pose -----------------------------------------------------------------
	var tirita := Vector3(sin(_t * 47.0), 0.0, sin(_t * 53.0 + 1.3)) * 0.0035 * temblor
	var angulo := _incl.length()
	var base_giro := Basis(Vector3.UP, _yaw + _giro)
	if angulo > 1e-4:
		var eje := Vector3.UP.cross(_incl / angulo).normalized()
		base_giro = Basis(eje, angulo) * base_giro
	_raiz.transform = Transform3D(base_giro, suelo + Vector3(0.0, _flote + _brinco, 0.0) + tirita)

	var inv := base_giro.inverse()
	var deforma := Basis.IDENTITY
	if _golpe_t < 0.75:
		var cede := 0.48 if _golpe_t < 0.05 else \
			0.48 * exp(-(_golpe_t - 0.05) * 7.5) * cos((_golpe_t - 0.05) * 26.0)
		deforma = _estirar((inv * _golpe_n).normalized(), 1.0 - cede)
	if absf(_estira - 1.0) > 0.002:
		deforma = deforma * _estirar((inv * _estira_dir).normalized(), _estira)
	_forma.transform = Transform3D(deforma * Basis.from_scale(_esc), Vector3(0.0, _centro_y, 0.0))

	# --- La gelatina ----------------------------------------------------------------
	_mat_cuerpo.set_shader_parameter("temblor", temblor)
	_mat_cuerpo.set_shader_parameter("encoge", encoge)
	_mat_cuerpo.set_shader_parameter("arrastre", _cuerpo.global_basis.inverse() * _arr)
	_poner_gel()
	_mover_zarcillos(delta, rizo_k, rizo_extra, onda, frecuencia, temblor)
	_mover_ojos(delta, mira3, abre, pupila, mirar, rodar, estado, ver_ojos)

	# --- La luz y la losa ----------------------------------------------------------
	_luz.position = Vector3(0.0, _centro_y * 0.55, 0.02)
	var late := 0.92 + 0.08 * sin(_t * 3.7 + _semilla)
	_luz.light_energy = (0.24 + 0.10 * _palidez + _destello * 0.3) * late * _cuaja
	_luz.light_color = Paleta.ARCANO.lerp(Paleta.BLANCO, _palidez * 0.35)
	_poner_suelo(delta, suelo, estado, miedo)

	# --- Lo que suelta ----------------------------------------------------------------
	_rastro.emitting = sale_rastro
	_rastro.global_position = centro() + Vector3(0.0, -0.06, 0.0)
	_motas.emitting = _cuaja > 0.6 and estado != Criatura.Estado.ACORRALADA
	_motas.global_position = _raiz.global_position + Vector3(0.0, 0.07 * ESCALA, 0.0)
	var fatuos := estado == Criatura.Estado.ATURDIDA
	for i in _fatuos.size():
		var f := _fatuos[i]
		f.visible = fatuos
		if fatuos:
			var a := _t * 3.4 + TAU * float(i) / 3.0
			f.position = _centro_local() + Vector3(cos(a) * 0.105, _alto - _centro_y + 0.02
				+ 0.015 * sin(_t * 5.0 + float(i) * 2.0), sin(a) * 0.105)
			var s := 0.8 + 0.25 * sin(_t * 9.0 + float(i) * 1.7)
			f.scale = Vector3.ONE * s

func _entrar(estado: int, suelo: Vector3) -> void:
	if estado == Criatura.Estado.ALERTA:
		# El respingo: un tirón hacia arriba que el muelle devuelve.
		_brinco_v = 1.1
		_onda = 0.001
	if estado == Criatura.Estado.APARECER:
		_yaw = atan2(hacia_camara.x, hacia_camara.y)
		_giro = 0.0
		_giro_v = 0.0
		_incl = Vector3.ZERO
		_incl_v = Vector3.ZERO
		_esc = Vector3(0.35, 1.35, 0.35)
		_esc_v = Vector3.ZERO
		_flote = -0.07
		_flote_v = 0.0
		_humo.global_position = suelo + Vector3(0.0, 0.02, 0.0)
		_humo.restart()
	if estado == Criatura.Estado.EN_BOLA:
		_desde = centro()
	if estado == Criatura.Estado.ACORRALADA:
		_aviso_sal = 1.0

## No atravesarse a la vista (la cuenta, en `calavera.gd`): bajo un raíl bajo se
## agacha, y a menos de `Calavera.UMBRAL_APARTE` de cualquier otra criatura se
## aparta y SUBE, como quien se quita de en medio asustado. Antes, cuando la caza
## los dejaba en la misma boca, sus ojos salían por la cuenca de la calavera.
func _apartarse(delta: float, suelo: Vector3) -> void:
	if not _tramos_listos:
		_tramos_listos = true
		_tramos = Calavera.tramos_bajos(get_parent())
	# Lo que mide con la pose del cuadro anterior: flotando, más el respingo y lo
	# que se estira hacia arriba (alerta llega a 1,16).
	var alto := maxf(_flote + _brinco, 0.0) + _centro_y + (_alto - _centro_y) * maxf(_esc.y, 1.0) + 0.01
	var alcance := c.radio * E * 1.2 + Calavera.ANCHO_RAIL
	var libre := Calavera.hueco_bajo_raiil(_tramos, suelo, alcance, alto)
	var agache := clampf(libre / alto, Calavera.AGACHE_MIN, 1.0)
	var e := Calavera.empuje(self, c, PackedStringArray(["escarabajo", "saltarin", "gotita"]))
	e = e.limit_length(APARTE_ESPECTRO)
	var sube := minf(e.length() * SUBE_AL_APARTARSE, SUBE_MAX)
	# Bajo un raíl no sube: se agacharía y subiría a la vez, contra el raíl.
	sube *= smoothstep(0.75, 1.0, agache)
	_agache = lerpf(_agache, agache, 1.0 - exp(-12.0 * delta))
	_aparte = _aparte.lerp(Vector3(e.x, sube, e.y), 1.0 - exp(-7.0 * delta))
	Calavera.colocar(self, suelo, _agache, _aparte)

func _quieto() -> void:
	_agache = 1.0
	_aparte = Vector3.ZERO
	transform = Transform3D.IDENTITY

## Lo que comparten todas las piezas de gelatina.
func _poner_gel() -> void:
	for m in _mats_gel:
		m.set_shader_parameter("reloj", _t)
		m.set_shader_parameter("palidez", _palidez)
		m.set_shader_parameter("destello", _destello)
		m.set_shader_parameter("cuaja", _cuaja)
		m.set_shader_parameter("agitacion", clampf(_palidez * 1.2, 0.0, 1.0))

## `recoge` (0..1) los encoge hacia la raíz: los que no tapan, acorralado, y
## todos al hacerse una bola para colarse en el cascabel.
func _mover_zarcillos(delta: float, rizo_k: float, rizo_extra: Vector2, onda: float,
		frecuencia: float, temblor: float, recoge: float = 0.0) -> void:
	var k := 1.0 - exp(-8.0 * delta)
	for z in _zarcillos:
		var nodo: MeshInstance3D = z["nodo"]
		var mat: ShaderMaterial = z["mat"]
		var reposo: Transform3D = z["reposo"]
		var rizo: Vector2 = z["rizo"]
		var detras: bool = z["detras"]
		var r0 := rizo.x * rizo_k + rizo_extra.x
		var r1 := rizo.y * rizo_k + rizo_extra.y
		var t := _tapa
		var arrastre := _arr * 1.4
		var encoge := recoge
		if detras:
			encoge = maxf(encoge, _tapa * 0.55)
			# Los que no tapan se recogen: más curvados, sin llegar a cerrarse.
			r1 = lerpf(r1, rizo.y * 1.7, t)
			t = 0.0
		else:
			r0 = lerpf(r0, RIZO_TAPA.x, t)
			r1 = lerpf(r1, RIZO_TAPA.y, t)
			arrastre *= 1.0 - t
		z["r0"] = lerpf(float(z["r0"]), r0, k)
		z["r1"] = lerpf(float(z["r1"]), r1, k)
		z["onda"] = lerpf(float(z["onda"]), onda, k)
		if t > 0.001:
			# La raíz resbala hasta la cuenca y el zarcillo se vuelve hacia el ojo.
			var tapa: Transform3D = z["tapa"]
			var u := smoothstep(0.0, 1.0, t)
			nodo.transform = Transform3D(
				Basis(reposo.basis.get_rotation_quaternion().slerp(
					tapa.basis.get_rotation_quaternion(), u)),
				reposo.origin.lerp(tapa.origin, u))
		else:
			nodo.transform = reposo
		if encoge > 0.001:
			nodo.transform = nodo.transform * Transform3D(Basis.from_scale(
				Vector3(1.0 - 0.75 * encoge, 1.0 - 0.35 * encoge, 1.0 - 0.35 * encoge)), Vector3.ZERO)
		# Los zarcillos cuajan después que la masa: salen de ella.
		mat.set_shader_parameter("cuaja", smoothstep(0.45, 1.0, _cuaja))
		mat.set_shader_parameter("rizo0", z["r0"])
		mat.set_shader_parameter("rizo1", z["r1"])
		mat.set_shader_parameter("onda", float(z["onda"]) * (1.0 - t * 0.8))
		mat.set_shader_parameter("frecuencia", frecuencia)
		mat.set_shader_parameter("temblor", temblor)
		mat.set_shader_parameter("desvanece", lerpf(DESVANECE, DESVANECE_TAPA, t))
		if t > 0.001:
			# Lo que tapa es gelatina, no humo: más denso que el resto del cuerpo
			# acorralado, que es casi transparente.
			mat.set_shader_parameter("palidez", _palidez * (1.0 - 0.6 * t))
		mat.set_shader_parameter("arrastre", nodo.global_basis.inverse() * arrastre)

func _mover_ojos(delta: float, mira3: Vector3, abre: float, pupila: float, mirar: bool,
		rodar: float, estado: int, ver: float) -> void:
	for i in _ojos.size():
		var o: Dictionary = _ojos[i]
		var nodo: MeshInstance3D = o["nodo"]
		var mat: ShaderMaterial = o["mat"]
		# El parpadeo, cada uno a su hora.
		# Sobresaltado, despedido o acorralado no se parpadea: un parpadeo en la
		# foto de la alerta dejaba un ojo cerrado justo cuando tienen que estar
		# los tres desorbitados.
		var parpadea := estado == Criatura.Estado.CORRER or estado == Criatura.Estado.HUIR \
			or estado == Criatura.Estado.ATURDIDA
		if parpadea:
			o["prox"] = float(o["prox"]) - delta
		else:
			o["parpadeo"] = 0.0
		if float(o["prox"]) <= 0.0:
			o["parpadeo"] = 0.14
			o["prox"] = 2.0 + 3.0 * _azar(_t * 1.7 + float(i) * 5.3 + _semilla)
		o["parpadeo"] = maxf(float(o["parpadeo"]) - delta, 0.0)
		var cierra := sin(PI * clampf(float(o["parpadeo"]) / 0.14, 0.0, 1.0))
		var a := abre
		if estado == Criatura.Estado.ATURDIDA:
			# A media asta y desacompasados.
			a = abre * (0.85 + 0.3 * sin(_t * 2.0 + float(i) * 2.1))
		a *= 1.0 - cierra

		# La mirada: a la bola, cada uno con su prisa y sus tics.
		o["prox_tic"] = float(o["prox_tic"]) - delta
		if float(o["prox_tic"]) <= 0.0:
			var nervio := 1.0 + 2.0 * _palidez
			o["tic"] = Vector3(_azar(_t * 3.1 + float(i)) - 0.5, _azar(_t * 2.3 + float(i) * 7.0) - 0.5,
				0.0) * 0.35 * nervio
			o["prox_tic"] = (0.35 + 0.9 * _azar(_t + float(i) * 11.0)) / nervio
		var hacia := Vector3(0.0, 0.0, 1.0)
		if mirar:
			var local := nodo.global_transform.affine_inverse() * mira3
			if local.length_squared() > 1e-8:
				hacia = local.normalized()
		hacia += o["tic"] as Vector3
		if rodar > 0.0:
			var g := _t * 6.0 + float(i) * 2.2
			hacia = Vector3(cos(g) * 0.75, sin(g) * 0.75, 0.6)
		# Nunca a la nuca: siempre algo hacia fuera, que es desde donde se le ve.
		# Y nunca más de 40° del frente del globo: más allá, la pupila se iba al
		# canto y el ojo desorbitado de la alerta se quedaba en blanco.
		hacia.z = maxf(hacia.z, 0.0) + 0.45
		hacia = hacia.normalized()
		var frente := Vector3(0.0, 0.0, 1.0)
		var abierto := frente.angle_to(hacia)
		if abierto > 0.70:
			hacia = frente.slerp(hacia, 0.70 / abierto).normalized()
		var mirada: Vector3 = o["mirada"]
		mirada = mirada.slerp(hacia, 1.0 - exp(-float(o["prisa"]) * delta)).normalized()
		o["mirada"] = mirada

		# El globo se le sale un poco con el susto (otro muelle).
		var pop_obj := 1.0 + 0.10 * clampf(abre - 1.0, 0.0, 0.6) / 0.6
		o["pop_v"] = float(o["pop_v"]) + (300.0 * (pop_obj - float(o["pop"])) \
			- 12.0 * float(o["pop_v"])) * delta
		o["pop"] = float(o["pop"]) + float(o["pop_v"]) * delta
		var reposo: Transform3D = o["reposo"]
		# Al aparecer, los globos salen de dentro de la gelatina cuando ya ha
		# cuajado: antes flotaban tres canicas en el humo.
		nodo.visible = ver > 0.02
		nodo.transform = Transform3D(reposo.basis.scaled(Vector3.ONE * float(o["pop"]) * maxf(ver, 0.02)),
			reposo.origin)

		mat.set_shader_parameter("mirada", mirada)
		mat.set_shader_parameter("abre", a)
		mat.set_shader_parameter("pupila", pupila)
		mat.set_shader_parameter("destello", _destello)
		mat.set_shader_parameter("palidez", _palidez)

func _poner_suelo(delta: float, suelo: Vector3, estado: int, miedo: float) -> void:
	_aviso_sal = maxf(_aviso_sal - delta * 3.0, 0.0)
	if _onda > 0.0:
		_onda += delta / 0.55
		if _onda >= 1.0:
			_onda = 0.0
	# Un pelo por encima de la losa y de lo que hay pintado en ella (las bocas
	# del túnel van a 0,009): a la misma altura, dos planos se pelean y parpadea.
	# EN EL SITIO DE LA CAZA, no donde se haya apartado o agachado el dibujo: el
	# aro es lo que dice dónde choca la bola. Colgaban del nodo y se iban con él
	# (y al subir, flotaban sobre la losa). Se deshace la transformada del nodo.
	var al_suelo := transform.affine_inverse()
	_sal.transform = al_suelo * Transform3D(Basis.IDENTITY, suelo + Vector3(0.0, 0.013, 0.0))
	_brillo.transform = al_suelo * Transform3D(Basis.IDENTITY, suelo + Vector3(0.0, 0.011, 0.0))
	var acorralado := estado == Criatura.Estado.ACORRALADA
	var queda := 1.0
	if acorralado:
		queda = 1.0 - clampf(c.t_estado / maxf(t_cierre, 0.1), 0.0, 1.0)
	_mat_sal.set_shader_parameter("miedo", miedo)
	_mat_sal.set_shader_parameter("cerrado", 1.0 if acorralado else 0.0)
	_mat_sal.set_shader_parameter("queda", queda)
	_mat_sal.set_shader_parameter("aviso", _aviso_sal)
	_mat_sal.set_shader_parameter("onda", _onda)
	_mat_sal.set_shader_parameter("sombra", _cuaja * (1.0 - smoothstep(0.03, 0.12, _flote + _brinco)) + 0.3)
	_mat_sal.set_shader_parameter("reloj", _t)
	_mat_brillo.set_shader_parameter("charco", _cuaja * (0.35 + 0.2 * _palidez))
	_mat_brillo.set_shader_parameter("filtra", 0.0)
	_mat_brillo.set_shader_parameter("reloj", _t)

## Dentro de la catacumba no se le ve: solo una luz que corre bajo la losa y se
## cuela por las grietas, y la luz violeta pegada al suelo.
func _poner_escondido(delta: float, suelo: Vector3) -> void:
	_t += delta
	_raiz.visible = false
	_sal.visible = false
	_rastro.emitting = false
	_motas.emitting = false
	for f in _fatuos:
		f.visible = false
	_brillo.visible = true
	# Entera, no solo la posición: si no, se quedaba con la escala que le dejó la
	# transformada deshecha del último cuadro a la vista (`_poner_suelo`).
	_brillo.transform = Transform3D(Basis.IDENTITY, suelo + Vector3(0.0, 0.011, 0.0))
	_mat_brillo.set_shader_parameter("charco", 0.35)
	_mat_brillo.set_shader_parameter("filtra", 1.0)
	_mat_brillo.set_shader_parameter("reloj", _t)
	_luz.visible = true
	# La luz se mueve con él aunque el cuerpo esté oculto: va pegada a la losa.
	_raiz.position = suelo
	_luz.position = Vector3(0.0, 0.03, 0.0)
	_luz.light_energy = 0.28 * (0.8 + 0.2 * sin(_t * 3.3))

## Recogido: se hace una bola donde está y luego se estira hacia la ranura del
## cascabel y se cuela. Después, nada.
func _poner_en_bola(delta: float, bola: Vector3) -> void:
	_t += delta
	var u := clampf(c.t_estado / T_COLARSE, 0.0, 1.0)
	_sal.visible = false
	_brillo.visible = false
	_rastro.emitting = false
	_motas.emitting = false
	for f in _fatuos:
		f.visible = false
	if u >= 1.0:
		_raiz.visible = false
		_luz.visible = false
		return
	_raiz.visible = true
	_luz.visible = true
	# DOS TIEMPOS, para que en una foto fija tenga su forma: primero se HACE UNA
	# BOLA donde está (los jirones recogidos y enroscados contra el cuerpo, el
	# faldón metido, girando sobre sí mismo y mirando la ranura con los tres ojos
	# fuera de las órbitas), y solo al final se estira y se cuela de un tirón.
	# La primera versión viajaba hacia la bola desde el primer cuadro y era una
	# tortita aplastada a medio camino, igual que acorralado.
	var bola_u := smoothstep(0.0, RECOGERSE, u)
	var tiron := clampf((u - RECOGERSE) / (1.0 - RECOGERSE), 0.0, 1.0)
	var k := tiron * tiron
	var centro_ahora := _desde.lerp(bola, k)
	var hacia := bola - _desde
	var d := hacia.normalized() if hacia.length_squared() > 1e-6 else Vector3.DOWN
	var base := Basis(Vector3.UP, _yaw + bola_u * 2.2 + tiron * 6.0)
	_raiz.transform = Transform3D(base, centro_ahora - Vector3(0.0, _centro_y, 0.0))
	var redondo := Vector3.ONE.lerp(Vector3(0.80, 0.74, 0.80), bola_u)
	var s := 1.0 + 1.8 * smoothstep(0.0, 0.6, tiron)
	_forma.transform = Transform3D(_estirar((base.inverse() * d).normalized(), s)
		* Basis.from_scale(redondo * (1.0 - 0.85 * k)), Vector3(0.0, _centro_y, 0.0))
	_cuaja = 1.0 - 0.55 * k
	_destello = 0.25 * tiron
	_palidez = lerpf(_palidez, 0.55, 1.0 - exp(-6.0 * delta))
	_tapa = 0.0
	_mat_cuerpo.set_shader_parameter("encoge", bola_u)
	_mat_cuerpo.set_shader_parameter("temblor", 0.6)
	_mat_cuerpo.set_shader_parameter("arrastre", Vector3.ZERO)
	_poner_gel()
	_mover_zarcillos(delta, 1.0 + 0.6 * bola_u, Vector2.ZERO, 0.25, 7.0, 0.6, bola_u)
	for z in _zarcillos:
		(z["mat"] as ShaderMaterial).set_shader_parameter("desvanece", lerpf(DESVANECE, 0.12, bola_u))
	_mover_ojos(delta, bola, 1.5, 0.14, true, 0.0, Criatura.Estado.EN_BOLA, 1.0)
	_luz.light_energy = 0.3 * (1.0 - k)
