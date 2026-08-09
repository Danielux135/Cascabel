class_name ParametrosAnimacion
extends RefCounted

## Todo el tacto visual, en un sitio. Como con la física: se ajusta mirándolo,
## no calculándolo, así que está para tocarlo.
##
## REGLA DE LA REJILLA: todo lo que deforme o mueva un sprite va en PÍXELES
## ENTEROS. Una escala continua sobre pixelart deja filas de píxel de distinto
## grosor y el sprite hierve. Por eso las amplitudes son `int` y no `float`.

# --- Respiración de los enemigos (squash y stretch, pivote en los pies) ---
## Cuántos píxeles crece y encoge de alto. El ancho compensa al revés, para que
## parezca que conserva volumen.
var respiracion_pixeles: int = 2
var respiracion_periodo: float = 2.4
## Los que flotan (la calavera llameante) no se apoyan en el suelo.
var flotante_altura: int = 10
var flotante_pixeles: int = 3
var flotante_periodo: float = 2.8

# --- Destello blanco al recibir daño (shader) ---
var destello_duracion: float = 0.18
var destello_color := Color(1, 1, 1)

# --- Embestida al atacar ---
## Hacia abajo, que es donde está el jugador. También en píxeles enteros.
var embestida_pixeles: int = 14
var embestida_ida: float = 0.10      # sale rápido
var embestida_vuelta: float = 0.38   # y vuelve despacio

# --- Disolución al morir, píxel a píxel ---
var disolucion_duracion: float = 1.1
## Franja de píxeles a punto de irse que se enciende antes de desaparecer.
var disolucion_borde: float = 0.14
var disolucion_color_borde := Color("E8814A")

# --- Bumpers ---
var bumper_destello_duracion: float = 0.22
## Cuánto crece el bumper al golpearlo. Entero, y el dibujo redondea el rect.
var bumper_crecimiento_pixeles: int = 6

# --- Girador ---
## Ocho escorzos pregenerados, no rotación continua (ver render/girador.gd).
var girador_fotogramas: int = 8
## Fotogramas por segundo cuando le entra la bola a tope (velocidad_maxima).
var girador_velocidad_maxima: float = 26.0
var girador_frenado: float = 9.0

# --- Impacto ---
## Hitstop: se congela la simulación unos milisegundos en los golpes fuertes.
## La capa visual sigue corriendo, así que el destello se ve DURANTE el parón,
## que es lo que le da el golpe seco.
var hitstop: float = 0.070
## Por debajo de esta velocidad de impacto no se congela nada: si no, un bumper
## rozado daría tirones constantes.
var hitstop_fuerza_minima: float = 420.0

## Sacudida de cámara. El desplazamiento se redondea SIEMPRE a píxel entero: a
## medio píxel el juego entero se ve borroso durante la sacudida.
var sacudida_maxima: float = 5.0
var sacudida_frenado: float = 26.0
var sacudida_bumper: float = 2.0
var sacudida_dano: float = 2.5
var sacudida_ataque: float = 4.0
var sacudida_muerte: float = 5.0

## Cuánto hay que congelar por un impacto de esta fuerza. 0 = no congelar.
func congelacion(fuerza: float) -> float:
	return hitstop if fuerza >= hitstop_fuerza_minima else 0.0

## Desplazamiento de la sacudida para una amplitud dada. Redondeado SIEMPRE a
## píxel entero: a medio píxel, con filtro nearest y escalado entero, la mesa
## se ve borrosa justo en el momento en el que más se mira.
func desplazamiento_sacudida(amplitud: float, rng: RandomNumberGenerator) -> Vector2:
	var a := clampf(amplitud, 0.0, sacudida_maxima)
	return Vector2(roundf(rng.randf_range(-a, a)), roundf(rng.randf_range(-a, a)))
