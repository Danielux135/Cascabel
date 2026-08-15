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
## Cuántos píxeles mira POR DEBAJO de la bola mientras desciende. Este es el
## adelanto de una bola LENTA: el que manda de verdad es el de abajo.
var adelanto: float = 110.0
## Subiendo no hace falta adelantarse. Lo que no puede pasar es perder los
## flippers de vista por irse detrás de una bola que sube.
var adelanto_subiendo: float = 0.0

## EL ADELANTO SE MIDE EN TIEMPO, NO EN PÍXELES, y esta es la mitad del arreglo
## de "con la bola rápida no llegas a ver el flipper".
##
## Con un adelanto fijo de 110 px la cámara miraba siempre lo mismo por debajo
## de la bola, cayera a 300 o a 1900 px/s. A 1900 esos 110 px son 58 ms de
## juego: la cámara enseñaba el sitio donde la bola ya estaba, no aquel al que
## iba. Medido: el borde inferior de la pantalla llegaba a quedarse 456 px por
## encima de la punta del flipper, o sea que la bola llegaba a una pala que no
## estaba en plano.
##
## Multiplicando por la velocidad, el adelanto ES el sitio donde va a estar la
## bola dentro de este tiempo, que es lo que hace falta ver. 0,18 s está elegido
## contra el techo de la pantalla, no a ojo: con la ventana de 540 px, un valor
## mayor mete a la bola rápida detrás de la barra de título en la bajada.
var tiempo_anticipacion: float = 0.18

## GARANTÍA DURA, y es la otra mitad del arreglo. La vieja prometía que la BOLA
## estuviera en pantalla, y eso se cumplía dejándola pegada al canto de abajo
## con nada debajo: se veía la bola y no se veía adónde caía. Esta promete lo
## contrario y es lo que de verdad se juega: **el borde inferior de la pantalla
## tiene que llegar por debajo de donde la bola va a estar**, con este margen.
var margen_debajo_bola: float = 150.0

## Lo que hay dibujado encima de la mesa por arriba, y por debajo de lo cual la
## bola no puede subir sin esconderse.
##
## YA NO ES UN APAÑO. Eran 58 px porque el HUD era una franja opaca pegada al
## borde superior, dentro de los 400 px de la mesa: el tiro más largo del juego
## —lo alto de la órbita— era el único que no se veía. El HUD se ha mudado a los
## paneles de la banda derecha, así que lo único que queda arriba es el marco de
## la ventana de la mesa con su barra de título, que son 8 + 16 = 24 px.
##
## Y ahora el número SIGNIFICA algo: es `NodoCascara.chrome_superior()`, o sea
## la altura medida de lo que tapa. Se escribe aquí porque las pruebas headless
## no montan la cáscara, y la vista lo vuelve a leer de ella al arrancar, que es
## el único sitio donde puede cambiar.
var alto_franja_hud: float = 24.0
var margen_superior: float = 16.0

## REGLA 2 — ancla inferior. Con la bola por debajo de esta línea (medida desde
## el fondo de la mesa) la cámara se fija abajo y no se mueve más: el tercio de
## los flippers es intocable.
var margen_ancla: float = 300.0

## REGLA 4 — zona muerta, o la cámara tiembla con cada rebote.
##
## OJO CON CÓMO SE USA, que aquí estaba la otra avería. La zona muerta decide si
## la cámara ARRANCA, no dónde se para. Estaba escrita como destino —se movía
## hacia el borde de la zona en vez de hacia el objetivo— y eso la dejaba
## parada a 45 px del ancla PARA SIEMPRE: los últimos 45 px de mesa, que son los
## del drenaje, no se veían nunca. Ahora es una histéresis: por debajo de la
## zona no arranca, y una vez arrancada llega hasta el final.
var zona_muerta: float = 45.0
var suavizado: float = 5.0
## Sin bola en juego (resolviendo, victoria) la cámara vuelve abajo, despacio.
var suavizado_reposo: float = 2.0
