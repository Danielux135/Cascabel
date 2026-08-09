class_name Bola
extends RefCounted

var pos := Vector2.ZERO
var vel := Vector2.ZERO
var viva := false
## Mientras esté en el carril lanzador, el lanzador funciona y el ball search no.
var en_carril := true

func velocidad() -> float:
	return vel.length()
