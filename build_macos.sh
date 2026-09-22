rm -f pubspec_overrides.yaml

fvm flutter clean
fvm flutter pub get

rm -rf macos/Pods macos/.symlinks macos/Podfile.lock

cd macos
pod install
cd ..

export SERIOUS_PYTHON_VERSION=3.14
export SERIOUS_PYTHON_SITE_PACKAGES=$(pwd)/build/site-packages
export SERIOUS_PYTHON_APP=$(pwd)/build/app
export SERIOUS_PYTHON_BUNDLE_ID=de.eventcatcher.roonmatrixmac
cd packages/python_backend
fvm dart run serious_python:main package ../../app/src -p Darwin -r -r -r ../../app/src/requirements.txt
cd ../../

#find build/site-packages -type f -name '*.so' -exec rm -f {} +

fvm flutter build macos
#fvm flutter run --release