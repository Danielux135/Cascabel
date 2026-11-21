# criatura_calavera.py — genera cripta3d/modelos/criatura_calavera.glb
#
#   python cripta3d/herramientas/blender3d.py cripta3d/blender/criatura_calavera.py -- \
#       cripta3d/modelos/criatura_calavera.glb [--vistas=C:/carpeta/temporal] [--borrador]
#
# LA CALAVERA de Cascabel en 3D: la criatura del sprite (`cr_calavera`), que en la
# caza es la especie «escarabajo», el acorazado. Una calavera de hueso que anda
# sobre sus dos manos.
#
# CÓMO ESTÁ HECHA, y por qué así. No hay ni una primitiva pegada: cada pieza es
# un CAMPO DE DISTANCIAS (una función que dice a qué distancia está cada punto de
# la superficie) hecho de elipsoides, cápsulas y cajas que se FUNDEN entre sí con
# uniones suaves y se vacían con restas suaves. Así los pómulos salen de la
# bóveda, las cuencas tienen el reborde romo y la mandíbula es una cuchara, no
# una caja. Del campo se saca la malla (redes de superficie, escritas abajo en
# numpy), Blender la reduce a los triángulos que caben, y TODO lo demás vuelve a
# salir del campo, no de la malla reducida:
#
#   · la posición final de cada vértice (se vuelve a posar sobre la superficie),
#   · la normal (el gradiente del campo: una malla de 3.000 triángulos sombrea
#     como la de 100.000 de la que salió),
#   · la oclusión (R): cuánto cielo ve cada vértice, marchando por el campo,
#   · el canto (G): la curvatura, que es la laplaciana del campo,
#   · y el diente (B): los dientes son islas aparte y van marcados.
#
# Es la convención de color de vértice de `cripta3d/LEEME.md`: R oclusión
# (1 = al aire), G canto/desgaste (1 = filo), B libre (aquí: esmalte de diente).
#
# LAS PIEZAS van separadas y con nombre porque en Godot se mueven por código
# (`cripta3d/criaturas/calavera.gd`), sin huesos ni animaciones grabadas:
#
#   craneo                      la bóveda con la cara y los dientes de arriba
#     └ mandibula               su origen es la BISAGRA: girar en X es abrir la boca
#         └ menton              (vacío) lo más bajo: por ahí la cierra el suelo
#     └ ojo_i, ojo_d            (vacíos) el fondo de cada cuenca, para la luz
#     └ hombro_i, hombro_d      (vacíos) de dónde salen los brazos
#     └ nuca, nuca_canal        (vacíos) el agujero occipital, de donde cuelga la
#                               cola, y un punto más abajo de su canal
#   humero_i/_d                 origen en el hombro, hueso a lo largo de +Y
#     └ codo_i/_d               (vacío) el otro extremo: da el largo
#   antebrazo_i/_d              origen en el codo, cúbito y radio a lo largo de +Y
#     └ muneca_i/_d             (vacío)
#   mano_i/_d                   origen en la muñeca, dedos hacia +Z, apoyada
#     └ dedo_i_0..2, pulgar_i   origen en el nudillo: girar en X es cerrar el dedo
#     └ apoyo_i/_d              (vacío) a qué altura está la muñeca cuando pisa
#   vertebra_0..4               la cola: las cinco vértebras que arrastra. Origen
#                               en el centro, la columna a lo largo de Z
#   huesecillo                  el hueso que le da vueltas cuando está aturdida
#
# `_i` es la IZQUIERDA de la criatura, que mirando hacia +Z cae en +X.
#
# LA MALLA DE IA (`calavera_trellis.glb`) SE MIRÓ Y NO SE USÓ (17-nov-2026). Es un
# buen cráneo, pero es OTRO cráneo: humano, alto y estrecho (0,68 de ancho por 1
# de alto), con la mandíbula cerrada y soldada (15 islas, 162 aristas abiertas)
# y una docena de dientes pequeños por fila. El del sprite es ancho y chato, de
# cuencas enormes, con la boca abierta y dientes pocos y gordos. Para llevarlo
# ahí habría que estirarlo un 40 % de ancho, cortarle la mandíbula y rehacerle
# los dientes: o sea, tirar justo lo que tiene de bueno. Aquí las proporciones
# salen MEDIDAS del sprite (1 px = 0,0083) y la mandíbula ya nace aparte.
#
# SE PROBÓ ENTERA (21-nov-2026), con `fuentes/calavera_ia.glb`: importada,
# ensanchada un 24 %, la mandíbula cortada por la línea de los dientes y por la
# rama hasta el cóndilo, los huecos tapados, reducida a 3.500 + 1.200
# triángulos, con la oclusión a rayos y la curvatura de la malla fina. En el
# visor, lado a lado con esta, PERDÍA en todas las tomas: a esa talla sus doce
# dientes por fila se funden en una masa, la boca no sale negra (es una cáscara
# hueca y se ve el interior), las cuencas son más pequeñas y angulosas que las
# del sprite y de lejos se lee como una calavera cualquiera, no como ESTA. Lo
# único que ganaba era algo de anatomía en la bóveda, que desde la cámara de
# juego no se ve. Se quedó la de campo.
#
# TODO SE ESCRIBE EN COORDENADAS DE GODOT (X a su izquierda, Y arriba, Z hacia
# donde mira) y se pasa a las de Blender al crear cada malla; el exportador las
# devuelve a Y-arriba y en Godot salen los mismos números que hay aquí.
import math
import os
import sys
import time

import bpy
import numpy as np
from mathutils import Matrix

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SALIDA = None
VISTAS = None
BORRADOR = False
for _a in ARGV:
    if _a.startswith("--vistas="):
        VISTAS = _a.split("=", 1)[1]
    elif _a == "--borrador":
        BORRADOR = True
    elif SALIDA is None:
        SALIDA = _a
if SALIDA is None:
    SALIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "modelos",
                          "criatura_calavera.glb")
SALIDA = os.path.abspath(SALIDA)

F32 = np.float32
T0 = time.time()


def traza(*a):
    print("[calavera %5.1fs]" % (time.time() - T0), *a, flush=True)


# ------------------------------------------------------------------- medidas
# En unidades de Godot (1 = 100 px de mesa). El radio de choque de la especie es
# 0,17 y la bola mide 0,09: la bóveda mide 0,244 de ancho.

L1 = 0.116                         # húmero: del hombro al codo
L2 = 0.116                         # antebrazo: del codo a la muñeca
KM = 1.20                          # talla de la mano respecto a como está escrita
H_MUNECA = 0.027 * KM              # altura de la muñeca con la mano apoyada
BISAGRA = (0.0, -0.084, -0.006)    # el eje de la mandíbula, en el cráneo
# De dónde sale el brazo izquierdo, en el cráneo: DEBAJO de la bóveda, detrás de
# la rama de la mandíbula, en la punta de una clavícula escondida. (Estuvo en la
# mejilla, con un rodete: el húmero le salía de la cara.)
HOMBRO = (0.064, -0.116, -0.040)
# El agujero occipital, en la base: de ahí nace el espinazo.
AGUJERO = (0.0, -0.098, -0.058)
OJO = (0.050, 0.004, 0.086)        # el fondo de la cuenca izquierda
BOCA_REPOSO = math.radians(22.0)   # la boca del sprite está abierta
# La pose en la que se exporta, solo para que el GLB se vea montado al girarlo:
ALTO_REPOSO = 0.178
CABECEO_REPOSO = math.radians(-22.0)
MANO_REPOSO = (0.190, 0.062)       # (x, z) de la muñeca apoyada, respecto al centro
MENTON = (0.0, -0.164, 0.118)      # lo más bajo de la mandíbula cerrada, en el cráneo
# De dónde cuelga la cola: la boca del agujero occipital, y hacia dónde sale (el
# canal baja y va hacia atrás).
NUCA = (0.0, -0.106, -0.058)
NUCA_DIR = (0.0, -0.45, -0.89)
# La cola: cinco vértebras, cada una más pequeña. `COLA_PASO` es lo que separa
# una de la siguiente a talla 1, y `KV` lo que crece la vértebra respecto a como
# está escrita. (Los mismos números están en calavera.gd.) El paso es MENOR que
# lo que mide una vértebra: se tocan, encajadas por sus apófisis articulares.
# Con el paso más largo que el hueso era un peine de piezas sueltas.
COLA_TALLAS = (1.0, 0.87, 0.75, 0.64, 0.54)
COLA_PASO = 0.040
KV = 1.50

# Triángulos de cada pieza (el total tiene que quedar por debajo de ~9.000).
TRIS = {
    "craneo": 3300, "diente": 78, "mandibula": 1050,
    "humero": 260, "antebrazo": 340, "palma": 200, "dedo": 124, "pulgar": 96,
    "huesecillo": 80, "vertebra": 104,
}
if BORRADOR:
    for _k in TRIS:
        TRIS[_k] = max(40, TRIS[_k] // 2)


# ------------------------------------------------- campos de distancias (numpy)

def rot_x(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]], dtype=F32)


def rot_y(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]], dtype=F32)


def rot_z(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]], dtype=F32)


def esfera(p, c, r):
    return np.linalg.norm(p - np.asarray(c, F32), axis=1) - F32(r)


def elipsoide(p, c, r, giro=None):
    """Aproximación de Quílez: exacta en la superficie y con buen gradiente cerca."""
    q = p - np.asarray(c, F32)
    if giro is not None:
        q = q @ giro
    r = np.asarray(r, F32)
    k0 = np.linalg.norm(q / r, axis=1)
    k1 = np.linalg.norm(q / (r * r), axis=1)
    return np.where(k1 > 1e-5, k0 * (k0 - 1.0) / np.maximum(k1, 1e-5), -r.min()).astype(F32)


def capsula(p, a, b, r1, r2=None):
    """Un tramo redondeado de `a` a `b`. Con `r2`, el radio cambia a lo largo."""
    a = np.asarray(a, F32)
    b = np.asarray(b, F32)
    pa = p - a
    ba = b - a
    h = np.clip(pa @ ba / F32(ba @ ba), 0.0, 1.0)
    d = np.linalg.norm(pa - h[:, None] * ba, axis=1)
    if r2 is None:
        return (d - F32(r1)).astype(F32)
    return (d - (F32(r1) + F32(r2 - r1) * h)).astype(F32)


def caja(p, c, medio, r, giro=None):
    """Caja de cantos redondos: `medio` es la mitad de cada lado, `r` el radio del canto."""
    q = p - np.asarray(c, F32)
    if giro is not None:
        q = q @ giro
    q = np.abs(q) - (np.asarray(medio, F32) - F32(r))
    return (np.linalg.norm(np.maximum(q, 0.0), axis=1)
            + np.minimum(q.max(axis=1), 0.0) - F32(r)).astype(F32)


def union(a, b, k):
    if k <= 0.0:
        return np.minimum(a, b)
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return (b + (a - b) * h - k * h * (1.0 - h)).astype(F32)


def resta(a, b, k):
    """`a` sin `b`, con el reborde redondeado `k`."""
    h = np.clip(0.5 - 0.5 * (a + b) / k, 0.0, 1.0)
    return (a + (-b - a) * h + k * h * (1.0 - h)).astype(F32)


def inter(a, b, k):
    h = np.clip(0.5 - 0.5 * (b - a) / k, 0.0, 1.0)
    return (b + (a - b) * h + k * h * (1.0 - h)).astype(F32)


def _azar(ix, iy, iz, semilla):
    n = (ix * 73856093) ^ (iy * 19349663) ^ (iz * 83492791) ^ (semilla * 2654435761)
    n = n & 0x7FFFFFFF
    n = (n * 1103515245 + 12345) & 0x7FFFFFFF
    n = ((n ^ (n >> 15)) * 2246822519) & 0x7FFFFFFF
    n = n ^ (n >> 13)
    return (n & 0xFFFFFF).astype(F32) / F32(0xFFFFFF)


def ruido(p, semilla=0):
    """Ruido de valor 3D suave, de 0 a 1."""
    base = np.floor(p)
    f = (p - base).astype(F32)
    i = base.astype(np.int64)
    u = f * f * (3.0 - 2.0 * f)
    total = np.zeros(len(p), dtype=F32)
    for dx in (0, 1):
        wx = u[:, 0] if dx else 1.0 - u[:, 0]
        for dy in (0, 1):
            wy = u[:, 1] if dy else 1.0 - u[:, 1]
            for dz in (0, 1):
                wz = u[:, 2] if dz else 1.0 - u[:, 2]
                total += wx * wy * wz * _azar(i[:, 0] + dx, i[:, 1] + dy, i[:, 2] + dz, semilla)
    return total


def fbm(p, octavas=3, semilla=0):
    total = np.zeros(len(p), dtype=F32)
    amp = 0.5
    frec = 1.0
    norma = 0.0
    for o in range(octavas):
        total += amp * ruido(p * F32(frec), semilla + o * 17)
        norma += amp
        frec *= 2.03
        amp *= 0.5
    return total / F32(norma)


# --------------------------------------------------------- del campo a la malla

def campo_en_rejilla(f, lo, hi, h):
    xs = np.arange(lo[0], hi[0] + h * 0.5, h, dtype=F32)
    ys = np.arange(lo[1], hi[1] + h * 0.5, h, dtype=F32)
    zs = np.arange(lo[2], hi[2] + h * 0.5, h, dtype=F32)
    gx, gy, gz = np.meshgrid(xs, ys, zs, indexing="ij")
    p = np.stack([gx.ravel(), gy.ravel(), gz.ravel()], axis=1)
    trozos = []
    for i in range(0, len(p), 300000):
        trozos.append(f(p[i:i + 300000]))
    campo = np.concatenate(trozos).reshape(gx.shape)
    return campo, np.array([xs[0], ys[0], zs[0]], dtype=np.float64)


def redes(campo, origen, h):
    """Redes de superficie: un vértice por celda que la superficie cruza (la media
    de los cortes de sus aristas) y un cuadrado por cada arista de la rejilla que
    cambia de signo. Da una malla cerrada, de cuadrados parejos y sin escalones."""
    nx, ny, nz = campo.shape
    dentro = campo < 0.0
    cuenta = np.zeros((nx - 1, ny - 1, nz - 1), dtype=np.uint8)
    for a in (0, 1):
        for b in (0, 1):
            for c in (0, 1):
                cuenta += dentro[a:nx - 1 + a, b:ny - 1 + b, c:nz - 1 + c]
    activa = (cuenta > 0) & (cuenta < 8)
    ci, cj, ck = np.nonzero(activa)
    n = ci.size
    val = {}
    for a in (0, 1):
        for b in (0, 1):
            for c in (0, 1):
                val[(a, b, c)] = campo[ci + a, cj + b, ck + c].astype(np.float64)
    suma = np.zeros((n, 3), dtype=np.float64)
    cortes = np.zeros(n, dtype=np.float64)
    aristas = []
    for a in (0, 1):
        for b in (0, 1):
            aristas.append(((0, a, b), (1, a, b)))
            aristas.append(((a, 0, b), (a, 1, b)))
            aristas.append(((a, b, 0), (a, b, 1)))
    for e0, e1 in aristas:
        v0 = val[e0]
        v1 = val[e1]
        cruza = (v0 < 0.0) != (v1 < 0.0)
        t = np.where(cruza, v0 / np.where(cruza, v0 - v1, 1.0), 0.0)
        for eje in range(3):
            suma[:, eje] += np.where(cruza, e0[eje] + t * (e1[eje] - e0[eje]), 0.0)
        cortes += cruza
    pos = suma / np.maximum(cortes, 1.0)[:, None]
    verts = origen + (np.stack([ci, cj, ck], axis=1) + pos) * h
    indice = -np.ones((nx - 1, ny - 1, nz - 1), dtype=np.int64)
    indice[ci, cj, ck] = np.arange(n)
    quads = []
    # Aristas a lo largo de X.
    ii, jj, kk = np.nonzero(dentro[:-1, 1:-1, 1:-1] != dentro[1:, 1:-1, 1:-1])
    jj = jj + 1
    kk = kk + 1
    q = np.stack([indice[ii, jj - 1, kk - 1], indice[ii, jj, kk - 1],
                  indice[ii, jj, kk], indice[ii, jj - 1, kk]], axis=1)
    fuera = ~dentro[ii, jj, kk]
    q[fuera] = q[fuera][:, ::-1]
    quads.append(q)
    # Aristas a lo largo de Y.
    ii, jj, kk = np.nonzero(dentro[1:-1, :-1, 1:-1] != dentro[1:-1, 1:, 1:-1])
    ii = ii + 1
    kk = kk + 1
    q = np.stack([indice[ii - 1, jj, kk - 1], indice[ii - 1, jj, kk],
                  indice[ii, jj, kk], indice[ii, jj, kk - 1]], axis=1)
    fuera = ~dentro[ii, jj, kk]
    q[fuera] = q[fuera][:, ::-1]
    quads.append(q)
    # Aristas a lo largo de Z.
    ii, jj, kk = np.nonzero(dentro[1:-1, 1:-1, :-1] != dentro[1:-1, 1:-1, 1:])
    ii = ii + 1
    jj = jj + 1
    q = np.stack([indice[ii - 1, jj - 1, kk], indice[ii, jj - 1, kk],
                  indice[ii, jj, kk], indice[ii - 1, jj, kk]], axis=1)
    fuera = ~dentro[ii, jj, kk]
    q[fuera] = q[fuera][:, ::-1]
    quads.append(q)
    quads = np.concatenate(quads)
    quads = quads[(quads >= 0).all(axis=1)]
    return verts.astype(F32), quads


def a_blender(v):
    """De Godot (X, Y arriba, Z al frente) a Blender (X, Y al fondo, Z arriba)."""
    return np.stack([v[:, 0], -v[:, 2], v[:, 1]], axis=1)


def de_blender(v):
    return np.stack([v[:, 0], v[:, 2], -v[:, 1]], axis=1)


def decimar(verts, quads, n_tris):
    """Reduce con el modificador de Blender (colapso de aristas)."""
    me = bpy.data.meshes.new("tmp")
    me.from_pydata(a_blender(verts).tolist(), [], quads.tolist())
    me.update()
    ob = bpy.data.objects.new("tmp", me)
    bpy.context.scene.collection.objects.link(ob)
    mod = ob.modifiers.new("reducir", "DECIMATE")
    mod.decimate_type = "COLLAPSE"
    mod.ratio = min(1.0, n_tris / float(len(quads) * 2))
    mod.use_collapse_triangulate = True
    deps = bpy.context.evaluated_depsgraph_get()
    me2 = bpy.data.meshes.new_from_object(ob.evaluated_get(deps))
    v = np.empty(len(me2.vertices) * 3, dtype=np.float32)
    me2.vertices.foreach_get("co", v)
    me2.calc_loop_triangles()
    t = np.empty(len(me2.loop_triangles) * 3, dtype=np.int32)
    me2.loop_triangles.foreach_get("vertices", t)
    bpy.data.objects.remove(ob)
    bpy.data.meshes.remove(me)
    bpy.data.meshes.remove(me2)
    return de_blender(v.reshape(-1, 3)).astype(F32), t.reshape(-1, 3).astype(np.int64)


def gradiente(f, p, e=0.0005):
    g = np.empty_like(p)
    for i in range(3):
        d = np.zeros(3, dtype=F32)
        d[i] = e
        g[:, i] = (f(p + d) - f(p - d)) / (2.0 * e)
    return g


def posar(f, p, pasos=3):
    """Devuelve cada vértice a la superficie del campo (reducir los aparta)."""
    for _ in range(pasos):
        d = f(p)
        g = gradiente(f, p)
        n2 = np.maximum((g * g).sum(axis=1), 1e-6)
        paso = np.clip(d / n2, -0.003, 0.003)
        p = (p - g * paso[:, None]).astype(F32)
    return p


def normales(f, p):
    g = gradiente(f, p)
    return (g / np.maximum(np.linalg.norm(g, axis=1), 1e-9)[:, None]).astype(F32)


def isla(f, lo, hi, h, n_tris, nombre=""):
    """Una pieza cerrada: campo → malla → reducida → posada, con sus normales."""
    campo, origen = campo_en_rejilla(f, lo, hi, h)
    borde = min(campo[0].min(), campo[-1].min(), campo[:, 0].min(), campo[:, -1].min(),
                campo[:, :, 0].min(), campo[:, :, -1].min())
    if borde < 0.0:
        traza("AVISO: la caja de «%s» corta la pieza (campo %.4f en el borde)" % (nombre, borde))
    v, q = redes(campo, origen, h)
    v2, t2 = decimar(v, q, n_tris)
    v2 = posar(f, v2)
    n = normales(f, v2)
    cara = np.cross(v2[t2[:, 1]] - v2[t2[:, 0]], v2[t2[:, 2]] - v2[t2[:, 0]])
    acuerdo = (cara * (n[t2[:, 0]] + n[t2[:, 1]] + n[t2[:, 2]])).sum(axis=1)
    if (acuerdo < 0.0).sum() > (acuerdo > 0.0).sum():
        t2 = t2[:, ::-1].copy()
    traza("  isla %-14s rejilla %s → %d cuadrados → %d triángulos" % (
        nombre, "x".join(str(s) for s in campo.shape), len(q), len(t2)))
    return {"v": v2, "t": t2, "n": n, "diente": np.zeros(len(v2), dtype=F32)}


def juntar(islas):
    v, t, n, d = [], [], [], []
    base = 0
    for i in islas:
        v.append(i["v"])
        n.append(i["n"])
        d.append(i["diente"])
        t.append(i["t"] + base)
        base += len(i["v"])
    return {"v": np.concatenate(v), "t": np.concatenate(t), "n": np.concatenate(n),
            "diente": np.concatenate(d)}


def espejar(pieza):
    """La otra mano: X cambiada de signo y las caras del revés."""
    v = pieza["v"].copy()
    n = pieza["n"].copy()
    v[:, 0] *= -1.0
    n[:, 0] *= -1.0
    otra = dict(pieza)
    otra["v"] = v
    otra["n"] = n
    otra["t"] = pieza["t"][:, ::-1].copy()
    return otra


# ----------------------------------------------------- el color de vértice

def _direcciones(k=24):
    """Semiesfera repartida con el coseno: así todas las direcciones pesan igual."""
    lista = []
    for i in range(k):
        u = (i + 0.5) / k
        r = math.sqrt(u)
        fi = i * 2.399963229728653
        lista.append((r * math.cos(fi), r * math.sin(fi), math.sqrt(1.0 - u)))
    return lista


DIRECCIONES = _direcciones(24)
PASOS_OCLUSION = (0.004, 0.009, 0.016, 0.026, 0.040, 0.060, 0.090)


def oclusion(f_escena, p, n, escala=1.0):
    """Cuánto cielo ve cada vértice: se marcha por el campo en un abanico de
    direcciones y cada una vale lo despejado que esté su cono. 1 = al aire."""
    ref = np.where(np.abs(n[:, 1:2]) < 0.9, np.array([[0.0, 1.0, 0.0]], dtype=F32),
                   np.array([[1.0, 0.0, 0.0]], dtype=F32))
    t = np.cross(ref, n)
    t /= np.maximum(np.linalg.norm(t, axis=1), 1e-9)[:, None]
    b = np.cross(n, t)
    total = np.zeros(len(p), dtype=F32)
    salida = p + n * F32(0.0012 * escala)
    for dx, dy, dz in DIRECCIONES:
        d = (t * F32(dx) + b * F32(dy) + n * F32(dz)).astype(F32)
        ve = np.ones(len(p), dtype=F32)
        for s in PASOS_OCLUSION:
            s2 = s * escala
            ve = np.minimum(ve, np.clip(f_escena(salida + d * F32(s2)) / F32(s2 * 0.42), 0.0, 1.0))
        total += ve
    return total / F32(len(DIRECCIONES))


def laplaciana(f, p, h):
    """Curvatura: positiva en lo que sobresale (un canto), negativa en un hueco."""
    total = -6.0 * f(p)
    for i in range(3):
        d = np.zeros(3, dtype=F32)
        d[i] = h
        total = total + f(p + d) + f(p - d)
    return total / F32(h * h)


def colorear(pieza, f_propio, f_escena, escala=1.0, canto=(35.0, 170.0), tapado=None):
    """R oclusión · G canto · B diente · A 1. `tapado` es una función que dice
    cuánta luz deja pasar cada punto (0 a 1): es la boca, que con la mandíbula
    abierta queda al aire y aun así tiene que ser negra."""
    p = pieza["v"]
    n = pieza["n"]
    oc = oclusion(f_escena, p, n, escala)
    if tapado is not None:
        oc = oc * tapado(p, n)
    lap = laplaciana(f_propio, p, 0.0035 * escala)
    hueco = np.clip((-lap - 25.0 / escala) / (150.0 / escala), 0.0, 1.0)
    r = np.clip(oc, 0.0, 1.0) ** 1.15 * (1.0 - 0.45 * hueco)
    g = np.clip((lap - canto[0] / escala) / ((canto[1] - canto[0]) / escala), 0.0, 1.0)
    # Un filo dentro de un hueco no se desgasta: no le llega nada.
    g = g * np.clip((oc - 0.25) / 0.35, 0.0, 1.0)
    col = np.stack([r, g, pieza["diente"], np.ones(len(p), dtype=F32)], axis=1).astype(F32)
    pieza["col"] = col
    return pieza


# =====================================================================
#  LAS PIEZAS
# =====================================================================

# ----------------------------------------------------------------- el cráneo

def _craneo_liso(p):
    """La bóveda con la cara. Origen en el centro de la bóveda; mira hacia +Z."""
    # La bóveda: ancha, baja y larga. Con más bulto detrás y la frente abombada.
    # Algo achatada por arriba (los parietales no son media esfera: con la bóveda
    # torneada, desde la cámara de juego —que mira desde arriba— era un huevo).
    d = elipsoide(p, (0.0, 0.004, -0.014), (0.122, 0.099, 0.134))
    d = union(d, elipsoide(p, (0.0, -0.020, -0.060), (0.103, 0.080, 0.083)), 0.030)
    d = union(d, elipsoide(p, (0.0, 0.028, 0.060), (0.102, 0.080, 0.064)), 0.035)
    # Los lados, casi rectos: por detrás, una calavera es un pentágono romo —
    # paredes que bajan y los parietales arriba en las esquinas—, no un círculo.
    # (Con el corte a 0,106 y blando 0,03 salía una caja: un gorro de cocinero.)
    d = inter(d, np.abs(p[:, 0]) - F32(0.112), 0.040)
    for s in (-1.0, 1.0):
        # Los abombamientos de los parietales: lo más ancho de una calavera vista
        # desde arriba está DETRÁS de las orejas. Es lo que le da la planta de
        # pentágono romo y no de óvalo.
        # Discretos: más gordos, de frente y agachada era un gorro de cocinero.
        d = union(d, elipsoide(p, (s * 0.066, 0.024, -0.056), (0.050, 0.044, 0.056)), 0.030)
    for s in (-1.0, 1.0):
        # Las sienes: la bóveda se estrecha por delante antes de los pómulos.
        d = resta(d, esfera(p, (s * 0.176, -0.004, 0.080), 0.076), 0.030)
        # La fosa temporal: el hundido que queda DENTRO del arco cigomático. Sin
        # ella el arco va pegado a la pared y desde arriba no se separa nada.
        # (Honda, la oclusión la dejaba negra: una segunda cuenca tras el ojo.)
        d = resta(d, elipsoide(p, (s * 0.134, -0.018, 0.026), (0.028, 0.032, 0.040)), 0.014)
    # El entrecejo y los arcos de las cejas: gruesos. Es la frente que para la bola.
    d = union(d, esfera(p, (0.0, 0.032, 0.116), 0.020), 0.016)
    for s in (-1.0, 1.0):
        d = union(d, capsula(p, (s * 0.016, 0.047, 0.113), (s * 0.086, 0.032, 0.089),
                             0.0150, 0.0125), 0.016)
        # El cerco de la cuenca por fuera: une la ceja con el pómulo.
        d = union(d, capsula(p, (s * 0.091, 0.028, 0.086), (s * 0.094, -0.020, 0.086),
                             0.0105), 0.012)
        # Pómulo y arco cigomático: lo que da la cara ancha del sprite.
        d = union(d, elipsoide(p, (s * 0.080, -0.031, 0.086), (0.038, 0.0205, 0.034)), 0.015)
        # El arco cigomático: un puente de hueso que SALE de lado, del pómulo a la
        # raíz de delante de la oreja, con la fosa temporal por dentro. Desde
        # arriba son las dos asas que hacen que se lea calavera y no pelota.
        # Es una PLACA de canto (más alta que gruesa): redonda, desde abajo era el
        # asa de una taza. Se mide en un espacio estirado en X.
        k_arco = np.array([1.7, 1.0, 1.0], dtype=F32)
        a0 = np.array((s * 0.100, -0.036, 0.068), F32) * k_arco
        a1 = np.array((s * 0.136, -0.034, 0.030), F32) * k_arco
        a2 = np.array((s * 0.106, -0.042, -0.016), F32) * k_arco
        arco = capsula(p * k_arco, a0, a1, 0.0110, 0.0088)
        arco = np.minimum(arco, capsula(p * k_arco, a1, a2, 0.0088, 0.0105))
        d = union(d, arco / F32(1.35), 0.009)
        # La apófisis mastoides: el pezón de detrás de la oreja, hacia abajo.
        d = union(d, elipsoide(p, (s * 0.090, -0.082, -0.036), (0.013, 0.021, 0.013)), 0.012)
        # El oído: el agujerito de detrás del arco.
        d = resta(d, elipsoide(p, (s * 0.106, -0.052, -0.020), (0.012, 0.0085, 0.0085)), 0.004)
    # El maxilar: el hocico corto donde van los dientes de arriba.
    d = union(d, caja(p, (0.0, -0.058, 0.094), (0.060, 0.031, 0.040), 0.022), 0.020)
    for s in (-1.0, 1.0):
        # Hundido bajo el pómulo: la cara se estrecha hacia los dientes.
        d = resta(d, elipsoide(p, (s * 0.094, -0.078, 0.078), (0.034, 0.030, 0.055)), 0.012)
    # EL OCCIPITAL: la nuca de verdad. La línea nucal es una cresta que cruza la
    # nuca de oreja a oreja y se junta en la protuberancia; por debajo, el plano
    # nucal baja metiéndose hacia el agujero. Sin esto, por detrás era un huevo.
    d = resta(d, elipsoide(p, (0.0, -0.120, -0.120), (0.096, 0.052, 0.046)), 0.010)
    d = union(d, elipsoide(p, (0.0, -0.054, -0.142), (0.014, 0.011, 0.012)), 0.010)
    for s in (-1.0, 1.0):
        d = union(d, capsula(p, (0.0, -0.054, -0.144), (s * 0.044, -0.060, -0.132), 0.0078,
                             0.0062), 0.007)
        d = union(d, capsula(p, (s * 0.044, -0.060, -0.132), (s * 0.084, -0.072, -0.098),
                             0.0062, 0.0046), 0.007)
    # Y la cresta de en medio, de la protuberancia al agujero.
    d = union(d, capsula(p, (0.0, -0.062, -0.140), (0.0, -0.094, -0.094), 0.0040, 0.0030),
              0.005)
    # La base: casi plana, que es lo que enseña boca arriba.
    d = inter(d, -(p[:, 1] + F32(0.104)), 0.010)
    # Las cuencas: grandes, hondas y caídas por fuera, como en el sprite.
    for s in (-1.0, 1.0):
        d = resta(d, elipsoide(p, (s * 0.050, 0.003, 0.126), (0.0395, 0.0345, 0.064),
                               rot_z(-s * 0.20)), 0.007)
    # La nariz: un corazón del revés (dos lóbulos que se juntan arriba).
    nariz = np.minimum(
        elipsoide(p, (0.0095, -0.043, 0.130), (0.0115, 0.0200, 0.040), rot_z(0.36)),
        elipsoide(p, (-0.0095, -0.043, 0.130), (0.0115, 0.0200, 0.040), rot_z(-0.36)))
    d = resta(d, nariz, 0.004)
    # El paladar: una bóveda POCO honda dentro del arco de los dientes. Hondo, boca
    # arriba se veía el hueco entero y los dientes de arriba flotando dentro.
    d = resta(d, elipsoide(p, (0.0, -0.104, 0.062), (0.033, 0.017, 0.042)), 0.008)
    # El agujero occipital: de aquí sale el espinazo. A cada lado, los cóndilos.
    d = resta(d, elipsoide(p, AGUJERO, (0.0165, 0.030, 0.0215)), 0.004)
    for s in (-1.0, 1.0):
        d = union(d, elipsoide(p, (s * 0.0225, -0.102, AGUJERO[2] + 0.010),
                               (0.0075, 0.0060, 0.0130), rot_y(s * 0.35)), 0.005)
    # EL HOMBRO ESCONDIDO: un muñón de omóplato que cuelga de debajo de la bóveda,
    # tras la mastoides, con la cavidad donde encaja el húmero, y la clavícula
    # que se mete hacia delante por debajo. Desde arriba no se ve; de lado, el
    # brazo nace de ahí y no de la mejilla.
    for s in (-1.0, 1.0):
        hombro = (s * HOMBRO[0], HOMBRO[1], HOMBRO[2])
        d = union(d, capsula(p, (s * 0.078, -0.094, -0.050), hombro, 0.0105, 0.0080), 0.008)
        d = union(d, elipsoide(p, hombro, (0.0125, 0.0105, 0.0135)), 0.006)
        d = union(d, capsula(p, hombro, (s * 0.050, -0.125, -0.022), 0.0058, 0.0046), 0.005)
    # Relieve: el hueso no es una bola torneada.
    d = d + F32(0.0034) * (ruido(p * F32(9.0), 3) - 0.5) \
        + F32(0.0016) * (fbm(p * F32(30.0), 3, 11) - 0.5)
    return d.astype(F32)


def _en_la_superficie(f, origen, direccion):
    """El punto (y la normal) donde un rayo que sale de dentro cruza la superficie."""
    o = np.asarray(origen, np.float64)
    d = np.asarray(direccion, np.float64)
    d = d / np.linalg.norm(d)
    t = 0.0
    paso = 0.001
    for _ in range(400):
        v = float(f((o + d * t)[None, :].astype(F32))[0])
        if v > 0.0:
            break
        paso = max(-v * 0.6, 0.0006)
        t += paso
    a, b = t - paso, t
    for _ in range(24):
        m = 0.5 * (a + b)
        if float(f((o + d * m)[None, :].astype(F32))[0]) > 0.0:
            b = m
        else:
            a = m
    punto = (o + d * b).astype(F32)
    return punto, normales(f, punto[None, :])[0]


# Los DESCONCHONES: las lascas que le han saltado las bolas que ya ha parado.
# Casi todas en la frente, que es por donde las para. Cada una es el corte de
# una esfera GRANDE que apenas roza la bóveda: sale una faceta casi plana con el
# filo vivo, que es como salta el hueso. (Con esferas pequeñas salían agujeros
# redondos y negros: parecía carcoma.) (dirección desde el centro, radio, hondo)
_MELLAS = [
    ((0.30, 0.46, 1.00), 0.062, 0.0046),
    ((-0.50, 0.70, 1.00), 0.050, 0.0024),
    ((0.10, 1.00, 0.62), 0.055, 0.0022),
    ((-0.42, 1.00, -0.30), 0.075, 0.0030),
    ((0.62, 0.42, -1.00), 0.080, 0.0034),
]
DESCONCHONES = []
for _dir, _r, _hondo in _MELLAS:
    _pt, _nm = _en_la_superficie(_craneo_liso, (0.0, 0.010, 0.0), _dir)
    DESCONCHONES.append((tuple(float(x) for x in (_pt + _nm * (_r - _hondo))), _r))


def craneo_hueso(p):
    d = _craneo_liso(p)
    for centro, r in DESCONCHONES:
        d = resta(d, esfera(p, centro, r), 0.0016)
    return d.astype(F32)


CENTRO_BOCA = np.array([0.0, -0.105, 0.060], dtype=F32)


def _hacia_la_boca(p, n):
    """1 donde la superficie mira hacia dentro de la boca, 0 donde mira afuera:
    lo que se tapa es el INTERIOR, no el mentón ni la cara de fuera de un diente."""
    v = CENTRO_BOCA - p
    v = v / np.maximum(np.linalg.norm(v, axis=1), 1e-6)[:, None]
    return np.clip(((n * v).sum(axis=1) + 0.10) / 0.40, 0.0, 1.0)


def boca_craneo(p, n):
    """Cuánta luz llega: 1 fuera, casi nada en el techo de la boca."""
    d = elipsoide(p, (0.0, -0.100, 0.060), (0.052, 0.048, 0.064))
    dentro = np.clip(0.5 - d / 0.010, 0.0, 1.0) * _hacia_la_boca(p, n)
    return (1.0 - 0.94 * dentro).astype(F32)


# Los dientes: pocos y gordos. (ángulo en el arco, ancho, alto, fondo, punta, inclinación)
DIENTES_ARRIBA = [
    (-62.0, 0.0190, 0.026, 0.0150, -0.1040, 0.05),
    (-37.0, 0.0185, 0.032, 0.0150, -0.1120, -0.04),
    (-12.0, 0.0215, 0.030, 0.0140, -0.1095, 0.03),
    (12.0, 0.0215, 0.031, 0.0140, -0.1105, -0.05),
    (37.0, 0.0185, 0.032, 0.0150, -0.1115, 0.06),
    (62.0, 0.0190, 0.026, 0.0150, -0.1035, -0.03),
]
ARCO_ARRIBA = (0.0500, 0.0580, 0.066)   # radio en X, radio en Z, centro en Z

DIENTES_ABAJO = [
    (-62.0, 0.0180, 0.024, 0.0140, -0.1100, -0.04),
    (-37.0, 0.0175, 0.028, 0.0140, -0.1065, 0.07),
    (-12.0, 0.0190, 0.027, 0.0130, -0.1075, -0.03),
    (12.0, 0.0190, 0.027, 0.0130, -0.1070, 0.04),
    (37.0, 0.0175, 0.019, 0.0140, -0.1150, -0.10),   # el colmillo roto
    (62.0, 0.0180, 0.024, 0.0140, -0.1105, 0.05),
]
ARCO_ABAJO = (0.0445, 0.0515, 0.066)


def _diente(spec, arco, hacia_arriba):
    """Devuelve (campo, caja_lo, caja_hi) de un diente, en coordenadas del cráneo."""
    ang, ancho, alto, fondo, punta, inclina = spec
    fi = math.radians(ang)
    cx = arco[0] * math.sin(fi)
    cz = arco[2] + arco[1] * math.cos(fi)
    # La corona acaba en `punta`; la raíz se hunde en el hueso.
    cy = punta + alto * 0.5 if not hacia_arriba else punta - alto * 0.5
    giro = rot_y(fi) @ rot_z(inclina)
    centro = (cx, cy, cz)
    medio = (ancho * 0.5, alto * 0.5, fondo * 0.5)
    radio = min(ancho, fondo) * 0.36

    def campo(p, centro=centro, medio=medio, radio=radio, giro=giro):
        d = caja(p, centro, medio, radio, giro)
        return (d + F32(0.0007) * (ruido(p * F32(120.0), 5) - 0.5)).astype(F32)

    m = max(ancho, fondo) * 0.5 + 0.006
    lo = (cx - m, cy - alto * 0.5 - 0.006, cz - m)
    hi = (cx + m, cy + alto * 0.5 + 0.006, cz + m)
    return campo, lo, hi


def _fila_dientes(specs, arco, hacia_arriba):
    campos = []
    cajas = []
    for spec in specs:
        campo, lo, hi = _diente(spec, arco, hacia_arriba)
        campos.append(campo)
        cajas.append((lo, hi))

    def todos(p):
        d = campos[0](p)
        for c in campos[1:]:
            d = np.minimum(d, c(p))
        return d

    return campos, cajas, todos


CAMPOS_ARRIBA, CAJAS_ARRIBA, dientes_arriba = _fila_dientes(DIENTES_ARRIBA, ARCO_ARRIBA, False)
CAMPOS_ABAJO, CAJAS_ABAJO, dientes_abajo_craneo = _fila_dientes(DIENTES_ABAJO, ARCO_ABAJO, True)


# --------------------------------------------------------------- la mandíbula

def mandibula_hueso_craneo(p):
    """La mandíbula CERRADA, en coordenadas del cráneo. Es una cuchara: herradura
    por delante, ramas hasta la bisagra, y suelo y pared detrás para que la boca
    abierta sea NEGRA desde cualquier cámara (en el sprite lo es)."""
    y = p[:, 1]
    yc = -0.141
    # La herradura: una cadena de cápsulas, con la sección más alta que gruesa
    # (se aplasta Y antes de medir).
    q = p.copy()
    q[:, 1] = (q[:, 1] - F32(yc)) * F32(0.62) + F32(yc)
    d = None
    n = 10
    for i in range(n):
        f0 = math.radians(-98.0 + 196.0 * i / n)
        f1 = math.radians(-98.0 + 196.0 * (i + 1) / n)
        a = (0.047 * math.sin(f0), yc, 0.066 + 0.054 * math.cos(f0))
        b = (0.047 * math.sin(f1), yc, 0.066 + 0.054 * math.cos(f1))
        c = capsula(q, a, b, 0.0118)
        d = c if d is None else np.minimum(d, c)
    # El mentón.
    d = union(d, elipsoide(p, (0.0, -0.151, 0.119), (0.025, 0.014, 0.013)), 0.010)
    # El cuenco: suelo y pared de atrás.
    d = union(d, elipsoide(p, (0.0, -0.128, 0.064), (0.051, 0.036, 0.057)), 0.006)
    # Enrasada por arriba, en la línea de los dientes.
    d = inter(d, y - F32(-0.1225), 0.004)
    # Las ramas, hasta los cóndilos de la bisagra. Son PLACAS, no barrotes: finas
    # de lado y anchas de canto (se mide en un espacio aplastado en X y estirado
    # en Z). Redondas, desde atrás eran dos palos y la pared un marco.
    plano = np.array([1.45, 1.0, 0.72], dtype=F32)
    for s in (-1.0, 1.0):
        a = np.array((s * 0.050, -0.143, 0.044), F32) * plano
        b = np.array((s * 0.074, -0.087, -0.004), F32) * plano
        rama = capsula(p * plano, a, b, 0.0118, 0.0088) * F32(0.80)
        d = union(d, rama, 0.010)
        # El ángulo de la mandíbula: el codo de atrás y abajo, donde la rama dobla.
        d = union(d, elipsoide(p, (s * 0.057, -0.141, 0.030), (0.010, 0.012, 0.016)), 0.010)
        d = union(d, esfera(p, (s * 0.074, BISAGRA[1], BISAGRA[2]), 0.0125), 0.006)
    # La pared del fondo: entre las dos ramas, hasta la altura de la bisagra. Sin
    # ella, con la boca abierta se veía por el fondo lo que hubiera detrás —el
    # suelo, la cola—, y la boca del sprite es NEGRA. Sube hasta el eje a
    # propósito: lo que está junto al eje no se mueve al abrir, así que la pared
    # tapa igual con la boca cerrada que desencajada.
    # Es la mitad de atrás de una CÁSCARA de elipsoide: desde detrás se ve una
    # garganta abombada que se funde con las ramas. (Hecha de barras en escalera
    # era una tabla plana con su marco: una caja bajo la nuca.)
    # MACIZA, no cáscara: rodando, la cáscara enseñaba su hueco por debajo y la
    # mandíbula era una taza. Lo que la vacía por delante es la resta de abajo.
    centro_g = (0.0, -0.118, 0.034)
    garganta = elipsoide(p, centro_g, (0.066, 0.050, 0.046))
    garganta = inter(garganta, p[:, 2] - F32(centro_g[2] + 0.004), 0.006)
    garganta = inter(garganta, p[:, 1] - F32(-0.082), 0.006)
    d = union(d, garganta, 0.010)
    # Vaciada por dentro.
    d = resta(d, elipsoide(p, (0.0, -0.116, 0.066), (0.037, 0.036, 0.046)), 0.006)
    d = d + F32(0.0022) * (ruido(p * F32(12.0), 23) - 0.5) \
        + F32(0.0012) * (fbm(p * F32(34.0), 3, 29) - 0.5)
    return d.astype(F32)


_H = np.asarray(BISAGRA, F32)
_GIRO_BOCA = rot_x(BOCA_REPOSO)


def mandibula_hueso(q):
    """En su sitio: origen en la bisagra."""
    return mandibula_hueso_craneo(q + _H)


def dientes_abajo(q):
    return dientes_abajo_craneo(q + _H)


def craneo_total(p):
    return np.minimum(craneo_hueso(p), dientes_arriba(p))


def mandibula_total(q):
    return np.minimum(mandibula_hueso(q), dientes_abajo(q))


def escena_craneo(p):
    """Lo que hace sombra al cráneo: él mismo y la mandíbula abierta como en reposo."""
    q = (p - _H) @ _GIRO_BOCA
    return np.minimum(craneo_total(p), mandibula_total(q))


def escena_mandibula(q):
    p = q @ _GIRO_BOCA.T + _H
    return np.minimum(mandibula_total(q), craneo_total(p))


def boca_mandibula(q, n):
    """Lo mismo, para el cuenco de la mandíbula y su pared del fondo."""
    p = q + _H
    d = elipsoide(p, (0.0, -0.112, 0.050), (0.050, 0.055, 0.066))
    dentro = np.clip(0.5 - d / 0.010, 0.0, 1.0) * _hacia_la_boca(p, n)
    return (1.0 - 0.94 * dentro).astype(F32)


# ------------------------------------------------------------------ los brazos

GORDO = np.array([1.0 / 1.14, 1.0, 1.0 / 1.14], dtype=F32)


def humero(p):
    """Origen en el hombro; el codo queda en (0, L1, 0) y su bisagra es el eje X."""
    p = p * GORDO
    d = esfera(p, (0.0, 0.002, 0.0), 0.0210)
    medio = (0.0026, L1 * 0.55, 0.0040)
    d = union(d, capsula(p, (0.0, 0.012, 0.0), medio, 0.0128, 0.0104), 0.009)
    d = union(d, capsula(p, medio, (0.0, L1 - 0.008, 0.0), 0.0104, 0.0128), 0.007)
    for s in (-1.0, 1.0):
        d = union(d, esfera(p, (s * 0.0128, L1 - 0.002, 0.0), 0.0138), 0.007)
    d = d + F32(0.0012) * (fbm(p * F32(60.0), 2, 41) - 0.5)
    return d.astype(F32)


def antebrazo(p):
    """Origen en el codo; la muñeca en (0, L2, 0). Cúbito y radio: DOS huesos que
    se cruzan. El cúbito va recto, con el olécranon (el pico del codo) detrás; el
    radio nace fuera, con su cabeza redonda, y cruza por delante del cúbito para
    acabar dentro, donde se ensancha en la muñeca. Cada uno es fino por en medio
    y gordo en las puntas (las epífisis). (Fueron dos cilindros paralelos con una
    raja entre ellos: en el golpe y boca arriba se leían como un tubo rajado.)"""
    p = p * GORDO
    # El cúbito, con el olécranon.
    cub_a = (-0.0088, 0.006, -0.0030)
    cub_b = (-0.0070, L2 - 0.010, -0.0015)
    cub_m = (-0.0085, L2 * 0.5, -0.0026)
    cubito = capsula(p, cub_a, cub_m, 0.0080, 0.0052)
    cubito = union(cubito, capsula(p, cub_m, cub_b, 0.0052, 0.0062), 0.004)
    cubito = union(cubito, elipsoide(p, (-0.0080, 0.000, -0.0085), (0.0090, 0.0105, 0.0085)),
                   0.006)
    cubito = union(cubito, esfera(p, (-0.0074, L2 - 0.006, -0.0020), 0.0074), 0.004)
    # El radio, que cruza: fuera y detrás en el codo, dentro y delante en la muñeca.
    rad_a = (0.0105, 0.010, 0.0010)
    rad_b = (-0.0010, L2 - 0.010, 0.0062)
    rad_m = (0.0060, L2 * 0.5, 0.0045)
    radio = capsula(p, rad_a, rad_m, 0.0058, 0.0050)
    radio = union(radio, capsula(p, rad_m, rad_b, 0.0050, 0.0072), 0.004)
    radio = union(radio, elipsoide(p, (0.0105, 0.006, 0.0010), (0.0080, 0.0050, 0.0080)), 0.003)
    radio = union(radio, elipsoide(p, (0.0010, L2 - 0.005, 0.0050), (0.0125, 0.0070, 0.0090)),
                  0.004)
    d = union(cubito, radio, 0.0022)
    # El codo: la tróclea donde encaja el húmero.
    d = union(d, elipsoide(p, (0.0, 0.003, -0.0030), (0.0150, 0.0085, 0.0100)), 0.005)
    d = d + F32(0.0010) * (fbm(p * F32(60.0), 2, 47) - 0.5)
    return d.astype(F32)


# -------------------------------------------------------------------- las manos
# La mano IZQUIERDA (la de +X). Origen en la muñeca, dedos hacia +Z. Pisa de
# puntillas: la muñeca queda a H_MUNECA del suelo y las yemas llegan abajo.
#
# `fuentes/mano_ia.glb` se miró (21-nov-2026) y no se usa: es una mano ABIERTA y
# PLANA, de una pieza, con cinco dedos largos y finos de mano de verdad. Esta
# anda: pisa con los dedos doblados en garra, y cada dedo es una pieza que se
# cierra, patalea y tamborilea por su cuenta. Para eso habría que trocear la de
# IA por los nudillos y doblarla, y aun así sus dedos, desde la cámara de juego,
# no llegan a un píxel de grueso; los del sprite son tres o cuatro morcillas.

NUDILLOS = [  # (x, y, z del nudillo, giro hacia fuera en grados, talla del dedo)
    (0.0215, 0.0010, 0.0345, 23.0, 0.95),
    (0.0005, 0.0025, 0.0400, 2.0, 1.06),
    (-0.0205, 0.0010, 0.0350, -20.0, 0.93),
]
PULGAR = (-0.0275, -0.0030, 0.0120, -60.0, 1.0)   # por dentro, hacia el cuerpo


def _palma0(p):
    d = elipsoide(p, (0.0, -0.0020, 0.0165), (0.0290, 0.0135, 0.0225))
    for x, y, z, _g, _t in NUDILLOS:
        d = union(d, esfera(p, (x, y - 0.0005, z - 0.0030), 0.0108), 0.007)
    d = union(d, esfera(p, (PULGAR[0] + 0.004, PULGAR[1], PULGAR[2]), 0.0104), 0.006)
    d = d + F32(0.0010) * (fbm(p * F32(70.0), 2, 53) - 0.5)
    return d.astype(F32)


def _dedo_puntos(talla):
    return ((0.0, 0.0, 0.0), (0.0, 0.0110 * talla, 0.0235 * talla),
            (0.0, 0.0025 * talla, 0.0430 * talla), (0.0, -0.0200, 0.0515 * talla))


def _dedo0(p, talla=1.0, semilla=0):
    """Origen en el nudillo, hacia +Z. Tres falanges ya dobladas: sube, baja y pisa."""
    a, b, c, e = _dedo_puntos(talla)
    d = capsula(p, a, b, 0.0082, 0.0074)
    d = union(d, esfera(p, a, 0.0110), 0.004)
    d = union(d, esfera(p, b, 0.0104), 0.004)
    d = union(d, capsula(p, b, c, 0.0074, 0.0068), 0.004)
    d = union(d, esfera(p, c, 0.0096), 0.004)
    d = union(d, capsula(p, c, e, 0.0068, 0.0062), 0.004)
    d = union(d, esfera(p, e, 0.0076), 0.003)
    d = d + F32(0.0008) * (fbm(p * F32(90.0), 2, 61 + semilla) - 0.5)
    return d.astype(F32)


def _pulgar0(p):
    a = (0.0, 0.0, 0.0)
    b = (0.0, 0.0050, 0.0225)
    c = (0.0, -0.0160, 0.0340)
    d = capsula(p, a, b, 0.0086, 0.0078)
    d = union(d, esfera(p, a, 0.0112), 0.004)
    d = union(d, esfera(p, b, 0.0106), 0.004)
    d = union(d, capsula(p, b, c, 0.0076, 0.0066), 0.004)
    d = union(d, esfera(p, c, 0.0080), 0.003)
    d = d + F32(0.0008) * (fbm(p * F32(90.0), 2, 71) - 0.5)
    return d.astype(F32)


def _giro_dedo(grados):
    return rot_y(math.radians(grados))


def _escena_mano0(p):
    d = _palma0(p)
    for i, (x, y, z, g, t) in enumerate(NUDILLOS):
        q = (p - np.asarray((x, y, z), F32)) @ _giro_dedo(g)
        d = np.minimum(d, _dedo0(q, t, i))
    q = (p - np.asarray(PULGAR[:3], F32)) @ _giro_dedo(PULGAR[3])
    d = np.minimum(d, _pulgar0(q))
    return d


# Las mismas, a su talla de verdad (KM).
def palma(p):
    return F32(KM) * _palma0(p / F32(KM))


def dedo(p, talla=1.0, semilla=0):
    return F32(KM) * _dedo0(p / F32(KM), talla, semilla)


def pulgar(p):
    return F32(KM) * _pulgar0(p / F32(KM))


def escena_mano(p):
    """La mano entera, para la oclusión de cada pieza. SIN el suelo: horneado,
    la palma y las yemas salían negras, y cuando patalea boca arriba es justo lo
    que enseña —una mano con guante negro—. La sombra del suelo ya la da la luz."""
    return F32(KM) * _escena_mano0(p / F32(KM))


# --------------------------------------------------------------- el huesecillo

def huesecillo(p):
    d = capsula(p, (0.0, -0.013, 0.0), (0.0, 0.013, 0.0), 0.0034)
    for sy in (-1.0, 1.0):
        for sx in (-1.0, 1.0):
            d = union(d, esfera(p, (sx * 0.0042, sy * 0.0150, 0.0), 0.0054), 0.003)
    return d.astype(F32)


# -------------------------------------------------------------------- la cola

def vertebra(p, semilla=0):
    """Una vértebra. Origen en el centro del cuerpo; la columna corre por Z (hacia
    +Z queda el cráneo) y la apófisis espinosa sube por +Y. Desde arriba, que es
    desde donde mira la cámara, es una crucecita: el cuerpo, las dos alas y la
    espina. Cuatro en fila se leen como espinazo sin tener que mirarlas de cerca."""
    # El cuerpo: un carrete, más largo que el paso de la cola, con los platillos
    # de las puntas algo más anchos (donde iba el disco).
    d = capsula(p, (0.0, 0.0, -0.0045), (0.0, 0.0, 0.0045), 0.0090)
    for s in (-1.0, 1.0):
        d = union(d, elipsoide(p, (0.0, 0.0, s * 0.0102), (0.0106, 0.0096, 0.0030)), 0.003)
    # El arco de encima, con el canal de la médula.
    d = union(d, elipsoide(p, (0.0, 0.0115, -0.0005), (0.0088, 0.0072, 0.0108)), 0.004)
    d = resta(d, capsula(p, (0.0, 0.0108, -0.020), (0.0, 0.0108, 0.020), 0.0034), 0.002)
    # La apófisis espinosa, hacia arriba y atrás: corta y gorda. (Larga y fina,
    # las cinco en fila eran las púas de un peine.)
    d = union(d, capsula(p, (0.0, 0.0165, -0.0015), (0.0, 0.0255, -0.0095), 0.0054, 0.0042),
              0.005)
    for s in (-1.0, 1.0):
        # Las alas (apófisis transversas): cortas y romas.
        d = union(d, capsula(p, (s * 0.0085, 0.0080, 0.0005), (s * 0.0180, 0.0098, -0.0030),
                             0.0046, 0.0038), 0.005)
        # Las articulares: dos pivotes hacia delante y dos hacia atrás, que montan
        # sobre los de la vecina. Son lo que hace de cinco huesos UNA cola.
        d = union(d, capsula(p, (s * 0.0058, 0.0140, 0.004), (s * 0.0062, 0.0146, 0.0150),
                             0.0036, 0.0032), 0.004)
        d = union(d, capsula(p, (s * 0.0058, 0.0130, -0.004), (s * 0.0052, 0.0120, -0.0145),
                             0.0036, 0.0032), 0.004)
    d = d + F32(0.0007) * (fbm(p * F32(110.0), 2, 83 + semilla) - 0.5)
    return d.astype(F32)


# =====================================================================
#  A BLENDER
# =====================================================================

CAMBIO = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


def matriz(base=None, origen=(0.0, 0.0, 0.0)):
    """Una transformación escrita en Godot (base 3×3 y origen), ya en Blender."""
    m = Matrix.Identity(4)
    if base is not None:
        for i in range(3):
            for j in range(3):
                m[i][j] = float(base[i][j])
    for i in range(3):
        m[i][3] = float(origen[i])
    return CAMBIO @ m @ CAMBIO.inverted()


def nuevo_material():
    """El material del GLB es solo para verlo suelto: en Godot manda el shader de
    `cripta3d/criaturas/calavera_hueso.gdshader`, que lee el color de vértice."""
    mat = bpy.data.materials.new("hueso")
    mat.diffuse_color = (0.55, 0.42, 0.26, 1.0)
    arbol = mat.node_tree
    if arbol is not None:
        bsdf = next((n for n in arbol.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if bsdf is None:
            bsdf = arbol.nodes.new("ShaderNodeBsdfPrincipled")
            salida = next((n for n in arbol.nodes if n.type == "OUTPUT_MATERIAL"), None)
            if salida is None:
                salida = arbol.nodes.new("ShaderNodeOutputMaterial")
            arbol.links.new(bsdf.outputs["BSDF"], salida.inputs["Surface"])
        bsdf.inputs["Base Color"].default_value = (0.55, 0.42, 0.26, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.85
    return mat


def crear(nombre, pieza, material, mat=None, padre=None):
    me = bpy.data.meshes.new(nombre)
    me.from_pydata(a_blender(pieza["v"]).tolist(), [], pieza["t"].tolist())
    me.polygons.foreach_set("use_smooth", [True] * len(me.polygons))
    me.update()
    capa = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    capa.data.foreach_set("color", pieza["col"].astype(np.float32).ravel())
    me.color_attributes.active_color = capa
    try:
        me.color_attributes.render_color_index = 0
    except Exception:
        pass
    me.normals_split_custom_set_from_vertices(a_blender(pieza["n"]).tolist())
    me.materials.append(material)
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(ob)
    if padre is not None:
        ob.parent = padre
    ob.matrix_basis = mat if mat is not None else Matrix.Identity(4)
    return ob


def vacio(nombre, origen, padre=None):
    ob = bpy.data.objects.new(nombre, None)
    ob.empty_display_size = 0.01
    bpy.context.scene.collection.objects.link(ob)
    if padre is not None:
        ob.parent = padre
    ob.matrix_basis = matriz(None, origen)
    return ob


def base_hueso(a, b, eje):
    """Base (columnas X, Y, Z) de un hueso que va de `a` a `b` con la bisagra en `eje`."""
    y = np.asarray(b, np.float64) - np.asarray(a, np.float64)
    y /= np.linalg.norm(y)
    x = np.asarray(eje, np.float64)
    x = x - y * (x @ y)
    x /= np.linalg.norm(x)
    z = np.cross(x, y)
    return np.stack([x, y, z], axis=1)


def construir():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    material = nuevo_material()
    h_fino = 1.6 if BORRADOR else 1.0

    # --- el cráneo -------------------------------------------------------------
    traza("cráneo")
    islas = [isla(craneo_hueso, (-0.150, -0.140, -0.166), (0.150, 0.126, 0.152),
                  0.0025 * h_fino, TRIS["craneo"], "bóveda")]
    for campo, (lo, hi) in zip(CAMPOS_ARRIBA, CAJAS_ARRIBA):
        d = isla(campo, lo, hi, 0.0011 * h_fino, TRIS["diente"], "diente")
        d["diente"][:] = 1.0
        islas.append(d)
    craneo = colorear(juntar(islas), craneo_total, escena_craneo, tapado=boca_craneo)

    # --- la mandíbula ----------------------------------------------------------
    traza("mandíbula")
    lo = (-0.100 - BISAGRA[0], -0.180 - BISAGRA[1], -0.036 - BISAGRA[2])
    hi = (0.100 - BISAGRA[0], -0.060 - BISAGRA[1], 0.146 - BISAGRA[2])
    islas = [isla(mandibula_hueso, lo, hi, 0.0020 * h_fino, TRIS["mandibula"], "mandíbula")]
    for campo, (lo, hi) in zip(CAMPOS_ABAJO, CAJAS_ABAJO):
        lo2 = tuple(lo[i] - BISAGRA[i] for i in range(3))
        hi2 = tuple(hi[i] - BISAGRA[i] for i in range(3))
        d = isla(lambda q, campo=campo: campo(q + _H), lo2, hi2, 0.0011 * h_fino,
                 TRIS["diente"], "diente")
        d["diente"][:] = 1.0
        islas.append(d)
    mandibula = colorear(juntar(islas), mandibula_total, escena_mandibula,
                         tapado=boca_mandibula)

    # --- los brazos ------------------------------------------------------------
    traza("brazos")
    p_humero = isla(humero, (-0.040, -0.028, -0.036), (0.040, L1 + 0.022, 0.036),
                    0.0012 * h_fino, TRIS["humero"], "húmero")
    p_humero = colorear(p_humero, humero, humero, 0.5, (60.0, 260.0))
    p_ante = isla(antebrazo, (-0.036, -0.021, -0.030), (0.036, L2 + 0.018, 0.030),
                  0.0010 * h_fino, TRIS["antebrazo"], "antebrazo")
    p_ante = colorear(p_ante, antebrazo, antebrazo, 0.5, (60.0, 260.0))

    # --- las manos -------------------------------------------------------------
    traza("manos")
    p_palma = isla(palma, (-0.048 * KM, -0.024 * KM, -0.014 * KM),
                   (0.040 * KM, 0.022 * KM, 0.056 * KM),
                   0.0010 * h_fino, TRIS["palma"], "palma")
    p_palma = colorear(p_palma, palma, escena_mano, 0.45, (70.0, 300.0))
    p_dedos = []
    for i, (x, y, z, g, t) in enumerate(NUDILLOS):
        giro = _giro_dedo(g)
        origen = np.asarray((x, y, z), F32) * F32(KM)

        def campo(q, t=t, i=i):
            return dedo(q, t, i)

        def escena(q, giro=giro, origen=origen):
            return escena_mano(q @ giro.T + origen)

        d = isla(campo, (-0.018 * KM, -0.034 * KM, -0.018 * KM),
                 (0.018 * KM, 0.030 * KM, 0.070 * KM),
                 0.0009 * h_fino, TRIS["dedo"], "dedo %d" % i)
        p_dedos.append((colorear(d, campo, escena, 0.4, (90.0, 340.0)), giro, origen))
    giro_p = _giro_dedo(PULGAR[3])
    origen_p = np.asarray(PULGAR[:3], F32) * F32(KM)
    d = isla(pulgar, (-0.018 * KM, -0.032 * KM, -0.018 * KM),
             (0.018 * KM, 0.024 * KM, 0.050 * KM),
             0.0009 * h_fino, TRIS["pulgar"], "pulgar")
    p_pulgar = colorear(d, pulgar, lambda q: escena_mano(q @ giro_p.T + origen_p), 0.4,
                        (90.0, 340.0))

    # --- el huesecillo ---------------------------------------------------------
    p_hueso = isla(huesecillo, (-0.014, -0.026, -0.010), (0.014, 0.026, 0.010),
                   0.0008 * h_fino, TRIS["huesecillo"], "huesecillo")
    p_hueso = colorear(p_hueso, huesecillo, huesecillo, 0.35, (120.0, 420.0))

    # --- la cola ---------------------------------------------------------------
    traza("cola")
    p_vertebras = []
    for i, k in enumerate(COLA_TALLAS):
        k = k * KV

        def campo(q, k=k, i=i):
            return F32(k) * vertebra(q / F32(k), i)

        d = isla(campo, (-0.031 * k, -0.016 * k, -0.026 * k), (0.031 * k, 0.040 * k, 0.026 * k),
                 0.0007 * h_fino * k, TRIS["vertebra"], "vértebra %d" % i)
        p_vertebras.append(colorear(d, campo, campo, 0.4 * k, (90.0, 340.0)))

    # =================== montaje, en la pose de reposo ===========================
    traza("montaje")
    base_craneo = rot_x(CABECEO_REPOSO)
    centro = np.array([0.0, ALTO_REPOSO, 0.0])
    ob_craneo = crear("craneo", craneo, material, matriz(base_craneo, centro))
    ob_mandibula = crear("mandibula", mandibula, material,
                         matriz(rot_x(BOCA_REPOSO), BISAGRA), ob_craneo)
    vacio("menton", tuple(MENTON[i] - BISAGRA[i] for i in range(3)), ob_mandibula)
    total = len(craneo["t"]) + len(mandibula["t"]) + len(p_hueso["t"])
    for lado, s in (("i", 1.0), ("d", -1.0)):
        vacio("ojo_" + lado, (s * OJO[0], OJO[1], OJO[2]), ob_craneo)
        vacio("hombro_" + lado, (s * HOMBRO[0], HOMBRO[1], HOMBRO[2]), ob_craneo)
        # El brazo, resuelto como lo resolverá Godot: dos tramos y el codo arriba y afuera.
        hombro = centro + base_craneo.astype(np.float64) @ np.array(
            [s * HOMBRO[0], HOMBRO[1], HOMBRO[2]])
        muneca = np.array([s * MANO_REPOSO[0], H_MUNECA, MANO_REPOSO[1]])
        v = muneca - hombro
        dist = min(np.linalg.norm(v), L1 + L2 - 0.002)
        u = v / np.linalg.norm(v)
        a = (L1 * L1 - L2 * L2 + dist * dist) / (2.0 * dist)
        alto = math.sqrt(max(L1 * L1 - a * a, 0.0))
        doblar = np.array([s * 0.55, 1.0, -0.35])
        doblar = doblar - u * (doblar @ u)
        doblar /= np.linalg.norm(doblar)
        codo = hombro + u * a + doblar * alto
        eje = np.cross(codo - hombro, muneca - codo)
        eje = eje / np.linalg.norm(eje) * s
        pieza_h = p_humero if s > 0 else espejar(p_humero)
        pieza_a = p_ante if s > 0 else espejar(p_ante)
        ob_h = crear("humero_" + lado, pieza_h, material,
                     matriz(base_hueso(hombro, codo, eje), hombro))
        vacio("codo_" + lado, (0.0, L1, 0.0), ob_h)
        ob_a = crear("antebrazo_" + lado, pieza_a, material,
                     matriz(base_hueso(codo, muneca, eje), codo))
        vacio("muneca_" + lado, (0.0, L2, 0.0), ob_a)
        # La mano: apoyada, con los dedos hacia delante y algo hacia fuera.
        ob_m = crear("mano_" + lado, p_palma if s > 0 else espejar(p_palma), material,
                     matriz(rot_y(s * math.radians(24.0)), muneca))
        vacio("apoyo_" + lado, (0.0, -H_MUNECA, 0.0), ob_m)
        total += len(p_humero["t"]) + len(p_ante["t"]) + len(p_palma["t"])
        for i, (pieza, giro, origen) in enumerate(p_dedos):
            g = giro if s > 0 else giro.T
            o = origen * np.array([s, 1.0, 1.0], dtype=F32)
            crear("dedo_%s_%d" % (lado, i), pieza if s > 0 else espejar(pieza), material,
                  matriz(g, o), ob_m)
            total += len(pieza["t"])
        g = giro_p if s > 0 else giro_p.T
        o = origen_p * np.array([s, 1.0, 1.0], dtype=F32)
        crear("pulgar_" + lado, p_pulgar if s > 0 else espejar(p_pulgar), material,
              matriz(g, o), ob_m)
        total += len(p_pulgar["t"])
    # La cola, colgando de la nuca hasta el suelo y arrastrada hacia atrás.
    # La cola nace en el agujero occipital y sale por su canal; `nuca_canal` es un
    # punto más abajo del canal, para que Godot sepa hacia dónde sale.
    vacio("nuca", NUCA, ob_craneo)
    vacio("nuca_canal", tuple(NUCA[i] + NUCA_DIR[i] * 0.03 for i in range(3)), ob_craneo)
    antes = centro + base_craneo.astype(np.float64) @ np.array(NUCA)
    sale = base_craneo.astype(np.float64) @ np.array(NUCA_DIR)
    sale /= np.linalg.norm(sale)
    for i, k in enumerate(COLA_TALLAS):
        paso = COLA_PASO * k
        suelo = 0.0105 * KV * k
        if i == 0:
            aqui = antes + sale * paso
            aqui[1] = max(aqui[1], suelo)
        else:
            baja = min(antes[1] - suelo, paso * 0.85)
            aqui = antes + np.array([0.0, -baja, -math.sqrt(max(paso * paso - baja * baja, 0.0))])
        z = antes - aqui
        z /= np.linalg.norm(z)
        x = np.cross(np.array([0.0, 1.0, 0.0]), z)
        x /= np.linalg.norm(x)
        y = np.cross(z, x)
        crear("vertebra_%d" % i, p_vertebras[i], material,
              matriz(np.stack([x, y, z], axis=1), aqui))
        total += len(p_vertebras[i]["t"])
        antes = aqui
    crear("huesecillo", p_hueso, material,
          matriz(rot_z(math.radians(90.0)) @ rot_y(0.6), (0.26, 0.006, 0.16)))
    traza("TOTAL: %d triángulos" % total)
    return total


def exportar():
    os.makedirs(os.path.dirname(SALIDA), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=SALIDA, export_format="GLB", use_selection=False,
        export_apply=False, export_yup=True, export_normals=True, export_tangents=False,
        export_vertex_color="ACTIVE", export_all_vertex_colors=False,
        export_active_vertex_color_when_no_material=True,
        export_materials="EXPORT", export_animations=False, export_skins=False,
        export_morph=False, export_extras=False)
    traza("GLB: %s (%.0f KB)" % (SALIDA, os.path.getsize(SALIDA) / 1024.0))


# ------------------------------------------------------ vistas de comprobación

def vistas(carpeta):
    """Renders rápidos (Workbench) para mirar la FORMA antes de pasar a Godot."""
    os.makedirs(carpeta, exist_ok=True)
    esc = bpy.context.scene
    esc.render.engine = "BLENDER_WORKBENCH"
    esc.render.resolution_x = 640
    esc.render.resolution_y = 640
    esc.render.film_transparent = False
    sombra = esc.display.shading
    sombra.light = "STUDIO"
    sombra.show_cavity = True
    sombra.cavity_type = "BOTH"
    sombra.cavity_ridge_factor = 1.0
    sombra.cavity_valley_factor = 1.5
    sombra.show_shadows = True
    sombra.shadow_intensity = 0.35
    sombra.show_object_outline = False
    mundo = bpy.data.worlds.new("fondo")
    esc.world = mundo
    cam_d = bpy.data.cameras.new("cam")
    cam_d.lens = 85.0
    cam = bpy.data.objects.new("cam", cam_d)
    esc.collection.objects.link(cam)
    esc.camera = cam
    mira = bpy.data.objects.new("mira", None)
    esc.collection.objects.link(mira)
    mira.location = (0.0, 0.0, 0.14)
    seguir = cam.constraints.new("TRACK_TO")
    seguir.target = mira
    # (nombre, posición de la cámara en Godot, color)
    tomas = [
        ("1_frente", (0.0, 0.20, 1.9), "SINGLE"),
        ("2_tres_cuartos", (1.25, 0.75, 1.35), "SINGLE"),
        ("3_perfil", (1.9, 0.2, 0.0), "SINGLE"),
        ("4_juego", (0.0, 1.55, 1.25), "SINGLE"),
        ("5_espalda", (-0.9, 0.9, -1.5), "SINGLE"),
        ("6_abajo", (0.6, -0.5, 1.6), "SINGLE"),
        ("7_color", (1.25, 0.75, 1.35), "VERTEX"),
        ("8_color_frente", (0.0, 0.20, 1.9), "VERTEX"),
        # Por detrás y bajo: lo que enseña la mandíbula cuando huye o rueda.
        ("9_detras_bajo", (-0.75, 0.02, -1.7), "SINGLE"),
        # Desde arriba es como la ve el juego; desde abajo, como la enseña volcada.
        ("10_arriba", (0.0, 1.9, -0.25), "SINGLE"),
        ("11_abajo", (0.35, -1.6, 0.55), "SINGLE"),
    ]
    for nombre, pos, color in tomas:
        cam.location = (pos[0], -pos[2], pos[1])
        sombra.color_type = color
        if color == "SINGLE":
            sombra.single_color = (0.80, 0.72, 0.58)
        esc.render.filepath = os.path.join(carpeta, nombre + ".png")
        bpy.ops.render.render(write_still=True)
    traza("vistas en", carpeta)


construir()
exportar()
if VISTAS:
    vistas(VISTAS)
traza("FIN")
