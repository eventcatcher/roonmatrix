@echo off
setlocal

echo Removing pubspec_overrides.yaml...
if exist pubspec_overrides.yaml del /f /q pubspec_overrides.yaml

echo Cleaning Flutter project...
flutter clean

echo Running flutter pub get...
flutter pub get

echo Building Windows app...
fvm flutter build windows

echo Done.
pause
