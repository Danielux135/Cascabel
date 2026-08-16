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

## Godot

No está en el PATH. El ejecutable de consola (el que devuelve la salida) es:

`C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe`

Batería de pruebas, sin abrir ventana:

    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/prueba_sim.gd

Medidas (no son pruebas: no fallan, imprimen tablas):

    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/medir_balance.gd
    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/medir_reliquias.gd

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

## Herramientas del repo

Se generan, no se dibujan ni se editan a mano:

| Script | Qué hace |
|---|---|
| `python3 fuente.py` | la fuente pixelart y los cinco marcos de nueve trozos — **OJO: los marcos que saca hoy NO son los del repo**, ver Trampas |
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
- **Los pines NO empujan, y la bóveda se recorta sola.** El campo de pines se
  genera desde `pin_paso` y `pin_alto_fila`, y `_cabe_pin` tira todo pin que no
  deje aire contra lo que ya hay. Dos invariantes, y los dos los vigila la
  batería: por todos los huecos tiene que caber la bola, y ningún pin puede tapar
  una boca de recorrido ni el platillo. Un pin que empujara sería un bumper
  pequeño y la bola se quedaría a vivir arriba.
- **LA MESA TIENE DOS PISOS, y no se comunican por gravedad.** Encima del arco
  está la arena de caza (`DISEÑO.md` §5 y §7): su propio techo, sus paredes y su
  propio suelo, con 12 px de nada entre el fondo de su embudo y el arco de abajo.
  Se sube por el **umbral** y se baja por el **regreso**, y las dos son curvas.
  Los dos números que lo cierran: la bola sube 643 px por sus medios —desde las
  palas, hasta y=557— así que a la arena no llega sola; y una caída libre desde
  ahí arriba llega a las palas a **1500 px/s, o sea 67 ms**, cuando el cañón ya
  se tuvo que ablandar porque 900 px/s era incazable. Abrir el arco y dejar caer
  la bola es regalar ese tiro en cada visita.
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
- **Un modificador NO es una mecánica.** Los nueve cascabeles se montaron como
  bolsa de modificadores —reutilizando el sistema de reliquias— y salieron
  medidos, equilibrados y **completamente invisibles**: un ×1,19 al daño no se ve
  jugando. **Una bolsa de modificadores solo sabe producir porcentajes; para que
  pasen cosas hacen falta EVENTOS** (`sim/estados.gd`). Cuando algo "no se nota"
  y los números dicen que está bien, mira la forma antes que el número.
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
