# ESTADO.md — CASCABEL

Estado vivo. Se lee al empezar la sesión y se actualiza al terminarla.

**Regla de tamaño:** esto no es un registro de cambios. Al cerrar sesión,
resume lo tuyo en dos o tres líneas dentro de "Hecho" y borra el detalle.
Lo que merezca sobrevivir para siempre va a `CLAUDE.md`, no aquí. Si esto
pasa de una pantalla, sobra algo.

---

## PARA RETOMAR ESTO SIN CONTEXTO

Lo mínimo que hay que saber si esta conversación empieza de cero.

**Dónde estamos.** La mesa tiene **dos plantas, y las dos son mesas de pinball
de verdad**. Se sube por el **umbral** y se baja por el **regreso**, los dos por
las franjas de 20 px de fuera de las bandas.

**Y LA PLANTA ALTA ESTÁ REHECHA (tanda 0i, 18-ago).** Ya no es una réplica de la
de abajo: dos palas CORTAS con las mismas teclas, **sin slingshots, sin
outlanes, sin carriles de retorno, sin postes, sin giradores y sin targets**, una
ISLA elevada en el centro que solo se alcanza subiendo, DOS TÚNELES por debajo
del tablero, una SUBIDA con cuesta que cruza por encima de un túnel, TRES
BÚMPERES sueltos pegados a las bocas y su ÓRBITA por la franja izquierda. Con
ella, las capas de altura de la tanda 0h dejan de estar apagadas: **no hizo falta
construir ningún sistema, solo encender el que ya estaba medido**.

Batería **499/499** con `assets/` en la caja (sin `assets/`, 20 fallos que son
todos "no existe tal PNG").

**Lo primero que hay que hacer, en este orden y antes de tocar nada:**

    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --import
    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/prueba_sim.gd

**Y LA PUERTA B YA SE HA JUGADO (18-ago).** Daniel la probó y tumbó el
planteamiento, no la construcción: *"es extremadamente fácil drenar e irte de la
zona de caza"*, *"flippers extremadamente cortos"*, y la frase que reordena el
diseño — *"esta fase debería sentirse como un bonus, algo especial, no algo tan
fácil de perder"*.

**Lo que se hizo con eso, y son dos decisiones suyas:**

1. **SALVABOLAS.** Drenar arriba ya no te echa: la mesa vuelve a servir la bola
   por donde entró y la caza solo se acaba por tiempo. El precio de estar ahí
   sigue siendo el reloj del enemigo, que no para.
2. **Palas de 38 a 54**, con los ejes a 136: el hueco baja de 61 px a 24, o sea
   la mitad que abajo. Medido: de tener que salvarle la bola al que aporrea, a
   **cero salvadas** y 6,3 golpes por caza (antes 3,7).

Sigue estando **F1 y luego F3** para subir a mano: el umbral se gana en 3 de cada
100 entradas al racimo, así que por el camino normal la planta alta se ve dos
veces por run y no se puede juzgar.

**El diseño está en `CAZA.md`** (tanda 0i-diseño, 17-ago), con el sistema de
CAPTURA entero. La geometría de §3 ya está construida; lo que queda de esa nota
son las fases de la captura (§2) y las nueve criaturas.

## LA PLANTA ALTA, REHECHA (tanda 0i · 18-ago)

`CAZA.md` §3 construido entero. **499/499**, y la planta de abajo da los mismos
números al decimal: 8,142 s de duración de bola, 120 golpes, huella 16621,1901.

| Lo que se fue | Lo que entró |
|---|---|
| 2 slingshots, 2 postes, 2 giradores, 2 bancos de targets, el racimo | 3 búmperes sueltos pegados a las bocas |
| la zona de palas calcada de abajo | 2 palas **cortas** (38) y dos paredes lisas que mueren en el eje |
| — | la **isla** con su falda por capa, 2 **túneles**, la **subida** con cuesta y la **órbita** por la franja izquierda |
| el andamio de capas de F3 | F3 sube la bola por el umbral a mano (puerta B) |
| **drenar arriba te echaba** | **salvabolas: la mesa te sirve otra bola y sigues** |

**El sistema de capas ya no está apagado**: la isla es una `Plataforma` con
cuatro paredes que solo existen en el tablero, los túneles son `subterranea`, la
subida lleva `velocidad_escape` y `capa_salida = CAPA_ALTA`, y cruza por encima
del túnel hondo sin tocarlo. Cero código de sistema nuevo.

### La avería que se cazó midiendo, y es la de la tanda

Con la pared diagonal muriendo EN el eje de la pala, la bola que baja rodando
llega al final de la pendiente y se encuentra la cápsula del eje como un bordillo
que no puede subir. Se queda ahí, y el rincón es **estable**: la pared la empuja
al campo, el eje hacia arriba, y entre las dos aguantan a la gravedad.

Medido con una sonda de usar y tirar, 60 cazas: **33 bolas muertas, 29 de ellas
en el mismo píxel** —(260,540), el rincón de la pala derecha—. El ball search la
despertaba a los 2 s, así que no era un cuelgue: eran dos segundos de mesa parada
en cada visita, sin decir por qué. Subiendo el codo del muro 12 px (el radio del
eje y cuatro más), el muro pasa POR ENCIMA del eje, la bola no puede tocar la
cápsula y lo primero que se encuentra al final de la pendiente es la paleta.
**Bolas muertas: 33 → 2**, y las dos que quedan son de la planta de abajo.

Y de paso destapó lo otro: antes del arreglo la planta alta no se jugaba nada
—cero entradas a la órbita, a la subida y al túnel hondo en 60 cazas—; después,
105 · 57 · 26. La bola no llegaba a los recorridos porque se moría en la esquina.

### Y la puerta B lo cambió: el bonus (18-ago, después de jugarlo)

El barrido de abajo está hecho contra la pregunta vieja —"cuánto tarda en drenar
el que aporrea"— y **esa pregunta se cayó al jugarlo**. Con salvabolas la caza
dura siempre el tope, así que la duración no informa. Lo que informa ahora, y es
lo que mide el medidor:

    largo  separ  hueco   salvadas   golpes
       46    136   38.8       1.3      3.7
       54    128   16.6       0.0      6.8
       54    136   24.6       0.0      6.3   <- el elegido
       54    144   32.6       0.4      6.5
       64    136    7.0       0.0      6.5

Con 54/136 el que aporrea da 6,3 golpes y 7 recorridos en el bonus, pasa el 37 %
del tiempo por encima de la zona de palas y solo el 21 % metido en una curva. Y
**la mesa no tiene que salvarle ni una vez**, que es lo que pedía Daniel.

Comprobado además contra atascos, que es donde muerde un hueco de 24 px con una
bola de 18: **2 bolas quietas de 60 y en sitios distintos**, cero disparos del
ball search. No hay rincón nuevo.

### Los diales, barridos (`tests/medir_planta_alta.gd`, nuevo) — LA TANDA ANTERIOR

60 cazas por celda, jugador que aporrea. El medidor mide **dos jugadores**, que
es lo que le faltaba a `medir_caza.gd`: una brecha son dos números.

    largo  separ  hueco   dura     drena
       46    130   32.8   18.2 s   pocas   <- la caza no se acaba nunca
       46    144   46.8   12.2 s   33/60
       38    144   60.9    7.6 s   48/60   <- el elegido
       38    158   74.9    6.6 s   49/60

El 46/144 —el mismo hueco que abajo— dejaba al que aporrea **12,2 s arriba, más
que los 8,1 s que dura una bola abajo**: la planta alta salía más blanda que la
de abajo teniendo la pala más corta, porque aquí no hay outlanes.

**Y `arena_desague_medio` salió INERTE**: 50 u 80, el mismo 7,6 s al decimal. Lo
que decide es el hueco central, no lo ancho que sea el embudo. Se queda como
parámetro con la medida escrita al lado, que es más útil que un número mágico.

### Dos fallos que la batería no ve y las capturas sí

Lanzada con `Xvfb` (ver `CLAUDE.md`, "sesión remota con ventana"):

- **El rótulo de la subida a la isla decía "CANON DANO x2"**, a media mesa del
  cañón de verdad. `ETIQUETA_RAMPA` estaba indexada por PREMIO, y la subida paga
  `DANO_FUERTE` igual que el cañón. Ahora va por nombre y dice "A LA ISLA".
- **La planta alta se dibujaba sobre un pozo negro.** `NodoSuelo` pintaba los 660
  px de arriba en hueco *"porque es raíl, no mesa"* — cierto cuando era un
  pasillo, falso desde que tiene palas, isla y túneles. Ahora las dos plantas
  llevan el mismo suelo de piedra y lo oscuro es solo lo que no es mesa: por
  encima del techo y los 12 px que separan las dos plantas.
- Y un tercero de orden: el túnel que pasa por debajo de la isla se dibujaba
  ENCIMA de la losa, o sea como un puente. Ahora hay tres alturas de dibujo:
  túneles, plataformas, rampas.

### Lo del "3-4 s" de `CAZA.md` §6: cerrado, y era la pregunta lo que estaba mal

Se persiguió el objetivo escrito —que el que aporrea drene en 3-4 s— y se llegó a
7,6. Al jugarlo quedó claro que **el objetivo era el equivocado**: buscar que el
malo pierda rápido es diseñar un castigo, y esto es un bonus. `CAZA.md` §6 está
corregido con la medida nueva.

Y `CAZA.md` §7 (riesgo 2) se cumplió **al revés de como estaba escrito**: se temía
que quitar slingshots Y acortar la pala fuese pasarse de castigo; lo medido es que
con los dos puestos la planta alta salía MÁS BLANDA que la de abajo (12,2 s contra
8,1 s), porque al quitar los slingshots se quitaron también los outlanes. Dos
castigos y dos válvulas quitadas a la vez se compensan sin que se vea.

## LA PLANTA ALTA Y LA CAPTURA, DECIDIDAS (tanda 0i-diseño · sin tocar código)

Tanda de diseño, no de código: la planta alta ha salido mal dos veces por
construir antes de decidir. **No se ha tocado ni un `.gd` y la batería sigue
donde estaba.** Sale `CAZA.md`, más punteros en `PLAN.md` §1d y `DISEÑO.md` §5.

**Lo que se ha resuelto, y era lo que bloqueaba: qué se captura.** `PROPÓSITO.md`
§2 (reconstruir el sistema, `RECUPERADO/`) y `DISEÑO.md` §5 (arriba se caza
material de desbloqueo) pedían lo mismo y nadie los había juntado. Se cazan **las
nueve criaturas de `assets/criaturas_64/`**, que llevan desde el 13 de agosto
procesadas y sin que las cargue nadie. Cada una que traes viva es un `.dat` que
deja de estar corrupto, y luego va dentro de tu cascabel en Preparación: **81
cascabeles con el arte ya hecho**.

**Y la pregunta de arte de Fátima —¿hacen falta muchos sprites por ángulo, como
en Pokémon Pinball?— tiene respuesta y es NO.** Pokémon Pinball no es caro por
los ángulos (cada bicho tiene una vista fija y no rota nunca), es caro por 151
criaturas. Aquí son nueve, y el eje correcto no es el ángulo sino el **estado**.

**Ojo, que aquí ponía "cero fotogramas nuevos" y era falso** — corregido el
17-ago al repasar los prompts de verdad. Esa hoja 4×4 de celda 96 es la del
ENEMIGO (`prompts_animacion.md` §1). La de las criaturas es §4: **8 fotogramas
en una fila, celda 64, solo `idle`**. La criatura tiene **dos papeles y necesita
dos hojas** — pasajera dentro del cascabel (§4, lista para generar hoy) y presa
suelta en la caza (§5, escrita ahora: acecho, susto, huida, rendida). Son 9
hojas más, y **van detrás de la puerta B**: si la planta alta no se siente
distinta sin bichos, no se generan nunca.

## `cr_brasa` ANIMADA, CORTADA Y MIRANDO (17-ago) — y sale `anim.py`

**La hoja piloto está hecha y es buena.** Fátima la generó con el prompt de §4
corregido y salió sin arco de piedra, que era lo que había que comprobar. Los 8
fotogramas están en `assets/criaturas_anim/cr_brasa/idle_1..8.png`.

| Qué | Valor |
|---|---|
| Línea de suelo | **y=551 en los ocho** — el prompt lo pedía y salió clavado |
| Alto de la llama | 151 a 200 px en origen; 45 a 60 dentro de la celda de 64 |
| Cambio entre fotogramas consecutivos | **440 a 1.159 px de 4.096**, y el 8→1 es el menor: el bucle cierra |
| Dibujo comido por el recorte | **0 px** (los 11 "agujeros" son magenta legítimo entre lenguas) |
| Colores finales | 10 de paleta, **0 de arcano** |

### Y cortarla destapó dos averías del proceso

**1. `procesar.py --tira N` no vale para una tira de animación.** Parte la hoja
en N columnas iguales dando por hecho que el generador centró cada fotograma en
la suya, y no lo hace: las bases caen a 15,6 / 9,1 / 7,2 / 6,8 / 4,1 / 0,1 /
−4,0 / −9,3 px del centro de su celda, o sea **24,9 px de recorrido = 7,5 px a
tamaño 64**. Un baile visible. El comando que estaba escrito en
`prompts_animacion.md` era ese.

Sale **`anim.py`**: ventana vertical común anclada al suelo, horizontal por el
**centroide de la base** de cada fotograma, y una sola escala. Centrar por la
caja entera tampoco valdría — se llevaría el movimiento de las puntas, que es lo
que se ha pedido dibujar. Y avisa por consola de cuánto cambia cada fotograma,
que es la comprobación que el ojo no hace.

**2. El halo del fondo se vuelve VIOLETA ARCANO al cuantizar.** 61 px de arcano
en una criatura de fuego, y `CONTEXTO.md` reserva ese violeta para lo mágico.
No lo dibujó la IA: el magenta deja un borde a 315° de tono con el fondo a
299,8°, y `procesar.py` corta a 14°. Ensanchar el margen NO lo arregla —de 14° a
28° el arcano baja de 5.585 a 833 px y se come 5.943 px de llama—. Lo que lo
arregla es **sacar los dos violetas de la paleta**: `anim.py` lo hace por
defecto, y `--con-arcano` los devuelve para `cr_espectro` y `cr_sombra`.
Medido: 61 → **0**.

*Probado y descartado, para que no se vuelva a intentar: sangrar el color sobre
el fondo antes de reducir, por si `Image.BOX` metía magenta al promediar RGB y
alfa por separado. Cambia 0 px.*

**Las dos están en `CLAUDE.md`, "Trampas", y la hoja en `INVENTARIO_HOJAS.md`.**

## LA SEGUNDA HOJA SALIÓ MAL, Y LA CULPA ERA DEL PROMPT (17-ago)

`cr_calavera` salió **sin manos, con una hoguera encima, con la silueta del
cráneo cortada por las llamas y con los dientes moviéndose**. Lo cazó Fátima
mirándola al lado de la referencia.

**No es culpa del generador.** La descripción que había escrita para `cr_calavera`
era *"a small skull with a flame burning behind its eye sockets"*, y el sprite
real **no tiene fuego por ningún lado**: medidos sus colores, todos piedra y
hueso —`3A3832`, `55524A`, `7A7669`, `D9BF95`— y **cero rojos**. Esa frase es
del enemigo `calavera_llameante` de §1.

**Las nueve descripciones estaban escritas desde los identificadores, sin mirar
los PNG.** Comprobadas una a una: **tres describen a otro bicho** —`cr_diablillo`
es un gato/gárgola gris sin cuernos ni sonrisa, `cr_espectro` es un blob violeta
de TRES ojos y no un encapuchado— y **tres más se quedan a medias**. Reescritas
las nueve mirando los sprites, en `prompts_animacion.md` §4.

**Y las manos son un problema de los nueve.** Ocho de nueve las tienen agarradas
al borde del arco (solo `cr_brasa` no, que es fuego): **son parte de la pose de
asomarse**, así que al mandar tirar el arco se quedan agarradas a nada y el
generador las borra. Ahora se pide explícitamente que se apoyen en el borde
inferior de la celda — y encaja, porque en la caza la criatura está encaramada a
la plataforma, que tiene borde.

**La regla que sale de aquí, y ya ha quemado dos hojas:**

> En un prompt con imagen de referencia, **gana el texto**. La descripción dice
> QUÉ SE MUEVE, no QUÉ ES. Y un rasgo que no nombras, el generador lo borra.

### Y sale una comprobación nueva: el mapa de movimiento

La hoja mala cambiaba entre 867 y 1.293 px por fotograma — **números tan buenos
como los de la hoja que salió bien**. Contar no basta.

`anim.py` saca ahora `_movimiento.png`: pinta encima del primer fotograma qué
píxeles cambian a lo largo del bucle. En `cr_brasa` se enciende el borde de la
llama y el centro se queda oscuro, que es justo lo que pedía el prompt. En la
calavera se enciende **todo el cráneo, mandíbula incluida**. Se mira contra lo
que decía el prompt, y si se ilumina algo que debía estar quieto, se regenera.

En `CLAUDE.md`, "Trampas", las dos.

## `cr_calavera` CERRADA — con la v3 y `--pulir`, no con la v4 (17-ago)

**La cuarta hoja salió PEOR que la tercera**, y eso destapó lo que estaba
pasando toda la mañana:

| | v3 | v4 |
|---|---|---|
| Línea de suelo | **61 en los ocho** | 60-61: flota |
| Alto | **43-43, variación cero** | 45-46 |
| Tonos de cuerpo | 7 | **8** |
| Reflejo que parpadea | 85 % | **86 %** |

No arregló ninguna de las dos cosas pedidas y rompió dos que ya estaban
perfectas. **No se puede iterar una generación:** cada hoja es una tirada nueva,
no una edición de la anterior. Ajustar el prompt y regenerar no sube una cuesta,
te mueve a otro punto al azar. Lo que funciona es meter todas las correcciones
en UN prompt, sacar **varias hojas de golpe con ese mismo prompt** y elegir. Está
en `CLAUDE.md`.

### Y la v3 se cierra sin generar nada más

La v3 tenía **el dibujo bien** —dos manos de tres dedos, tamaño clavado,
mandíbula con ciclo coherente de 426 a 532 px— y fallaba solo en lo **mecánico**.
Eso sí se arregla con código:

    python3 anim.py hoja.png --n 8 --tam 64 --salida assets/criaturas_anim/cr_calavera/ --pulir 3

| | v3 cruda | **v3 pulida** |
|---|---|---|
| Tonos de cuerpo | 7 | **3** |
| Reflejo que parpadea | 85 % | **34 %** |
| Manchas sueltas | 27 | **0** |
| Trazo más estrecho | 1 px | **3 px** |
| Batería | NO PASA | **PASA ENTERA** |

`--pulir N` hace tres cosas: silueta por mayoría de los ocho fotogramas,
contorno duro al color más oscuro de la paleta, y cuerpo reducido a los N tonos
más usados. **No se le pasa a `cr_brasa`**, que vive del degradado.

Con esto se matiza la regla que había quedado demasiado ancha: **post-procesar
no arregla lo mal DIBUJADO —personaje equivocado, dedos que no caben— pero sí
arregla lo MECÁNICO**, que son fallos de repetición y una máquina los hace mejor
que un generador.

*Y una tonta que costó un rato: di por perdida la versión pulida creyendo que
había perdido el contorno. Lo tenía (luminancia 19,5, más oscuro que el
original); el fondo de la previsualización era casi negro. **Los mosaicos de
revisión van sobre gris medio.***

### Lo que se vio en la tercera hoja, y cómo se llegó aquí

Lo que **sí** arregló, y no es poco:

| | v2 | **v3** |
|---|---|---|
| Manos | un bloque fundido, 2 separaciones | **dos manos, tres dedos gruesos, hueco claro** — medido `[4,4,1,4,5]` |
| Ancho / alto | 59-60 / 41-42 | **60-60 / 43-43**, variación CERO |
| Línea de suelo | 61 | **61 en los ocho** |
| La mandíbula | abría en un fotograma | **ciclo coherente**: la zona oscura va de 426 a 532 px y vuelve |

Y lo que **no**:

- **Los dientes son los dedos de antes.** 10 a 13 dientes con anchuras
  `[4, 2, 1, 7, 3, 3, 6, 2, 3, 3, 1]`. La regla de los 3 px la escribí nombrando
  los dedos, y **lo que no se nombra no se aplica**. Generalizada ahora a
  cualquier detalle repetido, con la cuenta: ancho ÷ 4 = repeticiones máximas.
- **7 tonos de cuerpo** donde la guía pide 3, así que el **85 % del reflejo
  sigue parpadeando**.
- **27 manchas sueltas** parpadeando por el borde, peor que las 22 de la v2.

### Y sale `revisar.py`, la batería que faltaba

Siete pruebas sobre una tira ya cortada —tonos, luz, silueta, tamaño, dónde se
mueve, detalle fino, cierre del bucle— cada una salida de un fallo que ya pasó.
Existe porque di por buena una hoja mala contando píxeles.

Con dos avisos escritos dentro: las pruebas 2 y 4 saltan en `cr_brasa` y **ahí
no es un fallo** —la llama crece a propósito—, y **la batería no sustituye a
mirar la hoja a 10×**, que es lo que cazó las tres malas.

### ⚠ LA SEGUNDA HOJA DE `cr_calavera` TAMPOCO VALE — y yo dije que sí

**Lo de abajo está mal y se deja escrito para no repetirlo.** Di por buena la
hoja con un «es la mejor de las tres» y con un ⚠️ blando sobre el temblor.
Fátima la miró y la tumbó en tres golpes: *«píxeles fuera de zona, dedos bug,
mucho cambio de píxeles en la luz»*. Los tres son reales y los tres se miden:

| Lo que vio | Medido |
|---|---|
| «mucho cambio en la luz» | **el 87 % del reflejo parpadea** — 172 px se encienden alguna vez y solo 23 en los ocho |
| «píxeles fuera de zona» | 116 px de tinta parpadeando **en 22 manchas sueltas** por el borde |
| «dedos bug» | la banda de dedos es **UN bloque fundido** con 2 separaciones |

Y las causas, que no son las que yo había supuesto:

- La luz parpadea porque la hoja usa **8 tonos de hueso** donde `GUIA_ESTILO.md`
  pide 3. Cada tono de más es una frontera más que tiembla.
- Los dedos no se leen por **aritmética, no por dibujo**: ~10 dedos repartidos en
  49 px son 4,9 px por dedo con su hueco. Por debajo de 3 px no hay dedo, hay
  banda gris.

**Probado y descartado como parche:** `anim.py --congelar-arriba 38` deja el
cráneo como una roca y baja el cambio de 333 a 207 px por fotograma, pero
entonces lo único que se mueve son los dedos — le da todo el protagonismo a lo
peor dibujado. **Post-procesar no salva una hoja mala.** La opción se queda en
la herramienta porque sirve para otros casos, con esa advertencia escrita.

De aquí sale el **suelo de legibilidad a 64 px**, en `CLAUDE.md` y en
`prompts_animacion.md` §4: nada por debajo de 3 px de ancho, máximo 3 tonos por
superficie, y el reflejo es una forma fija. **Tres dedos gruesos por mano y dos
manos separadas**, no diez dedos.

**La lección de proceso, que es la que más vale:** conté píxeles, miré el mapa de
movimiento y di el visto bueno sin mirar la hoja a 10× fotograma a fotograma. Los
números decían que la hoja era mejor que las anteriores y era verdad, pero
«mejor» no es «vale». **El juicio de arte lo cierra el ojo de Fátima, no una
tabla.**

### Lo que decía antes, y por qué se quedó corto

Fátima la volvió a generar con la descripción corregida y las tres CRITICAL
nuevas. **Sale bien**, y es la mejor de las tres hojas:

| Qué pedía el prompt | Qué salió |
|---|---|
| Sin fuego | ✅ ni un píxel |
| Cuencas vacías y negras | ✅ |
| Dos manos con dedos en el borde inferior | ✅ vuelven, y era el fallo gordo de la anterior |
| Silueta cerrada, nada la tapa | ✅ |
| Solo se mueve la mandíbula | ⚠️ abre en el fotograma 4, pero el cráneo entero se redibuja |
| Línea de suelo común | ✅ y=459 en los ocho |
| Tamaño estable | ✅ 170-173 px (3 de variación; la llama variaba 49) |

En `assets/criaturas_anim/cr_calavera/`. 16 colores, 0 de arcano.

### El temblor no se arregla con prompts: sale `--estabilizar`

El único punto flojo —que el cráneo se redibuja entero— **no es del prompt**.
Medido: 20-42 % de los píxeles cambian entre fotogramas y la silueta baila entre
377 y 1.841 px, aunque el prompt pedía "pixel-identical". Un generador no sabe
repetir un dibujo ocho veces, y no lo va a saber por insistir.

Descartado que fuera el recorte: cortando a paso uniforme entero en vez de por
centroide sale igual, 49 % contra 51 %.

Se arregla en `anim.py`, con el **fotograma moda**: el color más repetido de cada
píxel a lo largo del bucle es el dibujo que el generador intentaba repetir; cada
fotograma conserva solo lo que se aparta mucho de él. El movimiento de verdad
sobrevive, el ruido de redibujado desaparece. **Y nunca borra tinta** — sin esa
condición se comía las chispas sueltas de `cr_brasa`, que son arte.

Medido: la calavera pasa de 578 a 333 px de cambio por fotograma (87 % de la
tinta vuelve a la moda); la llama conserva su movimiento (68 %).

Está en `CLAUDE.md`, "Trampas". Se apaga con `--sin-estabilizar`.

**Lo que queda:** las siete criaturas restantes, con sus descripciones nuevas de
`prompts_animacion.md` §4. `cr_sombra` y `cr_espectro` con `--con-arcano`, las
demás sin él. Y dos cosas menores de la calavera que se pueden dejar o pulir:
un trazo gris en la sien derecha con una mota roja que no está en la referencia,
y que a 64 px la fila de dedos y la de dientes se leen como una sola banda.

## LOS PROMPTS, REPASADOS — Y LAS CRIATURAS LLEVAN CÁSCARA PINTADA (17-ago)

**El repaso ha cazado una trampa que se habría comido la hoja piloto.** Está
entera en `CLAUDE.md`, "Trampas".

Las nueve `assets/criaturas_64/*.png` **no están dibujadas solas**: llevan un
arco de piedra con interior oscuro, y varias con zarpas agarradas al borde. El
inventario las apuntó como *"criaturas peek 3×3"* y alguien leyó "peek" como
"dibujada sola"; quiere decir asomándose **por algo**, y ese algo está pintado.

Medido: **337 px (13,6 %) idénticos en las nueve, y dibujan el anillo exterior**.
Borrarlos **no cambia la caja** (59×48 antes y después), porque cada hoja sombreó
su arco distinto: **no se quita con máscara y `limpiar.py` no lo arregla.**

Tumba tres cosas escritas, y ninguna daba error:

1. **El prompt de §4 se contradecía**: adjuntaba una de esas PNG como *"exact
   reference"* y a la vez ordenaba *"no bell, no circular outline of any kind"*.
2. **La combinatoria de 81** (`PROPÓSITO.md` §3): el arco es gris, así que sobre
   `casc_hueso`, `casc_vidrio` o `casc_runas` canta.
3. **"La cáscara rueda, la criatura no"** (`DISEÑO.md` §4): al girar, el arco
   pintado se queda quieto y la costura se parte.

### Y preguntando por la ranura, Fátima destapó lo de verdad importante

*«Los cascabeles ya dibujados tienen una rejilla muy pequeña, ahí no va a caber
ningún peek.»* No cabe —la ranura es de **48 × 6 px**— pero al ir a medirlo salió
el motivo de fondo, y es aritmética:

| Dato | Dónde | Valor |
|---|---|---|
| Radio de la bola | `sim/parametros_mesa.gd:12` | `radio_bola = 9.0` → **18 px** |
| Sprite y escala | `render/vista_mesa.gd:1340` | `bola.png` de 24, escala 0,9 |
| La ranura a tamaño de mesa | factor 0,28 | **13,5 × 1,7 px** |

**A 18 px de una bola solo se lee el color y el patrón.** Probado perforando la
ranura y componiendo ojos de colores debajo: a 8× queda bien y a tamaño real no
existe. O sea que **el sistema de dos capas de `DISEÑO.md` §4 no puede devolver
nada en la mesa**, se haga como se haga.

**Y nada está comprometido:** `vista_mesa.gd:236` carga `assets/mesa/bola.png` y
punto — ni `bolas_64/` ni `criaturas_64/` las toca ninguna línea de código.

**Las tres decisiones de Fátima, 17-ago:**

1. **Las nueve cáscaras se quedan como están.** No se regeneran: a 18 px
   identifican de sobra por color y patrón.
2. **La criatura no se dibuja nunca sobre la bola.** Vive a 64 px en la interfaz
   (Preparación, `RECUPERADO/`, tooltips, la captura) y suelta por la planta alta
   durante la caza.
3. **Las 81 combinaciones pasan a ser de interfaz**, compuestas en un panel a 64
   donde hay sitio, no metidas por una ranura de seis píxeles.

Escrito en `DISEÑO.md` §4, `PROPÓSITO.md` §3, `CLAUDE.md` "Trampas" y el ⚠⚠ de
`prompts_animacion.md` §4.

**Y sale gratis un argumento a favor de la caza que no teníamos:** es el único
momento del juego en que ves lo que coleccionas a un tamaño en el que se lee.

**Lo que hay que generar, entonces:** las nueve criaturas **solas, sin arco**
(`prompts_animacion.md` §4), que es lo que Fátima propuso como `brasa_peek` sin
bola. Ya no para meterlas dentro de nada — para la interfaz y para la caza.

**Lo demás del repaso:** los comandos de `procesar.py` de los prompts están bien
(`--tam`, `--tira`, `--filas`, `--nombres` existen y hacen lo que dicen), y
`GUIA_ESTILO.md` no necesita tocarse. Se añade `prompts_animacion.md` §5 (la
presa) y `prompts_musica.md` §6b (la captura: dos estados por stems de `caza` y
tres puntadas, una de ellas recortada de `recuperado`).

**Y una decisión de Fátima sobre cómo se prueba:** *«si es de prueba vale, pero
no quiero cosas aleatorias para probar»*. El objetivo de la puerta B pasa a ser
determinista — `cr_brasa` plantada en la plataforma, tres impactos siempre, caza
abierta con tecla de depuración. Está en `CAZA.md` §5.

**La captura no resta vida, sube MIEDO**, y el túnel es la pieza que la hace
juego: mientras la criatura está debajo del tablero la pierdes de vista y el
miedo drena, así que no se juega a acertar, se juega a taparle las bocas.
Capturar **acaba la caza** (esa es la decisión), y luego **hay que bajarla viva
por el regreso** — que ya está medido llegando a una pala 60 de 60, a 211 px/s
y 292 ms, y que hoy no significa nada.

**Las dos decisiones de tacto de la tanda, y las tomó Fátima:**

1. **Palas cortas, no "sin palas".** Descartó la planta alta sin palas: *«no
   tenemos habilidades para controlar el resto de la mesa, y añadirlas con más
   botones abre mucho la complejidad de lo que es un pinball de dos teclas»*. Y
   dio la razón de la pala corta: *«pasa de ser random a skill»*. Como arriba
   drenar cuesta la caza y no vida, el hueco entre palas de arriba **es** el
   reloj de la caza; los 20 s son el techo.
2. **La planta de abajo se congela y se atenúa** mientras juegas arriba.

Y de ahí sale la que más se nota por menos trabajo: **fuera los slingshots**.
Un slingshot mantiene viva una bola que ya habías perdido, y patea al azar.
Sin él, la bola que se va por el lado está muerta. Es borrar dos nodos.

**La medida que cierra la geometría, y sustituye a "el hueco será de X px":** un
jugador que aporrea drena arriba en 3-4 s y uno bueno llega al techo de 20. Hoy
son 5,2 s de media y 52 de 60 acaban drenando, ninguna por tiempo: **la brecha
no existe**.

**Riesgo escrito antes de tropezar:** el 3 % de apertura de la caza ya estaba
anotado como dial, pero ahora importa más — una caza de cuatro fases hay que
aprenderla, y no se aprende lo que ves dos veces por run. Se decide la
frecuencia ANTES de construir las fases.

## CAPAS DE ALTURA: EL SISTEMA, Y NI UN NÚMERO MOVIDO (tanda 0h)

La mesa deja de ser plana, y lo importante de la tanda es lo que NO ha pasado.

**Lo que hay.** Una bola tiene un nivel (`Bola.capa`) y un colisionador solo
existe en los suyos (`Colisionador.capas`, y también `Flipper.capas`). Con eso
salen casi solas las cuatro piezas que Daniel pidió: **plataforma** (una región
con borde, `sim/plataforma.gd`; salirte del borde es caer), **túnel** (el mismo
spline con `subterranea`, que se dibuja oscuro y se traga la bola), **cruces**
(una boca elevada no engancha a una bola del tablero) y **rampas que no
llegan**.

**La velocidad de escape no es una escalera de tres casos, es energía:**

    v(recorrido)² = v_entrada² − (velocidad_escape · 0,6)² · recorrido / largo

y las tres bandas de `PROPÓSITO.md` §6 —no llegas / coronas justo / limpia— caen
de ahí sin fronteras escritas a mano. Medido, con escape a 1000: al 56 % vuelve,
al 64 % corona a 205 px/s, al 120 % sale a 1024. Y **la velocidad se calcula
desde la distancia, no se acumula**: sin eso, subir y volver a bajar devuelve un
número parecido en vez del mismo, y la rampa deja de ser determinista.

Fallar tiene dos formas y es **por rampa**: un tubo (`abierta` false) te devuelve
por donde entraste; un carril te **suelta al tablero**. Las dos avisan por
`rampa_fallada`, y la segunda además por `bola_cayo`, que es el MISMO evento que
salirse de una plataforma.

### Lo que de verdad había que medir

Todo esto entra **apagado**: máscaras en `TODAS`, cuesta a 0, `plataformas`
vacía, las dos bocas de cada rampa en el tablero. Y está comprobado, no supuesto
— `tests/medir_capas.gd` guarda la referencia medida ANTES de escribir una línea
y la reproduce después:

| Qué | Antes | Después |
|---|---|---|
| Duración de bola (60 bolas) | 8,142 s | **8,142 s** |
| Reparto de drenaje | 60 por el centro | **igual** |
| Golpes por entrada al racimo (240) | 3,09 | **3,09** |
| Huella (duraciones + posiciones) | 16621,1901 | **16621,1901** |
| `medir_caza.gd` entero | — | **idéntico línea a línea** |

Batería: **497/497** con assets. Son 15 pruebas nuevas (`_prueba_capas`), y la
primera de todas comprueba que nadie haya restringido una capa por su cuenta:
una máscara puesta sin querer no da error, deja a la bola atravesando una pared.

### PARA VERLO: F1 Y LUEGO F3

**El sistema entró apagado, así que la mesa se ve EXACTAMENTE igual que ayer**, y
eso confundió a Fátima con razón: parecía que no se había aplicado nada. Un
sistema que no se puede tocar no se puede juzgar, así que hay una tecla:

> **F1** enciende la depuración y **F3** monta el andamio de capas en la
> **planta alta**. Se sube por el umbral y ahí está: un carril con cuesta que
> lleva a una plataforma, la plataforma con su borde, y un túnel que cruza por
> debajo del tablero.

Va en la planta alta a propósito, que es la que ya está rechazada y se tira
entera en 0i: **la planta baja no se toca**, y por eso la huella de la mesa
sigue clavada. No se monta al empezar y no se llega a ella jugando: es banco de
pruebas, igual que F2 con la multibola.

### Y SE HA MIRADO DIBUJADO

Con display virtual, en una mesa de prueba de usar y tirar que no va al repo:
plataforma con sombra, túnel oscuro por debajo del tablero y carril con cuesta.
La captura está en la conversación. `VistaMesa` dibuja ya plataformas (relleno
de piedra, borde marcado y sombra proyectada) y túneles.

### Lo que NO está

- **No hay barra de CARGA** (`PROPÓSITO.md` §6). Duplicar daño cuatro segundos
  se pasa por `medir_daniel.gd` antes de tocar la mesa, y ese medidor todavía no
  sabe jugar con N bolas
- **No suena nada al caerse.** `bola_cayo` y `rampa_fallada` no tienen wav:
  meter una clave nueva sin generar el sonido en `sonidos.py` pone la batería en
  rojo. Es media tanda de Sonnet
- **Ninguna geometría usa el sistema.** Es a propósito y es el orden que decidió
  Daniel; la mesa de verdad se rediseña en 0i

## FUERA LOS PINES: LA PLANTA ALTA ES UNA MESA (tanda 0g)

Dos correcciones de Daniel, las dos jugando o mirando, y las dos cambiaron la
tanda entera.

**La primera:** *"el mapa tiene que ser jugable por la zona de las rampas, no el
límite de techo que tenemos"*. Estaba escrito desde el principio y lo habíamos
pasado por alto — `DISEÑO.md` §7 lista un tiro llamado **umbral alto** que "abre
el modo de caza" y §5 remata con *"y le da sentido a la zona alta, que hasta
ahora era un pasillo"*. Pasillo era literal: por encima del arco no había un solo
colisionador.

**La segunda, sobre el campo de pines que monté a la primera:** *"el pachinko es
literalmente que caiga la bola, y que luego no pase de la primera línea"*. Es el
diagnóstico exacto y se ve en la física: una rejilla es un **comedor de energía
pasivo** —la primera fila se lleva la velocidad y el resto es caída—, así que no
hay tiro, hay embudo. **Los pines están fuera del juego entero**, arena y bóveda.
Lo que hace que una zona de pinball se juegue son palas.

### Lo que hay montado

La planta alta es una mesa pequeña de verdad, y su zona de palas está **calcada
de la de abajo a propósito**: esa zona costó tres sesiones de averías —la bola
acuñada en el inlane, el slingshot que pateaba por la espalda, el outlane que
tragaba demasiado— y copiarla es heredar los arreglos.

- **Dos palas**, con las MISMAS teclas que las de abajo. Es lo que hace una
  máquina real con un flipper superior: no se aprende un control nuevo, se
  aprende una mesa nueva. Y no hay ambigüedad, porque el umbral no traga con
  multibola y las dos plantas no se juegan a la vez
- Slingshots, postes, carriles de retorno, dos giradores y outlanes
- **Un racimo propio** (`_racimo` es ahora una función: los dos racimos heredan
  la corrección de la cara de entrada)
- **Dos bancos de targets, metidos hacia dentro** y no pegados a las bandas:
  por fuera va la órbita, y una boca de recorrido a 20 px de un target se traga
  la bola que acaba de rebotar en él
- **Su propia órbita corta**, bidireccional, por fuera de los bancos. Es lo que
  hace que arriba se APUNTE en vez de aguantar: sin un tiro largo, una mesa
  pequeña es un pasillo con palas
- **Un embudo que lleva al desagüe**, y drenar arriba no cuesta vida: cuesta la
  caza

### Las dos franjas muertas, que las cazó Daniel mirando el dibujo

Entre la pared de cada banda y el borde de la mesa quedaban **20 px sin usar**,
de arriba abajo de las dos plantas. Son 20 px para una bola de 18: **un carril
exacto**. Ahí van ahora los dos recorridos que unen las plantas — el umbral sube
pegado a la derecha y el regreso baja pegado a la izquierda, como los habitrails
de alambre de una máquina de verdad. Y de paso se arregla otra cosa: cruzando por
dentro, esas curvas se dibujaban encima del racimo y de los targets.

### La caza ya no es un temporizador

**Se acaba de dos maneras: drenando arriba o agotando el tiempo.** Con la versión
de pines solo existía la segunda, y por eso daba igual lo que hicieras. Ahora
aguantar la bola en la planta alta es la misma habilidad que abajo, y el tiempo
(20 s) es el TECHO, no el final.

### Medido

| Qué | Valor |
|---|---|
| Se abre la caza | **3 de cada 100 entradas al racimo** |
| Golpes por caza (jugador que solo aporrea) | 8,3 de media, 24 el mejor |
| Dura | 5,2 s con ese jugador; el tope son 20 |
| Y acaba | **52 de 60 veces por DRENAR arriba**, ninguna por tiempo |
| Al volver, llega a una pala | **60 de 60** |
| Y llega a | **211 px/s · 292 ms** (un humano reacciona en 250) |

Ojo con el 292: con la salida a 0,35 y la boca 20 px más abajo salían **197 ms**,
por debajo del umbral humano, que es exactamente el fallo que tenía el cañón
antes de ablandarlo. Está ajustado contra el cronómetro, no a ojo.

### Y lo que Daniel decidió después de verla

Tres cosas, y las tres mandan sobre lo siguiente:

1. **La planta alta no puede ser una réplica.** Lo es: su zona de palas está
   calcada de la de abajo. Lo que pidió: *"diferente diseño, bumpers, zonas,
   plataformas, túneles"*
2. **Capas de altura**, como plataformas, y **físicas de rampas que no llegan**.
   Lo segundo ya está diseñado y sin construir en `PROPÓSITO.md` §6
   (`velocidad_escape`); lo primero es un sistema nuevo y está escrito ahora en
   `PLAN.md` §1c
3. **La altura de la mesa se puede subir** si hace falta: *"si ha de aumentarse
   la altura máxima del pinball, se aumenta"*. El ANCHO no, que de él cuelga el
   hueco entre palas

Y el orden lo decidió él: **primero el sistema de capas, después la geometría.**
Es lo único que no se puede hacer al revés.

### Los márgenes, medidos

Siguen sin usarse, y esto es lo medido sobre la mesa de hoy. Las franjas de 20 px
de fuera de las bandas solo están ocupadas por tramos:

| Franja | Ocupado por | Libre |
|---|---|---|
| Izquierda | el regreso, de y=672 a 1030 | **y=150 a 670 y de 1030 abajo** |
| Derecha | el umbral, de y=730 a 258 | **y=150 a 258 y de 730 abajo** |

Son unos **1.470 px de carril muerto, más de lo que hay usado**. Una bola mide 18
y la franja 20: es carril exacto, no margen.

### Lo que NO está

- **NO HAY BICHOS ARRIBA.** `DISEÑO.md` §5 dice que la zona alta es donde cazas
  material de desbloqueo. Está el sitio y el modo, no la caza
- **No se ha mirado dibujado.** La cámara debería subir sola —su límite superior
  ya da de sí y la planta alta entra entera en los 540 px visibles— pero eso es
  una cuenta, no una captura
- **`assets/sonido/pin.wav` se queda huérfano**: era el sonido del campo de
  pines. Se puede borrar; el bridge del escritorio no puede
- **El 3 % puede ser muy poco.** Los diales, por orden: `umbral_boca`,
  `umbral_entrada_radio`, `umbral_velocidad_minima`

## EL RACIMO ESTABA DE ESPALDAS (tanda 0f)

`PROPÓSITO.md` §8 pedía un campo de pines en la zona alta porque "la mesa se ve
más pelada que la carpeta de assets". El campo está puesto y funciona. Pero
medirlo contestó a una pregunta que nadie había hecho, y esa es la tanda.

### El campo de pines: hecho, medido y barato

Once pines en dos filas al tresbolillo bajo el arco, entre y=707 y y=736. **La
rejilla se genera**, no se escribe a mano: sale de `pin_paso` y `pin_alto_fila`,
y `_cabe_pin` tira todo pin que no deje 24 px de aire contra lo que ya hay. Por
eso la fila de abajo se abre justo encima del racimo y el campo es simétrico o no
es. La batería vigila el invariante que importa —**por todos los huecos cabe la
bola**, el más estrecho mide 24,1 y la bola 18—, porque tocar un número rehace
la rejilla entera y eso se rompe sin dar error.

- Los pines **no empujan**. Un bumper es un actuador y ya fabricó energía una vez
  (`bumper_rebote`); un pin solo quita, así que la bóveda se vacía sola. Medido:
  600 bolas soltadas dentro **con el ball search apagado**, ninguna atascada,
  salida media 0,72 s
- Pagan 2 de daño, son relleno como el bumper y el girador, y **no suman combo**.
  `pin_suma_combo` está expuesto y apagado: doce toques de una tacada te ponen el
  combo a ×4, y la brecha entre jugar mal y jugar bien es casi toda multiplicador
- Sonido propio, `pin`: 35 ms, el más corto de la mesa, y el que más desafine
  lleva (0,16). Es el que más veces suena de todo el juego

### Y midiendo eso salió lo otro, que es más gordo

El racimo son tres bumpers en triángulo, **dos en una cara y uno en la otra**. Su
comentario decía "esto está medido, no elegido": con uno en la cara de entrada
salían 1,4 golpes por entrada y con dos, 3,7. El número era bueno. **La bola con
la que se midió, no**: se dejaba caer DESDE ARRIBA, y a esta mesa no le llega
nada de arriba. El racimo está en lo más alto que se alcanza, así que todo lo que
entra, entra subiendo.

Medido otra vez, por las dos caras, 40 entradas de cada:

| orientación | de dónde | bumpers por entrada | lo más alto |
|---|---|---|---|
| dos arriba (como estaba) | **desde abajo** | **1,0** | y=863 |
| dos arriba | desde arriba | 4,1 | y=669 |
| **dos abajo (ahora)** | **desde abajo** | **6,3** | **y=704** |
| dos abajo | desde arriba | 1,9 | y=669 |

O sea que una bola que subía al racimo chocaba de frente contra el bumper de
abajo y se volvía por donde había venido. **Un manotazo y a la calle.** Girado
60°, se cuela entre los dos de abajo y rebota contra el de arriba.

Y arrastra la mitad del campo de pines: con el racimo girado la bola sale de él
hasta y=669, o sea que **por fin entra en la bóveda**. Con el racimo como estaba,
no llegaba ninguna ruta de la mesa.

Lo que cuesta, medido en la misma ejecución y con las mismas semillas: la bola
pasa de 1,51 s a 1,67 s por entrada al racimo (+11 %) y el reparto del drenaje se
mueve de 8/92 a 9/91 entre outlane y centro. Nada que toque la tabla.

### LO QUE ESTA TANDA DESTAPA Y NO ARREGLA, y manda en lo siguiente

**A la zona alta no se apunta.** El único tiro repetible de la mesa es el de la
bola atrapada en la cuna, y medido con las dos palas y 21 posiciones de cuna:

- sube a **y=893** de media, y el mejor de 42 llega a **y=751**
- toca **0,1 bumpers por tiro**, o sea ninguno: sube por las bandas, y el racimo
  está en el centro
- y ninguna de las cuatro rutas de recorrido llega tampoco: la órbita saca la
  bola a y=845, el cañón a y=985, el retorno a y=1085 y el platillo a y=784

O sea que el racimo y la bóveda están montados, medidos y equilibrados **en una
parte de la mesa a la que no se puede tirar a propósito**. Eso explica el 265
contra 1999 de daño por bola mucho mejor que el reparto de premios: el perfil
"racimero" da por hechos 16 golpes de bumper por bola, y la mesa entrega uno por
entrada y casi ninguna entrada. **Nadie puede ser el racimero.**

No se arregla midiendo: es geometría fina, y `ESTADO.md` ya dice lo mismo de las
bocas ("alinear cada boca con la línea de tiro de su pala se hace jugando"). Va
de primero en "Siguiente".

### El cedazo, probado y apagado

Antes de llegar a lo del racimo se probó bajar una fila de pines a y=875, que es
la banda que cruza todo lo que baja. Cobraba —10 de 21 tiros tocaban pin— pero
**el precio era tapar dos tiros**: los pines de los extremos caen justo debajo de
las bocas del retorno y del cañón (y=790), y el mejor tiro pasaba de y=751 a
y=884. Se queda `pin_cedazo_filas` en 0. Para encenderlo haría falta que
`_cabe_pin` sepa de **pasillos de tiro** y no solo de bocas.

### Lo que NO está y hay que saberlo antes de jugar

- **`pin.wav` no está generado en el repo de Daniel**: `python3 sonidos.py`
- Los pines se dibujan **por código**, tres rectángulos, sin sprite. Con 10 px de
  diámetro un sprite no daría más, y el campo se genera: el arte tendría que
  volver a cortarse cada vez que se toca un número
- **Nadie ha jugado esto.** El racimo girado cambia el tacto de la mitad de
  arriba de la mesa, y eso no se lee, se juega

## MULTIBOLA: LA MESA YA TIENE N BOLAS (tanda 0e)

`DISEÑO.md` §8 lista cinco ejes de build y el quinto es **Caos: multibola, bolas
extra, aleatoriedad**. Estaba escrito desde el principio y era el único eje sin
una sola línea de código: las nueve reliquias de Caos que había eran nueve
porcentajes con nombre gracioso. **Ahora la mesa tiene bolas de verdad.**

### Lo que se ha montado

**`Mesa.bolas`, un array que nunca está vacío.** Cuando no hay bola en juego
queda UNA, muerta, que es exactamente el estado de antes; por eso `mesa.bola`
sigue existiendo como `bolas[0]` y **ni la vista, ni el combate, ni las 400
pruebas viejas han tenido que reescribirse**. Lo que sí se ha movido de sitio es
el estado que estaba mal puesto: el temporizador del ball search y el "estoy
dentro del girador" eran de la mesa, y con dos bolas eso significa que una le
apaga el aviso a la otra. Viven en `Bola`.

**Choque bola contra bola** (`_colisionar_bolas`), masas iguales y rebote 0,65.
Sin él, la multibola son dos sprites de 18 px atravesándose. **Solo chocan las
bolas libres**: una enganchada a una rampa está en otro plano, igual que las
rampas no colisionan con nada. Y **en un platillo cabe una**: dos dentro salían
disparadas desde el mismo punto y se acuñaban.

**La cámara sigue a la BOLA MÁS BAJA** (`Mesa.bola_en_peligro`). Es lo que no
toca las cuatro reglas ni el escalado entero: se le sigue pasando UNA bola, así
que no hay zoom y el pixelart no hierve. `medir_camara.gd` sigue dando 0 % de
fotogramas sin flipper en plano. **El efecto secundario es la mitad del motivo
de elegirla**: con dos bolas casi siempre hay una abajo, así que durante una
multibola la cámara vive anclada en la banda de las palas.

**Perder una bola con otras vivas no cuesta NADA** —ni vida, ni combo, ni
contraataque—. La señal `bola_drenada` solo salta con la última; las demás
salen por `bola_perdida`, que existe para el sonido y el polvo y para nada más.
Y si caen dos en el mismo subpaso, se cierra UN turno, no dos.

### El eje de Caos, por fin como mecánica

Tres ganchos nuevos, ni un `if` por reliquia, y un prefijo nuevo (`azar_*`:
probabilidades que se suman y contra las que se tira un dado).

| Gancho | Cuándo |
|---|---|
| `azar_bola_extra_recorrido` | al completar cualquier recorrido |
| `azar_bola_extra_banco` | al cerrar un banco de targets |
| `suma_bolas_al_servir` | de salida, cada vez que te sirven bola |

Y la clave que lo convierte en un eje y no en tres reliquias sueltas: `Combate`
publica **`bolas`** en el contexto, así que `cuando: multibola` y `cuando:
bola_sola` ya se pueden escribir en el JSON. Soltar bolas es la mitad de la
build; que las bolas de más CAMBIEN algo es la otra.

Cinco reliquias nuevas (Bifurcación, Proceso hijo, Bomba de procesos, Condición
de carrera, Hilo único). **La bola extra sale por el carril lanzador y sale
disparada a tope**, no aparece en mitad del campo: un lanzamiento a tope engancha
la órbita siempre, así que entra en juego por arriba, dando la vuelta, igual que
la bola con la que empiezas. Cero geometría nueva.

### La decisión que se ha tomado y hay que saber que se tomó

**El eje de Caos pasa a tener 14 reliquias y los otros cuatro siguen con 9.** La
batería exigía que fueran los mismos y se ha aflojado a "al menos nueve"
(decisión de Daniel). Lo que se paga, dicho para poder deshacerlo sabiendo qué se
deshace: **la ruleta sortea por RAREZA, no por eje**, así que Caos pasa del 20 %
al 28 % de lo que se ofrece. Si al jugar sale demasiado, la salida no es volver a
cerrar la prueba: es sortear por eje, o subir los otros cuatro.

### Y SE HA MIRADO JUGANDO, con display virtual, y ha destapado algo

**Lo que se hizo:** arrancar el juego de verdad en la caja (Xvfb + un autoload de
usar y tirar que no va al repo), empezar un run, entrar al primer combate, meter
cuatro bolas y dejarlo 16 s dando a las palas, midiendo fotograma a fotograma
cuántas bolas vivas quedaban FUERA del rectángulo que se está viendo.

**El resultado, y no salía en ninguna prueba:**

| Qué | Medido |
|---|---|
| Fotogramas con dos o más bolas y ALGUNA fuera de plano | **61-67 %** |
| De esas, por arriba / por abajo | **79 / 2** |
| Lo más lejos que llegó a estar una bola por encima del borde | **485 px** |

O sea: **la mesa mide 1300 de alto y por la ventana caben 540**, así que con la
cámara siguiendo a UNA bola las demás se salen por definición, y casi siempre por
arriba —la que está dando la vuelta a la órbita—. Con una bola esto no podía
pasar, y por eso no existía el problema.

**Arreglado, y sin tocar la cámara:** `_dibujar_bolas_fuera()` pone una punta de
flecha dorada pegada al borde por el que se ha ido la bola, en su x y del tamaño
de la bola, y más pálida cuanto más lejos esté. **No es zoom**: alejar la cámara
rompe el escalado entero y la mesa hierve (`CLAUDE.md`). Mirado en las capturas:
se leen.

**Y de paso cayó una trampa vieja con cara nueva:** la primera versión ponía la
flecha a 10 px del canto de la pantalla y NO SE VEÍA, porque la cáscara va en la
capa 5 y la mesa en la 0, así que quedaba detrás de la barra de título. Es
exactamente lo que escondía la bola en lo alto de la órbita. Ahora el margen sale
de `cam.alto_franja_hud`, que es el mismo número que usa la cámara.

### Y está medido lo que se podía medir, que era la mitad importante

**El motor de multibola es EXACTAMENTE NEUTRO con una bola.** Corriendo
`medir_daniel.gd` en la caja, con el motor nuevo puesto y las cinco reliquias
nuevas sacadas del JSON, salen los mismos seis números dígito a dígito que antes
de tocar nada: **462 seco · 729 d/bola · 137 s · 7,6 reliquias · 71 % de vida ·
3 de 5 runs**. O sea que pasar de una bola a N no ha movido el balance ni un
punto, que es justo lo que había que demostrar antes de creerse nada más.

**Y las cinco reliquias nuevas SÍ mueven el balance, y mucho:** con ellas dentro,
el mismo perfil acaba el run con el **97 % de vida** en vez del 71 %, con 835 de
daño por bola y combates de 128 s. Medido, no supuesto.

**No es `condicion_de_carrera`**, que era el sospechoso obvio: quitándola sola el
número se queda en 97 %. **Son las bolas extra**, que vuelan solas y pegan gratis.

**Pero ese 97 % no vale como veredicto, solo como aviso**, y hay que saber por
qué: `medir_daniel.gd` **no sabe JUGAR con varias bolas** —sus perfiles no tienen
física dentro—, así que la bola extra le da todo el daño y no le cuesta ninguna
de las dos cosas que cuesta jugando: repartir la atención y perderlas. De paso se
ha arreglado ahí un fallo de verdad: el drenaje de mentira apagaba solo
`mesa.bola` y dejaba las extra vivas para siempre.

**Conclusión, y manda en el orden del plan:** calibrar el eje de Caos exige antes
que el medidor sepa jugar con N bolas. Va en "Siguiente" 1b, con el rebalance.

### Lo que NO está y hay que saberlo antes de jugar

- **El eje de Caos no está calibrado**, por lo de arriba: las cinco reliquias
  están puestas a ojo y el medidor no puede juzgarlas. **El rebalance con
  multibola va DESPUÉS de la Fase 6**, como el otro.
- **No hay arte de multibola.** Las bolas extra se dibujan todas iguales a
  propósito —una bola extra no es de segunda, pega lo mismo y se pierde igual—
  pero no hay ni contador en pantalla ni sonido propio: la bola extra suena con
  el arpegio del combo, que es un préstamo, igual que las reliquias.
- **Las cinco reliquias nuevas no tienen icono**, y suben a 32 las que no lo
  tienen.

## LA CÁMARA: DOS INTENTOS FALLIDOS Y EL BUENO (REGLA 5)

Daniel, jugando: *"se siente super mal a la hora de ponerse abajo, se
teletransporta"* — y después del primer arreglo, *"sigue siendo brusca al bajar
**en cierto punto**"*. Las dos veces tenía razón y las dos por un motivo
distinto. **Lo caro fue entender que se estaba midiendo el número equivocado.**

### Intento 1: tope de velocidad. Arregló el salto y no la sensación

Las dos garantías duras de `avanzar` —el techo de la barra de título y el suelo
que promete ver dónde cae la bola— se aplicaban DESPUÉS del suavizado, como un
`minf` y un `maxf`. Medido: **113 px en un fotograma, 13.616 px/s**. Se limitó la
velocidad y el salto bajó a 15 px… y seguía sintiéndose mal, porque un tope de
velocidad es **velocidad constante con arranque y parada instantáneos**, que es
lo más mecánico que puede hacer una cámara.

### Lo que de verdad se nota es la ACELERACIÓN, no el salto

Ese fue el cambio de instrumento, y con él se vio todo. `medir_camara.gd` §4 mide
ahora el pico de aceleración con seis bolas de verdad, y ahí estaban las dos
causas:

**(a) El "en cierto punto" era literal.** `suelo_visible` tenía escrito
`if bola_y > alto_mesa - margen_ancla: return alto_mesa`, o sea que al cruzar la
bola la línea de seguridad (y=1000) el suelo garantizado saltaba de ~1150 a 1300
**de golpe, siempre en el mismo sitio de la mesa**. Quitado: la REGLA 2 la sigue
poniendo `objetivo()`, así que no se afloja nada.

**(b) El objetivo dependía de `vy`, y `vy` NO es continua.** El suelo vale
`bola_y + vy × t_ant + margen`, y `vy` salta entero en cada salida de rampa, cada
bumper, cada palazo. **Un objetivo que salta no se puede suavizar sin perder la
garantía**: o la cámara llega a tiempo dando un corte, o va suave y se pierde el
flipper. Probadas las dos, medidas las dos, y las dos se notan.

### El arreglo: que el objetivo dependa solo de la POSICIÓN

`tiempo_anticipacion` pasa de 0,18 a **0**, y lo que se deja de pagar en
predicción se paga en margen: `margen_debajo_bola` de 150 a **300**. La posición
sí es continua, así que el objetivo ya no da ningún golpe.

|  t_ant | margen | Peor salto | Pico de aceleración | Sin flipper |
|---|---|---|---|---|
| 0,18 | 150 | 91,6 px | 1.244.744 px/s² | 0 % | ← como estaba |
| 0,09 | 150 | 36,3 px | 447.208 px/s² | 3 % |
| 0,00 | 150 | 8,4 px | 117.951 px/s² | **8 %** ← se pierde |
| 0,00 | 250 | 7,1 px | 76.637 px/s² | 0 % |
| **0,00** | **300** | **~6 px** | **~68.000 px/s²** | **0 %** ← elegido |
| 0,00 | 350 | 5,4 px | 60.132 px/s² | 0 % |

**15 veces menos salto y 18 veces menos aceleración, sin perder ni un fotograma
de flipper** — comprobado hasta con la caída recta a 1900 px/s, más rápido de lo
que la mesa puede producir. Los 300 px salen de una cuenta: el muelle va por
detrás como mucho `vy × tiempo_suavizado`, o sea 1500 × 0,16 = 240, y 300 deja
holgura.

### Y el suavizado pasa a ser un muelle

`lerp` arranca a tope y frena (tirón al empezar); un tope de velocidad no arranca
ni frena (mecánico). Un **muelle críticamente amortiguado** arranca de cero,
acelera, frena y nunca se pasa de largo. El dial es `tiempo_suavizado` = **0,16
s**, y ahora se piensa en segundos en vez de en un factor que además dependía de
los FPS.

### Las tres redes, y por qué están las tres

1. **Las garantías van en el OBJETIVO** (`objetivo_completo()`, pura y
   comprobable): el muelle sale hacia allí con tiempo y llega suave.
2. **Y otra vez al final, como red**: dentro de la zona muerta la cámara no se
   mueve, así que el objetivo no se aplica — sin esta red la bola se subía detrás
   de la barra de título (lo cazó la batería: 8 fotogramas, hasta 22 px de 24).
3. **Y el tope de velocidad, dormido casi siempre**: el peor fotograma jugando
   mueve ~6 px y el tope está en 21. Existe para lo que el medidor no ve — cuando
   **la BOLA se teletransporta** (se sirve otra, empieza otro combate) el objetivo
   se va al otro extremo de la mesa. Medido en el juego corriendo: **659 px en un
   fotograma**. Con el tope, un barrido de un cuarto de segundo.

**Dos pruebas nuevas** lo cierran: el tope de velocidad y **el pico de
aceleración**, con el techo una orden de magnitud por encima de lo que sale hoy —
es una alarma de que ha vuelto un objetivo discontinuo, no un ajuste de tacto.
Batería **438**, mismos 21 fallos de assets.

**Si aún se siente mal, el dial es `tiempo_suavizado`** (más alto = más cine, más
bajo = más pegada), y el que decide cuánta mesa se ve por debajo de la bola es
`margen_debajo_bola`. Los dos están medidos arriba.

## EL RUN DE DANIEL DEL 15 DE AGOSTO, Y LO QUE DICE

Ganado entero, acto 3, 15 nodos. **Es la primera partida de verdad con el
rebalance dentro**, y sin ninguna reliquia de multibola.

| | Antes del rebalance | Ahora | Modelo (`d-flojo`) |
|---|---|---|---|
| Vida al acabar | 98 % | **90 %** (976/1080) | 71 % |
| Daño por bola | 797 | **1450** | 729 |
| Combate medio | 45 s | **80 s** | 137 s |
| Bolas jugadas | 43 | **72** | — |

**El rebalance ha hecho algo, y se puede decir cuánto:** los combates duran casi
el doble y hacen falta 29 bolas más para ganar el run. Pero **el objetivo era
acabar entre el 25 y el 60 % de vida y sigue acabando al 90 %**, así que el
resultado es exactamente el que anunciaba el barrido: sin comportamientos de
enemigo no hay tabla de números que llegue a esa banda. Es la razón por la que la
Fase 6 existe, ahora medida con un jugador de verdad y no solo con el modelo.

**Y el modelo SIGUE sin ser Daniel, en otra dirección que antes.** Daniel pega el
doble por bola (1450 contra 729) y sus combates duran la mitad (80 s contra 137).
O sea: mata tan rápido que el reloj del enemigo le pega la mitad de veces, y por
eso acaba con más vida que el modelo aunque el modelo esté calibrado. **Lo que le
falta al perfil no es daño, es ritmo**: `medir_daniel.gd` reparte los tiros en el
tiempo como si todos costaran lo mismo. Va con la tanda 1b.

## LAS TRES TANDAS ANTERIORES, EN CORTO

Detalle borrado por la regla de tamaño de este fichero. Lo que sobrevive es lo
que sigue mandando en decisiones de hoy.

**Los cascabeles son elementos, no porcentajes (tanda 2b).** Fátima: *"cambiar de
cascabel es MUY inútil, esto tiene que ser un roguelike progresivo frenético"*, y
tenía razón por arquitectura: montados como bolsa de modificadores salieron
medidos, equilibrados y **completamente invisibles**, porque una bolsa de
modificadores solo sabe producir porcentajes y **para que PASEN COSAS hacen falta
eventos**. De ahí `sim/estados.gd`: veneno, escarcha, brasa, marca y frenesí, que
duran en el tiempo y acumulan. **Es la misma lección que ha traído la multibola**,
y ya van tres veces: lo que no se ve pasar, no existe.

**La capa de Preparación (tanda 2), hecha y medida.** Nueve cascabeles y cuatro
juegos de palas, todo abierto desde el primer día (`DISEÑO.md` §5). Un cascabel
no es código: es una bolsa con nombre que entra por `BolsaReliquias.base` usando
los ganchos que `Combate` ya leía. Las palas sí tocan la física, y por eso
`_montar_combate()` rehace la mesa entera al empezar el run: cambiar de palas
sobre una mesa ya hecha no hace nada.

**Guardado, clics, menú de Inicio y `RECUPERADO/` (tanda 1).** `sim/guardado.gd`
(escritura atómica en `user://`), 22 piezas recuperables, `render/regiones_clic.gd`
y `render/nodo_sistema.gd`. Al cerrar un run —**se gane o se pierda**— se paga
`1 + nodos_superados/5` piezas: que un run perdido también pague es la decisión
entera de la tanda. Lo que se recupera son criaturas (skin) y registros (texto),
así entra la meta-progresión sin reabrir `DISEÑO.md` §13.

**El rebalance, y por qué el modelo mentía.** `medir_balance.gd` juega el run con
un jugador que no completa misiones, así que llega al jefe con la bolsa vacía;
Daniel llega con once reliquias. **No medía un balance flojo, medía a otro
jugador.** `tests/medir_daniel.gd` lo arregla y acaba el run al 99 % de vida
contra el 98 % real. El barrido de vida × ataque dice lo que ya avisaba
"Abierto": **de 20 casillas, ninguna deja el run entre el 25 y el 60 % de vida**,
porque un enemigo con solo vida y un ataque por reloj pega picos, no presión.
**Lo que falta no es un número: son los comportamientos de la Fase 6.** Lo mejor
alcanzable sin ella ya está escrito: vida ×3, ataque ×0,7, curación de reliquias
a un tercio, combate medio de 52 s a **137 s**, y 3 de 5 runs acabados.

**Y la cámara, que tenía dos averías que cazó Fátima jugando** con la batería en
verde encima de las dos: quedaba parada a 45 px del ancla para siempre (los
últimos 45 px de mesa, los del drenaje, no se veían nunca) y el 57 % de los
fotogramas bajos no tenían el flipper en plano. Las dos a 0 %. El detalle está en
`CLAUDE.md`, "Trampas", y `tests/medir_camara.gd` mide `y_actual`, no la
intención.


## Hecho

- **MULTIBOLA.** `Mesa` pasa de una bola a N con choque entre bolas, estado por
  bola y drenaje que solo cuenta cuando cae la última; la cámara sigue a la más
  baja. **414/435 en la caja de la sesión** (los 21 que faltan son PNG que allí
  no están). Ver arriba.
- **La multibola mirada jugando, no deducida.** Con display virtual: 61-67 % de
  los fotogramas con dos o más bolas tenían alguna fuera de plano, casi siempre
  por arriba. Arreglado con flechas en el borde, sin tocar la cámara.
- **El eje de Caos existe.** Tres ganchos de bola extra, el prefijo `azar_*`, la
  clave `bolas` en el contexto y cinco reliquias nuevas. Es el primer eje de
  `DISEÑO.md` §8 que pasa de estar escrito a estar jugado.
- **El cuadro de diálogo del ataque, que era el peor bug que quedaba.** Su
  `relleno` no era un tono plano sino una baldosa con borde, así que al
  repetirse pintaba una **rejilla de ladrillos** por todo el cartel — y ese
  marco solo sale cuando el enemigo ataca. Era el único de los seis recortado a
  mano de una hoja de IA; ahora lo genera `fuente.py` con el mismo perfil
  biselado que los demás.
- **Los carteles del centro se cortaban por el tamaño de letra.** "ESPACIO:
  mantener y soltar para lanzar" salía "…para l", y "MANTÉN A o D PARA ATRAPAR
  Y APUNTAR" igual: a 16 px caben 33 caracteres en los 400 de la mesa y esos
  textos tienen 38 y 35. Ahora `_tam_que_cabe` baja al tamaño que quepa en vez
  de recortar, así que la frase se lee entera.
- **Las tildes, en los datos y en las MAYÚSCULAS.** 52 cambios en
  `data/misiones.json` y `data/reliquias.json` —nombres y textos, uno a uno, no
  buscar-y-reemplazar: "Puntería", "Metrónomo", "El reloj es mío", "daño",
  "cañón", "más", "último"—. Y en la fuente: **la tilde de las mayúsculas iba
  pegada a la letra y en la Í y la É desaparecía del todo** ("CRÍTICO" se leía
  "CRITICO"). Misma regla que la ñ: tilde arriba, fila en blanco, cuerpo
  comprimido a cinco filas.
- **El marco de la ventana de la mesa, que estaba mal montado desde la Fase 5.**
  Se dibujaba con CUATRO marcos de nueve trozos completos alrededor del hueco en
  vez de uno solo sin centro. Un nueve-trozos en una caja más estrecha que sus
  dos esquinas no se encoge: las esquinas se pegan a tamaño completo, se
  solapan entre sí y **sobresalen 4 px hacia dentro del campo por los cuatro
  lados**. Eso era el amasijo de tornillos de las cuatro puntas y lo que le
  comía tablero. Ahora es `NueveTrozos.dibujar_hueco`: un marco, sin relleno.
- **"COMUN" era el identificador del JSON pintado en pantalla.** La rareza, el
  tiro de la misión y el eje de la reliquia compartían una sola tabla para leer
  los datos y para dibujar, y la clave va sin tilde por fuerza. La tele llevaba
  desde la Fase 4 poniendo COMUN, CANON, ORBITA y GOLPE UNICO. Separadas en
  `NOMBRE_*` (clave) y `ROTULO_*` (rótulo): ahora salen **COMÚN, CAÑÓN, ÓRBITA,
  golpe único**.
- **La batería tenía nueve pruebas que no se ejecutaban.** Un mensaje de
  comprobación llamaba a `nombre_rareza()` sobre una `Reliquia`, que no lo
  tenía; GDScript evalúa el argumento aunque la prueba pase, así que abortaba el
  bloque. Eran 312 donde hay 321. Los fallos siguen siendo 13, los mismos.
- **Los textos de la cáscara, mirados de verdad.** Fátima vio en la captura lo
  que yo había dado por bueno. Cuatro cosas, todas del mismo par de causas:
  **la `ñ` se leía como una `n`** (la tilde estaba dibujada pegada a la letra y
  las dos manchas se fundían; la `Ñ` igual), y **tres textos más recortados por
  el `width` de `draw_string`**: la etiqueta "Dirección" del mapa salía
  "Direc", la pestaña de la barra de tareas cortaba el título de "(no
  responde)", y el nombre bajo un icono de reliquia tenía sitio para nueve
  caracteres, así que **41 de las 45 reliquias salían cortadas** — ahora van en
  dos renglones, como un escritorio de verdad, sin salirse por el margen.
  Comprobado todo en captura con la bolsa llena.
- **Assets bugueados, barridos y arreglados mirando el juego.** 36 ficheros.
  El fallo gordo era un **halo de magenta** pegado al contorno de los nueve
  iconos de escritorio, los tres cursores, los seis botones de la barra de
  título, el botón de Inicio y dos esquinas del diálogo: 717 px de fondo que el
  recorte no volvió transparente, invisible en un visor y evidente dentro de
  Godot. Además, sal de cuantización y verdes sueltos en los cursores y en
  nueve reliquias/criaturas. **`cr_espectro` ya no está roto** —la hoja del 13
  de agosto lo regeneró entero— así que sale de la lista de intocables de
  `limpiar.py`. Los tres fixers convergen a cero. Y de paso, dos bugs de
  código que solo se ven jugando: el reloj de la barra de tareas marcaba
  "14:5" (el `width` de `draw_string` recorta y el ancho estaba estimado a
  ojo), y la prueba del crítico llevaba en rojo por un lambda que capturaba
  el contador por valor —el crítico funcionaba—. Los dos en `CLAUDE.md`.
- **Exploración: criatura de fuego coleccionable (cascabel).** Sprite de 8
  frames generado con Claude Design, procesado y limpiado sin `procesar.py`
  real (sandbox sin `scipy`, reimplementado a mano). Confirmado con Fátima:
  desentona sin cuantizar contra reliquias reales, y cuantizado se acerca
  pero el contorno redondeado no es ruido —es la silueta que dibujó la
  IA—, así que limpiar no lo arregla. Queda en `assets/_pruebas/
  cascabel_brasa/`, sin carpeta final ni nodo que lo use.
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
- **Fase 3** (cerrada la sesión anterior, confirmada jugando) reloj del enemigo,
  identidad de los seis tiros, mapa del run, y la tabla de enemigos rehecha con
  `tests/medir_balance.gd`. Lo que salió de ahí y hay que recordar: el coste de
  un combate es `bolas × drenaje + relojes × ataque`, escalar vida no cierra la
  brecha entre jugadores, y la causa real era un escalón de reloj más gordo que
  la diferencia que pretendía medir
- **Fase 3C** mapa del run generado: tres actos, ramas, un jefe cerrando cada
  acto, descanso en la penúltima fila, y la vida que NO se cura entre
  combates, que es lo que hace que elegir rama importe. Pantalla de mapa
  propia con la vida y lo que hay en cada rama; derrota y victoria de run
- **Fase 4** las 45 reliquias escritas con sus once ganchos, la ruleta dentro
  de la tele y las misiones de mesa que las pagan. Sin cerrar: el criterio de
  salida es que dos partidas se sientan distintas, y eso se juega
- **Fase 5** (escrita, sin ejecutar) renderizador de nueve trozos, fuente
  propia pixelart, escritorio con barra de tareas e iconos de reliquia con
  tooltip, TILT como pantalla azul, arte de IA recortado e integrado, y la
  última pasada: HUD y enemigo fuera de la mesa a los paneles de la derecha,
  reloj dentro de la barra de título, mapa como explorador de carpetas,
  fondos con variante por acto y puntero propio

## Diales vivos

Los números que se tocan para ajustar el tacto. Uno cada vez.

| Dial | Valor | Para qué |
|---|---|---|
| `tiempo_suavizado` (cámara) | 0,16 s | **EL dial de tacto de la cámara.** Alto = cine, bajo = pegada |
| `margen_debajo_bola` | 300 px | Cuánta mesa se ve bajo la bola. Suelo 250: por debajo se pierde el flipper |
| `tiempo_anticipacion` | 0 | Subirlo devuelve la predicción por velocidad **y con ella el tirón** |
| `velocidad_maxima` (cámara) | 2600 px/s | Red para los teletransportes de bola. Dormida en juego normal |
| `ancho_outlane` | 21 | Dificultad. Suelo 18, techo ~26 |
| `flipper_longitud` | 64 | Dificultad. Hueco central 47 px |
| `flipper_velocidad_giro` | 30 | Lo lejos que llega tu tiro. Suelo 26: por debajo la cuna no alcanza |
| `flipper_activo_izq/der` | −16° / 196° | Dónde se posa la bola atrapada. Más empinado = sin palanca |
| `flipper_rebote` | 0,25 | Cuánto revive la goma la bola que llega |
| `rodadura` | 4 | Techo. Subirlo aplana la caída; bajarlo no asienta la cuna |
| `friccion_flipper` | 0,30 | Cuánto desvía la goma la bola al rozarla |
| `velocidad_rebote_minima` | 55 | Frontera entre impacto y bola apoyada |
| `target_canto` | 8 | Cuánto sobresale el target al campo |
| `reloj_carga` | 9 s | Solo de reserva: ahora cada enemigo trae el suyo en `data/enemigos.json` |
| `reloj_aviso` | 1,5 s | Tiene que caber holgado dentro de la carga: los relojes empiezan en 6 s |
| `factor_ataque_drenaje` | 0,5 | Cuánto duele drenar frente al reloj |
| curación de reliquias | a un tercio | Si el run vuelve a acabarse al 100 %, es esto antes que la tabla |
| `platillo_atrasa_reloj` | 0,35 | Se mide en fracción de barra, no en segundos: ahora son ~3 s |
| `dano_rampa_fuerte` | 78 | Lo que paga el cañón por ese retorno difícil |
| `curacion_descanso` | 0,30 | Si descansar es siempre obvio, bájalo |
| `filas_por_acto` | 4 | Largo del run. 4 y 3 actos = 12-15 combates |
| `factor_vida_elite` | 1,25 | Cuánto más duro es un élite |
| `casillas_ruleta` | 8 | Lo que se ve girando. Solo la primera es el premio |
| `repeticiones_ruleta` | 1 | Con 0 la build se decide a suertes; con 2+ vuelve a ser un menú |
| `vida_jugador` | **1080** | ×6 por resolución al alargar los combates |
| `reloj` (por enemigo) | 6-10 s | El dial de cuánto APRIETA cada uno, aparte de cuánto dura |
| vida de enemigo | **3750-9660** | Medido con `medir_daniel.gd`. El dial de cuánto DURA el combate |
| `prob_critico` | 0,06 | Cuántos críticos salen. Las reliquias lo suben |
| `factor_critico` | 2,0 | Por cuánto multiplica un crítico |
| `golpes_tramo_extra` | 12 | Lo que pide el tramo que añade una reliquia. Menos y el x5 sale regalado |
| `tiempo_anticipacion` | 0,18 s | Cuánto se adelanta la cámara. Techo real ~0,20: por encima, la bola rápida se mete tras la barra de título |
| `margen_debajo_bola` | 150 | Cuánta mesa se ve POR DEBAJO de donde va a caer la bola |
| `zona_muerta` | 45 | Cuánto tiene que irse el objetivo para que la cámara arranque. Ya no es un error permanente |

**Orden para aflojar la dificultad:** outlanes primero, flipper después.

## Que prueben Daniel y Fátima

**Prueban los dos y cualquiera de los dos puede cerrar una pregunta.** Donde
ponga un nombre, es porque esa en concreto depende de quién juega más horas; el
resto son de quien las mire. La lista se llamaba "Que pruebe Daniel" y eso ya no
era verdad: los textos cortados de la cáscara y las dos averías de la cámara las
encontró Fátima jugando, con la batería en verde encima de las dos.


**Primero importar y luego la batería. En ese orden, y nada de esto se ha
ejecutado:**

    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --import
    & "C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path C:\dev\tilt-os --script tests/prueba_sim.gd

**LO DE ESTA SESIÓN (capas de altura) — y ojo, que casi todo es "que no pase
nada":**

C1. **QUE LA MESA SIGA SIENDO LA MISMA.** El sistema entró apagado y los números
    salen idénticos, pero eso lo dice un medidor, no una mano. Juega tres o
    cuatro bolas y di si notas algo distinto —la bola más lenta, un rebote raro,
    una rampa que se traga distinto—. Si notas cualquier cosa, es un fallo mío y
    va antes que todo lo demás.

C2. **EL 60 % DE LA VELOCIDAD DE ESCAPE: ¿es la frontera buena?** Es tacto puro
    y está expuesto en `Rampa.UMBRAL_CORONA`. Todavía no lo lleva ninguna rampa
    de la mesa, así que esta se contesta de verdad en 0i; lo que sí se puede
    decidir ya es la INTENCIÓN: ¿qué prefieres, que fallar una rampa sea
    frecuente (frontera alta, más tensión, más frustración) o raro (frontera
    baja, la rampa engancha casi siempre y el fallo es un susto)?

C3. **CAERSE, ¿DEVUELVE O SUELTA?** Un tubo te devuelve la bola por donde
    entró, cayéndote a la pala; un carril te la suelta al tablero desde donde se
    paró. Es una propiedad por rampa, así que se puede mezclar. Mirando la
    captura de la conversación: ¿qué esperas de cada recorrido de la mesa de
    hoy?

C4. **LA PLATAFORMA Y EL TÚNEL, ¿SE LEEN?** Con F1+F3 en la planta alta. La
    primera versión la tumbó Fátima mirándola: la losa era un polígono
    translúcido con una sombra oscura detrás y encima de un tablero casi negro
    eso parecía un panel de la cáscara, no un bloque; y el túnel era negro sobre
    negro. Ahora la losa lleva **canto** —cara de arriba clara y opaca, banda
    oscura debajo— y el túnel lo tapa el tablero a trozos, con las dos bocas
    marcadas. ¿Se entiende ya que una está ALTA y que el otro va POR DEBAJO? Si
    no, sobra código: hace falta arte.

**Lo de la sesión anterior, por orden de lo que más puede haber salido mal. Las
M son de la multibola y ninguna se puede cerrar leyendo código:**

M0. **PARA PROBAR LA MULTIBOLA SIN DEPENDER DE LA SUERTE: F1 y luego F2.**
    F1 enciende la depuración y F2 suelta una bola extra, hasta cuatro. Es banco
    de pruebas y no un atajo del juego: por el camino normal la multibola sale de
    las reliquias de Caos, que son 5 de 50, o sea una de cada diez tiradas.

M1. **LA CÁMARA CON DOS BOLAS, que es la decisión que puede caerse entera.**
    Con F1+F2, o con `bomba_de_procesos` si la ruleta te la da, juega
    una multibola de verdad. Sigue a la más baja, así que se queda casi siempre
    abajo. **(b) ya está medido y arreglado**: el 61-67 % del tiempo había una
    bola fuera de plano, casi siempre por arriba, y ahora hay flechas doradas en
    el borde. Lo que queda es **(a): ¿se puede JUGAR?** ¿Basta con la flecha para
    saber que va a caer algo, o la bola de arriba sigue apareciendo de la nada?
    Y **(c)**: ¿estorban las flechas cuando hay tres? Son un `draw_colored_polygon`
    y se quitan en un minuto.

M2. **PERDER UNA BOLA NO CUESTA NADA, ¿se nota demasiado bueno?** Con multibola
    puedes drenar dos veces seguidas sin que pase nada. Es lo que hace que la
    multibola sea un eje de build y no un adorno, pero también es la red de
    seguridad más grande del juego. Si con una bola extra el combate deja de dar
    miedo, lo que se toca es que la bola extra cueste algo al entrar (reloj), no
    que perderla duela.

M3. **CUATRO BOLAS, ¿son demasiadas?** `bolas_maximas` está en 4 porque es lo
    que cabe en el plano, no porque esté medido. Con las palas llenas, ¿estás
    jugando o estás mirando?

M4. **La bola extra sale disparada por el carril lanzador.** ¿Se ve salir, o
    aparece sin más? Si no se ve, el sitio del aviso es el carril, no el centro.

M5. **Caos sale más que los otros ejes** (28 % contra 20 %) porque tiene 14
    reliquias. ¿Se nota jugando que la ruleta ofrece Caos de más?

S1. **EL SISTEMA OPERATIVO, que es lo nuevo.** Pulsa Inicio durante un combate.
    **(a)** ¿Se entiende que `RECUPERADO` es lo que te falta por conseguir, sin
    que nadie lo explique? Es la apuesta entera de `PROPÓSITO.md` §2: los
    ficheros de 0 KB con el nombre en interrogantes tienen que leerse como "aquí
    había algo", no como una lista de logros bloqueados. **(b)** ¿Congelar la
    mesa al abrir una ventana se agradece o desorienta al volver? Está medido que
    la bola se queda exactamente donde estaba. **(c)** ¿El aviso de "Recuperado:
    ..." al acabar un run se ve, o pasa desapercibido? Dura 6 s abajo a la
    derecha. **(d)** Los iconos a 16 px de la carpeta: ¿se distinguen unos de
    otros o son manchas?

S2. **EL PAGO POR RUN, que es el dial delicado.** Ahora un run paga
    `1 + nodos/5` piezas. Con 22 piezas y 11 de fábrica, quedan 11 por ganar.
    ¿Se siente a tragaperras —una pieza cada vez que respiras— o a que cuesta?
    **Si sobra, el dial es `NODOS_POR_PIEZA` hacia arriba, NO `PIEZAS_MINIMO`
    hacia abajo:** quitarle el pago al run perdido devuelve el problema de
    partida, que es que perder no costaba nada.

C1. **LA CÁMARA, que es lo único de código que cambia esta sesión.** Está medido
    que ya no se queda corta y que el flipper está siempre en plano bajo la
    línea de seguridad, pero lo que se mide no es lo que se siente. Tres cosas:
    **(a)** ¿se ven ahora los últimos píxeles de mesa cuando la bola drena, o
    sobra tanto que la mesa parece más pequeña? **(b)** con un bolazo de los
    fuertes cayendo, ¿la cámara **pega un tirón** al bajar? Si lo pega, el dial
    es `suavizado`, y si el tirón es al cruzar la línea de seguridad, es
    `margen_ancla`. **(c)** ¿la bola se te esconde detrás de la barra de título
    en alguna bajada rápida? Está medido que llega a 48 px del borde contra los
    24 del marco: es poco margen y es lo que más fácil se me escapa. El dial es
    `tiempo_anticipacion` (0,18): bajarlo separa la bola del borde y acerca la
    cámara a la bola.
N1. **¿SE VE LA BOLA EN LO ALTO DE LA ÓRBITA?** Es la prueba de que quitar el
    HUD ha servido para algo. Antes tenía 58 px opacos encima; ahora 24. Lanza a
    tope diez veces y mira si la bola sale por arriba del todo sin esconderse.
N2. **EL RELOJ EN LA BARRA DE TÍTULO.** Está pegado a la mesa, escrito y con
    barra, arriba del campo. ¿Lo pillas de reojo sin dejar de mirar la bola, o
    te enteras de que te van a pegar cuando ya te han pegado? **Si esto falla,
    falla la decisión entera** y el reloj vuelve a estar sobre el tablero.
N3. **EL ENEMIGO EN SU PANEL, a la derecha.** ¿Se lee el destello al pegarle
    ahora que está siempre a la vista? ¿Y la disolución al matarlo, con la
    explosión dentro del panel? Antes casi nunca estaba en plano.
N4. **LOS TRES PANELES DE LA DERECHA.** ¿Cabe todo sin apretarse y se lee sin
    girar la cabeza? Lo que más miedo me da es la vida: mirar a un lado para
    saber cuánta te queda mientras persigues la bola puede ser peor que tenerla
    encima. Si lo es, dilo y la vida vuelve a la barra de título con el reloj.
N5. **EL MAPA COMO EXPLORADOR.** Ruta arriba, detalles del nodo marcado a la
    izquierda, "N objetos" abajo, y los nodos como archivos con su extensión
    (`rata.exe`, `descanso.tmp`, un jefe en `.sys`). ¿Se sigue eligiendo rama
    igual de rápido, o el mueble se ha comido la legibilidad del grafo?
N6. **EL PUNTERO.** Ahora es el nuestro, pixelart, y el del sistema se esconde
    dentro de la ventana. ¿Va donde tiene que ir? ¿Sale el reloj de arena
    durante la ruleta? Si al hacer alt-tab desaparece y no vuelve, dímelo: es lo
    más fácil de que se me haya escapado.
N7. **LA VENTANA DE LA MESA, que hasta ahora no se veía.** Barra de título con
    "cascabel.exe" y tres botones, encima del campo. Es la primera vez que está
    en pantalla de verdad. ¿Se entiende la broma de un vistazo? **Ese es el
    criterio de salida de la fase.**
N8. **LOS FONDOS BUGUEADOS.** Cambian entre combate y combate. Acto 1 limpio,
    acto 2 con dos maneras de fallar, acto 3 con cuatro. ¿Se nota que el sistema
    se va cayendo, o pasa desapercibido?

**LO PRIMERO DE TODO, que es el rebalance y es lo que más puede haber salido
mal.** Un run entero con la tabla nueva, y estas cuatro:

R1. **¿SE HACE PESADO UN COMBATE?** Ahora duran 137 s de media contra los 45 de
    antes: tres veces más. **Esta es LA pregunta de la sesión.** Si se hace
    pesado, no es que la vida esté alta: es que el enemigo es un saco, y lo que
    toca es la Fase 6, que ya está puesta la primera de "Siguiente" por medida.
R2. **¿En qué nodo mueres y con cuánta vida llegas al jefe de cada acto?** El
    modelo dice 3 de 5 runs acabados y el 71 % de vida al ganar. Si acabas
    siempre y por encima del 90 %, el modelo se ha vuelto a quedar corto.
R3. **Las reliquias de cura, que han bajado a un tercio.** "Rutina de
    reparación" pasa del 8 % al 3 % y "Desfragmentación" del 2 % al 0,7 %.
    ¿Siguen mereciendo la pena o han quedado en nada? Si nunca las eliges, se
    subirá el número, pero **no al de antes**: al 8 % el run se curaba entero.
R4. **¿Sigue el reloj sin apretar?** Con el combate a 137 s comes muchos más
    relojes que antes. Si aun así no notas nada, el problema no es cuántos
    comes sino que cada uno pega poco, y eso ya no se arregla con la tabla.

M. **LOS SPRITES REPARADOS.** Mira sobre todo la calavera llameante, la
   sombra y la armadura vacía: a la armadura le he quitado unas motas verdes
   sueltas que tenía en hombros y piernas. Si ves algún bicho al que le falte
   un trozo o le sobre un pegote, dímelo por nombre.

M2. **LOS ICONOS DEL ESCRITORIO Y LOS CURSORES, sin el halo rosa.** Estaba
   comprobado ampliando la captura del juego y ya no está, pero el arreglo
   quita píxeles del contorno: mira que ningún icono haya adelgazado por un
   lado. Los que más perdieron son `registro`, `disco` y `papelera`.

M7. **LAS MAYÚSCULAS CON TILDE.** Á É Í Ó Ú Ü tienen ahora el cuerpo una fila
   más corto para que la tilde quepa encima. Mira "CRÍTICO" en `jugador.sys` y
   "COMÚN" en la tele: la tilde se ve, pero la letra queda algo más baja que
   sus vecinas. **Si prefieres las mayúsculas a plena altura y la tilde
   apretada, se deshace borrando la fila `"     "` de esos seis glifos en
   `fuente.py`.** Es tuyo.

M8. **EL CARTEL DEL ATAQUE.** Es el que estaba lleno de ladrillos. Ahora es un
   cuadro de diálogo gris claro. ¿Se lee el nombre del enemigo y el daño de un
   vistazo, con la bola parada detrás?

M6. **EL MARCO DE LA VENTANA DE LA MESA.** Es lo que más ha cambiado de sitio:
   ya no hay tornillos en las cuatro puntas y el marco no se mete en el campo.
   Mira si ahora se ve DEMASIADO liso —son 8 px de gris y nada más— o si con la
   barra de título y los tres botones ya cuenta la broma. **Ese sigue siendo el
   criterio de salida de la fase (N7).**

M4. **LOS NOMBRES DE RELIQUIA EN EL ESCRITORIO.** Ahora son dos renglones. ¿Se
   leen, o el escritorio se ha llenado de texto? El paso vertical entre iconos
   ha subido de 54 a 66 px para que quepa el segundo renglón: si con doce
   reliquias la banda se queda corta, se ve enseguida.

M5. **LA Ñ Y LAS TILDES.** "goblin_carroñero" ya sale con la tilde. Las tildes
   de á é í ó ú siguen tocando la letra —se leen, pero van pegadas— y **eso no
   lo he cambiado porque es tuyo**: si las quieres separadas, es una línea en
   `fuente.py` (tilde en la fila 0 y la 1 en blanco). Tengo las dos versiones
   comparadas si quieres verlas.

M3. **EL ESPECTRO.** Llevaba en la lista de "roto, no tocar" desde el fallo del
   magenta y **hoy sale entero**: cero interior comido, cero motas. Míralo en el
   mapa y confirma, y si está bien esa línea se cae del plan.

A. **LAS MISIONES, que es lo nuevo y lo que hay que juzgar.** ¿La tele te dice
   con claridad qué toca? ¿Te descubres yendo a por un tiro concreto porque lo
   pide la misión? Si te da igual lo que ponga y sigues dando tumbos, la misión
   no está hecha para leerse mientras juegas y hay que agrandarla o simplificarla.
B. **¿Las casillas de progreso se leen de reojo?** Son la fila de cuadraditos de
   abajo de la tele. Un "2/3" en letra pequeña no se lee persiguiendo una bola;
   la apuesta es que tres cuadraditos sí.
C. **La ruleta a mitad de combate.** Ahora la bola se queda congelada donde
   estaba y luego sigue. ¿Desorienta al reanudar, o se agradece la pausa? Es lo
   que pediste y es lo que menos claro tengo.
D. **Las misiones "sin drenar".** Al perder la bola sale "MISIÓN PERDIDA". ¿Se
   entiende que era por eso, o parece un castigo de la nada?
E. **¿Sigues muriendo pronto?** Si sí, dime en qué combate y con cuánta vida
   llegabas, y con los dos números de arriba lo dejo cuadrado.
F. **¿Se hacen largos los combates ahora que hay misión dentro?** Esa es la
   apuesta entera de la sesión.
G. **Los números de daño.** ¿Se leen sin dejar de mirar la bola? ¿El tamaño
   distingue de verdad un bumper de un cañón? Si saturan la pantalla, el dial es
   el rango 10-22 px de `_numero_de_dano` en `render/vista_mesa.gd`.
I. **LA FUENTE a 8 px.** Ahora casi todo el texto va a ese tamaño, así que pesa
   más que nunca: una fuente de 5×7 es legible o no lo es, y eso no lo dice
   ninguna prueba. Si alguna letra se confunde con otra, dime cuáles: se
   arreglan en `fuente.py`, que las tiene escritas como dibujos de texto.
J. **Los iconos de reliquia, pasando el ratón por encima.** ¿El tooltip llega a
   tiempo y dice algo útil? Y lo importante: **¿se ve encenderse y apagarse un
   icono condicional** cuando cruzas su umbral en mitad de un combate?
K. **La pantalla de TILT.** ¿Da ganas de volver a intentarlo? Ahí salen los dos
   números que necesito.
L. **El pendiente de siempre: ¿la ventana del pinball cuadra en tu portátil**, o
   sigue desbordando? Ahora hay tres paneles más midiendo contra la misma
   pantalla, así que si algo se sale se va a ver antes.
H. **Los críticos.** 6 % de base, ×2. ¿Salen lo bastante como para notarlos y lo
   bastante poco como para que sigan siendo un premio? Diales: `prob_critico` y
   `factor_critico`. Si te parece que el daño se ha vuelto aleatorio, es que la
   probabilidad es demasiado alta o el cartel no se lee.

Lo de abajo es lo que sigue sin comprobar (lo ya contestado se ha borrado:
cuna, reloj-como-carrera, cañón, outlanes y drenaje están bien).

0b. **La apertura.** Lanza a tope diez veces seguidas sin tocar nada más. La
   bola tiene que dar la vuelta por la órbita y **caerte en la pala
   izquierda**. Si vuelve a irse por el outlane, la boca se ha quedado corta.
1. **Atrapar la bola, que es lo que estaba mal.** Con la pala levantada debe
   RODAR hasta el hueco del eje y quedarse ahí (~0,6 s), no clavarse donde
   toque. Y con la pala en reposo no debe quedarse nunca: rueda y se va.
   Si sigue soldándose, baja `rodadura`; si no llega a asentarse, súbela.
4. **Los huecos del tablero en negro y el destello al pegar**, que es lo
   único que cambió de color.
6. **Subir de tramo, con el racimo sonando.** ¿Se oye que has subido sin
   mirar el número? ¿Y se distingue x3 de x4 solo por el tono? Si tapa
   demasiado los golpes, el dial es `db` de `combo` en `nodo_sonido.gd`.
8. **Que el golpe del reloj no se lea como injusto.** Llega en mitad de la
   bola y no para nada, a propósito. Si sorprende, el aviso de 3-2-1 es
   corto: `reloj_aviso`.
10. **El platillo, ahora que se ve lo que hace.** ¿Compensa buscarlo por los
    ~6 s, o prefieres siempre el cañón? Si nunca lo eliges, sube
    `platillo_atrasa_reloj`. **Ojo: esta pregunta no valía antes**, porque no
    se sabía que daba tiempo. Es la primera vez que se puede contestar.
11. **A ciegas, sin mirar la pantalla:** ¿sabes qué acabas de conseguir solo
    por el sonido? Racimo, target, banco cerrado, órbita, retorno, cañón y
    platillo tienen sonido propio. Si dos se confunden, dime cuáles.
13. **¿La vida aguanta un acto?** Si mueres siempre en el acto I, o el reloj
    aprieta demasiado o los enemigos tienen mal la vida. Dime en qué nodo
    mueres y con cuánta vida llegabas.
14. **¿Eliges rama de verdad?** Si siempre coges la misma sin mirar, o las
    ramas no se diferencian lo bastante o falta información en el mapa.

## Siguiente

**Por tandas. Una por sesión, y el modelo de cada una entre paréntesis.**
**El orden lo manda ahora `PROPÓSITO.md` §11**, que es donde está entero y con
el porqué de cada puesto. Resumen: guardado + clics + `RECUPERADO/` → capa de
Preparación → la cáscara reacciona → dopamina de mesa → rampas fallables →
selector de dificultad → tapar agujeros → **Fase 6** → reabrir §13.

0. ~~**Guardado + clics + menú de Inicio + `RECUPERADO/`**~~ **HECHA Y
   EJECUTADA.** Batería 358/358. Ver arriba.

0b. ~~**La capa de Preparación**~~ **HECHA Y MEDIDA.** 381/381. Ver arriba.

0c. ~~**Los cascabeles pagan en RELOJ, no en daño**~~ **HECHO Y MEDIDO.** Ver
   arriba. Y de paso ha quedado medido el pilar de `DISEÑO.md` §1, que no lo
   comprobaba nadie.

0e. ~~**MULTIBOLA**~~ **HECHA Y EJECUTADA.** 414/435 en la caja (los 21 que
   faltan son assets que allí no están). Con ella, el eje de Caos deja de ser
   nueve porcentajes. Ver arriba. Lo que queda de esta tanda son las preguntas
   M1-M5, y M1 puede tirar la decisión de cámara entera.

0f. ~~**`PROPÓSITO.md` §8, la dopamina de mesa: el campo de pines**~~ **HECHA Y
   MEDIDA.** 426/447. Campo de once pines, y de paso el racimo girado 60°
   porque llevaba desde siempre puesto de espaldas: 1,0 golpes por entrada
   pasan a 3,9. Ver arriba. Lo que queda de esta tanda es jugarla.

0g. ~~**QUE A LA ZONA ALTA SE PUEDA APUNTAR**~~ **HECHA Y MEDIDA**, y no como
   estaba escrita: lo corrigió Daniel. No era apuntar mejor al techo de siempre,
   era que **la zona de las rampas tenía que ser jugable**. Hay arena de caza.
   437/458. Ver arriba.

0h. ~~**CAPAS DE ALTURA: EL SISTEMA**~~ **HECHO Y MEDIDO.** 497/497 con assets,
   15 pruebas nuevas, y la mesa de hoy da los mismos números al decimal. Ver
   arriba. Lo que queda de esta tanda son los sonidos de caída y la barra de
   carga, y las dos van detrás de 0i.

0i-d. ~~**DISEÑAR LA PLANTA ALTA Y LA CAPTURA**~~ **HECHA.** Sale `CAZA.md`. Sin
   tocar código. Ver arriba.

0i. ~~**LA PLANTA ALTA, REHECHA — LA GEOMETRÍA**~~ **HECHA Y MEDIDA.** 499/499 y
   la planta de abajo igual al decimal. Ver arriba. Lo que queda de esta tanda es
   la puerta B, que es la de abajo.

0i-B. ~~**JUGAR LA PLANTA ALTA Y JUZGARLA**~~ **JUGADA (18-ago), y con
   consecuencias**: salvabolas y palas de 54. Ver arriba. **Falta volver a
   jugarla con eso puesto**, que es la segunda vuelta de la misma puerta:
   **P1.** ¿Ahora sí se siente como un bonus —algo que te ha tocado— en vez de
   como un sitio del que te echan?
   **P2.** Con el hueco a la mitad (24 px) y la pala a 54, ¿la zona de palas de
   arriba se siente distinta de la de abajo, o ya se parecen demasiado?
   **P3.** La salvada avisa con un "SALVADA" verde y el sonido del reloj en el
   desagüe de arriba. ¿Se entiende a la primera que la mesa te está sujetando?
   Medido, con un jugador que aporrea **no salta ni una vez**, así que puede que
   no la veas: si nunca aparece, sobra o hay que apretar el hueco.
   **P4.** La isla: ¿se entiende que está ALTA y que hay que subir a ella?
   **P5.** ¿Los túneles se leen como agujeros por debajo, o como rampas oscuras?
   **P6.** La planta de abajo se atenúa mientras cazas. ¿Ayuda o distrae?
   Y falta por construir de `CAZA.md` §3.7: la **ventana de recuperación de
   disco** que la cáscara tenía que abrir encima durante la caza.

0h2. **QUE CAERSE SUENE** (Sonnet, medio). `bola_cayo` y `rampa_fallada` no
   tienen sonido, y un evento que no se oye se diagnostica como que no existe
   —es la avería del platillo—. **Y ahora los dos pasan de verdad**: la isla tira
   al tablero a quien se sale de su borde y la subida suelta a quien no le pega
   fuerte, así que son los dos eventos nuevos de la mesa y no se oyen. Hay que
   generarlos en `sonidos.py`, reimportar y engancharlos en `vista_mesa.gd`.

0j. **EL 3 % DE ENTRADA AL UMBRAL** (Daniel y Fátima). Con la planta alta ya
   rehecha, la pregunta vuelve a estar viva y es la primera de `CAZA.md` §7: una
   caza de cuatro fases hay que APRENDERLA, y no se aprende lo que ves dos veces
   por run. ¿Una vez por combate garantizada, o sigue siendo un tiro que se
   busca? Se decide ANTES de construir la captura.

0k. **BICHOS EN LA ARENA: LA CAPTURA** (Opus, alto). `CAZA.md` §2 y §5, puertas
   C y D — ya está diseñada entera: rastro, acoso por MIEDO, cierre que acaba la
   caza, y el regreso donde se puede perder lo capturado. `DISEÑO.md` §5: ahí
   arriba se caza material de desbloqueo, y sin eso el modo es bonito y no sirve
   para nada — subir cuesta reloj y no da nada a cambio. Después de 0i, y
   **después de decidir cada cuánto se abre la caza** (`CAZA.md` §7, riesgo 1).
   Depende de la tanda 7 (reproductor de hojas de fotogramas) para los cuatro
   estados de cada criatura.
   Sube al primer puesto porque lo ha destapado la tanda anterior y porque
   invalida a medias todo lo que se decida encima: el tiro desde la cuna sube a
   y=893 de media y toca 0,1 bumpers, y ninguna salida de recorrido pasa de
   y=784. El racimo y la bóveda están equilibrados en una parte de la mesa a la
   que no se puede tirar. Es geometría fina y no se mide, se juega: alinear la
   línea de tiro de cada pala con algo que merezca la pena arriba. **Y hasta
   que esto no esté, el 265 contra 1999 no se arregla tocando premios.**

1. **FASE 6: comportamientos de enemigo** (Opus, razonamiento alto). **Baja de
   puesto por decisión de Fátima, no porque la medida haya cambiado:** el
   barrido sigue diciendo que con un solo ataque por reloj no existe ninguna
   tabla que deje el run en la banda de dificultad que se busca. `DISEÑO.md` §11
   tiene los seis (bloquear un recorrido, curarse, reflejar, blindaje, castigar
   el combo, acelerar el reloj). Y con combates de 137 s, un enemigo que solo
   tiene vida se nota que es un saco
1a. ~~**PONER LA BATERÍA EN VERDE**~~ **HECHA. 321/321.** Ver el detalle en
   "Abierto". Falta el commit.
1b. **Rebalance, segunda pasada** (Opus, alto), DESPUÉS de la Fase 6 y no antes,
   **y ahora tiene que contar la multibola**: `medir_daniel.gd` juega con
   perfiles sin física dentro, así que no sabe soltar bolas ni jugarlas y lo que
   diga de una build de Caos no vale. Antes del rebalance hace falta que el
   medidor sepa jugar con N bolas, o las cinco reliquias nuevas se calibran a
   ojo. Lo de siempre:
   con comportamientos dentro, `tests/medir_daniel.gd` vuelve a barrer y la
   banda del 25-60 % pasa a ser alcanzable. Hasta entonces, tocar la tabla es
   mover el mismo número por cuarta vez
2. ~~**Tanda de assets A: la hoja del espectro**~~ **HECHA sin gastar tanda:**
   la hoja del 13 de agosto ya lo había regenerado y nadie lo había medido.
   Sale de la lista de intocables de `limpiar.py`. Falta que Daniel lo mire (M3)
2b. **Cerrar la criatura del cascabel** (Sonnet, medio para colocarla;
   Opus + Daniel/Fátima si hace falta reabrir el estilo de borde). Decidir
   destino final (¿`reliquias/`? ¿carpeta nueva?), decidir si se acepta el
   contorno más suave o se regenera, correr `procesar.py` real para
   confirmar el resultado, y conectar el nodo que la use
3. **Tanda de assets C: piezas de bandeja de sistema** (Sonnet, medio). Es lo
   único que queda de `assets/prompts_cascara.md` §2 sin generar: reloj con
   sprite propio, separador, altavoz e icono de sin-red. La barra de tareas
   dibuja su bandeja con `draw_rect` a mano hasta entonces. **Guardar la hoja**
4. **Tanda de assets D: los 27 iconos de reliquia que faltan** (Sonnet,
   medio), con `assets/prompts_reliquias.md`. Se ven en tres sitios —tele,
   escritorio y tooltip—, así que se notan
5. **Fase 5: juzgarla jugando** (Daniel). El código está escrito entero y sin
   ejecutar. Lo que queda no se lee, se juega: las preguntas N1-N8 de arriba. Si
   N2 o N4 salen mal, lo que vuelve a la mesa es reversible en un rato
7. **Animación fotograma a fotograma de enemigos/criaturas/jefes** (Opus,
   razonamiento alto). Pedida por Daniel y por Fátima. **Los prompts ya están
   escritos, y ahora también la guía de estilo de la que dependían**: los tres
   ficheros de prompts empiezan por "Following the style guide above" y esa guía
   no estaba en el repo, así que ninguno generaba lo que decía. Está en
   `assets/GUIA_ESTILO.md`, **y es la original que pasó Fátima, no una
   reconstrucción**: bloque A el suyo tal cual (la línea que más trabaja es "in
   the style of Peglin"), bloque B tres líneas añadidas contra fallos ya
   medidos —el magenta que se comió el 22 % del espectro, el contorno redondeado
   que no se puede reparar, y las celdas con hueco que descuadran la hoja—.
   **La paleta va en palabras y NO en hex a propósito**: `procesar.py` cuantiza
   después, así que los códigos no aportan. Y de paso queda recuperado el prompt
   que generó `assets/mesa/`, con sus nueve objetos mapeados. **Y el prompt del cascabel estaba mal de diseño**:
   dibujaba campana y criatura juntas, que no se puede rotar (`DISEÑO.md` §4
   pide dos capas). Reescrito: las 9 criaturas van solas, 8 fotogramas, celda
   64, piloto `cr_brasa`. El orden de las hojas está al final de
   `assets/prompts_animacion.md`: hoja 4×4 por bicho (idle, golpe, ataque,
   muerte), las nueve descripciones con escala común, los jefes a 4×5, el
   cascabel de fuego, y el subsistema que hace falta. Hoy todo bicho es UN
   sprite estático deformado por código —`render/nodo_enemigo.gd`: respiración
   y embestida son squash/stretch en píxeles enteros, sin un solo fotograma de
   verdad—. Hace falta un subsistema nuevo: hojas de varios fotogramas y un
   reproductor que las pase, respetando rejilla de píxeles y escalado entero.
   Opus y alto porque es subsistema nuevo que cruza arte + timing + las
   trampas ya cazadas en `CLAUDE.md` (rejilla de píxeles, hitstop en
   `_physics_process`), y los fallos de ese tipo han costado sesiones enteras.
   Diseñar antes de tocar código: cuántos estados por criatura (idle, golpe,
   ataque, muerte), cuántos fotogramas cada uno, y de dónde sale el arte —
   ¿prompts de IA como las hojas de `assets/prompts_cascara.md`, o a mano?

## Mediciones

| Qué | Valor |
|---|---|
| Duración de bola, mesa pequeña | ~10 s |
| Objetivo de drenaje | cada 2-3 bolas |
| Daño por bola: malo / normal / bueno | 42 / 312 / 840 |
| **Run real de Daniel (15-ago, con rebalance)** | **90 % de vida · 1450 d/bola · 80 s · 72 bolas** |
| Run real de Daniel (antes del rebalance) | 98 % de vida · 797 d/bola · 45 s · 43 bolas |
| Motor de multibola, una bola: antes → después | 71 % / 3-5 runs → **idéntico** |
| Con las 5 reliquias de Caos dentro (modelo, no veredicto) | 97 % de vida, 835 d/bola, 128 s |
| Tope de bolas a la vez | 4 (`bolas_maximas`, elegido a ojo) |
| **Racimo: golpes por entrada, de espaldas → girado** | **1,0 → 3,9** |
| Tiro desde la cuna: sube a | y=893 de media, y=751 el mejor de 42 |
| Y toca | 0,1 bumpers por tiro |
| Salidas de recorrido: lo más alto | órbita 845 · cañón 985 · retorno 1085 · platillo 784 |
| Campo de pines: paso más estrecho | 24,1 px (bola 18) |
| Coste del racimo girado: duración de bola | 1,51 s → 1,67 s por entrada |
| Coste del racimo girado: drenaje outlane/centro | 8/92 → 9/91 |
| **Caza: se abre en** | **2 de cada 100 entradas al racimo** |
| Caza: pines por visita | 24,4 de media |
| Caza: el regreso llega a una pala | 60 de 60, a 251 px/s y 662 ms |
| Caída libre desde las rampas hasta las palas | 1500 px/s = 67 ms (incazable) |
| Subida máxima de la bola por sus medios | 643 px (desde las palas, hasta y=557) |
| Brecha entre jugar mal y jugar bien | 20× (8,4× sin multiplicador) |
| Vida de enemigos | 225-660, salida del barrido |
| Runs acabados: malo / normal / bueno | 0/5 · 2/5 · 5/5 |
| **Daniel, medido jugando** | **797 por bola · 45 s · 43 bolas · 1764/1800 al ganar** |
| **El modelo reproduciéndolo** | **729 por bola · 99 % de vida al acabar, con reliquias puestas** |
| Tabla nueva, medida | 137 s por combate · 71 % de vida al acabar · 3/5 runs |

**Cuál lanzar:** `tests/medir_balance.gd` mide la economía SECA del combate y
las tablas viejas siguen comparables con él. `tests/medir_daniel.gd` mide el RUN
con reliquias, y es el único que reproduce a Daniel: **para tocar balance, ese**.
La tabla ya se hizo tres veces contra el jugador equivocado.

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

- **El racimo de abajo pasa de 3,09 a 3,08 golpes por entrada, y NO es una
  regresión.** La huella de 60 bolas jugadas enteras es idéntica al decimal
  (16621,1901), así que la física de abajo no se ha movido. Lo que se mueve es
  A2, que suelta 240 bolas contra el racimo: **8 de esas 240 se van por el umbral
  a la planta alta** —es el 3 % medido de `medir_caza.gd`, igual antes que
  ahora—, y ahí arriba ahora hay otra mesa, así que esas ocho vuelven distintas.
  El número es determinista: dos lanzamientos dan 3,08 los dos.
- **`arena_desague_medio` está medido INERTE** (50 u 80 dan el mismo 7,6 s). Se
  queda como parámetro porque es la forma del embudo y con la medida escrita al
  lado vale más que un número mágico, pero **no sirve como dial de dificultad**:
  el que manda es el hueco entre palas.
- **`medir_caza.gd` y `medir_planta_alta.gd` se solapan a medias.** El viejo mide
  la ENTRADA (el 3 %) y el REGRESO, que el nuevo no toca; el nuevo mide lo de
  arriba con dos jugadores, que el viejo hacía con uno. Antes de tocar ninguno de
  los dos, mirar cuál contesta la pregunta: fusionarlos sin pensarlo perdería la
  parte A y la C, que son las que dicen si la caza se alcanza y si bajar cuesta
  la bola.
- **El jugador que "atrapa" del medidor nuevo es flojo, y hay que saberlo al leer
  la brecha.** Sube las dos palas y suelta a los 0,9 s con la bola posada; no
  apunta, así que la brecha que sale (x1,1 a x1,8) mide lo que perdona la mesa,
  no lo que da la habilidad. Un maniquí no mide una mesa —es la misma trampa que
  la tabla de balance calibrada contra un jugador inventado—, y por eso la puerta
  B la juzgáis vosotros.
- **La planta de abajo se atenúa durante la caza, pero la cáscara no reacciona.**
  `CAZA.md` §3.7 pedía además una **ventana de recuperación de disco** encima
  mientras cazas, y eso no está: es trabajo de `NodoSistema`, no de la mesa.

- **NO HAY BOLA-BOLA DENTRO DE LAS RAMPAS NI EN EL PLATILLO, y es a propósito.**
  Una bola enganchada a una curva está en otro plano —las rampas son elevadas—,
  así que las demás la atraviesan. Dos bolas SÍ pueden ir por la misma rampa a la
  vez: el recorrido lo lleva cada bola, no la rampa. En una mesa real se
  solaparían; aquí la de la curva se dibuja como sombra, así que ni se ve. Si
  alguna vez molesta, la salida es una cola por rampa, y es trabajo de verdad.
- **La bola no tiene giro, y ahora se nota más.** Sin spin, dos bolas que chocan
  no se transmiten efecto: el choque es puro impulso normal. La rodadura es la
  aproximación barata y aguanta, pero si en algún momento se quiere una física
  que destaque, el siguiente paso es momento angular, y es un cambio que toca el
  solver entero.
- **`medir_daniel.gd` no sabe jugar con varias bolas**, así que la multibola no
  está medida y las cinco reliquias de Caos están puestas a ojo. Es lo primero
  que hay que arreglar antes del rebalance de la Fase 6 (ver "Siguiente" 1b).
- **Las cinco reliquias nuevas no tienen icono**, y con ellas suben a 32 de 50
  las que no lo tienen. Los prompts están en `assets/prompts_reliquias.md`.
- **La bola extra no tiene sonido propio**: suena con el arpegio del combo, que
  es un préstamo. Igual que las reliquias.
- **`fuente.py` ya no reproduce los marcos del repo, y la tabla de herramientas
  de `CLAUDE.md` invita a lanzarlo.** Medido: al regenerar, las nueve piezas de
  `ventana`, `titulo` y `barra` salen con todos los píxeles distintos y
  `tooltip` sale de 4×4 en vez de 8×8. O los marcos del repo los hizo una
  versión anterior del script, o se retocaron después y no se anotó. Esta
  sesión regeneró la fuente y **restauró los marcos a mano** para no romper
  nada. Hay que decidir cuál de los dos es el bueno. **Mientras tanto, lanzar
  `fuente.py` a secas destruye la cáscara.**
- **Quedan carpetas mías dentro del repo: `_to_delete/`.** Tres carpetas de
  parche ya aplicadas, cuatro `.tgz` y dos `index.lock` sueltos. El puente del
  escritorio NO puede borrar ficheros, así que las dejé ahí y **Godot las
  escaneó**: cada copia de `nodo_cascara.gd` daba "Class NodoCascara hides a
  global script class" y llenaba el editor de rojos que no eran del juego.
  Tapado con un `.gdignore` vacío dentro, que hace que Godot se salte el
  directorio, y `_to_delete/` está en `.gitignore`. **Se puede borrar entera
  desde el Explorador: dentro no hay nada que sirva.**
- ~~Los NOMBRES de misión también van sin tildes~~ HECHO, aparte de los textos:
  "Punteria", "Artilleria", "La maquina", "El reloj es mio". Entra en la misma
  pasada que lo de abajo.
- **La `Ú` de "COMÚN" va apretada.** La tilde de las MAYÚSCULAS se come la
  primera fila de la letra —no hay sitio para más en una celda de 8 px— y a
  ese tamaño la Ú se puede confundir con una O. Se lee, pero si molesta, la
  salida es subir la celda a 10 px, y eso agranda TODO el texto del juego.
  Decisión de Fátima, no mía.
- ~~El texto de las reliquias está escrito sin tildes~~ **HECHO.** Lo que sigue abierto de aquí es solo la `Ú` apretada, arriba.
- **VIEJO, ya no aplica:** 47 palabras en 31
  entradas de `data/reliquias.json` y `data/misiones.json`: "dano", "canon",
  "mas", "Metronomo", "Cuerda de mas", "El reloj es mio". Viene de cuando la
  fuente de reserva no sabía dibujar acentos —el motivo por el que existe
  `fuente.py`— y ese motivo ya no está. `enemigos.json` sí los usa, así que en
  la misma pantalla conviven "goblin_carroñero" bien escrito y "Cuerda de mas".
- ~~LA BATERÍA ESTÁ EN ROJO~~ **HECHO: 321/321 en verde.** Los seis de pantalla
  se arreglaron dándole a `NodoCascara` un `SubViewport` de verdad dentro de la
  prueba — pero eso solo no bastó: `get_root().add_child(...)` en modo
  `--script` NO mete el nodo en el árbol de forma síncrona
  (`is_inside_tree()` da falso hasta el siguiente frame), así que hacía falta
  además un `await process_frame` antes de medir, propagado por los tres
  niveles de llamada (`_prueba_huecos_de_la_cascara` → `_prueba_cascara` →
  `_initialize`). Los siete de constantes viejas eran dos causas: el ataque de
  `_prueba_derrota` se calcula ahora contra `c.p.vida_jugador /
  c.p.factor_ataque_drenaje` en vez de un `1000` fijo, y las cuatro pruebas de
  daño exacto (combo y reliquias) fuerzan `prob_critico = 0.0` —igual que ya
  hacía `_prueba_criticos`— porque un crítico de la probabilidad de base podía
  colarse y doblar cualquier golpe medido. Nada de esto era un fallo del
  juego, medido jugando.
- **`assets/ui_marco/` no lo carga nadie.** Nueve piezas de marco de piedra
  remachada, 28 000 px, con alfa parcial (fleco antialiaseado, que en pixelart
  con escalado entero es fleco borroso) y un halo de magenta de los gordos. No
  se ha tocado a propósito: arreglar arte muerto es ruido. O se conecta o se
  borra, y eso lo decide quien sepa si ese marco se quería.
- **Hay mucho arte generado que el código no usa.** Sin referencia ninguna:
  `bolas/`, `bolas_64/`, `criaturas_64/` (sí se ven, pero por otra ruta),
  `mesa_anim/`, `mesa_placas/`, `mesa_props/`, `mesa_tunel/`, `reliquias2/`,
  `ui_marco/` y **9 de los 13 PNG de `mesa/`** (del bumper de engranaje al
  target de lápida). Los jefes ya se sabía que estaban aparcados a propósito;
  esto otro no estaba anotado. No es un bug, pero explica por qué la mesa se ve
  más pelada que la carpeta de assets.

- **LA `Ó` MAYÚSCULA SE LEE COMO UNA `ó` MINÚSCULA, y ahora se ve porque "Óxido"
  es un cascabel.** No es un fallo de `fuente.py`, es que la salida elegida no
  puede funcionar para esa letra en concreto. Las mayúsculas con tilde llevan el
  cuerpo comprimido a cinco filas para que la tilde quepa encima, y eso funciona
  con la `Á` porque conserva el travesaño —sigue siendo una A sin discusión—,
  pero **un `O` de cinco filas ES, píxel a píxel, una `o` minúscula**: no le
  queda ningún rasgo con el que distinguirse. Comprobado sacando los dos glifos
  del atlas y comparándolos.

      O          Ó          ó
      .###.      ..##.      ..#..
      #...#      .....      .#...
      #...#      .###.      .###.
      #...#      #...#      #...#
      #...#      #...#      #...#
      #...#      #...#      #...#
      .###.      .###.      .###.

  **La salida barata: dejar que las mayúsculas con tilde usen también la fila 7**,
  que hoy está vacía en todos los glifos. Eso da un cuerpo de SEIS filas en vez
  de cinco, y un O de seis filas ya no se confunde con uno de cinco. Es un cambio
  en `fuente.py`. **No lo he tocado por dos razones**: lanzar `fuente.py` destruye
  los cinco marcos de la cáscara (está en Trampas, hay que restaurarlos con `git
  checkout` justo después), y el estilo de las tildes lo decidiste tú.
- **EL ESCRITORIO SOLO SE PUEDE TOCAR DURANTE EL COMBATE, y hay que decidir si
  eso vale.** El mapa (capa 20) y TILT (40) se dibujan MAXIMIZADOS y tapan la
  barra de tareas, que va en la 5. Mientras están delante, el sistema se apaga
  entero a propósito: si no, el botón Inicio seguiría siendo pulsable debajo del
  mapa y sería un clic que abre un menú donde no hay nada dibujado. Pero eso deja
  `RECUPERADO` accesible solo con un combate empezado, que es raro. **Dos
  salidas, y las dos son trabajo de otro sitio:** (a) que el mapa deje 24 px de
  hueco abajo y la barra de tareas se dibuje encima de él —lo correcto, y es
  geometría de `NodoPantallaMapa`, que hoy pone su propia barra de estado justo
  ahí—; o (b) que TILT y el mapa tengan su propio botón de "Recuperado". **La (a)
  es la buena**: una barra de tareas de verdad está siempre encima de todo.
- **Los iconos de `RECUPERADO` van a 16 px y se ven pequeños.** Es lo que hace un
  explorador de verdad, pero la cáscara viene de `bolas_64` y bajar de 64 a 16
  tira tres de cada cuatro píxeles. Si al mirarlo no se distinguen unas de otras,
  lo que falta es un juego de 16 —como `reliquias_32` se hizo para el
  escritorio—, no escalar distinto.
- **LA MESA ESTÁ EN OTRA PERSPECTIVA QUE EL RESTO DEL JUEGO, y hay que decidirlo
  antes de generar más arte de mesa.** El prompt que generó `assets/mesa/`
  —recuperado en `assets/GUIA_ESTILO.md`— pide *"seen from DIRECTLY ABOVE... no
  three-quarter angle, no sides visible"*, o sea cenital pura. Y `CONTEXTO.md`,
  "Perspectiva", dice de todo lo demás: *"los objetos están de pie hacia la
  cámara. No es cenital puro, y es a propósito: es lo que hace Peglin"*. Las dos
  posturas son defendibles —un bumper de una máquina real sí se ve desde
  arriba—, pero `PROPÓSITO.md` §8 pide arte de mesa nuevo (pines, segundo
  racimo, postes de outlane) y tiene que ir en la misma que el que se quede.
  **Decisión de Fátima.** Lo único que no vale es que la mesa tenga las dos.
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
- **En el mapa, el nodo de jefe enseña el retrato del enemigo normal** del
  que sale, porque un jefe sigue siendo "el enemigo más duro del acto con más
  vida". Los tres sprites de `assets/jefes/` NO se usan a propósito: enseñar
  un golem y meterte contra una "Rata mayor" sería el mapa mintiendo. Se
  conectan cuando los jefes sean enemigos de verdad, en Fase 6.
- **Los jefes son de mentira.** Ahora un jefe es el enemigo más duro del acto
  con 1,8× de vida y "mayor" en el nombre. Eso NO cumple `DISEÑO.md` §8: un
  enemigo con más vida no es un enemigo nuevo. Los jefes de verdad, con sus
  fases y los sprites de `assets/jefes/`, son Fase 6.
- **La recompensa sale del combate, no del mapa.** El nodo del mapa sigue sin
  decir qué te va a dar, porque hasta que haya chatarra y tienda (Fases 4 y 6)
  todos los combates dan lo mismo: tres reliquias al azar. Cuando un nodo pueda
  dar cosas distintas, la línea de recompensa entra en la ficha del mapa, que ya
  tiene el hueco previsto.
- **El eje de escalado se paga por victorias, no por tiempo.** `bolsa.victorias`
  lo lleva `Run` y sube solo al ganar un combate: un descanso no cuenta, o
  descansar daría poder además de vida.
- **27 de las 45 reliquias no tienen icono**, y ninguna tiene sonido propio:
  quedarse una suena con el arpegio del combo, que es un préstamo. Los prompts
  para el arte que falta están en `assets/prompts_reliquias.md`.
- **Las misiones son 14 y se ven casi todas en un run.** Con tres por combate y
  doce combates ves 36 tiradas de un cajón de 14: se repiten. Ampliar es barato
  —una fila de JSON— pero hay que hacerlo.
- **Una misión puede quedar imposible en una mesa concreta.** Si pide tres
  platillos y el platillo es el tiro más difícil de la mesa, esa escalera se
  atasca ahí y el jugador se queda sin las dos siguientes. No hay tiempo límite
  ni forma de saltarla a propósito: si esto molesta, lo que falta es poder
  cambiar de misión con un tiro, no bajarles la exigencia.
- **La duración larga puede destapar que los enemigos son sacos.** Con combates
  de 25 s daba igual que un enemigo solo tuviera vida y un ataque; con tres
  minutos, no. `DISEÑO.md` §11 tiene los seis comportamientos que hacen falta
  (bloquear un recorrido, curarse, reflejar, blindaje, castigar el combo,
  acelerar el reloj) y son Fase 6. Si Daniel dice que se hace largo, el orden
  del plan cambia: la Fase 6 sube antes que la cáscara.
- **La tele se come sitio en el hueco entre palas.** No es física, pero sí es
  arte: 184×124 px justo encima de los flippers, por donde pasa la bola
  constantemente. Si estorba visualmente, se encoge o se sube, pero tiene que
  seguir dentro del encuadre con la cámara anclada abajo.
- **La bola no tiene giro.** No hay spin simulado, así que no hay efecto ni
  bola que "muerda" en un ángulo. La rodadura es la aproximación barata a eso
  y aguanta bien; si en algún momento se quiere una física que destaque de
  verdad, el siguiente paso es momento angular en la bola, y es un cambio
  gordo que toca el solver entero.
- **Al jugador bueno no le pasa nada en los actos I y II.** Seis de nueve
  enemigos le hacen cero. El reloj fino le quitó el escondite, pero al aflojar
  la dificultad los combates se acortaron a 7-14 s y la mayoría vuelven a caer
  por debajo de los 9 s de carga: **el problema del escalón reaparece a cada
  escala nueva**, porque aflojar acorta los combates y acortarlos vuelve a
  esconder al bueno. Si se quiere que note algo pronto, el camino es enemigos
  con MÁS vida y MENOS ataque (fila `1.20 / 0.85` del barrido), no seguir
  bajando números.
- **Los perfiles del medidor son una aproximación.** Un perfil describe lo que
  produce una bola, no juega con las palas: no hay física dentro. Sirve para la
  economía del combate, que es lo que se estaba midiendo, pero no dice nada de
  si un tiro es cazable ni de cómo se siente nada.
- **Los paneles de la derecha siguen encendidos durante la ruleta.** La mesa se
  apaga y la tele manda, pero el enemigo y las barras siguen a plena luz en su
  banda, que es otra capa. Es a propósito —así se ve contra quién estás—, pero
  si distrae en la ruleta, atenuarlos es un `modulate` y hay que probarlo
  antes: el enemigo lleva shader y el `modulate` puede no aplicarle.
- **La bandeja del reloj de la barra de tareas sigue dibujada con `draw_rect`**
  a mano, porque su arte es lo único de `prompts_cascara.md` §2 que no se ha
  generado. Es la tanda 3 de "Siguiente".
- **El juego se llama Cascabel** (`DISEÑO.md` rev. 4). Las rutas y el nombre del
  repo siguen siendo `tilt-os` a propósito. La cáscara del sistema operativo es
  el marco visual, en pixelart con marcos de nueve trozos y sin gestor de
  ventanas.
