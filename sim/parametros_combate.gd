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
## TODA la escala de daño de este archivo está multiplicada por 3 respecto de la
## primera versión (la vida eran 60, el bumper 2, el target 6...). No cambia
## NADA del equilibrio: es resolución.
##
## El motivo: con el reloj partido en dos, el ataque de un enemigo baja a la
## mitad, y en la escala vieja los nueve enemigos se quedaban en 2/2/2/3/3/3/
## 4/4/4. Tres valores distintos para nueve enemigos, con la Calavera perdiendo
## su identidad de pegar fuerte. El redondeo a entero estaba decidiendo el
## balance en vez del diseño. Con ×3 hay sitio para que cada enemigo tenga su
## número.
## SUBE DE 180 A 1080 (x6) al alargar los combates a 2-5 minutos, y no es
## inflar la barra: es resolución, la misma lección del x3 anterior. El coste de
## un combate crece con lo que dura, así que con combates 14 veces más largos y
## la vida en 180 los ataques de la tabla caían a 0,3 y el redondeo a entero
## volvía a decidir el balance en vez del diseño. Con 1080 hay sitio para que
## cada enemigo tenga su número otra vez.
var vida_jugador: int = 1080

# --- Daño base de cada golpe, antes del multiplicador ---
## OJO: estos valores están a la MITAD de los que había con el modelo anterior
## (4 / 12 / 25). Con el combo, una bola larga llega a x4 y multiplicaba por
## tres el daño total de una partida; con la mitad, una bola normal de 8 golpes
## hace ~24 y una muy buena de 25 golpes hace ~136, que es el rango en el que
## estaban los enemigos de data/enemigos.json (60-180 de vida).
var dano_bumper: int = 6
var dano_target: int = 18
## Abatir los tres targets de un banco. Premia apuntar en vez de dar tumbos.
## No cuenta como golpe para el combo: es una bonificación, no un impacto.
var dano_banco: int = 36

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
## Cuántos golpes más pide cada tramo que añada una reliquia por encima del
## último. 12 mantiene la progresión: los tramos van a 5, 10, 20, y el siguiente
## a 32 golpes. Si fuera menos, la reliquia del tramo extra sería un x5 casi
## regalado y se comería a las otras dos del eje de combo.
var golpes_tramo_extra: int = 12

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
## BAJA DE 18 A 9, y el ataque de los enemigos baja a la mitad con él, así que
## la presión POR SEGUNDO no se mueve. Lo que cambia es el tamaño del escalón, y
## el escalón era el fallo de fondo del balance:
##
## Un combate de jugador bueno duraba 9-19 s y uno normal 22-29 s. Con la carga
## en 18 s, el bueno caía por debajo del umbral y NO comía ningún golpe, y el
## normal lo cruzaba siempre y comía uno. La diferencia de castigo entre los dos
## era de cero a uno —una razón infinita— por un grano más grueso que la
## diferencia de habilidad que pretendía medir. Eso es también lo que hacía que
## bajar la vida de los enemigos separase a los perfiles en vez de acercarlos:
## metía los combates del bueno por debajo del umbral y se los regalaba enteros.
##
## Medido en `tests/medir_balance.gd`. Con 9 s el enemigo pega el doble de veces
## la mitad de fuerte, nadie se libra por redondeo, y el combate se siente MÁS
## carrera, no menos: en vez de un mazazo cada 18 s hay presión continua.
var reloj_carga: float = 9.0
## Últimos segundos en los que el reloj avisa, por pantalla y por sonido. Sin
## aviso el golpe llega de la nada y se lee como injusto. Baja a 2 porque tiene
## que caber holgado dentro de la carga: con 3 sobre 9 estaría avisando un
## tercio del tiempo y el aviso dejaría de significar nada.
## Baja a 1,5 porque los relojes de los enemigos empiezan en 6 s: con 2 sobre 6
## el aviso ocupaba un tercio del reloj y dejaba de significar nada.
var reloj_aviso: float = 1.5

## Cuánto pesa el contraataque por drenaje frente al del reloj. Drenar sigue
## costando vida —es invariante— pero ya no es la única presión, así que si
## pegara lo mismo que antes la presión se habría duplicado de golpe.
##
## Baja de 0,5 a 0,2 con medida delante (`tests/medir_balance.gd`). El motivo:
## el coste de un combate resultó ser, casi entero, BOLAS × COSTE DE DRENAR, y
## el número de bolas es vida del enemigo entre daño por bola. Como el daño por
## bola varía unas 19 veces entre jugar mal y jugar bien —el multiplicador de
## combo y el número de golpes se multiplican entre sí—, este factor amplificaba
## esa diferencia en vez de amortiguarla: un jugador flojo comía 34 drenajes
## contra la Gárgola y uno bueno cuatro. A 0,2 el drenaje sigue doliendo pero
## deja de ser lo que decide el run, y quien decide vuelve a ser el reloj, que
## es lo que `DISEÑO.md` §2 quiere.
##
## Y vuelve a 0,5 al partir el reloj en dos: el ataque de los enemigos bajó a la
## mitad con esa misma partida, así que este factor sube otro tanto para dejar
## el coste de DRENAR exactamente donde estaba. El número cambia; lo que cuesta
## drenar, no.
var factor_ataque_drenaje: float = 0.5

# --- Ritmo de la resolución al drenar ---
var pausa_drenaje: float = 0.7   # la bola se ha perdido y el combo cae a x1
var pausa_ataque: float = 0.9    # enseñando el contraataque

## El girador: la bola lo atraviesa y lo hace girar. Cuenta como golpe, igual
## que un bumper, pero pega menos porque es mucho más fácil de encadenar.
var dano_girador: int = 3

## El pin de la bóveda. Es el golpe más pequeño de la mesa a propósito: no se
## apunta a un pin, se cae en él, y lo que paga es que caen muchos seguidos.
## Uno solo no se nota; una entrada buena encadena diez o doce.
var dano_pin: int = 2

## SI EL PIN CUENTA PARA EL COMBO, Y ESTE ES EL DIAL DE LA TANDA.
##
## Los tramos de combo van a 5, 10 y 20 golpes, y una entrada a la bóveda son
## diez o doce toques de una tacada. Con esto encendido, cualquiera llega a ×4
## traqueteando, y eso no sube el suelo: BAJA EL TECHO, porque la brecha entre
## jugar mal y jugar bien —medida en 20×, y 8,4× sin el multiplicador— es casi
## toda multiplicador. Regalarlo es cobrarle al que juega bien.
##
## Apagado, el pin es lo que dice ser: daño pequeño y constante que arregla que
## la mitad de arriba de la mesa no compense, sin tocar la escala de habilidad.
##
## Se queda expuesto porque esto se decide jugando, no leyendo: encendido se
## siente mucho mejor —los números suben mientras traquetea— y puede que ese
## regalo valga lo que cuesta. Está medido por las dos ramas en ESTADO.md.
var pin_suma_combo: bool = false

# --- Críticos ---
## Todo golpe puede salir crítico. Es de las cosas más baratas que se le pueden
## poner a un juego de números: no cambia la media casi nada y cambia mucho cómo
## SE SIENTE, porque de vez en cuando sale un número grande y eso se recuerda.
##
## La probabilidad base es pequeña a propósito: lo que la sube son las reliquias
## (`suma_prob_critico`), y así el crítico es además un eje de build que se nota
## sin tocar ningún otro número.
var prob_critico: float = 0.06
## Por cuánto multiplica. Dos es lo legible: un crítico tiene que reconocerse por
## el tamaño del número sin leerlo.
var factor_critico: float = 2.0

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
var dano_rampa: int = 30
var dano_rampa_fuerte: int = 78
## Baja de 14 a 8 a propósito: si el platillo pagara además el mejor daño, el
## robo de reloj sería un extra y no una decisión. Lo que da es tiempo.
var dano_platillo: int = 24

## Cuánta carga del reloj le quita sacar la bola del platillo, en fracción.
## Con 0,35 y un reloj de 18 s son unos 6 s regalados: se nota de verdad, que
## es lo que hace que merezca la pena buscar un tiro escondido.
##
## Con el reloj en 9 s, 0,35 son ~3 s en vez de ~6. Se queda igual A PROPÓSITO:
## lo que importa no son los segundos sino la fracción de barra, que es lo que
## el jugador ve. Si se subiera para "recuperar los 6 segundos", el platillo
## pasaría a robar dos tercios de la barra y sería el tiro obligatorio.
var platillo_atrasa_reloj: float = 0.35
