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

if [ ! -d "$APPDIR/usr/share/applications" ]; then
    echo "ERROR: Applications folder missing at $APPDIR/usr/share/applications"
    exit 1
fi

# Desktop-File
DESKTOP_FILE="$APPDIR/usr/share/applications/RoonMatrix.desktop"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=RoonMatrix
Exec=usr/bin/roonmatrix
Icon=usr/share/icons/hicolor/256x256/apps/RoonMatrix.png
Type=Application
Categories=Utility;
EOF

# Prüfen ob korrekt geschrieben
if [ ! -f "$DESKTOP_FILE" ]; then
    echo "ERROR: Desktop file not created at $DESKTOP_FILE"
    ls -l "$APPDIR/usr/share/applications"
    exit 1
fi

# -----------------------------
# Icons & Desktop
# -----------------------------
ICON_SRC="$PROJECT_ROOT/assets/icon/icon.png"
ICON_FILE="$APPDIR/usr/share/icons/hicolor/256x256/apps/RoonMatrix.png"
if [ ! -f "$ICON_SRC" ]; then
  echo "ERROR: Icon not found at $ICON_SRC"
  exit 1
fi
cp "$ICON_SRC" "$ICON_FILE"

if [ ! -f "$ICON_FILE" ]; then
  echo "ERROR: Icon missing!"
  ls -R "$APPDIR/usr/share/icons/hicolor/256x256/apps"
  exit 1
fi

# -----------------------------
# Flutter Build
# -----------------------------
echo "Building Flutter Linux release..."

if [ -z "${GITHUB_WORKSPACE:-}" ]; then
    # Local → FVM
    echo "Using FVM locally"
    fvm flutter build linux --release
else
    # CI → Flutter from Action
    echo "Using Flutter from GitHub Action"
    flutter build linux --release
fi

# Copy Binary
BINARY="$PROJECT_ROOT/build/linux/x64/release/bundle/roonmatrix"
if [ ! -f "$BINARY" ]; then
  BINARY="$PROJECT_ROOT/build/linux/release/bundle/roonmatrix"
fi

if [ ! -f "$BINARY" ]; then
  echo "ERROR: Flutter binary not found at $BINARY"
  ls -R "$PROJECT_ROOT/build/linux"
  exit 1
fi

cp "$BINARY" "$APPDIR/usr/bin/"

# -----------------------------
# AppImageTool
# -----------------------------
if ! command -v appimagetool &> /dev/null; then
    echo "ERROR: appimagetool not found. Install from https://appimage.org/"
    exit 1
fi

echo "Check AppDir structure:"
find "$APPDIR"

echo "Building AppImage..."
appimagetool "$APPDIR"

# set rights
chmod +x "$PROJECT_ROOT"/RoonMatrix-x86_64.AppImage

echo "✅ AppImage created: $PROJECT_ROOT/RoonMatrix-x86_64.AppImage"