class_name Enemigo
extends RefCounted

## Un enemigo en combate: la definición de data/enemigos.json más su vida actual.

var id: String
var nombre: String
var vida_maxima: int
var vida: int
var ataque: int
var sprite: String
## La calavera llameante flota: se dibuja con desplazamiento propio en vez de
## alinearse al suelo como los demás.
var flota: bool

func _init(datos: Dictionary) -> void:
	id = str(datos.get("id", ""))
	nombre = str(datos.get("nombre", "?"))
	vida_maxima = int(datos.get("vida", 100))
	vida = vida_maxima
	ataque = int(datos.get("ataque", 10))
	sprite = str(datos.get("sprite", ""))
	flota = bool(datos.get("flota", false))

func vivo() -> bool:
	return vida > 0

## Devuelve el daño realmente aplicado (nunca más que la vida que le quedaba).
func recibir(dano: int) -> int:
	var real := clampi(dano, 0, vida)
	vida -= real
	return real
