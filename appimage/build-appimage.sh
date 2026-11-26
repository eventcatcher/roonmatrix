#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Build Roonmatrix AppImage
# -----------------------------
PROJECT_ROOT="${GITHUB_WORKSPACE:-$(dirname "$(realpath "$0")")/..}"
PROJECT_ROOT="$(realpath "$PROJECT_ROOT")"
APPDIR="$PROJECT_ROOT/appimage/Roonmatrix.AppDir"

# Detect architecture
ARCH=${1:-x86_64}

echo "Building Roonmatrix AppImage for $ARCH"

# -----------------------------
# Clean AppDir
# -----------------------------
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APPDIR/usr/share/applications"

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
# Local Flutter build
# (must run BEFORE copying the bundle: "flutter clean" wipes build/)
# -----------------------------
if [ -z "${GITHUB_ACTIONS:-}" ]; then
  cd "$PROJECT_ROOT"
  rm -f pubspec_overrides.yaml
  flutter clean
  flutter pub get

  echo "build Python packages..."
  export SERIOUS_PYTHON_VERSION=3.14
  export SERIOUS_PYTHON_SITE_PACKAGES="$PROJECT_ROOT/build/site-packages"
  export SERIOUS_PYTHON_APP="$PROJECT_ROOT/build/app"
  (cd packages/python_backend && dart run serious_python:main package ../../app/src -p Linux -r -r -r ../../app/src/requirements.txt)

  echo "Running local Flutter build..."
  flutter build linux --release
else
  echo "Skipping local Flutter build => running in GitHub Actions"
fi

# -----------------------------
# Locate Flutter bundle
# -----------------------------
BUNDLE=""
for candidate in \
  "$PROJECT_ROOT/build/linux/x64/release/bundle" \
  "$PROJECT_ROOT/build/linux/arm64/release/bundle" \
  "$PROJECT_ROOT/build/linux/release/bundle"; do
  if [ -f "$candidate/Roonmatrix" ]; then
    BUNDLE="$candidate"
    break
  fi
done

if [ -z "$BUNDLE" ]; then
  echo "ERROR: Flutter bundle not found"
  ls -R "$PROJECT_ROOT/build/linux" || true
  exit 1
fi
echo "Using bundle: $BUNDLE"

# The serious_python runtime expects app/, site-packages/ and python3.x/
# next to the executable, so the whole bundle is copied as-is.
if [ ! -f "$BUNDLE/app/roonmatrix.py" ]; then
  echo "ERROR: $BUNDLE/app/roonmatrix.py missing (SERIOUS_PYTHON_APP not set during flutter build?)"
  exit 1
fi

# -----------------------------
# Copy Flutter bundle (binary, data, lib, python, site-packages, app)
# -----------------------------
cp -a "$BUNDLE/." "$APPDIR/usr/bin/"
cp -a "$BUNDLE/lib/." "$APPDIR/usr/lib/"

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
cd "$PROJECT_ROOT"
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
