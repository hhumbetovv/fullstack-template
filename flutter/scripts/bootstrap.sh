fvm use
fvm global $(jq -r '.flutter' .fvmrc)
fvm flutter clean
cd app
fvm flutter clean
cd ..
fvm flutter pub get
sh scripts/gen_build.sh
dart pub global activate flutterfire_cli