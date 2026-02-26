#!/bin/bash
# Script per installare le icone dell'app in tutte le directory standard
# Supporta GNOME, KDE e altri Desktop Environment

APP_NAME="super-linux-utility"
ICON_NAME="super-linux-utility"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/linux/runner/assets"

# Verifica che le icone esistano
if [ ! -d "$ASSETS_DIR" ]; then
    echo "Errore: Directory assets non trovata: $ASSETS_DIR"
    exit 1
fi

# Funzione per installare icone in una directory
install_icons_in_dir() {
    local target_dir=$1
    local size=$2
    
    if [ -z "$size" ]; then
        # Installa tutte le dimensioni
        mkdir -p "$target_dir"
        for size in 16 24 32 48 64 128 256 512; do
            if [ -f "$ASSETS_DIR/icon_${size}.png" ]; then
                install -Dm644 "$ASSETS_DIR/icon_${size}.png" "$target_dir/${ICON_NAME}.png"
                # Crea anche un link simbolico per compatibilità
                ln -sf "${ICON_NAME}.png" "$target_dir/${ICON_NAME}_${size}.png" 2>/dev/null || true
            fi
        done
    else
        # Installa una dimensione specifica
        mkdir -p "$target_dir"
        if [ -f "$ASSETS_DIR/icon_${size}.png" ]; then
            install -Dm644 "$ASSETS_DIR/icon_${size}.png" "$target_dir/${ICON_NAME}.png"
        fi
    fi
}

# Verifica se siamo root
if [ "$EUID" -ne 0 ]; then 
    echo "Questo script richiede privilegi di root per installare le icone di sistema."
    echo "Eseguendo con sudo..."
    exec sudo "$0" "$@"
fi

echo "Installazione icone per $APP_NAME..."

# 1. Installa nelle directory hicolor (standard XDG - funziona con tutti i DE)
echo "Installazione in /usr/share/icons/hicolor/..."
for size in 16x16 24x24 32x32 48x48 64x64 128x128 256x256 512x512; do
    size_num=${size%x*}
    target_dir="/usr/share/icons/hicolor/${size}/apps"
    if [ -f "$ASSETS_DIR/icon_${size_num}.png" ]; then
        mkdir -p "$target_dir"
        install -m644 "$ASSETS_DIR/icon_${size_num}.png" "$target_dir/${ICON_NAME}.png"
    fi
done


# 2. Installa in /usr/share/pixmaps (legacy, per compatibilità)
echo "Installazione in /usr/share/pixmaps/..."
if [ -f "$ASSETS_DIR/icon_48.png" ]; then
    install -m644 "$ASSETS_DIR/icon_48.png" "/usr/share/pixmaps/${ICON_NAME}.png"
fi

# 3. Aggiorna la cache delle icone per GNOME
if command -v gtk-update-icon-cache &> /dev/null; then
    echo "Aggiornamento cache icone GTK..."
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
fi

# 4. Aggiorna la cache delle icone per KDE
if command -v kbuildsycoca4 &> /dev/null; then
    echo "Aggiornamento cache icone KDE 4..."
    kbuildsycoca4 2>/dev/null || true
fi

if command -v kbuildsycoca5 &> /dev/null; then
    echo "Aggiornamento cache icone KDE 5..."
    kbuildsycoca5 2>/dev/null || true
fi

# 5. Aggiorna la cache delle icone per KDE 6 (Plasma 6)
if command -v kbuildsycoca6 &> /dev/null; then
    echo "Aggiornamento cache icone KDE 6..."
    kbuildsycoca6 2>/dev/null || true
fi

echo "Icone installate con successo!"
echo "Le icone sono disponibili per:"
echo "  - GNOME (e derivate)"
echo "  - KDE Plasma"
echo "  - XFCE"
echo "  - Altri Desktop Environment compatibili con XDG"

