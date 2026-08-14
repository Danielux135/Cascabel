# ESTADO.md — CASCABEL

Estado vivo. Se lee al empezar la sesión y se actualiza al terminarla.

**Regla de tamaño:** esto no es un registro de cambios. Al cerrar sesión,
resume lo tuyo en dos o tres líneas dentro de "Hecho" y borra el detalle.
Lo que merezca sobrevivir para siempre va a `CLAUDE.md`, no aquí. Si esto
pasa de una pantalla, sobra algo.

---

## PARA RETOMAR ESTO SIN CONTEXTO

Lo mínimo que hay que saber si esta conversación empieza de cero.

**Dónde estamos.** La Fase 5 (la cáscara) está **escrita entera y sin ejecutar
ni una vez**: se escribió en remoto y allí no se podía lanzar el juego.

**Y eso último ya no es verdad, que es lo que más ahorra saber:** en una sesión
remota **sí se puede lanzar Godot**. Se baja el binario de Linux de la misma
versión y se corre en la caja de la sesión:

    curl -sSL -o g.zip https://github.com/godotengine/godot/releases/download/4.7.1-stable/Godot_v4.7.1-stable_linux.x86_64.zip
    unzip -q g.zip && chmod +x Godot_v4.7.1-stable_linux.x86_64
    ./Godot_v4.7.1-stable_linux.x86_64 --headless --path <copia> --import

Con `sim/`, `data/` y `tests/` copiados y un `project.godot` sin `main_scene`
basta: los medidores no tocan `render/` ni assets. **Todo el rebalance de esta
sesión se ha medido así, ejecutando de verdad**, no calculando.

**Lo primero que hay que hacer, en este orden y antes de tocar nada:**

    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --import
    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/prueba_sim.gd

El `--import` no es opcional: los 5 fondos bugueados nuevos de `assets/shell/`
no tienen `.import`, así que hasta que se importen no existen para el juego y
**dos pruebas nuevas van a salir en rojo diciendo exactamente eso**. Si salen
en rojo después de importar, entonces sí es un fallo de verdad.

**Está todo sin commitear**, y también lo de la sesión de assets anterior. El
commit se hace cuando la batería pase, no antes.

**Ficheros nuevos de la última sesión** (`render/`): `nodo_cascara_frente.gd`,
`nodo_panel_enemigo.gd`, `nodo_cursor.gd`. Borrado: ninguno salvo un
`nodo_marco_mesa.gd` intermedio que no llegó a durar. Reescritos a fondo:
`nodo_cascara.gd`, `nodo_hud.gd`, `nodo_pantalla_mapa.gd`. Tocados:
`vista_mesa.gd`, `parametros_camara.gd`, `nodo_enemigo.gd`, `nodo_tele.gd`,
`tests/prueba_sim.gd`. **El mapa de capas está en `CLAUDE.md`** y conviene
mirarlo antes de dibujar nada.

**Las dos decisiones que pueden caerse al jugar, y las dos son reversibles en
un rato:** el reloj dentro de la barra de título (pregunta N2) y la vida en un
panel lateral en vez de encima de la mesa (pregunta N4). Si cualquiera de las
dos molesta, se deshace; no hay nada construido encima.

**El REBALANCE (tanda 1) está hecho y medido**, y lo que ha destapado cambia el
orden del plan: ver la sección de abajo. Lo que manda ahora es la **Fase 6**.

---

## Fase actual

**Rebalance hecho, y el modelo por fin reproduce a Daniel.** Lo que faltaba no
era otro número: era que **el medidor jugaba sin reliquias**. `medir_balance.gd`
juega el run entero, pero su jugador de mentira no completa misiones, así que
llega al jefe del acto 3 con la bolsa vacía. Daniel llega con once reliquias
encima. Por eso el modelo decía que se pierden 500 de 1080 en un run y Daniel
perdió 36 de 1800: **no medía un balance flojo, medía a otro jugador.**

`tests/medir_daniel.gd` (nuevo) arregla eso: el combate comparte la bolsa del
run, recibe la escalera de misiones real, tira la ruleta al completarlas, y usa
la vida de verdad en vez de vida infinita —así las reliquias condicionales se
encienden cuando les toca—. **Acaba el run con el 99 % de vida contra el 98 %
real de Daniel.** Es la primera vez que el modelo y la partida dicen lo mismo.

### Lo que dice el barrido, y es más gordo que la tabla

Primero se barrió vida × ataque, que era lo que mandaba la tanda 1. **De las 20
casillas, ninguna deja el run entre el 25 y el 60 % de vida.** El patrón es
siempre el mismo: o el enemigo no te toca (93-100 % al acabar), o te mata. No
hay banda intermedia.

La causa está medida y **ya estaba escrita como aviso en Abierto**: un enemigo
que solo tiene vida y UN ataque por reloj no puede apretar de forma continua
durante dos minutos, solo puede pegar picos. Subir el ataque hace los picos
letales; bajarlo los vuelve invisibles. **Lo que falta no es un número de
`data/enemigos.json`: son los comportamientos de la Fase 6** (`DISEÑO.md` §11).

Lo segundo que salió, al añadir la curación como tercer eje: **las reliquias de
cura devuelven más de lo que cualquier tabla puede quitar.** `rutina_de_
reparacion` daba el 8 % al matar (96 % de barra en un run) y `desfragmentacion`
un 2 % acumulativo por victoria (156 %). Eso rompe el invariante de `DISEÑO.md`
§9 —la vida no se cura entre combates— que es lo que hace que elegir rama
importe. Bajadas a un tercio, con su texto reescrito.

### Lo que se ha escrito, que es lo mejor alcanzable sin Fase 6

| Qué | Antes | Ahora |
|---|---|---|
| Vida de enemigo | 1250-3220 | **3750-9660** (×3) |
| Ataque | 9-16 | **6-11** (×0,7) |
| Curación de reliquias | — | **a un tercio** |
| Combate medio | 52 s | **137 s** (el objetivo era 120-300) |
| Vida al acabar el run | 87 % | **71 %** |
| Runs acabados de 5 | 5/5 | **3/5** |

Confirmado lanzando el medidor contra los JSON ya escritos, no calculado.

### Lo que cambió de sitio la sesión anterior

| Qué | Antes | Ahora |
|---|---|---|
| Vida, enemigo, crítico, daño de bola | franja de 70 px sobre la mesa | paneles `enemigo.exe`, `jugador.sys`, `ayuda.hlp` en la banda derecha |
| El reloj del enemigo | barra en esa misma franja | **barra de progreso dentro de la barra de título de la mesa** |
| El enemigo | dentro del campo, en y=758 | su panel, con partículas propias |
| El mapa | pantalla suelta con fondo plano | ventana de explorador: menú, ruta, detalles y barra de estado |
| `alto_franja_hud` | 58 px escritos a mano | 24, y sale de `NodoCascara.chrome_superior()` |
| Fondo del escritorio | uno fijo por acto | variante al azar por acto, tirada al volver al mapa |

**La decisión de tacto la tomó Daniel: el reloj se queda en la mesa.** Dentro
de la barra de título, que ya gastaba 16 px pegados al campo diciendo
"cascabel.exe". Cuesta cero píxeles de campo, sigue en la línea de visión —que
era la razón de tenerlo en el HUD— y encima es la broma: una ventana con una
barra de progreso que no querrías que se llenara.

### La avería que se ha encontrado de paso

La cáscara va en la capa −10 y `NodoSuelo` pinta un rectángulo negro OPACO
sobre los 400 px de la mesa de arriba abajo. O sea que **la barra de título de
la ventana de la mesa se dibujaba entera y no se veía nunca**, y la barra de
tareas quedaba partida por la mitad —se salvó de milagro: Inicio, la pestaña y
el reloj caen los tres fuera de esa columna—. El docstring prometía una capa 5
desde la primera pasada y la capa no existía. Ahora sí: `NodoCascaraFrente`.
La regla está en `CLAUDE.md`, "Trampas".

Y una segunda, más pequeña: la prueba que impide tamaños de fuente sueltos
tenía un agujero en el patrón y dejaba pasar un `11` en el nombre de la
reliquia dentro de la tele. Arreglado el patrón y el 11.

## Hecho

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

**Orden para aflojar la dificultad:** outlanes primero, flipper después.

## Que pruebe Daniel

**Primero importar y luego la batería. En ese orden, y nada de esto se ha
ejecutado:**

    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --import
    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/prueba_sim.gd

**Lo de esta sesión, por orden de lo que más puede haber salido mal:**

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

1. **FASE 6: comportamientos de enemigo** (Opus, razonamiento alto). **Sube a
   la cabeza por medida, no por gusto:** el barrido dice que con un solo ataque
   por reloj no existe ninguna tabla que deje el run en la banda de dificultad
   que se busca. `DISEÑO.md` §11 tiene los seis (bloquear un recorrido, curarse,
   reflejar, blindaje, castigar el combo, acelerar el reloj). Y con combates de
   137 s, un enemigo que solo tiene vida se nota que es un saco
1b. **Rebalance, segunda pasada** (Opus, alto), DESPUÉS de la Fase 6 y no antes:
   con comportamientos dentro, `tests/medir_daniel.gd` vuelve a barrer y la
   banda del 25-60 % pasa a ser alcanzable. Hasta entonces, tocar la tabla es
   mover el mismo número por cuarta vez
2. **Tanda de assets A: la hoja del espectro** (Sonnet, medio). En cuanto
   Daniel diga si la tiene o si hay que regenerarla. Es el único sprite que
   sigue roto
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
   razonamiento alto). Pedida por Daniel. **Los prompts ya están escritos** en
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
