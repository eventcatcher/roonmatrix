@echo off

set "SERIOUS_PYTHON_SITE_PACKAGES=C:\Users\swilhelm\dev\gits\roonmatrix\app\src\__pypackages__"

cd packages/python_backend
dart run serious_python:main package ../../app/src -p Windows --asset assets/backend/roonmatrix.zip -r -r -r ../../app/src/requirements.txt
cd ../../

pause
