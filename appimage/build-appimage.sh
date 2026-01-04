#!/usr/bin/env bash
set -e

APP_NAME="RoonMatrix"
APP_ID="roonmatrix"
APPDIR="appimage/${APP_NAME}.AppDir"
ICON="assets/icon.png"

echo "==> Flutter build (linux, release)"
fvm flutter build linux --release

echo "==> Preparing AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

echo "==> Copy Flutter bundle"
cp -r build/linux/x64/release/bundle/* "$APPDIR/usr/bin/"

echo "==> Desktop file"
cat > "$APPDIR/usr/share/applications/${APP_ID}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=RoonMatrix
Exec=roonmatrix
Icon=roonmatrix
Categories=Utility;
Terminal=false
EOF

echo "==> Icon"
cp "$ICON" "$APPDIR/usr/share/icons/hicolor/256x256/apps/roonmatrix.png"

echo "==> AppRun"
cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/bin/lib:$LD_LIBRARY_PATH"
exec "$HERE/usr/bin/roonmatrix"
EOF
chmod +x "$APPDIR/AppRun"

echo "==> Download appimagetool (if missing)"
if [ ! -f appimage/appimagetool ]; then
  wget -O appimage/appimagetool \
    https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x appimage/appimagetool
fi

echo "==> Build AppImage"
appimage/appimagetool "$APPDIR"

echo "✅ AppImage created"
