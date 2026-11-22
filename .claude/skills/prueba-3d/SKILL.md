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

- Compatibility **NO tiene** SSIL, SSR, SDFGI, VoxelGI, niebla volumétrica,
  profundidad de campo, decals ni buffer de normales, y dibuja en 8 bits por
  canal (sin HDR: el tramado contra las bandas se lo pone uno).
- **SÍ TIENE OCLUSIÓN DE PANTALLA (SSAO) desde Godot 4.6**, y esta skill decía
  que no. Es una versión sencilla, sin pasada de desenfoque. Comprobado el
  21-nov-2026 en 4.7.1 con OpenGL: con `Environment.ssao_enabled` (radio 0,45,
  intensidad 1,6, potencia 1,3) sale la sombra de contacto en la base de los
  braseros y entre los dientes de los engranajes, y la luminancia media de la
  toma baja un 2 %. En CRIPTA es un interruptor de prueba (`-- --ssao`,
  `?ssao=1`), no va puesta: cambia el aspecto aprobado. Sin medir en web.
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

## El navegador compila por Direct3D: se mide con ANGLE

En un navegador de Windows, WebGL pasa por ANGLE: el GLSL se traduce a HLSL y lo
compila Direct3D (FXC), cien veces más lento que el OpenGL de escritorio. Con el
OpenGL de siempre NO SE VE: todo compila en milésimas y la caché lo tapa. Medido
el 21-nov-2026 (GTX 1060, i5-6600K): la primera lanzada de CRIPTA con ANGLE,
**212 s**; la segunda, con la caché caliente, 15. Eran 197 s de compilar: una
página congelada más de tres minutos en la primera visita.

- **El Godot de escritorio trae ANGLE dentro**: `--rendering-driver
  opengl3_angle` es el mismo traductor que usa Chrome. Lo que tarda ahí es lo
  que tardará el navegador, y se mide sin exportar nada.
- **EN FRÍO sin tocar la caché de verdad**: `APPDATA=<carpeta vacía> python
  cripta3d/herramientas/godot3d.py …`. Godot guarda la caché de sombreadores en
  `%APPDATA%\Godot\app_userdata\Cascabel\shader_cache`, al lado del guardado del
  juego (no se borra a mano); con otra `APPDATA`, usa otra. Esa caché, además,
  crece sin fin: en cuatro días de trabajo, 628 MB.
- **EL BANCO** (`cripta3d/banco_sombreadores.tscn`, su cabecera lo cuenta todo):
  lo que tarda en compilar cada sombreador, uno a uno, siempre en frío.
  `--solo=texto` filtra, `--fichero=ruta` mide uno suelto de fuera del repo,
  `--patrones` mide el sombreador vacío con cada modo.
- **LO QUE CUESTA LA PARTE DE GODOT** (un sombreador vacío): con luz **5,6 s**;
  `specular_disabled` 2,9; `vertex_lighting` **0,86**; `unshaded` **0,33**;
  escribir `CLEARCOAT`, 9,2. `diffuse_lambert`, `shadows_disabled` o
  `fog_disabled` por sí solos no ahorran nada.
- **POR QUÉ** (`drivers/gles3/shader_gles3.cpp`, `_initialize_version`): la
  primera vez que se usa un sombreador Godot compila CUATRO variantes «por
  defecto» (color, color con instancias y las dos de profundidad) con TODOS los
  tipos de luz dentro, también las luces de ÁREA nuevas de la 4.7, que son las
  caras. En una escena sin lightmaps no las usa nunca. Luego compila la de
  verdad, que es barata (la de la piedra, 0,8 s). La luz por vértice no lleva
  luces de área: por eso baja a 0,86.
- **EL CÓDIGO PROPIO SE PAGA TRES A CINCO VECES**, una por variante. Un ruido
  de valor con ocho `hash`, un `fbm`, unas celdas con triple bucle: Direct3D lo
  despliega todo. La calavera, hecha entera de ruido por código, eran 34,5 s.
  El ruido se LEE de las texturas de la casa.
- **UNA SOLA VARIANTE DE VERDAD POR SOMBREADOR.** Godot compila un programa por
  cada combinación de luces que le toca a una malla (`DISABLE_LIGHT_OMNI`,
  `DISABLE_LIGHT_SPOT`) y otro si el entorno de su cámara aplica la curva de
  tono dentro del sombreador (`APPLY_TONEMAPPING`: pasa cuando no lleva ni
  brillo ni ajustes, como el del reflejo). En web el núcleo pone dos luces de
  relleno que alcanzan todo y no alumbran, y le enciende al entorno del reflejo
  unos ajustes neutros (`MundoCripta._unificar_variantes`). Medido en Chrome
  contra la página publicada (`?relleno=0` las quita): sin ellas, al abrirse el
  telón la página se queda 4,4 s congelada y encadena unos 11 s de tirones; con
  ellas, ninguno, y cuestan 1,7 fotogramas por segundo de 49.
- **UNA LUZ CON SOMBRA ES OTRA PASADA POR MATERIAL** (la aditiva): en web,
  ninguna, en ninguna calidad. ÓRBITA lo paga: 10,7 s de parón cuando el
  vigilante sube a ALTA.
- **Y UNA LUZ CON SOMBRA ALUMBRA MÁS QUE LA MISMA SIN ELLA.** Esa pasada aparte
  se SUMA sobre la imagen ya en sRGB, y la pasada de siempre suma en lineal. Al
  quitarle la sombra al fuego del campo (MEDIA, BAJA y la web) los braseros
  bajaban de 75 a 61 de luminancia y el charco cálido del suelo casi se
  apagaba. Pasaba en MEDIA de escritorio desde el primer día y nadie lo midió:
  lo vio un crítico comparando la web con el escritorio. Ese fuego lleva ahora
  el doble de energía cuando no tiene sombra (`entorno.gd`, `SIN_SOMBRA_POR`,
  con su tabla). «Las tres calidades se ven igual» se comprueba con las mismas
  tomas en las tres, no se da por hecho.
- **Y LO QUE SE TAPABA A SÍ MISMO, SIN SOMBRA SE ENCIENDE.** La campana cuelga
  encima del fuego del campo y en ALTA su propia boca le hace sombra: es un
  bronce viejo y oscuro. Sin sombra ese fuego (y doble) la alumbraba entera
  desde abajo: un 28 % más clara y con una raya naranja en el labio de cada
  moldura. Va en su capa de dibujo (`Nucleo.CAPA_A_SU_SOMBRA`, que el reflejo
  también mira) y a ese fuego, cuando no lleva sombra, se le quita esa capa
  (`light_cull_mask`). La caja de la campana: ALTA 27,3; web antes 39,1; ahora
  32,0. **Y lo de dentro, que ese fuego sí alumbra, va en un forro:** la pared
  interior repetida 6 mm hacia dentro, con el mismo bronce, en una capa que esa
  luz sí alcanza (`atrezzo.gd`, `_montar_luz_boca`). Una luz no distingue dentro
  de fuera sin sombra; una malla sí. Sin él la boca se quedaba negra (su caja,
  de 64,9 en ALTA a 32,2; con el forro, 53,5), y lo vio un crítico en las vistas
  de la sala cuando yo había escrito que «solo se ve desde debajo». *Probado y
  quitado:* un disco de luz pintada dentro de la boca (desde la sala se mira
  casi de canto y queda detrás del labio) y devolver la viga a ese fuego (42,5
  contra 12,6 en ALTA: se queda fuera, algo oscura).
- **LA CARGA POR PARTES** (`cripta_3d.gd`, `_preparar_carga`): la mesa se monta
  tapada y delante de la cámara se pone, uno por fotograma, un cuadradito con
  cada material del mundo —también los de lo que está escondido esperando su
  momento, que es lo que luego daría un tirón jugando—. Un telón dice por cuál
  va. Vale porque en web cada sombreador tiene una sola variante. Con
  `--medir` escribe lo que tarda cada material, y «destape» dice lo que tarda
  el primer fotograma a la vista: si no son centésimas, algo se ha quedado sin
  compilar.
- **UN TIRÓN JUGANDO SE BUSCA CON `--medir --tirones`**, en frío y por ANGLE:
  cada fotograma de más de 60 ms sale apuntado con su segundo, con los
  materiales que hay en el mundo y la carga no compiló, y con las piezas que se
  vieron por primera vez en él. Tres minutos de piloto y de guion de caza:
  ningún material sin cargar. *Ojo al leerlo:* el reloj de la medida se pone a
  cero al destapar; sin eso, el último paso de la carga salía como un tirón de
  medio segundo «a los 0,0 s». Y con otro juego abierto en el equipo salen
  fotogramas sueltos de 60 a 200 ms que no se repiten: se mide dos veces.
- **AL PASAR ALGO A LUZ POR VÉRTICE** (`vertex_lighting`): la normal retocada
  en `fragment` deja de influir en la luz directa (lo que se «tallaba» en la
  normal se lleva al color); Godot NO voltea la normal en las caras de atrás
  con `cull_disabled`, y `diffuse_lambert_wrap` recorta N·L a cero antes de
  sumar, así que lo que se veía de espaldas sale más claro (la onda de un golpe
  salía al doble); y un `ALBEDO` que se escala, se escala EN LINEAL (Godot lo
  pasa de sRGB a lineal: multiplicar el sRGB por 2,2 lo multiplica por 6). Una
  malla con luz por vértice tiene que estar partida: la bruma, que era un plano
  de cuatro vértices, va ahora en rejilla de medio metro.
- **LO QUE TIENE QUE SEGUIR CON LA LUZ POR PÍXEL** (la piedra y el suelo) lleva
  `specular_disabled` y la `light()` de `cripta3d/materiales/luz_godot.gdshaderinc`,
  que es la del motor copiada a mano. Así las variantes por defecto se quedan
  sin el especular de las luces de área y el programa baja un 35 % (la piedra,
  de 8,8 a 5,7 s) viéndose IGUAL: catorce tomas fijas, diferencia media de 0,00
  a 0,28 sobre 255, lo mismo que entre dos lanzadas del mismo código.
- **EN COMPATIBILITY EL DIFUSO POR DEFECTO ES LAMBERT, NO BURLEY.** La
  documentación dice Burley, pero en `scene.glsl` un sombreador sin
  `diffuse_burley` cae en el `#else`, que es Lambert. La primera versión de esa
  `light()` copió Burley y toda la piedra salió un 2,8 % más clara: lo cazó la
  comparación de tomas fijas, no el ojo.
- **PARA COMPARAR UN CAMBIO QUE NO DEBERÍA VERSE:** tomas fijas en los primeros
  cuatro segundos (después la simulación se separa de una lanzada a otra), el
  mismo código DOS veces para saber cuánto ruido hay, y luego el cambio contra
  eso. Con las ocho primeras tomas el ruido es 0,00–0,22 de media.
- **JUNTAR SOMBREADORES AHORRA 0,33 s POR PIEZA.** Dos piezas con el mismo
  `render_mode` pueden ser un sombreador con un `uniform` que elige rama (la
  onda y el polvo, el núcleo y la llama). Y el vértice también se compila:
  mover `VERTEX` con algo de cuenta son de 0,1 a 0,4 s por sombreador.
- **«EL ASPECTO NO CAMBIA» LO DICE UN CRÍTICO DE FUERA, NO QUIEN REESCRIBE.**
  Los seis agentes que abarataron sombreadores informaron de que no se veía
  nada. Tres críticos, con la gira de antes y la de después lado a lado
  (`comparar.py giras`), encontraron nueve cosas, y una había que arreglarla
  (la bóveda de la calavera, sin grietas y con manchas). Lo que enseñaron los
  arreglos:
  - **Una luz pintada a mano se calibra en UN sitio y sirve en varios.** El
    ascua de los braseros de la sala salía encendida como la del campo. La
    costra lleva ahora el peso de luz de su zona, con los mismos cortes que el
    reparto del fuego (`ascua.gdshader`, `sitio_peso`).
  - **Un brillo estrecho no pinta ni un píxel en una pieza pequeña.** Con
    exponente 260 en una bombilla de 30 px, la normal gira 3,8° por píxel y el
    lóbulo mide 2°: cero píxeles. Lóbulo más ancho, y brillo por encima de 1 y
    recortado, como hace el GGX.
  - **«Es un 1 % de la luz» no dice nada si el albedo es 0,01.** El especular
    se compara con el difuso de ESA piel: en la gelatina del espectro pesaba lo
    mismo, y en el filo, cincuenta veces más.
  - **Con `vertex_lighting`, la rugosidad de las luces se escribe en
    `vertex()`.** Si no, vale 1,0 (la de `fragment` no llega) y el brillo
    desaparece. Y no es GGX: es un Blinn de exponente (1,2 − r)⁵·2000. Un GGX
    de 0,55 se parece a ese Blinn con 0,80.
  - **Al copiar a mano la atenuación de un foco, el exponente del cono es
    `1 / spot_angle_attenuation`.** Al derecho daba casi el doble de luz.
  - **Las luces de una criatura con luz propia se eligen por su DIFUSA**, no
    por `light_specular`: una que alumbra mucho y brilla poco se quedaba fuera.
    Y las dos de relleno (energía 0,0001) se descartan.
  - **Una textura de marcas guarda la DISTANCIA a la raya, no la raya.**
    Pintada y leída con mipmap, la grieta salía a puntos sueltos. Con la
    distancia, `textureLod` 0 y `fwidth`, sale continua y nunca de menos de un
    píxel.
  - **Y hubo una tercera ronda, porque los arreglos también rompen.** Devolver
    las grietas a la bóveda de la calavera las metió en la frente blindada, que
    era lisa; y dos cosas se le habían pasado a todos: el charco negro del que
    sale (22,7 → 44,4 de luminancia) y la losa bajo el espectro (144,9 → 121,8).
    Lo que enseñó:
    - **Con `vertex_lighting` el brillo de las luces va SIN FRESNEL** (el Blinn
      del vértice por f0 a secas). Lo que la luz por píxel tapaba con el brillo
      rasante (f90 son 50 veces f0) se queda a la vista: la sombra flotante del
      espectro. Se pinta a mano el GGX de las cuatro luces más fuertes, en
      `EMISSION` (`espectro_sal.gdshader`), y cuesta 0,07 s.
    - **Al cambiar un `render_mode` se repasa ENTERO.** La tiza de la calavera
      perdió su `specular_disabled` al pasar a luz por vértice, y un negro de
      0,004 de albedo recibía tres veces su difusa en brillo.
    - **Un ruido que antes se calculaba en cada píxel se lee con `textureLod`
      0.** Con mipmap, visto sesgado se queda en su media: la tiza salía «más
      pintura que tiza».
    - **Las capturas de un informe, con el sombreador FINAL.** En la segunda
      ronda se entregaron las de una versión intermedia y el crítico encontró
      lo que el informe no contaba.
- **LA GIRA «COMO EN LA WEB»:** `gira.py <carpeta> --con=--como-web
  --con=--calidad=media` saca las mismas tomas de siempre con lo que se
  publica (sin sombras, calidad media, letra de reserva).
- **Desde Git Bash, `--solo=/mundo/…` se convierte en una ruta de Windows** y
  no casa con nada: sin la barra del principio, o con `MSYS_NO_PATHCONV=1`.
- **`-- --como-web`** ensaya en escritorio lo que solo pasa en web: el telón, las
  luces de relleno, ninguna sombra y la letra de reserva en el marcador.
- **Un Chrome sin ventana** (`WEB.md`) mide la página publicada. Si corre a la
  vez que un Godot le falsea la medida: que espere su turno con el mismo candado.
- **El listón**: ÓRBITA, publicada, tarda 55 s en arrancar en frío en este
  equipo, con un parón de 40 s seguidos sin una palabra. CRIPTA quedó en 29,7 s
  de telón con el equipo libre (eran 197 de parón), con el paso más largo de
  4,2 s, y el banco de `cripta3d/` en 27 s (eran 146). En Chrome de verdad,
  contra la página publicada: 32,9 s de telón y se juega a los 43 s de pedirla
  (2,7 de bajar, 5,7 de arrancar el motor y 1,5 de montar la mesa); la segunda
  visita, a los 12.
- **EL EQUIPO NO SIEMPRE ESTÁ LIBRE, Y EL BANCO LLEVA SU REGLA.** El patrón
  «vacío con luz» tarda 4,2 s con el equipo del todo libre, 5,5 con otros
  agentes trabajando y 8,5 con un juego abierto al lado; lo demás de esa lanzada
  va inflado en proporción (los sombreadores grandes con luz, más que los
  pequeños). Un antes y un después se miden EN LA MISMA LANZADA (`--fichero` con
  la copia de antes), y se apunta lo que dio el patrón.

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

## La referencia de calidad: Saltline, diseccionado (21-nov-2026)

Saltline es un FPS de navegador en three.js r180 que hizo un modelo (Claude
Fable 5.2) de una sentada; la página lleva dentro esa versión sin retocar. **No
carga ni un modelo ni una textura: todo es código.** Lo que explica su aspecto,
por orden de peso, y si se puede en Godot web (leído en su código):

1. **UNA luz dominante** (un sol a 13°, a contraluz) y el entorno sacado del
   mismo cielo. *Se puede: es dirección de arte.* En CRIPTA mandan a medias el
   fuego y la luna.
2. **La cadena de imagen:** curva de tono de cine, TONO PARTIDO (sombras
   verdeazuladas, altas cálidas), curva en S, negros levantados, viñeta, grano
   y tramado. *Se puede, en el sombreador de pantalla.* CRIPTA no tiene tono
   partido.
3. **Mojado según hacia dónde mira cada cara** (charco arriba, regueros en
   vertical, salpicadura junto al suelo). *Se puede.* CRIPTA solo moja el suelo.
4. **Texturas generadas UNA vez al arrancar** (27 programas de ruido que dan
   color, rugosidad, metal y relieve), a escala real en metros y con un modelo
   de daño común: desconchones por zonas, la mayor parte del panel limpia. *Se
   puede:* es la regla de «el ruido se lee, no se calcula».
5. **Variación en espacio de mundo:** nada se repite igual a cinco metros.
6. **Modelos con MEDIDAS REALES y bisel por defecto** (la primitiva es una caja
   achaflanada de 12 mm), perfiles barridos, tornos y extrusiones con bisel;
   sin booleanas ni escultura. Lo que se modela es el objeto de verdad con sus
   piezas pequeñas (un contenedor con sus esquineros, sus barras de cierre y su
   matrícula). *Se puede.* Antes de modelar: la ficha técnica de la pieza.
7. **La historia, en los vértices:** polvo que sube del suelo, regueros de
   óxido, cantos gastados por curvatura, oclusión horneada.
8. **Niebla volumétrica que lee el mapa de sombras.** *NO en Compatibility:*
   aquí los rayos son mallas.
9. **Sombras suaves de penumbra variable** y oclusión de pantalla que solo
   oscurece lo que no da el sol. *Las sombras no; la oclusión sí desde 4.6.*
10. **Reflejos y suciedad de lente** (se puede, en pantalla), **exposición
    automática y búfer HDR** (no).

Y **fusiona las mallas por material**: de 233 a 433 llamadas de dibujo con 1,7 a
2,9 millones de triángulos. CRIPTA: 640 llamadas con 630.000.

**El método que deja ver su código es el de la casa:** un agente por módulo con
respaldo si falla, un banco de capturas por URL (cada módulo solo, cámara fija,
determinista), los valores de dirección de arte juntos en un objeto, y
comentarios que dicen la intención.

**three.js NO se libra de Direct3D.** Medido en este equipo con un Chrome sin
ventana: Saltline tarda entre 64 y 70 s en enseñar su primera imagen en frío
(con un parón de 40 s seguidos) y no va fluido hasta los 86 s. ÓRBITA, 55 s.
Cambiar de motor no arregla el arranque; solo daría lo que Godot web no dibuja
(puntos 8 a 10).

**Lo que dice la evidencia de fuera** (informe del 21-nov-2026):

- Los equipos pequeños que se ven de estudio deciden LA LUZ primero y se ponen
  pocas reglas. Con números: luz principal contra relleno de 4:1 a 8:1; albedo
  de lo que no es metal entre 30–50 y 240 en sRGB (el negro nunca es 0: el
  hierro de forja es un dieléctrico oscuro, hacia 40, no un metal a negro);
  metálico 0 o 1; bisel con normales ponderadas en todo canto.
- **Que el modelo juzgue su propio render casi no mejora nada** (3DCodeBench,
  jun-2026); lo que sube la nota es que mire OTRO. Los dos fallos típicos de un
  modelo en Blender: la API de versiones viejas y las piezas flotantes.
- Para un pinball: el VPX Lightmapper hornea en Blender una base y un mapa de
  luz por grupo de bombillas, y en juego los suma. El `LightmapGI` de Godot no
  se puede hornear por script: el horneado va por Blender (Cycles).
- Recursos CC0 con API: Poly Haven y ambientCG (dan 403 al `User-Agent` por
  defecto de Python: hay que poner uno propio). HDRI para una cripta:
  `sepulchral_chapel_basement`. No se encontró ninguna calavera escaneada ni
  ningún sonido de campana con CC0 comprobado.
