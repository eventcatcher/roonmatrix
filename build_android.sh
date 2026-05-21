cp pubspec_mobile_overrides.yaml pubspec_overrides.yaml

flutter clean
flutter pub get

fvm flutter build apk
