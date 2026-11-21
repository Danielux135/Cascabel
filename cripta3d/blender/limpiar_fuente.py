# limpiar_fuente.py — deja una malla generada por IA lista para servir de FUENTE a otros guiones.
#
#   python cripta3d/herramientas/blender3d.py cripta3d/blender/limpiar_fuente.py -- entrada.glb salida.glb [caras]
#
# Una malla de TRELLIS trae ~95.000 caras y una textura de 1024 con la luz ya
# pintada. Aquí solo se aprovecha LA FORMA —el material se lo pone la biblioteca
# de la prueba, para que no desentone—, así que se le quita el material, se
# reduce a `caras` (30.000 por defecto: de sobra para volver a reducirla en cada
# guion que la use), se centra, se posa en el suelo y se escala a 1 de alto.
# Lo que sale va a `cripta3d/blender/fuentes/`, que tiene un `.gdignore`: son
# fuentes de trabajo, Godot no las importa y no viajan en el juego.
import os
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
entrada, salida = argv[0], argv[1]
caras = int(argv[2]) if len(argv) > 2 else 30000

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=entrada)
mallas = [o for o in bpy.context.scene.objects if o.type == "MESH"]
bpy.ops.object.select_all(action="DESELECT")
for o in mallas:
    o.select_set(True)
bpy.context.view_layer.objects.active = mallas[0]
if len(mallas) > 1:
    bpy.ops.object.join()
ob = bpy.context.view_layer.objects.active
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
ob.data.materials.clear()
antes = len(ob.data.polygons)

# Soldar lo que el generador dejó suelto y reducir.
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0005)
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode="OBJECT")
if len(ob.data.polygons) > caras:
    mod = ob.modifiers.new("reducir", "DECIMATE")
    mod.ratio = caras / float(len(ob.data.polygons))
    bpy.ops.object.modifier_apply(modifier=mod.name)

# Centrada en planta, posada en el suelo y con 1 de alto.
vs = [ob.matrix_world @ v.co for v in ob.data.vertices]
vmin = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
vmax = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
alto = max(vmax.z - vmin.z, 1e-6)
centro = Vector(((vmin.x + vmax.x) / 2, (vmin.y + vmax.y) / 2, vmin.z))
for v in ob.data.vertices:
    v.co = (v.co - centro) / alto
for p in ob.data.polygons:
    p.use_smooth = True
ob.name = os.path.splitext(os.path.basename(salida))[0]
ob.data.name = ob.name

os.makedirs(os.path.dirname(os.path.abspath(salida)), exist_ok=True)
bpy.ops.object.select_all(action="DESELECT")
ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=salida, export_format="GLB", use_selection=True,
                          export_materials="NONE")
tam = (vmax - vmin) / alto
print("FUENTE %s: %d -> %d caras, tamaño %.2f x %.2f x %.2f, %d KB" % (
    ob.name, antes, len(ob.data.polygons), tam.x, tam.y, tam.z, os.path.getsize(salida) // 1024))
