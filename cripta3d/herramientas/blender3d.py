# blender3d.py — lanza un guion de Blender SIN interfaz y enseña lo que importa de su salida.
#
#   python cripta3d/herramientas/blender3d.py cripta3d/blender/loquesea.py [--tiempo S] [--lineas N]
#          [-- argumentos para el guion]
#
# Dentro del guion, los argumentos se leen así:
#   argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
#
# Blender 5.3 portable, en C:\Tools (se puede cambiar con la variable BLENDER_EXE).
# Va con `--factory-startup` para que no dependa de la configuración de nadie y con
# `--python-exit-code 1` para que un error del guion se vea en el código de salida.
import os
import subprocess
import sys
import time

BLENDER = os.environ.get("BLENDER_EXE", r"C:\Tools\blender-5.3.0-windows-x64\blender.exe")
RUIDO = ("Fra:", "Saved:", " Time: ", "Sample ", "| Mem:", "Read prefs", "found bundled python",
         "Rendering ", "Updating ", "Loading ", "Finished")


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass
    a = sys.argv[1:]
    if not a or a[0] in ("-h", "--help", "ayuda"):
        with open(__file__, encoding="utf-8") as f:
            print(f.read().split("import os")[0])
        return 2
    usuario = []
    if "--" in a:
        i = a.index("--")
        a, usuario = a[:i], a[i + 1:]
    tiempo, lineas, guion = 900.0, 60, None
    i = 0
    while i < len(a):
        if a[i] == "--tiempo":
            i += 1
            tiempo = float(a[i])
        elif a[i] == "--lineas":
            i += 1
            lineas = int(a[i])
        elif guion is None:
            guion = a[i]
        i += 1
    if guion is None or not os.path.exists(guion):
        print("[blender3d] no encuentro el guion:", guion)
        return 2
    args = [BLENDER, "--background", "--factory-startup", "--python-exit-code", "1",
            "--python", guion, "--"] + usuario
    t0 = time.time()
    try:
        r = subprocess.run(args, capture_output=True, timeout=tiempo)
    except subprocess.TimeoutExpired:
        print("[blender3d] TIEMPO AGOTADO a los %.0f s: lo he matado" % tiempo)
        return 124
    texto = (r.stdout + b"\n" + r.stderr).decode("utf-8", "replace")
    todas = [l.rstrip() for l in texto.splitlines() if l.strip()]
    utiles = [l for l in todas if not any(l.lstrip().startswith(x) or x in l[:40] for x in RUIDO)]
    cola = utiles[-lineas:] if lineas > 0 else utiles
    print("\n".join(cola))
    graves = [l for l in todas if "Traceback" in l or "Error" in l]
    print("[blender3d] %.1f s, código %d; %d líneas útiles, %d con Error/Traceback" % (
        time.time() - t0, r.returncode, len(utiles), len(graves)))
    return r.returncode


if __name__ == "__main__":
    sys.exit(main())
