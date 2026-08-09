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

# --- Ritmo de la resolución al drenar ---
var pausa_drenaje: float = 0.7   # la bola se ha perdido y el combo cae a x1
var pausa_ataque: float = 0.9    # enseñando el contraataque

## El girador: la bola lo atraviesa y lo hace girar. Cuenta como golpe, igual
## que un bumper, pero pega menos porque es mucho más fácil de encadenar.
var dano_girador: int = 1
