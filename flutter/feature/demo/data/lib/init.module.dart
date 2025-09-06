//@GeneratedMicroModule;DemoDataPackageModule;package:demo_data/init.module.dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:demo_data/src/repository/demo_repository_impl.dart' as _i143;
import 'package:demo_domain/repository.dart' as _i264;
import 'package:injectable/injectable.dart' as _i526;

class DemoDataPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.singleton<_i264.DemoRepository>(() => _i143.DemoRepositoryImpl());
  }
}
