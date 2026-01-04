#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Build RoonMatrix AppImage
# -----------------------------
# Local: FVM
# CI: Flutter Action using flutter
# -----------------------------

# Root of Project
PROJECT_ROOT="${GITHUB_WORKSPACE:-$(dirname "$(realpath "$0")")/..}"

# AppDir
APPDIR="$PROJECT_ROOT/appimage/RoonMatrix.AppDir"

# Clean AppDir
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APPDIR/usr/share/applications"

echo "PROJECT_ROOT: $PROJECT_ROOT"
echo "APPDIR: $APPDIR"

# -----------------------------
# Flutter Build
# -----------------------------
echo "Building Flutter Linux release..."

if [ -z "${GITHUB_WORKSPACE:-}" ]; then
    # Lokal → FVM
    echo "Using FVM locally"
    fvm flutter build linux --release
else
    # CI → Flutter from Action
    echo "Using Flutter from GitHub Action"
    flutter build linux --release
fi

# Copy Binary
BINARY="$PROJECT_ROOT/build/linux/release/bundle/roonmatrix"
if [ ! -f "$BINARY" ]; then
  echo "ERROR: Flutter binary not found at $BINARY"
  exit 1
fi

cp "$BINARY" "$APPDIR/usr/bin/"

# -----------------------------
# Icons & Desktop
# -----------------------------
ICON_SRC="$PROJECT_ROOT/assets/icon.png"
if [ ! -f "$ICON_SRC" ]; then
  echo "ERROR: Icon not found at $ICON_SRC"
  exit 1
fi
cp "$ICON_SRC" "$APPDIR/usr/share/icons/hicolor/256x256/apps/roonmatrix.png"

# Desktop-File
cat > "$APPDIR/usr/share/applications/roonmatrix.desktop" <<EOF
[Desktop Entry]
Name=RoonMatrix
Exec=roonmatrix
Icon=roonmatrix
Type=Application
Categories=Utility;
EOF

# -----------------------------
# AppImageTool
# -----------------------------
if ! command -v appimagetool &> /dev/null; then
    echo "ERROR: appimagetool not found. Install from https://appimage.org/"
    exit 1
fi

echo "Building AppImage..."
appimagetool "$APPDIR"

# set rights
chmod +x "$PROJECT_ROOT"/RoonMatrix-x86_64.AppImage

echo "✅ AppImage created: $PROJECT_ROOT/RoonMatrix-x86_64.AppImage"