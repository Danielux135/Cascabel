# ESTADO.md — CASCABEL

Estado vivo. Se lee al empezar la sesión y se actualiza al terminarla.

**Regla de tamaño:** esto no es un registro de cambios. Al cerrar sesión,
resume lo tuyo en dos o tres líneas dentro de "Hecho" y borra el detalle.
Lo que merezca sobrevivir para siempre va a `CLAUDE.md`, no aquí. Si esto
pasa de una pantalla, sobra algo.

**Última actualización:** arte de IA de la cáscara integrado (ventana, título,
barra de tareas, Inicio, botones, iconos), con el fallo del magenta sin
transparentar ya cerrado.

---

## Fase actual

**Fase 5, tercera pasada: cáscara con arte de verdad.** Nada se ha ejecutado
todavía: el sandbox no llega a Godot, así que todo lo de abajo es sin probar.

**La fuente y los marcos son nuestros y se generan por código** (`fuente.py`,
igual que `sonidos.py` genera los sonidos). Eso ya cerró dos fallos de
sesiones anteriores: la fuente de reserva de Godot sin acentos, y los marcos
recortados por silueta que no cuadraban entre sí. Detalle en `CLAUDE.md`.

**El cuadre en portátiles con pantalla no-16:9 tenía causa de código:**
`stretch/aspect = expand` hace crecer el viewport, y `ParametrosCamara` seguía
clavado en 960×540 mientras la cáscara medía el viewport real —dos sistemas de
coordenadas para la misma pantalla—. `VistaMesa._medir_pantalla()` los
sincroniza ahora en un solo sitio. **Sin confirmar por Daniel todavía.**

**El arte de IA de la cáscara ya está recortado e integrado esta sesión:**
ventana, barra de título y barra de tareas (de las hojas que generó Daniel
con `assets/prompts_cascara.md`, validadas con un mosaico de prueba antes de
tocar el repo), botón Inicio con el cascabel de logo, botones min/max/cerrar,
nueve iconos decorativos, y tres fondos que cambian por acto. Un primer
recorte dejó el fondo magenta sin volver transparente —motas rosas en las
esquinas y detrás de los iconos, que Daniel cazó a la primera jugada— y ya
está arreglado. Los iconos decorativos están en la banda izquierda, colgando
desde abajo para no chocar con las reliquias (arriba). El reloj de la barra de
tareas tiene ya su propia bandeja hundida, aunque el sprite de esa bandeja
sigue siendo un `draw_rect` de apaño.

**Sin conectar todavía, aunque ya están recortados:** cursor, barra de
progreso del reloj enemigo, marco de diálogo, tooltip nuevo —
`assets/ui/cursor`, `assets/ui/progreso`, `assets/ui/dialogo`,
`assets/ui/tooltip`. Y una segunda tanda de prompts, pedida por Daniel y
todavía sin generar: fondos que se "buguean" en variantes por acto (no una
imagen fija, sino dos o tres fallos distintos que se sortean) y piezas
pequeñas de bandeja de sistema (sprite del reloj, separador, altavoz, icono de
sin-red) — sección 2 de `assets/prompts_cascara.md`.

## Hecho

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
| `platillo_atrasa_reloj` | 0,35 | Se mide en fracción de barra, no en segundos: ahora son ~3 s |
| `dano_rampa_fuerte` | 78 | Lo que paga el cañón por ese retorno difícil |
| `curacion_descanso` | 0,30 | Si descansar es siempre obvio, bájalo |
| `filas_por_acto` | 4 | Largo del run. 4 y 3 actos = 12-15 combates |
| `factor_vida_elite` | 1,25 | Cuánto más duro es un élite |
| `casillas_ruleta` | 8 | Lo que se ve girando. Solo la primera es el premio |
| `repeticiones_ruleta` | 1 | Con 0 la build se decide a suertes; con 2+ vuelve a ser un menú |
| `vida_jugador` | **1080** | ×6 por resolución al alargar los combates |
| `reloj` (por enemigo) | 6-10 s | El dial de cuánto APRIETA cada uno, aparte de cuánto dura |
| vida de enemigo | 1250-3220 | **Aritmética, no medida.** El dial de cuánto DURA el combate |
| `prob_critico` | 0,06 | Cuántos críticos salen. Las reliquias lo suben |
| `factor_critico` | 2,0 | Por cuánto multiplica un crítico |
| `golpes_tramo_extra` | 12 | Lo que pide el tramo que añade una reliquia. Menos y el x5 sale regalado |

**Orden para aflojar la dificultad:** outlanes primero, flipper después.

## Que pruebe Daniel

**Primero la batería, que nada de esto se ha ejecutado:**

    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/prueba_sim.gd

**Y luego juega un run y DIME DOS NÚMEROS.** Al acabar (ganes o pierdas) la
pantalla enseña *tu daño por bola* y *tu combate medio*. Con esos dos la tabla
de enemigos se escribe exacta, sin modelos y sin volver a fallar. Es lo más
útil que puedes darme ahora mismo, más que cualquier impresión.

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
I. **LA FUENTE, que es lo de esta sesión.** ¿Se lee bien a 8 px? Es la parte
   que más puede fallar: una fuente de 5×7 es legible o no lo es, y eso no lo
   dice ninguna prueba. Si alguna letra se confunde con otra, dime cuáles: se
   arreglan en `fuente.py`, que las tiene escritas como dibujos de texto.
I2. **La cáscara con los marcos nuevos.** Ahora la mesa es una ventana con barra
   de título y un marco de 8 px, en vez de 47 px de piedra descuadrada. ¿Se
   entiende la broma de un vistazo? Ese es el criterio de salida de la fase.
J. **Los iconos de reliquia, pasando el ratón por encima.** ¿El tooltip llega a
   tiempo y dice algo útil? Y lo importante: **¿se ve encenderse y apagarse un
   icono condicional** cuando cruzas su umbral en mitad de un combate?
K. **La pantalla de TILT.** ¿Da ganas de volver a intentarlo? Ahí salen los dos
   números que necesito.
L. **EL ARTE NUEVO DE LA CÁSCARA, que es lo de esta sesión.** Ventana, barra de
   título, barra de tareas, botón Inicio, iconos del escritorio. ¿Ahora sí
   parece un sistema operativo, y sin motas rosas en ninguna esquina? Y el
   pendiente de siempre: ¿la ventana del pinball cuadra en tu portátil, o
   sigue desbordando?
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
5. **Que la banda gris de la derecha haya desaparecido** en pantalla
   completa.
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
12. → ahora es el punto D de arriba.
13. **¿La vida aguanta un acto?** Si mueres siempre en el acto I, o el reloj
    aprieta demasiado o los enemigos tienen mal la vida. Dime en qué nodo
    mueres y con cuánta vida llegabas.
14. **¿Eliges rama de verdad?** Si siempre coges la misma sin mirar, o las
    ramas no se diferencian lo bastante o falta información en el mapa.

## Siguiente

1. **La batería, y un run tuyo para sacar los dos números.** Sigue siendo lo que
   más falta hace: la tabla de enemigos lleva tres versiones escritas a ojo
2. **Conectar lo ya recortado:** cursor, barra de progreso del reloj enemigo,
   marco de diálogo, tooltip nuevo
3. **Generar la segunda tanda de `assets/prompts_cascara.md`** (fondos
   bugueados por acto, bandeja de sistema) cuando Daniel confirme cuántas
   variantes quiere por acto
4. **Lo que le queda a la Fase 5:** el HUD sigue encima de la mesa (el apaño de
   la Fase 1 que no se ha caído), el enemigo sigue en el tablero en vez de en su
   panel, y el mapa todavía no es un explorador de carpetas
5. **Los 27 iconos de reliquia**, con los prompts de `assets/prompts_reliquias.md`.
   Ahora se ven en tres sitios —tele, escritorio y tooltip—, así que faltan más
6. **Fase 6 si los combates aburren.** Un enemigo de tres minutos que solo tiene
   vida es un saco; las misiones lo tapan a medias

## Mediciones

| Qué | Valor |
|---|---|
| Duración de bola, mesa pequeña | ~10 s |
| Objetivo de drenaje | cada 2-3 bolas |
| Daño por bola: malo / normal / bueno | 42 / 312 / 840 |
| Brecha entre jugar mal y jugar bien | 20× (8,4× sin multiplicador) |
| Vida de enemigos | 225-660, salida del barrido |
| Runs acabados: malo / normal / bueno | 0/5 · 2/5 · 5/5 |

Todo esto sale de `tests/medir_balance.gd`. **Antes de tocar un número de
balance, lánzalo**: la tabla ya se hizo dos veces a ojo y las dos salió mal.

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
- **Las reliquias no se ven durante el combate.** Sabes lo que llevas en el mapa
  y en la pantalla de recompensa, pero no mientras juegas, así que una
  condicional que se enciende y se apaga —"por debajo del 30% de vida"— no
  avisa de que acaba de encenderse. Es exactamente la avería del platillo
  esperando a pasar otra vez, y el sitio donde se arregla es la Fase 5: las
  reliquias son iconos del escritorio y un icono puede encenderse.
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
- Enemigo fuera de pantalla al hacer scroll → Fase 5, panel propio
- Laterales del escritorio apagados al 66% como apaño → Fase 5
- **El juego pasa a llamarse Cascabel** (`DISEÑO.md` rev. 4). Cambiados los
  documentos, `project.godot` y los comentarios del código; las rutas y el
  nombre del repo siguen siendo `tilt-os` a propósito. La cáscara del
  sistema operativo se queda como marco visual, ahora en pixelart con marcos
  de nueve trozos y sin gestor de ventanas: la Fase 5 está reescrita con eso.
  **De la cáscara no hay ningún asset todavía salvo el fondo.**
