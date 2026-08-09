class_name ParametrosCamara
extends RefCounted

## Las cuatro reglas de la cámara vertical de PLAN.md, con sus números.
## La 3 (píxeles enteros) no está aquí porque no es negociable: va en el código.

## Ventana base 640x360, escalado por enteros: x2 = 720p, x3 = 1080p, x4 = 1440p.
var ancho_visible: float = 640.0
var alto_visible: float = 360.0

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

## REGLA 2 — ancla inferior. Con la bola por debajo de esta línea (medida desde
## el fondo de la mesa) la cámara se fija abajo y no se mueve más: el tercio de
## los flippers es intocable.
var margen_ancla: float = 300.0

## REGLA 4 — zona muerta, o la cámara tiembla con cada rebote.
var zona_muerta: float = 45.0
var suavizado: float = 5.0
## Sin bola en juego (resolviendo, victoria) la cámara vuelve abajo, despacio.
var suavizado_reposo: float = 2.0
