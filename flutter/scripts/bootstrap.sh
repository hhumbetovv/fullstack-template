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
fvm dart run scripts smart-build
fvm dart pub global activate flutterfire_cli
fvm dart pub global activate icon_font_generator
