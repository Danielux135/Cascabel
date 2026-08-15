# GUIA_ESTILO.md — el prefijo que hay que pegar antes de cualquier prompt

`prompts_animacion.md`, `prompts_cascara.md` y `prompts_reliquias.md` empiezan
todos por *"Following the style guide above"*. Durante un tiempo esa guía no
estaba escrita en ninguna parte del repo: vivía en una pestaña abierta, y sin
ella ninguno de los prompts generaba lo que decía generar. **Aquí está, y es la
de verdad**: la que Fátima usó y la que produjo el arte que ya está integrado.

**Cómo se usa:** se pega el BLOQUE A entero, después el BLOQUE B, y después el
prompt de la hoja concreta. Nada más.

---

## BLOQUE A — el original

**Esto no se toca.** Es lo que ha generado todo lo que hay en el repo, así que
cualquier hoja nueva que empiece por otra cosa va a desentonar con lo que ya
está. Se pega tal cual, en inglés.

> I am making sprites for a pixel art roguelike in the style of Peglin:
> chunky cartoon dungeon fantasy, thick dark outlines, exaggerated silhouettes,
> readable at small size.
>
> For every image: one single subject, centered, filling a square frame, on a
> flat solid magenta #FF00FF background. Nothing else — no ground, no cast
> shadow, no scenery, no frame, no border, no text, no watermark.
>
> Palette: cold neutral greys for iron and steel, copper and brass for
> mechanisms, warm browns and parchment for leather, wood and rope, muted
> greens, and violet used only for magic. Keep everything muted, not saturated.
>
> Light comes from the upper left. Maximum three tones per surface. Keep the
> shading blocky. Design every sprite to stay readable at 64 pixels.

### Por qué funciona, para no estropearlo al tocarlo

- **"in the style of Peglin"** es la línea que más trabaja de todo el prompt. Una
  referencia con nombre le da al generador la silueta, el grosor de contorno y el
  registro de humor de golpe; diez líneas describiéndolo no llegan.
- **"Maximum three tones per surface"** es una restricción dura y comprobable, y
  es lo que impide que salga arte con degradado disfrazado de pixelart.
- **La paleta va EN PALABRAS y no en códigos hex, y así se queda.** Un generador
  no acierta un hex exacto casi nunca, y `procesar.py` cuantiza a los 33 colores
  después de todas formas: meter los códigos no mejora el resultado y gasta
  atención del generador en algo que ya está resuelto aguas abajo.
- **"readable at 64 pixels"** es el tamaño real de casi todo. Los iconos de
  reliquia además se ven a 32, y por eso su prompt lo repite más fuerte.

---

## BLOQUE B — las tres líneas que le faltan

Cada una viene de un fallo que ya ha pasado y está anotado en `CLAUDE.md`. Se
pegan justo detrás del bloque A.

> IMPORTANT, in addition to the above:
>
> Do not use magenta, hot pink or fuchsia anywhere in the artwork itself. The
> magenta background is cut away automatically by hue, so a magenta-leaning
> colour on the subject gets deleted and leaves a hole in it. The violet used
> for magic must be clearly a violet — shifted well away from magenta in hue and
> lower in saturation — never a pink-leaning one.
>
> Hard pixel edges only: no antialiasing, no semi-transparent pixels, no
> feathering, no gradients, no blur and no glow bleeding onto the magenta. The
> contour must be ANGULAR and follow the pixel grid, with stepped diagonals — not
> a soft rounded silhouette. Do not draw it large and smooth and then shrink it.
>
> When the image is a grid or a strip of cells, all cells are exactly the same
> size, edge to edge, with NO gaps, margins, borders, separator lines, numbering
> or labels anywhere on the image.

### Qué arregla cada una

**1. El magenta.** Tu guía dice *"violet used only for magic"* y el fondo es
`#FF00FF`. Son el mismo tono, y ese choque es el bug del espectro: `procesar.py`
medía distancia RGB al magenta y cortaba a 95, y un violeta saturado del dibujo
—(156,5,197), la llama de la calavera, el cuerpo del espectro— cae a 88. **El
espectro perdió el 22 % del cuerpo** y no daba ningún error ni se veía en un
visor. El script ya detecta el fondo por TONO y no por distancia, así que la
avería está tapada por abajo; esta línea la tapa también por arriba, que es más
barato que reparar el sprite después.

**2. El contorno.** Es lo que salió de tu propia exploración del cascabel de
fuego, y está en `ESTADO.md` con estas palabras: *"el contorno redondeado no es
ruido —es la silueta que dibujó la IA—, así que limpiar no lo arregla"*. Un
contorno suave no se puede reparar con un script: hay que volver a generar. Esta
línea es lo único que lo evita antes de gastar la hoja.

**3. Las celdas.** Al trocear las hojas de nueve trozos, **una hoja traía las
celdas separadas por huecos de magenta** en vez de pegadas, así que dividir la
imagen en tercios iguales cortaba mitad celda y mitad hueco. No da error: deja el
marco descuadrado. En una animación es peor todavía, porque el bicho salta de
sitio a cada fotograma.

---

## La hoja que generó `assets/mesa/`

Guardada aquí porque `INVENTARIO_HOJAS.md` dice que de la tanda del 9 de agosto
*"no hay mapeo hoja-a-hoja detallado"*. De esta sí, y los nueve objetos cuadran
uno a uno con los ficheros que hay en el repo:

> Following the style guide above, create a 3x3 grid of 9 separate pinball
> table objects on a flat magenta #FF00FF background. Even spacing, each object
> centered in its own cell, all nine drawn at the same scale.
>
> CRITICAL: every object is seen from DIRECTLY ABOVE, straight top-down, like
> looking down at a table from the ceiling. No perspective, no three-quarter
> angle, no sides visible, no horizon.
>
> The nine objects are:
> 1. a round bumper shaped like a carved stone gargoyle face
> 2. a round bumper shaped like a rusted iron gear with a lit center
> 3. a standing target shaped like a small stone tombstone
> 4. a drop target shaped like a wooden shield with iron bands
> 5. a short round post with a red rubber ring around it
> 6. a circular hole in the table with a dark iron rim, like a drain
> 7. a spinning metal blade on a horizontal axle
> 8. a rectangular lit arrow panel, glowing amber
> 9. the same rectangular arrow panel, unlit and dark grey

| # | Objeto | Fichero |
|---|---|---|
| 1 | gárgola | `mesa/bumper_gargola.png` |
| 2 | engranaje | `mesa/bumper_engranaje.png` |
| 3 | lápida | `mesa/target_lapida.png` |
| 4 | escudo | `mesa/target_escudo.png` |
| 5 | poste | `mesa/poste_goma.png` |
| 6 | drenaje | `mesa/drenaje.png` |
| 7 | girador | `mesa/girador.png` |
| 8 | flecha encendida | `mesa/flecha_on.png` |
| 9 | flecha apagada | `mesa/flecha_off.png` |

### ⚠ Y de aquí sale una pregunta de estilo que no es mía

**Esta hoja pide perspectiva CENITAL PURA. El resto del juego no.**

`CONTEXTO.md`, "Perspectiva", dice: *"Los objetos se dibujan mirando al jugador,
como los sprites de un RPG cenital. El suelo se ve desde arriba, los objetos
están de pie hacia la cámara. **No es cenital puro, y es a propósito**: es lo que
hace Peglin y es más legible."*

Y este prompt dice, en mayúsculas: *"seen from DIRECTLY ABOVE... no
three-quarter angle, no sides visible"*. O sea que **los objetos de mesa están
dibujados en una perspectiva y todo lo demás en otra**.

No lo doy por bueno ni por malo, porque es defendible: un bumper de una máquina
real SÍ se ve desde arriba, y el suelo también. Pero conviene decidirlo antes de
generar la siguiente hoja de mesa —que `PROPÓSITO.md` §8 va a pedir: pines,
segundo racimo, postes de outlane— porque el arte nuevo tiene que ir en la misma
que el que se quede. **Es decisión de Fátima.** Lo único que no puede pasar es
que la mesa tenga las dos.

Dato suelto que puede ser pista o casualidad: de los objetos de esta hoja,
`target_lapida` y `target_escudo` no los carga nadie, y `ESTADO.md` da un motivo
distinto para esos dos (el canto del target es un dial vivo y se dibuja por
código). De los otros no dice nada.

---

## Notas de mantenimiento

- **Si cambia `render/paleta.gd`, aquí no hay que tocar nada** — y eso es a
  propósito, porque el bloque A describe la paleta con palabras. Es una ventaja
  de la guía original que conviene no perder al editarla.
- **`assets/ui/` está al 100 % fuera de la paleta de 33 y no es un fallo.** Los
  marcos, la barra, el botón, el título, el tooltip, el diálogo y la barra de
  progreso los genera `fuente.py` con los grises de Windows, que son la identidad
  de la cáscara. **El criterio no es la paleta, es quién generó el asset.**
- **Guardar la hoja siempre**, en `C:\Users\Daniel\Desktop\Sprites`, con su fila
  en `INVENTARIO_HOJAS.md`. De `criaturas_64`, `bolas` y la cáscara no hay
  original, así que esos sprites solo se pueden reparar, no rehacer.
