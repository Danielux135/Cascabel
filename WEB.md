# WEB.md — CASCABEL EN EL NAVEGADOR

**Estado (19-oct-2026): los arreglos están hechos, la batería da 647/647 y el
primer build web se ha jugado en un navegador.** Falta medir el rendimiento con
el navegador a la vista, OÍRLO, y publicarlo.

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
   vale.
2. **Oírlo**, que no se puede deducir. El arranque tiene que sonar con el primer
   clic, y los bucles tienen que empalmar sin hueco. Y ojo: **en la plantilla
   sin hilos, Stream mezcla en el hilo principal**. Un fotograma de más de ~40 ms
   deja sin datos al reproductor y la música corta. Si corta al cambiar de
   pantalla o en multibola, subir `audio/driver/output_latency.web`.
3. **Publicarlo.** El plan es GitHub Pages desde este repo, con un workflow de
   Actions que descargue Godot 4.7.2 y sus plantillas, exporte con
   `--export-release` y publique. Saldría en **`danielux.es/Cascabel/`**, porque
   `danielux.es` ya es el sitio de usuario de Pages con dominio propio, y en git
   no entraría ningún binario. **Pages no tiene contraseña**: lo ve quien tenga
   el enlace. Si hace falta privado, itch.io (Draft, o Restricted con
   contraseña; HTML, 960×540, botón de pantalla completa, sin "Mobile
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
