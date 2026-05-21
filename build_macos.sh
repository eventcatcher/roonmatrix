rm -f pubspec_overrides.yaml

flutter clean
flutter pub get

rm -rf macos/Pods macos/.symlinks macos/Podfile.lock

cd macos
pod install
cd ..

fvm flutter build macos
