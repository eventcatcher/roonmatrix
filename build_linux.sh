rm -f pubspec_overrides.yaml

fvm flutter clean
fvm flutter pub get

fvm flutter build linux --release
