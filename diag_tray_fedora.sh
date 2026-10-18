#!/bin/bash
# ============================================================================
# diag_tray_fedora.sh — Diagnosi PROFONDA del crash del system tray
# ----------------------------------------------------------------------------
# Il log di avvio mostra che l'AppImage muore dentro InitSystemTray, PRIMA
# della riga "SystemTray::set_system_tray_info" (che il plugin stampa quando
# arriva a icona/titolo). Rimangono in ballo, in ordine:
#     1) dlopen("libappindicator3.so.1") / dlsym
#     2) app_indicator_new()
#     3) app_indicator_set_status(ACTIVE)   (registrazione DBus SNI)
#
# Fedora ha sia il libappindicator REALE sul host (libappindicator-gtk3) sia
# la nostra catena bundled (libappindicator3.so.1 -> libayatana-*). Quindi
# eseguiamo DUE probe identici alla sequenza nativa del plugin:
#   PROBE A: con le librerie del SISTEMA  (senza LD_LIBRARY_PATH)
#   PROBE B: con le librerie BUNDLED      (LD_LIBRARY_PATH=<AppDir>/usr/lib)
# Se A crasha e B no (o viceversa) la causa è isolata al 100%.
# Ogni probe gira in un figlio forkato con marker su file (flush) e, se c'è
# gdb, produce la backtrace. Poi avvia l'AppImage reale e registra il segnale.
#
# Uso:  ./diag_tray_fedora.sh [./super-linux-utility-2.1.0-x86_64.AppImage]
# Output: /tmp/slu-tray-diag.log   (mandami questo file)
# ============================================================================

set -u

LOG=/tmp/slu-tray-diag.log
APPIMAGE="${1:-./super-linux-utility-2.1.0-x86_64.AppImage}"

case "$APPIMAGE" in
    /*) ;;
    *) APPIMAGE="$PWD/$APPIMAGE" ;;
esac

# 126 = "Permesso negato": il file AppImage deve avere il bit di esecuzione
if [ ! -x "$APPIMAGE" ]; then
    chmod +x "$APPIMAGE" 2>/dev/null
fi

rm -f "$LOG"

say()  { echo "$@" >> "$LOG"; }
sayr() { echo "$@" | tee -a "$LOG"; }

{
    echo "=== Diagnosi profonda tray — $(date -Is) ==="
    echo "AppImage: $APPIMAGE"
    echo "kernel:   $(uname -a)"
    echo
    echo "--- /etc/os-release ---"
    cat /etc/os-release 2>&1
    echo
    echo "--- sessione/grafica ---"
    env | grep -Ei '^(XDG|WAYLAND|DISPLAY|GDK|DESKTOP)' | sort 2>&1
    echo
    echo "--- pacchetti host del mondo tray ---"
    rpm -q gtk3 libdbusmenu-gtk3 libappindicator-gtk3 libayatana-appindicator-gtk3 \
           plasma-desktop fuse2-libs fuse3 2>&1
    echo
    echo "--- lib appindicator sul host ---"
    ls -l /usr/lib64/libappindicator3.so* /usr/lib64/libayatana-appindicator3.so* \
          /usr/lib64/libdbusmenu-gtk3.so* 2>&1
} >> "$LOG" 2>&1

# ── Probe python: identico alla sequenza del plugin (dlopen->dlsym->new->set) ─
cat > /tmp/slu_probe.py <<'PYEOF'
import ctypes, os, sys, time

MARK = os.environ["PROBE_MARK"]

def mark(msg):
    with open(MARK, "a") as f:
        f.write(msg + "\n")
        f.flush()

def pump(seconds):
    """Pompa il GLib main loop: senza questo le callback ASYNC della
    registrazione DBus (g_bus_own_name -> name_acquired ->
    RegisterStatusNotifierItem verso il watcher di KDE) NON partono mai.
    E' proprio quel codice, eseguito solo col loop attivo, il differenziale
    KDE vs GNOME."""
    try:
        glib = ctypes.CDLL("libglib-2.0.so.0")
    except OSError as e:
        mark("  child: main loop NON pompato (glib irreperibile: %s)" % e)
        return
    glib.g_main_context_default.restype = ctypes.c_void_p
    glib.g_main_context_iteration.argtypes = [ctypes.c_void_p, ctypes.c_int]
    glib.g_main_context_iteration.restype = ctypes.c_int
    glib.g_usleep.argtypes = [ctypes.c_ulong]
    ctx = glib.g_main_context_default()
    end = time.time() + seconds
    n = 0
    while time.time() < end:
        glib.g_main_context_iteration(ctx, 0)   # non bloccante
        glib.g_usleep(20000)                    # 20ms
        n += 1
    mark("  child: main loop pompato %.1fs (%d iter, nessun crash)" % (seconds, n))

def child():
    mark("  child: avviato (pid %d)" % os.getpid())
    mark("  child: dlopen('libappindicator3.so.1')")
    try:
        lib = ctypes.CDLL("libappindicator3.so.1")
    except OSError as e:
        mark("  child: dlopen FALLITO -> %s" % e)
        os._exit(3)
    mark("  child: dlopen OK  (handle %s)" % lib._handle)

    want = ["app_indicator_new", "app_indicator_set_status",
            "app_indicator_set_icon_full", "app_indicator_set_label",
            "app_indicator_get_label", "app_indicator_set_title",
            "app_indicator_set_attention_icon_full", "app_indicator_set_menu"]
    missing = [s for s in want if not hasattr(lib, s)]
    mark("  child: dlsym mancanti -> %s" % (",".join(missing) if missing else "nessuno"))

    # [1b] GTK init: NELL'APP GTK e' gia' inizializzato (display aperto) e
    # app_indicator_new tocca gtk_icon_theme_get_for_screen; senza display il
    # probe fermava l'esecuzione a critiche NULL e NON copriva quel percorso.
    mark("  child: [1b] gtk_init_check (GDK_BACKEND=%s)" % os.environ.get("GDK_BACKEND", "?"))
    try:
        gtk = ctypes.CDLL("libgtk-3.so.0")
    except OSError as e:
        mark("  child: libgtk-3 non caricato -> %s" % e)
        os._exit(4)
    gtk.gtk_init_check.restype = ctypes.c_int
    gtk.gtk_init_check.argtypes = [ctypes.POINTER(ctypes.c_int),
                                   ctypes.POINTER(ctypes.POINTER(ctypes.c_char_p))]
    argc = ctypes.c_int(1)
    argv0 = (ctypes.c_char_p * 1)(b"slu-probe")
    argv = ctypes.cast(argv0, ctypes.POINTER(ctypes.c_char_p))
    gtk_ok = gtk.gtk_init_check(ctypes.byref(argc), ctypes.byref(argv))
    mark("  child: [1b] gtk_init_check -> %d (1=display aperto)" % gtk_ok)

    lib.app_indicator_new.restype = ctypes.c_void_p
    lib.app_indicator_new.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_int]
    mark("  child: [2] app_indicator_new('slu.probe', '', CATEGORY_APPLICATION_STATUS=0)")
    ind = lib.app_indicator_new(b"slu.probe", b"", 0)
    mark("  child: [2] app_indicator_new OK -> %s" % ind)

    lib.app_indicator_set_status.argtypes = [ctypes.c_void_p, ctypes.c_int]
    mark("  child: [3] app_indicator_set_status(ind, ACTIVE=1)")
    lib.app_indicator_set_status(ind, 1)
    mark("  child: [3] set_status OK")

    mark("  child: [3b] pompaggio main loop GLib (callback async DBus/KDE)")
    pump(2.0)

    lib.app_indicator_set_icon_full.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
    mark("  child: [4] app_indicator_set_icon_full(ind, '/tmp/slu-probe.png', 'icon')")
    lib.app_indicator_set_icon_full(ind, b"/tmp/slu-probe.png", b"icon")
    mark("  child: [4] set_icon_full OK")

    lib.app_indicator_set_label.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
    mark("  child: [5] app_indicator_set_label(ind, 'probe', null)")
    lib.app_indicator_set_label(ind, b"probe", None)
    mark("  child: [5] set_label OK")

    # [7] menu + export dbusmenu: l'app dopo InitSystemTray chiama anche
    # CreateContextMenu/SetContextMenu (CreateContextMenu non compare piu'
    # nel log Fedora: il buffering puo' nasconderlo -> il probe lo copre).
    mark("  child: [7] gtk_menu_new + app_indicator_set_menu (export dbusmenu)")
    gtk.gtk_menu_new.restype = ctypes.c_void_p
    menu = gtk.gtk_menu_new()
    mark("  child: [7] gtk_menu_new OK -> %s" % menu)
    if ind and menu:
        lib.app_indicator_set_menu.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
        lib.app_indicator_set_menu(ind, menu)
        mark("  child: [7] set_menu OK")
        mark("  child: [7b] pompaggio main loop (export dbusmenu async)")
        pump(2.0)
        mark("  child: [7b] pump OK")

    mark("  child: [6] pompaggio finale del main loop")
    pump(1.5)
    mark("  child: sequenza nativa COMPLETATA senza crash")
    os._exit(0)

pid = os.fork()
if pid == 0:
    child()
else:
    _, status = os.waitpid(pid, 0)
    if os.WIFSIGNALED(status):
        mark("  PARENT: figlio UCCISO dal segnale %d (%s)"
             % (os.WTERMSIG(status),
                {11: "SIGSEGV", 6: "SIGABRT", 4: "SIGILL", 8: "SIGFPE"}.get(os.WTERMSIG(status), "?")))
    else:
        mark("  PARENT: figlio terminato con exit code %d%s"
             % (os.WEXITSTATUS(status),
                "  <-- 3 = dlopen fallito (libreria irreperibile)" if os.WEXITSTATUS(status) == 3 else ""))
PYEOF

# Icona temporanea per il passo [4]
printf '\x89PNG\r\n\x1a\n' > /tmp/slu-probe.png 2>/dev/null || true

run_probe() {
    local label="$1" ldpath="${2:-}"
    local mark="/tmp/slu-probe-$label.txt"
    rm -f "$mark"

    sayr ""
    sayr "=== PROBE $label: dlopen -> dlsym -> app_indicator_new -> set_status -> set_icon -> set_label ==="
    if [ -n "$ldpath" ]; then
        say "  LD_LIBRARY_PATH=$ldpath"
    else
        say "  (librerie del SISTEMA, niente LD_LIBRARY_PATH)"
    fi

    # LD_LIBRARY_PATH vuoto = elemento "" = cwd in glibc -> meglio unset.
    # GDK_BACKEND=x11 come nell'AppImage (l'hook gtk lo forza anche su Wayland).
    if [ -n "$ldpath" ]; then
        PROBE_MARK="$mark" GDK_BACKEND=x11 LD_LIBRARY_PATH="$ldpath" python3 /tmp/slu_probe.py >> "$LOG" 2>&1
    else
        PROBE_MARK="$mark" GDK_BACKEND=x11 env -u LD_LIBRARY_PATH python3 /tmp/slu_probe.py >> "$LOG" 2>&1
    fi

    if [ -s "$mark" ]; then
        tee -a "$LOG" < "$mark"
    else
        sayr "    (nessun marker: python3 assente o probe non partito)"
    fi

    if command -v gdb >/dev/null 2>&1; then
        sayr "    --- backtrace gdb del probe ---"
        if [ -n "$ldpath" ]; then
            PROBE_MARK="$mark.gdb" GDK_BACKEND=x11 LD_LIBRARY_PATH="$ldpath" gdb -batch \
                -ex "set debuginfod enabled off" -ex "set pagination off" \
                -ex "set follow-fork-mode child" \
                -ex run -ex bt \
                --args python3 /tmp/slu_probe.py >> "$LOG" 2>&1
        else
            PROBE_MARK="$mark.gdb" GDK_BACKEND=x11 env -u LD_LIBRARY_PATH gdb -batch \
                -ex "set debuginfod enabled off" -ex "set pagination off" \
                -ex "set follow-fork-mode child" \
                -ex run -ex bt \
                --args python3 /tmp/slu_probe.py >> "$LOG" 2>&1
        fi
        # ultimo passo raggiunto anche sotto gdb
        [ -s "$mark.gdb" ] && tail -2 "$mark.gdb" | sed 's/^/    [gdb] /' | tee -a "$LOG"
        grep -E "Program received signal|SIGSEGV|SIGABRT" "$LOG" | tail -2 | sed 's/^/    /' | tee -a "$LOG"
        grep -E "^#[0-9]+ " "$LOG" | tail -14 | sed 's/^/    /' | tee -a "$LOG"
    else
        sayr "    (gdb non installato: sudo dnf install -y gdb e rilancia per la backtrace)"
    fi
}

# ── [1] PROBE A: librerie del SISTEMA (Fedora ha il vero libappindicator3) ──
run_probe "A-SISTEMA" ""

# ── [2] PROBE B: librerie BUNDLED dell'AppImage ─────────────────────────────
sayr ""
sayr "=== [2] Preparo le librerie BUNDLED dell'AppImage ==="
WORK="$HOME/.cache/slu-appdir"
rm -rf "$WORK"; mkdir -p "$WORK"
say "--- estrazione (stderr incluso nel log) ---"
( cd "$WORK" && timeout 180 "$APPIMAGE" --appimage-extract ) >> "$LOG" 2>&1
ext_rc=$?
say "rc estrazione: $ext_rc"
APPDIR="$WORK/squashfs-root"
if [ ! -d "$APPDIR/usr/lib" ]; then
    sayr "  Estrazione fallita (rc=$ext_rc) — vedo il motivo nel log:"
    tail -5 "$LOG" | sed 's/^/    /' | tee -a "$LOG"
    sayr "  PROBE B saltato: riprova con più spazio su \$HOME, oppure installa squashfs-tools."
else
    say "AppDir: $APPDIR"
    say "catena bundled presente:"
    ls -l "$APPDIR/usr/lib/"*appindicator* "$APPDIR/usr/lib/"*ayatana* >> "$LOG" 2>&1

    # Stesso ambiente che l'hook linuxdeploy-plugin-gtk esporta per l'AppImage:
    # i cache (immodules/loaders/schemi) puntano alle librerie BUNDLED.
    export APPDIR="$APPDIR"
    export GTK_DATA_PREFIX="$APPDIR"
    export GTK_THEME="${APPIMAGE_GTK_THEME:-Adwaita:light}"
    export GTK_EXE_PREFIX="$APPDIR/usr"
    export GTK_PATH="$APPDIR/usr/lib/gtk-3.0"
    export GTK_IM_MODULE_FILE="$APPDIR/usr/lib/gtk-3.0/3.0.0/immodules.cache"
    export GDK_PIXBUF_MODULE_FILE="$APPDIR/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
    export XDG_DATA_DIRS="$APPDIR/usr/share:/usr/share:${XDG_DATA_DIRS:-}"

    run_probe "B-BUNDLED" "$APPDIR/usr/lib"
fi

# ── [3] AppImage reale: exit code + coredump ────────────────────────────────
sayr ""
sayr "=== [3] Avvio AppImage reale (exit code + coredump) ==="
CACHE="$HOME/.cache/slu-fedora-cache"
rm -rf "$CACHE"; mkdir -p "$CACHE"
rm -f /tmp/slu-lddebug.* /tmp/slu-startup.log
say "  (con LD_DEBUG=libs vedo QUALI file carica davvero il processo, bundled o host)"
LD_DEBUG=libs LD_DEBUG_OUTPUT=/tmp/slu-lddebug \
    XDG_CACHE_HOME="$CACHE" timeout -k 3 25 "$APPIMAGE" >> "$LOG" 2>&1
rc=$?
case "$rc" in
    139) sayr "  AppImage: UCCISO da SIGSEGV (139)  <-- crash nativo confermato" ;;
    134) sayr "  AppImage: UCCISO da SIGABRT (134)  <-- assertion/abort" ;;
    137) sayr "  AppImage: ucciso dal timeout (137) = NON è crashato in 25s" ;;
    0)   sayr "  AppImage: exit code 0 (chiusura pulita)" ;;
    *)   sayr "  AppImage: exit code $rc" ;;
esac
say "exit code AppImage: $rc"
say ""
say "--- lib appindicator/ayatana/dbusmenu caricate DAL PROCESSO (bundled vs host) ---"
if ls /tmp/slu-lddebug.* >/dev/null 2>&1; then
    grep -h -E "find library=lib(appindicator3|ayatana|dbusmenu)|trying file=.*lib(appindicator3|ayatana|dbusmenu)|calling init: .*lib(appindicator3|ayatana|dbusmenu)" \
        /tmp/slu-lddebug.* 2>/dev/null | sort -u | head -40 >> "$LOG"
    grep -h -E "calling init: .*lib(appindicator3|ayatana|dbusmenu)" \
        /tmp/slu-lddebug.* 2>/dev/null | sort -u | head -12 | sed 's/^/  /' | tee -a "$LOG"
    say "(file completi in /tmp/slu-lddebug.*)"
else
    say "(LD_DEBUG non ha prodotto file)"
fi
say ""
say "--- ultime righe del log di avvio dell'app (/tmp/slu-startup.log) ---"
tail -6 /tmp/slu-startup.log >> "$LOG" 2>&1

if command -v coredumpctl >/dev/null 2>&1; then
    say "--- coredump SOLO di questa app (segnale + stack) ---"
    coredumpctl info super_linux_utility --no-pager 2>&1 | head -70 >> "$LOG"
    if ! grep -q "super_linux_utility" "$LOG"; then
        say "(nessun coredump per super_linux_utility)"
    fi
else
    say "--- coredumpctl assente: journalctl ---"
    journalctl -k -n 40 --no-pager 2>&1 | grep -Ei 'segfault|traps|super_linux' | tail -12 >> "$LOG"
fi

echo
echo "=== FATTI — mandami il contenuto di: $LOG ==="
echo
grep -E "PROBE |child: \[|child: main loop|PARENT:|AppImage:|PROBE B saltato|Program received|^#[0-9]+ |calling init: .*(ayatana|appindicator|dbusmenu)" "$LOG" | tail -45
