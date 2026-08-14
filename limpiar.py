#!/usr/bin/env python3
"""
Reparacion de sprites YA recortados, para los que no queda hoja original.

Arregla tres averias distintas, y las tres son invisibles en un visor pero
cantan dentro del juego:

  1. SAL DE CUANTIZACION. Un pixel suelto al que la cuantizacion a paleta le
     asigno un color que no tiene nada que ver con sus vecinos: motas verdes
     en una armadura marron. No es ruido del generador, lo mete procesar.py.
  2. INTERIOR COMIDO. El recorte por distancia RGB al magenta borraba los
     violetas saturados, asi que a los sprites morados les faltan trozos de
     cuerpo por dentro. (La causa esta arreglada en procesar.py; esto repara
     lo que ya salio mal y no se puede rehacer.)
  3. MOTAS SUELTAS. Islas opacas de 1-3 px separadas del cuerpo, que son
     restos del recorte, no dibujo.

Uso:
    python3 limpiar.py assets/            # informe, no toca nada
    python3 limpiar.py assets/ --aplicar  # escribe
"""
import argparse, glob, os
import numpy as np
from PIL import Image
from scipy import ndimage
from procesar import srgb_a_lab, hsv


def vecinos8(a):
    """Apila los 8 desplazamientos de un array 2D en un eje nuevo."""
    p = np.pad(a, 1, mode="edge")
    return np.stack([p[i:i+a.shape[0], j:j+a.shape[1]]
                     for i in (0, 1, 2) for j in (0, 1, 2)
                     if (i, j) != (1, 1)], axis=-1)


def quitar_sal(rgb, op, umbral=42.0):
    """Un pixel es sal si TODOS sus vecinos opacos estan lejos de el en Lab.
    El umbral va en Lab (dE): 42 deja pasar un brillo especular o el punto de
    luz de un ojo —que tambien es un pixel solo, pero de un color vecino— y
    caza el verde perdido en mitad del marron."""
    lab = srgb_a_lab(rgb.astype(np.float32))
    vl = np.stack([vecinos8(lab[..., k]) for k in range(3)], axis=-2)  # h,w,3,8
    vop = vecinos8(op)
    d = np.sqrt(((vl - lab[..., None]) ** 2).sum(axis=-2))             # h,w,8
    d = np.where(vop, d, np.inf)
    cerca = (d < umbral).sum(-1)
    n_op = vop.sum(-1)
    sal = op & (cerca == 0) & (n_op >= 5)      # rodeado, y de nadie parecido
    if not sal.any():
        return rgb, 0
    # sustituir por el vecino opaco mas cercano que NO sea sal
    limpio = op & ~sal
    _, idx = ndimage.distance_transform_edt(~limpio, return_indices=True)
    out = rgb.copy()
    out[sal] = rgb[idx[0][sal], idx[1][sal]]
    return out, int(sal.sum())


def tapar_comido(rgb, op, cierre=3, min_riesgo=0.55):
    """Devuelve al cuerpo lo que el recorte se llevo, pero SOLO donde el
    hueco lleve la firma del bug.

    Un hueco dentro de la silueta no significa nada por si solo: el girador
    tiene radios, la reja tiene barrotes y la grieta es un hueco a proposito.
    Rellenarlos todos destroza mas de lo que arregla. La firma del fallo es
    otra: el borde del hueco tiene que ser color VIOLETA EN RIESGO, o sea
    cerca del magenta midiendo como media el algoritmo viejo (RGB) y lejos
    midiendo por tono, que es justo lo que se borraba de mas. Un radio de
    girador tiene el borde de acero y no pasa el filtro.
    """
    cerr = ndimage.binary_fill_holes(
        ndimage.binary_closing(op, np.ones((cierre, cierre)), border_value=0))
    falta = cerr & ~op
    if not falta.any():
        return rgb, op, 0

    # "violeta en riesgo" se mide sobre lo que SOBREVIVIO, ya cuantizado a
    # paleta, asi que no vale compararlo con el magenta: el borde del
    # espectro es 6B3F9E, a 161 del fondo. Lo que identifica al sospechoso
    # es ser violeta de verdad —tono 255-330, con color y con luz—. El acero
    # de un radio de girador no tiene saturacion y la grieta no tiene luz.
    h, sat, val = hsv(rgb.astype(np.float32))
    riesgo = (h > 255) & (h < 330) & (sat > 0.25) & (val > 0.25)

    lab, n = ndimage.label(falta)
    elegidos = np.zeros_like(falta)
    for e in range(1, n + 1):
        trozo = lab == e
        borde = ndimage.binary_dilation(trozo, iterations=1) & op
        if borde.any() and riesgo[borde].mean() >= min_riesgo:
            elegidos |= trozo
    if not elegidos.any():
        return rgb, op, 0

    _, idx = ndimage.distance_transform_edt(~op, return_indices=True)
    out = rgb.copy()
    out[elegidos] = rgb[idx[0][elegidos], idx[1][elegidos]]
    return out, op | elegidos, int(elegidos.sum())


def quitar_motas(op, min_px=3):
    """Islas opacas diminutas y despegadas del cuerpo: restos del recorte."""
    lab, n = ndimage.label(op)
    if n <= 1:
        return op, 0
    tam = ndimage.sum(op, lab, range(1, n + 1))
    fuera = [i + 1 for i, t in enumerate(tam) if t <= min_px and t < tam.max()]
    if not fuera:
        return op, 0
    mota = np.isin(lab, fuera)
    return op & ~mota, int(mota.sum())


# Demasiado destrozado para parchear: el cuerpo del espectro son mechones
# sueltos y cerrar la silueta lo convierte en un pegote que le tapa un ojo.
# Necesita la hoja original o volver a generarse. Comprobado mirandolo.
NO_TOCAR = ("criaturas_64/cr_espectro.png",)


def reparar(p, aplicar):
    if any(p.replace("\\", "/").endswith(n) for n in NO_TOCAR):
        return None
    a = np.array(Image.open(p).convert("RGBA"))
    rgb, al = a[..., :3].copy(), a[..., 3]
    op = al > 0
    if not op.any():
        return None
    rgb, n_sal = quitar_sal(rgb, op)
    rgb, op2, n_com = tapar_comido(rgb, op)
    op2, n_mot = quitar_motas(op2)
    if not (n_sal or n_com or n_mot):
        return None
    if aplicar:
        out = np.dstack([rgb, (op2 * 255).astype(np.uint8)])
        out[~op2] = 0
        Image.fromarray(out, "RGBA").save(p)
    return n_sal, n_com, n_mot


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("raiz")
    ap.add_argument("--aplicar", action="store_true")
    ap.add_argument("--excluir", default="ui/fuente,ui_marco,ui/ventana,ui/titulo,"
                    "ui/barra,ui/boton,ui/dialogo,ui/tooltip,mesa_suelo,shell",
                    help="marcos de nueve trozos y tiles: se repiten, no se "
                         "recortan, y no tienen silueta que cerrar")
    a = ap.parse_args()
    ex = [e for e in a.excluir.split(",") if e]
    fs = [f for f in sorted(glob.glob(os.path.join(a.raiz, "**", "*.png"),
                                      recursive=True))
          if not any(e in f.replace("\\", "/") for e in ex)]
    tot = [0, 0, 0]
    for f in fs:
        r = reparar(f, a.aplicar)
        if r:
            print(f"  {os.path.relpath(f, a.raiz):40} sal={r[0]:4} "
                  f"comido={r[1]:4} motas={r[2]:3}")
            tot = [t + x for t, x in zip(tot, r)]
    print(f"\n{len(fs)} PNG revisados · sal={tot[0]} comido={tot[1]} motas={tot[2]}"
          f"{'' if a.aplicar else '  (SIMULACRO: nada escrito, usa --aplicar)'}")


if __name__ == "__main__":
    main()
