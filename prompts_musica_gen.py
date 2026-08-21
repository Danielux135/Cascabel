#!/usr/bin/env python3
"""Monta los prompts de música enteros y reescribe §12 y §13.4.

Existe porque un prompt de estos son cuatro bloques pegados —timbre, cuerpo,
repetición y bucle— y montarlos a mano once veces es once oportunidades de que
uno se quede sin una línea. Y una línea que falta en un prompt no da error:
da una toma que no sirve, y no se sabe por qué hasta medirla.

    python prompts_musica_gen.py            # dice lo que haría
    python prompts_musica_gen.py --aplicar  # reescribe assets/prompts_musica.md
"""

import argparse
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent
DOC = RAIZ / "assets" / "prompts_musica.md"

# BLOQUE T — el timbre común, §4. Va al principio de todos.
T = ("1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, Adlib and Sound "
     "Blaster sound card timbres, tracker module music, MOD and XM demoscene, "
     "cheap General MIDI orchestral patches, Roland SC-55, slightly detuned "
     "and out of tune, hollow metallic tones, dry and close, lo-fi 22 kHz "
     "sample rate, dark, cold, mysterious, unresolved")

# BLOQUE R — la repetición de la SECCIÓN, §11. Es el que decide si habrá bucle.
#
# `for the entire duration` y no "at least 3 minutes": desde que Suno tiene
# mando de duración, el largo lo pone el deslizador y escribirlo en el texto
# solo puede contradecirlo. Y las repeticiones suben de ocho a dieciséis
# porque con el deslizador al máximo caben: a 96 BPM, ocho compases son 20 s,
# así que en ocho minutos entran veinticuatro.
def bloque_r(compases: int) -> str:
    return (f"the exact same {compases}-bar phrase repeated identically for "
            "the entire duration, at least sixteen times, every repetition "
            "must be identical to the previous one, no variation between "
            "repetitions, no fills, no drum fills, no turnarounds, no "
            "transitions, no new instrument enters after the first bar, "
            "nothing is added and nothing is taken away, the arrangement is "
            "frozen, the same loop from the first second to the last")

# BLOQUE L — el bucle, §2. Va al final, con su BPM.
def bloque_l(bpm: int, extra: str = "") -> str:
    return ("loopable, seamless loop, no intro, no outro, no fade in, no fade "
            "out, consistent energy throughout, no build, no climax, no drop, "
            "no breakdown, single key, no key change, no modulation, steady "
            f"rhythm, exactly {bpm} BPM, {extra}minimal variation, repetitive "
            "ostinato, instrumental, no vocals")

# El cuerpo de cada pieza: lo que la distingue de las otras. Sale de §4 y no
# se toca — es la descripción que ya estaba decidida.
CUERPOS = {
    "combate": (96, 8, "", (
        "driving dungeon crawler groove, low FM bass ostinato repeating every "
        "two bars, tight dry tracker drums, dark minor mode, one sustained "
        "low drone underneath, no lead melody at all, melodic movement only "
        "in the deep bass and in occasional high metallic bells, relentless, "
        "mechanical, hypnotic, the same two bars forever, patient menace")),
    "caza": (120, 8, "fast and urgent tempo, ", (
        "nervous fast ostinato, high plucked FM, an audible ticking clock "
        "underneath getting slightly ahead of the beat, thin and exposed "
        "arrangement, greedy, unsafe, the feeling of stealing time, it should "
        "have stopped by now")),
    "mapa": (84, 8, "", (
        "cold minimal arpeggio on a hollow FM patch, mechanical ticking "
        "pulse, one low cheap MIDI string pad, no melody, calculating, "
        "waiting, faint dread, nothing threatening yet")),
    "jefe": (108, 8, "", (
        "boss theme, heavy detuned FM brass stabs, tritone interval, "
        "relentless sixteenth note bass, dry mechanical drums, one distant "
        "choir pad far back in the mix, oppressive and inevitable, no "
        "heroism, no triumph, nothing to win, the feeling of a process that "
        "cannot be killed")),
    "escritorio": (60, 8, "", (
        "sparse dark ambient, almost silent, a single slow detuned FM bell "
        "every four bars, deep sub drone, distant hard drive seek noise and "
        "fan hum used as percussion, one unresolved minor second held too "
        "long, vast empty room, patient, waiting, nothing is happening and "
        "that is wrong")),
    # 16 compases y es el único: su frase melódica no cabe en ocho, que es
    # literalmente por lo que a 34 s no cerraba y a 68 sí.
    "recuperado": (56, 16, "", (
        "fragile and beautiful, a single unfinished melody on a detuned music "
        "box, one distant detuned choir pad, long silences between phrases, "
        "the melody stops mid-phrase and starts over from the beginning, "
        "never reaching its final note, melancholy, tender, something was "
        "here and is not here now")),
    "tienda": (70, 8, "", (
        "warm but wrong, slow detuned music box, one cheap MIDI harp, major "
        "key that keeps sliding flat, comforting and not quite right, very "
        "sparse, too much reverb for such a small room, safe for now")),
}

# LOS PUENTES. Ni bloque R ni bloque L: estos TERMINAN, y pedirles que se
# repitan es pedirles lo contrario de lo que son. El bloque T se recorta
# —no hace falta la mitad para dos segundos de ruido de máquina— pero se
# queda, porque tienen que sonar a la misma máquina que todo lo demás.
T_CORTO = ("1990s PC dungeon crawler soundtrack, OPL3 FM synthesis, Adlib and "
           "Sound Blaster sound card timbres, cheap General MIDI patches, "
           "Roland SC-55, slightly detuned, hollow metallic tones, dry and "
           "close, lo-fi 22 kHz sample rate")

PUENTES = {
    "puente_entrar": (
        "dark, cold, a short 2 second transition sting for an old operating "
        "system launching a program, a hard drive spinning up and seeking, "
        "one low FM tone rising and cutting off dead, mechanical relay click "
        "at the end, no melody, no rhythm, no tempo, no key, 2 seconds, ends "
        "in silence, instrumental, no vocals"),
    "puente_salir": (
        "dark, cold, a short 2 second transition sting for an old operating "
        "system closing a program, a hard drive spinning down, one low FM "
        "tone descending and losing pitch as if the power is dropping, a soft "
        "mechanical click, no melody, no rhythm, no tempo, no key, 2 seconds, "
        "ends in silence, instrumental, no vocals"),
    "puente_caza": (
        "a short 3 second transition sting for a hidden bonus area opening, "
        "air pressure rising, one detuned FM bell struck once and left "
        "ringing, a distant choir pad swelling underneath and cut off before "
        "it resolves, wonder and unease at once, something you were not "
        "supposed to reach, no melody, no rhythm, no tempo, 3 seconds, ends "
        "unresolved, instrumental, no vocals"),
    "puente_ventana": (
        "a very short 1.5 second sting for a window opening in an old "
        "operating system, one dull wooden knock, a brief burst of tape hiss, "
        "one flat detuned bell, no melody, no rhythm, no tempo, no key, "
        "1.5 seconds, ends in silence, instrumental, no vocals"),
}

# Orden de importancia, no de aparición: `combate` suena el 80 % de la partida.
ORDEN = ["combate", "caza", "mapa", "jefe", "escritorio", "recuperado",
         "tienda"]

NOTAS = {
    "caza": (
        "**Ojo con el tempo en esta.** Las dos tomas anteriores pidieron 120 y "
        "salieron a 83,4 y 80,7 — la única pieza donde Suno se fue tan lejos, "
        "y encima es la que tiene que dar prisa. Por eso lleva `fast and "
        "urgent tempo` además del número. **Se mide antes de cortar** "
        "(`python musica.py analizar`): si vuelve a salir por debajo de 100, "
        "la toma no sirve aunque suene bien."),
    "recuperado": (
        "**Lleva 16 compases en vez de 8**, y es el único caso: su frase "
        "melódica no cabe en ocho, que es literalmente por lo que a 34 s no "
        "cerraba y a 68 sí.\n\n"
        "**Y es la que menos falta hace regenerar**, porque su toma actual ya "
        "funciona a 68 s y fue la única que mejoró al alargarla. **La que hay "
        "no se tira hasta que algo la supere de verdad**, que es la regla de "
        "`CLAUDE.md`: si una tanda no supera a lo que ya está, no entra."),
    "combate": (
        "**La más importante de las siete.** Suena el 80 % de la partida y "
        "hoy no da más de 40 s teniendo una toma de 141."),
}


def prompt_de(nombre: str) -> str:
    bpm, compases, extra, cuerpo = CUERPOS[nombre]
    return ", ".join([T, cuerpo, bloque_r(compases), bloque_l(bpm, extra)])


def prompt_puente(nombre: str) -> str:
    return ", ".join([T_CORTO, PUENTES[nombre]])


def seccion_12() -> str:
    out = ["## 12. Los prompts de regeneración, ENTEROS", "",
           "Cada uno es UN bloque para copiar y pegar entero. Llevan dentro el",
           "bloque T, el cuerpo, el bloque R y el bloque L: no hay que componer",
           "nada ni pegar nada delante.", "",
           "**Los genera `prompts_musica_gen.py`**, y por eso esta sección no se",
           "edita a mano: montar cuatro bloques once veces son once ocasiones de",
           "que a uno le falte una línea, y una línea que falta no da error —",
           "da una toma que no sirve y no se sabe por qué hasta medirla.", "",
           "### Los ajustes de la interfaz de Suno, que no van en el texto", "",
           "| mando | valor | por qué |",
           "|---|---|---|",
           "| **Letra** | `Instrumental` | `no vocals` en el texto no basta: se "
           "cuela un \"ah\" de fondo. Es invariante — ninguna pieza del juego "
           "lleva voz. |",
           "| **Duración** | **al máximo** | Cuanto más largo, más "
           "repeticiones de la sección, y por tanto más sitio donde el bucle "
           "puede caer bien. Es el mando que no existía cuando se cortaron las "
           "primeras ocho. |",
           "| **Influencia del estilo** | alta | El prompt son cuatro bloques "
           "de restricciones; bajarla es pedirle que las ignore. |",
           "| **Rareza** | baja | Aquí no se busca sorpresa, se busca que "
           "repita. |", "",
           "**Y se generan VARIAS TOMAS DE GOLPE con el mismo prompt**, sin",
           "ajustar entre tirada y tirada. Es la lección de `CLAUDE.md` sobre las",
           "hojas de animación y vale igual aquí: cada generación es una tirada",
           "nueva, no una edición de la anterior.", ""]
    for i, nombre in enumerate(ORDEN, start=1):
        bpm = CUERPOS[nombre][0]
        out += [f"### 12.{i} `{nombre}` — {bpm} BPM", ""]
        if nombre in NOTAS:
            out += [NOTAS[nombre], ""]
        out += ["```", prompt_de(nombre), "```", ""]
    return "\n".join(out)


def seccion_134() -> str:
    out = ["### 13.4 Los prompts de puente, ENTEROS", "",
           "**Aquí no se pega ni el bloque R ni el bloque L.** El R pide que la",
           "sección vuelva y el L que no haya final: un puente es exactamente lo",
           "contrario de las dos cosas. El T sí, recortado, porque tienen que",
           "sonar a la misma máquina.", "",
           "**Y la duración va al MÍNIMO**, al revés que en §12. Es el único",
           "sitio de este documento donde ese deslizador se baja.", ""]
    for nombre in ("puente_entrar", "puente_salir", "puente_caza",
                   "puente_ventana"):
        out += [f"#### `{nombre}`", "", "```", prompt_puente(nombre), "```", ""]
        if nombre == "puente_caza":
            out += ["**Es el único de los cuatro que puede ser bonito**, y §1 "
                    "dice que el coro arcano va con cuentagotas: si suena aquí, "
                    "ya solo puede sonar en `recuperado`. Es una decisión, no un "
                    "adorno — dónde suena lo único bonito de la banda sonora es "
                    "lo que el jugador aprende a querer.", ""]
    return "\n".join(out)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--aplicar", action="store_true")
    args = ap.parse_args()
    s = DOC.read_text(encoding="utf-8")

    nueva12, nueva134 = seccion_12(), seccion_134()
    s2 = re.sub(r"## 12\. Los prompts.*?(?=\n---\n\n## 13\.)",
                lambda _m: nueva12, s, flags=re.S)
    s2 = re.sub(r"### 13\.4 .*?(?=\n### 13\.5 )",
                lambda _m: nueva134, s2, flags=re.S)
    if s2 == s:
        print("No se ha sustituido nada: ¿han cambiado los encabezados?",
              file=sys.stderr)
        return 1
    print("§12: %d prompts   §13.4: %d puentes" % (len(ORDEN), len(PUENTES)))
    for nombre in ORDEN:
        print(f"  {nombre:<11} {len(prompt_de(nombre)):4d} caracteres")
    if args.aplicar:
        DOC.write_text(s2, encoding="utf-8")
        print(f"\nEscrito en {DOC}")
    else:
        print("\n(simulacro: nada escrito. Añade --aplicar)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
