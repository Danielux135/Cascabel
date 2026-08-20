#!/usr/bin/env python3
"""
Corta una TIRA DE ANIMACIÓN de una hoja generada por IA.

Por qué no vale `procesar.py --tira N`: ese modo parte la hoja ENTERA en N
columnas iguales y da por hecho que el generador puso cada fotograma en el
centro exacto de su columna. Medido sobre la hoja de `cr_brasa`, no lo hace:
las bases de las llamas caen a 15,6 / 9,1 / 7,2 / 6,8 / 4,1 / 0,1 / -4,0 /
-9,3 px del centro de su celda, o sea **24,9 px de recorrido = 7,5 px a
tamaño 64**. Eso es un baile visible.

Lo que hace este script:
  · VERTICAL   — ventana común para los ocho, anclada a la línea de suelo.
                 La animación no puede flotar.
  · HORIZONTAL — cada fotograma se centra en el CENTROIDE DE SU BASE (el 25 %
                 inferior de la tinta), no en su caja entera. La base de una
                 llama es lo estable; las puntas se mueven a propósito y
                 centrar por la caja se llevaría ese movimiento por delante.
  · ESCALA     — una sola para los ocho, sacada del fotograma más alto.

Reutiliza el recorte de magenta por TONO y la cuantización a paleta de
`procesar.py`, así que el resultado es coherente con el resto de assets.

    python3 anim.py hoja.png --n 8 --tam 64 --salida assets/criaturas_anim/cr_brasa/
"""

import argparse
import os
import numpy as np
from PIL import Image
from scipy import ndimage

import procesar as P


def tramos_con_tinta(objeto, minimo=20):
    """Columnas ocupadas -> lista de (x0, x1), un tramo por fotograma."""
    col = objeto.any(axis=0)
    out, ini = [], None
    for i, v in enumerate(col):
        if v and ini is None:
            ini = i
        if not v and ini is not None:
            if i - ini >= minimo:
                out.append((ini, i - 1))
            ini = None
    if ini is not None and len(col) - ini >= minimo:
        out.append((ini, len(col) - 1))
    return out


def quitar_sal(color, alfa, raro=0.02):
    """Píxeles sueltos de un color que ningún vecino comparte.

    De dónde salen, medido en la hoja de `cr_calavera` (ago-2026): el hueco
    entre el cráneo y la mano deja un halo de magenta a medio camino, y al
    cuantizar cae al ROJO más cercano — que es justamente lo que `cuantizar`
    hace a propósito, porque en una llama el borde rojo es correcto. En un
    hueso es una mancha de sangre. **La cura de una criatura es la avería de
    la otra**, así que el halo no se arregla en la paleta: se arregla después.

    Solo toca lo que cumple LAS DOS condiciones: que el color sea raro en el
    sprite y que NINGÚN vecino lo comparta. Un detalle dibujado a propósito
    —un diente, una chispa— tiene al menos un vecino de su color o pesa lo
    suficiente para no ser raro; ver la trampa de `limpiar.py`, que ya avisa
    de que un arreglo automático de arte se mira antes de aplicarlo.
    """
    fuera = color.copy()
    llaves = (color[..., 0].astype(int) << 16) | (color[..., 1].astype(int) << 8) | color[..., 2]
    vals, cuentas = np.unique(llaves[alfa], return_counts=True)
    raros = set(vals[cuentas < max(1, int(alfa.sum() * raro))].tolist())
    ys, xs = np.where(alfa)
    for y, x in zip(ys, xs):
        if int(llaves[y, x]) not in raros:
            continue
        y0, y1 = max(0, y - 1), min(alfa.shape[0], y + 2)
        x0, x1 = max(0, x - 1), min(alfa.shape[1], x + 2)
        vec_k = llaves[y0:y1, x0:x1][alfa[y0:y1, x0:x1]]
        propios = int((vec_k == llaves[y, x]).sum()) - 1
        if propios > 0 or len(vec_k) < 2:
            continue
        v, c = np.unique(vec_k, return_counts=True)
        manda = int(v[np.argmax(c)])
        fuera[y, x] = [(manda >> 16) & 255, (manda >> 8) & 255, manda & 255]
    return fuera


def cortar(hoja, n, tam, margen=2, base_frac=0.25, sin_arcano=True, cerrar=False,
           sin_sal=False, fuera_paleta=None):
    rgb = np.array(Image.open(hoja).convert("RGB"))
    objeto = ~P.mascara_fondo(rgb)

    tramos = tramos_con_tinta(objeto)
    if len(tramos) != n:
        raise SystemExit(
            f"esperaba {n} fotogramas y he encontrado {len(tramos)}: {tramos}\n"
            "si el generador ha pegado dos, hay que separarlos a mano o "
            "volver a generar la hoja")

    # --- medidas comunes ---------------------------------------------------
    tops, suelos, anchos, centros = [], [], [], []
    for x0, x1 in tramos:
        ys, xs = np.where(objeto[:, x0:x1 + 1])
        y0, y1 = ys.min(), ys.max()
        corte = y1 - int((y1 - y0) * base_frac)
        tops.append(y0)
        suelos.append(y1)
        anchos.append(x1 - x0 + 1)
        centros.append(xs[ys >= corte].mean() + x0)

    suelo = max(suelos)
    if max(suelos) - min(suelos) > 2:
        print(f"  ⚠ la línea de suelo baila {max(suelos)-min(suelos)} px "
              f"en origen: la hoja no cumple 'feet on the same row'")
    alto = suelo - min(tops) + 1
    lado = max(alto, max(anchos))          # ventana cuadrada común
    escala = (tam - margen * 2) / lado
    print(f"  suelo y={suelo} · ventana {lado}px · escala {escala:.4f} "
          f"· alto de llama {min(a for a in [s-t+1 for s,t in zip(suelos,tops)])}"
          f"-{max(s-t+1 for s,t in zip(suelos,tops))} px")

    # --- recorte -----------------------------------------------------------
    # `desflecar` quita el halo magenta pegado al borde. Lo que NO quita es el
    # halo que queda clasificado como dibujo: ver `cuantizar` aquí abajo.
    #
    # (Probado y descartado: sangrar el color del objeto sobre el fondo antes
    # de reducir, por si `Image.BOX` metía magenta en el borde al promediar RGB
    # y alfa por separado. Medido, cambia 0 px — el umbral de alfa a 128 tira
    # esos píxeles antes de que lleguen. No se deja código que no hace nada.)
    limpio = P.desflecar(rgb, objeto)
    rgba = np.dstack([limpio, (objeto * 255).astype(np.uint8)])
    lienzo_grande = Image.fromarray(rgba, "RGBA")

    fotogramas = []
    for i, cx in enumerate(centros):
        x0 = int(round(cx - lado / 2))
        caja = (x0, suelo - lado + 1, x0 + lado, suelo + 1)
        trozo = lienzo_grande.crop(caja)

        # LA VENTANA PUEDE PISAR AL VECINO, Y ESO NO SE VE EN EL MOSAICO.
        # `lado` sale del ALTO de la llama más alta, así que en una hoja donde
        # el bicho es más alto que ancha su celda, la ventana se sale por los
        # lados y se trae un trozo del fotograma de al lado. Sale como dos
        # barritas sueltas flotando a derecha e izquierda, y a tamaño de mesa
        # parecen chispas: no dan error y no cantan hasta que se mira el
        # fotograma solo. Medido en la hoja de la brasa: ventana de 351 px con
        # las celdas a 271, o sea 40 px de vecino por lado.
        #
        # Se recorta por TRAMO, no por componente conectado. Quedarse con la
        # mancha más grande borraría también las chispas que sí son arte —
        # `cr_brasa` tiene—; esto solo tira lo que pertenece a otro fotograma.
        tx0, tx1 = tramos[i]
        cols = np.arange(x0, x0 + lado)
        fuera = (cols < tx0) | (cols > tx1)
        if fuera.any():
            a_t = np.array(trozo)
            a_t[:, fuera] = 0
            trozo = Image.fromarray(a_t, "RGBA")

        util = tam - margen * 2
        chico = trozo.resize((util, util), Image.BOX)

        celda = Image.new("RGBA", (tam, tam), (0, 0, 0, 0))
        celda.paste(chico, (margen, tam - margen - util))

        a = np.array(celda)
        alfa = a[..., 3] > 128
        color = cuantizar(a[..., :3], alfa, sin_arcano, fuera_paleta)

        # CERRAR EL CONTORNO. El generador pinta parte del borde exterior con
        # el tono oscuro del cuerpo en vez de con el del contorno, y deja
        # tramos sin línea: medido sobre los fotogramas sueltos de la brasa,
        # falta entre el 29 % y el 45 % del perímetro, y lo que falta cae
        # concentrado en los laterales, que es donde se ve.
        #
        # Es un fallo MECÁNICO —una línea que se redibuja—, así que se repite
        # con un script mejor que pidiéndoselo otra vez. Y con fotogramas
        # generados de uno en uno compra algo más: los deja a todos con el
        # MISMO grosor de contorno, que si no baila de una tirada a otra.
        #
        # El color no se escribe a mano: es el más oscuro de la paleta que ya
        # tiene el sprite, así que vale igual para una llama que para una
        # calavera.
        if cerrar:
            lum = color.astype(float) @ [0.299, 0.587, 0.114]
            oscuro = color[alfa][np.argmin(lum[alfa])]
            borde = ndimage.binary_dilation(~alfa, np.ones((3, 3), bool)) & alfa
            color[borde] = oscuro

        if sin_sal:
            color = quitar_sal(color, alfa)

        salida = np.dstack([color, (alfa * 255).astype(np.uint8)])
        salida[~alfa] = 0
        fotogramas.append(Image.fromarray(salida, "RGBA"))
    return fotogramas


ARCANO = ("6B3F9E", "A97BD9")


def cuantizar(rgb, mascara, sin_arcano, fuera=None):
    """Como `procesar.cuantizar`, pero pudiendo sacar el violeta arcano de la
    paleta.

    Por qué hace falta. El fondo magenta no acaba de golpe: deja un halo de
    píxeles a 315° de tono, y `procesar.py` corta el fondo a 14° del tono del
    fondo (299,8°), así que el halo sobrevive como si fuera dibujo. Al
    cuantizar, un magenta lavado cae en el violeta arcano — y `CONTEXTO.md`
    dice que el arcano es EL color mágico y va con cuentagotas. Una criatura de
    fuego salpicada de violeta rompe esa regla sin dar ningún error.

    Ensanchar el margen de tono NO lo arregla: medido sobre esta hoja, de 14° a
    28° el arcano baja de 5.585 px a 833 y de paso se come 5.943 px de llama.
    El halo va degradando hasta el rojo, así que no hay corte limpio.

    Sacando los dos violetas de la paleta, ese halo cae al rojo más cercano,
    que es exactamente lo que debe ser el borde de una llama. Medido: 61 px de
    arcano -> 0.

    Se apaga con `--con-arcano` para `cr_espectro` y `cr_sombra`, que sí
    pueden llevarlo a propósito.
    """
    if not sin_arcano:
        return P.cuantizar(rgb, mascara)
    quitar = set(ARCANO) if sin_arcano else set()
    quitar |= set(fuera or ())
    keep = [i for i, h in enumerate(P.PALETA_HEX) if h not in quitar]
    pal, pal_lab = P.PALETA[keep], P.PALETA_LAB[keep]
    salida = rgb.copy()
    pts = rgb[mascara].astype(np.float32)
    if len(pts) == 0:
        return salida
    lab = P.srgb_a_lab(pts)
    d = ((lab[:, None, :] - pal_lab[None, :, :]) ** 2).sum(axis=2)
    salida[mascara] = pal[d.argmin(axis=1)].astype(np.uint8)
    return salida


def estabilizar(fs, umbral=100):
    """Quita el temblor de fondo dejando el movimiento de verdad.

    El problema, medido: un generador NO sabe repetir un dibujo idéntico ocho
    veces. En la hoja buena de `cr_calavera` el prompt pedía que solo se moviera
    la mandíbula y **el 20-42 % de los píxeles cambia de un fotograma a otro, con
    la silueta bailando entre 377 y 1.841 px** — el cráneo entero se redibuja.
    A 64 px eso no se lee como animación, se lee como ruido: el sprite hierve.

    Descartado antes de esto: que fuera culpa del recorte. Se probó cortando a
    paso uniforme entero en vez de por centroide y sale igual (49 % contra 51 %),
    así que el temblor viene del arte.

    Cómo se quita sin perder lo que sí se mueve:

      · Se calcula el fotograma MODA — el color más repetido de cada píxel a lo
        largo del bucle. Ese es el dibujo "de verdad", el que el generador
        intentaba repetir.
      · Cada fotograma conserva solo los píxeles que se APARTAN mucho de la moda.
        Lo demás vuelve a la moda.

    Así, un movimiento de verdad (la llama que se dobla, la mandíbula que se
    abre) se aparta mucho y sobrevive; el ruido de redibujado se aparta poco y
    desaparece. Es moda y no media a propósito: estos píxeles son entradas de una
    paleta de 33, no una señal continua, y promediar inventaría colores que no
    están.
    """
    a = np.stack([np.array(f) for f in fs]).astype(np.int16)
    n, h, w, _ = a.shape

    # moda por píxel, tratando el color como una clave entera
    clave = (a[..., 0].astype(np.int64) << 24 | a[..., 1].astype(np.int64) << 16
             | a[..., 2].astype(np.int64) << 8 | a[..., 3].astype(np.int64))
    moda = np.zeros((h, w, 4), np.int16)
    plano = clave.reshape(n, -1)
    for p in range(plano.shape[1]):
        vals, cuenta = np.unique(plano[:, p], return_counts=True)
        k = int(vals[cuenta.argmax()])
        moda.reshape(-1, 4)[p] = [(k >> 24) & 255, (k >> 16) & 255,
                                  (k >> 8) & 255, k & 255]

    fuera = []
    quietos = 0
    for i in range(n):
        d = np.abs(a[i] - moda).sum(axis=2)
        # NUNCA BORRA TINTA. Solo se devuelve a la moda un píxel que está
        # opaco en los dos sitios: se corrige el color, no la silueta. Sin
        # esta condición el estabilizador se comía las chispas sueltas de
        # `cr_brasa` —las que solo salen en uno o dos fotogramas—, que son
        # arte y no ruido. Un píxel que aparece o desaparece es movimiento
        # por definición y no se toca.
        ambos = (a[i][..., 3] > 0) & (moda[..., 3] > 0)
        vuelve = ambos & (d <= umbral)
        quietos += int(vuelve.sum())
        r = np.where(vuelve[..., None], moda, a[i]).astype(np.uint8)
        fuera.append(Image.fromarray(r, "RGBA"))
    tinta = int((a[..., 3] > 0).sum())
    print(f"  estabilizado: {100*quietos/max(tinta,1):.0f} % de la tinta vuelve "
          f"a la moda (era ruido de redibujado); no se ha borrado ni un píxel")
    return fuera


def congelar_arriba(fs, corte):
    """Deja quieto todo por encima de la fila `corte`, tomándolo de la moda.

    **Es un último recurso, no un arreglo.** Sirve cuando el movimiento que
    quieres está todo en la parte de abajo (una mandíbula, un saco vocal) y
    arriba solo hay temblor. Probado en `cr_calavera`: congelando por encima de
    y=38 el cráneo queda como una roca y el cambio por fotograma baja de 333 a
    207 px.

    Pero no salva una hoja mala, y conviene saber por qué: al congelar arriba,
    lo único que se mueve pasa a ser lo de abajo — así que si lo de abajo está
    mal dibujado, le acabas de dar todo el protagonismo. En `cr_calavera` los
    dedos eran un bloque fundido ilegible y congelar el cráneo los dejó de
    únicos protagonistas. La hoja se regeneró.
    """
    a = np.stack([np.array(f) for f in fs]).astype(np.int16)
    n, h, w, _ = a.shape
    k = (a[..., 0].astype(np.int64) << 24 | a[..., 1].astype(np.int64) << 16
         | a[..., 2].astype(np.int64) << 8 | a[..., 3].astype(np.int64))
    moda = np.zeros((h, w, 4), np.int16)
    pl = k.reshape(n, -1)
    for p in range(pl.shape[1]):
        v, c = np.unique(pl[:, p], return_counts=True)
        x = int(v[c.argmax()])
        moda.reshape(-1, 4)[p] = [(x >> 24) & 255, (x >> 16) & 255,
                                  (x >> 8) & 255, x & 255]
    fuera = []
    for i in range(n):
        r = moda.copy()
        r[corte:] = a[i][corte:]
        fuera.append(Image.fromarray(r.astype(np.uint8), "RGBA"))
    print(f"  congelado todo por encima de y={corte}")
    return fuera


def pulir(fs, tonos=3):
    """Reduce a `tonos` tonos de cuerpo, fija el contorno y cuaja la silueta.

    **Y aquí hay que afinar una regla que escribí demasiado ancha.** Después de
    la segunda hoja de `cr_calavera` quedó escrito que "post-procesar no salva
    una hoja mala", y eso solo es verdad a medias. Lo correcto:

      · Lo que NO se arregla post-procesando es lo MAL DIBUJADO: un personaje
        equivocado, diez dedos que no caben en la celda, una pose que no es.
        Ahí no hay script; se regenera.
      · Lo que SÍ se arregla es lo MECÁNICO: tonos de más, un contorno que se
        redibuja, una silueta que tiembla. Son fallos de repetición, no de
        dibujo, y una máquina los repite mejor que un generador.

    La tercera hoja de `cr_calavera` tenía el dibujo bien —dos manos de tres
    dedos, tamaño clavado, mandíbula con ciclo coherente— y fallaba solo en lo
    mecánico: 7 tonos de cuerpo, el 85 % del reflejo parpadeando y 27 manchas
    sueltas por el borde. Pasando esto queda en 3 tonos, 34 % y **cero
    manchas**, y pasa la batería entera de `revisar.py`.

    Tres pasos:

      1. **Silueta por mayoría.** Un píxel es tinta si lo es en la mitad o más
         de los fotogramas. Se acabaron las manchas que aparecen y desaparecen.
      2. **Contorno duro.** El anillo exterior va al color más oscuro de la
         paleta, que es lo que pide `GUIA_ESTILO.md` y lo que hace que la
         silueta se lea sobre cualquier fondo.
      3. **Cuerpo a `tonos` tonos**, elegidos por uso: se cogen los N colores
         claros más frecuentes de la hoja y todo lo demás se acerca al más
         parecido en luminancia. Las zonas oscuras de dentro —cuencas, boca—
         se respetan, que si no se rellenan de hueso.

    Ojo: esto NO se le pasa a un bicho cuya gracia sea el degradado o el
    parpadeo, como la llama de `cr_brasa`. Es para criaturas de superficie
    plana.
    """
    a = np.stack([np.array(f) for f in fs]).astype(np.int16)
    n, h, w, _ = a.shape

    silueta = (a[..., 3] > 0).sum(axis=0) >= (n + 1) // 2

    # los `tonos` colores claros más usados de toda la hoja
    uso = {}
    for i in range(n):
        m = a[i, ..., 3] > 0
        c, k = np.unique(a[i][m][:, :3].reshape(-1, 3), axis=0,
                         return_counts=True)
        for col, cnt in zip(c, k):
            t = tuple(int(x) for x in col)
            if max(t) > 110:
                uso[t] = uso.get(t, 0) + int(cnt)
    cuerpo = np.array([c for c, _ in sorted(uso.items(),
                                            key=lambda x: -x[1])[:tonos]],
                      float)
    if len(cuerpo) == 0:
        return fs
    oscuro = np.array(P.PALETA[np.argmin(P.PALETA.sum(axis=1))], float)
    lum_c = 0.299 * cuerpo[:, 0] + 0.587 * cuerpo[:, 1] + 0.114 * cuerpo[:, 2]

    borde = silueta & ~ndimage.binary_erosion(silueta)
    interior = silueta & ~borde

    fuera = []
    for i in range(n):
        src = a[i][..., :3].astype(float)
        l = 0.299 * src[..., 0] + 0.587 * src[..., 1] + 0.114 * src[..., 2]
        r = np.zeros((h, w, 4), np.uint8)
        idx = np.abs(l[..., None] - lum_c[None, None, :]).argmin(axis=2)
        r[..., :3][interior] = cuerpo[idx][interior]
        r[..., :3][interior & (l < 70)] = oscuro      # cuencas, boca
        r[..., :3][borde] = oscuro
        r[..., 3] = silueta * 255
        fuera.append(Image.fromarray(r, "RGBA"))
    print(f"  pulido: {tonos} tonos de cuerpo + contorno duro, silueta por "
          f"mayoría (0 manchas sueltas)")
    return fuera


def mapa_movimiento(fs, ruta, z=6):
    """Pinta QUÉ píxeles cambian a lo largo del bucle, encima del fotograma 1.

    Es la comprobación que cazó la hoja mala de `cr_calavera`: el prompt pedía
    que solo se movieran las llamas de las cuencas y en la hoja se movían los
    DIENTES. Contar cuántos píxeles cambian dice que hay movimiento; este mapa
    dice DÓNDE, que es lo que hay que juzgar contra el prompt.

    Rojo = cambia mucho · ámbar = cambia poco · el resto, el sprite apagado.
    """
    a = np.stack([np.array(f).astype(np.int16) for f in fs])
    var = np.abs(a[:, ..., :3] - a[:1, ..., :3]).sum(axis=3).max(axis=0)
    alfa = (a[..., 3] > 0).any(axis=0)
    tam = a.shape[1]

    base = np.array(fs[0]).astype(np.float32)
    out = np.zeros((tam, tam, 4), np.uint8)
    out[..., :3] = (base[..., :3] * 0.30).astype(np.uint8)
    out[..., 3] = (base[..., 3] > 0) * 255

    fuerte = alfa & (var > 90)
    flojo = alfa & (var > 25) & ~fuerte
    out[flojo] = [224, 166, 60, 255]
    out[fuerte] = [199, 74, 60, 255]
    out[..., 3] = np.where(alfa | (var > 25), 255, out[..., 3])

    Image.fromarray(out, "RGBA").resize((tam * z, tam * z),
                                        Image.NEAREST).save(ruta)
    print(f"\n  mapa de movimiento: {ruta}")
    print(f"    se mueve el {100*fuerte.sum()/max(alfa.sum(),1):.0f} % del sprite "
          f"(fuerte) + {100*flojo.sum()/max(alfa.sum(),1):.0f} % (flojo)")
    print("    MÍRALO: si se ilumina algo que el prompt decía que estaba "
          "quieto, la hoja está mal y se vuelve a generar")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("entrada")
    p.add_argument("--n", type=int, required=True, help="fotogramas de la tira")
    p.add_argument("--tam", type=int, default=64)
    p.add_argument("--salida", required=True)
    p.add_argument("--prefijo", default="idle")
    p.add_argument("--pulir", type=int, default=0, metavar="TONOS",
                   help="reduce a TONOS tonos de cuerpo, fija el contorno y "
                        "cuaja la silueta. Para bichos de superficie plana; "
                        "NO para llamas ni degradados")
    p.add_argument("--congelar-arriba", type=int, default=0, metavar="FILA",
                   help="ULTIMO RECURSO: deja quieto todo por encima de esa "
                        "fila. No salva una hoja mala, ver la funcion")
    p.add_argument("--sin-estabilizar", action="store_true",
                   help="deja el temblor de redibujado del generador")
    p.add_argument("--umbral", type=int, default=100,
                   help="cuanto se tiene que apartar un pixel de la moda para "
                        "contar como movimiento (por defecto 100)")
    p.add_argument("--con-arcano", action="store_true",
                   help="deja el violeta arcano en la paleta; solo para "
                        "criaturas que lo lleven a proposito")
    p.add_argument("--contorno", action="store_true",
                   help="pinta TODO el perimetro exterior con el tono mas "
                        "oscuro del sprite. Para hojas a las que el generador "
                        "les deja tramos de borde sin linea, y para que "
                        "fotogramas generados por separado compartan grosor")
    p.add_argument("--fuera", default="",
                   help="colores de la paleta a NO usar al cuantizar, en hex "
                        "separados por coma. El caso real: en una criatura de "
                        "hueso el halo del fondo cae al rojo y parece sangre, "
                        "asi que se lanza con --fuera 8C2E2E,C74A3C")
    p.add_argument("--sin-sal", action="store_true",
                   help="quita los pixeles sueltos de un color que ningun "
                        "vecino comparte: el halo del fondo que cae al rojo en "
                        "criaturas que no son de fuego. MIRALO antes de darlo "
                        "por bueno")
    args = p.parse_args()

    fs = cortar(args.entrada, args.n, args.tam,
                sin_arcano=not args.con_arcano, cerrar=args.contorno,
                sin_sal=args.sin_sal,
                fuera_paleta=[h.strip().upper() for h in args.fuera.split(",") if h.strip()])
    if not args.sin_estabilizar:
        fs = estabilizar(fs, args.umbral)
    if args.congelar_arriba:
        fs = congelar_arriba(fs, args.congelar_arriba)
    if args.pulir:
        fs = pulir(fs, args.pulir)
    os.makedirs(args.salida, exist_ok=True)
    for i, f in enumerate(fs, 1):
        ruta = os.path.join(args.salida, f"{args.prefijo}_{i}.png")
        f.save(ruta)
        print(f"  {ruta}")

    mapa_movimiento(fs, os.path.join(args.salida, "_movimiento.png"))

    # comprobación que el ojo no hace: ¿se mueve algo entre fotograma y
    # fotograma? Dos fotogramas casi iguales son ocho copias con un píxel
    # movido, y eso no se ve hasta que está dentro del juego.
    print("\n  diferencia entre fotogramas consecutivos:")
    for i in range(len(fs)):
        a = np.array(fs[i]).astype(int)
        b = np.array(fs[(i + 1) % len(fs)]).astype(int)
        d = int((np.abs(a - b).sum(axis=2) > 24).sum())
        aviso = "  ← CASI IGUALES" if d < 20 else ""
        print(f"    {i+1} → {(i+1) % len(fs) + 1}: {d:4d} px cambian{aviso}")


if __name__ == "__main__":
    main()
