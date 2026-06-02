#!/usr/bin/env bash
#
# build-deb.sh — assemble a .deb from an already-built binary using stage.sh.
#
# Env knobs:
#   VERSION    package version           (default: derived from git)
#   ARCH       dpkg architecture         (default: amd64)
#   WIDGETSET  widgetset the binary uses (default: qt6) — selects runtime deps
#   OUTDIR     where to drop the .deb     (default: dist)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

VERSION="${VERSION:-$(git describe --tags --always 2>/dev/null | sed 's/^v//' || echo 0.0.0)}"
ARCH="${ARCH:-amd64}"
WIDGETSET="${WIDGETSET:-qt5}"
OUTDIR="${OUTDIR:-dist}"

# Widgetset-specific GUI dependency.
case "$WIDGETSET" in
  qt6)       WS_DEP="libqt6pas6" ;;
  qt5)       WS_DEP="libqt5pas1" ;;
  gtk3)      WS_DEP="libgtk-3-0 | libgtk-3-0t64" ;;
  gtk2|*)    WS_DEP="libgtk2.0-0 | libgtk2.0-0t64" ;;
esac

ROOTDIR="$(mktemp -d)"
trap 'rm -rf "$ROOTDIR"' EXIT

"$ROOT/packaging/stage.sh" "$ROOTDIR" /usr

# Control metadata.
install -d "$ROOTDIR/DEBIAN"
INSTALLED_KB=$(du -ks "$ROOTDIR" | cut -f1)
cat > "$ROOTDIR/DEBIAN/control" <<EOF
Package: ldapadmin
Version: $VERSION
Section: net
Priority: optional
Architecture: $ARCH
Depends: libc6, $WS_DEP, libssl3 | libssl3t64 | libssl1.1
Recommends: ca-certificates
Installed-Size: $INSTALLED_KB
Maintainer: Mikhail Artamonov <mailtoartamonov@gmail.com>
Homepage: https://github.com/mikhailartamonov/LDAP-Admin
Description: LDAP directory client and administration tool
 LDAP Admin is a Lazarus/Free Pascal port of the Windows LDAP Admin client.
 It browses and edits LDAP directories (OpenLDAP, Samba AD), manages POSIX
 and Samba accounts, supports LDIF import/export, schema browsing, templates
 and SSL/TLS connections.
EOF

# Refresh the desktop/icon caches on install & removal.
cat > "$ROOTDIR/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if [ -x "$(command -v update-desktop-database 2>/dev/null)" ]; then
  update-desktop-database -q /usr/share/applications 2>/dev/null || true
fi
if [ -x "$(command -v gtk-update-icon-cache 2>/dev/null)" ]; then
  gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor 2>/dev/null || true
fi
EOF
cp "$ROOTDIR/DEBIAN/postinst" "$ROOTDIR/DEBIAN/postrm"
chmod 0755 "$ROOTDIR/DEBIAN/postinst" "$ROOTDIR/DEBIAN/postrm"

mkdir -p "$OUTDIR"
OUT="$OUTDIR/ldapadmin_${VERSION}_${ARCH}.deb"
dpkg-deb --root-owner-group --build "$ROOTDIR" "$OUT"
echo "==> Built $OUT"
dpkg-deb -I "$OUT" | sed 's/^/    /'
