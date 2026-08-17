class_name Mesa
extends RefCounted

## Simulación de la mesa. Sin dependencias del motor más allá de Vector2:
## se puede ejecutar entera en headless (ver tests/prueba_sim.gd).
##
## Lienzo 400 x 1300, Y hacia abajo.

signal bumper_golpeado(punto: Vector2, fuerza: float)
signal slingshot_golpeado(punto: Vector2, fuerza: float)
signal poste_golpeado(punto: Vector2, fuerza: float)
signal flipper_golpeado(punto: Vector2, fuerza: float)
signal target_abatido(punto: Vector2, banco: int)
## La caza: se abre al salir del umbral, se cierra sola cuando se acaba el
## tiempo. `Combate` las escucha para el aviso y para no parar el reloj.
signal caza_empezada(punto: Vector2)
signal caza_terminada(punto: Vector2)
signal girador_girado(punto: Vector2, indice: int, fuerza: float)
signal banco_completado(punto: Vector2, banco: int)
## Ha caído LA ÚLTIMA bola: esto es un drenaje de verdad, con su vida y su combo.
signal bola_drenada()
## Ha caído una bola pero quedan otras en la mesa. NO es un drenaje: no cuesta
## nada. Existe para que la vista y el sonido puedan decirlo, nada más.
signal bola_perdida(restantes: int, punto: Vector2)
## Ha entrado una bola extra en juego.
signal bola_extra(punto: Vector2, total: int)
signal busqueda_bola(punto: Vector2)
signal rampa_entrada(punto: Vector2, indice: int)
signal rampa_salida(punto: Vector2, indice: int)
## La bola se ha quedado a mitad de una rampa con cuesta (`PROPÓSITO.md` §6). No
## es un castigo, es información: pasa siempre por aquí, tanto si el tubo la
## devuelve como si el carril la suelta.
signal rampa_fallada(punto: Vector2, indice: int, ratio: float)
## HA CAÍDO DE UNA CAPA A OTRA. Es el mismo evento para las dos formas de caerse
## —salirte del borde de una plataforma y desprenderte de una rampa abierta—
## porque en la mano se sienten igual.
signal bola_cayo(punto: Vector2, desde: int, hasta: int)
signal platillo_capturado(punto: Vector2, indice: int)
signal platillo_expulsado(punto: Vector2, indice: int)
## La bola acaba de quedarse atrapada en la cuna de una pala, o de salir de
## ella. Es el momento en el que el jugador puede mirar la mesa y elegir tiro.
signal atrape_cambiado(atrapada: bool)

const ANCHO := 400.0
const ALTO := 1300.0
## La zona baja (y 660..1300) es la mesa de 700 validada, bajada estos px. Todo
## lo de `_construir` se escribe con las coordenadas ORIGINALES y pasa por _v(),
## para que los números sigan siendo los del prototipo y se puedan comparar.
const DESPLAZAMIENTO := 600.0
const SEGMENTOS_ARCO := 48

## Las capas de altura, repetidas aquí para poder escribir `Mesa.CAPA_ALTA` sin
## acordarse de que viven en `Colisionador`. Son las mismas constantes.
const CAPA_TUNEL := Colisionador.CAPA_TUNEL
const CAPA_TABLERO := Colisionador.CAPA_TABLERO
const CAPA_ALTA := Colisionador.CAPA_ALTA

var p: ParametrosMesa
var rng := RandomNumberGenerator.new()

var colisionadores: Array[Colisionador] = []
## LAS CUATRO PALAS. `flipper_izq` y `flipper_der` siguen siendo LAS DE ABAJO y
## siguen llamándose igual a propósito: media batería y toda la vista las nombran
## así, y renombrarlas no habría arreglado nada. Lo que se añade es la lista, que
## es lo que recorre la física.
var flipper_izq: Flipper
var flipper_der: Flipper
## Las de la planta alta. Van con las MISMAS TECLAS que las de abajo, que es lo
## que hace una máquina real con un flipper superior: no se aprende un control
## nuevo, se aprende una mesa nueva.
var flipper_alto_izq: Flipper
var flipper_alto_der: Flipper
var flippers: Array[Flipper] = []

## LAS BOLAS QUE HAY EN LA MESA. Nunca está vacía: cuando no hay bola en juego
## queda una sola, con `viva = false`, que es exactamente el estado que había
## antes de que existiera la multibola.
##
## Las bolas que caen mientras quedan otras SE BORRAN de la lista. La última no:
## se queda ella sola y muerta, porque medio juego lee `mesa.bola.viva` para
## saber que no hay bola en juego y ese estado tiene que seguir existiendo.
var bolas: Array[Bola] = [Bola.new()]

## La bola de siempre, o sea `bolas[0]`.
##
## CON UNA SOLA BOLA ESTO ES EXACTAMENTE LO QUE ERA, y de ahí sale que la
## multibola no haya obligado a reescribir la vista, el combate ni las pruebas:
## `bolas` tiene un elemento, `bolas[0]` es esa bola, y todo lo escrito contra
## `mesa.bola` sigue diciendo lo mismo palabra por palabra.
##
## Con varias bolas en juego NO es la que hay que mirar. La cámara quiere
## `bola_en_peligro()` y el que dibuja quiere `bolas` entera. Se deja porque
## quitarla obligaría a tocar cien sitios que están bien, no porque sea la buena.
var bola: Bola:
	get:
		return bolas[0]

## Las que han caído en este subpaso, para decidir DESPUÉS de haber movido a
## todas si la que cayó era la última. Dentro del bucle no se puede saber.
var _drenadas: Array[Bola] = []

## Solo para dibujar: la polilínea del arco superior.
var arco := PackedVector2Array()
## Solo para dibujar: centros y radios de bumpers y postes.
var bumpers: Array[Vector2] = []
var postes: Array[Vector2] = []
## Targets abatibles, agrupados en bancos. `activo` dice si están en pie.
var targets: Array[Colisionador] = []
var bancos: Array[Array] = []
var _reset_banco: Array[float] = []
## Giradores: no colisionan, la bola los atraviesa y los hace girar.
var giradores: Array[Vector2] = []
## Rampas y platillos: no son colisionadores, son curvas y trampas.
var rampas: Array[Rampa] = []
## Índices de los dos recorridos de la zona alta. -1 si no están montados.
var umbral: int = -1
var regreso: int = -1
## El modo de caza está abierto, y cuánto le queda.
var en_caza := false
var caza_restante: float = 0.0
## Si la última caza acabó porque drenaste arriba (true) o porque se agotó el
## tiempo (false). Lo lee el cartel: no es lo mismo "se acabó" que "la has
## perdido", y contar las dos igual sería quitarle el mérito a aguantar.
var caza_por_drenaje := false
var platillos: Array[Platillo] = []
## Regiones elevadas. HOY ESTÁ VACÍA a propósito: el sistema entra sin tocar
## geometría, y la planta alta se rediseña encima después (`PLAN.md` §1d).
var plataformas: Array[Plataforma] = []

var carga_lanzador: float = 0.0
var cargando := false

var _contactos: Array[Contacto] = []
## La pala que tiene la bola atrapada en su cuna ahora mismo, o null. Es estado
## de la simulación, no de la vista: hace falta para poder avisar de que la bola
## está atrapada, que es LA técnica con la que se elige un tiro.
var flipper_atrapando: Flipper = null
var _atrapada_antes := false

func _init(parametros: ParametrosMesa = null) -> void:
	p = parametros if parametros != null else ParametrosMesa.new()
	rng.randomize()
	_construir()
	# Después de `_construir`, que es quien sabe cuántos giradores hay.
	_preparar_bola(bolas[0])

# ---------------------------------------------------------------- construcción

## Coordenada de la mesa validada de 700, ya bajada a su sitio.
func _v(x: float, y: float) -> Vector2:
	return Vector2(x, y + DESPLAZAMIENTO)

func _construir() -> void:
	_construir_arco()

	# Paredes laterales del campo de juego.
	_pared(_v(20, 130), _v(20, 700))     # baja hasta el drenaje: es el outlane
	_pared(_v(380, 130), _v(380, 660))   # exterior del carril lanzador

	# --- Carril lanzador ---
	# El tramo bajo se estrecha a 22 px para dejar sitio al inlane derecho.
	# La bola (18 px) sigue pasando holgada.
	_pared(_v(350, 300), _v(350, 440))
	_pared(_v(350, 440), _v(355, 458))
	_pared(_v(355, 458), _v(358, 470))
	_pared(_v(358, 470), _v(358, 700))   # ídem por la derecha
	_pared(_v(358, 660), _v(380, 660))   # suelo del carril
	# Puerta antirretorno. Inclinada a propósito: una bola que cae encima rueda
	# hacia la izquierda y entra al campo en vez de quedarse parada en la repisa.
	var puerta := _pared(_v(350, 304), _v(380, 296))
	puerta.tipo = Colisionador.Tipo.PUERTA
	puerta.una_direccion = true

	# --- ARREGLO 1: inlanes de verdad ---
	# El bug: la rampa acababa en (105,592) y el eje del flipper estaba en
	# (118,600). Quedaban 7,3 px de hueco para una bola de 9 px de radio: no
	# cabía, pero se acuñaba. La rampa ahora es la pared exterior de un carril
	# de retorno que muere en un poste de goma, y el poste solapa con la cápsula
	# del eje del flipper (11 + 8 = 19 px de radios contra 8,5 px de distancia).
	# No queda hueco: no hay dónde acuñarse. La bola sale por la boca del inlane
	# (30 px libres entre el poste y la punta del slingshot) y cae sobre el
	# flipper, que es lo que hace un inlane real.
	# La pared del carril de retorno no arranca pegada a la de fuera: el hueco
	# que deja por arriba es la BOCA DEL OUTLANE. Una bola que baja pegada a la
	# pared se cuela por ahí y se pierde; una que viene más hacia dentro cae
	# sobre la pared y baja por el retorno al flipper. Esa es la elección, y se
	# decide arriba, por dónde venga la bola. La boca es un tramo HORIZONTAL a
	# una altura fija y `ancho_outlane` solo la mueve de lado: cuando se
	# recortaba sobre la diagonal, estrechar el outlane subía además su esquina
	# y pinzaba la entrada del carril de retorno contra el slingshot.
	#
	# Los slingshots van SUBIDOS Y HACIA FUERA respecto de donde estaban. El
	# bug: la punta baja de cada banda cruzaba el arco que barre la pala, así
	# que la bola apoyada en la pala levantada tocaba el slingshot y salía
	# disparada, y con eso no se puede ni atrapar ni apuntar. Movidos 20 px el
	# izquierdo y 30 px el derecho, en perpendicular a la línea que describe la
	# bola apoyada en la pala arriba: es la dirección que aleja sin estrechar el
	# carril de retorno, que va casi paralelo a la banda.
	# Lo comprueba `_prueba_barrido_del_flipper`.
	_pared(_v(20.0 + p.ancho_outlane, 514), _v(99, 584))
	_slingshot(_v(64, 488), _v(117, 558))
	_poste(_v(102, 596))

	_pared(_v(358.0 - p.ancho_outlane, 512), _v(301, 584))
	# El derecho, además, se recorta por arriba: el carril de retorno izquierdo
	# suelta la bola en (330,1085), justo en la boca de este inlane, y la banda
	# subida le pasaba a 8 px. Recortada arriba le pasa a 14 y la punta de abajo
	# —que es la que tenía que alejarse del flipper— se queda donde estaba.
	_slingshot(_v(318, 492), _v(278, 556))
	_poste(_v(298, 596))

	# --- Bumpers, en racimo apretado ---
	_racimo_bumpers()

	# --- Bancos de targets ---
	# Pegados a las paredes pero sin sellarlas: quedan 23 px de carril por fuera
	# (la bola mide 18) para poder seguir bajando al inlane con el banco en pie.
	# Entre target y target quedan 10 px, así que por ahí no se cuela.
	#
	# La x sale de la pared + los 23 px de carril + medio canto: pared 20 -> 47,
	# pared 350 -> 323. Así el borde de fuera se queda clavado en 43 y 327 pase
	# lo que pase con `target_canto`, y el carril de detrás no se mueve nunca.
	_banco_targets(_v(20.0 + 23.0 + p.target_canto * 0.5, 320),
		_v(20.0 + 23.0 + p.target_canto * 0.5, 400), 3)
	_banco_targets(_v(350.0 - 23.0 - p.target_canto * 0.5, 320),
		_v(350.0 - 23.0 - p.target_canto * 0.5, 400), 3)

	# --- Giradores, en mitad de cada carril de retorno ---
	_girador(_v(87, 545))
	_girador(_v(300, 545))

	# --- La órbita: la única forma de llegar a la zona alta ---
	# Con gravedad 1750 y tope de 1500 px/s la bola no sube más de 643 px por su
	# cuenta, así que los 660 px de arriba solo se recorren enganchada a esta
	# curva. Es bidireccional, como las órbitas de verdad: entras por un lado y
	# sales por el otro. Su premio es SUBIR EL MULTIPLICADOR de tramo: es el
	# tiro largo, y lo que paga es que todo lo que venga después vale más. Las bocas están a y=880: un lanzamiento al 88 % o más
	# llega con velocidad de sobra para engancharse y uno más flojo no. Ahí está
	# la habilidad del tiro inicial.
	_orbita()

	# --- Carriles de retorno: tres recorridos, tres sitios de salida ---
	# La órbita te devuelve a la boca contraria, arriba del campo. Estos dos
	# bajan la bola a sitios distintos, y por eso tienen bocas distintas: hay
	# que decidir a cuál tiras.
	#
	# No son bidireccionales: se entra por su boca y punto. Una órbita se
	# recorre en los dos sentidos, un carril de retorno no.

	# Izquierda -> carril de retorno DERECHO, o sea que te deja la bola puesta
	# en la otra pala. El premio es poder encadenar: paga poco de daño porque
	# lo que da es la bola servida para el tiro siguiente.
	_carril(PackedVector2Array([
		Vector2(95, 790), Vector2(78, 690), Vector2(66, 560), Vector2(86, 430),
		Vector2(140, 340), Vector2(215, 315), Vector2(290, 360),
		Vector2(332, 470), Vector2(342, 620), Vector2(338, 780),
		Vector2(334, 940), Vector2(330, 1085),
	]), "retorno", Rampa.Premio.DANO)

	# EL CAÑÓN. El golpe gordo de un solo impacto, y el tiro que se paga caro:
	# no te deja la bola puesta, te la escupe CRUZADA Y RÁPIDA hacia la pala
	# contraria. Quien controla la caza y vuelve a tirar; quien no, la pierde.
	#
	# Dos versiones anteriores, las dos malas por el mismo motivo de fondo —
	# dónde suelta un recorrido decide qué bucle existe:
	#
	# 1. Acababa en (200,690), DENTRO del racimo. Como es el que más daño paga,
	#    el bucle se alimentaba solo: cañón -> bumpers -> rampa -> cañón. El
	#    enemigo se moría sin que las palas tocaran la bola nunca.
	# 2. Acababa en (66,1020), el inlane izquierdo. Ahí no había bucle, pero
	#    tampoco tiro: bajaba posada a la pala igual que el carril de retorno,
	#    o sea que los dos recorridos hacían lo mismo.
	#
	# Ahora sale por el centro-izquierda apuntando abajo y a la derecha, así que
	# la bola cruza el campo bajo a toda velocidad. El bucle que crea SÍ vale:
	# exige cazarla en cada vuelta.
	_carril(PackedVector2Array([
		Vector2(305, 790), Vector2(322, 690), Vector2(334, 560), Vector2(314, 430),
		Vector2(258, 342), Vector2(190, 312), Vector2(120, 350),
		Vector2(78, 440), Vector2(62, 580), Vector2(60, 750),
		Vector2(64, 860), Vector2(100, 940), Vector2(160, 985),
	]), "canon", Rampa.Premio.DANO_FUERTE, p.canon_factor_salida)

	# --- Platillo, metido bajo el arco a la izquierda ---
	# Hay que buscarlo: no está en el camino de la bola. Captura, pausa, y
	# escupe hacia el campo.
	_platillo(_v(70, 170), Vector2(0.75, 1.0))

	# --- LA ZONA ALTA: la arena de caza ---
	_arena()
	_umbral_y_regreso()

	flipper_izq = Flipper.new(
		p.flipper_eje_izq, p.flipper_longitud, p.flipper_radio, p.flipper_rebote,
		p.flipper_reposo_izq, p.flipper_activo_izq, p.flipper_velocidad_giro)
	# La derecha puede medir distinto (palas "desiguales" de la preparación). A
	# 0 —lo normal— vale la misma que la izquierda, así que ajustar
	# `flipper_longitud` sigue moviendo las dos como siempre.
	flipper_der = Flipper.new(
		p.flipper_eje_der,
		p.flipper_longitud_der if p.flipper_longitud_der > 0.0 else p.flipper_longitud,
		p.flipper_radio, p.flipper_rebote,
		p.flipper_reposo_der, p.flipper_activo_der, p.flipper_velocidad_giro)

	# LAS DE LA PLANTA ALTA. Mismo largo, mismo ángulo y misma velocidad que las
	# de abajo: la planta alta se aprende como mesa, no como control.
	flipper_alto_izq = Flipper.new(
		Vector2(p.flipper_eje_izq.x, p.arena_y_pala), p.flipper_longitud,
		p.flipper_radio, p.flipper_rebote,
		p.flipper_reposo_izq, p.flipper_activo_izq, p.flipper_velocidad_giro)
	flipper_alto_der = Flipper.new(
		Vector2(p.flipper_eje_der.x, p.arena_y_pala),
		p.flipper_longitud_der if p.flipper_longitud_der > 0.0 else p.flipper_longitud,
		p.flipper_radio, p.flipper_rebote,
		p.flipper_reposo_der, p.flipper_activo_der, p.flipper_velocidad_giro)
	flippers = [flipper_izq, flipper_der, flipper_alto_izq, flipper_alto_der]

	# El rozamiento se reparte aquí, al final y en un solo sitio: cada superficie
	# lo hereda de su tipo y así no hay que pasarlo por los treinta sitios en los
	# que se crea un colisionador.
	for c in colisionadores:
		c.friccion = p.friccion_de(c.tipo)
	for f in flippers:
		f.friccion = p.friccion_flipper

func _construir_arco() -> void:
	# Elipse centro (200,130), rx 180, ry 70. De (380,130) a (20,130) por arriba.
	arco.clear()
	for i in SEGMENTOS_ARCO + 1:
		var t := PI * float(i) / float(SEGMENTOS_ARCO)
		arco.append(_v(200.0 + 180.0 * cos(t), 130.0 - 70.0 * sin(t)))
	for i in SEGMENTOS_ARCO:
		_pared(arco[i], arco[i + 1])

func _pared(a: Vector2, b: Vector2) -> Colisionador:
	var c := Colisionador.new(a, b, 0.0, Colisionador.Tipo.PARED, p.rebote_pared)
	colisionadores.append(c)
	return c

func _slingshot(a: Vector2, b: Vector2) -> Colisionador:
	var c := Colisionador.new(a, b, 0.0, Colisionador.Tipo.SLINGSHOT,
		p.slingshot_rebote, p.slingshot_empuje, p.slingshot_velocidad_minima)
	# La goma mira al campo, y el campo es hacia el centro de la mesa. De las
	# dos perpendiculares se coge la que apunta hacia allí; por la espalda, que
	# es la que da a la banda del outlane, rebota pero no patea.
	var d := (b - a).normalized()
	var perp := Vector2(-d.y, d.x)
	if signf(perp.x) != signf(ANCHO * 0.5 - (a + b).x * 0.5):
		perp = -perp
	c.cara = perp
	colisionadores.append(c)
	return c

func _bumper(centro: Vector2) -> Colisionador:
	var c := Colisionador.new(centro, centro, p.bumper_radio, Colisionador.Tipo.BUMPER,
		p.bumper_rebote, p.bumper_empuje, p.bumper_velocidad_minima)
	colisionadores.append(c)
	bumpers.append(centro)
	return c

## Triángulo equilátero con `bumper_hueco` px entre bordes. El lado sale del
## hueco, así que tocar el parámetro reordena el racimo entero sin recolocar
## nada a mano.
##
## DOS EN LA CARA POR LA QUE ENTRA LA BOLA, y aquí está medido pero se midió mal
## una vez: la regla no es "dos arriba", es **dos en la cara de entrada**. La
## bola tiene que colarse entre dos y rebotar contra el tercero; si el tercero es
## el primero que se encuentra, se la devuelve de un manotazo y se acabó.
##
## En esta mesa el racimo está en lo más alto que se alcanza, así que la bola
## entra SUBIENDO y la cara de entrada es la de abajo. `bumper_giro` lo cuenta
## entero, con la tabla.
func _racimo_bumpers() -> void:
	_racimo(p.bumper_centro)

## Cada target es una PLANCHA, no un bolo: una cápsula tumbada a lo largo de la
## línea del banco (o sea, paralela a la pared), de `target_ancho` de cara y
## `target_canto` de fondo. Con un círculo, la bola que pasaba rozando se iba
## rebotada por el hombro redondo; con la cara plana o le das o no le das.
func _banco_targets(desde: Vector2, hasta: Vector2, cantidad: int) -> void:
	var indice := bancos.size()
	var banco: Array[Colisionador] = []
	var canto := p.target_canto * 0.5
	# El segmento es la cara menos los dos casquetes, para que la cápsula entera
	# mida `target_ancho`.
	var media_cara := maxf(p.target_ancho * 0.5 - canto, 0.0)
	var eje := (hasta - desde).normalized() * media_cara
	for i in cantidad:
		var t := float(i) / float(cantidad - 1) if cantidad > 1 else 0.0
		var centro := desde.lerp(hasta, t)
		var c := Colisionador.new(centro - eje, centro + eje, canto,
			Colisionador.Tipo.TARGET, p.target_rebote, 0.0, p.target_velocidad_minima)
		c.banco = indice
		colisionadores.append(c)
		targets.append(c)
		banco.append(c)
	bancos.append(banco)
	_reset_banco.append(0.0)

func _orbita() -> void:
	# En absoluto: la órbita cruza la mesa entera, no es de la zona baja.
	# LA BOCA IZQUIERDA NO PUEDE ESTAR PEGADA A LA PARED. Estuvo en (44,880), y
	# como la curva llega ahí bajando casi vertical, la bola salía a 650 px/s
	# rozando la banda, daba tres rebotes cortos y se iba por el outlane
	# izquierdo. Un lanzamiento a tope engancha la órbita SIEMPRE, así que eso
	# era la apertura de todas las bolas: tirar y perderla sin jugar.
	#
	# Ahora la curva baja más y se mete hacia dentro, así que la bola sale
	# apuntando abajo y a la derecha y aterriza sobre la pala izquierda. La boca
	# DERECHA se queda donde estaba: es por donde engancha el lanzamiento, y el
	# carril lanzador sube por x=369, o sea que moverla rompería la apertura.
	var control := PackedVector2Array([
		Vector2(80, 935),                                    # boca izquierda
		Vector2(52, 850), Vector2(38, 740), Vector2(40, 560), Vector2(70, 400),
		Vector2(130, 305), Vector2(200, 275), Vector2(270, 305),
		Vector2(330, 400), Vector2(360, 560), Vector2(362, 740),
		Vector2(356, 880),                                   # boca derecha
	])
	var r := Rampa.new(control)
	r.entrada_radio = p.rampa_entrada_radio
	r.velocidad_minima = p.rampa_velocidad_minima
	r.nombre = "orbita"
	r.premio = Rampa.Premio.MULTIPLICADOR
	rampas.append(r)

## Carril de retorno: como la órbita pero de un solo sentido.
func _carril(control: PackedVector2Array, nombre: String, premio: int,
		factor_salida: float = 1.0) -> void:
	var r := Rampa.new(control)
	r.entrada_radio = p.rampa_entrada_radio
	r.velocidad_minima = p.rampa_velocidad_minima
	r.bidireccional = false
	r.nombre = nombre
	r.premio = premio
	r.factor_salida = factor_salida
	rampas.append(r)

func _platillo(centro: Vector2, direccion: Vector2) -> void:
	platillos.append(Platillo.new(centro, direccion, p.platillo_radio,
		p.platillo_tiempo, p.platillo_impulso))

func _girador(centro: Vector2) -> void:
	giradores.append(centro)

# --------------------------------------------------------- la zona alta

## LA PLANTA ALTA. `DISEÑO.md` §5 y §7: un tiro difícil abre el umbral, subes,
## juegas arriba un tiempo limitado con el reloj del enemigo corriendo, y bajas.
##
## Y ES UNA MESA, NO UN CAMPO DE PINES. La primera versión era una rejilla al
## tresbolillo, y Daniel la tumbó jugándola con una frase que es el diagnóstico
## entero: *"el pachinko es literalmente que caiga la bola, y que luego no pase
## de la primera línea"*. Tenía razón y se ve en la física: una rejilla es un
## comedor de energía pasivo —la primera fila se lleva la velocidad y el resto es
## caída—, así que no hay tiro, hay embudo. **Lo que hace que una zona de pinball
## se juegue son palas**, y aquí arriba hay dos.
##
## Es un PISO APARTE, no la misma mesa estirada, y eso sigue siendo aritmética:
## la bola sube 643 px por sus medios (desde las palas de abajo, hasta y=557) y
## una caída libre desde aquí llega abajo a 1500 px/s, o sea 67 ms, cuando el
## cañón ya se tuvo que ablandar porque 900 px/s era incazable.
func _arena() -> void:
	var cx := ANCHO * 0.5
	var rx := cx - 20.0
	var yp := p.arena_y_pala

	# El techo, teselado igual que el arco de abajo para que las dos plantas se
	# lean como la misma mesa.
	for i in SEGMENTOS_ARCO:
		var t0 := PI * float(i) / float(SEGMENTOS_ARCO)
		var t1 := PI * float(i + 1) / float(SEGMENTOS_ARCO)
		_pared(
			Vector2(cx + rx * cos(t0), p.arena_hombro_y - p.arena_techo_ry * sin(t0)),
			Vector2(cx + rx * cos(t1), p.arena_hombro_y - p.arena_techo_ry * sin(t1)))

	# Las bandas, y bajan POR DEBAJO de las palas: ese tramo es la pared de fuera
	# del outlane, igual que abajo. Cortarlas a la altura de las palas dejaría a
	# la bola salirse de lado por el hueco.
	_pared(Vector2(20.0, p.arena_hombro_y), Vector2(20.0, yp + 30.0))
	_pared(Vector2(ANCHO - 20.0, p.arena_hombro_y), Vector2(ANCHO - 20.0, yp + 30.0))

	# --- La zona de palas, calcada de la de abajo y por buenas razones ---
	# La de abajo costó tres sesiones de averías —la bola acuñada en el inlane,
	# el slingshot que pateaba por la espalda, el outlane que tragaba demasiado—
	# y todas están resueltas en esas seis líneas. Copiarlas es heredar los
	# arreglos; inventarse otra zona de palas es volver a comprarlos.
	_pared(Vector2(20.0 + p.ancho_outlane, yp - 86.0), Vector2(99.0, yp - 16.0))
	_slingshot(Vector2(64.0, yp - 112.0), Vector2(117.0, yp - 42.0))
	_poste(Vector2(102.0, yp - 4.0))
	_pared(Vector2(ANCHO - 20.0 - p.ancho_outlane, yp - 88.0), Vector2(301.0, yp - 16.0))
	_slingshot(Vector2(318.0, yp - 108.0), Vector2(278.0, yp - 44.0))
	_poste(Vector2(298.0, yp - 4.0))

	# --- Un racimo propio, arriba del todo ---
	# Dos bumpers en la cara de entrada, que aquí también es la de abajo: a la
	# planta alta se sube igual que a la de abajo, tirando desde una pala.
	_racimo(p.arena_bumper_centro)

	# --- Dos bancos de targets, y NO pegados a las bandas ---
	# Abajo van pegados porque por fuera queda un carril de 23 px. Aquí por fuera
	# va la ÓRBITA, y una boca de recorrido a 20 px de un target se traga la bola
	# que acaba de rebotar en él. Metidos hacia dentro, el carril de la órbita
	# queda limpio y los bancos se leen como lo que son: un tiro del centro.
	_banco_targets(Vector2(100.0, p.arena_y_targets),
		Vector2(100.0, p.arena_y_targets + 80.0), 3)
	_banco_targets(Vector2(ANCHO - 100.0, p.arena_y_targets),
		Vector2(ANCHO - 100.0, p.arena_y_targets + 80.0), 3)

	# --- Un girador en cada carril de retorno ---
	_girador(Vector2(87.0, yp - 55.0))
	_girador(Vector2(ANCHO - 100.0, yp - 55.0))

	# --- Y la órbita corta: el tiro largo de la planta ---
	# Va por fuera de los bancos, pegada a las bandas, y da la vuelta por encima
	# del racimo. Es lo que hace que aquí arriba se APUNTE en vez de aguantar:
	# sin un tiro largo, una mesa pequeña es un pasillo con palas. Bidireccional,
	# como la de abajo: entras por un lado y sales por el otro.
	var o := Rampa.new(PackedVector2Array([
		Vector2(42.0, yp - 120.0),
		Vector2(34.0, 400.0), Vector2(36.0, 320.0), Vector2(60.0, 262.0),
		Vector2(120.0, 226.0), Vector2(200.0, 216.0), Vector2(280.0, 226.0),
		Vector2(340.0, 262.0), Vector2(364.0, 320.0), Vector2(366.0, 400.0),
		Vector2(358.0, yp - 120.0),
	]))
	o.entrada_radio = p.rampa_entrada_radio
	o.velocidad_minima = p.arena_orbita_velocidad_minima
	o.nombre = "orbita_alta"
	o.premio = Rampa.Premio.MULTIPLICADOR
	rampas.append(o)

	# --- El suelo: un embudo que lleva al desagüe ---
	# No es una pared que pare la bola, es por donde se va. Drenar en la planta
	# alta no cuesta vida: cuesta la caza, que es exactamente el castigo que
	# tiene que tener.
	_pared(Vector2(20.0, yp + 30.0), Vector2(cx - 40.0, p.arena_fondo_y))
	_pared(Vector2(ANCHO - 20.0, yp + 30.0), Vector2(cx + 40.0, p.arena_fondo_y))

## EL ANDAMIO DE CAPAS. No es geometría de la mesa y no se monta al empezar: lo
## pide F1+F3 desde la vista, y lo que monta va en la PLANTA ALTA, que es la que
## está rechazada y se tira entera en `PLAN.md` §1d.
##
## Por qué existe. El sistema de capas entró apagado —esa era la mitad del
## trabajo, porque encenderlo sin comprobarlo mueve el balance medido sin
## avisar—, y eso deja el juego exactamente igual que el día anterior. Un
## sistema que no se puede tocar no se puede juzgar: sin esto, la única forma
## de saber si una plataforma se lee como alta es creerse una tabla, y aquí las
## tablas verdes ya han tapado dos averías que se cazaron jugando.
##
## Monta las cuatro cosas de golpe y encadenadas, que es como se juzgan:
## un carril con cuesta que SUBE a una plataforma —si no le pegas fuerte, te
## suelta a mitad—, la plataforma con su borde —te sales y te caes—, y un túnel
## que cruza por debajo del tablero.
##
## Se puede llamar dos veces sin que se apile: si ya está, no hace nada.
func montar_andamio_de_capas() -> void:
	if not plataformas.is_empty():
		return

	# La losa, en el hueco que queda entre los dos bancos de targets y por
	# debajo del racimo.
	plataformas.append(Plataforma.new(Rect2(140.0, 396.0, 120.0, 84.0), CAPA_ALTA))

	# El carril que sube a ella desde la pala izquierda. ABIERTO a propósito:
	# es lo que hace que fallar sea caerse y no que te devuelvan.
	var subida := Rampa.new(PackedVector2Array([
		Vector2(78.0, 528.0), Vector2(110.0, 470.0), Vector2(168.0, 430.0)]))
	subida.entrada_radio = p.rampa_entrada_radio
	subida.velocidad_minima = 260.0
	subida.bidireccional = false
	subida.velocidad_escape = 700.0
	subida.abierta = true
	subida.capa_salida = CAPA_ALTA
	subida.nombre = "andamio_subida"
	rampas.append(subida)

	# Y el túnel, del lado derecho al centro. Las dos bocas en el tablero: baja,
	# cruza por debajo y vuelve a salir.
	var tunel := Rampa.new(PackedVector2Array([
		Vector2(330.0, 500.0), Vector2(300.0, 410.0), Vector2(268.0, 352.0)]))
	tunel.entrada_radio = p.rampa_entrada_radio
	tunel.velocidad_minima = 260.0
	tunel.bidireccional = false
	tunel.subterranea = true
	tunel.nombre = "andamio_tunel"
	rampas.append(tunel)

## El mismo triángulo del racimo de abajo, en el sitio que se le diga. Se saca a
## función porque ahora hay dos, y porque `bumper_giro` —que es la corrección de
## la cara de entrada— tiene que valer para los dos igual.
func _racimo(centro: Vector2) -> void:
	var lado := p.bumper_hueco + p.bumper_radio * 2.0
	var radio_racimo := lado / sqrt(3.0)
	for i in 3:
		var ang := PI * 0.5 + deg_to_rad(p.bumper_giro) + float(i) * TAU / 3.0
		_bumper(centro + Vector2(cos(ang), sin(ang)) * radio_racimo)

## EL UMBRAL Y EL REGRESO, y son las dos mitades de la misma idea: a la planta
## alta no se llega ni se sale por gravedad.
func _umbral_y_regreso() -> void:
	# EL UMBRAL. Boca pegada a la banda derecha, que es el único sitio por el que
	# la bola sube de verdad: el bumper de abajo a la derecha del racimo la
	# escupe hacia allí. El porqué entero, con la tabla por bandas, está en
	# `umbral_boca`.
	#
	# Y SUBE POR FUERA DE LA BANDA, por la franja de 20 px que quedaba muerta
	# entre la pared y el borde de la mesa. Son 20 px para una bola de 18: es un
	# carril exacto, y es lo que hace una máquina de verdad — el habitrail va por
	# el borde, no cruzando el campo. Cruzando por dentro, la curva se dibujaba
	# encima del racimo y de los targets y no se entendía nada.
	umbral = rampas.size()
	var r := Rampa.new(PackedVector2Array([
		p.umbral_boca,
		Vector2(376, 706), Vector2(390, 660), Vector2(391, 560),
		Vector2(391, 440), Vector2(390, 330), Vector2(378, 258),
		Vector2(344, 218), Vector2(295, 228),
	]))
	r.entrada_radio = p.umbral_entrada_radio
	r.velocidad_minima = p.umbral_velocidad_minima
	r.bidireccional = false
	r.nombre = "umbral"
	r.premio = Rampa.Premio.CAZA
	r.factor_salida = p.umbral_factor_salida
	rampas.append(r)

	# EL REGRESO, y NO TIENE BOCA a propósito: `velocidad_minima` imposible, así
	# que `sentido_entrada` no lo coge nunca. No se entra en él, te mete la
	# planta alta cuando drenas ahí arriba o cuando se acaba el tiempo. Baja por
	# la franja izquierda y devuelve la bola posada en el inlane.
	regreso = rampas.size()
	var g := Rampa.new(PackedVector2Array([
		Vector2(ANCHO * 0.5, p.arena_fondo_y - 24.0),
		Vector2(120, 640), Vector2(40, 672), Vector2(11, 730),
		Vector2(9, 840), Vector2(9, 940), Vector2(12, 990),
		Vector2(30, 1024), Vector2(58, 1034),
	]))
	g.entrada_radio = p.rampa_entrada_radio
	g.velocidad_minima = INF
	g.bidireccional = false
	g.nombre = "regreso"
	g.premio = Rampa.Premio.DANO
	g.factor_salida = p.regreso_factor_salida
	rampas.append(g)

## Se abre al SALIR del umbral, no al entrar: el viaje por la curva no se le come
## al jugador el tiempo que ha ganado.
func _empezar_caza(punto: Vector2) -> void:
	if en_caza:
		return
	en_caza = true
	caza_restante = p.caza_tiempo
	caza_empezada.emit(punto)

## LA CAZA SE ACABA DE DOS MANERAS, y esa es la diferencia entre una mesa y un
## paseo: **drenando ahí arriba** —o sea, jugando mal— o **agotando el tiempo**.
## Con la versión de pines solo existía la segunda, y por eso daba igual lo que
## hicieras: la rejilla te devolvía abajo pasaras lo que pasaras. Ahora aguantar
## la bola en la planta alta es la habilidad que se premia, igual que abajo.
func _terminar_caza(por_drenaje: bool = false) -> void:
	if not en_caza:
		return
	en_caza = false
	caza_restante = 0.0
	caza_por_drenaje = por_drenaje
	var punto := Vector2(ANCHO * 0.5, p.arena_fondo_y)
	for b in bolas:
		if b.viva and b.libre() and en_la_arena(b):
			punto = b.pos
			_meter_en_regreso(b)
	caza_terminada.emit(punto)

func _meter_en_regreso(b: Bola) -> void:
	if regreso < 0:
		return
	var r := rampas[regreso]
	b.rampa = regreso
	b.rampa_sentido = 1
	# Velocidad FIJA, no la que traía: una caza que acaba con la bola posada
	# tardaría siglos en bajar los 400 px del carril.
	b.rampa_velocidad = p.regreso_velocidad
	b.rampa_distancia = 0.0
	b.pos = r.punto_en(0.0)
	b.vel = Vector2.ZERO
	rampa_entrada.emit(b.pos, regreso)

## Una bola está arriba si está por encima del arco de la mesa de abajo. Es la
## frontera de verdad: entre el fondo del embudo y el arco no hay nada, así que
## cualquier bola libre por encima de ahí solo puede estar en la planta alta.
func en_la_arena(b: Bola) -> bool:
	return b.pos.y < p.arena_fondo_y + 6.0

func _avanzar_caza(h: float) -> void:
	if not en_caza:
		return
	# EL DRENAJE DE ARRIBA VA ANTES QUE EL RELOJ. Es una línea, no una boca:
	# una boca se puede esquivar cayendo por su lado y entonces la bola se queda
	# en el hueco entre las dos plantas, que es un sitio del que no se sale.
	for b in bolas:
		if b.viva and b.libre() and b.pos.y > p.arena_drenaje_y \
				and b.pos.y < p.arena_fondo_y + 40.0:
			_terminar_caza(true)
			return
	caza_restante -= h
	if caza_restante <= 0.0:
		_terminar_caza(false)

## Cuánto aire queda entre un círculo puesto en `centro` y lo más cercano que ya
## haya en la mesa. Negativo si se solapan. Lo usan las pruebas de la planta alta
## para comprobar que no hay rincones donde acuñar la bola.
func hueco_libre(centro: Vector2, radio: float) -> float:
	var menor := INF
	for c in colisionadores:
		menor = minf(menor,
			centro.distance_to(c.punto_mas_cercano(centro)) - c.radio - radio)
	return menor

## Los giradores no colisionan: la bola los atraviesa. Se disparan al ENTRAR,
## una vez por pasada, así que mientras la bola siga dentro no vuelven a avisar.
## El "estoy dentro" es POR BOLA (`Bola.girador_dentro`): con un registro por
## mesa, la segunda bola que cruza el mismo girador se lo encontraría marcado y
## no cobraría.
func _avanzar_giradores(b: Bola) -> void:
	for i in giradores.size():
		var dentro := b.viva \
			and b.pos.distance_to(giradores[i]) < p.girador_radio
		if dentro and not b.girador_dentro[i] \
				and b.velocidad() >= p.girador_velocidad_minima:
			girador_girado.emit(giradores[i], i, b.velocidad())
		b.girador_dentro[i] = dentro

## Vuelve a poner todos los targets en pie. Para empezar un combate nuevo.
func reiniciar_targets() -> void:
	for c in targets:
		c.activo = true
	for i in _reset_banco.size():
		_reset_banco[i] = 0.0

func centro_banco(indice: int) -> Vector2:
	var suma := Vector2.ZERO
	for c in bancos[indice]:
		suma += c.centro()
	return suma / float(bancos[indice].size())

func _abatir(c: Colisionador) -> void:
	c.activo = false
	target_abatido.emit(c.centro(), c.banco)
	for otro in bancos[c.banco]:
		if otro.activo:
			return
	_reset_banco[c.banco] = p.target_tiempo_reset
	banco_completado.emit(centro_banco(c.banco), c.banco)

func _avanzar_bancos(h: float) -> void:
	for i in _reset_banco.size():
		if _reset_banco[i] <= 0.0:
			continue
		_reset_banco[i] -= h
		if _reset_banco[i] <= 0.0:
			for c in bancos[i]:
				c.activo = true

func _poste(centro: Vector2) -> Colisionador:
	var c := Colisionador.new(centro, centro, p.poste_radio, Colisionador.Tipo.POSTE,
		p.poste_rebote, p.poste_empuje, p.poste_velocidad_minima)
	colisionadores.append(c)
	postes.append(centro)
	return c

# ------------------------------------------------------------------- bola/juego

## Deja una bola lista para usarse: sin rampa, sin platillo, sin temporizadores y
## con un hueco de girador por cada girador de la mesa.
func _preparar_bola(b: Bola) -> void:
	b.vel = Vector2.ZERO
	b.capa = CAPA_TABLERO
	b.rampa = -1
	b.platillo = -1
	b.platillo_espera = 0.0
	b.busqueda = 0.0
	b.tocando_flipper = false
	b.girador_dentro.clear()
	for _i in giradores.size():
		b.girador_dentro.append(false)

## Empieza una bola: se queda UNA en la mesa, en el carril, y las extra que
## hubiera desaparecen. Reutiliza el objeto de `bolas[0]` a propósito, porque hay
## quien se guarda la referencia (la vista, para dibujarla) entre bola y bola.
func nueva_bola() -> void:
	var b := bolas[0]
	bolas.clear()
	bolas.append(b)
	_preparar_bola(b)
	b.pos = p.inicio_bola
	b.viva = true
	b.en_carril = true
	carga_lanzador = 0.0
	cargando = false
	_drenadas.clear()

## Mete una bola más en juego, y devuelve null si ya se ha llegado al tope.
##
## ENTRA POR EL CARRIL LANZADOR Y SALE DISPARADA A TOPE. No aparece en mitad del
## campo, que es lo barato y lo que se ve regalado: un lanzamiento a tope engancha
## la órbita siempre, así que la bola extra entra en juego por arriba, dando la
## vuelta, igual que la bola con la que empiezas. Es la única entrada que la mesa
## ya tiene, y así la multibola no pide geometría nueva.
##
## Si ya hay alguien esperando en el carril, la nueva se pone por delante: dos
## bolas en el mismo punto se empujarían con toda la fuerza de la separación.
func soltar_bola_extra() -> Bola:
	if bolas.size() >= p.bolas_maximas:
		return null
	var en_carril := 0
	for otra in bolas:
		if otra.viva and otra.en_carril:
			en_carril += 1
	var b := Bola.new()
	_preparar_bola(b)
	b.pos = p.inicio_bola - Vector2(0.0, p.radio_bola * 2.4 * float(en_carril))
	b.vel = Vector2(0.0, -p.impulso_lanzador)
	b.viva = true
	b.en_carril = true
	bolas.append(b)
	bola_extra.emit(b.pos, bolas.size())
	return b

## Retira todas las bolas SIN que cuente como drenaje. Es lo que pasa al ganar y
## al perder: el combate ha terminado y no tiene sentido que las bolas sigan
## rodando y sumando golpes contra un enemigo muerto.
func retirar_bolas() -> void:
	var b := bolas[0]
	bolas.clear()
	bolas.append(b)
	b.viva = false
	b.vel = Vector2.ZERO
	_drenadas.clear()

## ¿Hay alguna bola jugándose, o sea viva y fuera del carril lanzador? Es lo que
## arranca el reloj del combate, y con multibola no puede preguntarse por
## `mesa.bola`: una bola extra ya lanzada mientras la principal sigue esperando
## en el carril es una bola en juego, y el reloj tiene que correr.
func hay_bola_en_juego() -> bool:
	for b in bolas:
		if b.viva and not b.en_carril:
			return true
	return false

func bolas_vivas() -> int:
	var n := 0
	for b in bolas:
		if b.viva:
			n += 1
	return n

## La bola que mira la cámara: LA MÁS BAJA de las vivas, o sea la que está más
## cerca del drenaje. Decisión de Daniel, y es la que no toca las cuatro reglas
## de la cámara ni el escalado entero del pixelart: se le sigue pasando UNA bola.
##
## Tiene un efecto secundario que es la mitad del motivo de elegirla: con dos
## bolas en juego casi siempre hay una abajo, así que la cámara vive anclada en
## la banda de las palas, que es donde se juega una multibola.
func bola_en_peligro() -> Bola:
	var elegida: Bola = bolas[0]
	var encontrada := false
	for b in bolas:
		if not b.viva:
			continue
		if not encontrada or b.pos.y > elegida.pos.y:
			elegida = b
			encontrada = true
	return elegida

## La bola que está esperando en el carril lanzador, o null. Con varias, la de
## más abajo: es la que tiene el muelle detrás.
func _bola_en_carril() -> Bola:
	var elegida: Bola = null
	for b in bolas:
		if not (b.viva and b.en_carril):
			continue
		if elegida == null or b.pos.y > elegida.pos.y:
			elegida = b
	return elegida

func cargar_lanzador(dt: float) -> void:
	if _bola_en_carril() == null:
		return
	cargando = true
	carga_lanzador = minf(carga_lanzador + dt / p.tiempo_carga_lanzador, 1.0)

func soltar_lanzador() -> void:
	if not cargando:
		return
	cargando = false
	var b := _bola_en_carril()
	if b != null:
		var ratio := p.ratio_minimo_lanzador + (1.0 - p.ratio_minimo_lanzador) * carga_lanzador
		b.vel.y -= p.impulso_lanzador * ratio
	carga_lanzador = 0.0

# ---------------------------------------------------------------------- avance

func avanzar(dt: float) -> void:
	var h := dt / float(p.subpasos)
	for _i in p.subpasos:
		_subpaso(h)

func _subpaso(h: float) -> void:
	for f in flippers:
		f.avanzar(h)
	_avanzar_bancos(h)
	# EL ATRAPE ES DE LA MESA, NO DE UNA BOLA: se reinicia una vez por subpaso y
	# lo enciende cualquier bola que esté posada en una cuna. Antes se reiniciaba
	# dentro de `_colisionar`, y ahí con varias bolas mandaría la última de la
	# lista: una bola volando por arriba le apagaría el aviso a la que está
	# atrapada en la pala.
	flipper_atrapando = null
	for b in bolas:
		if b.viva:
			_avanzar_bola(b, h)
	_colisionar_bolas()
	_avanzar_caza(h)
	if (flipper_atrapando != null) != _atrapada_antes:
		_atrapada_antes = flipper_atrapando != null
		atrape_cambiado.emit(_atrapada_antes)
	_recoger_drenadas()

func _avanzar_bola(b: Bola, h: float) -> void:
	# Se apaga aquí y no en `_colisionar`, que no llega a correr cuando la bola va
	# por una rampa: si no, una bola se quedaría con el "apoyada en la pala" del
	# subpaso anterior y el ball search no la despertaría nunca.
	b.tocando_flipper = false

	# Enganchada a una curva o capturada en un platillo: aquí no hay física.
	if b.rampa >= 0:
		_avanzar_rampa(b, h)
		return
	if b.platillo >= 0:
		_avanzar_platillo(b, h)
		return

	b.vel.y += p.gravedad * h
	b.vel *= exp(-p.rozamiento * h)
	_limitar_velocidad(b)
	b.pos += b.vel * h

	_colisionar(b, h)
	_avanzar_giradores(b)
	_comprobar_plataformas(b)
	_comprobar_rampas(b)
	_comprobar_platillos(b)
	_actualizar_estado(b)
	_ball_search(b, h)

## Choque entre bolas. Sin esto la multibola son dos bolas que se atraviesan, y
## con sprites de 18 px encima eso se ve roto a la primera.
##
## SOLO CHOCAN LAS BOLAS LIBRES, y no es pereza: una bola enganchada a una rampa
## o dormida en el platillo está en otro plano —las rampas son elevadas—, así que
## atravesarla es lo correcto. Es la misma razón por la que una rampa no
## colisiona con nada.
##
## Masas iguales, así que el reparto es mitad y mitad y no hace falta llevar masa
## por bola. El rebote no es 1: dos bolas encerradas en el racimo con rebote
## perfecto no se calman nunca.
func _colisionar_bolas() -> void:
	if bolas.size() < 2:
		return
	var diametro := p.radio_bola * 2.0
	for i in bolas.size() - 1:
		var a := bolas[i]
		if not (a.viva and a.libre()):
			continue
		for j in range(i + 1, bolas.size()):
			var b := bolas[j]
			if not (b.viva and b.libre()):
				continue
			var delta := b.pos - a.pos
			var dist := delta.length()
			if dist >= diametro:
				continue
			# Dos bolas exactamente encima la una de la otra no tienen normal. Se
			# separan en horizontal: en una mesa vertical es la única dirección
			# que no vuelve a meter una dentro de la otra en cuanto caigan.
			var n := (delta / dist) if dist > 1e-4 else Vector2.RIGHT
			var correccion := (diametro - dist) * 0.5
			a.pos -= n * correccion
			b.pos += n * correccion
			var vn := (b.vel - a.vel).dot(n)
			if vn >= 0.0:
				continue        # ya se separan
			var impulso := -(1.0 + p.rebote_bola) * vn * 0.5
			a.vel -= n * impulso
			b.vel += n * impulso
			_limitar_velocidad(a)
			_limitar_velocidad(b)

## Qué significa lo que ha caído en este subpaso.
##
## LA REGLA: mientras quede una bola en la mesa NO PASA NADA — ni vida, ni combo,
## ni contraataque. Solo cuenta la última. Por eso esto no puede vivir dentro del
## bucle de bolas: hasta que no se han movido todas no se sabe si la que acaba de
## caer era la última.
func _recoger_drenadas() -> void:
	if _drenadas.is_empty():
		return
	var ultima: Bola = null
	if bolas_vivas() == 0:
		# Si caen dos en el mismo subpaso, la que manda es la de después: solo se
		# avisa de UN drenaje, porque solo hay un turno que cerrar.
		ultima = _drenadas[_drenadas.size() - 1]
	for b in _drenadas:
		if b == ultima:
			continue
		bolas.erase(b)
		bola_perdida.emit(bolas.size(), b.pos)
	_drenadas.clear()
	if ultima == null:
		return
	bolas.clear()
	bolas.append(ultima)
	bola_drenada.emit()

# ------------------------------------------------------------ rampas

## La bola recorre la curva a la velocidad con la que entró, constante. Es a
## propósito: determinista, sabes cuánto tarda y no hay forma de que se atasque
## a mitad de rampa.
func _avanzar_rampa(b: Bola, h: float) -> void:
	var r := rampas[b.rampa]
	# La velocidad se CALCULA desde la distancia, no se acumula. Con la rampa
	# llana (`velocidad_escape` a 0) devuelve la de entrada tal cual y esto es
	# palabra por palabra lo de antes; con cuesta, no hay deriva de integración,
	# así que subir y volver a bajar devuelve exactamente la velocidad de
	# entrada en vez de un número parecido.
	var v := r.velocidad_en(b.rampa_velocidad,
		r.recorrido(b.rampa_distancia, b.rampa_subida))
	# ¿Se ha quedado sin cuesta? Solo cuenta subiendo: bajando la velocidad crece.
	if r.velocidad_escape > 0.0 and b.rampa_sentido == b.rampa_subida \
			and v <= Rampa.VELOCIDAD_ESTANCADA:
		_estancar(b, r)
		return
	b.rampa_distancia += v * float(b.rampa_sentido) * h
	if b.rampa_distancia > 0.0 and b.rampa_distancia < r.largo:
		b.pos = r.punto_en(b.rampa_distancia)
		return
	# Salida: vuelve a la física con la velocidad tangente.
	var d := clampf(b.rampa_distancia, 0.0, r.largo)
	var indice := b.rampa
	var v_salida := r.velocidad_en(b.rampa_velocidad,
		r.recorrido(d, b.rampa_subida))
	b.pos = r.punto_en(d)
	b.vel = r.tangente_en(d) * float(b.rampa_sentido) \
		* v_salida * r.factor_salida
	# La capa a la que sale es la de la boca por la que sale, que con las dos
	# bocas en el tablero —toda rampa de hoy— no cambia nada.
	b.capa = r.capa_salida if b.rampa_sentido > 0 else r.capa_entrada
	b.rampa = -1
	rampa_salida.emit(b.pos, indice)
	if indice == umbral:
		_empezar_caza(b.pos)

## La bola se ha quedado sin cuesta a mitad de rampa. Las dos salidas son las de
## `PROPÓSITO.md` §6 y es una propiedad POR RAMPA, no una decisión global:
##
##   - **tubo** (`abierta` false): la curva la baja sola. Vuelve por donde
##     entró, y por el modelo de energía llega abajo con la velocidad exacta con
##     la que entró — cayéndote a la pala, que es lo que se busca.
##   - **carril** (`abierta` true): se DESPRENDE. Cae al tablero desde donde se
##     quedó, y de ahí en adelante es una bola normal en caída libre.
func _estancar(b: Bola, r: Rampa) -> void:
	var indice := b.rampa
	var ratio := b.rampa_velocidad / maxf(r.velocidad_escape, 1.0)
	rampa_fallada.emit(b.pos, indice, ratio)
	if not r.abierta:
		b.rampa_sentido = -b.rampa_subida
		return
	b.pos = r.punto_en(b.rampa_distancia)
	# Sin velocidad: se ha parado de verdad. Lo que la baja es la gravedad, y
	# ESO es lo que se siente como caerse en vez de como volver.
	b.vel = Vector2.ZERO
	b.rampa = -1
	# `desde` es la capa a la que IBA, no en la que estaba: mientras recorre la
	# curva la bola está en el aire, y lo que cuenta la caída es de qué altura
	# se ha desprendido. Con las dos bocas en el tablero sale 0→0, que se lee
	# raro y es verdad: se ha soltado y ha caído al tablero.
	_caer(b, r.capa_entrada, r.capa_salida)

## Bajar una capa. El único sitio que lo hace, y por eso el único que avisa.
##
## AVISA SIEMPRE, aunque la capa de salida sea la misma. Caerse de una rampa
## abierta que empieza y acaba en el tablero no cambia ningún número y sí es un
## evento: es el que tiene que sonar, sacudir la cámara y contar para la barra
## de carga. Un aviso que se calla cuando "no ha cambiado nada" es la avería del
## platillo otra vez —un sistema que el jugador no ve no existe.
func _caer(b: Bola, hasta: int, desde: int = -99) -> void:
	var de := desde if desde != -99 else b.capa
	b.capa = hasta
	bola_cayo.emit(b.pos, de, hasta)

## ¿Se ha salido del borde de la plataforma en la que estaba?
##
## SI NO HAY NINGUNA PLATAFORMA EN SU CAPA, NO PASA NADA. Es lo que impide que
## una bola subida a la capa alta de una mesa sin plataformas —la de hoy— se
## caiga sola en el primer subpaso.
func _comprobar_plataformas(b: Bola) -> void:
	if plataformas.is_empty() or not b.libre():
		return
	var hay := false
	var dentro := false
	var debajo := CAPA_TABLERO
	for pl in plataformas:
		if pl.capa != b.capa:
			continue
		hay = true
		debajo = pl.capa_debajo
		if pl.contiene(b.pos):
			dentro = true
			break
	if hay and not dentro:
		_caer(b, debajo)

## Dos bolas SÍ pueden ir por la misma rampa a la vez, y a propósito: el recorrido
## lo lleva cada bola en sus propios `rampa_*`, no la rampa, así que no hay estado
## que compartir. En una mesa de verdad se solaparían; aquí ni se ven, porque el
## que va por la curva se dibuja como sombra.
## EL UMBRAL NO TRAGA CON MULTIBOLA, y es una decisión de cámara, no de balance.
## La cámara sigue a la bola MÁS BAJA (invariante de `CLAUDE.md`), así que con
## una bola arriba y otra abajo la caza pasaría entera fuera de plano. Con una
## sola bola, la cámara sube con ella y ya está: no hay que tocar ninguna de las
## cuatro reglas ni el escalado entero.
##
## Y tampoco traga si ya estás cazando: no se apilan dos visitas.
func _umbral_abierto() -> bool:
	return not en_caza and bolas_vivas() == 1

func _comprobar_rampas(b: Bola) -> void:
	if not b.libre():
		return
	for i in rampas.size():
		if i == umbral and not _umbral_abierto():
			continue
		var sentido := rampas[i].sentido_entrada(b.pos, b.vel)
		if sentido == 0:
			continue
		# LA BOCA TIENE ALTURA. Es lo que hace que dos recorridos se crucen sin
		# tocarse: una rampa elevada no le engancha la bola a la que va por el
		# tablero, aunque su boca caiga justo encima. Con todo en el tablero
		# —hoy— esta comprobación siempre pasa.
		var capa_boca := rampas[i].capa_entrada if sentido > 0 \
			else rampas[i].capa_salida
		if capa_boca != b.capa:
			continue
		b.rampa = i
		b.rampa_sentido = sentido
		b.rampa_subida = sentido
		b.rampa_velocidad = b.velocidad()
		b.rampa_distancia = 0.0 if sentido > 0 else rampas[i].largo
		b.pos = rampas[i].punto_en(b.rampa_distancia)
		b.vel = Vector2.ZERO
		rampa_entrada.emit(b.pos, i)
		return

# ------------------------------------------------------------ platillos

func _avanzar_platillo(b: Bola, h: float) -> void:
	b.platillo_espera -= h
	if b.platillo_espera > 0.0:
		return
	var pl := platillos[b.platillo]
	var indice := b.platillo
	b.vel = pl.direccion * pl.impulso
	b.pos = pl.centro + pl.direccion * (pl.radio + p.radio_bola + 1.0)
	b.platillo = -1
	platillo_expulsado.emit(pl.centro, indice)

## En un platillo cabe UNA bola. La segunda que llega rebota como si fuera mesa
## —o sea, sigue de largo— en vez de meterse encima de la que ya está dentro: dos
## bolas en el mismo agujero saldrían disparadas a la vez desde el mismo punto,
## que es la forma más rápida de que se queden acuñadas la una contra la otra.
func _platillo_ocupado(indice: int, salvo: Bola) -> bool:
	for otra in bolas:
		if otra != salvo and otra.platillo == indice:
			return true
	return false

func _comprobar_platillos(b: Bola) -> void:
	if not b.libre():
		return
	for i in platillos.size():
		if _platillo_ocupado(i, b):
			continue
		if not platillos[i].captura(b.pos):
			continue
		b.platillo = i
		b.platillo_espera = platillos[i].tiempo_captura
		b.pos = platillos[i].centro
		b.vel = Vector2.ZERO
		platillo_capturado.emit(platillos[i].centro, i)
		return

func _limitar_velocidad(b: Bola) -> void:
	var v := b.vel.length()
	if v > p.velocidad_maxima:
		b.vel *= p.velocidad_maxima / v

func _colisionar(b: Bola, h: float) -> void:
	# `flipper_atrapando` NO se reinicia aquí: es de la mesa y lo reinicia
	# `_subpaso` una vez para todas las bolas.
	_contactos.clear()
	# EL FILTRO DE CAPA VA AQUÍ Y NO DENTRO DE `consultar`: así la firma de
	# `consultar` no cambia, y flippers y colisionadores la comparten. Con todo
	# en `TODAS` —o sea, la mesa de hoy— esto es un `and` por colisionador y no
	# quita ni añade un solo contacto.
	for c in colisionadores:
		if not c.en_capa(b.capa):
			continue
		c.consultar(b.pos, b.vel, p.radio_bola, _contactos)
	for f in flippers:
		if not f.en_capa(b.capa):
			continue
		f.consultar(b.pos, b.vel, p.radio_bola, _contactos)
	if _contactos.is_empty():
		return

	var mas_profundo := _contactos[0]
	for c in _contactos:
		if c.profundidad > mas_profundo.profundidad:
			mas_profundo = c
		if not (c.origen is Flipper):
			continue
		var f := c.origen as Flipper
		if f.pulsado:
			b.tocando_flipper = true
			# Atrapada: la pala ya ha terminado de subir y la bola está posada
			# y quieta encima. Es el momento en el que se puede apuntar.
			if absf(f.omega) < p.flipper_omega_quieta \
					and b.velocidad() < p.velocidad_atrapada:
				flipper_atrapando = f

	# --- ARREGLO 2: resolver POSICIÓN solo contra el contacto más profundo ---
	# Corregir contra todos los contactos a la vez es lo que acuñaba la bola:
	# cada colisionador la empujaba contra el otro. Con uno solo, y dejando
	# `tolerancia_posicion` px de penetración sin corregir, no hay pelea ni
	# vibración en reposo. Los impulsos de todos los contactos van después.
	if mas_profundo.profundidad > p.tolerancia_posicion:
		b.pos += mas_profundo.normal * (mas_profundo.profundidad - p.tolerancia_posicion)

	_contactos.sort_custom(func(x: Contacto, y: Contacto) -> bool:
		return x.profundidad > y.profundidad)

	for c in _contactos:
		# Impulso contra la velocidad RELATIVA a la superficie. Esto es lo que
		# hace que un flipper en movimiento lance en vez de rebotar.
		var v_rel := b.vel - c.velocidad_superficie
		var vn := v_rel.dot(c.normal)
		if vn >= 0.0:
			continue    # ya se separa: no dupliques el rebote en las juntas
		var velocidad := -vn
		var e := c.restitucion
		# El rebote sube en rampa con la fuerza del golpe: nulo por debajo de
		# `velocidad_rebote_minima`, pleno a partir de `velocidad_rebote_pleno`.
		# Una bola apoyada llega al contacto con la velocidad que le acaba de dar
		# la gravedad en un subpaso, y devolvérsela es lo que la hace botar
		# encima de la pala en vez de quedarse.
		# Los bumpers no entran: los suyos los decide `velocidad_minima`.
		if c.empuje <= 0.0:
			e *= clampf((velocidad - p.velocidad_rebote_minima)
				/ maxf(p.velocidad_rebote_pleno - p.velocidad_rebote_minima, 1.0),
				0.0, 1.0)
		var empuje := 0.0
		if c.empuje > 0.0:
			if velocidad >= c.velocidad_minima:
				empuje = c.empuje
			else:
				e = p.rebote_pared   # por debajo del umbral el interruptor no salta
		# Impulso normal, y con él el presupuesto de rozamiento. El empuje del
		# bumper NO cuenta para ese presupuesto: es un actuador, no la carga que
		# la bola hace contra la superficie, y contarlo frenaría en seco toda
		# bola que roce un bumper.
		var jn := -(1.0 + e) * vn
		b.vel += c.normal * (jn + empuje)
		if velocidad >= p.velocidad_rebote_minima:
			_aplicar_friccion(b, c, jn, c.friccion)   # es un choque
		elif b.velocidad() <= p.velocidad_rodando:
			_aplicar_friccion(b, c, jn, c.friccion)   # casi parada: que se pare
		else:
			_aplicar_rodadura(b, c, h)                # rodando
		_avisar(c, velocidad, empuje)
	_limitar_velocidad(b)

## Rozamiento de Coulomb: un impulso a lo largo de la superficie, en contra del
## deslizamiento y limitado a `friccion` veces el impulso normal.
##
## Esto es lo que faltaba. Sin ello la bola solo sabía rebotar y resbalaba para
## siempre a lo largo de cualquier cosa que tocara, y sostenerla sobre la pala
## exigía apagarle la velocidad entera a mano. Ahora se sostiene sola: la cuna
## de la pala levantada la sujeta porque el rozamiento vence a la pendiente,
## igual que en una mesa de verdad.
##
## El impulso nunca puede invertir el deslizamiento, solo pararlo: por eso el
## `minf`. Sin él, con rozamiento alto la bola saldría disparada hacia atrás.
## Rodando: arrastre suave a lo largo de la superficie. Deja una velocidad
## límite de `gravedad·sen(cuesta)/rodadura`, y ESE es el número que hay que
## vigilar: con rodadura 20 la límite en la pala salía a 41 px/s, o sea que al
## soltar la pala la bola bajaba a velocidad constante en vez de acelerar, y se
## veía falso. Con la rodadura floja la límite se va a varios cientos de px/s,
## que la bola no alcanza en los 60 px de una pala: baja acelerando de verdad.
func _aplicar_rodadura(b: Bola, c: Contacto, h: float) -> void:
	if p.rodadura <= 0.0:
		return
	var v_rel := b.vel - c.velocidad_superficie
	var tangente := v_rel - c.normal * v_rel.dot(c.normal)
	b.vel -= tangente * (1.0 - exp(-p.rodadura * h))

func _aplicar_friccion(b: Bola, c: Contacto, jn: float, mu: float) -> void:
	if mu <= 0.0 or jn <= 0.0:
		return
	var v_rel := b.vel - c.velocidad_superficie
	var tangente := v_rel - c.normal * v_rel.dot(c.normal)
	var vt := tangente.length()
	if vt < 1e-4:
		return
	b.vel -= (tangente / vt) * minf(mu * jn, vt)

## Los avisos son la fuente del daño del combate, así que tienen que salir UNA
## vez por golpe de verdad. Sin el filtro, una bola rodando apoyada en un bumper
## emitía un aviso por subpaso: 480 golpes por segundo.
func _avisar(c: Contacto, fuerza: float, empuje: float) -> void:
	match c.tipo:
		Colisionador.Tipo.BUMPER:
			if empuje > 0.0:
				bumper_golpeado.emit(c.punto, fuerza)
		Colisionador.Tipo.SLINGSHOT:
			if empuje > 0.0:
				slingshot_golpeado.emit(c.punto, fuerza)
		Colisionador.Tipo.POSTE:
			if empuje > 0.0:
				poste_golpeado.emit(c.punto, fuerza)
		Colisionador.Tipo.FLIPPER:
			if fuerza >= 50.0:
				flipper_golpeado.emit(c.punto, fuerza)
		Colisionador.Tipo.TARGET:
			# El target se abate y deja de colisionar, así que no se repite.
			var col := c.origen as Colisionador
			if col.activo and fuerza >= col.velocidad_minima:
				_abatir(col)

## No avisa aquí de que la bola ha caído: la apunta en `_drenadas` y lo decide
## `_recoger_drenadas`, que es el único que sabe si quedaban más bolas.
func _actualizar_estado(b: Bola) -> void:
	if b.en_carril and b.pos.y < _v(0, 295).y:
		b.en_carril = false
	var fuera := b.pos.x < -60.0 or b.pos.x > ANCHO + 60.0 \
		or b.pos.y < -60.0 or b.pos.y > p.y_drenaje
	if fuera:
		b.viva = false
		b.vel = Vector2.ZERO
		_drenadas.append(b)

# --- ARREGLO 3: ball search ---
# Si la bola se queda por debajo de `busqueda_velocidad` durante
# `busqueda_tiempo`, empujón automático. Las máquinas reales lo hacen.
#
# El temporizador es POR BOLA. Con uno solo para la mesa, la bola que estás
# jugando le reiniciaba el reloj a la que se había quedado dormida en un rincón,
# y esa no se despertaba nunca.
func _ball_search(b: Bola, h: float) -> void:
	if not b.viva or b.en_carril:
		b.busqueda = 0.0
		return
	if p.busqueda_ignora_flipper_sostenido and b.tocando_flipper:
		b.busqueda = 0.0
		return
	if b.vel.length() >= p.busqueda_velocidad:
		b.busqueda = 0.0
		return
	b.busqueda += h
	if b.busqueda < p.busqueda_tiempo:
		return
	b.busqueda = 0.0
	var ang := -PI * 0.5 + rng.randf_range(-p.busqueda_dispersion, p.busqueda_dispersion)
	b.vel += Vector2(cos(ang), sin(ang)) * p.busqueda_impulso
	_limitar_velocidad(b)
	busqueda_bola.emit(b.pos)
