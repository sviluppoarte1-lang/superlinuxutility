#!/bin/bash

# Script per generare i pacchetti Arch Linux (.pkg.tar.zst) di Super Linux Utility
# Supporta: Arch Linux, CachyOS, EndeavourOS, Manjaro, Garuda, e derivate
# Produce tre pacchetti: standard (gratuito), advanced (a pagamento), personal (test/dev)

set -e

BINARY_NAME="super_linux_utility"
APP_VERSION="2.1.0"
BUILD_DIR="build/linux/x64/release/bundle"
PKG_BASE="pkg_arch"

# Dipendenze runtime per Arch Linux
ARCH_DEPS="gtk3 glib2 libayatana-appindicator"

echo "🔨 Building Super Linux Utility for Arch Linux (standard + advanced + personal)..."

# Verifica dipendenze build
for cmd in flutter makepkg; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ $cmd not found. Install it first."
        if [ "$cmd" = "makepkg" ]; then
            echo "   sudo pacman -S --needed base-devel"
        fi
        exit 1
    fi
done

# Pulisci build precedenti
flutter clean

# Genera le icone PNG in varie dimensioni dal PNG base
if [ -f "assets/icons/icon.png" ]; then
    echo "🎨 Generating icons from PNG base..."
    mkdir -p linux/runner/assets

    if command -v convert >/dev/null 2>&1; then
        for size in 16 24 32 48 64 128 256 512; do
            convert "assets/icons/icon.png" -resize ${size}x${size} -colorspace sRGB -type TrueColorAlpha -alpha on "linux/runner/assets/icon_${size}.png"
        done
        echo "✅ Icons generated successfully in all sizes"
    else
        echo "⚠️  ImageMagick not found, copying base PNG only"
        cp "assets/icons/icon.png" "linux/runner/assets/icon_512.png"
    fi
else
    echo "❌ Error: assets/icons/icon.png not found"
    exit 1
fi

# Funzione per creare il pacchetto Arch
build_variant() {
    local variant="$1"       # standard, advanced, personal
    local pkg_name="$2"      # nome pacchetto
    local dart_define="$3"   # valore APP_BUILD
    local description="$4"

    echo ""
    echo "📦 Building $variant version..."
    flutter build linux --release --dart-define=APP_BUILD="$dart_define"

    local pkg_dir="${PKG_BASE}_${variant}"
    rm -rf "$pkg_dir"
    mkdir -p "$pkg_dir/usr/bin"
    mkdir -p "$pkg_dir/usr/share/applications"
    mkdir -p "$pkg_dir/usr/share/pixmaps"
    mkdir -p "$pkg_dir/usr/share/$pkg_name"
    mkdir -p "$pkg_dir/usr/share/$pkg_name/assets"
    mkdir -p "$pkg_dir/usr/share/icons/hicolor"

    # Copia binari e bundle
    cp -r "$BUILD_DIR/"* "$pkg_dir/usr/share/$pkg_name/"

    # Wrapper script
    cat > "$pkg_dir/usr/bin/$pkg_name" << WRAPPER
#!/bin/bash
exec /usr/share/$pkg_name/super_linux_utility "\$@"
WRAPPER
    chmod +x "$pkg_dir/usr/bin/$pkg_name"

    # Desktop file
    cat > "$pkg_dir/usr/share/applications/$pkg_name.desktop" << DESKTOP
[Desktop Entry]
Name=Super Linux Utility
Comment=$description
Exec=/usr/bin/$pkg_name
Icon=$pkg_name
Terminal=false
Type=Application
Categories=System;Monitor;Utility;
DESKTOP

    # Icona
    cp "assets/icons/icon.png" "$pkg_dir/usr/share/pixmaps/$pkg_name.png"

    # Copia icone in hicolor
    for size in 16 24 32 48 64 128 256 512; do
        local icon_dir="$pkg_dir/usr/share/icons/hicolor/${size}x${size}/apps"
        mkdir -p "$icon_dir"
        if [ -f "linux/runner/assets/icon_${size}.png" ]; then
            cp "linux/runner/assets/icon_${size}.png" "$icon_dir/$pkg_name.png"
        fi
    done

    # Crea .PKGINFO per makepkg
    local depends=""
    for dep in $ARCH_DEPS; do
        depends="$depends depends = $dep"
    done

    echo "PKGNAME = $pkg_name" > "$pkg_dir/.PKGINFO"
    echo "PKGVER = $APP_VERSION" >> "$pkg_dir/.PKGINFO"
    echo "PKGDESC = $description" >> "$pkg_dir/.PKGINFO"
    echo "URL = https://github.com/sviluppoarte1-lang/superlinuxutility" >> "$pkg_dir/.PKGINFO"
    echo "BUILDDATE = $(date +%s)" >> "$pkg_dir/.PKGINFO"
    echo "MAKEDEPENDS = flutter" >> "$pkg_dir/.PKGINFO"
    echo "MAKEDEPENDS = cmake" >> "$pkg_dir/.PKGINFO"
    echo "MAKEDEPENDS = ninja" >> "$pkg_dir/.PKGINFO"
    echo "MAKEDEPENDS = clang" >> "$pkg_dir/.PKGINFO"
    echo "MAKEDEPENDS = pkg-config" >> "$pkg_dir/.PKGINFO"
    echo "MAKEDEPENDS = gtk3" >> "$pkg_dir/.PKGINFO"
    echo "MAKEDEPENDS = pcre2" >> "$pkg_dir/.PKGINFO"
    for dep in $ARCH_DEPS; do
        echo "DEPENDS = $dep" >> "$pkg_dir/.PKGINFO"
    done
    echo "ARCH = x86_64" >> "$pkg_dir/.PKGINFO"
    echo "LICENSE = GPL-3.0-or-later" >> "$pkg_dir/.PKGINFO"

    # Crea pacchetto con tar (makepkg-style)
    local pkg_file="${pkg_name}-${APP_VERSION}-1-x86_64.pkg.tar.zst"
    (cd "$pkg_dir" && tar --zstd -cf "../$pkg_file" .PKGINFO . 2>/dev/null)
    echo "✅ Package: $pkg_file ($(du -h "../$pkg_file" | cut -f1))"
}

# Build tutte le varianti
build_variant "standard" "super-linux-utility" "standard" "Super Linux Utility - System management tool"
build_variant "advanced" "super-linux-utility-advanced" "advanced" "Super Linux Utility Advanced - Enhanced system management"
build_variant "personal" "super-linux-utility-personal" "personal" "Super Linux Utility Personal - Dev/Test build"

echo ""
echo "🎉 All Arch Linux packages built successfully!"
echo ""
echo "To install (e.g. standard):"
echo "  sudo pacman -U ${PKG_BASE}_standard/super-linux-utility-${APP_VERSION}-1-x86_64.pkg.tar.zst"
echo ""
echo "To publish to AUR, copy the PKGBUILD and run: makepkg -si"
