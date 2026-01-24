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

FLUTTER_LIB_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle/lib"

# Clean AppDir
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APPDIR/usr/share/applications"

mkdir -p "$APPDIR/usr/bin/lib"
if [ -d "$FLUTTER_LIB_DIR" ]; then
  echo "Copying Flutter shared libraries..."
  cp -r "$FLUTTER_LIB_DIR/"* "$APPDIR/usr/bin/lib/"
else
  echo "WARNING: No Flutter lib directory found"
fi

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
# Flutter runtime data (REQUIRED!)
# -----------------------------
DATA_SRC="$PROJECT_ROOT/build/linux/x64/release/bundle/data"
DATA_DST="$APPDIR/usr/bin/data"

if [ ! -d "$DATA_SRC" ]; then
  echo "ERROR: Flutter data directory not found at $DATA_SRC"
  ls -R "$PROJECT_ROOT/build/linux/x64/release/bundle"
  exit 1
fi

mkdir -p "$DATA_DST"
cp -r "$DATA_SRC/"* "$DATA_DST/"

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
export GTK_USE_PORTAL=1

if ! command -v linuxdeploy >/dev/null; then
  echo "ERROR: linuxdeploy not installed"
  exit 1
fi

linuxdeploy \
  --appdir "$APPDIR" \
  --plugin gtk \
  --output appimage

# set rights
chmod +x "$PROJECT_ROOT"/appimage/RoonMatrix-x86_64.AppImage

echo "✅ AppImage created: $PROJECT_ROOT/RoonMatrix-x86_64.AppImage"