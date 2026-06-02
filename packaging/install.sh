#!/bin/sh
#
# LDAP Admin one-line installer.
#
#   curl -fsSL https://raw.githubusercontent.com/mikhailartamonov/LDAP-Admin/master/packaging/install.sh | sh
#
# Detects the distribution, downloads the matching artifact from the latest
# GitHub release and installs it:
#   * Debian/Ubuntu  -> .deb      (apt)
#   * Arch/Manjaro   -> .pkg.tar.zst (pacman)
#   * anything else  -> AppImage into ~/.local/bin
#
set -eu

REPO="mikhailartamonov/LDAP-Admin"
# Newest release including pre-releases (/releases/latest hides pre-releases).
API="https://api.github.com/repos/$REPO/releases?per_page=1"

say()  { printf '\033[1;32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$1" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$1" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || die "curl is required"

# Pick sudo only if we are not already root.
if [ "$(id -u)" = 0 ]; then SUDO=""; else
  command -v sudo >/dev/null 2>&1 && SUDO="sudo" || die "sudo is required (or run as root)"
fi

# Find a release asset whose name matches the given grep pattern.
asset_url() {
  curl -fsSL "$API" \
    | grep -o '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | sed 's/.*"\(https[^"]*\)"/\1/' \
    | grep -iE "$1" \
    | head -n1
}

download() {  # download <url> <dest>
  say "downloading $(basename "$2")"
  curl -fL --retry 3 -o "$2" "$1" || die "download failed: $1"
}

install_deb() {
  url="$(asset_url '\.deb$')" || true
  [ -n "${url:-}" ] || return 1
  tmp="$(mktemp --suffix=.deb)"
  download "$url" "$tmp"
  say "installing with apt"
  $SUDO apt-get update -qq || true
  $SUDO apt-get install -y "$tmp" || $SUDO dpkg -i "$tmp" || { $SUDO apt-get -f install -y; }
  rm -f "$tmp"
}

install_pacman() {
  url="$(asset_url '\.pkg\.tar\.(zst|xz)$')" || true
  [ -n "${url:-}" ] || return 1
  tmp="$(mktemp --suffix=.pkg.tar.zst)"
  download "$url" "$tmp"
  say "installing with pacman"
  $SUDO pacman -U --noconfirm "$tmp"
  rm -f "$tmp"
}

install_appimage() {
  url="$(asset_url '\.AppImage$')" || true
  [ -n "${url:-}" ] || die "no AppImage asset found in the latest release"
  dest="$HOME/.local/bin"
  mkdir -p "$dest"
  out="$dest/LDAP-Admin.AppImage"
  download "$url" "$out"
  chmod +x "$out"
  say "installed AppImage to $out"
  case ":$PATH:" in *":$dest:"*) ;; *) warn "add $dest to your PATH to run 'LDAP-Admin.AppImage'";; esac
}

main() {
  if command -v apt-get >/dev/null 2>&1 && [ -r /etc/debian_version ]; then
    say "Debian/Ubuntu detected"
    install_deb || { warn "no .deb in release, falling back to AppImage"; install_appimage; }
  elif command -v pacman >/dev/null 2>&1; then
    say "Arch Linux detected"
    install_pacman || { warn "no pacman package in release, falling back to AppImage"; install_appimage; }
  else
    warn "unknown distribution, using AppImage"
    install_appimage
  fi
  say "done — launch it with 'ldapadmin' (or from your application menu)"
}

main "$@"
