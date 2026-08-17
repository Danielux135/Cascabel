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

**Un solo estado: `idle`.** Y esto es lo que ahorra la tanda entera. Esta hoja es
la de la criatura **en la interfaz** —el retrato de Preparación, el icono de
`RECUPERADO/`, el tooltip—, o sea una cosa que está quieta en un panel:

| Lo que hace la criatura | Quién lo hace | ¿Se dibuja? |
|---|---|---|
| Respirar / moverse | **la hoja** | **sí, los 8 fotogramas** |
| Aplastarse, mirar hacia donde va | el código, si algún día hace falta | **no** |
| Girar | **nadie: la criatura no gira** | **no** |

Es la misma regla del punto 3 de arriba: no se pide arte de lo que ya hace el
motor, porque dibujarlo además lo duplica y el bicho hierve.

*Aquí ponía "la criatura va dentro de una bola que se pasa la partida
rebotando". **Ya no**: a 18 px no se ve nada dentro de la bola, ver el ⚠⚠ de
abajo. La hoja es la misma; lo que cambia es dónde se usa.*

### ⚠ LAS NUEVE CRIATURAS DE HOY **NO** ESTÁN DIBUJADAS SOLAS

*Medido y mirado el 17-ago-2026, antes de gastar la primera hoja. Aquí ponía lo
contrario y era falso.*

Lo que ponía: *"Sin cáscara alrededor y sin contorno de bola. La criatura se
dibuja sola, como si se asomara. Las que ya están en `assets/criaturas_64/` se
generaron así —la hoja está documentada como «criaturas peek 3×3»— y por eso
sirven como referencia exacta."*

**"Peek" no quiere decir "dibujada sola": quiere decir asomándose POR ALGO, y ese
algo está dibujado.** Las nueve llevan un **arco de piedra** encima y a los
lados, con su interior oscuro, y varias tienen manos o zarpas agarradas al borde.
Se ve en dos segundos montando el mosaico de las nueve a 5× y no se ve mirando un
PNG suelto, que es como se había mirado.

Medido sobre los nueve PNG:

| Qué | Valor |
|---|---|
| Caja de tinta de cada sprite | **59-60 × 47-48** sobre celda de 64 |
| Píxeles idénticos en los NUEVE | **337, el 13,6 %** — y dibujan el anillo exterior |
| Caja al borrar esos 337 px | **la misma**: 59×48 |

Ese último número es el que decide: **el arco no se puede quitar con una
máscara**, porque cada hoja lo sombreó distinto. No es reparable con
`limpiar.py`; hay que volver a generar.

**Y tumba tres cosas escritas en el repo:**

1. **El prompt de abajo se contradice consigo mismo.** Adjunta `cr_brasa.png`
   como *"exact reference — same character, same silhouette"* y a la vez ordena
   *"no ball, no bell, no sphere, no capsule and no circular outline of any kind
   around it"*. La referencia ES una campana. Un generador con esas dos órdenes
   devuelve cualquier cosa, y se gasta la hoja piloto averiguándolo.
2. **La combinatoria de 81 no es gratis** (`PROPÓSITO.md` §3, `DISEÑO.md` §4). El
   arco es piedra gris, así que sobre `casc_hueso` (crema), `casc_vidrio` (verde)
   o `casc_runas` sale un arco gris pegado a una campana que no lo es. Se ve
   compuesto: encaja con las cáscaras de piedra y canta con las otras.
3. **"La cáscara rueda, la criatura no" es imposible con este arte.** Al girar la
   cáscara, el arco que la criatura lleva pintado se queda quieto y la costura se
   parte al primer fotograma.

**La decisión, y es de Fátima:**

- **A — regenerar las nueve SOLAS.** Es lo recomendado, y es gratis *ahora*:
  las nueve hay que rehacerlas de todos modos para animarlas, así que el arreglo
  no cuesta ninguna hoja de más. Recupera la combinatoria y la rotación.
- **B — dar el "peek" por bueno.** Son nueve cascabeles completos y ya está: se
  cae el 81 y se cae la cáscara que rueda. Compuestas sobre las cáscaras de
  piedra se ven bien; es una salida honesta si A no sale a la primera.

**Se decide antes de generar, no después.** Lo de abajo está escrito para A.

### Cómo se le pasa la referencia si se va por A

No basta con adjuntar el PNG: hay que decirle qué parte tirar. La línea que lo
arregla, y va **antes** de las CRITICAL:

> The attached reference image shows this creature sitting inside a round stone
> bell, framed by a stone arch with a dark interior behind it. Use it ONLY for
> the creature itself — its shape, its colours, its face and its expression.
> **Discard the stone arch, the dark interior and the rim completely.** In the
> sheet, the creature must appear alone against the magenta, with nothing behind
> it and nothing around it.

Y el tamaño. **Aquí ponía que la criatura debía caber en 40×32 px "porque va
dentro de la cáscara", y eso ya no vale** (17-ago, ver el ⚠⚠ de abajo): la
criatura NO se dibuja nunca dentro de la cáscara. Se dibuja sola, a 64, en la
interfaz y en la caza. Así que ocupa la celda entera como cualquier otro sprite:

> The creature fills its cell the way the reference creature fills the opening in
> the reference image — same apparent size — but with nothing around it. Leave a
> 2 pixel margin of empty magenta on every side and nothing more.

### ⚠⚠ Y lo que zanja el asunto: en la mesa la bola mide 18 px

*Medido el 17-ago con el código delante, después de que Fátima preguntara si en
la ranura de los cascabeles cabía un peek.*

No cabe, y el motivo es más gordo que la ranura:

| Dato | Dónde sale | Valor |
|---|---|---|
| Radio de la bola | `sim/parametros_mesa.gd:12` | `radio_bola = 9.0` → **18 px** |
| Sprite y escala | `render/vista_mesa.gd:1340` | `bola.png` de 24, a escala 0,9 |
| Ranura de las cáscaras | medido sobre las nueve | **48 × 6 px** sobre celda de 64 |
| Esa ranura en la mesa | factor 0,28 | **13,5 × 1,7 px** |

> **A 18 px de una bola solo se lee el color y el patrón.** Cualquier sistema de
> dos capas —criatura dentro, ojos por la ranura, lo que sea— devuelve menos de
> dos píxeles. Se probó perforando la ranura y componiendo ojos debajo: a 8× queda
> bien y **a tamaño de mesa no existe**.

**Decisión de Fátima, 17-ago:**

- **Las nueve cáscaras se quedan como están.** Ruedan, y a 18 px identifican de
  sobra por color y patrón (bronce, hueso, óxido, verde y oro se distinguen).
  No se regeneran.
- **La criatura no se dibuja nunca sobre la bola.** Vive a 64 px en la interfaz
  —Preparación, `RECUPERADO/`, tooltips, el momento de capturar— y suelta por la
  planta alta durante la caza.
- **Las 81 combinaciones pasan a ser cosa de interfaz**: cáscara y criatura se
  eligen por separado y se componen en un panel a 64 px, donde hay sitio de
  sobra y no hay que meter nada por ninguna ranura.

Y de paso queda un argumento a favor de la caza que no teníamos: **es el único
momento del juego en que ves lo que estás coleccionando a un tamaño en el que se
lee.**

*Nota para quien retome esto: hoy no hay nada comprometido. `vista_mesa.gd:236`
carga `assets/mesa/bola.png` y ya está — ni `bolas_64/` ni `criaturas_64/` las
toca ninguna línea de código.*

**Y el mosaico de las nueve a 5× se monta ANTES de integrar**, que es lo que
cazó esto. Un PNG suelto en un visor no enseña que las nueve comparten arco.

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
> The attached reference image shows this creature sitting inside a round stone
> bell, framed by a stone arch with a dark interior behind it. Use it ONLY for
> the creature itself — its shape, its colours, its face and its expression.
> Discard the stone arch, the dark interior and the rim completely.
>
> CRITICAL: draw the creature ALONE. No ball, no bell, no sphere, no glass, no
> capsule, no arch and no circular outline of any kind around it, and no ground,
> no pedestal and no shadow under it. In the game this creature is drawn inside a
> separate shell sprite that is layered on top, so anything round you add here
> will be duplicated.
>
> CRITICAL: keep the creature at the same apparent size it has inside the opening
> of the reference image — do not enlarge it to fill the space left by the arch
> you removed. Leave a 2 pixel margin of empty magenta on every side.
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

### ⚠⚠⚠ LA REGLA QUE SALIÓ DE LA HOJA FALLIDA DE `cr_calavera` (17-ago)

Fátima generó `cr_calavera` con la descripción de más abajo y salió **otro
bicho**: sin manos, con una hoguera encima, con la silueta del cráneo cortada
por las llamas y con los dientes moviéndose.

**No es culpa del generador.** La descripción que había escrita era:

> *"a small skull with a flame burning behind its eye sockets"*

Y el sprite real de `assets/criaturas_64/cr_calavera.png` **no tiene fuego por
ningún lado**: medidos sus colores, son todos piedra y hueso —`3A3832`,
`55524A`, `7A7669`, `D9BF95`, `A88968`— y **cero rojos**. Es una calavera pálida
de cuencas vacías y negras con dos manos huesudas agarradas al borde.

Esa frase es del **enemigo `calavera_llameante`** de §1, no de la criatura.
Alguien escribió las nueve descripciones desde los identificadores en vez de
mirar los nueve PNG. Comprobadas una a una, **tres describen a otro bicho y tres
más se quedan a medias**.

> **LA REGLA: la descripción dice QUÉ SE MUEVE, no QUÉ ES.** Qué es lo dice la
> imagen de referencia. Cada adjetivo de aspecto que metas en el texto es una
> oportunidad de contradecirla — **y cuando texto e imagen se contradicen, gana
> el texto**. Ya ha pasado dos veces: "no bell" con una campana adjunta, y
> "flame burning" con una calavera sin fuego.

Lo único que el texto debe repetir del aspecto son **los rasgos que no se pueden
perder**, y por un motivo concreto: si no los nombras, el generador los quita.

### Las manos, que es un problema de los nueve

**Ocho de las nueve criaturas tienen manos o zarpas agarradas al borde del
arco.** Solo `cr_brasa` no las tiene, porque es fuego.

Y ahí está el motivo real de que la calavera saliera sin manos: **las manos son
parte de la pose de asomarse**. Al mandar tirar el arco, las manos se quedan
agarradas a nada y el generador simplemente las borra.

No hay que renunciar a ellas — hay que decir a qué se agarran:

> The creature's hands (or paws, or claws) must be kept exactly as in the
> reference: resting on the BOTTOM EDGE of the cell, fingers curled over it, as
> if it were leaning on a ledge. Do not remove them and do not redraw them
> hanging in the air.

Y encaja con el juego: en la caza la criatura está encaramada a la plataforma
central, que tiene borde. Agarrarse a un borde es la pose correcta.

### ⚠⚠⚠⚠ EL SUELO DE LEGIBILIDAD A 64 PX, Y LOS TRES NÚMEROS QUE LO FIJAN

*La segunda hoja de `cr_calavera` arregló el personaje —sin fuego, con manos,
silueta cerrada— y aun así **no vale**. Lo cazó Fátima mirándola: «píxeles fuera
de zona, dedos bug, mucho cambio de píxeles en la luz». Los tres, medidos:*

| Lo que vio | Medido | Por qué pasa |
|---|---|---|
| «mucho cambio en la luz» | **el 87 % del reflejo parpadea**: 172 px se encienden alguna vez y solo 23 en los ocho | la hoja usa **8 tonos de hueso** donde la guía pide 3. Con ocho tonos las fronteras se mueven un píxel por fotograma |
| «píxeles fuera de zona» | 116 px de tinta parpadean **en 22 manchas sueltas** por el borde | el contorno se redibuja entero cada fotograma |
| «dedos bug» | la banda de dedos es **UN bloque fundido** con 2 separaciones, donde debería haber dos manos | **aritmética**: ~10 dedos repartidos en 49 px son 4,9 px por dedo con su hueco |

**El tercero es el importante porque no es un fallo de dibujo, es un límite del
tamaño.** Y de ahí salen tres números que hay que meter en todo prompt de 64:

> - **Nada por debajo de 3 px de ancho se lee.** Un dedo de 2 px con un hueco de
>   1 px es una banda gris.
> - **Máximo 3 tonos por superficie**, que ya lo dice el bloque A y aquí se
>   incumplió. Cada tono de más es una frontera más que puede temblar.
> - **Un reflejo especular es una FORMA FIJA**, no una zona que se redibuja.

Traducido a líneas de prompt:

> The creature must read at 64 pixels. Use exactly THREE tones for the bone
> plus one dark outline, and nothing else — no extra shading tones, no gradients
> between them.
>
> The highlight is a FIXED shape in a FIXED position, pixel-identical in all
> eight frames. Do not redraw it, do not move it and do not resize it.
>
> The creature has TWO clearly separate hands, one on each side, with an empty
> gap between them. Each hand has only THREE thick fingers, each finger at least
> 3 pixels wide with a 1 pixel gap. Do not draw more fingers: at this size they
> merge into one solid bar.

**Y la regla vale para CUALQUIER detalle repetido, no solo para los dedos.** La
tercera hoja de `cr_calavera` arregló las manos —tres dedos gruesos, dos manos
separadas, medido y correcto— **y trasladó el fallo a los dientes**: 10 a 13
dientes con anchuras de `[4, 2, 1, 7, 3, 3, 6, 2, 3, 3, 1]`. La regla estaba
escrita nombrando los dedos, y lo que no se nombra no se aplica.

> Any repeated detail — teeth, fingers, ribs, spikes, whiskers, scales — must be
> at least 3 pixels wide with a 1 pixel gap. Count them: prefer FEWER and
> CHUNKIER. Five teeth read; twelve teeth are a grey smear.

**La cuenta que hay que hacer antes de pedir el prompt:** ancho disponible en
píxeles ÷ 4 = número máximo de repeticiones. Una boca de 30 px admite **siete
dientes como mucho**, y quedan mejor cinco.

*Y probado y descartado como arreglo: congelar el cráneo desde la herramienta
(`anim.py --congelar-arriba 38`). Deja el cráneo como una roca y baja el cambio
por fotograma de 333 a 207 px — pero entonces **lo único que se mueve son los
dedos**, o sea que le da todo el protagonismo a lo peor dibujado. Una hoja mala
no se salva post-procesando.*

### Las tres CRITICAL que faltaban

Cada una viene de un fallo de la hoja de `cr_calavera`:

> CRITICAL: the creature's silhouette must be CLOSED and COMPLETE in every
> frame. Nothing may cover, cut or overlap its outline — no flames, no smoke,
> no effect crossing in front of it. If part of the body is hidden the sprite
> reads as unfinished.
>
> CRITICAL: ONLY the parts named below may change between frames. Everything
> else — head, body, teeth, hands, outline — must be pixel-identical in all
> eight cells. Do not redraw the whole creature each frame.
>
> CRITICAL: do not add anything that is not in the reference image. No fire, no
> smoke, no sparks, no aura, no props and no background elements unless the
> reference already has them.

La segunda es la que arregla los dientes que bailan, y es **comprobable**:
`anim.py` saca un mapa de movimiento que enseña exactamente qué píxeles cambian
a lo largo del bucle. Si se ilumina la mandíbula, la hoja está mal.

### Las nueve descripciones, REESCRITAS MIRANDO LOS PNG

Cada una en dos partes: **lo que no se puede perder** (para que el generador no
lo borre) y **lo único que se mueve**.

| Criatura | Lo que es de verdad, y no se puede perder | Lo único que se mueve |
|---|---|---|
| `cr_brasa` | *a small live flame with two bright round eyes inside it; the flame IS the creature and it has no body and no hands* | *it leans, gutters and flares as if in a draught — the eyes stay level while the fire moves around them* ✅ *(la única que ya estaba bien: es la hoja que salió buena)* |
| `cr_calavera` | *a pale bone skull with EMPTY BLACK eye sockets and no fire anywhere, a row of square teeth, and TWO BONY HANDS with separated fingers resting on the bottom edge* | *only the jaw and the tiny highlights: it opens its jaw slightly and closes it again. The cranium, the sockets, the teeth and the hands do not move* |
| `cr_diablillo` | *a grey cat-like gargoyle creature with LARGE POINTED EARS, huge round yellow eyes, a short muzzle, and two grey clawed paws on the bottom edge. It has NO horns and NO grin* | *only the ears and the eyes: the ears flick on different frames and it blinks once during the loop* |
| `cr_espectro` | *a bright VIOLET blob-like creature with THREE white round eyes of different sizes and thin violet tendrils coming off it. It is NOT hooded and has no cloak* | *only the tendrils and the eyes: the tendrils curl and uncurl, and the three eyes blink out of sync* |
| `cr_gusano` | *a fat pale segmented grub with a ROUND MOUTH FULL OF SMALL TEETH and two small pale hands on the bottom edge* | *only the body segments: it compresses and extends along its length, the segments moving in sequence rather than all at once. The mouth and the hands stay put* |
| `cr_musgo` | *a grey STONE FACE covered in green moss and yellow lichen, with heavy half-closed golden eyes and two stone hands on the bottom edge* | *only the moss and the lichen: tufts sway at slightly different rates. The stone face itself does not move at all* |
| `cr_rata` | *a dark grey dungeon rat with LARGE BROWN EARS, RED eyes, pale whiskers and two brown paws on the bottom edge* | *only the nose, the whiskers and the ears: they twitch and flick, and it blinks once. The head and the paws stay still* |
| `cr_sapo` | *a grumpy green toad with heavy drooping eyelids over yellow eyes and two green hands on the bottom edge* | *only the throat and the eyelids: the throat swells and settles, and the lids droop lower and lift again* |
| `cr_sombra` | *a very dark blot of living shadow with two small pale eyes and ONE THIN VIOLET CRACK across it* | *only the outline and the crack: the silhouette creeps and shifts so it is never twice the same, keeping the same overall mass, and the violet crack flickers* |

**`cr_sombra` es la única que se corta con `--con-arcano`**, porque su grieta
violeta es arte, no halo. `cr_espectro` es violeta entero, así que también.
Las otras siete van con el arcano fuera.

### Después de generar — y NO es `procesar.py`

    python3 anim.py hoja.png --n 8 --tam 64 --salida assets/criaturas_anim/cr_brasa/

*Aquí ponía `procesar.py --tam 64 --tira 8 --filas 1`. **Se ejecutó el 17-ago
sobre la hoja de verdad y no vale**, por dos motivos que solo salen midiendo.*

**1. El recorte por silueta sí había que evitarlo, y `--tira` lo evita.** Eso
estaba bien visto: por defecto `procesar.py` saca cada fotograma con la caja de
su propio dibujo y la criatura salta de sitio y de tamaño. Es la misma avería
que descuadró los marcos de nueve trozos.

**2. Pero `--tira` parte la hoja ENTERA en N columnas iguales, y da por hecho
que el generador centró cada fotograma en su columna.** No lo hace. Medido sobre
la hoja de `cr_brasa`: las bases de las llamas caen a **15,6 / 9,1 / 7,2 / 6,8 /
4,1 / 0,1 / −4,0 / −9,3 px** del centro de su celda. Son **24,9 px de recorrido
= 7,5 px a tamaño 64**, o sea un baile bien visible.

`anim.py` hace las tres cosas que una tira necesita y que `--tira` no da:

| | Qué hace | Por qué |
|---|---|---|
| **Vertical** | ventana común anclada a la línea de suelo | la animación no puede flotar |
| **Horizontal** | centra cada fotograma en el **centroide de su base** (el 25 % inferior de la tinta) | mata la deriva del generador y **conserva** el movimiento de las puntas, que es el que se ha pedido |
| **Escala** | una sola, del fotograma más alto | si no, el más bajo se estira para llenar la celda |

Y de paso avisa por consola de lo que no se ve mirando: cuánto cambia cada
fotograma respecto al siguiente. En `cr_brasa` cambian de 440 a 1.159 px de
4.096 — hay animación de verdad, no ocho copias.

`procesar.py` se queda para todo lo demás: iconos sueltos, hojas 3×3, la mesa.

### El arcano que se cuela y no da ningún error

La hoja de `cr_brasa` salió con **61 px de violeta arcano** en una criatura de
fuego, y `CONTEXTO.md` dice que el arcano es EL color mágico y va con
cuentagotas. No es que la IA lo dibujara: **es el halo del fondo**.

El fondo magenta no acaba de golpe. Deja un borde a **315° de tono** cuando el
fondo está a 299,8°, y `procesar.py` corta el fondo a 14° — así que ese halo
sobrevive como si fuera dibujo, y al cuantizar un magenta lavado cae en el
violeta.

**Ensanchar el margen de tono no lo arregla**, y está medido: de 14° a 28° el
arcano baja de 5.585 px a 833 y de paso se lleva por delante 5.943 px de llama.
El halo degrada hasta el rojo, no hay corte limpio.

Lo que sí lo arregla: **`anim.py` saca los dos violetas de la paleta por
defecto**, así que ese halo cae al rojo más cercano — que es exactamente lo que
debe ser el borde de una llama. Medido: 61 px → **0**.

Se apaga con `--con-arcano` para `cr_espectro` y `cr_sombra`, que sí pueden
llevarlo a propósito. **Para las otras siete, no se toca.**

Y **guardar la hoja** en `Desktop\Sprites` con su fila en `INVENTARIO_HOJAS.md`.
De las tandas sin hoja guardada —`criaturas_64`, `bolas`, la cáscara— no hay
original, así que esos sprites solo se pueden reparar, no rehacer.

### La batería de revisión: `revisar.py`

*Escrita después de dar por buena una hoja mala contando píxeles.*

    python3 revisar.py assets/criaturas_anim/cr_calavera/

Siete pruebas, y las siete salen de un fallo que ya ha pasado:

| # | Qué mide | Salta cuando |
|---|---|---|
| 1 | **Tonos** | más de 4 tonos de cuerpo: cada uno de más es una frontera que tiembla |
| 2 | **La luz** | más del 40 % del reflejo parpadea |
| 3 | **Silueta** | más de 8 manchas de tinta apareciendo y desapareciendo por el borde |
| 4 | **Tamaño** | el bicho cambia de ancho o alto, o la línea de suelo baila |
| 5 | **Dónde se mueve** | reparte el movimiento por bandas, para contrastarlo con lo que pedía el prompt |
| 6 | **Detalle fino** | hay trazos de menos de 3 px |
| 7 | **Cierre del bucle** | el salto del último al primero es el mayor: se ve el tirón |

**Ojo con la 2 y la 4 en bichos que cambian de forma a propósito.** En
`cr_brasa` la llama crece 15 px y el reflejo se mueve con ella: ahí saltan y no
es un fallo. La batería no sustituye al criterio, ordena dónde mirar.

**Y no sustituye a mirar la hoja a 10× fotograma a fotograma**, que es lo que
cazó las tres hojas malas. Lo dice ella misma al acabar.

### Cómo mirarlo antes de meterlo en el juego

El mosaico de prueba que ya está en `CLAUDE.md`, pero para animación: montar los
8 fotogramas **en fila y a tamaño real**, y encima la misma fila a 4×. A tamaño
real se ve si el movimiento existe; a 4× se ve si el contorno está en rejilla.
Los dos fallos que ha tenido esta clase de hoja —fotogramas casi idénticos y
silueta redondeada— se ven ahí y no se ven dentro de Godot hasta mucho después.

---

## 5. La criatura como PRESA — la hoja de la caza

*Escrita el 17-ago-2026 con `CAZA.md`. **Esta hoja no existía**, y con ella se
cae la frase "la captura no cuesta ni un fotograma nuevo": sí cuesta, una hoja
por criatura, y conviene saberlo antes de prometer nada.*

**Las nueve criaturas tienen DOS papeles y necesitan DOS hojas.** Es lo que no
estaba visto:

| Papel | Dónde | Qué necesita | Estado |
|---|---|---|---|
| **Pasajera** — dentro de tu cascabel | la bola, todo el run | `idle` y nada más: el squash y el giro los hace el código | **§4, escrita y lista** |
| **Presa** — suelta en la planta alta | la caza (`CAZA.md`) | reacciona: se asusta, huye, se rinde | **esto** |

La de §4 se genera **ya**. Esta va **detrás de la puerta B de `CAZA.md` §5**: si
la planta alta no se siente distinta jugándola sin bichos, esta hoja no se genera
nunca y no se ha perdido nada.

### Los cuatro estados, y por qué son los mismos cuatro de un enemigo

Los de `CAZA.md` §2 caen casi encima de los de §1, así que **la plantilla del
enemigo vale tal cual**, cambiando la celda de 96 a 64:

| Fila | En un enemigo | En la caza | Qué pasa en la mesa |
|---|---|---|---|
| 1 | `idle` | **acecho** | está suelta y no la has tocado |
| 2 | `golpe` | **susto** | le has dado: sube el MIEDO |
| 3 | `ataque` | **huida** | se revuelve y se va a un túnel |
| 4 | `muerte` | **rendida** | miedo lleno: la ventana de captura |

La única fila que **no** se puede copiar es la 3. En un enemigo el ataque va
*hacia* el jugador; una presa se va *al revés*. Se cambia el párrafo:

> Row 3 — FLEEING, a 4-frame turn-and-bolt: flinching away · turning its back ·
> mid-scramble, low to the ground · almost out of frame but still fully inside
> its cell. It moves AWAY from the viewer, never toward it.

Y la 4 tampoco es una muerte: **la criatura no se muere, se rinde.** Es un juego
de coleccionar, y una presa que agoniza al capturarla dice lo contrario de lo que
quiere `PROPÓSITO.md`:

> Row 4 — GIVING UP, a 4-frame surrender: legs folding · sinking down · curled
> up small and still · the same, eyes closed. It is exhausted and it submits —
> it is NOT dying, NOT bleeding and NOT falling apart. Do not fade it out.

Las otras dos filas se copian de §1 sin tocar nada.

### Formato

**4×4, celda 64, la misma que §4.** No 96: la presa se ve sobre una planta alta
de 400 px de ancho y el enemigo se ve en su panel de la banda derecha.

    python3 procesar.py hoja.png --tam 64 --tira 4 --filas 4 \
        --salida assets/criaturas_caza/cr_brasa/ \
        --nombres "acecho_1,acecho_2,acecho_3,acecho_4,susto_1,susto_2,susto_3,susto_4,huida_1,huida_2,huida_3,huida_4,rendida_1,rendida_2,rendida_3,rendida_4"

**Y aquí SÍ se dibuja sola de verdad**, sin arco y sin cáscara: en la caza la
criatura está suelta por la mesa, no dentro de nada. O sea que la corrección del
apartado ⚠ de §4 vale igual, y con más motivo.

### La que no hace falta dibujar

**El rastro (`CAZA.md` §2, fase 1) no lleva arte de criatura.** Es una sombra que
cruza por debajo del tablero y partículas. Se dibuja con lo que ya hay, y es la
fase más barata de las cuatro — conviene que siga siéndolo.

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
| 1 | **`cr_brasa` animada** (§4) | ya | Es el piloto y el caso más difícil. Y sin criaturas no hay coleccionable, que es el gancho de `PROPÓSITO.md` §2. **Leer antes el ⚠ de §4: la referencia lleva un arco de piedra que hay que mandar tirar explícitamente** |
| 2 | **Las otras 8 criaturas** (§4) | tras validar la 1 | Trámite si la 1 sale bien. Si no, se cambia el prompt antes de gastar ocho hojas |
| 2b | **`cr_brasa` como presa** (§5) | **solo tras la puerta B de `CAZA.md` §5** | Si la planta alta no se siente distinta sin bichos, esta hoja no se genera y no se pierde nada |
| 2c | **Las otras 8 presas** (§5) | tras validar la 2b | |
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
