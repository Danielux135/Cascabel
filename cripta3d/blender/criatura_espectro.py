# criatura_espectro.py — el ESPECTRO de Cascabel, modelado entero por guion.
#
#   python cripta3d/herramientas/blender3d.py cripta3d/blender/criatura_espectro.py -- cripta3d/modelos/criatura_espectro.glb
#          [--vistas C:/carpeta/temporal]    además deja unos renders rápidos para mirar la forma
#
# QUÉ ES. El sprite `cr_espectro`: una masa violeta blanda con TRES OJOS grandes
# —uno arriba y dos abajo— y zarcillos que se rizan a los lados y gotean por
# abajo. No es un fantasma de sábana: es un blob de tres ojos. Aquí tiene volumen.
#
# QUÉ SALE. Un GLB con las piezas como objetos SEPARADOS y con nombre, que
# `cripta3d/criaturas/espectro.gd` busca por ese nombre y mueve por código:
#
#   cuerpo              la masa, con las tres cuencas y el faldón de goterones en punta
#   ojo_0               el de arriba, en el centro
#   ojo_1, ojo_2        los de abajo, izquierdo y derecho (simétricos)
#   zarcillo_i, _d      los dos jirones grandes de los lados (los del sprite)
#   zarcillo_i2, _d2    dos jirones menores, más bajos, a los lados
#   zarcillo_ti, _td    dos por detrás, que van a rastras
#   gota                una gota suelta, para las salpicaduras del golpe
# (Se siguen llamando «zarcillo» porque es el nombre que busca el guion; desde la
# crítica del 21-nov-2026 son CINTAS que se afilan, no tubos con un rizo.)
#
# El aspecto de verdad se lo ponen los shaders de `cripta3d/criaturas/espectro_*`;
# el material de aquí es de muestra, para que el GLB se entienda abierto solo.
#
# CÓMO ESTÁ HECHO. El cuerpo es un CAMPO DE DISTANCIAS (una fórmula que dice a qué
# distancia de la piel está cada punto) que se pasa a malla con OpenVDB y se
# simplifica: así los bultos, el reborde de las cuencas y los goterones se FUNDEN
# en la masa en vez de clavarse en ella. Las cuencas se calculan a partir de
# dónde caen los ojos sobre la piel, y los ojos se colocan en ese mismo sitio.
#
# LOS ZARCILLOS SALEN RECTOS, a lo largo de su +X local, y es a propósito: el rizo
# se lo pone `espectro_cuerpo.gdshader` (con `jiron` a 1), que sigue una curva a lo largo
# del zarcillo. Así se enroscan y se desenroscan VIVOS (miedo, huida, taparse los
# ojos) sin huesos. Abierto solo, el GLB los enseña estirados.
#
# EL COLOR DE VÉRTICE lleva la convención de la cripta (R oclusión, G canto, B libre):
#   cuerpo      R = oclusión (lo de debajo, el fondo de las cuencas, entre goterones)
#               G = canto: lo saliente, que es lo que coge el brillo de la gelatina
#               B = FALDÓN: 0 en la masa, 1 en la punta de cada goterón. Es lo que
#                   ondea y se queda atrás
#   zarcillos   R = oclusión (más oscuro en la raíz), G = canto, B = cuánto de
#               zarcillo es: 0 en la raíz, 1 en la punta
#   ojos        sin color: llevan UV y el ojo se dibuja en el shader
#
# Las coordenadas del guion son las de Godot (x derecha, y arriba, z hacia el
# jugador) y se giran al crear cada malla: Blender tiene la z arriba. y = 0 es la
# losa: el espectro FLOTA, así que nada del modelo baja de 0,02.
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
SALIDA = ARGV[0] if ARGV and not ARGV[0].startswith("--") else "cripta3d/modelos/criatura_espectro.glb"
VISTAS = ""
for _i, _a in enumerate(ARGV):
    if _a == "--vistas" and _i + 1 < len(ARGV):
        VISTAS = ARGV[_i + 1]

# ------------------------------------------------------------------- las medidas
# Radio de choque del corredor: 12 px = 0,12. La masa es un poco más estrecha que
# eso (0,11 de medio ancho) y los zarcillos sobresalen: lo que choca es el bulto.

## Desde dónde se buscan los ojos sobre la piel (el corazón de la masa).
CENTRO_OJOS = (0.0, 0.158, -0.005)


def direccion(azimut, elevacion):
    """Una dirección en grados: azimut 0 = hacia el jugador (+z), + a la derecha;
    elevación 0 = horizontal, 90 = arriba."""
    a, e = math.radians(azimut), math.radians(elevacion)
    return (math.sin(a) * math.cos(e), math.sin(e), math.cos(a) * math.cos(e))


## Los tres ojos, en TRIÁNGULO Y SIMÉTRICOS como en el sprite: uno arriba en el
## centro y dos abajo, a la misma altura. La cara va LEVANTADA unos 30°: la
## cámara de juego mira desde arriba (~48°), y con la cara vertical desde allí
## se veían dos ojos y no el triángulo. (Primera versión: el de arriba caído a la
## derecha y los de abajo torcidos; de frente no era la misma cara del sprite.)
OJOS = [
    ("ojo_0", direccion(0.0, 54.0), 0.0345),
    ("ojo_1", direccion(-38.0, 23.0), 0.0365),
    ("ojo_2", direccion(38.0, 23.0), 0.0365),
]
## Los JIRONES (las piezas se siguen llamando zarcillo_*, que es lo que busca
## `espectro.gd`): dónde nacen (dirección desde el centro, altura), hacia dónde
## salen, largo, MEDIO ANCHO en la raíz y una fase para que ninguno ondule igual.
## Son CINTAS, no tubos: la primera versión eran dos tubos de grosor constante con
## un rizo cerrado y se leían como asas de taza o cuernos de carnero. En el sprite
## son llamas irregulares de tamaños distintos que salen de la masa.
ZARCILLOS = [
    # nombre        hacia la raíz        altura  sale hacia            largo  r0     fase
    ("zarcillo_i", (-1.0, 0.0, 0.15), 0.150, (-1.0, 0.00, 0.18), 0.160, 0.041, 0.0),
    ("zarcillo_d", (1.0, 0.0, 0.10), 0.180, (1.0, 0.22, 0.08), 0.166, 0.038, 1.3),
    # Los menores salen hacia fuera y algo hacia arriba: colgando hacia abajo
    # eran dos patas más.
    ("zarcillo_i2", (-0.9, 0.0, 0.35), 0.100, (-0.90, 0.10, 0.45), 0.098, 0.025, 2.1),
    ("zarcillo_d2", (0.9, 0.0, 0.30), 0.104, (0.95, 0.06, 0.40), 0.108, 0.026, 3.4),
    ("zarcillo_ti", (-0.62, 0.0, -0.80), 0.128, (-0.55, -0.05, -0.85), 0.132, 0.030, 4.0),
    ("zarcillo_td", (0.66, 0.0, -0.76), 0.168, (0.52, 0.12, -0.85), 0.118, 0.027, 5.2),
]


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


def sd_cono_redondo(P, a, b, r1, r2):
    """Un tramo que adelgaza de r1 a r2 con los extremos redondos (el de Íñigo
    Quílez). Es el hueso de cada goterón."""
    a = np.asarray(a, dtype=np.float64)
    b = np.asarray(b, dtype=np.float64)
    ba = b - a
    l2 = float(ba @ ba)
    rr = r1 - r2
    a2 = l2 - rr * rr
    il2 = 1.0 / l2
    pa = P - a
    y = pa @ ba
    z = y - l2
    w = pa * l2 - np.outer(y, ba)
    x2 = (w * w).sum(1)
    y2 = y * y * l2
    z2 = z * z * l2
    k = math.copysign(1.0, rr) * rr * rr * x2
    d3 = (np.sqrt(np.maximum(x2 * a2 * il2, 0.0)) + y * rr) * il2 - r1
    d1 = np.sqrt(x2 + z2) * il2 - r2
    d2 = np.sqrt(x2 + y2) * il2 - r1
    return np.where(np.sign(z) * a2 * z2 > k, d1, np.where(np.sign(y) * a2 * y2 < k, d2, d3))


def sd_lenteja(P, c, n, ancho, alto):
    """Un elipsoide de revolución alrededor del eje `n` (`ancho` de través, `alto`
    a lo largo de `n`): el abultado de gelatina donde se hunde un ojo."""
    q = P - np.asarray(c, dtype=np.float64)
    n = np.asarray(n, dtype=np.float64)
    h = q @ n
    radial = q - np.outer(h, n)
    rho = np.sqrt((radial * radial).sum(1))
    k0 = np.sqrt((rho / ancho) ** 2 + (h / alto) ** 2)
    k1 = np.sqrt((rho / (ancho * ancho)) ** 2 + (h / (alto * alto)) ** 2)
    return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)


def ondas(P):
    """Un temblor de baja frecuencia en la piel: la masa no es una elipse limpia."""
    x, y, z = P[:, 0], P[:, 1], P[:, 2]
    return (np.sin(x * 61.0 + y * 23.0 + 1.3) * np.sin(z * 47.0 - y * 31.0 + 0.4)
            + 0.6 * np.sin(y * 83.0 + z * 29.0 + 2.1) * np.sin(x * 37.0 + 0.9))


# --- la masa

## Los bultos que la hacen ameba y no gota: centro y radios.
## La cara (lo que rodea a los ojos) va SIMÉTRICA, para que los tres ojos caigan
## en un triángulo limpio; lo asimétrico, que es lo que la hace ameba, va arriba
## y detrás.
BULTOS = [
    ((-0.064, 0.214, -0.034), (0.050, 0.046, 0.050)),
    ((0.058, 0.222, -0.044), (0.048, 0.042, 0.046)),
    ((0.004, 0.250, -0.046), (0.062, 0.034, 0.050)),
    ((-0.088, 0.140, -0.022), (0.044, 0.050, 0.050)),
    ((0.088, 0.140, -0.022), (0.044, 0.050, 0.050)),
    # la gotita de arriba a la izquierda del sprite, a medio desprenderse
    ((-0.098, 0.236, -0.020), (0.020, 0.020, 0.020)),
]

## Los goterones del faldón: ángulo en planta (0 = derecha, 90 = hacia el
## jugador), radio y altura arriba, radio y altura de la punta, grosor arriba y
## abajo. MUCHOS, FINOS Y EN PUNTA, de largos desiguales: la primera versión
## acababa cada uno en una gota roma del mismo grosor, y de frente eran cuatro
## patas o una ubre (una mesa con ojos). Ahora cada uno se afila hasta nada y el
## shader se los come por abajo: el espectro no tiene un final duro.
## Los de delante son cortos (dejan ver que flota); los de los lados y detrás,
## largos: son la silueta deshilachada.
def _goterones():
    g = []
    n = 17
    for i in range(n):
        ang = i * 360.0 / n + 11.0 * math.sin(i * 2.7)
        delante = max(0.0, math.sin(math.radians(ang)))
        largo = ((i * 7) % 5) / 4.0                     # 0..1, sin orden
        y_b = 0.022 + 0.044 * delante + 0.034 * (1.0 - largo)
        r_a = 0.090 - 0.010 * delante
        r_b = r_a * (1.04 + 0.14 * largo) - 0.016 * delante
        g_a = 0.0125 + 0.0045 * ((i * 5) % 3) / 2.0
        g_b = 0.0009
        g.append((ang, r_a, 0.104, r_b, y_b, g_a, g_b))
    return g


GOTERONES = _goterones()


def en_planta(grados, radio, y):
    a = math.radians(grados)
    return np.array([radio * math.cos(a), y, radio * math.sin(a)])


def sd_goteron(P, g, giro):
    ang, r_a, y_a, r_b, y_b, g_a, g_b = g
    arriba = en_planta(ang, r_a, y_a)
    medio = en_planta(ang + giro * 0.5, (r_a + r_b) * 0.52, (y_a + y_b) * 0.5 + 0.006)
    abajo = en_planta(ang + giro, r_b, y_b)
    # Se afila deprisa en la segunda mitad: un jirón, no un dedo. Sin gota en la
    # punta (era lo que los hacía patas).
    g_m = g_a * 0.62
    d = sd_cono_redondo(P, arriba, medio, g_a, g_m)
    return smin(d, sd_cono_redondo(P, medio, abajo, g_m, g_b), 0.008)


def sd_masa(P):
    d = sd_elipsoide(P, (0.0, 0.174, -0.006), (0.108, 0.098, 0.098))
    d = smin(d, sd_elipsoide(P, (0.0, 0.126, 0.006), (0.122, 0.050, 0.106)), 0.050)
    for c, r in BULTOS:
        d = smin(d, sd_elipsoide(P, c, r), 0.034)
    for i, g in enumerate(GOTERONES):
        giro = (-1.0 if i % 2 else 1.0) * (9.0 + 4.0 * (i % 3))
        d = smin(d, sd_goteron(P, g, giro), 0.020)
    return d + 0.0019 * ondas(P)


def gradiente(fn, p, e=0.0012):
    g = np.zeros(3)
    for i in range(3):
        d = np.zeros(3)
        d[i] = e
        g[i] = fn((p + d)[None, :])[0] - fn((p - d)[None, :])[0]
    return g / max(np.linalg.norm(g), 1e-12)


def sobre_la_piel(fn, desde, hacia):
    """El punto de la piel de `fn` que hay saliendo de `desde` en la dirección
    `hacia` (por bisección: dentro es negativo)."""
    desde = np.asarray(desde, dtype=np.float64)
    hacia = np.asarray(hacia, dtype=np.float64)
    hacia = hacia / np.linalg.norm(hacia)
    a, b = 0.0, 0.25
    for _ in range(50):
        m = 0.5 * (a + b)
        if fn((desde + hacia * m)[None, :])[0] < 0.0:
            a = m
        else:
            b = m
    return desde + hacia * 0.5 * (a + b)


def colocar_ojos():
    """Dónde cae cada ojo: en la piel de la masa, asomando algo más de la mitad."""
    ojos = []
    for nombre, hacia, r in OJOS:
        p = sobre_la_piel(sd_masa, CENTRO_OJOS, hacia)
        # El ojo mira hacia donde se le pide, no hacia donde caiga la normal de la
        # piel en ese punto: el temblor de la masa torcía un ojo y no el otro, y
        # la cara dejaba de ser simétrica.
        n = 0.25 * gradiente(sd_masa, p) + 0.75 * np.asarray(hacia) / np.linalg.norm(hacia)
        n /= np.linalg.norm(n)
        # Hundido: asoma un poco más de media esfera. Más fuera, eran pelotas de
        # ping-pong pegadas (el sprite los tiene a ras); más dentro, desde
        # arriba se veía un disco plano.
        c = p - n * r * 0.28
        ojos.append({"nombre": nombre, "c": c, "n": n, "r": r})
    return ojos


def sd_cuerpo(P, ojos):
    d = sd_masa(P)
    for o in ojos:
        # El párpado NACE de la masa: un abultado ancho y bajo de la propia
        # gelatina, fundido con mucha blandura, y dentro la cuenca. Así el borde
        # del ojo es un labio que sube de la piel. La primera versión le ponía un
        # toro y se leía como una arandela pegada (con su costura y todo).
        r = o["r"]
        d = smin(d, sd_lenteja(P, o["c"] - o["n"] * r * 0.20, o["n"], r * 1.55, r * 0.78), 0.016)
        # La cuenca, un pelo MÁS CHICA que el globo: el labio se le apoya encima.
        # Con holgura quedaba una rendija oscura alrededor del ojo, y esa rendija
        # era la arandela.
        d = smax(d, -sd_esfera(P, o["c"], r * 0.985), 0.006)
    return d


# ---------------------------------------------------------------- de campo a malla

def a_blender(P):
    """Godot (x, y arriba, z al jugador) → Blender (x, y al fondo, z arriba)."""
    P = np.asarray(P, dtype=np.float64)
    return np.stack([P[..., 0], -P[..., 2], P[..., 1]], axis=-1)


def a_godot(P):
    P = np.asarray(P, dtype=np.float64)
    return np.stack([P[..., 0], P[..., 2], -P[..., 1]], axis=-1)


def matriz(origen, bx, by, bz):
    """El marco de un objeto, dado en Godot: columnas x, y, z y origen. Un punto
    local de Godot (x, y, z) se guarda en Blender como (x, −z, y); con estas
    columnas, el GLB llega a Godot con la base (bx, by, bz) tal cual."""
    m1 = a_blender(bx)
    m2 = -a_blender(bz)
    m3 = a_blender(by)
    o = a_blender(origen)
    return Matrix((
        (m1[0], m2[0], m3[0], o[0]),
        (m1[1], m2[1], m3[1], o[1]),
        (m1[2], m2[2], m3[2], o[2]),
        (0.0, 0.0, 0.0, 1.0)))


def malla_de_campo(nombre, fn, lo, hi, paso, tris, alisar=2):
    """Evalúa el campo en una rejilla, saca la superficie y la deja en `tris`
    triángulos. Devuelve el objeto de Blender, ya en la escena."""
    lo = np.asarray(lo, dtype=np.float64)
    hi = np.asarray(hi, dtype=np.float64)
    ejes = [np.arange(lo[i], hi[i] + paso * 0.5, paso) for i in range(3)]
    X, Y, Z = np.meshgrid(ejes[0], ejes[1], ejes[2], indexing="ij")
    P = np.stack([X.ravel(), Y.ravel(), Z.ravel()], axis=1)
    campo = fn(P).reshape(X.shape).astype(np.float32)
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


def vertices_godot(obj, mundo=False):
    n = len(obj.data.vertices)
    co = np.zeros(n * 3)
    obj.data.vertices.foreach_get("co", co)
    no = np.zeros(n * 3)
    obj.data.vertices.foreach_get("normal", no)
    co = co.reshape(n, 3)
    no = no.reshape(n, 3)
    if mundo:
        m = np.array(obj.matrix_world)
        co = co @ m[:3, :3].T + m[:3, 3]
        no = no @ m[:3, :3].T
        no /= np.maximum(np.linalg.norm(no, axis=1, keepdims=True), 1e-9)
    return a_godot(co), a_godot(no)


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


def arbol_de(objs):
    """Un BVH con todas las piezas en coordenadas de mundo (de Blender)."""
    verts = []
    polis = []
    for o in objs:
        m = o.matrix_world
        base = len(verts)
        verts += [tuple(m @ v.co) for v in o.data.vertices]
        polis += [tuple(base + i for i in p.vertices) for p in o.data.polygons]
    return BVHTree.FromPolygons(verts, polis)


def oclusion(obj, arbol, radio, fuerza=1.0, rayos=40):
    """Oclusión por vértice lanzando rayos contra el conjunto (en Blender)."""
    malla = obj.data
    n = len(malla.vertices)
    m = obj.matrix_world
    m3 = m.to_3x3()
    dirs = hemisferio(rayos)
    ao = np.ones(n)
    for i, v in enumerate(malla.vertices):
        co = np.array(m @ v.co)
        nz = np.array(m3 @ v.normal)
        nz /= max(np.linalg.norm(nz), 1e-9)
        ref = np.array([0.0, 0.0, 1.0]) if abs(nz[2]) < 0.9 else np.array([1.0, 0.0, 0.0])
        tx = np.cross(ref, nz)
        tx /= max(np.linalg.norm(tx), 1e-9)
        ty = np.cross(nz, tx)
        origen = Vector(co + nz * 0.0015)
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
    """Un material de MUESTRA. La gelatina va en negro y con emisión: el color de
    vértice de esas mallas son datos (oclusión, canto, faldón) y glTF lo
    multiplica por el color base, así que con base de color saldría teñida."""
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
                n.inputs["Roughness"].default_value = 0.3
    obj.data.materials.clear()
    obj.data.materials.append(mat)


def triangulos(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


# -------------------------------------------------------------------- las piezas

def hacer_ojo(o, segmentos=32, anillos=18):
    """Un globo: una esfera de verdad, con UV y el polo hacia arriba. Lo de
    dentro de la cuenca no se ve, pero se deja: el ojo GIRA (parpadeo, mirada)
    y por el borde del reborde asoma cualquier lado."""
    r = o["r"]
    verts = []
    uvs = []
    for i in range(anillos + 1):
        v = i / anillos
        th = math.pi * v
        for j in range(segmentos + 1):
            u = j / segmentos
            ph = 2.0 * math.pi * u
            # local de Godot: y arriba, z hacia fuera de la piel. La costura
            # (ph = 0) va DETRÁS, dentro de la cuenca: delante partía el globo.
            x = r * math.sin(th) * math.sin(ph)
            y = r * math.cos(th)
            z = -r * math.sin(th) * math.cos(ph)
            verts.append((x, -z, y))       # local de Blender
            uvs.append((u, 1.0 - v))
    caras = []
    fila = segmentos + 1
    for i in range(anillos):
        for j in range(segmentos):
            a = i * fila + j
            b = a + fila
            if i == 0:
                caras.append((a, b + 1, b))
            elif i == anillos - 1:
                caras.append((a, a + 1, b))
            else:
                caras.append((a, a + 1, b + 1, b))
    malla = bpy.data.meshes.new(o["nombre"])
    malla.from_pydata(verts, [], caras)
    malla.update()
    capa = malla.uv_layers.new(name="UVMap")
    for poli in malla.polygons:
        for li in poli.loop_indices:
            capa.data[li].uv = uvs[malla.loops[li].vertex_index]
    bm = bmesh.new()
    bm.from_mesh(malla)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=r * 1e-4)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(malla)
    bm.free()
    malla.shade_smooth()
    obj = bpy.data.objects.new(o["nombre"], malla)
    bpy.context.scene.collection.objects.link(obj)
    n = o["n"]
    arriba = np.array([0.0, 1.0, 0.0]) - n * n[1]
    arriba /= np.linalg.norm(arriba)
    derecha = np.cross(arriba, n)
    obj.matrix_world = matriz(o["c"], derecha, arriba, n)
    material(obj, "espectro_ojo", (0.92, 0.90, 0.88))
    return obj


def hacer_zarcillo(nombre, raiz, sale, largo, r0, fase=0.0, tumbado=False, lados=12, tramos=30):
    """Un JIRÓN RECTO a lo largo de +X local, con la raíz en el origen y un trozo
    metido en la masa (x < 0) para que no se vea la junta. Es una CINTA: ancho en
    su Y local (el plano en el que lo dobla el shader) y fino en Z, como una
    lengua de llama. Se afila hasta nada, y los dos bordes ondulan cada uno a su
    aire (la línea del centro serpentea): sin eso, de frente era un tubo."""
    hundido = r0 * 1.2
    verts = []
    datos_b = []
    for i in range(tramos + 1):
        u = i / tramos
        x = -hundido + (largo + hundido) * u
        s = max(x, 0.0) / largo
        # El medio ancho: se afila en punta, con un par de ensanches de llama.
        bulto = 1.0 + 0.30 * math.sin(s * math.pi * 3.1 + fase) * paso_suave(0.10, 0.35, np.array([s]))[0]
        # No acaba en punta: se queda en una lengua de un tercio de ancho y es el
        # fundido del shader el que la deshace. En punta, de canto, eran lanzas.
        w = r0 * (1.0 - 0.68 * s ** 1.15) * bulto
        # La raíz se ensancha: el jirón NACE de la masa, no se clava en ella.
        w *= 1.0 + 0.45 * (1.0 - paso_suave(-0.004, 0.030, np.array([x]))[0])
        grueso = w * 0.30 + 0.0014 * (1.0 - s)
        centro_y = r0 * 0.45 * math.sin(s * math.pi * 2.3 + fase * 1.7) * s
        if i == tramos:
            w *= 0.6
            grueso *= 0.3
        for j in range(lados):
            a = 2.0 * math.pi * j / lados
            verts.append((x, centro_y + w * math.cos(a), grueso * math.sin(a)))
            datos_b.append(s)
    caras = []
    for i in range(tramos):
        for j in range(lados):
            j2 = (j + 1) % lados
            a = i * lados + j
            caras.append((a, a + lados, a + lados + j2 - j, i * lados + j2))
    # la tapa de la raíz (queda dentro de la masa, pero cerrada)
    caras.append(tuple(range(lados - 1, -1, -1)))
    malla = bpy.data.meshes.new(nombre)
    malla.from_pydata([(v[0], -v[2], v[1]) for v in verts], [], caras)
    malla.update()
    bm = bmesh.new()
    bm.from_mesh(malla)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(malla)
    bm.free()
    malla.shade_smooth()
    obj = bpy.data.objects.new(nombre, malla)
    bpy.context.scene.collection.objects.link(obj)
    x = np.asarray(sale, dtype=np.float64)
    x /= np.linalg.norm(x)
    # De pie (los de los lados: de frente se ven planos, como llamas) o TUMBADO
    # (los de detrás: la cinta queda de cara al techo y ondula en horizontal,
    # que es como se ve una cola que va a rastras desde la cámara de juego; de
    # pie, desde atrás se veían de canto y eran un pitorro tieso).
    # Los de los lados, de pie pero con la cara VUELTA hacia arriba y adelante
    # (unos 40°): de pie del todo, desde la cámara de juego se veían de canto y
    # eran lanzas finas.
    y = np.array([0.0, 1.0, -0.80])
    y = y - x * float(y @ x)
    if tumbado:
        y = np.cross(np.array([0.0, 1.0, 0.0]), x)
    y /= np.linalg.norm(y)
    z = np.cross(x, y)
    obj.matrix_world = matriz(raiz, x, y, z)
    material(obj, "espectro_gel", (0.42, 0.25, 0.62), 0.6)
    # B: cuánto de zarcillo (lo usa el shader para el rizo y el arrastre)
    xs = np.array([v.co.x for v in malla.vertices])
    return obj, np.clip(xs / largo, 0.0, 1.0)


def hacer_gota():
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.010)
    for v in bm.verts:
        # una gota: algo apuntada por detrás
        if v.co.y > 0.0:
            v.co.y *= 1.5
    malla = bpy.data.meshes.new("gota")
    bm.to_mesh(malla)
    bm.free()
    malla.shade_smooth()
    obj = bpy.data.objects.new("gota", malla)
    bpy.context.scene.collection.objects.link(obj)
    material(obj, "espectro_gel", (0.42, 0.25, 0.62), 0.6)
    return obj


# ------------------------------------------------------------------------ mirar

def renders(carpeta, grupos):
    """Renders de trabajo (Workbench, con el color de vértice) para ver la forma
    sin pasar por Godot. No son el aspecto final: eso lo ponen los shaders."""
    os.makedirs(carpeta, exist_ok=True)
    esc = bpy.context.scene
    esc.render.engine = "BLENDER_WORKBENCH"
    esc.display.shading.light = "STUDIO"
    esc.display.shading.color_type = "VERTEX"
    esc.display.shading.show_cavity = True
    esc.render.resolution_x = 520
    esc.render.resolution_y = 520
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
                                 "juego": (0.0, 51.0)}.items():
            a, e = math.radians(az), math.radians(el)
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

    ojos = colocar_ojos()
    for o in ojos:
        print("ESPECTRO %s en %s, normal %s" % (o["nombre"], np.round(o["c"], 4), np.round(o["n"], 3)))
    cuerpo = malla_de_campo("cuerpo", lambda P: sd_cuerpo(P, ojos), (-0.175, 0.0, -0.165),
                            (0.175, 0.300, 0.170), 0.0030, 4300)
    globos = [hacer_ojo(o) for o in ojos]

    zarcillos = []
    b_zarcillos = []
    for nombre, hacia, alto, sale, largo, r0, fase in ZARCILLOS:
        h = np.asarray(hacia, dtype=np.float64)
        h /= np.linalg.norm(h)
        # La raíz, en la piel de la masa a esa altura, hundida un pelo.
        p = sobre_la_piel(sd_masa, (0.0, alto, -0.005), h)
        obj, b = hacer_zarcillo(nombre, p - h * 0.004, sale, largo, r0, fase,
                                nombre.startswith("zarcillo_t"))
        zarcillos.append(obj)
        b_zarcillos.append(b)
    gota = hacer_gota()
    bpy.context.view_layer.update()

    # --- El color de vértice, con todas las piezas tapándose entre sí
    arbol = arbol_de([cuerpo] + globos + zarcillos)
    vec = vecinos(cuerpo)
    P, _n = vertices_godot(cuerpo)
    ao = suavizar(oclusion(cuerpo, arbol, 0.07, 1.7), vec, 1)
    # Lo de debajo: la gelatina no se ve desde abajo, pero el faldón sí, y la
    # panza es lo que queda en sombra.
    ao *= 0.72 + 0.28 * paso_suave(0.07, 0.16, P[:, 1])
    filo = suavizar(paso_suave(0.02, 0.22, canto(cuerpo, vec)), vec, 2)
    faldon = suavizar(paso_suave(0.104, 0.028, P[:, 1]), vec, 1)
    pintar(cuerpo, ao, filo, faldon)
    material(cuerpo, "espectro_gel", (0.42, 0.25, 0.62), 0.6)

    for obj, b in zip(zarcillos, b_zarcillos):
        vz = vecinos(obj)
        ao_z = suavizar(oclusion(obj, arbol, 0.05, 1.4, 24), vz, 1)
        ao_z *= 0.55 + 0.45 * paso_suave(0.0, 0.35, b)
        pintar(obj, ao_z, 0.35 + 0.65 * b, b)
    pintar(gota, np.ones(len(gota.data.vertices)), np.full(len(gota.data.vertices), 0.6),
           np.zeros(len(gota.data.vertices)))
    gota.location = Vector(a_blender(np.array((0.26, 0.10, 0.0))))

    total = 0
    for o in [cuerpo] + globos + zarcillos + [gota]:
        t = triangulos(o)
        total += t
        Pg, _n = vertices_godot(o, mundo=True)
        print("ESPECTRO %-12s %5d tri  x[%.3f %.3f] y[%.3f %.3f] z[%.3f %.3f]" % (
            o.name, t, Pg[:, 0].min(), Pg[:, 0].max(), Pg[:, 1].min(), Pg[:, 1].max(),
            Pg[:, 2].min(), Pg[:, 2].max()))
    print("ESPECTRO total: %d triángulos" % total)

    os.makedirs(os.path.dirname(os.path.abspath(SALIDA)), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=os.path.abspath(SALIDA), export_format="GLB", use_selection=False,
        export_yup=True, export_apply=False, export_normals=True, export_tangents=False,
        export_materials="EXPORT", export_vertex_color="ACTIVE",
        export_all_vertex_colors=False, export_active_vertex_color_when_no_material=True,
        export_animations=False, export_skins=False, export_morph=False)
    print("ESPECTRO guardado en", os.path.abspath(SALIDA))

    if VISTAS:
        renders(VISTAS, [("entero", [cuerpo] + globos + zarcillos, (0.0, 0.15, 0.0), 0.50)])
        print("ESPECTRO vistas en", VISTAS)


main()
