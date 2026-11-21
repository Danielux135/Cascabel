extends RefCounted

## CRIPTA 3D · MÓDULO «efectos» · LO QUE DURA UN INSTANTE
##
## QUÉ MONTA: todo lo que salta, se levanta o vuela cuando pasa algo en la mesa,
## y todo con caducidad. Nada de anillos de neón: cada cosa es de cripta.
##   · CHISPAS DE HIERRO: rayas de metal al rojo que vuelan y caen. En los golpes
##     de metal (braseros, el hierro de las palas y de los escudos, la entrada a
##     un raíl) y en lo que arde (la brasa).
##   · PAVESAS: el ascua de un brasero que salta con el golpe y SUBE, flotando,
##     hasta apagarse.
##   · POLVO DE PIEDRA: una bocanada que se ilumina con lo que tenga cerca (en lo
##     oscuro casi no se ve, como el polvo), más ESQUIRLAS que caen. En las
##     lápidas, en las PAREDES (ver abajo), al caer la bola y donde haya hueso
##     (las esquirlas de la calavera son de hueso; las del escudo, de madera).
##   · ONDAS DE POLVO: un anillo bajo de polvo que se abre a ras de losa. Si el
##     suceso tiene color, su frente lleva un resplandor rasante débil.
##   · MOTAS: puntos de luz para lo que no es fuego ni piedra (el espectro, la
##     catacumba): la magia, con cuentagotas.
##   · ALMAS: jirones de luz del color de la criatura, que van de ella a la bola
##     en espiral y se le meten dentro.
##   El polvo que flota quieto en el aire y las pavesas que se escapan solas de
##   los braseros NO son de aquí: los pone «entorno», que los mueve en el
##   sombreador sin gastar nada por cuadro.
##
## LAS PAREDES. La mesa no avisa cuando la bola da contra un sillar (no hay
## señal: para la simulación es un rebote más). Aquí se DEDUCE: si la velocidad
## de una bola cambia de golpe hacia atrás y en ese sitio no ha sonado ninguna
## señal de pieza (ni un brasero, ni una pala, ni una criatura) y no hay otra
## bola pegada, ha sido una pared. El polvo sale del punto de contacto, que es
## la bola menos su radio en la dirección del cambio.
##
## SEÑALES QUE ESCUCHA (de `mundo.mesa`): pone la chispa, el polvo, la onda, la
## sacudida de cámara y el latido de TODO lo que le pasa a la mesa. Las piezas
## solo se mueven ellas («piezas», «railes»); lo que salta de ellas es de aquí.
##   bumper_golpeado     chispas de hierro, pavesas del brasero, onda de polvo
##                       con brillo de ascua, sacudida según la fuerza, latido
##   slingshot_golpeado  una bocanada de polvo y unas chispas, sacudida
##   poste_golpeado      una bocanada pequeña
##   flipper_golpeado    si pega fuerte, unas chispas: hierro contra acero
##   target_abatido      lápidas: polvo, esquirlas y onda; escudos: astillas y chispas
##   bola_cayo           polvo y una onda pequeña donde cae
##   rampa_entrada       raíl: chispas en la boca; túnel: onda arcana en la boca
##   rampa_salida        si es el túnel: onda y motas arcanas en la otra boca
##   platillo_capturado  latido, sacudida y una bocanada en el sarcófago
##   platillo_expulsado  latido (el polvo, las chispas y la onda los pone «piezas»)
##   descarga_empezada   la CAMPANA MAYOR toca: una onda, chispas de bronce,
##                       latido, sacudida y el TAÑIDO (ver `tanido`)
##   (de la caza, solo para saber dónde NO ha sido una pared:
##    criatura_golpeada, criatura_blindada)
##
## FUNCIONES PÚBLICAS (el núcleo las ofrece a todos como `mundo.chispear` y
## `mundo.onda`, y llama él a `soltar_almas`)
##   chispear(punto: Vector2, altura: float, color: Color, cuantas: int)
##       EL COLOR DECIDE QUÉ SALTA: fuego (rojos, naranjas, oros) → chispas de
##       hierro; sin color (piedra, hueso, gris) → polvo y esquirlas de ese color;
##       lo demás (violetas, verdes, azules) → motas de luz.
##   onda(punto: Vector2, altura: float, color: Color, radio: float)
##   soltar_almas(desde: Vector3, bola: Bola, color: Color, cuantas: int)
##   tanido(punto: Vector2 = CAMPANA_PX)
##       LA ONDA DE LA CAMPANA A RAS DE SUELO (decisión 9): un aro fino de polvo
##       dorado que sale de la vertical de la campana y cruza el campo hasta las
##       palas en 1,5 s, avivando cada fuego del campo cuando le llega. Ya la
##       dispara este módulo con `descarga_empezada`; quien la pida además (p.
##       ej. «atrezzo», con otro punto) no la duplica: dos tañidos a menos de
##       0,3 s son uno.
##   calidad(n: int)   0 ALTA, 1 MEDIA, 2 BAJA (la llama el núcleo)
##   `punto` va en píxeles de mesa; `altura`, `radio` y `desde`, en unidades 3D.
##
## LO QUE NO TAPA: en la ZONA DE PALAS (z > `Z_PALAS`, 11) no se levanta polvo y
## las ondas se quedan pequeñas y flojas; solo saltan chispas. Las almas son un
## trazo fino y rápido. Las pavesas y las motas son puntos, no discos de luz.
##
## LO QUE NO PUEDE DEJAR DE HACER QUIEN LO REESCRIBA
##   1. Esas tres funciones, con esa firma: la caza entera habla por ellas (el
##      núcleo las llama en quince sucesos de las criaturas, y «piezas» en el
##      sarcófago). Si faltan no revienta nada, pero la caza se queda muda.
##   2. TODO EFECTO CADUCA SOLO. Aquí no se crea ni un nodo después de montar:
##      hay un cupo fijo de cada cosa y se reutiliza el más viejo. Un emisor por
##      golpe, creado al vuelo, son miles de nodos en una partida larga.
##   3. `mundo.sacudida` y `mundo.latir()` se suben AQUÍ, con `maxf`: nunca se
##      suman (dos golpes seguidos no pueden tirar la cámara el doble) y nunca
##      se bajan (se apagan solas en el núcleo).
##   4. Las almas persiguen a `mundo.posicion_bola(bola)` en cada cuadro, no al
##      sitio donde estaba la bola al recogerla: la bola no se para.
##   5. Nada de esto se refleja en el suelo: todo va en `Nucleo.CAPA_SIN_REFLEJO`
##      (el reflejo repite cada llamada de dibujo, y en un navegador cuestan).
##   6. El color viene dado en los sucesos de la caza (es el de la criatura).
##      Los de la mesa se deciden aquí, y la regla es de `LEEME.md`: fuego para
##      lo que arde, hueso y piedra para lo demás, arcano SOLO en la catacumba.
##   7. El polvo y las ondas se ILUMINAN y se SUMAN: no tienen luz propia y no
##      tapan nada. Si en una captura no se ven en un rincón oscuro, es lo
##      correcto; si no se ven junto a un brasero, algo falla. Y si salen como
##      una mancha negra, alguien los ha vuelto a mezclar en vez de sumarlos.

const Nucleo := preload("res://cripta3d/mundo_cripta.gd")
const MesaCripta := preload("res://cripta3d/mesa_cripta.gd")
const SH_CHISPA: Shader = preload("res://cripta3d/mundo/efectos_chispa.gdshader")
## La bocanada y la onda son el MISMO sombreador (`forma` 0 y 1): eran dos y
## compilaban 3,4 y 3,2 s en el navegador; juntos, uno de 1,0 (ver su cabecera).
const SH_POLVO: Shader = preload("res://cripta3d/mundo/efectos_polvo.gdshader")
const FORMA_BOCANADA := 0
const FORMA_ONDA := 1
const SH_JIRON: Shader = preload("res://cripta3d/mundo/efectos_jiron.gdshader")
const TEX_MANCHAS: Texture2D = preload("res://cripta3d/texturas/ruido_manchas.png")

## Los cupos. Se reutiliza el más viejo cuando se acaban.
const CHISPAS := 10
const PAVESAS := 4
const POLVOS := 8
const ESQUIRLAS := 8
const MOTAS := 6
const ONDAS := 8
const ALMAS := 21
## Lo que mide la cola de un alma, en cuadros.
const COLA_ALMA := 8
## LAS ALMAS SON UN TRAZO, NO UNA BANDA: medio ancho de la tira, lo que tardan
## en llegar a la bola (s) y lo que se abre su espiral.
## *Probado y quitado:* 0,028 de medio ancho, 0,62 s y 0,20 de espiral. Siete
## almas así eran siete bandas blancas que barrían la inlane y la pala justo
## cuando la bola llegaba a ella (z_d07 de la crítica de juego).
const ALMA_ANCHO := 0.011
const ALMA_VIAJE := 0.42
const ALMA_ESPIRAL := 0.11

## LA ZONA DE PALAS: de aquí hacia el jugador (z en unidades 3D) no se levanta
## polvo. Es donde se decide la partida y lo único que hay que ver es la bola y
## la pala en el momento de golpear; el polvo y una onda ancha las tapaban
## varios cuadros (la crítica: un anillo gris de 300 px encima de la pala
## izquierda al asegurar una criatura, y una bola de la multibola escondida tras
## la pala dentro de una nube). Aquí solo saltan chispas, y las ondas se quedan
## pequeñas y flojas.
const Z_PALAS := 11.0
const ONDA_PALAS_RADIO := 0.24
const ONDA_PALAS_OPACIDAD := 0.4

## EL TAÑIDO: la onda de la campana mayor a ras de suelo (decisión 9 de la
## dirección). Un anillo fino de polvo dorado que sale de la vertical de la
## campana y cruza el campo entero, y que aviva cada fuego del campo cuando le
## pasa por encima. Es lo que deja la campana en la cámara de juego, que no la
## tiene en plano.
const TANIDOS := 2
const CAMPANA_PX := Vector2(160.0, 742.0)
const TANIDO_RADIO := 5.2
const TANIDO_DURA := 1.5
## Dos tañidos más juntos que esto son el mismo (lo pueden pedir a la vez
## «atrezzo» y la señal de la mesa).
const TANIDO_JUNTOS := 0.3
## Qué cuenta como fuego del campo: dentro de la mesa, con un poco de margen.
const CAMPO := Rect2(0.0, 5.4, 4.0, 7.6)
## Lo que se ve del tañido: el tablero, de banda a banda y del ábside al pie.
const MESA_X := Vector2(0.2, 3.8)
const MESA_Z := Vector2(5.6, 12.7)

## Lo que se lee de un color: qué salta.
enum Clase { FUEGO, POLVO, MAGIA }

## Una pared: el cambio de velocidad (px/s) a partir del que es un golpe, el
## radio (px) alrededor de una señal de pieza en el que NO puede haberlo sido, y
## cuánto vale esa señal (s).
const PARED_DV := 240.0
const PARED_LEJOS := 46.0
const PARED_RECUERDO := 0.12

## El color del polvo de la cripta: piedra clara, que la luz del fuego tiñe.
const COLOR_POLVO := Color(0.46, 0.43, 0.38)

var _mundo: Nucleo
var _mesa: MesaCripta

var _chispas: Array[CPUParticles3D] = []
var _chispa_siguiente := 0
var _pavesas: Array[CPUParticles3D] = []
var _pavesa_siguiente := 0
var _polvos: Array[CPUParticles3D] = []
var _polvo_siguiente := 0
var _esquirlas: Array[CPUParticles3D] = []
var _esquirla_siguiente := 0
var _motas: Array[CPUParticles3D] = []
var _mota_siguiente := 0
var _ondas: Array[Dictionary] = []
var _onda_siguiente := 0
var _almas: Array[Dictionary] = []
var _malla_almas: ImmediateMesh
var _mat_almas: ShaderMaterial
var _tanidos: Array[Dictionary] = []
var _tanido_siguiente := 0
var _ultimo_tanido := -10.0
## 0 ALTA, 1 MEDIA, 2 BAJA. Ver `calidad`.
var _calidad := 0

## Las señales de pieza recientes: {punto, t}. Para descartar paredes.
var _sucesos: Array[Dictionary] = []
## Bola → {vel, espera}: lo que llevaba el cuadro anterior.
var _vel_antes: Dictionary = {}
var _caza_oida := false

func montar(mundo: Node3D) -> void:
	_mundo = mundo as Nucleo
	_mesa = _mundo.mesa
	_montar_chispas()
	_montar_pavesas()
	_montar_polvo()
	_montar_esquirlas()
	_montar_motas()
	_montar_ondas()
	_montar_tanidos()
	_montar_almas()
	_mesa.bumper_golpeado.connect(_al_golpear_brasero)
	_mesa.slingshot_golpeado.connect(_al_golpear_goma)
	_mesa.poste_golpeado.connect(_al_golpear_poste)
	_mesa.flipper_golpeado.connect(_al_golpear_pala)
	_mesa.target_abatido.connect(_al_abatir)
	_mesa.bola_cayo.connect(_al_caer)
	_mesa.rampa_entrada.connect(_al_entrar_rampa)
	_mesa.rampa_salida.connect(_al_salir_rampa)
	_mesa.platillo_capturado.connect(_al_tragar)
	_mesa.platillo_expulsado.connect(_al_escupir)
	_mesa.descarga_empezada.connect(_al_tocar_campana)

# ---------------------------------------------------------------- los emisores

## Un emisor de usar y volver a usar, ya colgado y fuera del reflejo.
func _emisor(malla: Mesh, material: Material, cuantas: int, vida: float) -> CPUParticles3D:
	var e := CPUParticles3D.new()
	e.emitting = false
	e.one_shot = true
	e.explosiveness = 1.0
	e.local_coords = false
	e.amount = cuantas
	e.lifetime = vida
	e.mesh = malla
	e.material_override = material
	e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	e.layers = Nucleo.CAPA_SIN_REFLEJO
	_mundo.add_child(e)
	return e

func _disparar(e: CPUParticles3D, donde: Vector3, cuantas: int) -> void:
	e.amount = maxi(cuantas, 1)
	e.position = donde
	e.restart()
	e.emitting = true

static func _rampa(colores: PackedColorArray, sitios: PackedFloat32Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = sitios
	g.colors = colores
	return g

static func _curva(puntos: PackedVector2Array) -> Curve:
	var c := Curve.new()
	for p in puntos:
		c.add_point(p)
	return c

func _material_luz(forma: int, energia: float, halo: float = 0.5) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_CHISPA
	m.set_shader_parameter("forma", forma)
	m.set_shader_parameter("energia", energia)
	m.set_shader_parameter("halo", halo)
	return m

## La raya de una chispa: dos tiras cruzadas a lo largo de Y, la cabeza en el
## origen y la cola hacia −Y (la partícula alinea Y con su velocidad).
static func _malla_raya(ancho: float, largo: float) -> ArrayMesh:
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

## Una esquirla: un pedrusco de ocho caras aplastado y torcido. No es una
## primitiva: cada una de las cuatro que se hacen tiene sus vértices movidos.
static func _malla_esquirla(lado: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var v: Array[Vector3] = [Vector3(1.0, 0.1, 0.2), Vector3(-0.8, -0.1, 0.3), Vector3(0.1, 0.55, -0.2),
		Vector3(0.2, -0.45, 0.1), Vector3(0.1, 0.2, 0.9), Vector3(-0.2, -0.1, -1.0)]
	var caras: Array[Vector3i] = [Vector3i(0, 2, 4), Vector3i(2, 1, 4), Vector3i(1, 3, 4), Vector3i(3, 0, 4),
		Vector3i(2, 0, 5), Vector3i(1, 2, 5), Vector3i(3, 1, 5), Vector3i(0, 3, 5)]
	for c in caras:
		var a := v[c.x] * lado
		var b := v[c.y] * lado
		var d := v[c.z] * lado
		var n := (b - a).cross(d - a).normalized()
		st.set_normal(n)
		st.add_vertex(a)
		st.set_normal(n)
		st.add_vertex(b)
		st.set_normal(n)
		st.add_vertex(d)
	return st.commit()

func _montar_chispas() -> void:
	var raya := _malla_raya(0.006, 0.075)
	var m := _material_luz(0, 3.4)
	var rampa := _rampa(PackedColorArray([Color(1.0, 0.95, 0.80, 1.0), Color(1.0, 0.62, 0.26, 1.0),
		Color(0.85, 0.22, 0.06, 0.8), Color(0.4, 0.06, 0.02, 0.0)]), PackedFloat32Array([0.0, 0.25, 0.6, 1.0]))
	for _i in CHISPAS:
		var ch := _emisor(raya, m, 12, 0.55)
		ch.lifetime_randomness = 0.55
		ch.randomness = 1.0
		ch.direction = Vector3.UP
		ch.spread = 70.0
		ch.initial_velocity_min = 1.2
		ch.initial_velocity_max = 3.6
		ch.gravity = Vector3(0.0, -9.0, 0.0)
		ch.damping_min = 0.4
		ch.damping_max = 1.4
		ch.scale_amount_min = 0.45
		ch.scale_amount_max = 1.15
		ch.particle_flag_align_y = true
		ch.color_ramp = rampa
		ch.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		ch.emission_sphere_radius = 0.02
		_chispas.append(ch)

## LAS PAVESAS: puntos de ascua, no discos de luz.
## *Probado y quitado:* 0,022 de lado, energía 2,6 y halo ancho, 1,7 s de vida.
## Subían por toda la mesa como motas grandes casi blancas, desenfocadas (un
## «bokeh»), y competían con el polvo frío del rayo de luna, que es el que tiene
## que leerse. Ahora son la mitad, más rojas, apagadas y de vida corta.
func _montar_pavesas() -> void:
	var punto := QuadMesh.new()
	punto.size = Vector2(0.011, 0.011)
	var m := _material_luz(1, 1.5, 0.12)
	var rampa := _rampa(PackedColorArray([Color(1.0, 0.70, 0.35, 0.0), Color(1.0, 0.55, 0.20, 1.0),
		Color(0.95, 0.30, 0.08, 0.8), Color(0.6, 0.08, 0.03, 0.0)]), PackedFloat32Array([0.0, 0.08, 0.45, 1.0]))
	for _i in PAVESAS:
		var p := _emisor(punto, m, 12, 1.1)
		p.explosiveness = 0.75
		p.lifetime_randomness = 0.5
		p.randomness = 1.0
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.09
		p.direction = Vector3.UP
		p.spread = 40.0
		p.initial_velocity_min = 0.35
		p.initial_velocity_max = 1.0
		# Suben: el aire caliente las lleva, y se frenan al enfriarse.
		p.gravity = Vector3(0.0, 0.35, 0.0)
		p.damping_min = 0.6
		p.damping_max = 1.4
		p.tangential_accel_min = -0.5
		p.tangential_accel_max = 0.5
		p.scale_amount_min = 0.35
		p.scale_amount_max = 1.0
		p.color_ramp = rampa
		_pavesas.append(p)

## EL POLVO DE GOLPE: una bocanada que cabe en dos bolas, floja y corta.
## *Probado y quitado:* 0,16 de lado que crecía al triple, opacidad 0,55 y 1,3 s.
## Era una nube que se quedaba encima de la pala y de la bola justo en el
## momento de golpear. Ahora mide como mucho 0,18 (dos radios de bola) y se va
## en menos de un segundo.
func _montar_polvo() -> void:
	var bocanada := QuadMesh.new()
	bocanada.size = Vector2(0.12, 0.12)
	var m := ShaderMaterial.new()
	m.shader = SH_POLVO
	m.set_shader_parameter("forma", FORMA_BOCANADA)
	m.set_shader_parameter("tex_manchas", TEX_MANCHAS)
	m.set_shader_parameter("opacidad", 0.3)
	for _i in POLVOS:
		var p := _emisor(bocanada, m, 6, 0.75)
		p.explosiveness = 0.92
		p.lifetime_randomness = 0.35
		p.randomness = 1.0
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.025
		p.direction = Vector3.UP
		p.spread = 80.0
		p.initial_velocity_min = 0.1
		p.initial_velocity_max = 0.35
		p.gravity = Vector3(0.0, 0.05, 0.0)
		p.damping_min = 1.2
		p.damping_max = 2.4
		p.angle_min = 0.0
		p.angle_max = 360.0
		# Se abre: de un bulto a una nube algo más del doble.
		p.scale_amount_min = 0.6
		p.scale_amount_max = 1.0
		p.scale_amount_curve = _curva(PackedVector2Array([Vector2(0.0, 0.4), Vector2(0.35, 0.85), Vector2(1.0, 1.0)]))
		_polvos.append(p)

func _montar_esquirlas() -> void:
	var piedra := _malla_esquirla(0.016)
	for _i in ESQUIRLAS:
		var e := _emisor(piedra, _mundo.mat.dame("piedra"), 10, 0.7)
		e.lifetime_randomness = 0.4
		e.randomness = 1.0
		e.direction = Vector3.UP
		e.spread = 65.0
		e.initial_velocity_min = 0.8
		e.initial_velocity_max = 2.2
		e.gravity = Vector3(0.0, -9.8, 0.0)
		e.scale_amount_min = 0.4
		e.scale_amount_max = 1.2
		e.scale_amount_curve = _curva(PackedVector2Array([Vector2(0.0, 1.0), Vector2(0.7, 1.0), Vector2(1.0, 0.0)]))
		e.particle_flag_rotate_y = true
		e.angle_min = 0.0
		e.angle_max = 360.0
		e.angular_velocity_min = -720.0
		e.angular_velocity_max = 720.0
		_esquirlas.append(e)

func _montar_motas() -> void:
	# Más pequeñas y más flojas que antes (0,03 y 2,4): por la misma razón que
	# las pavesas, salían como discos desenfocados.
	var punto := QuadMesh.new()
	punto.size = Vector2(0.018, 0.018)
	var m := _material_luz(1, 1.7, 0.3)
	for _i in MOTAS:
		var p := _emisor(punto, m, 12, 0.9)
		p.lifetime_randomness = 0.5
		p.randomness = 1.0
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.05
		p.direction = Vector3.UP
		p.spread = 90.0
		p.initial_velocity_min = 0.3
		p.initial_velocity_max = 1.1
		p.gravity = Vector3(0.0, 0.4, 0.0)
		p.damping_min = 1.5
		p.damping_max = 3.0
		p.scale_amount_min = 0.4
		p.scale_amount_max = 1.0
		p.scale_amount_curve = _curva(PackedVector2Array([Vector2(0.0, 0.2), Vector2(0.15, 1.0), Vector2(1.0, 0.0)]))
		_motas.append(p)

# ---------------------------------------------------------------- lo público

static func _clase(color: Color) -> Clase:
	if color.s < 0.32:
		return Clase.POLVO
	if color.h < 0.17 or color.h > 0.93:
		return Clase.FUEGO
	return Clase.MAGIA

## Lo que salta de un golpe, en un punto de la mesa. El COLOR decide qué es
## (ver la cabecera). Coge el emisor que lleva más tiempo sin usarse: si todos
## están en el aire, se corta el más viejo.
func chispear(punto: Vector2, altura: float, color: Color, cuantas: int) -> void:
	var donde := _mundo.a3(punto, altura)
	match _clase(color):
		Clase.FUEGO:
			_hierro(donde, color, cuantas)
		Clase.POLVO:
			_polvo(donde, color, cuantas)
		Clase.MAGIA:
			_magia(donde, color, cuantas)

func _hierro(donde: Vector3, color: Color, cuantas: int) -> void:
	if _chispas.is_empty():
		return
	var ch := _chispas[_chispa_siguiente]
	_chispa_siguiente = (_chispa_siguiente + 1) % _chispas.size()
	# La rampa ya va del blanco al rojo; el color del suceso la tiñe un poco
	# (el oro de la campana, el rojo de una boca tapada).
	ch.color = Color(1.0, 1.0, 1.0).lerp(color.lightened(0.3), 0.45)
	_disparar(ch, donde, cuantas)

func _polvo(donde: Vector3, color: Color, cuantas: int) -> void:
	_bocanada(donde, color, maxi(2, int(float(cuantas) / 3.0)))
	if _esquirlas.is_empty() or _calidad >= 2:
		return
	# En la zona de palas, pocas: una lluvia de piedrecitas también tapa la pala.
	if donde.z > Z_PALAS:
		cuantas = mini(cuantas, 4)
	var e := _esquirlas[_esquirla_siguiente]
	_esquirla_siguiente = (_esquirla_siguiente + 1) % _esquirlas.size()
	e.material_override = _material_esquirla(color)
	_disparar(e, donde, cuantas)

## Una bocanada de polvo sin esquirlas.
func _bocanada(donde: Vector3, color: Color, cuantas: int) -> void:
	# Ni en la zona de palas (ver `Z_PALAS`) ni en BAJA, donde el polvo es lo
	# primero que sobra: son cuadros semitransparentes grandes, y en un portátil
	# lo que cuesta es pintar píxeles encima de píxeles.
	if _polvos.is_empty() or donde.z > Z_PALAS or _calidad >= 2:
		return
	var p := _polvos[_polvo_siguiente]
	_polvo_siguiente = (_polvo_siguiente + 1) % _polvos.size()
	p.color = COLOR_POLVO.lerp(color, 0.35)
	_disparar(p, donde, cuantas)

## La esquirla es de lo que es el golpe: hueso si es claro y cálido, madera si
## es pardo, piedra si no.
func _material_esquirla(color: Color) -> Material:
	if color.v > 0.82:
		return _mundo.mat.dame("hueso")
	if color.h > 0.02 and color.h < 0.12 and color.s > 0.2 and color.v < 0.55:
		return _mundo.mat.dame("madera")
	return _mundo.mat.dame("piedra")

func _magia(donde: Vector3, color: Color, cuantas: int) -> void:
	if _motas.is_empty():
		return
	var p := _motas[_mota_siguiente]
	_mota_siguiente = (_mota_siguiente + 1) % _motas.size()
	p.color = color.lightened(0.15)
	_disparar(p, donde, cuantas)

## El ascua de un brasero salta y sube.
func _avivar_pavesas(donde: Vector3, cuantas: int) -> void:
	if _pavesas.is_empty() or _calidad >= 2:
		return
	if _calidad == 1:
		cuantas = maxi(int(float(cuantas) * 0.5), 3)
	var p := _pavesas[_pavesa_siguiente]
	_pavesa_siguiente = (_pavesa_siguiente + 1) % _pavesas.size()
	_disparar(p, donde, cuantas)

# ------------------------------------------------------------------------ ondas

## El anillo de la onda: bajo, con lomo. Radio de fuera 1, de dentro `dentro`
## (0,45 la de siempre; casi 1 el tañido, que es un aro fino), el lomo a medio
## camino y a 1 de alto (el nodo lo escala). UV.x da la vuelta, UV.y va de
## dentro afuera.
static func _malla_onda(dentro: float = 0.45, seg: int = 48) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var filas: Array[Vector2] = [Vector2(dentro, 0.0), Vector2((dentro + 1.0) * 0.5, 1.0), Vector2(1.0, 0.0)]
	for k in seg:
		var a0 := TAU * float(k) / float(seg)
		var a1 := TAU * float(k + 1) / float(seg)
		for f in filas.size() - 1:
			var r0 := filas[f]
			var r1 := filas[f + 1]
			var v0 := float(f) / float(filas.size() - 1)
			var v1 := float(f + 1) / float(filas.size() - 1)
			var p00 := Vector3(cos(a0) * r0.x, r0.y, sin(a0) * r0.x)
			var p01 := Vector3(cos(a1) * r0.x, r0.y, sin(a1) * r0.x)
			var p10 := Vector3(cos(a0) * r1.x, r1.y, sin(a0) * r1.x)
			var p11 := Vector3(cos(a1) * r1.x, r1.y, sin(a1) * r1.x)
			var u0 := float(k) / float(seg)
			var u1 := float(k + 1) / float(seg)
			var cuadro: Array[Vector3] = [p00, p01, p11, p00, p11, p10]
			var uvs: Array[Vector2] = [Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1),
				Vector2(u0, v0), Vector2(u1, v1), Vector2(u0, v1)]
			for j in 6:
				st.set_normal(Vector3.UP)
				st.set_uv(uvs[j])
				st.add_vertex(cuadro[j])
	return st.commit()

func _montar_ondas() -> void:
	var malla := _malla_onda()
	for i in ONDAS:
		var mat := ShaderMaterial.new()
		mat.shader = SH_POLVO
		mat.set_shader_parameter("forma", FORMA_ONDA)
		mat.set_shader_parameter("tex_manchas", TEX_MANCHAS)
		mat.set_shader_parameter("semilla", float(i) * 0.137)
		var mi := MeshInstance3D.new()
		mi.mesh = malla
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		mi.layers = Nucleo.CAPA_SIN_REFLEJO
		_mundo.add_child(mi)
		_ondas.append({"nodo": mi, "mat": mat, "t": 1.0, "radio": 0.5})

## Un anillo de polvo que se abre a ras de suelo desde un punto hasta `radio`
## unidades y se posa. El color tiñe el polvo y, si tiene color de verdad, le
## pone al frente un resplandor débil.
func onda(punto: Vector2, altura: float, color: Color, radio: float) -> void:
	if _ondas.is_empty():
		return
	var o: Dictionary = _ondas[_onda_siguiente]
	_onda_siguiente = (_onda_siguiente + 1) % _ondas.size()
	var opacidad := clampf(0.6 + radio * 0.5, 0.7, 1.2)
	# En la zona de palas, pequeña y floja: ver `Z_PALAS`. La de asegurar una
	# criatura en la pala medía 0,95 de radio y era un anillo gris de 300 px
	# encima de la pala izquierda.
	if punto.y * Nucleo.E > Z_PALAS:
		radio = minf(radio, ONDA_PALAS_RADIO)
		opacidad *= ONDA_PALAS_OPACIDAD
	o["t"] = 0.0
	o["radio"] = radio
	var mat: ShaderMaterial = o["mat"]
	mat.set_shader_parameter("color_polvo", COLOR_POLVO.lerp(color, 0.3))
	mat.set_shader_parameter("color_brillo", color)
	# Lo que no tiene color no brilla (piedra, hueso); la magia algo más que el
	# fuego, que ya tiene su luz al lado.
	var brillo := smoothstep(0.3, 0.6, color.s) * (0.9 if _clase(color) == Clase.MAGIA else 0.6)
	mat.set_shader_parameter("brillo", brillo)
	mat.set_shader_parameter("opacidad", opacidad)
	var nodo: MeshInstance3D = o["nodo"]
	nodo.position = _mundo.a3(punto, altura)
	nodo.rotation = Vector3(0.0, randf() * TAU, 0.0)
	nodo.scale = Vector3(0.01, 0.01, 0.01)
	nodo.visible = true

# ----------------------------------------------------------------------- tañido

func _montar_tanidos() -> void:
	var malla := _malla_onda(0.93, 96)
	for i in TANIDOS:
		var mat := ShaderMaterial.new()
		mat.shader = SH_POLVO
		mat.set_shader_parameter("forma", FORMA_ONDA)
		mat.set_shader_parameter("tex_manchas", TEX_MANCHAS)
		mat.set_shader_parameter("semilla", 0.5 + float(i) * 0.29)
		mat.set_shader_parameter("color_polvo", COLOR_POLVO.lerp(Paleta.ORO, 0.6))
		mat.set_shader_parameter("color_brillo", Paleta.ORO)
		mat.set_shader_parameter("brillo", 1.4)
		mat.set_shader_parameter("opacidad", 1.1)
		mat.set_shader_parameter("fundido", 0.9)
		mat.set_shader_parameter("recorte", Vector4(MESA_X.x, MESA_Z.x, MESA_X.y, MESA_Z.y))
		var mi := MeshInstance3D.new()
		mi.mesh = malla
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		mi.layers = Nucleo.CAPA_SIN_REFLEJO
		_mundo.add_child(mi)
		_tanidos.append({"nodo": mi, "mat": mat, "t": 1.0, "fuegos": []})

## EL TAÑIDO DE LA CAMPANA MAYOR (decisión 9): un aro fino de polvo dorado que
## nace en la vertical de la campana (`punto`, en px de mesa) y cruza el campo a
## ras de suelo en segundo y medio; cada fuego del campo se aviva cuando
## el aro le pasa por debajo. Lo dispara este módulo solo, con
## `descarga_empezada`; si otro lo pide además en el mismo instante, el segundo
## se ignora (`TANIDO_JUNTOS`), así que llamarlo de más no lo duplica.
func tanido(punto: Vector2 = CAMPANA_PX) -> void:
	if _tanidos.is_empty() or _mundo.tiempo - _ultimo_tanido < TANIDO_JUNTOS:
		return
	_ultimo_tanido = _mundo.tiempo
	var o: Dictionary = _tanidos[_tanido_siguiente]
	_tanido_siguiente = (_tanido_siguiente + 1) % _tanidos.size()
	var centro := _mundo.a3(punto, 0.015)
	# Los fuegos del campo y lo que distan del centro: se avivan cuando el aro
	# llega a ellos, no todos de golpe. Así se VE que la onda va de la campana a
	# las palas.
	var pendientes: Array = []
	if _mundo.has_method("fuegos"):
		for f: Dictionary in _mundo.fuegos():
			var luz := f.get("luz") as OmniLight3D
			if luz == null or not is_instance_valid(luz):
				continue
			var p := luz.global_position if luz.is_inside_tree() else luz.position
			if CAMPO.has_point(Vector2(p.x, p.z)):
				pendientes.append([Vector2(p.x - centro.x, p.z - centro.z).length(), luz])
	o["fuegos"] = pendientes
	o["t"] = 0.0
	var nodo: MeshInstance3D = o["nodo"]
	nodo.position = centro
	nodo.rotation = Vector3(0.0, randf() * TAU, 0.0)
	nodo.scale = Vector3(0.01, 0.01, 0.01)
	nodo.visible = true

func _mover_tanidos(delta: float) -> void:
	for o in _tanidos:
		var t: float = o["t"]
		if t >= 1.0:
			continue
		t = minf(t + delta / TANIDO_DURA, 1.0)
		o["t"] = t
		# Casi a velocidad constante: una onda que frena se lee como un charco
		# que se extiende, no como un golpe que viaja.
		var r := TANIDO_RADIO * (0.03 + 0.97 * pow(t, 0.85))
		var nodo: MeshInstance3D = o["nodo"]
		nodo.scale = Vector3(r, 0.045 * (1.0 - t) + 0.006, r)
		nodo.visible = t < 1.0
		(o["mat"] as ShaderMaterial).set_shader_parameter("t", t)
		var pendientes: Array = o["fuegos"]
		for k in range(pendientes.size() - 1, -1, -1):
			if float(pendientes[k][0]) <= r:
				var luz: OmniLight3D = pendientes[k][1]
				if is_instance_valid(luz):
					_mundo.avivar(luz, 0.9)
				pendientes.remove_at(k)

# ------------------------------------------------------------------------ almas

func _montar_almas() -> void:
	_malla_almas = ImmediateMesh.new()
	_mat_almas = ShaderMaterial.new()
	_mat_almas.shader = SH_JIRON
	_mat_almas.set_shader_parameter("tex_manchas", TEX_MANCHAS)
	var mi := MeshInstance3D.new()
	mi.mesh = _malla_almas
	mi.material_override = _mat_almas
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.layers = Nucleo.CAPA_SIN_REFLEJO
	_mundo.add_child(mi)
	for i in ALMAS:
		_almas.append({"t": 1.0, "espera": 0.0, "desde": Vector3.ZERO, "bola": null,
			"fase": 0.0, "color": Color.WHITE, "cola": [] as Array[Vector3],
			"semilla": float(i) * 0.37})

## Jirones de luz que salen de `desde` y se meten en la bola, uno detrás de
## otro y en espiral. Es lo que cuenta, sin una palabra, que la criatura va DENTRO.
func soltar_almas(desde: Vector3, bola: Bola, color: Color, cuantas: int) -> void:
	var puestas := 0
	for a in _almas:
		if puestas >= cuantas:
			return
		if float(a["t"]) < 1.0:
			continue
		a["t"] = 0.0
		a["espera"] = 0.05 * float(puestas)
		a["desde"] = desde
		a["bola"] = bola
		a["fase"] = float(puestas) * TAU / float(maxi(cuantas, 1)) + randf() * 0.6
		a["color"] = color
		(a["cola"] as Array[Vector3]).clear()
		puestas += 1

# -------------------------------------------------------------- lo que pasa en la mesa

## Una señal de pieza en este punto: durante un instante, un rebote aquí no es
## una pared.
func _marcar(punto: Vector2) -> void:
	_sucesos.append({"punto": punto, "t": _mundo.tiempo})

func _brasero_mas_cercano(punto: Vector2) -> Vector2:
	var mejor := punto
	var dist := INF
	for centro in _mesa.bumpers:
		var d := centro.distance_squared_to(punto)
		if d < dist:
			dist = d
			mejor = centro
	return mejor

func _al_golpear_brasero(punto: Vector2, fuerza: float) -> void:
	_marcar(punto)
	var centro := _brasero_mas_cercano(punto)
	chispear(punto, 0.10, Paleta.NARANJA, 12)
	_avivar_pavesas(_mundo.a3(centro, 0.16), int(clampf(fuerza / 90.0, 5.0, 10.0)))
	onda(centro, 0.02, Paleta.NARANJA, 0.7)
	_mundo.latir(1.0)
	_mundo.sacudida = maxf(_mundo.sacudida, clampf(fuerza / 900.0, 0.35, 1.0))

func _al_golpear_goma(punto: Vector2, _fuerza: float) -> void:
	_marcar(punto)
	_bocanada(_mundo.a3(punto, 0.06), Paleta.PIEDRA_4, 3)
	chispear(punto, 0.08, Paleta.ORO, 4)
	_mundo.sacudida = maxf(_mundo.sacudida, 0.4)

func _al_golpear_poste(punto: Vector2, _fuerza: float) -> void:
	_marcar(punto)
	_bocanada(_mundo.a3(punto, 0.07), Paleta.PIEDRA_4, 2)

## La pala es hierro y la bola acero: si pega fuerte, salta una chispa.
func _al_golpear_pala(punto: Vector2, fuerza: float) -> void:
	_marcar(punto)
	if fuerza > 650.0:
		chispear(punto, 0.06, Paleta.NARANJA, int(clampf(fuerza / 200.0, 3.0, 8.0)))

func _al_abatir(punto: Vector2, banco: int) -> void:
	_marcar(punto)
	if banco == MesaCripta.BANCO_ESCUDOS:
		# Madera de roble con herrajes: astillas y unas chispas.
		chispear(punto, 0.10, Paleta.TIERRA_3, 8)
		chispear(punto, 0.10, Paleta.NARANJA, 5)
		onda(punto, 0.02, Paleta.TIERRA_4, 0.3)
		return
	chispear(punto, 0.10, Paleta.PIEDRA_4, 12)
	onda(punto, 0.02, Paleta.PIEDRA_4, 0.42)

func _al_caer(punto: Vector2, _desde: int, hasta: int) -> void:
	_marcar(punto)
	var altura := _mundo.altura_capa(hasta)
	_bocanada(_mundo.a3(punto, altura + 0.04), Paleta.PIEDRA_4, 4)
	onda(punto, altura + 0.01, Paleta.PIEDRA_3, 0.3)

func _al_entrar_rampa(punto: Vector2, indice: int) -> void:
	_marcar(punto)
	if _mesa.rampas[indice].subterranea:
		onda(punto, 0.02, Paleta.ARCANO, 0.5)
		return
	# La bola entra en un raíl de hierro: un chasquido de chispas en la boca.
	chispear(punto, _mundo.altura_en(punto) + 0.05, Paleta.NARANJA, 5)

func _al_salir_rampa(punto: Vector2, indice: int) -> void:
	_marcar(punto)
	if _mesa.rampas[indice].subterranea:
		onda(punto, 0.02, Paleta.ARCANO, 0.5)
		chispear(punto, 0.10, Paleta.ARCANO, 10)

func _al_tragar(punto: Vector2, _indice: int) -> void:
	_marcar(punto)
	_bocanada(_mundo.a3(punto, _mundo.altura_en(punto) + 0.05), Paleta.PIEDRA_4, 4)
	_mundo.latir(1.0)
	_mundo.sacudida = maxf(_mundo.sacudida, 0.6)

## El sarcófago escupe: el polvo, las chispas y la onda los pone «piezas», que
## sabe dónde está la boca. Aquí solo lo acusa la mesa.
func _al_escupir(punto: Vector2, _indice: int) -> void:
	_marcar(punto)
	_mundo.latir(0.6)

## La campana mayor toca: la mesa entera lo acusa. Del recorrido que la ha hecho
## tocar sale una onda de polvo con el oro del bronce, y de la vertical de la
## campana, el TAÑIDO, que cruza el campo hasta las palas.
func _al_tocar_campana(punto: Vector2, _segundos: float) -> void:
	_marcar(punto)
	var altura := _mundo.altura_en(punto)
	onda(punto, altura + 0.02, Paleta.ORO, 1.1)
	chispear(punto, altura + 0.12, Paleta.ORO_CLARO, 16)
	_bocanada(_mundo.a3(punto, altura + 0.06), Paleta.PIEDRA_4, 6)
	tanido(CAMPANA_PX)
	_mundo.latir(1.0)
	_mundo.sacudida = maxf(_mundo.sacudida, 0.7)

## Las criaturas no son paredes: se oye a la caza solo para saber dónde no.
## Se engancha en el primer cuadro, porque la caza se monta después que el mundo.
func _oir_caza() -> void:
	_caza_oida = true
	if _mundo.caza == null:
		return
	# Con métodos y no con lambdas: una lambda guarda a este módulo por
	# referencia, la caza guarda la lambda y este módulo guarda la mesa, que
	# guarda la caza. Es un círculo y nada se libera al cerrar (se ve en la
	# salida: «RID allocations … leaked at exit»).
	var c: Object = _mundo.caza
	if c.has_signal("criatura_golpeada"):
		c.connect("criatura_golpeada", _al_golpear_criatura)
	if c.has_signal("criatura_blindada"):
		c.connect("criatura_blindada", _al_blindar_criatura)

func _al_golpear_criatura(_c: Object, punto: Vector2, _fuerza: float, _normal: Vector2) -> void:
	_marcar(punto)

func _al_blindar_criatura(_c: Object, punto: Vector2, _fuerza: float) -> void:
	_marcar(punto)

# ------------------------------------------------------------------- las paredes

func _buscar_paredes() -> void:
	var ahora := _mundo.tiempo
	while not _sucesos.is_empty() and ahora - float(_sucesos[0]["t"]) > PARED_RECUERDO:
		_sucesos.pop_front()
	var vivas := {}
	for b in _mesa.bolas:
		if not b.viva:
			continue
		vivas[b] = true
		var ficha: Dictionary = _vel_antes.get(b, {"vel": b.vel, "espera": 0.0})
		var antes: Vector2 = ficha["vel"]
		var espera: float = maxf(float(ficha["espera"]) - _mundo.get_process_delta_time(), 0.0)
		var cambio := b.vel - antes
		var libre := b.rampa < 0 and b.platillo < 0 and _mundo.posicion_bola(b).y > -0.03
		if libre and espera <= 0.0 and cambio.length() > PARED_DV and cambio.dot(antes) < 0.0 \
				and not _cerca_de_suceso(b.pos) and not _cerca_de_otra_bola(b):
			var normal := cambio.normalized()
			var contacto := b.pos - normal * _mesa.p.radio_bola
			var fuerza := clampf((cambio.length() - PARED_DV) / 500.0, 0.0, 1.0)
			var altura := _mundo.posicion_bola(b).y
			_bocanada(_mundo.a3(contacto, altura), Paleta.PIEDRA_4, 2 + int(fuerza * 3.0))
			if fuerza > 0.35:
				chispear(contacto, altura, Paleta.PIEDRA_3, 3 + int(fuerza * 5.0))
			espera = 0.08
		_vel_antes[b] = {"vel": b.vel, "espera": espera}
	for b in _vel_antes.keys():
		if not vivas.has(b):
			_vel_antes.erase(b)

func _cerca_de_suceso(punto: Vector2) -> bool:
	for s in _sucesos:
		if (s["punto"] as Vector2).distance_to(punto) < PARED_LEJOS:
			return true
	return false

func _cerca_de_otra_bola(b: Bola) -> bool:
	for otra in _mesa.bolas:
		if otra != b and otra.viva and otra.pos.distance_to(b.pos) < _mesa.p.radio_bola * 3.0:
			return true
	return false

# ------------------------------------------------------------------ cada cuadro

func actualizar(delta: float) -> void:
	if not _caza_oida:
		_oir_caza()
	_buscar_paredes()

	for o in _ondas:
		var t: float = o["t"]
		if t >= 1.0:
			continue
		t = minf(t + delta * 1.7, 1.0)
		o["t"] = t
		var nodo: MeshInstance3D = o["nodo"]
		var r: float = float(o["radio"]) * (0.12 + 0.88 * (1.0 - pow(1.0 - t, 3.0)))
		# El lomo de polvo: sube deprisa y se va posando mientras se abre.
		var alto := maxf(r * 0.14 * (1.0 - t * 0.7), 0.004)
		nodo.scale = Vector3(r, alto, r)
		(o["mat"] as ShaderMaterial).set_shader_parameter("t", t)
		nodo.visible = t < 1.0

	_mover_tanidos(delta)
	_mover_almas(delta)

## LA CALIDAD (la llama el núcleo al arrancar y cada vez que cambia): 0 ALTA,
## 1 MEDIA, 2 BAJA. En MEDIA, la mitad de pavesas; en BAJA, ni pavesas, ni
## bocanadas de polvo, ni esquirlas (cuadros semitransparentes y mallas que
## vuelan: lo que pesa en un portátil). Las chispas, las ondas, el tañido y las
## almas se quedan en las tres: son lo que cuenta lo que ha pasado.
func calidad(n: int) -> void:
	_calidad = clampi(n, 0, 2)
	if _calidad >= 2:
		for e in _pavesas + _polvos + _esquirlas:
			e.emitting = false

func _mover_almas(delta: float) -> void:
	_malla_almas.clear_surfaces()
	var cam: Camera3D = null
	if _mundo.is_inside_tree():
		cam = _mundo.get_viewport().get_camera_3d()
	for a in _almas:
		var t: float = a["t"]
		var cola: Array[Vector3] = a["cola"]
		if t >= 1.0:
			if not cola.is_empty():
				# Llegó: la cola se recoge dentro de la bola en unos cuadros.
				cola.pop_back()
				if cola.size() > 1:
					cola.pop_back()
				_dibujar_alma(a, cola, cam, 1.0)
			continue
		var espera: float = a["espera"]
		if espera > 0.0:
			a["espera"] = espera - delta
			continue
		t = minf(t + delta / ALMA_VIAJE, 1.0)
		a["t"] = t
		var desde: Vector3 = a["desde"]
		var hasta := desde
		var bola: Bola = a["bola"]
		if bola != null and bola.viva:
			hasta = _mundo.posicion_bola(bola)
		# Una espiral que se cierra sobre la bola: sale algo abierta y alta de la
		# criatura y entra recta por la ranura.
		var giro: float = float(a["fase"]) + t * 7.0
		var radio := ALMA_ESPIRAL * (1.0 - t) * (1.0 - t)
		var suave := t * t * (3.0 - 2.0 * t)
		var pos := desde.lerp(hasta, suave) + Vector3(cos(giro) * radio,
			0.10 * sin(PI * t), sin(giro) * radio)
		cola.push_front(pos)
		if cola.size() > COLA_ALMA:
			cola.resize(COLA_ALMA)
		_dibujar_alma(a, cola, cam, t)

## Un jirón: la tira de su cola, de cara a la cámara, gruesa en la cabeza.
func _dibujar_alma(a: Dictionary, cola: Array[Vector3], cam: Camera3D, t: float) -> void:
	var n := cola.size()
	if n < 2 or cam == null:
		return
	var ojo := cam.global_position
	var col: Color = a["color"]
	# Más fuerte en medio del viaje; al entrar en la bola se apaga dentro.
	var fuerza := smoothstep(0.0, 0.15, t) * (1.0 - smoothstep(0.85, 1.0, t) * 0.6)
	if t >= 1.0:
		fuerza = 0.35
	var c := Color(col.r * fuerza, col.g * fuerza, col.b * fuerza, float(a["semilla"]))
	_malla_almas.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _mat_almas)
	for j in n:
		var p0 := cola[j]
		var p1 := cola[mini(j + 1, n - 1)]
		var pm := cola[maxi(j - 1, 0)]
		var lateral := (pm - p1).cross(ojo - p0)
		if lateral.length_squared() < 1.0e-10:
			lateral = Vector3.RIGHT
		var v := float(j) / float(n - 1)
		lateral = lateral.normalized() * ALMA_ANCHO * (1.0 - 0.6 * v)
		_malla_almas.surface_set_color(c)
		_malla_almas.surface_set_uv(Vector2(0.0, v))
		_malla_almas.surface_add_vertex(p0 - lateral)
		_malla_almas.surface_set_color(c)
		_malla_almas.surface_set_uv(Vector2(1.0, v))
		_malla_almas.surface_add_vertex(p0 + lateral)
	_malla_almas.surface_end()
