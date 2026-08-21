# Prompts para la MÚSICA — la banda sonora que la máquina nunca recibió

> **Y hay un documento hermano: `prompts_canciones.md`.** Esto son diez piezas
> INSTRUMENTALES que se repiten mientras juegas. Aquello son CANCIONES —con voz y
> con letra en castellano— que no suenan de fondo: son ficheros que están en el
> disco de la máquina y que el jugador abre. Las dos reglas que aquí más pelean
> —*nada resuelve* y *sin voz*— allí se levantan a propósito, y por un motivo:
> **la única música de este juego a la que se le permite acabar es la que ya
> estaba acabada antes de que llegaras.**

Hoy el juego no tiene música. Tiene `assets/sonido/*.wav`, catorce efectos
sintetizados por `sonidos.py`, y nada más. Esto es el otro lado.

> **Antes de generar nada, la decisión que lo cambia todo:** esto **no es un
> chiptune de NES**. `DISEÑO.md` §4 dice que la mazmorra corre dentro de un
> sistema operativo viejo, y `CONTEXTO.md` fija la cáscara en un Windows XP de
> 2002. La música de una NES es de 1985 y de otra máquina. **Lo que sonaría en
> ESTA máquina es música de tracker y síntesis FM de tarjeta de sonido**, que
> además es exactamente lo que habría usado alguien programando un RPG en su
> casa en aquella época. Es la diferencia entre "genérico" y "de este juego".

---

## 1. El concepto, en una frase

`DISEÑO.md` §3: alguien intentó convertir una máquina de pinball en un juego de
rol, lo dejó a medias y se fue.

> **La banda sonora es una de las cosas que dejó a medias.**

No es "música oscura de mazmorra". Es **una máquina intentando reproducir una
banda sonora que nunca recibió del todo**: bucles un compás más cortos de lo que
deberían, instrumentos que son claramente un marcador de posición, una melodía
que empieza y no resuelve porque quien la escribía paró ahí.

Eso es lo oscuro y lo misterioso de verdad, y es lo que no da un prompt de
"dark dungeon music": **no da miedo, da mal**. Algo va mal y nadie lo explica.
Es la misma regla que la premisa —cero cinemáticas, cero guion— aplicada al
oído.

De ahí salen tres reglas que gobiernan todos los prompts de abajo:

1. **Suena a hardware barato**, no a orquesta. FM de OPL3, módulos de tracker,
   parches de MIDI general cutres. Un juego de fantasía que no podía pagarse
   instrumentos de verdad.
2. **Nada resuelve.** Ni una cadencia, ni un clímax, ni un final. Que además es
   justo lo que hace falta para que loopee (§2).
3. **Todo está un poco desafinado.** El reloj de la máquina no va fino. Es el
   detalle que convierte "retro" en "algo aquí no funciona".

### La paleta de sonido es la paleta de color

`CONTEXTO.md` fija 33 colores y una regla: *el violeta arcano es el único color
mágico, con cuentagotas*. La banda sonora se construye igual.

| Familia de color | Qué es en sonido |
|---|---|
| neutros · piedra | drones graves de FM, ruido filtrado, zumbido de ventilador |
| tierra | cuerdas MIDI baratas y desafinadas, maderas graves |
| oro · cobre | campanas, metales FM, pulsados secos |
| verdes · azules | pads sostenidos, nada que llame la atención |
| **arcano `6B3F9E`** | **UN solo sonido bonito**: un coro lejano desafinado. **Con cuentagotas.** |

Si el coro arcano aparece en más de dos de las diez piezas, deja de significar
nada. Va en `recuperado` sí o sí, y en `jefe` como mucho.

---

## 2. Por qué Suno no loopea, y cómo se arregla

Suno está entrenado con canciones, y una canción termina. **No va a darte un
bucle nunca; te da material del que sacas un bucle.** El arreglo tiene tres
capas y las tres hacen falta.

### Capa 1 — el prompt (el bloque L)

**Este bloque se pega al final de TODOS los prompts de §4**, cambiando solo el
número de BPM. Es el equivalente al prefijo de guía de estilo de
`prompts_animacion.md`: no se piensa cada vez, se pega.

> loopable, seamless loop, no intro, no outro, no fade in, no fade out,
> consistent energy throughout, no build, no climax, no drop, no breakdown,
> single key, no key change, no modulation, steady rhythm, exactly **NN** BPM,
> minimal variation, repetitive ostinato, instrumental, no vocals

Las cuatro que más trabajan y por qué:

- **`exactly NN BPM`** — sin un tempo fijo no hay rejilla de compases, y sin
  rejilla no hay dónde cortar. Es lo primero que hay que exigir.
- **`no build, no climax`** — una pieza que sube de intensidad no tiene ningún
  punto de corte válido, porque el final nunca casa con el principio. Lo que se
  busca es una pieza **plana**: cualquier trozo suena como cualquier otro.
- **`single key, no modulation`** — si modula, la costura del bucle desafina.
- **`instrumental, no vocals`** — y además marca el interruptor de *Instrumental*
  en Suno. Solo con ponerlo en el texto se le cuela un "ah" de fondo.

### Capa 2 — el recorte

Genera de 2 a 3 minutos y **tira el principio y el final**. El trozo bueno está
en el centro: busca el ciclo más estable de 20 a 90 segundos, corta en frontera
de compás, y ponle un desvanecido minúsculo (5-10 ms) a cada punta para que no
chasquee.

> **El techo era 40 s y lo subió Daniel oyéndolos** (21-ago): *"había pensado
> en alargar los audios, me parecen muy cortos"*. **Y el largo bueno es de cada
> pieza, no del documento** — medido: `recuperado` sube de 0,182 a 0,740 de
> costura al pasar de 34 a 68 s, porque sus frases no caben en 34; `mapa` cae
> de 0,905 a 0,647 haciendo lo mismo, porque la suya sí. Lo que `musica.py`
> elige es **el corte más largo de entre los que cierran casi tan bien como el
> mejor**, y así las que no dan más de sí se quedan cortas ellas solas. Después escúchalo cinco veces seguidas en bucle: si a la tercera te
molesta algo, es el corte, no la música.

El compás dura `60 / BPM × 4` segundos. A 96 BPM son 2,5 s, así que los cortes
válidos están cada 2,5 s. Cortar "a ojo" es lo que produce el clic.

### Capa 3 — Godot, que es donde casi nadie mira

**Godot ya sabe loopear con desplazamiento, así que ni siquiera hace falta que
el archivo empiece limpio.** Importando el `.ogg`, en el panel de importación:

- **`Loop`** activado
- **`Loop Offset`** = segundo exacto donde empieza el cuerpo

Con eso, la intro suena una vez al empezar y el bucle salta ahí a partir de la
segunda vuelta. Lo único que hay que quitar a mano es la cola del final. Para
`.wav` es lo mismo con `Loop Mode: Forward` y los puntos de inicio y fin en
muestras, pero para música va OGG: los WAV de `assets/sonido/` son de 5 a 66 KB
y una pieza de dos minutos en WAV son 20 MB.

### Y el atajo que resuelve medio documento: los stems

Suno exporta **pistas separadas** (batería, bajo, melodía). Eso no es una
comodidad, es lo que hace que esta banda sonora sea barata:

- **MODO SEGURO** (`PROPÓSITO.md` §5) dibuja el escritorio en 16 colores. Su
  música es **la misma pista con la mitad de los canales quitados**. Cuesta cero
  generación y es la misma broma que el apartado visual.
- **Los actos II y III** no son piezas nuevas: son la de combate perdiendo capas
  y ganando ruido.
- **La DESCARGA de rampa** (`PROPÓSITO.md` §6) puede meter una capa aguda
  durante sus cuatro segundos y quitarla al acabar. Música que reacciona a la
  mesa, que es exactamente lo que pide la tanda 3.

**Una generación de combate bien hecha da cinco estados de música.** Genera esa
primero y no generes las variantes: sepáralas.

---

## 3. La regla de mezcla que nadie recuerda hasta que es tarde

Los efectos de `sonidos.py` son ondas cuadradas cuantizadas y **suenan
constantemente**: un bumper es 520→150 Hz, un target 900→620 Hz, el flipper es
ruido filtrado a 2600 Hz. O sea que **la banda de 150 Hz a 1 kHz está ocupada y
está ocupada todo el rato.**

Si la música pone ahí su melodía, cada bola es un barrizal.

- **En el prompt:** pedir que no haya melodía de rango medio, y que lo melódico
  viva en el bajo profundo o en campanas agudas.
- **En el archivo, que es donde de verdad se arregla:** un corte ancho y suave
  de 3-4 dB entre 400 y 1200 Hz en la pista de música. Suno no obedece
  instrucciones de frecuencia, así que esto se hace en el editor, no pidiéndolo.
- **En Godot:** bus de música por debajo del de efectos, y la música agachándose
  un par de dB durante el multibola.

Es la razón por la que `combate` pide explícitamente **no llevar melodía**. No
es una pieza incompleta: es una pieza que deja sitio.

---

## 4. Las diez piezas

Orden de generación, no de aparición. **La primera no es la primera que se oye.**

### 0. Antes de nada: generar UNA y convertirla en Persona

Genera `combate` hasta que el timbre te guste de verdad —no la melodía, el
**timbre**— y guárdala como **Persona**. Todas las demás se generan desde ahí.

Sin eso, diez generaciones sueltas dan diez juegos distintos, y "suena genérico"
es casi siempre eso: no que cada pieza esté mal, sino que no se parecen entre
sí. La cohesión es lo que hace que una banda sonora suene a banda sonora.

---

### El bloque T — timbre común

**Se pega al principio de todos los prompts**, igual que el bloque L se pega al
final.

> 1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, Adlib and Sound
> Blaster sound card timbres, tracker module music, MOD and XM demoscene,
> cheap General MIDI orchestral patches, Roland SC-55, slightly detuned and
> out of tune, hollow metallic tones, dry and close, lo-fi 22 kHz sample rate,
> dark, cold, mysterious, unresolved

---

### 1. `combate.ogg` — la mesa · 96 BPM

Suena el 80 % de la partida. Es la que hay que clavar y es la semilla de Persona.

> [bloque T] · driving dungeon crawler groove, low FM bass ostinato repeating
> every two bars, tight dry tracker drums, dark minor mode, one sustained low
> drone underneath, **no lead melody at all**, melodic movement only in the deep
> bass and in occasional high metallic bells, relentless, mechanical, hypnotic,
> the same two bars forever, patient menace · [bloque L, 96 BPM]

**No lleva melodía a propósito** (§3). Si al escucharla sola te parece que le
falta algo, está bien: con la bola encima no le falta nada.

### 2. `escritorio.ogg` — el escritorio y el menú de Inicio · 60 BPM

Lo primero que se oye al abrir el juego. La máquina en reposo, con algo
corriendo que no debería.

> [bloque T] · sparse dark ambient, almost silent, a single slow detuned FM bell
> every four bars, deep sub drone, distant hard drive seek noise and fan hum used
> as percussion, one unresolved minor second held too long, vast empty room,
> patient, waiting, nothing is happening and that is wrong · [bloque L, 60 BPM]

**Que casi no haya música es la decisión, no una carencia.** Un escritorio con
melodía suena a menú de juego; un escritorio con un zumbido y una campana cada
diez segundos suena a máquina encendida sola.

### 3. `recuperado.ogg` — la carpeta RECUPERADO y `chkdsk` · 56 BPM

La pieza importante del documento. Es la recompensa de `PROPÓSITO.md` §2, y es
lo que se oye justo después de perder un run.

> [bloque T] · fragile and beautiful, a single unfinished melody on a detuned
> music box, one distant detuned choir pad, long silences between phrases,
> **the melody stops mid-phrase and starts over from the beginning**, never
> reaching its final note, melancholy, tender, something was here and is not
> here now · [bloque L, 56 BPM]

**La melodía que se corta a la mitad es el juego entero en cuatro compases.** Es
la única pieza de verdad bonita de las diez, y es donde va el coro arcano. Que
la única belleza del juego esté en la pantalla que sale al perder es todo el
diseño de `PROPÓSITO.md` dicho sin una línea de texto.

### 4. `jefe.ogg` — los tres jefes · 108 BPM

> [bloque T] · boss theme, heavy detuned FM brass stabs, tritone interval,
> relentless sixteenth note bass, dry mechanical drums, one distant choir pad
> far back in the mix, oppressive and inevitable, **no heroism, no triumph,
> nothing to win**, the feeling of a process that cannot be killed
> · [bloque L, 108 BPM]

`no heroism, no triumph` es la línea que más trabaja. Un tema de jefe épico
convierte al bicho en un rival; aquí es un proceso que no se deja matar.

### 5. `mapa.ogg` — la ventana del explorador · 84 BPM

Entre combates, eligiendo rama. Anticipación fría.

> [bloque T] · cold minimal arpeggio on a hollow FM patch, mechanical ticking
> pulse, one low cheap MIDI string pad, no melody, calculating, waiting,
> faint dread, nothing threatening yet · [bloque L, 84 BPM]

### 6. `caza.ogg` — el modo de caza de la zona alta · 120 BPM

`DISEÑO.md` §5: el reloj del enemigo sigue corriendo mientras estás arriba. La
música tiene que dar prisa.

> [bloque T] · nervous fast ostinato, high plucked FM, an audible ticking clock
> underneath getting slightly ahead of the beat, thin and exposed arrangement,
> greedy, unsafe, the feeling of stealing time, it should have stopped by now
> · [bloque L, 120 BPM]

`getting slightly ahead of the beat` es lo que la hace incómoda sin subir el
volumen. Es prisa, no acción.

### 6b. La CAPTURA — tres puntadas y dos estados · *añadido con `CAZA.md`*

`caza.ogg` cubre **una** de las cuatro fases de `CAZA.md` §2: el acoso. Las otras
tres piden sonido y **ninguna es una pieza nueva** — dos son stems de `caza` y
tres son puntadas de tres segundos. Coste real: **una generación de puntadas**.

**Los dos estados salen de los stems de `caza.ogg`**, igual que los actos II y
III salen de `combate` (§2). Se genera `caza` una vez y se separa:

| Fase | Qué suena | De dónde sale |
|---|---|---|
| **Rastro** — aún no la ves | `caza` **sin el ostinato**: solo el tic y el fondo | stem |
| **Acoso** — la estás acorralando | `caza` entera | ya está |
| **Regreso** — bajas con ella dentro | `caza` **sin el tic**, y el bajo de `recuperado` debajo | stem + stem |

Ese último es el que hace el trabajo: **al capturar, el reloj deja de oírse.** La
prisa se acaba y lo que queda es lo que llevas. Si además drenas, lo pierdes.

#### `captura_cierre.wav` — se rinde, se abre la ventana · 2 s · NO es bucle

> a sudden hush, the ticking stops dead, one low detuned FM bell struck once and
> left ringing, air pressure dropping, 2 seconds, unresolved, nothing triumphant

**Lo importante es que PARA**, no que suene. Después de 20 s de tic nervioso, el
silencio es el aviso de que hay ventana. Es la misma idea que el silencio detrás
de `tilt`.

#### `captura_hecha.wav` — la criatura entra en el cascabel · 3 s · NO es bucle

> the first three notes of a detuned music box phrase, warm and fragile, then a
> soft heavy latch closing over them, 3 seconds, do not finish the phrase

**Y aquí está la única idea de este apartado que vale la pena defender:** esas
tres notas son **el principio de `recuperado.ogg`**, la pieza de la carpeta. O
sea que la primera vez que oyes esa melodía es al capturar, se corta, y **solo
suena entera cuando abres `RECUPERADO/` y ves el fichero**. La recompensa se
promete con el oído en la mesa y se paga en la cáscara, sin una línea de texto.

Se genera **después** de `recuperado.ogg`, y se recorta de ella: no es una
generación nueva, son sus tres primeros segundos con el cierre encima.

#### `captura_perdida.wav` — drenas bajando y se escapa · 2 s · NO es bucle

> the same music box phrase cut off by a hard digital dropout mid-note, one
> descending detuned tone, then room tone, 2 seconds, no resolution, no impact
> hit

**Sin golpe.** La tentación es un porrazo, y un porrazo dice "has fallado un
tiro". Lo que ha pasado es peor y más callado: se ha ido. La frase cortada a
mitad de nota es la misma broma que `recuperado`, usada en contra.

#### La regla que las tres comparten

**Ninguna se pisa con `caza.ogg`, porque la música se agacha mientras suenan.**
Tres puntadas encima de un ostinato a 120 BPM no se oyen. Es el mismo ducking
que §3 pide para el multibola, y hay que acordarse de escribirlo al conectarlas.

### 7. `tienda.ogg` — tienda y descanso · 70 BPM

El único momento cálido del juego. Y aun así, mal.

> [bloque T] · warm but wrong, slow detuned music box, one cheap MIDI harp,
> major key that keeps sliding flat, comforting and not quite right, very sparse,
> too much reverb for such a small room, safe for now · [bloque L, 70 BPM]

**Si suena del todo bien, se rompe el tono del juego.** El descanso compite con
mejorar (`DISEÑO.md` §12): que la música sea acogedora y esté desafinada dice
eso mejor que un número.

### 8. `combate_corrupto` — actos II y III

**No se genera.** Son los stems de `combate` (§2): acto II pierde una capa y le
entra ruido de fondo; acto III pierde dos y va medio tono bajo.

Si aun así quieres generarla, la orden es *Cover* sobre `combate`, nunca una
pieza nueva:

> same groove and same instruments, but degraded: pitch drifting slightly flat,
> stuttering repeated notes, bit-crushed, channels dropping out and coming back,
> tape wobble, digital dropouts, **the music itself is failing**
> · [bloque L, 96 BPM]

### 9. `tilt.wav` — la derrota · NO es bucle

Cuatro o cinco segundos. Aquí el bloque L **no se pega**: esto sí termina.

> abrupt system failure sting, descending detuned FM tones collapsing into each
> other, one low hit, hard digital cut to absolute silence, dead air after,
> 5 seconds, no music, no resolution

El silencio después es parte del efecto. La pantalla azul de TILT no lleva
música de fondo.

### 10. `arranque.wav` — el arranque del sistema · NO es bucle

Tres o cuatro segundos, al abrir el juego, antes del escritorio.

> a short startup chime for a fake operating system, four notes on a warm
> detuned FM pad, rising, **the last note is slightly out of tune and held a
> beat too long**, then silence, 4 seconds

**Es la pieza más corta y la que más veces se va a oír.** Cuatro notas que casi
son bonitas y una última que no encaja: el juego entero, antes del menú.

---

## 5. Qué hacer, en orden

1. **`combate`**, hasta que el timbre esté bien. Guardarla como Persona.
2. **Separarla en stems** y montar de ahí los actos II y III y MODO SEGURO.
3. **`recuperado`**, que es la que decide si el propósito emociona o solo informa.
   **Y de ella salen recortadas las dos puntadas de captura de §6b**, así que va
   antes que `caza`.
4. **`arranque` y `tilt`**, que son cortas y no necesitan bucle.
5. Las cinco restantes, todas desde la Persona.
5b. **`caza`, y separarla en stems** — de ahí salen el rastro y el regreso (§6b)
   sin generar nada más.
6. ~~**Recortar, exportar a OGG, y en Godot activar `Loop` con su `Loop
   Offset`.**~~ **HECHO (tanda 0m), y con dos correcciones a este documento.**
   Lo hace `musica.py`, que además elige el corte midiendo en vez de a ojo.

   - **El `Loop Offset` de la capa 3 no se usa, y es mejor así.** La idea era
     dejar la intro en el archivo y que Godot saltara al cuerpo a partir de la
     segunda vuelta. Pero el offset vive en el `.import`, y Godot sirve la copia
     de `.godot/imported/`: un flag puesto ahí se pierde en cuanto alguien
     reimporta, que es justo lo primero que hay que hacer al regenerar audio.
     El bucle lo pone `NodoMusica` sobre el recurso cargado, la tabla es la
     única fuente de verdad, y hay una prueba que lo sujeta.
   - **El BPM de §2 es una hipótesis.** Cinco de las siete piezas salieron a un
     tempo que no es el que se pidió, así que la rejilla se mide sobre el
     archivo. Está en `CLAUDE.md`.

**Piloto de una antes de generar diez**, igual que con las hojas de animación.
Mete `combate` en el juego y juega tres combates con ella antes de generar la
segunda: la mitad de las decisiones de este documento solo se pueden juzgar con
una bola en pantalla.

---

## 11. EL BLOQUE R — lo que le faltaba al bloque L (21-ago)

> *Empieza en 11 porque las diez piezas de §4 se citan por su número —§6b, §8,
> §9, §10— desde `ESTADO.md` y desde `CLAUDE.md`, así que del 6 al 10 están
> tomados.*

**El bloque L no pide lo único que hace falta para que haya bucle**, y eso no
es una sospecha: está medido sobre las catorce tomas.

Midiendo cuánto se parece cada pieza a sí misma **a distancia de bucle** —20,
40, 60 y 80 segundos— sale esto:

| toma | dura | 20 s | 40 s | 60 s | 80 s |
|---|---|---|---|---|---|
| `combate_b` | 141 s | −0,00 | +0,05 | −0,02 | −0,02 |
| `caza_a` | 62 s | −0,18 | −0,07 | −0,00 | — |
| `mapa_a` | 147 s | +0,04 | +0,01 | −0,03 | +0,01 |
| `recuperado_a` | 129 s | −0,05 | −0,04 | −0,02 | +0,01 |
| `escritorio_a` | 83 s | **+0,44** | +0,26 | +0,09 | 0,00 |

**Ninguna toma contiene un bucle.** Y no es que Suno ignorara el bloque L: a
escala de COMPÁS obedeció perfectamente —el groove de `caza` se repite a sí
mismo 0,80 cada 2,88 s— pero **la sección no vuelve nunca**. La pieza avanza
para siempre sin repetirse.

De ahí sale todo lo que ha ido mal:

- **Un corte largo empalma dos sitios distintos de una pieza que avanza.** Por
  eso `caza` suena mal cortada aunque mida bien: sus cuatro criterios están en
  verde —costura 0,844, nivel 0,976, plana a 1,7 dB, armonía 0,991— porque los
  cuatro miran ventanas de cuatro segundos, y a cuatro segundos el groove sí es
  el mismo. Lo que no casa es la MÚSICA, que a los treinta segundos ya está en
  otro sitio.
- **Y por eso la herramienta no puede certificar un corte, solo descartarlo.**
  Con material que no se repite, ninguna medida de empalme dice la verdad.

> **El bloque R se pega junto al L, y es el que de verdad decide si habrá
> bucle.** El L pide que no haya clímax; el R pide que la sección VUELVA.

> the exact same 8-bar phrase repeated identically at least eight times,
> every repetition must be identical to the previous one, no variation between
> repetitions, no fills, no drum fills, no turnarounds, no transitions,
> no new instrument enters after the first bar, nothing is added and nothing
> is taken away, the arrangement is frozen, the same loop for the entire
> duration, at least 3 minutes long

Las tres que más trabajan:

- **`the exact same 8-bar phrase repeated identically`** — es lo único que pide
  repetición a escala de sección. Sin esta línea, "repetitive ostinato" del
  bloque L se cumple con un groove constante encima de música que cambia.
- **`no fills, no turnarounds`** — el relleno de batería al cerrar cada frase
  es la manera estándar de que dos repeticiones NO sean idénticas, y es
  exactamente lo que rompe un empalme.
- **`the arrangement is frozen`** — Suno entra y saca instrumentos por su
  cuenta. Una capa que aparece a la mitad convierte la segunda mitad en otra
  pieza.

**Y hay que generar VARIAS TOMAS DE GOLPE con el mismo prompt, no ir ajustando
entre tirada y tirada.** Es la lección de `CLAUDE.md` sobre las hojas de
animación, y vale igual aquí: cada generación es una tirada nueva, no una
edición de la anterior, así que un tirón de cuatro tomas iguales bate a cuatro
tomas distintas encadenadas.

---

## 12. Los prompts de regeneración, ENTEROS

Copiar y pegar tal cual. Llevan el bloque T, el cuerpo, el bloque R y el
bloque L ya montados: no hay que componer nada.

**Orden de importancia**, que no es el de aparición: `combate` suena el 80 % de
la partida y hoy no da más de 40 s; `caza` es la que canta al oído; `mapa` es
la más corta que hay (22,9 s).

### 12.1 `combate` — 96 BPM

1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, Adlib and Sound Blaster sound card timbres, tracker module music, MOD and XM demoscene, cheap General MIDI orchestral patches, Roland SC-55, slightly detuned and out of tune, hollow metallic tones, dry and close, lo-fi 22 kHz sample rate, dark, cold, mysterious, unresolved, driving dungeon crawler groove, low FM bass ostinato repeating every two bars, tight dry tracker drums, dark minor mode, one sustained low drone underneath, no lead melody at all, melodic movement only in the deep bass and in occasional high metallic bells, relentless, mechanical, hypnotic, the same two bars forever, patient menace, the exact same 8-bar phrase repeated identically at least eight times, every repetition must be identical to the previous one, no variation between repetitions, no fills, no drum fills, no turnarounds, no transitions, no new instrument enters after the first bar, nothing is added and nothing is taken away, the arrangement is frozen, the same loop for the entire duration, at least 3 minutes long, loopable, seamless loop, no intro, no outro, no fade in, no fade out, consistent energy throughout, no build, no climax, no drop, no breakdown, single key, no key change, no modulation, steady rhythm, exactly 96 BPM, minimal variation, repetitive ostinato, instrumental, no vocals

### 12.2 `caza` — 120 BPM

1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, Adlib and Sound Blaster sound card timbres, tracker module music, MOD and XM demoscene, cheap General MIDI orchestral patches, Roland SC-55, slightly detuned and out of tune, hollow metallic tones, dry and close, lo-fi 22 kHz sample rate, dark, cold, mysterious, unresolved, nervous fast ostinato, high plucked FM, an audible ticking clock underneath getting slightly ahead of the beat, thin and exposed arrangement, greedy, unsafe, the feeling of stealing time, it should have stopped by now, the exact same 8-bar phrase repeated identically at least eight times, every repetition must be identical to the previous one, no variation between repetitions, no fills, no drum fills, no turnarounds, no transitions, no new instrument enters after the first bar, nothing is added and nothing is taken away, the arrangement is frozen, the same loop for the entire duration, at least 3 minutes long, loopable, seamless loop, no intro, no outro, no fade in, no fade out, consistent energy throughout, no build, no climax, no drop, no breakdown, single key, no key change, no modulation, steady rhythm, exactly 120 BPM, fast and urgent tempo, minimal variation, repetitive ostinato, instrumental, no vocals

**Ojo con el tempo en esta.** Las dos tomas anteriores pidieron 120 y salieron a
83,4 y 80,7 — la única pieza donde Suno se fue tan lejos, y encima es la que
tiene que dar prisa. Por eso lleva `fast and urgent tempo` además del número.
**Se mide antes de cortar** (`python musica.py analizar`): si vuelve a salir por
debajo de 100, la toma no sirve aunque suene bien.

### 12.3 `mapa` — 84 BPM

1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, Adlib and Sound Blaster sound card timbres, tracker module music, MOD and XM demoscene, cheap General MIDI orchestral patches, Roland SC-55, slightly detuned and out of tune, hollow metallic tones, dry and close, lo-fi 22 kHz sample rate, dark, cold, mysterious, unresolved, cold minimal arpeggio on a hollow FM patch, mechanical ticking pulse, one low cheap MIDI string pad, no melody, calculating, waiting, faint dread, nothing threatening yet, the exact same 8-bar phrase repeated identically at least eight times, every repetition must be identical to the previous one, no variation between repetitions, no fills, no drum fills, no turnarounds, no transitions, no new instrument enters after the first bar, nothing is added and nothing is taken away, the arrangement is frozen, the same loop for the entire duration, at least 3 minutes long, loopable, seamless loop, no intro, no outro, no fade in, no fade out, consistent energy throughout, no build, no climax, no drop, no breakdown, single key, no key change, no modulation, steady rhythm, exactly 84 BPM, minimal variation, repetitive ostinato, instrumental, no vocals

### 12.4 `jefe` — 108 BPM

1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, Adlib and Sound Blaster sound card timbres, tracker module music, MOD and XM demoscene, cheap General MIDI orchestral patches, Roland SC-55, slightly detuned and out of tune, hollow metallic tones, dry and close, lo-fi 22 kHz sample rate, dark, cold, mysterious, unresolved, boss theme, heavy detuned FM brass stabs, tritone interval, relentless sixteenth note bass, dry mechanical drums, one distant choir pad far back in the mix, oppressive and inevitable, no heroism, no triumph, nothing to win, the feeling of a process that cannot be killed, the exact same 8-bar phrase repeated identically at least eight times, every repetition must be identical to the previous one, no variation between repetitions, no fills, no drum fills, no turnarounds, no transitions, no new instrument enters after the first bar, nothing is added and nothing is taken away, the arrangement is frozen, the same loop for the entire duration, at least 3 minutes long, loopable, seamless loop, no intro, no outro, no fade in, no fade out, consistent energy throughout, no build, no climax, no drop, no breakdown, single key, no key change, no modulation, steady rhythm, exactly 108 BPM, minimal variation, repetitive ostinato, instrumental, no vocals

### 12.5 `escritorio` — 60 BPM

1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, Adlib and Sound Blaster sound card timbres, tracker module music, MOD and XM demoscene, cheap General MIDI orchestral patches, Roland SC-55, slightly detuned and out of tune, hollow metallic tones, dry and close, lo-fi 22 kHz sample rate, dark, cold, mysterious, unresolved, sparse dark ambient, almost silent, a single slow detuned FM bell every four bars, deep sub drone, distant hard drive seek noise and fan hum used as percussion, one unresolved minor second held too long, vast empty room, patient, waiting, nothing is happening and that is wrong, the exact same 8-bar phrase repeated identically at least eight times, every repetition must be identical to the previous one, no variation between repetitions, no fills, no turnarounds, no transitions, no new instrument enters after the first bar, nothing is added and nothing is taken away, the arrangement is frozen, the same loop for the entire duration, at least 3 minutes long, loopable, seamless loop, no intro, no outro, no fade in, no fade out, consistent energy throughout, no build, no climax, no drop, no breakdown, single key, no key change, no modulation, steady rhythm, exactly 60 BPM, minimal variation, repetitive ostinato, instrumental, no vocals

### 12.6 `recuperado` — 56 BPM

**La que menos falta hace regenerar**, porque su toma actual ya funciona a 68 s
y es la única que mejoró al alargarla. Está aquí por si se quiere una tirada
mejor, pero **la que hay no se tira hasta que algo la supere de verdad**, que
es la regla de `CLAUDE.md`: si una tanda no supera a lo que ya está, no entra.

1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, Adlib and Sound Blaster sound card timbres, tracker module music, MOD and XM demoscene, cheap General MIDI orchestral patches, Roland SC-55, slightly detuned and out of tune, hollow metallic tones, dry and close, lo-fi 22 kHz sample rate, dark, cold, mysterious, unresolved, fragile and beautiful, a single unfinished melody on a detuned music box, one distant detuned choir pad, long silences between phrases, the melody stops mid-phrase and starts over from the beginning, never reaching its final note, melancholy, tender, something was here and is not here now, the exact same 16-bar phrase repeated identically at least six times, every repetition must be identical to the previous one, no variation between repetitions, no fills, no turnarounds, no transitions, no new instrument enters after the first bar, nothing is added and nothing is taken away, the arrangement is frozen, the same loop for the entire duration, at least 3 minutes long, loopable, seamless loop, no intro, no outro, no fade in, no fade out, consistent energy throughout, no build, no climax, no drop, no breakdown, single key, no key change, no modulation, steady rhythm, exactly 56 BPM, minimal variation, repetitive ostinato, instrumental, no vocals

**Lleva 16 compases en vez de 8**, y es el único caso: su frase melódica no cabe
en ocho, que es literalmente por lo que a 34 s no cerraba y a 68 sí.

### 12.7 `tienda` — 70 BPM

1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, Adlib and Sound Blaster sound card timbres, tracker module music, MOD and XM demoscene, cheap General MIDI orchestral patches, Roland SC-55, slightly detuned and out of tune, hollow metallic tones, dry and close, lo-fi 22 kHz sample rate, dark, cold, mysterious, unresolved, warm but wrong, slow detuned music box, one cheap MIDI harp, major key that keeps sliding flat, comforting and not quite right, very sparse, too much reverb for such a small room, safe for now, the exact same 8-bar phrase repeated identically at least eight times, every repetition must be identical to the previous one, no variation between repetitions, no fills, no turnarounds, no transitions, no new instrument enters after the first bar, nothing is added and nothing is taken away, the arrangement is frozen, the same loop for the entire duration, at least 3 minutes long, loopable, seamless loop, no intro, no outro, no fade in, no fade out, consistent energy throughout, no build, no climax, no drop, no breakdown, single key, no key change, no modulation, steady rhythm, exactly 70 BPM, minimal variation, repetitive ostinato, instrumental, no vocals

---

## 13. LOS PUENTES — y por qué no son lo que parecen

Idea de Daniel (21-ago): *"podríamos ingeniarnos transiciones como archivos de
música enteros"*. Es buena, y la parte de diseño que hay que decidir antes de
generar nada es **qué tiene que hacer un puente**, porque hay dos respuestas y
solo una se puede encargar.

### 13.1 Un puente que CASA es imposible de encargar; uno que TAPA es trivial

La versión que suena bien sobre el papel es un puente que sale del tono y el
tempo de la pieza que se va y entra en los de la que llega. **Eso no se le
puede pedir a Suno**: no sabe en qué tono está `mapa` ni en cuál `combate`, y
aunque se le dijera, ya sabemos que cinco de siete piezas ignoraron el BPM. Un
puente que casa habría que componerlo, no generarlo.

Pero un puente no necesita casar. **Necesita dar permiso al oído para que la
música cambie.** Si algo pasa por delante en el momento del cambio, deja de
oírse como un corte y pasa a oírse como un evento. Y eso no tiene tono ni
tempo, así que sí se puede encargar.

**Y la ficción ya lo tiene resuelto:** esto es un sistema operativo. Cambiar de
música es cambiar de programa. Un disco duro buscando, un lector arrancando,
un pitido de placa base. §1 de este documento ya metía "ruido de disco duro y
zumbido de ventilador" en la paleta de sonido; el puente es esa misma idea
puesta a trabajar.

### 13.2 Cómo suena, en el motor

**El puente NO sustituye al cruce: suena ENCIMA.** `NodoMusica` cruza las dos
piezas como ya hace, y a la vez dispara el puente. Así el puente no tiene que
casar con nada ni durar lo que dure la transición, y si algún día falta un
puente, el cambio sigue funcionando como hoy.

Hace falta un tercer reproductor en `NodoMusica`, fuera de la pareja del cruce
—por lo mismo que `NodoSonido.PROPIOS`: un sonido que informa no puede
comérselo la rueda—.

### 13.3 Cuáles hacen falta: cuatro, no nueve

La tentación es uno por cada par de estados, y son nueve. **Un puente no
describe de dónde vienes: describe qué acaba de pasar**, y de eso solo hay
cuatro clases.

| puente | cuándo | qué cuenta |
|---|---|---|
| `puente_entrar` | mapa → mesa | un programa que se abre y toma el control |
| `puente_salir` | mesa → mapa | ese programa que se cierra |
| `puente_caza` | mesa → arena de caza | **el único que es un premio**, no un cambio |
| `puente_ventana` | se abre `RECUPERADO` | una ventana del sistema encima de todo |

`arranque` y `tilt` no necesitan puente: ya SON transiciones enteras.

### 13.4 Los prompts, enteros

**Aquí el bloque L NO se pega** —estas terminan— y el bloque R tampoco, que es
lo contrario de lo que piden. El bloque T sí, porque tienen que sonar a la
misma máquina.

#### `puente_entrar` · 2 s

1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, Adlib and Sound Blaster sound card timbres, tracker module music, cheap General MIDI patches, Roland SC-55, slightly detuned and out of tune, hollow metallic tones, dry and close, lo-fi 22 kHz sample rate, dark, cold, a short 2 second transition sting for an old operating system launching a program, a hard drive spinning up and seeking, one low FM tone rising and cutting off dead, mechanical relay click at the end, no melody, no rhythm, no tempo, no key, 2 seconds, ends in silence, instrumental, no vocals

#### `puente_salir` · 2 s

1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, Adlib and Sound Blaster sound card timbres, tracker module music, cheap General MIDI patches, Roland SC-55, slightly detuned and out of tune, hollow metallic tones, dry and close, lo-fi 22 kHz sample rate, dark, cold, a short 2 second transition sting for an old operating system closing a program, a hard drive spinning down, one low FM tone descending and losing pitch as if the power is dropping, a soft mechanical click, no melody, no rhythm, no tempo, no key, 2 seconds, ends in silence, instrumental, no vocals

#### `puente_caza` · 3 s

1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, Adlib and Sound Blaster sound card timbres, cheap General MIDI patches, Roland SC-55, slightly detuned and out of tune, hollow metallic tones, lo-fi 22 kHz sample rate, a short 3 second transition sting for a hidden bonus area opening, air pressure rising, one detuned FM bell struck once and left ringing, a distant choir pad swelling underneath and cut off before it resolves, wonder and unease at once, something you were not supposed to reach, no melody, no rhythm, no tempo, 3 seconds, ends unresolved, instrumental, no vocals

**Es el único de los cuatro que puede ser bonito**, y `assets/prompts_musica.md`
§1 dice que el coro arcano va con cuentagotas: si suena aquí, ya solo puede
sonar en `recuperado`. Es una decisión, no un adorno — el sitio donde suena lo
único bonito de la banda sonora es lo que el jugador aprende a querer.

#### `puente_ventana` · 1,5 s

1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, Adlib and Sound Blaster sound card timbres, cheap General MIDI patches, Roland SC-55, slightly detuned, hollow metallic tones, dry and close, lo-fi 22 kHz sample rate, a very short 1.5 second sting for a window opening in an old operating system, one dull wooden knock, a brief burst of tape hiss, one flat detuned bell, no melody, no rhythm, no tempo, no key, 1.5 seconds, ends in silence, instrumental, no vocals

### 13.5 Y la vía que no necesita generar nada

**Hay 46 MB de tomas guardadas en `Desktop/Musica`**, y un puente dura dos
segundos. La cola de cualquier toma —donde Suno cierra la pieza, que es
justamente el trozo que se tira— es material de puente ya escrito, con el
timbre de la banda sonora garantizado porque ES la banda sonora.

Se recorta con lo que ya hay:

    ffmpeg -ss <segundo> -t 2 -i <toma>.ogg -af "afade=t=out:st=1.9:d=0.1" puente.ogg

**Merece probarse ANTES que los prompts de §13.4**, porque cuesta cero
generaciones y contesta la pregunta que de verdad importa: si un puente tapando
el cambio arregla lo que se oye. Si la respuesta es que sí, entonces vale la
pena generar unos buenos.
