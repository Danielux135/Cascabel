# CAZA.md — CASCABEL

La planta alta rehecha (`PLAN.md` §1d) y **el sistema de captura**, que hasta
hoy no existía escrito en ningún sitio.

Documento de diseño, no de estado. Se escribe entero antes de tocar geometría
porque la planta alta ya ha salido mal dos veces y las dos por construir antes
de decidir.

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

Y la razón no es estética, la dijo ella: *«pasa de ser random a skill»*. Una
pala corta perdona menos, y arriba **drenar no cuesta vida, cuesta la caza**
(tanda 0g). O sea:

> **El hueco entre palas de arriba ES el reloj de la caza.** Los 20 s son el
> techo; el suelo lo pone tu mano.

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

**La medida que cierra la geometría de arriba**, y sustituye a "el hueco será de
X px":

> Un jugador que solo aporrea drena arriba en **3-4 s**. Un jugador bueno llega
> al techo de 20. Hoy son **5,2 s de media y 52 de 60 acaban drenando, ninguna
> por tiempo**: la brecha no existe.

Se corre con el medidor de la tanda 0g, que ya sabe puntuar la caza.

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
