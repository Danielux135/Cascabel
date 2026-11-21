# hoja.py — junta varias capturas en UNA imagen con su rótulo, para mirarlas de un vistazo.
#
#   python cripta3d/herramientas/hoja.py salida.png captura1.png captura2.png ... [--cols 4] [--alto 360]
#   python cripta3d/herramientas/hoja.py salida.png carpeta_con_png            [--cols 4] [--alto 360]
#          [--gris]  fondo gris medio (7A6B52), para sprites: sobre negro no se ve el contorno
#          [--vecino] ampliar sin suavizar (pixelart)
#
# Mirar doce capturas una a una son doce lecturas de imagen; mirarlas en una hoja es una.
# Y se comparan mejor: lo que canta en un mosaico no canta en un PNG suelto.
import glob
import os
import sys

from PIL import Image, ImageDraw, ImageFont


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass
    a = sys.argv[1:]
    if len(a) < 2:
        with open(__file__, encoding="utf-8") as f:
            print(f.read().split("import glob")[0])
        return 2
    cols, alto, gris, vecino = 4, 360, False, False
    rutas, salida = [], None
    i = 0
    while i < len(a):
        if a[i] == "--cols":
            i += 1
            cols = int(a[i])
        elif a[i] == "--alto":
            i += 1
            alto = int(a[i])
        elif a[i] == "--gris":
            gris = True
        elif a[i] == "--vecino":
            vecino = True
        elif salida is None:
            salida = a[i]
        elif os.path.isdir(a[i]):
            rutas += sorted(glob.glob(os.path.join(a[i], "*.png")))
        else:
            rutas += sorted(glob.glob(a[i])) or [a[i]]
        i += 1
    rutas = [r for r in rutas if os.path.abspath(r) != os.path.abspath(salida)]
    ims = []
    for r in rutas:
        try:
            im = Image.open(r).convert("RGBA")
        except Exception as e:
            print("no abre:", r, e)
            continue
        k = alto / im.height
        im = im.resize((max(1, round(im.width * k)), alto), Image.NEAREST if vecino else Image.LANCZOS)
        ims.append((os.path.splitext(os.path.basename(r))[0], im))
    if not ims:
        print("[hoja] no hay imágenes")
        return 1
    cols = max(1, min(cols, len(ims)))
    ancho = max(im.width for _, im in ims)
    filas = (len(ims) + cols - 1) // cols
    pad, rot = 6, 20
    fondo = (0x7A, 0x6B, 0x52, 255) if gris else (18, 18, 22, 255)
    hoja = Image.new("RGBA", (cols * (ancho + pad) + pad, filas * (alto + rot + pad) + pad), fondo)
    dr = ImageDraw.Draw(hoja)
    try:
        fuente = ImageFont.truetype("arial.ttf", 15)
    except Exception:
        fuente = ImageFont.load_default()
    for n, (nombre, im) in enumerate(ims):
        x = pad + (n % cols) * (ancho + pad)
        y = pad + (n // cols) * (alto + rot + pad)
        hoja.alpha_composite(im, (x + (ancho - im.width) // 2, y + rot))
        dr.text((x + 2, y + 1), nombre, fill=(235, 235, 235, 255), font=fuente)
    hoja.convert("RGB").save(salida)
    print("[hoja] %s: %d imágenes, %dx%d" % (salida, len(ims), hoja.width, hoja.height))
    return 0


if __name__ == "__main__":
    sys.exit(main())
