#!/usr/bin/env bash
# Verifica la coerenza dell'AppDir prodotta da build_appimage.sh.
#
# Controlla che l'AppImage sia realmente AUTONOMO (test "simula Fedora":
# nessuna libreria host disponibile tranne le librerie base garantite da
# ogni distro Linux):
#   1) RUNPATH dei plugin Flutter (usr/bin/lib) basato su $ORIGIN
#      (in passato puntava ancora alla build machine → su Fedora il plugin
#      system_tray non si caricava: niente tray)
#   2) compat libappindicator3.so.1 (dlopen runtime del plugin system_tray)
#   3) libstdc++.so.6 (SONAME richiesto da exec/libflutter) presente
#   4) ogni NEEDED di ogni ELF risolvibile DENTRO l'AppDir, eccetto le
#      librerie base (libc-family, libgcc_s, ld-linux, libmvec, vDSO)
#   5) nessun symlink assoluto/broken che punta al sistema host
#
# Uso: ./verify_appimage.sh [standard|advanced|personal]   (default: standard)
# Exit code: 0 = tutto OK, 1 = problemi trovati (elencati su stderr)

set -u
VARIANT="${1:-standard}"
APPDIR="build/appimage/${VARIANT}/AppDir"
[ -d "$APPDIR" ] || { echo "AppDir mancante: $APPDIR" >&2; exit 1; }

BASEDIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BASEDIR" || exit 1

# Librerie garantite da ogni distro (glibc toolchain): non devono essere bundle.
WHITELIST="
libc.so.6
libm.so.6
libpthread.so.0
libdl.so.2
librt.so.1
libresolv.so.2
libutil.so.1
libmvec.so.1
libgcc_s.so.1
ld-linux-x86-64.so.2
linux-vdso.so.1
"

fail=0
err()  { echo "FAIL: $*" >&2; fail=1; }
info() { echo "  OK: $*"; }

echo "== ${VARIANT}: $APPDIR =="

# ── 1) RUNPATH exec + plugin Flutter + libs ─────────────────────────────────
# Tutto deve essere $ORIGIN-based: un RUNPATH assoluto (build machine) o
# assente non si risolve su altre distro → ibridazione con librerie host.
plugin_bad=0
check_origin() {
    local f="$1" rp
    rp=$(readelf -d "$f" 2>/dev/null | sed -n 's/.*PATH.*\[\(.*\)\]/\1/p')
    case "$rp" in
        *'$ORIGIN'*) : ;;
        *) err "RUNPATH non \$ORIGIN in ${f#"$APPDIR"/}: [$rp]"; plugin_bad=1 ;;
    esac
}
check_origin "$APPDIR/usr/bin/super_linux_utility"
for f in "$APPDIR"/usr/bin/lib/*.so*; do
    [ -f "$f" ] || continue
    check_origin "$f"
done
for f in "$APPDIR"/usr/lib/*.so*; do
    [ -f "$f" ] || continue
    [ -f "$f" ] && readelf -h "$f" >/dev/null 2>&1 || continue
    check_origin "$f"
done
[ "$plugin_bad" -eq 0 ] && info "RUNPATH exec + usr/bin/lib + usr/lib tutti \$ORIGIN-based"

# ── 2) compat dlopen system_tray + 3) SONAME libstdc++ ──────────────────────
if [ -e "$APPDIR/usr/lib/libappindicator3.so.1" ]; then
    info "libappindicator3.so.1 (compat dlopen system_tray) presente"
else
    err "libappindicator3.so.1 MANCANTE in usr/lib (dlopen system_tray fallirebbe)"
fi
if [ -e "$APPDIR/usr/lib/libayatana-appindicator3.so.1" ]; then
    info "libayatana-appindicator3.so.1 (NEEDED plugin) presente"
else
    err "libayatana-appindicator3.so.1 MANCANTE in usr/lib"
fi
if [ -e "$APPDIR/usr/lib/libstdc++.so.6" ] || [ -e "$APPDIR/usr/bin/lib/libstdc++.so.6" ]; then
    info "libstdc++.so.6 (SONAME) presente"
else
    err "libstdc++.so.6 MANCANTE (exec/libflutter non caricano su distro con GLIBCXX vecchio)"
fi

# ── 4) NEEDED risolvibili dentro l'AppDir ───────────────────────────────────
tmp_index=$(mktemp)
tmp_needed=$(mktemp)
trap 'rm -f "$tmp_index" "$tmp_needed"' EXIT
find "$APPDIR/usr/lib" "$APPDIR/usr/bin/lib" -maxdepth 1 \( -type f -o -type l \) \
    -printf '%f\n' 2>/dev/null | sort -u > "$tmp_index"

elf_count=0
for f in "$APPDIR"/usr/bin/super_linux_utility "$APPDIR"/usr/bin/lib/*.so* "$APPDIR"/usr/lib/*.so*; do
    [ -f "$f" ] || continue
    readelf -h "$f" >/dev/null 2>&1 || continue
    elf_count=$((elf_count + 1))
    readelf -d "$f" 2>/dev/null | sed -n 's/.*NEEDED.*\[\(.*\)\]/\1/p' > "$tmp_needed"
    while IFS= read -r need; do
        [ -n "$need" ] || continue
        case "$WHITELIST" in
            *"
$need
"*) continue ;;
        esac
        if ! grep -qxF "$need" "$tmp_index"; then
            err "NEEDED '$need' di ${f#"$APPDIR"/} NON risolvibile dentro l'AppDir"
        fi
    done < "$tmp_needed"
done
[ "$fail" -eq 0 ] && info "$elf_count ELF verificati: ogni NEEDED risolvibile in-AppDir (solo base-system in whitelist)"

# ── 5) symlink assoluti/broken ──────────────────────────────────────────────
abs_links=$(find "$APPDIR" -type l -lname '/*' 2>/dev/null | head -10)
if [ -n "$abs_links" ]; then
    err "symlink assoluti che puntano al sistema host:"
    echo "$abs_links" >&2
else
    info "nessun symlink assoluto verso il sistema host"
fi
broken=$(find "$APPDIR/usr" \( -type l ! -exec test -e {} \; -print \) 2>/dev/null | head -10)
if [ -n "$broken" ]; then
    err "symlink broken:"
    echo "$broken" >&2
else
    info "nessun symlink broken"
fi

if [ "$fail" -eq 0 ]; then
    echo "== ${VARIANT}: TUTTO OK =="
    exit 0
fi
echo "== ${VARIANT}: PROBLEMI TROVATI ==" >&2
exit 1
