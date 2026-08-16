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

## EL ADELANTO YA NO SE MIDE EN TIEMPO, Y ESTA ES LA HISTORIA COMPLETA PORQUE
## LAS DOS MITADES SON VERDAD.
##
## Estuvo en 0,18 s, y no por capricho: con un adelanto fijo de 110 px la cámara
## miraba siempre lo mismo por debajo de la bola, cayera a 300 o a 1900 px/s. A
## 1900 esos 110 px son 58 ms de juego, o sea que la cámara enseñaba el sitio
## donde la bola YA estaba. Medido entonces: el borde inferior llegaba a quedarse
## 456 px por encima de la punta del flipper. Multiplicar por la velocidad
## arreglaba eso.
##
## **Y era la causa del tirón.** El suelo garantizado vale
## `bola_y + vy × tiempo_anticipacion + margen_debajo_bola`, así que depende de
## `vy` — y `vy` NO es continua: salta entera cada vez que la bola sale de una
## rampa, pega en un bumper o toca una pala. Un objetivo que salta no se puede
## suavizar sin perder la garantía: o la cámara llega a tiempo dando un corte, o
## va suave y se pierde el flipper. Se probaron las dos y las dos se notan.
##
## **La salida es que el objetivo dependa solo de la POSICIÓN, que sí es
## continua**, y pagar en margen lo que se deja de pagar en predicción. Medido
## con seis bolas de verdad (`medir_camara.gd` §4):
##
##     t_ant  margen   peor salto      aceleración   sin flipper
##      0,18     150      91,6 px    1.244.744 px/s²      0 %   ← como estaba
##      0,09     150      36,3 px      447.208 px/s²      3 %
##      0,00     150       8,4 px      117.951 px/s²      8 %   ← se pierde
##      0,00     250       7,1 px       76.637 px/s²      0 %
##      0,00     300       —            —                 0 %   ← elegido
##      0,00     350       5,4 px       60.132 px/s²      0 %
##
## O sea: **17 veces menos salto y 20 veces menos aceleración, sin perder ni un
## fotograma de flipper**. Lo que cuesta es que se ve más mesa por debajo de la
## bola y menos por encima, que en una mesa vertical es el lado bueno.
##
## Se deja el parámetro en vez de borrarlo porque es el dial con el que se
## reabre esta decisión: subirlo devuelve la predicción y con ella el tirón.
var tiempo_anticipacion: float = 0.0

## GARANTÍA DURA: el borde inferior de la pantalla tiene que llegar por debajo de
## la bola con este margen. Ahora es lo ÚNICO que la sostiene —antes se repartía
## con la predicción de velocidad— y por eso ha subido de 150 a 300.
##
## El número sale de una cuenta, no del ojo: el muelle va por detrás del objetivo
## como mucho `vy × tiempo_suavizado`, y con la bola al tope (1500 px/s) y 0,16 s
## eso son 240 px. Con 300 queda holgura, y está comprobado contra la caída recta
## a 1900 px/s, que es más rápido de lo que la mesa puede producir.
var margen_debajo_bola: float = 300.0

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

## REGLA 5 — LA CÁMARA NO SE TELETRANSPORTA, y ahora tampoco arranca ni frena de
## golpe. **Cuánto tarda en llegar a donde quiere estar, en segundos.**
##
## SUSTITUYE AL `lerp` Y AL TOPE DE VELOCIDAD, y las tres formas se han probado
## jugando, en este orden, cada una arreglando el fallo de la anterior:
##
##   1. `lerp` con factor por fotograma. El tirón no estaba aquí: estaba en que
##      las garantías duras de `avanzar` se aplicaban DESPUÉS y sin suavizar.
##      Medido: 113 px en un fotograma, 13.616 px/s.
##   2. Tope de velocidad (`move_toward`). Quitó el salto —113 px pasaron a 15—
##      pero es velocidad constante con arranque y parada instantáneos, o sea lo
##      más mecánico de los tres. Daniel lo siguió notando: *"sigue siendo brusca
##      a la hora de bajar en cierto punto"*.
##   3. Muelle críticamente amortiguado, que es esto. Arranca de cero, acelera y
##      frena, y nunca se pasa de largo. **Lo que se nota no es el tamaño del
##      salto, es la aceleración**, y por eso los dos primeros intentos fallaron
##      midiendo bien el número equivocado.
##
## Y el "en cierto punto" era literal: `suelo_visible` tenía un escalón en la
## línea de seguridad (y=1000) que movía el suelo garantizado 150 px de golpe
## SIEMPRE EN EL MISMO SITIO de la mesa. Está quitado.
##
## **Es EL dial de tacto de la cámara.** Más alto = más perezosa y más cine; más
## bajo = más pegada a la bola y más nerviosa. El suelo lo pone la garantía del
## flipper: pasado cierto punto la cámara ya no llega a tiempo con la bola rápida
## y se pierde la punta de la pala. La tabla del barrido está en `ESTADO.md`.
var tiempo_suavizado: float = 0.16
## Sin bola en juego (resolviendo, victoria) la cámara vuelve abajo, despacio: no
## hay nada que perseguir, así que puede tomarse su tiempo.
var tiempo_suavizado_reposo: float = 0.45

## Red de seguridad del muelle, en px/s. **Ya no es el dial de tacto** —ese es
## `tiempo_suavizado`—: limita la DISTANCIA que el muelle se plantea de una vez,
## no la velocidad, porque recortar la velocidad devolvía la esquina dura que se
## quería quitar. Solo actúa en saltos de objetivo enormes.
var velocidad_maxima: float = 2600.0
