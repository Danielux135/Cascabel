# bola_cascabel.py — LA BOLA: un cascabel de acero, modelado por guion.
#
#   python cripta3d/herramientas/blender3d.py cripta3d/blender/bola_cascabel.py -- cripta3d/modelos/bola_cascabel.glb
#          [--vistas C:/carpeta/temporal]    además deja un render rápido con su color de vértice
#
# POR QUÉ ES UN CASCABEL. Las nueve cáscaras de bola del juego
# (`assets/.../bolas64`) son todas lo mismo: una esfera de metal con una RANURA
# atravesada. La de la mesa es la de acero, y aquí lleva lo que dice el encargo:
# acero gastado, remaches pequeños y la ranura negra. La ranura es lo único que
# deja ver que la bola RUEDA: sin ella una esfera girando es una esfera quieta.
#
# QUÉ SALE. Un GLB con dos objetos, que `cripta3d/mundo/bola.gd` busca por su
# nombre (solo coge la malla):
#
#   bola_casco   la cáscara: dos medias esferas de chapa con el cordón de la
#                costura detrás, la RANURA cortada de verdad (con grosor y los
#                labios biselados), dos coronas de remaches y unas abolladuras
#                que hacen que el reflejo del fuego tiemble. Acero de la
#                biblioteca, con color de vértice.
#   bola_hueco   lo de dentro, que se ve por la ranura: la cara de dentro de la
#                chapa (solo cerca de la ranura) y el BADAJO, la bolita suelta que
#                hace sonar un cascabel. En reposo es negro (carbón); con una
#                criatura dentro RESPLANDECE con su color, el badajo mucho y la
#                chapa poco (canal B). El material lo pone `bola.gd`.
#
# MEDIDAS. En unidades de Godot y a la medida de verdad: radio 0,09 (los 9 px
# de `radio_bola`). Así el detalle de la biblioteca («escala») se mide en mundo.
# La bola NUNCA cambia de tamaño (el invariante más viejo del juego); si un día
# cambiara el radio de la simulación, `bola.gd` escala la malla.
#
# EJES. Se modela en Blender (z arriba); el exportador pasa a y arriba. La
# ranura va por el ecuador y mira a −y aquí, que es +z en Godot: al jugador. Así
# sale horizontal, como en el sprite, y cualquier rodadura la voltea.
#
# COLOR DE VÉRTICE (la convención de la cripta): R oclusión (rayos contra la
# bola entera: la ranura y el pie de cada remache se oscurecen), G canto (los
# labios de la ranura, las cabezas de los remaches y el cordón: ahí se pela el
# acero y brilla), B libre (no se usa).

import math
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector, noise
from mathutils.bvhtree import BVHTree

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SALIDA = ARGV[0] if ARGV and not ARGV[0].startswith("--") else "cripta3d/modelos/bola_cascabel.glb"
VISTAS = ""
for _i, _a in enumerate(ARGV):
    if _a == "--vistas" and _i + 1 < len(ARGV):
        VISTAS = ARGV[_i + 1]

TAU = math.tau
R = 0.09
# La chapa: lo que se ve de canto en la ranura.
GROSOR = 0.11 * R
# La ranura: media altura y hasta qué ángulo llega el centro de sus puntas
# redondas, a cada lado del frente. En el sprite va de lado a lado casi entero;
# aquí da algo más de media vuelta, para que se vea desde casi cualquier sitio
# por dónde va la bola.
# *Probado y quitado:* 0,15·R de media altura (un 15 % del diámetro). De cerca
# era una ranura; a 30 px, la distancia de juego, desaparecía y quedaba una
# canica plateada cualquiera. En las nueve bolas del juego (`bolas64`) la ranura
# es una BANDA NEGRA de un 20-25 % del diámetro: es lo que dice «cascabel».
RANURA_W = 0.22 * R
# Y media vuelta larga: 92° a cada lado (antes, 74°). La bola RUEDA y la ranura
# gira con ella; más corta, desde la cámara de juego (que mira desde arriba)
# quedaba de espaldas o de canto casi siempre.
# *Probado y quitado:* 112° (dos tercios de vuelta). Se veía más veces, pero de
# cerca la bola era una almeja abierta, dos medias esferas con una boca, y no un
# cascabel.
RANURA_A = math.radians(92.0)
# EL PESO. La bola mide 25-35 px en juego y con multibola hay cuatro: la malla
# entera (cáscara + hueco) va por debajo de 4.000 triángulos. La primera versión
# llevaba 13.000 (una esfera de 64×32, remaches de diez lados, un cordón de 64
# anillos) y nada de eso se veía a la distancia de juego.
ESFERA_U, ESFERA_V = 32, 16

# ------------------------------------------------------------------ utilidades


def nueva(nombre, bm):
    malla = bpy.data.meshes.new(nombre)
    bm.normal_update()
    bm.to_mesh(malla)
    bm.free()
    obj = bpy.data.objects.new(nombre, malla)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def aplicar(obj):
    grafo = bpy.context.evaluated_depsgraph_get()
    vieja = obj.data
    nueva_m = bpy.data.meshes.new_from_object(obj.evaluated_get(grafo))
    obj.modifiers.clear()
    obj.data = nueva_m
    bpy.data.meshes.remove(vieja)
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


def torno(nombre, perfil, seg):
    """Superficie de revolución alrededor de z. `perfil` = [(r, z)]; un r = 0
    en un extremo cierra con un vértice."""
    bm = bmesh.new()
    anillos = []
    for r, z in perfil:
        if r < 1e-9:
            anillos.append([bm.verts.new((0.0, 0.0, z))])
        else:
            anillos.append([bm.verts.new((r * math.cos(TAU * k / seg), r * math.sin(TAU * k / seg), z))
                            for k in range(seg)])
    for a, b in zip(anillos[:-1], anillos[1:]):
        for k in range(seg):
            k2 = (k + 1) % seg
            try:
                if len(a) == 1:
                    bm.faces.new([a[0], b[k], b[k2]])
                elif len(b) == 1:
                    bm.faces.new([a[k], b[0], a[k2]])
                else:
                    bm.faces.new([a[k], a[k2], b[k2], b[k]])
            except ValueError:
                pass
    if len(anillos[0]) > 1:
        bm.faces.new(list(reversed(anillos[0])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return nueva(nombre, bm)


def triangulos(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


# ------------------------------------------------------------------- la cáscara


def esfera(nombre, radio, u, v):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=radio)
    return nueva(nombre, bm)


def cortador():
    """La ranura como sólido: una cápsula dibujada sobre el cilindro del
    ecuador (largo = ángulo, alto = z) y tendida radialmente de dentro afuera.
    Las rectas van muy partidas: el corte sigue la curva de la esfera."""
    contorno = []
    pasos_recta = 26
    pasos_punta = 8
    # Ida por abajo, de una punta a la otra; vuelta por arriba.
    for i in range(pasos_recta + 1):
        a = -RANURA_A + 2.0 * RANURA_A * i / pasos_recta
        contorno.append((a, -RANURA_W))
    for i in range(1, pasos_punta):
        t = -math.pi / 2 + math.pi * i / pasos_punta
        contorno.append((RANURA_A + (RANURA_W / R) * math.cos(t), RANURA_W * math.sin(t)))
    for i in range(pasos_recta + 1):
        a = RANURA_A - 2.0 * RANURA_A * i / pasos_recta
        contorno.append((a, RANURA_W))
    for i in range(1, pasos_punta):
        t = math.pi / 2 + math.pi * i / pasos_punta
        contorno.append((-RANURA_A + (RANURA_W / R) * math.cos(t), RANURA_W * math.sin(t)))
    bm = bmesh.new()
    dentro, fuera = 0.45 * R, 1.4 * R
    # El frente es −y: el ángulo 0 cae ahí.
    def punto(ang, z, rr):
        return (rr * math.sin(ang), -rr * math.cos(ang), z)
    a_ = [bm.verts.new(punto(a, z, dentro)) for a, z in contorno]
    b_ = [bm.verts.new(punto(a, z, fuera)) for a, z in contorno]
    n = len(contorno)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new([a_[i], a_[j], b_[j], b_[i]])
    # Las dos tapas (la de dentro y la de fuera) son trozos de cilindro. Van en
    # TIRAS de abajo arriba, una por paso de ángulo, y las puntas en abanico.
    # *Probado y quitado:* cada tapa como un solo polígono. Con la ranura de
    # media vuelta pasaba; al alargarla a más de 180° el polígono deja de ser
    # plano, el booleano exacto se lía y se comía media esfera (1.056 triángulos
    # de cáscara y el hueco vacío, sin un error).
    nr, kp = pasos_recta, pasos_punta
    def b(i):
        return i
    def p(j):
        return nr + j
    def t(m):
        return nr + kp + m
    def l(j):
        return 2 * nr + kp + j
    for anillo in (a_, b_):
        for i in range(nr):
            bm.faces.new([anillo[b(i)], anillo[b(i + 1)], anillo[t(nr - i - 1)], anillo[t(nr - i)]])
        bm.faces.new([anillo[b(nr)]] + [anillo[p(j)] for j in range(1, kp)] + [anillo[t(0)]])
        bm.faces.new([anillo[t(nr)]] + [anillo[l(j)] for j in range(1, kp)] + [anillo[b(0)]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return nueva("cortador", bm)


def casco():
    obj = esfera("bola_casco", R, ESFERA_U, ESFERA_V)
    # Chapa con grosor hacia dentro: por la ranura se ve el canto.
    mod = obj.modifiers.new("chapa", "SOLIDIFY")
    mod.thickness = GROSOR
    mod.offset = -1.0
    mod.use_even_offset = True
    aplicar(obj)
    corte = cortador()
    mod = obj.modifiers.new("ranura", "BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.solver = "EXACT"
    mod.object = corte
    aplicar(obj)
    bpy.data.objects.remove(corte)
    # Los labios de la ranura, romos: sin bisel el corte es una raya de ordenador
    # y no coge el brillo del fuego. El límite de ángulo deja fuera la esfera
    # (sus caras vecinas apenas se tuercen cinco grados).
    mod = obj.modifiers.new("bisel", "BEVEL")
    mod.width = 0.03 * R
    mod.segments = 2
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(35.0)
    mod.miter_outer = "MITER_ARC"
    aplicar(obj)
    # La cara de dentro de la chapa solo se ve por la ranura, y lo que se ve
    # tiene que ser NEGRO: con el acero, el reflejo del cielo la encendía y la
    # ranura se leía como dos rayas en vez de un hueco. Así que se separa y se
    # va con el hueco (otro material), y lo que queda lejos de la ranura se tira:
    # son la mitad de los triángulos y no se ven nunca.
    dentro = obj.copy()
    dentro.data = obj.data.copy()
    dentro.name = "dentro"
    bpy.context.scene.collection.objects.link(dentro)
    for o, quedarse_dentro in ((obj, False), (dentro, True)):
        bm = bmesh.new()
        bm.from_mesh(o.data)
        fuera = []
        for f in bm.faces:
            c = f.calc_center_median()
            es_dentro = c.length < R - GROSOR * 0.5
            if quedarse_dentro:
                if not es_dentro or distancia_ranura(c) > 0.45 * R:
                    fuera.append(f)
            elif es_dentro:
                fuera.append(f)
        bmesh.ops.delete(bm, geom=fuera, context="FACES")
        bm.to_mesh(o.data)
        bm.free()
        o.data.update()
    return obj, dentro


def distancia_ranura(p):
    """Lo que dista un punto de la ranura, medido sobre la esfera."""
    ang = math.atan2(p.x, -p.y)
    s = R * max(abs(ang) - RANURA_A, 0.0)
    dz = max(abs(p.z) - RANURA_W, 0.0) if s <= 0.0 else abs(p.z)
    if s > 0.0:
        return max(math.hypot(s, p.z) - RANURA_W, 0.0)
    return dz


def cordon():
    """La costura: un cordón de chapa doblada por el ecuador, por detrás, que se
    afina hasta perderse antes de llegar a las puntas de la ranura."""
    bm = bmesh.new()
    seg = 32
    lados = 5
    rc = 0.032 * R
    desde = RANURA_A + math.radians(22.0)
    hasta = TAU - desde
    anillos = []
    for i in range(seg + 1):
        t = i / seg
        ang = desde + (hasta - desde) * t
        # Se afina en los dos extremos.
        k = min(1.0, math.sin(math.pi * t) * 3.0)
        centro = Vector((math.sin(ang), -math.cos(ang), 0.0)) * (R - rc * 0.35)
        radial = centro.normalized()
        anillo = []
        for s in range(lados):
            phi = TAU * s / lados
            p = centro + (radial * math.cos(phi) + Vector((0.0, 0.0, 1.0)) * math.sin(phi)) * rc * k
            anillo.append(bm.verts.new(p))
        anillos.append(anillo)
    for a, b in zip(anillos[:-1], anillos[1:]):
        for s in range(lados):
            s2 = (s + 1) % lados
            bm.faces.new([a[s], a[s2], b[s2], b[s]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return nueva("cordon", bm)


def remaches():
    """Dos coronas de cabezas de remache, una por encima y otra por debajo de la
    ranura, al tresbolillo. Pequeñas: de cerca son remaches; de lejos, el
    brillo menudo que dice que esto es una pieza forjada y no una canica."""
    partes = []
    rr = 0.068 * R
    alto = 0.038 * R
    perfil = [(rr * 0.97, -alto * 0.8), (rr, 0.0)]
    for a in np.linspace(0.45, math.pi / 2, 3):
        perfil.append((rr * math.cos(a), alto * math.sin(a)))
    perfil[-1] = (0.0, alto)
    # Más arriba y más abajo que antes (0,38 rad → 0,46): con la ranura ancha,
    # una corona a 38° le mordía los labios.
    for fila, lat in ((0, math.radians(46.0)), (1, -math.radians(46.0))):
        n = 8
        for k in range(n):
            ang = TAU * (k + 0.5 * fila) / n
            o = torno("remache", perfil, 6)
            normal = Vector((math.cos(lat) * math.sin(ang), -math.cos(lat) * math.cos(ang), math.sin(lat)))
            giro = Vector((0.0, 0.0, 1.0)).rotation_difference(normal).to_matrix().to_4x4()
            o.data.transform(Matrix.Translation(normal * (R - 0.004 * R)) @ giro)
            partes.append(o)
    return partes


def abollar(obj, amplitud, escala, semilla):
    """El acero gastado no es una esfera perfecta: unas abolladuras suaves, que
    no se ven como forma sino en cómo tiembla el reflejo del fuego al rodar."""
    malla = obj.data
    malla.update()
    for v in malla.vertices:
        p = Vector(v.co) * escala + Vector((semilla, semilla * 1.7, semilla * 0.3))
        d = noise.noise(p) * amplitud
        dir_ = Vector(v.co).normalized() if Vector(v.co).length > 1e-9 else Vector((0, 0, 1))
        v.co = Vector(v.co) + dir_ * d
    malla.update()


# ------------------------------------------------------------ el color de vértice


def hemisferio(n):
    d = []
    for i in range(n):
        u = (i + 0.5) / n
        a = i * math.pi * (3.0 - math.sqrt(5.0))
        r = math.sqrt(u)
        d.append((r * math.cos(a), r * math.sin(a), math.sqrt(max(1.0 - u, 0.0))))
    return np.array(d)


def arbol_de(objs):
    verts = []
    polis = []
    for o in objs:
        base = len(verts)
        mw = o.matrix_world
        verts += [tuple(mw @ v.co) for v in o.data.vertices]
        polis += [tuple(base + i for i in p.vertices) for p in o.data.polygons]
    return BVHTree.FromPolygons(verts, polis)


def oclusion(obj, arbol, radio, rayos=32):
    malla = obj.data
    n = len(malla.vertices)
    co = np.zeros(n * 3)
    malla.vertices.foreach_get("co", co)
    co = co.reshape(n, 3)
    no = np.zeros(n * 3)
    malla.vertices.foreach_get("normal", no)
    no = no.reshape(n, 3)
    dirs = hemisferio(rayos)
    ao = np.ones(n)
    for i in range(n):
        nz = no[i]
        ref = np.array([0.0, 0.0, 1.0]) if abs(nz[2]) < 0.9 else np.array([1.0, 0.0, 0.0])
        tx = np.cross(ref, nz)
        tx /= max(np.linalg.norm(tx), 1e-9)
        ty = np.cross(nz, tx)
        origen = Vector(co[i] + nz * 0.0002)
        tapado = 0.0
        for d in dirs:
            w = tx * d[0] + ty * d[1] + nz * d[2]
            golpe = arbol.ray_cast(origen, Vector(w), radio)
            if golpe[0] is not None:
                tapado += 1.0 - golpe[3] / radio
        ao[i] = 1.0 - min(tapado / rayos * 1.6, 1.0)
    return ao


def vecinos(obj):
    lista = [[] for _ in range(len(obj.data.vertices))]
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


def hornear(obj, todos, ganancia_canto):
    arbol = arbol_de(todos)
    vec = vecinos(obj)
    ao = suavizar(oclusion(obj, arbol, 0.9 * R), vec, 1)
    # La curvatura de una esfera de radio R ya da un «canto» de fondo; se le
    # quita para que solo cuenten los filos de verdad.
    c = canto(obj, vec)
    c = c - float(np.median(c))
    g = suavizar(np.clip(c * ganancia_canto, 0.0, 1.0), vec, 1)
    # B: lo cerca que queda cada vértice de la ranura. Es la luz que se escapa
    # de dentro cuando hay una criatura: tiñe los labios y se apaga a un tercio
    # de radio. La cara de dentro de la chapa, entera.
    azul = np.zeros(len(ao))
    for i, v in enumerate(obj.data.vertices):
        p = Vector(v.co)
        if p.length < R - GROSOR * 0.5:
            azul[i] = 1.0
        else:
            d = distancia_ranura(p) / (0.33 * R)
            azul[i] = max(0.0, 1.0 - d) ** 2
    pintar(obj, 0.08 + 0.92 * ao, g, azul)


def material(obj, color):
    nombre = "muestra_%02x%02x%02x" % tuple(int(c * 255) for c in color)
    mat = bpy.data.materials.get(nombre) or bpy.data.materials.new(nombre)
    if mat.node_tree is not None:
        for n in mat.node_tree.nodes:
            if n.type == "BSDF_PRINCIPLED":
                n.inputs["Base Color"].default_value = (color[0], color[1], color[2], 1.0)
                n.inputs["Metallic"].default_value = 0.9
                n.inputs["Roughness"].default_value = 0.35
    obj.data.materials.clear()
    obj.data.materials.append(mat)


def alisar(obj, angulo):
    malla = obj.data
    malla.shade_smooth()
    try:
        malla.set_sharp_from_angle(angle=math.radians(angulo))
    except Exception:
        pass
    malla.update()


def renders(carpeta, objs):
    escena = bpy.context.scene
    escena.render.engine = "BLENDER_WORKBENCH"
    escena.display.shading.light = "STUDIO"
    escena.display.shading.color_type = "VERTEX"
    escena.render.resolution_x = 1200
    escena.render.resolution_y = 600
    cam_d = bpy.data.cameras.new("cam")
    cam_d.lens = 85
    cam = bpy.data.objects.new("cam", cam_d)
    escena.collection.objects.link(cam)
    escena.camera = cam
    os.makedirs(carpeta, exist_ok=True)
    for nombre, pos in (("frente", (0.0, -0.75, 0.25)), ("arriba", (0.35, -0.35, 0.65))):
        cam.location = Vector(pos)
        cam.rotation_euler = (Vector((0, 0, 0)) - cam.location).to_track_quat("-Z", "Y").to_euler()
        escena.render.filepath = os.path.join(carpeta, "bola_blender_%s.png" % nombre)
        bpy.ops.render.render(write_still=True)


# --------------------------------------------------------------------- montaje


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    cuerpo, dentro = casco()
    partes = [cuerpo, cordon()] + remaches()
    obj = unir("bola_casco", partes)
    abollar(obj, 0.006 * R, 4.0 / R, 3.1)
    # El hueco: la cara de dentro de la chapa (lo que se ve por la ranura) y,
    # más al fondo, el badajo: la bolita de hierro suelta que hace sonar un
    # cascabel. Es lo que se ve si se mira la ranura de frente.
    badajo = esfera("badajo", 0.5 * R, 14, 7)
    for v in badajo.data.vertices:
        v.co.z -= 0.18 * R
    # La cara de dentro sale del corte booleano llena de abanicos: 1.300
    # triángulos de carbón negro que solo se ven por la ranura. A la mitad no se
    # nota (es negro y está en sombra) y la bola baja de 4.000.
    mod = dentro.modifiers.new("aligerar", "DECIMATE")
    mod.decimate_type = "COLLAPSE"
    mod.ratio = 0.45
    aplicar(dentro)
    n_dentro = len(dentro.data.vertices)
    hueco = unir("bola_hueco", [dentro, badajo])
    hornear(obj, [obj, hueco], 2.2)
    vec_h = vecinos(hueco)
    ao_h = suavizar(oclusion(hueco, arbol_de([obj, hueco]), 0.9 * R), vec_h, 1)
    n_h = len(hueco.data.vertices)
    # B: cuánta luz da cada parte cuando hay una criatura dentro. El badajo
    # entero; la cara de dentro de la chapa, poca. Así la luz sale DE DENTRO y
    # no es un tubo encendido de punta a punta (`unir` pone primero lo de
    # `dentro` y luego el badajo).
    azul_h = np.ones(n_h)
    azul_h[:n_dentro] = 0.3
    pintar(hueco, 0.1 + 0.9 * ao_h, np.zeros(n_h), azul_h)
    alisar(obj, 40.0)
    alisar(hueco, 80.0)
    material(obj, (0.55, 0.57, 0.6))
    material(hueco, (0.05, 0.05, 0.05))
    for o in (obj, hueco):
        co = np.array([tuple(v.co) for v in o.data.vertices])
        print("BOLA %-12s %6d tri  radio max %.4f" % (o.name, triangulos(o), float(np.sqrt((co * co).sum(1)).max())))
    os.makedirs(os.path.dirname(os.path.abspath(SALIDA)), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=os.path.abspath(SALIDA), export_format="GLB", use_selection=False,
        export_yup=True, export_apply=False, export_normals=True, export_tangents=False,
        export_materials="EXPORT", export_vertex_color="ACTIVE",
        export_all_vertex_colors=False, export_active_vertex_color_when_no_material=True,
        export_animations=False, export_skins=False, export_morph=False)
    print("BOLA guardado en", os.path.abspath(SALIDA))
    if VISTAS:
        renders(VISTAS, [obj, hueco])
        print("BOLA vistas en", VISTAS)


main()
