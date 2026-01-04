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
Exec=roonmatrix
Icon=RoonMatrix
Type=Application
Categories=Utility;
EOF

chmod 644 "$DESKTOP_FILE"

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

flutter build linux --release

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
#if [ -z "${GITHUB_WORKSPACE:-}" ]; then
#  if ! command -v appimagetool &> /dev/null; then
#    echo "ERROR: appimagetool not found. Install from https://appimage.org/"
#    exit 1
#  fi
#else
#  if ! command -v linuxdeploy &> /dev/null; then
#    echo "ERROR: linuxdeploy not found."
#    exit 1
#  fi
#fi

echo "Check AppDir structure:"
find "$APPDIR"

# -----------------------------
# AppRun
# -----------------------------
cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
exec "$HERE/usr/bin/roonmatrix" "$@"
EOF
chmod +x "$APPDIR/AppRun"

echo "Listing AppDir root:"
ls -l "$APPDIR"

echo "Listing applications folder:"
ls -l "$APPDIR/usr/share/applications"

echo "AppRun executable?"
[ -x "$APPDIR/AppRun" ] && echo "AppRun OK" || echo "AppRun missing or not executable"

echo "Building AppImage..."
#if [ -z "${GITHUB_WORKSPACE:-}" ]; then
#    appimagetool "$APPDIR"
#else
#    linuxdeploy --appdir "$APPDIR" --output appimage
#fi
linuxdeploy --appdir "$APPDIR" --output appimage

# set rights
chmod +x "$PROJECT_ROOT"/RoonMatrix-x86_64.AppImage

echo "✅ AppImage created: $PROJECT_ROOT/RoonMatrix-x86_64.AppImage"