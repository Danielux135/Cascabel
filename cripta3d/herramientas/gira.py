"""LA GIRA: las vistas de siempre de «CRIPTA», para mirar antes y después.

    python cripta3d/herramientas/gira.py <carpeta> [juego] [piezas] [sala] [criaturas] [--con=ARG ...]

Sin grupo, los hace todos. Cada grupo deja sus capturas en <carpeta>/<grupo>/ y
una hoja de contactos en <carpeta>/<grupo>.png. Es la MISMA gira cada vez: así
dos hojas se comparan de un vistazo, y quien arregla algo mira lo mismo que miró
quien lo criticó.

`--con=ARG` le pasa ARG a la escena en todas las lanzadas. La gira de lo que
se ve en un navegador (sin sombras, calidad media, letra de reserva) es:

    python cripta3d/herramientas/gira.py <carpeta> --con=--como-web --con=--calidad=media

  juego      las tres cámaras de jugar (seguimiento, rasante, cenital), con el
             marcador puesto en la primera y el guion de la caza (`--demo`)
  piezas     cada pieza de cerca, y cada suceso FORZADO en el segundo en que se
             le hace la foto: un brasero golpeado, las lápidas cayendo, la bola
             en el sarcófago, una boca tapada, el espectro escondido, la campana
             armada y la campana tocando
  sala       la cripta alrededor de la mesa: de frente, el ábside, los dos
             costados, desde el asiento, desde arriba y el rayo de luna
  criaturas  la cámara pegada a cada criatura, con su guion de golpes
  fijas      (solo si se pide) catorce tomas sin sucesos y en los primeros
             segundos, para comparar píxel a píxel un cambio que no debería
             verse. Ver `FIJAS` y `comparar.py`

Va por `godot3d.py`, o sea sin ventana y de una en una. Las tomas están en
unidades 3D (x = px/100, z = py/100, y hacia arriba) y salen de los datos de la
mesa: si una pieza se mueve en `mesa_cripta.gd`, se mueve aquí su toma.
"""

import subprocess
import sys
from pathlib import Path

AQUI = Path(__file__).resolve().parent
ESCENA = "res://cripta3d/cripta_3d.tscn"

# Cada cuánto se hace una foto, en segundos de juego. La primera, a los 2,0.
CADA = 1.6

# (nombre, ojo, mira, fov, [sucesos forzados (antelación en s, quién, qué)])
PIEZAS = [
    ("palas", (2.0, 0.9, 13.6), (2.0, 0.1, 11.9), 45, []),
    ("honda_y_poste", (0.3, 0.7, 12.5), (1.05, 0.1, 11.4), 45, [(0.12, 0, "poste")]),
    ("braseros_golpe", (1.6, 1.0, 9.1), (1.6, 0.1, 7.45), 42, [(0.10, 2, "brasero")]),
    ("lapidas", (1.6, 0.7, 9.7), (1.6, 0.15, 8.32), 42, []),
    ("lapidas_cayendo", (1.6, 0.7, 9.7), (1.6, 0.15, 8.32), 42, [(0.22, 0, "banco")]),
    ("escudos", (2.5, 0.7, 9.6), (3.45, 0.15, 8.75), 42, []),
    ("sarcofago_con_bola", (4.2, 1.5, 7.9), (3.22, 0.34, 6.56), 40, [(0.30, 0, "platillo")]),
    ("coro", (3.9, 1.5, 8.8), (2.7, 0.4, 7.2), 48, []),
    ("torno_galeria", (1.2, 0.8, 10.3), (0.5, 0.15, 9.4), 42, [(0.20, 0, "torno")]),
    ("torno_coro", (2.9, 0.8, 10.0), (2.38, 0.15, 9.06), 42, [(0.20, 1, "torno")]),
    ("boca_tapada", (3.6, 1.0, 10.7), (3.1, 0.0, 9.62), 42, [(0.50, 0, "tapar")]),
    ("espectro_escondido", (0.6, 1.0, 11.4), (1.26, 0.0, 10.35), 42, [(0.90, 1, "esconder")]),
    ("lanzador", (3.1, 0.8, 13.3), (3.69, 0.1, 12.6), 42, []),
    ("campana_armada", (1.6, 0.9, 10.4), (1.6, 1.5, 7.42), 45, [(1.00, 0, "armar")]),
    ("campana_tocando", (1.6, 0.9, 10.4), (1.6, 1.5, 7.42), 45, [(0.60, 0, "tocar")]),
    ("campana_desde_el_juego", (2.0, 3.6, 14.6), (2.0, 0.0, 10.6), 50, [(0.10, 0, "bola")]),
]

SALA = [
    # Por DEBAJO de la bóveda (`Y_BOVEDA` = 7,0, y la clave del arco a 5,4): la
    # bóveda es de una cara y desde encima no se dibuja, así que una cámara a
    # y = 7,5 veía la sala sin techo y los fajones como bandas negras.
    ("de_frente", (2.0, 4.2, 19.5), (2.0, 0.5, 8.0), 50, []),
    ("abside", (2.0, 1.6, 9.6), (2.0, 1.2, 5.9), 55, []),
    # Entre la mesa y la fila de pilares (que están en x≈−3 y x≈7): más afuera
    # la cámara cae DENTRO de un pilar y la toma sale tapada.
    ("costado_izquierdo", (-1.7, 1.9, 13.4), (2.0, 0.4, 9.0), 50, []),
    ("costado_derecho", (5.7, 1.9, 13.4), (2.0, 0.4, 9.0), 50, []),
    ("desde_el_asiento", (2.0, 1.2, 15.5), (2.0, 0.6, 9.0), 50, []),
    ("desde_arriba", (2.0, 16.0, 9.31), (2.0, 0.0, 9.3), 50, []),
    ("rayo_de_luna", (3.4, 0.6, 10.5), (1.2, 1.4, 6.0), 55, []),
    ("rincon_izquierdo", (-0.8, 1.0, 10.8), (-1.6, 0.3, 8.8), 50, []),
    ("rincon_derecho", (4.8, 1.0, 10.8), (5.6, 0.3, 8.8), 50, []),
    ("fondo_y_boveda", (2.0, 0.5, 13.5), (2.0, 3.2, 5.0), 60, []),
]


# LAS TOMAS FIJAS: para comparar un cambio que NO debería verse (reescribir un
# sombreador para que compile antes, por ejemplo). Catorce tomas de piedra,
# hierro, bronce, madera y suelo, sin sucesos y todas en los primeros segundos:
# después la simulación se separa de una lanzada a otra (el piloto y las
# criaturas tiran de azar) y ya no se puede comparar píxel a píxel. Se sacan DOS
# veces con el mismo código para saber cuánto ruido hay, y luego con el cambio:
#     python cripta3d/herramientas/gira.py C:/ruta/antes fijas
#     python cripta3d/herramientas/comparar.py tomas C:/ruta/antes/fijas C:/ruta/despues/fijas
# Medido: con las ocho primeras el ruido es de 0,00 a 0,22 de media sobre 255.
CADA_FIJAS = 0.25
FIJAS = [
    ("palas", (2.0, 0.9, 13.6), (2.0, 0.1, 11.9), 45, []),
    ("honda_y_poste", (0.3, 0.7, 12.5), (1.05, 0.1, 11.4), 45, []),
    ("braseros", (1.6, 1.0, 9.1), (1.6, 0.1, 7.45), 42, []),
    ("lapidas", (1.6, 0.7, 9.7), (1.6, 0.15, 8.32), 42, []),
    ("escudos", (2.5, 0.7, 9.6), (3.45, 0.15, 8.75), 42, []),
    ("sarcofago", (4.2, 1.5, 7.9), (3.22, 0.34, 6.56), 40, []),
    ("coro", (3.9, 1.5, 8.8), (2.7, 0.4, 7.2), 48, []),
    ("lanzador", (3.1, 0.8, 13.3), (3.69, 0.1, 12.6), 42, []),
    ("campana", (1.6, 0.9, 10.4), (1.6, 1.5, 7.42), 45, []),
    ("de_frente", (2.0, 4.2, 19.5), (2.0, 0.5, 8.0), 50, []),
    ("abside", (2.0, 1.6, 9.6), (2.0, 1.2, 5.9), 55, []),
    ("costado_izquierdo", (-1.7, 1.9, 13.4), (2.0, 0.4, 9.0), 50, []),
    ("rincon_izquierdo", (-0.8, 1.0, 10.8), (-1.6, 0.3, 8.8), 50, []),
    ("fondo_y_boveda", (2.0, 0.5, 13.5), (2.0, 3.2, 5.0), 60, []),
]


# Lo que se le añade a TODAS las lanzadas (`--con=...` en la orden): la gira
# «como en la web» es `--con=--como-web --con=--calidad=media`.
SIEMPRE = []

# Con el telón de la carga por delante el reloj del juego no corre: cada
# lanzada necesita esos fotogramas de más (uno por material, y hay unos 60).
FOTOGRAMAS_DEL_TELON = 150


def lanzar(fotogramas, argumentos, lineas=12):
    if "--como-web" in SIEMPRE:
        fotogramas += FOTOGRAMAS_DEL_TELON
    orden = [sys.executable, str(AQUI / "godot3d.py"), "escena", ESCENA,
             "--fotogramas", str(fotogramas), "--tiempo", "600",
             "--lineas", str(lineas), "--"] + argumentos + SIEMPRE
    fuera = subprocess.run(orden, capture_output=True, text=True,
                           encoding="utf-8", errors="replace")
    cola = [r for r in (fuera.stdout + fuera.stderr).splitlines()
            if r.strip() and not r.startswith("captura:")]
    for r in cola[-lineas:]:
        print("   ", r)
    return fuera.returncode


def hoja(salida, carpeta, cols):
    subprocess.run([sys.executable, str(AQUI / "hoja.py"), str(salida), str(carpeta),
                    "--cols", str(cols), "--alto", "400"], check=False)


def numero(v):
    return ("%.3f" % v).rstrip("0").rstrip(".")


def tomas(destino, lista, extra, cada=CADA):
    """Una lanzada con una toma por foto y los sucesos a su hora."""
    destino.mkdir(parents=True, exist_ok=True)
    for viejo in destino.glob("*.png"):
        viejo.unlink()
    args = ["--capturas=" + destino.as_posix(), "--cada=" + numero(cada),
            "--sin-marcador"] + extra
    guion = []
    for k, (_nombre, ojo, mira, fov, sucesos) in enumerate(lista):
        args.append("--toma=%s/%s/%d" % (",".join(numero(c) for c in ojo),
                                         ",".join(numero(c) for c in mira), fov))
        cuando = 2.0 + k * cada
        for antes, quien, que in sucesos:
            guion.append("%s:%d:%s" % (numero(max(cuando - antes, 0.1)), quien, que))
    if guion:
        args.append("--guion=" + ",".join(guion))
    codigo = lanzar(int((2.0 + len(lista) * cada + 0.6) * 60), args)
    # Los ficheros salen tNN_00.png: se les pone delante el nombre de la toma.
    for k, (nombre, *_resto) in enumerate(lista):
        f = destino / ("t%02d_00.png" % k)
        if f.exists():
            f.rename(destino / ("%02d_%s.png" % (k, nombre)))
    return codigo


def juego(base):
    destino = base / "juego"
    destino.mkdir(parents=True, exist_ok=True)
    for viejo in destino.glob("*.png"):
        viejo.unlink()
    for vista, extra in ((0, []), (1, ["--sin-marcador"]), (2, ["--sin-marcador"])):
        lanzar(int((2.0 + 6 * 2.4 + 0.6) * 60),
               ["--capturas=" + destino.as_posix(), "--vista=%d" % vista,
                "--cada=2.4", "--cuantas=6", "--demo"] + extra)
    hoja(base / "juego.png", destino, 3)


def criaturas(base):
    destino = base / "criaturas"
    destino.mkdir(parents=True, exist_ok=True)
    for viejo in destino.glob("*.png"):
        viejo.unlink()
    # Índices de `caza.principales()`: el orden en que las da la caza.
    for cual in range(3):
        parcial = destino / ("c%d" % cual)
        parcial.mkdir(exist_ok=True)
        lanzar(int((2.0 + 8 * 1.8 + 0.6) * 60),
               ["--capturas=" + parcial.as_posix(), "--vista=5",
                "--criatura=%d" % cual, "--cada=1.8", "--cuantas=8", "--demo",
                "--sin-marcador"])
        for f in sorted(parcial.glob("*.png")):
            f.rename(destino / ("c%d_%s" % (cual, f.name)))
        parcial.rmdir()
    hoja(base / "criaturas.png", destino, 4)


def main():
    if len(sys.argv) < 2 or sys.argv[1].startswith("-"):
        # `gira.py --help` creaba una carpeta «--help» DENTRO del repo y lanzaba
        # la gira entera en ella: le pasó a un agente.
        print(__doc__)
        return 2
    base = Path(sys.argv[1]).resolve()
    # Las capturas NUNCA dentro del repo: Godot lo escanea entero e importa cada
    # PNG. Una ruta relativa («antes», «despues») cae dentro sin querer.
    repo = AQUI.parent.parent
    if base == repo or repo in base.parents:
        print("[gira] la carpeta de capturas no puede estar dentro del repo (%s):\n"
              "       da una ruta absoluta fuera, la de tu carpeta temporal." % repo)
        return 2
    base.mkdir(parents=True, exist_ok=True)
    resto = sys.argv[2:]
    SIEMPRE.extend(a[len("--con="):] for a in resto if a.startswith("--con="))
    grupos = [a for a in resto if not a.startswith("--con=")] \
        or ["juego", "piezas", "sala", "criaturas"]
    for g in grupos:
        print("[gira] " + g)
        if g == "juego":
            juego(base)
        elif g == "piezas":
            tomas(base / "piezas", PIEZAS, [])
            hoja(base / "piezas.png", base / "piezas", 4)
        elif g == "sala":
            tomas(base / "sala", SALA, [])
            hoja(base / "sala.png", base / "sala", 4)
        elif g == "fijas":
            # No entra en la gira de siempre: se pide por su nombre.
            tomas(base / "fijas", FIJAS, [], CADA_FIJAS)
            hoja(base / "fijas.png", base / "fijas", 4)
        elif g == "criaturas":
            criaturas(base)
        else:
            print("[gira] no conozco el grupo «%s»" % g)
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main())
