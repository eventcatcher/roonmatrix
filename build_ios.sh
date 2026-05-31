export SERIOUS_PYTHON_SITE_PACKAGES=$(pwd)/app/src/__pypackages__
#cp pubspec_mobile_overrides.yaml pubspec_overrides.yaml
rm -f pubspec_overrides.yaml

fvm flutter clean
fvm flutter pub get

rm -rf ios/Pods ios/.symlinks ios/Podfile.lock

cd ios
pod install
cd ..

fvm flutter build ipa --release
