class_name NodoMapa
extends RefCounted

## Un nodo del mapa del run.
##
## Los tipos que faltan de `DISEÑO.md` §9 —tienda y evento— NO están aquí a
## propósito: la tienda necesita chatarra y reliquias, que son Fase 4 y Fase 6.
## Meterlos ahora como nodos vacíos sería justo el fallo que `PLAN.md` dice que
## hay que evitar: acumular sistemas a medias sobre un núcleo sin terminar.

enum Tipo { COMBATE, ELITE, DESCANSO, JEFE }

static func nombre_de(tipo: int) -> String:
	match tipo:
		Tipo.COMBATE: return "COMBATE"
		Tipo.ELITE: return "ELITE"
		Tipo.DESCANSO: return "DESCANSO"
		Tipo.JEFE: return "JEFE"
	return "?"

var tipo: int = Tipo.COMBATE
var acto: int = 0
var fila: int = 0
var columna: int = 0
## Columnas de la fila siguiente a las que se puede ir desde aquí. Es lo que
## convierte el mapa en una decisión: si todos los nodos llevaran a todos, no
## habría rama que elegir.
var salidas: Array[int] = []

## Qué enemigo toca, decidido al generar el mapa y no al llegar: tienes que
## poder mirar el camino y decidir por dónde vas ANTES de meterte.
var enemigo: Dictionary = {}

func es_combate() -> bool:
	return tipo == Tipo.COMBATE or tipo == Tipo.ELITE or tipo == Tipo.JEFE
