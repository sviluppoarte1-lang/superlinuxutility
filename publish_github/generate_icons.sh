#!/bin/bash
# Script per generare icone PNG di alta qualità da SVG usando ImageMagick

set -e

ASSETS_DIR="linux/runner/assets"
SVG_FILE="$ASSETS_DIR/icon.svg"

if [ ! -f "$SVG_FILE" ]; then
    echo "Errore: File SVG non trovato: $SVG_FILE"
    exit 1
fi

echo "Generazione icone PNG da SVG..."

# Funzione per generare icona PNG con alta qualità
generate_icon() {
    local size=$1
    local output="$ASSETS_DIR/icon_${size}.png"
    
    echo "Generando icona ${size}x${size}..."
    
    if command -v inkscape >/dev/null 2>&1; then
        inkscape \
            --export-type=png \
            --export-filename="$output" \
            --export-width="$size" \
            --export-height="$size" \
            --export-background-opacity=0 \
            "$SVG_FILE"
    elif command -v rsvg-convert >/dev/null 2>&1; then
        rsvg-convert \
            --width="$size" \
            --height="$size" \
            --format=png \
            --keep-aspect-ratio \
            --output="$output" \
            "$SVG_FILE"
    else
        echo "Errore: Nessun tool disponibile (inkscape o rsvg-convert richiesti)"
        return 1
    fi
    
    # Verifica che il file sia stato creato
    if [ -f "$output" ]; then
        echo "  ✓ Creata: $output ($(du -h "$output" | cut -f1))"
    else
        echo "  ✗ Errore nella creazione di $output"
        return 1
    fi
}

# Genera tutte le dimensioni standard
for size in 16 24 32 48 64 128 256 512; do
    generate_icon $size
done

echo ""
echo "✓ Tutte le icone sono state generate con successo!"
echo ""
echo "File generati:"
ls -lh "$ASSETS_DIR"/icon_*.png

