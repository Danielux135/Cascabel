# ESTADO.md

Estado vivo del proyecto. Se lee al empezar la sesión y se actualiza al
terminarla. Mantenlo corto: si crece más de una pantalla, sobra algo.

**Última actualización:** subida a 960x540

---

## Fase actual

**Fase 2 — Sensación.** Cerrada salvo comprobación de Daniel.

## Hecho

- **Fase 0:** física, flippers, bumpers, targets, combate con daño en vivo,
  multiplicador de combo, vida del enemigo
- **Fase 1:** 960×540 con escalado entero, mesa 400×1300, cámara vertical
  con sus cuatro reglas, órbita bidireccional y dos carriles de retorno como
  splines, platillo que captura y expulsa
- **Fase 2:** hitstop, sacudida en píxeles enteros, girador con ocho
  rotaciones pregeneradas, respiración en pasos enteros, nueve sonidos
  sintetizados por `sonidos.py`, banco de 14 voces, efectos de onda, polvo
  y chispas

## Pendiente ahora mismo

Corrección de dificultad y control. La mesa se ha vuelto **demasiado
fácil**: Daniel drena una vez cada diez combates, cuando debería drenar
cada dos o tres bolas. Diagnóstico: las rampas son zonas de riesgo cero, y
al medir contra las proporciones de una máquina real salen dos elementos
mal dimensionados.

1. **Racimo de bumpers.** Hay 82 px de aire entre ellos y la bola pasa sin
   tocar. Juntarlos en triángulo con ~24 px entre bordes (la bola mide 18).
2. **Outlanes.** No existen: solo se drena por el centro. Dos carriles a
   los lados de los flippers con la anchura como parámetro. Es la válvula
   de dificultad de la mesa.
3. **Atrapar la bola.** Con el flipper levantado la bola debe asentarse y
   quedar quieta para poder apuntar. Sin esto no se apunta, se cae en los
   tiros de rebote.
4. **Identidad de los tres recorridos.** Ahora los tres solo mueven la
   bola. Recompensas y sonidos distintos.
5. **Multiplicador audible** al subir de tramo.

**Orden de los diales de dificultad:** outlanes primero, luego bajar el
flipper de 78 a 64. Uno cada vez, o no se sabrá cuál hizo qué.

## Hecho esta sesión

- **960×540.** `project.godot` y `ParametrosCamara`. Todo lo demás sale de
  `ancho_visible`/`alto_visible`, así que no hubo nada más que tocar: el HUD
  y el escritorio se recolocaron solos. El fondo del escritorio es 320×180,
  o sea ×3 exacto: sigue sin romper píxeles. La mesa sigue en 400 unidades y
  la física no se ha tocado.
- **Targets: la forma, no el tamaño.** Lo de "los targets miden 60" era un
  error de la nota anterior: ese 60 era el argumento `visible_px` de
  `_dibujar_sprite_centrado`, o sea el tamaño del dibujo dentro del PNG de
  64, no una medida de la mesa. Medido de verdad, el target ya media 30 px
  de cara, que es justo lo de un drop target real (1,5" sobre una mesa de
  20,25" = 400 unidades). Lo que estaba seis veces mal era el FONDO: era un
  círculo de radio 13 que metía 26 px de cuerpo redondo en el campo, y por
  eso se les daba de refilón. Ahora es una plancha:
  `target_ancho = 30` (la cara, no se toca) y `target_canto = 8` (lo que
  sobresale, este es el dial). El borde de fuera se queda clavado donde
  estaba, así que el carril de detrás sigue midiendo 23 px y lo que se abre
  son 18 px de campo por delante del banco.
- El target pasa a dibujarse **por código**, como el flipper, porque el
  canto es un dial vivo y el arte tiene que medir lo mismo que el
  colisionador. `target_escudo.png` y `target_lapida.png` quedan sin usar en
  `assets/mesa/`: vuelven cuando el número se quede quieto. Mientras tanto
  los dos bancos se distinguen por color (oro el izquierdo, arcano el
  derecho).

## Siguiente

- Bajar el flipper de 78 a 64, después de probar los outlanes.
- Fase 3: el mapa del run.

## Mediciones de referencia

| Qué | Valor |
|---|---|
| Duración de bola, mesa pequeña | ~10 s |
| Duración de bola, mesa grande | demasiado alta, casi no drena |
| Objetivo | drenar cada 2-3 bolas |
| Daño de una bola buena | 160 con 13 golpes a ×3 |

La tabla de vida de enemigos se rehará entera en la Fase 3: ajustarla ahora
es trabajo perdido.

## Que pruebe Daniel

1. **Que la mesa se lea bien con la vista nueva.** Con 540 px de alto la
   bola cae más centrada que antes: `adelanto = 110` la dejaba a 70 px del
   borde de arriba y ahora la deja a 160. Se ve más mesa por delante, pero
   si se nota que la cámara "va sobrada", el dial es `adelanto`.
2. **Que ya no se dé de refilón a los targets.** Pasar por delante del
   banco sin querer tocarlo. Si sigue enganchando, bajar `target_canto`; si
   ahora cuesta darles a propósito, subirlo.

## Abierto, sin resolver

- Enemigo fuera de pantalla al hacer scroll. Se resuelve en la Fase 5 con
  el enemigo en su propia ventana.
- Laterales del escritorio apagados al 66% como apaño provisional; en la
  Fase 5 pasa a ser el estado "ventana de combate en primer plano".
- Iconos de reliquia: hay versión de 64 y de 32 px. La de 32 es para el
  escritorio, la de 64 para la pantalla de recompensa.
