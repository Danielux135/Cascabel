class_name Plataforma
extends RefCounted

## Una región elevada con borde. Es la mitad barata del sistema de capas: la
## plataforma no colisiona con nada y no empuja a nadie. Lo único que hace es
## contestar a una pregunta —¿la bola sigue encima?— y, cuando la respuesta es
## que no, la bola CAE a la capa de abajo.
##
## Salirse del borde de una plataforma y caerse de una rampa que no corona son
## el mismo evento (`Mesa.bola_cayo`) a propósito: en una máquina de verdad se
## sienten igual, y tratarlos distinto obligaría a que la vista, el sonido y el
## combate se enteraran dos veces de lo mismo.
##
## Las paredes de la plataforma, si las lleva, son colisionadores normales con
## la máscara puesta a su capa. Aquí no hay ninguna: una plataforma con el borde
## amurallado por los cuatro lados no es una plataforma, es una habitación.

var nombre := ""
## En qué capa deja a la bola que está encima.
var capa: int = Colisionador.CAPA_ALTA
## A dónde cae quien se sale. Normalmente el tablero.
var capa_debajo: int = Colisionador.CAPA_TABLERO

## La forma. Si `poligono` tiene puntos manda él; si no, el rectángulo. Las dos
## porque la planta alta va a querer siluetas y una prueba no.
var region := Rect2()
var poligono := PackedVector2Array()

func _init(la_region: Rect2 = Rect2(), la_capa: int = Colisionador.CAPA_ALTA,
		debajo: int = Colisionador.CAPA_TABLERO) -> void:
	region = la_region
	capa = la_capa
	capa_debajo = debajo

## Se mide contra el CENTRO de la bola, no contra su borde. Con el borde, la
## bola se caería con medio cuerpo todavía apoyado: en una mesa de verdad se
## vuelca cuando pasa el centro de masa.
func contiene(pos: Vector2) -> bool:
	if poligono.size() >= 3:
		return Geometry2D.is_point_in_polygon(pos, poligono)
	return region.has_point(pos)
