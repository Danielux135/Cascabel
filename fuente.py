#!/usr/bin/env python3
"""
Genera la fuente pixelart del juego y los marcos de la cáscara.

    python3 fuente.py

POR QUÉ POR CÓDIGO Y NO A MANO, que es la misma razón que `sonidos.py`: una
fuente dibujada a mano en un PNG se retoca abriendo un editor y acordándose de
dónde estaba cada letra. Escrita así, cambiar el grosor de la N es cambiar una
línea de texto, y regenerar las 110 letras cuesta un segundo.

LA FUENTE
=========
Rejilla de 5x7 con celda de 6x8: 5 px de dibujo y 1 de separación a la derecha,
7 filas por encima de la línea base y 1 por debajo para las colas de g, j, p, q
e y. O sea que **la altura de la fuente es 8** y se ve nítida a 8, 16, 24, 32 y
48: cualquier tamaño que no sea múltiplo de 8 la escala en fracciones y la
destroza, y por eso `FuenteUI.tam()` redondea al múltiplo más cercano.

Las mayúsculas acentuadas llevan la tilde DENTRO de sus siete filas, comiéndose
la fila de arriba. Es lo que hacen todas las fuentes de mapa de bits pequeñas:
subirla fuera obligaría a una celda de 10 y todo el texto del juego mediría un
25 % más para que se vieran cuatro tildes.
"""

import json
import os

import numpy as np
from PIL import Image

ANCHO, ALTO = 5, 8      # celda de dibujo (sin contar la separación)
AVANCE = 6              # lo que ocupa una letra, separación incluida
LINEA_BASE = 7          # filas por encima de la base

# --------------------------------------------------------------- los glifos
#
# Cada letra son 7 u 8 filas de 5 caracteres. '#' pinta, cualquier otra cosa no.
# Las de 8 filas tienen cola por debajo de la línea base.

G = {}

G[" "] = ["     "] * 7

# --- Mayúsculas ---
G["A"] = [" ### ", "#   #", "#   #", "#####", "#   #", "#   #", "#   #"]
G["B"] = ["#### ", "#   #", "#### ", "#   #", "#   #", "#   #", "#### "]
G["C"] = [" ####", "#    ", "#    ", "#    ", "#    ", "#    ", " ####"]
G["D"] = ["#### ", "#   #", "#   #", "#   #", "#   #", "#   #", "#### "]
G["E"] = ["#####", "#    ", "#### ", "#    ", "#    ", "#    ", "#####"]
G["F"] = ["#####", "#    ", "#### ", "#    ", "#    ", "#    ", "#    "]
G["G"] = [" ####", "#    ", "#    ", "#  ##", "#   #", "#   #", " ####"]
G["H"] = ["#   #", "#   #", "#   #", "#####", "#   #", "#   #", "#   #"]
G["I"] = ["#####", "  #  ", "  #  ", "  #  ", "  #  ", "  #  ", "#####"]
G["J"] = ["    #", "    #", "    #", "    #", "    #", "#   #", " ### "]
G["K"] = ["#   #", "#  # ", "# #  ", "##   ", "# #  ", "#  # ", "#   #"]
G["L"] = ["#    ", "#    ", "#    ", "#    ", "#    ", "#    ", "#####"]
G["M"] = ["#   #", "## ##", "# # #", "#   #", "#   #", "#   #", "#   #"]
G["N"] = ["#   #", "##  #", "# # #", "#  ##", "#   #", "#   #", "#   #"]
G["O"] = [" ### ", "#   #", "#   #", "#   #", "#   #", "#   #", " ### "]
G["P"] = ["#### ", "#   #", "#   #", "#### ", "#    ", "#    ", "#    "]
G["Q"] = [" ### ", "#   #", "#   #", "#   #", "# # #", "#  # ", " ## #"]
G["R"] = ["#### ", "#   #", "#   #", "#### ", "# #  ", "#  # ", "#   #"]
G["S"] = [" ####", "#    ", "#    ", " ### ", "    #", "    #", "#### "]
G["T"] = ["#####", "  #  ", "  #  ", "  #  ", "  #  ", "  #  ", "  #  "]
G["U"] = ["#   #", "#   #", "#   #", "#   #", "#   #", "#   #", " ### "]
G["V"] = ["#   #", "#   #", "#   #", "#   #", "#   #", " # # ", "  #  "]
G["W"] = ["#   #", "#   #", "#   #", "#   #", "# # #", "## ##", "#   #"]
G["X"] = ["#   #", "#   #", " # # ", "  #  ", " # # ", "#   #", "#   #"]
G["Y"] = ["#   #", "#   #", " # # ", "  #  ", "  #  ", "  #  ", "  #  "]
G["Z"] = ["#####", "    #", "   # ", "  #  ", " #   ", "#    ", "#####"]

# --- Minúsculas ---
G["a"] = ["     ", "     ", " ### ", "    #", " ####", "#   #", " ####"]
G["b"] = ["#    ", "#    ", "#### ", "#   #", "#   #", "#   #", "#### "]
G["c"] = ["     ", "     ", " ####", "#    ", "#    ", "#    ", " ####"]
G["d"] = ["    #", "    #", " ####", "#   #", "#   #", "#   #", " ####"]
G["e"] = ["     ", "     ", " ### ", "#   #", "#####", "#    ", " ####"]
G["f"] = ["  ## ", " #   ", "#### ", " #   ", " #   ", " #   ", " #   "]
G["g"] = ["     ", "     ", " ####", "#   #", "#   #", " ####", "    #", " ### "]
G["h"] = ["#    ", "#    ", "#### ", "#   #", "#   #", "#   #", "#   #"]
G["i"] = ["  #  ", "     ", " ##  ", "  #  ", "  #  ", "  #  ", " ### "]
G["j"] = ["   # ", "     ", "  ## ", "   # ", "   # ", "   # ", "#  # ", " ##  "]
G["k"] = ["#    ", "#    ", "#  # ", "# #  ", "##   ", "# #  ", "#  # "]
G["l"] = [" ##  ", "  #  ", "  #  ", "  #  ", "  #  ", "  #  ", " ### "]
G["m"] = ["     ", "     ", "## # ", "# # #", "# # #", "# # #", "# # #"]
G["n"] = ["     ", "     ", "#### ", "#   #", "#   #", "#   #", "#   #"]
G["o"] = ["     ", "     ", " ### ", "#   #", "#   #", "#   #", " ### "]
G["p"] = ["     ", "     ", "#### ", "#   #", "#   #", "#### ", "#    ", "#    "]
G["q"] = ["     ", "     ", " ####", "#   #", "#   #", " ####", "    #", "    #"]
G["r"] = ["     ", "     ", "# ## ", "##   ", "#    ", "#    ", "#    "]
G["s"] = ["     ", "     ", " ####", "#    ", " ### ", "    #", "#### "]
G["t"] = [" #   ", " #   ", "#### ", " #   ", " #   ", " #  #", "  ## "]
G["u"] = ["     ", "     ", "#   #", "#   #", "#   #", "#   #", " ####"]
G["v"] = ["     ", "     ", "#   #", "#   #", "#   #", " # # ", "  #  "]
G["w"] = ["     ", "     ", "#   #", "#   #", "# # #", "# # #", " # # "]
G["x"] = ["     ", "     ", "#   #", " # # ", "  #  ", " # # ", "#   #"]
G["y"] = ["     ", "     ", "#   #", "#   #", "#   #", " ####", "    #", " ### "]
G["z"] = ["     ", "     ", "#####", "   # ", "  #  ", " #   ", "#####"]

# --- Números ---
G["0"] = [" ### ", "#   #", "#  ##", "# # #", "##  #", "#   #", " ### "]
G["1"] = ["  #  ", " ##  ", "  #  ", "  #  ", "  #  ", "  #  ", " ### "]
G["2"] = [" ### ", "#   #", "    #", "   # ", "  #  ", " #   ", "#####"]
G["3"] = ["#####", "   # ", "  ## ", "    #", "    #", "#   #", " ### "]
G["4"] = ["   # ", "  ## ", " # # ", "#  # ", "#####", "   # ", "   # "]
G["5"] = ["#####", "#    ", "#### ", "    #", "    #", "#   #", " ### "]
G["6"] = ["  ## ", " #   ", "#    ", "#### ", "#   #", "#   #", " ### "]
G["7"] = ["#####", "    #", "   # ", "  #  ", " #   ", " #   ", " #   "]
G["8"] = [" ### ", "#   #", "#   #", " ### ", "#   #", "#   #", " ### "]
G["9"] = [" ### ", "#   #", "#   #", " ####", "    #", "   # ", " ##  "]

# --- Puntuación y símbolos ---
G["."] = ["     ", "     ", "     ", "     ", "     ", " ##  ", " ##  "]
G[","] = ["     ", "     ", "     ", "     ", "     ", " ##  ", " ##  ", " #   "]
G[":"] = ["     ", " ##  ", " ##  ", "     ", " ##  ", " ##  ", "     "]
G[";"] = ["     ", " ##  ", " ##  ", "     ", " ##  ", " ##  ", " #   "]
G["!"] = ["  #  ", "  #  ", "  #  ", "  #  ", "  #  ", "     ", "  #  "]
G["?"] = [" ### ", "#   #", "    #", "   # ", "  #  ", "     ", "  #  "]
G["¡"] = ["  #  ", "     ", "  #  ", "  #  ", "  #  ", "  #  ", "  #  "]
G["¿"] = ["  #  ", "     ", "  #  ", " #   ", "#    ", "#   #", " ### "]
G["'"] = ["  #  ", "  #  ", "     ", "     ", "     ", "     ", "     "]
G['"'] = [" # # ", " # # ", "     ", "     ", "     ", "     ", "     "]
G["("] = ["   # ", "  #  ", " #   ", " #   ", " #   ", "  #  ", "   # "]
G[")"] = [" #   ", "  #  ", "   # ", "   # ", "   # ", "  #  ", " #   "]
G["["] = ["  ## ", "  #  ", "  #  ", "  #  ", "  #  ", "  #  ", "  ## "]
G["]"] = [" ##  ", "  #  ", "  #  ", "  #  ", "  #  ", "  #  ", " ##  "]
G["-"] = ["     ", "     ", "     ", " ### ", "     ", "     ", "     "]
G["—"] = ["     ", "     ", "     ", "#####", "     ", "     ", "     "]
G["+"] = ["     ", "  #  ", "  #  ", "#####", "  #  ", "  #  ", "     "]
G["="] = ["     ", "     ", "#####", "     ", "#####", "     ", "     "]
G["/"] = ["    #", "    #", "   # ", "  #  ", " #   ", "#    ", "#    "]
G["\\"] = ["#    ", "#    ", " #   ", "  #  ", "   # ", "    #", "    #"]
G["%"] = ["##  #", "##  #", "   # ", "  #  ", " #   ", "#  ##", "#  ##"]
G["·"] = ["     ", "     ", "     ", " ##  ", " ##  ", "     ", "     "]
G["×"] = ["     ", "     ", "#   #", " # # ", "  #  ", " # # ", "#   #"]
G["*"] = ["     ", "# # #", " ### ", "#####", " ### ", "# # #", "     "]
G["_"] = ["     ", "     ", "     ", "     ", "     ", "     ", "#####"]
G["<"] = ["   # ", "  #  ", " #   ", "#    ", " #   ", "  #  ", "   # "]
G[">"] = [" #   ", "  #  ", "   # ", "    #", "   # ", "  #  ", " #   "]
G["|"] = ["  #  ", "  #  ", "  #  ", "  #  ", "  #  ", "  #  ", "  #  "]
G["#"] = [" # # ", " # # ", "#####", " # # ", "#####", " # # ", " # # "]

# --------------------------------------------------------------- acentuadas
#
# Las minúsculas tienen libres las dos filas de arriba, así que la tilde entra
# tal cual. Las MAYÚSCULAS no: la tilde se come su primera fila, que es lo que
# hacen todas las fuentes de mapa de bits pequeñas. Se ve algo apretado y es la
# única alternativa a subir la celda a 10 px y hacer TODO el texto más grande
# para que se vean cuatro tildes.

# Las minúsculas tienen libres las dos filas de arriba, así que la tilde entra
# tal cual encima. Las MAYÚSCULAS no: hay que comprimir el cuerpo a seis filas y
# dejar la de arriba para la tilde. Se escriben a mano en vez de recortar la
# normal por código, porque recortar una fila cualquiera rompe la letra: a la A
# hay que quitarle la punta y a la E, una de las tres barras.

for base, acentuada in [("a", "á"), ("e", "é"), ("i", "í"), ("o", "ó"), ("u", "ú")]:
    g = list(G[base])
    g[0] = "  #  "
    g[1] = " #   "
    G[acentuada] = g

G["ü"] = list(G["u"])
G["ü"][0] = " # # "
# LA TILDE NECESITA UNA FILA EN BLANCO DEBAJO. Estaba dibujada pegada a la
# barra alta de la "n" —tilde en la fila 1, "n" desde la 2— y las dos se
# fundían en un techo grueso: la ñ salía leyéndose como una n. Se ve a 8 px
# dentro del juego, no en el atlas. La fila 0 estaba libre.
G["ñ"] = [" ### ", "     ", "#### ", "#   #", "#   #", "#   #", "#   #"]

# LA MISMA REGLA QUE LA ñ: fila 1 EN BLANCO y el cuerpo comprimido a cinco.
# Antes la tilde iba pegada a la primera fila de la letra y en las que tienen
# la fila de arriba llena —la I y la E— desaparecía del todo: "CRÍTICO" salía
# leyéndose "CRITICO" con la barra un poco más gorda. En la A, la O y la U se
# distinguía a duras penas. Comprimir el cuerpo cuesta una fila de dibujo y es
# lo que hace que la tilde exista a 8 px, que es donde se lee.
G["Á"] = ["  ## ", "     ", " ### ", "#   #", "#####", "#   #", "#   #"]
G["É"] = ["  ## ", "     ", "#####", "#    ", "#### ", "#    ", "#####"]
G["Í"] = ["  ## ", "     ", "#####", "  #  ", "  #  ", "  #  ", "#####"]
G["Ó"] = ["  ## ", "     ", " ### ", "#   #", "#   #", "#   #", " ### "]
G["Ú"] = ["  ## ", "     ", "#   #", "#   #", "#   #", "#   #", " ### "]
G["Ü"] = [" # # ", "     ", "#   #", "#   #", "#   #", "#   #", " ### "]
# Lo mismo arriba, y aquí no había fila libre: la "N" ocupa las siete. Se
# comprime a cinco quedándose con la diagonal entera —que es lo que hace
# que una N sea una N— y se gana el hueco bajo la tilde.
G["Ñ"] = [" ### ", "     ", "#   #", "##  #", "# # #", "#  ##", "#   #"]

G["°"] = [" ##  ", "#  # ", " ##  ", "     ", "     ", "     ", "     "]


def construir():
    letras = sorted(G.keys())
    columnas = 16
    filas = (len(letras) + columnas - 1) // columnas
    img = Image.new("RGBA", (columnas * AVANCE, filas * ALTO), (0, 0, 0, 0))
    px = img.load()
    metricas = {"alto": ALTO, "avance": AVANCE, "linea_base": LINEA_BASE,
                "ancho": ANCHO, "glifos": {}}

    for i, letra in enumerate(letras):
        cx = (i % columnas) * AVANCE
        cy = (i // columnas) * ALTO
        for fila, patron in enumerate(G[letra]):
            if fila >= ALTO:
                break
            for col, c in enumerate(patron[:ANCHO]):
                if c == "#":
                    px[cx + col, cy + fila] = (255, 255, 255, 255)
        metricas["glifos"][letra] = [cx, cy]

    os.makedirs("assets/ui", exist_ok=True)
    img.save("assets/ui/fuente_cascabel.png")
    with open("assets/ui/fuente_cascabel.json", "w", encoding="utf-8") as f:
        json.dump(metricas, f, ensure_ascii=False, indent=1)
    print(f"  fuente: {len(letras)} glifos, celda {AVANCE}x{ALTO}, "
          f"hoja {img.width}x{img.height}")
    return len(letras)


# =========================================================== los marcos
#
# LOS MARCOS DE LA CÁSCARA, y por qué se generan aquí en vez de dibujarse.
#
# El primer intento reusó para la ventana un marco de piedra pensado para la
# mazmorra, y se veían dos cosas mal a la vez: **no cuadraba** —lo había
# recortado `procesar.py` por silueta, así que cada pieza salía con el tamaño
# de su dibujo y el borde izquierdo no medía lo mismo que el derecho— y **no
# parecía un sistema operativo**, porque era piedra tallada alrededor de una
# ventana.
#
# Generados así, las nueve piezas SALEN CUADRADAS POR CONSTRUCCIÓN: todas miden
# la unidad, y la simetría izquierda/derecha es la misma línea de código
# reflejada. El descuadre de píxeles deja de ser posible.

HEX = {
    "negro": "14121A", "gris1": "2A2A33", "gris2": "43434F", "gris3": "62636F",
    "gris4": "8C8D99", "gris5": "B9BAC4", "blanco": "E4E6EC",
    "azul": "274A63", "azul_luz": "4478A0",
    "pergamino": "F5E9CE", "oro": "E0A63C", "oro_oscuro": "8A6524",
}


def c(nombre, alfa=255):
    h = HEX[nombre]
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alfa)


def _marco(carpeta, perfil, relleno, unidad=8):
    """Escribe los nueve trozos de un marco.

    `perfil` es la lista de colores desde el BORDE HACIA DENTRO, uno por píxel,
    y tiene que medir `unidad`. El mismo perfil se usa en los cuatro lados
    reflejándolo, que es lo que garantiza que izquierda y derecha midan y se
    vean exactamente igual.
    """
    assert len(perfil) == unidad, f"{carpeta}: perfil de {len(perfil)}, unidad {unidad}"
    u = unidad

    def lienzo():
        return np.zeros((u, u, 4), dtype=np.uint8)

    # Bordes: una tira de `unidad` de grosor, uniforme a lo largo. Uniforme es
    # obligatorio: es lo que se repite, y cualquier detalle se convertiría en un
    # patrón que canta cada 8 px.
    sup = lienzo()
    for i, col in enumerate(perfil):
        sup[i, :, :] = col
    inf = sup[::-1, :, :].copy()
    izq = lienzo()
    for i, col in enumerate(perfil):
        izq[:, i, :] = col
    der = izq[:, ::-1, :].copy()

    # Esquinas: el perfil por los dos ejes a la vez. Gana el más exterior, que
    # es lo que hace que la línea de fuera dé la vuelta entera sin cortarse.
    si = lienzo()
    for y in range(u):
        for x in range(u):
            si[y, x, :] = perfil[min(x, y)]
    sd = si[:, ::-1, :].copy()
    ii = si[::-1, :, :].copy()
    id_ = si[::-1, ::-1, :].copy()

    rel = lienzo()
    rel[:, :, :] = relleno

    os.makedirs(carpeta, exist_ok=True)
    for nombre, datos in [("esq_si", si), ("esq_sd", sd), ("esq_ii", ii),
                          ("esq_id", id_), ("borde_sup", sup), ("borde_inf", inf),
                          ("borde_izq", izq), ("borde_der", der),
                          ("relleno", rel)]:
        Image.fromarray(datos, "RGBA").save(f"{carpeta}/{nombre}.png")


def marcos():
    # LA VENTANA. Biselado de sistema operativo viejo: línea oscura fuera,
    # brillo, cara, sombra, y línea oscura dentro para separarla del contenido.
    _marco("assets/ui/ventana",
           [c("negro"), c("gris5"), c("gris4"), c("gris4"),
            c("gris4"), c("gris3"), c("gris2"), c("negro")],
           c("gris2"))

    # LA BARRA DE TÍTULO, en azul. Es lo que de verdad dice "esto es una
    # ventana": sin barra de título, un rectángulo enmarcado es una caja.
    _marco("assets/ui/titulo",
           [c("negro"), c("azul_luz"), c("azul_luz"), c("azul"),
            c("azul"), c("azul"), c("azul"), c("azul")],
           c("azul"))

    # LA BARRA DE TAREAS. Como la ventana pero sin la línea oscura de dentro:
    # abajo del todo no hay contenido del que separarse.
    _marco("assets/ui/barra",
           [c("negro"), c("gris5"), c("gris4"), c("gris4"),
            c("gris4"), c("gris4"), c("gris3"), c("gris3")],
           c("gris4"))

    # EL BOTÓN, con el bisel al revés en la parte de abajo para que se lea
    # levantado. Unidad 4: un botón de 8 px de marco por lado no cabe en la
    # barra de tareas.
    _marco("assets/ui/boton",
           [c("negro"), c("gris5"), c("gris4"), c("gris3")],
           c("gris4"), unidad=4)

    # EL TOOLTIP AMARILLO, que es el color de la broma. Unidad 4 y perfil casi
    # plano: un tooltip biselado se lee como un botón.
    _marco("assets/ui/tooltip",
           [c("negro"), c("pergamino"), c("pergamino"), c("pergamino")],
           c("pergamino"), unidad=4)

    # EL CUADRO DE DIÁLOGO. Gris CLARO, porque encima se escribe en oscuro, y
    # con la línea blanca por fuera para que se lea levantado sobre la mesa: es
    # lo que INTERRUMPE el juego y tiene que parecer que se ha puesto delante.
    #
    # Estaba recortado a mano de una hoja de IA y era el único marco de la
    # cáscara que no salía de aquí. Se veía: su `relleno` no era un tono plano
    # sino una baldosa con borde propio, así que al repetirse dibujaba una
    # REJILLA de ladrillos por todo el cuadro. Solo aparece cuando el enemigo
    # ataca, que es el peor momento para tener la pantalla llena de ruido.
    _marco("assets/ui/dialogo",
           [c("negro"), c("blanco"), c("gris5"), c("gris5"),
            c("gris5"), c("gris4"), c("gris3"), c("gris2")],
           c("gris5"))

    print("  marcos: ventana, titulo, barra, boton, tooltip, dialogo")


if __name__ == "__main__":
    construir()
    marcos()
