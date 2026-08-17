# DISEÑO.md — CASCABEL

Diseño de la capa roguelike. La capa de sensación —física, geometría,
*juice*— no se diseña aquí: se descubre jugando y vive en `PLAN.md`.

*Revisión 4: el juego se llama **Cascabel**. Un cascabel es una esfera con
algo vivo dentro que suena al moverse: es literalmente el personaje. Entra
la estructura de tres capas, y la cáscara de sistema operativo vuelve, pero
en pixelart y sin gestor de ventanas.*

---

## 1. El pilar

**La mesa es un menú de tiros.**

Cada tiro da algo distinto. Tu build decide cuáles te compensan. Los
enemigos deciden cuáles te dejan.

Si todos los tiros dan lo mismo, el jugador no elige nada, solo sobrevive, y
las reliquias se vuelven bonificaciones pasivas. Toda mecánica se juzga
contra esto: si no hace que un tiro sea más o menos deseable que otro, sobra.

---

## 2. El skill se recompensa

**Aguantar la bola es lo mejor que puede hacer el jugador.**

Por eso la presión no vive en el drenaje. **El enemigo ataca por reloj**: un
contador visible que carga mientras juegas y pega cuando llega, drenes o no.

- Aguantar sigue siendo lo mejor: es tiempo pegando
- Pero no es gratis: el reloj corre igual
- El combate es una carrera
- Drenar es un tropiezo, no una catástrofe: pierdes el multiplicador y le
  regalas un golpe

Un jugador excelente gana con vida de sobra. Uno malo se queda sin vida.
**El skill se paga en margen, no en inmortalidad.**

---

## 3. La premisa

**No es un modo historia.** Es un marco que se cuenta por mensajes de error,
archivos de registro abribles en el escritorio y el sistema degradándose
acto a acto. Cero cinemáticas, cero diálogo, cero coste.

Alguien intentó convertir una máquina de pinball en un juego de rol y no lo
terminó. Dejó la mazmorra a medio programar sobre el cableado de la máquina
y se fue. El sistema lleva desde entonces intentando ejecutar un juego que
no existe del todo.

**El jugador es un error de ese intento.** El programa necesitaba un
protagonista y no llegó a tener uno, así que el gestor de excepciones cogió
lo primero vivo que encontró y lo selló dentro de lo único que la máquina
sabe manejar: una bola. En el registro aparece como `cascabel.exe`. Nadie le
puso ese nombre; es el nombre del archivo.

**Las palas son la única parte real.** Son hardware atornillado a la máquina.
La mazmorra es software, los monstruos son procesos, el botín son fragmentos
de código sin usar. Por eso las palas son lo único que se controla de verdad
y por eso mejorarlas importa.

**Drenar no es morir: es que el sistema captura el fallo y reinicia el
nivel.** Por eso se repite, y por eso se conservan los desbloqueos: son
piezas rescatadas de la memoria antes de que el reinicio las borre.

**Perder del todo es TILT**, que es a la vez lo que hacen las máquinas de
pinball cuando alguien las empuja y una pantalla de fallo del sistema.

Cada pieza del diseño ya decidido encaja aquí sin forzarla: el bucle
roguelike es un reinicio de proceso, los desbloqueos son carroñeo, y la
cáscara es la máquina intentando gestionar un proceso que no puede matar.

---

## 4. El personaje y la cáscara

**La bola es una criatura, no un objeto.** Eso da a quién mejorar, de quién
tirar en las reliquias y a qué ponerle skins. La criatura no habla nunca.

**En la mesa se ve la CÁSCARA, y solo la cáscara.** Gira con ocho o doce
rotaciones pregeneradas por código y ajustadas a rejilla, elegidas según la
distancia recorrida. Un ciclo de rodadura con fotogramas NO sirve: la bola cambia
de dirección constantemente y un ciclo solo vale para un sentido. Y las cáscaras
se dibujan sin arriba ni abajo —sin pies, sin asa— porque van a rotar.

**La criatura NO se dibuja sobre la bola.** *Corregido ago-2026, y es aritmética,
no gusto.* Aquí ponía "dos capas, como una bola de hámster: la cáscara rueda, la
criatura no". Pero la bola mide **18 px** en la mesa (`radio_bola = 9.0`), y la
ranura de las nueve cáscaras baja de 48×6 a **13,5 × 1,7 px** a ese tamaño. Un
sistema de dos capas ahí no devuelve ni dos píxeles. Se probó perforando la
ranura y componiendo ojos debajo: a 8× queda bien y **a tamaño de mesa no
existe**.

El reparto que sí funciona:

| Dónde | Qué se ve | Tamaño |
|---|---|---|
| **La mesa** | la cáscara rodando; identifica por color y patrón | 18 px |
| **La interfaz** — Preparación, `RECUPERADO/`, tooltips, la captura | cáscara y criatura compuestas en un panel | 64 px |
| **La caza**, en la planta alta | la criatura suelta, sin cáscara | 64 px |

Las **81 combinaciones** de `PROPÓSITO.md` §3 siguen en pie y pasan a ser **de
interfaz**: se elige cáscara y criatura por separado y se componen donde hay
sitio, no metiendo nada por una ranura de seis píxeles.

Y de ahí sale un argumento a favor de la caza que no estaba escrito: **es el
único momento del juego en que ves lo que coleccionas a un tamaño en el que se
lee.**

**La mazmorra corre dentro de un sistema operativo viejo.** No se explica ni
se justifica; es el marco visual. Cada elemento del sistema hace trabajo de
juego, no decora:

- Reliquias = iconos del escritorio, con tooltip
- Mapa del run = ventana de explorador
- Combate = una ventana
- El reloj del enemigo = un diálogo de progreso cuyo botón de cerrar no
  cierra, y cuyo "tiempo restante" puede mentir como mentían los de verdad
- Derrota = pantalla azul de **TILT**, que además es término de pinball real
- Multibola = varias ventanas abiertas

**Toda la cáscara va en pixelart**, misma rejilla y misma paleta que el
resto. Se construye con marcos de nueve trozos que se estiran a cualquier
tamaño. La versión anterior —degradados y biselados dibujados por código en
resolución nativa— queda descartada: era más cara y peleaba con el arte.

**Aviso legal:** nada de assets reales de Microsoft. Ni Bliss, ni el logo,
ni Luna, ni los iconos. Reconocible sí, calcado no.

---

## 5. Las tres capas

Cada sistema modifica una capa. Amontonarlos en la misma es lo que hace que
un juego se sienta desordenado.

| Capa | Cuándo | Qué eliges |
|---|---|---|
| **Preparación** | Antes del run | Bola, flippers, mesa |
| **Progresión** | Durante el run | Reliquias, chatarra, tienda |
| **Desbloqueo** | Entre runs | Bolas, flippers, mesas, skins |

### Preparación: tres elecciones que definen el run

- **La bola** — tu personaje. Efectos propios: fuego encadena, piedra pega
  concentrado, hielo ralentiza el reloj del enemigo.
- **Los flippers** — tus manos. Alcance, potencia, ángulo de la cuna. Unos
  cortos y rápidos juegan distinto de unos largos y lentos.
- **La mesa** — el terreno. Gravedad, rebote, velocidad.

**La mesa se elige antes, nunca a mitad.** Elegir gravedad baja es elegir
otro juego y adaptarte; que una reliquia te la cambie en el combate siete es
castigarte por haber aprendido a jugar. Las reliquias modifican efectos y
números, **jamás la física base**.

### Desbloqueo: lo que cazas no sirve para este run

**Los monstruos de la zona alta sueltan material de desbloqueo, no poder de
run.**

Esa es la pieza que sostiene todo lo demás:

- **No rompe la escasez.** Farmear no te hace ganar esta partida, así que la
  tienda y las reliquias siguen siendo decisiones.
- **Da una decisión que casi ningún roguelike tiene explícita:** ¿juego para
  ganar este run, o para desbloquear cosas? Subir cuesta tiempo de reloj, o
  sea vida.
- **Y le da sentido a la zona alta**, que hasta ahora era un pasillo.

El modo dura un tiempo limitado y **el reloj del enemigo sigue corriendo
mientras estás arriba**. Sin eso, cazar sería gratis.

Las skins salen de aquí y no afectan a nada: son la recompensa de coleccionar.

**Qué se caza, y está entero en `CAZA.md` (ago-2026):** las nueve criaturas de
`assets/criaturas_64/`. Cada una que traes viva deja de estar corrupta en
`RECUPERADO/` y se puede meter en tu cascabel en Preparación — nueve cáscaras
por nueve criaturas son 81 cascabeles con el arte ya hecho. La captura no resta
vida, sube MIEDO; capturar acaba la caza; y **hay que bajar la criatura viva
por el regreso o se pierde**.

---

## 6. Los tres relojes

| Escala | Duración | Qué decides |
|---|---|---|
| **La bola** | ~15 s | Qué tiro intentas ahora |
| **El combate** | 1-2 min | Ir a por el tiro grande o acumular seguro |
| **El run** | 30-40 min | Qué build montas y qué camino tomas |

---

## 7. Los tiros de la mesa

| Tiro | Dificultad | Qué da |
|---|---|---|
| Racimo de bumpers | Fácil | Multiplicador, muchos golpes pequeños |
| Banco de targets | Media | Daño plano, se agota y se resetea |
| Órbita | Difícil | Salto de multiplicador de golpe |
| Cañón | Media | Daño grande, retorno difícil |
| Carril de retorno | Media | Devuelve la bola a la pala: encadenar |
| Platillo | Difícil | Atrasa el reloj del enemigo |
| Umbral alto | Difícil | Abre el modo de caza |

**Cuanto más difícil el tiro, más concentrada la recompensa.**

### Varían en acceso, no solo en premio

| Tipo | Cómo se aborda |
|---|---|
| Arco vertical | Tiro de frente hacia arriba |
| Carril pegado a pared | Se roza de refilón subiendo |
| Agujero en el suelo | Caes dentro, no lo apuntas |
| Boca alta | Solo llega un tiro muy limpio |

**La bola se dibuja detrás de la boca al entrar**, o no se lee como agujero.

**La regla de los bucles:** uno que exige control del jugador en cada vuelta
es bueno; uno que se sostiene solo está roto.

---

## 8. Los ejes de build

1. **Combo** — el multiplicador escala más. Frágil: drenar duele.
2. **Golpe único** — un tiro pega enorme. Pescas ese tiro una y otra vez.
3. **Supervivencia** — protección de outlanes, vida, curación.
4. **Escalado** — más fuerte a lo largo del run que dentro de la bola.
5. **Caos** — multibola, bolas extra, aleatoriedad.

**Prueba:** dos partidas con ejes distintos deben sentirse como juegos
distintos, no como el mismo con números más grandes.

---

## 9. Recursos

| Recurso | Vive | Se pierde |
|---|---|---|
| **Vida** | El run | Al drenar y al llegar el reloj. No se cura sola |
| **Multiplicador** | Una bola | Al drenar |
| **Chatarra** | El run | En la tienda |
| **Reliquias** | El run | Nunca |
| **Material de caza** | Para siempre | Al gastarlo en desbloqueos |

---

## 10. Misiones: de dónde salen las reliquias

**Las reliquias se ganan jugando la mesa, no por ganar el combate.** La
referencia es doble y las dos son de pinball de verdad: el display del 3D
Pinball del XP, que SIEMPRE dice qué toca ahora y te asciende de rango al
completar una misión; y Pokémon Pinball, donde lo que te llevas lo cazas tú
dando bolazos, no eligiéndolo en un menú.

Cada combate trae una **escalera de tres misiones**: común, rara y arcana. La
tele las anuncia una a una. Completar la común abre la rara, y así. Cada misión
paga una reliquia **de su misma rareza**.

Eso hace tres cosas a la vez:

- **El margen por habilidad se paga en objetos**, no en vida (§2). Quien aguanta
  la bola sube tres escalones en un combate; quien no, uno.
- **Un combate largo deja de ser un saco.** Sin misión, un enemigo de tres
  minutos es el mismo minuto tres veces. Con ella hay un siguiente escalón
  siempre visible.
- **Ganar el combate no da objeto**: te deja pasar. Se acabó la parada al final.

**Una misión no sube de rareza pidiendo más de lo mismo**, sino pidiendo lo que
cuesta control: tiros difíciles, en ORDEN, y sin drenar. Cuatro bumpers más no
es más difícil, es más largo.

**Las rarezas: común, rara, arcana.** Y la rareza **no es cuánto sube un
número, es cuánto cambia la partida**: una que da +12 de daño a los targets es
común aunque sume mucho; una que hace que el racimo cobre del multiplicador es
arcana aunque el número sea pequeño, porque te cambia a qué tiro vas, que es el
pilar (§1).

---

## 10b. Ganchos de reliquia

Las reliquias se diseñan contra esta rejilla, no una a una.

Al golpear un bumper · al golpear un target o agotar un banco · al completar
un recorrido concreto · al subir de tramo · al empezar la bola · al drenar ·
al matar · al entrar en combate · al cazar en la zona alta · pasivos
condicionales.

Las primeras cubren los cinco ejes y al menos seis ganchos. Nada de
variantes de "+2 de daño".

**Cuántas.** El plan decía quince y se quedó corto: con tres ofrecidas por
combate y doce combates ves unas treinta y seis, o sea que con quince las veías
todas y dos runs se parecían. La cifra que importa no es cuántas hay, es
cuántas NO ves. Van cuarenta y cinco, nueve por eje.

---

## 11. Enemigos que cambian cómo juegas

Uno con más vida no es un enemigo nuevo. Cada uno altera qué tiro compensa:

- **Bloquea un recorrido** hasta que le pegas por otro sitio
- **Se cura** si no le tocas en N segundos: prohíbe jugar seguro
- **Refleja** si repites tiro: obliga a variar
- **Blindaje** que solo rompe el daño concentrado: mata al build de combo
- **Castiga el multiplicador alto**: obliga a gastarlo
- **Acelera su reloj** cuando subes a cazar: castiga farmear

---

## 12. Estructura del run

Tres actos, doce a quince combates, treinta a cuarenta minutos.

```
Acto I    combate → combate → élite → tienda → combate → JEFE
Acto II   igual, con enemigos que responden a los ejes
Acto III  más corto y más duro
```

La vida no se cura entre combates. El descanso es la única cura y compite
con mejorar.

---

## 13. Lo que este juego NO es

- **No es un simulador de pinball.** Ni tabla de puntuaciones ni misiones de
  mesa.
- **No hay mesas procedurales.** Tres o cuatro a mano, como biomas.
- **No hay modo historia.** La criatura no habla. Ambientación por arte y
  por enemigos, no por guion.
- **No hay gestor de ventanas.** La cáscara son paneles enmarcados en
  posiciones fijas que parecen ventanas. Nada de arrastrar, redimensionar,
  foco, orden de apilado ni minimizar. Esa era la parte cara y no aporta
  nada: nadie va a querer mover el mapa a otra esquina.
- **No hay más de un jugador.**
- **La meta-progresión no se toca hasta que el run sea divertido sin ella.**

---

## 14. Preguntas abiertas

- ¿Cuánto dura la carga del reloj? Es el dial entre carrera y paseo.
- ¿La chatarra se gana por daño, por tiro difícil o por combate ganado? Lo
  que premies es lo que la gente jugará.
- ¿Cuántas bolas, flippers y mesas al empezar? Pocas y distintas antes que
  muchas parecidas.
