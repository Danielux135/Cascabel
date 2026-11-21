# WEB.md — CASCABEL EN EL NAVEGADOR

**Estado (19-oct-2026): PUBLICADO en https://danielux.es/Cascabel/.** Los
arreglos están hechos, la batería da 647/647 (también en Linux, en el CI) y el
build se ha jugado en un navegador. Falta medir el rendimiento con el navegador
a la vista y OÍRLO.

**Y desde el 13-nov hay una segunda página, https://danielux.es/cascabel-3d/**,
con las pruebas 3D de la rama `prueba-3d`: ÓRBITA y, desde el 21-nov, CRIPTA
(`?mesa=cripta`). No es el juego y no comparte nada con esta publicación: tienen
sus secciones al final.

## Cómo se publica

Pestaña **Actions** del repo → **"Publicar en la web"** → **Run workflow**.
Lo hace `.github/workflows/web.yml`, y se lanza A MANO a propósito: publicar es
una decisión, y con cada push lo que se juega en el enlace sería lo último que
se haya tocado. El workflow:

1. baja Godot 4.7.2 y sus plantillas web, comprobando el SHA512 (la primera vez;
   luego tira de caché);
2. importa y **pasa la batería**: con un fallo, o con un `SCRIPT ERROR`, que no
   sube el contador de fallos, **no publica**;
3. exporta en release y lo sube a GitHub Pages. Tarda unos minutos.

Sale en `danielux.es` porque `Danielux135.github.io` tiene ese dominio, y los
sitios de proyecto lo heredan con el nombre del repo detrás. **Pages no tiene
contraseña**: lo ve quien tenga el enlace.

**Comprobado que lo publicado es lo probado.** El `.wasm`, el `.js` y el
`index.html` publicados son idénticos byte a byte a los del build local, y del
`.pck` lo son los 832 ficheros salvo dos cachés del motor
(`global_script_class_cache.cfg` y `uid_cache.bin`), que tienen el mismo
contenido en otro orden: el del escaneo del disco de Linux. Ojo si se repite la
comprobación: comparar los dos `.pck` byte a byte da 357.000 bytes distintos y
engaña, porque Linux los guarda en otro orden; hay que comparar fichero a
fichero por su ruta.

Cómo funciona: Godot compila su motor (C++) a WebAssembly, y el juego va al
lado en un `.pck`. El navegador descarga los dos y los ejecuta. No hay que
reescribir nada, porque Cascabel ya cumplía lo difícil: renderizador
`gl_compatibility` (WebGL2), ni un hilo, todo el arte y el audio cargado con
`ResourceLoader.exists()` + `load()`, y los siete JSON dentro del `.pck`.

## Cómo se saca el build

    & "C:\Users\oscar\Desktop\Daniel\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path C:\Users\oscar\Desktop\Daniel\Cascabel --export-release "Web" <carpeta FUERA del repo>\index.html
    python -m http.server 8060 --directory <esa carpeta>

- **Siempre `--export-release`.** En un build de depuración vuelven F1, F2 y F3,
  y el diálogo de exportación del editor trae "Export With Debug" marcado por
  defecto.
- **Fuera del repo**, como todo lo de paso: Godot escanea el proyecto entero.
- Las plantillas son solo las web, en
  `%APPDATA%\Godot\export_templates\4.7.2.stable`. Salieron del `.tpz` oficial
  de las releases de Godot (1,22 GB, con el SHA512 comprobado), y el resto se
  borró.
- Abrir `index.html` con doble clic no funciona: hace falta un servidor, aunque
  sea el de Python. Sin hilos no hace falta ninguna cabecera especial.
- **Medido: `index.wasm` 39,5 MB, `index.pck` 6,78 MB, unos 46 MB en total.** Se
  exporta en 10 s.

El preset (`export_presets.cfg`): Web, **sin hilos**, **"Export all
resources"** —nunca "escenas seleccionadas": ningún PNG, WAV, OGG ni JSON es
dependencia de `mesa.tscn`, todo se carga por ruta y el juego saldría vacío— y
cuatro exclusiones: `*ChatGPT*`, `assets/sonido_pruebas/*`, `assets/_pruebas/*`
y `tests/*`. Las ocho hojas "ChatGPT Image …" son 8,6 MB que no carga nadie, y
**sus nombres llevan coma, que es el separador de la lista de filtros**: se
excluyen con el comodín. Comprobado dentro del `.pck`: no queda ni rastro de
ninguna de las cuatro, y están los JSON, la música, la fuente y el nodo nuevo.

## Lo que se arregló

| Qué | Dónde | Lo sujeta |
|---|---|---|
| **Esc y "Apagar..." congelaban la página.** `quit()` en web apaga el motor y deja el lienzo muerto con el último fotograma. Ahora todo sale por `VistaMesa.salir()`: en web Esc abre el menú de Inicio y "Apagar..." apaga la máquina | `vista_mesa.gd`, `nodo_sistema.gd` | cinco pruebas: un solo `quit` en todo el juego (buscado ancho), la forma de `salir()`, y que Esc y Apagar pasen por él |
| **La máquina arranca apagada en web.** El arranque sonaba contra un audio bloqueado y bloqueaba al mapa; el teclado no llegaba hasta el primer clic. Ahora la primera tecla o el primer clic la encienden y lanzan el arranque | `nodo_encendido.gd` (nuevo, capa 50) | arranca apagada, se enciende una vez, ni la rueda ni Esc la encienden |
| **Apagar y volver a encender** empieza un run nuevo, como un equipo de verdad, con *"Ya puede apagar el equipo."* | `nodo_encendido.gd`, `VistaMesa._al_encender` | encender tras apagar da run nuevo |
| **La música en Stream.** En Sample el bucle lo rehace JavaScript, con hueco en cada empalme, y el primer `play()` decodifica la pieza entera | `nodo_musica.gd` | las dos voces en Stream |
| **F1 solo en un build de depuración** (y con él F2 y F3) | `vista_mesa.gd` | regex sobre `KEY_F1` |
| **Pausa al perder el foco**, con la física, la ruleta y la cuenta atrás de la victoria paradas | `nodo_encendido.gd`, `vista_mesa.gd` | pausa con el aviso, red de seguridad, y que la mesa lo escuche |
| **Aviso si el navegador no guarda**, en la máquina apagada y en "Mi máquina" | `nodo_encendido.gd`, `nodo_sistema.gd` | — (solo existe en web) |
| **Un run nuevo suelta la banda de la cámara.** Tirar la mesa en plena caza la dejaba clavada arriba en el run siguiente. **Pasaba también en escritorio con R** | `VistaMesa._nuevo_run` | regex |
| **`NodoMusica.callar()`**: apagar corta también un arranque o un TILT a medias | `nodo_musica.gd` | callar y volver a poner |
| **El puntero dibujado deja de verse al sacar el ratón de la ventana**, en vez de quedarse congelado en el borde. Es el único cambio que se nota también en escritorio | `nodo_cursor.gd` | — |

Todo lo que es solo de web va detrás de `OS.has_feature("web")`, y
`NodoEncendido` no hace nada en escritorio. Una revisión adversarial lo
comprobó camino por camino. Las pruebas se pasaron por **cinco mutaciones**:
se rompe a propósito lo que dicen sujetar y tienen que ponerse en rojo.

### La trampa que solo salió en el navegador

**En web, `Window.has_focus()` dice siempre que sí**:
`DisplayServerWeb::window_is_focused` devuelve `true` a pelo en la 4.7.2. La
primera pausa preguntaba eso cada fotograma, la batería decía que estaba bien y
en el navegador la pausa no salía nunca. Lo que sí llega es el `blur` del lienzo,
convertido en `NOTIFICATION_WM_WINDOW_FOCUS_OUT`, y de eso vive la pausa. Para
que un aviso perdido no la deje puesta para siempre, cualquier tecla o clic que
llegue la quita. Está también en `CLAUDE.md`.

## Mirado en el navegador

En el Chromium del panel de Claude, lienzo de 1024×768 a escala 1,25, o sea
1280×960 píxeles reales:

- Arranca apagada; un clic la enciende; el mapa sale con sus enemigos, así que
  los JSON entraron.
- **Acentos y eñes** ("aquí", "carroñero", "ÓRBITA") y **giradores dibujados**.
  Era el riesgo que ninguna prueba cubría: los dos leen su textura de vuelta
  con `get_image()`, en el editor desde una copia en CPU y exportado desde la
  GPU. Funciona.
- Esc en el mapa no hace nada; Esc en combate abre el menú de Inicio; F1 no
  enciende la depuración.
- "Apagar..." lleva a *"Ya puede apagar el equipo."*, y una tecla, a un run
  nuevo con otro mapa.
- Quitarle el foco al lienzo pone *EN PAUSA*; un clic lo quita.
- Con 1280×960 el juego sale a ×1 con barras negras, como predijo la
  auditoría.

## Lo que falta

1. **Medir el rendimiento con el navegador a la vista.** Con el panel oculto el
   navegador estrangula la pestaña a 1 fotograma por segundo y la medida no
   vale. **Ya no hace falta tenerlo a la vista:** midiendo la prueba 3D salió
   una forma de hacerlo con un Chrome sin ventana (ver "Cómo se miró sin tener
   el panel a la vista", al final). Con el juego sigue sin hacer.
2. **Oírlo**, que no se puede deducir. El arranque tiene que sonar con el primer
   clic, y los bucles tienen que empalmar sin hueco. Y ojo: **en la plantilla
   sin hilos, Stream mezcla en el hilo principal**. Un fotograma de más de ~40 ms
   deja sin datos al reproductor y la música corta. Si corta al cambiar de
   pantalla o en multibola, subir `audio/driver/output_latency.web`.
3. **Mirar el publicado con los ojos**: que arranca apagado, que un clic lo
   enciende y que el mapa tiene enemigos. Lo que se comprobó al publicar fue que
   el motor arranca (la consola lo dice) y que los ficheros son los probados,
   porque con el panel del navegador oculto no hay fotogramas que mirar.
4. Si algún día hace falta que sea **privado**, itch.io (Draft, o Restricted
   con contraseña; HTML, 960×540, botón de pantalla completa, sin "Mobile
   friendly"). Cloudflare Pages no vale: 25 MiB por fichero, y el `.wasm` pasa.

## Pantalla

- Con escala entera y `expand`, un lienzo que no sea múltiplo exacto de 960×540
  sale a ×1 con barras negras. No rompe nada: la cáscara se maqueta desde
  `get_viewport_rect()`.
- **Un lienzo MENOR que 960×540 recorta por la derecha y por abajo, y se pierden
  las palas.** Pasa con un embed pequeño o con el zoom del navegador por debajo
  del 100 %. Remedio sin código: jugar en pantalla completa, que en 1080p da ×2
  exacto. Pasar a escala fraccional cuando no cabe tocaría el invariante
  *"escalado por enteros siempre"*: **eso lo deciden Daniel o Fátima.**
- `window/size/mode=3` y el override de 1920×1080 no se aplican en web.
  Inofensivo.

## Móvil: no

Solo teclado (`Input.is_physical_key_pressed`), sin ningún control táctil. En
itch, no marcar "Mobile friendly". Un control táctil sería diseño, no un
arreglo.

## Rendimiento: lo medido en nativo

i5-10300H, binario del editor con depuración, headless y con la máquina cargada:
orientativo.

| | tick de física, media | fotograma (`_process` + `_draw`), p50 |
|---|---|---|
| 1 bola | 0,37-0,85 ms | 2,0-2,3 ms |
| 3 bolas | 0,96-1,2 ms (p95 1,9-2,5) | 2,4-3,7 ms |
| 4 bolas (tope) | 1,3-2,2 ms | — |

A 60 fps hay 16,7 ms para dos ticks de 120 Hz y un fotograma. GDScript en
WebAssembly va entre 1,5 y 3 veces más lento (estimación, Jangda et al., USENIX
ATC 2019), y en la plantilla sin hilos todo va en el hilo principal del
navegador: **5-12 ms con una bola, cabe en un portátil**. La multibola de 3-4
bolas va justa en uno flojo.

Si el build va lento, hay dos puntos calientes, **solo después de medirlo**, y
ninguno toca un invariante:

- **La colisión es por fuerza bruta** (`sim/mesa.gd`, el bucle de
  `_colisionar`): cada bola prueba los 136 colisionadores en cada subpaso, 480
  veces por segundo. Una rejilla estática lo deja en 5-15 candidatos. **Tiene que
  conservar el orden original de los candidatos**, porque `sort_custom` no es
  estable: la huella de `tests/medir_capas.gd` tiene que salir idéntica.
- **`VistaMesa._draw` redibuja en cada fotograma toda la geometría fija**: unas
  261 llamadas `draw_*`, 1,3-1,4 ms. Se arregla con una capa estática.

## Conviene saberlo, aunque no sea de la web

- El guardado "atómico" (`guardado.gd`) **borra el bueno antes de renombrar el
  temporal**, y `cargar()` no recupera un `.tmp` huérfano: un corte justo en ese
  hueco pierde el guardado.
- Shift es la pala izquierda: cinco pulsaciones seguidas abren el diálogo de
  Teclas especiales de Windows, también dentro del navegador.
- La ayuda pone "A / D", pero las palas leen la tecla FÍSICA: en AZERTY la pala
  izquierda es la tecla que pone Q.
- La rama de reserva de `FuenteUI` (`Image.load_from_file`) no puede funcionar
  en un export. Hoy no se usa.

## LA PRUEBA 3D EN LA WEB (13-nov)

**Publicada en https://danielux.es/cascabel-3d/.** Es la escena de prueba de la
rama `prueba-3d` (`prueba3d/`, ver `ESTADO.md`), no el juego. La página del
juego y su workflow no se han tocado.

### Cómo se publica

En Pages, la ruta de un sitio de proyecto ES el nombre del repo, así que para
esa dirección hace falta un repo que se llame así: **`Danielux135/cascabel-3d`,
que no guarda ni código ni build, solo `.github/workflows/publicar.yml`**. Ese
workflow baja la rama `prueba-3d` de Cascabel, importa, **pasa la batería**,
arranca la escena 3D sin ventana seiscientos fotogramas —la batería no la
cubre—, exporta con el preset **"Web 3D"** y lo sube a Pages de su propio repo.

- **Para actualizarla:** push a `prueba-3d` y, en `cascabel-3d`, Actions →
  "Publicar la prueba 3D" → Run workflow. Unos tres minutos.
- **Para deshacerla:** borrar el repo `cascabel-3d`. No queda nada más.
- Tras publicar, **Pages sirve lo anterior hasta diez minutos**
  (`Cache-Control: max-age=600`). Un navegador que ya había entrado enseña la
  versión vieja y parece que no se ha publicado.

El preset "Web 3D" es el del juego con dos diferencias: excluye además la
música y las sondas, y lleva `custom_features="prueba3d"`. Con esa etiqueta
manda la línea `run/main_scene.prueba3d` de `project.godot`, y por eso ese
build arranca en la escena 3D y el del juego no. El `.pck` mide 1,6 MB; el
motor son los mismos 39,5 MB. En local se saca igual que el del juego:

    & "<Godot console>" --headless --path <repo> --export-release "Web 3D" <carpeta FUERA del repo>\index.html

### Lo que hubo que cambiar para el navegador

- **Arranca jugando sola**, con el piloto, hasta el primer clic o la primera
  tecla: hasta entonces el navegador no da ni teclado ni sonido. Con un dedo no
  se puede jugar —no hay palas que tocar—, así que en un móvil sigue sola y lo
  dice.
- **Ni Ctrl ni Mayús son palas en web**: con otra tecla son atajos del navegador
  (Ctrl+W cierra la pestaña y no se puede impedir).
- **El marcador escala fraccional.** El proyecto escala por enteros, y en una
  pestaña casi nunca caben dos veces 960×540: se quedaba a ×1, diminuto. La
  escena lo cambia para sí misma al arrancar; el juego sigue por enteros.
- **La letra es la de reserva de Godot** (Open Sans): en web no hay fuentes del
  sistema. Comprobado carácter a carácter que trae las tildes que se escriben.

### EL NAVEGADOR DIBUJA CON LA GRÁFICA INTEGRADA

**En el portátil de oscar hay una GTX 1650 y los navegadores no la usan**: tanto
el panel de Claude como Chrome dibujan con la Intel UHD. En escritorio Godot
pide la buena y la prueba va a 130-144 fotogramas por segundo; en el navegador,
tal como estaba, a **21**. Se pregunta desde la página con
`WEBGL_debug_renderer_info`; el motor no lo sabe, WebGL se lo esconde.

Lo que se midió y lo que se hizo con cada cosa (Intel UHD, ventana de 1902×984,
Chrome sin tope de fotogramas):

| Qué | Medido | Arreglo |
|---|---|---|
| **El cielo** | quince capas de ruido por píxel y por fotograma: 3,9 ms de 15 | la nebulosa se pinta UNA vez en una textura (`nebulosa.gdshader`) y el cielo solo la lee |
| **Cada llamada de dibujo** | unas 30 µs de hilo principal; el reflejo repetía 133 | el reflejo no dibuja lo que está a ras de cristal ni, en las cámaras de juego, patas y ojos |
| **El suavizado de bordes** | 7 ms a 1080p con 4 muestras | solo en la calidad ALTA |
| **Las sombras** | 3,4 ms, y sobre un cristal oscuro casi no se ven | fuera de MEDIA y de BAJA |
| El tamaño del mapa de sombras | de 4096 a 1024, nada | mando descartado |

Con eso: **ALTA de 21 a unos 35, MEDIA de 34 a 60-78, BAJA de 57 a unos 85.**
Arranca en MEDIA, que a 1080p es el 75 % de la resolución, con reflejo y sin
sombras.

**La calidad va con un tope de MEGAPÍXELES, no con una fracción de la ventana**:
con una fracción, una pantalla 4K le pediría cuatro veces más píxeles a la misma
gráfica. Y la lleva un vigilante que baja un nivel si no se llega a 47
fotogramas por segundo y prueba a subir si va sobrada. **Bajar no es para
siempre**: la primera versión no volvía a probar el nivel que había fallado, y
bastaba pasar por la cámara de CRIATURA, que carga más, para quedarse en BAJA el
resto de la partida. Ahora cada subida que falla hace esperar el doble a la
siguiente. La G la cambia a mano, y con `?calidad=alta` (o `media`, `baja`) en
la dirección se fuerza.

**La primera visita va lenta, y no es un fallo.** Son los mismos 39,5 MB de
motor que el juego: entre 35 y 45 s hasta arrancar en frío, y el primer minuto
el navegador todavía está optimizando el motor, así que va a 45-50 y el
vigilante la baja a BAJA; luego vuelve sola a MEDIA. Las siguientes visitas
arrancan en 3-4 s. Comprobado en la página publicada.

### Cómo se miró sin tener el panel a la vista

El panel del navegador de Claude estaba oculto, y oculto no dibuja: las capturas
no salen y la página va a 1,5 fotogramas por segundo. Lo que funcionó fue **un
Chrome sin ventana, con perfil propio y puerto de depuración**, conducido desde
Node, que ya trae `WebSocket` y `fetch` y no hay que instalar nada:

    chrome --headless=new --remote-debugging-port=9333 --user-data-dir=<carpeta de paso> --window-size=1920,1080 --ignore-gpu-blocklist --enable-gpu --mute-audio about:blank

Con cuatro órdenes del protocolo sale todo: `Page.navigate`,
`Page.captureScreenshot`, `Input.dispatchKeyEvent` y `Runtime.evaluate`, que es
con la que se cuentan los fotogramas desde `requestAnimationFrame`. Y
`Emulation.setDeviceMetricsOverride` para probar un tamaño de portátil o una
escala de 125 %. Sin ventana Chrome no tiene tope de 60, así que **se ve cuánto
margen hay**, que con el panel a la vista no se sabría.

La escena lleva además su propio medidor: con `?medir=1` (o `-- --medir` en
escritorio) dice cada segundo cuánto se llevan la física y el guion y cuántas
llamadas de dibujo salen.

Tres avisos, y los tres costaron una vuelta:

- **Un perfil nuevo mide el arranque en frío, no el juego.** Los números de
  régimen se sacan en la segunda visita con el mismo perfil.
- **El navegador se queda con la versión anterior diez minutos.** Para comprobar
  lo recién publicado, perfil nuevo.
- **Apagar cosas de una en una no dice lo que cuestan cuando el cuello es otro.**
  Quitar el reflejo o las sombras a resolución completa no ganaba nada, porque
  mandaban los píxeles; a resolución baja ganaban 13 ms entre los dos. Hay que
  medir con el tiempo del hilo principal al lado, no solo los fotogramas.

### Lo que falta de la prueba en web

- **Oírla y jugarla a mano** en el navegador.
- **Otros navegadores y otros equipos.** Solo Chrome, y solo en este portátil.
- Los sonidos de la caza son los del juego; no hay ninguno nuevo.

## CRIPTA EN LA WEB (21-nov)

**Publicada en https://danielux.es/cascabel-3d/?mesa=cripta.** Es la segunda
prueba 3D (`cripta3d/`). La dirección sin `?mesa=` sigue abriendo ÓRBITA: quien
tenía el enlace ve lo de siempre.

### Una página, dos mesas

El build «Web 3D» lleva las dos pruebas (CRIPTA usa la caza y las criaturas de
`prueba3d/`, así que no podía ir sola) y ya no arranca en ÓRBITA sino en **la
puerta**, `cripta3d/puerta_web.tscn` (`run/main_scene.prueba3d`): lee `?mesa=`
de la dirección, pinta un fotograma con el nombre de la mesa y la abre. Lo que
no conoce, o nada, es ÓRBITA. Los demás mandos se juntan con `&`:
`?mesa=cripta&calidad=alta`, `?mesa=cripta&medir=1`, `?mesa=cripta&carga=0`
(sin telón, para medir lo que se gana con él).

**La receta que publica no se ha tocado** (`Danielux135/cascabel-3d`,
`publicar.yml`): sigue bajando la rama `prueba-3d`, pasando la batería,
arrancando ÓRBITA sin ventana y exportando «Web 3D». O sea que **no arranca
CRIPTA antes de publicar**: eso se hace aquí a mano
(`godot --headless --path . res://cripta3d/cripta_3d.tscn --quit-after 600`).
Para que lo hiciera ella habría que editar esa receta, y el `gh` de este equipo
no tiene permiso para tocar workflows.

### EN UN NAVEGADOR, COMPILAR UN SOMBREADOR CUESTA SEGUNDOS

Es lo que no se veía desde el escritorio y lo que más ha costado. WebGL en
Windows pasa por ANGLE: el GLSL se traduce a HLSL y lo compila Direct3D, cien
veces más lento que el OpenGL de escritorio. Y en una página no hay caché de
Godot: lo paga cada visitante nuevo, con el lienzo congelado.

- **Se mide sin exportar:** el Godot de escritorio trae ANGLE
  (`--rendering-driver opengl3_angle`), y con `APPDATA` apuntando a una carpeta
  vacía arranca en frío sin tocar la caché de verdad. La primera lanzada de
  CRIPTA tardó así 212 s; la segunda, 15. **Eran 197 s de compilar.**
- **El porqué** (leído en el código de Godot 4.7): la primera vez que se usa un
  sombreador se compilan cuatro variantes «por defecto» con todos los tipos de
  luz dentro —también las luces de área nuevas, que son las caras— y que una
  escena sin lightmaps no usa nunca. Un sombreador VACÍO con luz son 5,6 s; sin
  especular, 2,9; con luz por vértice, 0,9; sin luz, 0,3. Y el código propio se
  paga tres a cinco veces, una por variante.
- **Lo que se hizo:** con la luz entera de Godot solo quedan la piedra y el
  suelo; lo demás pasó a luz por vértice, a luz propia o a no llevarla. El
  ruido por código (la calavera eran 34,5 s ella sola) se lee ahora de
  texturas. Cada malla usa UNA variante (dos luces de relleno que alcanzan todo
  y no alumbran, y el entorno del reflejo igualado al principal). En web no hay
  ninguna luz con sombra, en ninguna calidad. Y la mesa se monta detrás de un
  telón que compila un material por fotograma y dice por cuál va.
- **Con lo que queda:** la mesa entera, en frío y por ANGLE en el equipo de
  Daniel, pasa de **197 s de parón a unos 40 s detrás del telón** (38,8 s con el
  equipo libre; con otro juego abierto al lado, de 47 a 51). Son 41 pasos y solo
  dos son largos: la piedra (5,7 s) y el suelo (4,6 s); ningún otro pasa de 2 s.
  El primer fotograma a la vista tarda 0,06 s. Jugando tres minutos en frío con
  todos los sucesos forzados no aparece ningún material sin compilar
  (`--medir --tirones`): los fotogramas largos que quedan son sueltos, de 60 a
  200 ms, y no se repiten de una lanzada a otra.
- **«El aspecto no cambia» hubo que comprobarlo desde fuera.** Los agentes que
  reescribieron los sombreadores informaron de que no se veía nada. Tres
  críticos, con la gira de antes y la de después lado a lado, encontraron nueve
  diferencias (la bóveda de la calavera sin grietas, el espectro mate, las
  bombillas «de plástico», el carbón de la sala encendido…). Se arreglaron sin
  volver a encarecer la compilación; lo que enseñó cada una está en la skill.

El detalle, las medidas de cada modo y las herramientas (`banco_sombreadores`,
`-- --como-web`, `--medir`) están en la skill `prueba-3d` y en
`cripta3d/LEEME.md`.

**ÓRBITA tiene el mismo problema y nadie lo había medido:** publicada, tarda
55 s en arrancar en frío en el equipo de Daniel (GTX 1060, i5-6600K), con un
parón de 40 s seguidos sin una palabra y otro de 10,7 s cuando el vigilante
sube a ALTA y aparece la luz con sombra. No se ha tocado.

### Mirado en un navegador

Con el Chrome sin ventana de siempre (`cdp.mjs`), en el equipo de Daniel (GTX
1060, i5-6600K) y contra la página publicada. **Ojo con las cifras: esa noche
había otro juego abierto en el equipo**, que le quitaba procesador y gráfica;
la misma carga medida en escritorio por ANGLE salía entre un 20 y un 30 % más
lenta que con el equipo libre.

- **Lo que se baja:** el motor, 9,8 MB (el mismo de antes), y el paquete, que
  pasa de 1,4 a **7,4 MB** al llevar las dos mesas.
- **Primera visita: se juega a los 72 s.** 7 s de bajar; **13,5 s con la
  página parada en el logo de Godot** (arrancar el motor y montar la mesa: ahí
  no hay telón todavía); y 51 s de telón, con su barra y su «30 / 41». Los dos
  pasos largos, 9,2 y 7,8 s. Después, ni un parón: en el minuto y medio que se
  miró jugando, solo dos fotogramas pasan de un cuarto de segundo (0,39 y
  0,29 s).
- **Segunda visita: se juega a los 17 s.** El navegador guarda los programas
  compilados: el telón dura 10 s (cada paso, entre 0,15 y 0,75 s) y el arranque
  del motor, 4,5.
- **ÓRBITA, por la puerta, sigue abriendo** en la dirección de siempre, con su
  parón de 41,6 s de antes: no se ha tocado.
- **Lo que no vale de esta medida: los fotogramas por segundo.** Con la gráfica
  compartida con el otro juego salían 28–35 en MEDIA y 60–75 en BAJA, y el
  vigilante iba y venía entre las dos. En escritorio por ANGLE, con el equipo
  libre, MEDIA va a 55. Hay que repetirlo con el equipo libre.

**Cómo se midió y qué falló por el camino:** `medir_publicado.sh` lanza tres
visitas (CRIPTA con perfil nuevo, CRIPTA otra vez con ese perfil, y la dirección
de siempre). En la primera, el bucle que pregunta cada segundo se quedó
esperando las fotos —con la página parada compilando, una foto tarda lo que dure
el parón— y sacó 5 muestras en 150 s; la línea de tiempo se reconstruyó con la
lista de huecos del hilo principal, que sí va apuntada dentro de la página. Las
fotos ya no se esperan. Y la página apunta ahora sus hitos en `window.__hitos`
(«puerta», «escena», «montada», «carga», «juego», en milisegundos desde que se
pidió), para no tener que deducirlos.

### Lo que falta de CRIPTA en web

- **Jugarla a mano y oírla** en el navegador.
- **Otros navegadores y una gráfica integrada.** Solo Chrome sin ventana, en un
  equipo con GTX 1060: ahí el navegador usa la gráfica buena. En un portátil
  dibujará con la integrada y el vigilante la bajará de calidad; no está medido.
- **La letra del marcador es la de reserva de Godot**, como en ÓRBITA.
