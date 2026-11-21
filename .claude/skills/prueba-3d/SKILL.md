---
name: prueba-3d
description: "Cómo se trabaja el 3D de Cascabel (las pruebas «ÓRBITA» en prueba3d/ y «CRIPTA» en cripta3d/): capturar Godot SIN ventana con godot3d.py (escritorio oculto, candado, paso fijo), Blender sin interfaz con blender3d.py, el visor de criaturas, hoja.py, límites del motor Compatibility (web), convención de color de vértice, Hugging Face para imagen→3D, y las trampas ya pagadas. Cárgala antes de tocar cripta3d/ o prueba3d/, antes de lanzar Godot o Blender para mirar algo 3D, y antes de modelar, iluminar o capturar."
---

# Prueba 3D: herramientas, motor y trampas

Vecinas: `export-web` (lo que cambia en el navegador), `gdscript-bateria`
(trampas de GDScript y la batería), `arte-sprites-ia` y `animacion-sprites`
(si del 3D se hornean sprites). La dirección de arte y los contratos de la
prueba en curso están en `cripta3d/LEEME.md`: esto es lo que vale para
cualquier trabajo 3D en este repo.

- **Una trampa nueva de 3D se escribe AQUÍ**, con su medida.
- **Lo visual se mira, no se deduce**: nada se da por bueno sin abrir la captura.

## Dónde vive

- La rama es `prueba-3d` y se trabaja en **`C:\dev\tilt-os-3d`** (un worktree).
  `C:\dev\tilt-os` es `master` y no se toca desde el trabajo 3D.
- `prueba3d/` = «ÓRBITA» (publicada en danielux.es/cascabel-3d). `cripta3d/` =
  «CRIPTA». Ninguna toca `sim/`, `render/`, `tests/`, `assets/` ni `data/`.
- **La batería escanea TODO el proyecto**: un `.quit` o la palabra entre
  comillas en cualquier `.gd` la pone en rojo (solo `VistaMesa.salir()` sale del
  juego). Una escena de prueba se cierra con `--quit-after`, no desde el guion.
  Un guion de sonda que hereda de `SceneTree` sí puede llamar a `quit()` a secas.

## Lanzar Godot sin molestar: `cripta3d/herramientas/godot3d.py`

    python cripta3d/herramientas/godot3d.py importar
    python cripta3d/herramientas/godot3d.py escena res://cripta3d/cripta_3d.tscn --fotogramas 700 -- --capturas=C:/ruta --vista=0
    python cripta3d/herramientas/godot3d.py guion res://cripta3d/sonda_cripta.gd

- **`--headless` no dibuja.** Para capturar hace falta una ventana de verdad, y
  una ventana se le planta a Daniel en la pantalla. La herramienta crea la
  ventana en **otro escritorio de Windows** (`CreateDesktop` + `lpDesktop`): ni
  se ve ni roba el foco. Probado el 17-nov-2026 en la GTX 1060 con OpenGL
  (Compatibility) y con D3D12 (Forward+): las capturas salen iguales que a la
  vista.
- *Probado y descartado:* lanzar con `wShowWindow = SW_HIDE`. Godot enseña su
  ventana igualmente (a pantalla completa de tamaño, detrás de la activa).
- **Va a paso fijo** (`--fixed-fps 60`): en el escritorio oculto no hay
  sincronía vertical y un guion de 7 s se acababa en 1 con una sola captura.
  A paso fijo, `--fotogramas 600` son 10 s exactos de juego, dibuje a lo que
  dibuje.
- **Va con candado**: un solo Godot a la vez (dos se pisan `.godot/` al
  importar). El segundo espera.
- Tras crear o cambiar un `.glb`, un `.png` o una clase: `importar`. Si no,
  `Could not find type` o se sigue viendo el recurso viejo.
- El proyecto arranca a pantalla completa (`window/size/mode=3`): a mano, con
  `--windowed`.
- Forward+ se fuerza sin tocar `project.godot`: `--metodo forward`
  (`--rendering-method forward_plus`).

## Mirar: el visor y la hoja

- `cripta3d/visor.tscn` enseña UN cuerpo de criatura estado por estado (con una
  `Criatura` de mentira movida como la movería la caza) o gira UN `.glb`, con la
  luz de la cripta, y deja un PNG por toma.
- `cripta3d/herramientas/hoja.py salida.png carpeta --cols 5 --alto 300` junta
  todas las tomas en una imagen rotulada. Veintiuna capturas son una lectura.
- La escena principal captura sola con `-- --capturas=<carpeta> --vista=N
  [--demo] [--cada=2.0] [--calidad=alta]`.
- **VARIAS CÁMARAS EN UNA LANZADA.** `--toma=ojo/mira[/fov]` se repite y la
  captura N sale desde la toma N (unidades 3D: x = px/100, z = py/100). Antes
  cada pieza de cerca era una lanzada de Godot: los agentes gastaban veinticuatro
  por módulo y la mitad eran para cambiar la cámara de sitio.
- **LOS SUCESOS SE FUERZAN, NO SE ESPERAN.** `--guion=segundo:quién:qué,…`
  (campana armada o tocando, banco abatido, bola en el sarcófago, boca tapada,
  espectro escondido, golpe en un brasero…; la lista está en `_forzar` de
  `cripta_3d.gd`). Tres agentes entregaron diciendo «no he visto en captura la
  lápida cayendo ni el sarcófago tragando»: el figurante no acierta cuando hace
  falta. La primera captura es a los 2,0 s y las demás cada `--cada`: el suceso
  se pone unas décimas antes de su foto.
- **LA GIRA** (`cripta3d/herramientas/gira.py <carpeta> [juego] [piezas] [sala]
  [criaturas]`): las vistas de siempre, con cada suceso forzado en su toma, y
  una hoja por grupo. Es la misma cada vez: quien arregla mira lo mismo que miró
  quien criticó. **Ojo al escribir una toma a mano:** la sala tiene pilares en
  x≈−3 y x≈7, y una cámara puesta ahí cae DENTRO del pilar y sale tapada.
- **Las capturas van FUERA del repo** (Godot lo escanea entero).

## Blender sin interfaz: `cripta3d/herramientas/blender3d.py`

    python cripta3d/herramientas/blender3d.py cripta3d/blender/campana.py -- cripta3d/modelos/campana.glb

- Blender 5.3.0 portable en `C:\Tools\blender-5.3.0-windows-x64\blender.exe`.
  Se lanza con `--background --factory-startup --python-exit-code 1`.
- Probado en este equipo: EEVEE, Workbench y Cycles (OptiX en la 1060)
  renderizan sin interfaz, y exporta GLB.
- **En 5.3 no se toca `Material.use_nodes` ni `World.use_nodes`** (obsoletos:
  los materiales ya son de nodos). El nodo se busca por tipo
  (`n.type == "BSDF_PRINCIPLED"`).
- La lista estática de motores solo trae `BLENDER_EEVEE`: Workbench y Cycles se
  prueban ASIGNÁNDOLOS, no consultando el enumerado.
- Los argumentos del guion van detrás de `--`:
  `argv = sys.argv[sys.argv.index("--") + 1:]`.
- **Lo que se modela se genera por guion y el guion va al repo**
  (`cripta3d/blender/*.py` → `cripta3d/modelos/*.glb`), igual que `fuente.py` o
  `sonidos.py`: nada se edita a mano.

## El motor: Compatibility manda

El proyecto es `gl_compatibility` y la web solo puede eso (WebGL2; en 4.7 no
hay WebGPU). **Un aspecto que solo existe en Forward+ no puede ir a la web**,
así que lo que se enseña se construye para Compatibility.

- Compatibility **NO tiene** SSAO, SSIL, SSR, SDFGI, VoxelGI, niebla
  volumétrica, profundidad de campo, decals ni buffer de normales.
- **SÍ tiene**: brillo (glow), curva de tono, ajustes de color, niebla de
  profundidad y de altura, sombras (direccional, omni y foco), MSAA, sondas de
  reflexión, cielo con radiancia, y leer la pantalla y la profundidad desde un
  shader.
- Lo que falta se sustituye: oclusión horneada (color de vértice, mapa en el
  suelo), rayos de luz con mallas aditivas, reflejo plano con una segunda cámara
  (`prueba3d/prueba_3d.gd` ya lo hace), desenfoque en un shader de pantalla.
- **Como mucho 8 luces omni/foco por malla.** Una malla enorme pierde las que
  sobran y salen zonas negras: lo grande se parte en trozos.
- **`GeometryInstance3D.transparency` no hace nada** con un sombreador propio en
  Compatibility: para desvanecer algo hay que esconderlo o llevar el alfa en el
  sombreador (la campana en la cámara cenital se esconde, no se desvanece).
- **Forward+ tarda más de 240 s en compilar** los sombreadores de CRIPTA en
  D3D12 y `godot3d.py` lo mata (código 124) tras una o dos capturas. No es la
  vía de entrega: el proyecto y la web son Compatibility.

## Lo que costó en CRIPTA (21-nov-2026)

- **UNA SOMBRA DIRECCIONAL ES MEDIA ESCENA.** La luna con sombra eran 1.100
  llamadas de dibujo y 1,1 M de triángulos de 2.000 y 2,2 M: cada malla se
  dibuja otra vez por cada corte de la sombra. Y en MEDIA y BAJA, sin sombra, la
  luz bañaba la mesa entera y se perdía el motivo. En una sala cerrada la luna
  es un FOCO por el hueco, sin sombra: cuesta cero y es igual en las tres
  calidades. Antes de poner una sombra, contar cuántas mallas la van a pagar.
- **LO QUE SE MIDE EN CADA MÓDULO NO ES LO QUE PESA LA ESCENA.** Doce agentes
  hicieron cada uno su módulo «con cabeza» y la suma dio 2,2 M de triángulos:
  el atrezzo solo, el 56 %, en adornos de 30 píxeles. El reflejo y la sombra
  vuelven a dibujar todo lo que no se saque a mano de su capa. El presupuesto se
  reparte ANTES y se mide con `--fps 0 … -- --medir` en la escena entera.
- **UNA MEDIDA COMPARTIDA SE ESCRIBE UNA VEZ.** «Entorno» llevaba el suelo de la
  nave copiado a −0,42 y «arquitectura» lo puso a −0,9: la bruma flotó medio
  metro en el aire y nadie lo vio, porque cada uno miraba lo suyo. Lo que usan
  dos módulos va en el núcleo (`Y_SALA`, `Y_BOVEDA`).
- **EL QUE HACE UN MÓDULO NO VE LA ESCENA.** Los doce entregaron satisfechos y
  tres críticos de fuera le pusieron un 5,5: la zona de palas era la franja más
  oscura de la mesa, había cinco piedras distintas y veinte llamas del mismo
  tamaño. La revisión de la escena entera, con lentes distintas (arte,
  jugabilidad, técnica) y por alguien que no ha hecho nada, no es opcional.
- **UN ARREGLO SE COMPRUEBA DESDE FUERA, OTRA VEZ.** Los mismos tres críticos
  volvieron a mirar tras los arreglos, con el antes y el después delante: de 58
  hallazgos, 36 arreglados y 9 a medias, y la nota de 5,5 a 7. Y encontraron lo
  que los arreglos habían roto (las grietas del suelo brillando como hielo bajo
  la luna nueva, la campana armada quemada a dorado, un reflejo que hacía de
  bola falsa). Arreglar nueve cosas a la vez sin una segunda mirada es volver al
  punto anterior.
- **UN PERSONAJE RÍGIDO NO SE ESCALA PARA QUE QUEPA.** Para que la calavera no
  atravesara los raíles se la «agachó» con una escala no uniforme (0,42 de alto):
  salió una torta con las cuencas ovaladas, en siete capturas, y era una de las
  cosas que estaban en la lista de NO TOCAR. El hueso se hunde en el suelo o
  cambia de pose; aplastarse es de la llama y de la gelatina. Y una lista de «lo
  que no se toca» hay que comprobarla al acabar, no solo leerla al empezar.
- **EL DIBUJO NO SE SEPARA DE DONDE CHOCA.** Apartar el cuerpo del espectro de
  otra criatura lo dejaba a un aro de distancia de su cerco en el suelo, que es
  donde da la bola: el jugador apuntaba al fantasma y fallaba.
- **LA JERARQUÍA DE LUZ SE MIDE, NO SE OPINA.** Luminancia media (0–255) por
  zonas de la mesa, con la misma caja antes y después: palas, campo, braseros,
  ábside. «La zona de palas es la más oscura» eran 20 contra 57, y dejó de
  serlo cuando dio 58. Sin el número, cada agente decía que «ahora se ve mejor».
- **UN CORTE EXACTO SE COME UNA LUZ.** El reparto del fuego clasificaba «campo»
  con |x−2| ≤ 1,85 y el farol de la esquina colgaba a 1,84: ardía a energía
  entera cuando todos creían que iba a la mitad.
- **UN REFLEJO PUEDE MENTIR.** Una llama a 1,1 de alto, con la cámara rasante,
  se refleja en mitad del campo con el tamaño de la bola y más brillo que ella.
  El reflejo de lo emisivo lleva techo en el sombreador del suelo, y las llamas
  van fuera de la capa del reflejo.
- **Un GLB de IA se SUELDA antes de reducirlo.** Diezmado a pelo sale hecho
  confeti (una nube de triángulos sueltos): soldar en su escala, remallar por
  vóxeles y entonces diezmar.
- **`pow()` con base negativa da NaN en GLSL** y el plano no pinta nada, sin
  error: el cuadrado, a mano.
- **Con «vertice», el canto lo dice el canal G de la malla, no la curvatura.**
  Un tubo fino gira más que un bisel: los raíles eran «canto» de punta a punta
  y el desgaste les pintaba lunares de leopardo.
- **El marco de una espira no se saca cruzando la tangente con un eje fijo:** se
  colapsa dos veces por vuelta y el muelle sale en cintas planas. Se saca del
  radio de la hélice.
- **De menos de un milímetro, a la normal del sombreador.** Un detalle tan fino
  (las suturas del cráneo) no sobrevive a la reducción de la malla.
- **En el visor la bola queda DETRÁS de la criatura** al correr y al huir: un
  cuerpo que «mira a la bola» esconde la cara justo en esas tomas.
- **Letra:** Bahnschrift condensada por su eje de anchura, con ajuste a rejilla,
  rompe glifos a cuerpo pequeño (la D sin barriga): `hinting` a NONE. Y
  `get_string_size` no cuenta el espacio del final: se suma aparte.
- **Un guion de Python con `\n` o `\t` dentro de un heredoc de Bash pierde las
  barras** y escribe la barra y la letra tal cual en el fichero. Para tocar un
  `.gd`, la herramienta de edición, no un `python - <<EOF`.

## Convenciones

- 1 px de mesa = 0,01 unidades (`E`). `x = mesa.x·E`, `z = mesa.y·E`, `y` arriba.
  La bola mide 0,09 de radio.
- **Color de vértice:** `R` oclusión, `G` canto/desgaste, `B` libre. Se hornea
  en Blender antes de exportar.
- Los materiales salen de una biblioteca común; el arte y el colisionador
  miden lo mismo; sin `class_name` (se usa `preload`).

## Hugging Face (imagen → 3D)

- Conector de claude.ai activado por Daniel (cuenta gratis: **5 min de GPU al
  día**, no acumulables). Con 6 GB de VRAM, IA 3D en local no.
- El Space con MCP que sirve: `trellis-community/TRELLIS` (MIT):
  `TRELLIS_generate_and_extract_glb(image=<URL pública>, mesh_simplify=0.95,
  texture_size=1024)`. La imagen de entrada tiene que ser una URL pública.
- **El conector NO ejecuta Spaces** (17-nov-2026): `dynamic_space` con
  `operation: invoke` contesta «disabled because gradio=none is set». Sirve para
  buscar y leer, no para generar.
- Lo que sí funciona es llamar al Space con `gradio_client` desde un entorno de
  Python aparte (fuera del repo), subiendo la imagen desde disco: no hace falta
  URL pública. La cadena probada: `black-forest-labs/FLUX.1-schnell` (`/infer`)
  da la imagen de concepto y **`microsoft/TRELLIS.2`** (el Space oficial) la
  malla, en tres llamadas: `/preprocess_image`, `/image_to_3d`
  (`resolution="512"`: 17 s) y `/extract_glb` (15 s). La calavera salió con
  anatomía de verdad, mucho mejor que esculpida por guion.
- **Sin cuenta no cabe** («exceeded your ZeroGPU quota, 120s requested»): hace
  falta el token de Daniel en su variable de usuario `HF_TOKEN`. Lo pone ÉL
  (`setx HF_TOKEN "..."` en la consola, o la ventana de variables de entorno);
  no se escribe en ningún fichero ni se pega en el chat. El guion lo lee del
  registro (`HKCU\Environment`), así no hace falta reiniciar nada, y no lo
  imprime nunca, tampoco dentro de un error.
- **La cuota gratis da para DOS mallas al día**: a la tercera pieza, «exceeded
  your ZeroGPU runs limit». Hay que elegir qué se pide: lo que tiene anatomía o
  talla (calavera, mano, gárgola), no lo que sale bien por guion (engranajes,
  campanas, barriles).
- Las mallas generadas se limpian con `cripta3d/blender/limpiar_fuente.py` y se
  guardan en `cripta3d/blender/fuentes/` (con `.gdignore`), con su procedencia
  y sus encargos apuntados en el `LEEME.md` de esa carpeta. **Un guion de
  Blender del repo no importa nada de fuera del repo**, o deja de ser
  reproducible.
- Hunyuan3D no: su licencia excluye la UE.
- De un GLB generado se aprovecha la FORMA; el material se le pone aquí, con la
  biblioteca, para que no desentone.

## La referencia de calidad

Saltline (three.js, todo por código): el aspecto sale de materiales con
detalle procedural, luz baja y cálida a través de neblina, suelo mojado que
refleja, y etalonaje. ÓRBITA se quedaba corta justo ahí: superficies planas que
emiten luz y bichos hechos de esferas.
