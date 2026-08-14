#!/usr/bin/env python3
"""
Tubería de procesado de sprites para el pinball roguelike.

Toma un PNG generado (una rejilla NxM o un sprite suelto), lo recorta,
lo baja a resolución real, lo cuantiza a la paleta cerrada y lo deja
listo para el juego.

Uso:
    python3 procesar.py entrada.png --rejilla 3x3 --tam 64 --salida assets/
"""

import argparse
import os
import numpy as np
from PIL import Image
from scipy import ndimage

# ----------------------------------------------------------------- paleta
PALETA_HEX = [
    # neutros y acero (faltaban: sin ellos los grises se van al violeta)
    "14121A", "2A2A33", "43434F", "62636F", "8C8D99", "B9BAC4", "E4E6EC",
    # piedra (sin esta rampa, todo lo gris se iba al marron de cuero)
    "3A3832", "55524A", "7A7669", "A09B8A",
    # tierra, cuero y pergamino
    "2B2028", "4A3A42", "755F52", "A88968", "D9BF95", "F5E9CE",
    # rojos
    "8C2E2E", "C74A3C", "E8814A",
    # oro y laton
    "8A6524", "E0A63C", "F7D86B",
    # cobre y bronce (sin esto, el cobre se iba al rojo)
    "6B3A22", "A0603A", "C98A4B",
    # verdes (desaturados: el original salia de neon)
    "2F5A38", "4E7C3A", "7BA84A",
    # azules frios
    "274A63", "4478A0",
    # arcano
    "6B3F9E", "A97BD9",
]
PALETA = np.array([[int(h[i:i+2], 16) for i in (0, 2, 4)] for h in PALETA_HEX],
                  dtype=np.float32)

FONDO = np.array([243, 16, 233], dtype=np.float32)   # magenta nominal (reserva)
TOL_FONDO = 95.0                                     # solo para el desflecado

# --- deteccion de fondo por TONO, no por distancia RGB -------------------
# La distancia euclidea al magenta se come los violetas saturados del arte:
# (156,5,197) —la llama de la calavera, el cuerpo del espectro— cae a 88 del
# magenta, por debajo de los 95 de tolerancia, y desaparece. El tono no: el
# fondo es magenta puro (S~0.95) y un violeta de dibujo baja de saturacion o
# se va 25-30 grados de tono. Comparar en HSV separa las dos cosas.
TONO_MARGEN = 14.0     # grados alrededor del tono del fondo
SAT_MINIMA = 0.72      # por debajo es color de dibujo, no fondo plano
VAL_MINIMO = 0.62      # por debajo es una sombra, no fondo


def hsv(rgb):
    """rgb float 0-255 (..., 3) -> (tono 0-360, saturacion 0-1, valor 0-1)."""
    a = rgb.astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx, mn = a.max(-1), a.min(-1)
    c = mx - mn
    v = mx / 255.0
    s = np.where(mx > 0, c / np.maximum(mx, 1e-6), 0.0)
    h = np.zeros_like(mx)
    m = c > 0
    i = (mx == r) & m; h[i] = (60 * ((g - b)[i] / c[i])) % 360
    i = (mx == g) & m; h[i] = 60 * ((b - r)[i] / c[i]) + 120
    i = (mx == b) & m; h[i] = 60 * ((r - g)[i] / c[i]) + 240
    return h, s, v


def color_de_fondo(rgb):
    """El generador no siempre da el mismo magenta (hemos visto 224,12,223 y
    243,16,233). Se lee del borde de la hoja en vez de darlo por supuesto."""
    borde = np.concatenate([rgb[0, :], rgb[-1, :], rgb[:, 0], rgb[:, -1]])
    return np.median(borde, axis=0).astype(np.float32)


def es_magenta(rgb, ref, margen=TONO_MARGEN, sat=SAT_MINIMA, val=VAL_MINIMO):
    h, s, v = hsv(rgb)
    hr = hsv(ref.reshape(1, 1, 3))[0][0, 0]
    dh = np.minimum(np.abs(h - hr), 360 - np.abs(h - hr))
    return (dh < margen) & (s > sat) & (v > val)


# ------------------------------------------------------------------- color
def srgb_a_lab(rgb):
    """rgb float 0-255, forma (..., 3) -> Lab. Cuantizar en Lab evita que
    los tonos oscuros se colapsen todos en el mismo color."""
    c = rgb / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124, 0.3576, 0.1805],
                  [0.2126, 0.7152, 0.0722],
                  [0.0193, 0.1192, 0.9505]], dtype=np.float32)
    xyz = c @ m.T
    blanco = np.array([0.95047, 1.0, 1.08883], dtype=np.float32)
    xyz = xyz / blanco
    e = 216 / 24389
    k = 24389 / 27
    f = np.where(xyz > e, np.cbrt(xyz), (k * xyz + 16) / 116)
    L = 116 * f[..., 1] - 16
    a = 500 * (f[..., 0] - f[..., 1])
    b = 200 * (f[..., 1] - f[..., 2])
    return np.stack([L, a, b], axis=-1)


PALETA_LAB = srgb_a_lab(PALETA)


def cuantizar(rgb, mascara):
    """Sustituye cada píxel por el color más cercano de la paleta."""
    salida = rgb.copy()
    pts = rgb[mascara].astype(np.float32)
    if len(pts) == 0:
        return salida
    lab = srgb_a_lab(pts)
    d = ((lab[:, None, :] - PALETA_LAB[None, :, :]) ** 2).sum(axis=2)
    salida[mascara] = PALETA[d.argmin(axis=1)].astype(np.uint8)
    return salida


# ------------------------------------------------------------------ fondo
def mascara_fondo(rgb):
    """Fondo = pixeles de TONO magenta QUE ADEMAS esten conectados con el
    borde. Sin lo segundo, un objeto violeta se recortaria por dentro."""
    ref = color_de_fondo(rgb)
    parecido = es_magenta(rgb.astype(np.float32), ref)
    etiquetas, n = ndimage.label(parecido)
    if n == 0:
        return np.zeros(rgb.shape[:2], dtype=bool)
    borde = set(etiquetas[0, :]) | set(etiquetas[-1, :]) \
        | set(etiquetas[:, 0]) | set(etiquetas[:, -1])
    borde.discard(0)

    # bolsas de fondo encerradas: el hueco de un muelle o el ojo de una llave
    # no tocan el borde, pero siguen siendo fondo. Criterio mas estricto para
    # no confundirlas con un objeto violeta.
    estricto = es_magenta(rgb.astype(np.float32), ref, margen=8, sat=0.85)
    encerradas = [e for e in range(1, n + 1)
                  if e not in borde
                  and (etiquetas == e).sum() > 4
                  and estricto[etiquetas == e].mean() > 0.7]

    fondo = np.isin(etiquetas, list(borde) + encerradas)

    # tapar los dedos de fondo que se cuelan por un hueco de 1-2 px entre
    # mechones: el espectro perdia el 22% del cuerpo por ahi. Solo se
    # recupera lo que NO sea magenta de verdad, asi que un hueco legitimo
    # (el ojo de una llave) se queda abierto.
    objeto = ndimage.binary_closing(~fondo, np.ones((3, 3)), border_value=0)
    recuperado = objeto & fondo & ~estricto
    return fondo & ~recuperado


# ---------------------------------------------------------------- proceso
def desflecar(rgb, objeto):
    """Los bordes suavizados dejan un halo magenta dentro del objeto —muy
    visible en huecos pequeños, como el interior de un muelle—. Esos píxeles
    se sustituyen por el color válido más cercano."""
    ref = color_de_fondo(rgb)
    # solo en la franja pegada al fondo: si no, un objeto violeta —un vial de
    # poción— se detecta entero como halo y se destruye. Y el criterio es de
    # TONO, con el margen abierto: un halo es magenta lavado, no violeta.
    franja = ndimage.binary_dilation(~objeto, iterations=4) & objeto
    sucio = franja & es_magenta(rgb.astype(np.float32), ref,
                                margen=22, sat=0.45, val=0.45)
    limpio = objeto & ~sucio
    if not sucio.any() or not limpio.any():
        return rgb
    _, idx = ndimage.distance_transform_edt(~limpio, return_indices=True)
    salida = rgb.copy()
    salida[sucio] = rgb[idx[0][sucio], idx[1][sucio]]
    return salida


def procesar_celda(rgb, tam, margen=2, escala=None, al_suelo=False):
    fondo = mascara_fondo(rgb)
    objeto = ~fondo
    if not objeto.any():
        return None
    rgb = desflecar(rgb, objeto)

    ys, xs = np.where(objeto)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1

    rgba = np.dstack([rgb, (objeto * 255).astype(np.uint8)])
    recorte = Image.fromarray(rgba[y0:y1, x0:x1], "RGBA")

    # reducir manteniendo proporción, dejando margen
    util = tam - margen * 2
    w, h = recorte.size
    k = escala if escala else util / max(w, h)
    nuevo = (max(1, round(w * k)), max(1, round(h * k)))
    reducido = recorte.resize(nuevo, Image.BOX)

    lienzo = Image.new("RGBA", (tam, tam), (0, 0, 0, 0))
    y = tam - margen - nuevo[1] if al_suelo else (tam - nuevo[1]) // 2
    lienzo.paste(reducido, ((tam - nuevo[0]) // 2, max(0, y)))

    a = np.array(lienzo)
    alfa = a[..., 3] > 128            # umbral: sin bordes semitransparentes
    color = cuantizar(a[..., :3], alfa)
    salida = np.dstack([color, (alfa * 255).astype(np.uint8)])
    salida[~alfa] = 0
    return Image.fromarray(salida, "RGBA")


def agrupar(mascara, area_min=400, hueco=0.02):
    """Detecta los sprites por su silueta en lugar de trocear en rejilla.
    Una rejilla fija falla en cuanto un icono se sale de su casilla."""
    etiquetas, n = ndimage.label(mascara)
    cajas = []
    for e, sl in enumerate(ndimage.find_objects(etiquetas), start=1):
        if (etiquetas[sl] == e).sum() < area_min:
            continue
        cajas.append([sl[0].start, sl[0].stop, sl[1].start, sl[1].stop, {e}])

    margen = int(max(mascara.shape) * hueco)
    fusionado = True
    while fusionado:
        fusionado = False
        for i in range(len(cajas)):
            for j in range(i + 1, len(cajas)):
                a, b = cajas[i], cajas[j]
                if (a[0] - margen < b[1] and b[0] - margen < a[1]
                        and a[2] - margen < b[3] and b[2] - margen < a[3]):
                    cajas[i] = [min(a[0], b[0]), max(a[1], b[1]),
                                min(a[2], b[2]), max(a[3], b[3]), a[4] | b[4]]
                    cajas.pop(j)
                    fusionado = True
                    break
            if fusionado:
                break

    # orden de lectura: por filas, y dentro de cada fila de izquierda a derecha
    alto = np.median([c[1] - c[0] for c in cajas]) if cajas else 1
    cajas.sort(key=lambda c: (round((c[0] + c[1]) / 2 / alto), c[2]))
    return cajas, etiquetas


def main():
    p = argparse.ArgumentParser()
    p.add_argument("entrada")
    p.add_argument("--tam", type=int, default=64)
    p.add_argument("--salida", default="salida")
    p.add_argument("--prefijo", default="sprite")
    p.add_argument("--columnas", type=int, default=3,
                   help="solo para maquetar la vista previa")
    p.add_argument("--tira", type=int, default=0, metavar="N",
                   help="tira de animacion de N fotogramas: corta en rejilla "
                        "fija, NO por silueta, para que no se desplacen")
    p.add_argument("--filas", type=int, default=1,
                   help="filas de la tira (varias tiras apiladas)")
    p.add_argument("--conjunto", action="store_true",
                   help="misma escala para toda la hoja y pies alineados: "
                        "conserva los tamanos relativos entre sprites")
    p.add_argument("--nombres", default=None,
                   help="nombres separados por coma, en orden de lectura")
    args = p.parse_args()

    im = Image.open(args.entrada).convert("RGB")
    a = np.array(im)
    objeto = ~mascara_fondo(a)
    cajas, etiquetas = agrupar(objeto)
    print(f"  {len(cajas)} sprites detectados")

    nombres = args.nombres.split(",") if args.nombres else None
    os.makedirs(args.salida, exist_ok=True)

    if args.tira:
        W, H = im.size
        cols, filas = args.tira, args.filas
        cajas = []
        for f in range(filas):
            for c in range(cols):
                cajas.append((f*H//filas, (f+1)*H//filas,
                              c*W//cols, (c+1)*W//cols, None))
        print(f"  tira: {cols}x{filas} en rejilla fija (sin recorte por silueta)")

    escala = None
    if args.conjunto and cajas:
        mayor = max(max(c[1]-c[0], c[3]-c[2]) for c in cajas)
        escala = (args.tam - 4) / mayor
        print(f"  escala comun: el mayor ocupa {args.tam-4} px")

    hechos = []
    for i, (y0, y1, x0, x1, ids) in enumerate(cajas):
        recorte = a[y0:y1, x0:x1].copy()
        # borrar lo que pertenezca a otro sprite y caiga dentro de esta caja
        if ids is None:
            propio = np.ones((y1-y0, x1-x0), bool)
        else:
            propio = np.isin(etiquetas[y0:y1, x0:x1], list(ids))
        ajeno = objeto[y0:y1, x0:x1] & ~propio
        recorte[ajeno] = FONDO.astype(np.uint8)

        sp = procesar_celda(recorte, args.tam, escala=escala,
                            al_suelo=args.conjunto)
        if sp is None:
            continue
        nombre = nombres[i].strip() if nombres and i < len(nombres) \
            else f"{args.prefijo}_{i+1:02d}"
        sp.save(os.path.join(args.salida, f"{nombre}.png"))
        hechos.append((nombre, sp))
        print(f"  {nombre}.png  {args.tam}x{args.tam}")

    if hechos:
        cols = args.columnas
        filas = (len(hechos) + cols - 1) // cols
        z = max(1, 384 // args.tam)
        hoja = Image.new("RGBA", (cols*args.tam*z, filas*args.tam*z),
                         (32, 26, 38, 255))
        for i, (_, sp) in enumerate(hechos):
            g = sp.resize((args.tam*z, args.tam*z), Image.NEAREST)
            hoja.paste(g, ((i % cols)*args.tam*z, (i // cols)*args.tam*z), g)
        hoja.save(os.path.join(args.salida, "_vista_previa.png"))
        print(f"\nvista previa: {args.salida}/_vista_previa.png")


if __name__ == "__main__":
    main()
