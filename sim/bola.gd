class_name Bola
extends RefCounted

var pos := Vector2.ZERO
var vel := Vector2.ZERO
var viva := false
## Mientras esté en el carril lanzador, el lanzador funciona y el ball search no.
var en_carril := true

## Enganchada a una rampa: mientras `rampa >= 0` no hay física, la bola recorre
## la curva. `rampa_sentido` es +1 o -1 (las órbitas se recorren en los dos).
var rampa: int = -1
var rampa_sentido: int = 1
var rampa_distancia: float = 0.0
var rampa_velocidad: float = 0.0

## Capturada en un platillo: quieta hasta que se agote `platillo_espera`.
var platillo: int = -1
var platillo_espera: float = 0.0

func libre() -> bool:
	return rampa < 0 and platillo < 0

func velocidad() -> float:
	return vel.length()
