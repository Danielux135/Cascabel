class_name Rampa
extends RefCounted

## Una rampa es una CURVA, no paredes.
##
## La bola se desengancha del cuerpo físico al entrar, recorre la curva a la
## velocidad con la que entró, y al salir vuelve a la física con la velocidad
## tangente. Determinista y sin atascos. Construirlas con paredes y simularlas
## es el error que hunde los pinballs 2D.
##
## Es además lo que permite que la mesa mida 1300 sin tocar la física: con
## gravedad 1750 y tope de 1500 px/s la bola no puede subir más de 643 px por
## sus propios medios, así que a la zona alta solo se llega enganchada aquí.

## Qué paga completar este recorrido. La mesa dice QUÉ es cada rampa y
## ParametrosCombate cuánto vale: geometría aquí, balance allí.
## CAZA va el último: los ordinales de los otros tres no se tocan.
enum Premio { DANO, DANO_FUERTE, MULTIPLICADOR, CAZA }
var premio: int = Premio.DANO
var nombre := ""

var puntos := PackedVector2Array()
var largo: float = 0.0
var entrada_radio: float = 18.0
## Por debajo de esta velocidad la bola no engancha y rebota de largo. Es lo que
## convierte la entrada en una habilidad y no en un accidente.
var velocidad_minima: float = 500.0
## Una órbita se recorre en los dos sentidos, como las de verdad.
var bidireccional := true

## Con cuánta de la velocidad de entrada sale la bola al terminar el recorrido.
## A 1,0 sale como entró. Existe porque un recorrido puede tener que devolver la
## bola MÁS LENTA de lo que entró para que se pueda jugar: el cañón salía a 900
## px/s cruzando el campo y Daniel no llegaba a cazarla nunca, así que su premio
## era en la práctica perder la bola.
var factor_salida: float = 1.0

# ------------------------------------------------------------- capas de altura

## Qué capa hay en cada boca. Con las dos en el tablero —lo de siempre— una
## rampa se comporta EXACTAMENTE como antes: sube y baja sin cambiar de altura.
## Una rampa a una plataforma pone `capa_salida = CAPA_ALTA`; un túnel se mete
## por debajo y vuelve, así que sus dos bocas siguen en el tablero.
var capa_entrada: int = Colisionador.CAPA_TABLERO
var capa_salida: int = Colisionador.CAPA_TABLERO

## Va por DEBAJO del tablero. No cambia la física —una rampa nunca colisiona con
## nada— pero sí el dibujo: se pinta oscura y la bola no se ve mientras la
## recorre. Es lo único que separa un túnel de una rampa.
var subterranea := false

# ------------------------------------------------- la rampa que no siempre sube

## `PROPÓSITO.md` §6. A 0 esto está APAGADO y la rampa es la determinista de
## siempre: entras y sales. Por encima de 0, la curva tiene cuesta.
##
## El modelo es energía, no una escalera de casos: subir la rampa entera cuesta
## la energía cinética de `velocidad_escape * UMBRAL_CORONA`, así que
##
##     v(recorrido)² = v_entrada² − (velocidad_escape·0,6)² · recorrido/largo
##
## y de ahí salen solas las tres bandas del diseño, sin fronteras escritas a
## mano y sin integrar nada (la velocidad se calcula desde la distancia, no se
## acumula, así que no hay deriva y el recorrido sigue siendo determinista):
##
## | Entras a           | Qué pasa                                   |
## |--------------------|--------------------------------------------|
## | < 60 % de escape   | se para a mitad de cuesta                  |
## | 60-100 %           | corona y sale despacio                     |
## | > 100 %            | sale limpia y cada vez más rápido          |
var velocidad_escape: float = 0.0
## Dónde está la frontera de "no llego", en fracción de `velocidad_escape`. Es
## el 60 % del diseño y está aquí y no escrito dentro de la cuenta porque es
## tacto: se juzga jugando.
const UMBRAL_CORONA := 0.6
## Por debajo de esto se considera parada. No es cero para que una bola que se
## queda a un pelo no tarde un segundo entero en decidirse.
const VELOCIDAD_ESTANCADA := 8.0

## Un CARRIL (abierta) o un TUBO (cerrada), y es lo que decide qué pasa al no
## llegar: el tubo te devuelve por donde entraste, el carril te suelta al
## tablero. Es una propiedad por rampa, no una decisión global.
var abierta := false

## Cuánto ha subido la bola desde la boca por la que entró.
func recorrido(distancia: float, subida: int) -> float:
	return distancia if subida > 0 else largo - distancia

## La velocidad que le queda a la bola tras haber subido `recorrido`. Con
## `velocidad_escape` a 0 devuelve la de entrada tal cual, que es lo que deja
## intacta toda la mesa de hoy.
func velocidad_en(v_entrada: float, recorrido_hecho: float) -> float:
	if velocidad_escape <= 0.0 or largo <= 0.0:
		return v_entrada
	var coste := velocidad_escape * UMBRAL_CORONA
	var v2 := v_entrada * v_entrada \
		- coste * coste * clampf(recorrido_hecho / largo, 0.0, 1.0)
	return sqrt(maxf(v2, 0.0))

## ¿Llega arriba entrando a esta velocidad? Es la cuenta de arriba con el
## recorrido entero, y sirve para dibujar la banda antes de que pase.
func corona(v_entrada: float) -> bool:
	return velocidad_escape <= 0.0 \
		or v_entrada > velocidad_escape * UMBRAL_CORONA

var _acumulado := PackedFloat32Array()

func _init(control: PackedVector2Array, resolucion: int = 14) -> void:
	puntos = _muestrear(control, resolucion)
	_medir()

# ------------------------------------------------------------------ la curva

static func _catmull(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2,
		t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)

## Catmull-Rom por los puntos de control: la curva pasa POR ellos, que es lo
## que hace que se puedan colocar a mano mirando la mesa.
static func _muestrear(c: PackedVector2Array, res: int) -> PackedVector2Array:
	if c.size() < 2:
		return c
	var salida := PackedVector2Array()
	for i in c.size() - 1:
		var p0 := c[maxi(i - 1, 0)]
		var p1 := c[i]
		var p2 := c[i + 1]
		var p3 := c[mini(i + 2, c.size() - 1)]
		for j in res:
			salida.append(_catmull(p0, p1, p2, p3, float(j) / float(res)))
	salida.append(c[c.size() - 1])
	return salida

func _medir() -> void:
	_acumulado.resize(puntos.size())
	_acumulado[0] = 0.0
	for i in range(1, puntos.size()):
		_acumulado[i] = _acumulado[i - 1] + puntos[i - 1].distance_to(puntos[i])
	largo = _acumulado[_acumulado.size() - 1]

func _indice(d: float) -> int:
	var lo := 0
	var hi := _acumulado.size() - 1
	while lo < hi - 1:
		var med := (lo + hi) / 2
		if _acumulado[med] <= d:
			lo = med
		else:
			hi = med
	return lo

func punto_en(d: float) -> Vector2:
	var dd := clampf(d, 0.0, largo)
	var i := _indice(dd)
	var tramo := _acumulado[i + 1] - _acumulado[i]
	if tramo <= 0.0001:
		return puntos[i]
	return puntos[i].lerp(puntos[i + 1], (dd - _acumulado[i]) / tramo)

## Unitaria, en el sentido de avance de la curva.
func tangente_en(d: float) -> Vector2:
	var i := _indice(clampf(d, 0.0, largo))
	return (puntos[i + 1] - puntos[i]).normalized()

# ----------------------------------------------------------------- la entrada

func boca(sentido: int) -> Vector2:
	return puntos[0] if sentido > 0 else puntos[puntos.size() - 1]

## +1 si entra por la boca de abajo, -1 si por la de arriba, 0 si no engancha.
## Hace falta ir bastante en la dirección de la rampa: rozarla de lado no vale.
func sentido_entrada(pos: Vector2, vel: Vector2) -> int:
	if vel.length() < velocidad_minima:
		return 0
	var dir := vel.normalized()
	if pos.distance_to(puntos[0]) < entrada_radio \
			and dir.dot(tangente_en(0.0)) > 0.45:
		return 1
	if bidireccional and pos.distance_to(puntos[puntos.size() - 1]) < entrada_radio \
			and dir.dot(-tangente_en(largo)) > 0.45:
		return -1
	return 0
