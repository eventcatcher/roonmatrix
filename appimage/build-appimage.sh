#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Build RoonMatrix AppImage
# -----------------------------
# Local: FVM
# CI: Flutter Action using flutter
# -----------------------------

# -----------------------------
# Variables
# -----------------------------
PROJECT_ROOT="${GITHUB_WORKSPACE:-$(dirname "$(realpath "$0")")/..}"
APPDIR="$PROJECT_ROOT/appimage/RoonMatrix.AppDir"
FLUTTER_LIB_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle/lib"

# Extract version from pubspec.yaml
VERSION=$(grep '^version:' "$PROJECT_ROOT/pubspec.yaml" | awk '{print $2}' | cut -d+ -f1)
APPIMAGE_NAME="RoonMatrix-${VERSION}-x86_64.AppImage"

echo "Building RoonMatrix AppImage version $VERSION"

# -----------------------------
# Clean AppDir
# -----------------------------
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/bin/lib"

# -----------------------------
# Copy Flutter shared libraries
# -----------------------------
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

## -----------------------------
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
# local Flutter Build
# -----------------------------
if [ -z "${GITHUB_ACTIONS:-}" ]; then
  echo "Building Flutter Linux release (local)..."
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
  echo "ERROR: Flutter binary not found at $BINARY"
  ls -R "$PROJECT_ROOT/build/linux"
  exit 1
fi

cp "$BINARY" "$APPDIR/usr/bin/"

DATA_SRC="$PROJECT_ROOT/build/linux/x64/release/bundle/data"
DATA_DST="$APPDIR/usr/bin/data"
mkdir -p "$DATA_DST"
cp -r "$DATA_SRC/"* "$DATA_DST/"

# -----------------------------
# AppRun
# -----------------------------
cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
exec "$HERE/usr/bin/roonmatrix" "$@"
EOF
chmod +x "$APPDIR/AppRun"

echo "AppRun executable?"
[ -x "$APPDIR/AppRun" ] && echo "AppRun OK" || echo "AppRun missing or not executable"

# -----------------------------
# Build AppImage
# -----------------------------
export GTK_USE_PORTAL=1

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

# Move AppImage to versioned name
mv "$APPIMAGE" "$PROJECT_ROOT/appimage/$APPIMAGE_NAME"
chmod +x "$PROJECT_ROOT/appimage/$APPIMAGE_NAME"

echo "✅ AppImage created: $PROJECT_ROOT/appimage/$APPIMAGE_NAME"

# -----------------------------
# Headless Smoke-Test
# -----------------------------
echo "Running smoke-test..."
if [ -x "$APPIMAGE" ]; then
  echo "✅ AppImage is executable"
else
  echo "❌ AppImage is missing or not executable"
  exit 1
fi
echo "✅ Smoke-test passed!"