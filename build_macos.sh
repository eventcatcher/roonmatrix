rm -f pubspec_overrides.yaml

fvm flutter clean
fvm flutter pub get

rm -rf macos/Pods macos/.symlinks macos/Podfile.lock

cd macos
pod install
cd ..

fvm flutter build macos
