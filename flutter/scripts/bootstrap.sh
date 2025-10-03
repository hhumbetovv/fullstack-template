fvm use
fvm global $(jq -r '.flutter' .fvmrc)
fvm flutter clean
cd app
fvm flutter clean
fvm flutter pub get
cd ios
pod deintegrate
pod repo update
pod install
cd ../..
fvm flutter pub get
dart scripts/smart_build.dart
dart pub global activate flutterfire_cli