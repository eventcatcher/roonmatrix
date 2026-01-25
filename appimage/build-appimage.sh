#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Build RoonMatrix AppImage
# -----------------------------
PROJECT_ROOT="${GITHUB_WORKSPACE:-$(dirname "$(realpath "$0")")/..}"
APPDIR="$PROJECT_ROOT/appimage/RoonMatrix.AppDir"

# Detect architecture
ARCH=${1:-x86_64}
APPIMAGE_NAME="RoonMatrix-${VERSION:-unknown}-$ARCH.AppImage"

echo "Building RoonMatrix AppImage for $ARCH"

# -----------------------------
# Clean AppDir
# -----------------------------
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/bin/lib"

# -----------------------------
# Extract version
# -----------------------------
if [ -f "$PROJECT_ROOT/pubspec.yaml" ]; then
  VERSION=$(grep '^version:' "$PROJECT_ROOT/pubspec.yaml" | awk '{print $2}' | cut -d+ -f1)
else
  VERSION="0.0.0"
fi
echo "Version: $VERSION"
APPIMAGE_NAME="RoonMatrix-${VERSION}-$ARCH.AppImage"

# -----------------------------
# Copy Flutter shared libraries
# -----------------------------
FLUTTER_LIB_DIR_X64="$PROJECT_ROOT/build/linux/x64/release/bundle/lib"
FLUTTER_LIB_DIR_GENERIC="$PROJECT_ROOT/build/linux/release/bundle/lib"

if [ -d "$FLUTTER_LIB_DIR_X64" ]; then
  echo "Copying Flutter shared libraries from x64..."
  cp -r "$FLUTTER_LIB_DIR_X64/"* "$APPDIR/usr/bin/lib/"
elif [ -d "$FLUTTER_LIB_DIR_GENERIC" ]; then
  echo "Copying Flutter shared libraries from generic path..."
  cp -r "$FLUTTER_LIB_DIR_GENERIC/"* "$APPDIR/usr/bin/lib/"
else
  echo "WARNING: No Flutter lib directory found"
fi

# -----------------------------
# Desktop entry
# -----------------------------
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

# -----------------------------
# Copy icon
# -----------------------------
ICON_SRC="$PROJECT_ROOT/assets/icon/icon.png"
ICON_FILE="$APPDIR/usr/share/icons/hicolor/256x256/apps/RoonMatrix.png"
cp "$ICON_SRC" "$ICON_FILE"

# -----------------------------
# Local Flutter build
# -----------------------------
if [ -z "${GITHUB_ACTIONS:-}" ]; then
  echo "Running local Flutter build..."
  flutter build linux --release
else
  echo "Skipping local Flutter build => running in GitHub Actions"
fi

# -----------------------------
# Copy Flutter binary & data
# -----------------------------
BINARY="$PROJECT_ROOT/build/linux/x64/release/bundle/roonmatrix"
if [ ! -f "$BINARY" ]; then
  BINARY="$PROJECT_ROOT/build/linux/release/bundle/roonmatrix"
fi

if [ ! -f "$BINARY" ]; then
  echo "ERROR: Flutter binary not found"
  ls -R "$PROJECT_ROOT/build/linux"
  exit 1
fi

cp "$BINARY" "$APPDIR/usr/bin/"

DATA_SRC="$PROJECT_ROOT/build/linux/x64/release/bundle/data"
DATA_DST="$APPDIR/usr/bin/data"
if [ -d "$DATA_SRC" ]; then
  mkdir -p "$DATA_DST"
  cp -r "$DATA_SRC/"* "$DATA_DST/"
else
  echo "WARNING: No data folder found at $DATA_SRC"
fi

# -----------------------------
# AppRun
# -----------------------------
cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export GTK_USE_PORTAL=1

# NVIDIA + Flutter Linux Stabilisierung
export __GL_SYNC_TO_VBLANK=0
export __GL_YIELD="USLEEP"

# GTK / GDK Stabilisierung
export GDK_BACKEND=x11
export GDK_GL=gles
export GDK_FRAME_CLOCK=stable

exec "$HERE/usr/bin/roonmatrix" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# -----------------------------
# Build AppImage
# -----------------------------

if ! command -v linuxdeploy >/dev/null; then
  echo "ERROR: linuxdeploy not installed"
  exit 1
fi

echo "Running linuxdeploy..."
linuxdeploy \
  --appdir "$APPDIR" \
  --plugin gtk \
  --output appimage

APPIMAGE=$(ls *.AppImage | head -n 1)

if [ -z "$APPIMAGE" ]; then
  echo "ERROR: No AppImage generated"
  exit 1
fi

mv "$APPIMAGE" "$PROJECT_ROOT/appimage/$APPIMAGE_NAME"
chmod +x "$PROJECT_ROOT/appimage/$APPIMAGE_NAME"

echo "✅ AppImage created: $PROJECT_ROOT/appimage/$APPIMAGE_NAME"

# -----------------------------
# Smoke-Test
# -----------------------------
echo "Running smoke-test..."
if [ -x "$PROJECT_ROOT/appimage/$APPIMAGE_NAME" ]; then
  echo "✅ AppImage is executable"
else
  echo "❌ AppImage is missing or not executable"
  exit 1
fi
