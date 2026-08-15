# INVENTARIO_HOJAS.md — qué es cada hoja generada

Registro de qué hoja de `C:\Users\Daniel\Desktop\Sprites` (fuera del repo)
mapea a qué asset. Se actualiza al cerrar cada tanda, **siempre**, antes de
tocar `ESTADO.md`. Sin esto, cada sesión nueva tiene que volver a adivinar
qué es cada PNG mirando miniaturas — ya pasó una vez y costó media sesión.

Las hojas se identifican por su nombre de fichero (`ChatGPT Image <fecha>,
<hora>.png`) o por su UUID si vienen sin nombre. No se renombran en
`Desktop\Sprites`: este fichero es el índice.

---

## Tanda del 9 de agosto — integrada, sesión "arte de IA de la cáscara"

Diez hojas. Todas procesadas e integradas esa sesión (ventana, título,
barra de tareas, Inicio, botones, iconos, tres fondos por acto, enemigos,
jefes, reliquias, mesa). Ver `ESTADO.md` histórico y `CLAUDE.md` para el
fallo del magenta que salió de aquí. No hay mapeo hoja-a-hoja detallado de
esta tanda porque se hizo antes de que existiera este fichero.

**Recuperada una, la de objetos de mesa** (Fátima, agosto): el prompt entero
está transcrito en `assets/GUIA_ESTILO.md`, con la tabla de los nueve objetos
mapeados a sus ficheros. Es una rejilla 3×3 y da `bumper_gargola`,
`bumper_engranaje`, `target_lapida`, `target_escudo`, `poste_goma`, `drenaje`,
`girador`, `flecha_on` y `flecha_off`. **Y trae una pregunta abierta**: pide
perspectiva cenital pura, que es lo contrario de lo que dice `CONTEXTO.md` para
todo lo demás. Sin decidir antes de la siguiente hoja de mesa.

**Y de esa tanda salió también el style guide**, que llevaba desde entonces sin
estar escrito en el repo aunque los tres ficheros de prompts empiezan por
"Following the style guide above". Está en `assets/GUIA_ESTILO.md`, bloque A.

## Tanda del 13 de agosto — 29 hojas, mayoría ruido

Generadas por Daniel tras el primer run ganado, para: recuperar
`cr_espectro` (comido por el fallo del magenta) y completar la segunda
tanda de fondos bugueados (`prompts_cascara.md` §10). **Veintiséis de las
29 resultaron ser redos de assets que ya estaban integrados** —no se sabía
de antemano; hubo que abrir cada una para saberlo—, así que quedan
documentadas aquí para que la próxima sesión no tenga que volver a mirarlas
una por una.

| Hora | Contenido | Destino real | Estado |
|---|---|---|---|
| 15:54:31 | girador, tira de 8 fotogramas | `mesa_anim/girador_*` | **Redo, ignorada** — ya integrado |
| 15:54:35 | 6 placas/carteles | `mesa_placas/placa_*` | **Redo, ignorada** |
| 15:54:39 | props de mesa (antorcha, barril, cajas, rocas, brasero, gancho, rueda, pilar, huesos) | `mesa_props/*` | **Redo, ignorada** |
| 15:54:43 | muros de túnel | `mesa_tunel/tunel_*` | **Redo, ignorada** |
| 15:54:48 | rejas de túnel | `mesa_tunel/tapa_*` | **Redo, ignorada** |
| 15:54:53 | animaciones: portal morado, antorcha, reja abriéndose | `mesa_anim/*` | **Redo, ignorada** |
| 15:54:59 | marco de ventana, piedra remachada, 9 piezas + 3 botones | `ui/ventana` o similar | **Redo, ignorada** |
| 15:55:03 | otro marco 9-piezas, piedra oscura | `ui/dialogo` o similar | **Redo, ignorada** |
| 15:55:07 | bolas (canicas), 3×3 | `bolas_64/*` | **Redo, ignorada** |
| 15:55:11 | **criaturas peek 3×3, hoja cuadrada 1254×1254** | `criaturas_64/*` | **USADA.** Las 9 regeneradas, incluida `cr_espectro` intacta |
| 15:55:17 | criaturas peek 3×3, hoja 1536×1024 (variante) | `criaturas_64/*` | Descartada a favor de 15:55:11 (celdas cuadradas, mejor encaje) |
| 15:55:22 | iconos de herramienta (alicates, cuerda, engranajes...) | `reliquias2/*` o similar | **Redo/nueva, ignorada** — no pedida esta tanda |
| 15:55:27 | piezas mecánicas (rueda, muelle, aceitera...) | `reliquias2/*` | **Ignorada** |
| 15:55:31 | objetos de reliquia (daga+pergamino, libro, jaula...) | `reliquias2/*` | **Ignorada** |
| 15:55:35 | panel metálico 9-piezas | `ui/*` | **Redo, ignorada** |
| 15:55:57 | panel metálico 9-piezas (duplicado) | `ui/*` | **Redo, ignorada** |
| 15:56:04 | ventana azul 3×3 (variante "inactiva") | `ui/ventana` §13 | **Ignorada** — no se pidió esta tanda |
| 15:56:08 | botones min/max/cerrar ×2 estados | `ui/botones/*` | **Redo, ignorada** |
| 15:56:12 | panel metálico 9-piezas (duplicado) | `ui/*` | **Redo, ignorada** |
| 15:56:16 | barra Inicio con cascabel, 2 estados | `ui/inicio/*` | **Redo, ignorada** |
| 15:56:20 | iconos de escritorio 3×3 | `ui/iconos/*` | **Redo, ignorada** |
| 15:56:37 | **rota / bloques de color plano sin textura** | — | **Descartada, generación fallida** |
| 15:56:42 | barra de progreso (canal + relleno azul/rojo) | `ui/progreso/*` | **Redo, ignorada** |
| 15:56:48 | cursores (flecha, reloj de arena, combinado) | `ui/cursor/*` | **Redo, ignorada** |
| 15:56:53 | fondo colina limpio, sin glitch | `shell/fondo_acto1` | Ignorada (duplica lo que ya hay) |
| 15:56:58 | **fondo colina + puerta, banda de cielo desincronizada** | `shell/fondo_acto2_a.png` | **USADA** |
| 15:57:06 | **fondo colapso morado completo** | `shell/fondo_acto3_a.png` | **USADA** |
| 15:57:13 | fondo colina limpio | — | Ignorada (casi idéntica a 15:56:53) |
| 15:57:18 | fondo colina limpio | — | Ignorada |
| 15:57:23 | fondo colina limpio | — | Ignorada |
| 15:57:28 | fondo colina limpio | — | Ignorada |
| 15:57:45 | **fondo con solo el cielo colapsado en bandas, colina intacta** | `shell/fondo_acto3_b.png` | **USADA** |
| 15:57:50 | **fondo con césped congelado en tile repetido** | `shell/fondo_acto2_b.png` | **USADA** |
| 15:57:55 | **fondo con franja negra de pantalla desincronizada** | `shell/fondo_acto3_c.png` | **USADA** |
| ce03e8a8 (UUID) | arcos de entrada de túnel (5 variantes: calavera, boca, reja, pinchos, liso) | `mesa_tunel/tunel_entrada` o similar | **Nueva, ignorada** — no pedida esta tanda |

**Resultado neto de las 29:** 6 PNG usados (1 hoja de criaturas → 9 sprites,
5 hojas de fondo → 5 fondos), 1 hoja rota descartada, 22 ignoradas por ser
redos de algo ya integrado o contenido no pedido esta tanda.

**Pendiente real que sigue sin generar:** la bandeja del reloj (`bandeja_reloj`,
§11 de `prompts_cascara.md`) y los tres iconos de bandeja —separador,
altavoz, sin-red— (§12). Ninguna de las 29 hojas los trae. Si Daniel los
genera, van aquí en su propia fila cuando lleguen.

**Código sin conectar:** los 5 fondos nuevos existen como PNG pero
`render/nodo_cascara.gd` sigue eligiendo una sola textura fija por acto
(`_fondos_acto`, línea ~89-92). Hace falta un array de variantes por acto y
un sorteo al entrar en el escritorio. Detalle en `ESTADO.md`.

## Tanda del 13 de agosto (2) — criatura de fuego candidata a coleccionable, generada con Claude Design

No es una hoja de `Desktop\Sprites`: se generó con Claude Design (herramienta
externa, no el generador de IA habitual) a petición de Fátima, como un
sprite sheet de 8 fotogramas en una fila (512×64, 64×64 por celda), en RGBA
con alfa real — no magenta, a diferencia de todas las hojas anteriores.

**Qué es de verdad:** una criatura de fuego que vivirá dentro de un cascabel.
Fátima confirmó que **la imagen es el coleccionable** — no decoración de
mesa. Primer intento de esta sesión la trató como elemento ambiental
(`mesa_anim/`, nombre `brasa`): **mal categorizada, corregido.** Los 8 PNG
que se llegaron a copiar ahí (`mesa_anim/brasa_1..8.png`) se han borrado.

| Contenido | Destino actual | Estado |
|---|---|---|
| Cascabel de piedra con criatura de fuego dentro (ojos visibles en la llama), tira de 8 fotogramas | `assets/_pruebas/cascabel_brasa/` | **EXPLORACIÓN, sin integrar** |

Dentro de esa carpeta de prueba: `original_01..08.png` (sin cuantizar, tal
cual la entregó Claude Design), `cascabel_01..08.png` (cuantizados a la
paleta y limpiados — sal, motas, ruido de borde de 1px), `_comparacion.png`
(original vs. procesado vs. `farol`/`vela` reales, mismo fondo y escala) y
`_vista_previa_cuantizada.png`.

**Hallazgo de la comparación:** el original sin cuantizar desentona —
degradado de render 3D contra el sombreado plano de las reliquias reales.
El cuantizado se acerca pero el contorno sigue más redondeado que el de
`farol`/`vela`, y **no es ruido de recorte**: se corrió limpieza completa
(sal=1 en 8 frames, motas=0, borde=0) y no hay nada que arreglar — la
redondez es la forma en que la IA dibujó la silueta, no un defecto. Arreglarlo
de verdad pide o aceptar el estilo más suave para este coleccionable, o
regenerar/retocar el contorno a mano.

Se procesó con una reimplementación local de `procesar.py` (mismo código de
paleta y cuantización Lab, copiado literal) porque el sandbox de esa sesión
no tenía `scipy` ni red para instalarlo — el `procesar.py` real no se pudo
correr tal cual. Se usó el alfa real del PNG como máscara en vez de detectar
magenta (más fiable, dado que no había magenta). **Pendiente:** confirmar
con el `procesar.py` oficial en máquina local que da el mismo resultado.

**Pendiente real, para la próxima sesión de assets:** decidir destino
definitivo (¿`reliquias/`? ¿carpeta nueva de coleccionables si esto no es
una reliquia normal?) y estilo de borde (aceptar o regenerar), y solo
entonces mover de `_pruebas/` a su carpeta final y conectar el nodo que lo
usa.

## Tanda del 14 de agosto — sin hojas nuevas: reparación medida dentro del juego

No entró ni una hoja de `Desktop\Sprites`. Lo que se hizo fue **auditar los
272 PNG con detectores y luego MIRARLOS dentro de Godot** (sesión remota con
ventana virtual; receta en `CLAUDE.md`, "Godot"). 36 ficheros tocados.

| Qué estaba mal | Dónde | Cuánto |
|---|---|---|
| **Halo de magenta** del recorte, pegado al contorno | `ui/iconos/` (9), `ui/cursor/` (3), `ui/botones/` (6), `ui/inicio/` (2), `ui/dialogo/` (2) | 717 px |
| Sal de cuantización y verdes/rosas sueltos | los 3 cursores | 34 px |
| Sal de cuantización | 6 de `reliquias/`, 2 de `reliquias2/`, 3 de `criaturas_64/` | 28 px |
| Interior comido | `ui/cursor/`, `ui/iconos/` | 34 px |

**Por qué el halo seguía ahí:** `ui/iconos` y `ui/cursor` **nunca pasaron por
`procesar.py`**. Se ve sin abrirlos: el 100 % de sus píxeles está fuera de la
paleta de 33. Ningún paso de recorte les reescribió el alfa, así que el fondo
se quedó pegado al contorno mezclado con el borde del dibujo. Se ha quitado
por tono (magenta 282-345°) exigiendo además que el píxel sea MÁS magenta que
sus vecinos sanos, para no comerse un violeta pintado a propósito. Comparado
antes/después icono por icono y luego en captura del juego.

**`cr_espectro` ya NO está roto.** La hoja de criaturas del 13 de agosto
(15:55:11) lo regeneró entero y nadie lo había vuelto a medir: hoy sale con
interior comido = 0 y motas = 0. Sale de `NO_TOCAR` en `limpiar.py`, y con eso
se cae la "tanda de assets A" del plan.

**Lo que NO se ha tocado, y es a propósito:**

- `shell/fondo_acto3.png` y `fondo_acto3_a.png` llevan 823 px de magenta cada
  uno. **Es el glitch, no un fallo**: son los fondos del acto 3 corrompiéndose.
- Todo `ui/` está fuera de paleta y casi todo está bien: los marcos de nueve
  trozos, la barra, el botón, el título, el tooltip, el diálogo y la barra de
  progreso los genera `fuente.py` con los grises de Windows, que son la
  identidad de la cáscara.
- `ui/fuente_cascabel.png` sale con "223 islas sueltas" en cualquier detector
  de motas. Son las letras. No es un fallo.
- `ui_marco/` (9 piezas) tiene halo y fleco antialiaseado, y **no lo carga
  nadie**. Arreglar arte muerto es ruido: o se conecta o se borra.

**Sigue sin generar, igual que antes:** la bandeja del reloj (`bandeja_reloj`,
`prompts_cascara.md` §11) y los tres iconos de bandeja (§12). La barra de tareas
dibuja su bandeja con `draw_rect` a mano — y ahí estaba, de paso, el reloj
cortado a "14:5" que se ha arreglado esta sesión.
