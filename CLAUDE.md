# TILT OS

Pinball roguelike en Godot 4.7, GDScript. La mesa vive dentro de un sistema
operativo falso con estética de Windows XP.

## Lo primero de cada sesión

**Lee `ESTADO.md`.** Dice en qué fase estamos, qué está hecho, qué queda y
qué toca ahora. No empieces nada sin leerlo.

`PLAN.md` tiene las fases con sus criterios de salida.
`DISEÑO.md` tiene el diseño de la capa roguelike: el pilar, los ejes de
build, los ganchos de reliquia. **Ábrelo antes de tocar reliquias, enemigos
o estructura de run.**
`CONTEXTO.md` tiene la referencia densa: paleta, assets, proporciones,
estética. **Ábrelo solo para buscar un dato concreto**, no por costumbre, y
no es fuente de verdad para parámetros ni geometría: esos viven en el
código. Si contradice a este archivo, manda este archivo.

## Lo último de cada sesión

**Actualiza `ESTADO.md`** antes de terminar: qué has cerrado, qué queda
abierto, qué es lo siguiente y qué necesitas que Daniel pruebe. Si no lo
haces, la siguiente sesión empieza a ciegas.

## Godot

No está en el PATH. El ejecutable de consola (el que devuelve la salida) es:

`C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe`

Batería de pruebas, sin abrir ventana:

    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/prueba_sim.gd

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
- **`Mesa.new()` copia los parámetros dentro de cada colisionador** en el
  constructor. Cambiar `m.p.<lo_que_sea>` DESPUÉS de crear la mesa no hace
  nada: el colisionador ya tiene su copia. Un barrido de parámetros escrito
  así mide seis veces lo mismo. Para barrer hay que tocar
  `parametros_mesa.gd` y volver a lanzar.
- **No edites `.gd` con `Set-Content -Encoding utf8` desde PowerShell**:
  corrompe los acentos por doble codificación (`restitución` →
  `restituciÃ³n`). Usa herramientas de fichero, no `-replace` en consola.
- **Regenerar un wav no basta: hay que reimportarlo.** Godot sirve la copia
  de `.godot/imported/`, así que tras `python sonidos.py` el juego y las
  pruebas siguen oyendo el sonido viejo. Hay que lanzar
  `Godot ... --headless --path C:\dev\tilt-os --import` antes de probar.
- **Un cambio de recompensa puede romper la mesa sin romper la física.** El
  cañón devolvía la bola al racimo de bumpers y alimentaba un bucle que
  mataba al enemigo sin que las palas participaran nunca. Cuando cambies
  dónde sale un recorrido, mira qué bucle acabas de crear.

## Cómo trabajar

- **Una fase por sesión**, commit al cerrarla. Si en mitad aparece una idea
  buena de otra fase, se anota en `ESTADO.md` y se sigue.
- **`ESTADO.md` no es un registro de cambios.** Al cerrar sesión, resume lo
  tuyo en dos o tres líneas y borra el detalle de la sesión anterior. Lo que
  merezca sobrevivir para siempre —una trampa, un invariante— va aquí, no
  allí.
- **Los criterios de salida se comprueban jugando, no leyendo el código.**
  Cuando algo dependa del tacto, exponlo como parámetro y pregunta. No
  decidas desde el código lo que solo se sabe con las manos.
- **No te incluyas como colaborador, contribuidor ni autor** en el
  repositorio ni en ningún archivo: ni README, ni CONTRIBUTORS, ni
  cabeceras, ni mensajes de commit.
