#!/usr/bin/env python3
"""Recorta las piezas de Suno y las convierte en bucles.

`assets/prompts_musica.md` §2 explica por qué hace falta: Suno está entrenado
con canciones, y una canción termina. Lo que da es material del que se saca un
bucle, y sacarlo tiene tres pasos — elegir la toma, encontrar el ciclo estable
de 20-40 s, y cortar EN FRONTERA DE COMPÁS. Cortar a ojo es lo que produce el
clic, porque el compás dura `60 / BPM * 4` segundos y los cortes válidos están
solo ahí.

Se usa en dos pasos, y el de en medio es humano:

    python musica.py analizar          # propone corte y puntúa las dos tomas
    python musica.py cortar            # aplica lo que dice la tabla PIEZAS

**La tabla manda sobre el análisis.** El analizador propone; lo que se corta es
lo que está escrito en `PIEZAS`, igual que `sonidos.py` lleva sus recetas y
`NodoSonido.AJUSTES` sus ajustes. Un número elegido a oído y escrito aquí no lo
pisa el siguiente análisis.

Requisitos: ffmpeg y ffprobe en el PATH, y numpy.
"""

import argparse
import math
import os
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np

RAIZ = Path(__file__).resolve().parent
MUSICA = RAIZ / "assets" / "musica"

# DÓNDE VIVEN LAS TOMAS DE SUNO, y no es el repo. Son 46 MB de material bruto
# que el juego no carga, y `CLAUDE.md` ya tiene decidido lo mismo para las
# hojas de IA: el original se guarda siempre, pero fuera. Aquí además hay razón
# técnica — Godot escanea el proyecto entero, y catorce OGG que nadie pide es
# exactamente lo que el candado de catálogo existe para cazar.
#
# Se puede apuntar a otro sitio con la variable de entorno CASCABEL_MUSICA.
FUENTES = Path(os.environ.get(
    "CASCABEL_MUSICA", Path.home() / "Desktop" / "Musica"))

# Frecuencia a la que se analiza. No es la del archivo final: es solo para
# medir, y a 22050 sobra para una envolvente de energía y un espectro.
SR = 22050

# --------------------------------------------------------------------------
# LA TABLA. Una fila por pieza.
#
#   bpm       el que se le pidió a Suno en el prompt (§4). Sirve de referencia
#             contra lo que el analizador detecta: si no cuadran, el corte en
#             frontera de compás estaría midiendo la rejilla equivocada.
#   bpm_real  el que la pieza tiene de verdad, cuando Suno no obedeció. Se
#             escribe A MANO y manda sobre la detección: si no, el largo del
#             bucle dependería del detector y cambiaría el día que alguien
#             toque el analizador. Lo que se cortó tiene que poder volver a
#             cortarse igual dentro de un año.
#   toma      "a" o "b", cuál de las dos generaciones entra.
#   inicio    segundo donde empieza el bucle. None = lo elige el analizador.
#   compases  cuántos compases dura. None = lo elige el analizador.
#   bucle     False para las piezas que terminan (`arranque`, `tilt`): esas no
#             se recortan por compás, solo se les quita la cola de silencio.
#
# LAS TOMAS ESTÁN ELEGIDAS POR MEDIDA, NO DE OÍDO, y eso es provisional: la
# columna `costura` dice cuál de las dos CIERRA mejor, que no es lo mismo que
# cuál suena mejor. `python musica.py mosaico` saca cada bucle repetido tres
# veces para poder juzgarlo con la oreja, que es quien decide.
# --------------------------------------------------------------------------
PIEZAS = {
    # 40 s, y NO se puede alargar más aunque su toma dure 141: por encima de
    # los 16 compases no hay ni un corte que cierre dentro del margen. Es la
    # que suena el 80 % de la partida, o sea la que más ganaría, y la música
    # no da para más.
    "combate":    {"bpm": 96,  "toma": "b", "inicio": 42.92, "compases": 16},
    # 48 s. Pasa de 32 pagando 0,04 de costura, dentro del margen.
    "escritorio": {"bpm": 60,  "toma": "a", "inicio": 28.00, "compases": 12},
    # LA PIEZA DIFÍCIL, y la que más ha cambiado al subir el techo: pide por
    # prompt una melodía que se corta a la mitad y silencios largos, o sea lo
    # contrario de algo que se repita, y con bucles de 20-40 s ninguna de sus
    # dos tomas pasaba de 0,341 de costura.
    #
    # **Con 68 s la toma a sube a 0,740 y adelanta a la b**, que era la que
    # había entrado a la fuerza por repetirse más. Lo que le faltaba no era
    # otra toma, era sitio: una pieza de frases largas necesita un bucle largo,
    # y a 34 s el corte caía a media frase. De paso vuelve a su BPM real, 56.
    "recuperado": {"bpm": 56,  "toma": "a", "inicio": 26.41, "compases": 16},
    # 62 s, y también gana costura al alargar: 0,686 a 35 s, 0,795 a 62.
    "jefe":       {"bpm": 108, "toma": "b", "inicio": 13.38, "compases": 28},
    # 23 s, LA MÁS CORTA Y A PROPÓSITO: es la única donde alargar rompe el
    # bucle de verdad — 0,905 aquí contra 0,647 a 68 s. No hay ningún candidato
    # largo dentro del margen, así que el barrido se queda corto él solo.
    "mapa":       {"bpm": 84,  "toma": "a", "inicio": 23.44, "compases": 8},
    # NINGUNA DE LAS DOS TOMAS SALIÓ A 120: Suno dio 83,4 y 80,7. Se corta con
    # el real, que es lo único que pone la rejilla donde están los golpes.
    #
    # Y se queda en 34 s porque su toma solo dura 62: un bucle de 46 s tendría
    # que empezar antes del segundo 11 y el primer compás entero pasado el 15 %
    # cae en el 12. Se pasa por un compás. Esta es la única que no alarga por
    # falta de material, no por la música.
    "caza":       {"bpm": 120, "bpm_real": 83.4,
                   "toma": "a", "inicio": 20.41, "compases": 12},
    # 0,810 contra 0,598.
    #
    # Y NO ENTRA AL REPO TODAVÍA, porque no hay tienda ni descanso con
    # pantalla: hoy un nodo de descanso se resuelve solo y te devuelve al mapa,
    # así que no existe el momento en el que esta pieza sonaría. `CLAUDE.md`
    # lo tiene decidido para los sonidos con estas palabras — "un sonido vive
    # en el banco mientras no exista la cosa que lo dispara; el día que exista,
    # su receta se MUEVE" — y es el mismo caso. El corte se hace igual y se
    # guarda al lado de las tomas: el día que haya tienda, se cambia este
    # `False` y se le añade su fila a `NodoMusica.PIEZAS`, en el mismo commit.
    "tienda":     {"bpm": 70,  "toma": "a", "inicio": 58.52, "compases": 20,
                   "enganchada": False},
    "arranque":   {"bucle": False},
    "tilt":       {"bucle": False},
}

# CUÁNTO DURA UN BUCLE. §2 pedía de 20 a 40 s, y el techo lo subió Daniel
# oyéndolos: *"había pensado en alargar los audios, me parecen muy cortos"*.
# Tiene respaldo en la medida, pero solo en algunas piezas — `escritorio` sube
# de 0,855 a 0,949 de costura con 48 s en vez de 32, y `recuperado` de 0,182 a
# 0,740 con 68 s — mientras que `mapa` cierra mucho mejor corto (0,905 con 23 s
# contra 0,647 con 68). O sea que el largo bueno es de cada pieza, no del
# documento. El suelo se queda donde estaba: por debajo de 20 s el bucle se
# reconoce y cansa.
LARGO_MIN = 20.0
LARGO_MAX = 90.0

# CUÁNTA COSTURA SE PUEDE SACRIFICAR A CAMBIO DE DURACIÓN.
#
# Sin esto, alargar sería mover un número: el total premia la costura y en un
# empate técnico se llevaba el corte corto. Con esto, el barrido primero mira
# cuál es la mejor costura que se puede conseguir en la pieza, y de todos los
# cortes que quedan a menos de este margen elige EL MÁS LARGO.
#
# Se hace así y no metiendo la duración en el total a propósito: sumar
# segundos y correlaciones obliga a inventar una escala entre dos cosas que no
# se parecen, y el resultado sería un número que nadie sabe leer. Esto se lee
# solo — "el más largo de los que cierran bien" — y el mando dice exactamente
# cuánto vale "bien".
MARGEN_COSTURA = 0.06

# Y EL SUELO DE NIVEL, que es la otra mitad de "cierra bien". La primera
# versión de la regla de arriba filtraba SOLO por costura, y eso eligió para
# `caza` y `tienda` cortes con nivel 0,000 — doce decibelios o más de salto
# entre el final y el principio. Un bucle así casa de golpes y da un bajonazo
# de volumen en cada vuelta, que es más audible que un clic.
#
# 0,70 son 3,6 dB de salto: se nota si lo buscas y no salta a la cara.
NIVEL_MINIMO = 0.70

# Desvanecido de cada punta, en milisegundos. §2 pide de 5 a 10: lo justo para
# que no chasquee y no tanto como para que se oiga el bajón.
FUNDIDO_MS = 8

# Ventana con la que se compara la costura, en segundos. Se mira lo que suena
# JUSTO DESPUÉS del final contra lo que suena JUSTO DESPUÉS del inicio: si el
# bucle cae donde debe, los dos trozos están en la misma posición del ciclo
# musical y coinciden. Comparar el final con el principio a secas no vale —
# eso mide si la música es plana, no si el bucle cierra.
#
# Y SE MIDE SOBRE LOS ONSETS, NO SOBRE EL ESPECTRO. La primera versión de esto
# comparaba el espectro medio de los dos trozos y daba de 0,94 a 0,99 en las
# catorce tomas, o sea que no separaba nada: **estas piezas son planas a
# propósito** (§2 pide "cualquier trozo suena como cualquier otro"), así que el
# timbre medio es igual en toda la pieza y no dice nada del corte. Lo que
# distingue un bucle que cierra de uno que no es DÓNDE CAEN LOS GOLPES, y eso
# es tiempo. Es la misma avería que la de `sonidos.py` en `CLAUDE.md`: una
# medida de timbre que promedia el tiempo ignora justo lo que las separa.
VENTANA_COSTURA = 4.0

# Cuánto puede desviarse el BPM real del pedido para seguir dando el pedido por
# bueno, contando el doble y la mitad como el mismo tempo.
TOLERANCIA_BPM = 0.03


def decodificar(ruta: Path) -> np.ndarray:
    """El archivo entero como float32 mono a SR."""
    orden = ["ffmpeg", "-v", "error", "-i", str(ruta),
             "-f", "f32le", "-ac", "1", "-ar", str(SR), "-"]
    crudo = subprocess.run(orden, capture_output=True, check=True).stdout
    return np.frombuffer(crudo, dtype=np.float32)


def espectrograma(x: np.ndarray, salto: int = 512, ventana: int = 2048):
    """Magnitud en dB. Devuelve (marcos, bins)."""
    if len(x) < ventana:
        return np.zeros((0, ventana // 2 + 1), dtype=np.float32)
    n = 1 + (len(x) - ventana) // salto
    ven = np.hanning(ventana).astype(np.float32)
    marcos = np.lib.stride_tricks.as_strided(
        x, shape=(n, ventana),
        strides=(x.strides[0] * salto, x.strides[0])) * ven
    mag = np.abs(np.fft.rfft(marcos, axis=1))
    return 20.0 * np.log10(mag + 1e-6)


def envolvente_onsets(esp: np.ndarray) -> np.ndarray:
    """Flujo espectral positivo: dónde ENTRA energía nueva.

    Es lo que marca los golpes, y de sus repeticiones sale el tempo. La resta
    se recorta a positivo porque un instrumento que se apaga no es un golpe.
    """
    if esp.shape[0] < 2:
        return np.zeros(0, dtype=np.float32)
    dif = np.diff(esp, axis=0)
    return np.maximum(dif, 0.0).sum(axis=1)


def detectar_bpm(env: np.ndarray, salto: int) -> tuple:
    """BPM por autocorrelación de la envolvente, entre 50 y 180.

    Devuelve `(bpm, pulso)`, donde `pulso` es lo marcado que está el tempo: la
    altura del pico de autocorrelación respecto al desfase cero. **Hace falta
    tanto como el BPM**, porque tres de estas piezas están escritas para no
    tener pulso —`escritorio` es "casi silencio, una campana cada cuatro
    compases"— y en ellas el BPM que salga es el ruido de fondo con un número
    encima. Sin este segundo dato, la tabla dice 60,1 con la misma cara con la
    que dice 95,7 y no hay forma de saber cuál de los dos vale.

    Se le quita la media antes: sin eso la autocorrelación la domina el nivel
    continuo y el máximo cae siempre en el desfase 0.
    """
    if len(env) < 64:
        return 0.0, 0.0
    e = env - env.mean()
    ac = np.correlate(e, e, mode="full")[len(e) - 1:]
    if ac[0] <= 0.0:
        return 0.0, 0.0
    por_segundo = SR / salto
    lo = max(1, int(por_segundo * 60.0 / 180.0))
    hi = min(len(ac) - 1, int(por_segundo * 60.0 / 50.0))
    if hi <= lo:
        return 0.0, 0.0
    mejor = lo + int(np.argmax(ac[lo:hi]))
    return 60.0 * por_segundo / mejor, float(ac[mejor] / ac[0])


# PROBADO Y DESCARTADO: repartir el peso según la fuerza del pulso.
#
# La idea era que en `escritorio` y `recuperado` —escritas para no tener golpes,
# "a single slow detuned FM bell every four bars"— la costura medida sobre
# onsets no mediría nada, y que en esas la decisión tenía que salir del nivel y
# de la estabilidad. Medido, la fuerza de pulso sale de 0,645 a 0,897 en las
# CATORCE tomas: no separa ambientales de rítmicas, así que un umbral aquí
# sería un mando que no toca nada.
#
# Y de paso la contradice el propio dato que iba a proteger: si en `escritorio`
# no hubiera nada que correlacionar, sus dos tomas darían las dos cerca de
# cero, y dan +0,855 y -0,152. La costura mide ahí perfectamente. La columna se
# sigue imprimiendo porque el día que entre una pieza de verdad ambiental hay
# que poder verlo.


def bpm_efectivo(detectado: float, pedido: float) -> tuple:
    """Con qué BPM se corta de verdad, y si el pedido se cumplió.

    **El BPM del prompt es una hipótesis, no un dato.** Suno lo obedece a medias:
    medidas las catorce tomas, cinco de siete piezas salen con un tempo que no
    es el que se pidió. Y eso no es cosmético — la rejilla de compases sale del
    BPM, así que cortar con el pedido cuando el real es otro es cortar FUERA de
    frontera de compás, que es exactamente lo que §2 dice que produce el clic.

    Se cuentan el doble y la mitad como el mismo tempo: un detector de tempo
    confunde el pulso con el medio pulso constantemente, y para saber dónde cae
    un compás las dos respuestas valen igual.
    """
    if detectado <= 0.0:
        return pedido, True
    for mult in (0.5, 1.0, 2.0):
        if abs(detectado * mult - pedido) <= pedido * TOLERANCIA_BPM:
            return pedido, True
    return detectado, False


def fase_compas(env: np.ndarray, bpm: float, salto: int) -> float:
    """En qué segundo cae el primer tiempo fuerte.

    Sin esto, el barrido de inicios empieza donde le toque —el 15 % de la
    pieza— y avanza de compás en compás sobre una rejilla que no es la de la
    música. Los cortes caerían todos igual de mal, y encima de forma
    consistente, que es la manera de que un fallo no se vea en la tabla.
    """
    por_segundo = SR / salto
    paso = 60.0 / bpm * por_segundo
    if paso < 1.0 or len(env) < paso * 8:
        return 0.0
    mejor, mejor_suma = 0.0, -1.0
    despl = 0.0
    while despl < paso:
        idx = np.arange(despl, len(env) - 1, paso).astype(int)
        suma = float(env[idx].sum())
        if suma > mejor_suma:
            mejor_suma, mejor = suma, despl
        despl += 1.0
    return mejor / por_segundo


def pearson(a: np.ndarray, b: np.ndarray) -> float:
    n = min(len(a), len(b))
    if n < 4:
        return 0.0
    a, b = a[:n].astype(np.float64), b[:n].astype(np.float64)
    a, b = a - a.mean(), b - b.mean()
    da, db = float(np.linalg.norm(a)), float(np.linalg.norm(b))
    if da == 0.0 or db == 0.0:
        return 0.0
    return float(np.dot(a, b) / (da * db))


def rms_por_marco(x: np.ndarray, salto: int = 512) -> np.ndarray:
    n = len(x) // salto
    if n == 0:
        return np.zeros(0, dtype=np.float32)
    trozo = x[:n * salto].reshape(n, salto)
    return np.sqrt((trozo.astype(np.float64) ** 2).mean(axis=1))


def coseno(a: np.ndarray, b: np.ndarray) -> float:
    na, nb = np.linalg.norm(a), np.linalg.norm(b)
    if na == 0.0 or nb == 0.0:
        return 0.0
    return float(np.dot(a, b) / (na * nb))


def perfil(x: np.ndarray) -> np.ndarray:
    """Espectro medio de un trozo, en dB y sin el nivel general.

    Quitarle la media es lo que hace que compare TIMBRE y no volumen: dos
    trozos del mismo ostinato a distinto volumen tienen que salir parecidos.
    """
    esp = espectrograma(x)
    if esp.shape[0] == 0:
        return np.zeros(1025, dtype=np.float32)
    m = esp.mean(axis=0)
    return m - m.mean()


def puntuar(x: np.ndarray, env: np.ndarray, salto: int,
            ini: float, largo: float) -> dict:
    """Puntúa un candidato a bucle. Todo de 0 a 1, más alto es mejor."""
    a0, a1 = int(ini * SR), int((ini + largo) * SR)
    w = int(VENTANA_COSTURA * SR)
    if a1 + w > len(x) or a0 < 0:
        return {}
    por_segundo = SR / salto
    e0, e1 = int(ini * por_segundo), int((ini + largo) * por_segundo)
    ew = int(VENTANA_COSTURA * por_segundo)
    if e1 + ew > len(env):
        return {}

    # LA COSTURA, medida sobre los golpes. Lo que viene después del final
    # contra lo que viene después del inicio: si el corte cae en la misma
    # posición del ciclo, los golpes de los dos trozos caen en los mismos
    # instantes y la correlación sube. Si el bucle está desfasado medio
    # compás, los golpes de uno caen en los huecos del otro y se hunde.
    costura = pearson(env[e1:e1 + ew], env[e0:e0 + ew])

    # Y EL TIMBRE, con poco peso. No separa bucles buenos de malos —es plano en
    # toda la pieza— pero sí caza un corte que cruza un cambio de instrumento.
    timbre = coseno(perfil(x[a1:a1 + w]), perfil(x[a0:a0 + w]))

    # EL SALTO DE NIVEL en el empalme. Un bucle puede casar de golpes y aun así
    # dar un bache si el final viene más flojo que el principio.
    corto = int(0.05 * SR)
    r_fin = float(np.sqrt((x[a1 - corto:a1].astype(np.float64) ** 2).mean()))
    r_ini = float(np.sqrt((x[a0:a0 + corto].astype(np.float64) ** 2).mean()))
    salto_db = abs(20.0 * math.log10((r_fin + 1e-6) / (r_ini + 1e-6)))
    nivel = max(0.0, 1.0 - salto_db / 12.0)

    # LA ESTABILIDAD, que es literalmente lo que pide §2: "el ciclo más
    # estable". Poca variación de energía = cualquier trozo suena como
    # cualquier otro = no hay build ni clímax escondido dentro del bucle.
    r = rms_por_marco(x[a0:a1])
    estable = 0.0 if r.mean() <= 0 else max(0.0, 1.0 - float(r.std() / r.mean()))

    return {
        "inicio": ini, "largo": largo, "costura": costura, "timbre": timbre,
        "nivel": nivel, "estable": estable,
        "total": (0.50 * costura + 0.15 * timbre
                  + 0.15 * nivel + 0.20 * estable),
    }


def mejor_corte(x: np.ndarray, env: np.ndarray, salto: int,
                bpm: float, fase: float) -> dict:
    """Barre inicios en frontera de compás y devuelve el candidato ganador."""
    compas = 60.0 / bpm * 4.0
    dur = len(x) / SR
    candidatos = []
    # Longitudes: múltiplos de cuatro compases. Empezó siendo solo potencias
    # de dos y eso dejaba a `recuperado` —a 56 BPM— con UN candidato de largo
    # en toda la pieza: 8 compases son 34,3 s y 16 se pasan de 40. Un barrido
    # con un solo valor no es un barrido, es una comprobación.
    for n in range(4, 65, 4):
        largo = n * compas
        if not (LARGO_MIN <= largo <= LARGO_MAX):
            continue
        # Se tira el principio y el final (§2): el trozo bueno está en el
        # centro, y hay que dejar sitio para la ventana de costura. El barrido
        # arranca en el primer compás entero pasado el 15 % — así todos los
        # candidatos caen en la rejilla de la música, no en la del bucle for.
        k = math.ceil((dur * 0.15 - fase) / compas)
        ini = fase + k * compas
        tope = dur - largo - VENTANA_COSTURA - 1.0
        while ini <= tope:
            p = puntuar(x, env, salto, ini, largo)
            if p:
                p["compases"] = n
                candidatos.append(p)
            ini += compas
    if not candidatos:
        return {}
    # EL MÁS LARGO DE LOS QUE CIERRAN BIEN. Se mira primero cuál es la mejor
    # costura alcanzable en esta pieza, y entre todos los que se le acercan
    # gana la duración. En las piezas donde alargar rompe el bucle —`mapa`
    # pierde 0,26 de costura entre 23 s y 68— no hay ningún candidato largo
    # dentro del margen y el corte corto se queda, sin tener que escribirlo.
    # El suelo de nivel se aplica ANTES de mirar la costura: si no, el techo
    # de costura lo puede poner un corte con un bache de 12 dB, y entonces el
    # margen se mide contra un candidato que no era válido.
    sanos = [c for c in candidatos if c["nivel"] >= NIVEL_MINIMO]
    if not sanos:
        # Ninguno cierra sin bache. Antes que inventarse una excepción, se
        # devuelve el mejor por total y que lo juzgue la oreja.
        return max(candidatos, key=lambda c: c["total"])
    techo: float = max(c["costura"] for c in sanos)
    buenos = [c for c in sanos if c["costura"] >= techo - MARGEN_COSTURA]
    return max(buenos, key=lambda c: (c["largo"], c["total"]))


def fuentes(nombre: str, cfg: dict):
    """Los archivos de partida de una pieza: sus dos tomas, o la única.

    Todas llevan sufijo de toma, `arranque` y `tilt` incluidas aunque solo
    tengan una: sin él la fuente y el recorte final se llamarían igual, y
    cortar una pieza encima de su propio original la deja sin original. Estas
    dos no se pueden regenerar sin volver a Suno.
    """
    tomas = ("a", "b") if cfg.get("bucle", True) else ("a",)
    return [(t, FUENTES / f"{nombre}_{t}.ogg") for t in tomas]


def estudiar(ruta: Path, bpm_pedido: float, bpm_escrito=None) -> dict:
    """Todo lo que hace falta saber de una toma, medido de una vez."""
    x = decodificar(ruta)
    salto = 512
    env = envolvente_onsets(espectrograma(x, salto))
    det, pulso = detectar_bpm(env, salto)
    if bpm_escrito is not None:
        bpm, cumple = float(bpm_escrito), False
    else:
        bpm, cumple = bpm_efectivo(det, bpm_pedido)
    fase = fase_compas(env, bpm, salto)
    c = mejor_corte(x, env, salto, bpm, fase)
    return {"x": x, "detectado": det, "pulso": pulso,
            "bpm": bpm, "cumple": cumple, "fase": fase, "corte": c}


def analizar() -> None:
    print(f"{'pieza':<12} {'toma':<5} {'bpm ped':>7} {'bpm det':>7} "
          f"{'pulso':>6} {'usa':>6} {'inicio':>7} {'largo':>6} {'cmp':>4} "
          f"{'costura':>8} {'timbre':>7} {'nivel':>6} {'estable':>8} "
          f"{'TOTAL':>6}")
    print("-" * 118)
    for nombre, cfg in PIEZAS.items():
        if not cfg.get("bucle", True):
            for _, ruta in fuentes(nombre, cfg):
                if not ruta.exists():
                    print(f"{nombre:<12} FALTA {ruta.name}")
                    continue
                x = decodificar(ruta)
                r = rms_por_marco(x)
                umbral = r.max() * 0.02
                fin = len(r)
                while fin > 1 and r[fin - 1] < umbral:
                    fin -= 1
                print(f"{nombre:<12} {'-':<5} {'sin bucle':>15} "
                      f"dura {len(x)/SR:6.2f} s, "
                      f"con sonido hasta {fin*512/SR:5.2f} s")
            continue
        for toma, ruta in fuentes(nombre, cfg):
            if not ruta.exists():
                print(f"{nombre:<12} {toma:<5} FALTA {ruta.name}")
                continue
            pedido = float(cfg["bpm"])
            e = estudiar(ruta, pedido)
            c = e["corte"]
            marca = "<-" if toma == cfg.get("toma") else "  "
            if not e["cumple"]:
                marca = "!" + marca.strip()
            cab = (f"{nombre:<12} {toma:<5} {pedido:>7.0f} "
                   f"{e['detectado']:>7.1f} {e['pulso']:>6.3f} "
                   f"{e['bpm']:>6.1f}")
            if not c:
                print(f"{cab}   sin candidato de 20-40 s {marca}")
                continue
            print(f"{cab} "
                  f"{c['inicio']:>7.2f} {c['largo']:>6.2f} {c['compases']:>4} "
                  f"{c['costura']:>8.3f} {c['timbre']:>7.3f} "
                  f"{c['nivel']:>6.3f} {c['estable']:>8.3f} "
                  f"{c['total']:>6.3f} {marca}")
    print("\n  <- la toma elegida en la tabla PIEZAS."
          "\n  !  el BPM real no es el que se pidió: se corta con el real."
          "\n  ~  la pieza no tiene pulso audible: la costura no mide, y la"
          "\n     decide el nivel, el timbre y lo estable que sea el trozo.")


def cortar(seco: bool) -> None:
    for nombre, cfg in PIEZAS.items():
        # Una pieza que el juego todavía no pide no se deja en `assets/`: ahí
        # sería un archivo que nadie carga, y hay una prueba que lo caza. Se
        # corta igual y se guarda junto a las tomas hasta que tenga sitio.
        en_repo = cfg.get("enganchada", True)
        destino = (MUSICA if en_repo else FUENTES) / f"{nombre}.ogg"
        if not cfg.get("bucle", True):
            # Las que terminan solo pierden la cola de silencio. El aire de
            # después es parte del efecto en `tilt` (§4.9), así que se le deja
            # medio segundo en vez de cortarlo a hueso.
            ruta = FUENTES / f"{nombre}_a.ogg"
            if not ruta.exists():
                print(f"  ! falta {ruta.name}")
                continue
            x = decodificar(ruta)
            r = rms_por_marco(x)
            umbral = r.max() * 0.02
            fin = len(r)
            while fin > 1 and r[fin - 1] < umbral:
                fin -= 1
            largo = min(len(x) / SR, fin * 512 / SR + 0.5)
            print(f"  {nombre:<12} sin bucle, 0 -> {largo:.2f} s")
            if not seco:
                _exportar(ruta, 0.0, largo, destino, fundir_entrada=False)
            continue

        toma = cfg["toma"]
        origen = FUENTES / f"{nombre}_{toma}.ogg"
        if not origen.exists():
            print(f"  ! falta {origen.name}")
            continue
        ini, compases = cfg.get("inicio"), cfg.get("compases")
        e = estudiar(origen, float(cfg["bpm"]), cfg.get("bpm_real"))
        if ini is None or compases is None:
            c = e["corte"]
            if not c:
                print(f"  ! {nombre}: sin candidato")
                continue
            ini, compases = c["inicio"], c["compases"]
            print(f"  {nombre:<12} toma {toma}  AUTO  "
                  f"{ini:.2f} s + {compases} compases", end="")
        else:
            print(f"  {nombre:<12} toma {toma}  tabla "
                  f"{ini:.2f} s + {compases} compases", end="")
        largo = compases * 60.0 / e["bpm"] * 4.0
        print(f" a {e['bpm']:.1f} BPM = {largo:.2f} s"
              + ("" if en_repo else "   [al banco: aun no la pide nadie]"))
        if not seco:
            _exportar(origen, float(ini), largo, destino)


def mosaico(carpeta: Path) -> None:
    """Saca cada bucle repetido tres veces, para poder juzgarlo con la oreja.

    Es el mosaico de revisión de `CLAUDE.md` aplicado al oído. Un bucle no se
    juzga escuchándolo una vez de principio a fin: se juzga en el EMPALME, y el
    empalme solo existe cuando el archivo vuelve a empezar. §2 lo pide con esas
    palabras — "escúchalo cinco veces seguidas en bucle: si a la tercera te
    molesta algo, es el corte, no la música" — y sin esto no hay forma de
    hacerlo sin montarlo a mano en un editor.

    Salen LAS DOS TOMAS de cada pieza, no solo la elegida, porque la elección
    escrita en `PIEZAS` está hecha por medida y la medida dice cuál CIERRA
    mejor, no cuál suena mejor.

    Va fuera del repo a propósito: Godot escanea el proyecto entero y un OGG
    suelto que nadie carga es exactamente lo que el candado de catálogo tiene
    que cazar.
    """
    carpeta.mkdir(parents=True, exist_ok=True)
    for nombre, cfg in PIEZAS.items():
        if not cfg.get("bucle", True):
            continue
        for toma, origen in fuentes(nombre, cfg):
            if not origen.exists():
                continue
            elegida = toma == cfg.get("toma")
            e = estudiar(origen, float(cfg["bpm"]),
                         cfg.get("bpm_real") if elegida else None)
            if elegida and cfg.get("inicio") is not None:
                ini, compases = float(cfg["inicio"]), int(cfg["compases"])
            elif e["corte"]:
                ini, compases = e["corte"]["inicio"], e["corte"]["compases"]
            else:
                continue
            largo = compases * 60.0 / e["bpm"] * 4.0
            marca = "ELEGIDA" if elegida else "       "
            suelto = carpeta / f"{nombre}_{toma}.ogg"
            _exportar(origen, ini, largo, suelto)
            triple = carpeta / f"{nombre}_{toma}_x3.ogg"
            lista = carpeta / f"{nombre}_{toma}.txt"
            lista.write_text(
                "".join(f"file '{suelto.as_posix()}'\n" for _ in range(3)),
                encoding="utf-8")
            # SE REENCODIFICA, NO SE COPIA, y esto costó una revisión entera.
            # Con `-c copy` el concat de Ogg no fusiona nada: deja los tres
            # bitstreams encadenados, cada uno con su serial y sus tiempos
            # empezando de cero. El reproductor toca el primero y se planta —
            # que es justo lo que hay que oír en un mosaico de bucles, así que
            # el fallo se disfraza de "el bucle no cierra". La cabecera lo
            # cantaba: `combate_b_x3` declaraba 102 s con 120 s dentro.
            subprocess.run(
                ["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0",
                 "-i", str(lista), "-c:a", "libvorbis", "-q:a", "5",
                 str(triple)], check=True)
            lista.unlink()
            print(f"  {marca} {triple.name}  "
                  f"{ini:.2f} s + {compases} compases = {largo:.2f} s")
    print(f"\n  En {carpeta}")


def _exportar(origen: Path, ini: float, largo: float, destino: Path,
              fundir_entrada: bool = True) -> None:
    """Corta y escribe el OGG final, con sus fundidos de punta.

    Se escribe a un temporal y se renombra encima, nunca directo: origen y
    destino pueden ser el MISMO archivo cuando la pieza no lleva toma (el caso
    de `arranque` y `tilt`), y ffmpeg leyendo lo que está escribiendo deja el
    archivo a medias. Es la misma razón que el guardado de `CLAUDE.md`.
    """
    f = FUNDIDO_MS / 1000.0
    filtros = [f"afade=t=out:st={largo - f:.4f}:d={f:.4f}"]
    if fundir_entrada:
        filtros.insert(0, f"afade=t=in:st=0:d={f:.4f}")
    tmp = destino.with_suffix(".tmp.ogg")
    orden = ["ffmpeg", "-y", "-v", "error",
             "-ss", f"{ini:.4f}", "-t", f"{largo:.4f}", "-i", str(origen),
             "-af", ",".join(filtros),
             "-c:a", "libvorbis", "-q:a", "5", str(tmp)]
    subprocess.run(orden, check=True)
    tmp.replace(destino)


def main() -> int:
    global LARGO_MIN, LARGO_MAX
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("orden", choices=["analizar", "cortar", "mosaico"])
    ap.add_argument("--aplicar", action="store_true",
                    help="sin esto, `cortar` solo dice lo que haría")
    ap.add_argument("--a", default="", metavar="CARPETA",
                    help="dónde deja `mosaico` los bucles repetidos")
    ap.add_argument("--largo", default="", metavar="MIN-MAX",
                    help="rango de duración del bucle en segundos, para "
                         "explorar (por defecto %g-%g)" % (LARGO_MIN, LARGO_MAX))
    args = ap.parse_args()
    if args.largo:
        LARGO_MIN, LARGO_MAX = [float(v) for v in args.largo.split("-")]
    if shutil.which("ffmpeg") is None:
        print("Falta ffmpeg en el PATH.", file=sys.stderr)
        return 1
    if args.orden == "analizar":
        analizar()
    elif args.orden == "mosaico":
        if not args.a:
            print("mosaico necesita --a CARPETA, y fuera del repo.",
                  file=sys.stderr)
            return 1
        mosaico(Path(args.a))
    else:
        cortar(seco=not args.aplicar)
        if not args.aplicar:
            print("\n(simulacro: nada escrito. Añade --aplicar)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
