"""COMPARAR: el antes y el después, con números.

    python cripta3d/herramientas/comparar.py tomas <antes> <despues> [hoja.png]
    python cripta3d/herramientas/comparar.py giras <gira_antes> <gira_despues> <salida>

`tomas` compara dos carpetas con las MISMAS capturas (las de `gira.py … fijas`):
de cada una dice la diferencia media, la mediana, el percentil 99, cuántos
píxeles cambian más de 3 niveles (de 255) y la luminancia media de antes y de
después. Con una hoja, deja además la diferencia de cada toma multiplicada por
ocho, que es donde se ve DÓNDE cambia.

`giras` pone lado a lado dos giras enteras (`<salida>/pares/<grupo>/<toma>.png`,
antes a la izquierda) y escribe `<salida>/medidas.md` con la luminancia y el
color medio de cada toma. Es para los ojos: las tomas de «juego» y «criaturas»
las juega un piloto y no caen igual dos veces.

POR QUÉ EXISTE. «Se ve igual» no vale. Al copiar a mano la luz de Godot para que
la piedra compilara antes, la piedra salió un 2,8 % más clara (el difuso por
defecto de Compatibility es Lambert y se había copiado Burley). A ojo no se
distinguía; aquí daba 1,3 de media con un 10 % de píxeles cambiados, contra un
ruido de 0,02. Para saber cuánto ruido hay, se sacan las tomas DOS veces con el
mismo código y se comparan entre sí antes de comparar el cambio.

Las capturas y lo que esto escribe, FUERA del repo.
"""

import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageStat

GRUPOS = ("juego", "piezas", "sala", "criaturas")


def luminancia(im):
    return ImageStat.Stat(im.convert("L")).mean[0]


def tomas(antes, despues, hoja):
    difs = []
    peor = 0.0
    for fa in sorted(antes.glob("*.png")):
        fb = despues / fa.name
        if not fb.exists():
            print(fa.name, "FALTA EN EL DESPUÉS")
            continue
        a = Image.open(fa).convert("RGB")
        b = Image.open(fb).convert("RGB")
        if b.size != a.size:
            print(fa.name, "OTRO TAMAÑO", a.size, b.size)
            continue
        d = ImageChops.difference(a, b).convert("L")
        h = d.histogram()
        n = sum(h)
        media = sum(i * c for i, c in enumerate(h)) / n
        acum, mediana, p99 = 0, -1, 0
        for i, c in enumerate(h):
            acum += c
            if mediana < 0 and acum >= n * 0.5:
                mediana = i
            if acum >= n * 0.99:
                p99 = i
                break
        mas3 = 100.0 * sum(h[4:]) / n
        peor = max(peor, media)
        print("%-28s media %5.2f · mediana %d · p99 %3d · >3 niveles %5.2f %% · luminancia %6.2f -> %6.2f" % (
            fa.name, media, mediana, p99, mas3, luminancia(a), luminancia(b)))
        difs.append(d.point(lambda v: min(255, v * 8)).resize((480, 270)))
    print("PEOR media: %.2f" % peor)
    if hoja and difs:
        cols = 4
        filas = (len(difs) + cols - 1) // cols
        lienzo = Image.new("L", (cols * 480, filas * 270))
        for i, d in enumerate(difs):
            lienzo.paste(d, ((i % cols) * 480, (i // cols) * 270))
        lienzo.save(hoja)
        print("diferencias ×8 en", hoja)
    return 0


def color(im):
    r, g, b = ImageStat.Stat(im).mean[:3]
    return "%3.0f %3.0f %3.0f" % (r, g, b)


def giras(antes, despues, salida):
    filas = []
    for grupo in GRUPOS:
        (salida / "pares" / grupo).mkdir(parents=True, exist_ok=True)
        for fa in sorted((antes / grupo).glob("*.png")):
            fb = despues / grupo / fa.name
            if not fb.exists():
                filas.append((grupo, fa.name, None))
                continue
            a = Image.open(fa).convert("RGB")
            b = Image.open(fb).convert("RGB")
            if b.size != a.size:
                b = b.resize(a.size)
            w, h = a.size
            par = Image.new("RGB", (w, h // 2), (0, 0, 0))
            par.paste(a.resize((w // 2, h // 2)), (0, 0))
            par.paste(b.resize((w // 2, h // 2)), (w // 2, 0))
            d = ImageDraw.Draw(par)
            d.rectangle((0, 0, 84, 18), fill=(0, 0, 0))
            d.text((6, 3), "ANTES", fill=(255, 255, 255))
            d.rectangle((w // 2, 0, w // 2 + 96, 18), fill=(0, 0, 0))
            d.text((w // 2 + 6, 3), "DESPUES", fill=(255, 220, 120))
            par.save(salida / "pares" / grupo / fa.name)
            centro = (w // 3, 0, 2 * w // 3, h)
            dif = ImageStat.Stat(ImageChops.difference(a, b).convert("L")).mean[0]
            filas.append((grupo, fa.name, (luminancia(a), luminancia(b), luminancia(a.crop(centro)),
                                           luminancia(b.crop(centro)), color(a.crop(centro)),
                                           color(b.crop(centro)), dif)))
    lineas = ["# Antes y después, toma a toma", "",
              "Luminancia media (0-255). «Centro» es el tercio central de la imagen.",
              "La columna «cambio» es el del centro, en tanto por ciento. Un «OJO» en una",
              "toma con algo que se mueve (la campana, un torno, una criatura) suele ser",
              "la postura, no el aspecto: se mira el par.", "",
              "| grupo | toma | entera antes | entera después | centro antes | centro después | cambio | color centro antes | color centro después | diferencia media |",
              "|---|---|---|---|---|---|---|---|---|---|"]
    for grupo, nombre, m in filas:
        if m is None:
            lineas.append("| %s | %s | FALTA EN EL DESPUÉS | | | | | | | |" % (grupo, nombre))
            continue
        la, lb, ca, cb, cola, colb, dif = m
        cambio = 100.0 * (cb - ca) / max(ca, 0.01)
        marca = " **OJO**" if abs(cambio) > 6.0 else ""
        lineas.append("| %s | %s | %.1f | %.1f | %.1f | %.1f | %+.1f %%%s | %s | %s | %.1f |" % (
            grupo, nombre, la, lb, ca, cb, cambio, marca, cola, colb, dif))
    (salida / "medidas.md").write_text("\n".join(lineas) + "\n", encoding="utf-8")
    print("pares:", sum(1 for f in filas if f[2]), "· sin pareja:", sum(1 for f in filas if not f[2]))
    print("escrito", salida / "medidas.md")
    return 0


def main():
    a = sys.argv[1:]
    if len(a) < 3 or a[0] not in ("tomas", "giras") or (a[0] == "giras" and len(a) < 4):
        print(__doc__)
        return 2
    repo = Path(__file__).resolve().parent.parent.parent
    for ruta in a[3:4]:
        destino = Path(ruta).resolve()
        if destino == repo or repo in destino.parents:
            print("[comparar] lo que escribe no puede ir dentro del repo (%s)" % repo)
            return 2
    if a[0] == "tomas":
        return tomas(Path(a[1]), Path(a[2]), a[3] if len(a) > 3 else "")
    return giras(Path(a[1]), Path(a[2]), Path(a[3]))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main())
