//@GeneratedMicroModule;DemoPresentationPackageModule;package:demo_presentation/init.module.dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:demo_data/init.module.dart' as _i117;
import 'package:demo_domain/init.module.dart' as _i135;
import 'package:injectable/injectable.dart' as _i526;

class DemoPresentationPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) async {
    await _i135.DemoDomainPackageModule().init(gh);
    await _i117.DemoDataPackageModule().init(gh);
  }
}
