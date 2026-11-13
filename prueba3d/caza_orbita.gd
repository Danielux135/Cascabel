extends RefCounted

## PRUEBA 3D — LA CAZA. Quién corre por la mesa, cómo reacciona a la bola y cómo
## se deja capturar. Lógica pura: ni un nodo, ni una malla. Se ejecuta sin
## ventana (`sonda_caza.gd`) y con semilla: misma semilla, misma caza.
##
## TRES CRIATURAS, TRES FORMAS DE CAPTURAR. Es una prueba, así que en vez de una
## mecánica hay tres, para poder elegir jugándolas:
##
##   · LUMI, la huidiza. No tiene vida, tiene MIEDO. Cada golpe la asusta; con
##     el miedo lleno se queda ACORRALADA unos segundos y basta tocarla. Pero si
##     llega asustada a una boca del agujero de gusano se esconde, y dentro se
##     le pasa. Se le tapan las bocas pasando la bola por encima, y se la saca
##     metiendo la bola en el túnel.
##   · GOTA, la que se parte. El primer golpe la divide en dos mitades que salen
##     botando. Cada mitad se recoge con solo tocarla… si llegas antes de que se
##     vuelvan a juntar.
##   · TANQUE, el acorazado. No huye. Por delante la bola rebota como contra un
##     muro; hay que darle por un lado o por la espalda para VOLCARLO, y
##     recogerlo mientras patalea.
##
## Y EN LAS TRES, RECOGERLA NO ES CAPTURARLA. La criatura va dentro de la bola
## —eso es un cascabel— y queda ASEGURADA cuando esa bola toca una pala. Si la
## bola se pierde antes, se escapa.
##
## DOS REGLAS QUE PROTEGEN LA MESA:
##   · NUNCA se corrige la posición de la bola, solo su velocidad. Una criatura
##     no puede acuñar una bola contra una pared ni sostenerla: una bola lenta
##     la aparta y pasa.
##   · NO HAY ESTADO SIN SALIDA. Todos tienen tope de tiempo; andando, la
##     criatura solo existe sobre segmentos que se sabe que están libres, y si
##     aun así algo falla hay un rescate que la devuelve a la plaza. Los rescates
##     se cuentan: si la sonda no da cero, hay algo que mirar.

const Criatura := preload("res://prueba3d/criatura.gd")

signal criatura_aparecio(c: RefCounted, punto: Vector2)
signal criatura_alerta(c: RefCounted)
signal criatura_golpeada(c: RefCounted, punto: Vector2, fuerza: float, normal: Vector2)
signal criatura_blindada(c: RefCounted, punto: Vector2, fuerza: float)
signal criatura_volcada(c: RefCounted, punto: Vector2)
signal criatura_partida(c: RefCounted, punto: Vector2)
signal criatura_reunida(c: RefCounted, punto: Vector2)
signal criatura_aturdida(c: RefCounted)
signal criatura_acorralada(c: RefCounted)
signal criatura_rehecha(c: RefCounted)
signal criatura_recogida(c: RefCounted, punto: Vector2)
signal criatura_asegurada(c: RefCounted, punto: Vector2)
signal criatura_escapada(c: RefCounted, punto: Vector2)
signal criatura_escondida(c: RefCounted, punto: Vector2)
signal criatura_asoma(c: RefCounted, boca: int)
signal criatura_expulsada(c: RefCounted, punto: Vector2)
signal criatura_rescatada(c: RefCounted, punto: Vector2)
signal boca_tapada(boca: int, punto: Vector2)
signal susto_general(cuanto: float)
signal caza_completa(ola: int)

## `masa` es respecto a la bola (1), y es lo que se nota en la mano: a LUMI la
## bola la atraviesa con media velocidad, contra GOTA se queda clavada y de
## TANQUE vuelve rebotada.
const ESPECIES := {
	"corredor": {"nombre": "LUMI", "radio": 12.0, "masa": 0.5, "rebote": 0.5,
		"v_correr": 90.0, "v_huir": 185.0, "salta": false},
	"saltarin": {"nombre": "GOTA", "radio": 13.0, "masa": 1.0, "rebote": 0.5,
		"v_correr": 0.0, "v_huir": 0.0, "salta": true, "bote_largo": 40.0,
		"bote_tiempo": 0.30, "posada_paseo": 0.30, "posada_huida": 0.10},
	"gotita": {"nombre": "GOTITA", "radio": 9.0, "masa": 0.45, "rebote": 0.4,
		"v_correr": 0.0, "v_huir": 0.0, "salta": true, "bote_largo": 34.0,
		"bote_tiempo": 0.24, "posada_paseo": 0.22, "posada_huida": 0.07},
	"escarabajo": {"nombre": "TANQUE", "radio": 17.0, "masa": 4.0, "rebote": 0.5,
		"v_correr": 42.0, "v_huir": 42.0, "salta": false},
}

## LA PLAZA: el grafo por el que andan. Nodos puestos a mano en el centro de
## ESTA mesa —lejos de los soles, de las bocas de las rampas, de donde los
## raíles sueltan la bola y de las palas—; las aristas se calculan uniendo los
## que se ven con sitio de sobra. El 3 es el centro, sobre el emblema.
const PLAZA := [
	Vector2(160, 885), Vector2(205, 925), Vector2(125, 950), Vector2(214, 1018),
	Vector2(275, 975), Vector2(155, 1055), Vector2(255, 1055),
	Vector2(82, 962), Vector2(316, 1016),
]
const NODO_CENTRO := 3
const NODO_EXPULSION := 5

# ----------------------------------------------------------------- los diales
# Todo lo que es tacto está aquí arriba y con nombre, para moverlo jugando.

## LA AMENAZA: una bola libre a menos de `radio_ver` que va a pasarle a menos de
## `margen_paso` del cuerpo en menos de `t_prevision`. No basta con estar cerca.
var radio_ver := 150.0
var margen_paso := 9.0
var t_prevision := 0.35
## Lo que tarda en reaccionar, agachada. Es lo que hace que el tiro FUERTE entre
## siempre y el flojo se pueda esquivar: a 900 px/s la bola llega antes.
var t_alerta := 0.16
var t_huida_min := 1.0
var t_huida_max := 4.0
var radio_tranquila := 160.0
var t_tranquila := 0.6
## Por debajo de esta velocidad relativa no hay golpe: la bola la aparta y pasa.
var v_golpe := 120.0
var t_recarga := 0.30
var v_vuelo_max := 520.0
var v_vuelo_min := 200.0
var freno_vuelo := 4.5
var t_vuelo_max := 0.9
var v_reposo := 30.0
var rebote_pared := 0.4
var v_empujon := 110.0
## Más abajo de esta línea están los slingshots y las palas: ahí no pinta nada.
var y_rescate := 1085.0
var t_aparecer := 0.6

## --- LUMI: el miedo -------------------------------------------------------
var miedo_golpe := 0.34
var miedo_sol := 0.04
var miedo_recorrido := 0.15
var miedo_expulsion := 0.25
var miedo_esconderse := 0.5
## Solo se le pasa escondida. En la mesa, el miedo que lleva lo lleva.
var calma_escondida := 0.15
var miedo_al_salir := 0.2
var t_escondida_max := 4.0
var t_aviso_asoma := 0.6
var t_cierre := 5.0
var miedo_al_rehacerse := 0.5
var t_sin_refugio := 6.0
var radio_tapar := 28.0
var t_boca_tapada := 4.0

## --- GOTA: partirse -------------------------------------------------------
var v_mitad := 240.0
var t_mitad_intocable := 0.6
var t_reunion := 8.0
var radio_reunion := 20.0

## --- TANQUE: la coraza ----------------------------------------------------
## Medio ángulo del frente blindado, en grados, y cuánto rebota la bola en él.
var arco_blindaje := 70.0
var rebote_blindaje := 0.9
var t_plantado := 0.8
var t_volcada := 5.0
var giro_tanque := 170.0

## --- Llevarla a una pala --------------------------------------------------
var margen_pala := 2.0
var t_en_bola_max := 15.0
var t_reaparecer := 1.0
var t_entre_olas := 4.5

# ---------------------------------------------------------------------- estado

var criaturas: Array = []
var nodos := PackedVector2Array()
var vecinos: Array = []
## Índices de nodo de las bocas del túnel, y cuánto le queda tapada a cada una.
var bocas := PackedInt32Array()
var boca_cierre := PackedFloat32Array()
var tunel: Rampa = null
var rng := RandomNumberGenerator.new()
var capturas := 0
var ola := 1
var tiempo := 0.0
## `rescates` cuenta las que salieron volando de la plaza hacia las palas: pasa,
## y no es un fallo. Los otros tres SÍ tienen que dar cero: una criatura que no
## ve ningún nodo desde donde ha caído, una que no avanza, o un estado que no
## debería existir.
var rescates := 0
var sin_salida := 0
var saltos_de_vigia := 0
var ramas_por_defecto := 0

var _espera_ola := -1.0
var _capa := Colisionador.CAPA_TABLERO
## `_siguiente[a][b]`: por qué vecino se va de `a` a `b` por el camino corto.
var _siguiente: Array = []
var _saltos: Array = []

# ------------------------------------------------------------------ preparación

func preparar(mesa: Mesa, semilla: int = 1) -> void:
	rng.seed = semilla
	_montar_grafo(mesa)
	criaturas.clear()
	_crear("corredor", -1)
	var gota := _crear("saltarin", -1)
	_crear("escarabajo", -1)
	_crear("gotita", gota.indice)
	_crear("gotita", gota.indice)
	_repartir_entradas()
	mesa.bumper_golpeado.connect(_al_golpear_sol)
	mesa.rampa_entrada.connect(_al_entrar_rampa.bind(mesa))
	mesa.rampa_salida.connect(_al_salir_rampa.bind(mesa))

func _crear(especie: String, madre: int) -> Criatura:
	var ficha: Dictionary = ESPECIES[especie]
	var c := Criatura.new()
	c.indice = criaturas.size()
	c.especie = especie
	c.nombre = ficha["nombre"]
	c.radio = ficha["radio"]
	c.masa = ficha["masa"]
	c.rebote = ficha["rebote"]
	c.v_correr = ficha["v_correr"]
	c.v_huir = ficha["v_huir"]
	c.salta = ficha["salta"]
	if c.salta:
		c.bote_largo = ficha["bote_largo"]
		c.bote_tiempo = ficha["bote_tiempo"]
		c.posada_paseo = ficha["posada_paseo"]
		c.posada_huida = ficha["posada_huida"]
	c.madre = madre
	c.principal = madre < 0
	c.capa = _capa
	c.espera = -1.0
	criaturas.append(c)
	return c

func _repartir_entradas() -> void:
	var turno := 0
	for c: Criatura in criaturas:
		if c.principal and c.activa:
			c.espera = 1.0 + 1.2 * float(turno)
			turno += 1
		else:
			c.espera = -1.0

func mitades(c: Criatura) -> Array:
	var lista: Array = []
	for otra: Criatura in criaturas:
		if otra.madre == c.indice:
			lista.append(otra)
	return lista

func principales() -> Array:
	var lista: Array = []
	for c: Criatura in criaturas:
		if c.principal:
			lista.append(c)
	return lista

func _montar_grafo(mesa: Mesa) -> void:
	nodos = PackedVector2Array(PLAZA)
	bocas = PackedInt32Array()
	tunel = null
	for r in mesa.rampas:
		if r.subterranea:
			tunel = r
			bocas.append(nodos.size())
			nodos.append(r.puntos[0])
			bocas.append(nodos.size())
			nodos.append(r.puntos[r.puntos.size() - 1])
			break
	boca_cierre = PackedFloat32Array()
	boca_cierre.resize(bocas.size())
	# Se montan como listas normales y se empaquetan al final: un array
	# empaquetado metido dentro de otro se COPIA al sacarlo con `as`, así que
	# añadirle ahí no añade nada, y el grafo salía sin una sola arista.
	var listas: Array = []
	for i in nodos.size():
		listas.append([])
	for i in nodos.size():
		for j in range(i + 1, nodos.size()):
			if nodos[i].distance_to(nodos[j]) > 135.0:
				continue
			# De boca a boca no se anda: para eso está el túnel.
			if bocas.has(i) and bocas.has(j):
				continue
			if paso_libre(mesa, nodos[i], nodos[j], 19.0):
				(listas[i] as Array).append(j)
				(listas[j] as Array).append(i)
	vecinos.clear()
	for i in nodos.size():
		vecinos.append(PackedInt32Array(listas[i] as Array))
	_montar_rutas()

## Caminos cortos entre nodos, por anchura. Las bocas solo valen como llegada:
## nadie cruza una boca para ir a otro sitio.
func _montar_rutas() -> void:
	_siguiente.clear()
	_saltos.clear()
	var n := nodos.size()
	for origen in n:
		var sig := PackedInt32Array()
		var dist := PackedInt32Array()
		sig.resize(n)
		dist.resize(n)
		for k in n:
			sig[k] = -1
			dist[k] = 9999
		dist[origen] = 0
		var cola: Array = [origen]
		while not cola.is_empty():
			var a: int = cola.pop_front()
			if bocas.has(a) and a != origen:
				continue
			for b in (vecinos[a] as PackedInt32Array):
				if dist[b] <= dist[a] + 1:
					continue
				dist[b] = dist[a] + 1
				sig[b] = b if a == origen else sig[a]
				cola.append(b)
		_siguiente.append(sig)
		_saltos.append(dist)

## ¿Cabe un círculo de `radio` en `pt`, contra todo lo fijo de la capa? El
## `hueco_libre` de `Mesa` no filtra por capa: con él, la estación no existiría.
func cabe(mesa: Mesa, pt: Vector2, radio: float) -> bool:
	for col in mesa.colisionadores:
		if not col.activo or not col.en_capa(_capa):
			continue
		if pt.distance_to(col.punto_mas_cercano(pt)) < col.radio + radio:
			return false
	return true

func paso_libre(mesa: Mesa, a: Vector2, b: Vector2, radio: float) -> bool:
	var pasos := maxi(int(ceil(a.distance_to(b) / 4.0)), 1)
	for i in pasos + 1:
		if not cabe(mesa, a.lerp(b, float(i) / float(pasos)), radio):
			return false
	return true

func es_boca(nodo: int) -> bool:
	return bocas.has(nodo)

func _vecinos_de_plaza(nodo: int) -> PackedInt32Array:
	var lista := PackedInt32Array()
	for k in (vecinos[nodo] as PackedInt32Array):
		if not bocas.has(k):
			lista.append(k)
	return lista

# -------------------------------------------------------------------- el avance

## Una vez por tic de física (120 Hz), antes de mover las bolas.
func avanzar(mesa: Mesa, dt: float) -> void:
	tiempo += dt
	for k in boca_cierre.size():
		boca_cierre[k] = maxf(boca_cierre[k] - dt, 0.0)
	_vigilar_bocas(mesa)
	for c: Criatura in criaturas:
		if not c.activa:
			continue
		c.t_estado += dt
		c.t_recarga = maxf(c.t_recarga - dt, 0.0)
		c.t_empujon = maxf(c.t_empujon - dt, 0.0)
		c.t_refugio = maxf(c.t_refugio - dt, 0.0)
		c.t_realerta = maxf(c.t_realerta - dt, 0.0)
		match c.estado:
			Criatura.Estado.FUERA:
				_fuera(mesa, c, dt)
			Criatura.Estado.APARECER:
				if c.t_estado >= t_aparecer:
					_tras_aparecer(mesa, c)
			Criatura.Estado.CORRER:
				_correr(mesa, c, dt)
			Criatura.Estado.ALERTA:
				_alerta(mesa, c)
			Criatura.Estado.HUIR:
				_huir(mesa, c, dt)
			Criatura.Estado.VOLAR:
				_volar(mesa, c, dt)
			Criatura.Estado.ATURDIDA:
				c.vel = Vector2.ZERO
				if c.t_estado >= _t_aturdida(c):
					_al_grafo(mesa, c, true)
			Criatura.Estado.ACORRALADA:
				_acorralada(mesa, c)
			Criatura.Estado.VOLCADA:
				_volcada(mesa, c)
			Criatura.Estado.ESCONDIDA:
				_escondida(mesa, c, dt)
			Criatura.Estado.EN_BOLA:
				if c.t_estado >= t_en_bola_max:
					_asegurar(c, c.pos)
			_:
				# No debería existir. Si existe, se cuenta y vuelve a la plaza.
				ramas_por_defecto += 1
				_al_grafo(mesa, c, false)
		_vigia(c, dt)
	_reunir_mitades(mesa, dt)
	_ola_nueva(dt)

## Una vez por SUBPASO, después de mover las bolas. A 480 Hz por lo mismo que el
## resto de la mesa: a 1500 px/s una bola avanza 12 px por tic, y a esa zancada
## se saltaría media criatura.
func subpaso(mesa: Mesa, _h: float) -> void:
	var r_bola := mesa.p.radio_bola
	# Las que van dentro de una bola: ¿sigue viva?, ¿ha tocado una pala?
	for c: Criatura in criaturas:
		if c.estado != Criatura.Estado.EN_BOLA:
			continue
		var lleva: Bola = c.portadora
		# `has`: con multibola, pedir bola nueva saca a las extra de la lista sin
		# matarlas, y la criatura se quedaba pegada a una bola que ya no existe.
		if lleva == null or not lleva.viva or lleva.en_carril 				or not mesa.bolas.has(lleva):
			_soltar(c)
			continue
		c.pos = lleva.pos
		for f in mesa.flippers:
			if not f.en_capa(lleva.capa):
				continue
			var punta := f.punta()
			var eje_a_punta := punta - f.eje
			var t := clampf((lleva.pos - f.eje).dot(eje_a_punta)
				/ maxf(eje_a_punta.length_squared(), 0.001), 0.0, 1.0)
			var toque := f.eje + eje_a_punta * t
			if lleva.pos.distance_to(toque) <= f.radio + r_bola + margen_pala:
				_asegurar(c, toque)
				break

	for b in mesa.bolas:
		if not (b.viva and b.libre()) or b.en_carril:
			continue
		for c: Criatura in criaturas:
			if not c.activa or not c.golpeable() or c.capa != b.capa:
				continue
			var delta: Vector2 = b.pos - c.pos
			var suma: float = c.radio + r_bola
			var d2 := delta.length_squared()
			if d2 >= suma * suma:
				continue
			var d := sqrt(d2)
			var n: Vector2 = delta / d if d > 1e-4 else Vector2.UP
			var punto: Vector2 = c.pos + n * c.radio
			if c.rendida():
				_recoger(c, b, punto)
				continue
			if c.especie == "gotita":
				continue    # recién partida: aún no se la puede tocar
			var fuerza: float = -(b.vel - c.vel).dot(n)
			if fuerza >= v_golpe and c.t_recarga <= 0.0:
				_golpear(mesa, c, b, n, fuerza, punto)
			elif c.t_empujon <= 0.0 and c.estado != Criatura.Estado.VOLAR:
				_empujar(c, n)

# -------------------------------------------------------------------- percibir

func _bola_cuenta(b: Bola, c: Criatura) -> bool:
	return b.viva and b.libre() and not b.en_carril and b.capa == c.capa

## La bola que viene a por ella, o null.
func _amenaza(mesa: Mesa, c: Criatura) -> Bola:
	var peor: Bola = null
	var antes := INF
	var holgura: float = c.radio + mesa.p.radio_bola + margen_paso
	for b in mesa.bolas:
		if not _bola_cuenta(b, c):
			continue
		var rel: Vector2 = b.pos - c.pos
		if rel.length() > radio_ver:
			continue
		var v2 := b.vel.length_squared()
		if v2 < 3600.0:
			continue
		# Cuándo y a qué distancia va a pasarle más cerca, si sigue recta.
		var t := -rel.dot(b.vel) / v2
		if t <= 0.0 or t > t_prevision or t >= antes:
			continue
		if (rel + b.vel * t).length() < holgura:
			peor = b
			antes = t
	return peor

func _bola_mas_cercana(mesa: Mesa, c: Criatura) -> Bola:
	var mejor: Bola = null
	var dist := INF
	for b in mesa.bolas:
		if not b.viva:
			continue
		var d := c.pos.distance_squared_to(b.pos)
		if d < dist:
			dist = d
			mejor = b
	return mejor

func _hay_bola_cerca(mesa: Mesa, c: Criatura, radio: float) -> bool:
	for b in mesa.bolas:
		if _bola_cuenta(b, c) and b.pos.distance_to(c.pos) < radio:
			return true
	return false

## Lo lejos que queda un punto de donde VAN A ESTAR las bolas. Sin bolas, da igual.
func _lejania(mesa: Mesa, c: Criatura, pt: Vector2) -> float:
	var menor := INF
	for b in mesa.bolas:
		if not _bola_cuenta(b, c):
			continue
		menor = minf(menor, pt.distance_to(b.pos + b.vel * t_prevision))
	return menor if menor < INF else 0.0

func _mirar(mesa: Mesa, c: Criatura) -> void:
	var b := _bola_mas_cercana(mesa, c)
	if b != null and b.pos.distance_to(c.pos) < 260.0:
		c.mira = b.pos
	else:
		c.mira = c.pos + c.rumbo * 90.0

# ----------------------------------------------------------------------- a pie

func _correr(mesa: Mesa, c: Criatura, dt: float) -> void:
	_mirar(mesa, c)
	if c.especie != "escarabajo" and c.t_realerta <= 0.0:
		var b := _amenaza(mesa, c)
		if b != null:
			_alertar(c, b.pos)
			return
	if c.espera > 0.0:
		c.espera -= dt
		c.vel = Vector2.ZERO
		return
	if _avanzar_por_grafo(c, false, dt):
		_elegir_paseo(c)
		# Destino nuevo, cuenta nueva: el vigía mide lo que avanza DENTRO de un
		# tramo. Sin reiniciarlo, una vuelta entera a un triángulo de nodos la
		# dejaba donde empezó y contaba como atasco.
		c.t_vigia = 0.0
		c.pos_vigia = c.pos

func _alertar(c: Criatura, mira: Vector2) -> void:
	c.mira = mira
	c.vel = Vector2.ZERO
	c.bote_u = -1.0
	c.espera = 0.0
	c.cambiar(Criatura.Estado.ALERTA)
	criatura_alerta.emit(c)

func _alerta(mesa: Mesa, c: Criatura) -> void:
	c.vel = Vector2.ZERO
	if c.t_estado < t_alerta:
		return
	c.t_huyendo = 0.0
	c.t_sin_bola = 0.0
	c.bote_reloj = 0.0
	c.cambiar(Criatura.Estado.HUIR)
	_elegir_huida(mesa, c, true)

func _huir(mesa: Mesa, c: Criatura, dt: float) -> void:
	_mirar(mesa, c)
	c.t_huyendo += dt
	if _hay_bola_cerca(mesa, c, radio_tranquila):
		c.t_sin_bola = 0.0
	else:
		c.t_sin_bola += dt
	if (c.t_huyendo >= t_huida_min and c.t_sin_bola >= t_tranquila) \
			or c.t_huyendo >= t_huida_max:
		c.t_realerta = 0.5
		c.cambiar(Criatura.Estado.CORRER)
		return
	if not _avanzar_por_grafo(c, true, dt):
		return
	# Ha llegado. Si es una boca abierta y venía a esconderse, se mete.
	var k := bocas.find(c.destino)
	if k >= 0:
		if _puede_esconderse(c) and boca_cierre[k] <= 0.0:
			_esconder(c, k)
			return
	_elegir_huida(mesa, c, false)
	c.t_vigia = 0.0
	c.pos_vigia = c.pos

func _puede_esconderse(c: Criatura) -> bool:
	return c.especie == "corredor" and tunel != null and bocas.size() == 2 \
		and c.miedo >= miedo_esconderse and c.t_refugio <= 0.0

## Avanza hacia su nodo de destino por el segmento recto, que está libre. Las que
## andan, andan; las que saltan, a botes; y TANQUE primero se encara y luego
## avanza. Devuelve true al llegar.
func _avanzar_por_grafo(c: Criatura, huyendo: bool, dt: float) -> bool:
	if c.destino < 0 or c.destino >= nodos.size():
		c.destino = NODO_CENTRO
	var meta := nodos[c.destino]
	var hacia := meta - c.pos
	var d := hacia.length()
	if d < 0.5:
		c.pos = meta
		c.vel = Vector2.ZERO
		if c.salta and c.bote_u >= 0.0:
			c.bote_u = -1.0
			c.bote_reloj = c.posada_huida if huyendo else c.posada_paseo
		return true
	var dir := hacia / d

	if c.salta:
		if c.bote_u < 0.0:
			# Posada, cogiendo impulso.
			c.vel = Vector2.ZERO
			c.bote_reloj -= dt
			if c.bote_reloj > 0.0:
				return false
			c.bote_total = minf(c.bote_largo, d)
			c.bote_resto = c.bote_total
			c.bote_u = 0.0
			c.rumbo = dir
		var v: float = c.bote_largo / maxf(c.bote_tiempo, 0.05)
		var paso := minf(v * dt, c.bote_resto)
		c.pos += dir * paso
		c.vel = dir * v
		c.bote_resto -= paso
		c.bote_u = 1.0 - c.bote_resto / maxf(c.bote_total, 0.01)
		if c.bote_resto <= 0.01:
			c.bote_u = -1.0
			c.vel = Vector2.ZERO
			c.bote_reloj = c.posada_huida if huyendo else c.posada_paseo
			return c.pos.distance_to(meta) < 0.5
		return false

	if c.especie == "escarabajo":
		# Se encara antes de andar: girar le cuesta, y es cuando enseña el lomo.
		var ang := c.rumbo.angle_to(dir)
		var giro := deg_to_rad(giro_tanque) * dt
		if absf(ang) > giro:
			c.rumbo = c.rumbo.rotated(signf(ang) * giro).normalized()
			if absf(ang) > 0.35:
				c.vel = Vector2.ZERO
				return false
		else:
			c.rumbo = dir
	else:
		c.rumbo = dir

	var rapidez: float = c.v_huir if huyendo else c.v_correr
	var avance := minf(rapidez * dt, d)
	c.pos += dir * avance
	c.vel = dir * rapidez
	return d - avance < 0.5

func _elegir_paseo(c: Criatura) -> void:
	var aqui := c.destino
	var opciones := _vecinos_de_plaza(aqui)
	if opciones.is_empty():
		c.nodo = aqui
		c.destino = NODO_CENTRO
		return
	var elegido := -1
	if c.reuniendose:
		# Las mitades que se buscan van al centro por el camino corto.
		elegido = aqui if aqui == NODO_CENTRO else (_siguiente[aqui] as PackedInt32Array)[NODO_CENTRO]
		if elegido < 0:
			elegido = opciones[0]
	else:
		var k := rng.randi_range(0, opciones.size() - 1)
		elegido = opciones[k]
		# No vuelve por donde ha venido si hay otro sitio, ni a donde va otra.
		for _intento in opciones.size():
			if elegido != c.nodo and not _nodo_pedido(c, elegido):
				break
			k = (k + 1) % opciones.size()
			elegido = opciones[k]
		if c.especie == "escarabajo":
			c.espera = 0.25
		elif not c.salta and rng.randf() < 0.45:
			c.espera = rng.randf_range(0.5, 1.2)
	c.nodo = aqui
	c.destino = elegido

func _nodo_pedido(c: Criatura, nodo: int) -> bool:
	for otra: Criatura in criaturas:
		if otra != c and otra.activa and otra.a_pie() and otra.destino == nodo:
			return true
	return false

## Hacia dónde huye. `primera` es al salir de la alerta, que puede pillarla a
## mitad de un tramo: entonces solo puede seguir o dar media vuelta.
func _elegir_huida(mesa: Mesa, c: Criatura, primera: bool) -> void:
	var opciones := PackedInt32Array()
	var aqui := c.destino
	if primera:
		opciones.append(c.destino)
		if c.nodo >= 0 and c.nodo != c.destino and not bocas.has(c.nodo):
			opciones.append(c.nodo)
		aqui = -1
	else:
		opciones = _vecinos_de_plaza(aqui)
		if opciones.is_empty():
			c.destino = NODO_CENTRO
			return

	# El refugio tira: con miedo de sobra y una boca abierta a un paso o dos,
	# va hacia ella en vez de hacia lo más lejano.
	if _puede_esconderse(c):
		var mejor_boca := -1
		var cerca := 3
		var desde := c.destino if primera else aqui
		for k in bocas.size():
			if boca_cierre[k] > 0.0:
				continue
			var saltos: int = (_saltos[desde] as PackedInt32Array)[bocas[k]]
			if saltos < cerca:
				cerca = saltos
				mejor_boca = bocas[k]
		if mejor_boca >= 0 and not primera:
			var paso: int = (_siguiente[aqui] as PackedInt32Array)[mejor_boca]
			if paso >= 0:
				c.nodo = aqui
				c.destino = paso
				return

	var elegido := opciones[0]
	var nota := -INF
	for k in opciones:
		var n := _lejania(mesa, c, nodos[k]) + rng.randf_range(0.0, 12.0)
		# Volver por donde vino solo si es claramente mejor.
		if not primera and k == c.nodo:
			n -= 30.0
		if n > nota:
			nota = n
			elegido = k
	if primera:
		if elegido != c.destino:
			c.nodo = c.destino
			c.destino = elegido
	else:
		c.nodo = aqui
		c.destino = elegido

# ---------------------------------------------------------------- el golpe

func _golpear(mesa: Mesa, c: Criatura, b: Bola, n: Vector2, fuerza: float,
		punto: Vector2) -> void:
	c.t_recarga = t_recarga
	var e: float = c.rebote
	var frontal := false
	if c.especie == "escarabajo":
		frontal = n.dot(c.rumbo) > cos(deg_to_rad(arco_blindaje))
		if frontal:
			e = rebote_blindaje
	# Bola de masa 1 contra criatura de masa m. La bola se lleva su parte; la
	# posición de la bola NO se toca.
	var j := (1.0 + e) * fuerza * c.masa / (1.0 + c.masa)
	b.vel += n * j
	var v := b.vel.length()
	if v > mesa.p.velocidad_maxima:
		b.vel *= mesa.p.velocidad_maxima / v
	var salida := minf(j / c.masa, v_vuelo_max)

	match c.especie:
		"saltarin":
			criatura_golpeada.emit(c, punto, fuerza, n)
			_partir(c, n, punto)
		"escarabajo":
			if frontal:
				# La coraza: no pasa nada, salvo que la bola vuelve con ganas.
				c.espera = t_plantado
				c.vel = Vector2.ZERO
				criatura_blindada.emit(c, punto, fuerza)
			else:
				c.golpes += 1
				c.volcando = true
				c.empujada = false
				c.vel = -n * clampf(salida, 90.0, 220.0)
				c.cambiar(Criatura.Estado.VOLAR)
				criatura_golpeada.emit(c, punto, fuerza, n)
		_:
			c.golpes += 1
			c.miedo = _lleno(c.miedo + miedo_golpe)
			c.empujada = false
			c.vel = -n * maxf(salida, v_vuelo_min)
			c.bote_u = -1.0
			c.cambiar(Criatura.Estado.VOLAR)
			criatura_golpeada.emit(c, punto, fuerza, n)

## Una bola lenta no golpea: la aparta. La criatura se quita, la bola ni se entera.
func _empujar(c: Criatura, n: Vector2) -> void:
	c.t_empujon = 0.5
	if c.especie == "escarabajo" or c.estado == Criatura.Estado.ATURDIDA:
		return
	c.empujada = true
	c.vel = -n * v_empujon
	c.bote_u = -1.0
	c.cambiar(Criatura.Estado.VOLAR)

func _volar(mesa: Mesa, c: Criatura, dt: float) -> void:
	c.vel *= exp(-freno_vuelo * dt)
	c.pos += c.vel * dt
	_chocar_con_lo_fijo(mesa, c)
	_mirar(mesa, c)
	if c.pos.y > y_rescate or c.pos.y < 560.0 or c.pos.x < 10.0 \
			or c.pos.x > Mesa.ANCHO - 10.0:
		_rescatar(c)
		return
	if c.t_estado < t_vuelo_max and c.vel.length() >= v_reposo:
		return
	c.vel = Vector2.ZERO
	if c.empujada:
		c.empujada = false
		_al_grafo(mesa, c, true)
	elif c.volcando:
		c.volcando = false
		c.cambiar(Criatura.Estado.VOLCADA)
		criatura_volcada.emit(c, c.pos)
	elif c.especie == "corredor" and c.miedo >= 1.0:
		_acorralar(c)
	else:
		c.cambiar(Criatura.Estado.ATURDIDA)
		criatura_aturdida.emit(c)

## En el aire es un círculo libre: choca con lo fijo de su capa con el MISMO
## `consultar` que usa la bola. No recibe patadas de los soles, no abate
## satélites y no toca las palas: es un bicho rodando, no otra bola.
func _chocar_con_lo_fijo(mesa: Mesa, c: Criatura) -> void:
	var contactos: Array = []
	for col in mesa.colisionadores:
		if col.en_capa(c.capa):
			col.consultar(c.pos, c.vel, c.radio, contactos)
	for ct in contactos:
		var contacto: Contacto = ct
		c.pos += contacto.normal * contacto.profundidad
		var vn := c.vel.dot(contacto.normal)
		if vn < 0.0:
			c.vel -= contacto.normal * vn * (1.0 + rebote_pared)

func _t_aturdida(c: Criatura) -> float:
	match c.especie:
		"gotita":
			return 0.4
		"escarabajo":
			return 0.6
	return 0.7

# -------------------------------------------------------- LUMI: miedo y túnel

func _asustar(c: Criatura, cuanto: float) -> void:
	if c.especie != "corredor" or not c.activa:
		return
	if c.estado == Criatura.Estado.FUERA or c.estado == Criatura.Estado.EN_BOLA \
			or c.estado == Criatura.Estado.ESCONDIDA \
			or c.estado == Criatura.Estado.APARECER:
		return
	c.miedo = _lleno(c.miedo + cuanto)
	var en_el_suelo: bool = c.a_pie() or c.estado == Criatura.Estado.ALERTA
	if c.miedo >= 1.0 and (en_el_suelo or c.estado == Criatura.Estado.ATURDIDA):
		_acorralar(c)

## El miedo, sumado y topado. Por encima de 0,995 cuenta como lleno: dos golpes
## y ocho soles suman 1 en el papel y 0,9999 en coma flotante, y el aro se
## vería lleno sin que pasara nada.
func _lleno(valor: float) -> float:
	return 1.0 if valor > 0.995 else maxf(valor, 0.0)

func _acorralar(c: Criatura) -> void:
	c.miedo = 1.0
	c.vel = Vector2.ZERO
	c.bote_u = -1.0
	c.cambiar(Criatura.Estado.ACORRALADA)
	criatura_acorralada.emit(c)

func _acorralada(mesa: Mesa, c: Criatura) -> void:
	c.vel = Vector2.ZERO
	_mirar(mesa, c)
	if c.t_estado >= t_cierre:
		# Se le pasa el pánico: no se ha perdido, pero hay que volver a asustarla.
		c.miedo = miedo_al_rehacerse
		criatura_rehecha.emit(c)
		_al_grafo(mesa, c, true)

func _esconder(c: Criatura, boca: int) -> void:
	c.boca_entrada = boca
	c.boca_salida = 1 - boca
	c.asoma_avisado = false
	c.vel = Vector2.ZERO
	# Sale cuando se le ha pasado bastante, con un tope: no se queda a vivir.
	c.espera = clampf((c.miedo - miedo_al_salir) / maxf(calma_escondida, 0.01),
		1.2, t_escondida_max)
	c.cambiar(Criatura.Estado.ESCONDIDA)
	criatura_escondida.emit(c, nodos[bocas[boca]])

func _escondida(_mesa: Mesa, c: Criatura, dt: float) -> void:
	c.miedo = maxf(c.miedo - calma_escondida * dt, 0.0)
	var u := clampf(c.t_estado / maxf(c.espera, 0.1), 0.0, 1.0)
	if tunel != null:
		c.pos = tunel.punto_en(tunel.largo * (u if c.boca_entrada == 0 else 1.0 - u))
	if not c.asoma_avisado and c.t_estado >= c.espera - t_aviso_asoma:
		# Por la otra boca, salvo que esté tapada; entonces por la que entró. Con
		# las dos tapadas espera un poco, pero no para siempre.
		var salida := 1 - c.boca_entrada
		if boca_cierre[salida] > 0.0:
			salida = c.boca_entrada
			if boca_cierre[salida] > 0.0 and c.espera < t_escondida_max + 2.0:
				c.espera += 0.5
				return
		c.boca_salida = salida
		c.asoma_avisado = true
		criatura_asoma.emit(c, salida)
	if c.t_estado < c.espera or not c.asoma_avisado:
		return
	_salir_del_tunel(c, bocas[c.boca_salida])

func _salir_del_tunel(c: Criatura, nodo: int) -> void:
	c.pos = nodos[nodo]
	c.vel = Vector2.ZERO
	c.nodo = nodo
	c.destino = nodo
	c.t_refugio = t_sin_refugio
	c.cambiar(Criatura.Estado.APARECER)
	criatura_aparecio.emit(c, c.pos)

## Una bola en el túnel con ella dentro: la saca a la fuerza, y asustada.
func _expulsar(mesa: Mesa, c: Criatura) -> void:
	c.pos = nodos[NODO_EXPULSION]
	c.vel = Vector2.ZERO
	c.nodo = NODO_EXPULSION
	c.destino = NODO_EXPULSION
	c.t_refugio = t_sin_refugio
	c.miedo = _lleno(c.miedo + miedo_expulsion)
	criatura_expulsada.emit(c, c.pos)
	if c.miedo >= 1.0:
		_acorralar(c)
	else:
		c.cambiar(Criatura.Estado.ATURDIDA)
		criatura_aturdida.emit(c)
	_mirar(mesa, c)

func _tapar(boca: int) -> void:
	var estaba := boca_cierre[boca] > 0.0
	boca_cierre[boca] = t_boca_tapada
	if not estaba:
		boca_tapada.emit(boca, nodos[bocas[boca]])

func _vigilar_bocas(mesa: Mesa) -> void:
	for k in bocas.size():
		var pt := nodos[bocas[k]]
		for b in mesa.bolas:
			if b.viva and b.libre() and not b.en_carril and b.capa == _capa \
					and b.pos.distance_to(pt) < radio_tapar:
				_tapar(k)
				break

func _boca_mas_cercana(punto: Vector2) -> int:
	var mejor := -1
	var dist := INF
	for k in bocas.size():
		var d := punto.distance_to(nodos[bocas[k]])
		if d < dist:
			dist = d
			mejor = k
	return mejor

func _al_golpear_sol(_punto: Vector2, _fuerza: float) -> void:
	for c: Criatura in criaturas:
		_asustar(c, miedo_sol)
	susto_general.emit(miedo_sol)

func _al_entrar_rampa(punto: Vector2, indice: int, mesa: Mesa) -> void:
	var r := mesa.rampas[indice]
	if not r.subterranea or r != tunel:
		return
	var k := _boca_mas_cercana(punto)
	if k >= 0:
		_tapar(k)
	for c: Criatura in criaturas:
		if c.activa and c.estado == Criatura.Estado.ESCONDIDA:
			_expulsar(mesa, c)

func _al_salir_rampa(punto: Vector2, indice: int, mesa: Mesa) -> void:
	var r := mesa.rampas[indice]
	if r.subterranea:
		var k := _boca_mas_cercana(punto)
		if k >= 0 and r == tunel:
			_tapar(k)
		return
	if r.nombre != "orbita" and r.nombre != "cometa" and r.nombre != "estacion":
		return
	# Coronar un recorrido las asusta a todas y las pone en marcha.
	for c: Criatura in criaturas:
		_asustar(c, miedo_recorrido)
		if c.activa and c.estado == Criatura.Estado.CORRER \
				and c.especie != "escarabajo":
			_alertar(c, punto)
	susto_general.emit(miedo_recorrido)

# ------------------------------------------------------------ GOTA: partirse

func _partir(c: Criatura, n: Vector2, punto: Vector2) -> void:
	var lado := Vector2(-n.y, n.x)
	var signo := 1.0
	for g: Criatura in mitades(c):
		var m: Criatura = g
		m.activa = true
		m.asegurada = false
		m.reuniendose = false
		m.portadora = null
		m.empujada = false
		m.pos = c.pos + lado * signo * 7.0
		m.vel = -n * 130.0 + lado * signo * v_mitad
		m.rumbo = m.vel.normalized()
		m.capa = c.capa
		m.t_recarga = t_mitad_intocable
		m.bote_u = -1.0
		m.espera = -1.0
		m.cambiar(Criatura.Estado.VOLAR)
		signo = -signo
	c.partida = true
	c.t_partida = 0.0
	c.vel = Vector2.ZERO
	c.espera = -1.0
	c.cambiar(Criatura.Estado.FUERA)
	criatura_partida.emit(c, punto)

func _suelta_en_la_plaza(c: Criatura) -> bool:
	return c.estado == Criatura.Estado.CORRER or c.estado == Criatura.Estado.HUIR \
		or c.estado == Criatura.Estado.ALERTA or c.estado == Criatura.Estado.ATURDIDA

## Si las dos mitades siguen sueltas pasado un rato, se buscan y se juntan.
func _reunir_mitades(mesa: Mesa, dt: float) -> void:
	for c: Criatura in criaturas:
		if not c.activa or not c.partida:
			continue
		var m := mitades(c)
		if m.size() != 2:
			continue
		var a: Criatura = m[0]
		var b: Criatura = m[1]
		c.t_partida += dt
		var buscan := _suelta_en_la_plaza(a) and _suelta_en_la_plaza(b) \
			and c.t_partida >= t_reunion
		a.reuniendose = buscan
		b.reuniendose = buscan
		if not buscan or a.pos.distance_to(b.pos) > radio_reunion:
			continue
		var donde := (a.pos + b.pos) * 0.5
		for g: Criatura in m:
			var mitad: Criatura = g
			mitad.reuniendose = false
			mitad.vel = Vector2.ZERO
			mitad.espera = -1.0
			mitad.cambiar(Criatura.Estado.FUERA)
		c.partida = false
		c.pos = donde
		c.vel = Vector2.ZERO
		c.bote_u = -1.0
		c.nodo = NODO_CENTRO
		c.destino = NODO_CENTRO
		c.cambiar(Criatura.Estado.APARECER)
		criatura_reunida.emit(c, donde)
		_mirar(mesa, c)

# ---------------------------------------------------------- TANQUE: volcado

func _volcada(mesa: Mesa, c: Criatura) -> void:
	c.vel = Vector2.ZERO
	_mirar(mesa, c)
	if c.t_estado >= t_volcada:
		# Se da la vuelta solo. Hay que volver a pillarle la espalda.
		criatura_rehecha.emit(c)
		c.cambiar(Criatura.Estado.ATURDIDA)

# ------------------------------------------------------- recoger y asegurar

func _recoger(c: Criatura, b: Bola, punto: Vector2) -> void:
	c.portadora = b
	c.vel = Vector2.ZERO
	c.bote_u = -1.0
	c.reuniendose = false
	c.cambiar(Criatura.Estado.EN_BOLA)
	criatura_recogida.emit(c, punto)

func _asegurar(c: Criatura, punto: Vector2) -> void:
	c.portadora = null
	c.asegurada = true
	c.espera = -1.0
	c.cambiar(Criatura.Estado.FUERA)
	if c.madre < 0:
		capturas += 1
		criatura_asegurada.emit(c, punto)
	else:
		# Una mitad a salvo. La entera cuenta cuando lo están las dos.
		criatura_asegurada.emit(c, punto)
		var entera: Criatura = criaturas[c.madre]
		var todas := true
		for g: Criatura in mitades(entera):
			if not g.asegurada:
				todas = false
		if todas:
			entera.partida = false
			entera.asegurada = true
			capturas += 1
			criatura_asegurada.emit(entera, punto)
	_comprobar_ola()

## La bola que la llevaba se ha perdido: se escapa, y vuelve a la plaza.
func _soltar(c: Criatura) -> void:
	var punto: Vector2 = c.pos
	c.portadora = null
	c.vel = Vector2.ZERO
	c.miedo = miedo_al_rehacerse if c.especie == "corredor" else 0.0
	c.espera = t_reaparecer
	c.cambiar(Criatura.Estado.FUERA)
	criatura_escapada.emit(c, punto)

# ------------------------------------------------------------ entrar y salir

func _fuera(mesa: Mesa, c: Criatura, dt: float) -> void:
	if c.espera < 0.0:
		return
	c.espera -= dt
	if c.espera > 0.0:
		return
	var n := _nodo_de_entrada(mesa, c)
	c.pos = nodos[n]
	c.vel = Vector2.ZERO
	c.nodo = n
	c.destino = n
	c.bote_u = -1.0
	c.espera = 0.0
	c.cambiar(Criatura.Estado.APARECER)
	criatura_aparecio.emit(c, c.pos)

## El nodo de la plaza más lejos de las bolas y de las otras criaturas.
func _nodo_de_entrada(mesa: Mesa, c: Criatura) -> int:
	var mejor := NODO_CENTRO
	var nota := -INF
	for i in PLAZA.size():
		var pt := nodos[i]
		var n := 400.0
		for b in mesa.bolas:
			if b.viva and not b.en_carril:
				n = minf(n, pt.distance_to(b.pos))
		for otra: Criatura in criaturas:
			if otra != c and otra.activa and otra.a_la_vista():
				n = minf(n, pt.distance_to(otra.pos) * 1.5)
		if n > nota:
			nota = n
			mejor = i
	return mejor

## Lo que quedó a medias al caerse de la plaza se resuelve al volver: un TANQUE
## al que le dieron por la espalda y salió volando hacia las palas reaparece ya
## panza arriba. Sin esto, el rescate se comía el golpe. (El miedo lleno de LUMI
## lo recoge `_al_grafo`.)
func _tras_aparecer(mesa: Mesa, c: Criatura) -> void:
	if c.volcando:
		c.volcando = false
		c.cambiar(Criatura.Estado.VOLCADA)
		criatura_volcada.emit(c, c.pos)
		return
	_al_grafo(mesa, c, false)

## Vuelve a la plaza desde donde esté —después de volar, de aparecer, de
## rehacerse—: recta al nodo más cercano que vea con sitio. Si no ve ninguno,
## rescate.
func _al_grafo(mesa: Mesa, c: Criatura, huyendo: bool) -> void:
	# MIEDO LLENO Y VUELVE A ANDAR: se acorrala aquí, que es por donde pasan
	# todas —la que sale de aturdida, la apartada, la rescatada—. Antes solo se
	# miraba al aterrizar de un golpe, y una LUMI a la que el último susto le
	# llegaba aturdida salía corriendo con el aro lleno y se iba a esconder.
	# No se realimenta: `_acorralada` baja el miedo antes de volver a llamar.
	if c.especie == "corredor" and c.miedo >= 1.0:
		_acorralar(c)
		return
	var mejor := -1
	var dist := INF
	for i in PLAZA.size():
		var d := c.pos.distance_to(nodos[i])
		if d >= dist:
			continue
		# Dos píxeles de manga: después de rebotar se queda TOCANDO lo que la
		# paró, y con su radio entero no cabría ni donde está.
		if d < 1.0 or paso_libre(mesa, c.pos, nodos[i], c.radio - 2.0):
			dist = d
			mejor = i
	if mejor < 0:
		sin_salida += 1
		_rescatar(c)
		return
	c.nodo = mejor
	c.destino = mejor
	c.espera = 0.0
	c.bote_u = -1.0
	c.bote_reloj = 0.0
	c.t_huyendo = 0.0
	c.t_sin_bola = 0.0
	c.t_vigia = 0.0
	c.pos_vigia = c.pos
	if huyendo and c.especie != "escarabajo":
		c.cambiar(Criatura.Estado.HUIR)
	else:
		c.cambiar(Criatura.Estado.CORRER)

## El rescate: ha acabado donde no puede estar. Se deshace y vuelve a salir por
## la plaza, con el miedo que llevaba. Se cuenta.
func _rescatar(c: Criatura) -> void:
	var punto: Vector2 = c.pos
	rescates += 1
	c.vel = Vector2.ZERO
	c.empujada = false
	c.espera = t_reaparecer
	c.cambiar(Criatura.Estado.FUERA)
	criatura_rescatada.emit(c, punto)

## El vigilante: tres segundos queriendo andar sin moverse del sitio es un fallo
## de quien la mueve. La pone en su destino y lo cuenta.
func _vigia(c: Criatura, dt: float) -> void:
	if not c.a_pie() or c.espera > 0.0 or c.destino < 0 \
			or c.pos.distance_to(nodos[c.destino]) < 1.0:
		c.t_vigia = 0.0
		c.pos_vigia = c.pos
		return
	c.t_vigia += dt
	if c.t_vigia < 3.0:
		return
	if c.pos.distance_to(c.pos_vigia) < 4.0:
		saltos_de_vigia += 1
		c.pos = nodos[c.destino]
	c.t_vigia = 0.0
	c.pos_vigia = c.pos

# ----------------------------------------------------------------------- olas

func _comprobar_ola() -> void:
	var hay := false
	for c: Criatura in criaturas:
		if c.principal and c.activa:
			hay = true
			if not c.asegurada:
				return
	if hay and _espera_ola < 0.0:
		_espera_ola = t_entre_olas
		caza_completa.emit(ola)

func _ola_nueva(dt: float) -> void:
	if _espera_ola < 0.0:
		return
	_espera_ola -= dt
	if _espera_ola > 0.0:
		return
	_espera_ola = -1.0
	ola += 1
	for c: Criatura in criaturas:
		_reiniciar(c)
	_repartir_entradas()

func _reiniciar(c: Criatura) -> void:
	c.asegurada = false
	c.partida = false
	c.reuniendose = false
	c.volcando = false
	c.empujada = false
	c.portadora = null
	c.miedo = 0.0
	c.golpes = 0
	c.vel = Vector2.ZERO
	c.bote_u = -1.0
	c.espera = -1.0
	c.cambiar(Criatura.Estado.FUERA)

func pendientes() -> int:
	var n := 0
	for c: Criatura in criaturas:
		if c.principal and c.activa and not c.asegurada:
			n += 1
	return n

## Qué está haciendo, en dos palabras, para el marcador.
func estado_de(c: Criatura) -> String:
	if not c.activa:
		return "FUERA DE JUEGO"
	if c.asegurada:
		return "ASEGURADA"
	if c.partida:
		var sueltas := 0
		var a_salvo := 0
		var en_bola := 0
		for g: Criatura in mitades(c):
			if g.asegurada:
				a_salvo += 1
			elif g.estado == Criatura.Estado.EN_BOLA:
				en_bola += 1
			else:
				sueltas += 1
		if en_bola > 0:
			return "MITAD EN LA BOLA"
		return "PARTIDA · %d A SALVO" % a_salvo if a_salvo > 0 else "PARTIDA EN DOS"
	match c.estado:
		Criatura.Estado.ACORRALADA:
			return "ACORRALADA"
		Criatura.Estado.VOLCADA:
			return "PANZA ARRIBA"
		Criatura.Estado.ESCONDIDA:
			return "ESCONDIDA"
		Criatura.Estado.EN_BOLA:
			return "EN LA BOLA"
		Criatura.Estado.ATURDIDA:
			return "ATURDIDA"
		Criatura.Estado.HUIR, Criatura.Estado.ALERTA:
			return "HUYENDO"
		Criatura.Estado.FUERA, Criatura.Estado.APARECER:
			return "LLEGANDO"
	return "SUELTA"

# ------------------------------------------------- las teclas de la prueba

## Pone o quita una especie entera. Es de la prueba, no del juego.
func activar(especie: String, si: bool) -> void:
	for c: Criatura in criaturas:
		if c.especie != especie:
			continue
		c.activa = si
		_reiniciar(c)
		for g: Criatura in mitades(c):
			g.activa = si
			_reiniciar(g)
		if si:
			c.espera = 0.6
	if _espera_ola >= 0.0 and pendientes() > 0:
		_espera_ola = -1.0
	elif not si and _espera_ola < 0.0 and pendientes() == 0:
		# Al QUITAR la última que faltaba, la ola se cierra sola —sin premio:
		# nadie la ha capturado—. Sin esto no quedaba nada que asegurar y la
		# mesa se quedaba vacía para siempre.
		for c: Criatura in criaturas:
			if c.principal and c.activa:
				_espera_ola = t_entre_olas
				break

## Fuerza un suceso a mano. Solo para poder MIRAR cada estado en una captura sin
## esperar a acertar con la bola: no pasa por el choque.
func forzar(mesa: Mesa, c: Criatura, que: String) -> void:
	if not c.activa or not c.golpeable():
		return
	match que:
		"golpe":
			if c.especie == "saltarin":
				_partir(c, Vector2.UP, c.pos)
			else:
				c.vel = Vector2(0.7, -0.7).normalized() * 380.0
				if c.especie == "corredor":
					c.miedo = _lleno(c.miedo + miedo_golpe)
				elif c.especie == "escarabajo":
					c.volcando = true
				c.empujada = false
				c.cambiar(Criatura.Estado.VOLAR)
			criatura_golpeada.emit(c, c.pos, 400.0, Vector2.UP)
		"rendir":
			if c.especie == "corredor":
				_acorralar(c)
			elif c.especie == "escarabajo":
				c.cambiar(Criatura.Estado.VOLCADA)
				criatura_volcada.emit(c, c.pos)
		"recoger":
			var b := _bola_mas_cercana(mesa, c)
			if b != null and c.rendida():
				_recoger(c, b, c.pos)
