class_name Platillo
extends RefCounted

## Un platillo captura: la bola desaparece, hay una pausa, y sale con un
## impulso fijo. Esa pausa es de las mejores sensaciones del pinball, así que
## el tiempo está expuesto para ajustarlo jugando.

var centro: Vector2
var radio: float = 14.0
var tiempo_captura: float = 0.9
var impulso: float = 780.0
## Hacia dónde escupe. Unitaria.
var direccion := Vector2(0, -1)

func _init(el_centro: Vector2, la_direccion: Vector2, el_radio: float,
		el_tiempo: float, el_impulso: float) -> void:
	centro = el_centro
	direccion = la_direccion.normalized()
	radio = el_radio
	tiempo_captura = el_tiempo
	impulso = el_impulso

func captura(pos: Vector2) -> bool:
	return pos.distance_to(centro) < radio
