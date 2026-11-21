# Fuentes: mallas generadas con IA

Formas que salen mal esculpidas por guion y que se generaron el 17-nov-2026 en
Hugging Face, con la cuenta de Daniel. **Aquí solo se aprovecha la forma**: no
traen material (se lo pone la biblioteca de la prueba) y los guiones de
`cripta3d/blender/` las importan, las reducen y hornean su color de vértice.

Esta carpeta tiene un `.gdignore`: Godot no la importa y no viaja en el juego.

| Fichero | Qué es | Caras | Cómo viene |
|---|---|---|---|
| `calavera_ia.glb` | calavera estilizada, con la mandíbula PEGADA al cráneo | 30.000 | 1 de alto, posada en el suelo, mirando a −Y (de frente en Blender) |
| `mano_ia.glb` | mano de esqueleto abierta, plana | 20.000 | 1 de alto, DE PIE sobre la muñeca, con los dedos hacia arriba |
| `*_concepto.webp` | la imagen de la que salió cada una | — | la de la gárgola no llegó a malla: se acabó la cuota del día |

## Cómo se hicieron

1. **Imagen de concepto** con `black-forest-labs/FLUX.1-schnell` (Space de
   Hugging Face, 768×768, 4 pasos). Un objeto solo, centrado, fondo gris liso,
   aspecto de arcilla: es lo que mejor convierte.
2. **Imagen → malla** con `microsoft/TRELLIS.2` (Space oficial, resolución
   512): `/preprocess_image`, `/image_to_3d` y `/extract_glb`.
3. **Limpieza** con `cripta3d/blender/limpiar_fuente.py`: sin material, soldada,
   reducida, centrada y escalada a 1 de alto.

Los encargos, tal cual:

- *calavera:* «Stylized cartoon human skull sculpture, chunky proportions, large
  round empty eye sockets, small triangular nose hole, five big blocky upper
  teeth, lower jaw slightly open, smooth matte bone-colored clay with fine
  cracks, three-quarter front view, single object centered and fully visible,
  plain neutral light grey seamless background, soft diffuse studio lighting,
  product photography, sharp focus»
- *mano:* «A stylized cartoon skeleton hand sculpture, chunky thick bones, four
  fat fingers spread and curled like a claw gripping the ground, short thumb,
  wrist bones at the back, palm facing down, matte bone-colored clay with fine
  cracks, three-quarter view from above, single object centered and fully
  visible, plain neutral light grey seamless background, soft diffuse studio
  lighting, sharp focus» — salió abierta y plana, no en garra: en un encargo con
  imagen manda la imagen que salga, no lo que se pidió.

## Lo que hay que saber

- **La cuota gratis da para dos mallas al día.** Cada malla son tres llamadas
  de GPU (imagen, 3D y extracción) y a la tercera pieza contestó «exceeded your
  ZeroGPU runs limit». Se renueva a las 24 horas.
- TRELLIS.2 es MIT y FLUX.1-schnell es Apache-2.0.
- Para generar más: los guiones están fuera del repo (usan el token de Daniel,
  que vive en su variable `HF_TOKEN` y no se escribe en ningún fichero). El
  cómo está en la skill `prueba-3d`.
