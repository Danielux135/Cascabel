class_name Girador
extends RefCounted

## Los fotogramas del girador, pregenerados UNA VEZ al arrancar en vez de
## rotarlo en vivo.
##
## El girador real gira sobre su barra horizontal, así que lo que se ve es la
## paleta escorzándose: alta de frente, una raya de canto, alta otra vez. Se
## generan los ocho escorzos con altura de PÍXELES ENTEROS y recentrados sobre
## la barra. Escalar en vivo con un factor continuo dejaría, en cada fotograma,
## filas de píxel de distinto grosor, y a 26 fotogramas por segundo eso hierve.

## Devuelve `cantidad` texturas de `tamano` x `tamano`, una por escorzo.
##
## Se generan YA al tamaño con el que se van a dibujar, para poder pintarlas
## 1:1. Generarlas a 64 y dibujarlas a 32 volvería a partir píxeles y tiraría
## por tierra todo el cuidado de más abajo.
static func generar(origen: Texture2D, cantidad: int, tamano: int) -> Array[Texture2D]:
	var fotogramas: Array[Texture2D] = []
	if origen == null or cantidad <= 0:
		return fotogramas
	var base := origen.get_image()
	base.resize(tamano, tamano, Image.INTERPOLATE_NEAREST)
	var ancho := base.get_width()
	var alto := base.get_height()
	for i in cantidad:
		var angulo := float(i) / float(cantidad) * PI
		# Mínimo 2 px: de canto tiene que quedar una raya, no desaparecer.
		var alto_escorzo := maxi(int(roundf(float(alto) * absf(cos(angulo)))), 2)
		var escorzo := base.duplicate() as Image
		escorzo.resize(ancho, alto_escorzo, Image.INTERPOLATE_NEAREST)
		var lienzo := Image.create_empty(ancho, alto, false, base.get_format())
		lienzo.fill(Color(0, 0, 0, 0))
		# División entera: el recentrado también cae en la rejilla.
		lienzo.blit_rect(escorzo, Rect2i(0, 0, ancho, alto_escorzo),
			Vector2i(0, (alto - alto_escorzo) / 2))
		fotogramas.append(ImageTexture.create_from_image(lienzo))
	return fotogramas
