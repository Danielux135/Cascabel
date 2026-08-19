#!/usr/bin/env python3
"""
BANCO DE PROTOTIPOS DE SONIDO. Hermano pequeño de `sonidos.py`, y separado de él
por una razón concreta y no por orden.

`sonidos.py` genera los sonidos QUE EL JUEGO USA, y la batería tiene un candado
en los dos sentidos: falla si el juego pide un wav que no existe, y falla si
existe un wav que el juego no pide ("no hay ningun wav generado que el juego no
use"). Ese candado es bueno —un wav generado y sin enganchar es un evento mudo
esperando, que es la avería que abrió la tanda 0h2— y no se toca.

Pero deja sin sitio a lo que hay que poder OÍR ANTES DE CONSTRUIR. Ese sitio es
esto: escribe en `assets/sonido_pruebas/`, que la batería no mira, y no toca
`SONIDOS` ni `NodoSonido.AJUSTES`.

    LA REGLA, EN UNA LÍNEA
    Un sonido vive aquí mientras no exista la cosa que lo dispara. El día que
    exista, su receta se MUEVE a `sonidos.py` y su ajuste a `nodo_sonido.gd`,
    en el mismo commit. Nunca antes, nunca en los dos sitios.

Uso:
    python3 sonidos_pruebas.py                # regenera todos
    python3 sonidos_pruebas.py --uno cascabel # solo uno
    python3 sonidos_pruebas.py --listar       # qué hay, cuánto dura, dónde vive

El vocabulario de parámetros es el de `sonidos.py`: se importa su sintetizador
entero, así que lo que suene aquí sonará idéntico al mudarse.

------------------------------------------------------------------------------
EL HALLAZGO DE LA TANDA, que es de los que cambian más de un sonido:

`armonicos` acepta MÚLTIPLOS NO ENTEROS. `_capa` hace `fase * multiplo` sin
redondear nada, así que `armonicos=[(1.83, 0.4)]` es legal y suena a metal.

Eso importa porque **toda la mesa es armónica**: cuadradas y triángulos con
múltiplos enteros, que es lo que hace que todo suene a madera, piedra y plástico.
Un parcial en 1,83 no pertenece a ninguna serie armónica, y el oído lee eso como
UNA SOLA COSA: metal. Es un material entero que el juego no tenía, y estaba
disponible sin escribir una línea de sintetizador.

Lo destapó Fátima oyendo la variante D de la puerta: *"la D tiene un toque
especial, necesitamos más sonidos así"*. Los ratios de abajo salen de campanas de
verdad —1 : 1,19 : 1,51 : 2,02 para una campana grande; más apretados y más
agudos para un cascabel— y por eso no suenan a sintetizador, suenan a objeto.

Y hay una deuda que pagar con esto: **el juego se llama Cascabel y no tenía
ningún sonido de cascabel.**
"""

import argparse
import os
import sys
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sonidos as S

SALIDA = os.path.join("assets", "sonido_pruebas")


def semilla(nombre):
    """SEMILLA ESTABLE, y arregla un fallo de verdad: estaba puesto
    `abs(hash(...)) % 1000`, y el hash de una cadena en Python es ALEATORIO POR
    PROCESO desde la 3.3. O sea que este banco daba un wav distinto en cada
    ejecucion — medido: 609, 773 y 614 para el mismo nombre en tres arranques.

    Solo afecta a las capas de ruido, asi que el caracter no cambiaba; pero un
    proyecto que decide cosas midiendo no puede tener un generador que no
    reproduce. `crc32` si es estable entre ejecuciones y entre maquinas."""
    return zlib.crc32(nombre.encode("utf-8")) % 1000

# --------------------------------------------------------------- el cascabel
#
# *"Los cascabeles parece que sean 2 sonidos que acaban de distinta forma. Ha de
# ser un sonido agradable y coherente."* — Fátima, tercera vuelta.
#
# Diagnóstico exacto, y con DOS causas.
#
# LA PRIMERA se ve midiendo cuánto pesa el agudo en cada sexto del sonido. En la
# versión anterior iba 5,0 -> 14,5 -> 5,3 -> 2,6: eso no es un timbre que
# evoluciona, **es un segundo sonido que llega tarde y se va antes**. Y lo era
# literalmente — capas con `retardo` distinto y con `caida` de 2,2 a 9,0 en el
# mismo sonido, así que los agudos se morían a los 450 ms y el grave seguía solo
# 1,2 s más. "Dos sonidos que acaban de distinta forma", tal cual.
#
# LA SEGUNDA es más fina, y es la que impedía que cuajara ni siquiera el limpio:
# **`armonicos` sobre un TRIÁNGULO no da los parciales que pides.** Un triángulo
# ya trae su propia serie en 3f, 5f, 7f, así que un parcial pedido en 1,37 llega
# con la suya detrás (4,11, 6,85...). El resultado son dos peines superpuestos:
# uno armónico, que el oído lee como una NOTA, y otro inarmónico, que lee como
# una CAMPANA. Dos cosas sonando a la vez. Con `seno` de portadora cada parcial
# es un tono puro y suena exactamente lo que está escrito.
#
#     LA REGLA QUE SALE DE LAS DOS, y sirve para cualquier sonido que tenga que
#     leerse como UN objeto:
#
#         Todas las capas con el MISMO dur, el MISMO caida y el MISMO ataque.
#         Ningún retardo. Onda seno cuando los parciales importen.
#
# La única excepción es el badajo, y dura 14 ms: cabe dentro del ataque, así que
# el oído lo funde con el golpe en vez de contarlo aparte.
#
# Medido: el agudo por sextos pasa de 9,7 -> 3,0 a **18,3 -> 18,2**. Plano.

## Parciales de cascabel: apretados y agudos. Los de una campana grande son más
## abiertos (1 : 1,19 : 1,51 : 2,02) y por eso suena a iglesia y no a cascabel.
ARM = [(1.37, 0.42), (1.84, 0.26), (2.43, 0.15), (3.17, 0.08)]

## Parciales de campana GRANDE: abiertos y graves. Es la diferencia entre una
## iglesia y un objeto que llevas encima.
ARM_CAMPANA = [(1.19, 0.45), (1.51, 0.30), (2.02, 0.20), (2.67, 0.12)]


def capa(f, dur, caida, ataque, vol, arm=None, det=0.0, crush=0):
    """Una capa de objeto inarmónico. `det` la desafina para que bata contra su
    gemela. Todas las capas de un mismo sonido comparten dur, caida y ataque:
    esa es la regla de arriba, y aquí está escrita como firma de función para
    que cueste saltársela."""
    return dict(onda="seno", f0=f + det, f1=f + det - 4, armonicos=arm or [],
                dur=dur, caida=caida, ataque=ataque, crush=crush, vol=vol)


def cascabel(f, dur, caida, vol=0.62, crush=0, sub=0.16, det=7.0):
    """Un cascabel entero: dos cascarones a `det` Hz de distancia —que es lo que
    produce el batido, o sea lo que el oído llama "sonoro"—, un apoyo una octava
    por debajo y el badajo. Las cuatro capas comparten envolvente."""
    return dict(vol=vol, mezcla=[
        dict(onda="seno", f0=f, f1=f - 4, armonicos=ARM,
             dur=dur, caida=caida, ataque=0.012, crush=crush, vol=0.40),
        dict(onda="seno", f0=f + det, f1=f + det - 4, armonicos=ARM,
             dur=dur, caida=caida, ataque=0.012, crush=crush, vol=0.34),
        dict(onda="seno", f0=f * 0.5, f1=f * 0.5 - 2,
             dur=dur, caida=caida, ataque=0.012, crush=crush, vol=sub),
        dict(onda="ruido", dur=0.014, caida=150, filtro=3500, vol=0.10),
    ])

# ---------------------------------------------------------------- prototipos

PRUEBAS = {

# ============================================================================
# FAMILIA METAL — los inarmónicos. `CAZA.md` §9.10.
# ============================================================================

# EL CASCABEL. El juego se llama así y no sonaba nunca. Parciales apretados y
# agudos (1 : 1,37 : 1,84 : 2,43), que es lo que separa un cascabel de una
# campana de iglesia: la campana grande tiene los parciales abiertos y graves.
# El badajo va como capa aparte y dura 30 ms: sin él es un tono bonito, con él
# es un objeto que alguien ha movido.
"cascabel": dict(vol=0.85, mezcla=[
    dict(onda="triangulo", f0=1180, f1=1148,
         armonicos=[(1.37, 0.50), (1.84, 0.36), (2.43, 0.22)],
         dur=0.55, caida=6.0, ataque=0.002, filtro=9000, vol=0.42),
    dict(onda="ruido", dur=0.03, caida=90, filtro=7000, crush=5, vol=0.30),
]),

# LA CAMPANA ARCANA: el único sonido bonito del juego, con cuentagotas.
# `prompts_musica.md` fija que el violeta arcano es el único color mágico y que
# en sonido es UN solo timbre. Este es el candidato.
#
# Parciales de campana de verdad (1 : 1,19 : 1,51 : 2,02 : 2,67), el hum una
# octava por debajo entrando 30 ms tarde, y un tercer golpe a los 250 ms que hace
# de coro lejano. Y todo LIGERAMENTE DESAFINADO —622 cayendo a 616— porque el
# reloj de esta máquina no va fino, que es la regla 3 de la banda sonora.
"campana_arcana": dict(vol=0.80, mezcla=[
    dict(onda="triangulo", f0=622, f1=616,
         armonicos=[(1.19, 0.45), (1.51, 0.30), (2.02, 0.20), (2.67, 0.12)],
         dur=1.60, caida=2.4, ataque=0.020, filtro=7000, vol=0.40),
    dict(retardo=0.03, onda="triangulo", f0=311, f1=307, dur=1.80, caida=2.0,
         filtro=1400, vol=0.34),
    dict(retardo=0.25, onda="triangulo", f0=930, f1=919,
         armonicos=[(1.51, 0.30)], dur=1.10, caida=3.2, ataque=0.030,
         filtro=8000, vol=0.16),
]),

# LA PUERTA DE HIERRO QUE SE ABRE, para emparejar con la `c` que eligió Fátima
# por si al final el material gana a la estructura. Mismo esqueleto que
# `puerta_abre` —cerrojo agudo, y 180 ms después el cuerpo grave— pero con el
# hierro quejándose encima en 1 : 1,82 : 3,01 : 4,60.
"puerta_abre_hierro": dict(vol=0.80, mezcla=[
    dict(onda="ruido", dur=0.22, caida=9.0, filtro=4800, crush=5, vol=0.42),
    dict(retardo=0.18, onda="triangulo", f0=196, f1=188,
         armonicos=[(1.82, 0.38), (3.01, 0.20), (4.60, 0.10)],
         dur=0.70, caida=4.5, filtro=5200, vol=0.34),
    dict(retardo=0.18, onda="sierra", f0=84, f1=58, dur=0.60, caida=4.5,
         ruido=0.30, vibrato=(11.0, 1.1), filtro=700, crush=4, vol=0.50),
]),

# RESCATAR UNA PIEZA. `PROPÓSITO.md` §2: los desbloqueos son "piezas rescatadas
# de la memoria antes de que el reinicio las borre", y eso no es un premio de
# mesa, es otra cosa. Dos golpes de metal SUBIENDO —740 y 1109, una quinta— con
# el segundo el doble de largo: el gesto acaba arriba y se queda, igual que el
# arpegio del multiplicador, pero de metal en vez de de plástico.
"reliquia": dict(vol=1.25, mezcla=[
    dict(onda="triangulo", f0=740, f1=734,
         armonicos=[(1.83, 0.34), (2.98, 0.18)],
         dur=0.30, caida=9.0, ataque=0.004, filtro=7000, vol=0.36),
    dict(retardo=0.10, onda="triangulo", f0=1109, f1=1098,
         armonicos=[(1.83, 0.30), (2.98, 0.15)],
         dur=0.55, caida=5.0, ataque=0.004, filtro=8000, vol=0.34),
]),

# LA CRIATURA ATRAPADA (`CAZA.md` §2). Chasquido, la jaula sonando encima en
# 1 : 1,79 : 2,94 : 4,40, y un peso grave debajo que es lo que hace que se lea
# como algo que se ha CERRADO y no como algo que ha tintineado.
"captura": dict(vol=0.85, mezcla=[
    dict(onda="ruido", dur=0.04, caida=80, filtro=5000, crush=5, vol=0.42),
    dict(retardo=0.02, onda="triangulo", f0=330, f1=318,
         armonicos=[(1.79, 0.40), (2.94, 0.24), (4.40, 0.12)],
         dur=0.50, caida=8.0, filtro=6000, vol=0.34),
    dict(onda="cuadrada", f0=110, f1=48, dur=0.18, caida=24,
         filtro=800, crush=4, vol=0.40),
]),

# LA PRUEBA DE ESFUERZO DE LA FAMILIA, y es la que de verdad decide si el metal
# sirve para esta mesa: **¿aguanta a velocidad de bumper?** 130 ms, que es lo que
# dura el de abajo, con los parciales metálicos encima de un cuerpo grave.
#
# Si esto suena a metal en 130 ms, el material vale para toda la mesa. Si suena a
# chasquido sucio, el metal solo vale para lo que suena poco —puertas, campanas,
# capturas— y eso es una respuesta igual de útil y hay que saberla ANTES de
# rehacer nada.
"bumper_metal": dict(vol=0.80, mezcla=[
    dict(onda="triangulo", f0=430, f1=302,
         armonicos=[(1.81, 0.40), (2.97, 0.20)],
         dur=0.13, caida=26, filtro=5000, crush=5, vol=0.45),
    dict(onda="cuadrada", f0=170, f1=70, dur=0.11, caida=32,
         filtro=900, crush=4, vol=0.42),
]),

# ===================== PUERTAS: la familia B, que es la buena ==============
# Lo que la `b` tenía y la `c` no: la SALA contestando. Lo que le falta a la `b`:
# el CERROJO. Un portazo con eco es un portazo en una cueva; lo que dice "cerrado"
# —y no solo "golpe"— es la pieza que asienta después. La `b` no tenía ninguna.

# b2 · la b + el cerrojo, y el golpe AMORTIGUADO. Una puerta no resuena, resuena
# la sala: el impacto sube su caída de 18 a 26 para que se muera antes y deje
# sonar el cuarto. El cerrojo entra a los 150 ms, encima de la cola.
"puerta_cierra_b2": dict(vol=0.80, mezcla=[
    dict(onda="cuadrada", f0=158, f1=40, dur=0.20, caida=26,
         filtro=820, crush=4, vol=0.72),
    dict(onda="ruido", dur=0.08, caida=38, filtro=1050, crush=4, vol=0.40),
    dict(retardo=0.02, onda="triangulo", f0=57, f1=50, dur=0.90, caida=3.6,
         ruido=0.04, filtro=250, vol=0.60),
    dict(retardo=0.15, onda="ruido", dur=0.05, caida=78, filtro=6200,
         crush=5, vol=0.26),
    dict(retardo=0.15, onda="cuadrada", f0=210, f1=150, dur=0.07, caida=42,
         filtro=2400, crush=5, vol=0.20),
]),

# b3 · la b2 + un ANTES corto. 90 ms de aire, no los 240 de la `a`: lo justo para
# que la losa llegue de algún sitio sin convertir el sonido en un viaje.
"puerta_cierra_b3": dict(vol=0.80, mezcla=[
    dict(onda="ruido", dur=0.10, caida=9.0, filtro=1600, crush=4, vol=0.22),
    dict(retardo=0.09, onda="cuadrada", f0=158, f1=40, dur=0.20, caida=26,
         filtro=820, crush=4, vol=0.72),
    dict(retardo=0.09, onda="ruido", dur=0.08, caida=38, filtro=1050,
         crush=4, vol=0.40),
    dict(retardo=0.11, onda="triangulo", f0=57, f1=50, dur=0.90, caida=3.6,
         ruido=0.04, filtro=250, vol=0.60),
    dict(retardo=0.24, onda="ruido", dur=0.05, caida=78, filtro=6200,
         crush=5, vol=0.26),
    dict(retardo=0.24, onda="cuadrada", f0=210, f1=150, dur=0.07, caida=42,
         filtro=2400, crush=5, vol=0.20),
]),

# b4 · la b2 con la sala MÁS HONDA y más larga (1,3 s bajo 50 Hz) y el cerrojo
# doble, como el de una cerradura de verdad: clac-clac. Es la más "cerrado con
# llave" de las tres, y la que más se nota si la caza es un sitio grande.
"puerta_cierra_b4": dict(vol=0.80, mezcla=[
    dict(onda="cuadrada", f0=150, f1=38, dur=0.18, caida=28,
         filtro=780, crush=4, vol=0.70),
    dict(onda="ruido", dur=0.07, caida=42, filtro=1000, crush=4, vol=0.38),
    dict(retardo=0.02, onda="triangulo", f0=46, f1=41, dur=1.30, caida=2.6,
         ruido=0.03, filtro=200, vol=0.62),
    dict(retardo=0.16, onda="ruido", dur=0.04, caida=90, filtro=5600,
         crush=5, vol=0.24),
    dict(retardo=0.26, onda="ruido", dur=0.05, caida=70, filtro=6800,
         crush=5, vol=0.28),
    dict(retardo=0.26, onda="cuadrada", f0=230, f1=160, dur=0.07, caida=40,
         filtro=2600, crush=5, vol=0.22),
]),

# ===================== EL CASCABEL, EN SERIO ================================
# *"Debería ser más sonoro, y escucharse más suave: es el sonido que más currado
# debería estar."* — Fátima. Lo anterior estaba hecho como un efecto de mesa y
# esto no es un efecto de mesa, es el nombre del juego.
#
# LO QUE FALLABA, y son tres cosas que van juntas:
#   1. UN SOLO CASCARÓN. Un cascabel de verdad son dos mitades que nunca están
#      afinadas igual, y ese desajuste produce BATIDOS: el tono late despacio en
#      vez de quedarse quieto. Eso es exactamente lo que el oído llama "sonoro".
#   2. TODOS LOS PARCIALES MURIENDO A LA VEZ. En un objeto real los agudos se
#      apagan primero y el grave sostiene. Con una sola envolvente suena a
#      sintetizador; con una por parcial, suena a metal.
#   3. ATAQUE DE 2 ms Y BADAJO A TODO TRAPO. Eso es un clic, y un clic es lo
#      contrario de suave. Se sube el ataque a 12 ms —el tono FLORECE— y el
#      badajo baja de 0,30 a 0,16 y se mete por debajo del tono en vez de
#      delante.





# b5 · LA MISMA b2 CON LA SALA UNA OCTAVA MÁS ARRIBA (104 Hz en vez de 57).
# Existe por una duda de ingeniería, no de gusto: la cola de la `b` vive por
# debajo de 60 Hz, y un altavoz de portátil empieza a rendirse ahí. Como es un
# triángulo y no un seno, sus armónicos (114, 171, 228 Hz) sobreviven al filtro
# de 250 y por eso se oye algo igual — pero lo que se oye NO es lo que se diseñó.
# Esta la oye cualquiera, en cualquier sitio.
"puerta_cierra_b5": dict(vol=0.80, mezcla=[
    dict(onda="cuadrada", f0=158, f1=40, dur=0.20, caida=26,
         filtro=820, crush=4, vol=0.72),
    dict(onda="ruido", dur=0.08, caida=38, filtro=1050, crush=4, vol=0.40),
    dict(retardo=0.02, onda="triangulo", f0=104, f1=92, dur=0.85, caida=3.8,
         ruido=0.04, filtro=420, vol=0.52),
    dict(retardo=0.15, onda="ruido", dur=0.05, caida=78, filtro=6200,
         crush=5, vol=0.26),
    dict(retardo=0.15, onda="cuadrada", f0=210, f1=150, dur=0.07, caida=42,
         filtro=2400, crush=5, vol=0.20),
]),


# --- EL SONIDO DE ARRANQUE. Cuatro candidatos, porque el `cascabel_4` —que era
# el 1 con la cola larga— se quedó corto en el papel: *"el 4 no tanto"*. Lo que
# le falta no es longitud, es que una ENTRADA tiene que asentar algo, y un toque
# largo solo dura más. Los cuatro respetan la regla de arriba: un solo ataque,
# una sola envolvente, ningún retardo.
# a · DOS CASCABELES A LA QUINTA, golpeados A LA VEZ. Sigue siendo UN evento
#     —mismo ataque, misma envolvente, ningún retardo— pero suena más grande.
#     Es la forma de que un sonido de marca sea ceremonioso sin añadirle un
#     segundo golpe, que es lo que rompía las versiones anteriores.
"arranque_a": dict(vol=0.55, mezcla=[
    capa(1180, 2.8, 1.6, 0.020, 0.34, ARM),
    capa(1180, 2.8, 1.6, 0.020, 0.28, ARM, det=7),
    capa(1770, 2.8, 1.6, 0.020, 0.26, ARM),
    capa(1770, 2.8, 1.6, 0.020, 0.22, ARM, det=9),
    capa(590, 2.8, 1.6, 0.020, 0.16),
    dict(onda="ruido", dur=0.014, caida=150, filtro=3500, vol=0.08),
]),

# b · SIN BADAJO Y CON ATAQUE DE 45 ms. No lo golpean: APARECE. Es lo más
#     "logotipo" de los cuatro, y la prueba de si el badajo era lo que impedía
#     que el 4 se sintiera como una entrada en vez de como un toque largo.
"arranque_b": dict(vol=0.62, mezcla=[
    capa(1180, 3.0, 1.4, 0.045, 0.40, ARM),
    capa(1180, 3.0, 1.4, 0.045, 0.34, ARM, det=7),
    capa(590, 3.0, 1.4, 0.045, 0.18),
]),

# c · EL CÁLIDO A LONGITUD DE LOGOTIPO. Si el 2 funciona en la mesa, a lo mejor
#     el papel de arranque le toca a él y no al brillante: una entrada no tiene
#     que llamar la atención, tiene que asentar.
"arranque_c": dict(vol=0.62, mezcla=[
    capa(786, 3.2, 1.3, 0.030, 0.40, ARM),
    capa(786, 3.2, 1.3, 0.030, 0.34, ARM, det=5),
    capa(393, 3.2, 1.3, 0.030, 0.18),
    dict(onda="ruido", dur=0.014, caida=150, filtro=2600, vol=0.07),
]),

# d · CON PARCIALES DE CAMPANA GRANDE en vez de los de cascabel. Mismo material
#     —inarmónico, seno, una sola envolvente— pero el objeto es otro: más hondo
#     y más ceremonioso. Es el que más se aleja del sonido de mesa, y por eso
#     puede ser el que mejor o peor funcione.
"arranque_d": dict(vol=0.62, mezcla=[
    capa(620, 3.4, 1.2, 0.035, 0.40, ARM_CAMPANA),
    capa(620, 3.4, 1.2, 0.035, 0.32, ARM_CAMPANA, det=4),
    capa(310, 3.4, 1.2, 0.035, 0.20),
]),

# Y LA CAMPANA ARCANA, REHECHA. La vieja tenía los DOS defectos que se acaban de
# arreglar: portadora de triángulo (dos peines superpuestos) y una capa entrando
# a los 250 ms (un segundo sonido). Rehecha con la regla, y desafinada a
# propósito —620 cayendo a 616— porque el reloj de esta máquina no va fino.
"campana_arcana_2": dict(vol=0.60, mezcla=[
    capa(622, 2.6, 1.6, 0.030, 0.40, ARM_CAMPANA),
    capa(622, 2.6, 1.6, 0.030, 0.32, ARM_CAMPANA, det=3),
    capa(311, 2.6, 1.6, 0.030, 0.22),
]),

# 1 · EL DE MESA, brillante. Candidato por defecto.
"cascabel_1": cascabel(1180, 1.40, 3.2),
# 2 · el de mesa, CÁLIDO: una quinta por debajo, mismo esqueleto exacto.
"cascabel_2": cascabel(786, 1.60, 2.8),
# 3 · el 1 con la cuantización de la máquina puesta. Un seno limpio es precioso
#     y no es de este juego; 6 bits ensucian lo justo.
"cascabel_3": cascabel(1180, 1.40, 3.2, crush=6),
# 4 · EL DE ARRANQUE, y es LITERALMENTE el 1 con la cola larga: mismos parciales,
#     mismo batido, mismo todo. Lo único que cambia es cuánto dura. Eso es lo que
#     hace que los dos papeles se lean como el mismo objeto y no como dos
#     sonidos parecidos, que era la otra mitad de "coherente".
"cascabel_4": cascabel(1180, 2.60, 1.7),

# ============================================================================
# LAS PUERTAS DE LA TANDA ANTERIOR. `CAZA.md` §9.9 y §9.10.
# ============================================================================

"puerta_abre": dict(vol=0.95, mezcla=[
    dict(onda="ruido", dur=0.20, caida=11, filtro=5200, crush=5, vol=0.50),
    dict(retardo=0.15, onda="sierra", f0=92, f1=54, dur=0.60, caida=4.0,
         ruido=0.32, vibrato=(15.0, 1.3), filtro=760, crush=4, vol=0.62),
    dict(retardo=0.15, onda="ruido", dur=0.50, caida=5.5, filtro=1300,
         crush=4, vol=0.26),
]),

"puerta_niega": dict(vol=0.55, mezcla=[
    dict(onda="cuadrada", f0=124, f1=58, dur=0.09, caida=45,
         filtro=700, crush=4, vol=0.70),
    dict(onda="ruido", dur=0.05, caida=70, filtro=1400, crush=4, vol=0.45),
]),

# a · con recorrido. La losa corre 240 ms ANTES del portazo.
"puerta_cierra_a": dict(vol=0.85, mezcla=[
    dict(onda="sierra", f0=72, f1=48, dur=0.26, caida=6.0, ruido=0.30,
         vibrato=(12.0, 1.0), filtro=620, crush=4, vol=0.42),
    dict(onda="ruido", dur=0.26, caida=6.0, filtro=900, crush=4, vol=0.20),
    dict(retardo=0.24, onda="cuadrada", f0=150, f1=40, dur=0.28, caida=15,
         filtro=850, crush=4, vol=0.75),
    dict(retardo=0.24, onda="ruido", dur=0.09, caida=32, filtro=1200,
         crush=4, vol=0.40),
    dict(retardo=0.40, onda="ruido", dur=0.05, caida=80, filtro=6500,
         crush=5, vol=0.28),
]),

# b · con sala. Cola grave por debajo de 60 Hz después del golpe.
"puerta_cierra_b": dict(vol=0.80, mezcla=[
    dict(onda="cuadrada", f0=160, f1=42, dur=0.24, caida=18,
         filtro=900, crush=4, vol=0.72),
    dict(onda="ruido", dur=0.09, caida=34, filtro=1150, crush=4, vol=0.42),
    dict(retardo=0.02, onda="triangulo", f0=58, f1=51, dur=0.85, caida=4.0,
         ruido=0.04, filtro=260, vol=0.58),
]),

# c · DOBLE GOLPE. **La elegida por Fátima.** Cae, rebota, y asienta el cerrojo.
"puerta_cierra_c": dict(vol=0.85, mezcla=[
    dict(onda="cuadrada", f0=168, f1=48, dur=0.16, caida=22,
         filtro=900, crush=4, vol=0.70),
    dict(onda="ruido", dur=0.06, caida=45, filtro=1200, crush=4, vol=0.38),
    dict(retardo=0.09, onda="cuadrada", f0=140, f1=44, dur=0.20, caida=20,
         filtro=800, crush=4, vol=0.52),
    dict(retardo=0.09, onda="ruido", dur=0.04, caida=60, filtro=1100,
         crush=4, vol=0.22),
    dict(retardo=0.23, onda="ruido", dur=0.05, caida=75, filtro=6000,
         crush=5, vol=0.30),
]),

# d · DE HIERRO. La que destapó la familia metal.
"puerta_cierra_d": dict(vol=0.75, mezcla=[
    dict(onda="cuadrada", f0=120, f1=50, dur=0.20, caida=20,
         filtro=800, crush=4, vol=0.55),
    dict(onda="triangulo", f0=214, f1=205, dur=0.45, caida=7.0,
         filtro=4000, vol=0.30),
    dict(onda="triangulo", f0=389, f1=376, dur=0.38, caida=9.0,
         filtro=5000, vol=0.22),
    dict(onda="triangulo", f0=641, f1=620, dur=0.30, caida=12.0,
         filtro=6000, vol=0.16),
    dict(onda="ruido", dur=0.05, caida=60, filtro=3200, crush=5, vol=0.25),
]),

# La primera versión de `puerta_cierra`, la que Fátima tumbó por sonar a bumper.
# Se guarda porque su idea de reciclaje fue buena: ver `bumper_arena`.
"puerta_cierra_v1": dict(vol=0.62, mezcla=[
    dict(onda="cuadrada", f0=155, f1=44, dur=0.30, caida=16,
         filtro=900, crush=4, vol=0.72),
    dict(onda="ruido", dur=0.10, caida=30, filtro=1100, crush=4, vol=0.45),
    dict(retardo=0.14, onda="ruido", dur=0.05, caida=80, filtro=6500,
         crush=5, vol=0.30),
]),

# EL BÚMPER SECUNDARIO, idea de Fátima: `puerta_cierra_v1` recortado de 300 a
# 140 ms, que es lo que hace falta para algo que suena cuarenta veces por bola.
# Su sitio son los tres búmperes de la ARENA: (96,264), (304,264) y (134,424).
"bumper_arena": dict(vol=0.60, mezcla=[
    dict(onda="cuadrada", f0=205, f1=72, dur=0.14, caida=24,
         filtro=1000, crush=4, vol=0.72),
    dict(onda="ruido", dur=0.05, caida=55, filtro=1350, crush=4, vol=0.35),
]),
}

# DÓNDE VIVIRÍA CADA UNO SI SE APRUEBA. No es documentación: es lo que hace que
# mover una receta a `sonidos.py` sea un copiar y pegar y no una arqueología.
DESTINO = {
    "cascabel":           "v1, superada dos veces. Ver cascabel_1..4",
    "campana_arcana":     "v1: triángulo y una capa con retardo. Superada por campana_arcana_2",
    "puerta_abre_hierro": "puerta de entrada · CAZA.md §9.5",
    "reliquia":           "pieza rescatada · PROPOSITO.md §2",
    "captura":            "criatura atrapada · CAZA.md §2",
    "bumper_metal":       "PRUEBA DE ESFUERZO: ¿el metal aguanta 130 ms?",
    "puerta_abre":        "puerta de entrada · CAZA.md §9.5",
    "puerta_niega":       "requisitos sin cumplir · CAZA.md §9.5",
    "puerta_cierra_a":    "descartada: 240 ms de antes son un viaje, no una puerta",
    "puerta_cierra_b":    "LA FAMILIA BUENA, pero sin cerrojo. Ver b2..b5",
    "puerta_cierra_c":    "elegida y desdicha al reescucharla: gana la familia b",
    "puerta_cierra_d":    "descartada como puerta, ABRIÓ la familia metal",
    "puerta_cierra_b2":   "la b + cerrojo + golpe amortiguado",
    "puerta_cierra_b3":   "la b2 + 90 ms de antes",
    "puerta_cierra_b4":   "la b2 con sala más honda y cerrojo doble",
    "puerta_cierra_b5":   "la b2 con la sala una octava arriba: se oye en cualquier altavoz",
    "cascabel_1":         "**ELEGIDO** · el de mesa, brillante",
    "cascabel_2":         "**ELEGIDO** · el de mesa, cálido",
    "cascabel_3":         "DESCARTADO: el cascabel es lo único del juego que no es barato",
    "arranque_a":         "arranque · dos cascabeles a la quinta, un solo golpe",
    "arranque_b":         "arranque · sin badajo, ataque de 45 ms: APARECE",
    "arranque_c":         "arranque · el cálido a longitud de logotipo",
    "arranque_d":         "arranque · parciales de campana grande",
    "campana_arcana_2":   "el violeta arcano, REHECHO con la regla de coherencia",
    "cascabel_4":         "arranque, flojo: un toque largo no es una entrada. Ver arranque_a..d",
    "puerta_cierra_v1":   "tumbada por Fátima: sonaba a bumper",
    "bumper_arena":       "los tres búmperes de la arena",
}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--uno")
    ap.add_argument("--listar", action="store_true")
    a = ap.parse_args()

    if a.listar:
        for n, par in PRUEBAS.items():
            x = S.sintetizar(par, semilla=semilla(n))
            print("  %-20s %5.0f ms   %s"
                  % (n, 1000.0 * len(x) / S.FS, DESTINO.get(n, "")))
        return

    os.makedirs(SALIDA, exist_ok=True)
    for n, par in PRUEBAS.items():
        if a.uno and n != a.uno:
            continue
        x = S.sintetizar(par, semilla=semilla(n))
        ruta = os.path.join(SALIDA, n + ".wav")
        S.escribir(ruta, x)
        print("  %-20s %5.0f ms  ->  %s" % (n, 1000.0 * len(x) / S.FS, ruta))


if __name__ == "__main__":
    main()
