# CONTEXTO.md — TILT OS

Documento de traspaso. Léelo entero antes de tocar nada.

---

## Qué es esto

Un **pinball roguelike** para escritorio, inspirado en Peglin. Godot 4.7.1,
GDScript, renderizador Compatibility, proyecto en `C:\dev\tilt-os`.

Presupuesto del proyecto: **0 €**. Nada de dependencias de pago.

---

## Las dos decisiones de diseño que lo definen

**1. Flippers de verdad, no apuntar y soltar.** Peglin es por turnos: apuntas,
sueltas, se resuelve. Esto no. El jugador tiene control continuo.

**2. Drenar la bola termina el turno.** Es el puente entre el pinball continuo
y la estructura de combate del roguelike. Mientras la bola vive, acumulas
daño golpeando bumpers y targets. Cuando drena, se resuelve: pegas al enemigo
con lo acumulado y él contraataca. Tres bolas por combate.

Consecuencia: la habilidad con los flippers *es* el recurso. Quien aguanta la
bola más tiempo pega más fuerte y recibe menos ataques.

---

## La estética: el juego corre dentro de un sistema operativo falso

Se llama **TILT OS**. Aspecto de Windows XP de 2002. La mesa de pinball vive
dentro de una ventana de ese escritorio.

**Dos capas con reglas opuestas, y esto es importante:**

| Capa | Qué es | Cómo se hace |
|---|---|---|
| Cáscara | Ventanas, barra de tareas, botones, tooltips | **Por código.** Degradados, biselados, resolución nativa. |
| Contenido | Enemigos, reliquias, objetos de mesa, bola | Sprites pixelart, baja resolución, píxeles duros |

Esa diferencia es deliberada: parece un juego pixelado corriendo dentro de un
sistema que no lo es. **No dibujes la cáscara con sprites** y no apliques
filtro nearest a los elementos de interfaz.

Cada elemento del sistema hace trabajo de juego, no decora:

- Reliquias = iconos del escritorio
- Descripciones = tooltips amarillos de XP
- Mapa del run = ventana de explorador de carpetas
- Combate = una ventana
- Multibola = varias ventanas abiertas
- Derrota = pantalla azul TILT con volcado de error
- Menú principal = botón Inicio
- Eventos = ventanas emergentes que no se pueden cerrar

**Aviso legal:** nada de assets reales de Microsoft. Ni el fondo Bliss, ni el
logo, ni las texturas de Luna, ni los iconos originales. Reconocible sí,
calcado no.

---

## Estado actual

- Proyecto de Godot creado y vacío. Escena sin crear.
- `git init` hecho, primer commit hecho.
- Los cuatro ajustes de proyecto **están sin poner** (ver abajo).
- Assets generados y procesados, pendientes de copiar a `assets/`.
- Física validada en un prototipo HTML aparte. Los números están abajo.

---

## Ajustes de proyecto pendientes

Edítalos en `project.godot` directamente, es texto plano:

| Ajuste | Valor | Por qué |
|---|---|---|
| `rendering/textures/canvas_textures/default_texture_filter` | `0` (Nearest) | Sin esto los sprites salen borrosos |
| `display/window/stretch/mode` | `canvas_items` | Escalado con píxeles enteros |
| `display/window/stretch/scale_mode` | `integer` | Evita píxeles de tamaños mezclados |
| `physics/common/physics_ticks_per_second` | `120` | A 60 la bola atraviesa paredes |
| `display/window/size/viewport_width` | `400` | Ancho de la mesa |
| `display/window/size/viewport_height` | `700` | Alto de la mesa |

---

## Física: lo que ya está validado

Probado en un prototipo HTML con física propia. **Estos números están
ajustados a mano y funcionan.** Portarlos, no reinventarlos.

```
gravedad            1750 px/s²
rebote de paredes   0.42
radio de la bola    9 px
rozamiento          0.20   (v *= exp(-0.20 * dt))
velocidad máxima    1500 px/s
flippers:
  velocidad de giro 22 rad/s
  recorrido         60°
  rebote            0.30
  longitud          78 px
  radio de la pala  8 px
bumpers   empuje 620, restitución 1.8 en el término normal
slingshot empuje 700, restitución 0.55
lanzador  1350
```

**El detalle que hace todo el tacto:** el flipper no rebota, empuja. Calcula
la velocidad de la superficie en el punto de contacto (`ω × r`, siendo r el
vector del eje al punto de contacto) y resuelve el impulso contra la
velocidad *relativa* de la bola respecto a esa superficie. Un flipper quieto
solo rebota; uno en movimiento lanza. Si esto se pierde en el port, el juego
se siente muerto.

### Geometría de la mesa (lienzo 400 × 700, Y hacia abajo)

```
Arco superior   elipse centro (200,130) rx 180 ry 70, de (20,130) a (380,130)
Pared izquierda (20,130) -> (20,480)
Pared derecha   (380,130) -> (380,660)
Carril lanzador pared interior (350,300) -> (350,660), suelo (350,660)-(380,660)
Puerta antirretorno (350,300) -> (380,300), activa solo cuando la bola ya entró
Rampa izquierda (20,480)  -> (105,592)
Rampa derecha   (350,480) -> (295,592)
Slingshot izq   (75,505)  -> (128,575)
Slingshot der   (325,505) -> (272,575)
Flipper izq     eje (118,600), reposo 28°,  activo -32°
Flipper der     eje (282,600), reposo 152°, activo 212°
Bumpers         (140,225) r19, (260,225) r19, (200,165) r19
Drenaje         y > 700
Bola nueva      (365, 648) en el carril
```

### Bug conocido y sus tres arreglos

La bola se atasca junto a los flippers. Causa: entre el final de la rampa
(105,592) y el eje del flipper (118,600) quedan 7,3 px de hueco, y la bola
tiene 9 px de radio. No cabe, pero se acuña: cada colisionador la empuja
contra el otro y oscila hasta pararse.

Hacen falta los tres arreglos, no uno:

1. **Geometría.** Montar *inlanes* de verdad ahí: un carril de retorno con un
   poste de goma que devuelve la bola al flipper. No tapar el hueco, rediseñar.
2. **Solver.** Resolver la posición solo contra el contacto más profundo del
   substep y aplicar los impulsos de todos después, con tolerancia de ~0,5 px.
3. **Ball search.** Si la bola baja de cierta velocidad durante 2 segundos,
   empujón automático. Las máquinas reales lo hacen.

---

## Assets

Generados con ChatGPT, procesados con `procesar.py` (está en el repo). El
script recorta el fondo magenta, detecta los sprites por silueta, reduce y
cuantiza a la paleta. **No edites los PNG a mano**: si cambia la paleta, se
reprocesan todos de golpe desde los originales.

```
assets/
  reliquias/   9 iconos, 64x64
  mesa/        9 objetos + bola (24x24) + flipper_der y flipper_izq (64x64)
  enemigos/    9 enemigos, 96x96, escala común y pies alineados
```

`flipper_izq.png` es el derecho reflejado por código.

### Perspectiva

Los objetos se dibujan **mirando al jugador**, como los sprites de un RPG
cenital. El suelo se ve desde arriba, los objetos están de pie hacia la
cámara. No es cenital puro y es a propósito: es lo que hace Peglin y es más
legible.

### Paleta cerrada

```
neutros  14121A 2A2A33 43434F 62636F 8C8D99 B9BAC4 E4E6EC
piedra   3A3832 55524A 7A7669 A09B8A
tierra   2B2028 4A3A42 755F52 A88968 D9BF95 F5E9CE
rojos    8C2E2E C74A3C E8814A
oro      8A6524 E0A63C F7D86B
cobre    6B3A22 A0603A C98A4B
verdes   2F5A38 4E7C3A 7BA84A
azules   274A63 4478A0
arcano   6B3F9E A97BD9
```

El violeta arcano es el único color mágico. Con cuentagotas.

### Detalle técnico del pixelart

**La bola no se ajusta a la rejilla de píxeles.** A 1500 px/s tiritaría de
forma horrible. Los sprites estáticos se ajustan; la bola se dibuja con
subpíxel dentro del viewport de baja resolución.

La calavera llameante flota: necesita desplazamiento vertical propio en vez
de alinearse al suelo como los demás enemigos.

---

## Arquitectura sugerida

```
sim/       física y reglas, sin dependencias del motor
render/    dibujado y escenas
ui/        la cáscara de TILT OS
data/      reliquias, enemigos, mesas en JSON o .tres
assets/    sprites procesados
```

Mantener `sim/` independiente del resto: hace la física testeable sin abrir
ventana y permite ejecutar pruebas en headless.

---

## Reglas de trabajo

- **No te incluyas nunca como colaborador, contribuidor ni autor** en el
  repositorio ni en ningún archivo: ni en README, ni en CONTRIBUTORS, ni en
  cabeceras de código, ni en mensajes de commit.
- Commits pequeños y frecuentes. El repositorio es la red de seguridad.
- Verifica con `godot --headless` que el proyecto arranca antes de dar algo
  por hecho.
- La física se ajusta jugando, no calculando. Cuando algo dependa del tacto,
  exponerlo como parámetro y preguntar en vez de decidir.

---

## Siguiente paso

1. Aplicar los ajustes de proyecto.
2. Copiar los assets a `assets/`.
3. Montar la mesa con la física portada y los tres arreglos del atasco.
4. Enseñársela para que la juegue y diga qué se siente mal.

El loop roguelike viene después. Si la bola no se siente bien, lo demás
da igual.
