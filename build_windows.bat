@echo off
setlocal

echo Removing pubspec_overrides.yaml...
if exist pubspec_overrides.yaml del /f /q pubspec_overrides.yaml

echo Cleaning Flutter project...
call fvm flutter clean
echo flutter clean finished

echo Delete AppData Roaming Folder...
rd /s /q "%userprofile%\AppData\Roaming\de.eventcatcher\roonmatrix\flet"

echo Running flutter pub get...
call fvm flutter pub get

set "SERIOUS_PYTHON_SITE_PACKAGES=%userprofile%\dev\gits\roonmatrix\build\site-packages"
set "SERIOUS_PYTHON_APP=%userprofile%\dev\gits\roonmatrix\build\app"
cd packages/python_backend
fvm dart run serious_python:main package ../../app/src -p Windows -r -r -r ../../app/src/requirements.txt
cd ../../

echo Building Windows app...
call fvm flutter build windows

echo Done.
pause
