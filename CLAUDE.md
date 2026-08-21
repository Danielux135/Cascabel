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
`PROPÓSITO.md` tiene la capa que falta: por qué alguien vuelve a abrir el juego.
Preparación (cascabeles y palas), selector de dificultad, rampas fallables con
su barra de carga, y la cáscara como metajuego. **Ábrelo antes de tocar
desbloqueos, dificultad o la capa de Preparación.**
`CONTEXTO.md` tiene la referencia densa: paleta, assets, proporciones,
estética. **Ábrelo solo para buscar un dato concreto**, no por costumbre, y
no es fuente de verdad para parámetros ni geometría: esos viven en el
código. Si contradice a este archivo, manda este archivo.

## Lo último de cada sesión

**Actualiza `ESTADO.md`** antes de terminar: qué has cerrado, qué queda
abierto, qué es lo siguiente y qué necesitas que Daniel pruebe. Si no lo
haces, la siguiente sesión empieza a ciegas.

**Y actualiza la memoria del proyecto** si has tocado código significativo:

    codebase-memory-mcp cli index_repository --repo-path C:\dev\tilt-os

**Y ya está: no hay nada que commitear.** Ver el apartado de abajo.

## Codebase Memory MCP — cuándo y cómo

**Qué es:** El MCP indexa tu codebase (1.833 nodos, 7.599 relaciones) y pone
esa red de conexiones a disposición de Claude, evitando la lectura archivo
por archivo.

**Cuándo SÍ lo necesitas:**
- Buscar dónde se usa una función/clase en todo el proyecto
- Trazar la cadena completa de llamadas (quién llama a quién)
- Encontrar impacto arquitectónico de un cambio
- Auditar si algo está muerto o sin usar
- Preguntas de "¿cómo está organizado esto?" que cruzan módulos

**Cuándo NO lo necesitas:**
- Cambios locales dentro de un archivo que ya abierto
- Cuando ya sabes dónde buscar
- Un bugfix simple que solo toca una pieza
- Si la batería pasa, está todo bien sin MCP

**Cómo actualizar (al final de cambios significativos):**

    codebase-memory-mcp cli index_repository --repo-path C:\dev\tilt-os

Detecta automáticamente cambios incrementales (rápido, ~4 s), y **con eso ya
está hecho**.

**NO HAY NADA QUE COMMITEAR, y esto decía lo contrario.** Este apartado y el de
arriba mandaban `git add .codebase-memory/graph.db.zst`, y **ese fichero no
existe ni lo genera esta versión del CLI**: sus quince herramientas son
`index_repository`, `search_graph`, `query_graph`, `trace_path`,
`get_code_snippet`, `get_graph_schema`, `get_architecture`, `search_code`,
`list_projects`, `delete_project`, `index_status`, `check_index_coverage`,
`detect_changes`, `manage_adr` e `ingest_traces`, y ninguna exporta un
artefacto. El propio indexado lo dice en su salida: `"artifact_present": false`.
El grafo vive en el almacén local del daemon, así que **el índice NO viaja con
el repo**: en otra máquina hay que volver a indexar, que cuesta cuatro
segundos. `.codebase-memory/README.md` sigue describiendo el fichero y su
número de nodos como si existiera; está escrito de cuando lo generaba.

**Y hay que lanzarlo con Claude Code cerrado**, o el daemon rechaza al cliente
con `CBM daemon is active or starting but could not accept this client within
30000 ms`: el servidor MCP de la sesión lo tiene tomado. Si se atasca,
`taskkill /F /IM codebase-memory-mcp.exe` y reintentar.

**Ojo con `&&` al copiar comandos**: la consola de Daniel es Windows PowerShell
5.1 y ahí `&&` es un error de sintaxis. Se encadena con `;` o con
`A; if ($?) { B }`.

**Cómo ver el grafo 3D** (arquitectura visual):

    codebase-memory-mcp daemon start
    # Luego abre: http://localhost:9749

## Godot

No está en el PATH. El ejecutable de consola (el que devuelve la salida) es:

`C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe`

Batería de pruebas, sin abrir ventana:

    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/prueba_sim.gd

Medidas (no son pruebas: no fallan, imprimen tablas):

    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/medir_balance.gd
    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/medir_reliquias.gd
    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/medir_capas.gd

### En una sesión remota se puede lanzar el juego CON VENTANA

No solo los medidores sin `render/`. Con un display virtual, Godot abre la
ventana de verdad, se le mandan teclas y se guardan capturas, así que **se
puede MIRAR el juego en vez de imaginárselo**:

    curl -sSL -o g.zip https://github.com/godotengine/godot/releases/download/4.7.1-stable/Godot_v4.7.1-stable_linux.x86_64.zip
    unzip -q g.zip && chmod +x Godot_v4.7.1-stable_linux.x86_64
    Xvfb :99 -screen 0 1920x1080x24 &
    DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1 ./Godot_v4.7.1-stable_linux.x86_64 \
        --path <copia> --display-driver x11 --rendering-driver opengl3 --windowed

Para conducirlo se mete un autoload de usar y tirar que lea un guion de
`OS.get_environment`, mande las teclas con `Input.parse_input_event` y guarde
`get_viewport().get_texture().get_image().save_png(...)`. **Ese autoload no va
al repo**: se pone en la copia de la caja y se borra. El audio no arranca (no
hay tarjeta) y avisa; da igual.

Esto es lo que cazó el halo de magenta y el reloj cortado, y ninguno de los
dos salía en la batería. **Lo visual se mira, no se deduce.**

**Y para llevar el repo a la caja, un tar, no cincuenta ficheros.** El bridge
sube 50 ficheros por llamada y el repo tiene 600, así que lo que se hace es
comprimirlo EN la carpeta del escritorio, subir el `.tgz` y descomprimirlo en la
caja. Dos paquetes, porque el código pesa 300 KB y los assets 1,4 MB:

    tar czf caja_fuente.tgz --exclude='*.uid' project.godot icon.svg icon.svg.import \
        sim render tests data *.md
    tar czf caja_assets.tgz assets

Los `.uid` sobran: Godot los regenera con `--import`, que hay que lanzar en la
caja de todos modos y **también después de crear una clase nueva**, o `Parse
Error: Could not find type "..."`. Ojo con el sitio de los dos `.tgz`: nada se
descomprime dentro del repo (ver Trampas), y como el bridge no puede borrar, al
acabar se mueven a `_to_delete/`.

**Sin `assets/` la batería da 20 fallos que no son fallos** —todos "no existe tal
PNG"—, así que si lo que se toca es física, con el paquete de código basta; si se
toca cualquier cosa que dibuje, hay que subir los dos y entonces sale 499/499.

## Herramientas del repo

Se generan, no se dibujan ni se editan a mano:

| Script | Qué hace |
|---|---|
| `python3 fuente.py` | la fuente pixelart y los cinco marcos de nueve trozos — **OJO: los marcos que saca hoy NO son los del repo**, ver Trampas |
| `python3 sonidos.py` | los sonidos sintetizados (y luego hay que reimportar) |
| `python3 sonidos_pruebas.py` | **el banco de prototipos**: sonidos que aún no dispara nadie, en `assets/sonido_pruebas/`. Ver abajo |
| `python3 procesar.py hoja.png ...` | recorta una hoja de IA con fondo magenta |
| `python3 limpiar.py assets/` | repara sprites YA recortados de los que no queda hoja |

**`sonidos.py` y `sonidos_pruebas.py` están separados por un candado, no por
orden.** La batería falla si el juego pide un wav que no existe Y si existe un wav
que el juego no pide: un wav generado y sin enganchar es un evento mudo esperando,
que es la avería que abrió la tanda 0h2. Eso deja sin sitio a lo que hay que **oír
antes de construir**, y ese sitio es el banco. La regla: **un sonido vive en el
banco mientras no exista la cosa que lo dispara; el día que exista, su receta se
MUEVE a `sonidos.py` y su ajuste a `nodo_sonido.gd`, en el mismo commit.** Nunca
antes, nunca en los dos sitios.

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
- **Una rampa se cobra al COMPLETARLA, no al salir de ella.** Desde que tienen
  cuesta hay dos salidas —completarla, o volver por tu boca sin llegar— y solo
  la primera paga. Son dos señales distintas, `rampa_salida` y `rampa_devuelta`,
  y no se pueden juntar: si el fallo saliera por `rampa_salida`, el cañón te
  pagaría el golpe gordo por un tiro que no ha llegado y el umbral te abriría la
  caza por no llegar al umbral.
- **LA CUESTA COBRA ALTURA, NO LONGITUD DE CURVA.** `Rampa.velocidad_escape`
  descuenta energía por los píxeles que la bola SUBE, medidos sobre la propia
  curva. De ahí salen solas tres cosas que si no habría que escribir a mano: un
  túnel llano no cuesta nada, el regreso no se puede fallar porque solo baja, y
  mover un punto de control recalibra la rampa sin tocar ningún número.
- **TODAS las rampas que suben se pueden fallar.** Decisión de Fátima
  (ago-2026): *"todas las rampas han de tener esa mecánica de que puede no
  llegar; si hay que poner altura a las rampas, se pone."* Las cuatro que no la
  tienen es porque no suben —los dos túneles y el regreso— o porque Daniel la
  dejó cerrada a propósito: el umbral va a ser una puerta, y una puerta no se
  falla, se abre.
- **El daño se aplica al golpear, no al drenar.** No hay cuenta de bolas:
  hay vida, y drenar cuesta vida.
- **Con multibola, drenar es que caiga LA ÚLTIMA.** Perder una bola mientras
  quedan otras en la mesa no cuesta ni vida, ni combo, ni contraataque: la señal
  `bola_drenada` solo salta con la última, y las demás salen por `bola_perdida`,
  que existe para el sonido y para nada más. Decisión de Daniel (ago-2026), y es
  lo que hace que la multibola sea un eje de build y no un adorno. Si dos caen en
  el mismo subpaso se cierra UN turno, no dos.
- **La cámara sigue a la BOLA MÁS BAJA, y no hay zoom.** Decisión de Daniel
  (ago-2026): a la cámara se le pasa UNA bola —`Mesa.bola_en_peligro()`— y así las
  cuatro reglas y el escalado entero siguen intactos. Alejar la cámara para que
  quepan todas rompe el escalado entero del pixelart; si hace falta saber dónde
  están las otras, lo que se añade son flechas en el borde, no zoom.
- **El racimo tiene DOS bumpers en la cara por la que ENTRA la bola.** No "dos
  arriba": dos en la cara de entrada. La bola tiene que colarse entre dos y
  rebotar contra el tercero; si el tercero es el primero que se encuentra, se la
  devuelve de un manotazo. En esta mesa el racimo está en lo más alto que se
  alcanza, así que la bola entra SUBIENDO y la cara de entrada es la de abajo
  (`bumper_giro`, ago-2026). Estuvo del revés desde el principio con un
  comentario que decía "esto está medido": lo estaba, contra una bola que caía.
- **LA MESA TIENE DOS PLANTAS Y LAS DOS SON MESAS, con sus palas.** La planta
  alta tiene dos palas —con las MISMAS teclas que las de abajo, como un flipper
  superior de verdad— y **una mesa que no se parece a la de abajo**: palas
  CORTAS, sin slingshots, sin outlanes, sin carriles de retorno, sin postes, sin
  giradores y sin targets; con una ISLA elevada, dos TÚNELES, una SUBIDA con
  cuesta y su ÓRBITA por la franja izquierda. **Y las dos plantas llevan el mismo
  suelo**: mientras la de arriba fue un pasillo se dibujaba en hueco oscuro, y
  con palas dentro eso se lee como una mesa flotando en un pozo.
- **UNA REJILLA DE PINES ES UN COMEDOR DE ENERGÍA PASIVO.** La primera versión de
  la planta alta era un campo de pines y Daniel la tumbó jugándola: *"el pachinko
  es literalmente que caiga la bola, y que luego no pase de la primera línea"*.
  La primera fila se lleva la velocidad y el resto es caída, así que no hay tiro,
  hay embudo. **Lo que hace que una zona de pinball se juegue son palas.**
- **LA PLANTA ALTA FUE UNA RÉPLICA Y ESO NO VALÍA.** Su zona de palas estaba
  calcada de la de abajo —se hizo así para heredar tres sesiones de arreglos— y
  Daniel la tumbó mirándola: *"el mapa de arriba no puede ser una réplica, ha de
  sentirse diferente"*. Rehecha en la tanda 0i contra `CAZA.md` §3. **Si algún
  día vuelve a hacer falta una pieza arriba, no se copia de abajo: se decide.**
- **LAS CAPAS DE ALTURA YA NO ESTÁN APAGADAS, y solo las usa la planta alta.**
  Lo restringido son cuatro paredes —la falda de la isla, que solo existe en el
  tablero— y una rampa con cuesta y cambio de altura, la subida a la isla. **La
  planta de abajo sigue entera en `TODAS` las capas y sin cuesta**, y hay dos
  pruebas que lo sujetan: si algo de abajo aparece restringido, el balance medido
  deja de valer sin avisar. El párrafo de abajo sigue valiendo palabra por
  palabra para entender el sistema.
- **LA MESA TIENE CAPAS DE ALTURA, Y ENTRARON APAGADAS.** `Bola.capa` dice a qué
  altura va cada bola y `Colisionador.capas` en qué alturas existe cada cosa; una
  plataforma es una región con borde y salirse de él es caerse; un túnel es el
  mismo spline con `subterranea`; y una rampa puede tener cuesta
  (`velocidad_escape`). **Todo eso viene por defecto en "todas las capas" y con
  la cuesta a 0, que es lo único que deja la mesa medida exactamente como
  estaba** — y está comprobado al decimal en `tests/medir_capas.gd`. Cuando algo
  se restrinja a una capa, se restringe a mano y se vuelve a medir. Una máscara
  puesta sin querer no da ningún error: deja a la bola atravesando una pared.
- **Una rampa con cuesta es ENERGÍA, no tres casos.** `v² = v0² − (escape·0,6)²·
  recorrido/largo`, y las tres bandas de `PROPÓSITO.md` §6 salen de ahí sin
  fronteras escritas a mano. Y la velocidad se CALCULA desde la distancia, nunca
  se acumula: integrándola, subir y volver a bajar devuelve un número parecido en
  vez del mismo, y una rampa que no es determinista deja de ser una curva y pasa
  a ser física simulada, que es justo lo que el invariante prohíbe.
- **Caerse de una plataforma y caerse de una rampa son EL MISMO evento**
  (`Mesa.bola_cayo`). En la mano se sienten igual, y separarlos obligaría a la
  vista, al sonido y al combate a enterarse dos veces de lo mismo. Avisa aunque
  la capa no cambie: una rampa abierta que empieza y acaba en el tablero no mueve
  ningún número y sigue siendo un evento que tiene que sonar.
- **El ALTO de la mesa no es invariante; el ANCHO sí.** Los 400 px de ancho
  sostienen el hueco entre palas y toda la física medida. Los 1300 de alto se
  suben si las capas lo piden — lo dijo Daniel: *"si ha de aumentarse la altura
  máxima del pinball, se aumenta"*.
- **Las dos franjas de 20 px de fuera de las bandas son CARRIL, no margen.** Una
  bola mide 18. Ahí van el umbral (sube por la derecha) y el regreso (baja por la
  izquierda), como los habitrails de una máquina real. Un recorrido que cruza el
  campo por dentro se dibuja encima del racimo y de los targets y no se entiende.
- **Todo lo que se cuente sobre `bumpers`, `bancos`, `giradores` o `rampas`
  cuenta LAS DOS PLANTAS, y desde la tanda 0i no reparten igual**: los 6 bumpers
  son 3 abajo y 3 arriba, las 9 rampas son 3 abajo, 4 arriba y 2 que las unen, y
  los 2 bancos y los 2 giradores son TODOS de abajo. Una prueba que cuente sin
  decir de qué planta habla mide otra cosa.** Media batería contaba "3 bumpers" y "2 bancos" y se
  puso en rojo con la mesa perfecta: los huecos del racimo salían "entre 24 y
  521", y el 521 era la distancia de un racimo al otro. Cualquier prueba de
  geometría tiene que decir de qué planta habla.
- **Y LAS DOS PLANTAS no se comunican por gravedad.** Encima del arco
  está la arena de caza (`DISEÑO.md` §5 y §7): su propio techo, sus paredes y su
  propio suelo, con 12 px de nada entre el fondo de su embudo y el arco de abajo.
  Se sube por el **umbral** y se baja por el **regreso**, y las dos son curvas.
  Los dos números que lo cierran: la bola sube 643 px por sus medios —desde las
  palas, hasta y=557— así que a la arena no llega sola; y una caída libre desde
  ahí arriba llega a las palas a **1500 px/s, o sea 67 ms**, cuando el cañón ya
  se tuvo que ablandar porque 900 px/s era incazable. Abrir el arco y dejar caer
  la bola es regalar ese tiro en cada visita.
- **LA CAZA ES UN BONUS, Y UN BONUS NO SE PIERDE.** Decisión de Daniel
  jugándola (ago-2026): *"esta fase debería sentirse como un bonus, algo
  especial, no algo tan fácil de perder"*. **Drenar en la planta alta no te
  echa**: la mesa vuelve a servir la bola por donde entró (`caza_salvabolas`) y
  lo único que acaba la caza es el tiempo. El precio de estar ahí arriba es el
  que siempre fue —el reloj del enemigo, que no para—, y ese no se toca: lo que
  se quitó fue un SEGUNDO castigo encima del primero. Lo que sí se sigue
  pudiendo perder es la criatura al bajar, que es donde vive la tensión.
- **El regreso NO TIENE BOCA, y el umbral no traga con multibola.** Lo primero
  porque una boca en el suelo del piso de arriba haría que la caza durase lo que
  tarda la bola en encontrarla, no lo que dice `caza_tiempo`: al acabarse el
  tiempo, la arena METE la bola en el regreso. Lo segundo porque la cámara sigue
  a la bola más baja, así que con una bola arriba y otra abajo la caza pasaría
  entera fuera de plano.
- **Los enemigos normales viven fuera del campo de juego.**
- **La bola es el bloque de stats del jugador. NUNCA el radio.** El invariante
  decía "solo en efectos, nunca en tamaño ni masa", y su razón escrita es que
  descuadra el hueco entre palas: **eso solo lo toca el radio**. Fátima lo abrió
  (ago-2026) a **rebote, gravedad y rodadura**, que no tocan el hueco, y ahí es
  donde viven "ligera", "pesada" y "rebotona". `radio_bola` sigue cerrado, con
  una lista de claves prohibidas en `Preparacion` y dos pruebas. **Y toda
  configuración de bola pasa las tres pruebas de jugabilidad** —llega a una pala,
  se puede atrapar en la cuna, no se queda encerrada rebotando—: una gravedad
  baja con rebote alto deja la bola botando en un palmo de mesa para siempre, y
  eso no da ningún error.
- **LA CRIATURA VA DELANTE DE LA CÁSCARA, y eso NO es indiferente.** En el
  retrato de 64 de la preparación se dibuja primero la cáscara y encima la
  criatura: así las manos de `cr_calavera` se agarran al borde de la ranura y
  las dos capas se leen como UN bicho asomándose. Al revés la cáscara la tapa
  **entera** y lo que queda es una bola con una ranura negra — el bicho
  desaparece y no da ningún error. Mirado en un mosaico de las dos criaturas
  contra tres cáscaras antes de escribir la línea, que es lo que costó dos
  minutos y habría costado una sesión al revés.
- **Una hoja de fotogramas se pide por CATÁLOGO y la batería sujeta el candado.**
  `HojaAnimada.CATALOGO` dice qué carpetas y qué filas pide el juego, igual que
  `NodoSonido.AJUSTES` con los wav, y hay dos pruebas que comprueban que no
  queda ni una carpeta ni un PNG en disco fuera de la tabla. Es literalmente la
  avería que abrió la tanda 7: `cr_brasa` y `cr_calavera` llevaban cortadas,
  limpias y con sus ocho fotogramas **sin que las cargara nadie**.
- **Un modificador NO es una mecánica.** Los nueve cascabeles se montaron como
  bolsa de modificadores —reutilizando el sistema de reliquias— y salieron
  medidos, equilibrados y **completamente invisibles**: un ×1,19 al daño no se ve
  jugando. **Una bolsa de modificadores solo sabe producir porcentajes; para que
  pasen cosas hacen falta EVENTOS** (`sim/estados.gd`). Cuando algo "no se nota"
  y los números dicen que está bien, mira la forma antes que el número.
- **NINGUNA pieza de audio del juego lleva voz.** Decisión de Fátima (19-ago):
  se probó con voz —letra en castellano, muestra de 8 bits, tarareo, locutor—
  en las piezas-archivo de `MUSICA/` (`assets/prompts_canciones.md`) y se
  descartó por completo. La categoría de piezas-archivo se mantiene —siguen
  siendo ficheros que el jugador encuentra y abre, no bucles de fondo—, pero
  **instrumental, no vocals** va en todos los prompts sin excepción, igual que
  en `prompts_musica.md`. Si un candidato de Suno sale con voz, muestra vocal
  o algo que se le parezca, se descarta y se regenera: no se recorta la voz
  después.
- **LA MÚSICA SE PREGUNTA CADA FOTOGRAMA, NO SE ENCIENDE AL CAMBIAR DE
  PANTALLA.** `VistaMesa._musica_que_toca()` mira el estado y dice qué toca;
  `NodoMusica.poner` con lo que ya suena no hace nada. La otra forma —que cada
  sitio que cambia de pantalla ponga su pieza al pasar— es la avería de la caza
  que cruzaba de un combate al siguiente: **un estado que se enciende en un
  sitio y hay que acordarse de apagar en otro acaba puesto donde no toca**.
  Preguntando, no hay nada que se quede encendido, y el orden de los casos ES
  la prioridad. Las dos únicas que mandan sobre eso son las que TERMINAN,
  `arranque` y `tilt`: mientras suenan no se dejan pisar, porque si no el
  escritorio se come al arranque en el primer fotograma.
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
| 30 | `NodoSistema` | el menú de Inicio y las ventanas del sistema |
| 40 | `NodoTilt` | la pantalla azul |
| 100 | `NodoCursor` | el puntero |

La regla que sale de la tabla: **la capa −2 tapa todo lo que haya detrás dentro
de la columna de 400 px de la mesa.** Lo que caiga ahí va en la 5.

## Trampas que ya nos han costado tiempo

### Una pared que muere EN el eje de la pala es una trampa para la bola (ago-2026)

Al construir la planta alta, las dos paredes lisas se hicieron acabar
**exactamente en el eje de su pala**, y con buena intención: acabar *cerca* deja
un rincón del tamaño de la bola entre la pared y la cápsula del eje, y acabar
*en* el eje parecía cerrarlo del todo. Cierra el hueco y abre otro peor.

La bola que baja rodando por la pendiente llega al final y se encuentra la
cápsula del eje como un **bordillo que no puede subir**. Se para ahí, y el sitio
es estable: la pared la empuja hacia el campo, el eje hacia arriba, y entre las
dos aguantan a la gravedad.

Medido con una sonda de usar y tirar, 60 cazas: **33 bolas muertas y 29 de ellas
en el mismo píxel**. El ball search las despertaba a los 2 s, así que **no daba
ningún error y no era un cuelgue**: eran dos segundos de mesa parada en cada
visita. Y tapaba otra cosa más gorda — con la bola muriéndose en la esquina, los
cuatro recorridos de la planta alta registraban **cero entradas**; después del
arreglo, 105, 57, 36 y 26.

Lo que lo arregla: **subir el codo del muro el radio del eje y cuatro más**, de
forma que el muro del desagüe pase POR ENCIMA del eje. Entonces la bola no puede
tocar nunca la cápsula —queda a 24 px cuando necesita 17— y lo primero que se
encuentra al final de la pendiente es la paleta, que es donde tiene que caer.
Cuesta el 7 % del largo de la pala.

**La regla, y vale para cualquier rincón nuevo: no basta con preguntarse si la
bola CABE, hay que preguntarse si se queda.** Un hueco donde no cabe está bien;
uno donde cabe justo y no puede salir por arriba es una silla. Y la forma de
saberlo no es mirar la geometría: es soltar sesenta bolas y **apuntar en qué
píxel se paran** — con el mapa de dónde mueren, la causa salta a la vista; con el
número de bolas muertas a secas, no.

### Perseguir el objetivo escrito en vez de la sensación (ago-2026)

`CAZA.md` §6 pedía un número muy concreto para cerrar la planta alta: *"un
jugador que solo aporrea drena arriba en 3-4 s"*. Se construyó contra él, se
barrieron las palas, se eligió la fila que más se acercaba (7,6 s) y se anotó
como decisión pendiente lo que faltaba para llegar.

**Y el objetivo estaba mal.** Daniel la jugó y lo dijo en una frase: *"esta fase
debería sentirse como un bonus, algo especial, no algo tan fácil de perder"*.
Buscar que el jugador malo pierda rápido es diseñar un CASTIGO; el modo era un
premio que se gana con un tiro de 3 entre 100. Los dos números —el que se
perseguía y el que salió— eran correctos y ninguno de los dos medía lo que
importaba.

**La regla: un objetivo numérico escrito antes de jugar nada es una hipótesis,
no un criterio.** Cuando la medida se acerca al objetivo y aun así algo no
convence, lo primero que hay que poner en duda es el objetivo, no la geometría.
Y el aviso de que iba a pasar estaba escrito en la propia nota: el criterio de
salida decía *"no se lee, se juega"*.

*(Y su corolario, que ya está más abajo con otras palabras: cuando el maniquí y
la persona dicen cosas distintas, gana la persona. El maniquí no notó que la
planta alta era más blanda que la de abajo; Daniel lo notó en dos bolas.)*

### Dar por bueno el techo que hay (ago-2026)

El campo de pines de la tanda 0f se montó debajo del arco porque el arco era el
límite de la mesa. Lo era en el código y no en el diseño: `DISEÑO.md` llevaba
desde el principio un tiro llamado "umbral alto" que abre un modo de caza en la
zona alta, y una frase que lo decía entero — *"y le da sentido a la zona alta,
que hasta ahora era un pasillo"*. Lo cazó Daniel leyendo el resultado.

La regla: **antes de optimizar dentro de un límite, comprueba si el límite es
una decisión de diseño o una consecuencia de no haber construido nada ahí.** Un
techo que nadie escribió en `DISEÑO.md` ni en `PLAN.md` no es un invariante, es
una obra pendiente.


### Medir por la cara que no es (ago-2026)

El racimo de bumpers llevaba desde el principio puesto de espaldas, y lo tapaba
una medida buena: "con uno en la cara de entrada 1,4 golpes, con dos 3,7". El
número era correcto. La bola con la que se sacó, no: se dejaba caer desde
arriba, y a esta mesa no le llega nada de arriba. Medido por la cara buena, el
racimo daba **1,0 golpes por entrada** en vez de 3,7.

Es la misma avería que la tabla de balance medida contra el jugador equivocado,
y se caza igual: **antes de fiarse de una medida, mirar de dónde viene la bola
con la que se hizo.** Si la prueba escoge ella misma la dirección del impacto,
la prueba está eligiendo el resultado.


### En un prompt con imagen de referencia, GANA EL TEXTO (ago-2026)

Dos hojas quemadas por lo mismo, con una semana de diferencia:

1. El prompt de las criaturas adjuntaba `cr_brasa.png` como *"exact reference"* y
   a la vez ordenaba *"no bell, no circular outline of any kind"*. La referencia
   ERA una campana.
2. El prompt de `cr_calavera` decía *"a small skull with a flame burning behind
   its eye sockets"*, y `cr_calavera.png` **no tiene fuego por ningún lado** —
   medidos sus colores son todos piedra y hueso, cero rojos. Esa frase es del
   enemigo `calavera_llameante`. Salió una calavera ardiendo, sin manos, con la
   silueta del cráneo cortada por las llamas.

Las nueve descripciones estaban escritas **desde los identificadores**, no
mirando los nueve PNG. Comprobadas una a una: tres describían a otro bicho
(`cr_calavera` sin fuego, `cr_diablillo` que es un gato gris sin cuernos,
`cr_espectro` que es un blob violeta de tres ojos y no un encapuchado) y tres
más se quedaban a medias.

> **La regla: la descripción dice QUÉ SE MUEVE, no QUÉ ES.** Qué es lo dice la
> imagen. Cada adjetivo de aspecto en el texto es una oportunidad de
> contradecirla, y cuando se contradicen gana el texto.

**Y un rasgo que no nombras, el generador lo borra.** Ocho de las nueve
criaturas tienen manos agarradas al borde del arco: son parte de la pose de
asomarse, así que al mandar tirar el arco se quedan agarradas a nada y
desaparecen. Hay que decir a qué se agarran.

### NO SE PUEDE ITERAR UNA GENERACIÓN (ago-2026)

Cuatro hojas de `cr_calavera` en una mañana, y la cuarta salió **peor** que la
tercera. Medido:

| | v3 | v4 |
|---|---|---|
| Línea de suelo | **61 en los ocho** | 60-61: el bicho flota |
| Alto | **43-43, variación cero** | 45-46 |
| Tonos de cuerpo | 7 | **8** |
| Reflejo que parpadea | 85 % | **86 %** |

O sea: **no arregló ninguna de las dos cosas que se le pidieron y rompió dos que
ya estaban perfectas.** No es mala suerte, es cómo funciona: cada hoja nueva es
**una tirada nueva**, no una edición de la anterior. El generador no refina,
vuelve a dibujar de cero. Por eso ajustar el prompt y regenerar no sube una
cuesta: te mueve a otro punto al azar de la misma distribución.

**Lo que sí funciona:** meter TODAS las correcciones conocidas en UN prompt,
generar **varias hojas de golpe con ese mismo prompt**, y elegir la mejor. Un
tirón de cuatro tiradas iguales bate a cuatro tiradas distintas encadenadas.

**Y guardar siempre la mejor hasta la fecha.** La v3 estuvo a punto de perderse
porque la v4 parecía "la siguiente".

### Post-procesar sí arregla lo mecánico (y no, lo mal dibujado)

*Matiza la regla que quedó escrita demasiado ancha tras la v2.*

- **NO se arregla con un script lo MAL DIBUJADO**: un personaje equivocado, diez
  dedos que no caben en la celda, una pose que no es. Ahí se regenera.
- **SÍ se arregla lo MECÁNICO**: tonos de más, un contorno que se redibuja, una
  silueta que tiembla. Son fallos de repetición, y una máquina repite mejor que
  un generador.

`anim.py --pulir 3` hace las tres cosas: silueta por mayoría de los fotogramas,
contorno duro al color más oscuro de la paleta, y cuerpo reducido a los N tonos
más usados. La v3 de `cr_calavera` pasó de 7 tonos / 85 % de reflejo parpadeando
/ 27 manchas sueltas a **3 tonos / 34 % / cero manchas**, y de no pasar la
batería a pasarla entera. **Sin generar otra hoja.**

No se le pasa a un bicho cuya gracia sea el degradado o el parpadeo, como la
llama de `cr_brasa`.

### Mira los sprites sobre GRIS, no sobre el fondo del juego

Perdí un rato dando por perdida una versión pulida porque "había perdido el
contorno". Lo tenía —luminancia 19,5, más oscuro que el original— pero el fondo
de la previsualización era casi negro y un contorno negro sobre negro no existe.
**El mosaico de revisión va sobre un gris medio** (`7A6B52` sirve), que es donde
se ve a la vez la silueta y las luces.

### El suelo de legibilidad a 64 px, y no se negocia (ago-2026)

La segunda hoja de `cr_calavera` tenía el personaje bien —sin fuego, con manos,
silueta cerrada— y **no valía**. Lo cazó Fátima: *«píxeles fuera de zona, dedos
bug, mucho cambio de píxeles en la luz»*. Los tres, medidos:

| Síntoma | Medido | Causa |
|---|---|---|
| La luz parpadea | **87 % del reflejo**: 172 px se encienden alguna vez, 23 en los ocho | **8 tonos de hueso** donde la guía pide 3 |
| Píxeles sueltos por el borde | 116 px parpadeando en **22 manchas** | el contorno se redibuja cada fotograma |
| Dedos ilegibles | la banda es **UN bloque** con 2 separaciones | ~10 dedos en 49 px = **4,9 px por dedo** |

**El tercero no es un fallo de dibujo, es un límite del tamaño**, y por eso
importa más que los otros dos: no se arregla insistiendo, se arregla pidiendo
menos cosas más grandes.

Los tres números que van en cualquier prompt de celda 64:

- **Nada por debajo de 3 px de ancho se lee.** Un dedo de 2 px con hueco de 1 es
  una banda gris.
- **Máximo 3 tonos por superficie.** Ya está en el bloque A de `GUIA_ESTILO.md`;
  cada tono de más es una frontera más que puede temblar entre fotogramas.
- **Un reflejo especular es una FORMA FIJA**, no una zona que se redibuja.

**Y probado y descartado como parche:** congelar el cráneo con
`anim.py --congelar-arriba 38`. Funciona —el cambio por fotograma baja de 333 a
207 px— pero entonces lo único que se mueve son los dedos, o sea que le da todo
el protagonismo a lo peor dibujado. **Post-procesar no salva una hoja mala**, y
conviene recordarlo antes de escribir más código de salvamento.

### Un generador NO sabe repetir un dibujo ocho veces (ago-2026)

Y por eso hay una parte que no se arregla con prompts. La segunda hoja de
`cr_calavera` pedía *"everything else must be pixel-identical in all eight
cells"* y aun así **el 20-42 % de los píxeles cambia entre fotogramas, con la
silueta bailando entre 377 y 1.841 px**. A 64 px eso no se lee como animación,
se lee como que el sprite hierve.

**Descartado antes de culpar al arte:** que fuera el recorte. Se cortó a paso
uniforme entero en vez de por centroide y sale igual, 49 % contra 51 %. El
temblor viene de la hoja.

Se arregla en la herramienta, no pidiendo otra hoja. `anim.py --estabilizar`
(por defecto):

- Calcula el fotograma **MODA** — el color más repetido de cada píxel a lo largo
  del bucle. Ese es el dibujo que el generador intentaba repetir.
- Cada fotograma conserva solo los píxeles que se apartan mucho de la moda; el
  resto vuelve a ella. El movimiento de verdad se aparta mucho y sobrevive; el
  ruido de redibujado se aparta poco y desaparece.
- **Moda y no media**, porque son entradas de una paleta de 33 y promediar
  inventaría colores que no están.
- **Y nunca borra tinta**: solo devuelve a la moda un píxel opaco en los dos
  sitios. Sin esa condición se comía las chispas sueltas de `cr_brasa`, que solo
  salen en uno o dos fotogramas y son arte. Un píxel que aparece o desaparece es
  movimiento por definición.

Medido: la calavera pasa de 578 a 333 px de cambio por fotograma y el 87 % de la
tinta vuelve a la moda; la llama conserva su movimiento (68 %).

### El mapa de movimiento: contar píxeles no basta, hay que ver DÓNDE

La hoja mala de `cr_calavera` cambiaba entre 867 y 1.293 px por fotograma —
números buenísimos, iguales que los de la hoja buena de `cr_brasa`. Y estaba
mal: se movía el cráneo entero en vez de solo las cuencas.

`anim.py` saca `_movimiento.png`: pinta encima del primer fotograma qué píxeles
cambian a lo largo del bucle. En `cr_brasa` se enciende el borde de la llama y el
centro se queda oscuro; en la calavera se enciende **todo, mandíbula incluida**.

**Se mira contra lo que pedía el prompt.** Si se ilumina algo que debía estar
quieto, la hoja se vuelve a generar. Es de la misma familia que el mosaico antes
de integrar: la comprobación que el ojo no hace solo.

### Una tira de animación no se corta en rejilla fija (ago-2026)

`procesar.py --tira N` parte la hoja entera en N columnas iguales, y eso da por
hecho que el generador centró cada fotograma en su columna. **No lo hace.**
Medido sobre la hoja de `cr_brasa`: las bases de las llamas caen a 15,6 / 9,1 /
7,2 / 6,8 / 4,1 / 0,1 / −4,0 / −9,3 px del centro de su celda — **24,9 px de
recorrido, 7,5 px a tamaño 64**. Un baile visible.

Ojo, que `--tira` sigue siendo mejor que el recorte por silueta, que saca cada
fotograma con la caja de su propio dibujo. El problema es que arregla la mitad.

Lo correcto está en **`anim.py`**: ventana vertical común anclada al suelo,
horizontal por el **centroide de la base** de cada fotograma (el 25 % inferior de
la tinta), y **una sola escala** sacada del fotograma más alto. Centrar por la
caja entera tampoco vale: se llevaría por delante el movimiento de las puntas,
que es justo lo que se ha pedido dibujar.

**Y una tira se comprueba contando cuánto cambia cada fotograma respecto al
siguiente.** Ocho copias con un píxel movido no dan error y no se ven hasta que
están en el juego. En `cr_brasa`: de 440 a 1.159 px de 4.096.

### El halo del fondo se vuelve VIOLETA ARCANO al cuantizar (ago-2026)

La hoja de `cr_brasa` salió con 61 px de arcano en una criatura de fuego, y
`CONTEXTO.md` reserva ese violeta para lo mágico y lo pide con cuentagotas.

No lo dibujó la IA: **el fondo magenta no acaba de golpe**. Deja un borde a 315°
de tono con el fondo a 299,8°, y `procesar.py` corta a 14°, así que el halo
sobrevive como dibujo y al cuantizar cae en el violeta.

**Ensanchar el margen de tono NO lo arregla:** de 14° a 28° el arcano baja de
5.585 px a 833 y se come 5.943 px de llama. El halo degrada hasta el rojo y no
hay corte limpio.

Lo que lo arregla: **sacar los dos violetas de la paleta al cuantizar** una hoja
que no lleva magia. El halo cae al rojo más cercano, que es lo que debe ser el
borde de una llama. `anim.py` lo hace por defecto; `--con-arcano` lo devuelve
para `cr_espectro` y `cr_sombra`.

*Y una hipótesis que se probó y era falsa, anotada para que no se vuelva a
intentar: sangrar el color del objeto sobre el fondo antes de reducir, por si
`Image.BOX` metía magenta en el borde al promediar RGB y alfa por separado.
Cambia **0 px** — el umbral de alfa a 128 tira esos píxeles antes de que
lleguen.*

### Lo que se dibuje ENCIMA de la bola no se ve: mide 18 px (ago-2026)

Lo destapó Fátima preguntando si en la ranura de los cascabeles cabía un peek. No
cabe —la ranura es de **48 × 6 px** sobre celda de 64— pero el motivo de fondo es
peor y vale para cualquier cosa que se plantee dibujar sobre la bola:

| Dato | Dónde | Valor |
|---|---|---|
| Radio de la bola | `sim/parametros_mesa.gd:12` | `radio_bola = 9.0` → **18 px** |
| Sprite y escala | `render/vista_mesa.gd:1340` | `bola.png` de 24, escala 0,9 |
| La ranura, a tamaño de mesa | factor 0,28 | **13,5 × 1,7 px** |

**A 18 px de una bola solo se lee el color y el patrón.** Se probó perforando la
ranura y componiendo ojos de colores debajo: a 8× queda bien y a tamaño real no
existe. Por eso `DISEÑO.md` §4 dejó de pedir dos capas en la mesa.

**La regla: antes de diseñar algo que se dibuja sobre la bola, escálalo a 18 px y
míralo.** No a 4×, ni a 8×: a 18. Es la misma disciplina que el mosaico antes de
integrar, aplicada al tamaño en vez de al contenido.

### Una palabra del inventario no describe el asset (ago-2026)

`INVENTARIO_HOJAS.md` apuntó la hoja de las nueve criaturas como **"criaturas
peek 3×3"**. Alguien leyó "peek" como *"dibujada sola, asomándose"* y lo escribió
en `prompts_animacion.md` §4: *"se generaron así, y por eso sirven como
referencia exacta"*. **Peek quiere decir asomándose POR ALGO, y ese algo está
pintado**: las nueve llevan un arco de piedra con su interior oscuro, y varias
tienen zarpas agarradas al borde.

Medido: **337 px (13,6 %) son idénticos en los nueve sprites y dibujan el anillo
exterior**, y borrarlos **no cambia la caja de tinta** (59×48 antes y después),
porque cada hoja sombreó su arco distinto. O sea que **no se quita con máscara y
`limpiar.py` no lo arregla: hay que regenerar**.

Lo que se llevaba por delante, y ninguna de las tres daba error:

- El prompt de §4 adjuntaba una de esas PNG como *"exact reference"* y a la vez
  ordenaba *"no bell, no circular outline of any kind around it"*. **La
  referencia contradecía a la orden**, y eso se paga con la hoja piloto.
- La combinatoria de 81 de `PROPÓSITO.md` §3: el arco es piedra gris, así que
  sobre `casc_hueso`, `casc_vidrio` o `casc_runas` sale un arco gris pegado a una
  campana que no lo es.
- *"La cáscara rueda, la criatura no"* (`DISEÑO.md` §4): al girar la cáscara, el
  arco pintado en la criatura se queda quieto y la costura se parte.

**La regla: antes de usar un asset como referencia de una tanda nueva, MÍRALO —
las nueve juntas y ampliadas—, no leas lo que el inventario dice que es.** Es la
misma familia que "un identificador no es un rótulo" y que "medir por la cara que
no es": la etiqueta era correcta y la lectura no. Y el mosaico de las nueve a 5×
lo canta en dos segundos, mientras que un PNG suelto en un visor no enseña que
todas comparten arco.

- **Rejilla de píxeles.** Nada se mueve, escala ni rota en fracciones de
  píxel: la cámara, la respiración y las rotaciones van en pasos enteros o
  la imagen hierve.
- **EL OBJETIVO DE LA CÁMARA TIENE QUE SER CONTINUO, Y ESO MANDA SOBRE TODO LO
  DEMÁS.** Un objetivo que salta no se puede suavizar sin perder la garantía: o
  llega a tiempo dando un corte, o va suave y se pierde el flipper. Por eso
  `tiempo_anticipacion` está en 0: el suelo garantizado dependía de `vy`, y `vy`
  salta entera en cada salida de rampa. Lo que se deja de pagar en predicción se
  paga en `margen_debajo_bola`, que depende solo de la posición. **Y lo que se
  nota no es el salto, es la ACELERACIÓN** — se midió el salto dos veces, se
  arregló dos veces, y hasta que no se midió la aceleración no se encontró.
- **Toda garantía dura de la cámara tiene que pasar por el tope de velocidad.**
  `CamaraMesa.avanzar` acaba con un `move_toward` desde donde estaba: eso es la
  REGLA 5 y va LA ÚLTIMA de todas a propósito. Escrita regla a regla, el
  suavizado y la garantía se suman y entre las dos se saltan el tope. Las
  garantías siguen mandando sobre el objetivo —eso no cambia—, pero llegan
  moviéndose. Sin esto, el suelo garantizado depende de `vy`, `vy` cambia de
  golpe en cada salida de rampa, y la cámara daba saltos de 113 px medidos.
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
- **Lo que se dibuje pegado al canto de la pantalla queda DETRÁS de la cáscara.**
  La mesa va en la capa 0 y el marco de su ventana en la 5, así que un aviso a
  10 px del borde superior no se ve: lo tapa la barra de título. Es la misma
  trampa que escondía la bola en lo alto de la órbita, y ya ha vuelto una vez
  (las flechas de bola fuera de plano). El margen bueno sale de
  `cam.alto_franja_hud`, que es lo que mide la cáscara de verdad.
- **`mesa.bola` NO es la bola que hay que mirar: es `bolas[0]`.** Existe porque
  con una sola bola es exactamente lo que era y así la multibola no obligó a
  reescribir la vista, el combate ni cuatrocientas pruebas. Pero con varias bolas
  en juego, la cámara quiere `bola_en_peligro()` y el que dibuja quiere `bolas`
  entera. Escribir `mesa.bola` en código nuevo que tenga que aguantar multibola
  no da ningún error: hace lo que no querías, y solo con dos bolas.
- **Todo estado que sea DE UNA BOLA vive en `Bola`, no en `Mesa`.** El
  temporizador del ball search y el "estoy dentro del girador" estaban en la
  mesa, y con dos bolas eso significa que la que estás jugando le reinicia el
  reloj a la que se ha quedado dormida en un rincón —que no se despierta nunca— y
  que la segunda bola que cruza un girador no cobra. Lo que sí es de la mesa se
  reinicia UNA vez por subpaso y antes del bucle de bolas: `flipper_atrapando` se
  reiniciaba dentro de `_colisionar`, y ahí mandaba la última bola de la lista,
  o sea que una bola volando por arriba le apagaba el aviso de atrape a la que
  estaba posada en la pala.
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
### Una señal que nadie escucha es un evento mudo, y no da error (ago-2026)

`bola_cayo` y `rampa_fallada` se construyeron con el sistema de capas, se
emitían perfectamente y **no las escuchaba nadie**. Cero errores, batería en
verde, y dos eventos de la mesa que para el jugador no existían: es la avería
del platillo con otra cara.

Y no eran dos: la prueba que se escribió para cerrarlo —leer las señales de
`sim/mesa.gd` y comprobar que `vista_mesa.gd` conecta todas— destapó una
tercera, **`flipper_golpeado`**, que sigue muda. Lo que suena al dar a la pala es
el solenoide al pulsar la tecla, así que fallar un tiro suena igual que clavarlo.

**La regla: una señal sin oyente se comprueba en la batería, no se recuerda.**
Vale igual para los assets — un wav generado y no enganchado es el mismo fallo—,
y las dos comprobaciones se escriben **leyendo el fichero**, nunca con una lista
a mano: una lista copiada se queda vieja en cuanto alguien añada una señal, y
entonces la prueba da falsos negativos y se acaba desactivando.

### Un número de tacto fuera del alcance de la mesa no es un número (ago-2026)

Fátima, jugando: *"no he sido capaz de quedarme a medias en ninguna rampa, hay
que revisar esas físicas"*. **Y la física no tenía nada que revisar.** El modelo
de energía de la cuesta está medido banda por banda en la batería, con sus dos
formas de fallar, tubo y carril, y las tres bandas de `PROPÓSITO.md` §6 salen
solas de la fórmula. Todo correcto.

Lo que estaba mal era el número. La bola engancha la subida por encima de 300
px/s y la mesa la limita a 1500, así que las entradas viven en `[300, 1500]`; la
frontera de "no llego" estaba en **384**. Una ventana de 84 px/s en un rango de
1200. Medido jugando: **3 fallos de 74 entradas, el 4 %** — y con la mediana de
entrada en 1500, que es el tope de la mesa, o sea que la mitad de los tiros
llegaban con cuatro veces la energía necesaria.

**La regla: un parámetro de tacto se mide contra lo que la mesa PRODUCE, no
contra sí mismo.** 640 es un número perfectamente razonable mirando la rampa; es
absurdo mirando el histograma de velocidades con las que se entra en ella. Y el
histograma cuesta una sonda de una tarde.

**Y el corolario, que es lo que hace la prueba escribible:** el rango de entrada
tiene dos extremos y los dos son fallos distintos. Por debajo del mínimo de
enganche, no se puede fallar. Por encima del tope de velocidad de la mesa, no se
puede coronar — con escape 2800 medimos **100 % de fallos**, o sea una rampa que
ya no es una rampa. La batería sujeta que la frontera cae entre los dos.

**Y hay una trampa dentro de la trampa: la distribución se REALIMENTA.** El
primer intento de barrer esto fue analítico —medir las velocidades de entrada una
vez con la cuesta apagada y aplicar la cuenta a cada valor de escape— y dio 35 %
de fallos donde jugando salían 2 %. La causa: con la cuesta apagada la bola
corona siempre, se queda en un bucle que vuelve a entrar a la misma velocidad y
ese bucle infla la muestra; con la cuesta puesta, el primer fallo lo rompe.
**Una bola que falla juega distinto**, así que un parámetro que cambia lo que
hace la bola se barre jugando, aunque cueste diez veces más.

### La cámara fija manda sobre las cuatro reglas, y hay que acordarse de soltarla (ago-2026)

Fátima: *"cuando estás en modo de caza, si ganas una reliquia, la cámara no te
lleva a la televisión, y no se ve lo que ganas"*. `objetivo_completo` deja que la
banda de la caza gane a todo —y tiene que hacerlo, o la planta alta se sale de
plano en cuanto la bola baja al embudo—, así que la ruleta pedía el ancla de
abajo y no la escuchaba nadie: **la tele giraba 643 px por debajo de lo que se
estaba viendo.**

**La regla: cualquier momento que necesite su propio encuadre suelta la banda al
entrar y la vuelve a poner al salir, y eso es de la VISTA, no de la cámara.** La
cámara no sabe si se está jugando; sabe encuadrar. Y "al salir" tiene su propio
caso: la ruleta congela la simulación, así que se sale de ella con la bola
todavía arriba y el reloj del bonus corriendo — dejarla suelta devolvería la
cámara a la bola justo cuando la caza sigue.

**Y su gemela, que es la misma avería por el otro lado:** el estado de la caza
vivía en la mesa y **no se cerraba al servir bola nueva**, así que pasarse la
pantalla dentro de la caza lo colaba entero en el combate siguiente. Medido:
**20,0 s jugando la planta baja con la cámara clavada arriba** — *"se juega pero
no se ve"*. Es la misma familia que *"los estados no cruzan de un combate a
otro"*: lo que es de la bola que se acabó no puede seguir puesto cuando entra la
siguiente. Y no basta con apagar el booleano — **hay que AVISAR**, porque quien
suelta la cámara es la señal.

### Una cadencia de animación se juzga contra la PANTALLA, no contra el reloj (ago-2026)

Dos cosas del reproductor de fotogramas que no dan ningún error y las dos se
ven como "la animación va rara":

1. **La cadencia tiene que dividir a 60 sin resto.** Con una que no divide, el
   reproductor gasta unos fotogramas en 3 ticks y otros en 4, y a ocho
   fotogramas de bucle eso se lee como un cojeo. Es la rejilla de píxeles, pero
   en el tiempo. 10 → 6 ticks, 20 → 3, 15 → 4, 12 → 5. Hay una prueba.
2. **Y el acumulador se RESTA, nunca se pone a cero.** Poner a cero pierde el
   sobrante de cada fotograma, y con delta de 60 Hz eso no se nota —la cadencia
   divide a 60 justo para eso—, así que **hay que medirlo en una pantalla que no
   sea de 60**: a 144 Hz un fotograma de 10 fps cuesta 14,4 ticks y poniendo a
   cero cuesta 15, o sea **96 fotogramas en diez segundos en vez de 100**. La
   animación un 4 % más lenta solo en las pantallas rápidas, y sin un error.

Y la tercera, que es de la misma familia que el resto de esta lista: **un estado
que la hoja no tiene no puede dejar el sprite en blanco.** Hoy ninguna criatura
trae `golpe`, así que `Reproductor` se cae a `idle` y guarda en `estado_pedido`
lo que se le pidió — la diferencia se ve en una prueba en vez de descubrirse
jugando con un bicho invisible.

### Un sonido descendente más no se distingue: mira la FORMA, no el tono

Al diseñar el sonido de caerse, la mesa ya tenía tres sonidos que bajan de tono
(`drenaje`, `platillo`, `rampa_salida`) y dos graves sucios (`ataque`,
`rampa_fuerte`). El primer candidato salió al **0,98 de parecido espectral** con
`rampa_fuerte`.

Lo que lo arregló no fue mover frecuencias: fue **la envolvente**. Los seis
sonidos viejos tienen el pico de energía en el primer instante —se APAGAN—;
una caída **termina en un golpe**, porque hay suelo. Con el impacto retrasado
130 ms, el pico cae en el tramo 5 de 10 y es el único del juego, con
`rampa_fallada`, que llega tarde. De ahí el parámetro `retardo` de `sonidos.py`.

**Y ojo con el método**: el 0,98 contra `rampa_fuerte` era un espejismo del
espectro medio, que promedia el tiempo — o sea justo lo único que los separaba.
Comparados en los primeros 100 ms, donde el oído decide, el parecido cae a 0,74
contra otro sonido distinto. **Una medida de timbre que ignora el tiempo no
sirve para decidir si dos sonidos se confunden.**

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
- **Un ternario deja el `Array` sin tipar, y eso falla EN EJECUCIÓN.**
  `bolsa.base = [casc] if casc != null else []` compila sin decir nada y revienta
  al correr con "Invalid assignment... value of type 'Array'": las dos ramas
  juntas no infieren `Array[Reliquia]`. El juego seguía corriendo **como si no
  existiera la capa de preparación**, que es lo peor: no se cae, solo deja de
  hacer una cosa. Para una propiedad tipada, la lista se construye a mano con su
  tipo declarado.
- **Una clave de COMBO no da identidad de tiro: el multiplicador paga todo.**
  Óxido decía empujar a los recorridos y llevaba `suma_golpes_por_recorrido`,
  que no es una recompensa de recorrido —es un empujón al MULTIPLICADOR que
  dispara un recorrido, y el multiplicador cobra en todo lo que golpees después,
  bumpers incluidos—. Medido: subía más al jugador de racimo (x1,36) que al de
  recorridos (x1,31), justo lo contrario de lo que prometía su texto. **Para dar
  identidad de tiro hay que usar `factor_dano_<tiro>`, que solo toca ese tiro.**
- **Comparar perfiles de jugador en crudo no mide nada: hay que dividir por el
  neutro.** Los tres perfiles del cruce de tiros hacen 265, 1551 y 1999 de daño
  por bola, porque los recorridos son el tiro difícil y pagan concentrado. En
  números crudos gana SIEMPRE la misma columna y la tabla no dice nada del
  cascabel. Lo que informa es cuánto sube cada uno sobre Acero **dentro de su
  propia columna**.
- **Más daño hace el juego MÁS FÁCIL, y esto ya no es una sospecha.** El coste de
  un combate es `tiempo/reloj × ataque + bolas × drenaje`, así que subir el daño
  acorta el combate y un combate corto come menos relojes. Medido en los
  cascabeles: Vidrio pega un 46 % más que Acero y **acaba el run con más vida**
  (80 % contra 71 %), aunque drenar le cueste dos veces y media. **Un efecto que
  suba el daño tiene que pagarse en RELOJ, no en drenaje ni en vida**, o lo que
  parece un riesgo es un descuento.
- **Un `O` mayúsculo comprimido es una `o` minúscula.** Las mayúsculas con tilde
  llevan el cuerpo a cinco filas para que quepa el acento, y con la `Á` cuela
  porque conserva el travesaño. La `O` no tiene ningún rasgo que sobreviva a la
  compresión, así que `Ó` y `ó` se leen igual. **Al comprimir un glifo hay que
  preguntarse qué rasgo lo hace reconocible**, no cuántas filas quedan.
- **Lo que se dibuja en una capa TAPADA sigue siendo pulsable.** La barra de
  tareas va en la capa 5 y el mapa (20) y TILT (40) se dibujan maximizados
  encima. En cuanto el botón Inicio hizo algo, pulsar donde el mapa no enseña
  nada abría el menú: **un clic que responde donde no hay nada dibujado**. No da
  error y no se ve en una captura, porque en la captura no hay nada raro. La
  regla: **toda región pulsable tiene que preguntar si lo que la dibuja se está
  viendo**, no solo si existe (`NodoSistema.disponible()`). Es la misma familia
  que el resto de esta lista: algo que responde donde no se ve.
- **Las regiones de clic se calculan AL PREGUNTAR, no al dibujar.** La tentación
  es que cada nodo apunte sus rectángulos dentro de `_draw` y que el ratón lea
  esa lista. Godot procesa el input ANTES del dibujo, así que el primer clic de
  cada fotograma contesta con la disposición del fotograma ANTERIOR: con menús
  que se abren y se cierran, eso es un clic que cae en un botón que ya no está.
  `RegionesClic` guarda funciones, no listas, y las llama al preguntar.
- **Un guardado se escribe a un temporal y se renombra encima, nunca directo.**
  Escribir sobre el bueno abre una ventana en la que un cierre a destiempo deja
  medio JSON en disco, y medio JSON es un guardado ilegible, o sea la partida
  entera. Y al leer, cualquier cosa que no cuadre —sin fichero, JSON roto,
  versión del futuro— tiene que dejar un guardado VACÍO Y VÁLIDO y decirlo
  (`Guardado.ilegible`): un juego que no arranca por el guardado es peor que uno
  que empieza de cero, y un progreso que desaparece sin explicación se
  diagnostica como "el juego no guarda".
- **`draw_string` no sabe rotar.** El parámetro que lo parece es la DIRECCIÓN del
  texto (`TextServer.Direction`), no un ángulo, y pasarle un float es un error de
  compilación que tumba el fichero entero. Para texto vertical, una letra por
  llamada hacia abajo: además queda en píxel entero, que girar una fuente de
  rejilla no lo deja.
- **Un icono se dibuja a un tamaño que DIVIDA al del PNG.** En la carpeta
  `RECUPERADO` los iconos van a 16, así que la fuente tiene que ser 32 (÷2) o 64
  (÷4). `assets/bolas/` mide 24 y ahí no vale: 24→16 es ×0,66 y el sprite
  hierve. Por eso las cáscaras se leen de `bolas_64/` aunque la mesa use
  `bolas/`.
- **Comprobar la función PURA no comprueba el estado que se VE.** La batería
  probaba `CamaraMesa.objetivo()` —las cuatro reglas, una por una, todas en
  verde— y nadie miraba dónde acaba `y_actual`, que es lo único que se dibuja.
  Debajo vivían dos averías a la vez y las dos las cazó Fátima jugando: la zona
  muerta estaba escrita como DESTINO en vez de como disparador, así que la
  cámara se quedaba parada a 45 px del ancla **para siempre** y los últimos
  45 px de mesa —los del drenaje— no se veían nunca; y la garantía dura
  prometía que la BOLA estuviera en pantalla, cosa que se cumple dejándola
  pegada al canto de abajo con nada debajo, así que **el 57 % de los fotogramas
  con la bola bajo la línea de seguridad no tenían la punta del flipper en
  plano**, y a 1900 px/s el borde se quedaba 456 px por encima de ella. **Una
  función pura dice lo que el sistema QUIERE; el estado dice lo que hace.** Si
  hay un `objetivo()` y un `avanzar()`, hay que probar los dos.
- **Un adelanto de cámara medido en píxeles miente a alta velocidad.** 110 px
  fijos son 366 ms a 300 px/s y 58 ms a 1900: la cámara enseñaba el sitio donde
  la bola ya estaba. El adelanto de una cosa que se mueve se mide en SEGUNDOS y
  se multiplica por la velocidad. Y el techo no lo pone el gusto, lo pone la
  ventana: con 540 px de alto, pasar de 0,18 s mete a la bola rápida detrás de
  la barra de título en la bajada.
- **Cuando dos garantías de encuadre no caben, hay que decidir cuál manda y
  escribirlo.** "La bola visible" y "los flippers visibles" no caben las dos en
  540 px con la bola a media mesa: son 540 px de separación y el marco se come
  40. Manda ver dónde CAE la bola —el orden de los recortes en `avanzar` es esa
  decisión, y por eso la garantía de abajo va después de la de arriba—, y la de
  arriba se conserva porque está medido que con estos números no llegan a
  pelearse: lo más arriba que sale la bola son 48 px de pantalla contra los 24
  que mide el marco.
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

- **Un lambda de GDScript captura las locales POR VALOR.** Una prueba contaba
  los críticos con `var criticos := 0` y un `connect(func(): criticos += 1)`:
  el `+= 1` sube la copia de dentro del lambda y el de fuera se queda a 0 para
  siempre. La prueba llevaba en rojo desde la Fase 4 **y el juego no tenía
  nada**: el daño que ella misma imprimía ya era 36 sobre un `dano_target` de
  18, o sea que el crítico salía y doblaba. Todos los demás contadores del
  fichero usan `[0]` porque un Array es referencia; ese era el único `int`
  suelto. **Un rojo que no se reproduce a mano es la prueba, no el juego.**
- **El `width` de `draw_string` RECORTA, y un ancho a ojo es una mentira que
  no da error.** La bandeja del reloj de la barra de tareas se dimensionaba con
  `tam(8) * letras * 0,6`, pero el avance real de la fuente son 6 px sobre una
  celda de 8, o sea 0,75. La caja salía 6 px corta, el `width` cortaba a lo
  ancho y **el reloj llevaba toda la Fase 5 marcando "14:5" sin el último
  dígito**. Nadie lo vio porque la hora cambia y el hueco parece diseño. Los
  anchos se miden con `get_string_size`, no se estiman. **Y no era uno:**
  la etiqueta "Dirección" del mapa tenía 32 px para 54 y llevaba toda la
  fase poniendo "Direc"; la pestaña de la barra de tareas cortaba el título
  de "(no responde)"; y el nombre bajo un icono de reliquia tenía 56 px, o
  sea nueve caracteres, así que **41 de las 45 reliquias salían cortadas**.
  Un `width` fijo con texto que viene de un JSON es siempre una bomba.
- **El halo de magenta de un recorte SOLO se ve dentro de Godot.** Los nueve
  iconos de escritorio, los tres cursores, los botones de la barra de título y
  el botón de Inicio tenían un fleco de píxeles magenta pegado al contorno —de
  (181,0,178) puro hasta mezclas oscurísimas— y en un visor no se distinguía
  del fondo. Lanzando el juego y ampliando la banda de iconos canta a la
  primera. **La causa de fondo: `ui/iconos` y `ui/cursor` NUNCA pasaron por
  `procesar.py`** —el 100 % de sus píxeles está fuera de la paleta de 33—, así
  que ningún paso de recorte les tocó el alfa. Si un asset de IA está fuera de
  paleta, es que no se proceso: mirar antes el halo que el color.
- **Fuera de paleta no siempre es un fallo.** Todo `ui/` está al 100 % fuera de
  los 33 colores y eso es a propósito en casi todo: los marcos de nueve trozos,
  la barra, el botón, el título, el tooltip, el diálogo y la barra de progreso
  los genera `fuente.py` con los grises de Windows, que son la identidad de la
  cáscara. Lo que sí era fallo es el arte de IA de esa misma carpeta. **El
  criterio no es la paleta, es quién generó el asset.**

- **Una tilde pegada a la letra no es una tilde: es un techo más grueso.** La
  `ñ` tenía la tilde en la fila 1 y la `n` desde la 2, sin hueco, así que las
  dos manchas se fundían y **la ñ se leía como una n**: "goblin_carroñero"
  salía "goblin_carronero". A 8 px eso solo se ve dentro del juego; en el atlas
  ampliado parece que está. La `Ñ` igual, y encima sin fila libre: hay que
  comprimir la N a cinco filas —conservando la diagonal, que es lo que la hace
  N— para ganar el hueco. Las minúsculas tienen dos filas arriba: **tilde en la
  0 y la 1 EN BLANCO**.
- **Una prueba que comprueba que algo EXISTE no comprueba que esté bien
  dibujado.** "la fuente sabe escribir acentos y eñes" estaba en verde todo el
  tiempo que la ñ fue ilegible, porque solo miraba que el glifo estuviera en el
  atlas. Para arte no hay prueba que valga: se mira.
- **`fuente.py` YA NO reproduce los marcos que hay en el repo, así que lanzarlo
  destruye la cáscara.** Medido: al regenerarlo, las nueve piezas de `ventana`,
  `titulo` y `barra` salen con TODOS los píxeles distintos, y `tooltip` sale de
  4×4 en vez de 8×8. Es decir, los marcos del repo los hizo una versión
  anterior del script o se tocaron después. **La fuente sí se puede regenerar**
  —el atlas sale idéntico salvo los glifos que cambies— pero hay que restaurar
  las cinco carpetas de marcos justo después:

      python3 fuente.py
      git checkout -- assets/ui/ventana assets/ui/titulo assets/ui/barra \
          assets/ui/boton assets/ui/tooltip

  Hasta que alguien decida cuál de los dos marcos es el bueno, esto es una
  trampa cargada: la tabla de "Herramientas del repo" invita a lanzarlo.

- **Un marco con agujero es UN marco sin centro, no cuatro marcos pegados.** El
  de la ventana de la mesa se montaba con cuatro nueve-trozos completos
  alrededor del hueco. Un nueve-trozos metido en una caja más estrecha que sus
  dos esquinas NO se encoge: `dibujar` recorta el grosor a la mitad de la caja,
  pero las esquinas se PEGAN a tamaño completo. En una tira de 8 px con
  esquinas de 8, las dos esquinas caen a 4 px una de otra, se solapan, y cada
  una **sobresale 4 px hacia dentro del campo**. Eso era el amasijo de
  tornillos de las cuatro puntas de la mesa, y de paso le comía píxeles al
  tablero por los cuatro lados. Ahora hay `NueveTrozos.dibujar_hueco`. **Regla
  general: un nueve-trozos en una caja menor que 2× su esquina va a salir mal,
  y no da ningún aviso.**
- **Un rótulo indexado por PREMIO miente en cuanto hay dos recorridos que pagan
  igual.** Los carteles de las bocas salían de un diccionario `premio → texto`, y
  eso funcionó mientras cada premio tenía un solo recorrido. La subida a la isla
  de la planta alta paga `DANO_FUERTE` igual que el cañón, así que su boca decía
  **"CANON DANO x2"** a media mesa del cañón de verdad. No da error, la batería
  no lo ve y en el código se lee perfectamente razonable. **Lo que se dibuja se
  indexa por NOMBRE**; el premio dice lo que paga, que es otra pregunta.
- **Un comentario que justifica un dibujo caduca cuando cambia lo dibujado.**
  `NodoSuelo` pintaba los 660 px de arriba en hueco oscuro con su razón escrita al
  lado: *"la zona alta es hueco de raíl, no mesa"*. Era verdad cuando arriba solo
  pasaba la órbita, y siguió pintándose igual cuando arriba hubo palas, isla y
  túneles: una mesa flotando en un pozo. **Cuando construyas donde antes no había
  nada, busca quién dibujaba ese "nada"** — el comentario correcto de ayer es la
  avería de hoy, y solo se ve mirando.
- **El orden de dibujo es la ALTURA, y con capas son tres, no dos.** Túneles
  (bajo el tablero), plataformas (terreno elevado) y rampas (vuelan). Con las
  plataformas antes que los túneles, el túnel que pasa por debajo de la isla se
  dibujaba encima de la losa y se leía como un puente: exactamente lo contrario
  de lo que es.
- **Un identificador no es un rótulo.** La rareza, el tiro de una misión y el
  eje de una reliquia se guardaban en una sola tabla que servía a la vez para
  leer el JSON y para PINTAR. Como la clave del JSON va sin tilde, la tele
  llevaba desde la Fase 4 escribiendo **"COMUN", "CANON" y "ORBITA"**, y el
  tooltip "GOLPE UNICO". Ahora hay dos tablas: `NOMBRE_*` es la clave —no se
  toca, rompería los datos— y `ROTULO_*` es lo que se lee. **Si una cadena se
  dibuja, no puede ser la misma que se parsea.**
  **Y ha vuelto a pasar dos veces en la tanda del sistema operativo**, así que
  no basta con saberlo: la ventana del registro se titulaba `log_arranque.log`
  —la clave del JSON— en vez de `arranque.log`, y la papelera escribía
  `goblin_carroniero.exe`, sin tilde porque las claves van sin tilde por fuerza,
  al lado de un mapa que pone `goblin_carroñero.dll`. **Cada vez que una clave
  llegue a un `draw_string`, hay que probarlo**: hay dos pruebas para estos dos.
- **Un error dentro del MENSAJE de una comprobación revienta la batería sin que
  ninguna prueba salga en rojo.** `prueba_sim.gd` construía un mensaje con
  `reliquia.nombre_rareza()`, que no existía en `Reliquia`; GDScript evalúa el
  argumento siempre, aunque la comprobación pase, así que abortaba el bloque
  entero. Se veían 312 pruebas donde hay 321: **nueve pruebas no se estaban
  ejecutando y el contador no lo decía.** Si el número total de pruebas cambia
  sin que hayas añadido ninguna, mira los `SCRIPT ERROR` antes que los FALLO.

- **NADA se descomprime dentro del repo, ni en una carpeta que se llame
  `_to_delete`.** Godot escanea el proyecto ENTERO: una copia de
  `render/nodo_cascara.gd` en cualquier subcarpeta le da "Class NodoCascara
  hides a global script class" y llena el editor de errores rojos que no tienen
  nada que ver con el código. Pasó al traer los parches de una sesión remota:
  el bridge del escritorio no puede borrar ficheros —`rm` da "Operation not
  permitted"—, así que lo que entra ahí se queda. El apaño, si ya está dentro,
  es un fichero vacío `.gdignore` en la carpeta: Godot se salta el directorio
  entero. Comprobado mirando `.godot/global_script_class_cache.cfg`. Pero el
  sitio de un fichero de paso es FUERA del repo, y si no hay fuera, se copia
  encima directamente sin descomprimir a un lado.

- **Un `relleno` de nueve trozos tiene que ser un tono PLANO.** El del cuadro de
  diálogo era una baldosa con borde propio, así que al repetirse dibujaba una
  rejilla de ladrillos por todo el cuadro. Solo salía cuando el enemigo ataca,
  que es el único momento en que ese marco aparece — y el peor para llenar la
  pantalla de ruido. Era el único marco de la cáscara recortado a mano de una
  hoja de IA; ahora lo genera `fuente.py` como los otros cinco. **El mosaico de
  prueba que ya está en estas trampas lo canta en dos segundos: montarlo para
  los nueve marcos ANTES de mirarlo dentro del juego.**
- **El `width` de `draw_string` recorta, y el tamaño de letra también es un
  ancho.** Los carteles del centro de la mesa se escribían a 16 px contra los
  400 de ancho: a 16 el avance son 12, o sea 33 caracteres, y "ESPACIO:
  mantener y soltar para lanzar" tiene 38. Salía "…para l". La salida no es
  acortar el texto —una pista que enseña menos vale menos— sino **bajar al
  tamaño que quepa**: `_tam_que_cabe` en `nodo_hud.gd`, que prueba por
  múltiplos de la celda. Todo texto de ancho variable que venga de un JSON
  (nombres de enemigo, de reliquia, de misión) tiene que pasar por ahí.

### EL BPM QUE PEDISTE EN EL PROMPT ES UNA HIPÓTESIS (ago-2026)

`prompts_musica.md` §2 pega a todos los prompts un bloque que dice `exactly NN
BPM`, y explica por qué es lo primero que hay que exigir: **sin tempo fijo no
hay rejilla de compases, y sin rejilla no hay dónde cortar**. Todo correcto. Lo
que no dice es que Suno lo obedece a medias.

Medidas las catorce tomas, **cinco de las siete piezas salieron a un tempo que
no es el que se pidió**. `caza` pedía 120 y las dos tomas dieron 83,4 y 80,7;
`recuperado` pedía 56 y su toma buena va a 136. Y como el compás sale del BPM,
cortar con el número del prompt es cortar FUERA de frontera de compás — o sea
exactamente el clic que el bloque L existía para evitar.

**La regla: el BPM de un prompt es lo que se pidió, no lo que hay.** Se mide
sobre el archivo antes de cortar nada, y lo medido manda. Es la misma familia
que "un parámetro de tacto se mide contra lo que la mesa PRODUCE": el número
escrito es la hipótesis y el material es el dato.

**Y el corolario, que es de dónde salió esto:** el detector confunde el pulso
con el medio pulso constantemente —`jefe` salió a 52,7 contra 108 pedidos, que
es la mitad justa— así que el doble y la mitad cuentan como el mismo tempo. Un
detector que no lo contemple marca como incumplidas piezas que están bien.

### Un bucle no se juzga oyéndolo: se juzga en el EMPALME (ago-2026)

La primera versión de `musica.py` puntuaba el corte comparando el espectro
medio del final con el del principio, y dio **de 0,94 a 0,99 en las catorce
tomas**: una medida que no separa nada. La causa está escrita en el propio
documento que la pedía — §2 pide piezas PLANAS, "cualquier trozo suena como
cualquier otro"—, así que el timbre medio es el mismo en toda la pieza y no
dice nada del corte.

Lo que distingue un bucle que cierra de uno que no es **dónde caen los golpes**,
y eso es tiempo. Midiendo la correlación de la envolvente de onsets entre lo que
viene DESPUÉS del final y lo que viene DESPUÉS del inicio, la misma tabla se
abre de **−0,15 a 0,91**. Es la avería de `sonidos.py` otra vez —"una medida de
timbre que ignora el tiempo no sirve para decidir si dos sonidos se confunden"—
y esta vez en la costura en vez de en el timbre.

**Y probado y descartado:** repartir el peso según la fuerza del pulso, para las
piezas ambientales donde la costura por golpes no mediría. La fuerza de pulso
sale de 0,645 a 0,897 en las catorce, o sea que no separa ambientales de
rítmicas: era un mando que no tocaba nada. La contradice además el dato que iba
a proteger — si en `escritorio` no hubiera nada que correlacionar, sus dos tomas
darían las dos cerca de cero, y dan +0,855 y −0,152.

**Lo que sí hace falta es el mosaico**, que aquí es de oído: `musica.py mosaico`
saca cada bucle repetido tres veces, porque el empalme solo existe cuando el
archivo vuelve a empezar. Es lo mismo que montar el mosaico 6×6 antes de copiar
una hoja de nueve trozos al repo.

### PEDIR "REPETITIVO" NO PIDE QUE LA SECCIÓN VUELVA (ago-2026)

*La causa de que ninguno de los ocho bucles acabe de convencer, y estuvo
escondida detrás de cuatro métricas en verde.*

`prompts_musica.md` §2 pega a todos los prompts un bloque L con `minimal
variation, repetitive ostinato, no build, no climax`. Suno lo obedeció — y aun
así **ninguna de las catorce tomas contiene un bucle**. Medida la
autocorrelación a distancia de bucle, o sea 20, 40, 60 y 80 segundos:

| toma | 20 s | 40 s | 60 s | 80 s |
|---|---|---|---|---|
| `combate_b` | −0,00 | +0,05 | −0,02 | −0,02 |
| `caza_a` | −0,18 | −0,07 | −0,00 | — |
| `mapa_a` | +0,04 | +0,01 | −0,03 | +0,01 |

Cero en todas. Y sin embargo **a escala de COMPÁS la repetición es altísima**:
el groove de `caza` se parece a sí mismo 0,80 cada 2,88 s. O sea que el bloque L
se cumple perfectamente con **un groove constante encima de música que avanza y
no vuelve nunca**. "Repetitivo" describe la textura; no dice nada de la forma.

De ahí sale la avería entera: **un corte largo empalma dos sitios distintos de
una pieza que avanza**. Por eso `caza` suena mal cortada teniendo sus cuatro
criterios en verde —costura 0,844, nivel 0,976, plana a 1,7 dB, armonía
0,991—: los cuatro miran ventanas de cuatro segundos, y a cuatro segundos el
groove SÍ es el mismo. Lo que no casa es la música, que a los treinta segundos
ya está en otro sitio.

**La regla: para que haya bucle hay que pedir la REPETICIÓN DE LA SECCIÓN, en
compases y con número.** El bloque R de §11 lo dice así — *"the exact same
8-bar phrase repeated identically at least eight times"*, más `no fills, no
turnarounds` (el relleno de batería al cerrar frase es la forma estándar de que
dos repeticiones no sean idénticas) y `the arrangement is frozen` (Suno mete y
saca capas por su cuenta).

**Y el corolario que vale para toda esta lista: una medida de empalme no puede
certificar un corte si el material no se repite.** Sirve para descartar los
malos y nada más. Cuando las cuatro métricas dicen que sí y la oreja dice que
no, lo que hay que poner en duda es si están midiendo la escala correcta —
aquí, cuatro segundos contra treinta.

### Concatenar OGG con `-c copy` no concatena nada (ago-2026)

El mosaico de audio —cada bucle repetido tres veces, para oír el empalme— se
montaba con `ffmpeg -f concat -c copy`. **Y los catorce salieron rotos:** sonaba
un ciclo y se quedaba pillado. Lo cazó Daniel oyéndolos.

Ogg no se concatena copiando. Lo que queda son tres bitstreams ENCADENADOS, cada
uno con su serial y sus tiempos empezando de cero, y el reproductor toca el
primero y para. La cabecera lo cantaba: `combate_b_x3` declaraba 102 s con 120 s
dentro. Se arregla reencodificando (`-c:a libvorbis`).

**Lo que lo hace peor que un bug normal: el fallo se disfraza de lo que la
herramienta iba a medir.** Un mosaico de bucles que se queda pillado se lee como
"el bucle no cierra", que es exactamente el juicio que se estaba pidiendo. Es de
la misma familia que el resto de esta lista —algo que no da error y miente sobre
otra cosa— y por eso ahora se comprueba: **un archivo de audio generado se mide
decodificándolo entero, no leyendo su cabecera**, porque la cabecera es justo lo
que sale mal.

### Un bucle no dura lo que dice el documento: dura lo que da la pieza (ago-2026)

`prompts_musica.md` §2 pedía ciclos de 20 a 40 s, y las ocho piezas se cortaron
así. Daniel las oyó: *"me parecen muy cortos"*. Subido el techo a 90 s, **la
medida le da la razón en unas y se la quita en otras**, que es lo que hace que
esto valga la pena escribirlo:

| pieza | 20-40 s | hasta 90 s |
|---|---|---|
| `recuperado` | 0,182 | **0,740** a 68 s — y CAMBIA DE TOMA |
| `jefe` | 0,686 | **0,795** a 62 s |
| `mapa` | **0,905** | 0,647 a 68 s |
| `combate` | **0,891** | nada mejor, y su toma dura 141 s |

O sea que **el largo bueno es una propiedad de la música, no un número del
documento**. `recuperado` es el caso que lo explica: su prompt pide frases
largas que no resuelven, así que a 34 s el corte caía a media frase y ninguna de
sus dos tomas cerraba; con sitio para una frase entera, la toma que se había
descartado por "no repetirse" pasa a ser la buena.

**Y el criterio que salió de ahí, que es lo reutilizable:** no se mete la
duración en la puntuación —sumar segundos y correlaciones obliga a inventarse
una escala entre cosas que no se parecen— sino que se elige **el corte más largo
de entre los que cierran casi tan bien como el mejor**. Las piezas que no dan
más de sí se quedan cortas ellas solas, sin escribirlo en ningún sitio.

**Ojo con filtrar por un solo criterio:** la primera versión de esa regla miraba
solo la costura y eligió para `caza` y `tienda` cortes con **12 dB de salto de
volumen** en el empalme. Un bucle que casa de golpes y da un bajonazo en cada
vuelta es peor que un clic. Cuando un criterio compuesto se sustituye por uno
simple, hay que volver a mirar qué se quedó fuera.

### Una regla sacada de UNA rampa no vale para las nueve (ago-2026)

La tanda 0j dejó en la batería la comprobación de que la cuesta está calibrada:
*la frontera de "no llego" tiene que caer por encima de `velocidad_minima * 1,4`*.
El 1,4 salía de una medida buena —con la frontera en 384 contra un enganche de
300, la subida a la isla no se podía fallar— y **como regla general es falsa**:
da por hecho que las entradas se reparten por igual entre el enganche mínimo y el
tope de la mesa.

No se reparten así en ninguna rampa. En la órbita, que engancha a 500, la mitad
de las entradas cae entre 505 y 613 y la otra mitad se estira hasta 1169. La
regla pedía una frontera por encima de 700: en esa población es fallar dos de
cada tres, o sea lo contrario de lo que la regla creía estar protegiendo.

Al encender la cuesta en las cinco rampas, la regla tumbó cuatro pruebas de
valores que estaban MEDIDOS y bien. Lo que la sustituye es la medida:
`tests/sonda_rampas.gd` saca la banda de entrada real de cada boca y la prueba
comprueba que la frontera caiga dentro. **Una constante derivada de un caso se
escribe con el caso al lado, o el día que haya un segundo caso miente.**

### La cuesta cambió la mesa de abajo el DOBLE de lo que parecía (ago-2026)

Encender la cuesta en la órbita, el cañón y el retorno subió la duración de bola
del maniquí de **8,142 s a 17,874 s** y la huella de 16621 a 23569. Parece un
bucle nuevo y no lo es: **el maniquí ya se pasaba el 73 % de la bola dentro de la
órbita** (180 entradas en 60 bolas, sin cuesta). Lo que cambió no es cuántas
veces entra, es DÓNDE le deja la bola — la órbita completa la escupía por la boca
contraria, que baja al drenaje, y una fallada la devuelve a la boca por la que
entró, o sea a la pala. La cuesta no alargó la bola metiendo un bucle: le quitó a
la órbita el ser un billete rápido al desagüe.

Vale la pena por lo que enseña de cómo mirar una medida: **un número que se
duplica no dice qué ha cambiado.** Partirlo (cuesta sola / cuesta + descarga) y
contar entradas y tiempo-dentro-de-rampa costó una sonda de diez líneas y evitó
buscar un bucle que no existía.

### EL GENERADOR NO DIBUJA EN REJILLA: lo que hace de rejilla es la REDUCCIÓN (ago-2026)

*Una tarde entera, diez tandas de `cr_brasa`, y ninguna superó a la tercera. Lo
cazó Daniel mirando: «ni siquiera son píxeles de verdad, miden tamaños
diferentes». Medido después, tenía razón y era peor de lo que parecía.*

Contando los tramos de color constante de cada hoja:

| Hoja | Longitud de los tramos |
|---|---|
| Arte del repo, ampliado ×4 | 4 px 40 %, 8 px 21 %, 12 px 14 % — **todos múltiplos de 4** |
| Cualquier hoja del generador | **1 px: del 67 % al 76 %** |

O sea que **ninguna hoja de IA es pixelart**: son ilustraciones de alta
resolución con aspecto de pixelart, con detalle a nivel de píxel suelto. Las
líneas de prompt tipo *"make the pixel blocks visibly large and perfectly
square"* se ignoran las diez veces, así que no sirve de nada insistir.

**Lo que convierte eso en pixelart es el paso a 64, y por tanto el factor manda
sobre todo lo demás:**

| Formato | Celda | Factor a 64 | Resultado |
|---|---|---|---|
| Tira de 8 en una hoja de 2172 | 272 px | **×4** | bloques limpios |
| Un fotograma por imagen de 1254 | 1254 px | **×20** | promedia 400 px por bloque: papilla |

**El parámetro de pixelart es el TAMAÑO DE CELDA, no el del bicho.** Una tira de
ocho lo deja en ×4 sin pedírselo; un fotograma suelto lo dispara a ×20 y no hay
prompt que lo salve. Y ojo con la trampa dentro de la trampa: pedir *"dibújalo
grande, que llene la celda"* arregla el contorno roto **y destruye la rejilla**
— se hizo por escrito en la tanda 0k y costó dos tandas enteras.

**Y probado y descartado como parche:** reducir por MODA (el color que manda en
cada bloque) en vez de promediando. Da bordes más duros y mete sal dentro del
cuerpo. La reducción no es el sitio donde arreglar esto.

**El corolario, y es de Daniel viendo los dos bucles a la vez:** *"el de la
izquierda es más complejo, pero se ve peor que el de la derecha, que es más
sencillo pero pulido"*. **A 64 px la complejidad no es riqueza, es ruido.** Entre
una hoja con más detalle y una con menos tonos y la silueta cuajada, gana la
segunda siempre.

*Y la nota que ahorra la tarde entera: si una tanda no supera a lo que ya está en
el repo, no entra. Diez tandas después, `cr_calavera` sigue siendo la de hace
meses — que gana porque pasó por `--pulir 3`, el paso que su propia ayuda
recomienda para bichos de superficie plana y que esta vez me salté.*

### La cura de una criatura es la avería de la otra (ago-2026)

`anim.py` saca los violetas de la paleta al cuantizar para que el halo del fondo
magenta caiga al ROJO, que es lo que debe ser el borde de una llama. En una
criatura de HUESO ese mismo halo cae al rojo y deja **un punto de sangre entre el
cráneo y la mano** — 25 px, y Daniel lo vio a la primera.

Y no es sal: viene en grupos de 3 y 4 px, así que tienen vecinos de su color y un
filtro de píxeles sueltos no los toca (medido: de 25 baja a 24). Lo que lo
arregla es la paleta, con `--fuera 8C2E2E,C74A3C`: quitando los rojos, el halo
cae al tono de hueso más cercano. **De 25 px a 0.**

**La regla: un arreglo de color escrito para una criatura hay que volver a
juzgarlo en la siguiente.** El mecanismo de `--con-arcano` ya lo decía a medias;
ahora es general.

*(Y de la misma tanda, dos arreglos más de `anim.py`, cada uno de un fallo real:
**el recorte por tramo**, porque la ventana cuadrada se calcula con el ALTO y en
un bicho más alto que ancha su celda se trae un trozo del fotograma vecino —
salía como barritas flotando a los lados—; y **`--contorno`**, que pinta todo el
perímetro con el tono más oscuro del sprite, porque al generador se le olvida
entre el 29 % y el 45 % del borde.)*

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
- **Prueban y juzgan LOS DOS, Daniel y Fátima.** El apartado "Que pruebe Daniel"
  de `ESTADO.md` se llama así por costumbre, no porque el juicio sea de uno
  solo: las preguntas de tacto, de arte y de si algo se lee van a los dos, y
  cualquiera de los dos puede cerrar una. **Y está demostrado que hace falta:**
  los textos cortados de la cáscara y las dos averías de la cámara —45 px de
  mesa sin verse nunca y el 57 % de fotogramas sin flipper en plano— los cazó
  Fátima jugando, encima de una batería en verde. Al escribir una pregunta, di
  a quién le toca **solo si de verdad le toca a uno** (el tacto de la pala es de
  quien juega más), y si vale cualquiera de los dos, no pongas nombre.
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
