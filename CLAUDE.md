# CASCABEL

Pinball roguelike en Godot 4.7, GDScript. La mesa vive dentro de un sistema
operativo falso con estética de Windows XP, que es la **cáscara**: el marco
visual, no el nombre del juego. El juego se llama **Cascabel**.

Las carpetas del repo siguen llamándose `tilt-os` a propósito: el nombre de
la ruta no se toca. Y **TILT sigue siendo la pantalla de derrota**, que es
término de pinball real.

## Lo primero de cada sesión

**Lee `ESTADO.md`.** Dice en qué fase estamos, qué está hecho, qué queda y
qué toca ahora. No empieces nada sin leerlo.

`PLAN.md` tiene las fases con sus criterios de salida.
`DISEÑO.md` tiene el diseño de la capa roguelike: el pilar, los ejes de
build, los ganchos de reliquia. **Ábrelo antes de tocar reliquias, enemigos
o estructura de run.**
`CONTEXTO.md` tiene la referencia densa: paleta, assets, proporciones,
estética. **Ábrelo solo para buscar un dato concreto**, no por costumbre, y
no es fuente de verdad para parámetros ni geometría: esos viven en el
código. Si contradice a este archivo, manda este archivo.

## Lo último de cada sesión

**Actualiza `ESTADO.md`** antes de terminar: qué has cerrado, qué queda
abierto, qué es lo siguiente y qué necesitas que Daniel pruebe. Si no lo
haces, la siguiente sesión empieza a ciegas.

## Godot

No está en el PATH. El ejecutable de consola (el que devuelve la salida) es:

`C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe`

Batería de pruebas, sin abrir ventana:

    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/prueba_sim.gd

Medidas (no son pruebas: no fallan, imprimen tablas):

    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/medir_balance.gd
    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/medir_reliquias.gd

## Herramientas del repo

Se generan, no se dibujan ni se editan a mano:

| Script | Qué hace |
|---|---|
| `python3 fuente.py` | la fuente pixelart y los cinco marcos de nueve trozos |
| `python3 sonidos.py` | los sonidos sintetizados (y luego hay que reimportar) |
| `python3 procesar.py hoja.png ...` | recorta una hoja de IA con fondo magenta |
| `python3 limpiar.py assets/` | repara sprites YA recortados de los que no queda hoja |

`limpiar.py` va en simulacro por defecto: imprime qué tocaría y no escribe
nada hasta que se le pasa `--aplicar`. Arregla tres cosas —sal de
cuantización, interior comido y motas sueltas— y lleva su propia lista de
ficheros intocables.

**Las hojas originales de IA viven en `C:\Users\Daniel\Desktop\Sprites`**,
no en el repo. Solo están las del 9 de agosto (mesa, enemigos, jefes,
reliquias, efectos, fondo): de las tandas posteriores —`criaturas_64`,
`mesa_anim`, `bolas`, `bolas_64`, la cáscara— **no hay original**, así que
esos sprites solo se pueden reparar, no rehacer. Guardar la hoja al generar
una tanda nueva no es opcional.

## Invariantes

Decisiones cerradas. No las reabras sin que Daniel o Fátima lo pidan.

- **Mesas diseñadas a mano, nunca procedurales.** Lo que varía entre
  partidas son reliquias, enemigos y modificadores, no la geometría. **El
  mapa del run sí se genera**, y no lo contradice: lo que no puede generarse
  es la geometría, porque cada ángulo condiciona todos los rebotes.
- **Mantener el flipper sigue siendo mantener el flipper.** Es una técnica
  de juego. No se le asigna ninguna habilidad a ese gesto.
- **Las rampas son curvas, no física simulada.** La bola se desengancha,
  recorre un spline y vuelve con la velocidad tangente.
- **El daño se aplica al golpear, no al drenar.** No hay cuenta de bolas:
  hay vida, y drenar cuesta vida.
- **Los enemigos normales viven fuera del campo de juego.**
- **La bola es el bloque de stats del jugador, solo en efectos.** Nunca en
  tamaño ni masa: descuadra el hueco entre palas.
- **La cáscara va en PIXELART, con marcos de nueve trozos.** Misma rejilla y
  misma paleta que el resto. Se acabó dibujarla por código con degradados y
  biselados en resolución nativa: era más cara y peleaba con el arte.
- **No hay gestor de ventanas.** La cáscara son paneles enmarcados en
  posiciones fijas que PARECEN ventanas. Nada de arrastrar, redimensionar,
  foco, orden de apilado ni minimizar.
- **La recompensa no saca de la mesa.** Se juega en la TELE, que es una pantalla
  empotrada en el tablero encima de los flippers, donde ya vivía el
  multiplicador. La cámara baja, el resto se apaga, la ruleta gira y sigue el
  juego. **La tele no tiene colisionador y no puede tenerlo:** sería cambiar la
  geometría y crear un rincón donde se acuña la bola, justo entre las palas.
- **Nada de menús para elegir mejora.** La ruleta da una y las palas dan derecho
  a UNA repetición. Ni tres tarjetas, ni pantalla aparte, ni pausa larga.
- **Las reliquias se ganan JUGANDO, no por ganar el combate.** Se completan
  misiones de mesa —el display del pinball del XP, la caza de Pokémon Pinball— y
  cada misión paga una reliquia de su rareza. Ganar el combate no da objeto: te
  deja pasar. Cada combate trae una escalera de tres misiones (común, rara,
  arcana), así que quien aguanta la bola sale con tres reliquias y quien no, con
  una: **el margen por habilidad se paga en objetos**.
- **La tele dice siempre qué toca ahora.** Ese es su trabajo principal; el
  multiplicador es lo secundario. Un combate largo sin objetivo escrito es el
  mismo minuto repetido.
- **El HUD no va encima de la mesa.** Vida, enemigo, crítico y daño de bola
  viven en los paneles de la banda derecha, que dibuja la cáscara. La única
  excepción es **el reloj del enemigo, que va dentro de la barra de título de la
  ventana de la mesa**: tiene que verse de reojo sin dejar de mirar la bola, y
  ahí está pegado al campo sin quitarle ni un píxel. Cualquier dato nuevo que
  pida sitio va a un panel, no a una franja sobre el tablero.
- **Los marcos se REPITEN, no se estiran.** Estirar un pixelart lo destruye.
  `render/nueve_trozos.gd` los repite, y por eso los bordes del atlas van sin
  remates ni tornillos en las puntas: un detalle cerca del final de una tira se
  convierte en un patrón que se repite y canta.
- **Escalado por enteros siempre.**

## Las capas de dibujo

De atrás a delante. Saber esto de memoria ahorra la avería de dibujar algo
donde no se ve.

| Capa | Nodo | Qué |
|---|---|---|
| −10 | `NodoCascara` | fondo del escritorio, iconos de las dos bandas, paneles de la derecha |
| −2 | `NodoSuelo` | **rectángulo negro OPACO de 400×1300**, suelo y adornos |
| −1 | (libre) | era el enemigo; ya no |
| 0 | `VistaMesa` | paredes, rampas, bumpers, bola, números, velo |
| 5 | `NodoCascaraFrente` | marco de la ventana de la mesa + su reloj, barra de tareas, tooltip |
| 8 | `NodoPanelEnemigo` | el enemigo y sus partículas, dentro de su panel |
| 10 | `NodoHud` | lo que se escribe dentro de los paneles, y el cartel del centro |
| 20 | `NodoPantallaMapa` | el explorador de carpetas, maximizado |
| 40 | `NodoTilt` | la pantalla azul |
| 100 | `NodoCursor` | el puntero |

La regla que sale de la tabla: **la capa −2 tapa todo lo que haya detrás dentro
de la columna de 400 px de la mesa.** Lo que caiga ahí va en la 5.

## Trampas que ya nos han costado tiempo

- **Rejilla de píxeles.** Nada se mueve, escala ni rota en fracciones de
  píxel: la cámara, la respiración y las rotaciones van en pasos enteros o
  la imagen hierve.
- **La cámara va en `_physics_process`**, pegada a la simulación. En
  `_process` se queda un fotograma por detrás y a 720 px/s eso pierde la
  bola. Y una sola llamada: ya se duplicó una vez.
- **Los colisionadores y el arte deben ser la misma medida.** Cuando la
  forma sea un parámetro que aún se está ajustando, dibújala por código en
  vez de usar un sprite.
- **Todo efecto tiene que caducar solo.** Un sistema de partículas sin
  caducidad arrastra miles en una partida larga.
- **Cada rincón nuevo de la mesa es un sitio donde la bola se acuña.**
  Prueba cada zona nueva contra atascos y no toques el ball search.
- **Quedarse encerrada rebotando NO es un atasco, y el ball search no la
  saca.** En un atasco la bola se para; encerrada va a toda velocidad en un
  palmo de mesa, así que el ball search nunca salta y el jugador mira sin
  poder hacer nada. Pasa allí donde algo que EMPUJA quede casi paralelo a una
  pared: el slingshot empujaba también por su espalda y el pasillo del outlane
  se convertía en una trampa de 4 segundos. **Cualquier cosa con `empuje`
  tiene cara** (`Colisionador.cara`): por detrás rebota, pero no patea.
- **Que la bola drene no significa que el juego funcione.** La órbita soltaba
  la bola pegada a la banda izquierda y se iba por el outlane sin acercarse a
  una pala: la apertura de TODAS las bolas era perderla sin jugar, y la
  batería entera pasaba, porque medía que la bola no se sale, no se atasca y
  acaba drenando. Drenaba de maravilla. **Toda salida de recorrido tiene que
  probarse contra "¿llega a una pala?", no contra "¿acaba drenando?".**
- **`Mesa.new()` copia los parámetros dentro de cada colisionador** en el
  constructor. Cambiar `m.p.<lo_que_sea>` DESPUÉS de crear la mesa no hace
  nada: el colisionador ya tiene su copia. Un barrido de parámetros escrito
  así mide seis veces lo mismo. Para barrer hay que tocar
  `parametros_mesa.gd` y volver a lanzar.
- **No edites `.gd` con `Set-Content -Encoding utf8` desde PowerShell**:
  corrompe los acentos por doble codificación (`restitución` →
  `restituciÃ³n`). Usa herramientas de fichero, no `-replace` en consola.
- **Una bola rueda: no se sostiene en una cuesta.** El rozamiento de Coulomb
  sí puede sostenerla, así que aplicárselo a una bola apoyada la suelda al
  sitio. Por eso el contacto va en dos regímenes: por encima de
  `velocidad_rebote_minima` es un impacto y lleva Coulomb; por debajo está
  apoyada y solo lleva `rodadura`, que nunca puede vencer a la gravedad. Y lo
  que sostiene la bola en la pala levantada es **la forma de la cuna, no el
  rozamiento**: está medido que no depende de él.
- **Un frenado proporcional a la velocidad le pone VELOCIDAD LÍMITE a la
  bola.** `rodadura` es de esos: la límite vale
  `gravedad·sen(cuesta)/rodadura`, y si cae dentro del rango que la bola
  alcanza de verdad, la bola baja a velocidad constante y se ve falsa al
  instante —una bola con peso acelera—. Con `rodadura` a 20 la límite en la
  pala salía a 41 px/s y Daniel lo cazó jugando. Cualquier frenado que se
  escriba así se juzga por su velocidad límite, no por lo bien que amortigua.
- **La cuna la hace el ÁNGULO de la pala levantada, y decide dos cosas.** Con
  la pala muy empinada la bola rueda hasta el canto del eje, se cae por ahí y
  la pala la vuelve a coger: parece que bota contra la goma, y encima queda
  sin palanca, porque la velocidad que le mete la pala es ω×r. Si la bola no
  se asienta o el tiro desde la cuna no llega, mira `flipper_activo_*` antes
  que el rozamiento. Y el alcance de ese tiro lo da
  `flipper_velocidad_giro`: subirlo NO acelera el juego —está medido que la
  ventana de reacción y la duración de bola no se mueven, porque las fija la
  gravedad al caer— solo alarga lo que tú tiras.
- **Regenerar un wav no basta: hay que reimportarlo.** Godot sirve la copia
  de `.godot/imported/`, así que tras `python sonidos.py` el juego y las
  pruebas siguen oyendo el sonido viejo. Hay que lanzar
  `Godot ... --headless --path C:\dev\tilt-os --import` antes de probar.
- **Un sistema que el jugador no ve no existe, y se diagnostica como si
  faltara.** El platillo devolvía 6 s de reloj, con sonido, onda y un "+6 s"
  flotante, y Daniel jugó un run entero pidiendo "algo para parar el tiempo".
  El fallo era que la causa salía ABAJO, en el platillo, y el contador estaba
  ARRIBA y sin etiquetar: nada ataba una cosa a la otra. **Antes de construir
  lo que el jugador pide, comprueba si ya está y no se ve** —si lo construyes,
  acabas con el sistema duplicado y sigues sin que se entienda. Y la regla que
  sale de ahí: **un efecto se muestra donde se MIDE, no solo donde se
  produce.**
- **Una pregunta sobre un sistema invisible no tiene respuesta válida.** "¿El
  platillo compensa?" se contestó "prefiero el cañón" cuando en realidad era
  "no sabía que hacía nada". Si una pregunta de la lista depende de que el
  jugador haya entendido algo, verifica primero que lo entendió.
- **Un dato escrito en un fichero de datos no da error cuando está mal.** Una
  clave de reliquia mal escrita en `data/reliquias.json` no rompe nada: deja una
  reliquia que no hace absolutamente nada, el jugador la coge, no la nota, y el
  fallo se diagnostica como balance. Es la misma avería del platillo con otra
  cara. **Todo lo que se configure por datos necesita una prueba que compruebe
  que alguien LEE esa clave**, no solo que el fichero se parsea.
- **Un denominador escrito a mano miente igual que un dato mal.** El HUD dividía
  la vida por `p.vida_jugador` —la vida DE PARTIDA— en vez de por la máxima de
  verdad, así que con una reliquia que subiera el techo salía "215/180" y la
  barra se pasaba de largo. La curación estaba bien topada: lo que estaba mal
  era contra qué se comparaba. **Cuando un número tenga tope, enséñalo siempre
  contra la función que calcula el tope, nunca contra el parámetro.**
- **La fuente del juego es NUESTRA y se genera con `python3 fuente.py`**, igual
  que los sonidos. Rejilla de 5×7 en celda de 6×8, así que **solo se ve nítida a
  8, 16, 24, 32 y 48**: todo el texto pasa por `FuenteUI.tam()` y hay una prueba
  que impide que se cuele un tamaño suelto. Y los marcos de la cáscara salen del
  mismo script, **cuadrados por construcción**: las nueve piezas miden la unidad
  y los cuatro lados son el mismo perfil reflejado.
- **Una tipografía suave alrededor de píxeles duros parte la pantalla en dos.**
  El apaño de usar una fuente del sistema arreglaba los acentos y rompía otra
  cosa: la cáscara y la mesa dejaban de parecer el mismo programa. Si algo se ve
  "mal" y no sabes por qué, mira si hay material mezclado antes que geometría.
- **Una fuente sin glifos no da error, deja un hueco.** Todo cogía la fuente de
  reserva de Godot, que solo trae ASCII, y el juego llevaba meses sin acentos ni
  eñes sin que saltara nada: "MANTÉN" salía "MANTN". La fuente vive en
  `render/fuente_ui.gd` y hay una prueba que comprueba que sabe escribir en
  castellano. **Nadie coge `ThemeDB.fallback_font` por su cuenta.**
- **Calibrar contra un jugador inventado sale mal dos de dos.** Los perfiles de
  `medir_balance.gd` son un modelo, y el de en medio hace 312 de daño por bola:
  ESE NO ES DANIEL. Con la vida de los enemigos escrita para ese perfil, él no
  pasaba del segundo combate. La aritmética estaba bien y medía a otro. Por eso
  el juego mide ahora al jugador de verdad —`Run.dano_por_bola()` y
  `segundos_por_combate()`, en la pantalla de fin de run— y **la tabla se
  escribe con esos dos números, no con los del modelo.**
- **Cobrar por tiempo no escala: al alargar los combates, el coste se dispara.**
  El coste es `tiempo/reloj × ataque + bolas × drenaje`, así que multiplicar por
  catorce la duración multiplica por catorce lo que cuesta, y ninguna tabla de
  ataques cuadra —o el primer enemigo te mata o el último no hace nada—. Por eso
  **el reloj es de cada enemigo, no global**: la vida dice cuánto DURA y el
  reloj dice cuánto APRIETA, y son dos mandos separados.
- **Una fase que no se cierra deja la pantalla muerta, sin dar error.** El golpe
  que completaba la última misión podía ser el mismo que mataba al enemigo: el
  run entraba en RULETA, el combate intentaba cerrarse, `resolver_combate` se
  iba de puntillas por estar en otra fase, y el run se quedaba en RULETA para
  siempre. El mapa salía sin ninguna rama viva y no respondía a nada. **Todo
  `if fase != X: return` es un cuelgue esperando**: o se contempla la otra fase o
  se deja constancia de por qué es imposible llegar ahí.
- **Un número que no se ve no informa, aunque esté.** El daño salía en 9 px,
  igual para un bumper de 6 que para un cañón de 300. El número estaba y no
  decía nada. Ahora el tamaño sale de lo gordo que es el golpe COMPARADO CON EL
  RESTO DE LA PARTIDA, no de un umbral fijo: con reliquias de daño, un umbral
  escrito a mano se queda viejo a los tres combates.
- **Un atlas de nueve trozos se corta en REJILLA FIJA, no por silueta.**
  `procesar.py` recorta por silueta por defecto, que es lo correcto para un icono
  y lo peor posible para un marco: cada pieza sale con el tamaño de su dibujo, y
  entonces las esquinas no cuadran con los bordes por un par de píxeles. No da
  error, deja el marco descuadrado. Para marcos: `--tira 3 --filas 3`. Hay una
  prueba que comprueba que las cuatro esquinas midan igual.
- **Una reliquia no es código.** Es una bolsa de modificadores con nombre, y el
  combate pregunta por esas claves donde ya tomaba decisiones. Si una reliquia
  nueva pide un `if` nuevo en `Combate`, es que falta un gancho: se añade el
  gancho, no el caso. Y una bolsa vacía tiene que ser EXACTAMENTE neutra, o todo
  el balance medido deja de valer sin avisar.
- **El balance no se toca sin medir: hay una herramienta.**
  `tests/medir_balance.gd` monta combates con el `Combate` de verdad y tres
  perfiles de jugador, y barre configuraciones enteras. La tabla de enemigos se
  rehízo dos veces a ojo antes de existir, y las dos se llevó por delante el
  run. **Antes de tocar vidas, ataques o el reloj, lánzala.**
- **Un castigo que cobra por tiempo se paga al cuadrado si juegas mal.** El
  coste de un combate resultó ser `bolas × drenaje + relojes × ataque`, y las
  bolas son `vida del enemigo ÷ daño por bola`. O sea que jugar peor pega
  menos, y por eso tarda más, y por eso le cobran más veces. Está medido que el
  daño por bola varía 19 veces entre jugar mal y jugar bien, y que de esas 19
  solo 2,6 son el multiplicador de combo: las otras 8,4 son cuánto aguantas la
  bola viva, que ES la habilidad y no se puede tocar sin quitar el juego.
- **Un umbral más grueso que lo que pretende medir reparte por redondeo, no
  por habilidad.** Con el reloj cargando en 18 s, un combate de jugador bueno
  duraba 9-19 s y NO comía ningún golpe; uno normal duraba 22-29 s y comía uno.
  La diferencia de castigo entre los dos era de cero a uno —una razón
  infinita— por un escalón demasiado gordo. Eso hacía además que bajar la vida
  de los enemigos SEPARARA a los perfiles: metía los combates del bueno por
  debajo del umbral y se los regalaba enteros. **Si un mando no responde como
  debería, mira si hay un escalón antes de mirar los números.** Ojo, que la
  tensión sigue viva: aflojar acorta los combates, y acortarlos vuelve a
  esconder al jugador bueno bajo el umbral.
- **Un número escrito a mano en una prueba mide la escala, no lo que dice.**
  Al triplicar la escala de daño fallaron tres pruebas que no tenían nada roto:
  un enemigo con `vida: 5` dejó de necesitar tres bumpers, y un `ganado > 4.0`
  segundos venía de cuando el reloj cargaba en 18. Igual pasó con el criterio
  del barrido, escrito en puntos sobre una vida de 60: al pasar a 180 dejó de
  marcar ni una fila buena. **Las pruebas y los criterios se escriben contra
  los parámetros, no contra constantes.**
- **Recortar una hoja de IA con fondo magenta no es solo cortar la caja.** Al
  trocear las hojas de `assets/prompts_cascara.md` en sus nueve piezas, el
  primer recorte solo delimitó el contenido (bounding box) y no volvió
  transparente el magenta que quedaba dentro y alrededor. El PNG resultante
  se veía bien en un visor porque el magenta cuadraba con el fondo de la
  hoja, pero dentro del juego salía como motas rosas en las esquinas del
  marco y detrás de los iconos con forma no cuadrada. **Cualquier recorte de
  una hoja `#FF00FF` tiene que reescribir el canal alfa** (poner a 0 todo
  píxel cercano al magenta), no solo recortar el rectángulo que lo contiene.
- **Recortar el fondo por DISTANCIA RGB borra a los muñecos violetas.**
  `procesar.py` medía la distancia euclídea al magenta y cortaba a 95. Un
  violeta saturado del dibujo —(156,5,197), la llama de la calavera, el
  cuerpo del espectro— cae a 88 de ese magenta: por debajo del umbral, así
  que se borraba como si fuera fondo. No da error y no se ve en un visor:
  deja al bicho comido por dentro. El espectro perdió el 22 % del cuerpo.
  **El fondo se detecta por TONO, no por distancia**: es magenta puro
  (S≈0,95) y un violeta de dibujo baja de saturación o se va 25-30° de tono,
  que es lo que los separa. Y el magenta del generador no siempre es el
  mismo —hemos visto (243,16,233) y (224,12,223)—, así que se lee del borde
  de la hoja en vez de darlo por constante.
- **Un hueco dentro de un sprite no significa que falte nada.** Al reparar
  lo ya recortado, la tentación es cerrar la silueta y rellenar todo lo
  transparente que quede dentro: eso tapa los radios del girador, los
  barrotes de la reja y la grieta del suelo, que son huecos a propósito.
  `limpiar.py` solo rellena donde el borde del hueco sea violeta de verdad
  (tono 255-330 con saturación y con luz), que es la firma del fallo de
  arriba. **Un arreglo automático de arte se mira antes de aplicarlo**: el
  del espectro salía peor que el original —le tapaba un ojo—, así que está
  en la lista de excepciones esperando su hoja.
- **La cuantización a paleta deja sal.** Píxeles sueltos a los que les toca
  un color que no tiene nada que ver con sus vecinos: motas verdes en una
  armadura marrón. Es del script, no del generador. `limpiar.py` los caza
  midiendo en Lab contra los 8 vecinos.

- **Una capa DETRÁS de la mesa no existe allí donde la mesa dibuja.** La cáscara
  va en la capa −10 y `NodoSuelo` pinta un rectángulo de cabina OPACO sobre los
  400 px de ancho de la mesa, de arriba abajo de la pantalla. O sea que la barra
  de título de la ventana de la mesa —con su "cascabel.exe" y sus tres botones—
  se dibujaba entera y no se veía jamás: de la ventana solo sobrevivían las
  cuatro tiras de 8 px que sobresalen por los lados. La barra de tareas quedaba
  partida por el medio y se salvó de milagro, porque el botón Inicio, la pestaña
  y el reloj caen los tres FUERA de esa columna. **Todo lo que cruce la columna
  de la mesa va en `NodoCascaraFrente` (capa 5), no en `NodoCascara` (−10)**, y
  lo que se queda detrás es solo lo que nunca la pisa: fondo, iconos de las dos
  bandas y paneles de la derecha.
- **Un patrón de prueba con un agujero deja pasar exactamente lo que buscaba.**
  La prueba que impide tamaños de fuente sueltos buscaba `, 11, C_ALGO` o
  `, 11, Color(`, así que un `draw_string(..., 11, col)` con el color en una
  variable en minúsculas pasaba de largo: el nombre de la reliquia en la tele
  llevaba toda la Fase 5 escalado por 1,375, con filas de píxeles comidas, y la
  prueba decía que no había ninguno. **Un patrón que enumera las formas buenas
  se salta las que no se te ocurrieron**; si la regla es "todos los tamaños",
  el patrón tiene que cazar todas las llamadas y filtrar después.
- **Un mosaico de prueba antes de integrar ahorra una vuelta.** Para las
  hojas de nueve trozos generadas por IA, montar un mosaico 6×6 en memoria
  (repetir cada borde, poner las cuatro esquinas) y mirarlo ANTES de copiar
  nada al repo cazó un fallo real: una hoja tenía las nueve celdas separadas
  por huecos de magenta en vez de pegadas, así que dividir la imagen en
  tercios iguales cortaba mitad celda y mitad hueco. Sin el mosaico eso solo
  se ve dentro de Godot, tarde.
- **Un icono de escritorio decorativo va a la izquierda, no a la derecha.**
  En un escritorio de verdad los iconos se apilan donde hay sitio arriba a
  la izquierda; la banda derecha se deja vacía a propósito. Metimos los
  iconos nuevos a la derecha porque ahí es donde sobraba hueco en el layout,
  y quedó mal a la primera. Si hacen falta dos grupos en la misma banda (las
  reliquias, que si importan, y los decorativos, que no), que cuelguen desde
  extremos opuestos —reliquias desde arriba, decorativos desde abajo— en vez
  de repartir el escritorio en dos mitades que no es como se ve uno de
  verdad.
- **Un cambio de recompensa puede romper la mesa sin romper la física.** El
  cañón devolvía la bola al racimo de bumpers y alimentaba un bucle que
  mataba al enemigo sin que las palas participaran nunca. Cuando cambies
  dónde sale un recorrido, mira qué bucle acabas de crear. **El criterio no
  es que haya bucle, es quién lo mantiene:** uno que exige control del
  jugador en cada vuelta es bueno —es el eje de build "golpe único"—; uno
  que se sostiene solo está roto.

## Cómo trabajar

- **Una fase por sesión**, commit al cerrarla. Si en mitad aparece una idea
  buena de otra fase, se anota en `ESTADO.md` y se sigue.
- **`ESTADO.md` no es un registro de cambios.** Al cerrar sesión, resume lo
  tuyo en dos o tres líneas y borra el detalle de la sesión anterior. Lo que
  merezca sobrevivir para siempre —una trampa, un invariante— va aquí, no
  allí.
- **Los criterios de salida se comprueban jugando, no leyendo el código.**
  Cuando algo dependa del tacto, exponlo como parámetro y pregunta. No
  decidas desde el código lo que solo se sabe con las manos.
- **Di siempre qué modelo y qué nivel de razonamiento usas para cada tarea**,
  antes de empezarla, para que Daniel pueda ver dónde se va el presupuesto.
  Guía por tipo de trabajo:

  | Tarea | Modelo / razonamiento |
  |---|---|
  | Auditar assets, correr scripts, renombrar, mover ficheros | Haiku, razonamiento bajo |
  | Escribir un script de proceso, editar `.md`, conectar un asset ya recortado | Sonnet, razonamiento medio |
  | Balance, física, geometría de mesa, diagnosticar un bug de tacto | Opus, razonamiento alto |
  | Decidir diseño, reabrir un invariante | Opus + preguntar a Daniel o Fátima |

- **`rtk` (Rust Token Killer) siempre que se pueda.** Es un programa de
  consola instalado en el cmd/PowerShell de Daniel que recorta el contexto
  antes de mandarlo. Se usa para leer código y ficheros grandes en vez de
  volcarlos enteros. **Ojo:** desde un sandbox en la nube no se alcanza —el
  bridge da una VM Linux, no la consola de Windows—, así que en una sesión
  remota se trabaja sin él y se dice. En sesión local, con él.
  *(Pendiente: anotar aquí el comando exacto y los flags cuando Daniel los
  pase.)*

- **El trabajo de arte va POR TANDAS**, no todo de una vez: una tanda es un
  grupo de assets que comparte hoja y destino, se recorta, se mira en un
  mosaico y se integra antes de empezar la siguiente. Las tandas pendientes
  están en `ESTADO.md`.

- **Cada tanda de assets se documenta en `assets/INVENTARIO_HOJAS.md` antes
  de cerrar la sesión, siempre, sin que haga falta que Daniel lo pida.** Qué
  hoja es cada cosa, a qué carpeta y nombre fue, y qué se dejó fuera y por
  qué. La primera vez que hubo que mapear 29 hojas sin ese registro se
  perdió media sesión mirando miniaturas para adivinar qué era cada una —
  varias eran redos de cosas que ya estaban integradas, y sin documentarlo
  la próxima sesión habría vuelto a mirarlas una por una. El inventario es
  la memoria entre sesiones que `ESTADO.md` no puede ser, porque
  `ESTADO.md` tiene que quedarse corto y esto no cabe ahí.

- **No te incluyas como colaborador, contribuidor ni autor** en el
  repositorio ni en ningún archivo: ni README, ni CONTRIBUTORS, ni
  cabeceras, ni mensajes de commit.
