# ESTADO.md

Estado vivo. Se lee al empezar la sesión y se actualiza al terminarla.

**Regla de tamaño:** esto no es un registro de cambios. Al cerrar sesión,
resume lo tuyo en dos o tres líneas dentro de "Hecho" y borra el detalle.
Lo que merezca sobrevivir para siempre va a `CLAUDE.md`, no aquí. Si esto
pasa de una pantalla, sobra algo.

**Última actualización:** 3A y 3B construidas, las dos sin validar

---

## Fase actual

**Fase 3, 3A y 3B construidas y SIN VALIDAR.** Las dos tienen criterio de
salida que solo se comprueba jugando —que el combate se sienta como una
carrera, y que Daniel vaya a por un tiro concreto en vez de caer en él de
rebote— y ninguna se ha jugado todavía. 3C no debería empezar antes de eso.

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

## Diales vivos

Los números que se tocan para ajustar el tacto. Uno cada vez.

| Dial | Valor | Para qué |
|---|---|---|
| `ancho_outlane` | 21 | Dificultad. Suelo 18, techo ~26 |
| `flipper_longitud` | 64 | Dificultad. Hueco central 47 px |
| `flipper_rebote` | 0,25 | Cuánto revive la goma la bola que llega |
| `rodadura` | 20 | **Techo, no suelo.** Subirlo vuelve a pegar la bola |
| `friccion_flipper` | 0,30 | Cuánto desvía la goma la bola al rozarla |
| `velocidad_rebote_minima` | 55 | Frontera entre impacto y bola apoyada |
| `target_canto` | 8 | Cuánto sobresale el target al campo |
| `reloj_carga` | 18 s | **El dial de 3A.** Carrera tensa o paseo. Suelo 15, techo 25 |
| `factor_ataque_drenaje` | 0,5 | Cuánto duele drenar frente al reloj |
| `platillo_atrasa_reloj` | 0,35 | ~6 s. Si el platillo no compensa buscarlo, súbelo |
| `dano_rampa_fuerte` | 26 | Lo que paga el cañón por ese retorno difícil |

**Orden para aflojar la dificultad:** outlanes primero, flipper después.

## Que pruebe Daniel

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

## Siguiente

1. Ajustar con lo que diga Daniel y **cerrar 3A y 3B**
2. **Rehacer la tabla de enemigos**, que ya toca: los tiros pagan cosas
   distintas y el reloj existe, o sea que ya hay contra qué balancear
3. **3C, mapa del run**

## Mediciones

| Qué | Valor |
|---|---|
| Duración de bola, mesa pequeña | ~10 s |
| Objetivo de drenaje | cada 2-3 bolas |
| Daño de una bola buena | 160 con 13 golpes a ×3 |
| Vida de enemigos | ×3 provisional (180-540) |

La tabla de vida se rehace entera en la Fase 3. Ajustarla ahora es trabajo
perdido.

## Abierto

- **Los dos carriles de retorno no miden lo mismo**: 34 px de boca el
  izquierdo, 27 el derecho, porque el carril lanzador come sitio a la
  derecha. Si se nota al jugar hay que replantear el lado derecho entero, no
  moverlo 3 px.
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
- Enemigo fuera de pantalla al hacer scroll → Fase 5, ventana propia
- Laterales del escritorio apagados al 66% como apaño → Fase 5
