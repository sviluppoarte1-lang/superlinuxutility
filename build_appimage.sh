#!/bin/bash

# ============================================================================
# AppImage Builder for Super Linux Utility
# Generates 3 portable AppImages: standard (free), advanced (paid), personal (dev)
# ============================================================================

set -euo pipefail

# ---- Secret licenza (git-ignored, fuori dal repo) ----
# Legge $SLU_LICENSE_SECRET_FILE (default: $HOME/.config/slu/license_secret).
# Il valore viene passato via --dart-define al build: le licenze già vendute
# restano valide finché il file non cambia. Se manca, il build va avanti SENZA
# il secret (attivazione impossibile in Advanced) con un warning.
read_license_secret() {
    local f="${SLU_LICENSE_SECRET_FILE:-$HOME/.config/slu/license_secret}"
    if [ -n "${SLU_LICENSE_SECRET:-}" ]; then
        echo "${SLU_LICENSE_SECRET}"
    elif [ -f "$f" ]; then
        tr -d "[:space:]" < "$f"
    else
        echo ""
    fi
}


# ─── Configuration ───────────────────────────────────────────────────────────

BINARY_NAME="super_linux_utility"
APP_VERSION="2.1.0"
BUILD_MODE="release"
ICON_SOURCE="assets/icons/icon.png"

# Variant definitions: name, package_name, dart_define, display_name, description
VARIANTS=(
    "standard|super-linux-utility|standard|Super Linux Utility|System management tool (free)"
    "advanced|super-linux-utility-advanced|advanced|Super Linux Utility Advanced|Enhanced system management (paid)"
    "personal|super-linux-utility-personal|personal|Super Linux Utility Personal|Dev/Test build"
)

# Directories
BUILD_DIR="build/linux/x64/release/bundle"
APPDIR_ROOT="build/appimage"
TOOLS_DIR="build/appimage/tools"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ─── Helper functions ────────────────────────────────────────────────────────

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }
step()    { echo -e "\n${CYAN}━━━ $* ━━━${NC}"; }

check_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# ─── Prerequisite checks ────────────────────────────────────────────────────

step "Checking prerequisites"

MISSING=()

if check_cmd flutter; then
    success "Flutter found: $(which flutter)"
else
    error "Flutter not found"
    MISSING+=("flutter")
fi

if check_cmd cmake; then
    success "CMake found: v$(cmake --version | head -1 | grep -oP '\d+\.\d+')"
else
    error "CMake not found"
    MISSING+=("cmake")
fi

if check_cmd ninja; then
    success "Ninja found"
else
    error "Ninja not found"
    MISSING+=("ninja-build")
fi

if check_cmd clang; then
    success "Clang found: v$(clang --version | head -1 | grep -oP '\d+\.\d+\.\d+')"
else
    error "Clang not found"
    MISSING+=("clang")
fi

if check_cmd make; then
    success "Make found"
else
    error "Make not found"
    MISSING+=("make")
fi

if check_cmd pkg-config; then
    success "pkg-config found"
else
    error "pkg-config not found"
    MISSING+=("pkg-config")
fi

if pkg-config --exists gtk+-3.0 2>/dev/null; then
    success "GTK3 dev files: v$(pkg-config --modversion gtk+-3.0)"
else
    error "GTK3 dev files not found"
    MISSING+=("libgtk-3-dev")
fi

if check_cmd file; then
    success "file utility found"
else
    error "file utility not found"
    MISSING+=("file")
fi

if check_cmd patchelf; then
    success "patchelf found"
else
    warn "patchelf not found (will be downloaded with linuxdeploy)"
fi

if [ -f "$ICON_SOURCE" ]; then
    success "Icon found: $ICON_SOURCE"
else
    error "Icon not found: $ICON_SOURCE"
    MISSING+=("icon")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    error "Missing ${#MISSING[@]} required package(s): ${MISSING[*]}"
    echo ""
    echo "Install them with your package manager:"
    echo ""
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|linuxmint|pop|zorin|elementary|mx|kali|deepin)
                echo "  sudo apt update"
                echo "  sudo apt install -y cmake ninja-build clang pkg-config \\"
                echo "    libgtk-3-dev build-essential file patchelf"
                ;;
            fedora|rhel|centos|rocky|alma)
                echo "  sudo dnf install -y cmake ninja-build clang pkg-config \\"
                echo "    gtk3-devel patchelf"
                ;;
            arch|manjaro|endeavouros|cachyos|garuda)
                echo "  sudo pacman -S --needed cmake ninja clang pkg-config \\"
                echo "    gtk3 patchelf"
                ;;
            opensuse*|suse*)
                echo "  sudo zypper install -y cmake ninja clang pkg-config \\"
                echo "    gtk3-devel patchelf"
                ;;
            *)
                echo "  # Install: cmake, ninja-build, clang, pkg-config,"
                echo "  #          gtk3-devel (or libgtk-3-dev), patchelf"
                ;;
        esac
    fi
    echo ""
    exit 1
fi

success "All prerequisites satisfied"
echo ""

# ─── Download linuxdeploy tools ─────────────────────────────────────────────

step "Downloading linuxdeploy tools"

LINUXDEPLOY_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
LINUXDEPLOY_GTK_URL="https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh"
APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"

LINUXDEPLOY="${TOOLS_DIR}/linuxdeploy-x86_64.AppImage"
LINUXDEPLOY_GTK="${TOOLS_DIR}/linuxdeploy-plugin-gtk.sh"
APPIMAGETOOL="${TOOLS_DIR}/appimagetool-x86_64.AppImage"

mkdir -p "$TOOLS_DIR"

if [ ! -f "$LINUXDEPLOY" ]; then
    info "Downloading linuxdeploy..."
    curl -L -o "$LINUXDEPLOY" "$LINUXDEPLOY_URL"
    chmod +x "$LINUXDEPLOY"
    success "linuxdeploy downloaded"
else
    success "linuxdeploy already present"
fi

if [ ! -f "$LINUXDEPLOY_GTK" ]; then
    info "Downloading GTK plugin..."
    curl -L -o "$LINUXDEPLOY_GTK" "$LINUXDEPLOY_GTK_URL"
    chmod +x "$LINUXDEPLOY_GTK"
    success "GTK plugin downloaded"
else
    success "GTK plugin already present"
fi

if [ ! -f "$APPIMAGETOOL" ]; then
    info "Downloading appimagetool..."
    curl -L -o "$APPIMAGETOOL" "$APPIMAGETOOL_URL"
    chmod +x "$APPIMAGETOOL"
    success "appimagetool downloaded"
else
    success "appimagetool already present"
fi

# ─── Patch system_tray plugin (ayatana-first dlopen) ────────────────────────
# FIX Fedora: il plugin fa dlopen("libappindicator3.so.1") dopo essere stato
# compilato linkato a libayatana-appindicator3 (NEEDED). Su host RedHat-family
# (Fedora) esiste il VERO libappindicator3.so.1 (12.10.x) → il dlopen lo carica
# nel processo ACCANTO a quello ayatana già caricato → due stack appindicator
# su GLib diversi → SIGSEGV dentro InitSystemTray. Su Debian-family l'host
# libappindicator3.so.1 è un symlink verso ayatana (stesso inode) → dedup →
# un solo oggetto → nessun crash. Richiedere subito il soname ayatana rende il
# dlopen un no-op (dedup col NEEDED già caricato). Vedi AGENTS.md.
patch_system_tray_plugin() {
    local pub_cache_dir
    pub_cache_dir="$HOME/.pub-cache"
    # rispetta PUB_CACHE se impostato
    [ -n "${PUB_CACHE:-}" ] && pub_cache_dir="$PUB_CACHE"
    local f="$pub_cache_dir/hosted/pub.dev/system_tray-2.0.3/linux/tray.cc"
    if [ ! -f "$f" ]; then
        warn "system_tray tray.cc non trovato in $f: patch saltata"
        return 0
    fi
    if grep -q 'SLU-AYATANA-FIRST-PATCH' "$f"; then
        success "system_tray: patch ayatana-first già applicata"
        return 0
    fi
    if ! command -v python3 >/dev/null 2>&1; then
        error "python3 assente: non posso applicare la patch a system_tray"
        return 1
    fi
    python3 - "$f" <<'PYEOF'
import sys
p = sys.argv[1]
s = open(p).read()
old = '''    void* handle = dlopen("libappindicator3.so.1", RTLD_LAZY);
    if (!handle) {
      break;
    }
'''
new = '''    // SLU-AYATANA-FIRST-PATCH: vedasi build_appimage.sh. Il primo dlopen con
    // il soname ayatana dedup con il NEEDED gia' caricato dal loader; su host
    // senza ayatana (fallback) si usa il vecchio nome libappindicator3.so.1.
    void* handle = dlopen("libayatana-appindicator3.so.1", RTLD_LAZY);
    if (!handle) {
      handle = dlopen("libappindicator3.so.1", RTLD_LAZY);
    }
    if (!handle) {
      break;
    }
'''
if old not in s:
    sys.exit(2)
open(p, "w").write(s.replace(old, new, 1))
PYEOF
    local rc=$?
    if [ "$rc" -eq 0 ]; then
        success "system_tray: patch ayatana-first applicata (dlopen posizione ayatana prima)"
    else
        error "system_tray: patch NON applicata (pattern non trovato in tray.cc, rc=$rc)"
        return 1
    fi
}

patch_system_tray_plugin || exit 1

# ─── Build function ─────────────────────────────────────────────────────────

build_variant() {
    local variant="$1"
    local pkg_name="$2"
    local dart_define="$3"
    local display_name="$4"
    local description="$5"

    local variant_appdir="${APPDIR_ROOT}/${variant}/AppDir"

    echo ""
    step "Building variant: ${display_name} (${variant})"

    # Flutter build with variant-specific dart-define
    info "Running: flutter build linux --${BUILD_MODE} --dart-define=APP_BUILD=${dart_define}"
    LICENSE_SECRET="$(read_license_secret)"
    if [ -n "$LICENSE_SECRET" ]; then
        flutter build linux --"${BUILD_MODE}" --dart-define=APP_BUILD="${dart_define}" \
            --dart-define=SLU_LICENSE_SECRET="${LICENSE_SECRET}"
    else
        warn "License secret mancante ($HOME/.config/slu/license_secret): build senza attivazione licenze."
        flutter build linux --"${BUILD_MODE}" --dart-define=APP_BUILD="${dart_define}"
    fi

    if [ ! -d "$BUILD_DIR" ]; then
        error "Flutter build failed for ${variant}"
        return 1
    fi

    # Create AppDir structure
    info "Creating AppDir for ${variant}..."
    rm -rf "${APPDIR_ROOT:?}/${variant}"
    mkdir -p "$variant_appdir/usr/bin"
    mkdir -p "$variant_appdir/usr/share/applications"
    mkdir -p "$variant_appdir/usr/share/icons/hicolor/512x512/apps"
    mkdir -p "$variant_appdir/usr/lib"

    # Copy Flutter bundle
    cp -r "$BUILD_DIR"/* "$variant_appdir/usr/bin/"
    chmod +x "$variant_appdir/usr/bin/$BINARY_NAME"

    # Create .desktop file
    cat > "$variant_appdir/$BINARY_NAME.desktop" << DESKTOP_EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=${display_name}
GenericName=System Utility
Comment=${description}
Exec=$BINARY_NAME %F
Icon=$BINARY_NAME
Terminal=false
Categories=System;Utility;
Keywords=system;utility;linux;monitor;optimization;maintenance;
StartupNotify=true
StartupWMClass=com.superlinux.utility
NoDisplay=false
DESKTOP_EOF

    # Copy icon
    cp "$ICON_SOURCE" "$variant_appdir/usr/share/icons/hicolor/512x512/apps/$BINARY_NAME.png"
    cp "$ICON_SOURCE" "$variant_appdir/$BINARY_NAME.png"

    # Copy runtime libraries
    info "Copying runtime libraries..."
    local lib_dir="$variant_appdir/usr/lib"
    mkdir -p "$lib_dir"

    local copied=0
    local LIBS_TO_CHECK=(
        "libayatana-appindicator3.so" "libayatana-indicator3.so"
        "libgtk-3.so" "libgdk-3.so" "libgio-2.0.so"
        "libgobject-2.0.so" "libglib-2.0.so" "libgdk_pixbuf-2.0.so"
        "libpango-1.0.so" "libcairo.so" "libpangocairo-1.0.so"
        "libatk-1.0.so" "libatk-bridge-2.0.so" "libatspi.so"
        "libX11.so" "libXext.so" "libXfixes.so" "libXi.so"
        "libXrandr.so" "libXcursor.so" "libXdamage.so"
        "libXrender.so" "libXcomposite.so" "libXtst.so"
        "libwayland-client.so" "libwayland-cursor.so" "libwayland-egl.so"
        "libffi.so" "libfreetype.so" "libfontconfig.so"
        "libharfbuzz.so" "libpng16.so" "libjpeg.so" "libtiff.so"
        "libwebp.so" "libxml2.so" "libpixman-1.so" "libepoxy.so"
        "libpcre2-8.so" "libbz2.so" "libuuid.so" "libdeflate.so"
        "libfribidi.so" "libthai.so" "libdatrie.so" "libgraphite2.so"
        "libXau.so" "libXdmcp.so" "libbsd.so" "libcrypto.so" "libssl.so"
        # Nella blacklist di linuxdeploy ("ogni distro ce l'ha") ma sono NEEDED
        # di librerie BUNDLED: zlib per cairo/freetype/png/xml2, expat per
        # fontconfig, gmp per gnutls, com_err per krb5/gssapi, xcb per X11,
        # gpg-error per gcrypt. Senza bundle l'AppImage si appoggiava alle lib
        # HOST → stack ibrido (instabilità) e fallimento su distro minimali.
        "libz.so" "libxcb.so" "libexpat.so" "libgmp.so" "libcom_err.so" "libgpg-error.so"
        # libstdc++: il motore Flutter richiede GLIBCXX > di quello di alcune
        # distro "vecchie" (es. Debian 12 stock ha 3.4.30, serve 3.4.31).
        # Bundle sempre la lib della build machine: copia sempre >= di ciò che
        # servono engine/plugin (stessa macchina). I processi figli (rpm, apt…)
        # non ne risentono: non c'è LD_LIBRARY_PATH ereditato.
        "libstdc++.so.6"
    )

    for lib_name in "${LIBS_TO_CHECK[@]}"; do
        for search_dir in /usr/lib/x86_64-linux-gnu /usr/lib64 /usr/lib /lib/x86_64-linux-gnu /lib64 /lib; do
            for match in "${search_dir}/${lib_name}"*; do
                if [ -f "$match" ] || [ -L "$match" ]; then
                    local real
                    real=$(readlink -f "$match" 2>/dev/null || echo "$match")
                    if [ -f "$real" ]; then
                        cp -L "$real" "$lib_dir/" 2>/dev/null && ((copied++)) || true
                        for link in "${search_dir}/$(basename "$real")"*; do
                            if [ -L "$link" ]; then
                                cp -a "$link" "$lib_dir/" 2>/dev/null || true
                            fi
                        done
                        break 2
                    fi
                fi
            done
        done
    done
    success "Copied $copied library files"

    # ── Nomi SONAME + compat dlopen (system tray Fedora/AppImage) ───────────
    # 1) `cp -L` copia col nome del file REALE (es. libstdc++.so.6.0.33), ma
    #    le NEEDED del linker cercano il nome SONAME esatto (libstdc++.so.6).
    #    linuxdeploy crea i link mancanti tranne per le librerie "blacklisted"
    #    (tra cui libstdc++) → assicuriamo noi il nome SONAME per ogni ELF
    #    copiato (readelf -d SONAME), se non esiste già.
    if command -v readelf >/dev/null 2>&1; then
        local so_real so_name
        for so_real in "$lib_dir"/*.so.*.*; do
            [ -f "$so_real" ] || continue
            so_name=$(readelf -d "$so_real" 2>/dev/null | sed -n 's/.*SONAME.*\[\(.*\)\].*/\1/p' | head -1)
            if [ -n "$so_name" ] && [ "$so_name" != "$(basename "$so_real")" ] && [ ! -e "$lib_dir/$so_name" ]; then
                ln -sf "$(basename "$so_real")" "$lib_dir/$so_name" 2>/dev/null || true
            fi
        done
    fi

    # 2) Il plugin system_tray fa dlopen("libappindicator3.so.1") a runtime.
    #    Su Debian/Ubuntu quel file è un symlink verso ayatana (pacchetto
    #    libayatana-appindicator3-1); su Fedora NON esiste → dlopen falliva e
    #    la tray non partiva. Creiamo la catena SONAME + compat qui dentro:
    #    il dlopen usa SEMPRE la lib ayatana bundled (stack coerente, nessuna
    #    ibridazione con librerie host = causa storica di segfault su Fedora/KDE).
    if [ ! -e "$lib_dir/libayatana-appindicator3.so.1" ] && [ -e "$lib_dir/libayatana-appindicator3.so.1.0.0" ]; then
        ln -sf libayatana-appindicator3.so.1.0.0 "$lib_dir/libayatana-appindicator3.so.1"
    fi
    if [ -e "$lib_dir/libayatana-appindicator3.so.1" ] && [ ! -e "$lib_dir/libappindicator3.so.1" ]; then
        ln -sf libayatana-appindicator3.so.1 "$lib_dir/libappindicator3.so.1"
        success "Created libappindicator3.so.1 compat symlink (-> ayatana)"
    fi

    # 2) RUNPATH dei plugin Flutter (usr/bin/lib): linuxdeploy processa solo
    #    l'eseguibile e le sue dipendenze, NON i plugin (caricati a runtime dal
    #    motore). Il loro RUNPATH punta ancora alla build machine → su distro
    #    senza libayatana nei repo (Fedora) le NEEDED non si risolvono e il
    #    plugin system_tray non si carica (niente tray, eccezione plugin).
    #    $ORIGIN = usr/bin/lib, ../../lib = usr/lib (librerie bundled).
    if command -v patchelf >/dev/null 2>&1; then
        local patched=0
        local so_file magic
        for so_file in "$variant_appdir"/usr/bin/lib/*.so*; do
            [ -f "$so_file" ] || continue
            magic=$(head -c 4 "$so_file" 2>/dev/null || true)
            if [ "$magic" = $'\x7fELF' ]; then
                if patchelf --set-rpath '$ORIGIN:$ORIGIN/../../lib' "$so_file" 2>/dev/null; then
                    patched=$((patched + 1))
                fi
            fi
        done
        if [ "$patched" -gt 0 ]; then
            success "Patched RUNPATH on $patched file(s) in usr/bin/lib"
        else
            warn "No ELF files patched in usr/bin/lib (check patchelf)"
        fi
    else
        warn "patchelf not found: plugin RUNPATH NOT fixed — system tray will not load on distros without libayatana (e.g. Fedora)"
    fi

    # Run linuxdeploy. gtk-plugin cannot auto-detect the GTK version on systems
    # where it isn't resolvable (notably Fedora), so we detect it from the bundled
    # Flutter GTK libs ourselves and always pass --appstream, otherwise the plugin
    # exits non-zero and no AppImage is produced (the build then prints Success but
    # ships nothing). APPIMAGE_EXTRACT_AND_RUN forces self-extract-and-run at launch,
    # which requires FUSE auto-mount; on Fedora (no fuse3) that path fails silently.
    info "Running linuxdeploy..."

    # Detect GTK major version from the bundled Flutter GTK libraries in the AppDir.
    local gtk_version="" glib_lib
    for glib_lib in "$variant_appdir"/usr/lib/libgtk-*.so*; do
        [ -e "$glib_lib" ] || continue
        glib_lib=$(basename "$glib_lib")
        # strip libgtk-(3|4)-<so> / libgtk-x11-2.0-<...>; keep the version digits
        gtk_version=$(echo "$glib_lib" | grep -oE '[0-9]{1,2}\.' | head -1 | cut -d. -f1)
        [ -n "$gtk_version" ] && break
    done
    case "${gtk_version:-}" in
        2|3|4) ;;              # use detected major version (gtk-plugin wants {2,3,4})
        *)     gtk_version=3;  # safe default: never leave unset (previously caused the bug)
    esac
    export DEPLOY_GTK_VERSION="$gtk_version"

    # Generate a minimal AppStream metainfo so the gtk plugin can run without error.
    local meta_path="${variant_appdir}/usr/share/metainfo/${BINARY_NAME}.metainfo.xml"
    mkdir -p "$(dirname "$meta_path")"
    cat > "$meta_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<component>
  <id>${pkg_name}.AppImage</id>
  <name>${BINARY_NAME}</name>
  <summary>Slim Linux Utility - universal desktop toolkit</summary>
  <release version="${APP_VERSION}" date="$(date +%Y-%m-%d)"/>
</component>
EOF

    # Do NOT self-extract: a normal AppImage just needs the user to run it once.
    unset APPIMAGE_EXTRACT_AND_RUN

    "$LINUXDEPLOY" \
        --appdir "$variant_appdir" \
        --desktop-file "$variant_appdir/$BINARY_NAME.desktop" \
        --icon-file "$variant_appdir/$BINARY_NAME.png" \
        --plugin gtk \
        --output appimage 2>&1 | tee "${APPDIR_ROOT}/${variant}_linuxdeploy.log"
    local dep_rc=$?

    # Check if linuxdeploy produced the AppImage (only on success, not via masking).
    local appimage_file
    appimage_file=$(find "${APPDIR_ROOT}" -maxdepth 1 -name "*.AppImage" -type f | head -1)

    if [ "$dep_rc" -eq 0 ] && [ -n "$appimage_file" ]; then
        local final_name="${pkg_name}-${APP_VERSION}-x86_64.AppImage"
        mv "$appimage_file" "$final_name"
        success "AppImage created: $final_name ($(du -h "$final_name" | cut -f1))"
        return 0
    fi

    # Fallback: appimagetool (also sets GTK version + appstream, so it never silently fails).
    warn "linuxdeploy failed for ${variant}, using appimagetool..."
    sed -i 's/%F//g' "$variant_appdir/$BINARY_NAME.desktop"
    chmod +x "$variant_appdir/usr/bin/$BINARY_NAME"

    local final_name="${pkg_name}-${APP_VERSION}-x86_64.AppImage"
    ARCH=x86_64 DEPLOY_GTK_VERSION="$gtk_version" "$APPIMAGETOOL" \
        --no-appstream \
        "$variant_appdir" \
        "$final_name" 2>&1 | tee "${APPDIR_ROOT}/${variant}_appimagetool.log" || {
            error "appimagetool failed for ${variant} (check log)"
            return 1
        }

    if [ -f "$final_name" ]; then
        success "AppImage created: $final_name ($(du -h "$final_name" | cut -f1))"
        return 0
    fi

    error "AppImage creation failed for ${variant}"
    return 1
}

# ─── Build all variants ─────────────────────────────────────────────────────

step "Building all AppImage variants"

BUILT=()
FAILED=()

for variant_def in "${VARIANTS[@]}"; do
    IFS='|' read -r variant pkg_name dart_define display_name description <<< "$variant_def"

    if build_variant "$variant" "$pkg_name" "$dart_define" "$display_name" "$description"; then
        BUILT+=("$variant")
    else
        FAILED+=("$variant")
    fi
done

# ─── Summary ────────────────────────────────────────────────────────────────

echo ""
echo ""
if [ ${#BUILT[@]} -gt 0 ]; then
    success "=========================================="
    success " AppImage build complete!"
    success "=========================================="
    echo ""
    for v in "${BUILT[@]}"; do
        IFS='|' read -r _ pkg_name _ display_name _ <<< "$(printf '%s\n' "${VARIANTS[@]}" | grep "^${v}|")"
        local_file="${pkg_name}-${APP_VERSION}-x86_64.AppImage"
        if [ -f "$local_file" ]; then
            echo -e "  ${GREEN}✓${NC} ${display_name}"
            echo "    File: $local_file ($(du -h "$local_file" | cut -f1))"
        fi
    done
fi

if [ ${#FAILED[@]} -gt 0 ]; then
    echo ""
    error "Failed variants: ${FAILED[*]}"
fi

echo ""
echo "To run any variant:"
echo "  chmod +x <file>.AppImage"
echo "  ./<file>.AppImage"
echo ""
echo "To install system-wide (optional):"
echo "  sudo cp <file>.AppImage /usr/local/bin/"
