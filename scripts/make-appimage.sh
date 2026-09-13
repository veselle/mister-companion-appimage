#!/usr/bin/env bash
# Builds a single AppImage from an extracted MiSTer Companion Linux binary.
#
# Usage: make-appimage.sh <binary-path> <appimage-arch> <output-path>
#   appimage-arch: value for appimagetool's ARCH env var (x86_64 | aarch64)
set -euo pipefail

BINARY_PATH="$1"
APPIMAGE_ARCH="$2"
OUTPUT_PATH="$3"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

APPDIR="$WORK_DIR/AppDir"
mkdir -p "$APPDIR/usr/bin"

cp "$BINARY_PATH" "$APPDIR/usr/bin/mister-companion"
chmod +x "$APPDIR/usr/bin/mister-companion"

curl -sL -o "$APPDIR/mister-companion.png" \
  "https://raw.githubusercontent.com/Anime0t4ku/mister-companion/main/mister-companion/assets/icon.png"

cat > "$APPDIR/mister-companion.desktop" <<'EOF'
[Desktop Entry]
Name=MiSTer Companion
Exec=mister-companion
Icon=mister-companion
Type=Application
Categories=Utility;
EOF

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
exec "${HERE}/usr/bin/mister-companion" "$@"
EOF
chmod +x "$APPDIR/AppRun"

if [ ! -x "$WORK_DIR/appimagetool.AppImage" ]; then
  curl -sL -o "$WORK_DIR/appimagetool.AppImage" \
    "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
  chmod +x "$WORK_DIR/appimagetool.AppImage"
fi

ARCH="$APPIMAGE_ARCH" "$WORK_DIR/appimagetool.AppImage" "$APPDIR" "$OUTPUT_PATH"
