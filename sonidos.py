#!/usr/bin/env python3
"""
Generador de los sonidos del juego, por síntesis.

Los sonidos de arcade son ondas simples, así que se generan por código en vez
de a mano: para reajustar un golpe se cambia un número de SONIDOS y se vuelve
a ejecutar esto, en lugar de rehacer el wav.

Uso:
    python3 sonidos.py                 # regenera todos
    python3 sonidos.py --uno bumper    # solo uno, para ir probando
    python3 sonidos.py --listar        # qué hay y cuánto dura cada cosa

Salida: assets/sonido/*.wav, 44100 Hz, mono, 16 bits.

Vocabulario de parámetros (todos opcionales menos `dur`):

    onda        seno | cuadrada | sierra | triangulo | ruido
    f0, f1      frecuencia de inicio y final del barrido, en Hz
    barrido     exp (por defecto) | lineal
    dur         duración en segundos
    ataque      subida inicial en segundos, para que no chasquee
    caida       ritmo de la caída exponencial; a más alto, más seco
    ruido       0..1, cuánto ruido se mezcla con el tono
    vibrato     (hz, profundidad)
    armonicos   [(multiplo, amplitud), ...] sobre la misma onda
    filtro      corte del paso bajo en Hz; 0 = sin filtrar
    crush       bits de cuantización; 0 = sin cuantizar
    submuestreo mantener cada N muestras; 1 = sin tocar
    vol         0..1
    mezcla      lista de capas, cada una con estos mismos parámetros
    notas       lista de frecuencias, para arpegios; usa dur_nota
    dur_ultima  duración de la última nota del arpegio; por defecto, dur_nota
    caida_ultima  caída de la última nota; por defecto, la de las demás
"""

import argparse
import os
import wave

import numpy as np
from scipy.signal import lfilter

FS = 44100
SALIDA = os.path.join("assets", "sonido")

# --------------------------------------------------------------- los sonidos

SONIDOS = {
    # --- Golpes de mesa. Cortos y secos: suenan muchísimas veces por bola, y
    # cualquier cola larga aquí convierte una buena bola en un zumbido. ---
    "bumper": dict(
        onda="cuadrada", f0=520, f1=150, dur=0.13, caida=26,
        ruido=0.18, filtro=4200, crush=5, vol=0.55,
    ),
    "target": dict(
        onda="cuadrada", f0=900, f1=620, dur=0.07, caida=45,
        ruido=0.10, filtro=6000, crush=6, vol=0.42,
    ),
    # El flipper no es un tono: es un solenoide. Ruido filtrado y un golpe seco.
    "flipper": dict(vol=0.38, mezcla=[
        dict(onda="ruido", dur=0.045, caida=95, filtro=2600, crush=6, vol=0.8),
        dict(onda="cuadrada", f0=150, f1=70, dur=0.05, caida=70, vol=0.5),
    ]),

    # --- Rampas. Una sube y la otra baja, para saber por el oído si la bola
    # se ha ido arriba o está volviendo. ---
    "rampa_entrada": dict(
        onda="seno", f0=260, f1=980, dur=0.22, caida=7, ataque=0.012,
        ruido=0.28, filtro=5200, vol=0.42,
    ),
    "rampa_salida": dict(
        onda="seno", f0=880, f1=300, dur=0.20, caida=9,
        ruido=0.15, filtro=4200, vol=0.45,
    ),

    # El platillo se traga la bola: descendente y con vibrato, que es lo que
    # hace que suene a "tragar" y no a "apagarse".
    "platillo": dict(
        onda="triangulo", f0=420, f1=120, dur=0.32, caida=8,
        vibrato=(18.0, 0.9), filtro=3000, crush=5, vol=0.50,
    ),

    # El cañón, el recorrido que suelta la bola dentro del racimo: golpe gordo
    # y grave, para que se distinga de la salida de rampa normal.
    "rampa_fuerte": dict(vol=0.6, mezcla=[
        dict(onda="cuadrada", f0=180, f1=60, dur=0.42, caida=7.0,
             filtro=2000, crush=4, vol=0.7),
        dict(onda="ruido", dur=0.22, caida=16.0, filtro=3200, crush=5, vol=0.45),
    ]),

    # --- Subir de multiplicador: arpegio ascendente. Es lo único alegre que
    # suena en la mesa, y a propósito: marca el momento que importa.
    #
    # Va en triángulo con un armónico, NO en cuadrada: bumper y target ya son
    # cuadradas, y en mitad del racimo el arpegio se confundía con un golpe
    # más. El timbre distinto es lo que lo hace destacar, más que el volumen.
    # Cinco notas y la última sostenida: el oído necesita que el gesto termine
    # arriba y se quede, o no registra que ha subido nada. ---
    "combo": dict(
        onda="triangulo", armonicos=[(2.0, 0.30)],
        notas=[523, 659, 784, 1047, 1319], dur_nota=0.062, dur_ultima=0.30,
        caida=13, caida_ultima=6, ataque=0.004, filtro=8000, crush=6, vol=0.52,
    ),

    # --- Perder la bola y matar al enemigo. Los dos largos, que son los dos
    # momentos en los que el juego se para a decirte algo. ---
    "drenaje": dict(
        onda="sierra", f0=300, f1=70, dur=0.55, caida=5,
        vibrato=(9.0, 1.4), filtro=2200, crush=5, vol=0.50,
    ),
    "muerte": dict(vol=0.62, mezcla=[
        dict(onda="ruido", dur=0.75, caida=5.0, filtro=1200, crush=4, vol=0.75),
        dict(onda="cuadrada", f0=220, f1=48, dur=0.75, caida=4.0,
             filtro=1800, crush=4, vol=0.60),
    ]),
}

# ------------------------------------------------------------------ síntesis


def _envolvente(n, ataque, caida):
    t = np.arange(n) / FS
    env = np.exp(-caida * t)
    na = min(max(int(ataque * FS), 1), n)
    env[:na] *= np.linspace(0.0, 1.0, na)
    return env


def _fase(f0, f1, n, barrido):
    """Barrido exponencial por defecto: el lineal suena a sirena, el
    exponencial suena a golpe."""
    t = np.arange(n) / FS
    dur = max(n / FS, 1e-6)
    if barrido == "exp" and f0 > 0 and f1 > 0:
        f = f0 * (f1 / f0) ** (t / dur)
    else:
        f = f0 + (f1 - f0) * (t / dur)
    return 2.0 * np.pi * np.cumsum(f) / FS


def _onda(tipo, fase, rng, n):
    if tipo == "ruido":
        return rng.uniform(-1.0, 1.0, n)
    ciclo = (fase / (2.0 * np.pi)) % 1.0
    if tipo == "seno":
        return np.sin(fase)
    if tipo == "cuadrada":
        return np.where(ciclo < 0.5, 1.0, -1.0)
    if tipo == "sierra":
        return 2.0 * ciclo - 1.0
    if tipo == "triangulo":
        return 4.0 * np.abs(ciclo - 0.5) - 1.0
    raise ValueError("onda desconocida: %s" % tipo)


def _filtrar(x, corte):
    if not corte:
        return x
    a = float(np.exp(-2.0 * np.pi * corte / FS))
    return lfilter([1.0 - a], [1.0, -a], x)


def _crujir(x, bits, submuestreo):
    """Cuantizar y bajar la frecuencia de muestreo es lo que le da el punto de
    máquina vieja. Sin esto suena a sintetizador limpio, que no es."""
    if submuestreo > 1:
        idx = (np.arange(len(x)) // submuestreo) * submuestreo
        x = x[np.clip(idx, 0, len(x) - 1)]
    if bits:
        niveles = 2 ** bits
        x = np.round(x * (niveles / 2)) / (niveles / 2)
    return x


def _capa(par, rng):
    n = max(int(par["dur"] * FS), 1)
    f0 = par.get("f0", 440)
    fase = _fase(f0, par.get("f1", f0), n, par.get("barrido", "exp"))
    if par.get("vibrato"):
        hz, prof = par["vibrato"]
        fase = fase + prof * np.sin(2.0 * np.pi * hz * np.arange(n) / FS)

    tipo = par.get("onda", "seno")
    x = _onda(tipo, fase, rng, n)
    for multiplo, amp in par.get("armonicos", []):
        x = x + amp * _onda(tipo, fase * multiplo, rng, n)

    r = par.get("ruido", 0.0)
    if r > 0.0:
        x = (1.0 - r) * x + r * rng.uniform(-1.0, 1.0, n)

    x = x * _envolvente(n, par.get("ataque", 0.002), par.get("caida", 20.0))
    x = _filtrar(x, par.get("filtro", 0))
    x = _crujir(x, par.get("crush", 0), par.get("submuestreo", 1))
    return x * par.get("vol", 0.6)


def sintetizar(par, semilla=0):
    rng = np.random.default_rng(semilla)

    if "notas" in par:
        fuera = ("notas", "dur_nota", "dur_ultima", "caida_ultima")
        trozos = []
        ultima = len(par["notas"]) - 1
        for i, f in enumerate(par["notas"]):
            sub = {k: v for k, v in par.items() if k not in fuera}
            sub["f0"] = f
            sub["f1"] = f
            sub["dur"] = par["dur_nota"]
            # La última nota es la que dice "has subido": se deja sonar más y
            # cae más despacio, para que el arpegio aterrice en vez de cortarse.
            if i == ultima:
                sub["dur"] = par.get("dur_ultima", par["dur_nota"])
                if "caida_ultima" in par:
                    sub["caida"] = par["caida_ultima"]
            trozos.append(_capa(sub, rng))
        return np.concatenate(trozos)

    if "mezcla" in par:
        capas = [_capa(c, rng) for c in par["mezcla"]]
        n = max(len(c) for c in capas)
        suma = np.zeros(n)
        for c in capas:
            suma[:len(c)] += c
        return suma * par.get("vol", 1.0)

    return _capa(par, rng)


def escribir(ruta, x):
    x = np.asarray(x, dtype=np.float64)
    pico = float(np.max(np.abs(x))) if len(x) else 0.0
    if pico > 1.0:                      # normalizar solo si se pasa
        x = x / pico
    # Fundido final: cortar en seco chasquea, y el chasquido se oye más que
    # el propio sonido cuando se repite cien veces.
    n = min(int(0.006 * FS), len(x))
    if n:
        x[-n:] = x[-n:] * np.linspace(1.0, 0.0, n)
    datos = (np.clip(x, -1.0, 1.0) * 32767.0).astype("<i2").tobytes()
    with wave.open(ruta, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FS)
        w.writeframes(datos)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--uno", default=None, help="regenerar solo este sonido")
    ap.add_argument("--salida", default=SALIDA)
    ap.add_argument("--listar", action="store_true")
    args = ap.parse_args()

    if args.listar:
        for nombre, par in SONIDOS.items():
            x = sintetizar(par)
            print("  %-16s %5.0f ms" % (nombre, 1000.0 * len(x) / FS))
        return

    nombres = [args.uno] if args.uno else list(SONIDOS)
    for nombre in nombres:
        if nombre not in SONIDOS:
            raise SystemExit("no existe el sonido %r" % nombre)

    os.makedirs(args.salida, exist_ok=True)
    for nombre in nombres:
        x = sintetizar(SONIDOS[nombre])
        ruta = os.path.join(args.salida, nombre + ".wav")
        escribir(ruta, x)
        print("  %-16s %5.0f ms  ->  %s" % (nombre, 1000.0 * len(x) / FS, ruta))


if __name__ == "__main__":
    main()
