extends Node3D

## CRIPTA 3D — el cuerpo de la CALAVERA (`cr_calavera`), que en la caza es la
## especie «escarabajo», el acorazado. Solo LEE una `criatura.gd` y la pone en
## pantalla; no decide nada. Mismo contrato que `prueba3d/criatura_3d.gd`.
##
## EL PERSONAJE es el del sprite: una calavera de hueso con las cuencas negras,
## la boca abierta y dos manos de esqueleto. En el sprite las manos se agarran al
## borde de la ranura del cascabel; aquí, fuera de él, ANDA SOBRE ELLAS: dos
## brazos —húmero, y cúbito y radio— le salen de debajo de la bóveda y la
## llevan a rastras, con el mentón casi rozando la losa.
##
## El modelo sale de `cripta3d/blender/criatura_calavera.py` en piezas sueltas, y
## aquí se mueven por código, sin huesos ni animaciones grabadas:
##
##   1. LAS MANOS PISAN. Cada mano se queda clavada donde cayó y da el paso
##      cuando se ha quedado atrás, de una en una; el brazo se resuelve por
##      cinemática inversa. No patina andando ni girando sobre sí misma, que es
##      lo que más hace este bicho (se encara antes de andar).
##   2. PESA. El cuerpo se va a la mano que apoya, se hunde cuando levanta la
##      otra, y la mandíbula —que es un muelle suelto— castañetea a cada paso.
##   3. MIRA. En el fondo de cada cuenca hay una mota de luz fría que sigue a
##      la bola (`c.mira`), y la cabeza se le va un poco detrás.
##   3b. ARRASTRA UNA COLA: cinco vértebras, lo que le queda del espinazo, que
##      NACEN del agujero occipital y salen por su canal. Es una cola corta con
##      algo de rigidez: va a rastras detrás, da latigazos cuando rueda y se le
##      queda colgando boca arriba. Desde arriba dice dónde está la ESPALDA,
##      que es por donde hay que darle.
##   4. LO QUE LE PASA SE VE EN UNA FOTO FIJA (cada estado, con su cara):
##        · correr      la cara por delante, ladeada hacia la bola, la mandíbula
##                      batiendo y las manos tirando del cráneo a zancadas
##        · huir        el cráneo vuelto, mirando a la bola por encima del hombro,
##                      la boca abierta del todo y los brazos a toda prisa
##        · alerta      se agacha detrás de la frente y castañetea
##        · blindar()   SE CIERRA: agacha la frente hasta el suelo, la mandíbula
##                      cerrada de golpe, las manos debajo y los codos pegados; la
##                      frente se oscurece pulida y la tiza del frente echa rayas
##        · golpe       RUEDA de verdad sobre su propia forma, los brazos al aire
##        · aturdida    sentada, la mandíbula torcida y huesecillos girando
##        · volcada     boca arriba, la mandíbula colgando y las manos pataleando,
##                      con un cerco de tiza que se va borrando: el tiempo que queda
##        · en la bola  se ENROSCA —el cráneo hacia abajo, brazos y cola
##                      abrazándolo— y la bola se la lleva de un tirón
##
## HUESO, NO GOMA: el cráneo cede como mucho un 12 % al golpe, la mandíbula solo
## gira en su bisagra (nunca se separa) y codos y manos rodean la bóveda por
## fuera, nunca la atraviesan.
##
## LOS INDICADORES son de la cripta, no de neón: tiza sobre la losa
## (`calavera_tiza.gdshader`). El arco del frente dice por dónde NO le entra la
## bola; el cerco de la volcada es un reloj que se borra, de HUESO CLARO y pegado
## a ella (en oro y ancho se perdía sobre el anillo dorado de la rosa).
##
## NO SE ATRAVIESA A LA VISTA: bajo un raíl SE HUNDE en la losa (no se aplasta:
## es hueso), midiendo su pose de cada cuadro. La cuenta (`tramos_bajos`, `hueco_bajo_raiil`, `empuje`, `colocar`)
## vive aquí y la usan también BRASA y ESPECTRO: quien la toque, que mire los tres.

const Criatura := preload("res://prueba3d/criatura.gd")
const MODELO := preload("res://cripta3d/modelos/criatura_calavera.glb")
const HUESO := preload("res://cripta3d/criaturas/calavera_hueso.gdshader")
const TIZA := preload("res://cripta3d/criaturas/calavera_tiza.gdshader")
const MIRADA := preload("res://cripta3d/criaturas/calavera_mirada.gdshader")
const E := 0.01

## Las mismas capas que usa ÓRBITA: lo pintado en el suelo no sale en el reflejo
## (4) y lo menudo solo se refleja en las cámaras de cerca (8).
const CAPA_SIN_REFLEJO := 4
const CAPA_DETALLE := 8

# --- El tacto: todo lo que es pose está aquí arriba y con nombre ---------------
## Altura del centro de la bóveda cuando anda. Sale de la mandíbula: con la boca
## abierta como en el sprite, el mentón queda a un dedo de la losa.
const ALTO := 0.180
## Cabeceo de reposo (negativo = la cara hacia arriba): la cámara de juego mira
## desde lo alto, y una cara vertical solo se vería de frente.
const CABECEO := -0.36
const BOCA := 0.38
const BOCA_MAX := 0.92
## Dónde apoya cada mano respecto al centro, y cuánto abre los dedos hacia fuera.
const ABRE_X := 0.190
const ABRE_Z := 0.062
const GIRO_MANO := 0.42
const ZANCADA := 0.115
const ALZADA := 0.050
## Los elipsoides de la bóveda (centro y radios, en el cráneo): sobre ellos rueda.
const BOVEDA := [
	[Vector3(0.0, 0.008, -0.014), Vector3(0.122, 0.106, 0.134)],
	[Vector3(0.0, -0.020, -0.060), Vector3(0.103, 0.080, 0.083)],
	[Vector3(0.0, 0.028, 0.060), Vector3(0.102, 0.080, 0.064)],
]

## VOLCADA: el cabeceo de patas arriba (más allá de −π/2: sobre la coronilla, con
## la cara del revés), lo que dura la voltereta y lo alto que salta al darla.
const CABECEO_VOLCADA := -2.05
const VUELCO_T := 0.26
const VUELCO_ALTO := 0.085

## La cola: cinco vértebras, cada una más pequeña (los mismos números que en
## `cripta3d/blender/criatura_calavera.py`: talla de cada una, separación a
## talla 1 y lo que levanta del suelo el centro de una vértebra tumbada).
const COLA_TALLAS := [1.0, 0.87, 0.75, 0.64, 0.54]
const COLA_PASO := 0.040
const COLA_RADIO := 0.0145
## Lo que se resiste la cola a doblarse: la primera vértebra, casi nada (sale
## del canal); las demás, un poco (es espinazo, no cuerda).
const COLA_RIGIDEZ := [0.60, 0.34, 0.28, 0.22, 0.18]

## EL MARFIL. El sprite es hueso frío con sombras gris-pardas; con los tonos
## TIERRA de la paleta, bajo el fuego de la cripta salía melocotón y se perdía en
## la losa. Desde arriba tiene que ser la mancha más clara de la escena.
## Y FRÍO DE VERDAD: con la base en (0,85, 0,80, 0,68) —un crema— el fuego de la
## cripta la volvía «plastilina naranja» (crítica de arte, nov-2026). El hueso
## viejo es gris marfil; el calor se lo pone la luz que le llegue, no el albedo.
const MARFIL_LUZ := Color(0.90, 0.90, 0.86)
const MARFIL := Color(0.76, 0.75, 0.70)
const MARFIL_MEDIO := Color(0.58, 0.57, 0.54)
const MARFIL_SOMBRA := Color(0.37, 0.37, 0.36)
const MARFIL_MUGRE := Color(0.19, 0.19, 0.20)

## La bóveda vista como una caja de choque para los brazos y la cola (en el
## cráneo): codos, manos y vértebras la rodean por fuera.
const CASCO_CENTRO := Vector3(0.0, -0.004, -0.016)
const CASCO_RADIOS := Vector3(0.128, 0.104, 0.142)

## NO SE ATRAVIESAN A LA VISTA (remate, nov-2026). Los dos tubos de la escalera
## pasaban por dentro del cráneo, y el espectro se le metía dentro con los ojos
## saliendo por la cuenca. La caza decide dónde está cada una y eso NO se toca:
## lo que se aparta es el DIBUJO. Lo usan los tres cuerpos desde aquí (`brasa.gd`
## y `espectro.gd` precargan este guion) para que los tres midan igual:
##   · BAJO UN RAÍL BAJO, SE AGACHA: se mira el hueco entre el suelo que pisa y el
##     carril que tiene encima (la misma `altura_rampa` del núcleo con la que se
##     dibujan los raíles) y el cuerpo se aplasta en altura lo justo, con un pelo
##     de bulto a los lados para que siga pesando. ESO VALE PARA LA BRASA (fuego)
##     Y EL ESPECTRO (gelatina), NO PARA ESTA: la calavera aplastada hasta 0,42 y
##     ensanchada salía hecha una TORTITA bajo la escalera, y el raíl le seguía
##     cruzando las cuencas (los tres críticos, nov-2026). El hueso no se aplasta:
##     encoge como mucho a `ESCALA_MIN` (igual en los tres ejes, la misma silueta)
##     y lo que falte SE HUNDE en la losa, como cuando sale de la rosa: baja el
##     pivote, el hueso deja de pintarse por debajo del suelo (`corte`) y la tiza
##     pinta la fosa. Es una calavera que sale de la tierra (`_colocar_hueso`);
##   · A MENOS DE `UMBRAL_APARTE` DE OTRA, SE HACE A UN LADO quien ceda: el
##     espectro ante todas, y además sube; la brasa ante la calavera; la calavera
##     ante nadie (es la que pesa).
## Va como la transformada del propio nodo del cuerpo, con el pivote en el suelo
## que pisa: sirve igual para los tres y no toca su animación.
const UMBRAL_APARTE := 0.35
## Lo más que se desplaza el dibujo: la bola sigue chocando donde dice la caza, y
## un cuerpo muy lejos de su sitio engañaría al jugador.
const APARTE_MAX := 0.16
## Lo más que se aplastan la BRASA y el ESPECTRO (fuego y gelatina; la calavera
## no se aplasta nunca: ver `ESCALA_MIN`).
const AGACHE_MIN := 0.42
## Lo más que encoge la calavera bajo un raíl, IGUAL EN LOS TRES EJES: es hueso y
## sigue siendo la misma silueta. Por debajo de 0,85 ya no es la del visor.
const ESCALA_MIN := 0.90
## Lo que asoma de ella, como poco, por hundida que esté: la coronilla con el
## arranque de las cuencas. Del todo bajo la losa el jugador perdería el blanco.
const ASOMA_MIN := 0.075
## Lo que queda por debajo de la altura del recorrido: el carril (centro a
## 0,0045 y radio 0,0115 en `railes.gd`) y un pelo de aire.
const BAJO_RAIL := 0.016
## Media anchura del raíl en planta: los guardarraíles van a ±0,11 y miden 0,01.
const ANCHO_RAIL := 0.12
## Lo alta que es la calavera andando, por si aún no tiene pose que medir. Lo que
## se usa de verdad es `_alto_visible()`, que mide la pose de cada cuadro.
const ALTO_CUERPO := 0.31

class Brazo:
	var lado := 1.0
	var hombro := Vector3.ZERO
	var humero: MeshInstance3D
	var antebrazo: MeshInstance3D
	var mano: MeshInstance3D
	var dedos: Array[Node3D] = []
	var reposo_dedos: Array[Transform3D] = []
	## Dónde pisa: la muñeca, a ras de suelo.
	var pie := Vector3.ZERO
	var desde := Vector3.ZERO
	var alto_desde := 0.0
	var arco := 0.05
	var u := 1.0
	var dura := 0.16
	var en_aire := false
	## Hacia dónde apuntan los dedos. Se fija al pisar.
	var giro := 0.0
	var giro_desde := 0.0
	var muneca := Vector3.ZERO
	var eje := Vector3.RIGHT
	## 0 = mano posada, derecha sobre el suelo; 1 = suelta, sigue al antebrazo.
	var suelta := 0.0

var c: Criatura
## A qué altura está el suelo que pisa.
var y_base := 0.0
var t_cierre := 5.0
var t_volcada := 5.0
var arco_blindaje := 70.0

var _raiz: Node3D          # se mueve, gira, cabecea y rueda
var _forma: Node3D         # dentro: se aplasta contra el golpe y se estira hacia la bola
var _miembros: Node3D      # brazos y manos: van en coordenadas de mesa
var _craneo: MeshInstance3D
var _mandibula: MeshInstance3D
var _brazos: Array[Brazo] = []
var _mats: Array[ShaderMaterial] = []
var _mat_tiza: ShaderMaterial
var _mat_mirada: ShaderMaterial
var _tiza: MeshInstance3D
var _ojos: Array[MeshInstance3D] = []
var _ojos_centro: Array[Vector3] = []
var _huesecillos: Node3D
var _esquirlas: Array[CPUParticles3D] = []
var _polvos: Array[CPUParticles3D] = []
var _turno_esquirla := 0
var _turno_polvo := 0

var _bisagra := Vector3(0.0, -0.084, -0.006)
var _menton := Vector3(0.0, -0.080, 0.124)
var _l1 := 0.116
var _l2 := 0.116
var _h_muneca := 0.0324

var _tiempo := 0.0
var _yaw := 0.0
var _orient := Quaternion.IDENTITY
var _alto := ALTO
var _alto_v := 0.0
var _boca := BOCA
var _boca_v := 0.0
var _desencaje := 0.0
var _lado_desencaje := 1.0
var _estado_antes := -1
var _destello := 0.0
var _choque := 0.0
var _plantada := 0.0
var _aviso_t := 0.0
var _aro_aviso := 0.0
var _pies_puestos := false
var _golpe_t := 9.0
var _golpe_n := Vector3.FORWARD
var _parada := 0.0
var _desde_recogida := Vector3.ZERO
var _t_circulo := 0.0
var _escudo := 0.0
var _contacto := 0.0
var _parpadeo := 0.0
var _prox_parpadeo := 2.0
var _mira_ojos := Vector2.ZERO
var _fuerza_ojos := 1.0
var _manos_fuera := false
var _ultima_mano := 0
var _cola: Array[MeshInstance3D] = []
var _cola_p := PackedVector3Array()
var _cola_a := PackedVector3Array()
var _cola_puesta := false
var _nuca := Vector3(0.0, -0.106, -0.058)
## Hacia dónde sale el canal de la nuca, en el cráneo.
var _canal := Vector3(0.0, -0.62, -0.78)
## 0 a 1: cuánto está cerrada en blindaje (la pose y la frente pulida).
var _blindaje := 0.0
## 1 = codos abiertos de cangrejo; menos, pegados al cuerpo.
var _codos := 1.0
var _giro_mira := 0.0
var _espera_tambor := 0.9
var _tambor_t := 9.0
var _tambor_mano := 0
## Lo de no atravesarse (ver `UMBRAL_APARTE`): los raíles por encima de la losa,
## cuánto está agachada (1 = nada) y lo que se ha hecho a un lado.
var _tramos: Array[Dictionary] = []
var _tramos_listos := false
var _agache := 1.0
var _aparte := Vector3.ZERO
## Lo que está metida bajo la losa (unidades 3D) y lo que ha encogido (1 = nada).
var _hundido := 0.0
var _escala := 1.0

# ------------------------------------------------------------------- montaje

func montar(criatura: Criatura, _fuente: Font) -> void:
	c = criatura
	_raiz = Node3D.new()
	add_child(_raiz)
	_forma = Node3D.new()
	_raiz.add_child(_forma)
	_miembros = Node3D.new()
	add_child(_miembros)

	var escena := MODELO.instantiate() as Node3D
	var mat_craneo := _material(1.0, 1.0, Vector3.ZERO, 1.0, 1.0)
	_craneo = _sacar(escena, "craneo", _forma, mat_craneo)
	_mandibula = _craneo.get_node_or_null("mandibula") as MeshInstance3D
	if _mandibula != null:
		_mandibula.material_override = _material(0.0, 1.0, Vector3(3.1, 7.7, 1.3), 0.6, 0.7)
		_bisagra = _mandibula.position
		_menton = _marca(_mandibula, "menton", _menton)

	for lado: float in [1.0, -1.0]:
		var sufijo := "i" if lado > 0.0 else "d"
		var b := Brazo.new()
		b.lado = lado
		b.hombro = _marca(_craneo, "hombro_" + sufijo, Vector3(0.078 * lado, -0.076, -0.046))
		var mat := _material(0.0, 1.7, Vector3(5.3 * lado, 2.1, 9.4))
		b.humero = _sacar(escena, "humero_" + sufijo, _miembros, mat)
		b.antebrazo = _sacar(escena, "antebrazo_" + sufijo, _miembros, mat)
		b.mano = _sacar(escena, "mano_" + sufijo, _miembros, mat)
		_l1 = _marca(b.humero, "codo_" + sufijo, Vector3(0.0, _l1, 0.0)).y
		_l2 = _marca(b.antebrazo, "muneca_" + sufijo, Vector3(0.0, _l2, 0.0)).y
		_h_muneca = -_marca(b.mano, "apoyo_" + sufijo, Vector3(0.0, -_h_muneca, 0.0)).y
		# Los tres dedos (0, 1, 2) y el pulgar el último, vengan como vengan.
		for nombre: String in ["dedo_%s_0" % sufijo, "dedo_%s_1" % sufijo,
				"dedo_%s_2" % sufijo, "pulgar_" + sufijo]:
			var dedo := b.mano.get_node_or_null(nombre) as MeshInstance3D
			if dedo == null:
				push_warning("calavera: a la mano le falta «%s»" % nombre)
				continue
			dedo.material_override = mat
			b.dedos.append(dedo)
			b.reposo_dedos.append(dedo.transform)
		_brazos.append(b)
		_ojos_centro.append(_marca(_craneo, "ojo_" + sufijo, Vector3(0.050 * lado, 0.004, 0.086)))

	_nuca = _marca(_craneo, "nuca", _nuca)
	var canal := _marca(_craneo, "nuca_canal", _nuca + _canal * 0.03) - _nuca
	if canal.length_squared() > 1e-8:
		_canal = canal.normalized()
	var mat_cola := _material(0.0, 2.0, Vector3(6.6, 1.2, 4.9), 0.0, 0.3)
	for i in COLA_TALLAS.size():
		_cola.append(_sacar(escena, "vertebra_%d" % i, _miembros, mat_cola))
	_cola_p.resize(_cola.size() + 1)
	_cola_a.resize(_cola.size() + 1)

	_montar_mirada()
	_montar_huesecillos(escena)
	escena.free()
	_montar_suelo()
	_montar_particulas()
	_prox_parpadeo = 1.5 + float(c.indice) * 0.7
	_ocultar()

func _material(con_suturas: float, detalle: float, semilla: Vector3,
		roce: float = 0.0, grietas: float = 0.4) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = HUESO
	m.set_shader_parameter("hueso_luz", MARFIL_LUZ)
	m.set_shader_parameter("hueso", MARFIL)
	m.set_shader_parameter("hueso_medio", MARFIL_MEDIO)
	m.set_shader_parameter("hueso_sombra", MARFIL_SOMBRA)
	m.set_shader_parameter("mugre", MARFIL_MUGRE)
	m.set_shader_parameter("hondo", Paleta.NEGRO)
	m.set_shader_parameter("suturas", con_suturas)
	m.set_shader_parameter("escala_detalle", detalle)
	m.set_shader_parameter("semilla", semilla)
	m.set_shader_parameter("roce", roce)
	m.set_shader_parameter("grietas", grietas)
	_mats.append(m)
	return m

## Saca una pieza del modelo y la cuelga de donde se va a mover.
func _sacar(escena: Node3D, nombre: String, padre: Node3D, mat: Material) -> MeshInstance3D:
	var pieza := escena.find_child(nombre, true, false) as MeshInstance3D
	if pieza == null:
		push_warning("calavera: al modelo le falta la pieza «%s»" % nombre)
		pieza = MeshInstance3D.new()
	else:
		_soltar_dueno(pieza)
		pieza.get_parent().remove_child(pieza)
	padre.add_child(pieza)
	pieza.transform = Transform3D.IDENTITY
	pieza.material_override = mat
	return pieza

## La pieza deja de ser de la escena del modelo: si no, al cambiarla de padre
## Godot avisa de que el dueño ya no cuadra.
func _soltar_dueno(nodo: Node) -> void:
	nodo.owner = null
	for hijo in nodo.get_children():
		_soltar_dueno(hijo)

## Una marca es un nodo vacío del modelo: dónde está el hombro, el mentón, el codo.
func _marca(padre: Node, nombre: String, por_defecto: Vector3) -> Vector3:
	var nodo := padre.get_node_or_null(nombre) as Node3D
	return nodo.position if nodo != null else por_defecto

## SIN PUPILAS. Hubo una mota de luz fría al fondo de cada cuenca que seguía a la
## bola; en la mesa se leía como la pupila de un dibujo animado, y el sprite tiene
## las cuencas NEGRAS Y VACÍAS (crítica de arte, nov-2026). La mirada la cuentan
## ahora la cabeza, que se ladea hacia la bola, y la pose. El material se crea
## igual —`_tragar` y `_mover_mirada` lo tocan—, pero no hay motas que pintar.
const CON_PUPILAS := false

func _montar_mirada() -> void:
	_mat_mirada = ShaderMaterial.new()
	_mat_mirada.shader = MIRADA
	_mat_mirada.set_shader_parameter("color", Paleta.AZUL_LUZ.lerp(Paleta.BLANCO, 0.55))
	if not CON_PUPILAS:
		return
	var mota := SphereMesh.new()
	mota.radius = 0.0105
	mota.height = 0.021
	mota.radial_segments = 12
	mota.rings = 6
	for centro in _ojos_centro:
		var ojo := MeshInstance3D.new()
		ojo.mesh = mota
		ojo.material_override = _mat_mirada
		ojo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ojo.layers = CAPA_DETALLE
		ojo.position = centro
		_craneo.add_child(ojo)
		_ojos.append(ojo)

## Los huesecillos que le dan vueltas cuando está aturdida.
func _montar_huesecillos(escena: Node3D) -> void:
	_huesecillos = Node3D.new()
	_miembros.add_child(_huesecillos)
	var molde := escena.find_child("huesecillo", true, false) as MeshInstance3D
	if molde == null:
		return
	var mat := _material(0.0, 2.4, Vector3(1.7, 4.2, 8.8))
	for i in 4:
		var hueso := MeshInstance3D.new()
		hueso.mesh = molde.mesh
		hueso.material_override = mat
		hueso.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hueso.layers = CAPA_DETALLE
		_huesecillos.add_child(hueso)
	_huesecillos.visible = false

func _montar_suelo() -> void:
	var plano := PlaneMesh.new()
	var lado := c.radio * E * 4.9
	plano.size = Vector2(lado, lado)
	_mat_tiza = ShaderMaterial.new()
	_mat_tiza.shader = TIZA
	_mat_tiza.set_shader_parameter("color", Paleta.TIERRA_6)
	_mat_tiza.set_shader_parameter("arco", deg_to_rad(arco_blindaje))
	_mat_tiza.set_shader_parameter("semilla", 1.0 + float(c.indice) * 2.7)
	# El cerco de rendida, de HUESO CLARO y no de oro: en oro se confundía con el
	# anillo dorado de la rosa, que es donde suele rendirse (remate, nov-2026).
	_mat_tiza.set_shader_parameter("color_cerco", Paleta.TIERRA_6)
	_mat_tiza.set_shader_parameter("radio_cerco", 0.60)
	_tiza = MeshInstance3D.new()
	_tiza.mesh = plano
	_tiza.material_override = _mat_tiza
	_tiza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_tiza.layers = CAPA_SIN_REFLEJO
	add_child(_tiza)

## Esquirlas de hueso y polvo. Todo de un disparo y con vida corta: caduca solo.
func _montar_particulas() -> void:
	var trozo := PrismMesh.new()
	trozo.size = Vector3(0.011, 0.008, 0.0045)
	trozo.left_to_right = 0.28
	var mat_trozo := _material(0.0, 3.0, Vector3(9.1, 0.4, 2.2))
	mat_trozo.set_shader_parameter("relieve", 0.0)
	var mengua := Curve.new()
	mengua.add_point(Vector2(0.0, 1.0))
	mengua.add_point(Vector2(0.7, 0.9))
	mengua.add_point(Vector2(1.0, 0.0))
	for i in 2:
		var p := CPUParticles3D.new()
		p.mesh = trozo
		p.material_override = mat_trozo
		p.emitting = false
		p.one_shot = true
		p.amount = 14
		p.lifetime = 0.75
		p.explosiveness = 0.94
		p.randomness = 0.5
		p.local_coords = false
		p.spread = 48.0
		p.gravity = Vector3(0.0, -2.6, 0.0)
		p.initial_velocity_min = 0.45
		p.initial_velocity_max = 1.25
		p.scale_amount_min = 0.5
		p.scale_amount_max = 1.5
		p.scale_amount_curve = mengua
		# Cada astilla, girada a su manera y dando vueltas. Y el color de la
		# partícula es el color de vértice que lee el hueso: oclusión, canto,
		# diente. Así sale hueso corriente, no esmalte encendido.
		p.particle_flag_rotate_y = true
		p.angle_min = -180.0
		p.angle_max = 180.0
		p.angular_velocity_min = -900.0
		p.angular_velocity_max = 900.0
		p.color = Color(0.72, 0.25, 0.0, 1.0)
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		p.layers = CAPA_DETALLE
		add_child(p)
		_esquirlas.append(p)

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
	var mat_polvo := StandardMaterial3D.new()
	mat_polvo.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat_polvo.roughness = 1.0
	mat_polvo.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat_polvo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_polvo.albedo_texture = redonda
	mat_polvo.vertex_color_use_as_albedo = true
	mat_polvo.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat_polvo.billboard_keep_scale = true
	mat_polvo.cull_mode = BaseMaterial3D.CULL_DISABLED
	var nube := QuadMesh.new()
	nube.size = Vector2(1.0, 1.0)
	var crece := Curve.new()
	crece.add_point(Vector2(0.0, 0.35))
	crece.add_point(Vector2(0.35, 0.85))
	crece.add_point(Vector2(1.0, 1.0))
	# Polvo de hueso: del color de la piedra con un punto de hueso. No es luz:
	# recibe la de la cripta como todo lo demás, así que a oscuras es oscuro y
	# junto al fuego se ve. (Sin sombreado era una mancha sucia sobre el suelo.)
	var tono := Paleta.PIEDRA_4.lerp(Paleta.TIERRA_5, 0.5)
	var rampa := Gradient.new()
	rampa.set_color(0, Color(tono.r, tono.g, tono.b, 0.0))
	rampa.set_color(1, Color(tono.r, tono.g, tono.b, 0.0))
	rampa.add_point(0.15, Color(tono.r, tono.g, tono.b, 0.36))
	for i in 3:
		var p := CPUParticles3D.new()
		p.mesh = nube
		p.material_override = mat_polvo
		p.emitting = false
		p.one_shot = true
		p.amount = 14
		p.lifetime = 0.85
		p.explosiveness = 0.86
		p.randomness = 0.6
		p.local_coords = false
		p.spread = 62.0
		p.gravity = Vector3(0.0, 0.12, 0.0)
		p.initial_velocity_min = 0.10
		p.initial_velocity_max = 0.42
		p.damping_min = 0.9
		p.damping_max = 1.6
		p.scale_amount_min = 0.035
		p.scale_amount_max = 0.095
		p.scale_amount_curve = crece
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.035
		p.color_ramp = rampa
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		p.layers = CAPA_DETALLE
		add_child(p)
		_polvos.append(p)

func _esquirlar(punto: Vector3, hacia: Vector3, cuantas: int, empuje: float) -> void:
	if _esquirlas.is_empty():
		return
	var p := _esquirlas[_turno_esquirla]
	_turno_esquirla = (_turno_esquirla + 1) % _esquirlas.size()
	p.position = _sobre_la_losa(punto)
	p.direction = hacia.normalized() if hacia.length_squared() > 1e-6 else Vector3.UP
	p.amount = cuantas
	p.initial_velocity_min = 0.45 * empuje
	p.initial_velocity_max = 1.25 * empuje
	p.restart()
	p.emitting = true

func _soplar(punto: Vector3, hacia: Vector3, cuantas: int, empuje: float) -> void:
	if _polvos.is_empty():
		return
	var p := _polvos[_turno_polvo]
	_turno_polvo = (_turno_polvo + 1) % _polvos.size()
	p.position = _sobre_la_losa(punto)
	p.direction = hacia.normalized() if hacia.length_squared() > 1e-6 else Vector3.UP
	p.amount = cuantas
	p.initial_velocity_min = 0.10 * empuje
	p.initial_velocity_max = 0.42 * empuje
	p.restart()
	p.emitting = true

# ------------------------------------------------------------------- sucesos

## El golpe: salta hueso, la mandíbula se descuelga y el cuerpo cede contra el
## impacto. `normal` va de la criatura a la bola.
func golpear(normal: Vector2) -> void:
	_destello = 1.0
	_golpe_t = 0.0
	_golpe_n = Vector3(normal.x, 0.0, normal.y)
	_parada = 0.05
	_boca_v += 11.0
	if _raiz == null:
		return
	var punto := _raiz.position + _golpe_n * 0.11
	_esquirlar(punto, _golpe_n * 0.6 + Vector3(0.0, 1.0, 0.0), 14, 1.0)
	_soplar(punto, _golpe_n * 0.4 + Vector3(0.0, 0.6, 0.0), 8, 1.2)

## La frente ha parado la bola: SE CIERRA. La mandíbula se cierra de golpe
## (dientes contra dientes), agacha la frente hasta el suelo, mete las manos y
## pega los codos. Salta algo de polvo de hueso, poco: lo que se lee es la pose.
func blindar() -> void:
	_choque = 1.0
	_plantada = 1.0
	_destello = 0.0
	_boca_v = -26.0
	if _raiz == null:
		return
	var adelante := Basis(Vector3.UP, _yaw) * Vector3(0.0, 0.0, 1.0)
	var frente := _raiz.transform * Vector3(0.0, 0.035, 0.128)
	_esquirlar(frente, adelante + Vector3(0.0, 0.75, 0.0), 6, 0.9)
	_soplar(frente, adelante * 0.7 + Vector3(0.0, 0.5, 0.0), 9, 1.3)

func avisar_aro() -> void:
	_aro_aviso = 1.0

func color() -> Color:
	return MARFIL

## Dónde está el centro del cuerpo, para que la cámara y los efectos lo sigan.
## Con lo que se haya agachado o apartado (la transformada del propio nodo).
func centro() -> Vector3:
	return transform * _raiz.position

func _ocultar() -> void:
	_quieto()
	_raiz.visible = false
	_miembros.visible = false
	_tiza.visible = false
	_huesecillos.visible = false
	_cola_puesta = false

# --------------------------------------------------------------- cada cuadro

## `bola` es dónde está la bola que la lleva, si va dentro de una.
func actualizar(delta: float, bola: Vector3) -> void:
	_tiempo += delta
	var estado := c.estado
	var suelo := Vector3(c.pos.x * E, y_base, c.pos.y * E)
	if estado != _estado_antes:
		_al_cambiar(estado, suelo)
		_estado_antes = estado

	if not c.activa or estado == Criatura.Estado.FUERA \
			or estado == Criatura.Estado.ESCONDIDA:
		# Fuera no hay golpe que enseñar: si se quedara guardado, saltaría al volver.
		_parada = 0.0
		_destello = 0.0
		_choque = 0.0
		_plantada = 0.0
		_golpe_t = 9.0
		_ocultar()
		return
	if estado == Criatura.Estado.EN_BOLA:
		# En la bola va a donde va la bola: sin agacharse ni apartarse.
		_quieto()
		_tragar(delta, bola)
		return

	# La calavera no cede ante nadie: solo se agacha bajo un raíl. Con lo que mide
	# DE VERDAD en la pose que tiene: volcada, con la mandíbula al cielo y las manos
	# pataleando, pasa de 0,36, y con una altura fija (0,31) se agachaba de menos y
	# el raíl de la boca de la catacumba (a 0,285) le seguía cruzando la cara.
	# Y no se aplasta: se hunde (`_colocar_hueso`).
	_agacharse_hueso(delta, suelo, _alto_visible())
	_raiz.visible = true
	_destello = maxf(_destello - delta * 5.0, 0.0)
	_choque = maxf(_choque - delta * 3.2, 0.0)
	_plantada = maxf(_plantada - delta, 0.0)
	_aviso_t = maxf(_aviso_t - delta, 0.0)
	_aro_aviso = maxf(_aro_aviso - delta * 3.0, 0.0)

	# La parada del golpe: 50 ms con la pose congelada y ya aplastada. Solo aquí,
	# en lo que se ve: la mesa no se detiene.
	if _parada > 0.0:
		_parada -= delta
		_forma.transform = Transform3D(_ceder(0.0), Vector3.ZERO)
		_pintar_golpe(0.0)
		return

	var v3 := Vector3(c.vel.x, 0.0, c.vel.y) * E
	var rapidez := v3.length()
	var adelante := Vector3(c.rumbo.x, 0.0, c.rumbo.y)
	if adelante.length_squared() < 1e-6:
		adelante = Vector3(0.0, 0.0, 1.0)
	adelante = adelante.normalized()
	_yaw = lerp_angle(_yaw, atan2(adelante.x, adelante.z), 1.0 - exp(-14.0 * delta))

	# --- La pose de cada estado -----------------------------------------------
	var en_suelo := estado == Criatura.Estado.CORRER or estado == Criatura.Estado.HUIR
	var apoyada := false
	var alto := ALTO
	var cabeceo := CABECEO
	var balanceo := 0.0
	var guinada := 0.0
	var boca := BOCA
	var firmeza := 12.0
	var abre := 1.0
	var garra := 0.0
	var tiembla := 0.0
	var corte := -1000.0
	var desencaje := 0.0
	var aire_i := _aire(_brazos[0])
	var aire_d := _aire(_brazos[1])
	# Lo que sube por encima de su apoyo al volcarse (el salto de la voltereta).
	var vuelco_salto := 0.0

	if en_suelo:
		apoyada = true
		var huye := estado == Criatura.Estado.HUIR
		var anda_ya := rapidez > 0.03
		# El peso: se va a la mano que apoya, se hunde al levantar la otra y da
		# la cabezada del tirón.
		balanceo = 0.085 * (aire_i - aire_d)
		guinada = 0.075 * (aire_d - aire_i)
		alto = ALTO - 0.012 * (aire_i + aire_d) + 0.003 * sin(_tiempo * 2.3)
		cabeceo = CABECEO + 0.05 * (aire_i + aire_d) + 0.012 * sin(_tiempo * 1.7)
		# Hacia dónde le queda la bola, respecto a hacia dónde va.
		var hacia_bola := Vector2(c.mira.x - c.pos.x, c.mira.y - c.pos.y)
		var a_la_bola := 0.0
		if hacia_bola.length_squared() > 4.0:
			a_la_bola = angle_difference(_yaw, atan2(hacia_bola.x, hacia_bola.y))
		var quiere := 0.0
		var prisa_mira := 3.5
		if huye:
			# HUIR: no corre más —es lo que es—, pero mira atrás. El cráneo vuelto
			# hacia la bola por encima del hombro y ECHADO ATRÁS, la cara casi al
			# cielo: la cámara del juego mira desde arriba, y así las cuencas y la
			# boca abierta del todo se le ven siempre, huya hacia donde huya
			# (girada hacia la bola sin más, desde arriba se le veía la nuca). Los
			# brazos, a toda prisa, con el cuerpo tirado hacia un lado.
			var lado_bola := signf(a_la_bola) if absf(a_la_bola) > 0.05 else 1.0
			quiere = lado_bola * clampf(absf(a_la_bola), 0.90, 1.25)
			prisa_mira = 7.0
			balanceo = 0.16 * (aire_i - aire_d) + 0.24 * lado_bola
			cabeceo = CABECEO - 0.86 + 0.06 * (aire_i + aire_d)
			alto -= 0.010
			boca = 0.86 + 0.10 * sin(_tiempo * 33.0)
			tiembla = 0.25
		elif anda_ya:
			# CORRER: de cara. La frente por delante y ladeada hacia la bola, la
			# mandíbula batiendo a cada zancada y el cráneo tirado por las manos.
			# Es lo contrario de huir: la cara POR DELANTE (no echada atrás), algo
			# levantada para que desde arriba se le vean las cuencas, y cabeceando
			# hacia abajo a cada tirón de las manos.
			# No GIRA la cara hacia la bola (de lado se perdía la cara y quedaba la
			# bóveda): se INCLINA hacia ella, ladeando el cráneo.
			quiere = clampf(a_la_bola, -0.12, 0.12)
			balanceo -= 0.14 * clampf(a_la_bola, -1.0, 1.0)
			cabeceo = -0.24 + 0.16 * (aire_i + aire_d) + 0.012 * sin(_tiempo * 1.7)
			alto -= 0.006
			boca = 0.10 + 0.60 * (aire_i + aire_d)
		else:
			# Parada: curiosea, la cabeza un poco hacia la bola.
			quiere = clampf(a_la_bola, -0.16, 0.16)
		_giro_mira = lerpf(_giro_mira, quiere, 1.0 - exp(-prisa_mira * delta))
		guinada += _giro_mira
		balanceo += _giro_mira * (0.0 if huye else 0.35)
	elif estado == Criatura.Estado.ALERTA:
		# La anticipación: se agacha tras la frente y castañetea.
		apoyada = true
		alto = ALTO - 0.030
		cabeceo = CABECEO + 0.44
		boca = 0.02 + 0.15 * (0.5 + 0.5 * sin(_tiempo * 58.0))
		garra = 0.38
		abre = 0.92
		tiembla = 0.8
		firmeza = 22.0
	elif estado == Criatura.Estado.VOLAR:
		# Por los aires: RUEDA de verdad, lo que avanza, y sobre su propia forma.
		if rapidez > 0.02:
			var eje := Vector3.UP.cross(v3 / rapidez)
			_orient = (Quaternion(eje, rapidez * delta / 0.118) * _orient).normalized()
		var t := c.t_estado
		alto = _apoyo(Basis(_orient)) + 0.10 * absf(sin(t * 10.0)) * exp(-t * 3.4)
		boca = 0.42 + 0.26 * sin(t * 24.0)
	elif estado == Criatura.Estado.ATURDIDA:
		# Sentada en la losa, la cabeza dándole vueltas y la mandíbula desencajada.
		apoyada = true
		firmeza = 7.0
		cabeceo = -0.52 + 0.09 * sin(_tiempo * 2.9)
		balanceo = 0.30 * _lado_desencaje + 0.11 * sin(_tiempo * 2.3 + 1.0)
		guinada = 0.12 * sin(_tiempo * 1.9)
		boca = 0.66
		desencaje = 1.0
		abre = 1.26
		garra = -0.34
		alto = -1.0   # se posa: la altura la dice su propia forma
	elif estado == Criatura.Estado.VOLCADA:
		# PATAS ARRIBA, del todo: sobre la coronilla, con la cara del revés y la
		# mandíbula al cielo. Antes se quedaba en −1,50 (la cara mirando al cielo) y
		# tardaba en llegar (firmeza 9): desde la cámara de juego, que mira desde
		# arriba, una cara al cielo es casi la misma foto que la de andar, y el
		# jugador la veía «igual que antes» durante un segundo (crítica de juego,
		# nov-2026). Una cara DEL REVÉS se lee al instante.
		# El vuelco va en VUELCO_T: un salto con la voltereta y un rebote al caer.
		var t := c.t_estado
		firmeza = 30.0 if t < VUELCO_T else 9.0
		var queda := 1.0 - clampf(t / maxf(t_volcada, 0.1), 0.0, 1.0)
		# Cuanto menos le queda, más patalea y más se balancea: va a darse la vuelta.
		var afan := 1.0 + (1.0 - queda) * 0.8
		# Y se vuelca DE ESPALDAS A LA CÁMARA, para caer con la cara hacia ella y del
		# revés: la coronilla hacia el jugador, el mentón hacia el fondo. Volcada
		# hacia donde fuera, a veces enseñaba la base del cráneo y la mandíbula, y
		# se leía como un cuenco con brazos.
		_yaw = lerp_angle(_yaw, _de_espaldas_a_la_camara(suelo), 1.0 - exp(-22.0 * delta))
		cabeceo = CABECEO_VOLCADA + 0.08 * sin(_tiempo * 4.3 * afan)
		balanceo = (0.20 + 0.12 * (1.0 - queda)) * sin(_tiempo * 5.3 * afan)
		boca = 0.80 + 0.12 * sin(_tiempo * 8.7 * afan)
		alto = -1.0
		vuelco_salto = _salto_vuelco(t)
	elif estado == Criatura.Estado.APARECER:
		# Sale de la losa como de una fosa: primero la bóveda, luego las manos de
		# un manotazo, y se iza.
		var u := clampf(c.t_estado / 0.6, 0.0, 1.0)
		apoyada = u > 0.34
		corte = y_base + 0.002
		firmeza = 10.0
		var sube := smoothstep(0.0, 0.62, u)
		var iza := smoothstep(0.55, 1.0, u)
		alto = lerpf(-0.135, 0.085, sube) + (ALTO - 0.085) * iza
		cabeceo = lerpf(-0.95, CABECEO, smoothstep(0.25, 1.0, u))
		boca = lerpf(0.20, BOCA, iza)
		garra = 0.30 * (1.0 - iza)

	# --- BLINDADA: se cierra, venga de donde venga mientras pise --------------------
	# Entra de golpe (en 50 ms ya está) y sale despacio al final. Es la silueta
	# contraria a la de reposo: abierta y con la boca abierta, contra cerrada,
	# agachada y con las manos dentro.
	var cierra := 0.0
	if _plantada > 0.0 and apoyada and estado != Criatura.Estado.APARECER:
		cierra = smoothstep(1.0, 0.95, _plantada) * smoothstep(0.0, 0.25, _plantada)
		cabeceo = lerpf(cabeceo, 0.80, cierra)
		guinada = lerpf(guinada, 0.0, cierra)
		balanceo = lerpf(balanceo, 0.0, cierra)
		boca = lerpf(boca, 0.0, cierra)
		abre = lerpf(abre, 0.46, cierra)
		garra = maxf(garra, 0.55 * cierra)
		firmeza = lerpf(firmeza, 40.0, cierra)
		tiembla = maxf(tiembla, _choque * 0.6)
	_blindaje = move_toward(_blindaje, cierra, delta * 9.0)
	_codos = lerpf(1.0, 0.10, _blindaje)

	# --- Orientación y altura --------------------------------------------------
	if estado != Criatura.Estado.VOLAR:
		var objetivo := Quaternion(Basis(Vector3.UP, _yaw + guinada) \
			* Basis(Vector3.RIGHT, cabeceo) * Basis(Vector3.BACK, balanceo))
		_orient = _orient.slerp(objetivo, 1.0 - exp(-firmeza * delta)).normalized()
	var giro := Basis(_orient)
	var apoyo := _apoyo(giro)
	if alto < 0.0 and estado != Criatura.Estado.APARECER:
		alto = apoyo
	if cierra > 0.0:
		# Con la frente agachada lo más bajo es el mentón cerrado: se posa en él.
		alto = lerpf(alto, maxf(apoyo, _alto_menton(giro)), cierra)
	alto += vuelco_salto
	# El salto del vuelco va a pelo, sin el muelle: con él llegaba tarde y chato.
	var volcandose := estado == Criatura.Estado.VOLCADA and c.t_estado < VUELCO_T * 1.6
	if estado == Criatura.Estado.APARECER or estado == Criatura.Estado.VOLAR or volcandose:
		_alto = alto
		_alto_v = 0.0
	else:
		# Un muelle: al posarse rebota un pelo, que es lo que le da peso.
		_alto_v += (260.0 * (alto - _alto) - 22.0 * _alto_v) * delta
		_alto += _alto_v * delta
		if _alto < apoyo:
			_alto = apoyo
			_alto_v = maxf(_alto_v, 0.0)

	var sitio := suelo + Vector3(0.0, _alto, 0.0)
	# El retroceso al parar la bola, y el tiritar.
	sitio -= adelante * 0.030 * _choque * _choque
	if tiembla > 0.0:
		sitio += Vector3(sin(_tiempo * 71.0), 0.0, cos(_tiempo * 83.0)) * 0.0022 * tiembla
	_raiz.transform = Transform3D(giro, sitio)

	# --- El golpe: cede contra la dirección del impacto y vuelve con un muelle ---
	_golpe_t += delta
	_forma.transform = Transform3D(_ceder(_golpe_t), Vector3.ZERO)

	# --- La mandíbula -----------------------------------------------------------
	_desencaje = lerpf(_desencaje, desencaje, 1.0 - exp(-(10.0 if desencaje > 0.5 else 26.0) * delta))
	_mover_mandibula(delta, boca)

	# --- Brazos y manos ----------------------------------------------------------
	_miembros.visible = estado != Criatura.Estado.APARECER or apoyada
	_mover_brazos(delta, suelo, v3, rapidez, adelante, apoyada, estado, abre, garra)
	# La cola no sale hasta que el cuerpo está fuera: mientras la nuca sigue bajo
	# la losa no tiene de dónde colgar, y aparecía metida en la boca.
	var con_cola := estado != Criatura.Estado.APARECER or c.t_estado > 0.46
	for vertebra in _cola:
		vertebra.visible = con_cola
	if con_cola:
		var suelta := estado == Criatura.Estado.VOLAR or estado == Criatura.Estado.VOLCADA
		_mover_cola(delta, 1.0, -adelante, 0.0, 0.30 if suelta else 1.0)
	else:
		_cola_puesta = false

	# --- La piel -------------------------------------------------------------------
	# Hundida bajo un raíl: lo que queda bajo la losa no se pinta (la losa es
	# opaca, pero el reflejo y los bordes de las bocas lo dejarían ver).
	if _hundido > 0.0005:
		corte = maxf(corte, y_base + 0.002)
	for m in _mats:
		m.set_shader_parameter("corte", corte)
	_pintar_golpe(_choque)

	_mover_mirada(delta, estado)
	_pintar_suelo(delta, suelo, adelante, estado)
	_mover_huesecillos(estado)

func _pintar_golpe(en_la_frente: float) -> void:
	for m in _mats:
		m.set_shader_parameter("golpe", _destello)
		m.set_shader_parameter("frente", en_la_frente * 0.4)
		m.set_shader_parameter("blindaje", _blindaje)

## A qué altura tiene que estar el centro para que el mentón, con la boca como
## está, toque el suelo.
func _alto_menton(giro: Basis) -> float:
	var menton := _bisagra + Basis(Vector3.RIGHT, maxf(_boca, 0.0)) * _menton
	return -(giro * menton).y + 0.004

## Hacia dónde mira la cara cuando está DE ESPALDAS a la cámara que la mira (solo
## en planta). Sin cámara, de espaldas al jugador (+z de la mesa).
func _de_espaldas_a_la_camara(suelo: Vector3) -> float:
	var cam: Camera3D = null
	if is_inside_tree():
		cam = get_viewport().get_camera_3d()
	if cam != null:
		var d := cam.global_position - global_transform * suelo
		if Vector2(d.x, d.z).length_squared() > 1e-6:
			return atan2(d.x, d.z) - global_rotation.y + PI
	return PI

## El salto de la voltereta al volcarse: sube y cae en VUELCO_T, y da un rebote
## corto al tocar la losa. Es lo que dice «ha contado» en el mismo instante.
static func _salto_vuelco(t: float) -> float:
	var u := t / VUELCO_T
	if u < 1.0:
		return VUELCO_ALTO * sin(PI * u)
	if u < 1.6:
		return VUELCO_ALTO * 0.28 * sin(PI * (u - 1.0) / 0.6)
	return 0.0

func _aire(b: Brazo) -> float:
	return sin(PI * clampf(b.u, 0.0, 1.0)) if b.en_aire else 0.0

## A qué altura tiene que estar el centro para que la bóveda, girada así, toque
## el suelo: es lo que la hace rodar y posarse sobre su forma y no sobre una bola.
func _apoyo(giro: Basis) -> float:
	var fila := Vector3(giro.x.y, giro.y.y, giro.z.y)
	var alto := 0.0
	for par: Array in BOVEDA:
		var centro: Vector3 = par[0]
		var radios: Vector3 = par[1]
		var hondo := sqrt(pow(radios.x * fila.x, 2.0) + pow(radios.y * fila.y, 2.0) \
			+ pow(radios.z * fila.z, 2.0)) - fila.dot(centro)
		alto = maxf(alto, hondo)
	return alto

## Cuánto cede el cuerpo contra el golpe. Es hueso, no gelatina: poco, y seco.
## Como mucho un 12 % a lo largo del golpe y un 4 % de ancho (con un 20 % se
## veía el cráneo aplastado como una barra de pan).
func _ceder(t: float) -> Basis:
	if t >= 0.40:
		return Basis.IDENTITY
	var cede := 0.12 if t < 0.05 else 0.12 * exp(-(t - 0.05) * 15.0) * cos((t - 0.05) * 38.0)
	var n_local := (Basis(_orient).inverse() * _golpe_n)
	if n_local.length_squared() < 0.25:
		return Basis.IDENTITY
	return _estirar(n_local.normalized(), 1.0 - cede, 1.0 + cede * 0.33)

## Escala `largo` a lo largo de `d` y `ancho` en lo demás.
static func _estirar(d: Vector3, largo: float, ancho: float) -> Basis:
	var k := largo - ancho
	return Basis(
		Vector3(ancho + k * d.x * d.x, k * d.x * d.y, k * d.x * d.z),
		Vector3(k * d.y * d.x, ancho + k * d.y * d.y, k * d.y * d.z),
		Vector3(k * d.z * d.x, k * d.z * d.y, ancho + k * d.z * d.z))

func _al_cambiar(estado: int, suelo: Vector3) -> void:
	var antes := _estado_antes
	if estado == Criatura.Estado.ALERTA:
		_aviso_t = 0.7
		# Se clava de uñas: le salta polvo de las dos manos. Es lo que la separa,
		# en una foto fija, de ir andando (agachada y castañeteando no se ve quieta).
		for b in _brazos:
			if _pies_puestos:
				_soplar(b.pie + Vector3(0.0, 0.012, 0.0), Vector3.UP, 6, 0.9)
	if estado == Criatura.Estado.EN_BOLA:
		# Donde se la VE, con lo agachada o apartada que estuviera: al pasar a la
		# bola se quita esa transformada y así no salta.
		_desde_recogida = transform * _raiz.position
	if estado == Criatura.Estado.APARECER:
		# Sale de la nada: de debajo de la losa, y ya mirando hacia donde va.
		_yaw = atan2(c.rumbo.x, c.rumbo.y)
		_orient = Quaternion(Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, -0.95))
		_alto = -0.135
		_alto_v = 0.0
		_boca = 0.20
		_boca_v = 0.0
		_manos_fuera = false
		_soplar(suelo + Vector3(0.0, 0.03, 0.0), Vector3.UP, 12, 1.3)
		_esquirlar(suelo + Vector3(0.0, 0.03, 0.0), Vector3.UP, 9, 0.8)
	if estado == Criatura.Estado.VOLCADA:
		_t_circulo = 0.0
		_soplar(suelo + Vector3(0.0, 0.03, 0.0), Vector3.UP, 10, 1.2)
	if estado == Criatura.Estado.ATURDIDA:
		_lado_desencaje = -1.0 if (c.golpes + c.indice) % 2 == 0 else 1.0
		_boca_v += 5.0
	if antes == -1 or antes == Criatura.Estado.FUERA or antes == Criatura.Estado.ESCONDIDA \
			or antes == Criatura.Estado.EN_BOLA:
		_pies_puestos = false
		_destello = 0.0 if estado != Criatura.Estado.VOLAR else _destello
		if estado != Criatura.Estado.APARECER:
			_yaw = atan2(c.rumbo.x, c.rumbo.y)
			_orient = Quaternion(Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, CABECEO))
			_alto = ALTO
			_alto_v = 0.0

# ----------------------------------------------------------------- la mandíbula

## La mandíbula es un muelle flojo: va detrás de lo que se le pide, se pasa,
## rebota en los dientes de arriba (el castañeteo) y el suelo la cierra.
func _mover_mandibula(delta: float, boca: float) -> void:
	if _mandibula == null:
		return
	_boca_v += (460.0 * (boca - _boca) - 15.0 * _boca_v) * delta
	_boca += _boca_v * delta
	if _boca < 0.0:
		_boca = 0.0
		_boca_v = absf(_boca_v) * 0.35
	# Abierta del todo, no más: pasado esto la rama se metía en el hombro.
	_boca = minf(_boca, BOCA_MAX)
	# El suelo: si el mentón fuera a hundirse en la losa, la losa la cierra.
	var angulo := _boca
	var cuerpo := _raiz.transform
	for i in 10:
		var menton := cuerpo * (_bisagra + Basis(Vector3.RIGHT, angulo) * _menton)
		if menton.y >= y_base + 0.004 or angulo <= 0.0:
			break
		angulo = maxf(angulo - 0.05, 0.0)
	if angulo < _boca:
		_boca = angulo
		_boca_v = minf(_boca_v, 0.0)
	# Torcida (aturdida): gira algo de lado, pero SOBRE LA BISAGRA. Nunca se
	# desplaza: separada del cráneo dejaba de ser una calavera y era un cacharro.
	var d := _desencaje * _lado_desencaje
	var base := Basis(Vector3.UP, 0.16 * d) * Basis(Vector3.BACK, 0.12 * d) \
		* Basis(Vector3.RIGHT, _boca)
	_mandibula.transform = Transform3D(base, _bisagra)

# ------------------------------------------------------------------ los brazos

## LAS MANOS. Apoyada, cada mano se queda clavada donde cayó mientras el cuerpo
## avanza, y da el paso cuando se ha quedado atrás —o cuando el cuerpo ha girado
## y la ha dejado fuera de sitio—, siempre de una en una: la otra aguanta. Por el
## aire o boca arriba van sueltas, con retraso, y patalean.
func _mover_brazos(delta: float, suelo: Vector3, v3: Vector3, rapidez: float,
		adelante: Vector3, apoyada: bool, estado: int, abre: float, garra: float) -> void:
	var cuerpo := _raiz.transform * _forma.transform
	# Las manos pisan alrededor del rumbo, pero se van a medias con el cráneo cuando
	# lo vuelve (huyendo mira atrás): si no, los brazos se cruzaban por debajo.
	var plano := Basis(Vector3.UP, _yaw + _giro_mira * 0.5)
	var dir := v3 / rapidez if rapidez > 0.01 else adelante
	var anda := rapidez > 0.03 and (estado == Criatura.Estado.CORRER \
		or estado == Criatura.Estado.HUIR)
	var aparece := estado == Criatura.Estado.APARECER

	if apoyada:
		var reposos: Array[Vector3] = []
		for b in _brazos:
			reposos.append(suelo + plano * Vector3(b.lado * ABRE_X * abre, 0.0,
				ABRE_Z + 0.045 * _blindaje))
		if aparece and not _manos_fuera:
			# El manotazo: salen de debajo de la losa, junto al cuerpo, y caen fuera.
			_manos_fuera = true
			_pies_puestos = true
			for i in _brazos.size():
				var b := _brazos[i]
				b.desde = suelo + plano * Vector3(b.lado * 0.085, 0.0, 0.030)
				b.pie = b.desde
				b.alto_desde = -0.090
				b.arco = 0.105
				b.u = -0.25 * float(i)
				b.dura = 0.17
				b.en_aire = true
				b.giro = _yaw + b.lado * 1.2
				b.giro_desde = b.giro
				b.suelta = 0.0
				b.muneca = b.desde + Vector3(0.0, b.alto_desde, 0.0)
		elif not _pies_puestos:
			_pies_puestos = true
			for i in _brazos.size():
				var b := _brazos[i]
				if _estado_antes_suelto():
					# Viene de rodar o de estar boca arriba: la mano baja desde
					# donde estaba, no aparece puesta.
					b.desde = Vector3(b.muneca.x, suelo.y, b.muneca.z)
					b.alto_desde = maxf(b.muneca.y - suelo.y - _h_muneca, 0.0)
					b.arco = 0.02
					b.u = -0.3 * float(i)
					b.dura = 0.15
					b.en_aire = true
					b.giro_desde = _yaw + b.lado * GIRO_MANO
					b.giro = b.giro_desde
				else:
					b.pie = reposos[i]
					b.en_aire = false
					b.u = 1.0
					b.giro = _yaw + b.lado * GIRO_MANO
					b.muneca = b.pie + Vector3(0.0, _h_muneca, 0.0)

		# ¿A quién le toca dar el paso? A la que más lejos se ha quedado, y solo
		# si la otra está apoyada.
		var alguna_en_aire := false
		for b in _brazos:
			alguna_en_aire = alguna_en_aire or b.en_aire
		if not alguna_en_aire:
			var umbral := ZANCADA * 0.5 if anda else 0.030
			var peor := -1
			var cuanto := umbral
			for i in _brazos.size():
				var b := _brazos[i]
				var lejos := Vector2(b.pie.x - reposos[i].x, b.pie.z - reposos[i].z).length()
				# Si las dos piden paso a la vez, va la que no dio el último.
				if i != _ultima_mano:
					lejos += 0.004
				if lejos > cuanto:
					cuanto = lejos
					peor = i
			if peor >= 0:
				var b := _brazos[peor]
				_ultima_mano = peor
				b.en_aire = true
				b.u = 0.0
				b.desde = b.pie
				b.alto_desde = 0.0
				b.arco = ALZADA if anda else 0.028
				b.giro_desde = b.giro
				b.dura = clampf(0.40 * ZANCADA / maxf(rapidez, 0.01), 0.13, 0.19)
				if estado == Criatura.Estado.HUIR:
					# Huyendo, los brazos van a toda prisa y más altos: manotazos.
					b.dura = clampf(0.30 * ZANCADA / maxf(rapidez, 0.01), 0.09, 0.13)
					b.arco = ALZADA * 1.35

		# Parada y a lo suyo, de vez en cuando tamborilea con los dedos.
		var ociosa := not anda and not alguna_en_aire and garra <= 0.01 \
			and estado == Criatura.Estado.CORRER
		_tambor_t += delta
		if ociosa:
			_espera_tambor -= delta
			if _espera_tambor <= 0.0:
				_espera_tambor = 2.2 + fposmod(_tiempo * 3.7, 1.4)
				_tambor_t = 0.0
				_tambor_mano = (_tambor_mano + 1) % _brazos.size()
		else:
			_tambor_t = 9.0

		for i in _brazos.size():
			var b := _brazos[i]
			var alto_mano := 0.0
			var picado := 0.0
			if b.en_aire:
				b.u += delta / b.dura
				var u := clampf(b.u, 0.0, 1.0)
				var k := smoothstep(0.0, 1.0, u)
				var destino := reposos[i]
				if anda:
					destino += dir * ZANCADA * 0.5 + v3 * b.dura * (1.0 - u)
				b.pie = b.desde.lerp(destino, k)
				alto_mano = lerpf(b.alto_desde, 0.0, k) + b.arco * sin(PI * u)
				b.giro = lerp_angle(b.giro_desde, _yaw + b.lado * GIRO_MANO, k)
				# En el aire la mano cuelga de la muñeca: los dedos, hacia abajo.
				picado = 0.55 * sin(PI * u)
				if b.u >= 1.0:
					b.en_aire = false
					b.pie = destino
					alto_mano = 0.0
					picado = 0.0
					_al_pisar(b, aparece)
			# De uñas: el dedo se cierra y la muñeca sube lo que baja la yema.
			var cierre := maxf(garra, 0.0)
			var sube := 0.058 * sin(cierre) - 0.022 * (1.0 - cos(cierre))
			b.pie.y = suelo.y
			var muneca := b.pie + Vector3(0.0, _h_muneca + sube + alto_mano, 0.0)
			b.muneca = muneca
			b.suelta = move_toward(b.suelta, 0.0, delta * 9.0)
			var posada := Basis(Vector3.UP, b.giro) * Basis(Vector3.RIGHT, picado)
			_resolver(b, cuerpo * b.hombro, muneca, cuerpo.basis, 1.0, posada)
			_mover_dedos(b, garra + picado * 0.5, 0.0, _tambor_t if i == _tambor_mano else 9.0)
		return

	# --- Sin apoyo: por el aire o boca arriba -------------------------------------
	_pies_puestos = false
	for b in _brazos:
		var hombro := cuerpo * b.hombro
		var objetivo := hombro
		var prisa := 14.0
		var cierre := 0.0
		var abanico := 0.0
		if estado == Criatura.Estado.VOLCADA:
			# Pataleo: las manos dan vueltas en el aire, alternas, buscando suelo.
			var queda := 1.0 - clampf(c.t_estado / maxf(t_volcada, 0.1), 0.0, 1.0)
			var w := _tiempo * (8.5 + 5.0 * (1.0 - queda)) + (0.0 if b.lado > 0.0 else PI)
			objetivo = hombro + plano * Vector3(
				b.lado * (0.135 + 0.030 * sin(w)),
				0.0,
				-0.070 + 0.050 * cos(w * 0.9 + 1.0)) \
				+ Vector3(0.0, 0.150 + 0.030 * cos(w), 0.0)
			cierre = 0.25 + 0.45 * sin(w * 1.7)
			abanico = 0.30
			prisa = 16.0
		else:
			# Rodando: los brazos van a los lados del cuerpo, con retraso, a
			# latigazos, y por FUERA de la bóveda (antes se metían por dentro y
			# por el otro lado asomaban los dedos sueltos).
			var w := _tiempo * 27.0 + b.lado * 1.7
			objetivo = cuerpo * (b.hombro + Vector3(b.lado * (0.135 + 0.02 * sin(w)),
				-0.010 + 0.03 * cos(w), 0.010 + 0.03 * sin(w * 0.7)))
			cierre = 0.35
			abanico = 0.10
			prisa = 9.0
		b.muneca = b.muneca.lerp(objetivo, 1.0 - exp(-prisa * delta))
		b.muneca = _fuera_del_casco(b.muneca, cuerpo, 0.028)
		# Nunca por debajo de la losa.
		b.muneca.y = maxf(b.muneca.y, y_base + _h_muneca * 0.8)
		b.suelta = move_toward(b.suelta, 1.0, delta * 9.0)
		b.pie = Vector3(b.muneca.x, y_base, b.muneca.z)
		b.en_aire = false
		b.u = 1.0
		_resolver(b, hombro, b.muneca, cuerpo.basis, 1.0, Basis(Vector3.UP, b.giro))
		_mover_dedos(b, cierre, abanico)

func _estado_antes_suelto() -> bool:
	return _brazos[0].suelta > 0.5

## La mano acaba de caer: el cuerpo lo nota —la mandíbula da el bocado— y levanta
## un poco de polvo.
func _al_pisar(b: Brazo, fuerte: bool) -> void:
	_boca_v += 3.2 if fuerte else 1.6
	_alto_v -= 0.10 if fuerte else 0.035
	if fuerte:
		_soplar(b.pie + Vector3(0.0, 0.02, 0.0), Vector3.UP, 6, 0.9)

## Cinemática inversa de dos tramos, y coloca húmero, antebrazo y mano.
## `posada` es la base de la mano cuando pisa; suelta, sigue al antebrazo.
func _resolver(b: Brazo, hombro: Vector3, muneca: Vector3, cuerpo: Basis, talla: float,
		posada: Basis) -> void:
	var l1 := _l1 * talla
	var l2 := _l2 * talla
	var d := muneca - hombro
	var dist := d.length()
	var u_dir := d / dist if dist > 1e-6 else Vector3.DOWN
	var alcance := l1 + l2 - 0.003 * talla
	if dist > alcance:
		dist = alcance
		muneca = hombro + u_dir * dist
	dist = maxf(dist, absf(l1 - l2) + 0.004 * talla)
	var a := (l1 * l1 - l2 * l2 + dist * dist) / (2.0 * dist)
	var h := sqrt(maxf(l1 * l1 - a * a, 0.0))
	# El codo: arriba y hacia fuera, y un poco atrás. Como una pata de cangrejo.
	# Blindada (`_codos` bajo) lo pega al cuerpo: hacia fuera y nada hacia arriba.
	var fuera := (cuerpo * Vector3(b.lado, 0.0, 0.0)).normalized()
	var doblar := Vector3.UP * _codos + fuera * (0.55 + 0.60 * (1.0 - _codos)) \
		- (cuerpo * Vector3(0.0, 0.0, 1.0)).normalized() * 0.30 \
		+ (cuerpo * Vector3(0.0, 0.35, 0.0)) * _codos
	doblar -= u_dir * doblar.dot(u_dir)
	if doblar.length_squared() < 1e-8:
		doblar = Vector3.UP - u_dir * u_dir.y
	doblar = doblar.normalized()
	var codo := hombro + u_dir * a + doblar * h
	# Nunca por dentro de la bóveda: si cae dentro, se gira el codo alrededor del
	# brazo hasta que quede fuera.
	if _dentro_del_casco(codo, _raiz.transform * _forma.transform, 0.012):
		for giro_codo: float in [0.5, -0.5, 1.0, -1.0, 1.6, -1.6, 2.3, -2.3]:
			var otro := Basis(u_dir, giro_codo * b.lado) * doblar
			var prueba := hombro + u_dir * a + otro * h
			if not _dentro_del_casco(prueba, _raiz.transform * _forma.transform, 0.012):
				codo = prueba
				break
	var eje := (codo - hombro).cross(muneca - codo)
	if eje.length_squared() > 1e-10:
		b.eje = eje.normalized() * b.lado
	b.humero.transform = Transform3D(_base_hueso(codo - hombro, b.eje, talla), hombro)
	b.antebrazo.transform = Transform3D(_base_hueso(muneca - codo, b.eje, talla), codo)
	# La mano. Posada va derecha sobre el suelo; suelta, sigue al antebrazo.
	var z := (muneca - codo).normalized()
	var x := b.eje - z * b.eje.dot(z)
	x = x.normalized() if x.length_squared() > 1e-8 else Vector3.RIGHT
	var floja := Basis(x, z.cross(x), z).orthonormalized()
	var base := Basis(Quaternion(posada).slerp(Quaternion(floja), b.suelta))
	b.mano.transform = Transform3D(base.scaled(Vector3.ONE * talla), muneca)

## ¿Está `p` (en el mundo) dentro de la bóveda, con un margen?
func _dentro_del_casco(p: Vector3, cuerpo: Transform3D, margen: float) -> bool:
	var q := cuerpo.affine_inverse() * p - CASCO_CENTRO
	var r := CASCO_RADIOS + Vector3.ONE * margen
	return Vector3(q.x / r.x, q.y / r.y, q.z / r.z).length_squared() < 1.0

## Saca `p` (en el mundo) de la bóveda, empujándolo desde el centro hasta su
## superficie (más el margen). Si ya está fuera, no lo toca.
func _fuera_del_casco(p: Vector3, cuerpo: Transform3D, margen: float) -> Vector3:
	var q := cuerpo.affine_inverse() * p - CASCO_CENTRO
	var r := CASCO_RADIOS + Vector3.ONE * margen
	var n := Vector3(q.x / r.x, q.y / r.y, q.z / r.z)
	var largo := n.length()
	if largo >= 1.0 or largo < 1e-6:
		return p
	n /= largo
	return cuerpo * (CASCO_CENTRO + Vector3(n.x * r.x, n.y * r.y, n.z * r.z))

static func _base_hueso(a_lo_largo: Vector3, eje: Vector3, talla: float) -> Basis:
	var y := a_lo_largo.normalized()
	var x := eje - y * eje.dot(y)
	x = x.normalized() if x.length_squared() > 1e-8 else y.cross(Vector3.FORWARD).normalized()
	var z := x.cross(y)
	return Basis(x * talla, y * talla, z * talla)

## Los dedos giran en el nudillo: `cierre` positivo los cierra (la yema baja) y
## `abanico` los abre hacia los lados. `tambor` es el tiempo que lleva
## tamborileando: los dedos se levantan y caen uno detrás de otro.
func _mover_dedos(b: Brazo, cierre: float, abanico: float, tambor: float = 9.0) -> void:
	for i in b.dedos.size():
		var reposo := b.reposo_dedos[i]
		# Cada dedo, a su aire: que no se muevan los cuatro a la vez.
		var suyo := cierre + 0.05 * sin(_tiempo * 3.1 + float(i) * 1.9 + b.lado)
		if tambor < 1.0 and i < 3:
			suyo -= 0.62 * sin(PI * clampf((tambor - float(i) * 0.085) / 0.19, 0.0, 1.0))
		var lado := (float(i) - 1.0) * abanico * b.lado
		if i >= 3:
			lado = -abanico * 1.3 * b.lado
		b.dedos[i].transform = reposo * Transform3D(
			Basis(Vector3.UP, lado) * Basis(Vector3.RIGHT, suyo), Vector3.ZERO)

# -------------------------------------------------------------------- la mirada

## La mota de cada cuenca va hacia donde está la bola, dentro de la cuenca.
func _mover_mirada(delta: float, estado: int) -> void:
	_prox_parpadeo -= delta
	if _prox_parpadeo <= 0.0:
		_parpadeo = 0.12
		_prox_parpadeo = 2.4 + fposmod(_tiempo * 7.3 + float(c.indice), 2.8)
	_parpadeo = maxf(_parpadeo - delta, 0.0)

	var mira3 := Vector3(c.mira.x * E, y_base + 0.09, c.mira.y * E)
	var hacia := (_raiz.transform * _forma.transform).affine_inverse() * mira3
	var fuerza := 0.75
	var objetivo := Vector2.ZERO
	var prisa := 16.0
	var d := hacia - Vector3(0.0, 0.004, 0.086)
	if d.length_squared() > 1e-8:
		d = d.normalized()
		objetivo = Vector2(d.x, d.y)
	if estado == Criatura.Estado.ATURDIDA:
		# Le dan vueltas, cada una por su lado.
		fuerza = 0.45 + 0.20 * sin(_tiempo * 19.0)
		objetivo = Vector2.ZERO
	elif estado == Criatura.Estado.VOLCADA:
		# Pánico: va de un lado a otro sin fijarse en nada.
		fuerza = 1.25
		objetivo = Vector2(sin(_tiempo * 9.1), cos(_tiempo * 6.7))
		prisa = 30.0
	elif estado == Criatura.Estado.VOLAR:
		fuerza = 0.30
	elif estado == Criatura.Estado.ALERTA or _aviso_t > 0.0 or _plantada > 0.0 \
			or estado == Criatura.Estado.HUIR:
		fuerza = 1.35
	elif _parpadeo > 0.0:
		fuerza = 0.04
	fuerza += _destello * 0.9
	_fuerza_ojos = lerpf(_fuerza_ojos, fuerza, 1.0 - exp(-20.0 * delta))
	_mira_ojos = _mira_ojos.lerp(objetivo, 1.0 - exp(-prisa * delta))
	_mat_mirada.set_shader_parameter("fuerza", _fuerza_ojos)
	for i in _ojos.size():
		var centro := _ojos_centro[i]
		var desp := Vector3(_mira_ojos.x * 0.017, _mira_ojos.y * 0.013, 0.0)
		if estado == Criatura.Estado.ATURDIDA:
			var w := _tiempo * 11.0 * (1.0 if i == 0 else -1.0) + float(i) * 2.0
			desp = Vector3(cos(w) * 0.013, sin(w) * 0.011, 0.0)
		_ojos[i].position = centro + desp
		var talla := 1.0 + 0.22 * clampf(_fuerza_ojos - 0.75, 0.0, 1.5)
		_ojos[i].scale = Vector3.ONE * talla

# ---------------------------------------------------------------- lo del suelo

func _pintar_suelo(delta: float, suelo: Vector3, adelante: Vector3, estado: int) -> void:
	_tiza.visible = true
	# La tiza va en la LOSA y a su tamaño, aunque el cuerpo esté hundido o
	# encogido: se deshace la transformada del nodo (si no, se iba bajo el suelo).
	_tiza.transform = transform.affine_inverse() \
		* Transform3D(Basis.IDENTITY, suelo + Vector3(0.0, 0.012, 0.0))
	var volcada := estado == Criatura.Estado.VOLCADA
	var aparece := estado == Criatura.Estado.APARECER
	# El arco del frente: mientras la frente pare la bola.
	var con_escudo := not volcada and not aparece and estado != Criatura.Estado.VOLAR
	_escudo = move_toward(_escudo, 1.0 if con_escudo else 0.0, delta * 5.0)
	# El cerco se traza de una pasada al caer boca arriba, y se borra con el tiempo.
	var queda := 1.0
	var circulo := 0.0
	if volcada:
		_t_circulo += delta
		# A la vez que la voltereta: el aro está entero cuando cae.
		circulo = clampf(_t_circulo / VUELCO_T, 0.0, 1.0) * 1.05
		queda = 1.0 - clampf(c.t_estado / maxf(t_volcada, 0.1), 0.0, 1.0)
	# La sombra de contacto: más floja cuanto más alto va.
	var cerca := 1.0 - clampf((_alto - 0.20) / 0.12, 0.0, 1.0)
	_contacto = lerpf(_contacto, 0.0 if aparece else cerca, 1.0 - exp(-12.0 * delta))
	var fosa := 0.0
	if aparece:
		fosa = 1.0 - smoothstep(0.55, 1.0, clampf(c.t_estado / 0.6, 0.0, 1.0))
	# Hundida bajo un raíl, la losa se le abre igual que al salir: sin la mancha
	# del hoyo se leía como cortada por el suelo, no metida en él.
	fosa = maxf(fosa, 0.9 * smoothstep(0.005, 0.06, _hundido))
	_mat_tiza.set_shader_parameter("escudo", _escudo)
	# El rumbo de la LÓGICA, no el giro suavizado del cuerpo: el arco tiene que
	# marcar lo que de verdad para la bola.
	_mat_tiza.set_shader_parameter("direccion", Vector2(adelante.x, adelante.z))
	# En guardia, la tiza del frente se repasa: el arco sale entero y blanco.
	var guardia := 0.7 if estado == Criatura.Estado.ALERTA else 0.0
	_mat_tiza.set_shader_parameter("choque", maxf(maxf(_choque, guardia), _blindaje))
	_mat_tiza.set_shader_parameter("rebote", _blindaje)
	_mat_tiza.set_shader_parameter("circulo", circulo)
	_mat_tiza.set_shader_parameter("queda", queda)
	_mat_tiza.set_shader_parameter("aviso", maxf(_aro_aviso, 0.3 * guardia))
	_mat_tiza.set_shader_parameter("contacto", _contacto)
	_mat_tiza.set_shader_parameter("fosa", fosa)
	# El cerco de rendida lleva luz propia: más al trazarse, y luego la justa.
	var luz := 0.0
	if volcada:
		luz = 0.55 + 0.9 * (1.0 - smoothstep(0.0, 0.5, _t_circulo))
	_mat_tiza.set_shader_parameter("luz_cerco", luz)

func _mover_huesecillos(estado: int) -> void:
	var aturdida := estado == Criatura.Estado.ATURDIDA
	_huesecillos.visible = aturdida
	if not aturdida:
		return
	var sale := maxf(smoothstep(0.0, 0.18, c.t_estado), 0.02)
	_huesecillos.position = _raiz.position + Basis(_orient) * Vector3(0.0, 0.150, 0.0)
	_huesecillos.basis = Basis(Vector3.RIGHT, 0.26) * Basis(Vector3.BACK, 0.12)
	var n := _huesecillos.get_child_count()
	for i in n:
		var hueso := _huesecillos.get_child(i) as Node3D
		var w := _tiempo * 4.6 + TAU * float(i) / float(n)
		hueso.position = Vector3(cos(w) * 0.135, 0.010 * sin(_tiempo * 7.0 + float(i) * 2.1),
			sin(w) * 0.135) * sale
		hueso.basis = Basis(Vector3.UP, -w + 0.6) * Basis(Vector3.RIGHT, 1.2 + _tiempo * 5.0 \
			+ float(i)) * Basis.from_scale(Vector3.ONE * 2.1 * sale)

# ------------------------------------------------------------------ en la bola

## La bola se la traga. Primero SE ENROSCA en el sitio, como una cochinilla: el
## cráneo se vuelca con la cara hacia el suelo, la boca se cierra, los brazos lo
## abrazan por los lados y la cola se le sube por la nuca. Aguanta un instante
## temblando, y la bola se la lleva de un tirón, girando y menguando —toda a la
## vez: sin estirarla ni aplastarla, que es hueso—.
func _tragar(delta: float, bola: Vector3) -> void:
	_tiza.visible = false
	_huesecillos.visible = false
	var u := clampf(c.t_estado / 0.30, 0.0, 1.0)
	if u >= 1.0:
		_ocultar()
		return
	_raiz.visible = true
	_miembros.visible = true
	var enrosca := smoothstep(0.0, 0.55, u)
	var tiron := smoothstep(0.80, 1.0, u)
	var talla := 1.0 - 0.95 * tiron
	var hacia := bola - _desde_recogida
	hacia = hacia.normalized() if hacia.length_squared() > 1e-8 else Vector3.FORWARD
	# El cráneo: de la pose en que estaba a la cara contra el suelo, y en el tirón
	# rueda hacia la bola.
	var objetivo := Quaternion(Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT,
		lerpf(CABECEO, 1.30, enrosca)) * Basis(Vector3.BACK, 0.12 * enrosca))
	_orient = _orient.slerp(objetivo, 1.0 - exp(-22.0 * delta)).normalized()
	var giro := Basis(_orient)
	if tiron > 0.0:
		var eje := Vector3.UP.cross(hacia)
		eje = eje.normalized() if eje.length_squared() > 1e-6 else Vector3.RIGHT
		giro = Basis(eje, tiron * 7.0) * giro
	var alto := maxf(_apoyo(giro), _alto_menton(giro)) * talla
	var sitio := Vector3(_desde_recogida.x, y_base + alto, _desde_recogida.z)
	# Enroscada, tiembla; y en el tirón se va hacia la bola.
	var aguanta := smoothstep(0.45, 0.60, u) * (1.0 - tiron)
	sitio += Vector3(sin(_tiempo * 77.0), 0.0, cos(_tiempo * 91.0)) * 0.0030 * aguanta
	sitio = sitio.lerp(bola, pow(tiron, 1.5))
	_raiz.transform = Transform3D(giro, sitio)
	_forma.transform = Transform3D(Basis.from_scale(Vector3.ONE * talla), Vector3.ZERO)
	# La boca, cerrada de golpe.
	_boca = lerpf(_boca, 0.0, 1.0 - exp(-30.0 * delta))
	_boca_v = 0.0
	if _mandibula != null:
		_mandibula.transform = Transform3D(Basis(Vector3.RIGHT, _boca), _bisagra)
	_blindaje = 0.0
	_codos = 1.0
	for m in _mats:
		m.set_shader_parameter("golpe", 0.25 * tiron)
		m.set_shader_parameter("frente", 0.0)
		m.set_shader_parameter("blindaje", 0.0)
		m.set_shader_parameter("corte", -1000.0)
	_mat_mirada.set_shader_parameter("fuerza", 1.8)
	# Los brazos lo abrazan: cada mano se va al costado de la bóveda, por fuera,
	# hacia la frente, con los dedos cerrados agarrándola.
	var cuerpo := _raiz.transform * _forma.transform
	for b in _brazos:
		var hombro := cuerpo * b.hombro
		var abrazo := cuerpo * Vector3(b.lado * 0.118, 0.020, 0.070)
		abrazo = _fuera_del_casco(abrazo, cuerpo, 0.022)
		var suelta := hombro + (giro * Vector3(b.lado * 0.17, -0.03, 0.06)) * talla
		var quiere := suelta.lerp(abrazo, enrosca)
		b.muneca = b.muneca.lerp(quiere, 1.0 - exp(-24.0 * delta))
		b.muneca = _fuera_del_casco(b.muneca, cuerpo, 0.018)
		b.suelta = move_toward(b.suelta, 1.0, delta * 12.0)
		_resolver(b, hombro, b.muneca, cuerpo.basis.orthonormalized(), talla,
			Basis(Vector3.UP, b.giro))
		_mover_dedos(b, lerpf(-0.30, 0.95, enrosca), 0.10)
	_mover_cola(delta, talla, -hacia, enrosca)
	_pies_puestos = false


# -------------------------------------------------------------------- la cola

## La cola es un espinazo corto: cada vértebra sigue a la anterior a su
## distancia, cae por su peso, roza el suelo y no atraviesa la bóveda, y se
## resiste algo a doblarse (`COLA_RIGIDEZ`). La primera sale del agujero
## occipital por su canal. No hay nada dibujado: arrastra, da latigazos y cuelga
## porque es lo que hace algo así atado a un cráneo que se mueve.
## `abraza` (0 a 1) la enrosca por la nuca hacia arriba: es en_bola.
## `firme` escala la rigidez: rodando o boca arriba va floja y cae (tiesa, por el
## aire salía en horizontal como un peine).
func _mover_cola(delta: float, talla: float, atras: Vector3, abraza: float = 0.0,
		firme: float = 1.0) -> void:
	var n := _cola.size()
	if n == 0:
		return
	var cuerpo := _raiz.transform * _forma.transform
	var ancla := cuerpo * _nuca
	var canal := (cuerpo.basis * _canal).normalized()
	if not _cola_puesta:
		_cola_puesta = true
		var p := ancla
		_cola_p[0] = ancla
		_cola_a[0] = ancla
		var cae := (canal + atras * 0.6).normalized()
		for i in n:
			var t0: float = COLA_TALLAS[i]
			p += cae * COLA_PASO * t0 * talla
			p.y = maxf(p.y, y_base + COLA_RADIO * t0 * talla)
			_cola_p[i + 1] = p
			_cola_a[i + 1] = p
			cae = (cae + atras * 0.5 + Vector3(0.0, -0.3, 0.0)).normalized()
	_cola_p[0] = ancla
	var dt := minf(delta, 0.034)
	for i in range(1, n + 1):
		var t0: float = COLA_TALLAS[i - 1]
		var p := _cola_p[i]
		var vel := (p - _cola_a[i]) * 0.90
		if p.y <= y_base + COLA_RADIO * t0 * talla + 0.0015:
			# Rozando la losa, se frena.
			vel.x *= 0.60
			vel.z *= 0.60
		_cola_a[i] = p
		_cola_p[i] = p + vel + Vector3(0.0, -5.5, 0.0) * dt * dt
	for vuelta in 4:
		for i in range(1, n + 1):
			var t0: float = COLA_TALLAS[i - 1]
			var antes := _cola_p[i - 1]
			var paso := COLA_PASO * t0 * talla
			# Hacia dónde seguiría recta: la primera, por el canal; las demás, como
			# venía la anterior.
			var recta := canal
			if i >= 2:
				recta = (antes - _cola_p[i - 2]).normalized()
			var d := _cola_p[i] - antes
			var largo := d.length()
			var dir := d / largo if largo > 1e-6 else recta
			var rigidez: float = COLA_RIGIDEZ[i - 1]
			rigidez *= firme
			dir = dir.lerp(recta, rigidez).normalized()
			var p := antes + dir * paso
			if abraza > 0.0:
				# Enroscada: sube pegada a la nuca, por encima de la bóveda.
				var th := lerpf(-0.55, 1.05, float(i) / float(n))
				var pegada := cuerpo * (CASCO_CENTRO + Vector3(0.0, sin(th) * (CASCO_RADIOS.y + 0.020),
					-cos(th) * (CASCO_RADIOS.z + 0.020)))
				p = p.lerp(pegada, abraza * 0.85)
			# Fuera de la bóveda (la primera vértebra, no: sale de debajo de ella).
			if i >= 2:
				p = _fuera_del_casco(p, cuerpo, COLA_RADIO * t0 * talla)
			p.y = maxf(p.y, y_base + COLA_RADIO * t0 * talla)
			_cola_p[i] = p
	for i in n:
		var z := _cola_p[i] - _cola_p[i + 1]
		z = z.normalized() if z.length_squared() > 1e-10 else Vector3.BACK
		# La espina, hacia arriba; y si la vértebra cuelga a plomo, hacia atrás.
		var arriba := Vector3.UP if absf(z.y) < 0.9 else atras
		var x := arriba.cross(z)
		x = x.normalized() if x.length_squared() > 1e-8 else Vector3.RIGHT
		var y := z.cross(x)
		_cola[i].transform = Transform3D(Basis(x * talla, y * talla, z * talla), _cola_p[i + 1])

# ------------------------------------------------- no atravesarse a la vista

## Caber bajo un raíl SIN APLASTARSE (ver `UMBRAL_APARTE`). La calavera no cede
## ante nadie, así que no se aparta: solo mide el hueco. `_agache` guarda la
## parte de su alto que cabe (1 = toda), con un muelle corto: a ojo se mete al
## pasar, no salta.
func _agacharse_hueso(delta: float, suelo: Vector3, alto: float) -> void:
	if not _tramos_listos:
		_tramos_listos = true
		_tramos = tramos_bajos(get_parent())
	var libre := hueco_bajo_raiil(_tramos, suelo, maxf(c.radio * E, 0.14) + ANCHO_RAIL, alto)
	_agache = lerpf(_agache, clampf(libre / alto, 0.0, 1.0), 1.0 - exp(-12.0 * delta))
	_aparte = Vector3.ZERO
	_colocar_hueso(suelo, alto)

## Lo que asoma = lo que cabe (y nunca menos de `ASOMA_MIN`). Primero encoge,
## igual en los tres ejes y no menos de `ESCALA_MIN`; lo que aún sobre, se hunde
## bajo la losa con el pivote en el suelo que pisa. Antes era `colocar()`, que
## aplastaba en altura hasta 0,42 y ensanchaba ×1,13: una torta, no un cráneo.
func _colocar_hueso(suelo: Vector3, alto: float) -> void:
	var asoma := maxf(_agache * alto, minf(ASOMA_MIN, alto))
	_escala = clampf(asoma / maxf(alto, 0.001), ESCALA_MIN, 1.0)
	_hundido = maxf(_escala * alto - asoma, 0.0)
	var b := Basis.from_scale(Vector3.ONE * _escala)
	transform = Transform3D(b, suelo - b * suelo - Vector3(0.0, _hundido, 0.0))

## Un punto del cuerpo (en el nodo), subido a ras de losa si con el hundido se
## quedaba debajo: el polvo y las astillas de una calavera hundida salen del hoyo,
## no de debajo del suelo, donde no se verían.
func _sobre_la_losa(punto: Vector3) -> Vector3:
	if _hundido <= 0.0005:
		return punto
	var mundo := transform * punto
	if mundo.y >= y_base + 0.02:
		return punto
	return transform.affine_inverse() * Vector3(mundo.x, y_base + 0.02, mundo.z)

## Lo alto que llega el cuerpo sobre el suelo que pisa, con la pose del cuadro
## anterior y sin el agache: la bóveda (su radio mayor, gire como gire), la punta
## de la mandíbula, los codos y las manos con los dedos.
func _alto_visible() -> float:
	if _raiz == null:
		return ALTO_CUERPO
	var alto := _raiz.position.y - y_base + CASCO_RADIOS.z
	if _mandibula != null:
		var menton := _raiz.transform * _forma.transform \
			* (_bisagra + Basis(Vector3.RIGHT, _boca) * _menton)
		alto = maxf(alto, menton.y - y_base + 0.012)
	if _miembros.visible:
		for b in _brazos:
			alto = maxf(alto, b.antebrazo.position.y - y_base + 0.016)
			alto = maxf(alto, b.muneca.y - y_base + 0.040)
	return clampf(alto, 0.12, 0.48)

func _quieto() -> void:
	_agache = 1.0
	_aparte = Vector3.ZERO
	_hundido = 0.0
	_escala = 1.0
	transform = Transform3D.IDENTITY

## Los raíles de la mesa que van POR ENCIMA de la losa, en trozos de 16 puntos con
## su caja en planta (x, z), para descartar de un vistazo los que caen lejos. Cada
## punto es (x, altura, z) en unidades 3D. Sale del núcleo (`mundo.mesa.rampas` y
## `mundo.altura_rampa`); en el visor, que no tiene mesa, no hay ninguno.
static func tramos_bajos(mundo: Object) -> Array[Dictionary]:
	var tramos: Array[Dictionary] = []
	if mundo == null or not ("mesa" in mundo) or not mundo.has_method("altura_rampa"):
		return tramos
	var mesa: Variant = mundo.get("mesa")
	if mesa == null or not ("rampas" in mesa):
		return tramos
	for r: Rampa in mesa.get("rampas"):
		if r.subterranea or r.puntos.size() < 2:
			continue
		var d := 0.0
		var trozo := PackedVector3Array()
		for i in r.puntos.size():
			if i > 0:
				d += r.puntos[i].distance_to(r.puntos[i - 1])
			var h: float = mundo.call("altura_rampa", r, d)
			trozo.append(Vector3(r.puntos[i].x * E, h, r.puntos[i].y * E))
			# Cada trozo empieza donde acabó el anterior: no queda hueco entre dos.
			if trozo.size() >= 16 or i == r.puntos.size() - 1:
				_guardar_trozo(tramos, trozo)
				trozo = PackedVector3Array([trozo[trozo.size() - 1]])
	return tramos

static func _guardar_trozo(tramos: Array[Dictionary], trozo: PackedVector3Array) -> void:
	if trozo.size() < 2:
		return
	var caja := Rect2(trozo[0].x, trozo[0].z, 0.0, 0.0)
	var h_min := trozo[0].y
	var h_max := trozo[0].y
	for p in trozo:
		caja = caja.expand(Vector2(p.x, p.z))
		h_min = minf(h_min, p.y)
		h_max = maxf(h_max, p.y)
	# A ras de suelo (la galería) no es techo; muy alto (el campanario) no estorba.
	if h_max < 0.03 or h_min > 0.80:
		return
	tramos.append({"caja": caja, "p": trozo})

## Cuánta altura le deja al cuerpo el raíl más bajo que tiene encima: `alto` si
## nada lo estorba. `alcance` es su radio más la media anchura del raíl. El cuerpo
## es una cúpula, así que un raíl que solo le roza el borde casi no lo agacha.
static func hueco_bajo_raiil(tramos: Array[Dictionary], suelo: Vector3, alcance: float,
		alto: float) -> float:
	var libre := alto
	for t in tramos:
		var caja: Rect2 = t["caja"]
		if suelo.x < caja.position.x - alcance or suelo.x > caja.end.x + alcance \
				or suelo.z < caja.position.y - alcance or suelo.z > caja.end.y + alcance:
			continue
		var p: PackedVector3Array = t["p"]
		for i in range(1, p.size()):
			var a := p[i - 1]
			var b := p[i]
			var abx := b.x - a.x
			var abz := b.z - a.z
			var l2 := abx * abx + abz * abz
			var u := 0.0
			if l2 > 1e-10:
				u = clampf(((suelo.x - a.x) * abx + (suelo.z - a.z) * abz) / l2, 0.0, 1.0)
			var dx := suelo.x - (a.x + abx * u)
			var dz := suelo.z - (a.z + abz * u)
			var dist := sqrt(dx * dx + dz * dz)
			if dist >= alcance:
				continue
			var hueco := lerpf(a.y, b.y, u) - BAJO_RAIL - suelo.y
			# A ras de losa no es un techo (por ahí no se pasa por debajo); y por
			# encima de lo que mide, no estorba.
			if hueco <= 0.03 or hueco >= alto:
				continue
			var borde := smoothstep(alcance * 0.45, alcance, dist)
			libre = minf(libre, hueco + (alto - hueco) * borde)
	return libre

## Lo que empujan a `c` las criaturas ante las que cede (en planta, unidades 3D):
## las que están a la vista y a menos de `UMBRAL_APARTE`. Se mide con las
## posiciones de la CAZA, no con lo dibujado, para que no se persigan.
static func empuje(yo: Node, c: Criatura, cede_a: PackedStringArray) -> Vector2:
	var total := Vector2.ZERO
	var padre := yo.get_parent()
	if padre == null or cede_a.is_empty():
		return total
	for otro in padre.get_children():
		if otro == yo or not ("c" in otro):
			continue
		var oc: Variant = otro.get("c")
		if not (oc is Criatura):
			continue
		var o := oc as Criatura
		if o == c or not o.activa or not cede_a.has(o.especie):
			continue
		if o.estado == Criatura.Estado.FUERA or o.estado == Criatura.Estado.ESCONDIDA \
				or o.estado == Criatura.Estado.EN_BOLA:
			continue
		var d := (c.pos - o.pos) * E
		var largo := d.length()
		if largo >= UMBRAL_APARTE:
			continue
		# Una encima de otra: hacia un lado fijo por criatura, no a suertes.
		var dir := d / largo if largo > 1e-4 else Vector2.RIGHT.rotated(float(c.indice) * 2.4)
		total += dir * (UMBRAL_APARTE - largo)
	if total.length() > APARTE_MAX:
		total = total.normalized() * APARTE_MAX
	return total

## Pone la transformada del cuerpo: aplastado en altura `agache` con el pivote en
## el suelo que pisa, un pelo más ancho, y movido `aparte`. SOLO PARA LA BRASA Y
## EL ESPECTRO: la calavera va por `_colocar_hueso`, que no aplasta.
static func colocar(yo: Node3D, suelo: Vector3, agache: float, aparte: Vector3) -> void:
	var ancho := 1.0 + (1.0 - agache) * 0.22
	var b := Basis.from_scale(Vector3(ancho, agache, ancho))
	yo.transform = Transform3D(b, suelo - b * suelo + aparte)
