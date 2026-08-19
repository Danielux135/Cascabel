# CAZA.md — CASCABEL

La planta alta rehecha (`PLAN.md` §1d) y **el sistema de captura**, que hasta
hoy no existía escrito en ningún sitio.

Documento de diseño, no de estado. Se escribe entero antes de tocar geometría
porque la planta alta ya ha salido mal dos veces y las dos por construir antes
de decidir.

> **⚠ CORREGIDO EL 18-AGO, JUGÁNDOLO.** La geometría de §3 se construyó y Daniel
> la probó (puerta B de §5). Veredicto: *"es extremadamente fácil drenar e irte
> de la zona de caza"*, *"no he sido capaz de aguantar los 20 segundos ni de
> lejos"*, *"flippers extremadamente cortos"*, y sobre todo **la frase que cambia
> el diseño**: *"esta fase debería sentirse como un bonus, algo especial, no algo
> tan fácil de perder"* — *"ni siquiera me gusta la idea de que te puedas salir
> de esa zona tan fácil"*.
>
> Lo que se cae de esta nota: **el castigo**. Lo que entra: **un salvabolas**.
> Está marcado sección por sección abajo; §3.1, §5 y §6 son las que cambian.

---

## 0. La pregunta que desbloqueaba todo, y la respuesta es que no

> *«Deduzco que hacer muchos sprites para los diferentes ángulos de cada
> criatura como en Pokémon Pinball es muy complejo, ¿o no lo es?»* — Fátima

**No lo es. Pero cuesta más que cero, y la primera versión de esta nota decía
que cero.** Corregido el 17-ago tras repasar los prompts de verdad.

Pokémon Pinball no es caro por los ángulos. Cada bicho tiene **una sola vista
fija**, a la perspectiva de la mesa, con dos o tres fotogramas. No rota nunca.
Lo que hace caro a Pokémon Pinball son **151 criaturas**, no los ángulos.

Aquí son **nueve**, y están en `assets/criaturas_64/` desde el 13 de agosto:
`cr_brasa`, `cr_calavera`, `cr_diablillo`, `cr_espectro`, `cr_gusano`,
`cr_musgo`, `cr_rata`, `cr_sapo`, `cr_sombra`. Procesadas, cuantizadas y
**sin que ningún código las cargue** (`PROPÓSITO.md` §3).

El eje correcto no es el ángulo, es el **estado**:

| Eje | Coste | Sirve para |
|---|---|---|
| Ángulos (6-8 vistas por bicho) | 9 × 8 = 72 dibujos nuevos | nada: la criatura no rota, mira al jugador (`CONTEXTO.md`, "Perspectiva") |
| Estados (4 por bicho) | **9 hojas de 4×4** | todo lo que la caza necesita |

### ⚠ Lo que decía aquí y estaba mal

Ponía: *"`prompts_animacion.md` pide hoja 4×4 por bicho —idle, golpe, ataque,
muerte, celda 64—, así que cero fotogramas nuevos"*. **Eso es la hoja del
ENEMIGO** (§1 de ese fichero, celda 96). La de las criaturas es §4 y es otra
cosa: **8 fotogramas en UNA fila, celda 64, y un solo estado, `idle`**. Con
razón: la criatura pasajera va dentro de una bola que rebota, y el aplastado y
el giro los hace el código.

O sea que **la criatura tiene dos papeles y necesita dos hojas**:

| Papel | Hoja | ¿Existe el prompt? |
|---|---|---|
| **Pasajera**, dentro de tu cascabel | 8×1, celda 64, solo `idle` | **sí, §4, lista para generar hoy** |
| **Presa**, suelta en la planta alta | 4×4, celda 64: acecho, susto, huida, rendida | **escrito ahora, §5** |

Son **9 hojas más** de las que ya había. Sigue sin ser caro —el espejado
horizontal da izquierda/derecha gratis y la plantilla del enemigo vale casi tal
cual— pero no es gratis, y **van detrás de la puerta B**: si la planta alta no
se siente distinta jugándola sin bichos, esas nueve hojas no se generan nunca.

### Y la trampa que salió del repaso, que era más gorda

**Las nueve `cr_*.png` NO están dibujadas solas: llevan un arco de piedra
encima.** El inventario las documenta como *"criaturas peek 3×3"* y alguien leyó
"peek" como "dibujada sola, asomándose"; quiere decir asomándose **por algo**, y
ese algo está pintado. Medido: 337 px (13,6 %) son idénticos en las nueve y
dibujan el anillo, y **borrarlos no cambia la caja**, o sea que el arco no se
puede quitar con una máscara.

Eso tumba de paso la combinatoria de 81 (`PROPÓSITO.md` §3) y el "la cáscara
rueda, la criatura no" (`DISEÑO.md` §4), y **envenena el prompt de §4**, que
adjunta una de esas PNG como referencia exacta mientras ordena *"no bell, no
circular outline of any kind"*. Está todo escrito y arreglado en el ⚠ de
`assets/prompts_animacion.md` §4, con la decisión que le toca a Fátima.

Lo que falta, además del arte, es el reproductor de hojas de la tanda 7 de
`ESTADO.md` — y esa tanda ya estaba pedida por Daniel y por Fátima.

**Y hay un ahorro más que no es del presupuesto sino del estilo.** Con la
temática oscura, una criatura que es casi silueta con los ojos encendidos
necesita menos arte *y se lee mejor a 64 px*. `cr_sombra` (1.777 bytes, la más
ligera de las nueve) es la prueba de que eso ya está pasando solo.

---

## 1. Qué se captura, y por qué eso cierra el propósito

`PROPÓSITO.md` §2 dice que el juego va de reconstruir lo que otro dejó a medias,
y que los desbloqueos son *«piezas rescatadas de la memoria antes de que el
reinicio las borre»*. `DISEÑO.md` §5 dice que la zona alta suelta **material de
desbloqueo, no poder de run**.

Las dos frases piden lo mismo y nadie las había juntado:

> **Lo que se captura arriba son las criaturas del cascabel.** Cada una que
> traes viva es un `.dat` que deja de estar corrupto en `RECUPERADO/`, y a
> partir de ahí se puede meter dentro de tu cascabel en la capa de Preparación.

Con eso, la caza deja de ser un modo suelto:

- **Nueve cáscaras × nueve criaturas = 81 cascabeles** (`PROPÓSITO.md` §3), y el
  código que los dibuja ya es el mismo para los 81: la cáscara rueda, la
  criatura no (`DISEÑO.md` §4).
- **No rompe la escasez**: lo cazado no te hace ganar este run.
- **El hueco se ve.** Siete `????????.dat` de 0 KB en el escritorio dicen "aquí
  había algo" mejor que cualquier lista de logros.
- **Y la ficción no cuesta nada.** La criatura no habla nunca; el fichero sí.

---

## 1b. LA CAZA ES UN BONUS, Y UN BONUS NO SE PIERDE *(nuevo, 18-ago)*

Lo decidió Daniel jugando la geometría, y reordena media nota:

> **Drenar en la planta alta ya no te echa.** La mesa vuelve a servir la bola por
> donde entró y la caza sigue. Lo único que la acaba es el tiempo.

Por qué es coherente y no es un regalo:

- **El precio ya existía y no se ha tocado**: el reloj del enemigo corre mientras
  estás arriba (`DISEÑO.md` §5). Subir cuesta tiempo de combate, y eso es lo que
  impide que cazar sea gratis. Lo que se quita es un SEGUNDO castigo —perder el
  bonus— que estaba encima del primero.
- **Un bonus que se pierde en cuatro segundos no es un bonus, es un peaje.** Y
  medido: con las palas cortas, el que aporrea duraba arriba 7,6 s de los 20, o
  sea que se perdía dos tercios del modo por el que ha tenido que pagar un tiro
  difícil de 3 entre 100.
- **Lo que se juega arriba pasa a ser cuánto aprovechas**, no cuánto aguantas.
  Aguantar la bola ya es la habilidad de la planta de abajo; repetirla arriba con
  palas peores era pedir lo mismo y más difícil.

Vive en `caza_salvabolas`, y `caza_coste_salvada` (a 0) deja la variante
"salvabolas con coste en segundos" a un número de distancia, sin tocar código.

**Lo que esto NO cambia:** la captura sigue acabando la caza (§2, fase 3) y el
regreso sigue pudiendo costarte lo capturado (§2, fase 4). Perder la bola arriba
y perder la CRIATURA al bajar son dos cosas distintas, y la que da la tensión es
la segunda.

## 2. La captura: acorralar, no restar vida

La forma que **no** se hace: pegarle N veces a una barra. Es un contador, y un
contador no se nota jugando — es la misma objeción de Fátima a los
modificadores porcentuales.

Tres fases, y cada una usa una pieza de geometría distinta.

### Fase 1 — Rastro *(no se ve nada)*

La criatura no está dibujada todavía. Hay señales: el cascabeleo, una sombra
cruzando **por debajo del tablero** en un túnel, un búmper que se enciende al
pasar ella cerca. Hay que golpear para obligarla a salir.

Coste de arte: **cero**. Sombra, partículas y sonido. Es la fase que vende lo
oscuro y lo misterioso, y es la más barata de las tres.

### Fase 2 — Acoso *(el miedo, no la vida)*

Sale, y **se mueve por la geometría de arriba**: se sube a la plataforma, se
mete en los túneles, se planta entre los búmperes.

> Los golpes no le quitan vida. Le suben el **MIEDO**.

| Lo que haces | Miedo |
|---|---|
| Golpearla de lleno | sube mucho — pero el rebote te deja mal |
| Búmper cerca de ella | sube poco, y es tiro seguro |
| Coronar la rampa mientras está arriba | le corta la ruta: sube y además la mueve |
| **Ella se mete en un túnel** | **baja mientras no la ves** |

El túnel es la pieza clave y ya está construida (`Rampa.subterranea`, tanda 0h):
mientras la criatura está debajo del tablero **la pierdes de vista y el miedo
drena**. Así el modo no se juega a acertar, se juega a **taparle las bocas**.

Miedo lleno = se queda quieta unos segundos. Miedo desbordado sin cerrar = huye.

### Fase 3 — El cierre *(y aquí está el coste)*

Cuando se queda quieta se abre la boca del cascabel: un platillo que la traga.

> **Capturar acaba la caza.** La bola entra, el platillo se cierra, y bajas.

Eso es lo que hace que sea una decisión y no un regalo: los 20 s de arriba son
tuyos hasta que gastas la captura. ¿Cierras con esta criatura, o la sueltas y
sigues a por la que te falta en `RECUPERADO/`? El reloj del enemigo corre
mientras tanto (`DISEÑO.md` §5), así que dudar cuesta vida.

**Y no acaba ahí: hay que bajarla.**

### Fase 4 — El regreso, que es la que da la tensión

El regreso ya existe y está medido: **llega a una pala 60 de 60 veces, a 211
px/s y 292 ms** (tanda 0g). Hoy no significa nada. Con la captura dentro:

> Bajas la criatura **dentro de la bola**, y si drenas antes de que el cascabel
> toque una pala, **se pierde**.

292 ms es por encima del umbral humano de 250 a propósito, o sea que se puede
salvar — pero es el tiro más caro de la partida, porque no estás salvando una
bola, estás salvando un `.dat`. Es exactamente la tensión de bola que las
pruebas con gente decían que no se notaba.

**Coste de construcción: cero geometría nueva.** Es un estado en la bola y una
señal en el drenaje.

---

## 3. La planta alta: siete diferencias, y ninguna es decorado

> *«El mapa de arriba no puede ser una réplica, ha de sentirse diferente»* —
> Daniel. *«Diferente diseño, bumpers, zonas, plataformas, túneles»*.

La de hoy es una réplica **por la zona de palas**, que se copió a propósito para
heredar tres sesiones de arreglos. Ese atajo es el que hay que devolver.

### 3.1 — Palas cortas · **decidido por Fátima**

Se descartó la planta alta sin palas: *«no tenemos habilidades para controlar el
resto de la mesa, y añadirlas con más botones abre mucho la complejidad de lo
que es un pinball de dos teclas»*. Siguen siendo **dos palas y las dos mismas
teclas** — lo que hace una máquina real con un flipper superior.

Lo que cambia es el tamaño. Abajo la pala mide 64. Arriba, **más corta**.

Y la razón no es estética, la dijo ella: *«pasa de ser random a skill»*.

> **⚠ CORREGIDO (18-ago).** Aquí ponía además: *"el hueco entre palas de arriba
> ES el reloj de la caza; los 20 s son el techo, el suelo lo pone tu mano"*.
> **Eso se cae con el salvabolas de §1b**: el reloj es el reloj, y punto.
>
> Y el tamaño también. Se construyó con 38 —la mitad que abajo— y Daniel lo
> tumbó jugándolo: *"flippers extremadamente cortos"*. Queda en **54**, con los
> ejes a 136 para que el hueco baje a 24 px, o sea la MITAD que abajo.
>
> Lo que sobrevive de la decisión de Fátima, y es lo importante: **la pala de
> arriba sigue siendo más corta que la de abajo y se nota en la mano**. Lo que
> no sobrevive es usarla como castigo. Medido, 60 cazas con un jugador que
> aporrea: con 38 la mesa tenía que salvarle la bola una y otra vez; con 54 y el
> hueco a 24, **cero salvadas** y 6,3 golpes por caza (contra 3,7).

Ojo con el invariante: lo cerrado es el **ancho de mesa (400)** y el **tamaño de
bola**, porque de ellos cuelga el hueco de ABAJO. El largo de una pala de la
planta alta es geometría de una planta que se está rediseñando, y se puede
tocar. Pero **no se decide a ojo**: se resuelve contra la medida de §6.

### 3.2 — Sin slingshots · la diferencia que más se nota por menos trabajo

Abajo hay dos. Arriba, **ninguno**.

Un slingshot es lo que mantiene viva a una bola que ya habías perdido: patea
solo, y patea al azar. Quitarlos hace dos cosas a la vez, y las dos son lo que
se pidió:

- La bola que se te va por el lado de la pala **está muerta**. No hay salvada
  gratis. Eso es "de random a skill", literal.
- Se juega distinto **sin aprender nada nuevo**, que es la definición de mesa
  distinta que pide el criterio de salida de la Fase 1d.

En su sitio, **paredes lisas en diagonal** que dejan caer la bola hacia la pala.
Predecible en vez de explosivo. Coste: borrar dos nodos y mover dos paredes.

### 3.3 — Sin outlanes, sin carriles de retorno, sin órbita doble

La zona de palas de arriba es **lo mínimo**: dos palas cortas, dos paredes
lisas, el desagüe. Nada más. Abajo hay outlanes, inlanes, retorno y postes;
arriba, nada de eso. Se lee como otro sitio en la primera bola.

### 3.4 — Plataformas y túneles en vez de carriles · **el sistema ya está**

Todo esto entró apagado en la tanda 0h y no lo usa ninguna geometría:

| Pieza | Qué es arriba |
|---|---|
| **La plataforma central** | una isla elevada con borde. Es donde vive la criatura, y desde el tablero **no se la alcanza**: hay que subir. Salirte del borde es caer |
| **Dos túneles** | cruzan por debajo del tablero y salen en sitios distintos. Es donde la criatura se esconde y donde el miedo drena |
| **Un cruce** | una rampa pasa por encima de otra sin tocarla. Hoy es imposible; con capas es gratis |
| **Rampa que no llega** | `velocidad_escape` > 0: si no pegas fuerte, te caes al tablero de arriba |

Aquí es donde la tanda 0h se cobra: no hay que construir ningún sistema, hay que
**encender lo que ya está en verde**.

### 3.5 — Búmperes colocados, no un racimo

Abajo hay dos racimos y ya se midió lo que dan (3,9 golpes por entrada). Arriba
un tercer racimo sería más de lo mismo.

**Tres búmperes sueltos, cada uno pegado a una boca de túnel.** Su trabajo no es
puntuar, es que la criatura no quiera meterse ahí. Un búmper que empuja al bicho
en vez de al jugador es un búmper que se juega distinto con el mismo sprite.

*(Y esto no es pachinko: los pines se tiraron en la tanda 0g porque una rejilla
es un comedor de energía pasivo. Tres búmperes separados con hueco de sobra son
lo contrario.)*

### 3.6 — Los 1.470 px de carril muerto

Medido en la tanda 0g, sobre la mesa de hoy:

| Franja | Ocupado | Libre en la planta alta |
|---|---|---|
| Izquierda | el regreso, y=672 a 1030 | **y=150 a 670: entera** |
| Derecha | el umbral, y=730 a 258 | y=150 a 258 |

La izquierda da un carril limpio **de arriba abajo de la planta alta**, y una
bola mide 18 en una franja de 20: es carril exacto. Ahí va **la órbita de
arriba**, pegada al borde, tipo habitrail. Es lo único largo que tiene una mesa
pequeña, y sin un tiro largo la planta alta vuelve a ser un pasillo con palas.

### 3.7 — La planta de abajo se congela y se atenúa · **decidido por Fátima**

Ya era medio cierto (el umbral no traga con multibola y las dos plantas no se
juegan a la vez). Lo que se añade es que **se vea**: la cámara sube, la planta
de abajo queda oscurecida y sin simular.

Y la cáscara lo cobra gratis. `PROPÓSITO.md` §9 quiere que reaccione a la mesa,
y `DISEÑO.md` §4 ya usa las ventanas como estado de juego (multibola = varias
ventanas abiertas):

> **La caza abre una ventana encima**, con pinta de diálogo de recuperación de
> disco. Se cierra sola al acabar la caza, y el fichero recuperado aparece en
> `RECUPERADO/`.

Cero píxeles de campo, y explica el modo sin un solo tutorial.

---

## 4. Qué NO se toca

- **Las rampas siguen siendo curvas**, no física simulada (`PLAN.md`).
- **El ancho de mesa (400) y el tamaño de bola (18)**: de ahí cuelga el hueco
  entre palas de abajo y toda la física medida.
- **El alto sí se puede subir** si la planta alta lo pide (lo autorizó Daniel).
- **Mantener el flipper sigue siendo mantener el flipper**: ninguna habilidad
  colgada de ese gesto, arriba tampoco.
- **Las palas de arriba usan las mismas dos teclas.** No se añade un tercer
  botón: es la decisión de Fátima y cierra la puerta a las variantes sin palas.

---

## 5. El orden, y por qué este y no otro

La planta alta ha salido mal dos veces por construir antes de decidir. Esta vez
va al revés, y **la geometría se juega antes de que exista un solo bicho**:

| | Qué | Criterio para pasar a la siguiente |
|---|---|---|
| **A** | Geometría: palas cortas, sin slingshots, plataforma, dos túneles, tres búmperes, órbita por la franja izquierda | La batería sigue en verde y la planta de abajo da los mismos números al decimal |
| **B** | Jugarla con **un objetivo de prueba, pero NO aleatorio** (ver abajo) | Daniel y Fátima distinguen las dos plantas por **cómo se juegan**, no por cómo se ven |
| **C** | Encima, las cuatro fases de la captura | Fallar una captura duele |
| **D** | Las nueve criaturas y `RECUPERADO/` | Ver el hueco da ganas de volver a subir |

**B es una puerta, no un trámite.** Si la planta alta no se siente distinta *sin*
captura, la captura no la va a salvar — sería la tercera vez que se apila un
sistema encima de un núcleo que aún no divierte, y eso es justo lo que `PLAN.md`
dice que no se hace.

### El objetivo de prueba de B: **de prueba sí, aleatorio no**

*Lo pidió Fátima con estas palabras: «si es de prueba vale, pero no quiero cosas
aleatorias para probar».* Y tiene razón por una medida que ya está en el repo:
la tabla de balance se rehízo tres veces contra un jugador inventado y las tres
se la llevó por delante el run. **Un maniquí aleatorio no mide una mesa: mide el
maniquí.**

Así que el objetivo de B es **determinista de punta a punta**:

- **`cr_brasa` quieta en la plataforma central**, con el sprite que ya está en el
  repo. Sin fases, sin miedo, sin huir: **plantada**.
- **Se captura al tercer impacto**, siempre. Tres, no "un 30 % por golpe".
- **La caza se abre a mano**, con una tecla de depuración, no con el 3 % del
  umbral. Lo que se está midiendo es la mesa, no la puerta de entrada.
- **Y el regreso ya cuenta**: si drenas bajando, se pierde. Esa parte es
  gratis y es la mitad de lo que hay que juzgar.

Con eso, dos partidas seguidas se pueden comparar entre sí, que es lo único que
hace falta para contestar "¿se siente distinta de la de abajo?". Todo lo que en
B sea un dado es ruido metido a propósito en la única medida que importa.

---

## 6. Los diales, y la medida que los cierra

Nada de esto se decide a ojo. Se expone como parámetro y se barre.

| Dial | Punto de partida | Qué mide |
|---|---|---|
| `pala_alta_largo` | 64 → por barrer | duración de bola arriba |
| `pala_alta_separacion` | por barrer | ídem |
| `plataforma_borde_altura` | — | cuánto perdona caerse |
| `tunel_drenaje_miedo` | — | cuánto castiga perderla de vista |
| `miedo_por_golpe` / `por_bumper` | — | si el modo se juega a acertar o a acorralar |
| `caza_tope` | 20 s | ya existe, y hoy no se alcanza nunca |
| `umbral_boca`, `umbral_entrada_radio`, `umbral_velocidad_minima` | 3 % | cada cuánto se abre la caza |

**La medida que cierra la geometría de arriba.**

> **⚠ CORREGIDA (18-ago), y no por el número: por la pregunta.** Aquí ponía *"un
> jugador que solo aporrea drena arriba en 3-4 s"*. Se construyó, se midió —7,6 s
> con las palas a 38— y al jugarlo resultó que **el objetivo estaba mal**: buscar
> que el malo drene rápido es diseñar un castigo, y esto es un bonus.
>
> Con salvabolas, la duración es SIEMPRE el tope, así que medirla no dice nada.
> Lo que dice algo:
>
> **Cuántas veces tiene que salvarte la mesa** —o sea cuánto bonus tiras— y
> **cuánto llegas a tocar mientras estás arriba**. Medido con
> `tests/medir_planta_alta.gd`, 60 cazas por celda, jugador que aporrea:
>
>     largo  separ  hueco   salvadas   golpes
>        46    136   38.8       1.3      3.7
>        54    128   16.6       0.0      6.8
>        54    136   24.6       0.0      6.3   <- el elegido
>        54    144   32.6       0.4      6.5
>        64    136    7.0       0.0      6.5
>
> Y el otro número, el que dice si la planta se JUEGA o se mira: con 54/136 el
> que aporrea da **6,3 golpes y 7 recorridos** en el bonus, y pasa el 37 % del
> tiempo por encima de la zona de palas y solo el 21 % metido en una curva.

---

## 7. Los tres riesgos, escritos antes de tropezar

**1. El 3 % es probablemente muy poco, y ahora importa más.** Ya estaba anotado
como dial. Pero una caza de cuatro fases hay que **aprenderla**, y no se aprende
lo que ves dos veces por run. *Antes de construir la fase C hay que decidir cada
cuánto se abre*, o se estará puliendo un modo que casi nadie ve. Es la primera
pregunta de la lista de abajo.

**2. Quitar los slingshots puede pasarse de frenada.** Sin slingshots y con pala
corta, dos castigos a la vez. Si la medida da 1-2 s para un jugador normal, se
devuelve UNO de los dos: primero la pala, que es la que Fátima eligió, y los
slingshots se quedan fuera.

> **⚠ PASÓ, Y AL REVÉS DE COMO SE ESCRIBIÓ (18-ago).** El riesgo estaba bien
> visto —fue de frenada— pero por el sitio que no se miraba: **con los dos
> castigos puestos, la medida decía que la planta alta era MÁS BLANDA que la de
> abajo** (12,2 s arriba contra 8,1 s abajo), porque al quitar los slingshots se
> quitaron también los OUTLANES, que son los que se comen la bola abajo. El
> maniquí no lo notaba; Daniel jugándolo, sí. **Se devolvió la pala, como decía
> esta nota, y los slingshots siguen fuera.**
>
> La lección, que es de las de anotar: *dos castigos a la vez* y *dos válvulas
> quitadas a la vez* se compensan sin que se vea, y lo único que separa una cosa
> de la otra es jugarlo.

**3. Cuatro fases pueden ser demasiadas para 20 segundos.** Rastro + acoso +
cierre + regreso en 20 s es apretado. Plan B si al jugarlo se atropella:
**el rastro se cae** y la criatura sale ya visible. Las otras tres aguantan
solas, y el rastro es la más barata de rehacer luego.

---

## 8. Preguntas para Daniel y Fátima

Ninguna se contesta leyendo.

1. **¿Cada cuánto se abre la caza?** Hoy 3 de cada 100 entradas al racimo. Con
   cuatro fases hace falta verla más. ¿Una vez por combate garantizada, o sigue
   siendo un tiro que se busca?
2. **¿La criatura capturada se puede perder al drenar bajando?** Es lo que le da
   la tensión, y es lo que puede hacerla odiosa. Se decide jugándolo.
3. **¿Se caza una por caza, o varias?** Capturar acaba la caza es lo que la
   convierte en decisión; permitir dos la vuelve farmeo.
4. **¿Qué pasa si cazas una criatura que ya tienes?** ¿Chatarra? ¿Nada? ¿Una
   segunda copia que sirve para otra cosa?
5. **¿Los slingshots fuera del todo, o uno solo?**

---

## 9. LAS PUERTAS, Y LA MECÁNICA ENTERA DE LAS DOS PLANTAS *(18-ago, tarde)*

Lo abrió Fátima con tres frases seguidas, y las tres son la misma:

> *«Que tenga doble altura es para que podamos jugar con ideas como que la bola
> cae, que pueda pasar la bola por debajo, cosas así. La entrada y la salida ha
> de ser una puerta, y la puerta ha de reunir condiciones y requisitos para
> abrirse. Ya tenemos ejemplos de puertas que podemos usar.»*

Y encima el cuelgue del que salió todo esto: *«la bola se puede quedar entre la
parte de arriba y abajo infinitamente al drenar la bola arriba sin tocar la
salida»*.

**No se escribe geometría aquí.** Esta sección es para decidir, porque la planta
alta ya ha salido mal dos veces y las dos por construir antes de pensar.

---

### 9.1 La avería de verdad no era el cuelgue: es que las dos plantas no se tocan

El cuelgue está arreglado (`_desalojar_arena`, y con dos pruebas que lo sujetan).
Pero mirando POR QUÉ era posible sale una cosa más grande, y es la que gobierna
todo lo demás:

> **Hoy la planta alta y la planta baja no se comunican por gravedad.** Entre el
> fondo del embudo de la arena (`arena_fondo_y` = 648) y el arco de la mesa de
> abajo (y = 660) hay **12 px de nada**, y el arco es macizo. La única forma de
> bajar es el recorrido `regreso`, que tiene `velocidad_minima` **infinita**: o
> sea que **la bola no puede meterse en él ni queriendo**. Te mete la mesa.

De ahí cuelgan, una detrás de otra, TODAS las cosas raras de la planta alta:

| Lo que se ve raro | De dónde sale |
|---|---|
| la salida no se puede apuntar | el regreso no tiene boca, porque no puede tenerla |
| drenar arriba necesita un salvabolas | si no, la bola se queda sin sitio a donde ir |
| la bola se quedaba colgada para siempre | nadie la metía en el regreso y ella no podía |
| *"la bola cae"* y *"pasa por debajo"* | **imposibles hoy**: no hay por dónde |

Y esa última fila es la que importa, porque es literalmente lo que Fátima dice
que es la doble altura PARA. **Hoy la doble altura no es doble altura: son dos
mesas separadas con un ascensor.**

---

### 9.2 La decisión que hay que tomar antes que las puertas: abrir el suelo

Hay dos caminos y no son medio camino el uno del otro.

**Camino A — se queda el ascensor.** Las puertas son puertas de verdad (se abren,
se cierran, tienen requisitos) pero lo que hay detrás sigue siendo un recorrido
que teletransporta. Barato, cero riesgo, y *"la bola cae"* no llega nunca.

**Camino B — el arco de la planta baja gana un agujero.** El suelo de la arena
deja de ser macizo. A partir de ahí:

- la bola **cae** de una planta a la otra, de verdad y a la vista;
- drenar arriba deja de necesitar un invento: **drenar arriba es bajar**;
- **"pasar por debajo"** existe, porque hay un dentro y un fuera del arco;
- la salida se puede **apuntar**, o sea que es un tiro y no un trámite;
- y `_desalojar_arena` deja de hacer falta, porque el agujero hace su trabajo.

**El camino B es el que pide la frase de Fátima, y es el que recomienda esta
nota.** Pero tiene una cuenta que no se puede saltar, y está escrita desde el
primer día en `parametros_mesa.gd`:

> Una caída libre desde la arena llega abajo a **1500 px/s**, o sea **67 ms** de
> ventana para reaccionar. El cañón ya se tuvo que ablandar a la mitad porque
> 900 px/s —111 ms— era *«un tiro imposible, o sea perder la bola con pasos
> extra»*, y un humano reacciona en 250 ms.

O sea: **el agujero no puede soltar la bola sobre las palas.** Lo que hace un
pinball de verdad con esto es un *subway*: el agujero come la bola y la escupe
en un carril, a velocidad de carril. Que es **exactamente lo que ya hace el
regreso** —sale a 700 × 0,30 = 210 px/s y la prueba exige que llegue por debajo
de 650—. Así que el camino B no tira nada de lo construido:

> **El agujero es una BOCA para el regreso, no una sustitución del regreso.** Se
> le quita el `velocidad_minima = INF`, se le pone una boca de verdad debajo del
> agujero, y la bola pasa a poder entrar sola. El recorrido, su velocidad de
> salida y su prueba de "llega cazable" se quedan como están.

Y eso es una tanda pequeña, no un rediseño.

---

### 9.3 Entonces hay DOS agujeros, y esa es la mecánica

Con el suelo abierto, la planta alta tiene dos formas de acabarse y **no pueden
ser la misma**, porque una es habilidad y la otra es fallar:

|  | **LA PUERTA** (la salida) | **EL DESAGÜE** (el hueco entre palas) |
|---|---|---|
| dónde | a un lado, hay que apuntarle | en el centro, es donde caes |
| cómo se llega | tiro elegido | fallo |
| qué pasa | bajas por tu pie | la mesa te sirve otra bola arriba |
| qué cuesta | nada: te llevas lo cazado | lo que decida `caza_coste_salvada` |

Eso resuelve de un golpe la contradicción que había entre las dos frases de
Daniel: *«no me gusta que te puedas salir de esa zona tan fácil»* (o sea, drenar
no debe echarte) y *«debería sentirse como un bonus»* (o sea, no debe castigarte).
**Drenar sigue sin echarte. Lo que cambia es que ahora existe otra puerta, y esa
sí la eliges tú.**

Y le da al reloj un significado que hoy no tiene. Hoy el reloj es lo único que
acaba la caza, así que agotarlo es el final normal y por lo tanto no es nada. Con
la puerta abierta a un lado:

> **el reloj deja de ser una amenaza y pasa a ser una fecha límite.** Lo que se
> pierde al agotarlo no es la bola, es lo que llevabas encima sin haberlo bajado.

Que es codicia, no supervivencia, y la codicia es de lo que va un bonus. Encaja
además con `DISEÑO.md` §5 —la zona alta suelta **material de desbloqueo, no poder
de run**— y con `PROPÓSITO.md` §2: *«piezas rescatadas de la memoria antes de que
el reinicio las borre»*. **Bajarlas por tu pie ES rescatarlas.**

---

### 9.4 Qué es una puerta, técnicamente: ya está construida

*«Ya tenemos ejemplos de puertas que podemos usar»* — y es verdad, hay dos
mecanismos y entre los dos dan la puerta entera sin código nuevo:

1. **`Colisionador.Tipo.PUERTA` con `una_direccion`** — la puerta antirretorno del
   carril lanzador (`mesa.gd` línea 181). Existe solo para la bola que va bajando
   y no existe para la que sube. Es la mitad "se cierra a tu espalda".
2. **`Colisionador.activo`** — lo que hace que un target abatido deje de
   colisionar. Un colisionador con `activo = false` **no está**. Es la mitad "se
   abre y se cierra", y viene con su aviso y su sonido ya montados.

O sea que una puerta con requisitos es: **un `PUERTA` cuyo `activo` lo decide una
condición**. Lo que falta no es mecanismo, es elegir la condición.

---

### 9.5 La puerta de ENTRADA: qué debería abrirla

Hoy no hay puerta: hay un tiro que **se acierta 3 de cada 100 entradas al
racimo**. Y eso no es una dificultad, es una lotería — está escrito como pregunta
abierta en §8.1 desde el primer día. Una puerta es mejor que una lotería por una
razón concreta y no por gusto: **una lotería no se ve venir y una puerta sí.**

Tres candidatas, todas con lo que ya existe en la mesa:

| Requisito | A favor | En contra |
|---|---|---|
| **cerrar un banco de targets** | los dos bancos ya están, ya se abaten, ya suenan al cerrarse, y **se ven en pie desde el otro lado de la mesa**: sabes lo que te falta sin mirar el HUD | puede quedarse corto: los bancos se cierran solos a menudo |
| **tres cerrojos, tres tiros largos** (banco, órbita, rampa fuerte) | barra de progreso dibujada en la propia puerta, y obliga a variar de tiro | más lento; puede no abrirse nunca en un combate corto |
| **el multiplicador de tramo** | cero geometría | el requisito vive en el HUD y no en la mesa. **Es el peor por eso**, no por dificultad |

**Recomendación: empezar por el banco y medir cada cuánto abre.** Es el único de
los tres que se lee sin leer nada, y si sale demasiado fácil, subir a "los dos
bancos" o a los tres cerrojos es cambiar una constante. La pregunta §8.1 —*¿una
vez por combate garantizada, o un tiro que se busca?*— se contesta con esa medida
y no antes.

Y la puerta **se cierra al pasar**, con el `una_direccion` que ya existe: mientras
estás arriba, la entrada no está. Eso no es adorno — es lo que impide que la
entrada y la salida se confundan en el mismo agujero.

---

### 9.6 La puerta de SALIDA: la que hay que pensar mejor

Es la que más cambia el modo, porque decide si el bonus es una decisión o un
trámite. Tres formas, en orden de lo que aportan:

**a) Abierta desde el principio, bajar es voluntario.** Es la que sostiene §9.3
entera: te llevas lo cazado si bajas por tu pie, pierdes parte si te echa el
reloj. Convierte la salida en el segundo mejor tiro de la planta, después de la
subida a la isla. **Es la recomendada**, y de paso es la única que contesta
literalmente al *«sin tocar la salida»* de Fátima: hoy el jugador no tiene ningún
motivo para tocarla, y aquí tiene el único que hace falta.

**b) Cerrada hasta capturar.** Más limpia de leer y más ortodoxa —el objetivo abre
la puerta— pero la salida vuelve a ser un trámite: cuando se abre, ya has
terminado. Y choca con §8.3: si capturar abre la salida, capturar acaba la caza,
y eso hay que decidirlo aparte.

**c) Se abre por tramos según cae el reloj.** La más tensa y la más difícil de
leer en pantalla. Se guarda como variante de (a) —un `caza_puerta_desde` en
segundos— más que como opción propia.

**Lo que hay que decidir jugando, no leyendo:** si una salida voluntaria hace que
la gente se vaya en cuanto entra. Si pasa, el arreglo no es cerrar la puerta: es
que lo que se caza valga más que la seguridad, que es un número.

---

### 9.7 Qué pasa con el salvabolas

**No se toca todavía**, y a propósito: con la puerta de salida montada, el
salvabolas deja de ser un parche y pasa a ser una de las dos salidas. Su precio
—`caza_coste_salvada`, hoy a 0— es el dial que separa "bonus regalado" de "bonus
que se juega", y **ese número no se elige antes de que exista la puerta**, porque
hoy no hay nada contra lo que compararlo.

Cuando la puerta esté, la pregunta correcta es una sola: *¿cuántos segundos de
bonus vale no haber drenado?* Y se contesta con la medida de §6, no aquí.

---

### 9.8 El orden, que es lo único que no es opinión

1. **Abrir el suelo.** Un agujero en el arco + boca de verdad para el regreso.
   Es lo que desbloquea todo lo demás y es lo más pequeño de los cuatro.
   Criterio de salida: la bola **cae** de arriba abajo y llega a la pala por
   debajo de 650 px/s, que es la prueba que ya existe.
2. **La puerta de entrada**, con el banco como requisito. Medir cada cuánto abre.
3. **La puerta de salida**, en la variante (a). Jugarla.
4. **Y solo entonces**, el precio del salvabolas y las ideas que la doble altura
   abre —pasar por debajo, caer sobre el racimo, un tiro de la planta baja que
   entre por el agujero—. Antes de esto son dibujos.

Nada de esto se construye sin que Daniel o Fátima cierren §9.2, que es la única
pregunta de la que cuelgan las otras: **¿se abre el suelo, sí o no?**

---

### 9.9 El sonido de las tres puertas, ya hecho y fuera del repo *(18-ago)*

**Suno quedó descartado para efectos** (`assets/prompts_sonido.md` §7): no tiene
control de duración, así que a un golpe de 200 ms le rellena con lo que se le
ocurra los diecinueve segundos que le sobran. Y al caerse esa opción apareció lo
que había debajo, que es mejor:

> **Una puerta es la misma estructura que `caida`: una cosa que dura y LUEGO un
> golpe.** Eso ya se sabe hacer desde que `sonidos.py` tiene `retardo`, que fue
> justo el parámetro que hubo que inventar para el sonido de caerse.

Las tres están sintetizadas y medidas. Duran **exactamente** lo que se les pidió
—750, 90 y 300 ms, que es lo único que Suno no acertó ni una vez— y las tres viven
por debajo de 150 Hz, donde el bumper tiene el 0,1 por ciento de su energía y el
drenaje el 5: la banda está libre, así que la puerta no compite con nada.

| | dura | energía <150 Hz | energía >3 kHz |
|---|---|---|---|
| `puerta_abre` | 750 ms | 58 | 12 |
| `puerta_niega` | 90 ms | 82 | 0,5 |
| `puerta_cierra` | 300 ms | 69 | 0,7 |

**Y POR ESO ESTÁN AQUÍ Y NO EN `sonidos.py`.** Se metieron ahí, se generaron, y la
batería las tumbó a la primera con *"no hay ningún wav generado que el juego no
use: o se enganchan o se borran"*. **La prueba tiene razón y el candado se
respeta**: un wav generado y sin enganchar es un evento mudo esperando, que es la
avería que abrió la tanda 0h2. Como las puertas no existen todavía, meter las
recetas hoy abre una ventana de tres tandas en la que el repo tiene sonido de algo
que no está.

Así que las recetas viven en `sonidos_pruebas.py` y **se mudan a `SONIDOS` el
mismo día que se construyan las puertas**, en el mismo commit que sus entradas en
`NodoSonido.AJUSTES`. Ni antes, ni en los dos sitios. Ver §9.11.


Al pegarlas, las dos cosas de siempre: **`AJUSTES` en `nodo_sonido.gd`** —si no, la
otra prueba se queja de que falta el wav de algo que el juego pide— y
**reimportar** después de `python3 sonidos.py`, o Godot sigue sirviendo la copia
vieja de `.godot/imported/`.


> **`puerta_cierra` se cayó al oírlo. Ver §9.10.**

**`puerta_niega` es la que hay que oír con más atención.** Un "no" que suene bonito
se lee como un premio pequeño y el jugador vuelve a tirar creyendo que casi lo
tiene. Está construido para sonar a nada —caída 45, filtro a 700, cero energía por
encima de 1,4 kHz— y si al oírlo parece un golpe de mesa más, el que está mal es
este, no la puerta.

---

### 9.10 `puerta_cierra` se cayó de oído, y lo que salió de ahí *(18-ago)*

Fátima lo escuchó: *"el de puerta cierra es simple y se puede confundir con un
bumper, lo podríamos dejar como bumper secundario, prueba a hacer más"*.

**El diagnóstico es exacto y conviene escribirlo entero, porque vale para todo lo
que venga después:** aquello era UN GOLPE, y un golpe es un bumper. Lo que separa
a una puerta de un bumper no es el timbre —se puede bajar de tono todo lo que se
quiera y seguirá sonando a bumper grave— sino que

> **una puerta tiene un ANTES y un DESPUÉS, y un bumper no puede permitirse
> ninguno de los dos**, porque suena cuarenta veces por bola y cualquier cosa que
> dure se convierte en un zumbido.

O sea que el eje no es el color del sonido: es el **tiempo**. Por eso las cuatro
variantes de abajo no son cuatro ajustes de la misma receta, son cuatro respuestas
distintas a *¿por qué esto no es un bumper?*

| | dura | qué le añade | por qué un bumper no puede |
|---|---|---|---|
| **a · con recorrido** | 520 ms | la losa corre 240 ms ANTES del portazo | un bumper no tiene recorrido, aparece |
| **b · con sala** ← **GANA** | 870 ms | cola grave por debajo de 60 Hz después del golpe | la cola está prohibida en un golpe de mesa |
| **c · doble golpe** | 290 ms | cae, rebota una vez, y luego asienta el cerrojo | ningún sonido del juego golpea dos veces |
| **d · de hierro** | 450 ms | parciales INARMÓNICOS en 1 : 1,82 : 3,0 | la mesa entera es armónica |

La **d** es la única que cambia de material en vez de cambiar de tiempo, y está
ahí a propósito como control: si gana ella, lo que fallaba no era la estructura
sino que todo el juego suena a madera y piedra.

**Y el bumper secundario, con una corrección.** La idea es buena pero **300 ms no
valen para un bumper**: el de abajo dura 130 justamente porque suena todo el rato.
Se conserva el carácter —grave, pesado, sucio— y se recorta a **140 ms**.
Centroide 1114 Hz contra los 1762 del bumper de abajo, o sea la misma familia
claramente más oscura.

**Y el sitio bueno son los TRES BÚMPERES DE LA ARENA**, no el racimo de abajo:
que la planta alta suene distinta es media sensación de bonus, y esto la da sin
tocar geometría. Los tres están en (96,264), (304,264) y (134,424).

Las recetas de todo esto están en `sonidos_pruebas.py`, no aquí: ver §9.11.

---

### 9.11 LA FAMILIA METAL, y el banco donde vive *(18-ago)*

Fátima oyó las cuatro y contestó dos cosas distintas:

> *«La D tiene un toque especial, necesitamos más sonidos así. Aun así, si
> tuviese que elegir, me quedaría con la C.»*

**Eso no es una duda, son dos respuestas a dos preguntas.** La `c` gana la
pregunta de la ESTRUCTURA —un doble golpe no se confunde con un bumper—, y la `d`
gana otra que ni siquiera estaba planteada: la del MATERIAL. La `d` era el
control, y los controles están para esto.

#### Qué es el "toque especial", exactamente

`_capa` hace `fase * multiplo` sin redondear, así que **`armonicos` acepta
múltiplos NO ENTEROS** y siempre los ha aceptado. Nadie lo había usado.

Y ahí está todo, porque **toda la mesa es armónica**: cuadradas y triángulos con
múltiplos enteros, que es exactamente lo que hace que el juego entero suene a
madera, piedra y plástico. Un parcial en 1,83 no pertenece a ninguna serie
armónica, y el oído lee eso como una sola cosa y sin margen de duda: **metal**.

> **Es un material entero que el juego no tenía, y estaba disponible sin escribir
> una línea de sintetizador.** No hacía falta grabar nada, ni Suno, ni un banco de
> samples: hacía falta usar un parámetro que llevaba ahí desde el primer día.

Los ratios no se inventan, se copian de objetos reales: 1 : 1,19 : 1,51 : 2,02
para una campana grande, más apretados y más agudos para un cascabel. Por eso no
suenan a sintetizador, suenan a objeto.

#### La deuda que destapa, y es vergonzosa

**El juego se llama Cascabel y no tenía ningún sonido de cascabel.** Ahora hay uno
—`cascabel`, 550 ms— y no está asignado a nada todavía a propósito: es el sonido
de la marca, y dónde suena (la bola, el menú, el logotipo al arrancar) es una
decisión que no se toma de pasada.

#### Los seis nuevos

| | dura | qué es |
|---|---|---|
| `cascabel` | 550 ms | el objeto que da nombre al juego |
| `campana_arcana` | 1830 ms | candidato al ÚNICO sonido bonito, con cuentagotas |
| `puerta_abre_hierro` | 880 ms | la versión metálica de abrir, para emparejar con la `c` |
| `reliquia` | 650 ms | rescatar una pieza (`PROPÓSITO.md` §2): dos golpes subiendo |
| `captura` | 520 ms | la criatura atrapada (§2): jaula que se cierra |
| `bumper_metal` | **130 ms** | **la prueba de esfuerzo** |

**`bumper_metal` es el que hay que juzgar primero**, porque es el único que
decide algo grande. Casi todo lo que suena en esta mesa suena constantemente, así
que la pregunta no es si el metal es bonito —ya sabemos que sí— sino:

> **¿el metal sobrevive a 130 ms?**
>
> Si sí, el material vale para toda la mesa y hay una tanda de rehacer la paleta
> de sonido. Si suena a chasquido sucio, el metal solo vale para lo que suena
> POCO —puertas, campanas, capturas, reliquias— y entonces es un acento y no una
> paleta. **Las dos respuestas son útiles y las dos hay que saberlas antes de
> tocar `sonidos.py`.**

#### Dónde viven ahora, que es lo que faltaba

`sonidos_pruebas.py`, nuevo, y escribe en `assets/sonido_pruebas/`. Existe porque
el candado *"no hay ningún wav generado que el juego no use"* es bueno y no se
toca, pero deja sin sitio a lo que hay que **oír antes de construir** — que es
justo lo que se ha estado haciendo estas dos últimas rondas.

    LA REGLA
    Un sonido vive en el banco mientras no exista la cosa que lo dispara. El día
    que exista, su receta se MUEVE a `sonidos.py` y su ajuste a
    `nodo_sonido.gd`, en el mismo commit. Nunca antes, nunca en los dos sitios.

Cada prototipo lleva escrito en `DESTINO` dónde acabaría si se aprueba, para que
mudarlo sea copiar y pegar en vez de arqueología. `python3 sonidos_pruebas.py
--listar` los enseña todos con su duración y su destino. Los catorce que hay hoy
incluyen las cuatro puertas, la `v1` que Fátima tumbó y el `bumper_arena` que
salió de reciclarla.

---

### 9.12 Se cayó la `c` al reescucharla, y el cascabel se rehízo en serio *(18-ago)*

> *«Creo que la lié. Te dije la C, y ahora que la escucho, era la B: un sonido de
> cierre como con un eco o grave de fondo. Pero debería de ser más sonido de
> cierre.»* — Fátima

**No la lió: la primera escucha fue de estructura y la segunda de sensación**, y
son dos oídos distintos. La `c` gana en la mesa de disección —dos golpes no se
confunden con un bumper— y la `b` gana en el sitio, porque **la cola grave dice
algo que el doble golpe no puede decir: que hay una sala detrás.** Y la caza pasa
en una planta alta que tiene que sentirse otro sitio, así que eso vale más que la
distinción limpia.

#### Lo que le faltaba a la `b`, y era una sola cosa

*«Debería ser más sonido de cierre»* tiene una causa concreta: **la `b` no tiene
cerrojo.** Es un golpe y una sala, y eso es un portazo en una cueva. Lo que dice
*cerrado* —y no solo *golpe*— es la pieza que asienta después. La `c` sí lo tenía;
al elegir la `b` se perdió por el camino.

Cuatro variantes, todas con el cerrojo puesto y el impacto **amortiguado** (caída
de 18 a 26): una puerta no resuena, resuena la sala.

| | dura | qué añade |
|---|---|---|
| `b2` | 920 ms | la `b` + cerrojo a los 150 ms, golpe amortiguado |
| `b3` | 1010 ms | la `b2` + 90 ms de aire antes — no los 240 de la `a`, que eran un viaje |
| `b4` | 1320 ms | sala más honda (1,3 s) y cerrojo DOBLE, clac-clac de cerradura |
| `b5` | 870 ms | la `b2` con la sala **una octava arriba** |

**La `b5` no es una variante de gusto, es de ingeniería, y conviene mirarla.** La
cola de la familia `b` vive por debajo de 60 Hz, donde un altavoz de portátil
empieza a rendirse: medido, la `b2` tiene el **60 %** de su energía por debajo de
80 Hz y la `b4` el **72 %**. Se oye algo igual porque es un triángulo y no un seno
—sus armónicos en 114, 171 y 228 Hz sobreviven al filtro— pero **lo que se oye no
es lo que se diseñó**. La `b5` mueve la sala a 104 Hz y baja al 0,9 % por debajo
de 80: suena igual en cualquier sitio. Si en tus altavoces la `b2` y la `b5` se
parecen, gana la `b5` sin discusión.

#### Y el cascabel, que es el que más importa

> *«El de cascabel debería ser más sonoro, y escucharse más suave: es el sonido
> que más currado debería estar.»*

Tiene razón y el diagnóstico se puede escribir con números. **Estaba hecho como un
efecto de mesa**, y un efecto de mesa está optimizado para lo contrario de esto:
para ser corto, seco y no molestar cuando suena cuarenta veces. Tres fallos, y van
juntos:

1. **Un solo cascarón.** Un cascabel de verdad son dos mitades que nunca están
   afinadas igual, y ese desajuste produce **batidos**: el tono late despacio en
   vez de quedarse quieto. Eso es exactamente lo que el oído llama *sonoro*. Ahora
   son dos cascarones a 7 Hz de batido.
2. **Todos los parciales muriendo a la vez.** En un objeto real los agudos se
   apagan primero y el grave sostiene. Una sola envolvente suena a sintetizador;
   una por parcial suena a metal. Ahora los altos mueren en 450 ms y el hum
   sostiene 1,7 s.
3. **Ataque de 2 ms y badajo a todo trapo.** Eso es un clic, y un clic es lo
   contrario de suave. Ataque a 12 ms —el tono **florece**— y el badajo de 0,30 a
   0,16, metido por debajo del tono en vez de delante.

Medido: **suena entre 315 y 577 ms por encima del 10 % de su pico, contra 163 ms
de la versión vieja**, y el centroide baja de 2230 Hz a 1234-1721. Más largo y más
oscuro, que es *más sonoro y más suave* dicho en números.

| | dura | qué es |
|---|---|---|
| `cascabel_a` | 1700 ms | el limpio: un toque, batido de 7 Hz. El candidato por defecto |
| `cascabel_b` | 1715 ms | el que **repica**: tres toques en 130 ms y luego la cola. Es un objeto que alguien mueve |
| `cascabel_c` | 1900 ms | el cálido: una quinta por debajo y filtro a 5000. *Suave* llevado al final |
| `cascabel_d` | 2600 ms | **el del logotipo**: ataque de 25 ms, batido lento. No es para la mesa, es para lo que suena una vez por sesión |

La `d` no compite con las otras tres: son dos papeles distintos. **Un sonido de
marca que suena al arrancar puede durar 2,6 s; el mismo sonido dentro de una bola
no.** Lo normal sería quedarse con dos: uno de mesa y uno de arranque.

---

### 9.13 «Parece que sean 2 sonidos» — y lo era, por dos motivos *(18-ago)*

> *«Los cascabeles parece que sean 2 sonidos que acaban de distinta forma. Ha de
> ser un sonido agradable y coherente.»* — Fátima

Diagnóstico exacto, y esta vez se puede enseñar medido.

#### La primera causa: capas que empiezan y acaban en sitios distintos

La medida que lo destapa es **cuánto pesa el agudo (>1,5 kHz) en cada sexto del
sonido**. En un objeto que suena una vez, eso es casi plano. En los de la vuelta
anterior:

| | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| `cascabel_a` (v3) | 9,7 | 6,1 | 4,9 | 4,3 | 3,5 | **3,0** |
| `cascabel_d` (v3) | 5,0 | **14,5** | 5,3 | 4,6 | 3,5 | **2,6** |

La `d` triplica el agudo en el segundo sexto y luego se desploma: **eso es un
segundo sonido que llega tarde y se va antes**, y lo era literalmente — una capa
con `retardo=0.30`. Y la `a` pierde dos tercios de su brillo por el camino,
porque sus capas iban con `caida` de 2,2 a 9,0: los agudos se morían a los 450 ms
y el grave seguía solo 1,2 s más. **«Dos sonidos que acaban de distinta forma»,
tal cual.**

Fue culpa de aplicar bien una idea buena en el sitio equivocado. En un objeto
real los parciales altos SÍ se apagan antes que los graves — pero dentro de un
factor de dos, no de cuatro, y sin que ninguno desaparezca del todo mientras los
demás siguen.

#### La segunda: `armonicos` sobre un triángulo no da lo que pides

Más fina, y es la que impedía que cuajara ni siquiera el limpio.

Un triángulo **ya trae su propia serie armónica** en 3f, 5f, 7f. Así que un
parcial pedido en 1,37 llega con la suya detrás: 4,11, 6,85... El resultado son
**dos peines superpuestos** — uno armónico, que el oído lee como una NOTA, y otro
inarmónico, que lee como una CAMPANA. Dos cosas sonando a la vez, con la misma
envolvente y todo.

Con `seno` de portadora, cada parcial es un tono puro y **suena exactamente lo
que está escrito**. Es el mismo error de método que "medir por la cara que no es":
el parámetro hacía lo que dice, sobre una portadora que no valía.

#### La regla que sale de las dos

> **Todas las capas con el mismo `dur`, el mismo `caida` y el mismo `ataque`.
> Ningún `retardo`. Onda `seno` cuando los parciales importen.**

Vale para cualquier sonido que tenga que leerse como UN objeto — y **no vale para
los que son un gesto**: `caida` es aire y LUEGO un golpe, y la puerta es losa y
LUEGO cerrojo. Esos necesitan el `retardo` justamente por lo contrario. La
pregunta que decide cuál de las dos reglas aplicar es: *¿esto es una cosa, o una
cosa que le pasa a otra?*

Medido después del arreglo: el agudo por sextos va **18,3 · 24,2 · 20,8 · 19,0 ·
19,6 · 18,2**. Plano.

#### Los cuatro, y por qué son dos y no cuatro

| | dura | qué es |
|---|---|---|
| `cascabel_1` | 1400 ms | **el de MESA**, brillante. Candidato por defecto |
| `cascabel_2` | 1600 ms | el de mesa, cálido: una quinta por debajo |
| `cascabel_3` | 1400 ms | el 1 con 6 bits de cuantización, por si el seno limpio es demasiado limpio para esta máquina |
| `cascabel_4` | 2600 ms | **el de ARRANQUE**, y es *literalmente* el 1 con la cola larga |

**La `4` no es un diseño aparte: es la `1` con otro `caida`.** Mismos parciales,
mismo batido, mismo ataque, mismo todo. Eso es la otra mitad de *coherente* — que
el sonido de la mesa y el del arranque se lean como **el mismo objeto** en dos
sitios, y no como dos sonidos que se parecen.

#### Y un fallo del banco que salió por el camino

`sonidos_pruebas.py` sembraba el ruido con `abs(hash(nombre)) % 1000`, y **el
hash de una cadena en Python es aleatorio por proceso** desde la 3.3. Medido: 609,
773 y 614 para el mismo nombre en tres arranques. O sea que **el banco daba un wav
distinto cada vez que se lanzaba**.

Solo afectaba a las capas de ruido, así que el carácter no cambiaba y por eso no
se notó — pero un proyecto que decide cosas midiendo no puede tener un generador
que no reproduce, y además significaba que lo que se escuchaba no era exactamente
lo que quedaba guardado. Arreglado con `crc32`, que es estable entre ejecuciones y
entre máquinas.

---

### 9.14 Cerrado el cascabel de mesa; abierto el de arranque *(18-ago)*

> *«Cascabel 1-2 y 4 nos pueden servir (el 4 no tanto).»* — Fátima

**Cerrado: el cascabel de mesa es el `1` (brillante) o el `2` (cálido)**, y los
dos valen, así que la elección entre ellos puede esperar a que haya algo que lo
dispare y se oiga en contexto.

#### Que se caiga el `3` dice más que lo que se queda

El `3` era el `1` con seis bits de cuantización, o sea con la suciedad de máquina
que llevan **todos** los demás sonidos del juego: `bumper` tiene 5 bits,
`ataque` 4, `flipper` 6. Y descartarlo fija una regla de estilo que hasta ahora
no estaba escrita:

> **El cascabel es lo único del juego que NO es barato.**

Que es exactamente la misma decisión que el violeta arcano de `CONTEXTO.md` —*el
único color mágico, con cuentagotas*— y la del coro desafinado de
`prompts_musica.md` —*UN solo sonido bonito*—, trasladada al objeto que da nombre
al juego. La máquina no podía pagarse sonido bueno; **el cascabel es lo que la
máquina no fabricó**, y por eso se le nota.

#### Lo que le falta al `4`, y no es longitud

El `4` era el `1` con la cola larga, y eso lo hacía coherente pero no lo hacía
una entrada. **Un toque largo solo dura más.** Una entrada tiene que ASENTAR
algo, y para eso hay tres palancas que no son el tiempo — y ninguna de las tres
rompe la regla de §9.13, porque ninguna añade un segundo evento:

| | qué mueve | por qué podría funcionar |
|---|---|---|
| `arranque_a` | **dos cascabeles a la quinta**, golpeados a la vez | más grande sin ser más largo. Un solo ataque, una sola envolvente |
| `arranque_b` | **sin badajo**, ataque de 45 ms | no lo golpean: **aparece**. Es lo más "logotipo" de los cuatro |
| `arranque_c` | el **cálido** a longitud de logotipo | una entrada no tiene que llamar la atención, tiene que asentar |
| `arranque_d` | parciales de **campana grande** (1 : 1,19 : 1,51 : 2,02) | otro objeto, mismo material. El que más se aleja del sonido de mesa |

La `b` es la que contesta a la hipótesis concreta: **si lo que estorbaba era el
badajo**, o sea el "alguien lo ha golpeado" en un momento en el que nadie golpea
nada. Si gana la `b`, la regla es que un sonido de marca no lleva percusión.

#### Y la campana arcana estaba mal por lo mismo que el cascabel

`campana_arcana` se escribió antes de §9.13 y tiene **los dos defectos**:
portadora de triángulo —dos peines superpuestos— y una capa entrando a los
250 ms —un segundo sonido—. Rehecha con la regla en `campana_arcana_2`, con los
parciales de campana grande y desafinada a propósito, que es lo único que había
que conservar de la primera.

**Ojo con no repetir el error de método aquí:** la vieja no se borra hasta que
alguien confirme de oído que la nueva la supera. Es lo mismo que "guardar siempre
la mejor hasta la fecha" de `CLAUDE.md`, y ya estuvo a punto de costar la v3 de
`cr_calavera`.
