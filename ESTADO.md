# ESTADO.md

Estado vivo. Se lee al empezar la sesión y se actualiza al terminarla.

**Regla de tamaño:** esto no es un registro de cambios. Al cerrar sesión,
resume lo tuyo en dos o tres líneas dentro de "Hecho" y borra el detalle.
Lo que merezca sobrevivir para siempre va a `CLAUDE.md`, no aquí. Si esto
pasa de una pantalla, sobra algo.

**Última actualización:** cierre de la Fase 2

---

## Fase actual

**Fase 2 — Sensación: cerrada.** Falta que Daniel valide el tacto jugando.
Lo siguiente es la Fase 3, empezando por la identidad de los tiros.

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
  bug que impedía apuntar), flipper a 64, rebote a 0,10, agarre a 40 con
  umbral de velocidad a 700
- **Coherencia visual** `render/paleta.gd` como sitio único con los 33
  colores y alias por uso; prueba que impide colores inventados en `render/`
- **Multiplicador audible** el arpegio pasa a triángulo (bumper y target son
  cuadradas y se lo comían), cinco notas con la última sostenida, 548 ms,
  +1 dB, reproductor propio fuera de la rueda de voces, y transposición por
  tramo en intervalos musicales: x2 en su tono, x3 tercera menor, x4 quinta

## Diales vivos

Los números que se tocan para ajustar el tacto. Uno cada vez.

| Dial | Valor | Para qué |
|---|---|---|
| `ancho_outlane` | 21 | Dificultad. Suelo 18, techo ~26 |
| `flipper_longitud` | 64 | Dificultad. Hueco central 47 px |
| `flipper_rebote` | 0,10 | Si la bola botonea en la pala |
| `flipper_agarre` | 40 | Si no se queda quieta, o si se queda pegada |
| `flipper_agarre_velocidad` | 700 | Por encima de esto no agarra |
| `target_canto` | 8 | Cuánto sobresale el target al campo |

**Orden para aflojar la dificultad:** outlanes primero, flipper después.

## Que pruebe Daniel

1. **Atrapar la bola.** ¿Se queda quieta con la pala levantada? ¿Da tiempo
   a mirar, decidir y soltar?
2. **¿Cada cuánto drena?** El objetivo es cada dos o tres bolas.
3. **Los outlanes.** Deben castigar la bola descontrolada, no la controlada.
4. **Los huecos del tablero en negro y el destello al pegar**, que es lo
   único que cambió de color.
5. **Que la banda gris de la derecha haya desaparecido** en pantalla
   completa.
6. **Subir de tramo, con el racimo sonando.** ¿Se oye que has subido sin
   mirar el número? ¿Y se distingue x3 de x4 solo por el tono? Si tapa
   demasiado los golpes, el dial es `db` de `combo` en `nodo_sonido.gd`.

## Siguiente

1. **Identidad de los tiros** (`DISEÑO.md` §4). Es el arranque real de la
   Fase 3, antes que el mapa: sin tiros distintos no hay decisiones
2. Mapa del run

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
- **El cañón perdió su identidad.** Devolvía la bola al racimo de bumpers y
  eso alimentaba un bucle que mataba al enemigo sin que las palas
  participaran. Ahora baja a la pala izquierda, o sea que los dos carriles
  hacen lo mismo. Se le devolverá identidad al hacer `DISEÑO.md` §4.
- Enemigo fuera de pantalla al hacer scroll → Fase 5, ventana propia
- Laterales del escritorio apagados al 66% como apaño → Fase 5
