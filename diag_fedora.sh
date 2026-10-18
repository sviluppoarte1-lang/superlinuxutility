#!/bin/bash
# ============================================================================
# diag_fedora.sh — Diagnosi AppImage su Fedora (o qualsiasi altra distro)
# ----------------------------------------------------------------------------
# Avvia l'AppImage catturando TUTTO (stdout + stderr + debug GTK/GLib) e
# raccoglie il contesto di sistema. Serve a capire dove muore l'app quando
# non parte (crash al volo, tray assente, finestra invisibile...).
#
# Uso:
#   ./diag_fedora.sh                          # cerca ./*-x86_64.AppImage
#   ./diag_fedora.sh /percorso/app.AppImage
#
# Output:
#   /tmp/slu-fedora-diag.log   — questo script (env, lib, output dell'AppImage)
#   /tmp/slu-startup.log       — log di avvio scritto dall'app stessa
# ============================================================================

set -u

APPIMAGE="${1:-}"
if [ -z "$APPIMAGE" ]; then
    APPIMAGE=$(ls -1 ./*-x86_64.AppImage 2>/dev/null | head -1)
fi
if [ -z "$APPIMAGE" ] || [ ! -f "$APPIMAGE" ]; then
    echo "Uso: $0 /percorso/super-linux-utility-2.1.0-x86_64.AppImage"
    exit 1
fi
chmod +x "$APPIMAGE" 2>/dev/null || true

LOG=/tmp/slu-fedora-diag.log
rm -f "$LOG" /tmp/slu-startup.log

{
    echo "=== Diagnosi Super Linux Utility — $(date -Is) ==="
    echo "AppImage: $APPIMAGE ($(du -h "$APPIMAGE" | cut -f1))"
    echo "kernel:   $(uname -a)"
    echo
    echo "--- /etc/os-release ---"
    cat /etc/os-release 2>&1
    echo
    echo "--- sessione/grafica ---"
    env | grep -Ei '^(XDG|WAYLAND|DISPLAY|GDK|DESKTOP|QT_|XAUTH)' | sort 2>&1
    echo
    echo "--- librerie grafiche HOST (servono solo se non bundled) ---"
    (ldconfig -p 2>/dev/null || /sbin/ldconfig -p 2>/dev/null) \
        | grep -E 'libgtk-3|libglib-2.0|libayatana|libappindicator|libstdc\+\+|libepoxy' 2>&1
    echo
    echo "--- fuse (richiesto dagli AppImage classici) ---"
    command -v fusermount fusermount3 2>&1
    ls -l /dev/fuse 2>&1
    echo
    echo "--- esecuzione AppImage (stdout + stderr) ---"
} > "$LOG" 2>&1

echo "Log:      $LOG"
echo "Log app:  /tmp/slu-startup.log"
echo "Avvio AppImage... (chiudi l'app, oppure CTRL+C, per terminare)"

# G_MESSAGES_DEBUG=all espone i debug GTK/GLib; warning e critical finiscono
# su stderr in ogni caso (la pipe 2>&1 li cattura).
G_MESSAGES_DEBUG=all "$APPIMAGE" 2>&1 | tee -a "$LOG"

echo
echo "=== terminato — log in $LOG e /tmp/slu-startup.log ==="
