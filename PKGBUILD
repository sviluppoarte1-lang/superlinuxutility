# Maintainer: Super Linux Utility Team <sviluppoarte1-lang@users.noreply.github.com>
pkgname=super-linux-utility
pkgver=2.1.0
pkgrel=1
pkgdesc='System management tool for Linux - monitor, optimize, and manage your system'
arch=('x86_64')
url='https://github.com/sviluppoarte1-lang/superlinuxutility'
license=('GPL-3.0-or-later')
depends=('gtk3' 'glib2' 'libayatana-appindicator')
makedepends=('flutter' 'cmake' 'ninja' 'clang' 'pkg-config' 'gtk3' 'pcre2' 'graphviz')
options=('!strip')
source=("${url}/archive/refs/tags/${pkgver}.tar.gz::${url}/archive/refs/tags/${pkgver}.tar.gz")
sha256sums=('SKIP')

prepare() {
    cd "superlinuxutility-${pkgver}"

    # Enable Linux desktop support
    flutter config --enable-linux-desktop

    # Get dependencies
    flutter pub get
}

build() {
    cd "superlinuxutility-${pkgver}"

    # Generate icons from PNG base
    if [ -f "assets/icons/icon.png" ] && command -v convert &>/dev/null; then
        echo "Generating icons..."
        mkdir -p linux/runner/assets
        for size in 16 24 32 48 64 128 256 512; do
            convert "assets/icons/icon.png" -resize ${size}x${size} -colorspace sRGB -type TrueColorAlpha -alpha on "linux/runner/assets/icon_${size}.png"
        done
    fi

    # Build release
    flutter build linux --release --dart-define=APP_BUILD=standard
}

package() {
    cd "superlinuxutility-${pkgver}"

    # Install binary
    install -Dm755 "build/linux/x64/release/bundle/super_linux_utility" "${pkgdir}/usr/bin/super-linux-utility"

    # Install desktop file
    install -Dm644 "build/linux/x64/release/bundle/super-linux-utility.desktop" "${pkgdir}/usr/share/applications/super-linux-utility.desktop"

    # Install icons
    install -Dm644 "assets/icons/icon.png" "${pkgdir}/usr/share/pixmaps/super-linux-utility.png"

    # Install hicolor icons
    for size in 16 24 32 48 64 128 256 512; do
        local icon_path="linux/runner/assets/icon_${size}.png"
        if [ -f "$icon_path" ]; then
            install -Dm644 "$icon_path" "${pkgdir}/usr/share/icons/hicolor/${size}x${size}/apps/super-linux-utility.png"
        fi
    done

    # Install data files
    install -d "${pkgdir}/usr/share/super-linux-utility"
    cp -r "build/linux/x64/release/bundle/lib" "${pkgdir}/usr/share/super-linux-utility/"
    cp -r "build/linux/x64/release/bundle/data" "${pkgdir}/usr/share/super-linux-utility/" 2>/dev/null || true
}
