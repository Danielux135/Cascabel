class_name Bola
extends RefCounted

## Una bola. TODO lo que pasa por bola vive aquí y nada en `Mesa`, y eso es lo
## que ha hecho barata la multibola: pasar de una bola a N no ha sido repartir
## estado, ha sido mover a esta clase el que ya estaba mal puesto (el
## temporizador del ball search y el "dentro del girador" eran de la mesa, y con
## dos bolas eso significa que una le apaga el aviso a la otra).

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

## Cuánto lleva esta bola quieta. El ball search es POR BOLA: con una bola
## dormida en un rincón y otra en pleno vuelo, empujar a las dos sería empujar la
## que estás jugando.
var busqueda: float = 0.0
## Si esta bola está apoyada en una pala pulsada. También por bola, y por lo
## mismo: la cuna de la izquierda no puede desactivarle el ball search a la bola
## que se ha quedado muerta arriba del todo.
var tocando_flipper := false
## Un booleano por girador: si esta bola está dentro de él. Los giradores se
## disparan al ENTRAR, y sin un registro por bola la segunda bola que cruza el
## mismo girador no cobraría.
var girador_dentro: Array[bool] = []

func libre() -> bool:
	return rampa < 0 and platillo < 0

func velocidad() -> float:
	return vel.length()
