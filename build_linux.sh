rm -f pubspec_overrides.yaml

flutter clean
flutter pub get

flutter build linux --release
