# TILT OS

Pinball roguelike en Godot 4.7, GDScript. La mesa vive dentro de un sistema
operativo falso con estética de Windows XP.

## Lo primero de cada sesión

**Lee `ESTADO.md`.** Dice en qué fase estamos, qué está hecho, qué queda y
qué toca ahora. No empieces nada sin leerlo.

`PLAN.md` tiene las fases con sus criterios de salida.
`CONTEXTO.md` tiene la referencia densa: paleta, geometría de la mesa,
parámetros de física validados, inventario de assets. **Ábrelo solo cuando
necesites un dato concreto de ahí**, no por costumbre.

## Lo último de cada sesión

**Actualiza `ESTADO.md`** antes de terminar: qué has cerrado, qué queda
abierto, qué es lo siguiente y qué necesitas que Daniel pruebe. Si no lo
haces, la siguiente sesión empieza a ciegas.

## Invariantes

Decisiones cerradas. No las reabras sin que Daniel lo pida.

- **Mesas diseñadas a mano, nunca procedurales.** Lo que varía entre
  partidas son reliquias, enemigos y modificadores, no la geometría.
- **Mantener el flipper sigue siendo mantener el flipper.** Es una técnica
  de juego. No se le asigna ninguna habilidad a ese gesto.
- **Las rampas son curvas, no física simulada.** La bola se desengancha,
  recorre un spline y vuelve con la velocidad tangente.
- **El daño se aplica al golpear, no al drenar.** No hay cuenta de bolas:
  hay vida, y drenar cuesta vida.
- **Los enemigos normales viven fuera del campo de juego.**
- **La bola es el bloque de stats del jugador, solo en efectos.** Nunca en
  tamaño ni masa: descuadra el hueco entre palas.
- **Escalado por enteros siempre.**

## Trampas que ya nos han costado tiempo

- **Rejilla de píxeles.** Nada se mueve, escala ni rota en fracciones de
  píxel: la cámara, la respiración y las rotaciones van en pasos enteros o
  la imagen hierve.
- **La cámara va en `_physics_process`**, pegada a la simulación. En
  `_process` se queda un fotograma por detrás y a 720 px/s eso pierde la
  bola. Y una sola llamada: ya se duplicó una vez.
- **Los colisionadores y el arte deben ser la misma medida.** Cuando la
  forma sea un parámetro que aún se está ajustando, dibújala por código en
  vez de usar un sprite.
- **Todo efecto tiene que caducar solo.** Un sistema de partículas sin
  caducidad arrastra miles en una partida larga.
- **Cada rincón nuevo de la mesa es un sitio donde la bola se acuña.**
  Prueba cada zona nueva contra atascos y no toques el ball search.

## Cómo trabajar

- **Una fase por sesión**, commit al cerrarla. Si en mitad aparece una idea
  buena de otra fase, se anota en `ESTADO.md` y se sigue.
- **Los criterios de salida se comprueban jugando, no leyendo el código.**
  Cuando algo dependa del tacto, exponlo como parámetro y pregunta. No
  decidas desde el código lo que solo se sabe con las manos.
- **No te incluyas como colaborador, contribuidor ni autor** en el
  repositorio ni en ningún archivo: ni README, ni CONTRIBUTORS, ni
  cabeceras, ni mensajes de commit.
