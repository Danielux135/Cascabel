# PLAN.md — CASCABEL

Hoja de ruta. Cada fase tiene un **criterio de salida**: hasta que no se
cumpla, no se pasa a la siguiente. La regla evita el fallo clásico de
acumular sistemas a medias sobre un núcleo que aún no divierte.

*Revisión 2: la mesa grande y la pantalla completa se adelantan, porque
ajustar la sensación sobre una mesa que se va a rehacer es trabajo perdido.*

*Revisión 3: el juego se llama **Cascabel**. El sistema operativo falso
sigue siendo la cáscara, pero ya no da nombre al juego. La Fase 5 se
reescribe entera: la cáscara pasa a pixelart con marcos de nueve trozos y
sin gestor de ventanas.*

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
- Los ~240 px sobrantes a los lados son el escritorio de la cáscara

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

## Fase 4 — Reliquias · ESCRITA, SIN PROBAR

**Cuarenta y cinco**, nueve por eje.

*Revisión: aquí ponía "quince, no sesenta", y quince se quedaban cortas por una
razón de aritmética, no de gusto. Con tres ofrecidas por combate y doce combates
ves unas treinta y seis: con quince las veías TODAS y la segunda partida traía lo
mismo que la primera. **La cifra que importa no es cuántas hay, es cuántas no
ves.** Con cuarenta y cinco, un run enseña la mitad del cajón.*

*Lo que sí sigue en pie del "no sesenta": no valen por ser muchas. Cada una tiene
que caber en un gancho que ya existe, y si pide un `if` nuevo en `Combate` es que
falta un gancho.*

*Escritas las cuarenta y cinco, nueve por eje y once ganchos. Falta lo único que
cierra la fase: jugarlas. El criterio de salida no se lee, se juega.*

- Ganchos: al golpear, al drenar, al empezar bola, al matar, al entrar en
  rampa
- Elección de tres tras cada combate
- Modifican efectos y números, **nunca geometría ni tamaño de bola**

Deben cubrir familias distintas: daño plano, daño condicional, multiplicador,
defensa, economía, y varias que cambien cómo juegas.

**Criterio de salida:** dos partidas con reliquias distintas se sienten
como partidas distintas.

---

## Fase 5 — La cáscara · PRIMERA PASADA HECHA

Ahora el juego se mete dentro del sistema operativo falso, y de paso se
llena la pantalla.

*Reescrita: la cáscara ya no se dibuja por código. Va en pixelart, con
marcos de nueve trozos, y sin gestor de ventanas. Eso cambia el trabajo de
sitio: lo que hacía falta era código de interfaz, y ahora hacen falta
**assets** y **un renderizador de nueve trozos**.*

### Por qué el cambio

Dibujar degradados y biselados por código en resolución nativa era más caro
que dibujarlos una vez, y encima peleaba con el arte: un marco suave
alrededor de píxeles duros no se lee como el mismo juego. Y el gestor de
ventanas —arrastrar, redimensionar, foco, orden de apilado, minimizar— era
la parte más cara de todas y no aporta nada: nadie va a querer mover el mapa
a otra esquina.

### El renderizador de nueve trozos

La pieza técnica de la fase, y es pequeña. Un marco es un PNG dividido en
nueve regiones: cuatro esquinas que no se estiran, cuatro bordes que se
repiten en un eje y un centro que se repite en los dos.

- **Se repite (*tile*), no se estira.** Estirar un pixelart lo destruye.
- **Los tamaños de panel son múltiplos de la unidad de repetición**, o el
  último trozo sale cortado.
- **Todo en píxeles enteros de la base 640×360**, como el resto.
- Un solo renderizador sirve para paneles, botones, barra de tareas,
  tooltips y cuadros de diálogo: solo cambia el atlas.

### Los assets que hacen falta

Se procesan con `procesar.py` como todo lo demás, y llevan la paleta del
proyecto.

- Marco de panel: normal y activo
- Barra de título con su tira de botones (que no hacen nada, son decorado)
- Botones: reposo, encima, pulsado
- Marco de tooltip amarillo
- Barra de tareas y botón Inicio
- Barra de progreso, para el reloj del enemigo
- Fondo de la pantalla azul de TILT

### Qué se monta con eso

Paneles fijos, cada uno en su sitio, que parecen ventanas y no se mueven:

- Escritorio, fondo, barra de tareas, botón Inicio
- La mesa en el panel central; el resto alrededor
- Reliquias como iconos del escritorio con tooltip amarillo
- Enemigo en su panel, con su reloj como diálogo de progreso
- Mapa como panel de explorador de carpetas
- Derrota como pantalla azul **TILT** con volcado de error

Arrastra dos apaños de la Fase 1 que se resuelven aquí: el HUD que tapa la
bola en lo alto de la órbita y los laterales del escritorio apagados a mano.

*Hecho en la primera pasada: el renderizador de nueve trozos con su prueba, el
escritorio, la barra de tareas con botón Inicio y reloj, el marco alrededor de
la mesa, las reliquias como iconos con tooltip amarillo, y TILT como pantalla
azul con volcado. Arrastraba dos apaños de la Fase 1 y **se ha resuelto uno**:
los laterales ya no son un degradado a mano, son escritorio con contenido.*

*Segunda pasada: la fuente pasó a ser propia y pixelart (`fuente.py`), y los
cinco marcos pasaron de dibujarse por código (biselados planos) a generarse
igual. Después, Daniel generó arte de verdad con IA siguiendo
`assets/prompts_cascara.md` y esta sesión se recortó e integró: ventana, barra
de título y barra de tareas (recortadas de las hojas y validadas con una
previsualización de mosaico antes de tocar el repo), botón Inicio con el
cascabel de logo, botones min/max/cerrar, nueve iconos decorativos, y tres
fondos de escritorio que cambian por acto. Trampa real de esta pasada: el
primer recorte dejaba el fondo magenta de las hojas de IA sin volver
transparente, y salía como motas rosas en las esquinas del marco y detrás de
los iconos — está en `CLAUDE.md`, "Trampas".*

*Tercera pasada, y con ella la fase queda ESCRITA ENTERA: el HUD se fue de
encima de la mesa a tres paneles de la banda derecha (`enemigo.exe`,
`jugador.sys`, `ayuda.hlp`), el enemigo dejó el tablero y vive en el suyo, el
mapa pasó a ser una ventana de explorador con barra de menú, panel de detalles
y barra de estado, y los fondos bugueados se conectaron como variantes al azar
por acto. Se conectó también el arte que estaba recortado y sin usar: puntero,
barra de progreso y marco de diálogo.*

*Y salió una avería de las de no ver: la cáscara va en la capa −10 y el fondo
negro del tablero es opaco, así que **la barra de título de la ventana de la
mesa no se veía nunca** y la barra de tareas quedaba partida por la mitad. Está
en `CLAUDE.md`, "Trampas". Lo que cruza la columna de la mesa va ahora en
`NodoCascaraFrente`, en la capa 5.*

*La decisión de tacto de la pasada, que la tomó Daniel: **el reloj del enemigo
NO se va a un panel.** Se queda pegado a la mesa, dentro de la barra de título
de su ventana, como barra de progreso. Cuesta cero píxeles de campo y sigue en
la línea de visión, que era la razón de tenerlo en el HUD.*

*Queda sin generar la segunda tanda de prompts de bandeja de sistema (reloj con
sprite propio, separador, altavoz, icono de sin-red) — sección 2 de
`assets/prompts_cascara.md`. Y queda lo único que cierra la fase de verdad:
jugarla.*

**Criterio de salida:** quien vea una captura entiende la broma sin que se
la expliquen, y la cáscara y la mesa se leen como el mismo juego.

---

## Fase 6 — Contenido

Lo más largo. Rellenar moldes que ya funcionan.

- De 45 a 70-80 reliquias, y arte para las que no lo tienen
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

## Fase 1c — Capas de altura · EL SISTEMA, HECHO Y MEDIDO

*Escrita en agosto de 2026, después de que la primera planta alta saliera mal
dos veces. **El sistema está construido (tanda 0h, 16-ago-2026); la geometría
que lo use es la 1d.***

La mesa tiene dos plantas y las dos son mesa jugable. Lo que falta —y lo que
Daniel pidió con estas palabras— son **capas de altura, como plataformas, y
físicas de rampas que no llegan**.

Hoy la mesa es plana: todo colisiona con todo y una rampa es un spline por el que
la bola pasa entera. Con capas, la bola tiene un NIVEL, un colisionador solo
existe en el suyo, y las cosas que hacen que un pinball se lea en tres
dimensiones salen casi solas:

| Pieza | Qué es con capas |
|---|---|
| **Plataforma** | una región elevada con borde. Salirte del borde es caer a la capa de abajo |
| **Túnel** | el mismo spline de siempre, pero por DEBAJO del tablero: se dibuja oscuro y la bola desaparece |
| **Rampa que no llega** | `PROPÓSITO.md` §6 ya lo tiene escrito: entras por debajo de la velocidad de escape y la bola corona a medias. Con capas, además, **se cae de la rampa al tablero**, que es lo que se siente de verdad |
| **Cruces** | una rampa puede pasar por encima de otra sin tocarla, que hoy es imposible |

**Y la altura de la mesa puede crecer.** Los 1300 px no son un invariante: si las
capas piden más, se sube. Lo que no se puede tocar sin volver a medir todo es la
ANCHURA (400), porque de ella cuelga el hueco entre palas.

**Orden, y lo decidió Daniel:** primero el SISTEMA —nivel en la bola,
colisionadores por capa, caída de una capa a otra, velocidad de escape en las
rampas—, medido y en verde. La geometría se rediseña encima, después. Es lo único
que no se puede hacer al revés.

**Criterio de salida:** una rampa fallada te tira al tablero y sabes por qué; y
dos recorridos se cruzan sin tocarse.

### Lo que quedó construido

| Pieza | Dónde vive | Apagado por defecto |
|---|---|---|
| Nivel de altura de la bola | `Bola.capa` | toda bola nace en `CAPA_TABLERO` |
| Máscara por capa | `Colisionador.capas` y `Flipper.capas` | `TODAS`, o sea la mesa plana |
| Plataforma con borde | `sim/plataforma.gd`, `Mesa.plataformas` | la lista está VACÍA |
| Caída de una capa a otra | señal `Mesa.bola_cayo` | no salta si nadie sube |
| Velocidad de escape | `Rampa.velocidad_escape` | a 0 = la rampa determinista de siempre |
| Tubo o carril | `Rampa.abierta` | `false` |
| Túnel | `Rampa.subterranea` | `false` |
| Cruces | `Rampa.capa_entrada` / `capa_salida` | las dos en el tablero |

**Todo entra apagado, y eso es la mitad del trabajo.** La medida que lo cierra
está en `tests/medir_capas.gd`: la mesa de hoy da los mismos números al decimal
—8,142 s de duración de bola, 120 golpes, 3,09 golpes de bumper por entrada al
racimo, misma huella— antes y después de escribir el sistema entero.

La velocidad de escape no es una escalera de tres casos, es energía:

    v(recorrido)² = v_entrada² − (velocidad_escape · 0,6)² · recorrido / largo

y las tres bandas del diseño salen solas de ahí. La velocidad se calcula desde
la distancia en vez de acumularse, así que subir y volver a bajar devuelve la
velocidad de entrada exacta y el recorrido sigue siendo determinista.

**Lo que NO lleva:** la barra de CARGA de `PROPÓSITO.md` §6 (duplicar daño
cuatro segundos hay que pasarlo por `medir_daniel.gd` antes, y ese medidor
todavía no sabe jugar con N bolas), y ningún sonido para `bola_cayo` ni para
`rampa_fallada` — hace falta generarlos en `sonidos.py`, y meter una clave
nueva sin su wav pone la batería en rojo.

---

## Fase 1d — La planta alta, rediseñada

**LA PLANTA ALTA DE HOY NO VALE Y HAY QUE REHACERLA.** Está montada como una
COPIA de la de abajo —misma zona de palas, mismos slingshots, mismos carriles— y
Daniel la rechazó por eso: *"el mapa de arriba no puede ser una réplica, ha de
sentirse diferente"*.

Lo que pidió, con sus palabras: **"diferente diseño, bumpers, zonas,
plataformas, túneles"**.

Va DESPUÉS de las capas, porque plataformas y túneles son capas.

Y arrastra lo que sigue sin usarse: **los márgenes de los lados**. Medido con la
mesa de hoy, las dos franjas de 20 px de fuera de las bandas solo están ocupadas
por tramos —el umbral sube por la derecha de y=730 a 258, el regreso baja por la
izquierda de 672 a 1030— y queda **libre la izquierda de y=150 a 670 y de 1030
abajo, y la derecha de 150 a 258 y de 730 abajo**. Son unos 1.470 px de carril
muerto, más de lo que hay usado. Una bola mide 18 y la franja 20: es carril
exacto, no margen.

**Criterio de salida:** alguien que juegue las dos plantas las distingue por cómo
se juegan, no por cómo se ven.

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
- **La mesa tiene DOS PLANTAS**, y no se comunican por gravedad: la bola sube
  643 px por sus medios y una caída libre desde arriba llega a las palas a
  1500 px/s, o sea 67 ms. Se sube y se baja por recorrido.
- **La planta alta NO puede ser una réplica de la de abajo.** La de hoy lo es y
  está pendiente de rehacer (Fase 1d).
- **El ALTO de la mesa no es invariante; el ANCHO sí.** 400 px de ancho sostienen
  el hueco entre palas y toda la física medida. Los 1300 de alto se pueden subir
  si las capas lo piden.
- **Las franjas de 20 px de fuera de las bandas son CARRIL, no margen.** La bola
  mide 18.
- **Las rampas son curvas, no física simulada.**
- **La cáscara va en pixelart con marcos de nueve trozos**, no dibujada por
  código.
- **No hay gestor de ventanas.** Paneles fijos que parecen ventanas.
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
