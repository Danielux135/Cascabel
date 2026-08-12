# ESTADO.md — CASCABEL

Estado vivo. Se lee al empezar la sesión y se actualiza al terminarla.

**Regla de tamaño:** esto no es un registro de cambios. Al cerrar sesión,
resume lo tuyo en dos o tres líneas dentro de "Hecho" y borra el detalle.
Lo que merezca sobrevivir para siempre va a `CLAUDE.md`, no aquí. Si esto
pasa de una pantalla, sobra algo.

**Última actualización:** Fase 3 cerrada; tabla de enemigos rehecha con medida

---

## Fase actual

**Fase 3 cerrada entera.** Daniel confirmó jugando el pilar (la cuna apunta,
llega y gusta), el reloj como carrera y el cañón cazable con esfuerzo; el mapa
nuevo lo dio por bueno. Y encima se rehizo la tabla de enemigos, que era el
punto 2 de "Siguiente".

**Lo gordo de la sesión fue el balance, y hubo que construir herramienta.**
`tests/medir_balance.gd` monta combates con el `Combate` real y tres perfiles
de jugador, y barre configuraciones enteras. Sin eso no había forma: la tabla
ya se había hecho a ojo dos veces y las dos se llevó el run por delante.

Lo que encontró, en orden:

1. El coste de un combate es `bolas × drenaje + relojes × ataque`, o sea que
   **cobrar por tiempo se paga al cuadrado**: jugar peor pega menos, por eso
   tarda más, por eso le cobran más veces.
2. **Escalar la vida de los enemigos no arregla eso**, porque divide el coste
   de todos los perfiles por igual y la brecha entre ellos no se mueve. Medido
   y descartado.
3. Aplanar el multiplicador tampoco: cierra la brecha de 20× a 8,4× pero baja
   tanto el daño que se alargan los combates y muere hasta el jugador bueno.
4. La causa real era **un escalón más gordo que lo que medía**: con el reloj en
   18 s, los combates del jugador bueno caían por debajo del umbral y NO comían
   ningún golpe. Partir el reloj en dos lo arregló.

Las dos pegas que salió a pedir Daniel resultaron ser **la misma avería, dos
veces: información que estaba y no se leía.** Ninguna necesitó tocar la
simulación.

1. **El platillo** ya devolvía ~6 s de reloj y él hizo un run entero sin
   enterarse: el "+6 s" salía abajo en el platillo y la barra del reloj
   estaba arriba y sin etiquetar. Ahora la barra dice "ATAQUE EN Ns"
   siempre, y al robar tiempo se enciende en arcano con el "+N s" al lado.
   De paso vuelve la pista de atrapar, quitada cuando la cuna no alcanzaba.
2. **El mapa** ya decía enemigo, vida y tipo de nodo, en textitos de 9 px
   junto a los doce nodos a la vez. Ahora cada nodo es el **retrato del
   enemigo** (los sprites ya estaban en `assets/enemigos/`) y abajo hay una
   **ficha grande solo del nodo marcado**: retrato a 96, tipo, nombre, pv y
   lo que pega. Sin línea de recompensa, porque hasta la Fase 4 ganar no da
   nada y prometerlo sería mentir.

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
| `reloj_carga` | **9 s** | **El dial de 3A, y hay que volver a probarlo con las manos.** Pega el doble de veces la mitad de fuerte |
| `reloj_aviso` | 2 s | Tiene que caber holgado dentro de la carga |
| `factor_ataque_drenaje` | 0,5 | Cuánto duele drenar frente al reloj |
| `platillo_atrasa_reloj` | 0,35 | Se mide en fracción de barra, no en segundos: ahora son ~3 s |
| `dano_rampa_fuerte` | 78 | Lo que paga el cañón por ese retorno difícil |
| `vida_jugador` | 180 | Escala ×3 para que los ataques tengan resolución |
| `curacion_descanso` | 0,30 | Si descansar es siempre obvio, bájalo |
| `filas_por_acto` | 4 | Largo del run. 4 y 3 actos = 12-15 combates |
| `factor_vida_elite` | 1,35 | Cuánto más duro es un élite |

**Orden para aflojar la dificultad:** outlanes primero, flipper después.

## Que pruebe Daniel

**Primero, la batería** (no se ha lanzado desde los cambios del HUD; el
sandbox no llega a Godot, solo al repo):

    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/prueba_sim.gd

A. **El platillo, que es lo único que cambió.** Métele la bola. ¿Ves ahora
   que lo que te devuelve es tiempo, y de qué contador? Si sigue sin
   quedar claro, el siguiente paso NO es subir el dial: es enseñarlo la
   primera vez, con un cartel durante los 0,9 s de captura.
B. **La franja de arriba creció de 58 a 70 px** para que el reloj tenga su
   fila con etiqueta. ¿Come mesa? ¿Tapa algo de la parte de arriba?
C. **La pista de atrapar** sale las tres primeras veces. ¿Sobra, o llega
   tarde?
E. **EL RELOJ DE 9 SEGUNDOS, que es lo único importante de probar.** Está
   medido que la presión por segundo no cambia, pero eso no dice cómo se
   siente: ahora es presión continua en vez de un mazazo cada 18 s. ¿Sigue
   siendo una carrera o se ha vuelto ruido de fondo? Y el aviso de 2 s, ¿avisa
   o agobia? Si falla, el dial es `reloj_carga`.
F. **¿Aguantas el run?** Está medido que un jugador medio acaba 2 de cada 5.
   Si mueres siempre, dime en qué acto: la fila `1.20 / 0.85` del barrido da
   los mismos resultados con combates más largos.
D. **El mapa nuevo, que es lo que cierra 3C.** ¿Ahora eliges rama de verdad,
   mirando quién hay y con cuánta vida llegas? Mira sobre todo: si los nodos
   a 24 px se distinguen unos de otros, si la ficha de 118 px de alto come
   demasiado sitio a las ramas, y si echas de menos ver la ficha de un nodo
   que NO sea el marcado.

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

1. **Jugar el reloj de 9 s.** Es lo único de la sesión que ninguna medida
   puede validar, y es el dial que ya habías aprobado con las manos a 18
2. **Fase 4, reliquias.** Quince, cubriendo los cinco ejes y seis ganchos. Con
   ellas el descanso por fin compite con algo y el run deja de ser solo
   desgaste, que era la queja de Daniel al empezar la sesión

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
- **Sin reliquias, el descanso no compite con nada.** `DISEÑO.md` §9 dice que
  la tensión está en elegir entre curarte y mejorar; hasta la Fase 4 solo
  existe curarte, así que ese nodo todavía no decide nada.
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
