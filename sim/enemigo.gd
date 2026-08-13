class_name Enemigo
extends RefCounted

## Un enemigo en combate: la definición de data/enemigos.json más su vida actual.

var id: String
var nombre: String
var vida_maxima: int
var vida: int
var ataque: int
## Segundos que tarda SU reloj en cargar. 0 = el del parámetro general.
##
## POR QUÉ ES DEL ENEMIGO Y NO GLOBAL: el coste de un combate es
## `tiempo/reloj × ataque + bolas × drenaje`, o sea que crece con lo que dura.
## Al alargar los combates a 2-5 minutos, con un reloj único todos los enemigos
## acababan costando casi lo mismo en proporción y el enemigo duro dejaba de
## doler más: dolía más rato. Con el reloj suyo se separan las dos cosas que
## antes iban pegadas: **la vida dice cuánto DURA y el reloj dice cuánto
## APRIETA**.
var reloj: float
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
	reloj = float(datos.get("reloj", 0.0))
	sprite = str(datos.get("sprite", ""))
	flota = bool(datos.get("flota", false))

func vivo() -> bool:
	return vida > 0

## Devuelve el daño realmente aplicado (nunca más que la vida que le quedaba).
func recibir(dano: int) -> int:
	var real := clampi(dano, 0, vida)
	vida -= real
	return real
