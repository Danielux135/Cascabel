# atrezzo_modelos.py — EL ATREZZO DE LA CRIPTA, modelado por guion: la campana
# mayor con su yugo y su viga, antorchas, braseros, velas, cadenas, gárgolas,
# huesos, barriles y cajas.
#
#   python cripta3d/herramientas/blender3d.py cripta3d/blender/atrezzo_modelos.py -- cripta3d/modelos/atrezzo_piezas.glb
#          [--vistas C:/carpeta/temporal]    además deja renders de Workbench para mirarlas
#
# QUÉ SALE. Un GLB con cada pieza partida en los trozos que llevan material
# distinto o que se mueven por su cuenta, como objetos SEPARADOS y con nombre.
# `cripta3d/mundo/atrezzo.gd` los busca por ese nombre, coge SOLO la malla (en
# el GLB van repartidos en fila para poder mirarlos) y le pone el material de
# la biblioteca. Lo que se repite (velas, eslabones) sale una vez y se reparte
# en Godot con MultiMesh.
#
#   LA CAMPANA (origen en el EJE de giro; Godot lo pone en (1,60; 1,95; 7,42))
#   viga             la viga de roble de la que cuelga, con su travesaño (madera)
#   viga_herraje     abrazaderas, horquillas, cojinetes y las armellas de las
#                    cadenas que la sostienen (hierro). Fijo
#   yugo             el yugo de la campana (madera; voltea con ella)
#   yugo_herraje     sus bridas, pernos y muñones (hierro; voltea)
#   campana          el bronce: perfil de campana de verdad, asas, tres cenefas
#                    de filetes y ocho calaveras en relieve en la cintura
#   campana_brasa_0..2   el relleno de las tres cenefas: lo que se enciende de
#                    ascua según la carga (0 la del labio, 2 la del hombro)
#   badajo           el badajo (hierro), con el origen en SU eje, que va 0,15
#                    por debajo del de la campana
#   ANTORCHA (origen en la cara del muro, el frente hacia −y)
#   antorcha_hierro  placa remachada, brazo con voluta y la cesta de barras
#   antorcha_brea    el trapo con brea dentro de la cesta (carbón que arde)
#   BRASEROS (origen en el suelo)
#   brasero_cuenco   el cuenco forjado con su bocel y sus remaches; fondo en z = 0
#   brasero_brasas   el montón de brasas del cuenco (ascua; B = cuánto arde)
#   brasero_patas    cuatro patas de garra: el cuenco va encima a z = 0,10
#   brasero_pie      el trípode alto de la sala: el cuenco va a z = 0,90
#   candelabro       candelabro de pie de cinco brazos (hierro)
#   VELAS (origen en la base)
#   vela_0..2        tres velas de cera con chorretones (B = la luz que les
#                    llega de la llama, por dentro)
#   cera_charco      el charco de cera de un racimo
#   CADENAS
#   eslabon          un eslabón, a lo largo de z (Godot: y)
#   gancho           el gancho del extremo, colgando del origen
#   LO DEMÁS
#   gargola          mascarón de piedra en su medallón (el frente hacia −y)
#   gargola_ojos     las dos ascuas de las cuencas
#   huesos           un montón de huesos con dos calaveras (origen en el suelo)
#   calavera         una calavera suelta, para repisas y hornacinas
#   barril_madera / barril_aros     el barril
#   caja_madera / caja_herraje      la caja
#
# EJES. Se modela en ejes de Blender (z arriba) pensando en Godot: x es x, la
# altura es z, y el FRENTE de cada pieza (+z en Godot) es −y aquí. El
# exportador hace el giro.
#
# COLOR DE VÉRTICE (la convención de la cripta): R oclusión, horneada lanzando
# rayos contra la pieza y sus vecinas; G canto, de lo convexa que es la malla;
# B libre (cuánto arde, cuánta luz le llega a la cera).
import math
import os
import random
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector, noise
from mathutils.bvhtree import BVHTree

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SALIDA = ARGV[0] if ARGV and not ARGV[0].startswith("--") else "cripta3d/modelos/atrezzo_piezas.glb"
VISTAS = ""
for _i, _a in enumerate(ARGV):
    if _a == "--vistas" and _i + 1 < len(ARGV):
        VISTAS = ARGV[_i + 1]

AQUI = os.path.dirname(os.path.abspath(__file__))
CALAVERA = os.path.join(AQUI, "fuentes", "calavera_ia.glb")
TAU = math.tau
AZAR = random.Random(1931)

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


def caja(nombre, x0, x1, y0, y1, z0, z1):
    bm = bmesh.new()
    vs = [bm.verts.new((x, y, z)) for z in (z0, z1) for y in (y0, y1) for x in (x0, x1)]
    for idx in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
        cara(bm, [vs[i] for i in idx])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return nueva(nombre, bm)


def torno(nombre, perfil, seg, giro=0.0, radio_de=None, tapas=True):
    """Superficie de revolución alrededor de z. `perfil` = [(r, z)]; un r = 0 en
    un extremo cierra con un vértice. `radio_de(r, z, ang)` puede deformar cada
    punto (las duelas de un barril)."""
    bm = bmesh.new()
    anillos = []
    for r, z in perfil:
        if r < 1e-6:
            anillos.append([bm.verts.new((0.0, 0.0, z))])
        else:
            fila = []
            for k in range(seg):
                a = giro + TAU * k / seg
                rr = radio_de(r, z, a) if radio_de else r
                fila.append(bm.verts.new((rr * math.cos(a), rr * math.sin(a), z)))
            anillos.append(fila)
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
    if tapas and len(anillos[0]) > 1:
        cara(bm, list(reversed(anillos[0])))
    if tapas and len(anillos[-1]) > 1:
        cara(bm, anillos[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return nueva(nombre, bm)


def torno_cerrado(nombre, perfil, seg, radio_de=None):
    """Revolución de un perfil CERRADO (un anillo, un aro): cose el último con
    el primero. `radio_de(r, z, ang)` puede deformar cada punto (las duelas de
    un barril)."""
    bm = bmesh.new()
    anillos = []
    for r, z in perfil:
        fila = []
        for k in range(seg):
            a = TAU * k / seg
            rr = radio_de(r, z, a) if radio_de else r
            fila.append(bm.verts.new((rr * math.cos(a), rr * math.sin(a), z)))
        anillos.append(fila)
    m = len(anillos)
    for i in range(m):
        a = anillos[i]
        b = anillos[(i + 1) % m]
        for k in range(seg):
            k2 = (k + 1) % seg
            cara(bm, [a[k], a[k2], b[k2], b[k]])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return nueva(nombre, bm)


def perfil_redondo(r0, r1, z0, z1, radio, pasos=3):
    """El perfil (r, z) de un aro de sección rectangular con las esquinas
    redondeadas (va por fuera de abajo arriba y vuelve por dentro)."""
    pts = []
    esquinas = [(r1 - radio, z0 + radio, -90.0, 0.0), (r1 - radio, z1 - radio, 0.0, 90.0),
                (r0 + radio, z1 - radio, 90.0, 180.0), (r0 + radio, z0 + radio, 180.0, 270.0)]
    for cx, cz, a0, a1 in esquinas:
        for k in range(pasos + 1):
            a = math.radians(a0 + (a1 - a0) * k / pasos)
            pts.append((cx + radio * math.cos(a), cz + radio * math.sin(a)))
    return pts


def tubo(nombre, pts, r, lados=8, cerrado=False, radios=None, cuadrado=False, tapas=True):
    """Un tubo a lo largo de una polilínea, con marcos de transporte paralelo
    (no se retuerce). `radios` da un radio por punto; `cuadrado` hace barra de
    forja de sección cuadrada con los cantos matados."""
    pts = [Vector(p) for p in pts]
    n = len(pts)
    if radios is None:
        radios = [r] * n
    tang = []
    for i in range(n):
        if cerrado:
            t = pts[(i + 1) % n] - pts[(i - 1) % n]
        else:
            t = pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]
        tang.append(t.normalized())
    ref = Vector((0, 0, 1)) if abs(tang[0].z) < 0.9 else Vector((1, 0, 0))
    u = tang[0].cross(ref).normalized()
    marcos = []
    for i in range(n):
        if i > 0:
            u = u - tang[i] * u.dot(tang[i])
            if u.length < 1e-8:
                u = tang[i].orthogonal()
            u.normalize()
        v = tang[i].cross(u).normalized()
        marcos.append((u, v))
    if cuadrado:
        # Un cuadrado de lado 2·r con las cuatro esquinas achaflanadas.
        seccion = [(1.0, -0.72), (1.0, 0.72), (0.72, 1.0), (-0.72, 1.0),
                   (-1.0, 0.72), (-1.0, -0.72), (-0.72, -1.0), (0.72, -1.0)]
    else:
        seccion = [(math.cos(TAU * k / lados), math.sin(TAU * k / lados)) for k in range(lados)]
    bm = bmesh.new()
    anillos = []
    for i in range(n):
        u, v = marcos[i]
        anillos.append([bm.verts.new(pts[i] + (u * sx + v * sy) * radios[i]) for sx, sy in seccion])
    m = len(seccion)
    tramos = n if cerrado else n - 1
    for i in range(tramos):
        a = anillos[i]
        b = anillos[(i + 1) % n]
        for k in range(m):
            cara(bm, [a[k], a[(k + 1) % m], b[(k + 1) % m], b[k]])
    if not cerrado and tapas:
        cara(bm, list(reversed(anillos[0])))
        cara(bm, anillos[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return nueva(nombre, bm)


def voluta(desde, d, radio, n):
    """La voluta de un pie de forja: desde `desde` baja hacia fuera (en la
    dirección horizontal `d`), apoya en el suelo y se enrosca hacia dentro. No
    incluye el punto de partida."""
    arriba = Vector((0, 0, 1))
    c = Vector(desde) - arriba * radio
    pts = []
    for j in range(1, n + 1):
        t = j / n
        ang = t * TAU * 0.85
        rr = radio * (1.0 - 0.5 * t)
        pts.append(c + d * (rr * math.sin(ang)) + arriba * (rr * math.cos(ang)))
    return pts


def esfera(nombre, r, sub=2, centro=(0, 0, 0), escala=(1, 1, 1)):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=r)
    for v in bm.verts:
        v.co = Vector((v.co.x * escala[0] + centro[0], v.co.y * escala[1] + centro[1], v.co.z * escala[2] + centro[2]))
    return nueva(nombre, bm)


def aplicar(obj):
    grafo = bpy.context.evaluated_depsgraph_get()
    vieja = obj.data
    nueva_m = bpy.data.meshes.new_from_object(obj.evaluated_get(grafo))
    obj.modifiers.clear()
    obj.data = nueva_m
    bpy.data.meshes.remove(vieja)
    return obj


def biselar(obj, ancho, segs=2, angulo=30.0):
    mod = obj.modifiers.new("bisel", "BEVEL")
    mod.width = ancho
    mod.segments = segs
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(angulo)
    mod.miter_outer = "MITER_ARC"
    return aplicar(obj)


def subdividir(obj, cortes=1):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges, cuts=cortes, use_grid_fill=True)
    bm.to_mesh(obj.data)
    bm.free()
    return obj


def abollar(obj, amplitud, escala, semilla=0.0):
    """La superficie no es perfecta: mueve cada vértice por su normal con un
    ruido suave. Es lo que separa una pieza forjada de una de ordenador."""
    malla = obj.data
    malla.update()
    for v in malla.vertices:
        p = Vector(v.co) * escala + Vector((semilla, semilla * 1.7, semilla * 0.3))
        v.co = v.co + v.normal * (noise.noise(p) * amplitud)
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


def matriz(obj, m):
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


def soldar(obj, dist=0.0005):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=dist)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    return obj


def reducir(obj, caras):
    ahora = len(obj.data.polygons)
    if ahora > caras:
        mod = obj.modifiers.new("reducir", "DECIMATE")
        mod.ratio = caras / ahora
        mod.use_collapse_triangulate = True
        aplicar(obj)
    return obj


def alisar(obj, angulo=50.0):
    malla = obj.data
    malla.shade_smooth()
    try:
        malla.set_sharp_from_angle(angle=math.radians(angulo))
    except Exception:
        pass
    malla.update()


def remaches(lista, r, alto, seg=8):
    """Cabezas de remache en (x, y, z, normal): cúpulas bajas mirando hacia la
    normal que se les dé (un Vector). Seis lados y tres anillos como mucho: un
    remache mide un centímetro, y con ocho lados y cinco anillos cada uno eran
    80 triángulos (el herraje del yugo, con 18 remaches, pasaba de 4.900)."""
    partes = []
    seg = min(seg, 6)
    perfil = [(r * 0.98, -alto * 0.6), (r, 0.0)] + [(r * math.cos(a), alto * math.sin(a))
                                                      for a in np.linspace(0.6, math.pi / 2, 2)]
    perfil[-1] = (0.0, alto)
    for x, y, z, eje in lista:
        o = torno("remache", perfil, seg)
        giro = Vector((0, 0, 1)).rotation_difference(Vector(eje).normalized()).to_matrix().to_4x4()
        matriz(o, Matrix.Translation((x, y, z)) @ giro)
        partes.append(o)
    return partes


def metabolas(nombre, elementos, resol=0.005, umbral=0.6):
    """Una forma orgánica con metabolas, ya convertida en malla soldada."""
    mb = bpy.data.metaballs.new("mb_" + nombre)
    mb.resolution = resol
    mb.render_resolution = resol
    mb.threshold = umbral
    ob = bpy.data.objects.new("mb_" + nombre, mb)
    bpy.context.scene.collection.objects.link(ob)
    for e in elementos:
        el = mb.elements.new()
        el.type = e.get("tipo", "BALL")
        el.co = e["co"]
        el.radius = e["r"]
        if "tam" in e:
            el.size_x, el.size_y, el.size_z = e["tam"]
        if "rot" in e:
            el.rotation = e["rot"]
        el.use_negative = e.get("neg", False)
        el.stiffness = e.get("rigidez", 2.0)
    bpy.context.view_layer.update()
    grafo = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(grafo))
    bpy.data.objects.remove(ob)
    bpy.data.metaballs.remove(mb)
    o = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(o)
    return soldar(o, 0.0003)


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
        verts += [(-4.0, -4.0, suelo), (4.0, -4.0, suelo), (4.0, 4.0, suelo), (-4.0, 4.0, suelo)]
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


def coords(obj):
    n = len(obj.data.vertices)
    co = np.zeros(n * 3)
    obj.data.vertices.foreach_get("co", co)
    return co.reshape(n, 3)


def hornear(obj, vecinas, radio, fuerza=1.0, suelo=0.0, ganancia_canto=3.0, azul=None, piso=0.12):
    """R oclusión contra la pieza ENTERA (`vecinas`, que la incluye) y el suelo;
    G canto; B lo que se pida (una función de las coordenadas)."""
    arbol = arbol_de(vecinas, suelo)
    ao = oclusion(obj, arbol, radio, fuerza)
    vec = vecinos(obj)
    ao = suavizar(ao, vec, 1)
    g = suavizar(np.clip(canto(obj, vec) * ganancia_canto, 0.0, 1.0), vec, 1)
    b = np.zeros(len(ao)) if azul is None else np.asarray(azul(coords(obj), ao), dtype=np.float64)
    pintar(obj, piso + (1.0 - piso) * ao, g, b)


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


BRONCE = (0.45, 0.33, 0.14)
HIERRO = (0.12, 0.12, 0.14)
MADERA = (0.35, 0.25, 0.2)
PIEDRA = (0.35, 0.34, 0.31)
HUESO = (0.75, 0.68, 0.55)
CERA = (0.85, 0.8, 0.68)
ASCUA = (1.0, 0.45, 0.1)
CARBON = (0.05, 0.05, 0.05)

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
    soldar(obj, 0.002)
    co = coords(obj)
    lo, hi = co.min(0), co.max(0)
    centro = (lo + hi) * 0.5
    esc = alto / (hi[2] - lo[2])
    obj.data.transform(Matrix.Diagonal((esc, esc, esc, 1.0))
                       @ Matrix.Translation((-centro[0], -centro[1], -lo[2])))
    obj.data.update()
    # ANTES DE REDUCIR, UN REMALLADO DE VÓXELES. La malla de la IA tiene
    # decenas de miles de caras, agujeros y trozos sueltos, y el diezmado a
    # pelo hasta 600 caras la dejaba en papel arrugado: triángulos enormes y
    # normales cruzadas (se vio en los renders del 21-nov). Con un vóxel de 1/30
    # del alto sale una piel cerrada y limpia, y esa sí aguanta el diezmado.
    mod = obj.modifiers.new("remallar", "REMESH")
    mod.mode = "VOXEL"
    mod.voxel_size = alto / 30.0
    mod.adaptivity = 0.0
    aplicar(obj)
    reducir(obj, caras)
    obj.name = "calavera_tmp"
    return obj


# ============================================================ LA CAMPANA MAYOR
#
# Todo con el origen en el EJE de giro, que en Godot va a (1,60; 1,95; 7,42).
# El eje corre a lo largo de y aquí (z en Godot): la campana voltea de lado a
# lado, que es como se ve desde la cámara de juego.

Z_BOCA = -0.70
# Las tres cenefas: dónde va el centro de cada una (0 labio, 1 cintura, 2 hombro).
CENEFAS = [-0.615, -0.470, -0.205]
MEDIA_CENEFA = 0.019
Z_CALAVERAS = -0.340


def _perfil_base():
    """El perfil exterior de una campana de bronce de verdad (radio según la
    altura): labio grueso y acampanado, cintura casi recta, hombro redondo."""
    ctrl = [(-0.700, 0.300), (-0.660, 0.291), (-0.620, 0.271), (-0.580, 0.246), (-0.540, 0.224),
            (-0.500, 0.207), (-0.450, 0.192), (-0.400, 0.182), (-0.340, 0.175), (-0.280, 0.172),
            (-0.230, 0.171), (-0.190, 0.167), (-0.165, 0.157)]
    zs = [c[0] for c in ctrl]
    rs = [c[1] for c in ctrl]

    def r(z):
        return float(np.interp(z, zs, rs))
    return r


def _bulto(z, zc, ancho, alto):
    return alto * math.exp(-((z - zc) / ancho) ** 2)


# LOS LADOS de la campana y de sus cenefas (tienen que ser los mismos: la brasa
# va un pelo por fuera del fondo del surco, y con lados distintos las cuerdas no
# coinciden y el bronce la atraviesa).
LADOS_CAMPANA = 32


def _alturas_campana():
    """Las alturas del perfil de fuera, ADAPTATIVAS. Antes era un punto cada
    2,5 mm de arriba abajo (212 anillos × 64 lados: 44.728 triángulos, la malla
    más gorda de la escena para algo que en la cámara de juego mide 60 px). Los
    filetes de las cenefas sí necesitan puntos juntos —son bultos de 3,5 mm—,
    pero la cintura lisa no: aquí van finos solo donde hay forma."""
    finos = []
    for zc in CENEFAS:
        for f in (zc - MEDIA_CENEFA - 0.004, zc + MEDIA_CENEFA + 0.004):
            finos += [f - 0.006, f, f + 0.006]
        finos += [zc - MEDIA_CENEFA + 0.0015, zc, zc + MEDIA_CENEFA - 0.0015]
    finos += [-0.695, -0.688, -0.681]
    gruesos = [z for z in np.arange(-0.67, -0.166, 0.03)
               if min(abs(z - f) for f in finos) > 0.006]
    return sorted(finos + gruesos + [-0.166])


def campana_cuerpo():
    base = _perfil_base()

    def exterior(z):
        r = base(z)
        for zc in CENEFAS:
            # Dos filetes salientes y el surco entre ellos, donde va la brasa.
            r += _bulto(z, zc - MEDIA_CENEFA - 0.004, 0.0035, 0.0065)
            r += _bulto(z, zc + MEDIA_CENEFA + 0.004, 0.0035, 0.0065)
            if abs(z - zc) < MEDIA_CENEFA:
                r -= 0.0035
        # El cordón del labio.
        r += _bulto(z, -0.688, 0.006, 0.006)
        return r

    def grueso(z):
        return float(np.interp(z, [-0.70, -0.66, -0.55, -0.40, -0.20, -0.16],
                               [0.024, 0.034, 0.024, 0.017, 0.018, 0.020]))

    fuera = [(0.300, -0.700)] + [(exterior(z), z) for z in _alturas_campana()]
    # El hombro, la corona y el agujero del badajo (lo tapa su argolla).
    fuera += [(0.150, -0.152), (0.132, -0.142), (0.105, -0.136), (0.06, -0.133), (0.016, -0.132)]
    dentro = [(0.016, -0.156), (0.07, -0.158), (0.118, -0.165), (0.140, -0.180)]
    # Por dentro casi no se ve: un punto cada 5 cm.
    dentro += [(base(z) - grueso(z), z) for z in reversed(list(np.arange(-0.690, -0.19, 0.05)))]
    # La boca: el canto de abajo, redondeado.
    dentro += [(0.274, -0.698), (0.282, -0.7015), (0.292, -0.7015)]
    perfil = fuera + dentro
    cuerpo = torno_cerrado("campana", perfil, LADOS_CAMPANA)

    # LAS ASAS de la corona: cuatro medias argollas que la atan al yugo, y el
    # tejuelo del centro.
    asas = []
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        d = Vector((math.cos(a), math.sin(a), 0.0))
        pts = []
        for j in range(9):
            t = math.pi * j / 8
            pts.append(d * (0.055 + 0.038 * math.cos(t)) * -1.0 + d * 0.11 + Vector((0, 0, -0.136 + 0.07 * math.sin(t))))
        asas.append(tubo("asa", pts, 0.012, 6))
    tej = torno("tejuelo", [(0.0, -0.137), (0.05, -0.137), (0.046, -0.112), (0.03, -0.098), (0.0, -0.094)], 12)

    # LA CENEFA DE CALAVERAS, en relieve en la cintura. 130 caras cada una: miden
    # 5 cm y se leen por la silueta y las órbitas, no por el detalle.
    cal = calavera(0.05, 130)
    relieves = []
    for k in range(8):
        a = TAU * (k + 0.5) / 8
        c = copia(cal, "cal_%d" % k)
        r0 = base(Z_CALAVERAS) - 0.006
        m = Matrix.Translation((r0 * math.cos(a), r0 * math.sin(a), Z_CALAVERAS - 0.025)) \
            @ Matrix.Rotation(a + math.pi / 2, 4, "Z") @ Matrix.Rotation(math.radians(-6.0), 4, "X") \
            @ Matrix.Diagonal((1.0, 0.75, 1.0, 1.0))
        matriz(c, m)
        relieves.append(c)
    bpy.data.objects.remove(cal)
    todo = unir("campana", [cuerpo, tej] + asas + relieves)
    abollar(todo, 0.0007, 40.0, 3.0)

    # LAS BRASAS DE LAS CENEFAS: una banda en cada surco, un pelo por fuera del
    # fondo del surco y por dentro de los filetes.
    brasas = []
    for i, zc in enumerate(CENEFAS):
        z0, z1 = zc - MEDIA_CENEFA, zc + MEDIA_CENEFA
        pf = [(base(z0) - 0.004, z0 + 0.0005), (base(z0) - 0.0012, z0 + 0.003)]
        pf += [(base(zc) - 0.0012, zc)]
        pf += [(base(z1) - 0.0012, z1 - 0.003), (base(z1) - 0.004, z1 - 0.0005)]
        # Sin tapas: desde la cenital la campana se esconde y quedan solo estos
        # aros, y con tapa eran discos que tapaban el brasero de arriba.
        b = torno("campana_brasa_%d" % i, [(pf[0][0] - 0.002, pf[0][1])] + pf + [(pf[-1][0] - 0.002, pf[-1][1])],
                  LADOS_CAMPANA, tapas=False)
        brasas.append(b)
    return todo, brasas


def badajo():
    """El badajo, con el origen en su eje (que va 0,15 por debajo del de la
    campana): argolla, vástago, la pera que golpea y la cola."""
    perfil = [(0.0, -0.545), (0.012, -0.540), (0.018, -0.52), (0.016, -0.50), (0.026, -0.485),
              (0.040, -0.465), (0.045, -0.445), (0.043, -0.425), (0.034, -0.405), (0.020, -0.39),
              (0.013, -0.37), (0.011, -0.20), (0.010, -0.06), (0.014, -0.035), (0.014, -0.02), (0.0, -0.018)]
    cuerpo = torno("badajo", perfil, 10)
    arg = []
    for j in range(11):
        t = TAU * j / 10
        arg.append((0.0, 0.017 * math.sin(t), 0.0 + 0.017 * math.cos(t) - 0.002))
    anillo = tubo("argolla", arg[:-1], 0.005, 5, cerrado=True)
    b = unir("badajo", [cuerpo, anillo])
    abollar(b, 0.0006, 60.0, 5.0)
    return b


def yugo():
    """El yugo: el madero de roble que lleva la campana y voltea con ella, con
    sus bridas de hierro, los pernos y los muñones."""
    madero = caja("yugo", -0.068, 0.068, -0.235, 0.235, -0.066, 0.074)
    subdividir(madero, 3)
    madero = biselar(madero, 0.012, 2, 30.0)
    # Los extremos van achaflanados por abajo, como en los yugos de verdad.
    for v in madero.data.vertices:
        if abs(v.co.y) > 0.15 and v.co.z < 0:
            v.co.z += (abs(v.co.y) - 0.15) * 0.45 * (-v.co.z / 0.066)
    abollar(madero, 0.002, 18.0, 1.0)
    herr = []
    # Dos bridas en U que abrazan el yugo y bajan a las asas.
    for y in (-0.10, 0.10):
        pl = []
        for x0, x1, z0, z1 in ((-0.080, -0.068, -0.15, 0.074), (0.068, 0.080, -0.15, 0.074),
                               (-0.080, 0.080, 0.074, 0.086)):
            pl.append(caja("pl", x0, x1, y - 0.016, y + 0.016, z0, z1))
        for p in pl:
            subdividir(p, 1)
        br = biselar(unir("brida", pl), 0.003, 1, 30.0)
        herr.append(br)
        herr += remaches([(sx * 0.080, y, z, (sx, 0, 0)) for sx in (-1, 1) for z in (-0.02, 0.04)], 0.008, 0.005, 8)
        herr += remaches([(0.0, y, 0.086, (0, 0, 1))], 0.009, 0.005, 8)
    # Las tapas de los extremos y los muñones (el eje sobre el que voltea).
    for sy in (-1, 1):
        tapa = caja("tapa", -0.072, 0.072, sy * 0.235 - 0.006, sy * 0.235 + 0.006, -0.05, 0.07)
        herr.append(biselar(tapa, 0.003, 1, 30.0))
        mun = torno("munon", [(0.0, 0.0), (0.026, 0.0), (0.026, 0.012), (0.018, 0.016), (0.018, 0.075),
                              (0.014, 0.08), (0.0, 0.08)], 10)
        mover(mun, rx=-sy * math.pi / 2)
        mover(mun, 0.0, sy * 0.24, 0.0)
        herr.append(mun)
        herr += remaches([(sx * 0.045, sy * 0.242, z, (0, sy, 0)) for sx in (-1, 1) for z in (-0.03, 0.045)],
                         0.007, 0.004, 6)
    h = unir("yugo_herraje", herr)
    abollar(h, 0.0005, 70.0, 7.0)
    return madero, h


# La viga de la que cuelga todo: de x = 0,45 a 2,55 en la mesa, o sea de −1,15 a
# 0,95 respecto al eje de la campana (que está en x = 1,60).
VIGA_X = (-1.15, 0.95)
VIGA_Z = (0.235, 0.405)
# Dónde salen las cadenas que la sujetan (las armellas de arriba), respecto al eje.
ARMELLAS_X = (-1.04, 0.84)


def viga():
    madero = caja("viga", VIGA_X[0], VIGA_X[1], -0.08, 0.08, VIGA_Z[0], VIGA_Z[1])
    subdividir(madero, 4)
    madero = biselar(madero, 0.016, 2, 30.0)
    # Una viga vieja: comba, alabeo y alguna raja (un surco a lo largo).
    for v in madero.data.vertices:
        t = (v.co.x - VIGA_X[0]) / (VIGA_X[1] - VIGA_X[0])
        v.co.z -= 0.018 * math.sin(math.pi * t)
        v.co.y += 0.006 * math.sin(TAU * t * 1.3 + 0.4)
        if v.co.y < -0.07 and abs(v.co.z - 0.33) < 0.012:
            v.co.y += 0.006
    abollar(madero, 0.003, 9.0, 2.0)
    # El travesaño de debajo, a lo largo del eje: de él cuelgan las horquillas.
    trav = caja("trav", -0.05, 0.05, -0.31, 0.31, 0.150, 0.236)
    subdividir(trav, 2)
    trav = biselar(trav, 0.01, 2, 30.0)
    abollar(trav, 0.002, 14.0, 4.0)
    madera = unir("viga", [madero, trav])

    herr = []
    # Dos abrazaderas de pletina que sujetan el travesaño a la viga.
    for x in (-0.072, 0.072):
        pl = []
        for y0, y1, z0, z1 in ((-0.094, -0.082, 0.15, 0.405), (0.082, 0.094, 0.15, 0.405),
                               (-0.094, 0.094, 0.405, 0.417), (-0.094, 0.094, 0.138, 0.150)):
            pl.append(caja("pl", x - 0.017, x + 0.017, y0, y1, z0, z1))
        for p in pl:
            subdividir(p, 1)
        herr.append(biselar(unir("abraz", pl), 0.003, 1, 30.0))
        herr += remaches([(x, sy * 0.094, z, (0, sy, 0)) for sy in (-1, 1) for z in (0.20, 0.36)], 0.008, 0.005, 6)
    # Las horquillas: dos pletinas que bajan a los cojinetes del eje.
    for sy in (-1, 1):
        y = sy * 0.285
        hq = caja("horq", -0.028, 0.028, y - 0.009, y + 0.009, -0.035, 0.200)
        subdividir(hq, 2)
        hq = biselar(hq, 0.004, 1, 30.0)
        coj = torno("coj", perfil_redondo(0.019, 0.044, -0.014, 0.014, 0.006, 1), 12)
        mover(coj, rx=math.pi / 2)
        mover(coj, 0.0, y + sy * 0.012, 0.0)
        herr += [hq, coj]
        herr += remaches([(0.0, y + sy * 0.009, z, (0, sy, 0)) for z in (0.09, 0.17)], 0.008, 0.005, 6)
    # Los zunchos de los extremos y las armellas de las cadenas que la cuelgan.
    for x in ARMELLAS_X:
        pl = []
        for y0, y1, z0, z1 in ((-0.092, -0.08, 0.215, 0.39), (0.08, 0.092, 0.215, 0.39),
                               (-0.092, 0.092, 0.39, 0.402), (-0.092, 0.092, 0.203, 0.215)):
            pl.append(caja("pl", x - 0.022, x + 0.022, y0, y1, z0, z1))
        for p in pl:
            subdividir(p, 1)
        herr.append(biselar(unir("zuncho", pl), 0.003, 1, 30.0))
        herr += remaches([(x, sy * 0.092, z, (0, sy, 0)) for sy in (-1, 1) for z in (0.26, 0.34)], 0.007, 0.004, 6)
        ojo = []
        for j in range(11):
            t = TAU * j / 10
            ojo.append((x + 0.026 * math.sin(t), 0.0, 0.43 + 0.026 * math.cos(t)))
        herr.append(tubo("armella", ojo[:-1], 0.008, 6, cerrado=True))
        herr.append(torno("base", [(0.0, 0.0), (0.022, 0.0), (0.02, 0.012), (0.0, 0.014)], 8))
        mover(herr[-1], x, 0.0, 0.395)
    h = unir("viga_herraje", herr)
    abollar(h, 0.0005, 60.0, 9.0)
    return madera, h


# ================================================================ EL FUEGO


def antorcha():
    """La antorcha de pared del sprite: placa remachada, brazo de forja con su
    voluta, y una cesta de barras con el trapo de brea dentro."""
    placa = caja("placa", -0.045, 0.045, -0.014, 0.0, -0.115, 0.105)
    subdividir(placa, 2)
    for v in placa.data.vertices:
        # La cabeza de la placa, en punta de arco.
        if v.co.z > 0.06:
            v.co.z += 0.03 * (1.0 - abs(v.co.x) / 0.045)
    placa = biselar(placa, 0.004, 2, 30.0)
    partes = [placa]
    partes += remaches([(sx * 0.028, -0.014, z, (0, -1, 0)) for sx in (-1, 1) for z in (-0.085, 0.07)],
                       0.008, 0.005, 8)
    # El brazo: sale de la placa, se dobla hacia arriba y sostiene la cesta.
    brazo = [(0.0, -0.012, -0.03), (0.0, -0.05, -0.034), (0.0, -0.09, -0.026), (0.0, -0.122, -0.008),
             (0.0, -0.142, 0.012), (0.0, -0.15, 0.03)]
    partes.append(tubo("brazo", brazo, 0.0085, 8))
    # La voluta de debajo, que es lo que lo hace forja y no un tubo.
    vol = []
    for j in range(15):
        t = j / 14
        a = math.pi * 0.5 + t * TAU * 1.15
        rr = 0.032 * (1.0 - 0.75 * t)
        vol.append((0.0, -0.045 - rr * math.cos(a) * 0.9, -0.07 + rr * math.sin(a)))
    vol = [(0.0, -0.012, -0.075)] + vol
    partes.append(tubo("voluta", vol, 0.0055, 6))
    # La cesta: un aro abajo, seis barras que se abren, un aro arriba.
    c = Vector((0.0, -0.15, 0.03))
    for k in range(6):
        a = TAU * k / 6
        pts = []
        for j in range(9):
            t = j / 8
            rr = 0.012 + 0.042 * math.sin(t * math.pi / 2) ** 0.9
            pts.append(c + Vector((rr * math.cos(a), rr * math.sin(a), 0.115 * t)))
        # La punta de arriba se abre en un pétalo.
        pts.append(c + Vector((0.062 * math.cos(a), 0.062 * math.sin(a), 0.128)))
        partes.append(tubo("barra", pts, 0.0045, 4))
    for z, rr, g in ((0.03, 0.04, 0.0055), (0.115, 0.055, 0.006)):
        anillo = [c + Vector((rr * math.cos(TAU * j / 14), rr * math.sin(TAU * j / 14), z)) for j in range(14)]
        partes.append(tubo("aro", anillo, g, 4, cerrado=True))
    partes.append(torno("pomo", [(0.0, -0.035), (0.006, -0.03), (0.014, -0.012), (0.016, 0.0),
                                 (0.012, 0.008), (0.0, 0.01)], 10))
    mover(partes[-1], c.x, c.y, c.z)
    hierro = unir("antorcha_hierro", partes)
    abollar(hierro, 0.0006, 60.0, 11.0)
    # El trapo con brea: un bulto apelmazado que asoma por encima de la cesta.
    brea = esfera("antorcha_brea", 0.036, 2, centro=(c.x, c.y, c.z + 0.085), escala=(1.0, 1.0, 1.25))
    abollar(brea, 0.008, 45.0, 2.0)
    abollar(brea, 0.003, 120.0, 6.0)
    return hierro, brea


def brasero_cuenco():
    perfil = [(0.0, 0.0), (0.05, 0.0), (0.095, 0.016), (0.135, 0.044), (0.160, 0.078), (0.170, 0.104),
              (0.172, 0.114), (0.158, 0.114), (0.150, 0.092), (0.128, 0.060), (0.09, 0.040), (0.0, 0.032)]
    cuenco = torno("cuenco", perfil, 24)
    bocel = torno_cerrado("bocel", [(0.172 + 0.011 * math.cos(TAU * k / 6), 0.114 + 0.011 * math.sin(TAU * k / 6))
                                    for k in range(6)], 24)
    # Martillado: el cuenco no es de torno.
    abollar(cuenco, 0.0018, 26.0, 4.0)
    partes = [cuenco, bocel]
    lista = []
    for k in range(8):
        a = TAU * k / 8
        n = Vector((math.cos(a), math.sin(a), -0.25)).normalized()
        lista.append((0.155 * math.cos(a), 0.155 * math.sin(a), 0.072, tuple(n)))
    partes += remaches(lista, 0.008, 0.005, 6)
    # Cuatro orejetas donde muerden las patas.
    for k in range(4):
        a = TAU * k / 4 + math.pi / 4
        o = caja("oreja", -0.016, 0.016, -0.006, 0.006, -0.02, 0.025)
        o = biselar(o, 0.003, 1, 30.0)
        matriz(o, Matrix.Translation((0.168 * math.cos(a), 0.168 * math.sin(a), 0.07))
               @ Matrix.Rotation(a + math.pi / 2, 4, "Z"))
        partes.append(o)
    c = unir("brasero_cuenco", partes)
    return c


def brasero_brasas(radio=0.145, z0=0.06, alto=0.075, n=22, semilla=3):
    rnd = random.Random(semilla)
    piezas = []
    for i in range(n):
        a = rnd.uniform(0, TAU)
        rr = radio * math.sqrt(rnd.random()) * 0.95
        z = z0 + alto * (1.0 - (rr / radio) ** 2) * rnd.uniform(0.6, 1.0)
        s = rnd.uniform(0.022, 0.036)
        e = esfera("b", s, 1, centro=(rr * math.cos(a), rr * math.sin(a), z),
                   escala=(rnd.uniform(0.8, 1.3), rnd.uniform(0.8, 1.3), rnd.uniform(0.6, 0.9)))
        abollar(e, s * 0.35, 60.0, i * 1.3)
        piezas.append(e)
    return unir("brasero_brasas", piezas)


def brasero_patas():
    partes = []
    for k in range(4):
        a = TAU * k / 4 + math.pi / 4
        d = Vector((math.cos(a), math.sin(a), 0.0))
        pts = [d * 0.168 + Vector((0, 0, 0.17)), d * 0.178 + Vector((0, 0, 0.14)), d * 0.19 + Vector((0, 0, 0.09)),
               d * 0.205 + Vector((0, 0, 0.05)), d * 0.215 + Vector((0, 0, 0.03))]
        partes.append(tubo("pata", pts, 0.0, 6, radios=[0.011, 0.012, 0.013, 0.014, 0.016]))
        # La garra: tres dedos sobre el suelo.
        for g in (-0.5, 0.0, 0.5):
            dd = Vector((math.cos(a + g), math.sin(a + g), 0.0))
            base = d * 0.215 + Vector((0, 0, 0.03))
            dedo = [base, base + dd * 0.022 + Vector((0, 0, -0.016)), base + dd * 0.04 + Vector((0, 0, -0.024)),
                    base + dd * 0.05 + Vector((0, 0, -0.022))]
            partes.append(tubo("dedo", dedo, 0.0, 4, radios=[0.012, 0.009, 0.006, 0.003]))
    p = unir("brasero_patas", partes)
    abollar(p, 0.0008, 50.0, 8.0)
    return p


def brasero_pie():
    """El trípode alto de la sala: tres patas que bajan abriéndose desde el aro
    del cuenco, un aro de atado a media altura y volutas en los pies."""
    partes = []
    alto = 0.92
    for k in range(3):
        a = TAU * k / 3
        d = Vector((math.cos(a), math.sin(a), 0.0))
        pts = []
        for j in range(12):
            t = j / 11
            rr = 0.13 + 0.17 * t ** 1.6
            pts.append(d * rr + Vector((0, 0, alto - (alto - 0.07) * t)))
        # La voluta del pie: baja hacia fuera, apoya en el suelo y se enrosca.
        pts += voluta(pts[-1], d, 0.035, 13)
        partes.append(tubo("pata", pts, 0.0, 6, radios=[0.016] * 12 + [0.015 - 0.0007 * j for j in range(13)],
                           cuadrado=True))
    for z, rr in ((alto + 0.005, 0.13), (0.42, 0.13 + 0.17 * ((alto - 0.42) / (alto - 0.07)) ** 1.6)):
        anillo = [Vector((rr * math.cos(TAU * j / 20), rr * math.sin(TAU * j / 20), z)) for j in range(20)]
        partes.append(tubo("aro", anillo, 0.011, 5, cerrado=True))
    # Un vástago central con nudo, de suelo a cuenco.
    partes.append(torno("vastago", [(0.0, 0.40), (0.02, 0.40), (0.03, 0.43), (0.02, 0.46), (0.014, 0.48),
                                    (0.014, alto - 0.02), (0.03, alto), (0.0, alto + 0.002)], 10))
    p = unir("brasero_pie", partes)
    abollar(p, 0.0008, 40.0, 12.0)
    return p


# Los platillos del candelabro (dónde va cada vela), en ejes de Blender.
CANDELABRO_VELAS = [(0.0, 0.0, 1.335)] + [(0.2 * math.cos(TAU * k / 4), 0.2 * math.sin(TAU * k / 4), 1.225)
                                          for k in range(4)]


def candelabro():
    partes = []
    perfil = [(0.0, 0.10), (0.05, 0.10), (0.058, 0.12), (0.035, 0.15), (0.024, 0.20), (0.022, 0.30),
              (0.042, 0.32), (0.044, 0.345), (0.024, 0.37), (0.018, 0.60), (0.016, 0.95), (0.03, 0.97),
              (0.034, 0.99), (0.018, 1.02), (0.016, 1.20), (0.034, 1.215), (0.036, 1.235), (0.02, 1.25),
              (0.016, 1.29), (0.0, 1.29)]
    partes.append(torno("fuste", perfil, 10))
    # Tres pies de voluta.
    for k in range(3):
        a = TAU * k / 3 + 0.3
        d = Vector((math.cos(a), math.sin(a), 0.0))
        pts = [d * 0.03 + Vector((0, 0, 0.16)), d * 0.09 + Vector((0, 0, 0.12)), d * 0.15 + Vector((0, 0, 0.07)),
               d * 0.19 + Vector((0, 0, 0.05))]
        pts += voluta(pts[-1], d, 0.025, 9)
        partes.append(tubo("pie", pts, 0.0, 6, radios=[0.016, 0.014, 0.012, 0.011] + [0.010 - 0.0006 * j for j in range(9)],
                           cuadrado=True))
    # Los brazos en S, con su platillo y su cubo para la vela.
    for i, (x, y, z) in enumerate(CANDELABRO_VELAS):
        if i > 0:
            d = Vector((x, y, 0.0)).normalized()
            pts = []
            for j in range(12):
                t = j / 11
                pts.append(d * (0.2 * t) + Vector((0, 0, 1.08 + 0.10 * t - 0.05 * math.sin(t * math.pi) + 0.0)))
            partes.append(tubo("brazo", [Vector((0, 0, 1.12))] + pts[1:], 0.009, 6))
        pl = torno("platillo", [(0.0, -0.012), (0.012, -0.012), (0.05, -0.002), (0.056, 0.006), (0.05, 0.004),
                                (0.0, -0.004)], 10)
        cubo = torno("cubo", [(0.0, -0.004), (0.02, -0.004), (0.022, 0.025), (0.018, 0.025), (0.0, 0.01)], 8)
        mover(pl, x, y, z - 0.025)
        mover(cubo, x, y, z - 0.025)
        partes += [pl, cubo]
    p = unir("candelabro", partes)
    abollar(p, 0.0008, 40.0, 13.0)
    return p


def vela(nombre, alto, r, semilla, lados=10, filas=9, chorros=(3, 5), hondo=0.3):
    """Una vela de cera gastada: un poco cónica, el borde de arriba fundido y
    hundido, chorretones que bajan y un pie donde la cera se ha juntado. B es
    la luz que le llega de la llama (arde por dentro cerca de la mecha).
    Diez lados y nueve filas: eran 18 × 22 (888 triángulos) y hay cuarenta velas
    de 2 cm en pantalla; solo los cirios de la carga llevan más."""
    rnd = random.Random(semilla)
    chor = [(rnd.uniform(0, TAU), rnd.uniform(0.25, 0.8), rnd.uniform(0.18, 0.32))
            for _ in range(rnd.randint(chorros[0], chorros[1]))]
    bm = bmesh.new()
    anillos = []
    for j in range(filas + 1):
        t = j / filas
        z = alto * t
        fila = []
        for k in range(lados):
            a = TAU * k / lados
            rr = r * (1.03 - 0.06 * t)
            # Pie de cera junta.
            rr += r * 0.35 * math.exp(-z / (r * 0.6))
            for ac, largo, ancho in chor:
                da = math.atan2(math.sin(a - ac), math.cos(a - ac))
                if t > 1.0 - largo:
                    caida = (t - (1.0 - largo)) / largo
                    gorda = 0.22 + 0.25 * math.exp(-((t - (1.0 - largo) - 0.04) / 0.05) ** 2)
                    rr += r * gorda * math.exp(-(da / ancho) ** 2) * (0.4 + 0.6 * caida)
            fila.append(bm.verts.new((rr * math.cos(a), rr * math.sin(a), z)))
        anillos.append(fila)
    # El borde de arriba, fundido e irregular, y el cráter.
    borde = []
    for k in range(lados):
        a = TAU * k / lados
        v = anillos[-1][k]
        v.co.z += alto * 0.0 + r * 0.25 * noise.noise(Vector((math.cos(a) * 2, math.sin(a) * 2, semilla)))
        borde.append(v)
    crater = [bm.verts.new((r * 0.55 * math.cos(TAU * k / lados), r * 0.55 * math.sin(TAU * k / lados), alto - r * hondo))
              for k in range(lados)]
    for a, b in zip(anillos[:-1], anillos[1:]):
        for k in range(lados):
            cara(bm, [a[k], a[(k + 1) % lados], b[(k + 1) % lados], b[k]])
    for k in range(lados):
        cara(bm, [borde[k], borde[(k + 1) % lados], crater[(k + 1) % lados], crater[k]])
    hueco = alto - r * (hondo + 0.15)
    fondo = bm.verts.new((0.0, 0.0, hueco))
    for k in range(lados):
        cara(bm, [crater[k], crater[(k + 1) % lados], fondo])
    cara(bm, list(reversed(anillos[0])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = nueva(nombre, bm)
    # La mecha: un pelo negro (oclusión 0) en el cráter.
    mecha = tubo("mecha", [(0, 0, hueco), (0.0015, 0, alto + 0.004), (0.003, 0.001, alto + 0.010)],
                 0.0018, 4)
    o = unir(nombre, [o, mecha])
    return o


def cirio():
    """EL CIRIO de la carga de la campana. Antes era la vela grande escalada a
    1,5 × 1,7: un tubo de 6 cm de grueso que, con la cera naranja, se leía como
    un cono de tráfico. Este es un cirio de verdad: delgado (3,4 cm), alto, con
    la copa hundida y honda (se lee oscura desde arriba) y cinco o seis
    chorretones largos de geometría que bajan casi hasta el pie."""
    return vela("cirio", 0.27, 0.017, 41, lados=12, filas=16, chorros=(5, 6), hondo=0.7)


def cera_charco():
    bm = bmesh.new()
    lados = 14
    anillos = []
    for j, (rf, z) in enumerate(((1.0, 0.0), (0.92, 0.009), (0.5, 0.013), (0.0, 0.014))):
        fila = []
        for k in range(lados):
            a = TAU * k / lados
            rr = 0.085 * (1.0 + 0.28 * noise.noise(Vector((math.cos(a) * 1.6, math.sin(a) * 1.6, 0.3)))) * rf
            fila.append(bm.verts.new((rr * math.cos(a), rr * math.sin(a), z)))
        anillos.append(fila)
    for a, b in zip(anillos[:-1], anillos[1:]):
        for k in range(lados):
            cara(bm, [a[k], a[(k + 1) % lados], b[(k + 1) % lados], b[k]])
    cara(bm, list(reversed(anillos[0])))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = nueva("cera_charco", bm)
    abollar(o, 0.0015, 60.0, 2.0)
    return o


# ================================================================= LAS CADENAS

ESLABON_PASO = 0.035


def eslabon():
    """Un eslabón de 48 triángulos: seis puntos de óvalo y sección de rombo.
    Eran 24 × 7 = 336, y con cuatro cadenas de 54 a 72 eslabones sumaban 84.672
    triángulos (un cuarto de la escena) para algo que en la cámara de juego
    ocupa dos o tres píxeles por eslabón. Los ángulos van a medio paso: con un
    punto en sin = 0 el desfase de ±0,01 lo mandaba abajo y el óvalo salía torcido."""
    pts = []
    for j in range(6):
        a = TAU * (j + 0.5) / 6
        x = 0.0135 * math.cos(a)
        zz = 0.0135 * math.sin(a) + (0.01 if math.sin(a) > 0 else -0.01)
        pts.append((x, 0.0, zz))
    e = tubo("eslabon", pts, 0.0058, 4, cerrado=True)
    return e


def gancho():
    pts = [(0.0, 0.0, -0.012), (0.0, 0.0, -0.08)]
    for j in range(1, 9):
        a = math.pi * 1.15 * j / 8
        pts.append((0.03 - 0.03 * math.cos(a), 0.0, -0.08 - 0.03 * math.sin(a)))
    radios = [0.0075] * (len(pts) - 4) + [0.0068, 0.0055, 0.004, 0.0018]
    g = tubo("gancho", pts, 0.0, 5, radios=radios)
    ojo = [(0.012 * math.sin(TAU * j / 8), 0.0, -0.012 + 0.012 * math.cos(TAU * j / 8)) for j in range(8)]
    o = tubo("ojo", ojo, 0.005, 4, cerrado=True)
    h = unir("gancho", [g, o])
    abollar(h, 0.0006, 80.0, 4.0)
    return h


# ================================================================== LOS FAROLES
#
# Dos sitios de la mesa estaban a oscuras sin remedio: los ESCUDOS (el banco de
# la derecha, debajo de los raíles) y los CAPITELES de calaveras de las dos
# columnas del ábside. Una luz ahí tiene que tener motivo: un farol de hierro
# con una vela dentro. En los capiteles cuelga de un brazo de pared clavado en
# el fuste; en los escudos, de un PESCANTE que sale de la albardilla y vuela por
# encima de los raíles (la bola no lo toca: el atrezzo no choca).

# El pescante: lo alto del poste sobre la albardilla y lo que vuela el brazo.
# `atrezzo.gd` los copia (PESCANTE_ALTO, PESCANTE_LARGO).
PESCANTE_ALTO = 0.98
PESCANTE_LARGO = 0.70
# El brazo de pared: dónde cuelga el farol respecto a la cara del muro.
BRAZO_LARGO = 0.21


def farol():
    """Un farol de cuatro caras, con el origen en lo alto de la argolla de la
    que cuelga: tejadillo de chapa en pirámide, marco de pletina, una barra a
    media altura en cada cara y el plato de abajo. Sin cristales: es una jaula,
    y la vela de dentro se ve (la pone Godot, con las velas)."""
    partes = []
    arg = [(0.011 * math.sin(TAU * j / 8), 0.0, -0.011 + 0.011 * math.cos(TAU * j / 8)) for j in range(8)]
    partes.append(tubo("argolla", arg, 0.003, 4, cerrado=True))
    partes.append(torno("techo", [(0.0, -0.016), (0.014, -0.022), (0.062, -0.058), (0.066, -0.064),
                                  (0.0, -0.064)], 4, giro=math.pi / 4))
    partes.append(caja("plato_alto", -0.044, 0.044, -0.044, 0.044, -0.074, -0.064))
    partes.append(caja("plato", -0.047, 0.047, -0.047, 0.047, -0.200, -0.189))
    for sx in (-1, 1):
        for sy in (-1, 1):
            partes.append(caja("poste", sx * 0.035 - 0.004, sx * 0.035 + 0.004, sy * 0.035 - 0.004,
                               sy * 0.035 + 0.004, -0.19, -0.074))
    for eje in range(2):
        for s in (-1, 1):
            if eje == 0:
                partes.append(caja("barra", -0.035, 0.035, s * 0.035 - 0.002, s * 0.035 + 0.002, -0.134, -0.128))
            else:
                partes.append(caja("barra", s * 0.035 - 0.002, s * 0.035 + 0.002, -0.035, 0.035, -0.134, -0.128))
    partes.append(torno("pie", [(0.0, -0.200), (0.02, -0.200), (0.012, -0.214), (0.0, -0.216)], 6))
    f = unir("farol", partes)
    return f


def farol_brazo():
    """El brazo de pared del farol: placa remachada contra el muro (o el fuste)
    y una barra de forja que sale `BRAZO_LARGO` con una voluta debajo. El farol
    cuelga del gancho del extremo, que está en (0, −BRAZO_LARGO, 0) (frente −y)."""
    partes = [biselar(caja("placa", -0.03, 0.03, -0.012, 0.0, -0.08, 0.07), 0.003, 1, 30.0)]
    partes += remaches([(0.0, -0.012, z, (0, -1, 0)) for z in (-0.055, 0.045)], 0.007, 0.004)
    brazo = [(0.0, -0.010, 0.03), (0.0, -0.08, 0.042), (0.0, -0.16, 0.046), (0.0, -BRAZO_LARGO, 0.04),
             (0.0, -BRAZO_LARGO - 0.012, 0.025), (0.0, -BRAZO_LARGO, 0.008), (0.0, -BRAZO_LARGO, 0.0)]
    partes.append(tubo("brazo", brazo, 0.007, 4, cuadrado=True))
    vol = [(0.0, -0.010, -0.05)]
    for j in range(10):
        t = j / 9
        a = math.pi * 0.5 + t * TAU * 0.9
        rr = 0.045 * (1.0 - 0.6 * t)
        vol.append((0.0, -0.075 - rr * math.cos(a), -0.005 + rr * math.sin(a) * 0.8))
    partes.append(tubo("voluta", vol, 0.0045, 4))
    b = unir("farol_brazo", partes)
    abollar(b, 0.0005, 60.0, 14.0)
    return b


def pescante():
    """El pescante de los escudos: una placa en la albardilla, un poste de
    forja de `PESCANTE_ALTO`, un brazo que vuela `PESCANTE_LARGO` hacia el
    campo (frente −y) con su tornapuntas y su voluta, y el gancho del extremo,
    que queda en (0, −PESCANTE_LARGO, PESCANTE_ALTO − 0,04)."""
    h, largo = PESCANTE_ALTO, PESCANTE_LARGO
    partes = [biselar(caja("placa", -0.045, 0.045, -0.045, 0.045, 0.0, 0.014), 0.003, 1, 30.0)]
    partes += remaches([(sx * 0.03, sy * 0.03, 0.014, (0, 0, 1)) for sx in (-1, 1) for sy in (-1, 1)], 0.007, 0.004)
    partes.append(tubo("poste", [(0.0, 0.0, 0.01), (0.0, 0.0, h * 0.5), (0.0, 0.0, h + 0.02)], 0.012, 4,
                       cuadrado=True))
    partes.append(torno("remate", [(0.0, h + 0.015), (0.02, h + 0.02), (0.016, h + 0.045), (0.0, h + 0.06)], 6))
    partes.append(tubo("brazo", [(0.0, 0.01, h), (0.0, -largo * 0.5, h + 0.008), (0.0, -largo, h)], 0.01, 4,
                       cuadrado=True))
    partes.append(tubo("tornapuntas", [(0.0, -0.005, h - 0.30), (0.0, -0.15, h - 0.12), (0.0, -0.30, h - 0.005)],
                       0.007, 4, cuadrado=True))
    vol = [(0.0, -largo + 0.06, h)]
    for j in range(1, 10):
        t = j / 9
        a = t * TAU * 0.85
        rr = 0.04 * (1.0 - 0.6 * t)
        vol.append((0.0, -largo + 0.06 + rr * math.sin(a), h - 0.04 + rr * math.cos(a)))
    partes.append(tubo("voluta", vol, 0.005, 4))
    partes.append(tubo("gancho", [(0.0, -largo, h), (0.0, -largo, h - 0.03), (0.0, -largo + 0.008, h - 0.04)],
                       0.004, 4))
    p = unir("pescante", partes)
    abollar(p, 0.0006, 40.0, 15.0)
    return p


# ================================================================== LA GÁRGOLA


def gargola():
    """El mascarón del sprite `bumper_gargola`: una cabeza de gárgola con
    cuernos, ceño y la boca abierta con colmillos, saliendo de un medallón de
    piedra. Frente hacia −y, la espalda contra el muro en y = 0."""
    q = Quaternion
    els = [
        # El cráneo y la frente.
        {"tipo": "ELLIPSOID", "co": (0.0, -0.035, 0.03), "r": 0.105, "tam": (1.0, 0.72, 0.95)},
        # El ceño: dos almohadillas que se juntan en el centro y bajan.
        {"tipo": "ELLIPSOID", "co": (-0.036, -0.105, 0.052), "r": 0.052, "tam": (1.0, 0.55, 0.42),
         "rot": q((0, 1, 0), math.radians(26))},
        {"tipo": "ELLIPSOID", "co": (0.036, -0.105, 0.052), "r": 0.052, "tam": (1.0, 0.55, 0.42),
         "rot": q((0, 1, 0), math.radians(-26))},
        # Pómulos, hocico chato y la nariz.
        {"co": (-0.062, -0.083, -0.008), "r": 0.048},
        {"co": (0.062, -0.083, -0.008), "r": 0.048},
        {"tipo": "ELLIPSOID", "co": (0.0, -0.112, 0.004), "r": 0.05, "tam": (0.72, 0.75, 0.62)},
        {"co": (0.0, -0.146, 0.012), "r": 0.022},
        {"co": (-0.015, -0.142, -0.002), "r": 0.017},
        {"co": (0.015, -0.142, -0.002), "r": 0.017},
        # La mandíbula de abajo y los carrillos.
        {"tipo": "ELLIPSOID", "co": (0.0, -0.085, -0.098), "r": 0.062, "tam": (1.0, 0.78, 0.5)},
        {"co": (-0.07, -0.068, -0.06), "r": 0.046},
        {"co": (0.07, -0.068, -0.06), "r": 0.046},
        # Las orejas de murciélago, hacia fuera y arriba.
        {"tipo": "ELLIPSOID", "co": (-0.128, -0.025, 0.04), "r": 0.078, "tam": (0.45, 0.2, 1.0),
         "rot": q((0, 1, 0), math.radians(-42))},
        {"tipo": "ELLIPSOID", "co": (0.128, -0.025, 0.04), "r": 0.078, "tam": (0.45, 0.2, 1.0),
         "rot": q((0, 1, 0), math.radians(42))},
        # LO QUE SE QUITA: las cuencas, las ventanas de la nariz y la boca.
        {"co": (-0.040, -0.128, 0.026), "r": 0.03, "neg": True},
        {"co": (0.040, -0.128, 0.026), "r": 0.03, "neg": True},
        {"co": (-0.012, -0.158, -0.012), "r": 0.009, "neg": True},
        {"co": (0.012, -0.158, -0.012), "r": 0.009, "neg": True},
        {"tipo": "ELLIPSOID", "co": (0.0, -0.138, -0.060), "r": 0.074, "tam": (1.0, 0.65, 0.42), "neg": True},
    ]
    # Las metabolas, con más alcance y más umbral: mismo tamaño, pero cada una
    # empapa a sus vecinas y la cara sale de una pieza, no de bolas pegadas.
    for e in els:
        e["r"] *= 1.45 if e.get("neg", False) else 1.6
    cabeza = metabolas("garg", els, 0.0045, 1.32)
    mod = cabeza.modifiers.new("alisar", "SMOOTH")
    mod.factor = 0.5
    mod.iterations = 4
    aplicar(cabeza)
    # 1.300 caras: la gárgola mide 30 px desde la cámara de juego. Con 5.200
    # (más medallón, dientes y cuernos) eran 10.260 triángulos cada una.
    reducir(cabeza, 1300)
    # Los cuernos: un cuerno de verdad, anillado y curvado hacia fuera y
    # arriba, clavado en el cráneo (con metabolas la punta se suelta en bolas).
    cuernos = []
    for s in (-1, 1):
        pts, radios = [], []
        n = 10
        for k in range(n + 1):
            t = k / n
            pts.append((s * (0.030 + 0.075 * t + 0.03 * t * t), -0.035 + 0.01 * t - 0.02 * t * t,
                        0.065 + 0.135 * t + 0.01 * math.sin(t * math.pi)))
            anillo = 1.0 + 0.09 * (1.0 if k % 2 == 0 else -1.0) * (1.0 - t)
            radios.append(max(0.031 * (1.0 - t) ** 0.85, 0.0015) * anillo)
        cuernos.append(tubo("cuerno", pts, 0.0, 6, radios=radios))
    # Los cuatro colmillos y dos dientes (los menudos no se veían ni de cerca).
    dientes = []
    for x, z, hacia, largo, r in ((-0.032, -0.032, -1, 0.042, 0.010), (0.032, -0.032, -1, 0.042, 0.010),
                                  (-0.048, -0.084, 1, 0.032, 0.009), (0.048, -0.084, 1, 0.032, 0.009),
                                  (-0.012, -0.036, -1, 0.018, 0.006), (0.012, -0.036, -1, 0.018, 0.006)):
        d = torno("diente", [(0.0, -0.004), (r, 0.0), (r * 0.8, largo * 0.4), (r * 0.35, largo * 0.85), (0.0, largo)], 5)
        if hacia < 0:
            mover(d, rx=math.pi)
        mover(d, x, -0.142 + abs(x) * 0.35, z)
        dientes.append(d)
    # El medallón: un disco con el borde moldurado, como el sprite.
    perfil = [(0.0, 0.0), (0.178, 0.0), (0.182, 0.012), (0.178, 0.03), (0.168, 0.042), (0.152, 0.046),
              (0.140, 0.040), (0.135, 0.030), (0.120, 0.026), (0.0, 0.026)]
    med = torno("medallon", perfil, 28)
    mover(med, rx=math.pi / 2)
    abollar(med, 0.0015, 30.0, 6.0)
    g = unir("gargola", [cabeza, med] + dientes + cuernos)
    abollar(g, 0.0012, 55.0, 2.0)
    # Los ojos, hundidos en el fondo de las cuencas: brillan desde dentro.
    ojos = []
    for s in (-1, 1):
        ojos.append(esfera("ojo", 0.013, 1, centro=(s * 0.040, -0.100, 0.024), escala=(1.0, 0.7, 0.8)))
    o = unir("gargola_ojos", ojos)
    return g, o


# ======================================================= HUESOS, BARRIL Y CAJA


def hueso(largo, r, semilla):
    """Un hueso largo: caña y dos cabezas de dos cóndilos."""
    perfil = [(0.0, -largo * 0.5 - r * 0.6), (r * 1.6, -largo * 0.5 - r * 0.2), (r * 1.9, -largo * 0.5 + r * 0.6),
              (r * 1.2, -largo * 0.5 + r * 2.2), (r, -largo * 0.25), (r * 0.95, 0.0), (r, largo * 0.25),
              (r * 1.2, largo * 0.5 - r * 2.2), (r * 1.9, largo * 0.5 - r * 0.6), (r * 1.6, largo * 0.5 + r * 0.2),
              (0.0, largo * 0.5 + r * 0.6)]
    h = torno("hueso", perfil, 6)
    partes = [h]
    for s in (-1, 1):
        for dx in (-1, 1):
            partes.append(esfera("condilo", r * 1.15, 1, centro=(dx * r * 1.0, 0.0, s * (largo * 0.5 + r * 0.1))))
    o = unir("hueso", partes)
    abollar(o, r * 0.08, 40.0, semilla)
    return o


def huesos():
    # Catorce huesos un poco más gruesos en vez de treinta, y las calaveras a
    # 260 caras: el montón pesaba 10.982 triángulos y hay cuatro.
    rnd = random.Random(7)
    partes = []
    cal = calavera(0.11, 320)
    for i in range(14):
        largo = rnd.uniform(0.12, 0.22)
        h = hueso(largo, rnd.uniform(0.010, 0.014), i)
        a = rnd.uniform(0, TAU)
        rr = 0.15 * math.sqrt(rnd.random())
        z = 0.01 + 0.11 * (1.0 - (rr / 0.16) ** 2) ** 1.2 * rnd.uniform(0.5, 1.0)
        m = Matrix.Translation((rr * math.cos(a), rr * math.sin(a), z)) @ Matrix.Rotation(rnd.uniform(0, TAU), 4, "Z") \
            @ Matrix.Rotation(math.pi / 2 + rnd.uniform(-0.35, 0.35), 4, "X")
        matriz(h, m)
        partes.append(h)
    for x, y, z, giro, incl in ((0.02, -0.03, 0.085, 0.25, -0.25), (-0.12, 0.04, 0.02, -0.7, 0.1)):
        c = copia(cal, "cal")
        matriz(c, Matrix.Translation((x, y, z)) @ Matrix.Rotation(giro, 4, "Z") @ Matrix.Rotation(incl, 4, "X"))
        partes.append(c)
    bpy.data.objects.remove(cal)
    return unir("huesos", partes)


def calavera_suelta():
    c = calavera(0.12, 600)
    c.name = "calavera"
    c.data.name = "calavera"
    return c


def barril():
    alto, r_med, r_cab = 0.56, 0.20, 0.168
    duelas = 12

    def radio_de(r, z, a):
        # Las juntas de las duelas: un surco cada 1/18 de vuelta, y cada duela
        # un pelo distinta.
        f = (a / TAU * duelas) % 1.0
        surco = math.exp(-((f - 0.0) / 0.06) ** 2) + math.exp(-((f - 1.0) / 0.06) ** 2)
        k = int(a / TAU * duelas)
        return r * (1.0 - 0.012 * surco + 0.006 * math.sin(k * 7.3))

    def perfil_r(z):
        t = z / alto
        return r_cab + (r_med - r_cab) * math.sin(math.pi * t)
    zs = np.linspace(0.004, alto - 0.004, 9)
    fuera = [(perfil_r(z), z) for z in zs]
    # El canto de las duelas por arriba y el fondo hundido (el «jable»).
    tapa_z = alto - 0.03
    pf = [(0.0, 0.0), (r_cab - 0.006, 0.0)] + fuera + [(r_cab - 0.006, alto), (r_cab - 0.018, alto),
                                                      (r_cab - 0.018, tapa_z), (0.0, tapa_z)]
    # Tres puntos por duela (el surco de la junta y las dos caras): con 72 lados
    # y 18 filas el barril eran 5.304 triángulos, y está en la sala, en la niebla.
    cuerpo = torno("barril_madera", pf, duelas * 3, 0.0, radio_de)
    abollar(cuerpo, 0.0015, 14.0, 5.0)
    aros = []
    for z in (0.045, 0.15, alto - 0.15, alto - 0.045):
        rr = perfil_r(z) + 0.003
        aros.append(torno_cerrado("aro", perfil_redondo(rr - 0.004, rr + 0.005, z - 0.017, z + 0.017, 0.002, 1), 24))
        aros += remaches([((rr + 0.005) * math.cos(a), (rr + 0.005) * math.sin(a), z, (math.cos(a), math.sin(a), 0))
                          for a in (0.3, 3.4)], 0.006, 0.004, 6)
    a = unir("barril_aros", aros)
    abollar(a, 0.0008, 40.0, 9.0)
    return cuerpo, a


def caja_pieza():
    """Una caja de tablas: un núcleo y encima las tablas de cada cara, con su
    holgura, y los listones de los cantos. Herrajes de esquina remachados."""
    L = 0.36
    h = L / 2
    partes = [caja("nucleo", -h + 0.01, h - 0.01, -h + 0.01, h - 0.01, 0.01, L - 0.01)]
    rnd = random.Random(4)
    for eje in range(3):
        for s in (-1, 1):
            for k in range(3):
                a0 = -h + 0.03 + k * (L - 0.06) / 3 + 0.003
                a1 = -h + 0.03 + (k + 1) * (L - 0.06) / 3 - 0.003
                f0, f1 = s * h - 0.012, s * h + 0.004 * rnd.uniform(0.5, 1.0)
                if s < 0:
                    f0, f1 = s * h - 0.004 * rnd.uniform(0.5, 1.0), s * h + 0.012
                if eje == 0:
                    t = caja("tabla", f0, f1, -h + 0.03, h - 0.03, a0 + h, a1 + h)
                elif eje == 1:
                    t = caja("tabla", -h + 0.03, h - 0.03, f0, f1, a0 + h, a1 + h)
                else:
                    t = caja("tabla", a0, a1, -h + 0.03, h - 0.03, f0 + h, f1 + h)
                subdividir(t, 1)
                partes.append(biselar(t, 0.004, 1, 30.0))
    for x in (-1, 1):
        for y in (-1, 1):
            t = caja("liston", x * h - 0.032 if x > 0 else -h - 0.004, x * h + 0.004 if x > 0 else -h + 0.032,
                     y * h - 0.032 if y > 0 else -h - 0.004, y * h + 0.004 if y > 0 else -h + 0.032, 0.0, L)
            subdividir(t, 2)
            partes.append(biselar(t, 0.005, 2, 30.0))
    m = unir("caja_madera", partes)
    abollar(m, 0.0012, 16.0, 3.0)
    herr = []

    def tramo(s):
        # Los 7 cm que van de la esquina hacia dentro, por el lado `s`.
        return (h - 0.07, h + 0.001) if s > 0 else (-h - 0.001, -h + 0.07)
    for x in (-1, 1):
        for y in (-1, 1):
            for z0 in (-0.002, L - 0.068):
                fx = x * (h + 0.005)
                fy = y * (h + 0.005)
                ty = tramo(y)
                tx = tramo(x)
                p1 = caja("esq", min(fx - 0.003 * x, fx), max(fx - 0.003 * x, fx), ty[0], ty[1], z0, z0 + 0.07)
                p2 = caja("esq", tx[0], tx[1], min(fy - 0.003 * y, fy), max(fy - 0.003 * y, fy), z0, z0 + 0.07)
                herr.append(biselar(p1, 0.001, 1, 30.0))
                herr.append(biselar(p2, 0.001, 1, 30.0))
                herr += remaches([(x * (h + 0.007), y * (h - 0.04), z0 + 0.035, (x, 0, 0)),
                                  (x * (h - 0.04), y * (h + 0.007), z0 + 0.035, (0, y, 0))], 0.006, 0.004, 6)
    he = unir("caja_herraje", herr)
    return m, he


# ------------------------------------------------------------------- el render


def renders(carpeta, grupos):
    escena = bpy.context.scene
    escena.render.engine = "BLENDER_WORKBENCH"
    escena.display.shading.light = "STUDIO"
    escena.display.shading.color_type = "SINGLE"
    escena.display.shading.single_color = (0.6, 0.58, 0.55)
    escena.display.shading.show_cavity = True
    escena.display.shading.cavity_type = "BOTH"
    escena.render.resolution_x = 900
    escena.render.resolution_y = 900
    cam_d = bpy.data.cameras.new("cam")
    cam_d.lens = 50
    cam = bpy.data.objects.new("cam", cam_d)
    escena.collection.objects.link(cam)
    escena.camera = cam
    os.makedirs(carpeta, exist_ok=True)
    todos = [o for g in grupos for o in g[1]]
    for nombre, objs in grupos:
        for o in todos:
            o.hide_render = o not in objs
        co = np.array([tuple(o.matrix_world @ v.co) for o in objs for v in o.data.vertices])
        lo, hi = co.min(0), co.max(0)
        c = Vector(tuple((lo + hi) * 0.5))
        tam = float(max(hi - lo))
        for vista, dirn in (("a", Vector((0.35, -1.0, 0.45))), ("b", Vector((-0.8, -0.6, 0.9)))):
            cam.location = c + dirn.normalized() * tam * 2.0
            cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
            escena.render.filepath = os.path.join(carpeta, "%s_%s.png" % (nombre, vista))
            bpy.ops.render.render(write_still=True)
    for o in todos:
        o.hide_render = False


# --------------------------------------------------------------------- montaje


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    grupos = []

    # LA CAMPANA, montada para hornear como cuelga (el badajo, en su sitio).
    cuerpo, brasas = campana_cuerpo()
    bad = badajo()
    yu, yu_h = yugo()
    vi, vi_h = viga()
    mover(bad, 0.0, 0.0, -0.15)
    rig = [cuerpo, bad, yu, yu_h, vi, vi_h] + brasas
    # B del bronce: dónde se calienta cuando la campana está armada (las
    # cenefas y el labio), para que el resplandor salga de las brasas.
    hornear(cuerpo, rig, 0.08, 1.0, None,
            azul=lambda co, ao: np.clip(0.2 + sum(np.exp(-((co[:, 2] - zc) / 0.045) ** 2) for zc in CENEFAS), 0.0, 1.0))
    hornear(bad, [bad, cuerpo], 0.05, 0.7, None)
    hornear(yu, rig, 0.06, 1.0, None)
    hornear(yu_h, rig, 0.05, 1.0, None)
    hornear(vi, rig, 0.08, 1.0, None)
    hornear(vi_h, rig, 0.05, 1.0, None)
    for b in brasas:
        hornear(b, [b, cuerpo], 0.02, 0.6, None, azul=lambda co, ao: np.ones(len(co)))
    mover(bad, 0.0, 0.0, 0.15)
    for o, c in ((cuerpo, BRONCE), (bad, HIERRO), (yu, MADERA), (yu_h, HIERRO), (vi, MADERA), (vi_h, HIERRO)):
        material(o, c)
    for b in brasas:
        material(b, ASCUA)
    grupos.append(("campana", [vi, vi_h, yu, yu_h, cuerpo, bad] + brasas))

    # LA ANTORCHA.
    hi, br = antorcha()
    hornear(hi, [hi, br], 0.05, 1.0, None)
    hornear(br, [hi, br], 0.03, 0.8, None, azul=lambda co, ao: np.clip((co[:, 2] - 0.07) / 0.06, 0.15, 1.0) * ao)
    material(hi, HIERRO)
    material(br, CARBON)
    grupos.append(("antorcha", [hi, br]))

    # LOS BRASEROS.
    cu = brasero_cuenco()
    bs = brasero_brasas()
    pa = brasero_patas()
    pie = brasero_pie()
    mover(cu, 0.0, 0.0, 0.10)
    mover(bs, 0.0, 0.0, 0.10)
    hornear(cu, [cu, bs, pa], 0.06, 1.0, 0.0)
    hornear(bs, [cu, bs], 0.04, 1.0, None,
            azul=lambda co, ao: np.clip(0.35 + (co[:, 2] - 0.17) / 0.07, 0.2, 1.0) * (0.4 + 0.6 * ao))
    hornear(pa, [cu, pa], 0.06, 1.0, 0.0)
    mover(cu, 0.0, 0.0, -0.10)
    mover(bs, 0.0, 0.0, -0.10)
    cu2 = copia(cu, "tmp_cuenco")
    mover(cu2, 0.0, 0.0, 0.90)
    hornear(pie, [pie, cu2], 0.1, 1.0, 0.0)
    bpy.data.objects.remove(cu2)
    for o, c in ((cu, HIERRO), (bs, ASCUA), (pa, HIERRO), (pie, HIERRO)):
        material(o, c)
    grupos.append(("brasero", [cu, bs, pa]))
    grupos.append(("brasero_pie", [pie]))

    cand = candelabro()
    hornear(cand, [cand], 0.08, 1.0, 0.0)
    material(cand, HIERRO)

    # LAS VELAS.
    velas = []
    for i, (alto, r) in enumerate(((0.075, 0.019), (0.125, 0.017), (0.19, 0.021))):
        v = vela("vela_%d" % i, alto, r, 11 + i * 7)
        hornear(v, [v], 0.03, 0.8, 0.0,
                azul=lambda co, ao, al=alto: np.clip((co[:, 2] - (al - 0.05)) / 0.05, 0.0, 1.0) ** 1.5)
        # La mecha, negra.
        col = v.data.color_attributes["Col"]
        co = coords(v)
        for k in range(len(co)):
            if co[k, 2] > alto + 0.001 and abs(co[k, 0]) < 0.006 and abs(co[k, 1]) < 0.006:
                col.data[k].color = (0.0, 0.0, 0.0, 1.0)
        material(v, CERA)
        velas.append(v)
    # El cirio: B (la luz de la llama por dentro) solo en los dos centímetros de
    # la copa. Con la de las velas —cinco centímetros de cera encendida— y el
    # translúcido naranja, el cirio entero parecía de gominola.
    ci = cirio()
    hornear(ci, [ci], 0.03, 0.9, 0.0,
            azul=lambda co, ao: np.clip((co[:, 2] - 0.25) / 0.02, 0.0, 1.0) ** 2 * 0.6)
    col = ci.data.color_attributes["Col"]
    co = coords(ci)
    for k in range(len(co)):
        if co[k, 2] > 0.27 + 0.001 and abs(co[k, 0]) < 0.006 and abs(co[k, 1]) < 0.006:
            col.data[k].color = (0.0, 0.0, 0.0, 1.0)
    material(ci, CERA)
    velas.append(ci)
    ch = cera_charco()
    hornear(ch, [ch], 0.03, 0.6, 0.0)
    material(ch, CERA)
    grupos.append(("velas", velas + [ch, cand]))

    # LOS FAROLES.
    fa = farol()
    hornear(fa, [fa], 0.04, 1.0, None)
    fb = farol_brazo()
    hornear(fb, [fb], 0.04, 1.0, None)
    pe = pescante()
    hornear(pe, [pe], 0.06, 1.0, 0.0)
    for o in (fa, fb, pe):
        material(o, HIERRO)
    grupos.append(("faroles", [fa, fb, pe]))

    # LAS CADENAS.
    es = eslabon()
    ga = gancho()
    hornear(es, [es], 0.02, 0.6, None)
    hornear(ga, [ga], 0.02, 0.6, None)
    material(es, HIERRO)
    material(ga, HIERRO)
    grupos.append(("cadena", [es, ga]))

    # LA GÁRGOLA.
    ga_p, ga_o = gargola()
    pared = caja("pared", -0.4, 0.4, 0.0, 0.05, -0.4, 0.4)
    hornear(ga_p, [ga_p, pared], 0.06, 1.0, None)
    bpy.data.objects.remove(pared)
    pintar(ga_o, np.ones(len(ga_o.data.vertices)), np.zeros(len(ga_o.data.vertices)),
           np.ones(len(ga_o.data.vertices)))
    material(ga_p, PIEDRA)
    material(ga_o, ASCUA)
    grupos.append(("gargola", [ga_p, ga_o]))

    # HUESOS, BARRIL Y CAJA.
    hu = huesos()
    hornear(hu, [hu], 0.05, 1.2, 0.0)
    material(hu, HUESO)
    ca = calavera_suelta()
    hornear(ca, [ca], 0.04, 1.0, 0.0)
    material(ca, HUESO)
    grupos.append(("huesos", [hu, ca]))
    bm, ba = barril()
    hornear(bm, [bm, ba], 0.06, 1.0, 0.0)
    hornear(ba, [bm, ba], 0.04, 1.0, 0.0)
    material(bm, MADERA)
    material(ba, HIERRO)
    cm, chh = caja_pieza()
    hornear(cm, [cm, chh], 0.05, 1.0, 0.0)
    hornear(chh, [cm, chh], 0.04, 1.0, 0.0)
    material(cm, MADERA)
    material(chh, HIERRO)
    grupos.append(("barril_caja", [bm, ba, cm, chh]))

    # Repartidos en fila (solo para mirar el GLB: Godot coge las mallas).
    x = 0.0
    todos = []
    for nombre, objs in grupos:
        for o in objs:
            o.location = (x, 0.0, 0.0)
            alisar(o)
            todos.append(o)
        x += 2.5 if nombre == "campana" else 1.2
    # El badajo, en su sitio dentro de la campana (solo para mirar).
    bad.location = (bad.location.x, 0.0, -0.15)
    mover_vista = [(ca, 0.45), (cm, 0.6), (chh, 0.6), (cand, 0.55), (ch, 0.25)]
    for o, dx in mover_vista:
        o.location = (o.location.x + dx, 0.0, 0.0)
    total = 0
    for o in todos:
        t = triangulos(o)
        total += t
        co = coords(o)
        print("ATREZZO %-18s %6d tri  x[%.3f %.3f] y[%.3f %.3f] z[%.3f %.3f]" % (
            o.name, t, co[:, 0].min(), co[:, 0].max(), co[:, 1].min(), co[:, 1].max(),
            co[:, 2].min(), co[:, 2].max()))
    print("ATREZZO total: %d triángulos" % total)
    os.makedirs(os.path.dirname(os.path.abspath(SALIDA)), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=os.path.abspath(SALIDA), export_format="GLB", use_selection=False,
        export_yup=True, export_apply=False, export_normals=True, export_tangents=False,
        export_materials="EXPORT", export_vertex_color="ACTIVE",
        export_all_vertex_colors=False, export_active_vertex_color_when_no_material=True,
        export_animations=False, export_skins=False, export_morph=False)
    print("ATREZZO guardado en", os.path.abspath(SALIDA))
    if VISTAS:
        renders(VISTAS, grupos)
        print("ATREZZO vistas en", VISTAS)


main()
