# Prompts para los iconos de reliquia que faltan

45 reliquias, 18 con icono (los que ya estaban en `assets/reliquias/`), **27 sin
él**. Aquí están los tres prompts que los generan, en tres hojas de nueve.

**Antes de pegar el prompt hay que pegar el style guide**, como en el resto de
generaciones: estos empiezan por "Following the style guide above".

Después:

    python3 procesar.py hoja.png --tam 64 --columnas 3 --salida assets/reliquias/ --nombres "a,b,c,..."
    python3 procesar.py hoja.png --tam 32 --columnas 3 --salida assets/reliquias_32/ --nombres "a,b,c,..."

**Los nombres tienen que ser exactamente los `icono` de `data/reliquias.json`**, y
hay una prueba que lo comprueba (`_prueba_iconos`): un icono que falte no da
error, solo deja una tarjeta sin dibujo.

---

## Por qué el prompt dice lo que dice

Tres restricciones, y las tres vienen de fallos que ya han pasado:

1. **Se ven a 32.** Cada icono se usa a 64 en la tarjeta de recompensa y a 32 en
   el escritorio. Un objeto con detalle fino se convierte en papilla al reducir,
   y no se nota hasta que está dentro del juego. Por eso el prompt pide silueta
   gorda, un solo objeto y nada de líneas de un píxel.
2. **`procesar.py` recorta por silueta, no por rejilla.** Necesita separación
   real entre los nueve objetos y magenta limpio: una sombra suave en el suelo
   sobrevive al recorte y se queda de manchurrón gris.
3. **Nada de marcos ni placas.** El marco lo pone la tarjeta. Un icono que traiga
   su propio borde se ve como un botón dentro de otro botón.

---

## Hoja 1 — combo y golpe único

> Following the style guide above, create a 3x3 grid of nine item icons on a
> flat magenta `#FF00FF` background.
>
> CRITICAL: each icon must still read at 32x32 pixels. That means ONE object per
> cell, a fat unmistakable silhouette, and no fine detail: no thin one-pixel
> lines, no small text, no engraved writing, no filigree, no chains made of tiny
> links. If you have to squint to tell what it is, it is wrong.
>
> CRITICAL: the nine objects must be clearly separated, each well inside its own
> cell with empty magenta all around it. Nothing may touch or overlap a
> neighbour. No cast shadows, no ground shadow, no glow bleeding onto the
> magenta: the background must stay one flat pure colour so it can be cut away.
>
> CRITICAL: no frames, no borders, no plaques, no cards and no backing panels
> behind the objects. Just the bare object floating on magenta.
>
> Each object faces the viewer, standing up towards the camera like an item
> sprite in a top-down RPG, not seen from directly above.
>
> Row 1: a glowing ember held in a pair of iron tongs · a thick rope tied in a
> running slipknot · three interlocking brass gears
>
> Row 2: a wooden pendulum metronome · a spool of silk thread with a loose end
> hanging · a cold iron chisel with frost on its blade
>
> Row 3: a bronze aiming ring with a crosshair across it · a fat powder charge
> with a fuse · a length of rail track with a switch lever

Nombres: `brasa_pinzas,nudo_soga,engranajes,metronomo,carrete_seda,cincel_frio,mira_bronce,carga_polvora,via_aguja`

## Hoja 2 — supervivencia y escalado

> Following the style guide above, create a 3x3 grid of nine item icons on a
> flat magenta `#FF00FF` background.
>
> CRITICAL: each icon must still read at 32x32 pixels. ONE object per cell, a fat
> unmistakable silhouette, no thin one-pixel lines, no small text, no engraved
> writing, no filigree.
>
> CRITICAL: the nine objects must be clearly separated, each well inside its own
> cell with empty magenta all around it. No cast shadows, no ground shadow, no
> glow bleeding onto the magenta.
>
> CRITICAL: no frames, no borders, no plaques and no backing panels. Just the
> bare object floating on magenta.
>
> Each object faces the viewer, standing up towards the camera like an item
> sprite in a top-down RPG.
>
> Row 1: a thick new rubber ring · a riveted steel plate · a heavy coil spring
> inside a short cylinder
>
> Row 2: a brass relief valve venting steam · a padded leather cushion with a
> strap · a carved stone tally slab with deep notches
>
> Row 3: a hot brick wrapped in cloth · a copper coil covered in frost · a
> cracked ceramic tile mended with thick gold seams

Nombres: `aro_goma,chapa_remaches,amortiguador,valvula_vapor,cojin_correa,losa_muescas,ladrillo_caliente,bobina_escarcha,teja_dorada`

## Hoja 3 — caos, y lo que queda

> Following the style guide above, create a 3x3 grid of nine item icons on a
> flat magenta `#FF00FF` background.
>
> CRITICAL: each icon must still read at 32x32 pixels. ONE object per cell, a fat
> unmistakable silhouette, no thin one-pixel lines, no small text, no filigree.
> The broken and bent things must break in big obvious chunks, not in splinters:
> a crack has to be three pixels wide to survive.
>
> CRITICAL: the nine objects must be clearly separated, each well inside its own
> cell with empty magenta all around it. No cast shadows, no ground shadow, no
> glow bleeding onto the magenta.
>
> CRITICAL: no frames, no borders, no plaques and no backing panels. Just the
> bare object floating on magenta.
>
> Each object faces the viewer, standing up towards the camera like an item
> sprite in a top-down RPG.
>
> Row 1: a torn promissory note pinned through by a dagger · a ledger book with
> thick page tabs sticking out · a birdcage with its door burst open
>
> Row 2: two identical iron keys tied together with cord · a pressure gauge with
> the needle jammed past the red · a jug tipped over spilling coins
>
> Row 3: a carved wooden pointing hand hanging off a loose nail · a metal snake
> biting its own tail · a cracked alarm bell

Nombres: `pagare_daga,libro_pestanas,jaula_rota,llaves_gemelas,manometro_rojo,jarra_monedas,mano_madera,serpiente_anillo,campana_rajada`

---

## Qué reliquia se lleva cada icono

Al procesar las hojas hay que escribir el `icono` en `data/reliquias.json`:

| icono | reliquia |
|---|---|
| `brasa_pinzas` | arranque_en_caliente |
| `nudo_soga` | nudo_corredizo |
| `engranajes` | tren_de_engranajes |
| `metronomo` | metronomo |
| `carrete_seda` | carrete_de_seda |
| `cincel_frio` | punteria_fria |
| `mira_bronce` | mira_de_bronce |
| `carga_polvora` | carga_hueca |
| `via_aguja` | via_unica |
| `aro_goma` | gomas_nuevas |
| `chapa_remaches` | chapa_remachada |
| `amortiguador` | amortiguador |
| `valvula_vapor` | valvula_de_purga |
| `cojin_correa` | cuna_acolchada |
| `losa_muescas` | memoria_reservada |
| `ladrillo_caliente` | cache_caliente |
| `bobina_escarcha` | bobina_enfriada |
| `teja_dorada` | desfragmentacion |
| `pagare_daga` | deuda_tecnica |
| `libro_pestanas` | indice_invertido |
| `jaula_rota` | excepcion_no_capturada |
| `llaves_gemelas` | copia_de_seguridad |
| `manometro_rojo` | sobrecarga |
| `jarra_monedas` | desbordamiento |
| `mano_madera` | puntero_colgante |
| `serpiente_anillo` | bucle_infinito |
| `campana_rajada` | panico_del_kernel |
