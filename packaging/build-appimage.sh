#!/usr/bin/env bash
#
# build-appimage.sh — build a portable AppImage from an already-built binary.
# Uses linuxdeploy to bundle the toolkit + libraries so it runs on any modern
# glibc Linux (Ubuntu, Arch, Fedora, ...).
#
# Env knobs:
#   VERSION    used in the output filename (default: derived from git)
#   WIDGETSET  qt6|qt5|gtk3|gtk2 — selects the right linuxdeploy plugin
#   OUTDIR     output directory (default: dist)
#   TOOLDIR    where to cache linuxdeploy tools (default: .cache/appimage)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

VERSION="${VERSION:-$(git describe --tags --always 2>/dev/null | sed 's/^v//' || echo 0.0.0)}"
WIDGETSET="${WIDGETSET:-qt5}"
OUTDIR="${OUTDIR:-dist}"
TOOLDIR="${TOOLDIR:-$ROOT/.cache/appimage}"
ARCH_GNU="$(uname -m)"

mkdir -p "$TOOLDIR" "$OUTDIR"

fetch() {  # fetch <url> <dest>
  [ -f "$2" ] || { echo "==> downloading $(basename "$2")"; curl -fL --retry 3 -o "$2" "$1"; chmod +x "$2"; }
}

LD="$TOOLDIR/linuxdeploy-$ARCH_GNU.AppImage"
AT="$TOOLDIR/appimagetool-$ARCH_GNU.AppImage"
fetch "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-$ARCH_GNU.AppImage" "$LD"
fetch "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH_GNU.AppImage" "$AT"

PLUGIN_ARGS=()
case "$WIDGETSET" in
  qt6|qt5)
    QP="$TOOLDIR/linuxdeploy-plugin-qt-$ARCH_GNU.AppImage"
    fetch "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-$ARCH_GNU.AppImage" "$QP"
    PLUGIN_ARGS=(--plugin qt)
    ;;
  gtk3|gtk2)
    GP="$TOOLDIR/linuxdeploy-plugin-gtk.sh"
    fetch "https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh" "$GP"
    PLUGIN_ARGS=(--plugin gtk)
    ;;
esac

APPDIR="$(mktemp -d)/AppDir"
trap 'rm -rf "$(dirname "$APPDIR")"' EXIT
mkdir -p "$APPDIR"

# Lay out the usual /usr tree, then let linuxdeploy collect dependencies.
"$ROOT/packaging/stage.sh" "$APPDIR" /usr

# linuxdeploy wants the real ELF as the main executable (not the shell wrapper),
# and resolves data files relative to it — so it must keep its app-dir siblings.
export APPIMAGE_EXTRACT_AND_RUN=1
export OUTPUT="$OUTDIR/LDAP-Admin-${VERSION}-${ARCH_GNU}.AppImage"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"

"$LD" --appdir "$APPDIR" \
  --executable "$APPDIR/usr/lib/ldapadmin/LdapAdmin" \
  --desktop-file "$APPDIR/usr/share/applications/ldapadmin.desktop" \
  --icon-file "$APPDIR/usr/share/icons/hicolor/32x32/apps/ldapadmin.png" \
  "${PLUGIN_ARGS[@]}" \
  --output appimage

echo "==> Built $OUTPUT"
