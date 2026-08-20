# PROPÓSITO.md — CASCABEL

Lo que le falta al juego para que alguien quiera volver a abrirlo. Sale de las
pruebas con gente: **la bola se siente bien y no hay razón para jugar.**

Este documento no sustituye a `DISEÑO.md`, lo continúa. Donde contradiga a
`CLAUDE.md`, manda `CLAUDE.md`.

---

## 1. El diagnóstico, y no es el que parece

Hay tres relojes escritos en `DISEÑO.md` §6 y los tres funcionan:

| Escala | Qué decides | Estado |
|---|---|---|
| La bola, ~15 s | Qué tiro intentas ahora | **hecho** |
| El combate, 1-2 min | La escalera de misiones | **hecho** |
| El run, 30-40 min | Qué build montas y qué rama coges | **hecho** |

**Falta el cuarto, y es el único que sobrevive a perder.** Hoy, cuando el run
se acaba, no queda absolutamente nada: ni un objeto, ni un número que suba, ni
una línea distinta en la pantalla siguiente. Volver a empezar es literalmente
volver a empezar.

Eso explica las dos cosas que se vieron probando, que parecían separadas:

- **"No hay propósito"** — no es que falte una historia. Es que no hay ninguna
  frase que empiece por "la próxima vez".
- **"La tensión de la bola no se siente"** — está medido y la causa está
  escrita en `ESTADO.md`: de 20 combinaciones de vida × ataque, **ninguna** deja
  el run entre el 25 y el 60 % de vida. O el enemigo no te toca o te mata. Pero
  hay una segunda causa que el barrido no puede ver: **la tensión también
  necesita que perder cueste algo**, y hoy perder no cuesta nada porque no
  había nada.

Las dos se arreglan con la misma pieza.

---

## 2. El propósito: reconstruir el sistema

**La premisa ya es la meta-progresión y nadie la había usado como tal.**

`DISEÑO.md` §3 lo tiene escrito palabra por palabra: alguien intentó convertir
una máquina de pinball en un juego de rol, lo dejó a medias y se fue. Drenar no
es morir, es que **el sistema captura el fallo y reinicia el nivel**. Y los
desbloqueos son *«piezas rescatadas de la memoria antes de que el reinicio las
borre»*.

Eso no hay que inventarlo. Hay que enseñarlo.

> **El propósito del juego es terminar de reconstruir el juego que nunca se
> terminó.** Cada run recupera fragmentos del disco. El escritorio se llena.
> Ficheros que estaban corruptos se vuelven legibles. Programas que no
> arrancaban arrancan.

Es la respuesta correcta a "necesitamos un propósito" por cuatro razones, y
ninguna es temática:

1. **Se ve sin jugar.** Abres el juego y el escritorio ya te dice cuánto llevas.
   Un menú principal con un botón de "Jugar" no dice nada.
2. **Sobrevive a perder**, que es lo único que hace volver a un roguelike.
3. **Cuesta cero ficción.** Sin cinemáticas, sin diálogo, sin guion: es lo que
   `DISEÑO.md` §3 ya exigía.
4. **Vive en la cáscara**, que es la parte del juego que hoy solo decora.

### La carpeta

En el escritorio hay una carpeta, `RECUPERADO`. Dentro está todo lo que el
juego puede llegar a ser, y **lo que no tienes también está**: como un fichero
de 0 bytes con el nombre ilegible.

```
RECUPERADO/
  casc_acero.dat      12 KB    ✓
  casc_hueso.dat       9 KB    ✓
  ????????.dat         0 KB
  ????????.dat         0 KB
  pala_corta.sys       4 KB    ✓
  ????????.sys         0 KB
```

**Ver el hueco es el gancho.** Una lista de logros bloqueados dice "te falta
esto"; una carpeta con siete ficheros corruptos dice "aquí había algo". Es la
misma información y no se lee igual.

---

## 3. Lo que ya está dibujado y no se usa

Antes de diseñar nada conviene mirar el inventario, porque cambia el coste de
media propuesta. Esto está generado, procesado y en el repo **sin que ningún
código lo cargue**:

| Carpeta | Qué hay | Para qué sirve ahora |
|---|---|---|
| `assets/bolas/` + `bolas_64/` | **9 cáscaras** de cascabel | las 9 bolas de la capa de Preparación |
| `assets/criaturas_64/` | **9 criaturas** | la criatura de dentro (`DISEÑO.md` §4) |
| `assets/mesa_props/` | 7 objetos de suelo | que la mesa deje de verse pelada |
| `assets/mesa_placas/` | 6 placas | ídem |
| `assets/mesa_anim/` | antorcha y girador por fotogramas | animación de mesa |
| `assets/mesa_tunel/` | tapas y bocas de túnel | las rampas, que hoy no tienen boca dibujada |
| `assets/mesa/` | 9 de 13 PNG sin usar | bumpers y targets alternativos |

**Nueve cáscaras por nueve criaturas son 81 cascabeles distintos**, y eso
resuelve de golpe la pregunta de qué se colecciona.

**Pero el arte NO está hecho, y las 81 son de interfaz.** *Corregido ago-2026,
después de mirar los PNG en vez de fiarse del inventario:*

1. **Las nueve `criaturas_64/` no están dibujadas solas**: llevan un arco de
   piedra pintado, con interior oscuro y zarpas al borde. El inventario las
   apuntó como "criaturas peek 3×3" y se leyó "peek" como "sola". **Hay que
   regenerarlas sin arco**, y está escrito en `assets/prompts_animacion.md` §4.
2. **Y la combinatoria no es de mesa, es de interfaz.** La bola mide 18 px
   jugando y la ranura de las cáscaras baja a 1,7 px de alto: en la mesa se ve la
   cáscara y nada más. Las 81 se componen a 64 px en Preparación, en
   `RECUPERADO/` y en los tooltips, donde hay sitio de sobra. El detalle está en
   `DISEÑO.md` §4.

**Las cáscaras sí están hechas y no se tocan** (decisión de Fátima, 17-ago): a
18 px identifican de sobra por color y patrón.

---

## 4. La capa de Preparación

`DISEÑO.md` §5 la tiene diseñada entera y con cero implementado. **Elegir antes
del run no es desbloquear entre runs**, así que esto no toca §13: entra ahora,
con todo abierto desde el principio.

### La regla que las hace no ser mejoras planas

> **Un cascabel cambia QUÉ TIRO te compensa, no cuánto pegas.**

Es `DISEÑO.md` §1 aplicado. Si un cascabel es "+15 % de daño", sobra. Si te hace
querer ir al platillo en vez de al cañón, está bien.

**Y una segunda regla, que salió de medir los nueve y no estaba prevista:
lo que suba el daño tiene que pagarse EN RELOJ.** Está medido que Vidrio pega un
46 % más que Acero y acaba el run con MÁS vida —80 % contra 71 %—, aunque drenar
le cueste dos veces y media: el coste de un combate es `tiempo/reloj × ataque +
bolas × drenaje`, así que más daño acorta el combate y comerse menos relojes vale
más que cualquier castigo por drenar. De los nueve, el único que empuja el run a
la banda que se busca es Runas, y es el único que toca el reloj.

| Cascabel | Qué hace | Qué tiro empuja |
|---|---|---|
| **Acero** | Neutro. El de partida y la vara de medir | ninguno |
| **Piedra** | Pesa: cae más rápido y pega concentrado, pero le cuesta subir las rampas | targets y cañón, nunca rampa |
| **Vidrio** | Pega el doble. Al segundo drenaje del combate se rompe y pierdes el turno | todos, con miedo |
| **Hueso** | Cada drenaje le quita una capa, y cuanto más rota, más pega | recompensa jugar herido |
| **Óxido** | Lo que golpea queda oxidado y vale doble el siguiente golpe | repetir tiro, no variar |
| **Runas** | El multiplicador NO se pierde al drenar, pero el reloj corre un 30 % más rápido | combo largo, carrera |
| **Bronce** | Bumpers y girador cargan la barra de rampa (§6) | el racimo pasa a ser preparación |
| **Plata** | Rebota más: conserva velocidad, va más rápido y se controla peor | caos |
| **Hierro** | Inmune a lo que hagan los enemigos de la Fase 6 | seguro, aburrido, útil |

**La criatura de dentro es solo skin.** Ese es su trabajo: coleccionar sin
afectar al balance, que es lo que dice `DISEÑO.md` §5.

### Los flippers

Son «la única parte real» de la máquina (`DISEÑO.md` §3), así que cambiarlos
tiene que notarse en las manos. Y ojo, que esto **es un dial de dificultad**:
`flipper_longitud` decide el hueco central, hoy de 47 px.

| Palas | Largo · giro | Qué cambia |
|---|---|---|
| **De fábrica** | 64 · 30 | las de ahora |
| **Cortas** | 56 · 36 | hueco central más grande (más drenajes), pero llegas antes |
| **Largas** | 72 · 24 | hueco más pequeño, y la bola sale más lenta: menos alcance |
| **Desiguales** | 72 izq · 56 der | la mesa deja de ser simétrica y hay que aprenderla otra vez |

**Aviso de balance.** `tests/medir_daniel.gd` está calibrado contra las palas de
64. En cuanto haya flippers distintos, el medidor mide un jugador por juego de
palas o deja de reproducir a Daniel. Es la misma avería de "calibrar contra un
jugador inventado" que ya salió mal dos de dos.

---

## 5. El selector de dificultad: integridad del sistema

Un selector de dificultad no es un menú de números, y aquí además **arregla un
problema medido**: el barrido dice que no existe ninguna tabla que deje el run
en la banda de dificultad que buscamos. Cuando el diseñador no puede acertar la
banda, **la salida es dejar que el jugador elija la suya.**

Cinco niveles, y no se llaman fácil y difícil: son estados del sistema.

| Nivel | Se lee como | Qué toca |
|---|---|---|
| **MODO SEGURO** | 16 colores, sin fondo de escritorio | outlanes anchos, reloj lento |
| **NORMAL** | el de ahora | lo de ahora |
| **SIN VERIFICAR** | avisos que no se cierran | outlanes estrechos |
| **CORRUPTO** | fondos bugueados desde el acto I | + los enemigos traen comportamiento (Fase 6) |
| **KERNEL PANIC** | la cáscara falla de verdad | + un drenaje cuesta el doble |

Tres decisiones dentro de esto:

- **Cada nivel mueve DOS diales, no veinte.** `ancho_outlane` y el `reloj` de
  cada enemigo. `ESTADO.md` ya dice el orden: outlanes primero, palas después.
- **A partir del tercero se añaden REGLAS, no números.** Subir la dificultad
  metiendo más vida es lo que el barrido demostró que no funciona.
- **La dificultad se ve en la cáscara.** MODO SEGURO dibuja el escritorio en 16
  colores y sin fondo, como el modo seguro de verdad. Cuesta cero arte —es
  cuantizar lo que ya hay— y es la mejor broma disponible.

**Y es el regulador de la economía meta.** Recuperar ficheros solo cuenta de
NORMAL para arriba, y cuanto más alto, más recuperas. Así el selector no rompe
la escasez: farmear en MODO SEGURO no da nada.

---

## 6. Las rampas nunca aseguradas, y la carga

Esta es la mejor idea de la tanda y es la que más cambia el tacto.

Hoy una rampa es determinista: entras y sales. `PLAN.md` lo hizo así a propósito
—«construirlas con paredes y simularlas es el error que hunde los pinballs 2D»—
y **eso no se toca**: siguen siendo curvas. Lo que cambia es que la curva tenga
cuesta.

### Velocidad de escape

Cada rampa tiene una `velocidad_escape`. La bola recorre el spline frenando, y:

| Entras a | Qué pasa | Cómo suena |
|---|---|---|
| **< 60 %** | sube poco, se para y **vuelve por donde entró**, cayéndote a la pala | motor que se apaga |
| **60-100 %** | corona justo, sale despacio por arriba y **va donde va** | tensión, sin premio limpio |
| **> 100 %** | limpia: sale por donde tiene que salir, a la velocidad de siempre | el sonido de rampa de ahora |

Es exactamente el Pokémon Pinball: a veces no llegas, y no llegar **no es un
castigo, es información**. Y sigue siendo determinista y sin atascos, que era la
razón de que las rampas fueran splines.

### CONSTRUIDO (tanda 0k, 20-ago) — y lo que se cobra es ALTURA

Las cinco rampas que suben tienen cuesta. Las cuatro que no la tienen es porque
**no suben**: los dos túneles entran y salen a la misma altura y el regreso solo
baja, así que su cuesta se apaga sola por geometría y no por una excepción. El
umbral sube 513 px y se queda a cero por decisión de Daniel: va a ser una puerta,
y una puerta no se falla, se abre.

Lo que hizo falta cambiar del modelo de arriba fue el denominador. Cobrar por
`recorrido/largo` solo es correcto en una rampa que sube y ya está; en una órbita,
que sube 660 px y vuelve a bajar, deja la bola más lenta ABAJO que en lo alto.
Cobrando la ALTURA ganada sobre la propia curva, la bola frena subiendo y
**recupera bajando**, que es lo que la mesa ya le hace a la bola libre — y por eso
las dos se sienten igual en la mano.

| rampa | sube | escape | frontera | falla | se cae al |
|---|---|---|---|---|---|
| órbita | 660 | 950 | 570 | 23 % | 86 % |
| cañón | 478 | 1000 | 600 | 25 % | 91 % |
| retorno | 476 | 1000 | 600 | — | — |
| subida a la isla | 180 | 800 | 480 | 45 % | 77 % |
| órbita alta | 242 | 700 | 420 | 32 % | 80 % |

**La columna que manda no es "falla", es "se cae al":** quedarse a medias tiene
que ser subir casi entera y soltarse desde arriba. Un escape más alto sube el
porcentaje y BAJA ese número, y entonces el fallo se lee como un rebote en la
boca y no como no llegar.

### Y con capas de altura, fallar es CAERSE

*Añadido ago-2026, cuando Daniel pidió capas de altura y plataformas.*

Tal y como está escrito arriba, una rampa fallada devuelve la bola por donde
entró: la curva la baja sola. Eso está bien y se puede construir hoy mismo.

Pero con el sistema de capas de `PLAN.md` §1c, una rampa fallada puede hacer algo
mejor: **la bola se cae de la rampa al tablero de abajo**. No vuelve por donde
vino, se desprende. Es lo que se siente de verdad en una máquina y es gratis en
cuanto exista la capa, porque caer de una rampa y caer de una plataforma son el
mismo evento.

Las dos formas conviven: una rampa cerrada (un tubo) te devuelve; una abierta
(un carril) te tira. Es una propiedad por rampa, no una decisión global.

### La barra de CARGA

Y aquí está lo que pedías: algo que se cargue en función de la velocidad a la
que le pegas.

> **Toda entrada de rampa carga la barra, llegues o no**, en proporción a
> `(velocidad_entrada / velocidad_escape)²`. Una rampa fallada carga poco. Una
> justa carga. Una limpia carga el triple.

La barra es, literalmente, **una barra de progreso de Windows** en el marco de
la rampa. Cuando se llena:

> La siguiente rampa que hagas es una **DESCARGA**: la bola sale al doble de
> velocidad y durante cuatro segundos **todo lo que toca cuenta el doble**.

Por qué esto funciona y no es un número más:

- **Un tiro fallado sigue pagando**, así que sigues tirando a la rampa aunque no
  te salga. Es la válvula que hace que la mesa enganche.
- **Premia pegar fuerte**, que es lo que el flipper ya sabe hacer bien y hoy no
  se recompensa por ningún sitio.
- **Cumple `DISEÑO.md` §1**: cambia a qué tiro vas, porque durante la descarga
  te interesa el racimo y no el cañón.
- **La regla de los bucles se respeta**: la descarga se apaga sola en cuatro
  segundos, así que no se sostiene sin las palas.

**El riesgo, y hay que medirlo antes de escribirlo:** duplicar el daño cuatro
segundos puede cargarse la tabla de vida de enemigos entera. Se pasa por
`tests/medir_daniel.gd` antes de tocar la mesa, no después.

---

## 7. Tapar los agujeros de muerte segura

Lo del Pikachu y el Pichu. Es una mecánica de salvamento y tiene una forma
correcta y una forma que rompe el juego:

- **Rompe el juego** si es pasiva. Una reliquia que "a veces te salva" convierte
  el drenaje en aleatorio y `DISEÑO.md` §2 se cae: aguantar la bola deja de ser
  lo mejor que puede hacer el jugador.
- **Funciona** si la cargas tú, se ve cargándose, y se gasta.

Tres, en orden de coste:

**1. Recuperación de sector** *(los outlanes)*. Los outlanes son sectores
defectuosos del disco. El carril de retorno —un tiro de dificultad media que hoy
paga poco— carga una barra; al llenarse **sube un poste físico en un outlane
durante ocho segundos**, con su cuenta atrás a la vista. Elegir qué lado tapas
es la decisión.

**2. Kickback** *(clásico de pinball, y es el que más se parece al Pikachu)*.
Una carga por bola. La bola que se va por el outlane izquierdo **sale disparada
de vuelta**. La recarga la órbita, que es el tiro difícil de la mesa.

**3. El hueco central**, que es el que de verdad mata. Una vez por combate, y se
gana **completando la misión rara**: durante una bola, el hueco entre palas se
tapa. Esto sí que hay que medirlo con cuidado, porque el hueco central es la
dificultad entera de un pinball.

**Ninguna de las tres cura vida.** Todas te devuelven **la bola**, o sea tiempo
pegando, que es como §2 quiere que se pague la habilidad.

---

## 8. Que la bola pegue en más sitios

`ESTADO.md` ya lo tiene anotado en Abierto: *«explica por qué la mesa se ve más
pelada que la carpeta de assets»*. Ordenado por dopamina por hora de trabajo:

| Qué | Coste | Por qué |
|---|---|---|
| **Un campo de pines** en la zona alta | bajo — son colisionadores circulares | Lo de Peglin y el pachinko. La bola traquetea y suena veinte veces seguidas. **Es lo más barato y lo que más dopamina da de toda la lista** |
| **Segundo racimo de bumpers** en la banda opuesta | bajo | la física ya existe |
| **Standup targets sueltos** repartidos | bajo | golpes pequeños constantes |
| **Rollovers** (carriles que se encienden) arriba | medio | dan objetivo sin dar daño |
| **Conectar `mesa_props` y `mesa_placas`** | bajo | el arte ya está |
| **Antorchas animadas** (`mesa_anim`) | medio | la mesa deja de estar quieta |

### Y la que cambia más por menos: la cáscara reacciona a la mesa

Hoy el escritorio está muerto mientras juegas. Y dibuja cada fotograma de todas
formas.

- Un tramo de multiplicador nuevo → **los iconos del escritorio dan un salto**
- Un cañón → **se abre y se cierra un cuadro de diálogo de error** en un lado
- Una descarga de rampa → **la barra de tareas parpadea**
- Un drenaje → el sistema escribe una línea nueva en `registro.log`
- Matar a un enemigo → **su proceso desaparece de la barra de tareas**

Cuesta casi nada porque la cáscara ya se redibuja, hace que el sistema
operativo se sienta vivo, y sobre todo **ata la mesa a la cáscara**: hoy son dos
programas que comparten pantalla.

---

## 9. La cáscara viva

El invariante prohíbe **gestor de ventanas** —arrastrar, redimensionar, foco,
apilado, minimizar—, y eso sigue en pie. No prohíbe que las cosas se pulsen.

### Lo que hay que escribir primero, y hoy no existe

1. **Guardado.** No hay ninguno. Logros, desbloqueos y easter eggs son todos
   estado que sobrevive al cierre, así que **lo primero no es el menú, es el
   fichero**: un `user://cascabel.cfg` con versión, escrito al acabar el run.
2. **Clics.** Hoy el ratón solo mueve el puntero. Hace falta enrutado de clic,
   regiones pulsables y estados de encima/pulsado. `NodoCascara` ya calcula los
   rectángulos de los iconos para los tooltips: **medio subsistema está escrito**.

### El escritorio

| Elemento | Qué hace de verdad |
|---|---|
| **Botón Inicio** | menú real: Jugar · Recuperado · Ajustes · Apagar |
| **`RECUPERADO/`** | la carpeta de §2. Cascabeles, palas y mesas como ficheros |
| **`chkdsk`** | **la pantalla de logros, que no se llama logros**: sectores del disco recuperados, con su barra y su lista |
| **`registro.log`** | abrible, y se va escribiendo con tus runs en voz de sistema. Es donde vive la historia sin escribir historia |
| **`papelera`** | los enemigos que has matado. Vaciarla hace algo |
| **`ayuda.hlp`** | el manual del juego que nunca se terminó, con secciones que faltan |
| **`mi_maquina`** | las estadísticas: bolas jugadas, mejor run, daño por bola |

Los iconos ya están dibujados: `carpeta`, `cascabel`, `disco`, `disquete`,
`error`, `mi_maquina`, `monitor`, `papelera`, `registro`. **Los nueve.**

### Easter eggs

La regla: un easter egg es **un fichero que el sistema no debería tener**.

- Un `.txt` con el nombre de quien programó esto, y una fecha
- Un ejecutable que no arranca y da siempre el mismo error, hasta que un día no
- Un fondo de escritorio que solo aparece si apagas el sistema en vez de cerrar
- Una carpeta que reaparece después de vaciar la papelera tres veces
- El reloj de la barra de tareas, a determinada hora

**Ninguno da poder.** En cuanto un easter egg da ventaja deja de ser un secreto
y pasa a ser una guía que hay que leer.

---

## 10. Lo que NO se hace

Para que no se cuele por la puerta de atrás.

- **Nada de árbol de mejoras permanente.** Nada de "+2 % de daño para siempre".
  Es lo que §13 teme: esconder que el run no divierte detrás de una barra.
- **Los desbloqueos NO dan poder.** Dan **variedad**: otro cascabel no es mejor,
  es otro. Así §13 sigue en pie con todo abierto desde el primer día.
- **Nada de gestor de ventanas.**
- **Nada de mesas procedurales.**
- **La criatura sigue sin hablar.**
- **Nada de monedas premium, misiones diarias ni racha.**

---

## 11. Orden de tandas

Una por sesión, con su modelo. **La Fase 6 baja de puesto por decisión de
Fátima**, no porque la medida haya cambiado: el barrido sigue diciendo que sin
comportamientos de enemigo no hay tabla que valga.

| # | Tanda | Modelo / razonamiento | Por qué ahí |
|---|---|---|---|
| ~~0~~ | ~~Cámara~~ | ~~Opus, alto~~ | **HECHA** |
| ~~1~~ | ~~Guardado + clics + menú de Inicio + `RECUPERADO/`~~ | ~~Opus, alto~~ | **HECHA Y EJECUTADA.** Batería 358/358. Lo que se recupera son criaturas (skin) y registros (texto), así que §13 sigue en pie. Detalle en `ESTADO.md` |
| ~~2~~ | ~~Capa de Preparación: 9 cascabeles + 4 palas~~ | ~~Opus, alto~~ | **HECHA Y MEDIDA.** 381/381. Un cascabel es una bolsa de modificadores, sin un solo `if` nuevo en `Combate`. La medida destapó que pegar más hace el juego más fácil: ver `ESTADO.md` |
| 3 | **La cáscara reacciona a la mesa** | Sonnet, medio | Forma conocida, coste bajo, y es lo que más sube la sensación por hora |
| ~~4~~ | ~~**Dopamina de mesa**: pines, segundo racimo~~ | — | **HECHA Y DESHECHA.** El racimo girado se queda (era un error de medida de años). **Los pines salen del juego entero**: Daniel los tumbó jugándolos — *"el pachinko es literalmente que caiga la bola, y que luego no pase de la primera línea"*. Una rejilla es un comedor de energía pasivo |
| 4b | **Capas de altura** (`PLAN.md` §1c) | Opus, alto | El sistema: nivel en la bola, colisionadores por capa, caída entre capas, velocidad de escape. **Primero esto y luego la geometría**, decisión de Daniel: es lo único que no se puede hacer al revés |
| 4c | **La planta alta, rediseñada** (`PLAN.md` §1d) | Opus, alto + Daniel | Hoy es una réplica de la de abajo y por eso no vale. "Diferente diseño, bumpers, zonas, plataformas, túneles". Y ocupar los 1.470 px de carril muerto de los márgenes |
| 5 | **Rampas fallables + barra de CARGA** | Opus, alto | `sim/` puro, y la descarga puede cargarse la tabla de balance. Medir antes de escribir |
| 6 | **Selector de dificultad** | Opus, alto | Necesita la Fase 6 dentro para que los niveles altos añadan reglas |
| 7 | **Tapar agujeros**: kickback y recuperación de sector | Opus, alto | Cambia el drenaje, que es el corazón del balance |
| 8 | **Fase 6: comportamientos de enemigo** + rebalance | Opus, alto | Sigue siendo lo que arregla la banda de dificultad |
| 9 | **Desbloqueo de verdad** (reabrir §13) | Opus + Fátima | Solo cuando 2 y 5 se hayan jugado y se sepa qué merece la pena |

**El criterio de salida de todo esto, y no se lee, se juega:** alguien pierde un
run, ve que ha recuperado dos ficheros, y abre otro sin que se lo pidas.

---

## 12. Preguntas abiertas

- **¿Cuántos ficheros por run?** Es el dial entre "esto avanza" y "esto es una
  máquina tragaperras". Empezar bajo: 1-2 por run acabado, 0-1 por run perdido.
  Un run perdido tiene que dar **algo**, o perder sigue sin costar nada.
- **¿La criatura se elige o sale con la cáscara?** 81 combinaciones son muchas
  para un menú. Puede que la criatura salga al azar y eso sea parte de la gracia.
- **¿La barra de CARGA es por bola o por combate?** Por bola es más tenso y
  drenar duele más; por combate premia el combate largo, que es lo que ahora
  mismo se hace pesado.
- **¿La descarga de rampa dobla el daño o dobla el multiplicador?** No es lo
  mismo para el balance ni para los ejes de build.
- **¿KERNEL PANIC desbloquea algo o es solo orgullo?** Si desbloquea, hay que
  vigilar que no sea la única forma de ver contenido.
