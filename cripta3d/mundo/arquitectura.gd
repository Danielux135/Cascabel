extends RefCounted

## CRIPTA 3D · MÓDULO «arquitectura» · LA PIEDRA
##
## Lo que convierte la mesa en un sitio: el sarcófago sobre el que se juega, el
## ábside del fondo con sus hornacinas y su óculo, la tribuna del coro, y la sala
## alrededor —suelo, muro y pilares— perdiéndose en la niebla.
##
## QUÉ MONTA (todo fijo: no se mueve nada)
##   · LAS PAREDES del campo, una por cada colisionador PARED que existe en todas
##     las capas, y cada clase con su oficio:
##       exterior (un lado da fuera del campo)  sillares de albardilla que suben a
##             `H_BORDE`: el canto que mira al campo ESTÁ en la línea del
##             colisionador y la piedra crece hacia fuera. En los lados llega
##             hasta el borde del mueble; en el arco, hasta la cara del ábside
##       interior largo (el separador del carril lanzador)  bordillo de sillar
##             fino, centrado en la línea, con una pletina de hierro remachada
##       interior corto (≤ 30 px: los cierres del carril)  un mojón de piedra
##       interior medio (las guías de los carriles: inlanes, outlanes y los dos
##             de arriba)  guía de hierro forjado: dos barras y sus postes
##   · EL MUEBLE: la mesa es un bloque de piedra tipo sarcófago. Albardilla
##     gruesa alrededor, el cuerpo con zócalo hasta el suelo de la sala,
##     cantoneras y pletinas de hierro, un bocel bajo la albardilla, y en el
##     frente EL DESAGÜE: un canal de piedra a lo ancho y en su centro un aro de
##     hierro remachado sobre el pozo. El carril lanzador lleva dos guías de
##     hierro en el fondo, y su tope son dos orejetas (la bola se ve entera).
##   · EL ÁBSIDE: la pared curva del fondo, sillar a sillar (los sillares son
##     geometría: la junta es el bisel redondo y oscuro de dos piedras, no un
##     dibujo, y cada piedra tiene su tono y su vuelo), con zócalo, cuatro
##     HORNACINAS ciegas de medio punto con su repisa y sus dovelas, EL ÓCULO con
##     su anillo de dovelas y su reja (el taladro va inclinado en la dirección de
##     la luna, para que el rayo pase), una cornisa moldurada y una hilada de
##     arranque. Lo flanquean dos columnas con capitel de calaveras
##     (`arquitectura_capitel.glb`: tres por cara) que sostienen el ARCO TRIUNFAL,
##     entero, dovela a dovela, y detrás LA BÓVEDA DEL ÁBSIDE (de horno) con
##     cuatro nervios que se juntan en una clave.
##   · EL CORO: la tribuna alta. Arquería ciega en sus caras, losa volada sobre
##     ménsulas en el frente, piso de tablones de roble dentro de un cerco de
##     piedra, y la barandilla (los colisionadores de la capa alta) de hierro
##     forjado con balaustres.
##   · LA SALA: el suelo a `Y_SALA` con un metro de losas sueltas alrededor del
##     mueble, el muro del fondo con la cornisa del ábside corrida y, a los dos
##     lados del ábside, un ARCO CIEGO con su OSARIO (nichos con huesos y
##     calaveras, `arquitectura_osario.glb`), y dos filas de pilares (x = −3 y
##     x = 7) con basa, capitel y un dintel encima. Va en `CAPA_BAJO_SUELO`.
##   · LA BÓVEDA (decisión de la tanda de arreglos: la sala se cierra): cañón
##     sobre la nave central entre los pilares, cuarto de cañón en las laterales
##     hasta un muro de fuera, arcos fajones en cada fila de pilares, el testero
##     del fondo y argollas para las cadenas. Clave a `Y_BOVEDA`. TODO de una cara
##     mirando hacia abajo, sin sombra y en `CAPA_SIN_REFLEJO`.
##
## LO QUE DEJA A MANO PARA «atrezzo» (variables públicas, en coordenadas de mundo;
## se rellenan en `montar`, así que hay que leerlas DESPUÉS: «atrezzo» se monta
## detrás de este módulo en el orden del núcleo):
##   hornacinas       Array[Transform3D]  el centro del suelo de cada hornacina.
##                    Base: X a lo largo del muro, Y arriba, Z hacia fuera (hacia
##                    el campo). Caben 0,38 de ancho, 0,62 de alto, 0,16 de fondo
##   repisas          Array[Transform3D]  sitios planos donde dejar algo (velas,
##                    calaveras): las repisas de las hornacinas por su borde de
##                    fuera, y la cornisa del ábside. Misma base
##   argollas         Array[Transform3D]  el punto del que cuelga una cadena (el
##                    fondo de la argolla de hierro). Z hacia fuera del muro
##   apoyos_antorcha  Array[Transform3D]  en la cara del ábside, a `H_ANTORCHA`,
##                    en los cuatro ángulos de la v0 de «atrezzo» (38°, 72°, 108°
##                    y 142°): los huecos entre hornacinas
##   apoyos_pilar     Array[Transform3D]  en cada pilar de la sala, a 1,6 de
##                    alto, en la cara que mira a la mesa (Z hacia la mesa): los
##                    pilares están a oscuras y una antorcha ahí los saca
##   capiteles        Array[Transform3D]  lo alto de cada columna (encima del
##                    cimacio), por si algo se posa o cuelga de ahí
##   oculo            Transform3D         el centro del óculo en la cara del muro.
##                    Z es la dirección de la luz (hacia dentro de la sala)
##   anclajes_boveda  Array[Transform3D]  dónde se engancha una cadena al techo:
##                    el fondo de una argolla de hierro clavada en la bóveda (Y
##                    arriba). En este orden: [0] y [1] las dos cadenas de la viga
##                    de la campana (x 0,56 y 2,44, z 7,42: las ARMELLAS_X de
##                    «atrezzo»), [2] y [3] las dos cadenas de la sala (−2,35; 10,2)
##                    y (6,4; 10,0), y luego la clave de cada fajón de la nave
##                    (x = 2, z = 9,2 / 12,2 / 15,2 / 18,2). Las de la viga quedan
##                    a 6,22 de alto: la cadena va de la armella a ese punto
##   nichos_osario    Array[Transform3D]  los nichos de osario que quedan VACÍOS
##                    (la fila de abajo, que tapa el mueble): el centro del borde
##                    de delante de su suelo; caben 0,46 × 0,34 y 0,26 de fondo,
##                    Z hacia fuera del muro
##   techo(x, z) -> float   a qué altura está el techo encima de (x, z), para
##                    colgar algo de cualquier otro sitio
##   punto_abside(grados, altura, fuera) -> Vector3   un punto de la cara del
##                    ábside: 0° es la punta derecha, 180° la izquierda; `fuera`
##                    se aparta de la cara hacia el campo
##
## SEÑALES QUE ESCUCHA   ninguna.
##
## LO QUE NO PUEDE DEJAR DE HACER QUIEN LO REESCRIBA
##   1. LO QUE CHOCA MIDE LO QUE MIDE EL COLISIONADOR. Las paredes salen de
##      `mesa.colisionadores`, nunca de coordenadas escritas a mano: si se mueve
##      una pared en `mesa_cripta.gd`, aquí se mueve sola. Una pared exterior
##      tiene su cara EN la línea (la bola la toca con su radio, que es lo que
##      mide el motor); lo fino interior va centrado y no pasa de 3,5 px.
##   2. Hay TRES clases de pared y cada una es una cosa distinta:
##        capas == TODAS             pared del tablero
##        capas == bit(CAPA_ALTA)    barandilla del coro (encima de `H_ALTA`)
##        capas == bit(CAPA_TABLERO) la falda del coro: NO se dibuja como pared,
##                                   es la cara del bloque de la tribuna
##   3. El piso de la tribuna está a `H_ALTA` exactos (los tablones, como mucho
##      4 mm por debajo): la bola, la pala del coro y el sarcófago se colocan a
##      esa altura desde otros módulos. Su vuelo va por ENCIMA de 0,27: la bola
##      del tablero (0,18 de alto) pasa por debajo sin tocar nada que no choque.
##   4. Partir lo grande: Compatibility da 8 luces por malla. Todo va a parar a
##      `_lienzo(material, punto)`, que reparte en celdas (`_celda`). Y NO MÁS
##      CELDAS de las que pide la luz: cada malla es una llamada de dibujo (dos si
##      entra en el reflejo), y MEDIA y BAJA tienen tope (≤ 450 y ≤ 300 en la
##      escena entera). Se mide con `--medir-arquitectura`: mallas por grupo y
##      cuántos fuegos toca la peor de cada uno.
##   5. Lo que quede por debajo de y = 0 va en `CAPA_BAJO_SUELO`, o la cámara
##      del reflejo lo dibuja encima de todo; lo de lo alto (`_lienzo(…, alto)`)
##      y los materiales de `SIN_REFLEJO` (el hierro, la madera del coro) van en
##      `CAPA_SIN_REFLEJO`, y lo alto sin sombra. Solo echa sombra lo que está a
##      la altura del campo: la única luz con sombra es un fuego del campo.
##  10. LA BÓVEDA NO SE ILUMINA, SE INSINÚA: su luz propia va en el canal B del
##      color de vértice (`Malla.libre`), multiplicada por la «emision» de su
##      material (`EMISION_*`). Ni una luz más ahí arriba. Quien toque una pieza
##      de la bóveda le pone su B o la deja a oscuras.
##  11. Las juntas de los sillares del mueble son una RANURA con su mortero
##      oscuro dentro (`JUNTA`, `_mortero`). Sin el mortero la ranura se ve de
##      lado a lado y sale como un hilo de luz.
##   6. La luna entra por el óculo (un foco SIN sombra desde detrás, lo pone
##      «entorno»). El óculo está en la recta de esa luz (centro (0,95; 1,55;
##      5,94) y la luz hacia (2; 0; 9)): su taladro la sigue. Si «entorno» cambia
##      la luna, cambia `OCULO_CENTRO` y `LUZ_HACIA` aquí.
##   7. Los raíles del campanario y del tobogán pasan a 11 px del arco y suben
##      hasta 0,6: la cara del ábside está `MURO_HOLGURA` px por detrás del arco
##      y lo que sobresale de ella (zócalo, cornisa) no pasa de 0,05 abajo.
##      «atrezzo» usa `MURO_HOLGURA` para colgar del muro.
##   8. Nada alto delante del campo: lo que sube por encima de `H_BORDE` está
##      detrás del arco o fuera de x ∈ [0, 4]. La excepción es el ARCO TRIUNFAL,
##      que pasa por encima de la cabeza del campo: su clave está a 5,4 para que
##      la recta de la cámara CENITAL a la punta del campo pase por debajo, y la
##      cámara SEGUIMIENTO (ojo a 4,7 como mucho) y la RASANTE (2,3) miran hacia
##      abajo y no lo ven más que en sus arranques.
##   9. LA BÓVEDA ES DE UNA CARA y mira hacia abajo: la CENITAL (y = 13,5) la ve
##      de espaldas y no la dibuja. Nada de lo de arriba puede tener una cara que
##      mire hacia arriba o hacia el jugador por encima del campo: por eso los
##      fajones no tienen lomo y el testero se echa hacia delante por encima de
##      `H_INCLINA`. Comprobado con `--vista=2`: la mesa se ve entera.

const Nucleo := preload("res://cripta3d/mundo_cripta.gd")
const MesaCripta := preload("res://cripta3d/mesa_cripta.gd")

const RUTA_CAPITEL := "res://cripta3d/modelos/arquitectura_capitel.glb"
const RUTA_OSARIO := "res://cripta3d/modelos/arquitectura_osario.glb"

## La cara del ábside, por detrás del arco de la mesa (px). «atrezzo» la lee.
const MURO_HOLGURA := 14.0
## El suelo de la sala (donde se apoya el bloque de la mesa) y por donde cierra
## la bóveda: los dos son del núcleo, porque los comparten tres módulos. Aquí se
## repiten como constantes porque «atrezzo» lee `Y_SALA` de este guion.
const Y_SALA := Nucleo.Y_SALA
const Y_BOVEDA := Nucleo.Y_BOVEDA
## La albardilla del mueble: hasta dónde sube y cuánto mide de ancho por fuera
## de las paredes de los lados (px) y por delante del desagüe (px).
const H_BORDE := 0.22
const BORDE := 52.0
const BORDE_PIE := 44.0
## La junta entre dos sillares del mueble (albardilla, frente, bordillo): la
## ranura que queda entre uno y el siguiente, en unidades.
const JUNTA := 0.008
## Cuánto se mete el mortero de esa junta por detrás de las caras. Poco: con 7 mm,
## mirando al sesgo se veía la testa del sillar de al lado, de canto a la luz,
## y la junta salía como un hilo CLARO; con 2 mm lo que se ve es el mortero.
const JUNTA_FONDO := 0.002
## El ábside: grueso, dónde empieza la cornisa y su vuelo, y lo alto de la
## coronación arruinada.
const ABSIDE_GRUESO := 0.42
const H_CORNISA := 2.06
const H_CORONA := 2.52
## Hornacinas: en qué ángulos del arco (0° la punta derecha), el radio del arco,
## la altura de la repisa y de la imposta, el fondo y el ancho de las dovelas.
const HORNACINAS_GRADOS: Array[float] = [18.0, 55.0, 90.0, 160.0]
const HORNACINA_R := 0.2
const HORNACINA_REPISA := 0.42
const HORNACINA_IMPOSTA := 0.86
const HORNACINA_FONDO := 0.16
const DOVELA := 0.09
## El óculo, en la recta de la luna (ver la cabecera, punto 6).
const OCULO_CENTRO := Vector3(0.95, 1.55, 5.94)
const LUZ_HACIA := Vector3(2.0, 0.0, 9.0)
const OCULO_R := 0.28
const OCULO_ANILLO := 0.1
## Las antorchas de la v0 de «atrezzo»: aquí solo se dejan sus apoyos.
const ANTORCHAS_GRADOS: Array[float] = [38.0, 72.0, 108.0, 142.0]
const H_ANTORCHA := 0.95
## La tribuna: la altura bajo la losa y cuánto vuela.
const H_BAJO_LOSA := 0.27
## La sala: muro del fondo, pilares, y hasta dónde llega el suelo.
const SALA_X := Vector2(-9.0, 13.0)
const SALA_Z := Vector2(2.5, 21.0)
const H_SALA_MURO := 3.6
const PILARES_X: Array[float] = [-3.0, 7.0]
const PILARES_Z: Array[float] = [9.2, 12.2, 15.2, 18.2]
## LA BÓVEDA. Una nave central de cañón entre las dos filas de pilares (de
## x = −3 a 7, clave en `Y_BOVEDA`) y dos naves laterales de cuarto de cañón
## que bajan hasta el muro de fuera (x = −9 y 13). Todas arrancan a `ARRANQUE`,
## encima del dintel que corre sobre los pilares; las de los lados acaban abajo
## a `COSTADO_Y`, sobre un muro.
const ARRANQUE := 4.6
const H_DINTEL := 0.3
const H_CAPITEL_PILAR := ARRANQUE - H_DINTEL
const COSTADO_Y := 2.2
const NAVE_LADO := 6.0
## EL TESTERO (el muro del fondo por encima del ábside) es vertical hasta
## `H_INCLINA` y de ahí sube echándose hacia delante `INCLINA` en z por unidad
## de alto. NO es por gusto: la cámara CENITAL mira desde (2; 13,5; 9,6), y una
## cara vertical que mira al jugador la ve de frente y TAPA lo que tiene detrás,
## que es el ábside y la cabeza del campo. Con más de 17° de inclinación esa
## cámara la ve de espaldas y no se dibuja; con 27° hay margen.
const H_INCLINA := 5.6
const INCLINA := 0.5
## EL ARCO TRIUNFAL y la bóveda del ábside: el arco es media elipse de 2,2 de
## ancho (de columna a columna) y 3,0 de alto sobre el cimacio. Más bajo, desde
## la CENITAL tapaba la punta del campo (z = 5,7 en x = 2): la recta de esa
## cámara a ese punto cruza el plano del arco a 4,75 de alto, y la clave tiene
## que quedar por encima (5,4).
const ARCO_Y := 2.40
const ARCO_ALTO := 3.0
const ARCO_ANCHO := 2.2
## Las cadenas de la viga de la campana: el eje de la campana y sus armellas,
## en `atrezzo.gd` (EJE_CAMPANA, ARMELLAS_X). Aquí solo se anclan.
const CADENAS_VIGA: Array[Vector2] = [Vector2(0.56, 7.42), Vector2(2.44, 7.42)]
## Las dos cadenas que «atrezzo» cuelga en la sala.
const CADENAS_SALA: Array[Vector2] = [Vector2(-2.35, 10.2), Vector2(6.4, 10.0)]
## Cuánto cuelga un arco fajón por debajo de la bóveda.
const FAJON_FONDO := 0.16
## Las celdas en que se parte la geometría del campo (8 luces por malla): tres
## columnas y seis filas sobre el mueble, de 1,55 × 1,34 (ver `_celda`). Con
## una rejilla de 1,6 anclada en x = 0 eran cuatro columnas y seis filas, la
## mitad con un palmo de albardilla: 111 mallas, la que más de la escena. Con
## cinco filas de 1,6, la celda del ábside derecho tocaba nueve fuegos.
## Lo que no entra en el reflejo del suelo mojado aunque esté a la altura del
## campo (cada malla que entra se dibuja dos veces). El hierro es menudo
## —pletinas, remaches, guías de varilla, la reja— y su reflejo, emborronado por
## la losa, no se lee; el piso del coro mira arriba y la cámara del espejo lo ve
## de espaldas: pagaba la llamada para no pintar nada. La piedra sí entra: el
## ábside reflejado es media atmósfera.
const SIN_REFLEJO: Array[String] = ["hierro", "madera"]
const REJILLA := Vector2i(3, 6)
const REJILLA_FONDO := 1.34
## Cada cuánto se parte a lo ancho lo que va sobre la cara curva del ábside. El
## muro tiene casi dos unidades de radio: a 0,15 la cuerda se separa de la curva
## un milímetro y medio, que no se ve; a 0,09 (lo de antes) costaba el doble.
const PASO_CURVA := 0.15

## Color de vértice: R oclusión, G canto. La oclusión del pie: a `PIE_ALTO`
## unidades por encima del suelo de cada pieza ya está al aire.
const PIE_ALTO := 0.32
const PIE_OSCURO := 0.42

## La luz propia de la bóveda (ver `_preparar_materiales`): la «emision» del
## sombreador, que va multiplicada por el canal B del vértice (0..1). Tan baja
## que no se lee como luz, sino como piedra que se adivina.
## Medido en la toma de la mesa mirando arriba: con 0,05 en los nervios y 0,06
## de luna, el cuarto de esfera era un plato azul y los nervios quedaban MÁS
## OSCUROS que él, al revés de lo que se pedía. Los nervios mandan sobre la
## plementería; la luna es un lavado que se acaba.
const EMISION_RECALOR := 0.07
const EMISION_NERVIO := 0.14
const COLOR_RECALOR := Color(0.95, 0.55, 0.3)
const EMISION_LUNA := 0.035
const COLOR_LUNA := Color(0.42, 0.55, 0.85)

var hornacinas: Array[Transform3D] = []
var repisas: Array[Transform3D] = []
var argollas: Array[Transform3D] = []
var apoyos_antorcha: Array[Transform3D] = []
var capiteles: Array[Transform3D] = []
var apoyos_pilar: Array[Transform3D] = []
var oculo := Transform3D()
var anclajes_boveda: Array[Transform3D] = []
var nichos_osario: Array[Transform3D] = []

var _mundo: Nucleo
var _mesa: MesaCripta
var _mats: Dictionary = {}
var _lienzos: Dictionary = {}
var _azar := RandomNumberGenerator.new()
var _abside: Cara = null
## Todo lo que este módulo cuelga del mundo y se dibuja: para medirlo y para
## apagarle la sombra según la calidad.
var _nodos: Array[GeometryInstance3D] = []
## El contorno del campo en px, para saber de qué lado de una pared está fuera.
var _x_izq := 20.0
var _x_der := 380.0
## El plano del muro del fondo de la sala (la cara que mira al jugador).
var _z_testero := 7.0
## La planta del mueble (x, z), de donde sale la rejilla de celdas.
var _mueble := Rect2()

func montar(mundo: Node3D) -> void:
	_mundo = mundo as Nucleo
	_mesa = _mundo.mesa
	_azar.seed = 1931
	_x_izq = _mesa.arco[_mesa.arco.size() - 1].x
	_x_der = _mesa.arco[0].x
	var z_frente := (_mesa.p.y_drenaje + BORDE_PIE) * Nucleo.E
	var fondo := REJILLA_FONDO * float(REJILLA.y)
	_mueble = Rect2((_x_izq - BORDE) * Nucleo.E, z_frente - fondo,
		(_x_der - _x_izq + 2.0 * BORDE) * Nucleo.E, fondo)
	_preparar_materiales()
	_abside = _mapa_abside()
	_z_testero = _abside.p(0.0, 0.0, 0.0).z
	_montar_paredes()
	_montar_mueble()
	_montar_abside()
	_montar_columnas()
	_montar_coro()
	_montar_sala()
	_montar_boveda()
	_volcar()
	if "--medir-arquitectura" in OS.get_cmdline_user_args():
		# Diferido: las luces las ponen los módulos que se montan DESPUÉS de este, y
		# lo que interesa es cuántas le tocan a cada malla con la escena entera.
		_contar.call_deferred()

func actualizar(_delta: float) -> void:
	pass

## LA CALIDAD (la pide el núcleo: 0 ALTA, 1 MEDIA, 2 BAJA). En MEDIA y BAJA la
## única sombra de fuego se apaga (la reparte «entorno»), así que aquí sobra
## dibujar nada en su mapa: se quita la sombra a todo. La geometría se queda
## entera, que es lo que hace que MEDIA y BAJA sigan siendo la misma cripta.
func calidad(n: int) -> void:
	for gi in _nodos:
		if not is_instance_valid(gi):
			continue
		if not gi.has_meta("sombra"):
			gi.set_meta("sombra", gi.cast_shadow)
		gi.cast_shadow = gi.get_meta("sombra") if n == 0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Lo que pesa el módulo: mallas (llamadas de dibujo de una pasada) y triángulos,
## con las instancias de un MultiMesh contadas una a una. Solo con
## `--medir-arquitectura`: es para no pasarse del presupuesto (≤ 65.000; en el
## remate, 70 mallas y 64.600 triángulos, de 111 y 60.500: las tres variantes
## del osario y el mortero de las juntas son la diferencia).
func _contar() -> void:
	var mallas := 0
	var tris := 0
	var con_sombra := 0
	var por: Dictionary = {}
	# LAS LUCES DE CADA MALLA. Compatibility aplica como mucho 8 omni por malla, y
	# las que pasan de ahí se quedan fuera SIN avisar (las primeras que empareja,
	# no las que más alumbran). Unir mallas ahorra llamadas, pero una malla que
	# toca más de 8 fuegos sale con manchas: se cuenta aquí antes de dar por buena
	# una celda.
	var omnis: Array[Node] = _mundo.find_children("*", "OmniLight3D", true, false)
	var peor := 0
	var por_mat: Dictionary = {}
	for gi in _nodos:
		if not is_instance_valid(gi):
			continue
		var caja := gi.global_transform * gi.get_aabb()
		var luces := 0
		for o: Node in omnis:
			var l := o as OmniLight3D
			var r := l.omni_range
			if caja.intersects(AABB(l.global_position - Vector3.ONE * r, Vector3.ONE * r * 2.0)):
				luces += 1
		peor = maxi(peor, luces)
		if luces > 8:
			print("ARQUITECTURA: %s toca %d fuegos (caja %s)" % [str(gi.get_meta("celda", gi.get_meta("arq", "?"))),
				luces, str(caja)])
		var g0: String = gi.get_meta("arq", "?")
		var cuenta: Vector2i = por_mat.get(g0, Vector2i.ZERO)
		por_mat[g0] = Vector2i(cuenta.x + 1, maxi(cuenta.y, luces))
	print("ARQUITECTURA: %d omni en la escena; la malla que más toca, %d" % [omnis.size(), peor])
	print("ARQUITECTURA: mallas y luces máximas por grupo %s" % str(por_mat))
	for gi in _nodos:
		if not is_instance_valid(gi):
			continue
		var t := 0
		if gi is MeshInstance3D:
			t = _tris_de((gi as MeshInstance3D).mesh)
		elif gi is MultiMeshInstance3D:
			var mm := (gi as MultiMeshInstance3D).multimesh
			t = _tris_de(mm.mesh) * mm.instance_count
		mallas += 1
		tris += t
		var g: String = gi.get_meta("arq", "?")
		por[g] = int(por.get(g, 0)) + t
		if gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			con_sombra += 1
	print("ARQUITECTURA: %d mallas (%d con sombra), %d triángulos" % [mallas, con_sombra, tris])
	print("ARQUITECTURA: por grupo %s" % str(por))

static func _tris_de(m: Mesh) -> int:
	if m == null:
		return 0
	var t := 0
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		var idx: Variant = arr[Mesh.ARRAY_INDEX]
		if idx is PackedInt32Array and (idx as PackedInt32Array).size() > 0:
			t += (idx as PackedInt32Array).size() / 3
		else:
			t += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return t

## Un punto de la cara del ábside (ver la cabecera).
func punto_abside(grados: float, altura: float, fuera: float = 0.0) -> Vector3:
	if _abside == null:
		_abside = _mapa_abside()
	return _abside.p(_abside.s_de(deg_to_rad(grados)), altura, fuera)

# =================================================================== materiales

func _preparar_materiales() -> void:
	var m: Object = _mundo.mat
	_mats["piedra"] = m.call("dame", "piedra", {"vertice": true, "escala": 0.9})
	_mats["sillar"] = m.call("dame", "piedra", {"vertice": true, "escala": 1.1, "semilla": 3.0})
	# El cuerpo del mueble y el muro de la sala son caras planas a eje: ahí el
	# despiece del sombreador cuadra, y sale mucho más barato que en geometría.
	_mats["aparejo"] = m.call("dame", "piedra", {"vertice": true, "escala": 1.0, "semilla": 7.0,
		"juntas": Vector3(0.74, 0.34, 0.74)})
	_mats["sala"] = m.call("dame", "piedra", {"vertice": true, "escala": 1.4, "semilla": 11.0,
		"tinte": Color(0.78, 0.78, 0.82), "juntas": Vector3(1.1, 0.46, 1.1)})
	# Las losas sueltas de alrededor del mueble: el mismo suelo, sin el dibujo de
	# las juntas (las juntas las hace la geometría) y con color de vértice.
	_mats["losa"] = m.call("dame", "losa", {"vertice": true, "escala": 1.3,
		"tinte": Color(0.55, 0.55, 0.58), "juntas": Vector3.ZERO, "mojado": 0.3})
	_mats["losas"] = m.call("dame", "losa", {"escala": 1.3, "tinte": Color(0.5, 0.5, 0.54),
		"juntas": Vector3(1.25, 0.0, 0.9), "mojado": 0.35})
	# La bóveda: la misma piedra, con el despiece más grande y más oscura (está en
	# penumbra y no tiene que competir con nada).
	# LA BÓVEDA SE INSINÚA (decisión 3 del remate): era media pantalla de negro.
	# No se ilumina —ni una luz más—: lleva una luz propia bajísima en el canal B
	# del color de vértice (`Malla.libre`), que el sombreador multiplica por su
	# «emision». Cálida en los nervios, el arco y los fajones, más cuanto más
	# cerca del ábside (es el rebote de sus fuegos); fría en el cuarto de esfera
	# junto al óculo (la luna que entra). La plementería, casi nada: lo que se lee
	# es la estructura, no el techo.
	var boveda: Material = m.call("dame", "piedra", {"vertice": true, "escala": 1.3, "semilla": 13.0,
		"tinte": Color(0.66, 0.66, 0.7), "juntas": Vector3(0.9, 0.4, 0.9), "emision": EMISION_RECALOR})
	_mats["boveda"] = _luz_propia(boveda, COLOR_RECALOR)
	var nervio: Material = m.call("dame", "piedra", {"vertice": true, "escala": 1.1, "semilla": 3.0,
		"emision": EMISION_NERVIO})
	_mats["nervio"] = _luz_propia(nervio, COLOR_RECALOR)
	var concha: Material = m.call("dame", "piedra", {"vertice": true, "escala": 1.1, "semilla": 5.0,
		"emision": EMISION_LUNA})
	_mats["concha"] = _luz_propia(concha, COLOR_LUNA)
	_mats["hierro"] = m.call("dame", "hierro", {"vertice": true, "escala": 0.35})
	_mats["madera"] = m.call("dame", "madera", {"vertice": true, "escala": 0.5,
		"veta": Vector3(0.0, 0.0, 1.0)})
	_mats["pozo"] = m.call("dame", "carbon", {"vertice": true})

## Una copia del material con su propio color de luz propia. Es una copia y no
## el de la biblioteca porque la biblioteca da la misma instancia a quien pida
## lo mismo, y el color es solo de la bóveda. Con la biblioteca de reserva (un
## material liso) se queda como está.
func _luz_propia(base: Material, color: Color) -> Material:
	var sm := base as ShaderMaterial
	if sm == null:
		return base
	var copia := sm.duplicate() as ShaderMaterial
	copia.set_shader_parameter("color_emision", color)
	return copia

## Cuánto del rebote del ábside llega a un punto de la bóveda: 1 sobre el ábside
## y la mitad a 2,4 de su boca (en planta). El primer fajón de la nave queda a
## ~0,9 en la clave y ~0,4 en los pilares; los de las naves laterales y los del
## fondo, casi a nada.
func _cerca_abside(p: Vector3) -> float:
	var d := Vector2(p.x - 2.0, maxf(p.z - _z_testero, 0.0)).length() - ARCO_ANCHO
	return exp(-maxf(d, 0.0) / 3.5)

# ======================================================== el reparto en mallas

## La malla donde va una pieza: una por material, por celda (`_celda`) y por
## clase. Lo que queda entero por debajo del suelo va a `CAPA_BAJO_SUELO`; lo
## que va `alto` (la bóveda y lo que cuelga de ella) va a `CAPA_SIN_REFLEJO`, sin
## sombra y en dos celdas: allí no llega ningún fuego, así que no hay ocho luces
## que repartir, y cada celda de más es una llamada de dibujo.
func _lienzo(material_pedido: String, donde: Vector3, bajo_suelo: bool = false, alto: bool = false) -> Malla:
	# «piedra» y «sillar» eran dos variantes de LA MISMA piedra (la biblioteca ya
	# no cambia el grano con la escala) y cada una pagaba su malla en cada celda:
	# en las del ábside y la albardilla del arco iban las dos. Van juntas.
	var material := "sillar" if material_pedido == "piedra" else material_pedido
	var clase := 2 if alto else (1 if bajo_suelo else 0)
	var celda := _celda(donde, clase)
	var clave := "%s|%d|%d|%d" % [material, celda.x, celda.y, clase]
	if not _lienzos.has(clave):
		var nueva := Malla.new()
		nueva.material = material
		nueva.bajo_suelo = bajo_suelo
		nueva.alto = alto
		_lienzos[clave] = nueva
	return _lienzos[clave]

## LA CELDA de una pieza, según su clase. Es lo que decide cuántas llamadas de
## dibujo cuesta el módulo (una por material y celda; las de la clase 0, otra más
## en el reflejo), y el tope es la luz: Compatibility aplica 8 omni por malla.
##   0 (el campo y lo que lo rodea)  una rejilla de `REJILLA` celdas ALINEADA con
##       el mueble: del tamaño de la de 1,6 de antes (y así ≤ 8 fuegos por celda,
##       medido con `--medir-arquitectura`), pero sin las columnas de medio
##       palmo que dejaba una rejilla anclada en x = 0
##   1 (lo de debajo del tablero)  izquierda, mueble y derecha × fondo y pie:
##       losas, suelo de la nave, cuerpo del mueble y muro del osario. Ahí abajo
##       solo llegan los fuegos de la sala
##   2 (lo alto)  tres a lo ancho y el testero aparte: a la bóveda no llega
##       ningún fuego y cada celda de más era una llamada perdida (eran 26); al
##       pie del testero y a los muros de fuera, sí
func _celda(donde: Vector3, clase: int) -> Vector2i:
	if clase == 2:
		# En tres a lo ancho y el testero aparte: su pie y los muros de fuera sí
		# los alumbran los fuegos de la sala (en dos, cada mitad tocaba once).
		var ax := 0 if donde.x < -1.0 else (2 if donde.x > 5.0 else 1)
		return Vector2i(ax, 0 if donde.z < _z_testero + 2.0 else 1)
	if clase == 1:
		var cx := 1
		if donde.x < _mueble.position.x - 0.05:
			cx = 0
		elif donde.x > _mueble.end.x + 0.05:
			cx = 2
		return Vector2i(cx, 0 if donde.z < _mueble.get_center().y else 1)
	var tam := _mueble.size / Vector2(REJILLA)
	return Vector2i(clampi(floori((donde.x - _mueble.position.x) / tam.x), 0, REJILLA.x - 1),
		clampi(floori((donde.z - _mueble.position.y) / tam.y), 0, REJILLA.y - 1))

func _volcar() -> void:
	for clave: String in _lienzos:
		var m: Malla = _lienzos[clave]
		if m.v.is_empty():
			continue
		var mi := MeshInstance3D.new()
		mi.set_meta("arq", m.material + ("·alto" if m.alto else ("·bajo" if m.bajo_suelo else "")))
		mi.set_meta("celda", clave)
		mi.mesh = m.malla()
		mi.material_override = _mats[m.material]
		# LA SOMBRA, solo lo que está a la altura del campo. La única luz que hace
		# sombra es un fuego DEL CAMPO (la luna ya no: entra por el óculo sin
		# sombra), y lo que hay por debajo del tablero o en lo alto de la sala no
		# puede echarle sombra a nada que se vea; en cambio cada malla con sombra
		# se vuelve a dibujar seis veces en el mapa de la omni.
		var sombra := not (m.alto or m.bajo_suelo)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra 			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if m.bajo_suelo:
			mi.layers = Nucleo.CAPA_BAJO_SUELO
		elif m.alto or m.material in SIN_REFLEJO:
			mi.layers = Nucleo.CAPA_SIN_REFLEJO
		_mundo.add_child(mi)
		_nodos.append(mi)
	_lienzos.clear()

# ================================================================ las paredes

func _fuera_del_campo(q: Vector2) -> bool:
	if q.x < _x_izq or q.x > _x_der or q.y > _mesa.p.y_drenaje:
		return true
	var c := _mesa.arco_centro
	var r := _mesa.arco_radios
	if q.y < c.y:
		return Vector2((q.x - c.x) / r.x, (q.y - c.y) / r.y).length_squared() > 1.0
	return false

## La normal de la elipse del arco en un punto, hacia fuera (px).
func _normal_arco(q: Vector2) -> Vector2:
	var c := _mesa.arco_centro
	var r := _mesa.arco_radios
	return Vector2((q.x - c.x) / (r.x * r.x), (q.y - c.y) / (r.y * r.y)).normalized()

func _montar_paredes() -> void:
	var arco: Array = []
	for c in _mesa.colisionadores:
		if c.tipo != Colisionador.Tipo.PARED:
			continue
		if c.capas == Colisionador.bit(Mesa.CAPA_ALTA):
			_baranda(c.a, c.b)
			continue
		if c.capas != Colisionador.TODAS:
			continue
		var largo := c.a.distance_to(c.b)
		if largo < 0.5:
			continue
		var d := (c.b - c.a) / largo
		var nrm := Vector2(-d.y, d.x)
		var fa := _fuera_del_campo(c.centro() + nrm * 6.0)
		var fb := _fuera_del_campo(c.centro() - nrm * 6.0)
		if fa != fb:
			var fuera := nrm if fa else -nrm
			if c.centro().y < _mesa.arco_centro.y + 1.0:
				arco.append([c.a, c.b])
			else:
				_albardilla_lado(c.a, c.b, fuera)
		elif largo <= 30.0:
			if _es_tope_lanzador(c.a, c.b):
				_tope_lanzador(c.a, c.b)
			else:
				_mojon(c.a, c.b)
		elif largo < 150.0:
			_guia_hierro(c.a, c.b)
		else:
			_bordillo(c.a, c.b)
	_albardilla_arco(arco)

## El borde exterior de un lado: sillares de albardilla desde la línea del
## colisionador hasta el borde del mueble.
func _albardilla_lado(a: Vector2, b: Vector2, fuera: Vector2) -> void:
	var largo := a.distance_to(b)
	var d := (b - a) / largo
	var x := 0.0
	var i := 0
	while x < largo - 1.0:
		var paso := _azar.randf_range(48.0, 72.0)
		if largo - (x + paso) < 30.0:
			paso = largo - x
		var p0 := a + d * x
		var p1 := a + d * (x + paso)
		# La junta: cada sillar se queda medio `JUNTA` corto por cada punta. Las
		# caras de delante y de fuera eran un plano continuo de punta a punta (los
		# cantos solo llevan bisel arriba): sin esa ranura no se leía el despiece.
		var j := d * JUNTA * 0.5 / Nucleo.E
		var pol := PackedVector2Array([(p0 + j) * Nucleo.E, (p1 - j) * Nucleo.E,
			(p1 - j + fuera * BORDE) * Nucleo.E, (p0 + j + fuera * BORDE) * Nucleo.E])
		var m := _lienzo("piedra", _centro3(pol, 0.1))
		_pieza(m, _plano(), pol, -0.04, H_BORDE - _azar.randf_range(0.0, 0.008),
			_azar.randf_range(0.02, 0.03), 0.0, 1.0)
		if x > 0.0:
			var ji := JUNTA_FONDO / Nucleo.E
			_mortero(m, PackedVector2Array([(p0 - j * 1.2 + fuera * ji) * Nucleo.E,
				(p0 + j * 1.2 + fuera * ji) * Nucleo.E, (p0 + j * 1.2 + fuera * (BORDE - ji)) * Nucleo.E,
				(p0 - j * 1.2 + fuera * (BORDE - ji)) * Nucleo.E]), -0.04, H_BORDE - 0.03)
		# Una pletina de hierro cruzando la albardilla cada tres piedras.
		if i % 3 == 1:
			_pletina_cruzada(p0 * Nucleo.E, fuera)
		x += paso
		i += 1

## El arco: la media luna de piedra entre la línea del arco y la cara del
## ábside, de tres en tres segmentos.
func _albardilla_arco(arco: Array) -> void:
	var por_piedra := 3
	var i := 0
	while i < arco.size():
		var fin := mini(i + por_piedra, arco.size())
		var dentro := PackedVector2Array()
		var afuera := PackedVector2Array()
		for k in range(i, fin):
			var seg: Array = arco[k]
			var q0: Vector2 = seg[0]
			if k == i:
				dentro.append(q0 * Nucleo.E)
				afuera.append((q0 + _normal_arco(q0) * MURO_HOLGURA) * Nucleo.E)
			var q1: Vector2 = seg[1]
			dentro.append(q1 * Nucleo.E)
			afuera.append((q1 + _normal_arco(q1) * MURO_HOLGURA) * Nucleo.E)
		var pol := PackedVector2Array()
		pol.append_array(dentro)
		afuera.reverse()
		pol.append_array(afuera)
		var m := _lienzo("piedra", _centro3(pol, 0.1))
		_pieza(m, _plano(), pol, -0.04, H_BORDE - _azar.randf_range(0.0, 0.01),
			0.022, 0.0, 1.0)
		i = fin

## El separador del carril lanzador: bordillo fino con pletina de hierro.
func _bordillo(a: Vector2, b: Vector2) -> void:
	var largo := a.distance_to(b)
	var d := (b - a) / largo
	var n := Vector2(-d.y, d.x)
	var medio := 3.5
	var x := 0.0
	while x < largo - 1.0:
		var paso := minf(_azar.randf_range(55.0, 80.0), largo - x)
		# Con su junta, como la albardilla (ver `_albardilla_lado`).
		var p0 := a + d * (x + JUNTA * 0.5 / Nucleo.E)
		var p1 := a + d * (x + paso - JUNTA * 0.5 / Nucleo.E)
		var pol := PackedVector2Array([(p0 + n * medio) * Nucleo.E, (p1 + n * medio) * Nucleo.E,
			(p1 - n * medio) * Nucleo.E, (p0 - n * medio) * Nucleo.E])
		var mb := _lienzo("piedra", _centro3(pol, 0.1))
		_pieza(mb, _plano(), pol, -0.02, 0.135, 0.012, 0.0, 1.0)
		if x > 0.0:
			var q := a + d * x
			var jd := d * JUNTA * 0.6 / Nucleo.E
			var ji := medio - JUNTA_FONDO / Nucleo.E
			_mortero(mb, PackedVector2Array([(q - jd + n * ji) * Nucleo.E, (q + jd + n * ji) * Nucleo.E,
				(q + jd - n * ji) * Nucleo.E, (q - jd - n * ji) * Nucleo.E]), -0.02, 0.12)
		x += paso
	# La pletina, de punta a punta, con sus remaches.
	var h := _lienzo("hierro", Nucleo.E * Vector3((a.x + b.x) * 0.5, 0.0, (a.y + b.y) * 0.5))
	var pl := PackedVector2Array([(a + n * 2.2) * Nucleo.E, (b + n * 2.2) * Nucleo.E,
		(b - n * 2.2) * Nucleo.E, (a - n * 2.2) * Nucleo.E])
	_pieza(h, _plano(), pl, 0.128, 0.147, 0.004, 0.0, 1.0)
	var t := 25.0
	while t < largo - 10.0:
		var q := (a + d * t) * Nucleo.E
		_remache(h, Vector3(q.x, 0.147, q.y), Vector3.UP, 0.009)
		t += 25.0

## Un cierre corto: un mojón de piedra.
func _mojon(a: Vector2, b: Vector2) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)
	var medio := 4.5
	var pol := PackedVector2Array([(a + n * medio - d * 2.0) * Nucleo.E,
		(b + n * medio + d * 2.0) * Nucleo.E, (b - n * medio + d * 2.0) * Nucleo.E,
		(a - n * medio - d * 2.0) * Nucleo.E])
	_pieza(_lienzo("piedra", _centro3(pol, 0.1)), _plano(), pol, -0.02, 0.17, 0.014, 0.0, 1.0)

## El cierre de abajo del carril lanzador: la pared que cruza el carril por
## debajo de donde espera la bola.
func _es_tope_lanzador(a: Vector2, b: Vector2) -> bool:
	if absf(a.y - b.y) > 0.5 or a.y < 1100.0:
		return false
	return minf(a.x, b.x) >= _x_carril() - 1.0 and maxf(a.x, b.x) <= _x_der + 1.0

## EL TOPE DEL LANZADOR, con un taladro para el ariete. Era un mojón macizo, y
## la cabeza del ariete («piezas»: de 0,03 a 0,15 de alto, en z de 12,60 a 12,69,
## y retrocede 0,15 al cargar) quedaba DENTRO de la piedra: no se veía nunca. Es
## el mismo bloque, con un agujero redondo a la altura del eje (el centro de la
## bola) por el que asoma y entra el ariete. Va en dos mitades, una por cara,
## para que el bloque tenga cara por delante y por detrás.
##
## Y EN DOS OREJETAS (remate): era un dintel que cruzaba el carril a la altura
## de la bola, y la bola en reposo —justo cuando el jugador la mira antes de
## lanzar— quedaba medio tapada, cortada en recto por el bloque. Ahora son dos
## orejetas de piedra, una pegada a cada pared del carril, con una pletina de
## hierro encima; entre las dos pasa el ariete y la bola se ve entera. Cada
## orejeta llega hasta `OREJETA_LIBRE` del eje: un pelo más que el radio de la
## bola (0,09), para que no le muerda la silueta; el ariete pasa holgado.
const OREJETA_LIBRE := 0.094

func _tope_lanzador(a: Vector2, b: Vector2) -> void:
	var e := Nucleo.E
	var zc := (a.y + b.y) * 0.5 * e
	var x0 := (minf(a.x, b.x) - 2.0) * e
	var x1 := (maxf(a.x, b.x) + 2.0) * e
	var eje := _mesa.p.inicio_bola.x * e
	var medio := 4.5 * e
	var m := _lienzo("piedra", Vector3((x0 + x1) * 0.5, 0.1, zc))
	var h := _lienzo("hierro", Vector3((x0 + x1) * 0.5, 0.1, zc))
	for tramo: Vector2 in [Vector2(x0, eje - OREJETA_LIBRE), Vector2(eje + OREJETA_LIBRE, x1)]:
		if tramo.y - tramo.x < 0.01:
			continue
		# La orejeta: un bloque de piedra con el canto de arriba biselado y la
		# punta de dentro achaflanada (no es un ladrillo, es un tope labrado).
		var hacia := 1.0 if tramo.x <= x0 + 0.001 else -1.0
		var punta := tramo.y if hacia > 0.0 else tramo.x
		var raiz := tramo.x if hacia > 0.0 else tramo.y
		var pol := PackedVector2Array([Vector2(raiz, zc - medio), Vector2(punta - hacia * 0.012, zc - medio),
			Vector2(punta, zc - medio + 0.012), Vector2(punta, zc + medio - 0.012),
			Vector2(punta - hacia * 0.012, zc + medio), Vector2(raiz, zc + medio)])
		# LA OREJETA IZQUIERDA VA 6 mm MÁS BAJA (último retoque). La derecha se
		# hunde en la albardilla (0,22) y solo asoma su punta, rematada por la
		# pletina. La izquierda cae ENTERA dentro del bordillo del carril: la
		# pletina de hierro del bordillo llega a 0,147 y cubre ±2,2 px, y la
		# orejeta, de 2 px dentro de la pared a 3,6 px del eje del bordillo, salía
		# 3 mm por encima. Por los dos cabos, donde su pletina (±0,6 del fondo) ya
		# no la tapa, la piedra asomaba sobre el hierro: un hueco claro de seis
		# lados en la pletina negra (no da error: se ve). A 0,144 queda 3 mm por
		# debajo de la pletina del bordillo, y lo que se ve es su propio remate de
		# hierro, igual que en la derecha.
		var alto := 0.144 if hacia > 0.0 else 0.15
		_pieza(m, _plano(), pol, -0.02, alto, 0.012, 0.0, 1.0)
		# La pletina de hierro que la remata, con un remache.
		var pl := PackedVector2Array([Vector2(raiz, zc - medio * 0.6), Vector2(punta - hacia * 0.006, zc - medio * 0.6),
			Vector2(punta - hacia * 0.006, zc + medio * 0.6), Vector2(raiz, zc + medio * 0.6)])
		_pieza(h, _plano(), pl, 0.14, 0.156, 0.003, 0.0, 1.0)
		_remache(h, Vector3((raiz + punta) * 0.5, 0.156, zc), Vector3.UP, 0.009)

## Una guía de carril: dos barras de hierro forjado entre postes.
func _guia_hierro(a: Vector2, b: Vector2) -> void:
	var pa := Vector3(a.x, 0.0, a.y) * Nucleo.E
	var pb := Vector3(b.x, 0.0, b.y) * Nucleo.E
	var h := _lienzo("hierro", (pa + pb) * 0.5)
	var dir := (pb - pa).normalized()
	var lado := dir.cross(Vector3.UP).normalized()
	var barra := _seccion_rombo(0.0085)
	for alto: float in [0.055, 0.128]:
		_barrido(h, PackedVector3Array([pa + Vector3.UP * alto, pb + Vector3.UP * alto]),
			lado, barra, 0.0, true)
	var largo := pa.distance_to(pb)
	var postes := 2 if largo < 0.7 else 3
	for k in postes:
		var q := pa.lerp(pb, float(k) / float(postes - 1))
		_poste(h, q, 0.15, 0.012)

func _poste(m: Malla, q: Vector3, alto: float, medio: float) -> void:
	var sec := _seccion_cuadrada(medio, medio * 0.3)
	_barrido(m, PackedVector3Array([q, q + Vector3.UP * alto]), Vector3.RIGHT, sec, q.y, true)
	# El collarín y el botón de arriba.
	_barrido(m, PackedVector3Array([q + Vector3.UP * (alto * 0.42 - 0.006),
		q + Vector3.UP * (alto * 0.42 + 0.006)]), Vector3.RIGHT,
		_seccion_cuadrada(medio * 1.45, medio * 0.5), q.y, true)
	_torno(m, q + Vector3.UP * alto, [Vector2(medio * 1.3, 0.0), Vector2(medio * 1.5, 0.008),
		Vector2(medio * 1.1, 0.02), Vector2(0.0, 0.026)], 8, q.y)

## La pletina que cruza la albardilla de un lado y baja por la cara de fuera.
func _pletina_cruzada(q: Vector2, fuera: Vector2) -> void:
	var a := q - fuera * 0.005
	var b := q + fuera * (BORDE * Nucleo.E + 0.004)
	var t := Vector2(-fuera.y, fuera.x) * 0.026
	var h := _lienzo("hierro", Vector3(q.x, 0.1, q.y))
	var pol := PackedVector2Array([a + t, b + t, b - t, a - t])
	_pieza(h, _plano(), pol, H_BORDE - 0.01, H_BORDE + 0.008, 0.004, 0.0, 1.0)
	# La bajada por la cara de fuera del mueble.
	var o3 := Vector3(b.x, 0.0, b.y)
	var mv := _vertical(o3, Vector3(t.x, 0.0, t.y).normalized(), Vector3(fuera.x, 0.0, fuera.y))
	_pieza(h, mv, PackedVector2Array([Vector2(-0.026, -0.42), Vector2(0.026, -0.42),
		Vector2(0.026, H_BORDE + 0.008), Vector2(-0.026, H_BORDE + 0.008)]), -0.01, 0.006,
		0.004, -0.9, 1.0)
	for k in 3:
		var r := a.lerp(b, 0.2 + 0.3 * float(k))
		_remache(h, Vector3(r.x, H_BORDE + 0.008, r.y), Vector3.UP, 0.011)
	for y: float in [0.06, -0.12, -0.32]:
		_remache(h, o3 + Vector3(fuera.x, 0.0, fuera.y) * 0.006 + Vector3.UP * y,
			Vector3(fuera.x, 0.0, fuera.y), 0.011)

# ================================================================ la barandilla

## La barandilla del coro: un colisionador de la capa alta. Pasamanos y
## travesaño de hierro, balaustres cada 6 cm y un poste en cada punta. (A 4,5 cm
## y con nudo de seis lados, la barandilla sola eran cinco mil triángulos.)
func _baranda(a2: Vector2, b2: Vector2) -> void:
	var h0 := Nucleo.H_ALTA
	var pa := Vector3(a2.x, h0, a2.y) * Vector3(Nucleo.E, 1.0, Nucleo.E)
	var pb := Vector3(b2.x, h0, b2.y) * Vector3(Nucleo.E, 1.0, Nucleo.E)
	var m := _lienzo("hierro", (pa + pb) * 0.5)
	var dir := (pb - pa).normalized()
	var lado := dir.cross(Vector3.UP).normalized()
	_barrido(m, PackedVector3Array([pa + Vector3.UP * 0.125, pb + Vector3.UP * 0.125]),
		lado, _seccion_cuadrada(0.011, 0.004), h0, true)
	_barrido(m, PackedVector3Array([pa + Vector3.UP * 0.022, pb + Vector3.UP * 0.022]),
		lado, _seccion_cuadrada(0.007, 0.002), h0, true)
	var largo := pa.distance_to(pb)
	var n := maxi(int(largo / 0.06), 1)
	for k in range(1, n):
		var q := pa.lerp(pb, float(k) / float(n))
		_barrido(m, PackedVector3Array([q + Vector3.UP * 0.022, q + Vector3.UP * 0.125]),
			lado.rotated(Vector3.UP, PI * 0.25), _seccion_cuadrada(0.0045, 0.0), h0, false)
		# Un nudo a media altura: el balaustre forjado, no el alambre.
		_torno(m, q + Vector3.UP * 0.066, [Vector2(0.004, -0.008), Vector2(0.0085, 0.0),
			Vector2(0.004, 0.008)], 5, h0)
	for q: Vector3 in [pa, pb]:
		_poste(m, q, 0.15, 0.013)

# ================================================================== el mueble

## El sarcófago: el cuerpo de piedra hasta el suelo de la sala, el frente con
## el desagüe y el carril lanzador. La albardilla de los lados ya la han puesto
## las paredes exteriores.
func _montar_mueble() -> void:
	var e := Nucleo.E
	var xi := (_x_izq - BORDE) * e
	var xd := (_x_der + BORDE) * e
	var z_pie := _mesa.p.y_drenaje * e
	var z_frente := (_mesa.p.y_drenaje + BORDE_PIE) * e
	var z_fondo := _mesa.arco_centro.y * e

	# EL CUERPO: una moldura corrida por los tres lados, del suelo de la sala a
	# la albardilla. Zócalo abajo, la cara lisa con el aparejo del sombreador, y
	# arriba el goterón: la albardilla vuela dos centímetros sobre la cara.
	var cuerpo := PackedVector2Array([Vector2(xi, z_fondo), Vector2(xi, z_frente),
		Vector2(xd, z_frente), Vector2(xd, z_fondo)])
	var perfil: Array[Vector3] = [
		Vector3(0.07, Y_SALA - 0.01, 0.0), Vector3(0.07, Y_SALA + 0.11, 0.0),
		Vector3(0.055, Y_SALA + 0.135, 1.0), Vector3(0.03, Y_SALA + 0.15, 0.0),
		Vector3(0.0, Y_SALA + 0.17, 0.0), Vector3(0.0, -0.035, 0.0)]
	_barrido_planta(cuerpo, Vector2(2.0, 10.0), perfil, "aparejo", Y_SALA)
	# LA MOLDURA bajo la albardilla: un bocel corrido por los tres lados, donde
	# acaban los sillares de la albardilla y empieza el cuerpo. Sin ella la cara
	# de delante era un plano de medio metro de alto sin nada que la partiera.
	var bocel: Array[Vector3] = [
		Vector3(0.0, -0.26, 0.0), Vector3(0.012, -0.252, 0.0), Vector3(0.024, -0.236, 0.6),
		Vector3(0.028, -0.222, 1.0), Vector3(0.022, -0.208, 0.6), Vector3(0.012, -0.2, 0.0),
		Vector3(0.0, -0.196, 0.0)]
	_barrido_planta(cuerpo, Vector2(2.0, 10.0), bocel, "aparejo", Y_SALA)

	# LA ALBARDILLA DEL FRENTE, con el canal del desagüe recortado. Va en
	# sillares a lo ancho; lo que cae en el canal o en el pozo se recorta.
	var canal := Rect2(Vector2(_x_izq * e, z_pie), Vector2((_mesa.p.flipper_eje_der.x + 70.0) * e - _x_izq * e, 0.16))
	# El canal llega hasta el separador del carril lanzador (el último colisionador
	# vertical por dentro de la pared derecha): por ahí no cae bola.
	canal.size.x = _x_carril() * e - canal.position.x
	var pozo := Vector2(Mesa.ANCHO * 0.5 * e, z_pie + 0.12)
	var r_pozo := 0.105
	var r_aro := 0.175
	var corte_canal := PackedVector2Array([canal.position, Vector2(canal.end.x, canal.position.y),
		canal.end, Vector2(canal.position.x, canal.end.y)])
	var corte_pozo := _circulo(pozo, r_aro + 0.008, 28)
	# EL CORTE, con las esquinas redondeadas. Donde el canal recto se encontraba
	# con el círculo del pozo la piedra quedaba en dos picos de punta fina, y el
	# bisel los convertía en dos dientes de sierra. Se cierra la figura (se
	# engorda y se adelgaza lo mismo, con esquina redonda), que redondea justo
	# esos dos rincones y deja igual lo demás.
	var corte := _cerrar(Geometry2D.merge_polygons(corte_canal, corte_pozo), 0.035)
	var x := xi
	while x < xd - 0.01:
		var paso := _azar.randf_range(0.5, 0.72)
		if xd - (x + paso) < 0.3:
			paso = xd - x
		# Con su junta (ver `_albardilla_lado`): la cara de delante del mueble era
		# una losa lisa de cuatro metros.
		var bloque := PackedVector2Array([Vector2(x + JUNTA * 0.5, z_pie),
			Vector2(x + paso - JUNTA * 0.5, z_pie), Vector2(x + paso - JUNTA * 0.5, z_frente),
			Vector2(x + JUNTA * 0.5, z_frente)])
		for trozo in _restar(bloque, corte):
			_pieza(_lienzo("piedra", _centro3(trozo, 0.1)), _plano(), trozo, -0.2,
				H_BORDE - _azar.randf_range(0.0, 0.008), _azar.randf_range(0.02, 0.028), -0.12, 1.0)
		if x > xi + 0.01:
			var junta := PackedVector2Array([Vector2(x - JUNTA * 0.6, z_pie + JUNTA_FONDO),
				Vector2(x + JUNTA * 0.6, z_pie + JUNTA_FONDO), Vector2(x + JUNTA * 0.6, z_frente - JUNTA_FONDO),
				Vector2(x - JUNTA * 0.6, z_frente - JUNTA_FONDO)])
			for trozo in _restar(junta, corte):
				_mortero(_lienzo("piedra", _centro3(trozo, 0.1)), trozo, -0.2, H_BORDE - 0.03)
		x += paso

	# El fondo del canal, cayendo hacia el pozo, y su labio del lado del campo
	# (por debajo del tablero, que es un plano sin grueso).
	var m := _lienzo("piedra", Vector3(pozo.x, 0.0, pozo.y))
	for lado: float in [-1.0, 1.0]:
		var x0 := pozo.x
		var x1: float = canal.position.x if lado < 0.0 else canal.end.x
		var tramo := PackedVector2Array([Vector2(x0, canal.position.y), Vector2(x1, canal.position.y),
			Vector2(x1, canal.end.y), Vector2(x0, canal.end.y)])
		for trozo in _restar(tramo, [_circulo(pozo, r_pozo, 24)]):
			_pieza(_lienzo("piedra", _centro3(trozo, -0.1)), _plano(), trozo, -0.24, -0.12,
				0.0, -0.12, 1.0, 0.55)
	var labio := PackedVector2Array([Vector2(canal.position.x, z_pie - 0.03),
		Vector2(canal.end.x, z_pie - 0.03), Vector2(canal.end.x, z_pie), Vector2(canal.position.x, z_pie)])
	for trozo in _restar(labio, [_circulo(pozo, r_pozo, 24)]):
		_pieza(m, _plano(), trozo, -0.24, -0.003, 0.0, -0.12, 1.0)

	# EL POZO: un tubo negro hacia abajo y el aro de hierro remachado.
	var pz := _lienzo("pozo", Vector3(pozo.x, -0.2, pozo.y), true)
	_torno(pz, Vector3(pozo.x, -0.5, pozo.y), [Vector2(0.0, 0.0), Vector2(r_pozo, 0.0),
		Vector2(r_pozo, 0.42)], 20, -0.6, true)
	var h := _lienzo("hierro", Vector3(pozo.x, 0.0, pozo.y))
	# El perfil sube por FUERA y baja por dentro: así las normales miran afuera.
	_torno(h, Vector3(pozo.x, -0.06, pozo.y), [Vector2(r_aro + 0.004, 0.0),
		Vector2(r_aro, 0.058), Vector2(r_aro - 0.012, 0.072), Vector2(r_pozo + 0.006, 0.068),
		Vector2(r_pozo - 0.004, 0.05), Vector2(r_pozo - 0.004, -0.06)], 28, -0.1)
	for k in 10:
		var ang := TAU * (float(k) + 0.5) / 10.0
		var rr := (r_pozo + r_aro) * 0.5 + 0.004
		_remache(h, Vector3(pozo.x + cos(ang) * rr, 0.01, pozo.y + sin(ang) * rr), Vector3.UP, 0.015)
	# EL ARO DE ARRIBA: una banda de hierro remachada que remata el borde del
	# corte sobre la albardilla, que es lo que se ve desde la cámara de juego (el
	# aro del pozo queda abajo, en el canal). Es el aro del sprite del desagüe.
	var desde := asin(clampf((canal.end.y - pozo.y) / (r_aro + 0.008), -1.0, 1.0)) + 0.32
	var hasta := PI - desde
	var banda := PackedVector2Array()
	var nb := 16
	for k in nb + 1:
		var ang := lerpf(desde, hasta, float(k) / float(nb))
		banda.append(pozo + Vector2(cos(ang), sin(ang)) * (r_aro + 0.012))
	for k in nb + 1:
		var ang := lerpf(hasta, desde, float(k) / float(nb))
		banda.append(pozo + Vector2(cos(ang), sin(ang)) * (r_aro + 0.06))
	_pieza(h, _plano(), banda, H_BORDE - 0.012, H_BORDE + 0.008, 0.004, 0.0, 1.0)
	for k in 7:
		var ang := lerpf(desde + 0.1, hasta - 0.1, float(k) / 6.0)
		_remache(h, Vector3(pozo.x + cos(ang) * (r_aro + 0.036), H_BORDE + 0.008,
			pozo.y + sin(ang) * (r_aro + 0.036)), Vector3.UP, 0.014)

	# LAS CANTONERAS: escuadras de hierro en las dos esquinas de delante, sobre
	# la albardilla y bajando por las dos caras.
	for esquina: Vector2 in [Vector2(xi, z_frente), Vector2(xd, z_frente)]:
		_cantonera(esquina, signf(esquina.x - 2.0))

	# EL CARRIL LANZADOR: dos guías de hierro en el fondo, a 7 px del eje de la
	# bola, por debajo de donde la toca.
	_guias_lanzador()

## El separador del carril lanzador: la pared interior larga más a la derecha.
func _x_carril() -> float:
	var mejor := _x_der
	for c in _mesa.colisionadores:
		if c.tipo != Colisionador.Tipo.PARED or c.capas != Colisionador.TODAS:
			continue
		if absf(c.a.x - c.b.x) < 0.5 and c.a.distance_to(c.b) >= 150.0 and c.a.x < _x_der - 1.0:
			if c.a.x > _x_izq + 1.0 and (mejor == _x_der or c.a.x > mejor):
				mejor = c.a.x
	return mejor

func _guias_lanzador() -> void:
	var x0 := _x_carril()
	var eje := (x0 + _x_der) * 0.5
	# De la pared de arriba del carril a la de abajo.
	var arriba := 0.0
	var abajo := _mesa.p.y_drenaje
	for c in _mesa.colisionadores:
		if c.tipo != Colisionador.Tipo.PARED or absf(c.a.y - c.b.y) > 0.5:
			continue
		if minf(c.a.x, c.b.x) >= x0 - 1.0 and maxf(c.a.x, c.b.x) <= _x_der + 1.0:
			if c.a.y < 1100.0:
				arriba = maxf(arriba, c.a.y)
			else:
				abajo = minf(abajo, c.a.y)
	if arriba <= 0.0:
		return
	var e := Nucleo.E
	var h := _lienzo("hierro", Vector3(eje * e, 0.0, (arriba + abajo) * 0.5 * e))
	for dx: float in [-7.0, 7.0]:
		var gx := (eje + dx) * e
		var pol := PackedVector2Array([Vector2(gx - 0.007, (arriba + 4.0) * e),
			Vector2(gx + 0.007, (arriba + 4.0) * e), Vector2(gx + 0.007, (abajo - 4.0) * e),
			Vector2(gx - 0.007, (abajo - 4.0) * e)])
		_pieza(h, _plano(), pol, -0.01, 0.011, 0.003, 0.0, 1.0)
		var z := (arriba + 20.0) * e
		while z < (abajo - 10.0) * e:
			_remache(h, Vector3(gx, 0.011, z), Vector3.UP, 0.006)
			z += 0.3

func _cantonera(esquina: Vector2, lado_x: float) -> void:
	var h := _lienzo("hierro", Vector3(esquina.x, 0.0, esquina.y))
	var brazo := 0.2
	var ancho := 0.055
	var dx := -lado_x
	# Sobre la albardilla: una L.
	var l := PackedVector2Array([esquina + Vector2(0.004 * lado_x, 0.004),
		esquina + Vector2(dx * brazo, 0.004), esquina + Vector2(dx * brazo, -ancho),
		esquina + Vector2(dx * ancho, -ancho), esquina + Vector2(dx * ancho, -brazo),
		esquina + Vector2(0.004 * lado_x, -brazo)])
	_pieza(h, _plano(), l, H_BORDE - 0.012, H_BORDE + 0.007, 0.004, 0.0, 1.0)
	# Bajando por la cara de delante y por la del lado.
	var frente := _vertical(Vector3(esquina.x, 0.0, esquina.y + 0.004), Vector3(dx, 0.0, 0.0),
		Vector3.BACK)
	_pieza(h, frente, PackedVector2Array([Vector2(-0.004, -0.45), Vector2(ancho, -0.45),
		Vector2(ancho, H_BORDE + 0.007), Vector2(-0.004, H_BORDE + 0.007)]), -0.01, 0.006,
		0.004, -0.9, 1.0)
	var costado := _vertical(Vector3(esquina.x + 0.004 * lado_x, 0.0, esquina.y), Vector3.FORWARD,
		Vector3(lado_x, 0.0, 0.0))
	_pieza(h, costado, PackedVector2Array([Vector2(-0.004, -0.45), Vector2(ancho, -0.45),
		Vector2(ancho, H_BORDE + 0.007), Vector2(-0.004, H_BORDE + 0.007)]), -0.01, 0.006,
		0.004, -0.9, 1.0)
	for y: float in [0.12, -0.08, -0.3]:
		_remache(h, frente.p(ancho * 0.5, y, 0.006), Vector3.BACK, 0.012)
		_remache(h, costado.p(ancho * 0.5, y, 0.006), Vector3(lado_x, 0.0, 0.0), 0.012)
	for q: Vector2 in [Vector2(dx * 0.15, -ancho * 0.5), Vector2(dx * ancho * 0.5, -0.15),
			Vector2(dx * ancho * 0.5, -ancho * 0.5)]:
		_remache(h, Vector3(esquina.x + q.x, H_BORDE + 0.007, esquina.y + q.y), Vector3.UP, 0.012)

# ================================================================== el ábside

## La cara del ábside como superficie: `u` es la distancia a lo largo de la cara
## desde la punta izquierda, `v` la altura y `w` lo que se aparta hacia el campo.
func _mapa_abside() -> Cara:
	var m := Cara.new()
	m.curvo = true
	var c := _mesa.arco_centro
	var r := _mesa.arco_radios
	var muestras := 720
	var s := 0.0
	var antes := Vector3.ZERO
	for k in muestras + 1:
		var th := PI * (1.0 - float(k) / float(muestras))
		var q := Vector2(c.x + r.x * cos(th), c.y - r.y * sin(th))
		var n := _normal_arco(q)
		var cara := (q + n * MURO_HOLGURA) * Nucleo.E
		var p3 := Vector3(cara.x, 0.0, cara.y)
		if k > 0:
			s += p3.distance_to(antes)
		antes = p3
		m.cs.append(s)
		m.cp.append(p3)
		m.cn.append(Vector3(-n.x, 0.0, -n.y))
		m.ct.append(th)
	return m

func _montar_abside() -> void:
	var mapa := _abside
	var largo := mapa.largo()
	var T := ABSIDE_GRUESO

	# Lo que no es sillar corrido: las hornacinas y el óculo.
	var huecos: Array[PackedVector2Array] = []
	for g: float in HORNACINAS_GRADOS:
		var sc := mapa.s_de(deg_to_rad(g))
		huecos.append(_silueta_hornacina(sc, HORNACINA_R, DOVELA))
	var luz := (LUZ_HACIA - OCULO_CENTRO).normalized()
	var oc := _cruce_con_cara(mapa, OCULO_CENTRO, luz)
	huecos.append(_circulo(oc, OCULO_R + OCULO_ANILLO, 36))

	# LAS HILADAS. Un zócalo de 16 cm y luego hiladas de 27 a 33 cm hasta la
	# cornisa, cada una con sus sillares de largo al azar y la junta matada.
	var alturas: Array[float] = [0.0, 0.16]
	while alturas[alturas.size() - 1] < H_CORNISA - 0.42:
		alturas.append(alturas[alturas.size() - 1] + _azar.randf_range(0.27, 0.33))
	alturas.append(H_CORNISA)
	for k in alturas.size() - 1:
		var h0 := alturas[k]
		var h1 := alturas[k + 1]
		var u := -_azar.randf_range(0.0, 0.4)
		while u < largo:
			var paso := _azar.randf_range(0.42, 0.8)
			if k == 0:
				paso *= 1.6
			var u0 := maxf(u, 0.0)
			var u1 := minf(u + paso, largo)
			if u1 - u0 > 0.04:
				var bloque := PackedVector2Array([Vector2(u0, h0), Vector2(u1, h0),
					Vector2(u1, h1), Vector2(u0, h1)])
				# Una de cada cuatro piedras con una esquina de arriba rota.
				if k > 0 and u1 - u0 > 0.3 and _azar.randf() < 0.25:
					bloque = _esquina_rota(bloque, 2 if _azar.randf() < 0.5 else 3)
				# Cada piedra adelanta o retrasa unos milímetros, y tiene su tono.
				var vuelo := 0.045 if k == 0 else _azar.randf_range(-0.004, 0.016)
				var tono := _tono()
				for trozo in _restar(bloque, huecos):
					var m := _lienzo("sillar", mapa.p((u0 + u1) * 0.5, (h0 + h1) * 0.5, 0.0))
					_pieza(m, mapa, trozo, -T, vuelo, _azar.randf_range(0.011, 0.016), 0.0, 0.45, 1.0, tono)
			u += paso

	# EL CIMIENTO, por detrás y por debajo del tablero: desde la cámara cenital se
	# ve por encima del muro, y sin él el ábside flotaba sobre la sala.
	var cimiento := PackedVector2Array([Vector2(0.0, Y_SALA), Vector2(largo, Y_SALA),
		Vector2(largo, 0.0), Vector2(0.0, 0.0)])
	_pieza(_lienzo("sala", mapa.p(largo * 0.5, -0.5, -T), true), mapa, cimiento, -T - 0.03,
		-0.06, 0.0, Y_SALA, 1.0)

	# LAS HORNACINAS: el fondo rehundido, las dovelas del arco y la repisa.
	for g: float in HORNACINAS_GRADOS:
		_hornacina(mapa, mapa.s_de(deg_to_rad(g)))

	# EL ÓCULO: anillo de dovelas con el taladro inclinado como la luz, y su reja.
	_oculo(mapa, oc, luz)

	# LA CORNISA, corrida, y encima la hilada de arranque de la bóveda del ábside
	# (`_concha`). Era una coronación arruinada contra el cielo; ahora la sala
	# tiene bóveda y sobre la cornisa arranca la del ábside: la hilada va entera,
	# con las piedras un poco desiguales, que es lo viejo, no lo roto.
	_moldura(mapa, 0.0, largo, _perfil_cornisa(), "sillar", 0.0)
	var u := 0.0
	while u < largo:
		var paso := _azar.randf_range(0.35, 0.75)
		var u1 := minf(u + paso, largo)
		var b := H_CORNISA + 0.18
		var alto := ARCO_Y - b + _azar.randf_range(0.0, 0.04)
		var bloque := PackedVector2Array([Vector2(u, b), Vector2(u1, b), Vector2(u1, b + alto),
			Vector2(u, b + alto)])
		_pieza(_lienzo("sillar", mapa.p((u + u1) * 0.5, b, 0.0)), mapa, bloque, -T + 0.04,
			-0.05 + _azar.randf_range(-0.01, 0.01), 0.02, 0.0, 0.5, 1.0, _tono())
		u = u1

	# Y LO QUE SE DEJA A MANO: apoyos de antorcha, argollas y la repisa de la
	# cornisa.
	for g: float in ANTORCHAS_GRADOS:
		apoyos_antorcha.append(_marco_en(mapa, mapa.s_de(deg_to_rad(g)), H_ANTORCHA, 0.0))
	for g: float in [36.0, 125.0 + 25.0]:
		var sc := mapa.s_de(deg_to_rad(g))
		_argolla(mapa, sc, 1.78)
	for g: float in [30.0, 70.0, 110.0, 150.0]:
		repisas.append(_marco_en(mapa, mapa.s_de(deg_to_rad(g)), H_CORNISA + 0.18, 0.08))

## Dónde corta una recta la cara del ábside: devuelve (u, v) en la cara.
func _cruce_con_cara(mapa: Cara, punto: Vector3, dir: Vector3) -> Vector2:
	# La recta va hacia atrás, hacia la luna, hasta que deja de estar por delante
	# de la cara. A pasitos y luego a medias: es una sola vez.
	var t0 := 0.0
	var t1 := 2.0
	for _i in 40:
		var tm := (t0 + t1) * 0.5
		var q := punto - dir * tm
		var u := mapa.u_cercano(q)
		var delante := (q - mapa.p(u, q.y, 0.0)).dot(mapa.eje_w(u))
		if delante > 0.0:
			t0 = tm
		else:
			t1 = tm
	var q := punto - dir * t1
	return Vector2(mapa.u_cercano(q), q.y)

## La silueta de lo que una hornacina le quita a las hiladas: el vano hasta la
## imposta y, encima, el semicírculo de las dovelas.
func _silueta_hornacina(sc: float, r: float, anillo: float) -> PackedVector2Array:
	var pol := PackedVector2Array([Vector2(sc - r, HORNACINA_REPISA),
		Vector2(sc + r, HORNACINA_REPISA), Vector2(sc + r, HORNACINA_IMPOSTA),
		Vector2(sc + r + anillo, HORNACINA_IMPOSTA)])
	var n := 16
	for k in range(1, n):
		var a := PI * float(k) / float(n)
		pol.append(Vector2(sc + cos(a) * (r + anillo), HORNACINA_IMPOSTA + sin(a) * (r + anillo)))
	pol.append(Vector2(sc - r - anillo, HORNACINA_IMPOSTA))
	pol.append(Vector2(sc - r, HORNACINA_IMPOSTA))
	return pol

func _hornacina(mapa: Cara, sc: float) -> void:
	var r := HORNACINA_R
	var m := _lienzo("sillar", mapa.p(sc, 0.9, 0.0))
	# El fondo: la silueta del vano un poco mayor, a `HORNACINA_FONDO`.
	var vano := PackedVector2Array([Vector2(sc - r - 0.03, HORNACINA_REPISA - 0.02),
		Vector2(sc + r + 0.03, HORNACINA_REPISA - 0.02), Vector2(sc + r + 0.03, HORNACINA_IMPOSTA)])
	for k in range(1, 16):
		var a := PI * float(k) / 16.0
		vano.append(Vector2(sc + cos(a) * (r + 0.03), HORNACINA_IMPOSTA + sin(a) * (r + 0.03)))
	vano.append(Vector2(sc - r - 0.03, HORNACINA_IMPOSTA))
	_pieza(m, mapa, vano, -HORNACINA_FONDO - 0.05, -HORNACINA_FONDO, 0.0, 0.0, 1.0, 0.36)
	# Las dovelas: siete, con la clave un poco más larga y más saliente.
	var n := 7
	for k in n:
		var a0 := PI * float(k) / float(n)
		var a1 := PI * float(k + 1) / float(n)
		var clave := k == n / 2
		var ext := r + DOVELA + (0.03 if clave else 0.0)
		var pol := PackedVector2Array()
		for j in 5:
			var a := lerpf(a0, a1, float(j) / 4.0)
			pol.append(Vector2(sc + cos(a) * r, HORNACINA_IMPOSTA + sin(a) * r))
		for j in 5:
			var a := lerpf(a1, a0, float(j) / 4.0)
			pol.append(Vector2(sc + cos(a) * ext, HORNACINA_IMPOSTA + sin(a) * ext))
		_pieza(m, mapa, pol, -ABSIDE_GRUESO, 0.03 if clave else 0.016, 0.016, 0.0, 0.5)
	# Las impostas: dos piedras que vuelan donde arranca el arco.
	for lado: float in [-1.0, 1.0]:
		var x0 := sc + lado * r
		var x1 := sc + lado * (r + DOVELA + 0.04)
		var imp := PackedVector2Array([Vector2(minf(x0, x1), HORNACINA_IMPOSTA - 0.045),
			Vector2(maxf(x0, x1), HORNACINA_IMPOSTA - 0.045),
			Vector2(maxf(x0, x1), HORNACINA_IMPOSTA), Vector2(minf(x0, x1), HORNACINA_IMPOSTA)])
		_pieza(m, mapa, imp, -ABSIDE_GRUESO, 0.03, 0.01, 0.0, 0.5)
	# La repisa: una losa que vuela 8 cm y entra hasta el fondo.
	var rep := PackedVector2Array([Vector2(sc - r - 0.07, HORNACINA_REPISA - 0.06),
		Vector2(sc + r + 0.07, HORNACINA_REPISA - 0.06), Vector2(sc + r + 0.07, HORNACINA_REPISA),
		Vector2(sc - r - 0.07, HORNACINA_REPISA)])
	_pieza(m, mapa, rep, -HORNACINA_FONDO - 0.02, 0.08, 0.014, 0.0, 0.6)
	# Debajo, una ménsula pequeña que la sostiene.
	var men := PackedVector2Array([Vector2(sc - 0.07, HORNACINA_REPISA - 0.06),
		Vector2(sc + 0.07, HORNACINA_REPISA - 0.06), Vector2(sc + 0.05, HORNACINA_REPISA - 0.15),
		Vector2(sc - 0.05, HORNACINA_REPISA - 0.15)])
	_pieza(m, mapa, men, -0.1, 0.05, 0.012, 0.0, 0.6)
	hornacinas.append(_marco_en(mapa, sc, HORNACINA_REPISA, -HORNACINA_FONDO * 0.5))
	repisas.append(_marco_en(mapa, sc, HORNACINA_REPISA, 0.04))

func _oculo(mapa: Cara, oc: Vector2, luz: Vector3) -> void:
	# El taladro sigue la luz: lo que entra en el muro se corre a lo largo de
	# ella. `cizalla` es lo que hay que sumar por unidad de fondo.
	var w := mapa.eje_w(oc.x)
	var cz := luz / luz.dot(w) - w
	var inclinado := mapa.copia()
	inclinado.cizalla = cz
	var m := _lienzo("sillar", mapa.p(oc.x, oc.y, 0.0))
	var n := 12
	for k in n:
		var a0 := TAU * float(k) / float(n) + 0.13
		var a1 := TAU * float(k + 1) / float(n) + 0.13
		var pol := PackedVector2Array()
		for j in 5:
			var a := lerpf(a0, a1, float(j) / 4.0)
			pol.append(oc + Vector2(cos(a), sin(a)) * OCULO_R)
		for j in 5:
			var a := lerpf(a1, a0, float(j) / 4.0)
			pol.append(oc + Vector2(cos(a), sin(a)) * (OCULO_R + OCULO_ANILLO))
		_pieza(m, inclinado, pol, -ABSIDE_GRUESO, 0.022, 0.016, 0.0, 0.5)
	# LA REJA: un aro empotrado, una cruz, dos diagonales, un aro chico y la
	# bolla del centro, a 11 cm de la cara, en el plano del muro.
	var h := _lienzo("hierro", mapa.p(oc.x, oc.y, 0.0))
	var fondo := -0.11
	var u_ax := mapa.eje_u(oc.x)
	var lado := w
	var barra := _seccion_cuadrada(0.011, 0.003)
	for rr: float in [OCULO_R - 0.004, 0.12]:
		var pts := PackedVector3Array()
		for k in 33:
			var a := TAU * float(k) / 32.0
			pts.append(inclinado.p(oc.x + cos(a) * rr, oc.y + sin(a) * rr, fondo))
		_barrido(h, pts, lado, barra, 0.0, false)
	for k in 4:
		var a := PI * 0.25 * float(k)
		var d := Vector2(cos(a), sin(a)) * (OCULO_R + 0.01)
		_barrido(h, PackedVector3Array([inclinado.p(oc.x - d.x, oc.y - d.y, fondo),
			inclinado.p(oc.x + d.x, oc.y + d.y, fondo)]), lado, barra, 0.0, true)
	var centro := inclinado.p(oc.x, oc.y, fondo)
	_torno_eje(h, centro, w, [Vector2(0.0, -0.03), Vector2(0.03, -0.02), Vector2(0.036, 0.0),
		Vector2(0.03, 0.02), Vector2(0.0, 0.03)], 10)
	for k in 8:
		var a := PI * 0.25 * float(k)
		_remache(h, inclinado.p(oc.x + cos(a) * 0.12, oc.y + sin(a) * 0.12, fondo + 0.012), w, 0.012)
	oculo = Transform3D(Basis(u_ax, Vector3.UP, luz).orthonormalized(), mapa.p(oc.x, oc.y, 0.0))

func _perfil_cornisa() -> Array[Vector3]:
	# (fuera, alto, canto). De abajo y pegado al muro, hacia fuera y arriba, y
	# de vuelta al muro: una nacela, un filete, la corona y su vierteaguas.
	return [
		Vector3(0.0, H_CORNISA - 0.02, 0.0), Vector3(0.025, H_CORNISA, 0.3),
		Vector3(0.045, H_CORNISA + 0.03, 0.0), Vector3(0.07, H_CORNISA + 0.05, 0.0),
		Vector3(0.082, H_CORNISA + 0.06, 1.0), Vector3(0.082, H_CORNISA + 0.075, 0.0),
		Vector3(0.125, H_CORNISA + 0.09, 1.0), Vector3(0.138, H_CORNISA + 0.105, 1.0),
		Vector3(0.138, H_CORNISA + 0.15, 0.0), Vector3(0.124, H_CORNISA + 0.165, 1.0),
		Vector3(0.0, H_CORNISA + 0.18, 0.0)]

func _argolla(mapa: Cara, sc: float, h: float) -> void:
	var m := _lienzo("hierro", mapa.p(sc, h, 0.0))
	var w := mapa.eje_w(sc)
	var u := mapa.eje_u(sc)
	# La placa con su grapa y la argolla colgando, un poco ladeada.
	var placa := PackedVector2Array([Vector2(sc - 0.045, h - 0.04), Vector2(sc + 0.045, h - 0.04),
		Vector2(sc + 0.045, h + 0.05), Vector2(sc - 0.045, h + 0.05)])
	_pieza(m, mapa, placa, -0.01, 0.012, 0.004, 0.0, 1.0)
	_remache(m, mapa.p(sc, h + 0.03, 0.012), w, 0.012)
	_remache(m, mapa.p(sc, h - 0.022, 0.012), w, 0.012)
	var grapa := mapa.p(sc, h, 0.03)
	_barrido(m, PackedVector3Array([mapa.p(sc, h, 0.01), grapa]), u, _seccion_cuadrada(0.008, 0.002), 0.0, true)
	var anillo := PackedVector3Array()
	var rr := 0.06
	var giro := Basis(Vector3.UP, 0.3)
	for k in 25:
		var a := TAU * float(k) / 24.0
		var q := Vector3(sin(a) * rr, -rr + cos(a) * rr, 0.0)
		anillo.append(grapa + giro * (w * q.z * 0.0 + u * q.x + Vector3.UP * q.y) + w * 0.01)
	_barrido(m, anillo, w, _seccion_rombo(0.008), 0.0, false)
	argollas.append(Transform3D(Basis(u, Vector3.UP, w), grapa + Vector3.UP * (-2.0 * rr) + w * 0.01))

func _marco_en(mapa: Cara, u: float, v: float, w: float) -> Transform3D:
	return Transform3D(Basis(mapa.eje_u(u), Vector3.UP, mapa.eje_w(u)), mapa.p(u, v, w))

# =============================================================== las columnas

## Las dos columnas que flanquean el ábside, en el encuentro con el muro de la
## sala, y el arco triunfal que arrancaba de ellas, roto.
func _montar_columnas() -> void:
	var mapa := _abside
	var izq := mapa.p(0.0, 0.0, 0.0)
	var der := mapa.p(mapa.largo(), 0.0, 0.0)
	var r_fuste := 0.17
	var glb: PackedScene = null
	if ResourceLoader.exists(RUTA_CAPITEL):
		glb = load(RUTA_CAPITEL) as PackedScene
	for k in 2:
		var cara: Vector3 = izq if k == 0 else der
		var hacia: float = -1.0 if k == 0 else 1.0
		var c := Vector3(cara.x + hacia * 0.26, 0.0, cara.z - 0.06)
		var m := _lienzo("sillar", c + Vector3.UP * 1.0)
		var bajo := _lienzo("sillar", c + Vector3.UP * -0.5, true)
		# El plinto, en la sala, y la basa ática a la altura del tablero.
		_pieza(bajo, _plano(), _rect_c(Vector2(c.x, c.z), 0.27), Y_SALA, -0.02, 0.02, Y_SALA, 1.0)
		_pieza(m, _plano(), _rect_c(Vector2(c.x, c.z), 0.26), -0.02, H_BORDE + 0.04, 0.02, 0.0, 1.0)
		_torno(m, Vector3(c.x, H_BORDE + 0.04, c.z), [Vector2(0.24, 0.0), Vector2(0.245, 0.02),
			Vector2(0.235, 0.045), Vector2(0.21, 0.055), Vector2(0.195, 0.07), Vector2(0.2, 0.085),
			Vector2(0.21, 0.1), Vector2(0.2, 0.12), Vector2(r_fuste + 0.01, 0.13),
			Vector2(r_fuste, 0.15)], 20, H_BORDE)
		# El fuste, con éntasis, en tambores (los cortes son anillos de bisel).
		var y := H_BORDE + 0.19
		var tope := H_CORNISA - 0.08
		var tambores := 4
		for t in tambores:
			var y0 := lerpf(y, tope, float(t) / float(tambores))
			var y1 := lerpf(y, tope, float(t + 1) / float(tambores))
			var r0 := r_fuste * (1.0 - 0.06 * float(t) / float(tambores))
			var r1 := r_fuste * (1.0 - 0.06 * float(t + 1) / float(tambores))
			_torno(m, Vector3(c.x, y0, c.z), [Vector2(r0 - 0.008, 0.0), Vector2(r0, 0.008),
				Vector2(r1, y1 - y0 - 0.008), Vector2(r1 - 0.008, y1 - y0)], 18, 0.0)
		# El collarino y el capitel.
		_torno(m, Vector3(c.x, tope, c.z), [Vector2(r_fuste * 0.94, 0.0),
			Vector2(r_fuste * 0.94 + 0.02, 0.012), Vector2(r_fuste * 0.94 + 0.02, 0.03),
			Vector2(r_fuste * 0.94, 0.04)], 18, 0.0)
		var y_cap := tope + 0.04
		var alto_cap := _capitel(c, y_cap, glb, hacia)
		# El cimacio, a la altura de la cornisa.
		var y_cim := y_cap + alto_cap
		_pieza(m, _plano(), _rect_c(Vector2(c.x, c.z), 0.3), y_cim, y_cim + 0.08, 0.022, 0.0, 1.0)
		capiteles.append(Transform3D(Basis(), Vector3(c.x, y_cim + 0.08, c.z)))
	_arco_triunfal(_z_testero - 0.06)

## EL ARCO TRIUNFAL, entero: de columna a columna, dovela a dovela, y la bóveda
## del ábside detrás. Antes eran dos arranques rotos que no sostenían nada y,
## contra el cielo, se leían como dos tablones curvos sueltos. Es media elipse
## (ver `ARCO_ALTO`): la clave tiene que quedar por encima de la recta de la
## cámara CENITAL a la punta del campo. Sus caras de delante y de detrás no pasan
## de ±0,12 en z por lo mismo.
func _arco_triunfal(z: float) -> void:
	var n := 15
	var hueco := 0.004
	for k in n:
		var a0 := PI * float(k) / float(n) + hueco
		var a1 := PI * float(k + 1) / float(n) - hueco
		var clave := k == n / 2
		var grueso := 0.1 if clave else 0.08
		var fondo := 0.135 if clave else 0.115
		var pts := PackedVector3Array()
		for j in 4:
			var a := lerpf(a0, a1, float(j) / 3.0)
			pts.append(Vector3(2.0 + (ARCO_ANCHO + 0.08) * cos(a), ARCO_Y + (ARCO_ALTO + 0.08) * sin(a), z))
		var sec := PackedVector2Array([Vector2(-fondo + 0.02, -grueso), Vector2(fondo - 0.02, -grueso),
			Vector2(fondo, -grueso + 0.02), Vector2(fondo, grueso - 0.02), Vector2(fondo - 0.02, grueso),
			Vector2(-fondo + 0.02, grueso), Vector2(-fondo, grueso - 0.02), Vector2(-fondo, -grueso + 0.02)])
		var m := _lienzo("nervio", pts[1], false, true)
		var desde := m.v.size()
		_barrido(m, pts, Vector3.BACK, sec, 0.0, true)
		m.libre(desde, _recalor_nervio)

## El capitel: el de calaveras si está su GLB; si no, uno troncopiramidal liso.
## Devuelve su alto.
func _capitel(c: Vector3, y: float, glb: PackedScene, hacia: float) -> float:
	if glb != null:
		var escena := glb.instantiate() as Node3D
		if escena != null:
			escena.position = Vector3(c.x, y, c.z)
			# Las calaveras de las esquinas: que la de delante mire al jugador y
			# un poco hacia el ábside.
			escena.rotation.y = PI * 0.5 if hacia > 0.0 else 0.0
			_mundo.add_child(escena)
			_vestir(escena, _mats["sillar"])
			return 0.3
	var m := _lienzo("sillar", c + Vector3.UP * y)
	var abajo := _circulo(Vector2(c.x, c.z), 0.17, 16)
	_pieza(m, _plano(), abajo, y, y + 0.08, 0.0, 0.0, 1.0)
	var arriba := _rect_c(Vector2(c.x, c.z), 0.25)
	_pieza(m, _plano(), arriba, y + 0.08, y + 0.3, 0.03, 0.0, 1.0)
	return 0.3

func _vestir(nodo: Node, material: Material) -> void:
	var mi := nodo as MeshInstance3D
	if mi != null:
		mi.material_override = material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mi.set_meta("arq", "capitel")
		_nodos.append(mi)
	for hijo in nodo.get_children():
		_vestir(hijo, material)

# =================================================================== el coro

func _montar_coro() -> void:
	for pl in _mesa.plataformas:
		var h_alta := _mundo.altura_capa(pl.capa)
		var pol := PackedVector2Array()
		for q in pl.poligono:
			pol.append(q * Nucleo.E)
		pol = _ccw(pol)
		_tribuna(pol, h_alta)

func _tribuna(pol: PackedVector2Array, h_alta: float) -> void:
	var c := _centro3(pol, 0.0)
	var m := _lienzo("piedra", c)
	# EL NÚCLEO, metido 2 cm: su cara es el fondo de los arquillos.
	var nucleo := _desplazar(pol, -0.02)
	_pieza(m, _plano(), nucleo, -0.02, H_BAJO_LOSA, 0.0, 0.0, 1.0)
	# LA ARQUERÍA CIEGA en cada cara, de la línea de la falda hacia dentro.
	var n := pol.size()
	var frente := -1
	var mejor := -1.0e9
	for i in n:
		var a := pol[i]
		var b := pol[(i + 1) % n]
		var d := (b - a).normalized()
		var fuera := Vector2(d.y, -d.x)
		if fuera.y > mejor:
			mejor = fuera.y
			frente = i
		_arqueria(a, b, fuera)
	# LA LOSA: un cerco de piedra que vuela sobre las caras (5 cm por delante,
	# 2 por los lados) y dentro el piso de tablones.
	var vuelos := PackedFloat32Array()
	for i in n:
		vuelos.append(0.05 if i == frente else 0.02)
	var fuera_pol := _desplazar_lados(pol, vuelos)
	var dentro_pol := _desplazar(pol, -0.06)
	for i in n:
		var j := (i + 1) % n
		var tramo := PackedVector2Array([fuera_pol[i], fuera_pol[j], dentro_pol[j], dentro_pol[i]])
		_pieza(_lienzo("piedra", _centro3(tramo, h_alta)), _plano(), tramo, H_BAJO_LOSA, h_alta,
			0.012, 0.0, 1.0)
	_tablones(dentro_pol, h_alta)
	# LAS MÉNSULAS bajo el vuelo del frente.
	var a := pol[frente]
	var b := pol[(frente + 1) % n]
	var d := (b - a).normalized()
	var fuera := Vector2(d.y, -d.x)
	var largo := a.distance_to(b)
	var cuantas := maxi(int(largo / 0.2), 2)
	for k in cuantas:
		var q := a.lerp(b, (float(k) + 0.5) / float(cuantas))
		var mv := _vertical(Vector3(q.x, 0.0, q.y), Vector3(fuera.x, 0.0, fuera.y),
			Vector3(d.x, 0.0, d.y))
		var perfil := PackedVector2Array([Vector2(-0.01, H_BAJO_LOSA), Vector2(0.046, H_BAJO_LOSA),
			Vector2(0.046, H_BAJO_LOSA - 0.018), Vector2(0.03, H_BAJO_LOSA - 0.03),
			Vector2(0.03, H_BAJO_LOSA - 0.045), Vector2(0.012, H_BAJO_LOSA - 0.07),
			Vector2(-0.01, H_BAJO_LOSA - 0.075)])
		_pieza(m, mv, perfil, -0.022, 0.022, 0.006, 0.0, 1.0)

## Una cara de la tribuna: un paño con arquillos ciegos de medio punto.
func _arqueria(a: Vector2, b: Vector2, fuera: Vector2) -> void:
	var largo := a.distance_to(b)
	if largo < 0.05:
		return
	var d := (b - a) / largo
	var mv := _vertical(Vector3(a.x, 0.0, a.y), Vector3(d.x, 0.0, d.y), Vector3(fuera.x, 0.0, fuera.y))
	var pano := PackedVector2Array([Vector2(0.0, -0.02), Vector2(largo, -0.02),
		Vector2(largo, H_BAJO_LOSA), Vector2(0.0, H_BAJO_LOSA)])
	var huecos: Array[PackedVector2Array] = []
	var arcos := int(largo / 0.33)
	if arcos >= 1:
		var r := 0.085
		var imposta := 0.13
		for k in arcos:
			var cx := largo * (float(k) + 0.5) / float(arcos)
			var arco := PackedVector2Array([Vector2(cx - r, 0.035), Vector2(cx + r, 0.035)])
			for j in 13:
				var ang := PI * float(j) / 12.0
				arco.append(Vector2(cx + cos(ang) * r, imposta + sin(ang) * r))
			huecos.append(arco)
	var m := _lienzo("piedra", Vector3((a.x + b.x) * 0.5, 0.15, (a.y + b.y) * 0.5))
	for trozo in _restar(pano, huecos):
		_pieza(m, mv, trozo, -0.02, 0.0, 0.008, 0.0, 0.6)

## El piso del coro: tablones de roble viejo, de 9 cm, a lo largo de la tribuna.
func _tablones(pol: PackedVector2Array, h_alta: float) -> void:
	var caja := _caja(pol)
	var x := caja.position.x
	var m := _lienzo("madera", _centro3(pol, h_alta))
	while x < caja.end.x:
		var ancho := _azar.randf_range(0.08, 0.1)
		var z := caja.position.y - _azar.randf_range(0.0, 0.5)
		while z < caja.end.y:
			var largo := _azar.randf_range(0.5, 0.9)
			var tabla := PackedVector2Array([Vector2(x + 0.002, z + 0.002),
				Vector2(x + ancho - 0.002, z + 0.002), Vector2(x + ancho - 0.002, z + largo - 0.002),
				Vector2(x + 0.002, z + largo - 0.002)])
			for trozo in Geometry2D.intersect_polygons(tabla, pol):
				if _area(trozo) <= 0.0:
					continue
				_pieza(m, _plano(), trozo, H_BAJO_LOSA, h_alta - _azar.randf_range(0.0, 0.004),
					0.004, 0.0, 1.0)
			z += largo
		x += ancho

# ==================================================================== la sala

func _montar_sala() -> void:
	# EL SUELO: losas grandes y oscuras, a `Y_SALA`, en trozos. No llega por
	# debajo del mueble ni detrás del ábside más de lo que se ve.
	var e := Nucleo.E
	var xi := (_x_izq - BORDE) * e
	var xd := (_x_der + BORDE) * e
	var zf := (_mesa.p.y_drenaje + BORDE_PIE) * e
	var zonas: Array[Rect2] = []
	for x0: float in [SALA_X.x, -4.6]:
		var x1 := -4.6 if x0 < -5.0 else xi
		for z0: float in [SALA_Z.x, 8.5, 14.5]:
			var z1 := 8.5 if z0 < 3.0 else (14.5 if z0 < 9.0 else SALA_Z.y)
			zonas.append(Rect2(x0, z0, x1 - x0, z1 - z0))
	for x0: float in [xd, 8.6]:
		var x1 := 8.6 if x0 < 8.0 else SALA_X.y
		for z0: float in [SALA_Z.x, 8.5, 14.5]:
			var z1 := 8.5 if z0 < 3.0 else (14.5 if z0 < 9.0 else SALA_Z.y)
			zonas.append(Rect2(x0, z0, x1 - x0, z1 - z0))
	zonas.append(Rect2(xi, zf, xd - xi, SALA_Z.y - zf))
	zonas.append(Rect2(xi, SALA_Z.x, xd - xi, 7.0 - SALA_Z.x))
	# Cada zona era un PlaneMesh suelto: catorce llamadas para un suelo plano. Van
	# al lienzo, y el lienzo de abajo las junta en seis (ver `_celda`).
	var blanco := Color(1.0, 0.0, 0.0)
	for zona in zonas:
		var c := zona.get_center()
		var p0 := Vector3(zona.position.x, Y_SALA, zona.position.y)
		var p2 := Vector3(zona.end.x, Y_SALA, zona.end.y)
		_lienzo("losas", Vector3(c.x, Y_SALA, c.y), true).cuadro(p0, Vector3(p2.x, Y_SALA, p0.z), p2,
			Vector3(p0.x, Y_SALA, p2.z), Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP,
			blanco, blanco, blanco, blanco)

	_losas_alrededor()

	# EL MURO DEL FONDO, a los dos lados del ábside: en la nave, paños gruesos con
	# el aparejo del sombreador hasta `H_SALA_MURO` (encima va el testero, que
	# monta la bóveda); en las naves laterales el muro lo pone el testero entero.
	# La cornisa y el zócalo corren de punta a punta.
	var cara_z := _z_testero
	var x_izq := _abside.p(0.0, 0.0, 0.0).x - ABSIDE_GRUESO
	var x_der := _abside.p(_abside.largo(), 0.0, 0.0).x + ABSIDE_GRUESO
	var osario: Array[Transform3D] = []
	for tramo: Vector2 in [Vector2(PILARES_X[0], x_izq), Vector2(x_der, PILARES_X[1])]:
		# Lo libre entre el pilar metido en el muro y la columna del ábside.
		var izq := tramo.x < 2.0
		var libre := Vector2(tramo.x + (0.36 if izq else 0.16), tramo.y - (0.16 if izq else 0.36))
		_muro_osario(tramo, (libre.x + libre.y) * 0.5, osario)
	_osario(osario)
	for tramo: Vector2 in [Vector2(SALA_X.x, x_izq), Vector2(x_der, SALA_X.y)]:
		var mv := _vertical(Vector3(tramo.x, 0.0, cara_z), Vector3.RIGHT, Vector3.BACK)
		var largo := tramo.y - tramo.x
		var mm := _lienzo("sala", Vector3((tramo.x + tramo.y) * 0.5, 1.0, cara_z), true)
		_moldura(mv, 0.0, largo, _perfil_cornisa(), "sala", 0.0, mm)
		_moldura(mv, 0.0, largo, [Vector3(0.0, Y_SALA - 0.01, 0.0), Vector3(0.06, Y_SALA - 0.01, 0.0),
			Vector3(0.06, Y_SALA + 0.16, 1.0), Vector3(0.0, Y_SALA + 0.2, 0.0)], "sala", Y_SALA, mm)

	# LOS PILARES: uno hecho y repetido, los de las dos filas y, metidos medio en
	# el muro del fondo, los dos que reciben el dintel allí.
	var pilar := Malla.new()
	_pilar(pilar)
	# Una fila por MultiMesh: las dos juntas tocaban 11 fuegos (los de las
	# antorchas de cada pilar y los braseros de pie) y Compatibility solo aplica 8,
	# los primeros que empareja. Una llamada más a cambio de que no se apague
	# ninguna antorcha de pilar.
	var malla_pilar := pilar.malla()
	for px: float in PILARES_X:
		var sitios: Array[Vector3] = [Vector3(px, 0.0, cara_z)]
		for pz: float in PILARES_Z:
			sitios.append(Vector3(px, 0.0, pz))
		var mm2 := MultiMesh.new()
		mm2.transform_format = MultiMesh.TRANSFORM_3D
		mm2.mesh = malla_pilar
		mm2.instance_count = sitios.size()
		for k in sitios.size():
			mm2.set_instance_transform(k, Transform3D(Basis(), sitios[k]))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm2
		mmi.material_override = _mats["sala"]
		mmi.layers = Nucleo.CAPA_BAJO_SUELO
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mundo.add_child(mmi)
		mmi.set_meta("arq", "pilares")
		_nodos.append(mmi)
	# Los apoyos para colgar algo en los pilares: en la cara que mira a la mesa.
	for px: float in PILARES_X:
		var hacia := 1.0 if px < 2.0 else -1.0
		for pz: float in PILARES_Z:
			apoyos_pilar.append(Transform3D(Basis(Vector3.BACK * hacia, Vector3.UP,
				Vector3.RIGHT * hacia), Vector3(px + hacia * 0.22, 1.6, pz)))

## LAS LOSAS DE ALREDEDOR DEL MUEBLE: un metro de losas de verdad (con bisel y
## cada una de su tono y su altura) en el suelo de la sala, pegadas al zócalo.
## El suelo de la nave era un plano con el dibujo de las juntas, y a oscuras y
## con la bruma no se veía: la mesa flotaba en la niebla.
func _losas_alrededor() -> void:
	var e := Nucleo.E
	var xi := (_x_izq - BORDE) * e - 0.08
	var xd := (_x_der + BORDE) * e + 0.08
	var zf := (_mesa.p.y_drenaje + BORDE_PIE) * e + 0.08
	var mueble := Rect2(xi, _z_testero - 1.0, xd - xi, zf - _z_testero + 1.0)
	var fuera := Rect2(xi - 1.1, _z_testero, xd - xi + 2.2, zf - _z_testero + 1.1)
	var z := fuera.position.y
	var fila := 0
	while z < fuera.end.y - 0.05:
		var alto := minf(_azar.randf_range(0.42, 0.55), fuera.end.y - z)
		var x := fuera.position.x - (0.0 if fila % 2 == 0 else 0.3)
		while x < fuera.end.x - 0.05:
			var ancho := _azar.randf_range(0.5, 0.75)
			var losa := Rect2(maxf(x, fuera.position.x), z, minf(x + ancho, fuera.end.x) - maxf(x, fuera.position.x), alto)
			x += ancho
			if losa.size.x < 0.12:
				continue
			var pol := PackedVector2Array([losa.position + Vector2(0.006, 0.006),
				Vector2(losa.end.x - 0.006, losa.position.y + 0.006), losa.end - Vector2(0.006, 0.006),
				Vector2(losa.position.x + 0.006, losa.end.y - 0.006)])
			var hueco := PackedVector2Array([mueble.position, Vector2(mueble.end.x, mueble.position.y),
				mueble.end, Vector2(mueble.position.x, mueble.end.y)])
			var tono := _tono()
			var h := Y_SALA + _azar.randf_range(0.008, 0.02)
			for trozo in _restar(pol, [hueco]):
				if absf(_area(trozo)) < 0.01:
					continue
				_pieza(_lienzo("losa", _centro3(trozo, Y_SALA), true), _plano(), trozo, Y_SALA - 0.03,
					h, 0.014, Y_SALA - 0.03, 0.7, 1.0, tono)
		z += alto
		fila += 1

## EL OSARIO: un tramo del muro del fondo con un ARCO CIEGO (el muro rehundido
## bajo un arco de dovelas) y, dentro, una rejilla de nichos de osario. Era un
## paño liso: desde la mesa, lo que había alrededor del ábside no tenía ninguna
## silueta y se leía como un decorado de cajas. Los nichos de abajo quedan
## vacíos (los tapa el mueble y lo que hay delante); `nichos_osario` los deja a
## mano para quien quiera poner algo dentro. La sala es piedra de `CAPA_BAJO_SUELO`.
const OSARIO_R := 0.8
const OSARIO_IMPOSTA := 1.05
const OSARIO_ALFEIZAR := -0.62
const OSARIO_FONDO := 0.16
const NICHO := Vector2(0.46, 0.34)
const NICHO_FONDO := 0.26
const NICHOS_FILAS: Array[float] = [-0.5, -0.04, 0.42]

func _muro_osario(tramo: Vector2, c: float, osario: Array[Transform3D]) -> void:
	var cz := _z_testero
	var mv := _vertical(Vector3(0.0, 0.0, cz), Vector3.RIGHT, Vector3.BACK)
	var m := _lienzo("sala", Vector3(c, 0.5, cz), true)
	var r := OSARIO_R
	var arco := PackedVector2Array([Vector2(c - r, OSARIO_ALFEIZAR), Vector2(c + r, OSARIO_ALFEIZAR)])
	for k in 17:
		var a := PI * float(k) / 16.0
		arco.append(Vector2(c + cos(a) * r, OSARIO_IMPOSTA + sin(a) * r))
	# El paño, con el hueco del arco: sus costados son las jambas.
	var pano := PackedVector2Array([Vector2(tramo.x, Y_SALA), Vector2(tramo.y, Y_SALA),
		Vector2(tramo.y, H_SALA_MURO), Vector2(tramo.x, H_SALA_MURO)])
	for trozo in _restar(pano, [arco]):
		_pieza(m, mv, trozo, -0.5, 0.0, 0.03, Y_SALA, 0.7)
	# El fondo del arco, con los huecos de los nichos.
	var nichos: Array[PackedVector2Array] = []
	var centros: Array[Vector2] = []
	for fy: float in NICHOS_FILAS:
		for k in 3:
			var nx := c + (float(k) - 1.0) * (NICHO.x + 0.07)
			centros.append(Vector2(nx, fy))
			nichos.append(PackedVector2Array([Vector2(nx - NICHO.x * 0.5, fy),
				Vector2(nx + NICHO.x * 0.5, fy), Vector2(nx + NICHO.x * 0.5, fy + NICHO.y),
				Vector2(nx - NICHO.x * 0.5, fy + NICHO.y)]))
	var fondo := _desplazar(_ccw(arco), 0.02)
	for trozo in _restar(fondo, nichos):
		_pieza(m, mv, trozo, -0.5, -OSARIO_FONDO, 0.012, Y_SALA, 0.45, 0.82, _tono())
	# Cada nicho, con su fondo oscuro; los de arriba, con sus huesos.
	for i in centros.size():
		var q := centros[i]
		var atras := PackedVector2Array([Vector2(q.x - NICHO.x * 0.5 - 0.01, q.y - 0.01),
			Vector2(q.x + NICHO.x * 0.5 + 0.01, q.y - 0.01),
			Vector2(q.x + NICHO.x * 0.5 + 0.01, q.y + NICHO.y + 0.01),
			Vector2(q.x - NICHO.x * 0.5 - 0.01, q.y + NICHO.y + 0.01)])
		_pieza(m, mv, atras, -0.5, -OSARIO_FONDO - NICHO_FONDO, 0.0, Y_SALA, 1.0, 0.35)
		var xf := Transform3D(Basis(), Vector3(q.x, q.y, cz - OSARIO_FONDO))
		if q.y > NICHOS_FILAS[0] + 0.01:
			osario.append(xf)
		else:
			nichos_osario.append(xf)
	# Las dovelas del arco y las impostas.
	var n := 11
	for k in n:
		var a0 := PI * float(k) / float(n) + 0.006
		var a1 := PI * float(k + 1) / float(n) - 0.006
		var ext := r + (0.15 if k == n / 2 else 0.12)
		var pol := PackedVector2Array()
		for j in 4:
			var a := lerpf(a0, a1, float(j) / 3.0)
			pol.append(Vector2(c + cos(a) * r, OSARIO_IMPOSTA + sin(a) * r))
		for j in 4:
			var a := lerpf(a1, a0, float(j) / 3.0)
			pol.append(Vector2(c + cos(a) * ext, OSARIO_IMPOSTA + sin(a) * ext))
		_pieza(m, mv, pol, -0.1, 0.03 if k == n / 2 else 0.022, 0.012, Y_SALA, 0.6, 1.0, _tono())
	for lado: float in [-1.0, 1.0]:
		var x0 := c + lado * (r - 0.02)
		var x1 := c + lado * (r + 0.16)
		var imp := PackedVector2Array([Vector2(minf(x0, x1), OSARIO_IMPOSTA - 0.06),
			Vector2(maxf(x0, x1), OSARIO_IMPOSTA - 0.06), Vector2(maxf(x0, x1), OSARIO_IMPOSTA),
			Vector2(minf(x0, x1), OSARIO_IMPOSTA)])
		_pieza(m, mv, imp, -0.1, 0.035, 0.01, Y_SALA, 0.6)

## Los huesos de los nichos (`arquitectura_osario.glb`), en hueso viejo y sucio
## como el de «atrezzo». El GLB trae TRES nichos distintos (cada calavera con su
## giro, su talla y su tono); aquí cada nicho coge uno al azar, con su giro, una
## pizca de talla y su tono (multiplica la oclusión: de TIERRA_5 a TIERRA_6), y
## se juntan todos en UNA malla. Era un MultiMesh de una sola pieza: de cerca,
## la misma terna de calaveras repetida a escuadra en doce nichos.
func _osario(sitios: Array[Transform3D]) -> void:
	if sitios.is_empty() or not ResourceLoader.exists(RUTA_OSARIO):
		return
	var escena := (load(RUTA_OSARIO) as PackedScene).instantiate()
	var variantes: Array[Mesh] = []
	var pila: Array[Node] = [escena]
	while not pila.is_empty():
		var nodo: Node = pila.pop_back()
		if nodo is MeshInstance3D and (nodo as MeshInstance3D).mesh != null:
			variantes.append((nodo as MeshInstance3D).mesh)
		pila.append_array(nodo.get_children())
	escena.free()
	if variantes.is_empty():
		return
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var idx := PackedInt32Array()
	var ultima := -1
	for i in sitios.size():
		# Dos nichos seguidos nunca con la misma variante.
		var k := _azar.randi_range(0, variantes.size() - 1)
		if k == ultima and variantes.size() > 1:
			k = (k + 1) % variantes.size()
		ultima = k
		var giro := Basis(Vector3.UP, _azar.randf_range(-0.14, 0.14))
		var talla := _azar.randf_range(0.95, 1.04)
		var tono := _azar.randf_range(0.82, 1.0)
		var xf := Transform3D(giro.scaled(Vector3.ONE * talla), sitios[i].origin)
		var arr := variantes[k].surface_get_arrays(0)
		var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var cc: Variant = arr[Mesh.ARRAY_COLOR]
		var ii: Variant = arr[Mesh.ARRAY_INDEX]
		var base := v.size()
		for j in vv.size():
			v.append(xf * vv[j])
			n.append((giro * nn[j]).normalized())
			var col := Color(1.0, 0.0, 0.0)
			if cc is PackedColorArray and (cc as PackedColorArray).size() == vv.size():
				col = (cc as PackedColorArray)[j]
			c.append(Color(col.r * tono, col.g, col.b, 1.0))
		if ii is PackedInt32Array and (ii as PackedInt32Array).size() > 0:
			for q in (ii as PackedInt32Array):
				idx.append(base + q)
		else:
			for j in vv.size():
				idx.append(base + j)
	var juntos := []
	juntos.resize(Mesh.ARRAY_MAX)
	juntos[Mesh.ARRAY_VERTEX] = v
	juntos[Mesh.ARRAY_NORMAL] = n
	juntos[Mesh.ARRAY_COLOR] = c
	juntos[Mesh.ARRAY_INDEX] = idx
	var malla := ArrayMesh.new()
	malla.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, juntos)
	var mmi := MeshInstance3D.new()
	mmi.mesh = malla
	mmi.material_override = _mundo.mat.call("dame", "hueso", {"vertice": true, "escala": 0.1,
		"tinte": Color(0.72, 0.66, 0.58), "suciedad": 0.8})
	mmi.layers = Nucleo.CAPA_BAJO_SUELO
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.set_meta("arq", "osario")
	_mundo.add_child(mmi)
	_nodos.append(mmi)

## UN PILAR, del suelo de la sala al dintel: plinto ochavado, basa de toros,
## fuste redondo con un poco de éntasis, collarino, capitel de campana y ábaco.
## Era un poste ochavado con dos losas encima que acababa en el aire.
func _pilar(m: Malla) -> void:
	var y_fuste := Y_SALA + 0.44
	var y_collar := H_CAPITEL_PILAR - 0.5
	_pieza(m, _plano(), _octogono(0.62, 0.13), Y_SALA, Y_SALA + 0.24, 0.03, Y_SALA, 1.0)
	_torno(m, Vector3(0.0, Y_SALA + 0.24, 0.0), [Vector2(0.27, 0.0), Vector2(0.285, 0.03),
		Vector2(0.28, 0.07), Vector2(0.255, 0.09), Vector2(0.235, 0.1), Vector2(0.24, 0.12),
		Vector2(0.255, 0.14), Vector2(0.25, 0.165), Vector2(0.225, 0.18), Vector2(0.215, 0.2)], 10, Y_SALA)
	_torno(m, Vector3(0.0, y_fuste, 0.0), [Vector2(0.215, 0.0),
		Vector2(0.222, (y_collar - y_fuste) * 0.35), Vector2(0.2, y_collar - y_fuste)], 10, Y_SALA)
	_torno(m, Vector3(0.0, y_collar, 0.0), [Vector2(0.2, 0.0), Vector2(0.226, 0.015),
		Vector2(0.226, 0.045), Vector2(0.2, 0.06)], 10, -10.0)
	_torno(m, Vector3(0.0, y_collar + 0.06, 0.0), [Vector2(0.2, 0.0), Vector2(0.235, 0.12),
		Vector2(0.29, 0.24), Vector2(0.325, 0.3)], 10, -10.0)
	_pieza(m, _plano(), _rect_c(Vector2.ZERO, 0.31), y_collar + 0.36, H_CAPITEL_PILAR, 0.025, -10.0, 1.0)

# ================================================================== la bóveda

## La altura del techo de la sala en un punto (x, z): el intradós de la bóveda
## que haya encima, o el testero inclinado si está delante. Para colgar algo.
func techo(x: float, z: float) -> float:
	var y := _y_perfil(x)
	if z >= _z_testero:
		y = minf(y, H_INCLINA + (z - _z_testero) / INCLINA)
	return y

## El perfil de la bóveda visto de frente: la nave central entre los pilares, y
## las laterales hasta el muro de fuera.
func _y_perfil(x: float) -> float:
	var x0 := PILARES_X[0]
	var x1 := PILARES_X[1]
	if x >= x0 and x <= x1:
		var t := clampf((x - (x0 + x1) * 0.5) / ((x1 - x0) * 0.5), -1.0, 1.0)
		return ARRANQUE + (Y_BOVEDA - ARRANQUE) * sqrt(1.0 - t * t)
	var tl := clampf((x - (x0 if x < x0 else x1)) / NAVE_LADO, -1.0, 1.0)
	return COSTADO_Y + (ARRANQUE - COSTADO_Y) * sqrt(1.0 - tl * tl)

## Dónde empieza el cañón de la nave a una altura dada: detrás, el testero.
func _z_arranque(y: float) -> float:
	return _z_testero + maxf(y - H_INCLINA, 0.0) * INCLINA

## Un punto del perfil de la nave central (a = 0 el pilar derecho, PI el
## izquierdo), metido `d` hacia dentro, y la normal hacia dentro.
func _nave(a: float, d: float = 0.0) -> Array:
	var cx := (PILARES_X[0] + PILARES_X[1]) * 0.5
	var rx := (PILARES_X[1] - PILARES_X[0]) * 0.5
	var ry := Y_BOVEDA - ARRANQUE
	var n := -Vector2(cos(a) / rx, sin(a) / ry).normalized()
	var p := Vector2(cx + rx * cos(a), ARRANQUE + ry * sin(a)) + n * d
	return [p, Vector3(n.x, n.y, 0.0)]

## Un punto del perfil de una nave lateral (b = 0 abajo en el muro de fuera,
## PI/2 arriba en el pilar), metido `d` hacia dentro, y la normal hacia dentro.
func _lateral(lado: float, b: float, d: float = 0.0) -> Array:
	var cx := PILARES_X[0] if lado < 0.0 else PILARES_X[1]
	var ry := ARRANQUE - COSTADO_Y
	var n := -Vector2(lado * cos(b) / NAVE_LADO, sin(b) / ry).normalized()
	var p := Vector2(cx + lado * NAVE_LADO * cos(b), COSTADO_Y + ry * sin(b)) + n * d
	return [p, Vector3(n.x, n.y, 0.0)]

## LA BÓVEDA. Todo lo de aquí arriba es de UNA SOLA CARA y mira hacia abajo o
## hacia dentro: desde la sala se ve, y la cámara CENITAL (y = 13,5) la atraviesa
## porque la ve de espaldas y una cara de espaldas no se dibuja. Por eso los
## arcos fajones no tienen lomo: un lomo mira arriba y desde la cenital se vería
## cruzando la mesa. Sin sombra y fuera del reflejo (`_lienzo(…, alto)`).
func _montar_boveda() -> void:
	var cz := _z_testero
	var zf := SALA_Z.y
	var cortes: Array[float] = [cz]
	cortes.append_array(PILARES_Z)
	cortes.append(zf)
	var cx := (PILARES_X[0] + PILARES_X[1]) * 0.5

	# EL CAÑÓN DE LA NAVE, en tramos de pilar a pilar. El primero empieza donde
	# acaba el testero, que a media altura ya está echado hacia delante.
	var n := 24
	for i in n:
		var a0 := PI * float(i) / float(n)
		var a1 := PI * float(i + 1) / float(n)
		var q0: Array = _nave(a0)
		var q1: Array = _nave(a1)
		var p0: Vector2 = q0[0]
		var p1: Vector2 = q1[0]
		# Más oscuro en los arranques: es donde la bóveda se mete detrás del dintel.
		var c0 := Color(lerpf(0.5, 0.85, sin(a0)), 0.0, 0.0)
		var c1 := Color(lerpf(0.5, 0.85, sin(a1)), 0.0, 0.0)
		for k in cortes.size() - 1:
			var za0: float = _z_arranque(p0.y) if k == 0 else cortes[k]
			var zb0: float = _z_arranque(p1.y) if k == 0 else cortes[k]
			var z1: float = cortes[k + 1]
			var m := _lienzo("boveda", Vector3(cx, Y_BOVEDA, (za0 + z1) * 0.5), false, true)
			var desde := m.v.size()
			m.cuadro(Vector3(p0.x, p0.y, za0), Vector3(p1.x, p1.y, zb0), Vector3(p1.x, p1.y, z1),
				Vector3(p0.x, p0.y, z1), q0[1], q1[1], q1[1], q0[1], c0, c1, c1, c0)
			# La plementería apenas: lo que se adivina son los fajones.
			m.libre(desde, func(p: Vector3) -> float: return 0.22 * _cerca_abside(p))

	# LAS NAVES LATERALES (cuarto de cañón) y su muro de fuera.
	for lado: float in [-1.0, 1.0]:
		var nl := 8
		for i in nl:
			var b0 := PI * 0.5 * float(i) / float(nl)
			var b1 := PI * 0.5 * float(i + 1) / float(nl)
			var q0: Array = _lateral(lado, b0)
			var q1: Array = _lateral(lado, b1)
			var p0: Vector2 = q0[0]
			var p1: Vector2 = q1[0]
			var c0 := Color(lerpf(0.45, 0.7, sin(b0)), 0.0, 0.0)
			var c1 := Color(lerpf(0.45, 0.7, sin(b1)), 0.0, 0.0)
			for k in cortes.size() - 1:
				var z0: float = cortes[k]
				var z1: float = cortes[k + 1]
				var m := _lienzo("boveda", Vector3(p0.x, 3.0, (z0 + z1) * 0.5), false, true)
				m.cuadro(Vector3(p0.x, p0.y, z0), Vector3(p1.x, p1.y, z0), Vector3(p1.x, p1.y, z1),
					Vector3(p0.x, p0.y, z1), q0[1], q1[1], q1[1], q0[1], c0, c1, c1, c0)
		var xm := SALA_X.x if lado < 0.0 else SALA_X.y
		var nm := Vector3(-lado, 0.0, 0.0)
		for k in cortes.size() - 1:
			var z0: float = cortes[k]
			var z1: float = cortes[k + 1]
			var m := _lienzo("sala", Vector3(xm, 1.0, (z0 + z1) * 0.5), false, true)
			m.cuadro(Vector3(xm, Y_SALA, z0), Vector3(xm, Y_SALA, z1), Vector3(xm, COSTADO_Y, z1),
				Vector3(xm, COSTADO_Y, z0), nm, nm, nm, nm, Color(0.45, 0.0, 0.0),
				Color(0.45, 0.0, 0.0), Color(0.6, 0.0, 0.0), Color(0.6, 0.0, 0.0))
		# Las pilastras del muro de fuera, enfrente de cada pilar: de ahí arranca
		# el fajón de la nave lateral.
		for pz: float in PILARES_Z:
			var pil := PackedVector2Array([Vector2(xm, pz - 0.22), Vector2(xm - lado * 0.2, pz - 0.22),
				Vector2(xm - lado * 0.2, pz + 0.22), Vector2(xm, pz + 0.22)])
			_pieza(_lienzo("sala", Vector3(xm, 1.0, pz), false, true), _plano(), pil, Y_SALA,
				COSTADO_Y + 0.05, 0.03, Y_SALA, 1.0)

	# LOS ARCOS FAJONES: uno por cada fila de pilares, de pilar a pilar por la
	# nave y del pilar al muro por los lados.
	for pz: float in PILARES_Z:
		var pts: Array = []
		for i in n + 1:
			pts.append(_nave(PI * float(i) / float(n)))
		_fajon(pts, pz, Vector3(cx, Y_BOVEDA, pz))
		for lado: float in [-1.0, 1.0]:
			var lat: Array = []
			for i in 9:
				lat.append(_lateral(lado, PI * 0.5 * float(i) / 8.0))
			_fajon(lat, pz, Vector3(cx + lado * 6.0, 3.5, pz))

	# EL DINTEL que corre sobre cada fila de pilares, del testero al final.
	for px: float in PILARES_X:
		var h := ARRANQUE - H_DINTEL * 0.5
		var tramo := cz
		for z1: float in cortes.slice(1):
			_barrido(_lienzo("sala", Vector3(px, h, (tramo + z1) * 0.5), false, true),
				PackedVector3Array([Vector3(px, h, tramo), Vector3(px, h, z1)]), Vector3.UP,
				_seccion_rect(H_DINTEL * 0.5, 0.22, 0.03), 0.0, true)
			tramo = z1

	_testero()
	_concha()

	# LOS ANCLAJES de las cadenas: las de la viga de la campana, las de la sala y
	# la clave de cada fajón de la nave.
	for q: Vector2 in CADENAS_VIGA:
		anclajes_boveda.append(_argolla_techo(Vector3(q.x, techo(q.x, q.y), q.y)))
	for q: Vector2 in CADENAS_SALA:
		anclajes_boveda.append(_argolla_techo(Vector3(q.x, techo(q.x, q.y), q.y)))
	for pz: float in PILARES_Z:
		anclajes_boveda.append(_argolla_techo(Vector3(cx, Y_BOVEDA - FAJON_FONDO, pz)))

## Un arco fajón por una polilínea de [punto (x, y), normal hacia dentro], en el
## plano z = `z`. Sin lomo: el intradós y dos costados en talud (ver arriba).
func _fajon(pts: Array, z: float, donde: Vector3) -> void:
	var m := _lienzo("boveda", donde, false, true)
	var desde := m.v.size()
	var d := FAJON_FONDO
	var medio_in := 0.15
	var medio_out := 0.25
	var zz := Vector3(0.0, 0.0, z)
	var dz_in := Vector3(0.0, 0.0, medio_in)
	var dz_out := Vector3(0.0, 0.0, medio_out)
	var ci := Color(0.85, 0.25, 0.0)
	var cs := Color(0.6, 0.0, 0.0)
	for i in pts.size() - 1:
		var pa: Vector2 = pts[i][0]
		var pb: Vector2 = pts[i + 1][0]
		var na: Vector3 = pts[i][1]
		var nb: Vector3 = pts[i + 1][1]
		var ia := Vector3(pa.x, pa.y, 0.0) + na * d
		var ib := Vector3(pb.x, pb.y, 0.0) + nb * d
		var sa := Vector3(pa.x, pa.y, 0.0)
		var sb := Vector3(pb.x, pb.y, 0.0)
		# El intradós.
		m.cuadro(ia + zz - dz_in, ib + zz - dz_in, ib + zz + dz_in, ia + zz + dz_in, na, nb, nb, na,
			ci, ci, ci, ci)
		# Los dos costados, de la arista del intradós a la bóveda.
		for s: float in [-1.0, 1.0]:
			var ns_a := (na * (medio_out - medio_in) + Vector3(0.0, 0.0, s * d)).normalized()
			var ns_b := (nb * (medio_out - medio_in) + Vector3(0.0, 0.0, s * d)).normalized()
			m.cuadro(ia + zz + dz_in * s, ib + zz + dz_in * s, sb + zz + dz_out * s, sa + zz + dz_out * s,
				ns_a, ns_b, ns_b, ns_a, ci, ci, cs, cs)
	# El fajón, un punto más claro que la plementería y más cuanto más cerca del
	# ábside. Por igual de arriba abajo: el rebote no sube, se queda.
	m.libre(desde, func(p: Vector3) -> float: return _cerca_abside(p))

## EL TESTERO: el muro del fondo de la sala por encima de los paños de abajo,
## hasta la bóveda, con el hueco del arco triunfal. De una cara; vertical hasta
## `H_INCLINA` y echado hacia delante encima (ver la constante).
func _testero() -> void:
	var cz := _z_testero
	var x0 := PILARES_X[0]
	var x1 := PILARES_X[1]
	var pol := PackedVector2Array([Vector2(SALA_X.x, Y_SALA), Vector2(x0, Y_SALA),
		Vector2(x0, H_SALA_MURO), Vector2(x1, H_SALA_MURO), Vector2(x1, Y_SALA), Vector2(SALA_X.y, Y_SALA)])
	for i in range(0, 9):
		var q: Vector2 = _lateral(1.0, PI * 0.5 * float(i) / 8.0)[0]
		pol.append(q)
	for i in range(1, 24):
		var q: Vector2 = _nave(PI * float(i) / 24.0)[0]
		pol.append(q)
	for i in range(0, 9):
		var q: Vector2 = _lateral(-1.0, PI * 0.5 * float(8 - i) / 8.0)[0]
		pol.append(q)
	# El hueco del arco: el trasdós de la media elipse y, debajo, el ábside.
	var hueco := PackedVector2Array([Vector2(2.0 - ARCO_ANCHO - 0.16, 0.0),
		Vector2(2.0 + ARCO_ANCHO + 0.16, 0.0)])
	for i in 25:
		var a := PI * float(i) / 24.0
		hueco.append(Vector2(2.0 + (ARCO_ANCHO + 0.16) * cos(a), ARCO_Y + (ARCO_ALTO + 0.15) * sin(a)))
	for trozo in _restar(pol, [hueco]):
		for parte: int in 2:
			var caja := Rect2(Vector2(-100.0, -10.0), Vector2(200.0, H_INCLINA + 10.0)) if parte == 0 \
				else Rect2(Vector2(-100.0, H_INCLINA), Vector2(200.0, 20.0))
			var corte := PackedVector2Array([caja.position, Vector2(caja.end.x, caja.position.y),
				caja.end, Vector2(caja.position.x, caja.end.y)])
			for pieza in Geometry2D.intersect_polygons(trozo, corte):
				if absf(_area(pieza)) < 1.0e-5:
					continue
				var idx := Geometry2D.triangulate_polygon(pieza)
				var nrm := Vector3.BACK if parte == 0 else Vector3(0.0, -INCLINA, 1.0).normalized()
				var k := 0
				while k + 2 < idx.size():
					var tri: Array[Vector3] = []
					var col: Array[Color] = []
					for j in 3:
						var q := pieza[idx[k + j]]
						tri.append(Vector3(q.x, q.y, _z_arranque(q.y) if parte == 1 else cz))
						col.append(Color(clampf(0.45 + (q.y - Y_SALA) * 0.06, 0.45, 0.8), 0.0, 0.0))
					var cen := (tri[0] + tri[1] + tri[2]) / 3.0
					_lienzo("sala", cen, false, true).tri(tri[0], tri[1], tri[2], nrm, nrm, nrm,
						col[0], col[1], col[2])
					k += 3

## LA BÓVEDA DEL ÁBSIDE (de horno): de la hilada de coronación a la clave del
## arco triunfal, con cuatro nervios que bajan a los huecos entre hornacinas.
## Cada meridiano sale vertical del muro y llega a la clave en horizontal.
func _concha() -> void:
	var k := Vector3(2.0, ARCO_Y + ARCO_ALTO, _z_testero)
	var dentro := Vector3(2.0, ARCO_Y, _z_testero)
	var nt := 16
	var ns := 8
	var malla: Array[Array] = []
	for i in nt + 1:
		var fila: Array = []
		var th := PI * float(i) / float(nt)
		for j in ns + 1:
			fila.append(_meridiano(th, float(j) / float(ns), k))
		malla.append(fila)
	for i in nt:
		for j in ns:
			var p00: Vector3 = malla[i][j]
			var p10: Vector3 = malla[i + 1][j]
			var p11: Vector3 = malla[i + 1][j + 1]
			var p01: Vector3 = malla[i][j + 1]
			var cols: Array[Color] = []
			var nrms: Array[Vector3] = []
			for q: Vector3 in [p00, p10, p11, p01]:
				nrms.append(_normal_concha(q, dentro))
				cols.append(Color(lerpf(0.5, 0.9, clampf((q.y - ARCO_Y) / ARCO_ALTO, 0.0, 1.0)), 0.0, 0.0))
			var m := _lienzo("concha", (p00 + p11) * 0.5, false, true)
			var desde := m.v.size()
			m.cuadro(p00, p10, p11, p01, nrms[0], nrms[1], nrms[2], nrms[3], cols[0], cols[1],
				cols[2], cols[3])
			m.libre(desde, _lavado_luna)
	# LOS NERVIOS, de la coronación a la clave.
	var sec := PackedVector2Array([Vector2(-0.055, -0.045), Vector2(0.055, -0.045),
		Vector2(0.07, -0.02), Vector2(0.07, 0.03), Vector2(0.045, 0.06), Vector2(-0.045, 0.06),
		Vector2(-0.07, 0.03), Vector2(-0.07, -0.02)])
	for g: float in ANTORCHAS_GRADOS:
		var th := deg_to_rad(g)
		var pts := PackedVector3Array()
		for j in 13:
			var q := _meridiano(th, float(j) / 12.0 * 0.96, k)
			pts.append(q + _normal_concha(q, dentro) * 0.045)
		var b := _meridiano(th, 0.0, k)
		var lado := Vector3(k.z - b.z, 0.0, b.x - k.x).normalized()
		var mn := _lienzo("nervio", pts[3], false, true)
		var desde := mn.v.size()
		_barrido(mn, pts, lado, sec, 0.0, true)
		mn.libre(desde, _recalor_nervio)
	# LA CLAVE: un florón donde se juntan los nervios y el arco.
	var nk := _normal_concha(_meridiano(PI * 0.5, 0.97, k), dentro)
	var mk := _lienzo("nervio", k, false, true)
	var desde_k := mk.v.size()
	_torno_eje(mk, k + nk * 0.02, nk, [Vector2(0.0, -0.02),
		Vector2(0.13, -0.02), Vector2(0.14, 0.02), Vector2(0.1, 0.06), Vector2(0.05, 0.08),
		Vector2(0.0, 0.09)], 12)
	mk.libre(desde_k, _recalor_nervio)

## Los nervios y el arco triunfal cogen el rebote de los fuegos del ábside, que
## están debajo: más abajo, más (de 0,9 en el arranque a 0,35 en la clave).
func _recalor_nervio(p: Vector3) -> float:
	return lerpf(0.9, 0.35, clampf((p.y - ARCO_Y) / ARCO_ALTO, 0.0, 1.0))

## El cuarto de esfera junto al óculo: la luna que entra lo lava de frío. Se
## acaba a 2,2 del óculo y no llega a la mitad derecha.
func _lavado_luna(p: Vector3) -> float:
	var t := clampf(1.0 - p.distance_to(OCULO_CENTRO + Vector3(0.2, 1.4, 0.0)) / 2.2, 0.0, 1.0)
	return 0.04 + 0.96 * t * t

## Un punto de la bóveda del ábside: `th` sobre la planta (0 la punta derecha),
## `s` de 0 (la coronación) a 1 (la clave). La planta es la del muro del ábside
## agrandada hasta las columnas, que cae dentro de su grueso.
func _meridiano(th: float, s: float, k: Vector3) -> Vector3:
	var b := Vector3(2.0 + ARCO_ANCHO * cos(th), ARCO_Y, _z_testero - _fondo_concha() * sin(th))
	var f := 1.0 - cos(s * PI * 0.5)
	return Vector3(lerpf(b.x, k.x, f), ARCO_Y + (k.y - ARCO_Y) * sin(s * PI * 0.5), lerpf(b.z, k.z, f))

## Cuánto entra la bóveda del ábside hacia el fondo (en z) desde el testero.
func _fondo_concha() -> float:
	var apice := _abside.p(_abside.s_de(PI * 0.5), 0.0, 0.0)
	var punta := _abside.p(0.0, 0.0, 0.0)
	return (punta.z - apice.z) * ARCO_ANCHO / maxf(absf(punta.x - 2.0), 0.5)

## La normal de la bóveda del ábside hacia dentro: la de un cuarto de elipsoide
## con los mismos radios, que es lo que es casi.
func _normal_concha(q: Vector3, dentro: Vector3) -> Vector3:
	var h := q - dentro
	var rz := _fondo_concha()
	var g := Vector3(h.x / (ARCO_ANCHO * ARCO_ANCHO), h.y / (ARCO_ALTO * ARCO_ALTO), h.z / (rz * rz))
	return -g.normalized()

## Una argolla de hierro clavada en el techo, en `p`: la placa, la grapa y el
## aro colgando. Devuelve el marco del anclaje: el fondo del aro, Y arriba.
func _argolla_techo(p: Vector3) -> Transform3D:
	var m := _lienzo("hierro", p, false, true)
	var y0 := p.y - 0.015
	var placa := PackedVector2Array([Vector2(p.x - 0.07, p.z - 0.07), Vector2(p.x + 0.07, p.z - 0.07),
		Vector2(p.x + 0.07, p.z + 0.07), Vector2(p.x - 0.07, p.z + 0.07)])
	# La placa: los cuatro cantos y la cara de abajo (la de arriba está dentro de
	# la piedra). Sube un poco: el techo puede ir inclinado.
	for i in 4:
		var q0 := placa[i]
		var q1 := placa[(i + 1) % 4]
		var lado := Vector3(q1.y - q0.y, 0.0, -(q1.x - q0.x)).normalized()
		m.cuadro(Vector3(q0.x, y0, q0.y), Vector3(q1.x, y0, q1.y), Vector3(q1.x, p.y + 0.06, q1.y),
			Vector3(q0.x, p.y + 0.06, q0.y), lado, lado, lado, lado, Color(0.7, 0.6, 0.0),
			Color(0.7, 0.6, 0.0), Color(0.3, 0.0, 0.0), Color(0.3, 0.0, 0.0))
	var blanco := Color(1.0, 0.0, 0.0)
	m.cuadro(Vector3(placa[0].x, y0, placa[0].y), Vector3(placa[1].x, y0, placa[1].y),
		Vector3(placa[2].x, y0, placa[2].y), Vector3(placa[3].x, y0, placa[3].y),
		Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, blanco, blanco, blanco, blanco)
	for q: Vector2 in [Vector2(-0.045, -0.045), Vector2(0.045, 0.045), Vector2(-0.045, 0.045),
			Vector2(0.045, -0.045)]:
		_remache(m, Vector3(p.x + q.x, y0, p.z + q.y), Vector3.DOWN, 0.014)
	var a := Vector3(p.x, y0, p.z)
	var grapa := a + Vector3.DOWN * 0.05
	_barrido(m, PackedVector3Array([a, grapa]), Vector3.RIGHT, _seccion_cuadrada(0.012, 0.004), 0.0, true)
	var rr := 0.075
	var anillo := PackedVector3Array()
	for k in 13:
		var ang := TAU * float(k) / 12.0
		anillo.append(grapa + Vector3(sin(ang) * rr, -rr + cos(ang) * rr, 0.0))
	_barrido(m, anillo, Vector3.BACK, _seccion_rombo(0.011), 0.0, false)
	return Transform3D(Basis(), grapa + Vector3.DOWN * (2.0 * rr))

static func _seccion_rect(medio_x: float, medio_y: float, chaflan: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-medio_x + chaflan, -medio_y), Vector2(medio_x - chaflan, -medio_y),
		Vector2(medio_x, -medio_y + chaflan), Vector2(medio_x, medio_y - chaflan),
		Vector2(medio_x - chaflan, medio_y), Vector2(-medio_x + chaflan, medio_y),
		Vector2(-medio_x, medio_y - chaflan), Vector2(-medio_x, -medio_y + chaflan)])

# ============================================================ los generadores

## Una pieza: un polígono en el plano (u, v) de un mapa, levantado de `w0` a
## `w1`, con el canto de delante biselado. El color de vértice: R oclusión
## (oscura al pie, a `y_pie`, y hacia el fondo de los costados por `fondo`), G
## canto en el bisel. `oclu_frente` oscurece la cara entera (el fondo de una
## hornacina). `tono` es el de la piedra: multiplica la R de la cara y del bisel,
## y como el material oscurece y ensucia con ella, cada sillar sale de su color.
func _pieza(m: Malla, mapa: Cara, pol_in: PackedVector2Array, w0: float, w1: float,
		bisel: float, y_pie: float, fondo: float, oclu_frente: float = 1.0, tono: float = 1.0) -> void:
	var pol := _ccw(pol_in)
	if mapa.curvo:
		pol = _densificar(pol, PASO_CURVA)
	var n := pol.size()
	if n < 3 or absf(_area(pol)) < 1.0e-6:
		return
	bisel = minf(bisel, (w1 - w0) * 0.45)
	var dentro := _desplazar(pol, -bisel) if bisel > 0.0 else pol
	var medio := _desplazar(pol, -bisel * 0.29) if bisel > 0.0 else pol
	var wb := w1 - bisel
	var wm := wb + bisel * 0.71
	var ne := PackedVector2Array()
	ne.resize(n)
	for i in n:
		var d := pol[(i + 1) % n] - pol[i]
		ne[i] = Vector2(d.y, -d.x).normalized()
	var liso := PackedByteArray()
	liso.resize(n)
	var nv := PackedVector2Array()
	nv.resize(n)
	for i in n:
		var a := ne[(i + n - 1) % n]
		var b := ne[i]
		liso[i] = 1 if a.dot(b) > 0.8 else 0
		nv[i] = (a + b).normalized()
	for i in n:
		var j := (i + 1) % n
		var na2 := nv[i] if liso[i] == 1 else ne[i]
		var nb2 := nv[j] if liso[j] == 1 else ne[i]
		var na := mapa.dir(pol[i].x, na2)
		var nb := mapa.dir(pol[j].x, nb2)
		# El costado.
		var a0 := mapa.p(pol[i].x, pol[i].y, w0)
		var a1 := mapa.p(pol[i].x, pol[i].y, wb)
		var b0 := mapa.p(pol[j].x, pol[j].y, w0)
		var b1 := mapa.p(pol[j].x, pol[j].y, wb)
		var ca0 := _oclu(a0.y, y_pie) * fondo
		var cb0 := _oclu(b0.y, y_pie) * fondo
		var ca1 := _oclu(a1.y, y_pie) * 0.92
		var cb1 := _oclu(b1.y, y_pie) * 0.92
		m.cuadro(a0, b0, b1, a1, na, nb, nb, na,
			Color(ca0, 0.0, 0.0), Color(cb0, 0.0, 0.0), Color(cb1, 0.0, 0.0), Color(ca1, 0.0, 0.0))
		if bisel > 0.0:
			# EL BISEL, redondo y oscuro. Era un chaflán de un solo plano con el canto
			# (G) a 0,7: cogía la luz como un listón y la junta se leía como un marco
			# CLARO alrededor de cada piedra («paneles de armario»). Ahora son dos
			# planos con la normal suavizada (se lee redondo) y la oclusión baja hacia
			# el fondo de la junta: la junta es lo más oscuro, nunca lo más claro.
			var wa := mapa.eje_w(pol[i].x)
			var wbn := mapa.eje_w(pol[j].x)
			var am := mapa.p(medio[i].x, medio[i].y, wm)
			var bm := mapa.p(medio[j].x, medio[j].y, wm)
			var a2 := mapa.p(dentro[i].x, dentro[i].y, w1)
			var b2 := mapa.p(dentro[j].x, dentro[j].y, w1)
			var na0 := (na * 0.75 + wa * 0.35).normalized()
			var nb0 := (nb * 0.75 + wbn * 0.35).normalized()
			var nam := (na + wa).normalized()
			var nbm := (nb + wbn).normalized()
			var na1 := (na * 0.2 + wa).normalized()
			var nb1 := (nb * 0.2 + wbn).normalized()
			var fa := _oclu(a2.y, y_pie) * oclu_frente * tono
			var fb := _oclu(b2.y, y_pie) * oclu_frente * tono
			m.cuadro(a1, b1, bm, am, na0, nb0, nbm, nam,
				Color(ca1 * 0.62, 0.0, 0.0), Color(cb1 * 0.62, 0.0, 0.0),
				Color(fb * 0.86, 0.3, 0.0), Color(fa * 0.86, 0.3, 0.0))
			m.cuadro(am, bm, b2, a2, nam, nbm, nb1, na1,
				Color(fa * 0.86, 0.3, 0.0), Color(fb * 0.86, 0.3, 0.0),
				Color(fb, 0.1, 0.0), Color(fa, 0.1, 0.0))
	# La cara de delante.
	var tri := _triangular(dentro, mapa.curvo)
	var pts: PackedVector2Array = tri[0]
	var idx: PackedInt32Array = tri[1]
	var p3 := PackedVector3Array()
	var n3 := PackedVector3Array()
	var c3 := PackedColorArray()
	for q in pts:
		var p := mapa.p(q.x, q.y, w1)
		p3.append(p)
		n3.append(mapa.eje_w(q.x))
		c3.append(Color(_oclu(p.y, y_pie) * oclu_frente * tono, 0.0, 0.0))
	var k := 0
	while k + 2 < idx.size():
		m.tri(p3[idx[k]], p3[idx[k + 1]], p3[idx[k + 2]], n3[idx[k]], n3[idx[k + 1]], n3[idx[k + 2]],
			c3[idx[k]], c3[idx[k + 1]], c3[idx[k + 2]])
		k += 3

## EL LLAGUEADO: el mortero del fondo de una junta entre dos sillares (ver
## `JUNTA`). Va metido `JUNTA_FONDO` por dentro de las caras y oscuro (la R baja:
## es hueco). Sin él la ranura se veía de lado a lado y, con los fuegos del
## campo detrás, la junta salía como un hilo de LUZ, no de sombra.
func _mortero(m: Malla, pol: PackedVector2Array, y0: float, y1: float) -> void:
	_pieza(m, _plano(), pol, y0, y1, 0.0, 10.0, 0.6, 0.5)

## El tono de un sillar (ver `_pieza`): de 0,78 a 1, y casi todos claros.
func _tono() -> float:
	return 1.0 - 0.22 * pow(_azar.randf(), 1.6)

static func _oclu(y: float, y_pie: float) -> float:
	var t := clampf((y - y_pie) / PIE_ALTO, 0.0, 1.0)
	return lerpf(PIE_OSCURO, 1.0, t * t * (3.0 - 2.0 * t))

## La cara de delante en triángulos. En plano basta con recortar orejas; en la
## cara curva del ábside, un triángulo largo cortaría la curva por la cuerda, así
## que se siembran puntos dentro y se triangula con Delaunay.
func _triangular(pol: PackedVector2Array, curvo: bool) -> Array:
	if not curvo:
		var idx := Geometry2D.triangulate_polygon(pol)
		if idx.size() >= 3:
			return [pol, idx]
	var pts := pol.duplicate()
	if curvo:
		var caja := _caja(pol)
		# La cara es reglada en vertical (un cilindro): solo hace falta partirla a
		# lo ancho. Las semillas a media altura son para que Delaunay no tienda un
		# triángulo largo de punta a punta; con una fila basta.
		var paso_u := PASO_CURVA
		var paso_v := 0.6
		var u := caja.position.x + paso_u * 0.5
		while u < caja.end.x:
			var v := caja.position.y + paso_v * 0.5
			while v < caja.end.y:
				if Geometry2D.is_point_in_polygon(Vector2(u, v), pol):
					pts.append(Vector2(u, v))
				v += paso_v
			u += paso_u
	var todos := Geometry2D.triangulate_delaunay(pts)
	var buenos := PackedInt32Array()
	var k := 0
	while k + 2 < todos.size():
		var g := (pts[todos[k]] + pts[todos[k + 1]] + pts[todos[k + 2]]) / 3.0
		if Geometry2D.is_point_in_polygon(g, pol):
			buenos.append(todos[k])
			buenos.append(todos[k + 1])
			buenos.append(todos[k + 2])
		k += 3
	return [pts, buenos]

## Una moldura: un perfil (fuera, alto, canto) corrido a lo largo de `u` en un
## mapa. El perfil va de abajo pegado al muro, hacia fuera y arriba.
func _moldura(mapa: Cara, u0: float, u1: float, perfil: Array[Vector3], material: String,
		y_pie: float, fija: Malla = null) -> void:
	var paso := PASO_CURVA if mapa.curvo else (u1 - u0)
	var pasos := maxi(int(ceil((u1 - u0) / paso)), 1)
	var np := perfil.size()
	for s in pasos:
		var ua := lerpf(u0, u1, float(s) / float(pasos))
		var ub := lerpf(u0, u1, float(s + 1) / float(pasos))
		var m := fija if fija != null else _lienzo(material, mapa.p(ua, perfil[0].y, 0.0))
		for i in np - 1:
			var pa := perfil[i]
			var pb := perfil[i + 1]
			var d := Vector2(pb.x - pa.x, pb.y - pa.y)
			var n2 := Vector2(d.y, -d.x).normalized()
			var a0 := mapa.p(ua, pa.y, pa.x)
			var a1 := mapa.p(ua, pb.y, pb.x)
			var b0 := mapa.p(ub, pa.y, pa.x)
			var b1 := mapa.p(ub, pb.y, pb.x)
			var na := mapa.eje_w(ua) * n2.x + Vector3.UP * n2.y
			var nb := mapa.eje_w(ub) * n2.x + Vector3.UP * n2.y
			# Lo que mira abajo está en la sombra de lo que vuela.
			var bajo := 0.62 if n2.y < -0.3 else 1.0
			var ca := Color(_oclu(pa.y, y_pie) * bajo, pa.z, 0.0)
			var cb := Color(_oclu(pb.y, y_pie) * bajo, pb.z, 0.0)
			m.cuadro(a0, b0, b1, a1, na, nb, nb, na, ca, ca, cb, cb)

## Una moldura corrida por una polilínea de planta, con inglete en las esquinas.
## `interior` es un punto de dentro: el perfil crece hacia el otro lado.
func _barrido_planta(pts: PackedVector2Array, interior: Vector2, perfil: Array[Vector3],
		material: String, y_pie: float) -> void:
	var n := pts.size()
	for i in n - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var d := (b - a).normalized()
		var fuera := Vector2(d.y, -d.x)
		if fuera.dot((a + b) * 0.5 - interior) < 0.0:
			fuera = -fuera
		# Los ingletes: en cada punta, la bisectriz con el tramo vecino.
		var ia := fuera
		var ib := fuera
		if i > 0:
			ia = _inglete(pts[i - 1], a, b, fuera)
		if i < n - 2:
			ib = _inglete(a, b, pts[i + 2], fuera)
		# La celda se decide un palmo por fuera de la cara: así cada costado del
		# mueble cae en la celda de su lado de la sala (con sus fuegos) y no los
		# tres en la del medio, que juntos tocaban once.
		var m := _lienzo(material, Vector3((a.x + b.x) * 0.5 + fuera.x * 0.3, -0.5,
			(a.y + b.y) * 0.5 + fuera.y * 0.3), true)
		for k in perfil.size() - 1:
			var pa := perfil[k]
			var pb := perfil[k + 1]
			var dd := Vector2(pb.x - pa.x, pb.y - pa.y)
			var n2 := Vector2(dd.y, -dd.x).normalized()
			var nn := Vector3(fuera.x * n2.x, n2.y, fuera.y * n2.x)
			var a0 := Vector3(a.x + ia.x * pa.x, pa.y, a.y + ia.y * pa.x)
			var a1 := Vector3(a.x + ia.x * pb.x, pb.y, a.y + ia.y * pb.x)
			var b0 := Vector3(b.x + ib.x * pa.x, pa.y, b.y + ib.y * pa.x)
			var b1 := Vector3(b.x + ib.x * pb.x, pb.y, b.y + ib.y * pb.x)
			var bajo := 0.62 if n2.y < -0.3 else 1.0
			var ca := Color(_oclu(pa.y, y_pie) * bajo, pa.z, 0.0)
			var cb := Color(_oclu(pb.y, y_pie) * bajo, pb.z, 0.0)
			m.cuadro(a0, b0, b1, a1, nn, nn, nn, nn, ca, ca, cb, cb)

## El vector de inglete en `b`, entre los tramos a→b y b→c, escalado para que el
## perfil conserve su grueso.
func _inglete(a: Vector2, b: Vector2, c: Vector2, fuera_ab: Vector2) -> Vector2:
	var d1 := (b - a).normalized()
	var d2 := (c - b).normalized()
	var n1 := Vector2(d1.y, -d1.x)
	var n2 := Vector2(d2.y, -d2.x)
	if n1.dot(fuera_ab) < 0.0:
		n1 = -n1
		n2 = -n2
	var m := (n1 + n2).normalized()
	return m / maxf(m.dot(n1), 0.3)

## Una sección cerrada (en el plano lado × arriba) corrida por una polilínea 3D.
## `lado` es un eje fijo de la sección (para un nervio, la normal de su plano).
## Con `tapas`, cierra las puntas; con `rotura`, la última punta sale mellada.
func _barrido(m: Malla, pts: PackedVector3Array, lado: Vector3, sec: PackedVector2Array,
		y_pie: float, tapas: bool, rotura: float = 0.0) -> void:
	var n := pts.size()
	if n < 2:
		return
	var ns := sec.size()
	var anillos: Array[PackedVector3Array] = []
	var marcos: Array[Basis] = []
	for i in n:
		var t := Vector3.ZERO
		if i > 0:
			t += (pts[i] - pts[i - 1]).normalized()
		if i < n - 1:
			t += (pts[i + 1] - pts[i]).normalized()
		t = t.normalized()
		var b := t.cross(lado).normalized()
		if b.length_squared() < 0.5:
			b = t.cross(Vector3.UP if absf(t.y) < 0.9 else Vector3.RIGHT).normalized()
		var a := b.cross(t).normalized()
		marcos.append(Basis(a, b, t))
		var anillo := PackedVector3Array()
		for q in sec:
			var p := pts[i] + a * q.x + b * q.y
			if rotura > 0.0 and i == n - 1:
				p += t * _azar.randf_range(-rotura, rotura) * 0.6
			anillo.append(p)
		anillos.append(anillo)
	for i in n - 1:
		for k in ns:
			var k2 := (k + 1) % ns
			var e := sec[k2] - sec[k]
			var e2 := Vector2(e.y, -e.x).normalized()
			# Que la normal salga hacia fuera de la sección sea cual sea su giro.
			if e2.dot((sec[k] + sec[k2]) * 0.5) < 0.0:
				e2 = -e2
			var na := marcos[i].x * e2.x + marcos[i].y * e2.y
			var nb := marcos[i + 1].x * e2.x + marcos[i + 1].y * e2.y
			var p0 := anillos[i][k]
			var p1 := anillos[i][k2]
			var p2 := anillos[i + 1][k2]
			var p3 := anillos[i + 1][k]
			var abajo := 0.7 if e2.y < -0.5 and absf(lado.y) < 0.5 else 1.0
			var c0 := Color(_oclu(p0.y, y_pie) * abajo, 0.3, 0.0)
			var c1 := Color(_oclu(p1.y, y_pie) * abajo, 0.3, 0.0)
			var c2 := Color(_oclu(p2.y, y_pie) * abajo, 0.3, 0.0)
			var c3 := Color(_oclu(p3.y, y_pie) * abajo, 0.3, 0.0)
			m.cuadro(p0, p1, p2, p3, na, na, nb, nb, c0, c1, c2, c3)
	if tapas:
		for punta: int in [0, n - 1]:
			var anillo: PackedVector3Array = anillos[punta]
			var t: Vector3 = marcos[punta].z * (-1.0 if punta == 0 else 1.0)
			var centro := Vector3.ZERO
			for q in anillo:
				centro += q
			centro /= float(ns)
			if rotura > 0.0 and punta == n - 1:
				centro += t * rotura * 0.5
			for k in ns:
				var k2 := (k + 1) % ns
				var nn := t
				if rotura > 0.0 and punta == n - 1:
					nn = (anillo[k2] - anillo[k]).cross(centro - anillo[k]).normalized()
					if nn.dot(t) < 0.0:
						nn = -nn
				m.tri(anillo[k], anillo[k2], centro, nn, nn, nn,
					Color(0.7, 0.6, 0.0), Color(0.7, 0.6, 0.0), Color(0.8, 0.2, 0.0))

## Un sólido de revolución alrededor de un eje vertical. El perfil va en
## (radio, alto desde `base`); con `dentro`, las normales miran al eje (un pozo).
func _torno(m: Malla, base: Vector3, perfil: Array, lados: int, y_pie: float,
		dentro: bool = false) -> void:
	_torno_eje(m, base, Vector3.UP, perfil, lados, y_pie, dentro)

func _torno_eje(m: Malla, base: Vector3, eje: Vector3, perfil: Array, lados: int,
		y_pie: float = -10.0, dentro: bool = false) -> void:
	var y := eje.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	var np := perfil.size()
	for i in np - 1:
		var pa: Vector2 = perfil[i]
		var pb: Vector2 = perfil[i + 1]
		var d := pb - pa
		var n2 := Vector2(d.y, -d.x).normalized()
		if dentro:
			n2 = -n2
		for k in lados:
			var a0 := TAU * float(k) / float(lados)
			var a1 := TAU * float(k + 1) / float(lados)
			var r0 := x * cos(a0) + z * sin(a0)
			var r1 := x * cos(a1) + z * sin(a1)
			var p0 := base + r0 * pa.x + y * pa.y
			var p1 := base + r1 * pa.x + y * pa.y
			var p2 := base + r1 * pb.x + y * pb.y
			var p3 := base + r0 * pb.x + y * pb.y
			var n0 := (r0 * n2.x + y * n2.y).normalized()
			var n1 := (r1 * n2.x + y * n2.y).normalized()
			var g := 1.0 if absf(n2.x) > 0.3 and absf(n2.y) > 0.3 else 0.0
			var ca := Color(_oclu(p0.y, y_pie), g, 0.0)
			var cb := Color(_oclu(p3.y, y_pie), g, 0.0)
			if dentro:
				ca = Color(0.15, 0.0, 0.0)
				cb = Color(0.5 if pb.y > pa.y else 0.15, 0.0, 0.0)
			m.cuadro(p0, p1, p2, p3, n0, n1, n1, n0, ca, ca, cb, cb)

## Un remache: una cabeza de gota sobre una superficie.
## Seis lados y dos anillos: un remache mide un centímetro, y con siete lados y
## tres anillos los remaches eran la cuarta parte de los triángulos del módulo.
func _remache(m: Malla, p: Vector3, normal: Vector3, r: float) -> void:
	_torno_eje(m, p - normal * r * 0.2, normal, [Vector2(r, 0.0), Vector2(r * 0.8, r * 0.5),
		Vector2(0.0, r * 0.75)], 6)

# ================================================================== los mapas

func _plano() -> Cara:
	var m := Cara.new()
	m.horizontal = true
	return m

func _vertical(origen: Vector3, t: Vector3, n: Vector3) -> Cara:
	var m := Cara.new()
	m.o = origen
	m.t = t.normalized()
	m.nw = n.normalized()
	return m

# ================================================================ geometría 2D

static func _area(pol: PackedVector2Array) -> float:
	var a := 0.0
	var n := pol.size()
	for i in n:
		var p := pol[i]
		var q := pol[(i + 1) % n]
		a += p.x * q.y - q.x * p.y
	return a * 0.5

static func _ccw(pol: PackedVector2Array) -> PackedVector2Array:
	if _area(pol) < 0.0:
		var r := pol.duplicate()
		r.reverse()
		return r
	return pol

static func _densificar(pol: PackedVector2Array, paso: float) -> PackedVector2Array:
	var r := PackedVector2Array()
	var n := pol.size()
	for i in n:
		var a := pol[i]
		var b := pol[(i + 1) % n]
		var k := maxi(int(ceil(absf(b.x - a.x) / paso)), 1)
		for j in k:
			r.append(a.lerp(b, float(j) / float(k)))
	return r

## Desplaza un polígono CCW: positivo hacia fuera, negativo hacia dentro. A
## inglete, con tope: un vértice muy agudo no se dispara.
static func _desplazar(pol: PackedVector2Array, d: float) -> PackedVector2Array:
	var r := PackedVector2Array()
	var n := pol.size()
	for i in n:
		var a := pol[(i + n - 1) % n]
		var b := pol[i]
		var c := pol[(i + 1) % n]
		var e1 := (b - a).normalized()
		var e2 := (c - b).normalized()
		var n1 := Vector2(e1.y, -e1.x)
		var n2 := Vector2(e2.y, -e2.x)
		var m := n1 + n2
		if m.length_squared() < 1.0e-6:
			m = n1
		m = m.normalized()
		r.append(b + m * d / maxf(m.dot(n1), 0.35))
	return r

## Como `_desplazar`, pero cada lado `i` (de `i` a `i+1`) con su propia distancia.
static func _desplazar_lados(pol: PackedVector2Array, ds: PackedFloat32Array) -> PackedVector2Array:
	var r := PackedVector2Array()
	var n := pol.size()
	for i in n:
		var a := pol[(i + n - 1) % n]
		var b := pol[i]
		var c := pol[(i + 1) % n]
		var e1 := (b - a).normalized()
		var e2 := (c - b).normalized()
		var n1 := Vector2(e1.y, -e1.x)
		var n2 := Vector2(e2.y, -e2.x)
		var d1 := ds[(i + n - 1) % n]
		var d2 := ds[i]
		# El punto que está a d1 de la recta de antes y a d2 de la de después.
		var p1 := b + n1 * d1
		var p2 := b + n2 * d2
		var cruce: Variant = Geometry2D.line_intersects_line(p1, e1, p2, e2)
		r.append(cruce if cruce is Vector2 else b + n2 * d2)
	return r

## Lo que queda de un polígono tras quitarle unos huecos. Si un hueco queda
## entero dentro (el recorte daría un agujero), se parte el polígono en dos.
func _restar(pol: PackedVector2Array, huecos: Array) -> Array[PackedVector2Array]:
	var vivos: Array[PackedVector2Array] = [_ccw(pol)]
	for h: PackedVector2Array in huecos:
		var caja_h := _caja(h)
		var siguientes: Array[PackedVector2Array] = []
		for p in vivos:
			if not _caja(p).intersects(caja_h):
				siguientes.append(p)
				continue
			var trozos := Geometry2D.clip_polygons(p, h)
			var agujero := false
			for t in trozos:
				if _area(t) < 0.0:
					agujero = true
			if agujero:
				var cp := _caja(p)
				var corte := caja_h.get_center().x
				var izq := Geometry2D.intersect_polygons(p, PackedVector2Array([cp.position - Vector2.ONE,
					Vector2(corte, cp.position.y - 1.0), Vector2(corte, cp.end.y + 1.0),
					Vector2(cp.position.x - 1.0, cp.end.y + 1.0)]))
				var der := Geometry2D.intersect_polygons(p, PackedVector2Array([Vector2(corte, cp.position.y - 1.0),
					Vector2(cp.end.x + 1.0, cp.position.y - 1.0), cp.end + Vector2.ONE,
					Vector2(corte, cp.end.y + 1.0)]))
				var mitades: Array[PackedVector2Array] = []
				mitades.append_array(izq)
				mitades.append_array(der)
				for mitad in mitades:
					for t in Geometry2D.clip_polygons(mitad, h):
						if _area(t) > 0.0:
							siguientes.append(t)
			else:
				for t in trozos:
					siguientes.append(t)
		vivos = siguientes
	return vivos

## Un polígono con la esquina `i` mellada: dos puntos en vez de uno, a unos
## centímetros por los dos lados.
func _esquina_rota(pol: PackedVector2Array, i: int) -> PackedVector2Array:
	var n := pol.size()
	var p := pol[i]
	var a := pol[(i + n - 1) % n]
	var b := pol[(i + 1) % n]
	var r := PackedVector2Array()
	for k in n:
		if k == i:
			r.append(p + (a - p).normalized() * _azar.randf_range(0.03, 0.07))
			r.append(p + (b - p).normalized() * _azar.randf_range(0.02, 0.05))
		else:
			r.append(pol[k])
	return r

## El cierre de una figura (o de varias): se engorda `r` y se vuelve a
## adelgazar, con las esquinas redondas. Rellena los rincones de dentro con un
## redondeo de radio `r` y deja igual lo demás.
static func _cerrar(pols: Array, r: float) -> Array[PackedVector2Array]:
	var fuera: Array[PackedVector2Array] = []
	for pol: PackedVector2Array in pols:
		if _area(pol) < 0.0:
			continue
		for g: PackedVector2Array in Geometry2D.offset_polygon(pol, r, Geometry2D.JOIN_ROUND):
			for f: PackedVector2Array in Geometry2D.offset_polygon(g, -r, Geometry2D.JOIN_ROUND):
				if _area(f) > 0.0:
					fuera.append(f)
	return fuera

static func _caja(pol: PackedVector2Array) -> Rect2:
	var r := Rect2(pol[0], Vector2.ZERO)
	for q in pol:
		r = r.expand(q)
	return r

static func _circulo(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var pol := PackedVector2Array()
	for k in n:
		var a := TAU * float(k) / float(n)
		pol.append(c + Vector2(cos(a), sin(a)) * r)
	return pol

static func _rect_c(c: Vector2, medio: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(-medio, -medio), c + Vector2(medio, -medio),
		c + Vector2(medio, medio), c + Vector2(-medio, medio)])

## Un cuadrado de lado `lado` con las esquinas achaflanadas `chaflan`.
static func _octogono(lado: float, chaflan: float) -> PackedVector2Array:
	var h := lado * 0.5
	var c := h - chaflan
	return PackedVector2Array([Vector2(-c, -h), Vector2(c, -h), Vector2(h, -c), Vector2(h, c),
		Vector2(c, h), Vector2(-c, h), Vector2(-h, c), Vector2(-h, -c)])

static func _seccion_cuadrada(medio: float, chaflan: float) -> PackedVector2Array:
	if chaflan <= 0.0:
		return PackedVector2Array([Vector2(-medio, -medio), Vector2(medio, -medio),
			Vector2(medio, medio), Vector2(-medio, medio)])
	return _octogono(medio * 2.0, chaflan)

static func _seccion_rombo(r: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(0.0, -r), Vector2(r, 0.0), Vector2(0.0, r), Vector2(-r, 0.0)])

## El centro de un polígono de planta, a una altura.
static func _centro3(pol: PackedVector2Array, y: float) -> Vector3:
	var c := Vector2.ZERO
	for q in pol:
		c += q
	c /= float(pol.size())
	return Vector3(c.x, y, c.y)

# ================================================================== las clases

## Una malla en construcción: triángulos sueltos con normal y color de vértice.
class Malla extends RefCounted:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var material := ""
	var bajo_suelo := false
	var alto := false

	## La cara vista es la que mira hacia donde apuntan las normales: Godot toma
	## como vista la que va en sentido horario, y decidirlo aquí una vez es la
	## forma de no dejar media pieza del revés.
	func tri(p0: Vector3, p1: Vector3, p2: Vector3, n0: Vector3, n1: Vector3, n2: Vector3,
			c0: Color, c1: Color, c2: Color) -> void:
		if (p1 - p0).cross(p2 - p0).dot(n0 + n1 + n2) > 0.0:
			v.append_array([p0, p2, p1])
			n.append_array([n0, n2, n1])
			c.append_array([c0, c2, c1])
		else:
			v.append_array([p0, p1, p2])
			n.append_array([n0, n1, n2])
			c.append_array([c0, c1, c2])

	func cuadro(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
			n0: Vector3, n1: Vector3, n2: Vector3, n3: Vector3,
			c0: Color, c1: Color, c2: Color, c3: Color) -> void:
		tri(p0, p1, p2, n0, n1, n2, c0, c1, c2)
		tri(p0, p2, p3, n0, n2, n3, c0, c2, c3)

	## Pone el canal B (la luz propia, ver `_luz_propia`) de los vértices que se
	## han añadido desde `desde`, según dónde está cada uno: `f(p) -> float`.
	func libre(desde: int, f: Callable) -> void:
		for i in range(desde, v.size()):
			var col := c[i]
			col.b = clampf(float(f.call(v[i])), 0.0, 1.0)
			c[i] = col

	func malla() -> ArrayMesh:
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_COLOR] = c
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		return am

## Una superficie donde se dibuja en dos coordenadas (u, v) y se levanta en
## una tercera (w), que sale de la cara:
##   horizontal  u = x, v = z, w = altura
##   vertical    un plano: u a lo largo de `t`, v la altura, w hacia `nw`
##   curvo       la cara del ábside: u la distancia a lo largo de ella, v la
##               altura, w hacia el campo
## `cizalla` tuerce lo que entra en el muro (el taladro del óculo).
class Cara extends RefCounted:
	var horizontal := false
	var curvo := false
	var o := Vector3.ZERO
	var t := Vector3.RIGHT
	var nw := Vector3.BACK
	var cizalla := Vector3.ZERO
	var cs := PackedFloat32Array()
	var cp := PackedVector3Array()
	var cn := PackedVector3Array()
	var ct := PackedFloat32Array()

	func copia() -> Cara:
		var m := Cara.new()
		m.horizontal = horizontal
		m.curvo = curvo
		m.o = o
		m.t = t
		m.nw = nw
		m.cizalla = cizalla
		m.cs = cs
		m.cp = cp
		m.cn = cn
		m.ct = ct
		return m

	func largo() -> float:
		return cs[cs.size() - 1] if curvo else 0.0

	func _i(u: float) -> int:
		return clampi(cs.bsearch(u) - 1, 0, cs.size() - 2)

	func p(u: float, v: float, w: float) -> Vector3:
		if horizontal:
			return Vector3(u, w, v) + cizalla * w
		if not curvo:
			return o + t * u + Vector3.UP * v + nw * w + cizalla * w
		var i := _i(u)
		var f := clampf((u - cs[i]) / maxf(cs[i + 1] - cs[i], 1.0e-6), -2.0, 3.0)
		var base := cp[i].lerp(cp[i + 1], f)
		var nn := cn[i].lerp(cn[i + 1], clampf(f, 0.0, 1.0)).normalized()
		return base + Vector3.UP * v + nn * w + cizalla * w

	func eje_u(u: float) -> Vector3:
		if horizontal:
			return Vector3.RIGHT
		if not curvo:
			return t
		var i := _i(u)
		return (cp[i + 1] - cp[i]).normalized()

	func eje_v() -> Vector3:
		return Vector3.BACK if horizontal else Vector3.UP

	func eje_w(u: float) -> Vector3:
		if horizontal:
			return Vector3.UP
		if not curvo:
			return nw
		var i := _i(u)
		var f := clampf((u - cs[i]) / maxf(cs[i + 1] - cs[i], 1.0e-6), 0.0, 1.0)
		return cn[i].lerp(cn[i + 1], f).normalized()

	## Una dirección del plano (u, v) en el mundo.
	func dir(u: float, d: Vector2) -> Vector3:
		return (eje_u(u) * d.x + eje_v() * d.y).normalized()

	## La `u` de un ángulo del arco (0 la punta derecha, PI la izquierda).
	func s_de(theta: float) -> float:
		var k := clampi(int(round((PI - theta) / PI * float(cs.size() - 1))), 0, cs.size() - 1)
		return cs[k]

	## La `u` del punto de la cara más cercano a `q` (en planta).
	func u_cercano(q: Vector3) -> float:
		var mejor := 0
		var dmin := 1.0e9
		for k in cp.size():
			var d := Vector2(cp[k].x - q.x, cp[k].z - q.z).length_squared()
			if d < dmin:
				dmin = d
				mejor = k
		return cs[mejor]
