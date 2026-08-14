# Prompts para el arte ANIMADO — enemigos, jefes y criaturas

Hoy **ningún bicho del juego tiene un solo fotograma de verdad**. `render/
nodo_enemigo.gd` dibuja UNA textura estática y la deforma por código:
respiración en squash/stretch de píxel entero, vaivén de los que flotan,
empujón de la embestida, destello y disolución por shader. Cumple, y es el
mismo "cumple y es soso" que los marcos que escribía `fuente.py`.

Esto es la tanda 7 de `ESTADO.md`. **Se diseña antes de generar**, porque una
hoja de animación mal cortada no se arregla luego: se vuelve a generar.

---

## Lo que hay que decidir ANTES de pegar un prompt

**1. Cuatro estados por criatura, cuatro fotogramas cada uno.** La propuesta:

| Estado | Fotogramas | Cuándo suena | Qué sustituye |
|---|---|---|---|
| `idle` | 4 | siempre | `_paso_respiracion()` |
| `golpe` | 4 | al recibir daño | nada (hoy solo hay destello) |
| `ataque` | 4 | cuando el reloj cobra | `embestir()` |
| `muerte` | 4 | al matarlo | nada (hoy solo disolución) |

Cuatro y cuatro no es capricho: **una hoja de 4×4 celdas iguales es lo que
`procesar.py` sabe cortar en rejilla fija**, y 16 celdas es lo máximo que el
generador aguanta sin que el bicho cambie de cara entre la primera y la última.

**2. Si el `idle` se dibuja, la respiración por código se apaga.** Las dos a la
vez se suman y el bicho hierve. `ParametrosAnimacion.respiracion_pixeles` tiene
que pasar a ser por criatura, no global: los que no tengan hoja siguen
respirando por código y los que la tengan van a 0.

**3. El destello y la disolución NO se dibujan.** Son shader y se aplican sobre
la textura que toque, así que siguen funcionando con fotogramas. No pidas
fotogramas de "recibiendo daño en blanco" ni de "desvaneciéndose": ya los hace
el material, y dibujarlos además los duplica.

**4. El reproductor va en `_process`, y tiene que congelarse con el hitstop.**
El golpe es justo el momento en que el hitstop para el mundo: si los fotogramas
siguen corriendo durante la parada, la reacción al golpe se gasta mientras la
pantalla está quieta y no se ve.

**5. Cortar en rejilla fija, SIEMPRE.**

    python3 procesar.py hoja.png --tam 96 --tira 4 --filas 4 --salida assets/enemigos/rata/ \
        --nombres "idle_1,idle_2,idle_3,idle_4,golpe_1,golpe_2,golpe_3,golpe_4,ataque_1,ataque_2,ataque_3,ataque_4,muerte_1,muerte_2,muerte_3,muerte_4"

Por defecto `procesar.py` recorta **por silueta**, que es lo correcto para un
icono suelto y **lo peor posible para una animación**: cada fotograma sale con
la caja de su propio dibujo, así que el bicho salta de sitio y de tamaño a cada
fotograma. Es exactamente la avería que ya costó una sesión con los marcos de
nueve trozos, y aquí se nota más porque se mueve.

**6. Piloto de UNO antes de generar nueve.** La tanda del 13 de agosto fueron 29
hojas de las que se usaron 6. Genera la Rata, córtala, míramela en el juego, y
solo entonces las otras ocho. Y **guarda la hoja** en `Desktop\Sprites` con su
fila en `INVENTARIO_HOJAS.md`, o el sprite solo se podrá reparar, no rehacer.

**7. Pasa el sprite que ya existe como imagen de referencia.** Si describes la
Rata con palabras, sale otra rata, y el mapa enseñaría un bicho y el combate
otro. `assets/enemigos/rata.png` entra en el prompt como referencia.

---

## 1. La hoja de un enemigo (la plantilla)

Esta es la que se pega nueve veces cambiando solo el último párrafo.

> Following the style guide above, and using the attached sprite as the exact
> reference for this character, create a sprite animation sheet on a flat
> magenta `#FF00FF` background, as a 4x4 grid of equal square cells with NO gaps
> between them and no border, numbering or grid lines anywhere.
>
> CRITICAL: this is an animation sheet cut on a FIXED GRID. All sixteen cells
> must be exactly the same size, and in every single cell the character must be
> centred horizontally and stand with its FEET ON THE SAME ROW OF PIXELS. If one
> frame sits two pixels lower than the next, the creature jitters when it plays.
>
> CRITICAL: no motion blur, no speed lines, no ghosting, no onion-skinned
> previous frames, no glow bleeding onto the magenta. Hard 1px black outline,
> flat colours, no antialiasing anywhere, no cast shadows. The light comes from
> the same direction in all sixteen cells.
>
> CRITICAL: the character never leaves its cell and never changes scale between
> frames — the camera does not zoom. And the difference between two consecutive
> frames must be clearly visible at the real size of one cell, with no zoom: a
> one-pixel difference disappears in the game.
>
> Row 1 — IDLE, a 4-frame loop that reads as breathing while standing still:
> rest · rise · peak · fall. The last frame must lead back into the first.
> Row 2 — HIT, the reaction to taking damage: recoil back · furthest back and
> off balance · starting to recover · almost back to the idle pose.
> Row 3 — ATTACK, a 4-frame swing: wind up and lean away · furthest wind-up ·
> the strike, leaning hard toward the viewer · the follow-through.
> Row 4 — DEATH, collapsing: staggered · buckling · falling apart · a low pile
> of what is left. Do NOT fade it out and do NOT make it transparent: the
> dissolve is done in the game.
>
> The character is: [aquí va la descripción del bicho].

Descripciones, una por hoja, y **las nueve tienen que compartir escala**: un
esqueleto y una gárgola dibujados cada uno "llenando su celda" acaban midiendo
lo mismo y el acto III deja de dar miedo.

| Enemigo | Descripción para el último párrafo |
|---|---|
| `rata` | *"a scrappy dungeon rat standing on its hind legs, small — it should occupy about half the height of its cell"* |
| `limo_moneda` | *"a blob of slime with coins suspended inside it; it has no legs, so its idle is a wobble and its death is a puddle"* |
| `goblin_carroniero` | *"a small hunched goblin scavenger with a sack and a rusty knife"* |
| `calavera_llameante` | *"a burning skull that FLOATS — it has no feet, so instead keep the bottom of the skull on the same row of pixels in every cell; the flame moves more than the skull does"* |
| `esqueleto` | *"a skeleton warrior with a notched sword; its death should come apart into separate bones"* |
| `cultista` | *"a hooded cultist with a curved dagger, its face in shadow"* |
| `goblin_bruto` | *"a heavy, thick-armed goblin brute with a club; it should occupy nearly the full height of its cell"* |
| `armadura_vacia` | *"an empty suit of plate armour moving on its own, nothing inside the helmet but dark"* |
| `gargola` | *"a stone gargoyle with folded wings; the biggest of the set, filling its cell"* |

→ `assets/enemigos/<id>/`, celda 96.

## 2. Los tres jefes

Igual que la plantilla, cambiando el tamaño de celda y con **seis fotogramas de
muerte en vez de cuatro**: un jefe que se cae igual de rápido que una rata no se
lee como un jefe. Eso obliga a una rejilla distinta, así que la hoja del jefe es
**5 filas de 4** con la muerte ocupando las dos últimas filas:

> [la misma cabecera, con "a 4x5 grid of equal square cells"]
>
> Row 1 — IDLE · Row 2 — HIT · Row 3 — ATTACK, as above.
> Rows 4 and 5 — DEATH, eight frames: a long collapse that takes its time,
> ending in a pile that is clearly bigger than the creature was tall.

    python3 procesar.py hoja.png --tam 128 --tira 4 --filas 5 --salida assets/jefes/<id>/ ...

→ `assets/jefes/<id>/`, celda 128. **Ojo:** los tres sprites de `assets/jefes/`
no se usan todavía a propósito (`ESTADO.md`, Abierto): el mapa enseña el retrato
del enemigo normal porque un jefe hoy es "el mismo con más vida". Estas hojas
solo valen la pena **cuando los jefes sean enemigos de verdad, en Fase 6**. Si
la Fase 6 no está, esta sección se salta.

## 3. El cascabel con la criatura de fuego

Lo que quedó pendiente de la exploración de Fátima: hay 8 fotogramas ya
generados con Claude Design en `assets/_pruebas/cascabel_brasa/`, en tira de una
fila, 64×64. **No hace falta regenerarlos para animar**: lo que quedó abierto es
el estilo del contorno, no el movimiento.

Si se regenera, este es el prompt, y esta vez con fondo magenta como todo lo
demás en vez de alfa real:

> Following the style guide above, create a sprite animation sheet on a flat
> magenta `#FF00FF` background, as a single horizontal row of 8 equal 64x64
> cells with NO gaps between them.
>
> CRITICAL: fixed grid, equal cells, the object centred in every cell and its
> base on the same row of pixels throughout. No motion blur, no ghosting, no
> glow bleeding onto the magenta, hard 1px black outline, flat colours, no
> antialiasing. The contour must be ANGULAR and cut on the pixel grid — no soft
> rounded silhouette, no 3D shading, no gradients: it has to sit next to
> `farol.png` and `vela.png` without looking like it came from somewhere else.
>
> A round stone bell of the sort that goes on a cat's collar, with a slit mouth,
> and a small fire creature living inside it: two bright eyes visible in the
> flame. The 8 frames are one seamless loop of the flame breathing inside the
> bell — the bell itself barely moves; the fire does the work.

→ celda 64. Destino: **sin decidir** (`ESTADO.md`, tanda 2b). No es una reliquia
normal, así que probablemente carpeta propia de coleccionables.

---

## El subsistema que hace falta, en corto

Lo que cambia en el código es menos de lo que parece, y por eso conviene
escribirlo antes de generar nada:

- **`HojaAnimada`**: una lista de `AtlasTexture` sobre un PNG, o los PNG sueltos
  que ya escupe `procesar.py`. Lo segundo es más tonto y encaja con el resto del
  repo.
- **Un reproductor** con estado actual, fotograma actual y acumulador de tiempo.
  Los estados de un solo tiro (`golpe`, `ataque`, `muerte`) vuelven a `idle` al
  acabar; `muerte` se queda en el último fotograma y deja que la disolución haga
  el resto.
- **`NodoEnemigo._draw()`** cambia una línea: la textura que dibuja sale del
  reproductor. **`rect_dibujo()` no se toca**, y ahí está la gracia: el squash y
  el stretch de píxel entero siguen valiendo para los bichos sin hoja, y para
  los que la tengan basta con poner `respiracion_pixeles` a 0.
- **La cadencia en fotogramas por segundo tiene que ser un divisor limpio** y
  congelarse con el hitstop, o el fotograma de golpe se gasta durante la parada.

**Criterio de salida de la tanda:** con la hoja de la Rata puesta y la
respiración por código apagada, la Rata tiene que leerse mejor que ahora en las
cuatro cosas —quieta, golpeada, pegando y muriéndose— sin tocar ningún otro
bicho. Si no gana la comparación, el problema es el arte, no el reproductor, y
lo que hay que cambiar es el prompt.
