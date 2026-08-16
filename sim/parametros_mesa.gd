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

# --- Campo de pines (*) ---
# Pachinko: la bola sale disparada del racimo, traquetea por la bóveda que hay
# bajo el arco y vuelve a caer al racimo. No venían del prototipo.
#
# LOS PINES NO EMPUJAN, Y ESO ES EL DISEÑO ENTERO. Un bumper es un actuador y
# fabrica energía si te descuidas —ya pasó, ver `bumper_rebote`—; un pin solo
# recibe. Cada toque le quita algo a la bola, así que la bóveda se vacía sola y
# no puede convertirse en un bucle que se sostiene sin las palas, que es lo que
# `PLAN.md` §3B prohíbe.
#
# Y VAN DONDE NO ESTORBAN: la bóveda está por encima del racimo, fuera de los
# carriles por los que la bola BAJA. Meter pines en las bandas haría el descenso
# aleatorio, y con el outlane ahí abajo eso es perder la bola sin jugarla.
var pin_radio: float = 5.0
## Metal, y sin actuador: el rebote es de pared larga. Con más, la bola se queda
## viviendo arriba; con menos, cruza la bóveda sin traquetear.
var pin_rebote: float = 0.55
## Umbral del aviso, no de la física. Es lo que separa "esto ha sido un golpe"
## de "la bola está rozando el pin": sin él, una bola apoyada emitiría un aviso
## por subpaso, que es la trampa que ya cazamos con los bumpers (480 golpes por
## segundo). Una bola apoyada llega al contacto con lo que le da la gravedad en
## un subpaso —1750/480 = 3,6 px/s—, o sea que 70 la deja fuera de sobra.
var pin_velocidad_minima: float = 70.0
## Rejilla al tresbolillo: `pin_paso` de separación entre centros de la misma
## fila y `pin_alto_fila` entre filas, con las impares desplazadas medio paso.
##
## LOS DOS NÚMEROS SON UN INVARIANTE DISFRAZADO. El hueco por el que pasa la
## bola es `paso − 2·radio` en horizontal y `hipotenusa(paso/2, alto) − 2·radio`
## en diagonal, y la bola mide 18. Con 36 y 29 salen 26 y 24,1: pasa por los dos
## con holgura. El suelo es paso > 28; y con ese paso, alto > 21,4. Por debajo
## la bóveda deja de ser un campo de pines y pasa a ser una trampa de acuñar.
## Lo comprueba la batería, no la buena voluntad.
var pin_paso: float = 36.0
var pin_alto_fila: float = 29.0
## Dónde empieza la primera fila. 707 la deja bajo el arco (que en el centro
## abre hasta y=660) y por encima de los bumpers de arriba (y=787 menos 19 de
## radio = 768).
var pin_y: float = 707.0
## Tres filas pedidas, dos colocadas: la tercera cae encima del racimo y el
## filtro de holgura la tira entera. Se deja en 3 a propósito, para que apretar
## `pin_alto_fila` la recupere sin tocar nada más.
var pin_filas: int = 3

## EL CEDAZO, Y ESTÁ AQUÍ PORQUE LO PIDIÓ LA MEDIDA. La bóveda sola no la toca
## nadie: el tiro desde la cuna —el único tiro repetible de la mesa— sube a
## y=894 de media, y el mejor de 42 se queda en y=751, quince píxeles por debajo
## de la fila de abajo de la bóveda. Cero pines tocados en 42 tiros.
##
## Esta fila iba en y=875, que es la banda que cruza TODO lo que baja de la zona
## alta. Y SE QUEDA APAGADA, porque medirla contestó a una pregunta que no
## habíamos hecho: esa banda no es hueco libre, **es el pasillo de tiro**.
##
## Encendida, los tiros desde la cuna tocaban pin (10 de 21 por la izquierda, 9
## de 21 por la derecha) pero dejaban de subir: el mejor pasaba de y=751 a
## y=884. Y los dos pines de los extremos caen justo debajo de las bocas del
## retorno y del cañón, que están en y=790: o sea que el precio de que la bola
## traquetee era tapar dos de los seis tiros de `DISEÑO.md` §4.
##
## Se deja el parámetro, no el apaño: a 1 vuelve, y lo que haría falta antes es
## que `_cabe_pin` sepa de PASILLOS DE TIRO y no solo de bocas. Está apuntado en
## ESTADO.md.
var pin_cedazo_y: float = 875.0
var pin_cedazo_filas: int = 0
## Hueco mínimo que un pin tiene que dejar contra TODO lo que ya está puesto
## —arco, paredes, bumpers, platillo y bocas de recorrido— para que se coloque.
## Por debajo del diámetro de la bola sería un sitio donde acuñarse; 24 deja
## 3 px de aire por lado sobre los 18 que mide.
var pin_holgura: float = 24.0

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
var platillo_radio: float = 14.0
var platillo_tiempo: float = 0.9
var platillo_impulso: float = 780.0
