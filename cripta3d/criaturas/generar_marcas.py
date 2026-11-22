"""CRIPTA 3D — hornea las marcas del hueso de la calavera en una textura.

    python cripta3d/criaturas/generar_marcas.py
    python cripta3d/herramientas/godot3d.py importar --lineas 5

Deja `cripta3d/criaturas/calavera_marcas.png` (1024×1024, RGBA, sin pérdida) y
su ficha de importación. Tarda minuto y medio (numpy: las suturas son el ruido
de valor de antes, en coma flotante de 32 bits, sobre un millón de texeles).

POR QUÉ EXISTE. `calavera_hueso.gdshader` calculaba las suturas y las grietas
por código en cada píxel: la distancia a la sutura eran tres meandros de cinco
ruidos de valor (ocho hash cada uno), y la llamaba SEIS veces por píxel para
sacar la ranura y su pendiente; las grietas eran unas celdas con un triple
bucle de 27 vueltas. Con ANGLE, Direct3D lo despliega todo en cada variante
del sombreador: compilar el hueso costaba 31,7 s de los 35,7 de la familia
(banco, 21-nov-2026). Lo que no se mueve se calcula UNA vez, aquí, y lo que
viaja es una imagen.

LOS CUATRO CANALES:

  R  la sutura SAGITAL          } distancia (sin signo, en unidades) a la línea,
  G  la CORONAL y la LAMBDOIDEA } / `RANGO`. Proyección DESDE ARRIBA del cráneo,
                                  x y z locales: es la misma que ya usaba el
                                  sombreador (`distancia_sutura` solo miraba x y
                                  z; la altura y solo la borraba por abajo, y eso
                                  se sigue sumando allí). Con los tramos borrados
                                  y los finales ya dentro. La coronal y la
                                  lambdoidea comparten canal porque no se tocan:
                                  con su cerco, una no baja de z = −0,020 y la
                                  otra no sube de z = −0,033 (se comprueba
                                  abajo), y el sombreador elige el borrado de
                                  abajo de cada una por la z (corta en −0,026).
  B  las GRIETAS, tesela de `TESELA_GRIETA` unidades: la DISTANCIA a la grieta
     (F2 − F1, la de antes) entre `RANGO_GRIETA`. El sombreador saca de ella la
     raya (de un píxel como mínimo, ver `grietas()`) y el cerco de mugre de
     alrededor, 1 − smoothstep(0,02, 0,10, F2 − F1) en celdas de 1/8,5.
     Las celdas: 5×5 por tesela, de 1/10,6 (22-nov-2026). Las de antes eran de
     1/8,5, pero en 3D: la bóveda, que es una cúpula, atraviesa celdas a distintas
     alturas y en cada trozo corta otra, así que la red que se veía en la gira 5
     tenía casi el doble de polígonos que un Voronoi 2D de las mismas celdas
     (contado sobre una bóveda de mentira, `arreglos3_calavera/pruebas/esfera.py`:
     12–13 contra 6–7). Con 4 por tesela la crítica de la gira 7 vio «menos líneas,
     concentradas en un nudo en Y»; con 6, tramos gordos y negros donde el
     temblor aprieta el dominio. Con 5, 9–10 polígonos, y la raya no engorda.
     La distancia se sigue guardando EN CELDAS DE ANTES (1/8,5), para que la raya
     y el cerco del sombreador midan lo mismo en el hueso.
  A  el PORO oscuro: motas sueltas, en la misma tesela que las grietas. Antes,
     smoothstep(0,78, 0,95) de un ruido de valor 3D a 330 por unidad; aquí, EL
     MISMO ruido (330 por unidad, los mismos umbrales) cortado por una superficie
     ondulada (ver `poro()`): así las motas salen rayitas con esquinas, como
     antes, y no puntitos redondos.

POR QUÉ NO SALEN DE `ruido_celdas.png`: su canal A guarda la raíz de la
distancia a la grieta SIN signo, a 11 celdas por tesela. Entre dos texeles la
interpolación no baja de 0,134 cuando la grieta pasa por en medio: una raya tan
fina como la del hueso (0,0006 unidades) sale a trazos o, para que no se corte,
tres veces más gruesa. Aquí la distancia va SIN raíz y con su rango justo: entre
dos texeles no baja de unos 0,006 de celda, menos que la raya (0,0075).

Lo que se ve distinto a la fuerza: el dibujo del poro y de las grietas es otro
(otro azar, en 2D por tres planos y no en 3D), con el mismo tamaño y la misma
cobertura. Las suturas son las MISMAS (las mismas fórmulas, en
coma flotante de 32 bits como en la tarjeta).
"""

from pathlib import Path

import numpy as np
from PIL import Image

AQUI = Path(__file__).resolve().parent
SALIDA = AQUI / "calavera_marcas.png"
TAM = 1024

# --- Suturas: el recuadro del cráneo que cubre la textura (x, z locales) -------
# Las tres caben con su cerco (0,006) dentro: la sagital va de z = −0,116 a
# 0,050, la coronal sube hasta z ≈ 0,051 en el centro y la lambdoidea baja hasta
# z ≈ −0,115. Lo que queda fuera es «lejos» (el borde se repite al leer).
X0, X1 = -0.125, 0.125
Z0, Z1 = -0.1855, 0.0645
# Hasta dónde llega lo que importa: el cerco amarillo acaba a 0,006.
RANGO = 0.0065

# --- Grietas y poro: tesela periódica ------------------------------------------
# La tesela mide lo que cuatro celdas de antes (8,5 por unidad), y lleva cinco
# (ver «B» arriba).
TESELA_GRIETA = 4.0 / 8.5         # 0,4706 unidades: no cambiar sin el sombreador
CELDAS = 5
CELDAS_ANTES = 4
# B guarda la distancia a la grieta hasta aquí (en F2 − F1 de celda): donde
# acaba el cerco de mugre, 0,10 como antes.
RANGO_GRIETA = 0.10               # no cambiar sin el sombreador


# ------------------------------------------------- el ruido de antes, en float32

F = np.float32


def azar(p):
    """`azar(vec3)` del sombreador, en coma flotante de 32 bits."""
    p = p.astype(np.float32)
    p = p * F(0.3183099) + F(0.1)
    p = p - np.floor(p)
    p = p * F(17.0)
    v = p[..., 0] * p[..., 1] * p[..., 2] * (p[..., 0] + p[..., 1] + p[..., 2])
    return v - np.floor(v)


def ruido(x):
    """`ruido(vec3)` del sombreador: valor con interpolación suave."""
    x = x.astype(np.float32)
    i = np.floor(x)
    f = x - i
    f = f * f * (F(3.0) - F(2.0) * f)

    def a(dx, dy, dz):
        return azar(i + np.array([dx, dy, dz], dtype=np.float32))

    def mezcla(a0, a1, t):
        return a0 + (a1 - a0) * t

    fx, fy, fz = f[..., 0], f[..., 1], f[..., 2]
    return mezcla(
        mezcla(mezcla(a(0, 0, 0), a(1, 0, 0), fx), mezcla(a(0, 1, 0), a(1, 1, 0), fx), fy),
        mezcla(mezcla(a(0, 0, 1), a(1, 0, 1), fx), mezcla(a(0, 1, 1), a(1, 1, 1), fx), fy),
        fz)


def v3(a, b, c):
    a, b, c = np.broadcast_arrays(F(a), F(b), F(c))
    return np.stack([a, b, c], axis=-1).astype(np.float32)


def suave(a, b, x):
    t = np.clip((x - F(a)) / F(b - a), 0.0, 1.0)
    return t * t * (F(3.0) - F(2.0) * t)


def meandro(t, s):
    """El serpenteo de una sutura (igual que en el sombreador de antes)."""
    ancho = F(0.35) + F(0.85) * ruido(v3(t * F(9.0), s, 1.3))
    a = (ruido(v3(t * F(48.0), s, 0.0)) - F(0.5)) * F(0.0060) * ancho
    a = a + (ruido(v3(t * F(140.0), s, 5.0)) - F(0.5)) * F(0.0034) * ancho
    a = a + (ruido(v3(t * F(330.0), s, 9.0)) - F(0.5)) * F(0.0013)
    return a


def suturas():
    """R: sagital; G: coronal y lambdoidea. Distancia en x-z, sin la altura."""
    xs = (np.arange(TAM, dtype=np.float32) + F(0.5)) / F(TAM) * F(X1 - X0) + F(X0)
    zs = (np.arange(TAM, dtype=np.float32) + F(0.5)) / F(TAM) * F(Z1 - Z0) + F(Z0)
    x, z = np.meshgrid(xs, zs)          # fila = z, columna = x
    ax = np.abs(x)
    sag = np.abs(x - meandro(z, 1.0) - F(0.0025) * np.sin(z * F(21.0)))
    sag += suave(0.034, 0.050, z) + (F(1.0) - suave(-0.116, -0.098, z))
    sag += (F(1.0) - suave(0.30, 0.45, ruido(v3(z * F(30.0), 2.0, 7.0)))) * F(0.01)
    cor = np.abs(z - (F(0.044) - ax * F(0.30) - ax * ax * F(1.1)) - meandro(x, 4.0))
    cor += suave(0.100, 0.118, ax)
    cor += (F(1.0) - suave(0.28, 0.42, ruido(v3(x * F(34.0), 5.0, 3.0)))) * F(0.01)
    lam = np.abs(z - (F(-0.106) + ax * F(0.50)) - meandro(x, 8.0) * F(1.3))
    lam += suave(0.098, 0.116, ax)
    lam += (F(1.0) - suave(0.25, 0.40, ruido(v3(x * F(28.0), 9.0, 1.0)))) * F(0.01)
    # Las dos de un canal no se pisan: comprobado aquí, no supuesto.
    solape = (cor < RANGO) & (lam < RANGO)
    assert not solape.any(), "la coronal y la lambdoidea se tocan: no caben en un canal"
    return (np.clip(sag / RANGO, 0.0, 1.0), np.clip(np.minimum(cor, lam) / RANGO, 0.0, 1.0))


# ------------------------------------------------------------ grietas y poro


def grietas():
    """B: la DISTANCIA a la grieta (F2 − F1 del Voronoi periódico de
    CELDAS×CELDAS) / `RANGO_GRIETA`. La raya y el cerco los saca el sombreador."""
    n = TAM
    rng = np.random.default_rng(8509)
    # Un punto por celda, con el mismo margen de azar que `azar(celda)` (0..1).
    puntos = rng.random((CELDAS, CELDAS, 2)).astype(np.float32)
    c = (np.arange(n, dtype=np.float32) + F(0.5)) / F(n) * F(CELDAS)
    u, v = np.meshgrid(c, c)
    # El temblor de antes: el dominio se tuerce un poco (±0,07 de celda) con un
    # ruido periódico, para que la raya no sea una recta de regla.
    k = F(2.0 * np.pi / CELDAS)
    # Las ondas, de 0,36 a 0,8 de celda (con más vueltas por celda la raya se
    # rizaba en bucles y bolas negras, que las de antes no tenían). Las de cuatro
    # celdas por tesela (5, 7, 9 y 11 vueltas), en proporción a las cinco.
    tu = (np.sin(u * k * 6 + 1.3) * 0.5 + np.sin(v * k * 9 + 4.1) * 0.3
          + np.sin((u + v) * k * 14 + 2.2) * 0.2).astype(np.float32)
    tv = (np.sin(v * k * 6 + 5.7) * 0.5 + np.sin(u * k * 11 + 0.6) * 0.3
          + np.sin((u - v) * k * 14 + 3.9) * 0.2).astype(np.float32)
    u = u + tu * F(0.07)
    v = v + tv * F(0.07)
    iu = np.floor(u).astype(np.int64)
    iv = np.floor(v).astype(np.int64)
    fu = u - iu
    fv = v - iv
    d1 = np.full(u.shape, 8.0, dtype=np.float32)
    d2 = np.full(u.shape, 8.0, dtype=np.float32)
    for a in (-1, 0, 1):
        for b in (-1, 0, 1):
            o = puntos[(iv + b) % CELDAS, (iu + a) % CELDAS]
            ru = F(a) + o[..., 0] - fu
            rv = F(b) + o[..., 1] - fv
            d = ru * ru + rv * rv
            d2 = np.where(d < d1, d1, np.minimum(d2, d))
            d1 = np.minimum(d1, d)
    # En celdas DE ANTES (1/8,5): la raya y el cerco miden lo mismo en el hueso.
    celda = (np.sqrt(d2) - np.sqrt(d1)) * F(CELDAS_ANTES / CELDAS)
    # LA DISTANCIA, NO LA RAYA (21-nov-2026, tras la crítica de la gira 6). Aquí
    # se guardaba ya la raya pintada, a la mitad de ancho y promediada; filtrada
    # (mipmap, triplanar) se quedaba en una fila de puntos claros y oscuros
    # alternos, y de lejos desaparecía: «menos grietas, más cortas y a trozos».
    # Una distancia se interpola bien, y el sombreador saca de ella una raya de un
    # píxel como mínimo, suave (con `fwidth`), a cualquier distancia. Ocho bits
    # sobran: 0,10 / 255 = 0,0004 de celda, y un texel son ~0,006.
    return np.clip(celda / F(RANGO_GRIETA), 0.0, 1.0)


def ruido3_periodico(q, red):
    """Ruido de valor 3D (el `ruido` de antes) sobre una red periódica `red`."""
    P = red.shape[0]
    i = np.floor(q).astype(np.int64)
    f = (q - i).astype(np.float32)
    f = f * f * (F(3.0) - F(2.0) * f)

    def a(dx, dy, dz):
        return red[(i[..., 0] + dx) % P, (i[..., 1] + dy) % P, (i[..., 2] + dz) % P]

    def mezcla(a0, a1, t):
        return a0 + (a1 - a0) * t

    fx, fy, fz = f[..., 0], f[..., 1], f[..., 2]
    return mezcla(
        mezcla(mezcla(a(0, 0, 0), a(1, 0, 0), fx), mezcla(a(0, 1, 0), a(1, 1, 0), fx), fy),
        mezcla(mezcla(a(0, 0, 1), a(1, 0, 1), fx), mezcla(a(0, 1, 1), a(1, 1, 1), fx), fy),
        fz)


def poro():
    """A: motas oscuras sueltas: `smoothstep(0,78, 0,95, ruido(p·330))` de antes.

    UN CORTE DE UN RUIDO 3D, NO UN RUIDO 2D (21-nov-2026). El de antes era 3D y
    la superficie lo cortaba sesgada, cada trozo con su inclinación: las motas
    salían pequeñas, de canto duro, con esquinas, unas alargadas y otras no. Un
    ruido 2D alineado con la textura las daba redondas y blandas («el poro sale
    más blando y redondo», la crítica de la gira 6), y un corte por UN plano
    oblicuo, todas alargadas hacia el mismo lado, como lluvia. Aquí se corta una
    red 3D periódica de lado P por una superficie ONDULADA, z = suma de senos de
    u y v con un número entero de ondas por tesela (así la tesela P × P se
    repite sin costura): la inclinación va de 0 a unos 40° y cambia de un sitio a
    otro, como en el hueso de antes.
    EL TAMAÑO DE ANTES: 155 casillas por tesela, 330 por unidad del hueso, y los
    umbrales de antes (0,78–0,95). Hubo 470 por unidad (0,77–0,94) para que
    salieran tantas motas como en la gira 5, y la crítica de la gira 7 lo vio:
    «el poro de la gira 5 son rayitas angulosas de largo variable y el de ahora
    son puntitos más pequeños y redondos». A 470 la casilla mide 4,6 texeles y
    los brazos de la estrella del ruido de valor (las rayitas) no caben: queda el
    centro, redondo. A 330 caben, y sobre una bóveda de mentira pintada como la
    gira 5 (`arreglos3_calavera/pruebas/esfera.py`) salen las mismas rayitas, eles
    y cruces. Probado y descartado: la superficie tres veces más inclinada (todas
    las motas salen estiradas hacia el mismo lado, como pelos).
    """
    P = 155
    rng = np.random.default_rng(3301)
    red = rng.random((P, P, P)).astype(np.float32)
    c = (np.arange(TAM, dtype=np.float32) + F(0.5)) / F(TAM) * F(P)
    u, v = np.meshgrid(c, c)
    k = F(2.0 * np.pi / P)
    z = (F(9.0) * np.sin(u * k * 2 + 1.1) + F(9.0) * np.sin(v * k * 3 + 0.4)
         + F(6.0) * np.sin((u + v) * k * 2 + 2.6) + F(5.0) * np.sin((u - v) * k * 3 + 4.4))
    q = np.stack([u, v, z.astype(np.float32) + F(P / 2)], axis=-1)
    return suave(0.78, 0.95, ruido3_periodico(q, red))


def ficha():
    """La ficha de importación: sin pérdida, con mipmaps y sin tocar el alfa
    (aquí el alfa es un dato, no una transparencia). Lo mismo que las texturas
    de ruido de la casa (`materiales/generar_texturas.gd`)."""
    ruta = Path(str(SALIDA) + ".import")
    if ruta.exists():
        return
    ruta.write_text("[remap]\n\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n\n[params]\n\n"
                    "compress/mode=0\nmipmaps/generate=true\nprocess/fix_alpha_border=false\n"
                    "process/premult_alpha=false\ndetect_3d/compress_to=0\n", encoding="utf-8")


def main():
    r, g = suturas()
    b = grietas()
    a = poro()
    canales = [np.clip(np.rint(c * 255.0), 0, 255).astype(np.uint8) for c in (r, g, b, a)]
    # NUNCA un alfa de 0: un compresor sin pérdida puede tirar el color de un
    # píxel del todo transparente, y aquí ese «color» son tres datos.
    canales[3] = np.maximum(canales[3], 1)
    Image.fromarray(np.stack(canales, axis=-1), "RGBA").save(SALIDA, optimize=True)
    ficha()
    print("calavera_marcas: %s (%d KB)" % (SALIDA, SALIDA.stat().st_size // 1024))


if __name__ == "__main__":
    main()
