#!/bin/bash

# ============================================================================
# AppImage Builder for Super Linux Utility
# Generates 3 portable AppImages: standard (free), advanced (paid), personal (dev)
# ============================================================================

set -euo pipefail

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
    flutter build linux --"${BUILD_MODE}" --dart-define=APP_BUILD="${dart_define}"

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

    # Run linuxdeploy
    info "Running linuxdeploy..."
    export APPIMAGE_EXTRACT_AND_RUN=1
    export LINUXDEPLOY_PLUGIN_GTK="$LINUXDEPLOY_GTK"

    "$LINUXDEPLOY" \
        --appdir "$variant_appdir" \
        --desktop-file "$variant_appdir/$BINARY_NAME.desktop" \
        --icon-file "$variant_appdir/$BINARY_NAME.png" \
        --plugin gtk \
        --output appimage \
        2>&1 | tee "${APPDIR_ROOT}/${variant}_linuxdeploy.log" || true

    # Check if linuxdeploy produced the AppImage
    local appimage_file
    appimage_file=$(find "${APPDIR_ROOT}" -maxdepth 1 -name "*.AppImage" -type f | head -1)

    if [ -n "$appimage_file" ]; then
        local final_name="${pkg_name}-${APP_VERSION}-x86_64.AppImage"
        mv "$appimage_file" "$final_name"
        success "AppImage created: $final_name ($(du -h "$final_name" | cut -f1))"
        return 0
    fi

    # Fallback: appimagetool
    warn "linuxdeploy failed for ${variant}, using appimagetool..."
    sed -i 's/%F//g' "$variant_appdir/$BINARY_NAME.desktop"
    chmod +x "$variant_appdir/usr/bin/$BINARY_NAME"

    local final_name="${pkg_name}-${APP_VERSION}-x86_64.AppImage"
    ARCH=x86_64 "$APPIMAGETOOL" \
        --no-appstream \
        "$variant_appdir" \
        "$final_name" \
        2>&1 | tee "${APPDIR_ROOT}/${variant}_appimagetool.log" || {
            error "appimagetool failed for ${variant}"
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
