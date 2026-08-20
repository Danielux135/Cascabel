class_name ParametrosMesa
extends RefCounted

## Números de tacto. Todos vienen del prototipo HTML validado (ver CONTEXTO.md).
## Están expuestos a propósito: la física se ajusta jugando, no calculando.
## Si tocas uno, anótalo. Los que llevan (*) los he tenido que elegir yo porque
## no venían del prototipo.

# --- Bola y mundo ---
var gravedad: float = 1750.0
var rebote_pared: float = 0.42
var radio_bola: float = 9.0
var rozamiento: float = 0.20          # v *= exp(-rozamiento * dt)
var velocidad_maxima: float = 1500.0

# --- Multibola ---
## Cuántas bolas caben a la vez. El tope no es de rendimiento —el solver aguanta
## de sobra—, es de LEGIBILIDAD: con la cámara siguiendo a la más baja, a partir
## de cierto número lo que pasa arriba deja de existir para el jugador y las
## bolas de más son daño que cae solo. Cuatro es lo que cabe en el plano.
var bolas_maximas: int = 4
## Rebote de bola contra bola. Acero contra acero es casi elástico, pero no 1: con
## 1 dos bolas encerradas en el racimo se pasan el impulso para siempre y nunca se
## calman. (*)
var rebote_bola: float = 0.65

# --- Flippers ---
## Subida de 22 a 30 para cerrar el alcance del tiro desde la cuna, que es lo
## que hacía que la mesa no fuese un menú de tiros: la velocidad que la pala le
## mete a la bola es ω×r, y con 22 el tiro subía a y=1032 mientras las bocas
## están a y=790 (retorno y cañón) y y=880/935 (órbita). No llegaba a ninguna.
## Con 30 sube a y=787 y alcanza el banco de targets.
##
## Daba miedo que acelerase el juego entero —Daniel se quejó de que la bola va
## muy rápida—, pero está MEDIDO que no: la ventana de reacción se queda en 150
## ms y la duración de bola en 3,4 s, iguales que con 22. Tiene sentido: esa
## ventana la fija la gravedad mientras la bola cae, no la fuerza de la pala.
## Lo que cambia es lo lejos que llega lo que TÚ tiras.
var flipper_velocidad_giro: float = 30.0    # rad/s
## La pala no rebota, empuja: el rebote solo actúa cuando está quieta. Estuvo en
## 0,10 para tapar un problema que ya no existe —la bola botaba encima de la
## pala y perdía el contacto, y sin contacto no había agarre—, pero eso lo
## resuelve ahora `velocidad_rebote_minima`, que mata los microrebotes de raíz.
## Con 0,10 la goma se sentía muerta: 0,25 es goma de verdad y la bola llega
## viva a la pala.
var flipper_rebote: float = 0.25
## Bajado de 78 a 64: era el dial de dificultad que quedaba pendiente. Con 78 el
## hueco central medía 22 px y con 64 mide 47, o sea que drenar por el medio
## deja de ser un objetivo diminuto.
var flipper_longitud: float = 64.0
## Largo de la pala DERECHA, si es distinto. 0 = la misma que la izquierda, que
## es lo normal. Existe para las palas "desiguales" de la capa de Preparación
## (`DISEÑO.md` §5): una mesa asimétrica hay que volver a aprenderla, y eso es
## una elección de partida, no un desequilibrio.
##
## OJO: cambiar cualquiera de los dos largos mueve el barrido de la pala, y el
## barrido es de donde se sacaron los slingshots —era el bug que impedía
## apuntar—. Hay una prueba que recorre TODOS los juegos de palas comprobando
## que ninguno mete la pala dentro del slingshot ni deja de llegar a la bola:
## probar solo el juego por defecto dejaría los otros tres sin medir.
var flipper_longitud_der: float = 0.0
var flipper_radio: float = 8.0
## La pala levantada estaba a -32°, o sea muy empinada, y eso rompía la cuna por
## dos sitios a la vez. Medido:
##
##   -32°: la bola rueda hasta el canto del eje, se cae por ahí y la pala la
##         vuelve a coger, en bucle. Nunca se asienta del todo: picos de 137
##         px/s con la pala sostenida. Es el bote que Daniel mandó en captura.
##         Y acaba a 0,28 de la pala, donde omega por radio no da ni para subir
##         40 px: desde la cuna no se podía tirar a nada.
##   -16°: se para EN SECO en 0,13 s y se queda a 0,81 de la pala, que es donde
##         la pala sí tiene palanca.
##
## El recorrido pasa de 60° a 44°. La velocidad de giro no cambia, así que el
## golpe no se ablanda: lo que cambia es dónde queda la bola al sostener.
var flipper_reposo_izq: float = 28.0        # grados, Y hacia abajo
var flipper_activo_izq: float = -16.0       # recorrido de 44°
var flipper_reposo_der: float = 152.0
var flipper_activo_der: float = 196.0

## (*) CONTEXTO daba los ejes en x=118 y x=282. Con esos, las puntas en reposo
## quedan a 26,3 px una de otra: 10,3 px libres para una bola de 18 px de
## diámetro. El desagüe central quedaba sellado y la bola no podía drenar nunca.
## Separándolos 6 px por lado quedan 22,3 px libres y el drenaje central funciona.
## Es una decisión de tacto: si prefieres el hueco original, cámbialo aquí.
## En la mesa de 700 estaban en (112,600) y (288,600). La zona baja es esa
## misma mesa bajada Mesa.DESPLAZAMIENTO px, así que aquí van ya en absoluto.
var flipper_eje_izq := Vector2(112.0, 1200.0)
var flipper_eje_der := Vector2(288.0, 1200.0)

# --- Bumpers ---
var bumper_empuje: float = 620.0
## Bajado de 1,8 a 1,0. Por encima de 1 la bola sale MÁS RÁPIDA de la que entra:
## el bumper fabrica energía. Con 82 px de aire daba igual porque no se tocaban
## nunca; al apretar el racimo a 24 px la bola entró de verdad, rebotó varias
## veces seguidas y salió recargada cada vez. Resultado: se quedaba viviendo en
## la mitad de arriba y casi no bajaba a las palas. Con 1,0 sale como entró y el
## "pop" lo sigue dando bumper_empuje.
var bumper_rebote: float = 1.8              # restitución en el término normal
var bumper_radio: float = 19.0
var bumper_velocidad_minima: float = 40.0   # (*) umbral del interruptor

## (*) Racimo en triángulo equilátero, con este hueco entre BORDES. Antes había
## 82 px entre los dos de abajo y la bola pasaba por el medio sin tocar nada:
## medido, 0,0 bumpers golpeados por bola lanzada. Con 24 la bola (18) entra
## con holgura pero no pasa de largo, y al entrar rebota varias veces seguidas.
var bumper_hueco: float = 24.0
var bumper_centro := Vector2(200.0, 805.0)

## HACIA DÓNDE MIRA EL TRIÁNGULO, en grados. Y esto es la corrección de un error
## de medida, no un gusto.
##
## El racimo estaba en 0 —dos bumpers arriba y uno abajo— y su comentario decía
## "esto está medido, no elegido": con uno arriba salían 1,4 golpes por entrada
## y con dos, 3,7. El número era bueno; **la bola con la que se midió, no**. Se
## dejaba caer DESDE ARRIBA, y en esta mesa a la bola no le llega nada de
## arriba: el racimo está en lo más alto que se alcanza, así que todo lo que
## entra, entra SUBIENDO.
##
## Medido otra vez, ahora por las dos caras, 40 entradas de cada:
##
##     orientación   de dónde        bumpers   lo más alto
##     dos arriba    desde abajo         1,0        y=863
##     dos arriba    desde arriba        4,1        y=669
##     dos abajo     desde abajo         6,3        y=704
##     dos abajo     desde arriba        1,9        y=669
##
## O sea que el racimo llevaba todo este tiempo puesto de espaldas: una bola que
## sube choca de frente contra el bumper de abajo y se vuelve por donde vino.
## Girado 60°, la bola que sube se cuela entre los dos de abajo y rebota contra
## el de arriba, que es el 3,7 de la medida original pero por la cara buena.
##
## Y arrastra la otra mitad de la tanda: con dos abajo la bola sale del racimo
## hasta y=704, o sea que POR FIN entra en la bóveda de pines. Con el racimo
## como estaba, no llegaba ninguna ruta de la mesa.
var bumper_giro: float = 60.0

# --- LA PLANTA ALTA: LA ARENA DE CAZA ---
#
# `DISEÑO.md` §7 lista un tiro llamado **umbral alto** que "abre el modo de
# caza", y §5 dice que eso es lo que **"le da sentido a la zona alta, que hasta
# ahora era un pasillo"**. Pasillo era literal: por encima del arco (y=660) no
# había un solo colisionador.
#
# Y ES UNA MESA, NO UN CAMPO DE PINES. La primera versión era una rejilla al
# tresbolillo y Daniel la tumbó jugándola: *"el pachinko es literalmente que
# caiga la bola, y que luego no pase de la primera línea"*. Es exacto y se ve en
# la física: una rejilla es un comedor de energía pasivo —la primera fila se
# lleva la velocidad y el resto es caída—, así que no hay tiro, hay embudo.
# **Lo que hace que una zona de pinball se juegue son palas.**
#
# POR QUÉ ES UN PISO Y NO CAMPO ABIERTO, que es aritmética y no gusto: la bola
# sube 643 px por sus medios, o sea que desde las palas de abajo no pasa de
# y=557 aunque no hubiera techo; y una caída libre desde aquí llega abajo a
# 1500 px/s, 67 ms de ventana, cuando el cañón ya se tuvo que ablandar a la
# mitad porque 900 px/s —111 ms— era "un tiro imposible, o sea perder la bola
# con pasos extra".

## El techo de la arena: elipse igual que el arco de abajo, para que las dos
## plantas se lean como la misma mesa.
var arena_techo_ry: float = 70.0
## Donde el techo se encuentra con las bandas.
var arena_hombro_y: float = 220.0
## LA ALTURA DE LAS PALAS DE ARRIBA. Todo el resto de la zona de palas cuelga de
## aquí: las dos paredes lisas y el embudo del desagüe se colocan en relación a
## este número, así que moverlo mueve la zona de palas entera sin descuadrar nada.
var arena_y_pala: float = 560.0

## LAS PALAS DE ARRIBA SON CORTAS, Y LO DECIDIÓ FÁTIMA. La planta alta sin palas
## se descartó —gobernarla pedía botones nuevos y esto es un pinball de dos
## teclas—, así que lo que cambia no es el control, es el tamaño: *"pasa de ser
## random a skill"*. Una pala corta perdona menos, y como arriba drenar no cuesta
## vida sino la caza, **el hueco entre palas de arriba ES el reloj de la caza**.
##
## OJO CON EL INVARIANTE: lo cerrado es el ANCHO de mesa (400) y el radio de la
## bola, porque de ellos cuelga el hueco de ABAJO y toda la física medida. El
## largo y la separación de estas dos son geometría de una planta que se está
## rediseñando, y se tocan aquí (`CAZA.md` §3.1).
##
## El hueco libre entre puntas sale de los dos: `separacion − 2·largo·cos(reposo)
## − 2·radio`. Abajo son 176, 64 y 8 → 47 px. Aquí, 144 y 38 → **60,9 px**.
##
## Y ESTOS DOS NÚMEROS ESTÁN BARRIDOS, no elegidos (`tests/medir_planta_alta.gd`,
## 60 cazas por celda, jugador que aporrea):
##
##     largo  separ  hueco   dura     drena
##        46    130   32.8   18.2 s   pocas   <- la caza no se acaba nunca
##        46    144   46.8   12.2 s   33/60
##        46    158   60.8    7.7 s   —
##        38    130   46.9    9.5 s   —
##        38    144   60.9    7.6 s   48/60   <- el elegido
##        38    158   74.9    6.6 s   49/60
##
## El 46/144 —el mismo hueco que abajo— deja al que aporrea 12,2 s ARRIBA, o sea
## más que los 8,1 s que dura una bola abajo: la planta alta salía más blanda que
## la de abajo teniendo la pala más corta, porque aquí no hay outlanes que se
## coman la bola. Con 38/144 baja a 7,6 y ocho de cada diez cazas acaban
## drenando, que es lo que hace que el tope de 20 s sea un techo y no un trámite.
##
## **Lo que NO alcanza es el objetivo de `CAZA.md` §6** —3-4 s para el que
## aporrea—, y con esta geometría no hay fila que lo dé: 38/158 se queda en 6,6
## abriendo un hueco de 75 px, que es medio campo. Está anotado en `ESTADO.md`
## como decisión pendiente, y la salida que apunta `CAZA.md` §7 (devolver uno de
## los dos castigos) es al revés de lo que hace falta aquí.
## **Y 38 SE JUGÓ Y SE CAYÓ.** Daniel las probó: *"flippers extremadamente
## cortos"*, *"es extremadamente fácil drenar e irte de la zona de caza"*, *"no he
## sido capaz de aguantar los 20 segundos ni de lejos"*. La medida decía 7,6 s
## para el que aporrea y eso era exactamente lo que se buscaba; **lo que estaba
## mal era lo que se buscaba**, no el número.
##
## Punto intermedio elegido por Daniel: **54**, con los ejes más juntos para que
## el hueco baje de 61 px a 24. Conserva la idea de Fátima —la pala de arriba es
## más corta que la de abajo, y eso se nota en la mano— sin que la planta alta
## sea una trampa. Ver `CAZA.md` §3.1.
var pala_alta_largo: float = 54.0
## Distancia entre los dos ejes. No puede salir de `flipper_eje_*`: esas son las
## de abajo y su separación está atada al hueco medido de la planta baja.
##
## 136 con largo 54 deja **24 px de hueco**, o sea la mitad que abajo: arriba
## drenar por el medio tiene que ser un accidente, no la forma normal de acabar.
var pala_alta_separacion: float = 136.0

## LA MITAD DEL DESAGÜE, medida desde el centro. Es el tercer dial de la planta
## alta y el que no estaba escrito en `CAZA.md` §6, porque hasta medirlo no se
## veía que hiciera falta: sin outlanes, lo único que decide cuánta bola se
## pierde por FUERA de las palas es lo ancho que sea el embudo por el que se cae.
## Subirlo abre los dos pasillos que quedan por fuera de las puntas; bajarlo los
## cierra y deja el hueco central como única salida.
var arena_desague_medio: float = 50.0

## DONDE ARRANCAN LAS DOS PAREDES LISAS. Van de la banda al eje de su pala, sin
## slingshot, sin outlane y sin carril de retorno (`CAZA.md` §3.2 y §3.3): una
## bola que baja por el lado llega POSADA a la pala en vez de recibir un patadón
## al azar. Y como acaban EN el eje, no queda ni un rincón donde acuñarse.
var arena_diagonal_y: float = 452.0

## LA ISLA. Región elevada (`CAPA_ALTA`) en mitad de la planta: ahí vive la
## criatura y **desde el tablero no se la alcanza**, hay que subir por la rampa.
## Salirse de su borde es caerse, que es lo único que hace una plataforma.
var plataforma_region := Rect2(150.0, 250.0, 100.0, 96.0)
## LA FALDA: cuánto se meten hacia dentro las paredes que la sostienen. Esas
## paredes existen SOLO en el tablero, así que una bola de abajo choca contra la
## isla y una de arriba pasa por encima — que es lo que hace que se lea alta.
##
## Y el número no es estética: la bola cae cuando su CENTRO sale de la región, y
## en ese instante tiene que estar ya FUERA de la pared. Con la falda a 8 y radio
## 9, la bola aparece penetrando 1 px en vez de 9, o sea que no da el salto.
var plataforma_falda: float = 8.0

## LA RAMPA QUE SUBE A LA ISLA. Lleva cuesta (`PROPÓSITO.md` §6): por debajo del
## 60 % de la velocidad de escape te sueltas a mitad, y como es CARRIL y no tubo,
## soltarte es caerte al tablero. Es el tiro difícil de la planta.
##
## **640 ERA UN NÚMERO QUE NO SE PODÍA FALLAR, y lo cazó Fátima jugando:** *"no
## he sido capaz de quedarme a medias en ninguna rampa, hay que revisar esas
## físicas"*. La física estaba bien —el modelo de energía y sus tres bandas están
## medidos banda por banda en la batería—; el número estaba fuera de lo que la
## mesa produce. Con 640 la frontera de "no llego" cae en 384 y la rampa no
## engancha por debajo de 300: **una ventana de 84 px/s en un rango de 1200**, o
## sea el 4 % de las entradas medidas jugando (3 de 74). Todo lo que enganchaba,
## coronaba.
##
## 800 sale de un barrido de seis valores × 40 cazas × dos maniquíes, y no se
## eligió por el porcentaje sino por DÓNDE se cae la bola:
##
## | escape | corona a | falla | se cae al ... de la cuesta |
## |--------|----------|-------|----------------------------|
## | 640    | 384      |  9 %  | 73 %                       |
## | 750    | 450      | 14 %  | 66 %                       |
## | **800**| **480**  |**30 %**| **76 %**                  |
## | 850    | 510      | 64 %  | 86 %                       |
## | 1000   | 600      | 76 %  | 64 %                       |
##
## Entre 800 y 850 hay un ESCALÓN —30 % a 64 %— porque las velocidades de entrada
## se agolpan en 480-510, y un valor puesto encima de un escalón se mueve entero
## en cuanto alguien toque la geometría. 800 se queda del lado plano.
##
## Y el 76 % es lo que contesta a lo que pedía: quedarse a medias es subir casi
## entera y caerse desde arriba, no que la rampa te escupa en la boca. Subiendo
## más la cuesta el fallo llega antes y se lee como un rebote — con 2000, la bola
## se suelta al 18 % del recorrido.
var subida_velocidad_escape: float = 800.0
var subida_velocidad_minima: float = 300.0
## LA ÓRBITA DE ARRIBA. Es lo único LARGO de la planta alta y sube 242 px por el
## lado de abajo — **y 3 px por el de arriba, o sea que por ahí no se puede
## fallar, y es correcto**: quien la coge desde el corredor del techo ya está
## arriba y lo que hace es bajar. Que una rampa bidireccional se pueda fallar por
## un lado y no por el otro no es un caso especial escrito a mano; sale de que la
## cuesta cobre altura.
##
## 700: frontera en 420 contra entradas de 325-1480, falla 1 de cada 3 y se
## suelta al 80 % de la cuesta. A 800 sube a 44 % pero el punto de caída baja al
## 67 %, y arriba eso importa más que abajo — la planta alta dura 20 s y se ve dos
## veces por run, así que un fallo que se lee como rebote se ve muchas veces.
var arena_orbita_velocidad_escape: float = 700.0
## Los dos túneles cruzan por DEBAJO del tablero y salen lejos. Su velocidad
## mínima es baja porque no son el tiro difícil: son por donde la criatura se
## esconde, y taparles la boca es el modo entero (`CAZA.md` §2).
var arena_tunel_velocidad_minima: float = 240.0
## Velocidad mínima para engancharse a la órbita corta. Más baja que la de abajo
## (500) porque aquí arriba las distancias son la mitad: con 500 no engancharía
## nunca.
var arena_orbita_velocidad_minima: float = 320.0
## El fondo del embudo, que es la boca del desagüe de la planta alta. Entre este
## y el arco de la mesa de abajo (y=660) quedan 12 px de nada: **las dos plantas
## no se comunican por gravedad.**
var arena_fondo_y: float = 648.0
## Por debajo de esta línea la bola de la planta alta se ha drenado y la caza se
## acaba. Es una LÍNEA y no una boca: una boca se puede esquivar cayendo por su
## lado, y entonces la bola se queda en el hueco entre las dos plantas, que es un
## sitio del que no se sale.
var arena_drenaje_y: float = 630.0

## Cuánto dura el modo. `DISEÑO.md` §5: "el modo dura un tiempo limitado y el
## reloj del enemigo sigue corriendo mientras estás arriba. Sin eso, cazar sería
## gratis." **Pero el tiempo es el TECHO, no el final**: la caza se acaba de
## verdad cuando drenas ahí arriba, y por eso aguantar la bola también vale en la
## planta alta. Con la versión de pines solo existía el tiempo, y por eso daba
## igual lo que hicieras.
var caza_tiempo: float = 20.0

## EL SALVABOLAS DE LA CAZA, Y ES LO QUE LA CONVIERTE EN UN BONUS.
##
## Lo decidió Daniel jugándola: *"esta fase debería sentirse como un bonus, algo
## especial, no algo tan fácil de perder"*, *"ni siquiera me gusta la idea de que
## te puedas salir de esa zona tan fácil"*.
##
## Con esto en `true`, **drenar en la planta alta ya no te echa**: la mesa vuelve
## a servir la bola por donde entró y la caza sigue. Lo único que la acaba es el
## tiempo, y el precio de estar ahí arriba sigue siendo el que siempre fue —el
## reloj del enemigo corre mientras tanto (`DISEÑO.md` §5)—, que es lo que impide
## que un bonus sin riesgo sea gratis.
##
## Esto tumba media frase de `CAZA.md` §3.1: el hueco entre palas de arriba YA NO
## es el reloj de la caza, porque el reloj es el reloj. Lo que decide el hueco es
## cuántas veces te salvan, o sea cuánto tiempo del bonus tiras a la basura.
var caza_salvabolas: bool = true
## Lo que cuesta cada salvada, en segundos de caza. A 0 la salvada es gratis, que
## es lo que Daniel eligió. Subirlo es la variante "salvabolas con coste" sin
## tocar una línea de código: jugar mal acorta el bonus en vez de terminarlo.
var caza_coste_salvada: float = 0.0

## LA BOCA DEL UMBRAL, Y ESTÁ DONDE LA PUSO LA MEDIDA, NO DONDE QUEDABA BONITO.
##
## Empezó en el centro, (200,690), debajo del vértice del arco. Cero entradas en
## 240: **el bumper de arriba del racimo está en (200,769) y tapa el pasillo
## central entero.** Medido subiendo por el centro (x=200±26), la mejor de 240
## bolas se quedó en y=708 y la mediana en y=840.
##
## Repartido por bandas, de 240 entradas al racimo, cuántas suben por encima de:
##
##     banda x     y<700  y<730  y<760  y<790
##     20..90          0      0      0      1
##     90..150         0      0      3      4
##     150..250        1      1      1      1     <- el centro, tapado
##     250..310        0      0      3      3
##     310..380        0      8      9     10     <- por aquí se sube
##
## O sea que el único sitio por el que la bola sube de verdad es **el flanco
## derecho**, porque el bumper de abajo a la derecha del racimo la escupe hacia
## allí. Ahí va la boca.
##
## Y NO SE PUEDE PONER EN LA LÍNEA DE TIRO DE UNA PALA, aunque sea lo que pide
## `DISEÑO.md` §7 ("boca alta, solo llega un tiro muy limpio"): medido, el mejor
## tiro desde la cuna izquierda muere en (104,751) y el de la derecha en
## (296,751), y **las dos líneas ya acaban en una boca** —el retorno en (95,790)
## y el cañón en (305,790)—. Una boca por encima de esas no se alcanza nunca,
## porque la de abajo se traga la bola primero.
##
## Así que el umbral es literalmente **el tiro que hay más allá de los bumpers**:
## no se apunta, se gana con una entrada buena al racimo. **Este es el número que
## hay que mirar después de jugar**: si la planta alta no se ve nunca, los diales
## son esta posición, `umbral_entrada_radio` y `umbral_velocidad_minima`, por ese
## orden.
var umbral_boca := Vector2(340.0, 730.0)
## Y hay que llegar CON FUERZA, no de rebote agotado. Una bola que apenas alcanza
## la boca llega a 0 px/s: sin umbral de velocidad, el tiro difícil se ganaría
## por accidente.
var umbral_velocidad_minima: float = 150.0
## Con cuánta velocidad se suelta la bola arriba. Baja: subes a jugar, no a
## estrellarte contra el techo.
var umbral_factor_salida: float = 0.45
## La boca del umbral es MÁS ANCHA que las demás (18). Con 18 se abría la caza
## en 1 de cada 240 entradas al racimo: eso no es difícil, es que no existe.
var umbral_entrada_radio: float = 30.0

## EL REGRESO. No tiene boca: no se entra en él, te mete la planta alta cuando
## drenas arriba o cuando se acaba el tiempo. Por eso la bola se lanza a una
## velocidad fija en vez de con la que traía — si no, una caza que acaba con la
## bola parada tardaría siglos en bajar.
var regreso_velocidad: float = 700.0
## Y sale despacio. Vuelves de estar arriba y la bola te llega posada a la pala:
## el precio de la caza es el reloj del enemigo, no perder la bola al bajar.
## Medido, y ajustado dos veces contra el cronómetro: con la salida a 0,35 y la
## boca 20 px más abajo, la bola llegaba a la pala en 197 ms — por DEBAJO de los
## 250 que tarda un humano en reaccionar, o sea el mismo fallo que tenía el cañón
## antes de ablandarlo. Con 0,30 y la salida más arriba sale a 210 px/s y llega
## en 300 ms largos.
var regreso_factor_salida: float = 0.30

# --------------------------------------------------------- LA BARRA DE CARGA
#
# `PROPÓSITO.md` §6, y es la otra mitad de la cuesta. Poner cuesta a cinco rampas
# le quita a la mesa uno de cada cuatro o cinco premios de recorrido, porque las
# rampas **se cobran al salir** y una fallada no sale. La barra es lo que
# devuelve ese dinero, y lo devuelve por otra puerta:
#
#     toda entrada carga, LLEGUES O NO → el tiro fallado sigue pagando
#     → sigues tirando a la rampa que se te resiste.
#
# Si en vez de esto se hubiera compensado subiendo el daño de las rampas, fallar
# volvería a ser una pérdida seca y la mesa tendría los mismos tiros de antes con
# los números más gordos. Eso es un modificador, no una mecánica.

## Con qué se divide la velocidad de entrada en una rampa SIN cuesta —los dos
## túneles, el umbral, el regreso—. No hay escape con el que compararlas y
## dividir por cero no es una opción, así que se miden contra el orden de
## magnitud de las que sí lo tienen (700-1000). Es lo que hace que la barra sea
## legible: el mismo tiro carga lo mismo tire donde tire.
var carga_escape_llano: float = 900.0
## Cuántas entradas LIMPIAS (justo a la velocidad de escape, ratio 1) llenan la
## barra. Es EL dial de la barra: con él se decide cada cuánto hay descarga.
##
## **3 NO ES UN NÚMERO ELEGIDO A OJO: ES EL QUE DEVUELVE LO QUE LA CUESTA QUITA.**
## Medido con `tests/medir_daniel.gd`, contra el jugador con reliquias y misiones
## —que es el único modelo que reproduce a Daniel—, con la mesa antes de la
## cuesta pagando **835 de daño por bola en combates de 128 s**:
##
##   | carga_entradas | d/bola | s/combate | vida al acabar |
##   |----------------|--------|-----------|----------------|
##   | sin barra      |   747  |    143    | 95 %           |
##   | **3,0**        | **838**|  **127**  | 96 %           |
##   | 2,0            |   875  |    123    | 97 %           |
##   | 1,5            |   917  |    120    | 97 %           |
##   | 1,0            |   974  |    111    | 98 %           |
##
## La primera fila es el coste de la cuesta sin nada que lo compense: **la mesa
## paga un 11 % menos** porque una rampa fallada no cobra. Con 3, paga 838 contra
## 835: la planta baja se juega el doble de tiempo y cobra lo mismo.
##
## Y la última fila es el riesgo que `PROPÓSITO.md` §6 marcó por escrito —*"el
## riesgo, y hay que medirlo antes de escribirlo: duplicar el daño cuatro
## segundos puede cargarse la tabla de vida de enemigos entera"*—. Existe: con 1
## la mesa pega un 17 % más que antes y los combates se acortan 17 s. El dial no
## es "cada cuánto mola que haya descarga", es dónde deja de compensar y empieza
## a regalar.
var carga_entradas: float = 3.0
## Lo que dura la descarga. Cuatro segundos es de `PROPÓSITO.md` §6, y la razón
## es la regla de los bucles: se apaga sola, así que no se puede sostener sin las
## palas.
var descarga_tiempo: float = 4.0
## La bola sale al doble de la rampa que gasta la descarga. Se recorta al tope de
## la mesa: el doble de un tiro rápido se saldría del rango en el que el resto de
## la física está medida.
var descarga_factor_salida: float = 2.0


## (*) Outlanes: los dos carriles que van directos al drenaje, por fuera de los
## carriles de retorno. Son la válvula de dificultad de la mesa: sin ellos solo
## se pierde la bola por el hueco entre palas, que es un objetivo pequeño.
## Es la anchura de la BOCA, medida en horizontal contra la pared de fuera. Por
## debajo de 18 (el diámetro de la bola) el outlane deja de tragar.
## Con 26 entraba demasiado fácil: en la boca quedaban 8 px de margen para el
## centro de la bola y cualquier bajada por el lado se colaba. Con 21 quedan 3
## y hay que venir pegado a la pared de fuera, o sea descontrolado. 18 es el
## suelo absoluto: por debajo no cabe la bola y el outlane deja de existir.
var ancho_outlane: float = 21.0

## Umbral de "la pala está quieta", o sea que ya ha terminado de subir. No entra
## en la física: lo usan el aviso de bola atrapada, las pruebas y la depuración.
var flipper_omega_quieta: float = 0.6       # rad/s

## Por debajo de esto, con la pala arriba y quieta, la bola cuenta como
## ATRAPADA. Tampoco entra en la física: es cuándo se avisa de que ya puedes
## apuntar. Atrapar la bola es la técnica con la que se elige un tiro, y Daniel
## jugó una tanda entera sin saber que estaba ahí.
var velocidad_atrapada: float = 60.0

## El cañón cruza el campo hacia la pala contraria, y salía a la misma velocidad
## con la que entraba: ~900 px/s. Medido, eso deja menos de 150 ms para llegar a
## la pala, y un humano reacciona en 250: no era un tiro difícil, era un tiro
## imposible, o sea perder la bola con pasos extra. Sale más lento, pero sigue
## cruzado: lo que se paga es la posición, no la velocidad.
## Medido por barrido: a 1,0 la bola llega a la pala en 0 o en 875 ms según con
## qué rebote, o sea que no se puede jugar. A 0,5 llega entre 267 y 325 ms
## entrando a 700, 900 o 1100, que es el único tramo por encima del umbral
## humano en TODO el rango. A 0,6 todavía se pierde entrando fuerte.
var canon_factor_salida: float = 0.50

# --- Slingshots ---
var slingshot_empuje: float = 700.0
var slingshot_rebote: float = 0.55
var slingshot_velocidad_minima: float = 90.0  # (*) umbral del interruptor

# --- Targets abatibles (*) ---
# No venían del prototipo: la geometría de CONTEXTO no los colocaba. Van en dos
# bancos de tres, pegados a las paredes laterales pero dejando 23 px de carril
# libre por fuera para que se pueda seguir bajando al inlane con el banco en pie.
## La cara, medida A LO LARGO de la pared. Contra una máquina real: la mesa mide
## 20,25" y aquí son 400 unidades, o sea 19,75 px por pulgada; un drop target de
## 1,5" de cara toca a 30 px. Este número ya estaba bien y no se toca.
var target_ancho: float = 30.0
## Lo que SOBRESALE hacia el campo, y este es el dial de verdad. Antes el target
## era un círculo de radio 13: metía 26 px de cuerpo redondo dentro del campo y
## las bolas que pasaban rozando salían rebotadas por el hombro. Un drop target
## de verdad es una plancha; 8 px es lo que se ve de su cara desde arriba.
## El borde de FUERA se queda donde estaba (23 px de carril contra la pared), así
## que bajar esto abre campo por delante del banco, no por detrás.
var target_canto: float = 8.0
var target_rebote: float = 0.45
var target_velocidad_minima: float = 30.0
## Al abatir el banco entero se vuelve a levantar, pero con retardo: si se
## levantara en el mismo instante aparecería encima de la bola y el solver la
## tendría que expulsar 22 px de golpe.
var target_tiempo_reset: float = 0.5

# --- Giradores (*) ---
# No son colisionadores: la bola pasa a través y los hace girar, como los de
# verdad. Van uno en cada carril de retorno.
## 10 y no más: el carril de retorno derecho mide 23,8 px de ancho, así que un
## radio de 13 se salía por encima del slingshot y una bola que rebotara por
## FUERA del carril habría hecho girar el girador de dentro.
var girador_radio: float = 10.0
var girador_velocidad_minima: float = 80.0

# --- Lanzador ---
var impulso_lanzador: float = 1350.0
var tiempo_carga_lanzador: float = 0.8      # (*) mantener espacio para cargar
var ratio_minimo_lanzador: float = 0.35     # (*) potencia de un toque suelto

# --- Arreglo 1: postes de goma del inlane ---
var poste_radio: float = 11.0               # (*) sella el hueco contra el eje
var poste_rebote: float = 0.55              # (*) es goma, no metal
var poste_empuje: float = 90.0              # (*) devuelve la bola al flipper
var poste_velocidad_minima: float = 60.0    # (*)

# --- Arreglo 2: solver ---
var subpasos: int = 4                       # 1500 px/s a 120 Hz -> 3,1 px por subpaso
var tolerancia_posicion: float = 0.5        # penetración que se deja sin corregir

# --- Rozamiento de contacto (Coulomb) ---
## El solver resolvía SOLO la normal, así que la bola resbalaba eternamente a lo
## largo de cualquier superficie y había que frenarla a mano sobre la pala. Ese
## frenado era isótropo —mataba también la componente normal— y por eso la bola
## se quedaba literalmente pegada en vez de rodar.
##
## Ahora cada contacto aplica un impulso tangencial limitado a `friccion` veces
## el impulso normal, que es el modelo de Coulomb de toda la vida. La bola se
## asienta en la cuna de la pala porque la geometría y el rozamiento la
## sostienen, no porque se le apague la velocidad.
##
## Estos tres números son EL dial del tacto de las palas. Uno cada vez.
## Van bajos a propósito en todo lo que no sea la pala. La bola real RUEDA por
## la mesa, y aquí no hay giro simulado: un rozamiento de deslizamiento
## realista sobre una bola que no rueda frena muchísimo más de la cuenta. Con
## 0,25 en las gomas, el racimo dejaba de encadenar y el carril de retorno
## derecho ya no llegaba a la pala.
var friccion_metal: float = 0.03            # paredes, arco, targets
var friccion_goma: float = 0.12             # slingshots y postes
## Cero, y a propósito. El bumper es la única superficie de la mesa cuyo trabajo
## es que la bola SALGA disparada: cualquier arrastre en el toque se multiplica
## por los seis o siete toques de una entrada al racimo y se lo come entero.
var friccion_bumper: float = 0.0
## La goma de la pala. Medido que la cuna NO depende de este número —la sostiene
## la forma, no el rozamiento—, así que aquí manda el realismo: 0,30 es lo que
## da la goma contra acero, y es lo que decide cuánto desvía la bola al rozarla.
var friccion_flipper: float = 0.30

## La frontera entre "esto es un impacto" y "esto es la bola apoyada". Por
## debajo no hay rebote ni rozamiento de Coulomb: hay rodadura. Sin esta
## frontera la bola apoyada da microrebotes contra la pala, pierde el contacto
## y no hay forma de asentarla. Una bola real tampoco rebota a 3 cm/s.
var velocidad_rebote_minima: float = 55.0

## Y por encima de esta, el rebote es el pleno de la superficie. Entre las dos
## sube en rampa.
##
## Era un ESCALÓN: por debajo de 55 no rebotaba nada y por encima rebotaba
## entero. Con la bola atrapada en la cuna eso la hacía botar sobre la pala
## segundo y medio antes de asentarse —Daniel lo vio y lo mandó en una captura—,
## porque cada botecito caía justo por encima del escalón y se devolvía entero.
##
## La rampa además es lo que hace una pelota de verdad: el coeficiente de
## restitución baja cuanto más flojo es el golpe, no se apaga de golpe.
var velocidad_rebote_pleno: float = 320.0

## Resistencia a la rodadura del contacto sostenido: el mismo Coulomb que los
## impactos, pero con un coeficiente pequeñísimo. Una bola apoyada no choca,
## rueda, y rodar cuesta poquísimo.
##
## ESTUVO MAL: era un arrastre proporcional a la velocidad (`v *= exp(-k·h)`), y
## eso le pone VELOCIDAD LÍMITE a la bola. Con 20 la terminal en la pala en
## reposo salía a 41 px/s, o sea que al soltar la pala la bola bajaba a
## velocidad constante en vez de acelerar. Daniel lo vio jugando: "por físicas
## debería ir bajando cada vez más rápido". Un arrastre lineal no puede dar eso;
## un rozamiento de Coulomb sí, porque es una fuerza fija y la gravedad le gana
## siempre que la cuesta pase de `rodadura`.
##
## Medido, soltando la pala tras atrapar, en px/s cada 0,15 s:
##   rodadura 20 -> 45, 39, 40, 40   (plana: la velocidad límite, se ve falso)
##   rodadura  4 -> 52, 115, 152, 172 (acelera, y la cuna se asienta a 11 px/s)
##   rodadura  2 -> acelera igual, pero la cuna ya no se asienta (71 px/s)
var rodadura: float = 4.0

## La frontera entre "va rodando" y "se está asentando". Por encima, la bola
## solo lleva rodadura y por eso acelera cuesta abajo; por debajo, vuelve el
## Coulomb de la superficie y se para del todo en vez de reptar.
##
## Es un apaño con una causa concreta: no simulamos el giro de la bola. Con
## momento angular esto saldría solo, porque la energía se iría al giro y
## volvería, en vez de tener que decidir a mano cuándo frenar.
var velocidad_rodando: float = 30.0

## Devuelve el rozamiento que le toca a cada superficie.
func friccion_de(tipo: int) -> float:
	match tipo:
		Colisionador.Tipo.FLIPPER:
			return friccion_flipper
		Colisionador.Tipo.BUMPER:
			return friccion_bumper
		Colisionador.Tipo.SLINGSHOT, Colisionador.Tipo.POSTE:
			return friccion_goma
		_:
			return friccion_metal

# --- Arreglo 3: ball search ---
var busqueda_velocidad: float = 60.0        # (*) por debajo de esto cuenta como parada
var busqueda_tiempo: float = 2.0
var busqueda_impulso: float = 420.0         # (*)
var busqueda_dispersion: float = 0.6        # (*) rad de aleatoriedad del empujón
## Si la bola está apoyada en un flipper que el jugador mantiene pulsado, no es
## un atasco: está atrapada a propósito. Sin esto, cazar la bola con el flipper
## (que es LA habilidad del juego) se vuelve imposible.
var busqueda_ignora_flipper_sostenido: bool = true

# --- Mundo ---
var inicio_bola := Vector2(369.0, 1251.0)   # dentro del carril lanzador
var y_drenaje: float = 1300.0

# --- Rampas y platillos (*) ---
## Velocidad mínima para engancharse a una órbita. Con esto, un lanzamiento a
## tope la coge y uno flojo no: es la habilidad del tiro inicial.
var rampa_velocidad_minima: float = 500.0
var rampa_entrada_radio: float = 18.0

# ------------------------------------------------- LA CUESTA DE CADA RAMPA
#
# `PROPÓSITO.md` §6, y la tanda que las encendió todas la abrió Fátima de una
# frase: *"TODAS las rampas han de tener esa mecánica de que puede no llegar. Si
# hay que poner altura a las rampas, se pone."*
#
# **NO HUBO QUE PONER ALTURA A NINGUNA.** La mesa ya la tenía; lo que le faltaba
# era que la cuesta la leyera. El modelo cobraba por longitud de curva —correcto
# solo en la subida a la isla, que sube y ya está— y en una órbita, que sube 660
# px y vuelve a bajar, eso dejaba la bola más lenta ABAJO que en lo alto. Desde
# que cobra ALTURA (`Rampa.velocidad_escape`), la subida de cada curva sale de sus
# propios puntos de control y las nueve se calibran igual:
#
#   | rampa        | sube  | escape | frontera | falla | se cae al ... |
#   |--------------|-------|--------|----------|-------|---------------|
#   | orbita       |  660  |   950  |   570    | 23 %  | 86 %          |
#   | canon        |  478  |  1000  |   600    | 25 %  | 91 %          |
#   | retorno      |  476  |  1000  |   600    |  —    | —             |
#   | subida_isla  |  180  |   800  |   480    | 45 %  | 77 %          |
#   | orbita_alta  |  242  |   700  |   420    | 32 %  | 80 %          |
#   | umbral       |  513  |     0  |    —     |  —    | —             |
#   | los 2 túneles|    0  |     0  |    —     |  —    | —             |
#   | regreso      |    0  |     0  |    —     |  —    | —             |
#
# Medido con `tests/sonda_rampas.gd`: 90 bolas abajo con dos maniquíes (el que
# aporrea y el que atrapa y suelta) y 60 cazas arriba. **La columna que manda no
# es "falla", es "se cae al":** quedarse a medias tiene que ser subir casi entera
# y soltarse desde arriba. Un escape alto sube el porcentaje y BAJA ese número, y
# entonces el fallo se lee como un rebote en la boca y no como no llegar.
#
# Y los tres ceros de abajo no son excepciones escritas a mano: esas cuatro
# curvas no suben, así que la cuesta se apaga sola por geometría. El regreso es
# el que importa —una bola estancada ahí es el cuelgue entre plantas de la tanda
# 0i-C otra vez— y ahora es imposible por construcción, no por acordarse.

## LA ÓRBITA, la de abajo. Sube 660 px por la boca izquierda y 605 por la
## derecha, o sea que es la cuesta más larga de la mesa, y **es también por donde
## engancha el lanzamiento**: con la frontera en 570 un lanzamiento flojo la coge
## y no la corona, que es el segundo escalón de la habilidad del tiro inicial —
## antes solo había uno, engancharla o no.
##
## 950 y no 1000 por el escalón: de 950 a 1000 el fallo salta de 23 % a 43 %
## porque las entradas se agolpan en 570-600, y un número puesto encima de un
## escalón se mueve entero en cuanto alguien toque un punto de control. De 900 a
## 950 va de 19 % a 23 %: eso es el lado plano.
var orbita_velocidad_escape: float = 950.0
## EL CAÑÓN Y EL CARRIL DE RETORNO, y llevan **el mismo número a propósito.** Son
## la pareja simétrica de la planta baja: las dos bocas a y=790, 478 y 476 px de
## subida, y las dos son tiros apuntados desde la pala contraria. Si tuvieran
## cuestas distintas, la diferencia entre los dos tiros dejaría de ser DÓNDE te
## deja la bola —que es lo que las hace dos tiros— y pasaría a ser cuál es más
## fácil, que es un dial escondido.
##
## 1000 sale del cañón, que es el que tiene muestra (40 pasos por la boca contra
## 6 del retorno: el retorno se juega menos porque paga menos). Frontera en 600
## contra entradas de 545-892: falla 1 de cada 4 y se suelta al 91 % de la
## cuesta, que es lo más arriba que se cae ninguna de las nueve. A 1100 salta a
## 55 %: otro escalón, y 1000 se queda debajo.
var canon_velocidad_escape: float = 1000.0
var retorno_velocidad_escape: float = 1000.0
var platillo_radio: float = 14.0
var platillo_tiempo: float = 0.9
var platillo_impulso: float = 780.0
