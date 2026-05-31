export SERIOUS_PYTHON_SITE_PACKAGES=$(pwd)/app/src/__pypackages__
#cp pubspec_mobile_overrides.yaml pubspec_overrides.yaml
rm -f pubspec_overrides.yaml

fvm flutter clean
fvm flutter pub get

fvm flutter build apk
