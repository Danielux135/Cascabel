class_name ParametrosCombate
extends RefCounted

## Balance del combate. Todo esto es provisional y está para tocarlo: son los
## primeros números que he puesto, no vienen de ningún sitio validado.
##
## El daño se aplica EN VIVO al golpear. Lo que se acumula es el multiplicador
## de combo, que sube por número de golpes seguidos sin drenar y se resetea al
## drenar. O sea que aguantar la bola no guarda daño para el final: hace que
## cada golpe siguiente valga más.

# --- Jugador ---
var vida_jugador: int = 60

# --- Daño base de cada golpe, antes del multiplicador ---
## OJO: estos valores están a la MITAD de los que había con el modelo anterior
## (4 / 12 / 25). Con el combo, una bola larga llega a x4 y multiplicaba por
## tres el daño total de una partida; con la mitad, una bola normal de 8 golpes
## hace ~24 y una muy buena de 25 golpes hace ~136, que es el rango en el que
## estaban los enemigos de data/enemigos.json (60-180 de vida).
var dano_bumper: int = 2
var dano_target: int = 6
## Abatir los tres targets de un banco. Premia apuntar en vez de dar tumbos.
## No cuenta como golpe para el combo: es una bonificación, no un impacto.
var dano_banco: int = 12

# --- Multiplicador de combo ---
## Tramos: a partir de `golpes` golpes seguidos sin drenar, el daño se
## multiplica por `factor`. Tal cual está: x1 hasta 4 golpes, x2 hasta 9,
## x3 hasta 19, x4 a partir de 20.
var tramos_combo: Array = [
	{"golpes": 0,  "factor": 1},
	{"golpes": 5,  "factor": 2},
	{"golpes": 10, "factor": 3},
	{"golpes": 20, "factor": 4},
]

# --- El reloj del enemigo ---
## `DISEÑO.md` §2. El enemigo pega por reloj, drenes o no. Es lo que mueve la
## presión fuera del drenaje: aguantar la bola sigue siendo lo mejor, pero deja
## de ser gratis, porque el reloj corre igual mientras juegas.
##
## Segundos de carga. ES EL DIAL de la fase 3A: decide si el combate es una
## carrera tensa o un paseo. Solo se sabe jugando.
## De dónde sale el 18: la bola dura ~10 s y los combates largos rondan el
## minuto, o sea unos tres golpes de reloj por combate. Con los ataques de
## `data/enemigos.json` (6 a 16) eso son 18-48 de los 60 de vida, más lo que
## cueste drenar. Menos de 15 y los enemigos de abajo de la tabla son un muro;
## más de 25 y el reloj deja de presionar.
var reloj_carga: float = 18.0
## Últimos segundos en los que el reloj avisa, por pantalla y por sonido. Sin
## aviso el golpe llega de la nada y se lee como injusto.
var reloj_aviso: float = 3.0

## Cuánto pesa el contraataque por drenaje frente al del reloj. Drenar sigue
## costando vida —es invariante— pero ya no es la única presión, así que si
## pegara lo mismo que antes la presión se habría duplicado de golpe. A la
## mitad, drenar es el tropiezo que describe `DISEÑO.md` §2 y no la catástrofe.
var factor_ataque_drenaje: float = 0.5

# --- Ritmo de la resolución al drenar ---
var pausa_drenaje: float = 0.7   # la bola se ha perdido y el combo cae a x1
var pausa_ataque: float = 0.9    # enseñando el contraataque

## El girador: la bola lo atraviesa y lo hace girar. Cuenta como golpe, igual
## que un bumper, pero pega menos porque es mucho más fácil de encadenar.
var dano_girador: int = 1

## Completar la órbita entera y sacar la bola del platillo. Pagan bien porque
## las dos hay que buscarlas: la órbita pide un tiro fuerte y limpio, y el
## platillo está escondido bajo el arco.
## Cada recorrido paga distinto, que es lo que los hace tres tiros y no uno
## repetido tres veces:
##   orbita   -> sube el multiplicador un tramo de golpe, y paga poco daño
##   retorno  -> te deja la bola en la otra pala; paga poco, el premio es poder
##               encadenar
##   canon    -> el golpe gordo de un solo impacto, y te escupe la bola cruzada
##               y rápida a la pala contraria: el pago grande se paga con un
##               retorno difícil
##   platillo -> atrasa el reloj del enemigo. Es el único tiro que paga en algo
##               que no es daño, y por eso es el que cambia cómo juegas: cuando
##               vas justo de vida dejas de ir a por daño y vas a por tiempo
var dano_rampa: int = 10
var dano_rampa_fuerte: int = 26
## Baja de 14 a 8 a propósito: si el platillo pagara además el mejor daño, el
## robo de reloj sería un extra y no una decisión. Lo que da es tiempo.
var dano_platillo: int = 8

## Cuánta carga del reloj le quita sacar la bola del platillo, en fracción.
## Con 0,35 y un reloj de 18 s son unos 6 s regalados: se nota de verdad, que
## es lo que hace que merezca la pena buscar un tiro escondido.
var platillo_atrasa_reloj: float = 0.35
