# CRIPTA — la segunda prueba 3D de Cascabel

La primera prueba fue «ÓRBITA» (`prueba3d/`): una mesa espacial de neón, hecha
entera por código. Daniel pidió otra con gráficos «que le peguen a un juego
como Cascabel», con tres criaturas DEL JUEGO —la llama, la calavera y el
espectro— y con este listón: **Saltline**, un juego de three.js cuyo aspecto
sale de materiales con detalle, luz y atmósfera, no de modelos comprados.

Esto NO es Cascabel ni toca Cascabel: vive entero en `cripta3d/`. No se edita
nada de `sim/`, `render/`, `tests/`, `assets/`, `data/` ni `prueba3d/`.

## Lanzarla y mirarla

    # jugar (con ventana): A/D palas, ESPACIO lanzar, C cámara, T piloto, H ayuda
    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --path C:\dev\tilt-os-3d res://cripta3d/cripta_3d.tscn

    # capturar SIN ventana (escritorio oculto, de uno en uno, a paso fijo)
    python cripta3d/herramientas/godot3d.py escena res://cripta3d/cripta_3d.tscn --fotogramas 700 -- --capturas=C:/ruta --vista=0 --demo
    python cripta3d/herramientas/godot3d.py importar          # después de crear un .glb, un .png o una clase
    python cripta3d/herramientas/hoja.py C:/ruta/_hoja.png C:/ruta --cols 3 --alto 400   # todas las capturas en una imagen

    # LA GIRA: las vistas de siempre, para comparar antes y después (juego, piezas, sala, criaturas)
    python cripta3d/herramientas/gira.py C:/ruta piezas sala

    # varias cámaras en UNA lanzada (una por captura) y sucesos forzados a su hora
    python cripta3d/herramientas/godot3d.py escena res://cripta3d/cripta_3d.tscn --fotogramas 500 -- --capturas=C:/ruta --sin-marcador --cada=1.6 --toma=1.6,0.9,10.4/1.6,1.5,7.42/45 --toma=4.2,1.5,7.9/3.22,0.34,6.56/40 --guion=2.6:0:armar,3.0:0:tocar,3.3:0:platillo

    # una criatura sola, estado por estado
    python cripta3d/herramientas/godot3d.py escena res://cripta3d/visor.tscn --fotogramas 1000 -- --guion=res://cripta3d/criaturas/brasa.gd --especie=saltarin --capturas=C:/ruta
    # un modelo solo, girando
    python cripta3d/herramientas/godot3d.py escena res://cripta3d/visor.tscn --fotogramas 400 -- --glb=res://cripta3d/modelos/campana.glb --capturas=C:/ruta

    # Blender sin interfaz
    python cripta3d/herramientas/blender3d.py cripta3d/blender/campana.py -- cripta3d/modelos/campana.glb

`--toma=ojo/mira[/fov]` va en unidades 3D (x = px/100, z = py/100, y arriba) y
se repite: la captura N sale desde la toma N. `--guion=segundo:quién:qué,…`
fuerza un suceso a su hora para poder fotografiarlo —la campana armada o
tocando, las lápidas cayendo, la bola en el sarcófago, una boca tapada, el
espectro escondido—, y también el marcador (`ayuda`, `camara`, `aviso`,
`cartel`, `llena`); la lista entera está en `_forzar`, en `cripta_3d.gd`. La
primera captura es a los 2,0 s y las demás cada `--cada`. `godot3d.py --res
1280x720` da otra ventana (para mirar el marcador en otras proporciones) y
`--fps 0 … -- --medir` mide a tiempo real: fotogramas por segundo, llamadas de
dibujo y triángulos, un renglón por segundo.

**Lo visual se mira, no se deduce.** Nadie da por bueno nada sin haber abierto
la captura. Y las capturas NO se dejan dentro del repo: van a la carpeta
temporal que se le diga a cada uno.

## La mesa

`mesa_cripta.gd` hereda de `prueba3d/mesa_orbita.gd`: mismo esqueleto medido
(palas, carriles, la caza), otro tema, y piezas añadidas encima. **Los
identificadores no cambian; cambian los rótulos** (`MesaCripta.ROTULOS`).

| Identificador | Rótulo | Qué es en la cripta |
|---|---|---|
| `lanzadera` | CAMPANARIO | el raíl que sube la bola por la derecha, rodea la bóveda y la suelta arriba |
| bumpers (3) | BRASEROS | tres engranajes de hierro con el ascua dentro |
| targets (3) | LÁPIDAS | tres lápidas abatibles que tapan los braseros por debajo |
| girador | TORNO | el molinete de hierro de la boca de la galería |
| `orbita` | GALERÍA | el carril largo de la izquierda, a ras de suelo, que rodea el ábside |
| `cometa` | TOBOGÁN | sube, da la vuelta y baja por FUERA de la banda izquierda |
| `estacion` | CORO | la rampa que sube a la tribuna alta (capa alta), con su pala corta |
| platillo | SARCÓFAGO | al fondo del coro: se traga la bola y la escupe |
| `bajada` | ESCALERA | el raíl que baja del coro al carril derecho |
| `gusano` | CATACUMBA | el túnel: entra por la derecha y sale sobre la pala izquierda |

Medidas: 400 px de ancho; el campo va de y=570 (lo alto del ábside) a y=1300.
**1 px de mesa = 0,01 unidades 3D** (`E`). En 3D: `x = mesa.x·E`,
`z = mesa.y·E`, `y` es la altura. El jugador está en +z y mira hacia −z. La
bola mide 0,09 de radio. El coro está en la capa alta (`H_ALTA`); el túnel va
por debajo (`H_TUNEL`).

## LA DIRECCIÓN DE ARTE

**La idea:** la mesa es un sitio. Una cripta de piedra con una máquina de
hierro dentro, construida por un herrero de mazmorra: losas húmedas, hierro
forjado y remachado, engranajes con óxido, bronce viejo, hueso, madera de
roble. Iluminada por fuego —braseros, antorchas, velas— y por un rayo de luna
fría que entra por un óculo. Se fotografía como una maqueta de cine: cerca,
con profundidad, con niebla.

**De dónde sale la identidad:** de los sprites del propio juego. Están
ampliados en la carpeta de referencias que se le pasa a cada agente, y hay que
mirarlos antes de modelar: el búmper es un ENGRANAJE oxidado con un núcleo de
ascua; el target es una LÁPIDA con calavera (y un escudo de madera con
herrajes); el poste lleva un aro de GOMA ROJA; la pala es de hierro negro con
el eje de acero; el desagüe es un aro de hierro remachado; las flechas son
placas de hierro con bombillas ámbar; el atrezzo son antorchas de pared,
braseros, cadenas con gancho, barriles, montones de huesos; y la bola es un
CASCABEL: una esfera de metal con una ranura.

**El listón** (capturas de Saltline en las referencias): materiales físicos
con desgaste, una luz cálida y baja atravesando neblina, suelo mojado que
refleja la luz, siluetas fuertes y capas de profundidad, y un etalonaje de
cine. Lo que separa esto de ÓRBITA no son más polígonos: es que cada
superficie tiene historia y cada luz tiene un motivo.

### Los materiales

Todos salen de `materiales/biblioteca.gd`. **Nadie crea un `StandardMaterial3D`
suelto para una superficie de la mesa**: se pide a la biblioteca, y si falta
uno se añade allí. Es lo único que impide que seis agentes hagan seis mesas.

| Material | Tinte base (paleta del juego) | Cómo es |
|---|---|---|
| piedra | `PIEDRA_1..3` (3A3832, 55524A, 7A7669) | sillar gastado, cantos romos, juntas oscuras, manchas de humedad |
| losa (suelo) | `PIEDRA_1/2` + `GRIS_1` | losas grandes, pulidas por el uso en el centro, MOJADAS: refleja |
| hierro forjado | `GRIS_1/2` (2A2A33, 43434F) | negro mate, martillado, con el filo pulido a `GRIS_4` |
| óxido | `COBRE_1/2` (6B3A22, A0603A) | en las hendiduras y hacia abajo, nunca uniforme |
| bronce | `ORO_OSCURO` / `COBRE_3` (8A6524, C98A4B) | campana y herrajes: pátina oscura en los huecos |
| latón | `ORO` (E0A63C) | raíles e incrustaciones: lo único que brilla limpio |
| madera | `TIERRA_2/3` (4A3A42, 755F52) | roble viejo con veta, herrajes de hierro |
| hueso | `TIERRA_5/6` (D9BF95, F5E9CE) | mate, con las grietas en `TIERRA_3` |
| goma | `ROJO` (8C2E2E) | los postes y las gomas |
| ascua (emisivo) | `ORO_CLARO` → `NARANJA` → `ROJO_LUZ` | núcleo casi blanco, borde rojo; SIEMPRE con una luz al lado |
| arcano (emisivo) | `ARCANO_1` / `ARCANO` (6B3F9E, A97BD9) | **solo el espectro y su catacumba.** Con cuentagotas |

Cada material lleva: variación de color a gran escala, relieve fino,
rugosidad que cambia, suciedad en los huecos y desgaste en los cantos. Van en
triplanar (coordenadas de mundo) para que no haya costuras ni UV estirados.

**Convención de color de vértice** (para los GLB y para las mallas por código):
`R` = oclusión (1 = al aire, 0 = hueco), `G` = canto/desgaste (1 = filo
expuesto), `B` = libre para el material (ascua, musgo…). Un modelo sin color
de vértice se ve plano: en Blender se hornea antes de exportar.

### La geometría

- **Ningún canto vivo.** Todo borde duro lleva bisel: es lo que hace que una
  pieza coja un brillo y deje de parecer una primitiva. Una caja sin bisel es
  un fallo de la prueba.
- **Lo que choca mide lo que mide el colisionador.** Paredes, palas, búmperes,
  targets y postes salen de los datos de `mesa`; el adorno va alrededor.
  **UNA EXCEPCIÓN, consciente: las palas.** El colisionador es una cápsula de
  radio 8 px y el sprite es una lágrima; ajustadas a ±1,5 px los críticos las
  leyeron dos veces como barras. Su goma visible va de radio 10 px en el eje a
  5 px en la punta (hasta +2 y −3 px respecto a lo que choca): la bola rebota
  hasta 3 px antes de tocar la punta que se ve. Los números y el porqué están en
  la cabecera de `mundo/piezas.gd`. Si se quiere exacto, o se vuelve a la
  cápsula o se cambia el colisionador en `sim/`, que es del juego.
- Remaches, bandas, cadenas y tornillos son geometría, no pintura.
- Lo que no se ve desde las cámaras de juego no se modela.

### La luz

- **El fuego es la luz principal:** cálida, baja, parpadeando. Sale de cosas
  que existen (braseros, antorchas, velas, ascuas): no hay luz sin motivo.
- **La luna es el contraste:** una direccional fría, alta y con sombra, que
  entra por el óculo del ábside y dibuja un rayo en la niebla.
- Ambiente casi a cero y azulado. Las sombras son oscuras de verdad.
- **Pero se juega:** la bola y las palas se tienen que ver SIEMPRE. La bola
  lleva su brillo; la zona de palas, su luz.
- **El motor es Compatibility** (OpenGL/WebGL2), que es lo que puede ir a la
  web. Ahí NO hay SSAO, SSR, SDFGI, niebla volumétrica, profundidad de campo
  ni decals: la oclusión va horneada (color de vértice y un mapa en el suelo),
  los rayos de luz son mallas, y el reflejo del suelo es una segunda cámara.
  Forward+ (`--metodo forward`) se prueba al final y solo suma.
- **Compatibility aplica como mucho 8 luces por malla.** Una malla enorme (el
  suelo entero, todas las paredes juntas) se queda sin las que le sobran y
  salen manchas negras. Lo grande se parte en trozos de ~1,5 unidades.

### La atmósfera y el acabado

Niebla de profundidad cálida, polvo y pavesas flotando, rayo de luna. Curva de
tono de cine (ACES o AgX), brillo SOLO en el fuego, las ascuas y los ojos,
viñeta, grano fino, una pizca de aberración en los bordes.

### Lo que NO

Neón. Superficies que solo emiten. Colores planos sin luz. Esferas y cápsulas
a la vista haciendo de cuerpo. Rótulos flotando sobre la mesa (si hay texto, va
grabado en una placa). Violeta fuera del espectro. Negro aplastado donde hay
que jugar.

## LAS CRIATURAS

Las mueve la caza de ÓRBITA (`prueba3d/caza_orbita.gd`) sin tocarla; aquí solo
cambia el cuerpo. Cada especie de la caza es una criatura de Cascabel:

| Especie (caza) | Criatura | Cómo se captura | Guion del cuerpo |
|---|---|---|---|
| `saltarin` (GOTA) | **BRASA**, la llama | el primer golpe la parte en dos ASCUAS (`gotita`) que botan; se recogen tocándolas antes de que se junten | `criaturas/brasa.gd` |
| `escarabajo` (TANQUE) | **CALAVERA** | por delante la bola rebota en la frente; hay que darle por un lado o por detrás para VOLCARLA | `criaturas/calavera.gd` |
| `corredor` (LUMI) | **ESPECTRO** | no tiene vida, tiene MIEDO: a golpes se acorrala; se esconde en la catacumba | `criaturas/espectro.gd` |

**Contrato del cuerpo** (el mismo de `prueba3d/criatura_3d.gd`, que es la
referencia de cómo se lee cada estado): un `Node3D` con `montar(criatura,
fuente)`, `actualizar(delta, bola: Vector3)`, `golpear(normal: Vector2)`,
`blindar()`, `avisar_aro()`, `color() -> Color`, `centro() -> Vector3` y las
variables `y_base`, `t_cierre`, `t_volcada`, `arco_blindaje`. Solo LEE la
`Criatura`; no decide nada. Se coloca en `(c.pos.x·E, y_base, c.pos.y·E)`.

Se juzgan dos veces: **de cerca** (retratos del visor) tienen que ser el
personaje del sprite, con volumen; **de lejos** (`como_en_juego`) se tienen
que leer en 40 píxeles: silueta, color y ojos. La cámara mira desde arriba.

## EL CÓDIGO

| Fichero | Qué |
|---|---|
| `cripta_3d.tscn/.gd` | la escena: física, reglas, cámaras, piloto, capturas, calidad |
| `marcador.gd` | el marcador entero (un `Control`): la escena le dice QUÉ pasa y él decide cómo se enseña |
| `mesa_cripta.gd` | la mesa (hereda de `mesa_orbita.gd`) |
| `mundo_cripta.gd` | el NÚCLEO del mundo: alturas, utilidades, carga los módulos, la caza |
| `mundo/entorno.gd` | cielo, ambiente, luna, niebla, rayos, polvo, posprocesado |
| `mundo/suelo.gd` | las losas, el reflejo, la oclusión horneada, las incrustaciones |
| `mundo/arquitectura.gd` | paredes, ábside, mueble, coro, carril lanzador; la sala: bóveda, pilares, osarios |
| `mundo/atrezzo.gd` | la campana mayor, antorchas, braseros, velas, faroles, cadenas, gárgolas, huesos |
| `mundo/piezas.gd` | búmperes, gomas, postes, lápidas, palas, torno, sarcófago, lanzador |
| `mundo/railes.gd` | los recorridos: raíles, bocas de túnel, flechas de boca |
| `mundo/bola.gd` | el cascabel (la bola), su estela y su luz |
| `mundo/efectos.gd` | chispas, pavesas, polvo de golpe, ondas, almas |
| `materiales/biblioteca.gd` + shaders | TODOS los materiales |
| `criaturas/*.gd` | los cuerpos |
| `blender/*.py` → `modelos/*.glb` | lo que se modela se genera por guion: el guion va al repo |
| `texturas/` | texturas generadas (ruido, etc.) |
| `herramientas/` | `godot3d.py` (lanzar sin ventana), `blender3d.py`, `hoja.py`, `gira.py` |
| `visor.tscn` | una criatura o un `.glb` solos, estado por estado |
| `criaturas/*_banco.tscn`, `mundo/bola_prueba.tscn`, `materiales/muestrario.tscn` | bancos de prueba de quien hizo cada cosa: no los carga el juego. Su cabecera dice cómo se lanzan |
| `sonda_cripta.gd`, `sonda_caza_cripta.gd`, `materiales/sonda_biblioteca.gd` | medidas (bola media, campana, caza determinista, la biblioteca): no fallan, informan |

**Para mirar un material o un defecto sin adivinar:** `-- --depura-materiales=N`
pinta una máscara de la biblioteca en todos los opacos a la vez (1 canto,
5 normales…: la lista está en `biblioteca.gd`), `-- --suelo-depura=N` hace lo
mismo en el suelo (2 agua, 7 charco y hollín, 8 solo el reflejo) y
`-- --medir-arquitectura` cuenta mallas, triángulos y fuegos por malla.

**Contrato de un módulo** (`mundo/<nombre>.gd`): `extends RefCounted`, con
`func montar(mundo: Node3D) -> void` y `func actualizar(delta: float) -> void`.
Cuelga sus nodos del mundo, se conecta él mismo a las señales de `mundo.mesa`
que anima, y pide materiales a `mundo.mat`. **Un módulo no edita otro módulo
ni el núcleo**: si necesita algo del núcleo, lo dice en su informe.

**Lo que da el núcleo** (`mundo_cripta.gd`; la lista entera está en su
cabecera): `mesa`, `caza`, `mat`, `E`, `H_PARED`, `H_ALTA`, `H_TUNEL`,
`a3(v, h)`, `altura_capa(capa)`, `altura_rampa(r, d)`, `altura_bola(b)`,
`posicion_bola(b)`, `chispear(punto, altura, color, cuantas)`,
`luz_fuego(pos, energia, alcance)` (la da de alta para que parpadee) y
`sacudida`. Y lo que comparten varios módulos, que por eso se mide ahí y no en
cada uno: `Y_SALA` (el suelo de la nave, −0,9), `Y_BOVEDA` (por donde cierra la
bóveda, 7,0), `fuegos()` (las fichas de todos los fuegos, para quien reparte
la luz) y **la calidad**: la escena llama a `poner_calidad(n)` y el núcleo
llama a `calidad(n)` de cada módulo y de cada cuerpo que la tenga (0 ALTA,
1 MEDIA, 2 BAJA). Quien ponga algo que pese lo apaga ahí.

## Reglas duras

- **Ni un `.quit` ni la palabra entre comillas** en un `.gd` de aquí: la
  batería del juego (`tests/prueba_sim.gd`) lo busca en todo el proyecto y se
  pone en rojo. Se cierra con `--fotogramas`.
- **Sin `class_name`** (no se ensucia el espacio global del juego): se usa
  `const X := preload("res://cripta3d/…")`.
- GDScript tipado. Un lambda captura las locales POR VALOR (los contadores van
  en un `Array`). Un ternario deja un `Array` sin tipar.
- Después de crear o cambiar un `.glb`, un `.png` o un guion con clase nueva:
  `godot3d.py importar`. Si no, `Could not find type` o el modelo viejo.
- Godot se lanza SIEMPRE con `godot3d.py` (escritorio oculto y candado). Nunca
  el ejecutable a pelo: le planta una ventana a Daniel y pisa a otro agente.
- Nada se descomprime ni se deja tirado dentro del repo: Godot lo escanea
  entero. Las capturas y los ficheros de paso van a la carpeta temporal.
- No se hace commit: lo decide Daniel.
