# Prompts para las CANCIONES — los ficheros que ya estaban en el disco

`prompts_musica.md` son **diez piezas instrumentales que se repiten mientras
juegas**. Esto es otra cosa y por eso es otro documento:

> **Una canción de este juego no es música de fondo: es un ARCHIVO.** Está en el
> disco de la máquina, tiene nombre, se puede abrir, y alguien la puso ahí antes
> de que tú llegaras.

**DECISIÓN (19-ago): ninguna pieza de audio del juego lleva voz, ni canto ni
voz de muestra, tampoco estas.** Se probó con voz —letra en castellano, muestra
de 8 bits, tarareo, anuncio hablado— y se descartó. La categoría CANCIONES se
mantiene: siguen siendo ficheros que el jugador encuentra y abre en `MUSICA/`,
no bucles de fondo, pero **puramente instrumentales**, igual que el resto de la
banda sonora. Ver el invariante en `CLAUDE.md`.

Eso no es un adorno de ambientación, es lo que resuelve dos problemas a la vez:

1. **Justifica que TERMINEN.** Todo `prompts_musica.md` pelea contra Suno para
   que no cierre las piezas. Aquí no hay que pelear: **la única música de este
   juego a la que se le permite acabar es la que ya estaba acabada antes de que
   llegaras.** Suno hace piezas que terminan; aquí eso deja de ser un defecto y
   pasa a ser el sentido.
2. **Es historia sin guion.** `DISEÑO.md` §3 —cero cinemáticas, cero diálogo— y
   `PROPÓSITO.md` §2 —desbloqueos que son *"piezas rescatadas de la memoria antes
   de que el reinicio las borre"*. Una pieza **es** un fragmento rescatado, y lo
   que cuenta lo cuenta la forma —qué instrumento, qué se corta, qué falta—, no
   una letra.

Van en `MUSICA/`, una carpeta del escritorio falso, con su reproductor cutre.

---

## 1. La idea que hay que leer antes que los prompts

**La pieza de los cascabeles se desbloquea POR TRAMOS.**

Es un carrillón de contar, sin palabras. Nueve cascabeles, nueve motivos
musicales cortos —uno por cascabel, cada uno con su propio timbre— y el
reproductor **solo toca los tramos de los cascabeles que tienes**. Al
principio la pieza dura poco y tiene huecos; al final suena entera.

Lo que eso da, que es mucho para lo que cuesta:

- **Un desbloqueable que no es un número.** `DISEÑO.md` §13 lleva desde el
  principio queriendo meta-progresión que no sea "+3 % de daño"; esto es una cosa
  que **crece y se oye crecer**.
- **Un contador de colección que no es una lista.** Sabes cuántos te faltan
  porque la pieza tiene agujeros. No hace falta ninguna interfaz.
- **Coste de producción cero.** Se genera la pieza **entera, una vez**, y se
  corta por tramos. Nueve trozos de un OGG y un array de booleanos.
- **Y el remate, sin decir una palabra:** el noveno tramo —el del cascabel de
  runas— no es un motivo más: es la primera vez que suena un instrumento que no
  ha sonado en los ocho anteriores, respondiendo al motivo que se repite entre
  grupos de tres. Antes de tenerlo, la pieza calla ahí. Después, contesta.

Si de este documento solo se hace una cosa, es esta.

---

## 2. Cómo se pide una pieza-archivo, que no es como se pide un bucle

| | las diez piezas | las CANCIONES |
|---|---|---|
| bloque **T** (timbre) | sí, siempre | **sí** — es lo que las hace del mismo juego |
| bloque **L** (bucle) | sí, siempre | **NO.** Estas terminan |
| `instrumental` | sí | **sí, siempre** — ninguna lleva voz |
| BPM exacto | imprescindible | útil pero no crítico |
| dónde se decide | el prompt de estilo | **la estructura por secciones**, sobre todo |

**El bloque T se sigue pegando**, recortado a lo que cabe en el cuadro de estilo:

> 1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, cheap General MIDI
> patches, tracker module, slightly detuned, lo-fi 22 kHz, dry and close

Y **dos reglas propias**, que salen de las del documento de música traducidas
a pieza-archivo:

1. **Nada resuelve, salvo una: `cascabel_sa`.** Pueden terminar —eso es lo que
   las hace archivos— pero terminan **cortándose o apagándose**, no cerrando.
   En el prompt: `ends without resolving, no final cadence`. La única
   excepción está justificada en su propio apartado (§5).
2. **Sin voz, sin excepción.** `instrumental, no vocals` va en todos los
   prompts de estilo, igual que en `prompts_musica.md`. Ninguna melodía se
   escribe pensando "aquí cantaría algo": se escribe para un instrumento.

---

## 3. `los_nueve_cascabeles` — LA pieza · 84 BPM

La que pidió Fátima. Un carrillón de contar, de los de niños, y **por eso
funciona sin palabras**: una caja de música contando cosas que desaparecen da
más mal rollo que cualquier tema de terror, porque el timbre dice "esto es
inofensivo" y la estructura —un motivo que se apaga y no vuelve— dice lo
contrario. Es la misma regla del documento de música —*no da miedo, da mal*—
con otra ropa.

### El estilo

> 1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, cheap General MIDI
> patches, tracker module, slightly detuned, lo-fi 22 kHz, dry and close,
> lo-fi children's music box carillon from a 1990s PC game, detuned celesta and
> glockenspiel, sparse, slow, 84 BPM, minor key, warm and wrong, tape wobble,
> no lead melody sustained for long, each phrase played by a different small
> percussive instrument, instrumental, no vocals, ends without resolving, no
> final cadence

### La estructura

Nueve tramos cortos de dos compases, uno por cascabel, **más un motivo de tres
notas que se repite cada tres tramos** a modo de estribillo instrumental. La
estructura es así a propósito: el corte por tramos de §1 tiene que caer en
frontera de compás y sin cortar el motivo repetido.

```
[Intro] [Music box, solo]

[Section 1] [Detuned celesta, single note motif]
[Section 2] [Muted glockenspiel, descending]
[Section 3] [Hollow FM bell, two notes]

[Recurring motif] [Three-note chime, repeated]

[Section 4] [Low wooden block, dry]
[Section 5] [Glass-like FM tone, fragile]
[Section 6] [Detuned low bell, hollow]

[Recurring motif] [Three-note chime, repeated]

[Section 7] [Metallic scrape, short]
[Section 8] [Bright detuned bell, thin]
[Section 9] [A NEW instrument that has not played before, answering the
recurring motif]

[Outro] [Fading, unresolved]
```

**Cada cascabel tiene su timbre**, siguiendo el mismo material que ya describe
`DISEÑO.md`: acero, hierro, bronce, piedra, vidrio, hueso, óxido, plata y, el
noveno, runas. El instrumento del tramo 9 es el único que no suena en ningún
otro sitio del carillón —es lo que hace de "el noveno estaba vacío hasta que
llegaste" sin necesitar una frase.

### Cómo se corta

Se genera entera y se parte en nueve trozos por frontera de compás. A 84 BPM el
compás dura `60/84 × 4 = 2,857 s`, así que **todos los cortes válidos están en
múltiplos de 2,857 s**. Cortar a ojo produce el clic de siempre
(`prompts_musica.md` §2, capa 2).

El motivo recurrente y la intro **no se cortan**: van siempre. Lo que se
enciende y se apaga son los nueve tramos, y con un cascabel de menos lo que
suena en su sitio es **silencio de esa duración**, no el motivo de otro
cascabel adelantado. Un hueco en el carrillón se lee como una pieza sin
terminar, que es justo lo que es.

---

## 4. `sin_titulo` — la que se quedó a medias · 68 BPM

**La pieza que justifica el juego, en versión corta.** `recuperado.ogg` ya hace
esto —una melodía que no llega a su última nota—; esto es su hermana pequeña, y
la diferencia está en el instrumento, no en una voz: aquí toca **un solo
instrumento, sin acompañamiento**, y se para antes de terminar la frase.

Alguien estaba escribiendo una melodía para su juego y se fue a mitad.

### El estilo

> 1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, cheap General MIDI
> patches, tracker module, slightly detuned, lo-fi 22 kHz, dry and close,
> unfinished demo recording, a single detuned music box playing alone, no
> other instruments, no pad, no accompaniment, 68 BPM, minor, fragile,
> melancholy, instrumental, no vocals, the melody stops mid-phrase, no ending,
> no final cadence

### La estructura

```
[Melody] [Detuned music box, solo, alone]

[Melody continues, same phrase repeated with small variation]

[Cuts off mid-phrase]
```

**No lleva acompañamiento y ese es el contenido.** El fichero se llama
`sin_titulo` porque no le puso título; suena un solo instrumento porque nadie
más llegó a escribir su parte. Cuando el jugador abre esto en `MUSICA/` y oye
una caja de música sola parándose a media frase, sabe todo lo que hay que
saber de quién estuvo aquí antes.

**Se corta a mitad de frase, a mano, en el editor.** Suno va a cerrarla; hay
que quitarle el final. Es la única pieza del proyecto, junto con `recuperado`,
donde el recorte no es limpieza: es el efecto.

---

## 5. `cascabel_sa` — el anuncio de fábrica · 132 BPM

**Antes de que alguien la convirtiera en una mazmorra, esto era una máquina de
pinball**, y una máquina de pinball de 1994 venía con su jingle de
demostración. Está en el disco desde entonces, y es **lo único alegre del
juego entero**.

Que es exactamente por lo que hay que hacerla: la banda sonora es oscura de
principio a fin, y **una cosa oscura al lado de otra cosa oscura no da miedo,
da monotonía**. Lo que hace que la máquina dé mal rollo es que se le oiga lo
que fue.

### El estilo

> 1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, cheap General MIDI
> patches, tracker module, slightly detuned, lo-fi 22 kHz, dry and close,
> 1994 arcade pinball attract mode jingle, bright major key, cheesy FM brass
> stabs, slap bass, tacky drum machine, upbeat corporate advertising music, a
> simple hummable lead hook played on bright FM bells, instrumental, no
> vocals, no announcer, short, confident, ends on a clean chord

### La estructura

```
[Intro] [Bright FM brass stab, single hit]

[Hook] [Bells play the jingle's melodic hook, upbeat]

[Hook repeats, slightly fuller arrangement]

[Outro] [Clean major chord, held]
```

El gancho de campanas hace el trabajo que antes hacía la voz: **una melodía
tan simple que se tararea sola**, sin que nadie la cante. La broma de fábrica
—una máquina de pinball feliz escondida dentro de una mazmorra— sigue
funcionando por el contraste de timbre con el resto de la banda sonora, no por
un eslogan.

**Es la única pieza del proyecto que SÍ resuelve** (`ends on a clean chord`),
y eso también es contenido: la única música terminada de esta máquina es la
que venía de fábrica.

---

## 6. `nana` — para dormir a la bola · 52 BPM

La más corta y la más incómoda. Una nana sin nadie que la cante: **solo la
caja de música, muy sola, en una mesa que ya no tiene a nadie encima**.

Encaja donde `PROPÓSITO.md` §5 pone MODO SEGURO y donde la cáscara se queda
quieta: es lo que la máquina pone cuando cree que ha terminado.

**Nota (19-ago): el primer intento —con voz— se descartó por completo. Esta
versión sustituye a la anterior, no la complementa.**

### El estilo

> 1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, cheap General MIDI
> patches, tracker module, slightly detuned, lo-fi 22 kHz, dry and close, slow
> lullaby, detuned music box alone, no other instruments, 52 BPM, minor,
> tender and wrong, very sparse, long silences between phrases, instrumental,
> no vocals, ends by fading out mid-phrase, no final cadence

### La estructura

```
[Phrase] [Music box, very slow, sparse]

[Long silence]

[Phrase] [Same melody, quieter]

[Long silence]

[Fades out mid-phrase]
```

Los silencios largos son el contenido, no un hueco de producción: una nana sin
nadie a quien cantársela se para a escuchar si hay alguien, y no hay nadie.

---

## 7. Orden, y lo que NO hay que hacer

**El orden**, y el motivo de cada sitio:

1. **`los_nueve_cascabeles`.** Es la que pidió Fátima, la que trae el
   desbloqueable de §1 y la única que cambia cómo se juega. Va primera y **se
   genera antes de decidir cómo se corta**: si la pieza no vale, el sistema de
   tramos no vale.
2. **`sin_titulo`.** Corta, barata, y es la que dice si el tono se sostiene sin
   acompañamiento. Va después de `recuperado.ogg` para que se puedan comparar
   de oído.
3. **`cascabel_sa`.** La de mayor riesgo y mayor premio. Si sale bien, la
   máquina tiene pasado.
4. **`nana`.** La última, porque solo tiene sentido cuando las otras tres han
   fijado el tono.

**Lo que NO hay que hacer:**

- **No meterlas en la mesa.** Estas no suenan mientras juegas, ni de fondo, ni
  agachadas. Suenan cuando el jugador abre un fichero. En cuanto una suena
  encima de una bola, deja de ser un archivo y pasa a ser música de menú.
- **No usar la Persona de `combate`.** Las diez piezas se generan desde ahí para
  que suenen a la misma banda sonora; estas **son de otra época y de otra mano**,
  y parecerse sería justo el error. `sin_titulo` es la excepción: comparte
  melodía con `recuperado.ogg` a propósito.
- **No gastar aquí el coro arcano.** `prompts_musica.md` reserva ese timbre para
  `recuperado` y como mucho `jefe`. Que no aparezca tampoco aquí, o deja de
  significar nada en los dos sitios a la vez.
- **No meter voz, muestra vocal, tarareo ni locutor en ningún prompt.** Es la
  decisión de §0: si un candidato sale con algo que se le parezca, se descarta
  y se regenera, no se recorta la voz después.
