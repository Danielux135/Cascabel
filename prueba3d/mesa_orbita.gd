extends Mesa

## PRUEBA 3D — «ÓRBITA», una mesa nueva de arriba abajo.
##
## No es la mesa de Cascabel con otra ropa: es otro trazado, pensado como se
## piensa un pinball de verdad, con cada pieza puesta para alimentar a la
## siguiente. Lo único que hereda es el MOTOR de colisiones (`Mesa`): la pala que
## empuja en vez de rebotar, las rampas como curvas y las capas de altura. La
## geometría, entera, está aquí.
##
## EL TEMA Y LA LÓGICA. Un sistema solar:
##
##   · LANZADERA  El lanzador no escupe la bola al campo: la sube por un raíl que
##                rodea el arco y la deja caer arriba, sobre el sol.
##   · SOL        Tres bumpers en el centro alto. Todo lo que entra por arriba
##                cae en él.
##   · SATÉLITES  Tres dianas abatibles que tapan el sol por debajo. Tumbarlas
##                abre el tiro directo.
##   · ÓRBITA     El carril largo de la izquierda (tiro de la pala DERECHA).
##                Pasa por el PÚLSAR —el girador de su boca—, rodea el arco y
##                suelta la bola arriba, en el sol. Si entras flojo, no corona.
##   · COMETA     Rampa izquierda (pala DERECHA). Sube, da la vuelta y baja por
##                fuera de la banda hasta dejarte la bola en la pala IZQUIERDA.
##   · ESTACIÓN   Rampa derecha (pala IZQUIERDA). Sube a una cubierta elevada con
##                su propia pala pequeña y, al fondo, el AGUJERO NEGRO: una
##                segunda mesa en miniatura. Lo que se cae de ella baja por un
##                raíl a la pala DERECHA.
##   · AGUJERO DE GUSANO  Una boca a la derecha que se traga la bola y la saca
##                por la izquierda, encima de la pala izquierda.
##
## El dibujo que sale es un ocho: pala derecha → cometa → pala izquierda →
## estación → pala derecha. Cada rampa te deja servida la siguiente.

## Cómo quiere dibujarse cada recorrido. La simulación no lo usa: lo lee la
## vista. `lomo` es cuánto se levanta el raíl sobre sus dos bocas, en unidades
## 3D; a 0 va pegado al tablero.
var info_rampas: Dictionary = {}
var estacion: Plataforma
var flipper_estacion: Flipper
## −1 si la pala responde al botón izquierdo, +1 si al derecho. Una por pala.
var lado_pala: Array[int] = []
## LA CAZA que hay en marcha sobre esta mesa (`caza_orbita.gd`), o null. La mesa
## no sabe qué es una criatura: solo le da a la caza sus dos momentos, uno por
## tic y uno por subpaso, que es lo que necesita para chocar con la bola.
var caza: RefCounted = null
var arco_centro := Vector2(200.0, 700.0)
var arco_radios := Vector2(180.0, 130.0)

func _construir() -> void:
	# Lo que la mesa de Cascabel hace con su planta alta aquí no existe: se
	# aparta su línea de desalojo para que no se lleve ninguna bola.
	p.arena_drenaje_y = -1.0e6
	p.arena_fondo_y = -1.0e6
	p.carga_entradas = 1.0e9

	# --- El contorno -------------------------------------------------------
	arco.clear()
	for i in SEGMENTOS_ARCO + 1:
		var t := PI * float(i) / float(SEGMENTOS_ARCO)
		arco.append(Vector2(arco_centro.x + arco_radios.x * cos(t),
			arco_centro.y - arco_radios.y * sin(t)))
	for i in SEGMENTOS_ARCO:
		_pared(arco[i], arco[i + 1])
	_pared(Vector2(20, 700), Vector2(20, 1300))
	_pared(Vector2(380, 700), Vector2(380, 1300))

	# --- El carril lanzador: cerrado, solo se sale por el raíl --------------
	_pared(Vector2(358, 636), Vector2(358, 1300))
	_pared(Vector2(358, 1262), Vector2(380, 1262))
	_pared(Vector2(358, 955), Vector2(380, 955))

	# --- Los carriles de arriba, por los que la bola cae al sol -------------
	_pared(Vector2(132, 630), Vector2(132, 668))
	_pared(Vector2(188, 630), Vector2(188, 668))

	# --- El pie de la mesa: inlanes, outlanes, slingshots y postes ----------
	_pared(Vector2(20.0 + p.ancho_outlane, 1114), Vector2(99, 1184))
	_slingshot(Vector2(64, 1088), Vector2(117, 1158))
	_poste(Vector2(102, 1196))
	_pared(Vector2(358.0 - p.ancho_outlane, 1112), Vector2(301, 1184))
	_slingshot(Vector2(318, 1092), Vector2(278, 1156))
	_poste(Vector2(298, 1196))

	# --- EL SOL -------------------------------------------------------------
	_racimo(Vector2(160, 742))

	# --- LOS SATÉLITES: tapan el sol por debajo. Van un poco caídos para que
	# una bola que se les pose encima ruede y no se quede de repisa.
	_banco_targets(Vector2(131, 826), Vector2(189, 838), 3)

	# --- EL PÚLSAR, en la boca de la órbita ---------------------------------
	_girador(Vector2(50, 940))

	# --- LA LANZADERA -------------------------------------------------------
	_recorrido(PackedVector2Array([
		Vector2(369, 990), Vector2(369, 870), Vector2(368, 750),
		Vector2(360, 676), Vector2(338, 628), Vector2(300, 600),
		Vector2(256, 592), Vector2(222, 600), Vector2(210, 626),
	]), "lanzadera", Rampa.Premio.DANO, 0.25, 0.0, 0.50)
	rampas[rampas.size() - 1].velocidad_minima = 150.0

	# --- LA ÓRBITA ----------------------------------------------------------
	_recorrido(PackedVector2Array([
		Vector2(48, 905), Vector2(44, 830), Vector2(40, 750), Vector2(48, 680),
		Vector2(80, 624), Vector2(120, 598), Vector2(150, 604),
		Vector2(160, 628),
	]), "orbita", Rampa.Premio.MULTIPLICADOR, 0.32, 950.0, 0.0)

	# --- EL COMETA ----------------------------------------------------------
	_recorrido(PackedVector2Array([
		Vector2(104, 885), Vector2(100, 820), Vector2(95, 750),
		Vector2(88, 690), Vector2(70, 654), Vector2(46, 652), Vector2(26, 690),
		Vector2(12, 770), Vector2(9, 860), Vector2(9, 940), Vector2(12, 990),
		Vector2(30, 1024), Vector2(58, 1034),
	]), "cometa", Rampa.Premio.DANO, 0.30, 1000.0, 0.50)

	# --- LA ESTACIÓN: la rampa, la cubierta, su pala y el agujero negro -----
	_recorrido(PackedVector2Array([
		Vector2(250, 892), Vector2(244, 840), Vector2(232, 780),
		Vector2(226, 700), Vector2(230, 640), Vector2(246, 612),
		Vector2(264, 620), Vector2(270, 650),
	]), "estacion", Rampa.Premio.DANO_FUERTE, 0.35, 1000.0, 0.34)
	rampas[rampas.size() - 1].capa_salida = CAPA_ALTA

	estacion = Plataforma.new(Rect2(), CAPA_ALTA, CAPA_TABLERO)
	estacion.nombre = "estacion"
	estacion.poligono = PackedVector2Array([
		Vector2(246, 618), Vector2(318, 604), Vector2(352, 640),
		Vector2(352, 796), Vector2(246, 796),
	])
	plataformas.append(estacion)
	# La cubierta es un BLOQUE: desde el tablero es una pared por los cuatro
	# lados, y eso solo existe para quien va por abajo.
	var n := estacion.poligono.size()
	for i in n:
		var falda := _pared(estacion.poligono[i], estacion.poligono[(i + 1) % n])
		falda.capas = Colisionador.bit(CAPA_TABLERO)
	# Y sus barandillas, que solo existen para quien va por arriba. La de la
	# izquierda acaba en diagonal POR ENCIMA del eje de la pala: una pared que
	# muere en el eje es una silla para la bola (ver `CLAUDE.md`).
	for tramo in [
		[Vector2(250, 616), Vector2(316, 616)],
		[Vector2(316, 616), Vector2(348, 644)],
		[Vector2(348, 644), Vector2(348, 772)],
		[Vector2(250, 616), Vector2(250, 704)],
		[Vector2(250, 704), Vector2(270, 724)],
	]:
		var baranda := _pared(tramo[0], tramo[1])
		baranda.capas = Colisionador.bit(CAPA_ALTA)

	# El agujero negro, al fondo de la cubierta. Escupe flojo y hacia el hueco
	# de la bajada: la estación da UN tiro. Apuntando a la pala, un jugador de
	# mentira se quedaba 29 s de media en un bucle agujero-pala-agujero.
	platillos.append(Platillo.new(Vector2(322, 656), Vector2(0.05, 1.0),
		13.0, 1.1, 240.0))

	# La bajada: lo que se escapa junto a la punta de la pala de la estación no
	# cae al tablero, lo recoge un raíl que lo deja en el inlane derecho.
	_recorrido(PackedVector2Array([
		Vector2(326, 780), Vector2(328, 840), Vector2(332, 930),
		Vector2(334, 1010), Vector2(330, 1085),
	]), "bajada", Rampa.Premio.DANO, 0.6, 0.0, 0.10)
	var bajada := rampas[rampas.size() - 1]
	bajada.capa_entrada = CAPA_ALTA
	bajada.velocidad_minima = 20.0
	bajada.entrada_radio = 16.0

	# --- EL AGUJERO DE GUSANO: entra por la derecha, sale sobre la pala
	# izquierda. De un solo sentido: en los dos, la boca de salida se tragaría
	# los tiros rectos de la pala que tiene debajo.
	_tunel(PackedVector2Array([
		Vector2(310, 962), Vector2(328, 934), Vector2(318, 896),
		Vector2(250, 900), Vector2(170, 950), Vector2(118, 1000),
		Vector2(126, 1035),
	]), "gusano")
	var gusano := rampas[rampas.size() - 1]
	gusano.bidireccional = false
	gusano.factor_salida = 0.40
	info_rampas["gusano"] = {"lomo": 0.0}

	# --- Las palas ----------------------------------------------------------
	flipper_izq = Flipper.new(
		p.flipper_eje_izq, p.flipper_longitud, p.flipper_radio, p.flipper_rebote,
		p.flipper_reposo_izq, p.flipper_activo_izq, p.flipper_velocidad_giro)
	flipper_der = Flipper.new(
		p.flipper_eje_der, p.flipper_longitud, p.flipper_radio, p.flipper_rebote,
		p.flipper_reposo_der, p.flipper_activo_der, p.flipper_velocidad_giro)
	flipper_estacion = Flipper.new(
		Vector2(262, 742), 44.0, p.flipper_radio, p.flipper_rebote,
		p.flipper_reposo_izq, p.flipper_activo_izq, p.flipper_velocidad_giro)
	flipper_estacion.capas = Colisionador.bit(CAPA_ALTA)
	flippers = [flipper_izq, flipper_der, flipper_estacion]
	lado_pala = [-1, 1, -1]

	for c in colisionadores:
		c.friccion = p.friccion_de(c.tipo)
	for f in flippers:
		f.friccion = p.friccion_flipper

func _recorrido(control: PackedVector2Array, nombre: String, premio: int,
		factor_salida: float, velocidad_escape: float, lomo: float) -> void:
	_carril(control, nombre, premio, factor_salida, velocidad_escape)
	info_rampas[nombre] = {"lomo": lomo}

func avanzar(dt: float) -> void:
	if caza != null:
		caza.call("avanzar", self, dt)
	super.avanzar(dt)

func _subpaso(h: float) -> void:
	super._subpaso(h)
	if caza != null:
		caza.call("subpaso", self, h)

func indice_rampa(nombre: String) -> int:
	for i in rampas.size():
		if rampas[i].nombre == nombre:
			return i
	return -1

## La bola deja de estar "en el carril" cuando sale de él, que aquí es salir
## del pasillo de la derecha. La mesa de Cascabel lo mide con una altura fija
## que es de SU geometría.
func _actualizar_estado(b: Bola) -> void:
	if b.en_carril and not (b.pos.x > 358.0 and b.pos.y > 940.0):
		b.en_carril = false
	super._actualizar_estado(b)
