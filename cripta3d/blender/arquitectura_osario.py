# arquitectura_osario.py — lo que hay dentro de un nicho de osario: una fila de
# cabezas de hueso largo (las epífisis, de frente) y encima tres calaveras.
#
#   python cripta3d/herramientas/blender3d.py cripta3d/blender/arquitectura_osario.py -- cripta3d/modelos/arquitectura_osario.glb [carpeta_vistas]
#
# Lo reparte «arquitectura» (`cripta3d/mundo/arquitectura.gd`, `_osario`) en los
# nichos de los arcos ciegos del muro del fondo, con un MultiMesh y el hueso de
# la biblioteca: aquí solo sale LA FORMA y el color de vértice (R oclusión, G
# canto). Por qué un osario: el muro de la sala era un paño liso, y una pared de
# calaveras es lo que dice «cripta» en silueta, de lejos y sin un rótulo.
#
# Por qué tan pocas caras: van 12 nichos con tres calaveras cada uno, a 8 o 10
# unidades de la cámara de juego (una calavera ahí son unos 15 píxeles). Cada
# nicho ronda los mil triángulos; la calavera sale de la misma malla que el
# capitel (`fuentes/calavera_ia.glb`), reducida mucho más. Salen TRES nichos
# distintos (ver VARIANTES).
#
# Medidas (unidades de Godot; el origen, en el centro del borde de delante del
# suelo del nicho; el frente mira a +z en Godot, que es −y aquí):
#   el nicho por dentro mide 0,46 de ancho, 0,34 de alto y 0,22 de fondo
#   los huesos: cinco cabezas de 0,076, de lado a lado, en el suelo
#   las calaveras: tres de 0,17 de alto, encima y tocándose, un poco giradas
#   (más pequeñas, a 0,13, flotaban sueltas en el nicho y no se leía «osario»)
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SALIDA = os.path.abspath(argv[0] if argv else "cripta3d/modelos/arquitectura_osario.glb")
VISTAS = argv[1] if len(argv) > 1 else ""
RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FUENTE = os.path.join(RAIZ, "cripta3d", "blender", "fuentes", "calavera_ia.glb")

CARAS_CALAVERA = 240
ALTO_CALAVERA = 0.17

# LAS TRES VARIANTES (remate). Antes era UNA sola pieza de 170 caras repetida en
# los doce nichos: de cerca, «patatas» facetadas, alineadas a escuadra, todas
# iguales y del mismo tono. Ahora salen tres nichos distintos (`osario_a`, `_b`,
# `_c`), cada calavera con su giro, su talla y su tono, y la malla un poco más
# redonda (240 caras, remallado más fino y un suavizado). «arquitectura» los
# reparte al azar por los nichos, con giro y tono por nicho, y los junta en UNA
# malla (una llamada de dibujo, como el MultiMesh de antes).
# Cada calavera: (x, alto sobre el suelo, fondo, giro en Z, cabeceo en X,
# alabeo en Y, talla, tono). El tono multiplica la oclusión (R): el hueso de la
# biblioteca va de TIERRA_5 a TIERRA_6 con ella.
VARIANTES = {
    "osario_a": {
        "huesos": [-0.18, -0.09, 0.0, 0.09, 0.18],
        "calaveras": [(-0.152, 0.068, 0.05, -18.0, -6.0, 3.0, 0.96, 0.92),
                      (0.0, 0.068, 0.04, 9.0, -2.0, -2.0, 1.04, 1.0),
                      (0.152, 0.068, 0.05, 24.0, -8.0, 4.0, 0.92, 0.84)],
    },
    "osario_b": {
        "huesos": [-0.16, -0.055, 0.05, 0.155],
        # Dos delante y una entre ellas, metida al fondo, más alta y caída de
        # lado (apoyada en los huesos: más arriba flotaba).
        "calaveras": [(-0.115, 0.068, 0.04, -28.0, -4.0, 2.0, 1.0, 0.88),
                      (0.12, 0.068, 0.05, 14.0, -10.0, -3.0, 0.97, 0.97),
                      (0.0, 0.1, 0.13, 35.0, 6.0, 16.0, 0.86, 0.8)],
    },
    "osario_c": {
        "huesos": [-0.19, -0.115, -0.04, 0.035, 0.11, 0.185],
        # La de en medio, vuelta casi de perfil; la de la derecha, más pequeña.
        "calaveras": [(-0.15, 0.064, 0.05, -8.0, -3.0, -5.0, 1.02, 0.94),
                      (0.005, 0.066, 0.06, 52.0, -6.0, 0.0, 0.98, 0.86),
                      (0.158, 0.064, 0.04, -20.0, -12.0, 8.0, 0.88, 1.0)],
    },
}


def traza(*a):
    print("[osario]", *a, flush=True)


bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(7)


def calavera_base():
    antes = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=FUENTE)
    mallas = [o for o in bpy.context.scene.objects if o.type == "MESH" and o not in antes]
    ob = mallas[0]
    ob.data.materials.clear()
    # PRIMERO SE SUELDA, en su escala, y LUEGO se reduce. TRELLIS deja cada
    # cara con sus tres vértices: un diezmado sobre esa sopa de triángulos no
    # puede juntar nada y la calavera sale ESTALLADA en confeti (probado aquí:
    # a 340 caras era una nube de triángulos sueltos). El diezmado no clava el
    # número de caras: se tantea la proporción hasta quedarse cerca.
    ob.data.transform(ob.matrix_world)
    ob.matrix_world = Matrix.Identity(4)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0015)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(ob.data)
    bm.free()
    # Y aun soldada, la fuente trae islas sueltas (dientes, restos por dentro)
    # que el diezmado no sabe juntar: a 240 caras se quedaba en 1.200, con la
    # cáscara reducida a un tetraedro y las islas intactas. Un remallado por
    # vóxeles la deja en UNA cáscara cerrada, y esa sí se reduce bien.
    rem = ob.modifiers.new("cascara", "REMESH")
    rem.mode = "VOXEL"
    rem.voxel_size = 0.022
    # Un suavizado antes de reducir: lo que hacía «patata» eran las facetas
    # grandes y planas del remallado, no la falta de caras.
    lisa = ob.modifiers.new("alisar", "SMOOTH")
    lisa.factor = 0.6
    lisa.iterations = 3
    mod = ob.modifiers.new("reducir", "DECIMATE")
    ratio = CARAS_CALAVERA / float(max(len(ob.data.polygons), 1))
    me = None
    for _ in range(8):
        mod.ratio = min(ratio, 1.0)
        dg = bpy.context.evaluated_depsgraph_get()
        if me is not None:
            bpy.data.meshes.remove(me)
        me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
        bm = bmesh.new()
        bm.from_mesh(me)
        bmesh.ops.triangulate(bm, faces=bm.faces)
        bm.to_mesh(me)
        bm.free()
        caras = len(me.polygons)
        if abs(caras - CARAS_CALAVERA) < CARAS_CALAVERA * 0.12:
            break
        ratio *= CARAS_CALAVERA / float(max(caras, 1))
    me.validate()
    bpy.data.objects.remove(ob, do_unlink=True)
    traza("calavera reducida a %d caras" % len(me.polygons))
    return me


def poner(me_base, nombre, matriz):
    me = me_base.copy()
    me.transform(matriz)
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def cabeza_hueso(nombre, x, z, r):
    """Un hueso largo visto por la punta: la caña, un cilindro que se mete hacia
    el fondo, y la cabeza, dos cóndilos redondos con su hendidura. Eran una bola
    de 6×4 caras y un cono de 5: de cerca, dados redondeados."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=8, v_segments=5, radius=r)
    for v in bm.verts:
        v.co.y *= 0.62
        # Dos cóndilos: la cabeza no es una bola, tiene una hendidura en medio.
        v.co.z *= 1.0 - 0.28 * math.exp(-(v.co.x / (r * 0.32)) ** 2) * (1.0 if v.co.z > 0 else 0.0)
        v.co.x *= 1.12
    # La caña: más estrecha que la cabeza, con el cuello que se ensancha.
    bmesh.ops.create_cone(bm, cap_ends=False, cap_tris=False, segments=6, radius1=r * 0.5,
                          radius2=r * 0.42, depth=0.18,
                          matrix=Matrix.Translation((0.0, 0.1, 0.0)) @ Matrix.Rotation(math.pi / 2, 4, "X"))
    me = bpy.data.meshes.new(nombre)
    bm.to_mesh(me)
    bm.free()
    me.transform(Matrix.Translation((x, -0.02, z)) @ Matrix.Rotation(random.uniform(-0.5, 0.5), 4, "Y")
                 @ Matrix.Rotation(random.uniform(-0.12, 0.12), 4, "Z"))
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def construir(me_cal, nombre, receta):
    """Un nicho: su fila de huesos y sus calaveras, en UNA malla."""
    piezas = []
    hx = receta["huesos"]
    r = 0.038 if len(hx) <= 5 else 0.033
    for k, x in enumerate(hx):
        piezas.append(cabeza_hueso("%s_hueso_%d" % (nombre, k), x + random.uniform(-0.008, 0.008), r, r))
    for k, (x, alto, fondo, giro, cabeceo, alabeo, talla, _tono) in enumerate(receta["calaveras"]):
        # La fuente: 1 de alto, posada en el suelo, mirando a −Y (ver el capitel).
        h = ALTO_CALAVERA * talla
        m = Matrix.Translation(Vector((0.0, 0.08, -0.5)))
        m = Matrix.Scale(h, 4) @ m
        m = Matrix.Rotation(math.radians(alabeo), 4, "Y") @ m
        m = Matrix.Rotation(math.radians(giro), 4, "Z") @ m
        m = Matrix.Rotation(math.radians(cabeceo), 4, "X") @ m
        m = Matrix.Translation(Vector((x, fondo, alto + h * 0.5))) @ m
        piezas.append(poner(me_cal, "%s_calavera_%d" % (nombre, k), m))
    bpy.ops.object.select_all(action="DESELECT")
    for p in piezas:
        p.select_set(True)
    bpy.context.view_layer.objects.active = piezas[0]
    bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    ob.name = nombre
    ob.data.name = nombre
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def entonar(ob, receta):
    """El tono de cada calavera (multiplica R): la que tenga el vértice más
    cerca, por encima de la fila de huesos. Los huesos, a 0,9."""
    capa = ob.data.color_attributes["Col"]
    for i, v in enumerate(ob.data.vertices):
        tono = 0.9
        if v.co.z > 0.07:
            mejor = 1.0e9
            for (x, alto, fondo, _g, _c, _a, talla, t) in receta["calaveras"]:
                c = Vector((x, fondo, alto + ALTO_CALAVERA * talla * 0.5))
                d = (v.co - c).length
                if d < mejor:
                    mejor = d
                    tono = t
        col = capa.data[i].color
        capa.data[i].color = (col[0] * tono, col[1], col[2], 1.0)


def hornear(ob, _caja):
    """R: cuánto se ve el exterior desde cada vértice (rayos en el hemisferio de
    su normal contra las piezas y el nicho). G: el canto, por convexidad."""
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.verts.ensure_lookup_table()
    bm.normal_update()
    todo = bmesh.new()
    todo.from_mesh(ob.data)
    # El nicho pesa la mitad: lo que tapa de verdad ya lo dibuja la luz.
    arbol = BVHTree.FromBMesh(todo)
    dirs = []
    n_dir = 48
    for i in range(n_dir):
        z = 1.0 - (i + 0.5) / n_dir * 0.9
        r = math.sqrt(max(0.0, 1.0 - z * z))
        a = i * 2.399963
        dirs.append(Vector((r * math.cos(a), r * math.sin(a), z)))
    oclu = []
    for v in bm.verts:
        n = v.normal.normalized()
        t = n.orthogonal().normalized()
        b = n.cross(t)
        tapado = 0.0
        peso = 0.0
        for d in dirs:
            w = t * d.x + b * d.y + n * d.z
            golpe = arbol.ray_cast(v.co + n * 0.002, w, 0.08)
            peso += d.z
            if golpe[0] is not None:
                tapado += d.z * (1.0 - golpe[3] / 0.08 * 0.5)
        oclu.append(1.0 - min(1.0, tapado / max(peso, 1e-6) * 1.15))
    for _ in range(2):
        nuevo = []
        for v in bm.verts:
            s = oclu[v.index]
            c = 1.0
            for e in v.link_edges:
                s += oclu[e.other_vert(v).index]
                c += 1.0
            nuevo.append(s / c)
        oclu = nuevo
    canto = []
    for v in bm.verts:
        n = v.normal.normalized()
        acc = 0.0
        c = 0
        for e in v.link_edges:
            d = v.co - e.other_vert(v).co
            if d.length > 1e-7:
                acc += n.dot(d.normalized())
                c += 1
        canto.append(max(0.0, min(1.0, acc / max(c, 1) * 2.0)))
    me = ob.data
    capa = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    for i, (o, g) in enumerate(zip(oclu, canto)):
        # Más hondo que el capitel (0,12 de suelo): las órbitas de una calavera
        # de 15 píxeles solo se leen si son NEGRAS.
        capa.data[i].color = (0.12 + 0.88 * o, g * 0.6, 0.0, 1.0)
    me.color_attributes.active_color = capa
    try:
        me.color_attributes.render_color_index = 0
    except Exception:
        pass
    bm.free()
    todo.free()
    traza("horneado: %d vértices, oclusión media %.2f" % (len(oclu), sum(oclu) / len(oclu)))


def exportar(obs):
    mat = bpy.data.materials.new("hueso")
    bpy.ops.object.select_all(action="DESELECT")
    for ob in obs:
        ob.data.materials.append(mat)
        ob.select_set(True)
    os.makedirs(os.path.dirname(SALIDA), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=SALIDA, export_format="GLB", use_selection=True,
        export_apply=False, export_yup=True, export_normals=True, export_tangents=False,
        export_vertex_color="ACTIVE", export_all_vertex_colors=False,
        export_active_vertex_color_when_no_material=True,
        export_materials="EXPORT", export_animations=False, export_skins=False,
        export_morph=False, export_extras=False)
    traza("GLB: %s (%.0f KB)" % (SALIDA, os.path.getsize(SALIDA) / 1024.0))


def vistas(carpeta, obs):
    os.makedirs(carpeta, exist_ok=True)
    esc = bpy.context.scene
    esc.render.engine = "BLENDER_WORKBENCH"
    esc.render.resolution_x = 640
    esc.render.resolution_y = 480
    sombra = esc.display.shading
    sombra.light = "STUDIO"
    sombra.color_type = "VERTEX"
    esc.world = bpy.data.worlds.new("fondo")
    cam_d = bpy.data.cameras.new("cam")
    cam_d.lens = 60.0
    cam = bpy.data.objects.new("cam", cam_d)
    esc.collection.objects.link(cam)
    esc.camera = cam
    # Las tres variantes en fila, una al lado de otra.
    for k, ob in enumerate(obs):
        ob.location.x = (k - 1) * 0.55
    cam.location = Vector((0.15, -1.6, 0.45))
    d = Vector((0.0, 0.05, 0.14)) - cam.location
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    esc.render.filepath = os.path.join(carpeta, "osario_nichos.png")
    bpy.ops.render.render(write_still=True)


me_cal = calavera_base()
obs = []
for nombre, receta in VARIANTES.items():
    ob = construir(me_cal, nombre, receta)
    traza("%s: %d caras" % (nombre, len(ob.data.polygons)))
    hornear(ob, None)
    entonar(ob, receta)
    obs.append(ob)
bpy.data.meshes.remove(me_cal)
exportar(obs)
if VISTAS:
    vistas(VISTAS, obs)
