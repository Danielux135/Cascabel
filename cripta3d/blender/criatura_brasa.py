# criatura_brasa.py — BRASA, la llama de Cascabel, modelada entera por guion.
#
#   python cripta3d/herramientas/blender3d.py cripta3d/blender/criatura_brasa.py -- cripta3d/modelos/criatura_brasa.glb
#          [--vistas C:/carpeta/temporal]    además deja unos renders rápidos para mirar la forma
#
# QUÉ SALE. Un GLB con las piezas del cuerpo como objetos SEPARADOS y con nombre,
# que `cripta3d/criaturas/brasa.gd` busca por ese nombre y mueve por código:
#
#   entera/  llama, nucleo, carbon, ojo_izq, ojo_der   la BRASA entera (especie «saltarin»)
#   ascua/   llama_ascua, nucleo_ascua, carbon_ascua,
#            ojo_ascua_izq, ojo_ascua_der              cada ASCUA, su mitad (especie «gotita»)
#   pavesa                                             el rombo de las pavesas
#
# Las dos van LADO A LADO, cada una colgada de su vacío, y con un material de
# muestra, para que el GLB se pueda mirar solo (el visor con --glb=). El aspecto
# de verdad se lo ponen los shaders de `cripta3d/criaturas/brasa_*.gdshader`: lo
# que se ve aquí es la FORMA.
#
# CÓMO ESTÁ HECHO. Nada de primitivas pegadas: cada pieza es un CAMPO DE DISTANCIAS
# (una fórmula que dice a qué distancia de la superficie está cada punto) que se
# pasa a malla y se simplifica. Así las lenguas se FUNDEN con el cuerpo en vez de
# clavarse en él, y el carbón se parte en trozos con sus surcos de verdad.
#
#   · La LLAMA (la melena) es una hoguera ancha y baja: un cuerpo alto de hombros
#     con una corona de siete lenguas cortas, de alto parecido, abiertas en
#     abanico (ver `forma_entera`). Es lo que dibuja el sprite. Los hombros nacen
#     A LOS LADOS de la cara, no delante: desde la cámara de juego, que mira desde
#     arriba, una lengua delante de la cara es una lengua encima de un ojo.
#   · El NÚCLEO es la llama de dentro, la clara: es la CARA. La melena lleva una
#     ventana (se abre en el shader) por la que se le ve, y los ojos van sobre él.
#     El frente del núcleo va REBANADO en una careta casi plana, para que los
#     ojos caigan derechos (ver `sd_llama`).
#   · El CARBÓN es la brasa de la que nace: un tizón partido en trozos, con un
#     cráter arriba donde se asienta la llama y el ascua asomando por los surcos.
#   · La ASCUA es la mitad: la misma llama en pequeño (`a_ascua`) sobre medio
#     carbón, con la cara del corte al rojo.
#
# EL COLOR DE VÉRTICE lleva la convención de la cripta (R oclusión, G canto, B libre):
#   llama / nucleo   R = oclusión (lo que queda entre lenguas)
#                    G = cuánto de LENGUA es ese punto: 0 en el cuerpo, 1 en la punta.
#                        Es el «canto» de una llama: lo fino, lo que se deshace.
#                    B = una fase distinta por lengua, para que no bailen a la vez
#   carbon           R = oclusión, G = canto (ceniza y brillo de grafito),
#                    B = ASCUA: 1 en el fondo de los surcos y en el cráter
#   ojos             sin color: llevan UV (la cuenca se dibuja en el shader)
#
# Las coordenadas del guion son las de Godot (x derecha, y arriba, z hacia el
# jugador) y se giran al crear cada malla: Blender tiene la z arriba.
import math
import os
import sys

import bmesh
import bpy
import numpy as np
import openvdb as vdb
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SALIDA = ARGV[0] if ARGV and not ARGV[0].startswith("--") else "cripta3d/modelos/criatura_brasa.glb"
VISTAS = ""
for _i, _a in enumerate(ARGV):
    if _a == "--vistas" and _i + 1 < len(ARGV):
        VISTAS = ARGV[_i + 1]

RNG = np.random.default_rng(7)


# ---------------------------------------------------------------- campos de distancia

def smin(a, b, k):
    """Unión blanda: lo que hace que dos formas se fundan en vez de cortarse."""
    h = np.maximum(k - np.abs(a - b), 0.0) / k
    return np.minimum(a, b) - h * h * k * 0.25


def smax(a, b, k):
    return -smin(-a, -b, k)


def paso_suave(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def sd_elipsoide(P, c, r):
    c = np.asarray(c, dtype=np.float64)
    r = np.asarray(r, dtype=np.float64)
    q = (P - c) / r
    k0 = np.sqrt((q * q).sum(1))
    q2 = q / r
    k1 = np.sqrt((q2 * q2).sum(1))
    return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)


def sd_esfera(P, c, r):
    d = P - np.asarray(c, dtype=np.float64)
    return np.sqrt((d * d).sum(1)) - r


def bezier(p0, p1, p2, p3, n):
    t = np.linspace(0.0, 1.0, n + 1)[:, None]
    p0, p1, p2, p3 = (np.asarray(p, dtype=np.float64) for p in (p0, p1, p2, p3))
    return ((1 - t) ** 3) * p0 + 3 * ((1 - t) ** 2) * t * p1 + 3 * (1 - t) * (t ** 2) * p2 + (t ** 3) * p3


def lengua_libre(puntos, r0, exp=1.55, k=0.032, punta=0.0035, panza=0.95, tramos=12):
    """Una lengua por sus cuatro puntos de control."""
    return {"puntos": bezier(puntos[0], puntos[1], puntos[2], puntos[3], tramos),
            "r0": r0, "exp": exp, "k": k, "punta": punta, "panza": panza}


def lengua(grados, rb, yb, rt, yt, r0, comba=0.025, rizo=0.012, exp=1.55, k=0.032, punta=0.0035,
           panza=0.95):
    """Una lengua de la corona, dicha como la diría quien la dibuja: en qué lado
    nace (`grados`, 0 = de cara al jugador), a qué distancia del eje y a qué altura
    (`rb`, `yb`), dónde acaba la punta (`rt`, `yt`) y lo gorda que es (`r0`).
    `comba` la abomba hacia fuera a media altura y `rizo` la retuerce de lado: una
    lengua recta es un cono, y un cono no es una llama."""
    a = math.radians(grados)
    fuera = np.array([math.sin(a), 0.0, math.cos(a)])
    lado = np.array([math.cos(a), 0.0, -math.sin(a)])
    arriba = np.array([0.0, 1.0, 0.0])
    alto = yt - yb
    p0 = fuera * rb + arriba * yb
    p3 = fuera * rt + arriba * yt
    p1 = fuera * (rb + (rt - rb) * 0.40 + comba) + arriba * (yb + alto * 0.36) + lado * rizo
    p2 = fuera * (rt + comba * 0.55) + arriba * (yb + alto * 0.74) - lado * rizo * 0.9
    return lengua_libre([p0, p1, p2, p3], r0, exp, k, punta, panza)


def radio_lengua(L, u):
    """El grosor a lo largo de la lengua. No es un cono: aguanta gorda hasta media
    altura y luego se afila, como una hoja. Es lo que la hace llama y no cuerno."""
    return L["r0"] * (1.0 - u) ** L["exp"] * (1.0 + L["panza"] * u) + L["punta"]


def sd_lengua(P, L, recortar=True):
    """Distancia a una lengua y en qué punto de su largo cae (0 base, 1 punta)."""
    pts = L["puntos"]
    n = len(pts) - 1
    d = np.full(len(P), 1.0)
    u = np.zeros(len(P))
    idx = None
    Q = P
    if recortar:
        margen = L["r0"] + L["k"] + 0.02
        lo = pts.min(0) - margen
        hi = pts.max(0) + margen
        dentro = np.all((P > lo) & (P < hi), axis=1)
        idx = np.nonzero(dentro)[0]
        if len(idx) == 0:
            return d, u
        Q = P[idx]
    dq = np.full(len(Q), 1.0)
    uq = np.zeros(len(Q))
    for i in range(n):
        a, b = pts[i], pts[i + 1]
        ua, ub = i / n, (i + 1) / n
        ra, rb = radio_lengua(L, ua), radio_lengua(L, ub)
        ab = b - a
        t = np.clip(((Q - a) @ ab) / float(ab @ ab), 0.0, 1.0)
        c = a + t[:, None] * ab
        e = Q - c
        di = np.sqrt((e * e).sum(1)) - (ra + (rb - ra) * t)
        mejor = di < dq
        dq = np.where(mejor, di, dq)
        uq = np.where(mejor, ua + (ub - ua) * t, uq)
    if idx is None:
        return dq, uq
    d[idx] = dq
    u[idx] = uq
    return d, u


def sd_cuerpo_llama(P, F):
    """La gota: una cebolla achatada con un cuello estrecho por abajo, que es por
    donde sale del cráter del carbón. Estrecha en el pábilo, panzuda encima."""
    d = sd_elipsoide(P, F["c"], F["r"])
    return smin(d, sd_elipsoide(P, F["cuello_c"], F["cuello_r"]), 0.022)


def sd_llama(P, F, recortar=True):
    """La melena o el núcleo: la gota con sus lenguas fundidas."""
    d = sd_cuerpo_llama(P, F)
    for L in F["lenguas"]:
        dl, _u = sd_lengua(P, L, recortar)
        d = smin(d, dl, L["k"])
    if "cara_c" in F:
        # La CARA del núcleo: se le rebana el frente con una esfera muy grande, y
        # queda una careta casi plana, echada hacia atrás. Sobre una bola, unos
        # ojos de este tamaño se envolvían por los lados y se abrían en abanico;
        # sobre la careta caen derechos. Por encima de `cara_y` el corte se va
        # soltando, para no llevarse la lengua de dentro.
        corte = sd_esfera(P, F["cara_c"], F["cara_r"]) - 3.0 * np.maximum(P[:, 1] - F["cara_y"], 0.0)
        d = smax(d, corte, 0.014)
    # Por abajo se corta en plano: ahí se mete en el cráter del carbón.
    return smax(d, F["suelo"] - P[:, 1], 0.008)


def datos_llama(P, F):
    """Para cada vértice: cuánto de lengua es (G) y la fase de su lengua (B)."""
    cuerpo = sd_cuerpo_llama(P, F)
    g = np.zeros(len(P))
    b = np.full(len(P), 0.5)
    mejor = np.full(len(P), 1.0)
    for i, L in enumerate(F["lenguas"]):
        dl, ul = sd_lengua(P, L, False)
        # Solo cuenta como lengua lo que sobresale del cuerpo: en la raíz, donde las
        # dos formas se funden, el punto es mitad y mitad.
        manda = np.clip((cuerpo - dl) / 0.024 + 0.35, 0.0, 1.0)
        es = dl < mejor
        mejor = np.where(es, dl, mejor)
        g = np.where(es, ul * manda, g)
        b = np.where(es, L["fase"], b)
    return np.clip(g, 0.0, 1.0), b


def ondas(P, s):
    """Un campo de vectores suave y barato, para que nada sea un elipsoide limpio."""
    x, y, z = P[:, 0], P[:, 1], P[:, 2]
    return 0.5 * np.stack([
        np.sin(y * 31.0 + s) + np.sin(z * 23.0 + 1.3 * s),
        np.sin(z * 29.0 + 2.1 * s) + np.sin(x * 27.0 + 0.7 * s),
        np.sin(x * 33.0 + 1.9 * s) + np.sin(y * 25.0 + 2.9 * s)], axis=1)


def _celdas(Q, S):
    """Voronoi: para cada punto, su semilla más cercana y lo lejos que está de la
    frontera con la siguiente. Semilla a semilla, que la matriz entera no cabe."""
    d1 = np.full(len(Q), 1e9)
    d2 = np.full(len(Q), 1e9)
    i1 = np.zeros(len(Q), dtype=np.int64)
    i2 = np.zeros(len(Q), dtype=np.int64)
    for k in range(len(S)):
        e = Q - S[k]
        dk = np.sqrt((e * e).sum(1))
        primero = dk < d1
        segundo = (~primero) & (dk < d2)
        d2 = np.where(primero, d1, np.where(segundo, dk, d2))
        i2 = np.where(primero, i1, np.where(segundo, k, i2))
        d1 = np.where(primero, dk, d1)
        i1 = np.where(primero, k, i1)
    entre = S[i1] - S[i2]
    sep = np.maximum(np.sqrt((entre * entre).sum(1)), 1e-6)
    borde = (d2 * d2 - d1 * d1) / (2.0 * sep)
    return i1, borde


def sd_carbon(P, F, surcos=True):
    """El tizón: un bulto partido en trozos de Voronoi. El carbón no se rompe en
    almohadillas, se rompe en CARAS: a cada trozo se le corta la piel con un plano
    inclinado (su faceta), queda a su altura (`desnivel`), y entre trozo y trozo
    hay un surco estrecho y hondo. Arriba, un cráter: ahí se asienta la llama."""
    Q = P + F["bulto"] * ondas(P, F["semilla"])
    d = sd_elipsoide(Q, F["c"], F["r"])
    celda, borde = _celdas(Q, F["semillas"])
    d = d - F["desnivel"][celda]
    faceta = ((Q - F["semillas"][celda]) * F["normales"][celda]).sum(1) + F["rebaje"][celda]
    d = smax(d, faceta, 0.004)
    if surcos:
        surco = 1.0 - paso_suave(0.0, F["ancho"], borde)
        d = d + F["hondo"] * surco
        d = smax(d, -sd_esfera(P, F["crater_c"], F["crater_r"]), 0.008)
        if "corte_n" in F:
            # La cara por la que se partió: plana y al rojo.
            n = F["corte_n"]
            d = smax(d, P @ n - F["corte_d"], 0.005)
    return np.maximum(d, -P[:, 1])


def trozos_carbon(c, r, cuantas, baile=0.014, giro=0.42, rebaje=(0.0005, 0.0065)):
    """Las semillas de los trozos, repartidas por la piel del bulto (espiral de
    Fibonacci, movida), con la normal de la faceta de cada uno —la de la piel,
    torcida al azar— y cuánto se le rebaja."""
    c = np.asarray(c, dtype=np.float64)
    r = np.asarray(r, dtype=np.float64)
    pts = []
    for i in range(cuantas):
        y = 1.0 - 2.0 * (i + 0.5) / cuantas
        rad = math.sqrt(max(1.0 - y * y, 0.0))
        a = i * math.pi * (3.0 - math.sqrt(5.0))
        pts.append([math.cos(a) * rad, y, math.sin(a) * rad])
    esfera = np.array(pts)
    semillas = esfera * r * 0.98 + c
    semillas += RNG.uniform(-baile, baile, semillas.shape)
    normales = esfera / r
    normales /= np.linalg.norm(normales, axis=1)[:, None]
    normales += RNG.uniform(-giro, giro, normales.shape)
    normales /= np.linalg.norm(normales, axis=1)[:, None]
    return semillas, normales, RNG.uniform(rebaje[0], rebaje[1], cuantas)


# ------------------------------------------------------------------------- las formas

# Las alturas que se repiten entre piezas, juntas, porque tienen que cuadrar: el
# fondo del cráter del carbón es donde nace la llama, y `brasa.gd` aplasta y apaga
# la llama alrededor de ese mismo punto (su constante PIVOTE).
PIVOTE_ENTERA = 0.050
PIVOTE_ASCUA = 0.034
# Lo que mide una pavesa de las grandes, de lado a lado (en el sprite, 3 px).
TAM_PAVESA = 0.022
# Cuánto se aparta la ascua de la entera dentro del GLB, para verlas a la par.
APARTE_ASCUA = 0.40


# LA SILUETA ES LA DEL SPRITE: una hoguera ANCHA y BAJA, casi simétrica. Una
# corona de siete lenguas cortas y de alto parecido que se abren en abanico, y la
# cara grande abajo, casi tocando el carbón (en el sprite los ojos están en el
# tercio de abajo). Ancho:alto, con el carbón, 1,3:1.
#   Hubo antes una llama ALTA (0,9:1), con una púa central dominante y pétalos
# sueltos a los lados: de cerca se leía como una lechuga o un Calcifer, no como
# la llama del juego. Por eso: la central, como mucho un 20 % más alta que las
# otras; y ninguna lengua delante de la cara —la cámara de juego mira desde
# arriba, y una lengua delante de la cara es una lengua encima de un ojo—.
ALTO_LLAMA = 0.370
# Dónde van los ojos (el centro, en la cara del núcleo). Tamaño y separación son
# los de antes: es lo que mejor se leía de toda la criatura, también a 100 px.
OJO_X, OJO_Y, OJO_ANCHO, OJO_ALTO = 0.0420, 0.112, 0.0270, 0.0310


def forma_entera():
    # FUEGO, NO TULIPÁN (crítica de arte, nov-2026). La corona era de siete lenguas
    # de alto casi igual (0,246 a 0,300), gordas hasta arriba y simétricas lado a
    # lado: una COPA lisa con pétalos redondos, que de cerca se leía como un
    # tulipán de cerámica o una pantalla de lámpara. Ahora:
    #   · una lengua MANDA (la central, 0,37) y las demás van a alturas muy
    #     distintas, sin pareja: la de un lado alta, la del otro corta;
    #   · las puntas, afiladas (`exp` más alto y `punta` más fina): una llama
    #     acaba en hilo, no en yema de dedo;
    #   · dos lenguas BAJAS a los lados, casi a ras del carbón, como los
    #     chisporroteos de los lados del sprite: rompen el borde de la copa;
    #   · y lo roto y lo que se mueve lo pone el shader (`brasa_llama`), que come
    #     la parte alta con un ruido que sube.
    # Sigue sin haber ninguna lengua DELANTE de la cara (desde arriba taparía un ojo).
    # (La primera vuelta de esto llevaba las lenguas con panza, `panza` 0,95, y
    # abiertas hacia fuera: salió un cardo, una bola con púas. Una lengua de fuego
    # se afila POCO A POCO desde la raíz y sube casi derecha.)
    L = [
        # La central, la que manda: alta, con una S, un poco hacia atrás.
        lengua_libre([(0.000, 0.150, -0.030), (0.034, 0.222, -0.042),
                      (-0.026, 0.300, -0.050), (0.022, ALTO_LLAMA, -0.040)],
                     r0=0.060, exp=1.25, k=0.050, punta=0.0020, panza=0.30),
        # Los hombros: nacen A LOS LADOS de la cara y la enmarcan. Uno alto y
        # cerrado, el otro corto y abierto.
        lengua(66, rb=0.090, yb=0.150, rt=0.104, yt=0.312, r0=0.052, comba=0.022, rizo=0.034, k=0.046,
               exp=1.25, punta=0.0020, panza=0.30),
        lengua(-72, rb=0.092, yb=0.146, rt=0.136, yt=0.246, r0=0.048, comba=0.026, rizo=0.018, k=0.044,
               exp=1.3, punta=0.0020, panza=0.30),
        # Las de fuera: algo abiertas, son las que hacen la hoguera ancha.
        lengua(102, rb=0.110, yb=0.120, rt=0.156, yt=0.226, r0=0.046, comba=0.024, rizo=0.026, k=0.042,
               exp=1.3, punta=0.0020, panza=0.30),
        lengua(-98, rb=0.108, yb=0.124, rt=0.130, yt=0.290, r0=0.050, comba=0.020, rizo=0.030, k=0.046,
               exp=1.25, punta=0.0020, panza=0.30),
        # La espalda: lo que se ve desde arriba y por detrás. También desigual.
        lengua(150, rb=0.084, yb=0.148, rt=0.110, yt=0.262, r0=0.052, comba=0.024, rizo=0.022, k=0.046,
               exp=1.3, punta=0.0020, panza=0.30),
        lengua(-140, rb=0.084, yb=0.150, rt=0.090, yt=0.336, r0=0.056, comba=0.020, rizo=0.036, k=0.048,
               exp=1.25, punta=0.0020, panza=0.30),
        # Los chisporroteos bajos de los lados: pequeños y abiertos, casi a ras.
        lengua(118, rb=0.120, yb=0.090, rt=0.188, yt=0.176, r0=0.028, comba=0.012, rizo=0.012, k=0.028,
               exp=1.4, punta=0.0018, panza=0.20),
        lengua(-122, rb=0.118, yb=0.094, rt=0.180, yt=0.160, r0=0.024, comba=0.012, rizo=0.010, k=0.026,
               exp=1.4, punta=0.0018, panza=0.20),
    ]
    for i, l in enumerate(L):
        l["fase"] = (i * 0.37) % 1.0
    # El cuerpo, alto de hombros: así las lenguas son cortas, una corona, y no
    # pétalos sueltos con la muesca hasta abajo. Algo más estrecho que antes: la
    # anchura la dan ahora las lenguas, no la panza.
    return {"c": (0.0, 0.114, -0.004), "r": (0.140, 0.074, 0.120),
            "cuello_c": (0.0, 0.064, 0.0), "cuello_r": (0.092, 0.026, 0.084),
            "lenguas": L, "suelo": PIVOTE_ENTERA - 0.006}


def nucleo_entero():
    L = [lengua_libre([(0.000, 0.140, -0.012), (0.020, 0.180, -0.020),
                       (-0.016, 0.214, -0.026), (0.006, 0.246, -0.024)], r0=0.048, exp=1.2, k=0.032,
                      panza=0.3)]
    L[0]["fase"] = 0.0
    return {"c": (0.0, 0.104, 0.000), "r": (0.120, 0.056, 0.102),
            "cuello_c": (0.0, 0.066, 0.002), "cuello_r": (0.080, 0.024, 0.074),
            "cara_c": (0.0, -0.005, -0.190), "cara_r": 0.285, "cara_y": 0.146,
            "lenguas": L, "suelo": PIVOTE_ENTERA - 0.004}


# La ASCUA es la misma llama en pequeño: la misma corona, la misma cara. Antes
# era otra receta (una lengua y dos amagos) y salía otra criatura; las dos mitades
# de la BRASA tienen que leerse como ELLA, solo que menores y más rojas (el rojo
# lo pone el shader con `templado`).
TALLA_ASCUA = 0.72


def a_ascua(F):
    """La forma de la entera, escalada a la ascua alrededor del pie de la llama."""
    t = TALLA_ASCUA

    def p(v):
        v = np.asarray(v, dtype=np.float64)
        return np.stack([v[..., 0] * t, PIVOTE_ASCUA + (v[..., 1] - PIVOTE_ENTERA) * t, v[..., 2] * t], -1)

    G = dict(F)
    G["c"] = tuple(p(F["c"]))
    G["r"] = tuple(np.asarray(F["r"]) * t)
    G["cuello_c"] = tuple(p(F["cuello_c"]))
    G["cuello_r"] = tuple(np.asarray(F["cuello_r"]) * t)
    G["suelo"] = PIVOTE_ASCUA + (F["suelo"] - PIVOTE_ENTERA) * t
    if "cara_c" in F:
        G["cara_c"] = tuple(p(F["cara_c"]))
        G["cara_r"] = F["cara_r"] * t
        G["cara_y"] = PIVOTE_ASCUA + (F["cara_y"] - PIVOTE_ENTERA) * t
    G["lenguas"] = []
    for L in F["lenguas"]:
        M = dict(L)
        M["puntos"] = p(L["puntos"])
        for k in ("r0", "k", "punta"):
            M[k] = L[k] * t
        M["fase"] = (L["fase"] + 0.2) % 1.0
        G["lenguas"].append(M)
    return G


def forma_ascua():
    return a_ascua(forma_entera())


def nucleo_ascua():
    return a_ascua(nucleo_entero())


def carbon_entero():
    c, r = (0.0, 0.026, 0.0), (0.112, 0.050, 0.104)
    n = 20
    semillas, normales, rebaje = trozos_carbon(c, r, n, baile=0.016, giro=0.30)
    return {"c": c, "r": r, "bulto": 0.008, "semilla": 1.7,
            "semillas": semillas, "normales": normales, "rebaje": rebaje,
            "desnivel": RNG.uniform(-0.002, 0.007, n),
            "ancho": 0.0046, "hondo": 0.012,
            "crater_c": (0.003, PIVOTE_ENTERA + 0.080, -0.004), "crater_r": 0.080}


def carbon_ascua():
    c, r = (0.0, 0.019, 0.0), (0.076, 0.037, 0.070)
    n = 11
    semillas, normales, rebaje = trozos_carbon(c, r, n, baile=0.011, giro=0.30)
    corte = np.array([0.80, 0.30, -0.52])
    corte /= np.linalg.norm(corte)
    return {"c": c, "r": r, "bulto": 0.007, "semilla": 4.1,
            "semillas": semillas, "normales": normales, "rebaje": rebaje,
            "desnivel": RNG.uniform(-0.002, 0.005, n),
            "ancho": 0.0042, "hondo": 0.010,
            "crater_c": (0.0, PIVOTE_ASCUA + 0.058, 0.0), "crater_r": 0.058,
            "corte_n": corte, "corte_d": 0.050}


# ---------------------------------------------------------------- de campo a malla

def a_blender(P):
    """Godot (x, y arriba, z al jugador) → Blender (x, y al fondo, z arriba)."""
    P = np.asarray(P, dtype=np.float64)
    return np.stack([P[..., 0], -P[..., 2], P[..., 1]], axis=-1)


def a_godot(P):
    P = np.asarray(P, dtype=np.float64)
    return np.stack([P[..., 0], P[..., 2], -P[..., 1]], axis=-1)


def malla_de_campo(nombre, fn, lo, hi, paso, tris, alisar=2):
    """Evalúa el campo en una rejilla, saca la superficie y la deja en `tris`
    triángulos. Devuelve el objeto de Blender, ya en la escena."""
    lo = np.asarray(lo, dtype=np.float64)
    hi = np.asarray(hi, dtype=np.float64)
    ejes = [np.arange(lo[i], hi[i] + paso * 0.5, paso) for i in range(3)]
    X, Y, Z = np.meshgrid(ejes[0], ejes[1], ejes[2], indexing="ij")
    P = np.stack([X.ravel(), Y.ravel(), Z.ravel()], axis=1)
    campo = fn(P).reshape(X.shape).astype(np.float32)
    # En vóxeles: OpenVDB quiere la distancia en su propia unidad para interpolar bien.
    rejilla = vdb.FloatGrid(3.0)
    rejilla.copyFromArray(np.clip(campo / paso, -3.0, 3.0))
    pts, tri, cuad = rejilla.convertToPolygons(isovalue=0.0, adaptivity=0.0)
    verts = a_blender(lo + np.asarray(pts, dtype=np.float64) * paso)
    caras = [tuple(int(i) for i in t) for t in tri] + [tuple(int(i) for i in q) for q in cuad]
    malla = bpy.data.meshes.new(nombre + "_fina")
    malla.from_pydata([tuple(v) for v in verts], [], caras)
    malla.validate(verbose=False)
    malla.update()
    bm = bmesh.new()
    bm.from_mesh(malla)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=paso * 0.02)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    for _ in range(alisar):
        bmesh.ops.smooth_vert(bm, verts=bm.verts, factor=0.5, use_axis_x=True, use_axis_y=True,
                              use_axis_z=True)
    bm.to_mesh(malla)
    bm.free()
    obj = bpy.data.objects.new(nombre, malla)
    bpy.context.scene.collection.objects.link(obj)
    ahora = sum(len(p.vertices) - 2 for p in malla.polygons)
    if ahora > tris:
        mod = obj.modifiers.new("simplificar", "DECIMATE")
        mod.decimate_type = "COLLAPSE"
        mod.ratio = tris / ahora
        mod.use_collapse_triangulate = True
        grafo = bpy.context.evaluated_depsgraph_get()
        nueva = bpy.data.meshes.new_from_object(obj.evaluated_get(grafo))
        obj.modifiers.clear()
        obj.data = nueva
        bpy.data.meshes.remove(malla)
    # La simplificación deja a veces algún triángulo sin área: fuera, que el
    # exportador avisa de malla no válida y Godot los importa con normal cero.
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.validate(verbose=False)
    obj.data.update()
    obj.data.name = nombre
    obj.data.shade_smooth()
    return obj


def vertices_godot(obj):
    n = len(obj.data.vertices)
    co = np.zeros(n * 3)
    obj.data.vertices.foreach_get("co", co)
    no = np.zeros(n * 3)
    obj.data.vertices.foreach_get("normal", no)
    return a_godot(co.reshape(n, 3)), a_godot(no.reshape(n, 3))


def vecinos(obj):
    n = len(obj.data.vertices)
    lista = [[] for _ in range(n)]
    for e in obj.data.edges:
        a, b = e.vertices
        lista[a].append(b)
        lista[b].append(a)
    return lista


def suavizar(valores, vec, veces=1):
    v = np.asarray(valores, dtype=np.float64)
    for _ in range(veces):
        nuevo = v.copy()
        for i, lista in enumerate(vec):
            if lista:
                nuevo[i] = 0.5 * v[i] + 0.5 * float(np.mean(v[lista]))
        v = nuevo
    return v


def hemisferio(n):
    """Direcciones repartidas por la media esfera de +z, con más peso arriba."""
    d = []
    for i in range(n):
        u = (i + 0.5) / n
        a = i * math.pi * (3.0 - math.sqrt(5.0))
        r = math.sqrt(u)
        d.append((r * math.cos(a), r * math.sin(a), math.sqrt(max(1.0 - u, 0.0))))
    return np.array(d)


def oclusion(obj, radio, fuerza=1.0, rayos=40, con_suelo=False):
    """Oclusión por vértice lanzando rayos contra la propia malla (en Blender)."""
    malla = obj.data
    n = len(malla.vertices)
    co = np.zeros(n * 3)
    malla.vertices.foreach_get("co", co)
    co = co.reshape(n, 3)
    no = np.zeros(n * 3)
    malla.vertices.foreach_get("normal", no)
    no = no.reshape(n, 3)
    verts = [tuple(v) for v in co]
    polis = [tuple(p.vertices) for p in malla.polygons]
    if con_suelo:
        b = len(verts)
        verts += [(-2.0, -2.0, -0.0005), (2.0, -2.0, -0.0005), (2.0, 2.0, -0.0005), (-2.0, 2.0, -0.0005)]
        polis.append((b, b + 1, b + 2, b + 3))
    arbol = BVHTree.FromPolygons(verts, polis)
    dirs = hemisferio(rayos)
    ao = np.ones(n)
    for i in range(n):
        nz = no[i]
        ref = np.array([0.0, 0.0, 1.0]) if abs(nz[2]) < 0.9 else np.array([1.0, 0.0, 0.0])
        tx = np.cross(ref, nz)
        tx /= max(np.linalg.norm(tx), 1e-9)
        ty = np.cross(nz, tx)
        origen = Vector(co[i] + nz * 0.0015)
        tapado = 0.0
        for d in dirs:
            w = tx * d[0] + ty * d[1] + nz * d[2]
            golpe = arbol.ray_cast(origen, Vector(w), radio)
            if golpe[0] is not None:
                tapado += 1.0 - golpe[3] / radio
        ao[i] = 1.0 - min(tapado / rayos * fuerza, 1.0)
    return ao


def canto(obj, vec):
    """Lo saliente que es cada vértice: positivo en un filo, cero en un llano."""
    co, no = vertices_godot(obj)
    c = np.zeros(len(co))
    for i, lista in enumerate(vec):
        if not lista:
            continue
        e = co[i] - co[lista]
        largo = np.maximum(np.sqrt((e * e).sum(1)), 1e-9)
        c[i] = float(np.mean((e @ no[i]) / largo))
    return c


def pintar(obj, r, g, b):
    malla = obj.data
    n = len(malla.vertices)
    attr = malla.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    datos = np.ones((n, 4))
    datos[:, 0] = np.clip(r, 0.0, 1.0)
    datos[:, 1] = np.clip(g, 0.0, 1.0)
    datos[:, 2] = np.clip(b, 0.0, 1.0)
    attr.data.foreach_set("color", datos.ravel())
    malla.color_attributes.active_color = attr
    malla.color_attributes.render_color_index = 0


def material(obj, nombre, color=(0.5, 0.5, 0.5), luz=0.0):
    """Un material de MUESTRA: lo justo para que el GLB se entienda al abrirlo
    solo. Lo que arde va en negro y con emisión, porque el color de vértice de
    esas mallas son datos (oclusión, lengua, fase) y glTF lo multiplica por el
    color base: con base de color, la llama saldría teñida de sus propios datos."""
    mat = bpy.data.materials.get(nombre)
    if mat is None:
        mat = bpy.data.materials.new(nombre)
        nodos = mat.node_tree.nodes if mat.node_tree is not None else []
        for n in nodos:
            if n.type == "BSDF_PRINCIPLED":
                if luz > 0.0:
                    n.inputs["Base Color"].default_value = (0.0, 0.0, 0.0, 1.0)
                    n.inputs["Emission Color"].default_value = (color[0], color[1], color[2], 1.0)
                    n.inputs["Emission Strength"].default_value = luz
                else:
                    n.inputs["Base Color"].default_value = (color[0], color[1], color[2], 1.0)
                n.inputs["Roughness"].default_value = 0.85
    obj.data.materials.clear()
    obj.data.materials.append(mat)


def triangulos(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


# -------------------------------------------------------------------- las piezas

def ancho_ventana(cara, y):
    """Medio ancho de la ventana de la cara a la altura `y`. Es la MISMA cuenta
    que hace `brasa_llama.gdshader` (su función `ventana`): si se toca una, se
    toca la otra."""
    t = np.clip((y - cara[2]) / (cara[3] - cara[2]), 0.0, 1.0)
    return cara[0] * (1.0 - t) ** 0.8 * np.sqrt(np.clip((y - cara[1]) / 0.034, 0.0, 1.0))


def abrir_ventana(obj, cara, margen):
    """Quita de la melena las caras que el shader iba a tirar SIEMPRE. El borde de
    la ventana lo sigue royendo el shader con su ruido —por eso aquí se corta
    `margen` por dentro: el filo de polígonos queda donde nunca se dibuja—, pero
    con el hueco hecho de verdad el modelo enseña la cara al abrirlo solo, y la
    tarjeta se ahorra pintar para nada todo lo de delante del núcleo."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    fuera = []
    for f in bm.faces:
        dentro = True
        for v in f.verts:
            x, y, z = v.co.x, v.co.z, -v.co.y          # de Blender a Godot
            nz = -v.normal.y
            if not (abs(x) < ancho_ventana(cara, y) - margen and y > cara[1] + margen * 0.6
                    and nz > 0.28 and z > 0.0):
                dentro = False
                break
        if dentro:
            fuera.append(f)
    bmesh.ops.delete(bm, geom=fuera, context="FACES")
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    return len(fuera)


def hacer_llama(nombre, F, lo, hi, paso, tris, radio_ao, muestra, cara=None, margen=0.008):
    obj = malla_de_campo(nombre, lambda P: sd_llama(P, F), lo, hi, paso, tris)
    if cara is not None:
        quitadas = abrir_ventana(obj, cara, margen)
        print("BRASA %s: ventana %s, %d caras fuera" % (nombre, np.round(cara, 3), quitadas))
    obj.data.shade_smooth()
    P, _n = vertices_godot(obj)
    vec = vecinos(obj)
    g, b = datos_llama(P, F)
    ao = suavizar(oclusion(obj, radio_ao, 3.2), vec, 1)
    pintar(obj, ao, suavizar(g, vec, 1), b)
    material(obj, muestra[0], muestra[1], muestra[2])
    return obj


def ventana_de(ojos, alto_llama, talla):
    """Dónde va la ventana, sacado de dónde están los ojos. Es la misma cuenta
    que hace `brasa.gd` al montar (allí lee los ojos del GLB): medio ancho, y de
    abajo, y donde empieza a cerrarse, y de la punta."""
    cx = abs(ojos[0]["centro"][0])
    cy = 0.5 * (ojos[0]["centro"][1] + ojos[1]["centro"][1])
    medio = ojos[1]["medio"]
    alto_ojo = medio[1] * ojos[1]["arriba"][1]
    aire = 0.024 * talla
    return (cx + medio[0] + aire * 0.9, cy - alto_ojo - aire, cy + alto_ojo + aire * 0.2,
            cy + alto_ojo + (alto_llama - cy) * 0.30)


def hacer_carbon(nombre, F, lo, hi, paso, tris):
    obj = malla_de_campo(nombre, lambda P: sd_carbon(P, F), lo, hi, paso, tris, alisar=1)
    P, _n = vertices_godot(obj)
    vec = vecinos(obj)
    ao = suavizar(oclusion(obj, 0.045, 1.6, con_suelo=True), vec, 1)
    filo = suavizar(paso_suave(0.05, 0.30, canto(obj, vec)), vec, 1)
    # El ascua: lo que quedó por debajo de la piel del bulto sin tallar, o sea el
    # fondo de los surcos, el cráter y la cara del corte.
    hondo = -sd_carbon(P, F, surcos=False)
    ascua = paso_suave(0.0025, 0.0095, hondo)
    # Pegado al suelo no arde: ahí se apaga contra la losa.
    ascua *= paso_suave(0.002, 0.016, P[:, 1])
    pintar(obj, ao, filo, suavizar(ascua, vec, 1))
    material(obj, "brasa_carbon", (0.045, 0.043, 0.050))
    return obj


def superficie(fn, x, y, z0=0.0, z1=0.30):
    """El punto de la piel de `fn` que hay en (x, y) mirando desde delante."""
    a, b = z0, z1
    for _ in range(40):
        m = 0.5 * (a + b)
        if fn(np.array([[x, y, m]]))[0] < 0.0:
            a = m
        else:
            b = m
    return np.array([x, y, 0.5 * (a + b)])


def gradiente(fn, p, e=0.0015):
    g = np.zeros(3)
    for i in range(3):
        d = np.zeros(3)
        d[i] = e
        g[i] = fn((p + d)[None, :])[0] - fn((p - d)[None, :])[0]
    return g / max(np.linalg.norm(g), 1e-12)


def hacer_ojo(nombre, fn, x, y, ancho, alto, lado, anillos=4, sectores=20, ceja=0.06):
    """Una cuenca: un disco de superelipse AJUSTADO a la piel del núcleo, con el
    reborde levantado. El contorno se dibuja DE FRENTE —`ancho` y `alto` son lo
    que mide visto desde delante— y se proyecta sobre la cara: así el ojo sale
    derecho para cualquier cámara que mire desde el lado del jugador, por mucha
    curva que tenga la piel. Es un objeto con su propio marco —x a la derecha, y
    hacia arriba por la piel, z hacia fuera— para poder moverlo en Godot.
    `lado` es −1 para el izquierdo: la ceja cae hacia el centro de la cara."""
    centro = superficie(fn, x, y)
    n = gradiente(fn, centro)
    derecha = np.array([1.0, 0.0, 0.0])
    derecha = derecha - n * float(derecha @ n)
    derecha /= np.linalg.norm(derecha)
    arriba = np.cross(n, derecha)
    k = 3.0
    verts = []
    uvs = []
    # Las fracciones del radio: el último anillo es una falda que se hunde en el
    # núcleo, para que de canto no se vea una rendija entre la cuenca y la cara.
    fr = [i / anillos for i in range(anillos + 1)] + [1.05]
    for i, f in enumerate(fr):
        for j in range(sectores):
            if i == 0 and j > 0:
                break
            a = 2.0 * math.pi * j / sectores
            ca, sa = math.cos(a), math.sin(a)
            rho = 1.0 / (abs(ca) ** k + abs(sa) ** k) ** (1.0 / k)
            u = f * rho * ca
            v = f * rho * sa
            # La ceja: el borde de arriba baja hacia el centro de la cara.
            vv = v - ceja * (-lado * u) * max(v, 0.0)
            ps = superficie(fn, x + u * ancho, y + vv * alto)
            ns = gradiente(fn, ps)
            if f > 1.0:
                sube = -0.004
            else:
                sube = 0.0040 + 0.0042 * paso_suave(0.60, 0.86, np.array([f]))[0] \
                    * (1.0 - 0.55 * paso_suave(0.90, 1.0, np.array([f]))[0])
            p = ps + ns * sube
            e = p - centro
            verts.append((float(e @ derecha), float(e @ arriba), float(e @ n)))
            uvs.append((0.5 + 0.5 * u, 0.5 + 0.5 * v))
    caras = []
    for j in range(sectores):
        caras.append((0, 1 + j, 1 + (j + 1) % sectores))
    for i in range(1, len(fr) - 1):
        a0 = 1 + (i - 1) * sectores
        b0 = 1 + i * sectores
        for j in range(sectores):
            j2 = (j + 1) % sectores
            caras.append((a0 + j, b0 + j, b0 + j2, a0 + j2))
    # Local de Godot (x, y, z) → local de Blender (x, −z, y).
    malla = bpy.data.meshes.new(nombre)
    malla.from_pydata([(v[0], -v[2], v[1]) for v in verts], [], caras)
    malla.update()
    capa = malla.uv_layers.new(name="UVMap")
    for poli in malla.polygons:
        for li in poli.loop_indices:
            capa.data[li].uv = uvs[malla.loops[li].vertex_index]
    malla.shade_smooth()
    obj = bpy.data.objects.new(nombre, malla)
    bpy.context.scene.collection.objects.link(obj)
    # El marco: en Blender el eje local −y es el «hacia fuera» y el z el «arriba».
    ex = a_blender(derecha)
    ey = a_blender(-n)
    ez = a_blender(arriba)
    c = a_blender(centro)
    obj.matrix_world = Matrix((
        (ex[0], ey[0], ez[0], c[0]),
        (ex[1], ey[1], ez[1], c[1]),
        (ex[2], ey[2], ez[2], c[2]),
        (0.0, 0.0, 0.0, 1.0)))
    material(obj, "brasa_ojo", (0.10, 0.03, 0.03))
    # Que las caras miren hacia fuera (−y local en Blender).
    fuera = sum(1 for p in malla.polygons if p.normal.y < 0.0)
    if fuera < len(malla.polygons) / 2:
        malla.flip_normals()
    va = np.array(verts)
    medio = (0.5 * (va[:, 0].max() - va[:, 0].min()), 0.5 * (va[:, 1].max() - va[:, 1].min()))
    return {"obj": obj, "centro": centro, "n": n, "arriba": arriba, "medio": medio}


def hacer_pavesa():
    """Un rombo alargado: lo que en el sprite son los cuadraditos rojos de los lados."""
    a = TAM_PAVESA * 0.5
    v = [(a, 0.0, 0.0), (-a, 0.0, 0.0), (0.0, a, 0.0), (0.0, -a, 0.0), (0.0, 0.0, a * 1.6), (0.0, 0.0, -a * 1.6)]
    c = [(0, 2, 4), (2, 1, 4), (1, 3, 4), (3, 0, 4), (2, 0, 5), (1, 2, 5), (3, 1, 5), (0, 3, 5)]
    malla = bpy.data.meshes.new("pavesa")
    malla.from_pydata(v, [], c)
    malla.update()
    obj = bpy.data.objects.new("pavesa", malla)
    bpy.context.scene.collection.objects.link(obj)
    material(obj, "brasa_pavesa", (0.57, 0.07, 0.045), 0.9)
    return obj


# ------------------------------------------------------------------------ mirar

def renders(carpeta, grupos):
    """Unos renders de trabajo (Workbench, con el color de vértice) para ver la
    forma sin pasar por Godot. No son el aspecto final: eso lo ponen los shaders."""
    os.makedirs(carpeta, exist_ok=True)
    esc = bpy.context.scene
    esc.render.engine = "BLENDER_WORKBENCH"
    esc.display.shading.light = "STUDIO"
    esc.display.shading.color_type = "VERTEX"
    esc.display.shading.show_cavity = True
    esc.render.resolution_x = 640
    esc.render.resolution_y = 640
    esc.render.film_transparent = False
    esc.world = bpy.data.worlds.new("fondo")
    esc.world.color = (0.05, 0.05, 0.06)
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = "ORTHO"
    cam = bpy.data.objects.new("cam", cam_d)
    esc.collection.objects.link(cam)
    esc.camera = cam
    todos = [o for o in esc.objects if o.type == "MESH"]
    for nombre, objs, centro, tam in grupos:
        for o in todos:
            o.hide_render = o not in objs
        cam_d.ortho_scale = tam
        for vista, (az, el) in {"frente": (0.0, 8.0), "tres_cuartos": (38.0, 30.0),
                                 "lado": (90.0, 8.0), "espalda": (180.0, 20.0),
                                 "juego": (0.0, 48.0), "cenital": (0.0, 89.0)}.items():
            a, e = math.radians(az), math.radians(el)
            # En Godot: la cámara en +z mirando a −z. Se pasa a Blender.
            d = np.array([math.sin(a) * math.cos(e), math.sin(e), math.cos(a) * math.cos(e)])
            pos = a_blender(np.asarray(centro) + d * 2.0)
            cam.location = Vector(pos)
            hacia = Vector(a_blender(np.asarray(centro))) - cam.location
            cam.rotation_euler = hacia.to_track_quat("-Z", "Y").to_euler()
            esc.render.filepath = os.path.join(carpeta, "%s_%s.png" % (nombre, vista))
            bpy.ops.render.render(write_still=True)
    for o in todos:
        o.hide_render = False
    bpy.data.objects.remove(cam)


# ----------------------------------------------------------------------- el guion

def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)

    NARANJA, ORO, ROJO_LUZ = (0.81, 0.22, 0.07), (0.75, 0.38, 0.045), (0.57, 0.07, 0.045)

    F = forma_entera()
    N = nucleo_entero()
    nucleo = hacer_llama("nucleo", N, (-0.15, 0.0, -0.14), (0.15, 0.28, 0.14), 0.004, 720, 0.06,
                         ("brasa_nucleo", ORO, 0.9))
    fn_n = lambda P: sd_llama(P, N, False)
    ojos = [hacer_ojo("ojo_izq", fn_n, -OJO_X, OJO_Y, OJO_ANCHO, OJO_ALTO, -1.0),
            hacer_ojo("ojo_der", fn_n, OJO_X, OJO_Y, OJO_ANCHO, OJO_ALTO, 1.0)]
    alto = float(F["lenguas"][0]["puntos"][-1][1])
    llama = hacer_llama("llama", F, (-0.27, 0.0, -0.25), (0.27, 0.42, 0.25), 0.004, 2900, 0.10,
                        ("brasa_llama", NARANJA, 0.7), ventana_de(ojos, alto, 1.0))
    carbon = hacer_carbon("carbon", carbon_entero(), (-0.140, -0.008, -0.135), (0.140, 0.095, 0.135),
                          0.0026, 2000)

    Fa = forma_ascua()
    Na = nucleo_ascua()
    nucleo_a = hacer_llama("nucleo_ascua", Na, (-0.11, 0.0, -0.10), (0.11, 0.21, 0.10), 0.003, 380, 0.05,
                           ("brasa_nucleo", ORO, 0.9))
    fn_a = lambda P: sd_llama(P, Na, False)
    t = TALLA_ASCUA
    oy = PIVOTE_ASCUA + (OJO_Y - PIVOTE_ENTERA) * t
    ojos_a = [hacer_ojo("ojo_ascua_izq", fn_a, -OJO_X * t, oy, OJO_ANCHO * t, OJO_ALTO * t, -1.0),
              hacer_ojo("ojo_ascua_der", fn_a, OJO_X * t, oy, OJO_ANCHO * t, OJO_ALTO * t, 1.0)]
    alto_a = float(Fa["lenguas"][0]["puntos"][-1][1])
    llama_a = hacer_llama("llama_ascua", Fa, (-0.20, 0.0, -0.19), (0.20, 0.31, 0.19), 0.003, 1120, 0.07,
                          ("brasa_llama_ascua", ROJO_LUZ, 0.8), ventana_de(ojos_a, alto_a, 0.72), 0.006)
    carbon_a = hacer_carbon("carbon_ascua", carbon_ascua(), (-0.095, -0.006, -0.090),
                            (0.095, 0.074, 0.090), 0.0022, 900)
    pavesa = hacer_pavesa()
    ojo_i, ojo_d = ojos[0]["obj"], ojos[1]["obj"]
    ojo_ai, ojo_ad = ojos_a[0]["obj"], ojos_a[1]["obj"]
    c_i, n_i = ojos[0]["centro"], ojos[0]["n"]

    # Cada criatura, bajo su vacío. Las piezas guardan su sitio RESPECTO al vacío,
    # que es lo que lee `brasa.gd`: mover el vacío no descoloca nada.
    def colgar(nombre, piezas, donde):
        vacio = bpy.data.objects.new(nombre, None)
        bpy.context.scene.collection.objects.link(vacio)
        vacio.location = Vector(a_blender(np.array(donde)))
        for o in piezas:
            local = o.matrix_world.copy()
            o.parent = vacio
            o.matrix_parent_inverse = Matrix.Identity(4)
            o.matrix_local = local
        return vacio

    bpy.context.view_layer.update()
    colgar("entera", [llama, nucleo, carbon, ojo_i, ojo_d], (0.0, 0.0, 0.0))
    colgar("ascua", [llama_a, nucleo_a, carbon_a, ojo_ai, ojo_ad], (APARTE_ASCUA, 0.0, 0.0))
    pavesa.location = Vector(a_blender(np.array((-0.26, 0.10, 0.06))))

    total = 0
    for o in (llama, nucleo, carbon, ojo_i, ojo_d, llama_a, nucleo_a, carbon_a, ojo_ai, ojo_ad, pavesa):
        t = triangulos(o)
        total += t
        P, _n = vertices_godot(o)
        print("BRASA %-14s %5d tri  x[%.3f %.3f] y[%.3f %.3f] z[%.3f %.3f]" % (
            o.name, t, P[:, 0].min(), P[:, 0].max(), P[:, 1].min(), P[:, 1].max(),
            P[:, 2].min(), P[:, 2].max()))
    print("BRASA total: %d triángulos" % total)
    print("BRASA ojo_izq en %s, normal %s (sube %.0f°)" % (
        np.round(c_i, 4), np.round(n_i, 3), math.degrees(math.asin(n_i[1]))))

    os.makedirs(os.path.dirname(os.path.abspath(SALIDA)), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=os.path.abspath(SALIDA), export_format="GLB", use_selection=False,
        export_yup=True, export_apply=False, export_normals=True, export_tangents=False,
        export_materials="EXPORT", export_vertex_color="ACTIVE",
        export_all_vertex_colors=False, export_active_vertex_color_when_no_material=True,
        export_animations=False, export_skins=False, export_morph=False)
    print("BRASA guardado en", os.path.abspath(SALIDA))

    if VISTAS:
        renders(VISTAS, [
            ("entera", [llama, nucleo, carbon, ojo_i, ojo_d], (0.0, 0.17, 0.0), 0.50),
            ("nucleo", [nucleo, carbon, ojo_i, ojo_d], (0.0, 0.15, 0.0), 0.42),
            ("carbon", [carbon], (0.0, 0.04, 0.0), 0.30),
            ("ascua", [llama_a, nucleo_a, carbon_a, ojo_ai, ojo_ad], (APARTE_ASCUA, 0.12, 0.0), 0.36),
            ("las_dos", [llama, nucleo, carbon, ojo_i, ojo_d, llama_a, nucleo_a, carbon_a, ojo_ai,
                         ojo_ad, pavesa], (APARTE_ASCUA * 0.5, 0.16, 0.0), 0.80),
        ])
        print("BRASA vistas en", VISTAS)


main()
