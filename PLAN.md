# PLAN.md — TILT OS

Hoja de ruta. Cada fase tiene un **criterio de salida**: hasta que no se
cumpla, no se pasa a la siguiente. La regla evita el fallo clásico de
acumular sistemas a medias sobre un núcleo que aún no divierte.

*Revisión 2: la mesa grande y la pantalla completa se adelantan, porque
ajustar la sensación sobre una mesa que se va a rehacer es trabajo perdido.*

---

## Fase 0 — Física y combate · HECHA

Mesa, flippers, bola, bumpers, targets. Daño en vivo, multiplicador de
combo, vida del enemigo. Suelo y adornos. Animaciones básicas.

---

## Fase 1 — La mesa grande y la pantalla completa

### Resolución

- **Base 640×360**, escalado por enteros: ×2 = 720p, ×3 = 1080p, ×4 = 1440p
- Nunca escala fraccionaria: rompe la rejilla de píxeles
- La mesa mantiene **400 de ancho** (la física está ajustada a esa anchura
  y el hueco entre palas depende de ella)
- El alto crece a **1200-1400**
- Los ~240 px sobrantes a los lados son el escritorio de TILT OS

### Cámara vertical

Cuatro reglas, todas obligatorias:

1. **Nunca persigue a una bola que cae.** Si la bola desciende, la cámara
   se adelanta. Perder los flippers de vista al bajar la bola es
   injugable.
2. **Ancla inferior.** Por debajo de una línea de seguridad la cámara se
   fija abajo y no se mueve. El tercio de los flippers es intocable.
3. **Movimiento en píxeles enteros.** Posición fraccionaria = toda la mesa
   hirviendo.
4. **Zona muerta central**, o la cámara tiembla con cada rebote.

### Elementos nuevos de mesa

- **Rampas y túneles: son curvas, no física.** La bola se desengancha del
  cuerpo físico al entrar, recorre un spline a la velocidad de entrada, se
  dibuja por encima de la mesa, y al salir vuelve a la física con la
  velocidad tangente. Determinista y sin atascos. Construirlas con paredes
  y simularlas es el error que hunde los pinballs 2D.
- **Agujeros y platillos: capturan.** La bola desaparece, hay una pausa, y
  sale con un impulso fijo. Esa pausa es de las mejores sensaciones del
  pinball.
- **Carriles de retorno** en la zona superior que devuelven la bola al
  campo por sitios distintos.

**Criterio de salida:** la bola sube por una rampa, desaparece de vista, y
sabes dónde va a salir. La cámara nunca te deja sin ver los flippers.

### Remates pendientes

Pequeños, pero bloquean poder probar la fase:

- **El HUD tapa la bola en lo alto de la órbita.** Apaño provisional ya, no
  esperar a la Fase 5: si no se ve la bola, la órbita no se puede jugar.
- **Oscurecer los laterales del escritorio durante el combate.** Cielo azul
  y hierba verde flanqueando una mesa casi negra se llevan el ojo justo
  cuando hay que seguir una bola pequeña por el centro.
- **Más recorridos en la zona alta.** Ahora solo hay la órbita. Con el
  sistema de splines ya montado, añadir dos o tres carriles de retorno que
  devuelvan la bola por sitios distintos es barato.

---

## Fase 2 — Sensación · CASI HECHA

Hechos ya: hitstop de 70 ms, sacudida en píxeles enteros, girador con ocho
rotaciones pregeneradas, respiración en pasos de píxel entero.

Queda:

- **Sonido.** Generarlo por código con un script de Python (numpy → wav),
  no a mano con jsfxr: los sonidos de arcade son ondas simples, y así se
  reajustan cambiando un número en vez de rehaciéndolos. Hacen falta:
  bumper, target, flipper, entrada y salida de rampa, captura del
  platillo, subida de multiplicador, drenaje, muerte del enemigo.
- Efectos de impacto que falten: onda, polvo, chispas

**Criterio de salida:** golpear un bumper da ganas de volver a golpearlo.
Si alguien coge el teclado y juega dos minutos sin que le expliques nada,
está.

---

## Fase 3 — Que la mesa tenga decisiones

El orden va al revés de como lo escribí primero: el reloj antes que los
tiros, porque dos de los seis tiros no pueden tener identidad hasta que
exista una recompensa que no sea daño.

### 3A — El reloj del enemigo

`DISEÑO.md` §2. Contador visible que carga mientras juegas y pega cuando
llega, drenes o no.

Es la pieza que sostiene todo lo demás: mueve la presión fuera del drenaje,
permite premiar al que aguanta la bola sin volverlo invulnerable, arregla el
balance sin inflar barras de vida, y desbloquea recompensas que no son daño
(frenar el reloj, retrasarlo, robarle carga).

**Criterio de salida:** un combate se siente como una carrera. Un jugador
bueno gana con vida de sobra; uno malo se queda sin vida.

### 3B — Identidad de los tiros

`DISEÑO.md` §4. Los seis tiros dan cosas distintas, y cuanto más difícil el
tiro, más concentrada la recompensa.

**La regla de los bucles.** Un bucle que exige control del jugador en cada
vuelta es bueno: eso es el eje de build "golpe único". Un bucle que se
sostiene solo, sin que las palas participen, está roto. La diferencia no es
que haya bucle, es quién lo mantiene.

**Criterio de salida:** Daniel va a por un tiro concreto en vez de caer en
ellos de rebote, y distingue por el oído qué acaba de conseguir.

### 3C — El mapa del run

Nodos con ramas, secuencia de combates, vida que no se cura entre ellos,
derrota y victoria de run.

**Criterio de salida:** puedes perder en el cuarto combate y querer volver a
intentarlo.

---

## Fase 4 — Reliquias

**Quince**, no sesenta.

- Ganchos: al golpear, al drenar, al empezar bola, al matar, al entrar en
  rampa
- Elección de tres tras cada combate
- Modifican efectos y números, **nunca geometría ni tamaño de bola**

Las quince deben cubrir familias distintas: daño plano, daño condicional,
multiplicador, defensa, economía, y una que cambie cómo juegas.

**Criterio de salida:** dos partidas con reliquias distintas se sienten
como partidas distintas.

---

## Fase 5 — La cáscara TILT OS

Ahora el juego se mete dentro del sistema operativo, y de paso se llena la
pantalla.

- Escritorio, fondo, barra de tareas, botón Inicio
- La mesa vive en una ventana; el resto son otras ventanas
- Reliquias como iconos del escritorio con tooltip amarillo
- Enemigo en su propia ventana, mapa como explorador de carpetas
- Derrota como pantalla azul TILT con volcado de error

Todo por código. Nada de sprites de interfaz.

**Criterio de salida:** quien vea una captura entiende la broma sin que se
la expliquen.

---

## Fase 6 — Contenido

Lo más largo. Rellenar moldes que ya funcionan.

- De 15 a 50-60 reliquias
- Enemigos con comportamientos distintos, no solo más vida
- Los tres jefes con sus fases
- Dos o tres mesas más **diseñadas a mano**, como biomas
- Eventos y tienda

---

## Fase 7 — Meta-progresión

**Solo si las fases anteriores son divertidas.** Si el juego no engancha en
la primera partida, desbloquear cosas no lo arregla: esconde el problema
detrás de una barra de progreso.

---

## Fase 8 — Publicación

Sonido y música definitivos, menús, opciones, guardado, exportación a
Windows y web, página de itch.io.

---

## Decisiones cerradas

Reabrirlas cuesta más de lo que aportan.

- **Mesas diseñadas a mano, nunca procedurales.** El layout es artesanía:
  cada ángulo condiciona todos los rebotes. Lo que varía entre partidas son
  reliquias, enemigos y modificadores, no la geometría.
- **Mantener el flipper sigue siendo mantener el flipper.** Es una técnica
  de juego fundamental. No se le asigna ninguna habilidad a ese gesto.
- **La bola es el bloque de stats del jugador, pero solo en efectos.**
  Nunca en tamaño ni masa: descuadra el hueco entre palas.
- **Los enemigos normales viven fuera del campo de juego.** Un jefe sí
  puede ocupar la mesa como obstáculo físico.
- **El daño se aplica al golpear, no al drenar.**
- **No hay cuenta de bolas.** Hay vida, y drenar te cuesta vida.
- **Las rampas son curvas, no física simulada.**
- **Escalado por enteros siempre.**

---

## Cómo trabajar esto

**Una fase por sesión, y commit al cerrar cada una.** No mezclar fases: si
en mitad de la 3 aparece una idea buena de la 6, se anota y se sigue.

**El criterio de salida se comprueba jugando, no leyendo el código.**

**Cuando algo dependa del tacto, se expone como parámetro y se pregunta.**

### Qué modelo para qué

El reparto va por naturaleza del trabajo, no por fase.

**Modelo fuerte** para todo lo que toque `sim/` —física, cámara, splines,
balance—, para depurar cuando algo se siente mal sin dar error, y para
cualquier cosa donde "está hecho" sea un juicio y no una condición
comprobable.

**Modelo más barato** para trabajo con forma conocida: rellenar las 45
reliquias que falten una vez definido el sistema, los JSON de enemigos,
conectar sprites, refactors con pruebas que ya pasan.

Reservar el modelo fuerte para `sim/` y depuración estira mucho más el
límite de uso que gastarlo colocando sprites.
