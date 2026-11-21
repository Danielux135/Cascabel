# arquitectura_capitel.py — el capitel de las dos columnas del ábside: un capitel
# cúbico con una fila de tres calaveras en cada cara.
#
#   python cripta3d/herramientas/blender3d.py cripta3d/blender/arquitectura_capitel.py -- cripta3d/modelos/arquitectura_capitel.glb [carpeta_vistas]
#
# Lo monta «arquitectura» (`cripta3d/mundo/arquitectura.gd`) sobre el collarino de
# cada columna y le pone la piedra de la biblioteca: aquí solo sale LA FORMA y el
# color de vértice (R oclusión, G canto), que es lo que el material lee.
#
# Por qué un capitel de calaveras: es la talla que dice «cripta» desde lejos sin
# un rótulo, y la calavera ya existe con anatomía de verdad
# (`fuentes/calavera_ia.glb`, ver su LEEME). Por qué en Blender y no por código:
# la calavera es una malla de 30.000 caras que hay que reducir, y la oclusión de
# una talla se hornea mirando qué tapa a qué, que es un trazado de rayos.
#
# Medidas (unidades de Godot, el origen en el centro de la cara de abajo):
#   abajo   círculo de radio 0,175 (el collarino del fuste mide 0,18)
#   arriba  cuadrado de 0,5 de lado, a 0,30 de alto (encima va el cimacio, de 0,6)
#   las calaveras, de 0,165 de alto, tres por cara tocándose, mirando hacia fuera
#   y un poco hacia abajo
#
# Lo que estaba mal (y por qué está así ahora): eran cuatro calaveritas en las
# esquinas, y de cerca casi no se distinguían. No era solo el tamaño: la malla
# se REDUCÍA SIN SOLDAR, y un diezmado sobre la sopa de triángulos de TRELLIS
# deja la calavera hecha confeti. Ahora se suelda, se remalla en una cáscara y
# luego se reduce (lo mismo que el osario, `arquitectura_osario.py`).
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SALIDA = os.path.abspath(argv[0] if argv else "cripta3d/modelos/arquitectura_capitel.glb")
VISTAS = argv[1] if len(argv) > 1 else ""
RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FUENTE = os.path.join(RAIZ, "cripta3d", "blender", "fuentes", "calavera_ia.glb")

R_ABAJO = 0.175
LADO_ARRIBA = 0.25
ALTO = 0.30
CARAS_CALAVERA = 200
ALTO_CALAVERA = 0.165


def traza(*a):
    print("[capitel]", *a, flush=True)


bpy.ops.wm.read_factory_settings(use_empty=True)


# ------------------------------------------------------------ el cuerpo cúbico

def cuerpo():
    """Un tronco que pasa de círculo (abajo) a cuadrado (arriba) con una
    superelipse: el capitel cúbico románico. Los anillos se aprietan arriba,
    donde la curva cambia más."""
    bm = bmesh.new()
    anillos = []
    n_ang = 32
    n_alt = 10
    for j in range(n_alt + 1):
        t = j / n_alt
        tt = 1.0 - (1.0 - t) ** 1.6
        z = ALTO * tt
        # El exponente: 2 es un círculo; 14 ya es un cuadrado de esquina viva.
        e = 2.0 + 12.0 * tt ** 2.2
        tam = R_ABAJO + (LADO_ARRIBA - R_ABAJO) * tt ** 1.3
        # Un bocel en el arranque: el capitel no nace a ras del collarino.
        tam += 0.008 * math.exp(-((t - 0.06) / 0.04) ** 2)
        anillo = []
        for k in range(n_ang):
            a = 2.0 * math.pi * k / n_ang + math.pi / 4.0
            c, s = math.cos(a), math.sin(a)
            x = math.copysign(abs(c) ** (2.0 / e), c) * tam
            y = math.copysign(abs(s) ** (2.0 / e), s) * tam
            anillo.append(bm.verts.new((x, y, z)))
        anillos.append(anillo)
    for j in range(n_alt):
        for k in range(n_ang):
            k2 = (k + 1) % n_ang
            bm.faces.new((anillos[j][k], anillos[j][k2], anillos[j + 1][k2], anillos[j + 1][k]))
    # La tapa de arriba (la tapa el cimacio, pero así la pieza es cerrada).
    bm.faces.new(list(reversed(anillos[-1])))
    bm.normal_update()
    me = bpy.data.meshes.new("capitel")
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new("capitel", me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


# ---------------------------------------------------------------- la calavera

def calavera_base():
    antes = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=FUENTE)
    mallas = [o for o in bpy.context.scene.objects if o.type == "MESH" and o not in antes]
    ob = mallas[0]
    ob.data.materials.clear()
    # Soldar en su escala, remallar en una cáscara y reducir (ver la cabecera).
    ob.data.transform(ob.matrix_world)
    ob.matrix_world = Matrix.Identity(4)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0015)
    bm.to_mesh(ob.data)
    bm.free()
    rem = ob.modifiers.new("cascara", "REMESH")
    rem.mode = "VOXEL"
    rem.voxel_size = 0.025
    mod = ob.modifiers.new("reducir", "DECIMATE")
    ratio = 0.02
    me = None
    for _ in range(10):
        mod.ratio = min(ratio, 1.0)
        dg = bpy.context.evaluated_depsgraph_get()
        if me is not None:
            bpy.data.meshes.remove(me)
        me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
        bm = bmesh.new()
        bm.from_mesh(me)
        bmesh.ops.triangulate(bm, faces=bm.faces)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
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


def construir():
    base = cuerpo()
    me_cal = calavera_base()
    # La fuente: 1 de alto, posada en el suelo, mirando a −Y. Se escala, se sube
    # el centro al origen y se inclina hacia abajo.
    piezas = [base]
    for k in range(4):
        ang = k * math.pi / 2.0
        hacia = Vector((math.cos(ang), math.sin(ang), 0.0))
        lado = Vector((-hacia.y, hacia.x, 0.0))
        for j, d in enumerate((-0.155, 0.0, 0.155)):
            m = Matrix.Translation(Vector((0.0, 0.08, -0.5)))
            m = Matrix.Scale(ALTO_CALAVERA * (1.06 if j == 1 else 1.0), 4) @ m
            m = Matrix.Rotation(math.radians(-16.0), 4, "X") @ m
            # Las de los lados, un poco abiertas: así se tocan sin meterse una
            # en otra y la fila sigue la cara.
            m = Matrix.Rotation(math.radians(-d * 70.0), 4, "Z") @ m
            # Que mire hacia `hacia`: la fuente mira a −Y.
            giro = math.atan2(hacia.y, hacia.x) + math.pi / 2.0
            m = Matrix.Rotation(giro, 4, "Z") @ m
            centro = hacia * 0.235 + lado * d
            m = Matrix.Translation(Vector((centro.x, centro.y, ALTO - ALTO_CALAVERA * 0.62))) @ m
            piezas.append(poner(me_cal, "calavera_%d_%d" % (k, j), m))
    bpy.data.meshes.remove(me_cal)
    # Todo en una malla.
    bpy.ops.object.select_all(action="DESELECT")
    for p in piezas:
        p.select_set(True)
    bpy.context.view_layer.objects.active = base
    bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


# --------------------------------------------------- el color de vértice

def hornear(ob):
    """R: cuánto cielo ve cada vértice (rayos en el hemisferio de su normal, que
    chocan contra la propia pieza). G: el canto, por convexidad con los vecinos."""
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.verts.ensure_lookup_table()
    bm.normal_update()
    arbol = BVHTree.FromBMesh(bm)
    # Direcciones repartidas por una espiral de Fibonacci en la semiesfera.
    dirs = []
    n_dir = 40
    for i in range(n_dir):
        z = 1.0 - (i + 0.5) / n_dir * 0.85
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
            golpe = arbol.ray_cast(v.co + n * 0.002, w, 0.07)
            # Pesa más lo que tapa de frente (coseno).
            peso += d.z
            if golpe[0] is not None:
                tapado += d.z * (1.0 - golpe[3] / 0.07 * 0.6)
        oclu.append(1.0 - min(1.0, tapado / max(peso, 1e-6) * 1.1))
    # Dos pasadas de suavizado con los vecinos: sin ellas sale grano.
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
        conv = acc / max(c, 1)
        canto.append(max(0.0, min(1.0, conv * 2.2)))
    # El canto también se suaviza: la calavera tiene más relieve que vértices, y
    # sin suavizar el desgaste sale a motas.
    for _ in range(3):
        nuevo = []
        for v in bm.verts:
            s = canto[v.index]
            c = 1.0
            for e in v.link_edges:
                s += canto[e.other_vert(v).index]
                c += 1.0
            nuevo.append(s / c)
        canto = nuevo
    me = ob.data
    capa = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    for i, (o, g) in enumerate(zip(oclu, canto)):
        # La oclusión baja hasta 0,14: con el suelo en 0,3 las órbitas no se
        # leían y el capitel parecía liso. Que una órbita salga negra es lo que
        # dice «calavera» a 60 píxeles.
        capa.data[i].color = (0.14 + 0.86 * o, g * 0.6, 0.0, 1.0)
    me.color_attributes.active_color = capa
    try:
        me.color_attributes.render_color_index = 0
    except Exception:
        pass
    bm.free()
    traza("horneado: %d vértices, oclusión media %.2f" % (len(oclu), sum(oclu) / len(oclu)))


def material(ob):
    mat = bpy.data.materials.new("piedra")
    mat.diffuse_color = (0.33, 0.32, 0.29, 1.0)
    arbol = mat.node_tree
    if arbol is not None:
        bsdf = next((n for n in arbol.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if bsdf is not None:
            bsdf.inputs["Base Color"].default_value = (0.33, 0.32, 0.29, 1.0)
            bsdf.inputs["Roughness"].default_value = 0.9
    ob.data.materials.append(mat)


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


def vistas(carpeta, ob):
    os.makedirs(carpeta, exist_ok=True)
    esc = bpy.context.scene
    esc.render.engine = "BLENDER_WORKBENCH"
    esc.render.resolution_x = 640
    esc.render.resolution_y = 640
    sombra = esc.display.shading
    sombra.light = "STUDIO"
    sombra.color_type = "VERTEX"
    sombra.show_cavity = True
    sombra.cavity_type = "BOTH"
    esc.world = bpy.data.worlds.new("fondo")
    cam_d = bpy.data.cameras.new("cam")
    cam_d.lens = 70.0
    cam = bpy.data.objects.new("cam", cam_d)
    esc.collection.objects.link(cam)
    esc.camera = cam
    for tipo in ("SINGLE", "VERTEX"):
        sombra.color_type = tipo
        for nombre, ojo in (("frente", Vector((0.0, -1.6, 0.45))), ("esquina", Vector((0.75, -0.75, 0.25)))):
            cam.location = ojo
            d = Vector((0.0, 0.0, 0.16)) - ojo
            cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
            esc.render.filepath = os.path.join(carpeta, "capitel_%s_%s.png" % (nombre, tipo.lower()))
            bpy.ops.render.render(write_still=True)


ob = construir()
traza("caras: %d" % len(ob.data.polygons))
hornear(ob)
material(ob)
exportar()
if VISTAS:
    vistas(VISTAS, ob)
