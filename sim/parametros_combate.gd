class_name ParametrosCombate
extends RefCounted

## Balance del combate. Todo esto es provisional y está para tocarlo: son los
## primeros números que he puesto, no vienen de ningún sitio validado.
##
## La cuenta con la que están puestos: una bola buena hace ~8 bumpers (32) +
## los 3 targets de un banco (36) + la bonificación de banco (25) = 93. Una
## bola mala se queda en 8-12. Con 60 de vida y enemigos que pegan 5-16,
## aguantas entre 4 y 12 drenajes.

# --- Jugador ---
var vida_jugador: int = 60

# --- Daño acumulado mientras la bola vive ---
var dano_bumper: int = 4
var dano_target: int = 12
## Abatir los tres targets de un banco. Es lo que premia apuntar en vez de
## dejar que la bola dé tumbos.
var dano_banco: int = 25

# --- Ritmo de la resolución al drenar ---
var pausa_golpe: float = 0.9    # enseñando el daño que le has metido
var pausa_ataque: float = 0.9   # enseñando el contraataque
