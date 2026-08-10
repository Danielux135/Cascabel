# ESTADO.md

Estado vivo del proyecto. Se lee al empezar la sesión y se actualiza al
terminarla. Mantenlo corto: si crece más de una pantalla, sobra algo.

**Última actualización:** bloque 1 de control (pantalla completa, slingshots,
flipper 64, agarre, outlanes)

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

Los puntos 1 a 4 están cerrados y los dos diales de dificultad (outlanes y
longitud del flipper) ya están puestos. Queda medir con las manos si la mesa
castiga lo que tiene que castigar. Falta el punto 5.

## Hecho esta sesión (bloque 1: que se vea y se controle)

- **Pantalla completa por defecto.** La ventana de escritorio era 1908×960 y
  con base 960×540 el escalado entero caía a ×1. `window/size/mode=3` y el
  override de ventana en 1920×1080, que es ×2 exacto. Comprobado en las
  pruebas de ajustes.
- **Slingshots fuera del barrido de la pala.** Era el bug de verdad: la punta
  baja de cada banda cruzaba el arco que barre el flipper, así que la bola
  apoyada en la pala levantada tocaba el slingshot y salía disparada. Medido:
  la bola quedaba 8,8 px DENTRO del slingshot. Movidos 20 px el izquierdo y
  30 px el derecho, en perpendicular a la línea que describe la bola apoyada
  en la pala arriba (la dirección que aleja sin estrechar el carril de
  retorno). Ahora quedan 16 px de holgura. El derecho, además, recortado por
  arriba: el carril de retorno izquierdo suelta la bola en (330,1085) y la
  banda subida le pasaba a 8 px.
- **Prueba nueva `_prueba_barrido_del_flipper`.** Pasea una bola de mentira
  por encima de la pala en las 25 posiciones del recorrido y de 15 px del eje
  a la punta, y comprueba que no toca ningún colisionador. Verificada al
  revés: con los slingshots viejos falla en los dos lados.
- **Boca del outlane desacoplada de su altura.** Se recortaba sobre la
  diagonal de la pared, así que estrechar el outlane subía también su esquina
  y pinzaba la entrada del carril de retorno. Ahora la boca es un tramo
  horizontal a altura fija y `ancho_outlane` solo la mueve de lado.
- **Diales de dificultad y tacto:** `flipper_longitud` 78 → **64** (el hueco
  central pasa de 22 a 47 px), `ancho_outlane` 26 → **21**, `flipper_rebote`
  0,30 → **0,10**, `flipper_agarre` 16 → **40**.
- **La espiral del suelo, movida** de (128,900) a (285,895). No es capricho:
  con la pala corta la bola drena antes, la muestra se acorta y la espiral
  pasaba del 3 % que tolera `_prueba_adornos`. En el sitio nuevo marca 1,6 %.

## Hecho en sesiones anteriores

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

- **Bloque 2, coherencia visual.** Solo cuando Daniel dé el visto bueno al
  bloque 1. Todo lo que se dibuja por código (postes, slingshots, paredes,
  targets, carriles, HUD) tiene que salir de la paleta de 26 colores de
  `CONTEXTO.md`, centralizada en un único sitio. Ahora hay dorados, rojos
  puros y lavandas que no están en la paleta. Y el fondo del escritorio no
  cubre todo el ancho: queda una banda gris a la derecha.
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

Cinco cosas, y todas son de manos. Ninguna se decide leyendo el código.

1. **Atrapar la bola.** Levantar la pala con la bola encima y ver si se
   queda quieta para apuntar. Si todavía botonea, el dial es
   `flipper_rebote` (0,10); si se queda pegada como con cola y ya no sale
   bien al soltar, `flipper_agarre` (40).
2. **Que el slingshot ya no dispare la bola atrapada.** Es lo que impedía
   apuntar. Si sigue pasando en algún sitio, decir DÓNDE.
3. **La pala de 64.** El hueco central pasa de 22 a 47 px, así que se drena
   por el medio bastante más. Si ahora es demasiado, el dial es
   `flipper_longitud`.
4. **Los outlanes a 21.** Tienen que castigar la bola descontrolada, no la
   controlada. Si ya no se cuela nunca, subirlo hacia 24; 18 es el suelo
   (por debajo no cabe la bola).
5. **Que la pantalla completa entre a ×2** y no se vea nada borroso ni a
   tamaño de sello.

Objetivo de la tanda: pasar de "drena una vez cada diez combates" a "drena
cada dos o tres bolas". Si se pasa de castigo, el orden para aflojar es
outlanes primero y flipper después, uno cada vez.

## Abierto, sin resolver

- Los dos carriles de retorno no miden lo mismo: el izquierdo tiene 34 px de
  boca y el derecho 27, porque el carril lanzador le come sitio a la mitad
  derecha de la mesa. Ya era así antes; ahora la diferencia se nota un poco
  más. Si se acaba notando al jugar, hay que replantear el lado derecho
  entero, no moverlo 3 px.

- Enemigo fuera de pantalla al hacer scroll. Se resuelve en la Fase 5 con
  el enemigo en su propia ventana.
- Laterales del escritorio apagados al 66% como apaño provisional; en la
  Fase 5 pasa a ser el estado "ventana de combate en primer plano".
- Iconos de reliquia: hay versión de 64 y de 32 px. La de 32 es para el
  escritorio, la de 64 para la pantalla de recompensa.
