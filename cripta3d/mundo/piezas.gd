extends RefCounted

## CRIPTA 3D · MÓDULO «piezas»: LO QUE GOLPEA LA BOLA.
##
## Cada pieza es un objeto de la mazmorra sacado de los sprites del juego
## (`mesa_x4.png`), modelado por guion en Blender (`cripta3d/blender/
## piezas_modelos.py` → `modelos/piezas_cripta.glb`) y puesto donde dice la
## mesa, a la medida de su colisionador. Nada sale de coordenadas escritas aquí.
##
##   pieza (rótulo)        sale de                    qué hace
##   --------------------  -------------------------  ----------------------------------
##   BRASEROS (búmperes)   mesa.bumpers, p.bumper_radio  engranaje de hierro con óxido en
##                                                    lo hondo, un aro remachado y su
##                                                    cuenco de brasas, que ARDE SIEMPRE
##                                                    con una llama pequeña. Al golpe el aro
##                                                    SALTA, la rueda gira un diente, las
##                                                    brasas se ponen al blanco y sale
##                                                    una LLAMARADA que sube por encima
##                                                    de las lápidas
##   gomas (slingshots)    colisionadores SLINGSHOT   bastidor de hierro de tres postes
##                                                    con su banda de goma: ROJA (apagada)
##                                                    solo en la cara de golpe, negra en
##                                                    el resto. Al golpe la banda se
##                                                    ESTIRA hacia `cara`
##   postes                mesa.postes, p.poste_radio poste de piedra con zuncho y aro de
##                                                    goma roja, que se aplasta al golpe
##   LÁPIDAS y ESCUDOS     mesa.targets, c.banco,     lápidas de piedra con calavera y
##   (targets)             mesa.info_bancos[b]        escudos de roble con herrajes. Se
##                                                    ABATEN (se hunden por su ranura,
##                                                    echándose atrás) cuando `activo`
##                                                    es false y VUELVEN
##   palas                 mesa.flippers              LÁGRIMA de hierro forjado (la tapa,
##                                                    afilada como el sprite) sobre una
##                                                    goma negra que va de 10 px de radio
##                                                    en el eje a 5 en la punta (ver la
##                                                    EXCEPCIÓN del punto 1), y el eje de
##                                                    acero: giran con `angulo` y dejan
##                                                    una ESTELA
##   TORNOS (giradores)    mesa.giradores,            molinete de hierro entre dos
##                         mesa.info_tornos[i].eje    postecillos: gira con la fuerza
##                                                    del paso y se va frenando solo
##   SARCÓFAGO (platillo)  mesa.platillos             un sarcófago hundido en el coro,
##                                                    con la tapa apoyada en el rincón:
##                                                    se TRAGA la bola entera, el
##                                                    rescoldo de dentro se aviva, y la
##                                                    ESCUPE con polvo y un fogonazo
##   lanzador              p.inicio_bola,             ariete de hierro con su muelle:
##                         mesa.carga_lanzador        retrocede y aprieta el muelle con
##                                                    `carga_lanzador` (0..1)
##
## SEÑALES QUE ESCUCHA (de `mundo.mesa`)
##   bumper_golpeado(punto, fuerza)        → el brasero más cercano salta
##   slingshot_golpeado(punto, fuerza)     → la goma más cercana patea
##   poste_golpeado(punto, fuerza)         → la goma del poste se aplasta
##   girador_girado(punto, indice, fuerza) → el torno coge velocidad
##   platillo_capturado(punto, indice)     → el sarcófago se aviva
##   platillo_expulsado(punto, indice)     → polvo, chispas y fogonazo
## Y LEE EN CADA CUADRO: `flippers[i].angulo`, `targets[i].activo`,
## `carga_lanzador`. Las chispas, las ondas y la sacudida de los golpes normales
## NO son de aquí: las pone «efectos», que escucha las mismas señales. Lo único
## que pide aquí es el polvo del sarcófago al escupir, que es suyo.
##
## FUNCIONES PÚBLICAS    ninguna.
##
## LO QUE NO PUEDE DEJAR DE HACER QUIEN LO REESCRIBA
##   1. LO QUE CHOCA MIDE LO QUE MIDE EL COLISIONADOR, y es una CÁPSULA (segmento
##      a→b con radio; con a == b, un círculo). La goma de la pala, el diente
##      más salido del engranaje, la cara de la lápida y el aro del poste están
##      EXACTAMENTE donde el colisionador; el adorno va por dentro o por encima
##      de la bola (centro a 0,09, techo a 0,18). Los modelos están hechos a la
##      medida NOMINAL (`R_*`, `L_*`) y aquí se escalan o se ESTIRAN (`_estirar`)
##      a la de verdad: si la mesa cambia un radio, la pieza lo sigue.
##      LA ÚNICA EXCEPCIÓN, CONSCIENTE, SON LAS PALAS (decisión 6 del remate). El
##      colisionador es una cápsula de radio 8 px de punta a punta; la goma que
##      se ve va de radio 10 px en el eje a 5 px en la punta (+2 px y −3 px
##      respecto a lo que choca), y de costado baja un 16 % hacia la punta. Con
##      la regla estricta (±1,4 px: de 9,4 a 6,6) las palas se leyeron como
##      barras en dos revisiones seguidas; a velocidad de juego tres píxeles en
##      la punta no se notan y la lágrima del sprite, sí. No se amplía a
##      ninguna otra pieza ni a más de esos números sin que lo decidan Daniel o
##      Fátima. Las medidas están en `piezas_modelos.py` (`R_EJE`, `R_PUNTA`,
##      `CAIDA_ALTO`) y aquí se estiran con la pala como siempre.
##   2. La pala gira alrededor de `eje` con `rotation.y = -angulo`, y las tres
##      palas se ven SIEMPRE (`LEEME.md`). La del coro va a `H_ALTA`: se sabe
##      porque `f.capas == Colisionador.bit(Mesa.CAPA_ALTA)`.
##   3. Cada búmper, cada goma y cada lápida es SU nodo, porque se mueve sola.
##      Y el material que se anima se DUPLICA antes: `mat.dame("ascua")` es un
##      material compartido, y sin duplicar se encienden los tres a la vez. El
##      ascua de la biblioteca se anima con su parámetro "energia"; el carbón,
##      con "emision_grietas".
##      Y TODO LO QUE SE MUEVE pide su material con `{"local": true}`: el
##      dibujo de la biblioteca va en coordenadas de mundo, y sin eso la pala
##      resbala por dentro de su propia textura al girar.
##   4. La luz de los braseros se pide con `mundo.luz_fuego` y se aviva con
##      `mundo.avivar(luz, 1.0)`. No se escribe `light_energy`: la pisa el núcleo.
##   5. LO QUE SE HUNDE BAJO EL SUELO SALE EN EL REFLEJO COMO SI ESTUVIERA
##      LEVANTADO: la cámara del reflejo mira desde debajo y ve lo que hay bajo
##      y = 0. Por eso la lápida abatida se pasa a `CAPA_SIN_REFLEJO` mientras
##      está abajo (y del todo abajo se apaga). Cualquier otra cosa que baje, igual.
##   6. La bola dentro del sarcófago la coloca el NÚCLEO: queda con el centro a
##      `mundo.hundimiento_platillo` radios sobre el suelo del coro. Aquí se pone
##      a −1,3 en `montar`: el sarcófago se la traga ENTERA (queda bajo el suelo
##      de la tribuna, que la tapa) y la escupe.
##   7. El sarcófago NO tiene paredes en la simulación: la bola pasa rozándolo
##      sin caer. Por eso está HUNDIDO: el borde no levanta más de dos
##      centésimas, y la tapa está en el rincón de detrás, donde la bola no cabe
##      (entre el platillo y las paredes del coro quedan 13 px y la bola mide 18).
##   8. Los braseros son TRES y están juntos: con una luz cada uno son tres
##      luces de las ocho que caben por malla. Aquí hay UNA para el racimo.
##   9. El eje de cada torno NO es siempre el eje X: lo dice
##      `mesa.info_tornos[i]["eje"]` (unitario, perpendicular a por donde lo
##      cruza la bola). El del coro va en diagonal. El índice de la señal
##      `girador_girado` es el de `mesa.giradores`.
##  10. Un target es una cápsula y no tiene cara: hacia dónde mira cada banco lo
##      dice `mesa.info_bancos[b]["cara"]` (la normal del lado por el que le da
##      la bola), y qué es, `["clave"]` ("targets" las lápidas, "escudos" los
##      escudos). LA MESA SIGUE CRECIENDO: todo lo que haya en `targets`,
##      `giradores`, `bumpers`, `postes` y `platillos` se dibuja recorriendo la
##      lista, nunca contando con que son tres o que es uno.
##  11. LA GOMA DE LA HONDA NO PUEDE ENGORDAR HACIA ATRÁS: detrás de cada goma
##      va el pasillo del inlane, y entre la goma y la pared del pasillo quedan
##      de 30 a 34 px para una bola de 18. Por eso el bastidor es un triángulo
##      CHATO: el tercer poste va a `HONDA_FONDO` px de la banda, y lo de detrás
##      no pasa de 12 px. Lo que da presencia es la placa de arriba, no el fondo.
##  12. EL PESO (decisión 7 de la revisión: piezas ≤ 60.000 triángulos en una
##      pasada). Eran 117.038, con 109 k haciendo sombra y 114 k en el reflejo.
##      Los modelos se adelgazan en el guion de Blender (no aquí), y lo menudo
##      —remates, tornillería, el torno, el lanzador, los postes de la honda—
##      va por `_menudo`: sin sombra y fuera del reflejo. Lo que choca y se ve
##      grande (ruedas, lápidas, escudos, palas) se queda con las dos cosas.
##  13. LAS LÁPIDAS SON BAJAS A PROPÓSITO (0,168): más altas tapaban los braseros
##      desde las cámaras de juego. No se suben sin mirar --vista=0 y --vista=1
##      con --guion=…:brasero.
##  14. LA GOMA ROJA QUE SE VE EN EL EJE DE CADA PALA ES LA DEL POSTE que va
##      encima del eje, no de la pala: la pala es hierro y goma negra, como el
##      sprite. Si se quita ese poste, el rojo del eje se va con él.

const Nucleo := preload("res://cripta3d/mundo_cripta.gd")
const MesaCripta := preload("res://cripta3d/mesa_cripta.gd")
const MODELOS := "res://cripta3d/modelos/piezas_cripta.glb"
const ESTELA := preload("res://cripta3d/mundo/piezas_estela.gdshader")
const LLAMARADA := preload("res://cripta3d/mundo/piezas_llamarada.gdshader")

const E := 0.01

## Las medidas NOMINALES a las que están hechos los modelos (en unidades 3D).
## Son las del colisionador de hoy; la de verdad se lee de la mesa.
const R_BUMPER := 0.19
const R_POSTE := 0.11
const R_TORNO := 0.10
const Y_EJE_TORNO := 0.14
const R_PLATILLO := 0.13
const L_PALA := 0.64
const R_PALA := 0.08
## El target nominal: 30 px de largo con sus puntas y 8 de grueso. Las puntas
## (de −0,15 a −0,08 y de 0,08 a 0,15) no se estiran; el tramo del medio, sí.
const L_TARGET := 0.30
const R_TARGET := 0.04
const TRAMO_TARGET := 0.08
## El tramo recto de la pala, el que se estira para hacerla más larga o corta.
const TRAMO_PALA := Vector2(0.12, 0.50)

const DIENTES := 10
## La energía del ascua en reposo y lo que sube con un golpe.
const ASCUA_REPOSO := 2.4
const ASCUA_GOLPE := 6.0
## Lo que salta el aro del brasero con un golpe, en unidades.
const SALTO_ARO := 0.045
## LA LLAMARADA del golpe (ver `piezas_llamarada.gdshader`): de dónde nace (la
## boca del cuenco, en medidas del modelo), cuánto dura y cuánto mide de alta y
## de ancha en su punto más alto. 0,42 sobre el cuenco la deja 0,4 por encima de
## las lápidas, que es lo que hace falta para que se vea desde RASANTE y
## SEGUIMIENTO (comprobado con --guion=…:brasero desde --vista=0 y --vista=1).
const Y_BOCA_BRASERO := 0.10
const DURA_LLAMARADA := 0.32
const ALTO_LLAMARADA := 0.52
const ANCHO_LLAMARADA := 0.27
## LA LLAMA DE REPOSO (decisión 1 del remate, el hallazgo grave): los tres
## braseros del campo tenían que ser la luz principal de la mesa y desde la
## RASANTE eran tres engranajes oscuros con un punto de ascua, más apagados que
## las antorchas de la albardilla. Ahora cada cuenco ARDE SIEMPRE: el mismo
## cartel de la llamarada, más pequeño y a media fuerza, que asoma por encima de
## las lápidas (0,168); el golpe la estira a la llamarada de siempre, más alta.
## (Con 0,30 × 0,16 se veía desde SEGUIMIENTO más chica que la antorcha de la
## albardilla de al lado: un punto más, sin dejar de ser pequeña.)
const FUERZA_REPOSO := 0.58
const ALTO_REPOSO := 0.35
const ANCHO_REPOSO := 0.19
## LA LUZ DEL RACIMO en reposo, su alcance y dónde va. Con 1,1 y 2,0 en el
## centro del racimo no llegaba a las lápidas y la franja de arriba del campo
## caía a 47 de luminancia. *Probado y quitado:* 2,0 y 2,7 en el mismo sitio:
## el suelo de los braseros se quemaba a crema y la luz subía por el ábside
## (que no se aclara, decisión 1). Va ADELANTADA hacia las lápidas
## (`ADELANTO_LUZ`, en z) y algo más alta: el reparto entre lo cercano y las
## lápidas se empareja sin quemar lo de al lado ni llegar al ábside. El reparto
## de «entorno» la deja tal cual (es del campo, × 1).
const LUZ_BRASEROS := 1.6
const ALCANCE_BRASEROS := 2.3
const ADELANTO_LUZ := 0.3
const Y_LUZ_BRASEROS := 0.6
## Lo que brilla el cartel de la llama en reposo y en lo alto del golpe. A 2,2
## en reposo el corazón blanco ocupaba media llama y parecía una vela.
const BRILLO_REPOSO := 1.5
const BRILLO_GOLPE := 2.2

## LA HONDA (las gomas). En píxeles de mesa. Ver el punto 11 de la cabecera.
const HONDA_POSTE := 2.8       # radio del fuste de los postes
const HONDA_BANDA := 2.4       # grueso de la goma
const HONDA_FONDO := 6.5       # cuánto se aparta el tercer poste de la banda
const HONDA_PATADA := 3.2      # cuánto se estira la banda al patear
const HONDA_Y := Vector2(0.045, 0.122)   # de dónde a dónde llega la banda

## EL LANZADOR: cuánto retrocede el ariete con la carga entera, y el largo del
## muelle suelto. Con 7 vueltas de alambre de 0,0156 el muelle no baja de 0,109:
## 0,26 − 0,15 = 0,11, apretado pero sin atravesarse. (Si se engorda el alambre
## en `piezas_modelos.py`, se mira esta cuenta.)
const RETRO_LANZADOR := 0.15
const LARGO_MUELLE := 0.26
const FONDO_CABEZA := 0.094

## LA TAPA DEL SARCÓFAGO, apoyada en el rincón: a cuánto del centro del platillo
## posa el pie (px, por detrás) y cuánto se inclina (grados sobre el suelo).
const TAPA_PIE := 25.0
const TAPA_INCLINA := 62.0

var _mundo: Nucleo
var _mesa: MesaCripta
var _mallas: Dictionary = {}
var _avisado := false

var _braseros: Array[Dictionary] = []
var _luz_braseros: OmniLight3D = null
var _gomas: Array[Dictionary] = []
var _postes: Array[Dictionary] = []
var _lapidas: Array[Dictionary] = []
var _palas: Array[Dictionary] = []
var _tornos: Array[Dictionary] = []
var _sarcofagos: Array[Dictionary] = []
var _lanzador: Dictionary = {}

func montar(mundo: Node3D) -> void:
	_mundo = mundo as Nucleo
	_mesa = _mundo.mesa
	_cargar_mallas()
	# El sarcófago se traga la bola entera: ver el punto 6.
	if not _mesa.platillos.is_empty():
		_mundo.hundimiento_platillo = -1.3
	_montar_braseros()
	_montar_gomas()
	_montar_postes()
	_montar_lapidas()
	_montar_palas()
	_montar_tornos()
	_montar_sarcofagos()
	_montar_lanzador()
	_mesa.bumper_golpeado.connect(_al_golpear_brasero)
	_mesa.slingshot_golpeado.connect(_al_golpear_goma)
	_mesa.poste_golpeado.connect(_al_golpear_poste)
	_mesa.girador_girado.connect(_al_girar_torno)
	_mesa.platillo_capturado.connect(_al_tragar)
	_mesa.platillo_expulsado.connect(_al_escupir)

# ------------------------------------------------------------------ utilidades

## Saca las mallas del GLB por el nombre de su objeto. Del GLB solo se usa la
## MALLA: en el fichero van repartidas en fila para poder mirarlas.
func _cargar_mallas() -> void:
	if not ResourceLoader.exists(MODELOS):
		print("PIEZAS: falta %s (cripta3d/blender/piezas_modelos.py): las piezas salen vacías" % MODELOS)
		return
	var escena := (load(MODELOS) as PackedScene).instantiate()
	_recoger(escena)
	escena.free()

func _recoger(nodo: Node) -> void:
	var mi := nodo as MeshInstance3D
	if mi != null and mi.mesh != null:
		_mallas[String(mi.name)] = mi.mesh
	for hijo in nodo.get_children():
		_recoger(hijo)

func _malla(nombre: String) -> Mesh:
	var m: Mesh = _mallas.get(nombre)
	if m == null:
		if not _avisado:
			print("PIEZAS: no encuentro «%s» en el GLB; ¿hay que reimportar?" % nombre)
			_avisado = true
		return BoxMesh.new()
	return m

## Un material de la biblioteca que usa el color de vértice del modelo.
func _mat(nombre: String, variante: Dictionary = {}) -> Material:
	var v := {"vertice": true}
	v.merge(variante, true)
	return _mundo.mat.dame(nombre, v)

## Una copia propia de un material de la biblioteca, para poder animarlo.
func _propio(nombre: String, variante: Dictionary = {}) -> Material:
	var m: Material = _mat(nombre, variante)
	return m.duplicate() as Material if m != null else null

func _pieza(padre: Node3D, malla: Mesh, material: Material, sombra: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(mi)
	return mi

## Lo repetido y quieto, en una sola llamada de dibujo.
func _multi(malla: Mesh, material: Material, sitios: Array[Transform3D]) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malla
	mm.instance_count = sitios.size()
	for i in sitios.size():
		mm.set_instance_transform(i, sitios[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = material
	_mundo.add_child(mi)
	return mi

func _nodo(padre: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	padre.add_child(n)
	return n

## Sube o baja lo que brilla un ascua: el parámetro de la biblioteca o, si ha
## entrado la de reserva, la emisión de un material liso.
func _encender(material: Material, energia: float, parametro: String = "energia") -> void:
	var sombreado := material as ShaderMaterial
	if sombreado != null:
		sombreado.set_shader_parameter(parametro, energia)
		return
	var liso := material as BaseMaterial3D
	if liso != null:
		liso.emission_energy_multiplier = energia

func _mas_cercano(lista: Array[Dictionary], punto: Vector2) -> int:
	var mejor := -1
	var dist := INF
	for i in lista.size():
		var d: float = (lista[i]["centro"] as Vector2).distance_squared_to(punto)
		if d < dist:
			dist = d
			mejor = i
	return mejor

## ESTIRA una malla a lo largo de su x solo en el tramo [x0, x1]: lo de antes
## se queda, lo de después se corre `extra`. Así una pala o una lápida cambian
## de largo sin que se deformen sus puntas redondas. `lateral` escala la z (el
## grueso). Las normales casi no cambian: el tramo es de sección constante.
static func _estirar(malla: Mesh, x0: float, x1: float, extra: float, lateral: float = 1.0) -> Mesh:
	if absf(extra) < 0.0005 and absf(lateral - 1.0) < 0.001:
		return malla
	var salida := ArrayMesh.new()
	for s in malla.get_surface_count():
		var arrays := malla.surface_get_arrays(s)
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in v.size():
			var p := v[i]
			if p.x > x1:
				p.x += extra
			elif p.x > x0:
				p.x += extra * (p.x - x0) / (x1 - x0)
			p.z *= lateral
			v[i] = p
		arrays[Mesh.ARRAY_VERTEX] = v
		salida.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return salida

## Una base que pone la x local a lo largo de `a_lo_largo` y la z local hacia
## `frente`, con la y arriba. Si la x pedida no deja la z hacia el frente, se
## da la vuelta.
static func _base_mirando(a_lo_largo: Vector2, frente: Vector2) -> Basis:
	var x := Vector3(a_lo_largo.x, 0.0, a_lo_largo.y).normalized()
	var z := x.cross(Vector3.UP)
	if z.dot(Vector3(frente.x, 0.0, frente.y)) < 0.0:
		x = -x
		z = -z
	return Basis(x, Vector3.UP, z)

# -------------------------------------------------------------------- braseros

func _montar_braseros() -> void:
	if _mesa.bumpers.is_empty():
		return
	var k := _mesa.p.bumper_radio * E / R_BUMPER
	# LA RUEDA ES HIERRO CON ÓXIDO EN LO HONDO, no óxido entero. Con el material
	# «oxido» salía rosa salmón parejo, como de barro cocido (revisión de arte,
	# 02_braseros_golpe). El hierro de la biblioteca ya pinta su suciedad en
	# COBRE_1 —herrumbre— en los huecos que hornea el color de vértice (entre
	# dientes, en los aligeramientos y abajo): con mucha suciedad, el óxido va
	# donde va en el sprite y el filo de cada diente queda pelado y claro.
	var oxido := _mat("hierro", {"local": true, "escala": 0.12, "suciedad": 0.95, "desgaste": 0.8})
	var hierro := _mat("hierro", {"local": true, "escala": 0.16})
	var bronce := _mat("bronce", {"local": true, "escala": 0.14})
	var medio := Vector2.ZERO
	for i in _mesa.bumpers.size():
		var centro: Vector2 = _mesa.bumpers[i]
		medio += centro
		var raiz := _nodo(_mundo, _mundo.a3(centro, _mundo.altura_en(centro)))
		raiz.scale = Vector3.ONE * k
		# La rueda, cuya punta de diente es el colisionador: gira un diente por golpe.
		var rueda := _pieza(raiz, _malla("brasero_engranaje"), oxido)
		var giro := float(i) * 0.9 + 0.2
		rueda.rotation.y = giro
		# La corona: aro, bocel y brasas. Es la que salta. Lo de encima de la
		# rueda no hace sombra: la sombra que cuenta es la de la rueda, y el aro y
		# el bocel la repetían por dentro de ella (peso, decisión 7).
		var corona := _nodo(raiz, Vector3.ZERO)
		_pieza(corona, _malla("brasero_corona"), hierro, false)
		_menudo(_pieza(corona, _malla("brasero_bocel"), bronce, false))
		var ascua := _propio("ascua", {"local": true, "escala": 0.12, "semilla": float(i) * 2.3})
		_pieza(corona, _malla("brasero_brasas"), ascua, false)
		corona.rotation.y = -giro * 1.7
		_encender(ascua, ASCUA_REPOSO)
		var llama := _llamarada(raiz, float(i))
		_braseros.append({"centro": centro, "rueda": rueda, "corona": corona, "ascua": ascua,
			"flash": 0.0, "giro": giro, "meta": giro, "llama": llama})
	medio /= float(_mesa.bumpers.size())
	_luz_braseros = _mundo.luz_fuego(_mundo.a3(medio, Y_LUZ_BRASEROS) + Vector3(0.0, 0.0, ADELANTO_LUZ),
		LUZ_BRASEROS, ALCANCE_BRASEROS)

## LA LLAMA del cuenco: pequeña y quieta en reposo (`FUERZA_REPOSO`), y al golpe
## una lengua que sube por encima de las lápidas. Ver `piezas_llamarada.gdshader`.
## Va colgada de la raíz del brasero (escalada con él).
func _llamarada(raiz: Node3D, i: float) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	# El pie del cartel en el origen: la llama nace en la boca del cuenco.
	quad.center_offset = Vector3(0.0, 0.5, 0.0)
	var m := ShaderMaterial.new()
	m.shader = LLAMARADA
	m.set_shader_parameter("color_nucleo", Paleta.ORO_CLARO.lerp(Paleta.BLANCO, 0.45))
	m.set_shader_parameter("color_llama", Paleta.NARANJA)
	m.set_shader_parameter("color_borde", Paleta.ROJO_LUZ)
	m.set_shader_parameter("semilla", i * 7.3)
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.layers = Nucleo.CAPA_SIN_REFLEJO
	# El cartel es de 1 × 1: lo que mide lo pone `actualizar` con la escala. Su
	# caja se agranda para que no se recorte por la vista cuando se estira.
	mi.custom_aabb = AABB(Vector3(-0.5, 0.0, -0.5), Vector3(1.0, 1.0, 1.0))
	mi.position = Vector3(0.0, Y_BOCA_BRASERO, 0.0)
	mi.scale = Vector3(ANCHO_REPOSO, ALTO_REPOSO, 1.0)
	m.set_shader_parameter("fuerza", FUERZA_REPOSO)
	m.set_shader_parameter("brillo", BRILLO_REPOSO)
	raiz.add_child(mi)
	return mi

## Lo pequeño: ni sombra ni reflejo (decisión 7 de la revisión). En la cámara de
## juego mide unos pocos píxeles y en un navegador cada llamada de dibujo cuesta.
func _menudo(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.layers = Nucleo.CAPA_SIN_REFLEJO
	return mi

func _al_golpear_brasero(punto: Vector2, _fuerza: float) -> void:
	var mejor := _mas_cercano(_braseros, punto)
	if mejor < 0:
		return
	var s := _braseros[mejor]
	s["flash"] = 1.0
	s["arde"] = 1.0
	# Cada golpe la hace girar un diente: es una rueda, y se tiene que notar.
	s["meta"] = float(s["meta"]) + TAU / float(DIENTES)
	_mundo.avivar(_luz_braseros, 1.0)

# ------------------------------------------------------------------ las hondas

func _montar_gomas() -> void:
	# LAS HONDAS NO PUEDEN LLAMAR MÁS QUE LAS PALAS. Con la goma roja entera
	# alrededor de los tres postes eran cuatro triángulos con contorno rojo, más
	# vistosos que las palas, que son lo que se mira (revisión de juego,
	# z_cenital_zonas). Ahora el rojo va SOLO en la cara de golpe —la goma tensa
	# entre los dos postes de delante— y más apagado y mate que el de las palas;
	# el resto del lazo es goma negra, como la de la pala.
	var goma := _mat("goma", {"local": true, "escala": 0.15, "tinte": Color(0.74, 0.66, 0.64),
		"rugosidad": 1.35})
	var goma_negra := _mat("goma", {"local": true, "escala": 0.15, "tinte": Color(0.2, 0.18, 0.18)})
	var hierro := _mat("hierro", {"escala": 0.2})
	var poste := _malla("goma_poste")
	var placas := SurfaceTool.new()
	placas.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Los postes son seis iguales y no se mueven: van en un MultiMesh.
	var sitios: Array[Transform3D] = []
	var hay := false
	for c in _mesa.colisionadores:
		if c.tipo != Colisionador.Tipo.SLINGSHOT:
			continue
		hay = true
		var cara := c.cara.normalized()
		var dir := (c.b - c.a).normalized()
		var lejos := HONDA_POSTE + HONDA_BANDA
		# Los dos postes de la banda, metidos lo justo para que el FRENTE de la
		# goma caiga en la línea a→b del colisionador; el tercero, detrás.
		var pa: Vector2 = c.a + dir * lejos - cara * lejos
		var pb: Vector2 = c.b - dir * lejos - cara * lejos
		var pc: Vector2 = (c.a + c.b) * 0.5 - cara * (HONDA_FONDO + lejos)
		var postes := PackedVector2Array([pa, pb, pc])
		for pt in postes:
			sitios.append(Transform3D(Basis(Vector3.UP, pt.x * 3.1), _mundo.a3(pt, 0.0)))
		# La placa de abajo y la de arriba, un poco más anchas que el triángulo.
		var tri := _crecer(postes, HONDA_POSTE + HONDA_BANDA * 0.5)
		_losa(placas, tri, 0.0, 0.012, 0.004)
		_losa(placas, _crecer(postes, HONDA_POSTE + 1.2), 0.146, 0.166, 0.007)
		var nodo := MeshInstance3D.new()
		nodo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mundo.add_child(nodo)
		var g := {"centro": c.centro(), "nodo": nodo, "flash": 0.0, "postes": postes,
			"cara": cara, "dibujado": -1.0, "roja": goma, "negra": goma_negra}
		_gomas.append(g)
		_dibujar_banda(g, 0.0)
	if hay:
		_menudo(_multi(poste, hierro, sitios))
		placas.generate_normals()
		var mi := MeshInstance3D.new()
		mi.mesh = placas.commit()
		mi.material_override = hierro
		_menudo(mi)
		_mundo.add_child(mi)

## Un triángulo agrandado `d` px hacia fuera de su centro.
static func _crecer(pts: PackedVector2Array, d: float) -> PackedVector2Array:
	var c := Vector2.ZERO
	for p in pts:
		c += p
	c /= float(pts.size())
	var salida := PackedVector2Array()
	for p in pts:
		salida.append(p + (p - c).normalized() * d)
	return salida

## Una losa con el canto de arriba biselado y el color de vértice de la
## convención (R oclusión, G canto). Para las placas de la honda.
func _losa(st: SurfaceTool, poli: PackedVector2Array, y0: float, y1: float, bisel: float) -> void:
	var c := Vector2.ZERO
	for p in poli:
		c += p
	c /= float(poli.size())
	var n := poli.size()
	var dentro := PackedVector2Array()
	for p in poli:
		dentro.append(p + (c - p).normalized() * bisel / E)
	var ym := y1 - bisel
	var lado := Color(0.6, 0.15, 0.0)
	var filo := Color(1.0, 1.0, 0.0)
	var tapa := Color(1.0, 0.1, 0.0)
	for i in n:
		var j := (i + 1) % n
		var medio := (poli[i] + poli[j]) * 0.5 - c
		var fuera := Vector3(medio.x, 0.0, medio.y).normalized()
		var p0 := _mundo.a3(poli[i], y0)
		var p1 := _mundo.a3(poli[j], y0)
		var p2 := _mundo.a3(poli[j], ym)
		var p3 := _mundo.a3(poli[i], ym)
		_tri(st, [p0, p1, p2], [lado, lado, filo], fuera)
		_tri(st, [p0, p2, p3], [lado, filo, filo], fuera)
		var q2 := _mundo.a3(dentro[j], y1)
		var q3 := _mundo.a3(dentro[i], y1)
		var sesgo := fuera + Vector3.UP
		_tri(st, [p3, p2, q2], [filo, filo, tapa], sesgo)
		_tri(st, [p3, q2, q3], [filo, tapa, tapa], sesgo)
	for i in range(1, n - 1):
		_tri(st, [_mundo.a3(dentro[0], y1), _mundo.a3(dentro[i], y1), _mundo.a3(dentro[i + 1], y1)],
			[tapa, tapa, tapa], Vector3.UP)

## Un triángulo con la cara hacia `hacia` (o hacia fuera del eje vertical de la
## pieza si no se dice): Godot ve la cara en sentido horario.
static func _tri(st: SurfaceTool, p: Array, col: Array, hacia: Vector3 = Vector3.ZERO) -> void:
	var a: Vector3 = p[0]
	var b: Vector3 = p[1]
	var c: Vector3 = p[2]
	var n := (b - a).cross(c - a)
	var quiero := hacia
	if quiero == Vector3.ZERO:
		quiero = Vector3((a.x + b.x + c.x) / 3.0, 0.0, (a.z + b.z + c.z) / 3.0)
	var ca: Color = col[0]
	var cb: Color = col[1]
	var cc: Color = col[2]
	if n.dot(quiero) > 0.0:
		var t := b
		b = c
		c = t
		var tc := cb
		cb = cc
		cc = tc
	st.set_color(ca)
	st.add_vertex(a)
	st.set_color(cb)
	st.add_vertex(b)
	st.set_color(cc)
	st.add_vertex(c)

## LA BANDA de la honda: un lazo alrededor de los tres postes, con la sección
## redondeada. El tramo de delante (de pa a pb) se abomba hacia `cara` con la
## patada. Se rehace solo mientras se mueve.
func _dibujar_banda(g: Dictionary, patada: float) -> void:
	if absf(patada - float(g["dibujado"])) < 0.002:
		return
	g["dibujado"] = patada
	var postes: PackedVector2Array = g["postes"]
	var cara: Vector2 = g["cara"]
	var r := HONDA_POSTE + HONDA_BANDA * 0.5
	# El lazo: arco alrededor de cada poste y tramo recto hasta el siguiente.
	# El triángulo es convexo, así que cada arco es el giro corto entre la
	# normal del tramo que llega y la del que sale, en el sentido que sea.
	var orden := [0, 1, 2]
	var c := (postes[0] + postes[1] + postes[2]) / 3.0
	var camino := PackedVector2Array()
	var tramo_frente := PackedInt32Array()
	for k in 3:
		var i: int = orden[k]
		var j: int = orden[(k + 1) % 3]
		var h: int = orden[(k + 2) % 3]
		var p := postes[i]
		var q := postes[j]
		var prev := postes[h]
		var n_entra := _normal_fuera(prev, p, c)
		var n_sale := _normal_fuera(p, q, c)
		var a0 := n_entra.angle()
		var a1 := n_sale.angle()
		var da := wrapf(a1 - a0, -PI, PI)
		var pasos := 7
		for s in pasos + 1:
			var ang := a0 + da * float(s) / float(pasos)
			camino.append(p + Vector2(cos(ang), sin(ang)) * r)
			tramo_frente.append(-1)
		# El tramo recto hasta el siguiente poste. Si es el de delante (de pa
		# a pb o al revés), lleva la patada.
		var frente := (i == 0 and j == 1) or (i == 1 and j == 0)
		var desde := p + n_sale * r
		var hasta := q + n_sale * r
		var trozos := 10 if frente else 2
		for s in range(1, trozos):
			var t := float(s) / float(trozos)
			var pt := desde.lerp(hasta, t)
			if frente:
				pt += cara * patada * sin(PI * t)
			camino.append(pt)
			tramo_frente.append(1 if frente else -1)
	# Dos superficies: la cara de golpe (roja) y el resto del lazo (negro).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_negra := SurfaceTool.new()
	st_negra.begin(Mesh.PRIMITIVE_TRIANGLES)
	# La sección: un rectángulo de esquinas romas, de HONDA_BANDA de grueso.
	var perfil: Array[Vector2] = []    # (fuera, alto) relativos
	var colores: Array[Color] = []
	var media := HONDA_BANDA * 0.5 * E
	var y0 := HONDA_Y.x
	var y1 := HONDA_Y.y
	var romo := 0.009
	for esquina: Array in [[media - romo, y0 + romo, -90.0], [media - romo, y1 - romo, 0.0],
			[-media + romo, y1 - romo, 90.0], [-media + romo, y0 + romo, 180.0]]:
		for s in 4:
			var ang := deg_to_rad(float(esquina[2]) + 30.0 * float(s))
			perfil.append(Vector2(float(esquina[0]) + cos(ang) * romo, float(esquina[1]) + sin(ang) * romo))
			var alto := (perfil[-1].y - y0) / (y1 - y0)
			colores.append(Color(0.55 + 0.45 * alto, 0.6 if s == 1 or s == 2 else 0.2, 0.0))
	var m := camino.size()
	var np := perfil.size()
	var anillos: Array[PackedVector3Array] = []
	var normales: Array[PackedVector3Array] = []
	for i in m:
		var antes := camino[(i - 1 + m) % m]
		var despues := camino[(i + 1) % m]
		var tg := (despues - antes).normalized()
		var fuera := Vector2(tg.y, -tg.x)
		if fuera.dot(camino[i] - c) < 0.0:
			fuera = -fuera
		var anillo := PackedVector3Array()
		var nrm := PackedVector3Array()
		for k in np:
			var pr := perfil[k]
			var base := camino[i] * E + fuera * pr.x
			anillo.append(Vector3(base.x, pr.y, base.y))
			var mid := Vector2(0.0, (y0 + y1) * 0.5)
			var dn := (pr - mid)
			dn.y *= 2.5
			dn = dn.normalized()
			nrm.append(Vector3(fuera.x * dn.x, dn.y, fuera.y * dn.x).normalized())
		anillos.append(anillo)
		normales.append(nrm)
	for i in m:
		var a := anillos[i]
		var b := anillos[(i + 1) % m]
		var na := normales[i]
		var nb := normales[(i + 1) % m]
		# Es de la cara de golpe el tramo que toca algún punto del recto de delante.
		var roja := tramo_frente[i] == 1 or tramo_frente[(i + 1) % m] == 1
		var dst := st if roja else st_negra
		for k in np:
			var k2 := (k + 1) % np
			var cara_n := (na[k] + na[k2] + nb[k] + nb[k2])
			_tri_n(dst, a[k], a[k2], b[k2], na[k], na[k2], nb[k2], colores[k], colores[k2], colores[k2], cara_n)
			_tri_n(dst, a[k], b[k2], b[k], na[k], nb[k2], nb[k], colores[k], colores[k2], colores[k], cara_n)
	var malla := st.commit()
	st_negra.commit(malla)
	malla.surface_set_material(0, g["roja"] as Material)
	malla.surface_set_material(1, g["negra"] as Material)
	(g["nodo"] as MeshInstance3D).mesh = malla

static func _normal_fuera(p: Vector2, q: Vector2, centro: Vector2) -> Vector2:
	var d := (q - p).normalized()
	var n := Vector2(-d.y, d.x)
	if n.dot((p + q) * 0.5 - centro) < 0.0:
		n = -n
	return n

static func _tri_n(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		na: Vector3, nb: Vector3, nc: Vector3, ca: Color, cb: Color, cc: Color, hacia: Vector3) -> void:
	if (b - a).cross(c - a).dot(hacia) > 0.0:
		var t := b
		b = c
		c = t
		var tn := nb
		nb = nc
		nc = tn
		var tc := cb
		cb = cc
		cc = tc
	st.set_color(ca)
	st.set_normal(na)
	st.add_vertex(a)
	st.set_color(cb)
	st.set_normal(nb)
	st.add_vertex(b)
	st.set_color(cc)
	st.set_normal(nc)
	st.add_vertex(c)

func _al_golpear_goma(punto: Vector2, _fuerza: float) -> void:
	var mejor := _mas_cercano(_gomas, punto)
	if mejor >= 0:
		_gomas[mejor]["flash"] = 1.0

# ---------------------------------------------------------------------- postes

func _montar_postes() -> void:
	if _mesa.postes.is_empty():
		return
	var k := _mesa.p.poste_radio * E / R_POSTE
	var piedra := _mat("piedra", {"escala": 0.18})
	var goma := _mat("goma", {"local": true, "escala": 0.15})
	var hierro := _mat("hierro", {"escala": 0.16})
	for centro in _mesa.postes:
		var raiz := _nodo(_mundo, _mundo.a3(centro, _mundo.altura_en(centro)))
		raiz.scale = Vector3.ONE * k
		raiz.rotation.y = centro.x * 0.37
		_pieza(raiz, _malla("poste_cuerpo"), piedra)
		_menudo(_pieza(raiz, _malla("poste_tapa"), hierro))
		var aro := _pieza(raiz, _malla("poste_goma"), goma)
		_postes.append({"centro": centro, "aro": aro, "flash": 0.0})

func _al_golpear_poste(punto: Vector2, _fuerza: float) -> void:
	var mejor := _mas_cercano(_postes, punto)
	if mejor >= 0:
		_postes[mejor]["flash"] = 1.0

# ---------------------------------------------------------------------- lápidas

func _montar_lapidas() -> void:
	if _mesa.targets.is_empty():
		return
	# La mesa dice qué es cada banco en `info_bancos`: las LÁPIDAS son de piedra
	# y los ESCUDOS, de madera con herrajes. Lo que no diga, lápida.
	var info: Array = _mesa.info_bancos if "info_bancos" in _mesa else []
	var hierro := _mat("hierro", {"escala": 0.18})
	var cache := {}
	# Las ranuras del suelo, fijas e iguales: un MultiMesh.
	var ranuras: Array[Transform3D] = []
	for i in _mesa.targets.size():
		var c: Colisionador = _mesa.targets[i]
		var clave := "targets"
		var cara := Vector2.DOWN
		if c.banco >= 0 and c.banco < info.size():
			var datos := info[c.banco] as Dictionary
			clave = str(datos.get("clave", "targets"))
			cara = datos.get("cara", Vector2.DOWN)
		var escudo := clave == "escudos"
		var a_lo_largo := c.b - c.a
		if a_lo_largo.length_squared() < 0.01:
			a_lo_largo = Vector2(-cara.y, cara.x)
		var largo := (c.b - c.a).length() * E + 2.0 * c.radio * E
		var grueso := c.radio * E / R_TARGET
		var centro := (c.a + c.b) * 0.5
		var suelo := _mundo.altura_en(centro)
		# La ranura del suelo, fija: es por donde se hunde.
		ranuras.append(Transform3D(_base_mirando(a_lo_largo, cara).scaled_local(
			Vector3(largo / L_TARGET, 1.0, grueso)), _mundo.a3(centro, suelo)))
		var raiz := _nodo(_mundo, _mundo.a3(centro, suelo))
		raiz.basis = _base_mirando(a_lo_largo, cara)
		# El que se mueve es `cuerpo`: baja y se echa atrás sobre su pie.
		var cuerpo := _nodo(raiz, Vector3.ZERO)
		var partes: Array[MeshInstance3D] = []
		# Sin ternario: un ternario deja el Array sin tipo y no entra en Array[String].
		var nombres: Array[String] = ["lapida"]
		if escudo:
			nombres = ["escudo_madera", "escudo_herraje"]
		for nombre in nombres:
			var llave := "%s|%.3f|%.3f" % [nombre, largo, grueso]
			if not cache.has(llave):
				cache[llave] = _estirar(_malla(nombre), -TRAMO_TARGET, TRAMO_TARGET, largo - L_TARGET, grueso)
			var material: Material
			# LOS ESCUDOS NO SE LEÍAN: negros bajo los raíles (gira2/piezas/
			# 05_escudos). El roble, más claro (el TIERRA_3 del sprite); el
			# herraje, con el filo pelado hasta el gris claro, que es lo que coge
			# un brillo de cualquier luz. La forma (bandas en tejadillo, bloca
			# abombada, la cara echada atrás) está en el guion de Blender.
			match nombre:
				"escudo_madera":
					material = _mat("madera", {"local": true, "escala": 0.32, "veta": Vector3.UP,
						"semilla": float(i) * 1.9, "tinte": Color(1.45, 1.3, 1.2)})
				"escudo_herraje":
					material = _mat("hierro", {"local": true, "escala": 0.16, "desgaste": 0.95,
						"tinte": Color(1.35, 1.35, 1.4)})
				_:
					material = _mat("piedra", {"local": true, "escala": 0.26, "semilla": float(i) * 3.3})
			partes.append(_pieza(cuerpo, cache[llave] as Mesh, material))
		var alto := 0.0
		for mi in partes:
			alto = maxf(alto, mi.get_aabb().end.y)
		_lapidas.append({"cuerpo": cuerpo, "partes": partes, "hundir": alto + 0.006,
			"bajada": 0.0, "suelo": suelo})
	var mm := _multi(_malla("lapida_ranura"), hierro, ranuras)
	mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# A ras de suelo: su reflejo caería encima de sí misma.
	mm.layers = Nucleo.CAPA_SIN_REFLEJO

# ------------------------------------------------------------------------ palas

func _montar_palas() -> void:
	# El hierro de la pala, con el filo muy pelado: desde arriba (la CENITAL) la
	# hoja negra sobre la losa oscura no se separaba del suelo; es el filo claro
	# de la tapa el que dibuja la lágrima.
	var hierro := _mat("hierro", {"local": true, "escala": 0.3, "relieve": 0.7, "desgaste": 0.95})
	# La goma, negra de verdad: es la tapa de hierro la que dibuja la lágrima, y
	# una goma parda alrededor la volvía a convertir en barra. (El rojo que se ve
	# en el eje es el aro del poste que hay encima, y se queda.)
	var goma := _mat("goma", {"local": true, "escala": 0.2, "tinte": Color(0.12, 0.11, 0.11)})
	var acero := _mat("acero", {"local": true, "escala": 0.2})
	for f in _mesa.flippers:
		var arriba := f.capas == Colisionador.bit(Mesa.CAPA_ALTA)
		var raiz := _nodo(_mundo, _mundo.a3(f.eje, Nucleo.H_ALTA if arriba else 0.0))
		var extra := f.longitud * E - L_PALA
		var lateral := f.radio * E / R_PALA
		for par: Array in [["pala_cuerpo", hierro], ["pala_goma", goma], ["pala_acero", acero]]:
			var malla := _estirar(_malla(str(par[0])), TRAMO_PALA.x, TRAMO_PALA.y, extra, lateral)
			# El acero va encima de la tapa: sombra no (cae dentro de la de la
			# pala), pero reflejo sí, que es el brillo de la pala en el charco.
			_pieza(raiz, malla, par[1] as Material, str(par[0]) != "pala_acero")
		raiz.rotation.y = -f.angulo
		# LA ESTELA: un abanico de humo de hierro entre donde estaba la pala hace
		# un instante y donde está. Es lo que hace que el golpe se VEA: la pala
		# barre su recorrido en tres cuadros y, sin estela, salta.
		var estela := MeshInstance3D.new()
		estela.mesh = ImmediateMesh.new()
		var m := ShaderMaterial.new()
		m.shader = ESTELA
		estela.material_override = m
		estela.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		estela.layers = Nucleo.CAPA_SIN_REFLEJO
		estela.position = raiz.position
		_mundo.add_child(estela)
		_palas.append({"raiz": raiz, "estela": estela, "lag": f.angulo,
			"largo": f.longitud * E + f.radio * E, "r": f.radio * E})

## El abanico de la estela, de `desde` a `hasta` (ángulos de la mesa).
func _dibujar_estela(s: Dictionary, desde: float, hasta: float) -> void:
	var im := (s["estela"] as MeshInstance3D).mesh as ImmediateMesh
	im.clear_surfaces()
	var barrido := absf(hasta - desde)
	if barrido < 0.06:
		return
	var largo: float = s["largo"]
	var pasos := clampi(int(barrido / 0.08) + 2, 3, 16)
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in pasos:
		var t0 := float(k) / float(pasos)
		var t1 := float(k + 1) / float(pasos)
		var a0 := lerpf(desde, hasta, t0)
		var a1 := lerpf(desde, hasta, t1)
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		# UV.x: de la cola (0) a donde está la pala (1). UV.y: del eje (0) a la
		# punta (1). La altura, la de la cara de arriba de la pala.
		for v: Array in [[d0, t0, 0.18], [d1, t1, 0.18], [d1, t1, 1.0],
				[d0, t0, 0.18], [d1, t1, 1.0], [d0, t0, 1.0]]:
			var dir: Vector3 = v[0]
			im.surface_set_uv(Vector2(float(v[1]), float(v[2])))
			im.surface_add_vertex(dir * largo * float(v[2]) + Vector3.UP * 0.13)
	im.surface_end()

# ------------------------------------------------------------------------ torno

func _montar_tornos() -> void:
	if _mesa.giradores.is_empty():
		return
	var k := _mesa.p.girador_radio * E / R_TORNO
	var hierro_suelto := _mat("hierro", {"local": true, "escala": 0.14})
	var hierro := _mat("hierro", {"escala": 0.16})
	var acero := _mat("acero", {"escala": 0.2})
	# La mesa dice hacia dónde va el eje de cada uno; si no lo dice, a lo ancho.
	var info: Array = _mesa.info_tornos if "info_tornos" in _mesa else []
	for i in _mesa.giradores.size():
		var centro: Vector2 = _mesa.giradores[i]
		var eje := Vector2.RIGHT
		if i < info.size():
			var pedido: Vector2 = (info[i] as Dictionary).get("eje", Vector2.RIGHT)
			if pedido.length_squared() > 0.0001:
				eje = pedido.normalized()
		# Dos nodos: el de fuera orienta el eje y el de dentro da vueltas sobre él.
		var orientado := _nodo(_mundo, _mundo.a3(centro, _mundo.altura_en(centro)))
		orientado.rotation.y = -eje.angle()
		orientado.scale = Vector3.ONE * k
		# El torno es menudo (20 px): ni sombra ni reflejo, salvo la chapa, que
		# es lo que se ve girar.
		_menudo(_pieza(orientado, _malla("torno_soportes"), hierro))
		_menudo(_pieza(orientado, _malla("torno_eje"), acero))
		var pivote := _nodo(orientado, Vector3(0.0, Y_EJE_TORNO, 0.0))
		pivote.rotation.x = float(i) * 0.7
		_pieza(pivote, _malla("torno_aspa"), hierro_suelto, false)
		_tornos.append({"nodo": pivote, "vel": 0.0})

func _al_girar_torno(_punto: Vector2, indice: int, fuerza: float) -> void:
	if indice >= 0 and indice < _tornos.size():
		_tornos[indice]["vel"] = clampf(fuerza * 0.06, 14.0, 70.0)

# -------------------------------------------------------------------- sarcófago

func _montar_sarcofagos() -> void:
	var piedra := _mat("piedra", {"escala": 0.22})
	# Hueso viejo y sucio, más oscuro que el de la biblioteca: está a un palmo de
	# la luz del rescoldo y con el tono de serie salía quemado a blanco
	# (gira de esta tanda, 06_sarcofago_con_bola).
	var hueso := _mat("hueso", {"escala": 0.12, "tinte": Color(0.62, 0.56, 0.5)})
	for i in _mesa.platillos.size():
		var pl := _mesa.platillos[i]
		var altura := _mundo.altura_en(pl.centro)
		var k := pl.radio * E / R_PLATILLO
		# La cabecera mira al revés de por donde escupe: la bola sale por los pies.
		var sale := pl.direccion.normalized() if pl.direccion.length_squared() > 0.0001 else Vector2.DOWN
		var z := -Vector3(sale.x, 0.0, sale.y)
		var x := Vector3.UP.cross(z).normalized()
		var raiz := _nodo(_mundo, _mundo.a3(pl.centro, altura))
		raiz.basis = Basis(x, Vector3.UP, z).scaled(Vector3.ONE * k)
		# El brocal va a ras del suelo del coro: su sombra no se ve.
		_pieza(raiz, _malla("sarcofago_brocal"), piedra, false)
		# CARBÓN MATE. Con la rugosidad del carbón de la biblioteca (0,65), el
		# fondo era un espejo negro que recogía las llamas de alrededor: «negro
		# brillante», dijo la revisión. Ceniza y rescoldo no brillan.
		var fondo_mat := _propio("carbon", {"escala": 0.1, "emision": 1.2, "rugosidad": 1.45})
		# Además del fuego de las grietas, un resplandor parejo donde el azul
		# del modelo dice que hay rescoldo (el centro y la cabecera).
		_encender(fondo_mat, 0.3, "emision")
		_pieza(raiz, _malla("sarcofago_fondo"), fondo_mat, false)
		_pieza(raiz, _malla("sarcofago_huesos"), hueso, false)
		# La tapa, de pie y apoyada en el rincón de detrás de la cabecera: su
		# pie posa en el suelo a TAPA_PIE px del centro y se echa hacia atrás.
		var giro := Basis(Vector3.RIGHT, -deg_to_rad(TAPA_INCLINA))
		var pie_local := Vector3(0.0, 0.0, -0.215)
		var tapa := _pieza(raiz, _malla("sarcofago_tapa"), piedra)
		tapa.basis = giro
		tapa.position = Vector3(0.0, 0.0, TAPA_PIE * E / k) - giro * pie_local
		var luz := _mundo.luz_fuego(_mundo.a3(pl.centro, altura + 0.4), 0.55, 1.6)
		_sarcofagos.append({"centro": pl.centro, "altura": altura, "fondo": fondo_mat,
			"luz": luz, "activo": 0.0, "escupe": 0.0})

func _al_tragar(_punto: Vector2, indice: int) -> void:
	if indice < 0 or indice >= _sarcofagos.size():
		return
	_sarcofagos[indice]["activo"] = 1.0
	# Un avivón corto: con 0,6 la luz subía a 3,4 veces su reposo a un palmo de
	# la bocanada de polvo de «efectos» y la quemaba a blanco.
	_mundo.avivar(_sarcofagos[indice]["luz"] as OmniLight3D, 0.3)

## AL ESCUPIR: polvo de piedra, unas chispas del rescoldo y el fogonazo.
func _al_escupir(punto: Vector2, indice: int) -> void:
	if indice < 0 or indice >= _sarcofagos.size():
		return
	var s := _sarcofagos[indice]
	s["escupe"] = 1.0
	var altura: float = s["altura"]
	# El polvo, de piedra OSCURA y poco: con PIEDRA_4 y catorce motas, a un palmo
	# de la luz del sarcófago avivada, la bocanada salía como una mancha blanca
	# quemada (gira2/piezas/06). Lo que tiene que brillar es el rescoldo.
	_mundo.chispear(punto, altura + 0.05, Paleta.PIEDRA_2, 8)
	_mundo.chispear(punto, altura + 0.06, Paleta.NARANJA, 8)
	_mundo.onda(s["centro"] as Vector2, altura + 0.02, Paleta.PIEDRA_2, 0.4)
	_mundo.avivar(s["luz"] as OmniLight3D, 1.0)
	_mundo.sacudida = maxf(_mundo.sacudida, 0.25)

# --------------------------------------------------------------------- lanzador

## El ariete asoma por el fondo del carril con la cara en el pie de la bola y
## retrocede al cargar, apretando el muelle contra el soporte, que no se mueve.
func _montar_lanzador() -> void:
	var p := _mesa.p
	var hierro := _mat("hierro", {"local": true, "escala": 0.14})
	var acero := _mat("acero", {"local": true, "escala": 0.2})
	var frente := (p.inicio_bola.y + p.radio_bola) * E
	var raiz := _nodo(_mundo, Vector3(p.inicio_bola.x * E, 0.0, frente))
	# Va metido en su carril, entre dos paredes: no hace sombra que se vea ni
	# tiene charco donde reflejarse.
	var cabeza := _nodo(raiz, Vector3.ZERO)
	_menudo(_pieza(cabeza, _malla("lanzador_cabeza"), hierro))
	_menudo(_pieza(cabeza, _malla("lanzador_vastago"), acero))
	var muelle := _nodo(raiz, Vector3(0.0, 0.0, FONDO_CABEZA))
	_menudo(_pieza(muelle, _malla("lanzador_muelle"), acero))
	var soporte := _nodo(raiz, Vector3(0.0, 0.0, FONDO_CABEZA + LARGO_MUELLE))
	_menudo(_pieza(soporte, _malla("lanzador_soporte"), hierro))
	_lanzador = {"cabeza": cabeza, "muelle": muelle}

# ------------------------------------------------------------------ cada cuadro

func actualizar(delta: float) -> void:
	for s in _braseros:
		var f: float = maxf(float(s["flash"]) - delta * 4.0, 0.0)
		s["flash"] = f
		var giro := lerpf(float(s["giro"]), float(s["meta"]), 1.0 - exp(-14.0 * delta))
		s["giro"] = giro
		(s["rueda"] as Node3D).rotation.y = giro
		# El aro salta de golpe y cae con un rebote: `f` va de 1 a 0, y el
		# salto es una parábola que acaba en un botecito.
		var corona: Node3D = s["corona"]
		var salto := sin(f * PI) * (0.55 + 0.45 * f)
		corona.position.y = SALTO_ARO * salto
		var ancho := 1.0 + 0.06 * f
		corona.scale = Vector3(ancho, 1.0, ancho)
		_encender(s["ascua"] as Material, ASCUA_REPOSO + f * ASCUA_GOLPE)
		# La llamarada: sale entera de golpe y se va comiendo por arriba hasta
		# volver a la llama de reposo, que no se apaga nunca.
		var antes: float = s.get("arde", 0.0)
		var l: float = maxf(antes - delta / DURA_LLAMARADA, 0.0)
		s["arde"] = l
		if l > 0.0 or antes > 0.0:
			var llama: MeshInstance3D = s["llama"]
			llama.scale = Vector3(lerpf(ANCHO_REPOSO, ANCHO_LLAMARADA * (0.8 + 0.2 * l), l),
				lerpf(ALTO_REPOSO, ALTO_LLAMARADA * (0.7 + 0.3 * l), l), 1.0)
			var sm := llama.material_override as ShaderMaterial
			sm.set_shader_parameter("fuerza", lerpf(FUERZA_REPOSO, 1.0, l))
			sm.set_shader_parameter("brillo", lerpf(BRILLO_REPOSO, BRILLO_GOLPE, l))

	for g in _gomas:
		var f: float = maxf(float(g["flash"]) - delta * 5.0, 0.0)
		g["flash"] = f
		# La patada: sale de golpe y vuelve con un rebote que se apaga.
		var patada := HONDA_PATADA * sin(f * PI * 2.5) * f
		_dibujar_banda(g, patada)

	for s in _postes:
		var f: float = maxf(float(s["flash"]) - delta * 6.0, 0.0)
		s["flash"] = f
		var aplasta := sin(f * PI * 2.0) * f * 0.08
		(s["aro"] as Node3D).scale = Vector3(1.0 + aplasta, 1.0 - aplasta * 1.5, 1.0 + aplasta)

	for i in _lapidas.size():
		var s := _lapidas[i]
		var hundir: float = s["hundir"]
		var meta := 0.0 if _mesa.targets[i].activo else 1.0
		# Cae deprisa (la tumba el golpe) y sube despacio (la levanta el mecanismo).
		var vel := 7.0 if meta > float(s["bajada"]) else 2.2
		var b := move_toward(float(s["bajada"]), meta, delta * vel)
		s["bajada"] = b
		var cuerpo: Node3D = s["cuerpo"]
		cuerpo.position.y = -hundir * b
		cuerpo.rotation.x = -0.35 * sin(b * PI * 0.5) * (1.0 - b * 0.6)
		# Hundida no puede estar en la capa del reflejo: ver el punto 5. Y del
		# todo abajo, ni se dibuja.
		var capa := 1 if b < 0.04 else Nucleo.CAPA_SIN_REFLEJO
		var visible := b < 0.995
		for mi: MeshInstance3D in s["partes"]:
			mi.layers = capa
			mi.visible = visible

	for i in _palas.size():
		var s := _palas[i]
		var ang := _mesa.flippers[i].angulo
		(s["raiz"] as Node3D).rotation.y = -ang
		var lag := lerpf(float(s["lag"]), ang, 1.0 - exp(-22.0 * delta))
		s["lag"] = lag
		_dibujar_estela(s, lag, ang)

	for t in _tornos:
		var v: float = t["vel"]
		(t["nodo"] as Node3D).rotation.x += v * delta
		t["vel"] = v * exp(-1.5 * delta)

	for s in _sarcofagos:
		var a: float = maxf(float(s["activo"]) - delta * 0.9, 0.0)
		s["activo"] = a
		var e: float = maxf(float(s["escupe"]) - delta * 3.0, 0.0)
		s["escupe"] = e
		_encender(s["fondo"] as Material, 1.2 + a * 3.0 + e * 6.0, "emision_grietas")
		_encender(s["fondo"] as Material, 0.3 + a * 0.9 + e * 2.2, "emision")

	if not _lanzador.is_empty():
		var atras := _mesa.carga_lanzador * RETRO_LANZADOR
		(_lanzador["cabeza"] as Node3D).position.z = atras
		var muelle: Node3D = _lanzador["muelle"]
		muelle.position.z = FONDO_CABEZA + atras
		muelle.scale.z = (LARGO_MUELLE - atras) / LARGO_MUELLE
