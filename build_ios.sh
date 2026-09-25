#cp pubspec_mobile_overrides.yaml pubspec_overrides.yaml
rm -f pubspec_overrides.yaml

fvm flutter clean
fvm flutter pub get

rm -rf ios/Pods ios/.symlinks ios/Podfile.lock

cd ios
pod install
cd ..

export SERIOUS_PYTHON_VERSION=3.14
export SERIOUS_PYTHON_SITE_PACKAGES=$(pwd)/build/site-packages
export SERIOUS_PYTHON_APP=$(pwd)/build/app
export SERIOUS_PYTHON_BUNDLE_ID=de.eventcatcher.roonmatrix
cd packages/python_backend
fvm dart run serious_python:main package ../../app/src -p iOS -r -r -r ../../app/src/requirements.txt
cd ../../

#find build/site-packages -type f -name '*.so' -exec rm -f {} +

fvm flutter build ipa --release
#fvm flutter run --release