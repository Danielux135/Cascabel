# ESTADO.md — CASCABEL

Estado vivo. Se lee al empezar la sesión y se actualiza al terminarla.

**Regla de tamaño:** esto no es un registro de cambios. Al cerrar sesión,
resume lo tuyo en dos o tres líneas dentro de "Hecho" y borra el detalle.
Lo que merezca sobrevivir para siempre va a `CLAUDE.md`, no aquí. Si esto
pasa de una pantalla, sobra algo.

---

## PARA RETOMAR ESTO SIN CONTEXTO

Lo mínimo que hay que saber si esta conversación empieza de cero.

**Dónde estamos.** La mesa ya tiene **multibola**: `Mesa` pasa de una bola a N,
la cámara sigue a la más baja, y el eje de Caos de `DISEÑO.md` §8 —que llevaba
escrito desde el principio y sin implementar— existe por fin como mecánica y no
como porcentajes. Escrito **y ejecutado**: batería **414/435 en la caja de la
sesión**, y los 21 que faltan son todos "no existe tal PNG", porque en la caja
no está `assets/`. En el equipo de Daniel tienen que salir los 435.

**Lo primero que hay que hacer, en este orden y antes de tocar nada:**

    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --import
    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/prueba_sim.gd

**En una sesión remota se puede lanzar Godot, y CON VENTANA**: con un display
virtual se abre el juego de verdad, se le mandan teclas y se guardan capturas.
La receta entera está en `CLAUDE.md`, "Godot", y así se cazaron el halo de
magenta y el reloj cortado, que no salían en la batería. **Lo visual se mira, no
se deduce.** Para la batería basta con copiar `sim/`, `data/`, `tests/` y
`render/` y un `project.godot` sin `main_scene`.

**Lo que manda ahora** es `PROPÓSITO.md` §8, la dopamina de mesa: el campo de
pines. Ver "Siguiente".

**Las dos decisiones de la multibola, y las dos son de Daniel:** la cámara sigue
a la bola más baja, y perder una bola con otras vivas no cuesta absolutamente
nada. Las dos se deshacen en un rato si al jugar molestan; no hay nada
construido encima.

## MULTIBOLA: LA MESA YA TIENE N BOLAS (tanda 0e)

`DISEÑO.md` §8 lista cinco ejes de build y el quinto es **Caos: multibola, bolas
extra, aleatoriedad**. Estaba escrito desde el principio y era el único eje sin
una sola línea de código: las nueve reliquias de Caos que había eran nueve
porcentajes con nombre gracioso. **Ahora la mesa tiene bolas de verdad.**

### Lo que se ha montado

**`Mesa.bolas`, un array que nunca está vacío.** Cuando no hay bola en juego
queda UNA, muerta, que es exactamente el estado de antes; por eso `mesa.bola`
sigue existiendo como `bolas[0]` y **ni la vista, ni el combate, ni las 400
pruebas viejas han tenido que reescribirse**. Lo que sí se ha movido de sitio es
el estado que estaba mal puesto: el temporizador del ball search y el "estoy
dentro del girador" eran de la mesa, y con dos bolas eso significa que una le
apaga el aviso a la otra. Viven en `Bola`.

**Choque bola contra bola** (`_colisionar_bolas`), masas iguales y rebote 0,65.
Sin él, la multibola son dos sprites de 18 px atravesándose. **Solo chocan las
bolas libres**: una enganchada a una rampa está en otro plano, igual que las
rampas no colisionan con nada. Y **en un platillo cabe una**: dos dentro salían
disparadas desde el mismo punto y se acuñaban.

**La cámara sigue a la BOLA MÁS BAJA** (`Mesa.bola_en_peligro`). Es lo que no
toca las cuatro reglas ni el escalado entero: se le sigue pasando UNA bola, así
que no hay zoom y el pixelart no hierve. `medir_camara.gd` sigue dando 0 % de
fotogramas sin flipper en plano. **El efecto secundario es la mitad del motivo
de elegirla**: con dos bolas casi siempre hay una abajo, así que durante una
multibola la cámara vive anclada en la banda de las palas.

**Perder una bola con otras vivas no cuesta NADA** —ni vida, ni combo, ni
contraataque—. La señal `bola_drenada` solo salta con la última; las demás
salen por `bola_perdida`, que existe para el sonido y el polvo y para nada más.
Y si caen dos en el mismo subpaso, se cierra UN turno, no dos.

### El eje de Caos, por fin como mecánica

Tres ganchos nuevos, ni un `if` por reliquia, y un prefijo nuevo (`azar_*`:
probabilidades que se suman y contra las que se tira un dado).

| Gancho | Cuándo |
|---|---|
| `azar_bola_extra_recorrido` | al completar cualquier recorrido |
| `azar_bola_extra_banco` | al cerrar un banco de targets |
| `suma_bolas_al_servir` | de salida, cada vez que te sirven bola |

Y la clave que lo convierte en un eje y no en tres reliquias sueltas: `Combate`
publica **`bolas`** en el contexto, así que `cuando: multibola` y `cuando:
bola_sola` ya se pueden escribir en el JSON. Soltar bolas es la mitad de la
build; que las bolas de más CAMBIEN algo es la otra.

Cinco reliquias nuevas (Bifurcación, Proceso hijo, Bomba de procesos, Condición
de carrera, Hilo único). **La bola extra sale por el carril lanzador y sale
disparada a tope**, no aparece en mitad del campo: un lanzamiento a tope engancha
la órbita siempre, así que entra en juego por arriba, dando la vuelta, igual que
la bola con la que empiezas. Cero geometría nueva.

### La decisión que se ha tomado y hay que saber que se tomó

**El eje de Caos pasa a tener 14 reliquias y los otros cuatro siguen con 9.** La
batería exigía que fueran los mismos y se ha aflojado a "al menos nueve"
(decisión de Daniel). Lo que se paga, dicho para poder deshacerlo sabiendo qué se
deshace: **la ruleta sortea por RAREZA, no por eje**, así que Caos pasa del 20 %
al 28 % de lo que se ofrece. Si al jugar sale demasiado, la salida no es volver a
cerrar la prueba: es sortear por eje, o subir los otros cuatro.

### Y SE HA MIRADO JUGANDO, con display virtual, y ha destapado algo

**Lo que se hizo:** arrancar el juego de verdad en la caja (Xvfb + un autoload de
usar y tirar que no va al repo), empezar un run, entrar al primer combate, meter
cuatro bolas y dejarlo 16 s dando a las palas, midiendo fotograma a fotograma
cuántas bolas vivas quedaban FUERA del rectángulo que se está viendo.

**El resultado, y no salía en ninguna prueba:**

| Qué | Medido |
|---|---|
| Fotogramas con dos o más bolas y ALGUNA fuera de plano | **61-67 %** |
| De esas, por arriba / por abajo | **79 / 2** |
| Lo más lejos que llegó a estar una bola por encima del borde | **485 px** |

O sea: **la mesa mide 1300 de alto y por la ventana caben 540**, así que con la
cámara siguiendo a UNA bola las demás se salen por definición, y casi siempre por
arriba —la que está dando la vuelta a la órbita—. Con una bola esto no podía
pasar, y por eso no existía el problema.

**Arreglado, y sin tocar la cámara:** `_dibujar_bolas_fuera()` pone una punta de
flecha dorada pegada al borde por el que se ha ido la bola, en su x y del tamaño
de la bola, y más pálida cuanto más lejos esté. **No es zoom**: alejar la cámara
rompe el escalado entero y la mesa hierve (`CLAUDE.md`). Mirado en las capturas:
se leen.

**Y de paso cayó una trampa vieja con cara nueva:** la primera versión ponía la
flecha a 10 px del canto de la pantalla y NO SE VEÍA, porque la cáscara va en la
capa 5 y la mesa en la 0, así que quedaba detrás de la barra de título. Es
exactamente lo que escondía la bola en lo alto de la órbita. Ahora el margen sale
de `cam.alto_franja_hud`, que es el mismo número que usa la cámara.

### Y está medido lo que se podía medir, que era la mitad importante

**El motor de multibola es EXACTAMENTE NEUTRO con una bola.** Corriendo
`medir_daniel.gd` en la caja, con el motor nuevo puesto y las cinco reliquias
nuevas sacadas del JSON, salen los mismos seis números dígito a dígito que antes
de tocar nada: **462 seco · 729 d/bola · 137 s · 7,6 reliquias · 71 % de vida ·
3 de 5 runs**. O sea que pasar de una bola a N no ha movido el balance ni un
punto, que es justo lo que había que demostrar antes de creerse nada más.

**Y las cinco reliquias nuevas SÍ mueven el balance, y mucho:** con ellas dentro,
el mismo perfil acaba el run con el **97 % de vida** en vez del 71 %, con 835 de
daño por bola y combates de 128 s. Medido, no supuesto.

**No es `condicion_de_carrera`**, que era el sospechoso obvio: quitándola sola el
número se queda en 97 %. **Son las bolas extra**, que vuelan solas y pegan gratis.

**Pero ese 97 % no vale como veredicto, solo como aviso**, y hay que saber por
qué: `medir_daniel.gd` **no sabe JUGAR con varias bolas** —sus perfiles no tienen
física dentro—, así que la bola extra le da todo el daño y no le cuesta ninguna
de las dos cosas que cuesta jugando: repartir la atención y perderlas. De paso se
ha arreglado ahí un fallo de verdad: el drenaje de mentira apagaba solo
`mesa.bola` y dejaba las extra vivas para siempre.

**Conclusión, y manda en el orden del plan:** calibrar el eje de Caos exige antes
que el medidor sepa jugar con N bolas. Va en "Siguiente" 1b, con el rebalance.

### Lo que NO está y hay que saberlo antes de jugar

- **El eje de Caos no está calibrado**, por lo de arriba: las cinco reliquias
  están puestas a ojo y el medidor no puede juzgarlas. **El rebalance con
  multibola va DESPUÉS de la Fase 6**, como el otro.
- **No hay arte de multibola.** Las bolas extra se dibujan todas iguales a
  propósito —una bola extra no es de segunda, pega lo mismo y se pierde igual—
  pero no hay ni contador en pantalla ni sonido propio: la bola extra suena con
  el arpegio del combo, que es un préstamo, igual que las reliquias.
- **Las cinco reliquias nuevas no tienen icono**, y suben a 32 las que no lo
  tienen.

## LA CÁMARA: DOS INTENTOS FALLIDOS Y EL BUENO (REGLA 5)

Daniel, jugando: *"se siente super mal a la hora de ponerse abajo, se
teletransporta"* — y después del primer arreglo, *"sigue siendo brusca al bajar
**en cierto punto**"*. Las dos veces tenía razón y las dos por un motivo
distinto. **Lo caro fue entender que se estaba midiendo el número equivocado.**

### Intento 1: tope de velocidad. Arregló el salto y no la sensación

Las dos garantías duras de `avanzar` —el techo de la barra de título y el suelo
que promete ver dónde cae la bola— se aplicaban DESPUÉS del suavizado, como un
`minf` y un `maxf`. Medido: **113 px en un fotograma, 13.616 px/s**. Se limitó la
velocidad y el salto bajó a 15 px… y seguía sintiéndose mal, porque un tope de
velocidad es **velocidad constante con arranque y parada instantáneos**, que es
lo más mecánico que puede hacer una cámara.

### Lo que de verdad se nota es la ACELERACIÓN, no el salto

Ese fue el cambio de instrumento, y con él se vio todo. `medir_camara.gd` §4 mide
ahora el pico de aceleración con seis bolas de verdad, y ahí estaban las dos
causas:

**(a) El "en cierto punto" era literal.** `suelo_visible` tenía escrito
`if bola_y > alto_mesa - margen_ancla: return alto_mesa`, o sea que al cruzar la
bola la línea de seguridad (y=1000) el suelo garantizado saltaba de ~1150 a 1300
**de golpe, siempre en el mismo sitio de la mesa**. Quitado: la REGLA 2 la sigue
poniendo `objetivo()`, así que no se afloja nada.

**(b) El objetivo dependía de `vy`, y `vy` NO es continua.** El suelo vale
`bola_y + vy × t_ant + margen`, y `vy` salta entero en cada salida de rampa, cada
bumper, cada palazo. **Un objetivo que salta no se puede suavizar sin perder la
garantía**: o la cámara llega a tiempo dando un corte, o va suave y se pierde el
flipper. Probadas las dos, medidas las dos, y las dos se notan.

### El arreglo: que el objetivo dependa solo de la POSICIÓN

`tiempo_anticipacion` pasa de 0,18 a **0**, y lo que se deja de pagar en
predicción se paga en margen: `margen_debajo_bola` de 150 a **300**. La posición
sí es continua, así que el objetivo ya no da ningún golpe.

|  t_ant | margen | Peor salto | Pico de aceleración | Sin flipper |
|---|---|---|---|---|
| 0,18 | 150 | 91,6 px | 1.244.744 px/s² | 0 % | ← como estaba |
| 0,09 | 150 | 36,3 px | 447.208 px/s² | 3 % |
| 0,00 | 150 | 8,4 px | 117.951 px/s² | **8 %** ← se pierde |
| 0,00 | 250 | 7,1 px | 76.637 px/s² | 0 % |
| **0,00** | **300** | **~6 px** | **~68.000 px/s²** | **0 %** ← elegido |
| 0,00 | 350 | 5,4 px | 60.132 px/s² | 0 % |

**15 veces menos salto y 18 veces menos aceleración, sin perder ni un fotograma
de flipper** — comprobado hasta con la caída recta a 1900 px/s, más rápido de lo
que la mesa puede producir. Los 300 px salen de una cuenta: el muelle va por
detrás como mucho `vy × tiempo_suavizado`, o sea 1500 × 0,16 = 240, y 300 deja
holgura.

### Y el suavizado pasa a ser un muelle

`lerp` arranca a tope y frena (tirón al empezar); un tope de velocidad no arranca
ni frena (mecánico). Un **muelle críticamente amortiguado** arranca de cero,
acelera, frena y nunca se pasa de largo. El dial es `tiempo_suavizado` = **0,16
s**, y ahora se piensa en segundos en vez de en un factor que además dependía de
los FPS.

### Las tres redes, y por qué están las tres

1. **Las garantías van en el OBJETIVO** (`objetivo_completo()`, pura y
   comprobable): el muelle sale hacia allí con tiempo y llega suave.
2. **Y otra vez al final, como red**: dentro de la zona muerta la cámara no se
   mueve, así que el objetivo no se aplica — sin esta red la bola se subía detrás
   de la barra de título (lo cazó la batería: 8 fotogramas, hasta 22 px de 24).
3. **Y el tope de velocidad, dormido casi siempre**: el peor fotograma jugando
   mueve ~6 px y el tope está en 21. Existe para lo que el medidor no ve — cuando
   **la BOLA se teletransporta** (se sirve otra, empieza otro combate) el objetivo
   se va al otro extremo de la mesa. Medido en el juego corriendo: **659 px en un
   fotograma**. Con el tope, un barrido de un cuarto de segundo.

**Dos pruebas nuevas** lo cierran: el tope de velocidad y **el pico de
aceleración**, con el techo una orden de magnitud por encima de lo que sale hoy —
es una alarma de que ha vuelto un objetivo discontinuo, no un ajuste de tacto.
Batería **438**, mismos 21 fallos de assets.

**Si aún se siente mal, el dial es `tiempo_suavizado`** (más alto = más cine, más
bajo = más pegada), y el que decide cuánta mesa se ve por debajo de la bola es
`margen_debajo_bola`. Los dos están medidos arriba.

## EL RUN DE DANIEL DEL 15 DE AGOSTO, Y LO QUE DICE

Ganado entero, acto 3, 15 nodos. **Es la primera partida de verdad con el
rebalance dentro**, y sin ninguna reliquia de multibola.

| | Antes del rebalance | Ahora | Modelo (`d-flojo`) |
|---|---|---|---|
| Vida al acabar | 98 % | **90 %** (976/1080) | 71 % |
| Daño por bola | 797 | **1450** | 729 |
| Combate medio | 45 s | **80 s** | 137 s |
| Bolas jugadas | 43 | **72** | — |

**El rebalance ha hecho algo, y se puede decir cuánto:** los combates duran casi
el doble y hacen falta 29 bolas más para ganar el run. Pero **el objetivo era
acabar entre el 25 y el 60 % de vida y sigue acabando al 90 %**, así que el
resultado es exactamente el que anunciaba el barrido: sin comportamientos de
enemigo no hay tabla de números que llegue a esa banda. Es la razón por la que la
Fase 6 existe, ahora medida con un jugador de verdad y no solo con el modelo.

**Y el modelo SIGUE sin ser Daniel, en otra dirección que antes.** Daniel pega el
doble por bola (1450 contra 729) y sus combates duran la mitad (80 s contra 137).
O sea: mata tan rápido que el reloj del enemigo le pega la mitad de veces, y por
eso acaba con más vida que el modelo aunque el modelo esté calibrado. **Lo que le
falta al perfil no es daño, es ritmo**: `medir_daniel.gd` reparte los tiros en el
tiempo como si todos costaran lo mismo. Va con la tanda 1b.

## LAS TRES TANDAS ANTERIORES, EN CORTO

Detalle borrado por la regla de tamaño de este fichero. Lo que sobrevive es lo
que sigue mandando en decisiones de hoy.

**Los cascabeles son elementos, no porcentajes (tanda 2b).** Fátima: *"cambiar de
cascabel es MUY inútil, esto tiene que ser un roguelike progresivo frenético"*, y
tenía razón por arquitectura: montados como bolsa de modificadores salieron
medidos, equilibrados y **completamente invisibles**, porque una bolsa de
modificadores solo sabe producir porcentajes y **para que PASEN COSAS hacen falta
eventos**. De ahí `sim/estados.gd`: veneno, escarcha, brasa, marca y frenesí, que
duran en el tiempo y acumulan. **Es la misma lección que ha traído la multibola**,
y ya van tres veces: lo que no se ve pasar, no existe.

**La capa de Preparación (tanda 2), hecha y medida.** Nueve cascabeles y cuatro
juegos de palas, todo abierto desde el primer día (`DISEÑO.md` §5). Un cascabel
no es código: es una bolsa con nombre que entra por `BolsaReliquias.base` usando
los ganchos que `Combate` ya leía. Las palas sí tocan la física, y por eso
`_montar_combate()` rehace la mesa entera al empezar el run: cambiar de palas
sobre una mesa ya hecha no hace nada.

**Guardado, clics, menú de Inicio y `RECUPERADO/` (tanda 1).** `sim/guardado.gd`
(escritura atómica en `user://`), 22 piezas recuperables, `render/regiones_clic.gd`
y `render/nodo_sistema.gd`. Al cerrar un run —**se gane o se pierda**— se paga
`1 + nodos_superados/5` piezas: que un run perdido también pague es la decisión
entera de la tanda. Lo que se recupera son criaturas (skin) y registros (texto),
así entra la meta-progresión sin reabrir `DISEÑO.md` §13.

**El rebalance, y por qué el modelo mentía.** `medir_balance.gd` juega el run con
un jugador que no completa misiones, así que llega al jefe con la bolsa vacía;
Daniel llega con once reliquias. **No medía un balance flojo, medía a otro
jugador.** `tests/medir_daniel.gd` lo arregla y acaba el run al 99 % de vida
contra el 98 % real. El barrido de vida × ataque dice lo que ya avisaba
"Abierto": **de 20 casillas, ninguna deja el run entre el 25 y el 60 % de vida**,
porque un enemigo con solo vida y un ataque por reloj pega picos, no presión.
**Lo que falta no es un número: son los comportamientos de la Fase 6.** Lo mejor
alcanzable sin ella ya está escrito: vida ×3, ataque ×0,7, curación de reliquias
a un tercio, combate medio de 52 s a **137 s**, y 3 de 5 runs acabados.

**Y la cámara, que tenía dos averías que cazó Fátima jugando** con la batería en
verde encima de las dos: quedaba parada a 45 px del ancla para siempre (los
últimos 45 px de mesa, los del drenaje, no se veían nunca) y el 57 % de los
fotogramas bajos no tenían el flipper en plano. Las dos a 0 %. El detalle está en
`CLAUDE.md`, "Trampas", y `tests/medir_camara.gd` mide `y_actual`, no la
intención.


## Hecho

- **MULTIBOLA.** `Mesa` pasa de una bola a N con choque entre bolas, estado por
  bola y drenaje que solo cuenta cuando cae la última; la cámara sigue a la más
  baja. **414/435 en la caja de la sesión** (los 21 que faltan son PNG que allí
  no están). Ver arriba.
- **La multibola mirada jugando, no deducida.** Con display virtual: 61-67 % de
  los fotogramas con dos o más bolas tenían alguna fuera de plano, casi siempre
  por arriba. Arreglado con flechas en el borde, sin tocar la cámara.
- **El eje de Caos existe.** Tres ganchos de bola extra, el prefijo `azar_*`, la
  clave `bolas` en el contexto y cinco reliquias nuevas. Es el primer eje de
  `DISEÑO.md` §8 que pasa de estar escrito a estar jugado.
- **El cuadro de diálogo del ataque, que era el peor bug que quedaba.** Su
  `relleno` no era un tono plano sino una baldosa con borde, así que al
  repetirse pintaba una **rejilla de ladrillos** por todo el cartel — y ese
  marco solo sale cuando el enemigo ataca. Era el único de los seis recortado a
  mano de una hoja de IA; ahora lo genera `fuente.py` con el mismo perfil
  biselado que los demás.
- **Los carteles del centro se cortaban por el tamaño de letra.** "ESPACIO:
  mantener y soltar para lanzar" salía "…para l", y "MANTÉN A o D PARA ATRAPAR
  Y APUNTAR" igual: a 16 px caben 33 caracteres en los 400 de la mesa y esos
  textos tienen 38 y 35. Ahora `_tam_que_cabe` baja al tamaño que quepa en vez
  de recortar, así que la frase se lee entera.
- **Las tildes, en los datos y en las MAYÚSCULAS.** 52 cambios en
  `data/misiones.json` y `data/reliquias.json` —nombres y textos, uno a uno, no
  buscar-y-reemplazar: "Puntería", "Metrónomo", "El reloj es mío", "daño",
  "cañón", "más", "último"—. Y en la fuente: **la tilde de las mayúsculas iba
  pegada a la letra y en la Í y la É desaparecía del todo** ("CRÍTICO" se leía
  "CRITICO"). Misma regla que la ñ: tilde arriba, fila en blanco, cuerpo
  comprimido a cinco filas.
- **El marco de la ventana de la mesa, que estaba mal montado desde la Fase 5.**
  Se dibujaba con CUATRO marcos de nueve trozos completos alrededor del hueco en
  vez de uno solo sin centro. Un nueve-trozos en una caja más estrecha que sus
  dos esquinas no se encoge: las esquinas se pegan a tamaño completo, se
  solapan entre sí y **sobresalen 4 px hacia dentro del campo por los cuatro
  lados**. Eso era el amasijo de tornillos de las cuatro puntas y lo que le
  comía tablero. Ahora es `NueveTrozos.dibujar_hueco`: un marco, sin relleno.
- **"COMUN" era el identificador del JSON pintado en pantalla.** La rareza, el
  tiro de la misión y el eje de la reliquia compartían una sola tabla para leer
  los datos y para dibujar, y la clave va sin tilde por fuerza. La tele llevaba
  desde la Fase 4 poniendo COMUN, CANON, ORBITA y GOLPE UNICO. Separadas en
  `NOMBRE_*` (clave) y `ROTULO_*` (rótulo): ahora salen **COMÚN, CAÑÓN, ÓRBITA,
  golpe único**.
- **La batería tenía nueve pruebas que no se ejecutaban.** Un mensaje de
  comprobación llamaba a `nombre_rareza()` sobre una `Reliquia`, que no lo
  tenía; GDScript evalúa el argumento aunque la prueba pase, así que abortaba el
  bloque. Eran 312 donde hay 321. Los fallos siguen siendo 13, los mismos.
- **Los textos de la cáscara, mirados de verdad.** Fátima vio en la captura lo
  que yo había dado por bueno. Cuatro cosas, todas del mismo par de causas:
  **la `ñ` se leía como una `n`** (la tilde estaba dibujada pegada a la letra y
  las dos manchas se fundían; la `Ñ` igual), y **tres textos más recortados por
  el `width` de `draw_string`**: la etiqueta "Dirección" del mapa salía
  "Direc", la pestaña de la barra de tareas cortaba el título de "(no
  responde)", y el nombre bajo un icono de reliquia tenía sitio para nueve
  caracteres, así que **41 de las 45 reliquias salían cortadas** — ahora van en
  dos renglones, como un escritorio de verdad, sin salirse por el margen.
  Comprobado todo en captura con la bolsa llena.
- **Assets bugueados, barridos y arreglados mirando el juego.** 36 ficheros.
  El fallo gordo era un **halo de magenta** pegado al contorno de los nueve
  iconos de escritorio, los tres cursores, los seis botones de la barra de
  título, el botón de Inicio y dos esquinas del diálogo: 717 px de fondo que el
  recorte no volvió transparente, invisible en un visor y evidente dentro de
  Godot. Además, sal de cuantización y verdes sueltos en los cursores y en
  nueve reliquias/criaturas. **`cr_espectro` ya no está roto** —la hoja del 13
  de agosto lo regeneró entero— así que sale de la lista de intocables de
  `limpiar.py`. Los tres fixers convergen a cero. Y de paso, dos bugs de
  código que solo se ven jugando: el reloj de la barra de tareas marcaba
  "14:5" (el `width` de `draw_string` recorta y el ancho estaba estimado a
  ojo), y la prueba del crítico llevaba en rojo por un lambda que capturaba
  el contador por valor —el crítico funcionaba—. Los dos en `CLAUDE.md`.
- **Exploración: criatura de fuego coleccionable (cascabel).** Sprite de 8
  frames generado con Claude Design, procesado y limpiado sin `procesar.py`
  real (sandbox sin `scipy`, reimplementado a mano). Confirmado con Fátima:
  desentona sin cuantizar contra reliquias reales, y cuantizado se acerca
  pero el contorno redondeado no es ruido —es la silueta que dibujó la
  IA—, así que limpiar no lo arregla. Queda en `assets/_pruebas/
  cascabel_brasa/`, sin carpeta final ni nodo que lo use.
- **Fase 0** física, flippers, bumpers, targets, daño en vivo, multiplicador
  de combo, vida del enemigo
- **Fase 1** 960×540 con escalado entero y pantalla completa, mesa 400×1300,
  cámara vertical con sus cuatro reglas, órbita bidireccional y dos carriles
  de retorno como splines, platillo que captura, outlanes
- **Fase 2** hitstop, sacudida en píxeles enteros, girador con ocho
  rotaciones pregeneradas, respiración en pasos enteros, nueve sonidos
  sintetizados por `sonidos.py`, banco de 14 voces, efectos de onda, polvo y
  chispas
- **Control de la bola** slingshots sacados del barrido de la pala (era el
  bug que impedía apuntar), flipper a 64
- **Rozamiento de contacto** el solver solo resolvía la normal, así que la
  bola resbalaba eternamente y había que frenarla a mano sobre la pala con un
  amortiguado isótropo: eso es lo que la dejaba pegada. Ahora hay Coulomb en
  los impactos y rodadura en el contacto sostenido, y la cuna la sostiene la
  geometría
- **Coherencia visual** `render/paleta.gd` como sitio único con los 33
  colores y alias por uso; prueba que impide colores inventados en `render/`
- **Multiplicador audible** el arpegio pasa a triángulo (bumper y target son
  cuadradas y se lo comían), cinco notas con la última sostenida, 548 ms,
  +1 dB, reproductor propio fuera de la rueda de voces, y transposición por
  tramo en intervalos musicales: x2 en su tono, x3 tercera menor, x4 quinta
- **Fase 3A** reloj del enemigo: carga mientras juegas, pega drenes o no, no
  para la bola, avisa 3-2-1 por pantalla y por sonido, y no se rearma al
  drenar. El contraataque por drenaje baja a la mitad para que la presión no
  se duplique. Dos sonidos nuevos: el tic y el golpe
- **Fase 3B** los seis tiros pagan seis cosas: el cañón escupe la bola cruzada
  y rápida a la pala contraria (el pago grande se paga con un retorno difícil)
  y el platillo atrasa el reloj, que es el único tiro que no paga en daño.
  Cerrar un banco ya suena distinto de abatir un target
- **Fase 3** (cerrada la sesión anterior, confirmada jugando) reloj del enemigo,
  identidad de los seis tiros, mapa del run, y la tabla de enemigos rehecha con
  `tests/medir_balance.gd`. Lo que salió de ahí y hay que recordar: el coste de
  un combate es `bolas × drenaje + relojes × ataque`, escalar vida no cierra la
  brecha entre jugadores, y la causa real era un escalón de reloj más gordo que
  la diferencia que pretendía medir
- **Fase 3C** mapa del run generado: tres actos, ramas, un jefe cerrando cada
  acto, descanso en la penúltima fila, y la vida que NO se cura entre
  combates, que es lo que hace que elegir rama importe. Pantalla de mapa
  propia con la vida y lo que hay en cada rama; derrota y victoria de run
- **Fase 4** las 45 reliquias escritas con sus once ganchos, la ruleta dentro
  de la tele y las misiones de mesa que las pagan. Sin cerrar: el criterio de
  salida es que dos partidas se sientan distintas, y eso se juega
- **Fase 5** (escrita, sin ejecutar) renderizador de nueve trozos, fuente
  propia pixelart, escritorio con barra de tareas e iconos de reliquia con
  tooltip, TILT como pantalla azul, arte de IA recortado e integrado, y la
  última pasada: HUD y enemigo fuera de la mesa a los paneles de la derecha,
  reloj dentro de la barra de título, mapa como explorador de carpetas,
  fondos con variante por acto y puntero propio

## Diales vivos

Los números que se tocan para ajustar el tacto. Uno cada vez.

| Dial | Valor | Para qué |
|---|---|---|
| `tiempo_suavizado` (cámara) | 0,16 s | **EL dial de tacto de la cámara.** Alto = cine, bajo = pegada |
| `margen_debajo_bola` | 300 px | Cuánta mesa se ve bajo la bola. Suelo 250: por debajo se pierde el flipper |
| `tiempo_anticipacion` | 0 | Subirlo devuelve la predicción por velocidad **y con ella el tirón** |
| `velocidad_maxima` (cámara) | 2600 px/s | Red para los teletransportes de bola. Dormida en juego normal |
| `ancho_outlane` | 21 | Dificultad. Suelo 18, techo ~26 |
| `flipper_longitud` | 64 | Dificultad. Hueco central 47 px |
| `flipper_velocidad_giro` | 30 | Lo lejos que llega tu tiro. Suelo 26: por debajo la cuna no alcanza |
| `flipper_activo_izq/der` | −16° / 196° | Dónde se posa la bola atrapada. Más empinado = sin palanca |
| `flipper_rebote` | 0,25 | Cuánto revive la goma la bola que llega |
| `rodadura` | 4 | Techo. Subirlo aplana la caída; bajarlo no asienta la cuna |
| `friccion_flipper` | 0,30 | Cuánto desvía la goma la bola al rozarla |
| `velocidad_rebote_minima` | 55 | Frontera entre impacto y bola apoyada |
| `target_canto` | 8 | Cuánto sobresale el target al campo |
| `reloj_carga` | 9 s | Solo de reserva: ahora cada enemigo trae el suyo en `data/enemigos.json` |
| `reloj_aviso` | 1,5 s | Tiene que caber holgado dentro de la carga: los relojes empiezan en 6 s |
| `factor_ataque_drenaje` | 0,5 | Cuánto duele drenar frente al reloj |
| curación de reliquias | a un tercio | Si el run vuelve a acabarse al 100 %, es esto antes que la tabla |
| `platillo_atrasa_reloj` | 0,35 | Se mide en fracción de barra, no en segundos: ahora son ~3 s |
| `dano_rampa_fuerte` | 78 | Lo que paga el cañón por ese retorno difícil |
| `curacion_descanso` | 0,30 | Si descansar es siempre obvio, bájalo |
| `filas_por_acto` | 4 | Largo del run. 4 y 3 actos = 12-15 combates |
| `factor_vida_elite` | 1,25 | Cuánto más duro es un élite |
| `casillas_ruleta` | 8 | Lo que se ve girando. Solo la primera es el premio |
| `repeticiones_ruleta` | 1 | Con 0 la build se decide a suertes; con 2+ vuelve a ser un menú |
| `vida_jugador` | **1080** | ×6 por resolución al alargar los combates |
| `reloj` (por enemigo) | 6-10 s | El dial de cuánto APRIETA cada uno, aparte de cuánto dura |
| vida de enemigo | **3750-9660** | Medido con `medir_daniel.gd`. El dial de cuánto DURA el combate |
| `prob_critico` | 0,06 | Cuántos críticos salen. Las reliquias lo suben |
| `factor_critico` | 2,0 | Por cuánto multiplica un crítico |
| `golpes_tramo_extra` | 12 | Lo que pide el tramo que añade una reliquia. Menos y el x5 sale regalado |
| `tiempo_anticipacion` | 0,18 s | Cuánto se adelanta la cámara. Techo real ~0,20: por encima, la bola rápida se mete tras la barra de título |
| `margen_debajo_bola` | 150 | Cuánta mesa se ve POR DEBAJO de donde va a caer la bola |
| `zona_muerta` | 45 | Cuánto tiene que irse el objetivo para que la cámara arranque. Ya no es un error permanente |

**Orden para aflojar la dificultad:** outlanes primero, flipper después.

## Que prueben Daniel y Fátima

**Prueban los dos y cualquiera de los dos puede cerrar una pregunta.** Donde
ponga un nombre, es porque esa en concreto depende de quién juega más horas; el
resto son de quien las mire. La lista se llamaba "Que pruebe Daniel" y eso ya no
era verdad: los textos cortados de la cáscara y las dos averías de la cámara las
encontró Fátima jugando, con la batería en verde encima de las dos.


**Primero importar y luego la batería. En ese orden, y nada de esto se ha
ejecutado:**

    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --import
    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/prueba_sim.gd

**Lo de esta sesión, por orden de lo que más puede haber salido mal. Las M son
de la multibola y ninguna se puede cerrar leyendo código:**

M0. **PARA PROBAR LA MULTIBOLA SIN DEPENDER DE LA SUERTE: F1 y luego F2.**
    F1 enciende la depuración y F2 suelta una bola extra, hasta cuatro. Es banco
    de pruebas y no un atajo del juego: por el camino normal la multibola sale de
    las reliquias de Caos, que son 5 de 50, o sea una de cada diez tiradas.

M1. **LA CÁMARA CON DOS BOLAS, que es la decisión que puede caerse entera.**
    Con F1+F2, o con `bomba_de_procesos` si la ruleta te la da, juega
    una multibola de verdad. Sigue a la más baja, así que se queda casi siempre
    abajo. **(b) ya está medido y arreglado**: el 61-67 % del tiempo había una
    bola fuera de plano, casi siempre por arriba, y ahora hay flechas doradas en
    el borde. Lo que queda es **(a): ¿se puede JUGAR?** ¿Basta con la flecha para
    saber que va a caer algo, o la bola de arriba sigue apareciendo de la nada?
    Y **(c)**: ¿estorban las flechas cuando hay tres? Son un `draw_colored_polygon`
    y se quitan en un minuto.

M2. **PERDER UNA BOLA NO CUESTA NADA, ¿se nota demasiado bueno?** Con multibola
    puedes drenar dos veces seguidas sin que pase nada. Es lo que hace que la
    multibola sea un eje de build y no un adorno, pero también es la red de
    seguridad más grande del juego. Si con una bola extra el combate deja de dar
    miedo, lo que se toca es que la bola extra cueste algo al entrar (reloj), no
    que perderla duela.

M3. **CUATRO BOLAS, ¿son demasiadas?** `bolas_maximas` está en 4 porque es lo
    que cabe en el plano, no porque esté medido. Con las palas llenas, ¿estás
    jugando o estás mirando?

M4. **La bola extra sale disparada por el carril lanzador.** ¿Se ve salir, o
    aparece sin más? Si no se ve, el sitio del aviso es el carril, no el centro.

M5. **Caos sale más que los otros ejes** (28 % contra 20 %) porque tiene 14
    reliquias. ¿Se nota jugando que la ruleta ofrece Caos de más?

S1. **EL SISTEMA OPERATIVO, que es lo nuevo.** Pulsa Inicio durante un combate.
    **(a)** ¿Se entiende que `RECUPERADO` es lo que te falta por conseguir, sin
    que nadie lo explique? Es la apuesta entera de `PROPÓSITO.md` §2: los
    ficheros de 0 KB con el nombre en interrogantes tienen que leerse como "aquí
    había algo", no como una lista de logros bloqueados. **(b)** ¿Congelar la
    mesa al abrir una ventana se agradece o desorienta al volver? Está medido que
    la bola se queda exactamente donde estaba. **(c)** ¿El aviso de "Recuperado:
    ..." al acabar un run se ve, o pasa desapercibido? Dura 6 s abajo a la
    derecha. **(d)** Los iconos a 16 px de la carpeta: ¿se distinguen unos de
    otros o son manchas?

S2. **EL PAGO POR RUN, que es el dial delicado.** Ahora un run paga
    `1 + nodos/5` piezas. Con 22 piezas y 11 de fábrica, quedan 11 por ganar.
    ¿Se siente a tragaperras —una pieza cada vez que respiras— o a que cuesta?
    **Si sobra, el dial es `NODOS_POR_PIEZA` hacia arriba, NO `PIEZAS_MINIMO`
    hacia abajo:** quitarle el pago al run perdido devuelve el problema de
    partida, que es que perder no costaba nada.

C1. **LA CÁMARA, que es lo único de código que cambia esta sesión.** Está medido
    que ya no se queda corta y que el flipper está siempre en plano bajo la
    línea de seguridad, pero lo que se mide no es lo que se siente. Tres cosas:
    **(a)** ¿se ven ahora los últimos píxeles de mesa cuando la bola drena, o
    sobra tanto que la mesa parece más pequeña? **(b)** con un bolazo de los
    fuertes cayendo, ¿la cámara **pega un tirón** al bajar? Si lo pega, el dial
    es `suavizado`, y si el tirón es al cruzar la línea de seguridad, es
    `margen_ancla`. **(c)** ¿la bola se te esconde detrás de la barra de título
    en alguna bajada rápida? Está medido que llega a 48 px del borde contra los
    24 del marco: es poco margen y es lo que más fácil se me escapa. El dial es
    `tiempo_anticipacion` (0,18): bajarlo separa la bola del borde y acerca la
    cámara a la bola.
N1. **¿SE VE LA BOLA EN LO ALTO DE LA ÓRBITA?** Es la prueba de que quitar el
    HUD ha servido para algo. Antes tenía 58 px opacos encima; ahora 24. Lanza a
    tope diez veces y mira si la bola sale por arriba del todo sin esconderse.
N2. **EL RELOJ EN LA BARRA DE TÍTULO.** Está pegado a la mesa, escrito y con
    barra, arriba del campo. ¿Lo pillas de reojo sin dejar de mirar la bola, o
    te enteras de que te van a pegar cuando ya te han pegado? **Si esto falla,
    falla la decisión entera** y el reloj vuelve a estar sobre el tablero.
N3. **EL ENEMIGO EN SU PANEL, a la derecha.** ¿Se lee el destello al pegarle
    ahora que está siempre a la vista? ¿Y la disolución al matarlo, con la
    explosión dentro del panel? Antes casi nunca estaba en plano.
N4. **LOS TRES PANELES DE LA DERECHA.** ¿Cabe todo sin apretarse y se lee sin
    girar la cabeza? Lo que más miedo me da es la vida: mirar a un lado para
    saber cuánta te queda mientras persigues la bola puede ser peor que tenerla
    encima. Si lo es, dilo y la vida vuelve a la barra de título con el reloj.
N5. **EL MAPA COMO EXPLORADOR.** Ruta arriba, detalles del nodo marcado a la
    izquierda, "N objetos" abajo, y los nodos como archivos con su extensión
    (`rata.exe`, `descanso.tmp`, un jefe en `.sys`). ¿Se sigue eligiendo rama
    igual de rápido, o el mueble se ha comido la legibilidad del grafo?
N6. **EL PUNTERO.** Ahora es el nuestro, pixelart, y el del sistema se esconde
    dentro de la ventana. ¿Va donde tiene que ir? ¿Sale el reloj de arena
    durante la ruleta? Si al hacer alt-tab desaparece y no vuelve, dímelo: es lo
    más fácil de que se me haya escapado.
N7. **LA VENTANA DE LA MESA, que hasta ahora no se veía.** Barra de título con
    "cascabel.exe" y tres botones, encima del campo. Es la primera vez que está
    en pantalla de verdad. ¿Se entiende la broma de un vistazo? **Ese es el
    criterio de salida de la fase.**
N8. **LOS FONDOS BUGUEADOS.** Cambian entre combate y combate. Acto 1 limpio,
    acto 2 con dos maneras de fallar, acto 3 con cuatro. ¿Se nota que el sistema
    se va cayendo, o pasa desapercibido?

**LO PRIMERO DE TODO, que es el rebalance y es lo que más puede haber salido
mal.** Un run entero con la tabla nueva, y estas cuatro:

R1. **¿SE HACE PESADO UN COMBATE?** Ahora duran 137 s de media contra los 45 de
    antes: tres veces más. **Esta es LA pregunta de la sesión.** Si se hace
    pesado, no es que la vida esté alta: es que el enemigo es un saco, y lo que
    toca es la Fase 6, que ya está puesta la primera de "Siguiente" por medida.
R2. **¿En qué nodo mueres y con cuánta vida llegas al jefe de cada acto?** El
    modelo dice 3 de 5 runs acabados y el 71 % de vida al ganar. Si acabas
    siempre y por encima del 90 %, el modelo se ha vuelto a quedar corto.
R3. **Las reliquias de cura, que han bajado a un tercio.** "Rutina de
    reparación" pasa del 8 % al 3 % y "Desfragmentación" del 2 % al 0,7 %.
    ¿Siguen mereciendo la pena o han quedado en nada? Si nunca las eliges, se
    subirá el número, pero **no al de antes**: al 8 % el run se curaba entero.
R4. **¿Sigue el reloj sin apretar?** Con el combate a 137 s comes muchos más
    relojes que antes. Si aun así no notas nada, el problema no es cuántos
    comes sino que cada uno pega poco, y eso ya no se arregla con la tabla.

M. **LOS SPRITES REPARADOS.** Mira sobre todo la calavera llameante, la
   sombra y la armadura vacía: a la armadura le he quitado unas motas verdes
   sueltas que tenía en hombros y piernas. Si ves algún bicho al que le falte
   un trozo o le sobre un pegote, dímelo por nombre.

M2. **LOS ICONOS DEL ESCRITORIO Y LOS CURSORES, sin el halo rosa.** Estaba
   comprobado ampliando la captura del juego y ya no está, pero el arreglo
   quita píxeles del contorno: mira que ningún icono haya adelgazado por un
   lado. Los que más perdieron son `registro`, `disco` y `papelera`.

M7. **LAS MAYÚSCULAS CON TILDE.** Á É Í Ó Ú Ü tienen ahora el cuerpo una fila
   más corto para que la tilde quepa encima. Mira "CRÍTICO" en `jugador.sys` y
   "COMÚN" en la tele: la tilde se ve, pero la letra queda algo más baja que
   sus vecinas. **Si prefieres las mayúsculas a plena altura y la tilde
   apretada, se deshace borrando la fila `"     "` de esos seis glifos en
   `fuente.py`.** Es tuyo.

M8. **EL CARTEL DEL ATAQUE.** Es el que estaba lleno de ladrillos. Ahora es un
   cuadro de diálogo gris claro. ¿Se lee el nombre del enemigo y el daño de un
   vistazo, con la bola parada detrás?

M6. **EL MARCO DE LA VENTANA DE LA MESA.** Es lo que más ha cambiado de sitio:
   ya no hay tornillos en las cuatro puntas y el marco no se mete en el campo.
   Mira si ahora se ve DEMASIADO liso —son 8 px de gris y nada más— o si con la
   barra de título y los tres botones ya cuenta la broma. **Ese sigue siendo el
   criterio de salida de la fase (N7).**

M4. **LOS NOMBRES DE RELIQUIA EN EL ESCRITORIO.** Ahora son dos renglones. ¿Se
   leen, o el escritorio se ha llenado de texto? El paso vertical entre iconos
   ha subido de 54 a 66 px para que quepa el segundo renglón: si con doce
   reliquias la banda se queda corta, se ve enseguida.

M5. **LA Ñ Y LAS TILDES.** "goblin_carroñero" ya sale con la tilde. Las tildes
   de á é í ó ú siguen tocando la letra —se leen, pero van pegadas— y **eso no
   lo he cambiado porque es tuyo**: si las quieres separadas, es una línea en
   `fuente.py` (tilde en la fila 0 y la 1 en blanco). Tengo las dos versiones
   comparadas si quieres verlas.

M3. **EL ESPECTRO.** Llevaba en la lista de "roto, no tocar" desde el fallo del
   magenta y **hoy sale entero**: cero interior comido, cero motas. Míralo en el
   mapa y confirma, y si está bien esa línea se cae del plan.

A. **LAS MISIONES, que es lo nuevo y lo que hay que juzgar.** ¿La tele te dice
   con claridad qué toca? ¿Te descubres yendo a por un tiro concreto porque lo
   pide la misión? Si te da igual lo que ponga y sigues dando tumbos, la misión
   no está hecha para leerse mientras juegas y hay que agrandarla o simplificarla.
B. **¿Las casillas de progreso se leen de reojo?** Son la fila de cuadraditos de
   abajo de la tele. Un "2/3" en letra pequeña no se lee persiguiendo una bola;
   la apuesta es que tres cuadraditos sí.
C. **La ruleta a mitad de combate.** Ahora la bola se queda congelada donde
   estaba y luego sigue. ¿Desorienta al reanudar, o se agradece la pausa? Es lo
   que pediste y es lo que menos claro tengo.
D. **Las misiones "sin drenar".** Al perder la bola sale "MISIÓN PERDIDA". ¿Se
   entiende que era por eso, o parece un castigo de la nada?
E. **¿Sigues muriendo pronto?** Si sí, dime en qué combate y con cuánta vida
   llegabas, y con los dos números de arriba lo dejo cuadrado.
F. **¿Se hacen largos los combates ahora que hay misión dentro?** Esa es la
   apuesta entera de la sesión.
G. **Los números de daño.** ¿Se leen sin dejar de mirar la bola? ¿El tamaño
   distingue de verdad un bumper de un cañón? Si saturan la pantalla, el dial es
   el rango 10-22 px de `_numero_de_dano` en `render/vista_mesa.gd`.
I. **LA FUENTE a 8 px.** Ahora casi todo el texto va a ese tamaño, así que pesa
   más que nunca: una fuente de 5×7 es legible o no lo es, y eso no lo dice
   ninguna prueba. Si alguna letra se confunde con otra, dime cuáles: se
   arreglan en `fuente.py`, que las tiene escritas como dibujos de texto.
J. **Los iconos de reliquia, pasando el ratón por encima.** ¿El tooltip llega a
   tiempo y dice algo útil? Y lo importante: **¿se ve encenderse y apagarse un
   icono condicional** cuando cruzas su umbral en mitad de un combate?
K. **La pantalla de TILT.** ¿Da ganas de volver a intentarlo? Ahí salen los dos
   números que necesito.
L. **El pendiente de siempre: ¿la ventana del pinball cuadra en tu portátil**, o
   sigue desbordando? Ahora hay tres paneles más midiendo contra la misma
   pantalla, así que si algo se sale se va a ver antes.
H. **Los críticos.** 6 % de base, ×2. ¿Salen lo bastante como para notarlos y lo
   bastante poco como para que sigan siendo un premio? Diales: `prob_critico` y
   `factor_critico`. Si te parece que el daño se ha vuelto aleatorio, es que la
   probabilidad es demasiado alta o el cartel no se lee.

Lo de abajo es lo que sigue sin comprobar (lo ya contestado se ha borrado:
cuna, reloj-como-carrera, cañón, outlanes y drenaje están bien).

0b. **La apertura.** Lanza a tope diez veces seguidas sin tocar nada más. La
   bola tiene que dar la vuelta por la órbita y **caerte en la pala
   izquierda**. Si vuelve a irse por el outlane, la boca se ha quedado corta.
1. **Atrapar la bola, que es lo que estaba mal.** Con la pala levantada debe
   RODAR hasta el hueco del eje y quedarse ahí (~0,6 s), no clavarse donde
   toque. Y con la pala en reposo no debe quedarse nunca: rueda y se va.
   Si sigue soldándose, baja `rodadura`; si no llega a asentarse, súbela.
4. **Los huecos del tablero en negro y el destello al pegar**, que es lo
   único que cambió de color.
6. **Subir de tramo, con el racimo sonando.** ¿Se oye que has subido sin
   mirar el número? ¿Y se distingue x3 de x4 solo por el tono? Si tapa
   demasiado los golpes, el dial es `db` de `combo` en `nodo_sonido.gd`.
8. **Que el golpe del reloj no se lea como injusto.** Llega en mitad de la
   bola y no para nada, a propósito. Si sorprende, el aviso de 3-2-1 es
   corto: `reloj_aviso`.
10. **El platillo, ahora que se ve lo que hace.** ¿Compensa buscarlo por los
    ~6 s, o prefieres siempre el cañón? Si nunca lo eliges, sube
    `platillo_atrasa_reloj`. **Ojo: esta pregunta no valía antes**, porque no
    se sabía que daba tiempo. Es la primera vez que se puede contestar.
11. **A ciegas, sin mirar la pantalla:** ¿sabes qué acabas de conseguir solo
    por el sonido? Racimo, target, banco cerrado, órbita, retorno, cañón y
    platillo tienen sonido propio. Si dos se confunden, dime cuáles.
13. **¿La vida aguanta un acto?** Si mueres siempre en el acto I, o el reloj
    aprieta demasiado o los enemigos tienen mal la vida. Dime en qué nodo
    mueres y con cuánta vida llegabas.
14. **¿Eliges rama de verdad?** Si siempre coges la misma sin mirar, o las
    ramas no se diferencian lo bastante o falta información en el mapa.

## Siguiente

**Por tandas. Una por sesión, y el modelo de cada una entre paréntesis.**
**El orden lo manda ahora `PROPÓSITO.md` §11**, que es donde está entero y con
el porqué de cada puesto. Resumen: guardado + clics + `RECUPERADO/` → capa de
Preparación → la cáscara reacciona → dopamina de mesa → rampas fallables →
selector de dificultad → tapar agujeros → **Fase 6** → reabrir §13.

0. ~~**Guardado + clics + menú de Inicio + `RECUPERADO/`**~~ **HECHA Y
   EJECUTADA.** Batería 358/358. Ver arriba.

0b. ~~**La capa de Preparación**~~ **HECHA Y MEDIDA.** 381/381. Ver arriba.

0c. ~~**Los cascabeles pagan en RELOJ, no en daño**~~ **HECHO Y MEDIDO.** Ver
   arriba. Y de paso ha quedado medido el pilar de `DISEÑO.md` §1, que no lo
   comprobaba nadie.

0e. ~~**MULTIBOLA**~~ **HECHA Y EJECUTADA.** 414/435 en la caja (los 21 que
   faltan son assets que allí no están). Con ella, el eje de Caos deja de ser
   nueve porcentajes. Ver arriba. Lo que queda de esta tanda son las preguntas
   M1-M5, y M1 puede tirar la decisión de cámara entera.

0f. **Y después: `PROPÓSITO.md` §8, la dopamina de mesa** (el campo de
   pines con **Opus + alto**, porque es geometría nueva y cada rincón es un
   sitio donde la bola se acuña; los props y placas ya recortados con **Sonnet +
   medio**). Sube de puesto por lo que ha salido midiendo: **el jugador de
   racimo hace 265 de daño por bola contra los 1999 del de recorridos**, o sea
   que el racimo paga 7,5 veces menos. Que el tiro difícil pague más es
   `DISEÑO.md` §7, pero 7,5× no es una pendiente, es que la mitad de la mesa no
   compensa — y es justo la mitad que Fátima quiere llenar de sitios donde pegar.

1. **FASE 6: comportamientos de enemigo** (Opus, razonamiento alto). **Baja de
   puesto por decisión de Fátima, no porque la medida haya cambiado:** el
   barrido sigue diciendo que con un solo ataque por reloj no existe ninguna
   tabla que deje el run en la banda de dificultad que se busca. `DISEÑO.md` §11
   tiene los seis (bloquear un recorrido, curarse, reflejar, blindaje, castigar
   el combo, acelerar el reloj). Y con combates de 137 s, un enemigo que solo
   tiene vida se nota que es un saco
1a. ~~**PONER LA BATERÍA EN VERDE**~~ **HECHA. 321/321.** Ver el detalle en
   "Abierto". Falta el commit.
1b. **Rebalance, segunda pasada** (Opus, alto), DESPUÉS de la Fase 6 y no antes,
   **y ahora tiene que contar la multibola**: `medir_daniel.gd` juega con
   perfiles sin física dentro, así que no sabe soltar bolas ni jugarlas y lo que
   diga de una build de Caos no vale. Antes del rebalance hace falta que el
   medidor sepa jugar con N bolas, o las cinco reliquias nuevas se calibran a
   ojo. Lo de siempre:
   con comportamientos dentro, `tests/medir_daniel.gd` vuelve a barrer y la
   banda del 25-60 % pasa a ser alcanzable. Hasta entonces, tocar la tabla es
   mover el mismo número por cuarta vez
2. ~~**Tanda de assets A: la hoja del espectro**~~ **HECHA sin gastar tanda:**
   la hoja del 13 de agosto ya lo había regenerado y nadie lo había medido.
   Sale de la lista de intocables de `limpiar.py`. Falta que Daniel lo mire (M3)
2b. **Cerrar la criatura del cascabel** (Sonnet, medio para colocarla;
   Opus + Daniel/Fátima si hace falta reabrir el estilo de borde). Decidir
   destino final (¿`reliquias/`? ¿carpeta nueva?), decidir si se acepta el
   contorno más suave o se regenera, correr `procesar.py` real para
   confirmar el resultado, y conectar el nodo que la use
3. **Tanda de assets C: piezas de bandeja de sistema** (Sonnet, medio). Es lo
   único que queda de `assets/prompts_cascara.md` §2 sin generar: reloj con
   sprite propio, separador, altavoz e icono de sin-red. La barra de tareas
   dibuja su bandeja con `draw_rect` a mano hasta entonces. **Guardar la hoja**
4. **Tanda de assets D: los 27 iconos de reliquia que faltan** (Sonnet,
   medio), con `assets/prompts_reliquias.md`. Se ven en tres sitios —tele,
   escritorio y tooltip—, así que se notan
5. **Fase 5: juzgarla jugando** (Daniel). El código está escrito entero y sin
   ejecutar. Lo que queda no se lee, se juega: las preguntas N1-N8 de arriba. Si
   N2 o N4 salen mal, lo que vuelve a la mesa es reversible en un rato
7. **Animación fotograma a fotograma de enemigos/criaturas/jefes** (Opus,
   razonamiento alto). Pedida por Daniel y por Fátima. **Los prompts ya están
   escritos, y ahora también la guía de estilo de la que dependían**: los tres
   ficheros de prompts empiezan por "Following the style guide above" y esa guía
   no estaba en el repo, así que ninguno generaba lo que decía. Está en
   `assets/GUIA_ESTILO.md`, **y es la original que pasó Fátima, no una
   reconstrucción**: bloque A el suyo tal cual (la línea que más trabaja es "in
   the style of Peglin"), bloque B tres líneas añadidas contra fallos ya
   medidos —el magenta que se comió el 22 % del espectro, el contorno redondeado
   que no se puede reparar, y las celdas con hueco que descuadran la hoja—.
   **La paleta va en palabras y NO en hex a propósito**: `procesar.py` cuantiza
   después, así que los códigos no aportan. Y de paso queda recuperado el prompt
   que generó `assets/mesa/`, con sus nueve objetos mapeados. **Y el prompt del cascabel estaba mal de diseño**:
   dibujaba campana y criatura juntas, que no se puede rotar (`DISEÑO.md` §4
   pide dos capas). Reescrito: las 9 criaturas van solas, 8 fotogramas, celda
   64, piloto `cr_brasa`. El orden de las hojas está al final de
   `assets/prompts_animacion.md`: hoja 4×4 por bicho (idle, golpe, ataque,
   muerte), las nueve descripciones con escala común, los jefes a 4×5, el
   cascabel de fuego, y el subsistema que hace falta. Hoy todo bicho es UN
   sprite estático deformado por código —`render/nodo_enemigo.gd`: respiración
   y embestida son squash/stretch en píxeles enteros, sin un solo fotograma de
   verdad—. Hace falta un subsistema nuevo: hojas de varios fotogramas y un
   reproductor que las pase, respetando rejilla de píxeles y escalado entero.
   Opus y alto porque es subsistema nuevo que cruza arte + timing + las
   trampas ya cazadas en `CLAUDE.md` (rejilla de píxeles, hitstop en
   `_physics_process`), y los fallos de ese tipo han costado sesiones enteras.
   Diseñar antes de tocar código: cuántos estados por criatura (idle, golpe,
   ataque, muerte), cuántos fotogramas cada uno, y de dónde sale el arte —
   ¿prompts de IA como las hojas de `assets/prompts_cascara.md`, o a mano?

## Mediciones

| Qué | Valor |
|---|---|
| Duración de bola, mesa pequeña | ~10 s |
| Objetivo de drenaje | cada 2-3 bolas |
| Daño por bola: malo / normal / bueno | 42 / 312 / 840 |
| **Run real de Daniel (15-ago, con rebalance)** | **90 % de vida · 1450 d/bola · 80 s · 72 bolas** |
| Run real de Daniel (antes del rebalance) | 98 % de vida · 797 d/bola · 45 s · 43 bolas |
| Motor de multibola, una bola: antes → después | 71 % / 3-5 runs → **idéntico** |
| Con las 5 reliquias de Caos dentro (modelo, no veredicto) | 97 % de vida, 835 d/bola, 128 s |
| Tope de bolas a la vez | 4 (`bolas_maximas`, elegido a ojo) |
| Brecha entre jugar mal y jugar bien | 20× (8,4× sin multiplicador) |
| Vida de enemigos | 225-660, salida del barrido |
| Runs acabados: malo / normal / bueno | 0/5 · 2/5 · 5/5 |
| **Daniel, medido jugando** | **797 por bola · 45 s · 43 bolas · 1764/1800 al ganar** |
| **El modelo reproduciéndolo** | **729 por bola · 99 % de vida al acabar, con reliquias puestas** |
| Tabla nueva, medida | 137 s por combate · 71 % de vida al acabar · 3/5 runs |

**Cuál lanzar:** `tests/medir_balance.gd` mide la economía SECA del combate y
las tablas viejas siguen comparables con él. `tests/medir_daniel.gd` mide el RUN
con reliquias, y es el único que reproduce a Daniel: **para tocar balance, ese**.
La tabla ya se hizo tres veces contra el jugador equivocado.

## El pilar: la cuna ya alcanza

`DISEÑO.md` §1 dice que la mesa es un menú de tiros, y el único tiro
repetible que hay es el de la bola atrapada en la cuna. Estaba roto por dos
sitios y los dos están cerrados. Queda como referencia de dónde se toca:

| | roto | ahora |
|---|---|---|
| Pala levantada | −32° | **−16°** |
| La bola se posa en | 0,18 de la pala | **0,53** |
| Quieta con la pala sostenida | no, picos de 137 px/s | **sí** |
| `flipper_velocidad_giro` | 22 | **30** |
| El tiro sube a | y=1160 | **y=787** |
| A | 290 px/s | **1292 px/s** |
| Y toca | nada | **el banco de targets** |

**Por qué la pala más rápida no acelera el juego**, que era el miedo: está
medido que la ventana de reacción se queda en 150 ms y la duración de bola
en 3,4 s, iguales que antes. Esa ventana la fija la gravedad mientras la
bola CAE; la pala solo decide lo lejos que llega lo que tú tiras.

Y el cañón sigue siendo cazable con la pala nueva: para entrar en su boca
(y=790) la bola llega ya frenada a 500-650 px/s, así que sale a 250-325 y
da 283-342 ms. Por encima de 1200 de entrada se pasaría, pero esa entrada
no se alcanza: la boca está demasiado alta para llegar rápido.

**Lo que sigue sin estar:** la pala izquierda alcanza el banco de targets y
la derecha se queda en y=903 sin tocar nada. O sea que hay UN tiro de cuna
útil, no dos. Alinear cada boca con la línea de tiro de su pala es trabajo
de geometría fina y se hace jugando, no midiendo.

## Abierto

- **NO HAY BOLA-BOLA DENTRO DE LAS RAMPAS NI EN EL PLATILLO, y es a propósito.**
  Una bola enganchada a una curva está en otro plano —las rampas son elevadas—,
  así que las demás la atraviesan. Dos bolas SÍ pueden ir por la misma rampa a la
  vez: el recorrido lo lleva cada bola, no la rampa. En una mesa real se
  solaparían; aquí la de la curva se dibuja como sombra, así que ni se ve. Si
  alguna vez molesta, la salida es una cola por rampa, y es trabajo de verdad.
- **La bola no tiene giro, y ahora se nota más.** Sin spin, dos bolas que chocan
  no se transmiten efecto: el choque es puro impulso normal. La rodadura es la
  aproximación barata y aguanta, pero si en algún momento se quiere una física
  que destaque, el siguiente paso es momento angular, y es un cambio que toca el
  solver entero.
- **`medir_daniel.gd` no sabe jugar con varias bolas**, así que la multibola no
  está medida y las cinco reliquias de Caos están puestas a ojo. Es lo primero
  que hay que arreglar antes del rebalance de la Fase 6 (ver "Siguiente" 1b).
- **Las cinco reliquias nuevas no tienen icono**, y con ellas suben a 32 de 50
  las que no lo tienen. Los prompts están en `assets/prompts_reliquias.md`.
- **La bola extra no tiene sonido propio**: suena con el arpegio del combo, que
  es un préstamo. Igual que las reliquias.
- **`fuente.py` ya no reproduce los marcos del repo, y la tabla de herramientas
  de `CLAUDE.md` invita a lanzarlo.** Medido: al regenerar, las nueve piezas de
  `ventana`, `titulo` y `barra` salen con todos los píxeles distintos y
  `tooltip` sale de 4×4 en vez de 8×8. O los marcos del repo los hizo una
  versión anterior del script, o se retocaron después y no se anotó. Esta
  sesión regeneró la fuente y **restauró los marcos a mano** para no romper
  nada. Hay que decidir cuál de los dos es el bueno. **Mientras tanto, lanzar
  `fuente.py` a secas destruye la cáscara.**
- **Quedan carpetas mías dentro del repo: `_to_delete/`.** Tres carpetas de
  parche ya aplicadas, cuatro `.tgz` y dos `index.lock` sueltos. El puente del
  escritorio NO puede borrar ficheros, así que las dejé ahí y **Godot las
  escaneó**: cada copia de `nodo_cascara.gd` daba "Class NodoCascara hides a
  global script class" y llenaba el editor de rojos que no eran del juego.
  Tapado con un `.gdignore` vacío dentro, que hace que Godot se salte el
  directorio, y `_to_delete/` está en `.gitignore`. **Se puede borrar entera
  desde el Explorador: dentro no hay nada que sirva.**
- ~~Los NOMBRES de misión también van sin tildes~~ HECHO, aparte de los textos:
  "Punteria", "Artilleria", "La maquina", "El reloj es mio". Entra en la misma
  pasada que lo de abajo.
- **La `Ú` de "COMÚN" va apretada.** La tilde de las MAYÚSCULAS se come la
  primera fila de la letra —no hay sitio para más en una celda de 8 px— y a
  ese tamaño la Ú se puede confundir con una O. Se lee, pero si molesta, la
  salida es subir la celda a 10 px, y eso agranda TODO el texto del juego.
  Decisión de Fátima, no mía.
- ~~El texto de las reliquias está escrito sin tildes~~ **HECHO.** Lo que sigue abierto de aquí es solo la `Ú` apretada, arriba.
- **VIEJO, ya no aplica:** 47 palabras en 31
  entradas de `data/reliquias.json` y `data/misiones.json`: "dano", "canon",
  "mas", "Metronomo", "Cuerda de mas", "El reloj es mio". Viene de cuando la
  fuente de reserva no sabía dibujar acentos —el motivo por el que existe
  `fuente.py`— y ese motivo ya no está. `enemigos.json` sí los usa, así que en
  la misma pantalla conviven "goblin_carroñero" bien escrito y "Cuerda de mas".
- ~~LA BATERÍA ESTÁ EN ROJO~~ **HECHO: 321/321 en verde.** Los seis de pantalla
  se arreglaron dándole a `NodoCascara` un `SubViewport` de verdad dentro de la
  prueba — pero eso solo no bastó: `get_root().add_child(...)` en modo
  `--script` NO mete el nodo en el árbol de forma síncrona
  (`is_inside_tree()` da falso hasta el siguiente frame), así que hacía falta
  además un `await process_frame` antes de medir, propagado por los tres
  niveles de llamada (`_prueba_huecos_de_la_cascara` → `_prueba_cascara` →
  `_initialize`). Los siete de constantes viejas eran dos causas: el ataque de
  `_prueba_derrota` se calcula ahora contra `c.p.vida_jugador /
  c.p.factor_ataque_drenaje` en vez de un `1000` fijo, y las cuatro pruebas de
  daño exacto (combo y reliquias) fuerzan `prob_critico = 0.0` —igual que ya
  hacía `_prueba_criticos`— porque un crítico de la probabilidad de base podía
  colarse y doblar cualquier golpe medido. Nada de esto era un fallo del
  juego, medido jugando.
- **`assets/ui_marco/` no lo carga nadie.** Nueve piezas de marco de piedra
  remachada, 28 000 px, con alfa parcial (fleco antialiaseado, que en pixelart
  con escalado entero es fleco borroso) y un halo de magenta de los gordos. No
  se ha tocado a propósito: arreglar arte muerto es ruido. O se conecta o se
  borra, y eso lo decide quien sepa si ese marco se quería.
- **Hay mucho arte generado que el código no usa.** Sin referencia ninguna:
  `bolas/`, `bolas_64/`, `criaturas_64/` (sí se ven, pero por otra ruta),
  `mesa_anim/`, `mesa_placas/`, `mesa_props/`, `mesa_tunel/`, `reliquias2/`,
  `ui_marco/` y **9 de los 13 PNG de `mesa/`** (del bumper de engranaje al
  target de lápida). Los jefes ya se sabía que estaban aparcados a propósito;
  esto otro no estaba anotado. No es un bug, pero explica por qué la mesa se ve
  más pelada que la carpeta de assets.

- **LA `Ó` MAYÚSCULA SE LEE COMO UNA `ó` MINÚSCULA, y ahora se ve porque "Óxido"
  es un cascabel.** No es un fallo de `fuente.py`, es que la salida elegida no
  puede funcionar para esa letra en concreto. Las mayúsculas con tilde llevan el
  cuerpo comprimido a cinco filas para que la tilde quepa encima, y eso funciona
  con la `Á` porque conserva el travesaño —sigue siendo una A sin discusión—,
  pero **un `O` de cinco filas ES, píxel a píxel, una `o` minúscula**: no le
  queda ningún rasgo con el que distinguirse. Comprobado sacando los dos glifos
  del atlas y comparándolos.

      O          Ó          ó
      .###.      ..##.      ..#..
      #...#      .....      .#...
      #...#      .###.      .###.
      #...#      #...#      #...#
      #...#      #...#      #...#
      #...#      #...#      #...#
      .###.      .###.      .###.

  **La salida barata: dejar que las mayúsculas con tilde usen también la fila 7**,
  que hoy está vacía en todos los glifos. Eso da un cuerpo de SEIS filas en vez
  de cinco, y un O de seis filas ya no se confunde con uno de cinco. Es un cambio
  en `fuente.py`. **No lo he tocado por dos razones**: lanzar `fuente.py` destruye
  los cinco marcos de la cáscara (está en Trampas, hay que restaurarlos con `git
  checkout` justo después), y el estilo de las tildes lo decidiste tú.
- **EL ESCRITORIO SOLO SE PUEDE TOCAR DURANTE EL COMBATE, y hay que decidir si
  eso vale.** El mapa (capa 20) y TILT (40) se dibujan MAXIMIZADOS y tapan la
  barra de tareas, que va en la 5. Mientras están delante, el sistema se apaga
  entero a propósito: si no, el botón Inicio seguiría siendo pulsable debajo del
  mapa y sería un clic que abre un menú donde no hay nada dibujado. Pero eso deja
  `RECUPERADO` accesible solo con un combate empezado, que es raro. **Dos
  salidas, y las dos son trabajo de otro sitio:** (a) que el mapa deje 24 px de
  hueco abajo y la barra de tareas se dibuje encima de él —lo correcto, y es
  geometría de `NodoPantallaMapa`, que hoy pone su propia barra de estado justo
  ahí—; o (b) que TILT y el mapa tengan su propio botón de "Recuperado". **La (a)
  es la buena**: una barra de tareas de verdad está siempre encima de todo.
- **Los iconos de `RECUPERADO` van a 16 px y se ven pequeños.** Es lo que hace un
  explorador de verdad, pero la cáscara viene de `bolas_64` y bajar de 64 a 16
  tira tres de cada cuatro píxeles. Si al mirarlo no se distinguen unas de otras,
  lo que falta es un juego de 16 —como `reliquias_32` se hizo para el
  escritorio—, no escalar distinto.
- **LA MESA ESTÁ EN OTRA PERSPECTIVA QUE EL RESTO DEL JUEGO, y hay que decidirlo
  antes de generar más arte de mesa.** El prompt que generó `assets/mesa/`
  —recuperado en `assets/GUIA_ESTILO.md`— pide *"seen from DIRECTLY ABOVE... no
  three-quarter angle, no sides visible"*, o sea cenital pura. Y `CONTEXTO.md`,
  "Perspectiva", dice de todo lo demás: *"los objetos están de pie hacia la
  cámara. No es cenital puro, y es a propósito: es lo que hace Peglin"*. Las dos
  posturas son defendibles —un bumper de una máquina real sí se ve desde
  arriba—, pero `PROPÓSITO.md` §8 pide arte de mesa nuevo (pines, segundo
  racimo, postes de outlane) y tiene que ir en la misma que el que se quede.
  **Decisión de Fátima.** Lo único que no vale es que la mesa tenga las dos.
- **Los dos carriles de retorno no miden lo mismo**: 34 px de boca el
  izquierdo, 27 el derecho, porque el carril lanzador come sitio a la
  derecha. Si se nota al jugar hay que replantear el lado derecho entero, no
  moverlo 3 px.
- **Un lanzamiento flojo (por debajo del ~78 %) no hace nada:** la bola no
  llega a salir del carril, cae otra vez dentro y se queda ahí hasta que
  vuelves a tirar. No se pierde nada, pero tampoco es una opción: el
  "lanzamiento flojo" no existe como jugada, solo como tiro fallido.
- **Con la órbita arreglada, todo lanzamiento a tope regala un tramo de
  multiplicador.** Engancha siempre por encima del 80 % de carga, y ahora
  además conservas la bola, así que cada bola empieza gratis en ×2. Antes
  quedaba tapado porque perdías la bola justo después. ¿Es el *skill shot* que
  quieres, o el tramo debería costar algo? Es decisión de Daniel.
- **Del mapa faltan tienda y evento** (`DISEÑO.md` §9). No están porque la
  tienda necesita chatarra y reliquias: Fase 4 y Fase 6. Meterlos ahora como
  nodos vacíos sería acumular sistemas a medias.
- **En el mapa, el nodo de jefe enseña el retrato del enemigo normal** del
  que sale, porque un jefe sigue siendo "el enemigo más duro del acto con más
  vida". Los tres sprites de `assets/jefes/` NO se usan a propósito: enseñar
  un golem y meterte contra una "Rata mayor" sería el mapa mintiendo. Se
  conectan cuando los jefes sean enemigos de verdad, en Fase 6.
- **Los jefes son de mentira.** Ahora un jefe es el enemigo más duro del acto
  con 1,8× de vida y "mayor" en el nombre. Eso NO cumple `DISEÑO.md` §8: un
  enemigo con más vida no es un enemigo nuevo. Los jefes de verdad, con sus
  fases y los sprites de `assets/jefes/`, son Fase 6.
- **La recompensa sale del combate, no del mapa.** El nodo del mapa sigue sin
  decir qué te va a dar, porque hasta que haya chatarra y tienda (Fases 4 y 6)
  todos los combates dan lo mismo: tres reliquias al azar. Cuando un nodo pueda
  dar cosas distintas, la línea de recompensa entra en la ficha del mapa, que ya
  tiene el hueco previsto.
- **El eje de escalado se paga por victorias, no por tiempo.** `bolsa.victorias`
  lo lleva `Run` y sube solo al ganar un combate: un descanso no cuenta, o
  descansar daría poder además de vida.
- **27 de las 45 reliquias no tienen icono**, y ninguna tiene sonido propio:
  quedarse una suena con el arpegio del combo, que es un préstamo. Los prompts
  para el arte que falta están en `assets/prompts_reliquias.md`.
- **Las misiones son 14 y se ven casi todas en un run.** Con tres por combate y
  doce combates ves 36 tiradas de un cajón de 14: se repiten. Ampliar es barato
  —una fila de JSON— pero hay que hacerlo.
- **Una misión puede quedar imposible en una mesa concreta.** Si pide tres
  platillos y el platillo es el tiro más difícil de la mesa, esa escalera se
  atasca ahí y el jugador se queda sin las dos siguientes. No hay tiempo límite
  ni forma de saltarla a propósito: si esto molesta, lo que falta es poder
  cambiar de misión con un tiro, no bajarles la exigencia.
- **La duración larga puede destapar que los enemigos son sacos.** Con combates
  de 25 s daba igual que un enemigo solo tuviera vida y un ataque; con tres
  minutos, no. `DISEÑO.md` §11 tiene los seis comportamientos que hacen falta
  (bloquear un recorrido, curarse, reflejar, blindaje, castigar el combo,
  acelerar el reloj) y son Fase 6. Si Daniel dice que se hace largo, el orden
  del plan cambia: la Fase 6 sube antes que la cáscara.
- **La tele se come sitio en el hueco entre palas.** No es física, pero sí es
  arte: 184×124 px justo encima de los flippers, por donde pasa la bola
  constantemente. Si estorba visualmente, se encoge o se sube, pero tiene que
  seguir dentro del encuadre con la cámara anclada abajo.
- **La bola no tiene giro.** No hay spin simulado, así que no hay efecto ni
  bola que "muerda" en un ángulo. La rodadura es la aproximación barata a eso
  y aguanta bien; si en algún momento se quiere una física que destaque de
  verdad, el siguiente paso es momento angular en la bola, y es un cambio
  gordo que toca el solver entero.
- **Al jugador bueno no le pasa nada en los actos I y II.** Seis de nueve
  enemigos le hacen cero. El reloj fino le quitó el escondite, pero al aflojar
  la dificultad los combates se acortaron a 7-14 s y la mayoría vuelven a caer
  por debajo de los 9 s de carga: **el problema del escalón reaparece a cada
  escala nueva**, porque aflojar acorta los combates y acortarlos vuelve a
  esconder al bueno. Si se quiere que note algo pronto, el camino es enemigos
  con MÁS vida y MENOS ataque (fila `1.20 / 0.85` del barrido), no seguir
  bajando números.
- **Los perfiles del medidor son una aproximación.** Un perfil describe lo que
  produce una bola, no juega con las palas: no hay física dentro. Sirve para la
  economía del combate, que es lo que se estaba midiendo, pero no dice nada de
  si un tiro es cazable ni de cómo se siente nada.
- **Los paneles de la derecha siguen encendidos durante la ruleta.** La mesa se
  apaga y la tele manda, pero el enemigo y las barras siguen a plena luz en su
  banda, que es otra capa. Es a propósito —así se ve contra quién estás—, pero
  si distrae en la ruleta, atenuarlos es un `modulate` y hay que probarlo
  antes: el enemigo lleva shader y el `modulate` puede no aplicarle.
- **La bandeja del reloj de la barra de tareas sigue dibujada con `draw_rect`**
  a mano, porque su arte es lo único de `prompts_cascara.md` §2 que no se ha
  generado. Es la tanda 3 de "Siguiente".
- **El juego se llama Cascabel** (`DISEÑO.md` rev. 4). Las rutas y el nombre del
  repo siguen siendo `tilt-os` a propósito. La cáscara del sistema operativo es
  el marco visual, en pixelart con marcos de nueve trozos y sin gestor de
  ventanas.
