# CONTEXTO.md — CASCABEL

Referencia densa. **No se lee entero**: se abre para buscar un dato
concreto. El estado del proyecto está en `ESTADO.md`, las decisiones vivas
en `CLAUDE.md`, el diseño en `DISEÑO.md`, las fases en `PLAN.md`.

> **Aviso.** Este documento describe intenciones de partida y referencias de
> arte. **No es fuente de verdad para parámetros ni geometría**: esos viven
> en el código (`sim/parametros_*.gd`) y se ajustan jugando. Si algo de aquí
> contradice a `CLAUDE.md`, manda `CLAUDE.md`.

---

## La estética

El juego se llama **Cascabel**. La **cáscara** es un sistema operativo falso
con aspecto de Windows XP de 2002: la mesa vive dentro de un panel de ese
escritorio. Da el marco visual, no el nombre.

**Todo va en pixelart, cáscara incluida:**

| Capa | Qué es | Cómo se hace |
|---|---|---|
| Cáscara | Paneles, barra de tareas, botones, tooltips | **Sprites pixelart**, con marcos de nueve trozos que se estiran a cualquier tamaño |
| Contenido | Enemigos, reliquias, objetos de mesa, bola | Sprites pixelart, píxeles duros |

Misma rejilla y misma paleta para las dos. **La versión anterior —cáscara
dibujada por código con degradados y biselados en resolución nativa— queda
descartada**: era más cara y peleaba con el arte.

**No hay gestor de ventanas.** Los paneles están en posiciones fijas y solo
parecen ventanas: no se arrastran, no se redimensionan, no hay foco, ni
orden de apilado, ni minimizar.

Cada elemento del sistema hace trabajo de juego, no decora:

- Reliquias = iconos del escritorio
- Descripciones = tooltips amarillos
- Mapa del run = panel de explorador de carpetas
- Combate = un panel
- El reloj del enemigo = un diálogo de progreso cuyo botón de cerrar no cierra
- Multibola = varios paneles abiertos
- Derrota = pantalla azul **TILT** con volcado de error
- Menú principal = botón Inicio
- Eventos = avisos emergentes que no se pueden cerrar

**Aviso legal:** nada de assets reales de Microsoft. Ni Bliss, ni el logo,
ni las texturas de Luna, ni los iconos. Reconocible sí, calcado no.

---

## El detalle que hace todo el tacto

El flipper **no rebota, empuja**. Calcula la velocidad de la superficie en
el punto de contacto (`ω × r`, con r del eje al punto de contacto) y
resuelve el impulso contra la velocidad *relativa* de la bola respecto a esa
superficie.

Un flipper quieto solo rebota; uno en movimiento lanza. Si esto se pierde,
el juego se siente muerto.

---

## Assets

Generados con ChatGPT, procesados con `procesar.py`. El script recorta el
fondo magenta, detecta sprites por silueta, reduce y cuantiza a la paleta.
**No edites los PNG a mano**: si cambia la paleta, se reprocesan todos de
golpe desde los originales.

```
assets/
  reliquias/     18 iconos 64×64   (pantalla de recompensa)
  reliquias_32/  18 iconos 32×32   (escritorio)
  mesa/          objetos, bola 24, flippers 64
  enemigos/      9 enemigos 96×96, escala común, pies alineados
  jefes/         3 jefes 128×128
  mesa_suelo/    suelo_piedra 128×128, repite sin costuras
  mesa_deco/     9 adornos de suelo
  shell/         fondo_escritorio 320×180, paleta propia
```

De la cáscara solo existe el fondo. **Los marcos de nueve trozos, la barra de
tareas, los botones y los tooltips están por hacer**: son la Fase 5.

`flipper_izq.png` es el derecho reflejado por código.

**El fondo de escritorio NO lleva la paleta de la mazmorra.** Tiene su
propia paleta de 32 colores. Es cáscara, no contenido. Cuantizarlo lo
destruye.

Sin usar de momento: `target_escudo.png` y `target_lapida.png`, porque el
canto del target es un dial vivo y se dibuja por código. Vuelven cuando el
número se quede quieto.

### Perspectiva

Los objetos se dibujan **mirando al jugador**, como los sprites de un RPG
cenital. El suelo se ve desde arriba, los objetos están de pie hacia la
cámara. No es cenital puro, y es a propósito: es lo que hace Peglin y es más
legible.

### Paleta

La fuente de verdad es `render/paleta.gd`, con 33 colores y una capa de
alias por uso. Familias:

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

### Pixelart, detalles que ya nos han mordido

- **La bola no se ajusta a la rejilla.** A 1500 px/s tiritaría. Los sprites
  estáticos sí se ajustan; la bola se dibuja con subpíxel.
- **La calavera llameante flota**: necesita desplazamiento vertical propio
  en vez de alinearse al suelo.
- **Los jefes no están a la misma escala entre sí**: el rey ogro está
  sentado y ocupa a lo ancho, los otros dos de pie a lo alto. Encuadre y
  desplazamiento propios por jefe.

### Proporciones contra una máquina real

Mesa de 20,25 pulgadas = 400 unidades, o sea 19,75 px por pulgada.

| Elemento | Real | En unidades |
|---|---|---|
| Bola | 1,06" | 21 |
| Bumper | 3" | 59 |
| Drop target (cara) | 1,5" | 30 |
| Flipper | 3" | 59 |

Sirve para detectar elementos mal dimensionados, no como norma: el flipper
está a 64 a propósito.

---

## Arquitectura

```
sim/       física y reglas, sin dependencias del motor
render/    dibujado y escenas
ui/        la cáscara: paneles fijos del sistema operativo falso
data/      reliquias, enemigos, mesas en JSON
assets/    sprites procesados
tests/     prueba_sim.gd
```

`sim/` no sabe que existe un motor: la física es testeable sin abrir
ventana y las pruebas corren en headless.
