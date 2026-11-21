extends RefCounted

## CRIPTA 3D · MÓDULO «railes» · LOS RECORRIDOS
##
## QUÉ MONTA: los RECORRIDOS de `mesa.rampas`. Una rampa es una CURVA (`r.puntos`,
## en píxeles de mesa): la bola se engancha en su boca, la recorre y sale por la
## otra punta. Aquí se le pone cuerpo de hierro y latón, como los raíles de las
## vagonetas de una mina, y cada recorrido tiene su manera de estar hecho:
##
##   CAMPANARIO (`lanzadera`)  raíl de vagoneta: dos carriles de latón donde rueda
##                             la bola, dos guardarraíles encima, traviesas de
##                             hierro, aros que lo abrazan cada tanto con sus
##                             bombillas, y escuadras clavadas a las paredes
##   TOBOGÁN (`cometa`)        el mismo raíl, colgado de escuadras de hierro por
##                             fuera de la banda izquierda y de la viga de la
##                             campana mayor donde cruza el campo
##   CORO (`estacion`)         un PUENTECILLO: tablero de roble, largueros de
##                             hierro y barandilla de latón sobre balaustres
##   ESCALERA (`bajada`)       el raíl estrecho que baja de la tribuna: arriba,
##                             con barandilla; sobre el campo, ABIERTA (ver abajo)
##   GALERÍA (`orbita`)        a ras de suelo: un canal de losas con sus bordillos
##                             de piedra rematados de latón
##   CATACUMBA (`gusano`)      no se ve el recorrido, solo sus dos BOCAS: una
##                             trampilla con su arco de dovelas, la reja de hierro
##                             sobre el hueco y, al fondo, el resplandor arcano
##
##   Y delante de cada boca que se puede acertar, una PLACA de hierro con una
##   flecha de bombillas ámbar (los sprites `flecha_on`/`flecha_off`).
##
##   Y donde un raíl de vagoneta acaba cayendo a pique a otra planta (el tobogán
##   sobre la inlane izquierda, el campanario sobre los braseros), NO baja con sus
##   tubos hasta el suelo: acaba antes, en un LABIO de latón —una cubeta con el
##   borde vuelto— y la bola salta de él. Antes los cuatro tubos se doblaban hasta
##   la losa por encima de la inlane: «fideos» que tapaban la bola justo cuando
##   baja a la pala y no dejaban ver por dónde salía el recorrido.
##
## LAS LUCES
##   · Las bombillas de un recorrido se encienden EN CADENA con la bola: de la boca
##     hasta donde va, apagándose detrás. Las lleva `railes_bombilla.gdshader`,
##     UN SOLO MATERIAL para todas: cada bombilla dice en `UV2.y` de qué guía es, y
##     el estado de cada guía va en listas (`_estado`). Las acompaña una luz
##     ámbar que viaja con la bola por dentro del raíl.
##   · La flecha encendida deja un charco ámbar en la losa (`railes_charco.gdshader`,
##     un cuadro aditivo: no es una luz más).
##   · La flecha corre siempre despacio hacia su boca; con la CAMPANA ARMADA
##     (`mesa.descarga_armada`: el próximo recorrido completo la hace tocar) corre
##     deprisa y más fuerte; al entrar la bola, destello.
##
## SEÑALES QUE ESCUCHA (de `mundo.mesa`)
##   rampa_entrada(punto, indice) → las guías de ESE recorrido se encienden
##                                  (bombillas y flecha); si es el túnel, la boca
##                                  de entrada se aviva
##   rampa_salida(punto, indice)  → si es el túnel, se aviva la boca de salida
## Y LEE EN CADA CUADRO: `mundo.caza.boca_cierre[k]` (> 0: esa boca está TAPADA
## para el espectro; se apaga y se queda en un rescoldo rojo), las bolas que van
## por un recorrido (`b.rampa`, `b.rampa_distancia`) y las criaturas ESCONDIDAS,
## que llevan una luz arcana corriendo por debajo del suelo de una boca a otra.
##
## FUNCIONES PÚBLICAS
##   encender_boca(boca: int)   0 = la entrada del túnel, 1 = la salida. La llama
##                              el núcleo cuando una criatura se esconde por ahí
##                              o va a asomar: es el AVISO que hace justo esperarla.
##
## LO QUE NO PUEDE DEJAR DE HACER QUIEN LO REESCRIBA
##   1. La altura del raíl es `mundo.altura_rampa(r, d)` y NADA más: la bola va
##      a esa misma altura (más su radio), calculada en el núcleo. Un raíl
##      dibujado a otra altura es una bola flotando o enterrada.
##   2. La bola mide 9 px de radio: los carriles de abajo a ±5 la sostienen, los de
##      arriba a ±11 la guardan. Más juntos, la atraviesan. Los aros y los
##      balaustres pasan a más de 9 px del centro de la bola (`_aro`).
##   3. `info_rampas[nombre]["lomo"]` dice cuánto se levanta cada recorrido. El
##      de la GALERÍA es 0: va por el suelo, y por encima de ella rueda la bola
##      cuando no la ha enganchado, así que ahí no cabe nada de más de 0,025.
##   4. Las guías SE ENCIENDEN AL ENTRAR y se apagan solas: es lo que le dice al
##      jugador que el tiro ha entrado antes de ver la bola.
##   5. El material que se anima se DUPLICA o es propio: cada recorrido tiene el
##      suyo. El arcano de la biblioteca se anima con "energia" y "tinte".
##   6. Lo grande se parte, pero POR SITIO y no por recorrido: la mesa se corta
##      en celdas (`CELDA_X` × `CELDA_Y`) y todo lo de los raíles que cae en una
##      celda —de cualquier recorrido— va en UNA malla, con una superficie por
##      material (Compatibility da 8 luces por malla, así que no se puede hacer
##      una sola). Antes eran 78 mallas sueltas, una por recorrido, trozo y
##      material, y cada una se dibujaba en la vista, en el reflejo y en dos
##      cortes de sombra: unas 300 llamadas de dibujo solo de raíles.
##      Y lo que va a ras de suelo va en mallas aparte, FUERA DEL REFLEJO (su
##      reflejo cae encima de sí mismo): mezclado con lo alto, la malla entera
##      entraría en el reflejo.
##   7. `encender_boca` y el estado TAPADA son la mitad de la mecánica del
##      espectro: sin ellos no se sabe por dónde va a salir ni qué boca le has
##      cerrado. El arcano es SOLO para esto (`LEEME.md`).
##   8. Las bocas del túnel y las placas de flecha están en el suelo, por donde
##      pasan la bola y las criaturas: nada de más de 0,025.
##   9. NINGÚN APOYO PISA EL CAMPO. Un pie en el tablero es un poste que la bola
##      atraviesa. Los pies y las escuadras salen de lo que ya es sólido en la
##      simulación —las paredes (`colisionadores` de tipo PARED) y la falda del
##      coro—, y lo que cruza el campo cuelga de la viga de la campana mayor.
##  10. LOS RAÍLES NO HACEN SOMBRA. La luna era una direccional que proyectaba
##      cada tubo como una raya sobre las losas: un campo a rayas donde la bola,
##      a 25 px, no se distinguía de un borde de sombra. Ahora la luna es un foco
##      sin sombra, y aquí se apaga además la de cada malla.
##  11. LA ESCALERA, DONDE VUELA MÁS BAJA QUE UNA CRIATURA (`H_ABIERTA`), VA
##      ABIERTA: dos carriles finos y un travesaño cada `PASO_PELDANO`, sin
##      barandilla ni postes. Era un peldañado cada 9 px de 24 px de ancho sobre
##      el tercio derecho del campo —donde viven la catacumba y las criaturas—:
##      una persiana que dejaba ver la bola y los bichos a través de barrotes, y
##      la calavera y el espectro la atravesaban (bajan del coro a 0,35).

const Nucleo := preload("res://cripta3d/mundo_cripta.gd")
const MesaCripta := preload("res://cripta3d/mesa_cripta.gd")
const Criatura := preload("res://prueba3d/criatura.gd")
const BOMBILLA: Shader = preload("res://cripta3d/mundo/railes_bombilla.gdshader")

const CHARCO: Shader = preload("res://cripta3d/mundo/railes_charco.gdshader")

## Cada cuántos píxeles de curva se toma una muestra del raíl. Con 4 la curva no
## se veía más redonda y los tubos eran un tercio más de triángulos.
const PASO := 6.0
## LAS CELDAS en que se parte la obra, en píxeles de mesa (ver la regla 6). Con
## 3 × 4 celdas una malla mide como mucho 1,35 × 1,85 unidades: lo que medía un
## trozo de antes, que es lo que deja a cada una con menos de 8 fuegos encima.
const CELDA_X := 135.0
const CELDA_Y := 185.0
const Y_CELDA0 := 560.0
## Por debajo de esta altura, una pieza es suelo: va en las mallas sin reflejo.
const H_SUELO := 0.03
## Las guías del material de las bombillas: el índice del recorrido, y el de su
## flecha, ese mismo más `GUIA_FLECHA`. Tiene que caber en las listas del
## sombreador (16).
const GUIA_FLECHA := 8
const N_GUIAS := 16
## LA ESCALERA: por debajo de esta altura una criatura (que mide unos 0,35) pasa
## por dentro del raíl, y ahí va abierta (regla 11). Un travesaño cada tanto.
const H_ABIERTA := 0.36
const PASO_PELDANO := 34.0
## EL LABIO: un raíl de vagoneta cuya última caída pasa de `CAIDA_LABIO` en sus
## últimos 70 px acaba en un labio a `H_LABIO` por encima de donde cae la bola.
const CAIDA_LABIO := 0.30
const H_LABIO := 0.20
## La cubeta del labio: media anchura en píxeles (abraza los dos carriles, que
## van a ±5) y su borde sobre la altura del raíl. Pequeña a propósito: con 21 px
## de ancho y 18 de largo, en la caída del tobogán se leía como una pala de
## recoger, de cara a la cámara.
const LADO_LABIO := 7.8
const Y_LABIO := 0.016

## La sección del raíl, en unidades 3D. Los carriles van con el centro a
## `Y_CARRIL` sobre la altura del recorrido; los guardarraíles a `Y_GUARDA`.
const Y_CARRIL := 0.0045
const R_CARRIL := 0.0115
const Y_GUARDA := 0.10
const R_GUARDA := 0.0100
const LADO_CARRIL := 5.0
const LADO_GUARDA := 11.0

## Hasta dónde busca un apoyo una pared, en píxeles, y cuánto tiene que haber
## entre lo alto de la pared y el raíl para que quepa una escuadra.
const ALCANCE_ESCUADRA := 46.0
const PIE_DIRECTO := 7.0

## LA VIGA DE LA CAMPANA MAYOR (la monta «atrezzo»; estos números son el
## contrato del encargo): de ella cuelgan los raíles donde cruzan el campo.
const VIGA_Z := 7.42
const VIGA_Y := 1.95
const VIGA_X0 := 0.45
const VIGA_X1 := 2.55

const RADIO_BOCA := 17.0
## A cuántos píxeles de su boca va la placa de la flecha, por recorrido. Pegada a
## la lengüeta de la boca (que llega a 13 px de ella; la placa mide 37 de largo):
## a 44 y 50 px, desde la cámara de juego no se sabía qué boca anunciaba cada una.
## La de la galería va más lejos para no caer encima del torno, que está EN su
## boca; la de la catacumba, lo justo para no pisar el umbral (23 px).
## OJO: «suelo» tiene esta tabla copiada para sus cheurones de latón.
const DIST_FLECHA := {"orbita": 66.0, "cometa": 34.0, "estacion": 36.0, "gusano": 44.0}
## Por lo que se multiplica el violeta de una boca tapada para dejarlo en rojo.
const TINTE_TAPADA := Color(1.0, 0.22, 0.18)
const COLOR_BOMBILLA := Color(1.0, 0.62, 0.26)

## La flecha de bombillas, en píxeles: (a lo largo, de lado), con la punta hacia
## la boca. Un astil de una fila y la cabeza en cheurón, mucho más ancha que el
## astil: con el astil de dos filas (como el sprite, que es de 64 px) a este
## tamaño se leía una casita.
const FLECHA_BOMBILLAS: Array[Vector2] = [
	Vector2(-13.0, 0.0), Vector2(-9.0, 0.0), Vector2(-5.0, 0.0), Vector2(-1.0, 0.0),
	Vector2(1.5, 8.5), Vector2(1.5, -8.5), Vector2(5.0, 5.7), Vector2(5.0, -5.7),
	Vector2(8.5, 2.9), Vector2(8.5, -2.9), Vector2(12.0, 0.0), Vector2(3.5, 0.0),
]

var _mundo: Nucleo
var _mesa: MesaCripta
var _mat: Dictionary = {}

## nombre del recorrido → {flecha (bool), impulso, cadena, cabeza, indice, luz,
## rampa}
var _guias: Dictionary = {}
## El material de TODAS las bombillas y el de los charcos de las flechas, y lo
## que se les pasa cada cuadro: una casilla por guía (ver `GUIA_FLECHA`).
var _luces: ShaderMaterial
var _charco: ShaderMaterial
var _reposo := PackedFloat32Array()
var _corre := PackedFloat32Array()
var _velocidad := PackedFloat32Array()
var _cadena := PackedFloat32Array()
var _cabeza := PackedFloat32Array()
var _fogonazo := PackedFloat32Array()
var _luz_charco := PackedFloat32Array()
## La guía de lo que se está construyendo: va en `UV2.y` de cada bombilla.
var _guia := 0.0
## Las bocas de túnel: {mat, luz, activo, tapada}. Y nombre → índice de su entrada.
var _bocas: Array[Dictionary] = []
var _boca_de: Dictionary = {}
## Las paredes donde se puede clavar un apoyo: {a, b, alto}.
var _paredes: Array[Dictionary] = []
## Lo que se está construyendo: "grupo|celda" → {material → SurfaceTool}. El
## grupo es «a» (alto: entra en el reflejo) o «s» (a ras de suelo: no entra).
var _obra: Dictionary = {}
## El «orden» que se escribe en UV2 (solo las bombillas lo llevan).
var _orden := -1.0
## Multiplica la oclusión (R) de lo que se construye: lo que va debajo de otra
## cosa se oscurece aquí y no en el material.
var _sombra := 1.0
## La luz que corre por debajo del suelo con la criatura escondida.
var _luz_tunel: OmniLight3D

func montar(mundo: Node3D) -> void:
	_mundo = mundo as Nucleo
	_mesa = _mundo.mesa
	_preparar_materiales()
	_buscar_paredes()
	for i in mini(_mesa.rampas.size(), GUIA_FLECHA):
		var r := _mesa.rampas[i]
		_guias[r.nombre] = {"flecha": false,
			"impulso": 0.0, "cadena": 0.0, "cabeza": -10000.0, "indice": i,
			"luz": null, "rampa": r}
		_guia = float(i)
		if r.subterranea:
			_boca_de[r.nombre] = _bocas.size()
			_montar_boca(r, true)
			_montar_boca(r, false)
		else:
			_montar_recorrido(r)
		if DIST_FLECHA.has(r.nombre) and r.velocidad_minima < 100000.0:
			_guia = float(GUIA_FLECHA + i)
			_guias[r.nombre]["flecha"] = true
			_montar_flecha(r)
	_cerrar_obra()
	_luz_tunel = OmniLight3D.new()
	_luz_tunel.light_color = Paleta.ARCANO
	_luz_tunel.light_energy = 0.0
	_luz_tunel.omni_range = 0.6
	_luz_tunel.visible = false
	_mundo.add_child(_luz_tunel)
	_mesa.rampa_entrada.connect(_al_entrar)
	_mesa.rampa_salida.connect(_al_salir)

# ------------------------------------------------------------------ materiales

func _preparar_materiales() -> void:
	var m: Object = _mundo.mat
	_mat["laton"] = m.call("dame", "laton", {"vertice": true, "escala": 0.25})
	_mat["hierro"] = m.call("dame", "hierro", {"vertice": true, "escala": 0.22})
	_mat["madera"] = m.call("dame", "madera", {"vertice": true, "escala": 0.35})
	_mat["piedra"] = m.call("dame", "piedra", {"vertice": true, "juntas": Vector3.ZERO,
		"escala": 0.3, "tinte": Color(0.7, 0.68, 0.68), "suciedad": 0.65})
	_mat["losa"] = m.call("dame", "piedra", {"vertice": true, "juntas": Vector3.ZERO,
		"escala": 0.4, "tinte": Color(0.42, 0.42, 0.45), "mojado": 0.85, "semilla": 3.0})
	_mat["sillar"] = m.call("dame", "piedra", {"vertice": true, "juntas": Vector3.ZERO,
		"escala": 0.3, "tinte": Color(0.95, 0.9, 0.86), "suciedad": 0.5, "semilla": 7.0})
	_mat["oxido"] = m.call("dame", "oxido", {"vertice": true, "escala": 0.2,
		"tinte": Color(0.55, 0.5, 0.5)})
	_mat["bronce"] = m.call("dame", "bronce", {"vertice": true, "escala": 0.2})
	_mat["carbon"] = m.call("dame", "carbon", {"vertice": true})
	_luces = ShaderMaterial.new()
	_luces.shader = BOMBILLA
	_luces.set_shader_parameter("vidrio", Paleta.COBRE_1.darkened(0.45))
	_luces.set_shader_parameter("luz_ambar", Paleta.NARANJA.lerp(Paleta.ORO, 0.35))
	_luces.set_shader_parameter("luz_clara", Paleta.ORO_CLARO)
	_luces.set_shader_parameter("energia", 4.0)
	_luces.set_shader_parameter("periodo", 1.0)
	_charco = ShaderMaterial.new()
	_charco.shader = CHARCO
	_charco.set_shader_parameter("color", Paleta.NARANJA.lerp(Paleta.ORO, 0.45))
	# Las listas se dejan del tamaño de las del sombreador: una lista más corta
	# que la uniforme deja las casillas de más sin definir.
	_reposo.resize(N_GUIAS)
	_corre.resize(N_GUIAS)
	_velocidad.resize(N_GUIAS)
	_cadena.resize(N_GUIAS)
	_cabeza.resize(N_GUIAS)
	_fogonazo.resize(N_GUIAS)
	_luz_charco.resize(N_GUIAS)
	_cabeza.fill(-10000.0)
	_velocidad.fill(1.0)

func _propio(nombre: String) -> Material:
	var m: Material = _mundo.mat.call("dame", nombre)
	return m.duplicate() as Material if m != null else null

## Sube o baja lo que brilla un arcano: el parámetro "energia" de la biblioteca
## o, si ha entrado la de reserva, la emisión de un material liso. `tapada`
## (0..1) lo lleva del violeta al rojo: en la biblioteca con "tinte", que
## multiplica; en la de reserva, cambiando el color de la emisión.
func _encender(material: Material, energia: float, tapada: float = -1.0) -> void:
	var sombreado := material as ShaderMaterial
	if sombreado != null:
		sombreado.set_shader_parameter("energia", energia)
		if tapada >= 0.0:
			sombreado.set_shader_parameter("tinte", Color.WHITE.lerp(TINTE_TAPADA, tapada))
		return
	var liso := material as BaseMaterial3D
	if liso != null:
		liso.emission_energy_multiplier = energia
		if tapada >= 0.0:
			liso.emission = Paleta.ARCANO.lerp(Paleta.ROJO_LUZ, tapada)

# --------------------------------------------------------------- la obra: trozos

## Dónde se construye una pieza del recorrido `nombre` a `d` píxeles de su boca:
## en la celda de ese punto, y en el grupo que diga su altura.
func _st(nombre: String, d: float, material: String) -> SurfaceTool:
	var r: Rampa = _guias[nombre]["rampa"]
	var dd := clampf(d, 0.0, r.largo)
	return _st_p(_mundo.a3(r.punto_en(dd), _mundo.altura_rampa(r, dd)), material)

## Dónde se construye una pieza que está en `p` (unidades 3D).
func _st_p(p: Vector3, material: String) -> SurfaceTool:
	return _st_clave(_clave_p(p), material)

func _clave_p(p: Vector3) -> String:
	var cx := clampi(int(floor(p.x / Nucleo.E / CELDA_X)), 0, 2)
	var cy := clampi(int(floor((p.z / Nucleo.E - Y_CELDA0) / CELDA_Y)), 0, 3)
	return "%s|%d,%d" % ["s" if p.y < H_SUELO else "a", cx, cy]

func _st_clave(clave: String, material: String) -> SurfaceTool:
	if not _obra.has(clave):
		_obra[clave] = {}
	var celda: Dictionary = _obra[clave]
	if not celda.has(material):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		celda[material] = st
	return celda[material]

func _material_de(material: String) -> Material:
	if material == "luz":
		return _luces
	if material == "charco":
		return _charco
	if material.begins_with("arcano"):
		return _bocas[int(material.trim_prefix("arcano"))]["mat"]
	return _mat[material]

## Cuelga todo lo construido: UNA malla por celda y grupo, con una superficie por
## material. Ninguna hace sombra (regla 10), y las de a ras de suelo no entran en
## el reflejo (regla 6): se les pone la capa aquí, porque el núcleo solo saca del
## reflejo lo que queda entero por debajo de 0,03 y una celda de suelo puede
## llevar el arranque de un raíl que ya sube.
func _cerrar_obra() -> void:
	for clave: String in _obra:
		var celda: Dictionary = _obra[clave]
		var malla := ArrayMesh.new()
		for material: String in celda:
			var st: SurfaceTool = celda[material]
			st.commit(malla)
			malla.surface_set_material(malla.get_surface_count() - 1, _material_de(material))
		var mi := MeshInstance3D.new()
		mi.mesh = malla
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if clave.begins_with("s|"):
			mi.layers = Nucleo.CAPA_SIN_REFLEJO
		_mundo.add_child(mi)
	_obra.clear()

# -------------------------------------------------------- geometría: primitivas

## Un número de 0 a 1 que siempre es el mismo para la misma semilla.
static func _azar(n: float) -> float:
	return fposmod(sin(n * 127.1 + 311.7) * 43758.5453, 1.0)

func _color(normal: Vector3, canto: float) -> Color:
	var r := lerpf(0.5, 1.0, clampf(normal.y * 0.5 + 0.5, 0.0, 1.0)) * _sombra
	return Color(r, canto, 0.0)

func _v(st: SurfaceTool, p: Vector3, n: Vector3, c: Color) -> void:
	st.set_color(c)
	st.set_normal(n)
	if _orden >= 0.0:
		st.set_uv2(Vector2(_orden, _guia))
	st.add_vertex(p)

## Un triángulo con la cara vista hacia donde apuntan sus normales (la misma
## regla que `prueba3d/mallas_3d.gd`).
func _tri(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3,
		n0: Vector3, n1: Vector3, n2: Vector3, c0: Color, c1: Color, c2: Color) -> void:
	if (p1 - p0).cross(p2 - p0).dot(n0 + n1 + n2) > 0.0:
		_v(st, p0, n0, c0)
		_v(st, p2, n2, c2)
		_v(st, p1, n1, c1)
	else:
		_v(st, p0, n0, c0)
		_v(st, p1, n1, c1)
		_v(st, p2, n2, c2)

func _cuadro(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
		n0: Vector3, n1: Vector3, n2: Vector3, n3: Vector3,
		c0: Color, c1: Color, c2: Color, c3: Color) -> void:
	_tri(st, p0, p1, p2, n0, n1, n2, c0, c1, c2)
	_tri(st, p0, p2, p3, n0, n2, n3, c0, c2, c3)

## Una sección redonda: {p, n, g, facetas}. `g` es el canto de cada vértice.
func _sec_redonda(r: float, lados: int, canto: float = 0.3) -> Dictionary:
	var p := PackedVector2Array()
	var n := PackedVector2Array()
	var g := PackedFloat32Array()
	for k in lados:
		var a := TAU * float(k) / float(lados)
		var d := Vector2(cos(a), sin(a))
		p.append(d * r)
		n.append(d)
		g.append(canto)
	return {"p": p, "n": n, "g": g, "facetas": false}

## Una sección de pletina: un rectángulo de `ancho` × `alto` con los cuatro cantos
## achaflanados. Cada cara lleva sus dos vértices, para que el chaflán coja el
## brillo con filo y no se vea una barra de jabón. El chaflán es el canto (G).
func _sec_pletina(ancho: float, alto: float, chaflan: float) -> Dictionary:
	var a := ancho * 0.5
	var b := alto * 0.5
	var c := minf(chaflan, minf(a, b) * 0.6)
	var o: Array[Vector2] = [Vector2(a, -b + c), Vector2(a, b - c), Vector2(a - c, b),
		Vector2(-a + c, b), Vector2(-a, b - c), Vector2(-a, -b + c), Vector2(-a + c, -b),
		Vector2(a - c, -b)]
	var p := PackedVector2Array()
	var n := PackedVector2Array()
	var g := PackedFloat32Array()
	for i in 8:
		var e := o[(i + 1) % 8] - o[i]
		var nn := Vector2(e.y, -e.x).normalized()
		var canto := 0.9 if i % 2 == 1 else 0.25
		p.append(o[i])
		n.append(nn)
		g.append(canto)
		p.append(o[(i + 1) % 8])
		n.append(nn)
		g.append(canto)
	return {"p": p, "n": n, "g": g, "facetas": true}

## Barre una sección a lo largo de una línea 3D. El marco se lleva por
## transporte paralelo —se gira lo justo de un punto al siguiente—, así que una
## pletina no se retuerce en las curvas. `ref` dice hacia dónde mira el «alto» de
## la sección en el primer punto (por defecto, arriba).
func _barrer(st: SurfaceTool, pts: PackedVector3Array, sec: Dictionary,
		ref: Vector3 = Vector3.UP, tapas: bool = true) -> void:
	var n := pts.size()
	if n < 2:
		return
	var sp: PackedVector2Array = sec["p"]
	var sn: PackedVector2Array = sec["n"]
	var sg: PackedFloat32Array = sec["g"]
	var facetas: bool = sec["facetas"]
	var m := sp.size()
	var t0 := (pts[1] - pts[0]).normalized()
	var lat := t0.cross(ref)
	if lat.length_squared() < 1e-6:
		lat = t0.cross(Vector3.FORWARD)
	if lat.length_squared() < 1e-6:
		lat = t0.cross(Vector3.RIGHT)
	lat = lat.normalized()
	var t_antes := t0
	var anillos: Array[PackedVector3Array] = []
	var normales: Array[PackedVector3Array] = []
	var tangentes: Array[Vector3] = []
	for i in n:
		var t := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var eje := t_antes.cross(t)
		if eje.length_squared() > 1e-12:
			lat = lat.rotated(eje.normalized(), t_antes.angle_to(t))
		lat = (lat - t * lat.dot(t)).normalized()
		var alto := lat.cross(t).normalized()
		t_antes = t
		var anillo := PackedVector3Array()
		var nrm := PackedVector3Array()
		for k in m:
			anillo.append(pts[i] + lat * sp[k].x + alto * sp[k].y)
			nrm.append((lat * sn[k].x + alto * sn[k].y).normalized())
		anillos.append(anillo)
		normales.append(nrm)
		tangentes.append(t)
	for i in n - 1:
		var a0 := anillos[i]
		var a1 := anillos[i + 1]
		var n0 := normales[i]
		var n1 := normales[i + 1]
		var k := 0
		while k < m:
			var k2 := k + 1 if facetas else (k + 1) % m
			_cuadro(st, a0[k], a0[k2], a1[k2], a1[k], n0[k], n0[k2], n1[k2], n1[k],
				_color(n0[k], sg[k]), _color(n0[k2], sg[k2]),
				_color(n1[k2], sg[k2]), _color(n1[k], sg[k]))
			k += 2 if facetas else 1
	if not tapas:
		return
	for extremo: int in [0, n - 1]:
		var centro := pts[extremo]
		var nt: Vector3 = -tangentes[extremo] if extremo == 0 else tangentes[extremo]
		var anillo := anillos[extremo]
		var c := _color(nt, 0.7)
		for k in m:
			var k2 := (k + 1) % m
			if anillo[k].is_equal_approx(anillo[k2]):
				continue
			_tri(st, centro, anillo[k], anillo[k2], nt, nt, nt, c, c, c)

## Un torneado: el perfil (x = a lo largo del eje, y = radio) girado alrededor de
## `eje` desde `base`. Collarines, bombillas, copas, remaches, pies.
func _tornear(st: SurfaceTool, base: Vector3, eje: Vector3, perfil: PackedVector2Array,
		lados: int, canto: float = 0.4) -> void:
	eje = eje.normalized()
	var otro := Vector3.UP if absf(eje.y) < 0.95 else Vector3.RIGHT
	var u := eje.cross(otro).normalized()
	var w := eje.cross(u).normalized()
	var np := perfil.size()
	var nper := PackedVector2Array()
	for i in np:
		var tg := (perfil[mini(i + 1, np - 1)] - perfil[maxi(i - 1, 0)]).normalized()
		nper.append(Vector2(-tg.y, tg.x))
	for i in np - 1:
		for k in lados:
			var a0 := TAU * float(k) / float(lados)
			var a1 := TAU * float(k + 1) / float(lados)
			var d0 := u * cos(a0) + w * sin(a0)
			var d1 := u * cos(a1) + w * sin(a1)
			var p00 := base + eje * perfil[i].x + d0 * perfil[i].y
			var p01 := base + eje * perfil[i].x + d1 * perfil[i].y
			var p10 := base + eje * perfil[i + 1].x + d0 * perfil[i + 1].y
			var p11 := base + eje * perfil[i + 1].x + d1 * perfil[i + 1].y
			var n00 := (eje * nper[i].x + d0 * nper[i].y).normalized()
			var n01 := (eje * nper[i].x + d1 * nper[i].y).normalized()
			var n10 := (eje * nper[i + 1].x + d0 * nper[i + 1].y).normalized()
			var n11 := (eje * nper[i + 1].x + d1 * nper[i + 1].y).normalized()
			_cuadro(st, p00, p01, p11, p10, n00, n01, n11, n10,
				_color(n00, canto), _color(n01, canto), _color(n11, canto), _color(n10, canto))

## Una cabeza de remache mirando hacia `normal`. `r` en unidades.
func _remache(st: SurfaceTool, centro: Vector3, normal: Vector3, r: float = 0.0034) -> void:
	# Tres anillos y no cuatro: una cabeza de remache mide 2 o 3 px en pantalla, y
	# con los ~400 que hay el anillo de más eran 5.000 triángulos.
	_tornear(st, centro, normal, PackedVector2Array([
		Vector2(-0.001, r), Vector2(r * 0.3, r * 0.92), Vector2(r * 0.62, r * 0.62),
		Vector2(r * 0.8, 0.0)]), 6, 0.95)

## Un collarín: el anillo que une dos tramos de tubo.
func _collarin(st: SurfaceTool, centro: Vector3, eje: Vector3, r_tubo: float) -> void:
	var r := r_tubo + 0.0032
	_tornear(st, centro, eje, PackedVector2Array([
		Vector2(-0.008, r_tubo * 0.9), Vector2(-0.0065, r), Vector2(0.0065, r),
		Vector2(0.008, r_tubo * 0.9)]), 6, 0.8)

## Una bombilla con su copa de hierro, de pie sobre `base`. La copa va al
## material de hierro y el cristal al de las bombillas del recorrido.
func _bombilla(st_hierro: SurfaceTool, st_luz: SurfaceTool, base: Vector3,
		orden: float, r: float = 0.0135) -> void:
	_tornear(st_hierro, base, Vector3.UP, PackedVector2Array([
		Vector2(-0.002, r * 0.45), Vector2(0.0, r * 0.75), Vector2(r * 0.35, r * 0.95),
		Vector2(r * 0.6, r * 0.9)]), 6, 0.7)
	var c := base + Vector3.UP * (r * 1.25)
	_orden = orden
	var perfil := PackedVector2Array()
	for i in 7:
		var a := PI * float(i) / 6.0
		perfil.append(Vector2(-cos(a) * r, sin(a) * r))
	_tornear(st_luz, c, Vector3.UP, perfil, 6, 0.0)
	_orden = -1.0

## Una placa con el canto biselado: un polígono CONVEXO (en píxeles) levantado
## de `y0` a `y1`. Losas, sillares, placas y dovelas.
func _placa(st: SurfaceTool, contorno: PackedVector2Array, y0: float, y1: float,
		bisel_px: float, bisel_h: float, lado_r: float = 0.75, cojin: float = 0.0) -> void:
	var n := contorno.size()
	var c := Vector2.ZERO
	for q in contorno:
		c += q
	c /= float(n)
	var normales := PackedVector2Array()
	for i in n:
		var e := contorno[(i + 1) % n] - contorno[i]
		var nn := Vector2(e.y, -e.x).normalized()
		if nn.dot((contorno[i] + contorno[(i + 1) % n]) * 0.5 - c) < 0.0:
			nn = -nn
		normales.append(nn)
	var dentro := PackedVector2Array()
	for i in n:
		var n1 := normales[(i - 1 + n) % n]
		var n2 := normales[i]
		var vn := (n1 + n2).normalized()
		dentro.append(contorno[i] - vn * bisel_px / maxf(vn.dot(n2), 0.35))
	var ym := y1 - bisel_h
	var arriba := Vector3.UP
	var c_lado := Color(lado_r * _sombra, 0.3, 0.0)
	var c_lado_bajo := Color(lado_r * 0.6 * _sombra, 0.2, 0.0)
	var c_bisel := Color(_sombra, 0.65, 0.0)
	var c_tapa := Color(_sombra, 0.15, 0.0)
	var centro := _mundo.a3(c, y1 + cojin)
	for i in n:
		var j := (i + 1) % n
		var nl := Vector3(normales[i].x, 0.0, normales[i].y)
		_cuadro(st, _mundo.a3(contorno[i], y0), _mundo.a3(contorno[j], y0),
			_mundo.a3(contorno[j], ym), _mundo.a3(contorno[i], ym),
			nl, nl, nl, nl, c_lado_bajo, c_lado_bajo, c_lado, c_lado)
		var nb := (nl * bisel_h + arriba * bisel_px * Nucleo.E).normalized()
		_cuadro(st, _mundo.a3(contorno[i], ym), _mundo.a3(contorno[j], ym),
			_mundo.a3(dentro[j], y1), _mundo.a3(dentro[i], y1),
			nb, nb, nb, nb, c_bisel, c_bisel, c_bisel, c_bisel)
		var ni := arriba
		var nj := arriba
		if cojin > 0.0:
			# Abombada: en el borde de la tapa la normal ya se va hacia fuera.
			var fi := dentro[i] - c
			var fj := dentro[j] - c
			ni = (arriba + Vector3(fi.x, 0.0, fi.y).normalized() * cojin * 60.0).normalized()
			nj = (arriba + Vector3(fj.x, 0.0, fj.y).normalized() * cojin * 60.0).normalized()
		_tri(st, centro, _mundo.a3(dentro[i], y1), _mundo.a3(dentro[j], y1),
			arriba, ni, nj, c_tapa, c_tapa, c_tapa)

## Un rectángulo de esquinas romas, en píxeles, centrado en `c` y con su largo a
## lo largo de `eje`.
func _rect_romo(c: Vector2, eje: Vector2, largo: float, ancho: float,
		romo: float) -> PackedVector2Array:
	var lado := Vector2(-eje.y, eje.x)
	var a := largo * 0.5 - romo
	var b := ancho * 0.5 - romo
	var pts := PackedVector2Array()
	for esquina in 4:
		var sx := 1.0 if esquina == 0 or esquina == 1 else -1.0
		var sy := 1.0 if esquina == 1 or esquina == 2 else -1.0
		var base_ang := [-PI * 0.5, 0.0, PI * 0.5, PI][esquina] as float
		var ctr := Vector2(a * sx, b * sy)
		for k in 3:
			var ang := base_ang + PI * 0.5 * float(k) / 2.0
			var v := ctr + Vector2(cos(ang), sin(ang)) * romo
			pts.append(c + eje * v.x + lado * v.y)
	return pts

## Una barra recta de pletina entre dos puntos 3D.
func _barra(st: SurfaceTool, a: Vector3, b: Vector3, ancho: float, alto: float,
		ref: Vector3 = Vector3.UP) -> void:
	_barrer(st, PackedVector3Array([a, b]), _sec_pletina(ancho, alto, minf(ancho, alto) * 0.3), ref)

## Barre una línea larga repartiéndola por las celdas por las que pasa: cada
## tramo va a la malla de su celda (y de su grupo), y el siguiente arranca en el
## último punto del anterior, para que no quede hueco.
func _barrer_por_celdas(linea: PackedVector3Array, sec: Dictionary, material: String) -> void:
	var n := linea.size()
	var desde := 0
	while desde < n - 1:
		var clave := _clave_p(linea[desde])
		var hasta := desde + 1
		while hasta < n - 1 and _clave_p(linea[hasta]) == clave:
			hasta += 1
		_barrer(_st_clave(clave, material), linea.slice(desde, hasta + 1), sec)
		desde = hasta

## Una varilla redonda entre dos puntos 3D.
func _varilla(st: SurfaceTool, a: Vector3, b: Vector3, r: float, lados: int = 6) -> void:
	_barrer(st, PackedVector3Array([a, b]), _sec_redonda(r, lados, 0.5),
		Vector3.FORWARD if absf((b - a).normalized().y) > 0.9 else Vector3.UP)

# ------------------------------------------------------------------- las paredes

## Las paredes donde se puede clavar un apoyo: las del tablero (de 0 a H_PARED)
## y la falda del coro (hasta H_ALTA). Son las que ya son sólidas para la bola.
func _buscar_paredes() -> void:
	var falda := Colisionador.bit(Colisionador.CAPA_TABLERO)
	for c in _mesa.colisionadores:
		if c.tipo != Colisionador.Tipo.PARED:
			continue
		if c.capas == Colisionador.TODAS:
			_paredes.append({"a": c.a, "b": c.b, "alto": Nucleo.H_PARED})
		elif c.capas == falda:
			_paredes.append({"a": c.a, "b": c.b, "alto": Nucleo.H_ALTA})

## La pared más cercana a un punto: {punto, alto, dist}, o vacío si no hay.
func _pared_cerca(p: Vector2) -> Dictionary:
	var mejor := {}
	var dmin := INF
	for w in _paredes:
		var q := Geometry2D.get_closest_point_to_segment(p, w["a"], w["b"])
		var d := q.distance_to(p)
		if d < dmin:
			dmin = d
			mejor = {"punto": q, "alto": w["alto"], "dist": d}
	return mejor

# ------------------------------------------------------------------ recorridos

## La curva muestreada cada `PASO` píxeles: punto, tangente, perpendicular,
## altura y distancia desde la boca.
func _muestras(r: Rampa) -> Dictionary:
	var pts := PackedVector2Array()
	var tgs := PackedVector2Array()
	var perps := PackedVector2Array()
	var hs := PackedFloat32Array()
	var ds := PackedFloat32Array()
	var cuantos := maxi(int(ceil(r.largo / PASO)), 2)
	for i in cuantos + 1:
		var d := r.largo * float(i) / float(cuantos)
		var tg := r.tangente_en(d).normalized()
		pts.append(r.punto_en(d))
		tgs.append(tg)
		perps.append(Vector2(-tg.y, tg.x))
		hs.append(_mundo.altura_rampa(r, d))
		ds.append(d)
	return {"p": pts, "t": tgs, "n": perps, "h": hs, "d": ds}

func _montar_recorrido(r: Rampa) -> void:
	var info: Dictionary = _mesa.info_rampas.get(r.nombre, {})
	var lomo := float(info.get("lomo", 0.4))
	var mu := _muestras(r)
	var luz := OmniLight3D.new()
	luz.light_color = COLOR_BOMBILLA
	luz.light_energy = 0.0
	luz.omni_range = 0.75
	luz.omni_attenuation = 1.6
	luz.visible = false
	_mundo.add_child(luz)
	_guias[r.nombre]["luz"] = luz
	if lomo <= 0.001 and r.capa_entrada == r.capa_salida:
		_montar_galeria(r, mu)
		return
	match r.nombre:
		"estacion":
			_montar_puente(r, mu)
		"bajada":
			_montar_escalera(r, mu)
		_:
			_montar_vagoneta(r, mu)

## Los tubos que corren a lo largo del recorrido. `lado` en píxeles, `y` sobre la
## altura del recorrido. Con `remate`, sus dos puntas bajan curvándose hasta el
## suelo (los guardarraíles de una boca). Con `d_fin`, el tubo se acaba ahí; y si
## además se da `lado_fin`, su punta se dobla en 8 px hasta ese lado y a `y_fin`
## sobre el recorrido (una barandilla que muere en su carril, o en un labio): un
## tubo que se acaba en el aire se lee como roto.
func _tubo_largo(r: Rampa, mu: Dictionary, lado: float, y: float, radio: float,
		material: String, remate: bool, d_fin: float = INF, lado_fin: float = NAN,
		y_fin: float = 0.0) -> void:
	var p: PackedVector2Array = mu["p"]
	var nn: PackedVector2Array = mu["n"]
	var tt: PackedVector2Array = mu["t"]
	var hs: PackedFloat32Array = mu["h"]
	var ds: PackedFloat32Array = mu["d"]
	var n := p.size()
	var cortado := d_fin < r.largo - 0.5
	if cortado:
		n = 0
		while n < p.size() and ds[n] <= d_fin:
			n += 1
		n = maxi(n, 2)
	var linea := PackedVector3Array()
	var dists := PackedFloat32Array()
	if remate:
		# La punta de la boca se abre un poco y baja, sin llegar al suelo: la
		# sostiene un pie (abajo).
		for k in range(6, 0, -1):
			var f := float(k) / 6.0
			var abre := lado + signf(lado) * 3.0 * f
			var q := p[0] - tt[0] * 15.0 * f + nn[0] * abre
			linea.append(_mundo.a3(q, hs[0] + y * (1.0 - 0.7 * smoothstep(0.0, 1.0, f))))
			dists.append(0.0)
	for i in n:
		linea.append(_mundo.a3(p[i] + nn[i] * lado, hs[i] + y))
		dists.append(ds[i])
	if cortado:
		if not is_nan(lado_fin):
			for k in range(1, 5):
				var f := float(k) / 4.0
				var g := smoothstep(0.0, 1.0, f)
				var e := _en(r, minf(ds[n - 1] + 8.0 * f, r.largo))
				linea.append(_mundo.a3(e["p"] + e["n"] * lerpf(lado, lado_fin, g),
					float(e["h"]) + lerpf(y, y_fin, g)))
				dists.append(ds[n - 1])
	elif remate:
		for k in range(1, 7):
			var f := float(k) / 6.0
			var abre := lado + signf(lado) * 3.0 * f
			var q := p[n - 1] + tt[n - 1] * 15.0 * f + nn[n - 1] * abre
			linea.append(_mundo.a3(q, hs[n - 1] + y * (1.0 - 0.7 * smoothstep(0.0, 1.0, f))))
			dists.append(ds[n - 1])
	if remate:
		var extremos: Array[int] = [0]
		if not cortado:
			extremos.append(linea.size() - 1)
		for extremo: int in extremos:
			var punta := linea[extremo]
			var suelo := hs[0] if extremo == 0 else hs[n - 1]
			var st_pie := _st_p(Vector3(punta.x, suelo, punta.z), material)
			_varilla(st_pie, punta, Vector3(punta.x, suelo, punta.z), radio * 0.85, 8)
			_tornear(st_pie, Vector3(punta.x, suelo - 0.001, punta.z), Vector3.UP,
				PackedVector2Array([Vector2(0.0, radio * 2.2), Vector2(0.003, radio * 2.1),
				Vector2(0.006, radio * 1.3), Vector2(0.009, radio * 0.9)]), 10, 0.8)
	# Seis caras: un tubo mide 1 o 2 px de grueso desde la cámara de juego y con
	# las normales suaves no se ve la arista; con ocho eran un cuarto más de los
	# triángulos de todo el módulo.
	_barrer_por_celdas(linea, _sec_redonda(radio, 6, 0.35), material)

## Dónde caen los «aros» (los apoyos, las bombillas, los collarines): cada
## `cada` píxeles, sin los primeros y los últimos `margen`.
func _marcas(r: Rampa, cada: float, margen: float) -> PackedFloat32Array:
	var lista := PackedFloat32Array()
	var tramo := r.largo - margen * 2.0
	if tramo <= 0.0:
		return lista
	var cuantos := maxi(int(round(tramo / cada)), 1)
	for k in cuantos + 1:
		lista.append(margen + tramo * float(k) / float(cuantos))
	return lista

## El punto del recorrido a `d` píxeles: {p, t, n, h}.
func _en(r: Rampa, d: float) -> Dictionary:
	var tg := r.tangente_en(d).normalized()
	return {"p": r.punto_en(d), "t": tg, "n": Vector2(-tg.y, tg.x),
		"h": _mundo.altura_rampa(r, d)}

## LA PLACA DE UNA BOCA, a ras de suelo: la lengüeta de hierro por la que la bola
## sube al raíl. `hacia` mira dentro del recorrido.
func _lengueta(r: Rampa, d: float, centro: Vector2, hacia: Vector2, h: float) -> void:
	var st := _st(r.nombre, d, "hierro")
	var lado := Vector2(-hacia.y, hacia.x)
	var c := centro - hacia * 4.0
	var contorno := PackedVector2Array([
		c - hacia * 9.0 + lado * 16.0, c + hacia * 9.0 + lado * 13.5,
		c + hacia * 9.0 - lado * 13.5, c - hacia * 9.0 - lado * 16.0])
	_placa(st, contorno, h - 0.002, h + 0.005, 1.2, 0.002)
	for s: float in [-1.0, 1.0]:
		for a: float in [-5.0, 5.0]:
			_remache(st, _mundo.a3(c + hacia * a + lado * 11.0 * s, h + 0.005), Vector3.UP, 0.0028)

## EL RAÍL DE VAGONETA (campanario y tobogán): carriles, guardarraíles,
## traviesas, aros con bombillas y apoyos.
func _montar_vagoneta(r: Rampa, mu: Dictionary) -> void:
	# Si acaba cayendo a pique, acaba en un labio (ver la cabecera).
	var d_labio := _d_labio(r)
	var hasta := d_labio - 2.0 if d_labio < INF else INF
	for s: float in [-1.0, 1.0]:
		_tubo_largo(r, mu, LADO_CARRIL * s, Y_CARRIL, R_CARRIL, "laton", false, hasta)
		_tubo_largo(r, mu, LADO_GUARDA * s, Y_GUARDA, R_GUARDA, "laton", true,
			d_labio - 10.0 if d_labio < INF else INF, (LADO_LABIO + 0.4) * s, Y_LABIO)
	# Las traviesas: una pletina de hierro bajo los carriles cada 15 px.
	for d in _marcas(r, 15.0, 6.0):
		if d > hasta - 6.0:
			continue
		var e := _en(r, d)
		var st := _st(r.nombre, d, "hierro")
		var h: float = e["h"]
		var p: Vector2 = e["p"]
		var n: Vector2 = e["n"]
		var t3 := Vector3(e["t"].x, 0.0, e["t"].y)
		var y := h - 0.0062
		_barrer(st, PackedVector3Array([_mundo.a3(p - n * 8.5, y), _mundo.a3(p + n * 8.5, y)]),
			_sec_pletina(0.007, 0.026, 0.002), t3)
	var cada := 52.0 if r.nombre == "lanzadera" else 60.0
	var k := 0
	for d in _marcas(r, cada, 20.0):
		# El último aro, si cae dentro del labio o en la boca de su guardarraíl
		# doblado, sobra: lo que sostiene esa punta es el labio.
		if d > d_labio - 20.0:
			continue
		_aro(r, d, true, k % 2 == 0 or r.nombre != "lanzadera")
		k += 1
	_lengueta(r, 0.0, r.puntos[0], r.tangente_en(0.0).normalized(), _mundo.altura_rampa(r, 0.0))
	if d_labio < INF:
		_labio(r, d_labio)
	else:
		_lengueta(r, r.largo, r.puntos[r.puntos.size() - 1], -r.tangente_en(r.largo).normalized(),
			_mundo.altura_rampa(r, r.largo))
	_colgar_de_la_viga(r)

## Dónde acaba un raíl que cae a pique: el punto, contando desde el final, en que
## el raíl queda `H_LABIO` por encima de donde cae la bola. INF si su última
## caída es suave (entonces llega con sus tubos hasta el suelo, como la escalera).
func _d_labio(r: Rampa) -> float:
	var h_fin := _mundo.altura_rampa(r, r.largo)
	if _mundo.altura_rampa(r, maxf(r.largo - 70.0, 0.0)) - h_fin < CAIDA_LABIO:
		return INF
	var d := r.largo
	while d > r.largo - 70.0 and _mundo.altura_rampa(r, d) - h_fin < H_LABIO:
		d -= 1.0
	return d

## EL LABIO: la cubeta de latón en que acaba un raíl que cae a pique. Media caña
## que abraza los dos carriles, se ensancha y se aplana hacia la punta, con el
## borde vuelto en un bocel; los carriles mueren
## dentro y los guardarraíles se doblan hasta su borde. La bola sale volando de
## aquí y cae a la planta de abajo: la altura de la bola la suaviza el núcleo, y
## al caer pesa (baja a 2,8 por segundo), así que se lee como un salto.
func _labio(r: Rampa, d: float) -> void:
	var largo := 10.0
	var estaciones := 3
	var lados := 7
	var st := _st(r.nombre, d - largo * 0.5, "laton")
	var anillos: Array[PackedVector3Array] = []
	var normales: Array[PackedVector3Array] = []
	for i in estaciones + 1:
		var f := float(i) / float(estaciones)
		var e := _en(r, d - largo + largo * f)
		var p: Vector2 = e["p"]
		var n: Vector2 = e["n"]
		var h: float = e["h"]
		# Se abre y se aplana hacia la punta: es una boca, no un tubo.
		var ancho := LADO_LABIO + 1.5 * f * f
		var hondo := 0.020 - 0.008 * f
		var anillo := PackedVector3Array()
		var nrm := PackedVector3Array()
		for k in lados:
			var a := PI * float(k) / float(lados - 1)
			var lat := cos(a)
			var q := p + n * (ancho * lat)
			anillo.append(_mundo.a3(q, h + Y_LABIO - sin(a) * hondo))
			var n2 := Vector2(-lat * hondo, -sin(a) * ancho * Nucleo.E).normalized()
			nrm.append((Vector3(n.x, 0.0, n.y) * n2.x + Vector3.UP * -n2.y).normalized())
		anillos.append(anillo)
		normales.append(nrm)
	for i in estaciones:
		for k in lados - 1:
			var a0 := anillos[i]
			var a1 := anillos[i + 1]
			var n0 := normales[i]
			var n1 := normales[i + 1]
			var c := _color(Vector3.UP, 0.35)
			var c_bajo := Color(0.55, 0.3, 0.0)
			# Por dentro (la cara que ve la cámara) y por fuera, con la oclusión
			# del fondo de la cubeta: el latón de abajo no ve el fuego.
			_cuadro(st, a0[k], a0[k + 1], a1[k + 1], a1[k], n0[k], n0[k + 1], n1[k + 1], n1[k],
				c, c, c, c)
			var off := Vector3.DOWN * 0.003
			_cuadro(st, a0[k] + off, a0[k + 1] + off, a1[k + 1] + off, a1[k] + off,
				-n0[k], -n0[k + 1], -n1[k + 1], -n1[k], c_bajo, c_bajo, c_bajo, c_bajo)
	# El bocel: el borde vuelto de la punta y los dos cantos de arriba.
	var punta := anillos[estaciones]
	_barrer(st, punta, _sec_redonda(0.0042, 6, 0.9), Vector3.UP, true)
	for k: int in [0, lados - 1]:
		var canto := PackedVector3Array()
		for i in estaciones + 1:
			canto.append(anillos[i][k])
		_barrer(st, canto, _sec_redonda(0.0038, 6, 0.8), Vector3.UP, true)
	# Dos remaches por lado, donde el labio se clava a sus carriles.
	var e0 := _en(r, d - largo + 3.0)
	for s: float in [-1.0, 1.0]:
		var q: Vector2 = e0["p"] + e0["n"] * (LADO_LABIO - 1.2) * s
		_remache(st, _mundo.a3(q, float(e0["h"]) + Y_LABIO - 0.008),
			Vector3(e0["n"].x * s, 0.6, e0["n"].y * s).normalized(), 0.0026)
	# Debajo, su apoyo. El de los aros (`_apoyo`) no sirve aquí: el labio queda
	# a medio palmo de lo alto de la pared, demasiado cerca para una escuadra y
	# demasiado lejos para un pie derecho, y sin nada debajo se veía flotar. Así
	# que un pie corto desde la pared más cercana y un brazo hasta su panza.
	var e1 := _en(r, d - largo * 0.5)
	var c1: Vector2 = e1["p"]
	var t1 := Vector3(e1["t"].x, 0.0, e1["t"].y).normalized()
	var w := _pared_cerca(c1)
	var y_panza := float(e1["h"]) + Y_LABIO - 0.022
	if not w.is_empty() and float(w["dist"]) < 34.0 and y_panza - float(w["alto"]) > 0.012:
		var wp: Vector2 = w["punto"]
		var alto: float = w["alto"]
		var hierro := _st(r.nombre, d - largo * 0.5, "hierro")
		_pie(hierro, wp, alto, y_panza, t1)
		if float(w["dist"]) > 2.0:
			_barra(hierro, _mundo.a3(wp, y_panza - 0.004), _mundo.a3(c1, y_panza - 0.004),
				0.009, 0.008, Vector3.UP)
			_remache(hierro, _mundo.a3(c1, y_panza + 0.0005), Vector3.UP, 0.0028)

## UN ARO: la pletina en U que abraza los cuatro tubos, sus collarines, sus dos
## bombillas y, debajo, el apoyo que le toque. La U pasa a más de 9,6 px del
## centro de la bola en todo su recorrido (ver la cuenta en `LEEME`: la bola va
## a 0,09 sobre el raíl, la U baja recta por ±11 y dobla por debajo a −0,0065).
func _aro(r: Rampa, d: float, con_bombillas: bool, con_apoyo: bool) -> void:
	var e := _en(r, d)
	var p: Vector2 = e["p"]
	var n: Vector2 = e["n"]
	var h: float = e["h"]
	var t3 := Vector3(e["t"].x, 0.0, e["t"].y).normalized()
	var st := _st(r.nombre, d, "hierro")
	var linea := PackedVector3Array()
	var lado := LADO_GUARDA + 0.9
	var radio_codo := 3.4
	var y_fondo := h - 0.0065 - 0.003
	# Bajada por la izquierda, codo, fondo, codo, subida por la derecha.
	linea.append(_mundo.a3(p - n * lado, h + Y_GUARDA + 0.004))
	for k in 5:
		var a := PI * 0.5 * float(k) / 4.0
		var q := p - n * (lado - radio_codo + radio_codo * cos(a))
		linea.append(_mundo.a3(q, y_fondo + radio_codo * Nucleo.E * (1.0 - sin(a))))
	for k in 5:
		var a := PI * 0.5 * float(k) / 4.0
		var q := p + n * (lado - radio_codo + radio_codo * sin(a))
		linea.append(_mundo.a3(q, y_fondo + radio_codo * Nucleo.E * (1.0 - cos(a))))
	linea.append(_mundo.a3(p + n * lado, h + Y_GUARDA + 0.004))
	_barrer(st, linea, _sec_pletina(0.0045, 0.013, 0.0015), t3)
	for s: float in [-1.0, 1.0]:
		_collarin(st, _mundo.a3(p + n * LADO_GUARDA * s, h + Y_GUARDA), t3, R_GUARDA)
		_collarin(st, _mundo.a3(p + n * LADO_CARRIL * s, h + Y_CARRIL), t3, R_CARRIL)
		_remache(st, _mundo.a3(p + n * (lado + 0.25) * s, h + Y_GUARDA - 0.022),
			Vector3(n.x * s, 0.0, n.y * s), 0.0026)
	if con_bombillas and h > 0.05:
		var luz := _st(r.nombre, d, "luz")
		for s: float in [-1.0, 1.0]:
			_bombilla(st, luz, _mundo.a3(p + n * LADO_GUARDA * s, h + Y_GUARDA + R_GUARDA), d)
	if con_apoyo:
		_apoyo(r, d, p, n, h, t3)

## EL APOYO de un aro: lo busca en las paredes. Con la pared debajo del
## guardarraíl, un pie derecho; con la pared a un lado, una escuadra (pie, brazo
## y tornapuntas); sin pared cerca, nada (lo que cruza el campo cuelga de la
## viga: `_colgar_de_la_viga`).
func _apoyo(r: Rampa, d: float, p: Vector2, n: Vector2, h: float, t3: Vector3) -> void:
	if h < 0.12:
		return
	var st := _st(r.nombre, d, "hierro")
	var y_bajo := h - 0.012
	var pies := 0
	var mejor := {}
	for s: float in [-1.0, 1.0]:
		var g := p + n * LADO_GUARDA * s
		var w := _pared_cerca(g)
		if w.is_empty():
			continue
		if float(w["dist"]) <= PIE_DIRECTO and y_bajo - float(w["alto"]) > 0.03:
			_pie(st, w["punto"], float(w["alto"]), y_bajo, t3)
			pies += 1
		elif mejor.is_empty() or float(w["dist"]) < float(mejor["dist"]):
			mejor = w
	if pies > 0 or mejor.is_empty():
		return
	var wp: Vector2 = mejor["punto"]
	var alto: float = mejor["alto"]
	if wp.distance_to(p) > ALCANCE_ESCUADRA or y_bajo - alto < 0.10:
		return
	_escuadra(st, wp, alto, p, y_bajo, t3)

## Un pie derecho de pletina, de lo alto de una pared hasta debajo del aro, con
## su zapata de dos remaches.
func _pie(st: SurfaceTool, w: Vector2, desde: float, hasta: float, t3: Vector3) -> void:
	_barra(st, _mundo.a3(w, desde), _mundo.a3(w, hasta), 0.011, 0.011, t3)
	var zapata := _rect_romo(w, Vector2(t3.x, t3.z).normalized(), 5.0, 3.4, 0.8)
	_placa(st, zapata, desde - 0.001, desde + 0.004, 0.6, 0.0015)
	for s: float in [-1.0, 1.0]:
		_remache(st, _mundo.a3(w + Vector2(t3.x, t3.z).normalized() * 1.7 * s, desde + 0.004),
			Vector3.UP, 0.0024)

## Una escuadra: pie en la pared, brazo hasta pasar por debajo del raíl y un
## tornapuntas en diagonal. Es lo que se ve en los raíles de verdad.
func _escuadra(st: SurfaceTool, w: Vector2, alto: float, p: Vector2, y_brazo: float,
		t3: Vector3) -> void:
	var hacia := (p - w).normalized()
	var punta := p + hacia * (LADO_GUARDA + 2.0)
	var y := y_brazo - 0.006
	_pie(st, w, alto, y + 0.006, t3)
	_barra(st, _mundo.a3(w, y), _mundo.a3(punta, y), 0.010, 0.010, Vector3.UP)
	var largo := w.distance_to(p)
	if y - alto > 0.09 and largo > 8.0:
		var base := _mundo.a3(w, alto + (y - alto) * 0.4)
		var cima := _mundo.a3(w + hacia * minf(largo * 0.6, (y - alto) / Nucleo.E * 0.8), y - 0.005)
		_barra(st, base, cima, 0.007, 0.007, t3)
		_remache(st, cima + Vector3(t3.x, 0.0, t3.z) * 0.004, Vector3(t3.x, 0.0, t3.z), 0.0024)
	_remache(st, _mundo.a3(w, y + 0.005), Vector3.UP, 0.003)
	_remache(st, _mundo.a3(punta, y + 0.005), Vector3.UP, 0.003)

## Donde un raíl cruza la viga de la campana mayor por encima del campo, se
## cuelga de ella: un estribo que abraza el raíl por fuera de la bola y un
## tirante hasta la viga con su tensor y su argolla.
func _colgar_de_la_viga(r: Rampa) -> void:
	var p: PackedVector2Array = r.puntos
	for i in p.size() - 1:
		var z0 := p[i].y * Nucleo.E
		var z1 := p[i + 1].y * Nucleo.E
		if (z0 - VIGA_Z) * (z1 - VIGA_Z) > 0.0 or is_equal_approx(z0, z1):
			continue
		var f := (VIGA_Z - z0) / (z1 - z0)
		var q := p[i].lerp(p[i + 1], f)
		var x := q.x * Nucleo.E
		if x < VIGA_X0 + 0.05 or x > VIGA_X1 - 0.05:
			continue
		var d := 0.0
		for j in i:
			d += p[j].distance_to(p[j + 1])
		d += p[i].distance_to(q)
		var e := _en(r, d)
		var h: float = e["h"]
		if h < 0.25:
			continue
		var n: Vector2 = e["n"]
		var t3 := Vector3(e["t"].x, 0.0, e["t"].y).normalized()
		var st := _st(r.nombre, d, "hierro")
		var y_puente := h + 0.205
		# El estribo: dos varillas de los extremos de una traviesa hasta un
		# puente por encima de la bola (que llega a h + 0,18).
		var y_pie := h - 0.0065
		for s: float in [-1.0, 1.0]:
			var lado := q + n * (LADO_GUARDA + 3.5) * s
			_barra(st, _mundo.a3(lado, y_pie), _mundo.a3(lado, y_puente), 0.006, 0.006, t3)
			_remache(st, _mundo.a3(lado, y_pie), Vector3(n.x * s, 0.0, n.y * s), 0.0026)
		_barra(st, _mundo.a3(q - n * (LADO_GUARDA + 3.5), y_puente + 0.004),
			_mundo.a3(q + n * (LADO_GUARDA + 3.5), y_puente + 0.004), 0.012, 0.009, t3)
		_barra(st, _mundo.a3(q - n * (LADO_GUARDA + 3.5), y_pie - 0.004),
			_mundo.a3(q + n * (LADO_GUARDA + 3.5), y_pie - 0.004), 0.010, 0.008, t3)
		# El tirante, con su tensor a media altura y la argolla arriba.
		var arriba := VIGA_Y - 0.05
		var medio := lerpf(y_puente, arriba, 0.35)
		_varilla(st, _mundo.a3(q, y_puente + 0.008), _mundo.a3(q, medio - 0.03), 0.0045)
		_varilla(st, _mundo.a3(q, medio + 0.03), _mundo.a3(q, arriba), 0.0045)
		_tornear(st, _mundo.a3(q, medio - 0.034), Vector3.UP, PackedVector2Array([
			Vector2(0.0, 0.004), Vector2(0.006, 0.009), Vector2(0.062, 0.009),
			Vector2(0.068, 0.004)]), 6, 0.8)
		_barrer(st, _argolla(_mundo.a3(q, arriba + 0.024), t3, 0.022), _sec_redonda(0.0045, 6, 0.6),
			Vector3.UP, false)

## Una argolla: un círculo cerrado en el plano vertical que contiene `t3`.
func _argolla(centro: Vector3, t3: Vector3, radio: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for k in 15:
		var a := TAU * float(k) / 14.0
		pts.append(centro + t3 * (cos(a) * radio) + Vector3.UP * (sin(a) * radio))
	return pts

## EL PUENTECILLO del coro: tablero de roble sobre dos largueros de hierro, dos
## carriles de latón encima de las tablas, y la barandilla de latón sobre
## balaustres, con bombillas cada dos.
func _montar_puente(r: Rampa, mu: Dictionary) -> void:
	for s: float in [-1.0, 1.0]:
		_tubo_largo(r, mu, LADO_CARRIL * s, 0.0035, 0.0055, "laton", false)
		# A la llegada, sobre la tribuna, la barandilla se dobla hasta la tarima
		# y ahí se acaba: con el remate de las bocas se abría y bajaba con un pie
		# cada tubo, y desde la cámara del coro eran cuatro patas de araña.
		_tubo_largo(r, mu, LADO_GUARDA * s, Y_GUARDA, R_GUARDA, "laton", true,
			r.largo - 12.0, (LADO_GUARDA + 0.5) * s, 0.004)
		_larguero(r, mu, (LADO_GUARDA + 0.5) * s)
	for d in _marcas(r, 6.5, 3.0):
		var e := _en(r, d)
		var p: Vector2 = e["p"]
		var n: Vector2 = e["n"]
		var h: float = e["h"]
		var t3 := Vector3(e["t"].x, 0.0, e["t"].y).normalized()
		# Cada tabla, un pelo distinta: de largo, de alto y torcida.
		var az := _azar(d * 0.37 + float(r.nombre.length()))
		var torcida := (az - 0.5) * 1.4
		var lado := n.rotated(deg_to_rad(torcida) * 0.6)
		_barrer(_st(r.nombre, d, "madera"), PackedVector3Array([
			_mundo.a3(p - lado * (10.5 + az * 0.8), h - 0.0035 + az * 0.0012),
			_mundo.a3(p + lado * (11.2 - az * 0.6), h - 0.0035 + az * 0.0012)]),
			_sec_pletina(0.0065, 0.044, 0.0016), t3)
	var k := 0
	for d in _marcas(r, 24.0, 10.0):
		var e := _en(r, d)
		var p: Vector2 = e["p"]
		var n: Vector2 = e["n"]
		var h: float = e["h"]
		var t3 := Vector3(e["t"].x, 0.0, e["t"].y).normalized()
		var st := _st(r.nombre, d, "hierro")
		for s: float in [-1.0, 1.0]:
			var q := p + n * (LADO_GUARDA + 0.5) * s
			_varilla(st, _mundo.a3(q, h - 0.012), _mundo.a3(q, h + Y_GUARDA - 0.004), 0.0042)
			_collarin(st, _mundo.a3(p + n * LADO_GUARDA * s, h + Y_GUARDA), t3, R_GUARDA)
			_tornear(st, _mundo.a3(q, h - 0.002), Vector3.UP, PackedVector2Array([
				Vector2(0.0, 0.0068), Vector2(0.004, 0.0068), Vector2(0.008, 0.0045)]), 6, 0.8)
		if k % 2 == 0 and h > 0.05:
			var luz := _st(r.nombre, d, "luz")
			for s: float in [-1.0, 1.0]:
				_bombilla(st, luz, _mundo.a3(p + n * LADO_GUARDA * s, h + Y_GUARDA + R_GUARDA), d)
		if k % 2 == 0:
			_apoyo(r, d, p, n, h, t3)
		k += 1
	_lengueta(r, 0.0, r.puntos[0], r.tangente_en(0.0).normalized(), _mundo.altura_rampa(r, 0.0))
	_colgar_de_la_viga(r)

## Un larguero: la pletina de canto que corre por debajo de las tablas.
func _larguero(r: Rampa, mu: Dictionary, lado: float) -> void:
	var p: PackedVector2Array = mu["p"]
	var nn: PackedVector2Array = mu["n"]
	var hs: PackedFloat32Array = mu["h"]
	var linea := PackedVector3Array()
	for i in p.size():
		linea.append(_mundo.a3(p[i] + nn[i] * lado, hs[i] - 0.0145))
	_barrer_por_celdas(linea, _sec_pletina(0.005, 0.017, 0.0015), "hierro")

## LA ESCALERA: el raíl estrecho que baja de la tribuna. Arriba, sobre el coro y
## mientras vuela por encima de una criatura, dos carriles de latón y unos
## guardarraíles finos sobre postes. Desde `d_abre` —donde baja de `H_ABIERTA`—
## va ABIERTA (regla 11): los dos carriles, un travesaño fino cada
## `PASO_PELDANO` y las escuadras que la sujetan a la pared; la barandilla se
## dobla hasta su carril y se acaba ahí.
func _montar_escalera(r: Rampa, mu: Dictionary) -> void:
	var d_abre := _d_abre(r)
	for s: float in [-1.0, 1.0]:
		_tubo_largo(r, mu, LADO_CARRIL * s, Y_CARRIL, 0.0068, "laton", false)
		_tubo_largo(r, mu, LADO_GUARDA * s, Y_GUARDA - 0.01, 0.0058, "laton", true,
			d_abre, (LADO_CARRIL + 0.6) * s, Y_CARRIL + 0.004)
	# Los travesaños: una varilla fina que solo pasa un pelo de los carriles. Los
	# de antes eran de 24 px de ancho cada 9 px.
	var k := 0
	for d in _marcas(r, PASO_PELDANO, 6.0):
		var e := _en(r, d)
		var p: Vector2 = e["p"]
		var n: Vector2 = e["n"]
		var h: float = e["h"]
		var st := _st(r.nombre, d, "hierro")
		var ancho := LADO_CARRIL + 2.6
		_varilla(st, _mundo.a3(p - n * ancho, h - 0.003), _mundo.a3(p + n * ancho, h - 0.003), 0.0032)
		# Por donde va abierta no hay postes: las bombillas van en las puntas de
		# los travesaños, una de cada dos, para que la cadena de luz siga.
		if d > d_abre and k % 2 == 0 and h > 0.05:
			var luz := _st(r.nombre, d, "luz")
			for s: float in [-1.0, 1.0]:
				_bombilla(st, luz, _mundo.a3(p + n * ancho * s, h + 0.001), d, 0.0085)
		k += 1
	# Los postes de la barandilla, solo hasta donde hay barandilla.
	for d in _marcas(r, 38.0, 12.0):
		if d > d_abre - 6.0:
			break
		var e := _en(r, d)
		var p: Vector2 = e["p"]
		var n: Vector2 = e["n"]
		var h: float = e["h"]
		var t3 := Vector3(e["t"].x, 0.0, e["t"].y).normalized()
		var st := _st(r.nombre, d, "hierro")
		for s: float in [-1.0, 1.0]:
			var q := p + n * LADO_GUARDA * s
			_varilla(st, _mundo.a3(q, h - 0.004), _mundo.a3(q, h + Y_GUARDA - 0.014), 0.0035)
			_collarin(st, _mundo.a3(q, h + Y_GUARDA - 0.01), t3, 0.0058)
		if h > 0.05:
			var luz := _st(r.nombre, d, "luz")
			for s: float in [-1.0, 1.0]:
				_bombilla(st, luz, _mundo.a3(p + n * LADO_GUARDA * s, h + Y_GUARDA - 0.01 + 0.0058),
					d, 0.0095)
	# Las escuadras, a la pared que tenga a mano (no pisan el campo).
	for d in _marcas(r, 64.0, 20.0):
		var e := _en(r, d)
		_apoyo(r, d, e["p"], e["n"], float(e["h"]), Vector3(e["t"].x, 0.0, e["t"].y).normalized())
	_lengueta(r, r.largo, r.puntos[r.puntos.size() - 1], -r.tangente_en(r.largo).normalized(),
		_mundo.altura_rampa(r, r.largo))

## Dónde baja la escalera de `H_ABIERTA` por última vez después de su cima.
func _d_abre(r: Rampa) -> float:
	var cima := 0.0
	var h_cima := -INF
	var d := 0.0
	while d <= r.largo:
		var h := _mundo.altura_rampa(r, d)
		if h > h_cima:
			h_cima = h
			cima = d
		d += 2.0
	d = cima
	while d < r.largo and _mundo.altura_rampa(r, d) >= H_ABIERTA:
		d += 2.0
	return d

## LA GALERÍA, a ras de suelo: un canal de losas con dos bordillos de sillares,
## rematados por dentro con una media caña de latón y con bombillas engastadas.
## Nada pasa de 0,025: por encima rueda la bola que no ha entrado.
func _montar_galeria(r: Rampa, mu: Dictionary) -> void:
	var losa_largo := 19.0
	var bordillo_largo := 25.0
	var dentro := 11.0
	var fuera := 17.5
	var luz_cada := 3
	# Las losas del fondo del canal, oscuras hacia los bordes (la mugre se queda
	# en el rincón: es lo que hace que se lea rehundido).
	var d := 2.0
	while d < r.largo - 2.0:
		var d1 := minf(d + losa_largo, r.largo - 1.0)
		var az := _azar(d * 1.3)
		_sombra = 0.75 + 0.2 * az
		_placa(_st(r.nombre, d, "losa"), _franja(r, d + 0.6, d1 - 0.6, -dentro + 0.6, dentro - 0.6),
			-0.002, 0.0025 + az * 0.001, 1.2, 0.0012, 0.5)
		_sombra = 1.0
		d = d1
	# Los bordillos: sillares de piedra, cada uno un poco distinto de alto.
	var b := 0
	for s: float in [-1.0, 1.0]:
		d = 0.0
		var desfase := 0.0 if s < 0.0 else bordillo_largo * 0.5
		var primero := true
		while d < r.largo:
			var largo := bordillo_largo if not primero else bordillo_largo * 0.5 + desfase
			primero = false
			var d1 := minf(d + largo, r.largo)
			var az := _azar(d * 0.71 + s * 9.0)
			var lado_a := dentro if s > 0.0 else -fuera
			var lado_b := fuera if s > 0.0 else -dentro
			_placa(_st(r.nombre, d, "sillar"), _franja(r, d + 0.8, d1 - 0.8, lado_a, lado_b),
				-0.003, 0.015 + az * 0.004, 1.6, 0.004, 0.7, 0.003)
			if b % luz_cada == 1:
				var normal: Vector2 = _en(r, (d + d1) * 0.5)["n"]
				var centro: Vector2 = r.punto_en((d + d1) * 0.5) + normal * (dentro + fuera) * 0.5 * s
				_engastada(r, (d + d1) * 0.5, centro, 0.015 + az * 0.004)
			b += 1
			d = d1
	# La media caña de latón que remata cada bordillo por dentro.
	var p: PackedVector2Array = mu["p"]
	var nn: PackedVector2Array = mu["n"]
	for s: float in [-1.0, 1.0]:
		var linea := PackedVector3Array()
		for i in p.size():
			linea.append(_mundo.a3(p[i] + nn[i] * (dentro + 0.4) * s, 0.016))
		_barrer_por_celdas(linea, _sec_redonda(0.0052, 8, 0.4), "laton")

## Una franja del recorrido entre dos distancias y dos lados, como polígono
## convexo (cinco puntos por canto: la curva se sigue, y en un tramo de 25 px
## la concavidad no llega a un tercio de píxel).
func _franja(r: Rampa, d0: float, d1: float, lado0: float, lado1: float) -> PackedVector2Array:
	var a := PackedVector2Array()
	var b := PackedVector2Array()
	for k in 5:
		var d := lerpf(d0, d1, float(k) / 4.0)
		var e := _en(r, d)
		a.append(e["p"] + e["n"] * lado0)
		b.append(e["p"] + e["n"] * lado1)
	b.reverse()
	a.append_array(b)
	return _envolvente(a)

## La envolvente convexa de un puñado de puntos, en el orden en que se recorren.
func _envolvente(pts: PackedVector2Array) -> PackedVector2Array:
	var casco := Geometry2D.convex_hull(pts)
	if casco.size() > 1 and casco[0].is_equal_approx(casco[casco.size() - 1]):
		casco.remove_at(casco.size() - 1)
	return casco

## Una bombilla engastada en un bordillo: el bisel de latón y el cristal casi a
## ras (la galería no tiene altura).
func _engastada(r: Rampa, d: float, centro: Vector2, y: float) -> void:
	var st := _st(r.nombre, d, "laton")
	_tornear(st, _mundo.a3(centro, y - 0.002), Vector3.UP, PackedVector2Array([
		Vector2(0.0, 0.024), Vector2(0.003, 0.023), Vector2(0.0046, 0.018)]), 12, 0.8)
	var luz := _st(r.nombre, d, "luz")
	_orden = d
	var perfil := PackedVector2Array()
	for i in 5:
		var a := PI * 0.5 * float(i) / 4.0
		perfil.append(Vector2(sin(a) * 0.0065, cos(a) * 0.0165))
	_tornear(luz, _mundo.a3(centro, y + 0.0016), Vector3.UP, perfil, 10, 0.0)
	_orden = -1.0

# ----------------------------------------------------------- flechas de boca

## LA FLECHA DE UNA BOCA: placa de hierro con remaches en las esquinas, el campo
## de cobre comido y la flecha de bombillas ámbar apuntando a la boca, pegada a
## ella. A ras de suelo —la bola pasa por encima: nada de más de 0,025—, pero con
## RELIEVE: el marco, el cuerpo de bronce y las bombillas en sus casquillos se
## levantan por escalones (0,005 · 0,010 · 0,014 · 0,020). Antes todo cabía en
## 0,012 y, muy escorzada desde la cámara de juego, se leía como una pegatina.
## Encendida, deja un charco ámbar en la losa.
func _montar_flecha(r: Rampa) -> void:
	var boca := r.puntos[0]
	var hacia := r.tangente_en(0.0).normalized()
	var lado := Vector2(-hacia.y, hacia.x)
	var c := boca - hacia * float(DIST_FLECHA[r.nombre])
	var aqui := _mundo.a3(c, 0.0)
	var largo := 37.0
	var ancho := 25.0
	# El campo, de cobre, hundido entre el marco...
	_placa(_st_p(aqui, "oxido"), _rect_romo(c, hacia, largo - 2.0, ancho - 2.0, 2.5),
		-0.002, 0.005, 0.8, 0.0012)
	# ...y el marco de hierro alrededor: cuatro pletinas con los cantos romos.
	var st := _st_p(aqui, "hierro")
	var a := largo * 0.5 - 1.6
	var b := ancho * 0.5 - 1.6
	for s: float in [-1.0, 1.0]:
		_placa(st, _rect_romo(c + lado * b * s, hacia, largo, 3.6, 1.2), -0.002, 0.014, 1.0, 0.0035)
		_placa(st, _rect_romo(c + hacia * a * s, hacia, 3.6, ancho - 5.0, 1.2), -0.002, 0.014,
			1.0, 0.0035)
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			_remache(st, _mundo.a3(c + hacia * a * sx + lado * b * sy, 0.014), Vector3.UP, 0.0036)
	# El cuerpo de la flecha, de bronce, levantado sobre el campo: se lee aunque
	# esté apagada, como en el sprite.
	var bronce := _st_p(aqui, "laton")
	_placa(bronce, PackedVector2Array([
		c + hacia * -15.5 + lado * 2.9, c + hacia * 0.5 + lado * 2.9,
		c + hacia * 0.5 - lado * 2.9, c + hacia * -15.5 - lado * 2.9]), 0.002, 0.010, 1.0, 0.002)
	_placa(bronce, PackedVector2Array([
		c + hacia * -1.0 + lado * 11.2, c + hacia * 15.5, c + hacia * -1.0 - lado * 11.2]),
		0.002, 0.010, 1.0, 0.002)
	# Las bombillas, cada una en su casquillo de latón.
	var luz := _st_p(aqui, "luz")
	for q: Vector2 in FLECHA_BOMBILLAS:
		var pos := c + hacia * q.x + lado * q.y
		_tornear(bronce, _mundo.a3(pos, 0.0095), Vector3.UP, PackedVector2Array([
			Vector2(0.0, 0.0195), Vector2(0.0026, 0.0195), Vector2(0.004, 0.0162)]), 10, 0.8)
		_orden = (q.x + 13.0) / 25.0
		var perfil := PackedVector2Array()
		for i in 5:
			var ang := PI * 0.5 * float(i) / 4.0
			perfil.append(Vector2(sin(ang) * 0.0095, cos(ang) * 0.0152))
		_tornear(luz, _mundo.a3(pos, 0.0105), Vector3.UP, perfil, 8, 0.0)
		_orden = -1.0
	_charco_de(c, hacia, largo * 1.25, ancho * 1.5)

## El charco ámbar de una flecha: un cuadro a ras de losa, más grande que la
## placa, que se ve alrededor de ella. `UV` de −1 a 1 y la guía en `UV2.y`.
func _charco_de(c: Vector2, hacia: Vector2, medio_largo: float, medio_ancho: float) -> void:
	var st := _st_p(_mundo.a3(c, 0.0), "charco")
	var lado := Vector2(-hacia.y, hacia.x)
	var esquinas: Array[Vector2] = [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0),
		Vector2(-1.0, 1.0)]
	var pts: Array[Vector3] = []
	for e in esquinas:
		pts.append(_mundo.a3(c + hacia * e.x * medio_largo + lado * e.y * medio_ancho, 0.0018))
	for tri: Array in [[0, 1, 2], [0, 2, 3]]:
		var orden: Array = tri
		# La cara mira hacia arriba (cull_back): se ordena como en `_tri`.
		var p0: Vector3 = pts[orden[0]]
		var p1: Vector3 = pts[orden[1]]
		var p2: Vector3 = pts[orden[2]]
		if (p1 - p0).cross(p2 - p0).dot(Vector3.UP) > 0.0:
			orden = [orden[0], orden[2], orden[1]]
		for i: int in orden:
			st.set_normal(Vector3.UP)
			st.set_uv(esquinas[i])
			st.set_uv2(Vector2(0.0, _guia))
			st.add_vertex(pts[i])

# ------------------------------------------------------------ bocas del túnel

## UNA BOCA DE LA CATACUMBA: una trampilla redonda con su ARCO de dovelas del
## lado por donde el túnel se mete bajo tierra, un umbral gastado del otro lado,
## el pozo negro, la reja de hierro sobre la mitad honda y, al fondo, el
## resplandor arcano. Todo a menos de 0,025: es suelo.
func _montar_boca(r: Rampa, entrada: bool) -> void:
	var k := _bocas.size()
	var centro: Vector2 = r.puntos[0] if entrada else r.puntos[r.puntos.size() - 1]
	# Hacia dónde se hunde el túnel desde esta boca.
	var dentro := r.tangente_en(0.0).normalized() if entrada \
		else -r.tangente_en(r.largo).normalized()
	var lado := Vector2(-dentro.y, dentro.x)
	var r_in := RADIO_BOCA
	var r_arco := RADIO_BOCA + 8.5
	var r_umbral := RADIO_BOCA + 6.0
	var piedra := _st_p(_mundo.a3(centro, 0.0), "piedra")
	# El arco: siete dovelas y la clave, más alta.
	var dovelas := 7
	for i in dovelas:
		var a0 := -PI * 0.5 + PI * float(i) / float(dovelas) + 0.03
		var a1 := -PI * 0.5 + PI * float(i + 1) / float(dovelas) - 0.03
		var az := _azar(float(i) * 3.1 + float(k) * 17.0)
		var clave := i == 3
		var ro := r_arco + (2.0 if clave else 0.0)
		var pts := PackedVector2Array()
		for a: float in [a0, a1]:
			var dir := dentro.rotated(a)
			pts.append(centro + dir * r_in)
			pts.append(centro + dir * ro)
		_sombra = 0.8 + 0.2 * az
		_placa(piedra, _envolvente(pts), -0.003,
			(0.022 if clave else 0.015 + az * 0.004), 2.0, 0.006, 0.75, 0.0035)
		_sombra = 1.0
	# El umbral: tres piedras más bajas y gastadas.
	for i in 3:
		var a0 := PI * 0.5 + PI * float(i) / 3.0 + 0.035
		var a1 := PI * 0.5 + PI * float(i + 1) / 3.0 - 0.035
		var pts := PackedVector2Array()
		for j in 4:
			var dir := dentro.rotated(lerpf(a0, a1, float(j) / 3.0))
			pts.append(centro + dir * r_in)
			pts.append(centro + dir * r_umbral)
		_sombra = 0.9
		_placa(piedra, _envolvente(pts), -0.003, 0.009 + _azar(float(i) + float(k) * 5.0) * 0.003,
			2.6, 0.005, 0.75, 0.003)
		_sombra = 1.0
	# El pozo: negro, con una garganta de hollín que baja desde las piedras.
	var carbon := _st_p(_mundo.a3(centro, 0.0), "carbon")
	_sombra = 0.25
	_placa(carbon, _circulo(centro, r_in + 0.5, 28), -0.002, 0.0012, 0.0, 0.0001, 0.3)
	_sombra = 1.0
	# La garganta: un anillo de hollín que baja de las piedras al pozo. Es lo que
	# hace que el negro se lea como hondo y no como una pegatina.
	for i in 28:
		var a0 := TAU * float(i) / 28.0
		var a1 := TAU * float(i + 1) / 28.0
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		var arriba0 := _mundo.a3(centro + d0 * r_in, 0.011)
		var arriba1 := _mundo.a3(centro + d1 * r_in, 0.011)
		var abajo0 := _mundo.a3(centro + d0 * (r_in - 4.0), 0.0016)
		var abajo1 := _mundo.a3(centro + d1 * (r_in - 4.0), 0.0016)
		var n0 := (Vector3(-d0.x, 0.0, -d0.y) + Vector3.UP * 0.5).normalized()
		var n1 := (Vector3(-d1.x, 0.0, -d1.y) + Vector3.UP * 0.5).normalized()
		var claro := Color(0.45, 0.2, 0.0)
		var hondo := Color(0.04, 0.0, 0.0)
		_cuadro(carbon, arriba0, arriba1, abajo1, abajo0, n0, n1, n1, n0, claro, claro, hondo, hondo)
	# El resplandor, al fondo de la mitad honda, que asoma entre los barrotes.
	var arcano := _propio("arcano")
	var sombreado := arcano as ShaderMaterial
	if sombreado != null:
		sombreado.set_shader_parameter("usa_vertice", 1.0)
		sombreado.set_shader_parameter("calor", 0.62)
		sombreado.set_shader_parameter("nucleo", 0.25)
		sombreado.set_shader_parameter("costra", 0.15)
		sombreado.set_shader_parameter("suciedad", 0.0)
	_bocas.append({"mat": arcano, "luz": null, "activo": 0.0, "tapada": 0.0})
	var fondo := _st_p(_mundo.a3(centro, 0.0), "arcano" + str(k))
	var foco := centro + dentro * 6.0
	var c_foco := _mundo.a3(foco, 0.0017)
	var vivo := Color(1.0, 0.0, 1.0)
	var muerto := Color(0.3, 0.0, 0.0)
	for i in 24:
		var a0 := TAU * float(i) / 24.0
		var a1 := TAU * float(i + 1) / 24.0
		# Achatado hacia la boca: la luz sale de debajo de la reja, de lo hondo.
		var e0 := Vector2(cos(a0), sin(a0))
		var e1 := Vector2(cos(a1), sin(a1))
		var q0 := foco + dentro * e0.x * r_in * 0.62 + lado * e0.y * r_in * 0.78
		var q1 := foco + dentro * e1.x * r_in * 0.62 + lado * e1.y * r_in * 0.78
		_tri(fondo, c_foco, _mundo.a3(q0, 0.0016), _mundo.a3(q1, 0.0016),
			Vector3.UP, Vector3.UP, Vector3.UP, vivo, muerto, muerto)
	# La reja, sobre la mitad honda: barrotes cruzados con el canto vivo.
	var hierro := _st_p(_mundo.a3(centro, 0.0), "hierro")
	var y_reja := 0.0075
	for o: float in [3.0, 8.0, 13.0]:
		var medio := sqrt(maxf(r_in * r_in - o * o, 0.0)) + 1.5
		_barra(hierro, _mundo.a3(centro + dentro * o - lado * medio, y_reja),
			_mundo.a3(centro + dentro * o + lado * medio, y_reja), 0.0042, 0.0055,
			Vector3(dentro.x, 0.0, dentro.y))
	for s: float in [-1.0, 0.0, 1.0]:
		var o := 5.5 * s
		var hasta := sqrt(maxf(r_in * r_in - o * o, 0.0)) + 1.5
		_barra(hierro, _mundo.a3(centro + lado * o - dentro * 0.5, y_reja + 0.0012),
			_mundo.a3(centro + lado * o + dentro * hasta, y_reja + 0.0012), 0.0045, 0.0045,
			Vector3(lado.x, 0.0, lado.y))
	# Dos goznes y una argolla del lado del umbral: es una trampilla, se levanta.
	for s: float in [-1.0, 1.0]:
		var g := centro + lado * 9.0 * s - dentro * (r_umbral - 2.0)
		_barra(hierro, _mundo.a3(g - lado * 2.5, 0.0115), _mundo.a3(g + lado * 2.5, 0.0115),
			0.006, 0.0045, Vector3(dentro.x, 0.0, dentro.y))
		_remache(hierro, _mundo.a3(g, 0.014), Vector3.UP, 0.0024)
	var luz := OmniLight3D.new()
	luz.light_color = Paleta.ARCANO
	luz.light_energy = 0.0
	luz.omni_range = 1.1
	luz.position = _mundo.a3(centro + dentro * 4.0, 0.12)
	luz.visible = false
	_mundo.add_child(luz)
	_bocas[k]["luz"] = luz

func _circulo(c: Vector2, r: float, lados: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in lados:
		var a := TAU * float(i) / float(lados)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts

func encender_boca(boca: int) -> void:
	if boca >= 0 and boca < _bocas.size():
		_bocas[boca]["activo"] = 1.0

func _al_entrar(_punto: Vector2, indice: int) -> void:
	var r := _mesa.rampas[indice]
	if _guias.has(r.nombre):
		_guias[r.nombre]["impulso"] = 1.0
	if r.subterranea and _boca_de.has(r.nombre):
		encender_boca(int(_boca_de[r.nombre]))

func _al_salir(_punto: Vector2, indice: int) -> void:
	var r := _mesa.rampas[indice]
	if r.subterranea and _boca_de.has(r.nombre):
		encender_boca(int(_boca_de[r.nombre]) + 1)

# ------------------------------------------------------------------ cada cuadro

func actualizar(delta: float) -> void:
	var t := _mundo.tiempo
	var armada := _mesa.descarga_armada
	# Dónde va la bola más adelantada de cada recorrido.
	var cabezas: Dictionary = {}
	for b in _mesa.bolas:
		if b.viva and b.rampa >= 0:
			cabezas[b.rampa] = maxf(float(cabezas.get(b.rampa, -1.0)), b.rampa_distancia)
	for nombre in _guias:
		var guia: Dictionary = _guias[nombre]
		var imp: float = maxf(float(guia["impulso"]) - delta * 1.6, 0.0)
		guia["impulso"] = imp
		var indice: int = guia["indice"]
		var cadena: float = guia["cadena"]
		if cabezas.has(indice):
			guia["cabeza"] = float(cabezas[indice])
			cadena = minf(cadena + delta * 8.0, 1.0)
		else:
			cadena = maxf(cadena - delta * 1.4, 0.0)
		guia["cadena"] = cadena
		_cadena[indice] = cadena
		_cabeza[indice] = float(guia["cabeza"])
		_fogonazo[indice] = imp * 0.35
		_reposo[indice] = 0.13 + (0.07 if armada else 0.0)
		_corre[indice] = 0.0
		var luz: OmniLight3D = guia["luz"]
		if luz != null:
			var r: Rampa = guia["rampa"]
			var dd := clampf(float(guia["cabeza"]), 0.0, r.largo)
			luz.visible = cadena > 0.02
			luz.light_energy = cadena * 0.9
			luz.position = _mundo.a3(r.punto_en(dd), _mundo.altura_rampa(r, dd) + 0.16)
		# En reposo la flecha corre despacio hacia la boca, como en una máquina
		# de verdad; con la campana armada, deprisa; al entrar, destello.
		if guia["flecha"]:
			var f := GUIA_FLECHA + indice
			_reposo[f] = 0.10
			_corre[f] = 0.75 + (0.35 if armada else 0.0)
			_velocidad[f] = (1.6 if armada else 0.7) + 2.5 * imp
			_fogonazo[f] = imp * 1.2
			# El charco sigue a la flecha: un rescoldo en reposo, más con la
			# campana armada, y el fogonazo al entrar.
			_luz_charco[f] = 0.30 + (0.30 if armada else 0.0) + imp * 1.6
	_luces.set_shader_parameter("reloj", t)
	_luces.set_shader_parameter("reposo", _reposo)
	_luces.set_shader_parameter("corre", _corre)
	_luces.set_shader_parameter("velocidad", _velocidad)
	_luces.set_shader_parameter("cadena", _cadena)
	_luces.set_shader_parameter("cabeza", _cabeza)
	_luces.set_shader_parameter("fogonazo", _fogonazo)
	_charco.set_shader_parameter("luz", _luz_charco)

	var caza := _mundo.caza
	for k in _bocas.size():
		var boca := _bocas[k]
		var a: float = maxf(float(boca["activo"]) - delta * 1.2, 0.0)
		boca["activo"] = a
		# Una boca tapada se apaga y se queda en un rescoldo rojo: por ahí no se
		# esconde nadie.
		var meta := 0.0
		if caza != null and k < caza.boca_cierre.size() and caza.boca_cierre[k] > 0.0:
			meta = 1.0
		var tapada := lerpf(float(boca["tapada"]), meta, 1.0 - exp(-12.0 * delta))
		boca["tapada"] = tapada
		var energia := lerpf(1.2 + 0.3 * sin(t * 1.3 + float(k) * 2.0) + a * 5.0,
			1.0 + 0.5 * sin(t * 9.0), tapada)
		_encender(boca["mat"] as Material, energia, tapada)
		var luz: OmniLight3D = boca["luz"]
		luz.visible = a > 0.02
		luz.light_energy = a * 1.6
	_luz_escondida(t)

## La criatura escondida en la catacumba va por debajo del suelo de una boca a
## otra: una luz arcana muy baja la sigue, y el suelo se ilumina por donde pasa.
func _luz_escondida(t: float) -> void:
	var caza := _mundo.caza
	var donde := Vector2.INF
	if caza != null:
		for c in caza.criaturas:
			if c.estado == Criatura.Estado.ESCONDIDA:
				donde = c.pos
				break
	if donde == Vector2.INF:
		_luz_tunel.visible = false
		return
	_luz_tunel.visible = true
	_luz_tunel.position = _mundo.a3(donde, 0.035)
	_luz_tunel.light_energy = 0.55 + 0.2 * sin(t * 5.0)
