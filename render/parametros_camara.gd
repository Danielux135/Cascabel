class_name ParametrosCamara
extends RefCounted

## Las cuatro reglas de la cámara vertical de PLAN.md, con sus números.
## La 3 (píxeles enteros) no está aquí porque no es negociable: va en el código.

## Ventana base 960x540, escalado por enteros: x2 = 1080p, x4 = 4K.
## Se ve el 41 % de la mesa (antes el 28 %) y quedan 560 px de escritorio a los
## lados, que es el sitio donde la fase 5 pone las ventanas. La mesa sigue
## midiendo 400 unidades de ancho: la física no cambia nada.
##
## OJO, ESTO NO ES UNA CONSTANTE: `VistaMesa` lo REESCRIBE con el tamaño real
## del viewport al arrancar y cada vez que cambia la ventana.
##
## El porqué, que es el fallo de "no me cuadra en el portátil": el proyecto está
## en `stretch/aspect = expand`, así que en una pantalla que no da 16:9 exacto el
## viewport CRECE y se ve más juego, no barras negras. Con estos dos números
## clavados en 960x540, la cáscara medía contra el viewport de verdad y el HUD,
## el mapa y la cámara medían contra 960x540: dos sistemas de coordenadas
## distintos para la misma pantalla, y todo desalineado por la diferencia.
##
## Los 960x540 se quedan como valor de partida porque son las proporciones con
## las que está diseñado todo y porque las pruebas headless no tienen ventana.
var ancho_visible: float = 960.0
var alto_visible: float = 540.0

## REGLA 1 — nunca persigue a una bola que cae: se adelanta.
## Cuántos píxeles mira POR DEBAJO de la bola mientras desciende. Con esto la
## bola sale en la mitad de arriba de la pantalla y siempre ves adónde va.
var adelanto: float = 110.0
## Subiendo no hace falta adelantarse. Lo que no puede pasar es perder los
## flippers de vista por irse detrás de una bola que sube.
var adelanto_subiendo: float = 0.0
## Y por si el suavizado se queda corto: la bola nunca puede acercarse a menos
## de esto del borde de la pantalla. Si pasa, la cámara salta en vez de
## quedarse atrás. Es la garantía dura de la regla 1.
var margen_bola: float = 24.0

## APAÑO PROVISIONAL. Por arriba hace falta más margen que por abajo, porque la
## franja del HUD son 58 px opacos pegados al borde superior y la bola se metía
## detrás justo en lo alto de la órbita: el tiro más largo de la mesa era el
## único que no se veía. Con esto la cámara nunca deja subir la bola por encima
## de la franja.
## Cuando la fase 5 rehaga la interfaz y el HUD deje de estar ahí, este número
## baja a `margen_bola` y ya.
var alto_franja_hud: float = 58.0
var margen_superior: float = 16.0

## REGLA 2 — ancla inferior. Con la bola por debajo de esta línea (medida desde
## el fondo de la mesa) la cámara se fija abajo y no se mueve más: el tercio de
## los flippers es intocable.
var margen_ancla: float = 300.0

## REGLA 4 — zona muerta, o la cámara tiembla con cada rebote.
var zona_muerta: float = 45.0
var suavizado: float = 5.0
## Sin bola en juego (resolviendo, victoria) la cámara vuelve abajo, despacio.
var suavizado_reposo: float = 2.0
