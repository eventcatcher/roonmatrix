cp pubspec_mobile_overrides.yaml pubspec_overrides.yaml

fvm flutter clean
fvm flutter pub get

fvm flutter build apk
