class_name Contacto
extends RefCounted

## Un contacto resuelto entre la bola y una superficie, en el momento del subpaso.
## `velocidad_superficie` es la clave del tacto de los flippers: el impulso se
## resuelve contra la velocidad RELATIVA de la bola respecto a la superficie,
## no contra su velocidad absoluta.

var normal: Vector2              # unitaria, apunta de la superficie hacia la bola
var profundidad: float           # penetración en px
var punto: Vector2               # punto de contacto sobre la superficie
var velocidad_superficie: Vector2
var restitucion: float
var empuje: float                # impulso extra a lo largo de la normal (bumpers)
var velocidad_minima: float      # umbral por debajo del cual el empuje no salta
var tipo: int                    # Colisionador.Tipo
var origen: Object

func _init(
		p_normal: Vector2,
		p_profundidad: float,
		p_punto: Vector2,
		p_velocidad_superficie: Vector2,
		p_restitucion: float,
		p_empuje: float,
		p_velocidad_minima: float,
		p_tipo: int,
		p_origen: Object) -> void:
	normal = p_normal
	profundidad = p_profundidad
	punto = p_punto
	velocidad_superficie = p_velocidad_superficie
	restitucion = p_restitucion
	empuje = p_empuje
	velocidad_minima = p_velocidad_minima
	tipo = p_tipo
	origen = p_origen
