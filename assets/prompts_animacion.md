# Prompts para el arte ANIMADO — enemigos, jefes y criaturas

Hoy **ningún bicho del juego tiene un solo fotograma de verdad**. `render/
nodo_enemigo.gd` dibuja UNA textura estática y la deforma por código:
respiración en squash/stretch de píxel entero, vaivén de los que flotan,
empujón de la embestida, destello y disolución por shader. Cumple, y es el
mismo "cumple y es soso" que los marcos que escribía `fuente.py`.

Esto es la tanda 7 de `ESTADO.md`. **Se diseña antes de generar**, porque una
hoja de animación mal cortada no se arregla luego: se vuelve a generar.

> **ANTES DE PEGAR NADA: el prefijo está en `assets/GUIA_ESTILO.md`.** Todos los
> prompts de este fichero empiezan por "Following the style guide above" y
> durante un tiempo esa guía no estaba escrita en ninguna parte del repo. Ya lo
> está, y es la de verdad —la que Fátima usó y la que generó el arte que hay
> integrado—, no una reconstrucción. Se pegan el bloque A y el B, y luego el
> prompt.
>
> **Para animación, la línea del bloque A que más trabaja es "Maximum three
> tones per surface", y la del bloque B es la del contorno angular.** Un
> generador al que le pides ocho fotogramas tiende a suavizar para que la
> transición quede "bonita", y suavizar es exactamente lo que no se puede
> reparar después.

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

## 3. El cascabel: por qué la campana y la criatura van SEPARADAS

**El prompt que había aquí estaba mal y conviene saber por qué**, porque el fallo
es de diseño y no se ve mirando la imagen. Pedía *"a round stone bell with a
small fire creature living inside it"*, o sea **las dos cosas dibujadas juntas en
la misma celda**. Y `DISEÑO.md` §4 dice lo contrario, con todas las letras:

> *"Se dibuja en dos capas: la cáscara rueda, la criatura no. Como una bola de
> hámster. La cáscara gira con ocho o doce rotaciones pregeneradas por código y
> ajustadas a rejilla; la criatura se queda derecha, se aplasta al chocar y mira
> hacia donde va."*

Una campana con el bicho pintado dentro **no se puede rotar**: al girar la
cáscara, gira el bicho con ella y queda boca abajo. Y no se puede aplastar la
criatura sin aplastar la campana. Los 8 fotogramas de
`assets/_pruebas/cascabel_brasa/` valen como prueba de que el formato funciona
—y como referencia de estilo— pero **no como asset final**.

Además, dibujarlas juntas tira a la basura la combinatoria: hay **9 cáscaras en
`assets/bolas/` y 9 criaturas en `assets/criaturas_64/`**, que separadas son 81
cascabeles con el mismo código de dibujo, y juntas serían 81 hojas que generar.

**Las cáscaras ya están y no se animan**: las rota el código. Lo único que hay
que generar es la criatura.

## 4. Las nueve criaturas animadas

**Esta es la tanda que hay que hacer**, y es la que da los coleccionables de
`PROPÓSITO.md` §4.

### Las decisiones, antes del prompt

**Ocho fotogramas en una sola fila, celda de 64.** No es un número redondo por
capricho: es exactamente el formato de la exploración de `cascabel_brasa`, que ya
está probado de punta a punta con este generador. Cambiar de formato en el piloto
es cambiar dos cosas a la vez.

**Un solo estado: `idle`.** Y esto es lo que ahorra la tanda entera. La criatura
va dentro de una bola que se pasa la partida rebotando, así que:

| Lo que hace la criatura | Quién lo hace | ¿Se dibuja? |
|---|---|---|
| Respirar / moverse | **la hoja** | **sí, los 8 fotogramas** |
| Aplastarse al chocar | el código (squash de píxel entero) | **no** |
| Mirar hacia donde va | el código (desplazamiento de un par de píxeles) | **no** |
| Girar | **nadie: la criatura NO gira**, es la cáscara la que rueda | **no** |

Es la misma regla del punto 3 de arriba: no se pide arte de lo que ya hace el
motor, porque dibujarlo además lo duplica y el bicho hierve.

**Sin cáscara alrededor y sin contorno de bola.** La criatura se dibuja sola,
como si se asomara. Las que ya están en `assets/criaturas_64/` se generaron así
—la hoja del 13 de agosto está documentada como *"criaturas peek 3×3"*— y por eso
sirven como referencia exacta.

**El piloto es `cr_brasa`**, y por dos razones: es la que Fátima ya exploró, así
que hay con qué comparar; y es fuego, que es el caso más difícil —una llama que
se mueve de verdad entre fotogramas es lo que separa una animación buena de ocho
copias con un píxel movido—. Si sale bien, las otras ocho son trámite.

### El prompt

Se pega `GUIA_ESTILO.md` primero, **y la referencia**: el PNG de
`assets/criaturas_64/cr_brasa.png` va adjunto al prompt. Si se describe con
palabras sale otra criatura, y el escritorio enseñaría una y la mesa otra.

> Following the style guide above, and using the attached sprite as the exact
> reference for this creature — same character, same colours, same silhouette —
> create a sprite animation sheet on a flat magenta `#FF00FF` background, as a
> single horizontal row of 8 equal 64x64 cells with NO gaps between them and no
> border, numbering or grid lines anywhere.
>
> CRITICAL: this is cut on a FIXED GRID. All eight cells are exactly the same
> size, and in every cell the creature is centred horizontally and its lowest
> point sits on the SAME ROW OF PIXELS. If one frame sits two pixels lower than
> the next, the creature jitters.
>
> CRITICAL: draw the creature ALONE. No ball, no bell, no sphere, no glass, no
> capsule and no circular outline of any kind around it, and no ground, no
> pedestal and no shadow under it. In the game this creature is drawn inside a
> separate shell sprite that is layered on top, so anything round you add here
> will be duplicated.
>
> CRITICAL: the creature does NOT rotate, does not tilt and does not change
> scale between frames, and it never leaves its cell. It stays upright and
> facing the viewer in all eight cells.
>
> CRITICAL: no motion blur, no speed lines, no ghosting, no onion-skinned
> previous frames, no glow bleeding onto the magenta.
>
> The 8 frames are ONE SEAMLESS LOOP — frame 8 must lead straight back into
> frame 1 with no jump. The difference between two consecutive frames must be
> clearly visible at the real size of one cell with no zoom: a one-pixel
> difference disappears in the game. Make the loop asymmetric rather than a
> simple rise and fall, so it does not read as a machine breathing.
>
> The creature is: [descripción de la tabla].

### Las nueve descripciones

Cada una tiene que decir **qué parte se mueve**, que es lo único que distingue
una animación de ocho fotogramas idénticos.

| Criatura | Descripción para el último párrafo |
|---|---|
| `cr_brasa` | *"a small live flame with two bright eyes in it. The flame is the whole creature. Over the loop it leans, gutters and flares as if in a draught — the eyes stay level while the fire moves around them"* |
| `cr_calavera` | *"a small skull with a flame burning behind its eye sockets. The skull barely moves; the eye flames flicker and change size"* |
| `cr_diablillo` | *"a tiny horned imp with a wide grin. It shifts its weight side to side and its ears and tail-tip twitch on different frames"* |
| `cr_espectro` | *"a small hooded spectre with no legs, its lower half trailing off into nothing. It drifts and the trailing edge ripples — the hood and face stay still"* |
| `cr_gusano` | *"a fat pale dungeon grub. It compresses and extends along its length, like a caterpillar breathing, with the segments moving in sequence rather than all at once"* |
| `cr_musgo` | *"a lump of living moss with two small eyes. Tufts and fronds sway on it at slightly different rates; the body itself hardly moves"* |
| `cr_rata` | *"a small dungeon rat. Its nose and whiskers twitch, its ears flick, and it blinks once during the loop — the body stays still"* |
| `cr_sapo` | *"a squat warty toad. It inflates and deflates its throat sac; the throat does almost all the movement and the body follows a little behind"* |
| `cr_sombra` | *"a small blot of living shadow with two pale eyes. Its outline creeps and shifts, so its silhouette is never twice the same, but it keeps the same overall mass"* |

### Después de generar

    python3 procesar.py hoja.png --tam 64 --tira 8 --filas 1 \
        --salida assets/criaturas_anim/cr_brasa/ \
        --nombres "idle_1,idle_2,idle_3,idle_4,idle_5,idle_6,idle_7,idle_8"

`--tira 8 --filas 1` no es opcional: **por defecto `procesar.py` recorta por
silueta**, y en una animación eso saca cada fotograma con la caja de su propio
dibujo, así que la criatura salta de sitio y de tamaño a cada fotograma. Es la
misma avería que descuadró los marcos de nueve trozos, y aquí canta más porque se
mueve.

Y **guardar la hoja** en `Desktop\Sprites` con su fila en `INVENTARIO_HOJAS.md`.
De las tandas sin hoja guardada —`criaturas_64`, `bolas`, la cáscara— no hay
original, así que esos sprites solo se pueden reparar, no rehacer.

### Cómo mirarlo antes de meterlo en el juego

El mosaico de prueba que ya está en `CLAUDE.md`, pero para animación: montar los
8 fotogramas **en fila y a tamaño real**, y encima la misma fila a 4×. A tamaño
real se ve si el movimiento existe; a 4× se ve si el contorno está en rejilla.
Los dos fallos que ha tenido esta clase de hoja —fotogramas casi idénticos y
silueta redondeada— se ven ahí y no se ven dentro de Godot hasta mucho después.

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

**Y sirve igual para las criaturas**, con una diferencia: la criatura no tiene
"antes" con el que comparar, porque hoy la bola es un círculo. Ahí el criterio es
otro: **poner `cr_brasa` animada dentro de la cáscara `casc_hierro` girando, y
que las dos capas se lean como un solo bicho** y no como una calcomanía pegada a
una bola.

---

## Orden de las hojas, y por qué ese

Las de animación no van todas seguidas: se reparten según lo que desbloquean.

| # | Hoja | Cuándo | Por qué ahí |
|---|---|---|---|
| 1 | **`cr_brasa` animada** (§4) | ya | Es el piloto y el caso más difícil. Y sin criaturas no hay coleccionable, que es el gancho de `PROPÓSITO.md` §2 |
| 2 | **Las otras 8 criaturas** (§4) | tras validar la 1 | Trámite si la 1 sale bien. Si no, se cambia el prompt antes de gastar ocho hojas |
| 3 | **Bandeja de sistema** (`prompts_cascara.md` §11-12) | tanda de cáscara | Lo único de la cáscara sin generar, y la barra de tareas lo dibuja con `draw_rect` a mano hasta entonces |
| 4 | **27 iconos de reliquia** (`prompts_reliquias.md`) | cuando toque | 27 de 45 reliquias siguen sin icono y se ven en tres sitios |
| 5 | **`rata` animada** (§1) | con la Fase 6 | Un enemigo animado sin comportamiento sigue siendo un saco, solo que un saco que respira |
| 6 | **Las otras 8 enemigos** (§1) | tras validar la 5 | |
| 7 | **Los tres jefes** (§2) | **solo con Fase 6** | Hoy un jefe es el mismo enemigo con más vida. La sección lo dice: si no está la Fase 6, se salta |

### Lo que `PROPÓSITO.md` va a pedir y aún NO tiene prompt

Se anota aquí para que no se genere por sorpresa a mitad de otra tanda:

- **La barra de CARGA de rampa** y el efecto de DESCARGA (§6 de `PROPÓSITO.md`).
  La barra es cáscara —una barra de progreso de Windows— y probablemente sale de
  `fuente.py`, no de una hoja de IA. El efecto de descarga sí es arte.
- **El poste que tapa el outlane** y el kickback (§7). Son objetos de mesa, celda
  pequeña, y valen los prompts de `mesa/` que ya existen como plantilla.
- **El campo de pines** (§8). Un solo pin, y se repite por código.
- **Los ficheros de `RECUPERADO/`** (§2 y §9). Iconos de 32, y ya hay nueve
  iconos de escritorio integrados que dan el estilo exacto.
