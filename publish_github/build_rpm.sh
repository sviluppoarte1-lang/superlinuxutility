#!/bin/bash

# Script per generare il pacchetto .rpm di Super Linux Utility per Fedora

set -e

APP_NAME="super-linux-utility"
BINARY_NAME="super_linux_utility"
APP_VERSION="1.8.6"
APP_RELEASE="1"
BUILD_DIR="build/linux/x64/release/bundle"
RPMBUILD_DIR="$HOME/rpmbuild"
SPEC_FILE="$RPMBUILD_DIR/SPECS/${APP_NAME}.spec"
SOURCE_DIR="$RPMBUILD_DIR/SOURCES/${APP_NAME}-${APP_VERSION}"

echo "🔨 Building Super Linux Utility..."

# Verifica che rpmbuild sia installato
if ! command -v rpmbuild >/dev/null 2>&1; then
    echo "❌ Error: rpmbuild is not installed. Please install it with:"
    echo "   sudo dnf install rpm-build rpmdevtools"
    exit 1
fi

# Crea la struttura di directory per rpmbuild se non esiste
mkdir -p $RPMBUILD_DIR/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Pulisci build precedenti
echo "🧹 Cleaning previous builds..."
flutter clean

# Compila l'applicazione
echo "📦 Building Flutter application..."
flutter build linux --release

if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ Error: Build directory not found: $BUILD_DIR"
    exit 1
fi

echo "📦 Creating RPM package structure..."

# Pulisci directory sorgente precedente
rm -rf $SOURCE_DIR
mkdir -p $SOURCE_DIR

# Copia tutti i file della bundle nella directory sorgente
cp -r $BUILD_DIR/* $SOURCE_DIR/

# Crea lo script wrapper
cat > $SOURCE_DIR/${APP_NAME}.sh << 'WRAPPER_EOF'
#!/bin/bash
# Wrapper script per Super Linux Utility
APP_DIR="/usr/share/super-linux-utility"
EXECUTABLE="$APP_DIR/super_linux_utility"

# Verifica che la directory e l'eseguibile esistano
if [ ! -d "$APP_DIR" ]; then
    echo "Error: Application directory not found: $APP_DIR" >&2
    exit 1
fi

if [ ! -f "$EXECUTABLE" ]; then
    echo "Error: Executable not found: $EXECUTABLE" >&2
    exit 1
fi

# Cambia alla directory dell'app e esegui
cd "$APP_DIR" || exit 1
exec "$EXECUTABLE" "$@"
WRAPPER_EOF
chmod +x $SOURCE_DIR/${APP_NAME}.sh

# Crea il desktop file
cat > $SOURCE_DIR/${APP_NAME}.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Super Linux Utility
Comment=Super Linux Utility è un'applicazione completa per la gestione avanzata del sistema Linux. Offre strumenti potenti per ottimizzare le prestazioni, gestire servizi, applicazioni e personalizzare l'aspetto del sistema.
Exec=super-linux-utility
Icon=super-linux-utility
Terminal=false
Categories=System;Utility;
StartupNotify=true
NoDisplay=false
DESKTOP_EOF

# Copia l'icona se disponibile
if [ -f "linux/runner/assets/icon_512.png" ]; then
    cp linux/runner/assets/icon_512.png $SOURCE_DIR/${APP_NAME}.png
elif [ -f "assets/icon.svg" ]; then
    # Converti SVG in PNG se disponibile
    if command -v convert >/dev/null 2>&1; then
        convert -background none assets/icon.svg -resize 512x512 $SOURCE_DIR/${APP_NAME}.png 2>/dev/null || true
    fi
fi

# Crea il file SPEC per RPM
cat > $SPEC_FILE << SPEC_EOF
%define appname ${APP_NAME}
%define binaryname ${BINARY_NAME}
%define version ${APP_VERSION}
%define release ${APP_RELEASE}

Name:           %{appname}
Version:        %{version}
Release:        %{release}%{?dist}
Summary:        Super Linux Utility - Gestione completa del sistema Linux
License:        Proprietary
Group:          Applications/System
URL:            https://github.com/marcodigiangiacomo/super-linux-utility
Source0:        %{appname}-%{version}.tar.gz
BuildArch:      x86_64
BuildRequires:  desktop-file-utils
Requires:       gtk3 glib2 libc
Requires(post): desktop-file-utils
Requires(postun): desktop-file-utils

%description
Super Linux Utility è un'applicazione completa per la gestione avanzata del sistema Linux.
Offre strumenti potenti per ottimizzare le prestazioni, gestire servizi, applicazioni e
personalizzare l'aspetto del sistema.

Caratteristiche principali:
- Analisi e gestione servizi systemd (identifica servizi che rallentano l'avvio)
- Gestione applicazioni all'avvio con protezione app di sistema
- Pulizia intelligente file temporanei di applicazioni comuni
- Gestione app installate (APT, Snap, Flatpak, GNOME) con controllo dipendenze
- Monitoraggio processi e risorse di sistema (CPU, RAM, Dischi, GPU)
- Personalizzazione aspetto (font, temi, icone, sfondo, comportamento finestre)
- GRUB Editor (modalità avanzata) con backup automatico
- Gestione Kernel (modalità avanzata) con rimozione sicura
- Modalità Standard e Avanzata per separare funzionalità base da quelle avanzate
- Analizzatore di spazio disco con navigazione cartelle e anteprime file
- Supporto multilingua (Italiano, Inglese, Francese, Spagnolo, Tedesco, Portoghese)

%prep
%setup -q -n %{appname}-%{version}

%build
# Niente da compilare, l'app è già compilata

%install
# Crea le directory di installazione
mkdir -p %{buildroot}/usr/share/%{appname}
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/pixmaps

# Copia tutti i file dell'applicazione
cp -r * %{buildroot}/usr/share/%{appname}/

# Installa lo script wrapper
install -m 755 %{appname}.sh %{buildroot}/usr/bin/%{appname}

# Installa il desktop file
install -m 644 %{appname}.desktop %{buildroot}/usr/share/applications/

# Installa l'icona se disponibile
if [ -f %{appname}.png ]; then
    install -m 644 %{appname}.png %{buildroot}/usr/share/pixmaps/
fi

%post
# Aggiorna il database delle applicazioni desktop
if [ -x /usr/bin/update-desktop-database ]; then
    update-desktop-database -q /usr/share/applications 2>/dev/null || true
fi

# Aggiorna il database delle icone
if [ -x /usr/bin/update-icon-caches ]; then
    update-icon-caches /usr/share/pixmaps 2>/dev/null || true
fi

# Aggiorna il database GNOME (se disponibile)
if [ -x /usr/bin/glib-compile-schemas ]; then
    glib-compile-schemas /usr/share/glib-2.0/schemas 2>/dev/null || true
fi

# Forza l'aggiornamento del menu GNOME
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
fi

%postun
# Aggiorna il database delle applicazioni desktop dopo la rimozione
if [ -x /usr/bin/update-desktop-database ]; then
    update-desktop-database -q /usr/share/applications 2>/dev/null || true
fi

%files
%defattr(-,root,root,-)
/usr/share/%{appname}
/usr/bin/%{appname}
/usr/share/applications/%{appname}.desktop
%{_datadir}/pixmaps/%{appname}.png

%changelog
* $(date '+%a %b %d %Y') Marco Di Giangiacomo <marco@example.com> - %{version}-%{release}
- Initial RPM package for Super Linux Utility

SPEC_EOF

# Crea l'archivio sorgente
echo "📦 Creating source tarball..."
cd $RPMBUILD_DIR/SOURCES
tar -czf ${APP_NAME}-${APP_VERSION}.tar.gz ${APP_NAME}-${APP_VERSION}

# Costruisci il pacchetto RPM
echo "🔨 Building RPM package..."
rpmbuild -ba $SPEC_FILE

# Trova il file RPM generato
RPM_FILE=$(find $RPMBUILD_DIR/RPMS -name "${APP_NAME}-${APP_VERSION}-${APP_RELEASE}.*.rpm" | head -1)

if [ -n "$RPM_FILE" ]; then
    echo "✅ RPM package created: $RPM_FILE"
    echo "📦 Package size: $(du -h $RPM_FILE | cut -f1)"
    echo ""
    echo "📋 To install the package, run:"
    echo "   sudo dnf install $RPM_FILE"
    echo ""
    echo "📋 To check package contents:"
    echo "   rpm -qlp $RPM_FILE"
else
    echo "❌ Error: RPM package not found"
    exit 1
fi

