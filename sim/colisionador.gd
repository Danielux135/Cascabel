class_name Colisionador
extends RefCounted

## Cápsula estática: segmento a->b con un radio. Con a == b es un círculo.
## Todo el mundo de la mesa se monta con esto (paredes, arco teselado, bumpers,
## slingshots y los postes de goma).

enum Tipo { PARED, BUMPER, SLINGSHOT, POSTE, PUERTA, FLIPPER, TARGET }

# ------------------------------------------------------------- capas de altura
#
# La mesa deja de ser plana. Una bola tiene un NIVEL y un colisionador solo
# existe en los suyos, que es lo que hace que una plataforma tenga borde, que un
# túnel pase por debajo del tablero y que dos recorridos se crucen sin tocarse.
#
# Los números son alturas, no índices: el túnel va por debajo del tablero y por
# eso vale −1. La máscara los mete en bits con `bit()`, que suma
# `DESPLAZAMIENTO` para que el túnel no pida un bit negativo.
#
# POR DEFECTO TODO COLISIONADOR ESTÁ EN TODAS LAS CAPAS. No es pereza: es lo
# único que deja la mesa de hoy —y toda su física medida— exactamente como
# estaba. Una capa se restringe cuando alguien la restringe a mano.

const CAPA_TUNEL := -1
const CAPA_TABLERO := 0
const CAPA_ALTA := 1
## Cuántas capas hay sitio para nombrar. Sobra de largo; está escrito para que
## una capa nueva no obligue a mirar si cabe.
const CAPAS_MAXIMAS := 8
const DESPLAZAMIENTO_CAPA := 1
## Todos los bits de las capas nombrables. Es el valor por defecto.
const TODAS := (1 << (CAPAS_MAXIMAS + DESPLAZAMIENTO_CAPA)) - 1

static func bit(capa: int) -> int:
	return 1 << (capa + DESPLAZAMIENTO_CAPA)

## Máscara a partir de una lista de capas: `mascara([CAPA_ALTA])`.
static func mascara(capas_lista: Array) -> int:
	var m := 0
	for c in capas_lista:
		m |= bit(int(c))
	return m

## En qué capas existe esto. `TODAS` = la mesa plana de siempre.
var capas: int = TODAS

func en_capa(capa: int) -> bool:
	return (capas & bit(capa)) != 0

var a: Vector2
var b: Vector2
var radio: float
var tipo: int
var restitucion: float
## Rozamiento de Coulomb. Lo pone la mesa por tipo de superficie al terminar de
## construirse: el metal casi no agarra, la goma sí.
var friccion: float = 0.0
var empuje: float
var velocidad_minima: float
var activo := true

## Puerta antirretorno: solo existe para una bola que ya está por encima de ella
## y va bajando. Desde abajo (subiendo por el carril) no está.
var una_direccion := false

## Por qué cara empuja. Unitaria, o cero si empuja por todas (los bumpers y los
## postes son redondos: no tienen espalda).
##
## Un slingshot SÍ tiene espalda, y en una máquina real la goma solo mira al
## campo. Aquí empujaba por los dos lados, y como va casi paralelo a la banda
## del outlane, una bola metida en ese pasillo recibía un patadón contra la
## pared, volvía, y otro patadón: se quedaba encerrada rebotando segundos.
## Medido: hasta 4,1 s a 340 px/s. Daniel lo mandó en una captura.
var cara := Vector2.ZERO

## Solo para targets: a qué banco pertenece. -1 si no es un target.
var banco: int = -1

var _aabb: Rect2
var _normal_degenerada := Vector2.UP

func _init(
		p_a: Vector2,
		p_b: Vector2,
		p_radio: float,
		p_tipo: int,
		p_restitucion: float,
		p_empuje: float = 0.0,
		p_velocidad_minima: float = 0.0) -> void:
	a = p_a
	b = p_b
	radio = p_radio
	tipo = p_tipo
	restitucion = p_restitucion
	empuje = p_empuje
	velocidad_minima = p_velocidad_minima
	_recalcular()

func _recalcular() -> void:
	_aabb = Rect2(a, Vector2.ZERO).expand(b).grow(radio)
	var d := b - a
	if d.length_squared() > 1e-8:
		_normal_degenerada = Vector2(-d.y, d.x).normalized()

## El centro de la cápsula. Con a == b es `a`, así que vale para todos.
func centro() -> Vector2:
	return (a + b) * 0.5

func punto_mas_cercano(p: Vector2) -> Vector2:
	var d := b - a
	var l2 := d.length_squared()
	if l2 < 1e-8:
		return a
	return a + d * clampf((p - a).dot(d) / l2, 0.0, 1.0)

func consultar(pos: Vector2, vel: Vector2, radio_bola: float, salida: Array) -> void:
	if not activo:
		return
	if una_direccion:
		if pos.y > (a.y + b.y) * 0.5 or vel.y < 0.0:
			return
	if not _aabb.grow(radio_bola).has_point(pos):
		return
	var c := punto_mas_cercano(pos)
	var d := pos - c
	var dist := d.length()
	var suma := radio + radio_bola
	if dist >= suma:
		return
	var n := d / dist if dist > 1e-4 else _normal_degenerada
	# Por la espalda no empuja, pero sigue siendo goma: rebota igual.
	var e := empuje
	if cara != Vector2.ZERO and n.dot(cara) < 0.25:
		e = 0.0
	salida.append(Contacto.new(
		n, suma - dist, pos - n * radio_bola, Vector2.ZERO,
		restitucion, e, velocidad_minima, tipo, self, friccion))
