extends RefCounted

## CRIPTA 3D · MÓDULO «bola» · EL CASCABEL
##
## QUÉ MONTA
##   · LAS BOLAS: una por cada hueco de `mesa.p.bolas_maximas` (hay multibola).
##     Cada una es un CASCABEL de acero gastado, como las nueve cáscaras de bola
##     del juego: una esfera de chapa con una RANURA atravesada, el cordón de la
##     costura por detrás y dos coronas de remaches pequeños. Sale de
##     `cripta3d/blender/bola_cascabel.py` → `modelos/bola_cascabel.glb`, en dos
##     trozos: la cáscara (acero de la biblioteca, con su color de vértice) y el
##     HUECO de dentro, que es lo que se ve por la ranura. RUEDAN de verdad:
##     giran lo que avanzan, y la ranura se ve dar vueltas.
##   · LO QUE HACE QUE NO SE PIERDA DE VISTA SOBRE NINGÚN FONDO, medido para que
##     no sea una canica de neón: una segunda pasada sobre el acero
##     (`bola_brillo.gdshader`) con un CANTO frío en el contorno, un PISO de
##     claridad fría y el PUNTO de luz de los sprites, nada de eso dependiente de
##     la luz de la escena; una luz corta encima que alumbra la losa de
##     alrededor; y una SOMBRA DE CONTACTO (`bola_sombra.gdshader`): sin oclusión
##     de pantalla, una bola sin ella flota. La malla NO hace sombra: la posa la
##     de contacto.
##   · EL HALO DE LA CRIATURA (`bola_halo.gdshader`): con una criatura dentro, un
##     aro corto de su color alrededor de la silueta, que late con la ranura.
##   · LA ESTELA, que solo existe deprisa: un BARRIDO tenue del ancho de la bola
##     (`bola_barrido.gdshader`) y CHISPAS de hierro que salta el roce, como una
##     rueda de afilar. Despacio no hay nada.
##
## SEÑALES QUE ESCUCHA   ninguna. Lee `mesa.bolas` en cada cuadro.
##
## FUNCIONES PÚBLICAS
##   tenir(bola: Bola, color: Color)   esa bola lleva una criatura dentro. El
##                                     NÚCLEO la llama EN CADA CUADRO, antes de
##                                     `actualizar`, por cada bola cargada; la que
##                                     un cuadro no recibe la llamada vuelve a su
##                                     color. No hay "destenir". Con criatura, la
##                                     RANURA resplandece de su color (naranja la
##                                     brasa, hueso frío la calavera, violeta el
##                                     espectro), la luz de los labios se escapa
##                                     por fuera, el canto y la luz de encima se
##                                     tiñen, sale el halo, y todo late.
##   calidad(n: int)                   0 ALTA, 1 MEDIA, 2 BAJA (la llama el
##                                     núcleo). En BAJA se van las chispas del
##                                     roce y el barrido; lo que hace legible la
##                                     bola se queda en las tres.
##
## EL PESO: la malla entera (cáscara + hueco) va por debajo de 4.000 triángulos
## (`bola_cascabel.py` imprime la cuenta: hoy 2.789 + 758) y nada de la bola
## proyecta sombra de malla.
##
## LO QUE NO PUEDE DEJAR DE HACER QUIEN LO REESCRIBA
##   1. LA BOLA SE COLOCA EN `mundo.posicion_bola(b)` Y EN NINGÚN OTRO SITIO. La
##      altura no la sabe la simulación (para ella la mesa es plana): la calcula
##      y la SUAVIZA el núcleo, antes de llamar a los módulos —sube pegada al
##      raíl a 6 unidades por segundo, cae a 2,8—, y de ese mismo número cuelgan
##      la cámara, las almas y la criatura que va dentro. No se vuelve a suavizar.
##   2. La bola mide `mundo.r_bola` (0,09) de radio. Es el invariante más viejo
##      del juego: la bola NUNCA cambia de tamaño. El modelo viene a 0,09 y se
##      escala a `r_bola`; los remaches y el cordón sobresalen 3 milésimas, que
##      no se ven como tamaño.
##   3. LA BOLA SE VE SIEMPRE (`LEEME.md`): lleva su canto de luz, su luz y su
##      sombra de contacto. En una cripta a oscuras, un metal pulido refleja
##      negro y se pierde justo lo único que no se puede perder de vista.
##   4. Por debajo de y = −0,03 va por el túnel: no se dibuja ni ella, ni su luz,
##      ni su sombra, ni su estela.
##   4b. La bola RUEDA, así que sus materiales se piden con `{"local": true}`:
##      si no, la textura se queda quieta en el mundo y la bola patina por
##      dentro. Su brillo propio son los parámetros "color_emision" y "emision"
##      de la superficie de la biblioteca, multiplicados por el canal B del color
##      de vértice: en la cáscara B es la cercanía a la ranura (la luz que se
##      escapa), en el hueco vale 1.
##   5. Un material POR HUECO, y el hueco no es la bola: las bolas cambian de
##      hueco (multibola) y se reutilizan (`nueva_bola`). Si el hueco cambia de
##      bola, o la bola acaba de servirse (`en_carril`), el color se pone DE
##      GOLPE: fundiéndolo, un tercio de segundo brillaba del color de la
##      criatura la bola que NO la llevaba.
##   6. Con multibola son hasta cuatro luces más por donde pasen: alcance corto.
##   7. La estela se corta si la bola salta más de 0,7 de un cuadro a otro (la
##      ha escupido un túnel): si no, cruza la mesa una raya. Y con ella las
##      chispas: un salto no es velocidad.
##   8. Nada de esto se crea después de montar: las chispas de la estela son un
##      emisor por hueco que se enciende y se apaga.

const Nucleo := preload("res://cripta3d/mundo_cripta.gd")
const MesaCripta := preload("res://cripta3d/mesa_cripta.gd")
const MODELO := "res://cripta3d/modelos/bola_cascabel.glb"
const SH_BRILLO: Shader = preload("res://cripta3d/mundo/bola_brillo.gdshader")
const SH_SOMBRA: Shader = preload("res://cripta3d/mundo/bola_sombra.gdshader")
const SH_BARRIDO: Shader = preload("res://cripta3d/mundo/bola_barrido.gdshader")
const SH_CHISPA: Shader = preload("res://cripta3d/mundo/efectos_chispa.gdshader")
const SH_HALO: Shader = preload("res://cripta3d/mundo/bola_halo.gdshader")

## El radio al que viene el modelo (los 9 px de `radio_bola`).
const RADIO_MODELO := 0.09

## El canto de luz: frío, como la luna, para que no se confunda con nada de lo
## que arde.
## *Probado y quitado:* 0,32 de canto y nada más. Fuera del charco de luna la
## bola reflejaba fuego, se teñía del mismo bronce que el latón, los engranajes
## y la losa, y se perdía arriba y entre los raíles (la crítica de juego la
## perdió en 5 de 12 capturas). Ahora el canto es más decidido y lleva PISO (un
## mínimo de claridad fría) y PUNTO (el brillo fijo de arriba a la izquierda de
## los sprites): ver `bola_brillo.gdshader`.
const COLOR_CANTO := Color(0.82, 0.88, 1.0)
const CANTO_REPOSO := 0.75
const CANTO_CARGADA := 0.75
const PISO := 0.11
const PUNTO := 1.0
## El acero, un pelo enfriado: con su color neutro, a la luz de veinte llamas
## salía del mismo tono que el latón.
const TINTE_ACERO := Color(0.90, 0.93, 1.0)
const TINTE_HUECO := Color(0.25, 0.25, 0.27)
## El halo de la criatura: lo que sale de la silueta (en radios de bola) y su
## fuerza. Corto: es un aro, no una aureola.
const HALO_ALCANCE := 1.5
const HALO_FUERZA := 0.85
## La luz de encima: casi blanca y un pelo fría. Con más alcance o más energía
## la losa de alrededor se ve iluminada «por nada»; con menos, la bola se pierde
## en la zona de palas cuando la luna no le da.
const COLOR_LUZ := Color(0.86, 0.90, 1.0)
const LUZ_REPOSO := 0.42
const LUZ_CARGADA := 1.3
const ALCANCE_LUZ := 0.95
## EN EL CARRIL LANZADOR, LA LUZ DE ENCIMA SE RECOGE (último retoque). El carril
## es una zanja entre el bordillo y la albardilla, que sube 0,22: la luz va 0,22
## por encima de la bola, o sea casi a ras de la piedra de al lado, y con el
## alcance de campo dejaba en la albardilla una mancha blanco-azulada, lo más
## claro de la esquina de abajo a la derecha de la cámara de juego (no da error:
## se ve). Con el tope de dos orejetas la bola en reposo queda a la vista y la
## mancha con ella. Mientras `b.en_carril`, la energía y el alcance bajan a esta
## fracción; el canto, el piso y el punto de `bola_brillo.gdshader` no dependen
## de la luz de la escena, así que la bola se sigue viendo. Y lo deprisa que
## entra y sale (por segundo), para que al lanzar no se encienda de golpe.
## *Y no basta con `en_carril`:* la sim lo apaga al salir del pasillo y no lo
## vuelve a encender, y una bola que se queda corta en el CAMPANARIO baja otra vez
## por el pasillo y se para en el ariete con `en_carril` a falso (en la ráfaga del
## remate, una captura de cada ocho con bola: la mancha entera otra vez). Así que
## también cuenta estar DENTRO del pasillo, con la misma regla con que
## `mesa_orbita._actualizar_estado` decide que la bola ha salido: x > 358 px e
## y > 940 px (`PASILLO`). Si allí cambia, aquí también.
const LUZ_CARRIL := 0.12
const ALCANCE_CARRIL := 0.4
const CAMBIA_CARRIL := 4.0
const PASILLO := Vector2(358.0, 940.0)
## «Hueso frío»: la calavera da un color de hueso cálido, que en la ranura se
## confundía con el reflejo del fuego. Lo que tenga poco color se enfría hacia
## aquí, y así se lee como hueso a la luz de la luna.
const HUESO_FRIO := Color(0.80, 0.87, 1.0)

## La estela: a partir de qué velocidad (px/s) empieza y a cuál está entera.
## La máxima de la mesa es 1500; una bola que baja suelta de lo alto ronda 600.
const VEL_ESTELA := 760.0
const VEL_ESTELA_LLENA := 1300.0
const PUNTOS_BARRIDO := 6
## El barrido: del color de un metal que refleja fuego.
const COLOR_BARRIDO := Color(1.0, 0.84, 0.64)

var _mundo: Nucleo
var _mesa: MesaCripta

var _nodos: Array[Node3D] = []
var _mats_casco: Array[Material] = []
var _mats_hueco: Array[Material] = []
var _mats_canto: Array[ShaderMaterial] = []
var _luces: Array[OmniLight3D] = []
var _sombras: Array[MeshInstance3D] = []
var _mats_sombra: Array[ShaderMaterial] = []
var _chispas: Array[CPUParticles3D] = []
var _halos: Array[MeshInstance3D] = []
var _mats_halo: Array[ShaderMaterial] = []
## La calidad (0 ALTA, 1 MEDIA, 2 BAJA): en BAJA no hay chispas de roce ni
## barrido. La bola, su canto, su luz y su sombra de contacto se quedan en las
## tres: son lo que la hace legible.
var _calidad := 0
var _barrido: MeshInstance3D
## El color y la fuerza con los que brilla cada hueco ahora mismo (0 = en
## reposo, 1 = con criatura).
var _color: Array[Color] = []
var _carga: Array[float] = []
## Cuánto está cada hueco en el carril lanzador (0..1, suavizado): recoge su luz.
var _en_carril: Array[float] = []
## Qué bola dibujó cada hueco el cuadro anterior, y dónde estaba.
var _bola_del_hueco: Array = []
var _pos_antes: Array[Vector3] = []
## Bola → color de la criatura que lleva dentro. Se rellena con `tenir` y se
## vacía al final de cada `actualizar`.
var _tinte: Dictionary = {}
## Bola → los últimos sitios por los que ha pasado (el barrido).
var _rastro: Dictionary = {}
## Bola → cuánta estela lleva (0..1), ya suavizado.
var _prisa: Dictionary = {}
var _malla_barrido: ImmediateMesh
var _mat_barrido: ShaderMaterial

func montar(mundo: Node3D) -> void:
	_mundo = mundo as Nucleo
	_mesa = _mundo.mesa
	var mallas := _cargar_modelo()
	var casco: Mesh = mallas.get("bola_casco")
	var hueco: Mesh = mallas.get("bola_hueco")
	var escala := _mundo.r_bola / RADIO_MODELO
	if casco == null or hueco == null:
		print("BOLA: falta %s (cripta3d/blender/bola_cascabel.py): pongo una esfera lisa" % MODELO)
		casco = _esfera(_mundo.r_bola)
		hueco = _esfera(_mundo.r_bola * 0.8)
		escala = 1.0

	var sombra_malla := QuadMesh.new()
	sombra_malla.orientation = PlaneMesh.FACE_Y
	sombra_malla.size = Vector2.ONE * _mundo.r_bola * 3.4
	var chispa := _malla_chispa(0.0045, 0.05)
	var halo_malla := QuadMesh.new()
	halo_malla.size = Vector2.ONE * _mundo.r_bola * 2.0 * HALO_ALCANCE

	for _i in maxi(_mesa.p.bolas_maximas, 1):
		# La cáscara: acero gastado, pegado a la bola. El detalle mide lo que la
		# bola (escala ~ su diámetro) para que el grano del acero se vea de cerca.
		var m_casco := (_mundo.mat.dame("acero", {"local": true, "vertice": true,
			"escala": 0.16, "desgaste": 0.65, "suciedad": 0.5, "rugosidad": 1.45,
			"tinte": TINTE_ACERO}) as Material).duplicate() as Material
		var canto := ShaderMaterial.new()
		canto.shader = SH_BRILLO
		canto.set_shader_parameter("color_canto", COLOR_CANTO)
		canto.set_shader_parameter("fuerza", CANTO_REPOSO)
		canto.set_shader_parameter("piso", PISO)
		canto.set_shader_parameter("punto", PUNTO)
		m_casco.next_pass = canto
		# El hueco: carbón. Es la ranura «negra» del sprite, y lo que se enciende
		# con una criatura dentro. *Probado y quitado:* hierro oscurecido; es
		# metal, refleja el cielo, y la ranura se leía como dos rayas claras.
		# Y más negro que el carbón de la biblioteca: con la ranura ancha, el
		# badajo queda justo detrás, la luz de encima de la bola le daba de lleno
		# y la banda negra se leía como dos rayas con un gris en medio.
		var m_hueco := (_mundo.mat.dame("carbon", {"local": true, "vertice": true,
			"tinte": TINTE_HUECO, "rugosidad": 1.5}) as Material).duplicate() as Material
		_brillar(m_casco, COLOR_CANTO, 0.0)
		_brillar(m_hueco, COLOR_CANTO, 0.0)
		_mats_casco.append(m_casco)
		_mats_hueco.append(m_hueco)
		_mats_canto.append(canto)
		_color.append(COLOR_CANTO)
		_carga.append(0.0)
		_en_carril.append(1.0)

		var raiz := Node3D.new()
		raiz.visible = false
		_mundo.add_child(raiz)
		var mi_casco := MeshInstance3D.new()
		mi_casco.mesh = casco
		mi_casco.material_override = m_casco
		mi_casco.scale = Vector3.ONE * escala
		# SIN SOMBRA DE MALLA. Mide 30 px en juego y ya lleva su sombra de
		# contacto, que es la que la posa; la de la malla repetía la bola en cada
		# pasada de sombra (con multibola, cuatro veces) y no se veía.
		mi_casco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(mi_casco)
		var mi_hueco := MeshInstance3D.new()
		mi_hueco.mesh = hueco
		mi_hueco.material_override = m_hueco
		mi_hueco.scale = Vector3.ONE * escala
		mi_hueco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(mi_hueco)
		_nodos.append(raiz)
		_bola_del_hueco.append(null)
		_pos_antes.append(Vector3.ZERO)

		var luz := OmniLight3D.new()
		luz.light_color = COLOR_LUZ
		luz.light_energy = LUZ_REPOSO
		luz.omni_range = ALCANCE_LUZ
		luz.omni_attenuation = 1.6
		# Poco brillo propio sobre el acero: con más, cada bola llevaba un punto
		# blanco quemado en la coronilla, que es lo primero que se ve de un truco.
		luz.light_specular = 0.12
		luz.visible = false
		_mundo.add_child(luz)
		_luces.append(luz)

		var m_sombra := ShaderMaterial.new()
		m_sombra.shader = SH_SOMBRA
		var sombra := MeshInstance3D.new()
		sombra.mesh = sombra_malla
		sombra.material_override = m_sombra
		sombra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sombra.layers = Nucleo.CAPA_SIN_REFLEJO
		sombra.visible = false
		_mundo.add_child(sombra)
		_sombras.append(sombra)
		_mats_sombra.append(m_sombra)

		_chispas.append(_emisor_chispas(chispa))

		var m_halo := ShaderMaterial.new()
		m_halo.shader = SH_HALO
		m_halo.set_shader_parameter("borde_bola", 1.0 / HALO_ALCANCE)
		m_halo.set_shader_parameter("fuerza", 0.0)
		var halo := MeshInstance3D.new()
		halo.mesh = halo_malla
		halo.material_override = m_halo
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		halo.layers = Nucleo.CAPA_SIN_REFLEJO
		halo.visible = false
		_mundo.add_child(halo)
		_halos.append(halo)
		_mats_halo.append(m_halo)

	_malla_barrido = ImmediateMesh.new()
	_mat_barrido = ShaderMaterial.new()
	_mat_barrido.shader = SH_BARRIDO
	_barrido = MeshInstance3D.new()
	_barrido.mesh = _malla_barrido
	_barrido.material_override = _mat_barrido
	_barrido.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_barrido.layers = Nucleo.CAPA_SIN_REFLEJO
	_mundo.add_child(_barrido)

func tenir(bola: Bola, color: Color) -> void:
	_tinte[bola] = color

## LA CALIDAD (la llama el núcleo al arrancar y cada vez que cambia): 0 ALTA,
## 1 MEDIA, 2 BAJA. Lo que pesa de la bola es poco y casi todo es lo que la hace
## legible, así que se queda; en BAJA se van las chispas del roce y el barrido,
## que son adorno de velocidad.
func calidad(n: int) -> void:
	_calidad = clampi(n, 0, 2)
	var adorno := _calidad < 2
	if _barrido != null:
		_barrido.visible = adorno
	if not adorno:
		for ch in _chispas:
			ch.emitting = false

# ------------------------------------------------------------------- el montaje

func _cargar_modelo() -> Dictionary:
	var mallas := {}
	if not ResourceLoader.exists(MODELO):
		return mallas
	var escena := (load(MODELO) as PackedScene).instantiate()
	var pila: Array[Node] = [escena]
	while not pila.is_empty():
		var n: Node = pila.pop_back()
		var mi := n as MeshInstance3D
		if mi != null and mi.mesh != null:
			mallas[String(mi.name)] = mi.mesh
		pila.append_array(n.get_children())
	escena.free()
	return mallas

## Solo si falta el modelo: que el andamio siga jugándose.
func _esfera(radio: float) -> SphereMesh:
	var e := SphereMesh.new()
	e.radius = radio
	e.height = radio * 2.0
	return e

## Una chispa: dos tiras cruzadas a lo largo de Y, con la cabeza en el origen y
## la cola hacia −Y. La partícula alinea Y con su velocidad: así vuela de cabeza.
static func _malla_chispa(ancho: float, largo: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for eje: Vector3 in [Vector3.RIGHT, Vector3.BACK]:
		var a := eje * ancho * 0.5
		var esquinas: Array[Vector3] = [-a, a, a + Vector3.DOWN * largo, -a + Vector3.DOWN * largo]
		var uvs: Array[Vector2] = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		for k: int in [0, 1, 2, 0, 2, 3]:
			st.set_uv(uvs[k])
			st.add_vertex(esquinas[k])
	return st.commit()

## Las chispas del roce: un emisor por hueco, en coordenadas de mundo (se quedan
## atrás cuando la bola se va), que se enciende solo deprisa.
func _emisor_chispas(malla: Mesh) -> CPUParticles3D:
	var m := ShaderMaterial.new()
	m.shader = SH_CHISPA
	m.set_shader_parameter("forma", 0)
	m.set_shader_parameter("energia", 3.2)
	# Más naranja que las de un golpe, y pocas: es un roce, no un choque. *Probado
	# y quitado:* blancas, muchas y saltando hacia arriba; cada lanzamiento era
	# una bengala subiendo por el carril.
	var rampa := Gradient.new()
	rampa.set_color(0, Color(1.0, 0.80, 0.45, 1.0))
	rampa.set_color(1, Color(0.75, 0.16, 0.04, 0.0))
	rampa.add_point(0.3, Color(1.0, 0.50, 0.16, 0.9))
	var ch := CPUParticles3D.new()
	ch.emitting = false
	ch.local_coords = false
	ch.amount = 10
	ch.lifetime = 0.2
	ch.lifetime_randomness = 0.5
	ch.randomness = 1.0
	ch.spread = 28.0
	ch.initial_velocity_min = 0.5
	ch.initial_velocity_max = 1.5
	ch.gravity = Vector3(0.0, -7.0, 0.0)
	ch.damping_min = 0.5
	ch.damping_max = 1.5
	ch.scale_amount_min = 0.5
	ch.scale_amount_max = 1.1
	ch.particle_flag_align_y = true
	ch.color_ramp = rampa
	ch.mesh = malla
	ch.material_override = m
	ch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ch.layers = Nucleo.CAPA_SIN_REFLEJO
	_mundo.add_child(ch)
	return ch

## El brillo propio de un material: en la biblioteca son los parámetros
## "color_emision" y "emision" de la superficie; si ha entrado la de reserva,
## la emisión de un material liso.
func _brillar(material: Material, color: Color, energia: float) -> void:
	var sombreado := material as ShaderMaterial
	if sombreado != null:
		sombreado.set_shader_parameter("color_emision", color)
		sombreado.set_shader_parameter("emision", energia)
		return
	var liso := material as BaseMaterial3D
	if liso != null:
		liso.emission_enabled = true
		liso.emission = color
		liso.emission_energy_multiplier = energia

## El color con el que resplandece la ranura. Lo que trae poco color (el hueso
## de la calavera) se enfría: si no, se confunde con el fuego que refleja todo.
static func _color_criatura(c: Color) -> Color:
	if c.s < 0.35:
		return c.lerp(HUESO_FRIO, 0.6)
	# Algo más de color y algo menos de luz: una luz muy clara, al pasar por la
	# curva de tono, se queda en blanco y deja de decir de quién es.
	return Color.from_hsv(c.h, minf(c.s * 1.25, 1.0), minf(c.v, 0.9))

# ------------------------------------------------------------------ cada cuadro

func actualizar(delta: float) -> void:
	var radio := _mundo.r_bola
	var vivas := {}
	var dt := maxf(delta, 1.0e-4)
	for i in _nodos.size():
		var hay := i < _mesa.bolas.size() and _mesa.bolas[i].viva
		if not hay:
			_apagar(i)
			continue
		var b := _mesa.bolas[i]
		vivas[b] = true
		var pos := _mundo.posicion_bola(b)
		var a_la_vista := pos.y > -0.03
		var nodo := _nodos[i]
		var es_otra: bool = _bola_del_hueco[i] != b

		# Rueda: gira alrededor del eje perpendicular a lo que ha avanzado, lo
		# que ha avanzado partido por su radio. Si ha saltado (bola nueva, túnel)
		# no rueda ese cuadro.
		var paso := pos - _pos_antes[i]
		var salto := es_otra or paso.length() > 0.6
		var plano := Vector3(paso.x, 0.0, paso.z)
		var largo := plano.length()
		if not salto and largo > 1.0e-5:
			var eje := Vector3.UP.cross(plano / largo)
			nodo.basis = (Basis(eje, largo / radio) * nodo.basis).orthonormalized()
		# La velocidad de verdad, la que se ve: la de la simulación no sabe de
		# raíles que suben ni de caídas.
		var vel := Vector3.ZERO if salto else paso / dt
		_pos_antes[i] = pos
		nodo.position = pos
		nodo.visible = a_la_vista

		# Con una criatura dentro: la ranura resplandece y la bola late.
		var lleva: bool = _tinte.has(b)
		var color: Color = _color_criatura(_tinte[b]) if lleva else COLOR_CANTO
		var k := 1.0 - exp(-10.0 * delta)
		if es_otra or b.en_carril:
			k = 1.0
		_bola_del_hueco[i] = b
		_color[i] = _color[i].lerp(color, k)
		_carga[i] = lerpf(_carga[i], 1.0 if lleva else 0.0, k)
		var carga := _carga[i]
		var pulso := 0.8 + 0.2 * sin(_mundo.tiempo * 9.0 + float(i) * 1.7)
		# Sin pasarse: con más energía la curva de tono la lleva al blanco y la
		# brasa, la calavera y el espectro se encienden los tres iguales, como un
		# tubo. Lo que da la luz es el badajo (B = 1 en el modelo); la chapa de
		# dentro y los labios, mucho menos.
		# *Probado y quitado:* 2,4 en el badajo y 0,45 en los labios, sin halo.
		# Con la ranura estrecha y a 30 px, la bola con espectro era «apenas un
		# velo violeta»: no se sabía que llevaba nada. Ahora la ranura es ancha,
		# los labios cogen más color y hay un halo corto (`bola_halo.gdshader`).
		_brillar(_mats_hueco[i], _color[i], carga * 3.0 * pulso)
		_brillar(_mats_casco[i], _color[i], carga * 0.8 * pulso)
		_mats_canto[i].set_shader_parameter("color_canto", COLOR_CANTO.lerp(_color[i], carga * 0.8))
		_mats_canto[i].set_shader_parameter("fuerza", lerpf(CANTO_REPOSO, CANTO_CARGADA * pulso, carga))
		var halo := _halos[i]
		halo.visible = a_la_vista and carga > 0.02
		if halo.visible:
			halo.position = pos
			_mats_halo[i].set_shader_parameter("color", _color[i])
			_mats_halo[i].set_shader_parameter("fuerza", carga * HALO_FUERZA * pulso)

		var luz := _luces[i]
		luz.position = pos + Vector3(0.0, 0.22, 0.0)
		luz.visible = a_la_vista
		luz.light_color = COLOR_LUZ.lerp(_color[i], carga * 0.85)
		# Una bola nueva (o que cambia de hueco) entra con el carril puesto de
		# golpe: si no, el primer cuarto de segundo manchaba la albardilla.
		var en_pasillo := b.en_carril or (b.pos.x > PASILLO.x and b.pos.y > PASILLO.y)
		# `salto` y no solo `es_otra`: al perder la bola la mesa REUTILIZA la misma
		# y la planta en el carril de un cuadro a otro, y fundiéndolo desde el
		# campo los primeros cuartos de segundo manchaba igual.
		if salto:
			_en_carril[i] = 1.0 if en_pasillo else 0.0
		_en_carril[i] = move_toward(_en_carril[i], 1.0 if en_pasillo else 0.0, delta * CAMBIA_CARRIL)
		var recoge := lerpf(1.0, LUZ_CARRIL, _en_carril[i])
		luz.light_energy = lerpf(LUZ_REPOSO, LUZ_CARGADA * pulso, carga) * recoge
		luz.omni_range = lerpf(ALCANCE_LUZ, ALCANCE_CARRIL, _en_carril[i])

		_poner_sombra(i, b, pos, a_la_vista)

		# La estela: cuánta toca, suavizado para que no parpadee en el umbral.
		var rapidez := vel.length() / Nucleo.E
		var objetivo := clampf((rapidez - VEL_ESTELA) / (VEL_ESTELA_LLENA - VEL_ESTELA), 0.0, 1.0)
		if not a_la_vista or salto:
			objetivo = 0.0
		var prisa: float = _prisa.get(b, 0.0)
		prisa = objetivo if objetivo > prisa else lerpf(prisa, objetivo, 1.0 - exp(-8.0 * delta))
		_prisa[b] = prisa
		_poner_chispas(i, pos, vel, prisa)

		var rastro: Array = _rastro.get(b, [])
		if not a_la_vista or salto or (not rastro.is_empty() \
				and (rastro[0] as Vector3).distance_to(pos) > 0.7):
			rastro.clear()
		if a_la_vista:
			rastro.push_front(pos)
		if rastro.size() > PUNTOS_BARRIDO:
			rastro.resize(PUNTOS_BARRIDO)
		_rastro[b] = rastro
	for b in _rastro.keys():
		if not vivas.has(b):
			_rastro.erase(b)
			_prisa.erase(b)
	_dibujar_barridos()
	_tinte.clear()

func _apagar(i: int) -> void:
	_nodos[i].visible = false
	_luces[i].visible = false
	_sombras[i].visible = false
	_halos[i].visible = false
	_chispas[i].emitting = false
	_bola_del_hueco[i] = null

## La sombra de contacto: en el suelo que hay debajo (la losa o la tribuna del
## coro), y más floja cuanto más alta va la bola. En un raíl se apaga sola; en el
## sarcófago no hay suelo debajo, hay un hoyo.
func _poner_sombra(i: int, b: Bola, pos: Vector3, a_la_vista: bool) -> void:
	var sombra := _sombras[i]
	var suelo := _mundo.altura_en(b.pos)
	var altura := pos.y - _mundo.r_bola - suelo
	var fuerza := 1.0 - clampf(altura / 0.32, 0.0, 1.0)
	sombra.visible = a_la_vista and b.platillo < 0 and fuerza > 0.02
	if not sombra.visible:
		return
	sombra.position = Vector3(pos.x, suelo + 0.003, pos.z)
	# Al subir, la penumbra se abre y se aclara.
	sombra.scale = Vector3.ONE * (1.0 + clampf(altura, 0.0, 0.32) * 2.0)
	_mats_sombra[i].set_shader_parameter("fuerza", fuerza * fuerza)

## Las chispas del roce: salen del punto de apoyo, hacia atrás y un poco arriba.
func _poner_chispas(i: int, pos: Vector3, vel: Vector3, prisa: float) -> void:
	var ch := _chispas[i]
	var encender := prisa > 0.4 and _calidad < 2
	if encender:
		var dir := Vector3(vel.x, 0.0, vel.z)
		if dir.length_squared() > 1.0e-6:
			dir = dir.normalized()
			ch.position = pos + Vector3(0.0, -_mundo.r_bola * 0.85, 0.0) - dir * _mundo.r_bola * 0.4
			ch.direction = (-dir + Vector3.UP * 0.22).normalized()
			ch.initial_velocity_max = 0.7 + 0.9 * prisa
	if ch.emitting != encender:
		ch.emitting = encender

## El barrido: una tira del ancho de la bola por donde acaba de pasar, de cara a
## la cámara, que se deshace por los bordes y por la cola.
func _dibujar_barridos() -> void:
	_malla_barrido.clear_surfaces()
	if _calidad >= 2:
		return
	var cam: Camera3D = null
	if _mundo.is_inside_tree():
		cam = _mundo.get_viewport().get_camera_3d()
	if cam == null:
		return
	var ojo := cam.global_position
	for b: Bola in _rastro:
		var rastro: Array = _rastro[b]
		var n := rastro.size()
		var prisa: float = _prisa.get(b, 0.0)
		if n < 3 or prisa < 0.05:
			continue
		var base: Color = _color_criatura(_tinte[b]) if _tinte.has(b) else COLOR_BARRIDO
		_malla_barrido.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _mat_barrido)
		for j in n:
			var p0: Vector3 = rastro[j]
			var p1: Vector3 = rastro[mini(j + 1, n - 1)]
			var pm: Vector3 = rastro[maxi(j - 1, 0)]
			var lateral := (pm - p1).cross(ojo - p0)
			if lateral.length_squared() < 1.0e-10:
				lateral = Vector3.RIGHT
			var v := float(j) / float(n - 1)
			lateral = lateral.normalized() * _mundo.r_bola * (0.95 - 0.35 * v)
			var col := Color(base.r, base.g, base.b, 0.30 * prisa)
			_malla_barrido.surface_set_color(col)
			_malla_barrido.surface_set_uv(Vector2(0.0, v))
			_malla_barrido.surface_add_vertex(p0 - lateral)
			_malla_barrido.surface_set_color(col)
			_malla_barrido.surface_set_uv(Vector2(1.0, v))
			_malla_barrido.surface_add_vertex(p0 + lateral)
		_malla_barrido.surface_end()
