export SERIOUS_PYTHON_SITE_PACKAGES=$(pwd)/app/src/__pypackages__
rm -f pubspec_overrides.yaml

fvm flutter clean
fvm flutter pub get

fvm flutter build linux --release
