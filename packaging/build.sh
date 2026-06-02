#!/usr/bin/env bash
#
# build.sh — compile LDAP Admin with lazbuild.
# Assumes lazbuild + fpc are already on PATH (CI installs them via
# setup-lazarus on Ubuntu / pacman on Arch).
#
# Env knobs:
#   CPU               target CPU                 (default: x86_64)
#   WIDGETSET         LCL widgetset              (default: qt5)
#   BUILD_MODE        Lazarus build mode         (default: Linux)
#   LAZARUSDIR        Lazarus install dir        (default: auto-detected)
#   GCC_LIBPATH_FIX   1 = add the host gcc lib dir to the FPC library path.
#                     Needed where the gcc is newer than FPC 3.2.2 knows about
#                     (e.g. Arch's gcc 16), which otherwise fails to find
#                     crtbeginS.o at link time. Requires /etc/fpc.cfg to exist.
#   STATIC_URL        mORMot2 static libs archive (default: synopse.info)
#
set -euo pipefail

CPU="${CPU:-x86_64}"
WIDGETSET="${WIDGETSET:-qt5}"
BUILD_MODE="${BUILD_MODE:-Linux}"
STATIC_URL="${STATIC_URL:-https://synopse.info/files/mormot2static.7z}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

echo "==> Initialising submodules (mORMot2)"
git submodule update --init --recursive

# mORMot2 links prebuilt static objects (crc32c, sqlite3, ...) that are NOT
# stored in git; fetch them once into submodules/mORMot2/static/.
STATIC_DIR="submodules/mORMot2/static/$CPU-linux"
if ! ls "$STATIC_DIR"/*.o >/dev/null 2>&1; then
  echo "==> Fetching mORMot2 static libraries"
  tmp7z="$(mktemp --suffix=.7z)"
  curl -fL --retry 3 -o "$tmp7z" "$STATIC_URL"
  ( cd submodules/mORMot2 && rm -rf static && 7za x "$tmp7z" -ostatic >/dev/null )
  rm -f "$tmp7z"
fi

# Optionally teach FPC where the (too-new) gcc runtime objects live, without
# clobbering the system config: our fpc.cfg just includes it and appends -Fl.
if [ "${GCC_LIBPATH_FIX:-0}" = "1" ]; then
  GCC_DIR="/usr/lib/gcc/$(gcc -dumpmachine)/$(gcc -dumpversion)"
  echo "==> Adding gcc library path: $GCC_DIR"
  mkdir -p "$ROOT/.cache/fpc"
  printf '#INCLUDE /etc/fpc.cfg\n-Fl%s\n' "$GCC_DIR" > "$ROOT/.cache/fpc/fpc.cfg"
  export PPC_CONFIG_PATH="$ROOT/.cache/fpc"
fi

LAZ_ARGS=()
if [ -n "${LAZARUSDIR:-}" ]; then
  LAZ_ARGS+=(--lazarusdir="$LAZARUSDIR")
else
  # Auto-detect the Lazarus directory (the one holding packager/globallinks).
  gl="$(find /usr -path '*/packager/globallinks' -type d 2>/dev/null | head -1 || true)"
  [ -n "$gl" ] && LAZ_ARGS+=(--lazarusdir="$(dirname "$(dirname "$gl")")")
fi

echo "==> Registering mORMot2 Lazarus package"
lazbuild "${LAZ_ARGS[@]}" --add-package-link submodules/mORMot2/packages/lazarus/mormot2.lpk >/dev/null

echo "==> Building LdapAdmin (cpu=$CPU ws=$WIDGETSET mode=$BUILD_MODE)"
lazbuild "${LAZ_ARGS[@]}" \
  --cpu="$CPU" \
  --widgetset="$WIDGETSET" \
  --build-mode="$BUILD_MODE" \
  Source/LdapAdmin.lpi

test -x Source/LdapAdmin
echo "==> Built: $ROOT/Source/LdapAdmin"
file Source/LdapAdmin
