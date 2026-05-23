@echo off
setlocal

echo Removing pubspec_overrides.yaml...
if exist pubspec_overrides.yaml del /f /q pubspec_overrides.yaml

echo Cleaning Flutter project...
call flutter clean
echo flutter clean finished

echo Delete AppData Roaming Folder...
rd /s /q "%userprofile%\AppData\Roaming\de.eventcatcher\roonmatrix\flet\assets"

echo Running flutter pub get...
call flutter pub get

echo Building Windows app...
call fvm flutter build windows

echo Done.
pause
