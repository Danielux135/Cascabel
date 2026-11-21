# piezas_modelos.py — LAS PIEZAS QUE GOLPEA LA BOLA, modeladas por guion.
#
#   python cripta3d/herramientas/blender3d.py cripta3d/blender/piezas_modelos.py -- cripta3d/modelos/piezas_cripta.glb
#          [--vistas C:/carpeta/temporal]    además deja un render rápido de todas, con su color de vértice
#
# QUÉ SALE. Un GLB con cada pieza partida en los trozos que llevan material
# distinto o que se mueven por su cuenta, como objetos SEPARADOS y con nombre.
# `cripta3d/mundo/piezas.gd` los busca por ese nombre, coge SOLO la malla (no la
# posición del objeto: en el GLB van repartidos en fila para poder mirarlos) y
# le pone el material de la biblioteca.
#
#   brasero_engranaje   el engranaje oxidado: gira un diente con cada golpe
#   brasero_corona      el aro de hierro remachado con su cuenco: SALTA con el golpe
#   brasero_bocel       el bocel de bronce del borde del cuenco (salta con la corona)
#   brasero_brasas      el montón de brasas del cuenco (ascua; B = cuánto arde)
#   lapida              lápida con su zócalo y una calavera en relieve (piedra)
#   lapida_ranura       el marco de hierro de la ranura donde se hunde (fijo)
#   escudo_madera       el escudo de tablas de roble
#   escudo_herraje      su cerco, sus bandas, la bloca y los clavos (hierro)
#   pala_cuerpo         la pala de hierro forjado
#   pala_goma           su goma negra, en lágrima (lo que choca)
#   pala_acero          el eje, el tornillo y la varilla de acero de encima
#   torno_aspa          la chapa que gira, con su cubo y sus remaches
#   torno_soportes      los dos postecillos con sus cojinetes
#   torno_eje           el eje de acero
#   poste_cuerpo        el poste de piedra
#   poste_goma          su aro de goma roja
#   poste_tapa          el zuncho de hierro remachado de arriba
#   goma_poste          un poste de hierro de los que sujetan la banda de una goma
#   sarcofago_brocal    el borde de piedra del sarcófago hundido en el suelo del coro
#   sarcofago_fondo     lo de dentro: oscuro, con rescoldo (carbón; B = fuego)
#   sarcofago_huesos    la calavera y los huesos del fondo
#   sarcofago_tapa      la losa de la tapa, apartada y apoyada
#   lanzador_cabeza     la cabeza del ariete
#   lanzador_vastago    el vástago de acero
#   lanzador_muelle     el muelle (se ESTIRA en Godot a lo largo de su eje)
#   lanzador_soporte    el soporte fijo del fondo del carril
#
# MEDIDAS. Todo va en unidades de Godot (1 = 100 px de mesa) y a la medida
# NOMINAL del colisionador de hoy: búmper de 19 px de radio, poste de 11, torno
# de 10, platillo de 13, pala de 64 × 8, target de 30 × 8. `piezas.gd` lee la
# medida de verdad de la mesa y escala o ESTIRA la malla (las palas y los
# targets se estiran solo por su tramo recto, para no deformar las puntas).
#
# EJES. Se modela en ejes de Blender (z arriba) pensando en Godot: x es x, la
# altura es z, y el FRENTE de cada pieza (lo que mira al jugador, +z en Godot)
# es −y aquí. El exportador hace el giro.
#
# COLOR DE VÉRTICE (la convención de la cripta): R oclusión, horneada lanzando
# rayos contra la pieza entera y el suelo; G canto, de lo convexa que es la
# malla en cada vértice; B libre (cuánto arde, en las brasas y el fondo).
import math
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector, noise
from mathutils.bvhtree import BVHTree

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SALIDA = ARGV[0] if ARGV and not ARGV[0].startswith("--") else "cripta3d/modelos/piezas_cripta.glb"
VISTAS = ""
for _i, _a in enumerate(ARGV):
    if _a == "--vistas" and _i + 1 < len(ARGV):
        VISTAS = ARGV[_i + 1]

AQUI = os.path.dirname(os.path.abspath(__file__))
CALAVERA = os.path.join(AQUI, "fuentes", "calavera_ia.glb")
TAU = math.tau

# ------------------------------------------------------------------ utilidades


def nueva(nombre, bm):
    malla = bpy.data.meshes.new(nombre)
    bm.normal_update()
    bm.to_mesh(malla)
    bm.free()
    obj = bpy.data.objects.new(nombre, malla)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def cara(bm, vs):
    try:
        return bm.faces.new(vs)
    except ValueError:
        return None


def solido(nombre, contornos, z0, z1):
    """Un prisma: el contorno exterior y, si los hay, agujeros con el MISMO
    número de puntos (se cosen por cuadros). Contornos en el plano XY."""
    bm = bmesh.new()
    ext = contornos[0]
    n = len(ext)
    abajo = [bm.verts.new((x, y, z0)) for x, y in ext]
    arriba = [bm.verts.new((x, y, z1)) for x, y in ext]
    for i in range(n):
        j = (i + 1) % n
        cara(bm, [abajo[i], abajo[j], arriba[j], arriba[i]])
    if len(contornos) == 1:
        cara(bm, list(reversed(abajo)))
        cara(bm, arriba)
    else:
        hueco = contornos[1]
        hab = [bm.verts.new((x, y, z0)) for x, y in hueco]
        har = [bm.verts.new((x, y, z1)) for x, y in hueco]
        for i in range(n):
            j = (i + 1) % n
            cara(bm, [har[i], har[j], hab[j], hab[i]])
            cara(bm, [arriba[i], arriba[j], har[j], har[i]])
            cara(bm, [hab[i], hab[j], abajo[j], abajo[i]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return nueva(nombre, bm)


def torno(nombre, perfil, seg, giro=0.0):
    """Superficie de revolución alrededor de z. `perfil` = [(r, z)], de abajo
    arriba; un r = 0 en un extremo cierra con un vértice."""
    bm = bmesh.new()
    anillos = []
    for r, z in perfil:
        if r < 1e-6:
            anillos.append([bm.verts.new((0.0, 0.0, z))])
        else:
            anillos.append([bm.verts.new((r * math.cos(giro + TAU * k / seg),
                                          r * math.sin(giro + TAU * k / seg), z)) for k in range(seg)])
    for a, b in zip(anillos[:-1], anillos[1:]):
        for k in range(seg):
            k2 = (k + 1) % seg
            if len(a) == 1 and len(b) == 1:
                continue
            if len(a) == 1:
                cara(bm, [a[0], b[k], b[k2]])
            elif len(b) == 1:
                cara(bm, [a[k], b[0], a[k2]])
            else:
                cara(bm, [a[k], a[k2], b[k2], b[k]])
    if len(anillos[0]) > 1:
        cara(bm, list(reversed(anillos[0])))
    if len(anillos[-1]) > 1:
        cara(bm, anillos[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return nueva(nombre, bm)


def perfil_redondo(r0, r1, z0, z1, radio, pasos=4):
    """El perfil (r, z) de un anillo de sección rectangular con las cuatro
    esquinas redondeadas: va por fuera de abajo arriba y vuelve por dentro."""
    pts = []
    esquinas = [(r1 - radio, z0 + radio, -90.0, 0.0), (r1 - radio, z1 - radio, 0.0, 90.0),
                (r0 + radio, z1 - radio, 90.0, 180.0), (r0 + radio, z0 + radio, 180.0, 270.0)]
    for cx, cz, a0, a1 in esquinas:
        for k in range(pasos + 1):
            a = math.radians(a0 + (a1 - a0) * k / pasos)
            pts.append((cx + radio * math.cos(a), cz + radio * math.sin(a)))
    return pts


def torno_cerrado(nombre, perfil, seg):
    """Revolución de un perfil CERRADO (un anillo, un toro): cose el último con
    el primero."""
    bm = bmesh.new()
    anillos = [[bm.verts.new((r * math.cos(TAU * k / seg), r * math.sin(TAU * k / seg), z))
                for k in range(seg)] for r, z in perfil]
    m = len(anillos)
    for i in range(m):
        a = anillos[i]
        b = anillos[(i + 1) % m]
        for k in range(seg):
            k2 = (k + 1) % seg
            cara(bm, [a[k], a[k2], b[k2], b[k]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return nueva(nombre, bm)


def circulo(r, n, giro=0.0, centro=(0.0, 0.0)):
    return [(centro[0] + r * math.cos(giro + TAU * k / n), centro[1] + r * math.sin(giro + TAU * k / n))
            for k in range(n)]


def capsula(a, b, r, n):
    """El contorno de una cápsula del punto a al b (en el plano), n puntos por
    media vuelta. Es la forma de los colisionadores."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    base = math.atan2(dy, dx)
    pts = []
    for i in range(n + 1):
        ang = base - math.pi / 2 + math.pi * i / n
        pts.append((b[0] + r * math.cos(ang), b[1] + r * math.sin(ang)))
    for i in range(n + 1):
        ang = base + math.pi / 2 + math.pi * i / n
        pts.append((a[0] + r * math.cos(ang), a[1] + r * math.sin(ang)))
    return pts


def lagrima(a, ra, b, rb, n):
    """El contorno de dos círculos de radios distintos unidos por sus tangentes."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    d = math.hypot(dx, dy)
    base = math.atan2(dy, dx)
    alfa = math.acos((ra - rb) / d)
    pts = []
    for i in range(n + 1):
        ang = base - alfa + (2 * alfa) * i / n
        pts.append((b[0] + rb * math.cos(ang), b[1] + rb * math.sin(ang)))
    for i in range(n + 1):
        ang = base + alfa + (TAU - 2 * alfa) * i / n
        pts.append((a[0] + ra * math.cos(ang), a[1] + ra * math.sin(ang)))
    return pts


def aplicar(obj):
    grafo = bpy.context.evaluated_depsgraph_get()
    vieja = obj.data
    nueva_m = bpy.data.meshes.new_from_object(obj.evaluated_get(grafo))
    obj.modifiers.clear()
    obj.data = nueva_m
    bpy.data.meshes.remove(vieja)
    return obj


def biselar(obj, ancho, segs=3, angulo=30.0):
    mod = obj.modifiers.new("bisel", "BEVEL")
    mod.width = ancho
    mod.segments = segs
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(angulo)
    mod.miter_outer = "MITER_ARC"
    return aplicar(obj)


def aplanar(obj, grados=0.6):
    """Junta las caras coplanarias: un booleano deja el plano lleno de astillas
    que no se ven y cuestan triángulos."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.dissolve_limit(bm, angle_limit=math.radians(grados), verts=bm.verts, edges=bm.edges)
    bmesh.ops.triangulate(bm, faces=bm.faces, quad_method="BEAUTY", ngon_method="BEAUTY")
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    return obj


def subdividir(obj, cortes=1):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges, cuts=cortes, use_grid_fill=True)
    bm.to_mesh(obj.data)
    bm.free()
    return obj


def abollar(obj, amplitud, escala, semilla=0.0, solo_z=None):
    """Lo que separa una pieza forjada de una de ordenador: la superficie no
    es perfecta. Mueve cada vértice por su normal con un ruido suave."""
    malla = obj.data
    malla.update()
    for v in malla.vertices:
        p = Vector(v.co) * escala + Vector((semilla, semilla * 1.7, semilla * 0.3))
        d = noise.noise(p) * amplitud
        if solo_z is not None and v.co.z < solo_z:
            continue
        v.co = v.co + v.normal * d
    malla.update()
    return obj


def mover(obj, x=0.0, y=0.0, z=0.0, rz=0.0, rx=0.0, ry=0.0, esc=None):
    m = Matrix.Translation((x, y, z)) @ Matrix.Rotation(rz, 4, "Z") @ Matrix.Rotation(ry, 4, "Y") \
        @ Matrix.Rotation(rx, 4, "X")
    if esc is not None:
        if isinstance(esc, (int, float)):
            esc = (esc, esc, esc)
        m = m @ Matrix.Diagonal((esc[0], esc[1], esc[2], 1.0))
    obj.data.transform(m)
    obj.data.update()
    return obj


def unir(nombre, objs):
    bm = bmesh.new()
    for o in objs:
        m = o.data.copy()
        m.transform(o.matrix_world)
        bm.from_mesh(m)
        bpy.data.meshes.remove(m)
    for o in objs:
        malla = o.data
        bpy.data.objects.remove(o)
        if malla.users == 0:
            bpy.data.meshes.remove(malla)
    return nueva(nombre, bm)


def copia(obj, nombre=None):
    o = obj.copy()
    o.data = obj.data.copy()
    o.name = nombre or obj.name + "_c"
    bpy.context.scene.collection.objects.link(o)
    return o


## Objeto → desde qué vértice se alisa ENTERO, sin aristas vivas. La calavera
## en relieve de la lápida es una malla diezmada y aplastada de fondo: entre sus
## caras hay ángulos de más de 50°, `set_sharp_from_angle` las partía todas y
## salía con facetas planas que brillaban cada una por su lado, como cristal
## tallado (lo vio la revisión técnica en c3/t02).
LISOS = {}


def alisar(obj, angulo=50.0):
    malla = obj.data
    malla.shade_smooth()
    try:
        malla.set_sharp_from_angle(angle=math.radians(angulo))
    except Exception:
        pass
    desde = LISOS.get(obj.name)
    vivas = malla.attributes.get("sharp_edge")
    if desde is not None and vivas is not None:
        for e in malla.edges:
            if e.vertices[0] >= desde and e.vertices[1] >= desde:
                vivas.data[e.index].value = False
    malla.update()


def remaches(lista, r, alto, seg=8):
    """Cabezas de remache: cúpulas bajas en (x, y, z, eje) — el eje dice hacia
    dónde mira la cabeza: "z" arriba, "-y" al frente, "y" atrás."""
    partes = []
    perfil = [(r, 0.0)] + [(r * math.cos(a), alto * math.sin(a))
                           for a in np.linspace(0.25, math.pi / 2, 4)]
    perfil[-1] = (0.0, alto)
    for x, y, z, eje in lista:
        o = torno("remache", [(r * 0.98, -alto * 0.6)] + perfil, seg)
        if eje == "-y":
            mover(o, rx=math.pi / 2)
        elif eje == "y":
            mover(o, rx=-math.pi / 2)
        elif eje == "x":
            mover(o, ry=math.pi / 2)
        elif eje == "-x":
            mover(o, ry=-math.pi / 2)
        mover(o, x, y, z)
        partes.append(o)
    return partes


# ----------------------------------------------------------- el color de vértice


def hemisferio(n):
    d = []
    for i in range(n):
        u = (i + 0.5) / n
        a = i * math.pi * (3.0 - math.sqrt(5.0))
        r = math.sqrt(u)
        d.append((r * math.cos(a), r * math.sin(a), math.sqrt(max(1.0 - u, 0.0))))
    return np.array(d)


def arbol_de(objs, suelo):
    verts = []
    polis = []
    for o in objs:
        base = len(verts)
        mw = o.matrix_world
        verts += [tuple(mw @ v.co) for v in o.data.vertices]
        polis += [tuple(base + i for i in p.vertices) for p in o.data.polygons]
    if suelo is not None:
        b = len(verts)
        verts += [(-3.0, -3.0, suelo), (3.0, -3.0, suelo), (3.0, 3.0, suelo), (-3.0, 3.0, suelo)]
        polis.append((b, b + 1, b + 2, b + 3))
    return BVHTree.FromPolygons(verts, polis)


def oclusion(obj, arbol, radio, fuerza=1.0, rayos=24):
    malla = obj.data
    n = len(malla.vertices)
    co = np.zeros(n * 3)
    malla.vertices.foreach_get("co", co)
    co = co.reshape(n, 3)
    no = np.zeros(n * 3)
    malla.vertices.foreach_get("normal", no)
    no = no.reshape(n, 3)
    mw = obj.matrix_world
    dirs = hemisferio(rayos)
    ao = np.ones(n)
    for i in range(n):
        nz = no[i]
        ref = np.array([0.0, 0.0, 1.0]) if abs(nz[2]) < 0.9 else np.array([1.0, 0.0, 0.0])
        tx = np.cross(ref, nz)
        tx /= max(np.linalg.norm(tx), 1e-9)
        ty = np.cross(nz, tx)
        origen = mw @ Vector(co[i] + nz * 0.0008)
        tapado = 0.0
        for d in dirs:
            w = tx * d[0] + ty * d[1] + nz * d[2]
            golpe = arbol.ray_cast(origen, Vector(w), radio)
            if golpe[0] is not None:
                tapado += 1.0 - golpe[3] / radio
        ao[i] = 1.0 - min(tapado / rayos * fuerza, 1.0)
    return ao


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


def canto(obj, vec):
    malla = obj.data
    n = len(malla.vertices)
    co = np.zeros(n * 3)
    malla.vertices.foreach_get("co", co)
    co = co.reshape(n, 3)
    no = np.zeros(n * 3)
    malla.vertices.foreach_get("normal", no)
    no = no.reshape(n, 3)
    c = np.zeros(n)
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


def hornear(obj, vecinas, radio, fuerza=1.0, suelo=0.0, ganancia_canto=3.0, azul=None):
    """R oclusión contra la pieza ENTERA (`vecinas`, que la incluye) y el suelo;
    G canto; B lo que se pida."""
    arbol = arbol_de(vecinas, suelo)
    ao = oclusion(obj, arbol, radio, fuerza)
    vec = vecinos(obj)
    ao = suavizar(ao, vec, 1)
    g = suavizar(np.clip(canto(obj, vec) * ganancia_canto, 0.0, 1.0), vec, 1)
    b = np.zeros(len(ao)) if azul is None else np.asarray(azul(obj, ao), dtype=np.float64)
    pintar(obj, 0.12 + 0.88 * ao, g, b)


def material(obj, color):
    """Un material de MUESTRA, para que el GLB se entienda al abrirlo solo: el
    de verdad lo pone la biblioteca de la cripta."""
    nombre = "muestra_%02x%02x%02x" % tuple(int(c * 255) for c in color)
    mat = bpy.data.materials.get(nombre)
    if mat is None:
        mat = bpy.data.materials.new(nombre)
        if mat.node_tree is not None:
            for n in mat.node_tree.nodes:
                if n.type == "BSDF_PRINCIPLED":
                    n.inputs["Base Color"].default_value = (color[0], color[1], color[2], 1.0)
                    n.inputs["Roughness"].default_value = 0.7
    obj.data.materials.clear()
    obj.data.materials.append(mat)


def triangulos(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


# ----------------------------------------------------------------- la calavera


def calavera(alto, caras):
    """La calavera de la fuente de IA, reducida a `caras` y con `alto` de alto,
    mirando al frente (−y), con la base en z = 0."""
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=CALAVERA)
    nuevos = [o for o in bpy.data.objects if o not in antes]
    mallas = [o for o in nuevos if o.type == "MESH"]
    obj = mallas[0]
    obj.data = obj.data.copy()
    obj.data.transform(obj.matrix_world)
    obj.matrix_world = Matrix.Identity(4)
    obj.parent = None
    for o in nuevos:
        if o is not obj:
            bpy.data.objects.remove(o)
    if obj.name not in bpy.context.scene.collection.objects:
        for col in list(obj.users_collection):
            col.objects.unlink(obj)
        bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.clear()
    ahora = len(obj.data.polygons)
    if ahora > caras:
        mod = obj.modifiers.new("reducir", "DECIMATE")
        mod.ratio = caras / ahora
        mod.use_collapse_triangulate = True
        aplicar(obj)
    co = np.array([tuple(v.co) for v in obj.data.vertices])
    lo, hi = co.min(0), co.max(0)
    centro = (lo + hi) * 0.5
    esc = alto / (hi[2] - lo[2])
    obj.data.transform(Matrix.Diagonal((esc, esc, esc, 1.0))
                       @ Matrix.Translation((-centro[0], -centro[1], -lo[2])))
    obj.data.update()
    obj.name = "calavera"
    return obj


# ================================================================= LAS PIEZAS
#
# Cada función devuelve {nombre: objeto} con los trozos de su pieza, ya
# horneados y con su material de muestra.

R_BUMPER = 0.19


def brasero():
    dientes = 10
    r_punta, r_raiz, r_hueco = R_BUMPER, 0.152, 0.098
    # El engranaje: diente de flanco en cuña y punta plana, como el del sprite.
    ext = []
    paso = TAU / dientes
    for k in range(dientes):
        a = paso * k
        # Cinco puntos por diente (eran ocho): la punta sigue a r_punta, que es el
        # colisionador; lo que se quitó era el redondeo del flanco, que ya lo hace
        # el chaflán.
        for f, r in ((0.10, r_raiz), (0.30, r_punta), (0.56, r_punta), (0.76, r_raiz), (0.93, r_raiz)):
            ext.append((r * math.cos(a + paso * f), r * math.sin(a + paso * f)))
    hueco = []
    for k in range(dientes):
        a = paso * k
        for f in (0.10, 0.30, 0.56, 0.76, 0.93):
            hueco.append((r_hueco * math.cos(a + paso * f), r_hueco * math.sin(a + paso * f)))
    rueda = solido("brasero_engranaje", [ext, hueco], 0.012, 0.082)
    # Seis aligeramientos entre la llanta y los dientes: son los que dicen
    # «rueda de máquina» y no «galleta con picos». Por resta, antes del bisel,
    # para que el bisel les redondee también el canto.
    cils = []
    for k in range(6):
        a = TAU * (k + 0.5) / 6
        cil = torno("cil", [(0.0, -0.01), (0.012, -0.01), (0.012, 0.12), (0.0, 0.12)], 8)
        mover(cil, 0.132 * math.cos(a), 0.132 * math.sin(a))
        cils.append(cil)
    cil = unir("cils", cils)
    mod = rueda.modifiers.new("hueco", "BOOLEAN")
    mod.object = cil
    mod.operation = "DIFFERENCE"
    mod.solver = "EXACT"
    aplicar(rueda)
    bpy.data.objects.remove(cil)
    aplanar(rueda)
    # EL PESO: con un bisel de dos pasos y una llanta de 40 lados la rueda eran
    # 6.074 triángulos, por tres braseros y por tres pasadas (vista, reflejo y
    # sombra), para algo que en la cámara de juego mide 50 px. Un chaflán de un
    # paso coge el mismo brillo en el filo a esa distancia.
    rueda = biselar(rueda, 0.006, 1, 30.0)
    aplanar(rueda)
    # Un reborde más alto junto al cubo: la llanta y el plato no son la misma pieza.
    llanta = torno_cerrado("llanta", perfil_redondo(r_hueco, 0.113, 0.07, 0.092, 0.005, 1), 30)
    abollar(rueda, 0.0016, 38.0, 1.0)
    rueda = unir("brasero_engranaje", [rueda, llanta])

    # La corona: aro de hierro remachado con el cuenco dentro. Es la que salta.
    aro = torno_cerrado("aro", perfil_redondo(0.066, 0.118, 0.084, 0.114, 0.008, 2), 32)
    cuenco = torno("cuenco", [(0.0, 0.056), (0.03, 0.058), (0.055, 0.068), (0.068, 0.088),
                              (0.07, 0.1)], 24)
    clavos = remaches([(0.094 * math.cos(TAU * k / 8 + 0.2), 0.094 * math.sin(TAU * k / 8 + 0.2), 0.113, "z")
                       for k in range(8)], 0.0095, 0.0075, 6)
    corona = unir("brasero_corona", [aro, cuenco] + clavos)
    abollar(corona, 0.0008, 60.0, 2.0)
    # El bocel de bronce del borde del cuenco (el anillo cobrizo del sprite).
    bocel = torno_cerrado("brasero_bocel",
                          [(0.068 + 0.0085 * math.cos(a), 0.116 + 0.0085 * math.sin(a))
                           for a in np.linspace(0, TAU, 8, endpoint=False)], 28)

    # Las brasas: un montón de trozos de carbón dentro del cuenco, el del medio
    # más alto. El azul dice cuánto arde cada punto: lo hondo, entre trozos.
    rng = np.random.default_rng(3)
    trozos = []
    sitios = [(0.0, 0.0, 0.118, 0.036)]
    for k in range(7):
        a = TAU * k / 7 + rng.uniform(-0.2, 0.2)
        sitios.append((0.043 * math.cos(a), 0.043 * math.sin(a), 0.098 + rng.uniform(-0.004, 0.004),
                       0.024 + rng.uniform(-0.003, 0.004)))
    for x, y, z, r in sitios:
        bm = bmesh.new()
        # Dos subdivisiones, y no una: con 80 caras por trozo el color de vértice
        # (B = cuánto arde, R = oclusión) se reparte en manchas tan grandes que
        # las brasas salían apagadas, como piedras pardas (probado en esta tanda).
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=r)
        o = nueva("trozo", bm)
        abollar(o, r * 0.45, 26.0, float(rng.uniform(0, 50)))
        mover(o, x, y, z, rz=float(rng.uniform(0, TAU)), esc=(1.0, float(rng.uniform(0.8, 1.15)), 0.72))
        trozos.append(o)
    brasas = unir("brasero_brasas", trozos)

    piezas = [rueda, corona, bocel, brasas]
    hornear(rueda, piezas, 0.06, 1.1)
    hornear(corona, piezas, 0.05, 1.2)
    hornear(bocel, piezas, 0.03, 0.8)
    # Lo que arde: el fondo entre trozos (oclusión baja) y el centro.
    def fuego(obj, ao):
        co = np.array([tuple(v.co) for v in obj.data.vertices])
        r = np.sqrt(co[:, 0] ** 2 + co[:, 1] ** 2)
        # El sombreador del ascua MULTIPLICA su calor por esto: con 0 en la
        # cresta de cada trozo sale carbón muerto. Todo arde algo; lo hondo y
        # el centro, del todo.
        return np.clip(0.78 + (1.0 - ao) * 1.2 + np.clip(1.0 - r / 0.07, 0.0, 1.0) * 0.3, 0.0, 1.0)
    hornear(brasas, piezas, 0.04, 1.4, azul=fuego)
    material(rueda, (0.45, 0.22, 0.1))
    material(corona, (0.12, 0.12, 0.14))
    material(bocel, (0.55, 0.38, 0.15))
    material(brasas, (0.9, 0.35, 0.05))
    return {o.name: o for o in piezas}


def lapida():
    # El zócalo, en dos escalones, a la medida justa del colisionador: 30 × 8 px.
    z1 = solido("zocalo1", [capsula((-0.12, 0.0), (0.12, 0.0), 0.04, 3)], 0.0, 0.024)
    mover(z1, esc=(1.0, 1.0, 1.0))
    z1 = biselar(z1, 0.005, 2, 30.0)
    z2 = solido("zocalo2", [[(-0.138, -0.034), (0.138, -0.034), (0.138, 0.034), (-0.138, 0.034)]],
                0.024, 0.042)
    z2 = biselar(z2, 0.005, 2, 30.0)
    # La losa: recta hasta arriba y rematada en arco rebajado.
    # MÁS BAJA QUE ANTES (0,168 de alto, era 0,244): desde las cámaras de juego
    # las tres lápidas quedaban justo delante de los braseros y les tapaban la
    # mitad de abajo, y el golpe en un brasero no se veía. El colisionador manda
    # en planta, no en altura: la bola (techo a 0,18) sigue dando en la cara.
    contorno = [(-0.124, 0.040), (0.124, 0.040)]
    for k in range(13):
        t = k / 12.0
        x = 0.124 - 0.248 * t
        contorno.append((x, 0.122 + 0.046 * math.sqrt(max(1.0 - (x / 0.124) ** 2, 0.0)) ** 0.8))
    losa = solido("losa", [contorno], -0.029, 0.029)
    # El contorno se dibujó en XY; la losa va de pie: se tumba al plano XZ.
    mover(losa, rx=math.pi / 2)
    losa = biselar(losa, 0.008, 2, 30.0)
    abollar(losa, 0.0022, 30.0, 4.0)
    # Una muesca de esquina, que la piedra vieja no tiene los cantos enteros.
    mella = torno("mella", [(0.0, -0.03), (0.026, -0.03), (0.026, 0.03), (0.0, 0.03)], 6)
    mover(mella, 0.128, 0.0, 0.158, rx=math.pi / 2, rz=0.3)
    mod = losa.modifiers.new("mella", "BOOLEAN")
    mod.object = mella
    mod.operation = "DIFFERENCE"
    mod.solver = "EXACT"
    aplicar(losa)
    bpy.data.objects.remove(mella)
    # La calavera en relieve: la de la fuente, aplastada de fondo y medio
    # hundida en la cara de la losa. 700 caras: con 2.600 eran 4.752 triángulos
    # por lápida para un relieve de 25 px en la cámara de juego.
    cal = calavera(0.07, 700)
    co = np.array([tuple(v.co) for v in cal.data.vertices])
    fondo = co[:, 1].max() - co[:, 1].min()
    mover(cal, esc=(1.0, 0.022 / fondo, 1.0))
    co = np.array([tuple(v.co) for v in cal.data.vertices])
    mover(cal, 0.0, -0.042 - co[:, 1].min(), 0.074)
    # Dos tibias cruzadas bajo la calavera, como en las lápidas de verdad.
    tibias = []
    for s in (-1.0, 1.0):
        t = torno("tibia", [(0.0, -0.05), (0.008, -0.048), (0.0065, -0.04), (0.0055, 0.0),
                            (0.0065, 0.04), (0.008, 0.048), (0.0, 0.05)], 8)
        mover(t, esc=(0.85, 0.5, 0.8))
        mover(t, 0.0, -0.031, 0.07, ry=s * 1.05)
        tibias.append(t)
    # Cuántos vértices son de piedra lisa: lo que va detrás (calavera y tibias)
    # se alisa entero al final (ver `alisar_desde`).
    LISOS["lapida"] = sum(len(o.data.vertices) for o in (z1, z2, losa))
    lap = unir("lapida", [z1, z2, losa, cal] + tibias)
    # La ranura del suelo: el marco de hierro por el que se hunde.
    ext = [(-0.168, -0.058), (0.168, -0.058), (0.168, 0.058), (-0.168, 0.058)]
    hue = [(-0.152, -0.043), (0.152, -0.043), (0.152, 0.043), (-0.152, 0.043)]
    ran = solido("lapida_ranura", [ext, hue], 0.0, 0.008)
    # Seis ranuras iguales a ras de suelo, en un MultiMesh: un paso de bisel.
    ran = biselar(ran, 0.0025, 1, 30.0)
    clavos = remaches([(x, y, 0.008, "z") for x in (-0.16, 0.16) for y in (-0.05, 0.05)], 0.0055, 0.004)
    ran = unir("lapida_ranura", [ran] + clavos)
    hornear(lap, [lap], 0.06, 1.2)
    hornear(ran, [ran], 0.03, 0.8)
    material(lap, (0.42, 0.4, 0.37))
    material(ran, (0.12, 0.12, 0.14))
    return {"lapida": lap, "lapida_ranura": ran}


def escudo():
    """Escudo de tablas de roble, de punta redonda (el español), de 30 px de
    ancho y 8 de grueso, que es su colisionador. El frente es −y."""
    W, ALTO, R = 0.15, 0.29, 0.15
    zc = ALTO - (ALTO - R) - 0.0  # el centro del redondo de abajo

    def contorno(d, n_lado=4, n_arco=14):
        """El perfil del escudo crecido `d` (o encogido, si d < 0), en el plano
        XZ: arriba plano, lados rectos y el fondo en medio círculo."""
        w = W + d
        r = R + d
        pts = []
        top = ALTO + d
        for k in range(n_lado + 1):          # el lado derecho, de arriba abajo
            pts.append((w, top - (top - zc) * k / n_lado))
        for k in range(1, n_arco):            # el redondo de abajo
            a = -math.pi * k / n_arco
            pts.append((r * math.cos(a), zc + r * math.sin(a)))
        for k in range(n_lado + 1):          # el lado izquierdo, de abajo arriba
            pts.append((-w, zc + (top - zc) * k / n_lado))
        for k in range(1, 8):                # el borde de arriba
            pts.append((-w + 2 * w * k / 8, top))
        return pts

    # Las tablas: cuatro, con su junta, cada una recortada por el perfil.
    tablas = []
    n = 4
    for k in range(n):
        x0 = -W + 2 * W * k / n + 0.0018
        x1 = -W + 2 * W * (k + 1) / n - 0.0018
        pts = []
        xs = np.linspace(x0, x1, 7)
        for x in xs:
            z = zc - math.sqrt(max(R * R - x * x, 0.0)) if abs(x) < R else zc
            pts.append((x, max(z, 0.0) + 0.002))
        pts += [(x1, ALTO), (x0, ALTO)]
        t = solido("tabla", [pts], -0.016, 0.016)
        mover(t, rx=math.pi / 2)
        t = biselar(t, 0.0035, 1, 30.0)
        abollar(t, 0.0012, 45.0, float(k) * 3.1)
        tablas.append(t)
    madera = unir("escudo_madera", tablas)

    # El cerco: una banda que abraza el canto, más ancha por delante.
    ext = contorno(0.006)
    dentro = contorno(-0.017)
    cerco = solido("cerco", [ext, dentro], -0.02, 0.024)
    mover(cerco, rx=math.pi / 2)
    cerco = biselar(cerco, 0.003, 1, 30.0)
    # Las bandas en cruz y la bloca del centro. ANCHAS Y CON CRESTA: con 26 mm
    # de banda plana, a la sombra de los raíles el escudo era una silueta negra
    # (gira2/piezas/05_escudos). Una banda en tejadillo (las dos caras a 30°)
    # siempre tiene una de las dos mirando a alguna luz, y la bloca, abombada y
    # grande, coge un brillo desde cualquier lado: es lo que se lee a 40 px.
    def banda(nombre, x0, z0, x1, z1):
        b = solido(nombre, [[(x0, z0), (x1, z0), (x1, z1), (x0, z1)]], 0.015, 0.021)
        mover(b, rx=math.pi / 2)
        b = biselar(b, 0.0045, 1, 30.0)
        return b
    hb = banda("banda_h", -W + 0.005, 0.184, W - 0.005, 0.218)
    vb = banda("banda_v", -0.017, 0.02, 0.017, ALTO - 0.005)
    bloca = torno("bloca", [(0.0, 0.0), (0.05, 0.0), (0.05, 0.005), (0.044, 0.01), (0.034, 0.02),
                            (0.02, 0.028), (0.0, 0.031)], 20)
    mover(bloca, 0.0, -0.016, 0.201, rx=math.pi / 2)
    # Los clavos: por el cerco y por las bandas.
    lista = []
    for k in range(len(ext)):
        if k % 4 == 0:
            x, z = contorno(-0.0055)[k]
            lista.append((x, -0.024, z, "-y"))
    for x in (-0.12, -0.08, 0.08, 0.12):
        lista.append((x, -0.023, 0.201, "-y"))
    for z in (0.05, 0.1, 0.26):
        lista.append((0.0, -0.023, z, "-y"))
    clavos = remaches(lista, 0.006, 0.0048, 6)
    herraje = unir("escudo_herraje", [cerco, hb, vb, bloca] + clavos)
    abollar(herraje, 0.0006, 70.0, 5.0)
    # Todo un poco arriba: el redondo de abajo no se mete en el suelo.
    mover(madera, z=0.008)
    mover(herraje, z=0.008)
    # Y ECHADO ATRÁS 11°: así la cara mira algo hacia arriba, a la cámara de
    # juego y a la luz, en vez de a la pared de enfrente. Gira sobre la altura
    # del centro de la bola (0,09), que es donde choca: ahí la cara no se mueve,
    # arriba se aparta 4 px y abajo se adelanta 1,5, hasta el colisionador.
    for o in (madera, herraje):
        mover(o, z=-0.09)
        mover(o, rx=-0.19)
        mover(o, z=0.09)
    piezas = [madera, herraje]
    hornear(madera, piezas, 0.05, 1.2)
    hornear(herraje, piezas, 0.04, 1.0)
    material(madera, (0.45, 0.3, 0.2))
    material(herraje, (0.12, 0.12, 0.14))
    return {"escudo_madera": madera, "escudo_herraje": herraje}


L_PALA, R_PALA = 0.64, 0.08


## LA LÁGRIMA DE LA PALA. El colisionador es una cápsula de radio R_PALA (8 px)
## a lo largo de todo el brazo; el sprite es una lágrima, ancha en el eje y fina
## en la punta. EXCEPCIÓN CONSCIENTE a «lo que choca mide lo que mide el
## colisionador» (decisión 6 del remate): la goma va de radio 10 px en el eje a
## 5 px en la punta (+2 y −3 px respecto a lo que choca). Con la regla de 1,4 px
## (de 9,4 a 6,6) seguía leyéndose como una barra, dos revisiones seguidas; a
## velocidad de juego los 3 px de la punta no se notan y la identidad sí.
## Primero fue la cápsula tal cual, con la goma del mismo ancho de punta a
## punta: un dominó, no la pala del juego (gira2/piezas/00_palas contra mesa_x4).
R_EJE, R_PUNTA = 0.10, 0.05
## Y DE LADO TAMBIÉN SE AFILA: desde las cámaras de juego lo que más se ve de la
## pala es su costado, y con el mismo alto de punta a punta el costado era un
## listón. Todo baja hacia la punta hasta un CAIDA_ALTO menos (la goma acaba a
## 0,091, a la altura del centro de la bola, que choca a 0,09: más no, o la bola
## pasaría por encima del canto). Con 0,12 desde la cámara baja aún era barra.
CAIDA_ALTO = 0.16


def afilar_alto(obj, largo, caida):
    """Aplasta la altura hacia la punta (+x): en el eje no cambia y en `largo`
    queda en (1 − caida). Es lo que hace que el costado sea una cuña."""
    malla = obj.data
    for v in malla.vertices:
        t = min(max(v.co.x / largo, 0.0), 1.0)
        v.co.z *= 1.0 - caida * t
    malla.update()
    return obj


def pala():
    # La goma: la que toca la bola, en lágrima (ver R_EJE), negra. (La goma
    # roja «del eje» que se ve desde el juego es la del POSTE que hay sobre el
    # eje de cada pala, no de la pala: se probó un cuello rojo en la pala y
    # quedaba escondido debajo del poste.)
    fuera = lagrima((0.0, 0.0), R_EJE, (L_PALA, 0.0), R_PUNTA, 12)
    dentro = lagrima((0.0, 0.0), R_EJE - 0.016, (L_PALA, 0.0), R_PUNTA - 0.016, 12)
    goma = solido("pala_goma", [fuera, dentro], 0.032, 0.108)
    goma = biselar(goma, 0.010, 2, 30.0)
    # El cuerpo: un plato de base, el alma por dentro de la goma y la TAPA, que
    # es la que remata la lágrima: va por encima del centro de la bola y por
    # dentro de la goma, así que se afila más que ella, del ancho entero en el
    # eje a 3 px de radio en la punta. Desde arriba se ve una lágrima de hierro
    # con el filo pulido, y alrededor de la punta, la goma negra.
    base = solido("base", [lagrima((0.0, 0.0), R_EJE - 0.006, (L_PALA, 0.0), R_PUNTA - 0.006, 10)],
                  0.006, 0.032)
    base = biselar(base, 0.004, 1, 30.0)
    alma = solido("alma", [lagrima((0.0, 0.0), R_EJE - 0.015, (L_PALA, 0.0), R_PUNTA - 0.015, 10)],
                  0.03, 0.11)
    tapa = solido("tapa", [lagrima((0.0, 0.0), R_EJE - 0.002, (L_PALA - 0.02, 0.0), 0.03, 14)],
                  0.104, 0.14)
    tapa = biselar(tapa, 0.012, 3, 30.0)
    # Sin subdividir: el martillado de encima lo pone el relieve del hierro de
    # la biblioteca, y subdividida la tapa sola eran mil triángulos por pala.
    abollar(tapa, 0.0012, 40.0, 6.0, solo_z=0.12)
    cuerpo = unir("pala_cuerpo", [base, alma, tapa])
    # El acero: el ANILLO del eje (el aro claro del sprite, con el tornillo
    # oscuro dentro) y la varilla de encima, que es la línea de acero del
    # sprite: más ancha y más alta que antes, para que coja un brillo a lo largo.
    arandela = torno_cerrado("arandela", perfil_redondo(0.026, 0.056, 0.134, 0.152, 0.005, 2), 28)
    cabeza = torno("tornillo", [(0.0, 0.14), (0.024, 0.14), (0.024, 0.156), (0.0, 0.156)], 6, giro=0.3)
    cabeza = biselar(cabeza, 0.003, 1, 30.0)
    varilla = solido("varilla", [capsula((0.085, 0.0), (L_PALA - 0.075, 0.0), 0.011, 4)], 0.134, 0.1495)
    varilla = biselar(varilla, 0.004, 2, 30.0)
    acero = unir("pala_acero", [arandela, cabeza, varilla])
    # La cuña, a las tres a la vez: así la varilla sigue posada en la tapa.
    for o in (cuerpo, goma, acero):
        afilar_alto(o, L_PALA + 0.05, CAIDA_ALTO)
    piezas = [cuerpo, goma, acero]
    hornear(cuerpo, piezas, 0.05, 1.1)
    hornear(goma, piezas, 0.04, 1.0)
    hornear(acero, piezas, 0.03, 0.8)
    material(cuerpo, (0.07, 0.07, 0.08))
    material(goma, (0.06, 0.03, 0.03))
    material(acero, (0.6, 0.6, 0.62))
    return {"pala_cuerpo": cuerpo, "pala_goma": goma, "pala_acero": acero}


R_TORNO, Y_EJE = 0.10, 0.14


def torno_pieza():
    # El aspa: chapa de hierro de esquinas redondas que cuelga del eje y lo
    # rebasa por arriba (gira entera). El eje va a lo largo de x; la chapa en
    # el plano xz, con el eje en el origen.
    pts = []
    w, h, rr = 0.078, 0.072, 0.024
    for cx, cz, a0 in ((w - rr, h - rr, 0.0), (-w + rr, h - rr, 90.0), (-w + rr, -h + rr, 180.0),
                       (w - rr, -h + rr, 270.0)):
        for k in range(5):
            a = math.radians(a0 + 90.0 * k / 4)
            pts.append((cx + rr * math.cos(a), cz + rr * math.sin(a)))
    chapa = solido("chapa", [pts], -0.0045, 0.0045)
    mover(chapa, rx=math.pi / 2)
    chapa = biselar(chapa, 0.002, 1, 30.0)
    # Un nervio por el canto, de refuerzo: lo que hace que se lea como forja.
    marco = solido("marco", [pts, [(x * 0.82, z * 0.8) for x, z in pts]], -0.0075, 0.0075)
    mover(marco, rx=math.pi / 2)
    marco = biselar(marco, 0.002, 1, 30.0)
    cubo = torno("cubo", [(0.0, -0.032), (0.014, -0.032), (0.016, -0.028), (0.016, 0.028),
                          (0.014, 0.032), (0.0, 0.032)], 16)
    mover(cubo, ry=math.pi / 2)
    collares = []
    for s in (-1.0, 1.0):
        c = torno_cerrado("collar", perfil_redondo(0.006, 0.021, -0.006, 0.006, 0.002, 2), 16)
        mover(c, s * 0.038, ry=math.pi / 2)
        collares.append(c)
    clavos = remaches([(x, s * 0.0075, z, "-y" if s < 0 else "y")
                       for x in (-0.056, 0.056) for z in (-0.05, 0.05) for s in (-1.0, 1.0)], 0.005, 0.004, 6)
    aspa = unir("torno_aspa", [chapa, marco, cubo] + collares + clavos)
    abollar(aspa, 0.0005, 80.0, 7.0)
    # Los soportes: placa al suelo, poste ochavado, cojinete y remate.
    sop = []
    for s in (-1.0, 1.0):
        x = s * (R_TORNO + 0.02)
        placa = solido("placa", [[(-0.026, -0.026), (0.026, -0.026), (0.026, 0.026), (-0.026, 0.026)]], 0.0, 0.012)
        placa = biselar(placa, 0.003, 2, 30.0)
        mover(placa, x)
        poste = torno("poste", [(0.0, 0.0), (0.016, 0.0), (0.016, 0.02), (0.012, 0.03), (0.011, 0.17),
                                (0.0, 0.17)], 8, giro=math.pi / 8)
        mover(poste, x)
        coj = torno("cojinete", [(0.0, -0.02), (0.022, -0.02), (0.024, -0.016), (0.024, 0.016),
                                 (0.022, 0.02), (0.0, 0.02)], 16)
        mover(coj, x, 0.0, Y_EJE, ry=math.pi / 2)
        remate = torno("remate", [(0.0, 0.165), (0.016, 0.165), (0.018, 0.175), (0.012, 0.188), (0.004, 0.195),
                                  (0.0, 0.196)], 8, giro=math.pi / 8)
        mover(remate, x)
        clv = remaches([(x + dx, dy, 0.012, "z") for dx in (-0.017, 0.017) for dy in (-0.017, 0.017)],
                       0.0045, 0.0035, 6)
        sop += [placa, poste, coj, remate] + clv
    soportes = unir("torno_soportes", sop)
    eje = torno("torno_eje", [(0.0, -R_TORNO - 0.035), (0.0055, -R_TORNO - 0.035), (0.0055, R_TORNO + 0.035),
                              (0.0, R_TORNO + 0.035)], 10)
    mover(eje, 0.0, 0.0, Y_EJE, ry=math.pi / 2)
    # El aspa se hornea en su sitio (colgando del eje) y luego se baja al origen.
    mover(aspa, 0.0, 0.0, Y_EJE)
    piezas = [aspa, soportes, eje]
    hornear(aspa, piezas, 0.03, 0.8, suelo=None)
    hornear(soportes, piezas, 0.04, 1.0)
    hornear(eje, piezas, 0.02, 0.6)
    mover(aspa, 0.0, 0.0, -Y_EJE)
    material(aspa, (0.1, 0.1, 0.12))
    material(soportes, (0.1, 0.1, 0.12))
    material(eje, (0.6, 0.6, 0.62))
    return {"torno_aspa": aspa, "torno_soportes": soportes, "torno_eje": eje}


R_POSTE = 0.11


def poste():
    goma = torno_cerrado("poste_goma", perfil_redondo(0.075, R_POSTE, 0.034, 0.128, 0.018, 3), 32)
    cuerpo = torno("poste_cuerpo", [(0.0, 0.0), (0.09, 0.0), (0.09, 0.012), (0.082, 0.02), (0.07, 0.024),
                                    (0.07, 0.08), (0.07, 0.136), (0.08, 0.142), (0.08, 0.152), (0.072, 0.16),
                                    (0.055, 0.172), (0.03, 0.18), (0.0, 0.183)], 24)
    abollar(cuerpo, 0.0018, 40.0, 8.0)
    zuncho = torno_cerrado("zuncho", perfil_redondo(0.074, 0.0835, 0.13, 0.156, 0.003, 1), 24)
    # Los remaches del zuncho miran hacia fuera: se hacen mirando a +x en el
    # origen y se giran a su sitio.
    clavos = remaches([(0.0, 0.0, 0.0, "x") for _k in range(8)], 0.0055, 0.004, 6)
    for k, o in enumerate(clavos):
        a = TAU * k / 8
        o.data.transform(Matrix.Rotation(a, 4, "Z") @ Matrix.Translation((0.0835, 0.0, 0.143)))
    arriba = remaches([(0.04 * math.cos(TAU * k / 6 + 0.3), 0.04 * math.sin(TAU * k / 6 + 0.3), 0.176, "z")
                       for k in range(6)], 0.0065, 0.0045, 6)
    tapa = unir("poste_tapa", [zuncho] + clavos + arriba)
    piezas = [goma, cuerpo, tapa]
    hornear(goma, piezas, 0.04, 1.0)
    hornear(cuerpo, piezas, 0.05, 1.2)
    hornear(tapa, piezas, 0.03, 0.8)
    material(goma, (0.55, 0.12, 0.12))
    material(cuerpo, (0.4, 0.38, 0.35))
    material(tapa, (0.12, 0.12, 0.14))
    return {"poste_goma": goma, "poste_cuerpo": cuerpo, "poste_tapa": tapa}


def goma_poste():
    p = torno("goma_poste", [(0.0, 0.0), (0.04, 0.0), (0.04, 0.012), (0.032, 0.02), (0.026, 0.024),
                             (0.026, 0.15), (0.034, 0.158), (0.036, 0.17), (0.03, 0.178), (0.0, 0.18)],
              8, giro=math.pi / 8)
    # Un paso de bisel: son doce postes iguales y con dos pasos eran 1.016
    # triángulos cada uno para un fuste de 5 px.
    p = biselar(p, 0.003, 1, 35.0)
    cab = torno("cab", [(0.0, 0.176), (0.016, 0.176), (0.016, 0.188), (0.0, 0.188)], 6)
    p = unir("goma_poste", [p, cab])
    abollar(p, 0.0007, 70.0, 9.0)
    hornear(p, [p], 0.04, 1.0)
    material(p, (0.1, 0.1, 0.12))
    return {"goma_poste": p}


def sarcofago():
    """Un sarcófago hundido en el suelo del coro, abierto: el borde a ras y lo de
    dentro, oscuro. La bola se hunde en él (la baja el núcleo). El largo va por
    −y (hacia el fondo de la mesa, la cabecera) y +y (los pies)."""
    def ataud(d):
        # cabecera, hombros y pies, crecido `d`
        pts = [(-0.11 - d, -0.21 - d), (0.11 + d, -0.21 - d), (0.172 + d, -0.07), (0.118 + d, 0.215 + d),
               (-0.118 - d, 0.215 + d), (-0.172 - d, -0.07)]
        # Se reparten puntos por cada lado para que el bisel y la abolladura tengan malla.
        out = []
        for i in range(len(pts)):
            a, b = pts[i], pts[(i + 1) % len(pts)]
            for k in range(6):
                t = k / 6
                out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
        return out
    borde = solido("brocal", [ataud(0.0), ataud(-0.034)], 0.0, 0.02)
    borde = biselar(borde, 0.006, 3, 30.0)
    abollar(borde, 0.0012, 35.0, 11.0)
    brocal = borde
    brocal.name = "sarcofago_brocal"
    # El fondo: una losa negra apenas por encima del suelo, que es lo que se ve
    # por la boca. Lleva el rescoldo en el azul: más en el centro y la cabecera.
    fondo = solido("sarcofago_fondo", [ataud(-0.03)], 0.0, 0.003)
    subdividir(fondo, 2)
    abollar(fondo, 0.0012, 30.0, 12.0)
    # Los huesos: la calavera en la cabecera y unos huesos largos sueltos.
    cal = calavera(0.06, 600)
    mover(cal, 0.0, 0.0, 0.0, rx=-1.2)
    co = np.array([tuple(v.co) for v in cal.data.vertices])
    mover(cal, 0.0, -0.13 - co[:, 1].mean(), 0.022 - co[:, 2].max())
    huesos = [cal]
    for x, y, rz in ((-0.05, 0.04, 0.5), (0.04, 0.09, -0.35), (0.0, -0.02, 1.4), (0.06, -0.06, 0.2)):
        t = torno("hueso", [(0.0, -0.045), (0.0085, -0.043), (0.006, -0.034), (0.005, 0.0),
                            (0.006, 0.034), (0.0085, 0.043), (0.0, 0.045)], 8)
        mover(t, x, y, 0.006, rz=rz, rx=math.pi / 2)
        huesos.append(t)
    huesos_o = unir("sarcofago_huesos", huesos)
    # La tapa: la misma silueta en losa, con una cruz en relieve. Se modela
    # tumbada; `piezas.gd` la pone de pie contra el rincón.
    tapa = solido("tapa", [ataud(-0.004)], 0.0, 0.034)
    tapa = biselar(tapa, 0.007, 2, 30.0)
    abollar(tapa, 0.0018, 30.0, 13.0)
    cruz_v = solido("cruz_v", [[(-0.016, -0.17), (0.016, -0.17), (0.016, 0.16), (-0.016, 0.16)]], 0.03, 0.046)
    cruz_h = solido("cruz_h", [[(-0.1, -0.1), (0.1, -0.1), (0.1, -0.068), (-0.1, -0.068)]], 0.03, 0.046)
    cruz_v = biselar(cruz_v, 0.005, 2, 30.0)
    cruz_h = biselar(cruz_h, 0.005, 2, 30.0)
    tapa = unir("sarcofago_tapa", [tapa, cruz_v, cruz_h])
    piezas = [brocal, fondo, huesos_o]
    hornear(brocal, piezas, 0.06, 1.1)
    def rescoldo(obj, ao):
        co = np.array([tuple(v.co) for v in obj.data.vertices])
        return np.clip(1.0 - np.sqrt(co[:, 0] ** 2 + (co[:, 1] + 0.03) ** 2) / 0.17, 0.0, 1.0) ** 1.5
    hornear(fondo, piezas, 0.08, 1.6, azul=rescoldo)
    hornear(huesos_o, piezas, 0.04, 1.2)
    hornear(tapa, [tapa], 0.05, 1.0)
    material(brocal, (0.42, 0.4, 0.37))
    material(fondo, (0.05, 0.04, 0.04))
    material(huesos_o, (0.8, 0.72, 0.58))
    material(tapa, (0.42, 0.4, 0.37))
    return {"sarcofago_brocal": brocal, "sarcofago_fondo": fondo, "sarcofago_huesos": huesos_o,
            "sarcofago_tapa": tapa}


def lanzador():
    """El ariete del carril. Su frente (lo que toca la bola) está en y = 0 y
    mira a +y (al fondo de la mesa); todo lo demás va hacia −y (hacia el
    jugador). El eje del ariete va a la altura del centro de la bola."""
    zc = 0.09
    cab = torno("cabeza", [(0.0, 0.0), (0.04, 0.0), (0.05, 0.006), (0.052, 0.016), (0.052, 0.05),
                           (0.058, 0.054), (0.058, 0.066), (0.048, 0.07), (0.046, 0.085), (0.034, 0.092),
                           (0.0, 0.094)], 16)
    # Se modeló a lo largo de z: se tumba para que vaya por −y, frente en y = 0.
    mover(cab, rx=math.pi / 2)
    mover(cab, 0.0, 0.0, zc)
    cab = biselar(cab, 0.003, 2, 35.0)
    # Seis remaches en el zuncho, mirando hacia fuera del eje.
    clv = remaches([(0.0, 0.0, 0.0, "z") for _k in range(6)], 0.005, 0.004, 6)
    for k, o in enumerate(clv):
        a = TAU * (k + 0.5) / 6
        o.data.transform(Matrix.Translation((0.0, -0.06, zc)) @ Matrix.Rotation(-a, 4, "Y")
                         @ Matrix.Translation((0.0, 0.0, 0.057)))
    cabeza = unir("lanzador_cabeza", [cab] + clv)
    abollar(cabeza, 0.0006, 70.0, 14.0)
    vas = torno("lanzador_vastago", [(0.0, 0.0), (0.011, 0.0), (0.011, 0.44), (0.02, 0.445), (0.022, 0.46),
                                     (0.02, 0.475), (0.0, 0.48)], 12)
    mover(vas, rx=math.pi / 2)
    mover(vas, 0.0, -0.08, zc)
    # El muelle: una hélice de alambre, 0,26 de largo, desde y = 0 hacia −y.
    # SECCIÓN REDONDA DE VERDAD. Antes el marco de cada anillo salía de cruzar la
    # tangente con z, y la hélice gira en el plano XZ: arriba y abajo de cada
    # vuelta la tangente ES casi z, el cruce se quedaba en nada y el anillo se
    # retorcía y se aplastaba. De cerca eran cintas planas con el borde mordido
    # (revisión técnica, z_tope_lanzador). Ahora el marco es el RADIO de la
    # hélice, que nunca se anula; ocho lados (a 45°, `alisar` los deja lisos;
    # con seis, a 60°, salían aristas vivas) y un alambre algo más grueso.
    vueltas, largo, rh, ra = 7.0, 0.26, 0.032, 0.0078
    n = int(vueltas * 14)
    angs = [TAU * vueltas * i / n for i in range(n + 1)]
    pts = [Vector((rh * math.cos(a), -largo * i / n, rh * math.sin(a))) for i, a in enumerate(angs)]
    bm = bmesh.new()
    anillos = []
    lados = 8
    for i, p in enumerate(pts):
        tg = (pts[min(i + 1, n)] - pts[max(i - 1, 0)]).normalized()
        lat = Vector((math.cos(angs[i]), 0.0, math.sin(angs[i])))
        arr = tg.cross(lat).normalized()
        anillos.append([bm.verts.new(p + (lat * math.cos(TAU * k / lados) + arr * math.sin(TAU * k / lados)) * ra)
                        for k in range(lados)])
    for a, b in zip(anillos[:-1], anillos[1:]):
        for k in range(lados):
            cara(bm, [a[k], a[(k + 1) % lados], b[(k + 1) % lados], b[k]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    muelle = nueva("lanzador_muelle", bm)
    mover(muelle, 0.0, 0.0, zc)
    # El soporte: una placa de hierro atravesada por el vástago, con su brida.
    placa = solido("placa", [[(-0.085, -0.012), (0.085, -0.012), (0.085, 0.012), (-0.085, 0.012)]], 0.0, 0.17)
    placa = biselar(placa, 0.004, 2, 30.0)
    brida = torno("brida", [(0.0, 0.0), (0.042, 0.0), (0.042, 0.016), (0.03, 0.022), (0.0, 0.022)], 16)
    mover(brida, rx=-math.pi / 2)
    mover(brida, 0.0, 0.012, zc)
    clv2 = remaches([(x, 0.012, z, "y") for x in (-0.065, 0.065) for z in (0.03, 0.14)], 0.006, 0.0045, 6)
    soporte = unir("lanzador_soporte", [placa, brida] + clv2)
    # Su frente (la cara de la brida) queda en y = 0: `piezas.gd` la pone al
    # fondo del carril y estira el muelle hasta ella.
    mover(soporte, 0.0, -0.034, 0.0)
    abollar(soporte, 0.0006, 60.0, 15.0)
    piezas = [cabeza, vas, muelle, soporte]
    hornear(cabeza, piezas, 0.04, 1.0)
    hornear(vas, piezas, 0.03, 0.8)
    # Sin desgaste de canto (G = 0): en un alambre de 8 mm todo es canto, y el
    # filo pelado se comía la sección entera en dientes claros.
    hornear(muelle, [muelle, vas], 0.02, 0.6, ganancia_canto=0.0)
    hornear(soporte, piezas, 0.04, 1.0)
    for o, c in ((cabeza, (0.1, 0.1, 0.12)), (vas, (0.6, 0.6, 0.62)), (muelle, (0.4, 0.4, 0.42)),
                 (soporte, (0.1, 0.1, 0.12))):
        material(o, c)
    return {"lanzador_cabeza": cabeza, "lanzador_vastago": vas, "lanzador_muelle": muelle,
            "lanzador_soporte": soporte}


# ------------------------------------------------------------------- el render


def renders(carpeta, objs):
    escena = bpy.context.scene
    escena.render.engine = "BLENDER_WORKBENCH"
    escena.display.shading.light = "STUDIO"
    escena.display.shading.color_type = "VERTEX"
    escena.render.resolution_x = 1600
    escena.render.resolution_y = 900
    cam_d = bpy.data.cameras.new("cam")
    cam_d.lens = 50
    cam = bpy.data.objects.new("cam", cam_d)
    escena.collection.objects.link(cam)
    escena.camera = cam
    co = np.array([tuple(o.matrix_world @ v.co) for o in objs for v in o.data.vertices])
    lo, hi = co.min(0), co.max(0)
    c = (lo + hi) * 0.5
    ancho = max(hi[0] - lo[0], hi[1] - lo[1])
    cam.location = Vector((c[0], c[1] - ancho * 1.1, c[2] + ancho * 0.9))
    cam.rotation_euler = (Vector((c[0], c[1], c[2])) - cam.location).to_track_quat("-Z", "Y").to_euler()
    os.makedirs(carpeta, exist_ok=True)
    escena.render.filepath = os.path.join(carpeta, "piezas_blender.png")
    bpy.ops.render.render(write_still=True)


# --------------------------------------------------------------------- montaje


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    grupos = [brasero(), lapida(), escudo(), pala(), torno_pieza(), poste(), goma_poste(), sarcofago(),
              lanzador()]
    # Repartidos en fila (solo para mirar el GLB: Godot coge las mallas).
    x = 0.0
    todos = []
    for g in grupos:
        for o in g.values():
            o.location = (x, 0.0, 0.0)
            alisar(o)
            todos.append(o)
        x += 0.75
    total = 0
    for o in todos:
        t = triangulos(o)
        total += t
        co = np.array([tuple(v.co) for v in o.data.vertices])
        print("PIEZAS %-18s %6d tri  x[%.3f %.3f] y[%.3f %.3f] z[%.3f %.3f]" % (
            o.name, t, co[:, 0].min(), co[:, 0].max(), co[:, 1].min(), co[:, 1].max(),
            co[:, 2].min(), co[:, 2].max()))
    print("PIEZAS total: %d triángulos" % total)
    os.makedirs(os.path.dirname(os.path.abspath(SALIDA)), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=os.path.abspath(SALIDA), export_format="GLB", use_selection=False,
        export_yup=True, export_apply=False, export_normals=True, export_tangents=False,
        export_materials="EXPORT", export_vertex_color="ACTIVE",
        export_all_vertex_colors=False, export_active_vertex_color_when_no_material=True,
        export_animations=False, export_skins=False, export_morph=False)
    print("PIEZAS guardado en", os.path.abspath(SALIDA))
    if VISTAS:
        renders(VISTAS, todos)
        print("PIEZAS vistas en", VISTAS)


main()
