# Prompts para las CANCIONES — los ficheros que ya estaban en el disco

`prompts_musica.md` son **diez piezas instrumentales que se repiten mientras
juegas**. Esto es otra cosa y por eso es otro documento:

> **Una canción de este juego no es música de fondo: es un ARCHIVO.** Está en el
> disco de la máquina, tiene nombre, se puede abrir, y alguien la puso ahí antes
> de que tú llegaras.

Eso no es un adorno de ambientación, es lo que resuelve tres problemas a la vez:

1. **Justifica que haya voz.** `prompts_musica.md` §2 prohíbe cantar en las diez
   piezas —`instrumental, no vocals`— y con razón: una voz encima de una bola es
   ruido. Un fichero que abres en el escritorio, con el juego parado, no.
2. **Justifica que TERMINEN.** Todo el documento de música pelea contra Suno para
   que no cierre las piezas. Aquí no hay que pelear: **la única música de este
   juego a la que se le permite acabar es la que ya estaba acabada antes de que
   llegaras.** Suno hace canciones que terminan; aquí eso deja de ser un defecto
   y pasa a ser el sentido.
3. **Es historia sin guion.** `DISEÑO.md` §3 —cero cinemáticas, cero diálogo— y
   `PROPÓSITO.md` §2 —desbloqueos que son *"piezas rescatadas de la memoria antes
   de que el reinicio las borre"*. Una canción **es** una pieza rescatada.

Van en `MUSICA/`, una carpeta del escritorio falso, con su reproductor cutre.

---

## 1. La idea que hay que leer antes que los prompts

**La canción de los cascabeles se desbloquea POR ESTROFAS.**

Es una canción de contar. Nueve cascabeles, nueve estrofas, una por cascabel — y
el reproductor **solo toca las estrofas de los cascabeles que tienes**. Al
principio la canción dura veinte segundos y tiene huecos; al final dura entera.

Lo que eso da, que es mucho para lo que cuesta:

- **Un desbloqueable que no es un número.** `DISEÑO.md` §13 lleva desde el
  principio queriendo meta-progresión que no sea "+3 % de daño"; esto es una cosa
  que **crece y se oye crecer**.
- **Un contador de colección que no es una lista.** Sabes cuántos te faltan
  porque la canción tiene agujeros. No hace falta ninguna interfaz.
- **Coste de producción cero.** Se genera la canción **entera, una vez**, y se
  corta por estrofas. Nueve trozos de un OGG y un array de booleanos.
- **Y el remate:** la estrofa novena, la del cascabel de runas, es la que habla
  de ti. O sea que **la canción no se completa hasta que el juego te ha explicado
  quién eres**, y te lo explica cantando.

Si de este documento solo se hace una cosa, es esta.

---

## 2. Cómo se pide una canción, que no es como se pide un bucle

| | las diez piezas | las canciones |
|---|---|---|
| bloque **T** (timbre) | sí, siempre | **sí** — es lo que las hace del mismo juego |
| bloque **L** (bucle) | sí, siempre | **NO.** Estas terminan |
| `instrumental` | sí | **no**: aquí es donde vive la voz |
| BPM exacto | imprescindible | útil pero no crítico |
| dónde se decide | el prompt de estilo | **la letra**, sobre todo |

**El bloque T se sigue pegando**, recortado a lo que cabe en el cuadro de estilo:

> 1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, cheap General MIDI
> patches, tracker module, slightly detuned, lo-fi 22 kHz, dry and close

Y **tres reglas propias**, que salen de las tres del documento de música
traducidas a canción:

1. **La voz es una MUESTRA, no una cantante.** Esta máquina no podía grabar a
   nadie: lo que tendría es una voz digitalizada a 8 bits, corta y con la
   sibilancia rota. En el prompt: `thin sampled vocal, 8-bit voice sample,
   telephone bandwidth, lo-fi vocal`. Una voz bien grabada la saca del juego.
2. **Nada resuelve, tampoco aquí.** Pueden terminar —eso es lo que las hace
   archivos— pero terminan **cortándose o apagándose**, no cerrando. En el
   prompt: `ends without resolving, no final cadence`.
3. **La letra en castellano.** El juego está en castellano y la fuente sabe
   escribir eñes desde la tanda de la cáscara. Una canción en inglés dentro de un
   juego en castellano es material mezclado, que es la trampa que ya está en
   `CLAUDE.md`.

---

## 3. `los_nueve_cascabeles` — LA canción · 84 BPM

La que pidió Fátima. Canción de contar, de las de niños, y **por eso funciona**:
una canción de contar es la forma más vieja que hay de guardar una lista, y este
juego tiene nueve cascabeles con nueve nombres que el jugador no tiene dónde
aprender.

Y hay una segunda razón, que es la buena: **una canción infantil que cuenta cosas
que desaparecen da más miedo que cualquier tema de terror**, porque la forma dice
"esto es inofensivo" mientras la letra dice lo contrario. Es la misma regla del
documento de música —*no da miedo, da mal*— con otra ropa.

### El estilo

> lo-fi children's counting song from a 1990s PC game, detuned music box and
> cheap General MIDI celesta, a single thin sampled child-like voice, 8-bit
> vocal sample, telephone bandwidth, sparse, slow, 84 BPM, minor key, warm and
> wrong, tape wobble, dry and close, ends without resolving, no final cadence

### La letra

Nueve estrofas de dos versos, una por cascabel, **más un estribillo que se repite
cada tres**. La estructura es así a propósito: el corte por estrofas de §1 tiene
que caer en frontera de compás y sin cortar el estribillo.

```
[Intro] [Music box]

[Verso 1]
Uno de acero, que ya no da vueltas.
Dentro la rata, que nunca se duerme.

[Verso 2]
Dos es de hierro, y no se le abre.
Dentro el gusano, dando la vuelta.

[Verso 3]
Tres es de bronce, tibio de noche.
Dentro la brasa, que no se apaga.

[Estribillo]
Cascabel, cascabel,
nadie te puso ese nombre.
Cascabel, cascabel,
así se llamaba el archivo.

[Verso 4]
Cuatro de piedra, pesa y no suena.
Dentro el musgo, que se lo come.

[Verso 5]
Cinco de vidrio, se ve lo que guarda.
Dentro el espectro, mirando hacia fuera.

[Verso 6]
Seis es de hueso, no preguntes de quién.
Dentro la calavera, riéndose sola.

[Estribillo]
Cascabel, cascabel,
nadie te puso ese nombre.
Cascabel, cascabel,
así se llamaba el archivo.

[Verso 7]
Siete de óxido, se rompe si aprietas.
Dentro el sapo, quieto en el agua.

[Verso 8]
Ocho de plata, brilla y no vale.
Dentro el diablillo, contando tus vueltas.

[Verso 9]
Nueve de runas. Ese no lo abrió nadie.
Nueve de runas. No cuentes hasta nueve.

[Outro] [Whispered]
El noveno estaba vacío.
Estaba vacío hasta que llegaste.
```

**El estribillo es una cita literal de `DISEÑO.md` §3** —*«Nadie le puso ese
nombre; es el nombre del archivo»*— y eso no es un guiño: es el único sitio del
juego donde esa frase se dice en voz alta. La premisa entera entra por el oído,
en una canción infantil, sin una línea de texto ni una cinemática.

**Y el `[Outro]` susurrado es la novena estrofa de §1**, la que solo se desbloquea
con el cascabel de runas. Antes de tenerlo, la canción se acaba en el verso 8 y
**no se entiende**: cuenta ocho y calla. Después, cuenta nueve y te señala.

### Cómo se corta

Se genera entera y se parte en nueve trozos por frontera de compás. A 84 BPM el
compás dura `60/84 × 4 = 2,857 s`, así que **todos los cortes válidos están en
múltiplos de 2,857 s**. Cortar a ojo produce el clic de siempre
(`prompts_musica.md` §2, capa 2).

Los dos estribillos y la intro **no se cortan**: van siempre. Lo que se enciende
y se apaga son las nueve estrofas, y con un cascabel de menos lo que suena en su
sitio es **el acompañamiento sin voz**, no un silencio. Un hueco mudo se lee como
un fallo; un hueco con música y sin letra se lee como una falta.

---

## 4. `sin_titulo` — la que se quedó a medias · 68 BPM

**La pieza que justifica el juego, en versión canción.** `recuperado.ogg` ya hace
esto instrumentalmente; esto es su gemela con voz, y la diferencia importa: aquí
**la voz tararea porque nunca llegó a haber letra.**

Alguien estaba escribiendo una canción para su juego, hizo la melodía, dejó la
letra para después y se fue.

### El estilo

> unfinished demo recording, 1990s tracker music, detuned music box and one
> cheap MIDI string pad, a single close wordless humming voice, no lyrics,
> lo-fi, hiss, 68 BPM, minor, fragile, melancholy, unfinished, stops mid-phrase,
> no ending, no final cadence

### La letra

```
[Instrumental]

[Verso] [Humming, wordless]
Mmm... mmm... mmm...

[Verso] [Humming, wordless]
Mmm... mmm...

[Instrumental]
```

**No lleva letra y ese es el contenido.** El fichero se llama `sin_titulo` porque
no le puso título; la voz tararea porque no le puso letra. Cuando el jugador abre
esto en `MUSICA/` y oye a alguien tarareando una melodía que no acaba, sabe todo
lo que hay que saber de quién estuvo aquí antes.

**Se corta a mitad de frase, a mano, en el editor.** Suno va a cerrarla; hay que
quitarle el final. Es la única pieza del proyecto donde el recorte no es limpieza:
es el efecto.

---

## 5. `cascabel_sa` — el anuncio de fábrica · 132 BPM

**Antes de que alguien la convirtiera en una mazmorra, esto era una máquina de
pinball**, y una máquina de pinball de 1994 venía con su jingle de demostración.
Está en el disco desde entonces, y es **lo único alegre del juego entero**.

Que es exactamente por lo que hay que hacerla: la banda sonora es oscura de
principio a fin, y **una cosa oscura al lado de otra cosa oscura no da miedo, da
monotonía**. Lo que hace que la máquina dé mal rollo es que se le oiga lo que fue.

### El estilo

> 1994 arcade pinball attract mode jingle, bright major key, cheesy FM brass
> stabs, slap bass, tacky drum machine, upbeat corporate advertising music,
> enthusiastic sampled announcer voice, lo-fi 22 kHz, 132 BPM, short, confident,
> ends on a clean chord

### La letra

```
[Announcer, spoken, enthusiastic]
¡CASCABEL!

[Verso]
Dale a la bola, dale otra vez,
la máquina nunca se apaga.
Dale a la bola, dale otra vez,
¡nadie se va de Cascabel!

[Announcer, spoken]
Cascabel. Nadie se va.

[Outro] [Instrumental]
```

*«Nadie se va de Cascabel»* es un eslogan publicitario perfecto y es, literalmente,
lo que le pasa al jugador. **La broma solo funciona si la canción está grabada con
absoluta convicción comercial**, así que el prompt pide `enthusiastic` y
`confident` sin ninguna ironía: la ironía la pone el juego, no la música.

**Es la única pieza del proyecto que SÍ resuelve** (`ends on a clean chord`), y
eso también es contenido: la única música terminada de esta máquina es la que
venía de fábrica.

---

## 6. `nana` — para dormir a la bola · 52 BPM

La más corta y la más incómoda. Una nana **cantada a la bola**, o sea a ti.

Encaja donde `PROPÓSITO.md` §5 pone MODO SEGURO y donde la cáscara se queda
quieta: es lo que la máquina pone cuando cree que ha terminado.

### El estilo

> slow lullaby, 52 BPM, detuned music box alone, one thin sampled voice singing
> close and quiet, almost whispered, lo-fi, tape hiss, minor, tender and wrong,
> very sparse, long silences, ends by fading out mid-phrase, no final cadence

### La letra

```
[Verso] [Soft, close]
Duerme, que la mesa está fría,
duerme, que ya no hay nadie arriba.
Nadie va a venir a apagarme,
nadie va a venir a apagarte.

[Verso] [Soft, close]
Duerme, y mañana otra vez,
la misma bola, la misma mesa.
Si no te acuerdas, no duele.
Si no te acuerdas, no duele.

[Outro] [Whispered, fading]
No te acuerdas.
```

*«Si no te acuerdas, no duele»* es la mecánica del roguelike dicha como consuelo,
y por eso funciona: la máquina cree que te está consolando.

---

## 7. Orden, y lo que NO hay que hacer

**El orden**, y el motivo de cada sitio:

1. **`los_nueve_cascabeles`.** Es la que pidió Fátima, la que trae el
   desbloqueable de §1 y la única que cambia cómo se juega. Va primera y **se
   genera antes de decidir cómo se corta**: si la canción no vale, el sistema de
   estrofas no vale.
2. **`sin_titulo`.** Corta, barata, y es la que dice si el tono se sostiene con
   voz. Va después de `recuperado.ogg` para que compartan melodía.
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
  `recuperado` y como mucho `jefe`. Estas canciones tienen voz, pero **voz de
  muestra barata**, que es otra cosa: si el coro arcano aparece también aquí,
  deja de significar nada.
- **No traducirlas.** Un juego en castellano con canciones en inglés es material
  mezclado.
