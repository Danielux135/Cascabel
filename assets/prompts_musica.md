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
en el centro: busca el ciclo más estable de 20 a 40 segundos, corta en frontera
de compás, y ponle un desvanecido minúsculo (5-10 ms) a cada punta para que no
chasquee. Después escúchalo cinco veces seguidas en bucle: si a la tercera te
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
