class_name ParametrosRun
extends RefCounted

## La forma del run. `DISEÑO.md` §9: tres actos, doce a quince combates, treinta
## a cuarenta minutos.
##
## Todo esto es provisional igual que el resto del balance, pero aquí el número
## que importa no es ninguno en concreto: es que la vida NO se cura entre
## combates. Ahí está la tensión del mapa entera. Si esto se toca, el mapa deja
## de tener decisiones y pasa a ser una lista de combates.

var actos: int = 3
## Filas de nodos por acto, sin contar la del jefe. Con 4 filas y 3 actos salen
## 12 nodos de camino más 3 jefes: los doce a quince combates de `DISEÑO.md`.
var filas_por_acto: int = 4
## Cuántos nodos puede haber en una fila. Con 3 hay bifurcación de verdad; con
## 2 el mapa es una escalera y la elección se nota poco.
var nodos_por_fila_max: int = 3
var nodos_por_fila_min: int = 2

## En qué fila del acto va el descanso. La penúltima: llegar al jefe decidiendo
## si curarte o no es la decisión que hace que el mapa importe.
var fila_descanso: int = 2
## A partir de qué fila pueden salir élites. En la primera no, o el run se
## decide antes de que hayas montado nada.
var fila_primera_elite: int = 1

## Cuánto cura un descanso, en fracción de la vida máxima. No cura del todo a
## propósito: si curara entero, descansar sería siempre la respuesta correcta y
## dejaría de ser una decisión.
var curacion_descanso: float = 0.30

## Cuánto más duro es un élite que un combate normal del mismo acto, en vida.
var factor_vida_elite: float = 1.35
## Y el jefe. Provisional del todo: los jefes de verdad son Fase 6, con sus
## fases y sus sprites de `assets/jefes/`. Aquí un jefe es todavía el enemigo
## más duro del acto con más vida, y eso NO cumple `DISEÑO.md` §8.
var factor_vida_jefe: float = 1.8
