#!/usr/bin/env python3
"""
Pasa la BATERÍA DE REVISIÓN a una tira de fotogramas ya cortada.

Existe porque la segunda hoja de `cr_calavera` se dio por buena contando
píxeles y era mala. Contar cuánto cambia no vale: hay que mirar QUÉ cambia y
si lo que hay dibujado se lee al tamaño real. Esto automatiza lo que Fátima
cazó a ojo —«píxeles fuera de zona, dedos bug, mucho cambio en la luz»— para
que no dependa de que alguien tenga el día fino.

    python3 revisar.py assets/criaturas_anim/cr_calavera/

Siete pruebas. Ninguna sustituye a mirar la hoja a 10×, pero las siete juntas
cazan todo lo que ha fallado hasta ahora.
"""

import glob
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage


def lum(a):
    return 0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]


def revisar(carpeta):
    rutas = sorted(glob.glob(os.path.join(carpeta, "*.png")),
                   key=lambda r: int("".join(c for c in os.path.basename(r)
                                             if c.isdigit()) or 0))
    rutas = [r for r in rutas if not os.path.basename(r).startswith("_")]
    if not rutas:
        raise SystemExit(f"no hay fotogramas en {carpeta}")
    fs = [np.array(Image.open(r).convert("RGBA")) for r in rutas]
    a = np.stack(fs).astype(int)
    n, h, w, _ = a.shape
    tinta = a[..., 3] > 0
    print(f"\n  {carpeta}  ·  {n} fotogramas de {w}×{h}\n")
    fallos = []

    # 1 ── TONOS ────────────────────────────────────────────────────────────
    # `GUIA_ESTILO.md` bloque A: "Maximum three tones per surface". Cada tono
    # de más es una frontera más que puede temblar entre fotogramas, y es la
    # causa medida del parpadeo de la luz en la hoja mala.
    cols = set()
    for f in fs:
        m = f[..., 3] > 0
        for c in np.unique(f[m][:, :3].reshape(-1, 3), axis=0):
            cols.add(tuple(int(x) for x in c))
    cuerpo = [c for c in cols if max(c) > 110 and max(c) - min(c) < 70]
    ok = len(cuerpo) <= 4
    print(f"  1. TONOS            {len(cols)} colores, {len(cuerpo)} de cuerpo"
          f"        {'OK' if ok else '*** más de 4 tonos de cuerpo ***'}")
    if not ok:
        fallos.append("demasiados tonos: la luz va a temblar")

    # 2 ── LA LUZ ───────────────────────────────────────────────────────────
    # El reflejo especular es lo más brillante del sprite, así que es lo que
    # se lleva el ojo. Tiene que ser una FORMA FIJA.
    claro = np.zeros_like(tinta)
    umbral = np.percentile(lum(a)[tinta], 96)
    for i in range(n):
        claro[i] = (lum(a[i]) >= umbral) & tinta[i]
    u, it = claro.any(axis=0), claro.all(axis=0)
    parp = 100 * (u.sum() - it.sum()) / max(u.sum(), 1)
    print(f"  2. LA LUZ           {u.sum()} px se encienden, {it.sum()} en todos"
          f"   {'OK' if parp < 40 else '***'} {parp:.0f} % parpadea")
    if parp >= 40:
        fallos.append(f"el {parp:.0f} % del reflejo parpadea")

    # 3 ── SILUETA ──────────────────────────────────────────────────────────
    # Manchas de tinta que aparecen y desaparecen por el borde. Es lo que se
    # ve como "píxeles fuera de zona".
    uu, ii = tinta.any(axis=0), tinta.all(axis=0)
    inest = uu & ~ii
    lbl, nm = ndimage.label(inest, structure=np.ones((3, 3)))
    print(f"  3. SILUETA          {inest.sum()} px parpadean en {nm} manchas"
          f"      {'OK' if nm <= 8 else '***'} ")
    if nm > 8:
        fallos.append(f"{nm} manchas sueltas parpadeando por el borde")

    # 4 ── TAMAÑO Y POSICIÓN ────────────────────────────────────────────────
    # Un bicho quieto no puede cambiar de tamaño ni flotar.
    cajas = []
    for i in range(n):
        ys, xs = np.where(tinta[i])
        cajas.append((xs.min(), xs.max(), ys.min(), ys.max()))
    anc = [c[1] - c[0] + 1 for c in cajas]
    alt = [c[3] - c[2] + 1 for c in cajas]
    sue = [c[3] for c in cajas]
    okt = max(anc) - min(anc) <= 2 and max(alt) - min(alt) <= 2
    print(f"  4. TAMAÑO           ancho {min(anc)}-{max(anc)} · alto "
          f"{min(alt)}-{max(alt)} · suelo {min(sue)}-{max(sue)}"
          f"   {'OK' if okt and max(sue)==min(sue) else '***'}")
    if not okt:
        fallos.append(f"el bicho cambia de tamaño ({max(anc)-min(anc)} px de "
                      f"ancho, {max(alt)-min(alt)} de alto)")
    if max(sue) != min(sue):
        fallos.append("la línea de suelo baila: el bicho flota")

    # 5 ── DÓNDE SE MUEVE ───────────────────────────────────────────────────
    # Se compara contra lo que pedía el prompt. Un bicho al que solo se le
    # mueve una parte no puede tener el movimiento repartido por igual.
    var = np.abs(a[:, ..., :3] - a[:1, ..., :3]).sum(axis=3).max(axis=0)
    ys, _ = np.where(uu)
    y0, y1 = ys.min(), ys.max()
    print("  5. DÓNDE SE MUEVE   ", end="")
    for nom, fa, fb in [("arriba", 0.0, 0.34), ("medio", 0.34, 0.66),
                        ("abajo", 0.66, 1.0)]:
        ya = y0 + int((y1 - y0) * fa)
        yb = y0 + int((y1 - y0) * fb) + 1
        m = uu[ya:yb]
        mv = (m & (var[ya:yb] > 90)).sum()
        print(f"{nom} {100*mv/max(m.sum(),1):3.0f} %  ", end="")
    print()

    # 6 ── DETALLE MÁS FINO ─────────────────────────────────────────────────
    # Suelo de legibilidad: por debajo de 3 px de ancho no hay dedo, hay
    # banda gris. Se mide el hueco más estrecho de la fila más poblada.
    peor = 99
    for i in range(n):
        for y in range(h):
            fila = tinta[i, y]
            if fila.sum() < 6:
                continue
            r, c = [], 0
            for v in fila:
                if v:
                    c += 1
                elif c:
                    r.append(c)
                    c = 0
            if c:
                r.append(c)
            if len(r) >= 3:
                peor = min(peor, min(r))
    print(f"  6. DETALLE FINO     trazo más estrecho {peor} px"
          f"                 {'OK' if peor >= 3 else '*** por debajo de 3 px ***'}")
    if peor < 3:
        fallos.append(f"hay trazos de {peor} px: a 64 se funden en una banda")

    # 7 ── CIERRE DEL BUCLE ─────────────────────────────────────────────────
    # El salto del último al primero no puede ser mayor que el resto, o se ve
    # un tirón en cada vuelta.
    d = [int((np.abs(a[i] - a[(i + 1) % n]).sum(axis=2) > 24).sum())
         for i in range(n)]
    okb = d[-1] <= max(d[:-1])
    print(f"  7. CIERRE DEL BUCLE saltos {d} · el de cierre es {d[-1]}"
          f"   {'OK' if okb else '*** tirón al reiniciar ***'}")
    if not okb:
        fallos.append("el salto del último al primero es el mayor: se ve el corte")

    print()
    if fallos:
        print("  VEREDICTO: NO PASA")
        for f in fallos:
            print(f"    · {f}")
    else:
        print("  VEREDICTO: pasa la batería.")
    print("  Y aun así, MÍRALA A 10× FOTOGRAMA A FOTOGRAMA antes de darla por"
          " buena.\n")
    return fallos


if __name__ == "__main__":
    for c in sys.argv[1:] or ["."]:
        revisar(c)
