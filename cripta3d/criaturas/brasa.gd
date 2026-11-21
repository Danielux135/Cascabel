extends Node3D

## CRIPTA 3D — BRASA, la llama. El cuerpo de la especie «saltarin» de la caza y,
## con este mismo guion en pequeño, el de sus dos mitades: las ASCUAS («gotita»).
## Solo LEE una `criatura.gd` y la pone en pantalla; no decide nada. Mismo
## contrato que `prueba3d/criatura_3d.gd`.
##
## QUÉ ES. La llama del sprite `cr_brasa`: una hoguera ancha y baja, con una
## corona de lenguas cortas y la cara amarilla abajo, con dos ojos grandes. Aquí
## tiene cuerpo:
##
##   · un CARBÓN debajo —el tizón del que nace—, que es lo único que recibe luz y
##     lo que le da peso. Es lo que BOTA; la llama va encima y llega tarde;
##   · una LLAMA de dos capas con volumen, una dentro de otra: la melena, que es
##     la corona, y el núcleo claro, que es la cara y se ve por una ventana que se
##     abre en la melena. Las dos son LUZ y no pintura (`brasa_fuego.gdshaderinc`):
##     un degradado por altura, del blanco amarillento de la base al rojo de las
##     puntas, con un ruido que sube; la melena es translúcida en el canto y en
##     las puntas, y suma luz a lo de detrás;
##   · dos OJOS sobre el núcleo, en una careta echada hacia atrás porque la cámara
##     mira la mesa desde lo alto. Miran a la bola, parpadean y dicen cómo está;
##   · PAVESAS a los lados (luz que se suma, no confeti), humo cuando se apaga y
##     una luz cálida que tiembla y deja una mancha en la losa;
##   · en la losa, un TIZNE y un cerco de rescoldos: su sombra y su indicador.
##
## El modelo sale de `cripta3d/blender/criatura_brasa.py`. Todas las medidas que
## hacen falta aquí —por dónde sale la llama del cráter, dónde caen los ojos, lo
## ancha que es la ventana de la cara— se LEEN del GLB: si se cambia el modelo,
## este guion no hay que tocarlo.
##
## CÓMO SE MUEVE. Sin huesos ni animaciones grabadas; lo que la hace viva se
## calcula cada cuadro:
##   1. BOTA. El carbón sigue el arco del salto al milímetro; la llama es un
##      muelle encima: se estira al despegar, se aplasta al caer.
##   2. SE QUEDA ATRÁS, PERO SOLO POR ARRIBA. Las puntas se tumban contra la
##      velocidad (otro muelle) con un peso que es la altura al cuadrado: la base
##      y la cara no se mueven. Antes se ladeaba la llama entera como un sólido y,
##      al correr, se veían las láminas cruzarse y los ojos de canto. Eso es lo
##      que dice hacia dónde va, porque…
##   3. …LA CARA MIRA A LA CÁMARA. Una llama no tiene espalda: la careta se vuelve,
##      con amortiguación, hacia la cámara que la esté mirando, y las pupilas
##      siguen a la bola. Los ojos no se ven nunca de canto.
##   4. LO QUE LE PASA SE VE DE LEJOS: se encoge y se aviva antes de huir; el
##      golpe la pone al blanco y sale rodando con la llama a rastras; aturdida
##      se achica a un rescoldo granate que humea, con los ojos entornados; y al
##      cazarla se encoge de golpe dentro de la bola, con un fogonazo.
##
## LO QUE PESA. En la mesa hay a la vez la entera o sus dos ascuas, más las otras
## dos criaturas; y la caza crea los TRES cuerpos de BRASA desde el principio, así
## que lo que esté escondido no puede costar nada (`_ocultar`). Cada cuerpo lleva:
##   · 6 mallas: carbón, melena, núcleo, dos ojos y el cerco de la losa. La
##     entera son unos 5.800 triángulos y cada ascua unos 2.700 (el GLB entero,
##     8.500). La melena es la única transparente, con su pasada de profundidad;
##   · 3 surtidores, todos con su vida contada: pavesas (15, en la ascua 9),
##     chispas (un puñado de golpe) y humo (9, solo aturdida);
##   · 1 luz omni sin sombra, que se esconde con el cuerpo. Nunca hay más de dos
##     de BRASA a la vez (la entera no coincide con sus ascuas);
##   · la ascua, además, un HILO de chispas hasta su pareja (un cilindro de 12
##     triángulos, solo en la de índice menor) y chispas sueltas cada ~0,3 s.
##
## LAS ASCUAS se leen como MITADES, no como otras brasas: van a ESCALA_ASCUA del
## modelo de ascua (~0,58 de la entera), más rojas (TEMPLADO_ASCUA), crepitando,
## y unidas por el hilo, que se tensa cuando se van a juntar.
##
## EN LA MESA SE JUZGA, NO EN EL VISOR: la mesa usa AgX con exposición 1,5 y
## brillo, y lo que en el visor era un núcleo claro allí se quemaba a un bulbo
## crema. El fuego no pasa de oro claro y apenas de 1 (`brasa_color`), y los ojos
## son ranuras doradas en cuencas oscuras. Bajo un raíl se agacha y ante la
## calavera se hace a un lado (la cuenta, en `calavera.gd`).
##
## Para mirarla: el visor (`cripta3d/visor.tscn`, estado por estado) y el banco
## (`brasa_banco.tscn`: la entera partiéndose, juntándose y recogida).

const Criatura := preload("res://prueba3d/criatura.gd")
const MODELO := preload("res://cripta3d/modelos/criatura_brasa.glb")
## CUATRO SOMBREADORES PARA OCHO COSAS (web, 21-nov-2026). En el navegador cada
## sombreador se compila con ANGLE y Direct3D, y uno vacío ya cuesta 0,3 s: las
## piezas que pintan igual van juntas, con un `es_…` que dice cuál es cada una.
##   brasa_llama   la melena y el núcleo            (es_nucleo)
##   brasa_carbon  el carbón y los dos ojos         (es_ojo)
##   brasa_pavesa  las pavesas, las chispas y el hilo  (es_hilo)
##   brasa_cerco   el cerco de la losa y el humo    (es_humo)
## Eran ocho y 12,8 s de compilar; las cuentas, en cada sombreador.
const SH_LLAMA := preload("res://cripta3d/criaturas/brasa_llama.gdshader")
const SH_CARBON := preload("res://cripta3d/criaturas/brasa_carbon.gdshader")
const SH_PAVESA := preload("res://cripta3d/criaturas/brasa_pavesa.gdshader")
const SH_CERCO := preload("res://cripta3d/criaturas/brasa_cerco.gdshader")
## El ruido de los sombreadores, horneado (`brasa_ruido.gd`): en el navegador un
## ruido por código se compila desplegado en cada variante.
const RUIDO := preload("res://cripta3d/criaturas/brasa_ruido.png")
## No atravesarse a la vista (agacharse bajo un raíl, hacerse a un lado): la
## cuenta es la de la calavera, para que los tres cuerpos midan igual.
const Calavera := preload("res://cripta3d/criaturas/calavera.gd")
const E := 0.01

## LO PEQUEÑA QUE ES UNA ASCUA, además de lo que ya la achica el modelo (0,72).
## Con el modelo solo, en la mesa cada ascua se leía como OTRA brasa entera y no
## como la mitad de una (crítica de juego, nov-2026): con esto queda en ~0,58 de
## la entera, más roja (`TEMPLADO_ASCUA`) y chisporroteando.
const ESCALA_ASCUA := 0.80
const TEMPLADO_ASCUA := 0.24
## Cada cuánto escupe chispas sueltas un ascua (s): está rota y crepita.
const CHISPORROTEO := 0.32

## Lo rápido que la cara se vuelve hacia la cámara (1/s). Una llama no tiene
## espalda: su cara está donde ella quiere. Hubo un giro hacia el rumbo (hasta
## 30°) y al correr los ojos quedaban de perfil, como dos pastillas. Hacia dónde
## VA ya lo dicen las puntas, que se quedan atrás.
const VUELTA_CARA := 9.0
## Lo que tarda en meterse en el cascabel: se encoge de golpe, con un fogonazo.
const T_COLARSE := 0.20
## Lo más que se acerca a la bola mientras se encoge. Antes la llama se estiraba
## hasta la bola en un hilo, y si la bola ya iba lejos salía un tubo naranja
## gigante cruzando el encuadre.
const ALCANCE_COLARSE := 0.12

var c: Criatura
## A qué altura está el suelo que pisa.
var y_base := 0.0
## Del contrato. BRASA no los usa: ni se acorrala ni se vuelca ni lleva coraza.
var t_cierre := 5.0
var t_volcada := 5.0
var arco_blindaje := 70.0
## Hacia dónde está el jugador, en planta de mesa (+y de mesa es +z en 3D). Si la
## cámara de juego mirase desde otro lado, se le dice aquí ANTES de `montar`: de
## aquí salen hacia dónde se vuelve la cara y por dónde no nacen las pavesas.
var hacia_camara := Vector2(0.0, 1.0)

var _ascua := false
var _talla := 1.0
## La escala que se le aplica al cuerpo entero por código (ESCALA_ASCUA o 1).
var _k := 1.0
## El hilo hasta la otra ascua (solo lo lleva la de índice menor de las dos).
var _hilo: MeshInstance3D = null
var _mat_hilo: ShaderMaterial = null
var _pareja: Node3D = null
var _crepita := 0.0
var _pivote := 0.05          # el fondo del cráter: de ahí nace la llama
var _alto := 0.36            # hasta dónde llega la punta, en reposo
var _alzada := 0.13          # lo que sube en cada bote
var _centro_carbon := 0.03
var _radio_rueda := 0.07
var _color := Color(1.0, 0.56, 0.22)

var _raiz: Node3D            # la llama entera: va donde va el carbón y se vuelve con la cara
var _forma: Node3D           # dentro: se aplasta, se estira, se ladea y se apaga
var _pivote_carbon: Node3D   # el carbón rueda sobre su centro
var _carbon: MeshInstance3D
var _llama: MeshInstance3D
var _nucleo: MeshInstance3D
var _ojos: Array[Node3D] = []
var _reposo_ojos: Array[Transform3D] = []
var _mats_ojo: Array[ShaderMaterial] = []
var _mats_fuego: Array[ShaderMaterial] = []
var _mat_carbon: ShaderMaterial
var _mat_llama: ShaderMaterial
var _mat_cerco: ShaderMaterial
var _cerco: MeshInstance3D
var _luz: OmniLight3D
var _pavesas: CPUParticles3D
var _chispas: CPUParticles3D
var _humo: CPUParticles3D

var _reloj := 0.0
var _t_fuego := 0.0
var _estado_antes := -1
var _yaw := 0.0
var _yaw_carbon := 0.0
var _vuelco := Quaternion.IDENTITY
var _vida := 0.0             # 1 ardiendo, 0 apagada
var _prende := 1.0           # al nacer, lo que ha crecido la llama entera (con la cara)
var _avivar := 0.0
var _calor := 1.0            # el ascua del carbón
var _s := 1.0                # el muelle del cuerpo: 1 en reposo, menos aplastada
var _s_vel := 0.0
var _arr := Vector3.ZERO     # el muelle de las lenguas: cuánto se quedan atrás
var _arr_vel := Vector3.ZERO
var _arr_malla := Vector3.ZERO
var _en_aire := false
var _destello := 0.0
var _parada := 0.0
var _aviso := 0.0
var _aro_aviso := 0.0
var _parpadeo := 0.0
var _prox_parpadeo := 2.0
var _abre := 1.0
var _pupila := 1.0
var _ceja := 0.0
var _mirada := Vector2.ZERO
var _desde := Vector3.ZERO
var _colarse_chispas := false
## No atravesarse (ver `Calavera.UMBRAL_APARTE`): la brasa se agacha bajo un raíl
## y se hace a un lado ante la calavera, que es la que pesa.
var _tramos: Array[Dictionary] = []
var _tramos_listos := false
var _agache := 1.0
var _aparte := Vector3.ZERO

# ------------------------------------------------------------------- montaje

func montar(criatura: Criatura, _fuente: Font) -> void:
	c = criatura
	_ascua = c.especie == "gotita"
	var sufijo := "_ascua" if _ascua else ""
	_talla = 0.72 if _ascua else 1.0
	_k = ESCALA_ASCUA if _ascua else 1.0
	_alzada = 0.105 if _ascua else 0.135
	if _ascua:
		_color = Color(1.0, 0.34, 0.15)
	var semilla := 1.7 + float(c.indice) * 2.39

	var modelo := MODELO.instantiate() as Node3D
	var malla_llama := _malla_de(modelo, "llama" + sufijo)
	var malla_nucleo := _malla_de(modelo, "nucleo" + sufijo)
	var malla_carbon := _malla_de(modelo, "carbon" + sufijo)
	var malla_pavesa := _malla_de(modelo, "pavesa")
	var nombres: Array[String] = ["ojo_izq", "ojo_der"]
	if _ascua:
		nombres = ["ojo_ascua_izq", "ojo_ascua_der"]

	# Las medidas, del propio modelo.
	var caja_llama := malla_llama.get_aabb()
	var caja_carbon := malla_carbon.get_aabb()
	_pivote = caja_llama.position.y + 0.006
	_alto = caja_llama.end.y
	_centro_carbon = caja_carbon.position.y + caja_carbon.size.y * 0.5
	_radio_rueda = maxf(caja_carbon.size.x, caja_carbon.size.z) * 0.36

	_raiz = Node3D.new()
	add_child(_raiz)
	_forma = Node3D.new()
	_raiz.add_child(_forma)
	_pivote_carbon = Node3D.new()
	add_child(_pivote_carbon)
	_yaw_carbon = fposmod(semilla * 2.3, TAU)

	# --- El carbón
	_mat_carbon = ShaderMaterial.new()
	_mat_carbon.shader = SH_CARBON
	_mat_carbon.set_shader_parameter("ruido_brasa", RUIDO)
	_mat_carbon.set_shader_parameter("semilla", semilla)
	_mat_carbon.set_shader_parameter("c_negro", Paleta.NEGRO)
	_mat_carbon.set_shader_parameter("c_carbon", Paleta.GRIS_1)
	_mat_carbon.set_shader_parameter("c_ceniza", Paleta.GRIS_4)
	_mat_carbon.set_shader_parameter("c_ceniza_calida", Paleta.PIEDRA_4)
	_mat_carbon.set_shader_parameter("c_rojo", Paleta.ROJO)
	_mat_carbon.set_shader_parameter("c_rojo_luz", Paleta.ROJO_LUZ)
	_mat_carbon.set_shader_parameter("c_naranja", Paleta.NARANJA)
	_mat_carbon.set_shader_parameter("c_oro_claro", Paleta.ORO_CLARO)
	_carbon = _pieza(malla_carbon, _mat_carbon, _pivote_carbon, true)
	_carbon.position = Vector3(0.0, -_centro_carbon, 0.0)

	# --- La llama: melena y núcleo, los dos colgando del fondo del cráter.
	# Hubo una tercera capa, un BORDE de jirones rojo oscuro, y luego la melena
	# misma llevó un canto rojo opaco: las dos cosas hacían la llama papel quemado
	# o capucha. El rojo lo da ahora el degradado por altura, no una capa.
	var baja := Vector3(0.0, -_pivote, 0.0)
	var templado := TEMPLADO_ASCUA if _ascua else 0.0
	var mat_llama := _fuego(SH_LLAMA, semilla, templado)
	_mat_llama = mat_llama
	_llama = _pieza(malla_llama, mat_llama, _forma, false)
	_llama.position = baja
	var mat_nucleo := _fuego(SH_LLAMA, semilla, templado)
	mat_nucleo.set_shader_parameter("es_nucleo", 1.0)
	mat_nucleo.set_shader_parameter("cuanto", 0.55)
	mat_nucleo.set_shader_parameter("hervor_base", 0.02)
	# El núcleo es opaco, pero va con el sombreador de la melena, que es
	# transparente (con alfa 1 tapa igual): un puesto antes, para que la melena
	# se pinte siempre encima de él y no al revés.
	mat_nucleo.render_priority = -1
	_nucleo = _pieza(malla_nucleo, mat_nucleo, _forma, false)
	_nucleo.position = baja

	# --- Los ojos, donde los dejó el modelo.
	var medio := Vector2.ZERO
	var centro_ojos := Vector3.ZERO
	var sube := 1.0
	for i in nombres.size():
		var nodo := modelo.find_child(nombres[i], true, false) as MeshInstance3D
		if nodo == null:
			continue
		var mat := ShaderMaterial.new()
		mat.shader = SH_CARBON
		mat.set_shader_parameter("es_ojo", 1.0)
		mat.set_shader_parameter("lado", -1.0 if i == 0 else 1.0)
		mat.set_shader_parameter("c_cuenca", Paleta.ROJO)
		mat.set_shader_parameter("c_reborde", Paleta.COBRE_1)
		mat.set_shader_parameter("c_fondo", Paleta.TIERRA_1)
		mat.set_shader_parameter("c_parpado", Paleta.ORO)
		mat.set_shader_parameter("c_pupila", Paleta.ORO_CLARO)
		var ojo := _pieza(nodo.mesh, mat, _forma, false)
		var reposo := Transform3D(nodo.transform.basis, nodo.transform.origin + baja)
		ojo.transform = reposo
		_ojos.append(ojo)
		_reposo_ojos.append(reposo)
		_mats_ojo.append(mat)
		var caja := nodo.mesh.get_aabb()
		medio = Vector2(caja.size.x, caja.size.y) * 0.5
		centro_ojos += nodo.transform.origin * 0.5
		sube = nodo.transform.basis.y.y

	# La ventana de la cara, el punto más caliente y lo que no se encoge al
	# apagarse salen de dónde están los ojos.
	if not _ojos.is_empty():
		var ox := absf(_reposo_ojos[0].origin.x)
		var alto_ojo := medio.y * sube
		var aire := 0.024 * _talla
		# La ventana es una cara redonda, no una cerradura: se cierra enseguida por
		# encima de los ojos (0,30 de lo que queda hasta la punta). La misma cuenta
		# está en `ventana_de` del guion de Blender.
		mat_llama.set_shader_parameter("cara", Vector4(ox + medio.x + aire * 0.9,
			centro_ojos.y - alto_ojo - aire, centro_ojos.y + alto_ojo + aire * 0.2,
			centro_ojos.y + alto_ojo + (_alto - centro_ojos.y) * 0.30))
		mat_nucleo.set_shader_parameter("foco", Vector3(0.0, centro_ojos.y - alto_ojo * 0.55,
			centro_ojos.z + 0.012))
		mat_nucleo.set_shader_parameter("foco_radio", (ox + medio.x) * 0.80)
		for m in _mats_fuego:
			m.set_shader_parameter("encoge_desde", centro_ojos.y + alto_ojo + aire * 0.3)
	modelo.free()

	# --- La luz: una, cálida, sin sombra (es para la web). Es la que deja la mancha
	# caliente en la losa que la delata desde arriba, con un radio de unas tres
	# veces su ancho. OJO con la energía: la luz omni de Godot crece con
	# 1/distancia^atenuación, y aquí la losa está a un palmo: con 1 o 2 el suelo se
	# quemaba en blanco a su alrededor y el carbón parecía de bronce.
	_luz = OmniLight3D.new()
	_luz.light_color = Color(1.0, 0.58, 0.26)
	_luz.omni_range = 1.25 * _talla * _k
	_luz.omni_attenuation = 1.4
	_luz.shadow_enabled = false
	_luz.light_specular = 0.3
	_luz.position = Vector3(0.0, _pivote + (_alto - _pivote) * 0.45, 0.0)
	_raiz.add_child(_luz)

	_montar_cerco(semilla)
	_montar_particulas(malla_pavesa)
	if _ascua:
		_montar_hilo()
	_prox_parpadeo = 2.6 + float(c.indice) * 0.7
	_ocultar()

func _malla_de(modelo: Node, nombre: String) -> Mesh:
	var nodo := modelo.find_child(nombre, true, false) as MeshInstance3D
	if nodo == null:
		push_error("BRASA: al modelo le falta la pieza «%s»" % nombre)
		return BoxMesh.new()
	return nodo.mesh

func _pieza(malla: Mesh, mat: Material, padre: Node3D, sombra: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.material_override = mat
	if not sombra:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# El shader mueve los vértices fuera de la caja de la malla: sin margen, la
	# llama desaparece entera cuando la caja se sale de cuadro y ella no.
	mi.extra_cull_margin = 0.4
	padre.add_child(mi)
	return mi

## Una capa de la llama, con los seis colores del sprite, que son de la paleta.
func _fuego(shader: Shader, semilla: float, templado: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("ruido_brasa", RUIDO)
	m.set_shader_parameter("semilla", semilla)
	m.set_shader_parameter("pie", _pivote)
	m.set_shader_parameter("altura", _alto)
	m.set_shader_parameter("templado", templado)
	m.set_shader_parameter("c_oro_claro", Paleta.ORO_CLARO)
	m.set_shader_parameter("c_oro", Paleta.ORO)
	m.set_shader_parameter("c_naranja", Paleta.NARANJA)
	m.set_shader_parameter("c_rojo_luz", Paleta.ROJO_LUZ)
	m.set_shader_parameter("c_rojo", Paleta.ROJO)
	m.set_shader_parameter("c_cobre", Paleta.COBRE_1)
	_mats_fuego.append(m)
	return m

## Lo pintado en la losa: el tizne y el cerco de rescoldos.
func _montar_cerco(semilla: float) -> void:
	var plano := PlaneMesh.new()
	var lado := c.radio * E * 3.6
	plano.size = Vector2(lado, lado)
	_mat_cerco = ShaderMaterial.new()
	_mat_cerco.shader = SH_CERCO
	_mat_cerco.set_shader_parameter("ruido_brasa", RUIDO)
	_mat_cerco.set_shader_parameter("semilla", semilla)
	_mat_cerco.set_shader_parameter("radio", c.radio * E / (lado * 0.5))
	_mat_cerco.set_shader_parameter("c_hollin", Paleta.NEGRO)
	_mat_cerco.set_shader_parameter("c_rojo", Paleta.ROJO)
	_mat_cerco.set_shader_parameter("c_naranja", Paleta.NARANJA)
	_mat_cerco.set_shader_parameter("c_oro_claro", Paleta.ORO_CLARO)
	_cerco = MeshInstance3D.new()
	_cerco.mesh = plano
	_cerco.material_override = _mat_cerco
	_cerco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Como en ÓRBITA: lo pintado en el suelo no va al reflejo (capa 4).
	_cerco.layers = 4
	add_child(_cerco)

## Tres surtidores, y los tres caducan solos: cada partícula tiene su vida
## contada, así que al esconderse la criatura no queda nada colgando.
func _montar_particulas(malla_pavesa: Mesh) -> void:
	# El color de cada pavesa lo pone su shader según la edad (ver allí por qué):
	# aquí solo se le dicen los tres tonos. Rojas las que flotan, claras las chispas.
	var mat_pavesa := ShaderMaterial.new()
	mat_pavesa.shader = SH_PAVESA
	mat_pavesa.set_shader_parameter("c_nueva", Paleta.NARANJA)
	mat_pavesa.set_shader_parameter("c_media", Paleta.ROJO_LUZ)
	mat_pavesa.set_shader_parameter("c_vieja", Paleta.ROJO)
	mat_pavesa.set_shader_parameter("fuerza", 2.2)
	var mat_chispa := ShaderMaterial.new()
	mat_chispa.shader = SH_PAVESA
	mat_chispa.set_shader_parameter("c_nueva", Paleta.TIERRA_6)
	mat_chispa.set_shader_parameter("c_media", Paleta.ORO_CLARO)
	mat_chispa.set_shader_parameter("c_vieja", Paleta.ROJO_LUZ)
	mat_chispa.set_shader_parameter("fuerza", 3.4)

	# Las PAVESAS: los rombos rojos del sprite, flotando a los lados. Se quedan
	# en el mundo: cuando huye deja un reguero.
	_pavesas = CPUParticles3D.new()
	_pavesas.mesh = malla_pavesa
	_pavesas.material_override = mat_pavesa
	_pavesas.amount = 9 if _ascua else 15
	_pavesas.lifetime = 1.7
	_pavesas.randomness = 0.6
	_pavesas.lifetime_randomness = 0.35
	_pavesas.local_coords = false
	# Nacen a los lados y por detrás, como en el sprite, y nunca delante: una
	# pavesa cruzándole la cara es una pavesa tapándole un ojo.
	var cuna := PackedVector3Array()
	for k in 40:
		var a := deg_to_rad(58.0 + 244.0 * (float(k) + 0.5) / 40.0)
		var r := (0.130 + 0.060 * fposmod(float(k) * 0.618, 1.0)) * _talla * _k
		var h := (0.10 * fposmod(float(k) * 0.377, 1.0) - 0.02) * _talla * _k
		cuna.append(Vector3(sin(a) * r * hacia_camara.y + cos(a) * r * hacia_camara.x, h,
			cos(a) * r * hacia_camara.y - sin(a) * r * hacia_camara.x))
	_pavesas.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINTS
	_pavesas.emission_points = cuna
	_pavesas.direction = Vector3.UP
	_pavesas.spread = 28.0
	_pavesas.gravity = Vector3(0.0, 0.09, 0.0)
	_pavesas.initial_velocity_min = 0.02
	_pavesas.initial_velocity_max = 0.09
	_pavesas.damping_min = 0.2
	_pavesas.damping_max = 0.6
	_pavesas.particle_flag_rotate_y = true
	_pavesas.angle_min = 0.0
	_pavesas.angle_max = 360.0
	_pavesas.angular_velocity_min = -160.0
	_pavesas.angular_velocity_max = 160.0
	# La pavesa del GLB mide lo que una de las grandes: aquí se reparten tamaños.
	_pavesas.scale_amount_min = 0.42 * _talla * _k
	_pavesas.scale_amount_max = 0.82 * _talla * _k
	_pavesas.scale_amount_curve = _curva([Vector2(0.0, 0.0), Vector2(0.14, 1.0), Vector2(0.65, 0.85),
		Vector2(1.0, 0.0)])
	_pavesas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pavesas.emitting = false
	add_child(_pavesas)

	# Las CHISPAS: un puñado de golpe, cuando la golpean, se parte o se aviva.
	_chispas = CPUParticles3D.new()
	_chispas.mesh = malla_pavesa
	_chispas.material_override = mat_chispa
	_chispas.amount = 14
	_chispas.lifetime = 0.55
	_chispas.one_shot = true
	_chispas.explosiveness = 0.92
	_chispas.lifetime_randomness = 0.4
	_chispas.local_coords = false
	_chispas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_chispas.emission_sphere_radius = 0.05 * _talla * _k
	_chispas.direction = Vector3.UP
	_chispas.spread = 70.0
	_chispas.gravity = Vector3(0.0, -2.4, 0.0)
	_chispas.initial_velocity_min = 0.45
	_chispas.initial_velocity_max = 1.15
	_chispas.particle_flag_rotate_y = true
	_chispas.angle_max = 360.0
	_chispas.scale_amount_min = 0.32
	_chispas.scale_amount_max = 0.68
	_chispas.scale_amount_curve = _curva([Vector2(0.0, 1.0), Vector2(0.6, 0.8), Vector2(1.0, 0.0)])
	_chispas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_chispas.emitting = false
	add_child(_chispas)

	# El HUMO: un hilo, solo cuando se queda casi apagada. De la rampa solo se
	# usa la transparencia: el gris lo pone el shader.
	var mat_humo := ShaderMaterial.new()
	mat_humo.shader = SH_CERCO
	mat_humo.set_shader_parameter("es_humo", 1.0)
	mat_humo.set_shader_parameter("ruido_brasa", RUIDO)
	mat_humo.set_shader_parameter("color", Paleta.PIEDRA_3)
	var cuadro := QuadMesh.new()
	cuadro.size = Vector2(1.0, 1.0)
	_humo = CPUParticles3D.new()
	_humo.mesh = cuadro
	_humo.material_override = mat_humo
	_humo.amount = 9
	_humo.lifetime = 1.5
	_humo.lifetime_randomness = 0.3
	_humo.local_coords = false
	_humo.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_humo.emission_sphere_radius = 0.025 * _talla * _k
	_humo.direction = Vector3.UP
	_humo.spread = 14.0
	_humo.gravity = Vector3(0.0, 0.06, 0.0)
	_humo.initial_velocity_min = 0.13
	_humo.initial_velocity_max = 0.22
	_humo.damping_min = 0.1
	_humo.damping_max = 0.25
	_humo.scale_amount_min = 0.11 * _talla * _k
	_humo.scale_amount_max = 0.17 * _talla * _k
	_humo.scale_amount_curve = _curva([Vector2(0.0, 0.25), Vector2(0.5, 0.8), Vector2(1.0, 1.0)])
	_humo.color_ramp = _degradado([0.0, 0.18, 0.6, 1.0], [Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.42), Color(1.0, 1.0, 1.0, 0.24), Color(1.0, 1.0, 1.0, 0.0)])
	_humo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_humo.emitting = false
	add_child(_humo)

## El hilo de chispas hasta la otra ascua (`brasa_pavesa.gdshader`, `es_hilo`). Un cilindro de
## 6 lados a lo largo de su Y, que se estira y se apunta cada cuadro.
func _montar_hilo() -> void:
	var tubo := CylinderMesh.new()
	tubo.top_radius = 0.0045
	tubo.bottom_radius = 0.0045
	tubo.height = 1.0
	tubo.radial_segments = 6
	tubo.rings = 1
	tubo.cap_top = false
	tubo.cap_bottom = false
	_mat_hilo = ShaderMaterial.new()
	_mat_hilo.shader = SH_PAVESA
	_mat_hilo.set_shader_parameter("es_hilo", 1.0)
	_mat_hilo.set_shader_parameter("fuerza", 1.0)
	_mat_hilo.set_shader_parameter("color", Paleta.NARANJA)
	_mat_hilo.set_shader_parameter("color_vivo", Paleta.ORO_CLARO)
	_hilo = MeshInstance3D.new()
	_hilo.mesh = tubo
	_hilo.material_override = _mat_hilo
	_hilo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hilo.layers = 8   # CAPA_DETALLE: lo menudo no va al reflejo en las cámaras de juego
	_hilo.visible = false
	add_child(_hilo)

## La otra mitad de la misma brasa: el cuerpo hermano con una ascua de la misma
## madre. Se busca una vez y se guarda; solo se vuelve a buscar si deja de valer.
func _buscar_pareja() -> Node3D:
	if _pareja != null and is_instance_valid(_pareja) and _es_mi_pareja(_pareja):
		return _pareja
	_pareja = null
	var padre := get_parent()
	if padre == null or c.madre < 0:
		return null
	for otro in padre.get_children():
		if otro != self and otro is Node3D and _es_mi_pareja(otro):
			_pareja = otro as Node3D
			break
	return _pareja

func _es_mi_pareja(otro: Node) -> bool:
	if not ("c" in otro) or not otro.has_method("centro"):
		return false
	var oc: Variant = otro.get("c")
	if not (oc is Criatura):
		return false
	var cr := oc as Criatura
	return cr != c and cr.especie == "gotita" and cr.madre == c.madre and cr.activa

## Tiende el hilo de esta ascua a la otra, si le toca dibujarlo (la de índice
## menor) y las dos están sueltas por la mesa. Se tensa al acercarse.
func _mover_hilo(sitio: Vector3) -> void:
	if _hilo == null:
		return
	var otra := _buscar_pareja()
	var S := Criatura.Estado
	var vale := otra != null and c.indice < (otra.get("c") as Criatura).indice
	if vale:
		var oc := otra.get("c") as Criatura
		vale = oc.estado != S.EN_BOLA and oc.estado != S.FUERA and oc.estado != S.ESCONDIDA \
			and c.estado != S.APARECER
	if not vale:
		_hilo.visible = false
		return
	var alto := Vector3(0.0, (_pivote + 0.04) * _k, 0.0)
	var a := sitio + alto
	# `centro()` ya viene con la transformada de la otra; el hilo cuelga de esta.
	var b: Vector3 = transform.affine_inverse() * (otra.call("centro") as Vector3) + alto
	var d := b - a
	var largo := d.length()
	if largo < 0.02:
		_hilo.visible = false
		return
	_hilo.visible = true
	var y := d / largo
	var x := y.cross(Vector3.UP)
	if x.length_squared() < 1e-6:
		x = Vector3.RIGHT
	x = x.normalized()
	var z := x.cross(y)
	# Tenso: más fino. Lejos (más de un palmo largo) casi no se ve.
	var tension := 1.0 - clampf((largo - 0.10) / 0.9, 0.0, 1.0)
	var grosor := lerpf(1.2, 0.7, tension)
	_hilo.transform = Transform3D(Basis(x * grosor, y * largo, z * grosor), (a + b) * 0.5)
	_mat_hilo.set_shader_parameter("tension", tension)
	_mat_hilo.set_shader_parameter("largo", largo)
	_mat_hilo.set_shader_parameter("fuerza", lerpf(0.35, 1.0, tension) * (1.3 if c.reuniendose else 1.0))

## No atravesarse a la vista (la cuenta, en `calavera.gd`): bajo un raíl bajo se
## agacha, y ante la calavera se hace a un lado. No sube: una llama no flota.
func _apartarse(delta: float, suelo: Vector3) -> void:
	if not _tramos_listos:
		_tramos_listos = true
		_tramos = Calavera.tramos_bajos(get_parent())
	# Lo que mide: la punta de la llama más medio bote.
	var alto := (_alto + _alzada * 0.5) * _k
	var alcance := c.radio * E * 1.1 + Calavera.ANCHO_RAIL
	var libre := Calavera.hueco_bajo_raiil(_tramos, suelo, alcance, alto)
	var agache := clampf(libre / alto, Calavera.AGACHE_MIN, 1.0)
	var e := Calavera.empuje(self, c, PackedStringArray(["escarabajo"]))
	_agache = lerpf(_agache, agache, 1.0 - exp(-12.0 * delta))
	_aparte = _aparte.lerp(Vector3(e.x, 0.0, e.y), 1.0 - exp(-8.0 * delta))
	Calavera.colocar(self, suelo, _agache, _aparte)

func _quieto() -> void:
	_agache = 1.0
	_aparte = Vector3.ZERO
	transform = Transform3D.IDENTITY

## LA CALIDAD (0 ALTA, 1 MEDIA, 2 BAJA): lo llama el núcleo. Lo que pesa aquí son
## las partículas; la llama y su luz se quedan, que son la criatura.
func calidad(n: int) -> void:
	if _pavesas == null:
		return
	var base := 9 if _ascua else 15
	var cuantas := base
	if n == 1:
		cuantas = int(round(base * 0.66))
	elif n >= 2:
		cuantas = int(round(base * 0.5))
	if _pavesas.amount != cuantas:
		_pavesas.amount = cuantas

func _curva(puntos: Array[Vector2]) -> Curve:
	var cu := Curve.new()
	for p in puntos:
		cu.add_point(p)
	return cu

func _degradado(sitios: Array[float], colores: Array[Color]) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(sitios)
	g.colors = PackedColorArray(colores)
	return g

# ------------------------------------------------------------------- sucesos

## El golpe: fogonazo, un puñado de chispas y la llama se va con la bola.
func golpear(normal: Vector2) -> void:
	_destello = 1.0
	_parada = 0.05
	# La bola viene de `normal` y sigue hacia el otro lado: se lleva la llama.
	_arr_vel += Vector3(-normal.x, 0.3, -normal.y) * 1.7
	_soltar_chispas(14, 1.0)

## Del contrato: BRASA no tiene coraza. Si alguien la llama, un parpadeo y ya.
func blindar() -> void:
	_destello = maxf(_destello, 0.35)

## El cerco de rescoldos se aviva un instante.
func avisar_aro() -> void:
	_aro_aviso = 1.0

func color() -> Color:
	return _color

## Dónde está el cuerpo, para que la cámara y los efectos lo sigan.
func centro() -> Vector3:
	return transform * _raiz.position

func _soltar_chispas(cuantas: int, fuerza: float, hacia := Vector3.UP, abre := 70.0) -> void:
	_chispas.amount = cuantas
	_chispas.initial_velocity_max = 1.15 * fuerza
	_chispas.initial_velocity_min = 0.45 * fuerza
	_chispas.direction = hacia
	_chispas.spread = abre
	_chispas.position = _raiz.position + Vector3(0.0, (_pivote + 0.03) * _k, 0.0)
	_chispas.restart()
	_chispas.emitting = true

func _ocultar() -> void:
	_quieto()
	_raiz.visible = false
	_pivote_carbon.visible = false
	_cerco.visible = false
	_pavesas.emitting = false
	_humo.emitting = false
	if _hilo != null:
		_hilo.visible = false

func _al_cambiar(antes: int, ahora: int) -> void:
	var S := Criatura.Estado
	var de_la_nada := antes == S.FUERA or antes == -1 or antes == S.ESCONDIDA
	if ahora == S.APARECER:
		# Nace del carbón: sin llama, y ya vuelta hacia donde va.
		_vida = 0.0
		_prende = 0.0
		_avivar = 0.0
		_s = 1.0
		_s_vel = 0.0
		_arr = Vector3.ZERO
		_arr_vel = Vector3.ZERO
		_vuelco = Quaternion.IDENTITY
		_yaw = _rumbo_de_la_cara()
		_abre = 0.0
	elif de_la_nada:
		# Un ascua recién partida entra ya volando: nace encendida, con su fogonazo.
		_vida = 0.8
		_s = 1.0
		_s_vel = 0.0
		_arr = Vector3.ZERO
		_arr_vel = Vector3.ZERO
		_yaw = _rumbo_de_la_cara()
		if ahora == S.VOLAR:
			_destello = 0.7
	if ahora == S.ALERTA:
		_aviso = 1.0
		_s_vel -= 3.0
	if ahora == S.EN_BOLA:
		# Donde se la VE: al colarse se quita lo agachada o apartada que fuera, y
		# así no salta.
		_desde = transform * _raiz.position
		_colarse_chispas = true
	if ahora == S.ATURDIDA:
		_s_vel -= 2.5

# --------------------------------------------------------------- cada cuadro

## `bola` es dónde está la bola que la lleva, si va dentro de una.
func actualizar(delta: float, bola: Vector3) -> void:
	_reloj += delta
	var S := Criatura.Estado
	var estado := c.estado
	var suelo := Vector3(c.pos.x * E, y_base, c.pos.y * E)
	var antes := _estado_antes
	if estado != antes:
		_al_cambiar(antes, estado)
		_estado_antes = estado
		if (estado == S.APARECER or estado == S.VOLAR) \
				and (antes == S.FUERA or antes == -1 or antes == S.ESCONDIDA):
			_raiz.position = suelo
			_soltar_chispas(8 if estado == S.APARECER else 12, 0.8)

	if not c.activa or estado == S.FUERA or estado == S.ESCONDIDA:
		# Fuera no hay golpe que enseñar: si se guarda, salta al reaparecer.
		_parada = 0.0
		_destello = 0.0
		_ocultar()
		return
	if estado == S.EN_BOLA:
		_quieto()
		_colarse(bola)
		return

	_apartarse(delta, suelo)
	_raiz.visible = true
	_pivote_carbon.visible = true
	_cerco.visible = true
	_forma.visible = true
	for ojo in _ojos:
		ojo.visible = true

	# La parada del golpe: 50 ms con la pose congelada y todo al blanco. Solo en
	# lo que se ve: la mesa no se detiene.
	if _parada > 0.0:
		_parada -= delta
		_pintar(estado, false)
		return

	var v3 := Vector3(c.vel.x, 0.0, c.vel.y) * E
	var rapidez := v3.length()
	var salto := 0.0
	var vy := 0.0
	var vida_obj := 1.0
	var avivar_obj := 0.0
	var s_obj := 1.0
	var calor_obj := 1.0
	var tirar := 1.0
	var vuelco_obj := Quaternion.IDENTITY
	var endereza := 14.0
	var escala_carbon := 1.0
	var prisa := 1.0
	var humea := false

	if estado == S.CORRER or estado == S.HUIR:
		if c.salta and c.bote_u >= 0.0:
			# El bote lo dicta la lógica: de 0 a 1 en el aire, −1 posada.
			salto = _alzada * sin(PI * c.bote_u)
			vy = _alzada * PI * cos(PI * c.bote_u) / maxf(c.bote_tiempo, 0.05)
			if not _en_aire:
				_en_aire = true
				_s_vel += 3.4
		elif _en_aire:
			# Ha caído: el carbón se clava y la llama se le viene encima.
			_en_aire = false
			_s_vel -= 6.5
			_soltar_chispas(4, 0.45)
		else:
			# Posada respira: un fuego quieto no está quieto.
			s_obj = 1.0 + 0.022 * sin(_reloj * 3.1)
		if estado == S.HUIR:
			avivar_obj = 0.40
			tirar = 2.1
			prisa = 1.6
		elif c.reuniendose:
			# Dos ascuas que se buscan: se avivan a golpes, como llamándose.
			avivar_obj = 0.28 + 0.22 * sin(_reloj * 10.0)
			prisa = 1.3
	elif estado == S.ALERTA:
		# Se encoge y se aviva: es el aviso de que va a salir.
		s_obj = 0.70
		avivar_obj = 1.0
		calor_obj = 1.7
		prisa = 1.9
	elif estado == S.VOLAR:
		# Sale rodando: el carbón rueda de verdad, lo que avanza, y la llama va a
		# rastras, medio sofocada.
		var t := c.t_estado
		salto = 0.11 * _talla * absf(sin(t * 9.0)) * exp(-t * 3.0)
		if rapidez > 0.02:
			var eje := Vector3.UP.cross(v3 / rapidez)
			_vuelco = (Quaternion(eje, rapidez * delta / _radio_rueda) * _vuelco).normalized()
		vuelco_obj = _vuelco
		vida_obj = 0.72
		avivar_obj = 0.25
		s_obj = 0.86
		tirar = 1.9
		calor_obj = 1.4
		prisa = 1.6
	elif estado == S.APARECER:
		# Prende: primero el carbón, luego sube la llama y se pasa de alta.
		var u := clampf(c.t_estado / 0.6, 0.0, 1.0)
		vida_obj = smoothstep(0.08, 0.72, u)
		_vida = vida_obj
		_prende = smoothstep(0.05, 0.60, u)
		avivar_obj = sin(PI * clampf((u - 0.15) / 0.85, 0.0, 1.0)) * 0.8
		s_obj = 1.0 + 0.30 * sin(PI * u)
		calor_obj = lerpf(0.5, 1.8, smoothstep(0.0, 0.5, u))
		var k := clampf(u / 0.28, 0.0, 1.0)
		escala_carbon = 1.0 - pow(1.0 - k, 3.0) * 0.55 + sin(k * PI) * 0.12
		prisa = 1.6
	else:
		# ATURDIDA (y, si alguna vez le tocaran, ACORRALADA o VOLCADA): casi
		# apagada. Un rescoldo que humea, con la brasa a la vista.
		vida_obj = 0.24
		s_obj = 0.94
		calor_obj = 0.62 + 0.20 * sin(_reloj * 2.3)
		endereza = 7.0
		prisa = 0.55
		humea = true
	if estado != S.CORRER and estado != S.HUIR:
		_en_aire = false

	# --- Los muelles
	if estado != S.APARECER:
		_prende = 1.0
		_vida = lerpf(_vida, vida_obj, 1.0 - exp(-(10.0 if vida_obj < _vida else 4.5) * delta))
	_avivar = lerpf(_avivar, avivar_obj, 1.0 - exp(-13.0 * delta))
	_calor = lerpf(_calor, calor_obj, 1.0 - exp(-8.0 * delta))
	_s_vel += (-430.0 * (_s - s_obj) - 15.0 * _s_vel) * delta
	_s = clampf(_s + _s_vel * delta, 0.5, 1.6)
	var arr_obj := -v3 * 0.052 * tirar + Vector3(0.0, -vy * 0.032, 0.0)
	if arr_obj.length() > 0.14:
		arr_obj = arr_obj.normalized() * 0.14
	_arr_vel += ((arr_obj - _arr) * 150.0 - _arr_vel * 12.0) * delta
	_arr += _arr_vel * delta
	if _arr.length() > 0.2:
		_arr = _arr.normalized() * 0.2
	if estado != S.VOLAR:
		_vuelco = _vuelco.slerp(vuelco_obj, 1.0 - exp(-endereza * delta))
	_yaw = lerp_angle(_yaw, _rumbo_de_la_cara(), 1.0 - exp(-VUELTA_CARA * delta))
	_t_fuego += delta * prisa

	# --- Dónde y cómo
	var sitio := suelo + Vector3(0.0, salto, 0.0)
	_raiz.transform = Transform3D(Basis(Vector3.UP, _yaw).scaled(Vector3.ONE * _k), sitio)
	_pivote_carbon.transform = Transform3D(
		Basis(_vuelco) * Basis(Vector3.UP, _yaw_carbon) * Basis.from_scale(Vector3.ONE * escala_carbon * _k),
		sitio + Vector3(0.0, _centro_carbon * escala_carbon * _k, 0.0))

	# La llama: aplastada o estirada (sin perder bulto) y, al prender, creciendo
	# entera desde el carbón. NADA MÁS: no se ladea ni se encoge aquí. Lo que se
	# queda atrás son las puntas (el arrastre, en el shader, con peso altura²) y lo
	# que se apaga son las lenguas (`brasa_talla_lenguas`, también en el shader):
	# la base, la cara y los ojos se quedan donde están.
	var ancho := 1.0 / sqrt(maxf(_s, 0.3))
	var crece := lerpf(0.30, 1.0, _prende)
	var escala := Vector3(ancho, _s, ancho) * crece
	var base_forma := Basis.from_scale(escala)
	_forma.transform = Transform3D(base_forma, Vector3(0.0, _pivote, 0.0))
	# El arrastre, en el marco de la malla: ya escalada.
	_arr_malla = base_forma.inverse() * (Basis(Vector3.UP, -_yaw) * _arr)
	_arr_malla.y = clampf(_arr_malla.y, -0.10, 0.10)

	_destello = maxf(_destello - delta * 4.5, 0.0)
	_aviso = maxf(_aviso - delta * 2.2, 0.0)
	_aro_aviso = maxf(_aro_aviso - delta * 3.0, 0.0)
	_mover_ojos(delta, estado)
	_pintar(estado, salto > 0.02)

	# --- La luz: tiembla como tiembla un fuego (±15 %, con tres ondas que no
	# casan, para que no se le note el compás) y dice lo viva que está.
	_luz.light_energy = (0.12 + 0.80 * _vida * _prende + 0.25 * _avivar + 0.9 * _destello) 		* _temblor() * _talla

	# --- Las partículas
	_pavesas.position = sitio + Vector3(0.0, (_pivote + 0.05 * _talla) * _k, 0.0)
	_pavesas.emitting = _vida > 0.5
	_pavesas.speed_scale = 1.0 + 1.4 * _avivar
	_humo.position = sitio + Vector3(0.0, (_pivote + 0.03) * _k, 0.0)
	_humo.emitting = humea

	# El ascua está rota: crepita, con chispas sueltas a golpes. Y el hilo.
	if _ascua:
		_crepita -= delta
		if _crepita <= 0.0 and _vida > 0.5 and _parada <= 0.0:
			_crepita = CHISPORROTEO * (0.6 + 0.8 * fposmod(_reloj * 7.13 + float(c.indice), 1.0))
			_soltar_chispas(3, 0.45, Vector3.UP, 50.0)
		_mover_hilo(sitio)

## Hacia dónde se vuelve la cara: hacia la cámara que la mira, solo en planta
## (un giro en Y). Sin cámara a mano, hacia `hacia_camara`.
func _rumbo_de_la_cara() -> float:
	var cam: Camera3D = null
	if is_inside_tree():
		cam = get_viewport().get_camera_3d()
	if cam != null:
		var yo := global_transform * Vector3(c.pos.x * E, y_base, c.pos.y * E)
		var d := cam.global_position - yo
		if Vector2(d.x, d.z).length_squared() > 1e-6:
			return atan2(d.x, d.z) - global_rotation.y
	return atan2(hacia_camara.x, hacia_camara.y)

## El temblor de la luz: 1 ± 0,15.
func _temblor() -> float:
	var t := _t_fuego
	return 1.0 + 0.15 * (0.5 * sin(t * 11.3) + 0.3 * sin(t * 23.7 + 1.3) + 0.2 * sin(t * 37.1 + 4.1))

## Los ojos: adónde miran, cuánto se abren y qué cara ponen.
func _mover_ojos(delta: float, estado: int) -> void:
	var S := Criatura.Estado
	_prox_parpadeo -= delta
	if _prox_parpadeo <= 0.0:
		_parpadeo = 0.14
		_prox_parpadeo = 2.2 + fposmod(_reloj * 7.3 + float(c.indice), 2.5)
	_parpadeo = maxf(_parpadeo - delta, 0.0)

	var abre := 1.0
	var pupila := 1.0
	var ceja := 0.10
	var vago := false
	if estado == S.ALERTA:
		abre = 1.3
		pupila = 0.60
		ceja = -0.25
	elif estado == S.HUIR:
		abre = 1.15
		pupila = 0.78
		ceja = -0.55
	elif estado == S.VOLAR:
		abre = 0.30
		ceja = 0.9
	elif estado == S.APARECER:
		abre = smoothstep(0.30, 0.85, clampf(c.t_estado / 0.6, 0.0, 1.0)) * 1.1
	elif estado != S.CORRER:
		abre = 0.40
		pupila = 0.85
		ceja = -0.35
		vago = true
	elif _parpadeo > 0.0:
		abre = 0.05
	_abre = lerpf(_abre, abre, 1.0 - exp(-(30.0 if abre < _abre else 16.0) * delta))
	_pupila = lerpf(_pupila, pupila, 1.0 - exp(-14.0 * delta))
	_ceja = lerpf(_ceja, ceja, 1.0 - exp(-12.0 * delta))

	# La mirada: la bola, llevada al marco de cada ojo. Lo que cuenta es por dónde
	# cae en el plano de la cuenca; si está detrás, la pupila se va al canto.
	var mira := c.mira if c.mira != Vector2.ZERO else c.pos + hacia_camara * 120.0
	var objetivo := Vector3(mira.x * E, y_base + 0.09, mira.y * E)
	for i in _ojos.size():
		var ojo := _ojos[i]
		var mirada := Vector2.ZERO
		if vago:
			# Aturdida no mira nada: los ojos le dan vueltas, cada uno a su aire.
			var a := _reloj * 3.4 + float(i) * 2.2
			mirada = Vector2(cos(a), sin(a) * 0.7) * 0.20
		else:
			var d := ojo.global_transform.affine_inverse() * objetivo
			var en_plano := Vector2(d.x, d.y)
			var lejos := en_plano.length()
			if lejos > 1e-4:
				var cuanto := clampf(lejos / maxf(absf(d.z) * 0.9 + 0.12, 0.05), 0.0, 1.0)
				mirada = en_plano / lejos * cuanto * Vector2(0.36, 0.24)
		if i == 0:
			_mirada = _mirada.lerp(mirada, 1.0 - exp(-16.0 * delta))
			mirada = _mirada
		else:
			# El segundo ojo converge con el primero: mira lo mismo, un pelo cruzado.
			mirada = _mirada if not vago else mirada
		var guino := _abre
		if vago and i == 1:
			guino *= 0.62
		var mat := _mats_ojo[i]
		mat.set_shader_parameter("mirada", mirada)
		mat.set_shader_parameter("abre", guino)
		mat.set_shader_parameter("pupila", _pupila)
		mat.set_shader_parameter("ceja", _ceja)
		mat.set_shader_parameter("brillo", lerpf(0.55, 1.0, _vida) + 0.35 * _avivar)
		mat.set_shader_parameter("golpe", _destello)
		# De par en par, la cuenca entera crece un poco: se lee de lejos.
		var crece := 1.0 + 0.16 * clampf(_abre - 1.0, 0.0, 0.4) / 0.4
		ojo.transform = Transform3D(_reposo_ojos[i].basis * Basis.from_scale(Vector3(crece, crece, 1.0)),
			_reposo_ojos[i].origin)

## Los mandos de los shaders.
func _pintar(estado: int, en_el_aire: bool) -> void:
	for m in _mats_fuego:
		m.set_shader_parameter("tiempo", _t_fuego)
		m.set_shader_parameter("arrastre", _arr_malla)
		m.set_shader_parameter("vida", _vida)
		m.set_shader_parameter("avivar", _avivar)
		m.set_shader_parameter("golpe", _destello)
	_mat_carbon.set_shader_parameter("tiempo", _reloj)
	_mat_carbon.set_shader_parameter("calor", _calor)
	_mat_carbon.set_shader_parameter("golpe", _destello)
	for m in _mats_ojo:
		m.set_shader_parameter("golpe", _destello)

	# El cerco, en la losa: donde está de verdad, aunque ella vaya por el aire.
	# Durante la parada del golpe no: se queda clavado con el cuerpo.
	if _parada <= 0.0:
		_cerco.position = Vector3(c.pos.x * E, y_base + 0.012, c.pos.y * E)
	var S := Criatura.Estado
	var brillo := 0.62
	if estado == S.ATURDIDA:
		brillo = 0.30
	elif estado == S.APARECER:
		brillo = 0.62 * clampf(c.t_estado / 0.5, 0.0, 1.0)
	# Un ascua a la que ya basta tocar para recogerla: el cerco late.
	var late := 1.0 if (_ascua and c.rendida()) else 0.0
	_mat_cerco.set_shader_parameter("tiempo", _reloj)
	_mat_cerco.set_shader_parameter("brillo", brillo)
	_mat_cerco.set_shader_parameter("late", late)
	_mat_cerco.set_shader_parameter("aviso", maxf(maxf(_aviso, _aro_aviso), _destello * 0.8))
	_mat_cerco.set_shader_parameter("tizne", 0.55 if en_el_aire else 1.0)

## EN_BOLA: se mete en el cascabel. No se estira hasta la bola: se ENCOGE de
## golpe, en T_COLARSE, hacia un punto que se arrima a la bola como mucho
## ALCANCE_COLARSE, con un fogonazo, la luz al máximo y un puñado de chispas que
## salen disparadas hacia la bola. El carbón se consume en su sitio, en el suelo.
## Hubo un «genio en la lámpara»: la llama se afilaba en un hilo que iba hasta la
## bola, y con la bola ya lejos era un tubo naranja gigante y sin acabar que
## cruzaba el encuadre, con el carbón flotando solo.
func _colarse(bola: Vector3) -> void:
	var u := clampf(c.t_estado / T_COLARSE, 0.0, 1.0)
	_cerco.visible = false
	_pavesas.emitting = false
	_humo.emitting = false
	if _hilo != null:
		_hilo.visible = false
	var suelo := Vector3(_desde.x, y_base, _desde.z)
	var a_bola := Vector3(bola.x - suelo.x, 0.0, bola.z - suelo.z)
	if a_bola.length() > ALCANCE_COLARSE:
		a_bola = a_bola.normalized() * ALCANCE_COLARSE
	if _colarse_chispas:
		_colarse_chispas = false
		_raiz.position = suelo
		var hacia := (bola - (suelo + Vector3(0.0, _pivote * _k, 0.0))).normalized()
		_soltar_chispas(16, 1.1, (hacia + Vector3.UP * 0.4).normalized(), 30.0)
	if u >= 1.0:
		_raiz.visible = false
		_pivote_carbon.visible = false
		_luz.light_energy = 0.0
		return
	_raiz.visible = true
	_pivote_carbon.visible = true
	for ojo in _ojos:
		ojo.visible = u < 0.6
	# Primero se hincha un pelo (el fogonazo) y luego se va a cero.
	var k := (1.0 - smoothstep(0.08, 1.0, u)) * (1.0 + 0.18 * sin(PI * minf(u / 0.25, 1.0)))
	var sitio := suelo + a_bola * smoothstep(0.0, 1.0, u)
	_raiz.transform = Transform3D(Basis(Vector3.UP, _yaw).scaled(Vector3.ONE * _k), sitio)
	_forma.transform = Transform3D(Basis.from_scale(Vector3.ONE * maxf(k, 0.001)),
		Vector3(0.0, _pivote + (_alto - _pivote) * 0.3 * (1.0 - k), 0.0))
	# El carbón, en el suelo, se consume un poco por detrás de la llama.
	var kc := maxf(1.0 - smoothstep(0.15, 1.0, u), 0.001)
	_pivote_carbon.transform = Transform3D(
		Basis(Vector3.UP, _yaw_carbon) * Basis.from_scale(Vector3.ONE * kc * _k),
		suelo + Vector3(0.0, _centro_carbon * kc * _k, 0.0))
	_t_fuego += 0.03
	var fogonazo := 1.0 - smoothstep(0.0, 0.9, u)
	for m in _mats_fuego:
		m.set_shader_parameter("tiempo", _t_fuego)
		m.set_shader_parameter("arrastre", Vector3.ZERO)
		m.set_shader_parameter("vida", 1.0)
		m.set_shader_parameter("avivar", 0.6)
		m.set_shader_parameter("golpe", fogonazo)
	for m in _mats_ojo:
		m.set_shader_parameter("golpe", fogonazo)
	_mat_carbon.set_shader_parameter("calor", 1.8)
	_mat_carbon.set_shader_parameter("golpe", fogonazo * 0.6)
	_luz.light_energy = (0.7 + 1.1 * fogonazo) * kc * _talla
