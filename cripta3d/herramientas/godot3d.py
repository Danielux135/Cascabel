# godot3d.py — lanza Godot SIN que se vea ni robe el foco, y de uno en uno.
#
#   python cascabel3d/herramientas/godot3d.py importar
#   python cascabel3d/herramientas/godot3d.py escena res://ruta/escena.tscn [--metodo compat|forward]
#          [--fotogramas N] [--fps 60] [--res 1280x720] [--visible] [--tiempo S] [--lineas N]
#          [-- argumentos de usuario para la escena]
#   python cascabel3d/herramientas/godot3d.py guion res://ruta/guion.gd [-- args]
#   python cascabel3d/herramientas/godot3d.py crudo -- <argumentos tal cual para Godot>
#
# POR QUÉ EXISTE. `--headless` no dibuja, así que para capturar hace falta una
# ventana de verdad, y una ventana de verdad se le planta a Daniel en la pantalla
# cada vez. Aquí la ventana se crea en OTRO ESCRITORIO de Windows (CreateDesktop):
# existe, tiene contexto gráfico y la tarjeta dibuja en ella, pero no se compone
# en el escritorio que se está usando, así que ni se ve ni puede quitar el foco.
# Probado el 17-nov-2026 con OpenGL (Compatibility) y con D3D12 (Forward+).
#
# VA CON CANDADO: dos Godot a la vez sobre el mismo proyecto se pisan `.godot/`
# al importar y se reparten la tarjeta. El segundo espera a que acabe el primero.
#
# Y VA A PASO FIJO (`--fps 60`, que es `--fixed-fps` de Godot): cada fotograma
# vale 1/60 s pase lo que pase, así que `--fotogramas 600` son diez segundos de
# juego exactos y la captura sale igual aunque la tarjeta dibuje a 400 por
# segundo. Sin esto, en el escritorio oculto no hay sincronía vertical y un
# guion de diez segundos se acababa en uno. Con `--fps 0` va a tiempo real.
import ctypes
import msvcrt
import os
import subprocess
import sys
import tempfile
import time
from ctypes import wintypes as wt

GODOT = os.environ.get("GODOT_EXE", r"C:\Users\Daniel\Desktop\Godot\Godot_v4.7.1-stable_win64.exe")
AQUI = os.path.dirname(os.path.abspath(__file__))
ESCRITORIO = "cascabel_capturas"

k32 = ctypes.WinDLL("kernel32", use_last_error=True)
u32 = ctypes.WinDLL("user32", use_last_error=True)


class STARTUPINFOW(ctypes.Structure):
    _fields_ = [("cb", wt.DWORD), ("lpReserved", wt.LPWSTR), ("lpDesktop", wt.LPWSTR),
                ("lpTitle", wt.LPWSTR), ("dwX", wt.DWORD), ("dwY", wt.DWORD),
                ("dwXSize", wt.DWORD), ("dwYSize", wt.DWORD), ("dwXCountChars", wt.DWORD),
                ("dwYCountChars", wt.DWORD), ("dwFillAttribute", wt.DWORD), ("dwFlags", wt.DWORD),
                ("wShowWindow", wt.WORD), ("cbReserved2", wt.WORD),
                ("lpReserved2", ctypes.POINTER(ctypes.c_byte)), ("hStdInput", wt.HANDLE),
                ("hStdOutput", wt.HANDLE), ("hStdError", wt.HANDLE)]


class PROCESS_INFORMATION(ctypes.Structure):
    _fields_ = [("hProcess", wt.HANDLE), ("hThread", wt.HANDLE),
                ("dwProcessId", wt.DWORD), ("dwThreadId", wt.DWORD)]


class SECURITY_ATTRIBUTES(ctypes.Structure):
    _fields_ = [("nLength", wt.DWORD), ("lpSecurityDescriptor", wt.LPVOID),
                ("bInheritHandle", wt.BOOL)]


k32.CreateFileW.restype = wt.HANDLE
k32.CreateFileW.argtypes = [wt.LPCWSTR, wt.DWORD, wt.DWORD, ctypes.POINTER(SECURITY_ATTRIBUTES),
                            wt.DWORD, wt.DWORD, wt.HANDLE]
k32.CreateProcessW.argtypes = [wt.LPCWSTR, wt.LPWSTR, wt.LPVOID, wt.LPVOID, wt.BOOL, wt.DWORD,
                               wt.LPVOID, wt.LPCWSTR, ctypes.POINTER(STARTUPINFOW),
                               ctypes.POINTER(PROCESS_INFORMATION)]
k32.WaitForSingleObject.argtypes = [wt.HANDLE, wt.DWORD]
k32.TerminateProcess.argtypes = [wt.HANDLE, wt.UINT]
k32.GetExitCodeProcess.argtypes = [wt.HANDLE, ctypes.POINTER(wt.DWORD)]
k32.CloseHandle.argtypes = [wt.HANDLE]
u32.CreateDesktopW.restype = wt.HANDLE
u32.CreateDesktopW.argtypes = [wt.LPCWSTR, wt.LPCWSTR, wt.LPVOID, wt.DWORD, wt.DWORD, wt.LPVOID]
u32.CloseDesktop.argtypes = [wt.HANDLE]

INVALIDO = wt.HANDLE(-1).value


def raiz_del_repo():
    d = AQUI
    for _ in range(6):
        if os.path.exists(os.path.join(d, "project.godot")):
            return d
        d = os.path.dirname(d)
    return os.environ.get("CASCABEL_REPO", r"C:\dev\tilt-os-3d")


class Candado:
    """Un Godot cada vez. Se suelta solo si el proceso muere."""

    def __init__(self, espera=1800.0):
        self.ruta = os.path.join(tempfile.gettempdir(), "cascabel_godot3d.candado")
        self.espera = espera
        self.f = None

    def __enter__(self):
        self.f = open(self.ruta, "a+b")
        t0 = time.time()
        avisado = False
        while True:
            try:
                self.f.seek(0)
                msvcrt.locking(self.f.fileno(), msvcrt.LK_NBLCK, 1)
                return self
            except OSError:
                if not avisado:
                    print("[godot3d] otro Godot en marcha: espero mi turno...", flush=True)
                    avisado = True
                if time.time() - t0 > self.espera:
                    raise SystemExit("[godot3d] el candado no se suelta tras %.0f s" % self.espera)
                time.sleep(0.5)

    def __exit__(self, *a):
        try:
            self.f.seek(0)
            msvcrt.locking(self.f.fileno(), msvcrt.LK_UNLCK, 1)
        finally:
            self.f.close()


def lanzar(args, oculto=True, tiempo=240.0, lineas=60):
    """Ejecuta Godot con `args`. Devuelve (código, salida)."""
    orden = subprocess.list2cmdline([GODOT] + args)
    registro = os.path.join(tempfile.gettempdir(), "cascabel_godot3d_%d.log" % os.getpid())
    sa = SECURITY_ATTRIBUTES(ctypes.sizeof(SECURITY_ATTRIBUTES), None, True)
    h_log = k32.CreateFileW(registro, 0x40000000, 0x3, ctypes.byref(sa), 2, 0x80, None)
    h_nul = k32.CreateFileW("NUL", 0x80000000, 0x3, ctypes.byref(sa), 3, 0x80, None)
    if h_log == INVALIDO or h_nul == INVALIDO:
        raise SystemExit("[godot3d] no puedo abrir el registro: %d" % ctypes.get_last_error())
    si = STARTUPINFOW()
    si.cb = ctypes.sizeof(STARTUPINFOW)
    si.dwFlags = 0x100  # STARTF_USESTDHANDLES
    si.hStdInput, si.hStdOutput, si.hStdError = h_nul, h_log, h_log
    h_desk = None
    if oculto:
        h_desk = u32.CreateDesktopW(ESCRITORIO, None, None, 0, 0x10000000, None)
        if not h_desk:
            print("[godot3d] AVISO: no hay escritorio oculto (error %d): la ventana se verá"
                  % ctypes.get_last_error(), flush=True)
        else:
            si.lpDesktop = ESCRITORIO
    pi = PROCESS_INFORMATION()
    buf = ctypes.create_unicode_buffer(orden)
    t0 = time.time()
    ok = k32.CreateProcessW(None, buf, None, None, True, 0, None, None,
                            ctypes.byref(si), ctypes.byref(pi))
    if not ok:
        err = ctypes.get_last_error()
        k32.CloseHandle(h_log)
        k32.CloseHandle(h_nul)
        raise SystemExit("[godot3d] no arranca Godot (error %d): %s" % (err, orden))
    agotado = k32.WaitForSingleObject(pi.hProcess, int(tiempo * 1000)) == 0x102
    if agotado:
        k32.TerminateProcess(pi.hProcess, 124)
        k32.WaitForSingleObject(pi.hProcess, 5000)
    codigo = wt.DWORD()
    k32.GetExitCodeProcess(pi.hProcess, ctypes.byref(codigo))
    for h in (pi.hThread, pi.hProcess, h_log, h_nul):
        k32.CloseHandle(h)
    if h_desk:
        u32.CloseDesktop(h_desk)
    try:
        with open(registro, "rb") as f:
            texto = f.read().decode("utf-8", "replace")
        os.remove(registro)
    except OSError:
        texto = ""
    seg = time.time() - t0
    todas = texto.splitlines()
    # Estas dos salen siempre al cerrar con --quit-after y no son un fallo.
    ruido = ("resources still in use at exit", "ObjectDB instances were leaked",
             "at: cleanup (core/object", "at: clear (core/io/resource")
    todas = [l for l in todas if not any(r in l for r in ruido)]
    graves = [l for l in todas if "SCRIPT ERROR" in l or "Parse Error" in l or "ERROR:" in l
              or "Invalid " in l]
    cola = todas[-lineas:] if lineas > 0 else todas
    print("\n".join(cola))
    print("[godot3d] %s en %.1f s, código %d%s; %d líneas, %d con ERROR" % (
        "oculto" if (oculto and h_desk) else "a la vista", seg, codigo.value,
        " (TIEMPO AGOTADO: lo he matado)" if agotado else "", len(todas), len(graves)))
    if graves and lineas > 0 and len(todas) > lineas:
        print("[godot3d] errores que quedan fuera de la cola mostrada:")
        print("\n".join(graves[:30]))
    return codigo.value, texto


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass
    a = sys.argv[1:]
    if not a or a[0] in ("-h", "--help", "ayuda"):
        with open(__file__, encoding="utf-8") as f:
            print(f.read().split("import ctypes")[0])
        return 0
    orden, resto = a[0], a[1:]
    usuario = []
    if "--" in resto:
        i = resto.index("--")
        resto, usuario = resto[:i], resto[i + 1:]
    repo = raiz_del_repo()
    oculto, tiempo, lineas = True, 240.0, 60
    metodo, fotogramas, res, fps = None, None, None, "60"
    libres = []
    i = 0
    while i < len(resto):
        x = resto[i]
        if x == "--visible":
            oculto = False
        elif x in ("--tiempo", "--lineas", "--metodo", "--fotogramas", "--res", "--repo", "--fps"):
            i += 1
            v = resto[i]
            if x == "--tiempo":
                tiempo = float(v)
            elif x == "--lineas":
                lineas = int(v)
            elif x == "--metodo":
                metodo = v
            elif x == "--fotogramas":
                fotogramas = v
            elif x == "--res":
                res = v
            elif x == "--repo":
                repo = v
            elif x == "--fps":
                fps = v
        else:
            libres.append(x)
        i += 1
    base = ["--path", repo]
    if orden == "importar":
        args = base + ["--headless", "--import"]
        oculto = False
        tiempo = max(tiempo, 900.0)
    elif orden == "guion":
        args = base + ["--headless", "--script"] + libres
        oculto = False
    elif orden == "escena":
        args = base + ["--windowed"]
        if res:
            args += ["--resolution", res]
        if metodo == "forward":
            args += ["--rendering-method", "forward_plus"]
        elif metodo == "compat":
            args += ["--rendering-method", "gl_compatibility"]
        if fps and fps != "0":
            args += ["--fixed-fps", fps]
        args += ["--quit-after", str(fotogramas or 600)]
        args += libres
    elif orden == "crudo":
        args = usuario
        usuario = []
    else:
        raise SystemExit("orden desconocida: " + orden)
    if usuario:
        args += ["--"] + usuario
    with Candado():
        codigo, _ = lanzar(args, oculto=oculto, tiempo=tiempo, lineas=lineas)
    return codigo


if __name__ == "__main__":
    sys.exit(main())
