#!/usr/bin/env bash
# Builds a single AppImage from an extracted MiSTer Companion Linux binary.
#
# Usage: make-appimage.sh <binary-path> <appimage-arch> <output-path> <owner/repo> <version>
#   appimage-arch: value for appimagetool's ARCH env var (x86_64 | aarch64)
#   owner/repo: this repo's GitHub slug, used for embedded update information
#     (read by update checkers like Gear Lever); the release asset name is
#     taken from the basename of <output-path>.
#   version: upstream release tag, embedded as X-AppImage-Version in the
#     desktop file -- the key Gear Lever reads to display an app's version.
#
# Also produces "<output-path>.zsync" alongside the AppImage (appimagetool
# bundles its own zsyncmake). Gear Lever's embedded-update-info detection
# only recognizes gh-releases-zsync strings whose filename ends in ".zsync",
# and it fetches that file's "SHA-1:" header to decide if an update exists
# -- so the .zsync file must also be uploaded as a release asset.
set -euo pipefail

BINARY_PATH="$1"
APPIMAGE_ARCH="$2"
OUTPUT_PATH="$3"
OWNER_REPO="$4"
VERSION="$5"

OWNER="${OWNER_REPO%%/*}"
REPO_NAME="${OWNER_REPO#*/}"
RELEASE_FILENAME="$(basename "$OUTPUT_PATH")"
UPDATE_INFO="gh-releases-zsync|${OWNER}|${REPO_NAME}|latest|${RELEASE_FILENAME}.zsync"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

APPDIR="$WORK_DIR/AppDir"
mkdir -p "$APPDIR/usr/bin"

cp "$BINARY_PATH" "$APPDIR/usr/bin/mister-companion"
chmod +x "$APPDIR/usr/bin/mister-companion"

curl -sL -o "$APPDIR/mister-companion.png" \
  "https://raw.githubusercontent.com/Anime0t4ku/mister-companion/main/mister-companion/assets/icon.png"

cat > "$APPDIR/mister-companion.desktop" <<EOF
[Desktop Entry]
Name=MiSTer Companion
Exec=mister-companion
Icon=mister-companion
Type=Application
Categories=Utility;
X-AppImage-Version=${VERSION}
EOF

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
# MiSTer Companion stores config.json next to its own executable and expects
# that directory to be writable and stable across runs. The AppImage's squashfs
# mount is read-only and gets a new path every launch, so copy the binary out
# to a persistent, writable location and run it from there instead.
HERE="$(dirname "$(readlink -f "${0}")")"

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/mister-companion"
mkdir -p "$DATA_DIR"

SRC_BIN="$HERE/usr/bin/mister-companion"
RUN_BIN="$DATA_DIR/mister-companion"

if [ ! -x "$RUN_BIN" ] || ! cmp -s "$SRC_BIN" "$RUN_BIN"; then
  cp "$SRC_BIN" "$RUN_BIN.new"
  chmod +x "$RUN_BIN.new"
  mv "$RUN_BIN.new" "$RUN_BIN"
fi

cd "$DATA_DIR"
exec "$RUN_BIN" "$@"
EOF
chmod +x "$APPDIR/AppRun"

if [ ! -x "$WORK_DIR/appimagetool.AppImage" ]; then
  curl -sL -o "$WORK_DIR/appimagetool.AppImage" \
    "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
  chmod +x "$WORK_DIR/appimagetool.AppImage"
fi

ARCH="$APPIMAGE_ARCH" "$WORK_DIR/appimagetool.AppImage" -u "$UPDATE_INFO" "$APPDIR" "$OUTPUT_PATH"
