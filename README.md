# LDAP Admin for Linux

A maintained Linux fork of [LDAP Admin](http://ldapadmin.org) — a client and
administration tool for LDAP directories (OpenLDAP, Samba AD). This fork exists
to provide **ready-to-install packages** so you don't have to install Lazarus
and compile anything by hand.

> Tested primarily against **OpenLDAP**.

![Main window](docs/screenshots/main.png)

## Install

### One-liner (Ubuntu & Arch)

```sh
curl -fsSL https://raw.githubusercontent.com/mikhailartamonov/LDAP-Admin/master/packaging/install.sh | sh
```

The script detects your distribution, downloads the matching artifact from the
[latest release](../../releases/latest) and installs it (`.deb` via `apt` on
Ubuntu/Debian, `.pkg.tar.zst` via `pacman` on Arch, AppImage everywhere else).

### Ubuntu / Debian (`.deb`)

```sh
# download ldapadmin_<version>_amd64.deb from the Releases page, then:
sudo apt install ./ldapadmin_*_amd64.deb
```

### Arch Linux (`.pkg.tar.zst`)

```sh
# download the package from the Releases page, then:
sudo pacman -U ldapadmin-*-x86_64.pkg.tar.zst
```

Or build it yourself from the bundled [`PKGBUILD`](packaging/PKGBUILD):

```sh
makepkg -si
```

### AppImage (any distro)

```sh
chmod +x LDAP-Admin-*.AppImage
./LDAP-Admin-*.AppImage
```

After installing a package, launch it from your application menu or run
`ldapadmin` from a terminal.

## Features

- Browse and edit LDAP directories
- Recursive operations on directory trees (copy, move, delete)
- Schema browser
- LDIF export / import
- Password management (crypt, md5, sha, sha-crypt, samba)
- Template support
- Binary attribute support
- LDAP over SSL/TLS

## Screenshots

| Main window | Connection manager |
|---|---|
| ![Main window](docs/screenshots/main.png) | ![Connection manager](docs/screenshots/connect.png) |

## How packages are built

Everything is built on GitHub Actions — see
[`.github/workflows/build.yml`](.github/workflows/build.yml):

| Distro | Toolchain | Widgetset | Output |
|--------|-----------|-----------|--------|
| Ubuntu | official Lazarus 4.6 + FPC 3.2.2 | Qt5 | `.deb`, AppImage |
| Arch   | `lazarus-qt5` + `qt5pas`          | Qt5 | `.pkg.tar.zst` |

The UI uses the **Qt5** widgetset for a modern, native look (rounded window
corners and proper theming on GNOME/KDE).

Pushing a `v*` tag triggers a release with all three artifacts attached.

## Build from source

Requirements: Lazarus 4.x, FPC 3.2.2, the mORMot2 submodule and Qt5 bindings
(`libqt5pas-dev` on Debian/Ubuntu, `qt5pas` on Arch).

```sh
git clone https://github.com/mikhailartamonov/LDAP-Admin.git
cd LDAP-Admin
git submodule update --init --recursive
./packaging/build.sh                 # builds Source/LdapAdmin
```

Build the packages from the compiled binary:

```sh
./packaging/build-deb.sh             # -> dist/ldapadmin_<ver>_amd64.deb
./packaging/build-appimage.sh        # -> dist/LDAP-Admin-<ver>-x86_64.AppImage
```

### Compiling in the Lazarus IDE

Open `Source/LdapAdmin.lpi`, make sure the `mormot2` package
(`submodules/mORMot2/packages/lazarus/mormot2.lpk`) is registered, then build.

## Configuration

Connections and settings are stored per-user under
`~/.config/LdapAdmin/`. Default templates live next to the binary in
`/usr/lib/ldapadmin/`.

## Localization

Translations are compiled `.po`/`.mo` files (Russian, German, Polish included).
To add a language, copy `Source/locale/LdapAdmin.po` to
`LdapAdmin.<xx>.po`, translate it with [Poedit](https://poedit.net/) and place
the resulting `.mo` next to the binary in `locale/`.

## Credits

- Original Windows application: <http://www.ldapadmin.org>
- Linux port: <https://github.com/ibv/LDAP-Admin>
- mORMot2 framework: <https://github.com/synopse/mORMot2>
