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
var flipper_rebote: float = 0.30
var flipper_longitud: float = 78.0
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
var bumper_rebote: float = 1.8              # restitución en el término normal
var bumper_radio: float = 19.0
var bumper_velocidad_minima: float = 40.0   # (*) umbral del interruptor

# --- Slingshots ---
var slingshot_empuje: float = 700.0
var slingshot_rebote: float = 0.55
var slingshot_velocidad_minima: float = 90.0  # (*) umbral del interruptor

# --- Targets abatibles (*) ---
# No venían del prototipo: la geometría de CONTEXTO no los colocaba. Van en dos
# bancos de tres, pegados a las paredes laterales pero dejando 23 px de carril
# libre por fuera para que se pueda seguir bajando al inlane con el banco en pie.
var target_radio: float = 13.0
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
