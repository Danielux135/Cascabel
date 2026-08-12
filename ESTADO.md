# ESTADO.md — CASCABEL

Estado vivo. Se lee al empezar la sesión y se actualiza al terminarla.

**Regla de tamaño:** esto no es un registro de cambios. Al cerrar sesión,
resume lo tuyo en dos o tres líneas dentro de "Hecho" y borra el detalle.
Lo que merezca sobrevivir para siempre va a `CLAUDE.md`, no aquí. Si esto
pasa de una pantalla, sobra algo.

**Última actualización:** Fase 3 entera construida, nada validado

---

## Fase actual

**Fase 3 construida entera (3A, 3B y 3C) y SIN VALIDAR NADA.** Las tres
tienen criterio de salida que solo se comprueba jugando: que el combate se
sienta como una carrera, que vayas a por un tiro concreto en vez de caer en
él de rebote, y que puedas perder en el cuarto combate y querer repetir. No
se ha jugado ninguna. Antes de la Fase 4 hay que sentarse a jugar.

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
| `reloj_carga` | 18 s | **El dial de 3A.** Carrera tensa o paseo. Suelo 15, techo 25 |
| `factor_ataque_drenaje` | 0,5 | Cuánto duele drenar frente al reloj |
| `platillo_atrasa_reloj` | 0,35 | ~6 s. Si el platillo no compensa buscarlo, súbelo |
| `dano_rampa_fuerte` | 26 | Lo que paga el cañón por ese retorno difícil |
| `curacion_descanso` | 0,30 | Si descansar es siempre obvio, bájalo |
| `filas_por_acto` | 4 | Largo del run. 4 y 3 actos = 12-15 combates |
| `factor_vida_elite` | 1,35 | Cuánto más duro es un élite |

**Orden para aflojar la dificultad:** outlanes primero, flipper después.

## Que pruebe Daniel

0. **El tiro desde la cuna, que es lo último que se ha tocado.** Atrapa la
   bola, suéltala y vuelve a dar. Con la pala izquierda debe llegar arriba y
   alcanzar el banco de targets. Dos cosas que mirar: si el golpe se siente
   demasiado fuerte ahora (`flipper_velocidad_giro`, de 22 a 30), y si la
   pala derecha se queda corta —está medido que llega a y=903 sin tocar nada.
0b. **La apertura.** Lanza a tope diez veces seguidas sin tocar nada más. La
   bola tiene que dar la vuelta por la órbita y **caerte en la pala
   izquierda**. Si vuelve a irse por el outlane, la boca se ha quedado corta.
1. **Atrapar la bola, que es lo que estaba mal.** Con la pala levantada debe
   RODAR hasta el hueco del eje y quedarse ahí (~0,6 s), no clavarse donde
   toque. Y con la pala en reposo no debe quedarse nunca: rueda y se va.
   Si sigue soldándose, baja `rodadura`; si no llega a asentarse, súbela.
2. **¿Cada cuánto drena?** El objetivo es cada dos o tres bolas.
3. **Los outlanes.** Deben castigar la bola descontrolada, no la controlada.
4. **Los huecos del tablero en negro y el destello al pegar**, que es lo
   único que cambió de color.
5. **Que la banda gris de la derecha haya desaparecido** en pantalla
   completa.
6. **Subir de tramo, con el racimo sonando.** ¿Se oye que has subido sin
   mirar el número? ¿Y se distingue x3 de x4 solo por el tono? Si tapa
   demasiado los golpes, el dial es `db` de `combo` en `nodo_sonido.gd`.
7. **El reloj, que es el criterio de salida de 3A.** ¿El combate se siente
   como una carrera? Contra la Rata y contra la Gárgola, que son los dos
   extremos de la tabla (N cambia de enemigo). Un jugador bueno debe ganar
   con vida de sobra y uno malo quedarse sin vida.
8. **Que el golpe del reloj no se lea como injusto.** Llega en mitad de la
   bola y no para nada, a propósito. Si sorprende, el aviso de 3-2-1 es
   corto: `reloj_aviso`.
9. **El cañón, que es el criterio de salida de 3B.** Te escupe la bola
   cruzada y rápida a la pala derecha. ¿La cazas si vas atento y la pierdes
   si no? Si es imposible de cazar siempre, el tiro no vale lo que paga.
10. **El platillo.** ¿Compensa buscarlo por los ~6 s que quita del reloj, o
    prefieres siempre el cañón? Si nunca lo eliges, sube
    `platillo_atrasa_reloj`.
11. **A ciegas, sin mirar la pantalla:** ¿sabes qué acabas de conseguir solo
    por el sonido? Racimo, target, banco cerrado, órbita, retorno, cañón y
    platillo tienen sonido propio. Si dos se confunden, dime cuáles.
12. **El mapa, que es el criterio de salida de 3C.** Pierde a propósito por el
    cuarto nodo: ¿te apetece darle a R? Si no, el problema no es el mapa, es
    que el combate todavía no engancha.
13. **¿La vida aguanta un acto?** Si mueres siempre en el acto I, o el reloj
    aprieta demasiado o los enemigos tienen mal la vida. Dime en qué nodo
    mueres y con cuánta vida llegabas.
14. **¿Eliges rama de verdad?** Si siempre coges la misma sin mirar, o las
    ramas no se diferencian lo bastante o falta información en el mapa.

## Siguiente

1. **Jugar y cerrar la Fase 3 entera.** Nada de esto está validado
2. **Rehacer la tabla de enemigos**, que ya toca: los tiros pagan cosas
   distintas, el reloj existe y el mapa reparte enemigos por acto, o sea que
   por fin hay contra qué balancear
3. **Fase 4, reliquias.** Quince, cubriendo los cinco ejes y seis ganchos

## Mediciones

| Qué | Valor |
|---|---|
| Duración de bola, mesa pequeña | ~10 s |
| Objetivo de drenaje | cada 2-3 bolas |
| Daño de una bola buena | 160 con 13 golpes a ×3 |
| Vida de enemigos | ×3 provisional (180-540) |

La tabla de vida se rehace entera en la Fase 3. Ajustarla ahora es trabajo
perdido.

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
- **La tabla de enemigos no está balanceada contra el reloj.** Con vidas de
  180 a 540 y ataques de 6 a 16, los de arriba caen antes del primer golpe
  de reloj y los de abajo pueden ser un muro. La tabla se rehace entera
  después de 3B, cuando los tiros paguen cosas distintas: ajustarla ahora es
  trabajo perdido otra vez.
- Enemigo fuera de pantalla al hacer scroll → Fase 5, panel propio
- Laterales del escritorio apagados al 66% como apaño → Fase 5
- **El juego pasa a llamarse Cascabel** (`DISEÑO.md` rev. 4). Cambiados los
  documentos, `project.godot` y los comentarios del código; las rutas y el
  nombre del repo siguen siendo `tilt-os` a propósito. La cáscara del
  sistema operativo se queda como marco visual, ahora en pixelart con marcos
  de nueve trozos y sin gestor de ventanas: la Fase 5 está reescrita con eso.
  **De la cáscara no hay ningún asset todavía salvo el fondo.**
