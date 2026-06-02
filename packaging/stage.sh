#!/usr/bin/env bash
#
# stage.sh — lay out the LDAP Admin files into a DESTDIR using FHS paths.
# Shared by every packaging target (.deb, AppImage, Arch PKGBUILD) so the
# on-disk layout is identical everywhere.
#
# Usage: stage.sh <DESTDIR> [PREFIX]
#   DESTDIR  staging root (e.g. build/deb-root, AppDir, $pkgdir)
#   PREFIX   install prefix, default /usr
#
# Expects the project to be built already: Source/LdapAdmin must exist.
#
set -euo pipefail

DESTDIR="${1:?usage: stage.sh <DESTDIR> [PREFIX]}"
PREFIX="${2:-/usr}"

# Resolve repository root from this script's location (packaging/..).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$ROOT/Source"
BIN="$SRC/LdapAdmin"

[ -x "$BIN" ] || { echo "stage.sh: built binary not found at $BIN — build first" >&2; exit 1; }

# Private application directory: binary + data files live together, because
# the program looks for templates/translations next to its own executable.
APPDIR="$DESTDIR$PREFIX/lib/ldapadmin"
install -d "$APPDIR" "$APPDIR/locale"

install -m 0755 "$BIN"                       "$APPDIR/LdapAdmin"
install -m 0644 "$SRC/LdapAdmin_Icon.ico"    "$APPDIR/" 2>/dev/null || true

# Templates (*.ltf) must sit directly beside the executable.
if compgen -G "$SRC/templates/*.ltf" >/dev/null; then
  install -m 0644 "$SRC"/templates/*.ltf     "$APPDIR/"
fi

# Compiled translations (*.mo) go into <appdir>/locale, where the LCL
# DefaultTranslator looks them up by the LdapAdmin.<lang>.mo pattern.
if compgen -G "$SRC/locale/*.mo" >/dev/null; then
  install -m 0644 "$SRC"/locale/*.mo         "$APPDIR/locale/"
fi

# Launcher on PATH. Uses exec with an absolute path so argv[0] (and therefore
# the template/locale lookup) resolves to the real app directory.
install -d "$DESTDIR$PREFIX/bin"
cat > "$DESTDIR$PREFIX/bin/ldapadmin" <<EOF
#!/bin/sh
exec "$PREFIX/lib/ldapadmin/LdapAdmin" "\$@"
EOF
chmod 0755 "$DESTDIR$PREFIX/bin/ldapadmin"

# Desktop entry.
install -d "$DESTDIR$PREFIX/share/applications"
install -m 0644 "$ROOT/packaging/ldapadmin.desktop" \
                "$DESTDIR$PREFIX/share/applications/ldapadmin.desktop"

# Icons (hicolor theme). Native sizes from the .ico plus an upscaled 256px
# so the app looks acceptable in modern launchers / app grids.
for spec in 16 32; do
  src=$(ls "$ROOT"/packaging/icons/*_"${spec}x${spec}"x*.png 2>/dev/null | head -1 || true)
  [ -n "$src" ] || continue
  d="$DESTDIR$PREFIX/share/icons/hicolor/${spec}x${spec}/apps"
  install -d "$d"
  install -m 0644 "$src" "$d/ldapadmin.png"
done
if [ -f "$ROOT/packaging/icons/ldapadmin-256.png" ]; then
  d="$DESTDIR$PREFIX/share/icons/hicolor/256x256/apps"
  install -d "$d"
  install -m 0644 "$ROOT/packaging/icons/ldapadmin-256.png" "$d/ldapadmin.png"
fi

# Docs.
install -d "$DESTDIR$PREFIX/share/doc/ldapadmin"
install -m 0644 "$ROOT/README.md"     "$DESTDIR$PREFIX/share/doc/ldapadmin/" 2>/dev/null || true
install -m 0644 "$ROOT/ChangeLog.md"  "$DESTDIR$PREFIX/share/doc/ldapadmin/" 2>/dev/null || true

echo "stage.sh: staged into $DESTDIR (prefix $PREFIX)"
