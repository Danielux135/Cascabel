class_name Reproductor
extends RefCounted

## PASA LOS FOTOGRAMAS DE UNA `HojaAnimada`. Estado actual, fotograma actual y
## acumulador de tiempo, y nada más: no dibuja, no sabe dónde está y no toca la
## rejilla de píxeles. Eso es de quien dibuja.
##
## TRES DECISIONES QUE NO SON DE ESTILO:
##
## 1. **Se congela con el hitstop.** El parón congela la SIMULACIÓN y no el
##    dibujado —el destello y la sacudida se ven durante la parada, que es lo
##    que hace el golpe seco—, pero el fotograma de golpe no: si el reproductor
##    siguiera corriendo, los 70 ms de parón se comerían justo el fotograma que
##    el parón quiere enseñar. Por eso `avanzar` recibe `congelado`.
##
## 2. **Un estado que la hoja no tiene se cae a `idle`, y se puede preguntar.**
##    Hoy `cr_brasa` y `cr_calavera` solo traen `idle`, así que pedirles `golpe`
##    tiene que hacer algo razonable. Lo peligroso sería dibujar nada: un sprite
##    en blanco no da ningún error. `estado_pedido` guarda lo que se pidió y
##    `estado` lo que de verdad se está reproduciendo, así que la diferencia se
##    ve en una prueba en vez de descubrirse jugando.
##
## 3. **El acumulador se resta, no se pone a cero.** Poner a cero pierde el
##    sobrante de cada fotograma y a 10 fps con delta de 60 Hz eso acumula
##    deriva: el bucle de ocho tarda de más y dos bichos puestos a la vez se
##    desincronizan solos.

var hoja: HojaAnimada
## Lo que se está reproduciendo de verdad.
var estado := HojaAnimada.QUIETO
## Lo último que se pidió, aunque la hoja no lo tuviera.
var estado_pedido := HojaAnimada.QUIETO
var fotograma := 0

var _t := 0.0

func poner(la_hoja: HojaAnimada) -> void:
	hoja = la_hoja
	estado = HojaAnimada.QUIETO
	estado_pedido = HojaAnimada.QUIETO
	fotograma = 0
	_t = 0.0

func vacio() -> bool:
	return hoja == null or not hoja.tiene(estado)

## Pedir un estado. Los de un solo tiro se reinician aunque ya estuvieran
## puestos: dos golpes seguidos tienen que verse dos veces.
func pedir(el_estado: String) -> void:
	estado_pedido = el_estado
	var destino := el_estado
	if hoja == null or not hoja.tiene(destino):
		destino = HojaAnimada.QUIETO
	if destino == estado and HojaAnimada.va_en_bucle(destino):
		return
	estado = destino
	fotograma = 0
	_t = 0.0

## True cuando un estado de un solo tiro ha llegado al final y se ha quedado
## ahí. Solo puede pasar con `muerte`: los demás vuelven a `idle` solos.
func terminado() -> bool:
	if hoja == null or HojaAnimada.va_en_bucle(estado):
		return false
	return estado == HojaAnimada.SE_QUEDA and fotograma >= hoja.cuantos(estado) - 1

func avanzar(delta: float, congelado: bool = false) -> void:
	if congelado or hoja == null or not hoja.tiene(estado):
		return
	var n := hoja.cuantos(estado)
	if n <= 1:
		return
	var paso := 1.0 / HojaAnimada.fps_de(estado)
	_t += delta
	# `while`, no `if`: con un delta gordo —el primer fotograma tras cargar, o
	# una pausa— hay que pasar los fotogramas que toquen, no uno.
	while _t >= paso:
		_t -= paso
		if HojaAnimada.va_en_bucle(estado):
			fotograma = (fotograma + 1) % n
		elif fotograma + 1 < n:
			fotograma += 1
		elif estado == HojaAnimada.SE_QUEDA:
			# Se queda clavada en el último y deja que la disolución termine.
			_t = 0.0
			return
		else:
			estado = HojaAnimada.QUIETO
			estado_pedido = HojaAnimada.QUIETO
			fotograma = 0
			n = hoja.cuantos(estado)
			if n <= 1:
				return

func textura() -> Texture2D:
	if hoja == null:
		return null
	return hoja.fotograma(estado, fotograma)
