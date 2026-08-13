# Prompts para los assets de la cáscara

Lo que hay ahora lo genera `fuente.py` por código: cinco marcos de nueve trozos
con biselado plano. **Cumplen y son sosos**, que es exactamente lo que pasa
cuando el arte lo escribe un programa. Estos prompts son para sustituirlos por
arte de verdad.

**Antes de pegar cualquiera hay que pegar el style guide**, como siempre: todos
empiezan por "Following the style guide above".

---

## Lo que hay que saber antes de generar

**1. Un marco de nueve trozos se corta en REJILLA FIJA, no por silueta.**

    python3 procesar.py hoja.png --tam 24 --tira 3 --filas 3 --salida assets/ui/ventana/ \
        --nombres "esq_si,borde_sup,esq_sd,borde_izq,relleno,borde_der,esq_ii,borde_inf,esq_id"

`procesar.py` recorta por silueta por defecto: correcto para un icono, y lo peor
posible para un marco, porque cada pieza sale con el tamaño de su dibujo y las
esquinas dejan de cuadrar con los bordes. Es el fallo que ya nos costó una
sesión. Hay una prueba que lo caza.

**2. La unidad manda.** Los marcos actuales son de 8 px por lado (el tooltip y
el botón, de 4). Si el arte nuevo viene a 16, hay que tocar `GROSOR_VENTANA`,
`ALTO_TITULO` y `ALTO_BARRA` en `render/nodo_cascara.gd` para que sigan siendo
múltiplos, o el último trozo sale cortado.

**3. La cáscara NO lleva la paleta de la mazmorra.** Es cáscara, no contenido,
igual que el fondo de escritorio. No la cuantices con `procesar.py`; recórtala y
redimensiónala y ya.

**4. Nada de assets reales de Microsoft.** Ni Bliss, ni el logo, ni Luna, ni los
iconos. Reconocible sí, calcado no.

---

## 1. El marco de ventana

Lo más importante de la lista: es lo que se ve todo el rato alrededor de la mesa.

> Following the style guide above, create a user interface nine-slice sheet on a
> flat magenta `#FF00FF` background, as a 3x3 grid of equal 24x24 cells with no
> gaps between them.
>
> CRITICAL: these are NOT nine small finished frames. They are nine fragments of
> ONE large window frame, cut apart on a fixed grid. Every cell must be exactly
> the same size and the pieces must line up when reassembled.
>
> CRITICAL: each edge piece is a bare strip with NO end caps, NO rivets at its
> ends and NO decoration that would repeat: when the same strip is tiled twenty
> times in a row it must read as one continuous unbroken length. Any detail near
> the ends of a strip becomes a repeating pattern and ruins it.
>
> Top row:    top-left corner · top edge strip · top-right corner
> Middle row: left edge strip · a single flat dark fill square · right edge strip
> Bottom row: bottom-left corner · bottom edge strip · bottom-right corner
>
> The frame is the chrome of a chunky late-90s desktop operating system window,
> but built like a machine panel: brushed grey metal, a bright bevel on the top
> and left, a dark bevel on the bottom and right, a hard 1px black outline on
> the outside AND on the inside, and a fine horizontal brushed grain along the
> metal. The corners carry a small flush screw head, nothing else.
>
> The fill square is almost flat and very dark, with barely any texture, because
> text and icons will sit on top of it and must stay readable.

Nombres: `esq_si,borde_sup,esq_sd,borde_izq,relleno,borde_der,esq_ii,borde_inf,esq_id`
→ `assets/ui/ventana/`

**Y una segunda pasada para la ventana inactiva**, con el mismo prompt cambiando
"brushed grey metal" por "dull desaturated grey metal, no shine" → `ventana_apagada/`.

## 2. La barra de título

> Following the style guide above, create a user interface nine-slice sheet on a
> flat magenta `#FF00FF` background, as a 3x3 grid of equal 16x16 cells with no
> gaps.
>
> CRITICAL: fixed grid, all nine cells exactly the same size, and the edge
> strips are uniform along their length with NO end caps — they are going to be
> tiled two hundred times horizontally and must read as one continuous bar.
>
> This is the TITLE BAR of an operating system window: a deep blue band with a
> lighter blue highlight along its top edge and a darker blue at the bottom, a
> subtle vertical gradient banded into three or four flat steps (no smooth
> gradient — flat bands only), and a 1px black outline. It must read as
> "this window is focused and alive".

Nombres: los mismos → `assets/ui/titulo/`

## 3. Los botones de la barra de título

> Following the style guide above, create a horizontal strip of six 16x16 icons
> on a flat magenta `#FF00FF` background, evenly spaced with clear empty magenta
> between them.
>
> CRITICAL: each icon must read at 16x16 with no zoom. That means fat shapes,
>1px symbols at most, and no antialiasing anywhere. No drop shadows, no glow.
>
> These are the little square buttons of an operating system title bar, drawn as
> raised metal squares with a bright top-left bevel and a dark bottom-right one.
> In order: minimize (a low horizontal bar) · maximize (a hollow rectangle) ·
> close (an X) · and then the same three again but PRESSED, with the bevel
> inverted so they read as pushed in.

Nombres: `min,max,cerrar,min_pulsado,max_pulsado,cerrar_pulsado` → `assets/ui/botones/`

## 4. La barra de tareas y el botón Inicio

Esto es lo que has dicho que está más soso, y tiene arreglo: una barra de tareas
de verdad tiene relieve, separadores y una bandeja hundida.

> Following the style guide above, create a user interface sheet on a flat
> magenta `#FF00FF` background, as a 3x3 grid of equal 24x24 cells with no gaps.
>
> CRITICAL: fixed grid, all nine cells the same size, edge strips uniform with
> NO end caps: this bar spans the whole width of the screen and the top strip
> will be tiled forty times.
>
> This is the TASKBAR of a chunky desktop operating system: a horizontal band of
> grey metal with a bright 1px highlight along its very top edge, a soft vertical
> banding of two or three flat tones below it, and a fine brushed grain. It is
> the heaviest, most solid element on screen — it should feel like the base the
> whole desktop rests on.

Nombres: los de siempre → `assets/ui/barra/`

Y el botón Inicio, aparte, porque es el único elemento con identidad de la barra:

> Following the style guide above, create two 64x24 buttons stacked vertically on
> a flat magenta `#FF00FF` background, with empty magenta between them.
>
> CRITICAL: they must read at their real size, 64x24, with no zoom. Fat shapes
> only, no fine detail, no antialiasing.
>
> A start button for a fake operating system, drawn as a raised rounded metal
> tab with a bright top-left bevel, a dark bottom-right bevel and a 1px black
> outline. On its left third there is a small emblem: a **round bell with a slit
> mouth**, the sort you'd find on a cat's collar — it is the logo of this system
> and it must read as a bell at 16x16. Leave the right two thirds empty: text
> goes there.
>
> The second copy is the same button PRESSED: the bevel inverted so it reads as
> pushed in, and everything shifted one pixel down and right.

Nombres: `inicio,inicio_pulsado` → `assets/ui/inicio/`

## 5. Los iconos del escritorio

Los 280 px de cada lado están vacíos salvo por las reliquias. Esto es lo que hace
que un escritorio parezca un escritorio.

> Following the style guide above, create a 3x3 grid of nine 32x32 desktop icons
> on a flat magenta `#FF00FF` background, clearly separated with empty magenta
> around each one.
>
> CRITICAL: each icon must read at 32x32 with no zoom. ONE object per cell, a fat
> unmistakable silhouette, no thin one-pixel lines, no text, no antialiasing, no
> cast shadows and no glow bleeding onto the magenta.
>
> They are the system icons of a fake operating system that is running a dungeon
> it does not understand, so each one is an office object with something wrong
> with it.
>
> Row 1: a beige desktop computer with a **stone dungeon door** where the screen
> should be · a wastebasket with a bone sticking out · a manila folder with a
> chain and padlock across it
>
> Row 2: a floppy disk with a wax seal stamped on it · a scroll of parchment
> rolled around a printed page · a hard drive with roots growing out of it
>
> Row 3: a text document icon with a red error cross · a pinball with a system
> cursor arrow embedded in it · a small CRT monitor showing a flatlined line

Nombres: `mi_maquina,papelera,carpeta,disquete,registro,disco,error,cascabel,monitor`
→ `assets/ui/iconos/`

## 6. El tooltip y el cuadro de diálogo

> Following the style guide above, create TWO separate nine-slice sheets on a
> flat magenta `#FF00FF` background, one above the other, each a 3x3 grid of
> equal 8x8 cells with no gaps inside the grid and a wide magenta gap between
> the two grids.
>
> CRITICAL: fixed grid, equal cells, edge strips uniform with no end caps.
>
> The first is a TOOLTIP: pale yellow parchment paper with a hard 1px black
> outline and nothing else. Almost completely flat — text sits on it and must
> stay readable. No bevel: a bevelled tooltip reads as a button.
>
> The second is an ALERT DIALOG: the same grey metal as the window frame but
> with a thicker double bevel, so it reads as a small modal box that has popped
> up on top of everything.

Nombres: primero `assets/ui/tooltip/`, luego `assets/ui/dialogo/`

## 7. La barra de progreso

Es el reloj del enemigo, y ahora mismo es un rectángulo de color.

> Following the style guide above, create a horizontal sheet on a flat magenta
> `#FF00FF` background with three separate pieces, clearly separated:
>
> 1. an empty progress-bar trough, 48x12, drawn as a sunken channel: dark inside,
>    a dark bevel on the top-left and a bright one on the bottom-right, 1px black
>    outline
> 2. a 8x8 tile of the FILL: a solid block of colour with a bright 1px highlight
>    along its top edge, designed to be repeated horizontally with no seam and no
>    end cap
> 3. the same 8x8 fill tile again but in an alarm colour, for when the bar is
>    nearly full
>
> CRITICAL: the fill tiles must be seamless when repeated and must have no
> detail near their left or right edges.

Nombres: `canal,relleno,relleno_alarma` → `assets/ui/progreso/`

## 8. El cursor

> Following the style guide above, create a horizontal strip of three cursors on
> a flat magenta `#FF00FF` background, clearly separated: a 12x18 arrow pointer,
> a 16x16 hourglass, and a 16x16 arrow with a small hourglass beside it.
>
> CRITICAL: each cursor is solid white inside with a hard 1px black outline all
> around, and nothing else. No antialiasing, no grey, no shadow. The tip of the
> arrow must be at the very top-left pixel of its box.

Nombres: `flecha,reloj,ocupado` → `assets/ui/cursor/`

## 9. Los tres fondos de escritorio

`DISEÑO.md` §3 dice que el sistema se degrada acto a acto, y ahora mismo eso no
se ve en ninguna parte. Tres fondos es la forma más barata de contarlo.

> Following the style guide above, create a 320x180 pixel art desktop wallpaper.
> No text, no logos, no user interface: only the wallpaper image, filling the
> whole canvas edge to edge.
>
> A rolling green hill under a blue sky with fat cumulus clouds — the calm,
> almost corporate default wallpaper of an operating system that shipped in 2002.
> Serene and slightly boring on purpose.

Y las otras dos, con el mismo prompt cambiando el último párrafo:

- **Acto II:** *"The same hill and sky, but wrong: the grass is patchy and grey
  at the edges, a band of the sky is corrupted into horizontal stripes of solid
  colour, and a stone dungeon doorway stands on the hilltop where nothing should
  be."*
- **Acto III:** *"The same hill, now almost entirely corrupted: most of the
  image has collapsed into horizontal bands of flat colour and repeated broken
  tiles, only a corner of green survives, and the sky is dark violet."*

Nombres: `fondo_acto1,fondo_acto2,fondo_acto3` → `assets/shell/`

---

## Orden por el que yo empezaría

1. **La barra de tareas y el botón Inicio** (4), que es lo que has dicho que
   está más soso y es lo que más se ve.
2. **El marco de ventana y la barra de título** (1 y 2): es el borde de todo.
3. **Los iconos del escritorio** (5), que llenan los laterales vacíos.
4. Lo demás.

Cuando tengas cualquiera de estos, dímelo y lo conecto: el renderizador de nueve
trozos ya está y solo hay que cambiarle la carpeta.

---

# Segunda tanda: más fondos "bugueados" y más detalle de sistema

Lo primero ya está integrado y validado (ventana, título, barra, Inicio,
botones, iconos, los tres fondos por acto). Esto es lo que pediste encima:
variantes de fondo dentro de cada acto, para que la corrupción no se vea como
tres imágenes fijas sino como algo que puede empeorar de un momento a otro, y
más piezas de "sistema operativo de verdad" para la bandeja y la barra.

## 10. Más fondos por acto — variaciones, no solo progresión

Ahora mismo hay UN fondo por acto. La apuesta de esta tanda es tener DOS o TRES
por acto: el run elige uno al azar cada vez que entras en el escritorio (entre
combate y combate, por ejemplo), así el jugador no memoriza "el fondo del acto
2" sino que nota que el sistema se comporta mal de forma distinta cada vez.

Usa el MISMO prompt base del acto que toque (arriba, sección 9) y pide dos o
tres variaciones del mismo fallo, no fallos nuevos cada vez:

> Following the style guide above, create a 320x180 pixel art desktop
> wallpaper. No text, no logos, no user interface: only the wallpaper image,
> filling the whole canvas edge to edge.
>
> The same rolling green hill and blue sky as the reference wallpaper, but
> with a DIFFERENT glitch than before: [aquí cambia el fallo concreto].
> The corruption should feel like the same sick system having a slightly
> different bad moment, not a different picture.

Fallos concretos que puedes pedir, uno por imagen (dos o tres por acto):

- **Acto II** (grado leve — la doorway de piedra ya es fija, el fallo es del
  cielo o del suelo):
  - *"a horizontal band of the sky has scrolled sideways and doesn't line up
    with the rest, like a torn video signal"*
  - *"a chunk of the grass near the bottom has frozen into a repeating tile,
    the same 8x8 patch stamped over and over"*
  - *"the clouds have duplicated: two faint identical copies of the same
    cloud, offset by a few pixels, like a bad screen redraw"*
- **Acto III** (grado fuerte — ya casi todo colapsado, varía QUÉ sobrevive):
  - *"only the sky has collapsed into flat bands; the hill below is still
    green and intact, which is somehow worse"*
  - *"only the ground has collapsed into broken repeated tiles; the sky above
    is still a calm, perfect blue"*
  - *"the whole image has shifted a few pixels to one side, leaving a strip of
    pure black down one edge, like a screen that lost sync"*

Nombres sugeridos: `fondo_acto2_a, fondo_acto2_b, fondo_acto3_a, fondo_acto3_b`
→ `assets/shell/`. Dime cuántas quieres por acto y ajusto
`render/nodo_cascara.gd` para que elija una al azar en vez de una fija.

## 11. El reloj de la bandeja

Ahora mismo el reloj es texto suelto sobre una caja plana que dibujo por
código — un apaño, no una pieza. Necesita ser una bandeja hundida de verdad,
del mismo material que la barra de tareas.

> Following the style guide above, create a single UI element on a flat
> magenta `#FF00FF` background: a small rectangular tray, roughly 64x16,
> drawn as a SUNKEN inset panel — dark inside, with a dark bevel along the
> top-left edge and a bright highlight along the bottom-right edge (the
> opposite of a raised button), 1px black outline. Plain and empty inside:
> digits will be drawn on top of it, so keep the interior flat and dark.

Nombre: `bandeja_reloj` → `assets/ui/`

## 12. Separadores y detalle de bandeja

Lo que distingue una barra de tareas de un rectángulo gris es que tiene
piezas pequeñas: un separador vertical entre secciones, un altavoz, un
indicador de red roto (parte de la broma: el sistema no tiene con qué
conectarse).

> Following the style guide above, create a horizontal strip of three small
> 12x16 tray icons on a flat magenta `#FF00FF` background, evenly spaced.
>
> CRITICAL: each icon must read at 12x16 with no zoom, flat colors, hard 1px
> black outline, no antialiasing.
>
> A thin vertical separator bar (just two shades of grey, a bevel groove) ·
> a small speaker icon · a small "no network" icon: a broken plug or a signal
> bars icon with a red X over it.

Nombre: `separador,altavoz,sin_red` → `assets/ui/bandeja/`

## 13. Ventana inactiva de verdad

Ya pediste la variante apagada del marco en la sección 1, pero si aún no la
has generado, es la pieza que falta para que el título de la ventana lea bien
cuando el combate te tiene mirando la mesa y no el marco: sin contraste, ahora
mismo la ventana se ve "encendida" todo el rato aunque nunca pierda el foco
(no hay gestor de ventanas, así que esto solo se usaría si algún día una
ventana secundaria se dibuja encima — no es urgente).

---

## Sobre el desbordamiento en tu portátil

Eso no se arregla con arte: es el viewport creciendo en pantallas que no dan
16:9 exacto. Ya está corregido en el código (`VistaMesa._medir_pantalla()`).
Si la ventana del pinball sigue sin cuadrar después de esto, dímelo con una
captura y el tamaño de tu pantalla — puede que haga falta otro ajuste, pero
esta vez ya no es un problema de arte.
