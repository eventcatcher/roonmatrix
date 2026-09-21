#cp pubspec_mobile_overrides.yaml pubspec_overrides.yaml
rm -f pubspec_overrides.yaml

fvm flutter clean
fvm flutter pub get

export SERIOUS_PYTHON_VERSION=3.14
export SERIOUS_PYTHON_SITE_PACKAGES=$(pwd)/build/site-packages
export SERIOUS_PYTHON_APP=$(pwd)/build/app
cd packages/python_backend
fvm dart run serious_python:main package ../../app/src -p Android -r -r -r ../../app/src/requirements.txt
cd ../../

fvm flutter build apk
