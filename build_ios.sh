cp pubspec_mobile_overrides.yaml pubspec_overrides.yaml

flutter clean
flutter pub get

rm -rf ios/Pods ios/.symlinks ios/Podfile.lock

cd ios
pod install
cd ..

fvm flutter build ipa --release
