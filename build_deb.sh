#!/bin/bash

# Script per generare i pacchetti .deb di Super Linux Utility
# Produce due .deb: versione standard (gratuita) e versione avanzata (a pagamento)

set -e

BINARY_NAME="super_linux_utility"
APP_VERSION="1.8.6"
DEB_BASE="deb_package"
BUILD_DIR="build/linux/x64/release/bundle"

echo "🔨 Building Super Linux Utility (standard + advanced + personal)..."

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

# --- Build e pacchetto STANDARD (gratuito) ---
echo ""
echo "📦 Building STANDARD version (free)..."
flutter build linux --release --dart-define=APP_BUILD=standard

APP_NAME="super-linux-utility"
DEB_DIR="${DEB_BASE}_standard"
rm -rf "$DEB_DIR"
mkdir -p $DEB_DIR/DEBIAN
mkdir -p $DEB_DIR/usr/bin
mkdir -p $DEB_DIR/usr/share/applications
mkdir -p $DEB_DIR/usr/share/pixmaps
mkdir -p $DEB_DIR/usr/share/$APP_NAME
mkdir -p $DEB_DIR/usr/share/$APP_NAME/assets
for size in 16x16 24x24 32x32 48x48 64x64 128x128 256x256 512x512 scalable; do
    mkdir -p $DEB_DIR/usr/share/icons/hicolor/${size}/apps
done

cat > $DEB_DIR/DEBIAN/control << EOF
Package: $APP_NAME
Version: $APP_VERSION
Section: utils
Priority: optional
Architecture: amd64
Depends: libgtk-3-0, libglib2.0-0, libc6, libayatana-appindicator3-1
Maintainer: Marco Di Giangiacomo
License: GPL-3.0+
Homepage: https://github.com/marcodigiangiacomo/super-linux-utility
Description: Super Linux Utility - Versione standard (gratuita)
 Applicazione per la gestione del sistema Linux: servizi systemd, applicazioni
 all'avvio, pulizia file temporanei, app installate (APT, Snap, Flatpak),
 monitoraggio risorse, analisi disco. Senza funzioni avanzate (GRUB, Kernel, Recovery).
 .
 Questo software è distribuito sotto licenza GPL-3.0 o successiva.
EOF

cp -r $BUILD_DIR/* $DEB_DIR/usr/share/$APP_NAME/

cat > $DEB_DIR/usr/bin/$APP_NAME << WRAPPER_EOF
#!/bin/bash
APP_DIR="/usr/share/$APP_NAME"
EXECUTABLE="\$APP_DIR/$BINARY_NAME"
if [ ! -d "\$APP_DIR" ]; then echo "Error: Application directory not found: \$APP_DIR" >&2; exit 1; fi
if [ ! -f "\$EXECUTABLE" ]; then echo "Error: Executable not found: \$EXECUTABLE" >&2; exit 1; fi
cd "\$APP_DIR" || exit 1
exec "\$EXECUTABLE" "\$@"
WRAPPER_EOF
chmod +x $DEB_DIR/usr/bin/$APP_NAME

cat > $DEB_DIR/usr/share/applications/$APP_NAME.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Super Linux Utility
Comment=Gestione sistema Linux - Versione standard (gratuita)
Exec=$APP_NAME
Icon=$APP_NAME
Terminal=false
Categories=System;Utility;
StartupNotify=true
EOF
chmod 644 $DEB_DIR/usr/share/applications/$APP_NAME.desktop

if [ -d "linux/runner/assets" ]; then
    for size in 16 24 32 48 64 128 256 512; do
        [ -f "linux/runner/assets/icon_${size}.png" ] && cp "linux/runner/assets/icon_${size}.png" $DEB_DIR/usr/share/icons/hicolor/${size}x${size}/apps/$APP_NAME.png
    done
    [ -f "linux/runner/assets/icon_48.png" ] && cp "linux/runner/assets/icon_48.png" $DEB_DIR/usr/share/pixmaps/$APP_NAME.png
    cp linux/runner/assets/*.png $DEB_DIR/usr/share/$APP_NAME/assets/ 2>/dev/null || true
fi

cat > $DEB_DIR/DEBIAN/postinst << 'POSTEOF'
#!/bin/bash
set -e
[ -x /usr/bin/update-desktop-database ] && update-desktop-database -q /usr/share/applications 2>/dev/null || true
[ -x /usr/bin/update-icon-caches ] && update-icon-caches /usr/share/pixmaps 2>/dev/null || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
exit 0
POSTEOF
chmod +x $DEB_DIR/DEBIAN/postinst

cat > $DEB_DIR/DEBIAN/postrm << 'POSTEOF'
#!/bin/bash
set -e
[ -x /usr/bin/update-desktop-database ] && update-desktop-database -q /usr/share/applications 2>/dev/null || true
exit 0
POSTEOF
chmod +x $DEB_DIR/DEBIAN/postrm

[ -f "/usr/share/common-licenses/GPL-3" ] && mkdir -p $DEB_DIR/usr/share/doc/$APP_NAME && cp /usr/share/common-licenses/GPL-3 $DEB_DIR/usr/share/doc/$APP_NAME/copyright

dpkg-deb --build $DEB_DIR ${APP_NAME}_${APP_VERSION}_amd64.deb
echo "✅ Standard DEB: ${APP_NAME}_${APP_VERSION}_amd64.deb ($(du -h ${APP_NAME}_${APP_VERSION}_amd64.deb | cut -f1))"

# --- Build e pacchetto ADVANCED (a pagamento) ---
echo ""
echo "📦 Building ADVANCED version (paid)..."
flutter build linux --release --dart-define=APP_BUILD=advanced

APP_NAME="super-linux-utility-advanced"
DEB_DIR="${DEB_BASE}_advanced"
rm -rf "$DEB_DIR"
mkdir -p $DEB_DIR/DEBIAN
mkdir -p $DEB_DIR/usr/bin
mkdir -p $DEB_DIR/usr/share/applications
mkdir -p $DEB_DIR/usr/share/pixmaps
mkdir -p $DEB_DIR/usr/share/$APP_NAME
mkdir -p $DEB_DIR/usr/share/$APP_NAME/assets
for size in 16x16 24x24 32x32 48x48 64x64 128x128 256x256 512x512 scalable; do
    mkdir -p $DEB_DIR/usr/share/icons/hicolor/${size}/apps
done

cat > $DEB_DIR/DEBIAN/control << EOF
Package: $APP_NAME
Version: $APP_VERSION
Section: utils
Priority: optional
Architecture: amd64
Depends: libgtk-3-0, libglib2.0-0, libc6, libayatana-appindicator3-1
Maintainer: Marco Di Giangiacomo
License: GPL-3.0+
Homepage: https://github.com/marcodigiangiacomo/super-linux-utility
Description: Super Linux Utility - Versione avanzata (a pagamento)
 Versione completa con GRUB Editor, gestione Kernel e System Recovery.
 Richiede attivazione licenza. Include tutte le funzioni della versione standard
 più strumenti avanzati per utenti esperti.
 .
 Questo software è distribuito sotto licenza GPL-3.0 o successiva.
EOF

cp -r $BUILD_DIR/* $DEB_DIR/usr/share/$APP_NAME/

cat > $DEB_DIR/usr/bin/$APP_NAME << WRAPPER_EOF
#!/bin/bash
APP_DIR="/usr/share/$APP_NAME"
EXECUTABLE="\$APP_DIR/$BINARY_NAME"
if [ ! -d "\$APP_DIR" ]; then echo "Error: Application directory not found: \$APP_DIR" >&2; exit 1; fi
if [ ! -f "\$EXECUTABLE" ]; then echo "Error: Executable not found: \$EXECUTABLE" >&2; exit 1; fi
cd "\$APP_DIR" || exit 1
exec "\$EXECUTABLE" "\$@"
WRAPPER_EOF
chmod +x $DEB_DIR/usr/bin/$APP_NAME

cat > $DEB_DIR/usr/share/applications/$APP_NAME.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Super Linux Utility (Advanced)
Comment=Gestione sistema Linux - Versione avanzata (GRUB, Kernel, Recovery)
Exec=$APP_NAME
Icon=$APP_NAME
Terminal=false
Categories=System;Utility;
StartupNotify=true
EOF
chmod 644 $DEB_DIR/usr/share/applications/$APP_NAME.desktop

if [ -d "linux/runner/assets" ]; then
    for size in 16 24 32 48 64 128 256 512; do
        [ -f "linux/runner/assets/icon_${size}.png" ] && cp "linux/runner/assets/icon_${size}.png" $DEB_DIR/usr/share/icons/hicolor/${size}x${size}/apps/$APP_NAME.png
    done
    [ -f "linux/runner/assets/icon_48.png" ] && cp "linux/runner/assets/icon_48.png" $DEB_DIR/usr/share/pixmaps/$APP_NAME.png
    cp linux/runner/assets/*.png $DEB_DIR/usr/share/$APP_NAME/assets/ 2>/dev/null || true
fi

cat > $DEB_DIR/DEBIAN/postinst << 'POSTEOF'
#!/bin/bash
set -e
[ -x /usr/bin/update-desktop-database ] && update-desktop-database -q /usr/share/applications 2>/dev/null || true
[ -x /usr/bin/update-icon-caches ] && update-icon-caches /usr/share/pixmaps 2>/dev/null || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
exit 0
POSTEOF
chmod +x $DEB_DIR/DEBIAN/postinst

cat > $DEB_DIR/DEBIAN/postrm << 'POSTEOF'
#!/bin/bash
set -e
[ -x /usr/bin/update-desktop-database ] && update-desktop-database -q /usr/share/applications 2>/dev/null || true
exit 0
POSTEOF
chmod +x $DEB_DIR/DEBIAN/postrm

[ -f "/usr/share/common-licenses/GPL-3" ] && mkdir -p $DEB_DIR/usr/share/doc/$APP_NAME && cp /usr/share/common-licenses/GPL-3 $DEB_DIR/usr/share/doc/$APP_NAME/copyright

dpkg-deb --build $DEB_DIR ${APP_NAME}_${APP_VERSION}_amd64.deb
echo "✅ Advanced DEB: ${APP_NAME}_${APP_VERSION}_amd64.deb ($(du -h ${APP_NAME}_${APP_VERSION}_amd64.deb | cut -f1))"

# --- Build e pacchetto PERSONAL (test/dev, no license) ---
echo ""
echo "📦 Building PERSONAL version (test, no license)..."
flutter build linux --release --dart-define=APP_BUILD=personal

APP_NAME="super-linux-utility-personal"
DEB_DIR="${DEB_BASE}_personal"
rm -rf "$DEB_DIR"
mkdir -p $DEB_DIR/DEBIAN
mkdir -p $DEB_DIR/usr/bin
mkdir -p $DEB_DIR/usr/share/applications
mkdir -p $DEB_DIR/usr/share/pixmaps
mkdir -p $DEB_DIR/usr/share/$APP_NAME
mkdir -p $DEB_DIR/usr/share/$APP_NAME/assets
for size in 16x16 24x24 32x32 48x48 64x64 128x128 256x256 512x512 scalable; do
    mkdir -p $DEB_DIR/usr/share/icons/hicolor/${size}/apps
done

cat > $DEB_DIR/DEBIAN/control << EOF
Package: $APP_NAME
Version: $APP_VERSION
Section: utils
Priority: optional
Architecture: amd64
Depends: libgtk-3-0, libglib2.0-0, libc6, libayatana-appindicator3-1
Maintainer: Marco Di Giangiacomo
License: GPL-3.0+
Homepage: https://github.com/marcodigiangiacomo/super-linux-utility
Description: Super Linux Utility - Versione personale (test)
 Versione completa per uso personale/test: stesse funzioni della versione
 avanzata senza richiesta di licenza. Non per distribuzione.
 .
 Questo software è distribuito sotto licenza GPL-3.0 o successiva.
EOF

cp -r $BUILD_DIR/* $DEB_DIR/usr/share/$APP_NAME/

cat > $DEB_DIR/usr/bin/$APP_NAME << WRAPPER_EOF
#!/bin/bash
APP_DIR="/usr/share/$APP_NAME"
EXECUTABLE="\$APP_DIR/$BINARY_NAME"
if [ ! -d "\$APP_DIR" ]; then echo "Error: Application directory not found: \$APP_DIR" >&2; exit 1; fi
if [ ! -f "\$EXECUTABLE" ]; then echo "Error: Executable not found: \$EXECUTABLE" >&2; exit 1; fi
cd "\$APP_DIR" || exit 1
exec "\$EXECUTABLE" "\$@"
WRAPPER_EOF
chmod +x $DEB_DIR/usr/bin/$APP_NAME

cat > $DEB_DIR/usr/share/applications/$APP_NAME.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Super Linux Utility (Personal)
Comment=Gestione sistema Linux - Versione personale/test (GRUB, Kernel, Recovery)
Exec=$APP_NAME
Icon=$APP_NAME
Terminal=false
Categories=System;Utility;
StartupNotify=true
EOF
chmod 644 $DEB_DIR/usr/share/applications/$APP_NAME.desktop

if [ -d "linux/runner/assets" ]; then
    for size in 16 24 32 48 64 128 256 512; do
        [ -f "linux/runner/assets/icon_${size}.png" ] && cp "linux/runner/assets/icon_${size}.png" $DEB_DIR/usr/share/icons/hicolor/${size}x${size}/apps/$APP_NAME.png
    done
    [ -f "linux/runner/assets/icon_48.png" ] && cp "linux/runner/assets/icon_48.png" $DEB_DIR/usr/share/pixmaps/$APP_NAME.png
    cp linux/runner/assets/*.png $DEB_DIR/usr/share/$APP_NAME/assets/ 2>/dev/null || true
fi

cat > $DEB_DIR/DEBIAN/postinst << 'POSTEOF'
#!/bin/bash
set -e
[ -x /usr/bin/update-desktop-database ] && update-desktop-database -q /usr/share/applications 2>/dev/null || true
[ -x /usr/bin/update-icon-caches ] && update-icon-caches /usr/share/pixmaps 2>/dev/null || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
exit 0
POSTEOF
chmod +x $DEB_DIR/DEBIAN/postinst

cat > $DEB_DIR/DEBIAN/postrm << 'POSTEOF'
#!/bin/bash
set -e
[ -x /usr/bin/update-desktop-database ] && update-desktop-database -q /usr/share/applications 2>/dev/null || true
exit 0
POSTEOF
chmod +x $DEB_DIR/DEBIAN/postrm

[ -f "/usr/share/common-licenses/GPL-3" ] && mkdir -p $DEB_DIR/usr/share/doc/$APP_NAME && cp /usr/share/common-licenses/GPL-3 $DEB_DIR/usr/share/doc/$APP_NAME/copyright

dpkg-deb --build $DEB_DIR ${APP_NAME}_${APP_VERSION}_amd64.deb
echo "✅ Personal DEB: ${APP_NAME}_${APP_VERSION}_amd64.deb ($(du -h ${APP_NAME}_${APP_VERSION}_amd64.deb | cut -f1))"

echo ""
echo "✅ Done. Three packages created:"
echo "   - super-linux-utility_${APP_VERSION}_amd64.deb (standard, free)"
echo "   - super-linux-utility-advanced_${APP_VERSION}_amd64.deb (advanced, paid)"
echo "   - super-linux-utility-personal_${APP_VERSION}_amd64.deb (personal, test)"
