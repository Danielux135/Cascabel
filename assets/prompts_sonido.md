# Prompts para los SONIDOS — la tanda de prueba de Suno

`prompts_musica.md` es el otro lado de esto y va de piezas largas. Esto va de
**samples**: la pestaña *Sonidos* de Suno (v5.5), la que da one-shots y loops
cortos.

Documento de prueba, no de producción. Lo que se decide aquí es **si Suno sirve
para esta mesa**, y con nueve prompts se sabe.

> ## ⚠ YA SE SABE, Y ES QUE NO (18-ago)
>
> **La tanda se generó y Suno queda descartado para efectos.** Lo que hizo,
> en palabras de Fátima: *"hace mucho lo que le da la gana: sonidos muy largos,
> con hasta 2 secciones, trozos de sonidos diferentes en el mismo audio"*.
>
> **Los prompts no eran el problema y por eso no se vuelve a intentar por ahí.**
> Ver §7, que es lo único de este documento que hay que leer entero. El resto se
> queda como está —incluidos los nueve prompts— porque es el registro de qué se
> probó exactamente, y sin eso dentro de tres tandas alguien lo repite.

---

## 0. La pregunta que lo abre, y la respuesta incómoda

> *«Si te conecto a algún programa de sonidos, ¿eres capaz de hacerlos?»*

**Los sonidos del juego ya los hago yo, y sin conectarme a nada.** Son
`sonidos.py`: diecisiete efectos sintetizados por código, 44100 Hz, mono, 16
bits. Un bumper es una cuadrada de 520 a 150 Hz con un 18 % de ruido y cinco
bits de cuantización, y eso no es un apaño hasta que llegue algo mejor: es lo
que hace que **reajustar un golpe sea cambiar un número**, no rehacer un wav.
Un pinball dispara el mismo sonido cuarenta veces por bola. Cuando algo suena
cuarenta veces por bola, poder moverlo medio decibelio vale más que su timbre.

**Lo que la síntesis no puede hacer es materia.** Una onda no tiene madera, ni
óxido, ni garganta, ni sala. Y esos cuatro son exactamente los que hacen falta
ahora: la puerta del umbral es un mecanismo, no un tono; la criatura tiene voz;
la cáscara necesita el zumbido de una máquina encendida, que es una sala.

De ahí sale la única regla de reparto que hace falta:

> **`sonidos.py` se queda con la INFORMACIÓN. Suno se lleva la MATERIA.**

| Se queda en `sonidos.py` | Se va a Suno |
|---|---|
| bumper, target, flipper, banco | la puerta abriéndose y negándose |
| rampa entrada/salida/fallada/fuerte | la voz de la criatura |
| combo, reloj, ataque, atrasar, **salvaguarda** | el zumbido de la máquina |
| platillo, atrapar, caída, drenaje, muerte | el ambiente de la planta alta |

Un sonido de la izquierda suena veinte veces por bola, tiene que ocupar 5 KB y
tiene que poder afinarse en una línea. Uno de la derecha suena una vez cada
minuto y su trabajo es que el sitio exista.

**Y esa tabla es la que hay que comprobar, no dar por buena.** Por eso la tanda
lleva un control (§4, tanda D): si Suno da un bumper mejor que la cuadrada, la
regla estaba mal escrita.

---

## 1. Los cuatro diales de la pestaña, y qué se pone en cada uno

| Dial | Qué es | Qué ponemos |
|---|---|---|
| **Sonido** | el prompt, **máximo 500 caracteres** | lo de §4, con la cola de §3 pegada |
| **Tipo** | One-Shot / Loop | One-Shot casi siempre. Loop **solo** en la tanda B |
| **BPM** | Auto o un número | **Auto** en todo lo de aquí. Ver abajo |
| **Tonalidad** | Cualquiera o una nota | **Cualquiera**. Ver abajo |

**BPM en Auto, y no es pereza.** En `prompts_musica.md` §2 el BPM es lo primero
que se exige, porque sin rejilla de compases no hay dónde cortar el bucle. Aquí
no hay nada que cortar en compases: un golpe de puerta dura 400 ms y un zumbido
de ventilador no tiene pulso. Pedirle 96 BPM a un zumbido es pedirle que meta un
pulso que no queremos.

**Tonalidad en Cualquiera, con una excepción que hoy no se puede resolver.** Lo
que suene afinado —una campana, un coro— tendría que ir en la tonalidad de la
pieza sobre la que va a sonar, y esa pieza aún no existe. Así que hoy: nada
afinado. Cuando haya música, se vuelve aquí.

---

## 2. La regla de mezcla, que aquí muerde más que en la música

`prompts_musica.md` §3 ya lo dice para la banda sonora y aquí es peor, porque un
efecto y otro efecto suenan **a la vez**:

> **De 150 Hz a 1 kHz está ocupado, todo el rato.** Bumper 520→150. Target
> 900→620. Flipper, ruido filtrado a 2600 con un golpe de 150→70.

Así que todo lo de §4 tiene que vivir **por debajo de 150 Hz o por encima de
2 kHz**, y eso va escrito dentro de cada prompt en vez de arreglarse después con
un ecualizador. Un sonido que hay que ecualizar para que quepa es un sonido que
se generó mal.

La criatura, en concreto, **no habla en el centro**: gruñe grave o chilla agudo.
Es la misma decisión que el violeta arcano —un solo sitio del espectro para lo
que importa— aplicada al oído.

---

## 3. El tope de 500 caracteres, y las dos colas que salen de él

**La pestaña *Sonidos* no admite más de 500 caracteres.** Eso no es un detalle de
formato: mata la forma de trabajar de `prompts_musica.md`, donde el bloque L son
280 caracteres que se pegan tal cual a todos los prompts y aún sobra sitio. Aquí
un bloque así se come más de la mitad del presupuesto.

Así que la cola se recorta a lo que de verdad trabaja, y hay **dos**, una por
tipo. Se pegan al final igual que antes; lo que cambia es que ahora hay que
mirar el contador.

**Cola de ONE-SHOT** — 130 caracteres:

> dry, no reverb, isolated single sound, mono, lo-fi 1990s PC sample, no music, no melody, no rhythm, no vocals, no silence at start

**Cola de LOOP** — 140 caracteres:

> seamless loop, same at end as at start, no events, no build, no fade in, no fade out, mono, lo-fi, no music, no melody, no rhythm, no vocals

Lo que se ha caído y por qué no duele:

- **`close-miked`, `cheap sample`, `1990s sound card`** → colapsado en
  `lo-fi 1990s PC sample`. Tres formas de pedir lo mismo eran tres formas de
  gastar caracteres.
- **`slightly detuned`** → fuera. Es la regla de la MÚSICA (`prompts_musica.md`
  §1) y en un golpe de 200 ms no se oye desafinar nada.
- **`no reverb tail`** → `no reverb`, que es más fuerte y más corto.

Lo que se queda y no se toca, porque es lo que rompe el resultado si falta:

- **`no reverb`** — la cola es lo que convierte un efecto en un zumbido cuando
  suena dos veces seguidas. Quitarla después no se puede.
- **`no silence at start`** — Suno mete medio segundo de nada delante y en un
  pinball medio segundo es una eternidad.
- **`no vocals`** — se cuela un "ah" de fondo con una facilidad que asusta, y en
  los loops es lo primero que rompe la costura.
- **`no music, no melody, no rhythm`** — las tres, porque Suno está entrenado con
  canciones y en cuanto le dejas un hueco te compone algo.

Y el presupuesto que queda: **entre 274 y 359 caracteres por prompt**, o sea que
sobran 140 como mínimo. Si algún prompt hay que engordar tras la primera tanda,
hay sitio; lo que no hay es sitio para volver al bloque largo.

---

## 4. La tanda de prueba: nueve prompts, cuatro preguntas

Todos por debajo de 500. El número de al lado es el largo real, para que se vea
cuánto margen queda si hay que retocar.

### Tanda A — foley mecánico (One-Shot). **¿Tiene materia?**

Los tres estados de la puerta del umbral, que es lo que se está diseñando ahora
mismo (`CAZA.md` §9): una puerta que se abre cuando cumples los requisitos, que
te dice que no cuando no los cumples, y que se cierra a tu espalda.

**`puerta_abre`** — 337 caracteres

> Heavy iron bolt sliding back, then a stone slab grinding open. One event, 700 ms. Deep rumble under 120 Hz plus a bright metallic scrape above 3 kHz, nothing in the middle. Dungeon machinery, ends resolved. dry, no reverb, isolated single sound, mono, lo-fi 1990s PC sample, no music, no melody, no rhythm, no vocals, no silence at start

**`puerta_niega`** — 329 caracteres

> A locked mechanism refusing. One short dull clunk, metal hitting a stop and not moving. 200 ms, dead, no ring, no resonance, no pitch. Muffled and abrupt: the sound of something that did not happen. dry, no reverb, isolated single sound, mono, lo-fi 1990s PC sample, no music, no melody, no rhythm, no vocals, no silence at start

> **El que más importa de los tres.** Un "no" que suene bonito se lee como un
> premio pequeño y el jugador vuelve a intentarlo pensando que casi lo tiene.
> **Tiene que sonar a nada.** Si Suno le pone cola o le pone tono, este se
> sintetiza y punto: es un caso de manual para `sonidos.py`.

**`puerta_cierra`** — 294 caracteres

> A stone slab dropping shut and a bolt seating. One heavy impact, 400 ms. Deep thud under 100 Hz with a short metallic click above 4 kHz. Final, no bounce, no echo. dry, no reverb, isolated single sound, mono, lo-fi 1990s PC sample, no music, no melody, no rhythm, no vocals, no silence at start

---

### Tanda B — la máquina (Loop). **¿Loopea, o vuelve a pasar lo de la música?**

Suno no da bucles, da material del que se saca un bucle (`prompts_musica.md` §2).
La pestaña *Sonidos* dice tener un tipo **Loop** — y esta tanda existe **para ver
si esa palabra significa algo**. Es la prueba de fuego del documento.

**`zumbido_maquina`** — 353 caracteres

> Steady electrical hum of an old desktop PC: case fan, idle hard drive, CRT whine. Continuous, unchanging, no clicks, no variation. Deep hum near 100 Hz and a thin whine near 15 kHz, nothing in between. Room tone. seamless loop, same at end as at start, no events, no build, no fade in, no fade out, mono, lo-fi, no music, no melody, no rhythm, no vocals

**`arena_ambiente`** — 359 caracteres

> Room tone of a huge empty stone chamber high above the ground. Distant low drone, faint air movement. No wind gusts, no drips, no footsteps. Featureless, calm but wrong. Sub-bass under 90 Hz, faint shimmer above 6 kHz. seamless loop, same at end as at start, no events, no build, no fade in, no fade out, mono, lo-fi, no music, no melody, no rhythm, no vocals

> Cómo se juzga: se pone en bucle **cinco veces seguidas**. Si a la tercera se
> oye la costura, Suno no loopea y estos dos se cortan a mano igual que la
> música. Si aguanta las cinco, la pestaña *Sonidos* vale por sí sola.

---

### Tanda C — la criatura (One-Shot). **¿Tiene garganta?**

Tres de los cuatro estados de la presa de `CAZA.md` §5. **Van detrás de la puerta
B igual que su arte**: si la planta alta no se siente distinta, esto no se genera
nunca. Están escritos ahora porque el prompt es lo barato.

Sin especie a propósito: en cuanto un prompt dice "rata" o "sapo", Suno entrega
un documental.

**`criatura_acecho`** — 308 caracteres

> A small creature breathing in the dark, aware of you. Low irregular growl under 130 Hz ending in a wet click, 600 ms. Animal but not any real animal. Restrained, not aggressive. dry, no reverb, isolated single sound, mono, lo-fi 1990s PC sample, no music, no melody, no rhythm, no vocals, no silence at start

**`criatura_susto`** — 294 caracteres

> A small creature startled. One sharp inhaled shriek, 250 ms, thin and high above 2.5 kHz, cracked like a broken 8-bit sample. Cuts off abruptly, no tail. Not cute. dry, no reverb, isolated single sound, mono, lo-fi 1990s PC sample, no music, no melody, no rhythm, no vocals, no silence at start

**`criatura_rendida`** — 301 caracteres

> A small creature giving up. One long low exhale sinking in pitch, 900 ms, under 150 Hz. Tired, almost a sigh. Ends in silence, not in a cutoff. Sad without being musical. dry, no reverb, isolated single sound, mono, lo-fi 1990s PC sample, no music, no melody, no rhythm, no vocals, no silence at start

---

### Tanda D — el control. **¿Estaba bien la tabla de §0?**

**`bumper_control`** — 274 caracteres

> Pinball bumper hit. One percussive electronic blip, 130 ms, square wave falling 520 Hz to 150 Hz, bit-crushed, a little noise, no tail. Arcade. dry, no reverb, isolated single sound, mono, lo-fi 1990s PC sample, no music, no melody, no rhythm, no vocals, no silence at start

Es la descripción literal de `SONIDOS["bumper"]`. **Si Suno lo hace mejor, la
regla de reparto de §0 está mal** y hay que replanteársela entera. Si lo hace peor
o parecido —que es lo que espero—, queda demostrado en vez de supuesto, y
`sonidos.py` deja de ser una decisión que hay que defender cada vez.

---

## 5. Qué hacer con lo que salga

**No se mete en el repo tal cual.** Un sample de Suno viene largo, en estéreo, a
la frecuencia que le apetezca y con silencio delante. Los del repo son mono,
44100 Hz, 16 bits y de 5 a 66 KB.

El camino corto, mientras la tanda sea de prueba: recortar, pasar a mono,
normalizar a −3 dBFS, guardar como wav en `assets/sonido/` y reimportar en
Godot.

El camino largo, si la prueba sale bien: `sonidos.py` gana un modo `--importar`
que hace ese recorte y esa conversión siempre igual, y `SONIDOS` gana entradas
que en vez de parámetros de síntesis apuntan a un fichero de origen. Así el
generador sigue siendo el único sitio donde se decide cómo suena el juego,
vengan las muestras de una onda o de Suno. **Eso no se monta hasta que haya algo
que importar**: montar el importador antes de saber si Suno sirve es exactamente
el error de construir antes de decidir.

---

## 6. Lo que NO va a Suno, aunque parezca que sí

- **La salvaguarda de la planta alta.** Hoy suena con el wav de `atrasar`, o sea
  el mismo que la red de seguridad de abajo, y por eso los dos mensajes se
  confunden. La salida no es un sample bonito: es un sonido **propio** y
  sintetizado, porque es información —te está diciendo que la mesa te sujeta—
  y la información se afina con un número.
- **Cualquier cosa que suene más de tres veces por bola.** No por calidad: por
  peso y por poder ajustarla.
- **La música.** Tiene su documento y su pestaña, y son otra cosa.

---

## 7. EL VEREDICTO: la prueba salió que no *(18-ago)*

Se generó la tanda. **Suno queda descartado para efectos de sonido.** No para la
música, que tiene su documento y sigue en pie.

### Lo que falló, y no es el prompt

> *«Hace mucho lo que le da la gana: sonidos muy largos, con hasta 2 secciones,
> trozos de sonidos diferentes en el mismo audio»* — Fátima

Los tres síntomas son **el mismo**: no hay control de la duración. Y eso está
confirmado fuera de nuestra prueba — la ayuda de Suno dice que *Sounds* solo trae
**Tipo, BPM y Tonalidad**, que la duración se "sugiere" escribiéndola dentro del
prompt, y que la función **sigue en beta**. Los nueve prompts pedían milisegundos
explícitos —`200 ms`, `700 ms`, `130 ms`— y no los respetó ni una vez.

De ahí sale todo lo demás: si el modelo decide que el clip dura veinte segundos y
solo le has descrito un golpe de 200 ms, **tiene que rellenar diecinueve segundos
con algo**. Eso es exactamente lo que son las "2 secciones" y los "trozos de
sonidos diferentes": no es que no te entienda, es que le sobra sitio y lo llena.

### Y la trampa que hay que dejar escrita, porque casi cuela

Fátima notó que **los primeros prompts largos convencían más que los abreviados a
500 caracteres**, y añadió ella misma la duda: *"también es posible que sea
suerte, ya que los sonidos son muy diferentes unos de otros"*.

**La duda es la respuesta.** Con una tirada por prompt y una varianza tan alta que
dos generaciones del mismo texto no se parecen, **no se puede atribuir la calidad
del resultado a la calidad del prompt**. Es literalmente la misma avería que
`CLAUDE.md` ya tiene anotada para las hojas de imagen —*no se puede iterar una
generación*— con otra cara: cada tirada es una tirada nueva, no una edición de la
anterior, así que retocar el texto no sube una cuesta, te mueve a otro punto al
azar de la misma distribución.

> **La regla: una herramienta cuya varianza es mayor que el efecto del prompt no
> se afina con prompts.** Se descarta o se usa como banco de material del que se
> recorta a mano. Y para efectos de 200 ms no hay nada que recortar: el efecto ES
> el clip entero.

### Qué lo sustituye, y por qué sale ganando

**La tabla de §0 estaba mal en la mitad que no se comprobó.** Decía que
`sonidos.py` se queda la INFORMACIÓN y Suno se lleva la MATERIA. La primera mitad
sigue en pie; la segunda se cae, y al caerse aparece lo que había debajo:

> **Una puerta es la misma estructura que `caida`: una cosa que dura y LUEGO un
> golpe.** Eso ya se sabe hacer desde que `sonidos.py` tiene `retardo`, que fue
> justo el parámetro que hubo que inventar para el sonido de caerse. No hacía
> falta materia grabada: hacía falta el ingrediente que ya estaba.

Y el argumento de fondo es el mismo que sostiene toda la banda sonora: **esta
máquina no podía pagarse sonido bueno.** Una puerta grabada en una mazmorra de
verdad sonaría *peor* aquí, porque los búmperes de al lado son ondas cuadradas
cuantizadas a cinco bits. Es la trampa de "material mezclado" de `CLAUDE.md`
—una tipografía suave alrededor de píxeles duros parte la pantalla en dos—
aplicada al oído.

**Las tres puertas ya están sintetizadas y medidas** (`sonidos.py`, marcadas como
prototipo porque todavía no hay puertas en la mesa):

| | dura | <150 Hz | >3 kHz | qué hace |
|---|---|---|---|---|
| `puerta_abre` | **750 ms** | 58 % | 12 % | cerrojo agudo, y 150 ms después la losa moliendo |
| `puerta_niega` | **90 ms** | 82 % | 0,5 % | un golpe que se muere antes de resonar |
| `puerta_cierra` | **300 ms** | 69 % | 0,7 % | la losa cae, y 140 ms después asienta el cerrojo |

Las tres duran **exactamente lo que se les pidió**, que es la única cosa que Suno
no supo hacer ni una vez. Y las tres viven por debajo de 150 Hz, donde el bumper
tiene el 0,1 % de su energía y el drenaje el 5 %: la regla de mezcla de §2 se
cumple por construcción en vez de arreglarse con un ecualizador después.

### Lo que queda abierto de verdad

**La voz de la criatura** (tanda C) es el único hueco que la síntesis no tapa
sola. Un gruñido, un chillido y un suspiro no son ondas. Las tres salidas, en
orden de lo que cuestan:

1. **Grabarlo y destrozarlo.** Es como se hacía en los 90 literalmente: voz
   humana, bajada de tono, cuantizada a cuatro bits. Encaja con la mentira de la
   máquina mejor que ninguna otra opción, y cuesta un móvil.
2. **Banco de samples libres** (CC0). Fiable y aburrido; hay que buscar mucho para
   que no suene a documental.
3. **Sintetizarlo igualmente**, con ruido filtrado y un formante barrido. Sale
   una criatura de máquina, no de carne — que puede ser lo correcto, viendo que
   `cr_sombra` es casi una silueta.

**Va detrás de la puerta B igual que su arte**: si la planta alta no se siente
distinta, no hace falta ninguna de las tres.
