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

# --- Flippers ---
var flipper_velocidad_giro: float = 22.0    # rad/s
## La pala no rebota, empuja: el rebote solo actúa cuando está quieta, y ahí lo
## que hace falta es que la bola se quede, no que salte. Con 0,30 la bola
## botaba encima de la pala y perdía el contacto, así que el agarre se
## encendía y se apagaba y no había forma de asentarla para apuntar.
var flipper_rebote: float = 0.10
## Bajado de 78 a 64: era el dial de dificultad que quedaba pendiente. Con 78 el
## hueco central medía 22 px y con 64 mide 47, o sea que drenar por el medio
## deja de ser un objetivo diminuto.
var flipper_longitud: float = 64.0
var flipper_radio: float = 8.0
var flipper_reposo_izq: float = 28.0        # grados, Y hacia abajo
var flipper_activo_izq: float = -32.0       # recorrido de 60°
var flipper_reposo_der: float = 152.0
var flipper_activo_der: float = 212.0

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

## (*) Atrapar la bola. Con el flipper levantado Y QUIETO (o sea, cuando ya ha
## llegado arriba) y la bola apoyada encima, se frena hasta pararse en vez de
## resbalar por la pala. Es lo que permite apuntar antes de soltar.
## En movimiento no agarra: ahí lanza como siempre, que es lo que da el tacto.
## Subido de 16 a 40: con 16 la bola seguía deslizando casi medio segundo por la
## pala antes de pararse, y en ese medio segundo ya se había ido de la punta.
## Con 40 se asienta en menos de 0,1 s y se queda donde cae.
var flipper_agarre: float = 40.0            # frenado tangencial, 1/s
## Subido de 300 a 700: con 300 el agarre no llegaba a encenderse casi nunca.
## La bola tiene tope 1500 y baja por la mesa muy por encima de 300, así que
## Daniel solo consiguió asentarla UNA vez en toda una tanda: la única en que
## llegó lenta. El umbral venía de la mesa pequeña y aquí sobraba.
var flipper_agarre_velocidad: float = 700.0 # por encima de esto no agarra
var flipper_agarre_omega: float = 0.6       # rad/s; si la pala gira, no agarra

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
