extends RefCounted

## CRIPTA 3D · MÓDULO «atrezzo» · LA CAMPANA Y EL FUEGO
##
## QUÉ MONTA (las piezas salen de `blender/atrezzo_modelos.py` →
## `modelos/atrezzo_piezas.glb`; de ahí solo se coge la MALLA y el material se
## pide a la biblioteca)
##   · LA CAMPANA MAYOR, colgada sobre los braseros: bronce viejo con tres
##     cenefas de filetes y ocho calaveras en relieve, su yugo de roble con
##     bridas y muñones, el badajo, y la viga con su travesaño y sus horquillas,
##     sostenida por dos cadenas que SUBEN HASTA LA BÓVEDA (`Nucleo.Y_BOVEDA`, o
##     el anclaje que publique «arquitectura»). Es la BARRA DE CARGA de la mesa.
##   · CUATRO ANTORCHAS de pared en el ábside (los `apoyos_antorcha` de
##     «arquitectura»): placa remachada, brazo con voluta, cesta de barras, el
##     trapo de brea ardiendo y su llama.
##   · DOS BRASEROS DE GARRA en las esquinas del fondo, sobre la albardilla,
##     delante de las columnas.
##   · DOS FAROLES colgados del fuste de las dos columnas del ábside, debajo del
##     capitel de calaveras: le dan motivo a la luz que saca los capiteles.
##   · UN FAROL EN SU PESCANTE sobre los ESCUDOS (el banco de la derecha), que
##     sale de la albardilla y vuela por encima de los raíles: los escudos
##     estaban a oscuras debajo de ellos.
##   · CUATRO CIRIOS en las albardillas, a los lados del fondo: son la carga de
##     la campana donde la cámara de juego SÍ mira (ver `_montar_cirios`).
##   · VELAS: racimos de cera con chorretones en las cuatro hornacinas y en la
##     cornisa, con calaveras.
##   · CADENAS con gancho colgando de las argollas del ábside, y dos más en la
##     sala, colgando de la bóveda.
##   · TRES GÁRGOLAS: el sprite `bumper_gargola` hecho mascarón de piedra, con
##     los ojos de ascua.
##   · LA SALA: dos braseros de pie y dos candelabros junto a los pilares,
##     barriles, cajas y montones de huesos. Y dos montones más en la albardilla.
##
## EL PESO (decisión 7 de la tanda de arreglos, 21-nov-2026). Este módulo ponía
## 342.000 triángulos de 612.000, 297.000 de ellos haciendo sombra, en adornos
## que miden 30 px en la cámara de juego. Ahora:
##   · las mallas del GLB van rebajadas a lo que se ve (ver el guion);
##   · NADA hace sombra salvo el bronce de la campana, y solo en ALTA: la única
##     sombra de fuego es la de un brasero del campo, que está debajo;
##   · al reflejo solo van la campana y su viga. NINGUNA LLAMA se refleja
##     (revisión 2, decisión 5): la de una antorcha del ábside caía con la
##     RASANTE en mitad del campo y era una bola falsa más clara que la bola;
##   · lo fijo se UNE por material y por celda (`_fijo` → `_volcar`): una malla
##     por material y por trozo de 2,4 unidades, no una por pieza. Por celdas y
##     no todo junto porque Compatibility aplica 8 luces por malla;
##   · lo repetido (velas, eslabones, charcos de cera, llamas) va en MultiMesh.
##   Con `--medir` imprime lo que pone: mallas, triángulos y cuántos en sombra y
##   en el reflejo.
##
## LAS LUCES: siete. Las dos antorchas del centro (alumbran el ábside por detrás
## de la campana y le sacan el canto), las dos de las esquinas (subidas entre
## el brasero de garra y el farol de la columna: alumbran las dos cosas y llegan
## al capitel), la del farol de los escudos y los dos braseros de pie de la sala.
## Las velas, las brasas y los ojos brillan con su material, sin luz propia.
##
## LAS VELAS DE LAS HORNACINAS van en el labio de la repisa, delante del plano
## del muro: metidas en el hueco, vistas de lado, la jamba les cortaba el costado
## y parecían clavadas en la piedra (`_montar_hornacinas_y_cornisa`).
##
## LA LLAMA es `atrezzo_llama.gdshader`: una lámina que mira a la cámara con un
## ruido que sube, la tuerce y la rompe en lenguas. Todas van en TRES MultiMesh
## (las grandes, las de las velas y faroles, y las de los cirios). LA LLAMA
## TIENE JERARQUÍA (decisión 4): la de los braseros del fondo manda, la de las
## antorchas del ábside va a la mitad, la de la sala más baja, y las velas son
## puntos.
##
## LA CAMPANA, que es mecánica y hay que conservarla entera:
##   mesa.carga (0..1)        toda entrada a una rampa tira de la cuerda. Aquí
##                            las cenefas se ENCIENDEN DE ABAJO ARRIBA (la del
##                            labio, la de la cintura, la del hombro) y la
##                            campana se va ladeando
##   mesa.descarga_armada     llena: queda armada hasta que se COMPLETE una
##                            rampa. Aquí se queda ladeada del todo, TIEMBLA y
##                            las tres cenefas laten EN ÁMBAR. El cuerpo sigue
##                            siendo bronce con pátina (revisión 2, decisión 4:
##                            «al rojo» se quemaba a latón pulido). Y en el
##                            CAMPO, bajo su vertical, respira un disco de polvo
##                            dorado con un aro que se cierra
##                            (`atrezzo_resplandor.gdshader`): con la bola abajo
##                            SEGUIMIENTO no ve la campana, y armada es lo que le
##                            pide algo al jugador
##   mesa.descarga_restante   segundos que le quedan TOCANDO. Aquí VOLTEA como un
##                            péndulo de verdad (al que alguien tira de la
##                            cuerda), el badajo GOLPEA el labio, y cada golpe
##                            suelta polvo, una ONDA DE POLVO DORADO A RAS DE
##                            SUELO que cruza el campo desde la vertical de la
##                            campana, y aviva el fuego. Mientras toca, los
##                            fuegos DEL CAMPO arden avivados (decisión 9: la
##                            campana se tiene que notar donde se juega)
##   Y con cada golpe de búmper tiembla un poco. Si la mesa tuviera la carga
##   apagada (`p.carga_entradas` enorme, como en ÓRBITA), la campana se carga
##   ella sola con los golpes de búmper (`GOLPES_SIN_CARGA`) y toca igual.
##
## SEÑALES QUE ESCUCHA
##   descarga_empezada   el tirón: la campana arranca a voltear
##   carga_cambiada      un destello en las cenefas cuando sube la carga
##   bumper_golpeado     un temblor (y, sin carga en la mesa, la cuenta)
##   El ESTADO (cargando, armada, tocando) no se guarda: se lee de la mesa en
##   cada cuadro, que es lo que impide que la campana se quede puesta en un
##   estado que ya no es (la mesa la desarma al servir bola).
## FUNCIONES PÚBLICAS
##   calidad(n)          0 ALTA, 1 MEDIA, 2 BAJA (la llama el núcleo). En MEDIA
##                       la campana deja de hacer sombra; en BAJA, además, se
##                       apaga lo menudo de la sala (barriles, cajas, huesos y
##                       cadenas de la nave), que está en la niebla.
##
## LO QUE NO PUEDE DEJAR DE HACER QUIEN LO REESCRIBA
##   1. `montar(mundo)` y `actualizar(delta)`.
##   2. LA CAMPANA SE TIENE QUE LEER DESDE LA CÁMARA DE JUEGO en sus tres
##      estados —cargando, armada, tocando— sin mirar el marcador. Un sistema que
##      el jugador no ve no existe (`CLAUDE.md`, la avería del platillo). Con la
##      bola abajo, la campana se sale del plano de SEGUIMIENTO: por eso los
##      cirios de las albardillas dicen lo mismo, y cada tañido deja su onda en
##      el suelo del campo.
##   3. El atrezzo NO CHOCA: no hay colisionador detrás de nada de lo que se
##      ponga aquí. Así que va FUERA del campo —en el muro, en la albardilla, en
##      la sala, colgado por encima de la bola y de los raíles (que suben hasta
##      0,7)— o la bola lo atraviesa. Y no puede tapar las palas ni la bola desde
##      la cámara de juego. LA CAMPANA y EL FAROL DE LOS ESCUDOS SÍ caen sobre el
##      campo vistos desde la CENITAL: por eso, cuando la cámara mira a plomo, se
##      esconden (`_desvanecer`) y de la campana quedan solo las tres cenefas.
##   4. Toda llama grande pide su luz con `mundo.luz_fuego(pos, energia,
##      alcance)` (el núcleo la hace parpadear) o está a un paso de una que la
##      pidió. No se anima `light_energy`: para un fogonazo, `mundo.avivar`.
##   5. Las luces se cuentan: SIETE, y Compatibility aplica 8 por malla. Una
##      luz más por antorcha o por vela no cabe.
##   6. El muro del fondo sigue el arco de la mesa `HOLGURA_MURO` px por detrás
##      (lo pone «arquitectura»): si allí cambia, aquí hay que cambiarlo.
##   7. Lo que se mueve (la campana, su yugo, el badajo) pide su material con
##      `{"local": true}`.
##   8. La viga de la campana se queda EXACTAMENTE donde está (y 1,95, z 7,42, x
##      de 0,45 a 2,55): de ella cuelgan los tirantes del tobogán y del
##      puentecillo de «railes».
##   9. `PESCANTE_ALTO`, `PESCANTE_LARGO` y `BRAZO_FAROL` son los del guion de
##      Blender: si cambian allí, cambian aquí.

const Nucleo := preload("res://cripta3d/mundo_cripta.gd")
const MesaCripta := preload("res://cripta3d/mesa_cripta.gd")
const LLAMA: Shader = preload("res://cripta3d/mundo/atrezzo_llama.gdshader")
const RESPLANDOR: Shader = preload("res://cripta3d/mundo/atrezzo_resplandor.gdshader")
const CENEFA: Shader = preload("res://cripta3d/mundo/atrezzo_cenefa.gdshader")
const RUIDO: Texture2D = preload("res://cripta3d/texturas/ruido_manchas.png")
const MODELOS := "res://cripta3d/modelos/atrezzo_piezas.glb"

## La cara de dentro del muro del fondo va a esta distancia del arco (px). Es
## la `MURO_HOLGURA` de `arquitectura.gd`, y solo se usa si ese módulo falta.
const HOLGURA_MURO := 14.0
## Si «arquitectura» no está: dónde irían sus apoyos.
const ANTORCHAS_GRADOS: Array[float] = [38.0, 72.0, 108.0, 142.0]
const HORNACINAS_GRADOS: Array[float] = [18.0, 55.0, 90.0, 160.0]
const H_ANTORCHA := 0.95
const H_REPISA_HORNACINA := 0.42
const H_CORNISA := 2.06
## Las dos antorchas que llevan luz (índices de `apoyos_antorcha`).
const ANTORCHAS_CON_LUZ: Array[int] = [1, 2]
## Dónde va la llama en una antorcha, en sus ejes (sale de la brea).
const LLAMA_ANTORCHA := Vector3(0.0, 0.135, 0.15)
## Las gárgolas: en qué ángulos del arco y a qué altura.
const GARGOLAS_GRADOS: Array[float] = [22.0, 90.0, 158.0]
const H_GARGOLA := 1.52

## LA CAMPANA. El eje de giro (fijado por la escena: no tapa el campo desde la
## cámara de juego), y lo que mide por dentro.
const EJE_CAMPANA := Vector3(1.60, 1.95, 7.42)
## El eje del badajo, por debajo del de la campana, y lo que mide hasta la pera.
const BAJA_BADAJO := 0.15
const LARGO_BADAJO := 0.45
## Cuánto puede separarse el badajo de la campana antes de dar en el labio.
const TOPE_BADAJO := 0.40
## Las armellas de la viga, respecto al eje. Sus cadenas suben a la bóveda.
const ARMELLAS_X: Array[float] = [-1.04, 0.84]
const ARMELLA_Y := 0.43
## Cargando se ladea hasta esto (rad), y armada se queda ahí.
const LADEO_ARMADA := 0.30
## EL BRONCE EN REPOSO. Con el metal de la biblioteca (0,95) el bronce no tiene
## difuso: solo devuelve lo que refleja, y en reposo, desde el ábside, la cara
## que mira a la cámara reflejaba la sala a oscuras y la campana se quedaba casi
## negra (último retoque; en la gira 3 todavía tenía su brillo). En reposo (y
## cargando) baja el metal y sube la rugosidad, que abre el brillo del fuego de
## abajo, y lleva un templado mínimo del mismo emisivo que armada (el naranja de
## la biblioteca por el canal B, que pesa más junto a las cenefas): una pátina
## tibia, no un farol. Armada y tocando vuelven al metal de la biblioteca y a su
## emisivo de siempre, que es como se juzgaron. Y lo deprisa que cambia (por
## segundo), para que no salte al armarse.
## *Probado y quitado:* solo el metal a 0,62 y la rugosidad a 0,5. En la toma del
## ábside la cara de delante no cambió: no le llega luz directa, y sin luz el
## difuso no tiene qué devolver.
const METAL_REPOSO := 0.62
const RUGOSIDAD_REPOSO := 0.5
const EMISION_REPOSO := 0.16
const CAMBIA_REPOSO := 1.2
## El techo de la energía de las cenefas (`atrezzo_cenefa.gdshader`): por encima
## la curva de tono lleva el ámbar a crema.
const TECHO_CENEFA := 1.2
## El péndulo: lo que tarda en ir y volver la campana y el badajo (s).
const PERIODO_CAMPANA := 1.7
const PERIODO_BADAJO := 1.25
## Cuánto voltea tocando (rad), al empezar.
const AMPLITUD_TOQUE := 0.95
## Sin carga en la mesa: golpes de búmper por toque, y lo que suena.
const GOLPES_SIN_CARGA := 14
const TOQUE_SIN_CARGA := 4.0
## LA CAMPANA EN EL CAMPO: el radio de la onda de polvo dorado que deja cada
## tañido a ras de suelo (unidades), y cuánto se avivan los fuegos del campo
## mientras toca (fracción del fogonazo de `mundo.avivar`).
const ONDA_TANIDO := 2.1
const AVIVA_TOCANDO := 0.07
## ARMADA EN EL CAMPO: el lado del disco de polvo dorado que respira en el suelo
## bajo la campana mientras está armada (`atrezzo_resplandor.gdshader`), y lo
## deprisa que entra y sale (por segundo).
const LADO_RESPLANDOR := 2.3
const ENTRA_RESPLANDOR := 1.5
## Los cirios de la carga, en las albardillas: a qué distancia del centro de la
## mesa (por fuera de los raíles que bajan por los lados) y en qué filas. Dos
## filas: con tres, la del frente se metía en el sitio del pescante, y seis
## cirios gordos eran la mancha naranja más llamativa de la rasante.
const CIRIOS_X := 2.13
const CIRIOS_Z: Array[float] = [7.95, 8.4]
## El alto del cirio del GLB.
const ALTO_CIRIO := 0.27
## El eslabón mide esto de paso (lo que avanza la cadena por eslabón).
const ESLABON_PASO := 0.035
## Las velas del GLB: el alto de cada una.
const ALTO_VELA: Array[float] = [0.075, 0.125, 0.19]
## Los platillos del candelabro (en sus ejes de Godot). Solo llevan vela tres:
## cinco llamas por candelabro eran diez puntos de fuego más en la sala.
const CANDELABRO_VELAS: Array[Vector3] = [Vector3(0.0, 1.335, 0.0), Vector3(0.2, 1.225, 0.0),
	Vector3(-0.2, 1.225, 0.0)]
## LOS FAROLES (ver el guion de Blender). Del pescante: lo alto del poste sobre
## la albardilla y lo que vuela el brazo; del brazo de pared: dónde cuelga el
## farol respecto a la cara. El farol tiene el origen en su argolla, y su plato
## de abajo (donde va la vela) a `FAROL_PLATO`.
const PESCANTE_ALTO := 0.98
const PESCANTE_LARGO := 0.70
const BRAZO_FAROL := 0.21
const FAROL_PLATO := -0.189
## El pescante de los escudos: su pie en la albardilla y hacia dónde vuela (el
## banco de escudos está en x = 3,45, de z = 8,35 a 9,15).
const PESCANTE_PIE := Vector3(3.95, 0.0, 8.95)
const PESCANTE_HACIA := Vector3(3.27, 0.0, 8.76)
## El farol de la columna, a esta altura (debajo del collarino, que está a 1,98).
const H_FAROL_COLUMNA := 1.62
const R_FUSTE := 0.165
## Las celdas en que se parte lo fijo unido (8 luces por malla).
const CELDA := 2.4

var _mundo: Nucleo
var _mesa: MesaCripta
var _mallas: Dictionary = {}
var _avisado := false
var _azar := RandomNumberGenerator.new()
var _y_sala := Nucleo.Y_SALA
var _h_borde := 0.22
## La capa de dibujo de lo que se va colgando. LA CÁMARA DEL REFLEJO solo ve la
## 1, y cada cosa que ve es otra llamada de dibujo: casi todo va en
## `CAPA_SIN_REFLEJO`, y la sala entera en `CAPA_BAJO_SUELO`, que además es
## OBLIGADO para lo que baja de y = 0: el reflejo lo pintaría delante de todo.
var _capa := 1

## LO FIJO, antes de unirlo: clave → {mat, capa, grupo, partes: [[malla, xf]]}.
var _lotes: Dictionary = {}
## Lo que se apaga en BAJA (la sala menuda) y lo que se esconde desde la cenital
## (lo que vuela sobre el campo).
var _detalle: Array[Node3D] = []
var _colgado: Array[Node3D] = []
## Todo lo que dibuja este módulo, para contarlo (`--medir`).
var _mios: Array[GeometryInstance3D] = []

## Las llamas, antes de hacer sus MultiMesh: {pos, ancho, alto}.
var _llamas_grandes: Array[Dictionary] = []
var _llamas_chicas: Array[Dictionary] = []
var _llamas_cirios: Array[Dictionary] = []
var _mm_grandes: MultiMesh = null
var _mm_chicas: MultiMesh = null
var _mm_cirios: MultiMesh = null
## Las velas (tipo → transformadas) y los charcos de cera, antes de sus MultiMesh.
var _velas: Array[Array] = [[], [], []]
var _charcos: Array[Transform3D] = []
## Las llamas y las velas que van con el farol de los escudos (índices en sus
## MultiMesh), para esconderlas desde la cenital con su farol.
var _llama_colgada := -1
var _vela_colgada := -1
var _mm_velas_0: MultiMesh = null
var _xf_vela_colgada := Transform3D()
## Las cadenas: los eslabones, por grupo («viga», «muro», «sala»).
var _eslabones: Dictionary = {"viga": [] as Array[Transform3D], "muro": [] as Array[Transform3D],
	"sala": [] as Array[Transform3D]}
## Las luces de fuego pedidas al núcleo, y cuánto se avivan con la campana.
var _luces: Array[OmniLight3D] = []
var _aviva := 0.0
## Dónde arden los dos braseros de las esquinas (su luz la pone `_montar_faroles`).
var _fuegos_esquina: Array[Vector3] = []
## La cera de velas y cirios (una copia propia: ver `_material_cera`).
var _cera: Material = null

## La campana: sus nodos, sus materiales propios y su péndulo.
var _campana: Node3D = null
var _badajo: Node3D = null
var _brasas_campana: Array[ShaderMaterial] = []
var _bronce: ShaderMaterial = null
var _bronce_malla: MeshInstance3D = null
## El metal y la rugosidad del bronce de la biblioteca, y cuánto está en reposo
## (1 = en reposo del todo: ver `METAL_REPOSO`).
var _metal_bronce := 0.95
var _rugosidad_bronce := 0.42
var _f_reposo := 1.0
var _piezas_campana: Array[Node3D] = []
var _cenefas: Array[MeshInstance3D] = []
## El resplandor de «armada» en el suelo, y cuánto está encendido (0..1).
var _resplandor: MeshInstance3D = null
var _mat_resplandor: ShaderMaterial = null
var _f_resplandor := 0.0
var _th := 0.0
var _w := 0.0
var _fi := 0.0
var _wf := 0.0
var _destello := 0.0
var _desde_arriba := false
var _calidad := 0
## Sin carga en la mesa, la campana lleva su propia cuenta.
var _carga_propia := 0.0
var _toque_propio := 0.0
var _armada_propia := false

func montar(mundo: Node3D) -> void:
	_mundo = mundo as Nucleo
	_mesa = _mundo.mesa
	_azar.seed = 4127
	_leer_medidas()
	_cargar_mallas()
	_cera = _material_cera()
	# Al reflejo solo va lo grande del ábside que se reconoce en el suelo
	# mojado: la campana (cae a media mesa en el reflejo). Las llamas no: ver
	# `_montar_llamas`.
	_capa = 1
	_montar_campana()
	_capa = Nucleo.CAPA_SIN_REFLEJO
	_montar_antorchas()
	_montar_braseros_esquina()
	_montar_gargolas()
	_montar_hornacinas_y_cornisa()
	_montar_cadenas_muro()
	_montar_cirios()
	_montar_faroles()
	_capa = Nucleo.CAPA_BAJO_SUELO
	_montar_sala()
	_capa = 1
	_montar_velas()
	_montar_cadenas()
	_montar_llamas()
	_volcar()
	_mesa.descarga_empezada.connect(_al_empezar_descarga)
	_mesa.carga_cambiada.connect(_al_cambiar_carga)
	_mesa.bumper_golpeado.connect(_al_golpear_bumper)
	if OS.get_cmdline_user_args().has("--medir"):
		_contar()

# ------------------------------------------------------------------ utilidades

## Lo alto de la albardilla, que es de «arquitectura». Si ese módulo falta, la
## de siempre. El suelo de la sala ya no se lee de allí: es `Nucleo.Y_SALA`.
func _leer_medidas() -> void:
	var arq: Object = _mundo.modulo("arquitectura")
	if arq == null or arq.get_script() == null:
		return
	var consts: Dictionary = (arq.get_script() as GDScript).get_script_constant_map()
	_h_borde = float(consts.get("H_BORDE", _h_borde))

func _cargar_mallas() -> void:
	if not ResourceLoader.exists(MODELOS):
		print("ATREZZO: falta %s (cripta3d/blender/atrezzo_modelos.py): el atrezzo sale vacío" % MODELOS)
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
			print("ATREZZO: no encuentro «%s» en el GLB; ¿hay que reimportar?" % nombre)
			_avisado = true
		return BoxMesh.new()
	return m

## Un material de la biblioteca que usa el color de vértice del modelo.
func _mat(nombre: String, variante: Dictionary = {}) -> Material:
	var v := {"vertice": true}
	v.merge(variante, true)
	return _mundo.mat.dame(nombre, v)

## Una copia propia de un material de la biblioteca, para poder animarla sin
## encender a la vez todo lo que comparte el original. Con los materiales de
## reserva (`--reserva`) es un `StandardMaterial3D`: se pinta, pero no se anima.
func _propio(nombre: String, variante: Dictionary = {}) -> Material:
	var m: Material = _mat(nombre, variante)
	return m.duplicate() as Material if m != null else null

## LA CERA DE LAS VELAS Y LOS CIRIOS. La «cera» de la biblioteca deja pasar la
## luz en NARANJA (`translucido`), y con los braseros de las esquinas al lado los
## cirios salían naranja saturado: tubos de PVC, conos de tráfico (lo dijo la
## crítica de arte del 21-nov). La cera de una cripta es marfil sucio y mate, y
## se calienta por la luz que le llega, no por su color: aquí se pide la de la
## biblioteca más mate y más sucia, y a una copia propia se le baja el paso de
## luz a un pardo apagado. (Se le pide a «materiales» que lo traiga de serie.)
func _material_cera() -> Material:
	# El tinte, marfil sucio tirando a hueso: con (0,93; 0,90; 0,84) la primera
	# prueba salió blanco de vela de farmacia.
	var m := _propio("cera", {"escala": 0.06, "tinte": Color(0.8, 0.72, 0.58), "rugosidad": 1.7,
		"suciedad": 0.85})
	var sm := m as ShaderMaterial
	if sm != null:
		sm.set_shader_parameter("translucido", Paleta.TIERRA_4.darkened(0.8))
	return m

## Una pieza SUELTA: las que se mueven o se esconden por su cuenta (la campana).
func _pieza(padre: Node3D, malla: String, material: Material, xf: Transform3D,
		sombra: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _malla(malla)
	mi.material_override = material
	mi.transform = xf
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.layers = _capa
	padre.add_child(mi)
	_mios.append(mi)
	return mi

## Una pieza FIJA: no se cuelga sola, se apunta en su lote (mismo material, misma
## capa, mismo grupo y misma celda) y `_volcar` une cada lote en UNA malla. Antes
## cada barril, cada antorcha y cada gárgola era su llamada de dibujo, y la
## mayoría se repetía en la sombra y en el reflejo. `grupo`: "" lo normal,
## "detalle" se apaga en BAJA, "colgado" se esconde desde la cenital.
func _fijo(malla: String, material: Material, xf: Transform3D, grupo: String = "") -> void:
	var celda := Vector2i(floori(xf.origin.x / CELDA), floori(xf.origin.z / CELDA))
	var clave := "%d|%d|%s|%d|%d" % [material.get_instance_id(), _capa, grupo, celda.x, celda.y]
	if not _lotes.has(clave):
		_lotes[clave] = {"mat": material, "capa": _capa, "grupo": grupo, "partes": []}
	(_lotes[clave]["partes"] as Array).append([_malla(malla), xf])

func _volcar() -> void:
	for clave: String in _lotes:
		var lote: Dictionary = _lotes[clave]
		var st := SurfaceTool.new()
		for par: Array in lote["partes"]:
			var m: Mesh = par[0]
			for s in m.get_surface_count():
				st.append_from(m, s, par[1] as Transform3D)
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = lote["mat"]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.layers = int(lote["capa"])
		_mundo.add_child(mi)
		_mios.append(mi)
		_apuntar(mi, str(lote["grupo"]))
	_lotes.clear()

func _apuntar(nodo: Node3D, grupo: String) -> void:
	if grupo == "detalle":
		_detalle.append(nodo)
	elif grupo == "colgado":
		_colgado.append(nodo)

## Lo repetido, en un MultiMesh. Cada grupo va junto en el espacio: un MultiMesh
## es UNA malla para las 8 luces de Compatibility.
func _repetir(malla: Mesh, material: Material, xfs: Array[Transform3D]) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malla
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.layers = _capa
	_mundo.add_child(mmi)
	_mios.append(mmi)
	return mmi

## Una base que mira hacia `w` (horizontal), con Y arriba: lo que se modeló con
## el frente a +z queda mirando hacia `w`.
static func _base_hacia(w: Vector3) -> Basis:
	var z := Vector3(w.x, 0.0, w.z).normalized()
	if z.length() < 0.5:
		z = Vector3.BACK
	var x := Vector3.UP.cross(z).normalized()
	return Basis(x, Vector3.UP, z)

## Un punto de la cara del ábside y su marco (X a lo largo del muro, Y arriba,
## Z hacia el campo). Se lo pide a «arquitectura»; si no está, lo calcula del
## arco de la mesa.
func _marco_muro(grados: float, altura: float, fuera: float = 0.0) -> Transform3D:
	var arq: Object = _mundo.modulo("arquitectura")
	if arq != null and arq.has_method("punto_abside"):
		var p: Vector3 = arq.call("punto_abside", grados, altura, fuera)
		var a: Vector3 = arq.call("punto_abside", grados - 0.6, altura, fuera)
		var b: Vector3 = arq.call("punto_abside", grados + 0.6, altura, fuera)
		var u := (a - b).normalized()
		return Transform3D(Basis(u, Vector3.UP, u.cross(Vector3.UP).normalized()), p)
	var c := _mesa.arco_centro
	var r := _mesa.arco_radios
	var t := deg_to_rad(grados)
	var en_arco := Vector2(c.x + r.x * cos(t), c.y - r.y * sin(t))
	var hacia_fuera := Vector2(cos(t) / r.x, -sin(t) / r.y).normalized()
	var pos := _mundo.a3(en_arco + hacia_fuera * HOLGURA_MURO, altura) \
		- Vector3(hacia_fuera.x, 0.0, hacia_fuera.y) * fuera
	var u3 := Vector3(sin(t) * r.x, 0.0, cos(t) * r.y).normalized()
	return Transform3D(Basis(u3, Vector3.UP, u3.cross(Vector3.UP).normalized()), pos)

## Los apoyos que deja «arquitectura» (o, si falta, los de su cabecera).
func _apoyos(nombre: String, grados: Array[float], altura: float, fuera: float) -> Array[Transform3D]:
	var lista: Array[Transform3D] = []
	var arq: Object = _mundo.modulo("arquitectura")
	if arq != null:
		var v: Variant = arq.get(nombre)
		if v is Array:
			for xf: Variant in v:
				if xf is Transform3D:
					lista.append(xf)
	if lista.is_empty():
		for g in grados:
			lista.append(_marco_muro(g, altura, fuera))
	return lista

## LOS ANCLAJES DE LA BÓVEDA, si «arquitectura» los publica (con cualquiera de
## estos nombres, como Transform3D o Vector3). Si no, lista vacía y las cadenas
## suben rectas hasta `Nucleo.Y_BOVEDA`.
func _anclajes_boveda() -> Array[Vector3]:
	var lista: Array[Vector3] = []
	var arq: Object = _mundo.modulo("arquitectura")
	if arq == null:
		return lista
	for nombre: String in ["anclajes_boveda", "anclajes_cadenas", "anclajes"]:
		var v: Variant = arq.get(nombre)
		if v is Array:
			for a: Variant in v:
				if a is Transform3D:
					lista.append((a as Transform3D).origin)
				elif a is Vector3:
					lista.append(a)
		if not lista.is_empty():
			break
	return lista

## Hasta dónde sube una cadena que sale de `desde`: al anclaje de la bóveda más
## cercano en planta (si lo hay a menos de un paso), o recta hasta la bóveda.
func _techo_sobre(desde: Vector3, anclajes: Array[Vector3]) -> Vector3:
	var mejor := Vector3(desde.x, Nucleo.Y_BOVEDA, desde.z)
	var d_mejor := 0.9
	for a in anclajes:
		var d := Vector2(a.x - desde.x, a.z - desde.z).length()
		if d < d_mejor and a.y > desde.y + 0.5:
			d_mejor = d
			mejor = a
	return mejor

func _llama(lista: Array[Dictionary], pos: Vector3, ancho: float, alto: float) -> int:
	lista.append({"pos": pos, "ancho": ancho, "alto": alto})
	return lista.size() - 1

# ------------------------------------------------------------- la campana mayor

func _montar_campana() -> void:
	var raiz := Node3D.new()
	raiz.name = "CampanaMayor"
	raiz.position = EJE_CAMPANA
	_mundo.add_child(raiz)
	# Lo fijo: la viga y sus hierros. La madera, con la veta a lo largo.
	_piezas_campana.append(_pieza(raiz, "viga", _mat("madera", {"veta": Vector3.RIGHT, "escala": 0.8}),
		Transform3D()))
	_piezas_campana.append(_pieza(raiz, "viga_herraje", _mat("hierro", {"escala": 0.3}), Transform3D()))
	# Las dos cadenas que cuelgan la viga SUBEN HASTA LA BÓVEDA (decisión 2):
	# antes subían a y = 5,6 y se perdían en un cielo que ya no existe.
	var anclajes := _anclajes_boveda()
	for x in ARMELLAS_X:
		var desde := EJE_CAMPANA + Vector3(x, ARMELLA_Y, 0.0)
		_cadena(desde, _techo_sobre(desde, anclajes), 1.7, false, "viga")

	# Lo que voltea: el yugo, la campana y sus brasas. Todo con «local».
	_campana = Node3D.new()
	raiz.add_child(_campana)
	_piezas_campana.append(_pieza(_campana, "yugo",
		_mat("madera", {"local": true, "veta": Vector3.BACK, "escala": 0.5}), Transform3D()))
	_piezas_campana.append(_pieza(_campana, "yugo_herraje",
		_mat("hierro", {"local": true, "escala": 0.25}), Transform3D()))
	# El bronce, propio: se pone al rojo cuando está armada. Es lo único del
	# atrezzo que hace sombra, y solo en ALTA (`calidad`).
	var bronce := _propio("bronce", {"local": true, "escala": 0.45, "desgaste": 0.7, "suciedad": 0.9})
	_bronce = bronce as ShaderMaterial
	if _bronce != null:
		var met: Variant = _bronce.get_shader_parameter("metal")
		var rug: Variant = _bronce.get_shader_parameter("rugosidad")
		if met is float:
			_metal_bronce = met
		if rug is float:
			_rugosidad_bronce = rug
	_bronce_malla = _pieza(_campana, "campana", bronce, Transform3D(), true)
	_piezas_campana.append(_bronce_malla)
	for i in 3:
		# LA CENEFA ES UNA BANDA LISA DE ÁMBAR, con su sombreador propio
		# (`atrezzo_cenefa.gdshader`, donde está el porqué). Antes era una copia
		# del «ascua» de la biblioteca con la paleta bajada a ámbar, y su costra,
		# sus grietas y su hervor la sacaban armada con estampado de jirafa en
		# crema y rosa, y desde la RASANTE como una cinta de obra a bloques. Es
		# un efecto (como la llama y el resplandor), no una superficie de la
		# mesa: por eso no se le pide a la biblioteca.
		var sm := ShaderMaterial.new()
		sm.shader = CENEFA
		# De ORO_OSCURO a ORO, con el verde y el azul recogidos. La curva de tono
		# es AgX con exposición 1,5 («entorno»), que lleva lo que brilla hacia el
		# blanco amarillento: con ORO a pelo la banda salía amarillo caqui
		# (167, 123, 41 medido en la captura armada) y, mezclada con NARANJA,
		# melocotón (242, 161, 93), porque el azul de NARANJA y de COBRE_3 sube a
		# crema. Ámbar es rojo y verde con el azul casi a cero, y poca luz.
		sm.set_shader_parameter("color_bajo", Color(0.54, 0.30, 0.05))
		sm.set_shader_parameter("color_alto", Color(0.88, 0.52, 0.08))
		sm.set_shader_parameter("brillo", 0.5)
		sm.set_shader_parameter("color_apagado", Paleta.ORO_OSCURO.darkened(0.72))
		sm.set_shader_parameter("energia", 0.0)
		_brasas_campana.append(sm)
		# Las cenefas NO van en `_piezas_campana`: son lo único que se queda a la
		# vista desde la cenital (y solo con carga: ver `actualizar`).
		_cenefas.append(_pieza(_campana, "campana_brasa_%d" % i, sm, Transform3D()))
	_badajo = Node3D.new()
	_badajo.position = Vector3(0.0, -BAJA_BADAJO, 0.0)
	_campana.add_child(_badajo)
	# El badajo va por dentro: al reflejo no le aporta nada.
	var bad := _pieza(_badajo, "badajo", _mat("hierro", {"local": true, "escala": 0.2}), Transform3D())
	bad.layers = Nucleo.CAPA_SIN_REFLEJO
	_piezas_campana.append(bad)
	_montar_resplandor()

## ARMADA SE NOTA EN EL CAMPO (decisión 4 de la revisión 2). Con la bola abajo,
## SEGUIMIENTO no ve la campana, y armada es el estado que le pide algo al
## jugador. Un disco de polvo dorado en el suelo, bajo su vertical, que solo se
## enciende armada (`actualizar`). Un plano con su sombreador: no es una luz (las
## siete están contadas) ni pasa por el reflejo (va pintado sobre el suelo).
## Escondido no cuesta ni una llamada de dibujo.
func _montar_resplandor() -> void:
	var suelo := Vector2(EJE_CAMPANA.x, EJE_CAMPANA.z) / Nucleo.E
	var plano := PlaneMesh.new()
	plano.size = Vector2.ONE * LADO_RESPLANDOR
	_mat_resplandor = ShaderMaterial.new()
	_mat_resplandor.shader = RESPLANDOR
	_mat_resplandor.set_shader_parameter("color", Paleta.ORO)
	_resplandor = MeshInstance3D.new()
	_resplandor.name = "ResplandorArmada"
	_resplandor.mesh = plano
	_resplandor.material_override = _mat_resplandor
	_resplandor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_resplandor.layers = Nucleo.CAPA_SIN_REFLEJO
	# Un centímetro y medio sobre el suelo: las incrustaciones van a ras y con
	# menos se pelean en profundidad.
	_resplandor.position = Vector3(EJE_CAMPANA.x, _mundo.altura_en(suelo) + 0.015, EJE_CAMPANA.z)
	_resplandor.visible = false
	_mundo.add_child(_resplandor)
	_mios.append(_resplandor)

# ------------------------------------------------------------------ el fuego

## LA JERARQUÍA DE LA LLAMA (decisión 4): las antorchas del ábside, a la mitad
## de lo que eran (0,11 × 0,24); los braseros del fondo, algo por debajo de lo
## que eran; la sala, más baja; las velas, puntos.
func _montar_antorchas() -> void:
	var apoyos := _apoyos("apoyos_antorcha", ANTORCHAS_GRADOS, H_ANTORCHA, 0.0)
	var hierro := _mat("hierro", {"escala": 0.2})
	var brea := _mat("carbon", {"emision": 2.6, "escala": 0.08})
	for i in apoyos.size():
		var xf := apoyos[i]
		_fijo("antorcha_hierro", hierro, xf)
		_fijo("antorcha_brea", brea, xf)
		var llama := xf * LLAMA_ANTORCHA
		_llama(_llamas_grandes, llama, 0.075, 0.17)
		_llama(_llamas_grandes, llama + xf.basis.x * 0.01 + Vector3.UP * 0.008, 0.05, 0.11)
		if ANTORCHAS_CON_LUZ.has(i):
			# Un poco por delante de la llama: pegada al muro lo quema y no llega
			# al suelo.
			_luces.append(_mundo.luz_fuego(llama + xf.basis.z * 0.22 + Vector3.UP * 0.12, 1.25, 2.0))

## Un brasero de garra: patas, cuenco, brasas y tres lenguas de fuego. `llama`
## escala solo el fuego (la jerarquía), no el hierro.
func _brasero(base: Vector3, escala: float, giro: float, pie_alto: bool, llama: float,
		grupo: String = "") -> Vector3:
	var b := Basis(Vector3.UP, giro).scaled(Vector3.ONE * escala)
	# Todo el hierro fijo con la MISMA variante: cada variante es otro material
	# y otro lote, o sea otra llamada de dibujo.
	var hierro := _mat("hierro", {"escala": 0.2})
	var alto_cuenco := 0.10
	if pie_alto:
		_fijo("brasero_pie", hierro, Transform3D(Basis(Vector3.UP, giro), base), grupo)
		alto_cuenco = 0.90
	else:
		_fijo("brasero_patas", hierro, Transform3D(b, base), grupo)
		alto_cuenco *= escala
	var en_cuenco := base + Vector3.UP * alto_cuenco
	_fijo("brasero_cuenco", hierro, Transform3D(b, en_cuenco), grupo)
	_fijo("brasero_brasas", _mat("ascua", {"escala": 0.1}), Transform3D(b, en_cuenco), grupo)
	var fuego := en_cuenco + Vector3.UP * 0.12 * escala
	var f := escala * llama
	_llama(_llamas_grandes, fuego, 0.26 * f, 0.46 * f)
	_llama(_llamas_grandes, fuego + b.x * 0.06 + b.z * 0.02, 0.15 * f, 0.30 * f)
	_llama(_llamas_grandes, fuego - b.x * 0.05 - b.z * 0.03, 0.14 * f, 0.26 * f)
	return fuego

## Los dos braseros de las esquinas del fondo: en la albardilla, delante de las
## columnas del ábside y por fuera de los raíles que bajan por los lados. Su luz
## ya no va pegada a la llama: sube hasta media columna, entre el brasero y el
## farol del fuste, y así llega también al CAPITEL de calaveras, que antes se
## quedaba a oscuras (la crítica de arte: «no se ven»).
func _montar_braseros_esquina() -> void:
	var z := (_mesa.arco_centro.y + 50.0) * Nucleo.E
	for lado: float in [-1.0, 1.0]:
		var x := 2.0 + lado * 2.17
		_fuegos_esquina.append(_brasero(Vector3(x, _h_borde, z), 0.82, lado * 0.4, false, 0.95))

## La luz de un brasero de la esquina, donde se le diga. La pone `_montar_faroles`
## (dentro del farol de la columna de encima) o, si no hay columnas, al lado de
## la llama como antes. Energía × alcance pensados para no quitarle la sombra
## de fuego a los braseros del campo («entorno» se la da a la luz que más pesa).
func _luz_esquina(pos: Vector3) -> void:
	_luces.append(_mundo.luz_fuego(pos, 1.2, 2.4))
	# EL FILO DE LAS CENEFAS APAGADAS es el brillo de estos dos fuegos en el
	# bronce: con la luz por vértice no salía (gira6: el canto de la cinta, de
	# 22–29 de rojo a 2), y la cenefa lo pinta a mano (`atrezzo_cenefa.gdshader`).
	# Las dos esquinas quedan a los lados de la campana; el mundo está en el
	# origen, así que su espacio es el de la escena.
	var uniforme := "fuego_a" if pos.x < 2.0 else "fuego_b"
	for sm in _brasas_campana:
		sm.set_shader_parameter(uniforme, pos)

# ------------------------------------------------------------------ el muro

func _montar_gargolas() -> void:
	var piedra := _mat("piedra", {"escala": 0.35, "juntas": Vector3.ZERO})
	var ojos := _mat("ascua", {"emision": 1.6, "escala": 0.05})
	for g in GARGOLAS_GRADOS:
		var xf := _marco_muro(g, H_GARGOLA, 0.0)
		_fijo("gargola", piedra, xf)
		_fijo("gargola_ojos", ojos, xf)

## Un racimo de velas sobre su charco de cera, con las llamitas. `xf` es el
## sitio (Y arriba); las velas se reparten en un círculo de `radio`.
func _racimo(xf: Transform3D, cuantas: int, radio: float, grande: float = 1.0) -> void:
	_charcos.append(Transform3D(xf.basis.scaled(Vector3(radio * 11.0, 1.0, radio * 11.0)), xf.origin))
	for k in cuantas:
		var a := _azar.randf() * TAU
		var r := radio * sqrt(_azar.randf()) * 0.85
		if k == 0:
			r = 0.0
		var tipo := 2 if k == 0 else _azar.randi_range(0, 1 if k > 2 else 2)
		var esc := _azar.randf_range(0.8, 1.15) * grande
		var donde := xf * Vector3(cos(a) * r, 0.003, sin(a) * r)
		var b := Basis(Vector3.UP, _azar.randf() * TAU).scaled(Vector3(esc, esc * _azar.randf_range(0.85, 1.2), esc))
		_velas[tipo].append(Transform3D(b, donde))
		var punta := donde + Vector3.UP * (ALTO_VELA[tipo] * b.y.length() + 0.004)
		# Una vela es un PUNTO de fuego, no una antorcha pequeña.
		_llama(_llamas_chicas, punta, 0.018 * grande, 0.045 * grande)

## Menos velas que antes (eran 22 llamas en el muro): tres en las hornacinas de
## los lados, una a cada lado de la calavera en las del centro, y en la cornisa
## dos y una alternas.
func _montar_hornacinas_y_cornisa() -> void:
	var calaveras: Array[Transform3D] = []
	var hornacinas := _apoyos("hornacinas", HORNACINAS_GRADOS, H_REPISA_HORNACINA, -0.08)
	for i in hornacinas.size():
		var xf := hornacinas[i]
		# EL CIRIO QUE ATRAVESABA LA JAMBA (revisión 2, técnica). El racimo iba a
		# media hondura de la hornacina (`xf`, 0,08 dentro del muro) y, visto de
		# lado desde el coro, la jamba le cortaba el costado justo por su borde:
		# se leía como una vela metida en la piedra. Ahora el racimo de las de
		# los lados se sienta en el LABIO de la repisa, delante del plano del
		# muro (la repisa vuela 0,08), y las de las calaveras se adelantan y se
		# arriman al centro: ninguna queda a menos de 0,09 de una jamba.
		if i == 1 or i == 2:
			# Una calavera en el centro de la hornacina, con sus velas a los lados.
			calaveras.append(Transform3D(xf.basis.rotated(Vector3.UP, _azar.randf_range(-0.3, 0.3)),
				xf * Vector3(0.0, 0.0, 0.02)))
			_racimo(xf.translated_local(Vector3(-0.085, 0.0, 0.05)), 1, 0.03)
			_racimo(xf.translated_local(Vector3(0.09, 0.0, 0.04)), 1, 0.03)
		else:
			_racimo(xf.translated_local(Vector3(0.0, 0.0, 0.105)), 3, 0.035)
	# La cornisa: las repisas de arriba (las de las hornacinas ya tienen lo suyo).
	var arq: Object = _mundo.modulo("arquitectura")
	var repisas: Array[Transform3D] = []
	if arq != null and arq.get("repisas") is Array:
		for xf: Variant in arq.get("repisas"):
			if xf is Transform3D and (xf as Transform3D).origin.y > H_CORNISA - 0.1:
				repisas.append(xf)
	if repisas.is_empty():
		for g: float in [30.0, 70.0, 110.0, 150.0]:
			repisas.append(_marco_muro(g, H_CORNISA + 0.18, -0.08))
	for i in repisas.size():
		if i % 2 == 0:
			_racimo(repisas[i], 2, 0.04)
		else:
			calaveras.append(Transform3D(repisas[i].basis, repisas[i].origin))
			_racimo(repisas[i].translated_local(Vector3(0.09, 0.0, -0.02)), 1, 0.02)
	var hueso := _mat("hueso", {"escala": 0.1})
	for xf in calaveras:
		_fijo("calavera", hueso, xf)

# ----------------------------------------------------------------- las cadenas

## Una cadena recta de `desde` a `hasta`, con los eslabones alternando de
## plano. Si `gancho`, acaba en un gancho. Los eslabones van a su grupo: cada
## grupo es UN MultiMesh (`_montar_cadenas`), no uno por cadena.
func _cadena(desde: Vector3, hasta: Vector3, escala: float, gancho: bool, grupo: String) -> void:
	var dir := hasta - desde
	var largo := dir.length()
	if largo < 0.01:
		return
	dir /= largo
	var paso := ESLABON_PASO * escala
	var n := int(largo / paso)
	var ref := Vector3.RIGHT if absf(dir.x) < 0.9 else Vector3.BACK
	var x := ref.cross(dir).normalized()
	var base := Basis(x, dir, x.cross(dir).normalized()).scaled(Vector3.ONE * escala)
	var lista: Array[Transform3D] = _eslabones[grupo]
	for k in n:
		var b := base.rotated(dir, (PI * 0.5 if k % 2 == 1 else 0.0) + _azar.randf_range(-0.12, 0.12))
		# Un eslabón cuelga del anterior: su centro va medio paso más allá.
		lista.append(Transform3D(b, desde + dir * (paso * (float(k) + 0.5))))
	if gancho:
		var fin := desde + dir * (paso * float(n) + 0.006 * escala)
		# El gancho cuelga hacia abajo: su ojo en el último eslabón.
		var bg := Basis(Vector3.UP, _azar.randf() * TAU).scaled(Vector3.ONE * escala * 0.9)
		_fijo("gancho", _mat("hierro", {"escala": 0.2}), Transform3D(bg, fin),
			"detalle" if grupo == "sala" else "")

func _montar_cadenas_muro() -> void:
	var argollas := _apoyos("argollas", [36.0, 150.0], 1.66, 0.03)
	for xf in argollas:
		_cadena(xf.origin, xf.origin + Vector3.DOWN * 0.30, 1.0, true, "muro")

## Los eslabones, un MultiMesh por grupo. Ni sombra ni reflejo: un eslabón son
## dos o tres píxeles en la cámara de juego. Los de la viga se esconden con la
## campana desde la cenital; los de la sala se apagan en BAJA.
func _montar_cadenas() -> void:
	var hierro := _mat("hierro", {"escala": 0.08})
	var capa_antes := _capa
	_capa = Nucleo.CAPA_SIN_REFLEJO
	for grupo: String in ["viga", "muro", "sala"]:
		var lista: Array[Transform3D] = _eslabones[grupo]
		if lista.is_empty():
			continue
		var mmi := _repetir(_malla("eslabon"), hierro, lista)
		# La cadena larga no cabe en la caja de un eslabón: que no la recorten.
		mmi.extra_cull_margin = 0.2
		if grupo == "viga":
			_piezas_campana.append(mmi)
		elif grupo == "sala":
			mmi.layers = Nucleo.CAPA_BAJO_SUELO
			_detalle.append(mmi)
	_capa = capa_antes

# --------------------------------------------------------------------- la sala

func _montar_sala() -> void:
	var y := _y_sala
	# Los braseros de pie, delante de los pilares del fondo: luz para los lados.
	# La sala va a un cuarto (decisión 4): la llama, más baja que la del fondo.
	for lado: float in [-1.0, 1.0]:
		var x := 2.0 + lado * 4.1
		var fuego := _brasero(Vector3(x, y, 9.0), 1.3, lado * 0.7, true, 0.55)
		# Pesa poco por lo mismo que los de las esquinas; y con sombra, el cuenco
		# pintaba un disco negro en el suelo, justo debajo.
		_luces.append(_mundo.luz_fuego(fuego + Vector3(-lado * 0.1, 0.4, 0.25), 1.4, 2.3))
	# Los candelabros, más cerca del jugador.
	var hierro := _mat("hierro", {"escala": 0.2})
	for lado: float in [-1.0, 1.0]:
		var base := Vector3(2.0 + lado * 4.25, y, 11.3)
		var b := Basis(Vector3.UP, lado * 0.35)
		_fijo("candelabro", hierro, Transform3D(b, base))
		for p in CANDELABRO_VELAS:
			var tipo := 1 if p.y < 1.3 else 2
			var esc := _azar.randf_range(0.9, 1.1)
			var bv := Basis(Vector3.UP, _azar.randf() * TAU).scaled(Vector3(esc, esc, esc))
			var donde := base + b * p
			_velas[tipo].append(Transform3D(bv, donde))
			_llama(_llamas_chicas, donde + Vector3.UP * (ALTO_VELA[tipo] * esc + 0.004), 0.022, 0.055)
	# Barriles y cajas en los rincones de detrás del mueble, y huesos: lo menudo
	# de la sala, que se apaga en BAJA.
	var madera := _mat("madera", {"veta": Vector3.UP, "escala": 0.5})
	var aros := _mat("hierro", {"escala": 0.2})
	for p: Vector3 in [Vector3(-1.2, y, 7.5), Vector3(-1.62, y, 8.0)]:
		var xf := Transform3D(Basis(Vector3.UP, _azar.randf() * TAU), p)
		_fijo("barril_madera", madera, xf, "detalle")
		_fijo("barril_aros", aros, xf, "detalle")
	var tablas := _mat("madera", {"escala": 0.45})
	for c: Array in [[Vector3(5.22, y, 7.62), 0.2], [Vector3(5.3, y, 8.04), -0.15],
			[Vector3(5.25, y + 0.36, 7.84), 0.6]]:
		var xf := Transform3D(Basis(Vector3.UP, float(c[1])), c[0])
		_fijo("caja_madera", tablas, xf, "detalle")
		_fijo("caja_herraje", aros, xf, "detalle")
	# Hueso viejo y sucio: limpio, un montón en la albardilla salta a la vista
	# más que la bola. Los dos de la albardilla se quedan en BAJA (están junto
	# al campo); los de la sala no.
	var hueso := _mat("hueso", {"escala": 0.12, "tinte": Color(0.74, 0.68, 0.6), "suciedad": 0.75})
	for c: Array in [[Vector3(-1.55, y, 8.7), 0.4, 1.3, "detalle"], [Vector3(5.55, y, 8.75), 2.1, 1.3, "detalle"],
			[Vector3(2.0 - 2.07, _h_borde, 12.55), 1.0, 0.9, ""], [Vector3(2.0 + 2.07, _h_borde, 11.9), -0.6, 0.9, ""]]:
		var esc := float(c[2])
		_fijo("huesos", hueso, Transform3D(Basis(Vector3.UP, float(c[1])).scaled(Vector3.ONE * esc), c[0]),
			str(c[3]))
	# Dos cadenas colgando de la BÓVEDA de la sala, con su gancho.
	var anclajes := _anclajes_boveda()
	for p: Vector3 in [Vector3(-2.35, 0.0, 10.2), Vector3(6.4, 0.0, 10.0)]:
		var abajo := Vector3(p.x, 1.15 + _azar.randf() * 0.4, p.z)
		_cadena(_techo_sobre(abajo, anclajes), abajo, 2.0, true, "sala")

# ----------------------------------------------------------------- los faroles

## LOS FAROLES. Dos sitios de la mesa estaban a oscuras y una luz ahí necesita
## motivo (LEEME: «no hay luz sin motivo»):
##   · LOS CAPITELES de calaveras de las columnas del ábside. Un farol colgado
##     de un brazo clavado en el fuste, debajo del capitel; su luz es la del
##     brasero de la esquina, subida (ver `_montar_braseros_esquina`).
##   · LOS ESCUDOS del banco de la derecha, debajo de los raíles. Un farol en un
##     PESCANTE que sale de la albardilla y vuela por encima de los raíles hasta
##     delante de los escudos, con su luz propia. Desde la cenital vuela sobre
##     el campo: se esconde (`_desvanecer`).
func _montar_faroles() -> void:
	var hierro := _mat("hierro", {"escala": 0.2})
	var sin_luz: Array[Vector3] = _fuegos_esquina.duplicate()
	var arq: Object = _mundo.modulo("arquitectura")
	if arq != null and arq.get("capiteles") is Array:
		for c: Variant in arq.get("capiteles"):
			if not (c is Transform3D):
				continue
			var eje := (c as Transform3D).origin
			# El brazo, en la cara del fuste que mira al centro del campo.
			var hacia := Vector3(2.0 - eje.x, 0.0, 9.0 - eje.z).normalized()
			var b := _base_hacia(hacia)
			var brazo := Transform3D(b, Vector3(eje.x, H_FAROL_COLUMNA, eje.z) + hacia * R_FUSTE)
			_fijo("farol_brazo", hierro, brazo)
			var farol := Transform3D(b, brazo * Vector3(0.0, 0.0, BRAZO_FAROL))
			_farol(farol, hierro, "")
			# La luz del brasero de debajo sube aquí, al farol: desde y = 1,05
			# (la primera prueba) el capitel, a 2,1, seguía a oscuras.
			var cerca := -1
			for i in sin_luz.size():
				if cerca < 0 or absf(sin_luz[i].x - eje.x) < absf(sin_luz[cerca].x - eje.x):
					cerca = i
			if cerca >= 0 and absf(sin_luz[cerca].x - eje.x) < 1.0:
				sin_luz.remove_at(cerca)
				_luz_esquina(farol * Vector3(0.0, -0.13, 0.0) + hacia * 0.12)
	for fuego in sin_luz:
		_luz_esquina(fuego + Vector3(signf(2.0 - fuego.x) * 0.15, 0.32, -0.1))
	# El pescante de los escudos.
	var pie := Vector3(PESCANTE_PIE.x, _h_borde, PESCANTE_PIE.z)
	var bp := _base_hacia(PESCANTE_HACIA - PESCANTE_PIE)
	_fijo("pescante", hierro, Transform3D(bp, pie), "colgado")
	var farol := Transform3D(bp, pie + bp * Vector3(0.0, PESCANTE_ALTO - 0.04, PESCANTE_LARGO))
	var llama := _farol(farol, hierro, "colgado")
	_llama_colgada = llama
	# La luz, dentro del farol: alumbra los escudos desde delante y desde arriba.
	_luces.append(_mundo.luz_fuego(farol * Vector3(0.0, -0.12, 0.0), 0.85, 1.5))

## Un farol colgado de su argolla en `xf`, con su vela dentro. Devuelve el
## índice de su llama en las chicas.
func _farol(xf: Transform3D, hierro: Material, grupo: String) -> int:
	_fijo("farol", hierro, xf, grupo)
	var donde := xf * Vector3(0.0, FAROL_PLATO, 0.0)
	var b := Basis(Vector3.UP, _azar.randf() * TAU).scaled(Vector3.ONE * 0.75)
	if grupo == "colgado":
		_vela_colgada = _velas[0].size()
		_xf_vela_colgada = Transform3D(b, donde)
	_velas[0].append(Transform3D(b, donde))
	return _llama(_llamas_chicas, donde + Vector3.UP * (ALTO_VELA[0] * 0.75 + 0.006), 0.026, 0.06)

# ------------------------------------------------------------------- las velas

## Las velas de todo el módulo (hornacinas, cornisa, candelabros y faroles), un
## MultiMesh por tipo, más los charcos de cera. Todas con la cera mate.
func _montar_velas() -> void:
	var capa_antes := _capa
	_capa = Nucleo.CAPA_SIN_REFLEJO
	for t in 3:
		var lista: Array[Transform3D] = []
		lista.assign(_velas[t])
		if not lista.is_empty():
			var mmi := _repetir(_malla("vela_%d" % t), _cera, lista)
			if t == 0:
				_mm_velas_0 = mmi.multimesh
	if not _charcos.is_empty():
		_repetir(_malla("cera_charco"), _cera, _charcos)
	_capa = capa_antes

# ------------------------------------------------------------------- las llamas

func _malla_llama() -> ArrayMesh:
	var v := PackedVector3Array([Vector3(-0.5, 0.0, 0.0), Vector3(0.5, 0.0, 0.0),
		Vector3(0.5, 1.0, 0.0), Vector3(-0.5, 1.0, 0.0)])
	var uv := PackedVector2Array([Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)])
	var n := PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 2, 1, 0, 3, 2])
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m

func _material_llama(energia: float, prisa: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = LLAMA
	m.set_shader_parameter("tex_ruido", RUIDO)
	m.set_shader_parameter("color_borde", Paleta.ROJO_LUZ.lerp(Paleta.ROJO, 0.5))
	m.set_shader_parameter("color_cuerpo", Paleta.NARANJA)
	m.set_shader_parameter("color_corazon", Paleta.ORO.lerp(Paleta.NARANJA, 0.25))
	m.set_shader_parameter("color_nucleo", Paleta.ORO_CLARO.lerp(Paleta.TIERRA_6, 0.45))
	m.set_shader_parameter("energia", energia)
	m.set_shader_parameter("prisa", prisa)
	return m

## Las llamas, en tres MultiMesh: las grandes (antorchas y braseros), las de las
## velas y faroles (más apagadas: son
## puntos) y las de los cirios de la carga (que se encienden y se apagan una a
## una).
func _montar_llamas() -> void:
	# LAS GRANDES TAMPOCO VAN AL REFLEJO (decisión 5 de la revisión 2). Una
	# antorcha del ábside, a 1,1 de alto, se refleja con la cámara RASANTE justo
	# debajo de las lápidas (z ≈ 8,5), en mitad del recorrido de la bola: un óvalo
	# crema con una llama dentro, del tamaño de la bola y más claro que ella. Los
	# braseros de las esquinas caen en el borde del campo y harían lo mismo en
	# pequeño. El suelo mojado sigue cogiendo el brillo de sus LUCES.
	_mm_grandes = _llamas_en(_llamas_grandes, 1.0, Nucleo.CAPA_SIN_REFLEJO)
	_mm_chicas = _llamas_en(_llamas_chicas, 1.5, Nucleo.CAPA_SIN_REFLEJO, 1.0)
	_mm_cirios = _llamas_en(_llamas_cirios, 1.3, Nucleo.CAPA_SIN_REFLEJO, 1.5)
	if _mm_cirios != null:
		for i in _mm_cirios.instance_count:
			var c := _mm_cirios.get_instance_custom_data(i)
			_mm_cirios.set_instance_custom_data(i, Color(c.r, 0.0, 1.0, 0.0))

func _llamas_en(lista: Array[Dictionary], prisa: float, capa: int, energia: float = 1.3) -> MultiMesh:
	if lista.is_empty():
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _malla_llama()
	mm.instance_count = lista.size()
	for i in lista.size():
		var d := lista[i]
		var b := Basis.from_scale(Vector3(float(d["ancho"]), float(d["alto"]), 1.0))
		mm.set_instance_transform(i, Transform3D(b, d["pos"]))
		mm.set_instance_custom_data(i, Color(_azar.randf() * 10.0, 0.0, 0.0, 0.0))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	# Las pequeñas, más deprisa: una llama pequeña tiembla más.
	mmi.material_override = _material_llama(energia, prisa)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# La lámina gira hacia la cámara en el sombreador: la caja de la malla
	# (plana) no la cubre.
	mmi.extra_cull_margin = 0.5
	mmi.layers = capa
	_mundo.add_child(mmi)
	_mios.append(mmi)
	return mm

## LOS CIRIOS DE LA CARGA. La campana cuelga donde la cámara de juego solo la
## ve con la bola arriba (con la bola abajo el borde de arriba del plano pasa a
## 0,77 de altura por su vertical, y por debajo de 0,75 ya taparía el fondo del
## campo: no hay altura que valga). Así que la carga se lee TAMBIÉN aquí: cuatro
## cirios en las albardillas, a los dos lados del fondo, que se encienden uno a
## uno de atrás adelante según se carga, arden altos y nerviosos armada,
## restallan con cada golpe del badajo y se apagan de golpe cuando la campana
## calla (la carga vuelve a cero).
## Son CIRIOS DE CERA (`cirio` del GLB): delgados, marfil sucio y mate, con
## chorretones de geometría y la copa honda. Antes eran la vela grande
## escalada a 1,5 × 1,7 —un tubo de 6 cm— con la cera naranja: se leían como
## conos de tráfico.
func _montar_cirios() -> void:
	var cirios: Array[Transform3D] = []
	# Sus charcos van con los de las velas (`_charcos`): un MultiMesh menos.
	var charcos := _charcos
	for k in CIRIOS_Z.size():
		for lado: float in [-1.0, 1.0]:
			var base := Vector3(2.0 + lado * CIRIOS_X, _h_borde, CIRIOS_Z[k])
			var alto := 1.0 - 0.08 * float(k) + _azar.randf_range(-0.05, 0.05)
			var b := Basis(Vector3.UP, _azar.randf() * TAU).scaled(Vector3(1.0, alto, 1.0))
			cirios.append(Transform3D(b, base + Vector3.UP * 0.002))
			charcos.append(Transform3D(Basis(Vector3.UP, _azar.randf() * TAU).scaled(Vector3(0.45, 1.0, 0.45)), base))
			var punta := base + Vector3.UP * (ALTO_CIRIO * alto + 0.008)
			# Más grande que la de una vela de hornacina: se tiene que contar desde
			# la cámara de juego, a siete unidades. Pero no una antorcha.
			_llama(_llamas_cirios, punta, 0.045, 0.12)
	_repetir(_malla("cirio"), _cera, cirios)

## Cuánto arde cada cirio: se encienden en el orden en que se montaron (los dos
## de atrás, luego los de delante), y cada uno CRECE desde la mecha en su
## parte de la carga.
func _avivar_cirios(t: float, carga: float, armada: bool, tocando: bool, queda: float) -> void:
	if _mm_cirios == null:
		return
	var n := _mm_cirios.instance_count
	for i in n:
		var c := _mm_cirios.get_instance_custom_data(i)
		var viva := clampf(carga * float(n) - float(i), 0.0, 1.0)
		var aviva := 0.0
		if armada:
			viva = 1.0
			aviva = 0.35 + 0.25 * sin(t * 9.0 + float(i) * 1.7)
		elif tocando:
			viva = 0.55 + 0.45 * queda
			aviva = _aviva * 0.8
		_mm_cirios.set_instance_custom_data(i, Color(c.r, aviva, 1.0 - viva, 0.0))

# ------------------------------------------------------------- las señales

## El tirón de la cuerda: la campana arranca desde donde esté ladeada.
func _al_empezar_descarga(_punto: Vector2, _segundos: float) -> void:
	var lado := -signf(_th) if absf(_th) > 0.02 else 1.0
	_w += lado * 2.2
	_destello = 1.0

func _al_cambiar_carga(_fraccion: float, armada: bool) -> void:
	_destello = maxf(_destello, 0.7 if armada else 0.35)

func _al_golpear_bumper(_punto: Vector2, fuerza: float) -> void:
	var f := clampf(fuerza / 900.0, 0.25, 1.0)
	_w += _azar.randf_range(-1.0, 1.0) * 0.22 * f
	_wf += _azar.randf_range(-1.0, 1.0) * 0.6 * f
	if _carga_apagada() and _toque_propio <= 0.0:
		_carga_propia = minf(_carga_propia + 1.0 / float(GOLPES_SIN_CARGA), 1.0)
		if _carga_propia >= 1.0:
			_carga_propia = 0.0
			_toque_propio = TOQUE_SIN_CARGA
			_al_empezar_descarga(Vector2.ZERO, TOQUE_SIN_CARGA)

## ÓRBITA apagaba la barra con una carga imposible: así se sabe que está apagada.
func _carga_apagada() -> bool:
	return _mesa.p.carga_entradas > 1.0e5

# ------------------------------------------------------------------ la calidad

## 0 ALTA, 1 MEDIA, 2 BAJA (decisión 8). En MEDIA la campana deja de hacer
## sombra (la sombra de fuego ya no existe ahí); en BAJA se apaga además lo
## menudo de la sala, que está en la niebla. Lo que se ve junto al campo
## —cirios, faroles, braseros, el ábside— es igual en las tres.
func calidad(n: int) -> void:
	_calidad = n
	if is_instance_valid(_bronce_malla):
		_bronce_malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if n == 0 \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for nodo in _detalle:
		if is_instance_valid(nodo):
			nodo.visible = n < 2

# ------------------------------------------------------------------ cada cuadro

func actualizar(delta: float) -> void:
	if _campana == null:
		return
	var t := _mundo.tiempo
	_destello = maxf(_destello - delta * 2.2, 0.0)
	_aviva = maxf(_aviva - delta * 2.5, 0.0)

	# EL ESTADO, leído de la mesa (o de la cuenta propia si no hay carga).
	var carga := _mesa.carga
	var armada := _mesa.descarga_armada
	var queda := 0.0
	if _mesa.descarga_restante > 0.0:
		queda = _mesa.descarga_restante / maxf(_mesa.p.descarga_tiempo, 0.1)
	if _carga_apagada():
		_toque_propio = maxf(_toque_propio - delta, 0.0)
		carga = _carga_propia
		armada = false
		queda = _toque_propio / TOQUE_SIN_CARGA
	var tocando := queda > 0.0

	_pendulo(delta, carga, armada, tocando, queda)

	# Armada tiembla: está tirando de la cuerda y no la sueltan.
	var temblor := 0.0
	if armada and not tocando:
		temblor = 0.018 * sin(t * 37.0) + 0.011 * sin(t * 53.0 + 1.3)
	_campana.rotation.z = _th + temblor
	_campana.position.x = temblor * 0.05
	_badajo.rotation.z = _fi - _th

	_encender(t, delta, carga, armada, tocando, queda)
	_avivar_cirios(t, carga, armada, tocando, queda)
	# El resplandor del suelo: solo armada. Tocando se apaga, que la onda del
	# tañido ya dice lo suyo y las dos juntas eran ruido.
	_f_resplandor = move_toward(_f_resplandor, 1.0 if armada and not tocando else 0.0,
		delta * ENTRA_RESPLANDOR)
	if _resplandor != null:
		_resplandor.visible = _f_resplandor > 0.01
		_mat_resplandor.set_shader_parameter("fuerza", _f_resplandor)
	if tocando:
		_avivar_campo(AVIVA_TOCANDO * (0.5 + 0.5 * queda))
	_desvanecer()
	# Desde la cenital, sin carga, las tres cenefas apagadas eran unos aros
	# oscuros encima del brasero de arriba que tapaban una pieza golpeable sin
	# decir nada (la crítica de juego: «un halo sobre el brasero»). Solo se
	# quedan cuando dicen algo.
	var dicen := carga > 0.001 or armada or tocando
	for cen in _cenefas:
		cen.visible = not _desde_arriba or dicen
	if _mm_grandes != null and _aviva > 0.001:
		for i in _mm_grandes.instance_count:
			var c := _mm_grandes.get_instance_custom_data(i)
			_mm_grandes.set_instance_custom_data(i, Color(c.r, _aviva, 0.0, 0.0))
	elif _mm_grandes != null and _aviva <= 0.001 and _mm_grandes.instance_count > 0 \
			and _mm_grandes.get_instance_custom_data(0).g > 0.0:
		for i in _mm_grandes.instance_count:
			var c := _mm_grandes.get_instance_custom_data(i)
			_mm_grandes.set_instance_custom_data(i, Color(c.r, 0.0, 0.0, 0.0))

## LOS FUEGOS DEL CAMPO, AVIVADOS (decisión 9). Son los que pidieron otros
## módulos (los braseros de engranaje de «piezas», la luz de la zona de palas
## de «entorno»): se buscan en `mundo.fuegos()` por dónde están —dentro del
## campo y a ras de suelo—, en cada cuadro, porque se dan de alta después de
## este módulo y alguno se puede ir. `avivar` se queda con el mayor, así que
## llamarlo cada cuadro los mantiene arriba sin acumular.
func _avivar_campo(cuanto: float) -> void:
	for ficha: Dictionary in _mundo.fuegos():
		var que: Variant = ficha.get("luz")
		if not is_instance_valid(que):
			continue
		var luz: OmniLight3D = que
		var p := luz.global_position
		if p.x > 0.1 and p.x < 3.9 and p.z > 5.6 and p.z < 12.8 and p.y < 0.9:
			_mundo.avivar(luz, cuanto)

## EL PÉNDULO. La campana es un péndulo amortiguado de verdad alrededor de su
## punto de equilibrio: cargando, ese punto se ladea con la carga (la cuerda
## tensa); tocando, vuelve a plomo y alguien tira de la cuerda a cada vuelta
## para llevarla a la amplitud que toca (la energía decide, no un seno). El
## badajo es otro péndulo colgado de ella, más corto: se queda atrás, y cuando
## se separa `TOPE_BADAJO` da en el labio y rebota.
func _pendulo(delta: float, carga: float, armada: bool, tocando: bool, queda: float) -> void:
	var w2 := pow(TAU / PERIODO_CAMPANA, 2.0)
	var wb2 := pow(TAU / PERIODO_BADAJO, 2.0)
	var eq := carga * LADEO_ARMADA
	var amort := 1.6
	var meta := 0.0
	if tocando:
		eq = 0.0
		amort = 0.15
		meta = AMPLITUD_TOQUE * (0.35 + 0.65 * queda)
	elif armada:
		eq = LADEO_ARMADA
	var pasos := 4
	var h := minf(delta, 0.05) / float(pasos)
	for _i in pasos:
		var a := -w2 * sin(_th - eq) - amort * _w
		if meta > 0.0:
			var energia := 0.5 * _w * _w + w2 * (1.0 - cos(_th))
			var amp := acos(clampf(1.0 - energia / w2, -1.0, 1.0))
			var sentido := signf(_w) if absf(_w) > 0.05 else 1.0
			a += clampf((meta - amp) * 10.0, -5.0, 7.0) * sentido
		_w += a * h
		_th += _w * h
		# El badajo cuelga de un punto de la campana que se mueve con ella: la
		# aceleración de ese punto lo empuja al revés.
		var ab := -wb2 * sin(_fi) - 0.5 * _wf - a * (BAJA_BADAJO / LARGO_BADAJO) * cos(_fi - _th)
		_wf += ab * h
		_fi += _wf * h
		var rel := _fi - _th
		if absf(rel) > TOPE_BADAJO:
			var lado := signf(rel)
			_fi = _th + lado * TOPE_BADAJO
			var vr := _wf - _w
			if vr * lado > 0.0:
				_wf = _w - vr * 0.3
				_golpe_badajo(absf(vr))

## El badajo da en el labio. Un golpe flojo (un búmper) es un destello; uno de
## verdad suelta polvo de la campana, aviva el fuego y deja UNA ONDA DE POLVO
## DORADO A RAS DE SUELO desde la vertical de la campana, tan ancha que cruza el
## campo (decisión 9). Antes la onda salía a la altura de la boca de la campana
## (1,27 sobre el suelo), donde la cámara de juego no mira: el campo se quedaba
## igual que antes de tocar (la crítica de juego lo midió 0,2 s después).
func _golpe_badajo(fuerza: float) -> void:
	if fuerza < 0.4:
		return
	_destello = maxf(_destello, clampf(fuerza / 2.5, 0.25, 1.0))
	if fuerza < 1.2:
		return
	var lado := signf(_fi - _th)
	var boca := EJE_CAMPANA + Vector3(sin(_th) * 0.62 + lado * 0.28 * cos(_th), -cos(_th) * 0.62, 0.0)
	var en_mesa := Vector2(boca.x, boca.z) / Nucleo.E
	_mundo.chispear(en_mesa, boca.y, Paleta.PIEDRA_3, 5)
	var suelo := Vector2(EJE_CAMPANA.x, EJE_CAMPANA.z) / Nucleo.E
	_mundo.onda(suelo, _mundo.altura_en(suelo) + 0.02, Paleta.ORO,
		ONDA_TANIDO * (0.8 + 0.2 * clampf(fuerza / 3.0, 0.0, 1.0)))
	_aviva = maxf(_aviva, 0.6)
	for luz in _luces:
		_mundo.avivar(luz, 0.18)
	_avivar_campo(0.3)
	_mundo.latir(0.25)

## LAS CENEFAS. Cargando se encienden de abajo arriba, cada una entera antes de
## la siguiente; armada laten las tres y el bronce se pone al rojo; tocando
## arden y se apagan con el tiempo que queda, y cada golpe las aviva.
func _encender(t: float, delta: float, carga: float, armada: bool, tocando: bool, queda: float) -> void:
	for i in _brasas_campana.size():
		var lleno := clampf(carga * 3.0 - float(i), 0.0, 1.0)
		var e := 0.0
		# `calor` es el tono de la banda: 0 ORO_OSCURO, 1 ORO.
		var calor := 0.15 + 0.35 * lleno
		# Ojo con pasarse: por encima de `TECHO_CENEFA` la curva de tono lleva el
		# ámbar a crema y la cenefa parece un tubo de neón, no metal fundido en un
		# surco. Lo que distingue armada de cargando es que LATE y que es más
		# dorada, no que queme. Y armada el tono no se mueve: late SOLO la
		# intensidad.
		if tocando:
			e = 0.7 + 0.3 * queda + _destello * 0.35
			calor = 0.6 + 0.25 * queda + 0.15 * _destello
		elif armada:
			e = 0.8 + 0.28 * sin(t * 7.5 - float(i) * 0.9) + _destello * 0.25
			calor = 0.75
		elif lleno > 0.0:
			e = 0.3 + 0.6 * lleno + _destello * 0.4 * lleno
		_brasas_campana[i].set_shader_parameter("energia", minf(e, TECHO_CENEFA))
		_brasas_campana[i].set_shader_parameter("calor", clampf(calor, 0.0, 1.0))
	if _bronce != null:
		# El bronce en reposo: menos metal, más difuso (ver `METAL_REPOSO`).
		# Cargando cuenta como reposo: la primera rampa ya deja un tercio de carga
		# y la campana se ve así casi siempre (la toma del ábside de la gira, al
		# 21 %). Solo armada y tocando vuelven al metal de la biblioteca.
		var reposo := 0.0 if (armada or tocando) else 1.0
		_f_reposo = move_toward(_f_reposo, reposo, delta * CAMBIA_REPOSO)
		_bronce.set_shader_parameter("metal", lerpf(_metal_bronce, METAL_REPOSO, _f_reposo))
		_bronce.set_shader_parameter("rugosidad", lerpf(_rugosidad_bronce, RUGOSIDAD_REPOSO, _f_reposo))
		var tibio := EMISION_REPOSO * _f_reposo
		# EL CUERPO ES BRONCE CON PÁTINA EN LOS TRES ESTADOS (decisión 4 de la
		# revisión 2). Antes armada se ponía «al rojo» (0,3-0,45 de emisivo
		# naranja) y se quemaba a dorado pulido: un farol de latón al lado de la
		# piedra gris. Ahora el cuerpo apenas se templa y solo el golpe del
		# badajo lo enciende un instante.
		var rojo := 0.0
		if tocando:
			rojo = 0.05 * queda + 0.22 * _destello
		elif armada:
			rojo = 0.04 + 0.02 * sin(t * 7.5)
		else:
			rojo = 0.03 * carga + 0.08 * _destello * carga
		_bronce.set_shader_parameter("emision", rojo + tibio)

## Vista a plomo (la cámara cenital), la campana y su viga caen encima de los
## braseros y tapan la bola, y el farol de los escudos vuela sobre el carril de
## la derecha. Se esconden, y de la campana quedan SOLO las tres cenefas: desde
## arriba son tres aros finos de fuego flotando sobre los braseros, que no tapan
## nada y siguen diciendo cuánto lleva cargado.
## PROBADO Y DESCARTADO: `GeometryInstance3D.transparency`. En Compatibility no
## hace nada con estos materiales: en las capturas cenitales la viga y la
## campana salían igual de opacas con 0,82 que con 0,92 (y la cámara era la
## buena: se comprobó imprimiéndola).
func _desvanecer() -> void:
	var cam := _mundo.get_viewport().get_camera_3d()
	var arriba := cam != null and cam.global_transform.basis.z.y > 0.9
	if arriba == _desde_arriba:
		return
	_desde_arriba = arriba
	for gi in _piezas_campana:
		if is_instance_valid(gi):
			gi.visible = not arriba
	for gi in _colgado:
		if is_instance_valid(gi):
			gi.visible = not arriba
	# La llama y la vela del farol de los escudos van en MultiMesh compartidos:
	# se apagan por su índice.
	if _mm_chicas != null and _llama_colgada >= 0 and _llama_colgada < _mm_chicas.instance_count:
		var c := _mm_chicas.get_instance_custom_data(_llama_colgada)
		_mm_chicas.set_instance_custom_data(_llama_colgada, Color(c.r, c.g, 1.0 if arriba else 0.0, 0.0))
	if _mm_velas_0 != null and _vela_colgada >= 0 and _vela_colgada < _mm_velas_0.instance_count:
		var xf := _xf_vela_colgada
		if arriba:
			xf = Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), xf.origin)
		_mm_velas_0.set_instance_transform(_vela_colgada, xf)

# ------------------------------------------------------------------- la medida

## Con `--medir`: lo que pone este módulo, para el presupuesto de la decisión 7
## (atrezzo ≤ 120.000 triángulos de malla en una pasada).
func _contar() -> void:
	var cuenta := {"mallas": 0, "tri": 0, "sombra": 0, "reflejo": 0}
	var gordas: Array[String] = []
	for gi in _mios:
		if is_instance_valid(gi):
			_contar_en(gi, cuenta, gordas)
	print("ATREZZO medida: %d mallas, %d triángulos (%d con sombra, %d en el reflejo)" % [
		cuenta["mallas"], cuenta["tri"], cuenta["sombra"], cuenta["reflejo"]])
	for g in gordas:
		print("ATREZZO   ", g)

func _contar_en(gi: GeometryInstance3D, cuenta: Dictionary, gordas: Array[String]) -> void:
	var tri := 0
	var malla: Mesh = null
	var veces := 1
	if gi is MeshInstance3D:
		malla = (gi as MeshInstance3D).mesh
	elif gi is MultiMeshInstance3D and (gi as MultiMeshInstance3D).multimesh != null:
		malla = (gi as MultiMeshInstance3D).multimesh.mesh
		veces = (gi as MultiMeshInstance3D).multimesh.instance_count
	if malla != null:
		for s in malla.get_surface_count():
			var arr := malla.surface_get_arrays(s)
			var nv := (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			var ni := 0
			if arr[Mesh.ARRAY_INDEX] != null:
				ni = (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size()
			tri += (ni if ni > 0 else nv) / 3
	tri *= veces
	cuenta["mallas"] = int(cuenta["mallas"]) + 1
	cuenta["tri"] = int(cuenta["tri"]) + tri
	if gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
		cuenta["sombra"] = int(cuenta["sombra"]) + tri
	if (gi.layers & 1) != 0:
		cuenta["reflejo"] = int(cuenta["reflejo"]) + tri
	if tri >= 3000:
		var nombre := "?"
		if gi.material_override != null:
			nombre = gi.material_override.resource_name
		gordas.append("%6d  %s ×%d  %s" % [tri, nombre, veces, str(gi.global_position.snapped(Vector3.ONE * 0.01))])
