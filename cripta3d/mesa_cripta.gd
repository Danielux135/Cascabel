extends "res://prueba3d/mesa_orbita.gd"

## SEGUNDA PRUEBA 3D — «CRIPTA», la mesa.
##
## Daniel lo dijo al encargarla: *«la mesa de Cascabel original no tiene ningún
## diseño. Haz la mesa como creas conveniente… el diseño de la mesa siempre puede
## rehacerse»*. Así que esta NO es la mesa del juego, y tampoco se inventa un
## trazado desde cero: parte del esqueleto de «ÓRBITA» (`mesa_orbita.gd`), que es
## el único trazado de la prueba que está MEDIDO —sesenta bolas con sonda, la
## caza determinista, cero rescates— y le cambia el tema entero y le añade piezas.
##
## Por qué heredar y no copiar: lo que se juzga en esta prueba son los GRÁFICOS.
## Con el mismo esqueleto debajo, quien compare ÓRBITA con CRIPTA está comparando
## dos direcciones de arte sobre la misma mesa, que es justo la pregunta. Y lo
## que se añade aquí se añade ENCIMA, pasando por la sonda (`sonda_cripta.gd`).
##
## EL TEMA: una cripta. Cada pieza de ÓRBITA tiene aquí su sitio, y los
## identificadores NO cambian (la caza y los marcadores los usan): lo que cambia
## es el RÓTULO, que es lo que se lee. Un identificador no es un rótulo.
##
##   identificador   en ÓRBITA            en CRIPTA
##   -------------   ------------------   -----------------------------------
##   lanzadera       la lanzadera         EL CAMPANARIO: la subida del campanero
##   (bumpers)       el sol               LOS BRASEROS: tres engranajes con ascua
##   (targets)       los satélites        LAS LÁPIDAS
##   (girador)       el púlsar            EL TORNO
##   orbita          la órbita            LA GALERÍA
##   cometa          el cometa            EL TOBOGÁN
##   estacion        la estación          EL CORO: la tribuna alta, con su pala
##   (platillo)      el agujero negro     EL SARCÓFAGO
##   bajada          la bajada            LA ESCALERA
##   gusano          el agujero de gusano LA CATACUMBA: donde se esconde el espectro
##
## LO QUE CRIPTA AÑADE ENCIMA. Nada de lo de ÓRBITA se mueve: ni el pie de la mesa,
## ni la plaza de la caza, ni una boca ni un punto de control. Cada pieza de aquí
## abajo lleva al lado lo que midió la sonda al ponerla.
##
##   pieza               qué es para el motor            cómo se lee desde fuera
##   -----------------   -----------------------------   ---------------------------
##   LA CAMPANA MAYOR    la barra de carga, que ÓRBITA   `carga`, `descarga_armada`,
##                       dejó apagada                    `descarga_restante`
##   EL TORNO DEL CORO   un girador más                  `giradores[TORNO_CORO]`
##   LOS ESCUDOS         un banco más de tres targets    `bancos[BANCO_ESCUDOS]`

const ROTULOS := {
	"lanzadera": "CAMPANARIO",
	"orbita": "GALERÍA",
	"cometa": "TOBOGÁN",
	"estacion": "CORO",
	"bajada": "ESCALERA",
	"gusano": "CATACUMBA",
	"bumpers": "BRASEROS",
	"targets": "LÁPIDAS",
	"girador": "TORNO",
	"platillo": "SARCÓFAGO",
	"campana": "CAMPANA MAYOR",
	"girador_coro": "TORNO DEL CORO",
	"escudos": "ESCUDOS",
}

## Los índices de lo que hay dos veces, para que nadie escriba un 1 a pelo. Son
## los que llevan las señales: `girador_girado(punto, INDICE, fuerza)`,
## `target_abatido(punto, BANCO)` y `banco_completado(punto, BANCO)`.
const TORNO_GALERIA := 0
const TORNO_CORO := 1
const BANCO_LAPIDAS := 0
const BANCO_ESCUDOS := 1

## Cómo quiere dibujarse cada torno, uno por girador y en el mismo orden que
## `giradores`. La simulación no lo usa —para ella un girador es un punto y un
## radio—: lo lee la vista. `eje` es la dirección del eje del molinete, unitaria,
## o sea perpendicular a por donde lo cruza la bola; `boca` es el recorrido cuya
## entrada guarda; `clave` es su entrada en `ROTULOS` y `rotulo` lo que se lee.
var info_tornos: Array[Dictionary] = []
## Lo mismo para cada banco, en el orden de `bancos`. Un target es una cápsula y
## no tiene cara: `cara` es la normal, unitaria, del lado por el que le da la
## bola, que es hacia donde tiene que mirar lo que se dibuje.
var info_bancos: Array[Dictionary] = []

func _construir() -> void:
	super._construir()
	var antes := colisionadores.size()
	_campana()
	_tornos()
	_escudos()
	# `mesa_orbita.gd` reparte el rozamiento al acabar SU construcción. Lo que se
	# añade después nace con rozamiento cero: se le da aquí el de su tipo.
	for i in range(antes, colisionadores.size()):
		colisionadores[i].friccion = p.friccion_de(colisionadores[i].tipo)

# ------------------------------------------------------------- la campana mayor

## LA CAMPANA MAYOR es la barra de carga del motor (`Mesa.cargar_barra`), que
## ÓRBITA apagó poniendo `carga_entradas` en mil millones. Aquí cuelga sobre la
## mesa: toda entrada de rampa tira de la cuerda —llegues o no, y más cuanto más
## fuerte entres—, llena queda ARMADA, y la siguiente rampa que COMPLETES la hace
## tocar. Mientras toca (`descarga_restante`) no se carga.
##
## Y el lanzamiento también tira, que aquí no es un accidente del motor sino el
## tema: la lanzadera es EL CAMPANARIO, la subida del campanero.
##
## Los tres números están medidos con `sonda_cripta.gd`, cinco series de sesenta
## bolas (300 bolas) cada fila:
func _campana() -> void:
	# CUÁNTAS ENTRADAS LIMPIAS LA LLENAN. Con la barra apagada, el figurante de
	# la sonda entra en 4,35 rampas por bola y esas entradas cargan 3,91
	# «entradas limpias» (el cuadrado de velocidad/escape): 1,04 el campanario,
	# 0,97 el tobogán, 0,73 la galería, 0,58 el coro, 0,39 la catacumba y 0,20 la
	# escalera. El encargo es que toque una vez cada una o dos bolas:
	#
	#   | carga_entradas | toca una vez cada | veces en 300 bolas |
	#   | 6              | 1,92 bolas        | 156                |
	#   | 5              | 1,64 bolas        | 183                |
	#
	# No es 3,91 a secas porque cada toque se come entrada y media: mientras
	# suena no carga, y lo que sobra de la entrada que la llena se pierde. Se
	# queda en 5 y no más abajo porque el figurante juega peor que una persona:
	# quien meta el doble de rampas la toca cada bola. Con la mesa entera —los
	# escudos puestos— y 900 bolas: 525 toques, uno cada 1,71 bolas.
	p.carga_entradas = 5.0
	# CUÁNTO SUENA. El figurante entra en una rampa cada 3,1 s, así que 4 s
	# llegan hasta el tiro siguiente y se apagan solos: no se sostiene sin palas.
	# Con 5 de carga suena el 17 % del tiempo (667 s de 4.020), y tres de cada
	# diez toques los corta el drenaje antes de acabar (161 de 525).
	p.descarga_tiempo = 4.0
	# LA CAMPANA NO EMPUJA LA BOLA. En Cascabel la rampa que gasta la descarga
	# suelta la bola al doble de velocidad; aquí eso convierte el premio en un
	# castigo, porque cada recorrido de esta mesa está frenado para dejar la bola
	# servida en la pala siguiente y el doble se la pasa de largo. Cuántas veces
	# drena la bola antes de 4 s de coronar una rampa:
	#
	#   | factor de salida | sin tocar | tocando la campana | bola media |
	#   | 2,0              | 18 %      | 49 %               | 11,2 s     |
	#   | 1,0              | 18 %      | 17 %               | 13,4 s     |
	#
	# Y por dentro es peor que la media: con el doble, tocarla en el tobogán fue
	# perder la bola 37 veces de 37, y en la galería 35 de 36. El tobogán lo
	# explica solo, y es una cuenta: entrando a 800 px/s sale hacia la derecha a
	# 240 y cae en x≈152, sobre la pala izquierda, cuya punta está en x=168. Al
	# doble —450, que es donde lo deja el tope de la mesa— cae en x≈235, pasado
	# el hueco entre palas; y con un 1,2 ya cae en la punta. Ahí no cabe ningún
	# empujón. A 1,0 la descarga no cambia ni un rebote —la mesa da la bola media
	# de ÓRBITA, 13,4 s en esas mismas cinco series— y lo que queda es lo que
	# tiene que ser: la campana suena.
	p.descarga_factor_salida = 1.0

## LA CAMPANA SE REARMA SIN AVISAR, y aquí se le pone el aviso. Al servir bola
## con la campana armada, `Mesa.cortar_descarga` la desarma pero deja la carga en
## 1; la primera entrada de la bola siguiente —el campanario— la vuelve a armar, y
## como la carga no ha cambiado, `Mesa.cargar_barra` no emite nada. Para quien
## dibuja la campana eso es una campana que toca sin haber estado armada. No se
## toca la cuenta: solo se dice lo que el motor calla.
func cargar_barra(r: Rampa, v_entrada: float) -> void:
	var estaba := descarga_armada
	var antes := carga
	super.cargar_barra(r, v_entrada)
	if descarga_armada and not estaba and is_equal_approx(antes, carga):
		carga_cambiada.emit(carga, true)

# ------------------------------------------------------------------- los tornos

func _tornos() -> void:
	# El de ÓRBITA, que sigue donde estaba: (50, 940), girador 0. Lo cruza poco
	# de lo que va a la galería (52 entradas de 595, el 9 %): casi todos sus
	# giros son de bolas que bajan por la banda izquierda. No se mueve porque es
	# de ÓRBITA; se apunta para que nadie lo dibuje como la puerta de la galería.
	info_tornos.append({"rotulo": ROTULOS["girador"], "clave": "girador",
		"boca": "orbita", "eje": Vector2.RIGHT})

	# EL TORNO DEL CORO, girador 1. La boca del coro está en (250, 892) y engancha
	# a 18 px, pero la bola no llega recta desde la pala: sube frenándose, así
	# que entra desde abajo y a la izquierda. El sitio se midió con una rejilla de
	# noventa tornos de prueba alrededor de la boca —un torno no choca, caben
	# todos a la vez— contando, de las 209 entradas al coro de 300 bolas, cuántas
	# cruzaban cada uno:
	#
	#   | torno en   | entradas que lo cruzan |
	#   | (250, 906) |  71                    |   justo debajo de la boca
	#   | (244, 906) | 129                    |
	#   | (238, 906) | 153 (73 %)             |   el mejor de la rejilla
	#   | (232, 906) | 133                    |
	#
	# Ya en su sitio, con la mesa entera y 900 bolas: 783 giros, 387 de las 538
	# entradas al coro pasan por él (72 %), y la bola lo cruza subiendo con rumbo
	# (0,26, −0,89). El eje es la perpendicular a ese rumbo.
	_girador(Vector2(238, 906))
	info_tornos.append({"rotulo": ROTULOS["girador_coro"], "clave": "girador_coro",
		"boca": "estacion", "eje": Vector2(0.96, 0.28).normalized()})

# ------------------------------------------------------------------ los escudos

## LOS ESCUDOS: tres targets abatibles en la pared del carril lanzador, debajo
## del coro. Es el BOLSILLO de la mesa: lo que no engancha ni el coro ni la
## catacumba sube por aquí, da en el faldón de la tribuna o en la pared y cae.
##
## POR QUÉ AQUÍ. El bolsillo era el sumidero del outlane derecho. Medido en 300
## bolas sin escudos: 192 visitas al bolsillo, 102 llegan a la pared, y de las 47
## bolas que se pierden por el outlane derecho 38 salían de aquí menos de 3 s
## antes. La pared desnuda devuelve la bola con el centro en x=349, encima de la
## boca del outlane (de 337 a 358). Un escudo en pie la devuelve en x=332 —341
## de cara menos 9 de radio—, a la izquierda de la punta del separador (337): la
## que muere contra un escudo cae al INLANE. Mientras están en pie, los escudos
## guardan el outlane; tumbarlos lo abre.
##
## LO QUE DICE LA SONDA, con las mismas quince series (900 bolas) sin y con ellos.
## Las cuentas van por cada 300 bolas:
##
##   |                          | sin escudos    | con escudos    |
##   | bola media               | 12,70 ± 0,28 s | 12,50 ± 0,23 s |
##   | entradas al coro         | 182            | 179            |
##   | entradas a la catacumba  | 59             | 57             |
##   | se va por el outlane der.| 47             | 36             |
##   | escudos abatidos         | —              | 87             |
##   | paradas en el bolsillo   | 0              | 0              |
##
## Ni la bola media se mueve —0,2 s, menos que su error— ni se cierra ninguna
## boca. El banco se completa 13 veces en 900 bolas: es un tiro, no un trámite.
## Y mirando solo el bolsillo (300 bolas): de las que se pierden menos de 3 s
## después de salir de él, por el outlane derecho se iban 38 y se van 18; la
## visita más larga dura 1,4 s, así que ahí dentro tampoco se queda rebotando.
##
## Y LA PREGUNTA DE SIEMPRE: no si la bola cabe, sino si se queda. Detrás de los
## escudos quedan 9 px hasta la pared y la bola mide 18: no cabe. El único
## asiento posible es el hombro de arriba de un escudo contra la pared, y para
## quedarse ahí la bola tendría que posarse a menos de 30 px/s
## (`target_velocidad_minima`), o sea caer menos de un cuarto de píxel: lo que
## llega de más alto abate el escudo y el asiento desaparece. Las 900 bolas
## dieron UNA parada y no es del banco: en (41, 1106), la punta del separador
## del outlane IZQUIERDO, que es de ÓRBITA.
##
## Las otras dos posiciones que se probaron (300 bolas cada una) tampoco hacían
## daño, pero no guardaban nada: pegados a la pared (x=354) el outlane derecho
## se queda en 47; colgando del faldón del coro (y=804), en 40.
##
## Para la caza son tres colisionadores más, y la plaza se calcula con ellos
## puestos: la arista más cercana les pasa a 46 px y hacen falta 19. El grafo
## sale con las mismas 29 aristas (`sonda_caza_cripta.gd`).
func _escudos() -> void:
	info_bancos.append({"rotulo": ROTULOS["targets"], "clave": "targets",
		"cara": _cara_de(BANCO_LAPIDAS)})
	# Tres escudos de 30 px con 10 de hueco, de y=820 a y=930: de ahí para arriba
	# quedan 24 px hasta el faldón del coro (796), que es por donde entra la bola
	# a tumbar el primero desde arriba, y por abajo 32 hasta la boca de la
	# catacumba (310, 962), que engancha a 18.
	_banco_targets(Vector2(345, 835), Vector2(345, 915), 3)
	info_bancos.append({"rotulo": ROTULOS["escudos"], "clave": "escudos",
		"cara": _cara_de(BANCO_ESCUDOS)})

# PROBADO Y DESCARTADO: UN PLATILLO EN EL SUELO DEL BOLSILLO. Era la quinta
# pieza posible —un pozo al fondo, en (300, 818), que se tragara lo que sube por
# el medio y lo escupiera cruzando la plaza hasta la pala izquierda—. Medido con
# los escudos puestos, 300 bolas: se traga 40 y 20 se pierden antes de 3 s de
# escupirlas, el 50 %; sin pozo, de lo que entra al bolsillo se pierde el 33 %.
# Desde ahí arriba la bola llega a la pala a 1.200 px/s caiga como caiga —son
# 355 px de caída—, y además les quita un tercio de los golpes a los escudos
# (58 contra 87). El único sitio desde el que un platillo podría devolverla
# despacio es la boca de la catacumba, y para apuntarle hay que estar debajo y
# a su izquierda: en la plaza de la caza. No se pone.

## La normal de un banco por el lado que mira al campo, o sea hacia las palas.
func _cara_de(banco: int) -> Vector2:
	var pieza: Colisionador = bancos[banco][0]
	var a_lo_largo := (pieza.b - pieza.a).normalized()
	var normal := Vector2(-a_lo_largo.y, a_lo_largo.x)
	var palas := (p.flipper_eje_izq + p.flipper_eje_der) * 0.5
	return normal if normal.dot(palas - centro_banco(banco)) > 0.0 else -normal
