#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Build Roonmatrix AppImage
# -----------------------------
PROJECT_ROOT="${GITHUB_WORKSPACE:-$(dirname "$(realpath "$0")")/..}"
APPDIR="$PROJECT_ROOT/appimage/Roonmatrix.AppDir"

# Detect architecture
ARCH=${1:-x86_64}
APPIMAGE_NAME="Roonmatrix-${VERSION:-unknown}-$ARCH.AppImage"

echo "Building Roonmatrix AppImage for $ARCH"

# -----------------------------
# Clean AppDir
# -----------------------------
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/bin/lib"
mkdir -p "$APPDIR/usr/bin/site-packages"
mkdir -p "$APPDIR/usr/bin/python3.12"

# -----------------------------
# Extract version
# -----------------------------
if [ -f "$PROJECT_ROOT/pubspec.yaml" ]; then
  VERSION=$(grep '^version:' "$PROJECT_ROOT/pubspec.yaml" | awk '{print $2}' | cut -d+ -f1)
else
  VERSION="0.0.0"
fi
echo "Version: $VERSION"
APPIMAGE_NAME="Roonmatrix-${VERSION}-$ARCH.AppImage"

# -----------------------------
# Copy Flutter shared libraries
# -----------------------------
FLUTTER_LIB_DIR_X64="$PROJECT_ROOT/build/linux/x64/release/bundle/lib"
FLUTTER_LIB_DIR_GENERIC="$PROJECT_ROOT/build/linux/release/bundle/lib"

if [ -d "$FLUTTER_LIB_DIR_X64" ]; then
  echo "Copying Flutter shared libraries from x64..."
  cp -a "$FLUTTER_LIB_DIR_X64/." "$APPDIR/usr/bin/lib/"
  mkdir -p "$APPDIR/usr/lib"
  cp -a "$FLUTTER_LIB_DIR_X64/." "$APPDIR/usr/lib/"
elif [ -d "$FLUTTER_LIB_DIR_GENERIC" ]; then
  echo "Copying Flutter shared libraries from generic path..."
  cp -a "$FLUTTER_LIB_DIR_GENERIC/." "$APPDIR/usr/bin/lib/"
else
  echo "WARNING: No Flutter lib directory found"
fi

# ---------------------------------
# Copy Flutter python site-packages
# ---------------------------------
FLUTTER_PKG_DIR_X64="$PROJECT_ROOT/build/linux/x64/release/bundle/site-packages"
FLUTTER_PKG_DIR_GENERIC="$PROJECT_ROOT/build/linux/release/bundle/site-packages"

if [ -d "$FLUTTER_PKG_DIR_X64" ]; then
  echo "Copying Python packages from x64..."
  cp -r "$FLUTTER_PKG_DIR_X64/"* "$APPDIR/usr/bin/site-packages/"
elif [ -d "$FLUTTER_PKG_DIR_GENERIC" ]; then
  echo "Copying Python packages from generic path..."
  cp -r "$FLUTTER_PKG_DIR_GENERIC/"* "$APPDIR/usr/bin/site-packages/"
else
  echo "WARNING: No Python packages directory found"
fi

# -------------------
# Copy Flutter python
# -------------------
FLUTTER_PYTH_DIR_X64="$PROJECT_ROOT/build/linux/x64/release/bundle/python3.12"
FLUTTER_PYTH_DIR_GENERIC="$PROJECT_ROOT/build/linux/release/bundle/python3.12"

if [ -d "$FLUTTER_PYTH_DIR_X64" ]; then
  echo "Copying Flutter Python from x64..."
  cp -r "$FLUTTER_PYTH_DIR_X64/"* "$APPDIR/usr/bin/python3.12/"
elif [ -d "$FLUTTER_PYTH_DIR_GENERIC" ]; then
  echo "Copying Flutter Python from generic path..."
  cp -r "$FLUTTER_PYTH_DIR_GENERIC/"* "$APPDIR/usr/bin/python3.12/"
else
  echo "WARNING: No Python directory found"
fi

# -----------------------------
# Desktop entry
# -----------------------------
DESKTOP_FILE="$APPDIR/usr/share/applications/Roonmatrix.desktop"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Roonmatrix
Exec=Roonmatrix
Icon=Roonmatrix
Type=Application
Categories=Utility;
EOF
chmod 644 "$DESKTOP_FILE"

# -----------------------------
# Copy icon
# -----------------------------
ICON_SRC="$PROJECT_ROOT/assets/icon/icon.png"
ICON_FILE="$APPDIR/usr/share/icons/hicolor/256x256/apps/Roonmatrix.png"
cp "$ICON_SRC" "$ICON_FILE"

# -----------------------------
# Local Flutter build
# -----------------------------
if [ -z "${GITHUB_ACTIONS:-}" ]; then
  echo "build Python packages (1st run).."
  export SERIOUS_PYTHON_SITE_PACKAGES=$(pwd)/app/src/__pypackages__  
  cd packages/python_backend
  dart run serious_python:main package ../../app/src -p Linux --asset assets/backend/roonmatrix.zip -r -r -r ../../app/src/requirements.txt
  cd ../../

  echo "build Python packages (2nd run)..."
  export SERIOUS_PYTHON_SITE_PACKAGES=$(pwd)/app/src/__pypackages__  
  cd packages/python_backend
  dart run serious_python:main package ../../app/src -p Linux --asset assets/backend/roonmatrix.zip -r -r -r ../../app/src/requirements.txt
  cd ../../

  echo "Running local Flutter build..."
  rm -f pubspec_overrides.yaml
  flutter clean
  flutter pub get
  flutter build linux --release
else
  echo "Skipping local Flutter build => running in GitHub Actions"
fi

# -----------------------------
# Copy Flutter binary & data
# -----------------------------
BINARY="$PROJECT_ROOT/build/linux/x64/release/bundle/Roonmatrix"
if [ ! -f "$BINARY" ]; then
  BINARY="$PROJECT_ROOT/build/linux/release/bundle/Roonmatrix"
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

# python in-app packages folder
export SERIOUS_PYTHON_SITE_PACKAGES="$PROJECT_ROOT/app/src/__pypackages__"

exec "$HERE/usr/bin/Roonmatrix" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# -----------------------------
# Build AppImage
# -----------------------------

if ! command -v linuxdeploy >/dev/null; then
  echo "ERROR: linuxdeploy not installed"
  exit 1
fi

echo "waiting..."
sleep 5s

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
