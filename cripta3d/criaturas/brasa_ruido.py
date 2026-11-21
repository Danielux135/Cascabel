"""CRIPTA 3D — BRASA: hornea `brasa_ruido.png`, el ruido de los sombreadores de BRASA.

    python cripta3d/criaturas/brasa_ruido.py
    python cripta3d/herramientas/godot3d.py importar --lineas 5

POR QUÉ (web, 21-nov-2026). Los sombreadores de BRASA hacían su ruido por código:
un ruido de valor 3D, ocho `hash` y siete mezclas por llamada, once llamadas en la
llama. En el navegador, WebGL pasa por ANGLE y lo compila Direct3D, que despliega
ese código en cada variante del sombreador: la llama tardaba 2,5 s en compilar y
el carbón 7,2. Leer el ruido de una imagen es una instrucción.

QUÉ LLEVA. No es «un ruido parecido»: es EL MISMO ruido de valor (una rejilla de
números al azar, mezclados con la curva suave 3f² − 2f³), solo que ya calculado.
Así el grano, el reparto de valores y los umbrales de los sombreadores siguen
valiendo tal cual.

  - 32 celdas por lado, 8 píxeles por celda: 256 × 256. Se repite cada 32 celdas
    (la rejilla da la vuelta), sin costura.
  - Cada píxel guarda el valor en su CENTRO, (x + 0,5) / 8 celdas: con el filtro
    lineal, leer en `celda / 32` cae justo en esos centros. Entre centro y centro
    el filtro mezcla en recta, y con 8 por celda la curva suave sale casi exacta.
  - R: el ruido, plano z = k.  G: el R corrido (37, 17) celdas, que el sombreador
    usa como el plano z = k + 1. Una lectura trae los dos planos y mezclarlos con
    la curva es el ruido 3D (`brasa_ruido` en `brasa_fuego.gdshaderinc`).
  - B: otro ruido, de otra rejilla, para lo que solo necesita un plano.
  - A: 255 (sin uso; un alfa 0 lo puede tirar un compresor).

SIN MIPMAPS (ver la ficha `.import`): el ruido por código no se promediaba al
alejarse; con mipmaps, de lejos se leería una media más gris que la de antes y
los umbrales (las puntas que se van, los jirones) cortarían en otro sitio.

Sin dependencias: escribe el PNG a mano con zlib.
"""

import math
import os
import struct
import zlib

CELDAS = 32
POR_CELDA = 8
TAM = CELDAS * POR_CELDA
CORRIMIENTO = (37, 17)


def azar(x, y, z):
    """El `brasa_azar` de antes, en doble precisión, sobre la rejilla."""
    px = (x * 0.3183099 + 0.1) % 1.0 * 17.0
    py = (y * 0.3183099 + 0.17) % 1.0 * 17.0
    pz = (z * 0.3183099 + 0.23) % 1.0 * 17.0
    return (px * py * pz * (px + py + pz)) % 1.0


def rejilla(z):
    return [[azar(i, j, z) for i in range(CELDAS)] for j in range(CELDAS)]


def ruido(r, x, y):
    """Ruido de valor 2D, periódico, en coordenadas de celda."""
    i0 = math.floor(x)
    j0 = math.floor(y)
    fx = x - i0
    fy = y - j0
    fx = fx * fx * (3.0 - 2.0 * fx)
    fy = fy * fy * (3.0 - 2.0 * fy)
    i0 %= CELDAS
    j0 %= CELDAS
    i1 = (i0 + 1) % CELDAS
    j1 = (j0 + 1) % CELDAS
    a = r[j0][i0] + (r[j0][i1] - r[j0][i0]) * fx
    b = r[j1][i0] + (r[j1][i1] - r[j1][i0]) * fx
    return a + (b - a) * fy


def byte(v):
    return max(0, min(255, int(v * 255.0 + 0.5)))


def png(ruta, filas):
    crudo = b"".join(b"\x00" + bytes(f) for f in filas)
    def trozo(tipo, datos):
        return (struct.pack(">I", len(datos)) + tipo + datos
                + struct.pack(">I", zlib.crc32(tipo + datos) & 0xFFFFFFFF))
    with open(ruta, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(trozo(b"IHDR", struct.pack(">IIBBBBB", TAM, TAM, 8, 6, 0, 0, 0)))
        f.write(trozo(b"IDAT", zlib.compress(crudo, 9)))
        f.write(trozo(b"IEND", b""))


def main():
    r = rejilla(0.0)
    otra = rejilla(5.0)
    filas = []
    for y in range(TAM):
        fila = bytearray()
        cy = (y + 0.5) / POR_CELDA
        for x in range(TAM):
            cx = (x + 0.5) / POR_CELDA
            fila += bytes((
                byte(ruido(r, cx, cy)),
                byte(ruido(r, cx + CORRIMIENTO[0], cy + CORRIMIENTO[1])),
                byte(ruido(otra, cx, cy)),
                255,
            ))
        filas.append(fila)
    ruta = os.path.join(os.path.dirname(os.path.abspath(__file__)), "brasa_ruido.png")
    png(ruta, filas)
    print("brasa_ruido.png: %d x %d, %d celdas por lado" % (TAM, TAM, CELDAS))


if __name__ == "__main__":
    main()
