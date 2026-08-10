class_name Colisionador
extends RefCounted

## Cápsula estática: segmento a->b con un radio. Con a == b es un círculo.
## Todo el mundo de la mesa se monta con esto (paredes, arco teselado, bumpers,
## slingshots y los postes de goma).

enum Tipo { PARED, BUMPER, SLINGSHOT, POSTE, PUERTA, FLIPPER, TARGET }

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
	salida.append(Contacto.new(
		n, suma - dist, pos - n * radio_bola, Vector2.ZERO,
		restitucion, empuje, velocidad_minima, tipo, self, friccion))
